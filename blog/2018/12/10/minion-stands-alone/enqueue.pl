#!/usr/bin/env perl
use Minion;
my $minion = Minion->new(
    SQLite => 'sqlite:minion.db', # The same database as the worker
);
$minion->enqueue(
    check_url => ['http://mojolicious.org'],
);
