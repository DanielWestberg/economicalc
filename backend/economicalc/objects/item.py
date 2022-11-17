class Item:
    def __init__(self, name: str, price: int, quantity: int) -> None:
        self.name = name
        self.price = price
        self.quantity = quantity

    @staticmethod
    def from_mongo_doc(doc):
        return Item(doc["name"], doc["price"], doc["quantity"])

    def to_dict(self):
        return {
            "name": self.name,
            "price": self.price,
            "quantity", self.quantity,
        }

    @staticmethod
    def doc2dict(doc):
        return Item.from_mongo_doc(doc).to_dict()
