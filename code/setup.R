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
  writeLines(Sys.getenv('SCTO_AUTH'), auth_file)}

auth = scto_auth(auth_file)

########################################

if (Sys.getenv('GOOGLE_TOKEN') == '') {
  gs4_auth()
} else {
  gs4_auth(path = Sys.getenv('GOOGLE_TOKEN'))}

########################################

get_duplicates = function(acct_survey) {
  acct_dups = acct_survey[, if (.N > 1) .SD, by = id]
  drop_empties(acct_dups)
  acct_dups[, duplicate_group := .GRP, by = id]
  setcolorder(acct_dups, 'duplicate_group')
  return(acct_dups[])}


get_monitor = function(acct_survey, cases, by_cols) {
  acct_monitor = merge(
    cases[, ..by_cols],
    unique(acct_survey[, ..by_cols])[, submitted := 1L],
    by = by_cols, all.x = TRUE)
  acct_monitor[is.na(submitted), submitted := 0L]
  return(acct_monitor[])}


get_summary = function(acct_monitor, by_cols) {
  acct_summary = acct_monitor[
    , .(assigned_cases = .N, submitted_cases = sum(submitted)),
    keyby = by_cols]
  acct_summary[, missing_cases := assigned_cases - submitted_cases]
  setorder(acct_summary, -missing_cases)
  return(acct_summary[])}


get_missing = function(acct_monitor, cases, by_cols) {
  acct_missing = merge(
    acct_monitor[submitted == 0, !'submitted'], cases, by = by_cols)
  return(acct_missing)}

