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
