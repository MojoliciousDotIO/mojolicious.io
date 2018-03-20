---
title: 'Day 15: Start a New Yancy App'
tags:
    - advent
    - app
author: Doug Bell
images:
  banner:
    src: '/static/scaffold.jpg'
    alt: 'Workers on a scaffold'
    data:
      attribution: |-
        [Image](http://www.publicdomainpictures.net/view-image.php?image=6416) in the public domain.
data:
  bio: preaction
  description: 'Rapid-prototype a data-backed application using Mojolicious and Yancy.'
---
[Yancy](http://metacpan.org/pod/Yancy) is a new content management
plugin for the [Mojolicious web framework](http://mojolicious.org).
Yancy allows you to easily administrate your site’s content just by
describing it using [JSON Schema](http://json-schema.org). Yancy
supports [multiple backends](http://metacpan.org/pod/Yancy::Backend), so
your site's content can be in
[Postgres](http://metacpan.org/pod/Yancy::Backend::Pg),
[MySQL](http://metacpan.org/pod/Yancy::Backend::Mysql), and
[DBIx::Class](http://metacpan.org/pod/Yancy::Backend::Dbic).

---

## Demonstration
For an demonstration application, let’s create a simple blog using
[Mojolicious::Lite](http://mojolicious.org/perldoc/Mojolicious/Lite).
First we need to create a database schema for our blog posts. Let's use
[Mojo::Pg](http://metacpan.org/pod/Mojo::Pg) and its [migrations
feature](http://metacpan.org/pod/Mojo::Pg::Migrations) to create a table
called "blog" with fields for an ID, a title, a date, some markdown, and
some HTML.

%= highlight Perl => "# myapp.pl\n" . include -raw => '01-migrate.pl'

Next we add [the Yancy
plugin](http://metacpan.org/pod/Mojolicious::Plugin::Yancy) and tell it
about our backend and data. Yancy deals with data as a set of
collections which contain items. For a relational database like
Postgres, a collection is a table, and an item is a row in that table.

Yancy uses a JSON schema to describe each item in a collection.
For our `blog` collection, we have five fields:

1. `id` which is an auto-generated integer and should be read-only
2. `title` which is a free-form string which is required
3. `created` which is an ISO8601 date/time string, auto-generated
4. `markdown` which is a required Markdown-formatted string
5. `html`, a string which holds the rendered Markdown and is also required

Here's our configured Yancy `blog` collection:

%= highlight Perl => begin
plugin Yancy => {
    backend => 'pg://localhost/blog',
    collections => {
        blog => {
            required => [ 'title', 'markdown', 'html' ],
            properties => {
                id => {
                    type => 'integer',
                    readOnly => 1,
                },
                title => {
                    type => 'string',
                },
                created => {
                    type => 'string',
                    format => 'date-time',
                    readOnly => 1,
                },
                markdown => {
                    type => 'string',
                    format => 'markdown',
                    'x-html-field' => 'html',
                },
                html => {
                    type => 'string',
                },
            },
        },
    },
};
% end

Yancy will build us a rich form for our collection from the field types
we tell it. Some fields, like the `markdown` field, take additional
configuration: `x-html-field` tells the Markdown field where to save the
rendered HTML. There's plenty of customization options in [the Yancy
configuration documentation](http://metacpan.org/pod/Yancy#CONFIGURATION).

Now we can start up our app and go to <http://127.0.0.1:3000/yancy> to
manage our site's content:

    $ perl myapp.pl daemon
    Server available at http://127.0.0.1:3000

![Screen shot of adding a new blog item with Yancy](adding-item.png)
![Screen shot of Yancy after the new blog item is added](item-added.png)

Finally, we need some way to display our blog posts.  [Yancy provides
helpers to access our
data](http://metacpan.org/pod/Mojolicious::Plugin::Yancy#HELPERS). Let's
use the `list` helper to display a list of blog posts. This helper takes
a collection name and gives us a list of items in that collection. It
also allows us to search for items and order them to our liking. Since
we've got a blog, we will order by the creation date, descending.

%= highlight Perl => begin
get '/' => sub {
    my ( $c ) = @_;
    return $c->render(
        'index',
        posts => [ $c->yancy->list(
            'blog', {}, { order_by => { -desc => 'created' } },
        ) ],
    );
};
% end

Now we just need an HTML template to go with our route! Here, I use the standard
[Bootstrap 4 starter template](http://getbootstrap.com/docs/4.0/getting-started/introduction/#starter-template)
and add this short loop to render our blog posts:

    <main role="main" class="container">
    %% for my $post ( @{ stash 'posts' } ) {
        <%%== $post->{html} %>
    %% }
    </main>

[Now we have our completed application](04-template.pl) and we can test
to see our blog post:

    $ perl myapp.pl daemon
    Server available at http://127.0.0.1:3000

![The rendered blog post with our template](blog-post.png)

Yancy provides a rapid way to get started building a Mojolicious
application (above Mojolicious’s already rapid development). Yancy
provides a basic level of content management so site developers can
focus on what makes their site unique.

