#!/usr/bin/perl -w
use strict;

# Where to find the authentication module
use FindBin qw($Bin);
use lib "$Bin";


use PFXCheck;

my $switch;
$switch = shift;
if( $switch and $switch eq "-f" ) {
        PFXCheck::deleteAllKeys;
} else {
	print "Are you sure to delete all keys? This will also delete the specific day limits for users (y/n): ";
	chomp( my $line = <STDIN> );
	if ( $line eq 'y' ) {
        	PFXCheck::deleteAllKeys;
	}
}
