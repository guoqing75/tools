#!/usr/bin/env perl
#author guoqing75@gmail.com
# all free
#####################

use Getopt::Long;
use strict;

$|=1;    # turn off I/O buffering

my %df=();
my $df_count = 0;
my @df_key=();

my $start_dir = `pwd`;
chomp($start_dir);
my $depth_dir = 6;
my $min_size_to_print = 100000; #k
my $min_percent_to_print = 1; #1%

sub print_usage{
	print <<EOB
	Usage:
		$0 <-p|--path start_path> [-n|nonfs] [-d|--depth depth_number] [-s|--size min_size_to_print(k)] [-r|--rate min_percent_to_print(%)]
EOB
}

my $arg1 = $ARGV[0];
my ($op_start_dir,$op_nonfs, $op_depth_dir, $op_min_size_to_print, $op_min_percent_to_print);
my $op_result = GetOptions(
		'p|path=s' => \$op_start_dir,
		'n|nonfs' => \$op_nonfs,
		'd|depth=i' => \$op_depth_dir,
		's|size=i' => \$op_min_size_to_print,
		'r|rate=i' => \$op_min_percent_to_print
);

if(! $op_result || !$arg1 || $arg1 eq "-h" || $arg1 eq "-help" || $arg1 eq "--help")
{
	&print_usage();
	exit(1);
}
		
$start_dir = $op_start_dir if($op_start_dir);
$op_depth_dir && ($depth_dir = $op_depth_dir);
$op_min_size_to_print && ($min_size_to_print = $op_min_size_to_print);
$op_min_percent_to_print && ($min_percent_to_print = $op_min_percent_to_print);

my @nfs_arr = `df -t nfs|grep ':'|awk '{ print \$6; }'`;
my %nfs = ();
foreach my $i(@nfs_arr) { chomp($i); $nfs{$i} = 1; }

my @temp_arr = `df -k|grep -v '^procfs'|awk '{ print \$6","\$2; }'|sort -r|uniq|grep '^/'`;
foreach my $s (@temp_arr) {
	my ($mount, $size) = split(',', $s);
	if(!$op_nonfs or ($op_nonfs && !defined($nfs{$mount}))) {
		printf("%10dk,%s\n", $size,$mount) 
	} else {
		next;
	}
	$df{$mount} = $size;
	$df_key[$df_count] = $mount;
	$df_count++;
}

printf("--------------------------------------\n");
printf("--- Notice, passed procfs and nfs mount valume.\n");
printf("Filer:\n\tstart_dir:%s\n\tdepth_number:%s\n\tmin_size_to_print:%s(k)\n\tmin_percent_to_print:%s%\n", $start_dir, $depth_dir, $min_size_to_print,$min_percent_to_print);

printf("--------------------------------------crawling ...\n");

sub get_mount_size{
	my $dirname = shift;
    
    my $l=0;
    my $lc=-1;

	for(my $i=0;$i<$df_count;$i++) {
#		printf("%s %s\n", $df_key[$i], $dirname) if( $dirname =~ /^$df_key[$i]/);
        if( $dirname =~ /^$df_key[$i]/ && $l<length($df_key[$i])) {
            $l=length($df_key[$i]);
            $lc=$i;
        }
	}
	return $df{$df_key[$lc]}  if($lc>=0);
	die($dirname . " no mount point\n");
}

sub ScanDirectory {
    my ($workdir) = shift; 
    $workdir =~ s'//'/'g;

	my $p = $workdir . '/';
   if($op_nonfs) {
   while ((my $k,my $v) = each %nfs) {
      return if($op_nonfs && $workdir  =~ /^$k/);
   }}
    
    return if($workdir =~ '^/proc/?$' || $workdir =~ '^/dev/?$');

	my $dir_size = 0; #k

    opendir(DIR, $workdir) or die "Unable to open $workdir:$!\n";
    my @names = readdir(DIR);
    closedir(DIR);
 
	my $full_path_a;
    foreach my $name (@names){
        next if ($name eq "."); 
        next if ($name eq "..");
	
		my $full_path = $workdir .'/'. $name;
        $full_path =~ s'//'/'g;

		my ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size, $atime,$mtime,$ctime,$blksize,$blocks) = stat $full_path;
		my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($mtime);
		my $modify_datetime = sprintf("%04d%02d%02d-%02d%02d%02d", $year+1900, $mon+1, $mday, $hour, $min, $sec);
		my $size_k = int($size/1024);
		$dir_size +=  $size_k;
        if (-l $full_path) {
			next;
		} elsif(-d $full_path) {                     # is this a directory?
            $dir_size += &ScanDirectory($full_path);
            next;
        } elsif(-f $full_path) {
	    my $p = int($size_k/&get_mount_size($full_path)*100);
	    my @full_path_a = split('/', $full_path);
            printf("F%3d%% %10dK %s %s\n", $p, $size_k, $modify_datetime, $full_path) if(($depth_dir>0 && $#full_path_a<=$depth_dir) && ($size_k > $min_size_to_print or $p > $min_percent_to_print) && ($full_path !~ '^/proc/' )); # print the bad filename
        }
    }
	my $p = int($dir_size/&get_mount_size($workdir)*100);
	my $full_path = $workdir;
	my @full_path_a = split('/', $full_path);

		my ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size, $atime,$mtime,$ctime,$blksize,$blocks) = stat $workdir;
		my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($mtime);
		my $modify_datetime = sprintf("%04d%02d%02d-%02d%02d%02d", $year+1900, $mon+1, $mday, $hour, $min, $sec);
	printf("D%3d%% %10dK %s %s\n",$p, $dir_size,$modify_datetime, $workdir) if(($depth_dir>0 && $#full_path_a<=$depth_dir) && ($dir_size >  $min_size_to_print or $p > $min_percent_to_print) && ($full_path !~ '^/proc/'));
	return $dir_size;
}

&ScanDirectory($start_dir);


