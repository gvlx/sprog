use strict;
use Sprog::TestHelper tests => 8;

use_ok('TestApp');

my $app = TestApp->make_test_app;

isa_ok($app, 'TestApp', 'test app object');

my($source, $filter, $sink) = $app->make_test_machine(qw(
  MessageSource
  ParaTest
  MessageSink
));

isa_ok($filter, 'ParaTest',                  'paragraph test gear');
isa_ok($filter, 'Sprog::Mixin::InputByPara', 'paragraph test gear also');

$source->messages(
  [ file_start => undef ],
  [ data => "First line of paragraph one.\n"
          . "Second line of paragraph one.\n"
          . "\n"
          . "First line of paragraph two.\n"
          . "Second line of paragraph two.\n"
          . "Third line of paragraph two.\n"
          . "\n"
          . "Paragraph four.\n" ],
  [ file_end => undef ],
);

is($app->test_run_machine, '', 'passed in test data');

is_deeply([ $sink->messages ], [
  [ file_start => undef ],
  [ data => "First line of paragraph one.\nSecond line of paragraph one.\n" ],
  [ data => "\nFirst line of paragraph two.\n"
          . "Second line of paragraph two.\n"
          . "Third line of paragraph two.\n" ],
  [ data => "\nParagraph four.\n" ],
  [ file_end => undef ],
], "parsed paragraphs from one data message");


$source->messages(
  [ file_start => undef ],
  [ data => "First line of paragraph one." ],
  [ data => "\nSecond line of paragraph one.\n" ],
  [ data => "\n" ],
  [ data => "First line of paragraph two.\n" ],
  [ data => "Second line of paragraph two.\n" ],
  [ data => "Third line of paragraph two.\n" ],
  [ data => "\n" ],
  [ data => "Paragraph four.\n" ],
  [ file_end => undef ],
);

is($app->test_run_machine, '', 'passed in test data');

is_deeply([ $sink->messages ], [
  [ file_start => undef ],
  [ data => "First line of paragraph one.\nSecond line of paragraph one.\n" ],
  [ data => "\nFirst line of paragraph two.\n"
          . "Second line of paragraph two.\n"
          . "Third line of paragraph two.\n" ],
  [ data => "\nParagraph four.\n" ],
  [ file_end => undef ],
], "parsed paragraphs from many data messages");



