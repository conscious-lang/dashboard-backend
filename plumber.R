# plumber.R
library(plumber)
library(here)
library(stringr)


# Startup functions -------------------------------------------------------

clean_ag_output <- function(string) {
	match <- str_extract(string,':[0-9]*$')
	name  <- str_remove(string, match) %>% str_remove('^:')
	value <- str_remove(match,':') %>% as.integer()
	data.frame(File = name, Count = value)
}


# /search -----------------------------------------------------------------

#* Return the sum of two numbers
#* @param repo The repo to search
#* @param word The word to find
#* @get /search
#* @serializer csv
function(repo, word) {
	print(glue::glue('{repo} / {word}'))

	# change dir so we don't print the filepath
	setwd(here('clones',repo))

        # This is very ugly, but ag returns exit 1 on match-not-found
	suppressWarnings(
		system2('ag', c('--ackmate','-c', word, '.'), stdout = TRUE)
	) -> res

	if (length(res) == 0) {
		tibble::tibble(File='name',Count=0,.rows=0)
	} else {
		res %>%
			purrr::map_dfr(clean_ag_output) %>%
			dplyr::arrange(-Count)
	}
}
