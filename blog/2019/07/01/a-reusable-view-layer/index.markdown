---
images:
  banner:
    alt: A brick wall embossed with a cloud image
    data:
      attribution: |-
        Image by Doug Bell. Brick background by Homero Chapa
        (https://www.stockvault.net/user/profile/3608)
        https://www.stockvault.net/photo/117550/brick-texture, used
        under StockVault Non-Commercial license.
    src: /blog/2019/07/01/a-reusable-view-layer/banner.jpg
author:
  name: Doug Bell
data:
  bio: preaction
  description: 'How to make generic, reusable templates for Mojolicious'
disable_content_template: 1
status: published
tags:
  - templates
  - rendering
title: A Reusable View Layer
---

In a well-designed
[Model-View-Controller](https://en.wikipedia.org/wiki/Model–view–controller)
web application, most of the code and the development time will be in
the model layer (which contains the [business
logic](https://en.wikipedia.org/wiki/Business_logic)). The other two
layers are meant to be as re-usable as possible. Earlier this year
I discussed how to build a [reusable controller for
Mojolicious](https://mojolicious.io/blog/2019/01/21/writing-reusable-controllers/)
and how to [build an inheritable controller to increase code
re-use](https://mojolicious.io/blog/2019/01/28/writing-extensible-controllers/).
Now, I'd like to talk about how the [Mojolicious web
framework](https://mojolicious.org) provides ways to reuse, combine, and
compose the view code: [the
stash](https://mojolicious.org/perldoc/Mojolicious/Guides/Tutorial#Stash-and-templates),
[includes](https://mojolicious.org/perldoc/Mojolicious/Guides/Rendering#Partial-templates),
[layout
templates](https://mojolicious.org/perldoc/Mojolicious/Guides/Rendering#Layouts),
and [named content
blocks](https://mojolicious.org/perldoc/Mojolicious/Guides/Rendering#Content-blocks).

This week, I'll talk about how to make reusable, configurable,
composable templates.

---

## Configuration with the Stash

The stash is generally used to provide data for the templates to render,
but it can also be used to configure templates. If I have to render
a bunch of arrays of hashes in tables, I can make one template to do it.
This template could have additional configuration for which keys to
display in which order and whether or not to show column headers, like
so:

    @@ table.html.ep
    %# By default, show all the keys in the hash (by getting the keys of the
    %# first item)
    % my $properties = stash()->{properties} || [ sort keys %{ $items->[0] } ];
    %# Show the table heading by default, but allow disabling
    % my $thead = exists stash()->{thead} ? stash()->{thead} : 1;
    %# Allow adding classes to the table
    % my $class = stash('class') ? sprintf q{ class="%s"}, stash('class') : '';
    <table<%= $class %>>
        % if ( $thead ) {
            <thead>
                % for my $key ( @$properties ) {
                    <th><%= $key %></th>
                % }
            </thead>
        % }
        <tbody>
            % for my $item ( @$items ) {
                <tr>
                    <% for my $key ( @$properties ) { %>
                        <td><%= $item->{ $key } %></td>
                    % }
                </tr>
            % }
        </tbody>
    </table>

Then I can configure my template from my route:

    get '/events' => 'yancy#list',
        schema => 'event',
        template => 'table',
        properties => [qw( title start_date end_date )];

    get '/articles' => 'yancy#list',
        schema => 'article',
        template => 'table',
        thead => 0;

When my template is rendered, it gets the current value of the `thead`
stash. I could even override that stash value in my route handler, so
I can enable/disable parts of the template based on the user's
preferences:

    get '/articles' => sub {
        my ( $c ) = @_;
        # Send ?show_header=1 to show the table header
        if ( $c->param( 'show_header' ) ) {
            $c->stash( thead => 1 );
        }
        return $c->render( 'table' );
    };

## Includes

Any template can import another template. Like the calling template, the
imported template has access to the entire [request
stash](https://mojolicious.io/blog/2017/12/02/day-2-the-stash/). But,
I can also pass in additional stash values that are only seen by the
imported template.

So, I could create a page that shows my most recent article as a big
banner, and the rest of my articles as a table (using my table template
from above):

    @@ articles.html.ep
    % my $latest = $items->[0];
    <h1>Latest article: <%= $latest->{title} %></h1>
    <p><%== $latest->{html} %></p>

    <h1>Past Articles</h1>
    %= include 'table' => items => [ @{$items}[ 1..$#$items ] ]

Then, when I use my `articles` template in my route, I can configure the
`table` template's columns and header using the `properties` stash key
(just like above).

    get '/articles' => 'yancy#list',
        schema => 'article',
        template => 'table',
        properties => [qw( title published_date )],
        thead => 0;

With these techniques I can create one template that satisfies multiple
uses! If I add CSS classes to my template configuration, I can even make
each table look completely different using a little bit of CSS. The cost
here is extra complexity in the templates: The templates become more
like a subroutine in a program and less like annotated HTML, so you'll
have to find the right balance for your application and your team.

Next week, I'll discuss named content blocks, layout templates, and
template inheritance. Until then!
