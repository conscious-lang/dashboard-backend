# Cron script to get the list of repos from
# conscious-lang's GDrive doc

library(pins)
library(googledrive)
library(tidyverse)

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

projects[,4] %>%
  rename(repo = 1) %>%
  separate_rows(repo,sep=',') %>%
  mutate(repo = str_trim(repo),
         repo = str_remove(repo,'/$')) -> projects

pins::board_register_local(name = 'conscious_lang', cache = '/tmp')
pin(projects,name='cl_projects', board = 'conscious_lang')
