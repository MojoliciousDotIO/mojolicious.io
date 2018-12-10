---
title: Day 9: Add a theme system to your Mojolicious app
status: published
tags:
  - advent
  - theme
author: Luc Didry
images:
  banner:
    src: '/blog/2018/12/09/add-a-theme-system-to-your-mojolicious-app/banner.jpg'
    alt: 'Four lines of paint drawn on a roller, in green, red, orange and blue'
    data:
      attribution: |-
        [Photo](https://unsplash.com/photos/46juD4zY1XA) by [David Pisnoy](https://unsplash.com/@davidpisnoy), [Unsplash license](https://unsplash.com/license) (quite similar to public domain)
data:
  bio: ldidry
---
You wrote an awesome Mojolicious app, and people use it.
Marvellous!
But users may want to modify the theme of your app: change the logo, use another CSS framework, such sort of things.

Modifying the theme of a Mojolicious app is quite easy: add, modify or delete things in `public` and `templates`.
But all those direct modifications may not survive on update of the app: they will simply be erased by the files of the new version.

Let's see how we can provide a way to have a theme system in a Mojolicious application, that allows users to have a custom theme without pain and without risk of losing it on updates.

---

## A fresh application

When you create a new Mojolicious app with `mojo generate MyApplication`, these are the default directories that will serve files and their default contents to be served:

    $ tree public templates
    public
    └── index.html
    templates
    ├── example
    │   └── welcome.html.ep
    └── layouts
        └── default.html.ep

    2 directories, 3 files

`public` is where static files are stored, and `templates` is where templates are stored.

Those paths are registered in your Mojolicious application in `$app->static->paths` and `$app->renderer->paths`.
Luckily, those two objects are array references, so we can add or remove directories to them.

When serving a static file, our application search for the file in the first directory of the `$app->static->paths` array, and if it does not found it, search in the next directory, and so on.
It goes the same for template rendering.

## Let's change paths

We could keep the `public` and `templates` default directories at the root of the application directory but I like to regroup all the themes-related stuff in a directory called `themes` and call my default theme… well, `default`.

Create the new directories and move the default theme directories in it:

    $ mkdir -p themes/default
    $ mv public templates themes/default

Then, we need to change the paths in our application.
Add this in `lib/MyApplication.pm`:

    # Replace the default paths
    $self->renderer->paths([$self->home->rel_file('themes/default/templates')]);
    $self->static->paths([$self->home->rel_file('themes/default/public')]);

## Add a way to use another theme

As said before, Mojolicious search for static files or templates in the first directory of the registered paths, and goes to next if it can't find the files or templates.

Thus, we need to add our new theme paths before the default ones.

Let's say that we created a `christmas` theme which files are in `themes/christmas/public` and which templates are in `themes/christmas/templates`.

Our snippet to add to the code becomes:

    # Replace the default paths
    $self->renderer->paths([$self->home->rel_file('themes/default/templates')]);
    $self->static->paths([$self->home->rel_file('themes/default/public')]);
    # Put the new theme first
    unshift @{$self->renderer->paths}, $self->home->rel_file('themes/christmas/templates');
    unshift @{$self->static->paths},   $self->home->rel_file('themes/christmas/public');

By doing that way, we can overload the default files.

You don't have to modify each file of the default theme to have a new theme: just copy the files you want to overload in your new theme directory and it will be used instead of the default one.

Let's say that you have a `background.png` file in your default theme:

    $ cd themes/default
    $ tree public templates
    public
    ├── background.png
    └── index.html
    templates
    ├── example
    │   └── welcome.html.ep
    └── layouts
        └── default.html.ep

    2 directories, 4 files

In order to overload it, you just have to have this:

    $ cd themes/christmas
    $ tree public templates
    public
    └── background.png
    templates

    0 directories, 1 files

## Using Mojolicious::Plugin::Config plugin

[Mojolicious::Plugin::Config](https://mojolicious.org/perldoc/Mojolicious/Plugin/Config) comes with Mojolicious itself and is a great way to let users configure your application.
Why not using it to let them choose the theme they want?
In our example, the setting will unsurprisingly be named `theme`.

First, use the plugin:

    # Mojolicious
    my $config = $app->plugin('Config' => {
        default => {
            theme => 'default'
        }
    });

Note that I added a default value to the configuration of the plugin.
It makes sure that we will have a correct value for the chosen theme even if the user didn't choose one.

Now, we just have to use that configuration setting in our code:

    # Replace the default paths
    $self->renderer->paths([$self->home->rel_file('themes/default/templates')]);
    $self->static->paths([$self->home->rel_file('themes/default/public')]);
    # Do we use a different theme?
    if ($config->{theme} ne 'default') {
        # Put the new theme first
        my $theme = $self->home->rel_file('themes/'.$config->{theme});
        unshift @{$self->renderer->paths}, $theme.'/templates' if -d $theme.'/templates';
        unshift @{$self->static->paths},   $theme.'/public'    if -d $theme.'/public';
    }

Note the `if -d $theme.'/templates'`: it prevents problems if the use made a typo in the name of the theme and allow to avoid creating both `templates` and `public` in the theme directory if you only need one of them.

## Conclusion

You are now providing a theme system in your application.
Users will now be able to change the style of it without fearing losing their changes on updates (though they will need to check the changes they made in case the default theme changed a lot).

You may even provides different themes yourself, like I did for my [URL-shortening app, Lstu](https://framagit.org/fiat-tux/hat-softwares/lstu) 🙂
