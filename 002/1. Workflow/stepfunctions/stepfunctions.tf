resource "aws_sfn_state_machine" "student_score_workflow" {
  name     = "wsc2026-student-score-workflow"
  role_arn = var.sf_role_arn
  type     = "STANDARD"

  definition = jsonencode({
    Comment = "Student Score Processing Workflow"
    StartAt = "ProcessStudentData"
    States = {
      ProcessStudentData = {
        Type     = "Task"
        Resource = "arn:aws:states:::lambda:invoke"
        Parameters = {
          FunctionName = var.score_function_name
          Payload = {
            "key.$" = "$.key"
          }
        }
        ResultSelector = {
          "statusCode.$" = "$.Payload.statusCode"
          "processed.$"  = "$.Payload.processed"
          "errors.$"     = "$.Payload.errors"
        }
        ResultPath = "$.result"
        Retry = [
          {
            ErrorEquals     = ["States.ALL"]
            IntervalSeconds = 2
            MaxAttempts     = 3
            BackoffRate     = 2
          }
        ]
        Next = "CheckResult"
      }
      CheckResult = {
        Type = "Choice"
        Choices = [
          {
            Variable      = "$.result.statusCode"
            NumericEquals = 200
            Next          = "MoveToProcessed"
          }
        ]
        Default = "MoveToError"
      }
      MoveToProcessed = {
        Type = "Task"
        Parameters = {
          "Bucket.$"     = "$.bucket"
          "CopySource.$" = "States.Format('{}/{}', $.bucket, $.key)"
          "Key.$"        = "States.Format('processed/{}', States.ArrayGetItem(States.StringSplit($.key, '/'), 1))"
        }
        Resource   = "arn:aws:states:::aws-sdk:s3:copyObject"
        ResultPath = null
        Next       = "DeleteInputFile"
      }
      DeleteInputFile = {
        Type = "Task"
        Parameters = {
          "Bucket.$" = "$.bucket"
          "Key.$"    = "$.key"
        }
        Resource   = "arn:aws:states:::aws-sdk:s3:deleteObject"
        ResultPath = null
        End        = true
      }
      MoveToError = {
        Type = "Task"
        Parameters = {
          "Bucket.$"     = "$.bucket"
          "CopySource.$" = "States.Format('{}/{}', $.bucket, $.key)"
          "Key.$"        = "States.Format('error/{}', States.ArrayGetItem(States.StringSplit($.key, '/'), 1))"
        }
        Resource   = "arn:aws:states:::aws-sdk:s3:copyObject"
        ResultPath = null
        Next       = "DeleteInputFileOnError"
      }
      DeleteInputFileOnError = {
        Type = "Task"
        Parameters = {
          "Bucket.$" = "$.bucket"
          "Key.$"    = "$.key"
        }
        Resource   = "arn:aws:states:::aws-sdk:s3:deleteObject"
        ResultPath = null
        Next       = "WorkflowFailed"
      }
      WorkflowFailed = {
        Type  = "Fail"
        Error = "WorkflowFailed"
        Cause = "Processing failed or file not found"
      }
    }
  })

  tags = { Name = "wsc2026-student-score-workflow" }
}
