import os
from flask import Flask, request, jsonify
from flask_pymongo import PyMongo
from bson.objectid import ObjectId

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
