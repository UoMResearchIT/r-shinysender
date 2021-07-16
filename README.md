# shinysender

<!-- badges: start -->

<!-- badges: end -->

The aim of this package is to provide tools and a Shiny app to allow users to send their Shiny apps to a remote Shiny Server.

## Usage

The package uses the config package to set the Shiny server address. A `config.yml` file is required, containing the server address and (optionally, but recommended) fingerprint:

```{r}
default:
  server: shiny.server.com
  serverfingerprint: 12:34:56:ab:cd:ef

```

Multiple servers can be specified in the `config.yml` file, and selected when making the connection.

### Basic usage

```{r}
# Connect to shiny server, as user Alice, using private key in ~/.ssh/id_rsh
session <- ss_connect("alice", "~/.ssh/id_rsh")

# List Alice's apps on Shiny server
ss_listapps(session)

# Delete Alice's app "demo" on the server
# TODO implement
ss_deleteapp(session, "demo")

# Upload app stored in ~/testapp to server as an app called demo
ss_uploadappdir(session, "~/testapp/", "demo")

# Disconnect from the server
ss_disconnect(session)
```

## Notes

Initially:

-   Will serve \~/ShinyApps only

-   Setup of users' accounts on remote Shiny server is out of scope

Handling package dependencies (i.e. each user ideally has their own packages) `renv` is designed to handle each project having its own libraries (and versions). So should get us most of hte way there.

Had an issue with broken symlinks in libraries within `./renv/`: `renv::rebuild()` seemed to fix this

<https://community.rstudio.com/t/shiny-server-renv/71879/3> suggests using `renv::isolate()` on the local machine (i.e. pre deployment)

Need to include renv::activate() at the top of the Shiny app, so it will see the renv packages when running

### Renv and Windows

Need to install Rtools on Windows (so R can build packages from source)

Renv will have installed win versions of packages.

On Shiny server, do `renv::restore()` on project to download/install Linux versions

TODO - test just renv::restore() without isolate - less to transfer over

### rsconnect deployment

Can we use rsconnect library to build the bundle, and then deploy at the other end? This deals with a lot of the dependency troubles...however, Packrat will install a full set for each app (rather than using system ones).

2021-07-16: Packrat has a Cache feature (<https://stackoverflow.com/questions/44676570/how-does-the-use-cache-feature-of-packrat-work>) which works by symlinking, so will hopefully avoid the space/time constraints of each app getting a full set of packages.

This approach looks like it should be feasible - have put a wrapper round rsconnect bundling code in `ss_bundleapp()` (probably shoudn't export this), and modified `ss_uploadappdir()` to upload the bundle (rather than individual files)

On the server end... we need to:

-   Repopulate the packrat local library (with `packrat::restore()`)

-   Make sure the app (when invoked by Shiny Server uses the packrat library

The second point is a bit tricky. TODO - try adding code to \~/.RProfile to check whether:

-   Set user level packrat cache location

-   We're running under shinyserver (how??)

-   If so check whether a (populated) packrat directory exists (i.e. one that's been `packrat::restore()`ed)

-   If so run `packrat::on()` to use packrat library

### Packrat Cache

The following in \~/.Rprofile sets up each user's Packrat cache:

    message("Setting up packrat cache")
    Sys.setenv(R_PACKRAT_CACHE_DIR = "~/R/packratcache")
    packrat::set_opts(use.cache=TRUE)

Will need to have the packrat library installed for all users, so they can run the final command (TODO - test if library is installed before running any of it)

Two approaches for doing this... use `/etc/skel` to set up on user creation, or provide a function to populate user's remote `.Rprofile` from `shinysender` package. The latter approach is probably better.
