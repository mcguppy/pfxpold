package PFXCheck;

use strict;
use warnings;
#use Data::Dumper;
use Redis::Client;

our $VERSION = '0.1';

my $REDIS_HOST = "localhost";
my $REDIS_PORT = 6379;

my $dayLimit = 500; # this is the default daily limit, if no value "dayLimit" in redis is set

my $REJECT_MESSAGE = "REJECT 590 daily mail limit reached";

sub new(){
	my $class = shift;
	my $self  = {};
	&main::dolog("debug", "$class instantiated.");
	$self->{'dbh'} = undef;
	bless $self;
}
	
sub do_check($){
	&main::dolog("debug", "Entering do_check routine.");

	my $self      = shift @_;
	my $querydata = shift @_;

	# Check if all data was sent
	unless ($querydata->{'sasl_username'}){
		&main::dolog("debug", "Ignoring no SASL authenticated mail request.");
		return "DUNNO";
	}
	my $sasl_username  = "$querydata->{'sasl_username'}";
	
	# number of recipient
	my $recipient      = "";
	my $nbrOfRecipients = 1;
	if ($querydata->{'recipient'}){
		$recipient      = "$querydata->{'recipient'}";
		$nbrOfRecipients = $recipient =~ tr/,//;
		$nbrOfRecipients = $nbrOfRecipients + 1;
	}
		
	&main::dolog("debug", "Checking for: sasl_username=$sasl_username");
	
	
	# Connect to DB
	$self->{'dbh'} = Redis::Client->new(
			server => "$REDIS_HOST:$REDIS_PORT", 
			reconnect => 2, 
			every => 100000
	) or die "Cant connect to redis server : $!";
	
	&main::dolog("debug", "Redis DB connection established.");
	
	if ($self->{'dbh'}->hexists($sasl_username, "dayLimit")) {
		# user is in redis and has a day limit value
		$dayLimit = $self->{'dbh'}->hget($sasl_username, 'dayLimit');
	}
	unless ($self->{'dbh'}->hexists($sasl_username, "dayCounter")) {
		# if no day counter is set yet (first mail of the day), set the counter to 0
		$self->{'dbh'}->hset($sasl_username, 'dayCounter' => 0);	
	}
	
	unless ($self->{'dbh'}->hexists($sasl_username, "totalCounter")) {
		# if no total counter is set yet (first mail since resetting the total counter), set the counter to 0
		$self->{'dbh'}->hset($sasl_username, 'totalCounter' => 0);	
	}
    
	my $dayCounter = $self->{'dbh'}->hget($sasl_username, 'dayCounter');
	my $totalCounter = $self->{'dbh'}->hget($sasl_username, 'totalCounter');

	if ($dayCounter >= 0 and $dayCounter <= $dayLimit and $dayCounter + $nbrOfRecipients <= $dayLimit){
		# update limited User who hasnt reached MAXMAIL
		my $newDayCounter = $dayCounter + $nbrOfRecipients;
		my $newTotalCounter = $totalCounter + $nbrOfRecipients;
		$self->{'dbh'}->hset($sasl_username, 'dayCounter' => $newDayCounter);
		$self->{'dbh'}->hset($sasl_username, 'totalCounter' => $newTotalCounter);
		&main::dolog("info", "PFX-PERMIT: sasl_username=$sasl_username --> day counter: $newDayCounter; day limit: $dayLimit; total-counter (since last reset): $newTotalCounter");
    		undef $self->{'dbh'};
		return "DUNNO"
	} else {
		# limited User has reached MAXMAIL
		&main::dolog("warning", "PFX-DENY: sasl_username=$sasl_username --> day counter: $dayCounter; day limit: $dayLimit; Nbr of mails not sent because of day limit: $nbrOfRecipients; total-counter (since last reset): $totalCounter");
       		undef $self->{'dbh'};
		return "$REJECT_MESSAGE";
	}
	
}
1;
