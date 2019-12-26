---
status: published
title: Announcing Core async/await
disable_content_template: 1
tags:
  - async/await
  - non-blocking
  - promises
author: Joel Berger
images:
  banner:
    src: '/blog/2019/12/26/announcing-core-async-await/radar.jpg'
    alt: 'Radar dish at sunset'
    data:
      attribution: |-
        Image: [michaelqiao13591 on pixabay.com](https://www.needpix.com/photo/1768752/radar-blue-cozy-gorgeous-free-pictures-free-photos-free-images-royalty-free-free-illustrations)
data:
  bio: jberger
  description: Wrap up the 2018 Calendar with news and gratitude.
---
For years one of my primary tasks as a Mojolicious Core Team member has been to teach Mojolicious users the ins and outs of asynchronous programming.
We have championed several patterns to tame the beast and clean up async code, including continuation passing, promises and now async/await.
But while promises were a noted improvement over continuation passing, it is becoming more and more clear that the async/await pattern is a paradigm shift in asynchronous programming semantics.

I personally believe that it is far and away the easiest way to do nonblocking code in modern languages.
It might even reach the extent that languages and/or frameworks that do not support it are going to be in real trouble as new user will expect it to be available.
Soon many may not have even been exposed to "the old ways" at all!

Last year, during the 2018 Mojolicious Advent Calendar, I [introduced](https://mojolicious.io/blog/2018/12/24/async-await-the-mojo-way/) my [Mojo::AsyncAwait](https://metacpan.org/pod/Mojo::AsyncAwait) library which was intended to address the immediate need for the Mojolicious community, based on the Mojolicious core promise module [Mojo::Promise](https://mojolicious.org/perldoc/Mojo/Promise).
It did rely on a "controversial" module ([Coro](https://metacpan.org/pod/Coro)) to accomplish its task, and therefore it was not a good candidate for all users.

Meanwhile, others in the Perl community were noticing as well.
Paul Evans (LeoNerd) applied for and received [a grant](https://news.perlfoundation.org/post/grant_proposal_futureasyncawai) from The Perl Foundation to build a low-level async/await mechanism for his [Future](https://metacpan.org/pod/Future) promise library.
As that project has successfully culminated in [Future::AsyncAwait](https://metacpan.org/pod/Future::AsyncAwait) on CPAN, the Mojolicious team has been engaging with Paul on a collaboration to allow Mojo::Promise to hook directly into it.

So without futher ado, the Mojolicious Core Team is very happy to announce that as of the most recent release of Mojolicious, async/await is now a built-in framework feature!

---

The feature is experimental, so be careful when using it in production services for now (ie, probably don't until we remove that warning).
Indeed, for the moment Paul is still finalizing a few details that will not affect end users, so we've temporarily forked a "frozen" version of it (Future::AsyncAwait::Frozen) so that we can make it available to our users as soon as possible; once his module is ready we will move right back to the main one.
Also note that Future::AsyncAwait has some requirements on Perl versions that will also apply to using this feature in Mojolicious as well.

The feature is optional, so all you need to do is install Future::AsyncAwait::Frozen (or Future::AsyncAwait once it is ready) and use the new `-async` import flag.

One additional change is that the Mojolicious applications will now also notice controller actions that return promises (as all async functions automatically do) and attach error handlers to them.
In my article from last year I promoted the PromiseActions plugin from CPAN for this purpose but that is no longer needed with this new core functionality!

As an example, from [the Mojolicious Cookbook](https://mojolicious.org/perldoc/Mojolicious/Guides/Cookbook#async-await), this Lite app makes two non-blocking HTTP requests, and extracts the HTML title from each response, all without blocking the server.
See how clean and understandable the code is!

    use Mojolicious::Lite -signatures, -async;

    get '/' => async sub ($c) {
      my $mojo_tx    = await $c->ua->get_p('https://mojolicious.org');
      my $mojo_title = $mojo_tx->result->dom->at('title')->text;
      my $cpan_tx    = await $c->ua->get_p('https://metacpan.org');
      my $cpan_title = $cpan_tx->result->dom->at('title')->text;

      $c->render(json => {mojo => $mojo_title, cpan => $cpan_title});
    };

    app->start;

To learn more about async/await read [last year's article](https://mojolicious.io/blog/2018/12/24/async-await-the-mojo-way/) (though you don't need my module or PromiseActions anymore) or watch [this great video](https://www.youtube.com/watch?v=gB-OmN1egV8) (which focuses on Javascript but will teach all the concepts).
Then read the new [Cookbook entries](https://mojolicious.org/perldoc/Mojolicious/Guides/Cookbook#async-await) to learn the specifics for core Mojo.

It happens to be Mojolicious's 9th birthday today and to celebrate we're very excited to bring you this new technology!
We hope you'll use it and share it with your friends and then tell us about your experiences with it.
And as always happy Perling!
