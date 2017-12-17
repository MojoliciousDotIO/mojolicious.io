---
title: 'Day 17: The Wishlist App'
tags:
    - advent
    - rendering
    - templates
    - example
author: Joel Berger
images:
  banner:
    src: '/static/xmas_tree.jpg'
    alt: 'Living room, Christmas tree, and presents'
    data:
      attribution: |-
        [Image](https://pxhere.com/en/photo/1056078) in the Public Domain.
data:
  bio: jberger
  description: Introducing template concepts with a group wishlist app.
---

For today's article, I really wanted to demonstrate concepts using a practical example appliation.
It is possible I let the exaxmple get away from me!

In today's article I indend to show how to use template composition techniques to produce a wishlist app.
We will cover [layouts](http://mojolicious.org/perldoc/Mojolicious/Guides/Rendering#Layouts), [partial templates](http://mojolicious.org/perldoc/Mojolicious/Guides/Rendering#Partial-templates), [content blocks](http://mojolicious.org/perldoc/Mojolicious/Guides/Rendering#Content-blocks).

The data model is admittedly rough, however I think my plan will be to make that a feature and not a bug.
Today we will example concepts mostly relating to the templates, then in tomorrows post I will migrate the model from using the simplistic persistence of [DBM::Deep](https://metacpan.org/pod/DBM::Deep) that it uses now to [Mojo::SQLite](https://metacpan.org/pod/Mojo::SQLite).
---

At that point I hope to put the application into a repository of its own.
In the meantime however, you can see the application in the source for this [article](https://github.com/jberger/mojolicious.io/tree/master/blog/2017/12/17/day-17-the-wishlist-app/wishlist).
To run it, you will need to install two additional modules, DBM::Deep and [LinkEmbedder](https://metacpan.org/pod/LinkEmbedder).

    $ cpanm Mojolicious DBM::Deep LinkEmbedder

## Layouts

Most web sites have a defined style and layout between pages.
A header bar, a sidebar for navigation, a footer.
The content of each might change slightly between pages but the similarity is remarkable.

Do the developers copy and paste this logic between pages?
Certainly not!

The first tool of the trade is a layout template.
This is a template that will contain the results of rendering some inner template.
This will usually contain the outermost tags, like `<html>`, `<head>`, and `<body>`.
They will likely also establish any structure that exists on all of the pages, like navigation and sidebar sections.

Let's look at the layout that our wishlist application

%= highlight Perl => include -raw => 'wishlist/templates/layouts/default.html.ep'
<small>templates/layouts/default.html.ep</small>

Here you can see that I include the [Boostrap](https://getbootstrap.com/docs/3.3).
You can also see a few bits of templating.
The first is that I use a `<title>` tag with the content `<%%= title %>`.
This is a shortcut helper to get the value of the [`title` key of the stash](http://mojolicious.org/perldoc/Mojolicious/Plugin/DefaultHelpers#title).
Well shall see in a moment how this value gets set.

The remaining template portions are each getting the contents of named content buffers.
While I establish five such inclusions, I will only actually use three: `head`, `sidebar` and the default unnamed buffer.

With the possible exception of `sidebar`, buffers like these are useful in almost all application layouts.
The `head` and `end` buffers let you add contents to those locations, especially useful to include extra stylesheets and javascript respectively.
The `footer` buffer would allow additions to be placed at the end of the body but before any javascript inclusions.

It is interesting to note that if we rendered this template directly, those buffers would all be empty.
Therefore the content put into them must come from someplace else.

## A Primary Template

I mentioned before the the layout was like a container that would hold some inner content.
Let's consider the simplest such case.

When a user first accesses the site, the will be greeted with a login page.

![Screen shot of the login page](login.png)

%= highlight Perl => include -raw => 'wishlist/templates/login.html.ep'
<small>templates/login.html.ep</small>

Immediately you can see that there are a few statements at the top.
These set the layout to our default one above and set the title key for the page.
It is important to realize that this page is rendered **first** before any layout is rendered.

After the template renders, Mojolicious will notice that a layout key was set and as a result it will render the layout with the result of the primary template rendering available as the default content buffer.
As we saw before, that content will be placed inside the `#main` section of the page.
However, in the process of rendering the primary template, the title was also set.
Since the layout is rendered afterwards, this value is now available to set the `<title>` tag at the top of the page.

While this may seem obvious, it is actually quite remarkable.
If the page had been rendered all in order, the value would not have been set in time to be used there at the top of the page.
Knowing the rendering order is therefore very important to understanding the rendering process.

## The Application

I've gone about as far as is practical without showing you, dear reader, what the actual application script looks like.

%= highlight Perl => include -raw => 'wishlist/wishlist.pl'
<small>wishlist.pl</small>

### Helpers

I won't go into great detail today as much of the model logic will be replaced in tomorrow's article.
Still, in broad strokes, we define a persistent hash structure, the keys of which are users and the values are hashes of information.

Once you login, your name is stored in the [`session`](http://mojolicious.org/perldoc/Mojolicious/Controller#session) and in this hash.
While I haven't followed the [best practices for sessions from yesterday](https://mojolicious.io/blog/2017/12/16/day-16-the-secret-life-of-sessions/), you certainly could and should if this data mattered to you.
But also, no authentication is attempted, this is a personal wishlist app, hopefully none of your friends are going to play the Grinch on you!

The `user` helper is especially clever.
You can pass it a name for lookup, if that isn't provided then a name is looked for in the stash and the session in turn.
In this way you are looking up a specific user, the user being referenced by the page, or the logged in user.

There is also a helper that uses [LinkEmbedder](https://metacpan.org/pod/LinkEmbedder) to look up information about a link and return it.
That is used when a user pastes a url that they want to add to their list.
LinkEmbedder will fetch that page and scrape it for metadata using several open protocols and falling back onto heuristics if possible.
It will then return the information and an short HTML representation of that resource.

### Routes

The routes are mostly self explanatory, even if their code is not.
The `/login` and `/logout` handlers, for example.

There are two routes for `/add` a `GET` and a `POST`.
`GET` requests are safe and will not change data, in this case the request triggers LinkEmbedder to fetch the information which is then displayed.

#### Adding Items

![Screen shot of the add items page](add.png)

%= highlight Perl => include -raw => 'wishlist/templates/add.html.ep'
<small>templates/add.html.ep</small>

Beyond being interesting to see how the link is used to embed HTML into the page, we also see our first uses of named content buffers via [`content_for`](http://mojolicious.org/perldoc/Mojolicious/Plugin/DefaultHelpers#content_for).
These add styling that is specific to the page into the `<head>` tag and inject a panel into the sidebar.
Once this page renders, again before the layout is rendered, the content of that section is available in the `sidebar` buffer.

The result is a tiny form that contains the data to be stored if the user wants to add it to their wishlist.
Because the resulting main page might be quite large, and I want the user to have easy access to decide if they want to add the item, I've placed it in the left hand column.
Perhaps this is bad UX, but for educational purposes, it shows how these buffers can be used.

We also see our first example of [`include`](http://mojolicious.org/perldoc/Mojolicious/Plugin/DefaultHelpers#include).
When called, the renderer immediately renders the template specified and returns the result.

%= highlight Perl => include -raw => 'wishlist/templates/partial/log_out.html.ep'
<small>templates/partial/log_out.html.ep</small>

While our application doesn't do so, calls to `include` can take arguments that they see in the stash.
They can also add content to named content buffers, just like the primary template can.
All our logout "partial" template does is generate a nicely formatted link to the log out route.
The name partial indicates that, like layout, this template is not intended to be rendered on its own.
The utility of making this its own template is that many pages can use that same partial to render that same log out link.

#### The List

There are two routes that might render a wishlist.
The `/` route either allows the user to log in or if they are, displays their list.
There is a also a `/list/:name` route that renders any user's list by name.

![Screen shot of the list page](list.png)

%= highlight Perl => include -raw => 'wishlist/templates/list.html.ep'
<small>templates/list.html.ep</small>

The template itself is the most complex in the application.
It includes three partial templates and places all of their content into the `sidebar` buffer.
It then looks up the user by virtue of that clever `user` helper and loops over their items.

The items are placed into a table, displaying the title and link to the item.
The third column's contents depends if the list is being shown is the user's own page or not.

If not, they are likely considering buying one of these gifts for their friend or family member.
They are given the option to mark an item as purchased or not.
This is done by calling the `/update` method, the result of which will change the item's status and re-render the page.o

If it is their own page, they don't want to have the surprise spoiled see that someone has bought their present.
So we don't show the purchase state.
However perhaps they have changed their mind and no longer want that item.
In that case, they are presented with a remove button which calls to the `/remove` route.

Finally let's look at those last two partials.
There is a sidebar list of the users, so you can see everyone's list.

%= highlight Perl => include -raw => 'wishlist/templates/partial/user_list.html.ep'
<small>templates/partial/user_list.html.ep</small>

And an input box that allows the user to submit a link to add to their wishlist.

%= highlight Perl => include -raw => 'wishlist/templates/partial/add_url.html.ep'
<small>templates/partial/add_url.html.ep</small>

This form calls back to the add template we saw earlier.

## Moving On

As I said before, I'm looking forward to making a more complete application with proper storage for tomorrow.
That said, the code shown today already works and is quite useful, even for as small as it is!

