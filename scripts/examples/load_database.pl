#!/usr/bin/perl -w
use strict;
use File::Basename;
# load one or two databases from one or two sql dumps in ../../saved_content/databases
# 
# this file is built into the dist folder and tokens are substituted for database credentilas taken form the current configured target
# 
# usage ./load_database.pl filename1.sql [filename2.sql]
# or perl load_database.pl filename1.sql [filename2.sql]
# 
# filename1.sql is the filename of the sql dump in ../../saved_content/databases to be loaded into db1
# filename2.sql is optional and used for a 2nd database if one is configured for your current target

our $debug=0; # set 1 to log more info for debugging

our $sql_file1 = shift || '';
our $sql_file2 = shift || '';

if($sql_file1 eq '') {
	die "ERROR you must provide the sql filename of a file in ../../saved_content/databases\n";
}

# these vars are updated by the cfg file:
our $execute=1; # 0 to test, 1 to run
my $mysql = '/usr/bin/mysql';
my $mysql_ssh = 'mysql'; # where mysqldump is on ssh host (if used)
our $dirname = dirname(__FILE__);
my $save_backups_here = "$dirname/../../saved_content/databases";



#mysqldump -h 91.208.99.2 --port=3345 -u z00eu573_ba -p z00eu573_buildingassets > z00_ba_test.sql
#mysqldump --host=91.208.99.2 -u z00eu573_ba -p******** --port=3345 z00eu573_buildingassets > "./../db_exports/db_z00eu573_buildingassets_backup.sql
#
# use_ssh to run the command via ssh and get the output (useful for 1&1 or other hosts we can ssh on to.
# put the hostname & pw etc. into ~/.ssh/config)
# 
my @database_credentials = (
	{
		# db1
		use_ssh => '{{secrets.db.USE_SSH}}', db_host => '{{secrets.db.HOST}}', db_port => '{{secrets.db.PORT}}',
		db_name => '{{secrets.db.NAME}}', db_user => '{{secrets.db.USER}}', db_pass => '{{secrets.db.PASSWORD}}',
		sql_file => $sql_file1,
	},
	{
		# db2
		use_ssh => '{{secrets.db2.USE_SSH}}', db_host => '{{secrets.db2.HOST}}', db_port => '{{secrets.db2.PORT}}',
		db_name => '{{secrets.db2.NAME}}', db_user => '{{secrets.db2.USER}}', db_pass => '{{secrets.db2.PASSWORD}}',
		sql_file => $sql_file2,
	},
);

foreach my $db (@database_credentials){
	my $use_ssh = $db->{use_ssh} || '';
	my $db_name = $db->{db_name};
	my $db_host = $db->{db_host} || '';
	my $db_port = $db->{db_port} || '3306';
	my $db_user = $db->{db_user};
	my $db_pass = $db->{db_pass};
	my $sql_file = $db->{sql_file};

	if($db_name ne ''){ # ignore unnamed databases, our config allows for up to 2 and one will probably be empty
		my $hostname = $db_host;
		$db_host = '--host=' . $db_host if $db_host ne '';

		my $cmd = "$mysql $db_host -u $db_user -p$db_pass --port=$db_port $db_name -e \"source ../../saved_content/databases/$sql_file\"";

		if($use_ssh ne ''){
			$cmd = "ssh $use_ssh $mysql_ssh $db_host -u $db_user -p$db_pass --port=$db_port $db_name -e \"source ../../saved_content/databases/$sql_file\"";
		}

		my $xcmd = $cmd;
		$xcmd =~ s/p$db_pass/p********/g if $db_pass ne '';
		
		run($cmd, $xcmd);

	}
}

print get_timestamp() . " <<<<< Finished load.\n\n";

sub run{
	my $cmd=shift;
	my $xcmd=shift || $cmd; # optional modified version of cmd to be logged (perhaps without asswords visible)
	print "executing $xcmd\n";
	if ($execute){
		print `$cmd`;
	}else{
		print "  (cmd not executed in testing mode)\n";
	}
}

sub get_timestamp{
   my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
   return sprintf "%04u%02u%02u_%02u%02u%02u",$year+1900,$mon+1,$mday,$hour,$min,$sec;
}

1;