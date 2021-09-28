# shinysender

<!-- badges: start -->

<!-- badges: end -->

The aim of this package is to provide tools and a Shiny app to allow users to easily send their Shiny apps to a remote Shiny Server.

## Usage

*You must be connected to Globalprotect to access the server*

* Install the shinysender package:
```{r}
install.packages("devtools")  # If you don't already have devtools installed
devtools::install_github("UoMResearchIT/r-shinysender")

```

* Set the name of the server and your username on it:

```{r}
# This is UoM pilot server - must be connected via global protect
Sys.setenv(SHINYSENDER_SERVER="10.99.97.195")  
Sys.setenv(SHINYSENDER_USER="alice")
```

(you may wish to add these lines to `~/.Rprofile`, or set the environment variables
in `~/.Renviron`, to avoid having to set them each time you start R)


* Set your working directory to your Shiny app's application directory (this will usually happen automatically when
you load the project)
* In Rstudio: Addins, Upload App from the main toolbar (this can be bound to a keyboard shortcut (Tools, Modify Keyboard Shortcuts).
* Or, if you're running outwith RStudio, run `shinysender::ss_uploadAddin()` from the console
* The app will be bundled and deployed on the remote server.  The first time you deploy any app, this will likely take some time
since the system needs to download and compile the same versions of the R libraries you're using as on your local system. Subsequent
deployments will use cached copies and so will be much quicker.
* You can deploy the app again to update it

You may get a warning about the version of R on the server being different to your
local version.  It is usually safe to ignore this.

# Advanced workflow

If you want to do anything more complex, the following code may help:

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
sets the cache location and turns Packrat on.  The staging `.Rprofile` also configure the UoM web proxy so we can download packages)

