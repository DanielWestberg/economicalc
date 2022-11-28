from datetime import datetime, timezone
from dateutil.parser import *
from typing import Optional, Dict, Any, List, Union

from bson.objectid import ObjectId

from .item import Item
from .type_check import check_type


class Transaction:
    def __init__(self, id: Optional[Union[str, ObjectId]], recipient: str, items: List[Item], date: datetime, total_sum_kr: int, total_sum_ore: int, image_id: Optional[ObjectId] = None) -> None:
        check_type(id, [type(None), str, ObjectId], "transaction._id")
        check_type(recipient, str, "transaction.recipient")
        check_type(items, list, "transaction.items")
        check_type(date, datetime, "transaction.date")
        check_type(total_sum_kr, int, "transaction.total_sum_kr")
        check_type(total_sum_ore, int, "transaction.total_sum_ore")
        check_type(image_id, [type(None), ObjectId], "transaction.image_id")

        self.id = ObjectId(id)
        self.recipient = recipient
        self.items = items
        self.total_sum_kr = total_sum_kr
        self.total_sum_ore = total_sum_ore
        self.image_id = image_id

        self.date = datetime(date.year, date.month, date.day, tzinfo=timezone.utc)

    def __eq__(self, other: Any) -> bool:
        return (
            type(self) == type(other) and
            self.id == other.id and
            self.recipient == other.recipient and
            all([expected == actual for (expected, actual) in zip(self.items, other.items)]) and
            self.total_sum_kr == other.total_sum_kr and
            self.total_sum_ore == other.total_sum_ore and
            self.image_id == other.image_id and
            self.date == other.date
        )

    def to_dict(self, json_serializable=False) -> Dict[str, Any]:
        res = {
            "recipient": self.recipient,
            "items": [item.to_dict() for item in self.items],
            "date": self.date,
            "total_sum_kr": self.total_sum_kr,
            "total_sum_ore": self.total_sum_ore
        }

        if self.image_id is not None:
            res["image_id"] = str(self.image_id) if json_serializable else self.image_id

        res["_id"] = str(self.id) if json_serializable else self.id

        return res

    @staticmethod
    def from_dict(d: Dict[str, Any]):
        check_type(d, dict, "transaction")
        check_type(d["items"], list, "transaction.items")

        recipient = d["recipient"]
        items = [Item.from_dict(d_item) for d_item in d["items"]]
        date = parse(d["date"]) if type(d["date"]) == str else d["date"]
        total_sum_kr = d["total_sum_kr"]
        total_sum_ore = d["total_sum_ore"]
        image_id = ObjectId(d["image_id"]) if "image_id" in d else None
        id = ObjectId(d["_id"]) if "_id" in d else None

        return Transaction(id, recipient, items, date, total_sum_kr, total_sum_ore, image_id)
