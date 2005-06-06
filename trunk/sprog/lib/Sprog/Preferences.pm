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


sub _deferred_save {
  my $self = shift;

  $self->{_last_update} = time();

  return if $self->{_time_tag};

  $self->{_time_tag} = $self->app->add_timeout(3000, sub {
    return 1 if time() - $self->{_last_update} < 3;
    $self->save;
    delete $self->{_time_tag};
    return 0;
  });
}


1;

