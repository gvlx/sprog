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
  my $about;
  foreach my $window (Gtk2::Window->list_toplevels) {
    my $title = $window->get_title or next;
    $about = $window if($title =~ /About Sprog/);
  }
  isa_ok($about, 'Gtk2::Dialog', 'located the about window');

  my $button = $about->get_focus;
  isa_ok($button, 'Gtk2::Button', 'close button');

  $button->activate;

  return FALSE;   # don't re-invoke this handler
}
