---
title: 'Day 8: Mocking a REST API'
tags:
    - advent
    - mocking
    - api
author: Doug Bell
images:
  banner:
    src: '/static/1280px-crash-test-dummies.jpg'
    alt: 'Two crash test dummies'
    data:
      attribution: |-
        <a href="https://commons.wikimedia.org/w/index.php?curid=37564272">Image</a> by Calspan Corporation, National Highway Traffic Safety Administration - Public Domain.
data:
  bio: preaction
  description: 'Doug uses Mojolicious to quickly build a mock api for testing a front-end application.'
---

One of my applications is a pure-JavaScript UI for a JSON API. This UI
is an entirely different project that communicates with a public API
using an OpenAPI specification.

Our public API is huge and complex: To set up the public API, I need
a database, sample data, and three other private API servers that
perform individual tasks as directed by the public API. Worse, I would
need to set up a lot of different test scenarios with different kinds of
data.

It would be a lot easier to set up a mock public API that I could use to
test my UI, and it turns out that Mojolicious makes this very easy.

So let's set up a simple Mojolicious::Lite app that responds to a path
with a JSON response:

%= highlight Perl => "# test-api.pl\n" . include -raw => '01-get.pl'

Now I can fetch that JSON response by starting the web application and
going to `/servers` or by using the `get` command:

    $ perl test-api.pl get /servers
    [{"ip":"10.0.0.1","os":"Debian 9"},{"ip":"10.0.0.2","os":"Debian 8"}

    $ perl test-api.pl daemon
    Server available at http://127.0.0.1:3000

That's pretty easy and shows how easy Mojolicious can be to get started.
But I have dozens of routes in my application! Combined with all the
possible data and its thousands of routes. How do I make all of them
work without copy-pasting code for every single route?

Let's match the whole path of the route and then create a template with
the given path. Mojolicious lets us match the whole path using the `*`
placeholder in the route path. Then we can use that path to look up the
template, which we'll put in the `__DATA__` section.

%= highlight Perl => "# test-api.pl\n" . include -raw => '02-template.pl'

Again, we can use the `get` command to test that we get the right data:

    $ perl test-api.pl get /servers
    [
        { "ip": "10.0.0.1", "os": "Debian 9" },
        { "ip": "10.0.0.2", "os": "Debian 8" }
    ]

So now I can write a bunch of JSON in my script and it will be exposed
as an API. But I'd like it to be easier to make lists of things: REST
APIs often have one endpoint as a list and another as an individual item
in that list. We can make a list by composing our individual parts using
Mojolicious templates and the `include` template helper:

%= highlight Perl => "# test-api.pl\n" . include -raw => '03-include.pl'

Now I can test the list endpoint again:

    $ perl test-api.pl get /servers
    [
        { "ip": "10.0.0.1", "os": "Debian 9" }
    ,
        { "ip": "10.0.0.2", "os": "Debian 8" }
    ]

And also one of the individual item endpoints:

    $ perl test-api.pl get /servers/1
    { "ip": "10.0.0.1", "os": "Debian 9" }

Currently we handle all request methods (`GET`, `POST`, `PUT`, `DELETE`)
the same, but my API doesn't work like that. So, I need to be able to
provide different data for different request methods. To do that, let's add the
request method to the template path:

%= highlight Perl => "# test-api.pl\n" . include -raw => '04-method.pl'

Now all our template paths start with the HTTP request method (`GET`),
allowing us to add different routes for `POST` requests and other HTTP
methods.

We also added a `POST/servers.json.ep` template that shows us getting
a successful response from adding a new server via the API. It even
correctly gives us back the data we submitted, like our original API
might do.

We can test our added `POST /servers` method with the `get` command
again:

    $ perl test-api.pl get -M POST -c '{ "ip": "10.0.0.3" }' /servers
    { "status": "success", "id": 3, "server": { "ip": "10.0.0.3" } }

Now what if I want to test what happens when the API gives me an error?
Mojolicious has an easy way to layer on additional templates to use for
certain routes: [Template
variants](http://mojolicious.org/perldoc/Mojolicious/Guides/Rendering#Template-variants).
These variant templates will be used instead of the original template,
but only if they are available. Read more on [how to use template
variants yesterday on the advent
calendar](/blog/2017/12/07/day-7-using-template-variants-for-a-beta-landing-page/).

By setting the template variant to the application "mode", we can easily
switch between multiple sets of templates by adding `-m <mode>` to the
command we run.

%= highlight( Perl => "# test-api.pl\n" . include -raw => '05-variant.pl' )

    $ perl test-api.pl get -m error -M POST -c '{}' /servers
    { "status": "error", "error": "Bad request" }

And finally, since I'm using this to test an AJAX web application,
I need to allow the preflight `OPTIONS` request to succeed and I need to
make sure that all of the correct `Access-Control-*` headers are set
to allow for cross-origin requests.

%= highlight Perl => "# test-api.pl\n" . include -raw => '06-ajax.pl'

Now I have 20 lines of code that can be made to mock any JSON API
I write. Mojolicious makes everything easy!

