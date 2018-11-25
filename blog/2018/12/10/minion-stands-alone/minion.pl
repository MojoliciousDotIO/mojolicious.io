#!/usr/bin/env perl

use v5.28;
use Mojolicious::Lite;
use experimental qw( signatures );
use Time::HiRes qw( time );

plugin Minion => {
    SQLite => 'sqlite:' . app->home->child('minion.db'),
};

app->minion->add_task(
    check_url => sub( $job, $url ) {
        my $start = time;
        my $tx = $job->app->ua->head( $url );
        my $elapsed = time - $start;
        $job->app->log->info(
            sprintf 'Fetching %s took %.3f seconds', $url, $elapsed
        );
        # If there's an error loading the web page, fail the job
        if ( $tx->error ) {
            $job->app->log->error(
                sprintf 'Error loading URL (%s): %s (%s)',
                    $url, @{ $tx->error }{qw( code message )},
            );
            return $job->fail(
                sprintf '%s: %s', @{ $tx->error }{qw( code message )}
            );
        }
        $job->finish( $elapsed );
    },
);

app->start;
