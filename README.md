zip-tests
=========

Test suite of Zip (Info-Zip) utilities. I will be glad if you add your hands
and write some suggestions, tips or tests.

It's created for testing of new upstream versions (avalable on
ftp://ftp.info-zip.org/pub/infozip/beta/). I think that tests
could be helpfull for next development for upstream and also zip maintainers.

Usage
=====
 tests.sh [--nocolors] [--unzip FILE] [--zip FILE] [--zipnote FILE]
           [-c | --compact VAL] [ --run-test test_function ] [-h | --help]

    --nocolors      No colored output

    --unzip FILE    Will be used this script as unzip.
                    Default: /usr/bin/unzip

    --zip FILE      Will be sed this script as zip.
                    Default: /usr/bin/zip

    --zipnote FILE  Will be used this script as zipnote
                    Default: /usr/bin/zipnote

    --run-test test_function
                    Run only test with same name of function

    -c, --compact VAL
                    Create compact output. VAL can be number 1..5.
                    1 - suppress output from  utilities and error messages
                        and print only basic info about tests.

                    2 - print whole output and basic info about success of each
                        test print one more time after ends of tests

                    3 - similar to 2, but logged errors are print by between
                        compact output after tests are completed. In this case
                        these errors are printed to STDOUT istead of STDERR

                    4 - similar to 3 with suppressed output from utilities,
                        but prints basic info about test (it's like progress)

                    5 - similar to 4, but suppressed any output during testing


    -h, --help      Print this help.


Notes
=====
I recommend same PWD as basedir of this script. In other cases may some bugs
could be found.
