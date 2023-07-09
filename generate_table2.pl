#!/usr/bin/env perl
use strict;
use warnings;

use File::Basename 'dirname';
use Cwd 'abs_path';

my $UTILS = abs_path(dirname(__FILE__)) . '/include/utils.pm';
require $UTILS;
my $CSV_PARSER = abs_path(dirname(__FILE__)) . '/include/CsvParser.pm';
require $CSV_PARSER;
# allow us to access table1 package subroutines and variables
my $GENERATE_TABLE1 = abs_path(dirname(__FILE__)) . '/generate_table1.pl';
require $GENERATE_TABLE1;

package table2;

# File must be UTF8, no BOM, LF. Double quotes around values. First line must be column names. 
my $FILENAME = 'data/eo_sds.csv';

# convert text file to array of strings
my @lines = CsvParser::slurp_into_arr($FILENAME);
# parse headers from first line and remove it from the array
my @headers = CsvParser::parse_headers(shift(@lines));
my %results = ();

sub fill_results {
    table1::fill_results();
    foreach my $section_hierarchy ('Common Components', 'Plugins', 'Strategy Management') {
        foreach my $execution_type ('Automated', 'Manual') {
            foreach my $priority ('P1', 'P2', 'P3', 'P4') {
                my %filters = (
                    'Section Hierarchy' => [$section_hierarchy . '.*'],
                    'Execution Type' => ['\s?' . $execution_type],
                    'Priority' => [$priority . ' - .*']
                );
                my $regex = CsvParser::generate_regex(\@headers, %filters);
                my $c = utils::count_matched_elements(\@lines, $regex);
                $results{$section_hierarchy}{$execution_type}{$priority} = $c;
                $results{$section_hierarchy}{$priority} += $c;
                $results{$section_hierarchy}{'Total'} += $c;
                if($table1::results{$section_hierarchy}{$priority} != 0) {
                    $results{'Proportion'}{$section_hierarchy}{$priority} 
                        += ($c / $table1::results{$section_hierarchy}{$priority} * 100);
                } else {
                    # null dividor means no proportion
                    $results{'Proportion'}{$section_hierarchy}{$priority} = '-';
                }
            }
        }
        if($table1::results{$section_hierarchy}{'Total'} != 0) {
            $results{'Proportion'}{$section_hierarchy}{'Total'}
                += ($results{$section_hierarchy}{'Total'} / $table1::results{$section_hierarchy}{'Total'} * 100);
        } else {
            # null dividor means no proportion
            $results{'Proportion'}{$section_hierarchy}{'Total'} = '-';
        }
    }
}

sub generate_csv_result {
    my ($product) = @_;
    my @cells = ();
    if($_[1] eq 'Proportion') {
        push @cells, 'Proportion of Test Library (%)';
        push @cells, $results{'Proportion'}{$product}{'Total'};
        # blank execution type
        push @cells, '';
        push @cells, utils::hash_values(%{$results{'Proportion'}{$product}});
        # remove 'Total' value already added before
        pop @cells;
    } else {
        push @cells, $product;
        push @cells, $results{$product}{'Total'};
        # $_[1] corresponds to execution type in this conditional branch #
        push @cells, $_[1];
        push @cells, utils::hash_values(%{$results{$product}{$_[1]}});
    }
    return utils::args_to_csv_line(@cells);
}

sub save_results {
    my $FILENAME = 'output_tables/table2.csv';
    open(my $fh, '>:encoding(UTF-8)', $FILENAME) or die "Can't open file $FILENAME, $!";
    print $fh '"Product","Total Test Cases Run during Release Endgame","Execution Type","Critical P1","High P2","Medium P3","Low P4"' . "\n";
    print $fh generate_csv_result('Common Components', 'Automated');
    print $fh generate_csv_result('Common Components', 'Manual');
    print $fh generate_csv_result('Common Components', 'Proportion');
    print $fh generate_csv_result('Plugins', 'Automated');
    print $fh generate_csv_result('Plugins', 'Manual');
    print $fh generate_csv_result('Plugins', 'Proportion');
    print $fh generate_csv_result('Strategy Management', 'Automated');
    print $fh generate_csv_result('Strategy Management', 'Manual');
    print $fh generate_csv_result('Strategy Management', 'Proportion');
    close $fh;
}

package main;

unless(caller) {
    print "table2 main called\n";
    table2::fill_results();
    table2::save_results();
}
