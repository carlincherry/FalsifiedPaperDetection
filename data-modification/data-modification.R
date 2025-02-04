# data-modification.R -----------------------------------------------------
# Our data cleaning and blending. Loads datasets from Bik et. al. and the 
# results of our scraping/research. Modifies some variables and joins in the 
# auxiliary datasets.
# 
# Needs the following files in the working directory:
# - bik-dataset-original.tsv
# - microsoft-academic-results.csv
# - linkedin-results.csv
# - journal_impact_factors.csv
# - google-trends-results.csv
# - usnews-results.csv
# 
# Outputs the following:
# - TEAM_03_UPDATED_DATASET.tsv
# - bik-modified.csv
# - bik-modified.json
#
# If there are questions/comments, please contact Matt (mdlee@usc.edu).
# -------------------------------------------------------------------------

# Loading required packages
library("tidyverse")
library("jsonlite")

# Loading original Bik dataset
bik_original <- read.delim("bik-dataset-original.tsv", 
                           encoding = "UTF-8-BOM",
                           stringsAsFactors = FALSE, 
                           check.names = FALSE)

# Loading results from Microsoft Academic
microsoft_academic <- read.csv("microsoft-academic-results.csv", 
                               na.strings = c(NA, ""),
                               stringsAsFactors = FALSE)

# Loading results from LinkedIn
linkedin <- read.csv("linkedin-results.csv",
                     na.strings = c(NA, ""),
                     stringsAsFactors = FALSE)

#Loading Impact Factor scores
impact_factor <- read.csv("journal_impact_factors.csv",
                          fileEncoding = "UTF-8-BOM",
                          na.strings = c(NA,""),
                          stringsAsFactors = FALSE)

# Loading results from Google Trends
google_trends <- read.csv("google-trends-results.csv",
                          na.strings = c(NA, ""),
                          stringsAsFactors = FALSE)

industry_funding <- read.csv("usnews-results.csv",
                             na.strings = c(NA,""),
                             stringsAsFactors = FALSE)

# Diagnostics
summary(bik_original)
lapply(bik_original, class)
# View(bik_original)
# - row count seems off
# - names could use fixing
# - feature month has errors
# - feature `3` has errors

# Standardizing column names to be more programming friendly
# - all lowercase
# - underscore for spaces
new_col_names <- names(bik_original) %>%
  tolower %>%
  gsub("(\\.)|(\\s)", "\\_", .)

# Modifying bik dataset
bik <- bik_original %>%
  # Assign new names
  `colnames<-`(new_col_names) %>%
  rename(completed = "sum__completed",
         simple_duplication = `0`,
         reposition_duplication = `1`,
         alteration_duplication = `2`,
         cuts_and_beautification = `3`) %>%
  # Remove blank rows
  filter(authors != "") %>%
  # Fixing encoding (Windows issue?)
  mutate_if(is.character, enc2utf8) %>%
  # Modifying features that should be boolean but have erroneous string entries
  mutate_at(vars(cuts_and_beautification, reported),
            function(x) {
              if_else(x != "", 1, as.numeric(NA))
            }) %>%
  # Modifying booleans to use 0 instead of NA (for preference)
  mutate_at(vars(simple_duplication, reposition_duplication, alteration_duplication,
                 cuts_and_beautification, reported, retraction, correction, no_action,
                 completed),
            function(x) {
              if_else(is.na(x), 0, 1)
            }) %>%
  # Modifying month: extract from citation using first letters of the month as pattern
  mutate(month = str_extract(citation, "((Jan)|(Feb)|(Mar)|(Apr)|(May)|(Jun)|(Jul)|(Aug)|(Sep)|(Oct)|(Nov)|(Dec)){1}[a-z]*")) %>%
  # Modifying correction_date to be a proper date
  mutate(correction_date = as.Date(correction_date, "%m/%d/%Y")) %>%
  # Joining in Microsoft Academic results
  # - rows are aligned exactly by author/paper, so can simply put columns together
  # - dropping not_found, since this is blank (results were found for each row)
  cbind(select(microsoft_academic, -not_found)) %>%
  mutate(
    lab_size_approx = top_authors %>%
      str_split(pattern = "\\|") %>%
      lapply(na.exclude) %>%
      lapply(length) %>%
      unlist,
    publication_variety = publication_types %>%
      str_split(pattern = "\\|") %>%
      lapply(na.exclude) %>%
      lapply(length) %>%
      unlist,
    journal_variety = top_journals %>%
      str_split(pattern = "\\|") %>%
      lapply(na.exclude) %>%
      lapply(length) %>%
      unlist,
    institution_variety = top_institutions %>%
      str_split(pattern = "\\|") %>%
      lapply(na.exclude) %>%
      lapply(length) %>%
      unlist,
    conference_variety = top_conferences %>%
      str_split(pattern = "\\|") %>%
      lapply(na.exclude) %>%
      lapply(length) %>%
      unlist,
    biology = grepl("(biology)", tolower(top_topics)),
    medicine = grepl("(medicine)", tolower(top_topics)),
    immunology = grepl("(immunology)", tolower(top_topics)),
    cancer = grepl("(cancer)", tolower(top_topics)),
    biochemistry = grepl("(biochemistry)", tolower(top_topics)),
    virology = grepl("(virology)", tolower(top_topics)),
    career_duration = 2020 - year_start,
    publication_rate = publications / career_duration
  ) %>%
  # Joining in LinkedIn results
  left_join(select(linkedin, first_author, title, highest_degree, degree_area),
            by = c("first_author", "title")) %>%
  # Cleaning highest_degree with regular expressions.
  # Also adding a numeric equivalent -- this puts more weight on higher degrees
  # And puts "unknown" at the average of the known scores.
  # - NA: 4 (the average of non-null entries)
  # - "something": 1
  # - Associate: 3 (+2 years from "something")
  # - Bachelor: 5 (+4 years from "something")
  # - Master: 7 (+2 years from "bachelor")
  # - PhD: 10 (+5 years from "bachelor")
  # If NA/missing, then assigned a value of 4, the mean of the non-NA entries
  mutate(
    highest_degree = factor(
      case_when(
        grepl("(Doctor)|(P.?h.?D)", highest_degree) ~ "PhD",
        grepl("(Master)|(M.?S.?)", highest_degree) ~ "Master",
        grepl("(Bachelor)|(B.?A.?)|(B.?S.?)", highest_degree) ~ "Bachelor",
        grepl("(Associate)|(Certificate)", highest_degree) ~ "Associate",
        !is.na(highest_degree) ~ "Other",
        TRUE ~ as.character(NA)
      ),
      ordered = TRUE
    ),
    degree_level = case_when(
      highest_degree == "PhD" ~ 10,
      highest_degree == "Master" ~ 7,
      highest_degree == "Bachelor" ~ 5,
      highest_degree == "Associate" ~ 3,
      highest_degree == "Other" ~ 1,
      is.na(highest_degree) ~ 4
    )
  ) %>%
  # Joining in Impact Factor results 
  cbind(select(impact_factor, -citation, -year)) %>%
  # Joining in Google Trends results
  left_join(google_trends, by = c("first_author", "title")) %>%
  # Joining in Industry Funding results
  cbind(select(industry_funding, -affiliation))

bik_json <- bik %>%
  select(-authors, -title, -citation, -doi, -reported, -completed, -first_author) %>%
  mutate_if(is.character, function(x) {
    iconv(x, from = "UTF-8", to = "ASCII//TRANSLIT", sub = "")
  }) %>%
  mutate(id = as.character(0:(nrow(.) - 1)))

write_tsv(bik, "TEAM_03_UPDATED_DATSET.tsv")
write.csv(bik, "bik-modified.csv", row.names = FALSE)
write_json(bik_json, "bik-modified.json")
