<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.01//EN" "http://www.w3.org/TR/html4/strict.dtd">

<?php include("./copyrightstatement.php"); ?>

<html>

<head>
<title>SNPduoWeb at the Pevsnerlab -- Tutorial</title>
<link rel="stylesheet" type="text/css" href="SNPduo.css">
<meta name="author" content="Elisha Roberson">
<meta name="description" content="A tutorial explaining the preparation of data for SNPduoWeb and how to run the tool">
<meta name="keywords" content="SNPduo,SNP,tutorial,how to,guide,Affymetrix,Illumina,Hap Map,custom,data,export,upload,options">
</head>

<body>

<?php include("./header.php"); ?>

<p><a name="top"></a></p>

<table width="100%" border="0" cellpadding="0" cellspacing="0">
<tr class="rowcommon cell2">

<td>
<blockquote>
<table border="0" cellpadding="6" cellspacing="3">

<tr class="rowcommon">
<td class="cell1">Tutorial</td>
<td class="cell2">A tutorial for first-time SNPduoWeb users. Covers the analysis of Affymetrix, Illumina, HapMap, and custom format data</td>
</tr>
</table>
</blockquote>
</td>

</tr>
</table>

<hr>
<p>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Each of the exported data types that SNPduoWeb supports have slightly different formats. SNPduoWeb has been designed to handle the differences in these formats, but the data must be exported in a way SNPduoWeb can understand. Please select a tutorial to learn how to export data and run SNPduo.
<br><br>

Jump to a tutorial<br><br>
<a href="#Affymetrix">Affymetrix CNAT 4.0 Data Export</a><br>
<a href="#Illumina">Illumina BeadStudio Data Export</a><br>
<a href="#HapMap">HapMap Downloaded Data Export</a><br>
<a href="#Custom">Custom Data Formats</a><br>
<a href="#SNPduo">Running SNPduo</a><br>
<a href="#Tips">Tips and Hints</a>
</p>

<hr>

<!-- Affy data analysis -->
<p>
<a name="Affymetrix"><strong>Affymetrix CNAT 4.0 Data</strong></a>
<br><br>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Affymetrix data files are typically analyzed using the GeneChip Genotyping Analysis Software. This tutorial was written based on version 4.1.0.26, but should be applicable to older versions as well.


<blockquote>
	<p>
	1. Open the Affymetrix GType software
	<br><br>
	2. In the data source panel choose "Analysis Results"
	</p>
	
	<blockquote>
	<p>
	<img src="images/affy_analysisresults.jpg" width="251" height="186" alt="Affy Analysis Results">
	</p>
	</blockquote>
	
	<p>
	3. Double click on the appropriate "*.chp" files for the individuals you wish to analyze
	<br><br>
	
	4. Several columns are displayed for the data you have chosen. SNPduoWeb will run faster if less extraneous data is displayed. Right click in the column headers for data <strong>other</strong> than Chromosome, Physical Position, and the genotype calls for the individuals of interest, and click the "Hide Column" option
	</p>
	
	<blockquote>
	<p>
	<img src="images/affy_hide.jpg" width="444" height="180" alt="Affy Hide Columns">
	</p>
	</blockquote>
	
	<p>
	5. Click the Export button from the toolbar
	</p>
	
	<blockquote>
	<p>
	<img src="images/affy_export.jpg" width="529" height="63" alt="Affy Export Data">
	</p>
	</blockquote>
	
	<p>
	6. Choose an appropriate file name and save location. Be sure the "Export All" option is clicked and export the data
	</p>
	
	<blockquote>
	<p>
	<img src="images/affy_save.jpg" width="428" height="122" alt="Affy Save File">
	</p>
	</blockquote>
	
	<p>
	7. Proceed with using the SNPduoWeb tool as described <a href="#SNPduo">below</a>
	</p>
</blockquote>

<p>
<a href="#top">top</a>
</p>

<hr>

<!-- Illumina data analysis -->

<p>
<a  name="Illumina"><strong>Illumina - BeadStudio</strong></a>
<br><br>

&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;For SNPs genotyped using Illumina data the standard analysis software is BeadStudio. This portion of the tutorial will cover how to export data from BeadStudio for use with SNPduo.
</p>


<blockquote>
	<p>
	1. Open your data file (typically *.bsc) with BeadStudio
	<br><br>
	
	2. Make sure you are in the Full Data Table
	<br><br>
	
	3. Using the Column Chooser be sure you have at least the following selected:
	</p>
	
	<blockquote>
	<p>
	<img src="images/illumina_columnchooser.jpg" width="471" height="77" alt="Illumina Column Chooser">
	</p>
	</blockquote>
	
	<p>
	<strong>From "Displayed Columns" show</strong>
	</p>
	<ul>
		<li>Chr</li>
		<li>Position</li>
		<li>The individuals of interest</li>
	</ul>
	
	<p>
	<strong>From "Displayed Subcolumns" show</strong>
	</p>
	<ul>
		<li>GType</li>
	</ul>
	
	<p>
	4. Press the "Export Displayed Data to File" Button. Choose a save location and name. Export the data
	</p>
	
	<blockquote>
	<p>
	<img src="images/illumina_export.jpg" width="483" height="78" alt="Illumina Export Data">
	</p>
	</blockquote>
	
	<p>
	5. SNPduoWeb labels plots based on the column headers for the two compared individuals. To adjust the headers on a BeadStudio file open the exported file in a text editor. Change the genotype headers to whatever you wish to be displayed in the title of each individual's genotype plot and the overall title.
	<br><br>
	
	Note: Genotype columns of data exported from BeadStudio end in ".GType". This trailing ".GType" is automatically removed by SNPduo.
	<br><br>
	
	6. Proceed with using the SNPduoWeb tool as described <a href="#SNPduo">below</a>
	</p>
</blockquote>

<p>
<a href="#top">top</a>
</p>

<hr>

<!-- HapMap data analysis -->

<p>
<a name="HapMap"><strong>HapMap - Downloaded Data</strong></a>
<br><br>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;SNPduoWeb can analyze data downloaded from the HapMap site. These data are very high density, and therefore have large files. The HapMap data should be run on a <strong>per chromosome</strong> basis. This portion of the tutorial will cover how to download HapMap data for use with SNPduo.
</p>

<blockquote>
	<p>
	1. First go to the <a href="http://www.hapmap.org/downloads/">Downloads</a> page at the International HapMap Project website
	<br><br>
	
	2. Click the "Genotypes" link from Bulk Data listing
	</p>
	
	<blockquote>
	<p>
	<img src="images/hapmap_genotype.jpg" width="527" height="286" alt="HapMap Genotype Download">
	</p>
	</blockquote>
	
	<p>
	3. Pick the directory of the latest data for the build you wish to use
	</p>
	
	<blockquote>
	<p>
	<img src="images/hapmap_build.jpg" width="426" height="168" alt="HapMap Build Selection">
	</p>
	</blockquote>
	
	<p>
	4. Pick the "non-redundant" folder of SNP data (you may or may not have to choose a strand first)
	<br><br>
	
	5. You should now see a list of files for each chromosome in each population. Select the chromosome and population you are interested in and click to download the file. The download will be a gzipped text file. On Linux and Mac systems the shell command "gunzip <i>filename</i>" should extract the text file from the archive. On Windows utility such as <a href="http://www.winzip.com">WinZip</a> or <a href="http://www.rarlab.com">WinRAR</a> can extract the text file from the archive.
	<br><br>
	
	6. Proceed with using the SNPduoWeb tool as described <a href="#SNPduo">below</a>
	</p>
</blockquote>

<p>
<a href="#top">top</a>
</p>

<hr>

<!-- Custom data format analysis -->
<p>
<a name="Custom"><strong>Custom Data Format</strong></a>
<br><br>

&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;The "Custom" data format allows for the analysis of data from any source, provided it follows the appropriate guidelines.</p>

<blockquote>
	<p>
	1. Chromosome column must have the name "Chromosome"
	<br><br>
	
	2. Physical Position column must have the name "Physical Position" or "Physical.Position"
	<br><br>
	
	3. Lines that should be skipped must start with a "#" character
	<br><br>
	
	4. Lines containing only whitespace (tabs, spaces, newline characters) are skipped
	<br><br>
	
	5. The only limitation on the number of SNPs is the maximum filesize upload limit
	</p>
</blockquote>

<p>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;To use the Custom format be sure to select "Custom" from the SNPduoWeb Data Type dropdown list. Detailed instructions for running SNPduoWeb are provided <a href="#SNPduo">below</a>.

<br><br>
<a href="#top">top</a>
</p>

<hr>

<!-- SNPduoWeb explanation -->

<p>
<a name="SNPduo"><strong>Running SNPduo</strong></a>
<br><br>

&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;The previous sections of this tutorial describe how to properly export data for use with SNPduo. This section will cover the use of the tool itself.
<br><br>

<img src="images/duo_01_file.png" alt="SNPduoWeb Specify File">
<br>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;The first step in using SNPduoWeb is to specify the file you want to analyze. By following the previous tutorials you should have a file exported in the proper format for your data type. Use the "Browse" button to locate this file.
<br><br>

<img src="images/duo_02_sep.png" alt="SNPduoWeb Select Column Delimiter">
<br>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;SNP data files can come in a variety of delimited formats. The second step is to select which delimiter your file uses. Choices include a comma, tab, or single space. Delimiters shouldn't be mixed within one file, and there should be only a single delimiter character between successive columns. Illumina and Affymetrix data are typically tab delimited by default (though you can export csv files). HapMap Bulk Data Downloads are single space separated.
<br><br>

<img src="images/duo_03_platform.png" alt="SNPduoWeb Select Data Source">
<br>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;The third step is to select the source of your data. Choose one of the options in the drop-down box. For custom formatted data be sure you have followed the rules described previously for formatting this type of input.
<br><br>

<img src="images/duo_04_05_individual.png" alt="SNPduoWeb Data Columns">
<br>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;The fourth and fifth steps tell SNPduoWeb where the genotype data is located. The order of who is individual one and who is individual two is not important. In each box enter the number of the column where the genotype data is located. For instance, if the headers of your input were "Chromosome,Physical Position,Individual 1,Individual 2", you would enter 3 and 4 in the box for individual 1 and individual 2, respectively.
<br><br>

<img src="images/duo_06_chr.png" alt="SNPduoWeb Select Chromosome">
<br>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Step six specifies the chromosome of interest. There are several ways to proceed with this option.

<ol class="lowerroman">
<li>Select individual chromosome(s) from the choices of chromosomes 1-22, X, Y, and M<br>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;This option will provide summary data and plot for the individual chromosome specified.</li>
<li>Select "Genome"<br>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;This option will provide summary data and plot on one graph the entire genome</li>
<li>Select "Genome by Chromosome"<br>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Picking this option is the same thing as doing option "i" for every chromosome. The data is provided in a *.zip file containing the plots for each individual chromosome and the summary data for the genome</li>
</ol>

<p>
<img src="images/duo_07_08_pagesize.png" alt="SNPduoWeb Output Page Size">
<br>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Steps seven and eight allow you to specify the size of the postscript file the program generates. The default is standard letter size. Images are landscape format so the width should be the widest dimension. Common paper sizes in inches are listed below:

<br>
</p>

<table border="1" cellspacing="3" cellpadding="6">
<tr align="center"><td>Letter</td><td>8.5x11</td></tr>

<tr align="center"><td>Legal</td><td>8.5x14</td></tr>

<tr align="center"><td>Government Letter</td><td>8.5x10.5</td></tr>

<tr align="center"><td>Government Legal</td><td>8.5x13</td></tr>

<tr align="center"><td>Ledger</td><td>11x17</td></tr>
</table>

<p>
<img src="images/duo_09_build.png" alt="SNPduoWeb Build Information">
<br>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;The positions and extent of centromeres, telomeres, and other heterochromatin can change between genome builds. Step 9 allows you to specify which build the data is based on so the ideogram for that build is displayed correctly. Affymetrix CNAT 4.0 will be based on Build 35. Illumina BeadStudio data is based on Build 35. If you are using HapMap, select the build appropriate for the data that you downloaded. Custom data could be any build, and the user is responsible for deciding which to use.
<br><br>

<img src="images/duo_10_makeps.png" alt="SNPduoWeb make postscript option">
<br>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;By default postscript images are created for each analysis. However, if only tabulated data is required this option can be turned off in order to increase analysis speed. You cannot create PNGs without including the make postscript option.
<br><br>

<img src="images/duo_11_makepng.png" alt="SNPduoWeb make PNG option">
<br>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;In step 11 you can specify whether the software should generate PNG files of your data. The default is to create PNGs. These PNG files will displayed in your web browser and will be available for download. The advantage of making PNGs is to be able to see the data in the browser without having to download the postscript and open it in a vector graphics program. The disadvantage is that making an PNG from a postscript is a slow process and may significantly slow down the performance of the program. <strong>NOTE:</strong> the option to make Postscripts MUST be selected in order to make PNG files.
<br><br>

<img src="images/duo_12_segment.png" alt="SNPduoWeb perform segmentation option">
<br>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;DNA moves in discrete blocks through generations, making block-like IBS structures between individuals. SNPduo provides a simple density-based segmenting algorithm for finding IBS blocks in data. This option defaults to Yes, but can be disabled if desired. Data for blocks are returned as a UCSC Genome Browser viewable ".bed" file. 
<br><br>

<img src="images/duo_13_runmode.png" alt="SNPduoWeb Normal, Batch, or Tabulate mode options">
<br>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;SNPduoWeb can be run to analyze a single pair in Normal Mode or all comparisons for a list of individuals in Batch or Tabulate Modes. The default mode in step 13 is Normal Mode.<br><br>

&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;If you wish to run all comparisons for several individuals, select Batch Mode. Then specify the columns of the individuals you wish to compare in the "Individual 1" box. Individuals should be separated by columns, and ranges can be specified using either a hyphen or colon to donate a column range (for lower to greater column number). For example, if you want to perform all comparisons between columns 4 to 6 and column 8, enter "4,5,6,8", "4-6,8", or "4:6,8" in the Individual 1 box. Individual 2 can be left blank (and any input there will be ignored in Batch and Tabulate Modes).<br><br>

&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Tabulate mode is invoked in the same way as Batch mode, but the code is optimized to just count IBS states. Using this option no images can be generated, and all output is included in two downloadable files. This is the fastest analysis option.
<br><br>

<img src="images/duo_14_submit.png" alt="SNPduoWeb Submit data">
<br>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;The final step in running SNPduoWeb is to double check the form choices you have made, and submit the data. Pressing the submit button uploads your input file to the SNPduoWeb server and triggers the supporting scripts to analyze the data using the parameters you chose. After processing a new page will display, showing a PNG version of your IBS plot, along with links to the summary file, bed file for the UCSC Genome Browswer, PNG image, postscript file, and a zip file containing all output files in a single archive.
</p>

<hr>

<p>
<a name="Tips"><strong>Tips and Hints</strong>
<br><br>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;SNPduoWeb is designed to ignore lines that start with a # character (commented lines). Any line that contains this character is automatically ignored. Also, in any context OTHER than commenting out a line the # sign is a forbidden character and will automatically be replaced by alternative characters.
<br><br>

&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;If you need to manually edit any header information of large text files on a Windows PC, we suggest using a more advanced text/code editor than notepad, such as <a href="http://www.crimsoneditor.com">Crimson Editor</a> or <a href="http://notepad-plus.sourceforge.net">Notepad++</a>. Mac and Linux text editors such as vi, emacs, and xemacs can usually open and manipulate large files with little problem.
<br><br>

&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;If performing a "Genome" plot, it may be useful to keep the height at approximately normal landscape page size (approximately 8.5") and set the width to very long (for example 50). This will spread the plot out enough to more easily see patterns in your data.
<br><br>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;The platform specific plotting functions are designed to work if you follow the steps outlined in this tutorial. If the data is not obtained by following those steps it should be considered Custom Data and formatted in an appropriate manner.
<br><br>
<a href="#top">top</a>
</p>

<?php include("./footer.php"); ?>

<p>This page last updated on <?php echo date("F d, Y", getlastmod() ); ?> </p>

</body>
</html>