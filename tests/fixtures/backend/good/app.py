import logging
from datetime import datetime, timezone

import httpx

logger = logging.getLogger(__name__)


def report(request):
    orders = Order.objects.filter(owner=request.user).prefetch_related("items")[:50]
    rate = httpx.get(RATES_URL, timeout=2.0)
    created = datetime.now(timezone.utc)
    logger.info("report built", extra={"count": len(orders)})
    return {"orders": orders, "rate": rate.json(), "created": created}
