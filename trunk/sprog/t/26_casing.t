use strict;
use warnings;

use Test::More 'no_plan';# tests => 26;

use File::Spec;

BEGIN {
  unshift @INC, File::Spec->catfile('t', 'lib');
}

my $data = <<'EOF';
Line One
Line Two
EOF

my @all = $data =~ /(.*?\n)/g;


use_ok('TextGear');
use_ok('Sprog::Gear::UpperCase');
use_ok('Sprog::Gear::LowerCase');
use_ok('Sprog::ClassFactory');

my $app = make_app(               # Imported from ClassFactory.pm
  '/app'         => 'DummyApp',
  '/app/machine' => 'DummyMachine',
);


my $sink = TextGear->new(id => 2);
isa_ok($sink, 'TextGear');
$sink->prime;


my $caser = Sprog::Gear::UpperCase->new();
isa_ok($caser, 'Sprog::Gear::UpperCase');
isa_ok($caser, 'Sprog::Gear');

ok($caser->has_input, 'has input');
ok($caser->has_output, 'has output');
is($caser->title, 'Uppercase', 'title looks ok');
ok($caser->no_properties, 'has no properties');

$caser->next($sink);
isa_ok($caser->last, 'TextGear');

$caser->machine($app->machine);
$caser->prime;

$caser->msg_in(data => $data);
$caser->turn_once;
1 while($sink->turn_once);

like($sink->text, qr/LINE ONE\s+LINE TWO/s,
  "data converted to upper case successfully");


$caser = Sprog::Gear::LowerCase->new();
isa_ok($caser, 'Sprog::Gear::LowerCase');
isa_ok($caser, 'Sprog::Gear');

ok($caser->has_input, 'has input');
ok($caser->has_output, 'has output');
is($caser->title, 'Lowercase', 'title looks ok');
ok($caser->no_properties, 'has no properties');

$caser->next($sink);
isa_ok($caser->last, 'TextGear');

$caser->machine($app->machine);
$caser->prime;

$caser->msg_in(data => $data);
$caser->turn_once;
1 while($sink->turn_once);

like($sink->text, qr/line one\s+line two/s,
  "data converted to lower case successfully");

