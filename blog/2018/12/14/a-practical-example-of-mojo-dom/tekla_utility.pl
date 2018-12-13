#!/usr/bin/perl
use Mojo::Base -base;
use Mojo::Util qw(getopt);
use Mojo::File;
use Mojo::DOM;

getopt 'p|path=s' => \my $path;

sub main {
  # look in xml elements for laserscans that have hashes for names, then rename.
  my $file = Mojo::File->new($path, 'pointclouds.xml');
  my $dom  = Mojo::DOM->new($file->slurp);
  for my $e ($dom->find('PointCloudData')->each) { 
    $e->{Folder} = rename_files($e) and $e->{Hash} = '' if $e->{Hash};
  }
  # save xml file so we don't try to rename the pointclouds again
  $file->spurt($dom);
}

sub rename_files {
  # rename pointcloud folder and database file
  my $e = shift;
  my $newname = $e->{Folder} =~ s/$e->{Hash}/$e->{Name}/r;
  say "renaming: $e->{Folder} to:\n$newname";
  rename $e->{Folder},       $newname       || die ("Couldn't rename $e->{Folder}");
  rename $e->{Folder}.'.db', $newname.'.db' || die ("Couldn't rename $e->{Folder}.db");
  return ($newname);
}

main() if $path || die 'Please enter a path to the example files.';