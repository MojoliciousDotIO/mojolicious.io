---
status: published
title: Announcing Mojolicious 9.0
tags:
  - async/await
  - non-blocking
  - promises
  - documentation
  - deployment
  - routing
author: Joel Berger
images:
  banner:
    src: '/blog/2021/02/14/announcing-mojolicious-9-0/nine_point_oh.png'
    alt: 'Mojolicious cloud with text "nine point oh"'
data:
  bio: jberger
  description: Announcing release of Mojolicious version 9.0
---
The Mojolicious Core Team is delighted to announce the release and immediate availability of [Mojolicious](https://mojolicious.org) [9.0](https://metacpan.org/release/SRI/Mojolicious-9.0), [code named](https://docs.mojolicious.org/Mojolicious#CODE-NAMES) "Waffle" 🧇!

Every major release I think that there can't be much more to add or change in Mojolicious and then when the next one arrives I reflect on how much has changed since I last thought that.
In 9.0 there's far too much to discuss each at length, so I'm going to highlight some of my favorites and then include a distilled list of changes since 8.0.

## Perl 5.16 and beyond

Mojolicious now requires Perl version 5.16. This change gives us useful tools to build Mojolicious including the `__SUB__` token for building self-referential callbacks without leaking.
We were pleased that the community response since the change a few months ago has been ... well crickets.
This is great news since we do hope to move to Perl 5.20 in the not so distant future so that we can use Perl's native signatures once that is a sound option for us.
We are already encouraging the use of signatures both in the documentation and in our code generation commands.

## Asynchronous Functionality

Clearly the highlight of the pre-9.0 development cycle has been the integration of Async/Await.
Thanks to Paul Evans (LeoNerd)'s efforts installing [Future::AsyncAwait](https://metacpan.org/pod/Future::AsyncAwait) enables Mojolicious to provide the new keywords `async` and `await` to provide the most seamless asynchronous development possible, and which is becoming more and more the standard for asynchronous code in other languages.
Writing a non-blocking endpoint is now as simple as

    use Mojolicious::Lite -signatures, -async_await;

    # Request HTML titles from two sites non-blocking
    get '/' => async sub ($c) {
      my $mojo_tx    = await $c->ua->get_p('https://mojolicious.org');
      my $mojo_title = $mojo_tx->result->dom->at('title')->text;
      my $cpan_tx    = await $c->ua->get_p('https://metacpan.org');
      my $cpan_title = $cpan_tx->result->dom->at('title')->text;

      $c->render(json => {mojo => $mojo_title, cpan => $cpan_title});
    };

    app->start;

When I teach non-blocking to people I can now tell them to follow a trivial recipe for most non-blocking tasks.
Simply `await` any function that returns a promise and mark and function that uses `await` with the `async` keyword.
Note also that all `async` functions return promises so `await` any calls to them.
There are some optimizations you can make at times and top-level `await` (if you aren't in a Mojolicious webapp) can be a little strange but to a first approximation that's all you need to write a non-blocking webapp today!

Speaking of promises (which are at the heart of Async/Await), Mojo::Promise has grown a lot this cycle too, adding `all_settled`, `any`, `map`, `timer`, and `timeout` class methods, changing its constructor to be more like the one in JavaScript and to warn when an unhandled rejected promise is destroyed.
The latter can help in development where such cases used to hide errors, now, much like the browser, you can at least find where things are going wrong even if you didn't wire all your promises to a catch callback like you should.

---

## Focus on Containerization and Cloud Deployments

The Mojolicious Core Team is aware that more and more deployments are in containers and cloud services these days and we've been thinking of ways to make that easier.
With 9.0 we've added two new features specifically designed to help with these types of deployments.

Most existing applications assume a standard deployment by an unprivileged user behind a reverse proxy, but with new deployment strategies the number of configurations an application might expect are too numerous to expect each application to support.
To address this we've added support for [deployment specific plugins](https://docs.mojolicious.org/Mojolicious/Guides/Cookbook#Deployment-specific-plugins) that help you add deployment-level functionality to existing applications.
Now the deployer is in control of these features, rather than needing to ask the application author to add support.

We've also extended the existing [reverse proxy](https://docs.mojolicious.org/Mojolicious/Guides/Cookbook#Reverse-proxy) support to allow for multiple trusted proxies, specifically when you know what the expected IP address or CIDR network you're expecting proxy requests from.
This can be useful both when deploying from say Kubernetes where it is likely you'll have several layers of local proxies, or when you're behind a third-party proxy like CloudFlare, who publish a list of their proxy networks.
This is an important safety feature in these situations, blindly trusting forwarding headers can lead to [big problems](https://twitter.com/logicbomb_1/status/1354452751619559428).

Also, we've noticed that many cloud deployment tools are based on YAML, so we've added a YAML configuration file loader to our existing Perl and JSON configuration loaders.
Because YAML is a tricky target and because ours is technically not-quite-YAML, we've called ours cheekily [NotYAMLConfig](https://docs.mojolicious.org/Mojolicious/Plugin/NotYAMLConfig).
In the unlikely event that that distinction should matter for your needs, you can load a specific YAML module from CPAN.

But it isn't just functionality, we've added a Dockerfile generation (`myapp generate dockerfile`) and added a Container [Cookbook recipe](https://docs.mojolicious.org/Mojolicious/Guides/Cookbook#Containers) to the documentation.
We've also added a [Cookbook recipe](https://docs.mojolicious.org/Mojolicious/Guides/Cookbook#Envoy) for the popular cloud-native proxy [Envoy](https://www.envoyproxy.io/).
If you have other common container or cloud recipes that you think should be added, please let us know!

## Documentation Improvements

Speaking of documentation, you might have noticed that both our [documentation site](https://docs.mojolicious.org) and [built-in templates](https://twitter.com/perlmojo/status/1343932370106392577/photo/1) for 404 and 500 pages have gotten a face lift.
They're even prettier and easier to read than before, they're responsive, and they have a newer code library (highlight.js) to better render our code.
Further the documentation site is now redeployed immediately on any push to master of the website or the main Mojolicious projects, `mojolicious`, `mojo-pg`, and `minion`, so that you always have the most up-to-date docs at your fingertips.

Along with the container and cloud-native changes I've already highlighted, we have updated our documentation to use of upcoming Perl native signatures throughout and paired it with updating our `app` and `lite-app` generators to generate applications with signatures too.

## Routing (and Rendering)

The routing engine is an often overlooked part of a web framework but it really is at the heart of everything that it does.
It often can often be a source of confusion or frustration, especially when it doesn't do what you expect.
For 9.0 we've made the router both safer and more closely aligned to user expectations.

The biggest change is that Mojolicious now prevents applications from using reserved placeholders in routes.
This was originally considered a "feature" because it allowed very terse route definitions for quick apps, but in practice most people that understood how that worked just used the long form while unsuspecting newcomers would trip on it from time to time.
We've also made several cases throw exceptions when routing would fail that used to fail silently or unexpectedly.
When a route points to a missing controller, a namespace without a controller or a controller without an action, you now get an exception rather than a 404, which would often confuse people.
Additionally, you get an exception when when auto-rendering fails or a call to render cannot render a response, which would often appear to hang (while it actually was trying to wait for a delayed response that was never going to happen).

Finally we've simplified some of the routing method names themselves.
We've removed the lesser-used `detour` and `route` methods in favor of the more generic `any` method.
We've renamed method that designates which HTTP methods to respond to (usually when picking several but not all of them, e.g. `GET` and `POST` but not `any`) from `via` to `methods`.
We've also renamed the method that designates conditional routing from `over` to `requires`.
I'm especially excited about this one since `over` implied a contrast with the commonly used `under` method, where no such contrast is meant to be implied; they do very different things.

## Logging

The big one for me is that Mojolicious now is capable of sanely using a contextual logger!
Mojolicious applications have a `log` attribute that holds a `Mojo::Log` instance, however that logger is global to the application and any context you'd want to add is only for a given request/response cycle.
Unlike blocking frameworks, a Mojolicious app might switch between several requests before any are rendered, meaning manually keeping context attached to that global logger was nearly impossible.
With 9.0 we now have the ability to use a per-controller "child" logger which descends from the global logger and still logs via it, but can keep its own context information.
It feeds that information to its parent when you log from it.

By default, these child loggers now have a random request id attached to it, however you can put whatever context you'd like to add there.
You can also pass these loggers (themselves an instance of `Mojo::Log`) to models or other code that might want to log with that context attached.

We've also improved logging performance in cases where generating the log message is expensive and useless if the log level means that the log message is not emitted.
If you pass a closure (code reference) to the logger's `debug`, `info`, `warn`, `error`, and `fatal` methods and the logger will only invoke that closure if the log level check is met.
In fact this improved Mojolicious' own performance metrics by 10%!

Please note that we have changed the log format slightly so be aware if you care about such things.

And finally, we've removed the confusing behavior of logging to a file if a `log` directory exists.
While it sometimes did what people wanted, it more often than not confused newcomers who couldn't find their logs.
The behavior now is to always log to `STDERR` but you can easily change it to point the file of your choice while your application is starting up.

## Proxy Helpers

How often have you written an application which takes a request from a client, makes a request of another server, then responds back to the client with the result?
I've done that quite often.
While it may seem trivial to do, there can be some subtle problems like what do you do it the read and write speeds mismatch badly enough?
Never thought about that?
Well you don't have to anymore.

Mojolicious now comes with proxy helpers, the generic [`proxy->start_p`](https://docs.mojolicious.org/Mojolicious/Plugin/DefaultHelpers#proxy-start_p) and the shortcuts `proxy->get_p` and `proxy->post_p` for common GET and POST requests.
Proxying a GET request in an action can now be as simple as

    $c->proxy->get_p('http://mojolicious.org')->catch(sub ($err) {
      $c->log->debug("Proxy error: $err");
      $c->render(text => 'Something went wrong!', status => 400);
    });

while using `start_p` you can customize the transactions to your exact needs by subscribing to available events.
See the linked documentation for an example.

## Mojo::DOM

CSS Selectors are amazing, but one major failing is that you can only extract the last element in your selector, not something in the middle.
Or to put it another way, thing they lack is the ability to conditionally match an element based on a property of its children.
Well CSS4 proposes that lets you assert just such a condition, the `:has` pseudo-class.

Without it, if you wanted to find all the links that have images as their content, you'd have to match `a > img` and traverse back up to the parent (which gets even harder if it isn't a direct child, e.g. `a img`).
However now you can simply do something like

    $ mojo get https://mojolicious.org 'a:has(> img)' attr href

for only direct descendants or

    $ mojo get https://mojolicious.org 'a:has(img)' attr href

to see all such links.
In its syntax, the inner selector is a "relative selector" where the `a` element in question, called the `:scope`, is implicitly a "virtual root".

    $ mojo get https://mojolicious.org 'a:has(:scope > img)' attr href

would be the same query.

Another neat feature we've imported from CSS4 is the `:is` pseudo-class.
In CSS3 you can "or" together several queries with a comma, but only for each query as a whole.
If you wanted to search for `h1` elements inside of other tags, you'd have to do for example `section h1, article h1, aside h1, nav h1`.
CSS4 gives you the `:is` pseudo-class that lets you group logical portions of a selector together so you can make a more concise and comprehensible query.
The previous example can be rewritten as `:is(section, article, aside, nav) h1`.

Now you've seen that I've mentioned that these are CSS4 features but CSS4 is not yet had a stable release, it is still being changed and updated.
Mojolicious supports these selectors (and a few others from CSS4) but they will continue to be marked as experimental until the spec is released officially.
Until then they might be changed or removed as the CSS4 spec changes.

## Team and Process

During the 9.0 development cycle the team grew!
We've welcomed CandyAngel and Christopher Rasch-Olsen Raa (mishanti1) and welcomed back Dan Book (Grinnz).
We're very happy to have them!

We've also added some automation.
In addition to the documentation site that I've already mentioned, and existing test runners, we've also added a perltidy check so that all PRs conform to our [rules](https://docs.mojolicious.org/Mojolicious/Guides/Contributing#Rules) about it.
We also simplified our PR process so that if a PR gets two approvals from the team it is automatically merged.
This is a wonderful process boost since it encourages PRs to be reviewed and ensures that PRs with interest can see action quickly.

Finally, We're always looking for more help and to encourage people to do so, we've decided to open the process somewhat.
We are encouraging people to review PRs even if you don't have review rights.
This will do two things for us, first it will give us more opinions both in regards to community interest and from people who might have technical knowledge of the topic.
Secondly, we've started tracking who is reviewing PRs and if you catch our notice, you might be on track to join more officially.

If this sounds interesting, at any level, we hope to see you on our [pulls page](https://github.com/mojolicious/mojo/pulls).
While you are there, you might see that we've enabled [github discussions](https://github.com/mojolicious/mojo/discussions) as an alternative to (and possible eventual replacement for) our [mailing list](https://groups.google.com/g/mojolicious).

Thanks for reading this!
We hope you'll love Mojolicious 9.0!
___

As promised here is a distillation of all the non-trivial [Changes](https://github.com/mojolicious/mojo/blob/master/Changes) since 8.0.

- Increased Perl version requirement to 5.16.0. This is just a first step however, at some point in the not so distant future we will increase the Perl version requirement to 5.20.0 for full subroutine signatures support
- Async/Await
  * Requires `Future::AsyncAwait` 0.36
  * enable with `-async_await`
- `Mojo::Promise` enhancements
  * Added `all_settled`, `any`, `map`, `timer`, `timeout`
  * constructor arguments more like Javascript
  * warn when unhandled rejected promise is destroyed
  * Added `MOJO_PROMISE_DEBUG` environment variable
  * Improved `wait` method in Mojo::Promise not to be affected by manually stopped event loops
  * Improved `eval` command with support for promises
- Docker
  * `generate dockerfile` command
  * Container cookbook recipe
- Envoy deployment recipe
- Trusted proxy support
- Added support for deployment specific plugins
- Disallowed the use of reserved stash values, such as `/:action`, in route patterns
- Make routing safer and clearer
  * Throw exceptions for missing controllers
    - Disallowed namespace without controller for routing
  * Throw exceptions for routes with controllers but without action
  * Die if auto rendering failed or call to `$c->render` cannot render a response
- Cleaned up lesser-used router methods
  * Removed `detour`, `route` (use `any`)
  * Renamed `over` to `requires`, `via` to `methods`
- Contextual logger
  * Added `log` helper to which builds a child logger with context (request id)
  * Added `context` method to `Mojo::Log`
- Slightly changed log format (datetime format, process id, lines joined with spaces)
- Removed automatically logging to `log/$mode.log` if log directory exists, default is always `STDERR` now
- Improved log messages generated by Mojolicious to include request ids when possible
- Improved `debug`, `error`, `fatal`, `info` and `warn` methods in Mojo::Log to accept closures to generate log messages on demand, so expensive code for debugging can be deactivated easily in production
  * Improved Mojolicious performance by up to 10% with more efficient logging
- Added support for YAML config files:
  * Added module `Mojolicious::Plugin::NotYAMLConfig`
  * Improved app generator command to use a YAML config file
- Proxying with backpressure monitoring
  * Added `proxy->get_p`, `proxy->post_p` and `proxy->start_p` helpers
  * Added `high_water_mark` attribute in Mojo::IOLoop::Stream
  * Added `bytes_waiting` and `can_write` methods in Mojo::IOLoop::Stream
- Added EXPERIMENTAL support for SameSite cookies to better protect Mojolicious applications from CSRF attacks
  * Added EXPERIMENTAL `samesite` attributes to `Mojo::Cookie::Response` and `Mojolicious::Cookies`
- Improved helper performance (`Mojo::DynamicMethods`)
- Added `before_command` hook (expimental)
- `Mojo::DOM`
  * `all_text` method now excludes `<script>` and `<style>` from text extraction in HTML documents
- `Mojo::DOM::CSS`
  * Added `:scope`, `:has` (experimental)
  * Added `:is` (experimental)
  * Added `:any-link` (experimental)
  * Case-sensitive attribute selectors like `[foo="bar" s]`
- `Mojo::IOLoop::Subprocess`
  * Added support for progress updates (`progress` method and event)
  * Added `run_p` method
  * Added `exit_code` method
  * Added `cleanup` event
- Improved `Mojolicious::Commands` to treat commands like `mojo generate lite_app` as `mojo generate lite-app`
- `Test::Mojo`
  * Improved extenability and testability of `Test::Mojo` with `test` method and `handler` attribute
  * Added `attr_is`, `attr_isnt`, `attr_like` and `attr_unlike` methods
  * Added `header_exists` and `header_exists_not` methods
- `Mojolicious::Validator`
  * Added `not_empty` filter
  * Simplify `size` check
  * Fixed validator to also validate empty string values instead of ignoring them. This behaviour had caused a lot of confusion in the past
- Added compression (gzip) functionality to `Mojolicious::Renderer` for dynamic content
  * activate with `Mojolicious::Renderer::compress` (see [the Rendering Guide](https://docs.mojolicious.org/Mojolicious/Guides/Rendering#Post-processing-dynamic-content))
- Improved `is_fresh` method in Mojolicious::Static with support for weak etags
- `Mojo::Exception`
  * Added support for `MOJO_EXCEPTION_VERBOSE` environment variable
  * `raise`, `check` functions
  * include a stack trace in verbose output
- `Mojo::Base`
  * Improved `Mojo::Base` flags not to require a certain order
  * Added support for weak reference accessors to `Mojo::Base`
  * Improved `Mojo::Base` to enable the Perl 5.16 feature bundle with `unicode_strings`, `unicode_eval`, `evalbytes`, `current_sub` and `fc`
- `Mojo::Server::Daemon` (and thus the other servers) now differentiate between `inactivity_timeout` and `keep_alive_timeout`
- `Mojo::Reactor::again` can now change the timeout for a retry
- New conveniences
  * Added `Mojo::Util::network_contains`
  * Added `Mojo::Util::scope_guard`
  * Added `content_type` and `file_types` to `Mojolicious::Types`
  * Added `extname`, `curfile`, `stat`, `lstat`, `remove`, and `touch` to `Mojo::File`
  * `humanize_bytes` in `Mojo::Util` and `Mojo::ByteStream`
  * Added `head` and `tail` to `Mojo::Collection`
  * Added `l` function to ojo
  * Added `save_to` method to Mojo::Message
- Website improvements
  * Style
  * Responsiveness
  * Replaced `prettify.js` with `highlight.js`
  * auto-deployed on push to master
- Built-in templates [updated too](https://twitter.com/perlmojo/status/1343932370106392577/photo/1)
- Encouraged signatures
  * Improved `app` and `lite_app` generators to use templates with subroutine signatures
  * Updated all documentation to use subroutine signatures
- Removed module Mojo::IOLoop::Delay
  * Spun out to CPAN for long term compat (but not continued development)
- Removed deprecated success method from `Mojo::Transaction` (use `!$tx->error` or `$tx->result`)
- Cleaned up lesser used connection properties in `Mojo::UserAgent` and `Mojo::IOLoop::Client`
- Removed `config` stash value
- Removed `Mojo::Collection::slice`
- Welcome to the Mojolicious core team CandyAngel, Christopher Rasch-Olsen Raa and Dan Book
- Mergebot
- Reviewers wanted!
- Perltidy check
