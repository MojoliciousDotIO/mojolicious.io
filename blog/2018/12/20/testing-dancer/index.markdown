---
title: Day 20: Testing Dancer
disable_content_template: 1
tags:
  - advent
  - testing
  - psgi
author: Joel Berger
images:
  banner:
    src: '/blog/2018/12/20/testing-dancer/banner.jpg'
    alt: 'Dancers and judges at a dance competition'
    data:
      attribution: |-
        Banner image adapted from [Ballroom Dance Competition in Aukland, New Zealand](https://www.flickr.com/photos/louisepalanker/6848788290) by [Louise Palanker](https://www.flickr.com/photos/louisepalanker/), licensed CC BY-SA 2.0.
data:
  bio: jberger
  description: Test your Dancer2 applications with Test::Mojo
---

Authors of Dancer (and other) PSGI applications are probably accustomed to [testing](https://metacpan.org/pod/distribution/Dancer2/lib/Dancer2/Manual.pod#TESTING) with [Plack::Test](https://metacpan.org/pod/Plack::Test), and while that is a venerated option, it is pretty bare-bones.

During advent last year, I wrote about [Test::Mojo](https://mojolicious.org/perldoc/Test/Mojo), showing the many easy and (dare I say) fun ways that you can use it to test your Mojolicious applications.
If you missed it, go [check it out](https://mojolicious.io/blog/2017/12/09/day-9-the-best-way-to-test/).

I expect there are at least a few of you out there who read that and think, "I'd love to use that, but I don't use Mojolicious!"; well, you're in luck!
With just a little role to bridge the gap, you can use Test::Mojo to test your PSGI applications too!

---

## Mounting PSGI Applications

Mojolicious itself doesn't use the [PSGI](https://metacpan.org/pod/PSGI) protocol, owing to certain features that it doesn't provide and which are necessary for certain asynchronous operations.
That said, you can serve a Mojolicious application on a PSGI server by using [Mojo::Server::PSGI](https://mojolicious.org/perldoc/Mojo/Server/PSGI).
This Mojolicious-core module is automatically used for you when your Mojolicious-based app detects that it has started under a PSGI server (e.g. plackup or Starman).

While translating between a Mojo app and a PSGI server is core functionality, doing the opposite, translating between a PSGI app and a Mojolicious server (or app, as you'll see) is available as a third party module.
[Mojolicious::Plugin::MountPSGI](https://metacpan.org/pod/Mojolicious::Plugin::MountPSGI), as it's name implies, can mount a PSGI application into a Mojolicious-based one.
To do so, it builds a new, empty Mojolicious application that translates all requests to PSGI environments before dispatching to it as with any [mount](https://mojolicious.org/perldoc/Mojolicious/Plugin/Mount)-ed application.

## Testing using Test::Mojo

Once you can do that, it is trivial to take a PSGI application, wrap it with MountPSGI, and set it as the application for use with Test::Mojo.
Still, to make it even easier, that has all been done for you in [Test::Mojo::Role::PSGI](https://metacpan.org/pod/Test::Mojo::Role::PSGI).

Like any [Mojolicious Role](https://mojolicious.io/blog/2017/12/13/day-13-more-about-roles/), we can use `with_roles` to create a (mostly anonymous) subclass with the role applied.
You can use the shortcut `+` to stand in for `Test::Mojo::Role::`.

    use Test::Mojo;
    my $class = Test::Mojo->with_roles('+PSGI');

Then you instantiate that role with the path to the PSGI application, or else the PSGI application itself.

Since you're using roles, which are all about composition, you can also apply other roles that you might [find on CPAN](https://metacpan.org/search?q=%22Test%3A%3AMojo%3A%3ARole%22).

## An Example

As an example, let's say we have a simple application script (named `app.psgi`) that can render a `"hello world"` or `"hello $user"` in several formats.
I'll allow a plain text response, JSON, and templated HTML (using the [simple](https://metacpan.org/pod/Dancer2::Template::Simple) template to keep this concise).

    use Dancer2;

    set template => 'simple';
    set views => '.';

    any '/text' => sub {
      my $name = param('name') // 'world';
      send_as plain => "hello $name";
    };

    any '/data' => sub {
      my $name = param('name') // 'world';
      send_as JSON => { hello => $name };
    };

    any '/html' => sub {
      my $name = param('name') // 'world';
      template 'hello' => { name => $name };
    };

    start;

And the template (`hello.tt`) is

    <dl id="data">
      <dt id="hello">hello</dt>
      <dd><% name %></dd>
    </dl>

The [dl](https://developer.mozilla.org/en-US/docs/Web/HTML/Element/dl), [dt](https://developer.mozilla.org/en-US/docs/Web/HTML/Element/dt) and [dd](https://developer.mozilla.org/en-US/docs/Web/HTML/Element/dd) tags are a semantic way to markup key-value pairs in HTML, so it is almost the same as the JSON form above it.
The HTML I've built, while nice for display isn't necessarily nice for querying programmatically, this is on purpose for the example.

## The Tests

Of course we could start the application with [`plackup`](https://metacpan.org/pod/distribution/Plack/script/plackup) but that's not what we're trying to do.
I'll break the test script down a bit but if you want to see any of these files look at the [blog repo](https://github.com/MojoliciousDotIO/mojolicious.io/tree/master/blog/2018/12/20/testing-dancer/ex) for a full listing.
Instead, let's load this into a test script.

    use Mojo::Base -strict;

Now if you aren't familiar, `use Mojo::Base -strict` is a quick way to say

    use strict;
    use warnings;
    use utf8;
    use IO::Handle;
    use feature ':5.10';

but saves a lot of typing.
Next we load the necessary testing libraries.
Then make an instance of `Test::Mojo` composed with the `PSGI` role and make a new instance that points to the app we want to test.

    use Test::More;
    use Test::Mojo;
    my $t = Test::Mojo->with_roles('+PSGI')->new('app.psgi');

With that out of the way, on to the tests!
In our first tests we'll focus on the plain text endpoint `/text`.

    $t->get_ok('/text')
      ->status_is(200)
      ->content_type_like(qr[text/plain])
      ->content_is('hello world');

Each of the above method calls is a test.
The first, `get_ok`, builds a transaction and requests the resource.
Since the url is relative, it is handled by the app (if we wanted we could request and web resource too using a fully qualified url).
The transaction is stored in the tester object (`$t`) and all following tests will check it until it is replaced by the next request.

The remaining tests are reasonably self-explanatory, we check that the response status was 200, that we got a content type header that we expected and that its content is as we expect.
The content has already been utf-8 decoded, and the script has implicitly `use utf8`, so if you expected unicode, you can compare them easily.
The tests return the tester object so chaining is possible, making for visually clean sets of tests.

The next test is similar but this one uses the standard [Mojo::UserAgent](https://mojolicious.org/perldoc/Mojo/UserAgent) style request generation to build a query string naming Santa for our greeting.
The tests are all the same except of course that it checks that the content greets Santa.

    $t->get_ok('/text', form => { name => 'santa' })
      ->status_is(200)
      ->content_type_like(qr[text/plain])
      ->content_is('hello santa');

Moving on we request the data endpoint, both without and with a query, then similarly test the responses.

    $t->get_ok('/data')
      ->status_is(200)
      ->content_type_like(qr[application/json])
      ->json_is('/hello' => 'world');

    $t->post_ok('/data' => form => { name => 'rudolph' })
      ->status_is(200)
      ->content_type_like(qr[application/json])
      ->json_is('/hello' => 'rudolph');

You can see we use the `json_is` method to test the responses.
Now, the test could have been `->json_is({hello => 'rudolph'})` if had wanted to test the entire document.
By passing a [JSON Pointer](https://mojolicious.org/perldoc/Mojo/JSON/Pointer) I can inspect only the portions I'm interested in.

Finally I'm going to test the HTML endpoint.
As I said above, the result resists easy parsing.
We want to test the `dd` tag contents that follows a `dt` tag with the id `hello`, all inside a `dl` tag with the id `data`.
That would be a monstrous regexp (hehe).
However it is a piece of cake using [CSS Selectors](https://mojolicious.org/perldoc/Mojo/DOM/CSS).

    $t->get_ok('/html')
      ->status_is(200)
      ->content_type_like(qr[text/html])
      ->text_is('dl#data dt#hello + dd', 'world');

    $t->post_ok('/html' => form => { name => 'grinch' })
      ->status_is(200)
      ->content_type_like(qr[text/html])
      ->text_is('dl#data dt#hello + dd', 'grinch');

    done_testing;

In this year's Mojolicious advent calendar, we've already seen [some](https://mojolicious.io/blog/2018/12/05/compound-selectors/) [great](https://mojolicious.io/blog/2018/12/14/a-practical-example-of-mojo-dom/) [examples](https://mojolicious.io/blog/2018/12/15/practical-web-content-munging/) of the power of CSS selectors so I won't go into too much detail.
The point remains however, testing HTML responses with CSS selectors allows you to make your tests targetd in a way that allows you to write more and better tests since you don't have to hack around extracting the bits you want.

## Testing WebSockets

Ok so that's great and all, but of course now it comes to the point you've all been waiting for: can you test WebSockets?
As Jason Crome mentioned in his [Twelve Days of Dancer](http://advent.perldancer.org/2018/13) "State of Dancer", you can now dance with WebSockets via [Dancer2::Plugin::WebSocket](https://metacpan.org/pod/Dancer2::Plugin::WebSocket), so can Test::Mojo test them?

Well, so far not via the role I showed above.
It might be possible, but it would involve learning deep PSGI magick that I'm not sure I'm smart enough to do; patches welcome obviously :D.

Still I mentioned above that Test::Mojo can test anything it can access via an fully qualified URL, so let's just start up a server and test it!
I'll use the [example bundled with the plugin](https://github.com/yanick/Dancer2-Plugin-WebSocket/tree/releases/example) for simplicty.

    use Mojo::Base -strict;

    use EV;
    use Test::More;
    use Test::Mojo;

    use Twiggy::Server;
    use Plack::Util;

    my $app = Plack::Util::load_psgi('bin/app.psgi');
    my $url;
    my $twiggy = Twiggy::Server->new(
      host => '127.0.0.1',
      server_ready => sub {
        my $args = shift;
        $url = "ws://$args->{host}:$args->{port}/ws";
      },
    );
    $twiggy->register_service($app);

This starts Twiggy bound to localhost on a random port and starts the application using it.
When the server starts, the actual host and port are passed to the `server_ready` callback which we use to build the test url.
Now you just create a Test::Mojo instance as normal but this time open a websocket to the fully-qualified url that we built above.

    my $t = Test::Mojo->new;

    $t->websocket_ok($url)
      ->send_ok({json => {hello => 'Dancer'}})
      ->message_ok
      ->json_message_is({hello => 'browser!'})
      ->finish_ok;

    done_testing;

Unlike the previous examples, this time the connection stays open (but blocked) between method calls.
Per the protocol of the example, we first send a greeting to the Dancer app as a JSON document.
Since so much real-world websocket usage is just serialized JSON messages, Mojolicious provides many JSON-over-WebSocket conveniences.
One such convenience is a virtual websocket frame type that takes a data structure and serializes it as JSON before actually sending it as a text frame.

We then wait to get a message in response with `message_ok`.
In this case, we expect the application to greet us by calling us "browser!".
Oh well, it doesn't know any better!
We can the test that JSON reply with `json_message_is` (like `json_is` above but for websocket messages).
Finally we close the connection, testing that it closes correctly.

Testing WebSockets, even from a Dancer application, is easy!

## Conclusion

Although there are some great testing options in the PSGI space, Test::Mojo has lots of benefits for Dancer and PSGI users.
By using `Test::Mojo::Role::PSGI` or by running against a locally-bound server, Test::Mojo can be a tool in the toolbox of any PSGI developer.

