---
title: A Website For Yancy
disable_content_template: 1
tags:
    - advent
    - yancy
author: Doug Bell
images:
  banner:
    src: '/blog/2018/12/17/a-website-for-yancy/banner.jpg'
    alt: 'Code on a computer screen'
    data:
      attribution: |-
        Banner image CC0 Public Domain
data:
  bio: preaction
  description: 'Building a markdown-based site with Yancy'
---

For this year, I decided that Yancy needed a website. Rather than build
a website with a [static site generator like
Statocles](http://preaction.me/statocles), which is so popular these
days, I decided to do something wild and unpredictable: A dynamic
website! Lucky for me, I have the perfect project to easily build
a dynamic website: Yancy!
---

The key part of any dynamic website is the database. Since I just want
to write Markdown and render HTML, my schema is quite simple: A place to
store the page's path, a place to store the page's Markdown for editing,
and a place to put the rendered HTML. I set up a SQLite database and
build the pages table using
[Mojo::SQLite::Migrations](https://metacpan.org/pod/Mojo::SQLite::Migrations).

    #!/usr/bin/env perl
    use Mojolicious::Lite;
    use Mojo::SQLite;
    helper db => sub {
        state $db = Mojo::SQLite->new( 'sqlite:' . app->home->child( 'docs.db' ) );
        return $db;
    };
    app->db->auto_migrate(1)->migrations->from_data( 'main' );

    # Start the app. Must be the code of the script
    app->start;

    __DATA__
    @@ migrations
    -- 1 up
    CREATE TABLE pages (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        path VARCHAR UNIQUE NOT NULL,
        markdown TEXT,
        html TEXT
    );

With our database table prepared, I need a way to edit my pages. Yancy's
built-in editor comes with [marked.js](https://marked.js.org/) to render
Markdown into HTML. I just need to tell it which column is Markdown and
where to store the HTML. We'll use the path as the ID to make it easy to
retrieve our pages.

    plugin 'Yancy', {
        backend => { Sqlite => app->db },
        read_schema => 1,
        collections => {
            pages => {
                'x-id-field' => 'path',
                'x-list-columns' => [qw( path )],
                'x-view-item-url' => '/{path}',
                properties => {
                    id => {
                        readOnly => 1,
                    },
                    markdown => {
                        format => 'markdown',
                        'x-html-field' => 'html',
                    },
                },
            },
        },
    };

Now we can create some pages. I can start up the app with `perl myapp.pl
daemon`, and then edit my content by visiting
`http://127.0.0.1:3000/yancy`. The site will especially need an index
page, so I'll create one.

![Screenshot showing the Yancy editor adding an "index"
page](edit-index.png)
![Screenshot showing the Yancy editor listing the index page in the
database](list-index.png)

With our content created, I need to add a route to display it. Using the
[`*` wildcard
placeholder](https://mojolicious.org/perldoc/Mojolicious/Guides/Routing#Wildcard-placeholders),
the route will match any path. I can then look up the page requested
from the database using the [Yancy controller `get`
action](https://metacpan.org/pod/Yancy::Controller::Yancy/get). I set
a default of "index" to pull our index page when users visit "/". Last,
the route will need a little bit of a template just to display the
page's HTML and a layout with some useful links and maybe some
[Bootstrap](http://getbootstrap.com) to make things look a bit nicer.

    get '/*id' => {
        id => 'index', # Default to index page
        controller => 'yancy',
        action => 'get',
        collection => 'pages',
        template => 'pages',
    };
    # Start the app. Must be the last code of the script
    app->start;
    __DATA__
    @@ pages.html.ep
    % layout 'default';
    %== $item->{html}

    @@ layouts/default.html.ep
    <!DOCTYPE html>
    <html>
        <head>
            <link rel="stylesheet" href="/yancy/bootstrap.css">
            <title><%= title %></title>
        </head>
        <body>
            <header>
                <!-- Omitted for brevity -->
            </header>
            <main class="container">
                <%= content %>
            </main>
            %= javascript '/yancy/jquery.js'
            %= javascript '/yancy/popper.js'
            %= javascript '/yancy/bootstrap.js'
        </body>
    </html>

Now I can open my website and see the index page I created!

![Screenshot showing the index page for the site](view-index.png)

Now I have a basic website! [Here's the code so far](myapp.pl). This is
a good start, but I'll need more if it's going to be useful...
