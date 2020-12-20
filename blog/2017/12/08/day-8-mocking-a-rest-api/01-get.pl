use Mojolicious::Lite;
get '/servers' => sub {
    my ( $c ) = @_;
    return $c->render(
        json => [
            { ip => '10.0.0.1', os => 'Debian 9' },
            { ip => '10.0.0.2', os => 'Debian 8' }
        ],
    );
};
app->start;
