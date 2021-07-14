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
