import os
from flask import Flask, request, jsonify
from flask_pymongo import PyMongo
from bson.objectid import ObjectId
import requests

from .objects.image import Image
from .config import RunConfig


def create_app(config):
    app = Flask(__name__)
    app.config["MONGO_URI"] = config.MONGO_URI

    db = PyMongo(app).db

    @app.route('/')
    def index():
        return jsonify(
            status=True,
            message='Welcome to the Dockerized Flask MongoDB app!'
        )

    @app.route('/receipts/<id>')
    def fetch_receipts(id):
        user = db.users.find_one_or_404({"bankId": id})
        return jsonify(
            status=True,
            data=user['receipts']
        )

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
    

    @app.route('/tink_transaction_history/<access_token>')
    def tink_transaction_history(access_token):

        headers = {
            'Authorization': f'Bearer {access_token}',
        }

        response = requests.get('https://api.tink.com/data/v2/transactions', headers=headers)

        return response.text


    
    # XXX: Debug only
    @app.route('/user')
    def user():
        users = db.user.find()
        data = []
        for user in users:
            data.append({
                'id': str(user['_id']),
            })

        return jsonify(data=data)

    @app.route('/image')
    def image():
        images = db.image.find()
        data = []
        for image in images:
            data.append(Image.doc2Dict(image))

        return jsonify(
            status=True,
            data=data
        )

    return app


if __name__ == "__main__":
    ENVIRONMENT_DEBUG = os.environ.get("APP_DEBUG", True)
    ENVIRONMENT_PORT = os.environ.get("APP_PORT", 5000)
    app = create_app(RunConfig())
    app.run(host='0.0.0.0', port=ENVIRONMENT_PORT, debug=ENVIRONMENT_DEBUG)
