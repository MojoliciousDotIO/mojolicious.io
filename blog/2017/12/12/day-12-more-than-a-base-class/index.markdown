---
title: 'Day 12: More Than a Base Class'
tags:
    - advent
    - fluent
    - roles
author: Joel Berger
images:
  banner:
    src: '/static/1280px-GG-ftpoint-bridge-2.jpg'
    alt: 'Golden Gate Bridge viewed and Fort Point'
    data:
      attribution: |-
        <a href="https://commons.wikimedia.org/w/index.php?curid=1592390">Image</a> by <a href="https://en.wikipedia.org/wiki/User:Mactographer" title="en:User:Mactographer">David Ball</a> - Original work, <a href="http://creativecommons.org/licenses/by/2.5" title="Creative Commons Attribution 2.5">CC BY 2.5</a>.
data:
  bio: jberger
  description: Mojo::Base is a streamlined base class with lots of extra goodies.
---

Through this series, you've seen the module [Mojo::Base](http://mojolicious.org/perldoc/Mojo/Base) referenced several times, though briefly and mostly in passing.
It shouldn't be taken lightly however, it packs a lot of punch in one import statement!
Nearly every file in the Mojolicious distribution uses it, either directly or indirectly.
So what is it?

First it imports several handy pragma that make your code safer and some features that are useful.
Second, it can be a base class to the current package, or establish a parent class, or even define a role.
Let's see how it does it.
---

## Importing Pragma and Functionality

Most of the authors in the modern Perl commmunity recommend that all Perl code use the [strict](https://metacpan.org/pod/strict) and [warnings](https://metacpan.org/pod/warnings) pragmas.
Like many of the major Perl object frameworks, [Moose](https://metacpan.org/pod/Moose) and [Moo](https://metacpan.org/pod/Moo) included, Mojo::Base feels these are important enough that it imports them for you.
Unlike those others, it goes further.

Since the modern web is trending towards UTF-8 encoding, the [utf8](https://metacpan.org/pod/utf8) pragma is loaded; this enables you to use UTF-8 encoded characters right in your script.
Mojolicious does much of your web-facing encoding for you so this **almost** means you don't have to think about character encoding at all!

And because Mojolicious itself requires Perl 5.10, it also enables all of the [features](https://metacpan.org/pod/feature) that came with that version.
This includes [handy functionality](https://www.effectiveperlprogramming.com/2009/12/perl-5-10-new-features/) like the `state` and `say` keywords as well as the defined-or operator `//`.
Finally it imports IO::Handle so that all of your handles behave as objects (if you don't know what that means or why, don't worry about it).

If this is the only thing you want from Mojo::Base, perhaps in a script or a test file, all you do is pass the `-strict` flag

    use Mojo::Base -strict;

and you get everything listed above.
Otherwise, if you use the class or roles functionality then these imports come along for free.

### Experimental Signatures

In the past few years, Perl has added [signatures](https://metacpan.org/pod/perlsub#Signatures) to subroutines as an [experimental](https://metacpan.org/pod/perlexperiment) feature.
With Mojolicious' emphasis on non-blocking functionality, and the frequent use of callbacks that that entails, the Mojo community has been especially anxious to use them.
However since these are still experimental, and are still subject to change, when Mojo::Base recently added this functionality, it was decided that it should be an additional opt-in flag.
Using it, suddenly

    use Mojo::Base -strict;
    $ua->get('/url' => sub {
      my ($ua, $tx) = @_;
      ...
    });

becomes

    use Mojo::Base -strict, -signatures;
    $ua->get('/url' => sub ($ua, $tx) { ... });

## Establishing a Class

Now for the functionality that the name implies, setting up a class.
The Mojo stack modules make LOTS of objects in the course of performing their tasks, from making or handling HTTP requests to processing HTML documents, object creation time is key.
Therefore the primary feature of Mojo::Base classes is speed!

The object system is spartan even when compared to Moo.
You get a hash-based object with declarative read/write lazy accessors and a constructor.
When considering Moose vs Moo, you trade lesser-used features for a noticable performance gain.
Likewise when you consider Mojo::Base vs Moo, you strip down futher, this time to the bare essentials, but again get a performance gain.

Now if you need more functionality, you are more than welcome to use Moo or other object systems in your applications (though the Mojo internals will of course continue to use Mojo::Base).
That said, much of the real world usage of Moo is very similar to Mojo::Base: lazy accessor generation; this might be all you need.

To declare a new class with Mojo::Base, one with no other parent classes, you use the `-base` flag.

    package My::Class;
    use Mojo::Base -base;

This adds the `has` keyword to your package which, as we will see soon, declares the class's attributes.
This will cause your new class to inherit from Mojo::Base, meaning it will get the methods from Mojo::Base as well, which you will also see.
Of course, the module also acquires the pragmas and functionality listed above and may add `-signatures` if desired.

If you want your class to derive from some other parent class, you can pass that name rather than `-base`.

    package My::Class::Subclass;
    use Mojo::Base 'My::Class';

You saw this usage quite a bit in the Full app example on [Day 6](/blog/2017/12/06/day-6-adding-your-own-commands).
Mojo::Base only supports single-inheritance because we don't want to encourage bad practices.
If you know why you might want to use multipe-inheritance, you probably know how to get around this limitation as well.

### Attributes and Constructor

Mojo::Base implements a class method which can be used to add attributes to the class (called `attr`).
While this is necessary for the implementation, this isn't the preferred usage.

The `has` keyword, added by the import above, gives us that nice declarative style that Perl users are familiar with from Moose and Moo.
The usage is different from those, owing to the limited choices available in declaration.
`has` takes a name or an array reference of name of the attribute(s) to declare.
It then optionally takes either a simple (non-reference) scalar default value or a callback to be used as a lazy builder.
When the lazy builder is called, it gets as an argument the instance itself.
That's it, clean and simple.

    package My::Class;
    use Mojo::Base -base;

    # attribute whose default is undef
    has 'foo';

    # two attribtues whose defaults are both 0
    has ['min', 'max'] => 0;

    # attribute that defaults to a new, empty hash reference
    has 'data' => sub { {} };

    # attribute that uses its existing state to build
    has 'double_max' => sub {
      my $self = shift;
      return 2 * $self->max;
    };

The callbacks are always lazy, meaning if the value of that attribute hasn't been established, either via the constructor or via a setter, then the default is used or the builder is run.

The default constructor (`new`), inherited from Mojo::Base, takes a hash reference or key-value pairs and uses them as initialization for the defined attributes.

    my $obj = My::Class->new(foo => 'bar', max => 10);
    my $obj = My::Class->new({foo => 'bar', max => 10}); # same

Note that there is nothing to prevent you from passing data that isn't for a defined attribute (ie, the constructor isn't [strict](https://metacpan.org/pod/MooX::StrictConstructor)).
Nor is there anything that declares a required attribute, though you can easily make one

    has 'username' => sub { die 'username is required' };

### Accessor Methods

A read/write accessor method is installed into the class for each declared attribute.
However, have one major difference from other common Perl object systems.
While the getters return the value as expected,

    my $foo = $self->foo;
    my $value = $self->data->{key};

the setters (ie, when passing an argument to change the stored value) return the object itself, not the value.
THe reason for this is to create what is called a [fluent interface](https://en.wikipedia.org/wiki/Fluent_interface), more commonly known as chaining.

    my $ua = Mojo::UserAgent->new->max_redirects(10)->inactivity_timeout(1200);

Many of the Mojo modules support a fluent interface with their methods, so this this nicely consistent.

    my $title = Mojo::UserAgent->new
      ->max_redirects(10)
      ->get('http://mojolicious.org')
      ->res
      ->dom
      ->at('title')
      ->text;

Frequent users of such Javascript libraries as [jQuery](https://jquery.com/) or [lodash](https://lodash.com/) will find this type of chaining very familiar.
Once you get the hang of this style it is [hard to let go of it](https://metacpan.org/pod/MooX::ChainedAttributes).
In a future post I intent to discuss several of the fluent interfaces that the Mojo stack provides.

### The tap Method

Speaking of fluent interfaces, Mojo::Base provides an interesting method called `tap`, which is (in comp-sci terms) a [K-combinator](https://en.wikipedia.org/wiki/SKI_combinator_calculus).
This is a more advanced feature, but it allows you to insert a non-chainable call into a method chain without breaking it.
The first argument is the method or callback to be called, any additional arguments are passed to the tapped subroutine.
Within that subroutine the invocant is available as the first argument (before any passed arguments) or as `$_`.

If you had a proxy that you needed to setup before running the previous example, you could do

    my $title = Mojo::UserAgent->new
      ->max_redirects(10)
      ->tap(sub { $_->proxy->detect })
      ->get('http://mojolicious.org')
      ->res
      ->dom
      ->at('title')
      ->text;

Perhaps this is too much adherence to fluent interfaces but as you progress, getting a nice long chain can really feel like an accomplishment!
If you'd rather pass on this method, that's fine too.

## Roles

While Mojo::Base has always tacitly supported roles via external modules, just recently has it started to offer explicit functionality in this area.
That said, I have lots ot say on the matter, so if you'll permit me, I'm going to keep you in suspense until [tomorrow](/blog/2017/12/13/day-13-more-about-roles).

