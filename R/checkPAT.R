get_pat_expiry <- function(pat = Sys.getenv("GITHUB_PAT")) {
  # Can test PAT without passing a username
  r <- httr::GET(
    "https://api.github.com/user",
    config = httr::authenticate(user = "", password = pat)
  )

  if (r$status_code == 200) {
    expiresat <- as.POSIXct(
      httr::headers(r)$`github-authentication-token-expiration`
    )
  } else {
    return(NA)
  }

  return(expiresat)
}

#' Check if the Github PAT is going to expire soon
#'
#' Displays a warning if so
#'
#' Gets the PAT from GITHUB_PAT by default
#'
#' @param pat The Personal Access Token
#' @param minweeks Warn if fewer than minweeks weeks left until expiry
#'
check_pat_expiry <- function(pat = Sys.getenv("GITHUB_PAT"), minweeks = 2) {
  if (requireNamespace("httr", quietly = TRUE)) {
    expiresat <- get_pat_expiry(pat = pat)

    if ("POSIXct" %in% class(expiresat)) {
      weeksleft <- difftime(expiresat, Sys.time(), units = "weeks")
      if (weeksleft < 0) {
        stop("Github PAT has expired")
      } else if (weeksleft < minweeks) {
        daysleft <- floor(difftime(expiresat, Sys.time(), units = "days"))
        warning("Github PAT expires in ", daysleft, " days.")
      }
    } else {
      warning("Could not get token expiry date")
    }
  } else {
    message("Install httr package to test if Github PAT expires soon")
  }
}
