---
status: published
title: Reverse Proxy With Path
disable_content_template: 1
tags:
    - deployment
    - development
author: Doug Bell
images:
  banner:
    src: '/blog/2019/03/18/reverse-proxy-with-path/banner.jpg'
    alt: 'Clouds with arrows pointing back and forth on a blue background'
    data:
      attribution: |-
        Original artwork by Doug Bell (licensed CC-BY-SA 4.0).
data:
  bio: preaction
  description: 'Host multiple Mojolicious applications on the same domain using reverse proxies'
---

It's extremely common for a [Mojolicious](http://mojolicious.org) web
application to be hosted behind some kind of HTTP proxy: A production website
usually includes [Varnish](https://varnish-cache.org), or
[Nginx](https://www.nginx.com), or a CDN (probably using Varnish or Nginx).

In the most common case, a web application is the entire domain, so configuring
the reverse proxy is very simple: Add the `-p` option to
[`hypnotoad`](https://mojolicious.org/perldoc/hypnotoad) or [`myapp.pl
daemon`](https://mojolicious.org/perldoc/Mojolicious/Command/daemon) command,
or set the `MOJO_REVERSE_PROXY` environment variable to a true value. [See the
Mojolicious Cookbook for more
details](https://mojolicious.org/perldoc/Mojolicious/Guides/Cookbook).

But what if my application doesn't have its own domain? How do I host a
Mojolicious application as a reverse proxy from a path in another domain?

---

Hosting a site as a reverse proxy from a path in a domain allows a bunch of
individual applications to handle a single domain. Static content can be served
by a simple server like [Apache HTTPD](https://httpd.apache.org), and a section
of dynamic content can be a Mojolicious application.

This presents a problem: If I host a blog application at
`http://example.com/blog`, every URL in the application needs to start with
`/blog`. I could fix this by adding the prefix to every link in every template
and all the content in my application, but this creates some problems. First,
since the `/blog` path is added by my proxy, trying to run the application
locally for testing will break all the links (unless I also run a local proxy).
Second, if I want to change the path, I need to change all my templates!

There's an easier way. Every request in Mojolicious has a URL,
a [Mojo::URL](https://mojolicious.org/perldoc/Mojo/URL) object. Every
Mojo::URL object has a `base`. When Mojolicious parses a request, it
takes the request's path (`/blog`) and puts it in the URL. Then it takes
the request's domain name (from the HTTP `Host` header) and puts it in
the `base`.  Then, every time the app needs an absolute URL (like in the
[`url_for`
helper](https://mojolicious.org/perldoc/Mojolicious/Plugin/DefaultHelpers#url_for)),
it combines the URL with the `base`.

So, to solve the problem of hosting a Mojolicious app behind a proxy with a
path, I need to add my proxy's path to the `base` of the request's URL. I can
do that with the [`before_dispatch`
hook](https://mojolicious.org/perldoc/Mojolicious#before_dispatch):

    app->hook( before_dispatch => sub {
        my ( $c ) = @_;
        my $url = $c->req->url;
        my $base = $url->base;
        # Append "/blog" to the base path
        push @{ $base->path }, 'blog';
        # The base must end with a slash, making
        # http://example.com/blog/
        $base->path->trailing_slash(1);
        # and the URL must not, so that relative links 
        # on the home page work correctly
        $url->path->leading_slash(0);
    });

Except now I have the same problem as if I just added `/blog` to every
link in my templates: My URLs always have `/blog` in front, even when
I'm running my application locally without a proxy. What I need is a way
to configure the path in the production environment, but not in the
development environment.

I could use [the Config
plugin](https://mojolicious.org/perldoc/Mojolicious/Plugin/Config) and
different configuration files for production and development to enable
and disable this behavior as needed, but I already have a way to detect
if the application behind a reverse proxy: The `MOJO_REVERSE_PROXY`
environment variable. If that's set, I want to add the hook.

But I also have that magic string "blog" hanging out in our hook. This
means the application knows what the reverse proxy's path is, and if the
reverse proxy's path changes, so must the app. That's not good
encapsulation. It'd be better if I put the proxy path inside the
`MOJO_REVERSE_PROXY` environment variable. That way the hook could see
if it exists, and then use it to fix the base path if it does!

    if ( my $path = $ENV{MOJO_REVERSE_PROXY} ) {
        my @path_parts = grep /\S/, split m{/}, $path;
        app->hook( before_dispatch => sub {
            my ( $c ) = @_;
            my $url = $c->req->url;
            my $base = $url->base;
            push @{ $base->path }, @path_parts;
            $base->path->trailing_slash(1);
            $url->path->leading_slash(0);
        });
    }

Now I can add `MOJO_REVERSE_PROXY=/blog` to my environment and my
application hosted behind my reverse proxy will work correctly! Without
the environment variable, my application still works correctly. As long
as I make sure to use the `url_for` helper (either directly or via
[Mojolicious tag
helpers](https://mojolicious.org/perldoc/Mojolicious/Plugin/TagHelpers)),
my application will work the same in both places.

There are lots of different ways that reverse proxies can be configured,
so you may have to do something slightly different in your hook. See
[the Rewriting section of the Mojolicious
Cookbook](https://mojolicious.org/perldoc/Mojolicious/Guides/Cookbook#Rewriting)
for other examples.
