package Wishlist;
use Mojo::Base 'Mojolicious';

use Mojo::File;
use Mojo::SQLite;
use LinkEmbedder;
use Wishlist::Model;

has sqlite => sub {
  my $app = shift;

  # determine the storage location
  my $file = $app->config->{database} || 'wishlist.db';
  unless ($file =~ /^:/) {
    $file = Mojo::File->new($file);
    unless ($file->is_abs) {
      $file = $app->home->child("$file");
    }
  }

  my $sqlite = Mojo::SQLite->new
    ->from_filename("$file")
    ->auto_migrate(1);

  # attach migrations file
  $sqlite->migrations->from_file(
    $app->home->child('wishlist.sql')
  )->name('wishlist');

  return $sqlite;
};

sub startup {
  my $app = shift;

  $app->plugin('Config' => {
    default => {},
  });

  if (my $secrets = $app->config->{secrets}) {
    $app->secrets($secrets);
  }

  $app->helper(link => sub {
    my $c = shift;
    state $le = LinkEmbedder->new;
    return $le->get(@_);
  });

  $app->helper(model => sub {
    my $c = shift;
    return Wishlist::Model->new(
      sqlite => $c->app->sqlite,
    );
  });

  $app->helper(user => sub {
    my ($c, $name) = @_;
    $name ||= $c->stash->{name} || $c->session->{name};
    return {} unless $name;

    my $model = $c->model;
    my $user = $model->user($name);
    unless ($user) {
      $model->add_user($name);
      $user = $model->user($name);
    }
    return $user;
  });

  $app->helper(users => sub {
    my $c = shift;
    return $c->model->list_user_names;
  });

  my $r = $app->routes;
  $r->get('/' => sub {
    my $c = shift;
    my $template = $c->session->{name} ? 'list' : 'login';
    $c->render($template);
  });

  $r->get('/list/:name')->to(template => 'list')->name('list');

  $r->get('/add')->to('List#show_add')->name('show_add');
  $r->post('/add')->to('List#do_add')->name('do_add');

  $r->post('/update')->to('List#update')->name('update');
  $r->post('/remove')->to('List#remove')->name('remove');

  $r->post('/login')->to('Access#login')->name('login');
  $r->any('/logout')->to('Access#logout')->name('logout');

}

1;

