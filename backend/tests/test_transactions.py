import pytest

from datetime import datetime
from dateutil.parser import *
from typing import List

from flask.json import loads

from .conftest import constants

from economicalc.objects import *
from economicalc.app import create_db


@pytest.fixture()
def images() -> List[Image]:
    return [
        Image("test.jpg"),
        Image("rofl.jpg"),
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


class TestTransactions():

    def compare_items(self, expected, actual):
        for key in ["name", "price_kr", "price_ore", "sum_kr", "sum_ore", "quantity"]:
            assert expected[key] == actual[key]

    def compare_transactions(self, expected, actual):
        for key in ["recipient", "total_sum_kr", "total_sum_ore"]:
            assert expected[key] == actual[key]

        assert expected["date"] == parse(actual["date"])

        if "image" not in expected:
            assert "image" not in actual
        else:
            expected_image = expected["image"]
            actual_image = actual["image"]
            assert expected_image["name"] == actual_image["name"]

        for (expected_item, actual_item) in zip(expected["items"], actual["items"]):
            self.compare_items(expected_item, actual_item)

    def test_get_user_transactions(self, images, client, users):
        for user in users:
            response = client.get(f"/users/{user.bankId}/transactions")
            assert response.status == constants["ok"]

            response_transactions = loads(response.data)["data"]

            for (expected_transaction, actual_transaction) in zip(user.transactions, response_transactions):
                expected_transaction = expected_transaction.to_dict()
                self.compare_transactions(expected_transaction, actual_transaction)
