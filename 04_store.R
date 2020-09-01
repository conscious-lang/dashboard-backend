library(tidyverse)
library(glue)
library(here)
library(googledrive)

pins::board_register_local(name = 'conscious_lang', cache = '/tmp')

d <- pins::pin_get('cl_results',board='conscious_lang')
h <- pins::pin_get('cl_hist',board='conscious_lang')

d %>%
	mutate(date = Sys.Date()) %>%
	relocate(date,.before = url) %>%
	bind_rows(h) -> h1

h1 %>% pins::pin('cl_hist',board='conscious_lang')

# Push h1 to GDrive as a backup

# Register to GDrive
options(
  gargle_oauth_cache = ".secrets",
  gargle_oauth_email = TRUE
)
drive_auth(email = TRUE)

# Get the backup dir for this env (or create)
backup_dir <- drive_get(glue("DataBackups/ConsciousLanguage"))
if (nrow(backup_dir) == 0) backup_dir <- drive_mkdir(glue("DataBackups/ConsciousLanguage"))

tmpfile <- tempfile()
on.exit(unlink(tmpfile))
h1 %>% write.csv(tmpfile)

drive_put(media = tmpfile, type = 'spreadsheet',
          path = 'DataBackups/ConsciousLanguage', name = 'historical_data.csv')
