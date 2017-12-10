use Mojo::Base -strict;
use Mojo::UserAgent;
use Mojo::JSON 'encode_json';
use Mojo::File;

my $url   = 'https://www.googleapis.com/upload/drive/v3/files?uploadType=multipart';
my $token = 'XXXXXXXXXX';
my $file  = Mojo::File->new('local/path/to/image.jpg');
my $ua    = Mojo::UserAgent->new;

$ua->post(
  $url,
  {
    Authorization => "Bearer $token",
    'Content-Type' => 'multipart/related',
  },
  multipart => [
    {
      'Content-Type' => 'application/json; charset=UTF-8',
      content => encode_json({name => 'myObject'}),
    },
    {
      'Content-Type' => 'image/jpeg',
      content => $file->slurp,
    }
  ]
);


