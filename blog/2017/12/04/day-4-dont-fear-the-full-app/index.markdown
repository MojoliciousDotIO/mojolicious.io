---
title: "Day 4: Don't Fear the Full App"
tags:
    - advent
    - lite
    - full
    - growing
author: Joel Berger
images:
  banner:
    src: '/static/arucaria.jpg'
    alt: 'Arucaria trees in Curitiba Brazil'
    data:
      attribution: |-
        Image is copyright (c) 2013 Joel Berger.
        It shows a pair of Arucaria trees in the city of Curitiba, during YAPC::Brasil 2013.
        It is licensed under a <a rel="license" href="http://creativecommons.org/licenses/by-sa/4.0/">Creative Commons Attribution-ShareAlike 4.0 International License</a>.
data:
  bio: jberger
  description: Growing from Lite to Full apps is easy. There's no magic to worry about.
---
One of the most common misconceptions about Mojolicious is that there is a large difference between the declarative "Lite" apps that we have seen so far and large-scale structured "Full" apps.
Nothing could be further from the truth.
[Mojolicious::Lite](http://mojolicious.org/perldoc/Mojolicious/Lite) is a very tiny wrapper around the so-called "Full" app architecture, giving it the approachable keyword syntax.

Because it is much nicer to have concise single-file examples for documentation most of Mojolicious' documentation uses Lite syntax most of the time.
It is understandable that people worry about migrating (or as we call it "growing") even once their apps would benefit from Object-Oriented structure; after all the docs seem geared towards Lite apps.
However, let those fears go, the transition is easy.
And once you understand it, the documentatation examples are trivial to translate.

Plus, Mojolicious comes with two forms of help when transitioning.
The first is the [Growing Guide](http://mojolicious.org/perldoc/Mojolicious/Guides/Growing) which covers everything this post will but from the perspective of porting an existing application (which I won't duplicate here).
The second is the [inflate command](http://mojolicious.org/perldoc/Mojolicious/Command/inflate) which can even start you on the process by moving your templates from the data section and into their own files.

That said, in order to futher demystify things, I'm going to cover some of the differences and pull back the curtain on the Lite syntax itself.
---
## Let Me Convince You

After repeated attempts to convince people that there is very little difference between the two, I've found that there is one really great way to turn the conversation.
I show them the code.
No really [take a look](https://github.com/kraih/mojo/blob/master/lib/Mojolicious/Lite.pm).
As of this writing, Mojolicious::Lite is only 37 lines of code (as computed by David A. Wheeler's [SLOCCount](https://www.dwheeler.com/sloccount/))!
How much difference could there be in 37 lines of code?

Ok now that you believe me, let's talk about those few differences.

## The Script and the Class

In a Lite script, your application logic lives right there in the script.
If a Full app, your logic goes in a separate class, mostly in the `startup` method, but remove `app->start` line.
While the first argument to a method (the invocant) is usually called `$self`, and you will see that, to keep things clear in this series I will always use `$app`.
So we have:

    sub startup {
      my $app = shift;
      ... # the rest of what was your script
    }

Meanwhile the script that is run is just a few lines that start the app.
That script is always the same thing, having nothing to do with your app but the name of the class to invoke.
I just use the one at the [end of the Growing Guide](http://mojolicious.org/perldoc/Mojolicious/Guides/Growing#Script).

## The Keywords

Now that the code lives in the right place, it needs to be translated to be Object Oriented.
The first step is to place the logic into a method called `startup`, which takes the application object as its first argument.

There are really three types of keywords, those that are the application object or methods on the application, those that are methods on the router, and `group`.

The `app` keyword is just that invocant from before, so `app` becomes `$app`.
The keywords `helper`, `hook`, and `plugin` are just methods on the app, so `plugin ...` becomes `$app->plugin(...)`, etc.

The routing methods

  - `any`
  - `del` (as `delete`)
  - `get`
  - `options`
  - `patch`
  - `post`
  - `put`
  - `websocket`

are methods on route objects used exactly as they were before.
To get the toplevel route object, call `$app->routes`; by convention we call this toplevel route object `$r`.

    get '/' => sub { ... } => 'route_name';

becomes

    my $r = $app->routes;
    $r->get('/' => sub { ... } => 'route_name');
    ... # add more toplevel routes to $r

These are what we call 'hybrid routes'.
They basically use the Lite arguments but are given to the methods.
As you get deeper into Mojolicious, you might like setting up routes via attributes better than by a positional argument

    $r->get('/')->to(cb => sub { ... })->name('route_name');

but either way works, choose the one you like!
TIMTOWTDI again.

If you've only used those keywords above, translate them as I just showed you and you're done.

### Nested Routing

By now, you must have seen that I keep qualifying my statement as 'toplevel routes'.
Well ok so there is one small difference between Lite and Full, and that difference is how nested routes work.

There are two other keywords, `under` and `group`.
`under` allows routes to share code, like say for authentication.
They also can share parts of their path.
For example, parts of an API that need authentication might be all under `/protected`.

    get '/unsafe' => 'unsafe';

    under '/protected' => sub {
      # check authentication
    };

    # /protected/safe
    get '/safe' => 'safe';

In Lite apps, these protected routes are literally *under* their `under`.
That works fine until you think, "now wait, that means I can't ever get back to the unprotected space."
Well spotted!
That's where `group` comes in.

    get '/unsafe' => 'unsafe';

    group {
      under '/protected' => sub {
        # check authentication
      };

      # /protected/safe
      get '/safe' => 'safe';
    };

    get '/another_unsafe' => ...;

### Wait, What?

If you are confused, that's ok.
I'm going to let you in on a little secret, I think this is confusing too.
The Lite form of nesting routes is really more for completeness, once you need it, it is probably a good sign that you should look at switching to Full apps instead.
Full apps have it much easier!

In a Full app, the route methods all return a new route object.
If you store those in a variable, you can use them to build off of each other.
This is a much more natural API for building nested structures in my opinion.

    my $r = $app->routes;
    $r->get('/unsafe' => 'unsafe');

    my $protected = $r->under('/protected' => sub {
      # check authentication
    });

    # /protected/safe
    $protected->get('/safe' => 'safe');

    $r->get('/another_unsafe' => ...);

Since Lite app keywords don't have a way to attach to another route, they basically always add them to the "current global route".
That's where the confusion comes in.

Speaking of which, I'm going to let you in even deeper on my secret.
I like the chained type of routing so much more than using `group` that I actually use it in my Lite apps.
Sure I still use `app` and `plugin`, but one of the first things I do is `my $r = app->routes`.
Then, I use that instead of the routing keywords in all but the simplest of cases.

## Conclusion

That's it, with the exception of using `group` for nested routing, it is just direct translation.
And if you always use the method forms of routing you don't even need to worry about that!
With that, I encourage you to go back and read the [Tutorial and Guides](http://mojolicious.org/perldoc#TUTORIAL) and realize that everything that looks like Lite apps is really just as true for Full ones.

