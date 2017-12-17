use Mojolicious::Lite;

use DBM::Deep;
use LinkEmbedder;

helper link => sub {
  my $c = shift;
  state $le = LinkEmbedder->new;
  return $le->get(@_);
};

helper users => sub {
  state $db = DBM::Deep->new('wishlist.db');
};

helper user => sub {
  my ($c, $name) = @_;
  $name ||= $c->stash->{name} || $c->session->{name};
  return {} unless $name;
  return $c->users->{$name} ||= {
    name => $name,
    items => {},
  };
};

get '/' => sub {
  my $c = shift;
  my $template = $c->session->{name} ? 'list' : 'login';
  $c->render($template);
};

get '/list/:name' => 'list';

get '/add' => sub {
  my $c = shift;
  my $link = $c->link($c->param('url'));
  $c->render('add', link => $link);
};

post '/add' => sub {
  my $c = shift;
  my $title = $c->param('title');
  $c->user->{items}{$title} = {
    title => $title,
    url => $c->param('url'),
    purchased => 0,
  };
  $c->redirect_to('/');
};

post '/update' => sub {
  my $c = shift;
  my $user = $c->user($c->param('user'));
  my $item = $user->{items}{$c->param('title')};
  $item->{purchased} = $c->param('purchased');
  $c->redirect_to('list', name => $user->{name});
};

post '/remove' => sub {
  my $c = shift;
  delete $c->user->{items}{$c->param('title')};
  $c->redirect_to('/');
};

post '/login' => sub {
  my $c = shift;
  if (my $name = $c->param('name')) {
    $c->session->{name} = $name;
  }
  $c->redirect_to('/');
};

any '/logout' => sub {
  my $c = shift;
  $c->session(expires => 1);
  $c->redirect_to('/');
};

app->start;

