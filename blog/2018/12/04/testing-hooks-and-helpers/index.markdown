---
status: published
title: Testing Hooks and Helpers
disable_content_template: 1
tags:
    - advent
    - testing
author: Doug Bell
images:
  banner:
    src: '/blog/2018/12/04/testing-hooks-and-helpers/banner.jpg'
    alt: 'Scientific calculator on a mathematics textbook'
    data:
      attribution: |-
        Photo from pexels.com, licensed CC0.
data:
  bio: preaction
  description: 'How to easily test hooks and helpers using Test::Mojo'
---
[Test::Mojo](https://mojolicious.org/perldoc/Test/Mojo), the
[Mojolicious](http://mojolicious.org) testing tool, has a lot of ways to
[test routes in web
applications](https://mojolicious.org/perldoc/Mojolicious/Guides/Testing)
(even for [testing in other web
frameworks](https://metacpan.org/pod/Test::Mojo::Role::PSGI)).

But what if what I need to test isn't a route? What if it's
a [hook](https://mojolicious.org/perldoc/Mojolicious#HOOKS),
a [plugin](https://mojolicious.org/perldoc/Mojolicious/Guides/Cookbook#Adding-a-plugin-to-your-application),
or
a [helper](https://mojolicious.org/perldoc/Mojolicious/Guides/Rendering#Helpers)?
We can test all those things, too!

# Hooks

To thoroughly test hooks, I need to find ways to configure my test
cases. I could count on my application to do it, and find the right
routes to test the right behavior. But, that creates larger tests that
integrate different parts and makes test failures harder to debug. What
I want is to isolate the thing I'm testing. The best way to do that is
to create routes that test only what I want to test.

What if I have a hook to log exceptions to a special log file, like so:

    #!/usr/bin/env perl
    use Mojolicious::Lite;
    # Log exceptions to a separate log file
    hook after_dispatch => sub {
        my ( $c ) = @_;
        return unless my $e = $c->stash( 'exception' );
        state $path = $c->app->home->child("exception.log");
        state $log = Mojo::Log->new( path => $path );
        $log->error( $e );
    };
    app->start;

To test this, once I've loaded my app and created a Test::Mojo object,
I'm free to add more configuration to my app, including new routes!
These routes can set up exactly the right conditions for my test.

    # test.pl
    use Test::More;
    use Test::Mojo;
    use Mojo::File qw( path );
    my $t = Test::Mojo->new( path( 'myapp.pl' ) );
    # Add a route that generates an exception
    $t->app->routes->get(
        '/test/exception' => sub { die "Exception" },
    );
    $t->get_ok( '/test/exception' )->status_is( 500 );
    my $log_content = path( 'exception.log' )->slurp;
    like $log_content, qr{Exception}, 'exception is logged';
    done_testing;

Sure, this is technically testing a route. But, it's useful to know that
I can edit my application after I load it (but before any routes are
exercised). I often spawn additional Test::Mojo objects, sometimes using
the default
[Mojo::HelloWorld](https://mojolicious.org/perldoc/Mojo/HelloWorld)
application to test different plugins.

# Helpers

Now, I could test my helpers in the exact same way: Set up a new route
that uses my helper and examine the result. But, testing helpers can be
even easier: I can just ask the app to give me a controller with [the
`build_controller`
method](https://mojolicious.org/perldoc/Mojolicious#build_controller).
The controller will have
a [Mojo::Request](https://mojolicious.org/perldoc/Mojo/Message/Request)
and
a [Mojo::Response](https://mojolicious.org/perldoc/Mojo/Message/Response)
object, so I can set up the conditions for my test.

So, for example, if I have an authentication token in my configuration,
I could write a helper to check if my site visitor is trying to
authenticate.

    #!/usr/bin/env perl
    use Mojolicious::Lite;
    # Allow access via tokens
    plugin Config => {
        default => {
            tokens => { }, # token => username
        },
    };
    helper current_user => sub( $c ) {
        my $auth = $c->req->headers->authorization;
        return undef unless $auth;
        my ( $token ) = $auth =~ /^Token\ (\S+)$/;
        return undef unless $token;
        return $c->app->config->{tokens}{ $token };
    };

Then, rather than generating web requests to check all our
authentication edge cases, I can build a controller and set the right
headers to run my tests (using [Test::Mojo configuration
overrides](https://mojolicious.org/perldoc/Test/Mojo#new) to add a test
token):

    # test.pl
    use Test::More;
    use Test::Mojo;
    use Mojo::File qw( path );
    my $token = 'mytoken';
    my $t = Test::Mojo->new( path('myapp.pl'), {
        # Add a token as a configuration override
        tokens => { $token => 'preaction' },
    } );

    my $c = $t->app->build_controller;
    is $c->current_user, undef, 'current_user not set';

    $c->req->headers->authorization( 'NOTATOKEN' );
    is $c->current_user, undef, 'current_user without "Token"';

    $c->req->headers->authorization( 'Token NOTFOUND' );
    is $c->current_user, undef, 'current_user token incorrect';

    $c->req->headers->authorization( "Token $token" );
    is $c->current_user, 'preaction', 'current_user correct';

Of course, we'll still need to test whether the routes we want to
protect with tokens are protected, but this shows that our
authentication helper works so if there are problems with our routes,
it's probably not here.

So, it's not only the web requests in our app I can test. When I need to
test hooks, I can make my own routes for testing. When I need to test
helpers, I can do so by directly calling them. The narrower the scope of
the test, the easier debugging of test failures!
