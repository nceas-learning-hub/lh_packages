### Run this to update the lesson catalog (lesson_catalog.qmd):
### * installs the latest lhLessons package from GitHub (uncomment the line below)
### * for each lesson in lhLessons, writes a stub qmd into lh_packages/lessons that
###   contains only the title, categories (tags) and description from the lesson's
###   YAML header, plus the learning objectives callout and the overview/summary text
###   (whichever are present; if neither, a one-line note that it is part of lhLessons).
###   Since there is no code or other content, the site renders without R or auxiliary files
### * records the lhLessons version in _catalog_version.md, which lesson_catalog.qmd
###   includes at the top of the page
### Then re-render the site, and commit the changes in lessons/ and _catalog_version.md.

# remotes::install_github('nceas-learning-hub/lhLessons')

lesson_fs <- list.files(system.file('lessons', package = 'lhLessons'),
                        pattern = '[.]qmd$', full.names = TRUE)
catalog_keys <- c('title', 'categories', 'description')

### Remove all old lessons and anything else in the lessons folder
unlink(list.files(here::here('lessons'), full.names = TRUE), recursive = TRUE)
dir.create(here::here('lessons'), showWarnings = FALSE)

### Write a stub for each lesson: catalog fields of its YAML header, plus the
### learning objectives callout and the overview/summary text (whichever are present).
### If the lesson has neither, the stub gets a one-line default note instead.
default_note <- 'This lesson is part of the lhLessons package.'

### Does a line open a block that we don't want in the overview text?
### (divs, images, code, html, tables, headings)
is_non_prose <- function(x) {
  any(startsWith(x, c(':::', '![', '<', '```', '|', '#')))
}

for (f in lesson_fs) {
  lines <- readLines(f, warn = FALSE)
  yaml_marks <- which(lines == '---')
  header <- lines[(yaml_marks[1] + 1):(yaml_marks[2] - 1)]
  keep <- header[grepl(sprintf('^(%s):', paste(catalog_keys, collapse = '|')), header)]
  if (length(keep) != length(catalog_keys)) {
    warning('Missing title/categories/description in header of ', basename(f))
  }

  ### Learning objectives callout (a ::: div, possibly with nested divs)
  objectives <- NULL
  lo_start <- grep('^:+ *[{][.]callout-learning', lines)[1]
  if (!is.na(lo_start)) {
    depth <- 0
    for (i in lo_start:length(lines)) {
      if (grepl('^:{3,}[[:space:]]*[^[:space:]]', lines[i])) depth <- depth + 1
      else if (grepl('^:{3,}[[:space:]]*$', lines[i])) depth <- depth - 1
      if (depth == 0) break
    }
    objectives <- lines[lo_start:i]
  }

  ### Overview or summary: a level-2 heading named Overview or Summary (ignoring
  ### headings inside code chunks); keep only the leading prose and lists, stopping
  ### at the first div, image, code, html, table or heading, since the files those
  ### need are not copied and divs may be unbalanced once cut out of the lesson
  overview <- NULL
  in_code <- cumsum(grepl('^```', lines)) %% 2 == 1
  ov_pattern <- '^##[[:space:]]+(Overview|Summary)[[:space:]]*([{][^}]*[}])?[[:space:]]*$'
  ov_start <- which(!in_code & grepl(ov_pattern, lines, ignore.case = TRUE))[1]
  if (!is.na(ov_start)) {
    ov_end <- ov_start
    for (i in (ov_start + 1):length(lines)) {
      if (is_non_prose(lines[i])) break
      ov_end <- i
    }
    overview <- lines[ov_start:ov_end]
    ### trim trailing blank lines; skip if nothing but the heading is left
    while (length(overview) > 1 && !nzchar(trimws(overview[length(overview)]))) {
      overview <- overview[-length(overview)]
    }
    if (length(overview) < 2) overview <- NULL
  }

  body <- c(objectives, if (!is.null(objectives) && !is.null(overview)) '', overview)
  if (length(body) == 0) body <- default_note
  writeLines(c('---', keep, '---', '', body), here::here('lessons', basename(f)))
}

### Record the lhLessons version (and update date) for the top of lesson_catalog.qmd
lh_version <- as.character(utils::packageVersion('lhLessons'))
update_date <- format(Sys.time(), '%Y-%m-%d', tz = 'America/Los_Angeles')
writeLines(
  sprintf('**Catalog version:** `{lhLessons}` version %s (catalog updated %s)',
          lh_version, update_date),
  here::here('_catalog_version.md')
)
