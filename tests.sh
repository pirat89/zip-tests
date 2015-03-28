#!/bin/bash
# This script is created for testing of InfoZip utilities on Linux systems
# and probably will not work right on the other system.
# I didn't test it.

# - I hope that unzip will not be generator of errors :-)
# NOTE: may I will add some option for skipping unzip-tests
#       or alternative results (as FAILED_CHECK or something similar)

#TODO: store results of tests to variable (array). add function for
# check of previous results
# add option for print of results s

#zip="../zip"
#unzip="../unzip"
#zipnote="../zipnote"
zipnote="$( which zipnote )"
zip="$(which zip)"
unzip="$(which unzip)"
scriptname="$(basename "$0")"
TEST_DIR="test_dir"
cd "${0%$scriptname}"
_SCRIPT_PWD="$PWD"
COMPACT=0
__tmp_output=""
only_test=""


#################################################
# USAGE
#################################################
print_usage() {
  echo "
 tests.sh [--nocolors] [--unzip FILE] [--zip FILE] [--zipnote FILE]
          [-c | --compact VAL] [ --run-test test_function ] [-h | --help]

    --nocolors      No colored output

    --unzip FILE    Will be used this script as unzip.
                    Default: $(which unzip)

    --zip FILE      Will be sed this script as zip.
                    Default: $(which zip)

    --zipnote FILE  Will be used this script as zipnote
                    Default: $(which zipnote)

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
"
}

#################################################
# PROCESS PARAMETERS                            #
#################################################
NOCOLORS=0
while [[ $1 != "" ]]; do
  param="$(echo "$1" | sed -r "s/^(.*)=.*/\1/")"

  if [[ "$param" != "$1"  ]]; then
     _VAL=$(echo "$1" | sed -r "s/^.*=(.*)/\1/g");
     _USED_NEXT=0
  else
     _VAL="$2"
     _USED_NEXT=1
  fi

  case "$param" in
    --help | -h)
      print_usage
      exit 0
      ;;

    --nocolors)
      NOCOLORS=1
      ;;

    --unzip)
      unzip="$_VAL"
      shift $_USED_NEXT
      ;;

    --zip)
      zip="$_VAL"
      shift $_USED_NEXT
      ;;

    --zipnote)
      zipnote="$_VAL"
      shift $_USED_NEXT
      ;;

    --run-test)
      only_test="$_VAL"
      shift $_USED_NEXT
      ;;

    -c | --compact)
      echo "$_VAL" | grep -qE "^[1-5]$"
      [ $? -ne 0 ] && {
        echo "Wrong parameter of compact! Only value from 1 to 5 can be used!" >&2
        exit 1;
      }
      COMPACT=$_VAL
      shift $_USED_NEXT
      ;;

    *)
    echo "Unknown option '$param'" >&2
    exit 1
    ;;
  esac
  shift
done

#################################################
#################################################
if [[ ! -e "$zip" ]]; then
  echo "Script Error: File $zip doesn't exists." >&2
  exit 1
fi

if [[ ! -e "$unzip" ]]; then
  echo "Script Error : File $unzip doesn't exists." >&2
  exit 1
fi

if [[ ! -e "$zipnote" ]]; then
  echo "Script Error: File $zipnote doesn't exists." >&2
  exit 1
fi

for i in "diff" "cmp"; do
  which $i >/dev/null 2>/dev/null && [[ -f "$(which $i)" ]] || {
    echo "Script error: Utility $i is missing! This utility is required for testing!" >&2
    exit 1
  }
done


[ -n "$TEST_DIR" ] || {
  echo "EMPTY destination of TEST_DIR!! Threatens remove of all files on disk!" >2&
  exit 2
}

rm -rf "$TEST_DIR"
mkdir "$TEST_DIR" || {
  echo "Error: test directory wasn't created!"
  exit 1
}

#################################################
# BASIC FUNCTIONS & VARS                        #
#################################################
# here are basic functions and variables for easier testing
# you can add here other functions which are helpfull for you

FAILED=0
PASSED=0
SKIPPED=0 # some functions don't have to be available (e.g. bzip,...)
ERRORS=0 # maybe will be able to used/implemented later
__zip_version="$($zip -v | head -n 2 | tail -n 1 | cut -d " " -f 4)"
__unzip_version="$($unzip -vqqqq)"

__TEST_COUNTER=1

if [[ $NOCOLORS -eq 0 ]]; then
  green='\e[1;32m'
  red='\e[1;31m'
  cyan='\e[1;36m'
  endColor='\e[0m'
else
  green=""
  red=""
  cyan=""
  endcolor=""
fi

TEST_TITLE=""
DTEST_DIR="$TEST_DIR/$TEST_DIR" # double testdir - for unzipped files

set_title() {
  TEST_TITLE="$*"
}

clean_test_dir() {
  [ -n "$TEST_DIR" ] || {
    echo "EMPTY destination of TEST_DIR!! Threatens remove of all files on disk!" >2&
    exit 2
  }
  rm -rf "$TEST_DIR"/* > /dev/null
}

test_failed() {
  [ "$PWD" != "$_SCRIPT_PWD" ] && cd "$_SCRIPT_PWD"
  clean_test_dir
  [ $COMPACT -ne 5 ] && \
    echo -e "[  ${red}FAIL${endColor}  ] TEST ${__TEST_COUNTER}: $TEST_TITLE"
  [ $COMPACT -gt 1 ] && \
    __tmp_output="${__tmp_output}\n[  ${red}FAIL${endColor}  ] TEST ${__TEST_COUNTER}: $TEST_TITLE"
  __TEST_COUNTER=$[ $__TEST_COUNTER +1 ]
  FAILED=$[ $FAILED +1 ]
}

test_passed() {
  [ "$PWD" != "$_SCRIPT_PWD" ] && cd "$_SCRIPT_PWD"
  clean_test_dir
  [ $COMPACT -ne 5 ] && \
    echo -e "[  ${green}PASS${endColor}  ] TEST ${__TEST_COUNTER}: $TEST_TITLE"
  [ $COMPACT -gt 1 ] && \
    __tmp_output="${__tmp_output}\n[  ${green}PASS${endColor}  ] TEST ${__TEST_COUNTER}: $TEST_TITLE"
  __TEST_COUNTER=$[ $__TEST_COUNTER +1 ]
  PASSED=$[ $PASSED +1 ]
}

test_skipped() {
  [ "$PWD" != "$_SCRIPT_PWD" ] && cd "$_SCRIPT_PWD"
  clean_test_dir
  [ $COMPACT -ne 5 ] && \
    echo -e "[  ${cyan}SKIP${endColor}  ] TEST ${__TEST_COUNTER}: $TEST_TITLE"
  [ $COMPACT -gt 1 ] && \
    __tmp_output="${__tmp_output}\n[  ${cyan}SKIP${endColor}  ] TEST ${__TEST_COUNTER}: $TEST_TITLE"
  __TEST_COUNTER=$[ $__TEST_COUNTER +1 ]
  SKIPPED=$[ $SKIPPED +1 ]
}

# use this if you want print some error message
log_error() {
  echo "Error: TEST $__TEST_COUNTER: $*" >&2
  [ $COMPACT -gt 2 ] && __tmp_output="${__tmp_output}\nError: TEST $__TEST_COUNTER: $*"
}

#################################################
# OTHER USABLE FUNCTIONS                        #
#################################################
# You could use and insert here functions which are helpfull for testing.
# However you SHOULDN'T modify them, without check of every function which
# use them!

is_integer() {
  echo "$1" | grep -qE "^[0-9]+$"
  return $?
}

create_text() {
  # this nice generator is undertaken from Alan Skorkin
  # http://www.skorks.com/2010/03/how-to-quickly-generate-a-large-file-on-the-command-line-with-linux/
  # optional parameter for setting length of text

  is_integer "$1" && chars=$1 || chars=100000
  echo $(ruby -e 'a=STDIN.readlines;500.times do;b=[];20.times do;
           b << a[rand(a.size)].chomp end; puts b.join(" "); end' \
     < /usr/share/dict/words ) | head -c $chars
}

# create unique filename for files in $TEST_DIR
# $1 prefix
# $2 suffix
create_unique_filename() {
  echo "$1" | grep -qE "^[a-zA-Z0-9_]+$"
  [ $? -eq 0 ] && prefix="$1" || prefix="tmp_"

  echo "$2" | grep -qE "^[a-zA-Z0-9_]+$"
  [ $? -eq 0 ] && suffix="$2" || suffix=""

  file_counter=$( ls "$TEST_DIR" | wc -l )
  while [ 1 ]; do
    filename="${prefix}${file_counter}${suffix}"

    [ ! -e "$TEST_DIR/$filename" ] && {
       echo $filename
       return 0
    }
    file_counter=$[ $file_counter +1 ]
  done
}

# long lines - 100k characters
# parameter sets length of file - default 10k
create_text_file() {
  filename="$( echo -e "tmp_"$( ls $TEST_DIR | wc -l ))"
  is_integer "$1" && chars=$1 || chars=10000
  yes "$( create_text )" | head -c $chars > "$TEST_DIR/$filename"
  echo $filename
}

# change 2 bits in compressed content
# and print filename of archive (without path)
create_easy_damaged_archive() {
  filename=$( create_text_file 1000 )
  eda="$TEST_DIR/$( create_unique_filename "eda_" ".tmp" )"
  archive="$TEST_DIR/$( create_unique_filename "archive_" ".zip" )"
  hex_file="$TEST_DIR/$( create_unique_filename "hex_" ".tmp" )"

  $zip $archive $TEST_DIR/$filename >&2
  xxd $archive $hex_file >&2
  line_counter=0

  while read line; do
    line_counter=$[ $line_counter +1 ]
    [ $line_counter -ne 10 ] && {
      echo $line >> $eda
      continue
    }

    # this line we easy damage
    echo -n "$( echo $line | cut -d " " -f 1 ) " >> $eda
    rest=$(echo $line | cut -d " " -f 1 --complement)
    echo -n $(echo $rest | sed -r "s/^(..).*$/\1/" | tr "0123456789abcdef" "123456789abcdefe") \
      >> $eda
    echo $rest | sed -r "s/^..(.*)$/\1/" >> $eda
  done < $hex_file
  xxd -r $eda $archive >&2
  echo ${archive#"$TEST_DIR/"}
}

# $1 - expected return value
# $2 - real return value
test_ecode() {
  [ $# -ne 2 ] && {
    log_error "test_ecode(): wrong count of arguments!"
    return 2
  }

  [ $1 -eq $2 ] && return 0

  log_error "Wrong exit code! Expected $1, but returned $2"
  return 1
}

#################################################
# TESTS BEGIN                                   #
#################################################

#TODO: proposed tests for implementation
#### test | expected result
# create archive with really many files | ? (limit)
# create archive with symlinks | success
# add file - not exists | ?
# add file - limit reached | ?
# add file - empty archive | success
# delete file - deleted already | ?
# delete file - deleted already and empty | ?
# test really big archive? | ?
## series of can't read zip and files | failed
## series zipfile format
# error writing | 14 (can't write) - I duno how test this now
# tests for zipnote and zipcloak
## invalid comment format | 7

#################################################
# Here add test functions.
# Do not add call of function! these will be called automatically
# by this script in section TESTINGS!
# Any helpfull functions add into the section above

#skeleton
# test_X () {
#   set_title "title/label of test" # it's required! for right output report
#   # do what you want
#   ....
#   return 0 # PASSED
#   return 1 # FAILED
#   return 2 # SKIPPED
#}



# create archive | success 0
test_1 () {
  set_title "Create archive.zip - unzip, cmp verify"
  filename=$( create_text_file )
  $zip $TEST_DIR/archive.zip $TEST_DIR/$filename
  test_ecode 0 $? || return 1

  [ ! -e $TEST_DIR/archive.zip ] && return 1
  $unzip -d $TEST_DIR $TEST_DIR/archive.zip
  [ $? -ne 0 ] && {
    log_error "Unzip failed."
    return 1
  }

  [ ! -f "$DTEST_DIR/$filename" ] && {
     log_error "Unzipped archive doesn't contain archived file."
     return 1
  }

  cmp -s "$DTEST_DIR/$filename" "$TEST_DIR/$filename" || {
    log_error "Unzipped file is different!"
    return 1
  }

  return 0
}

# create archive - without extension | automatic adding of .zip
test_2 () {
  set_title "Create archive - extension adding"
  filename=$( create_text_file )
  $zip $TEST_DIR/archive $TEST_DIR/$filename && \
    [ -e "$TEST_DIR/archive.zip" ] && return 0

  return 1
}

# create archive - file doesn't exists | nothing to do
test_3() {
  set_title "Create archive - file doesn't exists"
  $zip $TEST_DIR/archive $TEST_DIR/non_existing_file
  test_ecode 12 $? || return 1
  [ -e "$TEST_DIR/archive.zip" ] && {
    log_error "Archive was created but it shouldn't!"
    return 1
  }

  return 0
}

# Create archive - empty filelist | nothing to do
test_4() {
  set_title "Create archive - without any file in list"
  $zip $TEST_DIR/archive
  test_ecode 12 $? || return 1
  [ -e "$TEST_DIR/archive.zip" ] && {
    log_error "Archive was created but it shouldn't!"
    return 1
  }

  return 0
}

# update not exists archive | warning, create archive
test_5() {
  set_title "Update - archive not exists"
  filename=$( create_text_file )
  $zip -u $TEST_DIR/archive $TEST_DIR/$filename 2> $TEST_DIR/log
  test_ecode 0 $? || return 1
  [ -e "$TEST_DIR/archive.zip" ] || \
    { log_error "Archive wasn't created"; return 1; }
  cat $TEST_DIR/log | grep -iq "warning"
  [ $? -ne 0 ] && { log_error "Warning missing"; return 1; }

  return 0
}

# update archive - verify with unzip | success
test_6() {
  set_title "Update archive - add new file and replace existing - unzip, cmp verify"
  touch $TEST_DIR/tmp_0 $TEST_DIR/tmp_1
  filename=$( create_text_file )
  $zip $TEST_DIR/archive $TEST_DIR/tmp_0 $TEST_DIR/tmp_1
  sleep 1 # MUST BE!
  echo "Secret text" >> $TEST_DIR/tmp_0

  $zip -u $TEST_DIR/archive $TEST_DIR/tmp_0 $TEST_DIR/$filename
  test_ecode 0 $? || return 1

  $unzip -d $TEST_DIR $TEST_DIR/archive.zip
  [ -f $DTEST_DIR/tmp_0 -a -f $DTEST_DIR/tmp_1 -a -f $DTEST_DIR/$filename ] || {
    log_error "unzipped: archive doesn't contain all expected files"
    return 1
  }

  cmp -s "$DTEST_DIR/tmp_0" "$TEST_DIR/tmp_0" && \
    cmp -s "$DTEST_DIR/$filename" "$TEST_DIR/$filename" &&
    cmp -s "$DTEST_DIR/tmp_1" "$TEST_DIR/tmp_1" || {
      log_error "unzipped files are different"
      return 1
  }

  return 0
}

# update archive - nothing changed | nothing to do 12
test_7() {
  set_title "Update archive - nothing to do"
  echo "something" > $TEST_DIR/tmp_0
  $zip $TEST_DIR/archive $TEST_DIR/tmp_0
  $zip -u $TEST_DIR/archive
  test_ecode 12 $? || return 1

  return 0
}

# check -sf option | print all archived files
test_8() {
  set_title "Check -sf option (print filelist)"
  touch $TEST_DIR/archive $TEST_DIR/tmp_0 $TEST_DIR/tmp_1 $TEST_DIR/tmp_2

  $zip $TEST_DIR/archive $TEST_DIR/tmp_0 $TEST_DIR/tmp_1 $TEST_DIR/tmp_2
  lines=$( $zip -sf $TEST_DIR/archive | grep -c "tmp_[012]$" )
  [ $lines -eq 3 ] || {
     log_error "-sf option print wrong output"
     return 1
  }

  return 0
}

# delete file | success
test_9() {
  set_title "Delete file"
  touch $TEST_DIR/archive $TEST_DIR/tmp_0 $TEST_DIR/tmp_2
  echo "something" > $TEST_DIR/tmp_1

  $zip $TEST_DIR/archive $TEST_DIR/*
  $zip -d $TEST_DIR/archive $TEST_DIR/tmp_1

  test_ecode 0 $? || return 1
  lines=$( $zip -sf $TEST_DIR/archive | grep -c "tmp_[012]$" )
  $zip -sf $TEST_DIR/archive | grep -q "tmp_1"
  [ $? -eq 1 -a $lines -eq 2 ] || {
    log_error "File was not removed or something is wrong with other files"
    return 1
  }

  return 0
}

# update archive - empty | warning, 13
test_10() {
  set_title "Update empty archive"
  touch $TEST_DIR/tmp_0
  $zip $TEST_DIR/archive $TEST_DIR/tmp_0
  $zip -d $TEST_DIR/archive $TEST_DIR/tmp_0
  $zip -u $TEST_DIR/archive > $TEST_DIR/log
  test_ecode 13 $? || return 1

  grep -qE "warning.*empty" $TEST_DIR/log || {
    log_error "Warning missing or wrong warning message"
    return 1
  }

  return 0
}

# updated archive doesn't exists
test_11() {
  set_title "Updated archive doesn't exists"
  $zip -u $TEST_DIR/nothing_exists
  test_ecode 13 $? || return 1

  return 0
}

# update archive - file (not archive) not found | 12
test_12() {
  set_title "Update empty archive - file not exists and it's not part of archive"
  touch $TEST_DIR/tmp_0
  $zip $TEST_DIR/archive $TEST_DIR/tmp_0
  $zip -u $TEST_DIR/archive $TEST_DIR/tmp_1 # > $TEST_DIR/log
  test_ecode 12 $? || return 1

  return 0
}

# update archive - original file removed | 12
test_13() {
  set_title "Update empty archive - original file was removed"
  touch $TEST_DIR/tmp_0
  $zip $TEST_DIR/archive $TEST_DIR/tmp_0
  rm -f $TEST_DIR/tmp_0
  $zip -u $TEST_DIR/archive $TEST_DIR/tmp_0 # > $TEST_DIR/log
  test_ecode 12 $? || return 1

  return 0
}

# add already added file | success
test_14() {
  set_title "Add already added file - without changes"
  filename=$( create_text_file )
  $zip $TEST_DIR/archive $TEST_DIR/$filename
  $zip $TEST_DIR/archive $TEST_DIR/$filename
  test_ecode 0 $? || return 1

  return 0
}

# delete file - never exists | ?
test_15() {
  set_title "Delete file which hasn't been part of archive"
  touch $TEST_DIR/tmp_0
  $zip $TEST_DIR/archive $TEST_DIR/tmp_0
  $zip -d $TEST_DIR/archive $TEST_DIR/tmp_1 > $TEST_DIR/log
  test_ecode 12 $? || return 1

  grep -qE "warning.*not matched" $TEST_DIR/log || {
    log_error "Wrong of missing warning"
    return 1
  }

  return 0
}

# delete file - never exists and empty | 13
test_16() {
  set_title "Delete file from empty archive"
  touch $TEST_DIR/tmp_0
  $zip $TEST_DIR/archive $TEST_DIR/tmp_0
  $zip -d $TEST_DIR/archive $TEST_DIR/tmp_0
  $zip -d $TEST_DIR/archive $TEST_DIR/never_ever
  test_ecode 13 $? || return 1

  return 0
}

# delete file - archive become empty
test_17() {
  set_title "Delete file - archive become empty"
  touch $TEST_DIR/tmp_0
  $zip $TEST_DIR/archive $TEST_DIR/tmp_0
  $zip -d $TEST_DIR/archive $TEST_DIR/tmp_0 > $TEST_DIR/log
  test_ecode 0 $? || return 1

  grep -E "warning.*empty" $TEST_DIR/log || {
    log_error "Wrong of missing warning"
    return 1
  }

  return 0
}

# wrong commandline parameters | 16
test_18() {
  set_title "Wrong commandline parameters"
  $zip -w $TEST_DIR/something
  test_ecode 16 $? || return 1

  return 0
}


# error writting | 15 (cant create file for write)
test_19() {
  set_title "Can't create file for write"
  filename=$( create_text_file )
  mkdir $DTEST_DIR

  chmod -x $DTEST_DIR
  $zip $DTEST_DIR/archive $TEST_DIR/$filename

  status=$?
  chmod +x $DTEST_DIR
  test_ecode 15 $status || return 1

  return 0
}

test_20() {
  set_title "Write permission denied - existing archive"
  touch $TEST_DIR/tmp_0
  $zip $TEST_DIR/archive $TEST_DIR/tmp_0
  chmod -w $TEST_DIR/archive.zip
  $zip -d $TEST_DIR/archive $TEST_DIR/tmp_0

  status=$?
  chmod +w $TEST_DIR/archive.zip
  test_ecode 15 $status || return 1

  return 0
}

# test archive -T | success
test_21() {
  set_title "Test the integrity of archive (success)"
  filename=$( create_text_file 1000 )
  $zip $TEST_DIR/archive.zip $TEST_DIR/$filename
  $zip -T $TEST_DIR/archive.zip
  test_ecode 0 $? || return 1

  return 0
}

test_22() {
  set_title "Test the integrity of the new archive (damaged file)"
  archive=$( create_easy_damaged_archive )
  $zip -T $TEST_DIR/$archive
  test_ecode 8 $? || return 1

  return 0
}

test_23() {
  set_title "Generic zipfile format error"
  echo "Lorem ipsum, whatever..." > $TEST_DIR/archive.zip
  $zip -T $TEST_DIR/archive.zip
  test_ecode 3 $? || return 1
  return 0
}

test_24() {
  set_title "Update archive with corrupted data inside (modify original file)"
  archive=$(create_easy_damaged_archive)
  orig_file=$($zip -sf $TEST_DIR/$archive | grep -o "test_dir/.*")

  # update is possible only if original file is changed now
  # IMHO it should be automatically when CRC is wrong in future
  sleep 1
  touch -m $orig_file

  # file should be updated (repaired) to original
  $zip -u $TEST_DIR/$archive
  test_ecode 0 $? || return 1

  # test the integrity of archive again
  $zip -T $TEST_DIR/$archive
  test_ecode 0 $? || return 1

  return 0
}

# zip was interrupted | 9
test_25() {
  set_title "Interrupt zip"
  filename=$( create_text_file 50000000 ) # 50 MB
  ( $zip $TEST_DIR/archive.zip $TEST_DIR/$filename ) &
  pid=$!
  ( sleep 0.2; kill -s SIGINT $pid ) &
  wait $pid
  test_ecode 9 $? || return 1

  return 0
}

test_26() {
  set_title "Create temp file in chosen path"
  filename=$( create_text_file 50000000) # 50 MB
  mkdir $DTEST_DIR
  ( $zip -b $DTEST_DIR $TEST_DIR/archive $TEST_DIR/$filename ) &
  pid=$!

  # important - without sleep it's possible check dir before file is created
  sleep 0.5
  [ $( ls $DTEST_DIR | wc -l ) -eq 0 ] && {
    log_error "Tempfile was not created in chosen directory."
    kill -s SIGINT $pid
    return 1
  }

  kill -s SIGINT $pid
  return 0
}

# problem with tmp file | 10
test_27() {
  set_title "Problem with tmp file (chosen path doesn't exists)"
  filename=$( create_text_file 1000 )
  $zip -b $TEST_DIR/not_existing_directory $TEST_DIR/archive $TEST_DIR/$filename
  test_ecode 10 $? || return 1

  return 0
}

test_28() {
  set_title "Problem with tmp file (can't crate temp file)"
  filename=$( create_text_file 1000 )
  mkdir $DTEST_DIR
  chmod -x $DTEST_DIR
  $zip -b $DTEST_DIR $TEST_DIR/archive $TEST_DIR/$filename
  test_ecode 10 $? || return 1

  return 0
}

# series can't read errors
test_29() {
  set_title "Create archive - can't read file"
  filename=$( create_text_file )
  chmod -r $TEST_DIR/$filename
  $zip $DTEST_DIR $TEST_DIR/$filename
  test_ecode 18 $? || return 1

  return 0
}

test_30() {
  set_title "Update archive - can't read archive (consult with upstream)"
  filename=$( create_text_file )
  $zip $TEST_DIR/archive $TEST_DIR/$filename
  chmod -r $TEST_DIR/archive.zip
  echo "aa" >> $TEST_DIR/$filename
  $zip -u $TEST_DIR/archive.zip
  test_ecode 18 $? || return 1

  return 0
}

test_31() {
  set_title "Update archive - can't read only some files"
  echo "file1" > $TEST_DIR/tmp0
  echo "file2" > $TEST_DIR/tmp1
  echo "file3" > $TEST_DIR/tmp2
  touch $TEST_DIR/tmp3
  $zip $TEST_DIR/archive $TEST_DIR/{tmp0,tmp1,tmp2}

  sleep 1
  echo "Secret text" > $TEST_DIR/tmp0
  echo "Yep" >> $TEST_DIR/tmp1
  chmod -r $TEST_DIR/tmp0
  $zip -u $TEST_DIR/archive.zip
  test_ecode 18 $? || return 1

  return 0
}

test_32() {
  set_title "Create archive with symlinks"
  echo "Some next not funny text" > $TEST_DIR/tmp_0
  ln -s ./tmp_0 $TEST_DIR/symlink_file

  $zip --symlinks $TEST_DIR/archive.zip $TEST_DIR/{tmp_0,symlink_file}
  test_ecode 0 $? || return 1

  $unzip -d $TEST_DIR $TEST_DIR/archive.zip
  status=$?
  [ $status -ne 0 ] && {
    log_error "Unzip: return $status but expected is 0 (Archive contains symlink)"
    return 1
  }

  [ ! -L $DTEST_DIR/symlink_file ] && {
    log_error "Unzipped file is not symlink!"
    return 1
  }

  cmp -s "$TEST_DIR/tmp_0" "$DTEST_DIR/symlink_file" || {
    log_error "Unzipped files are different (symlink)"
    return 1
  }

  return 0
}

test_33() {
  set_title "Create archive without --symlinks (one input file is symlink)"
  echo "Some next not funny text" > $TEST_DIR/tmp_0
  ln -s ./tmp_0 $TEST_DIR/symlink_file

  $zip $TEST_DIR/archive.zip $TEST_DIR/{tmp_0,symlink_file}
  test_ecode 0 $? || return 1

  $unzip -d $TEST_DIR $TEST_DIR/archive.zip
  status=$?
  [ $status -ne 0 ] && {
    log_error "Unzip: return $status but expected is 0 (Archive contains symlink)"
    return 1
  }

  [ -L $DTEST_DIR/symlink_file ] && {
    log_error "Unzziped file is symlink, but it shouldn't (option \"--symlinks\" wasn't used)"
    return 1
  }

  cmp -s "$TEST_DIR/tmp_0" "$DTEST_DIR/symlink_file" && \
    cmp -s "$TEST_DIR/tmp_0" "$DTEST_DIR/tmp_0" || {
      log_error "Unzipped files are different (symlink)"
      return 1
    }

  return 0
}

test_34() {
  set_title "Create archive with many files and symlinks"
  text=$( create_text 1000 )
  mkdir -p $TEST_DIR/files/some
  for i in {0..10000}; do
    echo "$text" > "$TEST_DIR/files/tmp_$i"
  done

  echo "$( create_text 16000)" >> $TEST_DIR/files/tmp_152
  echo "$( create_text 16000)" >> $TEST_DIR/files/tmp_153
  echo "$( create_text 16000)" >> $TEST_DIR/files/tmp_154
  cp $TEST_DIR/files/tmp_154 $TEST_DIR/files/some/juhuu
  ln -s tmp_152 $TEST_DIR/files/syml_0
  ln -s some/juhuu $TEST_DIR/files/u_syml_1
  for i in {160..260}; do
    ln -s tmp_$i $TEST_DIR/files/tmp_${i}_0
  done

  $zip -r --symlinks $TEST_DIR/archive.zip $TEST_DIR/* >/dev/null
  test_ecode 0 $? || return 1

  $unzip -d $TEST_DIR $TEST_DIR/archive.zip > "$TEST_DIR/log_unzip" 2>&1
  status=$?
  [ $status -ne 0 ] && {
    log_error "Unzip: return $status but expected is 0 (Archive contains symlink and many files)"
    return 1
  }

  files_orig=$(ls $TEST_DIR/files/ | wc -l)
  files_unzipped=$(ls $DTEST_DIR/files/ | wc -l)
  [ $files_orig -ne $files_unzipped ] && {
     log_error "Some files are missing. Before: $files_orig - After: $files_unzipped"
     return 1
  }


  missing=0
  for i in {160..260}; do
    [ ! -L $DTEST_DIR/files/tmp_${i}_0 ] && {
      missing=1
      break
    }
  done

  [ -L $DTEST_DIR/files/syml_0 -a -L $DTEST_DIR/files/u_syml_1 -a $missing -eq 0 ] || {
    log_error "(some) Symlinks was not created"
    return 1
  }

  lines=$(cat $TEST_DIR/log_unzip | grep -cE "\->\s*(tmp_[0-9]+|some/juhuu)$" )
  [ $lines -ne 103 ] && {
    ## this archive is not affected by unzip bug https://bugzilla.redhat.com/show_bug.cgi?id=740012
    ## if someone can create such archive here, please write me or send me patch/new test
    ## e.g. this archive is affected https://github.com/mono/mono/archive/master.zip
    log_error "Unzip decompress symlinks wrong. (Known bug in unzip 6.10b and older - patched on fedora 19 and newer)"
    return 1
  }

  return 0
}

test_35() {
  set_title "Freshen archive (empty archive)"
  touch $TEST_DIR/tmpfile
  $zip $TEST_DIR/archive $TEST_DIR/tmpfile
  $zip -d $TEST_DIR/archive.zip $TEST_DIR/tmpfile
  $zip -f $TEST_DIR/archive.zip
  test_ecode 13 $? || return 1

  return 0
}

test_36() {
  set_title "Freshen archive (test not adding new files)"
  touch $TEST_DIR/tmp_0 $TEST_DIR/tmp_1
  $zip $TEST_DIR/archive $TEST_DIR/tmp_0
  $zip -f $TEST_DIR/archive.zip $TEST_DIR/tmp_1
  test_ecode 12 $? || return 1

  sleep 1
  echo "And rains, and rains.." >> $TEST_DIR/tmp_0
  $zip -f $TEST_DIR/archive.zip $TEST_DIR/*
  test_ecode 0 $?

  lines=$( $zip -sf $TEST_DIR/archive.zip | wc -l )
  [ $lines -ne 3 ] && {
    log_error "Freshen  - added files (or changed report!)"
    return 1
  }

  return 0
}

# truncate archive - try repair and verify with unzip
test_37() {
  set_title "Unexpected end of zipfile"
  filename=$( create_text_file 1000 )
  $zip $TEST_DIR/archive $TEST_DIR/$filename
  size=$[ $(wc -c $TEST_DIR/archive.zip | cut -d " " -f 1) - 5 ]
  truncate --size $size $TEST_DIR/archive.zip
  $zip -T $TEST_DIR/archive
  test_ecode 2 $? || return 1

  ## -F and also -FF do not repair truncated end of archive

  return 0
}

test_38() {
  set_title "Insert zip file comment '-z' - verify by zipnote"
  echo "whatever wherever" > $TEST_DIR/tmp_0
  text="Short comment"

  $zip $TEST_DIR/archive $TEST_DIR/tmp_0
  echo "$text" | $zip -z $TEST_DIR/archive.zip
  test_ecode 0 $? || return 1

  $zipnote $TEST_DIR/archive.zip | tail -n 1 | grep -q "^$text$"
  [ $? -ne 0 ] && {
    log_error "Comment wasn't added or error in zipnote"
    return 1
  }

  return 0
}

test_39() {
  set_title "Insert comment for each file - verify zipnote"
  touch $TEST_DIR/{tmp_0,tmp_1,tmp_2}
  text="short_comment"
  yes "$text" | zip -c $TEST_DIR/archive $TEST_DIR/tmp_*
  test_ecode 0 $? || return 1

  lines=$($zipnote $TEST_DIR/archive.zip | grep -c "$text")
  [ $lines -ne 3 ] && {
    log_error "Comments weren't added of error in zipnote"
    return 1
  }

  return 0
}

test_40() {
  # when patch will be created, this test should be modified
  # because probably new option will be created
  set_title "Acrhive with too long filename - unzip (may it will not be fixed)"
  ## skip if you you forget copy special test archives too
  [ -f "too_long_filename.zip" ] || return 2
  cp too_long_filename.zip $TEST_DIR/too_long_filename.zip

  $unzip -l $TEST_DIR/too_long_filename.zip | head -n4 | tail -n1 | cut -d " " -t 15- \
    | grep "^[[:space:][:alnum:]_-]+$" || return 1
  return 0
}

test_41() {
  set_title "Rename files in archive by zipnote"
  return 2
  # this is dangerous even for testing !!
  # zipnote is killed by SIGSEGV the often, but sometimes is freezing
  # and can't be interrupted even by SIGTERM (only sigkill)
  # and I don't want start/create know test which is permanently wrong and
  # needs special construction for interruption by other processe

  # TODO: create test with safe run of zipnote

  return 0
}

# wrong argument | 16
test_42() {
  set_title "Split archive  - wrong argument (lesser then minimum size of chunk)"
  filename="$( create_text_file $[ 2**20 ] )"
  $zip $TEST_DIR/archive.zip -s 30k "$TEST_DIR/$filename"
  test_ecode 16 $? || return 1
  return 0
}

test_43() {
  set_title "Split archive - archive has lesser size then chunk"
  filename="$( create_text_file $[ 2**20 ] )"
  $zip $TEST_DIR/archive.zip -s 2m "$TEST_DIR/$filename"
  test_ecode 0 $? || return 1

  mm_count=$(ls -1 $TEST_DIR/archive.* | wc -l)
  [[ $mm_count -eq 1 ]] || return 1

  return 0
}

test_44() {
  set_title "Split archive"
  filename="$( create_text_file $[ 2**20 ] )"
  $zip "$TEST_DIR/archive_split" -s 128k "$TEST_DIR/$filename"

  # we must check sum size of archive and then calculate
  # how many files we want..
  sum_size=$(ls -lt $TEST_DIR/archive_split.* | awk '{ x+=$5 }END{ print x }')

  counts=$(ls -lt $TEST_DIR/archive_split.* | wc -l)
  expected_counts=$[ $sum_size / (2**17) ]
  [[ $sum_size -gt $[ $expected_counts * 2**17 ] ]] && expected_counts=$[ $expected_counts + 1 ]
  [[ $counts -ne $expected_counts ]] && {
    log_error "Wrong number of counts: expected $expected_counts - exists $counts"
    return 1
  }

  [[ "$(ls -t $TEST_DIR/archive_split.* | head -n1)" == "$TEST_DIR/archive_split.zip" ]] || {
    log_error "Last file doesn't have extension/suffix .zip"
    return 1
  }

  #TODO add zip -FF and join everything back together.
  # then unzip archive and compare result
  # it's good check before testing of support by unzip

  return 0
}

test_45() {
  set_title "Unzip segmented archive - single file"
  filename="$( create_text_file $[ 2**20 * 100 ] )"
  $zip "$TEST_DIR/archive_split" -s 1m "$TEST_DIR/$filename" || {
    log_error "Zip fail during compression of segmented archive"
    return 2 # skip because this is problem of zip
  }

  $unzip -d "$TEST_DIR" "$TEST_DIR/archive_split"
  test_ecode 0 $? || return 1

  [ -e "$DTEST_DIR/$filename" ] || {
    log_error "unzipped file can't be found! Probably wasn't created."
    return 1
  }

  cmp -s "$TEST_DIR/$filename" "$DTEST_DIR/$filename" || {
    log_error "Unzipped file is different from original!"
    return 1
  }

  return 0
}

test_46() {
  set_title "Unzip segmented archive - many files"
  filename="$( create_text_file $[ 2**20 * 100 ] )"
  $zip "$TEST_DIR/archive_split" -s 1m "$TEST_DIR/$filename" && \
   $zip "$TEST_DIR/double_split" -s 128k "$TEST_DIR"/archive_split* || {
    log_error "Zip fail during compression of segmented archive"
    exit 0
    return 2 # skip because this is problem of zip
  }

  $unzip -d "$TEST_DIR" "$TEST_DIR/double_split"
  test_ecode 0 $? || return 1

  [ -e "$DTEST_DIR" ] || {
    log_error "Destination directory wasn't created."
    return 1
  }

  original_files=$(ls "$TEST_DIR"/double_split* | wc -l)
  output_files=$(ls "$DTEST_DIR"/arhive_split | wc -l)
  [ $original_files -eq $output_files ] || {
    log_error "Different count of files! Originally: $original_files - Unzipped: $output_files"
    return 1
  }

  $unzip -d "$TEST_DIR" "$DTEST_DIR/archive_split"
  test_ecode 0 $? | return 1

  cmp -s "$TEST_DIR/$filename" "$DTEST_DIR/$filename" || {
    log_error "Unzipped file is different from original!"
    return 1
  }

  return 0
}


# Do not edit next lines!
# TESTS ENDS
#################################################
# TESTINGS                                      #
#################################################
# print version of zip and unzip
echo "-----------------------------------------------------------------------
zip: $__zip_version
unzip: $__unzip_version
-----------------------------------------------------------------------"

# automatic invocation of test functions in section above

__tests_startline=$(grep -nm 1 "# TESTS BEGIN" $scriptname | cut -d ":" -f 1)
__tests_endline=$(grep -nm 1 "# TESTS ENDS" $scriptname | cut -d ":" -f 1)
__tests_lines=$[ $__tests_endline - $__tests_startline ]
__file_lines=$(wc -l $scriptname | cut -d " " -f 1)
__tests_functions=$(cat "$scriptname" | tail -n $[ $__file_lines - $__tests_startline ] \
  | head -n $__tests_lines | grep -E "^\s*[_a-zA-Z0-9]+\s*\(\)\s*\{" \
  | grep -oE "^\s*[_a-zA-Z0-9]+"; )
for item in $__tests_functions; do
  [ -n "$only_test" ] && {
    [ "$item" == "$only_test" ] || continue
  }
  if [ $COMPACT -eq 1  -o  $COMPACT -ge 4 ]; then
    $item >/dev/null 2>/dev/null && { test_passed; continue; }
  else
    $item >&2 && { test_passed; continue; }
  fi
  [ $? -eq 1 ] && test_failed || test_skipped
done

[ $COMPACT -gt 1 ] && echo -e "
================================================
=                COMPACT RESULTS               =
================================================
$__tmp_output
"

#################################################
# RESULTS                                       #
#################################################
TOTAL=$[ $FAILED + $PASSED + $SKIPPED ]
echo "
================================================
=                 RESULTS                      =
================================================
Total tests:  $TOTAL
Passed:       $PASSED
Failed:       $FAILED
Skipped:      $SKIPPED
"

[ -n "$TEST_DIR" ] || {
  echo "EMPTY destination of TEST_DIR!! Threatens remove of all files on disk!" >2&
  exit 2
}

rm -rf $TEST_DIR # clean mess

