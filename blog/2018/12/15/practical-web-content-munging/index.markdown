---
status: published
title: Day 15: Practical Web Content Munging
author: Joe Cooper
images:
  banner:
    src: '/blog/2018/12/15/practical-web-content-munging/banner.jpg'
    alt: 'An eyeball of alarming size'
    data:
      attribution: |-
        Banner image: [An eyeball looking at Dallas](https://flic.kr/p/Rqj9Jj) by [Joe Cooper](https://www.flickr.com/photos/nerdnomad/) licensed [CC BY-NC-SA 2.0](https://creativecommons.org/licenses/by-nc-sa/2.0/)
tags:
  - advent
  - css
  - html
data:
  bio: swelljoe
  description: Working with ugly old websites using Mojo::UserAgent and Mojo::DOM
---
Following brian d foy's great [write-up of using Mojo::DOM selectors from Day 5](https://mojolicious.io/blog/2018/12/05/compound-selectors/), I thought it'd be fun to talk about some website migration scripts I recently built using [Mojo::UserAgent](https://mojolicious.org/perldoc/Mojo/UserAgent) and [Mojo::DOM](https://mojolicious.org/perldoc/Mojo/DOM), in order to show some basic practical usage of these modules. I've never really used Mojo before, but I recently needed to migrate a website that hasn't had a redesign in about 15 years, and it seemed like a great fit for my content mangling needs. In the past I would have used regexes, and probably would have spent at least as much time manually massaging the input or output into the right shape as I spent writing code. Mojo::DOM made it easy for me, a Mojolicious beginner, to get the results I wanted really quickly.

##From Static Site to Static Site Generator

The problem I set out to solve was taking an old static website that was once hosted on SourceForge.net and migrating it to an exciting new...um...static website. But, this time, it'll be a modern take on a static website. Instead of editing HTML by hand and using home-built page munging scripts that would do things like insert news items or changelog entries at the top of the content div using regexes, I'll be using a modern static website generator. There are several to choose from, including the well-known Jekyll, which is written in Ruby, Hugo, built with Go, and Statocles, which is in Perl and runs this site. For my project, I chose [Hugo](https://gohugo.io), for its speed and maturity.
---

Hugo, like most modern static site generators, expects content to be in Markdown format with some metadata at the top of the file. I want to convert our crusty old HTML, as you'll see an example of below, into something that looks a bit like this:

    ---
    title: "Frobnitz 3.141593 released"
    date: 2016-10-10
    description: "This release includes a fog-flavored bauble of three equal sides, providing the restless..."
    categories: []
    aliases: []
    toc: false
    draft: false
    ---
    This release includes a fog-flavored bauble of three equal sides, providing 
    the restless digital spirits a brief respite from their painful awareness of
    impermanence.

    You can find the new version under the usual shadowy bridge.

So, to start out, I need to fetch the old site. I could have bothered the old maintainer of the site about it and gotten the original sources, but I decided just to fetch them from the web. One option would be to use wget or curl; the stuff we do later with Mojo::DOM can work with HTML from anywhere, including local files. But, it seemed simpler to do it all in Perl. So, we'll fetch a list of page paths, and then do stuff with them. Mojo::UserAgent does the hard work. The simplest example might look something like this:

    use Mojo::UserAgent;

    my $url = 'intro';
    my $ua  = Mojo::UserAgent->new;
    my $tx = $ua->get("example.tld/$url.html");

That's it! We just fetched a web page. You might be tempted to print out $tx to see what's in it (that's what I did, rather than reading the docs, at first). But, it's a [Mojo::Transaction::HTTP](https://mojolicious.org/perldoc/Mojo/Transaction/HTTP) object. We have to reach down through the hierarchy, first looking at the `res` attribute, which is a [Mojo::Message::Response](https://mojolicious.org/perldoc/Mojo/Message/Response) object, which has a `body` method:

    print $tx->res->body();

This will display the response body with its HTML contents. But, that's not really very interesting. But, we can do much more interesting and powerful things very easily with a Mojo response.

##CSS Selectors

The `res` response object provides a `dom` object, that gives the ability to select parts of an HTML document using CSS selectors. So, if I have a document with a `#main` div, I can retrieve just the contents of that div using something like:

    my $main = $tx->res->dom->find("#main");

Of course, if you're familiar with CSS selectors, you know it can be more precise than that. So, let's talk about something concrete. In my case, I have a couple of different types of page. One is a page of news items, which is lots of sections that are clearly delineated to a human reader, but they aren't in their own divs or otherwise grouped as far as the HTML parser can tell. They're just a bunch of vaguely similar shapes of HTML.

I want to divide those news items out into their own individual pages, which can then be aggregated in whatever way I like, such as having them available in a paginated list or having the most recent items included in a div on the front page of the website.

Those news items look something like this on the old site:

    <h1>Latest News</h1>

    <h3>Frobnitz 4.5 released</h3>
    <p>
    This release improves castigation of the widely formed sonterols.
    <br>
    Current users may upgrade by applying coil oil to application points A, C, W, 
    DF, Y0, IN34, RS232, and Frank, then gently inserting the conjubilant apparatus
    into the ferulic treeble socket.
    </p>
    <p class="post-footer align-right">
    <span class="date">December 2, 2018</span>
    </p>

    <h3>Frobnitz 4.4 released</h3>
    <p>
    This release is effulgent and wavering gently.
    <br>
    Becomes bees.
    </p>
    <p class="post-footer align-right">
    <span class="date">November 30, 2018</span>
    </p>

Notice that the structure of this is regular but not selectable with any one div or piece of markup. I can use the selector `h3` to get the headings, but the text of each news item is just a paragraph, and we also want to grab the date separately.

So, I want to grab all of the titles, and the paragraph following the title, and the date, and put them all into some sort of data structure so I can spit them out into pages of their own.

Let's start with the titles, as it'll show a neat trick Mojo has up its sleeves.

    my $main = $tx->res->dom->at('#main');
    my @headers = $main->find('h3')->map('text')->each;

Do you see it? The `find` method here is returning a [Mojo::Collection](https://mojolicious.org/perldoc/Mojo/Collection). "Collection" is kind of a fancy way to say "list", but these lists have a bunch of useful utility methods, similar to some core Perl functions that operate on lists, as well as methods found in `List::Util`. It has the usual suspects, like `join`, `grep`, `map`, and `each`. So, collections are fancy, and they deserve a fancy name. In the above, `map` calls the method `text` on every item returned by `find` and `each` returns the results as a list.

After this, `@headers` will contain all of the titles. There's no way I could do that as simply with regexes (and, we could have chained all of this, including finding `#main`, into one line, but I'm re-using `#main` again so I put it into a variable).

Now, an even trickier thing to do with regexes would be to find the immediately subsequent sibling of these headers. But, with Mojo::DOM, we can grab it with just a few more lines of code (there's probably a way to do it with even less code, but this is what I came up with in a few minutes of experimentation).

    my @paras;
    for my $header ($main->find('h3')->each) {
      push (@paras, $header->next->content);
    }

This, once again selects the `h3` elements, and iterates over the resulting collection of DOM objects, putting each one into `$header` as it loops. Then we pick out the `content` of the `next` element (which, in my case, is always a single paragraph, sometimes containing one or more `br` tags), and pushes them all into `@paras`.

So, now we've got an array of headers, an array of the following paragraphs, and we just need to get the dates. This one is actually very easy, because the HTML template marks the date using a `date` class.

    my @dates = $main->find('.date')->map('text')->each;

Pow! We're done. OK, not quite. We've yet to deliver on the "munging" part of the title of this post. We have the data from our crusty old HTML site, now let's do something with it.

##Munging the Dates

As shown in the example Hugo content item above, I want to include a date in the metadata. Luckily, we have dates associated with each news item. Unluckily, they aren't in the format that Hugo expects. I did a little digging on the CPAN and found [Time::Piece](https://metacpan.org/pod/Time::Piece), which is a clever module that parses and converts times and dates in most common formats.

I need my dates to look like `2017-09-30`, so I used the following code (assume this is inside a loop that's putting each subsequent date in the `@dates` array we made above into `$date`):

    use Time::Piece;
    my $tp = Time::Piece->strptime($date, "%B %d, %Y");
    my $fixed = $tp->strftime("%Y-%m-%d");

##Munging Into Markdown

I'll also need to convert to Markdown. I've used [HTML::WikiConverter](https://metacpan.org/pod/HTML::WikiConverter) for the task.

In its simplest form, we could do something like this (again assuming we're in a loop where `$para` gets a value from `@paras` on each iteration:

    use HTML::WikiConverter;
    my $wc = new HTML::WikiConverter(dialect => 'Markdown');
    my $md = $wc->html2wiki( $para );

Done!

##Generating the Metadata

As we saw earlier, Hugo posts have metadata that precede the Markdown content, and contains information like author information, date of publication, description, etc. Some are optional, but some are mandatory (and I need dates so I can show the most recent news items on the front page of the new site). I need to automatically generate all of this based on the information I gathered from the original HTML.

I'm going to gloss over how the `@entries` data structure was built, but I will mention that it's an array of hashes containing the three pieces of data we found above. I'll also link to a GitHub repo with the real world code at the end, if you want to see the gritty details.

    use Mojo::File;
    use String::Truncate qw(elide);

    for my $e (@entries) {
      my $desc = elide($e->{'text'}, 100, {at_space => 1});
      my $md = <<"EOF";
    ---
    title: "$e->{'title'}"
    date: $e->{'date'}
    description: "$desc"
    categories: []
    aliases: []
    toc: false
    draft: false
    ---
    $e->{'text'}
    EOF

      my $filename = lc $e->{'title'};
      $filename =~ s/\s/-/g;
      $filename =~ s/[!,()'"\/]//g;
      my $file = Mojo::File->new("content/news/$filename.md");
      $file->spurt($md);
    }

There's a lot going on here, and I'll only briefly explain some of it, since it's not Mojo-related.

The first line of the loop creates a description, which is usually a summary or whatever. In my case, the main site will show the description as a clickable link, so the user will get a short summary of the news item on the main page, and then the ability to click it to see the whole item. I'm using the [String::Truncate](https://metacpan.org/pod/String::Truncate) module, which has an `elide` method that will truncate a string on word boundaries and add an ellipsis to indicate text was left out.

Then, in the here document, I fill in all the metadata, using values from `$e`, each of which is just a reference to a hash. Then we write it to a file using the `spurt` method of [Mojo::File](https://mojolicious.org/perldoc/Mojo/File). That's it! When this is done in a loop over a page with any number of news items in the expected format, we get a bunch of nice new Hugo posts.

In the interest of clarity and brevity (and because it's basic Perl and not Mojo-related) I've left out the loops and building of the data structure that I used when generating metadata. If you want to see it all in one place, with some ugly bits to workaround broken dates and things that just don't work well in Markdown (like tables), you can see the code (still in progress, but nearly ready to migrate our cranky old site!) in the [repository on GitHub](https://github.com/swelljoe/webmin-com-extractor). I didn't make it pretty, because it only needs to run once, but it will do the job, and it didn't take much time to build, thanks to Mojolicious and a few other modules from the CPAN.
