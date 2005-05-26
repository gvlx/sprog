use strict;
use warnings;

use Test::More 'no_plan';# tests => 31;

use File::Spec;

BEGIN {
  unshift @INC, File::Spec->catfile('t', 'lib');
}

use_ok('TestApp');
use_ok('Sprog::Gear::ParseHTMLTable');

my $app = TestApp->make_test_app;

my($source, $stripper, $sink) = $app->make_test_machine(qw(
  Sprog::Gear::TextInput
  Sprog::Gear::ParseHTMLTable
  ListSink
));
is($app->alerts, '', 'no alerts while creating machine');

isa_ok($stripper, 'Sprog::Gear::ParseHTMLTable', 'filter gear');
isa_ok($stripper, 'Sprog::Gear',                 'filter gear also');

ok($stripper->has_input, 'has input');
ok($stripper->has_output, 'has output');
is($stripper->input_type,  'P', 'correct input connector type (pipe)');
is($stripper->output_type, 'A', 'correct output connector type (list)');
is($stripper->title, 'Parse HTML Table', 'title looks ok');
like($stripper->dialog_xml, qr{<glade-interface>.*</glade-interface>}s, 
  'Glade XML looks plausible');
is($stripper->selector, '1', "default table selector is '1'");


$source->text('');

is($app->test_run_machine, '', "empty input caused no problem");

is_deeply([ $sink->rows ], [ ],
  "no data extracted - as expected");


$source->text('<p>This does not contain a table</p>');

is($app->test_run_machine, '', "HTML without <table> handled OK");

is_deeply([ $sink->rows ], [ ],
  "still no data extracted - as expected");


$source->text('<p>This has no closing tag and no table');

is($app->test_run_machine, '', "unclosed HTML without <table> handled OK");

is_deeply([ $sink->rows ], [ ],
  "still no data extracted - as expected");


my $html = <<'EOF';
<html>
<head>
  <title>TITLE</title>
</head>
<body>
  <table>
    <tr>
      <td>one</td>
      <td>two</td>
    </tr>
    <tr>
      <td>buckle</td>
      <td>your shoe</td>
    </tr>
  </table>
</body>
</html>
EOF

$source->text($html);

is($app->test_run_machine, '', "parsed some actual HTML without incident");

is_deeply([ $sink->rows ], [
    [ 'one', 'two' ],
    [ 'buckle', 'your shoe' ],
  ],
  "two-by-two table parsed successfully");

