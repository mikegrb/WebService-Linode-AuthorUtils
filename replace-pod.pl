#!/usr/bin/env perl

use strict;
use warnings;
use autodie;

# pod fragment filename as command line argument or via stdin
my $pod_fragment = join '', <>;

my $path = '../WebService-Linode/lib/WebService/Linode.pm';

open( my $old_fh, '<', $path );
open( my $new_fh, '>', $path . '.new' );

my $fragment_added = 0;
while ( defined( my $line = <$old_fh> ) ) {
  if ( ( $line =~ /^=for autogen$/ ) .. ( $line =~ /^=for endautogen$/ ) ) {
    print $new_fh $pod_fragment unless $fragment_added++;
  }
  else {
    print $new_fh $line;
  }
}

unlink $path;
rename $path . '.new', $path;

