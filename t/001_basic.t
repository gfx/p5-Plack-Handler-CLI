#!perl -w

use strict;
use Test::More;

use Plack::Handler::CLI;
use Plack::Request;

sub hello {
    my($env) = @_;
    my $req = Plack::Request->new($env);

    my $lang = $req->param('lang');
    return [
        200,
        [ 'Content-Type' => 'text/plain' ],
        [ "Hello, $lang world!" ],
   ];
}

my $s = '';
my $out;
open $out, '>', \$s;
my $cli = Plack::Handler::CLI->new(stdout => $out);

$cli->run(\&hello, '--lang' => 'PSGI/CLI');
like $s, qr/Status: \s+ 200/xmsi, 'status';
like $s, qr{Hello, PSGI/CLI world!}, 'content';

open $out, '>', \$s;
$cli->run(\&hello, '--lang=Foo');
like $s, qr/Status: \s+ 200/xmsi, 'status';
like $s, qr{Hello, Foo world!}, 'content';

$cli = Plack::Handler::CLI->new(
    stdout       => $out,
    need_headers => 0,
);

open $out, '>', \$s;
$cli->run(sub {
    my $req = Plack::Request->new(@_);

    is $req->path_info, 'a/b/c', 'path_info';
    is $req->uri, 'http://localhost/a/b/c?foo=bar';
    is $req->param('foo'), 'bar';

    return [
        200,
        ['Content-Type' => 'text/plain'],
        ['Hello, world!'],
   ];
}, '--foo' => 'bar', 'a', 'b', 'c');

unlike $s, qr/Status: \s+ 200/xmsi, 'need_headers => 0';
is $s, 'Hello, world!';

done_testing;
