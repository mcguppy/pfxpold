#!/usr/bin/perl -w
use strict;

# Where to find the authentication module
use FindBin qw($Bin);
use lib "$Bin";

use PFXCheck;

my $switch;
$switch = shift;
if( $switch and $switch eq "-f" ) {
        PFXCheck::resetTotalCounter;
} else {
	print "Are you sure to reset all total counters (y/n): ";
	chomp( my $line = <STDIN> );
	if ( $line eq 'y' ) {
        	PFXCheck::resetTotalCounter;
	}
}
