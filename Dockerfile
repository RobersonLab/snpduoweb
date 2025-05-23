###########################
# SNPduo web image        #
# Author: Elisha Roberson #
# Edited: 2025-02-10      #
###########################

# R portion of install adapted from other sources
# Adapted from Rocker code for our ubuntu image
# https://github.com/rocker-org/rocker/blob/df1414259dceb0282f163f29f4dccfa184d38d86/r-base/4.1.2/Dockerfile
# And cloud R project
# https://cran.r-project.org/bin/linux/ubuntu/fullREADME.html

# Built from official httpd image

FROM ubuntu:noble-20250127

###########
# setup R #
###########
ENV R_BASE_VERSION 4.4.1
ENV TZ=America/Chicago

RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && \
    echo $TZ > /etc/timezone

###################################
# Install required based packages #
###################################
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    make \
    software-properties-common \
    dirmngr \
    libicu74 \
    libreadline8 \
    default-jre \
    default-jdk \
    libfftw3-bin \
    libfftw3-dev \
    libopenblas64-0 \
    libopenblas-dev \
    libxml2-dev \
    libssl-dev \
    libpng-dev \
    wget \
    curl \
    libcurl4-openssl-dev \
    locales \
    locales-all \
    gfortran \
    fontconfig \
    libfontconfig1-dev \
    libharfbuzz-dev \
    libfribidi-dev \
    libfreetype6-dev \
    libpng-dev \
    libtiff5-dev \
    libjpeg-dev \
    cmake \
    gpg-agent \
    perl \
    libwww-perl \
    libcgi-pm-perl \
    libimage-magick-perl \
    zip \
    apache2

#############
# setup cgi #
#############
RUN a2enmod cgi 

#############
# install R #
#############

# update keys for right R version
RUN wget -qO- https://cloud.r-project.org/bin/linux/ubuntu/marutter_pubkey.asc | tee -a /etc/apt/trusted.gpg.d/cran_ubuntu_key.asc && \
    echo 'deb https://cloud.r-project.org/bin/linux/ubuntu noble-cran40/' >> /etc/apt/sources.list && \
    apt-key adv --keyserver keyserver.ubuntu.com --recv-keys E298A3A825C0D65DFD57CBB651716619E084DAB9 && \
    apt-get update && \
    apt-get install -y --no-install-recommends r-base

# link blas
RUN ln -s /usr/lib/x86_64-linux-gnu/openblas/libblas.so.3 /usr/lib/blas.so && \
    ln -s /usr/lib/x86_64-linux-gnu/openblas/liblapack.so.3 /usr/lib/lapack.so

#################################################
# Download and start working on SNPduoWeb setup #
#################################################
# copy files
RUN mkdir -p /var/www/html/snpduo/tool_output && \
    mkdir -p /usr/lib/cgi-bin/snpduo && \
    mkdir -p /data/snpduo_uploads && \
    wget https://github.com/RobersonLab/snpduoweb/archive/refs/tags/v1.4.0.tar.gz && \
    tar -xvf v1.4.0.tar.gz && \
    cp -R /snpduoweb-1.4.0/html/* /var/www/html/snpduo && \
    cp /snpduoweb-1.4.0/cgi-bin/*.R /usr/lib/cgi-bin/snpduo && \
    cp /snpduoweb-1.4.0/cgi-bin/*.Rbin /usr/lib/cgi-bin/snpduo && \
    cp /snpduoweb-1.4.0/cgi-bin/*.c /usr/lib/cgi-bin/snpduo && \
	#cat /snpduoweb-1.4.0/html/SNPduo01.html | sed 's/\/cgi\-bin\/SNPduo\/SNPduo.cgi/\/usr\/lib\/cgi\-bin\/snpduo\/SNPduo.cgi/' > /var/www/html/snpduo/SNPduo01.html
    cat /snpduoweb-1.4.0/html/SNPduo01.html | sed 's/\/cgi\-bin\/SNPduo\/SNPduo.cgi/\/cgi\-bin\/snpduo\/SNPduo.cgi/' > /var/www/html/snpduo/SNPduo01.html

# compile shared library
WORKDIR /usr/lib/cgi-bin/snpduo

RUN R CMD SHLIB -o SNPduoCCodes.so SNPduoCCodes.c && \
    cat /snpduoweb-1.4.0/cgi-bin/SNPduo.cgi | \
    sed 's/RENAME => "TRUE"/RENAME => "FALSE"/' | \
    sed 's/dataDir = "\/home\/SNP\/uploads\/SNPduo"/dataDir = "\/data\/snpduo_uploads"/' | \
    sed 's/outputDir = "\/home\/SNP\/html\/uploads\/SNPduo"/outputDir = "\/var\/www\/html\/snpduo\/tool_output"/' | \
    sed 's/http\:\/\/127\.0\.0\.1//' | \
    sed 's/outputFolder = "uploads\/SNPduo"/outputFolder = "tool_output"/' | \
    sed 's/codeDir = "\/home\/SNP\/cgi\-bin\/SNPduo"/codeDir = "\/usr\/lib\/cgi\-bin\/snpduo"/' | \
    sed 's/compiledDir = "\/home\/SNP\/cgi\-bin\/SNPduo"/compiledDir = "\/usr\/lib\/cgi\-bin\/snpduo"/' > SNPduo.cgi

# compile and setup permissions
WORKDIR /

RUN chmod -R u+x /usr/lib/cgi-bin/snpduo && \
    chown -R www-data:www-data /var/www/html && \
    chown -R www-data:www-data /usr/lib/cgi-bin/snpduo && \
    chown -R www-data:www-data /data/snpduo_uploads

#################################
# default command starts apache #
#################################
CMD apachectl -D FOREGROUND
