use Mojolicious::Lite;
any '/*path' => sub {
    my ( $c ) = @_;
    return $c->render(
        template => $c->stash( 'path' ),
        format => 'json',
    );
};
app->start;
__DATA__
@@ servers.json.ep
[
    { "ip": "10.0.0.1", "os": "Debian 9" },
    { "ip": "10.0.0.2", "os": "Debian 8" }
]
