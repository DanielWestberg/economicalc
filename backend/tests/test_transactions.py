import pytest

from datetime import datetime
from dateutil.parser import *
from typing import List, Tuple

from flask.json import loads
from bson.objectid import ObjectId
from gridfs import GridFS

import economicalc.constants as constants

from economicalc.objects import *
from economicalc.app import create_db


@pytest.fixture()
def images() -> List[Image]:
    return [
        Image("coop_receipt.JPG"),
        Image("ica_receipt.JPG"),
        Image("yeah.jpg"),
    ]


@pytest.fixture()
def items() -> List[Item]:
    return [
        Item("Äpple", 39, 0, 39, 0, 1),
        Item("Banan", 49, 0, 98, 0, 2),
        Item("Fil", 16, 90, 33, 80, 2),
        Item("Kikärter", 13, 0, 26, 0, 2),
        Item("Vetemjöl", 26, 0, 78, 0, 3),
        Item("Jäst", 3, 50, 3, 50, 1),
    ]


@pytest.fixture()
def transactions(items, images) -> List[Transaction]:
    return [
        Transaction(
            "Ica",
            [items[0], items[1], items[3]],
            datetime(2022, 6, 30),
            163,
            0,
            images[1]
        ), Transaction(
            "Coop",
            [items[2], items[3], items[4], items[5]],
            datetime(2022, 7, 1),
            141,
            30
        ), Transaction(
            "Willy's",
            [items[1], items[5]],
            datetime(2021, 12, 13),
            101,
            50,
            images[0]
        )
    ]


@pytest.fixture()
def users(transactions) -> List[User]:
    return [
        User(
            "test1",
            [transactions[0], transactions[2]]
        ),
        User(
            "test2",
            [transactions[1]]
        )
    ]


@pytest.fixture()
def users_to_post() -> List[User]:
    return [
        User("test3", []),
    ]


@pytest.fixture()
def images_to_post() -> List[Image]:
    return [
        Image("ica_receipt.JPG"),
        Image("yeah.jpg"),
    ]


@pytest.fixture()
def transactions_to_post(users, users_to_post, images_to_post) -> List[Tuple[User, Transaction]]:
    return [
        (users[1], Transaction(
            "Specsavers",
            Item("Glasögon", 1337, 50, 1337, 50, 1),
            datetime(2022, 2, 24),
            1337,
            50,
            images_to_post[0]
        )), (User("test3", []), Transaction(
            "Yes",
            Item("Dood", 1, 1, 1, 1, 1),
            datetime(1970, 1, 1),
            1,
            1,
            images_to_post[1]
        )),
    ]



@pytest.fixture(autouse=True)
def db(app, images, users, transactions_to_post):
    db = create_db(app)
    fs = GridFS(db)

    for user in users:

        for transaction in user.transactions:
            image = transaction.image
            if image is None:
                continue

            with open(f"./tests/res/{image.name}", "rb") as f:
                id = fs.put(f, filename=image.name, content_type=image.content_type)
                image.id = str(id)

        db.users.insert_one(user.to_dict())

    yield db

    for user in users:
        db.users.delete_many(user.to_dict())
        assert db.users.find_one({"bankId": user.bankId}) is None

        for transaction in user.transactions:
            image = transaction.image
            if image is not None:
                fs.delete(ObjectId(image.id))

                assert not fs.exists({"_id": ObjectId(image.id)})
                assert not fs.exists({"filename": image.name})


class TestTransactions():

    def compare_images_of(self, expected, actual):
        if "image" not in expected:
            assert "image" not in actual
            return

        expected_image = expected["image"]
        actual_image = actual["image"]
        print(expected_image)
        print(actual_image)

        assert expected_image["name"] == actual_image["name"]
        assert expected_image["_id"] == actual_image["_id"]

    def compare_items(self, expected, actual):
        for key in ["name", "price_kr", "price_ore", "sum_kr", "sum_ore", "quantity"]:
            assert expected[key] == actual[key]

    def compare_transactions(self, expected, actual):
        for key in ["recipient", "total_sum_kr", "total_sum_ore"]:
            assert expected[key] == actual[key]

        assert expected["date"] == parse(actual["date"])

        self.compare_images_of(expected, actual)

        for (expected_item, actual_item) in zip(expected["items"], actual["items"]):
            self.compare_items(expected_item, actual_item)

    def test_get_user_transactions(self, images, client, users):
        for user in users:
            response = client.get(f"/users/{user.bankId}/transactions")
            assert response.status == constants.ok

            response_transactions = loads(response.data)["data"]

            for (expected_transaction, actual_transaction) in zip(user.transactions, response_transactions):
                expected_transaction = expected_transaction.to_dict()
                self.compare_transactions(expected_transaction, actual_transaction)

    def test_post_user_transaction(self, transactions_to_post, client):
        for (user, transaction) in transactions_to_post:
            response = client.post(f"/users/{user.bankId}/transactions")
            assert response.status == constants.created
