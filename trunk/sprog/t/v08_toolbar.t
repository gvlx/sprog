use strict;
use warnings;

use Test::More;
use File::Spec;
use Gtk2::Gdk::Keysyms;

BEGIN {
  plan 'skip_all' => 'No X'
    unless(defined($ENV{DISPLAY})  &&  $ENV{DISPLAY} =~ /:\d/);
}

plan tests => 21;

use File::Spec;

BEGIN {
  unshift @INC, File::Spec->catfile('t', 'lib');
}

use_ok('TestApp');

my $app = TestApp->make_gtk_app;
is($app->alerts, '', 'no alerts when creating app');

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
    $app->add_timeout(200, sub { cancel_dialog('Save as') });
    $tool_button{'Save'}->clicked;
  },

  sub {
    ok(1, "returned successfully from 'Save as' dialog");
    $tool_button{'Palette'}->clicked;
  },

  sub {
    ok($app->view->palette->widget->visible, "palette is visible");
    ok($tool_button{'Run'}->sensitive, "run button is sensitive");
    ok(!$tool_button{'Stop'}->sensitive, "stop button is not sensitive");
    $tool_button{'Run'}->clicked;
  },

  sub {
    like($app->alerts, qr/You must add an input gear/, "'Run' button works");
    $app->alerts('');
    is(scalar(keys %{$app->machine->parts}), 0, 'workspace is empty');
    $app->add_timeout(200, sub { cancel_dialog('Open') });
    $tool_button{'Open'}->clicked;
  },

  sub {
    ok(1, "returned successfully from 'Open' dialog");
    my $filename = File::Spec->catfile('t', 'counter.sprog');
    $filename = File::Spec->rel2abs($filename);
    $app->load_from_file($filename);
    is(scalar(keys %{$app->machine->parts}), 2, 'loaded a two gear machine');
    $tool_button{'Run'}->clicked;
  },

  sub {
    my $running = $app->machine_running;
    is($running, 1, 'machine is running');
    ok(!$tool_button{'Run'}->sensitive, "run button is not sensitive");
    ok($tool_button{'Stop'}->sensitive, "stop button is sensitive");
  },

  1500,

  sub {
    $tool_button{'Stop'}->clicked;
  },

  sub {
    my $running = $app->machine_running;
    is($running, 0, 'machine is no longer running');
    ok($tool_button{'Run'}->sensitive, "run button is sensitive");
    ok(!$tool_button{'Stop'}->sensitive, "stop button is not sensitive");

    my $window_name = 'Text Output';
    my $dialog = $app->view->find_window($window_name);
    isa_ok($dialog, 'Gtk2::Window', "'$window_name' window");

    my $clear = $app->view->find_button($dialog, 'Clear');
    $clear->clicked;

    my $hide = $app->view->find_button($dialog, 'Hide');
    $hide->clicked;

    $app->quit;
  },

);

is($app->timed_out, 0, 'app exited before timeout');

exit;


sub cancel_dialog {
  my($window_name) = @_;

  my $dialog = $app->view->find_window($window_name);
  isa_ok($dialog, 'Gtk2::Window', "'$window_name' window");

  $dialog->response('cancel');
  return;
}


sub check_machine1 {
  my $running = $app->machine_running;
  is($running, 1, 'machine is running');
  ok(!$tool_button{'Run'}->sensitive, "run button is not sensitive");
  ok($tool_button{'Stop'}->sensitive, "stop button is sensitive");

  $tool_button{'Stop'}->clicked;

  return;
}


sub check_machine2 {
  my $running = $app->machine_running;
  is($running, 0, 'machine is no longer running');
  ok($tool_button{'Run'}->sensitive, "run button is sensitive");
  ok(!$tool_button{'Stop'}->sensitive, "stop button is not sensitive");

  my $window_name = 'Text Output';
  my $dialog = $app->view->find_window($window_name);
  isa_ok($dialog, 'Gtk2::Window', "'$window_name' window");

  my $clear = $app->view->find_button($dialog, 'Clear');
  $clear->clicked;

  my $hide = $app->view->find_button($dialog, 'Hide');
  $hide->clicked;

  return;
}


# This routine is not used - can't seem to make it go :-(

sub open_counter {
  my $dialog = $app->view->find_window('Open');
  isa_ok($dialog, 'Gtk2::Window', "'Open' dialog");
  isa_ok($dialog, 'Gtk2::FileChooserDialog', "'Open' dialog also");

  my $filename = File::Spec->catfile('t', 'counter.sprog');
  $filename = File::Spec->rel2abs($filename);
  $dialog->select_filename($filename);

  $dialog->response('ok');
  $dialog->response('accept');
  $dialog->signal_emit('file-activated');
  return;
}

