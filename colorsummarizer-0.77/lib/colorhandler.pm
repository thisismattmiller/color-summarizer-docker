
################################################################
#
# routines to deal with color conversion and
# color name to hue mapping
#

package colorhandler;

use strict;
use Storable;
use Data::Dumper;
use POSIX qw(pow);
use Math::Round;
use Graphics::ColorObject;
use Math::VecStat qw(sum min max average);

$colorhandler::rgb_text           = "cache/rgb.clean.txt";
$colorhandler::strip_color_number = 1;

# the hue map is a hash that relates a hue (0-359) to a color name
# a map of color names and rgb values is obtained from image::magick's
# internal list (via Query Color) and supplemented with 
# UNIX's X11R6/*/rgb.txt

sub make_hue_map {

  my $cachefile = shift;
  my $rgb_file  = shift;

  if(-e $cachefile && ! $main::CONF{huemap}{alwayscreate}) {
		eval {
			return retrieve($cachefile);
		};
		if ($@) {
			# we'll have to redo the cache file
		}
  }

  my $huemap;
  # color names we've already seen
  my %seen;

  # hash of colors and their rgb values
  # rgbmap->{green} = [r,g,b]
  my %rgbmap;

  # first from the rgb color text file
  # note - color names in this file may contain spaces and number suffixes, which 
  # usually map to the value of the color
  open(F,$rgb_file || $colorhandler::rgb_text);
  while (<F>) {
    next if /^!/;
    chomp;
    my ($r,$g,$b,@name) = split;
    my $color = lc join("",@name);
    $color =~ s/\d+$// if $colorhandler::strip_color_number;
    next unless $color;
    $rgbmap{$color} = [$r,$g,$b];
  }
  close(F);

  for my $color (keys %rgbmap) {
    my ($r,$g,$b) = @{$rgbmap{$color}};
    my ($h,$s,$v) = rgb2hsv($r,$g,$b);
    next unless $s >= $main::CONF{huemap}{saturation_cutoff};
    for my $rx (keys %{$main::CONF{huemap}{stripwords}}) {
      $color =~ s/$rx//;
    }
    next if $seen{$color}++;
    # hue is rounded in the color map key
    push @{$huemap->{round $h}}, {color=>$color,rgb=>[$r,$g,$b],hsv=>[$h,$s,$v],hex=>rgb2hex($r,$g,$b)};
  }
  store($huemap,$cachefile);
  return $huemap;
}

sub find_closest_huemap_entry {
  my $hue      = shift;
  my $huemap   = shift;
  $hue = round($hue);
  for my $step (0..360) {
    my $h = $hue+$step;
    $h += 360 if $h < 0;
    $h -= 360 if $h > 360;
    return $huemap->{$h} if $huemap->{$h};
    $h = $hue-$step;
    $h += 360 if $h < 0;
    $h -= 360 if $h > 360;
    return $huemap->{$h} if $huemap->{$h};
  }
  return undef;
}

# from rgb values (r,g,b) to hex (HHhhHH)
sub rgb2hex {
  my ($r,$g,$b) = @_;
  return sprintf("%02x%02x%02x",$r,$g,$b);
}

# scaled unit conversions
#
# r,g,b :: 0-255
# h :: 0-359
# s :: 0-100
# v :: 0-255
sub rgb2hsv {
  my ($r,$g,$b) = @_;
  my ($h,$s,$v) = rgb2hsv_raw($r,$g,$b);
  return map { round $_ } ($h,$s*100,$v*100/255);
}

sub hsv2rgb {
  my ($h,$s,$v) = @_;
  my ($r,$g,$b) = hsv2rgb_raw($h,$s/100,$v*255/100);
  return map { round $_ } ($r,$g,$b);
}

# from rgb to hsv (hue, saturation, value)
#
# h = 0 .. 360
# s = 0 .. 1
# v = 0 .. 255
sub rgb2hsv_raw {
  my ($r, $g, $b) = @_;
  my ($h, $s, $v);

  my ($min,$max) = ($r,$r); # choose r as default

  # fast determination of min/max. since rgb2hsv is called alot, 
  # any savings here add up
  my $t1 = $r < $g;
  my $t2 = $r < $b;
  my $t3 = $g < $b;
  if($t1 && $t2) {
    # r < g AND r < b
    $min = $r;
  } elsif ($t3 && ! $t1) {
    # g < b AND g <= r
    $min = $g;
  } else {
    $min = $b;
  }
  if(! $t1 && ! $t2) {
    $max = $r;
  } elsif ($t1 && ! $t3) {
    $max = $g;
  } else {
    $max = $b;
  }
  # sanity check - turn on only for debugging
  #die "min wrong $min: $r $g $b" unless $min == min($r,$g,$b);
  #die "max wrong $max: $r $g $b" unless $max == max($r,$g,$b);
  # print STDERR "$min $max\n";
  my $delta = $max - $min;
  $v = $max;
  $s = $max ? $delta/$max : 0;
  return (0,$s,$v) if $s == 0;

  if($r == $max) {
    $h = ( $g - $b ) / $delta; 
  } elsif ( $g == $max ) {
    $h = 2 + ( $b - $r ) / $delta; 
  } else {
    $h = 4 + ( $r - $g ) / $delta;
  }
  $h *= 60;
  $h += 360 if $h < 0;
  return ($h,$s,$v);
}

# inverse of rgb2hsv
sub hsv2rgb_raw  {
  my ($h, $s, $v) = @_;
  my ($r, $g, $b);

  while ($h < 0) { $h += 360; }
  while ($h >= 360) { $h -= 360; }

  $h /= 60;
  my $i = POSIX::floor( $h );
  my $f = $h - $i;
  my $p = $v * ( 1 - $s );
  my $q = $v * ( 1 - $s * $f );
  my $t = $v * ( 1 - $s * ( 1 - $f ) );

  if($i == 0) {
    $r = $v;
    $g = $t;
    $b = $p;
  } elsif ($i == 1) {
    $r = $q;
    $g = $v;
    $b = $p;
  } elsif ($i == 2) {
    $r = $p;
    $g = $v;
    $b = $t;
  } elsif ($i == 3) {
    $r = $p;
    $g = $q;
    $b = $v;
  } elsif($i == 4) {
    $r = $t;
    $g = $p;
    $b = $v;
  } else {
    $r = $v;
    $g = $p;
    $b = $q;
  }
  return ($r,$g,$b);
}

1;


