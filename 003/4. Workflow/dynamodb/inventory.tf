resource "aws_dynamodb_table" "inventory" {
  name         = "${var.prefix}-inventory"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "product_id"

  attribute {
    name = "product_id"
    type = "S"
  }

  tags = { Name = "${var.prefix}-inventory" }
}

# 초기 재고 데이터 (inventory-seed.json 반영)
locals {
  inventory_seed = [
    { product_id = "PROD-A100", product_name = "Wireless Keyboard",  stock = 50,  category = "electronics" },
    { product_id = "PROD-B200", product_name = "USB-C Monitor",      stock = 20,  category = "electronics" },
    { product_id = "PROD-C300", product_name = "Bluetooth Speaker",  stock = 100, category = "audio" },
  ]
}

resource "aws_dynamodb_table_item" "inventory_seed" {
  for_each = { for item in local.inventory_seed : item.product_id => item }

  table_name = aws_dynamodb_table.inventory.name
  hash_key   = aws_dynamodb_table.inventory.hash_key

  item = jsonencode({
    product_id   = { S = each.value.product_id }
    product_name = { S = each.value.product_name }
    stock        = { N = tostring(each.value.stock) }
    category     = { S = each.value.category }
  })

  # 재고가 변경되어도 Terraform이 덮어쓰지 않도록
  lifecycle {
    ignore_changes = [item]
  }
}
