package Sprog;

use strict;
use Sprog::Machine;
use Sprog::GtkView;

our $VERSION = '0.04';

use base qw(Class::Accessor::Fast);

__PACKAGE__->mk_accessors(qw(
  machine
  view
));

sub new {
  my $class = shift;

  my $self = bless { @_ }, $class;
  $self->machine( Sprog::Machine->new(app => $self) );

  return $self;
}

sub gtk_app {
  my($class) = @_;

  my $self = $class->new;

  $self->view( Sprog::GtkView->new(app => $self) );
  return $self;
}

sub run {
  my $self = shift;
  
  $self->load_from_file(shift) if(@_);

  $self->view->run;
}


sub alert        { shift->view->alert(@_);           }
sub drop_gear    { shift->view->drop_gear(@_);       }

sub detach_gear  { shift->machine->detach_gear(@_);  }

sub add_idle_handler { shift->view->add_idle_handler(@_); }
sub add_io_reader    { shift->view->add_io_reader(@_);    }

sub not_implemented  { shift->alert('Not implemented');   }

sub file_new         { shift->alert('Not implemented');   }


sub file_open {
  my $self = shift;

  my $filename = $self->view->file_open_filename || return;
  $self->load_from_file($filename);
}


sub file_save {
  my $self = shift;

  my $filename = $self->filename || return $self->file_save_as;
  $self->machine->save_to_file($filename);
}


sub file_save_as {
  my $self = shift;

  my $filename = $self->view->file_save_as_filename || return;
  $self->machine->save_to_file($filename) || return;
  $self->filename($filename);
}


sub load_from_file {
  my($self, $filename) = @_;

  $self->machine->expunge;
  $self->machine->load_from_file($filename) || return;
  $self->filename($filename);
}


sub filename {
  my $self = shift;

  if(@_) {
    $self->{filename} = shift;
    $self->view->set_window_title;
  }

  return $self->{filename};
}


sub add_gear_at_x_y {
  my($self, $gear_class, $x, $y) = @_;

  my $gear = $self->machine->add_gear($gear_class, x => $x, y => $y);
  $self->view->add_gear_view($gear);

  return $gear;
}

sub show_palette     { shift->alert('Not implemented');   }

sub run_machine {
  my $self = shift;

  my $machine = $self->machine;
  $machine->build_gear_train || return;

  $self->machine_running(1);

  $machine->enable_idle_handler;
}


sub stop_machine {
  my $self = shift;
  $self->machine->stop;
}


sub machine_running {
  my $self = shift;

  $self->view->running(@_);
  $self->machine->running(@_);
}


sub require_class {
  my($self, $class) = @_;
  
  my $path = $class . '.pm';
  $path =~ s{::}{/}g;

  require $path;
}


sub delete_gear_by_id {
  my($self, $id) = @_;

  $self->machine->delete_gear_by_id($id);
  $self->view->delete_gear_view_by_id($id);
}

=head1 NAME

Sprog - GUI with a Perl centre

=head1 SYNOPSIS

  #!/usr/bin/perl -w

  use strict;
  use Sprog;

  Sprog->gtk_app->run;

=head1 DESCRIPTION

Sprog is a GUI tool for building pipelines to process data.  It allows you to
select a data source; hook up some filter components and an output component;
then feed your data through.

In Sprog jargon, the components are called 'gears' and the assembled result is
called a 'machine'.  Sprog ships with a number of pre-written gears - most of
which are configurable.  It's relatively straightforward to write your own
gears using the supplied framework.  This allows you to make reusable
components for the data transformations you use most often.

=head1 WARNING

The Sprog code is in 'pre-alpha' state.  This means that bugs are not only
possible, they're expected.

The 'pre-alpha' state also means that the API is not yet stable - if you write
a component today you might need to tweak it to make it work with the next
version of Sprog.

=head1 PREREQUISITES

All the classes are built on top of L<Class::Accessor>.

The GUI and event-driven scheduler is built on L<Gtk2>.

The properties auto-dialog (PAD) framework uses L<Gtk2::GladeXML>.

If you don't already have gtk2-perl installed then you may find that is a major
hurdle.  Of course if you're running Debian GNU/Linux then you'll just need to
run:

  apt-get install libgtk2-perl libgnome2-canvas-perl libgtk2-gladexml-perl \
          libclass-accessor-perl

=head1 SEE ALSO

L<Sprog::internals> contains notes for developers.

The Sprog web site is hosted by SourceForge at: L<http://sprog.sourceforge.net/>

=head1 COPYRIGHT 

Copyright 2004 Grant McLean E<lt>grantm@cpan.orgE<gt>

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself. 

=cut

1;
