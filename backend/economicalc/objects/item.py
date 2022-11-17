class Item:
    def __init__(self, item_name: str, price: int) -> None:
        self.item_name = item_name
        self.price = price

    @staticmethod
    def from_mongo_doc(doc):
        return Item(doc["item_name"], doc["price"])

    def to_dict(self):
        return {
            "item_name": self.item_name,
            "receipts": self.receipts,
        }

    @staticmethod
    def doc2dict(doc):
        return Item.from_mongo_doc(doc).to_dict()
