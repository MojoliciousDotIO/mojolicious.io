---
status: published
title: Day 21: A Little Christmas Template Cookings
author: brian d foy
tags:
    - templates
    - advent
images:
  banner:
    src: '/blog/2018/12/21/a-little-christmas-template-cooking/banner.jpg'
    alt: 'Elgin Theater'
    data:
      attribution: |-
        <a data-flickr-embed="true"  href="https://www.flickr.com/photos/39908901@N06/11412118604/in/photolist-ios6gA-5LGoKq-PnBoBQ-ibEPHM-7qUncc-SSGFhT-SCYSD9-7pwexw-2doKrZi-b18y32-acMecE-91MNrB-ogyG6P-LX7iMB-ShNXEj-8ZydMc-qdCE4G-4gn2We-qeqCfM-vcGZh-uVByK-h7ffe3-5y5KW9-2cvWMiq-G28Wj6-9ghgVP-4kkcHa-95mLjQ-45ntcs-ShQc5J-nKVW5Q-SP6zgo-imwWqF-SFiTgF-b1xMUr-98xU34-iy3ziA-3ajXVu-7qujMF-SFiitR-dD7wZD-nZfia-kyWT4M-iAZSYf-8ys5cz-94snpg-ShNKW9-5EV5Ns-21qzGXJ-b3oaiT" title="Peanut Butter Kisses cookies"><img src="https://farm8.staticflickr.com/7346/11412118604_cd0ee37d7c_k.jpg" width="2048" height="1356" alt="Peanut Butter Kisses cookies"></a>
data:
  bio: briandfoy
  description:
---
The Advent Calendar has shown you many great ways to use Mojolicious, and since you already have Mojo installed you can use it for things besides web processing. Today's recipe uses The templating rendering engine for something other than web responses.
---

First, process some string templates. Here's an example lifted from the [Mojo::Template](https://mojolicious.org/perldoc/Mojo/Template), using the [squiggly heredoc syntax released in v5.26](https://www.effectiveperlprogramming.com/2016/12/strip-leading-spaces-from-here-docs-with-v5-26/)

	use Mojo::Template;

	my $mt = Mojo::Template->new;

	say $mt->render(<<~'EOF');
		% use Time::Piece;
		<div>
		  % my $now = localtime;
		  Time: <%= $now->hms %>
		</div>
		EOF

The lines with leading percent sings are Perl code. One of those lines loads a module, [Time::Piece](), and the other creates the variable `$now`. The `<%= %>` insert values inline. You can figure out the other template syntax on your own; it's all in the [module documentation](https://mojolicious.org/perldoc/Mojo/Template).

You can invert that so that the source of the values comes from outside of the template. The `vars()` method turns on your ability to pass a hash to the template; the hash keys turn into values. Sometimes this is preferable to having too much logic in the presentation layer:

	use Mojo::Template;

	my $mt = Mojo::Template->new->vars(1);

	use Time::Piece;
	my $now = localtime;

	say $mt->render(<<~'EOF', { time => $now->hms } );
		<div>
		  Time: <%= $time %>
		</div>
		EOF

Now that you know everything about Mojo templates, you can process a directory full of them to start a new project.

I used to do this with [Template Toolkit](http://template-toolkit.org), a very fine and capable module that's as good as it ever was. The `ttree` program could process a directory of templates to give you a new set of files.
