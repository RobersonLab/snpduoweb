<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.01//EN" "http://www.w3.org/TR/html4/strict.dtd">

<?php include("./copyrightstatement.php"); ?>

<html>

<head>
<title>SNPduoWeb at the Pevsnerlab -- Sample Patterns</title>
<link rel="stylesheet" type="text/css" href="SNPduo.css">
<meta name="author" content="Elisha Roberson">
<meta name="description" content="Examples of sample output from SNPduo">
<meta name="keywords" content="SNPduo,SNP,examples,deletion,amplification,parent child, sibling,pedigree,aneuploidy,sibling,recombination,recombination pattern">
</head>

<body>

<?php include("./header.php"); ?>


<table width="100%" border="0" cellpadding="0" cellspacing="0">
<tr class="rowcommon cell2">
<td>

<blockquote>
<table border="0" cellpadding="6" cellspacing="3">
<tr class="rowcommon">
<td class="cell1">Sample Output</td>
<td class="cell2">Visual examples of the types of Identity by State patterns identified with SNPduo</td>
</tr>
</table>
</blockquote>

</td>
</tr>
</table>

<hr>
<p>
	&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;There are four basic IBS track patterns commonly seen in SNPduoWeb data.<br>
</p>
<blockquote>
	<p>
		<img src="images/Example_IBS0.png" width="267" height="220" alt="Image Example IBS-0 Pattern">
	</p>
</blockquote>

<p>
	&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;The first type is the IBS-0 pattern, which consists of three overlaid tracks, showing a mix of IBS-0, IBS-1, and IBS-2 classifications. The track densities are actually quite different; the IBS-2 track will have the highest density, followed by IBS-1, then IBS-0 (which is apparent visually). This pattern is expected for individuals considered "unrelated" to one another. This pattern also can occur in parent-child comparisons where the child has a de novo deletion on the allele inherited from that parent.
</p>

<blockquote>
	<p>
		<img src="images/Example_IBS1.png" width="267" height="214" alt="Image Example IBS-1 Pattern">
	</p>
</blockquote>

<p>
	&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;The IBS-1 pattern consists of two overlaid tracks: IBS-1 and IBS-2. Track densities differ within this pattern as well, with a higher density on the IBS-2 track. A pattern of IBS-1 across the entire genome (possibly excluding the X chromosome) is seen in the comparison of parent-child pairings, since the parent passes one allele to the child. This pattern is also seen in higher degree relationships (grandparent-grandchild, avuncular, half-sibs, first-cousins, second-cousins, etc.), but the regions become progressively smaller the further the two individuals are removed from a common ancestor.
</p>

<blockquote>
	<p>
		<img src="images/Example_IBS2.png" width="265" height="217" alt="Image Example IBS-2 Pattern">
	</p>
</blockquote>

<p>
	&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Third is the IBS-2 pattern. Only one track, the IBS-2 track, is present in this pattern. It represents genomic segments where both alleles, i.e. both chromosome copies, are shared identically between both individuals. This pattern might be seen, for example, in the comparison of identical siblings. An individual compared to themselves from separate genotyping experiments would show this pattern. Biologically this is seen segmentally in siblings as well, as occasionally both siblings receive the same chromosomal segments from each parent. The pattern is seen in areas of population autozygosity, as the locus has become homogenized by inbreeding. 
</p>

<blockquote>
	<p>
		<img src="images/Example_Deletion.png" width="270" height="184" alt="Image Example of Deletion Pattern">
	</p>
</blockquote>

<p>
	&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;The final pattern consists of two overlaid tracks: IBS-2 and IBS-0. For this pattern to occur both individuals must be homozygous in region, and the remaining genomic segment must be non-identical. This is most common when comparing two males for the X chromosome, since both individuals are homozygous.
	<br>
	<br>
	&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Homozygous deletions are more problematic to visualize on SNPduo. These areas tend to be high in uncalled SNP alleles, and uncalled alleles are not plotted on the SNPduoWeb track. However, a pattern where SNPduoWeb points disappear in the same region that clustered uncalled alleles appear can indicate a possible homozygous deletion.
</p>

<?php include("./footer.php"); ?>

<p>This page last updated on <?php echo date("F d, Y", getlastmod() ); ?> </p>

</body>
</html>