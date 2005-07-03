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

  my $title = $gear->title;
  $title =~ s{^Run (Filter )?Command$}{}i;
  $self->title($title);

  $self->command($gear->command);

  my $meta = $self->app->gear_class_info($gear_class);
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

  return '' unless $title =~ /\S/;

  return join('', map { ucfirst lc $_ } split /\s+/, $title) . '.pm';
}


sub save {
  my $self = shift;

  my $app = $self->app;

  my $title = $self->title;
  return $app->alert("You must enter a title")    unless length $title;

  my $command = $self->command;
  return $app->alert("You must enter a command")  unless length $command;

  my $keywords = $self->keywords;

  my $class = $self->filename;
  return $app->alert("You must enter a filename") unless length $class;

  $class =~ s/\.pm$//i;

  if($class =~ /([^\w.])/) {
    return $app->alert("Invalid character in filename: '$1'");
  }

  my $path = File::Spec->catfile($self->gear_dir, $class . '.pm');

  return if -e $path
            && !$app->confirm_yes_no('Save As', 'File exists.  Overwrite?');

  my $type = $self->type;
  my($conn_in, $conn_out, $parent);
  if($type eq 'input') {
    $conn_in  = '_';
    $conn_out = 'P';
    $parent   = 'CommandIn';
  }
  elsif($type eq 'filter') {
    $conn_in  = 'P';
    $conn_out = 'P';
    $parent   = 'CommandFilter';
  }
  else {
    $conn_in  = 'P';
    $conn_out = '_';
    $parent   = 'CommandOut';
  }

  $command =~ s{([()])}{\\$1}g;

  open my $fh, '>', $path or return $self->app->alert(
    "Error creating $path", "$!"
  );

  print $fh <<"EOF";
package SprogEx::Gear::$class;

=begin sprog-gear-metadata

  title: $title
  type_in: $conn_in
  type_out: $conn_out
  keywords: $keywords
  no_properties: 1
  custom_command_gear: 1

=end sprog-gear-metadata

=cut

use strict;

use base qw(Sprog::Gear::$parent);

__PACKAGE__->declare_properties( -command => undef );

sub command { q($command); }

1;
EOF

  close($fh);
  
  my $inc_key = "SprogEx/Gear/$class.pm";
  delete $INC{$inc_key};
  delete $INC{$path};

  $app->init_private_path;  # refresh palette view

  return 1;
}


sub delete {
  my $self = shift;

  my $gear_class = 'SprogEx::Gear::' . $self->filename;
  $gear_class =~ s/\.pm$//;

  my $meta = $self->app->gear_class_info($gear_class) or return;
  return unless $meta->custom_command_gear;

  return unless $self->app->confirm_yes_no(
    'Delete Gear?', 
    "Are you sure you wish to delete the gear from\n" .
    "the palette and from your personal gear folder?"
  );
  if(!unlink($meta->file)) {
    return $self->app->alert("Error deleting custom command gear", "$!");
  }

  $self->app->init_private_path;  # refresh palette view
  
  return 1;
}

1;

