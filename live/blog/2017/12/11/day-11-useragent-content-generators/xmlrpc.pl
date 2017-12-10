use Mojo::Base -strict;
use Mojo::UserAgent;
use Mojo::XMLRPC qw[encode_xmlrpc decode_xmlrpc];

my $ua = Mojo::UserAgent->new;
my $tx = $ua->post(
  '/rpc',
  {'Content-Type' => 'text/xml'},
  encode_xmlrpc(call => 'target_method', 'arg1', 'arg2')
);
my $res = decode_xmlrpc($tx->res->body);

