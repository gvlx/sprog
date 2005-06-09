package Sprog;

use strict;

our $VERSION = '0.09';

use base qw(Class::Accessor::Fast);

use Getopt::Long qw(GetOptions);
use Pod::Usage   qw(pod2usage);
use File::Spec   qw();

__PACKAGE__->mk_accessors(qw(
  factory
  opt
  prefs
  geardb
  machine
  view
  event_loop
));

sub new {
  my $class = shift;

  return bless { @_ }, $class;
}


sub _init {
  my $self = shift;

  my $factory = $self->{factory} or die "No class factory";

  $factory->inject(   # set default classes if not already defined
    '/app/preferences' => 'Sprog::Preferences',
    '/app/geardb'      => 'Sprog::GearMetadata',
    '/app/machine'     => 'Sprog::Machine',
    '/app/help_parser' => 'Sprog::HelpParser',
  );

  if($self->opt->{nogui}) {
    $factory->inject(
      '/app/view'      => 'Sprog::TextView',
      '/app/eventloop' => 'Sprog::GlibEventLoop',
    );
  }
  else {
    $factory->inject(
      '/app/view'      => 'Sprog::GtkView',
      '/app/eventloop' => 'Sprog::GtkEventLoop',
    );
  }

  $self->geardb    ( $factory->load_class('/app/geardb'   ) );
  $self->event_loop( $factory->load_class('/app/eventloop') );
  $self->prefs     ( $factory->make_class('/app/preferences', app => $self) );
  $self->machine   ( $factory->make_class('/app/machine',     app => $self) );
  $self->view      ( $factory->make_class('/app/view',        app => $self) );

  $self->view->apply_prefs;

  return $self;
}

sub run {
  my $self = shift;

  my $opt = $self->_getopt(@_);

  $self->_init;

  $self->load_from_file($opt->{sprog_file}) if $opt->{sprog_file};

  if($opt->{run}) {
    $self->add_idle_handler(sub { $self->run_machine; return 0 });
  }

  $self->event_loop->run;
}


sub _getopt {
  my $self = shift;

  my %opt = ();

  local(@ARGV) = @_;
  if(!GetOptions(\%opt, 
    'help|h|?', 'version|v', 'run|r', 'nogui|n', 'quit|q',
  )) {
    pod2usage({ -exitval => 1,  -verbose => 0,  -input   => _pod_file() });
  }

  if($opt{help}) {
    pod2usage({ -exitval => 0,  -verbose => 2,  -input   => _pod_file() });
  }

  if($opt{version}) {
    print "$VERSION\n";
    exit 0;
  }

  $opt{sprog_file} = shift @ARGV if(@ARGV  and  $ARGV[0] =~ /\.sprog$/i);
  $opt{filenames}  = [ @ARGV ]   if @ARGV;
  $opt{run}        = 1           if $opt{nogui};
  $opt{quit}       = 1           if $opt{nogui};
  $opt{quit}       = 0           unless $opt{sprog_file};

  if($opt{nogui} and !$opt{sprog_file}) {
    pod2usage({
      -message => "<filename.sprog> required in 'nogui' mode.",
      -exitval => 1,  -verbose => 0,  -input   => _pod_file() 
    });
  }

  return $self->opt(\%opt);
}


sub _pod_file {
  foreach (@INC) {
    my $path = File::Spec->catfile($_, qw(Sprog help commandline.pod));
    return $path if -e $path;
  }

  die "Unable to find Sprog::help::commandline.pod";
}


sub inject            { shift->factory->inject(@_);              }
sub make_class        { shift->factory->make_class(@_);          }
sub load_class        { shift->factory->load_class(@_);          }

sub get_pref          { shift->prefs->get_pref(@_);              }
sub set_pref          { shift->prefs->set_pref(@_);              }

sub show_toolbar { my $view = shift->view or return; $view->show_toolbar(); }
sub hide_toolbar { my $view = shift->view or return; $view->hide_toolbar(); }

sub set_toolbar_style { shift->view->set_toolbar_style(@_);      }
sub toggle_palette    { shift->view->toggle_palette();           }
sub show_palette      { shift->view->show_palette();             }
sub hide_palette      { shift->view->hide_palette();             }

sub alert             { shift->view->alert(@_);                  }
sub update_gear_view  { shift->view->update_gear_view(@_);       }
sub status_message    { shift->view->status_message(@_);         }
sub not_implemented   { shift->alert('Not implemented');         }

sub confirm_yes_no    { shift->view->confirm_yes_no(@_);         }

sub drop_gear         { shift->view->drop_gear(@_);              }
sub detach_gear       { shift->machine->detach_gear(@_);         }

sub file_new          { shift->not_implemented();                }


sub quit              { shift->event_loop->quit();               }
sub add_timeout       { shift->event_loop->add_timeout(@_);      }
sub add_idle_handler  { shift->event_loop->add_idle_handler(@_); }
sub add_io_reader     { shift->event_loop->add_io_reader(@_);    }
sub add_io_writer     { shift->event_loop->add_io_writer(@_);    }

sub show_help         { shift->view->show_help(@_);              }
sub help_contents     { shift->show_help('Sprog::help::index');  }


sub file_open {
  my $self = shift;

  my $filename = $self->view->file_open_filename or return;
  $self->load_from_file($filename);
}


sub file_save {
  my $self = shift;

  my $filename = $self->filename or return $self->file_save_as;
  $self->machine->save_to_file($filename);
}


sub file_save_as {
  my $self = shift;

  my $filename = $self->view->file_save_as_filename or return;
  $self->machine->save_to_file($filename) or return;
  $self->filename($filename);
}


sub load_from_file {
  my($self, $filename) = @_;

  $self->machine->expunge;
  $self->machine->load_from_file($filename) or return;
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

  my $gear = $self->machine->add_gear($gear_class, x => $x, y => $y) or return;
  $self->view->add_gear_view($gear);

  return $gear;
}

sub run_machine {
  my $self = shift;

  $self->machine->run;
}


sub stop_machine {
  my $self = shift;
  $self->machine->stop;
}


sub machine_running {
  my $self = shift;

  if(@_) {
    return $self->quit if($self->opt->{quit} and !$_[0]);
    $self->view->running(@_);
  }
  return $self->machine->running(@_);
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

sub help_about {
  shift->view->help_about({
    app_detail       => "Sprog $VERSION",
    copyright        => '(C) 2004-2005 Grant McLean <grantm@cpan.org>',
    project_url      => 'http://sprog.sourceforge.net/',
  });
}

1;

__END__


=head1 NAME

Sprog - Scripting for the GUI Guys

=head1 SYNOPSIS

The C<sprog> script (included in the distribution) is a simple wrapper which
instantiates an object of class C<Sprog> and calls its C<run> method:

  use Sprog::ClassFactory;

  make_app()->run(@ARGV);

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

The Sprog code is in 'alpha' state.  This means that bugs are not only
possible, they're expected.  It also means that the API is still stablising -
if you write a component today you might need to tweak it to make it work with
the next version of Sprog.  

Please don't let the alpha status discourage you - the more people that try it
out and report their experiences, the sooner the bugs will get shaken out.

=head1 PREREQUISITES

All the classes are built on top of L<Class::Accessor>.

The GUI and event-driven scheduler is built on L<Gtk2> and the
L<Gnome2::Canvas> (although the GNOME desktop environment is not required).

The properties auto-dialog (PAD) framework uses L<Gtk2::GladeXML>.

File save and restore uses L<YAML>.

The help viewer uses L<Pod::Simple>.

If you don't already have gtk2-perl installed then you may find that is a major
hurdle.  Of course if you're running Debian GNU/Linux then you'll just need to
run:

  apt-get install libgtk2-perl libgnome2-canvas-perl libgtk2-gladexml-perl \
          libclass-accessor-perl libyaml-perl libpod-simple-perl

=head1 SEE ALSO

When you run Sprog, you will find information both for users and for developers
in the help viewer - accessed via the F1 key (or the help menu).

The Sprog web site is hosted by SourceForge at: L<http://sprog.sourceforge.net/>

=head1 COPYRIGHT 

Copyright 2004-2005 Grant McLean E<lt>grantm@cpan.orgE<gt>

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself. 

=cut

