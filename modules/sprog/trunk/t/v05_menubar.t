use Sprog::TestHelper tests => 54, display => 1;

use Glib qw(TRUE FALSE);

use_ok('TestApp');

my $app = TestApp->make_gtk_app;
is($app->alerts, '', 'no alerts when creating app');
$app->quit_on_stop(0);

my $file_quit_failed = 0;
my $last_dialog;
my $outputv;

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

    my $path = '/Help/About';
    $app->add_timeout(200, \&click_close_button );
    ok(
      $app->view->activate_menu_item($path),
      "selected $path"
    );
  },

  sub {
    my $filename = File::Spec->catfile('t', 'counter.sprog');
    $filename = File::Spec->rel2abs($filename);
    $app->load_from_file($filename);

    my $input = $app->machine->head_gear;
    isa_ok($input, 'Sprog::Gear::CommandIn', 'input gear from file');

    my $output = $input->last;
    isa_ok($output, 'Sprog::Gear::TextWindow', 'output gear from file');

    $outputv = $app->view->gear_view_by_id($output->id);
    isa_ok($outputv, 'Sprog::GtkGearView::TextWindow', 'view object for output gear');
    $app->alerts('');
    $@ = '';
    eval {
      $outputv->clear;
    };
    is($app->alerts . "$@", '', 'clear output of non-existant window not fatal');

    my $path = '/Machine/Run';
    ok(
      $app->view->activate_menu_item($path),
      "selected $path"
    );
  },

  100,

  sub {
    my $running = $app->machine_running;
    is($running, 1, 'machine is running');

    my $path = '/Machine/Stop';
    ok(
      $app->view->activate_menu_item($path),
      "selected $path"
    );
  },

  sub {
    my $running = $app->machine_running;
    is($running, 0, 'machine is stopped');

    $app->alerts('');
    $@ = '';
    eval {
      $outputv->clear;
      $outputv->toggle_window_visibility;
    };
    is($app->alerts . "$@", '', 'no errors clearing & hiding text window');

    # Trying to set sensitivity of no-existant menu item is non-fatal
    $app->alerts('');
    $@ = '';
    eval {
      $app->view->menubar->set_sensitive('/Foo/Bar', FALSE);
    };
    is($app->alerts . "$@", '', 'set sensitive on bad path quietly ignored');
  },

  sub {
    # Silly messing around to improve coverage :-)
    my $menu = $app->view->menubar->menu;
    $menu->delete_entries({path => '/View/Palette'});
    $app->alerts('');
    $@ = '';
    eval {
      $app->toggle_palette;
    };
    is($app->alerts . "$@", '', 'toggling palette when menu item deleted');
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

is($app->timed_out, 0, 'app did not time out');
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

sub click_close_button {
  my $dialog = $app->view->find_window('About Sprog');
  ok(defined($dialog), 'located the alert window');

  my $close = $app->view->find_button($dialog, 'Close');
  isa_ok($close, 'Gtk2::Button', 'close button');

  $close->clicked;

  return FALSE;   # don't re-invoke this handler
}
