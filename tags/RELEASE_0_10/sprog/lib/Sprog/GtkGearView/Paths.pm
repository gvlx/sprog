package Sprog::GtkGearView::Paths;

use strict;

use Glib qw(TRUE FALSE);

use Sprog::GtkAutoDialog;

use constant gBW  => 300;   # Gear Block Width
use constant gBH  =>  40;   # Gear Block Height
use constant gCW  =>  24;   # Gear Connector Width
use constant gCH  =>  12;   # Gear Connector Height
use constant gCR  =>   8;   # Gear Corner Radius

use constant gIN  => 0;
use constant gOUT => 1;

my %path;  # for path cache

my %offsets_by_type = (

  P => [
         [
           [0,          gCH],
           [gCW,        gCH],
           [gCW,        0],
         ],
         [
           [0,          gCH],
           [gCW * -1,   gCH],
           [gCW * -1,   0],
         ],
       ],

  A => [
         [
           [0,          gCH],
           [gCW/3,      gCH],
           [gCW/3,      gCH/2],
           [2 * gCW/3,  gCH/2],
           [2 * gCW/3,  gCH],
           [gCW,        gCH],
           [gCW,        0],
         ],
         [
           [0,          gCH],
           [gCW/3 * -1, gCH],
           [gCW/3 * -1, gCH/2],
           [gCW/3 * -2, gCH/2],
           [gCW/3 * -2, gCH],
           [gCW * -1,   gCH],
           [gCW * -1,   0],
         ],
       ],

  H => [
         [
           [0,          gCH * 0.6],
           [gCW/2,      gCH * 1.3],
           [gCW,        gCH * 0.6],
           [gCW,        0],
         ],
         [
           [0,          gCH * 0.6],
           [gCW/2 * -1, gCH * 1.3],
           [gCW * -1,   gCH * 0.6],
           [gCW * -1,   0],
         ],
       ],

  X => [
         [
           [gCW/3,      gCH/2],
           [0,          gCH],
           [gCW,        gCH],
           [gCW/3 * 2,  gCH/2],
           [gCW,        0],
         ],
         [
           [gCW/3 * -1, gCH/2],
           [0,          gCH],
           [gCW * -1,   gCH],
           [gCW/3 * -2, gCH/2],
           [gCW * -1,   0],
         ],
       ],

  D => [     # Inverted T
         [
           [gCW/3,      0],
           [gCW/3,      gCH/2],
           [0,          gCH/2],
           [0,          gCH],
         # [gCW/2,      gCH * 1.5],
           [gCW,        gCH],
           [gCW,        gCH/2],
           [2 * gCW/3,  gCH/2],
           [2 * gCW/3,  0],
           [gCW,        0],
         ],
         [
           [gCW/3 * -1, 0],
           [gCW/3 * -1, gCH/2],
           [0,          gCH/2],
           [0,          gCH],
         # [gCW/2 * -1, gCH * 1.5],
           [gCW * -1,   gCH],
           [gCW * -1,   gCH/2],
           [gCW/3 * -2, gCH/2],
           [gCW/3 * -2, 0],
           [gCW * -1,   0],
         ],
       ],

);


sub gear_path {
  my($self, $gear) = @_;

  my $type_in  = $gear->input_type;
  my $type_out = $gear->output_type;
  my $r2 = gCR / 2;

  my($x, $y) = (0, 0);

  my $p = Gnome2::Canvas::PathDef->new;
  $p->moveto($x + gCR, $y);
  $p->lineto($x + gCW, $y);

  if($type_in) {
    $self->draw_connector($p, $type_in, $x + gCW, $y, gIN);
  }

  $p->lineto($x + gBW - gCR, $y);

  $p->curveto($x + gBW - $r2, $y, $x + gBW, $y + $r2, $x + gBW, $y + gCR);

  $p->lineto($x + gBW, $y + gBH - gCR);
  
  $p->curveto($x + gBW, $y + gBH - $r2, $x + gBW - $r2, $y + gBH, $x + gBW - gCR, $y + gBH);

  $p->lineto($x + gCW + gCW, $y + gBH);

  if($type_out) {
    $self->draw_connector($p, $type_out, $x + gCW + gCW, $y + gBH, gOUT);
  }
  
  $p->lineto($x + gCR, $y + gBH);

  $p->curveto($x + $r2, $y + gBH, $x, $y + gBH - $r2, $x, $y + gBH - gCR);

  $p->lineto($x, $y + gCR);

  $p->curveto($x, $y + $r2, $x + $r2, $y, $x + gCR, $y);

  $p->closepath;

  return $p;
}


sub draw_connector {
  my($self, $p, $type, $x, $y, $i) = @_;

  my $offsets = $offsets_by_type{$type}->[$i];
  foreach (@$offsets) {
    $p->lineto($x + $_->[0], $y + $_->[1]);
  }
}


1;


