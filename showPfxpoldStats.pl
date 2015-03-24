#!/usr/bin/perl -w
use strict;

# Where to find the authentication module
use FindBin qw($Bin);
use lib "$Bin";

use PFXCheck;

print PFXCheck::getStats;
