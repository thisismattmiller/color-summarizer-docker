
################################################################
#
# Cluster colors in image data sampled with imagesample::sample_image
# and return color and number of pixels in each cluster
#
package colorspace;

use strict;
use Math::Round qw(round nearest);
use Graphics::ColorObject;

our $precision = 1;

our %callers = ( cmy  => "as_CMY",
								 cmyk => "as_CMYK",
								 hsl  => "as_HSL",
								 hsv  => "as_HSV",
								 hex  => "as_RGBhex",
								 xyz  => "as_XYZ",
								 rgb  => "as_RGB255",
								 xyy  => "as_xyY",
								 lab  => "as_Lab",
								 lch  => "as_LCHab",
								 luv  => "as_Luv" );

# color conversion function to $space
sub caller_as {
	my $space = shift;
	return $callers{$space} || undef;
}

# initializer function for $space
sub caller_new {
	my $space  = shift;
	my $caller = caller_as($space);
	$caller =~ s/as_/new_/ if $caller;
	return $caller || undef;
}

# convert to another color space
# - use lookup table
{
	my $table = {};
	sub convert {
		my ($cobj,$space) = @_;
		my $fn     = caller_as($space);
		return undef if ! $fn;
		my $xyz_key = join(",",@{$cobj->{xyz}});
		my @coords;
		if(exists $table->{$xyz_key}{$space}) {
			@coords = @{$table->{$xyz_key}{$space}};
		} else {
			my $coords = $cobj->$fn();
			@coords = ref $coords eq "ARRAY" ? @$coords : ($coords);
			$table->{$xyz_key}{$space} = [@coords];
		}
		return colorspace::format_coordinates($space,@coords);
	}
}

sub format_coordinates {
	my ($space,@x) = @_;
	$space = lc $space;
	if($space eq "rgb") {
		return map {nearest($precision,$_) } @x;
	} elsif ($space eq "hsv") {
		return (nearest($precision,$x[0]),
						nearest($precision,$x[1]*100),
						nearest($precision,$x[2]*100));
	} elsif ($space eq "cmyk") {
		return map {nearest($precision,$_*100) } @x;
	} elsif ($space eq "lab") {
		return map {nearest($precision,$_) } @x;
	} elsif ($space eq "luv") {
		return map {nearest($precision,$_) } @x;
	} elsif ($space eq "lch") {
		if($x[2] < 0) {
			$x[2] += 360;
		} elsif ($x[2] > 360) {
			$x[2] -= 360;
		}
		return map {nearest($precision,$_) } @x;
	} elsif ($space eq "xyz") {
		return map {nearest($precision/100,$_)} @x;
	} elsif ($space eq "hex") {
		$x[0] = "#".$x[0] if $x[0] !~ /^\#/;
		return $x[0];
	} else {
		return @x;
	}
}


1;
