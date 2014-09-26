#!/usr/bin/env perl

use strict;
use warnings;
use 5.014;

use Term::ANSIColor;
use List::Compare;
use File::Slurp;

my ( $old, $new ) = @ARGV or die "Usage: $0 old_validation new_validation";

# don't eval untrusted shit, m'kay?
eval '$_ = ' . read_file($_) for ( $old, $new );

for my $group ( sort keys $old ) {
    unless ( exists $new->{$group} ) {
        say "Group $group no longer exists.\n";
        next;
    }

    for my $method ( sort keys $old->{$group} ) {
        unless ( exists $new->{$group}{$method} ) {
            say "Group $group.$method no longer exists.\n";
            next;
        }

        my $old_args = $old->{$group}{$method};
        my $new_args = $new->{$group}{$method};

        my $args = {
            'required' => List::Compare->new( $old_args->[0], $new_args->[0] ),
            'optional' => List::Compare->new( $old_args->[1], $new_args->[1] )
        };

        for my $type ( keys $args ) {
            next if $args->{$type}->is_LequivalentR();
            say "$group.$method difference in $type arguments: ";
            my @old = $args->{$type}->get_unique();
            print "\t";
            for my $differing ( $args->{$type}->get_symmetric_difference() ) {
                my $removed = grep { $_ eq $differing } @old;
                print colored( ( $removed ? '- ' : '+ ' ) . $differing . '  ',
                    ( $removed ? 'red' : 'green' ) );
            }
            say "\n";
        }
    }

    for my $method ( sort keys $new->{$group} ) {
        next if exists $old->{$group}{$method};
        say "New method $group.$method\n";
    }

}

for my $group ( sort keys $new ) {
    next if exists $old->{$group};
    say "New group $group\n";
}

