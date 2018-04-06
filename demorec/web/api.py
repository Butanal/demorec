#!/usr/bin/env python3

from flask import Flask
from flask_restful import Resource, Api, reqparse
import re
import os
import base64
import sys

app = Flask(__name__)
api = Api(app)

try:
    sv_key = open("key.txt", "r").read()
except FileNotFoundError:
    print("Error : no server key found in key.txt.")
    sys.exit()

pending_posts = {
                }

parser = reqparse.RequestParser()
parser.add_argument("sid64", type=int, help="Invalid SteamID64", required=True)
parser.add_argument("filename", help="Invalid filename", required=True)
parser.add_argument("cl_key", type=int, help="Invalid client key",
                    required=True)

write_parser = parser.copy()
write_parser.add_argument("data_b64", help="Invalid data", required=True)

client_parser = parser.copy()
client_parser.add_argument("sv_key", help="Invalid server key",
                           required=True)


def validate_sid64(sid64):
    return re.match("^765\d{7,17}", str(sid64))


def validate_filename(filename):
    return re.match(".*\.dem$", filename)


def find_tbl(sid64, filename, key):
    for tbl in pending_posts[sid64]:
        if tbl["filename"] == filename and tbl["key"] == key:
            return tbl

    return False


def create_if_not_exists(directory):
    if not os.path.exists(directory):
        os.makedirs(directory)


class DemoWrite(Resource):
    def post(self):
        args = write_parser.parse_args(strict=True)

        sid64 = args["sid64"]
        filename = args["filename"]
        key = args["cl_key"]

        if not (validate_sid64(sid64) and sid64 in pending_posts):
            return {"message": "Invalid SteamID64, frick off."}, 400

        if not validate_filename(filename):
            return {"message": "Invalid filename, frick off."}, 400

        demo_tbl = find_tbl(sid64, filename, key)

        if not demo_tbl:
            return {"message": "No such demo, frick off."}, 400

        create_if_not_exists("demos/" + str(sid64))

        data_b64 = args["data_b64"]

        if len(data_b64) == 0:
            return {"message": "Invalid data, frick off."}, 400

        try:
            data = base64.b64decode(data_b64)
        except:
            return {"message": "Invalid b64 data, frick off."}, 400

        filename = "demos/" + str(sid64) + "/" + filename

        with open(filename, "wb") as f:
            f.write(data)

        pending_posts[sid64].remove(demo_tbl)

        print("Client {} successfully uploaded demo.".format(sid64))

        return {"message": "Success."}


class ClientAdd(Resource):
    def post(self):
        args = client_parser.parse_args(strict=True)
        sid64 = args["sid64"]
        filename = args["filename"]
        given_sv_key = args["sv_key"]
        cl_key = args["cl_key"]

        if given_sv_key != sv_key:
            return {"message": "Invalid server key, frick off"}, 401

        if not validate_sid64(sid64):
            return {"message": "Invalid SteamID64"}, 400

        if not validate_filename(filename):
            return {"message": "Invalid filename"}, 400

        if sid64 not in pending_posts:
            pending_posts[sid64] = []

        pending_posts[sid64].append({"filename": filename, "key": cl_key})

        print("Client {} now able to post demo.".format(sid64))

        return {"message": "Success."}


api.add_resource(DemoWrite, "/postdemo")
api.add_resource(ClientAdd, "/addclient")

if __name__ == "__main__":
    app.run(host="0.0.0.0")
