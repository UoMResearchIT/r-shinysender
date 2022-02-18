# shinysender

<!-- badges: start -->

[![R-CMD-check](https://github.com/UoMResearchIT/r-shinysender/workflows/R-CMD-check/badge.svg)](https://github.com/UoMResearchIT/r-shinysender/actions)
[![Codecov test coverage](https://codecov.io/gh/UoMResearchIT/r-shinysender/branch/master/graph/badge.svg)](https://app.codecov.io/gh/UoMResearchIT/r-shinysender?branch=master)
<!-- badges: end -->

The aim of this package is to provide tools and a Shiny app to allow users to easily send their Shiny apps to the University of Manchester's pilot Shiny server.
Apps published on the server will be public.  To obtain an account on the server please email david.mawdsley@manchester.ac.uk to request access.

## Usage

*You must be connected to Globalprotect to upload an app*
(You do not need to be connected to Globalprotect to view an app -these are visible worldwide)

* Install the shinysender package:
```{r}
install.packages("devtools")  # If you don't already have devtools installed
devtools::install_github("UoMResearchIT/r-shinysender")

```

* Set the name of the server and your username on it:

```{r}
# This is UoM pilot server - must be connected via global protect
# to upload your app.  Deployed apps will be visible on the public
# internet.  
Sys.setenv(SHINYSENDER_SERVER="shiny.its.manchester.ac.uk")  
# Your username is your UoM login
Sys.setenv(SHINYSENDER_USER="alice")
```

(you may wish to add these lines to `~/.Rprofile`, or set the environment variables
in `~/.Renviron`, to avoid having to set them each time you start R)


* Set your working directory to your Shiny app's application directory (this will usually happen automatically when
you load the project)
* In Rstudio: Addins, Upload App from the main toolbar (this can be bound to a keyboard shortcut (Tools, Modify Keyboard Shortcuts).
* Or, if you're running outwith RStudio, run `shinysender::ss_uploadAddin()` from the console
* You will be prompted for your UoM password.  
* The app will be bundled and deployed on the remote server.  The first time you deploy any app, this will likely take some time
since the system needs to download and compile the same versions of the R libraries you're using as on your local system. Subsequent
deployments will use cached copies and so will be much quicker.
* You can deploy the app again to update it
* By default, your app will have the name of your local project directory, to set it to something different, set the `SHINYSENDER_REMOTENAME`
environment variable before deploying: `Sys.setenv('SHINYSENDER_REMOTENAME="appname")`.

You may get a warning about the version of R on the server being different to your
local version.  It is usually safe to ignore this.

## Overriding the default proxy

The package uses the UoM web proxy to download the packages needed during app
staging.  If you need to override this, set the required server and port in the
`SHINYSENDER_PROXY` environment variable:

```{r}
Sys.setenv(SHINYSENDER_PROXY="myproxy.co.uk:3128")
```



# Advanced workflow

If you want to do anything more complex, the following code may help:

```{r}
library(shinysender)

# Connect to shiny server, using the same login name as the local account
# (this can be overriden by setting the SHINYSENDER_USER environment variable
# and the server set in the SHINYSENDER_SERVER environment variable
# User will be prompted for password if not using ssh keys
session <- ss_connect()


# Set up the user's account on the server to use Packrat packages
# (This only needs to be done once)
ss_setupserver(session)

# List apps on Shiny server
ss_listdir(session)

# Upload app stored in ~/testapp to server as an app called demo
# This will automatically set up the package environment to match the user's local computer
# This will take some time for the first app you install, since we need to build
# all of its library dependencies from source.  Subsequent updates and other apps will
# use cached versions of the libraries.
ss_uploadappdir(session, "~/testapp/", "demo")


# Show the most recent log file for app "demo"
ss_getlogs(session, "demo")

# Delete app "demo" on the server
ss_deleteapp(session, "demo")

# Disconnect from the server
ss_disconnect(session)
```


## R Markdown documents

It is possible to host interactive R Markdown documents, as described [here](https://bookdown.org/yihui/rmarkdown/shiny-documents.html). *You will need to ensure that you have an `index.Rmd` document in your deployment directory.* The document can then be deployed in the same way as a Shiny app.

## Golem framework

If you are using the [Golem Framework](https://github.com/ThinkR-open/golem) to develop your app, you will need to run
`golem::add_shinyserver_file()` before deploying your app.

## Non CRAN repositories

If you are using non-CRAN packages, you will need to install them using `devtools::install_github()`. For example: `devtools::install_github("tidyverse/ggplot2")` will install the development version of ggplot2.

If your package is in a private repository, you will need to [generate a personal access token](https://github.com/settings/tokens), with the "repo" scope. Put the token in the `GITHUB_PAT` environment variable: `Sys.setenv(GITHUB_PAT="mytoken")`. The environment variable will need to be set before using `devtools::install_github()`, and when uploading your app. The token will be used to install the private repositories on the remote sever, but will not be stored on it.

Locally hosted packages (i.e. an R package source that only exists on your local machine) cannot be included in the "bundle" that is sent to the remote server - you will need to put them on Github, and then install them as described above. This is because the remote machine has no way of getting the source for your local package.

### Bioconductor

If your app uses Bioconductor packages, run `options(repos = BiocManager::repositories())` before deploying your app. 

### .Rprofile

The deployed app uses Packrat to emulate your local development environment. This is set up to cache installed libraries (and their versions) between all your apps. This is set up in the `.Rprofile` file in the deployed app's directory on the server.

If you have a project level `.Rprofile`, this will be uploaded to the remote server and modified to use Packrat - your local `.Rprofile` will not be edited. If you do not have a project level `.Rprofile` a new one will be created on the remote machine.

If your *user* level `.Rprofile` on your local machine is contains settings that your app *requires*, you will need to copy these to a project level `.Rprofile` so that the server can use them.

Note that R only runs a *single* `.Rprofile` on startup - this will be the project level `.Rprofile`, if it exists, and the user level one otherwise - see <https://rstats.wtf/r-startup.html> for more details.

(Technical aside:  We actually modify the user's `.Rprofile` twice - for staging we need to load `devtools`, and set the Packrat cache
but not _actually_ turn packrat on - otherwise we can't see devtools and its dependencies to install private Github repos.  Once the apps
libraries have been restored, we remove the staging `.Rprofile` code and replace it with a deployment version, which 
sets the cache location and turns Packrat on.  The staging `.Rprofile` also configure the UoM web proxy so we can download packages.  The deployed `.Rprofile`
doesn't set up access to the UoM web proxy, so deployed apps will be unable to access remote sites.  If this functionality is needed the proxy will need to 
be set in the local `.Rprofile` before deployment).

### Shiny training

https://uomresearchit.github.io/r-shiny-course/ contains the notes for a half day workshop on developing Shiny apps.  This may be useful if you haven't used Shiny before

### Embedding your app in an existing webpage

It isn't (currently) possible to change the URL of deployed apps (i.e. they will always be https://shiny.its.manchester.ac.uk/username/appname).  You may want 
to embed your app within an existing web page.  This can be done with an iframe.  The fragement of html code below gives an example:

```{html}
<iframe width="100%" height="700px" name="iframe" src="https://shiny.its.manchester.ac.uk/username/appname" 
    frameborder="0" 
    scrolling="no" 
    onload="resizeIframe(this)">
</iframe>
```

(This is the technique we use to embed the example Shiny app in the Shiny course referred to above)

### Server fingerprint

The ssh fingerprint of the pilot shiny server is
`26:0d:42:55:99:32:1b:75:3d:38:2d:dc:c8:08:1b:0b:40:f9:e9:e6`
This will be shown the first time you connect to the service





### Setting up the remote Server
(This is only needed if you're planning on deploying a new server -
end users don't need this)


Using Ubuntu 20.04

Install system libraries for common packages (The following covers the packages installed on the standard desktop image - had to tweak tcl and libopenmpi versions from autogenerated), plus dependencies needed for systemPipeShiny (which we use for testing, as it's complicated with lots of dependencies):

    sudo apt install pandoc pandoc-citeproc libssl-dev libxml2-dev libcurl4-openssl-dev libcairo2 libcairo2-dev git-core zlib1g-dev jags default-jre-headless libopenmpi3 libopenmpi-dev libomp-dev make libgit2-dev libssh2-1-dev libgmp10 libgmp-dev libglpk-dev libpng-dev python gdal-bin libproj-dev libgdal-dev libmpfr-dev libgeos-dev libgeos++-dev libsodium-dev libicu-dev tcl8.6 tk8.6 tk-table libudunits2-dev libv8-dev librsvg2-dev libssh-dev libxt-dev libcairo-5c-dev



(This list covers most of the debs needed for common R packages - e.g. tidyverse, sf, etc.
See: <https://github.com/rstudio/r-system-requirements> and <https://github.com/r-hub/sysreqsdb> for two (different) databases of OS package dependencies for R libraries. `./librarydeps/getdeps.R` will produce a (draft) apt install line for a given set of packages)


Install R following instructions at <https://docs.rstudio.com/resources/install-r/> (I went with most recent version (4.1.1 at time of writing). Note `r-base` with Ubuntu 20.04 is very old, so don't use Ubuntu provided packages. Set up the symlinks as described on that page.

Start R as root, and install shiny, rmarkdown, devtools and packrat packages:

`sudo R`

`install.packages(c("shiny", "rmarkdown", "packrat", "devtools"))`

`q()`

Install Shiny server (<https://www.rstudio.com/products/shiny/download-server/ubuntu/>), e.g.:

(check you're getting latest version of Shiny Server - note URL is ubuntu-14.04, even though we're using 20.04)

    sudo apt-get install gdebi-core
    wget https://download3.rstudio.org/ubuntu-14.04/x86_64/shiny-server-1.5.16.958-amd64.deb
    sudo gdebi shiny-server-1.5.16.958-amd64.deb

Check Shiny server is working correctly - go to <http://server:3838>, and check the Shiny and RMarkdown apps appear in frames on the right hand side.

Setup timezone on the server

`sudo dpkg-reconfigure tzdata`

Edit `/etc/shiny-server/shiny-server.conf`:

    # Instruct Shiny Server to run applications as the user "shiny"
    run_as shiny;

    # Define a server that listens on port 3838 on localhost
    server {
      listen 3838 127.0.0.1;


      location / {
        run_as :HOME_USER:;
        user_dirs;
        directory_index off;
      }

    }

Restart Shiny Server `sudo service shiny-server restart`

Make it so that user's cannot read others' home directories (<https://superuser.com/a/615990>): update `DIR_MODE` to `DIR_MODE=0750` in `/etc/adduser.conf` and change permissions on any existing homedirs.

(ShinyServer "su"s to the user when serving apps from `~/ShinyApps`, so this will still work)

Add users either using `adduser` for regular accounts / RIT script for UoM authentication.

### Nginx

We use a reverse proxy to serve the apps, and handle https

Modify `location /` of `/etc/nginx/sites-available/default` to:

```
        location / {
                # First attempt to serve request as file, then
                # as directory, then fall back to displaying a 404.
#               try_files $uri $uri/ =404;
                proxy_pass http://127.0.0.1:3838/;
                proxy_redirect http://127.0.0.1:3838/ $scheme://$host/;
                proxy_http_version 1.1;

                # $http_upgrade and $connection_upgrade are set up
                # in /etc/nginx/nginx.conf
                proxy_set_header Upgrade $http_upgrade;
                proxy_set_header Connection $connection_upgrade;
                proxy_read_timeout 20d;
                proxy_buffering off;
        }

```

Add the following to the `http` section of `/etc/nginx/nginx.conf`:


```
        # For Shiny proxy
          map $http_upgrade $connection_upgrade {
            default upgrade;
            ''      close;
        }


```

(based on https://www.r-bloggers.com/2016/03/add-authentication-to-shiny-server-with-nginx/ and https://support.rstudio.com/hc/en-us/articles/213733868-Running-Shiny-Server-with-a-Proxy)

Edit `/etc/issue.net` to make it clear that the server is only for hosting public Shiny apps, and that the user is responsible for them. (This text will be displayed in the R console when the user connects to the server)

### https

We use [Let's Encrypt](https://letsencrypt.org/getting-started/) to handle the 
server certificates for https.  Certbot automatically sets this up using the 
nginx config

