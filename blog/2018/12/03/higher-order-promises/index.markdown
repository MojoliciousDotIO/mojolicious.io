---
status: published
title: Higher Order Promises
author: brian d foy
tags:
    - promises
    - advent
images:
  banner:
    src: '1280px-Fractal-Cauliflower.jpg'
    alt: 'fractal cauliflower'
    data:
      attribution: |-
        <a rel="nofollow" class="external text" href="https://www.flickr.com/photos/joeshlabotnik/3059554662/">Image</a> by <a href="https://www.flickr.com/photos/joeshlabotnik/">Joe Shlabotnik</a> <a href="https://creativecommons.org/licenses/by-sa/2.0" title="Creative Commons Attribution-Share Alike 2.0">CC BY-SA 2.0</a>
---
## Create new, complex Promises by composing Promises

Mojolicious 7.49 added an its own implementation of the [Promises/A+ specification](https://promisesaplus.com). mohawk wrote about these in [Day 14: You Promised To Call!](https://mojolicious.io/blog/2017/12/14/day-14-you-promised-to-call/) of the 2017 Mojolicious Advent Calender where he showed you how to fetch many webpages concurrently. This Advent entry extends that with  more Promise tricks.

---

A Promise is a structure designed to eliminate nested callbacks (also known as ["callback hell"](http://callbackhell.com)). A properly written chain of Promises has a flat structure that easy to follow linearly.

A higher-order Promise is one that comprises other Promises and bases its status on them. The [Mojo::Promise::Role::HigherOrder](https://metacpan.org/pod/Mojo::Promise::Role::HigherOrder) distribution provides three roles that you can mix into `Mojo::Promise`to create fancier Promises that comprise Promises. Before you see those, though, look at the two that [Mojo::Promise](https://mojolicious.org/perldoc/Mojo/Promise) already provides.


### All

An `all` promise resolves only when all of its Promises also resolve. If one of them is rejected, the `all` Promise is rejected. This means that the overall Promise knows what to do if one is rejected and it doesn't need to know the status of any of the others.

  use Mojo::Promise;
  use Mojo::UserAgent;
  my $ua = Mojo::UserAgent->new;

  my @urls = ( ... );
  my @all_sites = map { $ua->get_p( $_ ) } @urls;
  my $all_promise = Mojo::Promise
    ->all( @all_sites )
    ->then(
      sub { say "They all worked!" },
      sub { say "One of them didn't work!" }
      );

The Promises aren't required to do their work in any order, though, so don't base your work on that.

### First come, first served

A "race" resolves when the first Promise is no longer pending and after that doesn't need the other Promises to keep working.

  use Mojo::Promise;
  use Mojo::UserAgent;
  my $ua = Mojo::UserAgent->new;

  my @urls = ( ... );
  my @all_sites = map { $ua->get_p( $_ ) } @urls;
  my $all_promise = Mojo::Promise
    ->race( @all_sites )
    ->then(
      sub { say "One of them finished!" },
      );

### Any


An "any" Promise resolves immediately when the first of its Promises resolves. This is slightly different from `race` because at least one Promise must resolve. A Promise being rejected doesn't resolve the `any` as it would with `race`. This should act like `any` in [bluebirdjs](http://bluebirdjs.com/docs/api/promise.any.html).

Here's a program that extracts the configured CPAN mirrors and tests that it can get the _index.html_ file. To ensure that it finds that file and not some captive portal, it looks for "Jarkko" in the body:

  use v5.28;
  use utf8;
  use strict;
  use warnings;
  use feature qw(signatures);
  no warnings qw(experimental::signatures);

  use File::Spec::Functions;
  use Mojo::Promise;
  use Mojo::Promise::Role::HigherOrder;
  use Mojo::UserAgent;
  use Mojo::URL;

  use lib catfile( $ENV{HOME}, '.cpan' );
  my @mirrors = eval {
    no warnings qw(once);
    my $file = Mojo::URL->new( 'index.html' );
    require CPAN::MyConfig;
    map { say "1: $_"; $file->clone->base(Mojo::URL->new($_))->to_abs }
      $CPAN::Config->{urllist}->@*
    };

  die "Did not find CPAN::MyConfig\n" unless @mirrors;
  my $ua = Mojo::UserAgent->new;

  my @all_sites = map {
    $ua->get_p( $_ )->then( sub ($tx) {
        die unless $tx->result->body =~ /Jarkko/ });
    } @mirrors;
  my $any_promise = Mojo::Promise
    ->with_roles( '+Any' )
    ->any( @all_sites )
    ->then(
      sub { say "At least one of them worked!" },
      sub { say "None of them worked!" },
      );

  $any_promise->wait;

### Some

A `some` Promise resolves when a certain number of its Promises resolve. You specify how many you need to succeed and the the `some` Promise resolves when that number resolve. This should act like `some` in [bluebirdjs](http://bluebirdjs.com/docs/api/promise.some.html).

This example modifies the previous program to find more than one mirror that works. You can specify the number that need to work for the `some` to resolve:

  use v5.28;
  use utf8;
  use strict;
  use warnings;
  use feature qw(signatures);
  no warnings qw(experimental::signatures);

  use File::Spec::Functions;
  use Mojo::Promise;
  use Mojo::Promise::Role::HigherOrder;
  use Mojo::UserAgent;
  use Mojo::URL;

  use lib catfile( $ENV{HOME}, '.cpan' );
  my @mirrors = eval {
    no warnings qw(once);
    my $file = Mojo::URL->new( 'index.html' );
    require CPAN::MyConfig;
    map { say "1: $_"; $file->clone->base(Mojo::URL->new($_))->to_abs }
      $CPAN::Config->{urllist}->@*
    };

  die "Did not find CPAN::MyConfig\n" unless @mirrors;
  my $ua = Mojo::UserAgent->new;

  my $count = 2;
  my @all_sites = map {
    $ua->get_p( $_ )->then( sub ($tx) {
        die unless $tx->result->body =~ /Jarkko/ });
    } @mirrors;
  my $some_promise = Mojo::Promise
    ->with_roles( '+Some' )
    ->some( \@all_sites, 2 )
    ->then(
      sub { say "At least $count of them worked!" },
      sub { say "None of them worked!" },
      );

  $some_promise->wait;

### None

A "none" Promise resolves when all of the its Promises are rejected. It's a trivial case that might be useful somewhere and I created it mostly because Perl 6 has a [none Junction](https://docs.perl6.org/routine/none) (which isn't really the same thing). There may be times when it's easier to check that no promises are fulfilled rather than one of them is rejected.

For this very simple example, consider the task to check that no sites are that annoying "404 File Not Found":

  use v5.28;
  use utf8;
  use strict;
  use warnings;
  use feature qw(signatures);
  no warnings qw(experimental::signatures);

  use Mojo::UserAgent;
  my $ua = Mojo::UserAgent->new;

  use Mojo::Promise;
  use Mojo::Promise::Role::HigherOrder;

  my @urls = qw(
    https://www.learning-perl.com/
    https://www.perl.org/
    https://perldoc.perl.org/not_there.pod
    );

  my @all_sites = map {
    my $p = $ua->get_p( $_ );
    $p->then( sub ( $tx ) {
      $tx->res->code == 404 ? $tx->req->url : die $tx->req->url
      } );
    } @urls;

  my $all_promise = Mojo::Promise
    ->with_roles( '+None' )
    ->none( @all_sites )
    ->then(
      sub { say "None of them were 404!" },
      sub { say "At least one was 404: @_!" },
      );

  $all_promise->wait;

## Conclusion

It's easy to make new Promises out of smaller ones to represent complex situations. You can combine the Promises that Mojolicious creates for you with your own handmade Promises to do almost anything you like.
