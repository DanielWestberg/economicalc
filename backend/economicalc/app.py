import os
from flask import Flask, request, jsonify
from flask_pymongo import PyMongo
from bson.objectid import ObjectId
import requests

from .objects import Image, User
from .config import FlaskConfig


def create_app(config):
    app = Flask(__name__)
    app.config["MONGO_URI"] = config.MONGO_URI

    db = create_db(app)

    @app.route("/users/<bankId>/transactions")
    def transactions(bankId):
        user = db.users.find_one_or_404({"bankId": bankId})
        transactions = user["transactions"]
        return jsonify(transactions)

    return app


def create_db(app):
    return PyMongo(app).db


if __name__ == "__main__":
    ENVIRONMENT_DEBUG = os.environ.get("APP_DEBUG", True)
    ENVIRONMENT_PORT = os.environ.get("APP_PORT", 5000)
    app = create_app(FlaskConfig())
    app.run(host='0.0.0.0', port=ENVIRONMENT_PORT, debug=ENVIRONMENT_DEBUG)
