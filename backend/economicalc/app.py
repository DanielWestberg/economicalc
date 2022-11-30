import os
from flask import Flask, request, jsonify, make_response, send_file
from flask_pymongo import PyMongo
from bson.objectid import ObjectId
from gridfs import GridFS
import requests

from .objects import Receipt, User
from .config import FlaskConfig
from .constants import *


def create_app(config):
    app = Flask(__name__)
    app.config["MONGO_URI"] = config.MONGO_URI

    db = create_db(app)
    fs = GridFS(db)

    @app.route("/users/<bankId>/receipts", methods=["GET", "POST"])
    def user_receipts(bankId):
        if request.method == "GET":
            return get_receipts(bankId, request)
        
        return post_receipts(bankId, request)


    @app.route('/initiate_bank_session/')
    def initiate_bank_session():
        appUri = ""
        callBackUri = ""
        fields = {}
        originatingUserIp = ""
        providerName = ""

        authenticationOptionDefinition = "",
        authenticationOptionsGroup = "",
        selectedAuthenticationOptions = [
            authenticationOptionDefinition,
            authenticationOptionsGroup,
            fields 
        ]
        triggerRefresh = True
        url = "https://api.tink.com/link/v1/session"
        #request = requests.post()
        return ""

    @app.route('/tink_access_token/<code>')
    def tink_access_token(code):

        ENVIRONMENT_TINK_CLIENT_ID = os.environ.get('TINK_CLIENT_ID')
        ENVIRONMENT_TINK_CLIENT_SECRET = os.environ.get('TINK_CLIENT_SECRET')
        headers = {
            'Content-Type': 'application/x-www-form-urlencoded',
        }
        print(ENVIRONMENT_TINK_CLIENT_ID)
        print(ENVIRONMENT_TINK_CLIENT_SECRET)
        data = f'code={code}&client_id={ENVIRONMENT_TINK_CLIENT_ID}&client_secret={ENVIRONMENT_TINK_CLIENT_SECRET}&grant_type=authorization_code'
        print(data)
        response = requests.post('https://api.tink.com/api/v1/oauth/token', headers=headers, data=data)
        print(response.text, flush=True)
        return(
            response.text
        )
    def session_token_set(access_token):
        return ""

    def session_token_get(session_token):
        return ""
        
        

    @app.route('/tink_transaction_history/<access_token>')
    def tink_transaction_history(access_token):

        headers = {
            'Authorization': f'Bearer {access_token}',
        }

        response = requests.get('https://api.tink.com/data/v2/transactions', headers=headers)

        return response.text

    @app.route('/tink_transaction_history/<access_token>')
    def tink_account_info(access_token):

        headers = {
            'Authorization': f'Bearer {access_token}',
        }

        response = requests.get('https://api.tink.com/data/v2/accounts', headers=headers)
        print("TRANSACTIONS:::")
        print(response.text)

        return response.text


    def get_receipts(bankId, request):
        user = db.users.find_one_or_404({"bankId": bankId})
        User.make_json_serializable(user)

        return jsonify(data=user["receipts"])


    def parse_receipt_or_make_response(receipt_dict):
        try:
            receipt = Receipt.from_dict(receipt_dict)
        except KeyError as e:
            key = e.args[0]
            return make_response(f"Missing required field \"{key}\"", unprocessable_entity)
        except TypeError as e:
            return make_response(e.args[0], unprocessable_entity)

        return receipt


    def post_receipts(bankId, request):
        required_type = "application/json"
        if request.content_type[:len(required_type)] != "application/json":
            return make_response(f"Expected content type application/json, not {request.content_type}", unsupported_media_type)
        receipt_dict = request.json
        receipt_dict.pop("_id", None)
        receipt_dict.pop("imageId", None)

        receipt = parse_receipt_or_make_response(receipt_dict)
        if type(receipt) != Receipt:
            return receipt

        if len(receipt.items) == 0:
            return make_response("Field \"items\" may not be an empty list", unprocessable_entity)

        user = db.users.find_one({"bankId": bankId})
        if user is None:
            user = User(bankId, [receipt])
            db.users.insert_one(user.to_dict())
        else:
            update_action = {"$push": {"receipts": receipt.to_dict()}}
            db.users.update_one({"_id": user["_id"]}, update_action)

        return make_response(jsonify(data=receipt.to_dict(True)), created)

    @app.route("/users/<bankId>/receipts/<ObjectId:receiptId>", methods=["PUT"])
    def user_receipt_by_id(bankId, receiptId):
        # When more methods are added for this URL, check request.method to determine the appropriate method to call
        return put_receipt(bankId, receiptId, request)


    def put_receipt(bankId, receiptId, request):
        required_type = "application/json"
        if request.content_type[:len(required_type)] != required_type:
            return make_response(f"Expected content type application/json, not {request.content_type}", unsupported_media_type)

        receipt_dict = request.json

        new_receipt = parse_receipt_or_make_response(receipt_dict)
        if type(new_receipt) != Receipt:
            return new_receipt

        user = db.users.find_one_or_404({"bankId": bankId, "receipts._id": receiptId}, {"_id": 0, "receipts.$": 1})
        old_receipt = user["receipts"][0]
        new_receipt.id = old_receipt["_id"]

        new_receipt.image_id = old_receipt["imageId"] if "imageId" in old_receipt else None

        db.users.find_one_and_update({"bankId": bankId, "receipts._id": receiptId}, {"$set": {"receipts.$": new_receipt.to_dict()}})
        return jsonify(data=new_receipt.to_dict(True))


    @app.route("/users/<bankId>/receipts/<ObjectId:receiptId>/image", methods=["GET", "PUT"])
    def user_receipt_image(bankId, receiptId):
        if request.method == "GET":
            return get_image(bankId, receiptId, request)

        return put_image(bankId, receiptId, request)


    def get_image(bankId, receiptId, request):
        user = db.users.find_one_or_404({"bankId": bankId, "receipts._id": receiptId}, {"_id": 0, "receipts.$": 1})
        receipt = user["receipts"][0]
        image_id = receipt["imageId"] if "imageId" in receipt else None
        image = fs.find_one(ObjectId(image_id)) if image_id is not None else None
        if image is None:
            return make_response("No image found", not_found)

        return send_file(image, mimetype=image.content_type[0])

    
    def put_image(bankId, receiptId, request):
        user = db.users.find_one_or_404({"bankId": bankId, "receipts._id": receiptId}, {"_id": 0, "receipts.$": 1})
        receipt = user["receipts"][0]
        image_id = receipt["imageId"] if "imageId" in receipt else None
        image_id = ObjectId(image_id)

        if not "imageId" in receipt:
            db.users.update_one({"bankId": bankId, "receipts._id": receiptId}, {"$set": {"receipts.$.imageId": image_id}})
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
