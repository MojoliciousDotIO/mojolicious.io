---
title: 'Day 11: UserAgent Content Generators'
tags:
    - advent
    - useragent
author: Joel Berger
images:
  banner:
    src: '/static/artist-painting-1459778857j86.jpg'
    alt: 'Artist painting'
    data:
      attribution: |-
        [Image](http://www.publicdomainpictures.net/view-image.php?image=157945&picture=artist-painting) in the Public Domain.
data:
  bio: jberger
  description: Using Mojo::UserAgent Content Generators to build request bodies.
---

We have already seen [Mojo::UserAgent](http://mojolicious.org/perldoc/Mojo/UserAgent) used to make HTTP requests in this series.
In fact we've already seen how you can use [Content Generators](http://mojolicious.org/perldoc/Mojolicious/Guides/Cookbook#USER-AGENT) to build requests [in tests](/blog/2017/12/09/day-9-the-best-way-to-test#making-requests).
But we didn't look at how they work or how you can add new ones.
---

## Using Content Generators

The UserAgent, and more specifically its [Transactor](http://mojolicious.org/perl/Mojo/UserAgent/Transactor), help you by making it easy to create HTTP requests.
Consider the most basic request with a body, a `POST` with a binary body, maybe ASCII text.
In that case, the request

    my $ua = Mojo::UserAgent->new;
    $ua->post(
      '/url',
      {'Content-Type' => 'text/plain'},
      'some binary content'
    );

is equivalent to

    my $ua = Mojo::UserAgent->new;
    my $tx = $ua->build_tx(POST => '/url');
    $tx->req->headers->header('Content-Type', 'text/plain');
    $tx->req->body('some binary content');
    $ua->start($tx);

A Content Generators is a shortcut to help build requests for certain types of content.
The previous example wasn't technically a Content Generator as these are indicated by a generator name and usually accept arguments.
That said, you can almost imagine that setting the body content is the default generator.

The simplest use of an actual Content Generator is the one the builds a JSON request.
A JSON post like

    $ua->post('/url', json => {some => ['json', 'data']});

does two things, it builds the binary form of the body and it sets the `Content-Type` header.
To do it manually it would be either

    use Mojo::JSON 'encode_json';
    $ua->post(
      '/url',
      {'Content-Type' => 'application/json'},
      encode_json({some => ['json', 'data']})
    );

or a similar example to the above using `build_tx`.
I think you'll agree that the generator form is much easier to read and "does what you mean".

At the time of this writing, Mojo::UserAgent comes with three [built-in Content Generators](http://mojolicious.org/perldoc/Mojo/UserAgent/Transactor#tx), including the `json` one as we've already seen.

The `form` generator creates urlencoded or multipart requests depending on the data passed.
The form generator is, unsurprisingly, useful for submittng forms, often used to login to sites, search for content or upload files.
It is even smart enought to use query parameters for `GET` and `HEAD` requests (which cannot take a body), while using body parameters for others.

Finally, the recently-added `multipart` generator is for building your own generic multipart requests.
Though not common, some APIs allow or even require users to upload multiple files in the same request.

This was the case presented to us by a user not too long ago.
They were interacting with the [Google Drive API](https://developers.google.com/drive/v3/web/multipart-upload) that wanted them to upload a file as part of a multipart message with a JSON document attached containing metadata.
The overall request was to be marked at [`multipart/related`](https://tools.ietf.org/html/rfc2387) while each part should have its own `Content-Type`.
Google's documented example is

    POST https://www.googleapis.com/upload/drive/v3/files?uploadType=multipart HTTP/1.1
    Authorization: Bearer [YOUR_AUTH_TOKEN]
    Content-Type: multipart/related; boundary=foo_bar_baz
    Content-Length: [NUMBER_OF_BYTES_IN_ENTIRE_REQUEST_BODY]

    --foo_bar_baz
    Content-Type: application/json; charset=UTF-8

    {
      "name": "myObject"
    }

    --foo_bar_baz
    Content-Type: image/jpeg

    [JPEG_DATA]
    --foo_bar_baz--

While this was possible using the lower level tools, we decided that adding a generator for it would make using that API much easier for them.
Thus the `multipart` generator was added to the mix.
Using it, one can make a compliant request by writing something like

%= highlight 'Perl' => include -raw => 'multipart.pl'

Though you have to form the parts a little more manually (no, generators don't call other generators), this is still a much simpler use than building the message manually.
Most notably, the length calculations and all of the boundary handling is done transparently.

## Adding New Content Generators

So if you are reading this and thinking that Content Generators look great but the type you need isn't available, take heart!
Adding content generators is easy too!
As seen in the [documentation](http://mojolicious.org/perldoc/Mojo/UserAgent/Transactor#add_generator) adding a generator is as simple as adding a callback that will build the request.

To motivate this discussion, I'll introduce another module.
At work, I had to use [XML-RPC](http://xmlrpc.scripting.com/spec.html) to interact with a remote service.
XML-RPC defines an XML schema for asking the service to call a method, just as you would locally, by method name and with some arguments.
It then returns a result or fault (exception).
These responses also contain arguments, that is to say, the response data.

Personally I find it is much easier to learn something new by seeing how it works.
I pulled [XMLRPC::Fast](https://metacpan.org/pod/XMLRPC::Fast) from CPAN and started inspecting the code.
It started to make sense to me, but I noticed that it used [XML::Parser](https://metacpan.org/pod/XML::Parser) for its XML.
Since Mojolicious has tools for that, I decided to continue learning by porting the code to [Mojo::Template](http://mojolicious.org/perldoc/Mojo/Template) and [Mojo::DOM](http://mojolicious.org/perldoc/Mojo/DOM).

By the time I finished I had completely rewritten the module and decided that perhaps others would benefit from it in environments already using the Mojo stack.
So with much thanks to XMLRPC::Fast and its author Sébastien Aperghis-Tramoni I released my own as [Mojo::XMLRPC](https://metacpan.org/pod/Mojo::XMLRPC).
My module (as did the original) only has functions that build the XML payloads.
Therefore, to make a simple request, pass the result of encoding as XML-RPC as the body of a request, like so

%= highlight 'Perl' => include -raw => 'xmlrpc.pl'

which produces a request like

%= highlight 'xml' => include -raw => 'xmlrpc.txt'

Although the usage isn't terribly difficult, how would it look as a Content Generator?

%= highlight 'Perl' => include -raw => 'xmlrpc_generator.pl'

which produces an output essentially identical to the first.

At first glance it only appears to be a modest improvement.
However, once defined, it does cut down on repeated code for subsequent requests.
Thus the benefit grows the more times it is used.
In a larger code base, that adherence to the DRY mantra (Don't Repeat Yourself) might be invaluable.



