---
title: 'Day 6: Adding Your Own Commands'
tags:
    - advent
    - command
    - example
author: Joel Berger
images:
  banner:
    src: '/static/1280px-Brightly_lit_STS-135_on_launch_pad_39a.jpg'
    alt: 'Space shuttle Atlantis prepared for liftoff (night)'
    data:
      attribution: |-
        <a href="https://commons.wikimedia.org/w/index.php?curid=15739462">Image</a>
        by Bill Ingalls - <a rel="nofollow" href="http://www.flickr.com/photos/nasahqphoto/5914101671/in/photostream/">http://www.flickr.com/photos/nasahqphoto/5914101671/in/photostream/</a>, Public Domain.
data:
  bio: jberger
  description: Adding commands to your app to ease administration and avoid auxiliary scripts.
---
Everyone has written those one-off administration or check scripts.
There are probably a few cluttering your project root or bin directory right now.
Those have a problem beyond just the clutter: duplication.

Programmers hate duplication because of skew.
If code gets improved in one place, it is unlikely to be improved in all places, unless there is only the one.
So that script you wrote a while back, the one with the database connection you hand-rolled, is that still correct?

In the [previous article in this series](/blog/2017/12/05/day-5-your-apps-built-in-commands) I talked about the built-in commands available to your application.
The final command was [`eval`](http://mojolicious.org/perldoc/Mojolicious/Command/eval).
I mentioned that when combined with predefined behaviors, the command could be great for administrative tasks.
That's true, but you need to know what to eval in order to do so.

To formalize that process, we can go one step further: defining our own commands.
By doing this your application's administative behaviors can take arguemnts and provide optional switches as well as give usage messages.
In this way these administative commands decouple themselves from knowledge of the application's internals and become useful to a broader set of users.
---
## What is a Command?

Structurally, a command is just a class that inherits from [Mojolicious::Command](http://mojolicious.org/perldoc/Mojolicious/Command) and implements a `run` method.
The method is passed an instance of the command class and the arguments given on the command line.
The command has the application as an attribute.
Just as the `eval` command demonstrated, the real power of the command comes from having access to an instance of the application, including its relevant configuration and methods.

By default your application looks for available commands in the namespace `Mojolicious::Command`.
As we saw before, several are available built-in to the system.
However others are available from CPAN, for example, I have a [nopaste clone](https://metacpan.org/pod/Mojolicious::Command::nopaste) that when installed is available via your application or the `mojo` executable.

Your application can add to or even replace the default namespace search path by setting [`app->commands->namespaces`](http://mojolicious.org/perldoc/Mojolicious#commands).
My [Galileo](https://metacpan.org/pod/Galileo) CMS adds a command namespace so that its deploy command is available as `galileo deploy` but not as `mojo deploy`.
Meanwhile plugins that your app loads can add to the namespaces.
The [Minion](http://mojolicious.org/perldoc/Minion) job queue is added to your application as a plugin, it appends `Minion::command` to your command namespaces so that your application has access to the minion commands like starting workers or checking status.

## Let's Build a Weather App

Rather than give several small examples I'm going to change it up this time and give one big example.
It will be ok if you don't understand every line, I'm skipping a few pedagogical steps to make this example.

Why don't we build a weather caching app?
I've put the entire thing on github at <https://github.com/jberger/MyWeatherApp>.
I'm going to copy portions of the code into this article for clarity, but consider that that site is probably the most up to date.

Of course, we'll need some data.
I've chosen to use <https://openweathermap.org/>
To do run this you'll need to sign up for a [free account](http://home.openweathermap.org/users/sign_up).
It only needs an email address, I tried but I really couldn't find a totally open access weather API.
From there you can get an API key, which will need to go in a configuration file.
Once you have it create a configuration file called `myweatherapp.conf` and fill it in like so:

    {
      appid => 'XXXXXXXXX',
    }

### The Script

First you will need the script, a wrapper to start the application.
Let's call it [bin/myweatherapp](https://github.com/jberger/MyWeatherApp/blob/master/bin/myweatherapp).
It should be exactly

    #!/usr/bin/env perl

    use strict;
    use warnings;

    use FindBin;
    BEGIN { unshift @INC, "$FindBin::Bin/../lib" }
    use Mojolicious::Commands;

    # Start command line interface for application
    Mojolicious::Commands->start_app('MyWeatherApp');

### The Model

Now let's make a model class.
A model is the business logic of any application.
It knows how to do the important work and should be free of anything to do with your actual site.

We'll store it in [lib/MyWeatherApp/Model/Weather.pm](https://github.com/jberger/MyWeatherApp/blob/master/lib/MyWeatherApp/Model/Weather.pm).

    package MyWeatherApp::Model::Weather;
    use Mojo::Base -base;

    use Carp ();
    use Mojo::URL;
    use Mojo::UserAgent;

    has appid  => sub { Carp::croak 'appid is required' };
    has sqlite => sub { Carp::croak 'sqlite is required' };
    has ua     => sub { Mojo::UserAgent->new };
    has 'units';

    sub fetch {
      my ($self, $search) = @_;
      my $url = Mojo::URL->new('http://api.openweathermap.org/data/2.5/weather');
      $url->query(
        q => $search,
        APPID => $self->appid,
        units => $self->units || 'metric',
      );
      return $self->ua->get($url)->result->json;
    }

    sub insert {
      my ($self, $search, $result) = @_;
      $self->sqlite->db->query(<<'  SQL', $search, $result->{dt}, $result->{main}{temp});
        INSERT INTO weather (search, time, temperature)
        VALUES (?, ?, ?)
      SQL
    }

    sub recall {
      my ($self, $search) = @_;
      $self->sqlite->db->query(<<'  SQL', $search)->hashes;
        SELECT time, temperature
        FROM weather
        WHERE search=?
        ORDER BY time ASC
      SQL
    }

    1;

It is just a class with a few methods that know how to look up and store weather data.
The class has two required attributes, `sqlite` and `appid`.
Whoever instantiates this class will need to pass them in.

The fetch method builds a URL from attributes and a passed-in search term.
It then requests the data from OpenWeatherMap.
The `result` method dies if there is a connection error.
For brevity I'm being a little lax on other error checking.

The other two methods insert data into sqlite and recall it out again, again based on a search term.
This is basically just caching the data from OpenWeatherMap
Again for brevity I'm only storing the term, the time, and the temperature.

### The Application

Once we have an application we can start to make try it out a little.
The main class is at [lib/MyWeatherApp.pm](https://github.com/jberger/MyWeatherApp/blob/master/lib/MyWeatherApp.pm).

    package MyWeatherApp;
    use Mojo::Base 'Mojolicious';

    use Mojo::SQLite;
    use MyWeatherApp::Model::Weather;

    has sqlite => sub {
      my $app = shift;
      my $file = $app->config->{file} // 'weather.db';
      my $sqlite = Mojo::SQLite->new("dblite:$file");
      $sqlite->migrations->from_data;
      return $sqlite;
    };

    sub startup {
      my $app = shift;

      $app->moniker('myweatherapp');
      $app->plugin('Config');

      push @{ $app->commands->namespaces }, 'MyWeatherApp::Command';

      $app->helper('weather' => sub {
        my $c = shift;
        my $config = $c->app->config;
        return MyWeatherApp::Model::Weather->new(
          sqlite => $app->sqlite,
          appid => $config->{appid},
          units => $config->{units} || 'metric',
        );
      });

      my $r = $app->routes;
      $r->get('/weather')->to('Weather#recall');
    }

    1;

    __DATA__

    @@ migrations

    -- 1 up

    CREATE TABLE weather (
      id INTEGER PRIMARY KEY,
      search TEXT NOT NULL,
      time DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
      temperature REAL NOT NULL
    );

    -- 1 down

    DROP TABLE IF EXISTS weather;

This class does a few important things.
It defines a connection to a SQLite configurable database.
It then defines the all-important `startup` method.
This method is what is run when the application is first instantiated.

It defines the moniker, which in turn defines the configuration file name.
It then loads configuration; this is necessary since we need your appid for OpenWeatherMap.
It tells the app that we are going to define some application-specific commands under [MyWeatherApp::Command](https://github.com/jberger/MyWeatherApp/tree/master/lib/MyWeatherApp/Command).

Then there's something I haven't shown you before, a helper.
Helpers are like methods but they are available to the app and the controllers and even to templates.
They always receive a controller, even if they are called on the app.
Helpers are very useful for tying parts of your application together.
In this case we use one to build and return an instance of our model class.
It attaches that required data that we noted earlier.

Moving on, the application now defines a route.
As we'll see later it is attached to the [Weather controller class](https://github.com/jberger/MyWeatherApp/blob/master/lib/MyWeatherApp/Controller/Weather.pm) and more specifically its `recall` action method.
This is much like the action callbacks we saw before, but by keeping it in a separate class the application class is easier to read.

Finally we define the database schema.
This is a format common to the Mojo-flavored database modules, like [Mojo::Pg](http://mojolicious.org/perldoc/Mojo/Pg), [Mojo::mysql](https://metacpan.org/pod/Mojo::mysql), and [Mojo::SQLite](https://metacpan.org/pod/Mojo::SQLite).
Each section is defined with a version number and the word `up` or `down`.
When migrating versions, it will apply each change set from the current version (beginning at 0) until the version you request.
If you don't request a version it gets the highest version.

Noe that all that is done, we can try it out!

    $ perl bin/myweatherapp eval -V 'app->weather->fetch("Chicago")'

If you've configured your appid correctly you should get a dump of weather data about my home city.

### The Commands

Well finally we have arrived at the whole reason we started this endeavour: the commands!

This example has two different uses for commands.
The first use is to deploy our database schema or to upgrade it should it change.
This would likely be run by an operations manager or configuration management software when installing or upgrading.
The command exists in [lib/MyWeatherApp/Command/deploy.pm](https://github.com/jberger/MyWeatherApp/blob/master/lib/MyWeatherApp/Command/deploy.pm).

    package MyWeatherApp::Command::deploy;
    use Mojo::Base 'Mojolicious::Command';

    use Mojo::Util 'getopt';

    has 'description' => 'Deploy or update the MyWeatherApp schema';
    has 'usage' => <<"USAGE";
    $0 deploy [OPTIONS]
    OPTIONS:
      -v , --verbose  the version to deploy
                      defaults to latest
    USAGE

    sub run {
      my ($self, @args) = @_;

      getopt(
        \@args,
        'v|version=i' => \my $version,
      );

      my $app = $self->app;
      $app->sqlite->migrations->migrate(defined $version ? $version : ());
    }

    1;

The second use is to fetch and store the data in the database.
This could be run manually, but more likely this could be run by cron to regularly keep the database up to date.
It is located at [lib/MyWeatherApp/Command/fetch_weather.pm](https://github.com/jberger/MyWeatherApp/blob/master/lib/MyWeatherApp/Command/fetch_weather.pm).

    package MyWeatherApp::Command::fetch_weather;
    use Mojo::Base 'Mojolicious::Command';

    has description => 'Fetch and cache the current weather';
    has usage => <<"USAGE";
    $0 fetch_weather [SEARCH, ...]

    All arguments are search terms.
    If none are given, the "search" field in the configuration is used.
    USAGE

    sub run {
      my ($self, @args) = @_;
      my $app = $self->app;

      unless (@args) {
        @args = @{ $app->config->search || [] };
      }

      for my $search (@args) {
        my $result = $app->weather->fetch($search);
        $app->weather->insert($search, $result);
      }
    }

    1;

Now you can see that both of these commands are fairly simple.
Indeed they **could** be done by smart use of the `eval` command.
But see how the `deploy` command can take an optional version parameter.
Similarly the `fetch_weather` command can either take search terms on the command line or get them from the configuration file.
And both have a description and usage information to help a new user understand how they work.
Try running

    $ perl bin/myweatherapp help

You should see those commands listed (you shouldn't see them via `mojo help`).
To load some data try running

    $ perl bin/myweatherapp fetch_weather Seattle

This should populate some data into the database.
Run it a few times if you want or for a few locations.

### The Controller

Finally, and almost just for completeness, we have the controller.
By now it should be clear what it is going to do.
Let's look at [lib/MyWeatherApp/Controller/Weather.pm](https://github.com/jberger/MyWeatherApp/blob/master/lib/MyWeatherApp/Controller/Weather.pm) just to be sure.

    package MyWeatherApp::Controller::Weather;
    use Mojo::Base 'Mojolicious::Controller';

    sub recall {
      my $c = shift;
      my $search = $c->param('q');

      return $c->render(
        status => 400,
        text => 'q parameter is required',
      ) unless $search;

      my $data = $c->weather->recall($search);
      $c->render(json => $data);
    }

    1;

When you request the `/weather` route with a query parameter that we've cached some data for, it will return that data.
Given that you could write some fancy front-end to display the data but for now lets just revert to the `get` command; a great use of its talents.

    $ perl bin/myweatherapp get /weather?q=Seattle
    [{"temperature":1.9,"time":1512545520},{"temperature":1.9,"time":1512545520}]

### Finally

There are several other topics I missed in order to bring this real world example.
I'll mention two quickly.

There are convenient mechanisms to generate the usage output from pod documentation inline in the command's file.
And there is one command that lists subcommands, [Mojolicious::Commands](http://mojolicious.org/perldoc/Mojolicious/Commands) itself.
Indeed the one command we've seen so far that has subcommands, the [`generate`](http://mojolicious.org/perldoc/Mojolicious/Command/generate) command subclasses it to get that behavior.
It in turn has its own set of namespaces to search for commands, which it displays as subcommands.

Commands are very flexible and very powerful.
Indeed they are one of my very favorite things about Mojolicious.
Perhaps you can tell?


