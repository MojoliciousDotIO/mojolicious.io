use Mojo::Base -strict;
# or:
# use strict;
# use warnings;
# use utf8;
# use IO::Handle;
# use feature ':5.10';

use Test::More;
use Test::Mojo;
my $t = Test::Mojo->with_roles('+PSGI')->new('app.psgi');

$t->get_ok('/text')
  ->status_is(200)
  ->content_type_like(qr[text/plain])
  ->content_is('hello world');

$t->get_ok('/text', form => { name => 'santa' })
  ->status_is(200)
  ->content_type_like(qr[text/plain])
  ->content_is('hello santa');

$t->get_ok('/data')
  ->status_is(200)
  ->content_type_like(qr[application/json])
  ->json_is('/hello' => 'world');

$t->post_ok('/data' => form => { name => 'rudolph' })
  ->status_is(200)
  ->content_type_like(qr[application/json])
  ->json_is('/hello' => 'rudolph');

$t->get_ok('/html')
  ->status_is(200)
  ->content_type_like(qr[text/html])
  ->text_is('dl#data dt#hello + dd', 'world');

$t->post_ok('/html' => form => { name => 'grinch' })
  ->status_is(200)
  ->content_type_like(qr[text/html])
  ->text_is('dl#data dt#hello + dd', 'grinch');

done_testing;
