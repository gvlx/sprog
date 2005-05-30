use strict;
use Sprog::TestHelper tests => 12, display => 1;

use_ok('TestApp');

my $app = TestApp->make_gtk_app;
is($app->alerts, '', 'no alerts when creating app');

my($reader_id, $filev, $textwin_id, $textv, $grep_id, $grepv, $x, $y);
$app->run_sequence(

  sub {
    $app->add_gear_at_x_y('Sprog::Gear::ReadFile', 100, 40);
  },

  sub {
    $reader_id = gear_id_from_class('Sprog::Gear::ReadFile');
    ok(defined($reader_id), 'successfully added a file reader gear');
    $filev = $app->view->gear_view_by_id($reader_id);
    isa_ok($filev, 'Sprog::GtkGearView', 'file reader gear');

    $app->add_gear_at_x_y('Sprog::Gear::TextWindow', 100, 140);
  },

  sub {
    $textwin_id = gear_id_from_class('Sprog::Gear::TextWindow');
    ok(defined($textwin_id), 'successfully added a text window gear');
    $textv = $app->view->gear_view_by_id($textwin_id);
    isa_ok($textv, 'Sprog::GtkGearView', 'text window gear');
    isa_ok($textv, 'Sprog::GtkGearView::TextWindow', 'text window gear also');

    $app->add_gear_at_x_y('Sprog::Gear::Grep', 100, 240);
  },

  sub {
    $grep_id = gear_id_from_class('Sprog::Gear::Grep');
    ok(defined($grep_id), 'successfully added a pattern match gear');
    $grepv = $app->view->gear_view_by_id($grep_id);
    isa_ok($grepv, 'Sprog::GtkGearView', 'pattern match gear');

    ok(!defined($filev->gear->next), 'file reader gear has no next gear');
    $grepv->move(10, -90);
    ($x, $y) = $textv->group->get_bounds;
    $x += 10;
    $y += 10;
    $app->drop_gear($grepv, $x, $y);
  },

  sub {
    TODO: {
      local $TODO = 'Drop coordinates need fixing';
      ok(abs($grepv->gear->x - $x) < 2, 'x position = drop point');
      ok(abs($grepv->gear->y - $y) < 2, 'y position = drop point');
    }

    $grepv->move(0, -100);
    $app->drop_gear($grepv, 110, 50);
  },

);

exit;

sub gear_id_from_class {
  my($class) = @_;

  my $id;
  while(my($k, $gear) = each %{ $app->machine->parts }) {
    $id = $k if UNIVERSAL::isa($gear, $class);
  }

  return $id;
}
