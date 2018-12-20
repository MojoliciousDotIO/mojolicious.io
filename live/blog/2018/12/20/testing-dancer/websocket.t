use Mojo::Base -strict;

use EV;
use Test::More;
use Test::Mojo;

use Twiggy::Server;
use Plack::Util;

my $app = Plack::Util::load_psgi('bin/app.psgi');
my $url;
my $twiggy = Twiggy::Server->new(
  host => '127.0.0.1',
  server_ready => sub {
    my $args = shift;
    $url = "ws://$args->{host}:$args->{port}/ws";
  },
);
$twiggy->register_service($app);

my $t = Test::Mojo->new;

$t->websocket_ok($url)
  ->send_ok({json => {hello => 'Dancer'}})
  ->message_ok
  ->json_message_is({hello => 'browser!'})
  ->finish_ok;

done_testing;
