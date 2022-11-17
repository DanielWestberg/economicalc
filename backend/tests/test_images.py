import pytest

from flask.json import loads

from .conftest import constants

from economicalc.objects.image import Image


@pytest.fixture()
def images():
    return [
        Image("test.jpg").to_dict()
    ]


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

        image = loads(response.data)[0]

        assert image["name"] == "test.jpg"
