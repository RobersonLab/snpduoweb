#!/usr/bin/perl -wT

###############################
# SNPduo.cgi                  #
# Author: Eli Roberson        #
# Created: September 04, 2007 #
# Edited: January 7, 2026     #
###############################

use constant RENAME => "TRUE";
# Rename can be used if the upload and output directories
#are on THE SAME PARTITION. Otherwise this must be set to FALSE

use constant CAIRO => "TRUE";
# Use CAIRO png utility in R. If set, this overrides
# PERLMAGICK directive. Requires png(type="cairo") support in R

use constant PERLMAGICK => "FALSE";
# Use PerlMagick for image conversion. Overrode by CAIRO "TRUE".
# If CAIRO = FALSE and PERLMAGICK = "FALSE" the script defaults
# back to a system command to ImageMagick convert command-line utility

###############################################
# Location of files and directories on server #
# Never leave trailing slashes.               #
# Make all FILE paths absolute.               #
###############################################
my $dataDir = "/home/SNP/uploads/SNPduo";
# Directory data files are uploaded to. Recommend this should NOT
# be in the html directory to avoid revealing someones data online.

my $outputDir = "/home/SNP/html/uploads/SNPduo";
# Directory output is transferred to for web display (must be in
# apache accessible directory)

my $webpage = "http://127.0.0.1/snpduo";
# Domain name of the server. When building output links uses
# $webpage/$outputFolder

my $outputFolder = "uploads/SNPduo";
# This is the $outputDir RELATIVE to $webpage.
# Used for linking PNGs (see above lines)

my $codeDir = "/home/SNP/cgi-bin/SNPduo";
# Directory where R template scripts are stored

my $compiledDir = "/home/SNP/cgi-bin/SNPduo";
# Directoy where compiled C Code is stored, along with
# the genomic feature (cytoband) files

my $pathtoR = "/usr/bin/R";
# Path to R executable

################################
# Set file and directory sizes #
################################
use constant FILE_MAX => 1024 * 1024 * 5000;
# upload limit - increased to 5 GB

use constant DIR_MAX => 1024 * 1024 * 50; 
# Max 50 Gb upload directory. Third number is number GB.
# Notice there are only 1024 * 1024, instead of three multiplies.
# This differs from FILE_MAX since it uses `du -c` output. That
# utility reports KB of file space (neglecting the need for 
# using 1024*1024*1024*

use constant OUTPUT_MAX => 1024 * 1024 * 50;
#Max 50 Gb of output stored in output directory. Same explain as DIR_MAX

##############################################################
# WARNING!!!!!!!!!!!!!!                                      #
# DO NOT CHANGE BELOW THE LINE UNLESS YOU ARE MODIFYING CODE #
##############################################################

use CGI;
# Required because the web input is parsed by CGI interface rather than POST

if ( PERLMAGICK eq "TRUE" and CAIRO eq "FALSE" )
{
	use Image::Magick; #####PERLMAGICK#####
}

$CGI::POST_MAX = FILE_MAX;
# Set maximum upload size based on $FILE_MAX set above

#########################
# Set up some constants #
#########################
my $current_revision = "v1.5.0";
my $startTimeStamp = timestamp();
my $pageGenerated = undef;
my @batchchroms = ();

my $cgi = new CGI;
my $rComparisonIndexString = 0;
my $totalNumberOfComparisons = 0;
my $comparisonCounter = 0;
my $ind2 = " ";
my $chrom;
my $chromList;

##############################################
# Save values from post to variables         #
# Give errors if not everything is specified #
##############################################

my $runmode = $cgi->param("runmode") or error($cgi, "Runmode not received");
my $file = $cgi->param("file") or error($cgi, "No file selected for upload");
my $delimiter = $cgi->param("delimiter") or error($cgi, "No delimiter selected");
my $platform = $cgi->param("platform") or error($cgi, "No platform selected");
my $ind1 = $cgi->param("ind1") or error($cgi, "Individual 1 not specified");
if($runmode ne "Batch" && $runmode ne "Tabulate") {$ind2 = $cgi->param("ind2") or error($cgi, "Individual 2 not specified. Please specify individual 2 or use batch mode");}
my @chromParam = $cgi->param("chrom") or error($cgi, "No chromosome specified");
my $postscriptWidth = $cgi->param("pswidth") or error($cgi, "No page width specified");
my $postscriptHeight = $cgi->param("psheight") or error($cgi, "No page height specified");
my $genomeBuild = $cgi->param("genomebuild") or error($cgi, "Genome build information not received");
my $makePostscript = $cgi->param("makeps") or error($cgi, "Postscript option not received");
my $makePng = $cgi->param("makepng") or error($cgi, "PNG option not received");
my $segmentation = $cgi->param("segmentation") or error($cgi, "Segmentation optino not received");

##############################
# Check for error conditions #
##############################

####################################
# Untaint variables                #
# Note: Taint mode is important to #
# prevent code injection.          #
# HIGHLY recommended to keep on    #
####################################

# Path
$ENV{'PATH'} =~ /(.*)/;
$ENV{'PATH'} = $1;

# Filename
if ( $file =~ /^.*[\/\\]([\w\@\.\-]*)$/ )
{
	$file = $1;
}
elsif  ($file =~ /^([\w\@\.\-]*)$/ )
{
	$file = $1;
}
else
{
	error( $cgi, "The filename \"$file\" contains illegal characters. Rename using only alphanumeric characters, \"_\", \"-\", \".\", and \"@\"." );
}

# Delimiter
if ( $delimiter =~ /^(\w*)$/ )
{
	$delimiter = $1
}
else
{
	error( $cgi, "The delimiter field contains illegal characters. If this message persists, please contact the webmaster" );
}

# Platform
if ( $platform =~ /^([\w]*)$/ )
{
	$platform = $1;
}
else
{
	error ( $cgi, "Platform field returned illegal characters. If this message persists, please contact the webmaster" );
}

# Chromosome
if ( scalar(@chromParam) < 1 ) { error($cgi, "No chromosome specified"); }

foreach $tmpChrom (@chromParam)
{
	if ($tmpChrom =~ /^(\w*)$/)
	{
		$tmpChrom = $1;
		
		# this was a legacy error.
		# i see no reason why it should still be checking.
		#if ($platform eq "HapMap" & $tmpChrom eq "GenomeByChromosome")
		#{
		#	error ($cgi, "HapMap samples not allowed in \"Genome - By Chromosome\" mode");
		#}
	}
	else
	{
		error($cgi, "The chromosome field returned $tmpChrom, which contains illegal characters. If this message persists, please contact the webmaster");
	}
}

# Width
if ($postscriptWidth =~ /^([\d\.]*)$/)
{
	$postscriptWidth = $1;
}
else
{
	error ($cgi, "The width field contains illegal characters. Please use only numeric characters in this field");
}

# Height
if ($postscriptHeight =~ /^([\d\.]*)$/)
{
	$postscriptHeight = $1;
}
else
{
	error ($cgi, "The height field contains illegal characters. Please use only numeric characters in this field");
}

# Genome build
if ($genomeBuild =~ /^([\w\.\-]*)$/)
{
	$genomeBuild = $1;
}
else
{
	error($cgi, "The genome build field returned illegal characters. If this message persists, please contact the webmaster");
}

# PNG
if ($makePng =~ /^(\w*)$/)
{
	$makePng = $1;
}
else
{
	error($cgi, "The Make PNG field returned illegal characters. If this message persists, please contact the webmaster");
}

#Postscript
if ($makePostscript =~ /^(\w*)$/)
{
	$makePostscript = $1;
}
else
{
	error($cgi, "The Make Postscript field returned illegal characters. If this message persists, please contact the webmaster");
}

# Segmentation
if ($segmentation =~ /^(\w*)$/)
{
	$segmentation = $1;
}
else
{
	error ($cgi, "Segmenation option returned $segmentation, which is not valid. If this message persists, please contact the webmaster");
}

# RUNMODE
if ($runmode =~ /^(\w*)$/)
{
	$runmode = $1;
}
else
{
	error ($cgi, "The Run Mode field returned illegal characters. If this message persists, please contact the webmaster");
}

# Individuals to compare
$ind1 =~ s/\s//g;
$ind2 =~ s/\s//g;
if ( $runmode ne "Batch" && $runmode ne "Tabulate" )
{
	# Individual 1
	if ($ind1 =~ /^(\d*)$/)
	{
		$ind1 = $1;
	}
	else
	{
		error ($cgi, "The field for individual 1 contains illegal characters. Please try again");
	}
	
	# Individual 2
	if ($ind2 =~ /^(\d*)$/)
	{
		$ind2 = $1;
	}
	else
	{
		error ($cgi, "The field for individual 2 contains illegal characters. Please try again");
	}
}
elsif ( $runmode eq  "Batch" || $runmode eq "Tabulate" )
{
	# Individual 1
	$ind1 =~ s/^,//;
	
	if ( $ind1 =~ /^([\d,\-\:]*)$/ )
	{
		$ind1 = $1;
	}
	else
	{
		error ( $cgi, "Input of multiple columns failed. This field should contain numbers separated by commas. Whitespace is allowed. Please try again" );
	}
}

#######################################
# Prep individuals for R Code vectors #
#######################################
if ( $runmode ne "Batch" && $runmode ne "Tabulate" )
{
	if ( $platform eq "HapMap" )
	{
		$ind1 -= 9;
		$ind2 -= 9;
	}
	$rComparisonIndexString = "c\($ind1, $ind2\)";
	$totalNumberOfComparisons = 1;
}
elsif ( $runmode eq "Batch" || $runmode eq "Tabulate" )
{	
	my @tmpComparisons = split( /,/, $ind1 );
	my $numberOfComparisons = 0;
	
	$rComparisonIndexString = 'c(';
	
	while ( <@tmpComparisons> )
	{
		my $col = $_;
		
		if ( $col =~ /[\:\-]/ )
		{
			local $" = ',';
			my ( $startCol, $endCol ) = split( /[\:\-]/, $col );
			
			if ( $platform eq "HapMap" )
			{
				$startCol -= 9;
				$endCol -= 9;
			}
			
			my @colArray = $startCol .. $endCol;
			$rComparisonIndexString .= "@colArray,";
			$numberOfComparisons += scalar( @colArray );
		}
		else
		{
			if ($platform eq "HapMap")
			{
				$col -= 9;
			}
			
			$rComparisonIndexString .= "$col,";
			++$numberOfComparisons;
		}
	}
	
	$rComparisonIndexString =~ s/,$//;
	$rComparisonIndexString .= ')';
	
	$totalNumberOfComparisons = ( $numberOfComparisons * ( $numberOfComparisons - 1 ) ) / 2;
}

########################
# Prep chromosome list #
########################
$chromList = "c(";
while ( <@chromParam> )
{
	my $tmpValue = $_;
	chomp ( $tmpValue );
	$chromList .= "\"$tmpValue\",";
}

$chromList =~ s/,$//;
$chromList .= ")";

if ( $chromList =~ /GenomeByChromosome/ )
{
	$chrom = "GenomeByChromosome";
	$chromList = NULL;
}
elsif ( $chromList =~ /Genome/ )
{
	$chrom = "Genome";
	$chromList = NULL;
}
elsif ( scalar(@chromParam) > 1 )
{
	$chrom = "GenomeByChromosome";
}
else
{
	$chrom = $chromParam[0];
}

###################
# Adjust filename #
###################

# Filename must start with a number or letter, not other characters or whitespace
if ($file !~ m/^\w.*$/)
{
    error($cgi, "Filename  \"${file}\" doesn't begin with number or letter"); 
}

#####################################
# Get rid of whitespace in filename #
#####################################
my $upload = $file;
$upload =~ s/\s/_/g;

##########################
# Check column separator #
##########################
if ($delimiter eq "tab")
{
	$delimiter = '"\t"';
}
elsif ($delimiter eq "csv")
{
	$delimiter = '","';
}
elsif ($delimiter eq "space")
{
	$delimiter = '" "';
}
else
{
	error($cgi, "Delimiter $delimiter not recognized");
}

###################################
# Check for upload directory size #
# Clean if necessary              #
###################################
DirectoryCheck( $dataDir, $outputDir );

#############################################
# Give a server side filename to the upload #
#############################################

# Test in a loop whether a file with the same name as the upload exists on the server
# If it does, add a digit to the end of the filename and repeat the test.
# Auto increment the digit until the filename is unique

until (! -e "${dataDir}/${upload}")
{
	$upload =~ s/^(\d*)(\S+)$/($1||0) + 1 . $2/e;
}

###########################################
# Don't call upload until now so errors   #
# happen before the file starts to upload #
###########################################
my $uploadStart = time();
my $fh = $cgi->upload( "file" ) or error( $cgi, "File upload did not begin properly" );
binmode $fh; #, ':raw'; # change to raw ASCII

################################
# setup output for text upload #
################################
open (LOCAL, ">${dataDir}/${upload}") or error ($cgi,  "Cannot make file for upload:$!");
binmode LOCAL; #, ':raw'; #':encoding(UTF-8)';

##############################
# Start platform adjustments #
##############################
my $rowcounts = -1; # Set the row count to -1 so that headers are ignored

############
# Illumina #
############
if ($platform eq "Illumina")
{
	local $/ = "\n"; # explicit input delimiter to ensure consistency in processing
	
	while (my $uploadline = <$fh>)
	{
		# initial processing
		# fix up line endings
		$uploadline =~ s/\r\n?/\n/g;
		chomp $uploadline;
		
		# do any tainting 
		$uploadline =~ /\A([0-9A-Za-z.,_\t -]+)\z/s or next;
		
		$uploadline = $1;
		
		# skip commented lines
		next if $uploadline =~ /^\s*\#/;
		
		# skip empty lines
		next if $uploadline =~ /^\s*$/;
		
		# get rid of stray hashes since R doesn't like them midstream
		$uploadline =~ s/\#+//g;
		   
		# Make the header something the script will find. Substitute Chr field for Chromosome
		$uploadline =~ s/^Chr${delimiter}/Chromosome${delimiter}/g;
		$uploadline =~ s/${delimiter}Chr${delimiter}/${delimiter}Chromosome${delimiter}/g;
		$uploadline =~ s/${delimiter}Chr\n/${delimiter}Chromosome\n/g;
		

		# Adjust the name of the position column
		$uploadline =~ s/^Position${delimiter}/Physical.Position${delimiter}/g;
		$uploadline =~ s/${delimiter}Position${delimiter}/${delimiter}Physical.Position${delimiter}/g;
		$uploadline =~ s/${delimiter}Position\n/${delimiter}Physical.Position\n/g;
		
		# Get read or .GType suffix on genotype columns
		$uploadline =~ s/\.GType//g;
		
		print LOCAL "$uploadline\n";
		
		++$rowcounts; # Autoincrement the row count
    }

    WriteRTemplate( $codeDir,$dataDir,$upload,$chrom,$chromList,$rComparisonIndexString,$compiledDir,$rowcounts,$postscriptWidth,$postscriptHeight,$genomeBuild, $totalNumberOfComparisons,$delimiter,$makePostscript, $runmode,$segmentation, 0 );
}

elsif ($platform eq "Affymetrix4")
{	
	##############
	# Affymetrix #
	##############
	local $/ = "\n"; # explicit input delimiter to ensure consistency in processing
	
	while (my $uploadline = <$fh>)
	{
		# initial processing
		# fix up line endings
		$uploadline =~ s/\r\n?/\n/g;
		chomp $uploadline;
		
		# undo any tainting 
		$uploadline =~ /\A([0-9A-Za-z.,_\t -]+)\z/s or next;
		
		$uploadline = $1;
		
		# skip commented lines
		next if $uploadline =~ /^\s*\#/;
		
		# skip empty lines
		next if $uploadline =~ /^\s*$/;
		
		# get rid of stray hashes since R doesn't like them midstream
		$uploadline =~ s/\#+//g;
		
		# New CNAT No Calls are blanks. Substitute so the program sees them
		$uploadline =~ s/${delimiter}${delimiter}/${delimiter}NoCall${delimiter}/g;
		$uploadline =~ s/${delimiter}\n/${delimiter}NoCall\n/g;
		
		# Remove annoying suffixes
		$uploadline =~ s/_Call//g;
		$uploadline =~ s/\.brlmm//g;
		$uploadline =~ s/\.loh//g;
		
		print LOCAL "$uploadline\n";
		
		++$rowcounts; # Autoincrement of the row count
    }

	WriteRTemplate( $codeDir,$dataDir,$upload,$chrom,$chromList,$rComparisonIndexString,$compiledDir,$rowcounts,$postscriptWidth,$postscriptHeight,$genomeBuild, $totalNumberOfComparisons,$delimiter,$makePostscript, $runmode,$segmentation, 1 );
}

elsif ($platform eq "HapMap")
{
    my $HapMapDelimiter = "";
	
	if ($delimiter =~ /\",\"/)
	{
		$HapMapDelimiter = ",";
	}
	elsif ($delimiter =~ /\"\\t\"/)
	{
		$HapMapDelimiter = "\t";
	}
	elsif ($delimiter =~ /\" \"/)
	{
		$HapMapDelimiter = " ";
	}
	
	##########
	# HapMap #
	##########
	local $/ = "\n"; # explicit input delimiter to ensure consistency in processing
	
	while (my $uploadline = <$fh>)
    {
		# initial processing
		# fix up line endings
		$uploadline =~ s/\r\n?/\n/g;
		chomp $uploadline;
		
		# do any tainting 
		$uploadline =~ /\A([0-9A-Za-z.,_\t -]+)\z/s or next;
		
		$uploadline = $1;
		
		# skip commented lines
		next if $uploadline =~ /^\s*\#/;
		
		# skip empty lines
		next if $uploadline =~ /^\s*$/;
		
		# get rid of stray hashes since R doesn't like them midstream
		$uploadline =~ s/\#+//g;
		
		# Split data up for printing
		my ($rs, $allele, $chromosome, $position, $strand, $build, $center, $prot, $assay, $panel, $QC, @genotypes) = split(/$HapMapDelimiter/, $uploadline );
	    
		# Before printing anything, check alleles to see how many there are.
		# If there are more than two, skip it.

		my @alleletest = split /\//, $allele;
	    
		if(scalar(@alleletest) > 2)
		{
			next;
		}
	    
		# Change chr and pos to the same as others
		$chromosome =~ s/chrom/Chromosome/g;
		$chromosome =~ s/chr//g;
		$position =~ s/pos/Physical.Position/g;
	    
		# Print the chromosome and position
		print LOCAL "${chromosome}${HapMapDelimiter}${position}";
	    
		if (scalar(@alleletest) < 2)
		{
			foreach $name (@genotypes)
			{
				print LOCAL "${HapMapDelimiter}${name}";
			}
			next;
		}
		
		# Change genotypes
		my ($Aallele, $Ballele) = split /\//, $allele; # Split the two alleles specified into two different scalars
		
		# Run a loop that will substitute the genotypes
		foreach $genotype (@genotypes)
		{
			my ($gen1, $gen2) = split(//,$genotype);
			
			if ($gen1 eq $Aallele)
			{
				$gen1="A";
			}
			elsif ($gen1 eq $Ballele)
			{
				$gen1="B";
			}
			else
			{
				$gen1 = "N";
			}
			
			if ($gen2 eq $Aallele)
			{
				$gen2="A";
			}
			elsif ($gen2 eq $Ballele)
			{
				$gen2="B";
			}
			else
			{
				$gen2 = "C";
			}
			
			$genotype = $gen1 . $gen2;
			
			if ($genotype eq "BA")
			{
				$genotype = "AB";
			}
			
			print LOCAL "${HapMapDelimiter}${genotype}"; # Print the transformed data
		}
		
		print LOCAL "\n"; # Print an end of line
		
		++$rowcounts; # Autoincrement the row count
	}
	
	WriteRTemplate( $codeDir,$dataDir,$upload,$chrom,$chromList,$rComparisonIndexString,$compiledDir,$rowcounts,$postscriptWidth,$postscriptHeight,$genomeBuild, $totalNumberOfComparisons,$delimiter,$makePostscript, $runmode,$segmentation, 0 );
}

elsif ($platform eq "Custom")
{
	##########
	# Custom #
	##########
	# Upload the file first
	local $/ = "\n"; # explicit input delimiter to ensure consistency in processing
	
	while (my $uploadline = <$fh>)
	{
		# initial processing
		# fix up line endings
		$uploadline =~ s/\r\n?/\n/g;
		chomp $uploadline;
		
		# do any tainting 
		$uploadline =~ /\A([0-9A-Za-z.,_\t -]+)\z/s or next;
		
		$uploadline = $1;
		
		# skip commented lines
		next if $uploadline =~ /^\s*\#/;
		
		# skip empty lines
		next if $uploadline =~ /^\s*$/;
		
		# get rid of stray hashes since R doesn't like them midstream
		$uploadline =~ s/\#+//g;
				
		print LOCAL "$uploadline\n";
		
		++$rowcounts; # Autoincrement the row count
	}

	WriteRTemplate( $codeDir,$dataDir,$upload,$chrom,$chromList,$rComparisonIndexString,$compiledDir,$rowcounts,$postscriptWidth,$postscriptHeight,$genomeBuild, $totalNumberOfComparisons,$delimiter,$makePostscript, $runmode,$segmentation, 0 ); 
}

close LOCAL; # close the filehandle

my $uploadEnd = time();
my $uploadTime = $uploadEnd - $uploadStart;

# Die if the file uploaded was blank
error( $cgi, "The uploaded file appears to be empty..." ) if (! -s "${dataDir}/${upload}");

#####################
# Run R computation #
#####################
my $ibsStart = time();
system ("cd ${dataDir}; $pathtoR --vanilla <${upload}.R 1>${dataDir}/${upload}.R.screendump 2>${dataDir}/${upload}.R.debug"); # Make call to R to perform SNPduo and make plots
my $ibsEnd = time();
my $ibsTime = $ibsEnd - $ibsStart;

###############################
# See if R finished correctly #
# Throw an error otherwise    #
###############################

my $DebugSize = -s "${dataDir}/${upload}.R.debug";

if ($DebugSize > 0)
{	
	open RERROR, "${dataDir}/${upload}.R.debug" or error($cgi, "An R error occurred, but I can't read the debugging file ${upload}.R.debug:$!");
		
	my @allRerror = <RERROR>;
	foreach $error (@allRerror)
	{
		$error =~ s/\n/\n\<BR\>\n/g;
	}
	
	my $errorindex = 0;
		
	for ($errorindex = 0; $errorindex < scalar(@allRerror); ++$errorindex)
	{
		if ($allRerror[$errorindex] =~ m/Error/g)
		{
			error($cgi, "\n<br>Processing cannot continue. Errors detected during R code execution. R message follows:\n<br><br>\n@allRerror");
		}
	}
}
else
{
	unlink("${dataDir}/${upload}.R.debug");
	unlink("${dataDir}/${upload}.R.screendump");
}
 
#######################################################
# Make an bed file for display on UCSC genome browser #
#######################################################
if ($runmode ne "Tabulate" && $segmentation eq "TRUE")
{
	open BEDFILE, ">${dataDir}/${upload}.bed" or error( $cgi, "Cannot create UCSC browser file: $!" );
	my $bedchrom = "chr" . $chrom; # Specify chromosome
	
	if ($bedchrom =~ /Genome/)
	{
		$bedchrom = "chr1";
	}
	
	print BEDFILE "browser position $bedchrom\n";
	
	for ($comparisonCounter = 1; $comparisonCounter <= $totalNumberOfComparisons; ++$comparisonCounter)
	{
		my $bedfileInd1 = "";
		my $bedfileInd2 = "";
		my $bedfileChr = "";
		my $bedfileRow = "Ind1";
		my $writeTrack = 1;
		
		my $currentComparison = $comparisonCounter;
		my $bedsummaryfile = $upload;
		my $bedchromprev = 0;
		$bedsummaryfile .= "_${currentComparison}.bedsummary.txt"; # Specify the filename for the overall summary data
		open FORBED, "${dataDir}/${bedsummaryfile}" or error($cgi,  "Cannot find $bedsummaryfile to generate bed file: $!"); 
		 
		BEDLoop: while (<FORBED>)
		{
			#CHR CHRStart CHREnd TRACKTYPE 1 + CHRStart CHREnd itemRGB #,#,#
			# IBS0 255,0,0 red
			# IBS1 99,184,255 steelblue1
			# IBS2 0,255,0 lime
			# Aberration 191,62,255 dark orchid
			
			chomp;
			
			if ($bedfileRow eq "Blocks")
			{
				if (/\/{3}/)
				{
					$bedfileRow = "Ind1";
					next BEDLoop;
				}
				
				my ($start, $end, $type) = split /,/;
				my $rgb = "";
				
				if ($type eq "IBS2")
				{
					$rgb = "77,175,74";
				}
				elsif ($type eq "IBS1")
				{
					$rgb = "55,126,184";
				}
				elsif ($type eq "IBS0")
				{
					$rgb = "228,26,28";
				}
				elsif ($type eq "Aberration")
				{
					$rgb = "152,78,163";
				}
				else
				{
					error($cgi, "IBS type of \"${type}\" not recognized.")
				}
				
				print BEDFILE "${bedfileChr}\t${start}\t${end}\t${type}\t0\t+\t${start}\t${end}\t${rgb}\n";
			}
			elsif ($bedfileRow eq "Ind1")
			{
				$bedfileInd1 = $_;
				$bedfileRow = "Ind2";
			}
			elsif ($bedfileRow eq "Ind2")
			{
				$bedfileInd2 = $_;
				$bedfileRow = "Chr";
			}
			elsif ($bedfileRow eq "Chr")
			{
				if ($_ eq "X" | $_ eq "x" | $_ eq "XY" | $_ eq "xy")
				{
					$_ = "X";
				}
				elsif ($_ eq "M" | $_ eq "MITO" | $_ eq "MT")
				{
					$_ = "M";
				}
				
				$bedfileChr = "chr" . $_;
				$bedfileRow = "Blocks";
				if ($writeTrack != 0)
				{
					print BEDFILE "track name=\"$bedfileInd1 $bedfileInd2\" description=\"$bedfileInd1 $bedfileInd2 IBS blocks\" visibility=1 priority=20 itemRgb=\"On\"\n";
					$writeTrack = 0;
				}
			}
		}
			
		close (FORBED);
		unlink ("${dataDir}/${bedsummaryfile}");
	}
	close (BEDFILE);
}
	
########################################
# The next section applies only to the #
# analysis of individual chromosomes.  #
########################################
my @genos = 0;
my @sumind1 = 0;
my @sumind2 = 0;
my @ibs = 0;
my @count = 0;

if ($chrom ne "GenomeByChromosome" && $runmode ne "Tabulate")
{
	for ($comparisonCounter = 1; $comparisonCounter <= $totalNumberOfComparisons; ++$comparisonCounter)
	{		
		my $currentComparison = $comparisonCounter;
		
		############################################
		# This section section applies only to the #
		# analysis of individual chromosomes or    #
		# whole genome on one plot                 #
		############################################
				
		if ($makePng eq "TRUE" && $makePostscript eq "TRUE")
		{
			if (PERLMAGICK eq "TRUE" && CAIRO eq "FALSE")
			{
				PerlMagickConvertPStoPNG($dataDir,$upload,$currentComparison,$postscriptWidth,$postscriptHeight,"FALSE"); #####PERLMAGICK#####
			}
			elsif (CAIRO eq "FALSE")
			{
				CLForkConvertPStoPNG($dataDir,$upload,$currentComparison,$postscriptWidth,$postscriptHeight,"FALSE");#####NOPERLMAGICK#####
			}
			
			if (RENAME eq "TRUE")
			{
				rename ("${dataDir}/${upload}_${currentComparison}.png", "${outputDir}/${upload}_${currentComparison}.png"); #####RENAME#####
			}
			else
			{
				system("mv ${dataDir}/${upload}_${currentComparison}.png ${outputDir}/${upload}_${currentComparison}.png"); #####NORENAME#####
			}
		}
			
		########################################
		# Move files to the proper directories to display on results page
		########################################
		# Using mv command-line directive
		if (RENAME ne "TRUE")
		{	 
			if ($makePostscript eq "TRUE")
			{
				system("mv ${dataDir}/${upload}_${currentComparison}.ps $outputDir/${upload}_${currentComparison}.ps; mv ${dataDir}/${upload}_${currentComparison}.summary.txt $outputDir/${upload}_${currentComparison}.summary.txt");  #####NORENAME#####
			}
			else
			{
				system("mv ${dataDir}/${upload}_${currentComparison}.summary.txt $outputDir/${upload}_${currentComparison}.summary.txt");  #####NORENAME#####
			}
		}
		
		# Using rename
	 	if (RENAME eq "TRUE")
		{
			if ($makePostscript eq "TRUE")
			{
				rename("${dataDir}/${upload}_${currentComparison}.ps","${outputDir}/${upload}_${currentComparison}.ps");
			}
			rename ("${dataDir}/${upload}_${currentComparison}.summary.txt", "${outputDir}/${upload}_${currentComparison}.summary.txt"); #####RENAME#####
		}
		
		# Make zip file
	 	if ($makePostscript eq "TRUE" && $makePng eq "TRUE")
	 	{
			system ("cd $outputDir; zip -q ${upload}_${currentComparison}.zip ${upload}_${currentComparison}.ps ${upload}_${currentComparison}.png ${upload}.summary_${currentComparison}.txt");
		}
		elsif ($makePostscript eq "TRUE" && $makePng eq "FALSE")
		{
			system ("cd $outputDir; zip -q ${upload}_${currentComparison}.zip ${upload}_${currentComparison}.ps ${upload}_${currentComparison}.summary.txt");
		}
		else
		{
			system ("cd $outputDir; zip -q ${upload}_${currentComparison}.zip ${upload}_${currentComparison}.summary.txt");
		}
		
		#####################################
		# Make a table for the results page #
		#####################################
		# Pull in summary data #
		########################
		open GENO, "${dataDir}/${upload}_${currentComparison}.gensum" or error ($cgi,  "Cannot open genotype summary:$!"); 
		
		while(<GENO>)
		{
			if ($_ !~ /^\s*$/)
			{
				chomp;
				my @tmp = split/\t/;
				push (@genos,$tmp[0]);
				push (@sumind1, $tmp[1]);
				push (@sumind2, $tmp[2]);
			}
		}
		close(GENO);
		
		unlink ("${dataDir}/${upload}_${currentComparison}.gensum");
		
		open IBS, "${dataDir}/${upload}_${currentComparison}.ibssum" or error ($cgi,  "Cannot open IBS summary:$!"); 
		
		while(<IBS>)
		{
			if ($_ !~ /^\s*$/)
			{
				chomp;
				@tmp = split /\t/;
				push (@ibs, $tmp[0]);
				push (@count, $tmp[1]);
			}
		}
		close (IBS);
		unlink ("${dataDir}/${upload}_${currentComparison}.ibssum");
	}
	
	# Moving BED
	if (RENAME eq "TRUE")
	{
		rename ("${dataDir}/${upload}.bed", "${outputDir}/${upload}.bed");
	}
	else
	{
		system("mv ${dataDir}/${upload}.bed $outputDir/${upload}.bed");
	}
	
	$pageGenerated = timestamp();
	
	print $cgi->header();

	print("<html>\n<head>\n<title>SNPduo Results for $file</title>\n\n<style type=\"text/css\">\ntable {margin-left:auto;margin-right:auto}\ntr {text-align: center; vertical-align: middle}\nth {text-align: center}\nbody {font-family: verdana, arial, helvetica, sans-serif}\n</style>\n</head>\n<body>\n\n<p>\nFile uploaded: $file\n<br>SNPduo Version: $current_revision\n<br>Analysis started at $startTimeStamp\n<br>Page generated at $pageGenerated\n<br>File upload: $uploadTime seconds\n<br>IBS calculation: $ibsTime seconds</p>");
	
	if ($segmentation eq "TRUE")
	{
		print ("<p>\n");
		print ("Click <a href=\"${webpage}/${outputFolder}/${upload}.bed\">here (.bed)</a> to download combined BED file of IBS blocks.\n");
		print ("</p>\n");
	}
	
	for ($comparisonCounter = 1; $comparisonCounter <= $totalNumberOfComparisons; ++$comparisonCounter)
	{		
		my $currentComparison = $comparisonCounter;
		########################
		# Make the HTML output #
		########################
		
		print ("<hr>\n\n");

		##########################################
		# Standard output - Genome or Chromosome #
		##########################################
		if ($makePng eq "TRUE" && $makePostscript eq "TRUE")
		{
			print("<center><img src=\"$webpage/${outputFolder}/${upload}_${currentComparison}.png\" alt=\"PNG of SNPduo output\"></center>\n<br>");
			print("<p>Click <a href=\"${webpage}/${outputFolder}/${upload}_${currentComparison}.png\">here (.png)</a> to download the displayed image.<br>\n");
		}
		else
		{
			print("<p>\n");
		}
		
		if ($makePostscript eq "TRUE")
		{
			print ("Click <a href=\"${webpage}/${outputFolder}/${upload}_${currentComparison}.ps\">here (.ps)</a> to download the postscript file.<br>\n");
		}
		
		print ("Click <a href=\"${webpage}/${outputFolder}/${upload}_${currentComparison}.summary.txt\">here (.txt)</a> to download the text summary.<br>\n");
		print ("Or click <a href=\"${webpage}/${outputFolder}/${upload}_${currentComparison}.zip\">here (.zip)</a> to download a zip file containing the summary file and any generated images.\n</p>\n\n");
		
		print ("<table align=\"center\" border=\"1\">\n\n");
		
		my $loopcount = 1;
		
		for ($loopcount = ( 1  +( 5 * ( $currentComparison - 1 ) ) ); $loopcount < ( 6 + ( 5 * ( $currentComparison - 1 ) ) ); ++$loopcount)
		{
			print ("<tr>\n<td>$genos[$loopcount]</td>\n");
			print ("<td>$sumind1[$loopcount]</td>\n");
			print ("<td>$sumind2[$loopcount]</td>\n</tr>\n\n");
		}
		
		print ("</table>\n\n<br>\n\n");
		
		print ("<table align=\"center\" border=\"1\" cellpadding=\"3\">\n");
		print ("<tr>\n<th>Identity by State</th>\n<th>Counts</th>\n</tr>\n\n");
		
		for ($loopcount = ( 2 + ( 4 * ( $currentComparison - 1 )) ); $loopcount < ( 5 + ( 4 * ( $currentComparison - 1 ) ) ); ++$loopcount)
		{
			print ("<tr>\n<td align=\"center\">$ibs[$loopcount]</td>\n");
			print ("<td align=\"center\" border=\"1\" cellpadding=\"3\">$count[$loopcount]</td>\n</tr>\n\n");
		}
		
		print ("</table>\n");
		
		print ("<br><br>\n");
	}
	
	print("\n</body>\n</html>\n");

}

elsif ($chrom eq "GenomeByChromosome" && $runmode ne "Tabulate")
{	
	#########################################
	# Grab the list of chromosomes analyzed #
	# processing of the appropriate files   #
	#########################################
	open BATCHLIST, "${dataDir}/${upload}_1.chromlist" or error ($cgi,  "Can't open list of chromosomes processed:$!"); 
	
	@batchchroms = <BATCHLIST>;
	chomp (@batchchroms);
	
	close BATCHLIST;

	@batchchroms = SortChromosomeList( @batchchroms );
	
	for ($comparisonCounter = 1; $comparisonCounter <= $totalNumberOfComparisons; ++$comparisonCounter)
	{		
		my $currentComparison = $comparisonCounter;	
		########################################
		# The next section applies only to the #
		# analysis of the genome by chromosome #
		########################################
		
		unlink ("${dataDir}/${upload}_${currentComparison}.chromlist");
		
		#########################
		# Make some pngs        #
		# Move to web directory #
		# Then add to zip file  #
		# Remove files          #	
		#########################
		my $pngwidth = 0;#####PERLMAGICK#####
		my $pngheight = 0;#####PERLMAGICK#####
		
		if ($makePng eq "TRUE" && $makePostscript eq "TRUE")
		{
			my $tmpchrom = 0;
			
			while (<@batchchroms>)
			{
				$tmpchrom = $_;
				if ($tmpchrom =~ /^\s*(\w*)\s*$/)
				{
					$tmpchrom = $1;
				}
				else
				{
					error($cgi, "Couldn't unprotect tainted data: $!");
				}
				
				$tmpchrom = $upload ."chr" . $tmpchrom;
				
				if (PERLMAGICK eq "TRUE" && CAIRO eq "FALSE")
				{
					PerlMagickConvertPStoPNG ($dataDir,$tmpchrom,$currentComparison,$postscriptWidth,$postscriptHeight,"TRUE"); #####PERLMAGICK#####
				}
				elsif (CAIRO eq "FALSE")
				{
					CLForkConvertPStoPNG ($dataDir,$tmpchrom,$currentComparison,$postscriptWidth,$postscriptHeight,"TRUE"); #####NOPERLMAGICK#####
				}
				
				# Move output files to webaccessible directory
				if (RENAME eq "TRUE")
				{
					rename ("${dataDir}/${tmpchrom}_${currentComparison}.ps","${outputDir}/${tmpchrom}_${currentComparison}.ps"); #####RENAME#####
					rename ("${dataDir}/${tmpchrom}_${currentComparison}.png","${outputDir}/${tmpchrom}_${currentComparison}.png"); #####RENAME#####
					rename ("${dataDir}/${tmpchrom}thumb_${currentComparison}.png","${outputDir}/${tmpchrom}thumb_${currentComparison}.png"); #####RENAME#####
				}
				else
				{
					system("mv ${dataDir}/${tmpchrom}_${currentComparison}.ps ${outputDir}/${tmpchrom}_${currentComparison}.ps; mv ${dataDir}/${tmpchrom}_${currentComparison}.png ${outputDir}/${tmpchrom}_${currentComparison}.png; mv ${dataDir}/${tmpchrom}thumb_${currentComparison}.png ${outputDir}/${tmpchrom}thumb_${currentComparison}.png");######NORENAME#####
				}
			}
		} 
		
		#######################
		# Move the summary    #
		# Add to the zip file #
		#######################
		if (RENAME eq "TRUE")
		{
			rename ("${dataDir}/${upload}_${currentComparison}.summary.txt","${outputDir}/${upload}_${currentComparison}.summary.txt"); #####RENAME#####
		}
		else
		{
			system("mv ${dataDir}/${upload}_${currentComparison}.summary.txt ${outputDir}/${upload}_${currentComparison}.summary.txt");
		}
	 	
	 	if ($makePng eq "TRUE" && $makePostscript eq "TRUE")
	 	{
		 	system ("cd ${outputDir}; zip -q ${upload}_${currentComparison}.zip ${upload}_${currentComparison}.summary.txt ${upload}*_${currentComparison}.ps ${upload}*_${currentComparison}.png");
	 	}
	 	elsif ($makePng eq "FALSE" && $makePostscript eq "TRUE")
	 	{
		 	system ("cd ${outputDir}; zip -q ${upload}_${currentComparison}.zip ${upload}_${currentComparison}.summary.txt  ${upload}*_${currentComparison}.ps");
	 	}
	 	else
	 	{
		 	system ("cd ${outputDir}; zip -q ${upload}_${currentComparison}.zip ${upload}_${currentComparison}.summary.txt  ${upload}*_${currentComparison}.ps");
	 	}
	
		########################
		# Pull in summary data #
		########################
		while (<@batchchroms>)
		{			
			$tmpchrom = $_;
			if ($tmpchrom =~ /^\s*(\w*)\s*$/)
			{
				$tmpchrom = $1;
			}
			else
			{
				error ($cgi, "Couldn't unprotect tainted data: $!");
			}
			
			$tmpchrom = $upload ."chr" . $tmpchrom;
			
			open GENO, "${dataDir}/${tmpchrom}_${currentComparison}.gensum" or error ($cgi,  "Cannot open genotype summary ${tmpchrom}_${currentComparison}.gensum:$!"); 
					
			while (<GENO>)
			{
				chomp;
				if ($_ !~ /^\s*$/)
				{
					my @tmp = split/\t/;
					push (@genos,$tmp[0]);
					push (@sumind1, $tmp[1]);
					push (@sumind2, $tmp[2]);
				}
			}
			close (GENO);
			unlink ("${dataDir}/${tmpchrom}_${currentComparison}.gensum");
			
			open IBS, "${dataDir}/${tmpchrom}_${currentComparison}.ibssum" or error ($cgi,  "Cannot open IBS summary ${tmpchrom}_${currentComparison}.ibssum:$!"); 
					
			while (<IBS>)
			{
				chomp;
				if ($_ !~ /^\s*$/)
				{
					@tmp = split /\t/;
					push (@ibs, $tmp[0]);
					push (@count, $tmp[1]);
				}
			}
			close (IBS);
			unlink ("${dataDir}/${tmpchrom}_${currentComparison}.ibssum");
		}
	}
	
	# Moving BED
	if (RENAME eq "TRUE")
	{
		rename ("${dataDir}/${upload}.bed", "${outputDir}/${upload}.bed");
	}
	else
	{
		system("mv ${dataDir}/${upload}.bed $outputDir/$upload.bed");
	}
	
	########################
	# Make the HTML output #
	########################
		
	#################################
	# Output for GenomeByChromosome #
	#################################
	$pageGenerated = timestamp();
	
	print $cgi->header();

	print "<html>\n<head>\n<title>SNPduo Results for $file</title>\n<style type=\"text/css\">\ntable {margin-left: auto; margin-right: auto}\ntr {text-align: center; vertical-align: middle}\nth {text-align: center}\nbody {font-family: verdana, arial, helvetica, sans-serif}\n</style></head>\n<body>\n\n<p>\nFile uploaded: $file\n<br>SNPduo Version: $current_revision\n<br>Analysis started at $startTimeStamp\n<br>Page generated at $pageGenerated\n<br>\nFile upload: $uploadTime seconds\n<br>IBS calculation: $ibsTime seconds</p>";
	
	if ($segmentation eq "TRUE")
	{
		print ("<p>\n");
		print ("Click <a href=\"${webpage}/${outputFolder}/${upload}.bed\">here (.bed)</a> to download combined BED file of IBS blocks.\n");
		print ("</p>\n");
	}
	
	my $masterOffset = 0;
	
	for ($comparisonCounter = 1; $comparisonCounter <= $totalNumberOfComparisons; ++$comparisonCounter)
	{		
		print ("<hr>\n\n");
		
		my $currentComparison = $comparisonCounter;
		my $chromCounter = 0;		
		my $rowcounter = 1;
		
		# Print a table showing reduced images for this format
		if ($makePng eq "TRUE")
		{
			print "<center><table>\n<tr><th colspan=\"12\">Chromosome Images</th></tr>\n\n<tr>";
			
			while (<@batchchroms>)
			{
				my $htmlchrom = $_;
				
				if ($htmlchrom =~ /^\s*(\w*)\s*$/)
				{
					$htmlchrom = $1;
				}
				else
				{
					error($cgi, "Couldn't unprotect tainted data: $!");
				}
				
				$tmpchrom = $upload . "chr" . $htmlchrom;
				
				if ($rowcounter > 6)
				{
					print "</tr>\n\n<tr>\n";
					$rowcounter = 1;
				}
				
				print "<td>$htmlchrom</td>\n<td><a href=\"${webpage}/${outputFolder}/${tmpchrom}_${currentComparison}.png\"><img src=\"${webpage}/${outputFolder}/${tmpchrom}thumb_${currentComparison}.png\" alt=\"${tmpchrom}_${currentComparison} SNPduo Output\"></a></td>\n";
				
				++$rowcounter;
			}
			
			if ($rowcounter <= 6)
			{
				until ($rowcounter > 6)
				{
					print "<td>&nbsp\;</td>\n";
					++$rowcounter;
				}
			}
			
			print "</tr></table></center>\n\n";
		}
		
		# Show the download links
		print "<p><br>\n\n";
		print "Click <a href=\"${webpage}/${outputFolder}/${upload}_${currentComparison}.summary.txt\">here (.txt)</a> to download the text summary.<br>\n";
		print "Click <a href=\"${webpage}/${outputFolder}/${upload}_${currentComparison}.zip\">here (.zip)</a> to download a zip file containing the summary file and any generated images.";
		print "</p>\n\n";
		print "<table align=\"center\" border=\"1\" cellpadding=\"3\">\n";
		print "<tr><th rowspan=\"2\">Chromosome</th>\n";
		print "<th colspan=\"4\">$sumind1[1+(5*$masterOffset)]</th>\n";
		print "<th colspan=\"4\">$sumind2[1+(5*$masterOffset)]</th>\n</tr>\n";
		print "\n<tr>\n<th>AA</th>\n<th>AB</th>\n<th>BB</th>\n<th>NoCall</th>\n<th>AA</th>\n<th>AB</th>\n<th>BB</th>\n<th>NoCall</th>\n</tr>\n\n";
		
		my $offset = $masterOffset;
		
		while (<@batchchroms>)
		{		
			$htmlchrom = $_;
			$tmpchrom = $upload . "chr" . $_;
			
			print "<tr>\n<td>$htmlchrom</td>\n";
			print "<td>$sumind1[2+(5*$offset)]</td>\n";
			print "<td>$sumind1[3+(5*$offset)]</td>\n";
			print "<td>$sumind1[4+(5*$offset)]</td>\n";
			print "<td>$sumind1[5+(5*$offset)]</td>\n";
			print "<td>$sumind2[2+(5*$offset)]</td>\n";
			print "<td>$sumind2[3+(5*$offset)]</td>\n";
			print "<td>$sumind2[4+(5*$offset)]</td>\n";
			print "<td>$sumind2[5+(5*$offset)]</td>\n";
			print "</tr>\n\n";
			
			++$offset;
		}
		
		print "</table>\n\n<br>\n\n";
		
		print "<table align=\"center\" border=\"1\" cellpadding=\"3\">\n";
		print "<tr>\n<th rowspan=\"2\">Chromosome</th>\n<th colspan=\"3\">Identity by State</th>\n</tr>\n\n";
		print "<tr>\n<th>IBS 0</th>\n<th>IBS 1</th>\n<th>IBS 2</th>\n</tr>\n\n";
		
		$offset = $masterOffset;
		
		while (<@batchchroms>)
		{
			$htmlchrom = $_;
			
			if ($htmlchrom =~ /^\s*(\w*)\s*$/)
			{
				$htmlchrom = $1;
			}
			else
			{
				error($cgi, "Couldn't unprotect tainted data: $!");
			}
			
			$tmpchrom = $upload . "chr" . $_;
			
			print "<tr>\n<td>$htmlchrom</td>\n";
			print "<td>$count[2+(4*$offset)]</td>\n";
			print "<td>$count[3+(4*$offset)]</td>\n";
			print "<td>$count[4+(4*$offset)]</td>\n";
			print "</tr>\n\n";
			
			++$offset;
		}
		print "</table>\n<br>\n<br>\n<br>\n";
		
		$masterOffset = $offset;
	}
	print "</body>\n</html>";
}

elsif ($runmode eq "Tabulate")
{
	########################################
	# Grab the list of chromsomes analyzed #
	# processing of the appropriate files  #
	########################################
	open BATCHLIST, "${dataDir}/${upload}.chromlist" or error ($cgi,  "Can't open list of chromosomes processed:$!"); 
	
	@batchchroms = <BATCHLIST>;
	chomp (@batchchroms);
	
	close BATCHLIST;
	unlink ("${dataDir}/${upload}.chromlist");

	@batchchroms = SortChromosomeList( @batchchroms );
	
	########################################
	# Move the ibs and genotype summary files
	########################################
	if (RENAME eq "TRUE")
	{
		rename ("${dataDir}/${upload}.SummaryIBS.csv","${outputDir}/${upload}.SummaryIBS.csv");
		rename ("${dataDir}/${upload}.SummaryGenotype.csv","${outputDir}/${upload}.SummaryGenotype.csv");
		rename ("${dataDir}/${upload}.SummaryMeanSD.csv", "${outputDir}/${upload}.SummaryMeanSD.csv");
	}
	else
	{
		system ("mv ${dataDir}/${upload}.SummaryIBS.csv ${outputDir}/${upload}.SummaryIBS.csv; mv ${dataDir}/${upload}.SummaryGenotype.csv ${outputDir}/${upload}.SummaryGenotype.csv; mv ${dataDir}/${upload}.SummaryMeanSD.csv ${outputDir}/${upload}.SummaryMeanSD.csv");
	}
	
	########################
	# Make the HTML output #
	########################
		
	#################################
	# Output for GenomeByChromosome #
	#################################
	$pageGenerated = timestamp();
	
	################################
	# HTML header and initial text #
	################################
	print $cgi->header();
	print "<html>\n<head>\n<title>SNPduo Results for $file</title>\n<style type=\"text/css\">\ntable {margin-left: auto; margin-right: auto}\ntr {text-align: center; vertical-align: middle}\nth {text-align: center}\nbody {font-family: verdana, arial, helvetica, sans-serif}\n</style></head>\n<body>\n\n<p>\nFile uploaded: $file\n<br>SNPduo Version: $current_revision\n<br>Analysis started at $startTimeStamp\n<br>Page generated at $pageGenerated\n<br>\nFile upload: $uploadTime seconds\n<br>IBS calculation: $ibsTime seconds</p>";
	
	##############################
	# horizontal break and links #
	##############################
	print "<hr>\n\n";
	print "<p><br>\n\n";
	print "Click <a href=\"${webpage}/${outputFolder}/${upload}.SummaryGenotype.csv\">here (.csv)</a> to download the Genotype summary.<br>\n";
	print "Click <a href=\"${webpage}/${outputFolder}/${upload}.SummaryIBS.csv\">here (.csv)</a> to download the IBS summary.<br>\n";
	print "Click <a href=\"${webpage}/${outputFolder}/${upload}.SummaryMeanSD.csv\">here (.csv)</a> to download the Autosomal Mean / SD summary.<br>\n";
	print "</p>\n\n";
	
	################################
	# Print Genotype summary table #
	################################
	print "<table align=\"center\" border=\"1\" cellpadding=\"3\">\n";
	print "<tr><th rowspan=\"2\">Samples</th>\n";
	
	while (<@batchchroms>)
	{
		my $tmpChrom = $_;
		chomp ($tmpChrom);
		print "<th colspan=\"4\">Chromosome ${tmpChrom}</th>\n";
	}
	print "</tr>\n\n";
	
	print "<tr>\n";
	
	for (my $i = 0; $i < scalar(@batchchroms); ++$i)
	{
		print "<th>AA</th>\n";
		print "<th>AB</th>\n";
		print "<th>BB</th>\n";
		print "<th>NC</th>\n";
	}
	
	##################################
	# Print genotype data row by row #
	##################################
	my $prevSample = "NULLVALUENOPREVIOUSVALUE";
	
	open GENO, "${outputDir}/${upload}.SummaryGenotype.csv" or error ($cgi, "Couldn't open genotype summary file :$!");
	my $trash = <GENO>;
	
	while (<GENO>)
	{
		chomp;
		my ($currSample, $currChrom, $AA, $AB, $BB, $NC) = split /,/;
		
		if ($currSample ne $prevSample)
		{
			print "</tr>\n\n<tr>\n";
			print "<td>$currSample</td>\n";
			
			$prevSample = $currSample;
		}
		
		print "<td>$AA</td>\n<td>$AB</td>\n<td>$BB</td>\n<td>$NC</td>\n";
	}
	print "</tr>\n\n";
	print "</table>\n\n";
	close GENO;
	
	###########################
	# Print IBS summary table #
	###########################
	print "<br><br>\n\n<table align=\"center\" border=\"1\" cellpadding=\"3\">\n";
	print "<tr><th rowspan=\"2\">Sample A</th>\n";
	print "<th rowspan=\"2\">Sample B</th>\n";
	
	while (<@batchchroms>)
	{
		my $tmpChrom = $_;
		chomp ($tmpChrom);
		
		print "<th colspan=\"3\">Chromosome ${tmpChrom}</th>\n";
	}
	
	print "</tr>\n\n";
	print "<tr>\n";
	
	for (my $i = 0; $i < scalar(@batchchroms); ++$i)
	{
		print "<th>IBS0</th>\n";
		print "<th>IBS1</th>\n";
		print "<th>IBS2</th>\n";
	}
	
	#############################
	# Print IBS data row by row #
	#############################
	my $prevSampleA = "NULLVALUENOPREVIOUSVALUE";
	my $prevSampleB = "NULLVALUENOPREVIOUSVALUE";
	
	open IBS, "${outputDir}/${upload}.SummaryIBS.csv" or error ($cgi, "Couldn't open IBS summary file :$!");
	$trash = <IBS>;
	
	while (<IBS>)
	{
		chomp;
		my ($SampleA, $SampleB, $Chromosome, $IBS0, $IBS1, $IBS2) = split /,/;
		
		if ($SampleA ne $prevSampleA || $SampleB ne $prevSampleB)
		{
			print "</tr>\n\n<tr>\n";
			print "<td>$SampleA</td>\n<td>$SampleB</td>\n";
			
			$prevSampleA = $SampleA;
			$prevSampleB = $SampleB;
		}
		
		print "<td>$IBS0</td>\n<td>$IBS1</td>\n<td>$IBS2</td>\n";
	}
	print "</tr>\n\n";
	print "</table>\n\n";
	close IBS;
	
	###############################
	# Print Mean SD summary table #
	###############################
	print "<br><br>\n\n<table align=\"center\" border=\"1\" cellpadding=\"3\">\n";
	print "<tr><th>Sample A</th>\n";
	print "<th>Sample B</th>\n";
	print "<th>Mean IBS</th>\n";
	print "<th>SD IBS</th>\n";
	print "</tr>\n";
	
	###################################
	# Print Mean / SD data row by row #
	###################################
	open MEANSD, "${outputDir}/${upload}.SummaryMeanSD.csv" or error ($cgi, "Couldn't open Mean/SD summary file :$!");
	$trash = <MEANSD>;
	
	while (<MEANSD>)
	{
		chomp;
		my ($SampleA, $SampleB, $Mean, $SD) = split /,/;
		
		print "<tr>\n";
		print "<td>${SampleA}</td>\n<td>${SampleB}</td>\n<td>${Mean}</td>\n<td>${SD}</td>\n";
		print "</tr>\n";
	}
	print "</table>\n\n";
	
	close MEANSD;
	########################
	# Close remaining tags #
	########################
	print "</body>\n</html>";
}

##################################
# Subroutine for error reporting #
##################################
sub error
{
	my ($out, $message) = @_;
	
	print $out->header("text/html");
	print ("<html>\n<head>\n<title>Error Page\n</title>\n\n<style type=\"text/css\">\ntable {margin-left: auto; margin-right: auto}\ntr {text-align: center; vertical-align: middle}\nth {text-align: center}\nbody {font-family: verdana, arial, helvetica, sans-serif}\n</style>\n</head>\n<body>\n");
	
	print ("<p>An error has occurred during file processing\n<br>Error message: ${message}\n</p>\n");
	print ("</body>\n</html>");

	exit 1;
}

####################################
# Subroutine for timestamping runs #
####################################
sub timestamp
{
	my @months = qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec);
	my @weekDays = qw(Sun Mon Tue Wed Thu Fri Sat Sun);
	
	my ($second, $minute, $hour, $dayOfMonth, $month, $yearOffset, $dayOfWeek, $dayOfYear, $daylightSavings) = localtime();
	
	$year = 1900 + $yearOffset;
	
	if ($minute < 10)
	{
		$minute = "0" . $minute;
	}
	
	if ($second < 10)
	{
		$second = "0" . $second;
	}
	
	$theTime = "$hour:$minute:$second on $weekDays[$dayOfWeek] $months[$month] $dayOfMonth, $year";
	
	return ($theTime);
}

##############################################
# Subroutine for generating custom R scripts #
##############################################
sub WriteRTemplate
{
	my ( $codeDir, $dataDir, $uploadName, $chromName, $chromListObjects, $RcomparisonVector,
	$compiledDir,$rowCounts,$psWidth,$psHeight,$Build,$ComparisonVector,$Delimiter,$Makeps, $RunMode, $BEDMode, $skipValue ) = @_;
	
	open TEMPLATE, "${codeDir}/snpduo_code_template.R" or error ( $cgi, "Cannot open snpduo_code_template: $!" );
	open R_CODE, ">${dataDir}/${uploadName}.R" or error ( $cgi, "Cannot make custom R code: $!" );
	
	while (<TEMPLATE>)
	{
		s/SKIP_HOLDER/$skipValue/g;
		s/UPLOAD_HOLDER/$uploadName/g;
		s/CHR_HOLDER/$chromName/g;
		s/CHR_LIST/$chromListObjects/g;
		s/IND_HOLDER/$RcomparisonVector/g;
		s/SCRIPT_SOURCE/$codeDir\/SNPduoFunctions\.R/g;
		s/COMPILE_DIR/$compiledDir/g;
		s/ROW_HOLDER/$rowCounts/g;
		s/WIDTH_HOLDER/$psWidth/g;
		s/HEIGHT_HOLDER/$psHeight/g;
		s/BUILD_HOLDER/$Build/g;
		s/COMPARISON_VECTOR/1\:$ComparisonVector/;
		s/SEP_HOLDER/$Delimiter/;
		s/PS_HOLDER/$Makeps/g;
		s/MODE_HOLDER/$RunMode/g;
		s/BED_HOLDER/$BEDMode/g;
		if (CAIRO eq "TRUE")
		{
			s/PNG_HOLDER/TRUE/g;
		}
		else
		{
			s/PNG_HOLDER/FALSE/g;
		}
		
		print R_CODE;
	}
	
	close TEMPLATE;
	close R_CODE;
}

########################################
# Subroutine for creating images using #
# the PerlMagick Module                #
########################################
if ( PERLMAGICK eq "TRUE" ) {
	sub PerlMagickConvertPStoPNG
	{
		
		my ($dataDir,$uploadName,$currentName,$psWidth,$psHeight,$Thumbnail) = @_;
		
		my $imageCMD = Image::Magick->new;
		my $image = $imageCMD->Read("${dataDir}/${uploadName}_${currentName}.ps");
		$image = $imageCMD->Rotate(degrees=>90);
		my $pngwidth = int($psWidth*72);
		my $pngheight = int($psHeight*72);
		$image = $imageCMD->Resize(geometry=>"${pngwidth}x${pngheight}");
		$image = $imageCMD->Write("${dataDir}/${uploadName}_${currentName}.png");
		
		if( $Thumbnail eq "TRUE" )
		{
			$image = $imageCMD->Resize(geometry=>"124x96");
			$image = $imageCMD->Write("${dataDir}/${uploadName}thumb_${currentName}.png");
		}
	}
}

########################################
# Subroutine for creating images using #
# the command-line version of          #
# Image Magick convert                 #
########################################
sub CLForkConvertPStoPNG
{
	my ($dataDir,$uploadName,$currentName,$psWidth,$psHeight,$Thumbnail) = @_;
	
	my $pngwidth = int($psWidth*72);
	my $pngheight = int($psHeight*72);
	
	system( "convert -rotate \"90\" +antialias -resize ${pngwidth}x${pngheight} ${dataDir}/${uploadName}_${currentName}.ps ${dataDir}/${uploadName}_${currentName}.png" );
	
	if ( $Thumbnail eq "TRUE" )
	{
		system( "convert -rotate \"90\" +antialias -resize 124x96 ${dataDir}/${uploadName}_${currentName}.ps ${dataDir}/${uploadName}thumb_${currentName}.png" );
	}
}

###########################################
# Subroutine for checking directory sizes #
###########################################
sub DirectoryCheck
{
	my ($uploadDir, $outputDir) = @_;
	
	if ( $uploadDir eq '/' || $uploadDir eq "/home" || $uploadDir eq "/home/" ) {
		error( "WHOA! uploadDir is a BAD choice! You could frag your whole drive." );
	}
	
	if ( $outputDir eq "/" || $outputDir eq "/home" || $uploadDir eq "/home/" ) {
		error( "WHOA! outputDir is a BAD choice! You could frag important data!!!" );
	}
	
	my $uploadDirSize = `du -c $uploadDir | grep total`;
	$uploadDirSize =~ s/^\s*(\d+)\s*total.*$/$1/e;
	my $outputDirSize = `du -c $outputDir | grep total`;
	$outputDirSize =~ s/^\s*(\d+)\s*total.*$/$1/e;
	
	if ($uploadDirSize > DIR_MAX || $outputDirSize > OUTPUT_MAX)
	{
		DirectoryClean ($uploadDir,$outputDir);
	}
}

############################################
# Subroutine for cleaning full directories #
############################################
sub DirectoryClean
{
	my ($uploadDirectory, $outputDirectory) = @_;
	
	if ( $uploadDir eq '/' || $uploadDir eq "/home" || $uploadDir eq "/home/" ) {
		error( "WHOA! uploadDir is a BAD choice! You could frag your whole drive." );
	}
	
	if ( $outputDir eq "/" || $outputDir eq "/home" || $uploadDir eq "/home/" ) {
		error( "WHOA! outputDir is a BAD choice! You could frag important data!!!" );
	}
	
	my $round = 1;
	my $dirClean = 0;
	
	opendir (DIR, $uploadDirectory);
	my @uploadFiles = readdir(DIR);
	shift (@uploadFiles); # remove "."
	shift (@uploadFiles); # remove ".."
	closedir (DIR);
	
	foreach $file (@uploadFiles)
	{ 
		$file =~ s/^([\w\s\-\_\.]+)$/$1/ || die "Can't match file $file for cleaning: $!\n";
		$file = $uploadDirectory . "/" . $file;
	}
	
	opendir (DIR, $outputDirectory);
	my @outputFiles = readdir(DIR);
	shift (@outputFiles); # remove "."
	shift (@outputFiles); # remove ".."
	closedir (DIR);
	
	foreach $file (@outputFiles)
	{
		$file =~ s/^([\w\s\-\_\.]+)$/$1/ || die "Can't match file $file for cleaning: $!\n";
		$file = $outputDirectory . "/" . $file;
	}
	
	# Combine arrays
	my @allFiles = (@uploadFiles, @outputFiles);
		
	# Loop through cleaning files, multiple times if necessary
	until ($dirClean == 1 || $round > 7)
	{
		# Get each file size
		foreach $file (@allFiles)
		{
			next if ($file eq " ");
			
			my $age = -M $file || error($cgi, "In attempting to clean upload directory could not stat $file");
			
			if ($round == 1 && $age >= 7)
			{
				unlink( $file );
				$file = " ";
			}
			
			elsif ($round == 2 && $age >= 3)
			{
				unlink( $file );
				$file = " ";
			}
			
			elsif ($round == 3 && $age >= 1)
			{
				unlink( $file );
				$file = " ";
			}
			
			elsif ($round == 4 && $age >= 0.50)
			{
				unlink( $file );
				$file = " ";
			}
			
			elsif ($round == 5 && $age >= 0.25)
			{
				unlink( $file );
				$file = " ";
			}
			
			elsif ($round == 6 && $age >= 0.04)
			{
				unlink( $file );
				$file = " ";
			}
			
			else
			{
				unlink( $file );
				$file = " ";
			}
		}
		
				
		my $uploadDirSize = `du -c $uploadDirectory | grep total`;
		$uploadDirSize =~ s/^\s*(\d+)\s*.*$/$1/e or die "Can't understand upload directory size $uploadDirSize: $!\n";
		
		my $outputDirSize = `du -c $outputDirectory | grep total`;
		$outputDirSize =~ s/^\s*(\d+)\s*.*$/$1/e or die "Can't understand output directory size $outputDirSize: $!\n";
		
		if ($uploadDirSize < DIR_MAX && $outputDirSize < DIR_MAX)
		{
			$dirClean = 1;
		}
		
		++$round;
	}
	
	if ($dirClean == 0)
	{
		error($cgi, "Upload or output directory full and script was unable to clean it. Please contact the webmaster.")
		;
	}
}

#####################################################
# Subroutine for correctly sorting chromosome order #
#####################################################
sub SortChromosomeList
{
	#############################################
	# Sort the chromosomes so order makes sense #
	#############################################
	my $mitoChar = "NULL";
	
	my @chromsToSort = @_;
	
	foreach $sorting (@chromsToSort)
	{
		$sorting =~ s/XY/50/g;
		$sorting =~ s/X/23/g;
		$sorting =~ s/Y/24/g;
		
		if ( $sorting =~ /MITO/g ) {
			$sorting =~ s/MITO/25/g;
			$mitoChar = "MITO";
		}
		
		elsif ( $sorting =~ /Mito/g ) {
			$sorting =~ s/Mito/25/g;
			$mitoChar = "Mito";
		}
		
		elsif ( $sorting =~ /MT/g ) {
			$sorting =~ s/MT/25/g;
			$mitoChar = "MT";
		}
		
		elsif ( $sorting =~ /M/g ) {
			$sorting =~ s/M/25/g;
			$mitoChar = "M";
		}
	}
	
	@chromsToSort = sort {$a <=> $b} @chromsToSort;
	
	foreach $sorting (@chromsToSort)
	{
		$sorting =~ s/23/X/g;
		$sorting =~ s/24/Y/g;
		$sorting =~ s/25/${mitoChar}/g;
	}
	
	return( @chromsToSort );
}
