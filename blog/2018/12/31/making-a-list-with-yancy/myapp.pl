
use v5.28;
use Mojolicious::Lite;
use Mojo::SQLite;

# Connect to the SQLite database and load our schema from the
# '@@ migrations' section, below
my $db = Mojo::SQLite->new( 'sqlite:thelist.db' );
$db->auto_migrate(1)->migrations->from_data( 'main' );

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

# Set the delivered state of a list row
post '/deliver/:id', {
    controller => 'yancy',
    action => 'set',
    collection => 'the_list',
    properties => [qw( is_delivered )],
    forward_to => 'the_list.list',
}, 'the_list.deliver';

# Start the app. Must be the last line of the script.
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
%= javascript begin
    // Automatically submit the form when an input changes
    $( 'form input' ).change( function ( e ) {
        $(this).parents("form").submit();
    } );
% end

