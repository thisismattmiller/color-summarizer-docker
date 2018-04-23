
package imagehandler;

use strict;
use Math::VecStat qw(sum min max average);

sub resize_image {
  my $im = shift;
  my $maxdim = shift;
  my ($w,$h) = ($im->Get("width"),$im->Get("height"));
  if ($maxdim && scalar(max($w,$h)) > $maxdim) {
    my ($w_new,$h_new);
    if ($w > $h) {
      $w_new = $maxdim;
      $h_new = $w_new/$w * $h;
    } else {
      $h_new = $maxdim;
      $w_new = $h_new/$h * $w;
    }
    $im->Resize(width=>$w_new,height=>$h_new);
  }
  return $im;
}

1;
