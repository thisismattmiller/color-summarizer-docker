
################################################################
#
# Histogram colors
#
package imagehistogram;

use strict;
use Math::Round;
use Data::Dumper;
use Math::VecStat qw(average sum min max);
use POSIX qw(ceil);

use constant PI => 4 * atan2(1, 1);

sub make_histograms {
	my %args      = @_;
	my $imgdata   = $args{-imgdata};
	my $histogram = $args{-histogram};
	my $stats     = $args{-stats};

 	my @spaces    = keys %{$imgdata->{space}};
	my $hdata;
 	for my $space (@spaces) {
		my @components = split("",$space);
		for my $component_idx (0..@components-1) {
			my $component = $components[$component_idx];
			my @values = map { $_->[$component_idx] } @{$imgdata->{space}{$space}};
			if($histogram) {
				for my $value (@values) {
					$hdata->{$space}{$component}{hist}{$value}++;
				}
			}
			if($stats) {
				# hue gets averaged differently
				if($component eq "h") {
					my (@x,@y);
					for my $v (@values) {
						my $angle = PI*$v/180;
						#printinfo($v,$angle,atan2(sin($angle),cos($angle)));
						push @x, cos($angle);
						push @y, sin($angle);
					}
					my ($xavg,$yavg) = (average(@x),average(@y));
					$hdata->{$space}{$component}{avg} = sprintf("%d %.2f",180*atan2($yavg,$xavg)/PI % 360,round(sqrt($xavg**2+$yavg**2)));
				} else {
					$hdata->{$space}{$component}{avg}  = round(average(@values));
				}
				$hdata->{$space}{$component}{median} = median(@values);
				$hdata->{$space}{$component}{min}    = scalar min(@values);
				$hdata->{$space}{$component}{max}    = scalar max(@values);
			}
		}
	}
	return $hdata;
}

sub median {
  sum( ( sort { $a <=> $b } @_ )[ int( $#_/2 ), ceil( $#_/2 ) ] )/2;
}

1;
