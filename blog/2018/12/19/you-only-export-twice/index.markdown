---
title: Day 19: You Only Export Twice
disable_content_template: 1
tags:
    - advent
    - command
    - yancy
author: Doug Bell
images:
  banner:
    src: '/blog/2018/12/19/you-only-export-twice/banner.jpg'
    alt: 'Container ship leaving port'
    data:
      attribution: |-
        Banner image CC0 Public Domain
data:
  bio: preaction
  description: 'Export content for static rendering'
---
With my Yancy documentation site built, with [a custom landing
page](/blog/2018/12/17/a-website-for-yancy) and [a POD
viewer](/blog/2018/12/18/a-view-to-a-pod), I just need to deploy the site. I
could deploy the site using [hypnotoad, Mojolicious's preforking server with
hot
deployment](https://mojolicious.org/perldoc/Mojolicious/Guides/Cookbook#Hypnotoad),
but that would require me to have a server and keep it online. It'd be a lot
better if I could just deploy a [static website to
Github](https://pages.github.com) like all the cool people are doing.

But to do that, I'd need to take my dynamic website and turn it into a static
one, and that's impossible! Or is it? Why am I asking me, when I'm the one who
wrote a way to do it: The [Mojolicious export
command](https://metacpan.org/pod/Mojolicious::Command::export).
---

The export command takes a set of paths as input, fetches those pages, and
writes the result to a directory. It then looks at all the links on those pages
and writes those pages, too. In this way, it exports an entire Mojolicious
website as static files.

All I need to do to be able to use the export command is to install it:

    $ cpanm Mojolicious::Command::export

Once it's installed, we now have the export command in our application which I
can use like any other Mojolicious command.

    $ ./myapp.pl export

By default, the export command tries to export the home page (`/`) and works
recursively from there. If I have pages that aren't linked from other places, I
should (a) probably add some links to that page, but (b) can just add it to the
list of pages to export:

    $ ./myapp.pl export / /private

Since I'm hosting this site under a directory in my personal website, I need to
use the `--base` option to rewrite all the internal links to the correct path,
and I can use the `--to` option to write directly to the web server's
directory:

    $ ./myapp.pl export --base /yancy --to /var/www/preaction.me/yancy

And, if I want, I can use [the Mojolicious Config
plugin](https://mojolicious.org/perldoc/Mojolicious/Guides/Cookbook#Adding-a-configuration-file)
to change the default settings, including what pages to export, the export
directory, and a base URL.

The best part is that the export command handles redirects. So, when we're
using [the PODViewer
plugin](http://metacpan.org/pod/Mojolicious::Plugin::PODViewer) and get
redirected to [MetaCPAN](http://metacpan.org), the page gets updated with the
redirected location!

In the future it'd be nice if this command were made into a plugin so that it
could have hooks for customizing the exported content or additional checks for
broken links. If anyone is interested in helping out with this work, let me
know and I can help get them started!

Now, with [the Yancy CMS](http://preaction.me/yancy), [the PODViewer
plugin](http://metacpan.org/pod/Mojolicious::Plugin::PODViewer), and [the
Mojolicious export
command](http://metacpan.org/pod/Mojolicious::Command::export), I've got a
good-looking documentation website for Yancy! [View the full, completed
application](myapp.pl).

