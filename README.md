# shinysender

<!-- badges: start -->

[![R-CMD-check](https://github.com/UoMResearchIT/r-shinysender/workflows/R-CMD-check/badge.svg)](https://github.com/UoMResearchIT/r-shinysender/actions)
[![Codecov test coverage](https://codecov.io/gh/UoMResearchIT/r-shinysender/branch/master/graph/badge.svg)](https://app.codecov.io/gh/UoMResearchIT/r-shinysender?branch=master)
<!-- badges: end -->

The aim of this package is to provide tools and a Shiny app to allow users to easily send their Shiny apps to the University of Manchester's pilot Shiny server.
Apps published on the server will be public.  To obtain an account on the server please email its-ri-team@manchester.ac.uk to request access.

(If you wish to use the package for another Shiny server, please see the notes at the end of this file)

## Usage

### 1. Make sure you have access to the server

> [!WARNING]
> **You must be on the campus network\* to upload an app**  

You do not need to be on Campus to view an app; these are visible worldwide.

SSH access through GlobalProtect was disabled due to the phishing-incident in 2023, and as of 02/2025 it is still not available.

If you are unsure, open a terminal (PowerShell on Windows) and try to `ssh` into the server with your `<userid>`:
```
ssh <userid>@shiny.its.manchester.ac.uk
```

### 2. Install the shinysender package

From an R console:

```{r}
install.packages("devtools")  # If you don't already have devtools installed
devtools::install_github("UoMResearchIT/r-shinysender")
```

> [!NOTE]
> If your `packageVersion("rsconnect")` is **older than 0.8**, update your `Rstudio`, or try using the old version in the [rsconnect_0.8](https://github.com/UoMResearchIT/r-shinysender/tree/rsconnect_0.8) branch. Replacing the command above with:
>
> ```{r}
> devtools::install_github("UoMResearchIT/r-shinysender@rsconnect_0.8")
> ```

### 3. Prepare your environment:

* Set your working directory to your Shiny app's application directory (this will usually happen automatically when
you load the project)

* Set the name of the server and your username on it:

```{r}
# This is UoM pilot server - must be connected via global protect
# to upload your app.  Deployed apps will be visible on the public
# internet.  
Sys.setenv(SHINYSENDER_SERVER="shiny.its.manchester.ac.uk")

# Your username is your UoM login
Sys.setenv(SHINYSENDER_USER="alice")
```

(you may wish to add these lines to `~/.Rprofile`, to avoid having to set them each time you start R --  see [.Rprofile / .Renviron](#rprofile--renviron) below)

* By default, your app will have the name of your local project directory, to set it to something different, set the `SHINYSENDER_REMOTENAME`
environment variable before deploying: `Sys.setenv('SHINYSENDER_REMOTENAME="appname")`.

> [!IMPORTANT]
> App names must be alphanumeric (and may contain hyphens or underscores, but no spaces), between 4 and 63 characters long. Names are case-sensitive.

* If you are using packages from GitHub, you will have to make sure you have an active access token see [Non CRAN packages](#Non-CRAN-packages) below.

* If you are using the [Golem Framework](https://github.com/ThinkR-open/golem), you will need to run `golem::add_shinyserver_file()` before deploying your app.

### 4. (Optional) create an `.rscignore` file

To reduce the size of your app on the server (and speed up the upload process), create a file called `.rscignore` on your project base directory,
and populate it with files and folders that are not required for your app to run, e.g.:

```
.git
.Rhistory
.Rprofile
.Rproj.user

data-raw
...
```
> Note: unfortunately, `.rscignore` files don't take wildcards, so you'll have to list each file or parent directory explicitly.

### 5. Upload your app

* In Rstudio: Addins, Upload App from the main toolbar (this can be bound to a keyboard shortcut (Tools, Modify Keyboard Shortcuts).
* Or, if you're running outwith RStudio, run `shinysender::ss_uploadAddin()` from the console
* You will be prompted for your UoM password.  
* The app will be bundled and deployed on the remote server.  The first time you deploy any app, this will likely take some time
since the system needs to download and compile the same versions of the R libraries you're using as on your local system. Subsequent
deployments will use cached copies and so will be much quicker.
* You can deploy the app again to update it

You may get a warning about the version of R on the server being different to your
local version.  It is usually safe to ignore this.

# Troubleshooting / Advanced workflow

`shinysender::ss_uploadAddin()` will try to perform the following steps:

1. Establish a connection to the server using `ssh::ssh_connect`
1. Prepare the application for uploading, using `rsconnect:::bundleApp`
1. Send the app to the server (`~/ShinyApps_staging/<appname>`), using `ssh::scp_upload`
1. Replicate your local R environment on the server, using `renv::restore`
1. Move the app to `~/ShinyApps/<appname>`, where it will be picked up by the `shinyserver`

If you found a problem, or you want to do anything more complex, the following code may help:

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

In some cases, restoring the `renv` lockfile will fail on the server, even when the app uploaded successfully (your app will be uploaded, but it will fail to run, or display with errors). You can troubleshoot this manually via an interactive R session on the server:

Open a terminal and try to `ssh` into the server with your `<userid>`; navigate to your <appname> folder, and run `R` to open an interactive session:
```bash
ssh <userid>@shiny.its.manchester.ac.uk
cd ~/ShinyApps/<appname>
R
```

From there, try:
```R
> renv::status()
> renv::restore() 
```

## Debugging your app

Make sure that your app runs locally, that it has effectively been uploaded (use a version tag), and that all of the libraries have been installed and synced correctly (see `renv::status()` above).

The server is configured to store application logs on your home folder, specifically: `~/ShinyApps/logs`. However in many cases (e.g. when the app fails to launch) these can get deleted automatically. To avoid this, place a file called `.shiny_app.conf` on your application root folder (next to your `app.R` or `ui.R` / `server.R` files), with the content:
```.shiny_app.conf
preserve_logs true;
```

You can explore and read your app logs from a remote terminal:
```sh
ssh <userid>@shiny.its.manchester.ac.uk
cd ~/ShinyApps/logs

# list existing logs
ls

# print the contents of the most recent log
cat $(ls -Art | tail -n 1)

# print the last lines of the most recent (active) log, and reflect changes dynamically (Ctrl+C to exit)
tail -f $(ls -Art | tail -n 1)
```

Once you're happy with your app, you might want to remove the `.shiny_app.conf` file, or come back and erase the contents of `~/ShinyApps/logs` once in a while.

## R Markdown documents

It is possible to host interactive R Markdown documents, as described [here](https://bookdown.org/yihui/rmarkdown/shiny-documents.html). *You will need to ensure that you have an `index.Rmd` document in your deployment directory.* The document can then be deployed in the same way as a Shiny app.

## Golem framework

If you are using the [Golem Framework](https://github.com/ThinkR-open/golem) to develop your app, you will need to run
`golem::add_shinyserver_file()` before deploying your app.

## Non CRAN packages

If you are using non-CRAN packages, you will need to install them using `devtools::install_github()`. For example: `devtools::install_github("tidyverse/ggplot2")` will install the development version of ggplot2.

If your package is in a private repository, you will need to [generate a personal access token](https://github.com/settings/tokens), with the "repo" scope. Put the token in the `GITHUB_PAT` environment variable: `Sys.setenv(GITHUB_PAT="mytoken")`. The environment variable will need to be set before using `devtools::install_github()`, and when uploading your app. The token will be used to install the private repositories on the remote sever, but will not be stored on it.

Locally hosted packages (i.e. an R package source that only exists on your local machine) cannot be included in the "bundle" that is sent to the remote server - you will need to put them on Github, and then install them as described above. This is because the remote machine has no way of getting the source for your local package.

### Bioconductor

If your app uses Bioconductor packages, run `options(repos = BiocManager::repositories())` before deploying your app. 

## .Rprofile / .Renviron

The deployed app uses `renv` to emulate your local development environment (even if don't do it explicitly). It will be set up to cache installed libraries (and their versions) between all your apps, by means of the `.Renviron` and `.Rprofile` files in the deployed app's directory on the server.

> [!WARNING]
> If you have an `.Renviron` file, it will be overwritten on the server. Replace it by including the affected variables in `Sys.setenv` calls inside your local `.Rprofile`.

If you have a project level `.Rprofile`, this will be uploaded to the remote server and modified to use `renv` - your local `.Rprofile` will not be edited. If you do not have a project level `.Rprofile` a new one will be created on the remote machine. If your *user* level `.Rprofile` on your local machine contains settings that your app *requires*, you will have to copy these to a project level `.Rprofile` so that the server can use them.

Note that R only runs a *single* `.Rprofile` on startup - this will be the project level `.Rprofile`, if it exists, and the user level one otherwise - see <https://rstats.wtf/r-startup.html> for more details.

## Overriding the default proxy

If you need to override the default proxy (used to download packages during staging), set the required server and port in the `SHINYSENDER_PROXY` environment variable:

```{r}
Sys.setenv(SHINYSENDER_PROXY="http://myproxy.co.uk:3128")
```

(To set the http and https proxies to different servers, instead use SHINYSENDER_PROXY_HTTP and
SHINYSENDER_PROXY_HTTPS environment variables) 

## Shiny training

https://uomresearchit.github.io/r-shiny-course/ contains the notes for a half day workshop on developing Shiny apps.  This may be useful if you haven't used Shiny before

## Embedding your app in an existing webpage

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

The ssh fingerprints of the pilot shiny server are:
```
256 SHA256:/4TL+4cIftoWaRuCjJrCKJWUWKl+6Vek+M6Xf5erIMI shiny.its.manchester.ac.uk (ECDSA)
3072 SHA256:UQaTb8LetrR2yK6qEDAOqQa8CAdPXcglh+mA3+NcHkg shiny.its.manchester.ac.uk (RSA)
256 SHA256:eePFU2itdNN2KCRh3R8gjemn6fOnoZZbP6yPsVN5jGc shiny.its.manchester.ac.uk (ED25519)
```
On of these should be shown the first time you connect to the service.

## Other servers

This package was originally written for the University of Manchester Shiny Pilot service.  If the package is used with this server it will automatically
set up the required web proxy. If you are using another server, no web proxy will be set by default.

If you need to use a different web proxy, then set _either_ the `SHINYSENDER_PROXY` environment variable, or, if you require a different proxy address for http and https, set `SHINYSENDER_PROXY_HTTP` and `SHINYSENDER_PROXY_HTTPS`.  (setting `SHINYSENDER_PROXY` sets the http and https proxy to the same address). In all cases, the variable should be set to the full URL, including protocol, e.g. `Sys.setenv(SHINYSENDER_PROXY="http://myproxy.co.uk:3128")`

### Server setup

This section contains some minimal instructions for setting up a new Shiny server to use with this package.  It should work
with any server that's setup to deploy apps from users' home directories. The main thing is that this package 
expects the Shiny, Rmarkdown, Packrat and Devtools libraries to be available to all users.

Note that the URL of the deployed app assumes that the apps are on https, and 
that the location section of `shiny-server.conf` is set up as in the example below

Using Ubuntu 20.04

Install R following instructions at <https://docs.posit.co/resources/install-r.html>. 

> [!IMPORTANT]
> Don't install using Ubuntu PPA's (as in <https://cran.r-project.org/bin/linux/ubuntu/>). This makes it easy to upgrade the R version by mistake (e.g. by apt upgrade), breaking user's libraries... it happened to a friend.

Install common packages (and their system requirements). The easiest is to use `pak`, running R as root:

```sh
sudo R
```

```r
# You might want to tweak this list depending on your user's needs
common_packages <- c('tidyverse','devtools','shiny','markdown','sf','renv')

install.packages('pak')
pak::pkg_install(common_packages, ask = FALSE)
q()
```

For troubleshooting, you might want to use `pak::pkg_sysreqs(common_packages)`

Install Shiny server (<https://www.rstudio.com/products/shiny/download-server/ubuntu/>), e.g.:

(check you're getting latest version of Shiny Server - note URL is ubuntu-14.04, even though we're using 20.04)

```
sudo apt-get install gdebi-core
wget https://download3.rstudio.org/ubuntu-20.04/x86_64/shiny-server-1.5.23.1030-amd64.deb
sudo gdebi shiny-server-1.5.23.1030-amd64.deb
```

(Note that there isn't a repository for shiny-server, so it won't update with `apt-get etc...`, so you'll need to keep an eye on new versions manually.
The product information email list at: https://www.rstudio.com/about/subscription-management/  should inform you when an update is out.)

Check Shiny server is working correctly - go to <http://server:3838>, and check the Shiny and RMarkdown apps appear in frames on the right hand side.

Setup timezone on the server

`sudo dpkg-reconfigure tzdata`


Edit `/etc/shiny-server/shiny-server.conf`:

    # Instruct Shiny Server to run applications as the user "shiny"
    run_as shiny;

    # Define a server that listens on port 3838 on localhost
    # You will probably want to put this behind a reverse proxy, or listen on all interfaces if accessing directly
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

