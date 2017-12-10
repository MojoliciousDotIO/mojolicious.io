---
title: 'Day 10: Give the Customer What They Want'
tags:
    - advent
    - rendering
author: Joel Berger
images:
  banner:
    src: '/static/cafe-wood-vintage-retro-seat-restaurant-946984-pxhere.com.jpg'
    alt: 'Wood bar counter with chairs'
data:
  bio: jberger
  description: Using content negotiation to create APIs that support multiple response formats.
---
Writing an API can be as easy as taking the results of some database query and presenting it to the user.
A more advanced can often present the data in one of multiple formats.
The user can then specify which format they want.

JSON is currently the most popular format for new APIs.
XML is another common one and was certainly king before JSON hit the scene.
An API might choose to make an HTML format of the data available, whether in some representation of the data or to render documentation about the API itself.
Of course there are many others.

Mojolicious believes in [Content Negotiation](http://mojolicious.org/perldoc/Mojolicious/Guides/Rendering#Content-negotiation), as it is called, and supports it throughout the stack.
Mojolicious makes it easy and convenient for users to pick a format they would like.
Similarly it makes rendering the different formats easy on the site author, as you would expect.
---

## Requesting a Format

### Accept Headers

The most HTTP-native way to choose a response format is with the [`Accept`](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Accept).
A request bearing the `Accept: application/json` header is indicating it wants JSON in the response.
Mojolicious supports this header, and this format is very handy for programmatic API clients, but it isn't very friendly to users, so there are several other options.

### File Extension

The first of these is via [file extension](http://mojolicious.org/perldoc/Mojolicious/Guides/Routing#Formats).
When defining a route, if you use the `:` placeholder you are opting-in to file-extension-based content negotiation.

    get '/:name' ...

These are called [Standard Placeholders](http://mojolicious.org/perldoc/Mojolicious/Guides/Routing#Standard-placeholders)
When used the generated route will strip something that looks like a file extension and places it in the `format` stash key.
In the above example, a request to `GET /santa.json` will result in the stash containing (among other things)

    {
      name => 'santa',
      format => 'json',
    }

If you'd like to opt out of extension-based Content Negotiation, you can use [Relaxed Placeholders](http://mojolicious.org/perldoc/Mojolicious/Guides/Routing#Relaxed-placeholders), using a `#` rather than a `:`.

### Query Parameter

Sometimes a file extension doesn't fit the API for some reason.
Perhaps the dot character is needed to indicate other things or perhaps it just looks weird for some requests.
In that case there is yet another mechanism.
For requests bearing a `format` query parameter, that value will be used.
A request to 'GET `/santa?format=json` will result in the same stash values as the previous example.

### How It Works

By now you probably suspect, correctly, that the `format` stash value is the driver of Content Negotiation.
Other methods, which you will see later, will check that value in order to determine what should be rendered.

With that knowledge therefore this way you might guess, correctly, that if you'd like to force a route to have a certain default format you can just put it into the route default stash values

    get '/:name' => {format => 'json'} ...

In Mojolicious the overall [default format](http://mojolicious.org/perldoc/Mojolicious/Renderer#default_format) is html, but of course can be changed.

    app->renderer->default_value('json');

There are also mechanims to limit the format detection, but those are beyond the scope of this article.
The links above contain more.

Note also that the mappings between file extensions and MIME types obviously are in play here.
If you have special format types you can add them to the [types](http://mojolicious.org/perldoc/Mojolicious#types) object on the application.

## Responding to the Format Request

There are two methods which help render what the client wants: [`respond_to`](http://mojolicious.org/perldoc/Mojolicious/Controller#respond_to) and [`accepts`](http://mojolicious.org/perldoc/Mojolicious/Plugin/DefaultHelpers#accepts).

The former, `respond_to`, is much more high level and should be your go-to choice.
It takes key value pairs where the keys are the file types that should be handled (in extension format).
The values are either stash values that should be used when rendering or else a callback to be invoked.

Since I showed you [yesterday](/blog/2017/12/09/day-9-the-best-way-to-test) how to use [Test::Mojo](http://mojolicious.org/perldoc/Test/Mojo), let's examine this as a test.
Imagine a test for an application that returns information about Santa's Reindeer.

%= highlight 'Perl' => include -raw => 'reindeer.t'

In it you can see each file type maps to a set of stash values.
The test cases use a varity of ways to request the different response types.

N.B. I like showing test cases as examples because it not only shows the code, it shows how to test it and what the expected responses should be.

## A More Advanced Case

To demonstrate how powerful this mechanism, let me show you some code that I wrote for a previous job.
That company was friendly to Open Source and so it lives on CPAN as [Mojolicious::Plugin::ReplyTable](https://metacpan.org/pod/Mojolicious::Plugin::ReplyTable).
I won't copy and paste the whole module, you can see it on MetCPAN.

The upshot is that it provides a `reply->table` helper which takes a set of "rectangular" data and renders it as one of many forms.

    use Mojolicious::Lite;
    plugin 'ReplyTable';

    any '/table' => sub {
      my $c = shift;
      my $data = [
        [qw/a b c d/],
        [qw/e f g h/],
      ];
      $c->reply->table($data);
    };

    app->start;

Of course under the hood this is using Content Negotiation and several other modules to provide CSV, HTML, JSON, text, XLS, and XLSX outputs.
It is configurable via several stash values that might be set.
If you'd like to dig into that code to see how it works, please feel free.

