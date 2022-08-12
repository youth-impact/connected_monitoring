library('data.table')

dataDir = 'data'
outputDir = 'output'

if (!dir.exists(outputDir)) dir.create(outputDir)

########################################

get_raw_assignments = function(path, sheet = 'FULL LIST') {
  d = readxl::read_excel(path, sheet)
  setDT(d)
  setnames(d, tolower)
  return(d)}

assignments1 = get_raw_assignments(
  file.path(dataDir, 'TaRL_R7_Accountability_Call_Assignments_w1_w3_w5.xlsx'))

assignments2 = get_raw_assignments(
  file.path(dataDir, 'Updated_TaRL_R7_Accountability_Call_Assignments_w2_w4_w6.xlsx'))

########################################

keep = data.table(
  old = c('unique household id', 'best number to call', 'student name',
          'facilitator id', 'assigned facilitator'),
  new = c('id', 'current_phone_num_best', 'student_name',
          'facilitator_id', 'facilitator_name'))

assignments = rbind(
  assignments1[, keep$old, with = FALSE][, biweekly_group := 1L],
  assignments2[, keep$old, with = FALSE][, biweekly_group := 2L])

setnames(assignments, keep$old, keep$new)

fwrite(assignments, file.path(outputDir, 'call_assignments.csv'))
