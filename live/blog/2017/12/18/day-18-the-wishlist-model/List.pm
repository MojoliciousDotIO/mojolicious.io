package Wishlist::Controller::List;
use Mojo::Base 'Mojolicious::Controller';

sub show_add {
  my $c = shift;
  my $link = $c->link($c->param('url'));
  $c->render('add', link => $link);
}

sub do_add {
  my $c = shift;
  my %item = (
    title => $c->param('title'),
    url => $c->param('url'),
    purchased => 0,
  );
  $c->model->add_item($c->user, \%item);
  $c->redirect_to('/');
}

sub update {
  my $c = shift;
  $c->model->update_item(
    {id => $c->param('id')},
    $c->param('purchased')
  );
  $c->redirect_to('list', name => $c->param('name'));
}

sub remove {
  my $c = shift;
  $c->model->remove_item(
    {id => $c->param('id')},
  );
  $c->redirect_to('/');
}

1;

