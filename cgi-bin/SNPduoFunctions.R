################################################################################
#  SNPduoFunctions.R                                                           #
#  Author: Eli Roberson                                                        #
#  Created: April 20, 2007                                                     #
#  Last Edit: March 09, 2012 - ER                                              #
#                                                                              #
#  Copyright (c)  2007-2012 Elisha Roberson and Jonathan Pevsner.              #
#                 All Rights Reserved.                                         #
#                                                                              #
#  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS "AS IS" AND ANY          #
#  EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE           #
#  IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR          #
#  PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNERS BE           #
#  LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR         #
#  CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF        #
#  SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS    #
#  INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN     #
#  CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)     #
#  ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE  #
#  POSSIBILITY OF SUCH DAMAGE. THIS SOFTWARE IS FREE FOR PERSONAL OR ACADEMIC  #
#  USE. THE SOFTWARE MAY NOT BE USED COMMERCIALLY WITHOUT THE EXPRESS, WRITTEN #
#  PERMISSION OF THE COPYRIGHT HOLDERS. ALL ACTIONS OR PROCEEDINGS RELATED TO  #
#  THIS SOFTWARE SHALL BE TRIED EXCLUSIVELY IN THE STATE AND FEDERAL COURTS    #
#  LOCATED IN THE COUNTY OF BALTIMORE CITY, MARYLAND. USE OF THIS SOFTWARE     #
#  IMPLIES ACCEPTANCE OF THIS CONTRACT.                                        #
################################################################################

#############################################
#  SNPduo                                   #
#                                           #
#  Function to plot a single chromosome     #
#  Used for single chromosome comparisons   #
#  and for Genome By Chromosome comparisons #
#############################################
SNPduo = function(x, y, ind1, ind2, savename, pagewidth, pageheight, bychromosome = FALSE, cexScale = 0.20, comparison = "None", pchValue=20,doPostscript = TRUE, makeBED = TRUE, doPNG=FALSE, DPI=72, THUMBNAIL=FALSE)
{	
	if (!doPNG & THUMBNAIL) { THUMBNAIL = FALSE } # We only allow thumbnail generation if doPNG is set
	
	########################################
	# Find the columns containing chromosome and position by grep
	########################################
	pos = grep("Physical.Position", names(x))
	chr = grep("Chromosome", names(x))
	########################################
	# R converts spaces to dots. For printing gsub dots for spaces. 
	########################################
	printInd1 = gsub("\\.", " ", names(x)[ind1])
	printInd2 = gsub("\\.", " ", names(x)[ind2])
	
	########################################
	# Error check
	########################################
	if (length(pos) < 1)
	{
		stop("Position column not found");
	}
	
	if (length(chr) < 1)
	{
		stop("Chromosome column not found");
	}
		
	########################################
	# Find which rows match the chromosome of interest
	########################################
	currIndex = which(x[,chr] == y)
	
	########################################
	# Error check
	########################################
	if (length(currIndex) < 1)
	{
		stop(paste("Problem subsetting data. You specified chromosome", y, "but it can't be found in your data"))
	}
		
	########################################
	# Subset the data so that only the part containing the chromosome you are interested in is used.
	########################################
	curr = x[currIndex,]
	
	########################################
	# For numeric chromosomes make sure they are in numeric form by running chrom_convert function
	########################################
	if (y != "X" && y != "Y" && y != "M" && y != "MT" && y != "Mito" && y != "MITO" && y != "XY") {y = chrom_convert(y)}
	
	########################################
	# Pull the physical position data into a vector
	########################################
	physPos = curr[,pos]
	
	########################################
	# Make sure physical position is numeric
	########################################
	if(!is.numeric(physPos))
	{
		physPos = as.numeric(physPos)
	}
	
	########################################
	# Vectorize the individual genotypes
	########################################
	gen1 = curr[,ind1]
	gen2 = curr[,ind2]
	
	########################################
	## Pull some values to be written to the output file before they are manipulated from their standard form
	########################################
	fortext = data.frame("Chromosome" = y, "Physical Position" = physPos, "IBS" = -1, "tmp1" = gen1, "tmp2" = gen2)
	
	########################################
	# Substitute "alpha" genoytpes (AA, AB, BB, NC) for numeric genotypes for speed in comparisons using gensub function
	########################################
	if(!is.numeric(gen1)) {gen1 = gensub(gen1)}
	if(!is.numeric(gen2)) {gen2 = gensub(gen2)} 
	
	########################################
	# Score SNPs
	# Passes genotypes to function that performs the passing of data from R to C and returns the proper fields.
	########################################
	Cdata = Cscore.snps(gen1, gen2)
	
	########################################
	# Pull ibs scores
	########################################
	ibsVector = unlist(Cdata[1])
		
	########################################
	# IBS Summary Information
	########################################
	ibs2 = unlist(Cdata[2])
	ibs1 = unlist(Cdata[3])
	ibs0 = unlist(Cdata[4])
	
	########################################
	# Calculate Average IBS
	########################################
	avg.ibs = round(mean(ibsVector, na.rm=TRUE), 3)
	
	########################################
	# Genotype Summary Information
	########################################
	ind1.AA = unlist(Cdata[5])
	ind1.AB = unlist(Cdata[6])
	ind1.BB = unlist(Cdata[7])
	ind1.NC = unlist(Cdata[8])

	ind2.AA = unlist(Cdata[9])
	ind2.AB = unlist(Cdata[10])
	ind2.BB = unlist(Cdata[11])
	ind2.NC = unlist(Cdata[12])
	
	if (doPostscript == TRUE || doPNG == TRUE || THUMBNAIL == TRUE)
	{
		########################################
		# Tick Marks
		# Find maximum plotting point
		########################################
		maxpos = max(physPos)
		maxcytoband = bandMax(y, cytoband)
		
		if (maxpos < maxcytoband)
		{
			maxpos = maxcytoband
		}
		
		########################################
		# Use function find ticks to find tick mark position, number, and the proper x-axis label for the tick scale
		# Also find the jittered placement of IBS and genotype, for consistency between PS and PNG
		########################################
		ticks = findticks(maxpos)
		ticklabel = unlist(ticks[2])
		posprefix = unlist(ticks[3])
		ticks = unlist(ticks[1])	
		
		max.tmp = maxpos
		max.ticks = max(ticks)
		
		if(max.ticks > max.tmp)
		{
			max.tmp = max.ticks
		}
		
		ibs.jittered = jitter(ibsVector, amount = 0.20) + 13
		gen1.jittered = jitter(gen1, amount = 0.20) + 8
		gen2.jittered = jitter(gen2, amount = 0.20) + 3
		
		# A new trick to get the PNG and postscript to print the same thing if asked
		while (doPostscript == TRUE || doPNG == TRUE || THUMBNAIL == TRUE)
		{
			########################################
			# Postscript
			# Set paper size bases on page input. Name the file appropriately for single chromosome versus genome by chromosome
			########################################
			if (bychromosome)
			{
				if (doPostscript)
				{
					postscript(file=paste(savename,"chr", y, "_", comparison, ".ps", sep=""), paper="special", width=pagewidth, height=pageheight, horizontal=TRUE)
				} else if (doPNG)
				{
					png(filename=paste(savename,"chr", y, "_", comparison, ".png", sep=""), width=round(pagewidth * DPI,0), height=round(pageheight*DPI,0), units="px", bg="white", type="cairo", antialias="default", res=DPI)
				} else if (THUMBNAIL)
				{
					png(filename=paste(savename,"chr", y, "thumb_", comparison, ".png", sep=""), width=124, height=96, units="px", bg="white", type="cairo", antialias="default", res=DPI, pointsize=1)
				}
			} else
			{
				if (doPostscript)
				{
					postscript(file=paste(savename,"_", comparison,".ps", sep=""), paper="special", width=pagewidth, height=pageheight, horizontal=TRUE)
				} else if (doPNG)
				{
					png(filename=paste(savename,"_", comparison,".png", sep=""), width=round(pagewidth * DPI,0), height=round(pageheight*DPI,0), units="px", bg="white", type="cairo", antialias="default", res=DPI)
				}
			}
			
			plot.min = 0
			plot.max = 16
			par("mar" = c(5, 4, 4, 5) + 0.1)
			plot.new()
			plot.window(xlim = c(1, max.tmp), ylim = c(plot.min, plot.max))
			title(paste("Chromosome ", y, " SNPduo Output\n", printInd1, " - ", printInd2, "\nAverage IBS: ", avg.ibs,sep=""))
			title(xlab = paste("Physical Position", posprefix))
			
			points(physPos, ibs.jittered, cex = cexScale, pch = pchValue)
			points(physPos, gen1.jittered, cex = cexScale, pch = pchValue)
			points(physPos, gen2.jittered, cex = cexScale, pch = pchValue)
			drawCytobands(y, cytoband, miny = 0, maxy = 2)
			axis(1, at = ticks, labels = as.character(ticklabel))
			
			ibslab = c(0,1,2)
			genlab = c(0,1,2,3)
			axis(2, at = c((genlab + 3)), labels = c("NC", "AA", "AB", "BB") , las = 1)
			axis(2, at = c((genlab + 8)), labels = c("NC", "AA", "AB", "BB") , las = 1)
			axis(2, at = c((ibslab + 13)), labels = c("0", "1", "2") , las = 1)
			
			axis(4, at = c((genlab + 3)), c(paste( format(ind2.NC,big.mark=",")), paste( format(ind2.AA,big.mark=",")), paste( format(ind2.AB,big.mark=",")), paste( format(ind2.BB,big.mark=","))), las = 1)
			axis(4, at = c((genlab + 8)), c(paste( format(ind1.NC,big.mark=",")), paste( format(ind1.AA,big.mark=",")), paste( format(ind1.AB,big.mark=",")), paste( format(ind1.BB,big.mark=","))), las = 1)
			axis(4, at = c((ibslab + 13)), c(paste( format(ibs0,big.mark=",")), paste( format(ibs1,big.mark=",")), paste( format(ibs2,big.mark=","))), las = 1)
			
			########################################
			# Side labels
			########################################
			mtext("Genotype", line = 3,side = 2, at = 4.5, cex = 1.15)
			mtext("Genotype", line = 3,side = 2, at = 9.5, cex = 1.15)
			mtext("Identity by State", line = 3, side = 2, at = 14, cex = 1.15)
			
			########################################
			# Inside labels
			########################################
			text(x = max.tmp / 2, y = 12, paste(printInd1), cex = 1.05)
			text(x = max.tmp / 2, y = 7, paste(printInd2), cex = 1.05)
			
			########################################
			# Box it
			########################################
			rect(0, 2.4, max.tmp, 15.6)
			
			dev.off()
			
			if (doPostscript)
			{
				doPostscript = FALSE
			} else if (doPNG)
			{
				doPNG = FALSE
			} else if (THUMBNAIL)
			{
				THUMBNAIL = FALSE
			}
		}
	}
	
	########################################	
	# Now write a text file summary
	# Genotypes -- make a data frame and put the individual data summaries in it
	########################################
	genSummary = data.frame("Genotype" = c("AA", "AB", "BB", "NoCall"),"ind1" = 0,"ind2" = 0)
	
	genSummary[1,2] = ind1.AA
	genSummary[2,2] = ind1.AB
	genSummary[3,2] = ind1.BB
	genSummary[4,2] = ind1.NC

	genSummary[1,3] = ind2.AA
	genSummary[2,3] = ind2.AB
	genSummary[3,3] = ind2.BB
	genSummary[4,3] = ind2.NC

	########################################
	# IBS -- summary data frame for IBS types
	########################################
	ibsSummary = data.frame("Alleles Identical by State" = c(0,1,2),"Counts" = 0)
	ibsSummary[1,2] = ibs0
	ibsSummary[2,2] = ibs1
	ibsSummary[3,2] = ibs2	
	
	########################################
	# Write everything
	# Put the proper data in the IBS column
	########################################
	fortext$IBS = ibsVector
	########################################
	# Order by Physical Position
	########################################
	fortext = fortext[order(fortext[,2]),]
	
	########################################
	# Put the adjusted header names in the right places for each file
	########################################
	names(fortext)[4] = paste(printInd1)
	names(fortext)[5] = paste(printInd2)
	
	names(genSummary)[2] = paste(printInd1)
	names(genSummary)[3] = paste(printInd2)
	
	########################################
	# Name the files appropriately bases on whether this is a single chromosome or genome by chromosome.
	########################################
	if (!bychromosome)
	{	
		write.table(fortext, row.names = FALSE, quote = FALSE, file = paste(savename,"_", comparison, ".summary.txt", sep = ""), sep = "\t")
		if (makeBED)
		{
			if (y %in% c(1:23, "X"))
			{
				SegmentBlocks(ibs=ibsVector, position=physPos, chromosome=y,Ind1=printInd1,Ind2=printInd2,File=paste(savename,"_", comparison,  ".bedsummary.txt", sep = ""))
			}
		}
		write.table(genSummary, row.names = FALSE, quote = FALSE, file = paste(savename,"_", comparison, ".gensum", sep = ""),sep = "\t")
		write.table(ibsSummary, row.names = FALSE, quote = FALSE, file = paste(savename,"_", comparison, ".ibssum", sep = ""),sep = "\t")
	} else if (bychromosome)
	{
		write.table(fortext, row.names = FALSE, quote = FALSE, file = paste(savename,"_", comparison,  ".summary.txt", sep=""), sep="\t", col.names=FALSE, append=TRUE)
		if (makeBED)
		{
			if (y %in% c(1:23, "X"))
			{
				SegmentBlocks(ibs=ibsVector, position=physPos, chromosome=y,Ind1=printInd1,Ind2=printInd2,File=paste(savename,"_", comparison,  ".bedsummary.txt", sep = ""), Append=TRUE)
			}
		}
		write.table(genSummary, row.names = FALSE, quote = FALSE, file = paste(savename, "chr", y, "_", comparison, ".gensum", sep=""),sep="\t")
		write.table(ibsSummary, row.names = FALSE, quote = FALSE, file = paste(savename, "chr", y, "_", comparison, ".ibssum", sep=""),sep="\t")
	}
}

########################################
# genome.plot
#
# Function to plot the whole genome on
# a single image.
########################################
genome.plot = function(x, ind1, ind2, savename, pagewidth, pageheight, cexScale=0.20, comparison="None", pchValue=20, doPostscript=TRUE, makeBED = TRUE, doPNG=FALSE, DPI=72,chr.offset=NULL)
{
	if (is.null(chr.offset))
	{
		stop("Chromosome offsets where not passed!!!")
	}
	
	pos = grep("Physical.Position", names(x))
	chr = grep("Chromosome", names(x))
	printInd1 = gsub("\\.", " ", names(x)[ind1])
	printInd2 = gsub("\\.", " ", names(x)[ind2])
	
	x = x[which(x[,chr] %in% c(1:24,"X","Y")),]
	#x = x[which(x[,chr] != "XY" & x[,chr] != "M" & x[,chr] != "MT" & x[,chr] != "MITO"),]
		
	outputchroms = x[,chr]
	
	x[, (x[,chr] == "X")] = 23
	x[, (x[,chr] == "Y")] = 24
	
	if (!is.numeric(x[,chr]))
	{
		if(!is.character(x[,chr]))
		{
			x[,chr] = as.character(x[,chr])
		}
		x[,chr] = as.numeric(x[,chr])
	}
	
	curr = x
			
	size = dim(curr)[1]
	physPos = curr[,pos]
	
	if (!is.numeric(physPos))
	{
		physPos = as.numeric(physPos)
	}
	
	########################################
	## Pull some values before they are manipulated
	########################################
	fortext = data.frame("Chromosome" = outputchroms, "Physical Position" = physPos, "IBS" = -1, "tmp1" = 0, "tmp2" = 0)
#	forbed  = data.frame("Chromosome" = outputchroms, "Physical Position" = physPos, "IBS" = -1, "tmp1" = 0, "tmp2" = 0)
	
	physPos = physPos + chr.offset[curr[,chr]]
	
	###
	gen1 = curr[,ind1]
	gen2 = curr[,ind2]
	
	###
	fortext$tmp1 = gen1
	fortext$tmp2 = gen2
#	forbed$tmp1 = gen1
#	forbed$tmp2 = gen2
	
	if(!is.numeric(gen1)) {gen1 = gensub(gen1)}
	if(!is.numeric(gen2)) {gen2 = gensub(gen2)}
	
	########################################
	# Score SNPs
	########################################
	Cdata = Cscore.snps(gen1, gen2)
	
	########################################
	# Pull ibs scores
	########################################
	ibsVector = unlist(Cdata[1])
		
	########################################
	# IBS Summary Information
	########################################
	ibs2 = unlist(Cdata[2])
	ibs1 = unlist(Cdata[3])
	ibs0 = unlist(Cdata[4])
	
	########################################
	# Average IBS
	########################################
	avg.ibs = round(mean(ibsVector, na.rm = TRUE), 3)
	
	########################################
	# Genotype Summary Information
	########################################
	ind1.AA = unlist(Cdata[5])
	ind1.AB = unlist(Cdata[6])
	ind1.BB = unlist(Cdata[7])
	ind1.NC = unlist(Cdata[8])

	ind2.AA = unlist(Cdata[9])
	ind2.AB = unlist(Cdata[10])
	ind2.BB = unlist(Cdata[11])
	ind2.NC = unlist(Cdata[12])
	
	if(doPostscript == TRUE || doPNG == TRUE)
	{
		###################################################
		# Tick Marks
		maxpos = max(chr.offset[25]) # The 25th slot gives the whole genome size of that version of the genome
		# Use function to find tick marks
		ticks = findticks(maxpos)
		ticklabel = unlist(ticks[2])
		posprefix = unlist(ticks[3])
		ticks = unlist(ticks[1])
		
		max.tmp = maxpos
		
		if(max(ticks) > maxpos)
		{
			max.tmp = max(ticks)
		}
		###################################################
		
		# Jittering
		ibs.jittered = jitter(ibsVector, amount = 0.20) + 13
		gen1.jittered = jitter(gen1, amount = 0.20) + 8
		gen2.jittered = jitter(gen2, amount = 0.20) + 3
		
		while (doPostscript || doPNG)
		{
			if (doPostscript)
			{
				######
				# ps #
				######
				postscript(file = paste(savename,"_", comparison,".ps", sep=""), paper = "special", width = pagewidth, height = pageheight, horizontal = TRUE)
			} else if (doPNG)
			{
				#######
				# PNG #
				#######
				png(filename=paste(savename,"_", comparison,".png", sep=""), width=round(pagewidth*72,0), height=round(pageheight*72,0), units="px", bg="white", type="cairo", antialias="default", res=DPI)
			}
			
			plot.min = 0
			plot.max = 16
			par("mar" = c(5, 4, 3, 5) + 0.1)
			plot.new()
			plot.window(xlim = c(1, max.tmp), ylim = c(plot.min,plot.max))
			title(paste("Genome-wide SNPduo Output\n", printInd1, " - ", printInd2, "\nAverage IBS: ", avg.ibs,sep=""))
			title(xlab = paste("Physical Position", posprefix))
			
			points(physPos, ibs.jittered, cex = cexScale, pch = pchValue)
			points(physPos, gen1.jittered, cex = cexScale, pch = pchValue)
			points(physPos, gen2.jittered, cex = cexScale, pch = pchValue)
			
			axis(1, at = ticks, labels = as.character(ticklabel))
			
			ibslab = c(0,1,2)
			genlab = c(0,1,2,3)
			axis(2, at = c((genlab + 3), (genlab + 8), (ibslab + 13)), labels = c("NC", "AA", "AB", "BB","NC", "AA", "AB", "BB", "0", "1", "2") , las = 1)
			########################################
			# Add in format command here to get formatted counts and split the axis 4 command into three statements
			########################################
			axis(4, at = c((genlab + 3), (genlab + 8), (ibslab + 13) ),c(paste(ind2.NC), paste(ind2.AA), paste(ind2.AB), paste(ind2.BB), paste(ind1.NC), paste(ind1.AA), paste(ind1.AB), paste(ind1.BB), paste(ibs0),paste(ibs1),paste(ibs2)), las = 1)
			
			########################################
			# Side labels
			########################################
			mtext("Genotype", line = 3,side = 2, at = 4.5,cex = 1.15)
			mtext("Genotype", line = 3,side = 2, at = 9.5,cex = 1.15)
			mtext("Identity by State", line = 3, side = 2, at = 14,cex = 1.15)
			
			########################################
			# Inside labels
			########################################
			text(x = max.tmp / 2, y = 7, paste(printInd1))
			text(x = max.tmp / 2, y = 12, paste(printInd2))
			
			########################################
			# Box it
			########################################
			rect(0, 2.4, max.tmp, 15.6)
			
			########################################
			# Chromosome Labels
			########################################
			chr.lines(chr.offset, 0,2)
			ChromosomeLabeling(chr.offset, 1)
			
			dev.off()
			
			if (doPostscript)
			{
				doPostscript = FALSE
			} else if (doPNG)
			{
				doPNG = FALSE
			}
		}
	}
	
	########################################
	# Write everything
	########################################
	fortext$IBS = ibsVector
	fortext = fortext[order(physPos),]
	
	names(fortext)[4] = paste(printInd1)
	names(fortext)[5] = paste(printInd2)
	
	write.table(fortext, row.names = FALSE, quote = FALSE, file = paste(savename,"_", comparison, ".summary.txt", sep = ""), sep = "\t")
	
	if (makeBED)
	{
		SegmentBlocks(ibs=ibsVector, position=physPos, chromosome=y,Ind1=printInd1,Ind2=printInd2,File=paste(savename,"_", comparison,  ".bedsummary.txt", sep = ""))
	}
	
	genSummary = data.frame("Genotype" = c("AA", "AB", "BB", "NoCall"),"tmp1" = 0,"tmp2" = 0)
	
	genSummary[1,2] = ind1.AA
	genSummary[2,2] = ind1.AB
	genSummary[3,2] = ind1.BB
	genSummary[4,2] = ind1.NC

	genSummary[1,3] = ind2.AA
	genSummary[2,3] = ind2.AB
	genSummary[3,3] = ind2.BB
	genSummary[4,3] = ind2.NC

	names(genSummary)[2] = paste(printInd1)
	names(genSummary)[3] = paste(printInd2)

	# IBS
	ibsSummary = data.frame("Alleles Identical by State" = c(0,1,2),"Counts" = 0)
	ibsSummary[1,2] = ibs0
	ibsSummary[2,2] = ibs1
	ibsSummary[3,2] = ibs2	
	
	write.table(genSummary, row.names = FALSE, quote = FALSE, file = paste(savename,"_", comparison, ".gensum", sep = ""),sep = "\t")
	write.table(ibsSummary, row.names = FALSE, quote = FALSE, file = paste(savename,"_", comparison, ".ibssum", sep = ""),sep = "\t")
}

########################################
#  Tabulate
#
#  Function to tabulate number of each ibs
#  count and genotype call in large samples
#
########################################
TabulateIBS = function (dataObject, chromosomeVector, individualColumns, savename)
{
	chr = grep("Chromosome", names(dataObject))
	if (length(chr) == 0)
	{
		stop("Chromosome column not found!")
	} else if (length(chr) > 1)
	{
		stop("Multiple chromosome columns found!")
	}
	
	if (is.null(chromosomeVector))
	{
		chromosomeVector = unique(dataObject[,chr])
	}
	
	sampleNames = names(dataObject)[individualColumns]
	numberSamples = length(individualColumns)
	numberComparisons = (numberSamples * (numberSamples - 1)) / 2
	numberChromosomes = length(chromosomeVector)
	
	########################################
	# Subset data on the chromosomes selected
	########################################
	dataObject = dataObject[which(dataObject[,chr] %in% chromosomeVector),]
	if (dim(dataObject)[1] == 0)
	{
		stop ("Tabulate mode failed: selected chromosomes not found in data")
	}
	
	########################################
	# Code inviduals genotypes
	########################################
	genotypeMatrix = matrix(ncol = numberSamples, nrow = dim(dataObject)[1],0)
	if (any(!is.numeric(dataObject[,individualColumns])))
	{
		genotypeMatrix[dataObject[,individualColumns] == "AA"] = 1
		genotypeMatrix[dataObject[,individualColumns] == "AB"] = 2
		genotypeMatrix[dataObject[,individualColumns] == "BB"] = 3
		genotypeMatrix[dataObject[,individualColumns] == "NC"] = 0
		genotypeMatrix[is.na(dataObject[,individualColumns])] = 0
	} else 
	{
		genotypeMatrix = as.matrix(genotypeDataframe[,individualColumns])
	}
	
	########################################
	# Get chromosome indexes only once
	########################################
	chromosomeIndexes = vector("list", numberChromosomes)
	
	for (i in 1:numberChromosomes)
	{
		chromosomeIndexes[[i]] = which (dataObject[,chr] == chromosomeVector[i])
	}
	
	########################################
	# Count genotypes
	########################################
	genotypeCountMatrix = matrix(nrow = numberChromosomes * numberSamples, ncol = 4,0) # From left to right: AA, AB, BB, NC
	genChromosome = character(numberChromosomes * numberSamples)
	genSample = character(numberChromosomes * numberSamples)
	
	iterationCounter = 1
	for (i in 1:numberSamples)
	{
		for (j in 1:numberChromosomes)
		{
			genChromosome[iterationCounter] = as.character(chromosomeVector[j])
			genSample[iterationCounter] = sampleNames[i]
			
			cGenotype = .C("CountGenotypes",
			cSize = as.integer(length(unlist(chromosomeIndexes[j]))),
			cGeno = as.integer(genotypeMatrix[unlist(chromosomeIndexes[j]),i]),
			cNC = as.integer(0),
			cAA = as.integer(0),
			cAB = as.integer(0),
			cBB = as.integer(0))
			
			genotypeCountMatrix[iterationCounter,1] = cGenotype$cAA
			genotypeCountMatrix[iterationCounter,2] = cGenotype$cAB
			genotypeCountMatrix[iterationCounter,3] = cGenotype$cBB
			genotypeCountMatrix[iterationCounter,4] = cGenotype$cNC
			
			iterationCounter = iterationCounter + 1
		}
	}
	
	genotypeCountDataframe = data.frame(genSample,genChromosome,genotypeCountMatrix)
	names(genotypeCountDataframe) = c("Sample", "Chromosome", "AA", "AB", "BB", "NC")
	
	########################################
	# Count IBS states
	########################################
	ibsCountMatrix = matrix(nrow = numberChromosomes * numberComparisons, ncol=3) #From left to right: IBS0, IBS1,IBS2
	colnames (ibsCountMatrix) = c("IBS0","IBS1","IBS2")
	ibsChromosome = character(numberChromosomes * numberComparisons)
	ibsSampleA = character(numberChromosomes * numberComparisons)
	ibsSampleB = character(numberChromosomes * numberComparisons)
	
	iterationCounter = 1
	for (i in 1:(numberSamples-1))
	{
		for (j in (i+1):numberSamples)
		{
			for (h in 1:numberChromosomes)
			{
				ibsChromosome[iterationCounter] = as.character(chromosomeVector[h])
				ibsSampleA[iterationCounter] = sampleNames[i]
				ibsSampleB[iterationCounter] = sampleNames[j]
				
				cIBS = .C ("CountIBSFromGenotypes",
				cSize = as.integer(length(unlist(chromosomeIndexes[h]))),
				cGeno1 = as.integer(genotypeMatrix[unlist(chromosomeIndexes[h]), i]),
				cGeno2 = as.integer(genotypeMatrix[unlist(chromosomeIndexes[h]), j]),
				cIBS0 = as.integer(0),
				cIBS1 = as.integer(0),
				cIBS2 = as.integer(0))
				
				ibsCountMatrix[iterationCounter,1] = cIBS$cIBS0
				ibsCountMatrix[iterationCounter,2] = cIBS$cIBS1
				ibsCountMatrix[iterationCounter,3] = cIBS$cIBS2
				
				iterationCounter = iterationCounter + 1
			}
		}
	}
	
	ibsCountDataframe = data.frame(ibsSampleA,ibsSampleB,ibsChromosome, ibsCountMatrix)
	names(ibsCountDataframe) = c("SampleA","SampleB","Chromosome","IBS0", "IBS1","IBS2")
	
	########################################
	# Autosomal Mean and SD
	########################################
	countsMatrix = matrix(nrow = numberComparisons, ncol = 3)
	colnames (countsMatrix) = c("IBS0", "IBS1", "IBS2")
	meanSDMatrix = matrix(nrow = numberComparisons, ncol = 2)
	colnames(meanSDMatrix) = c("Mean_IBS", "SD_IBS")
	meanSDsampleA = character (numberComparisons)
	meanSDsampleB = character (numberComparisons)
	
	iterationCounter = 1
	for (i in 1:(numberSamples - 1))
	{
		for (j in (i + 1):numberSamples)
		{
			# Get names
			meanSDsampleA[iterationCounter] = sampleNames[i]
			meanSDsampleB[iterationCounter] = sampleNames[j]
			
			# Do counts of IBS states
			countsMatrix[iterationCounter, "IBS0"] = sum(ibsCountMatrix[(ibsChromosome %in% 1:22 & ibsSampleA == sampleNames[i] & ibsSampleB == sampleNames[j]), "IBS0"])
			countsMatrix[iterationCounter, "IBS1"] = sum(ibsCountMatrix[(ibsChromosome %in% 1:22 & ibsSampleA == sampleNames[i] & ibsSampleB == sampleNames[j]), "IBS1"])
			countsMatrix[iterationCounter, "IBS2"] = sum(ibsCountMatrix[(ibsChromosome %in% 1:22 & ibsSampleA == sampleNames[i] & ibsSampleB == sampleNames[j]), "IBS2"])
			
			# Calculate Mean and SD
			meanSDMatrix = MeanSDFromCounts (countsMatrix)
			# Make sure everything saves
			meanSDdataframe = data.frame("SampleA" = meanSDsampleA, "SampleB" = meanSDsampleB, meanSDMatrix)
			
			iterationCounter = iterationCounter + 1
		}
	}
	
	
	########################################
	# Sort arrays so they are in order
	########################################
# 	X = 23
# 	XY = 24
# 	Y = 25
# 	M MITO MT = 26
	chromosomeVector = chromosomeVector[order(ChromosomeToInteger(chromosomeVector))]
		
	ibsCountDataframe = ibsCountDataframe[order(as.character(ibsCountDataframe$SampleA),as.character(ibsCountDataframe$SampleB),ChromosomeToInteger(ibsCountDataframe$Chromosome)),]
	
	genotypeCountDataframe = genotypeCountDataframe[order(as.character(genotypeCountDataframe$Sample),ChromosomeToInteger(genotypeCountDataframe$Chromosome)),]	
	meanSDdataframe = meanSDdataframe[order(as.character(meanSDdataframe$SampleA), as.character(meanSDdataframe$SampleB)),]	
	
	########################################
	# Write Genotype
	########################################
	write.table(ibsCountDataframe, file = paste(savename, ".SummaryIBS.csv", sep=""), row.names = FALSE, quote = FALSE, sep = ",")
	
	########################################
	# Write IBS
	########################################
	write.table(genotypeCountDataframe, file = paste(savename, ".SummaryGenotype.csv", sep=""), row.names = FALSE, quote = FALSE, sep = ",")
	
	########################################
	# Write Mean / SD
	########################################
	write.table(meanSDdataframe, file = paste(savename, ".SummaryMeanSD.csv", sep=""), row.names = FALSE, quote = FALSE, sep = ",")
	
	########################################
	# Write Chromosomes
	########################################
	write.table(as.character(chromosomeVector), file = paste(savename, ".chromlist", sep=""), row.names = FALSE, col.names=F,quote = FALSE, sep = "\t")
}

########################################
# ChromosomeToInteger
#
# Function to convert character chromosomes
# to numeric chromosomes for sorting
########################################
ChromosomeToInteger = function(charChr)
{
	if (!is.character(charChr))
	{
		charChr = as.character(charChr)
	}
	
	charChr[charChr == "X"] = 23
	charChr[charChr == "XY"] = 24
	charChr[charChr == "Y"] = 25
	charChr[charChr %in% c("M","MITO","MT")] = 26
	
	return(as.integer(charChr))
}

########################################
# Label Chromosomes
#
# Places labels for each chromosome on 
# plots where the whole genome is viewed
# on one image.
########################################
ChromosomeLabeling = function(chr.offset, yvalue)
{
	########################################
	# A function that simply places labels for each chromosome in the plot with the genome in one frame.
	########################################
	num.rows = length(chr.offset)
	plot.text = c(1:22, "X")
	
	for (i in 2:num.rows)
	{
		text(((chr.offset[i] + chr.offset[(i - 1)]) / 2) , yvalue, plot.text[i - 1], cex = 0.95)
	}
}

########################################
# JitterForWig
#
# BED Jitter
# Function used to created jittered data
# for creating a BED file output.
########################################
JitterForWig = function (toJitter, amountJitter = 0.15)
{
	toJitter = gsub(2, (2 - amountJitter), toJitter)
	toJitter = gsub(0, (0 + amountJitter), toJitter)
	
	if (!is.numeric(toJitter))
	{
		toJitter = as.numeric(toJitter)
	}
	
	toJitter = jitter(toJitter, amount = amountJitter)
	
	return( round(toJitter,3) )
}

########################################
# Cscore.snps
#
# R function to run SNPduo IBS comparisons
# in C code.
########################################
Cscore.snps = function(IND.1, IND.2)
{	
	########################################
	# Get number of SNPs to compar and vectorize the SNP data if it isn't already.
	########################################
	if (is.null(dim(IND.1)))
	{
		size = length(IND.1)
	} else
	{
		IND.1 = IND.1[,1]
		size = length(IND.1)
	}
	
	if (!is.null(dim(IND.2)))
	{
		IND.2 = IND.2[,1]
	}
	
	########################################
	# Replace NAs with 0s
	########################################
	IND.1[is.na(IND.1)] = 0
	IND.2[is.na(IND.2)] = 0
	
	########################################	
	# Preallocate memory and set to a value you should never get so it can be removed later.
	########################################
	tmp = integer(size)
	tmp[] = -5
	
	########################################
	# Call the compiled C function to do the actual comparison
	########################################
	CReturn = .C ("SNPScore",
	csize = as.integer(size),
	cgeno1 = as.integer(IND.1),
	cgeno2 = as.integer(IND.2),
	cscore = as.integer(tmp),
	ibs2count = as.integer(0),
	ibs1count = as.integer(0),
	ibs0count = as.integer(0),
	ind1AA = as.integer(0),
	ind1AB = as.integer(0),
	ind1BB = as.integer(0),
	ind1NC = as.integer(0),
	ind2AA = as.integer(0),
	ind2AB = as.integer(0),
	ind2BB = as.integer(0),
	ind2NC = as.integer(0))
	
	########################################
	# Remove any pesky placeholders that remain and replace them with NAs
	########################################
	CReturn$cscore[CReturn$cscore == -5] = NA
	
	########################################
	# Return all of the IBS calls, IBS counts, and genotype counts in the form of a list which is easier to deal with
	########################################
	forreturn = list(CReturn$cscore, CReturn$ibs2count,CReturn$ibs1count,CReturn$ibs0count,
	CReturn$ind1AA, CReturn$ind1AB, CReturn$ind1BB, CReturn$ind1NC, 
	CReturn$ind2AA, CReturn$ind2AB, CReturn$ind2BB, CReturn$ind2NC)
	
	return(forreturn)
}

########################################
# gensub
#
# Convert alpha type genotypes to numeric
########################################
gensub = function(genotypes)
{	
	########################################
	# Convert No Calls (either NC or NoCall) to 0
	# AA to 1, AB to 2, BB to 3
	# Then turn any NAs into 0s.
	########################################
	if (!is.character(genotypes))
	{
		genotypes = as.character(genotypes)
	}
	
	genotypes[genotypes == "NC"] = 0
	genotypes[genotypes == "NoCall"] = 0
	genotypes[genotypes == "AA"] = 1
	genotypes[genotypes == "AB"] = 2
	genotypes[genotypes == "BB"] = 3
	genotypes[is.na(genotypes)] = 0 
	
# 	genotypes = gsub("NC",0, genotypes)
# 	genotypes = gsub("NoCall", 0,genotypes)
# 	genotypes = gsub("AB",2, genotypes)
# 	genotypes = gsub("AA",1, genotypes)
# 	genotypes = gsub("BB",3, genotypes)
# 	genotypes[which(is.na(genotypes))] = 0
# 	genotypes = as.numeric(genotypes)
	return(as.integer(genotypes))
}

########################################
# chr.lines
#
# When genome is plotted in single frame
# this function is used to plot vertical
# lines at chromosome boundaries.
########################################
chr.lines = function(chr.offset, plot.min, plot.max)
{
	for (i in 2:24)
	{
		lines(c(rep(chr.offset[i], 2)), c(plot.min, plot.max))
	}
}

########################################
# chrom_convert
#
# Converts chromosomes into
# numeric form by testing to see if they
# are numeric. If not, then they are tested
# as characters and converted if they are
# not character class. Then finally converted
# to numerics.
########################################
chrom_convert = function(charChromosomes)
{
	if (!is.numeric(charChromosomes))
	{	
		if (!is.character(charChromosomes))
		{
			charChromosomes = as.character(charChromosomes)
		}
		charChromosomes[charChromosomes == "X"] = 23
		charChromosomes[charChromosomes == "XY"] = 24
		charChromosomes[charChromosomes == "Y"] = 25
		charChromosomes[charChromosomes %in% c("M","MITO","MT")] = 26
	}
	
	return(as.integer(charChromosomes))
}

########################################
# findticks
#
# Function to find where tick marks
# should go on a plot and what axis
# label is most appropriate
########################################
findticks = function(total)
{
	if (total >= 1000000)
	{
		adjustment = 1000000
		plotlabel = "(Mb)"
	} else
	{
		adjustment = 1000
		plotlabel = "(Kb)"
	}
	
	if (adjustment == 1000000)
	{		
		if (total > 2000000000)
		{
			bases = 200
		} else if (total > 200000000)
		{
			bases = 20
		} else if (total > 100000000)
		{
			bases = 10
		} else
		{
			bases = 5
		}
	}
	
	if (adjustment == 1000)
	{
		bases = 1
	}

	bases = bases * adjustment
	
	ticks = seq(0, total, by = bases)
	
	maxtick = max(ticks)
	
	if((total - maxtick) >= (bases / 2))
	{
		ticks = c(ticks, (maxtick + bases))
	}
	
	ticklabel = ticks / adjustment
	
	return(list(ticks, ticklabel, plotlabel))
}

########################################
# genomebychromosome
#
# Plot each chromosome individually while
# making appropriate single summary files
# and appropriately naming each one.
########################################
genomebychromosome = function (x, ind1, ind2, savename, pswidth, psheight, comparison = "None", doPostscript = TRUE, chromlist = NULL, makeBED = TRUE, doPNG=FALSE, DPI=72)
{
	printInd1 = gsub("\\.", " ", names(x)[ind1])
	printInd2 = gsub("\\.", " ", names(x)[ind2])
	
	if (is.null(chromlist))
	{
		chromlist = unique(x$Chromosome)
	}
	
	write.table(chromlist, file = paste(savename, "_", comparison, ".chromlist", sep=""), row.names = FALSE, col.names = FALSE, quote = FALSE, sep = "\t")
	
	cat("Chromosome\tPhysical Position\tIBS\t", paste(printInd1), "\t", paste(printInd2), "\n" ,file = paste(savename, "_", comparison, ".summary.txt", sep = ""))
#	cat("Chromosome\tPhysical Position\tIBS\t", paste(printInd1), "\t", paste(printInd2), "\n" ,file = paste(savename, "_", comparison, ".bedsummary.txt", sep = ""))
	
	for (i in 1:length(chromlist))
	{
		chrom = chromlist[i]
		SNPduo(x,chrom, ind1, ind2, savename, pswidth, psheight, bychromosome = TRUE, comparison = comparison, doPostscript = doPostscript, makeBED = makeBED, doPNG=doPNG, DPI=DPI, THUMBNAIL=TRUE)
	}
}

########################################
# LoadFeatures
#
# Load binary saves of centromere, 
# telomere, and heterochromatin locations
# for different genome builds
########################################
LoadFeatures = function(compiled, genomebuild)
{	
	########################################
	# Load appropriate genomic feature locations
	########################################
	if (genomebuild == "v34") {
		load(file.path(compiled, "v34cytoband.Rbin"))
	} else if (genomebuild == "v35")
	{
		load(file.path(compiled, "v35cytoband.Rbin"))
	} else if (genomebuild == "v36")
	{
		load(file.path(compiled, "v36.1cytoband.Rbin"))
	} else if (genomebuild == "vGRCh37")
	{
		load(file.path(compiled, "vGRCh37cytoband.Rbin"))
	} else
	{
		stop(paste("The indicated genome build", genomebuild, "was not found. Please try again.\n"))
	}
	
	########################################
	# If the objects didn't load correctly throw an error
	########################################
	if(!exists("cytoband"))
	{
		stop("Cytoband locations did not load properly")
	}

	return( cytoband )
}

##########################################################
# Load offsets                                           #
# Load chromosome offsets for genome plot based on build #
##########################################################
LoadOffsets = function( compiled, genomebuild )
{
	# This only gives offset for 1-22 and X/Y. Line 25 is the TOTAL genome size for giving the x plot size
	load(file.path(compiled, "offsets.Rbin"))
	if (!exists("offsets"))
	{
		stop("Offset information couldn't be loaded for genome plot!!!")
	}
	
	good.offset = offsets[,genomebuild]
	
	if (!exists("good.offset") || is.null(good.offset))
	{
		stop("Build not found in offsets!!!")
	}
	
	return( good.offset )
}

########################################
# drawCytobands
#
# Use cytoband data loaded for the current
# build to draw cytobands on an image.
########################################
drawCytobands = function(x, cytoband, drawLabels = TRUE, miny = 0, maxy = 2)
{	
	rangeY = maxy - miny
	quarterRange = rangeY / 4
	
	numBands = which(cytoband$chrom == paste("chr", x, sep = ""))
	
	type = "left"
	
	if (length(numBands) > 0)
	{
		for (i in 1:length(numBands))
		{			
			curr = numBands[i]
			
			stain = cytoband$gieStain[curr]
			if (length(stain) == 1)
			{
				if (stain == "gneg")
				{
					color = "grey100"
				} else if (stain == "gpos25")
				{
					color = "grey90"
				} else if (stain == "gpos50")
				{
					color = "grey70"
				} else if (stain == "gpos75")
				{
					color = "grey40"
				} else if (stain == "gpos100")
				{
					color = "grey0"
				} else if (stain == "gvar")
				{
					color = "grey95"
				} else if (stain == "stalk")
				{
					color = "brown3"
				} else if (stain == "acen")
				{
					color = "brown4"
				} else
				{
					color = "white"
				}
			}
			
			start.cyto = cytoband$chromStart[curr]
			end.cyto = cytoband$chromEnd[curr]
			size = end.cyto - start.cyto
			
			if (i == 1 || ((stain == "acen") && (type == "left")))
			{				
				secondPoint = start.cyto + (size / 5)
				
				polygon(c(start.cyto, start.cyto, secondPoint, end.cyto, end.cyto, secondPoint), c(miny + quarterRange, maxy - quarterRange, maxy, maxy, miny, miny), col = color)
				
				type = "right"
				
			} else if (i == length(numBands) || ((stain == "acen") && (type == "right")))
			{
				secondPoint = end.cyto
				end.cyto = end.cyto - (size / 5)
				
				polygon(c(start.cyto, start.cyto, end.cyto, secondPoint, secondPoint, end.cyto), c(miny, maxy, maxy, maxy-quarterRange, miny + quarterRange, miny), col = color)
				type = "left"
			} else
			{
				polygon(c(start.cyto, start.cyto, end.cyto, end.cyto), c(miny, maxy, maxy, miny), col = color)
			}
			
			########################################
			# Do text for cytobands here
			########################################
			if (drawLabels == TRUE)
			{
				chrSize = bandMax(x, cytoband)
				
				if ((size / chrSize) >= 0.02)
				{
					bandName = cytoband[curr, "name"]
					
					if (stain == "acen" || stain == "stalk" || stain == "gpos100")
					{
						textColor = "white"
					} else
					{
						textColor = "black"
					}
					
					text(x = start.cyto + (size / 2) , y = miny + (rangeY / 2), srt = 90, paste(bandName), col = textColor)
				}
			}
		}
	}
}

########################################
# bandMax
#
# Maximum of the cytoband data
########################################
bandMax = function(x, cytoband)
{	
	numBands = which(cytoband$chrom == paste("chr", x, sep = ""))
	
	if (length(numBands) > 1)
	{
		tmp = max(cytoband$chromEnd[numBands])
	} else
	{
		tmp = 0
	}
	
	return(tmp)
}

########################################
# 
# Diff Loop
# Function used in block finding protocol
# 
########################################
DiffLoop = function(diffIndex, maximumDist)
{
	# Set up index holders and calculate of vector to keep from recalculating
	size = length(diffIndex)
	startPos = size
	endPos = 0
	# make holders for index
	startIndex = c()
	endIndex = c()
	
	# test to find blocks
	for (i in 1:size)
	{
		if(diffIndex[i] < maximumDist)
		{
			if(i < startPos)
			{
				startPos = i
			} 
			if (i > endPos)
			{
				endPos = i
			}
		}
		
		# If you reach an boundary (block greater than certain distance
		if (diffIndex[i] >= maximumDist | i == size)
		{
			if ((endPos != 0) & (startPos != size) & (endPos != startPos))
			{
				startIndex[length(startIndex) + 1] = startPos
				endIndex[length(endIndex) + 1] = endPos + 1
			}
			
			startPos = size
			endPos = 0
		}		
	}
	
	return(list(startIndex, endIndex))
}


########################################
# SegmentBlocks
# Front end function for block finding
########################################
SegmentBlocks = function (ibs, position, chromosome, maximumDist = NULL, minIbs0 = NULL, minIbs1 = NULL, minIbs2 = NULL, Ind1=NULL,Ind2=NULL, Append=FALSE, File=NULL)
{
	blockStarts = integer(10)
	blockEnds = integer(10)
	blockType = character(10)
	blockCount = 0
	blockIndex = 1
	
	ibs = ibs[order(position)]
	position = position[order(position)]
	
	size = length(ibs)
	
	maximumDistIbs0 = 0.0175 * size
	maximumDistIbs1 = 0.015 * size
	maximumDistIbs2 = 0.005 * size
	
	if (maximumDistIbs0 < 5) { maximumDistIbs0 = 5 }
	if (maximumDistIbs1 < 5) { maximumDistIbs1 = 5 }
	if (maximumDistIbs2 < 5) { maximumDistIbs2 = 5 }
	
	#################################
	count0 = length(which(ibs == 0)) 
	count1 = length(which(ibs == 1))
	count2 = length(which(ibs == 2))
	
	##### Consider changing to be reflective of IBS type. Example: minIbs2 = 0.20 * count2
	if (is.null(minIbs0)) {minIbs0 = 0.0075 * count0}
	if (is.null(minIbs1)) {minIbs1 = 0.0075 * count1}
	if (is.null(minIbs2)) {minIbs2 = 0.0075 * count2}
	if (minIbs0 < 5) {minIbs0 = 5}
	if (minIbs1 < 5) {minIbs1 = 5}
	if (minIbs2 < 5) {minIbs2 = 5}
	
	#### #### #### #### #### #### #### #### #### #### #### #### #### #### #### #### #### #### #### #### ####
	#  # #  # #  # #  # #  # #  # #  # #  # #  # #  # #  # #  # #  # #  # #  # #  # #  # #  # #  # #  # #  #
	#### #### #### #### #### #### #### #### #### #### #### #### #### #### #### #### #### #### #### #### ####
	# IBS0
	index = which(ibs == 0)
	indexDiff = diff(index)
	
	if (length(index) >= minIbs0)
	{
		listHolder = DiffLoop(indexDiff, maximumDistIbs0)
		startIndex = unlist(listHolder[1])
		endIndex = unlist(listHolder[2])
		
		numSnps = endIndex - startIndex + 1
		
		startIndex = startIndex[numSnps >= minIbs0]
		endIndex = endIndex[numSnps >= minIbs0]
		
		if (length(startIndex) > 0 && length(endIndex) > 0)
		{
			for (i in 1:length(startIndex))
			{
				blockStarts[blockIndex] = index[startIndex[i]]
				blockEnds[blockIndex] = index[endIndex[i]]
				blockType[blockIndex] = "IBS0"
				blockCount = blockCount + 1
				blockIndex = blockIndex + 1
			}
		}
	}
	
	#### #### #### #### #### #### #### #### #### #### #### #### #### #### #### #### #### #### #### #### ####
	#  # #  # #  # #  # #  # #  # #  # #  # #  # #  # #  # #  # #  # #  # #  # #  # #  # #  # #  # #  # #  #
	#### #### #### #### #### #### #### #### #### #### #### #### #### #### #### #### #### #### #### #### ####
	#IBS1
	index = which(ibs == 1)
	indexDiff = diff(index)
	
	if (blockCount > 0)
	{
		# Find and remove SNPs already in the blocks
		for (i in 1:blockCount)
		{
			remTmp = which(index >= blockStarts[i] & index <= blockEnds[i])
			if (length(remTmp) > 0)
			{
				minIndex = min(remTmp)
				maxIndex = max(remTmp)
				sizeIndex = length(index)
				
				index = index [ -remTmp ]
				
				if (minIndex == 1)
				{
					# If taking from beginning
					indexDiff = indexDiff[ -remTmp ]
					
				} else if (maxIndex == sizeIndex)
				{
					# If taking from the end
					indexDiff = indexDiff[ -(remTmp - 1) ]
				} else
				{
					# If taking form the middle
					indexDiff = indexDiff[ -(remTmp - 1) ]
					indexDiff[ minIndex - 1 ] = maximumDistIbs1 + 1
				}
			} else
			{
				# Do this if no SNPs fall into the region.
				# Try to pull out the SNPs that are just before, and just after. Adjust diff to prevent block crossing
				low = max (which (index <= blockStarts[i]))
				high = min (which (index >= blockEnds[i]))
				if (low != high & high - low == 1)
				{
					indexDiff[low] = maximumDistIbs1 + 1
				}
			}
		}
	}
	
	if (length(index) >= minIbs1)
	{
		listHolder = DiffLoop(indexDiff, maximumDistIbs1)
		startIndex = unlist(listHolder[1])
		endIndex = unlist(listHolder[2])
		
		# Pick out 
		numSnps = endIndex - startIndex + 1
		
		startIndex = startIndex[numSnps >= minIbs1]
		endIndex = endIndex[numSnps >= minIbs1]
		
		if (length(startIndex) > 0 && length(endIndex) > 0)
		{
			for (i in 1:length(startIndex))
			{
				blockStarts[blockIndex] = index[startIndex[i]]
				blockEnds[blockIndex] = index[endIndex[i]]
				blockType[blockIndex] = "IBS1"
				blockCount = blockCount + 1
				blockIndex = blockIndex + 1
			}
		}
	}
	#### #### #### #### #### #### #### #### #### #### #### #### #### #### #### #### #### #### #### #### ####
	#  # #  # #  # #  # #  # #  # #  # #  # #  # #  # #  # #  # #  # #  # #  # #  # #  # #  # #  # #  # #  #
	#### #### #### #### #### #### #### #### #### #### #### #### #### #### #### #### #### #### #### #### ####
	#IBS2
	index = which(ibs == 2)
	indexDiff = diff(index)
	
	if (blockCount > 0)
	{
		rem = integer()
		# Find and remove SNPs already in the blocks
		for (i in 1:blockCount)
		{
			remTmp = which(index >= blockStarts[i] & index <= blockEnds[i])
			if (length(remTmp) > 0)
			{
				minIndex = min(remTmp)
				maxIndex = max(remTmp)
				sizeIndex = length(index)
				
				index = index [ -remTmp ]
				
				if (minIndex == 1)
				{
					# If taking from beginning
					indexDiff = indexDiff[ -remTmp ]
					
				} else if (maxIndex == sizeIndex)
				{
					# If taking from the end
					indexDiff = indexDiff[ -(remTmp - 1) ]
				} else
				{
					# If taking form the middle
					indexDiff = indexDiff[ -(remTmp - 1) ]
					indexDiff[ minIndex - 1 ] = maximumDistIbs2 + 1
				}
			} else
			{
				# Do this if no SNPs fall into the region.
				# Try to pull out the SNPs that are just before, and just after. Adjust diff to prevent block crossing
				low = max (which (index <= blockStarts[i]))
				high = min (which (index >= blockEnds[i]))
				if (low != high & high - low == 1)
				{
					indexDiff[low] = maximumDistIbs2 + 1
				}
			}
		}
	}
	
	if (length(index) >= minIbs2)
	{
		listHolder = DiffLoop(indexDiff, maximumDistIbs2)
		startIndex = unlist(listHolder[1])
		endIndex = unlist(listHolder[2])
		
		# Pick out 
		numSnps = endIndex - startIndex + 1
		
		startIndex = startIndex[numSnps >= minIbs2]
		endIndex = endIndex[numSnps >= minIbs2]
		
		if (length(startIndex) > 0 && length(endIndex) > 0)
		{
			for (i in 1:length(startIndex))
			{
				blockStarts[blockIndex] = index[startIndex[i]]
				blockEnds[blockIndex] = index[endIndex[i]]
				blockType[blockIndex] = "IBS2"
				blockCount = blockCount + 1
				blockIndex = blockIndex + 1
			}
		}
	}
	
	#### #### #### #### #### #### #### #### #### #### #### #### #### #### #### #### #### #### #### #### ####
	#  # #  # #  # #  # #  # #  # #  # #  # #  # #  # #  # #  # #  # #  # #  # #  # #  # #  # #  # #  # #  #
	#### #### #### #### #### #### #### #### #### #### #### #### #### #### #### #### #### #### #### #### ####
	# Aberration
	ibs0Index = which(blockType == "IBS0")
	if (length(ibs0Index) > 0)
	{
		allIbs1 = which(ibs == 1)
		for (i in 1:length(ibs0Index))
		{
			snps = blockEnds[i] - blockStarts[i]
			ibs1count = length( which(allIbs1 >= blockStarts[i] & allIbs1 <= blockEnds[i]))
			percIbs1 = ibs1count / snps
			
			if (percIbs1 < 0.10)
			{
				blockType[i] = "Aberration"
			}
		}
	}
	
	tmp = data.frame(StartPosition = position[blockStarts[1:blockCount]], EndPosition = position[blockEnds[1:blockCount]], Type = blockType[1:blockCount])
	tmp = tmp[ order(tmp$StartPosition) , ]
	
	# Print output to temporary file
	cat(Ind1,"\n", file=File, append=Append)
	cat(Ind2,"\n", file=File, append=TRUE)
	cat(chromosome,"\n", file=File, append=TRUE)
	write.table(tmp, file=File, append=TRUE, sep=",", quote=FALSE, row.names=FALSE, col.names=FALSE)
	cat("///\n", file=File, append=TRUE)
}

########################################
# plotBlocks
# print images of blocks
########################################
plotBlocks = function (...)
{
	plot.new()
	plot.window(ylim=c(-0.5,2.5), xlim=c(0, max(position)))
	title(ylab="Physical Position", xlab="Block Type")
	axis(2,at=c(0,1,2), las=1)
	axis(1)
	box()
	
	# IBS0
	ibs0Index = which(blockType == "IBS0")
	if (length(ibs0Index) > 0)
	{
		rect(position[blockStarts[ibs0Index]], rep(plot.min, length(ibs0Index)), position[blockEnds[ibs0Index]], rep(plot.max,length(ibs0Index)), col="orangered", lwd=1)
	}
	# IBS1
	ibs1Index = which(blockType == "IBS1")
	if (length(ibs1Index) > 0)
	{
		rect(position[blockStarts[ibs1Index]], rep(plot.min+1, length(ibs1Index)), position[blockEnds[ibs1Index]], rep(plot.max+1,length(ibs1Index)), col="cadetblue", lwd=1)
	}
	# IBS2
	ibs2Index = which(blockType == "IBS2")
	if (length(ibs2Index) > 0)
	{
		rect(position[blockStarts[ibs2Index]], rep(plot.min+2, length(ibs2Index)), position[blockEnds[ibs2Index]], rep(plot.max+2,length(ibs2Index)), col="springgreen", lwd=1)
	}
	# Aberration
	ibsAbIndex = which(blockType == "Aberration")
	if (length(ibsAbIndex) > 0)
	{
		rect(position[blockStarts[ibsAbIndex]], rep(plot.min, length(ibsAbIndex)), position[blockEnds[ibsAbIndex]], rep(plot.max,length(ibsAbIndex)), col="purple", lwd=1)
	}
	
}

########################################
# plotBlocks
# print images of blocks
########################################
MeanSDFromCounts = function (ibsCounts)
{
	size = dim(ibsCounts)[1]
	summaryStat = matrix(nrow = size, ncol = 2)
	colnames (summaryStat) = c("Mean_IBS", "SD_IBS")
	
	for (i in 1:size)
	{
		summaryStat[i,"Mean_IBS"] = ( (ibsCounts[i, "IBS2"] * 2) + ibsCounts[i, "IBS1"]) / sum( ibsCounts[i, "IBS2"], ibsCounts[i, "IBS1"],ibsCounts[i, "IBS0"]) # Mean
		summaryStat[i, "SD_IBS"] = sqrt( ( ( ( (2 - summaryStat[i, "Mean_IBS"]) ^ 2) * ibsCounts[i, "IBS2"]) + ( ( (1 - summaryStat[i, "Mean_IBS"]) ^ 2) * ibsCounts[i, "IBS1"]) + ( ( (0 - summaryStat[i, "Mean_IBS"]) ^ 2) * ibsCounts[i, "IBS0"])) / (sum (ibsCounts[i, "IBS2"],ibsCounts[i, "IBS1"], ibsCounts[i, "IBS0"]))) # Standard Deviation
	}
	
	return(summaryStat)
}
