use Test::More;
use Test::Mojo;
use Mojo::File qw( path );
my $t = Test::Mojo->new( path('myapp.pl') );
# Add a route that generates an exception
$t->app->routes->get(
    '/test/exception' => sub { die "Exception" },
);
$t->get_ok( '/test/exception' )->status_is( 500 );
my $log_content = path( 'exception.log' )->slurp;
like $log_content, qr{Exception}, 'exception is logged';

my $token = 'mytoken';
$t = Test::Mojo->new( path('myapp.pl'), {
    tokens => { $token => 'preaction' },
} );
my $c = $t->app->build_controller;
is $c->current_user, undef, 'current_user not set';
$c->req->headers->authorization( 'NOTATOKEN' );
is $c->current_user, undef, 'current_user without "Token"';
$c->req->headers->authorization( 'Token NOTFOUND' );
is $c->current_user, undef, 'current_user token incorrect';
$c->req->headers->authorization( "Token $token" );
is $c->current_user, 'preaction', 'current_user correct';

done_testing;
