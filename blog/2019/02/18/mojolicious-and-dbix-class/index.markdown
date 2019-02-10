---
status: published
title: Mojolicious and DBIx::Class
disable_content_template: 1
tags:
    - development
    - controller
    - DBIx::Class
author: Doug Bell
images:
  banner:
    src: '/blog/2019/02/18/mojolicious-and-dbix-class/banner.jpg'
    alt: 'Mojolicious (heart) database on a pink background. Original artwork by Doug Bell'
    data:
      attribution: |-
        Original artwork by Doug Bell (licensed CC-BY-SA 4.0). Includes
        the Mojolicious logo (licensed CC-BY-SA 4.0).
data:
  bio: preaction
  description: 'Use Mojolicious and DBIx::Class together more easily with Mojolicious::Plugin::DBIC'
---

[Mojolicious](http://mojolicious.org) is an [MVC
framework](https://mojolicious.org/perldoc/Mojolicious/Guides/Growing#Model-View-Controller).
But, unlike [Catalyst](http://www.catalystframework.org), Mojolicious
does not provide a model API. This is a good thing: Mojolicious works
well with any model layer, including the existing models used by your
current application.

[DBIx::Class](https://metacpan.org/pod/DBIx::Class) is a popular model
layer for Mojolicious applications. DBIx::Class (or "DBIC") is an
[Object-Relational Mapper
(ORM)](https://en.wikipedia.org/wiki/Object-relational_mapping) to map
objects onto a relational database. This allows for a well-organized
model layer, and a standard API to access the data.

For those who read last month's posts on [Writing Reusable
Controllers](/blog/2019/01/21/writing-reusable-controllers/) and
[Writing Extensible
Controllers](/blog/2019/01/28/writing-extensible-controllers/), this
post introduces the end result of those posts: The [Mojolicious DBIC
Plugin](http://metacpan.org/pod/Mojolicious::Plugin::DBIC). This plugin
makes it easier to start using DBIx::Class with Mojolicious.

---

Normally to use DBIx::Class with Mojolicious there's a bunch of glue
I need to write:

* I need to instantiate my DBIx::Class schema
    * Which I then need to make available to my controllers via
      a [helper](https://mojolicious.org/perldoc/Mojolicious/Guides/Rendering#Helpers)
* I need to read my database configuration from my [config
  file](https://mojolicious.org/perldoc/Mojolicious/Guides/Cookbook#Adding-a-configuration-file)
  so that I can have different configurations for development, staging,
  and production
* I need to write controller methods to create, read, update, and delete
  my data

Since everyone who uses DBIx::Class has to do the same thing, I thought
it'd be nice to make a reusable plugin to do all that:
[Mojolicious::Plugin::DBIC](http://metacpan.org/pod/Mojolicious::Plugin::DBIC)

The [Mojolicious DBIC
plugin](http://metacpan.org/pod/Mojolicious::Plugin::DBIC) presently
provides two things (because that's all I've had time for so far):

1. [Configuration to load the schema class and connect to the
   database](https://metacpan.org/pod/Mojolicious::Plugin::DBIC#Configuration)
2. [Controller to easily wire up routes to work with
   data](https://metacpan.org/pod/Mojolicious::Plugin::DBIC::Controller::DBIC)

But, with these two things, starting a Mojolicious web application to
work with your DBIx::Class data mostly involves writing some templates!

# The Notebook

Here's an example application that lets us store some notes. [My schema
is
here](https://github.com/preaction/Mojolicious-Plugin-DBIC/tree/master/t/lib/Local),
and contains a "Notes" table with two fields: "title" and "description".
Our application will let us:

* List our notes
* Read a note
* Edit a note
* Delete a note (and confirm before deleting)
* Create a new note

All in exactly 100 lines of code and templates. We'll call our
application `myapp.pl`.

## Configure a Connection

Before we can start reading data, we need to connect to our database.
It's nice to have a configuration file to configure our database
connection, so we'll use
[Mojolicious::Plugin::Config](https://mojolicious.org/perldoc/Mojolicious/Plugin/Config)
to do that:

    #!/usr/bin/env perl
    use Mojolicious::Lite;
    plugin 'Config';
    plugin 'DBIC';

Then, we need our configuration file (`myapp.conf`) to load our schema (the `Local::Schema` class) and connect to a SQLite database (`data.db`):

    # myapp.conf
    {
        dbic => {
            schema => { 'Local::Schema' => 'dbi:SQLite:data.db' },
        },
    }

## Build Routes

With our schema ready, we need to set up our routes. Each route will
fulfill one of our needs (from above). Each route has the following
configuration (in the route's
[stash](https://mojolicious.org/perldoc/Mojolicious/Guides/Routing#Stash)):

* A controller. The [DBIC
  controller](https://metacpan.org/pod/Mojolicious::Plugin::DBIC::Controller::DBIC)
  that comes with Mojolicious::Plugin::DBIC.
* An action. One of the methods in the DBIC controller.
* A resultset class. Our "Notes" table.
* A template, which we'll write later.
* A name so we can refer to it later in other templates.

These route configurations go below our plugins in our `myapp.pl` file.

    # List notes
    get '/' => {
        controller => 'DBIC',
        action => 'list',
        resultset => 'Notes',
        template => 'notes/list',
    } => 'notes.list';

    # Create a new note
    any [qw( GET POST )], '/notes/new' => {
        controller => 'DBIC',
        action => 'set',
        resultset => 'Notes',
        template => 'notes/edit', # Same form used to edit existing notes
        forward_to => 'notes.get',
    } => 'notes.create';

    # Get a note
    get '/notes/:id' => {
        controller => 'DBIC',
        action => 'get',
        resultset => 'Notes',
        template => 'notes/get',
    } => 'notes.get';

    # Edit a note
    any [qw( GET POST )], '/notes/:id/edit' => {
        controller => 'DBIC',
        action => 'set',
        resultset => 'Notes',
        template => 'notes/edit', # Show the edit form for GET requests
        forward_to => 'notes.get', # View the note after saving
    } => 'notes.edit';

    # Delete a note (and confirm before deleting)
    any [qw( GET POST )], '/notes/:id/delete' => {
        controller => 'DBIC',
        action => 'delete',
        resultset => 'Notes',
        template => 'notes/delete', # Show a confirm page for GET requests
        forward_to => 'notes.list', # View the list after deleting
    } => 'notes.delete';

With our routes done, we can write the last line of code that
Mojolicious::Lite needs:

    app->start;

## Write Templates

Last, we need to write our templates. The templates will tie together
our routes with links and forms. Our five routes from above need four
templates:

* `notes/list.html.ep` - Show a list of our notes. The landing page with
  a link to create new notes.
* `notes/get.html.ep` - Show a single note. Also contains a link to edit
  this note or delete this note.
* `notes/edit.html.ep` - A form to edit a note. Also used to create new
  notes.
* `notes/delete.html.ep` - A page to confirm deleting a note.

We'll add these templates right in the same file (`myapp.pl`) under the
`__DATA__` directive (which goes beneath the `app->start` line). Each
template in the data section starts with `@@` and the template filename.

    __DATA__
    @@ notes/list.html.ep
    <h1>Notes</h1>
    <p>[<%= link_to Create => 'notes.create' %>]</p>
    <ul>
        % for my $row ( $resultset->all ) {
            <li><%=
                link_to $row->title,
                    'notes.get', { id => $row->id }
            %></li>
        % }
    </ul>

    @@ notes/get.html.ep
    % title $row->title;
    %= link_to 'Back' => 'notes.list'
    <h1><%= $row->title %></h1>
    %== $row->description
    <p>
        [<%= link_to 'Edit' => 'notes.edit' %>]
        [<%= link_to 'Delete' => 'notes.delete' %>]
    </p>

    @@ notes/edit.html.ep
    %= stylesheet begin
        label, input[type=text], textarea {
            display: block;
            width: 50vw;
        }
        textarea {
            height: 30vh;
        }
    % end
    %= form_for current_route, method => 'POST', begin
        %= csrf_field
        %= label_for 'title' => 'Title'
        %= text_field 'title'
        %= label_for 'description' => 'Body'
        %= text_area 'description'
        %= submit_button
    % end

    @@ notes/delete.html.ep
    %= stylesheet begin
        form {
            display: inline-block;
        }
    % end
    <h1>Delete <%= $row->title %>?</h1>
    %= link_to 'Cancel' => 'notes.get'
    %= csrf_button_to 'Delete' => 'notes.delete', method => 'POST'

## Start it Up

With our routes configured and our templates written, we can now run our
app. If we haven't yet deployed the database, we can do so with a quick
command:

    perl myapp.pl eval 'app->schema->deploy'

The [Mojolicious `eval`
command](https://mojolicious.org/perldoc/Mojolicious/Command/eval) is
incredibly useful. [Read about the `eval` command and all the other
built-in
commands](https://mojolicious.io/blog/2017/12/05/day-5-your-apps-built-in-commands/).

With our database deployed, we can start the daemon. While we're
developing, we'll use [the Mojolicious development daemon,
`morbo`](https://mojolicious.org/perldoc/morbo) to automatically restart
our app when it changes (we could also add [the AutoReload
plugin](https://metacpan.org/pod/Mojolicious::Plugin::AutoReload) to
automatically refresh our browser when the app restarts).

    $ morbo myapp.pl
    Listening on http://127.0.0.1:3000

And that's it! We've got a quick and easy note-taking application! [See
the full code of our app](myapp.pl). [Read more about
Mojolicious::Plugin::DBIC](https://metacpan.org/pod/Mojolicious::Plugin::DBIC).
