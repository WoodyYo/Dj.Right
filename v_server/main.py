#!/usr/bin/env python
from bottle import *
from db_manager import *
import json
import os

MANAGER = DBManager()
DATAPATH = "data/"

@route('/profile/<userid>')
def profile(userid):
    global MANAGER
    user = MANAGER.find_by_id(userid)
    if(user):
        user["msg"] = MANAGER.read_all_msg(userid)
        return json.dumps(user)
    else:
        MANAGER.new_user(userid)
        return json.dumps(MANAGER.find_by_id(userid))
@route('/upload/<userid>', method='POST')
def upload(userid):
    global MANAGER
    emo = request.query['emo']
    u = MANAGER.find_by_id(userid)
    try:
        upload = request.files.get('upload')
        name, ext = os.path.splitext(upload.filename)
        save_path = DATAPATH+emo+"/"+userid+"_"+(u[emo])+ext
        MANAGER.set_emo_count(userid, emo, u[emo]+1)
        upload.save(save_path)
        return "OK"
    except:
        return "OOOPS"

if __name__ == "__main__":
    global MANAGER
    run(host="0.0.0.0", port="8888")
    MANAGER.close()
