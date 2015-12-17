package Collectd::Plugins::SurfBoard;

use strict;
use warnings;

use Collectd qw( :all );
use HTML::TableExtract;
use LWP::Simple qw($ua get);

my $page;
my @channel_id;
my @frequency;
my @snr;
my @power;
my @unerrored;
my @correctable;
my @uncorrectable;

sub extract_values {
  my @vals;

  foreach my $column (@{$_[0]}) {
    $column =~ /$_[1]/;
    push @vals, $1;
  }

  return @vals;
}

sub sb_init {
  $ua->timeout(3);
  return 1;
}

sub sb_read {
  my $page = get('http://192.168.100.1/cmSignalData.htm');

  if (!$page) {
    plugin_log(ERROR,"Could not read Surfboard signal page.");
    return 0;
  }

  my %v = ('host'=>$hostname_g, 'interval'=>plugin_get_interval(), 'time'=>time(), 'plugin'=>'surfboard');

  for my $signal_type ('Downstream', 'Upstream', 'Signal Stats (Codewords)') {
    my $headers = [quotemeta($signal_type), 'Bonding Channel Value'];
    my $table_extract = HTML::TableExtract->new(
      headers => $headers,
      slice_columns => 0
    );

    $table_extract->parse($page);
    my ($table) = $table_extract->tables;
  
    for my $row ($table->rows) {
      my $item = shift(@$row);

      if ($item eq 'Channel ID') {
        @channel_id = extract_values(\@$row, '(\d*).*');
      } elsif ($item eq 'Frequency') {
        @frequency = extract_values(\@$row, '(\d*) Hz.*');
      } elsif ($item eq 'Signal to Noise Ratio') {
        @snr = extract_values(\@$row, '(\d*) dB.*');
      } elsif ($item eq 'Power Level') {
        @power = extract_values(\@$row, '(\d*) dBmV.*');
      } elsif ($item eq 'Total Unerrored Codewords') {
        @unerrored = extract_values(\@$row, '(\d*).*');
      } elsif ($item eq 'Total Correctable Codewords') {
        @correctable = extract_values(\@$row, '(\d*).*');
      } elsif ($item eq 'Total Uncorrectable Codewords') {
        @uncorrectable = extract_values(\@$row, '(\d*).*');
      }
    }

    if ($signal_type eq 'Downstream') {
      for my $i (0 .. $#channel_id) {
        $v{'type'}='sb_downstream';
        $v{'type_instance'}=$channel_id[$i];
        $v{'values'}=();
        $v{'values'}[0]=$channel_id[$i];
        $v{'values'}[1]=$frequency[$i];
        $v{'values'}[2]=$snr[$i];
        $v{'values'}[3]=$power[$i];
        plugin_dispatch_values(\%v);
      }
    } elsif ($signal_type eq 'Upstream') {
      for my $i (0 .. $#channel_id) {
        $v{'type'}='sb_upstream';
        $v{'type_instance'}=$channel_id[$i];
        $v{'values'}=();
        $v{'values'}[0]=$channel_id[$i];
        $v{'values'}[1]=$frequency[$i];
        $v{'values'}[2]=$power[$i];
        plugin_dispatch_values(\%v);
      }
    } elsif ($signal_type eq 'Signal Stats (Codewords)') {
      for my $i (0 .. $#channel_id) {
        $v{'type'}='sb_codewords';
        $v{'type_instance'}=$channel_id[$i];
        $v{'values'}=();
        $v{'values'}[0]=$channel_id[$i];
        $v{'values'}[1]=$unerrored[$i];
        $v{'values'}[2]=$correctable[$i];
        $v{'values'}[3]=$uncorrectable[$i];
        plugin_dispatch_values(\%v);
      }
    }
  }

  return 1;
}

plugin_register(TYPE_READ, 'SurfBoard', 'sb_read');
plugin_register(TYPE_INIT, 'SurfBoard', 'sb_init');

return 1;
