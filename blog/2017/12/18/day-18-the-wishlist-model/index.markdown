---
title: 'Day 18: The Wishlist Model'
tags:
    - advent
    - model
    - example
    - wishlist
author: Joel Berger
images:
  banner:
    src: '/static/van_gogh_still_life.jpg'
    alt: 'Still Life: Vase with Pink Roses by Vincent van Gogh'
    data:
      attribution: |-
        <a href="https://commons.wikimedia.org/w/index.php?curid=10510831">Image</a> "Still Life: Vase with Pink Roses" by <a href="https://en.wikipedia.org/wiki/en:Vincent_van_Gogh" class="extiw" title="w:en:Vincent van Gogh">Vincent van Gogh</a> - <a rel="nofollow" class="external text" href="http://www.nga.gov/content/ngaweb/Collection/art-object-page.72328.html">National Gallery of Art</a>, Public Domain.
data:
  bio: jberger
  description: Building a proper model layer for the Wishlist app.
---

[Yesterday](https://mojolicious.io/blog/2017/12/17/day-17-the-wishlist-app/) we discussed templates features like layouts, partial templates, and content buffers.
We motivated the discussion by introducing a fully functioning example application that tracked user's Christmas wishlists.
That application did lack sophistication in the area of data storage, using [DBM::Deep](https://metacpan.org/pod/DBM::Deep) for quickly getting a basic persistence layer.
While that worked well enough to demonstrate template functionality it was no triumph of the model layer.
Indeed some very hack techniques are used, especially in manipulating wishlist items, since there was no unique record ids.

Well as promised I have created a [repository](https://github.com/jberger/Wishlist) for the application on Github.
I have also added several tags.
While development on the application may continue, those tags will remain for future readers.

The initial form of the application (as seen in yesterday's post) is tagged [`blog_post/dbm_deep`](https://github.com/jberger/Wishlist/tree/blog_post/dbm_deep).
You are then invited to step through the commits [from that one to `blog_post/full_app`](https://github.com/jberger/Wishlist/compare/blog_post/dbm_deep...blog_post/full_app) to follow along as I port it from a Lite to a Full app; a practical demonstration of what we saw on [Day 4](https://mojolicious.io/blog/2017/12/04/day-4-dont-fear-the-full-app/).

This article will briefly discuss the application as it exists in the next tag, [`blog_post/sqlite_model`](https://github.com/jberger/Wishlist/tree/blog_post/sqlite_model).
At this point I have replaced DBM::Deep with [Mojo::SQLite](https://metacpan.org/pod/Mojo::SQLite), written a rudimentary model layer for it, and connected the two with the application via helpers.
Let's see how that improves the application and in the meantime, get a look at idiomatic database access in Mojolicious!
---

## Model View Controller

Most modern web applications adhere to a pattern called [Model View Controller](https://en.wikipedia.org/wiki/Model%E2%80%93view%E2%80%93controller) or MVC.
Much has been written about MVC, more than could be conveyed here.
Quickly though, the view is how data is displayed, the template.
The model is the database, both read and write access, and how to manipulated it.
This is usually thought of as the "business logic".
Finally the controller is supposed to be the minimal amount of logic that can be used to connect the two and process web requests.

In Perl almost all relational database access is via [DBI](https://metacpan.org/pod/DBI) whether directly or indirectly.
However this isn't a model as such, a model really needs to have defined data layout (schema) and manipulation.

Many Perl users turn to [DBIx::Class](https://metacpan.org/pod/DBIx::Class), an [Object-Relational Mapper](https://en.wikipedia.org/wiki/Object-relational_mapping) (ORM), and this is a great choice.
It hides most of the SQL and creates classes for the tables.
However some developers like staying a little closer to the SQL.

## Mojo-Flavored DBI

The Mojolicious community has several modules that live partway between DBI and DBIx::Class.
I lovingly call them "Mojo-Flavored DBI" collectively.
The first of these was [Mojo::Pg](https://metacpan.org/pod/Mojo::Pg) for [PostgreSQL](https://www.postgresql.org/).
Quickly, copycat modules were made, [Mojo::mysql](https://metacpan.org/pod/Mojo::mysql) for [MySQL](https://www.mysql.com/) and [Mojo::SQLite](https://metacpan.org/pod/Mojo::SQLite) for the embedded database [SQLite](https://www.sqlite.org/).

These are attractive because they are lightweight in comparison to ORMs.
They feature schema migration management and similar [fluent interfaces](https://mojolicious.io/blog/2017/12/12/day-12-more-than-a-base-class/) as Mojolicious.
They handle connection pooling and nonblocking access (emulated in the case of SQLite).
In recent versions, they also wrap [SQL::Abstract](https://metacpan.org/pod/SQL::Abstract) which can be used to simplify certain common actions.
SQL::Abstract is also used by DBIx::Class, so as you'd expect, these have a feel similar to an ORM.

Going forward with this article, I will use Mojo::SQLite since it doesn't require an external database.

## The Schema

The first thing we need to establish is the database schema; the collection of tables and their columns.
In Mojo-Flavored DBI these are collected into one file, broken up by comments.
These comments and their following contents define how to move between schema version.

%= highlight SQL => include -raw => 'wishlist.sql'
<small>wishlist.sql</small>

Here you can see how to move from the empty version 0 up to version 1.
You can also define how to move back down though it is ok to ignore those and not support downgrading.

The schema we define mimics the one we used yesterday.
Users have names.
Items have titles, urls, purchased state (SQLite doesn't have a boolean) and a reference to the user that requested it.

## The Model Class

I extracted the business logic from the [original application's controller actions](https://metacpan.org/pod/SQL::Abstract), anything that handled persistence, and moved them to a dedicated class, [Wishlist::Model](https://github.com/jberger/Wishlist/blob/blog_post/sqlite_model/lib/Wishlist/Model.pm).

%= highlight Perl => include -raw => 'Model.pm'
<small>lib/Wishlist/Model.pm</small>

This class define the ways that the application can alter the data in the database.
Rather than the familiar DBI methods like `selectrow_arrayref`, Mojo-Flavored DBI make a query and then ask for the result shape they want returned.
The user can ask for a row as a hash or an array.
They can also ask for and array of all thr rows, again as a hash or an array.
Sometimes there are other data you want rather than the actual results, like the `last_insert_id` or the number of `rows` affected.

Most of the methods are simple enough to employ the SQL::Abstract forms: add, update, remove, even listing the users.
However for getting a user we want to make a more complex `query` by hand.
It looks up the user row by name, and aggregates the items that user is wishing for as JSON.

Before fetching the results we tell Mojo::SQLite that we would like to expand the JSON back into Perl data transparently.
This [`expand`](https://metacpan.org/pod/Mojo::SQLite::Results#expand) method differs slightly from the other flavors since SQLite doesn't have metadata to give Mojo::SQLite hints about which column to expand.
Once setup, when we call `hash` we get a nice Perl structure as a result.

## The Application Class

The application class might look quite different but its behavior is very similar to yesterday.
Don't fret over every line, I will only cover the important things for our purposes.

%= highlight Perl => include -raw => 'Wishlist.pm'
<small>lib/Wishlist.pm</small>

There is an application attribute which holds the Mojo::SQLite instance.
Its initializer pulls the name of the database file from configuration or defaults to `wishlist.db` as before.
Unlike with DBM::Deep we now also have to tell it where to find the migrations file.
To target these files we use the application's [`home`](http://mojolicious.org/perldoc/Mojolicious#home) object and [Mojo::File](http://mojolicious.org/perldoc/Mojo/File) which is a topic for another day.

The application's `startup` method establishes a `model` helper which creates an instance of Wishlist::Model and attaches the Mojo::SQLite instance to it.
This is a very important concept because this very thin helper is what ties the model into the application as a whole.
Any part of the application that needs data from the model ends up using this helper.

For example, there are still the `user` and `users` helpers that behave just as their counterparts from yesterday.
This time however they work via the model to do their business.

Finally the routes use the Full app declaration style but they do basically the same thing as before once they dispatch to their controllers.

## The List Controller

And speaking of controllers, let's see what a controller looks like now.
This is the List controller that handles most of the pages.

%= highlight Perl => include -raw => 'List.pm'
<small>lib/Wishlist/Controller/List.pm</small>

While all the same business logic is accomplished, this time the semantic model methods are used rather than manipulating the data directly.
THe methods establish what they want to be done not how to do it.
This is much better MVC and will serve you better in the long run.

So is this the end of our discussion of the Wishlist app?
Who can say?
