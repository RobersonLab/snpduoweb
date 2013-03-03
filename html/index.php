<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.01//EN" "http://www.w3.org/TR/html4/strict.dtd">

<?php include("./copyrightstatement.php"); ?>

<html>

<head>
<title>SNPduoWeb at the Pevsnerlab</title>
<link rel="stylesheet" type="text/css" href="SNPduo.css">
<meta name="author" content="Elisha Roberson">
<meta name="description" content="Gateway page for the Pevsner Lab SNPduoWeb tool">
<meta name="keywords" content="SNP,SNPduo,pair-wise,web tool,recombination,identity by state,identity by descent,IBS,IBD,pedigree,high-density,high density,high-throughput,sib,family,visualize,plot,publication quality,ucsc genome browser,related,relatedness,deletion,amplification,UPD,uniparental disomy,Affymetrix,Illumina,Hap Map,custom,data">
</head>

<body>

<?php include("./header.php"); ?>

<table width="100%" border="0" cellpadding="0" cellspacing="0">

<tr class="rowcommon cell2">
<td>
<blockquote><p>Welcome to the SNPduoWeb website. This tool is designed to provide an analysis of Single Nucleotide Polymorphism (SNP) data
between any two individuals. It has been designed based on data exported from Affymetrix CNAT 4.0 or Illumina Beadstudio, as well
as data downloaded from the HapMap project. However, provided that the data is formatted correctly SNPduoWeb can analyze any SNP data.
</p></blockquote>
</td>
</tr>

<tr class="rowcommon cell2">
<td>
<blockquote>
<table border="0" cellpadding="6" cellspacing="3">

<tr class="rowcommon">
<td class="cell1"><a href="SNPduo01.php" class="cell1">Run SNPduo</a></td>
<td class="cell2">Click to run the SNPduoWeb tool</td>
</tr>

<tr class="rowcommon">
<td class="cell1"><a href="SNPduo02.php" class="cell1">Introduction</a></td>
<td class="cell2">An introduction into the function of SNPduo</td>
</tr>

<tr class="rowcommon">
<td class="cell1"><a href="SNPduo03.php" class="cell1">Tutorial</a></td>
<td class="cell2">A tutorial for first-time SNPduoWeb users. Covers the analysis of Affymetrix, Illumina, HapMap, and custom format data</td>
</tr>

<tr class="rowcommon">
<td class="cell1"><a href="SNPduo04.php" class="cell1">Sample Output</a></td>
<td class="cell2">Visual examples of the types of Identity by State patterns identified with SNPduo</td>
</tr>

<tr class="rowcommon">
<td class="cell1"><a href="SNPduo05.php" class="cell1">Code</a></td>
<td class="cell2">The code for running web-based SNPduoWeb locally and a command-line based C++ version for large datasets.</td>
</tr>

<!--
<tr class="rowcommon">
<td class="cell1"<a href="Supplemental/index.php" class="cell1>Supplmental Data</a></td>
<td class="cell2">Supplemental data from the SNPduoWeb manuscript</td>
</tr>
-->

<tr class="rowcommon">
<td class="cell1"><a href="SNPduo06.php" class="cell1">Credits and Contact</a></td>
<td class="cell2">Please send us questions, comments, or report bugs in using the software</td>
</tr>

</table>
</blockquote>
</td>
</tr>

</table>

<?php include("./footer.php"); ?>

<p>This page last updated on <?php echo date("F d, Y", getlastmod() ); ?> </p>

</body>

</html>
