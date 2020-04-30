---
status: published
title: Minion without Mojo
---

I generally like to play with things in a way that I don't necessary recommend for production code. Some of that is simply goofing around, but most of it is tinkering with the innards to see what things can do. Now I want to do that with Minion but without a Mojolicious web application. I don't have a particular reason other than "Hold my beer".

In the 2018 Mojolicious Advent Calendar, Doug Bell (preaction) wrote about using [Minion without a full web application](/blog/2018/12/10/minion-stands-alone/). The advantage there is obviously in the commands that [Mojolicious::Plugin::Minion](https://metacpan.org/pod/Mojolicious::Plugin::Minion) provides. It's very easy to do it that way, and it's probably what you should do. However, it doesn't tell you much about how things work because it does everything for you. It's very Mojo, which is why we love it.

Here's what I want to do just to show off what Minion is doing and to give you some more possibilities for how you might employ it:

* Create jobs on Computer A
* Do some jobs from Computer A
* Do some jobs from Computer B

Minion is a job queue. You add jobs to the queue and various workers can ask for jobs, do those jobs, and return their results. There's a backend that holds the list of jobs, and workers (local, remote, whatever) connect to get jobs.

The basic idea is that you can throw some work out into the universe and something else can do it while your program moves on to something else. Your frontline programs are simpler because they merely note that something needs to be done.

Your web app might accept a file upload and then need to process that file. However, the web app doesn't need to process the file—something else does that later. The web app doesn't care because it needs to accept files from other requests.

On the non-web-app side, I control things from my laptop but I want the work to occur on the Mac Pro tower I have in the corner. My local program makes the jobs, then the Mac Pro notices the jobs, takes them, and does the work. My laptop fans stay quiet so I can hear my podcasts.

There are several other advantages to a job queue: I'm not reliant on a single process to stay alive to handle everything. I don't need to see when a process finishes to start another one. I won't even need to come up with a way to store the result. The queue keeps track of everything, can retry failed jobs, and I can have as many computers working on it as I like.

## Setup Postgres

For my demonstration, I want to use the Postgres backend so remote workers can connect to it to get some jobs. Install Postgres, configure it for remote access, and create a database. I used `minion` but name it whatever you like. but I didn't need to create tables or anything else. Minion will do that for me the first time it connects.

## Setup Perl

On the Perl side, install Minion and the Pg driver:

    $ cpan Minion Mojo::Pg

## Connect to Minion

The first time I connect to the backend, Minion sets up everything that I need. Connecting to Minion is good enough to do that:

	use v5.30;
	use warnings;

	my $connection = ...;
	my $minion = Minion->new( Pg => $connection );

That connection string is the tricky part because I want to do this from at least two computers that point at the same backend. It's also a bit tricky because macOS puts the socket in an odd place. So, I wrapped this in a little module. I make liberal use of environment variables and defaults, but you could use a configuration file or something else that suits your needs. This exists so I don't have to copy and paste the same thing into multiple programs. I have this in the *lib/* directory:

	package MyMinion;

	use v5.30;
	use Mojo::Base -strict, -signatures;

	use Carp qw(croak);
	use File::Basename qw(dirname);

	use Minion;

	use Mojo::URL;
	use Mojo::Util qw(dumper url_escape);

	sub connection_string ( $class, $host = $ENV{PG_HOST} ) {
		my $user     = $ENV{MINION_PG_USER} // 'postgres';
		my $password = $ENV{PG_PASSWORD}    // croak "Set PG_PASSWORD!";
		my $port     = $ENV{PG_PORT}        // 5432;
		my $db_name  = $ENV{MINION_DB_NAME} // 'minion';
		my $local    = ! $host;

		if( $local ) {
			($host) = grep { -S } (
				$ENV{PG_UNIX_SOCKET} // '',
				"/tmp/.s.PGSQL.$port",
				"/var/pgsql_socket/.s.PGSQL.$port",
				);
			$host = url_escape( dirname($host) );
			}

		my $url = Mojo::URL->new->scheme('postgresql')
			->host($host)
			->userinfo( join ':', $user, $password )
			->path($db_name);
		$url->port($port) unless $host =~ /:$port\z/;

		$url->to_unsafe_string;
		}

	sub connect ( $class, $host = $ENV{PG_HOST} ) {
		my $connection_string = $class->connection_string;
		say STDERR "Connection string is <$connection_string>";
		my $minion = Minion->new( Pg => $connection_string );
		}

	1;

Now I should be able to connect to Minion. Although I said I didn't want to use a web app, I do want to see the Minion dashboard. Here's a small program just for that:

	use Mojolicious::Lite;

	use FindBin;
	use lib "$FindBin::Bin/lib";
	use MyMinion;

	# perl minion-admin.pl daemon

	plugin Minion => {
		Pg => MyMinion->connection_string,
		};

	plugin 'Minion::Admin', {
		route => app->routes->any('/'),
		};

	app->start;

Even though I haven't done anything yet, and among the things I haven't done is setup the database tables, I can connect to the database and Minion will take care of it. I can see the dashboard even without any jobs:

	$ perl minion-admin.pl daemon


![](XXX: admin image)

## Make some jobs

The unit of work is a **job**. A job has a name and some arguments. A job doesn't specify what should happen, how it should happen, or who is going to do it. The job doesn't know when it is going to happen. You can play with some job parameters, but I'm not going to do that here.

Now I'll add those jobs to the backend by "enqueueing" them. I give the job a name, which can be just about any string that I like, and an array reference of arguments, which should be simple Perl values (not blessed references):

	use v5.30;
	use Mojo::Base -strict, -signatures;

	use FindBin;
	use lib "$FindBin::Bin/lib";
	use MyMinion;

	my $minion = MyMinion->connect;

	for( my $i = 0; $i < 100; $i++ ) {
		my @rands = ( int rand 100 ) x (3+rand 5);
		$minion->enqueue( sum => \@rands );
		}

When I run this program, it adds 100 jobs to Minion. The dashboard's
top graph updates the top scroll to show 100 jobs and the "inactive" jobs is now 100. They are inactive until something decides to work on them.

Minion doesn't even know what the task is, and it doesn't care; it has a name and some arguments. It knows that at some other time there will be something that knows how to handle jobs named `sum`. When something wants to perform a job, Minion will hand out what it has.

## Get to work!

A worker is something that "dequeues" a job, does the work, and gives Minion its result. You can have multiple workers all talking to the same backend. They can run from one computer or many, as long as they can connect to the database.

This first worker program connects to Minion in the same way, but this time I define a **task**. I can define the task any way that I like. In this case, I take the arguments and add them together then give the result to `finish`. This work happens on the machine that is running the worker program. For this example, I'm doing it on the same machine that enqueued the jobs:

	use v5.30;
	use Mojo::Base -strict, -signatures;

	use FindBin;
	use lib "$FindBin::Bin/lib";
	use MyMinion;

	my $minion = MyMinion->connect;

	$minion->add_task( sum => sub ( $job, @args ) {
		say "A: Working on ", $job->id;
		sleep int rand 10;
		my $sum = 0;
		$sum += $_ for @args;
		say "Sum of (@args) is $sum";
		$job->finish( $sum )
		} );

	$minion->worker->run;

When I run this, some of the inactive jobs turn to active jobs. I also see that there's one worker:

![](XXX: admin image)

That worker keeps asking for work until I do something to stop it, even if there are no more jobs. If new jobs show up, it starts working on those. I can run the job queuer again to make more jobs:

![](XXX: admin image)

The worker notices the new jobs and starts working on those too.

## Start a second worker

Now here's the slightly mind-bending part. I can start another worker to process the `sum` jobs, but it can have a completely different task definition. Instead of summing numbers, I accidentally multiply them. This doesn't matter. The job is a name and a list of arguments, not a task definition. The worker needs to know how to do it, but different workers don't need to use the same definition. Different workers should probably use the same definition, but that's up to you. Be careful!

	use v5.30;
	use Mojo::Base -strict, -signatures;

	use FindBin;
	use lib "$FindBin::Bin/lib";
	use MyMinion;

	my $minion = MyMinion->connect;

	$minion->add_task( sum => sub ( $job, @args ) {
		say "B: Working on ", $job->id;
		sleep int rand 10;
		my $sum = 1;
		$sum *= $_ for @args;
		say "Product of (@args) is $sum";
		$job->finish( $sum )
		} );

	$minion->worker->run;


When I run this, it will process jobs with the name `sum` if they are there. It's competing with the other worker. Two workers are now idling now.

## Start a remote worker

I start a worker from my laptop. The Minion database is on the Mac Pro tower. The same *MyMinion.pm* knows how to connect to the right host when I set the right environment variable, even though I'm not on the same machine as the database:

	$ env PG_HOST=macbook.local perl worker-a.pl

I should see three workers in the admin portal now. It doesn't matter that this one is remote:

![](XXX: admin image)

Back on the local side, I create a bunch more jobs:

	$ perl make-some-jobs.pl

## Different jobs, different workers

So far I've added jobs with the same name and all of my workers have processed that single name. I can enqueue jobs with different names and different workers can handle the jobs they like:

	use v5.30;
	use Mojo::Base -strict, -signatures;

	use FindBin;
	use lib "$FindBin::Bin/lib";
	use MyMinion;

	my $minion = MyMinion->connect;

	for( my $i = 0; $i < $ARGV[0] // 100; $i++ ) {
		my @rands = map { int rand 100 } 0 .. (3+rand 5);
		$minion->enqueue( sum => \@rands );
		$minion->enqueue( product => \@rands );
		$minion->enqueue( concat => \@rands );
		}

Here's a worker that handles just `sum`:

	use v5.30;
	use Mojo::Base -strict, -signatures;

	use FindBin;
	use lib "$FindBin::Bin/lib";
	use MyMinion;

	my $minion = MyMinion->connect;

	$minion->add_task( sum => sub ( $job, @args ) {
			sleep int rand 10;
			my $sum = 0;
			$sum += $_ for @args;
			$job->finish( $sum )
			} );

	$minion->worker->run;

Again, Minion doesn't care who does the work and how they do it. Here's a completely different a worker that handles `product` and 	`concat` jobs:

	use v5.30;
	use Mojo::Base -strict, -signatures;

	use FindBin;
	use lib "$FindBin::Bin/lib";
	use MyMinion;

	my $minion = MyMinion->connect;

	$minion->add_task( product => sub ( $job, @args ) {
			sleep int rand 10;
			my $product = 0;
			$product *= $_ for @args;
			$job->finish( $product )
			} );
	$minion->add_task( concat => sub ( $job, @args ) {
			sleep int rand 10;
			my $s = '';
			$s .= $_ for @args;
			$job->finish( $s )
			} );

	$minion->worker->run;

## Taking it one step further

I've created multiple workers and workers handling different sorts of jobs. How about a worker that creates more jobs? A job can have a **parent** and it won't run until that parent has finished, but that's not what I'm going to do here. Instead, I enqueue more jobs inside the task. That's handy when I don't know which jobs might come next in a multistage process.

	use v5.30;
	use Mojo::Base -strict, -signatures;

	use FindBin;
	use lib "$FindBin::Bin/lib";
	use MyMinion;

	my $minion = MyMinion->connect;

	$minion->add_task( one => sub ( $job, @args ) {
			$minion->enqueue( two => [ reverse @args ] );
			$job->finish( \@args )
			} );

	$minion->add_task( two => sub ( $job, @args ) {
			$minion->enqueue( three => [ @args[0,-1] = @args[-1,0] ] );
			$job->finish( \@args )
			} );

	$minion->add_task( three => sub ( $job, @args ) {
			$job->finish( 'Done!' )
			} );

	$minion->worker->run;

Those tasks could be something much more meaningful—perhaps a task checks a web link then adds enqueues jobs for each link it finds, which then enqueues even more links. The particular worker programs can start up, shut down, start up again without worrying about saving the work they still need to do.

## Conclusion

Employing Minion without Mojo is easy. Something creates some jobs and multiple something elses can run the tasks—all with no web app involved.
