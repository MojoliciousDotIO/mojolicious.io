---
status: published
title: Who Watches The Minions
disable_content_template: 1
tags:
    - advent
    - development
author: Doug Bell
images:
  banner:
    src: '/blog/2018/12/29/who-watches-the-minions/banner.jpg'
    alt: 'Minion logo in the middle of binocular circles, original artwork by Doug Bell'
    data:
      attribution: |-
        Original artwork by Doug Bell, released under CC-BY-SA 4.0. It includes
        the Minion logo (CC-BY-SA 4.0)
data:
  bio: preaction
  description: 'Check the status of a Minion job queue using commands and the Minion::Admin UI'
---

Now that I have a [Minion job
queue](https://mojolicious.org/perldoc/Minion), I need to take care of
it properly. Are the workers working (have they seized the means of
production)? Are jobs completing successfully? Are there any errors?
What are they?

## Minion Jobs Command

Minion comes with a [`job`
command](https://mojolicious.org/perldoc/Minion/Command/minion/job) that
lists the jobs and their statuses.

    $ perl myapp.pl minion job
    6  inactive  default  check_url
    5  active    default  check_url
    4  failed    default  check_url
    3  failed    default  check_url
    2  finished  default  check_url
    1  finished  default  check_url

I can look at an individual job's information by passing in the job's
ID.

    $ perl minion.pl minion job 1
    {
      "args" => [
        "http://mojolicious.org"
      ],
      "attempts" => 1,
      "children" => [],
      "created" => "2018-11-23T19:15:47Z",
      "delayed" => "2018-11-23T19:15:47Z",
      "finished" => "2018-11-23T19:15:48Z",
      "id" => 1,
      "notes" => {},
      "parents" => [],
      "priority" => 0,
      "queue" => "default",
      "result" => "0.0716841220855713",
      "retried" => undef,
      "retries" => 0,
      "started" => "2018-11-23T19:15:47Z",
      "state" => "finished",
      "task" => "check_url",
      "worker" => 1
    }

But, it'd be a lot nicer if I didn't have to open a terminal, open an
SSH connection, and run a command to look at the status of my Minion.

## Minion Admin UI

I said I didn't have a web application, and I don't. But if I want
a simple web application to check on the status of the Minion workers
and read the results of jobs, Minion comes with [an Admin UI
plugin](https://mojolicious.org/perldoc/Mojolicious/Plugin/Minion/Admin).

I can add the Minion::Admin plugin the same way I added the Minion
plugin:

    use Mojolicious::Lite;
    plugin Minion => {
        SQLite => 'sqlite:' . app->home->child('minion.db'),
    };
    plugin 'Minion::Admin', {
        # Host Admin UI at /
        route => app->routes->any('/'),
    };
    app->start;

Once I add the plugin, I now have a web application that I can run with
the [Mojolicious `daemon`
command](https://mojolicious.org/perldoc/Mojolicious/Command/daemon).

    $ perl myapp.pl daemon
    Server available at http://127.0.0.1:3000

Now I can access the Minion UI:

![A web browser showing the main Minion UI screen with charts showing
the status of running jobs](01-main.png)

The main page shows the current status. The links at the top show lists
of jobs in the given state, any locks that exist, and the workers.

![A web browser showing a list of jobs in the "finished"
state](02-job-list.png)

When looking at a list of jobs, I can click the buttons on top left to
manage the job queue, or click on the caret on the right of each job row
to view the details of that job (the same as the `job` command shows).

![A web browser showing the details of a single Minion job as
JSON](03-job-details.png)

The Minion Admin UI is a great addition to a great tool! [View the entire
source of the Minion app](minion.pl)
