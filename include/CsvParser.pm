package CsvParser;

sub slurp_into_arr {
    my ($filename) = @_;
    open(my $fh, '<:encoding(UTF-8)', $filename) or die "Can't open file $filename, $!";
    chomp(my @lines = <$fh>);
    close($fh);
    return @lines;
}

sub parse_headers {
    my ($str) = @_;
    return map {substr($_, 1, -1)} split(',', $str);
}

sub generate_regex {
    my ($headers, %filters) = @_;
    my ($regex, $filter) = '"';
    # error handling #
    foreach my $k (keys %filters) {
        unless(utils::is_in_array($k, $headers)) {
            die "Header '" . $k . "' used in filters but not found in headers";
        }
    }
    foreach (@$headers) {
        # add all possible options if any otherwise accept everything (with .*)
        $filter = (exists $filters{$_}) ? '(' . join('|', @{$filters{$_}}) . ')' : '.*';
        $regex .= $filter . '","';
    }
    # remove last ',"'
    return substr($regex, 0, -2);
}

1;
