package DummyView;

use strict;
use warnings;

use base qw(Sprog::Accessor);

__PACKAGE__->mk_accessors(qw(
  app
));

use Scalar::Util qw(weaken);


sub new {
  my $class = shift;

  my $self = bless { @_ }, $class;

  $self->{app} && weaken($self->{app});

  return $self;
}

# NOP Methods:

sub add_gear_view          { return; }
sub running                { return; }
sub status_message         { return; }
sub set_window_title       { return; }
sub delete_gear_view_by_id { return; }
sub gear_view_by_id        { return; }
sub update_gear_view       { return; }
sub apply_prefs            { return; }
sub sync_run_on_drop       { return; }
sub refresh_palette        { return; }

1;

