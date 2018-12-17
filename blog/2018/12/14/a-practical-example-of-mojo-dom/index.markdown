---
status: published
title: Day 14: A Practical Example of Mojo::DOM
tags:
    - advent
    - xml
    - non-web
author: maschine
images:
  banner:
    src: '/blog/2018/12/14/a-practical-example-of-mojo-dom/banner.png'
    alt: 'A typical industrial platform model overlaid with a laser scan'
    data:
      attribution: |-
        Original screenshots by maschine, released under CC-BY-SA 4.0.
data:
  bio: maschine
  description: 'Use Mojo::DOM to parse XML'
---

With recent versions of Mojolicious, [Mojo::DOM](https://mojolicious.org/perldoc/Mojo/DOM) gained a lot of power that I have been excited to try, but haven't had the time for.  Recently, I had a problem at my real job (in Engineering, Procurement, and Construction, or EPC for short) that I solved with Mojo::DOM (and other parts of Mojolicious) in a very short time – including learning how to use Mojo::DOM, which I had never done before.
---

## The task - simple, but tedious.

3D models and drawings are fantastic tools, but in reality things are not so perfect.  Construction tolerances being what they are, our company relies a lot on [laser scanning](https://www.youtube.com/watch?v=H-uNzEmt5sw), where we go out to a project site and create a point cloud of the as-built conditions.  This generates hundreds of files that take many hours to process - a recent project had over 3 *billion* individual points.  These are critical for engineering, modeling, and construction throughout every project we do.

The problem is when our 3D modeling software ([Tekla Structures](https://www.tekla.com/products/tekla-structures)) processes the point clouds, it changes the file names of each one from something human readable, such as `Pipe Rack Area1`, to a hash, like `2e9d52829f973c5b98f60935d8a9fa2b`.  This is not very user friendly when one project could have dozens of areas, and you only really want to load one or two at a time (an *average* area is 15gb!).

![Point clouds add information that is not available in the 3D model](pointcloud1.jpg)
_Point clouds provide critical information that is either too difficult or too costly to model directly_

Fortunately, Tekla uses a lot of standard file formats that anyone can edit – including using XML to describe each point cloud it has processed.  Of course, I could just hand edit them to change the names, but that would have to be done for every scan and every project - not a good solution.

Conveniently, the XML file contains both the hash name and the original file name – so I knew I could use Mojo::DOM to parse the XML and rename the point clouds to be human readable. This simple task is the perfect example of how Mojolicious can accomplish a lot of work with relatively short code. The result is the script below:

    #!/usr/bin/perl
    use Mojo::Base -strict;
    use Mojo::Util qw(getopt);
    use Mojo::File;
    use Mojo::DOM;

    getopt 'p|path=s' => \my $path;

    sub main {
      # look in xml elements for laserscans that have hashes for names
      my $file = Mojo::File->new($path, 'pointclouds.xml');
      my $dom  = Mojo::DOM->new($file->slurp);
      # if 'Hash' is populated, rename_files(); otherwise ignore
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
      rename $e->{Folder},       $newname       || die $!;
      rename $e->{Folder}.'.db', $newname.'.db' || die $!;
      return ($newname);
    }

    main() if $path || die 'Please enter a path to the example files.';

## Not a web app

Not every use of Mojolicious has to be a full app - parts of it can be used like any other Perl module. For a simple script, it can make getting to your actual purpose much quicker.  I use following line now all the time, even if I'm not building a full Mojolicious app. [Mojo::Base](https://mojolicious.org/perldoc/Mojo/Base) saves me from typing additional boiler plate and enables strict, warnings, and other goodies I often want to use.

    use Mojo::Base -strict;

## Mojo::Util - just for fun

The production version of my utility actually loads a dummy Mojolicious `$app` so that I can use [Mojolicious::Plugin::Config](https://mojolicious.org/perldoc/Mojolicious/Plugin/Config) to locate the point cloud files in `myapp.conf`, but in this version I'm using [Mojo::Util](https://mojolicious.org/perldoc/Mojo/Util) to get the point cloud file path with a command line option `--p`.

    getopt 'p|path=s' => \my $path;

To the run my [utility](tekla_utility.pl) on the [example files](a-practical-example-of-mojo-dom.rar), you must first change the contents of `Folder` in `pointclouds.xml` to wherever you've saved them.

    $ perl tekla_utility.pl --p 'path to example files'

## Mojo::File - never manually write file code again!

[Mojo::File](https://mojolicious.org/perldoc/Mojo/File) makes reading `pointclouds.xml` so I can parse it with Mojo::DOM simple:

    my $file = Mojo::File->new($path, 'pointclouds.xml');
    my $dom  = Mojo::DOM->new($file->slurp);

In the [bad old days](https://cgi-lib.berkeley.edu/2.18/cgi-lib.pl.txt), I probably hand wrote 15 lines of (horrible) code every time I wanted to read a file.

## Mojo::DOM - what can't it do?

And of course, [Mojo::DOM](https://mojolicious.org/perldoc/Mojo/DOM) makes finding the right values in the XML easy - it also handles HTML and CSS selectors.  Basically, I just iterate through the contents of `PointCloudData`, which contains the `Folder`, `Hash`, and `Name` keys for each point cloud Tekla has processed:

    for my $e ($dom->find('PointCloudData')->each) {
      $e->{Folder} = rename_files($e) and $e->{Hash} = '' if $e->{Hash};
    }

I only run `rename_files` if `Hash` is populated, and if it is, I empty it so I don't try to rename them again.  `rename_files` is about the only Perl code I had to write myself - almost everything else was copied and pasted straight from the excellent [Mojolicious docs](https://mojolicious.org/perldoc)!

A substitution stores the desired file & folder name in `$newname` (non-destructive modifier `/r` allows me to work on a copy of `$e` without changing the original).  Then I simply rename the point cloud folder and the \*.db file (which contains the actual point cloud data).

    my $newname = $e->{Folder} =~ s/$e->{Hash}/$e->{Name}/r;

When I'm finished renaming the point clouds, I use [Mojo::File](https://mojolicious.org/perldoc/Mojo/File) to save the contents of `$dom` back to `pointclouds.xml` with one line:

    $file->spurt($dom)

The neat thing is, when I altered the contents of `$e->{Folder}` and `$e->{Hash}` in my loop, saving it back just works - I don't need to think too much about the XML structure at all.  Interestingly, saving `$dom` alpabetizes the keys, but Tekla doesn't seem to notice.

![Point clouds are not perfect, but are still a valuable tool](pointcloud2.jpg)
_Note the grainy nature of the point cloud - since they are just points with no area, the closer you get, the grainier it looks_

##  Useful for all skill levels

This is just one example of how I have used Mojolicious in my day job.  Sometimes, existing software doesn't do what you want, or does it in a format that's not useful - problems that can be solved with the many tools Mojolicious provides.  You don't even have to be a real programmer (I'm not), or work in the software industry at all.

My next project idea is to rebuild a reporting tool I wrote for Material Take Offs (MTOs) to work with Tekla, which our engineers loved with our old modeling software - and I'm sure I will continue to find good uses for Mojolicious well into the future.

