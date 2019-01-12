---
status: published
title: Writing Extensible Controllers
disable_content_template: 1
tags:
    - development
    - controller
    - DBIx::Class
author: Doug Bell
images:
  banner:
    src: '/blog/2019/01/28/writing-extensible-controllers/banner.jpg'
    alt: 'Clouds stacked inside clouds, mixed with gears. Original artwork by Doug Bell'
    data:
      attribution: |-
        Original artwork by Doug Bell, released under CC-BY-SA 4.0.
data:
  bio: preaction
  description: 'Learn how to write controllers that can be subclassed'
---

Once I have a [reusable
controller](/blog/2019/01/21/writing-reusable-controllers), how do
I extend it? Object-oriented programming gives me a couple ways of
extending a controller through code: Inheritance and composition. But,
we need to write our controller so that it's easy to inherit or compose.

# Don't Render, Stash

First, this means we shouldn't call [the `render`
method](https://mojolicious.org/perldoc/Mojolicious/Controller#render)
ourselves (unless we have a good reason, but we'll get to that later).
The `render` method can only ever be called once, so we should only call
it after we've gathered all the data we want.

    # This method cannot easily be used by a subclass, since it explicitly
    # calls render()
    sub list {
        my ( $c ) = @_;
        my $resultset_class = $c->stash( 'resultset' );
        my $resultset = $c->schema->resultset( $resultset_class );
        $c->render(
            resultset => $resultset,
        );
    }

So, to make sure I don't call `render` too early, and to make sure
subclasses can use the data from my superclass, I instead put all the
data directly in to the stash with the [`stash()`
method](https://mojolicious.org/perldoc/Mojolicious/Controller#stash).

Remember that `$c->render( %stash );` is the same as `$c->stash( %stash
); $c->render();`. And, if we never call `render()` ourselves, that's
okay, as Mojolicious will call it for us (unless we call
[`render_later`](https://mojolicious.org/perldoc/Mojolicious/Controller#render_later),
which we won't).

    # This method can be used by a subclass, which can get
    # the ResultSet object out of the stash
    sub list {
        my ( $c ) = @_;
        my $resultset_class = $c->stash( 'resultset' );
        my $resultset = $c->schema->resultset( $resultset_class );
        $c->stash(
            resultset => $resultset,
        );
    }

# Return True to Continue

Since there are times where we do want to render a response in the
superclass (in the case of a 404 not found error, for example), we need
to be able to tell our caller that we did.

    # How can I tell that a 404 error is already rendered?
    sub get {
        my ( $c ) = @_;
        my $resultset_class = $c->stash( 'resultset' );
        my $id = $c->stash( 'id' );
        my $resultset = $c->schema->resultset( $resultset_class );
        my $row = $resultset->find( $id );
        if ( !$row ) {
            $c->reply->not_found();
        }
        else {
            $c->stash(
                row => $row,
            );
        }
    }

We can do so with a simple convention: Return true to continue the
dispatch, and return false to stop. This is the same as [`under` route
callbacks](https://mojolicious.org/perldoc/Mojolicious/Guides/Routing#Under).
Since we're returning, we can also simplify the code a little bit to
remove the need for the `else` block:

    sub get {
        my ( $c ) = @_;
        my $resultset_class = $c->stash( 'resultset' );
        my $id = $c->stash( 'id' );
        my $resultset = $c->schema->resultset( $resultset_class );
        my $row = $resultset->find( $id );
        if ( !$row ) {
            $c->reply->not_found();
            # stop dispatch
            return;
        }
        # continue dispatch
        return $c->stash(
            row => $row,
        );
    }

# Inheritance

With our superclass controller ready, I can now write a subclass. I have
a section of my site that's dedicated to user content, so I'll filter
the `list` ResultSet to only those results for the current user, and
make sure that `get` only returns content for the current user
(displaying a "not found" response if it's the wrong user).

Remember our superclass method will return true if we're okay to
continue working. So, we need to check the return value.

    package My::Controller::DBIC::UserContent;
    use Mojo::Base 'My::Controller::DBIC';
    sub list {
        my ( $c ) = @_;
        $c->SUPER::list || return;
        my $rs = $c->stash( 'resultset' );
        $rs = $rs->search( { user_id => $c->current_user->id } );
        $c->stash( resultset => $rs );
    }
    sub get {
        my ( $c ) = @_;
        $c->SUPER::get || return;
        my $row = $c->stash( 'row' );
        if ( $row->user_id ne $c->current_user->id ) {
            $c->reply->not_found;
            return;
        }
    }

With reusable controllers, we can greatly reduce the amount of code we
need to write. Less code means fewer bugs and more time spent writing
new features and doing useful things!

