package Sprog::ClassFactory;

use strict;

use Carp;

use Exporter qw(import);

our @EXPORT_OK = qw(make_app);
our @EXPORT    = qw(make_app);


sub make_app {
  my $factory = __PACKAGE__->new(@_);

  $factory->inject('/app' => 'Sprog');

  return $factory->make_class('/app', factory => $factory);
}


sub new {
  my $class = shift;

  return bless { @_ }, $class;
}


sub inject {
  my $self = shift;

  while(@_) {
    my $path  = shift;
    my $class = shift;
    $self->{$path} ||= $class;
  }
}


sub make_class {
  my($self, $path, @args) = @_;

  my $obj = eval {
    my $class = $self->{$path} || die "No class registered for '$path'";

    my $class_path = $class . '.pm';
    $class_path =~ s{::}{/}g;

    require $class_path;

    $class->new(@_);
  };
  croak "$@" if($@);

  return $obj;
}

1;

