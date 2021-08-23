# shinysender

<!-- badges: start -->

<!-- badges: end -->

The aim of this package is to provide tools and a Shiny app to allow users to easily send their Shiny apps to a remote Shiny Server.

## Usage

The server you wish to send the apps to can be specified using the `server=` parameter of `ss_connect()`, or by setting the `SHINYSENDER_SERVER` environment variable, e.g. in `~/.Renviron`.

You will need to have a user account on the remote server already set up. If this is set up to use ssh keys then these will be used. Otherwise you will be prompted for the account password.

### Basic workflow

```{r}
# Connect to shiny server, using the same login name as the local account
# (this can be overriden by setting the SHINYSENDER_USER environment variable
# and the server set in the SHINYSENDER_SERVER environment variable
# User will be prompted for password if not using ssh keys
session <- ss_connect()

# Set up the user's account on the server to use Packrat packages
# (This only needs to be done once)
ss_setupserver(session)

# List apps on Shiny server
ss_listapps(session)

# Upload app stored in ~/testapp to server as an app called demo
# This will automatically set up the package environment to match the user's local computer
# This will take some time for the first app you install, since we need to build
# all of its library dependencies from source.  Subsequent updates and other apps will
# use cached versions of the libraries.
ss_uploadappdir(session, "~/testapp/", "demo")

# Delete app "demo" on the server
ss_deleteapp(session, "demo")

# Disconnect from the server
ss_disconnect(session)
```

If you're using RStudio, you may find it easier to use the "Upload app" addin. To use this just set the remote server's name and your user name on it using the SHINYSENDER_SERVER and SHINYSENDER_USER environment variables:

```{r}
Sys.setenv(SHINYSENDER_SERVER="myshinyserver.com")
Sys.setenv(SHINYSENDER_USER="alice")

```

With your working directory set to the application's directory, select Addins, Upload App from the main toolbar (this can be bound to a keyboard shortcut (Tools, Modify Keyboard Shortcuts).

By default the name of the app on the remote server will be the same as the basename of your working directory. You can override the name of the app on the remote server by setting the SHINYSENDER_REMOTENAME environment variable.

If you always use the same settings, it may be easier to [set these in a .Renviron file](https://support.rstudio.com/hc/en-us/articles/360047157094-Managing-R-with-Rprofile-Renviron-Rprofile-site-Renviron-site-rsession-conf-and-repos-conf).

## R Markdown documents

It is possible to host interactive R Markdown documents, as described [here](https://bookdown.org/yihui/rmarkdown/shiny-documents.html). You will need to ensure that you have an `index.Rmd` document in your deployment directory. The document can then be deployed in the same way as a Shiny app.

## Non CRAN repositories

If you are using non-CRAN packages, you will need to install them using `devtools::install_github()`. For example: `devtools::install_github("tidyverse/ggplot2")` will install the development version of ggplot2.

If your package is in a private repository, you will need to [generate a personal access token](https://github.com/settings/tokens), with the "repo" scope. Put this in the `GITHUB_PAT` environment variable: `Sys.setenv(GITHUB_PAT="mytoken")`. The environment variable will need to be set before using `devtools::install_github()`, and when uploading your app. The token will be used to install the private repositories on the remote sever, but will not be stored on it.

Locally hosted packages (i.e. an R package source that only exists on your local machine) cannot be included in the "bundle" that is sent to the remote server - you will need to put them on Github, and then install them as described above.

### .Rprofile

The deployed app uses Packrat to emulate your local development environment. This is set up to cache installed libraries (and their versions) between all your apps. This process is set up in the `.Rprofile` file in the deployed app's directory on the server.

If you have a project level `.Rprofile`, this will be uploaded to the remote server and modified to use Packrat - your local `.Rprofile` will not be edited. If you do not have a project level `.Rprofile` a new one will be created on the remote machine.

If your user level `.Rprofile` on your local machine is contains settings that your app *requires*, you will need to copy these to a project level `.Rprofile` so that the server can use them.

Note that R only runs a *single* `.Rprofile` on startup - this will be the project level `.Rprofile`, if it exists, and the user level one otherwise - see <https://rstats.wtf/r-startup.html> for more details.

### Setting up the remote Server

(these notes are currently incomplete)

-   Tested using Ubuntu 21.04

-   Check homedir permissions - should be set correctly on 21.04, but not on earlier versions. Don't want to be able to access others' home dir.

-   Install Packrat as root from CRAN

-   Dependencies for Tidyverse: `sudo apt install libcurl4-openssl-dev libssl-dev libxml2-dev` (from <https://blog.zenggyu.com/en/post/2018-01-29/installing-r-r-packages-e-g-tidyverse-and-rstudio-on-ubuntu-linux/>)

-   Other development libraries we're likely to need: library deb name (package needed for)

    -   libfontconfig1-dev (freetype)

    -   libcairo2-dev (cairo)

    -   libudunits2-dev (units (sf dependency))

    -   libgdal-dev (sf)

-   Will need to set http_proxy and https_proxy for downloading packages on RVM

(Library dependencies - this could get quite complicated - see: <https://github.com/rstudio/r-system-requirements> <https://github.com/r-hub/sysreqsdb> for two (different) databases of OS package dependencies for R libraries. `getdeps.R` will produce a (draft) apt install line for a given set of packages)

### Server notes - Ubuntu 20.04

Using Ubuntu 20.04

Install system libraries for common packages (The following covers the packages installed on the standard desktop image - had to tweak tcl and libopenmpi versions from autogenerated), plus dependencies needed for systemPipeShiny (which we use for testing, as it's complicated with lots of dependencies):

    sudo apt install pandoc pandoc-citeproc libssl-dev libxml2-dev libcurl4-openssl-dev libcairo2 libcairo2-dev git-core zlib1g-dev jags default-jre-headless libopenmpi3 libopenmpi-dev libomp-dev make libgit2-dev libssh2-1-dev libgmp10 libgmp-dev libglpk-dev libpng-dev python gdal-bin libproj-dev libgdal-dev libmpfr-dev libgeos-dev libgeos++-dev libsodium-dev libicu-dev tcl8.6 tk8.6 tk-table libudunits2-dev libv8-dev librsvg2-dev

Install R following instructions at <https://docs.rstudio.com/resources/install-r/> (I went with most recent version (4.1.1 at time of writing). Note `r-base` with Ubuntu 20.04 is very old, so don't use Ubuntu provided packages. Set up the symlinks as described on that page.

Start R as root, and install shiny, rmarkdown and packrat packages:

`sudo R`

`install.packages(c("shiny", "rmarkdown", "packrat"))`

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

    # Define a server that listens on port 3838
    server {
      listen 3838;


      location /user {
        run_as :HOME_USER:;
        user_dirs;
        directory_index off;
      }

    }

Restart Shiny Server `sudo service shiny-server restart`

Make it so that user's cannot read others' home directories (<https://superuser.com/a/615990>): update `DIR_MODE` to `DIR_MODE=0750` in `/etc/adduser.conf` and change permissions on any existing homedirs.

(ShinyServer "su"s to the user when serving apps from `~/ShinyApps`, so this will still work)

Add users with `adduser`

### Shinyproxy notes (very incomplete)

This section contains notes and thoughts about how we might switch to a Shinyproxy based setup. This would provide better scaling for apps, since each user gets their own copy in its own Dockerised instance.

Published apps need to be added to `application.yml` and the server restarted. This causes all current users sessions to be ended. <https://shinyproxy.io/documentation/configuration/#session-persistence> suggests we can keep the sessions open using Redis (unclear what happens during the \~20 seconds the Shinyproxy is restarting and we get a 502 error)

If we go down this route, we'd probably want to mount /home as /home in Docker container (how to handle permissions???) so the Packrat libraries are available (and in the same place within and without the container)

(See also notes on local Wekan server)
