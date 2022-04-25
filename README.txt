# TEAM_03_INF550_HW_BIG_DATA

This is Team 03's submission of *Assignment 1: Analysis of Media and Semantic Forensics in Scientific Literature* from USC Viterbi's INF550: Data Science at Scale, Spring 2020 course. The contents of this project are listed below:

* **analysis**: directory with similarity scores, visualizations, and R code cluster analysis
* **data-modification**: directory with original Bik .tsv, and R code that joins in results from our other datasets and performs cleanup for analysis
* **rselenium-chrome**: directory for our web-scraping scripts
* **requirements.R**: an R script that installs all packages used to develop this project
* **TEAM_03_BIGDATA.pdf**: our final report
* **TEAM_03_UPDATED_DATSET.tsv**: our updated dataset
* **README.txt**: .txt version of this readme
* **README.md**: this file; readme for github

The rselenium-chrome folder has its own README as well, which details its configuration and contents (including test files to demonstrate the crawler).

Our project also involved modified files from Tika-Similarity, but we could not get those to appear in the github repository for this project (because Tika-Similarity has its own, most likely). The modifications are available in the pull request here:
https://github.com/chrismattmann/tika-similarity/pull/97

## Team Members

* **Cherry, Carlin** - ccherry@usc.edu - 8211265507
* **Lee, Matthew** - mdlee@usc.edu - 4356300240
* **May, David** - davidmay@usc.edu - 5801939142

For any inquires on code, please contact Matt at mdlee@usc.edu. Thank you!

## Software

* [R 3.6.2](https://www.r-project.org/)
* [RStudio](https://rstudio.com/products/rstudio/download/#download)
* [Rtools 3.5.0.4](https://cran.r-project.org/bin/windows/Rtools/) (if on Windows)
* [Docker Desktop](https://docs.docker.com/install/)
* [Python 2.7](https://www.python.org/downloads/)
* [Tika-Python](https://github.com/chrismattmann/tika-python)
* [Tika-Similarity](https://github.com/chrismattmann/tika-similarity)
* [D3](https://d3js.org/) (built-in to Tika-Similarity)

## R Packages

A list of all packaged installed into RStudio for the development of this project, and a brief description of what the package was for. The file `requirements.R` included in the main project directory contains code to install all the necessary packages. To install all packages from that file, open RStudio, change the working directory to the location of `requirements.R`, and run `source("requirements.R")`

* `tidyverse`: functions to manipulate datasets, plotting through ggplot2, pipe operator
* `lubridate`: for formatting dates
* `RSelenium`: bindings for running Selenium through R (and Docker)
* `getProxy`: for "free" proxies; experimental
* `keyring`: for password management [1]
* `jsonlite`: for reading and writing JSON
* `gtrendsR`: for querying from Google Trends API
* `naniar`: for missingness map plot
* `factoextra`: for principal component analysis plot
* `cluster`: for distance measures and clustering algorithms
* `Rtsne`: for t-SNE plots, used to visualize clusters
* `arsenal`: for summary tables of clusters
* `gridExtra`: for plotting

[1] requires some configuration, but we only used it for scraping LinkedIn with an alternate account; see `r-keyring-tutorial.R` in the rselenium-chrome/keyring folder.

## Glossary of Features

A list of features in our updated dataset. Features in the original dataset with no changes have the note "[no change]"; otherwise, there is a brief description of what we modified (if a modified original feature) or where the feature is from (if added from data blending).

A ^ before the name indicates a feature that we excluded from the final clustering results (i.e. not used to calculate the distance measure for determining clusters; we still examined these features in exploring the clusters). Some exclusions are for improving accuracy; others were due to time constraints and the need to push forward with the analysis.

* ^`authors`: [no change]
* ^`title`: [no change]
* ^`citation`: [no change]
* ^`doi`: [no change]
* `year`: [no change]
* ^`month`: extracted text from `citation`
* `simple_duplication`: renamed from `0`; replaced NA with 0
* `reposition_duplication`: renamed from `1`; replaced NA with 0
* `alteration_duplication`: renamed from `2`; replaced NA with 0
* `cuts_and_beautification`: renamed from `3`; replaced NA with 0
* `findings`: [no change]
* ^`reported`: replaced NA with 0
* `correction_date`: [no change]
* `retraction`: replaced NA with 0
* `correction`: replaced NA with 0
* `no_action`: replaced NA with 0
* ^`completed`: replaced NA with 0
* ^`first_author`: extracted text from `authors`
* `affiliation`: from Microsoft Academic; author's current associated organization
* `publications`: from Microsoft Academic; times author has published a paper
* `citations`: from Microsoft Academic; times any of author's papers have been cited
* `year_start`: from Microsoft Academic; year of first publication
* `year_end`: from Microsoft Academic; year of last publication
* `top_topics`: from Microsoft Academic; fields of study associated with given author
* `publication_types`: from Microsoft Academic; mediums of publication from given author
* `top_authors`: from Microsoft Academic; other authors associated with given author
* `top_journals`: from Microsoft Academic; journals given author has published in
* `top_institutions`: from Microsoft Academic; institutions associated with given author
* `top_conferences`: from Microsoft Academic; conferences given author has presented at
* `lab_size_approx`: count of distinct, non-NA values in `top_authors`
* `publication_variety`: count of distinct, non-NA values in `publication_types`
* `journal_variety`: count of distinct, non-NA values in `top_journals`
* `institution_variety`: count of distinct, non-NA values in `top_institutions`
* `conference_variety`: count of distinct, non-NA values in `top_conferences`
* `biology`: 1 if `top_topics` contains "biology"; 0 otherwise
* `medicine`: 1 if `top_topics` contains "medicine"; 0 otherwise
* `immunology`: 1 if `top_topics` contains "immunology"; 0 otherwise
* `cancer`: 1 if `top_topics` contains "cancer"; 0 otherwise
* `biochemistry`: 1 if `top_topics` contains "biochemistry"; 0 otherwise
* `virology`: 1 if `top_topics` contains "virology"; 0 otherwise
* `career_duration`: 2020 - `year_start`
* `publication_rate`: `publications` / `career_duration`
* `highest_degree`: from LinkedIn; degree title of first education record
* `degree_area`: from LinkedIn; field of study of first education record
* `degree_level`: `highest_degree` expressed as a number, with more weight on higher honors
* `total_cites`: from InCites; total citations of a given journal
* `impact_factor`: from InCites; a measure of journal prestige within its field
* `eigenfactor`: from InCites; importance of journal considering citations
* `web_interest`: from Google Trends; interest score for web searches
* `images_interest`: from Google Trends; interest score for image searches
* `youtube_interest`: from Google Trends; interest score for video searches
* ^`academic_reputation`: from USNews; score for university reputation
* ^`affiliation_funding`: from manual research; whether a university is public or private

## Other Material

Some of our analysis involve similarity/clustering techniques not mentioned in lecture (and accumulated gradually from years of reading stackexchange posts...). These resources help provide some context behind such terms.

* [Gower distance](https://stats.stackexchange.com/questions/15287/hierarchical-clustering-with-mixed-type-data-what-distance-similarity-to-use)
* [Silhouette criterion](https://stats.stackexchange.com/questions/320831/interpreting-silhouette-plot-for-cluster-analysis/320886)
* [Partitioning Around Medoids](https://en.wikipedia.org/wiki/K-medoids)
* [t-SNE plot](https://distill.pub/2016/misread-tsne/)
