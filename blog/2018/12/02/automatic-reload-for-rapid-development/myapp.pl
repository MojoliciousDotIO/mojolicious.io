
# Author's note: As of Mojolicious::Plugin::AutoReload version 0.004,
# you no longer need to use the auto_reload helper, which removes the
# need for a layout here.

use v5.28;
use Mojolicious::Lite;

plugin 'AutoReload';
get '/' => 'index';

app->start;
__DATA__

@@ layouts/default.html.ep
%= auto_reload
%= content

@@ index.html.ep
% layout 'default';
<h1>Hello, World!</h1>
