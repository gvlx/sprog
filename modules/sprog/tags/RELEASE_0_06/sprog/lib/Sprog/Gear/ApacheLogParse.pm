package Sprog::Gear::ApacheLogParse;

use strict;

use base qw(Sprog::Gear);

use Apache::LogRegex;

__PACKAGE__->declare_properties(
  log_format => 'combined',
);

sub title { 'Parse Apache Log' };

sub output_type   { 'H'; }

sub prime {
  my $self = shift;

  my $lr = eval {
    Sprog::Gear::ApacheLogParse::Parser->new($self->format_string) 
  };
  if ($@) {
    $self->app->alert("Unable to parse log format string", $@);
    return;
  }

  $self->{lr} = $lr;

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

  return unless $self->{lr};

  my %data = eval { $self->{lr}->parse($line); };

  if(%data) {
    $self->msg_out(data => \%data);
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
