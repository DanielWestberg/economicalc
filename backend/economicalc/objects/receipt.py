from datetime import datetime, timezone
from dateutil.parser import *
from typing import Optional, Dict, Any, List, Union

from bson.objectid import ObjectId

from .item import Item
from .type_check import check_type


class Receipt:
    def __init__(self, id: int, recipient: str, items: List[Item], date: datetime, total: float, category_id: int, image_id: Optional[ObjectId] = None) -> None:
        check_type(id, int, "receipt._id")
        check_type(recipient, str, "receipt.recipient")
        check_type(items, list, "receipt.items")
        check_type(date, datetime, "receipt.date")
        check_type(total, float, "receipt.total")
        check_type(category_id, int, "receipt.categoryID")
        check_type(image_id, [type(None), ObjectId], "receipt.imageId")

        self.id = id
        self.recipient = recipient
        self.items = items
        self.total = total
        self.category_id = category_id
        self.image_id = image_id

        self.date = datetime(date.year, date.month, date.day, tzinfo=timezone.utc)

    def __eq__(self, other: Any) -> bool:
        return (
            type(self) == type(other) and
            self.id == other.id and
            self.recipient == other.recipient and
            all([expected == actual for (expected, actual) in zip(self.items, other.items)]) and
            self.total == other.total and
            self.image_id == other.image_id and
            self.category_id == other.category_id and
            self.date == other.date
        )

    def to_dict(self, json_serializable=False) -> Dict[str, Any]:
        res = {
            "id": self.id,
            "recipient": self.recipient,
            "items": [item.to_dict() for item in self.items],
            "date": self.date,
            "total": self.total,
            "categoryID": self.category_id,
        }

        if self.image_id is not None:
            res["imageId"] = str(self.image_id) if json_serializable else self.image_id

        return res

    @staticmethod
    def from_dict(d: Dict[str, Any]):
        check_type(d, dict, "receipt")
        check_type(d["items"], list, "receipt.items")

        recipient = d["recipient"]
        items = [Item.from_dict(d_item) for d_item in d["items"]]
        date = parse(d["date"]) if type(d["date"]) == str else d["date"]
        total = d["total"]
        category_id = d["categoryID"]
        image_id = ObjectId(d["imageId"]) if "imageId" in d else None
        id = d["id"]

        return Receipt(id, recipient, items, date, total, category_id, image_id)

    @staticmethod
    def make_json_serializable(receipt_dict: Dict[str, Any]):
        if "imageId" in receipt_dict:
            receipt_dict["imageId"] = str(receipt_dict["imageId"])
