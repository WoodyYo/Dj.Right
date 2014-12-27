#!/usr/bin/env python
import sqlite3
import sys

class DBManager:
    def __init__(self):
        self.conn = sqlite3.connect('volunteer.db')
        self.c = self.conn.cursor()
        try:
            self.c.execute('''CREATE TABLE users 
                    (id string primary key, angry int, sad int, happy int, joyful int)''')
            self.new_user("woody")
            self.c.execute('''CREATE TABLE messages 
                    (id string, body text, time TIMESTAMP(8), read int)''')
        except:
            print "Created"
        self.commit()
    def dropall(self):
        print "If u wanna drop all table, please input the project's name"
        s = sys.stdin.readline()
        if(s.endswith("\n")):
            s = s[0:-1]
        if(s == "Dj. Right"):
            self.c.execute("DROP TABLE users")
            self.c.execute("DROP TABLE messages")
        else:
            print "Fuck U"
    def close(self):
        self.conn.commit()
        self.conn.close()
    def commit(self):
        self.conn.commit()
    def new_user(self, new_id):
        try:
            self.c.execute("INSERT INTO users VALUES (?, 0, 0, 0, 0)", [new_id])
	    self.commit()
            return True
        except:
            return False
    def parse(self, u):
        if(u):
	    a = {}
	    a["id"] = u[0]
	    a["angry"] = u[1]
	    a["sad"] = u[2]
	    a["happy"] = u[3]
	    a["joyful"] = u[4]
	    return a
        else:
            return None
    def find_by_id(self, userid):
        self.c.execute("SELECT * FROM users WHERE id=?", [userid])
        return self.parse(self.c.fetchone())
    def get_all_users(self):
        self.c.execute("SELECT * FROM users")
        return [u for u in self.c]
    def send_msg(self, userid, msg):
        if(self.find_by_id(userid)):
            self.c.execute("INSERT INTO messages VALUES (?, ?, CURRENT_TIMESTAMP, 0)", [userid, msg])
            self.commit()
            return True
        else:
            return False
    def get_all_msg(self, userid):
        self.c.execute("SELECT body FROM messages WHERE id=? and read=0 ORDER BY time", [userid])
        return [msg[0] for msg in self.c]
    def read_all_msg(self, userid):
        a = self.get_all_msg(userid)
        self.c.execute("UPDATE messages SET read=1 WHERE id=? and read=0", [userid])
        return a
    def set_emo_count(self, userid, emo, count):
	self.m.execute("UPDATE user SET ?=? WHERE id=?", [emo, count, userid])
    def broadcast(self, s):
        self.c.execute("SELECT id FROM users")
        for uid in self.c:
            uid = uid[0]
            self.send_msg(uid, s)

if __name__ == "__main__":
    m = DBManager()
    if(len(sys.argv) == 1):
        for u in m.get_all_users():
            print u
    elif(sys.argv[1])== "drop":
        m.dropall()
    elif(sys.argv[1] == 'msg'):
        uid = sys.argv[2]
        while(True):
            s = sys.stdin.readline()
            if(s == ''):
                break
            else:
                m.send_msg(uid, s)
    elif(sys.argv[1] == "peek"):
        print m.get_all_msg(sys.argv[2])
    elif(sys.argv[1] == "broadcast"):
        s = sys.stdin.readline()
        if(s == ''):
            break
        else:
            m.broadcast(s)
    else:
        for u in m.get_all_users():
            print u
    m.close()
