use Dancer2;

set template => 'simple';
set views => '.';

any '/text' => sub {
  my $name = param('name') // 'world';
  send_as plain => "hello $name";
};

any '/data' => sub {
  my $name = param('name') // 'world';
  send_as JSON => { hello => $name };
};

any '/html' => sub {
  my $name = param('name') // 'world';
  template 'hello' => { name => $name };
};

start;
