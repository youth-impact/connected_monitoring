library('data.table')
library('glue')
library('googlesheets4')
library('rsurveycto')
library('yaml')

paramsDir = 'params'
params = read_yaml(file.path(paramsDir, 'params.yaml'))

########################################

if (Sys.getenv('SCTO_AUTH') == '') {
  auth_file = file.path(paramsDir, 'scto_auth.txt')
} else {
  auth_file = withr::local_tempfile()
  writeLines(Sys.getenv('SCTO_AUTH'), auth_file)
}

auth = scto_auth(auth_file)

########################################

if (is.null(gs4_user())) {
  if (Sys.getenv('GOOGLE_TOKEN') == '') {
    gs4_auth()
  } else {
    gs4_auth(path = Sys.getenv('GOOGLE_TOKEN'))
  }
}

########################################

get_duplicates = function(survey, file_url) {
  dups = survey[, if (.N > 1) .SD, by = id]
  dups[, sort_datetime := max(CompletionDate), by = id]
  setorder(dups, -sort_datetime, id, -CompletionDate)
  dups[, sort_datetime := NULL]
  dups[, dup_group := .GRP, by = id]
  dups[, dup_group := max(dup_group) - dup_group + 1L]

  dups_old = setDT(read_sheet(file_url, 'duplicates'))
  cols = c('keep', 'KEY')
  if (all(cols %in% colnames(dups_old))) {
    dups = merge(
      dups, dups_old[, ..cols], by = 'KEY', all.x = TRUE, sort = FALSE)
    dups[, keep := as.integer(keep)]
    dups[is.na(keep), keep := -1L]
    dups[, ok := sum(keep == 1L) == 1L, by = dup_group]
    dups[ok == TRUE & keep != 1L, keep := 0L]
    dups[ok == FALSE, keep := -1L]
    dups[, ok := NULL]
  } else {
    dups[, keep := -1L]
  }
  setcolorder(dups, c('keep', 'dup_group', 'KEY'))
  return(dups[])
}


get_monitor = function(survey, cases, by_cols) {
  monitor = merge(
    cases[, ..by_cols],
    unique(survey[, ..by_cols])[, submitted := 1L],
    by = by_cols, all.x = TRUE)
  monitor[is.na(submitted), submitted := 0L]
  return(monitor[])
}


get_summary = function(monitor, by_cols) {
  summary = monitor[, .(
    assigned_cases = .N, submitted_cases = sum(submitted)),
    keyby = by_cols]
  summary[, missing_cases := assigned_cases - submitted_cases]
  setorder(summary, -missing_cases)
  return(summary[])
}


get_missing = function(monitor, cases, by_cols) {
  missing = merge(monitor[submitted == 0, !'submitted'], cases, by = by_cols)
  return(missing)
}
