package Sprog::GtkView::RenameDialog;

use strict;

use Glib qw(TRUE FALSE);

use base qw(Sprog::Accessor);

__PACKAGE__->mk_accessors(qw(
  gear
  entry
));

use constant RESET_TO_DEFAULT => 100;

sub new {
  my $class = shift;
  return bless { @_ }, $class;
}


sub invoke {
  my($class, $parent, $gear) = @_;

  my $self = $class->new(gear => $gear);

  my $dialog = $self->build_dialog($parent);

  my $return;
  while(my $resp = $dialog->run) {
    if($resp eq RESET_TO_DEFAULT) {
      $self->entry->set_text($self->gear->default_title);
      next;
    }
    elsif($resp eq 'ok') {
      $self->gear->title($self->entry->get_text);
    }
    last;
  }

  $dialog->destroy;

  return;
}


sub build_dialog {
  my($self, $parent) = @_;

  my $dialog = Gtk2::Dialog->new_with_buttons(
    "Rename Gear",
    $parent,
    [qw/modal destroy-with-parent no-separator/],
    'gtk-revert-to-saved' => RESET_TO_DEFAULT,
    'gtk-cancel'          => 'cancel',
    'gtk-ok'              => 'ok',
  );

  $dialog->set_default_response ('ok');

  my $table = Gtk2::Table->new(2, 2, FALSE);
  $dialog->vbox->pack_start($table, FALSE, FALSE, 4);

  my $label = Gtk2::Label->new('New title:');
  $table->attach($label, 0, 1, 0, 1, ['fill'], ['fill'], 4, 2);

  my $entry = $self->entry(Gtk2::Entry->new);
  $entry->set_text($self->gear->title);
  $entry->set_activates_default(TRUE);
  $table->attach($entry, 1, 2, 0, 1, ['expand', 'fill'], ['fill'], 4, 2);

  $dialog->show_all;

  return $dialog;
}

1;

