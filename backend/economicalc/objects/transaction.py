from datetime import datetime, timezone
from dateutil.parser import *
from typing import Optional, Dict, Any, List

from .image import Image
from .item import Item


class Transaction:
    def __init__(self, recipient: str, items: List[Item], date_of_purchase: datetime, total_sum_kr: int, total_sum_ore: int, image: Optional[Image] = None) -> None:
        if type(recipient) != str:
            raise TypeError("Field \"recipient\" must be a string")
        if type(items) != list:
            raise TypeError("Field \"items\" must be a list")
        if type(date_of_purchase) != datetime:
            raise TypeError("Field \"date\" must be a valid date")
        if type(total_sum_kr) != int:
            raise TypeError("Field \"total_sum_kr\" must be an integer")
        if type(total_sum_ore) != int:
            raise TypeError("Field \"total_sum_ore\" must be an integer")

        self.recipient = recipient
        self.items = items
        self.total_sum_kr = total_sum_kr
        self.total_sum_ore = total_sum_ore
        self.image = image

        date = date_of_purchase
        self.date = datetime(date.year, date.month, date.day, tzinfo=timezone.utc)

    def to_dict(self) -> Dict[str, Any]:
        res = {
            "recipient": self.recipient,
            "items": [item.to_dict() for item in self.items],
            "date": self.date,
            "total_sum_kr": self.total_sum_kr,
            "total_sum_ore": self.total_sum_ore
        }

        if self.image is not None:
            res["image"] = self.image.to_dict()

        return res

    @staticmethod
    def from_dict(d: Dict[str, Any]):
        recipient = d["recipient"]
        items = [Item.from_dict(d_item) for d_item in d["items"]]
        date = parse(d["date"]) if type(d["date"]) == str else d["date"]
        total_sum_kr = d["total_sum_kr"]
        total_sum_ore = d["total_sum_ore"]
        image = Image.from_dict(d["image"]) if "image" in d else None
        return Transaction(recipient, items, date, total_sum_kr, total_sum_ore, image)
