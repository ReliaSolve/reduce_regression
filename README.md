# reduce_regression
Regression tests for the Reduce repository.

## Running
There is a `run.sh` BASH script that will build the original version of
Reduce to compare against (defaults to commit e31d8e0ef14e6e8b85634dea502cadac9cf7832b,
but adding a second command-line argument can specify another git tag) against
a more recent version (defaults to the master branch but a first command-line argument
can specify another git tag).

This script compiles both versions and then runs each against every file in the
test_files directory.  If the standard outputs of either run differ by other than
the original 'reduce' version line, it is marked as a failure.  If there are no
failures, then **Success!** is printed as the last output, otherwise a message
telling how many failed is written.

In any case, all of the standard output and standard error files are written
into an **outputs** directory, along with the standard-output file that have
the reduce line stripped off.

The script exits with code 0 on success and the number of failures if any comparison failed.

