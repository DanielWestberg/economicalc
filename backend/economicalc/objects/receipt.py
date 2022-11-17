from datetime import date


class Receipt:
    def __init__(self, id: int, store: str, items: list, date_of_purchase: date, total_sum: float) -> None:
        self.id = id
        self.store = store
        self.items = items
        self.date = date_of_purchase
        self.total_sum = total_sum

    @staticmethod
    def from_mongo_doc(doc):
        return Receipt(doc["_id"], doc["store"], doc["items"].from_mongo_doc, doc["date_of_purchase"], doc["total_sum"])

    def to_dict(self):
        return {
            "id": self.id,
            "store": self.store,
            "items": self.items.to_dict(),
            "date": self.date,
            "total_sum": self.total_sum,
        }

    @staticmethod
    def doc2dict(doc):
        return Receipt.from_mongo_doc(doc).to_dict()
