#!/bin/bash

function ask_for_credentials {
    read -rp "Enter TestRail username (experianuk\LANID): " user
    read -sp "Enter password for user \"$user\": " pwd; echo
}

function get_supplementary_tests_file {
    EPP_WINDOWS_RUN_ID=2469
    SUPLEMENTARY_TESTS_FILENAME='data/.epp_win.json'
    [[ -v user ]] || ask_for_credentials
    curl -sS \
        -H 'Content-Type: application/json' \
        -u "$user:$pwd" \
        -o $SUPLEMENTARY_TESTS_FILENAME \
        "testrail-gsg.experian.local/index.php?/api/v2/get_tests/$EPP_WINDOWS_RUN_ID"
    if [ $(head -c 8 $SUPLEMENTARY_TESTS_FILENAME) == '{"error"' ]; then
        cat $SUPLEMENTARY_TESTS_FILENAME; echo
        exit 1
    fi
    perl epp_win_json_to_csv.pl 2> /dev/null
}

mkdir -p data output_tables

# get input files #
    get_supplementary_tests_file
    FILENAMES="powercurve eo_sds epp_win"
    for f in $FILENAMES; do
        # remove the BOM if existing
        sed -i 's/^\xEF\xBB\xBF//' data/$f.csv

        # CRLF to LF (remove any CR)
        sed -i 's/\r//' data/$f.csv

        # put double quotes if missing #
        sed -ri '/^"|"$/! s/^(.*)$/"\1"/gm' data/$f.csv
        sed -i '/",/! s/,/","/gm' data/$f.csv
    done

# generate output files #
    for script in generate_table*.pl; do
        perl $script 2> /dev/null
    done
