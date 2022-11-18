import pytest

from datetime import date

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
def items():
    return [
        Item("Äpple", 1500),
        Item("Banan", 2000),
        Item("Fil", 1700),
        Item("Kikärter", 1300),
        Item("Vetemjöl", 2600),
        Item("Jäst", 350),
    ]


@pytest.fixture()
def receipts(items, images):
    return [
        Receipt(
            0,
            "Ica",
            [items[0], items[1], items[3]],
            date(2022, 6, 30),
            1500 + 2000 + 1300,
            images[1]
        ), Receipt(
            1,
            "Coop",
            [items[2], items[3], items[4], items[5]],
            date(2022, 7, 1),
            1700 + 1300 + 2600 + 350
        ), Receipt(
            2,
            "Willy's",
            [items[1], items[5]],
            date(2021, 12, 13),
            2000 + 350,
            images[0]
        )
    ]


@pytest.fixture()
def users(receipts):
    return [
        User(
            "test1",
            [receipts[0], receipts[2]]
        ),
        User(
            "test2",
            [receipts[1]]
        )
    ]


@pytest.fixture()
def db_images(db, images):
    for image in images:
        db.images.insert_one(image)

    yield db.images

    for image in images:
        db.images.delete_one(image)


@pytest.fixture()
def db_users(db, users):
    for user in users:
        db.users.insert_one(user)

    yield db.users

    for user in users:
        db.users.delete_one(user)


class TestImages():

    def test_get_user_image(self, images, db_images, client, users, db_users):
        for user in users:
            response = client.get(f"/user/{user.bankId}/receipts")
            assert response.status == constants["ok"]

            response_data = loads(response.data)
            response_receipts = response_data["receipts"]

            for (expected_receipt, actual_receipt) in zip(response_receipts, user.receipts):
                expected_image = expected_receipt.image if expected_receipt.image is not None else "null"
                response_image = response_receipt["image"]

                if expected_image == "null":
                    assert response_image == "null"
                else:
                    assert expected_image.name == response_image["name"]
