
package colordebug;

use strict;
use Time::HiRes;

sub printdebug {
  printinfo("debug",@_) if $main::CONF{debug};
}

sub printdumper {
  printinfo(Dumper(@_));
}

sub printinfo {
  printf("%s\n",join(" ",@_));
}

sub printerr {
  printf STDERR ("%s\n",join(" ",@_));
}

sub printtimer {
  my $t0 = shift;
  printinfo(sprintf("timer %.2f",tv_interval($t0)));
}

1;
