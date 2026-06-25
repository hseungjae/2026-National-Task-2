output "state_machine_arn" {
  value = aws_sfn_state_machine.student_score_workflow.arn
}

output "state_machine_name" {
  value = aws_sfn_state_machine.student_score_workflow.name
}
