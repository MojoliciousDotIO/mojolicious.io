---
title: Making A List with Yancy
disable_content_template: 1
tags:
    - advent
    - yancy
    - example
author: Doug Bell
images:
  banner:
    src: '/blog/2018/12/06/making-a-list-with-yancy/banner.jpg'
    alt: 'Santa making a list'
    data:
      attribution: |-
        [Banner image](https://pxhere.com/en/photo/1263707) CC0 Public Domain
data:
  bio: preaction
  description: "Santa's list building just got easier!"
---

In these modern times, with billions of people in the world, Santa needs a
modern system to keep track of his naughty/nice list. Lucky for Santa, modern
Perl has a modern web framework, [Mojolicious](http://mojolicious.org).

# Step 1: Build The List

First, we need a database schema. Santa only really needs to know if someone
has been naughty or nice, so our schema is pretty simple. We'll start our
[Mojolicious::Lite](https://mojolicious.org/perldoc/Mojolicious/Guides/Tutorial)
app by connecting to a [SQLite](http://sqlite.org) database using
[Mojo::SQLite](https://metacpan.org/pod/Mojo::SQLite) and loading our database
schema from the [__DATA__ section of our
script](https://perldoc.perl.org/perldata.html#Special-Literals) using
[Mojo::SQLite migrations](https://metacpan.org/pod/Mojo::SQLite::Migrations):

    use v5.28;
    use Mojolicious::Lite;
    use Mojo::SQLite;

    # Connect to the SQLite database and load our schema from the
    # '@@ migrations' section, below
    my $db = Mojo::SQLite->new( 'sqlite:thelist.db' );
    $db->auto_migrate(1)->migrations->from_data( 'main' );

    # Start the app. Must be the last code of the script.
    app->start;

    __DATA__
    @@ migrations
    -- 1 up
    CREATE TABLE the_list (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name VARCHAR NOT NULL,
        address VARCHAR NOT NULL,
        is_nice BOOLEAN DEFAULT FALSE,
        is_delivered BOOLEAN DEFAULT FALSE
    );

With our schema created, we can add
[Yancy](http://metacpan.org/pod/Yancy). Yancy is a simple CMS for
editing content and streamlining data-driven website development. We'll
tell Yancy to read our database schema to configure itself, but we'll
also give it a few hints to make editing content easier.

    # Configure Yancy
    plugin Yancy => {
        backend => { sqlite => $db },
        # Read the schema configuration from the database
        read_schema => 1,
        collections => {
            the_list => {
                # Show these columns in the Yancy editor
                'x-list-columns' => [qw( name address is_nice is_delivered )],
                properties => {
                    # `id` is auto-increment, so hide it when creating rows
                    id => { readOnly => 1 },
                },
            },
        },
    };

If we run our app (`perl myapp.pl daemon`) and go to
`http://127.0.0.1:3000/yancy`, we can edit the list data.

![Browser window showing a form to edit a list
entry](editor-form-screenshot.png)

Now Santa's data entry elves get to work entering the data for all the
people in the universe!

![Browser window showing the list of data entered
in](editor-list-screenshot.png)

# Step 2: View The List

With our data entry Neptunians working hard, we can build a way to view
the list. With four arms, they can enter data twice as fast!

![Three Futurama Neptunians in front of baby strollers containing
one-eared rabbit dolls](neptunians.png)

Yancy comes with controllers that let us easily list our data just by
configuring a route and creating a template to render. First we
configure the route to use [Yancy::Controller::Yancy `list`
method](https://metacpan.org/pod/Yancy::Controller::Yancy#list):

    # Display the naughty rows of the list
    get '/', {
        controller => 'yancy',
        action => 'list',
        template => 'the_list',
        collection => 'the_list',
        filter => {
            is_nice => 0,
        },
    }, 'the_list.list';

Now we build our template. Yancy comes with a [Bootstrap
4](http://getbootstrap.com) we can use to make a pretty list of names
and addresses.

    @@ layouts/default.html.ep
    <head>
        <script src="/yancy/jquery.js"></script>
        <link rel="stylesheet" href="/yancy/bootstrap.css">
    </head>
    <body>
        <main class="container">
            %= content
        </main>
    </body>

    @@ the_list.html.ep
    % layout 'default';
    <h1>Naughty List</h1>
    <ul class="list-group">
        % for my $item ( @$items ) {
            <li class="list-group-item d-flex justify-content-between">
                <div>
                    %= $item->{name}
                    <br/>
                    %= $item->{address}
                </div>
                % end
            </li>
        % }
    </ul>

# Step 3: Complete Delivery

Santa's a busy robot, and all that ordnance is expensive. Once he's done
a delivery, he needs to mark it as done so he can move on to all the
other deserving people.

![Santa Robot (from Futurama) writing on his list with a quill
pen](editing-list.png)

Stopping to check people off manually really slows down the murder and
mayhem.

Yancy makes it easy to update the data, this time with the ["set" action
in Yancy::Controller::Yancy](https://metacpan.org/pod/Yancy::Controller::Yancy#set):

    # Set the delivered state of a list row
    post '/deliver/:id', {
        controller => 'yancy',
        action => 'set',
        collection => 'the_list',
        properties => [qw( is_delivered )],
        forward_to => 'the_list.list',
    }, 'the_list.deliver';

With the route configured, we need to add a form to our template. We'll
use [the `form_for` helper from
Mojolicious](https://mojolicious.org/perldoc/Mojolicious/Plugin/TagHelpers#form_for).
The form will display a yes/no toggle button for every row. Yancy is
secure by default, so we need to make sure that our form contains the
[CSRF token](https://mojolicious.org/perldoc/Mojolicious/Guides/Rendering#Cross-site-request-forgery)
(using [the `csrf_field` helper](https://mojolicious.org/perldoc/Mojolicious/Plugin/TagHelpers#csrf_field))
to prevent cross-site requests.

    @@ the_list.html.ep
    % layout 'default';
    <h1>Naughty List</h1>
    <ul class="list-group">
        % for my $item ( @$items ) {
            <li class="list-group-item d-flex justify-content-between">
                <div>
                    %= $item->{name}
                    <br/>
                    %= $item->{address}
                </div>
                %= form_for 'the_list.deliver', $item, begin
                    Delivered:
                    %= csrf_field
                    % my $delivered = $item->{is_delivered};
                    <div class="btn-group btn-group-toggle">
                        <label class="btn btn-xs <%= $delivered ? 'btn-success active' : 'btn-outline-success' %>">
                            <input type="radio" name="is_delivered" value="true" <%== $delivered ? 'checked' : '' %>> Yes
                        </label>
                        <label class="btn btn-xs <%= $delivered ? 'btn-outline-danger' : 'btn-danger active' %>">
                            <input type="radio" name="is_delivered" value="false" <%== $delivered ? '' : 'checked' %>> No
                        </label>
                    </div>
                % end
            </li>
        % }
    </ul>

We'll add some jQuery at the end (using [the `javascript`
helper](https://mojolicious.org/perldoc/Mojolicious/Plugin/TagHelpers#javascript))
to automatically submit the form when the value is changed.

    %= javascript begin
        // Automatically submit the form when an input changes
        $( 'form input' ).change( function ( e ) {
            $(this).parents("form").submit();
        } );
    % end

Now our webapp looks like this:

![A browser window showing the completed webapp. A set of rows with name
and address on the left, and a Delivered button with Yes and No options
on the right.  Some rows have the No button checked, others the Yes
button](finished-screenshot.png)

We can view our entire list, and check off the ones who we've delivered to already!
[View the entire app here](myapp.pl).

![Santa Robot in his sleigh with burning buildings in the foreground and
background](success.png)

Another successful Xmas, powered by [Mojolicious](http://mojolicious.org)!
