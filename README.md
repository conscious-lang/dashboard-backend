# Conscious Language Dashboard - backend

This repo contains the necessary tools to generate the dataset(s) used by the
dashboard frontend, as well as the API that the dashboard will use to access
them

# Installation

Short version: There is an Ansible playbook for the necessary dependencies, run
that first

```
ansible-playbook playbook.yml
```

(This was written for a Debian host, but essentially it installs some
dependencies, and sets up LighTTPD to run the API)

# R dependencies

In the root of the project, use [Renv](https://rstudio.github.io/renv) to get the deps:

```
Rscript -e 'renv::restore()'
```

# Input Data

As written, the tool currently downloads a spreadsheet from Google Drive as its
"source of truth" - but this is not public.

If you want to replicate, you'll want a CSV file or similar with:

* Git repositories in column 4 (D)
* GitHub Organisations in column 5 (E)
  * These will be expanded out in the script
* Repos to exclude in column 6 (F)
  * These are then removed from the expansion in column 5

You'll need to mess with `01_get_repos.R` to change how it loads.

# Output

The scripts cache ([pin](https://rstudio.github.io/pins)) the output to
directories in /tmp. This is not robust, but this is mostly fine, as the data
is just the result of running `ag` on Git repositories, and can always be
recreated.

The historical data (i.e. the results of previous runs) is much harder to
recreate - currently this file is backed up to Google Drive at the end of each
run (see `04_store.R`). This could probably be improved as a process, but works
as an insurance policy for now.

# API

The project uses [PlumbeR](https://www.rplumber.io) to serve an API for the
dashboard to hit, as well as serving the data pins directly via LighTTPD. To
run the Plumber API, add the [[conscious_language_api.service]] file to
Systemd.

# Contributing

Help is very welcome at all levels - please do open Issues or Pull Requests as
required, even for minor things!
