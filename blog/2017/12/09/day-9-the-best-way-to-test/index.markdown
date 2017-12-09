---
title: 'Day 9: The Best Way to Test'
tags:
    - advent
    - testing
author: Joel Berger
images:
  banner:
    src: '/static/1280px-CSIRO_ScienceImage_2798_Testing_in_the_Laboratory.jpg'
    alt: 'Woman using chemistry lab equipment'
    data:
      attribution: |-
        <a href="https://commons.wikimedia.org/w/index.php?curid=35474503">Image</a> by CSIRO, <a href="http://creativecommons.org/licenses/by/3.0" title="Creative Commons Attribution 3.0">CC BY 3.0</a>.
data:
  bio: jberger
  description: An introduction to Test::Mojo, the testing framework for Mojolicious.
---
Ok so it is a bit of a click-bait headline.
But that doesn't mean I don't believe it.

[Test::Mojo](http://mojolicious.org/perldoc/Test/Mojo) is a test framework for websites and related technologies.
While its true that there are many such tools, this one gets its power comes from combining so many of the tools that Mojolicious provides.
A full non-blocking web server, including websockets, an [event loop](http://mojolicious.org/perldoc/Mojo/IOLoop), an [XML/HTML DOM parser](http://mojolicious.org/perldoc/Mojo/DOM), [JSON parser and emitter](http://mojolicious.org/perldoc/Mojo/JSON), and more all come together to make to make incredibly detailed testing simple.
Further, with the recent additions in support of [roles](http://mojolicious.org/perldoc/Mojo/Base#with_roles) (which will be discussed in a future post), Test::Mojo is becoming an extensible testing platform.

In this article, I'll give a quick overview of how to use Test::Mojo and some of its methods.
Rest assured you'll see more of it as the series continues.
---

## Getting Started

The topmatter of a Test::Mojo script usually is fairly consistent.

    use Mojo::Base -strict;
    use Test::More;
    use Test::Mojo;

Unlike the Mojolicious, Mojolicious::Lite or Mojo::Base modules, importing Test::Mojo does not import strict, warnings and other recommended pragma.
Therefore we can import them via Mojo::Base with its `-strict` switch.
Test::Mojo relies on the venerable Perl testing system, usually accessed via [Test::More](https://metacpan.org/pod/Test::More).
We will need at least the `done_testing` keyword from that module so we import it too.

If you only want to test external websites then that's all you need to do before instantiating.

    my $t = Test::Mojo->new;

By convention, the tester object is stored in a variable named `$t`.

If you want to test a local application, presumably one you are developing (as most users do) then you have to tell it how to do so.
If you are testing a Mojolicious::Lite script, all you have to do is `require` the script into your test file.
This is usually done with the help of [FindBin](https://metacpan.org/pod/FindBin) which gives the location of the test script, from which you can derive where your application is.
For example, if your script is `project/myapp.pl` and your test is `project/t/mytest.t` then you need to go up one directory to find your script, like so

    use FindBin;
    require "$FindBin::Bin/../myapp.pl";
    my $t = Test::Mojo->new;

One might also create a Lite app in the test file itself, especially when say testing a plugin on its own.

    use Mojolicious::Lite;
    plugin 'MyCoolPlugin';
    my $t = Test::Mojo->new;

Testing a Full app couldn't be simpler, you just pass it a class name for it to instantiate.

    my $t = Test::Mojo->new('MyApp');

When instantiating a Full app you can actually pass it a second argument, a hash reference of configuration overrides.
This can be especially handy for overriding things like database parameters to access a test instance rather than your regular database.
Of couse how you use your configuration might vary but if your app does something like

    has pg => sub {
      my $app = shift;
      return Mojo::Pg->new($app->config->{pg});
    };

Then you could override whatever configuration might be present in your system by doing

    my $t = Test::Mojo->new('MyApp', {pg => 'postgresql://testuser:testpass@/testdb'});

If you use [Mojolicious::Plugin::Config](http://mojolicious.org/perldoc/Mojolicious/Plugin/Config) or [Mojolicious::Plugin::JSONConfig](http://mojolicious.org/perldoc/Mojolicious/Plugin/JSONConfig) or one of several other third-party config loaders on CPAN, this configuration will be loaded instead of what it would otherwise load.
If you use some other loader on CPAN (that is Mojolicious aware) and it doesn't support this somewhat newish feature, please point it out to the author, it is easy to add.
Note that this does not work for Lite apps because it has inject the configuration overrides as the application is being built, something which isn't possible for a Lite app.

Finally you might find yourself in a situation where you already have an instantiated application.
If that is the case just pass it to the constructor.

    my $app = build_my_app();
    my $t = Test::Mojo->new($app);

## How It Works

Test::Mojo contains an instance of [Mojo::UserAgent](http://mojolicious.org/perldoc/Mojo/UserAgent) which it uses to make requests.
What many people don't know is that Mojo::UserAgent can act as a [server](http://mojolicious.org/perldoc/Mojo/UserAgent#server) for a Mojo application!
When the useragent gets a request for a relative url, (i.e. without a protocol or host), it uses this embedded server to fulfil the request.
This isn't just useful for Test::Mojo, but that is its primary purpose.

Many testing frameworks in Perl start some kind of fake server, mimicing the request/response cycle.
That works in blocking scenarios, but once you add non-blocking to the mix there is no substitute for a real server.
The useragent's server actually starts up on two different (local-only) ports, one for blocking requests and one for non-blocking.
Most people don't need to worry about that but for doing very complex things, knowing that might help.

When you make a request with Test::Mojo, its useragent will make the request, whether locally or externally and return to it the [transaction](http://mojolicious.org/perldoc/Mojo/Transaction) object.
Test::Mojo then keeps that object in its [tx](http://mojolicious.org/perldoc/Test/Mojo#tx) attribute for subsequent tests until the next request is made.
If none of the test methods that it provides will allow you to test what you need, you are welcome to fish the data out that that object.

When you use Test::More, when a test fails the test function returns a false value, allowing you to take some action on failure.

    is $answer, 42 or diag 'Deep Thought was wrong';

Test::Mojo uses a chaining method scheme so this doesn't work.
Rather, whenever any test is run (methods ending in words like `_ok` or `_is` or `_like`) the result is stored in the `success` attribute.
That value is checked by the `or` method allowing a similar functionality

    $t->text_is('.answer', 42)->or(sub{ diag 'Deep Thought was wrong' });

Getting ahead of myself, one of my favorite tester roles on CPAN, [Test::Mojo::Role::Debug](https://metacpan.org/pod/Test::Mojo::Role::Debug) uses this to great effect, adding a method that acts like `or` but dumps part of a DOM structure on failure.

    $t->text_is('.answer', 42)->d('.answer');

giving you context when a failure occurs.

## Making Requests

Now that we have a running application and a tester to test it, what can we do?
The Mojolicious documentation has lots of examples both in the [class documenation](http://mojolicious.org/perldoc/Test/Mojo) that we've already seen and in the [testing guide](http://mojolicious.org/perldoc/Mojolicious/Guides/Testing).
That said for the sake explication, let's see a few things.

You can make requests with most of the same arguments as to [Mojo::UserAgent](http://mojolicious/perldoc/Mojo/UserAgent#METHODS).
These can include headers as a hash reference:

    $t->get_ok('/login', {'X-Application-Auth' => 'custom value'});

Requests with JSON, form, for multipart data are built via [content generators](http://mojolicious.org/perldoc/Mojo/UserAgent/Transactor#GENERATORS).
You can [add your own](http://mojolicious.org/perldoc/Mojo/UserAgent/Transactor#add_generator) generator too; perhaps the subject of another article if there is interest.

    $t->post_ok('/login', form => {user => 'me', pass => 'secr3t'});
    $t->put_ok('/inventory/12345', json => {type => 'widget', value => 'tons'});

Or you can submit raw data as a trailing argument

    use Mojo::XMLRPC 'encode_xmlrpc'; # from CPAN
    $t->post_ok('/xmlrpc', encode_xmlrpc(call => 'mymethod', 'myarg'));

There are methods for all the standard HTTP methods.
The result of these tests is essentially the succes of the transport.

You'll also likely want to check the return status.

    $t->get_ok('/')->status_is(200);

There is also a method one to open a websocket

    $t->websocket_ok('/socket');

## Testing Results

For nearly every type of test, there are several forms.
A method ending in `_is` checks for equality with some value, while `_isnt` checks for inequality.
`_like` methods check for a pattern match, and `_unlike` checks that a pattern does not match.
As we've seen, methods that end in `_ok` check that something occured.

So what can we check?
We can check headers with `header_` etc, there is also a special `content_type_` family since that is often useful.
The `content_` methods check the raw data of the response, raw websocket messages can be tested with `message_`.

    $t->get_ok('/test.txt')
      ->status_is(200)
      ->content_like(qr/coal/);

There are methods for JSON.
HTTP requests responding with JSON can be tested with `json_`, websocket messages received containing JSON use `json_message_`.
The structure is tested using Test::More's [`is_deeply`](https://metacpan.org/pod/Test::More#is_deeply).

    $t->get_ok('/santa_list/joel.json')
      ->json_is({name => 'Joel Berger', status => 'nice'});

These methods allow the (optional) first argument to be a [JSON Pointer](http://mojolicious.org/perldoc/Mojo/JSON/Pointer) to "dive in" to the data structure.
Very handy when you only care about subsets of the data.

    $t->get_ok('/santa_list/joel.json')
      ->json_is('/status', 'nice');

Of course there are methods to test HTML responses.
Since it makes little sense to test the whole thing (and if you wanted to you could use `content_`), these take a [CSS3 Selector](http://mojolicious.org/perldoc/Mojo/DOM/CSS) to narrow their focus in a similar manner to the JSON Pointers.
To inspect the textual portions of the HTML response, use the `text_` methods with a selector.
For other tests, there might not be text to test, or the value doesn't matter.
For those cases there are `element_exists`, `element_exists_not`, and `element_count_is`, which, as their names indicate, take a selector and tries to find if or how many elements match it.
These really need a post of their own, but as a few examples

    $t->text_is('div.main-content p:nth-of-type(2)', 'This is the third paragraph of the main-section of text');
    $t->element_exists('img[src="kitten.jpg"]);

## Testing Websockets

Websockets are an intersting challenge to test, however Test::Mojo makes them easy.
We've already seen that you open a websocket with `websocket_ok`.

You can then either send a message with `send_ok` (taking the same arguments as the controller's [send](http://mojolicious.org/perldoc/Mojolicious/Controller#send) method) or you can wait for a message with `message_ok`.
The test then waits for a message to arrive without blocking the application, so it can do its work.
When it does arrive, you can test it with the `message_` and `json_message_` families of test methods.
Then you can send and or wait again until you have tested sufficiently.

To finish testing the websocket, you can't just request something else as with HTTP methods.
A websocket is a persistent connection and so it must be closed to continue.
You must be sure to call `finish_ok` or if you expect the websocket to close on its own, call `finished_ok`.

    $t->websocket_ok('/socket')
      ->send_ok('echo me')
      ->message_ok
      ->message_is('ECHO: echo me')
      ->send_ok('quack')
      ->message_ok
      ->message_is('Ducks quacks do not echo, silly')
      ->finish_ok;

## To Be Continued

There is still so much to say on the topic of testing.
Various tips and tricks.
Extensions that make testing javascript possible, extensions that make testing Catalyst or Dancer apps possible.
But this overview has gone plenty long and those should wait for another day.

As I said before, the Mojolicious documentation has lots of examples both in the [class documenation](http://mojolicious.org/perldoc/Test/Mojo) and in the [testing guide](http://mojolicious.org/perldoc/Mojolicious/Guides/Testing).
Check those out while you wait, if you've liked what you've seen above.

