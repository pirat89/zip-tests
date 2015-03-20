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
          [-h | --help]

    --nocolors      No colored output
    
    --unzip FILE    Will be used this script as unzip.
                    Default: /usr/bin/unzip   

    --zip FILE      Will be sed this script as zip.
                    Default: /usr/bin/zip

    --zipnote FILE  Will be used this script as zipnote
                    Default: /usr/bin/zipnote

    -h, --help      Print this help.


Notes
=====
Colored output - Yes, it's not ideal for every output. It can be removed
or will be added commandline option for colored output. For me is good now.

I recommend same PWD as basedir of this script. In other cases may some bugs
could be found.
