use strict;
use warnings;

use Test::More tests => 27;

use File::Spec;

BEGIN {
  unshift @INC, File::Spec->catfile('t', 'lib');
}

use_ok('TestApp');

my $app = TestApp->make_test_app;

my($input, $caser, $sink) = $app->make_test_machine(qw(
  Sprog::Gear::TextInput
  Sprog::Gear::UpperCase
  TextGear
));
is($app->alerts, '', 'no alerts while creating machine');

isa_ok($input, 'Sprog::Gear::TextInput', 'input gear');
isa_ok($input, 'Sprog::Gear::Top', 'input gear also');
isa_ok($input, 'Sprog::Gear', 'input gear also');

isa_ok($caser, 'Sprog::Gear::UpperCase', 'transform gear');
isa_ok($caser, 'Sprog::Gear', 'transform gear also');

isa_ok($sink,  'TextGear', 'output gear');


my $data = "Line One\nLine Two\n";
my @all = $data =~ /(.*?\n)/g;

ok(!$input->has_input, 'has no input');
ok($input->has_output, 'has output');
is($input->title, 'Text Input', 'title looks ok');
like($input->dialog_xml, qr{<glade-interface>.*</glade-interface>}s, 
  'Glade XML looks plausible for Text Input');

ok($caser->has_input, 'has input');
ok($caser->has_output, 'has output');
is($caser->title, 'Uppercase', 'title looks ok');
ok($caser->no_properties, 'has no properties');

$input->text($data);
is($app->run_machine, '', 'run completed without timeout or alerts');
like($sink->text, qr/LINE ONE\s+LINE TWO/s,
  "data converted to upper case successfully");


($input, $caser, $sink) = $app->make_test_machine(qw(
  Sprog::Gear::TextInput
  Sprog::Gear::LowerCase
  TextGear
));
is($app->alerts, '', 'no alerts while creating machine');

isa_ok($caser, 'Sprog::Gear::LowerCase', 'transform gear');
isa_ok($caser, 'Sprog::Gear', 'transform gear');

ok($caser->has_input, 'has input');
ok($caser->has_output, 'has output');
is($caser->title, 'Lowercase', 'title looks ok');
ok($caser->no_properties, 'has no properties');

$input->text($data);
is($app->run_machine, '', 'run completed without timeout or alerts');

like($sink->text, qr/line one\s+line two/s,
  "data converted to lower case successfully");

