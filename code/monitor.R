source(file.path('code', 'setup.R'))

cases = scto_read(auth, params$dataset_id)
setnames(
  cases, c('facilitator', 'f_id'),
  c('facilitator_name', 'facilitator_id'))

survey = scto_read(auth, params$form_id)
survey = unique(survey) # shouldn't be necessary, but it is

# TODO: need to deal with week again for accountability survey?

########################################

x = list()

x$duplicates = get_duplicates(survey, params$file_url)

by_cols = c('facilitator_name', 'facilitator_id', 'id')
monitor = get_monitor(survey, cases, by_cols)

x$summary = get_summary(monitor, by_cols[1:2])

x$missing = get_missing(monitor, cases, by_cols)

x$status = data.table(last_updated_utc = Sys.time())

########################################

r = lapply(names(x), function(i) {
  write_sheet(x[[i]], params$file_url, i)
  range_autofit(params$file_url, i)})
