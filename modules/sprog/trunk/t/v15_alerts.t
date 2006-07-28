use Sprog::TestHelper tests => 12, display => 1;

use Glib qw(TRUE FALSE);

use_ok('TestApp');

my $app = TestApp->make_gtk_app;
$app->intercept_alerts(0);
is($app->alerts, '', 'no alerts when creating app');

my $dialog_returned = 0;

$app->run_sequence(

  sub {
    $app->add_timeout(200, \&check_dialog_1 );
    my $path = '/Machine/Run';
    ok(
      $app->view->activate_menu_item($path),
      "selected $path"
    );
  },

  sub {
    $dialog_returned++;
  },

  sub {
    $app->add_timeout(200, \&check_dialog_2 );
    $app->add_gear_at_x_y('Bogus::Gear::Class', 10, 10);
  },

  sub {
    $dialog_returned++;
  },

);

is($dialog_returned, 2, 'alert dialogs returned successfully');


exit;


sub check_dialog_1 {
  my $dialog = $app->view->find_window('Warning');
  isa_ok($dialog, 'Gtk2::Window', 'alert window');

  my $details = $app->view->find_button($dialog, 'Details');
  ok(!defined($details), "dialog has no 'details' button");

  my $dismiss = $app->view->find_button($dialog, 'Dismiss');
  isa_ok($dismiss, 'Gtk2::Button', 'close button');

  $dismiss->clicked;

  return FALSE;   # don't re-invoke this handler
}


sub check_dialog_2 {
  my $dialog = $app->view->find_window('Warning');
  isa_ok($dialog, 'Gtk2::Window', 'alert window');

  my $details = $app->view->find_button($dialog, 'Show De_tails');
  isa_ok($details, 'Gtk2::Button', 'show details button');

  $details->clicked;
  like($details->get_label, qr/Hide De_tails/, 'button now reads hide details');

  $details->clicked;
  like($details->get_label, qr/Show De_tails/, 'button reads show details again');

  my $dismiss = $app->view->find_button($dialog, 'Dismiss');
  isa_ok($dismiss, 'Gtk2::Button', 'close button');

  $dismiss->clicked;

  return FALSE;   # don't re-invoke this handler
}

