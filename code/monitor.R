source(file.path('code', 'setup.R'))

########################################

cases = scto_read(auth, 'cases')
setnames(cases, c('facilitator', 'f_id'), c('facilitator_name', 'facilitator_id'))

########################################

# TODO: convert numeric values to meanings based on
# import_tarl_accountability_survey_r7.do

acct_survey = scto_read(auth, params$form_id, 'form')
acct_survey[, comp_date := as.IDate(
  CompletionDate, format = '%b %e, %Y %I:%M:%S %p')]
acct_survey[, week := temp_week_name]

week_now = acct_survey[comp_date == max(comp_date)]$week[1L]
acct_survey = acct_survey[week == week_now]

########################################

x = list()

x$duplicates = get_duplicates(acct_survey)

by_cols = c('facilitator_name', 'facilitator_id', 'id')
acct_monitor = get_monitor(acct_survey, cases, by_cols)

x$summary = get_summary(acct_monitor, by_cols[1:2])

x$missing = get_missing(acct_monitor, cases, by_cols)

x$status = data.table(
  week = week_now,
  last_updated_utc = Sys.time())

########################################

r = lapply(names(x), function(i) {
  write_sheet(x[[i]], params$file_url, i)
  range_autofit(params$file_url, i)})
