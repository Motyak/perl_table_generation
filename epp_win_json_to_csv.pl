#!/usr/bin/env perl
use strict;
use warnings;

sub parse_csv_line {
    my ($str) = @_;
    return map {substr($_, 1, -1)} split(',', $str);
}

# get caseid and product row indices #
sub get_indices {
    my ($header_as_str) = @_;
    my @header = parse_csv_line($header_as_str);
    my @res = ();
    foreach my $col_name ('ID', 'Section Hierarchy') {
        for my $i (0..scalar(@header)-1) {
            if($header[$i] eq $col_name) {
                push @res, $i;
            }
        }
    }
    return @res;
}

sub parse_caseid_product {
    my ($str, $caseid_index, $product_index) = @_;
    my @cells = parse_csv_line($str);
    my $case_id = $cells[$caseid_index] =~ s/^.//r;
    my ($product) = $cells[$product_index] =~ /^(.*?)(?:$| > )/gm;
    return ($case_id, $product);
}

# read powercurve.csv and create hash map associating each case id to its product type #
my $POWERCURVE_FILENAME = 'data/powercurve.csv';
my %product = ();
open(my $fh, '<:encoding(UTF-8)', $POWERCURVE_FILENAME) or die "Can't open file $POWERCURVE_FILENAME, $!";
chomp(my @lines = <$fh>);
close($fh);
my ($caseid_col_index, $product_col_index) = get_indices(shift @lines);
my ($case_id, $product);
foreach (@lines) {
    ($case_id, $product) = parse_caseid_product($_, $caseid_col_index, $product_col_index);
    $product{$case_id} = $product;
}

# load .epp_win.json as string #
my $JSON_FILENAME = 'data/.epp_win.json';
my $json;
{
    open(my $fh, '<:encoding(UTF-8)', $JSON_FILENAME) or die "Can't open file $JSON_FILENAME, $!";
    local $/ = undef;
    $json = <$fh>;
    close $fh;
}

# parse json id fields #
my @cases = ($json =~ /\s*"case_id"\s*:\s*(\d+)/gs);
my @priorities = ($json =~ /\s*"priority_id"\s*:\s*(\d+)/gs);
my @statuses = ($json =~ /\s*"status_id"\s*:\s*(\d+)/gs);
unless(scalar(@cases) eq scalar(@priorities) and scalar(@priorities) eq scalar(@statuses)) {
    die "Invalid JSON data in $JSON_FILENAME";
}

# TestRails constants #
my %priority = (
    4 => 'P1 - Critical',
    3 => 'P2 - High',
    2 => 'P3 - Medium',
    1 => 'P4 - Low'
);
my %status = (
    1 => 'Passed',
    5 => 'Failed',
    2 => 'Blocked',
    7 => 'Skip',
    4 => 'Retest'
);

# write epp_win.csv #
my $CSV_FILENAME = 'data/epp_win.csv';
open($fh, '>:encoding(UTF-8)', $CSV_FILENAME) or die "Can't open file $CSV_FILENAME, $!";
print $fh '"Status","Priority","Product"' . "\n";
for my $i (0..scalar(@cases)-1) {
    print $fh '"' . $status{$statuses[$i]} . '","' 
        . $priority{$priorities[$i]} . '","' 
        . $product{$cases[$i]} . '"' . "\n";
}
close $fh;
