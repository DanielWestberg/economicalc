import os
from flask import Flask, request, jsonify
from flask_pymongo import PyMongo

from objects.image import Image


def create_app():
    app = Flask(__name__)
    app.config["MONGO_URI"] = 'mongodb://' + os.environ['MONGODB_USERNAME'] + ':' + os.environ['MONGODB_PASSWORD'] + '@' + os.environ['MONGODB_HOSTNAME'] + ':27017/' + os.environ['MONGODB_DATABASE']

    db = PyMongo(app).db

    @app.route('/')
    def index():
        return jsonify(
            status=True,
            message='Welcome to the Dockerized Flask MongoDB app!'
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
    app = create_app()
    app.run(host='0.0.0.0', port=ENVIRONMENT_PORT, debug=ENVIRONMENT_DEBUG)
