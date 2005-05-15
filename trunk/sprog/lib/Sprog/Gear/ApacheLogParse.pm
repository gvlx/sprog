package Sprog::Gear::ApacheLogParse;

=begin sprog-gear-metadata

  title: Parse Apache Log
  type_in: P
  type_out: H

=end sprog-gear-metadata

=cut

use strict;

use base qw(
  Sprog::Gear
  Sprog::Gear::InputByLine
);

use Apache::LogRegex;

__PACKAGE__->declare_properties(
  log_format => 'combined',
);

sub prime {
  my $self = shift;

  my $parser = eval {
    Sprog::Gear::ApacheLogParse::Parser->new($self->format_string) 
  };
  if ($@) {
    $self->app->alert("Unable to parse log format string", $@);
    return;
  }

  $self->{parser} = $parser;

  return $self->SUPER::prime;
}


sub format_string {
  my $self = shift;
  
  my $log_format = $self->log_format;
  if($log_format eq 'common') {
    return '%h %l %u %t \"%r\" %>s %b';
  }
  else {
    return '%h %l %u %t \"%r\" %>s %b \"%{Referer}i\" \"%{User-Agent}i\"';
  }
}


sub line {
  my($self, $line) = @_;

  return unless $self->{parser};

  my %fields = eval { $self->{parser}->parse($line); };

  if(%fields) {
    $self->msg_out(record => \%fields);
  }
  else {
    warn "Could not parse: $line\n";
  }
}


sub dialog_xml {
#  return 'file:/home/grant/projects/sf/sprog/glade/apache_log.glade';
  return <<'END_XML';
<?xml version="1.0" standalone="no"?> <!--*- mode: xml -*-->
<!DOCTYPE glade-interface SYSTEM "http://glade.gnome.org/glade-2.0.dtd">

<glade-interface>

<widget class="GtkDialog" id="properties">
  <property name="title" translatable="yes">Properties</property>
  <property name="type">GTK_WINDOW_TOPLEVEL</property>
  <property name="window_position">GTK_WIN_POS_MOUSE</property>
  <property name="modal">False</property>
  <property name="resizable">True</property>
  <property name="destroy_with_parent">True</property>
  <property name="decorated">True</property>
  <property name="skip_taskbar_hint">True</property>
  <property name="skip_pager_hint">True</property>
  <property name="type_hint">GDK_WINDOW_TYPE_HINT_DIALOG</property>
  <property name="gravity">GDK_GRAVITY_NORTH_WEST</property>
  <property name="has_separator">True</property>

  <child internal-child="vbox">
    <widget class="GtkVBox" id="dialog-vbox1">
      <property name="visible">True</property>
      <property name="homogeneous">False</property>
      <property name="spacing">0</property>

      <child internal-child="action_area">
	<widget class="GtkHButtonBox" id="dialog-action_area1">
	  <property name="visible">True</property>
	  <property name="layout_style">GTK_BUTTONBOX_END</property>

	  <child>
	    <widget class="GtkButton" id="cancelbutton1">
	      <property name="visible">True</property>
	      <property name="can_default">True</property>
	      <property name="can_focus">True</property>
	      <property name="label">gtk-cancel</property>
	      <property name="use_stock">True</property>
	      <property name="relief">GTK_RELIEF_NORMAL</property>
	      <property name="focus_on_click">True</property>
	      <property name="response_id">-6</property>
	    </widget>
	  </child>

	  <child>
	    <widget class="GtkButton" id="okbutton1">
	      <property name="visible">True</property>
	      <property name="can_default">True</property>
	      <property name="has_default">True</property>
	      <property name="can_focus">True</property>
	      <property name="label">gtk-ok</property>
	      <property name="use_stock">True</property>
	      <property name="relief">GTK_RELIEF_NORMAL</property>
	      <property name="focus_on_click">True</property>
	      <property name="response_id">-5</property>
	    </widget>
	  </child>
	</widget>
	<packing>
	  <property name="padding">0</property>
	  <property name="expand">False</property>
	  <property name="fill">True</property>
	  <property name="pack_type">GTK_PACK_END</property>
	</packing>
      </child>

      <child>
	<widget class="GtkTable" id="table1">
	  <property name="border_width">10</property>
	  <property name="visible">True</property>
	  <property name="n_rows">1</property>
	  <property name="n_columns">1</property>
	  <property name="homogeneous">False</property>
	  <property name="row_spacing">0</property>
	  <property name="column_spacing">0</property>

	  <child>
	    <widget class="GtkVBox" id="vbox1">
	      <property name="visible">True</property>
	      <property name="homogeneous">False</property>
	      <property name="spacing">0</property>

	      <child>
		<widget class="GtkRadioButton" id="PAD.log_format.combined">
		  <property name="visible">True</property>
		  <property name="can_focus">True</property>
		  <property name="label" translatable="yes">Combined log format (with Referer &amp; User-agent)</property>
		  <property name="use_underline">True</property>
		  <property name="relief">GTK_RELIEF_NORMAL</property>
		  <property name="focus_on_click">True</property>
		  <property name="active">False</property>
		  <property name="inconsistent">False</property>
		  <property name="draw_indicator">True</property>
		</widget>
		<packing>
		  <property name="padding">0</property>
		  <property name="expand">False</property>
		  <property name="fill">False</property>
		</packing>
	      </child>

	      <child>
		<widget class="GtkRadioButton" id="PAD.log_format.common">
		  <property name="visible">True</property>
		  <property name="can_focus">True</property>
		  <property name="label" translatable="yes">Common log format (CLF)</property>
		  <property name="use_underline">True</property>
		  <property name="relief">GTK_RELIEF_NORMAL</property>
		  <property name="focus_on_click">True</property>
		  <property name="active">False</property>
		  <property name="inconsistent">False</property>
		  <property name="draw_indicator">True</property>
		  <property name="group">PAD.log_format.combined</property>
		</widget>
		<packing>
		  <property name="padding">0</property>
		  <property name="expand">False</property>
		  <property name="fill">False</property>
		</packing>
	      </child>
	    </widget>
	    <packing>
	      <property name="left_attach">0</property>
	      <property name="right_attach">1</property>
	      <property name="top_attach">0</property>
	      <property name="bottom_attach">1</property>
	      <property name="x_options">fill</property>
	    </packing>
	  </child>
	</widget>
	<packing>
	  <property name="padding">5</property>
	  <property name="expand">True</property>
	  <property name="fill">True</property>
	</packing>
      </child>
    </widget>
  </child>
</widget>

</glade-interface>
END_XML
}


package Sprog::Gear::ApacheLogParse::Parser;

use base 'Apache::LogRegex';

my %common_fields;

BEGIN {
  %common_fields = (
    '%a'  => 'client_ip',
    '%A'  => 'server_ip',
    '%b'  => 'bytes_sent',
    '%B'  => 'ibytes_sent',
    '%c'  => 'connection_status',
    '%f'  => 'filename',
    '%h'  => 'host',
    '%H'  => 'protocol',
    '%l'  => 'client_login',
    '%m'  => 'method',
    '%p'  => 'server_port',
    '%P'  => 'server_pid',
    '%q'  => 'query_string',
    '%r'  => 'request',
    '%>s' => 'status',
    '%s'  => 'initial_status',
    '%t'  => 'time',
    '%T'  => 'elapsed_time',
    '%u'  => 'auth_user',
    '%U'  => 'url_path',
    '%v'  => 'canonical_server_name',
    '%V'  => 'server_name',
  );
}

sub new {
  my($class, $log_format) = @_;

  return $class->SUPER::new($log_format);
}


sub rename_this_name {
  my($self, $name) = @_;

  return $common_fields{$name} if exists $common_fields{$name};

  if($name =~ /\{(.+?)\}(.)/) {
    if($2 eq 't') {
      return 'strftime';
    }
    $name = $1;
    $name .= '-out'  if $2 eq 'o';
    $name .= '-note' if $2 eq 'n';
  }

  return $name;
}

1;

__END__



=head1 NAME

Sprog::Gear::ApacheLogParse - parses Apache log entries into records

=head1 DESCRIPTION

This gear parses Apache access log entries by reading data a line at a time
from the 'pipe' input connector and producing a matching output 'record' for
each line.  The fields from the log entry are parsed into keys in the the hash
record.

=head1 SEE ALSO

This module uses L<Apache::LogRegex> for the parsing.

=head1 COPYRIGHT 

Copyright 2004-2005 Grant McLean E<lt>grantm@cpan.orgE<gt>

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself. 


=begin :sprog-help-text

=head1 Parse Apache Log Gear

The 'Parse Apache Log' gear takes a line at a time from the input 'pipe'
connector and produces data for the output 'record' connector.

Lines which match the selected Apache log file format will be split out into
separate keys in the output record.  Lines which cannot be parsed will be
ignored.

=head2 Properties

The Parse Apache Log gear has only one property - the log format.  Select one 
of:

=over 4

=item *

Combined log format (with Referer and User-agent)

=item *

Common log format (CLF)

=back

=head2 Output Record Format

The output record (hash) will have the following keys:

  host
  client_login
  auth_user
  time
  request
  status
  bytes_sent
  User-Agent
  Referer

The last two keys will not be present if the 'Common Log Format' was selected.

I<Remember, the hash keys are both case-sensitive and unordered>.

=end :sprog-help-text

