import pytest

from flask.json import loads

from .conftest import constants

from economicalc.objects import *


@pytest.fixture()
def images():
    return map(Image.to_dict, [
        Image("test.jpg"),
        Image("rofl.jpg"),
    ])


@pytest.fixture()
def db_images(db, images):
    for image in images:
        db.images.insert_one(image)

    yield db.images

    for image in images:
        db.images.delete_one(image)


class TestImages():

    def test_get_user_image(self, images, db_images, client):
        response = client.get("/images")
        assert response.status == constants["ok"]

        response_images = loads(response.data)

        for (image_expected, image_actual) in zip(response_images, images):
            assert image_expected["name"] == image_actual["name"]
