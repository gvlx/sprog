use strict;
use warnings;

use Test::More;

BEGIN {
  plan 'skip_all' => 'No X'
    unless(defined($ENV{DISPLAY})  &&  $ENV{DISPLAY} =~ /:\d/);
}

plan tests => 39;

use File::Spec;

BEGIN {
  unshift @INC, File::Spec->catfile('t', 'lib');
}

use_ok('TestApp');

my $app = TestApp->make_gtk_app;
is($app->alerts, '', 'no alerts when creating app');

my $file_quit_failed = 0;
my $last_dialog;

$app->run_sequence(

  sub {
    my $toolbar = $app->view->toolbar->widget;
    my $visible = $toolbar && $toolbar->visible;
    ok($visible, 'toolbar is visible by default');
  },

  sub {
    my $path = '/View/Toolbar Style/Icons Only';
    ok(
      $app->view->activate_menu_item($path),
      "selected $path"
    );
  },

  sub {
    my $toolbar = $app->view->toolbar->widget;
    my $style = $toolbar ? $toolbar->get_style : 'undef';
    is($style, 'icons', 'toolbar style switched to icons only');
  },

  sub {
    my $path = '/View/Toolbar Style/Text Only';
    ok(
      $app->view->activate_menu_item($path),
      "selected $path"
    );
  },

  sub {
    my $toolbar = $app->view->toolbar->widget;
    my $style = $toolbar ? $toolbar->get_style : 'undef';
    is($style, 'text', 'toolbar style switched to text only');
  },

  sub {
    my $path = '/View/Toolbar Style/Text Beside Icons';
    ok(
      $app->view->activate_menu_item($path),
      "selected $path"
    );
  },

  sub {
    my $toolbar = $app->view->toolbar->widget;
    my $style = $toolbar ? $toolbar->get_style : 'undef';
    is($style, 'both-horiz', 'toolbar style switched to text beside icons');
  },

  sub {
    my $path = '/View/Toolbar Style/Icons and Text';
    ok(
      $app->view->activate_menu_item($path),
      "selected $path"
    );
  },

  sub {
    my $toolbar = $app->view->toolbar->widget;
    my $style = $toolbar ? $toolbar->get_style : 'undef';
    is($style, 'both', 'toolbar style switched to icons and text');
  },

  sub {
    my $path = '/View/Toolbar';
    ok(
      $app->view->activate_menu_item($path),
      "selected $path"
    );
  },

  sub {
    my $toolbar = $app->view->toolbar->widget;
    my $visible = $toolbar && $toolbar->visible;
    ok(!$visible, 'toolbar is hidden');
  },

  sub {
    my $path = '/View/Toolbar';
    ok(
      $app->view->activate_menu_item($path),
      "selected $path"
    );
  },

  sub {
    my $toolbar = $app->view->toolbar->widget;
    my $visible = $toolbar && $toolbar->visible;
    ok($visible, 'toolbar is visible again');
  },

  sub {
    my $button = $app->view->toolbar->{palette};
    my $active = $button && $button->get_active;
    ok(!$active, 'toolbar palette button is inactive');
  },

  sub {
    my $path = '/View/Palette';
    ok(
      $app->view->activate_menu_item($path),
      "selected $path"
    );
  },

  sub {
    my $button = $app->view->toolbar->{palette};
    my $active = $button && $button->get_active;
    ok($active, 'toolbar palette button is active');

    my $palette = $app->view->palette->widget;
    my $visible = $palette && $palette->visible;
    ok($visible, 'palette is visible');
  },

  sub {
    my $path = '/View/Palette';
    ok(
      $app->view->activate_menu_item($path),
      "selected $path"
    );
  },

  sub {
    my $palette = $app->view->palette->widget;
    my $visible = $palette && $palette->visible;
    ok(!$visible, 'palette is hidden');
  },

  sub {
    my $path = '/File/New';
    ok(
      $app->view->activate_menu_item($path),
      "selected $path"
    );
  },

  sub {
    like($app->alerts, qr/^Not implemented/,
      'correct alert for File New not implemented');
    $app->alerts('');
    $app->add_timeout(200, sub { dialog_response('Open', 'cancel') });
    my $path = '/File/Open';
    ok(
      $app->view->activate_menu_item($path),
      "selected $path"
    );
  },

  sub {
    is($last_dialog, 'Open', 'file open dialog was opened');
    my $dialog = $app->view->find_window($last_dialog);
    is($dialog, undef, 'and is now closed');
    $app->add_timeout(200, sub { dialog_response('Save as', 'cancel') });
    my $path = '/File/Save';
    ok(
      $app->view->activate_menu_item($path),
      "selected $path"
    );
  },

  sub {
    is($last_dialog, 'Save as', 'file save dialog was opened');
    my $dialog = $app->view->find_window($last_dialog);
    is($dialog, undef, 'and is now closed');
    $app->add_timeout(200, sub { dialog_response('Save as', 'cancel') });
    my $path = '/File/Save As';
    ok(
      $app->view->activate_menu_item($path),
      "selected $path"
    );
  },

  sub {
    is($last_dialog, 'Save as', 'file save as dialog was opened');
    my $dialog = $app->view->find_window($last_dialog);
    is($dialog, undef, 'and is now closed');
    my $path = '/Machine/Run';
    ok(
      $app->view->activate_menu_item($path),
      "selected $path"
    );
  },

  sub {
    like($app->alerts, qr/^You must add an input gear/,
      'correct alert for trying to run an empty machine');
    $app->alerts('');
  },

  sub {
    my $path = '/File/Quit';    # should exit the app
    ok(
      $app->view->activate_menu_item($path),
      "selected $path"
    );
  },

  sub {
    $file_quit_failed = 1;  # should never be reached
  },

);

ok(!$file_quit_failed, 'exited successfully using File Quit');

exit;


sub dialog_response {
  my($window_name, $response) = @_;

  $last_dialog = undef;
  my $dialog = $app->view->find_window($window_name);
  isa_ok($dialog, 'Gtk2::Window', "'$window_name' window");
  $last_dialog = $dialog->get_title;

  $dialog->response($response);
  return;
}

