use Mojolicious::Lite;
use Mojo::Pg;

my $pg = Mojo::Pg->new( 'postgres://localhost/blog' );
$pg->migrations->from_data->migrate;

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
