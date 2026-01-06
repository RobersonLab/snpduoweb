###########################
#	snpduo_code_template.R #
#	Author: Eli Roberson   #
##########################

source( "SCRIPT_SOURCE" )

# Counter
comparisonVectorCounter = 1

upload = "UPLOAD_HOLDER"

SEP = SEP_HOLDER

SKIP = SKIP_HOLDER

input = read.delim( upload, colClasses="character", comment.char="", nrow=ROW_HOLDER, sep=SEP, skip=SKIP )

if ( dim( input )[2] == 1 )
{
	stop( paste( "One column found in uploaded data. Check your file format to be sure this is correct" ) )
}

names( input )[ which( names( input ) == "Chr" ) ] = "Chromosome"
names( input )[ which( names( input ) == "Position" ) ] = "Physical.Position"

chrom = "CHR_HOLDER"

chromList = CHR_LIST

comparisonColumns = IND_HOLDER

pswidth = WIDTH_HOLDER

psheight = HEIGHT_HOLDER

compiled = "COMPILE_DIR"

genomebuild = "BUILD_HOLDER"

comparisonVector = COMPARISON_VECTOR

cytoband = load_chromosome_features(compiled, genomebuild)

makepostscript = PS_HOLDER

makePNG = PNG_HOLDER

MODE = "MODE_HOLDER"

BED = "BED_HOLDER"

# Load the library now and do it only once. No need to access it repeatedly.
dyn.load( file.path( compiled, paste( "SNPduoCCodes", .Platform$dynlib.ext, sep="" ) ) )
if ( MODE != "Tabulate" )
{
	write.table( comparisonVector, file=paste( upload, "_Comparisons.txt", sep="" ), row.names=FALSE, col.names=FALSE, quote=FALSE, sep="\t" )
	
	for ( person1index in 1:( length( comparisonColumns ) - 1 ) )
	{
		ind1 = comparisonColumns[person1index]
		
		for ( person2index in (person1index + 1):length( comparisonColumns ) )
		{
			ind2 = comparisonColumns[person2index]
	
			if( chrom == "Genome" )
			{
				whole_genome_plot( input, ind1, ind2, savename=upload, pswidth, psheight, comparison=comparisonVector[comparisonVectorCounter], doPostscript=makepostscript, makeBED = BED, doPNG=makePNG, chr.offset=load_chromosome_position_offsets( compiled, genomebuild ) )
			} else if ( chrom == "GenomeByChromosome" )
			{
				genome_by_chromosome( input,ind1, ind2, savename=upload, pswidth, psheight, comparison=comparisonVector[comparisonVectorCounter], doPostscript=makepostscript,chromlist=chromList, makeBED = BED, doPNG=makePNG )
			} else
			{
				snpduo_single_chromosome( input,chrom, ind1, ind2, savename=upload, pswidth, psheight, comparison=comparisonVector[comparisonVectorCounter], doPostscript=makepostscript, makeBED = BED, doPNG=makePNG )
			}
			
			comparisonVectorCounter = comparisonVectorCounter + 1
		}
	}
} else
{
	tabulate_ibs( input, chromList, unique( comparisonColumns ), upload )
}

# Unload at the end to be sure everything closes nicely
dyn.unload( file.path( compiled, paste( "SNPduoCCodes", .Platform$dynlib.ext, sep="" ) ) )
