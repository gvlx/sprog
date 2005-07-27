package Sprog::Accessor;

use strict;
use warnings;

use Carp;

sub mk_accessors {
  my $class = shift;

  foreach (@_) {
    my($prefix, $method) = (/^(-)?(.*)/);

    if($prefix and $prefix eq '-') {
      no strict 'refs';
      *{$class . '::' . $method} =
        sub {
          my $self = shift;
          croak "'$method' is a read-only property of $class'" if @_;
          return $self->{$method};
        };
    }
    else {
      no strict 'refs';
      *{$class . '::' . $method} =
        sub {
          my $self = shift;
          $self->{$method} = shift if @_;
          return $self->{$method};
        };
    }

  }
}


sub new {
  my $class = shift;

  my $self = bless { @_ }, $class;
}

1;

__END__


