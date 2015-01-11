#!/usr/bin/env perl

use strict;
use warnings;
use 5.014;

use Mojo::UserAgent;
use Data::Dumper;
use Getopt::Std;

my %opts;
getopts( 'v', \%opts );

my $api_base = shift || "https://api.linode.com/";
my $spec = get_spec();
my ( $verbose_validation, $validation ) = parse_spec($spec);

if ( $opts{v} ) {
  print Data::Dumper->Dump( [$verbose_validation], ['verbose_validation'] );
}
else {
  dump_validation($validation);
}

sub get_spec {
    my $res = Mojo::UserAgent->new->get(
        "${api_base}?api_action=api.spec")->res;
  die $res->error->{message} if $res->error;
  return $res;
}

sub parse_spec {
    my $res     = shift;
    my $methods = $res->json->{DATA}->{METHODS};

    my ( $verbose_validation, $valiation );
    for my $remote_method ( keys %$methods ) {
        unless ( $remote_method =~ m/^(\S+)\.([^\.\s]++)$/ ) {
            warn "UNMATCHED METHOD: $remote_method\n";
            next;
        }
        my ( $group, $method ) = ( lc($1), lc($2) );
        $group =~ tr/\./_/;

        for my $parameter ( keys %{ $methods->{$remote_method}{PARAMETERS} } ) {
            my $key = $methods->{$remote_method}{PARAMETERS}{$parameter}{REQUIRED} ? 'required' : 'optional';
            push @{ $verbose_validation->{$group}{$method}{$key} },
                [ lc $parameter, $methods->{$remote_method}{PARAMETERS}{$parameter}{DESCRIPTION} ];
        }
        for my $type ( 'required', 'optional') {
          push @{ $validation->{$group}{$method} }, [ map { $_->[0] } @{ $verbose_validation->{$group}{$method}{$type} } ];
        }

        $verbose_validation->{$group}{$method}{description} = $methods->{$remote_method}{DESCRIPTION};
    }
    return $verbose_validation, $validation;
}

sub dump_validation {
    my $validation = shift;
    print "{ \n";
    for my $group ( sort keys %$validation ) {
        print "    $group => {\n";
        for my $method ( sort keys %{ $validation->{$group} } ) {
            my $args = join ', ',
                map { dump_arrayref($_) } @{ $validation->{$group}{$method} };
            print "        $method => [ $args ],\n";
        }
        print "    },\n";
    }
    print "}\n";
}

sub dump_arrayref {
        my $ref = shift;
        @$ref = sort @$ref;
        if ( @$ref == 0 ) {
            return '[]';
        }
        elsif ( @$ref <= 2 ) {
            return '[ ' . join( ', ', map {"'$_'"} @$ref ) . ' ]';
        }
        return '[qw( ' . join( ' ', @$ref ) . ' )]';
}
