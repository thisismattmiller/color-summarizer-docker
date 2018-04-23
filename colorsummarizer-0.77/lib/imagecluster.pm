
################################################################
#
# Cluster colors in image data sampled with imagesample::sample_image
# and return color and number of pixels in each cluster
#
package imagecluster;

use strict;
use File::Basename;
use Math::Round;
use Data::Dumper;
use Graphics::ColorObject;
use Math::VecStat qw(average sum);
use Algorithm::Cluster qw(kcluster);

use colorspace;

sub cluster_image_colors {
	my %args        = @_;
	my $imgdata     = $args{-imgdata};
	my $coordmask   = $args{-coordmask};
	my $coordweight = $args{-coordweight};
	my $retrysol    = $args{-retrysol};
	my $minnsol     = $args{-minnsol};
	my $retrysolt   = $args{-retrysolt};
	my $minnsolt    = $args{-minnsolt};
	my $nclusters   = $args{-nclusters};
	my $space       = $args{-space};
	my $npass       = $args{-npass};
	my $clipwhite   = $args{-clipwhite};
	my $clipblack   = $args{-clipblack};
	my $clipalpha   = $args{-clipalpha};
	my $clipgreen   = $args{-clipgreen};
	my $make_images = $args{-make_images};
	my $file        = $args{-file};

	return undef if ! $imgdata->{space}{$space};

	# $clusters - list of cluster id for each element in data
	# $error    - total distance between points and their clusters (not used)
	# $found    - number of times optimal solution was found       (not used)

	my $imgdata_to_cluster;
	my $mask;

	&colordebug::printdebug("generating cluster mask...",$clipalpha);
	for my $i (0..@{$imgdata->{space}{$space}}-1) {
		my @rgb          = @{$imgdata->{space}{rgb}[$i]};
		my $alpha        = $rgb[3];
		my @color_coords = @{$imgdata->{space}{$space}[$i]};
		my $use_pixel    = 1;
		if($clipalpha && $imgdata->{channels} == 4 && $alpha < 255) {
			# Make sure that the image has 4 channels to test for transparency.
			# If we only have 3 channels, the alpha is retrieved as 0, which is
			# indistinguishable from transparent.
			$use_pixel     = 0;
		}
		if($clipblack && !$rgb[0]      && !$rgb[1]        && !$rgb[2]       ) {
			$use_pixel     = 0;
		}
		if($clipwhite && $rgb[0] == 255 && $rgb[1] == 255 && $rgb[2] == 255 ) {
			$use_pixel     = 0;
		}
		if($clipgreen && $rgb[0] == 0   && $rgb[1] == 255 && $rgb[2] == 0   ) {
			$use_pixel     = 0;
		}
		if($use_pixel) {
			push @$mask, 1;
			my $coord_to_cluster = $imgdata->{space}{$space}[$i];
			push @$imgdata_to_cluster, $coord_to_cluster;
		} else {
			#colordebug::printdebug("clipped",@rgb);
			push @$mask, 0;
		}
	}
	&colordebug::printdebug("using",sum(@$mask)."/".int(@$mask),"pixels");
	my %kcluster_param = (
												nclusters =>  $nclusters,
												transpose => 0,
												npass     => $npass || 10,
												mask      => [split(",",$coordmask)],
												weight    => [split(",",$coordweight)],
												method    => $args{-method} || "a",
												dist      => $args{-dist}   || "e",
											 );

	my $skip = 0;
	my ($clusters,$error,$found);
	my ($this_clusters,$this_error,$this_found);
	do {
		&colordebug::printdebug("applying k-means...");
		($this_clusters,$this_error,$this_found) = kcluster(%kcluster_param,data=>$imgdata_to_cluster);
		if( (! defined $error || $this_error < $error) ||
				(! defined $found || $this_found > $found) ) {
			($clusters,$error,$found) = ($this_clusters,$this_error,$this_found);
		}
		&colordebug::printdebug("k-means","error",$error,"solution found",$found."/$npass","times","need",$minnsol);
		if($minnsolt && $skip && not ($skip % $retrysolt)) {
			$minnsol -= $minnsolt if $minnsolt;
		}
	} while($this_found < $minnsol && ++$skip < $retrysol);

	&colordebug::printdebug("sol","error",$error,"solution found",$found."/$npass","times");

	$clusters = remap_cluster_ids($clusters);

	# $cluster_data->{id}[ID]{value}      = [ [a1,b1,c1], [a2,b2,c2], ... ] list of colors in cluster
	# $cluster_data->{id}[ID]{avg}{SPACE} = [a,b,c] average color in cluster for color space SPACE
	# $cluster_data->{id}[ID]{n}          = number of pixels in cluster
	# $cluster_data->{id}[ID]{f}          = fraction of pixels in cluster
	# $cluster_data->{id}[ID]{rank}       = cluster rank (0,1...) in desc order of total pixels in cluster

	my $cluster_data = { clusters => $clusters,
										   mask     => $mask };
	for my $i (0..@$clusters-1) {
		my $cluster_id = $clusters->[$i];
		my $imgvalue   = $imgdata->{space}{$space}[$i]; # $imgdata_to_cluster->[$i];
		push @{$cluster_data->{id}[$cluster_id]{value}}, $imgvalue;
		$cluster_data->{id}[$cluster_id]{n}++;
	}

	my $rank = 0;
	for my $cluster_id (sort {$cluster_data->{id}[$b]{n} <=> $cluster_data->{id}[$a]{n}} 0..@{$cluster_data->{id}}-1) {

		push @{$cluster_data->{id_sorted}}, $cluster_id;

		my $this_cluster = $cluster_data->{id}[$cluster_id];

		$this_cluster->{f}    = $cluster_data->{id}[$cluster_id]{n} / @$clusters;
		$this_cluster->{rank} = $rank++;

		&colordebug::printdebug("processing cluster",$cluster_id,$this_cluster->{n},$this_cluster->{f});
		# pixel values for this cluster
		my $values      = $this_cluster->{value};
		my @cluster_avg = ( average( map { $_->[0] } @$values),
												average( map { $_->[1] } @$values),
												average( map { $_->[2] } @$values) );
		my $fn_new = colorspace::caller_new($space);
		$this_cluster->{avg}{$space} = [ colorspace::format_coordinates($space,@cluster_avg) ];
		my $cobj   = Graphics::ColorObject->$fn_new(\@cluster_avg);
		for my $space (qw(rgb hsv lch hex cmyk luv xyz)) {
			$this_cluster->{avg}{$space} =	[ colorspace::convert($cobj,$space) ];
		}
	}

	if(defined $make_images) {
		my $outdir = $make_images != 1 ? $make_images : dirname($file);
		&colordebug::printdebug("making cluster thumbnails to $outdir");
		die "Cannot find requested output directory [$outdir] for file [$file]" if ! -d $outdir;
		die "Cannot write to requested output directory $outdir" if ! -w $outdir;

		make_images(
								-imgdata     => $imgdata,
								-clusterdata => $cluster_data,
								-mask        => $mask,
								-outdir      => $outdir,
								-file        => $file,
							 );
	}

	return $cluster_data;
}

# kmeans assigns IDs to clusters arbitrarily. Here, remap
# them so that the IDs are numbered in descending order
# of membership
sub remap_cluster_ids {
	my $clusters = shift;

	# renumber the clusters so that they are ordered by number of pixels
	my $cluster_count;
	for my $i (@$clusters) {
		$cluster_count->{$i}++;
	}

	my @sorted_cluster_id = sort { $cluster_count->{$b} <=> $cluster_count->{$a} } keys %$cluster_count;
	my $new_cluster_id;
	for my $i (0 .. @sorted_cluster_id-1) {
		$new_cluster_id->{ $sorted_cluster_id[$i] } = $i;
	}
	return [ map { $new_cluster_id->{$_} } @$clusters ];
}


# create images, same size as input image, for each cluster of pixels in that cluster

sub make_images {
	my %args         = @_;

	my $imgdata      = $args{-imgdata};
	my $cluster_data = $args{-clusterdata};
	my $mask         = $args{-mask};
	my $file         = $args{-file};
	my $outdir       = $args{-outdir};

	my $ims;
	# generate thumbnails for each cluster
	my ($w,$h) = @{$imgdata->{size}}{qw(w h)};
	my $white  = Imager::Color->new(255,255,255);
	for my $cluster_id ( @{$cluster_data->{id_sorted}} ) {
		$ims->[$cluster_id] = Imager->new(xsize=>$w,ysize=>$h);
		$ims->[$cluster_id]->flood_fill(x=>0,y=>0,color=>$white);
	}
	my ($i,$ii) = (0,0);
	for my $y (0..$h-1) {
		for my $x (0..$w-1) {
			# index in array - row dominant
			my $idx = $i; # $y * $w + $x;
			next if ! $mask->[$ii++];
			#&colordebug::printinfo($x,$y,@{$imgdata->{pixel}[$idx]});
			# this pixel has been clipped for clusteringau
			# next if ! $cluster_data->{mask}[$idx];
			my $cluster_id = $cluster_data->{clusters}[ $idx ];
			my $rgb        = $imgdata->{space}{rgb}[$ii];
			$ims->[$cluster_id]->setpixel(x=>$x,y=>$y,color=>Imager::Color->new(@$rgb[0..2]));
			$i++;
		}
	}
	$cluster_data->{images} = $ims;
	my $i = 0;
	my $root_file_name = fileparse($file);
	$root_file_name =~ s/[.][^.]+//;
	for my $img (@{$cluster_data->{images}}) {
		my $file_name = sprintf("%s/%s-cluster-%d.jpg",$outdir,$root_file_name,$i);
		&colordebug::printdebug("writing cluster $i for $root_file_name to",$file_name);
		$img->write(file=>$file_name) || die Imager->errstr;
		$i++;
	}
}

1;
