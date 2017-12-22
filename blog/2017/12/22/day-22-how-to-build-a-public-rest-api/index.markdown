---
title: 'Day 22: A restful API with OpenAPI'
tags:
    - advent
    - api
    - openapi
    - rest
    - swagger
author: Ed J
images:
  banner:
    src: '/static/pinky_swear.jpg'
    alt: 'Two hands with interlocked pinkies, a pinky swear'
    data:
      attribution: |-
        [Image](https://www.flickr.com/photos/elsabordelossegundos/15418211523) by [mariadelajuana](https://www.flickr.com/photos/elsabordelossegundos/), [CC BY 2.0](https://creativecommons.org/licenses/by/2.0/).
data:
  bio: batman
  description: 'How to build a public REST API for your Mojolicious application'
---
The [OpenAPI](https://www.openapis.org/) Specification is an API description
format for REST APIs. An API specification written using the the rules set by
the Open API Initiative can be used to describe:

* All the available endpoints. An endpoint is a unique resource that can
  access or modify a given object.
* Input parameters, such as headers, query parameters and/or body parameters.
* The structure of the response, including headers status codes and the body -
  if any.
* Authentication methods
* Contact information, license, terms of use and other information

This post look into how to write an API specification and how to use it
together with
[Mojolicious::Plugin::OpenAPI](https://metacpan.org/pod/Mojolicious::Plugin::OpenAPI)
and [OpenAPI::Client](https://metacpan.org/pod/OpenAPI::Client).
---

## Why would you use OpenAPI

This question comes up quite often after telling people about OpenAPI:
"but...why?" The people asking this often come from the same background as
myself, where you both write the producer (backend web server) and consumer
(JavaScript, ...) of the data. When you're in complete control of both sides
you don't really need to write any formal specification or document your API,
since you already _know_ how it works. This can be very true - at least if you
make sure you have tests of all your endpoints.

Personally I'm a [huge fan](http://www.linkognito.com/images/05-08-08/metal.gif)
of documenting as well as testing. I often say that if you can't document
(describe) the API/method/whatever, something is wrong and you should reconsider
what you're coding. Documenting an API on the other hand is awful in my opinion,
especially during rapid prototyping/developing where it's hard to keep the
code and documentation up to date.

So how does OpenAPI fix this? Since the input/ouput Perl code is generated
_from_ the OpenAPI Specification, you know that the backend is always running
code accordingly to the specification. Also, since the documentation you
generate is not hand written, but generated from the same OpenAPI document you
can with certainty know that the code the server is running, is in sync with
the documentation.

By "generated code" I don't just mean the routes/endpoints, but also input and
output validation. This means that when any data has made it through to your
controller action, you know that the data is valid. On the other side, the
consumer (let's say a JavaScript that cares about the difference between an
integer and string) will know that it has received the correct data, since
invalid output will result in a
[500 - Internal Server Error](https://en.wikipedia.org/wiki/List_of_HTTP_status_codes#5xx_Server_Error).

So... If you don't care about documentation or collaboration with others, then
I'm not sure if I would care much about OpenAPI either.

Note that the OpenAPI spec is not just for the server, but can also be used to
generate [JavaScript](int://github.com/swagger-api/swagger-js) and
[Perl client side code](https://metacpan.org/pod/OpenAPI::Client) code.

## Prerequisites

To run any of the example code below, you need to install the following
modules:

```shell
$ cpanm Mojolicious::Plugin::OpenAPI # server side plugin
$ cpanm OpenAPI::Client              # client to talk with the server
$ cpanm YAML::XS                     # to read YAML formatted specifications
```

## How to write the specification

Some people like to generate the specification from code, but I truly believe
that writing the specification by hand and the generate code is the right way
to do it. The reasoning behind this is "seperation of concern": Having the
specification in a common format (JSON or YAML) allow other non-perl developer
to contribute and read the document.

The API need to follow the rules set by the
[OpenAPI specification](https://github.com/OAI/OpenAPI-Specification/blob/master/versions/2.0.md).
In this post we will use the 2.0 version, but version
[3.0](https://github.com/OAI/OpenAPI-Specification/blob/master/versions/3.0.0.md)
will be available soon, so you might consider looking at that as well.

Here is an example API, written in YAML:

```yaml
swagger: '2.0'
info:
  version: '0.42'
  title: Dummy example
schemes: [ http ]
basePath: "/api"
paths:
  /echo:
    post:
      x-mojo-to: "echo#index"
      operationId: echo
      parameters:
      - in: body
        name: body
        schema:
          type: object
      responses:
        200:
          description: Echo response
          schema:
            type: object
```

There's a bunch of things to dive into, but here is a quick overview:

* `swagger` is just to specify the version of the spec
* `info` is to give some meta-information about the API
* `schemes` is a list of valid HTTP schemes that can be used to access the API
* All the resources under `paths` will be relative to `basePath`, meaning that
  you need to use `/api/echo` to access the "echo" resource.
* The key `post` under `/echo` tells you which HTTP method you need to use to
  access the resource.
* `x-mojo-to` is specific for
  [Mojolicious::Plugin::OpenAPI](https://metacpan.org/pod/Mojolicious::Plugin::OpenAPI),
  and will be passed on to the route's
  [to()](https://metacpan.org/pod/Mojolicious::Routes::Route#to) method.
* `operationId` is used by
  [OpenAPI::Client](https://metacpan.org/pod/OpenAPI::Client) and other
  clients to generate a method that can be used to access the resource from
  the client side.
* `parameters` and `responses` contains a description of the acceptable input
  and output.

While this article will not talk further about how to make a
`Mojolicious::Lite` web app, the key to getting your routes recognised
are to make them have the right path (in this case, `/echo` - it will
get moved by the plugin under `/api`) and the right `name` (the third
parameter to eg `get`) to match either the `x-mojo-name` or `operationId`.

## How to use the specification in your Mojolicious application

The example application will use the specification above to generate routes
and input/output validation rules. The app is a full-app, but you can also
write Mojolicious lite-apps and still use the plugin.

To start off, we can use the "generate" command to create the app:

```shell
$ mojo generate app MyApp
```

After that, edit `lib/MyApp.pm` to make it look like this:

```perl
package MyApp;
use Mojo::Base "Mojolicious";

sub startup {
  my $self = shift;

  # Load the "api.yaml" specification from the public directory
  $self->plugin(OpenAPI => {spec => $self->static->file("api.yaml")->path});
}

1;
```

Then copy/paste the specification from above and save it to `public/api.yaml`.

Last you must create a controller `lib/MyApp/Controller/Echo.pm` to match
`x-mojo-to` in the API specification:

```perl
package MyApp::Controller::Echo;
use Mojo::Base "Mojolicious::Controller";

sub index {
  # Validate input request or return an error document
  my $self = shift->openapi->valid_input or return;

  # Render back the same data as you received using the "openapi" handler
  $self->render(openapi => $self->req->json);
}

1;
```

And you're done creating an OpenAPI powered application!

## Running your application

To see what you just created, you can run your application:

```shell
$ ./script/my_app routes
/api      *        api
  +/      GET
  +/echo  POST     "echo"
  +/echo  OPTIONS  echo
```

From the output above, we can see that the expected route `/api/echo` is
generated, so let's see if we can send/receive any data to the server. To try
it out, we use the "openapi" sub command which was installed with
[OpenAPI::Client](https://metacpan.org/pod/OpenAPI::Client).

In this first example we try to send invalid body data using the `-c` switch:

```shell
$ MOJO_LOG_LEVEL=info ./script/my_app openapi /api echo -c '[42]'
{"errors":[{"message":"Expected object - got array.","path":"\/body"}]}
```

This next example should succeed, since we change from sending an array to
sending an object, as described in the API specification:

```shell
$ MOJO_LOG_LEVEL=info ./script/my_app openapi /api echo -c '{"age":42}'
{"age":42}
```

Yay! We see that the same input data was echoed back to us, without any error
message. Mission accomplished!

## See also

Did you find OpenAPI interesting? Check out these resources to find out more:

* [Mojolicious::Plugin::OpenAPI](https://metacpan.org/release/Mojolicious-Plugin-OpenAPI)
  contains guides and synopsis to get you started.
* [OpenAPI::Client](https://metacpan.org/pod/OpenAPI::Client)'s manual
  contains more information about how the client side works.
* [Swagger's about page](https://swagger.io/docs/specification/about/) has
  information about the specification and OpenAPI.
* [OAI](https://www.openapis.org/) is the official OpenAPI resource page.
* [JSON::Validator](https://metacpan.org/pod/JSON::Validator) is the "brain"
  behind both the plugin and client side in Perl. Check it out, if you're
  interested in JSON-Schema.
