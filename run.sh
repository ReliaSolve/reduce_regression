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

echo "Updating submodule"
git submodule update --init

######################
# Check out each version and build each.
# The original version is build using Make because older versions don't
# have CMakeLists.txt files.

echo "Building $orig"
(cd reduce; git checkout $orig; make) &> /dev/null 

echo "Building $new"
(cd reduce; git checkout $new) &> /dev/null
mkdir -p build_new
(cd build_new; cmake ../reduce; make) &> /dev/null

orig_exe="./reduce/reduce_src/reduce"
new_exe="./build_new/reduce_src/reduce"

######################
# Generate two outputs for each test file, redirecting standard
# output and standard error to different files.
# Test the standard outputs to see if any differences are other than we expect.

echo
mkdir -p outputs
files=`ls test_files`
failed=0
for f in $files; do
  ##############################################
  # Full input-file name
  inf=test_files/$f

  ##############################################
  # Test with no command-line arguments

  echo "Testing file $f"
  gunzip < $inf | $orig_exe - > outputs/$f.orig 2> outputs/$f.orig.stderr
  gunzip < $inf | $new_exe - > outputs/$f.new 2> outputs/$f.new.stderr

  # Strip out expected differences
  grep -v reduce < outputs/$f.orig > outputs/$f.orig.strip
  grep -v reduce < outputs/$f.new > outputs/$f.new.strip

  ##############################################
  # Test with -TRIM command-line argument

  echo "Testing file $f with -TRIM"
  gunzip < $inf | $orig_exe -TRIM - > outputs/$f.TRIM.orig 2> outputs/$f.TRIM.orig.stderr
  gunzip < $inf | $new_exe -TRIM - > outputs/$f.TRIM.new 2> outputs/$f.TRIM.new.stderr

  # Strip out expected differences
  grep -v reduce < outputs/$f.TRIM.orig > outputs/$f.TRIM.orig.strip
  grep -v reduce < outputs/$f.TRIM.new > outputs/$f.TRIM.new.strip

  # Test for unexpected differences
  d=`diff outputs/$f.TRIM.orig.strip outputs/$f.TRIM.new.strip | wc -c`
  if [ $d -ne 0 ]; then echo " Failed!"; failed=$((failed + 1)); fi
done

echo
if [ $failed -eq 0 ]
then
  echo "Success!"
else
  echo "$failed files failed"
fi

exit $failed

