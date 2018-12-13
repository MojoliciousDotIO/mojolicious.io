#!/usr/bin/env perl
# myapp.pl
use Mojolicious::Lite -signatures;
# Log exceptions to a separate log file
hook after_dispatch => sub( $c ) {
    return unless my $e = $c->stash( 'exception' );
    state $path = $c->app->home->child("exception.log");
    state $log = Mojo::Log->new( path => $path );
    $log->error( $e );
};
# Allow access via tokens
plugin Config => {
    default => {
        tokens => { }, # token => username
    },
};
helper current_user => sub( $c ) {
    my $auth = $c->req->headers->authorization;
    return undef unless $auth;
    my ( $token ) = $auth =~ /^Token\ (\S+)$/;
    return undef unless $token;
    return $c->app->config->{tokens}{ $token };
};
app->start;
