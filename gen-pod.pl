#!/usr/bin/env perl

use strict;
use warnings;

use File::Slurp;

my $validation_file = shift || die "Usage: $0 filename";

my $ref;
eval '$ref = ' . read_file($validation_file);
my %validation = %$ref;

foreach my $group (qw{avail domain domain_resource linode linode_config linode_disk linode_ip linode_job stackscript nodeblancer nodebalancer_config  nodebalancer_node  user}) {
    # print "=head2 $group\n\n";
    foreach my $method (keys %{$validation{$group}}) {
        print "=head3 ${group}_${method}\n\n";
        if (@{$validation{$group}{$method}[0]}) {
            print "Required Parameters:\n\n";
            print "=over 4\n\n";
            print "=item * $_\n\n" for @{$validation{$group}{$method}[0]};
            print "=back\n\n";
        }
        if (@{$validation{$group}{$method}[1]}) {
            print "Optional Parameters:\n\n";
            print "=over 4\n\n";
            print "=item * $_\n\n" for @{$validation{$group}{$method}[1]};
            print "=back\n\n";
        }
    }
}
