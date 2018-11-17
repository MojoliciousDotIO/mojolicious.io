---
title: 'Day 14: You Promised To Call!'
tags:
    - advent
    - 'non-blocking'
    - promises
author: Ed J
images:
  banner:
    src: '/blog/2017/12/14/day-14-you-promised-to-call/pinky_swear.jpg'
    alt: 'Two hands with interlocked pinkies, a pinky swear'
    data:
      attribution: |-
        [Image](https://www.flickr.com/photos/elsabordelossegundos/15418211523) by [mariadelajuana](https://www.flickr.com/photos/elsabordelossegundos/), [CC BY 2.0](https://creativecommons.org/licenses/by/2.0/).
data:
  bio: mohawk
  description: Learn about Promises and their new prominent role in Mojolicious.
---
A new feature of [Mojolicious](http://mojolicious.org/), as of [7.49](https://metacpan.org/release/SRI/Mojolicious-7.49), is the implementation of the [Promises/A+ specification](https://promisesaplus.com/implementations#in-other-languages). In this posting, we're going to use promises to implement non-blocking, parallel fetching of a number of web pages.
---

## Background

"Normal" Perl code runs synchronously: it does each step it is told to, one at a time, and only that. This is also known as "blocking", since the program cannot do anything else.

The essence of a non-blocking code framework is that if you are waiting for something, you can register with the framework what to do when that thing happens. It can then do other processing tasks in the meantime. This means you don't have lots of processes (or possibly threads) sitting there, hogging operating-system resources, just blocked waiting for something else to finish; only the bare minimum of information is kept, about what to wait for, and what to do then.

Originally this was done just using callbacks, but this lead to what is known as "callback hell": each callback contains the next callback, at an increasing level of indentation. Even harder to keep track of is if the functions are kept separate. Avoiding this lead to the development of Promises, then Promises/A+.

Promises are used to easily add processing steps to a transaction: one can keep adding code for what to do "then" - after a previous stage has finished. Best of all, each "callback" is small and separate, with each one placed in succession. The resulting code reads like sequential, synchronous code, even though it runs asynchronously.

First let's get web pages, one after the other, synchronously. Obviously, that means the code will block anything else while it's running.

    # refers to a previously-set-up @urls
    sub fetchpages {
      while (my $url = shift @urls) {
        # Fetch, show title
        say $ua->get($url)->result->dom->at('title')->text;
      }
    }

## With a callback

This you could realistically have running as part of a web service, since with any kind of callback it will run asynchronously, therefore non-blocking, as discussed above.

    sub fetchpages {
      # Stop if there are no more URLs
      return unless my $url = shift @urls;
      # Fetch the next title
      $ua->get($url, sub {
        my ($tx) = @_;
        say "$url: ", $tx->result->dom->at('title')->text;
        fetchpages();
      });
    }

## Promises

With promises, we're going to split the processing, still in a single "stream" of activity, into two steps, to show the use of `then`. Notice the first `then` doesn't return a Promise, just a normal object. When using `then`, that's fine!

    sub fetchpages {
      # Stop if there are no more URLs
      return unless my $url = shift @urls;
      # Fetch the next title
      $ua->get_p($url)->then(sub {
        my ($tx) = @_;
        $tx->result;
      })->then(sub {
        my ($result) = @_;
        say "$url: ", $result->dom->at('title')->text;
        fetchpages(); # returns a promise, but of a whole new page to process
      });
    }

Here you'll see we're using [`get_p`](http://mojolicious.org/perldoc/Mojo/UserAgent#get_p). This is just like [`get`](http://mojolicious.org/perldoc/Mojo/UserAgent#get), but instead of taking a callback, it returns a Promise.

## Promises with two streams

Given that a Promise is a single chain of processing steps, how can we have a number of them running concurrently, without making all the requests at once? We'll use two ideas: chaining (shown above - the key is each "then" returns a new Promise), and [`Mojo::Promise->all`](http://mojolicious.org/perldoc/Mojo/Promise#all) - it will wait until all the promises it's given are finished. Combining them gives us multiple streams of concurrent, but sequenced, activity.

    sub fetchpages {
      # Stop if there are no more URLs
      return unless my $url = shift @urls;
      # Fetch the next title
      $ua->get_p($url)->then(sub {
        my ($tx) = @_;
        $tx->result;
      })->then(sub {
        my ($result) = @_;
        say "$url: ", $result->dom->at('title')->text;
        fetchpages(); # returns a promise, but of a whole new page to process
      });
    }

    # Process two requests at a time
    my @promises = map fetchpages(), 1 .. 2;
    Mojo::Promise->all(@promises)->wait if @promises;

Another option for dealing with a number of concurrent activities, if you just want the first one that completes, is [`race`](http://mojolicious.org/perldoc/Mojo/Promise#race).

## What if something doesn't work?

In the above, we assumed that everything worked. What if it doesn't? Promises as a standard offer two other methods: `catch`, and `finally`.

`catch` is given a code-ref, which will be called when a Promise is "rejected". When things work as above, each Promise is "resolved". That means the value it was resolved with gets passed to the next `then`. If it is "rejected", then the error it is rejected with gets passed to the next `catch` in the chain, however far along that is. E.g.:

    sub fetchpage {
      $ua->get_p($url)->then(sub { ... })->then(sub { ... })->catch(sub {
        # either log, or report, or something else
      });
    }

If either the initial `get_p`, or either of the `then`s get rejected, then execution will skip to the `catch`. Another way to get this behaviour is to give a second code-ref to `then`.

`finally` is given a code-ref which will be called with either the successful (i.e. resolved) value, or the failure (i.e. the rejection) value.

## The task at hand

We have to synchronise the work between the multiple "streams" of execution, so that nothing gets missed, or done twice. Luckily, in the asynchronous but single-threaded context we have here, we can just pass around a reference to a single "queue", a Perl array. Let's build that array, at the start of our script:

    #!/usr/bin/env perl

    # cut down from https://stackoverflow.com/questions/15152633/perl-mojo-and-json-for-simultaneous-requests/15166898#15166898
    sub usage { die "Usage: bulkget-delay urlbase outdir suffixesfile\n", @_ };
    # each line of suffixesfile is a suffix
    # it gets appended to urlbase, then requested non-blocking
    # output in outdir with suffix as filename

    use Mojo::Base -strict;
    use Mojo::UserAgent;
    use Mojo::Promise;
    use Mojo::File 'path';

    my $MAXREQ = 20;

    my ($urlbase, $outdir, $suffixesfile) = @ARGV;
    usage "No URL" if !$urlbase;
    usage "$outdir: $!" if ! -d $outdir;
    usage "$suffixesfile: $!" if ! -f $suffixesfile;

    my $outpath = path($outdir);
    my @suffixes = getsuffixes($suffixesfile, $outpath);
    my $ua = Mojo::UserAgent->new;

    sub getsuffixes {
      my ($suffixesfile, $outpath) = @_;
      open my $fh, '<', $suffixesfile or die $!;
      grep { !-f $outpath->child($_); } map { chomp; $_ } <$fh>;
    }

We also want a procedure to handle results that are ready, to store them in a file if successful:

    sub handle_result {
      my ($outpath, $tx, $s) = @_;
      if ($tx->res->is_success) {
        print "got $s\n";
        $outpath->child($s)->spurt($tx->res->body);
      } else {
        print "error $s\n";
      }
    }

And now, the Promise part:

    my @promises = map makepromise($urlbase, $ua, \@suffixes, $outpath), (1..$MAXREQ);
    Mojo::Promise->all(@promises)->wait if @promises;

    sub makepromise {
      my ($urlbase, $ua, $suffixes, $outpath) = @_;
      my $s = shift @$suffixes;
      return if !defined $s;
      my $url = $urlbase . $s;
      print "getting $url\n";
      $ua->get_p($url)->then(sub {
        my ($tx) = @_;
        handle_result($outpath, $tx, $s);
        makepromise($urlbase, $ua, $suffixes, $outpath);
      });
    }

Once each stream runs out of suffixes to process, it will finish. If we wanted to add the ability to add to the queue that could keep as many streams as we started, we would restructure so that each stream is subscribed to a queue, and if the queue is empty, to wait (asynchronously!) until it is not. That's absolutely idiomatic for Promises, but we'll look at that another time!

## See also

  - The Mojolicious Cookbook shows how to implement non-blocking requests [with promises](http://mojolicious.org/perldoc/Mojolicious/Guides/Cookbook#Concurrent-blocking-requests).
  - The new [Mojo::Promise](http://mojolicious.org/perldoc/Mojo/Promise) class documentation.
  - This script is now available as a `Mojolicious::Command`: [Mojolicious::Command::bulkget](https://metacpan.org/pod/Mojolicious::Command::bulkget)!
