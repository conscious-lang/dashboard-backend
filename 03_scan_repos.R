# Cron script to clone the necessary git repos

library(pins)
library(tidyverse)
library(here)
library(furrr)
plan(multiprocess, workers=2)

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

count_words <- function(org, repo, word) {
  # Search path for this repo
  path = here('clones',org,repo)

  # This is very ugly, but ag returns exit 1 on match-not-found
  suppressWarnings(
    system2('ag',c('-c', word, path), stdout = TRUE, stderr = FALSE)
  ) -> res

  # Ag2 vs Ag1
  if (length(res) > 0 && str_detect(res[1],':')) {
    #AG1 returns paths too
    res %>%
      str_extract(':[0-9]*$') %>%
      str_remove(':') -> res
  }

  res %>%
    as.integer() %>%
    sum() %>%
    return()
}

# Count words in clone
projects %>%
  mutate(blacklist = future_map2_int(org, repo, count_words, 'blacklist', .progress = TRUE),
         whitelist = future_map2_int(org, repo, count_words, 'whitelist', .progress = TRUE),
         master    = future_map2_int(org, repo, count_words, 'master',    .progress = TRUE),
         slave     = future_map2_int(org, repo, count_words, 'slave',     .progress = TRUE)
  ) -> projects

projects <- projects %>% filter(blacklist + whitelist + master + slave > 0)

pin(projects,name='cl_results', board = 'conscious_lang')
