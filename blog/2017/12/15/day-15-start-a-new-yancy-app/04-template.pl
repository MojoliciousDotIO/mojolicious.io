use Mojolicious::Lite;
use Mojo::Pg;

my $pg = Mojo::Pg->new( 'postgres://localhost/blog' );
$pg->migrations->from_data->migrate;

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

get '/' => sub {
    my ( $c ) = @_;
    return $c->render(
        'index',
        posts => [ $c->yancy->list(
            'blog', {}, { order_by => { -desc => 'created' } },
        ) ],
    );
};

app->start;

__DATA__
@@ index.html.ep
<!doctype html>
<html lang="en">
  <head>
    <title>Hello, world!</title>
    <!-- Required meta tags -->
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1, shrink-to-fit=no">

    <!-- Bootstrap CSS -->
    <link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/4.0.0-beta.2/css/bootstrap.min.css" integrity="sha384-PsH8R72JQ3SOdhVi3uxftmaW6Vc51MKb0q5P2rRUpPvrszuE4W1povHYgTpBfshb" crossorigin="anonymous">
  </head>
  <body>
    <main role="main" class="container">
    % for my $post ( @{ stash 'posts' } ) {
      <%== $post->{html} %>
    % }
    </main>

    <!-- Optional JavaScript -->
    <!-- jQuery first, then Popper.js, then Bootstrap JS -->
    <script src="https://code.jquery.com/jquery-3.2.1.slim.min.js" integrity="sha384-KJ3o2DKtIkvYIK3UENzmM7KCkRr/rE9/Qpg6aAZGJwFDMVNA/GpGFF93hXpG5KkN" crossorigin="anonymous"></script>
    <script src="https://cdnjs.cloudflare.com/ajax/libs/popper.js/1.12.3/umd/popper.min.js" integrity="sha384-vFJXuSJphROIrBnz7yo7oB41mKfc8JzQZiCq4NCceLEaO4IHwicKwpJf9c9IpFgh" crossorigin="anonymous"></script>
    <script src="https://maxcdn.bootstrapcdn.com/bootstrap/4.0.0-beta.2/js/bootstrap.min.js" integrity="sha384-alpBpkh1PFOepccYVYDB4do5UnbKysX5WZXm3XxPqe5iKTfUKjNkCk9SaVuEZflJ" crossorigin="anonymous"></script>
  </body>
</html>

@@ migrations
-- 1 up
CREATE TABLE blog (
    id SERIAL PRIMARY KEY,
    title VARCHAR NOT NULL,
    created TIMESTAMP NOT NULL DEFAULT NOW(),
    markdown TEXT NOT NULL,
    html TEXT NOT NULL
);
-- 1 down
DROP TABLE blog;
