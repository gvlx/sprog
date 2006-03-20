package Sprog::Preferences;

use strict;
use warnings;

sub new {
  my $class = shift;
  
  my $prefs_class = $class . '::' . $class->_select_os_subclass;

  eval "use $prefs_class;";
  die($@) if $@;
  
  return $prefs_class->new(@_);
}

sub _select_os_subclass {
  my $class = shift;

  return 'Win32' if $^O =~ /win32/i;
  return 'Unix'  if -d '/etc';

  die "No preferences support for '$^O' operating system\n";
}


1;

