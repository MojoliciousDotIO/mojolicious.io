---
title: 'Day 20: Practical Testing'
tags:
    - advent
    - mocking
    - testing
    - wishlist
author: Joel Berger
images:
  banner:
    src: '/blog/2017/12/20/day-20-practical-testing/lava.jpg'
    alt: 'Taking a sample of lava at Kilauea'
    data:
      attribution: |-
        <a href="https://commons.wikimedia.org/w/index.php?curid=11337658">Image</a> by Hawaii Volcano Observatory, USGS - <a rel="nofollow" class="external text" href="http://hvo.wr.usgs.gov/kilauea/update/archive/2009/2009_Jun-Oct.html">Kilauea image archive for June-October 2009</a>: see entry for 26 June 2009., Public Domain.
data:
  bio: jberger
  description: Some practical tricks for testing real-world applications.
---

Back on [Day 9](/blog/2017/12/09/day-9-the-best-way-to-test) we discussed testing and especially [Test::Mojo](http://mojolicious.org/perldoc/Test/Mojo).
Today I want to just briefly talk about some practical things that can come up when testing real world applications.
Once again the discussion will be motivated by the [Wishlist](https://github.com/jberger/Wishlist) application that we've been developing these past few days.
---

## Configuration Overrides

In the Day 9 article I mentioned that the Test::Mojo [constructor](http://mojolicious.org/perldoc/Test/Mojo#new) could be passed configuration overrides.
In this example we can see how that override lets us ensure that we are testing on a fresh and isolated database.

%= highlight Perl => include -raw => 'model.t'
<small>[t/model.t](https://github.com/jberger/Wishlist/blob/blog_post/practical_testing/t/model.t)</small>

When called this way the passed hashref is loaded into the configuration rather than any configuration file.
Because of the way the [`sqlite`](https://github.com/jberger/Wishlist/blob/blog_post/practical_testing/lib/Wishlist.pm#L20-L26) attribute initializer was coded, the Mojo::SQLite special literal `:temp:` is passed through unchanged.
Now I would never suggest that you write any code into your application that is specific to testing, however it is entirely reasonable to code around special literals that someone might need.
You could of course start a Wishlist server using a temporary database.

SQLite's in-memory (and Mojo::SQLite's on-disk temporary) databases are really handy for testing because they are automatically testing in isolation.
You don't have to worry about overwriting the existing database nor clearing the data at the end of your test.
Further, you can run your tests in [parallel](https://metacpan.org/pod/Test::Harness#j<n>) to get a nice speedup in large test suites.

For databases that require a running server you have to be a little more careful, however isolated testing is still very possible.
For example, in Mojo::Pg you can set a [`search_path`](http://mojolicious.org/perldoc/Mojo/Pg#search_path) which isolates your test.

    my $t = Test::Mojo->new(
      'MyApp',
      {database => 'postgresql:///test?search_path=test_one'}
    );
    $pg->db->query('drop schema if exists test_one cascade');
    $pg->db->query('create schema test_one');
    ...
    $pg->db->query('drop schema test_one cascade');

You might have to be careful about when the migration happens too (ie disable `auto_migrate` and run it manually).
Also this will only isolate the tests per-name, here `test_one`.
Therefore I recommend you name the path for the name of the test file, this should be both descriptive and unique.
And you have to clean up after yourself otherwise the next time the test is run it will be affected by the remaining data.

## Mocking Helpers

If you have done any testing you've probably dealt with mocking, but if you haven't, mocking is the act of replacing functionality from essentially unrelated code with test-specific code.
Doing this lets you test one section of code (called a unit) in isolation from others.

Everyone has their favorite mock library.
There are so many tastes and styles that in the end Many people make their own, including [yours truly](https://metacpan.org/pod/Mock::MonkeyPatch).
Of course you can use those libraries in Mojolicious when appropriate.
As I mentioned before you can also mock out services by attaching tiny Mojolicious applications to a UserAgent's [`server`](http://mojolicious.org/perldoc/Mojo/UserAgent#server) attribute or making an entire external service as Doug showed us on [Day 8](https://mojolicious.io/blog/2017/12/08/day-8-mocking-a-rest-api/).

In some cases however, the natural place to mock is in the place of a helper.
When you think about it, this is actually rather obvious since helpers are often the glue used in Mojolicious applications to combine disparate code, like models or in this case the [LinkEmbedder](https://github.com/jberger/Wishlist/blob/blog_post/practical_testing/lib/Wishlist.pm#L55-L59).

To test this we could actually do any of the mentioned options from mocking [LinkEmbedder->get](https://metacpan.org/pod/LinkEmbedder#get) to attaching a mock service.
That said it is sufficient here to just replace the helper, which is as easy as assigning over it.

%= highlight Perl => include -raw => 'embed.t'
<small>[t/embed.t](https://github.com/jberger/Wishlist/blob/blog_post/practical_testing/t/embed.t)</small>

Because the template expects the result to be an object we have to build a tiny class to contain our mock results.
Also whenever you are mocking, it is important to check the input your mock received as well as the results that the calling code derives from your mock return value.

In the test you can also see some examples of how to use selectors to test for both text and attribute values.
The text test is especially important because it shows that the html value that I got back from the LinkEmbedder isn't being escaped by the template and will render as HTML to the client.

A few more tests and some documentation and our application will really be taking final shape!

