# snpduoweb

Repository for the web-based version / visualization engine for the SNPduoWeb tool. It was designed to visualize identity-by-state in high-density SNP data. SNPduoWeb was originally developed in the lab of Dr. Jonathan Pevsner while at the Kennedy Krieger Institute in Baltimore.

Publication PMID: [19696932](http://www.plosone.org/article/info%3Adoi%2F10.1371%2Fjournal.pone.0006711).

The hosting servers for this web tool have since been decommissioned. You have to host yourself to run this tool. There are instructions for the standard bare metal install as well as a simple Docker setup.

## Important notes regarding security
This tool does not **in any way** try to protect your data. It's just a system for uploading and processing data. Security becomes an issue if you are processing clinically relevant data. I can in no way offer you professional advice on securing your data. I can pass along how I approach this in our environments.

1. Host machine security. Keep the OS up-to-date with security fixes. Use tools like fail2ban to automatically block addresses sniffing for access to the machine. Use a firewall to limit access to only required ports.

2. Remote user access. Use minimum user permissions, i.e. not everyone needs root privileges. Force public-private key authentication **only** for SSH sessions, limit remote logins to specific user accounts you have created, and do not allow remote root login at all.

3. Use a reverse proxy like nginx with Let's Encrypt certificates to allow secure connections between the browser and the server.

4. Use full disk encryption of disks on the host machine.

Only a security consultant can advise you for use in protected environments with sensitive data. For research purposes, these approaches may reduce your attack surface for bag actors.

## Running SNPduoWeb on your own server -- the Docker way
Running the server via docker-compose should be the easiest setup. For this example, we will assume the tool data will be in /data/snpduoweb with a folder for uploads and downloads mounted as volumes in the container.

This setup will require docker and docker-compose.

1. Create a directory to hold the file data for SNPduoWeb.
```bash
mkdir -p /data/snpduoweb/download_dir /data/snpduoweb/upload_dir
```

2. Download the docker-compose.yml file from this repository into the directory you made for SNPduoWeb.
```bash
cd /data/snpduoweb
wget https://github.com/RobersonLab/snpduoweb/blob/master/docker-compose.yml
```

3. Edit the yml if you already have a service running on port 80. Example: from - "80:80/tcp" to - "3000:80/tcp" to run the service on port 3000 on the local machine (forwarded to port 80 in the image).

4. Initialize the image by running docker-compose.
```bash
docker-compose up
```

5. Reach SNPduoWeb by going to http://MACHINEIP:PORT/snpduoweb in your browser. For example, if you're running it on another computer at IP address 192.168.1.250 using port 3000, you'd go to http://192.168.1.250:3000/snpduoweb

If the service is running on port 80, the port isn't required.

**Hint 1**: The docker-compose command fails!
Make sure the persistent volumes have the right file permissions to let the docker user read and write.

**Hint 2**: My data timed out!
The built-in apache time limits may be too short. I've disabled the timeout in the image to the best of my knowledge. If you still get timeouts, let me know to try and troubleshoot.

## Installing SNPduoWeb on bare metal - the fragile old-fashioned way
Installing the web-interfaced version of SNPduo has minimal requirements:

* Linux based OS
* Web server - we have used apache
* Perl
* R statistical programming software - having an R version with cairo graphic support helps enormously
* Image Magick

### Download repo
Clone the SNPduo Web repository from GitHub. Switching to the newest tag is highly recommended.

```bash
mkdir /code
cd /code
git clone https://github.com/RobersonLab/snpduoweb.git
```

There are two key directories included: cgi-bin containing the executables needed by the web browser, and html, which contains the html files to serve the site. This code would have downloaded the files to /code/snpduoweb.

### Setting up paths
The paths for receiving input data and serving output data need to be readable and writable by your http daemon. It's also important to consider the path for input data. It should be a location writeable by your http daemon, but **should not** be within your html serving directory. This prevents someone else directly accessing uploaded data by brute force (unlikely but possible).

For this example, we'll assume that the tool is going to be running on a Linux box (Ubuntu) with Apache serving as the web server.

#### Data directory
This is where upload data goes. I'm going to use a dedicated data directory for this. The user/group assignments will vary based on *nix platform and http server. In this example the user/group will be www-data/www-data.

```bash
mkdir /data/snpduo_uploads
sudo chown www-data.www-data /data/snpduo_uploads
```

#### Html directory
You have to setup two different html directories. One to serve the front-end pages for the tool, and another for the output from the tool. They do not have to be in the same physical path, but the output is assumed to be a *subdirectory* of the webpage address specified in the CGI script (below).

*Tool output **must** be in an individual folder*. The tool checks the size of both the **upload and output folders** and deletes the contents. **Any other content in those directories would also be lost!**

```bash
sudo mkdir /var/www/html/snpduo
sudo mkdir /var/www/html/snpduo/tool_output
sudo chown www-data.www-data /var/www/html/snpduo
sudo chown www-data.www-data /var/www/html/snpduo/tool_output
```

#### Script directories
The cgi scripts must be readable and executable by your http daemon, and cgi must be enabled in your http daemon configuration. We have to setup a home for the cgi code and compiled R code.

```bash
sudo mkdir /usr/lib/cgi-bin/snpduo
sudo chown www-data.www-data /usr/lib/cgi-bin/snpduo
```

### Copying files

#### Front-end web pages

Copy front-end webpages to their html serving home.

```bash
sudo cp -R /code/snpduoweb/html/* /var/www/html/snpduo
sudo chown -R www-data.www-data /var/www/html/snpduo
```

#### CGI scripts

The Perl script (cgi file) is executed to upload & format data, as well as prepare R scripts for processing the uploaded information. It handles all file renaming, copying, moving, and directory size checks as well. **The file must be executable by daemon user!**

```bash
sudo cp /code/snpduoweb/cgi-bin/SNPduo.cgi /usr/lib/cgi-bin/snpduo
sudo chown www-data.www-data /usr/lib/cgi-bin/snpduo
sudo chmod u+x /usr/lib/cgi-bin/snpduo
```

#### R code and executables
R code templates, chromosome banding binaries, and raw C code must be copied as well. They **can** be in different directories, but in practice we keep the Perl CGI file and the R files together. The C code must be compiled into a shared library after copying.

```bash
sudo cp /code/snpduoweb/cgi-bin/*.R /usr/lib/cgi-bin/snpduo
sudo cp /code/snpduoweb/cgi-bin/.Rbin /usr/lib/cgi-bin/snpduo
sudo cp /code/snpduoweb/cgi-bin/*.c /usr/lib/cgi-bin/snpduo
cd /usr/lib/cgi-bin/snpduo
sudo R CMD SHLIB /usr/lib/cgi-bin/snpduo/SNPduoCCodes.c
sudo chown www-data.www-data /usr/lib/cgi-bin/snpduo/*
sudo chmod u+x /usr/lib/cgi-bin/snpduo/*
```

### Configuring the Perl CGI file
The script is designed to require only a few modifications to function. Values, such as maximum directory sizes, directory locations, name of the host, etc are required. It's recommended to make a backup of the original CGI in the event of catastrophic file disruption. The default script is edited for this example below. All values requiring editing are at the top of the script.

**Note** The FILE_MAX, DIR_MAX, and OUTPUT_MAX variables are likely different from what is shown here to better represent larger file sizes and more spacious drives than when the tool was first made.

```perl
use constant RENAME => "TRUE";
use constant CAIRO => "TRUE";
use constant PERLMAGICK => "FALSE";
my $datadir = "/data/snpduo_uploads";
my $outputdir = "/var/www/html/snpduo/tool_output";
my $webpage = "http://www.mydomain.com/snpduo";
my $outputFolder = "tool_output"; # which turns into http://www.mydomain.com/snpduo/tool_output for serving result files
my $codedir = "/usr/lib/cgi-bin/snpduo";
my $compileddir = "/usr/lib/cgi-bin/snpduo";
my $pathtoR = "/usr/bin/R";
use constant FILE_MAX => 1024 * 1024 * 500;
use constant DIR_MAX => 1024 * 1024 * 5;
use constant OUTPUT_MAX => 1024 * 1024 * 5
```

There are several important characteristics to consider for your system.

* Renaming files is faster than moving, but only works if they are on the same partition. If your html output directory and upload directory are on the same partition, use RENAME => "TRUE".

* Cairo graphics in R are typically on par with or faster than Image Magick. Recommend using Cairo first, and comparing to Perl Magick if results are not acceptable (requires Perl Magick module to be installed).

* FILE_MAX uses an internal file-size calculation that reports *bytes*. DIR_MAX and OUTPUT_MAX use a system du -c call that returns *kilobytes* of storage. Keep this in mind when setting the directory sizes. FILE_MAX defaults to a 500 MB max upload file size, and the upload and output directories default to 5 GB max sizes.

### Configuring SNPduo01.html
The submit form has to point to the correct path for the CGI script (relative to cgi-bin base directory in Apache configuration).

```html
<form enctype="multipart/form-data" action="/cgi-bin/snpduo/SNPduo.cgi" method="post">
```

## Running SNPduoWeb
Read the tutorial page for help getting started. Files may be delimited by commas, tabs, or single-spaces. The column headers are assumed based on the data type chosen on the upload page.

### Choosing samples
Sample selection is based on which *columns* of data you want to compare in your samples. For normal mode, place the column number of the first individual in column 1, and the number of the second individual in column 2. For all pair-wise comparisons of multiple individuals, set the "Run Mode" to Batch, and list all individuals in the Individual 1 box. They may be separated by commas are range designations, e.g. 5,6,7,9-12,14:22.

### Running multiple chromosomes
You may hold control or shift to manually select multiple chromosomes from the upload page. Alternatively, the Genome by Chromosome mode will make a plot for each chromosome discovered in your upload data. The Genome method will make a **single** plot for the whole genome, and label the bottom to show the chromosome boundaries.

### Genome build
Human builds 34-38 are available. This provides the chromosome sizes and cytoband information for plots.

### Images
An R generated postscript is created when selected. To make PNG representations of this postscript, both 'Make Postscripts' and 'Make PNGs' must be selected. If 'Do Not Make PNGs' is selected, no thumbnail previews will be available on the output page. If Do Not Make Postscripts is selected, no thumbnails **or** postscript output will be available.

### Block segmentation
This **very simple** block segmentation algorithm will attempt to find the boundaries of IBS blocks in your data iteratively (IBS0, then IBS1, then IBS2). It may not do a very good job, and was tuned on SNP data based on trial and error. Use with caution compared to the data plots, but is surprisingly robust for finding  boundaries.

### Run mode
Default is normal mode, when only a single pair of individuals is specified. As stated above, an exhaustive set of comparisons amongst all individuals can be performed by setting Run mode to Batch, and listing columns and column ranges on the Individual 1 box. Tabulate mode is also available. Samples are specified as in Batch mode, but no plots or segments are produced. This is only a very quick way to get IBS counts for individuals.
