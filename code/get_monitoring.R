library('data.table')
library('glue')
library('rsurveycto')

paramsDir = 'params'
dataDir = 'data'
outputDir = 'output'

if (interactive()) {
  week_now = 5
} else {
  cArgs = commandArgs(TRUE)
  if (!(cArgs[1L] %in% as.character(1:6))) stop('Invalid week.')
  week_now = as.integer(cArgs[1L])}

if (!dir.exists(outputDir)) dir.create(outputDir)

########################################

group_now = if (week_now %in% c(1, 3, 5)) 1 else 2
auth = scto_auth(file.path(paramsDir, 'scto_auth.txt'))

########################################

assignments = fread(file.path(outputDir, 'acct_call_assignments.csv'))
assignments[, current_phone_num_best := as.character(current_phone_num_best)]
assignments = assignments[biweekly_group == group_now]

########################################

# TODO: convert numeric values to meanings based on
# import_tarl_accountability_survey_r7.do

acct_survey = scto_pull(
  auth, 'tarl_accountability_survey_r7', 'form', #refresh = TRUE,
  cache_dir = dataDir)

acct_survey = acct_survey[week == week_now]

########################################

acct_dups = acct_survey[, if (.N > 1) .SD, by = id]

fwrite(
  acct_dups,
  file.path(outputDir, glue('week{week_now}_acct_duplicates.csv')))

########################################

by_cols = c('facilitator_name', 'facilitator_id', 'id')

acct_monitor = merge(
  assignments[, ..by_cols],
  unique(acct_survey[, ..by_cols])[, submitted := 1L],
  by = by_cols, all.x = TRUE)

acct_monitor[is.na(submitted), submitted := 0L]

acct_monitor_summary = acct_monitor[
  , .(assigned_cases = .N, submitted_cases = sum(submitted)),
  keyby = eval(by_cols[1:2])]

acct_monitor_summary[, missing_cases := assigned_cases - submitted_cases]
setorder(acct_monitor_summary, -missing_cases)

fwrite(
  acct_monitor_summary,
  file.path(outputDir, glue('week{week_now}_acct_summary.csv')))

########################################

acct_monitor_missing = merge(
  acct_monitor[submitted == 0, !'submitted'],
  assignments[, !'biweekly_group'], by = by_cols)

fwrite(
  acct_monitor_missing,
  file.path(outputDir, glue('week{week_now}_acct_missing.csv')))
