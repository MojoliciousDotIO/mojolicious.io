use Mojolicious::Lite;

plugin 'Config';

if (my $secrets = app->config->{secrets}) {
  app->secrets($secrets);
}

get '/' => sub {
  my $c = shift;
  my $count = ++$c->session->{count};
  my $message = "You have visited $count time";
  $message .= 's' unless $count == 1;
  $c->render(text => $message);
};

app->start;

