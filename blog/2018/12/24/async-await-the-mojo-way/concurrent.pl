use Mojo::Base -strict, -signatures;

use Mojo::AsyncAwait;
use Mojo::Promise;
use Mojo::UserAgent;
use Mojo::Util 'trim';

my $ua = Mojo::UserAgent->new;

async get_title_p => sub ($url) {
  my $tx = await $ua->get_p($url);
  return trim $tx->res->dom->at('title')->text;
};

async main => sub (@urls) {
  my @promises = map { get_title_p($_) } @urls;
  my @titles = await Mojo::Promise->all(@promises);
  say for map { $_->[0] } @titles;
};

my @urls = (qw(
  https://mojolicious.org
  https://mojolicious.io
  https://metacpan.org
));
main(@urls)->wait;


