# Cron script to get the list of repos from
# conscious-lang's GDrive doc

library(pins)
library(googledrive)
library(tidyverse)
source('lib.R')

# Register to GDrive
options(
  gargle_oauth_cache = ".secrets",
  gargle_oauth_email = TRUE
)
drive_auth(email = TRUE)

# Get the app config
id <- as_id("1NpC0pTB9nH-Rx6T60VrRH3XIWR-xhIY06e5IOiKNPQE")
drive_download(id, path = 'app_config.xlsx', overwrite = T)

projects <- readxl::read_xlsx('./app_config.xlsx',sheet = 'Upstream Projects')

# Unwrap the org values
orgs <- unlist_column(projects,5) %>%
  rename(url = 1) -> orgs

safe_fetch <- purrr::possibly(fetch_repos_from_org, NA)
orgs %>%
  mutate(list = map(url, safe_fetch)) %>%
  na.omit() %>%
  unnest(cols=c(list)) %>%
  select(repo) -> org_repos

single_repos <- unlist_column(projects,4) %>%
  rename(repo = 1)

exclusions <- unlist_column(projects,6) %>% pull(1)

repos <- bind_rows(org_repos, single_repos) %>%
  na.omit() %>%
  distinct(repo) %>%
  filter(repo %nin% exclusions)

pins::board_register_local(name = 'conscious_lang', cache = '/tmp')
pin(repos,name='cl_projects', board = 'conscious_lang')
