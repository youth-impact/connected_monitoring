source(file.path('code', 'setup.R'))

# TODO: calculate get_next_level week by week, do merges and handle duplicates
id = as_sheets_id(params$file_url)

sens_raw = unique(scto_read(auth, 'tarl_sensitization_survey_r8'))
acct_raw = unique(scto_read(auth, 'tarl_accountability_survey_r8'))

get_next_level = function(
    current, level_up = rep(1L, length(current)), levs = 1:5, na = -99L,
    ceil = 77L) {
  i = match(current, levs)
  i[current == na] = NA
  j = !is.na(i)
  y = current
  y[j] = c(levs, ceil)[i[j] + level_up[j]]
  return(y)
}

cols = c('id', 'current_stud_name', 'current_stud_level')
sens = sens_raw[, ..cols]
setkey(sens)
sens[, current_stud_level := as.integer(current_stud_level)]
sens[, next_level := get_next_level(current_stud_level)]

sens_summary = sens[, .(
  num_students = .N),
  keyby = .(current_stud_level, next_level)]

cols = c(
  'id', 'endtime', 'week', 'student_name_b', 'checkpoint_q', 'lesson_operation')
acct = acct_raw[, ..cols]
setkey(acct)
acct[, checkpoint_q := as.integer(checkpoint_q)]
acct[, lesson_operation := as.integer(lesson_operation)]
acct[, next_level := get_next_level(checkpoint_q, lesson_operation)]

acct_summary = acct[, .(
  num_students = .N),
  keyby = .(checkpoint_q, lesson_operation, next_level)]

write_sheet(sens_summary, id, sheet = 'sens_leveling_summary')
write_sheet(acct_summary, id, sheet = 'acct_leveling_summary')
