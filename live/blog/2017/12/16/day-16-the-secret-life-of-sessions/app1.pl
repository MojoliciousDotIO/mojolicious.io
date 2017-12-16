use Mojolicious::Lite;

get '/' => sub {
  my $c = shift;
  my $count = ++$c->session->{count};
  my $message = "You have visited $count time";
  $message .= 's' unless $count == 1;
  $c->render(text => $message);
};

app->start;

