#! /bin/bash
## makeTestFiles.sh
##
## Usage makeTestFiles.sh <fileroot> <count> [extension]
##
## Edit the 'choice' value below (around line 28) to set file contents.

ext='' ## default to no extension

if [ $# -lt 2 ]; then
  echo "Usage: makeTestFiles.sh <fileroot> <count> [extension]"
  exit 1
fi

fileroot=$1
count=$2

if [ $# == 3 ]; then
  ext=$3
fi

n=0
while [ $n -lt $count ]; do
  numFormatted=`printf "%03d" $n`
  filename="$fileroot$numFormatted$ext"

  ## Choose different file content options:
  choice=1
  case $choice in
    ## File contains the filename
    1) echo "I am $filename" > $filename;;

    ## or,zero size files:
    2) rm -f $filename; touch $filename;;

    ## or, copy a sample repeatedly
    3) cp /tmp/sample.data $filename;;

    ## or, create a 100MiB file for throughput testing
    ## (Very fast, but may not work on all types of file systems.)
    ## Length suffixes of k, m, g, t, p, e may be specified 
    ## to denote KiB, MiB, GiB, etc. (200p = 200 PetaBytes!?!?!?)
    4) rm -f $filename; fallocate --length 100m $filename;;

    ## or, create a 100MiB file (slower) if #4 doesn't work
    ## bs=block size in bytes, count=number of blocks to write
    ## if=/dev/zero, Input File /dev/zero is a special file that always 
    ## returns 0's when read
    5) dd if=/dev/zero of=$filename count=102400 bs=1024;;
  esac
  let n=n+1
done
