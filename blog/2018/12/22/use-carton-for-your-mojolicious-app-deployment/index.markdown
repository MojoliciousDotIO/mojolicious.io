---
title: Day 22: Use Carton for your Mojolicious app deployment
status: published
tags:
  - advent
  - deployment
  - carton
author: Luc Didry
images:
  banner:
    src: '/blog/2018/12/22/use-carton-for-your-mojolicious-app-deployment/banner.jpg'
    alt: 'Brown cardboard boxes on a white floor'
    data:
      attribution: |-
        [Photo](https://unsplash.com/photos/mTkXSSScrzw) by [Leone Venter](https://unsplash.com/@fempreneurstyledstock), [Unsplash license](https://unsplash.com/license) (quite similar to public domain)
data:
  bio: ldidry
---
You have a lovely Mojolicious app, it’s time to deploy it!

But… it’s not working on the production server! What is going on? Oh no, the modules you rely on are not on the same version that on your development server. What can you do?

---

Indeed, some modules evolve fast (Hello Mojolicious!) which is not bad but can lead to incompatible changes.

There’s also the bugs which can be resolved or introduced in a version and that you encounter if you have the wrong version.

## Cpanfile to the rescue

[Cpanfile](https://metacpan.org/pod/cpanfile) is a format for describing CPAN dependencies for Perl applications.

With `cpanfile`, we can list the modules we need, but we can also force the minimal versions of the modules, their maximum versions… or say "I want this exact version of that module".

But we can also list optional modules: you can support different databases, but users shouldn’t have to install MySQL-related modules if they want to use PostgreSQL.

Here’s an example of `cpanfile`:

    # Do not ask for a specific version
    requires 'DateTime';
    # Ask a specific version
    requires 'Plack', '== 1.0';
    # Ask a minimal version
    requires 'Net::DNS', '>= 1.12';
    # Or
    requires 'Net::DNS', '1.12';
    # Ask a maximal version
    requires 'Locale::Maketext', '< 1.28';
    # Give a range
    requires 'Mojolicious', '>= 7.0, < 8.0';

    # Optional modules
    feature 'postgresql', 'PostgreSQL support' => sub {
        requires 'Mojo::Pg';
    };
    feature 'mysql', 'MySQL support' => sub {
        requires 'Mojo::mysql';
    };
    feature 'ldap', 'LDAP authentication support' => sub {
        requires 'Net::LDAP';
    };

Cpanfile format can do more (recommended modules, requirements for a specific phase (`configure`, `test`…), using modules not published on CPAN…), but this is a post about Carton: I let you read cpanfile documentation 🙂

Nota bene: be careful to list non-Perl dependencies in README file<span id="back-to-1" class="superscript">[1](#footnote-1)</span>, like `libpq-dev` for [`Mojo::Pg`](https://mojolicious.org/perldoc/Mojo/Pg) 😉

Cpanfile can be used by [cpanminus](https://metacpan.org/pod/cpanm) or [Carton](https://metacpan.org/pod/Carton).

Go to the directory containing your `cpanfile` and do:

    cpanm --installdeps .

*Et voilà !*

Note that the modules in `features` has not been installed. You can install them with:

    cpanm --installdeps . --with-feature postgresql

Or, to install all `features` modules, but not the `mysql` one:

    cpanm --installdeps . --with-all-features --without-feature mysql

So, now, we can be sure that we have the good version of our application’s dependencies on the system.

But what if we host other applications on that system, that have conflicting requirements?

Cpanm is able to install modules in a specific folder (thank you, [local::lib](https://metacpan.org/pod/local::lib)), but wouldn’t it be convenient to install our dependencies in the directory of our application?
We would always know where our dependencies are.

## Here comes Carton

[Carton](https://metacpan.org/pod/Carton) is Perl module dependency manager. Think `bundler` in Ruby. Think `npm` in Node.js.

Like `npm` does, Carton installs the dependencies in the directory of the application.

### Deployment

First, install Carton:

    cpanm Carton

Then, we can install our dependencies with:

    carton install

Our dependencies will be installed in a directory named `local`.
But there is more: Carton will generate a `cpanfile.snapshot` file, containing the exact version of our dependencies, allowing us to enforce those exact version (ship it with your application).

In our `cpanfile` example, we asked for a Mojolicious version greater or equal than 7.0 and lesser than 8.0.
Between the installation on our development server and the installation on the production server, some newer versions of modules we depend on may have been published.
Let’s say that we have Mojolicious 7.77 in our development environment and 7.90 and that something has changed, which leads to problems (for example, the delay helper from [Mojolicious::Plugin::DefaultHelpers](https://mojolicious.org/perldoc/Mojolicious/Plugin/DefaultHelpers) has been [deprecated in 7.78](https://github.com/mojolicious/mojo/blob/47d1369fd11b09af47a76f7f7192985a30ce2409/Changes#L243) and [removed in 7.90](https://github.com/mojolicious/mojo/blob/47d1369fd11b09af47a76f7f7192985a30ce2409/Changes#L150)).

Both 7.77 and 7.90 versions are in our range, but our application does not work on the production server… we need to make the production environment as identical as possible as the development one.

For that, since we have a `cpanfile.snapshot` file from our development server, we can do:

    carton install --deployment

That installs the exact versions of modules listed in your snapshot.

### Features

Per default, `carton install` will install all the *features* dependencies, but we can deactivate some:

    carton install --deployment --without mysql

In order to provide the correct version for all modules, even the optional ones, do a `carton install` on the development server, and use `--without` (note that this isn't `--without-feature` like `cpanm`) only while deploying your application: you need to have a `cpanfile.snapshot` containing all modules.

### Start your application

In order to be able to use the `local` directory containing the dependencies, you can prefix your commands with `carton exec`.
So, to start a Mojolicious application with the built-in server [hypnotoad](https://mojolicious.org/perldoc/Mojo/Server/Hypnotoad), do:

    carton exec -- hypnotoad script/my_application

That works for all that you can do with your application. Example:

    carton exec -- script/my_application routes

Note the two dashes: they avoid carton to interpret arguments passed to the script.
This will show your application’s help message:

    carton exec -- script/my_application --help

This will show carton’s help message:

    carton exec script/my_application --help

See the difference? 😉

### Bundling the dependencies

To make installation quicker, carton can bundle all the tarballs for your dependencies into a directory so that you can even install dependencies that are not available on CPAN, such as internal distribution aka DarkPAN:

    carton bundle

This will bundle the tarballs in `vendor/cache`.
You can now install your dependencies with:

    carton install --cached

Combined with `--deployment` option, you can avoid querying for a database like CPAN Meta DB or downloading files from CPAN mirrors.

You may even avoid the need to install Carton on the production server,

    cpanm -L local --from "$PWD/vendor/cache" --installdeps --notest --quiet .

but then you will need to add the `local/lib/perl5` directory to `@INC` to start your application, since you can’t use `carton exec`.
You can do so using the core [lib](https://metacpan.org/pod/lib) module, the handy [lib::relative](https://metacpan.org/pod/lib::relative) from CPAN, [PERL5LIB](https://perldoc.pl/perlrun#PERL5LIB) environment variable, or [-I](https://perldoc.pl/perlrun#-Idirectory) switch.

## Conclusion

Carton and cpanfile are a great way to ease Mojolicious apps deployment.
Not only it avoids to list all the dependencies needed by your application in the README or the INSTALL file, but it speeds up deployments and make them more safer, since it sure lowers the risks of bugs due to bad versions of dependencies.

<small id="footnote-1">1: or INSTALL, or wherever you put your installation documentation [↩️](#back-to-1)<small>
