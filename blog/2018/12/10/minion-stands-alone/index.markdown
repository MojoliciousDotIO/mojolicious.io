---
title: Day 10: Minion Stands Alone
disable_content_template: 1
tags:
    - advent
    - minion
author: Doug Bell
images:
  banner:
    src: '/blog/2018/12/10/minion-stands-alone/banner.jpg'
    alt: 'Minion logo in front of a faded Mojolicious cloud, original artwork by Doug Bell'
    data:
      attribution: |-
        Original artwork by Doug Bell, released under CC-BY-SA 4.0. It includes
        a screenshot of the Mojolicious.org website (fair use), the Mojolicious
        logo (CC-BY-SA 4.0), and the Minion logo (CC-BY-SA 4.0)
data:
  bio: preaction
  description: 'Learn how to use the Minion job queue without needing a Mojolicious web application'
---

The [Minion job queue](https://mojolicious.org/perldoc/Minion) is an
incredibly useful tool, but sometimes I need to use it for non-web
projects. So, how can I use Minion without needing
a [Mojolicious](http://mojolicious.org) web application?
---

If I don't have a large enough set of jobs to need the task organization
provided by [Beam::Minion](https://metacpan.org/pod/Beam::Minion), and although
Minion can be used as a [fully stand-alone
library](https://mojolicious.org/perldoc/Minion#SYNOPSIS), the easiest solution
is just to build a Mojolicious app. Lucky for me, a Mojolicious app can be just
2 lines:

    use Mojolicious::Lite;
    app->start;

Now, if I never run a web daemon, this will never be a website. So, can
this be called a web application if nobody ever uses a web browser to
access it? 🤔

## Add Minion

To use Minion, add the Minion plugin to the app. For this example, I'll
use [the SQLite Minion
backend](https://metacpan.org/pod/Minion::Backend::SQLite) so that
I don't need a separate database process running, but Minion can work
across multiple machines if you have a database that accepts remote
connections.

    plugin Minion => {
        SQLite => 'sqlite:' . app->home->child('minion.db'),
    };

With the Minion plugin loaded, my application gains some new features:

* I can add Minion tasks (runnable bits of code) with the
  [`minion.add_task`](https://mojolicious.org/perldoc/Minion#add_task)
  helper
* I can enqueue jobs in multiple ways:
    * From the command-line with [the `minion job`
      command](https://mojolicious.org/perldoc/Minion/Command/minion/job)
    * From inside the application with [the `minion.enqueue`
      helper](https://mojolicious.org/perldoc/Minion#enqueue1)
    * From any Perl script by loading Minion and using [the enqueue
      method](https://mojolicious.org/perldoc/Minion#enqueue1)
* I can run a Minion worker with [the `minion worker`
  command](https://mojolicious.org/perldoc/Minion/Command/minion/worker),
  which will execute any enqueued jobs

## Create a Task

I'll create a task called `check_url` to check how long it takes to
download a URL. The
[Time::HiRes](https://perldoc.perl.org/Time/HiRes.html) core module will
give me high resolution times.

    #!/usr/bin/env perl

    use v5.28;
    use Mojolicious::Lite;
    use experimental qw( signatures );
    use Time::HiRes qw( time );

    plugin Minion => {
        SQLite => 'sqlite:' . app->home->child('minion.db'),
    };

    app->minion->add_task(
        check_url => sub( $job, $url ) {
            my $start = time;
            my $tx = $job->app->ua->head( $url );
            my $elapsed = time - $start;
            $job->app->log->info(
                sprintf 'Fetching %s took %.3f seconds', $url, $elapsed
            );
            # If there's an error loading the web page, fail the job
            if ( $tx->error ) {
                $job->app->log->error(
                    sprintf 'Error loading URL (%s): %s (%s)',
                        $url, @{ $tx->error }{qw( code message )},
                );
                return $job->fail(
                    sprintf '%s: %s', @{ $tx->error }{qw( code message )}
                );
            }
            $job->finish( $elapsed );
        },
    );

    app->start;

## Enqueuing Jobs

Now that I have a task, I can enqueue some jobs. I can add jobs using
[the `minion job`
command](https://mojolicious.org/perldoc/Minion/Command/minion/job):

    $ perl myapp.pl minion job -e check_url -a '["http://mojolicious.org"]'

Or from inside of another Perl script by loading Minion and using [the
enqueue method](https://mojolicious.org/perldoc/Minion#enqueue1):

    #!/usr/bin/env perl
    use Minion;
    my $minion = Minion->new(
        SQLite => 'sqlite:minion.db', # The same database as the worker
    );
    $minion->enqueue(
        check_url => ['http://mojolicious.org'],
    );

## Running a Worker

I've enqueued jobs, but nothing's happening, and nothing will happen
until I run a worker using [the `minion worker`
command](https://mojolicious.org/perldoc/Minion/Command/minion/worker):

    $ perl myapp.pl minion worker

Once the worker starts up, it will immediately begin processing the jobs
I told it to run.

And that's it! I'm using Minion without a Mojolicious
web application. View the source of the [Minion app](minion.pl) and the
[enqueue.pl script](enqueue.pl).

