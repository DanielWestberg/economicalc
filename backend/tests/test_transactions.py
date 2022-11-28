import pytest

from datetime import datetime
from dateutil.parser import *
from typing import List, Optional, Tuple

from flask.json import load, dump
from bson.objectid import ObjectId
from gridfs import GridFS

import economicalc.constants as constants

from economicalc.objects import *
from economicalc.app import create_db


@pytest.fixture()
def images() -> List[Tuple[str, ObjectId]]:
    return [
        ("coop_receipt.JPG", ObjectId()),
        ("ica_receipt.JPG", ObjectId()),
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
            None,
            "Ica",
            [items[0], items[1], items[3]],
            datetime(2022, 6, 30),
            163,
            0,
            images[1][1]
        ), Transaction(
            None,
            "Coop",
            [items[2], items[3], items[4], items[5]],
            datetime(2022, 7, 1),
            141,
            30
        ), Transaction(
            None,
            "Willy's",
            [items[1], items[5]],
            datetime(2021, 12, 13),
            101,
            50,
            images[0][1]
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
def images_to_post() -> List[str]:
    return [
        "yeah.jpg",
    ]


@pytest.fixture()
def transactions_to_post(users, users_to_post, images_to_post) -> List[Tuple[User, Transaction, Optional[str]]]:
    return [
        (users[1], Transaction(
            None,
            "Specsavers",
            [Item("Glasögon", 1337, 50, 1337, 50, 1)],
            datetime(2022, 2, 24),
            1337,
            50
        ), None), (users_to_post[0], Transaction(
            None,
            "Yes",
            [Item("Dood", 1, 1, 1, 1, 1)],
            datetime(1970, 1, 1),
            1,
            1
        ), images_to_post[0]),
    ]


def clean_users(database, gridfs, user_list):
    for user in user_list:
        database.users.delete_many({"bankId": user.bankId})
        assert database.users.find_one({"bankId": user.bankId}) is None

        for transaction in user.transactions:
            image_id = transaction.image_id
            if image_id is not None:
                assert type(image_id) == ObjectId

                gridfs.delete(image_id)
                assert not gridfs.exists(image_id)
    


@pytest.fixture(autouse=True)
def db(app, images, users, transactions_to_post, users_to_post):
    db = create_db(app)
    fs = GridFS(db)

    for image in images:
        with open(f"./tests/res/{image[0]}", "rb") as f:
            assert fs.put(f, _id = image[1]) == image[1]

    for user in users:

        for transaction in user.transactions:
            if transaction.image_id is not None:
                assert fs.exists(transaction.image_id)

        db.users.insert_one(user.to_dict())

    yield db

    clean_users(db, fs, users)
    clean_users(db, fs, users_to_post)

    for image in images:
        assert not fs.exists(image[1])


class TestTransactions():

    def test_get_user_transactions(self, images, client, users):
        for user in users:
            response = client.get(f"/users/{user.bankId}/transactions")
            assert response.status == constants.ok

            response_transaction_dicts = response.json["data"]
            response_transactions = [Transaction.from_dict(d) for d in response_transaction_dicts]

            for (expected, actual) in zip(user.transactions, response_transactions):
                assert expected == actual


    def test_post_user_transaction(self, db, transactions_to_post, client):
        for (user, transaction, _) in transactions_to_post:
            transaction_dict = transaction.to_dict(True)
            response = client.post(f"/users/{user.bankId}/transactions", json=transaction_dict)
            assert response.status == constants.created

            response_dict = response.json["data"]
            response_transaction = Transaction.from_dict(response_dict)
            assert transaction == response_transaction

            user.transactions.append(transaction)

            response = client.get(f"/users/{user.bankId}/transactions")
            response_transaction_dicts = response.json["data"]
            response_transactions = [Transaction.from_dict(d) for d in response_transaction_dicts]
            assert transaction in response_transactions


    def post_errenous_transaction(self, transaction_dict, client):
        response = client.post("/users/not-a-user/transactions", json=transaction_dict)
        assert response.status == constants.unprocessable_entity


    def test_post_missing_field(self, db, transactions_to_post, client):
        transaction = transactions_to_post[0][1].to_dict(True)
        transaction.pop("items", None)
        self.post_errenous_transaction(transaction, client)

        transaction["items"] = []
        self.post_errenous_transaction(transaction, client)


    def test_post_weird_field(self, db, transactions_to_post, client):
        transaction = transactions_to_post[0][1]
        transaction_dict = transaction.to_dict(True)
        transaction_dict["items"] = {"a": "a"}
        self.post_errenous_transaction(transaction_dict, client)

        transaction_dict = transaction.to_dict(True)
        transaction_dict["recipient"] = 0
        self.post_errenous_transaction(transaction_dict, client)


    def test_post_weird_items(self, db, transactions_to_post, client):
        transaction = transactions_to_post[0][1]
        transaction_dict = transaction.to_dict(True)
        item_dict = transaction_dict["items"][0]
        item_dict["name"] = 0
        self.post_errenous_transaction(transaction_dict, client)

        item_dict["name"] = "lmao"
        item_dict["quantity"] = "lmao"
        self.post_errenous_transaction(transaction_dict, client)


    def test_get_image(self, db, users, client):
        for user in users:
            for transaction in user.transactions:
                response = client.get(f"/users/{user.bankId}/transactions/{transaction.id}/image")
                assert response.status == constants.ok

                response_transaction_dict = response.json["data"]
                response_transaction = Transaction.from_dict(response_transaction_dict)
                assert transaction == response_transaction
