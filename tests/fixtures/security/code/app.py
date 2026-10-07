import subprocess, hashlib
API_KEY = "sk_live_abcd1234efgh5678ijkl"
def get_user(uid):
    return db.execute("SELECT * FROM users WHERE id = " + uid)
def run(cmd):
    subprocess.call(cmd, shell=True)
def token(u):
    return hashlib.md5(u.encode()).hexdigest()
AWS = "AKIAIOSFODNN7EXAMPLE"
DEBUG = True
def update(request):
    role = request.json.get("role")
    total = request.form["total"]
    claims = jwt.decode(token, options={"verify_signature": False})
    resp.set_cookie("sid", sid)
    tenant = request.META["HTTP_X_TENANT_ID"]
    return jsonify(os.environ)
    claims = jwt.decode(token, options={"ignore_expiration": True})
