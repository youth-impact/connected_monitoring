source(file.path('code', 'setup.R'))

########################################

cases = scto_read(auth, params$dataset_id)
setnames(cases, c('f_name', 'f_id'), c('facilitator_name', 'facilitator_id'))

########################################

acct_survey = scto_read(auth, params$form_id)
acct_survey[, comp_date := as.IDate(
  CompletionDate, format = '%b %e, %Y %I:%M:%S %p')]

########################################

# raw_duplicates sheet has column for keep
# unresolved_duplicates sheet
# or use formatting to highlight the unresolved duplicates?

x = list()

x$duplicates = get_duplicates(acct_survey)

by_cols = c('facilitator_name', 'facilitator_id', 'id')
acct_monitor = get_monitor(acct_survey, cases, by_cols)

x$summary = get_summary(acct_monitor, by_cols[1:2])

x$missing = get_missing(acct_monitor, cases, by_cols)

x$status = data.table(last_updated_utc = Sys.time())

########################################

r = lapply(names(x), function(i) {
  write_sheet(x[[i]], params$file_url, i)
  range_autofit(params$file_url, i)})
