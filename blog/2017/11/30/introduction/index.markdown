---
tags: ~
title: Introduction
author: Joel Berger
data:
  bio: jberger
---
Hello and welcome to the new site!

My name is Joel Berger.
I'm on the Core Development team of the Mojolicious web framework.

I guess the immediate question is, why start a new site and blog?
This site grew out of ideas I have had to promote the framework, especially outside of the Perl bubble.

The immediate goal is to publish an Advent Calendar focused on Mojolicious.
It is a fun tradition and an interesting challenge, blogging once a day for almost a month.
The question was where to put it.
---

## Where to host?

I have an existing Perl-focused blog at <http://blogs.perl.org/users/joel_berger>.
For a variety of reasons, while it is a nice service, it wasn't where I wanted to put this series of blogs.
The biggest is that I want a place for semi-official Mojolicious news and articles that isn't tied to just my name and isn't so Perl focused.
The other is that for an extended series like an Advent Calendar, the multi-user nature of BPO means that the articles wouldn't show up consecutively in the main feed.

Mojolicious has also at times had its own blog.
This has been both lead author Sebastian Riedel's personal blog or a shared Tumblr (maybe others?).
Tumblr was an interesting idea but the UI leaves much to be desired.
The primary feature, reblogging, promised to give a good halfway house between BPO and a curated multiuser feed.
Contributors could blog on their own blog and then the main blog could reblog it to include it in the feed.
However in practice the reblogging feature left much to be desired, notably once a reblogging happens the content is immutable.
Not being able to correct errors in the most visible location is a non-starter for a technical blog.

The next logical thing is to host our own blog, so it can be curated as we'd like.
However that requires servers and monitoring and patches etc.

So finally we come to static blog generation.
This site is generated using [Preaction](http://preaction.me/)'s [Statocles](http://preaction.me/statocles/) static blogging engine.
While it is a static generator, it does actually use some of the Mojo Toolkit under the hood.
And while at launch time I am self-hosting it, static blogging hosts are a dime a dozen now and likely at some point it will get shipped to Github's hosting for peace of mind.

## Goals

Now that I have a plan for hosting, what kind of content am I expecting?
Well for starters, the Advent Calendar series.
Beyond that, I've been meaning to revisit my old BPO posts and brush them up for newer Mojolicious versions and best practices.
And of course new blog entries.

It will also be nice to have a semi-official place to put documentation and notes.
We do have a community-edited [wiki](https://github.com/kraih/mojo/wiki) on Github as well as the [official documentation](http://mojolicious.org/perldoc).
Having something in the middle seems warrented at times though too.

Finally, and perhaps with some help and encouragement, a screencast series could be possible.
Tempire's excellent [Mojocast](http://mojocasts.com/e1) have served us well, but they are getting a little long in the tooth.
We have a list of [errata](https://github.com/kraih/mojo/wiki#screencasts) on the wiki, but user have to know to seek that out.

Thanks, and watch this space!

