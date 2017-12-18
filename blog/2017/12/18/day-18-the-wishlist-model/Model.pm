package Wishlist::Model;
use Mojo::Base -base;

use Carp ();

has sqlite => sub { Carp::croak 'sqlite is required' };

sub add_user {
  my ($self, $name) = @_;
  return $self
    ->sqlite
    ->db
    ->insert(
      'users',
      {name => $name},
    )->last_insert_id;
}

sub user {
  my ($self, $name) = @_;
  my $sql = <<'  SQL';
    select
      user.id,
      user.name,
      (
        select
          json_group_array(item)
        from (
          select json_object(
            'id',        items.id,
            'title',     items.title,
            'url',       items.url,
            'purchased', items.purchased
          ) as item
          from items
          where items.user_id=user.id
        )
      ) as items
    from users user
    where user.name=?
  SQL
  return $self
    ->sqlite
    ->db
    ->query($sql, $name)
    ->expand(json => 'items')
    ->hash;
}

sub list_user_names {
  my $self = shift;
  return $self
    ->sqlite
    ->db
    ->select(
      'users' => ['name'],
      undef,
      {-asc => 'name'},
    )
    ->arrays
    ->map(sub{ $_->[0] });
}

sub add_item {
  my ($self, $user, $item) = @_;
  $item->{user_id} = $user->{id};
  return $self
    ->sqlite
    ->db
    ->insert('items' => $item)
    ->last_insert_id;
}

sub update_item {
  my ($self, $item, $purchased) = @_;
  return $self
    ->sqlite
    ->db
    ->update(
      'items',
      {purchased => $purchased},
      {id => $item->{id}},
    )->rows;
}

sub remove_item {
  my ($self, $item) = @_;
  return $self
    ->sqlite
    ->db
    ->delete(
      'items',
      {id => $item->{id}},
    )->rows;
}

1;

