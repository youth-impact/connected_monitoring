library('data.table')
library('glue')
library('googlesheets4')
library('rsurveycto')
library('yaml')

paramsDir = 'params'
# dataDir = 'data'
outputDir = 'output'

if (!dir.exists(outputDir)) dir.create(outputDir)

params = read_yaml(file.path(paramsDir, 'params.yaml'))
# groups = fread(file.path(paramsDir, 'biweekly_groups.csv'))

########################################

# if (interactive()) {
#   week_now = 0
# } else {
#   cArgs = commandArgs(TRUE)
#   if (!(cArgs[1L] %in% as.character(0:6))) stop('Invalid week.')
#   week_now = as.integer(cArgs[1L])}

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

cases = scto_read(auth, 'cases')
setnames(cases, c('facilitator', 'f_id'), c('facilitator_name', 'facilitator_id'))
# cases[, current_phone_num_best := as.character(current_phone_num_best)]

# assignments = fread(file.path(outputDir, 'call_assignments.csv'))
# assignments[, current_phone_num_best := as.character(current_phone_num_best)]

########################################

# TODO: convert numeric values to meanings based on
# import_tarl_accountability_survey_r7.do

acct_survey = scto_read(auth, params$dataset_id, 'form')
# acct_survey[, week := as.integer(week)]

acct_survey[, comp_date := as.IDate(CompletionDate, format = '%b %e, %Y %I:%M:%S %p')]
acct_survey[, week := temp_week_name]

week_now = acct_survey[comp_date == max(comp_date)]$week[1L]
acct_survey = acct_survey[week == week_now]

########################################

# if (week_now == 0) week_now = max(acct_survey$week)
# group_now = groups[week == week_now]$biweekly_group

# assignments = assignments[biweekly_group == group_now]
# acct_survey = acct_survey[week == week_now]

########################################

acct_dups = acct_survey[, if (.N > 1) .SD, by = id]
drop_empties(acct_dups)
acct_dups[, duplicate_group := .GRP, by = id]
setcolorder(acct_dups, 'duplicate_group')

write_sheet(acct_dups, params$googlesheet_id, 'duplicates')
range_autofit(params$googlesheet_id, 'duplicates')
fwrite(acct_dups, file.path(outputDir, 'duplicates.csv'))

########################################

by_cols = c('facilitator_name', 'facilitator_id', 'id')

acct_monitor = merge(
  # assignments[, ..by_cols],
  cases[, ..by_cols],
  unique(acct_survey[, ..by_cols])[, submitted := 1L],
  by = by_cols, all.x = TRUE)

acct_monitor[is.na(submitted), submitted := 0L]

acct_summary = acct_monitor[
  , .(assigned_cases = .N, submitted_cases = sum(submitted)),
  keyby = eval(by_cols[1:2])]

acct_summary[, missing_cases := assigned_cases - submitted_cases]
setorder(acct_summary, -missing_cases)

write_sheet(acct_summary, params$googlesheet_id, 'summary')
range_autofit(params$googlesheet_id, 'summary')
fwrite(acct_summary, file.path(outputDir, 'summary.csv'))

########################################

acct_missing = merge(
  acct_monitor[submitted == 0, !'submitted'], cases, by = by_cols)
  # assignments[, !'biweekly_group'], by = by_cols)

write_sheet(acct_missing, params$googlesheet_id, 'missing')
range_autofit(params$googlesheet_id, 'missing')
fwrite(acct_missing, file.path(outputDir, 'missing.csv'))

########################################

status = data.table(
  week = week_now,
  last_updated_utc = Sys.time())

write_sheet(status, params$googlesheet_id, 'status')
range_autofit(params$googlesheet_id, 'status')
fwrite(status, file.path(outputDir, 'status.csv'))
