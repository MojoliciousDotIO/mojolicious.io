---
title: Automatic Reload for Rapid Development
disable_content_template: 1
tags:
    - advent
    - development
author: Doug Bell
images:
  banner:
    src: '/blog/2018/12/02/automatic-reload-for-rapid-development/banner.jpg'
    alt: 'Mojolicious art and reload icon, original artwork by Doug Bell'
    data:
      attribution: |-
        Original artwork by Doug Bell, released under CC-BY-SA 4.0. It includes
        a screenshot of the Mojolicious.org website (fair use), the Mojolicious
        logo (CC-BY-SA 4.0), and a
        ["reload"](https://commons.wikimedia.org/wiki/File:Refresh_icon.svg)
        icon from Wikimedia Commons (CC0: Public domain)
data:
  bio: preaction
  description: 'Learn how to reload both the server and client on changes during application development.'
---
Developing webapps with [Mojolicious](http://mojolicious.org) is a lot of fun!
Using [the `morbo` server](https://mojolicious.org/perldoc/morbo) for
development, every change to my webapp causes a restart to load my changes.
This way the next request I make has all my new code!

So, I change my code, the webapp restarts, and I go back to my browser window.
Wait... Where's my new code? Why isn't the bug fixed? Did... Did I forget to
reload my browser window again? Ugh! Of course!

Does this happen to you? Probably not. But, it's still annoying to reload the
browser window after every backend code change. It'd be nice if my browser
window automatically reloaded every time the web server restarted!
---

# AutoReload Plugin

Like every problem in Perl, there's a CPAN module for this:
[Mojolicious::Plugin::AutoReload](http://metacpan.org/pod/Mojolicious::Plugin::AutoReload).
Adding this plugin to our application will automatically reload any browser
windows connected to our app, making it even easier to develop Mojolicious
applications!

To use the plugin, we add it to our application using the `plugin` method.
Then, we add the `auto_reload` helper to our [layout
template](https://metacpan.org/pod/distribution/Mojolicious/lib/Mojolicious/Guides/Tutorial.pod#Layouts)

    use Mojolicious::Lite;

    plugin 'AutoReload';
    get '/' => 'index';

    app->start;
    __DATA__

    @@ layouts/default.html.ep
    %= auto_reload
    %= content

    @@ index.html.ep
    % layout 'default';
    <h1>Hello, World!</h1>

[Download the code here](myapp.pl). Now while we have our application open in
our browser, if the server is restarted, our browser will reload the page to
see the new app!

## How It Works

This plugin is sheer elegance in its simplicity: When the browser loads the
page, it connects to a WebSocket located at `/auto_reload`. When the server
restarts, the WebSocket connection is broken. The client sees the broken
connection, waits a second for the server to start listening for connections
again, and then reloads the page.

## Disable In Production

Once we switch from `morbo` to `hypnotoad`, we don't want the automatic reload
anymore. So, the plugin doesn't send the browser the JavaScript to build the
websocket. This is controlled with [the `mode`
attribute](https://mojolicious.org/perldoc/Mojolicious/Guides/Tutorial#Mode).
When the `mode` is `development` (the default for `morbo`), the browser is told
to make the WebSocket. When the `mode` is anything else, no WebSocket is made.

Part of what makes Mojolicious so much fun is how easy it is. [The entire
plugin is only 40 lines of
code](https://github.com/preaction/Mojolicious-Plugin-AutoReload/blob/v0.003/lib/Mojolicious/Plugin/AutoReload.pm#L56-L92).

And now, with Mojolicious::Plugin::AutoReload, developing in Mojolicious is
just a little easier, and a little more fun!
