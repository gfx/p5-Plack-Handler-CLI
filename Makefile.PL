use strict;
use warnings;
use inc::Module::Install;

all_from 'lib/Plack/Handler/CLI.pm';

requires 'Plack' => 0.99;
requires 'Any::Moose';
requires 'URI::Escape';
requires 'IO::Handle';

recommends 'URI::Escape::XS' => 0.07;

test_requires 'Test::More' => 0.88; # done_testing()

tests_recursive;
author_tests 'xt';

auto_set_repository() if -d '.git';

clean_files qw(
    Plack-Handler-CLI-* *.stackdump
    cover_db
    nytprof
    *.out
);

WriteAll(check_nmake => 0);
