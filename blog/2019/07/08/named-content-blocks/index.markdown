---
images:
  banner:
    alt: A pen hovering over a drafting blueprint
    data:
      attribution: |-
        Image by Ivan (https://www.stockvault.net/photo/143213/building-blueprint),
        modified by Doug Bell. Used under StockVault Non-Commercial license.
    src: /blog/2019/07/08/named-content-blocks/banner.jpg
author:
  name: Doug Bell
data:
  bio: preaction
  description: 'How to pass content to layouts and extend templates'
disable_content_template: 1
status: published
tags:
  - templates
  - rendering
title: Named Content Blocks
---

[Last week I went over how to configure and include
templates](/blog/2019/07/01/a-reusable-view-layer/). This
is a pretty standard procedural solution: My current template calls
another template. But what if I need to pass additional data to my
layout template? Perhaps in addition to the content in my template,
I also have some `<meta>` or `<script>` tags to include, or some
`<style>` specific to this page. This would involve somehow passing data
"up", or making the data available for the layout template to use.
[Mojolicious](http://mojolicious.org) provides a way to do this: [named
content
blocks](https://mojolicious.org/perldoc/Mojolicious/Guides/Rendering#Content-blocks).

---

## Content blocks

[Layout
templates](https://mojolicious.org/perldoc/Mojolicious/Guides/Rendering#Layouts)
are the most common way of re-using a template. Layout templates wrap
around the page's content and provide a common framing with header,
footer, navigation, metadata, and otherwise. So layout templates
necessarily get re-used quite a lot.

In addition to the main content, displayed with the `content` helper,
I can add other content blocks to my layout that templates can add to
using the `content_for` helper. Frequently this is used for putting
additional content like stylesheets or JavaScript in `<head>`:

    @@ layouts/default.html.ep
    <!DOCTYPE html>
    <head>
        <title><%= title %></title>
        %# Put `content_for 'head'` here
        %= content 'head'
    </head>
    <body>
        %= content
    </body>

    @@ jquery-datatable.html.ep
    %# Add sorting and searching to a table using the DataTables
    %# library: http://datatables.net
    % content_for head => begin
        %= stylesheet '//cdn.datatables.net/1.10.19/css/jquery.dataTables.min.css'
        %= javascript '//cdn.datatables.net/1.10.19/js/jquery.dataTables.min.js'
    % end
    %= include 'table', class => 'data-table'
    %= javascript begin
        $(document).ready( function () {
            $('.data-table').DataTable();
        } );
    % end

## Template Inheritance

Named content blocks can also be used to create additional layers of
templates. A generic template defines one or more named content section,
and then a template can extend the original by filling in those blocks.

Using [the `extends`
helper](https://mojolicious.org/perldoc/Mojolicious/Guides/Rendering#Template-inheritance)
I can build some simple pages with blocks to fill in (again, much like
a layout). Unlike a layout, extending templates always involves named
content blocks. The default content is reserved for the top-most layout.

For example, I can build a parent template that provides a two-column
layout:

    @@ page/two-column.html.ep
    %# This template provides content blocks named "left" and "right"
    %# for the left and right column, respectively
    <div style="display: flex">
        <div><%= content 'left' %></div>
        <div><%= content 'right' %></div>
    </div>

    @@ articles.html.ep
    % extends 'page/two-column';
    % layout 'default';
    % my $latest = $items->[0];
    % content_for left => begin
        <h1>Latest article: <%= $latest->{title} %></h1>
        <p><%== $latest->{html} %></p>
    % end
    % content_for right => begin
        <h1>Past Articles</h1>
        %= include 'table' => items => [ @{$items}[ 1..$#$items ] ]
    % end

I can also extend layouts to achieve the same result. This time I create
a new layout called 'two-column' which extends the 'default' layout and
is used by my articles template:

    @@ layouts/two-column.html.ep
    %# This layout provides content blocks named "left" and "right"
    %# for the left and right column, respectively
    % extends 'layouts/default';
    <div style="display: flex">
        <div><%= content 'left' %></div>
        <div><%= content 'right' %></div>
    </div>

    @@ articles.html.ep
    % layout 'two-column';
    % my $latest = $items->[0];
    % content_for left => begin
        <h1>Latest article: <%= $latest->{title} %></h1>
        <p><%== $latest->{html} %></p>
    % end
    % content_for right => begin
        <h1>Past Articles</h1>
        %= include 'table' => items => [ @{$items}[ 1..$#$items ] ]
    % end

The result is the same, so which method you use is a matter of
preference and convenience.

So, to maximize the reusability of your view layer, remember:

* Stash values can be used to configure templates
* Stash values are passed down to included templates (`include`)
* Includes can accept additional stash values visible only to the
  included template
* Named content blocks allow content to be passed up to parent templates
  (`extends`) or layout templates (`layout`)
* Create and append to named content blocks using `content_for 'name',
  ...`
* The main `content` helper is reserved for the upper-most layout
  template

With more robust templates, I can write less code and change my site
quickly and easily!
