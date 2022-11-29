import os
from flask import Flask, request, jsonify, make_response, send_file
from flask_pymongo import PyMongo
from bson.objectid import ObjectId
from gridfs import GridFS
import requests

from .objects import Transaction, User
from .config import FlaskConfig
from .constants import *


def create_app(config):
    app = Flask(__name__)
    app.config["MONGO_URI"] = config.MONGO_URI

    db = create_db(app)
    fs = GridFS(db)

    @app.route("/users/<bankId>/transactions", methods=["GET"])
    def get_transactions(bankId):
        user = db.users.find_one_or_404({"bankId": bankId})
        User.make_json_serializable(user)

        return jsonify(data=user["transactions"])


    @app.route("/users/<bankId>/transactions", methods=["POST"])
    def post_transactions(bankId):
        if request.content_type != "application/json":
            return make_response(f"Expected content type application/json, not {request.content_type}", unsupported_media_type)
        transaction_dict = request.json
        transaction_dict.pop("_id", None)
        transaction_dict.pop("image_id", None)

        try:
            transaction = Transaction.from_dict(request.json)
        except KeyError as e:
            key = e.args[0]
            return make_response(f"Missing required field \"{key}\"", unprocessable_entity)
        except TypeError as e:
            return make_response(e.args[0], unprocessable_entity)

        if len(transaction.items) == 0:
            return make_response("Field \"items\" may not be an empty list", unprocessable_entity)

        user = db.users.find_one({"bankId": bankId})
        if user is None:
            user = User(bankId, [transaction])
            db.users.insert_one(user.to_dict())
        else:
            update_action = {"$push": {"transactions": transaction.to_dict()}}
            db.users.update_one({"_id": user["_id"]}, update_action)

        return make_response(jsonify(data=transaction.to_dict(True)), created)


    @app.route("/users/<bankId>/transactions/<ObjectId:transactionId>/image", methods=["GET"])
    def get_image(bankId, transactionId):
        user = db.users.find_one_or_404({"bankId": bankId, "transactions._id": transactionId}, {"_id": 0, "transactions.$": 1})
        transaction = user["transactions"][0]
        image_id = transaction["image_id"] if "image_id" in transaction else None
        image = fs.find_one(ObjectId(image_id)) if image_id is not None else None
        if image is None:
            return make_response("No image found", not_found)

        return send_file(image, mimetype=image.content_type[0])

    
    @app.route("/users/<bankId>/transactions/<ObjectId:transactionId>/image", methods=["PUT"])
    def put_image(bankId, transactionId):
        user = db.users.find_one_or_404({"bankId": bankId, "transactions._id": transactionId}, {"_id": 0, "transactions.$": 1})
        transaction = user["transactions"][0]
        image_id = transaction["image_id"] if "image_id" in transaction else None
        image_id = ObjectId(image_id)

        if not "image_id" in transaction:
            db.users.update_one({"bankId": bankId, "transactions._id": transactionId}, {"$set": {"transactions.$.image_id": image_id}})
        else:
            fs.delete(image_id)

        fs.put(request.stream, _id=image_id, content_type=request.mimetype)

        return make_response("", no_content)

    return app


def create_db(app):
    return PyMongo(app).db


if __name__ == "__main__":
    ENVIRONMENT_DEBUG = os.environ.get("APP_DEBUG", True)
    ENVIRONMENT_PORT = os.environ.get("APP_PORT", 5000)
    app = create_app(FlaskConfig())
    app.run(host='0.0.0.0', port=ENVIRONMENT_PORT, debug=ENVIRONMENT_DEBUG)
