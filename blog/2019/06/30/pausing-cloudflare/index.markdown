---
images:
  banner:
    alt: image tba
    data:
      attribution: |-
        attribution tba
    src: /blog/2019/06/30/pausing-cloudflare/banner.jpg
author: brian d foy
data:
  bio: briandfoy
  description: How to make a static Markdown website with Yancy
status: published
tags:
  - cloudflare
  - mojo-useragent
title: Pausing Cloudflare
---

My various Perl blogs, such as
[learningperl6.com](https://www.learningperl6.com), run through
[Cloudflare](https://www.cloudflare.com), a global service that sits in
front of servers to filter and respond to traffic. Should I ever be
slashdotted (unlikely) or the target of some random attack (much more
likely), I can turn that off at Cloudflare before my server falls
over.

Cloudflare lets me pause their service so I can deal with the servers
directly. For a long time, I'd pause the sites by hand through the web
UI. You can probably already see where this is going.

The first time I need to do something, I do it manually. The second
time I think "I should automate this". The third time, "I should
automate this". At some point, I say "I'm automating this". Typically
it's very easy to automate, but I still have half my brain in the
pre-web-API world. Now everyone has one of those, and some are even
easy to use. Embarrassingly, I didn't think to automate this because
the task deserved it. Instead, I wanted an example for my upcoming
ebook on Mojolicious web user agents.

---

There are two things I need for the [Cloudflare
API](https://api.cloudflare.com): my overall account key and the ID of
the particular site that I want to affect. I make a PATCH request and
send a little bit of JSON to pause a single site:

	use Mojo::UserAgent;
	my $ua = Mojo::UserAgent->new;
	my $url = 'https://api.cloudflare.com/client/v4/zones/' . $site_id;
	my $tx = $ua->patch( $url =>
		json => { paused => Mojo::JSON->true }
		);

The first time I wrote this program, I copied the IDs for each site—about
20 of them—into a hash. That wasn't a big deal because I already had
the list, but I would otherwise have to visit each site's Cloudflare
page. That's certainly something I wouldn't want to do were I managing
hundreds of domains. But, the API will give all that too me too. After
a couple minutes, I had this program:

	use Mojo::Base -base, -signatures;
	use Mojo::UserAgent;

	my $ua = Mojo::UserAgent->new;
	$ua->on( start => sub ($ua, $tx) {
		$tx->req->headers->header('X-Auth-Email' => $ENV{CLOUDFLARE_EMAIL});
		$tx->req->headers->header('X-Auth-Key'   => $ENV{CLOUDFLARE_AUTH_KEY});
		});

	my $boolean = $ARGV[0] ? 'true' : 'false';

	my $sites_tx = $ua->get(
		'https://api.cloudflare.com/client/v4/zones' =>
		form => {
			page     => 1,
			per_page => 50,
			}
		);

	foreach my $site ( $sites_tx->result->json->{result}->@* ) {
		say join ' ', $site->@{qw(id name)};
		my $url = 'https://api.cloudflare.com/client/v4/zones/' . $site->{'id'};
		my $tx = $ua->patch( $url =>
			json => { paused => Mojo::JSON->$boolean() }
			);
		say $tx->result->code, ' ', $site;
		}

To use this, I supply a command-line argument. A true argument
(anything Perl considers true) should pause all the sites:

	$ pause-cloudflare 1

When I'm done, I use a false value to unpause the sites:

	$ pause-cloudflare 0

## The details

[Mojo::Base](https://mojolicious.org/perldoc/Mojo/Base) takes care of
the usual boilerplate with its `-base` and `-signatures` settings. The
[signature feature introduced in v5.20](https://www.effectiveperlprogramming.com/2015/04/use-v5-20-subroutine-signatures/)
is still experimental, but Mojolicious can load it for you and turn off
its experimental warnings.

Since I'm only talking to Cloudflare, I set up my user-agent to do
some work for every request. The API expects my email and API key in
the request headers so I use a `start` handler to add those to every
request. I could do this for every request, but if I need to talk to
a different server, I can make a different user-agent.

Next, I need to get the list of my zone (site) IDs. The `$sites_tx`
transaction handles that. Since I have fewer than 50 sites, I can get
everything in one request. Otherwise I'd have to do some work to
handle the pagination, in which case I might want to bring in
[Promises](/blog/tag/promises/) to start pausing sites while I'm still
fetching site IDs.

The `foreach` goes through all of the sites from `$sites_tx` to get
the the ID. From that I make a new request. The PATCH request pauses
the site: now Cloudflare doesn't get in the way of requests.

There's a trick here, though. In the JSON, I need to send a boolean
value. That's a `true` or `false`, but not the strings `"true"` or
`"false"`. These mean different things in JSON:

	{ "value": true }
	{ "value": 1 }
	{ "value": "true" }

In my own programming I can normalize those values to be what I need
them to be, but when I'm talking to a web API, I don't have that
flexibility. Perl doesn't have such a value that I can put in the hash
I give for the PATCH data. This won't work:

   json => { paused => "false" }

How do I know that? That's what I did first, and that's what all of
the answers to "why doesn't my Cloudflare API call work?" point to.
That's not the expected value. In this case, the string value "false"
ends up being true on the other side (just like "false" is a true
value in Perl).

But, Mojolicious knows this. I have two options. References to 0 or 1
turn into the right JSON boolean values:

	json => { paused => \0 }

I can also call `Mojo::JSON->true` or `->false` to get the same
thing. I like that a bit better because references to literal values
tend to cause question (and some people think it's a mistake so they
remove the `\`.

I use the command line argument to decide which of those methods to
choose and store the method name in `$boolean`. I use that variable as
the method name for
[Mojo::JSON](https://mojolicious.org/perldoc/Mojo/JSON)

## Wrapping it up

Mojolicious facilities for events (the `start` event) and built-in JSON
support made this task quite easy. It's easy to configure a user-agent
for a particular site and then extract the results.

Now that I have a program that automates some work, something that
took me five minutes takes me no time at all. Not only that, it
happens the same way each time. I don't have the chance to forget to
unpause a site. If I'd started the whole thing by looking for an API
(which, to be fair, I'm not sure existed when I started using the
service) I could have saved myself quit a bit of time.
