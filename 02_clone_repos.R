# Cron script to clone the necessary git repos

library(pins)
library(tidyverse)
library(git2r)
library(here)

setwd(here())

pins::board_register_local(name = 'conscious_lang', cache = '/tmp')

projects <- pin_get('cl_projects', board = 'conscious_lang') %>%
  # temporary, github only, other styles to come
  filter(str_detect(repo,'github.com')) %>%
  # split up the path so we can use it for things
  mutate(url   = repo,
         path  = str_split(url,'/'),
         parts = map_int(path, ~{ .x %>%
                                    unlist() %>%
                                    length() })
  ) %>%
  filter(parts == 5) %>% # habndle orgs (4 parts) later
  mutate(org  = map_chr(path, ~{ unlist(.x) %>%
                                   tail(2) %>%
                                   head(1) }),
         repo = map_chr(path, ~{ unlist(.x) %>%
                                   tail(1) })
  ) %>%
  select(url, org, repo)

# Holding area
if (!dir.exists(here('clones'))) { dir.create(here('clones'))}

# Create any necessary org dirs
for (dir in unique(projects$org)) {
  if (!dir.exists(here('clones',dir))) { dir.create(here('clones',dir))}
}

# Wrapper to clone or pull depending on the repo presence
pull_or_clone <- function(url, path) {
  if (dir.exists(path)) {
	  #TODO makde this a fetch/reset process to avoid conflicts
    branch <- git2r::repository_head(path)$name
    target <- glue::glue('origin/{branch}')
    # Can't depth-1 fetch with git2r
    setwd(here::here(path))
    system2('git', c('fetch', '--no-tags', '--prune', '--depth', '1', '--quiet'))
    system2('git', c('reset', '--hard', target))
    system2('git', c('clean', '--force', '-d'))
    setwd(here::here())
  } else {
    # Can't depth-1 clone with git2r
    system2('git', c('clone', '--depth', '1', '--quiet', url, path))
  }
}
# Do it nicely, don't break the loop
safe_pull_or_clone = possibly(pull_or_clone, otherwise = NA)

# Clone repos
library(furrr)
plan(multiprocess, workers=4)
projects <- projects %>%
  mutate(pull = future_map2(url,
                     str_c('clones',org,repo,sep='/'),
                     safe_pull_or_clone,
                     .progress = TRUE))

# Note the failures
projects %>%
  filter(is.na(pull)) %>%
  mutate(pull = dir.exists(here('clones',org,repo))) %>%
  select(url, pull) -> failures

pin(failures,name='cl_fails', board = 'conscious_lang')
pin(projects,name='cl_results', board = 'conscious_lang')
