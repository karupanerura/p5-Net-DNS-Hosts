#!perl -w
use strict;
use warnings;
use utf8;

use Net::DNS::Hosts (
    'www.example.yyy.xxx' => '127.0.0.1'
);

use Test::More;
use Test::TCP;

use IO::Socket::INET;

my $server = Test::TCP->new(
    code => sub {
        my $port = shift;
        my $s = IO::Socket::INET->new(
            LocalAddr => '127.0.0.1',
            LocalPort => $port,
            Proto     => 'tcp',
            Listen    => 10,
            (($^O eq 'MSWin32') ? () : (ReuseAddr => 1)),
        ) or die $!;
        $s->listen or die $!;

        while (my $c = $s->accept) {
            my $line = $c->getline;
            if ($line) {
                is $line, "ping\n", 'ping';
                $c->print("pong\n");
                $c->close;
            }
        }

        $s->close;
    },
);

my $c = IO::Socket::INET->new(
    PeerAddr => 'www.example.yyy.xxx',
    PeerPort => $server->port,
    Proto    => "tcp"
) or die $!;

$c->print("ping\n");
is $c->getline, "pong\n", 'pong';
$c->close;

undef $server;
done_testing;
