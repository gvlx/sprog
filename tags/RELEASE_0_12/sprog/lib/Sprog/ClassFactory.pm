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
    $self->{$path} = $class unless exists $self->{$path};
  }
}


sub override {
  my $self = shift;

  while(@_) {
    my $path  = shift;
    my $class = shift;
    $self->{$path} = $class;
  }
}


sub load_class {
  my($self, $path) = @_;

  my $class;
  eval {
    $class = $self->{$path} or die "No class registered for '$path'\n";

    my $class_file = $class . '.pm';
    $class_file =~ s{::}{/}g;

    require $class_file;
  };
  croak "$@" if($@);

  return $class;
}


sub make_class {
  my($self, $path, @args) = @_;

  my $obj = eval {
    my $class = $self->load_class($path);
    $class->new(@args);
  };
  croak "$@" if($@);

  return $obj;
}

1;

__END__

=head1 NAME

Sprog::ClassFactory - simple dependency injection framework for Sprog

=head1 SYNOPSIS

To use all the default classes:

  use Sprog::ClassFactory;

  make_app()->run(@ARGV);

To override defaults:

  make_app(
    '/app/view'  =>  'Sprog::TextView',      # Yeah right
  )->run(@ARGV);

=head1 DESCRIPTION

This class provides a very simple framework for abstracting the building of
classes for the Sprog application.  The primary aim is to support the test
suite.

=head1 EXPORTED FUNCTIONS

=head2 make_app

This function is exported into the caller's namespace.  It is usually called
with no arguments and returns an application object of class L<Sprog>.  The
application object is passed the factory object, which is used to create
classes for the various components of the application.

The default classes used for each component are hardcoded in the class that
requires them.  However, those defaults are passed through this factory class
to provide a central location for declaring alternative classes.

=head1 METHODS

=head2 new ( path => class, ... )

The constructor is called automatically from C<make_app> and returns a factory
object which maps abstract paths of the form '/app/view' to concrete class
names of the form 'Sprog::GtkView'.

=head2 inject ( path => class, ... )

This method can be called at any time to add a new path to class mapping.
If the specified path is already mapped to a class, this method will silently
do nothing.

=head2 override ( path => class, ... )

This method is exactly the same as C<inject> except it will replace a path
that is already mapped.

=head2 make_class ( path, args )

Creates an object of the class defined for the specified path.  Throws a
fatal exception if no class is defined for C<path>.  Any arguments are passed
to the class constructor.

=head2 load_class ( path )

Determines the class name for the specified path; C<require>'s the class and
returns its name.  Useful for when you need to call methods in the class other
than the constructor.

=head1 COPYRIGHT 

Copyright 2005 Grant McLean E<lt>grantm@cpan.orgE<gt>

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself. 

=cut

