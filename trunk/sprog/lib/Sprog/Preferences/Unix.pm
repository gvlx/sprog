package Sprog::Preferences::Unix;


use base qw(Sprog::Preferences);

use YAML;
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

  my $home_dir = $ENV{HOME} || (getpwuid($>))[7];

  die "Unable to locate home directory for user preferences file\n" 
    unless $home_dir;

  $prefs_path = "$home_dir/.sprog";

  if(-e $prefs_path) {
    $self->_read_prefs_file
  }
  else {
    $prefs_data = { };
  }
}


sub _read_prefs_file {
  my $self = shift;

  open my $in, '<', $prefs_path
    or die "Error reading $prefs_path: $!\n";

  local($/) = undef;
  my $yaml = <$in>;

  $prefs_data = eval { YAML::Load($yaml); };
  if($@) {
    warn "User preferences file ($prefs_path) appears to be corrupt\n$@\n";
    $@ = '';
    $prefs_data = { };
  }
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
  open my $out, '>', $prefs_path
    or die "Error saving preferences $prefs_path: $!\n";

  print $out YAML::Dump($prefs_data);
}

1;

