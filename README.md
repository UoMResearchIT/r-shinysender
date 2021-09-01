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

## Golem framework

If you are using the [Golem Framework](https://github.com/ThinkR-open/golem) to develop your app, you will need to run
`golem::add_shinyserver_file()` before deploying your app.

## Non CRAN repositories

If you are using non-CRAN packages, you will need to install them using `devtools::install_github()`. For example: `devtools::install_github("tidyverse/ggplot2")` will install the development version of ggplot2.

If your package is in a private repository, you will need to [generate a personal access token](https://github.com/settings/tokens), with the "repo" scope. Put this in the `GITHUB_PAT` environment variable: `Sys.setenv(GITHUB_PAT="mytoken")`. The environment variable will need to be set before using `devtools::install_github()`, and when uploading your app. The token will be used to install the private repositories on the remote sever, but will not be stored on it.

Locally hosted packages (i.e. an R package source that only exists on your local machine) cannot be included in the "bundle" that is sent to the remote server - you will need to put them on Github, and then install them as described above.

### Bioconductor

If your app uses Bioconductor packages, run `options(repos = BiocManager::repositories())` before deploying your app. 

### .Rprofile

The deployed app uses Packrat to emulate your local development environment. This is set up to cache installed libraries (and their versions) between all your apps. This process is set up in the `.Rprofile` file in the deployed app's directory on the server.

If you have a project level `.Rprofile`, this will be uploaded to the remote server and modified to use Packrat - your local `.Rprofile` will not be edited. If you do not have a project level `.Rprofile` a new one will be created on the remote machine.

If your user level `.Rprofile` on your local machine is contains settings that your app *requires*, you will need to copy these to a project level `.Rprofile` so that the server can use them.

Note that R only runs a *single* `.Rprofile` on startup - this will be the project level `.Rprofile`, if it exists, and the user level one otherwise - see <https://rstats.wtf/r-startup.html> for more details.

(Technical aside:  We actually modify the user's `.Rprofile` twice - for staging we need to load `devtools`, and set the Packrat cache
but not _actually_ turn packrat on - otherwise we can't see devtools and its dependencies to install private Github repos.  Once the apps
libraries have been restored, we remove the staging `.Rprofile` code and replace it with a deployment version, which 
sets the cache location and turns Packrat on. 
