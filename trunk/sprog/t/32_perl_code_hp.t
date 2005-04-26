use strict;
use warnings;

use Test::More tests => 36;

use File::Spec;

BEGIN {
  unshift @INC, File::Spec->catfile('t', 'lib');
}

use_ok('TestApp');
use_ok('Sprog::Gear::PerlCodeHP');
use_ok('Sprog::ClassFactory');

my $data = <<'EOF';
127.0.0.1 - - [16/Mar/2005:06:56:52 +1300] "GET /proxy.pac HTTP/1.1" 200 501 "-" "Mozilla/5.0 (X11; U; Linux i686; en-US; rv:1.7.5) Gecko/20050105 Debian/1.7.5-1"
127.0.0.1 - - [16/Mar/2005:06:58:55 +1300] "GET / HTTP/1.1" 200 5084 "-" "Mozilla/5.0 (X11; U; Linux i686; en-US; rv:1.7.5) Gecko/20050105 Debian/1.7.5-1"
127.0.0.1 - - [16/Mar/2005:06:58:55 +1300] "GET /style.css HTTP/1.1" 304 - "http://localhost/" "Mozilla/5.0 (X11; U; Linux i686; en-US; rv:1.7.5) Gecko/20050105 Debian/1.7.5-1"
127.0.0.1 - - [16/Mar/2005:06:58:55 +1300] "GET /utils.js HTTP/1.1" 304 - "http://localhost/" "Mozilla/5.0 (X11; U; Linux i686; en-US; rv:1.7.5) Gecko/20050105 Debian/1.7.5-1"
127.0.0.1 - - [16/Mar/2005:18:46:43 +1300] "GET /proxy.pac HTTP/1.1" 200 501 "-" "Mozilla/5.0 (X11; U; Linux i686; en-US; rv:1.7.5) Gecko/20050105 Debian/1.7.5-1"
127.0.0.1 - - [16/Mar/2005:18:46:46 +1300] "GET / HTTP/1.1" 200 5084 "-" "Mozilla/5.0 (X11; U; Linux i686; en-US; rv:1.7.5) Gecko/20050105 Debian/1.7.5-1"
EOF

my $bad_data = "< bogus >\n";

my $app = TestApp->make_test_app;

my($input, $parser, $perl, $sink) = $app->make_test_machine(qw(
  Sprog::Gear::TextInput
  Sprog::Gear::ApacheLogParse
  Sprog::Gear::PerlCodeHP
  LineGear
));
is($app->alerts, '', 'no alerts while creating machine');


isa_ok($parser, 'Sprog::Gear::ApacheLogParse', 'parser gear');
ok($parser->has_input, 'has input');
ok($parser->has_output, 'has output');
is($parser->input_type,  'P', 'correct input connector type (pipe)');
is($parser->output_type, 'H', 'correct input connector type (hash)');
is($parser->title, 'Parse Apache Log', 'title looks ok');
like($parser->dialog_xml, qr{<glade-interface>.*</glade-interface>}s, 
  'Glade XML looks plausible');
is($parser->log_format, 'combined', "default log format is 'combined'");

isa_ok($sink, 'LineGear', 'output gear');

isa_ok($perl, 'Sprog::Gear::PerlCodeHP', 'perl gear');
isa_ok($perl, 'Sprog::Gear');

ok($perl->has_input, 'has input');
ok($perl->has_output, 'has output');
is($perl->input_type,  'H', 'correct input connector type (hash)');
is($perl->output_type, 'P', 'correct input connector type (pipe)');
is($perl->title, 'Perl Code', 'title looks ok');
like($perl->dialog_xml, qr{<glade-interface>.*</glade-interface>}s, 
  'Glade XML looks plausible');
is($perl->perl_code, '', 'default Perl code is blank');

$input->text($data);

is($app->test_run_machine, '', 'run completed without timeout or alerts');
is_deeply([ $sink->lines ], [ ], 'no output by default');
$sink->reset;

$perl->perl_code('{');

like($app->test_run_machine, qr/syntax error/, 'syntax error captured successfully');

$perl->perl_code('$_ = "$r->{host}\n"');

is($app->test_run_machine, '', 'run completed without timeout or alerts');
is_deeply([ $sink->lines ], [ ("127.0.0.1\n") x 6 ], 'got expected output from $r');
$sink->reset;

$perl->perl_code('$_ = "$rec{host}\n"');

is($app->test_run_machine, '', 'run completed without timeout or alerts');
is_deeply([ $sink->lines ], [ ("127.0.0.1\n") x 6 ], 'got expected output from %rec');
$sink->reset;

$perl->perl_code('print "$rec{host}\n"');

is($app->test_run_machine, '', 'run completed without timeout or alerts');
is_deeply([ $sink->lines ], [ ("127.0.0.1\n") x 6 ], 'got expected output via print');
$sink->reset;

$perl->perl_code('
  next RECORD unless $r->{request} =~ /proxy/;
  $_ = "$r->{bytes_sent}\n"
');

is($app->test_run_machine, '', 'run completed without timeout or alerts');
is_deeply([ $sink->lines ], [ ("501\n") x 2 ], 'got expected output');
$sink->reset;

{
  my $warnings = '';
  local($SIG{__WARN__}) = sub { $warnings .= shift; };

  $parser->log_format('common');
  $input->text($bad_data);
  is($app->test_run_machine, '', 'run completed without timeout or alerts');
  is_deeply([ ], [ ], 'no output from bad data');
  like($warnings, qr/Could not parse: < bogus >/, 'got expected warning');
  $sink->reset;
}

exit;


package BrokenPerlCode;

use base qw(Sprog::Gear::PerlCode);

sub _sub_preamble  { return; }
sub _sub_postamble { return; }

sub _suppress_used_once_warning { $Sprog::Gear::PerlBase::GearDefaultProps; }
