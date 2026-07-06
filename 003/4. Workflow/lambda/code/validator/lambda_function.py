def lambda_handler(event, context):
    order = event
    errors = []

    order_id = str(order.get("order_id", ""))
    if not order_id.startswith("ORD-"):
        errors.append("order_id must start with 'ORD-'")

    if not str(order.get("product_id", "")):
        errors.append("product_id is empty")

    try:
        qty = int(order.get("quantity", 0))
        if qty < 1:
            errors.append("quantity must be >= 1")
    except (ValueError, TypeError):
        errors.append("quantity is not a valid number")

    try:
        price = float(order.get("unit_price", 0))
        if price <= 0:
            errors.append("unit_price must be > 0")
    except (ValueError, TypeError):
        errors.append("unit_price is not a valid number")

    if order.get("payment_method") not in ("CARD", "BANK_TRANSFER"):
        errors.append("payment_method must be CARD or BANK_TRANSFER")

    if errors:
        return {"valid": False, "order": order, "errors": errors}
    return {"valid": True, "order": order}
