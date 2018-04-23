
package imagereport;

use strict;
use Math::Round;
use Math::VecStat qw(min max);
use Statistics::Basic qw(median stddev mean);
use JSON::XS;

sub text_report {
	my %args = @_;
	my $img_data       = $args{-img_data};
	my $cluster_data   = $args{-cluster_data};
	my $histogram_data = $args{-histogram_data};
	my $deltaE         = $args{-deltaE};

	my (@lines,@xml,@json);

	my $json;
	my $json_basic = {};
	if (! defined $args{-filename} || $args{-filename}) {
		push @lines, ["image",
									"size",@{$img_data->{size}}{qw(w0 h0)},
									"crop",@{$img_data->{crop}}{qw(x1 x2 y1 y2)},
									"resampled",@{$img_data->{size}}{qw(w h)}];
		push @xml,   [sprintf('<imgdata file="%s" width_original="%d" width="%d" height_original="%d" height="%d">',
													$img_data->{file},
													@{$img_data->{size}}{qw(w0 w h0 h)})];
		$json->{file} = {filename=>$img_data->{file},
										 w0=>$img_data->{size}{w0},
										 h0=>$img_data->{size}{h0},
										 w=>$img_data->{size}{w},
										 w=>$img_data->{size}{h}};
	} else {
		push @lines, [@{$img_data->{size}}{qw(w0 h0 w h)}];
		push @xml,   [sprintf('<imgdata width_original="%d" width="%d" height_original="%d" height="%d">',
													@{$img_data->{size}}{qw(w0 w h0 h)})];
		$json->{file} = {filename=>$img_data->{file},
										 w0=>$img_data->{size}{w0},
										 h0=>$img_data->{size}{h0},
										 w=>$img_data->{size}{w},
										 w=>$img_data->{size}{h}};
	}
	if($deltaE) {
		my @values = sort {$a <=> $b} @$deltaE;
		if(@values) {
		push @lines, ["uniformity",
									"mean",mean(@values),
									"median",median(@values),
									"stddev",stddev(@values),
									(map { sprintf("p%d %.2f",$_,$values[@values*$_/100]) } (5,10,25,75,90,95))
								 ];
	}
	}

	if ($cluster_data) {
		push @xml, ["<clusters>"];
		for my $cluster_id ( @{$cluster_data->{id_sorted}} ) {
			my $neighbour = $cluster_data->{id}[$cluster_id]{neighbour};
			my $avg       = $cluster_data->{id}[$cluster_id]{avg};
			push @lines, ["cluster",
										$cluster_id,
										"n",
										$cluster_data->{id}[$cluster_id]{n},
										"f",
										$cluster_data->{id}[$cluster_id]{f},
										"rgb",@{$avg->{rgb}},
										"hex",@{$avg->{hex}},
										"hsv",@{$avg->{hsv}},
										"lab",@{$avg->{lab}},
										"lch",@{$avg->{lch}},
										"xyz",@{$avg->{xyz}},
										"cmyk",@{$avg->{cmyk}},
										(map { $neighbour->{$_} } (qw(neighbours num_neighbours_maxdE tags))),
									 ];
			$json_basic->{data}{"color$cluster_id"} = $avg->{hex}[0];
			$json->{clusters}{$cluster_id} = 
				{ n => $cluster_data->{id}[$cluster_id]{n},
				  f => $cluster_data->{id}[$cluster_id]{f},
					rgb => $avg->{rgb},
					hex => $avg->{hex},
					hsv => $avg->{hsv},
					lch => $avg->{lch},
					xyz => $avg->{xyz},
					cmyk => $avg->{cmyk},
					neighbours=>$neighbour->{neighbours},
					num_neighbours_maxdE=>$neighbour->{num_neighbours_maxdE},
					tags=>$neighbour->{tags}};
			push @xml, [sprintf('<cluster id="%d" n="%d" f="%f">',
													$cluster_id,
													$cluster_data->{id}[$cluster_id]{n},
													$cluster_data->{id}[$cluster_id]{f})];
			push @xml, [sprintf('<rgb r="%s" g="%s" b="%s"/>',@{$avg->{rgb}})];
			push @xml, [sprintf('<hex hex="%s" />',@{$avg->{hex}})];
			push @xml, [sprintf('<hsv h="%s" s="%s" v="%s" />',@{$avg->{hsv}})];
			push @xml, [sprintf('<lab l="%s" a="%s" b="%s" />',@{$avg->{lab}})];
			push @xml, [sprintf('<lch l="%s" c="%s" h="%s" />',@{$avg->{lch}})];
			push @xml, [sprintf('<xyz x="%s" y="%s" z="%s" />',@{$avg->{xyz}})];
			push @xml, [sprintf('<cmyk c="%s" m="%s" y="%s" k="%s" />',@{$avg->{cmyk}})];
			if ($neighbour) {
				push @xml, [sprintf('<neighbours>%s</neighbours>',$neighbour->{neighbours})];
				push @xml, [sprintf('<num_neighbours_maxdE>%s</num_neighbours_maxdE>',$neighbour->{num_neighbours_maxdE})];
				push @xml, [sprintf('<tags>%s</tags>',$neighbour->{tags})];
			}
			push @xml, ["</cluster>"];
		}
		push @xml, ["</clusters>"];
	}

	# aggregate statistics
	if (! defined $args{-stats} || $args{-stats} == 1) {
		push @xml, ["<stats>"];
		for my $space (sort keys %{$histogram_data}) {
			push @xml, ["<$space>"];
			for my $component (sort keys %{$histogram_data->{$space}}) {
				for my $stat (qw(avg median min max)) {
					push @xml, [sprintf('<%s>%f</%s>',$stat,$histogram_data->{$space}{$component}{$stat},$stat)];
					push @lines, ["stat",$space,$component,$stat,$histogram_data->{$space}{$component}{$stat}];
					push @{$json->{stats}{$space}{$component}{$stat}}, $histogram_data->{$space}{$component}{$stat};
				}
			}
			push @xml, ["</$space>"];
		}
		push @xml, ["</stats>"];
	}

	if ($histogram_data) {
		if (! defined $args{-histogram} || $args{-histogram} == 1) {
			push @xml, ["<histogram>"];
			# histogram, if available
			for my $space (sort keys %{$histogram_data}) {
				push @xml, ["<$space>"];
				for my $component (sort keys %{$histogram_data->{$space}}) {
					next unless $histogram_data->{$space}{$component}{hist};
					for my $x (sort {$a <=> $b} keys %{$histogram_data->{$space}{$component}{hist}}) {
						push @xml, [sprintf('<%s bin="%f">%d</%s>',$component,$x,$histogram_data->{$space}{$component}{hist}{$x},$component)];
						push @lines, ["hist",$space,$component,$x,$histogram_data->{$space}{$component}{hist}{$x}];
						push @{$json->{histogram}{$space}{$component}{$x}}, $histogram_data->{$space}{$component}{hist}{$x};
					}
				}
				push @xml, ["</$space>"];
			}
			push @xml, ["</histogram>"];
		}
	}
	
	if (! defined $args{-pixel} || $args{-pixel} == 1) {
		# raw pixel data
		my @space = sort keys %{$img_data->{space}};
		push @xml, ["<pixels>"];
		my @clusters = @{$cluster_data->{clusters}} if $cluster_data;
		for my $y (0..$img_data->{size}{h}-1) {
			for my $x (0..$img_data->{size}{w}-1) {
				my $idx     = $y * $img_data->{size}{w} + $x;
				my $cluster = $cluster_data->{mask}[$idx] ? shift @clusters : -1;
				my @line = ("pix",$x,$y,"cluster",$cluster);
				push @xml, [sprintf('<pixel x="%d" y="%d" cluster="%d">',$x,$y,$cluster_data->{clusters}[$idx])];
				$json->{pixels}{$idx} = {cluster=>$cluster,x=>$x,y=>$y};
				for my $space (@space) {
					my $p = $img_data->{space}{$space}[$idx];
					push @line, ($space,@$p);
					push @xml, [sprintf("<$space>%s</$space>",join(",",@$p))];
					$json->{pixels}{$idx}{$space} = $p;
				}
				push @xml, ["</pixel>"];
				push @lines, [@line];
			}
		}
		push @xml, ["</pixels>"];
	}

	#my $xml_text   = join("\n",map {join(" ",@$_)} @xml);
	#my $dataXML    = XMLin($xml_text);
	my $jsonString  = JSON::XS->new->pretty(1)->encode($json);
	my $jsonString_basic  = JSON::XS->new->pretty(1)->canonical(1)->encode($json_basic);

	push @xml, ["</imgdata>"];
	return (\@lines,\@xml,$jsonString,$jsonString_basic);
}

1;
