class Item:
    def __init__(self, name: str, price: int, quantity: int) -> None:
        self.name = name
        self.price = price
        self.quantity = quantity

    def to_dict(self):
        return {
            "name": self.name,
            "price": self.price,
            "quantity": self.quantity,
        }
