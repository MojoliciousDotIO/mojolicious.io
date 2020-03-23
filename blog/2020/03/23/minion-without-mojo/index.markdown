---
status: published
title: Minion without Mojo
---

I generally like to play with things in a way that I don't necessary recommend for production code. Some of that is simply goofing around, but most of it is tinkering with the innards to see what things can do. Now I want to do that with Minion but without using Mojolicious. I don't have a particular reason other than "Hold my beer".

In the 2018 Mojolicious Advent Calendar, Doug Bell (preaction) wrote about using [Minion without a full web application](/blog/2018/12/10/minion-stands-alone/). The advantage there is obviously in the commands that [Mojolicious::Plugin::Minion](https://metacpan.org/pod/Mojolicious::Plugin::Minion) provides. It's very easy to do it that way, and it's probably what you should do. However, it doesn't tell you much about how things work because it does everything for you. It's very Mojo, which is why we love it.

Here's what I want to do just to show off what Minion is doing and to give you some more possibilities for how you might employ it:

* Create jobs on Computer A
* Do some jobs from Computer A
* Do some jobs from Computer B

Minion is a job queue. You add jobs to the queue and various workers can ask for jobs, do those jobs, and return their results. There's a backend that holds the list of jobs, and workers (local, remote, whatever) connect to get jobs.

The basic idea is that you can throw some work out into the universe and something else can do it while your program moves on to something else. Your frontline programs are simpler because they merely note that something needs to be done.

Your web app might accept a file upload and then need to process that file. However, the web app doesn't need to process the file—something else does that later. The web app doesn't care because it needs to accept files from other requests.

On the non-web-app side, I control things from my laptop but I want the work to occur on the Mac Pro tower I have in the corner. My local program makes the jobs, then the Mac Pro notices the jobs, takes them, and does the work. My laptop fans stay quiet so I can hear my podcasts.

## Setup Postgres

For my demonstration, I want to use the Postgres backend so remote workers can connect to it to get some jobs. Install Postgres, [configure it for remote access](https://blog.bigbinary.com/2016/01/23/configure-postgresql-to-allow-remote-connection.html
). I created a database I named `minion`, but I didn't need to create tables or anything else. Minion will do that for me the first time it connects.

## Setup Perl

On the Perl side, install Minion and the Pg driver:

    $ cpan Minion Mojo::Pg

## Connect to Minion

The first time I connect to the backend, Minion sets up everything that I need. This is good enough to do that:

	use v5.30;
	use warnings;

	my $connection = ...;
	my $minion = Minion->new( Pg => $connection );

That connection string is the tricky part because I want to do this from at least two computers that point at the same backend. So, I wrapped this in a little module. I make liberal use of environment variables, but you could use a configuration file or something else. This exists so I don't have to copy and paste the same thing into multiple programs:

	package MyMinion;

	use v5.30;
	use warnings;
	use feature qw(signatures);
	no warnings qw(experimental::signatures);

	use Carp qw(croak);
	use File::Basename qw(dirname);

	use Minion;

	use Mojo::Util qw(url_escape);

	sub connection_string ( $class ) {
		my $user     = $ENV{MINION_PG_USER} // 'postgres';
		my $password = $ENV{PG_PASSWORD} // croak "Set PG_PASSWORD!";

		my $port = $ENV{PGPORT} // 5432;

		my $path = do {
			# connect to a remote Pg
			if( exists $ENV{PG_HOST} ) { $ENV{PG_HOST} }
			# connect to a local Pg through a unix domain socket
			# the socket isn't always in the same place. This uses
			# the default port
			else {
				my( $socket_path ) = grep { -S -e } (
					$ENV{PG_UNIX_SOCKET} // '',
					'/tmp/.s.PGSQL.5432',
					'/var/pgsql_socket/.s.PGSQL.5432',
					);
				url_escape( dirname($socket_path) )
				}
			};

		my $connection_string = "postgresql://$user:$password\@$path/minion";
		}

	sub connect ( $class ) {
		my $minion = Minion->new( Pg => $class->connection_string );
		}

	1;

I put *MyMinion.pm* in the current directory then `require` it so I can look for it in the current directory since [dot is no longer in @INC](https://www.effectiveperlprogramming.com/2017/01/v5-26-removes-dot-from-inc/). All the programs I write can start with the same short boilerplate:

	use v5.30;
	use warnings;

	require './MyMinion.pm';

	my $minion = MyMinion->connect;

I can monitor the backend with a short Mojo web app:

	# minion-admin.pl
	use Mojolicious::Lite;
	require './MyMinion.pm';

	# perl minion-admin.pl daemon

	plugin Minion => {
		Pg => MyMinion->connection_string,
			};

	plugin 'Minion::Admin', {
		route => app->routes->any('/'),
	};

	app->start;

This isn't necessary for the task but it makes pretty pictures. Along the top I see the inactive and active job counts along with the number of workers:

![](XXX: admin image)

## Make some jobs

The unit of work is a **job**. A job has a name and some arguments. A job doesn't specify what should happen, how it should happen, or who is going to do it. You can play with some job parameters, but I'm not going to do that here.

Now I make some jobs. I add those jobs to the backend by "enqueueing" them. I give the job a name, which can be just about any string that I like, and an array reference of arguments, which should be simple Perl values (not blessed references):

	# jobs.pl
	use v5.30;
	use warnings;

	require "./MyMinion.pm";

	my $minion = MyMinion->connect;

	for( my $i = 0; $i < $ARGV[0] // 100; $i++ ) {
		my @rands = map { int rand 100 } 0 .. (3+rand 5);
		$minion->enqueue( sum => \@rands );
		}

I run this program. It adds 100 jobs to Minion, but when I look at the admin interface, I see that they are inactive. Of course they are. I haven't told anything to work on these jobs. Not only that, but I haven't even defined what the job is. Minion doesn't care. It knows that at some other time there will be something that knows how to handle jobs named `sum`.

## Start some workers

A worker is something that "dequeues" a job, does the work, and gives the backend the result. You can have multiple workers all talking to the same backend.

Here's my first worker program. I connect to Minion in the same way, but this time I define a **task**. I can define the task any way that I like. In this case, I take the arguments and add them together then give the result to `finish`. This work happens on the machine that is running the worker program. For this example, I'm doing it on the same machine that enqueued the jobs:

	# worker-a.pl
	use v5.30;
	use warnings;
	use feature qw(signatures);
	no warnings qw(experimental::signatures);

	require "./MyMinion.pm";

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


That worker I run at the end of the program will keep working until I do something to stop it. It sticks around even after all the jobs have been processed. I can run the job queuer again to make more jobs:

![](XXX: admin image)

The worker notices the new jobs and starts working on those:

## Start a second worker

Now here's the slightly mind-bending part. I can start another worker to process the `sum` jobs, but it can have a completely different task definition. Instead of summing numbers, I accidentally multiply them. This doesn't matter. The job is a name and a list of arguments, not a task definition. The worker needs to know how to do it, but different workers don't need to use the same definition. Different workers should probably use the same definition, but that's up to you. Be careful!

	# worker-b.pl
	use v5.30;
	use warnings;
	use feature qw(signatures);
	no warnings qw(experimental::signatures);

	require "./MyMinion.pm";

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

When I run this, it will process jobs with the name `sum` if they are there. It's competing with the other worker.

## Start a remote worker

I start a remote worker on my Mac Pro. The same *./MyMinion.pm* knows how to connect to the right host:

	$ env PG_HOST=macbook.local perl worker-a.pl

I should see three workers in the admin portal now. It doesn't matter that this one is remote:

![](XXX: admin image)

Back on the local side, I create a bunch more jobs:

	$ perl jobs.pl

## Different jobs, different workers

So far I've added jobs with the same name and all of my workers have processed that single name. I can enqueue jobs with different names and different workers can handle the jobs they like:

	# multiple-jobs.pl
	use v5.30;
	use warnings;

	require "./MyMinion.pm";

	my $minion = MyMinion->connect;

	for( my $i = 0; $i < $ARGV[0] // 100; $i++ ) {
		my @rands = map { int rand 100 } 0 .. (3+rand 5);
		$minion->enqueue( sum => \@rands );
		$minion->enqueue( product => \@rands );
		$minion->enqueue( concat => \@rands );
		}

Here's a worker that handles just `sum`:

	# worker-sum.pl
	use v5.30;
	use warnings;
	use feature qw(signatures);
	no warnings qw(experimental::signatures);

	require "./MyMinion.pm";

	my $minion = MyMinion->connect;

	$minion->add_task( sum => sub ( $job, @args ) {
			sleep int rand 10;
			my $sum = 0;
			$sum += $_ for @args;
			$job->finish( $sum )
			} );

	$minion->worker->run;

And here's a completely different a worker that handles `product` and 	`concat`:

	# worker-product.pl
	use v5.30;
	use warnings;
	use feature qw(signatures);
	no warnings qw(experimental::signatures);

	require "./MyMinion.pm";

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

You've seen multiple workers and workers handling different sorts of jobs. How about a worker that creates more jobs? A job can have a **parent** and it won't run until that parent has finished, but that's not what I'm going to do here. Instead, I can enqueue more jobs inside the task. That's handy when you don't know which jobs might come next in a multistage process:

 	# worker-multistep.pl
	use v5.30;
	use warnings;
	use feature qw(signatures);
	no warnings qw(experimental::signatures);

	require "./MyMinion.pm";

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
			$minion->enqueue( three => [ "@args" ] );
			$job->finish( 'Done!' )
			} );
	$minion->worker->run;

## Conclusion

Employing Minion without Mojo is easy. Something create some jobs with `enqueue` and something processes those jobs with `add_task` and then running one or more workers.
