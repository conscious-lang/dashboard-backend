#!/bin/bash

Rscript ./01_get_repos.R
Rscript ./02_clone_repos.R
Rscript ./03_scan_repos.R
Rscript ./04_store.R
