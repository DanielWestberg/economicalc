from datetime import datetime
from typing import Optional

from .image import Image


class Receipt:
    def __init__(self, id: int, store: str, items: list, date_of_purchase: datetime, total_sum: int, image: Optional[Image] = None) -> None:
        self.id = id
        self.store = store
        self.items = items
        self.date = date_of_purchase
        self.total_sum = total_sum
        self.image = image

    @staticmethod
    def from_mongo_doc(doc):
        return Receipt(doc["_id"], doc["store"], doc["items"].from_mongo_doc, doc["date_of_purchase"], doc["total_sum"], doc["image"])

    def to_dict(self):
        res = {
            "id": self.id,
            "store": self.store,
            "items": [item.to_dict() for item in self.items],
            "date": self.date,
            "total_sum": self.total_sum,
        }

        if self.image is not None:
            res["image"] = self.image.to_dict()

        return res

    @staticmethod
    def doc2dict(doc):
        return Receipt.from_mongo_doc(doc).to_dict()
