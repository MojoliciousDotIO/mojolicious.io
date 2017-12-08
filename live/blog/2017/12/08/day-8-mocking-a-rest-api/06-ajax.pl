use Mojolicious::Lite;
hook after_build_tx => sub {
my ($tx, $app) = @_;
    $tx->res->headers->header( 'Access-Control-Allow-Origin' => '*' );
    $tx->res->headers->header( 'Access-Control-Allow-Methods' => 'GET, POST, PUT, PATCH, DELETE, OPTIONS' );
    $tx->res->headers->header( 'Access-Control-Max-Age' => 3600 );
    $tx->res->headers->header( 'Access-Control-Allow-Headers' => 'Content-Type, Authorization, X-Requested-With' );
};
any '/*path' => sub {
    my ( $c ) = @_;
    # Allow preflight OPTIONS request for XmlHttpRequest to succeed
    return $c->rendered( 204 ) if $c->req->method eq 'OPTIONS';
    return $c->render(
        template => join( '/', uc $c->req->method, $c->stash( 'path' ) ),
        variant => $c->app->mode,
        format => 'json',
    );
};
app->start;
__DATA__
@@ GET/servers.json.ep
[
    <%== include 'GET/servers/1' %>,
    <%== include 'GET/servers/2' %>
]
@@ GET/servers/1.json.ep
{ "ip": "10.0.0.1", "os": "Debian 9" }
@@ GET/servers/2.json.ep
{ "ip": "10.0.0.2", "os": "Debian 8" }
@@ POST/servers.json.ep
{ "status": "success", "id": 3, "server": <%== $c->req->body %> }
@@ POST/servers.json+error.ep
% $c->res->code( 400 );
{ "status": "error", "error": "Bad request" }
