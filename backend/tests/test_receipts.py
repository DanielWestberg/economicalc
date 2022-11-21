import pytest

from datetime import datetime
from dateutil.parser import *

from flask.json import loads

from .conftest import constants

from economicalc.objects import *
from economicalc.app import create_db


@pytest.fixture()
def images():
    return [
        Image("test.jpg"),
        Image("rofl.jpg"),
    ]


@pytest.fixture()
def items():
    return [
        Item("Äpple", 1500, 7),
        Item("Banan", 2000, 7),
        Item("Fil", 1700, 2),
        Item("Kikärter", 1300, 1),
        Item("Vetemjöl", 2600, 1),
        Item("Jäst", 350, 1),
    ]


@pytest.fixture()
def receipts(items, images):
    return [
        Receipt(
            0,
            "Ica",
            [items[0], items[1], items[3]],
            datetime(2022, 6, 30),
            1500 + 2000 + 1300,
            images[1]
        ), Receipt(
            1,
            "Coop",
            [items[2], items[3], items[4], items[5]],
            datetime(2022, 7, 1),
            1700 + 1300 + 2600 + 350
        ), Receipt(
            2,
            "Willy's",
            [items[1], items[5]],
            datetime(2021, 12, 13),
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


@pytest.fixture(autouse=True)
def db(app, images, users):
    db = create_db(app)

    for image in images:
        db.images.insert_one(image.to_dict())

    for user in users:
        db.users.insert_one(user.to_dict())

    yield db

    for user in users:
        db.users.delete_one(user.to_dict())

    for image in images:
        db.images.delete_one(image.to_dict())


class TestReceipts():

    def test_get_user_receipts(self, images, client, users):
        for user in users:
            response = client.get(f"/users/{user.bankId}/receipts")
            assert response.status == constants["ok"]

            response_receipts = loads(response.data)

            for (expected_receipt, actual_receipt) in zip(user.receipts, response_receipts):
                expected_receipt = expected_receipt.to_dict()

                for key in ["id", "store", "total_sum"]:
                    assert expected_receipt[key] == actual_receipt[key]

                assert expected_receipt["date"] == parse(actual_receipt["date"])

                if "image" not in expected_receipt:
                    assert "image" not in actual_receipt
                else:
                    expected_image = expected_receipt["image"]
                    actual_image = actual_receipt["image"]
                    assert expected_image["name"] == actual_image["name"]
