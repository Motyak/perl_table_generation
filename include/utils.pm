package utils;

sub is_in_array {
    my ($str, $array) = @_;
    foreach (@$array) {
        if($_ eq $str) {
            return 1;
        }
    }
    return 0;
}

sub hash_values {
    my %hash = @_;
    my @values = ();
    foreach (sort keys %hash) {
        push @values, $hash{$_};
    }
    return @values;
}

sub count_matched_elements {
    my ($array, $regex) = @_;
    my $i = 0;
    foreach (@$array) {
        if($_ =~ $regex) {
            $i++;
        }
    }
    return $i;
}

sub args_to_csv_line {
    my (@args) = @_;
    return join(',', map {'"' . $_ . '"'} @args) . "\n";
}

1;
