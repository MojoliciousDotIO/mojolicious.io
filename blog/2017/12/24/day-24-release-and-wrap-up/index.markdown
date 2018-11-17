---
title: 'Day 24: Release and Wrap-Up'
tags:
    - advent
    - wishlist
author: Joel Berger
images:
  banner:
    src: '/blog/2017/12/24/day-24-release-and-wrap-up/tree_unfocused.jpg'
    alt: 'Out of focus image of lit Christmas tree'
    data:
      attribution: |-
        [Image](https://www.pexels.com/photo/art-blurred-blurry-bokeh-383646/) by Tim Mossholder, in the Public Domain
data:
  bio: jberger
  description: The Wishlist app is released to CPAN and a wrap-up for the advent calendar.
---

Over the course of this advent calendar, we have discussed the [Wishlist example application](https://mojolicious.io/blog/tag/wishlist/) several times.
We used it to motivate discussions about [templates](/blog/2017/12/17/day-17-the-wishlist-app/), [models](/blog/2017/12/18/day-18-the-wishlist-model/), [installable apps](/blog/2017/12/19/day-19-make-your-app-installable/), and [testing](/blog/2017/12/20/day-20-practical-testing/).
In this post I want to use it somewhat differently.
I would like to motivate you, the reader, into action in a few different ways.
---

### The Double-Edged Sword

The internet has made so many amazing things possible.
Old friendships are kept alive.
Personal photographs can be stored forever and shared with friends.
Rare items can be discussed, found, and purchased.
News can spread as fast as fingers can type them.

But for all this ease and convenience there is a price.
Personal data is being taken, mined, and sold.
People are buying products that require internet connections but whose manufacturers will drop support before the hardware fails.
Statements you make and pictures you share will live on on the internet forever, even if you change.

### Fighting Back

I would never say that the bad outweighs the good, but I do wish people would be more intentional about these types of choices online.
Yet that almost cannot happen until they have alternatives that they control.
To that end I have been trying in the past year to start to take control of my digital life where possible.
I have deployed [NextCloud](https://nextcloud.com/) on a private server to keep my files and share with people I choose.
I wrote an application called [CarPark](https://github.com/jberger/CarPark) to control my garage door via a RaspberryPi and even spoke about it at [The Perl Conference](https://www.youtube.com/watch?v=aJc5yYONBBc); it isn't on CPAN yet but I hope it will be soon.

And that brings us to the [Wishlist](https://github.com/jberger/Wishlist) application.
Several sites, some large and some small, offer similar services: tracking your wishlists and aiding gift buying, all for free.
However, this too must also come at a cost.

In this article I'm announcing that after adding a few tweaks around user registration, I have now released the Wishlist application to [CPAN](https://metacpan.org/pod/Wishlist).
I hope you can use it to keep a slightly tighter grasp on your digital footprint without sacrificing utility.

You can deploy it on a VPS, like [Linode](https://www.linode.com/) or [Scaleway](https://www.scaleway.com/).
You could even use it on that old desktop computer in your home office as long as you are careful about network security.
Speaking of which, [Let's Encrypt](https://letsencrypt.org/) finally makes SSL practical for personal users, try [certbot](https://certbot.eff.org) or my [plugin](https://metacpan.org/pod/Mojolicious::Plugin::ACME) to get started.
Once you have one service running, it will become progressively easier to host more and more of your own personal cloud applications.

I'd love to see if Wishlist and CarPark and other such applications could put you back in the driver's seat for your digital lives.

### A Call to Action

That said they aren't nearly good enough.
They need more tests, more documentation, more functionality.
It would be great if they could support plugins and theming.
Wishlist is reasonably easy to deploy but it could always be easier via tools like Docker etc.
CarPark is much more difficult because of the hardware aspect and could use some love in this area too.

I know that other people have similar notions.
If you are interested in working on such projects, or others, and if you have the skills to help me, we could make some really useful tools for everyone.
I'd love to have your help.

And if not, I hope you'll enjoy what they are or what they will be.

## Wrapping Up

I have had so much fun producing this Advent Calendar for you.
I hope you have enjoyed it too.
Thank you so much for reading along with me!
Please refer back to it as needed and share it with friends and coworkers if and when it can help others learn and use Mojolicious.

I want to thank the guest authors who have contributed posts

* Doug Bell - preaction ([twitter](https://twitter.com/preaction)/[CPAN](https://metacpan.org/author/PREACTION)/[GitHub](https://github.com/preaction)/[web](http://preaction.me/))
* Ed J - mohawk ([CPAN](https://metacpan.org/author/ETJ)/[GitHub](https://github.com/mohawk2))
* CandyAngel ([twitter](https://twitter.com/CandyAngel_Nay)/[CPAN](https://metacpan.org/author/EJUNGLE)/[GitHub](https://github.com/CandyAngel))
* Jan Henning Thorsen - batman ([twitter](https://twitter.com/jhthorsen)/[CPAN](https://metacpan.org/author/JHTHORSEN)/[GitHub](https://github.com/jhthorsen)/[web](http://thorsen.pm/))

Without their contributions, this series would have just been me rambling.
Thank you so very much!

I do hope to do this again next year, if you are interested in contributing or just want to see it happen be sure to let me know.
This site will continue, keep an eye on it for new Mojolicious content, even if it doesn't hit the pages daily.

## Getting Help

As always I want to be sure to remind people where to get help.
I'm on IRC almost all the time, you can find us in #mojo on [irc.perl.org](http://irc.perl.org), you can even join by [clicking here](https://chat.mibbit.com/?channel=%23mojo&server=irc.perl.org).
We have a mailing list at <https://groups.google.com/forum/#!forum/mojolicious>.
All of the documentation is online at <http://mojolicious.org/perldoc>.

## Happy holidays from the Mojolicious community!


