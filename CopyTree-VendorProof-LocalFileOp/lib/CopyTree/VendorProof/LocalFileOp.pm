package CopyTree::VendorProof::LocalFileOp;

use 5.008000;
use strict;
use warnings;

#our @ISA = qw(CopyTree::VendorProof); #if this weren't commented out, the use base below won't work

our $VERSION = '0.0011';
use Carp ();
use File::Basename ();
use MIME::Base64 ();
use Data::Dumper;
use base qw(CopyTree::VendorProof);#for the @ISAs
#use base happens at compile time, so we don't get the runtime error of our, saying that
#Can't locate package CopyTree::VendorProof for @SharePoint::SOAPHandler::ISA at (eval 8) line 2.


# Preloaded methods go here.

sub new {
	my $class =shift;
	my $path = shift;
	$path =~s/\/$// unless (!$path or $path eq '/');
	my $hashref;
	$hashref = bless {path => $path}, $class;
	return $hashref;
}

#lists files and / or dirs of a dir
sub fdls {
	my $inst = shift;
	
	unless (ref $inst ){
		Carp::croak("fdls item must be an instance, not a class\n");	
	}
	my $lsoption =shift;
	my $path =shift;
	$path =~s/\/$// unless (!$path or $path eq '/'); #removes trailing /

	$lsoption ='' if !($lsoption);
	$path = $inst ->SUPER::path if (!$path);
	my $dirH;
	opendir ($dirH, $path) or Carp::carp ("ERROR in local_ls cannot open dirH to $path $!\n");
	my @itemsnoparent =readdir $dirH;
	closedir $dirH;
	my @results;
	my @files;
	my @dirs;
	for (@itemsnoparent){
		next if  ($_ eq '.' or $_ eq '..');
		push @files, $path.'/'.$_ if (-f "$path/$_");
		push @dirs, $path.'/'.$_ if (-d "$path/$_");
	}
	$inst ->SUPER::fdls_ret ($lsoption, \@files, \@dirs);
}

sub is_fd{
	my $class_inst=shift;
	my $query = shift;
	if (-d $query){
		return 'd';
	}
	elsif (-f $query){
		return 'f';
	}
	else {
		my $parent = File::Basename::dirname($query);
		if (-d $parent){
			return 'pd';
		}
		else{return 0}
	}
}
#memory is a ref to a scalar, in bin mode
sub read_into_memory{
	my $inst=shift;
	my $sourcepath = shift;
	$sourcepath =~s/\/$// unless $sourcepath eq '/';
	$sourcepath=$inst->SUPER::path if (!$sourcepath);
	my $binfile;
	open my $readFH, "<", $sourcepath or  Carp::carp("cannot read sourcepath [$sourcepath] $!\n");
	binmode ($readFH);
	{#slurp
		local $/ =undef;
		$binfile = <$readFH>;
	}
	close $readFH;
	return \$binfile;

}
#memory is a ref to a scalar, in bin mode
sub write_from_memory{
	my $inst=shift;
	my $bincontentref = shift;
	my $dest = shift;
	$dest = $inst ->SUPER::path if (!$dest);
	open my $outFH, ">","$dest" or Carp::carp("cannot write to dest [$dest] $!\n");
	binmode ($outFH);
	print $outFH $$bincontentref ;
	close $outFH;


}

sub copy_local_files {
	my $inst = shift;
	my $source = shift;
	my $dest = shift;
	open my $inFH, "<", $source or Carp::carp( "cannot open source fh $source $!\n");
	open my $ouFH, ">", $dest or Carp::carp( "cannot open dest fh $dest $!\n");
	binmode ($inFH);
	binmode ($ouFH);
	{
		local $/=undef; #slurp 
		my $content = <$inFH>;
		print $ouFH $content;
	}
	close $inFH;
	close $ouFH;
}

sub cust_mkdir{
	my $inst = shift;
	my $path = shift;
	Carp::croak( "should not be mkdiring a root [/]\n" )unless $path ne '/';
	$path =~s/\/$// ; # purposefully disallow mkdir / unless $path eq '/';
	mkdir $path or Carp::carp ("cannot mkdir $path $!\n");

}
sub cust_rmdir{
	my $inst = shift;
	my $path = shift;
	Carp::croak( "should not be rmdiring a root [/]\n" )unless $path ne '/';
	$path =~s/\/$// ; # purposefully disallow rmdir / unless $path eq '/';
	unless (rmdir $path){
		Carp::carp( "the dir [$path] you want to remove is NOT EMPTY $!\n");
		Carp::croak( "wait. you told me to delete something that's not a dir. I'll stop for your protection.\n") if (! -d $path);
		my ($files, $dirs) = $inst ->ls_tree_fdret($path, $inst ->ls_tree($path) );
		print Dumper $files;
		print Dumper $dirs;
		Carp::carp( "danger - going to take out the whole tree under [$path]\n");
		Carp::carp( "going to wait 3 seconds. use Ctrl-c to escape this. Hold down the Ctrl key, and hit 'c'.\n");
		sleep 3;
		for (@$files){
			unlink $_ or Carp::carp ("cannot unlink $_ $!\n");
		}	
		for (@$dirs){
			rmdir $_ or Carp::carp ("cannot rmdir $_ $!\n");
		}
		rmdir $path;
	}
}
sub cust_rmfile {
	my $inst=shift;
	my $filepath=shift;
	Carp::croak("[$filepath] is not a file") if (! -f $filepath);
	unlink $filepath;
}



1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

CopyTree::VendorProof::LocalFileOp - Perl extension for providing a connecter instance for CopyTree::VendorProof.

This module provides CopyTree::VendorProof a connector instance with methods to deal with local file operations.


=head1 SYNOPSIS

  use CopyTree::VendorProof::LocalFileOp;

To create a LocalFileOp connector instance:

	my $lcfo_inst = CopyTree::VendorProof::LocalFileOp ->new;

To add a source or destination item to a CopyTree::VendorProof instance:

	my $ctvp_inst = CopyTree::VendorProof ->new;
	$ctvp_inst ->src ('some_source_path_of_local_file_system', $lcfo_inst);
	$ctvp_inst ->dst ('some_destination_path_of_local_file_system', $lcfo_inst);
	$ctvp_inst ->cp;


=head1 DESCRIPTION

CopyTree::VendorProof::LocalFileOp does nothing flashy - it merely provides an instance and local file operation methods for its parent class, CopyTree::VendorProof.

The methods provided in this connector objects include:

=over

	new
	fdls				
	is_fd
	read_info_memory
	write_from_memory
	copy_local_files
	cust_mkdir
	cust_rmdir
	cust_rmfile

=back

The functionality of these methods are descripbed in 
perldoc CopyTree::VendorProof and 
perldoc CopyTree::VendorProof::LocalFileOp

=head1 Instance Methods

Since these are class methods, the first item from @_ is the instance itself, and should be stored in $inst, or whatever you'd like to call it. 

=head2 0. new

	which takes no arguments, but blesses an anonymous hash into the data connection object and returns it

=head2 1. fdls

	which takes two arguments:
		an option ($lsoption) that's one of 'f', 'd', 'fdarrayrefs', or ''
		and a directory path $startpath.
		The lsoption is passed to the SUPER class fdls_ret, and is not handled at this level.
	This method will generate @files and @dirs, which are lists of files and directories that start with $startpath,
	And return $self -> SUPER::fdls_ret ($lsoption, \@files, \@dirs),
	which is ultimately a listing of the directory content, being one of
		@files, @dirs, (\@files, \@dirs), or  @files_and_dirs) depending on the options being 'f', 'd', 'fdarrayrefs' or ''

=head2 2. is_fd

	which takes a single argument of a file or dir $path,
	and returns 'd' for directory, 
		'f' for file,
		'pd' for non-existing, but has a valid parent dir,
		'0' for non of the above.

=head2 3. read_into_memory

	which takes the $sourcepath of a file, 
	and reads (slurps) it into a scalar $binfile #preferably in binmode,
	and returns it as \$binfile

=head2 4. write_from_memory

	which takes the reference to a scalar $binfile (\$binfile)  PLUS 
	a destination path, and writes the scalar to the destination.
	no return is necessary

=head2 5. copy_local_files

	which takes the $source and $destination files on the same file system, 
	and copies from $source to $destination.  No return is necessary.  This 
	method is included such that entirely remote operations may transfer faster,
	without an intermediate 'download to local machine' step.

=head2 6. cust_mkdir

	which takes a $dirpath and creates the dir.  If the parent of $dirpah
	does not exist, give a warning and do not do anything

=head2 7. cust_rmdir

	which takes a $dirpath and removes the entire dir tree from $dirpath
	croaks / dies if $dirpath is not a dir. No return is necessary.
	To make things easier, when writing this method, use

	my ($filesref, $dirsref) = $inst -> ls_tree_fdret( $dirpath, $inst -> ls_tree($dirpath);

	to get array references of @files and @dirs under $dirpath
	Note: ls_tree and ls_tree_fdret uses fdls, and are parent classes in CopyTree::VendorProof 

=head2 8. cust_rmfile

	which takes a $filepath and removes it.
	croaks / dies if $file is not a file. 




=head1 SEE ALSO

CopyTree::VendorProof
SharePoint::SOAPHandler

=head1 AUTHOR

dbmolester, dbmolester de gmail.com

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 by dbmolester

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.1 or,
at your option, any later version of Perl 5 you may have available.


=cut
