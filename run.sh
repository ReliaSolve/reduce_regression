#!/bin/bash
#############################################################################
# Run regression tests against a specified target (default master) and a
# specified original (default e31d8e0ef14e6e8b85634dea502cadac9cf7832b)
# to make sure that the only differences between the outputs have to do with
# the version information printed at the beginning of the output file.
#
# Tests are run using all of the files in the test_files directory.
#
# Both versions of reduce are built and then they are both run against each file.
#############################################################################

######################
# Parse the command line

new="master"
orig="e31d8e0ef14e6e8b85634dea502cadac9cf7832b"
if [ "$1" != "" ] ; then new="$1" ; fi
if [ "$2" != "" ] ; then orig="$2" ; fi

echo "Checking $new against $orig"

#####################
# Make sure the reduce submodule is checked out

git submodule update --init

######################
# Check out each version and build each.
# The original version is build using Make because older versions don't
# have CMakeLists.txt files.

(cd reduce; git checkout $orig; make)

(cd reduce; git checkout $new)
mkdir -p build_new
(cd build_new; cmake ../reduce; make)

orig_exe="./reduce/reduce_src/reduce"
new_exe="./build_new/reduce_src/reduce"

######################
# Generate two outputs for each test file, redirecting standard
# output and standard error to different files.
# Test the standard outputs to see if any differences are other than we expect.

mkdir -p outputs
files=`ls test_files`
failed=0
for f in $files; do
  echo "Testing file $f"
  $orig_exe test_files/$f > outputs/$f.orig 2> outputs/$f.orig.stderr
  $new_exe test_files/$f > outputs/$f.new 2> outputs/$f.new.stderr

  # Strip out expected differences
  grep -v reduce < outputs/$f.orig > outputs/$f.orig.strip
  grep -v reduce < outputs/$f.new > outputs/$f.new.strip

  # Test for unexpected differences
  d=`diff outputs/$f.orig.strip outputs/$f.new.strip | wc -c`
  if [ $d -ne 0 ]; then echo " Failed!"; failed=$((failed + 1)); fi
done

if [ $failed -eq 0 ]; then echo "Success!"; else echo "$failed files failed"; fi

