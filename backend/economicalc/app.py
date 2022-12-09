from datetime import timedelta
import os
from flask import Flask, request, jsonify, make_response, send_file, session
from flask_pymongo import PyMongo
from bson.objectid import ObjectId
from gridfs import GridFS
import requests

from .objects import Category, Receipt, User
from .config import FlaskConfig
from .constants import *


def create_app(config):
    app = Flask(__name__)
    app.config["MONGO_URI"] = config.MONGO_URI
    app.secret_key= os.environ.get('TINK_CLIENT_SECRET')
    app.permanent_session_lifetime=timedelta(minutes=15)

    db = create_db(app)
    fs = GridFS(db)

    def make_unauthorized_response(message="Authentication required"):
        return make_response(message, unauthorized)

    def initiate_session(access_token, ssn):
        session_id = str(ObjectId())
        session["id"] = session_id
        session["access_token"] = access_token
        session["ssn"] = ssn
        return session_id

    def session_is_valid(session_id):
        return "id" in session and session["id"] == session_id
        
    def terminate_session():
        pass

    @app.route("/tink_user_data")
    def tink_user_data():
        account_report_id = request.json["account_report_id"]
        transaction_report_id = request.json["transaction_report_id"]
        cred_respose = post_credentials_token(True)
        print(cred_respose, flush=True)
        access_token = cred_respose['access_token']


        account_report = get_account_info(account_report_id, access_token)
        transaction_report = get_transaction_data(transaction_report_id, access_token)
        if account_report.status_code != 200 or transaction_report.status_code != 200:
            return make_response("Dumbass", bad_request)

        account_report = account_report.json()
        transaction_report = transaction_report.json()
        #print(account_report["userDataByProvider"][0])
        ssn = account_report["userDataByProvider"][0]["identity"]["ssn"]
        print(ssn)

        #CREATE NEW SESSION
        session_id = initiate_session(access_token, ssn)

        res_json = {
            "session_id": str(session_id),
            "account_report": account_report,
            "transaction_report": transaction_report,
        }

        return jsonify(data=res_json)

        

    def get_account_info(account_report_id, access_token):
        headers = {'Authorization': f'Bearer {access_token}',}
        response = requests.get(
        f'https://api.tink.com/api/v1/account-verification-reports/{account_report_id}', headers=headers,)
        return response

    def get_transaction_data(transaction_report_id, access_token):
        headers = {'Authorization': f'Bearer {access_token}',}
        response = requests.get(f'https://api.tink.com/data/v2/transaction-reports/{transaction_report_id}', headers=headers,)
        return response
    
    def post_credentials_token(test : bool):
        if test:
            ENVIRONMENT_TINK_CLIENT_ID = os.environ.get('TINK_CLIENT_ID')
            ENVIRONMENT_TINK_CLIENT_SECRET = os.environ.get('TINK_CLIENT_SECRET')
        else:
            ENVIRONMENT_TINK_CLIENT_ID = os.environ.get('PROD_TINK_CLIENT_ID')
            ENVIRONMENT_TINK_CLIENT_SECRET = os.environ.get('PROD_TINK_CLIENT_SECRET')

        headers = { 'Content-Type': 'application/x-www-form-urlencoded', }

        data = f'client_id={ENVIRONMENT_TINK_CLIENT_ID}&client_secret={ENVIRONMENT_TINK_CLIENT_SECRET}&grant_type=client_credentials&scope=account-verification-reports:read,transaction-reports:readonly'

        response = requests.post('https://api.tink.com/api/v1/oauth/token', headers=headers, data=data)

        return response.json()
        

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

    @app.route('/tink_access_token/<code>/<test>')
    def tink_access_token(code, test):
        if test == 'T':
            ENVIRONMENT_TINK_CLIENT_ID = os.environ.get('TINK_CLIENT_ID')
            ENVIRONMENT_TINK_CLIENT_SECRET = os.environ.get('TINK_CLIENT_SECRET')
        else:
            ENVIRONMENT_TINK_CLIENT_ID = os.environ.get('PROD_TINK_CLIENT_ID')
            ENVIRONMENT_TINK_CLIENT_SECRET = os.environ.get('PROD_TINK_CLIENT_SECRET')
        headers = {
            'Content-Type': 'application/x-www-form-urlencoded',
        }
        print(ENVIRONMENT_TINK_CLIENT_ID)
        print(ENVIRONMENT_TINK_CLIENT_SECRET)
        data = f'code={code}&client_id={ENVIRONMENT_TINK_CLIENT_ID}&client_secret={ENVIRONMENT_TINK_CLIENT_SECRET}&grant_type=authorization_code&scope=transactions:read,user:read,account:read'
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


    @app.route("/users/<session_id>/receipts", methods=["GET", "POST"])
    def user_receipts(session_id):
        if not session_is_valid(session_id):
            return make_unauthorized_response()

        ssn = session["ssn"]
        if request.method == "GET":
            return get_receipts(ssn, request)
        
        return post_receipts(ssn, request)


    def get_receipts(bankId, request):
        user = db.users.find_one_or_404({"bankId": bankId})
        User.make_json_serializable(user)

        return jsonify(data=user["receipts"])


    def parse_receipt_or_make_response(receipt_dict):
        try:
            receipt = Receipt.from_dict(receipt_dict)
        except KeyError as e:
            key = e.args[0]
            print(key)
            return make_response(f"Missing required field \"{key}\"", unprocessable_entity)
        except TypeError as e:
            print(e.args[0])
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

        user = db.users.find_one_or_404({"bankId": bankId})
        update_action = {"$push": {"receipts": receipt.to_dict()}}
        db.users.update_one({"_id": user["_id"]}, update_action)

        return make_response(jsonify(data=receipt.to_dict(True)), created)

    @app.route("/users/<session_id>/receipts/<ObjectId:receiptId>", methods=["PUT", "DELETE"])
    def user_receipt_by_id(session_id, receiptId):
        if not session_is_valid(session_id):
            return make_unauthorized_response()

        ssn = session["ssn"]
        if request.method == "PUT":
            return put_receipt(ssn, receiptId, request)

        return delete_receipt(ssn, receiptId, request)


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


    def delete_receipt(bankId, receiptId, request):
        delete_image(bankId, receiptId, request)
        db.users.find_one_and_update({"bankId": bankId, "receipts._id": receiptId}, {"$pull": {"receipts": {"_id": receiptId}}})
        return make_response("", no_content)


    @app.route("/users/<session_id>/receipts/<ObjectId:receiptId>/image", methods=["GET", "PUT", "DELETE"])
    def user_receipt_image(session_id, receiptId):
        if not session_is_valid(session_id):
            return make_unauthorized_response()

        ssn = session["ssn"]
        if request.method == "GET":
            return get_image(ssn, receiptId, request)
        elif request.method == "PUT":
            return put_image(ssn, receiptId, request)

        return delete_image(ssn, receiptId, request)


    def get_image(bankId, receiptId, request):
        user = db.users.find_one_or_404({"bankId": bankId, "receipts._id": receiptId}, {"_id": 0, "receipts.$": 1})
        receipt = user["receipts"][0]
        image_id = receipt["imageId"] if "imageId" in receipt else None
        image = fs.find_one(ObjectId(image_id)) if image_id is not None else None
        if image is None:
            return make_response("No image found", not_found)

        return send_file(image, mimetype=image.content_type[0])

    
    def put_image(bankId, receiptId, request):
        if len(request.files) == 0:
            return make_response("No file found in request", bad_request)

        user = db.users.find_one_or_404({"bankId": bankId, "receipts._id": receiptId}, {"_id": 0, "receipts.$": 1})
        receipt = user["receipts"][0]
        image_id = receipt["imageId"] if "imageId" in receipt else None
        image_id = ObjectId(image_id)

        if not "imageId" in receipt:
            db.users.update_one({"bankId": bankId, "receipts._id": receiptId}, {"$set": {"receipts.$.imageId": image_id}})
        else:
            fs.delete(image_id)

        file = request.files["file"]
        fs.put(file, _id=image_id, content_type=request.mimetype)

        return make_response("", no_content)


    def delete_image(bankId, receiptId, request):
        user = db.users.find_one({"bankId": bankId, "receipts._id": receiptId}, {"_id": 0, "receipts.$": 1})
        receipt = user["receipts"][0] if user is not None else None
        image_id = ObjectId(receipt["imageId"]) if receipt is not None and "imageId" in receipt else None
        if image_id is not None:
            fs.delete(image_id)

        return make_response("", no_content)


    @app.route("/users/<session_id>/categories", methods=["GET", "POST"])
    def user_categories(session_id):
        if not session_is_valid(session_id):
            return make_unauthorized_response()

        ssn = session["ssn"]
        if request.method == "GET":
            return get_categories(ssn, request)

        return post_category(ssn, request)


    def get_categories(bankId, request):
        user = db.users.find_one_or_404({"bankId": bankId})
        categories = user["categories"]
        return jsonify(data=categories)


    def parse_category_or_make_response(category_dict):
        try:
            category = Category.from_dict(category_dict)
        except KeyError as e:
            key = e.args[0]
            return make_response(f"Missing required field \"{key}\"", unprocessable_entity)
        except TypeError as e:
            return make_response(e.args[0], unprocessable_entity)

        return category


    def post_category(bankId, request):
        user = db.users.find_one_or_404({"bankId": bankId})
        category = parse_category_or_make_response(request.json)
        if type(category) != Category:
            return category

        filtered_user = db.users.find_one({"bankId": bankId, "categories.id": category.id}, {"_id": 0, "categories.$": 1})
        if filtered_user is not None:
            return make_response(f"Category with ID {category.id} already exists", conflict)

        update_action = {"$push": {"categories": category.to_dict()}}
        db.users.update_one({"_id": user["_id"]}, update_action)

        return make_response(jsonify(data=category.to_dict(True)), created)


    @app.route("/users/<session_id>/categories/<int:categoryId>", methods=["PUT", "DELETE"])
    def user_category_by_id(session_id, categoryId):
        if not session_is_valid(session_id):
            return make_unauthorized_response()

        ssn = session["ssn"]
        if request.method == "PUT":
            return put_category(ssn, categoryId, request)

        return delete_category(ssn, categoryId, request)


    def put_category(bankId, categoryId, request):

        category_dict = request.json
        category_dict["id"] = categoryId
        category = parse_category_or_make_response(category_dict)
        if type(category) != Category:
            return category

        user = db.users.find_one({"bankId": bankId, "categories.id": categoryId}, {"_id": 0, "categories.$": 1})
        if user is None:
            user = db.users.find_one_or_404({"bankId": bankId})
            update_action = {"$push": {"categories": category.to_dict()}}
            db.users.update_one({"_id": user["_id"]}, update_action)

            return make_response(jsonify(data=category.to_dict(True)), created)

        db.users.find_one_and_update({"bankId": bankId, "categories.id": categoryId}, {"$set": {"categories.$": category.to_dict()}})
        return jsonify(data=category.to_dict(True))


    def delete_category(bankId, categoryId, request):
        db.users.find_one_and_update({"bankId": bankId, "categories.id": categoryId}, {"$pull": {"categories": {"id": categoryId}}})
        return make_response("", no_content)


    # TODO: Add authentication with BankID
    @app.route("/users/<session_id>", methods=["PUT"])
    def create_user(session_id):
        if not session_is_valid(session_id):
            return make_unauthorized_response()

        ssn = session["ssn"]
        if db.users.find_one({"bankId": ssn}) is None:
            db.users.insert_one({"bankId": ssn, "receipts": [], "categories": []})

        return make_response("", no_content)
        

    return app

    


def create_db(app):
    return PyMongo(app).db



if __name__ == "__main__":
    ENVIRONMENT_DEBUG = os.environ.get("APP_DEBUG", True)
    ENVIRONMENT_PORT = os.environ.get("APP_PORT", 5000)
    app = create_app(FlaskConfig())
    app.run(host='0.0.0.0', port=ENVIRONMENT_PORT, debug=ENVIRONMENT_DEBUG)
