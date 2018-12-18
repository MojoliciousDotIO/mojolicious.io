use Mojolicious::Lite -signatures;
use Mojo::AsyncAwait;
use Mojo::Promise;
use Mojo::Util 'trim';

plugin 'PromiseActions';

helper get_title_p => async sub ($c, $url) {
  my $tx = await $c->ua->get_p($url);
  return trim $tx->res->dom->at('title')->text;
};

any '/' => async sub ($c) {
  my $urls = $c->every_param('url');
  my @promises = map { $c->get_title_p($_) } @$urls;
  my @titles = await Mojo::Promise->all(@promises);
  $c->render(json => [ map { $_->[0] } @titles ]);
};

app->start;

