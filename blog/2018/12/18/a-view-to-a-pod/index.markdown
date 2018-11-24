---
title: A View To A POD
disable_content_template: 1
tags:
    - advent
    - documentation
    - yancy
author: Doug Bell
images:
  banner:
    src: '/blog/2018/12/18/a-view-to-a-pod/banner.jpg'
    alt: 'Books on a library shelf'
    data:
      attribution: |-
        Banner image CC0 Public Domain
data:
  bio: preaction
  description: 'A new POD viewer plugin for Mojolicious'
---
In order for Yancy to have a good documentation site, it needs to
actually render the documentation. To render Perl documentation in
[Mojolicious](http://mojolicious.org), I can use the
[PODViewer](http://metacpan.org/pod/Mojolicious::Plugin::PODViewer)
plugin (a fork of the now-deprecated
[PODRenderer](http://mojolicious.org/perldoc/Mojolicious/Plugin/PODRenderer)
plugin).
---

Adding PODViewer to the existing site is easy!

    use Mojolicious::Lite;
    plugin 'PODViewer';
    app->start;

Now when I visit <http://127.0.0.1:3000/perldoc> I see the POD for
[Mojolicious::Guides](http://mojolicious.org/perldoc). That's great and
all, but this is a documentation site for Yancy, not Mojolicious. Let's
adjust some configuration to make the default module Yancy, and only
allow viewing Yancy modules (trying to view another module will redirect
the user to [MetaCPAN](http://metacpan.org)).

    use Mojolicious::Lite;
    plugin 'PODViewer', {
        default_module => 'Yancy',
        allow_modules => [qw( Yancy Mojolicious::Plugin::Yancy )],
    };
    app->start;

There, now the Yancy docs are shown on the front page.

![Screenshot of Yancy module documenation](okay-docs.png)

Finally, let's make it look a bit nicer: The documentation definitely
needs to use the default site layout, and a little additional CSS will
also make the documentation look a lot better!

    use Mojolicious::Lite;
    plugin 'PODViewer', {
        default_module => 'Yancy',
        allow_modules => [qw( Yancy Mojolicious::Plugin::Yancy )],
        layout => 'default',
    };
    app->start;
    __DATA__
    @@ layouts/default.html.ep
    <!DOCTYPE html>
    <html>
        <head>
            <link rel="stylesheet" href="/yancy/bootstrap.css">
            <style>
                h1 { font-size: 2.00rem }
                h2 { font-size: 1.75rem }
                h3 { font-size: 1.50rem }
                h1, h2, h3 {
                    position: relative;
                }
                h1 .permalink, h2 .permalink, h3 .permalink {
                    position: absolute;
                    top: auto;
                    left: -0.7em;
                    color: #ddd;
                }
                h1:hover .permalink, h2:hover .permalink, h3:hover .permalink {
                    color: #212529;
                }
                pre {
                    border: 1px solid #ccc;
                    border-radius: 5px;
                    background: #f6f6f6;
                    padding: 0.6em;
                }
                .crumbs .more {
                    font-size: small;
                }
            </style>
            <title><%= title %></title>
        </head>
        <body>
            %= content
        </body>
    </html>

Now our documentation looks good!

![Screenshot of Yancy module documenation with new style](good-docs.png)

[Here's the full source](myapp.pl).  Now that I have a beautiful
website, I just need to deploy the new site to the Internet...

