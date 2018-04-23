
################################################################
# compute the average and median of a periodic data set, like
# a set of angles or hues
#
# periodic_averge($data,$min,$max,$step)
#
# $data = [x1,x2,x3,....]
# $min  = min possible value for $data
# $max  = max possible value for $data
# $step = position increment for sliding window (default 1)

package peravg;

use strict;
use Math::Round;

# calculate the average of @data, assuming that 
# this stores a quantity 0-359 that folds over
#
# mode is the most frequently seen hue (rounded)

sub periodic_average {
  my @data = @_;
  my @newdata = @data;
  while(@newdata > 1) {
    @newdata = peravg::pair_down_faster(@newdata);
  }
  my $avg = $newdata[0];
  return $avg;
}

sub pair_down {
  my @data = @_;
  my @newdata;
  for my $i (0..@data/2) {
    my ($v1,$v2) = ($data[2*$i],$data[2*$i+1]);
    last if ! defined $v1;
    if(! defined $v2) {
      push @newdata,$v1;
      last;
    } else {
      my $avg;
      ($v1,$v2) = ($v2,$v1) if $v2 < $v1;
      if($v2 - $v1 > 180) {
	$avg = ($v2 - 360 + $v1)/2;
	$avg += 360 if $avg < 0;
      } else {
	$avg = ($v1 + $v2)/2;
      }
      push @newdata, $avg;
    }
  }
  return @newdata;
}

sub pair_down_faster {
  my @data = @_;
  my @newdata;
  while(my ($v1,$v2) = splice(@data,0,2)) {
    if(! defined $v2) {
      push @newdata,$v1;
    } else {
      my $avg;
      my $d = $v1 - $v2;
      if($d > 180 || $d < -180) {
	$avg = ($v2 - 360 + $v1)/2;
	$avg += 360 if $avg < 0;
      } else {
	$avg = ($v1 + $v2)/2;
      }
      push @newdata, $avg;
    }
  }
  return @newdata;
}

sub fracmod {
  my ($a,$b) = @_;
  return $a - $b*int($a/$b);
}

1;
