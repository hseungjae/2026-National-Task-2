# 데이터 정제 워크플로우
# Transform(Lambda) 성공 → Success / ValidationError → HandleError(Fail)
resource "aws_sfn_state_machine" "workflow" {
  name     = var.state_machine_name
  role_arn = var.role_arn

  definition = jsonencode({
    Comment = "wsc2026 Workflow"
    StartAt = "Transform"
    States = {
      Transform = {
        Type     = "Task"
        Resource = "arn:aws:states:::lambda:invoke"
        Parameters = {
          FunctionName = var.lambda_arn
          "Payload.$"  = "$"
        }
        ResultPath = "$.transformResult"
        Catch = [{
          ErrorEquals = ["ValidationError"]
          Next        = "HandleError"
          ResultPath  = "$.error"
        }]
        Next = "Success"
      }
      HandleError = {
        Type  = "Fail"
        Error = "ValidationError"
        Cause = "Transform validation failed"
      }
      Success = {
        Type = "Succeed"
      }
    }
  })
}
