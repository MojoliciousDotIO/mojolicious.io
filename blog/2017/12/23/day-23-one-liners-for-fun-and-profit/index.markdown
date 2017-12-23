---
title: 'Day 23: One-Liners for Fun and Profit'
tags:
    - advent
    - command
    - debugging
    - lite
author: Joel Berger
images:
  banner:
    src: '/static/chess.jpg'
    alt: 'Old man playing timed chess'
    data:
      attribution: |-
        <a href="https://commons.wikimedia.org/w/index.php?curid=21375125">Image</a> by © <a rel="nofollow" href="http://www.royan.com.ar">Jorge Royan</a>, <a href="https://creativecommons.org/licenses/by-sa/3.0" title="Creative Commons Attribution-Share Alike 3.0">CC BY-SA 3.0</a>.
data:
  bio: jberger
  description: For those times when you just need a quick check or example.
---

Perl is well-known for its [one-liners](http://www.catonmat.net/download/perl1line.txt): short programs written as part of the [command line invocation of the interpreter](http://perldoc.perl.org/perlrun.html).
Certainly every programmer or sysadmin has the need, from time to time, to do a quick one-off task programmatically.
Such tasks can be done with a full script, to be sure, but once you get the hang of writing them, one-liners can save the time and hassle of actually doing so.

These tasks may include removing unwanted lines from files, collecting data from logs, or even a quick proof-of-concept of something that would become a script later.
They can read lines in files, even multiple files, can operate on files in-place, can read from STDIN as a pipe.
But while one-liners have been tools of the trade for these activities, certainly no such thing would be practical for web tasks, right?

But of course, on [day 5](https://mojolicious.io/blog/2017/12/05/day-5-your-apps-built-in-commands/) and [day 6](https://mojolicious.io/blog/2017/12/06/day-6-adding-your-own-commands/) of this series that we saw that we can build command line tools with your app.
We have even seen how to use the [eval](http://mojolicious.org/perldoc/Mojolicious/Command/eval) command to run a one-liner against your app.
So could we take this further?

Could we do remote data fetching and manipulation as a one-liner?
Could we build an entire web application as a one-liner?
Would I be asking if the answer was no?

## A Note on Readability

Almost always when I post articles on Mojolicious, I'm keenly aware of Perl's reputation for readability.
I firmly believe that Perl can be written to be easily read, it just takes awareness from the author.
But every now and again you need to have a little fun!

One-liners are not meant for too much reuse.
Their value is the extreme rapidity of their creation and as such they are terse.
If they were well-formed scripts, well, you'd put them in a file.

So please, if this is the first time you see Perl and Mojolicious, I want you to know that this is the exception and not the rule!

## The Key ... words?

Mojo one-liners are just Perl one-liners.
You will use `-E` (or `-e`) to write the program.
You might use `-n` to loop over input, or `-p` to do the same while printing `$_` after each item, just like normal one-liners.

To get the extra Mojo goodness, add `-Mojo`.
The name itself is a cute hack.
Since `-M` is what loads a module on the command line, the module name is therefore [`ojo`](http://mojolicious.org/perldoc/ojo).

This module imports many functions into the main namespace for your use.
The names of these functions are (almost) all just one letter long: these are one-liners after all, brevity is key!
I'll show you them below.

Importantly, however, the main namepace also imports [Mojolicious::Lite](http://mojolicious.org/perldoc/Mojolicious/Lite).
Whether you use it or not, you have a Lite app just waiting for you!
One caveat is that this does import `strict`, so you must declare your variables unless you disable strict manually.

### Output and Input

The first two functions we will look at are related to output.
The function `r` takes an argument and formats it with [Mojo::Util's wrapper](http://mojolicious.org/perldoc/Mojo/Util#dumper) for [Data::Dumper](https://metacpan.org/pod/Data::Dumper).
Somewhat similarly the `j` function takes any Perl data structure and [return it as a JSON string](http://mojolicious.org/perldoc/Mojo/JSON#encode_json).

    perl -Mojo -E 'print r({hello => "world"})'
    perl -Mojo -E 'print j({hello => "world"})'

The `j` function is more interesting in that if you give it a string, it will [decode it from JSON](http://mojolicious.org/perldoc/Mojo/JSON#decode_json) and return a data structure.

    echo '{"hello":"world"}' | perl -Mojo -E 'print j(<>)->{hello}'

On their own, these aren't that interesting.
But when combined with others, you can start to have fun.

### Making Requests

Most of the functions are dedicated to making HTTP requests.
There are functions for

* get - `g`
* head - `h`
* post - `p`
* put - `u`
* patch - `t`
* delete - `d`
* options - `o`

These are just their respective calls on [Mojo::UserAgent](http://mojolicious.org/perldoc/Mojo/UserAgent) with the one space-saving optimization that they return the [Response](http://mojolicious.org/perldoc/Mojo/Message/Response) object rather than the transaction.

A simple use could be to fetch the title from a webpage.

    perl -Mojo -E 'print g("mojolicious.org")->dom->at("title")->text'

This simple request is something you could have done with the [get](http://mojolicious.org/perldoc/Mojolicious/Command/get) command,

    mojo get mojolicious.org title text

however the one liner form can let you do much more, like complex mapping.
For example, to get the text and link from each link on a site as a data structure.

    perl -Mojo -E 'print r({ g("mojolicious.io/blog")->dom->find("a")->map(sub{ $_->text => $_->{href} })->each })'

You can also use Perl's looping constructs.
Perhaps you have a file full of sites for which you want to get some data.

    $ cat sites
    mojolicious.org
    mojolicious.io
    mojocasts.com

You can then take each line, request it, and post-processes.

    perl -Mojo -nlE 'say g($_)->dom->at("title")->text' sites

### Object Constructors

The Mojo toolkit contains many helpful classes.
The ojo functions provide quick constructors for them, so you can access their functionality without all the typing!

* [Mojo::ByteStream](http://mojolicious.org/perldoc/Mojo/ByteStream) - `b`
* [Mojo::Collection](http://mojolicious.org/perldoc/Mojo/Collection) - `c`
* [Mojo::DOM](http://mojolicious.org/perldoc/Mojo/DOM) - `x`
* [Mojo::File](http://mojolicious.org/perldoc/Mojo/File) - `f`

So you can slurp an HTML file with `f`, then build DOM object with `x` and get its title

    perl -Mojo -E 'say x(f(shift)->slurp)->at("title")->text' test.html

or as we did earlier, get urls from a file, but this time `trim` unslightly whitespace from the output

    perl -Mojo -nlE 'say b(g($_)->dom->at("title")->text)->trim' sites

We can slurp the `sites` file itself, split the lines and ouput it as JSON.

    perl -Mojo -E 'print j({sites => b(f(shift)->slurp)->split("\n")})' sites

We can even `trim` and `sort` while we do it

    perl -Mojo -E 'print j({sites => b(f(shift)->slurp)->split("\n")->map("trim")->sort})' sites

### The Lite App

If all of that weren't enough for you, remember that your one-liner is also a Lite app.
This means that you get all of the Lite app keywords.
I like to show the Mojolicious error page, featuring the glorious Fail Raptor, to the uninitiated.
While I could find the image in the repo, just making a "fail app" is so much easier!

    perl -Mojo -E 'get "/" => sub { die }; app->start' daemon -m production

If you haven't seen him, you need to run that one-liner to see him for yourself!

You do still have to call `app->start` as ever, and the application gets called with commands, just like any application.
Call it with `daemon` and since we want to show the production version of the page, force it into production mode.

There is an even shorter way to declare a one-liner application too.
Since one-liners are likely to be used immediately, and routing conditions aren't so important, there is one ojo keyword to shorten things.
That keyword is `a`, whose name should cause you to think of Lite's [`any`](http://mojolicious.org/perldoc/Mojolicious/Lite#any) keyword.

It has a one important differences besides just the shorter name: it returns the application rather than the route instance, allowing you to chain the call to `start`.
Another handy trick is that, when using `ojo`, actions expose the controller instance as `$_` so you don't have to unpack the arguments to get access to it.
(If you have a recent enough Perl, you can also use signatures on your functions automagically too.)

    perl -Mojo -E 'a("/" => sub { $_->render(text => scalar localtime) })->start' get /

Since all the commands work, using the Lite app and the `get` command together can mean that you see the results of a request to your one-liner application right there on your terminal!

I use this functionality all the time to quickly demonstrate some concept; sometimes to others or sometimes to myself.
What happens if I set this stash parameter?
Will a route condition do what I expect?
Indeed the Mojolicious core team members often make one-liner applications to paste into IRC when we want to reproduce some bug or discuss some change.

### Benchmarking

And speaing of development, there is one more ojo function, and it is quite unlike the others.
The `n` function takes a block of code to run and optionally a number of times to run it and the function will output timing statistics over the runs.
The heavy lifting here is done by the Perl core [Benchmark](https://metacpan.org/pod/Benchmark) module.

Say the Mojolicious core team is considering a change to the very performance sensitive Mojo::DOM parser.
We can take a baseline and then make our changes and each time run something like

    perl -Ilib -Mojo -E 'my $body = g("html.spec.whatwg.org")->body; n { x $body } 10'

This fetches the rather large HTML document that defines HTML itself and then parses it 10 times.
The more runs, the more consistent your data should be since variations are averaged out.
Note especially how easily the fetching is excluded while what we care about is included.
On my laptop this gives the output.

    29.3775 wallclock secs (29.11 usr +  0.26 sys = 29.37 CPU) @  0.34/s (n=10)

Knowing that data taken with and without proposed changes we can have a better idea of the performance gains or impacts from that change.
While there is no magic in this function, the ease-of-use of the benchmarker means we are actually likely to use it, even for what may seem like small and insignificant changes.
This is a major reason for Mojolicious' consistently blazing speeds.

## Conclusion

Making `ojo` one-liners can be great to experiment with new concepts, demonstrate problems, fetch and work with data, and many other tasks.
You might use them in non-web one-liners that need JSON or Data::Dumper or perhaps MMojo::Collection for chaining.
(Speaking of chaining, for bonus points, check out [ojoBox](https://metacpan.org/pod/ojoBox) for [autoboxing Perl types](https://metacpan.org/pod/Mojo::Autobox), making even cooler chains!)

These one-liners are not going to be everyone's cup of tea.
If these don't seem like your's you can completely ignore them.

However, once you start using them, I think you'll find yourself using them often.


