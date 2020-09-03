# function library for repo string manipulation

`%nin%` <- Negate(`%in%`)

# unlist_column -----------------------------------------------------------
# get a column from the project spreadsheet, unlist the CSV values, trim

unlist_column <- function(d,col) {
  tmp <- d[,col]
  name <- names(tmp)[1]
  tmp %>%
    rename(c = 1) %>%
    separate_rows(c,sep=',') %>%
    mutate(c = str_trim(c),
           c = str_remove(c,'/$')) -> tmp
  names(tmp) <- name
  na.omit(tmp)
}

# fetch_repos_from_org ----------------------------------------------------
# Queries the GH API for repo lists, recursively
fetch_repos_from_org <- function(url) {
  org <- get_org_from_url(url)

  if (is.na(org))
    return(NA)

  # github api only returns 100
  orgs <- gh::gh('/orgs/:orgname/repos', orgname = org, .limit = 100)
  next_page <- TRUE # recurse until we have them all
  while (next_page) {
    status <- tryCatch(next_orgs <- gh::gh_next(orgs), error = identity)
    if (inherits(status, "error")) {
      next_page <- FALSE
      next
    }
    orgs <- c(orgs,next_orgs)
  }
  tibble(repo     = map_chr(orgs,'html_url'),
         fork     = map_lgl(orgs,'fork'),
         archived = map_lgl(orgs,'archived')) %>%
    filter(fork == FALSE & archived == FALSE) %>%
    select(repo)
}

# get_org_from_url --------------------------------------------------------
# works on a single string, not vectorised
# extracts "foo" from "https://github.com/foo"
get_org_from_url <- function(url) {
  if (!str_detect(url,'github.com'))
    return(NA)

  parts <- str_split(url, '/')[[1]]

  if (length(parts) != 4)
    return(NA)

  return(parts[4])
}
