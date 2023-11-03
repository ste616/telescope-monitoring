#!/usr/bin/perl

use Astro::Time;
use ATNF::MoniCA;
use JSON;
use Data::Dumper;
use strict;
use utf8;

# Our argument is the configuration file that tells
# us how to form the JSON.
my $config_file = $ARGV[0];
if (!defined $config_file) {
    die "Must supply configuration file as argument\n";
}
my %cfg = &read_config_file($config_file);

# Start the output JSON object.
my %jo;

# Check for necessary information.
# First, we need a "monicaServer" key.
if (!defined $cfg{'monicaServer'}) {
    die "Configuration file must supply MoniCA server information!\n";
}
# We also need the telescope name.
if (!defined $cfg{'antennaName'}) {
    die "Configuration file must supply antenna name!\n";
}
$jo{'antennaName'} = $cfg{'antennaName'};

# Collect all the MoniCA points we need.
my $mon = monconnect($cfg{'monicaServer'});

foreach my $k (keys %cfg) {
    if (($k ne "antennaName") && ($k ne "monicaServer")) {
	#print "doing $k\n";
	my $jl = \%jo;
	# Dots in the name are levels in the object.
	my @ne = split(/\./, $k);
	for (my $i = 0; $i < $#ne; $i++) {
	    if (!defined $jl->{$ne[$i]}) {
		$jl->{$ne[$i]} = {};
	    }
	    $jl = $jl->{$ne[$i]};
	}
	# All elements are supplied as a comma-separated list.
	my @ps = split(/\,/, $cfg{$k});
	# The last element is the instruction, so we just take all
	# but the last point.
	my $inst = splice(@ps, -1);
	my @point_vals = monpoll2($mon, @ps);
	if ($inst eq "value") {
	    $jl->{$ne[$#ne]} = &get_values(@point_vals);
	} elsif ($inst eq "error") {
	    $jl->{$ne[$#ne]} = &get_errors(@point_vals);
	} # keep doing elsifs for each different subroutine
	# Standardise things.
	&standardise_outputs($jl, $k);
    }
    
}

monclose($mon);

# Output the JSON.
print to_json(\%jo);
print "\n";

sub standardise_outputs {
    my $o = shift;
    my $k = shift;

    # The standards for some keywords.
    my %keystandards = (
	'weather.windSpeed' => [ "number" ],
	'configuration.tickPhase' => [ "number" ],
	'azimuth' => [ "number" ], 'elevation' => [ "number" ],
	'rightAscensionICRF' => [ "sexagesimal" ],
	'declinationICRF' => [ "sexagesimal" ],
	'weather.temperature' => [ "number" ],
	'configuration.frequencies' => [ "number" ]
	);
    my @ne = split(/\./, $k);
    my $lk = $ne[$#ne];
    if (defined $keystandards{$k}) {
	for (my $i = 0; $i <= $#{$keystandards{$k}}; $i++) {
	    if (ref($o->{$lk}) eq "ARRAY") {
		for (my $j = 0; $j <= $#{$o->{$lk}}; $j++) {
		    if ($keystandards{$k}->[$i] eq "number") {
			$o->{$lk}->[$j] = &convert_to_number($o->{$lk}->[$j]);
		    } elsif ($keystandards{$k}->[$i] eq "sexagesimal") {
			$o->{$lk}->[$j] = &convert_to_sexagesimal($o->{$lk}->[$j]);
		    }
		}
	    } else {
		if ($keystandards{$k}->[$i] eq "number") {
		    $o->{$lk} = &convert_to_number($o->{$lk});
		} elsif ($keystandards{$k}->[$i] eq "sexagesimal") {
		    $o->{$lk} = &convert_to_sexagesimal($o->{$lk});
		}
	    }
	}
    }

    # Convert a single-element array into a scalar.
    if ((ref($o->{$lk}) eq "ARRAY") && ($#{$o->{$lk}} == 0)) {
	$o->{$lk} = $o->{$lk}->[0];
    }
}

sub convert_to_sexagesimal($) {
    my $nn = shift;
    if ($nn =~ /[\'°]+/) {
	$nn =~ s/[\'°]/\:/g;
	$nn =~ s/\"//g;
	$nn =~ s/[^\d\:\.]//g;
	return $nn;
    }
    return $nn;
}

sub convert_to_number($) {
    my $nn = shift;
    # We assume it's already in the units it's supposed to be in.
    $nn = &convert_to_sexagesimal($nn);
    if ($nn =~ /\:/) {
	return str2deg($nn, "D");
    } else {
	return $nn + 0;
    }
}

sub get_errors {
    my @r = @_;

    my @e;
    for (my $i = 0; $i <= $#r; $i++) {
	my $estate = (($r[$i]->errorstate ne "true") &&
		      ($r[$i]->errorstate ne "false")) ?
	    "false" : $r[$i]->errorstate;
	if ($estate eq "true") {
	    $estate = "false";
	} else {
	    $estate = "true";
	}
	push @e, $estate;
    }

    return \@e;
}

sub get_values {
    my @r = @_;

    my @v;
    for (my $i = 0; $i <= $#r; $i++) {
	push @v, $r[$i]->val;
    }

    return \@v;
}

sub read_config_file($) {
    my $cf = shift;
    
    if (!-e $cf) {
	die "$cf is not a file!\n";
    }
    open(C, $cf) || die "Unable to open $cf for reading!\n";
    my %cfg;
    while(<C>) {
	chomp(my $line = $_);
	my $sline = &sanitise_input($line);
	my @els = split(/\=/, $sline);
	if ($#els == 1) {
	    $cfg{$els[0]} = $els[1];
	}
    }
    close(C);

    return %cfg;
}

sub sanitise_input($) {
    my $u = shift;

    if (!defined $u) {
	return "";
    }
    
    # We make sure bad characters don't get in here.
    my $goodchars = qr/[a-zA-Z0-9\:\;\+\-\_\,\.\=]+/;
    my $badchars = qr/[^a-zA-Z0-9\:\;\+\-\_\,\.\=]/;

    $u =~ s/$badchars//g;

    my $c = "";
    
    if ($u =~ /($goodchars)/) {
	$c = $1;
    }

    return $c;
}
