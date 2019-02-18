#!/usr/bin/env perl
use Mojolicious::Lite;
plugin 'Config';
plugin 'DBIC';

# List notes
get '/' => {
    controller => 'DBIC',
    action => 'list',
    resultset => 'Notes',
    template => 'notes/list',
} => 'notes.list';

# Create a new note
any [qw( GET POST )], '/notes/new' => {
    controller => 'DBIC',
    action => 'set',
    resultset => 'Notes',
    template => 'notes/edit', # Same form used to edit existing notes
    forward_to => 'notes.get',
} => 'notes.create';

# Get a note
get '/notes/:id' => {
    controller => 'DBIC',
    action => 'get',
    resultset => 'Notes',
    template => 'notes/get',
} => 'notes.get';

# Edit a note
any [qw( GET POST )], '/notes/:id/edit' => {
    controller => 'DBIC',
    action => 'set',
    resultset => 'Notes',
    template => 'notes/edit', # Show the edit form for GET requests
    forward_to => 'notes.get', # View the note after saving
} => 'notes.edit';

# Delete a note (and confirm before deleting)
any [qw( GET POST )], '/notes/:id/delete' => {
    controller => 'DBIC',
    action => 'delete',
    resultset => 'Notes',
    template => 'notes/delete', # Show a confirm page for GET requests
    forward_to => 'notes.list', # View the list after deleting
} => 'notes.delete';

app->start;
__DATA__
@@ notes/list.html.ep
<h1>Notes</h1>
<p>[<%= link_to Create => 'notes.create' %>]</p>
<ul>
    % for my $row ( $resultset->all ) {
        <li><%=
            link_to $row->title,
                'notes.get', { id => $row->id }
        %></li>
    % }
</ul>

@@ notes/get.html.ep
% title $row->title;
%= link_to 'Back' => 'notes.list'
<h1><%= $row->title %></h1>
%== $row->description
<p>
    [<%= link_to 'Edit' => 'notes.edit' %>]
    [<%= link_to 'Delete' => 'notes.delete' %>]
</p>

@@ notes/edit.html.ep
%= stylesheet begin
    label, input[type=text], textarea {
        display: block;
        width: 50vw;
    }
    textarea {
        height: 30vh;
    }
% end
%= form_for current_route, method => 'POST', begin
    %= csrf_field
    %= label_for 'title' => 'Title'
    %= text_field 'title'
    %= label_for 'description' => 'Body'
    %= text_area 'description'
    %= submit_button
% end

@@ notes/delete.html.ep
%= stylesheet begin
    form {
        display: inline-block;
    }
% end
<h1>Delete <%= $row->title %>?</h1>
%= link_to 'Cancel' => 'notes.get'
%= csrf_button_to 'Delete' => 'notes.delete', method => 'POST'
