---
title: 'Day 19: Make Your App Installable'
tags:
    - advent
    - wishlist
author: Joel Berger
images:
  banner:
    src: '/blog/2017/12/19/day-19-make-your-app-installable/container_ship.jpg'
    alt: 'Container ship loading at the dock'
    data:
      attribution: |-
       <a href="https://en.wikipedia.org/w/index.php?curid=31630711">Image</a> by Gnovick - Own work, <a href="https://creativecommons.org/licenses/by/3.0/" title="Creative Commons Attribution 3.0">CC BY 3.0</a>.
data:
  bio: jberger
  description: A few simple changes to make your application installable.
---

Thus far we have always run our applications from the local directory.
That is usually the project root directory and/or the repository checkout.
But did you know that with only a few changes you can make your application installable like other Perl modules?

While, you must do this if you want to upload your application to CPAN, even if you don't intend to do that, it still has benefits.
You can install the application on your personal computer, especially if you want to be able to run the script while in other directories.
Having an installable module also means that you can use a so-called "DarkPAN" and related tools to build yourself a local "CPAN".
If you have multiple Perl modules at your company (or as part of any project) using a DarkPAN can ease integration and deployment immensely!
N.B. there is even a DarkPAN tool written using Mojolicious called [opan](https://metacpan.org/pod/App::opan).

And hey if you needed even more more reason, it cleans up your project root directory somewhat too!
---

## The Challenge

The hardest part of this process is managing static files.
There are several Perl install tools that each handle static files slightly differently.
Some will happily bundle any files in the project directory, others will only bundle Perl files by default.

Then once installed that bundle location is usually different that what it was during development (even relative to the project).
It can be a challenge to make it so that you application can find those file both during development and after installation.

## TIMTOWTDI

Before we get started, I should mention that there are many ways to accomplish this task.
If your application small and already located in a `script` directory and has no external static files, you're probably already done!
That isn't the case for most applications of any real size, however.

If you've read the [Cookbook](http://mojolicious.org/perldoc/Mojolicious/Guides/Cookbook), you've already seen that there is a section on [Making your application installable](http://mojolicious.org/perldoc/Mojolicious/Guides/Cookbook#Making-your-application-installable).
While that's true, it makes its recommendations without using external modules and for one specific installation tool.
It also assumes that your application [`home`](http://mojolicious.org/perldoc/Mojolicious#home) should be related to the installation directory, which isn't always the case.

Yours truly has even written a [module](https://metacpan.org/pod/Mojolicious::Plugin::InstallablePaths) that was intended to ease this process somewhat.
While it does that, and I don't intend to deprecate it, I think there are even easier patterns now.

## The Share Directory

Perl has a lesser known and somewhat informal functionality for bundling static files called a "share directory".
Create a directory in your project root called `share` which will serve for this purpose.
Then move the `templates` and `public` directories from your project root into that directory.
You should also move any other static files like say database migration files (e.g. `wishlist.sql` from [yesterday](https://mojolicious.io/blog/2017/12/18/day-18-the-wishlist-model/)).

Although each install tool has different ways of specifying where the share directory is located during the development phase, none is espectially difficult to work with.
One reason I chose the name `share` is because my preferred installation tool [Module::Build::Tiny](https://metacpan.org/pod/Module::Build::Tiny) (which I use via [App::ModuleBuildTiny](https://metacpan.org/pod/App::ModuleBuildTiny)) requires it to be called that.
The others are configurable in the install scripts themselves (Makefile.PL/Build.PL/dist.ini).
For [Module::Build](https://metacpan.org/pod/Module::Build), you set the [`share_dir`](https://metacpan.org/pod/Module::Build::API#share_dir) parameter

    share_dir => 'share'

For [ExtUtils::MakeMaker](https://metacpan.org/pod/ExtUtils::MakeMaker) use [File::ShareDir::Install](https://metacpan.org/pod/File::ShareDir::Install)

    use File::ShareDir::Install;
    install_share 'share';

And [Dist::Zilla](https://metacpan.org/pod/Dist::Zilla) has a [plugin](https://metacpan.org/pod/Dist::Zilla::Plugin::ShareDir).

    [ShareDir]

whose default is `share`.
I'm sure other installers have ways to handle it too.

## File::Share Saves the Day

Since we earlier moved the location of templates and static files, we now need to tell the application where we put them.
The major innovation that makes this method possible and so painless is the module [File::Share](https://metacpan.org/pod/File::Share).
While it isn't [the original module](https://metacpan.org/pod/File::ShareDir) used to locate share directories after installation, it is the best one since it also works before hand during development too.
To do so it uses the heuristic of looking to see if a directory exists named `share` in that particular location (and a few checks for sanity), thus the second reason we call the directory that.

When used we get the absolute path to the share directory of your distribution.
Usually the name of the distribution is the name of your main module with the `::` replaced by `-`.

## Use in Mojolicious Apps

To use File::Share in a Mojolicious (Full) app I recommend wrapping it in a [Mojo::File](http://mojolicious.org/perldoc/Mojo/File) object and storing it in an attirbute on the app.
The attribute can be named anything, perhaps even as simple as `files`, though for the [Wishlist app](https://github.com/jberger/Wishlist/blob/blog_post/installable/lib/Wishlist.pm#L10-L14) I have used the name `dist_dir` since that is meaningful to me.

Why `dist_dir`?
Well that is the name of the function provided by File::Share.

    package Wishlist;
    use Mojo::Base 'Mojolicious';

    ...
    use File::Share;

    has dist_dir => sub {
      return Mojo::File->new(
        File::Share::dist_dir('Wishlist')
      );
    };
    ...

Mojo::File is an object class represeting files and directories on file systems.
By having this object, creating derived paths from it is simple.

    has sqlite => sub {
      my $app = shift;

      # determine the storage location
      my $file = $app->config->{database} || 'wishlist.db';
      ...

      my $sqlite = Mojo::SQLite->new
        ->from_filename("$file")
        ->auto_migrate(1);

      # attach migrations file
      $sqlite->migrations->from_file(
        $app->dist_dir->child('wishlist.sql')
      )->name('wishlist');

      return $sqlite;
    };

    sub startup {
      my $app = shift;

      $app->renderer->paths([
        $app->dist_dir->child('templates'),
      ]);
      $app->static->paths([
        $app->dist_dir->child('public'),
      ]);

      ...
    }

## What About The App Home?

So far we have been focusing on bundled static files.
As we saw in the Cookbook entry, one other consideration for installable applications is its `home`.

Apart from setting the above paths, which we no longer need it to do, the other main job of the `home` is to locate data from the application user rather than the application's own files.
Here it is still amply useful!

The first and most import example of this is loading configuration via say [Mojolicious::Plugin::Config](http://mojolicious.org/perldoc/Mojolicious/Plugin/Config#file).
The user will be provide configuration and almost certainly not from the installed location of the application, unlike its bundled support files.

This also provides another conundrum, if the home is used to load the configuration, then it cannot be set by via the configuration.
No, the home really needs to be set by the user via the `MOJO_HOME` environment variable [as documented](http://mojolicious.org/perldoc/Mojo/Home#detect).
If this isn't desirable, some other environment variable could be used by providing your own in your class, overriding the one from the parent.

    has home => sub {
      Mojo::Home->new($ENV{WISHLIST_HOME});
    };

Though `MOJO_HOME` is likely a fine place to start.

From there, you might (in some cases) want the users to be able to provide their own static files and/or templates.
Say if your application could be themed.
To do so, you could get values from the configuration and add them to the paths we set above.

Those might be raw paths.

    my $templates = $app->config->{theme}{templates};

Or you could allow them to be relative to the home.

    $templates = Mojo::File->new($templates);
    if ($templates->is_abs) {
      $templates = $app->home->child("$templates");
    }

Set these directories before the bundled versions so that if a file exists within them, they get used while defaulting to the bundled ones otherwise.

    if (-d $templates) {
      unshift @{ $app->renderer->paths }, $templates;
    }

Note that you could use that kind of process to allow other configured files to be relative to the home.
The application home is a great place to put data like a sqlite database; the sqlite database file seen earlier, which as show had to be an absolute path.
Indeed such a transform exists already exists in the Wishlist app but was omitted above for clarity.

## In Conclusion

I have made some of these changes to the [Wishlist App](https://github.com/jberger/Wishlist/compare/blog_post/sqlite_model...blog_post/installable).
You'll see that it it really isn't much to do.

You also see that I only used as much of these instructions as I needed; you can do the same.
There is no magic in any of what you've seen (other than perhaps File::Share).
If you don't need to think about theming or customizing the environment variable, then don't worry about it.
But if you find yourself in that situation, you'll know you can make such features available to your users.

And hey, if it is a useful application, consider uploading it to CPAN.
Though I warn you, once you start contributing to CPAN it can be addictive!

