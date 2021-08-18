FROM library/ubuntu:hirsute
#FROM rocker/r-ver:4.0.4
#openanalytics/r-base

# Based on Openanalytic's shinyproxy-demo image

#MAINTAINER Tobias Verbeke "tobias.verbeke@openanalytics.eu"
Remove debug code
# This is to stop it prompting for timezone.  Will use UTC by default
# TO do properly, see https://stackoverflow.com/questions/44331836/apt-get-install-tzdata-noninteractive
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    sudo \
    pandoc \
    pandoc-citeproc \
#    libcurl4-gnutls-dev \
    libcairo2-dev \
    libxt-dev \
    libssl-dev \
    libssh2-1-dev \
    libssl1.1 \
    r-base r-base-dev \
    libcurl4-openssl-dev libssl-dev libxml2-dev \
    libfontconfig1-dev libcairo2-dev libudunits2-dev libgdal-dev

# Roll up with previous command before release
RUN apt-get install -y wget


# packages needed for basic shiny functionality
# We don't need Shiny image-wide, since it'll be in the app's Packrat dir
#RUN R -e "install.packages(c('shiny', 'rmarkdown'), repos='https://cloud.r-project.org')"
# Install packrat
RUN R -e "install.packages(c('packrat'), repos='https://cloud.r-project.org')"
# install shinyproxy package with demo shiny application
#COPY shinyproxy_0.0.1.tar.gz /root/
#RUN R CMD INSTALL /root/shinyproxy_0.0.1.tar.gz
#RUN rm /root/shinyproxy_0.0.1.tar.gz

# set host and port
#COPY Rprofile.site /usr/lib/R/etc/

EXPOSE 3838

#CMD ["R", "-e", "shinyproxy::run_01_hello()"]
