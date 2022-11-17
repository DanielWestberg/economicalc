import pytest
from flask_pymongo import PyMongo

from economicalc.config import FlaskConfig
from economicalc.app import create_app, create_db

@pytest.fixture()
def app():
    app = create_app(FlaskConfig())
    app.testing = True

    # further setup code goes here, if any

    yield app

    # cleanup code goes here, if any

@pytest.fixture()
def db(app):
    return PyMongo(app).db

@pytest.fixture()
def client(app):
    return app.test_client()