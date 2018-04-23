
package colornames;

use strict;
use Math::Round;
use Graphics::ColorObject;
use List::MoreUtils qw(uniq);

sub read_color_name_file {
	my $file = shift;
	my $db;
	open(F,$file) || return $db;
	while(my $c = <F>) {
		chomp($c);
		next if $c =~ /^\#/;
		my @tok  = split(" ",$c);
		my $idx  = shift @tok;
		my $name = shift @tok;
		my $entry = {name=>$name,i=>$idx};
		for my $space (qw(rgb hex hsv xyz lab lch)) {
			shift @tok;
			if($space ne "hex") {
				$entry->{space}{$space} = [(shift @tok),(shift @tok),(shift @tok)];
			} else {
				$entry->{space}{$space} = shift @tok;
			}
		}
		push @$db, $entry;
	}
	return $db;
}

sub find_neighbours {
	my ($rgb,$db,%args) = @_;

	my $namerx     = $args{-namerx};
	my $maxdE      = $args{-maxde}      || 5;
	my $precision  = $args{-precision}  || 4;
	my $neighbours = $args{-neighbours} || $args{-neighbors} || 10;
	my $fmtrgb     = "%d,%d,%d";
	my $fmt        = join(" ",map {"%.".$precision."f"} (0..2));
	my $fmt4       = join(" ",map {"%.".$precision."f"} (0..3));

	my $cobj = Graphics::ColorObject->new_RGB255($rgb);
	my $color;
	$color->{space}{rgb}  = $rgb;
	$color->{space}{hex}  = $cobj->as_RGBhex();
	$color->{space}{hsv}  = $cobj->as_HSV();
	$color->{space}{xyz}  = $cobj->as_XYZ();
	$color->{space}{lab}  = $cobj->as_Lab();
	$color->{space}{lch}  = $cobj->as_LCHab();
	$color->{space}{lch}[2] += 360 if $color->{space}{lch}[2] < 0;
	$color->{space}{cmyk} = $cobj->as_CMYK();
	# calculate distances between all the colors
	my @n;
	for my $dbc (@$db) {
		next if $namerx && $dbc->{name} !~ /$namerx/;
		my $de = deltaE($color->{space}{lab},$dbc->{space}{lab});
		push @n, {name  => $dbc->{name},
							i     => $dbc->{i},
							space => $dbc->{space},
							de    => $de};
	}
	@n = sort {$a->{de} <=> $b->{de}} @n;
	my $words;
	my $num_neighbours_maxdE;
	if($n[0]{de} <= $maxdE) {
		$words = join(" ",map { $_->{name} } grep($_->{de} <= $maxdE, @n[0..$neighbours-1]));
		$num_neighbours_maxdE = grep($_->{de} <= $maxdE, @n[0..$neighbours-1]);
	} else {
		$num_neighbours_maxdE = 0;
		$words = $n[0]{name};
	}
	$words =~ s/_/ /g;
	my @words = uniq(sort split(" ",$words));
	my $n = join(":", map { sprintf("%s[%d][$fmtrgb](%.1f)", 
																	$_->{name},
																	$_->{i},
																	@{$_->{space}{rgb}},
																	$_->{de}) } 
							 @n[0..$neighbours-1]);

	my $neighbour = { rgb  => sprintf("%d %d %d",@{$color->{space}{rgb}}),
										hex  => sprintf("%s",$color->{space}{hex}),
										hsv  => sprintf($fmt,@{$color->{space}{hsv}}),
										xyz  => sprintf($fmt,@{$color->{space}{xyz}}),
										lab  => sprintf($fmt,@{$color->{space}{lab}}),
										lch  => sprintf($fmt,@{$color->{space}{lch}}),
										cmyk => sprintf($fmt4,@{$color->{space}{cmyk}}),
										neighbours_list=>[@n],
										neighbours=>$n,
										num_neighbours_maxdE=>$num_neighbours_maxdE,
										tags=>join(":",sort_tags(@words)) };
	return $neighbour;
}
sub sort_tags {
	my @tags = @_;
	my %tags = map { $_=>1 } @tags;

	my @prefixes = qw(very vivid brilliant strong flat dark light burnt moderate medium deep slate misty pale luminous antique);
	my @hues     = qw(red orange green yellow blue purple violet brown lemon lime lavender pink almond white grey gray black peach mint rose turquoise papaya aquamarine azure indigo crimson);

	my @prefixes_this = ();
	my @hues_this     = ();

	for my $p (@prefixes) {
		if($tags{$p}) {
			unshift @prefixes_this, $p;
			delete $tags{$p};
		}
	}
	for my $h (@hues) {
		if($tags{$h}) {
			unshift @hues_this, $h;
			delete $tags{$h};
		}
	}

	return @prefixes_this,(sort keys %tags),(sort @hues_this);

}

sub deltaE {
	my ($c1,$c2) = @_;
	my $dl = $c1->[0] - $c2->[0];
	my $da = $c1->[1] - $c2->[1];
	my $db = $c1->[2] - $c2->[2];
	return sqrt($dl**2 + $da**2 + $db**2);
}

1;
