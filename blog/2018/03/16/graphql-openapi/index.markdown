---
title: 'Mojolicious, OpenAPI - and GraphQL'
tags:
    - api
    - openapi
    - swagger
    - graphql
author: Ed J
images:
  banner:
    src: '/static/todo.jpg'
    alt: 'TODO'
    data:
      attribution: ""
data:
  bio: mohawk
  description: 'How to easily add a GraphQL interface to the public REST API of your Mojolicious application'
---

# How to easily add a GraphQL interface to the public REST API of your Mojolicious application

During the Mojolicious 2017 Advent calendar series, we looked at [how to build a public REST API using Mojolicious](https://mojolicious.io/blog/2017/12/22/day-22-how-to-build-a-public-rest-api/). A technology that is getting a lot of buzz is [GraphQL](http://graphql.org/learn/). Now that it has been [ported to Perl 5](https://metacpan.org/pod/GraphQL), what if there were an easy way to let people access your API using it?
---

## Why use GraphQL

GraphQL could be considered an evolution of OpenAPI. It not only allows, but forces you to clearly specify all of your types, inputs and outputs, and available queries and mutations, in a simple, clear way. When you make actual queries, you request everything that you want to get back, and you get back all of that, with no unnecessary extras, and with just one request. This saves both time and network bandwidth.

To learn more about how to use it, there is a translation of the [JavaScript tutorial](http://graphql.org/graphql-js/) for GraphQL into [Perl using Mojolicious](http://blogs.perl.org/users/ed_j/2017/10/graphql-perl---graphql-js-tutorial-translation-to-graphql-perl-and-mojoliciousplugingraphql.html).

## Prerequisites

To run the example code below, you need to have gone through the "build a public REST API" article and installed its prerequisites, and made your app. Then install the following modules:

```shell
$ cpanm Mojolicious::Plugin::GraphQL      # server side plugin
$ cpanm GraphQL::Plugin::Convert::OpenAPI # convert OpenAPI spec to GraphQL
```

## How to add GraphQL to your existing REST API

To do the bare minimum to get our miniature API going with GraphQL, we just need to change `lib/MyApp.pm` a little:

```perl
# add this at the top:
use Mojo::File 'path';

# change the `OpenAPI` line to:
my $path = $self->static->file("api.yaml")->path;
my $api = $self->plugin(OpenAPI => {spec => $path});
$self->plugin(GraphQL => {convert => [ qw(OpenAPI), $api->validator->bundle, $self ], graphiql => 1});
```

This gets the `plugin` object returned by the OpenAPI plugin, then uses that to pass the API spec along to the GraphQL plugin. The `graphiql` flag is to tell the plugin to deliver the "GraphiQL" interface if you request the `/graphql` interface with your browser. We'll talk more about that soon.

We'll also add a tiny test this works to `t/basic.t`:

```perl
$t->post_ok('/graphql', json => {
  query => 'mutation m {echo(body: [{key:"one", value:"two"}]) { key value }}'
})->json_is(
  { data => { echo => [{key=>"one", value=>"two"}] } },
)->or(sub { diag explain $t->tx->res->body });
```

Check it still all works right:

```shell
$ prove -l t
```

This makes a GraphQL request as conventionally done over HTTP. There are two points to note:
- it's a "mutation", which probably sounds like it would change something, but here it doesn't - it's still just an "echo" service
- both the inputs and outputs look like hashes with `key` and `value` attributes

The reason it's a mutation is because our basic REST API used a `POST` route so it could pass in an arbitrary JSON `object`. The GraphQL plugin treats all routes that aren't a `GET` as mutations. It also turns such an `object` into a list of "hash pairs", which are turned to/from a real hash before passing to/getting back from the REST API.

Let's add a slightly more realistic REST API, then we'll be able to use Facebook's excellent "GraphiQL" tool to talk to our API!

## Adjusting the REST API specification

We're going to add a `GET` echo route, and a fake user-creation `POST` route, including the controller code and tests. We'll also add a `User` definition, which will be turned into a GraphQL type of the same name (the other "pairs" stuff gets turned into types as well). For simplicity, we'll modify our `index` so it works as the user-creating code in the `Echo` controller, but in real life you should already see how you'd divide different things into different modules for easier maintenance.

Make your `api.yaml` read:

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
    get:
      x-mojo-to: "echo#index"
      operationId: echoGet
      parameters:
      - in: query
        name: q
        type: string
      responses:
        200:
          description: Echo response
          schema:
            type: string
  /user:
    post:
      x-mojo-to: "echo#index"
      operationId: createUser
      parameters:
      - in: body
        name: user
        schema:
          $ref: "#/definitions/User"
      responses:
        200:
          description: Created User
          schema:
            $ref: "#/definitions/User"
definitions:
  User:
    type: object
    properties:
      name:
        type: string
      email:
        type: string
```

Now change your `lib/MyApp/Controller/Echo.pm` so the index method is:

```perl
sub index {
  # Validate input request or return an error document
  my $self = shift->openapi->valid_input or return;
  my $data = $self->req->method eq 'POST'
    ? $self->req->json
    : $self->req->param('q');
  # Render back the same data as you received using the "openapi" handler
  $self->render(openapi => $data);
}
```

Of course you'll want to update your tests, so add this to `t/basic.t`:

```perl
$t->get_ok('/api/echo?q=good')->status_is(200)->json_is("good");
$t->post_ok('/api/user', json => {email=>'a@b',name=>'Bob'})->json_is(
  {email=>'a@b', name=> 'Bob'}
);
$t->post_ok('/graphql', json => {
  query => '{echoGet(q: "Hello")}'
})->json_is(
  { data => { echoGet => 'Hello' } },
)->or(sub { diag explain $t->tx->res->body });
$t->post_ok('/graphql', json => {
  query => 'mutation m {createUser(user: {email:"one@a", name:"Bob"}) { email name }}'
})->json_is(
  { data => { createUser => {email=>'one@a', name=>'Bob'} } },
)->or(sub { diag explain $t->tx->res->body });
```

By now you know how to run the tests!

## How to use GraphiQL to interactively talk to your API

Start up your service:

```shell
$ ./script/my_app daemon -l 'http://*:5000'
```

And connect your browser to http://localhost:5000/graphql and try this query:

```
{echoGet(q: "hi")}
```

Now do a fake "user creation":

```
mutation m {
  createUser(user: {
    email: "one@two"
    name: "Jan"
  }) {
    email
    name
  }
}
```

For further exploration, use the "Docs" button in the top-right of the window. It will show you the available types, starting from the root `Query` (whose fields are all the queries), and `Mutation`, which has our `createUser` with input that's a `UserInput` and output that's a `User`.

## See also

Did you find GraphQL interesting? Check out these resources to find out more:

* [See the GitHub repo with the code for this app](https://github.com/graphql-perl/sample-openapi-local).
* [GraphQL](https://metacpan.org/pod/GraphQL)'s manual
  contains more information about how the core library works.
* [Mojolicious::Plugin::GraphQL](https://metacpan.org/pod/Mojolicious::Plugin::GraphQL) is how to hook Mojolicious apps up to the core library.
* [GraphQL::Plugin::Convert::OpenAPI](https://metacpan.org/pod/GraphQL::Plugin::Convert::OpenAPI) is how to hook an OpenAPI interface to GraphQL.
* [GraphQL::Plugin::Convert::DBIC](https://metacpan.org/pod/GraphQL::Plugin::Convert::DBIC) is how to hook an existing `DBIx::Class` interface to GraphQL.
* [GraphQL's about page](http://graphql.org/) has
  information about GraphQL and what it's all about.

## Author

### Ed J

Ed J (aka "mohawk" on IRC) has been using Perl for a long time. He is currently porting the reference GraphQL implementation from the JavaScript version to Perl. Find out more by joining the #graphql-perl channel on irc.perl.org!
