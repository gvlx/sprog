package Sprog::TextGearView;

use strict;

use base qw(Sprog::Accessor);

__PACKAGE__->mk_accessors(qw(
  app
));

use Scalar::Util qw(weaken);

sub new {
  my $class = shift;

  my $self = bless { @_ }, $class;
  weaken($self->{app});

  return $self;
}


# NULL-methods - placeholders

sub set_title_text { }


1;


__END__


=head1 NAME

Sprog::TextGearView - a text-mode 'view' for a Sprog gear

=head1 DESCRIPTION

This class implements the 'view' logic for a gear when running in C<--nogui>
mode.  It performs no useful function other than providing empty
implementations of methods which the L<Sprog> application requires.

Gears may implement custom gear view classes which inherit from this class (and
presumably add useful text-mode functionality).  For example, the
L<Sprog::Gear::TextWindow> uses the custom view class
L<Sprog::TextGearView::TextWindow> which outputs text to STDOUT rather than to
a window.

=head1 CLASS METHODS

=head2 new ( key => value, ... )

Constructor.  Called from L<Sprog::TextView>.

=head1 COPYRIGHT 

Copyright 2005 Grant McLean E<lt>grantm@cpan.orgE<gt>

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself. 

=cut

