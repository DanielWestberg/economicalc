import os
from flask import Flask, request, jsonify
from flask_pymongo import PyMongo

from .objects.image import Image
from .config import FlaskConfig


def create_app(config):
    app = Flask(__name__)
    app.config["MONGO_URI"] = config.MONGO_URI

    db = create_db(app)

    @app.route('/')
    def index():
        return jsonify(
            status=True,
            message='Welcome to the Dockerized Flask MongoDB app!'
        )

    # XXX: Debug only
    @app.route('/users')
    def user():
        users = db.user.find()
        data = []
        for user in users:
            data.append({
                'id': str(user['_id']),
            })

        return jsonify(data=data)

    @app.route('/images')
    def image():
        images = db.images.find()
        data = []
        for image in images:
            data.append(Image.doc2dict(image))

        return jsonify(
            data
        )

    return app


def create_db(app):
    return PyMongo(app).db


if __name__ == "__main__":
    ENVIRONMENT_DEBUG = os.environ.get("APP_DEBUG", True)
    ENVIRONMENT_PORT = os.environ.get("APP_PORT", 5000)
    app = create_app(FlaskConfig())
    app.run(host='0.0.0.0', port=ENVIRONMENT_PORT, debug=ENVIRONMENT_DEBUG)
