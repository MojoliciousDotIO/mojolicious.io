---
title: Day 24: Async/Await the Mojo Way
disable_content_template: 1
tags:
  - advent
  - non-blocking
author: Joel Berger
images:
  banner:
    src: '/blog/2018/12/24/async-await-the-mojo-way/banner.jpg'
    alt: 'Vancouver Symphony Orchestra with Bramwell Tovey'
    data:
      attribution: |-
        <a href="https://commons.wikimedia.org/w/index.php?curid=15521095">Banner image</a> by <a href="https://www.flickr.com/people/56355577@N06">Vancouver 125 - The City of Vancouver</a> <a href="https://www.flickr.com/photos/vancouver125/5834658432/">Vancouver Symphony Orchestra with Bramwell Tovey</a>. Uploaded by <a href="//commons.wikimedia.org/wiki/User:Skeezix1000" title="User:Skeezix1000">Skeezix1000</a>, <a href="https://creativecommons.org/licenses/by/2.0" title="Creative Commons Attribution 2.0">CC BY 2.0</a>.
data:
  bio: jberger
  description: Announcing Mojo::AsyncAwait - Better non-blocking workflows for Mojolicious
---

## The Problems with Thinking in Asynchronous Code

I've thought a lot about asynchronous code.
Learning it, writing it, teaching it.
Async is hard.

> Learning async programming is about being completely confused and overcomplicating everything and eventually having an 'aha' moment and then being utterly frustrated you don't have a way to teach other people without them needing to go through the same process.
> <cite>[Matt S. Trout](https://shadow.cat/blog/matt-s-trout/)</cite>

While Matt is right, I've thought a lot about that quote and I think I've come up with an underlying problem.
This may sound trite and it may seem obvious, but the problem is that writing asynchronous code is just fundamentally different than writing blocking code.

We've always known how to make one instruction follow another, that's easy, it happens on the next line of code.
Line one executes and then line two.
If line two needs something from line one it will be there.

Say you want to write "get this web resource, then print the title".
In blocking code that is easy!

    use Mojo::Base -strict, -signatures;
    use Mojo::UserAgent;
    use Mojo::Util 'trim';
    my $ua = Mojo::UserAgent->new;

    my $title = trim $ua->get($url)->res->dom->at('title')->text;
    say $title;

In asynchronous code, those two steps don't just follow in sequence, either in execution in the file nor in actual code flow.
A newcomer to nonblocking is told that to make that nonblocking, you need a callback; a thing to do once the transaction is complete.
So they might write this (non-working!) code instead.

    use Mojo::Base -strict, -signatures;
    use Mojo::IOLoop;
    use Mojo::UserAgent;
    use Mojo::Util 'trim';
    my $ua = Mojo::UserAgent->new;
    my $url = 'https://mojolicious.org';

    my $title;
    $ua->get($url, sub ($ua, $tx) {
      $title = trim $tx->res->dom->at('title')->text;
    });
    say $title;

    Mojo::IOLoop->start;

The problem of course is, the print statement happens before the title is extracted.
In fact the print statement happens before the request is even made!

_Because there are a lot of examples, I'll skip the first chunk of code.
Assume those lines are always there going foward._

The fix in this case is easy

    $ua->get($url, sub ($ua, $tx) {
      my $title = trim $tx->res->dom->at('title')->text;
      say $title;
    });
    Mojo::IOLoop->start;

but that isn't always the case.
What if you wanted to return the title rather than print it?
What if wanted to fetch two resources rather than one, whether sequentially or in parallel?

## An Important First Step

Several attempts have been made to organize and improve this situation.
The pattern that seems to have emerged as the preferred choice is [Promises](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Guide/Using_promises).

Promises have a nice property that gets them closer to linear code.
You create and return a promise object that represents the eventual result of the task, though the task itself may not have even started yet.
In our example before we could say

    use Mojo::Promise;

    my $promise = Mojo::Promise->new;
    $ua->get($url, sub ($ua, $tx) {
      my $title = trim $tx->res->dom->at('title')->text;
      $promise->resolve($title);
    });

    $promise->then(sub ($title) {
      say $title;
    })->wait;

At first glance this isn't too much better than the callback.
However, a few nice features emerge.
The most important of which is that the promise object can be returned to the caller and the caller can choose what to do with it.

In useful code you would also want to attach error handling, though I've omitted it here for bevity.
Mojolicious' promise implementation also gives us the `wait` method to start the ioloop if necessary.

Although it is interesting to see how a user can create a promise object to convert a callback api to promises, many libraries, including Mojolicious, now have promise variants built-in.
Rather than depending on the user to create a promise to resolve in the callback, these libraries will just return a promise of their own.
In the Mojolicious project, by convention methods that return promises end in `_p`.

With that we can write similar code to the one above

    my $promise = $ua->get_p($url);

    $promise->then(sub ($tx) {
      my $title = trim $tx->res->dom->at('title')->text;
      say $title;
    })->wait;

However that's slightly different.
The promise above resolved with the title, this one resolves with the transaction.
That brings us to the next interesting feature of promises: the return value of `then` is another promise that is resolved with the return value of the callback.
Additionally, if that value is another promise then they chain, if not then it resolves with the value.

We can use that property to replicate the original promise example above more directly like this

    my $promise = $ua->get_p($url)->then(sub ($tx) {
      return trim $tx->res->dom->at('title')->text;
    });

    $promise->then(sub ($title) {
      say $title;
    })->wait;

This is important if say you had a function that was intended to return a promise that resolved to a title.
Perhaps you might have a function called `get_title_p` that needs to be called from elsewhere in your project.
Rather than relying on the promise that the user-agent returned, you can now post-process and return the title rather than the HTTP response.

    sub get_title_p ($url) {
      my $promise = $ua->get_p($url)->then(sub ($tx) {
        return trim $tx->res->dom->at('title')->text;
      });
      return $promise;
    }

    get_title_p($url)->then(sub ($title) {
      say $title;
    })->wait;

All told, this is a step in the right direction, but it still involves a mental shift in style.
Even if this is easier than using pure callbacks, you still have to keep track of promises, consider the implications of chaining.
You still have to attach callbacks using `then`.
And don't forget error handling callbacks too!

_Editor's note: to this point in the article, it is similar to the Perl Advent Calendar entry [posted just a few days before this one on 2018-12-19](http://www.perladvent.org/2018/2018-12-19.html), humorously presented by Mark Fowler.
If you'd like to see another take on promises and Mojo::Promise specifically, give it a read.
Everything in it is applicable even as this article takes it one step further below ..._

## Async/Await

What we really wish we could tell the Perl interpreter to do is

  - suspend execution until this promise resolves or is rejected
  - then move on to handle tasks
  - when it eventually does resolve or reject
  - then resume processing right here or throw an exception

It is a big ask, but if you could say that, you'd basically get linearity back.
Promises give us the control we'd need for such a mechanism, but until now we in Perl-land lack the ability to suspend and resume the interpreter.
Indeed, some languages already have this mechanism and the result is called the Async/Await pattern.
With a little added magic, howver, we can do just that.

That was a lot of introduction, but now I'm finally ready to introduce [Mojo::AsyncAwait](https://metacpan.org/pod/Mojo::AsyncAwait)!

    use Mojo::AsyncAwait;

    async get_title_p => sub ($url) {
      my $tx = await $ua->get_p($url);
      return trim $tx->res->dom->at('title')->text;
    };

    get_title_p($url)->then(sub ($title) {
      say $title;
    })->wait;

This code behaves exactly the same as before, but there are some noticable differences.
First we declared `get_title_p` using the `async` keyword.
For our purposes this means two things: the function can use the `await` keyword and it must return a promise.
Of course right away you'll see that I don't return a promise from that function.
Don't worry, it gets wrapped in one automatically if needed.

And what is that `await` keyword?
That keyword is the magic suspend/resume that we had hoped for above.
It receives a promise (or a value, which is automatically wrapped in a promise), and tells Perl that it can move on to other things until that promise is resolved or rejected.
When it is the code extracts the value, in this case the transaction, and the execution continues as if it were blocking code!

Now we wish we could do the same when calling `get_title_p`.
Never fear, just wrap it in an async function too, let's call it `main`.

    use Mojo::AsyncAwait;

    async get_title_p => sub ($url) {
      my $tx = await $ua->get_p($url);
      return trim $tx->res->dom->at('title')->text;
    };

    async main => sub {
      my $title = await get_title_p($url);
      say $title;
    };

    main()->wait;

Of course, if we didn't need the intermediary function anymore, we could skip it.
After all, the first example didn't have `get_title_p`, it just fetched the url, extracted the title, and printed it.

    use Mojo::AsyncAwait;

    async main => sub {
      my $tx = await $ua->get_p($url);
      my $title = trim $tx->res->dom->at('title')->text;
      say $title;
    };

    main()->wait;

And now that's what we've done too!

## Real World Use

The above examples were neat, but since they only fetch one url there's no reason to be async.
Let's look at a few quick useful examples where async is a benefit.

### Concurrent Requests

The first case might be to extend our example to fetching multiple urls concurrently.
We can get the promises returned by calling `get_title_p` on each url, then await a new promise that represents all of them.
We use `map` to take the first (only) resolve value from the result of each promise in `all`.

    use Mojo::AsyncAwait;
    use Mojo::Promise;

    async get_title_p => sub ($url) {
      my $tx = await $ua->get_p($url);
      return trim $tx->res->dom->at('title')->text;
    };

    async main => sub (@urls) {
      my @promises = map { get_title_p($_) } @urls;
      my @titles = await Mojo::Promise->all(@promises);
      say for map { $_->[0] } @titles;
    };

    my @urls = (qw(
      https://mojolicious.org
      https://mojolicious.io
      https://metacpan.org
    ));
    main(@urls)->wait;

Were this code written sequentially, the time it would take to run would be the sum of the time to fetch each url.
However, as written, this will run in approximately the time it takes for the slowest url to respond.

### Web Apps

Now let's say you wanted to turn that script into a web API.
If we had a webapp that accepted urls as query parameters and returned the responses as JSON it might look like this

    use Mojolicious::Lite -signatures;
    use Mojo::AsyncAwait;
    use Mojo::Promise;
    use Mojo::Util 'trim';

    plugin 'PromiseActions';

    helper get_title_p => async sub ($c, $url) {
      my $tx = await $c->ua->get_p($url);
      return trim $tx->res->dom->at('title')->text;
    };

    any '/' => async sub ($c) {
      my $urls = $c->every_param('url');
      my @promises = map { $c->get_title_p($_) } @$urls;
      my @titles = await Mojo::Promise->all(@promises);
      $c->render(json => [ map { $_->[0] } @titles ]);
    };

    app->start;

Where the example above would be at

    localhost:3000?url=https%3A%2F%2Fmojolicious.org&url=https%3A%2F%2Fmojolicious.io&url=https%3A%2F%2Fmetacpan.org

That code is almost exactly what you'd write for a blocking implementation except that it would block the server and it have to fetch the urls sequentially.
Instead, since it is written nonblocking, the requests are all made concurrently and the server is still free to respond to new clients.
And yet the code is still very easy to follow.

Note: the [PromiseActions](https://metacpan.org/pod/Mojolicious::Plugin::PromiseActions) plugin automatically attaches error handlers to the controller action when it returns a promise; it is highly recommended when using async actions.

## A Word on Implementation

As stated before Mojo::AsyncAwait requires some mechanism to suspend the interpreter and resume it at that point later on.
Currently, the module uses the somewhat controversial module [Coro](https://metacpan.org/pod/Coro) to do it.
As a bulwark against future implimentation changes, it comes with a pluggable backend system, not unlike how Mojo::IOLoop's pluggable reactor system works.
The default implementation may change and users may choose to use any available backend if they have a preference (once new ones come along, and others  **are** in the works).

## Conclusion

So now the formula is simple.

- Use libraries that return promises rather than take callbacks.
- Use the `async` keyword when declaring functions that need to `await` promises.
- Organize your promises using [all](https://mojolicious.org/perldoc/Mojo/Promise#all), [race](https://mojolicious.org/perldoc/Mojo/Promise#race) (only wait for the first resolved promise) or some [higher order promise](https://mojolicious.io/blog/2018/12/03/higher-order-promises/) when needed.

Hopefully with Mojo::AsyncAwait, writing asynchronous code is finally going to be accessible to those users that haven't yet had Matt's "aha" moment.
And for those of us who have, don't worry, you'll love it too.

_Another excellent resource is [The Evolution of Async JavaScript: From Callbacks, to Promises, to Async/Await](https://www.youtube.com/watch?v=gB-OmN1egV8) by Tyler McGinnis.
It is for JavaScript, but nearly everything applies except they syntax.
Highly recommended._

