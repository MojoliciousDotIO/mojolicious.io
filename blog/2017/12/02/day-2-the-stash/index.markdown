---
tags:
  - advent
  - hello world
  - rendering
title: Day 2: The Stash
author: Joel Berger
bio: jberger
images:
  banner:
    src: '/static/bag-1854148_1920.jpg'
    alt: 'leather bag'
---
In Mojolicious, when processing a request and preparing a response one of the most important concepts is "the stash".
Since it is a non-blocking framework, your code can't use global variables to store any state during processing.
If you did and some other code were to run, it could very easily get cross-talk between requests.

The stash is the place you can store information while you process it.
It is just a simple hash reference that is attached to the controller object that is processing the request.
It lives and dies with that one transaction.

While you can and should use it as a scratchpad, it really is much more.
The stash controls almost every aspect of the response that you generate.
Let's look a little closer to see how it works
---
## Using the Stash for Rendering Text

In the previous post, we discussed the most simple 'Hello world' application.

    use Mojolicious::Lite;
    get '/' => {text => 'Hello 🌍 World!'};
    app->start;

While that is a very simple working case, a more common example would look like

    use Mojolicious::Lite;
    get '/' => sub {
      my $c = shift;
      $c->render(text => 'Hello 🌍 World!');
    };
    app->start;

In this example, the `GET /` request is handled by an "action callback".
A callback is function reference, intended to be called in the future; in this case the callback will be called when a client requests comes in that matches that type of request.

An action is called with one argument, called the [controller](http://mojolicious.org/perldoc/Mojolicious/Controller).
The controller is an object that represents our application's interaction with the current transaction.
It contains an object representing the [transaction](http://mojolicious.org/perldoc/Mojo/Transaction), which in tern holds objects for the [request](https://mojolicious.org/perldoc/Mojo/Message/Request) and [response](https://mojolicious.org/perldoc/Mojo/Message/Response).
It has methods which can be used generate responses, one of which is `render`, which you see above.
Here you see that we are going to render some text.

In truth though, most of the arguements to render are actually just merged into the stash.
Indeed the above example is the same as

    use Mojolicious::Lite;
    gee '/' => sub {
      my $c = shift;
      $c->stash(text => 'Hello 🌍 World!');
      $c->render;
    };
    app->start;

What you see now is that Mojolicious looks to the stash to see how to render a response.
And indeed, if you don't call render, but it has enough information to render a response in the stash already, it will just do so.

    use Mojolicious::Lite;
    get '/' => sub {
      my $c = shift;
      $c->stash(text => 'Hello 🌍 World!');
    };
    app->start;

## Stash Defaults

In the above example we saw how you can set a stash value during a request to control the response.
Remember that the action callback is only called when a request comes in.
However, there is nothing special about the requst that we need to wait for to understand how to respond to it.

In Mojolicious, when establishing a route, we can also specify some default values to add to the stash on each request (unless they are changed).
These defaults are passed as a hash reference to the route contructor `get`.

    use Mojolicious::Lite;
    get '/' => {text => 'Hello 🌍 World!'} => sub {
      my $c = shift;
    };
    app->start;

However now our action doesn't do anything, so we don't actually need it at all, and we are back to our original example.

    use mojolicious::lite;
    get '/' => {text => 'hello 🌍 world!'};
    app->start;

## Using Placeholders

We can take that example further and show how to make a more interesting greeting application, this time taking a name.

    use Mojolicious::Lite;
    get '/:name' => sub {
      my $c = shift;
      my $name = $c->stash('name');
      $c->stash(text => "Hello $name");
    };
    app->start;

Here we see that [placeholder](http://mojolicious.org/perldoc/Mojolicious/Guides/Routing#Standard-placeholders) values get merged into the stash.
We then can use them to render a more personalized response.
If you start the server and request `/Joel` in your browser you should see an application greeting me, or you can do it with your name.

If you tried to request `/` however, you would get a 404, not found.
The router doesn't want to handle this request without a value for the placeholder, so it assumes you wanted some other route to handle it.
While we could define another one for `/`, as we did before, we can do both at once by bringing back the defaults.

    use mojolicious::lite;
    get '/:name' => {name => '🌍 world!'} => sub {
      my $c = shift;
      my $name = $c->stash('name');
      $c->stash(text => "hello $name");
    };
    app->start;

Now that the router knows what the default for `name` should be, it can now handle `/` as well as `/santa`!

## Stash Values in Templates

Simple stash values, those that are only a single word (no punctuation) are also available in [templates](http://mojolicious.org/perldoc/Mojolicious/Guides/Rendering#Embedded-Perl).
Here is the previous example using an "inline template".

    use mojolicious::lite;
    get '/:name' => {name => '🌍 world!'} => sub {
      my $c = shift;
      $c->stash(inline => 'hello <%%= $name %>');
    };
    app->start;

Or if you'll let me use a concept without fully introducing it, here is a template in the data section of your script.

    use mojolicious::lite;
    get '/:name' => {name => '🌍 world!'} => sub {
      my $c = shift;
      $c->render('hello');
    };
    app->start;

    __DATA__

    @@ hello.html.ep
    hello <%%= $name %>

In the latter you see the first example of calling render with only one argument.
When it is called with an odd number of arguments, the first one is the identifier (name) of a template.
This is the same as stashing `template => 'hello'`, which you could even do in the route defaults.

## Special/Reserved Stash Keys

So there are probably a few people asking "so the `text` stash value controls part of the rendering, does the `name` stash value do anything?"
No, there are only a few stash values that have special meaning, they are documented on the [stash method](http://mojolicious.org/perldoc/Mojolicious/Controller#stash) itself.
Those keys are

- `action`
- `app`
- `cb`
- `controller`
- `data`
- `extends`
- `format`
- `handler`
- `inline`
- `json`
- `layout`
- `namespace`
- `path`
- `status`
- `template`
- `text`
- `variant`

Additionally all keys like `mojo.*` are reserved for internal use.
Most of those values are either useful in routing, templating, or rendering.

You've seen `text`, which render a string by utf8 encoding it.
To render data in a binary format (or just text without being utf8 encoded) use the `data` key.
Both of those, as well as the `template` will be rendered with the content type `text/html`.
To use something different, you can specify it with the `format` key.

    use mojolicious::lite;
    get '/' => {text => 'hello 🌍 world!', format => 'txt'};
    app->start;

Where the understood formats are listed [here](http://mojolicious.org/perldoc/Mojolicious/Types#DESCRIPTION) (and more [can be added](http://mojolicious.org/perldoc/Mojolicious/Types#DESCRIPTION)).

The others all have meanings, some of which you can probably figure out on your own, but this post has gone on long enough.
Those others will have to wait for another day.
