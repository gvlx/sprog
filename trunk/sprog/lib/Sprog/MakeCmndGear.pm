package Sprog::MakeCmndGear;

use strict;
use warnings;

use base qw(Sprog::Accessor);

__PACKAGE__->mk_accessors(qw(
  app
  gear_dir
  type
  title
  command
  keywords
  filename
));

use Scalar::Util qw(weaken);


sub new {
  my($class, $app, $gear) = @_;

  my $gear_dir = $app->get_pref('private_gear_folder')
    or return $app->alert(
      "You must first define your Personal Gear Folder in preferences"
    );

  return $app->alert(
    "Personal Gear Folder does not exist", 
    "$gear_dir: no such file or directory"
  ) unless -d $gear_dir;

  my $self = bless { app => $app, gear_dir => $gear_dir }, $class;
  weaken($self->{app});

  return $self->_init($gear);
}


sub _init {
  my($self, $gear) = @_;

  $self->_init_from_gear($gear)  and return $self;
  $self->_init_from_class($gear) and return $self;

  $self->type('filter');
  $self->title('');
  $self->command('');
  $self->keywords('');
  $self->filename('');
  #$self->filename($self->default_filename($self->title));
  return $self;
}


sub _init_from_gear {
  my($self, $gear) = @_;

  my $gear_class = ref($gear) or return;

  if($gear->has_input) {
    if($gear->has_output) {
      $self->type('filter');
    }
    else {
      $self->type('output');
    }
  }
  else {
    $self->type('input');
  }

  $self->title($gear->title);
  $self->command($gear->command);

  my $meta = $self->app->geardb->gear_class_info($gear_class);
  my $keywords = $meta->keywords;
  substr($keywords, 0, length($gear->title) + 1) = '';  # strip title off
  $self->keywords($keywords);

  if($gear->is_command_gear) {
    $self->filename($self->default_filename($self->title));
  }
  else {
    my $filename = $gear_class . '.pm';
    $filename =~ s/^.*:://;
    $self->filename($filename);
  }

  return 1;
}


sub _init_from_class {
  my($self, $class) = @_;

  return unless $class;

  $self->app->machine->require_gear_class($class);

  my $gear = $class->new(app => $self->app);

  return $self->_init_from_gear($gear);
}


sub default_filename {
  my($self, $title) = @_;

  $title =~ s/[\W_]+/ /g;

  return join('', map { ucfirst lc $_ } split /\s+/, $title) . '.pm';
}


sub save {
  my $self = shift;

  warn("Type: " .$self->type . "\n");
  warn("Title: " .$self->title . "\n");
  warn("Command: " .$self->command . "\n");
  warn("Keywords: " .$self->keywords . "\n");
  warn("Filename: " .$self->filename . "\n");
}
1;

