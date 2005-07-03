package TestPrefs;


sub new { return bless {}, shift; }

sub get_pref {
  my($self, $key) = @_;
  return $self->{$key};
}

sub set_pref {
  my($self, $key, $val) = @_;
  $self->{$key} = $val;
}


1;
