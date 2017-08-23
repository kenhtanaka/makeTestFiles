#!/usr/bin/perl -w
##****************************************************************************
##
##  FILE:       filename_replicator.pl
##
##  PURPOSE:    Replicate filenames for testing. Generates
##              a series of unix commands to simulate the file hierarchy for
##              testing. File content is "I am <filename>"
##
##  ORIGIN:     NGDC/NOAA, Department of Commerce, USA
##              NCEI -> National Centers for Environmental Information, Boulder, Colorado
##
##  AUTHORS:
##      KHT     Ken Tanaka, Ken.Tanaka@noaa.gov
##
##****************************************************************************
##  NOTES:
##  Recursively scan subdirectories of a starting directory, matching filename
##  patterns and writing commands to replicate the directory structure and
##  filenames, but not their content.
##
##  Typical usage:
##      filename_replicator.pl -s /nfs/startdir -p /data/backup/prefix > x-file-data.sh
##
##****************************************************************************
##  CHANGE HISTORY:
##  DATE            VER.    WHO:COMMENTS
##  2015 03 27      1.0     KHT:Inititial Version entry.
##
##****************************************************************************
## This source is formatted with indents at every 4th column.  If using
## the vim editor use ":se ts=8 sw=4 sts=4 expandtab" to set up proper formatting.
##****************************************************************************

use English;
use Getopt::Long;

## Define main directories
my $StartDir = '';
my $Prefix = ''; ## Prefix for destination
my $NameFilter = '.+';
my $FakeFile = ''; ## if empty, then file contains "I am filename".

my $Debugging = 0;

my $Usage = <<'ENDUSAGE';
USAGE: filename_replicator.pl -s <startDir> -p <prefixDir> [-f <fakefile>] [-m <namefilter>] [-d/-nod] [> <script.sh>]

where:  -s <startDir>   specifies the starting directory. Subdirectories
                        will be recursively scanned.
        -p <prefixDir>  Prepended root for copy of directory structure.
        -f <fakefile>   Absolute path to a sample file to be used for all results.
        -m <namefilter> Name matching regular expression for filenames (example: '.*\.nc$' will only allow files ending in ".nc")
        -d/-nod         Debug/No Debug mode
ENDUSAGE

##-------------------------------------------------------------
##  Parse command line options.
##-------------------------------------------------------------
if (GetOptions( 'start=s'   => \$StartDir,
                'prefix=s'  => \$Prefix,
                'fakefile=s'=> \$FakeFile,
                'match=s'   => \$NameFilter,
                'debug!'    => \$Debugging,
                'help|?'    => \$UsageAndExit)) {
    if ($UsageAndExit) {
        print $Usage;
        print "Defaults:\n";
        print "  -s '$StartDir'\n";
        print "  -p '$Prefix'\n";
        print "  -f '$FakeFile'\n";
        print "  -m '$NameFilter'\n";
        print "  -d '$Debugging'\n";
        exit(0);
    }
} else {
    print "Error processing arguments.\n";
    die $Usage;
}

if (not $StartDir or not $Prefix) {
    print $Usage;
    exit;
}

##-------------------------------------------------------------
##  start main process
##-------------------------------------------------------------

if (-d $StartDir) {
    print "PREFIX=$Prefix\n";
    print "FAKEFILE=$FakeFile\n" if $FakeFile;
    print qq{mkdir -p "\$PREFIX/$StartDir"\n};
    &scandir($StartDir);
} else {
    warn "WARNING: not a directory: $StartDir";
}

##-------------------------------------------------------------
##  Clean up
##-------------------------------------------------------------
print "## Done\n" if $Debugging;


##***********************************************************************
##
##  process()
##
##  process($filepath)
##
##  Process filepaths. Generate a command to create a file.
##
##***********************************************************************
sub process {
    my $filepath = shift;

    if ($FakeFile) {
        print qq{cp "\$FAKEFILE" "\$PREFIX/$filepath"\n};
    } else {
        print qq{echo 'I am $filepath' > "\$PREFIX/$filepath"\n};
    }
} ## process()


##***********************************************************************
##
##  scandir()
##
##  scandir($dir)
##
##  Scan files in a directory. The directory read is $dir, 
##  and subdirectories will be recursively scanned.
##
##***********************************************************************
sub scandir {
    my $dir = shift;
    my $dirpat;
    my $file;
    my $Nprints;
    my @list;
    my @slist;
    
    print "## ---scanning in directory $dir\n" if $Debugging;
    
    ##-------------------------------------------------------------------------
    ##  Initialize the search list.
    ##-------------------------------------------------------------------------
    @slist = ();
    
    ##-------------------------------------------------------------------------
    ##  Build up the search list of files in the current directory.
    ##-------------------------------------------------------------------------
    opendir(DIR, "$dir") || die "Can't open dir $dir";
    @list = readdir(DIR);
    closedir(DIR);
    print "## list=@list (words=$#list)\n" if $Debugging;
    foreach $file (@list) {
        if (-f "$dir/$file" and $file =~ $NameFilter) {
            push @slist, "$dir/$file";
        }
    }
    
    print "## slist=@slist (words=$#slist)\n" if $Debugging;
    
    ##-------------------------------------------------------------------------
    ##  Do the actual scanning if there are entries in the scan list $slist.
    ##-------------------------------------------------------------------------
    foreach $file (@slist) {
        &process($file);
    }
    
    ##-------------------------------------------------------------------------
    ##  Call scandir recursively for any directories in the current directory.
    ##-------------------------------------------------------------------------
    foreach $file (@list) {
        if  (   -d "$dir/$file"         ##  It must be a directory.
            and $file !~ /^(\.|\.\.)$/  ##  Avoid '.' or '..' directories.
            ) {
            print qq{mkdir "\$PREFIX/$dir/$file"\n};
            &scandir("$dir/$file");
        }
    }
} ##  scandir()
