import subprocess, hashlib
DB_PASSWORD = "prod_db_pw_9f8a7b6c5d4e"
def find_user(uid):
    return db.execute("SELECT * FROM users WHERE id = " + uid)
def ping(host):
    subprocess.call("ping " + host, shell=True)
def hash_pw(p):
    return hashlib.md5(p.encode()).hexdigest()
