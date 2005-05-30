use strict;
use Sprog::TestHelper tests => 17, requires => 'Apache::LogRegex';

use_ok('TestApp');
use_ok('Sprog::Gear::ApacheLogParse');

my $app = TestApp->make_test_app;

my($source, $parser, $sink) = $app->make_test_machine(qw(
  Sprog::Gear::TextInput
  Sprog::Gear::ApacheLogParse
  RecordSink
));
is($app->alerts, '', 'no alerts while creating machine');

isa_ok($parser, 'Sprog::Gear::ApacheLogParse', 'parser gear');
isa_ok($parser, 'Sprog::Gear',                 'parser gear also');

ok($parser->has_input, 'has input');
ok($parser->has_output, 'has output');
is($parser->input_type,  'P', 'correct input connector type (pipe)');
is($parser->output_type, 'H', 'correct output connector type (record)');
is($parser->title, 'Parse Apache Log', 'title looks ok');
like($parser->dialog_xml, qr{<glade-interface>.*</glade-interface>}s, 
  'Glade XML looks plausible');
is($parser->log_format, 'combined', "default log format is 'combined'");


my $bad_data = "< bogus >\n";

{
  my $warnings = '';
  local($SIG{__WARN__}) = sub { $warnings .= shift; };

  $parser->log_format('common');
  $source->text($bad_data);
  is($app->test_run_machine, '',
    'bad input data processed without timeout or alerts');
  is_deeply([ $sink->records ], [ ], 'bad data in = no data out');
  like($warnings, qr/Could not parse: < bogus >/, 'got expected warning');
  $sink->reset;
}


my $data = <<'EOF';
127.0.0.1 - - [16/Mar/2005:06:56:52 +1300] "GET /proxy.pac HTTP/1.1" 200 501 "-" "Mozilla/5.0 (X11; U; Linux i686; en-US; rv:1.7.5) Gecko/20050105 Debian/1.7.5-1"
127.0.0.1 - - [16/Mar/2005:06:58:55 +1300] "GET / HTTP/1.1" 200 5084 "-" "Mozilla/5.0 (X11; U; Linux i686; en-US; rv:1.7.5) Gecko/20050105 Debian/1.7.5-1"
EOF


$source->text($data);
$parser->log_format('combined');

is($app->test_run_machine, '', 'processed actual log entries');

is_deeply([ $sink->records ], [
    {
      'request' => 'GET /proxy.pac HTTP/1.1',
      'User-Agent' => 'Mozilla/5.0 (X11; U; Linux i686; en-US; rv:1.7.5) Gecko/20050105 Debian/1.7.5-1',
      'time' => '[16/Mar/2005:06:56:52 +1300]',
      'status' => '200',
      'host' => '127.0.0.1',
      'Referer' => '-',
      'auth_user' => '-',
      'bytes_sent' => '501',
      'client_login' => '-'
    },
    {
      'request' => 'GET / HTTP/1.1',
      'User-Agent' => 'Mozilla/5.0 (X11; U; Linux i686; en-US; rv:1.7.5) Gecko/20050105 Debian/1.7.5-1',
      'time' => '[16/Mar/2005:06:58:55 +1300]',
      'status' => '200',
      'host' => '127.0.0.1',
      'Referer' => '-',
      'auth_user' => '-',
      'bytes_sent' => '5084',
      'client_login' => '-'
    },
  ], "got expected output");


