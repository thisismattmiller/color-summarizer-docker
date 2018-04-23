
package colors;

sub allocate {

  my $im = shift;
  my $colors = {

    white   => $im->colorAllocate(255,255,255),
    black   => $im->colorAllocate(0,0,0),

    vlgrey  => $im->colorAllocate(240,240,240),
    lgrey   => $im->colorAllocate(220,220,220),
    grey    => $im->colorAllocate(200,200,200),
    dgrey   => $im->colorAllocate(170,170,170),
    vdgrey  => $im->colorAllocate(140,140,140),

    lred    => $im->colorAllocate(255,120,120),
    red     => $im->colorAllocate(255,0,0),
    dred    => $im->colorAllocate(180,0,0),

    lgreen   => $im->colorAllocate(180,255,180),
    green   => $im->colorAllocate(0,255,0),
    dgreen  => $im->colorAllocate(0,180,0),

    vlblue  => $im->colorAllocate(0,192,255),
    lblue    => $im->colorAllocate(120,120,255),
    blue    => $im->colorAllocate(0,0,255),
    dblue    => $im->colorAllocate(0,0,180),
    vdblue  =>	 $im->colorAllocate(0,128,170),

    lpurple  => $im->colorAllocate(224,120,255),
    purple  => $im->colorAllocate(204,0,255),
    dpurple  => $im->colorAllocate(130,0,180),

    lyellow  => $im->colorAllocate(255,255,180),
    yellow  => $im->colorAllocate(255,255,0),
    dyellow  => $im->colorAllocate(200,200,0),

    lorange  => $im->colorAllocate(255,224,120),
    orange  => $im->colorAllocate(255,204,0),
    dorange => $im->colorAllocate(180,130,0),

    # cytogenetic colours in keeping with Ensembl's colour scheme

    gpos100 => $im->colorAllocate(0,0,0),
    gpos    => $im->colorAllocate(0,0,0),
    gpos75  => $im->colorAllocate(130,130,130),
    gpos50  => $im->colorAllocate(200,200,200),
    gpos25  => $im->colorAllocate(200,200,200),
    gvar    => $im->colorAllocate(220,220,220),
    acen    => $im->colorAllocate(255,0,0),
    gneg    => $im->colorAllocate(255,255,255),

    select  => $im->colorAllocate(58,255,58),

  };
  return $colors;


}

1;
