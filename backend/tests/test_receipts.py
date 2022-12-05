import pytest

from datetime import datetime
from dateutil.parser import *
from mimetypes import guess_type
from pathlib import Path
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
        Item("Äpple", 1.),
        Item("Banan", 2.),
        Item("Fil", 2.),
        Item("Kikärter", 2.),
        Item("Vetemjöl", 3.),
        Item("Jäst", 1.),
    ]


@pytest.fixture()
def receipts(items, images) -> List[Receipt]:
    return [
        Receipt(
            None,
            "Ica",
            [items[0], items[1], items[3]],
            datetime(2022, 6, 30),
            163.,
            1,
            images[1][1]
        ), Receipt(
            None,
            "Coop",
            [items[2], items[3], items[4], items[5]],
            datetime(2022, 7, 1),
            141.3,
            2,
        ), Receipt(
            None,
            "Willy's",
            [items[1], items[5]],
            datetime(2021, 12, 13),
            101.5,
            3,
            images[0][1]
        )
    ]


@pytest.fixture()
def categories() -> List[Category]:
    return [
        Category(
            1,
            "Groceries",
            0xEE6622,
        ), Category(
            2,
            "Clothes",
            0xBBCC33,
        ), Category(
            3,
            "Explosives",
            0x77FF33,
        ), Category(
            4,
            "Furniture",
            0x2288DD,
        ),
    ]


@pytest.fixture()
def users(receipts, categories) -> List[User]:
    return [
        User(
            "test1",
            [receipts[0], receipts[2]],
            [categories[0], categories[1]],
        ),
        User(
            "test2",
            [receipts[1]],
            [categories[2]],
        )
    ]


@pytest.fixture()
def users_to_post() -> List[User]:
    return [
        User("test3", [], []),
    ]


@pytest.fixture()
def image_to_put() -> Path:
    return Path(__file__).parent / "res" / "tsu.jpg"


@pytest.fixture()
def receipts_to_post(users, users_to_post) -> List[Tuple[User, Receipt]]:
    return [
        (users[1], Receipt(
            None,
            "Specsavers",
            [Item("Glasögon", 1.)],
            datetime(2022, 2, 24),
            1337.5,
            1,
        )), (users_to_post[0], Receipt(
            None,
            "Yes",
            [Item("Dood", 1.)],
            datetime(1970, 1, 1),
            1.1,
            5,
        ))
    ]


@pytest.fixture()
def categories_to_post() -> List[Category]:
    return [
        Category(
            7,
            "Entertainment",
            0xBB77BB,
        ), Category(
            8,
            "Investment",
            0xFF0000,
        )
    ]


def clean_users(database, gridfs, user_list):
    for user in user_list:
        database.users.delete_many({"bankId": user.bankId})
        assert database.users.find_one({"bankId": user.bankId}) is None

        for receipt in user.receipts:
            image_id = receipt.image_id
            if image_id is not None:
                assert type(image_id) == ObjectId

                gridfs.delete(image_id)
                assert not gridfs.exists(image_id)
    


@pytest.fixture(autouse=True)
def db(app, images, users, receipts_to_post, users_to_post):
    db = create_db(app)
    fs = GridFS(db)

    for image in images:
        with open(f"./tests/res/{image[0]}", "rb") as f:
            assert fs.put(f, _id = image[1], content_type = guess_type(image[0])) == image[1]

    for user in users:

        for receipt in user.receipts:
            if receipt.image_id is not None:
                assert fs.exists(receipt.image_id)

        db.users.insert_one(user.to_dict())

    yield db

    clean_users(db, fs, users)
    clean_users(db, fs, users_to_post)

    for image in images:
        assert not fs.exists(image[1])


@pytest.fixture()
def fs(db):
    yield GridFS(db)


class TestReceipt():

    def test_get_user_receipts(self, images, client, users):
        for user in users:
            response = client.get(f"/users/{user.bankId}/receipts")
            assert response.status == constants.ok

            response_receipt_dicts = response.json["data"]
            response_receipts = [Receipt.from_dict(d) for d in response_receipt_dicts]

            for (expected, actual) in zip(user.receipts, response_receipts):
                assert expected == actual


    def test_post_user_receipt(self, db, receipts_to_post, client):
        for (user, receipt) in receipts_to_post:
            receipt_dict = receipt.to_dict(True)
            receipt_dict.pop("_id", None)

            response = client.post(f"/users/{user.bankId}/receipts", json=receipt_dict)
            assert response.status == constants.created

            response_dict = response.json["data"]
            assert "_id" in response_dict

            receipt.id = ObjectId(response_dict["_id"])
            response_receipt = Receipt.from_dict(response_dict)
            assert receipt == response_receipt

            user.receipts.append(receipt)

            response = client.get(f"/users/{user.bankId}/receipts")
            response_receipt_dicts = response.json["data"]
            response_receipts = [Receipt.from_dict(d) for d in response_receipt_dicts]

            db_receipt_dicts = db.users.find_one({"bankId": user.bankId})["receipts"]
            db_receipt_ids = [d["_id"] for d in db_receipt_dicts]
            assert all([type(id) == ObjectId for id in db_receipt_ids])
            assert receipt.id in db_receipt_ids

            assert receipt in response_receipts


    def post_errenous_receipt(self, receipt_dict, client):
        response = client.post("/users/not-a-user/receipts", json=receipt_dict)
        assert response.status == constants.unprocessable_entity


    def test_post_missing_field(self, db, receipts_to_post, client):
        receipt = receipts_to_post[0][1].to_dict(True)
        receipt.pop("items", None)
        self.post_errenous_receipt(receipt, client)

        receipt["items"] = []
        self.post_errenous_receipt(receipt, client)


    def test_post_weird_field(self, db, receipts_to_post, client):
        receipt = receipts_to_post[0][1]
        receipt_dict = receipt.to_dict(True)
        receipt_dict["items"] = {"a": "a"}
        self.post_errenous_receipt(receipt_dict, client)

        receipt_dict = receipt.to_dict(True)
        receipt_dict["recipient"] = 0
        self.post_errenous_receipt(receipt_dict, client)


    def test_post_weird_items(self, db, receipts_to_post, client):
        receipt = receipts_to_post[0][1]
        receipt_dict = receipt.to_dict(True)
        item_dict = receipt_dict["items"][0]
        item_dict["itemName"] = 0
        self.post_errenous_receipt(receipt_dict, client)

        item_dict["itemName"] = "lmao"
        item_dict["amount"] = "lmao"
        self.post_errenous_receipt(receipt_dict, client)


    def test_put_all_receipts(self, db, users, client):
        for user in users:
            for receipt in user.receipts:
                receipt_dict = receipt.to_dict(True)
                for item in receipt_dict["items"]:
                    item["itemName"] = f"XMAS {item['itemName']}"

                receipt = Receipt.from_dict(receipt_dict)

                response = client.put(f"/users/{user.bankId}/receipts/{receipt.id}", json=receipt_dict)
                assert response.status == constants.ok
                assert response.content_type == "application/json"

                response_dict = response.json["data"]
                response_receipt = Receipt.from_dict(response_dict)
                assert receipt == response_receipt

                response = client.get(f"/users/{user.bankId}/receipts")
                response_dicts = response.json["data"]
                response_receipts = [Receipt.from_dict(d) for d in response_dicts]

                assert receipt in response_receipts


    def test_put_receipt_is_isolated(self, db, users, client):
        main_receipt = users[0].receipts[0]
        main_receipt.date = datetime(1970, 1, 1)
        response = client.put(f"/users/{users[0].bankId}/receipts/{main_receipt.id}", json=main_receipt.to_dict(True))
        assert response.status == constants.ok

        changed_count = 0
        for user in users:
            response = client.get(f"/users/{user.bankId}/receipts")
            response_dicts = response.json["data"]
            for response_dict in response_dicts:
                receipt = Receipt.from_dict(response_dict)
                receipt.date = datetime(receipt.date.year, receipt.date.month, receipt.date.day)
                if receipt.date == main_receipt.date:
                    changed_count += 1

        assert changed_count == 1


    def test_get_image(self, tmp_path, db, fs, users, client):
        tmp_file = tmp_path / "response_image"
        for user in users:
            for receipt in user.receipts:
                response = client.get(f"/users/{user.bankId}/receipts/{receipt.id}/image")
                if receipt.image_id is None:
                    assert response.status == constants.not_found
                    continue

                assert response.status == constants.ok

                with tmp_file.open("wb") as f:
                    for data in response.response:
                        f.write(data)

                with tmp_file.open("rb") as f:
                    for (expected, actual) in zip(fs.find_one(receipt.image_id), f):
                        assert expected == actual


    def test_put_image(self, tmp_path, db, fs, users, image_to_put, client):
        filetype = guess_type(str(image_to_put))[0]
        tmp_file = tmp_path / "response_image"

        for user in users:
            for receipt in user.receipts:
                if receipt.image_id is not None:
                    continue

                response = client.put(f"/users/{user.bankId}/receipts/{receipt.id}/image", data = {"file": image_to_put.open("rb")})
                assert response.status == constants.no_content

                response = client.get(f"/users/{user.bankId}/receipts/{receipt.id}/image")
                assert response.status == constants.ok

                with tmp_file.open("wb") as f:
                    for data in response.response:
                        f.write(data)

                for (expected, actual) in zip(image_to_put.open("rb"), tmp_file.open("rb")):
                    assert expected == actual


    def test_put_image_is_isolated(self, tmp_path, db, fs, users, image_to_put, client):
        filetype = guess_type(str(image_to_put))[0]
        tmp_file = tmp_path / "response_image"

        original_receipt = users[0].receipts[0]
        client.put(f"/users/{users[0].bankId}/receipts/{original_receipt.id}/image", data = {"file": image_to_put.open("rb")})

        for user in users:
            for receipt in user.receipts:
                if receipt.id == original_receipt.id:
                    continue

                response = client.get(f"/users/{user.bankId}/receipts/{receipt.id}/image")
                if response.status == constants.not_found:
                    continue

                with tmp_file.open("wb") as f:
                    for data in response.response:
                        f.write(data)

                failed = True
                for (expected, actual) in zip(tmp_file.open("rb"), image_to_put.open("rb")):
                    failed = failed and expected == actual
                    if failed:
                        break

                assert not failed


    def test_get_categories(self, db, users, client):
        for user in users:
            response = client.get(f"/users/{user.bankId}/categories")
            assert response.status == constants.ok

            response_dicts = response.json["data"]
            response_categories = [Category.from_dict(d) for d in response_dicts]

            for (expected, actual) in zip(user.categories, response_categories):
                assert expected == actual


    def test_post_category(self, db, users, categories_to_post, client):
        user = users[0]
        for category in categories_to_post:
            response = client.post(f"/users/{user.bankId}/categories", json=category.to_dict(True))
            assert response.status == constants.created

            response_dict = response.json["data"]
            response_category = Category.from_dict(response_dict)
            assert category == response_category

            response = client.get(f"/users/{user.bankId}/categories")
            response_dicts = response.json["data"]
            response_categories = [Category.from_dict(d) for d in response_dicts]
            assert category in response_categories


    def test_post_existing_category_fails(self, db, users, client):
        user = users[0]
        category = user.categories[0]

        response = client.post(f"/users/{user.bankId}/categories", json=category.to_dict(True))
        assert response.status == constants.conflict

        response = client.get(f"/users/{user.bankId}/categories")
        response_dicts = response.json["data"]
        assert len(response_dicts) == len(user.categories)


    def test_put_category(self, db, users, client):
        for user in users:
            for category in user.categories:
                category.color = 0
                category_dict = category.to_dict(True)

                response = client.put(f"/users/{user.bankId}/categories/{category.id}", json=category_dict)
                assert response.status == constants.ok
                
                response_dict = response.json["data"]
                response_category = Category.from_dict(response_dict)
                assert category == response_category
                
                response = client.get(f"/users/{user.bankId}/categories")
                response_dicts = response.json["data"]
                response_categories = [Category.from_dict(d) for d in response_dicts]

                assert category in response_categories


    def test_put_new_category(self, db, users, categories_to_post, client):
        user = users[0]
        for category in categories_to_post:
            response = client.put(f"/users/{user.bankId}/categories/{category.id}", json=category.to_dict(True))
            assert response.status == constants.created

            response_dict = response.json["data"]
            response_category = Category.from_dict(response_dict)
            assert category == response_category

            response = client.get(f"/users/{user.bankId}/categories")
            response_dicts = response.json["data"]
            response_categories = [Category.from_dict(d) for d in response_dicts]
            assert category in response_categories


    def test_delete_category(self, db, users, client):
        for user in users:
            while len(user.categories) > 0:
                category = user.categories.pop()
                response = client.delete(f"/users/{user.bankId}/categories/{category.id}")
                assert response.status == constants.no_content

                response = client.get(f"/users/{user.bankId}/categories")
                response_dicts = response.json["data"]
                response_categories = [Category.from_dict(d) for d in response_dicts]
                assert category not in response_categories

                for category in user.categories:
                    assert category in response_categories


    def test_delete_inexistent_category(self, db, users, categories_to_post, client):
        user = users[0]
        category = categories_to_post[0]
        response = client.delete(f"/users/{user.bankId}/categories/{category.id}")
        assert response.status == constants.no_content

        response = client.get(f"/users/{user.bankId}/categories")
        response_dicts = response.json["data"]
        response_categories = [Category.from_dict(d) for d in response_dicts]
        for category in user.categories:
            assert category in response_categories
