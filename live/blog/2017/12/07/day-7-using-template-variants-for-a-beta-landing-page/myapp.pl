# myapp.pl
use Mojolicious::Lite;
get '/*path', { path => 'index' }, sub {
    my ( $c ) = @_;
    return $c->render(
        template => $c->stash( 'path' ),
        variant => $c->app->mode,
    );
};
app->start;
