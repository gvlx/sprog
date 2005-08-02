package Sprog::Gear::ChartWindow;

=begin sprog-gear-metadata

  title: Chart Window
  type_in: A
  type_out: _
  view_subclass: ChartWindow

=end sprog-gear-metadata

=cut

#  view_subclass: ChartWindow

use strict;

use base qw(Sprog::Gear);

sub file_start {
  my $self = shift;

  $self->{_data} = [];
  $self->{_index} = 0;

  my $gear_view = $self->app->view->gear_view_by_id($self->id);
  $gear_view->reset;
}

sub row {
  my($self, $row) = @_;

  my $i = $self->{_index}++;
  my $cols = @$row;
  foreach my $j (0..$cols-1) {    # storage is rotated 90 degrees
    $self->{_data}->[$j]->[$i] = $row->[$j];
  }
}


sub file_end {
  my $self = shift;

  my @headers;
  my $data = $self->{_data};
  return unless @$data;
  foreach (@$data) {
    push @headers, shift @$_;
  }

  my $gear_view = $self->app->view->gear_view_by_id($self->id);
  $gear_view->show_chart;
}


sub data_series { return shift->{_data}; }

1;

