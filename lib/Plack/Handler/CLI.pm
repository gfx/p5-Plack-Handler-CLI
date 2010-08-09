package Plack::Handler::CLI;

use 5.008_001;
use Mouse;

our $VERSION = '0.01';

use IO::Handle  ();
use Plack::Util ();

BEGIN {
    if(eval { require URI::Escape::XS }) {
        *_uri_escape = \&URI::Escape::XS::encodeURIComponent;
    }
    else {
        require URI::Escape;
        *_uri_escape = \&URI::Escape::uri_escape_utf8;
    }
}

my $CRLF = "\015\012";

has need_headers => (
    is      => 'ro',
    isa     => 'Bool',
    default => 1,
);

has stdin => (
    is      => 'ro',
    isa     => 'FileHandle',
    default => *STDIN,
);

has stdout => (
    is      => 'ro',
    isa     => 'FileHandle',
    default => *STDOUT,
);

has stderr => (
    is      => 'ro',
    isa     => 'FileHandle',
    default => *STDERR,
);

sub run {
    my($self, $app, @argv) = @_;

    my @params;
    while(defined(my $s = shift @argv)) {
        if($s =~ s/\A -- //xms) {
            my($name, $value) = split /=/, $s, 2;
            if(not defined $value) {
                $value = shift @argv;
                if(not defined $value) {
                    die "Arguments must be key-value pairs\n";
                }
            }
            push @params, join '=',
                _uri_escape($name) => _uri_escape($value);
        }
        else {
            unshift @argv, $s; # push back
            last;
        }
    }

    my $path_info = join '/', map { _uri_escape($_) } @argv;
    my $query     = join ';', @params;
    my $uri       = 'http://localhost/' . $path_info;
    $uri .= "?$query" if length($query);

    my %env = (
        # HTTP
        HTTP_COOKIE  => '', # TODO?
        HTTP_HOST    => 'localhost',

        # Client
        REQUEST_METHOD => 'GET',
        REQUEST_URI    => $uri,
        QUERY_STRING   => $query,
        PATH_INFO      => $path_info,
        SCRIPT_NAME    => '',

        # Server
        SERVER_PROTOCOL => 'HTTP/1.0',
        SERVER_PORT     => 0,
        SERVER_NAME     => 'localhost',
        SERVER_SOFTWARE => ref($self),

        # PSGI
        'psgi.version'      => [1,1],
        'psgi.url_scheme'   => 'http', # mock :)
        'psgi.input'        => $self->stdin,
        'psgi.errors'       => $self->stderr,
        'psgi.multithread'  => Plack::Util::FALSE,
        'psgi.multiprocess' => Plack::Util::TRUE,
        'psgi.run_once'     => Plack::Util::TRUE,
        'psgi.streaming'    => Plack::Util::FALSE,
        'psgi.nonblocking'  => Plack::Util::FALSE,

        %ENV, # override
    );

    my $res = Plack::Util::run_app($app, \%env);

    if (ref $res eq 'ARRAY') {
        $self->_handle_response($res);
    }
    elsif (ref $res eq 'CODE') {
        $res->(sub {
            $self->_handle_response($_[0]);
        });
    }
    else {
        die "Bad response $res";
    }
}

sub _handle_response {
    my ($self, $res) = @_;

    my $stdout = $self->stdout;

    $stdout->autoflush(1);

    if($self->need_headers) {
        my $hdrs = "Status: $res->[0]" . $CRLF;

        my $headers = $res->[1];
        while (my ($k, $v) = splice @$headers, 0, 2) {
            $hdrs .= "$k: $v" . $CRLF;
        }
        $hdrs .= $CRLF;

        print $stdout $hdrs;
    }

    my $cb     = sub { print $stdout @_ };
    my $body   = $res->[2];
    if (defined $body) {
        Plack::Util::foreach($body, $cb);
    }
    else {
        return Plack::Util::inline_object
            write => $cb,
            close => sub { };
    }
}

no Mouse;
__PACKAGE__->meta->make_immutable();
__END__

=head1 NAME

Plack::Handler::CLI - Command line interface for Plack

=head1 VERSION

This document describes Plack::Handler::CLI version 0.01.

=head1 SYNOPSIS

    #!perl -w
    # a cat(1) implementation on PSGI/CLI
    use strict;
    use Plack::Handler::CLI;
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

    my $handler = Plack::Handler::CLI->new(need_headers => 0);
    $handler->run(\&main, @ARGV);

=head1 DESCRIPTION

Plack::Handler::CLI is a PSGI handler which provides a command line interface
for PSGI applications.

=head1 INTERFACE

=head2 B<< Plack::Handler::CLI->new(%options) : CLI >>

=head2 B<< $cli->run(\&app, @argv) : Void >>

=head1 DEPENDENCIES

Perl 5.8.1 or later.

=head1 BUGS

All complex software has bugs lurking in it, and this module is no
exception. If you find a bug please either email me, or add the bug
to cpan-RT.

=head1 SEE ALSO

L<perl>

=head1 AUTHOR

Goro Fuji (gfx) E<lt>gfuji(at)cpan.orgE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2010, Goro Fuji (gfx). All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. See L<perlartistic> for details.

=cut
