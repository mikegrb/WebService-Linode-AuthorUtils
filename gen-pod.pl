#!/usr/bin/env perl

use strict;
use warnings;

# validation file as command line argument of via stdin
my $validation_source = join '', <>;

my $verbose_validation;
eval $validation_source; # don't eval untrusted stuff, m'kay
my %validation = %$verbose_validation;

print "=for autogen\n\n";

foreach my $group ( qw{ account avail domain domain_resource linode
  linode_config linode_disk linode_ip linode_job stackscript
  nodeblancer nodebalancer_config nodebalancer_node user image })
{

  foreach my $method ( sort keys %{ $validation{$group} } ) {
    print "=head3 ${group}_${method}\n\n";
    print $validation{$group}{$method}{description} . "\n\n" if $validation{$group}{$method}{description};

    if ( exists $validation{$group}{$method}{required} && @{ $validation{$group}{$method}{required} } ) {
      print "Required Parameters:\n\n";
      print "=over 4\n\n";
      print generate_item($_) for ( sort @{ $validation{$group}{$method}{required} } );
      print "=back\n\n";
    }

    if ( exists $validation{$group}{$method}{optional} && @{ $validation{$group}{$method}{optional} } ) {
      print "Optional Parameters:\n\n";
      print "=over 4\n\n";
      print generate_item($_) for ( sort @{ $validation{$group}{$method}{optional} } );
      print "=back\n\n";
    }

  }
}

print "=for endautogen\n";

sub generate_item {
  my $item_info = shift;
  my $result    = "=item * $item_info->[0]";
  $result .= ' - ' . $item_info->[1] if $item_info->[1];
  $result .= "\n\n";
  return $result;
}
