import os
from flask import Flask, request, jsonify, make_response
from flask_pymongo import PyMongo
from bson.objectid import ObjectId
import requests

from .objects import Image, User
from .config import FlaskConfig
from .constants import *


def create_app(config):
    app = Flask(__name__)
    app.config["MONGO_URI"] = config.MONGO_URI

    db = create_db(app)

    @app.route("/users/<bankId>/transactions", methods=["GET"])
    def get_transactions(bankId):
        user = db.users.find_one_or_404({"bankId": bankId})
        transactions = user["transactions"]
        return jsonify(data=transactions)

    @app.route("/users/<bankId>/transactions", methods=["POST"])
    def post_transactions(bankId):
        return make_response("", created)

    return app


def create_db(app):
    return PyMongo(app).db


if __name__ == "__main__":
    ENVIRONMENT_DEBUG = os.environ.get("APP_DEBUG", True)
    ENVIRONMENT_PORT = os.environ.get("APP_PORT", 5000)
    app = create_app(FlaskConfig())
    app.run(host='0.0.0.0', port=ENVIRONMENT_PORT, debug=ENVIRONMENT_DEBUG)
