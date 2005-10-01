#!/usr/bin/env perl
BEGIN {
    # add current source dir to the include-path
    # we need this for make distcheck
   (my $srcdir = $0) =~ s#/[^/]+$#/#;
   unshift @INC, $srcdir;
}

use strict;
use IO::Socket;
use Test::More tests => 9;
use LightyTest;

my $tf = LightyTest->new();
my $t;
    
ok($tf->start_proc == 0, "Starting lighttpd") or die();

$t->{REQUEST}  = ( <<EOF
GET /server-status HTTP/1.0
EOF
 );
$t->{RESPONSE} = [ { 'HTTP-Protocol' => 'HTTP/1.0', 'HTTP-Status' => 401 } ];
ok($tf->handle_http($t) == 0, 'Missing Auth-token');

$t->{REQUEST}  = ( <<EOF
GET /server-status HTTP/1.0
Authorization: Basic amFuOmphb
EOF
 );
$t->{RESPONSE} = [ { 'HTTP-Protocol' => 'HTTP/1.0', 'HTTP-Status' => 401 } ];
ok($tf->handle_http($t) == 0, 'Basic-Auth: Wrong Auth-token');

$t->{REQUEST}  = ( <<EOF
GET /server-config HTTP/1.0
Authorization: Basic amFuOmphbg==
EOF
 );
$t->{RESPONSE} = [ { 'HTTP-Protocol' => 'HTTP/1.0', 'HTTP-Status' => 200 } ];
ok($tf->handle_http($t) == 0, 'Basic-Auth: Valid Auth-token - plain');

$t->{REQUEST}  = ( <<EOF
GET /server-config HTTP/1.0
Host: auth-htpasswd.example.org
Authorization: Basic ZGVzOmRlcw==
EOF
 );
$t->{RESPONSE} = [ { 'HTTP-Protocol' => 'HTTP/1.0', 'HTTP-Status' => 200 } ];
ok($tf->handle_http($t) == 0, 'Basic-Auth: Valid Auth-token - htpasswd (des)');

SKIP: {
	skip "no md5 for crypt under cygwin", 1 if $^O eq 'cygwin';
$t->{REQUEST}  = ( <<EOF
GET /server-config HTTP/1.0
Host: auth-htpasswd.example.org
Authorization: Basic bWQ1Om1kNQ==
EOF
 );
$t->{RESPONSE} = [ { 'HTTP-Protocol' => 'HTTP/1.0', 'HTTP-Status' => 200 } ];
ok($tf->handle_http($t) == 0, 'Basic-Auth: Valid Auth-token - htpasswd (md5)');
}

$t->{REQUEST}  = ( <<EOF
GET /server-config HTTP/1.0
Authorization: Basic bWQ1Om1kNA==
EOF
 );
$t->{RESPONSE} = [ { 'HTTP-Protocol' => 'HTTP/1.0', 'HTTP-Status' => 401 } ];
ok($tf->handle_http($t) == 0, 'Basic-Auth: Valid Auth-token');

## this should not crash
$t->{REQUEST}  = ( <<EOF
GET /server-status HTTP/1.0
User-Agent: Wget/1.9.1
Authorization: Digest username="jan", realm="jan", nonce="9a5428ccc05b086a08d918e73b01fc6f",
                uri="/server-status", response="ea5f7d9a30b8b762f9610ccb87dea74f"
EOF
 );
$t->{RESPONSE} = [ { 'HTTP-Protocol' => 'HTTP/1.0', 'HTTP-Status' => 401 } ];
ok($tf->handle_http($t) == 0, 'Digest-Auth: missing qop, no crash');


ok($tf->stop_proc == 0, "Stopping lighttpd");

