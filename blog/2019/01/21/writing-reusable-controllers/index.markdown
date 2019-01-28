---
images:
  banner:
    alt: Clouds with user icons raining gears
    data:
      attribution: |-
        Resized/cropped image from StockVault by Jack Moreh licensed under
        [StockVault Commercial
        license](https://www.stockvault.net/photo/177237/network-concept-with-cloud-technology)
    src: /blog/2019/01/21/writing-reusable-controllers/banner.jpg
author: Doug Bell
data:
  bio: preaction
  description: Learn how to write re-usable controllers for your application
disable_content_template: 1
status: published
tags:
  - development
  - controller
  - DBIx::Class
title: Writing Reusable Controllers
---

In all the web applications I've written with
[Mojolicious](http://mojolicious.org), one of the most mis-used features
are controllers. Mojolicious is
a [Model-View-Controller](https://mojolicious.org/perldoc/Mojolicious/Guides/Growing#Model-View-Controller)
framework, and the MVC pattern is intended to provide for code re-use.

Models can be interchangeable and used by the same controllers and
templates. With a common, consistent model API, the right controller can
list any data, update any data. If all of our models have a method named
"search", I can make a single controller method that will run a search
on any of them.

The easiest way to demonstrate this is with
[DBIx::Class](http://metacpan.org/pod/DBIx::Class). DBIx::Class provides
a consistent API for a relational database. 

## The Problem

For this example, I'll use [this DBIx::Class
schema](https://github.com/preaction/Mojolicious-Plugin-DBIC/tree/master/t/lib/Local).
My schema has a couple tables: `notes` for storing simple notes, and
`events` for storing calendar events.

---

In order to work with my data, I need to write some controller methods:

    package MyApp::Controller::Notes;
    sub list {
        my ( $c ) = @_;
        my $resultset = $c->schema->resultset( 'Notes' );
        $c->render(
            template => 'notes/list',
            resultset => $resultset,
        );
    }

    package MyApp::Controller::Events;
    sub list {
        my ( $c ) = @_;
        my $resultset = $c->schema->resultset( 'Events' );
        $c->render(
            template => 'events/list',
            resultset => $resultset,
        );
    }

Well, that's less-than-ideal: I've just copy/pasted the same code and
changed a few words. And now I need to do the same for looking at
individual notes/events, creating, updating, and deleting.

Copy/pasting code is tedious and makes code harder to maintain. It would
be much nicer if we could write one controller and just configure it to
use our different tables!

## The Stash

The way to configure controllers is through the [Mojolicious
stash](https://mojolicious.org/perldoc/Mojolicious/Guides/Tutorial#Stash-and-templates),
the data store for a request. When setting up a route, I can add stash
values that will be used by my controller. This includes the "reserved"
stash values like "template" which tells Mojolicious what template to
render by default.

If, instead of above, I write a controller method that looks in the
stash for its configuration, I can reuse it by changing those stash
values.

    package MyApp::Controller::DBIC;
    sub list {
        my ( $c ) = @_;
        my $resultset_class = $c->stash( 'resultset' );
        my $resultset = $c->schema->resultset( $resultset_class );
        $c->render(
            resultset => $resultset,
        );
    }

Now I've got a "list" method that accepts a ResultSet class in the
`resultset` stash. 

Then I can configure a route (`/notes`) which will route to the DBIC
controller I've created and the `list` method inside it to list the
Resultset I tell it to with the template I give it:

    use Mojolicious::Lite;
    use Local::Schema;
    my $dsn = 'dbi:SQLite:data.db';
    # Controller will use this to get our schema
    helper schema => Local::Schema->connect( $dsn );
    # List all our notes
    get '/notes' => {
        controller => 'DBIC',
        action => 'list',
        resultset => 'Notes',
        template => 'notes/list',
    } => 'notes.list';
    app->start;
    __DATA__
    @@ notes/list.html.ep
    <ul><% for my $row ( $resultset->all ) { %>
        <li><%= $row->title %></li>
    <% } %></ul>

## Route Placeholders

That's all fine and good for simple tasks like listing all the things,
but what about when there's a variable involved, like looking up items
by their ID? Again, we just need a little configuration, this time the
row's ID:

    package MyApp::Controller::DBIC;
    sub get {
        my ( $c ) = @_;
        my $resultset_class = $c->stash( 'resultset' );
        my $id = $c->stash( 'id' );
        my $resultset = $c->schema->resultset( $resultset_class );
        my $row = $resultset->find( $id );
        $c->render(
            row => $row,
        );
    }

Now, since route placeholders are put into the stash, I can use them to
configure my controller as well. So, when a user visits `/notes/34`,
they will see the note with an ID of '34':

    # ...
    get '/notes/:id' => {
        controller => 'DBIC',
        action => 'get',
        resultset => 'Notes',
        template => 'notes/get',
    } => 'notes.get';
    # ...
    __DATA__
    @@ notes/get.html.ep
    % title $row->title;
    <h1><%= $row->title %></h1>
    %== $row->description

With this new named route, I can display the saved note.

*Note*: By exposing the stash to the URL, users can type in any ID they
want. So, if you have data you don't want users to see, make sure to
protect it!

## ... And more

I can continue doing this for "create", "update", and "delete" actions
as well, making an application much easier to assemble: Most of my code
will (rightly) be in my model classes and my templates.

I can also add more features to my "DBIC" controller:

* Stash values to set [ResultSet `search()` condition and options
  hashes](https://metacpan.org/pod/DBIx::Class::ResultSet#search).
* Expose search columns and options to query parameters, safely
* Add JSON API responses using [the `respond_to`
  helper](https://mojolicious.org/perldoc/Mojolicious/Plugin/DefaultHelpers#respond_to)
* Pagination on the `list` method

Once the features are added once, every route can take advantage of
them.

Since there's little point in multiple copies of the exact same "DBIC"
controller, I wrote one and released it to CPAN as
[Mojolicious::Plugin::DBIC](http://metacpan.org/pod/Mojolicious::Plugin::DBIC).
The [code for this example is available on
Github](https://github.com/preaction/Mojolicious-Plugin-DBIC/tree/master/eg).

If DBIx::Class isn't your model layer, or even if it is,
[Yancy](http://preaction.me/yancy) provides [configurable
controllers](http://preaction.me/yancy/perldoc/Yancy/Controller/Yancy)
like this, along with an [app to edit
content](http://preaction.me/yancy/perldoc/#DESCRIPTION).
