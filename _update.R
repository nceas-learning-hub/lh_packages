### Run this to update the lesson catalog (lesson_catalog.qmd):
### * installs the latest lhLessons package from GitHub (uncomment the line below)
### * copies over all lesson qmds from lhLessons into lh_packages/lessons
### * copies the resource folders into lh_packages/lessons/resources
###   (some lessons need a .bib to render, even with execute: enabled: false)
### * keeps lessons/_metadata.yml, which turns off code execution for the lessons
### * records the lhLessons version in _catalog_version.md, which lesson_catalog.qmd
###   includes at the top of the page
### Then re-render the site, and commit the changes in lessons/.

# remotes::install_github('nceas-learning-hub/lhLessons')

lesson_fs <- list.files(system.file('lessons', package = 'lhLessons'), full.names = TRUE)
resource_fs <- list.files(system.file('lesson_resources', package = 'lhLessons'), full.names = TRUE)

### Remove all old lessons (but keep _metadata.yml)
old_fs <- list.files(here::here('lessons'), full.names = TRUE)
unlink(old_fs[basename(old_fs) != '_metadata.yml'], recursive = TRUE)

### Copy lessons and resource folders
file.copy(lesson_fs, here::here('lessons/'))
dir.create(here::here('lessons/resources'))
file.copy(resource_fs, here::here('lessons/resources/'), recursive = TRUE)

### Record the lhLessons version (and update date) for the top of lesson_catalog.qmd
lh_version <- as.character(utils::packageVersion('lhLessons'))
update_date <- format(Sys.time(), '%Y-%m-%d', tz = 'America/Los_Angeles')
writeLines(
  sprintf('**Catalog version:** `{lhLessons}` version %s (catalog updated %s)',
          lh_version, update_date),
  here::here('_catalog_version.md')
)
