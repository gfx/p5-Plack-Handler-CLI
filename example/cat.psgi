#!perl -w

use strict;
use URI::Escape qw(uri_unescape);

sub err {
    my(@msg) = @_;
    return [
        500,
        [ 'Content-Type' => 'text/plain' ],
        \@msg,
    ];
}

sub main {
    my($env) = @_;

    my @files = split '/', $env->{PATH_INFO};

    local $/;

    my @contents;
    if(@files) {
        foreach my $file(@files) {
            my $f = uri_unescape($file);
            open my $fh, '<', $f
                or return err("Cannot open '$f': $!\n");

            push @contents, readline($fh);
        }
    }
    else {
        push @contents, readline($env->{'psgi.input'});
    }

    return [
        200,
        [ 'Content-Type' => 'text/plain'],
        \@contents,
    ];
}

if(caller) {
    return \&main;
}
else {
    require Plack::Handler::CLI;
    my $handler = Plack::Handler::CLI->new(need_headers => 0);
    $handler->run(\&main, @ARGV);
}
