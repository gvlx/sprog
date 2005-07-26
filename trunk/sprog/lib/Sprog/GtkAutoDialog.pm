package Sprog::GtkAutoDialog;

use strict;

use base qw(Sprog::Accessor);

__PACKAGE__->mk_accessors(qw(
  gearview
));

use Glib qw(TRUE FALSE);
use Gtk2::GladeXML;

my %widget_class_map = (
  'Gtk2::Entry'       => 'Sprog::GtkAutoDialog::Entry',
  'Gtk2::CheckButton' => 'Sprog::GtkAutoDialog::CheckButton',
  'Gtk2::RadioButton' => 'Sprog::GtkAutoDialog::RadioButton',
  'Gtk2::TextView'    => 'Sprog::GtkAutoDialog::TextView',
  'Gtk2::SpinButton'  => 'Sprog::GtkAutoDialog::SpinButton',
  'Gtk2::ColorButton' => 'Sprog::GtkAutoDialog::ColorButton',
);


sub new {
  my $class = shift;

  return bless { inputs => {}, @_ }, $class;
}

sub app { return shift->gearview->app; }


sub invoke {
  my $class = shift;
  my $self  = $class->new(@_);

  my $dialog = $self->build_dialog || return;

  while(my $resp = $dialog->run) {
    if($resp eq 'help') {
      my $topic = $self->gearview->gear_class;
      $self->app->show_help($topic);
      next;
    }
    $self->save if $resp eq 'ok';
    last;
  }

  $dialog->destroy;

  return 1;
}


sub save      { $_->save foreach (values %{$_[0]->{inputs}}); }

sub input     { $_[0]->{inputs}->{$_[1]};         }


sub add_input {
  my($self, $name, $new) = @_;
  
  if(my $group = $self->{inputs}->{$name}) {
    if($group->can('add_to_group')) {
      $group->add_to_group($new);
    }
    else {
      warn "Multiple widgets called $name (First: $group)\n";
    }
  }
  else {
    $self->{inputs}->{$name} = $new;
  }
}

sub build_dialog {
  my $self = shift;

  my $gearview = $self->gearview                               || return;
  my $xml      = $gearview->dialog_xml                         || return;
  my $gladexml = Gtk2::GladeXML->new_from_buffer($xml)         || return;

  my $dialog   = $gladexml->get_widget($gearview->dialog_name);
  if(!$dialog) {
    $self->app->alert(
      'Error loading properties dialog',
      "Can't find '" . $gearview->dialog_name . "' in:\n\n$xml"
    );
    return;
  }

  $self->find_inputs($dialog);

  return $dialog;
}


sub find_inputs {
  my($self, $widget) = @_;

  my $name = $widget->get_widget_name || '';
  while($name =~ /^PAD\.(\w+)(?:\.(\w+))?(?:\((.*?)\))?(?:,(.*))?/) {
    if($3) {
      $self->connect_behaviour($widget, $1, $3);
    }
    else {
      $self->connect_property($widget, $1, $2);
    }
    $name = $4 || '';
  }
  return unless $widget->can('get_children');
  my @children = $widget->get_children;
  foreach my $child (@children) {
    $self->find_inputs($child);
  }
}


sub connect_property {
  my($self, $widget, $name, $value) = @_;

  my $gear = $self->gearview->gear;
  return unless($gear->can($name));
  my $type = ref $widget;
  if(my $class = $widget_class_map{$type}) {
    my %args = (name => $name, widget => $widget, gear => $gear);
    $args{value} = $value if defined($value);
    $self->add_input( $name => $class->new(%args) );
  }
  else {
    warn __PACKAGE__ . " - $type not supported yet\n";
  }
}


sub connect_behaviour {
  my($self, $widget, $behaviour, $args) = @_;

  if($behaviour eq 'browse_to_entry') {
    my($target, $type) = split(/\s*,\s*/, $args);
    $type ||= 'open';
    $widget->signal_connect(clicked => sub {
      my $file_chooser = Gtk2::FileChooserDialog->new(
        ucfirst($type),
        undef,
        $type,
        'gtk-cancel' => 'cancel',
        'gtk-ok'     => 'ok'
      );
      if($file_chooser->run eq 'ok') {
        my $filename = $file_chooser->get_filename;
        $self->input($target)->set($filename);
      }
      $file_chooser->destroy;
    });
  }
  else {
    warn __PACKAGE__ . " Unrecognised behaviour: $behaviour($args)\n";
  }
}


package Sprog::GtkAutoDialog::Entry;


sub new {
  my $class = shift;

  my $self = bless { @_ }, $class;
  my $name = $self->{name};
  $self->set($self->{gear}->$name || '');
  return $self;
}

sub set {
  $_[0]->{widget}->set_text($_[1]);
}

sub save {
  my $self = shift;
  my $name = $self->{name};
  $self->{gear}->$name($self->{widget}->get_text);
};


package Sprog::GtkAutoDialog::CheckButton;

use Glib qw(TRUE FALSE);

sub new {
  my $class = shift;

  my $self = bless { @_ }, $class;
  my $name = $self->{name};
  $self->{widget}->set_active($self->{gear}->$name || FALSE);
  return $self;
}


sub save {
  my $self = shift;
  my $name = $self->{name};
  $self->{gear}->$name($self->{widget}->get_active);
};


package Sprog::GtkAutoDialog::RadioButton;

sub new {
  my $class = shift;

  my $self = bless { @_ }, $class;
  my $name = $self->{name};
  my $current = $self->{gear}->$name || '';
  $self->{widget}->set_active($current eq $self->{value});
  return Sprog::GtkAutoDialog::RadioButtonGroup->new($self);
}


sub save {
  my $self = shift;
  my $name = $self->{name};
  if($self->{widget}->get_active) {
    $self->{gear}->$name($self->{value});
  }
};


package Sprog::GtkAutoDialog::RadioButtonGroup;


sub new {
  my $class = shift;
  return bless [ @_ ], $class;
}


sub add_to_group {
  my($self, $item) = @_;
  push @$self, @$item;
}


sub save {
  my $self = shift;
  $_->save foreach @$self;
}


package Sprog::GtkAutoDialog::TextView;


sub new {
  my $class = shift;

  my $self = bless { @_ }, $class;
  my $name = $self->{name};
  my $buffer = $self->{widget}->get_buffer;
  $buffer->set_text($self->{gear}->$name || '');

  if(my $app = $self->{gear}->app) {
    my $font_desc = Gtk2::Pango::FontDescription->from_string(
      $app->view->text_window_font
    );
    $self->{widget}->modify_font($font_desc);
  }

  return $self;
}


sub save {
  my $self = shift;
  my $name = $self->{name};
  my $buffer = $self->{widget}->get_buffer;
  my $s      = $buffer->get_start_iter;
  my $e      = $buffer->get_end_iter;
  my $text   = $buffer->get_text($s, $e, 0);
  $self->{gear}->$name($text);
};


package Sprog::GtkAutoDialog::SpinButton;


sub new {
  my $class = shift;

  my $self = bless { @_ }, $class;
  my $name = $self->{name};
  $self->{widget}->set_value($self->{gear}->$name || '1');
  return $self;
}


sub save {
  my $self = shift;
  my $name = $self->{name};
  my $value = $self->{widget}->get_value;
  $self->{gear}->$name($value);
};


package Sprog::GtkAutoDialog::ColorButton;


sub new {
  my $class = shift;

  my $self = bless { @_ }, $class;
  my $name = $self->{name};
  my $value = $self->{gear}->$name || '#000000000000';
  my @rgb = map { hex $_ } $value =~ /#(....)(....)(....)/;
  my $colour = Gtk2::Gdk::Color->new(@rgb);
  $self->{widget}->set_color($colour);
  return $self;
}


sub save {
  my $self = shift;
  my $name = $self->{name};
  my $colour = $self->{widget}->get_color;
  my @rgb = map { $colour->$_ } qw(red green blue);
  $self->{gear}->$name(sprintf("#%04X%04X%04X", @rgb));
};


1;
