---
title: 'Day 13: More About Roles'
tags:
    - advent
    - roles
author: Joel Berger
images:
  banner:
    src: '/static/amsterdam_hats.jpg'
    alt: 'Pile of hats'
    data:
      attribution: |-
        <a href="https://commons.wikimedia.org/w/index.php?curid=15179120">Image</a> © Jorge Royan&nbsp;/&nbsp;<a rel="nofollow" class="external free" href="http://www.royan.com.ar">http://www.royan.com.ar</a>, <a href="https://creativecommons.org/licenses/by-sa/3.0" title="Creative Commons Attribution-Share Alike 3.0">CC BY-SA 3.0</a>.
data:
  bio: jberger
  description: Investigating Mojo::Base's recently-added role support.
---
Before we get ahead of ourselves, what are roles?
Briefly stated, roles enable composing functionality (usually methods) into a class without without implying a change of inheritence.
Said another way, roles let you specify what a class does without changing what it is.
For a better description, check out Toby Inkster's article [Horizontal Reuse: An Alternative to Inheritance](http://radar.oreilly.com/2014/01/horizontal-reuse-an-alternative-to-inheritance.html).

An important utility of roles is that you can easily use more than one role at the same time in the same consuming class.
With inheritance, especially of third-party functionality, you have to choose one set of extensions to utilize.
This is because the author of the subclass establishes the inheritance.
In roles, the user determines which roles to compose into the base class.

[Yesterday](/blog/2017/12/12/day-12-more-than-a-base-class) I ended the discussion of [Mojo::Base](http://mojolicious.org/perldoc/Mojo/Base) before discussing the roles support.
Added in several installments between Mojolicious versions [7.40](https://metacpan.org/release/SRI/Mojolicious-7.40) and [7.55](https://metacpan.org/release/SRI/Mojolicious-7.55), this role support is one of the most recently added features in the ecosystem (along with [promises](http://mojolicious.org/perldoc/Mojo/Promise), which will be covered in an upcoming article).
The role handling comes from [Role::Tiny](https://metacpan.org/pod/Role::Tiny) which is an optional dependency in Mojolicious, but is required in order to use the functionality that I will describe.
---

This is not to say that roles couldn't be or weren't used in Mojolicious before then, only that Mojo::Base didn't include any special handling to make it user-friendly.
Prior to the functionality being formally available from Mojo::Base, a few roles were available for Mojo stack classes on CPAN.
To my knowledge they all used Role::Tiny, but they had to roll their own composition mechanisms, presenting some barrier to use.

## Creating Roles

A role itself looks like a class at first glance.
It has a package name and probably has methods.
Rather than using the `-base` flag or specifying a parent class, a role uses the `-role` flag.
Once again, an optional `-signatures` flag is allowed too.

Let's look at a (contrived) example.
Say we want to make a role that finds all the tags matching elements in a [Mojo::DOM](http://mojolicious.org/perldoc/Mojo/DOM) based on a selector stored in an attribute.

    package Mojo::DOM::Role::FindCustom;
    use Mojo::Base -role;

    requires 'find';

    has custom_selector => 'a';

    sub find_custom {
      my $self = shift;
      return $self->find($self->custom_selector);
    }

This example shows three interesting features.
First is that even though it is not a class, the package still gets Mojo::Base's [has](http://mojolicious.org/perldoc/Mojo/Base#has) keyword, used to make accessors for attributes.
Second is that a new keyword, `requires`, has been added, coming from [Role::Tiny](https://metacpan.org/pod/Role::Tiny#requires).
This keyword tells the role that it can only be composed into a class that provides a `find` keyword.
Consider the new `find_custom` method, since it uses `find` if the class it is composed into didn't provide that method our new method couldn't behave as expected.

Indeed several keywords are imported from Role::Tiny including `with` to compose other roles and several method modifiers coming from [Class::Method::Modifiers](https://metacpan.org/pod/Class::Method::Modifiers) (which is an optional dependency only required if used).
While I won't discuss these in depth, if you need to change how a method from a consuming class works by adding behavior before and/or after that method, check out method modifiers.

The third thing you might notice is the name of the package that I chose.
The only thing that limits what classes the role can be consumed by is the `requires` keyword.
Howver clearly this role is intended to work with functionality provided by Mojo::DOM and so this name is a good choice.

## Composing Roles

Now that we know how to create a role, how is it used?
Well, let's continue with the prior example.
To use the role, we use the [`with_roles`](http://mojolicious.org/perldoc/Mojo/Base#with_roles) method provided by Mojo::Base.

This method is slightly different when used on class versus when it is used on an object.
When used as a class method, the return value is a new semi-anonymous class that composes all the given roles.

    my $class = Mojo::DOM->with_roles('Mojo::DOM::Role::FindCustom');
    my $dom = $class->new('<html><a href="http://mojolicious.org">Mojolicious</a></html>');
    my $anchors = $dom->find_custom;

While this is conceptually a new class which inherits from the consuming class, this is really an implementation detail because of how Perl does namespacing and packages.
You are encouraged to think of this new class as just the old one with more behaviors.
Usually however, the returned class is just used to instantiate an object anyway, so we can skip storing it.

    my $dom = Mojo::DOM->with_roles('Mojo::DOM::Role::FindCustom')->new(
      '<html><a href="http://mojolicious.org">Mojolicious</a></html>'
    );
    my $anchors = $dom->find_custom;

That looks less awkward, but now that's a lot to type before instantiating.
Remember that choice of package name for the role, turns out when you compose a role into a class whose name starts with `<CLASS>::Role::` there is a shortcut you can use.
Just replace all of that common prefix with a `+` sign!

    my $dom = Mojo::DOM->with_roles('+FindCustom')->new(
      '<html><a href="http://mojolicious.org">Mojolicious</a></html>'
    );
    my $anchors = $dom->find_custom;

And finally that looks quite nice.
It should be noted that this shortcut usage is different from some other plugin systems on CPAN, some of which use `+` to indicate a literal (ie non-shortened) class name.
We feel that you should be explicit about requesting a non-literal class name and so we made this choice.

Now sometimes you don't instantiate the class, sometimes you have an instance given to you.
For example say the Mojo::DOM document came from a [Mojo::UserAgent](http://mojolicious.org/perldoc/Mojo/UserAgent) request.
In this case you can still use `with_roles`.
What happens in this case is that a little magic happens in the background to add the functionality to the instance.

    my $dom = $ua
      ->get('http://mojolicious.org')
      ->res
      ->dom
      ->with_roles('+FindCustom');
    my $anchors = $dom->find_custom;

Finally, when you are checking if a class consumes a role, you don't check with `->isa` as if it were inheritance.
Rather you check with `->does`.
You cannot use the shortened forms of roles when using this check however.

    if ($dom->does('Mojo::DOM::Role::FindCustom')) {
      $dom->find_custom->each(sub{ say });
    }

## Roles on CPAN

The first part of the ecosystem to embrace roles was testing.
Given the interface of [Test::Mojo](http://mojolicious.org/perldoc/Test/Mojo), adding additional test methods isn't as easy as is generally true of other testers in the [Test::More](https://metacpan.org/pod/Test::More) landscape.
Roles fill that gap nicely, and therefore such roles predated Mojo::Base's own role handling and even inspired adding it to the core.

As I've mentioned [earlier in this series](/blog/2017/12/09/day-9-the-best-way-to-test), [Test::Mojo::Role::Debug](https://metacpan.org/pod/Test::Mojo::Role::Debug) adds methods to run a callback on failed tests.
[Test::Mojo::Role::TestDeep](https://metacpan.org/pod/Test::Mojo::Role::TestDeep) lets you test responses with the comparison functions from [Test::Deep](https://metacpan.org/pod/Test::Deep).
[Test::Mojo::Role::PSGI](https://metacpan.org/pod/Test::Mojo::Role::PSGI) lets you use Test::Mojo with non-Mojolicious web frameworks!
You can even use them all together.

    use Mojo::Base -strict;
    use Test::More;
    use Test::Mojo;
    use Test::Deep; # for its keywords

    my $t = Test::Mojo
      ->with_roles('+PSGI', '+TestDeep', '+Debug')
      ->new('/path/to/app.psgi');

    $t->get_ok('/')
      ->text_deeply(
        'nav a',
        [qw( Home Blog Projects About Contact )],
        'nav link text matches site section titles',
      )->d(sub{ diag $t->tx->req->body });

This example loads a hypothetical psgi application from the filesystem, tests it for text elements and if that test fails dumps the response body to the console.

There are three modules (only two on CPAN so far) that let you run javascript on pages via external processes.
[Test::Mojo::Role::Phantom](https://metacpan.org/pod/Test::Mojo::Role::Phantom) and [Test::Mojo::Role::Selenium](https://metacpan.org/pod/Test::Mojo::Role::Selenium) use [PhantomJS](http://phantomjs.org/) and [Selenium](http://www.seleniumhq.org/) respectively.
PhantomJS is abandoned however so [Test::Mojo::Role::Chrome](https://github.com/jberger/Mojo-Chrome) is in development on my Github and will replace the PhantomJS role.

Note that several of these modules depend on a module named [Test::Mojo::WithRoles](https://metacpan.org/pod/Test::Mojo::WithRoles) which is essentially obsolete at this point.
It can be safely ignored and authors can remove it from their module's dependencies when convenient.

Apart from testing, other roles include

  - [Mojo::Role::Log::Clearable](https://metacpan.org/pod/Mojo::Log::Role::Clearable) allowing the Mojo::Log to cleanly change paths
  - [Mojo::DOM::Role::PrettyPrinter](https://metacpan.org/pod/Mojo::DOM::Role::PrettyPrinter) pretty prints Mojo::DOM documents
  - [Mojo::Collection::Role::UtilsBy](https://metacpan.org/pod/Mojo::Collection::Role::UtilsBy) adds [List::UtilsBy](https://metacpan.org/pod/List::UtilsBy) methods to [Mojo::Collection](http://mojolicious.org/perldoc/Mojo/Collection)
  - [Mojo::UserAgent::CookieJar::Role::Persistent](https://metacpan.org/pod/distribution/Mojo-UserAgent-CookieJar-Role-Persistent/lib/Mojo/UserAgent/CookieJar/Role/Persistent.pod) can store cookies from Mojo::UserAgent requests persistently for use between runs/processes

... as well as others.
And the list is sure to grow now that Mojo::Base can natively compose these roles.

