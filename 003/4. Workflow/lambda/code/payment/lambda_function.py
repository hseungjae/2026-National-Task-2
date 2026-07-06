from datetime import datetime, timezone


def lambda_handler(event, context):
    order = event.get("order", event)

    quantity   = int(order["quantity"])
    unit_price = float(order["unit_price"])

    total_amount = round(quantity * unit_price, 2)
    total_usd    = round(total_amount / 1350, 2)

    now_iso = datetime.now(timezone.utc).isoformat()

    order["total_amount"]   = total_amount
    order["total_usd"]      = total_usd
    order["payment_status"] = "APPROVED"
    order["processed_at"]   = now_iso

    # 원본에 ordered_at이 없으면 부여 (DynamoDB SK 필수)
    if "ordered_at" not in order or not order.get("ordered_at"):
        order["ordered_at"] = now_iso

    return order
