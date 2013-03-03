#############################
#
#	HapMapTemplate.R
#	Author: Eli Roberson
#	Created: September 21, 2007 
#	Last Edit: March 09, 2012 - ER
#
#############################
#  Copyright (c)  2007-2012 Elisha Roberson and Jonathan Pevsner.
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
#############################
source("SCRIPT_SOURCE")

# Counter
comparisonVectorCounter = 1

###############################################
upload = "UPLOAD_HOLDER"

SEP = SEP_HOLDER

input = read.delim(upload, colClasses="character", comment.char="", nrow=ROW_HOLDER, sep=SEP)

if (dim(input)[2] == 1) { stop( paste("One column found in uploaded data. Check your file format to be sure this is correct") ) }

names(input)[which(names(input)=="Chr")] = "Chromosome"
names(input)[which(names(input)=="Position")] = "Physical.Position"

# Sanitize input to throw away unusual probes
input = subset(input, Chromosome %in% c(1:22, "X", "Y", "M", "MT", "Mito", "MITO"))

chrom = "CHR_HOLDER"

chromList = CHR_LIST

comparisonColumns = IND_HOLDER

pswidth = WIDTH_HOLDER

psheight = HEIGHT_HOLDER

compiled = "COMPILE_DIR"

genomebuild = "BUILD_HOLDER"

comparisonVector = COMPARISON_VECTOR

cytoband = LoadFeatures(compiled, genomebuild)

makepostscript = PS_HOLDER

makePNG = PNG_HOLDER

MODE = "MODE_HOLDER"

BED = "BED_HOLDER"

# Precode genotypes
uniqColumns = unique(comparisonColumns)
if (MODE != "Tabulate")
{
	for (i in 1:length(uniqColumns))
	{
		input[, uniqColumns[i]] = gensub(input[, uniqColumns[i]])
	}
}

# Load the library now and do it only once. No need to access it repeatedly.
dyn.load(file.path( compiled, paste("SNPduoCCodes", .Platform$dynlib.ext,sep="")))

if (MODE != "Tabulate")
{
	write.table(comparisonVector, file=paste(upload, "_Comparisons.txt", sep=""), row.names=FALSE, col.names=FALSE, quote=FALSE, sep="\t")
	
	for ( i in 1:(length(comparisonColumns) - 1))
	{
		ind1 = comparisonColumns[i]
		
		for (j in (i + 1):length(comparisonColumns))
		{
			ind2 = comparisonColumns[j]
	
			if(chrom == "Genome")
			{
				genome.plot(input,ind1,ind2,savename=upload,pswidth, psheight, comparison=comparisonVector[comparisonVectorCounter], doPostscript=makepostscript, makeBED = BED, doPNG=makePNG, chr.offset=LoadOffsets(compiled,genomebuild))
			} else if (chrom == "GenomeByChromosome")
			{
				genomebychromosome(input,ind1, ind2, savename=upload, pswidth, psheight, comparison=comparisonVector[comparisonVectorCounter], doPostscript=makepostscript,chromlist=chromList, makeBED = BED, doPNG=makePNG)
			} else
			{
				SNPduo(input,chrom, ind1, ind2, savename=upload, pswidth, psheight, comparison=comparisonVector[comparisonVectorCounter], doPostscript=makepostscript, makeBED = BED, doPNG=makePNG)
			}
			
			comparisonVectorCounter = comparisonVectorCounter + 1
		}
	}	
} else
{
	if (is.null(chromList))
	{
		TabulateIBS(input, chromosomeVector=NULL,uniqColumns, upload)
	} else
	{
		TabulateIBS(input, chromList, uniqColumns, upload)
	}
}

# Unload at the end to be sure everything closes nicely
dyn.unload(file.path(compiled, paste("SNPduoCCodes", .Platform$dynlib.ext,sep="")))
