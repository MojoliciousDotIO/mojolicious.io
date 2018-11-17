---
title: "Day 5: Your App's Built-In Commands"
tags:
    - advent
    - command
    - debugging
    - administration
author: Joel Berger
images:
  banner:
    src: '/blog/2017/12/05/day-5-your-apps-built-in-commands/1200px-Rocket_prolant.jpg'
    alt: 'Space shuttle Atlantis liftoff'
    data:
      attribution: '<a href="https://commons.wikimedia.org/w/index.php?curid=44576486">Image</a> by <a href="//commons.wikimedia.org/w/index.php?title=User:Gsaisudha75&amp;action=edit&amp;redlink=1" title="User:Gsaisudha75 (page does not exist)">Gsaisudha75</a> (editor). For the original file: NASA/Scott Andrews - Derivative work of: <a href="//commons.wikimedia.org/wiki/File:STS-125_Atlantis_Liftoff_02.jpg" title="File:STS-125 Atlantis Liftoff 02.jpg">File:STS-125 Atlantis Liftoff 02.jpg</a> (while the modifications is Own work). Original file: <a rel="nofollow"  href="http://mediaarchive.ksc.nasa.gov/detail.cfm?mediaid=41220">http://mediaarchive.ksc.nasa.gov/detail.cfm?mediaid=41220</a>, <a href="https://creativecommons.org/licenses/by-sa/4.0" title="Creative Commons Attribution-Share Alike 4.0">CC BY-SA 4.0</a>'
data:
  bio: jberger
  description: Exploring the built-in commands that come with every Mojolicious Application.
---
I mentioned at the outset of this series that Mojolicious applications are more than just web servers.
I then showed how you can start a web server using the [`daemon`](http://mojolicious.org/perldoc/Mojolicious/Command/daemon) or [`prefork`](http://mojolicious.org/perldoc/Mojolicious/Command/prefork) commands.
In the previous post, I mentioned an [`inflate`](http://mojolicious.org/perldoc/Mojolicious/Command/inflate) command that can help you with growing your app from Lite to Full.

But there are other commands, built right in to your app, that can help you be more productive right away!
---
## Command Basics

Before I start, I want to briefly discuss the [`mojo`](http://mojolicious.org/perldoc/mojo) application/script that comes bundled with the Mojolicious distribution.
This command is a tiny Mojolicious app (actually another "hello world") which can be thought of as the "null app".
The built-in commands work both for your application and this null one, so use whichever is more appropriate.
When it doesn't matter which application runs a command, you can just use `mojo`.

Each command comes with a one-line description and a (possibly multi-line) usage statement.
To see the available commands, run `mojo help` and you will see all of the commands and their description.
You should see something like this:

    $ mojo help
    Usage: APPLICATION COMMAND [OPTIONS]

      mojo version
      mojo generate lite_app
      ./myapp.pl daemon -m production -l http://*:8080
      ./myapp.pl get /foo
      ./myapp.pl routes -v

    Tip: CGI and PSGI environments can be automatically detected very often and
        work without commands.

    Options (for all commands):
      -h, --help          Get more information on a specific command
          --home <path>   Path to home directory of your application, defaults to
                          the value of MOJO_HOME or auto-detection
      -m, --mode <name>   Operating mode for your application, defaults to the
                          value of MOJO_MODE/PLACK_ENV or "development"

    Commands:
    cgi       Start application with CGI
    cpanify   Upload distribution to CPAN
    daemon    Start application with HTTP and WebSocket server
    eval      Run code against application
    generate  Generate files and directories from templates
    get       Perform HTTP request
    inflate   Inflate embedded files to real files
    prefork   Start application with pre-forking HTTP and WebSocket server
    psgi      Start application with PSGI
    routes    Show available routes
    test      Run tests
    version   Show versions of available modules

    See 'APPLICATION help COMMAND' for more information on a specific command.

As it says, you can now see the more detailed information on each command by running `mojo help COMMAND` for one of those commands.

## The Built-In Commands

Since we've already briefly discussed [deployment](http://mojolicious.org/perldoc/Mojolicious/Guides/Cookbook#DEPLOYMENT) I'll skip over the servers this time, including the [`cgi`](http://mojolicious.org/perldoc/Mojolicious/Command/cgi) and [`psgi`](http://mojolicious.org/perldoc/Mojolicious/Command/psgi) commands.
Similarly I'll skip the `inflate` command.
In the interest of space, I'll skip the [`test`](http://mojolicious.org/perldoc/Mojolicious/Command/test) command that simply runs your application's tests like [prove](https://metacpan.org/pod/prove).
I'll also skip [`cpanify`](http://mojolicious.org/perldoc/Mojolicious/Command/cpanify) which lets CPAN authors upload modules to CPAN (I use it all the time).

### The generate Command

Perhaps the first command you use should be the [`generate`](http://mojolicious.org/perldoc/Mojolicious/Command/generate) command.
It lets you generate a new application (or other) project skeleton from templates.

It has a few subcommands, including one for generating each type of app.
To create a [Lite app](http://mojolicious.org/perldoc/Mojolicious/Command/generate/lite_app), pass the name of the script to create

    $ mojo generate lite_app myapp.pl

To create a [Full app](http://mojolicious.org/perldoc/Mojolicious/Command/generate/app), pass the name of the class

    $ mojo generate app MyApp

You can also create a [plugin project](http://mojolicious.org/perldoc/Mojolicious/Command/generate/plugin) or [generate a Makefile](http://mojolicious.org/perldoc/Mojolicious/Command/generate/makefile).

There is some more to say on the subject of file generation, but since this is an overview post, I'll leave it at that for now.

### The version Command

The [`version`](http://mojolicious.org/perldoc/Mojolicious/Command/version) command is a simple utility to check your Mojolicious installation.

It outputs your current version of Perl and Mojolicious along with any installed optional libraries.
For example, you'll want to install [IO::Socket::SSL](https://metacpan.org/pod/IO::Socket::SSL) if you want to fetch or serve sites over HTTPS.
It then checks to see if there is an updated version of Mojolicious available.

### The routes Command

Once you started writing your application, you might want to introspect it a little bit, especially for debugging purposes.
The most straightforward command of that nature is [`routes`](http://mojolicious.org/perldoc/Mojolicious/Command/routes).
Simply run it on your app to see what routes you have defined.

For example, we can run it on Santa's application from [day 3](/blog/2017/12/03/day-3-using-named-routes).

    $ perl santa.pl routes
    /toy/:toy_name  GET  "toy"
    /meet/:name     GET  "staff"
    /               GET  "home"

This shows you the three routes that were defined.
It shows the paths for each route including their placeholders, that all three handle GET, and their route name.
Using this output is especially helpful when using named routes, as we learned in that post; all the information you need is right in that table!

We can go a little deeper and ask for verbose output by adding a flag

    $ perl santa.pl routes -v
    /toy/:toy_name  ....  GET  "toy"    ^\/toy/([^/.]+)/?(?:\.([^/]+))?$
    /meet/:name     ....  GET  "staff"  ^\/meet/([^/.]+)/?(?:\.([^/]+))?$
    /               ....  GET  "home"   ^/?(?:\.([^/]+))?$

This output includes all the same stuff as before but this time it also adds a few extra items.
Certain routes are more complex, and while all these were simple and so no flags are shown, if one were an `under` route or a `websocket` it would be noted where the `....` are.
Finally it includes a pattern that is what is actually matched by the router.
This can be helpful sometimes when debugging why certain requests match (or more likely don't match) a certain route.
Note that the router checks each route in order top to bottom, the first to match is what is used.

### The get Command

Now we're getting to the fun stuff!

Mojolicious comes with a [user agent](http://mojolicious.org/perldoc/Mojo/UserAgent) and lots of post-processing power, including [HTML/XML](http://mojolicious.org/perldoc/Mojo/DOM) and [JSON](http://mojolicious.org/perldoc/Mojo/JSON) parsers.
This command exposes those features together on the command line, like a smart version of cURL or wget.

Output is written to STDOUT so that you can redirect the result to a file if you'd like.
Because of that, headers are omitted from the output unless you pass `-v`.

Let's see what it can do!
You can find the latest version of `IO::Socket::SSL` using the [Meta::CPAN JSON API](https://github.com/metacpan/metacpan-api/blob/master/docs/API-docs.md).
The response is parsed as JSON and only the `version` element is output.

    mojo get https://fastapi.metacpan.org/v1/module/IO::Socket::SSL /version

You can fetch the Perl headlines from reddit.
To do so we fetch the url (following redirects with `-r`), then we give it a [CSS3 selector](http://mojolicious.org/perldoc/Mojo/DOM/CSS), and finally extract the text from each found element.

    mojo get -r reddit.com/r/perl 'p.title > a.title' text

How fun is that?!

  - You can POST or PUT or DELETE data.
  - It handles HTTP basic authentication using `username:password@` in the URL.
  - You can submit forms, even with file uploads using the standard `@filename` syntax.
  - You can pipe data to the command if you just want to send the raw contents of a file rather than url-encode it.
  - See lots more examples in the [documentation](http://mojolicious.org/perldoc/Mojolicious/Command/get#SYNOPSIS).

But I haven't even touched on its coolest feature yet.
This command also works on your application when you request a relative url.
This is so handy for debugging requests during rapid development; you don't even need a browser!

    perl santa.pl get /meet/rudolph 'p' text

### The eval Command

Finally in this whirlwind tour, I'll show you my favorite command.
The [`eval`](http://mojolicious.org/perldoc/Mojolicious/Command/eval) command.
This command has the magic power to run one-off commands using your application!
The application is available as `app` in your one-liner.

So say you can't figure out what is wrong with your configuration, just ask it to dump what it thinks its configuration is

    perl myapp.pl eval -v 'app->home'
    perl myapp.pl eval -V 'app->config'

The `-v` flag prints the string result of the last statement to STDOUT, the `-V` flag does the same but for data structures.
Maybe you want to see why it can't find your templates.

    perl myapp.pl eval -V 'app->renderer->paths'

This is especially helpful once you have database interactions setup via some model layer.
If you want to see the result for some query, just check.

    perl myapp.pl eval -V 'app->model->users->find({name => "Joel"})'

Though of course that will depend on how your model layer works.
Or maybe you want to deploy your schema, or roll it back.

    perl myapp.pl eval 'app->pg->migrations->migrate'

Or just check that the database is reachable.

    perl myapp.pl eval -V 'app->pg->db->query("SELECT NOW()")->hash'

These last two database examples assumed that your app was using [Mojo::Pg](http://mojolicious.org/perldoc/Mojo/Pg) but similar one-liners could work for any database that your app knows about.

There really is nothing like debugging or administering your application without having to copy and paste a bunch of your logic from your app to some script.
Although if you really find yourself using the `eval` command for the same tasks often ... well that should wait until tomorrow.

