package Sprog::GtkView::MakeCommand;

use strict;
use warnings;

use Glib qw(TRUE FALSE);
use Gtk2::GladeXML;

use base qw(
  Sprog::Accessor
);

__PACKAGE__->mk_accessors(qw(
  app
  dialog
  gear_dir
  gear
  types
  title
  command
  keywords
  filename
  custom_filename
));

use Scalar::Util qw(weaken);

my $mini_icons;

use constant HELP_TOPIC => 'Sprog::help::make_command';


sub invoke {
  my($class, $app, $gear_dir, $gear) = @_;

  my $self = $class->new(app => $app, gear_dir => $gear_dir, gear => $gear);

  my $dialog = $self->dialog or return;

  while(my $resp = $dialog->run) {
    if($resp eq 'help') {
#      my $topic = $self->gearview->gear_class;
#      $self->app->show_help(HELP_TOPIC);
      next;
    }
    if($resp eq 'ok') {
      next unless $self->save;
    }
    last;
  }

  $dialog->destroy;
}


sub new { 
  my $class = shift;

  my $self = bless({ @_, custom_filename => 0 }, $class);
  weaken($self->{app});

  return $self->_init;
}


sub _init {
  my $self = shift;

  my $glade_src = $self->glade_xml;
  my $gladexml = Gtk2::GladeXML->new_from_buffer($glade_src);

  $self->dialog($gladexml->get_widget('make_command'));

  my $app  = $self->app;
  my $view = $app->view;

  $mini_icons = $view->chrome_class->mini_icons() unless(defined($mini_icons));
  $gladexml->get_widget('image_input')->set_from_pixbuf($mini_icons->{_P});
  $gladexml->get_widget('image_filter')->set_from_pixbuf($mini_icons->{PP});
  $gladexml->get_widget('image_output')->set_from_pixbuf($mini_icons->{P_});

  $self->types($gladexml->get_widget('gear_type_input')->get_group);
  $self->title($gladexml->get_widget('title'));
  $self->command($gladexml->get_widget('command'));
  $self->keywords($gladexml->get_widget('keywords'));
  $self->filename($gladexml->get_widget('filename'));

  $gladexml->signal_autoconnect_from_package($self);

  return $self;
}


sub on_title_changed {
  my($self, $widget) = @_;

  my $filename = $self->filename or return;
  my $text = $filename->get_text;
  $self->custom_filename(0) if $text eq $self->_default_filename;

  return if $self->custom_filename;

  $filename->set_text($self->_default_filename);
}


sub on_filename_changed {
  my($self, $widget) = @_;

  my $text = $widget->get_text;
  return $self->custom_filename(1) if $text ne $self->_default_filename;

  $self->custom_filename(0);
}


sub _default_filename {
  my $self = shift;

  my $title = $self->title->get_text or return '';
  $title =~ s/[\W_]+/ /g;

  return join('', map { ucfirst lc $_ } split /\s+/, $title) . '.pm';
}


sub save {
  my($self) = @_;

  my $app  = $self->app;
  my $gear = { type => 'input' };

  foreach my $rb (@{ $self->types }) {
    next unless $rb->get_active;
    next unless $rb->get_name =~ /^gear_type_(\w+)/;
    $gear->{type} = $1;
    last;
  };

  $gear->{title}   = $self->title->get_text;
  return $app->alert("You must enter a title") unless length($gear->{title});

  $gear->{command} = $self->command->get_text;
  return $app->alert("You must enter a command") unless length($gear->{command});

  $gear->{keywords} = $self->keywords->get_text;

  $gear->{class} = $self->filename->get_text;
  $gear->{class} =~ s{\.pm?$}{};
  $gear->{class} =~ s{[\W_]}{}g;
  return $app->alert("You must enter a filename") unless length($gear->{class});

  return $self->_write_gear_to_file($gear);
}


sub _write_gear_to_file {
  my($self, $gear) = @_;

  my $app  = $self->app;
  my $dir  = $self->gear_dir;
  my $path = File::Spec->catfile($dir, $gear->{class} . '.pm');

  return if -e $path
            && !$app->confirm_yes_no('Save As', 'File exists.  Overwrite?');

  if($gear->{type} eq 'input') {
    $gear->{conn_in}  = '_';
    $gear->{conn_out} = 'P';
    $gear->{parent}   = 'CommandIn';
  }
  elsif($gear->{type} eq 'filter') {
    $gear->{conn_in}  = 'P';
    $gear->{conn_out} = 'P';
    $gear->{parent}   = 'FilterCommand';
  }
  else {
    $gear->{conn_in}  = 'P';
    $gear->{conn_out} = '_';
    $gear->{parent}   = 'CommandOut';
  }

  $gear->{command} =~ s{([()])}{\\$1}g;

  open my $fh, '>', $path or return $self->app->alert(
    "Error creating $path", "$!"
  );

  print $fh <<"EOF";
package $gear->{class};

=begin sprog-gear-metadata

  title: $gear->{title}
  type_in: $gear->{conn_in}
  type_out: $gear->{conn_out}
  keywords: $gear->{keywords}
  no_properties: 1

=end sprog-gear-metadata

=cut

use strict;

use base qw(Sprog::Gear::$gear->{parent});

__PACKAGE__->declare_properties( -command => undef );

sub command { q($gear->{command}); }

1;
EOF

  close($fh);
  
  $app->init_private_path;  # refresh palette view

  return 1;
}


sub glade_xml {
  return `cat /home/grant/projects/sf/sprog/glade/make_command.glade`;
  return <<'END_XML';

END_XML
}

1;

