package Net::DNS::Hosts;
use 5.008_001;
use strict;
use warnings;
use utf8;

our $VERSION = '0.01';

use Socket ();

sub import {
    my $class = shift;
    $class->set_super_inet_aton( *Socket::inet_aton{CODE} );
    $class->disable_override;
    {
        no warnings 'redefine';
        *Socket::inet_aton = sub {
            $class->inet_aton->(@_);
        };
    }
}

my $SUPER_inet_aton;
sub set_super_inet_aton { $SUPER_inet_aton = $_[1] };
sub super_inet_aton     { $SUPER_inet_aton };

my $inet_aton;
sub set_inet_aton { $inet_aton = $_[1] };
sub inet_aton     { $inet_aton };

my %HOSTS;
sub reset_hosts {  %HOSTS = () }
sub hosts       { \%HOSTS }

sub scope {
    my $class = shift;

    $class->reset_hosts;
    $class->register_host(@_);
    $class->enable_override;
    return Net::DNS::Hosts::Guard->new(sub {
        $class->reset_hosts;
        $class->disable_override;
    });
}

sub register_host {
    my $class = shift;
    my %hosts = @_;

    for my $host (keys %hosts) {
        $class->hosts->{$host} = $class->super_inet_aton->($hosts{$host});
    }
}

sub registered_peer_addr {
    my ($class, $host) = @_;

    return unless exists $class->hosts->{$host};
    return $class->hosts->{$host};
}

sub enable_override {
    my $class = shift;
    $class->set_inet_aton(
        sub {
            return $class->registered_peer_addr(@_) || $class->super_inet_aton->(@_);
        }
    );
}

sub disable_override {
    my $class = shift;
    $class->set_inet_aton(
        sub {
            return $class->super_inet_aton->(@_);
        }
    );
}

package # for no index
    Net::DNS::Hosts::Guard;
use strict;
use warnings;
use utf8;

sub new {
    my($class, $code) = @_;

    return bless +{
        code => $code
    } => $class;
}

sub fire {
    shift->{code}->();
}

sub DESTROY {
    shift->fire();
}

1;
__END__

=head1 NAME

Net::DNS::Hosts - Perl extention to do something

=head1 VERSION

This document describes Net::DNS::Hosts version 0.01.

=head1 SYNOPSIS

    use Net::DNS::Hosts;
    use LWP::UserAgent;

    my $scope = Net::DNS::Hosts->scope(
        'www.cpan.org' => '127.0.0.1'
    );

    # override request hosts with peer addr defined above
    my $ua  = LWP::UserAgent->new;
    my $res = $ua->get("http://www.cpan.org/");
    print $res->content; # is same as "http://127.0.0.1/" content

=head1 DESCRIPTION

# TODO

=head1 INTERFACE

=head2 Functions

=head3 C<< hello() >>

# TODO

=head1 DEPENDENCIES

Perl 5.8.1 or later.

=head1 BUGS

All complex software has bugs lurking in it, and this module is no
exception. If you find a bug please either email me, or add the bug
to cpan-RT.

=head1 SEE ALSO

L<perl>

=head1 AUTHOR

Kenta Sato E<lt>karupa@cpan.orgE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2012, Kenta Sato. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
