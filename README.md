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

### Shinyproxy notes (very incomplete)

This section contains notes and thoughts about how we might switch to a Shinyproxy based setup. This would provide better scaling for apps, since each user gets their own copy in its own Dockerised instance.

Published apps need to be added to `application.yml` and the server restarted. This causes all current users sessions to be ended. <https://shinyproxy.io/documentation/configuration/#session-persistence> suggests we can keep the sessions open using Redis (unclear what happens during the \~20 seconds the Shinyproxy is restarting and we get a 502 error)

If we go down this route, we'd probably want to mount /home as /home in Docker container (how to handle permissions???) so the Packrat libraries are available (and in the same place within and without the container)

The Docker image we run will need to be the same version of Ubuntu as the host OS (since we use the packrat libraries in the app directory; these will have been compiled on the host OS when we deploy the app).

We ideally want to run the container containing the app as the user whose app it is (rather than doing everything as root). This appears to be possible: <https://github.com/openanalytics/shinyproxy/issues/164> (though each user will need their own custom image - space wise this won't be an issue, since all the big layers will be shared). The user's home directory will need to be mounted *to the same location* in Docker, i.e. `-v /home/alice:/home/alice`

The container will need to contain the same libraries, e.g. libcurl etc., as the host.

### Launching the app

We need to source the app's .Rprofile (so we get packrat setup), and then launch the app.

    docker run  -v /home/david:/home/david   -p4040:4040 openanalytics/shinyproxy-demo R -e "setwd('/home/david/ShinyApps/testapp2'); source('.Rprofile'); shiny::runApp('/home/david/ShinyApps/testapp2', port = 4040, host = '0.0.0.0')"

Works from the command line, so we need the ""ed string in our Shinyproxy's application.yml

`shinyproxy/` contains a rough Dockerfile and application.yml to use with Shinysender apps (these don't implement running as a non-root user).

### Updating `application.yml`

We will need to scan users' `~/ShinyApps` to generate the appropriate configs for each app. Shinyproxy will only deploy to a single location (e.g. shinyserver.com/app_direct/appname, not shinyserver.com/app_direct/david/appname). We *can* use hyphens in the Shinyproxy appname - may be possible to do some URL rewriting in e.g. nginx to convert `david-testapp` to `david/testapp`

Will need disable `shinyserver.com/app` URLs, to prevent everything on the server being listed. This should be doable in the web proxy config.

`shinyproxy/shinyproxytemplate` contains some rough Python code to scan users' \~/ShinyApps and output an application.yml to stdout. This uses jinja for the templating (in python3-jinja2 package).

Next steps - run this as a cron job on the server, and restart Shinyproxy if changed. Will (eventually) need to report differences and failure by email.

To think about:

* Should we rehydrate the Packrat cache within the container (rather than on the server directly)?  Would need to sort out user permissions first.  This would have the benefit that we could support multiple R versions on the server (since each can have its own Docker container).  Packrat uses R version specific directories so shouldn't get any clashes there.
* 
