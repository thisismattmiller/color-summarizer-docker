
################################################################
#
# look at each pixel in the image and return array with
#
# [x][y]{space}{SPACE} = [a,b,c]
# [x][y]{cobj}         = Graphics::ColorObject() for pixel
#
################################################################

package imagesampler;

use Imager;
use strict;
use Math::Round;
use Math::VecStat qw(min max);
use Data::Dumper;
use Graphics::ColorObject;

use colorspace;
use colordebug;

our @spaces  = qw(hsv lch lab);

sub get_image_size {
	my $file = shift;
	my $im = Imager->new();
	$im->open(file=>$file) or die Imager->errstr();
	return ($im->getwidth(),$im->getheight());
}

sub sample_image {

	my %args   = @_;
	my $file   = $args{-file};
	my $spaces = $args{-spaces} || \@spaces;
	my $cropx  = $args{-cropx}  || 0;
	my $cropy  = $args{-cropy}  || 0;
	my $cropw  = $args{-cropw};
	my $croph  = $args{-croph};
	my $error;

	&colordebug::printdebug("reading image",$file);

	die "The file $file does not exist" if ! -e $file;
	die "The file $file cannot be read" if ! -r $file;

	my ($w,$h,$im);
	$im = Imager->new();
	$im->open(file=>$file) or die Imager->errstr();
	($w,$h) = ($im->getwidth(),$im->getheight());
	&colordebug::printdebug($im,$file,$w,$h);

  my $imgdata = {file=>$file,channels=>$im->getchannels,size=>{w0=>$w,h0=>$h,w=>$w,h=>$h}};

	# single or double coordinates
	# cropx = 10
  # cropx = 10,20
	if($args{-cropx} || $args{-cropy} || $cropw || $croph) {
		my ($x1,$x2) = split(",",$args{-cropx});
		$x1 ||= 0;
		if(defined $args{-cropw}) {
			$x2 = $x1 + $args{-cropw};
		} else {
			$x2 = $x1 if ! defined $x2;
			$x2 = $w - $x2;
		}
		my ($y1,$y2) = split(",",$args{-cropy});
		$y1 ||= 0;
		if(defined $args{-croph}) {
			$y2 = $y1 + $args{-croph};
		} else {
			$y2 = $y1 if ! defined $y2;
			$y2 = $h - $y1;
		}
		$im = $im->crop(left => $x1, right  => $x2,
										top  => $y1, bottom => $y2);
		($w,$h) = ($im->getwidth(),$im->getheight());
		&colordebug::printdebug("cropping region",$x1,$y1,$x2,$y2,"width",$w,"height",$h);
		$imgdata->{crop} = {x1=>$x1,
												y1=>$y1,
												x2=>$x2,
												y2=>$y2};
	} else {
		$imgdata->{crop} = {x1=>0,
												y1=>0,
												x2=>$w,
												y2=>$h};
	}

	if($args{-resizew} && $args{-resizew} < $w) {
		$im = $im->scale(xpixels=>$args{-resizew},qtype=>"normal");
		($w,$h) = ($im->getwidth(),$im->getheight());
		@{$imgdata->{size}}{qw(w h)} = ($w,$h);
		&colordebug::printdebug("resized",$w,$h);
	}

	return (undef,"Could not resize the image.") if ! $im || Imager->errstr;

	# for each pixel, store color values, alpha
	# and the Graphics::ColorObject object 
	#
	# {space}{SPACE}
	# {alpha}
  # {cobj}
	#
	my @x = (0..$w-1);
	for my $y (0..$h-1) {
		my ($r,$g,$b,$a);
		#my @colors    = $im->getpixel(x=>\@x,y=>$y);
		my @colors    = $im->getscanline(y=>$y);
		for my $i (0..@colors-1) {
			my $color = $colors[$i];
			my $x     = $x[$i];
			($r,$g,$b,$a) = $color->rgba();
			&colordebug::printdebug("xy",$x,$y,"sample","rgb",$r,$g,$b,"a",$a);
			# $a = 0   transparent
			# $a = 255 opaque
			push @{$imgdata->{space}{rgb}}, [$r,$g,$b,$a];
			push @{$imgdata->{alpha}}, $a;
			$imgdata->{pixel}[$x][$y] = [$r,$g,$b,$a];
			my $cobj = Graphics::ColorObject->new_RGB255([$r,$g,$b]);
			push @{$imgdata->{cobj}}, $cobj;
			for my $space (@$spaces) {
				next if $space eq "rgb";
				my $coords = [ colorspace::convert($cobj,$space) ];
				&colordebug::printdebug("xy",$x,$y,"convert","rgb",$r,$g,$b,$space,@$coords);
				push @{$imgdata->{space}{$space}}, $coords;
			}
		}
	}
	return ($imgdata,$error);
}

1;
