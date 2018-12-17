#!/usr/bin/env perl

use Mojolicious::Lite;
use Mojo::SQLite;

helper db => sub {
    state $db = Mojo::SQLite->new( 'sqlite:' . app->home->child( 'docs.db' ) );
    return $db;
};
app->db->auto_migrate(1)->migrations->from_data();

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
            <nav class="navbar navbar-dark bg-dark navbar-expand-sm sticky-top">
                <a class="navbar-brand" href="/">Yancy</a>
                <div class="collapse navbar-collapse" id="navbar">
                    <ul class="navbar-nav ml-auto">
                        <li class="nav-item">
                            <a class="nav-link" href="https://metacpan.org/pod/Yancy">
                                CPAN
                            </a>
                        </li>
                        <li class="nav-item">
                            <a class="nav-link" href="https://github.com/preaction/Yancy">
                                GitHub
                            </a>
                        </li>
                        <li class="nav-item">
                            <a class="nav-link" href="https://kiwiirc.com/nextclient/#irc://irc.perl.org/#yancy?nick=www-guest-?">
                                Chat
                            </a>
                        </li>
                    </ul>
                </div>
                <button class="navbar-toggler" type="button" data-toggle="collapse" data-target="#navbar" aria-controls="navbar" aria-expanded="false" aria-label="Toggle navigation">
                    <span class="navbar-toggler-icon"></span>
                </button>
            </nav>
        </header>
        <main class="container">
            <%= content %>
        </main>
        %= javascript '/yancy/jquery.js'
        %= javascript '/yancy/popper.js'
        %= javascript '/yancy/bootstrap.js'
    </body>
</html>

@@ migrations
-- 1 up
CREATE TABLE pages (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    path VARCHAR UNIQUE NOT NULL,
    markdown TEXT,
    html TEXT
);

