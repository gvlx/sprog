use strict;
use warnings;

use Test::More;
use Gtk2::Gdk::Keysyms;

BEGIN {
  plan 'skip_all' => 'No X'
    unless(defined($ENV{DISPLAY})  &&  $ENV{DISPLAY} =~ /:\d/);
}

plan tests => 9;

use File::Spec;

BEGIN {
  unshift @INC, File::Spec->catfile('t', 'lib');
}

use_ok('TestApp');

my $app = TestApp->make_gtk_app;
is($app->alerts, '', 'no alerts when creating app');

my $file_quit_failed = 0;

my $toolbar;

my %tool_button;

$app->run_sequence(

  sub {
    %tool_button = $app->view->get_tool_buttons;
    $tool_button{'New'}->clicked;
  },

  sub {
    like($app->alerts, qr/Not implemented/, "'New' button works");
    $app->alerts('');
    $app->add_timeout(200, sub { cancel_dialog('Open') });
    $tool_button{'Open'}->clicked;
  },

  sub {
    ok(1, "returned successfully from 'Open' dialog");
    $app->add_timeout(200, sub { cancel_dialog('Save as') });
    $tool_button{'Save'}->clicked;
  },

  sub {
    ok(1, "returned successfully from 'Save as' dialog");
    $tool_button{'Palette'}->clicked;
  },

  sub {
    ok($app->view->palette->widget->visible, "palette is visible");
    $tool_button{'Run'}->clicked;
  },

  sub {
    like($app->alerts, qr/You must add an input gear/, "'Run' button works");
    $app->alerts('');
  },

  sub {
    $app->quit;
  },

);


exit;


sub cancel_dialog {
  my($window_name) = @_;

  my $dialog = $app->view->find_window($window_name);
  isa_ok($dialog, 'Gtk2::Window', "'$window_name' window");

  $dialog->response('cancel');
  return;
}

