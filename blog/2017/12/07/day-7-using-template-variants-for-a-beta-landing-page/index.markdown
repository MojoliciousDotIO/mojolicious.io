---
title: 'Day 7: Using Template Variants For a Beta Landing Page'
tags:
    - advent
    - rendering
    - template
author: Doug Bell
images:
  banner:
    src: '/static/1280px-Single_yellow_tulip_in_a_field_of_red_tulips.jpg'
    alt: 'Single yellow tulip in a field of red tulips'
    data:
      attribution: |-
        <a href="https://commons.wikimedia.org/w/index.php?curid=2147460">Image</a> by Photo by and (c)2007 <a href="//commons.wikimedia.org/wiki/User:Jina_Lee" title="User:Jina Lee">Jina Lee</a> - <span class="int-own-work" lang="en">Own work</span>, <a href="http://creativecommons.org/licenses/by-sa/3.0/" title="Creative Commons Attribution-Share Alike 3.0">CC BY-SA 3.0</a>.
data:
  bio: preaction
  description: 'Doug demonstrates using Mojolicious template variants to show a new landing page for a beta-testing website'
---
[CPAN Testers](http://cpantesters.org) is a pretty big project with a long,
storied history. At its heart is a data warehouse holding all the test reports
made by people installing CPAN modules. Around that exists an ecosystem of
tools and visualizations that use this data to provide useful insight into the
status of CPAN distributions.

For the [CPAN Testers webapp
project](http://github.com/cpan-testers/cpantesters-web), I needed a way to
show off some pre-release tools with some context about what they are and how
they might be made ready for release. I needed a "beta" website with a front
page that introduced the beta projects. But, I also needed the same
[Mojolicious](http://mojolicious.org) application to serve (in the future) as a
production website. The front page of the production website would be
completely different from the front page of the beta testing website.

To achieve this, I used [Mojolicious's template variants
feature](http://mojolicious.org/perldoc/Mojolicious/Guides/Rendering#Template-variants).
---

First, I created a variant of my index.html template for my beta site
and called it `index.html+beta.ep`.

%= highlight HTML => include -raw => 'templates/index.html+beta.ep'

Next, I told Mojolicious to use the "beta" variant when in "beta" mode
by passing `$app->mode` to the `variant` stash variable.

%= highlight Perl => include -raw => 'myapp.pl'

The mode is set by passing the `-m beta` option to Mojolicious's `daemon` or
`prefork` command.

    $ perl myapp.pl daemon -m beta

This gives me the [new landing page for beta.cpantesters.org](http://beta.cpantesters.org).

    $ perl myapp.pl get / -m beta
    <h1>CPAN Testers Beta</h1>
    <p>This site shows off some new features currently being tested.</p>
    <h2><a href="/chart.html">Release Dashboard</a></h2>

But now I also need to replace the original landing page (index.html.ep)
so it can still be seen on the beta website. I do this with a simple
trick: I created a new template called `web.html+beta.ep` that imports
the original template and unsets the `variant` stash variable. Now
I can see the [main index page on the beta site at
http://beta.cpantesters.org/web](http://beta.cpantesters.org/web).

%= highlight HTML => include -raw => 'templates/web.html+beta.ep'

    $ perl myapp.pl get /web -m beta
    <h1>CPAN Testers</h1>
    <p>This is the main CPAN Testers application.</p>

Template variants are a useful feature in some edge cases, and this isn't the
first time I've found a good use for them. I've also used them to provide a
different layout template in "development" mode to display a banner saying
"You're on the development site". Useful for folks who are undergoing user
acceptance testing. The best part is that if the desired variant for that
specific template is not found, Mojolicious falls back to the main template. I
built a mock JSON API application which made extensive use of this fallback
feature, but that's another blog post for another time.
