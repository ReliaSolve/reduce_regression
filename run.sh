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
# Get rid of any old scripts and libraries
rm -f reduce.py
rm -f mmtbx_reduce_ext.so

######################
# Parse the command line

new="master"
orig="fcbdf1821e02661b7b3a637a1e57bcad6ba1cea9"
if [ "$1" != "" ] ; then new="$1" ; fi
if [ "$2" != "" ] ; then orig="$2" ; fi

echo "Checking $new against $orig"

#####################
# Make sure the reduce submodule is checked out

echo "Updating submodule"
git submodule update --init
(cd reduce; git pull) &> /dev/null 

######################
# Check out each version and build each.
# The original version is build using Make because older versions don't
# have CMakeLists.txt files.

echo "Building $orig"
(cd reduce; git checkout $orig; make) &> /dev/null 

echo "Building $new"
(cd reduce; git fetch)
(cd reduce; git checkout $new) &> /dev/null
(cd reduce; git pull)
mkdir -p build_new
(cd build_new; cmake -DCMAKE_BUILD_TYPE=Release ../reduce; make) &> /dev/null

orig_exe="./reduce/reduce_src/reduce"
orig_arg=""
new_exe="./build_new/reduce_src/reduce"
new_args="-rad0.0"
python_args="-rad0.0"

# See if we are building Python
PYTHON=1
if [ ! -f ./reduce/reduce_src/reduce.py ]; then
  PYTHON=0
  echo "Not testing Python"
fi

if [ "$PYTHON" -eq "1" ]; then
  # Get what we need to run Python locally with the mmtbx_reduce_ext shared library
  cp ./build_new/reduce_src/mmtbx_reduce_ext.so .
  cp ./reduce/reduce_src/reduce.py .
  python_script="./reduce.py"
fi

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

  # We must extract to a file and then run with that file as a command-line argument
  # because the original version did not process all models in a file when run with
  # the model coming on standard input.
  tfile=outputs/temp_file.tmp
  gunzip < $inf > $tfile

  ##############################################
  # Test with no command-line arguments

  echo "Testing file $f"
  # Run old and new versions in parallel
  ($orig_exe $orig_args $tfile > outputs/$f.orig 2> outputs/$f.orig.stderr) &
  ($new_exe $new_args $tfile > outputs/$f.new 2> outputs/$f.new.stderr) &
  if [ "$PYTHON" -eq "1" ]; then
    (python $python_script $python_args $tfile > outputs/$f.py 2> outputs/$f.py.stderr) &
  fi
  wait

  # Strip out expected differences
  grep -v reduce < outputs/$f.orig > outputs/$f.orig.strip
  grep -v reduce < outputs/$f.new > outputs/$f.new.strip
  if [ "$PYTHON" -eq "1" ]; then
    grep -v reduce < outputs/$f.py > outputs/$f.py.strip
  fi

  # Test for unexpected differences
  d=`diff outputs/$f.orig.strip outputs/$f.new.strip | wc -c`
  if [ $d -ne 0 ]; then echo " Failed!"; failed=$((failed + 1)); fi
  if [ "$PYTHON" -eq "1" ]; then
    d=`diff outputs/$f.orig.strip outputs/$f.py.strip | wc -c`
    if [ $d -ne 0 ]; then echo " Failed!"; failed=$((failed + 1)); fi
  fi

  ##############################################
  # Test with -TRIM command-line argument

  echo "Testing file $f with -TRIM"
  # Run old and new versions in parallel
  ($orig_exe $orig_args -TRIM $tfile > outputs/$f.TRIM.orig 2> outputs/$f.TRIM.orig.stderr) &
  ($new_exe $new_args -TRIM $tfile > outputs/$f.TRIM.new 2> outputs/$f.TRIM.new.stderr) &
  if [ "$PYTHON" -eq "1" ]; then
    (python $python_script $python_args -TRIM $tfile > outputs/$f.TRIM.py 2> outputs/$f.TRIM.py.stderr) &
  fi
  wait

  # Strip out expected differences
  grep -v reduce < outputs/$f.TRIM.orig > outputs/$f.TRIM.orig.strip
  grep -v reduce < outputs/$f.TRIM.new > outputs/$f.TRIM.new.strip
  if [ "$PYTHON" -eq "1" ]; then
    grep -v reduce < outputs/$f.TRIM.py > outputs/$f.TRIM.py.strip
  fi

  # Test for unexpected differences
  d=`diff outputs/$f.TRIM.orig.strip outputs/$f.TRIM.new.strip | wc -c`
  if [ $d -ne 0 ]; then echo " Failed!"; failed=$((failed + 1)); fi
  if [ "$PYTHON" -eq "1" ]; then
    d=`diff outputs/$f.TRIM.orig.strip outputs/$f.TRIM.py.strip | wc -c`
    if [ $d -ne 0 ]; then echo " Failed!"; failed=$((failed + 1)); fi
  fi

  ##############################################
  # Test with -FLIP command-line argument

  echo "Testing file $f with -FLIP"
  # Run old and new versions in parallel
  ($orig_exe $orig_args -FLIP $tfile > outputs/$f.FLIP.orig 2> outputs/$f.FLIP.orig.stderr) &
  ($new_exe $new_args -FLIP $tfile > outputs/$f.FLIP.new 2> outputs/$f.FLIP.new.stderr) &
  if [ "$PYTHON" -eq "1" ]; then
    (python $python_script $python_args -FLIP $tfile > outputs/$f.FLIP.py 2> outputs/$f.FLIP.py.stderr) &
  fi
  wait

  # Strip out expected differences
  grep -v reduce < outputs/$f.FLIP.orig > outputs/$f.FLIP.orig.strip
  grep -v reduce < outputs/$f.FLIP.new > outputs/$f.FLIP.new.strip
  if [ "$PYTHON" -eq "1" ]; then
    grep -v reduce < outputs/$f.FLIP.py > outputs/$f.FLIP.py.strip
  fi

  # Test for unexpected differences
  d=`diff outputs/$f.FLIP.orig.strip outputs/$f.FLIP.new.strip | wc -c`
  if [ $d -ne 0 ]; then echo " Failed!"; failed=$((failed + 1)); fi
  if [ "$PYTHON" -eq "1" ]; then
    d=`diff outputs/$f.FLIP.orig.strip outputs/$f.FLIP.py.strip | wc -c`
    if [ $d -ne 0 ]; then echo " Failed!"; failed=$((failed + 1)); fi
  fi

done

echo
if [ $failed -eq 0 ]
then
  echo "Success!"
else
  echo "$failed files failed"
fi

exit $failed

