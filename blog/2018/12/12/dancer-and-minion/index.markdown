---
title: Day 12: Using Minion in Dancer Apps
disable_content_template: 1
tags:
    - advent
    - development
    - dancer
    - minion
author: Jason Crome
data:
  bio: cromedome
  description: 'Overview of how to use Minion from within a Dancer application.'

---

At `$work`, we have built an API with Dancer that generates PDF documents and XML files. This API is a critical component of an insurance enrollment system: PDFs are generated to deliver to the client in a web browser 
immediately, and the XML is delivered to the carrier as soon as it becomes available. Since the XML often takes a significant amount of time to generate, the job is generated in the background so as not to tie up the 
application server for an extended amount of time. When this was done, a homegrown process management system was developed, and works by `fork()`ing a process, tracking its pid, and hoping we can later successfully
reap the completed process. 

There have been several problems with this approach:
- it's fragile
- it doesn't scale
- it's too easy to screw something up as a developer

In 2019, we have to ramp up to take on a significantly larger workload. The current solution simply will not handle the amount of work we anticipate needing to handle. Enter Minion.

*Note:* The techniques used in this article work equally well with Dancer or Dancer2.

---

## Why Minion?

We looked at several alternatives to Minion, including [beanstalkd](https://beanstalkd.github.io/) and [celeryd](http://www.celeryproject.org/). Using either one of these meant involving our already over-taxed
infrastructure team, however; using Minion allowed us to use expertise that my team already has without having to burden someone else with assisting us. From a development standpoint, using a product that
was developed in Perl gave us the quickest time to implementation. 

Scaling our existing setup was near impossible. It's not only not easy to get a handle on what resources are consumed by processes we've forked, but it was impossible to run the jobs on more than one server. 
Starting over with Minion also gave us a much needed opportunity to clean up some code in sore need of refactoring. With a minimal amount of work, we were able to clean up our XML rendering code and make it work
from Minion. This cleanup allowed us to more easily get information as to how much memory and CPU was consumed by an XML rendering job. This information is vital for us in planning future capacity.

## Accessing Minion

Since we are a Dancer shop, and not Mojolicious, a lot of convenience you'd get from Mojolicious for working with Minion isn't as available to us. Given we are also sharing some Minion-based
code with our business models, we had to build some of our own plumbing around Minion:

    package MyJob::JobQueue;

    use Moose;
    use Minion;

    use MyJob::Models::FooBar;
    with 'MyJob::Roles::ConfigReader';

    my @QUEUE_TYPES = qw( default InstantXML PayrollXML ChangeRequest );

    has 'runner' => (
        is      => 'ro',
        isa     => 'Minion',
        lazy    => 1,
        default => sub( $self ) {
            $ENV{ MOJO_PUBSUB_EXPERIMENTAL } = 1;
            Minion->new( mysql => MyJob::DBConnectionManager->new->get_connection_uri({ 
                db_type => 'feeds', 
                io_type => 'rw',
            }));
        },
    );

    sub has_invalid_queues( $self, @queues ) {
        return 1 if $self->get_invalid_queues( @queues );
        return 0;
    }

    sub get_invalid_queues( $self, @queues ) {
        my %queue_map;
        @queue_map{ @QUEUE_TYPES } = (); 
        my @invalid_queues = grep !exists $queue_map{ $_ }, @queues;
        return @invalid_queues;
    }

    sub run_job( $self, $args ) {
        my $job_name = $args->{ name     } or die "run_job(): must define job name!";
        my $guid     = $args->{ guid     } or die "run_job(): must have GUID to process!";
        my $title    = $args->{ title    } // $job_name;
        my $queue    = $args->{ queue    } // 'default';
        my $job_args = $args->{ job_args };

        die "run_job(): Invalid job queue '$queue' specified" if $self->has_invalid_queues( $queue );

        my %notes = ( title => $title, guid  => $guid );

        return $self->runner->enqueue( $job_name => $job_args => { notes => \%notes, queue => $queue });
    }

    1;

## Creating Jobs

In our base model class (Moose-based), we would create an attribute for our job runner:

    has 'job_runner' => (
        is      => 'ro',
        isa     => 'Empowered::JobQueue',
        lazy    => 1,
        default => sub( $self ) { return Empowered::JobQueue->new->runner; },
    );

And in the models themselves, creating a new queueable task was as easy as:

    $self->runner->add_task( InstantXML => sub( $job, $request_path, $guid, $company_db, $force, $die_on_error = 0 ) {
        $job->note( 
            request_path => $request_path,
            feed_id      => 2098,
            group        => $company_db,
        );
        MyJob::Models::FooBar->new( request_path => $request_path )->generate_xml({
            pdf_guid     => $guid,
            group        => $company_db,
            force        => $force,
            die_on_error => $die_on_error,
        });
    });


## Running Jobs

Starting a job from Dancer was super easy:

    use Dancer2;
    use MyJob::JobQueue;

    sub job_queue {
        return MyJob::JobQueue->new;
    }

    get '/my/api/route/:guid/:group/:force' => sub {
        my $guid  = route_parameters->get( 'guid' );
        my $group = route_parameters->get( 'group' );
        my $force = route_parameters->get( 'force' );

        debug "GENERATING XML ONLY FOR $guid";
        job_queue->run_job({
            name     => "InstantXML",
            guid     => $guid,
            title    => "Instant XML Generator",
            queue    => 'InstantXML',
            job_args => [ $self->request_path, $guid, $group, $force ],
        }); 
    }

## Creating and Configuring the Job Queue Worker

We wanted to easily configure our Minions for all hosts and environments in one spot. Since we use a lot of YAML in Dancer, specifying the Minion configuration in YAML made a lot of sense
to us:

    # What port does the dashboard listen on?
    dashboard_port: 4000

    # Add the rest later.
    dashboards:
        UNKNOWN: http://localhost:3000/
        DEV: http://my.development.host.tld:8001/

    # Hosts that have no entry assume the default configuration
    default:
        max_children: 4
        queues:
            - default

    # Host-specific settings
    jcrome-precision-3510:
        max_children: 8
        queues:
            - default
            - InstantXML
            - PayrollXML
            - ChangeRequest

Our job queue workers look like:

    #!/usr/bin/env perl

    use MyJob::Base;
    use MyJob::JobQueue;
    use MyJob::Log4p;
    use MyJob::Util::Logger;
    use MyJob::Util::SysTools qw(get_hostname);

    use Mojo::mysql;

    my $config     = MyJob::Config->new->config;
    my $hostconfig = get_hostconfig();
    my $minion     = MyJob::JobQueue->new;
    my $worker     = $minion->runner->worker;

    my $log_eng = MyJob::Log4p->new({ logger_name => "Minion" });
    my $logger  = MyJob::Util::Logger->new->logger($log_eng);

    $worker->on( dequeue => sub( $worker, $job ) {
        my $id    = $job->id;
        my $notes = $job->info->{ notes };
        my $title = $notes->{ title };
        my $guid  = $notes->{ guid };

        $job->on( spawn => sub( $job, $pid ) {  
            $0 = "$title $guid";
            $logger->info( "$title: Created child process $pid for job $id by parent $$ - $guid");
        });
        
        $job->on( failed => sub( $job, $error ) {
            chomp $error;
            $logger->error( $error );
        });
    });

    $worker->on( busy => sub( $worker ) {
        my $max = $worker->status->{ jobs };
        $logger->log( "$0: Running at capacity (performing $max jobs)." );
    });

    my $max_jobs = $hostconfig->{ max_children };
    my @queues   = @{ $hostconfig->{ queues }};

    if( $minion->has_invalid_queues( @queues ) ){
        print "Invalid job queues specified: " . join( ',', $minion->get_invalid_queues( @queues ) );
        say ". Aborting!";
        exit 1;
    }

    say "Starting Job Queue Worker on " . get_hostname();
    say "- Configured to run a max of $max_jobs jobs";
    say "- Listening for jobs on queues: ", join(', ', @queues );
    $worker->status->{ jobs }   = $max_jobs;
    $worker->status->{ queues } = \@queues;
    $worker->run;

    sub get_hostconfig {
        my $minion_config = MyJob::Config->new({ filename => "environments/minions.yml" })->config;
        my $hostname      = get_hostname();

        if( exists $minion_config->{ $hostname }) {
            return $minion_config->{ $hostname };
        } else {
            return $minion_config->{ default };
        }
    }

## Monitoring the Workers

Our Minion dashboard was virtually identical to the one that @preaction posted in [Who Watches the Minions?](https://mojolicious.io/blog/2018/12/11/who-watches-the-minions/#section-2).
If you'd like to know more, I highly recommend reading his article.

## Outcome

Within about a two-week timespan, we went from having zero practical knowledge of Minion to having things up and running. We've made some refinements and improvements along the way, but the quick turnaround
is a true testament to the simplicity of working with Minion. 

We now have all the necessary pieces in place to scale our XML rendering both horizontally and vertically: thanks to Minion, we can easily run XML jobs across multiple boxes, and can more efficiently run 
more jobs concurrently on the same hardware as before. This setup allows us to grow as quickly as our customer base does.

## Further Reading

* [Dancer](https://metacpan.org/pod/Dancer)
* [Dancer2](https://metacpan.org/pod/Dancer2)
* [Minion](https://metacpan.org/pod/Minion)

