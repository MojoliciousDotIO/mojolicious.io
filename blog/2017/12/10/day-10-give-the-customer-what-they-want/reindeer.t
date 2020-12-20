use Mojolicious::Lite;

# This could be a db lookup
helper 'reindeer' => sub {
  my ($c, $name) = @_;
  my %reindeer = (
    rudolph => {
      name => 'Rudolph',
      description => 'has a very shiny nose',
    },
  );
  return $reindeer{$name};
};

get '/:name' => sub {
  my $c = shift;
  my $reindeer = $c->reindeer($c->stash('name'));
  return $c->reply->not_found unless $reindeer;

  $c->respond_to(
    json => {json => $reindeer},
    xml  => {template => 'reindeer', reindeer => $reindeer},
    txt  => {text => "$reindeer->{name}: $reindeer->{description}"},
    any  => {status => 406, text => 'Only json, xml, and txt are supported' },
  );
};

use Test::More;
use Test::Mojo;

my $t = Test::Mojo->new;

$t->get_ok('/rudolph.html')
  ->status_is(406);

$t->get_ok('/rudolph.json')
  ->status_is(200)
  ->json_is('/name' => 'Rudolph');

$t->get_ok('/rudolph', {Accept => 'text/xml'})
  ->status_is(200)
  ->text_is('Reindeer Name' => 'Rudolph');

$t->get_ok('/rudolph?format=txt')
  ->status_is(200)
  ->content_like(qr/^Rudolph:/);

done_testing;

__DATA__

@@ reindeer.xml.ep
<?xml version="1.0"?>
<Reindeer>
  <Name><%= $reindeer->{name} =%></Name>
  <Description><%= $reindeer->{description} =%></Description>
</Reindeer>

