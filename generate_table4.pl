#!/usr/bin/env perl
use strict;
use warnings;

use File::Basename 'dirname';
use Cwd 'abs_path';

my $UTILS = abs_path(dirname(__FILE__)) . '/include/utils.pm';
require $UTILS;
my $CSV_PARSER = abs_path(dirname(__FILE__)) . '/include/CsvParser.pm';
require $CSV_PARSER;

package table4;

# File must be UTF8, no BOM, LF. Double quotes around values. First line must be column names. 
my $FILENAME = 'data/epp_win.csv';

# convert text file to array of strings
my @lines = CsvParser::slurp_into_arr($FILENAME);
# parse headers from first line and remove it from the array
my @headers = CsvParser::parse_headers(shift(@lines));
my %results = ();

sub fill_results {
    foreach my $product ('Common Components', 'Strategy Management') {
        foreach my $priority ('P3', 'P4') {
            foreach my $status ('Passed', 'Failed', 'Blocked', 'Skipped') {
                my %filters = (
                    'Product' => [$product . '.*'],
                    'Priority' => [$priority . ' - .*'],
                    'Status' => [$status]
                );
                my $regex = CsvParser::generate_regex(\@headers, %filters);
                my $c = utils::count_matched_elements(\@lines, $regex);
                $results{$product}{$priority}{$status} = $c;
                $results{$product}{$priority}{'Executed'} += $c;
                $results{'Total'}{$status} += $c;
                $results{'Total'}{'Executed'} += $c;
            }
            # alias to make the following code more readable
            my %h = %{$results{$product}{$priority}};
            if($h{'Executed'} != 0) {
                $results{$product}{$priority}{'Pass Rate'} = $h{'Passed'} / $h{'Executed'} * 100;
                $results{$product}{$priority}{'Failure Rate'} = $h{'Failed'} / $h{'Executed'} * 100;
            } else {
                # null dividor means no proportion
                $results{$product}{$priority}{'Pass Rate'} 
                    = $results{$product}{$priority}{'Failure Rate'} 
                    = '-';
            }
        }
    }
    # we assume $results{'Total'}{'Executed'} will never be 0, which seems reasonable #
    $results{'Total'}{'Pass Rate'} = $results{'Total'}{'Passed'} / $results{'Total'}{'Executed'} * 100;
    $results{'Total'}{'Failure Rate'} = $results{'Total'}{'Failed'} / $results{'Total'}{'Executed'} * 100;
}

sub generate_csv_result {
    my ($product, $priority) = @_;
    my @cells = ($product);

    if($product eq 'Total') {
        # blank priority
        push @cells, '';
        push @cells, (
            $results{'Total'}{'Executed'}, $results{'Total'}{'Passed'},
            $results{'Total'}{'Failed'}, $results{'Total'}{'Blocked'},
            $results{'Total'}{'Skipped'}, $results{'Total'}{'Pass Rate'},
            $results{'Total'}{'Failure Rate'}
        );
    } else {
        # alias to make the following code more readable
        my %h = %{$results{$product}{$priority}};
        push @cells, (
            $priority, $h{'Executed'}, $h{'Passed'}, 
            $h{'Failed'}, $h{'Blocked'}, $h{'Skipped'},
            $h{'Pass Rate'}, $h{'Failure Rate'}
        );
    }
    return utils::args_to_csv_line(@cells);
}

sub save_results {
    my $FILENAME = 'output_tables/table4.csv';
    open(my $fh, '>:encoding(UTF-8)', $FILENAME) or die "Can't open file $FILENAME, $!";
    print $fh '"Product / Service","Priority","Total Test Cases Executed","Passed","Failed","Blocked","Skipped","Pass Rate (%)","Failure Rate (%)"' . "\n";
    print $fh generate_csv_result('Common Components', 'P3');
    print $fh generate_csv_result('Common Components', 'P4');
    print $fh generate_csv_result('Strategy Management', 'P3');
    print $fh generate_csv_result('Strategy Management', 'P4');
    print $fh generate_csv_result('Total');
    close $fh;
}

package main;

unless(caller) {
    print "table4 main called\n";
    table4::fill_results();
    table4::save_results();
}
