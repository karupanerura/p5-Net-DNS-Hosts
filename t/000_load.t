#!perl -w
use strict;
use Test::More tests => 1;

BEGIN {
    use_ok 'Net::DNS::Hosts';
}

diag "Testing Net::DNS::Hosts/$Net::DNS::Hosts::VERSION";
