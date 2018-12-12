---
status: published
title: Practical Web Content Munging
author: Joe Cooper
data:
  bio: swelljoe
  description: Working with ugly old websites using Mojo::UserAgent and Mojo::DOM
---
Following brian d foy's great write-up of using Mojo::DOM selectors from Day 5, I thought it'd be fun to talk about some website migration scripts I recently built using Mojo::UserAgent and Mojo::DOM, two powerful aspects of Mojolicious. There was a time when Perl ruled the internet; it was the glue that held it all together. The world has changed and there is more than one kind of glue for the internet today. But, when I started looking at updating an old website that hasn't been updated in roughly 15 years (it's gotten new content, but the design and HTML template is the same), I found myself looking to Perl as the simplest option, because of the strength of Mojo::UserAgent and Mojo::DOM. In the past I would have used regexes, and then I would likely have had to add a bunch of special cases where the regex didn't quite match, and then after a few hours of fighting I would have resigned myself to cleaning up the remaining handful of broken pages by hand. No more! Mojo::DOM always gets it right, and with alarmingly little code.
---

##From Static Site to Static Site Generator

The problem I set out to solve was taking an old static website that was once hosted on SourceForge.net and migrating it to an exciting new...um...static website. But, this time, it'll be a modern take on a static website. Instead of editing HTML by hand and using home-built page munging scripts that would do things like insert news items or changelog entries at the top of the content div using regexes, I'll be using a modern static website generator. There are several such generators, including the well-known Jekyll, which is written in Ruby, Hugo, built with Go, and Statocles, which is in Perl and runs this site. For my project, I chose Hugo, for its speed and maturity.

So, to start out, I need to fetch the old site. I could have bothered the old maintainer of the site about it and gotten the original sources, but I decided just to fetch them from the web. One option would be to use wget or curl; the stuff we do later with Mojo::DOM can work with HTML from anywhere, including local files. But, it seemed simpler to do it all in Perl. So, we'll fetch a list of page paths, and then do stuff with them. Mojo::UserAgent does the hard work. The simplest example might look something like this:

```perl
use Mojo::UserAgent;

my $url = 'intro';
my $ua  = Mojo::UserAgent->new;
my $tx = $ua->get("webmin.com/$url.html");
```

That's it! We just fetched a web page. You might be tempted to print out $tx to see what's in it (that's what I did, rather than reading the docs, at first). But, it's a `Mojo::Transaction::HTTP object`. We have to reach down through the hierarchy, first looking at the `res` attribute, which is a `Mojo::Message::Response` object, which has a `body` method:

```perl
print $tx->res->body();
```

This will display the HTML `<body>` contents. But, that's not really very interesting. Using a regex to find everything between `<body>` and </body> isn't so difficult. But, we can do much more interesting and powerful things very easily with a Mojo response.

The `res` response object also provides a `dom` object, that gives the ability to select parts of an HTML document using CSS selectors. So, if I have a document with a `#main` div, I can retrieve just the contents of that div using something like:

```perl
my $main = $tx->res->dom->find("#main");
```

Of course, if you're familiar with CSS selectors, you know it can be more precise than that. So, let's talk about something concrete. In my case, I have a couple of different primary "styles" of page. One is a page of news items, which is lots of sections that are visible to the human eye, but they aren't in their own divs. They're just a set of vaguely similar shapes of HTML.

I want to divide those news items out into their own individual pages, which can then be aggregated in whatever way I like, such as having them available in a paginated list or having the most recent items included in a div on the front page of the website.

Those news items look something like this:

```html
<h1>Latest News</h1>

<h3>Frobnitz 4.5 released</h3>
<p>
This release improves castigation of the widely formed sonterols.
<br>
Current users may upgrade by applying coil oil to application points A, C, W, DF, Y0, IN34, RS232, and Frank, then gently inserting the conjubilant apparatus into the ferulic treeble socket.
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
```

Notice that the structure of this is regular but not selectable with any one div or piece of markup. I can't say, `find('h3')`, here, because that would just bring back the title of the news item (which is useful, because we want the title of the blurb for the title of our new news page). We need something that will grab everything *between* each `h3`.

So, I want to grab all of the titles, and grab all of the HTML between the titles, and put them all into some sort of data structure so I can spit them out into pages of there own.

Let's start with the titles, as it'll show a neat trick Mojo has up its sleeves.

```perl
use Mojo::UserAgent;

my $ua = Mojo::UserAgent->new;
my $tx = $ua->get('http://webmin.com');

my $main = $tx->res->dom->at('#main');
my @headers = $main->find('h3')->map('text')->each;
```

Do you see it? The `find` method here is returning a [Mojo::Collection](https://metacpan.org/pod/Mojo::Collection). "Collection" is a fancy way to say "list", but these lists have a bunch of useful utility methods, similar to some core Perl functions that operate on lists, as well as methods found in `List::Util`. It has the usual suspects, like `join`, `grep`, `map`, and `each`. So, they're fancy, and they deserve a fancy name.

After this `@headers` will now contain all of the titles for all of the news items on the page. Try doing *that* in two lines of clear code with regexes (and, we could have chained all of this, including finding `#main`, into one line, but because I'm re-using `#main` multiple times I put it into its own variable).

To break this down a little bit, `map` calls the given method (`text`) on every item returned by find, and then `each` returns them all as a list which can be slurped into an array, as I've done.

Now, an even trickier thing to do with regexes would be to find the text between each title. But, with Mojo::DOM, we can grab it with just a few more lines of code (there's probably even a way to do it with one line of code, but this is what I came up with in a few minutes of experimentation, I welcome suggestions for how to improve it).

```perl
my @hcols   = $main->find('h3')->each;
my @paras;
for my $h (@hcols) {
  push(@paras, $h->next->content);
}
```


