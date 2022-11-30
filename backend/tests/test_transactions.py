import pytest

from datetime import datetime
from dateutil.parser import *
from typing import List, Optional, Tuple
from mimetypes import guess_type

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
def image_to_put() -> str:
    return "tsu.jpg"


@pytest.fixture()
def transactions_to_post(users, users_to_post) -> List[Tuple[User, Transaction]]:
    return [
        (users[1], Transaction(
            None,
            "Specsavers",
            [Item("Glasögon", 1337, 50, 1337, 50, 1)],
            datetime(2022, 2, 24),
            1337,
            50
        )), (users_to_post[0], Transaction(
            None,
            "Yes",
            [Item("Dood", 1, 1, 1, 1, 1)],
            datetime(1970, 1, 1),
            1,
            1
        ))
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
            assert fs.put(f, _id = image[1], content_type = guess_type(image[0])) == image[1]

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


@pytest.fixture()
def fs(db):
    yield GridFS(db)


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
        for (user, transaction) in transactions_to_post:
            transaction_dict = transaction.to_dict(True)
            transaction_dict.pop("_id", None)

            response = client.post(f"/users/{user.bankId}/transactions", json=transaction_dict)
            assert response.status == constants.created

            response_dict = response.json["data"]
            assert "_id" in response_dict

            transaction.id = ObjectId(response_dict["_id"])
            response_transaction = Transaction.from_dict(response_dict)
            assert transaction == response_transaction

            user.transactions.append(transaction)

            response = client.get(f"/users/{user.bankId}/transactions")
            response_transaction_dicts = response.json["data"]
            response_transactions = [Transaction.from_dict(d) for d in response_transaction_dicts]

            db_transaction_dicts = db.users.find_one({"bankId": user.bankId})["transactions"]
            db_transaction_ids = [d["_id"] for d in db_transaction_dicts]
            assert all([type(id) == ObjectId for id in db_transaction_ids])
            assert transaction.id in db_transaction_ids

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
        item_dict["itemName"] = 0
        self.post_errenous_transaction(transaction_dict, client)

        item_dict["itemName"] = "lmao"
        item_dict["amount"] = "lmao"
        self.post_errenous_transaction(transaction_dict, client)


    def test_put_all_transactions(self, db, users, client):
        for user in users:
            for transaction in user.transactions:
                transaction_dict = transaction.to_dict(True)
                for item in transaction_dict["items"]:
                    item["itemName"] = f"XMAS {item['itemName']}"

                transaction = Transaction.from_dict(transaction_dict)

                response = client.put(f"/users/{user.bankId}/transactions/{transaction.id}", json=transaction_dict)
                assert response.status == constants.ok
                assert response.content_type == "application/json"

                response_dict = response.json["data"]
                response_transaction = Transaction.from_dict(response_dict)
                assert transaction == response_transaction

                response = client.get(f"/users/{user.bankId}/transactions")
                response_dicts = response.json["data"]
                response_transactions = [Transaction.from_dict(d) for d in response_dicts]

                assert transaction in response_transactions


    def test_put_transaction_is_isolated(self, db, users, client):
        main_transaction = users[0].transactions[0]
        main_transaction.date = datetime(1970, 1, 1)
        response = client.put(f"/users/{users[0].bankId}/transactions/{main_transaction.id}", json=main_transaction.to_dict(True))
        assert response.status == constants.ok

        changed_count = 0
        for user in users:
            response = client.get(f"/users/{user.bankId}/transactions")
            response_dicts = response.json["data"]
            for response_dict in response_dicts:
                transaction = Transaction.from_dict(response_dict)
                transaction.date = datetime(transaction.date.year, transaction.date.month, transaction.date.day)
                if transaction.date == main_transaction.date:
                    changed_count += 1

        assert changed_count == 1


    def test_get_image(self, tmp_path, db, fs, users, client):
        tmp_file = tmp_path / "response_image"
        for user in users:
            for transaction in user.transactions:
                response = client.get(f"/users/{user.bankId}/transactions/{transaction.id}/image")
                if transaction.image_id is None:
                    assert response.status == constants.not_found
                    continue

                assert response.status == constants.ok
                assert response.is_streamed

                with tmp_file.open("wb") as f:
                    for data in response.response:
                        f.write(data)

                with tmp_file.open("rb") as f:
                    for (expected, actual) in zip(fs.find_one(transaction.image_id), f):
                        assert expected == actual


    def test_put_image(self, tmp_path, db, fs, users, image_to_put, client):
        filename = f"./tests/res/{image_to_put}"
        filetype = guess_type(filename)[0]
        tmp_file = tmp_path / "response_image"

        for user in users:
            for transaction in user.transactions:
                if transaction.image_id is not None:
                    continue

                with open(filename, "rb") as f:
                    response = client.put(f"/users/{user.bankId}/transactions/{transaction.id}/image", data = f, content_type = filetype)
                    assert response.status == constants.no_content

                    response = client.get(f"/users/{user.bankId}/transactions/{transaction.id}/image")
                    assert response.status == constants.ok

                    with tmp_file.open("wb") as eff:
                        for data in response.response:
                            eff.write(data)

                    f.seek(0)

                    with tmp_file.open("rb") as eff:
                        for (expected, actual) in zip(f, eff):
                            assert expected == actual


    def test_put_image_is_isolated(self, tmp_path, db, fs, users, image_to_put, client):
        filename = f"./tests/res/{image_to_put}"
        filetype = guess_type(filename)[0]
        tmp_file = tmp_path / "response_image"


        original_transaction = users[0].transactions[0]
        with open(filename, "rb") as f:
            client.put(f"/users/{users[0].bankId}/transactions/{original_transaction.id}/image", data = f, content_type = filetype)

        for user in users:
            for transaction in user.transactions:
                if transaction.id == original_transaction.id:
                    continue

                response = client.get(f"/users/{user.bankId}/transactions/{transaction.id}/image")
                if response.status == constants.not_found:
                    continue

                with tmp_file.open("wb") as f:
                    for data in response.response:
                        f.write(data)

                with tmp_file.open("rb") as received_file:
                    with open(filename, "rb") as original_file:
                        failed = True
                        for (expected, actual) in zip(received_file, original_file):
                            failed = failed and expected == actual
                            if failed:
                                break

                        assert not failed
