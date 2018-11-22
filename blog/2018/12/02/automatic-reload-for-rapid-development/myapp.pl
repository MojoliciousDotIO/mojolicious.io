
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
