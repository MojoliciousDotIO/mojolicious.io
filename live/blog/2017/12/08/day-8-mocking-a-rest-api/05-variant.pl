use Mojolicious::Lite;
any '/*path' => sub {
    my ( $c ) = @_;
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
