#!perl -w

use strict;
use URI::Escape qw(uri_unescape);
use Plack::Request;

our $VERSION = '1.0';

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
    my $req  = Plack::Request->new($env);
    my $res  = $req->new_response(200);

    if($req->param('version')) {
        $res->body("cat.psgi version $VERSION on $env->{SERVER_SOFTWARE}\n");
    }
    elsif($req->param('help')) {
        $res->body("cat.psgi [--version] [--help] files...\n");
    }
    else {
        my @files = split '/', $req->path_info;

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
        $res->body(\@contents);
    }

    return $res->finalize();
}

if(caller) {
    return \&main;
}
else {
    require Plack::Handler::CLI;
    my $handler = Plack::Handler::CLI->new(need_headers => 0);
    $handler->run(\&main, @ARGV);
}
