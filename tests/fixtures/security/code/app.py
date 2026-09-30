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
