#!/bin/bash
# This script is created for testing on Linux systems
# and probably will not work right on the other system.
# I didn't test it.

# for some tests could be used unzip, for checking of differents
# between original data and zipped/unzipped data
# - I hope that unzip will not be generator of errors :-)
# NOTE: may I will add some option for skipping unzip-tests 
#       or alternative results (as FAILED_CHECK or something similar)

zip="../zip"
unzip=$(which unzip)
scriptname=$(basename $0)
TEST_DIR="test_dir"
cd ${0%$scriptname}
_SCRIPT_PWD=$PWD

if [[ ! -e $zip ]]; then
  echo "File $zip doesn't exists."
  exit 1
fi

if [[ ! -e $unzip ]]; then
  echo "File $unzip doesn't exists."
  exit 1
fi

rm -rf $TEST_DIR
mkdir $TEST_DIR || {
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
ERRORS=0 # maybe will be able to used/implemented later
__zip_version=$($zip -v | head -n 2 | tail -n 1 | cut -d " " -f 4)
__unzip_version=$($unzip -vqqqq)

__TEST_COUNTER=1
_test_EOK='eval [[ $? -eq 0 ]] || { log_error "Wrong ecode"; return 1; }'

green='\e[1;32m'
red='\e[1;31m'
endColor='\e[0m'

TEST_TITLE=""
DTEST_DIR="$TEST_DIR/$TEST_DIR" # double testdir - for unzipped files

set_title() {
  TEST_TITLE="$@"
}

clean_test_dir() {
  rm -rf $TEST_DIR/* > /dev/null
}

test_failed() {
  [ $PWD != $_SCRIPT_PWD ] && cd $_SCRIPT_PWD
  clean_test_dir
  echo -e "[  ${red}FAIL${endColor}  ] TEST ${__TEST_COUNTER}: $TEST_TITLE"
  __TEST_COUNTER=$[ $__TEST_COUNTER +1 ]
  FAILED=$[ $FAILED +1 ]
}

test_passed() {
  [ $PWD != $_SCRIPT_PWD ] && cd $_SCRIPT_PWD
  clean_test_dir
  echo -e "[  ${green}PASS${endColor}  ] TEST ${__TEST_COUNTER}: $TEST_TITLE"
  __TEST_COUNTER=$[ $__TEST_COUNTER +1 ]
  PASSED=$[ $PASSED +1 ]
}

# use this if you want print some error message
log_error() {
  echo "Error: TEST $__TEST_COUNTER: $@" >&2
}

#################################################
# OTHER USABLE FUNCTIONS                        #
#################################################
# You could use and insert here functions which are helpfull for testing.
# However you SHOULDN'T modify them, without check of every function which
# is using them!

is_integer() {
  echo "$1" | grep -qE "^[0-9]+$"
  return $?
}

create_text() {
  # this nice generator is undertaken from Alan Skorkin
  # http://www.skorks.com/2010/03/how-to-quickly-generate-a-large-file-on-the-command-line-with-linux/
  # optional parameter for setting length of text

  is_integer $1 && chars=$1 || chars=100000
  ruby -e 'a=STDIN.readlines;500.times do;b=[];20.times do;
           b << a[rand(a.size)].chomp end; puts b.join(" "); end' \
     < /usr/share/dict/words | head -c $chars
}

# long lines - 100k characters
# parameter sets length of file - default 10k
create_text_file() {
  filename=$( echo -e "tmp_"$( ls $TEST_DIR | wc -l ))
  is_integer $1 && chars=$1 || chars=10000
  yes $( create_text ) | head -c $chars > $TEST_DIR/$filename
  echo $filename
}

# not implemented - not important now
create_binary_file() {
  return 1
}


create_archive() {
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
# test archive -T | success
# test archive -T - damaged | ?
# test really big archive? | ?
## series of can't read zip and files | failed
## series zipfile format
## invalid comment format | 7
## zip was interrupted | 9
# problem with tmp file | 10
# error writting | 14 (can't write) - I duno how test this now

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
#   return 1 # FAILED
#   ## or
#   return 0 # PASSED
#}



# create archive | success 0
test_1 () {
  set_title "Create archive.zip - unzip,diff verify"
  filename=$( create_text_file )
  $zip $TEST_DIR/archive.zip $TEST_DIR/$filename
  status=$?

  $_test_EOK
  [ ! -e $TEST_DIR/archive.zip ] && return 1
  $unzip -d $TEST_DIR $TEST_DIR/archive.zip
  [ $? -ne 0 ] && {
    log_error "Unzip failed."
    return 1
  }

  [ ! -f $DTEST_DIR/$filename ] && {
     log_error "Unzipped archive doesn't contain archived filed."
     return 1
  }

  diff -q $DTEST_DIR/$filename $TEST_DIR/$filename || {
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
  [ $? -eq 12 ] || { log_error "Wrong ecode"; return 1; }
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
  [ $? -eq 12 ] || { log_error "Wrong ecode"; return 1; }
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
  $_test_EOK
  [ -e "$TEST_DIR/archive.zip" ] || \
    { log_error "Archive wasn't created"; return 1; }
  cat $TEST_DIR/log | grep -iq "warning"
  [ $? -ne 0 ] && { log_error "Warning missing"; return 1; }

  return 0
}

# update archive - verify with unzip | success
test_6() {
  set_title "Update archive - add new file and replace existing - unzip,diff verify"
  touch $TEST_DIR/tmp_0 $TEST_DIR/tmp_1
  filename=$( create_text_file )
  $zip $TEST_DIR/archive $TEST_DIR/tmp_0 $TEST_DIR/tmp_1
  stdbuf -o echo -e "Secret text\n" > $TEST_DIR/tmp_0

  $zip -u $TEST_DIR/archive $TEST_DIR/tmp_0 $TEST_DIR/$filename
  $_test_EOK
  
  $unzip -d $TEST_DIR $TEST_DIR/archive.zip
  [ -f $DTEST_DIR/tmp_0 -a -f $DTEST_DIR/tmp_1 -a -f $DTEST_DIR/$filename ] || {
    log_error "unzipped: archive doesn't contain all expected files"
    return 1
  }

  diff -q $DTEST_DIR/tmp_0 $TEST_DIR/tmp_0 && \
    diff -q $DTEST_DIR/$filename $TEST_DIR/$filename &&
    diff -q $DTEST_DIR/tmp_1 $TEST_DIR/tmp_1 || {
      log_error "unzipped - diff: files are different"
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
  [ $? -eq 12 ] || {
    log_error "Update - error code - expected 12"
    return 1
  }

  return 0
}

# check -sf option | print all archived files
test_8() {
  set_title "Check -sf option (print filelist)"
  touch $TEST_DIR/archive $TEST_DIR/tmp_0 $TEST_DIR/tmp_1 $TEST_DIR/tmp_2

  $zip $TEST_DIR/archive $TEST_DIR/tmp_0 $TEST_DIR/tmp_1 $TEST_DIR/tmp_2
  lines=$( $zip -sf $TEST_DIR/archive | grep "tmp_[012]$" | wc -l )
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

  $_test_EOK
  lines=$( $zip -sf $TEST_DIR/archive | grep "tmp_[012]$" | wc -l )
  $zip -sf $TEST_DIR/archive | grep -q "tmp_1"
  [ $? -eq 1 -a $lines -eq 2 ] || {
    log_error "File was not removed or somehting is wrong with other files"
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
  [ $? -eq 13 ] || {
    log_error "Wrong ecode"
    return 1
  }

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
  [ $? -eq 13 ] || {
    log_error "Expected code 13"
    return 1
  }

  return 0
}

# update archive - file (not archive) not found | 12
test_12() {
  set_title "Update empty archive - file not exists and it's not part of archive"
  touch $TEST_DIR/tmp_0
  $zip $TEST_DIR/archive $TEST_DIR/tmp_0
  $zip -u $TEST_DIR/archive $TEST_DIR/tmp_1 # > $TEST_DIR/log
  [ $? -eq 12 ] || {
    log_error "Wrong ecode"
    return 1
  }

  return 0     
}

# update archive - original file removed | 12
test_13() {
  set_title "Update empty archive - original file was removed"
  touch $TEST_DIR/tmp_0
  $zip $TEST_DIR/archive $TEST_DIR/tmp_0
  rm -f $TEST_DIR/tmp_0
  $zip -u $TEST_DIR/archive $TEST_DIR/tmp_0 # > $TEST_DIR/log
  [ $? -eq 12 ] || {
    log_error "Wrong ecode"
    return 1
  }

  return 0
}

# add already added file | success
test_14() {
  set_title "Add already added file - without changes"
  filename=$( create_text_file )
  $zip $TEST_DIR/archive $TEST_DIR/$filename
  $zip $TEST_DIR/archive $TEST_DIR/$filename
  $_test_EOK

  return 0
}

# delete file - never exists | ?
test_15() {
  set_title "Delete file which hasn't been part of archive"
  touch $TEST_DIR/tmp_0
  $zip $TEST_DIR/archive $TEST_DIR/tmp_0
  $zip -d $TEST_DIR/archive $TEST_DIR/tmp_1 > $TEST_DIR/log
  [ $? -eq 12 ] || {
    log_error "Wrong ecode"
    return 1 
  }

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
  [ $? -eq 13 ] || {
    log_error "Wrong ecode"
    return 1
  }

  return 0
}

# delete file - archive become empty
test_17() {
  set_title "Delete file - archive become empty"
  touch $TEST_DIR/tmp_0
  $zip $TEST_DIR/archive $TEST_DIR/tmp_0
  $zip -d $TEST_DIR/archive $TEST_DIR/tmp_0 > $TEST_DIR/log
  $_test_EOK
  
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
  [ $? -eq 16 ] || {
    log_error "Wrong ecode"
    return 1
  }

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

  [ $status -eq 15 ] || {
    log_error "Wrong ecode - expected 15, but returned $status"
    return 1
  }

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

  [ $status -eq 15 ] || {
    log_error "Wrong code - expected 14, but returned $status"
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
__tests_functions=$(cat $scriptname | tail -n $[ $__file_lines - $__tests_startline ] \
  | head -n $__tests_lines | grep -E "^\s*[_a-zA-Z0-9]+\s*\(\)\s*\{" \
  | grep -oE "^\s*[_a-zA-Z0-9]+"; )
for item in $__tests_functions; do
  $item >&2 && test_passed || test_failed 
done

#################################################
# RESULTS                                       #
#################################################
TOTAL=$[ $FAILED + $PASSED ]
echo "
================================================
=                 RESULTS                      =
================================================
Total tests:  $TOTAL
Passed:       $PASSED
Failed:       $FAILED
"