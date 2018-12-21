---
status: published
disable_content_template: 1
title: Day 21: A Little Christmas Template Cooking
author: brian d foy
tags:
    - templates
    - advent
images:
  banner:
    src: '/blog/2018/12/21/a-little-christmas-template-cooking/banner.jpg'
    alt: 'Peanut Butter Kisses cookies'
    data:
      attribution: |-
        <a data-flickr-embed="true"  href="https://www.flickr.com/photos/39908901@N06/11412118604/in/photolist-ios6gA-5LGoKq-PnBoBQ-ibEPHM-7qUncc-SSGFhT-SCYSD9-7pwexw-2doKrZi-b18y32-acMecE-91MNrB-ogyG6P-LX7iMB-ShNXEj-8ZydMc-qdCE4G-4gn2We-qeqCfM-vcGZh-uVByK-h7ffe3-5y5KW9-2cvWMiq-G28Wj6-9ghgVP-4kkcHa-95mLjQ-45ntcs-ShQc5J-nKVW5Q-SP6zgo-imwWqF-SFiTgF-b1xMUr-98xU34-iy3ziA-3ajXVu-7qujMF-SFiitR-dD7wZD-nZfia-kyWT4M-iAZSYf-8ys5cz-94snpg-ShNKW9-5EV5Ns-21qzGXJ-b3oaiT" title="Peanut Butter Kisses cookies"><img src="https://farm8.staticflickr.com/7346/11412118604_cd0ee37d7c_k.jpg" width="2048" height="1356" alt="Peanut Butter Kisses cookies"></a>
data:
  bio: briandfoy
  description: Using Mojo::Template for non-web applications.
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

The lines with leading percent sings are Perl code. One of those lines loads a module, [Time::Piece](https://metacpan.org/pod/Time::Piece), and the other creates the variable `$now`. The `<%= %>` insert values inline. You can figure out the other template syntax on your own; it's all in the [module documentation](https://mojolicious.org/perldoc/Mojo/Template).

You can invert that so that the source of the values comes from outside of the template.
Sometimes this is preferable to having too much logic in the presentation layer:

    use v5.26;
    use Mojo::Template;

    my $mt = Mojo::Template->new;

    use Time::Piece;
    my $now = localtime;

    say $mt->render(<<~'EOF', $now->hms );
      % my $time = shift;
      <div>
        Time: <%= $time %>
      </div>
      EOF

As seen above, by default, arguments are passed in to the template positionally.
However it is much more natural to describe variables by name rather than position.
The `vars` attribute turns on your ability to pass a hash to the template; the hash keys become variable names in the template itself.

    use v5.26;
    use Mojo::Template;

    my $mt = Mojo::Template->new->vars(1);

    use Time::Piece;
    my $now = localtime;

    say $mt->render(<<~'EOF', { time => $now->hms } );
      <div>
        Time: <%= $time %>
      </div>
      EOF

It's just as easy to take that template from a file (or many files). This is the sort of thing I used to do this with [Template Toolkit](http://template-toolkit.org), a very fine and capable module that's as good as it ever was. But, I'm already using Mojo for quite a few things and it already has a templating engine. I can reduce my dependency count and focus on one templating language.

Typically, Mojo templates use the extension _.ep_. Loop through all of the files that you specify on the command line and cook the ones that have that extension

    use v5.14;
    use Mojo::Template;

    my $mt = Mojo::Template->new->vars(1);

    use Time::Piece;
    my $now = localtime;

    foreach my $file ( @ARGV ) {
      my $new_file = $file =~ s/\.ep\z//r;
      open my $fh, '>:utf8', $new_file or do {
        warn "Could not open $new_file: $!\n";
        next;
        };

      print {$fh} $mt->render_file($file, { time => $now->hms } );
      }

Now that you know everything about Mojo templates, you can process a directory full of them to start a new project.

    use File::Find qw(find);

    use v5.14;
    use Mojo::Template;

    my $mt = Mojo::Template->new->vars(1);

    use Time::Piece;
    my $now = localtime;

    my $wanted = sub {
      return unless /\.ep\z/;
      my $new_file = $File::Find::name =~ s/\.ep\z//r;
      open my $fh, '>:utf8', $new_file or do {
        warn "Could not open $new_file: $!\n";
        next;
        };

      print {$fh} $mt->render_file(
        $File::Find::name,
        { time => $now->hms }
        );
      };

    find( $wanted, @ARGV );

That's about it. Your `$wanted` subroutine can be more sophisticated to put the cooked files in a different directories, skip directories, and many other things. You don't even need to use [File::Find](https://perldoc.perl.org/File/Find.html); I like it because it comes with Perl.
Some clever use of [Mojo::File](https://mojolicious.org/perldoc/Mojo/File) and [Mojo::Collection](https://mojolicious.org/perldoc/Mojo/File) could surely do the trick too.
The rest of the complexity comes from the particular situation where you want to apply this.
