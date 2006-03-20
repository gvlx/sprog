use strict;
use warnings;

use Test::More;

BEGIN {
  plan 'skip_all' => 'No X'
    unless(defined($ENV{DISPLAY})  &&  $ENV{DISPLAY} =~ /:\d/);
}

plan tests => 5;

use File::Spec;
use Glib qw(TRUE FALSE);

BEGIN {
  unshift @INC, File::Spec->catfile('t', 'lib');
}

use_ok('TestApp');

my $app = TestApp->make_gtk_app;
is($app->alerts, '', 'no alerts when creating app');

my $about_dialog_returned = 0;

$app->run_sequence(

  sub {
    $app->add_timeout(200, \&click_close_button );
    $app->help_about;
  },

  sub {
    $about_dialog_returned = 1;
  }
);

ok($about_dialog_returned, 'About dialog returned successfully');


exit;

sub click_close_button {
  my $dialog = $app->view->find_window('About Sprog');
  ok(defined($dialog), 'located the alert window');

  my $close = $app->view->find_button($dialog, 'Close');
  isa_ok($close, 'Gtk2::Button', 'close button');

  $close->clicked;

  return FALSE;   # don't re-invoke this handler
}
