#!/usr/bin/env perl

use strict;
use warnings;
use autodie;

# validation fragment filename as command line argument or via stdin
my $validation = join '', <>;
chomp($validation);    # remove just final \n
my $path = '../WebService-Linode/lib/WebService/Linode.pm';

open( my $old_fh, '<', $path );
open( my $new_fh, '>', $path . '.new' );

my $fragment_added = 0;
while ( defined( my $line = <$old_fh> ) ) {
  if ( ( $line =~ /^# beginvalidation$/ ) .. ( $line =~ /^# endvalidation$/ ) ) {
    print $new_fh "# beginvalidation\n", 'my $validation = ', $validation, ";\n# endvalidation\n"
      unless $fragment_added++;
  }
  else {
    print $new_fh $line;
  }
}

unlink $path;
rename $path . '.new', $path;

