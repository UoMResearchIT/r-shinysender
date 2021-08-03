# shinysender

<!-- badges: start -->

<!-- badges: end -->

The aim of this package is to provide tools and a Shiny app to allow users to send their Shiny apps to a remote Shiny Server.

## Usage

The server you wish to send the apps to can be specified using the `server=` parameter of `ss_connect()`, or by setting the `SHINYSENDER_SERVER` environment variable, e.g. in `~/.Renviron`.

You will need to have a user account on the remote server already set up. If this is set up to use ssh keys then these will be used. Otherwise you will be prompted for the account password.

### Basic workflow

```{r}
# Connect to shiny server, using the same login name as the local account and the server
# set in the SHINYSENDER_SERVER environment variable
# User will be prompted for password if not using ssh keys
session <- ss_connect()

# Set up the user's account on the server to use Packrat packages
# (This only needs to be done once)
ss_setupserver(session)

# List apps on Shiny server
ss_listapps(session)

# Upload app stored in ~/testapp to server as an app called demo
# This will automatically set up the package environment to match the user's local computer
ss_uploadappdir(session, "~/testapp/", "demo")

# Delete app "demo" on the server
ss_deleteapp(session, "demo")

# Disconnect from the server
ss_disconnect(session)
```

### Setting up the remote Server

(these notes are currently incomplete)

-   Tested using Ubuntu 21.04
-   Check homedir permissions - should be set correctly on 21.04, but not on earlier versions. Don't want to be able to see others' home dir.
-   Dependencies for Tidyverse: `sudo apt install libcurl4-openssl-dev libssl-dev libxml2-dev` (from <https://blog.zenggyu.com/en/post/2018-01-29/installing-r-r-packages-e-g-tidyverse-and-rstudio-on-ubuntu-linux/>)
-   Install Packrat as root from CRAN
