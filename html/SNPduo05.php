<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.01//EN" "http://www.w3.org/TR/html4/strict.dtd">

<?php include("./copyrightstatement.php"); ?>

<html>

<head>
<title>SNPduoWeb at the Pevsnerlab -- Code</title>
<link rel="stylesheet" type="text/css" href="SNPduo.css">
<meta name="author" content="Elisha Roberson">
<meta name="description" content="Information on how to download and run SNPduoWeb on a local Linux server">
<meta name="keywords" content="SNPduo++,SNPduo,IBS,PLINK,C++,g++,SNPduo,code,open source,download,free,install,local,linux,R,Perl,C,compiled,current release,requirements,recommendations">
</head>

<body>

<?php include("./header.php"); ?>


<table width="100%" border="0" cellpadding="0" cellspacing="0">
<tr class="rowcommon cell2">
<td>

<blockquote>
<table border="0" cellpadding="6" cellspacing="3">
<tr class="rowcommon">
<td class="cell1">Code</td>
<td class="cell2">The code for running SNPduoWeb locally is available for download, and includes files written in html, css, R, C, and perl.</td>
</tr>
</table>
</blockquote>

</td>
</tr>
</table>

<hr>
<p>
<strong>Requirements</strong>
</p>
<blockquote>
	<p>
	Linux Operating System
	<br>
	
	<a href="http://cran.r-project.org/">R</a>
	<br>
	
	<a href="http://httpd.apache.org/">Apache</a>
	<br>
	
	<a href="http://gcc.gnu.org/">gcc</a>
	<br>
	
	Zip -- Linux command line utility
	<br>
	
	<a href="http://www.ghostscript.com/">Ghostscript</a>
	<br>
	
	<a href="http://www.perl.org/">Perl</a>
	<br>
	
	<a href="http://search.cpan.org/search%3fmodule=CGI">Perl CGI Module</a>
	<br>
	
	<a href="http://www.imagemagick.org">Image Magick</a>
	</p>
</blockquote>

<p>
<strong>Recommendations</strong>
</p>
<blockquote>
	<p>
	<a href="http://search.cpan.org/search%3fmodule=Image::Magick">Perl Image::Magick Module</a> -- Greatly increases performance of JPEG creation speed
	<br><br>
	
	Upload directory on same disk partition as HTML output -- Allows Perl rename to move files versus command-line fork to mv
	</p>
</blockquote>

<hr>
<p>
<strong>Version History</strong><br><br>
March 09, 2009 -- Version 1.01b fo SNPduo++ released<br>
February 25, 2009 -- Version 1.10 of SNPduoWeb rolled out, including SNPduo++<br>
August 07, 2008 -- Server migration altered JPEG creation. A switch to PNG format solved the problem<br>
June 18, 2008 -- Version 1.00 goes live
</p>
<hr>
<p>
<strong>Download</strong><br><br>
<!--<a href="">Current</a> SHA1 Digest: <br><br>-->
<a href="code/SNPduoWeb_v110.zip">SNPduoWeb v1.10</a> -- Released Feb. 25, 2009
<!-- Archive Releases<br><br> -->
</p>

<hr>

<p>
<strong>SNPduo++</strong><br><br>
A command-line based C++ program for calculating Mean_IBS and Standard Deviation of IBS on large datasets in ped/map or tped/tmap (<a href="http://pngu.mgh.harvard.edu/~purcell/plink/">PLINK</a> compatible) format. Works under Windows and Linux. Able to identify identical samples in large datasets, as well unannotated first-degree relatives.
<br><br>
**Windows requires manual compilation (use "g++ -o snpduo *.cpp").<br><br>
<a href="code/SNPduo_v101b.zip">Source Code v1.01b</a> -- Released Mar. 09, 2009<br>
<a href="code/SNPduo_v100.zip">Source Code v1.00</a> -- Released Feb. 25, 2009
</p>

<hr>


<?php include("./footer.php"); ?>

<p>This page last updated on <?php echo date("F d, Y", getlastmod() ); ?> </p>

</body>
</html>