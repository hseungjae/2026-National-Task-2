resource "aws_sfn_state_machine" "workflow" {
  name     = "workflow-state-machine"
  role_arn = aws_iam_role.sfn_role.arn

  definition = jsonencode({
    Comment = "CSV workflow"

    StartAt = "InvokeLambda"

    States = {
      InvokeLambda = {
        Type     = "Task"
        Resource = "arn:aws:states:::lambda:invoke"

        Parameters = {
          FunctionName = var.lambda_function_name
          "Payload.$"  = "$"
        }

        End = true
      }
    }
  })
}