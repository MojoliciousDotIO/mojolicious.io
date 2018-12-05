---
status: published
title: Day 5: Compound Selectors are Easier than Regexes
author: brian d foy
tags:
    - promises
    - advent
images:
  banner:
    src: '/blog/2018/12/05/compound-selectors/banner.jpg'
    alt: 'Sled dogs waiting to run'
    data:
      attribution: |-
        <a rel="nofollow" class="external text" href="https://www.flickr.com/photos/feuilllu/101083313/in/photolist-9W5xK-SWEcv6-qmMqBb-9W66e-umaBj-7Gkg2a-bnmWDf-jZPHK7-bAgNFi-bnmW3J-Hd8y3-dYNuYc-Hd9o9-22MW7qW-6qZWkL-7yzScF-24W5o6o-bBNUMi-5QPxcD-boz5qm-VmkEd7-bBeNyD-5ZuaNe-eFvSS-5ZubhH-hroLWM-dyiEjD-7x18L-6qVKL2-5BtJpc-Tat77P-V2rCfA-HdcdK-bpyFMR-qmUynZ-bBtZU6-zYsqAQ-bBNVia-RSZkN5-Hd8zq-bBtY8M-4okvTd-bBeMZz-EnynD-feMXov-qUSFPR-boTZGE-9mfjyh-9e8KsD-kspqik">Image</a> by <a href="https://www.flickr.com/photos/feuilllu/">Pierre Metivier</a> <a href="https://creativecommons.org/licenses/by-sa/2.0" title="Creative Commons Attribution-Share Alike 2.0">CC BY-SA 2.0</a>
data:
  bio: briandfoy
  description: Extract HTML quickly and easily with Mojo::DOM
---
When people tell me that I can't (they mean shouldn't) parse HTML with a regex, I say "hold my beer". It isn't a matter of skill or attitude so much as convenience. Doing it the right way was not always so easy (I remember HTML 0.9 being a big deal). Lately, though, I've been using [Mojo::DOM](https://mojolicious.org/perldoc/Mojo/DOM) to do it for me. It's easier than the old, expedient way.
---
The trick was always to isolate the interesting HTML. I could do that excising all of the data around the interesting parts:

	my $html = ...;
	$html =~ s/.*?<table class="foo".*?>//;
	$html =~ s/<\/table>.*//;

Now I don't have to parse all of HTML; I can think about the table. Even though that's expedient it's not so nice. Before I replace that with something nicer, I'll take a quick detour.

## Cascading Style Sheets

You may know about Cascading Style Sheets (CSS) for making your web pages look beautiful (but not mine, really). You can add meta data to tags:

	<img id="bender" class="robot" src="..." />
	<img id="fry" class="human" src="..." />
	<img id="leela" class="mutant" src="..." />

CSS rules can address these items by their ID or class to apply styles to them. This addressing is a "selector" and people with better skills than me use these to make the presentation pretty:

	img#fry   { border: 1px; }

	img.robot { margin: 20px; }

The HTML can be a bit more complicated. Perhaps those interesting tags are in a list. That wraps another layer of HTML structure around the data:

	<ul class="employees">
	<li><img id="bender" class="robot" src="..." /></li>
	<li><img id="fry" class="human" src="..." /></li>
	<li><img id="leela" class="mutant" src="..." /></li>
	</ul>

If I'd like to affect only those images in that list but only the items in that list. I can specify the ancestry with a compound selector (two or more used together). With just a space between the selectors, this means that the second selector is contained in the first (a "descendent"):

	ul.employees img.human { border: 1px; }

	ul.employees img.robot { margin: 20px; }

However, this article isn't about all the fancy things that you can do with selectors. You know that they exist and you can see the possibilities in [Mojo::CSS::Selectors](https://mojolicious.org/perldoc/Mojo/DOM/CSS). I'll show you a few examples in the next section.

## Using Selectors with Mojo

But you can do much more with these. With [Mojo::DOM](https://mojolicious.org/perldoc/Mojo/DOM), which supports CSS Selectors [Level 3](https://www.w3.org/TR/2018/PR-selectors-3-20180911/) (and some stuff from [Level 4](https://www.w3.org/TR/selectors-4/)), you can use the same addressing to extract data.

Start with some HTML. Note the fancy new [indented here doc syntax introduced in Perl 5.26](https://www.effectiveperlprogramming.com/2016/12/strip-leading-spaces-from-here-docs-with-v5-26/):

	use v5.28;
	use utf8;
	use strict;
	use warnings;

	use Mojo::DOM;

	my $selector = $ARGV[0] // 'img';

	my $html =<<~'HTML';

		<img id="farnworth " class="human" src="..." />
		<ul class="employees">
		<li><img id="bender" class="robot" src="..." /></li>
		<li><img id="fry" class="human" src="..." /></li>
		<li><img id="leela" class="mutant" src="..." /></li>
		</ul>
		HTML

	my $dom = Mojo::DOM->new( $html );

	say $dom->find( $selector )->join( "\n" );

Run this with no argument and I see all the `img` tags:

	$ perl html.pl
	<img class="human" id="farnworth " src="...">
	<img class="robot" id="bender" src="...">
	<img class="human" id="fry" src="...">
	<img class="mutant" id="leela" src="...">

With an argument I can choose any part that I like. Here I get the parts starting with the `li` tag:

	$ perl html.pl li
	<li><img class="robot" id="bender" src="..."></li>
	<li><img class="human" id="fry" src="..."></li>
	<li><img class="mutant" id="leela" src="..."></li>

I can select all the images with a certain class:

	$ perl html.pl img.human
	<img class="human" id="farnworth " src="...">
	<img class="human" id="fry" src="...">

But what if I wanted just the human images in the list? I have to work a little bit harder. I specify a compound selector that notes that the `img` has to be in an `li` tag:

	$ perl html.pl "li img.human"
	<img class="human" id="fry" src="...">

Imagine, then, more complicated HTML with other lists that also had images? I could add another selector to say it has to be in a certain sort of `ul` tag:

	$ perl html.pl "ul.employees li img.human"
	<img class="human" id="fry" src="...">

If nothing should be between those tags. I can connect the selector with `>` to mean those should be immediate children instead of descendants:

	$ perl html.pl "ul.employees > li > img.human"
	<img class="human" id="fry" src="...">

Now, consider how much work I've done there. Almost nothing. I made a DOM object, applied a selector, and I've isolated parts of the data. This is the same thing I was doing the hard way before. This way is better and isn't more work. That's why I like Mojolicious!

## How about those new emojis?

While writing about the [Unicode 9 updates in Perl v5.26](https://www.effectiveperlprogramming.com/2018/08/find-the-new-emojis-in-perls-unicode-support/), I wondered what I could show that might be interesting. How about figuring out which new emoji showed up?

My first attempt simply trawled through every character and compared the various Unicode properties to see which code numbers changed from `Unassigned` to `Present_In`. That was fine, but then I found that someone was already listing all the new emoji and I could scrape their site.

I won't explain everything in this program. Trust me that it uses [Mojo::UserAgent](https://mojolicious.org/perldoc/Mojo/UserAgent) to fetch the data, extracts the DOM, and finds the text I want by using the compound selector `ul:not( [class] ) li a`. The rest is merely transforms on that extracted list. Those `map`s and the `join` come from [Mojo::Collection](https://mojolicious.org/perldoc/Mojo/Collection). This is much easier than trying to do this with regexes:

	use v5.28;
	use utf8;
	use strict;
	use warnings;
	use open qw(:std :utf8);
	use charnames qw();

	use Mojo::UserAgent;
	my $ua = Mojo::UserAgent->new;

	my $url = 'https://blog.emojipedia.org/new-unicode-9-emojis/';
	my $tx = $ua->get( $url );

	die "That didn't work!\n" if $tx->error;

	say $tx->result
		->dom
		->find( 'ul:not( [class] ) li a' )
		->map( 'text' )
		->map( sub {
			my $c = substr $_, 0, 1;
			[ $c, ord($c), charnames::viacode( ord($c) ) ]
			})
		->sort( sub { $a->[1] <=> $b->[1] } )
		->map( sub {
			sprintf '%s (U+%05X) %s', $_->@*
			} )
		->join( "\n" );

This makes a nice list that starts like this:

	🕺 (U+1F57A) MAN DANCING
	🖤 (U+1F5A4) BLACK HEART
	🛑 (U+1F6D1) OCTAGONAL SIGN
	🛒 (U+1F6D2) SHOPPING TROLLEY
	🛴 (U+1F6F4) SCOOTER
	🛵 (U+1F6F5) MOTOR SCOOTER
	🛶 (U+1F6F6) CANOE

I used the same program to find [the Unicode 10 updates in v5.28](https://www.effectiveperlprogramming.com/2018/08/use-unicode-10-in-perl-v5-28/) too.

## Extracting columns from a table

Not impressed yet? How about slicing a table with CSS Selectors? Here's a short table that has ID, name, and score columns. I want to sum all of the scores.

I'm not afraid of doing with this with regexes (emphasize plural there!) but it's easier with [Mojo::DOM](https://mojolicious.org/perldoc/Mojo/DOM). The compound selector finds the table by its class, selects each row, and addresses the table cell by position (in this case, `:last-child`):

	use v5.26;
	use utf8;
	use strict;
	use warnings;

	use List::Util qw(sum);
	use Mojo::DOM;

    my $html = <<~'HTML';
        <table class="scores">
        <tr><th>ID</th><th>Name</th><th>Score</th></tr>

        <tr><td>1</td> <td>Nibbler</td> <td>1023</td></tr>
        <tr><td>27</td><td>Scruffy</td> <td>39</td>  </tr>
        <tr><td>5</td> <td>Zoidberg</td><td>5834</td></tr>
        </table>
        HTML

    my @scores = Mojo::DOM->new( $html )
        ->find( 'table.scores > tr > td:last-child' )
        ->map( 'text' )
        ->each
        ;

    my $grand = sum( @scores );
    say "Grand total: $grand";

<em style="font-size: 10px">
Editor's note: Unfortunately this example breaks our syntax highlighter. This is the site's fault not the author. We're trying to find a better way to render it short of rewriting the rendering engine.
</em>

## Conclusion

Even for an old programmer like me, dealing with HTML through CSS Selectors applied by Mojolicious is much easier than what I was doing before (which was dirty and much easier than doing it correctly). With a little skill creating compound selectors, I can get to just about any part I want.
