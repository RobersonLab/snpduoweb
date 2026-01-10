#########################
#  SNPduoFunctions.R    #
#  Author: Eli Roberson #
#########################

###########################################
# load_chromosome_features                #
#                                         #
# Load binary saves of centromere,        #
# telomere, and heterochromatin locations #
# for different genome builds             #
###########################################
load_chromosome_features = function( compiled, genomebuild )
{  
  
  build_file = paste0( genomebuild, 'cytoband.Rbin' )
  build_path = file.path( compiled, build_file )
  
  if ( file.exists( build_path ) ) {
    load( file = build_path )
  } else {
    stop( 
      paste( "The indicated genome build", 
             genomebuild, 
             "was not found. Please try again.\n" )
      )
  }
  
  #######################################################
  # If the objects didn't load correctly throw an error #
  #######################################################
  if( !exists( "cytoband" ) )
  {
    stop( "Cytoband locations did not load properly" )
  }

  return( cytoband )
}

##########################################################
# Load offsets                                           #
# Load chromosome offsets for genome plot based on build #
##########################################################
load_chromosome_position_offsets = function( compiled, genomebuild )
{
  # Offsets go from 1-25. 1-22 are autosomes.
  # 23 = X. 24 = Y. 25 = M.
  load( file.path( compiled, "offsets.Rbin" ) )
  
  if ( !exists( "offsets" ) )
  {
    stop("Offset information couldn't be loaded for genome plot!!!")
  }
  
  good_offset = offsets[,genomebuild]
  
  if ( !exists("good_offset") || is.null( good_offset ) )
  {
    stop( "Build not found in offsets!!!" )
  }
  
  return( good_offset )
}

################################
# get_maximum_cytoband_end     #
#                              #
# Maximum of the cytoband data #
################################
get_maximum_cytoband_end = function( chromosome, cytobandInfo )
{
  chrom_name = paste0( 'chr', chromosome )
  
  chromosome_index = which( cytobandInfo$chrom == chrom_name )
  
  if ( length( chromosome_index ) > 0 )
  {
    return( max( cytobandInfo$chromEnd[chromosome_index] ) )
  }
  
  return( 0 )
}

############################################
# draw_cytobands                           #
#                                          #
# Use cytoband data loaded for the current #
# build to draw cytobands on an image.     #
############################################
draw_cytobands = function( chromosome, cytoband, drawLabels = TRUE, miny = 0, maxy = 2 )
{
  stainColors = c( "gneg" = "grey100", 
                   "gpos25" = "grey90", 
                   "gpos50" = "grey70", 
                   "gpos75" = "grey40", 
                   "gpos100" = "grey0", 
                   "gvar" = "grey95", 
                   "stalk" = "brown3", 
                   "acen" = "brown4" )
  
  textColors = c( "gneg" = "black", 
                  "gpos25" = "black", 
                  "gpos50" = "black", 
                  "gpos75" = "black", 
                  "gpos100" = "white", 
                  "gvar" = "black", 
                  "stalk" = "white", 
                  "acen" = "white" )
  
  rangeY = maxy - miny
  quarterRange = rangeY / 4
  
  numBands = which( cytoband$chrom == paste("chr", chromosome, sep = "") )
  
  type = "left"
  
  if ( length( numBands ) > 0 )
  {
    for ( i in 1:length( numBands ) )
    {      
      curr = numBands[i]
      
      stain = cytoband$gieStain[curr]
      color = stainColors[stain]
      
      start.cyto = cytoband$chromStart[curr]
      end.cyto = cytoband$chromEnd[curr]
      size = end.cyto - start.cyto
      
      if ( i == 1 || ( ( stain == "acen" ) && ( type == "left" ) ) )
      {        
        secondPoint = start.cyto + ( size / 5 )
        
        polygon( c( start.cyto, start.cyto, secondPoint, end.cyto, end.cyto, secondPoint ), c( miny + quarterRange, maxy - quarterRange, maxy, maxy, miny, miny ), col = color )
        
        type = "right"
        
      } else if ( i == length(numBands) || ( ( stain == "acen" ) && ( type == "right" ) ) )
      {
        secondPoint = end.cyto
        end.cyto = end.cyto - ( size / 5 )
        
        polygon( c( start.cyto, start.cyto, end.cyto, secondPoint, secondPoint, end.cyto), c(miny, maxy, maxy, maxy-quarterRange, miny + quarterRange, miny ), col = color )
        type = "left"
      } else
      {
        polygon( c( start.cyto, start.cyto, end.cyto, end.cyto ), c( miny, maxy, maxy, miny ), col = color )
      }
      
      ##############################
      # Do text for cytobands here #
      ##############################
      if ( drawLabels == TRUE )
      {
        chrSize = get_maximum_cytoband_end( chromosome, cytoband )
        
        if ( ( size / chrSize ) >= 0.02 )
        {
          bandName = cytoband[curr, "name"]
          
          textColor = textColors[stain]
          
          text( x = start.cyto + ( size / 2 ) , y = miny + ( rangeY / 2 ), srt = 90, paste( bandName ), col = textColor )
        }
      }
    }
  }
}

##########################################
# Label Chromosomes                      #
#                                        #
# Places labels for each chromosome on   #
# plots where the whole genome is viewed #
# on one image.                          #
##########################################
chromosome_labeling = function( chr.offset, yvalue )
{
  ######################################################################################################
  # A function that simply places labels for each chromosome in the plot with the genome in one frame. #
  ######################################################################################################
  num.rows = length( chr.offset )
  plot.text = c( 1:22, "X" )
  
  for ( i in 2:num.rows )
  {
    text( ( ( chr.offset[i] + chr.offset[(i - 1)]) / 2) , yvalue, plot.text[i - 1], cex = 0.95 )
  }
}

##########################################
# jitter_for_wig                         #
#                                        #
# BED Jitter                             #
# Function used to created jittered data #
# for creating a BED file output.        #
##########################################
jitter_for_wig = function ( toJitter, amountJitter = 0.15 )
{
  toJitter = gsub( 2, ( 2 - amountJitter ), toJitter )
  toJitter = gsub( 0, ( 0 + amountJitter ), toJitter )
  
  if ( !is.numeric( toJitter ) )
  {
    toJitter = as.numeric( toJitter )
  }
  
  toJitter = jitter( toJitter, amount = amountJitter )
  
  return( round( toJitter, 3 ) )
}

############################################
# c_code_ibs_calculation                   #
#                                          #
# R function to run SNPduo IBS comparisons #
# in C code.                               #
############################################
c_code_ibs_calculation = function( genotypeVector1, genotypeVector2 )
{  
  ################################################################################
  # Get number of SNPs to compar and vectorize the SNP data if it isn't already. #
  ################################################################################
  if ( is.null( dim( genotypeVector1 ) ) )
  {
    size = length( genotypeVector1 )
  } else
  {
    genotypeVector1 = genotypeVector1[,1]
    size = length( genotypeVector1 )
  }
  
  if ( !is.null( dim( genotypeVector2 ) ) )
  {
    genotypeVector2 = genotypeVector2[,1]
  }
  
  #######################
  # Replace NAs with 0s #
  #######################
  genotypeVector1[ is.na(genotypeVector1) ] = 0
  genotypeVector2[ is.na(genotypeVector2) ] = 0
  
  ##########################################################################################
  # Preallocate memory and set to a value you should never get so it can be removed later. #
  ##########################################################################################
  tmp = integer( size )
  tmp[] = -5
  
  ############################################################
  # Call the compiled C function to do the actual comparison #
  ############################################################
  CReturn = .C( "SNPScore",
  csize = as.integer( size ),
  cgeno1 = as.integer( genotypeVector1 ),
  cgeno2 = as.integer( genotypeVector2 ),
  cscore = as.integer( tmp ),
  ibs2count = as.integer( 0 ),
  ibs1count = as.integer( 0 ),
  ibs0count = as.integer( 0 ),
  ind1AA = as.integer( 0 ),
  ind1AB = as.integer( 0 ),
  ind1BB = as.integer( 0 ),
  ind1NC = as.integer( 0 ),
  ind2AA = as.integer( 0 ),
  ind2AB = as.integer( 0 ),
  ind2BB = as.integer( 0 ),
  ind2NC = as.integer( 0 ) )
  
  #######################################################################
  # Remove any pesky placeholders that remain and replace them with NAs #
  #######################################################################
  CReturn$cscore[ CReturn$cscore == -5 ] = NA
  
  ###################################################################################################################
  # Return all of the IBS calls, IBS counts, and genotype counts in the form of a list which is easier to deal with #
  ###################################################################################################################
  return( list( 'ibsState'=CReturn$cscore, 'ibs2count'=CReturn$ibs2count, 'ibs1count'=CReturn$ibs1count, 'ibs0count'=CReturn$ibs0count, 'ind1aa'=CReturn$ind1AA, 'ind1ab'=CReturn$ind1AB, 'ind1bb'=CReturn$ind1BB, 'ind1nc'=CReturn$ind1NC, 'ind2aa'=CReturn$ind2AA, 'ind2ab'=CReturn$ind2AB, 'ind2bb'=CReturn$ind2BB, 'ind2nc'=CReturn$ind2NC ) )
}

###########################################
# genotypes_to_integers                   #
#                                         #
# Convert alpha type genotypes to numeric #
###########################################
genotypes_to_integers = function( genotypes )
{  
  ###############################################
  # Convert No Calls (either NC or NoCall) to 0 #
  # AA to 1, AB to 2, BB to 3                   #
  # Then turn any NAs into 0s.                  #
  ###############################################
  if ( !is.character( genotypes ) )
  {
    genotypes = as.character( genotypes )
  }
  
  codedGenotypes = integer( length( genotypes ) )
  
  codedGenotypes[ genotypes == "AA" ] = 1
  codedGenotypes[ genotypes == "AB" ] = 2
  codedGenotypes[ genotypes == "BB" ] = 3
  
  return( codedGenotypes )
}

##########################################
# draw_genome_chromosome_boundaries      #
#                                        #
# When genome is plotted in single frame #
# this function is used to plot vertical #
# lines at chromosome boundaries.        #
##########################################
draw_genome_chromosome_boundaries = function( chr.offset, plot.min, plot.max )
{
  for ( i in 2:24 )
  {
    lines( c ( rep ( chr.offset[i], 2 ) ), c( plot.min, plot.max ) )
  }
}

###############################################
# chrom_convert_to_integer                    #
#                                             #
# Converts chromosomes into                   #
# numeric form by testing to see if they      #
# are numeric. If not, then they are tested   #
# as characters and converted if they are     #
# not character class. Then finally converted #
# to numerics.                                #
###############################################
chrom_convert_to_integer = function( charChromosomes )
{
  if ( !is.numeric( charChromosomes ) )
  {  
    if ( !is.character( charChromosomes ) )
    {
      charChromosomes = as.character( charChromosomes )
    }
    
    charChromosomes[charChromosomes == "X"] = 23
    charChromosomes[charChromosomes == "Y"] = 24
    charChromosomes[charChromosomes %in% c( "M", "MITO", "MT", "Mito" )] = 25
    
    return( as.integer( charChromosomes ) )
  } else 
  {
    return( charChromosomes )
  }
}

#####################################
# tick_marks_and_axis_labels        #
#                                   #
# Function to find where tick marks #
# should go on a plot and what axis #
# label is most appropriate         #
#####################################
tick_marks_and_axis_labels = function( total )
{
  if ( total >= 1000000 )
  {
    adjustment = 1000000
    plotlabel = "(Mb)"
  } else
  {
    adjustment = 1000
    plotlabel = "(Kb)"
  }
  
  if ( adjustment == 1000000 )
  {    
    if ( total > 2000000000 )
    {
      bases = 200
    } else if ( total > 200000000 )
    {
      bases = 20
    } else if ( total > 100000000 )
    {
      bases = 10
    } else
    {
      bases = 5
    }
  }
  
  if ( adjustment == 1000 )
  {
    bases = 1
  }

  bases = bases * adjustment
  
  ticks = seq( 0, total, by = bases )
  
  maxtick = max( ticks )
  
  if( ( total - maxtick ) >= ( bases / 2 ) )
  {
    ticks = c( ticks, ( maxtick + bases ) )
  }
  
  ticklabel = ticks / adjustment
  
  return( list( 'ticks'=ticks, 'labels'=ticklabel, 'plotLabel'=plotlabel ) )
}

###########################
# mean_and_sd_from_counts #
###########################
mean_and_sd_from_counts = function( ibsCounts )
{
  size = dim( ibsCounts )[1]
  summaryStat = matrix( nrow = size, ncol = 2 )
  colnames( summaryStat ) = c( "Mean_IBS", "SD_IBS" )
  
  for ( i in 1:size )
  {
    numIbs2 = ibsCounts[i, "IBS2"]
    numIbs1 = ibsCounts[i, "IBS1"]
    numIbs0 = ibsCounts[i, "IBS0"]
    numberCounts = sum( numIbs2, numIbs1, numIbs0 )
    
    meanVal = ( ( numIbs2 * 2 ) + numIbs1 ) / numberCounts
    summaryStat[ i,"Mean_IBS" ] = meanVal
    
    ibs2part = ( ( 2 - meanVal ) ^ 2 ) * numIbs2
    ibs1part = ( ( 1 - meanVal ) ^ 2 ) * numIbs1
    ibs0part = ( ( 0 - meanVal ) ^ 2 ) * numIbs0
    summaryStat[ i, "SD_IBS" ] = sqrt( ( ibs2part + ibs1part + ibs0part ) / ( numberCounts - 1 ) ) # Standard Deviation
  }
  
  return( summaryStat )
}

###########################################
# Diff Loop                               #
# Function used in block finding protocol #
###########################################
diff_blockify = function( diffIndex, maximumDist )
{
  # Set up index holders and calculate of vector to keep from recalculating
  size = length( diffIndex )
  startPos = size
  endPos = 0
  
  # make holders for index
  startIndex = integer( 0 )
  endIndex = integer( 0 )
  
  # test to find blocks
  for ( i in 1:size )
  {
    if ( diffIndex[i] < maximumDist )
    {
      if ( i < startPos )
      {
        startPos = i
      } 
      if ( i > endPos )
      {
        endPos = i
      }
    }
    
    # If you reach an boundary (block greater than certain distance)
    if ( diffIndex[i] >= maximumDist | i == size )
    {
      if ( ( endPos != 0 ) & ( startPos != size ) & ( endPos != startPos ) )
      {
        startIndex = c( startIndex, startPos )
        endIndex = c( endIndex, endPos + 1 )
      }
      
      startPos = size
      endPos = 0
    }    
  }
  
  return( list( 'starts'=startIndex, 'ends'=endIndex ) )
}

########################
# remove_called_blocks #
########################
remove_called_blocks = function( index, indexDiff, blockStarts, blockEnds )
{
  blockCount = length( blockStarts )
  
  if ( blockCount > 0 )
  {
    for ( i in 1:blockCount )
    {
      remTmp = which( index >= blockStarts[i] & index <= blockEnds[i] )
      
      if ( length( remTmp ) > 0 )
      {
        minIndex = min( remTmp )
        maxIndex = max( remTmp )
        sizeIndex = length( index )
        
        index = index [ -c( remTmp ) ]
        
        if ( minIndex == 1 | maxIndex == sizeIndex )
        {
          # If taking from beginning
          #indexDiff = indexDiff[ -c( remTmp ) ]
          indexDiff = diff( index )
        } else
        {
          # If taking from the middle
          indexDiff = indexDiff[ -c(remTmp) ]
          indexDiff[ minIndex - 1 ] = Inf
        }
      }
    }
  }
  
  return( list( "newIndex"=index, "newIndexDiff"=indexDiff ) )
}

########################################
# segment_ibs_blocks                   #
# Front end function for block finding #
########################################
segment_ibs_blocks = function ( ibs, position, chromosome, maximumDist = NULL, minIbs0 = NULL, minIbs1 = NULL, minIbs2 = NULL, Ind1=NULL,Ind2=NULL, AppendLogical=FALSE, File=NULL, minNumberSites=5 )
{
  if ( length( ibs ) >= minNumberSites )
  {  
    blockStarts = integer(0)
    blockEnds = integer(0)
    blockType = character(0)
    
    ibs = ibs[ order( position ) ]
    position = position[ order( position ) ]
    
    size = length( ibs )
    
    maximumDistIbs0 = 0.0175 * size
    maximumDistIbs1 = 0.015 * size
    maximumDistIbs2 = 0.005 * size
    
    if ( maximumDistIbs0 < 5 ) { maximumDistIbs0 = 5 }
    if ( maximumDistIbs1 < 5 ) { maximumDistIbs1 = 5 }
    if ( maximumDistIbs2 < 5 ) { maximumDistIbs2 = 5 }
    
    #################################
    count0 = length( which( ibs == 0 ) ) 
    count1 = length( which( ibs == 1 ) )
    count2 = length( which( ibs == 2 ) )
    
    ##### Consider changing to be reflective of IBS type. Example: minIbs2 = 0.20 * count2
    if ( is.null( minIbs0 ) ) { minIbs0 = 0.0075 * count0 }
    if ( is.null( minIbs1 ) ) { minIbs1 = 0.0075 * count1 }
    if ( is.null( minIbs2 ) ) { minIbs2 = 0.0075 * count2 }
    if ( minIbs0 < 5 ) { minIbs0 = 5 }
    if ( minIbs1 < 5 ) { minIbs1 = 5 }
    if ( minIbs2 < 5 ) { minIbs2 = 5 }
    
    #### #### #### #### #### #### #### #### #### #### #### #### #### #### #### #### #### #### #### #### ####
    #  # #  # #  # #  # #  # #  # #  # #  # #  # #  # #  # #  # #  # #  # #  # #  # #  # #  # #  # #  # #  #
    #### #### #### #### #### #### #### #### #### #### #### #### #### #### #### #### #### #### #### #### ####
    # IBS0
    index = which( ibs == 0 )
    indexDiff = diff( index )
    
    if ( length( index ) >= minIbs0 )
    {
      listHolder = diff_blockify( indexDiff, maximumDistIbs0 )
      startIndex = listHolder[['starts']]
      endIndex = listHolder[['ends']]
      
      numSnps = endIndex - startIndex + 1
      
      startIndex = startIndex[numSnps >= minIbs0]
      endIndex = endIndex[numSnps >= minIbs0]
      
      numBlocks = length( startIndex )
      
      if ( numBlocks > 0 )
      {
        blockStarts = c( blockStarts, index[startIndex] )
        blockEnds = c( blockEnds, index[endIndex] )
        blockType = c( blockType, rep( "IBS0", numBlocks ) )
      }
    }
    
    #### #### #### #### #### #### #### #### #### #### #### #### #### #### #### #### #### #### #### #### ####
    #  # #  # #  # #  # #  # #  # #  # #  # #  # #  # #  # #  # #  # #  # #  # #  # #  # #  # #  # #  # #  #
    #### #### #### #### #### #### #### #### #### #### #### #### #### #### #### #### #### #### #### #### ####
    #IBS1
    index = which( ibs == 1 )
    indexDiff = diff( index )
    
    fixedIndexes = remove_called_blocks( index, indexDiff, blockStarts, blockEnds )
    
    index = fixedIndexes[["newIndex"]]
    indexDiff = fixedIndexes[["newIndexDiff"]]
    
    if ( length( index ) >= minIbs1 )
    {
      listHolder = diff_blockify( indexDiff, maximumDistIbs1 )
      startIndex = listHolder[['starts']]
      endIndex = listHolder[['ends']]
      
      numSnps = endIndex - startIndex + 1
      
      startIndex = startIndex[numSnps >= minIbs1]
      endIndex = endIndex[numSnps >= minIbs1]
      
      numBlocks = length( startIndex )
      
      if ( numBlocks > 0 )
      {
        blockStarts = c( blockStarts, index[startIndex] )
        blockEnds = c( blockEnds, index[endIndex] )
        blockType = c( blockType, rep( "IBS1", numBlocks ) )
      }
    }
    
    #### #### #### #### #### #### #### #### #### #### #### #### #### #### #### #### #### #### #### #### ####
    #  # #  # #  # #  # #  # #  # #  # #  # #  # #  # #  # #  # #  # #  # #  # #  # #  # #  # #  # #  # #  #
    #### #### #### #### #### #### #### #### #### #### #### #### #### #### #### #### #### #### #### #### ####
    #IBS2
    index = which( ibs == 2 )
    indexDiff = diff( index )
    
    fixedIndexes = remove_called_blocks( index, indexDiff, blockStarts, blockEnds )
    
    index = fixedIndexes[["newIndex"]]
    indexDiff = fixedIndexes[["newIndexDiff"]]
    
    if ( length( index ) >= minIbs2 )
    {
      listHolder = diff_blockify( indexDiff, maximumDistIbs2 )
      startIndex = listHolder[['starts']]
      endIndex = listHolder[['ends']]
      
      numSnps = endIndex - startIndex + 1
      
      startIndex = startIndex[numSnps >= minIbs2]
      endIndex = endIndex[numSnps >= minIbs2]
      
      numBlocks = length( startIndex )
      
      if ( numBlocks > 0 )
      {
        blockStarts = c( blockStarts, index[startIndex] )
        blockEnds = c( blockEnds, index[endIndex] )
        blockType = c( blockType, rep( "IBS2", numBlocks ) )
      }
    }
    
    #### #### #### #### #### #### #### #### #### #### #### #### #### #### #### #### #### #### #### #### ####
    #  # #  # #  # #  # #  # #  # #  # #  # #  # #  # #  # #  # #  # #  # #  # #  # #  # #  # #  # #  # #  #
    #### #### #### #### #### #### #### #### #### #### #### #### #### #### #### #### #### #### #### #### ####
    # Aberration
    ibs0Index = which( blockType == "IBS0" )
    if ( length( ibs0Index ) > 0 )
    {
      allIbs1 = which( ibs == 1 )
      
      for ( i in 1:length( ibs0Index ) )
      {
        snps = blockEnds[i] - blockStarts[i]
        ibs1count = length( which( allIbs1 >= blockStarts[i] & allIbs1 <= blockEnds[i] ) )
        percIbs1 = ibs1count / snps
        
        if (percIbs1 < 0.10)
        {
          blockType[i] = "Aberration"
        }
      }
    }
    
    tmp = data.frame( StartPosition = position[blockStarts], EndPosition = position[blockEnds], Type = blockType )
    tmp = tmp[ order( tmp$StartPosition ), ]
    
    # Print output to temporary file
    cat( Ind1,"\n", file=File, append=AppendLogical )
    cat( Ind2,"\n", file=File, append=TRUE )
    cat( chromosome,"\n", file=File, append=TRUE )
    write.table(tmp, file=File, append=TRUE, sep=",", quote=FALSE, row.names=FALSE, col.names=FALSE )
    cat("///\n", file=File, append=TRUE )
  }
}

#############################################
#  snpduo_single_chromosome                 #
#                                           #
#  Function to plot a single chromosome     #
#  Used for single chromosome comparisons   #
#  and for Genome By Chromosome comparisons #
#############################################
snpduo_single_chromosome = function( genotypeData, chromosome, ind1, ind2, savename, pagewidth, pageheight, bychromosome = FALSE, cexScale = 0.20, comparison = "None", pchValue=20,doPostscript = TRUE, makeBED = TRUE, doPNG=FALSE, DPI=72, THUMBNAIL=FALSE )
{  
  if ( !doPNG & THUMBNAIL ) { THUMBNAIL = FALSE } # We only allow thumbnail generation if doPNG is set
  
  ###############################################################
  # Find the columns containing chromosome and position by grep #
  ###############################################################
  pos = grep( "Physical.Position", names( genotypeData ) )
  chr = grep( "Chromosome", names( genotypeData ) )
  
  #################################################################
  # R converts spaces to dots. For printing gsub dots for spaces. #
  #################################################################
  printInd1 = gsub( "\\.", " ", names( genotypeData )[ind1] )
  printInd2 = gsub( "\\.", " ", names( genotypeData )[ind2] )
  
  ###############
  # Error check #
  ###############
  if ( length( pos ) < 1 )
  {
    stop( "Position column not found" )
  }
  
  if ( length( chr ) < 1 )
  {
    stop( "Chromosome column not found" )
  }
    
  ####################################################
  # Find which rows match the chromosome of interest #
  ####################################################
  if ( chromosome != "M" ) {
    currIndex = which( genotypeData[,chr] == chromosome )
  } else
  {
    currIndex = which( genotypeData[,chr] %in% c( "M", "MT", "Mito", "MITO" ) )
  }
  
  ###############
  # Error check #
  ###############
  if ( length( currIndex ) < 1 )
  {
    stop( paste( "Problem subsetting data. You specified chromosome", chromosome, "but it can't be found in your data" ) )
  }
    
  ##################################################################################################
  # Subset the data so that only the part containing the chromosome you are interested in is used. #
  ##################################################################################################
  curr = genotypeData[currIndex,]
  
  ################################################################################################
  # For numeric chromosomes make sure they are in numeric form by running chrom_convert_to_integer function #
  ################################################################################################
  if ( chromosome != "X" && chromosome != "Y" && chromosome != "M" && chromosome != "MT" && chromosome != "Mito" && chromosome != "MITO" && chromosome != "XY" ) {
    chromosome = chrom_convert_to_integer( chromosome )
  }
  
  #################################################
  # Pull the physical position data into a vector #
  #################################################
  physPos = curr[,pos]
  
  ##########################################
  # Make sure physical position is numeric #
  ##########################################
  if( !is.numeric( physPos ) )
  {
    physPos = as.numeric( physPos )
  }
  
  ######################################
  # Vectorize the individual genotypes #
  ######################################
  gen1 = curr[,ind1]
  gen2 = curr[,ind2]
  
  ###########################################################################################################
  ## Pull some values to be written to the output file before they are manipulated from their standard form #
  ###########################################################################################################
  fortext = data.frame( "Chromosome" = chromosome, "Physical Position" = physPos, "IBS" = -1, "tmp1" = gen1, "tmp2" = gen2 )
  
  ######################################################################################################################
  # Substitute "alpha" genoytpes (AA, AB, BB, NC) for numeric genotypes for speed in comparisons using genotypes_to_integers function #
  ######################################################################################################################
  if ( !is.numeric( gen1 ) ) {
    gen1 = genotypes_to_integers( gen1 )
  }
  
  if ( !is.numeric( gen2 ) ) {
    gen2 = genotypes_to_integers( gen2 )
  } 
  
  #############################################################################################################
  # Score SNPs                                                                                                #
  # Passes genotypes to function that performs the passing of data from R to C and returns the proper fields. #
  #############################################################################################################
  Cdata = c_code_ibs_calculation( gen1, gen2 )
  
  ###################
  # Pull ibs scores #
  ###################
  ibsVector = Cdata[['ibsState']]
    
  ###########################
  # IBS Summary Information #
  ###########################
  ibs2 = Cdata[['ibs2count']]
  ibs1 = Cdata[['ibs1count']]
  ibs0 = Cdata[['ibs0count']]
  
  #########################
  # Calculate Average IBS #
  #########################
  avg.ibs = round( mean( ibsVector, na.rm=TRUE ), 3 )
  
  ################################
  # Genotype Summary Information #
  ################################
  ind1.AA = Cdata[['ind1aa']]
  ind1.AB = Cdata[['ind1ab']]
  ind1.BB = Cdata[['ind1bb']]
  ind1.NC = Cdata[['ind1nc']]

  ind2.AA = Cdata[['ind2aa']]
  ind2.AB = Cdata[['ind2ab']]
  ind2.BB = Cdata[['ind2bb']]
  ind2.NC = Cdata[['ind2nc']]
  
  if ( doPostscript == TRUE || doPNG == TRUE || THUMBNAIL == TRUE )
  {
    ###############################
    # Tick Marks                  #
    # Find maximum plotting point #
    ###############################
    maxpos = max( physPos )
    maxcytoband = get_maximum_cytoband_end( chromosome, cytoband )
    
    if ( maxpos < maxcytoband )
    {
      maxpos = maxcytoband
    }
    
    ##############################################################################################################
    # Use function find ticks to find tick mark position, number, and the proper x-axis label for the tick scale #
    # Also find the jittered placement of IBS and genotype, for consistency between PS and PNG                   #
    ##############################################################################################################
    ticks = tick_marks_and_axis_labels( maxpos )
    ticklabel = ticks[['labels']]
    posprefix = ticks[['plotLabel']]
    ticks = ticks[['ticks']]  
    
    max.tmp = maxpos
    max.ticks = max( ticks )
    
    if ( max.ticks > max.tmp )
    {
      max.tmp = max.ticks
    }
    
    ibs.jittered = jitter( ibsVector, amount = 0.20 ) + 13
    gen1.jittered = jitter( gen1, amount = 0.20 ) + 8
    gen2.jittered = jitter( gen2, amount = 0.20 ) + 3
    
    # A new trick to get the PNG and postscript to print the same thing if asked
    while ( doPostscript == TRUE || doPNG == TRUE || THUMBNAIL == TRUE )
    {
      # Postscript
      # Set paper size bases on page input. Name the file appropriately for single chromosome versus genome by chromosome
      if ( bychromosome )
      {
        if ( doPostscript )
        {
          postscript( file=paste(savename,"chr", chromosome, "_", comparison, ".ps", sep=""), paper="special", width=pagewidth, height=pageheight, horizontal=TRUE )
        } else if ( doPNG )
        {
          png( filename=paste(savename,"chr", chromosome, "_", comparison, ".png", sep=""), width=round(pagewidth * DPI,0), height=round(pageheight*DPI,0), units="px", bg="white", type="cairo", antialias="default", res=DPI )
        } else if ( THUMBNAIL )
        {
          png( filename=paste(savename,"chr", chromosome, "thumb_", comparison, ".png", sep=""), width=124, height=96, units="px", bg="white", type="cairo", antialias="default", res=DPI, pointsize=1 )
        }
      } else
      {
        if ( doPostscript )
        {
          postscript( file=paste(savename,"_", comparison,".ps", sep=""), paper="special", width=pagewidth, height=pageheight, horizontal=TRUE )
        } else if (doPNG)
        {
          png( filename=paste(savename,"_", comparison,".png", sep=""), width=round(pagewidth * DPI,0), height=round(pageheight*DPI,0), units="px", bg="white", type="cairo", antialias="default", res=DPI )
        }
      }
      
      plot.min = 0
      plot.max = 16
      par( "mar" = c( 5, 4, 4, 5 ) + 0.1 )
      plot.new()
      plot.window( xlim = c( 1, max.tmp ), ylim = c( plot.min, plot.max ) )
      title( paste( "Chromosome ", chromosome, " SNPduo Output\n", printInd1, " - ", printInd2, "\nAverage IBS: ", avg.ibs,sep="" ) )
      title( xlab = paste( "Physical Position", posprefix ) )
      
      points( physPos, ibs.jittered, cex = cexScale, pch = pchValue )
      points( physPos, gen1.jittered, cex = cexScale, pch = pchValue )
      points( physPos, gen2.jittered, cex = cexScale, pch = pchValue )
      draw_cytobands( chromosome, cytoband, miny = 0, maxy = 2 )
      axis( 1, at = ticks, labels = as.character(ticklabel) )
      
      ibslab = c(0,1,2)
      genlab = c(0,1,2,3)
      axis( 2, at = c((genlab + 3)), labels = c("NC", "AA", "AB", "BB") , las = 1 )
      axis( 2, at = c((genlab + 8)), labels = c("NC", "AA", "AB", "BB") , las = 1 )
      axis( 2, at = c((ibslab + 13)), labels = c("0", "1", "2") , las = 1 )
      
      axis( 4, at = c((genlab + 3)), c(paste( format(ind2.NC,big.mark=",")), paste( format(ind2.AA,big.mark=",")), paste( format(ind2.AB,big.mark=",")), paste( format(ind2.BB,big.mark=","))), las = 1 )
      axis( 4, at = c((genlab + 8)), c(paste( format(ind1.NC,big.mark=",")), paste( format(ind1.AA,big.mark=",")), paste( format(ind1.AB,big.mark=",")), paste( format(ind1.BB,big.mark=","))), las = 1 )
      axis( 4, at = c((ibslab + 13)), c(paste( format(ibs0,big.mark=",")), paste( format(ibs1,big.mark=",")), paste( format(ibs2,big.mark=","))), las = 1 )
      
      ###############
      # Side labels #
      ###############
      mtext( "Genotype", line = 3,side = 2, at = 4.5, cex = 1.15 )
      mtext( "Genotype", line = 3,side = 2, at = 9.5, cex = 1.15 )
      mtext( "Identity by State", line = 3, side = 2, at = 14, cex = 1.15 )
      
      #################
      # Inside labels #
      #################
      text( x = max.tmp / 2, y = 12, paste(printInd1), cex = 1.05 )
      text( x = max.tmp / 2, y = 7, paste(printInd2), cex = 1.05 )
      
      ##########
      # Box it #
      ##########
      rect( 0, 2.4, max.tmp, 15.6 )
      
      dev.off()
      
      if ( doPostscript )
      {
        doPostscript = FALSE
      } else if ( doPNG )
      {
        doPNG = FALSE
      } else if ( THUMBNAIL )
      {
        THUMBNAIL = FALSE
      }
    }
  }
  
  ##############################################################################
  # Now write a text file summary                                              #
  # Genotypes -- make a data frame and put the individual data summaries in it #
  ##############################################################################
  genSummary = data.frame( "Genotype" = c("AA", "AB", "BB", "NoCall"),"ind1" = 0,"ind2" = 0 )
  
  genSummary[1,2] = ind1.AA
  genSummary[2,2] = ind1.AB
  genSummary[3,2] = ind1.BB
  genSummary[4,2] = ind1.NC

  genSummary[1,3] = ind2.AA
  genSummary[2,3] = ind2.AB
  genSummary[3,3] = ind2.BB
  genSummary[4,3] = ind2.NC

  ###########################################
  # IBS -- summary data frame for IBS types #
  ###########################################
  ibsSummary = data.frame("Alleles Identical by State" = c(0,1,2),"Counts" = 0)
  ibsSummary[1,2] = ibs0
  ibsSummary[2,2] = ibs1
  ibsSummary[3,2] = ibs2  
  
  #########################################
  # Write everything                      #
  # Put the proper data in the IBS column #
  #########################################
  fortext$IBS = ibsVector
  
  ##############################
  # Order by Physical Position #
  ##############################
  fortext = fortext[ order( fortext[,2] ), ]
  
  ###################################################################
  # Put the adjusted header names in the right places for each file #
  ###################################################################
  names( fortext )[4] = paste(printInd1)
  names( fortext )[5] = paste(printInd2)
  
  names( genSummary )[2] = paste( printInd1 )
  names( genSummary )[3] = paste( printInd2 )
  
  ######################################################################################################
  # Name the files appropriately bases on whether this is a single chromosome or genome by chromosome. #
  ######################################################################################################
  if ( !bychromosome )
  {  
    write.table( fortext, row.names = FALSE, quote = FALSE, file = paste( savename,"_", comparison, ".summary.txt", sep = "" ), sep = "\t" )
    if ( makeBED )
    {
      segment_ibs_blocks( ibs=ibsVector, position=physPos, chromosome=chromosome, Ind1=printInd1, Ind2=printInd2, File=paste(savename,"_", comparison,  ".bedsummary.txt", sep = "" ) )
    }
    write.table( genSummary, row.names = FALSE, quote = FALSE, file = paste( savename,"_", comparison, ".gensum", sep = "" ), sep = "\t" )
    write.table( ibsSummary, row.names = FALSE, quote = FALSE, file = paste( savename,"_", comparison, ".ibssum", sep = "" ), sep = "\t" )
  } else if ( bychromosome )
  {
    write.table( fortext, row.names = FALSE, quote = FALSE, file = paste( savename,"_", comparison,  ".summary.txt", sep="" ), sep="\t", col.names=FALSE, append=TRUE )
    if ( makeBED )
    {
      segment_ibs_blocks( ibs=ibsVector, position=physPos, chromosome=chromosome, Ind1=printInd1, Ind2=printInd2, File=paste( savename,"_", comparison,  ".bedsummary.txt", sep = "" ), AppendLogical=TRUE )
    }
    write.table( genSummary, row.names = FALSE, quote = FALSE, file = paste( savename, "chr", chromosome, "_", comparison, ".gensum", sep="" ), sep="\t" )
    write.table( ibsSummary, row.names = FALSE, quote = FALSE, file = paste( savename, "chr", chromosome, "_", comparison, ".ibssum", sep="" ), sep="\t" )
  }
}

########################################
# whole_genome_plot                    #
#                                      #
# Function to plot the whole genome on #
# a single image.                      #
########################################
whole_genome_plot = function( genotype_data, 
                              index_ind1, 
                              index_ind2, 
                              savename, 
                              pagewidth, 
                              pageheight, 
                              cexScale=0.20, 
                              comparison="None", 
                              pchValue=20, 
                              doPostscript=TRUE, 
                              makeBED = TRUE, 
                              doPNG=FALSE, 
                              DPI=72,
                              chr_offset=NULL )
{
  if ( is.null( chr_offset ) )
  {
    stop( "Chromosome offsets were not passed!!!" )
  }
  
  input_names <- colnames( genotype_data )
  
  index_position_col = grep( "Physical.Position", input_names )
  index_chrom_col = grep( "Chromosome", input_names )
  
  label_ind1 = gsub( "\\.", " ", input_names[index_ind1] )
  label_ind2 = gsub( "\\.", " ", input_names[index_ind2] )
  
  acceptable_chromosomes = c( 1:25, "X", "Y", "M" )
  index_usable_snps = which( genotype_data[,index_chrom_col] %in% acceptable_chromosomes )
  
  if (!(length(index_usable_snps) > 0)) {
    stop( "No chromosomes match expected values!!!" )
  }
  
  genotype_data = genotype_data[ index_usable_snps, ]
  
  fortext = data.frame( "Chromosome" = genotype_data[,index_chrom_col], 
                        "Physical Position" = genotype_data[,index_position_col], 
                        "IBS" = -1, 
                        "tmp1" = genotype_data[,index_ind1], 
                        "tmp2" = genotype_data[,index_ind2] )
  
  size = nrow( genotype_data )
    
  outputchroms = chrom_convert_to_integer( genotype_data[,index_chrom_col] )
  
  physPos = as.integer( genotype_data[,index_position_col] )
  physPos = physPos + chr_offset[outputchroms]

  gen1 = genotypes_to_integers( genotype_data[,index_ind1] )
  gen2 = genotypes_to_integers( genotype_data[,index_ind2] )
  
  ##############
  # Score SNPs #
  ##############
  Cdata = c_code_ibs_calculation( gen1, gen2 )
  
  ###################
  # Pull ibs scores #
  ###################
  ibsVector = Cdata[['ibsState']]
    
  ###########################
  # IBS Summary Information #
  ###########################
  ibs2 = Cdata[['ibs2count']]
  ibs1 = Cdata[['ibs1count']]
  ibs0 = Cdata[['ibs0count']]
  
  ###############
  # Average IBS #
  ###############
  avg_ibs = round( mean( ibsVector, na.rm = TRUE ), 3 )
  
  ################################
  # Genotype Summary Information #
  ################################
  ind1_AA = Cdata[['ind1aa']]
  ind1_AB = Cdata[['ind1ab']]
  ind1_BB = Cdata[['ind1bb']]
  ind1_NC = Cdata[['ind1nc']]

  ind2_AA = Cdata[['ind2aa']]
  ind2_AB = Cdata[['ind2ab']]
  ind2_BB = Cdata[['ind2bb']]
  ind2_NC = Cdata[['ind2nc']]
  
  if ( doPostscript == TRUE || doPNG == TRUE )
  {
    ##############
    # Tick Marks #
    ##############
    maxpos = max( chr_offset[25] ) # 25th slot gives max offset.
                                   # this works well enough for us
    
    # Use function to find tick marks
    ticks = tick_marks_and_axis_labels( maxpos )
    ticklabel = ticks[['labels']]
    posprefix = ticks[['plotLabel']]
    ticks = ticks[['ticks']]
    
    max_tmp = maxpos
    
    if ( max( ticks ) > maxpos )
    {
      max_tmp = max( ticks )
    }
    
    # Jittering
    ibs_jittered = jitter( ibsVector, amount = 0.20 ) + 13
    gen1_jittered = jitter( gen1, amount = 0.20 ) + 8
    gen2_jittered = jitter( gen2, amount = 0.20 ) + 3
    
    while ( doPostscript || doPNG )
    {
      if ( doPostscript )
      {
        ######
        # ps #
        ######
        postscript( file = paste0(savename,"_", comparison,".ps"), 
                    paper = "special", 
                    width = pagewidth, 
                    height = pageheight, 
                    horizontal = TRUE )
      } else if (doPNG)
      {
        #######
        # PNG #
        #######
        png( filename=paste0(savename,"_", comparison,".png"), 
             width=round(pagewidth*72,0), 
             height=round(pageheight*72,0), 
             units="px", 
             bg="white", 
             type="cairo", 
             antialias="default", 
             res=DPI )
      }
      
      plot_min = 0
      plot_max = 16
      par( "mar" = c( 5, 4, 3, 5 ) + 0.1 )
      
      plot.new()
      plot.window( xlim = c( 1, max_tmp ), 
                   ylim = c( plot_min, plot_max ) )
      
      title( paste0( "Genome-wide SNPduo Output\n", 
                    label_ind1, 
                    " - ", 
                    label_ind2, 
                    "\nAverage IBS: ", avg_ibs ) )
      
      title( xlab = paste( "Physical Position", posprefix ) )
      
      points( physPos, ibs_jittered, cex = cexScale, pch = pchValue )
      points( physPos, gen1_jittered, cex = cexScale, pch = pchValue )
      points( physPos, gen2_jittered, cex = cexScale, pch = pchValue )
      
      axis( 1, at = ticks, labels = as.character( ticklabel ) )
      
      ibslab = c( 0,1,2 )
      genlab = c( 0,1,2,3 )
      axis( 2, 
            at = c( ( genlab + 3 ), ( genlab + 8 ), ( ibslab + 13 ) ), 
            labels = c( "NC", "AA", "AB", "BB","NC", "AA", "AB", "BB", "0", "1", "2" ) , 
            las = 1 )
      
      #########################################################################################################
      # Add in format command here to get formatted counts and split the axis 4 command into three statements #
      #########################################################################################################
      axis( 4, 
            at = c( ( genlab + 3 ), ( genlab + 8 ), ( ibslab + 13 ) ), 
            c( paste( ind2_NC ), paste( ind2_AA ), paste( ind2_AB ), paste( ind2_BB ), paste( ind1_NC ), paste( ind1_AA ), paste( ind1_AB ), paste( ind1_BB ), paste( ibs0 ), paste( ibs1 ), paste( ibs2 ) ), 
            las = 1 )
      
      ###############
      # Side labels #
      ###############
      mtext( "Genotype", line = 3, side = 2, at = 4.5, cex = 1.15 )
      mtext( "Genotype", line = 3, side = 2, at = 9.5, cex = 1.15 )
      mtext( "Identity by State", line = 3, side = 2, at = 14, cex = 1.15 )
      
      #################
      # Inside labels #
      #################
      text( x = max_tmp / 2, y = 12, paste( label_ind1 ) )
      text( x = max_tmp / 2, y = 7, paste( label_ind2 ) )
      
      ##########
      # Box it #
      ##########
      rect( 0, 2.4, max_tmp, 15.6 )
      
      #####################
      # Chromosome Labels #
      #####################
      draw_genome_chromosome_boundaries( chr_offset, 0, 2 )
      chromosome_labeling( chr_offset, 1 )
      
      dev.off()
      
      if ( doPostscript )
      {
        doPostscript = FALSE
      } else if ( doPNG )
      {
        doPNG = FALSE
      }
    }
  }
  
  ####################
  # Write everything #
  ####################
  fortext$IBS = ibsVector
  fortext = fortext[ order( physPos ), ]
  
  names( fortext )[4] = paste( label_ind1 )
  names( fortext )[5] = paste( label_ind2 )
  
  write.table( fortext, 
               row.names = FALSE, 
               quote = FALSE, 
               file = paste0( savename,"_", comparison, ".summary.txt"), 
               sep = "\t" )
  
  if ( makeBED )
  {
    chromList = unique( genotypeData[,chr] )
    
    for ( chromIndex in 1:length( chromList ) )
    {
      chromValues = which( genotypeData[,chr] == chromList[ chromIndex ] )
      
      ibsTmp = ibsVector[ chromValues ]
      positionTmp = genotypeData[chromValues,pos]
      
      segment_ibs_blocks( ibs=ibsTmp, 
                          position=positionTmp, 
                          chromosome=chromList[ chromIndex ], 
                          Ind1=label_ind1, 
                          Ind2=label_ind2, 
                          File=paste0( savename,"_", comparison,  ".bedsummary.txt"), 
                          AppendLogical=TRUE )
    }
  }
  
  genSummary = data.frame( "Genotype" = c( "AA", "AB", "BB", "NoCall" ), "tmp1" = 0, "tmp2" = 0 )
  
  genSummary[1,2] = ind1_AA
  genSummary[2,2] = ind1_AB
  genSummary[3,2] = ind1_BB
  genSummary[4,2] = ind1_NC

  genSummary[1,3] = ind2_AA
  genSummary[2,3] = ind2_AB
  genSummary[3,3] = ind2_BB
  genSummary[4,3] = ind2_NC

  names( genSummary )[2] = paste( label_ind1 )
  names( genSummary )[3] = paste( label_ind2 )

  # IBS
  ibsSummary = data.frame( "Alleles Identical by State" = c( 0, 1, 2 ),
                           "Counts" = 0 )
  ibsSummary[1,2] = ibs0
  ibsSummary[2,2] = ibs1
  ibsSummary[3,2] = ibs2  
  
  write.table( genSummary, 
               row.names = FALSE, 
               quote = FALSE, 
               file = paste0( savename,"_", comparison, ".gensum" ), 
               sep = "\t" )
  
  write.table( ibsSummary, 
               row.names = FALSE, 
               quote = FALSE, 
               file = paste0( savename,"_", comparison, ".ibssum" ), 
               sep = "\t" )
}

#############################################
#  Tabulate                                 #
#                                           #
#  Function to tabulate number of each ibs  #
#  count and genotype call in large samples #
#                                           #
#############################################
tabulate_ibs = function ( dataObject, chromosomeVector, individualColumns, savename )
{
  chr = grep( "Chromosome", names(dataObject) )
  
  if ( length( chr ) == 0 )
  {
    stop( "Chromosome column not found!" )
  } else if ( length(chr) > 1 )
  {
    stop( "Multiple chromosome columns found!" )
  }
  
  if ( is.null( chromosomeVector ) )
  {
    chromosomeVector = unique( dataObject[,chr] )
  }
  
  sampleNames = names( dataObject )[individualColumns]
  numberSamples = length( individualColumns )
  numberComparisons = ( numberSamples * ( numberSamples - 1 ) ) / 2
  numberChromosomes = length( chromosomeVector )
  
  ###########################################
  # Subset data on the chromosomes selected #
  ###########################################
  dataObject = dataObject[ which( dataObject[,chr] %in% chromosomeVector ), ]
  
  if ( dim( dataObject )[1] == 0 )
  {
    stop ( "Tabulate mode failed: selected chromosomes not found in data" )
  }
  
  ############################
  # Code inviduals genotypes #
  ############################
  for ( index in 1:numberSamples )
  {
    if ( !is.numeric( dataObject[, individualColumns[index]] ) ) {
      dataObject[,individualColumns[index]] = genotypes_to_integers( dataObject[,individualColumns[index]] )
    }
  }
  
  genotypeMatrix = as.matrix( dataObject[,individualColumns] )
  
  if ( dim( genotypeMatrix )[2] != numberSamples ) {
    stop( "Problem! Not all individuals found in data!" )
  }
  
  ####################################
  # Get chromosome indexes only once #
  ####################################
  chromosomeIndexes = vector( "list", numberChromosomes )
  
  for ( i in 1:numberChromosomes )
  {
    chromosomeIndexes[[i]] = which( dataObject[,chr] == chromosomeVector[i] )
  }
  
  ###################
  # Count genotypes #
  ###################
  genotypeCountMatrix = matrix( nrow = numberChromosomes * numberSamples, ncol = 4, 0 ) # From left to right: AA, AB, BB, NC
  genChromosome = character( numberChromosomes * numberSamples )
  genSample = character( numberChromosomes * numberSamples )
  
  iterationCounter = 1
  for ( sampleIndex in 1:numberSamples )
  {
    for ( chromosomeIndex in 1:numberChromosomes )
    {
      genChromosome[iterationCounter] = as.character( chromosomeVector[chromosomeIndex] )
      genSample[iterationCounter] = sampleNames[sampleIndex]
      
      cGenotype = .C( "CountGenotypes",
      cSize = as.integer( length(chromosomeIndexes[[chromosomeIndex]]) ),
      cGeno = as.integer( genotypeMatrix[ chromosomeIndexes[[chromosomeIndex]], sampleIndex ] ),
      cNC = as.integer(0),
      cAA = as.integer(0),
      cAB = as.integer(0),
      cBB = as.integer(0) )
      
      genotypeCountMatrix[iterationCounter,1] = cGenotype$cAA
      genotypeCountMatrix[iterationCounter,2] = cGenotype$cAB
      genotypeCountMatrix[iterationCounter,3] = cGenotype$cBB
      genotypeCountMatrix[iterationCounter,4] = cGenotype$cNC
      
      iterationCounter = iterationCounter + 1
    }
  }
  
  genotypeCountDataframe = data.frame( genSample,genChromosome,genotypeCountMatrix )
  names( genotypeCountDataframe ) = c( "Sample", "Chromosome", "AA", "AB", "BB", "NC" )
  
  ####################
  # Count IBS states #
  ####################
  ibsCountMatrix = matrix( nrow = numberChromosomes * numberComparisons, ncol=3 ) #From left to right: IBS0, IBS1,IBS2
  colnames( ibsCountMatrix ) = c( "IBS0","IBS1","IBS2" )
  ibsChromosome = character( numberChromosomes * numberComparisons )
  ibsSampleA = character( numberChromosomes * numberComparisons )
  ibsSampleB = character( numberChromosomes * numberComparisons )
  
  iterationCounter = 1
  for ( firstSampleIndex in 1:( numberSamples-1 ) )
  {
    for ( secondSampleIndex in ( firstSampleIndex+1 ):numberSamples )
    {
      for ( chromosomeIndex in 1:numberChromosomes )
      {
        ibsChromosome[iterationCounter] = as.character( chromosomeVector[chromosomeIndex] )
        ibsSampleA[iterationCounter] = sampleNames[firstSampleIndex]
        ibsSampleB[iterationCounter] = sampleNames[secondSampleIndex]
        
        if ( !all( chromosomeIndexes[[chromosomeIndex]] %in% 1:dim( genotypeMatrix )[1] ) )
        {
          stop( "Chromosome indexes not in genotype matrix!" )
        }
        
        if ( firstSampleIndex > dim( genotypeMatrix )[2] )
        {
          stop( paste( "firstSampleIndex greater than columns in genotypeMatrix!\nFirst Sample Index: ", firstSampleIndex, "\nColumns in matrix: ", dim( genotypeMatrix )[2] ) )
        }
        
        if ( secondSampleIndex > dim( genotypeMatrix )[2] )
        {
          stop( paste( "secondSampleIndex greater than columns in genotypeMatrix!\n Second Sample Index: ", secondSampleIndex, "\nColumns in matrix: ", dim( genotypeMatrix )[2] ) )
        }
        
        cIBS = .C ( "CountIBSFromGenotypes",
        cSize = as.integer( length( chromosomeIndexes[[chromosomeIndex]] ) ),
        cGeno1 = as.integer( genotypeMatrix[chromosomeIndexes[[chromosomeIndex]], firstSampleIndex] ),
        cGeno2 = as.integer( genotypeMatrix[chromosomeIndexes[[chromosomeIndex]], secondSampleIndex] ),
        cIBS0 = as.integer(0),
        cIBS1 = as.integer(0),
        cIBS2 = as.integer(0) )
        
        ibsCountMatrix[iterationCounter,1] = cIBS$cIBS0
        ibsCountMatrix[iterationCounter,2] = cIBS$cIBS1
        ibsCountMatrix[iterationCounter,3] = cIBS$cIBS2
        
        iterationCounter = iterationCounter + 1
      }
    }
  }
  
  ibsCountDataframe = data.frame( ibsSampleA,ibsSampleB,ibsChromosome, ibsCountMatrix )
  names(ibsCountDataframe) = c( "SampleA","SampleB","Chromosome","IBS0", "IBS1","IBS2" )
  
  #########################
  # Autosomal Mean and SD #
  #########################
  countsMatrix = matrix( nrow = numberComparisons, ncol = 3)
  colnames( countsMatrix ) = c( "IBS0", "IBS1", "IBS2" )
  meanSDMatrix = matrix( nrow = numberComparisons, ncol = 2 )
  colnames( meanSDMatrix ) = c( "Mean_IBS", "SD_IBS" )
  meanSDsampleA = character( numberComparisons )
  meanSDsampleB = character( numberComparisons )
  
  iterationCounter = 1
  for ( firstSampleIndex in 1:( numberSamples - 1 ) )
  {
    for ( secondSampleIndex in ( firstSampleIndex + 1 ):numberSamples )
    {
      # Get names
      meanSDsampleA[iterationCounter] = sampleNames[firstSampleIndex]
      meanSDsampleB[iterationCounter] = sampleNames[secondSampleIndex]
      
      # Do counts of IBS states
      countsMatrix[iterationCounter, "IBS0"] = sum( ibsCountMatrix[(ibsChromosome %in% 1:22 & ibsSampleA == sampleNames[firstSampleIndex] & ibsSampleB == sampleNames[secondSampleIndex]), "IBS0"] )
      countsMatrix[iterationCounter, "IBS1"] = sum( ibsCountMatrix[(ibsChromosome %in% 1:22 & ibsSampleA == sampleNames[firstSampleIndex] & ibsSampleB == sampleNames[secondSampleIndex]), "IBS1"] )
      countsMatrix[iterationCounter, "IBS2"] = sum( ibsCountMatrix[(ibsChromosome %in% 1:22 & ibsSampleA == sampleNames[firstSampleIndex] & ibsSampleB == sampleNames[secondSampleIndex]), "IBS2"] )
      
      # Calculate Mean and SD
      meanSDMatrix = mean_and_sd_from_counts( countsMatrix )
      
      # Make sure everything saves
      meanSDdataframe = data.frame( "SampleA" = meanSDsampleA, "SampleB" = meanSDsampleB, meanSDMatrix )
      
      iterationCounter = iterationCounter + 1
    }
  }
  
  ####################################
  # Sort arrays so they are in order #
  ####################################
  chromosomeVector = chromosomeVector[ order(chrom_convert_to_integer( chromosomeVector ) ) ]
    
  ibsCountDataframe = ibsCountDataframe[ order( as.character( ibsCountDataframe$SampleA ), as.character( ibsCountDataframe$SampleB ),chrom_convert_to_integer( ibsCountDataframe$Chromosome ) ),]
  
  genotypeCountDataframe = genotypeCountDataframe[ order( as.character( genotypeCountDataframe$Sample ), chrom_convert_to_integer( genotypeCountDataframe$Chromosome ) ),]  
  meanSDdataframe = meanSDdataframe[ order( as.character( meanSDdataframe$SampleA ), as.character( meanSDdataframe$SampleB ) ),]  
  
  ##################
  # Write Genotype #
  ##################
  write.table( ibsCountDataframe, file = paste( savename, ".SummaryIBS.csv", sep="" ), row.names = FALSE, quote = FALSE, sep = "," )
  
  #############
  # Write IBS #
  #############
  write.table( genotypeCountDataframe, file = paste( savename, ".SummaryGenotype.csv", sep="" ), row.names = FALSE, quote = FALSE, sep = "," )
  
  ###################
  # Write Mean / SD #
  ###################
  write.table( meanSDdataframe, file = paste( savename, ".SummaryMeanSD.csv", sep="" ), row.names = FALSE, quote = FALSE, sep = "," )
  
  #####################
  # Write Chromosomes #
  #####################
  write.table( as.character( chromosomeVector ), file = paste( savename, ".chromlist", sep="" ), row.names = FALSE, col.names=FALSE,quote = FALSE, sep = "\t")
}

###########################################
# genome_by_chromosome                    #
#                                         #
# Plot each chromosome individually while #
# making appropriate single summary files #
# and appropriately naming each one.      #
###########################################
genome_by_chromosome = function ( genotypeData, ind1, ind2, savename, pswidth, psheight, comparison = "None", doPostscript = TRUE, chromlist = NULL, makeBED = TRUE, doPNG=FALSE, DPI=72 )
{
  printInd1 = gsub( "\\.", " ", names( genotypeData )[ ind1 ] )
  printInd2 = gsub( "\\.", " ", names( genotypeData )[ ind2 ] )
  
  if ( is.null( chromlist ) )
  {
    chromlist = unique( genotypeData$Chromosome )
  }
  
  write.table( chromlist, file = paste( savename, "_", comparison, ".chromlist", sep="" ), row.names = FALSE, col.names = FALSE, quote = FALSE, sep = "\t" )
  
  cat( "Chromosome\tPhysical Position\tIBS\t", paste( printInd1 ), "\t", paste( printInd2 ), "\n" ,file = paste( savename, "_", comparison, ".summary.txt", sep = "" ) )
  
  for ( i in 1:length( chromlist ) )
  {
    chrom = chromlist[i]
    snpduo_single_chromosome( genotypeData,chrom, ind1, ind2, savename, pswidth, psheight, bychromosome = TRUE, comparison = comparison, doPostscript = doPostscript, makeBED = makeBED, doPNG=doPNG, DPI=DPI, THUMBNAIL=TRUE )
  }
}
