import os
def get_user(uid):
    return db.execute("SELECT * FROM users WHERE id = %s", [uid])
API_KEY = os.environ["API_KEY"]
