#!/usr/bin/env perl
use strict;
use warnings;

use File::Basename 'dirname';
use Cwd 'abs_path';

my $UTILS = abs_path(dirname(__FILE__)) . '/include/utils.pm';
require $UTILS;
my $CSV_PARSER = abs_path(dirname(__FILE__)) . '/include/CsvParser.pm';
require $CSV_PARSER;

package table1;

# File must be UTF8, no BOM, LF. Double quotes around values. First line must be column names. 
my $FILENAME = 'data/powercurve.csv';

# convert text file to array of strings
my @lines = CsvParser::slurp_into_arr($FILENAME);
# parse headers from first line and remove it from the array
my @headers = CsvParser::parse_headers(shift(@lines));
# 'our' makes a package variable, accessible from the outside as table1::results
our %results = ();

sub fill_results {
    foreach my $section_hierarchy ('Common Components', 'Plugins', 'Strategy Management') {
        foreach my $execution_type ('Automated', 'Manual') {
            foreach my $priority ('P1', 'P2', 'P3', 'P4') {
                my %filters = (
                    'Studio or Runtime' => ['\s?Studio'],
                    'Section Hierarchy' => [$section_hierarchy . '.*'],
                    'Execution Type' => ['\s?' . $execution_type],
                    'Priority' => [$priority . ' - .*']
                );
                my $regex = CsvParser::generate_regex(\@headers, %filters);
                my $c = utils::count_matched_elements(\@lines, $regex);
                $results{$section_hierarchy}{$execution_type}{$priority} = $c;
                $results{$section_hierarchy}{$priority} += $c;
                $results{$section_hierarchy}{'Total'} += $c;
                $results{'Total'}{$priority} += $c;
            }
        }
        $results{'Total'}{'Total'} += $results{$section_hierarchy}{'Total'};
    }
}

sub generate_csv_result {
    my ($product, $execution_type) = @_;
    my @cells = ($product, $results{$product}{'Total'});
    if($product eq 'Total') {
        # blank execution type
        push @cells, '';
        push @cells, utils::hash_values(%{$results{'Total'}});
        # remove 'Total' value already added before if statement
        pop @cells;
    } else {
        push @cells, ($execution_type);
        push @cells, utils::hash_values(%{$results{$product}{$execution_type}});
    }
    return utils::args_to_csv_line(@cells);
}

sub save_results {
    my $FILENAME = 'output_tables/table1.csv';
    open(my $fh, '>:encoding(UTF-8)', $FILENAME) or die "Can't open file $FILENAME, $!";
    print $fh utils::args_to_csv_line('Product', 'Total Test Cases in Library', 'Execution Type', 'Critical P1', 'High P2', 'Medium P3', 'Low P4');
    print $fh generate_csv_result('Common Components', 'Automated');
    print $fh generate_csv_result('Common Components', 'Manual');
    print $fh generate_csv_result('Plugins', 'Automated');
    print $fh generate_csv_result('Plugins', 'Manual');
    print $fh generate_csv_result('Strategy Management', 'Automated');
    print $fh generate_csv_result('Strategy Management', 'Manual');
    print $fh generate_csv_result('Total');
    close $fh;
}

package main;

unless(caller) {
    print "table1 main called\n";
    table1::fill_results();
    table1::save_results();
}
