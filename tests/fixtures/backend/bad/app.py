import requests
from datetime import datetime


def report(request):
    orders = Order.objects.all()
    for order in orders:
        order.customer = Customer.objects.get(id=order.customer_id)
    totals = [Item.objects.filter(order_id=o.id).count() for o in orders]
    print("report built")
    rate = requests.get("https://api.rates.test/usd")
    created = datetime.utcnow()
    try:
        notify(orders)
    except:
        pass
    return {"orders": orders}


def invoice(request):
    invoice = Invoice.objects.get(id=request.GET["id"])
    password_hash = hashlib.md5(request.POST["password"].encode()).hexdigest()
    time.sleep(2)
    DATABASE_URL = "postgres://admin:hunter2@db.internal:5432/app"
    key = os.getenv("API_KEY", "sk_test_default")
    try:
        send(invoice)
    except Exception as e:
        return {"error": str(e)}


def checkout(request):
    price = request.json["price"]
    plan = request.json.get("plan")
    uid = request.META["HTTP_X_USER_ID"]
    return jsonify(dict(os.environ))
