# Cron script to clone the necessary git repos

library(pins)
library(tidyverse)
library(git2r)
library(here)
library(furrr)

setwd(here())

pins::board_register_local(name = 'conscious_lang', cache = '/tmp')

repos <- pin_get('cl_projects', board = 'conscious_lang') %>%
  # split up the path so we can use it for things
  mutate(url   = repo,
         path  = str_split(url,'/'),
         parts = map_int(path, ~{ .x %>%
                                    unlist() %>%
                                    length() })
  ) %>%
  mutate(org  = map2_chr(path, parts, ~{ unlist(.x) %>%
                                         head(.y) %>%
                                         tail(2) %>%
                                         head(1) }),
         repo = map_chr(path, ~{ unlist(.x) %>%
                                   tail(1) })
  ) %>%
  filter(!is.na(org)) %>%
  filter(!(org == '')) %>%
  select(url, org, repo)

# We need to avoid conflicts when updating git repos *and* remove dirs no
# longer listed in the spreadsheet. While we *could* do this with "git reset"
# and "git clean" and then store every cloned dir and delete others, it's
# altogether easier to delete "clones" and start again. 20Gb of bandwidth a week
# is not so bad.

# Clean the holding area
if (dir.exists(here('clones'))) { unlink(here('clones'), recursive = T) }

# Create necessary dirs
dir.create(here('clones'))
for (dir in unique(repos$org)) {
  if (!dir.exists(here('clones',dir))) { dir.create(here('clones',dir))}
}

# Clone the repos
clone_to_path <- function(url, path) {
  # Can't depth-1 clone with git2r
  system2('git', c('clone', '--depth', '1', '--quiet', url, path))
}
# Do it nicely, don't break the loop
safe_clone = possibly(clone_to_path, otherwise = NA)

# Clone repos, parallel
plan(multiprocess, workers=4)
repos <- repos %>%
  mutate(pull = future_map2(url,
                     str_c('clones',org,repo,sep='/'),
                     safe_clone,
                     .progress = TRUE))

# Note the failures
repos %>%
  filter(is.na(pull)) %>%
  mutate(pull = dir.exists(here('clones',org,repo))) %>%
  select(url, pull) -> failures

pin(failures,name='cl_fails', board = 'conscious_lang')
pin(repos,name='cl_results', board = 'conscious_lang')
