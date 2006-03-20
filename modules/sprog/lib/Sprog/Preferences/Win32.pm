package Sprog::Preferences::Win32;

# This module is just a placeholder - real implementation to follow

use base qw(Sprog::Preferences);

use Scalar::Util qw(weaken);


my $prefs_path = undef;
my $prefs_data = undef;

sub new {
  my $class = shift;

  my $self = bless { @_ }, $class;
  weaken($self->{app});

  $self->_init;

  return $self
}

sub app { shift->{app}; };

sub _init {
  my $self = shift;

  # dummy initialisation stuff
  $prefs_data = { };
}


sub get_pref {
  my($self, $key) = @_;

  return $prefs_data->{$key};
}


sub set_pref {
  my($self, $key, $value) = @_;

  $prefs_data->{$key} = $value;
  $self->save;
}


sub save {
  my $self = shift;

  # Hmm, where shall I stick it?
}


1;

