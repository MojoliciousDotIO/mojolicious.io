use Mojo::Base -strict;

use Test::More;
use Test::Mojo;

my $t = Test::Mojo->new(
  'Wishlist',
  {database => ':temp:'}
);

my $model = $t->app->model;
is_deeply $model->list_user_names, [], 'No existing users';

my $user_id = $model->add_user('Zoidberg');
ok $user_id, 'add_user returned a value';
my $user = $model->user('Zoidberg');
is_deeply $user, {
  id => $user_id,
  name => 'Zoidberg',
  items => [],
}, 'correct initial user state';
is_deeply $model->list_user_names, ['Zoidberg'], 'user in list of names';

my $item_id = $model->add_item($user, {
  title => 'Dark Matter',
  url   => 'lordnibbler.org',
});
ok $item_id, 'add_item returned a value';
$user = $model->user('Zoidberg');
is_deeply $user, {
  id => $user_id,
  name => 'Zoidberg',
  items => [
    {
      id => $item_id,
      purchased => 0,
      title => 'Dark Matter',
      url   => 'lordnibbler.org',
    },
  ],
}, 'correct initial user state';

done_testing;

