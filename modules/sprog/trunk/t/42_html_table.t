use Sprog::TestHelper tests => 32, requires => 'XML::LibXML';

use_ok('TestApp');
use_ok('Sprog::Gear::ParseHTMLTable');

my $app = TestApp->make_test_app;

my($source, $parser, $sink) = $app->make_test_machine(qw(
  Sprog::Gear::TextInput
  Sprog::Gear::ParseHTMLTable
  ListSink
));
is($app->alerts, '', 'no alerts while creating machine');

isa_ok($parser, 'Sprog::Gear::ParseHTMLTable', 'filter gear');
isa_ok($parser, 'Sprog::Gear',                 'filter gear also');

ok($parser->has_input, 'has input');
ok($parser->has_output, 'has output');
is($parser->input_type,  'P', 'correct input connector type (pipe)');
is($parser->output_type, 'A', 'correct output connector type (list)');
is($parser->title, 'Parse HTML Table', 'title looks ok');
like($parser->dialog_xml, qr{<glade-interface>.*</glade-interface>}s, 
  'Glade XML looks plausible');
ok(!$parser->no_properties, "filter gear has properties");
is($parser->selector, '1', "default table selector is '1'");


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
    <tr><td>one</td><td>two</td></tr>
    <tr><td>buckle</td><td>your shoe</td></tr>
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


$html = <<'EOF';
<HTML>
<HEAD>
  <TITLE>TITLE</TITLE>
</HEAD>
<BODY>
  <TABLE>
    <TR><TH>three</TH><TH>four</TH></TR>
    <TR><TD>knock on</TD><TD>the door</TD></TR>
  </TABLE>
</BODY>
</HTML>
EOF

$source->text($html);

is($app->test_run_machine, '', "same again but with <TH> and <TD> tags");

is_deeply([ $sink->rows ], [
    [ 'three', 'four' ],
    [ 'knock on', 'the door' ],
  ],
  "correct data was extracted");


$html = <<'EOF';
<html>
<head>
  <title>TITLE</title>
</head>
<body>
  <table>
    <thead>
      <tr><th>Seven</th><th>Eight</th></tr>
    </thead>
    <tbody>
      <tr><td colspan=2>Don't be late</td></tr>
    </tbody>
  </table>
</body>
</html>
EOF

$source->text($html);

is($app->test_run_machine, '', "now with <thead>, <tbody> and unquoted attr");

is_deeply([ $sink->rows ], [
    [ 'Seven', 'Eight' ],
    [ "Don't be late" ],
  ],
  "correct data was extracted");


$html = <<'EOF';
<html>
<head>
  <title>TITLE</title>
</head>
<body>

  <h1>First Heading</h1>
  <table>
    <tr><td>one</td><td>two</td></tr>
    <tr><td>buckle</td><td>your shoe</td></tr>
  </table>

  <table>
    <tr><td>five</td><td>six</td></tr>
    <tr><td> pick up </td><td><font size="large"><b>STICKS!</b></font></td></tr>
  </table>

  <h1>Second Heading</h1>
  <div class="products">
    <table>
      <thead>
        <tr><th>Product Name</th><th>Part Number</th><th>Qty</th></tr>
      </thead>
      <tbody>
        <tr><td>Umbrella</td><td>123-4567-890</td><td>80</td></tr>
        <tr><td>Saw Horse</td><td>123-4567-891</td><td>9871</td></tr>
        <tr><td>Ballpoint Pen</td><td>123-4567-892</td><td>1</td></tr>
      </tbody>
    </table>
  </div>

  <h1>Third Heading</h1>
  <div class="table-soup">
    <table>
      <tr>
         <td><img src="corp-logo.gif"></td>
         <td><h1>Big Heading</h1></td>
      </tr>
      <tr>
         <td>
           <div id="nav-links">

             <table>
               <tr>
                 <td><img src="bullet.gif"></td>
                 <td><a href="#">First Option</a></td>
               </tr>
               <tr>
                 <td><img src="bullet.gif"></td>
                 <td><a href="#">Second Option</a></td>
               </tr>
               <tr>
                 <td><img src="bullet.gif"></td>
                 <td><a href="#">Third Option</a></td>
               </tr>
             </table>
           </div>
         </td>
         <td>

           <table>

             <tr>
               <th>Division</th>
               <th>Address</th>
               <th>Phone</th>
             </tr>

             <tr>
               <td>Manufacturing</td>
               <td>
                 2130 Franklin Drive<br>
                 Maketon
               </td>
               <td>555-1234</td>
             </tr>

             <tr>
               <td>Marketing</td>
               <td>
                 Penthouse Suite<br>
                 Strump Tower<br>
                 8650 4th Avenue<br>
                 Big City
               </td>
               <td>555-4321</td>
             </tr>

           </table>
         
         </td>
      </tr>
    </table>
  </div>

</body>
</html>
EOF

$source->text($html);
$parser->selector('3');

is($app->test_run_machine, '', "successfully parsed some rather unpleasant HTML");

is_deeply([ $sink->rows ], [
    [ 'Product Name', 'Part Number', 'Qty' ],
    [ 'Umbrella', '123-4567-890', '80' ],
    [ 'Saw Horse', '123-4567-891', '9871' ],
    [ 'Ballpoint Pen', '123-4567-892', '1' ],
  ],
  "extracted contents of nested table using a numeric selector");


$source->text($html);
$parser->selector(q{//table[./tr[1]/*[1 and contains(text(), 'Division')]]});

is($app->test_run_machine, '', "successfully parsed some rather unpleasant HTML");

is_deeply([ $sink->rows ], [
    [ 'Division', 'Address', 'Phone' ],
    [ 'Manufacturing', '
                 2130 Franklin Drive
                 Maketon
               ', '555-1234' ],
    [ 'Marketing', '
                 Penthouse Suite
                 Strump Tower
                 8650 4th Avenue
                 Big City
               ', '555-4321' ],
  ],
  "extracted contents of table selected using an XPath expression");


my($filter);
($source, $parser, $filter, $sink) = $app->make_test_machine(qw(
  MessageSource
  Sprog::Gear::ParseHTMLTable
  Sprog::Gear::ListToCSV
  MessageSink
));
is($app->alerts, '', 'no alerts while creating new machine');


# Confirm file start/end events are passed in correct sequence

$html = <<'EOF';
<html>
<body>
  <table>
    <tr><td>one</td><td>two</td></tr>
    <tr><td>three</td><td>four</td></tr>
  </table>
</body>
</html>
EOF

$source->messages(
  [ file_start => 'table.html' ],
  [ data       => $html        ],
  [ file_end   => 'table.html' ],
);

is($app->test_run_machine, '', 'processed message stream without errors');

is_deeply([ $sink->messages ], [
    [ file_start => 'table.html'   ],
    [ data       => "one,two\n"    ],
    [ data       => "three,four\n" ],
    [ file_end   => 'table.html'   ],
  ], 
  "got expected messages"
);
