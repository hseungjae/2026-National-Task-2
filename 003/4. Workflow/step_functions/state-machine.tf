resource "aws_sfn_state_machine" "pipeline" {
  name     = "${var.prefix}-order-pipeline"
  role_arn = aws_iam_role.sfn.arn
  type     = "STANDARD"

  definition = templatefile("${path.module}/asl.json.tftpl", {
    validator_name  = "${var.prefix}-order-validator"
    payment_name    = "${var.prefix}-payment-processor"
    orders_table    = "${var.prefix}-orders"
    inventory_table = "${var.prefix}-inventory"
    history_table   = "${var.prefix}-pipeline-history"
  })

  depends_on = [aws_iam_role_policy_attachment.sfn]
}
