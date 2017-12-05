---
tags:
    - advent
    - installing
    - hello world
    - lite
title: 'Day 1: Getting Started'
author: Joel Berger
images:
  banner:
    src: '/static/1280px-Colorado_Springs_Hot_Air_Balloon_Competition.jpg'
    alt: 'hot air ballons'
data:
  bio: jberger
  description: Hit the ground running with Mojolicious. A working application in minutes!
---
## Start at the Beginning

In this Advent Calendar series, some posts will be introductory, some will be advanced, some will be on new features.
Who knows what could be next?
But for now let's ensure a level playing field by working out how to get started.
---
## What is Mojolicious?

Well, [Mojolicious](http://mojolicious.org) is really two things.
First it is a powerful web-focused toolkit called Mojo.
Second it is a powerful web framework called Mojolicious.
The Mojolicious framework is built using the Mojo toolkit.

That that doesn't mean you can't use Mojo tools elsewhere.
If you see some tools you like but want to use with some other framework, go ahead, I won't tell!
Use it in any Perl code you want!

Shoot I wasn't going to mention Perl!
Yes, Mojolicious is written in Perl.
Don't let that scare you.
It has tons of ways to keep you and your code safe!
From a built-in object system to a consistent api with chainable methods Mojolicious is designed to keep your code clean and readable.
Hopefully you'll even have some fun using it!

## Installation

Installation is easy and fast.
In fact, if you set the test harness to run in parallel, it should install in seconds!
You can do that by setting `HARNESS_OPTIONS=j9` in your environment (where `9` is one more than your number of cores).

The easiest way to install is to run

    curl -L https://cpanmin.us | perl - -M https://cpan.metacpan.org -n Mojolicious

or, you can install using any cpan client (we like [`cpanm`](https://metacpan.org/pod/App::cpanminus)) or using your system's package manager.

## Your First Application

In the grand tradition of programming, the first thing we need to do is to run a hello world application.

Save the following as `hello.pl`

    use Mojolicious::Lite;
    get '/' => {text => 'Hello 🌍 World!'};
    app->start;

This script simply

- imports Mojolicious (the lite version)
- defines a GET handler to respond to requests with a unicode version of hello world
- starts the application

But before that's any use to us, we have to start a web server.

## Running Your Application

Mojolicious applications (as we'll see in another post) are more than just web servers.
In order to use them as one, we need to start it as a web server.

Mojolicious comes with four built-in servers

- `daemon`, single-threaded, the basis of all the others
- `morbo`, the development server, restarts on files changes
- `prefork`, optimized production server
- `hypnotoad`, like prefork but with hot-restart capability

`daemon` and `prefork` are application commands and are run like

    perl hello.pl daemon

These will work, but for development let's use `morbo`.
`morbo` and `hypnotoad` are their own scripts which take the application as an argument.
Start it by running

    morbo hello.pl

When it starts it should tell you to visit `http://127.0.0.1:3000`.
Open that url in your browser.
Your first advent treat should be waiting for you!

## Getting Help

The documentation is available at <http://mojolicious.org/perldoc>.
You are especially encouraged to read the Tutorial and Guides in the order suggested there.

Read it carefully, unlike some documentation, it is written for brevity and conciseness.
Users accustomed to skimming documentation filled with fluff might need a second take.

If you still have trouble, we have a mailing list and an IRC channel ready to help!
Find us at <http://mojolicious.org/perldoc#SUPPORT>!


<small><a href="https://commons.wikimedia.org/wiki/File:Colorado_Springs_Hot_Air_Balloon_Competition.jpg">Image by DarlArthurS</a> licensed under the <a href="https://en.wikipedia.org/wiki/en:Creative_Commons" class="extiw" title="w:en:Creative Commons">Creative Commons</a> <a rel="nofollow" href="//creativecommons.org/licenses/by-sa/3.0/deed.en">Attribution-Share Alike 3.0 Unported</a> license.</small>
