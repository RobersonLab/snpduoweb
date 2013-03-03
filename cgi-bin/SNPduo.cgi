#!/usr/bin/perl -wT

########################################
#
#	SNPduo.cgi
#	Author: Eli Roberson
#	Created: September 04, 2007 
#	Last Edit: November 07, 2008 - ER
#
########################################
#  Copyright (c)  2007-2008 Elisha Roberson and Jonathan Pevsner.
#                 All Rights Reserved.
#
#  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS "AS IS" AND ANY 
#  EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
#  IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR 
#  PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNERS BE
#  LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
#  CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
#  SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
#  INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
#  CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
#  ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
#  POSSIBILITY OF SUCH DAMAGE. THIS SOFTWARE IS FREE FOR PERSONAL OR ACADEMIC
#  USE. THE SOFTWARE MAY NOT BE USED COMMERCIALLY WITHOUT THE EXPRESS, WRITTEN
#  PERMISSION OF THE COPYRIGHT HOLDERS. ALL ACTIONS OR PROCEEDINGS RELATED TO 
#  THIS SOFTWARE SHALL BE TRIED EXCLUSIVELY IN THE STATE AND FEDERAL COURTS 
#  LOCATED IN THE COUNTY OF BALTIMORE CITY, MARYLAND. USE OF THIS SOFTWARE
#  IMPLIES ACCEPTANCE OF THIS CONTRACT.
########################################
use constant RENAME => "TRUE";
use constant PERLMAGICK => "TRUE";

use CGI;
if (PERLMAGICK eq "TRUE") {
	use Image::Magick; #####PERLMAGICK#####
}

########################################
# Declare some constants
########################################
use constant FILE_MAX => 1_024 * 1_024 * 200; #200Mb upload limit
use constant DIR_MAX => 1024 * 1024; # Max 1Gb upload directory. Second number is number of megabytes allowed
use constant OUTPUT_MAX => 1024 * 1024 * 3; #Max 3Gb of output stored in output directory
 
$CGI::POST_MAX = FILE_MAX;

########################################
# Set some variables to find where files are.
# Never leave trailing slashes.
# Make all file paths absolute.
########################################

my $datadir = "/home/SNP/uploads/SNPduo"; # Directory data files are uploaded to
my $outputdir = "/home/SNP/html/uploads/SNPduo"; # Directory output is transferred to for web display
my $webpage = "http://10.8.32.151"; # Domain name of the server. Assumes output is in $domain/uploads/SNPduo (uploads in document root)
my $outputFolder = "uploads/SNPduo";
my $codedir = "/home/SNP/cgi-bin/SNPduo"; # Directory where templates are stored
my $compileddir = "/home/SNP/cgi-bin/SNPduo"; # Directoy where compiled C Code is stored, along with the genomic feature files
my $pathtoR = "/usr/bin/R"; # Directory where R executable is located

# WARNING!!!!!!!!!!!!!!
# DO NOT CHANGE BELOW THE LINE UNLESS YOU ARE MODIFYING CODE
# If you modify the code yourself you are responsible for debugging it.

#######################################################################################################################################
#######################################################################################################################################
my $current_revision = "1.00 Development";
my $starttimestamp = timestamp();

my $cgi = new CGI;
my $Rcomparisons = 0;
my $comparisonVector = 0;
my $comparisoncounter = 0;
my $ind2 = " ";
my $chrom;
my $chromList;

########################################
# Save values from post to variables
# Give errors if not everything is specified
########################################

my $runmode = $cgi->param("runmode") or error($cgi, "Runmode not received");
my $file = $cgi->param("file") or error($cgi, "No file selected for upload");
my $delimiter = $cgi->param("delimiter") or error($cgi, "No delimiter selected");
my $platform = $cgi->param("platform") or error($cgi, "No platform selected");
my $ind1 = $cgi->param("ind1") or error($cgi, "Individual 1 not specified");
if($runmode ne "Batch" && $runmode ne "Tabulate") {$ind2 = $cgi->param("ind2") or error($cgi, "Individual 2 not specified. Please specify individual 2 or use batch mode");}
my @chromParam = $cgi->param("chrom") or error($cgi, "No chromosome specified");
my $pswidth = $cgi->param("pswidth") or error($cgi, "No page width specified");
my $psheight = $cgi->param("psheight") or error($cgi, "No page height specified");
my $genomebuild = $cgi->param("genomebuild") or error($cgi, "Genome build information not received");
my $makeps = $cgi->param("makeps") or error($cgi, "Postscript option not received");
my $makepng = $cgi->param("makepng") or error($cgi, "PNG option not received");
my $segmentation = $cgi->param("segmentation") or error($cgi, "Segmentation optino not received");

########################################
# Check for error conditions
########################################

########################################
# Untaint variables
########################################

# Path
$ENV{'PATH'} =~ /(.*)/;
$ENV{'PATH'} = $1;

# Filename
if ($file =~ /^.*[\/\\]([\w\@\.\-]*)$/)
{
	$file = $1;
}
elsif ($file =~ /^([\w\@\.\-]*)$/)
{
	$file = $1;
}
else
{
	error($cgi, "The filename \"$file\" contains illegal characters. Rename using only alphanumeric characters, \"_\", \"-\", \".\", and \"@\".");
}

# Delimiter
if ($delimiter =~ /^(\w*)$/)
{
	$delimiter = $1
}
else
{
	error($cgi, "The delimiter field contains illegal characters. If this message persists, please contact the webmaster");
}

# Platform
if ($platform =~ /^([\w]*)$/)
{
	$platform = $1;
}
else
{
	error ($cgi, "Platform field returned illegal characters. If this message persists, please contact the webmaster");
}

# Chromosome
if (scalar(@chromParam) < 1) {error($cgi, "No chromosome specified");}

foreach $tmpChrom (@chromParam)
{
	if ($tmpChrom =~ /^(\w*)$/)
	{
		$tmpChrom = $1;
		if ($platform eq "HapMap" & $tmpChrom eq "GenomeByChromosome")
		{
			error ($cgi, "HapMap samples not allowed in \"Genome - By Chromosome\" mode");
		}
	}
	else
	{
		error($cgi, "The chromosome field returned $tmpChrom, which contains illegal characters. If this message persists, please contact the webmaster");
	}
}

# Width
if ($pswidth =~ /^([\d\.]*)$/)
{
	$pswidth = $1;
}
else
{
	error ($cgi, "The width field contains illegal characters. Please use only numeric characters in this field");
}

# Height
if ($psheight =~ /^([\d\.]*)$/)
{
	$psheight = $1;
}
else
{
	error ($cgi, "The height field contains illegal characters. Please use only numeric characters in this field");
}

# Genome build
if ($genomebuild =~ /^([\w\.\-]*)$/)
{
	$genomebuild = $1;
}
else
{
	error($cgi, "The genome build field returned illegal characters. If this message persists, please contact the webmaster");
}

# PNG
if ($makepng =~ /^(\w*)$/)
{
	$makepng = $1;
}
else
{
	error($cgi, "The Make PNG field returned illegal characters. If this message persists, please contact the webmaster");
}

#Postscript
if ($makeps =~ /^(\w*)$/)
{
	$makeps = $1;
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
if ($runmode ne "Batch" && $runmode ne "Tabulate")
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
elsif ($runmode eq  "Batch" || $runmode eq "Tabulate")
{
	# Individual 1
	$ind1 =~ s/^,//;
	
	if ($ind1 =~ /^([\d,\-\:]*)$/)
	{
		$ind1 = $1;
	}
	else
	{
		error ($cgi, "Input of multiple columns failed. This field should contain numbers separated by commas. Whitespace is allowed. Please try again");
	}
}

########################################
# Prep individuals for R Code vectors
########################################

if ($runmode ne "Batch" && $runmode ne "Tabulate")
{
	if ($platform eq "HapMap")
	{
		$ind1 -= 9;
		$ind2 -= 9;
	}
	$Rcomparisons = "c\($ind1, $ind2\)";
	$comparisonVector = 1;
}
elsif ($runmode eq "Batch" || $runmode eq "Tabulate")
{	
	my @tmpComparisons = split(/,/, $ind1);
	my $NumberOfComparisons = 0;
	
	$Rcomparisons = "c\(";
	
	while (<@tmpComparisons>)
	{
		my $col = $_;
		
		if ($col =~ /[\:\-]/)
		{
			local $" = ',';
			my ($startCol, $endCol) = split /[\:\-]/, $col;
			if ($platform eq "HapMap")
			{
				$startCol -= 9;
				$endCol -= 9;
			}
			my @colArray = $startCol .. $endCol;
			$Rcomparisons .= "@colArray,";
			$NumberOfComparisons += scalar(@colArray);
		}
		else
		{
			if ($platform eq "HapMap")
			{
				$col -= 9;
			}
			$Rcomparisons .= "$col,";
			++$NumberOfComparisons;
		}
	}
	
	$Rcomparisons =~ s/,$//;
	$Rcomparisons .= "\)";
	
	$comparisonVector = ($NumberOfComparisons * ($NumberOfComparisons - 1)) / 2;
}

########################################
# Prep chromosome list
########################################
$chromList = "c(";
while (<@chromParam>)
{
	my $tmpValue = $_;
	chomp ($tmpValue);
	$chromList .= "\"$tmpValue\",";
}

$chromList =~ s/,$//;
$chromList .= ")";

if ($chromList =~ /GenomeByChromosome/)
{
	$chrom = "GenomeByChromosome";
	$chromList = NULL;
}
elsif ($chromList =~ /Genome/)
{
	$chrom = "Genome";
	$chromList = NULL;
}
elsif (scalar(@chromParam) > 1)
{
	$chrom = "GenomeByChromosome";
}
else
{
	$chrom = $chromParam[0];
}

########################################
# Adjust filename
########################################

# Filename must start with a number or letter, not other characters or whitespace
if ($file !~ m/^\w.*$/)
{
    error($cgi, "Filename  \"${file}\" doesn't begin with number or letter"); 
}

##
# Get rid of whitespace in filename
##
my $upload = $file;
$upload =~ s/\s/_/g;

########################################
# Check column separator
########################################
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

########################################
# Check for upload directory size
# Clean if necessary
########################################
DirectoryCheck ($datadir, $outputdir);

########################################
# Give a server side filename to the upload
########################################

##
# Test in a loop whether a file with the same name as the upload exists on the server
# If it does, add a digit to the end of the filename and repeat the test.
# Auto increment the digit until the filename is unique
##
until (! -e "${datadir}/${upload}")
{
	$upload =~ s/^(\d*)(\S+)$/($1||0) + 1 . $2/e;
}

########################################
# Don't call upload until now so errors
# happen before the file starts to upload
########################################
my $uploadStart = time();
my $fh = $cgi->upload("file") or error($cgi, "File upload did not begin properly");

########################################
# Start platform adjustments
########################################
my $rowcounts = -1; # Set the row count to -1 so that headers are ignored

########################################
# Illumina
########################################
if ($platform eq "Illumina")
{
	##
	# Upload the file first
	##
    open (LOCAL, ">${datadir}/${upload}") or error ($cgi,  "Cannot make file for upload:$!"); 
	
    ##
    # Necessary for windows servers. Greater portability by specifying this
    ##
    binmode LOCAL;
    binmode $fh;

    IlluminaFH: while (<$fh>)
    {		
	    ##
		# Skip commented lines
		##
		if (/^\s*\#/)
		{
			next IlluminaFH;
		}
		if (/^\s*$/)
		{
			next IlluminaFH;
		}
		
		##
		# R doesn't like # so get rid of it elsewhere
		##
		s/\#//g;
		
		##    
		# Make the header something the script will find. Substitute Chr field for Chromosome
		##
		s/^Chr${delimiter}/Chromosome${delimiter}/g;
		s/${delimiter}Chr${delimiter}/${delimiter}Chromosome${delimiter}/g;
		s/${delimiter}Chr\n/${delimiter}Chromosome\n/g;
		
		##
		# Adjust the name of the position column
		##
		s/^Position${delimiter}/Physical.Position${delimiter}/g;
		s/${delimiter}Position${delimiter}/${delimiter}Physical.Position${delimiter}/g;
		s/${delimiter}Position\n/${delimiter}Physical.Position\n/g;
		
		##
		# Get read or .GType suffix on genotype columns
		##
		s/\.GType//g;
		
		
		print LOCAL $_; # Now write the file
		
		++$rowcounts; # Autoincrement the row count
    }

    close LOCAL; # Close things nicely
    
########################################
    WriteRTemplate ($codedir,$datadir,"IlluminaTemplate",$upload,$chrom,$chromList,$Rcomparisons,$compileddir,$rowcounts,$pswidth,$psheight,$genomebuild, $comparisonVector,$delimiter,$makeps, $runmode,$segmentation);
}

elsif ($platform eq "Affymetrix4")
{	
	########################################
	# Affymetrix
	########################################
	##
	# Upload the file, substituting in No Calls where necessary"
	##
    open (LOCAL, ">${datadir}/${upload}") or error ($cgi,  "Cannot make file for upload:$!"); 
	
    ##
    # Necessary for windows servers. Greater portability by specifying this
    ##
    binmode LOCAL;
    binmode $fh;

    AffyFH: while (<$fh>)
    {	
	    ##
	    # Skip commented lines
	    ##
		if (/^\s*\#/)
		{
			next AffyFH;
		}
		if (/^\s*$/)
		{
			next AffyFH;
		}
		
		##
		# R doesn't like # so get rid of it elsewhere
		##
		s/\#//g;
		
		##    
		# New CNAT No Calls are blanks. Substitute so the program sees them
		##
		s/${delimiter}${delimiter}/${delimiter}NoCall${delimiter}/g;
		s/${delimiter}\n/${delimiter}NoCall\n/g;
		
		##
		# Remove annoying suffixes
		##
		s/_Call//g;
		s/\.brlmm//g;
		s/\.loh//g;
		
		print LOCAL $_; # Print the adjusted file
		++$rowcounts; # Autoincrement of the row count
    }

    close LOCAL; # Close things nicely
    
#######################################
	WriteRTemplate ($codedir,$datadir,"AffyCNAT4Template",$upload,$chrom,$chromList,$Rcomparisons,$compileddir,$rowcounts,$pswidth,$psheight,$genomebuild, $comparisonVector,$delimiter,$makeps, $runmode,$segmentation);
	
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
	
	########################################
	# HapMap
	########################################
	open LOCAL, ">${datadir}/${upload}" or error ($cgi,  "Cannot make file for upload:$!"); 
	
    ##
    # Necessary for windows servers. Greater portability by specifying this
    ##
    binmode LOCAL;
    binmode $fh;

    HapMapFH: while (<$fh>)
    {
		##
	    # Skip commented lines
	    ##
		if (/^\s*\#/)
		{
			next HapMapFH;
		}
		if (/^\s*$/)
		{
			next HapMapFH;
		}
	    
		##
		# R doesn't like # so get rid of it elsewhere
		##
		s/\#//g;
	    
		##
		# Split data up for printing
		##
		my ($rs, $allele, $chromosome, $position, $strand, $build, $center, $prot, $assay, $panel, $QC, @genotypes) = split(/$HapMapDelimiter/);
	    
		##
		# Before printing anything, check alleles to see how many there are.
		# If there are more than two, skip it.
		##
		my @alleletest = split /\//, $allele;
	    
		if(scalar(@alleletest) > 2)
		{
			next HapMapFH;
		}
	    
		##
		# Change chr and pos to the same as others
		##
		$chromosome =~ s/chrom/Chromosome/g;
		$chromosome =~ s/chr//g;
		$position =~ s/pos/Physical.Position/g;
	    
		##
		# Print the chromosome and position
		##
		print LOCAL "${chromosome}${HapMapDelimiter}${position}";
	    
		if (scalar(@alleletest) < 2)
		{
			foreach $name (@genotypes)
			{
				print LOCAL "${HapMapDelimiter}${name}";
			}
			next HapMapFH;
		}
		
		##
		# Change genotypes
		##
		my ($Aallele, $Ballele) = split /\//, $allele; # Split the two alleles specified into two different scalars
		
		##
		# Run a loop that will substitute the genotypes
		##
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
	
	close LOCAL; # Close things nicely

	##############################
	WriteRTemplate ($codedir,$datadir,"HapMapTemplate",$upload,$chrom,$chromList,$Rcomparisons,$compileddir,$rowcounts,$pswidth,$psheight,$genomebuild, $comparisonVector,$delimiter,$makeps, $runmode,$segmentation);

}

elsif ($platform eq "Custom")
{
	########################################
	# Custom
	########################################
	##
	# Upload the file first
	##
	open (LOCAL, ">${datadir}/${upload}") or error ($cgi,  "Cannot make file for upload:$!"); 
	
	##
	# Necessary for windows servers. Greater portability by specifying this
	##
	binmode LOCAL;
	binmode $fh;

	CustomFH: while (<$fh>)
	{		
		##
		# Skip commented lines
		##
		if (/^\s*\#/)
		{
			next CustomFH;
		}
		if (/^\s*$/)
		{
			next CustomFH;
		}
		
		##
		# R doesn't like # so get rid of it elsewhere
		##
		s/\#//g;
				
		print LOCAL $_; # Now write the file
		
		++$rowcounts; # Autoincrement the row count
	}

	close LOCAL; # Close things nicely
	
########################################
	WriteRTemplate ($codedir,$datadir,"CustomTemplate",$upload,$chrom,$chromList,$Rcomparisons,$compileddir,$rowcounts,$pswidth,$psheight,$genomebuild, $comparisonVector,$delimiter,$makeps, $runmode,$segmentation); 
}

my $uploadEnd = time();
my $uploadTime = $uploadEnd - $uploadStart;

########################################
# Run R computation
########################################
my $ibsStart = time();
system ("cd ${datadir}; $pathtoR --vanilla <${upload}.R 1>${datadir}/${upload}.R.screendump 2>${datadir}/${upload}.R.debug"); # Make call to R to perform SNPduo and make plots
my $ibsEnd = time();
my $ibsTime = $ibsEnd - $ibsStart;

########################################
# See if R finished correctly
# Throw an error otherwise
########################################

my $DebugSize = -s "${datadir}/${upload}.R.debug";

if ($DebugSize > 0)
{	
	open RERROR, "${datadir}/${upload}.R.debug" or error($cgi, "An R error occurred, but I can't read the debugging file ${upload}.R.debug:$!");
		
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
	unlink("${datadir}/${upload}.R.debug");
	unlink("${datadir}/${upload}.R.screendump");
}
 
########################################
# Make an bed file for display on UCSC genome browser
########################################
if ($runmode ne "Tabulate" && $segmentation eq "TRUE")
{
	open BEDFILE, ">${datadir}/${upload}.bed" or error($cgi,  "Cannot create UCSC browser file: $!");
	my $bedchrom = "chr" . $chrom; # Specify chromosome
	
	if ($bedchrom =~ /Genome/)
	{
		$bedchrom = "chr1";
	}
	
	print BEDFILE "browser position $bedchrom\n";
	
	for ($comparisoncounter = 1; $comparisoncounter <= $comparisonVector; ++$comparisoncounter)
	{
		my $bedfileInd1 = "";
		my $bedfileInd2 = "";
		my $bedfileChr = "";
		my $bedfileRow = "Ind1";
		my $writeTrack = 1;
		
		my $currentComparison = $comparisoncounter;
		my $bedsummaryfile = $upload;
		my $bedchromprev = 0;
		$bedsummaryfile .= "_${currentComparison}.bedsummary.txt"; # Specify the filename for the overall summary data
		open FORBED, "${datadir}/${bedsummaryfile}" or error($cgi,  "Cannot find $bedsummaryfile to generate bed file: $!"); 
		 
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
					#$rgb = "0,255,0"; # Lime
					$rgb = "77,175,74";
				}
				elsif ($type eq "IBS1")
				{
					#$rgb = "99,184,255"; # Steelblue1
					$rgb = "55,126,184";
				}
				elsif ($type eq "IBS0")
				{
					#$rgb = "255,0,0"; # Red
					$rgb = "228,26,28";
				}
				elsif ($type eq "Aberration")
				{
					#$rgb = "191,62,255"; # Dark orchid
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
		unlink ("${datadir}/${bedsummaryfile}");
	}
	close (BEDFILE);
}
	
########################################
#
# The next section applies only to the
# analysis of individual chromosomes.
#
########################################
my @genos = 0;
my @sumind1 = 0;
my @sumind2 = 0;
my @ibs = 0;
my @count = 0;

if ($chrom ne "GenomeByChromosome" && $runmode ne "Tabulate")
{
	for ($comparisoncounter = 1; $comparisoncounter <= $comparisonVector; ++$comparisoncounter)
	{		
		my $currentComparison = $comparisoncounter;
		
		########################################
		#
		# This section section applies only to the
		# analysis of individual chromosomes or
		# whole genome on one plot
		#
		########################################
				
		if ($makepng eq "TRUE" && $makeps eq "TRUE")
		{
			if (PERLMAGICK eq "TRUE")
			{
				PerlMagickConvertPStoPNG($datadir,$upload,$currentComparison,$pswidth,$psheight,"FALSE"); #####PERLMAGICK#####
			}
			else
			{
				CLFORKConvertPStoPNG();#####NOPERLMAGICK#####
#				system ("convert ${datadir}/${upload}.ps -rotate \"90\" ${datadir}/${upload}.png"); #####NOPERLMAGICK##### # Rotate postscript 90 degrees and convert to a png
			}
			
			if (RENAME eq "TRUE")
			{
				rename ("${datadir}/${upload}_${currentComparison}.png", "${outputdir}/${upload}_${currentComparison}.png"); #####RENAME#####
			}
		}
			
		########################################
		# Move files to the proper directories to display on results page
		########################################
		
		##
		# Move output files to webaccessible directory
		##
#		if ($makeps eq "TRUE" && $makepng eq "TRUE")
#		{
#			system("mv ${datadir}/${upload}.ps $outputdir/${upload}.ps;mv ${datadir}/${upload}.png $outputdir/${upload}.png;mv ${datadir}/${upload}.summary.txt $outputdir/$upload.summary.txt");
#		} #####NORENAME#####
#		if ($makeps eq "TRUE" && $makepng eq"FALSE")
#		{
#			system("mv ${datadir}/${upload}.ps $outputdir/${upload}.ps;mv ${datadir}/${upload}.summary.txt $outputdir/$upload.summary.txt");
#		} #####NORENAME#####
#		if ($makeps eq "FALSE")
#		{
#			system("mv ${datadir}/${upload}.summary.txt $outputdir/$upload.summary.txt");
#		} #####NORENAME#####
	 	if ($makeps eq "TRUE")
	 	{
		 	rename("${datadir}/${upload}_${currentComparison}.ps","${outputdir}/${upload}_${currentComparison}.ps");
		} #####RENAME#####
		
		if (RENAME eq "TRUE")
		{
			rename ("${datadir}/${upload}_${currentComparison}.summary.txt", "${outputdir}/${upload}_${currentComparison}.summary.txt"); #####RENAME#####
			
		}
		
	 	if ($makeps eq "TRUE" && $makepng eq "TRUE")
	 	{
			system ("cd $outputdir; zip -q ${upload}_${currentComparison}.zip ${upload}_${currentComparison}.ps ${upload}_${currentComparison}.png ${upload}.summary_${currentComparison}.txt");
		}
		elsif ($makeps eq "TRUE" && $makepng eq "FALSE")
		{
			system ("cd $outputdir; zip -q ${upload}_${currentComparison}.zip ${upload}_${currentComparison}.ps ${upload}_${currentComparison}.summary.txt");
		}
		else
		{
			system ("cd $outputdir; zip -q ${upload}_${currentComparison}.zip ${upload}_${currentComparison}.summary.txt");
		}
		
		########################################
		# Make a table for the results page
		########################################
		##
		# Pull in summary data
		##
		open GENO, "${datadir}/${upload}_${currentComparison}.gensum" or error ($cgi,  "Cannot open genotype summary:$!"); 
#		my @genos = 0;
#		my @sumind1 = 0;
#		my @sumind2 = 0;
		
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
		
		unlink ("${datadir}/${upload}_${currentComparison}.gensum");
		
		open IBS, "${datadir}/${upload}_${currentComparison}.ibssum" or error ($cgi,  "Cannot open IBS summary:$!"); 
#		my @ibs = 0;
#		my @count = 0;
		
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
		unlink ("${datadir}/${upload}_${currentComparison}.ibssum");
		
	}
	
	# Moving BED
	if (RENAME eq "TRUE")
	{
		rename ("${datadir}/${upload}.bed", "${outputdir}/${upload}.bed");
	}
	else
	{
		system("mv ${datadir}/${upload}.bed $outputdir/$upload.bed");
	}
	
	my $pagegenerated = timestamp();
	
	print $cgi->header();
	
# print <<HTMLEND;
# <html>
# <head>
# <title>SNPduo Results for $file</title>

# <style type="text/css">
# table {margin-left:auto;margin-right:auto}
# tr {text-align:center; vertical-align: middle}
# th {text-align:center;}
# body{font-family:verdana,arial,helvetica,sans-serif}
# </style>
# </head>
# <body>

# <p>
# File uploaded: $file<br>
# SNPduo Version: $current_revision<br>
# Analysis started at $starttimestamp<br>
# Page generated at $pagegenerated
# </p>
# HTMLEND

	print("<html>\n<head>\n<title>SNPduo Results for $file</title>\n\n<style type=\"text/css\">\ntable {margin-left:auto;margin-right:auto}\ntr {text-align: center; vertical-align: middle}\nth {text-align: center}\nbody {font-family: verdana, arial, helvetica, sans-serif}\n</style>\n</head>\n<body>\n\n<p>\nFile uploaded: $file\n<br>SNPduo Version: $current_revision\n<br>Analysis started at $starttimestamp\n<br>Page generated at $pagegenerated\n<br>File upload: $uploadTime seconds\n<br>IBS calculation: $ibsTime seconds</p>");
	
	if ($segmentation eq "TRUE")
	{
		print ("<p>\n");
		print ("Click <a href=\"${webpage}/${outputFolder}/${upload}.bed\">here (.bed)</a> to download combined BED file of IBS blocks.\n");
		print ("</p>\n");
	}
	
	for ($comparisoncounter = 1; $comparisoncounter <= $comparisonVector; ++$comparisoncounter)
	{		
		my $currentComparison = $comparisoncounter;
		########################################
		# Make the HTML output
		########################################
		
		print ("<hr>\n\n");

		########################################
		# Standard output - Genome or Chromosome
		########################################
		if ($makepng eq "TRUE" && $makeps eq "TRUE")
		{
			print("<center><img src=\"$webpage/${outputFolder}/${upload}_${currentComparison}.png\" alt=\"PNG of SNPduo output\"></center>\n<br>");
			print("<p>Click <a href=\"${webpage}/${outputFolder}/${upload}_${currentComparison}.png\">here (.png)</a> to download the displayed image.<br>\n");
		
		}
		else
		{
			print("<p>\n");
		}
		
		if ($makeps eq "TRUE")
		{
			print ("Click <a href=\"${webpage}/${outputFolder}/${upload}_${currentComparison}.ps\">here (.ps)</a> to download the postscript file.<br>\n");
		}
		
		print ("Click <a href=\"${webpage}/${outputFolder}/${upload}_${currentComparison}.summary.txt\">here (.txt)</a> to download the text summary.<br>\n");
		print ("Or click <a href=\"${webpage}/${outputFolder}/${upload}_${currentComparison}.zip\">here (.zip)</a> to download a zip file containing the summary file and any generated images.\n</p>\n\n");
		
		print ("<table align=\"center\" border=\"1\">\n\n");
		
		my $loopcount = 1;
		
		#for ($loopcount = 1; $loopcount < 6; ++$loopcount) {
		for ($loopcount = (1+(5*($currentComparison-1))); $loopcount < (6+(5*($currentComparison-1))); ++$loopcount)
		{
			print ("<tr>\n<td>$genos[$loopcount]</td>\n");
			print ("<td>$sumind1[$loopcount]</td>\n");
			print ("<td>$sumind2[$loopcount]</td>\n</tr>\n\n");
		}
		
		print ("</table>\n\n<br>\n\n");
		
		print ("<table align=\"center\" border=\"1\" cellpadding=\"3\">\n");
		print ("<tr>\n<th>Identity by State</th>\n<th>Counts</th>\n</tr>\n\n");
		
		for ($loopcount = (2+(4*($currentComparison-1))); $loopcount < (5+(4*($currentComparison-1))); ++$loopcount)
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
	########################################
	# Grab the list of chromsomes analyzed 
	# processing of the appropriate files
	########################################
	open BATCHLIST, "${datadir}/${upload}_1.chromlist" or error ($cgi,  "Can't open list of chromosomes processed:$!"); 
	
	our @batchchroms = <BATCHLIST>;
	chomp (@batchchroms);
	
	close BATCHLIST;

	########################################
	# Sort the chromosomes so order makes sense
	########################################
	foreach $sorting (@batchchroms)
	{
		$sorting =~ s/XY/24/g;
		$sorting =~ s/X/23/g;
		$sorting =~ s/Y/25/g;
		$sorting =~ s/M/26/g;
	}
	
	@batchchroms = sort {$a <=> $b} @batchchroms;
	
	foreach $sorting (@batchchroms)
	{
		$sorting =~ s/24/XY/g;
		$sorting =~ s/23/X/g;
		$sorting =~ s/25/Y/g;
		$sorting =~ s/26/M/g;
	}
	
	for ($comparisoncounter = 1; $comparisoncounter <= $comparisonVector; ++$comparisoncounter)
	{		
		my $currentComparison = $comparisoncounter;	
		########################################
		#
		# The next section applies only to the
		# analysis of the genome by chromosome.
		#
		########################################
		
		unlink ("${datadir}/${upload}_${currentComparison}.chromlist");
		
		########################################
		# Make some pngs
		# Move to web directory
		# Then add to zip file
		# Remove files
		########################################
		my $pngwidth = 0;#####PERLMAGICK#####
		my $pngheight = 0;#####PERLMAGICK#####
		
		if ($makepng eq "TRUE" && $makeps eq "TRUE")
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
				
				PerlMagickConvertPStoPNG ($datadir,$tmpchrom,$currentComparison,$pswidth,$psheight,"TRUE"); #####PERLMAGICK#####
#				CLForkConvertPStoPNG ( ... ); #####NOPERLMAGICK#####
#					system("convert $datadir/$tmpchrom.ps -rotate \"90\" $datadir/$tmpchrom.png; convert -resize 124x96 $datadir/$tmpchrom.png $datadir/${tmpchrom}thumb.png"); #####NOPERLMAGICK#####
				
				##
				# Move output files to webaccessible directory
				##
#				system("mv $datadir/$tmpchrom.ps $outputdir/$tmpchrom.ps; mv $datadir/$tmpchrom.png $outputdir/$tmpchrom.png; mv $datadir/${tmpchrom}thumb.png $outputdir/${tmpchrom}thumb.png");######NORENAME#####
				
		 		rename ("${datadir}/${tmpchrom}_${currentComparison}.ps","${outputdir}/${tmpchrom}_${currentComparison}.ps"); #####RENAME#####
		 		rename ("${datadir}/${tmpchrom}_${currentComparison}.png","${outputdir}/${tmpchrom}_${currentComparison}.png"); #####RENAME#####
		 		rename ("${datadir}/${tmpchrom}thumb_${currentComparison}.png","${outputdir}/${tmpchrom}thumb_${currentComparison}.png"); #####RENAME#####
			}
		} 
		
		########################################
		# Move the summary
		# Add to the zip file
		########################################
#		system ("mv ${datadir}/${upload}.summary.txt $outputdir/$upload.summary.txt; cd $outputdir; zip -q ${upload}.zip ${upload}.summary.txt");######NORENAME#####
	 	rename ("${datadir}/${upload}_${currentComparison}.summary.txt","${outputdir}/${upload}_${currentComparison}.summary.txt"); #####RENAME#####
	 	
	 	if ($makepng eq "TRUE" && $makeps eq "TRUE")
	 	{
		 	system ("cd ${outputdir}; zip -q ${upload}_${currentComparison}.zip ${upload}_${currentComparison}.summary.txt ${upload}*_${currentComparison}.ps ${upload}*_${currentComparison}.png");
	 	}
	 	elsif ($makepng eq "FALSE" && $makeps eq "TRUE")
	 	{
		 	system ("cd ${outputdir}; zip -q ${upload}_${currentComparison}.zip ${upload}_${currentComparison}.summary.txt  ${upload}*_${currentComparison}.ps");
	 	}
	 	else
	 	{
		 	system ("cd ${outputdir}; zip -q ${upload}_${currentComparison}.zip ${upload}_${currentComparison}.summary.txt  ${upload}*_${currentComparison}.ps");
	 	}
	
		
		########################################
		# Pull in summary data
		########################################
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
			
			open GENO, "${datadir}/${tmpchrom}_${currentComparison}.gensum" or error ($cgi,  "Cannot open genotype summary ${tmpchrom}_${currentComparison}.gensum:$!"); 
					
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
			unlink ("${datadir}/${tmpchrom}_${currentComparison}.gensum");
			
			open IBS, "${datadir}/${tmpchrom}_${currentComparison}.ibssum" or error ($cgi,  "Cannot open IBS summary ${tmpchrom}_${currentComparison}.ibssum:$!"); 
					
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
			unlink ("${datadir}/${tmpchrom}_${currentComparison}.ibssum");
		}
	}
	
	# Moving BED
	if (RENAME eq "TRUE")
	{
		rename ("${datadir}/${upload}.bed", "${outputdir}/${upload}.bed");
	}
	else
	{
		system("mv ${datadir}/${upload}.bed $outputdir/$upload.bed");
	}
	
	########################################
	# Make the HTML output
	########################################
		
	########################################
	# Output for GenomeByChromosome
	########################################
	my $pagegenerated = timestamp();
	
	print $cgi->header();

	print "<html>\n<head>\n<title>SNPduo Results for $file</title>\n<style type=\"text/css\">\ntable {margin-left: auto; margin-right: auto}\ntr {text-align: center; vertical-align: middle}\nth {text-align: center}\nbody {font-family: verdana, arial, helvetica, sans-serif}\n</style></head>\n<body>\n\n<p>\nFile uploaded: $file\n<br>SNPduo Version: $current_revision\n<br>Analysis started at $starttimestamp\n<br>Page generated at $pagegenerated\n<br>\nFile upload: $uploadTime seconds\n<br>IBS calculation: $ibsTime seconds</p>";
	
	if ($segmentation eq "TRUE")
	{
		print ("<p>\n");
		print ("Click <a href=\"${webpage}/${outputFolder}/${upload}.bed\">here (.bed)</a> to download combined BED file of IBS blocks.\n");
		print ("</p>\n");
	}
	
	my $masterOffset = 0;
	
	for ($comparisoncounter = 1; $comparisoncounter <= $comparisonVector; ++$comparisoncounter)
	{		
		print ("<hr>\n\n");
		
		my $currentComparison = $comparisoncounter;
		my $chromCounter = 0;		
		my $rowcounter = 1;
		
		##
		# Print a table showing reduced images for this format
		##
		if ($makepng eq "TRUE")
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
		
		##
		# Show the download links
		##
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
	# Grab the list of chromsomes analyzed 
	# processing of the appropriate files
	########################################
	open BATCHLIST, "${datadir}/${upload}.chromlist" or error ($cgi,  "Can't open list of chromosomes processed:$!"); 
	
	my @batchchroms = <BATCHLIST>;
	chomp (@batchchroms);
	
	close BATCHLIST;
	unlink ("${datadir}/${upload}.chromlist");

	########################################
	# Sort the chromosomes so order makes sense
	########################################
	foreach $sorting (@batchchroms)
	{
		$sorting =~ s/XY/24/g;
		$sorting =~ s/X/23/g;
		$sorting =~ s/Y/25/g;
		$sorting =~ s/M/26/g;
	}
	
	@batchchroms = sort {$a <=> $b} @batchchroms;
	
	foreach $sorting (@batchchroms)
	{
		$sorting =~ s/24/XY/g;
		$sorting =~ s/23/X/g;
		$sorting =~ s/25/Y/g;
		$sorting =~ s/26/M/g;
	}
	
	########################################
	# Move the ibs and genotype summary files
	########################################
	if (RENAME eq "TRUE")
	{
		rename ("${datadir}/${upload}.SummaryIBS.csv","${outputdir}/${upload}.SummaryIBS.csv");
		rename ("${datadir}/${upload}.SummaryGenotype.csv","${outputdir}/${upload}.SummaryGenotype.csv");
		rename ("${datadir}/${upload}.SummaryMeanSD.csv", "${outputdir}/${upload}.SummaryMeanSD.csv");
	}
	else
	{
		system ("mv ${datadir}/${upload}.SummaryIBS.csv ${outputdir}/${upload}.SummaryIBS.csv; mv ${datadir}/${upload}.SummaryGenotype.csv ${outputdir}/${upload}.SummaryGenotype.csv; mv ${datadir}/${upload}.SummaryMeanSD.csv ${outputdir}/${upload}.SummaryMeanSD.csv");
	}
	
	########################################
	# Make the HTML output
	########################################
		
	########################################
	# Output for GenomeByChromosome
	########################################
	my $pagegenerated = timestamp();
	
	########################################
	# HTML header and initial text
	########################################
	print $cgi->header();
	print "<html>\n<head>\n<title>SNPduo Results for $file</title>\n<style type=\"text/css\">\ntable {margin-left: auto; margin-right: auto}\ntr {text-align: center; vertical-align: middle}\nth {text-align: center}\nbody {font-family: verdana, arial, helvetica, sans-serif}\n</style></head>\n<body>\n\n<p>\nFile uploaded: $file\n<br>SNPduo Version: $current_revision\n<br>Analysis started at $starttimestamp\n<br>Page generated at $pagegenerated\n<br>\nFile upload: $uploadTime seconds\n<br>IBS calculation: $ibsTime seconds</p>";
	
	########################################
	# horizontal break and links
	########################################	
	print "<hr>\n\n";
	print "<p><br>\n\n";
	print "Click <a href=\"${webpage}/${outputFolder}/${upload}.SummaryGenotype.csv\">here (.csv)</a> to download the Genotype summary.<br>\n";
	print "Click <a href=\"${webpage}/${outputFolder}/${upload}.SummaryIBS.csv\">here (.csv)</a> to download the IBS summary.<br>\n";
	print "Click <a href=\"${webpage}/${outputFolder}/${upload}.SummaryMeanSD.csv\">here (.csv)</a> to download the Autosomal Mean / SD summary.<br>\n";
	print "</p>\n\n";
	
	########################################
	# Print Genotype summary table
	########################################	
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
	
	########################################
	# Print genotype data row by row
	########################################
	my $prevSample = "NULLVALUENOPREVIOUSVALUE";
	
	open GENO, "${outputdir}/${upload}.SummaryGenotype.csv" or error ($cgi, "Couldn't open genotype summary file :$!");
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
	
	########################################
	# Print IBS summary table
	########################################
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
	
	########################################
	# Print IBS data row by row
	########################################
	my $prevSampleA = "NULLVALUENOPREVIOUSVALUE";
	my $prevSampleB = "NULLVALUENOPREVIOUSVALUE";
	
	open IBS, "${outputdir}/${upload}.SummaryIBS.csv" or error ($cgi, "Couldn't open IBS summary file :$!");
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
	
	########################################
	# Print Mean SD summary table
	########################################
	print "<br><br>\n\n<table align=\"center\" border=\"1\" cellpadding=\"3\">\n";
	print "<tr><th>Sample A</th>\n";
	print "<th>Sample B</th>\n";
	print "<th>Mean IBS</th>\n";
	print "<th>SD IBS</th>\n";
	print "</tr>\n";
	
	########################################
	# Print Mean / SD data row by row
	########################################
	open MEANSD, "${outputdir}/${upload}.SummaryMeanSD.csv" or error ($cgi, "Couldn't open Mean/SD summary file :$!");
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
	########################################
	# Close remaining tags
	########################################
	print "</body>\n</html>";
}

########################################
# Subroutine for reporting errors
########################################

sub error
{
	my ($out, $message) = @_;
	
	print $out->header("text/html");
	print ("<html>\n<head>\n<title>Error Page\n</title>\n\n<style type=\"text/css\">\ntable {margin-left: auto; margin-right: auto}\ntr {text-align: center; vertical-align: middle}\nth {text-align: center}\nbody {font-family: verdana, arial, helvetica, sans-serif}\n</style>\n</head>\n<body>\n");
	
	print ("<p>An error has occurred during file processing\n<br>Error message: $message\n</p>\n");
	print ("</body>\n</html>");

	exit 0;
}

########################################
# Subroutine for timestamping runs
########################################

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

########################################
# Subroutine for generating custom R scripts
########################################

sub WriteRTemplate
{
	my ($codeDir, $dataDir, $Platform, $uploadName, $chromName, $chromListObjects, $RcomparisonVector,
	$compiledDir,$rowCounts,$psWidth,$psHeight,$Build,$ComparisonVector,$Delimiter,$Makeps, $RunMode, $BEDMode) = @_;
	
	open TEMPLATE, "${codeDir}/${Platform}.R" or error ($cgi, "Cannot open $Platform template: $!");
	open R_CODE, ">${dataDir}/${uploadName}.R" or error ($cgi, "Cannot make custom R code for $Platform: $!");
	
	while (<TEMPLATE>)
	{
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
		
		print R_CODE;
	}
	
	close TEMPLATE;
	close R_CODE;
}

########################################
# Subroutine for creating images using
# the PerlMagick Module
########################################
sub PerlMagickConvertPStoPNG
{
	
	my ($dataDir,$uploadName,$currentName,$psWidth,$psHeight,$Thumbnail) = @_;
	
	my $imageCMD = Image::Magick->new;
	my $image = $imageCMD->Read("${dataDir}/${uploadName}_${currentName}.ps");
	   $image = $imageCMD->Rotate(degrees=>90);
	my $pngwidth = int($psWidth*72);
	my $pngheight = int($psHeight*72);
	   $image = $imageCMD->Resize(geometry=>"pngwidth x $pngheight", filter=>"Blackman");
#	   $image = $imageCMD->Sharpen(2);
	   $image = $imageCMD->Write("${dataDir}/${uploadName}_${currentName}.png");
	if( $Thumbnail eq "TRUE" )
	{
		$image = $imageCMD->Resize(geometry=>"124 x 96");
		$image = $imageCMD->Write("${dataDir}/${uploadName}thumb_${currentName}.png");
	}
}

########################################
# Subroutine for checking directory sizes
########################################

sub DirectoryCheck {
	my ($uploadDir, $outputDir) = @_;
	
	my $uploadDirSize = `du -c $uploadDir | grep total`;
	$uploadDirSize =~ s/^\s*(\d+)\s*total.*$/$1/e;
	my $outputDirSize = `du -c $outputDir | grep total`;
	$outputDirSize =~ s/^\s*(\d+)\s*total.*$/$1/e;
	
	if ($uploadDirSize > DIR_MAX || $outputDirSize > OUTPUT_MAX)
	{
		DirectoryClean ($uploadDir,$outputDir);
	}
}

########################################
# Subroutine for cleaning full directories
########################################

sub DirectoryClean
{
	my $i = 0;
	my ($uploadDirectory, $outputDirectory) = @_;
	my $round = 1;
	my $dirClean = 0;

	# Loop through cleaning files, multiple times if necessary
	until ($dirClean == 1 || $round > 7)
	{
		my @age = 0;
		my @killArray = 0;
		
		# Get both directory contents
		opendir (DIR, $uploadDirectory);
		my @uploadFiles = readdir(DIR);
		shift (@uploadFiles);
		shift (@uploadFiles);
		closedir (DIR);
		opendir (DIR, $outputDirectory);
		my @outputFiles = readdir(DIR);
		shift (@outputFiles);
		shift (@outputFiles);
		closedir (DIR);
		
		# Add the directory onto the file to get stats
		foreach $file (@uploadFiles)
		{ 
			$file =~ s/^([\w\s\-\_\.]*)$/$1/ || die "Can't match file $file for cleaning: $!\n";
			$file = $uploadDirectory . "/" . $file;
		}
		foreach $file (@outputFiles)
		{
			$file =~ s/^([\w\s\-\_\.]*)$/$1/ || die "Can't match file $file for cleaning: $!\n";
			$file = $outputDirectory . "/" . $file;
		}
		
		# Combine arrays
		my @allFiles = (@uploadFiles, @outputFiles);
		
		# Get each file size
		foreach $file (@allFiles)
		{
			my @stat = stat($file);
			push (@age, $stat[9]);
		}
		
		# Kill the starting zero if there are any files to process
		if (scalar(@age) > 1)
		{
			shift(@age);
		}
		
		my $currTime = time;
		
		# Now select files to delete, based on the severity of file overload
		for ($i = 0; $i < scalar(@age); ++$i)
		{
			my $currAge = $age[$i];
			
			if ($round == 1)
			{
				# Delete older than 7 days
				if (($currTime - $currAge) > 604800)
				{
					push(@killArray, $allFiles[$i]);
				}
			} 
			elsif ($round == 2)
			{
				# Delete older than 3 days
				if (($currTime - $currAge) > 259200)
				{
					push(@killArray, $allFiles[$i]);
				}
			}
			elsif ($round == 3)
			{
				# Delete files older than 1 day
				if (($currTime - $currAge) > 86400)
				{
					push(@killArray, $allFiles[$i]);
				}
			}
			elsif ($round == 4)
			{
				# Delete files older than 12 hours
				if (($currTime - $currAge) > 43200)
				{
					push(@killArray, $allFiles[$i]);
				}
			}
			elsif ($round == 5)
			{
				# Delete files older than 6 hours
				if (($currTime - $currAge) > 21600)
				{
					push(@killArray, $allFiles[$i]);
				}
			}
			elsif ($round == 6)
			{
				# Delete files older than 1 hour
				if (($currTime - $currAge) > 3600)
				{
					push(@killArray, $allFiles[$i]);
				}
			}
			else
			{
				# Kill everything in the two directories as a last resort
				push (@killArray, $allFiles[$i]);
			}
		}		
		
		if (scalar(@killArray) > 1)
		{
			shift (@killArray);
			
			foreach $file (@killArray)
			{
				chomp ($file);
				if ($file =~ /^(.*)$/)
				{
					$file = $1;
					unlink ("$file");
				}
			}
		}
				
		my $uploadDirSize = `du -c $uploadDirectory | grep total`;
		$uploadDirSize =~ s/^(\d*)\s*.*$/$1/e or die "Can't understand upload directory size $uploadDirSize: $!\n";
		my $outputDirSize = `du -c $outputDirectory | grep total`;
		$outputDirSize =~ s/^(\d*)\s*.*$/$1/e or die "Can't understand output directory size $outputDirSize: $!\n";
		
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
