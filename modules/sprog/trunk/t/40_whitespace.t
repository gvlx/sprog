use Sprog::TestHelper tests => 31;

use_ok('TestApp');
use_ok('Sprog::Gear::StripWhitespace');

my $app = TestApp->make_test_app;

my($source, $stripper, $sink) = $app->make_test_machine(qw(
  MessageSource
  Sprog::Gear::StripWhitespace
  ListSink
));
is($app->alerts, '', 'no alerts while creating machine');

isa_ok($stripper, 'Sprog::Gear::StripWhitespace', 'filter gear');
isa_ok($stripper, 'Sprog::Gear',                  'filter gear also');

ok($stripper->has_input, 'has input');
ok($stripper->has_output, 'has output');
is($stripper->input_type,  'A', 'correct input connector type (list)');
is($stripper->output_type, 'A', 'correct output connector type (list)');
is($stripper->title, 'Strip Whitespace', 'title looks ok');
like($stripper->dialog_xml, qr{<glade-interface>.*</glade-interface>}s, 
  'Glade XML looks plausible');
is($stripper->strip_leading, 1, 'leading whitespace is stripped by default');
is($stripper->strip_trailing, 1, 'trailing whitespace is stripped by default');
is($stripper->collapse_spaces, 0, 'multiple spaces are not collapsed by default');
is($stripper->collapse_lines, 0, 'newlines are not collapsed by default');
is($stripper->strip_all, 0, 'strip_all is disabled by default');

my @data = (
  [ row => [ ' one', '  two', " \t three", "\tfour", "\t five" ] ],
  [ row => [ 'six ', 'seven  ', "eight \t ", "nine\t", "ten \t" ] ],
);

$source->messages(@data);

is($app->test_run_machine, '', "passed two rows without incident");

is_deeply(($sink->rows)[0],
  [ 'one', 'two', 'three', 'four', 'five' ],
  "leading whitespace was stripped by default");

is_deeply(($sink->rows)[1],
  [ 'six', 'seven', 'eight', 'nine', 'ten' ],
  "trailing whitespace was stripped by default too");


$stripper->strip_leading(0);
$stripper->strip_trailing(0);
$source->messages(@data);

is($app->test_run_machine, '', "same again with defaults turned off");

is_deeply([ $sink->rows ], [ map { $_->[1] } @data ],
  "data passed unchanged when strip_leading and strip_trailing turned off");


@data = (
  [ row => [ ' one one ', '  two  two  ', " three\t three ", "four\n four" ] ],
);

$stripper->strip_leading(0);
$stripper->strip_trailing(1);
$source->messages(@data);

is($app->test_run_machine, '', "passed some data with embedded spaces");

is_deeply([ $sink->rows ], [ 
    [ ' one one', '  two  two', " three\t three", "four\n four" ],
  ],
  "embedded spaces untouched by default");


$stripper->strip_leading(1);
$stripper->strip_trailing(0);
$stripper->collapse_spaces(1);
$source->messages(@data);

is($app->test_run_machine, '', "same again with collapse_spaces enabled");

is_deeply([ $sink->rows ], [ 
    [ 'one one ', 'two two ', "three three ", "four\n four" ],
  ],
  "embedded spaces collapsed on demand");


$stripper->strip_leading(1);
$stripper->strip_trailing(1);
$stripper->collapse_spaces(1);
$stripper->collapse_lines(1);
$source->messages(@data);

is($app->test_run_machine, '', "same again with collapse_lines enabled");

is_deeply([ $sink->rows ], [ 
    [ 'one one', 'two two', "three three", "four four" ],
  ],
  "embedded newlines collapsed on demand");


$stripper->strip_leading(0);
$stripper->strip_trailing(0);
$stripper->collapse_spaces(0);
$stripper->collapse_lines(0);
$stripper->strip_all(1);
$source->messages(@data);

is($app->test_run_machine, '', "same again strip_all enabled");

is_deeply([ $sink->rows ], [ 
    [ 'oneone', 'twotwo', "threethree", "four\nfour" ],
  ],
  "all spaces except newlines removed on demand");


$stripper->strip_leading(0);
$stripper->strip_trailing(0);
$stripper->collapse_spaces(0);
$stripper->collapse_lines(1);
$stripper->strip_all(1);
$source->messages(@data);

is($app->test_run_machine, '', "same again with collapse_newlines enabled");

is_deeply([ $sink->rows ], [ 
    [ 'oneone', 'twotwo', "threethree", "fourfour" ],
  ],
  "all spaces including newlines removed on demand");


