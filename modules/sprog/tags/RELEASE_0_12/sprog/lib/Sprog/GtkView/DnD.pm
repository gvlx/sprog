package Sprog::GtkView::DnD;

use base qw(Exporter);

our @EXPORT_OK = qw(
  TARG_SPROG_GEAR_CLASS
  TARG_STRING
  SPROG_GEAR_TARGET
  DRAG_FILES_TARGET
);

use constant TARG_STRING            => 0;
use constant TARG_SPROG_GEAR_CLASS  => 20565;

use constant SPROG_GEAR_TARGET => {
                'target' => "application/x-sprog-gear-class", 
                'flags'  => ['same-app'], 
                'info'   => TARG_SPROG_GEAR_CLASS,
             };

use constant DRAG_FILES_TARGET => {
                'target' => "text/plain",
                'flags'  => [],
                'info'   => TARG_STRING
             };


1;

