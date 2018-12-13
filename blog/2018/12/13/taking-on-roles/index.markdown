---
status: published
title: Day 13: Taking on Roles
author: brian d foy
tags:
    - roles
    - advent
images:
  banner:
    src: '/blog/2018/12/13/mojo-roles/banner.jpg'
    alt: 'Elgin Theater'
    data:
      attribution: |-
        <a rel="nofollow" class="external text" href="https://www.flickr.com/photos/eskimo_jo/27387510917/in/photolist-HJ99Q6-fziGbA-fypQyz-7pCEK2-e6kG1-8NxgJh-9gKfaE-eEhB2w-9wc7yk-fwnRyf-62b1R6-27u47Nh-4ohfrN-9o2vut-2xyVmv-2yas82-ctV3fq-nBYJN4-q6zkbS-dT86ZD-mh1ZCy-p9dih6-bkQjXj-2TrSuT-b6wss6-2xDeis-cWvgV-dTdHes-gzKwrS-9KCHh8-hbhMuo-dTdHGs-9NE65X-rDnHax-eU8Vvr-2xCPHU-pmTNvB-h3sd4v-ng4Mq4-8Cg1jj-eDBCNd-c7vNYA-aNAcbz-X2wae1-dmfhPB-brquEG-2oCtmk-6spRo4-6spTQP-e6mTB">Image</a> by <a href="https://www.flickr.com/photos/eskimo_jo/">Viv Lynch</a> <a href="https://creativecommons.org/licenses/by-nc-nd/2.0/" title="Creative Commons Attribution-NonCommercial-NoDerivs 2.0 Generic ">CC BY-NC-ND 2.0</a>
data:
  bio: briandfoy
  description: Need a little extra in your class?
---
In my previous Advent article, I created [higher-order promises](/blog/2018/12/03/higher-order-promises/) and showed you how to use them. I didn't show you the magic of how they work, so now I'll develop another example but from the other direction.
---

There are times that I want [Mojo::File](https://mojolicious.org/perldoc/Mojo/File) to act a bit differently than it does. Often I have a path where I want to combine only the basename with a different directory. I end up making `Mojo::File` objects for both and then working with the directory object to get what I want:

	use Mojo::File qw(path);
	my $path     = Mojo::File->new( '/Users/brian/bin/interesting.txt' );
	my $dir      = Mojo::File->new( '/usr/local/bin' );
	my $new_path = $dir->child( $path->basename );

	say $new_path;  # /usr/local/bin/interesting.txt

That's annoying. There are a few methods that I'd like instead. I'd rather be able to write it like this, where I start with the interesting file and keep working on it instead of switching to some other object:

	use Mojo::File qw(path);

	my $new_path = Mojo::File
		->new( '/Users/brian/bin/interesting.txt' )
		->rebase( '/usr/local/bin' );   # this isn't a method

	say $new_path;  # /usr/local/bin/interesting.txt

I could go through various Perl tricks to add this method to `Mojo::File` through [monkey patching](https://mojolicious.org/perldoc/Mojo/Util#monkey_patch) or subclassing. But, as usual, Mojolicious anticipates my desire and provides a way to do this. I can add a role,

You can read about roles on your own while I jump into it. First, I create a class to represent my role. I define the method(s) I want. I use the name of the package I want to affect, add `::Role::`, then the name I'd like to use; it's not important that its lowercase. `Mojo::Base` sets up everything I need when I import `-role`:

	package Mojo::File::Role::rebase {
		use Mojo::Base qw(-role -signatures);

		sub rebase ($file, $dir) {
			$file->new( $dir, $file->basename )
			}
		}

I apply my new functionality by using `with_roles`. Since I used the naming convention, I can leave off most of the package name and use the last part of it preceded by a plus sign:

	my $file_class = Mojo::File->with_roles( '+rebase' );

Alternately I could have typed out the full package name, which I would have to do if I didn't follow the naming convention:

	my $file_class = Mojo::File->with_roles(
		'Mojo::File::Role::rebase' );

The `$file_class` is a string with the new class name. Behind that class there is some multiple inheritance magic that you'll be much happier ignoring. You don't need to use a bareword class name to call class methods. A string works just as well. Now I can use my `rebase`:

	say $file_class
		->new( '/Users/brian/bin/interesting.txt' )
		->rebase( '/usr/local/bin/' );

This doesn't solve the problem of `Mojo::File` objects that I get from other Mojolicious operations, but this is good enough the simple programs that I'm writing.

I can go further. Any methods I add to my role become part of the class. I often want to get the digests of files and although [Mojo::Util](https://mojolicious.org/perldoc/Mojo/File) makes that easier with some convenience functions, I want even more convenience. I add a couple of methods to my role to do the slurping for me:

	use Mojo::File;

	package Mojo::File::Role::MyUtils {
		use Mojo::Base qw(-role -signatures);
		use Mojo::Util qw(md5_sum sha1_sum);

		sub rebase ($file, $dir) {
			$file->new( $dir, $file->basename )
			}

		sub md5 ($file) {
			md5_sum( $file->slurp )
			}

		sub sha1 ($file) {
			sha1_sum( $file->slurp )
			}
		}

	my $file = Mojo::File
		->with_roles( '+MyUtils' )
		->new(shift);

	say $file->sha1;
	say $file->md5;


