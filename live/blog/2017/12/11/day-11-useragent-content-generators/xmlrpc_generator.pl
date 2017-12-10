use Mojo::Base -strict;
use Mojo::UserAgent;
use Mojo::XMLRPC qw[encode_xmlrpc decode_xmlrpc];

my $ua = Mojo::UserAgent->new;
$ua->transactor->add_generator(xmlrpc => sub {
  my ($transactor, $tx, @args) = @_;
  $tx->req->headers->content_type('text/xml');
  $tx->req->body(encode_xmlrpc(call => @args));
});

my $tx = $ua->post('/rpc', xmlrpc => 'target_method', 'arg1', 'arg2');
my $res = decode_xmlrpc($tx->res->body);


