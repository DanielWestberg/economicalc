class Item:
    def __init__(self, name: str, price_kr: int, price_ore: int, sum_kr: int, sum_ore: int, quantity: int) -> None:
        self.name = name
        self.price_kr = price_kr
        self.price_ore = price_ore
        self.sum_kr = sum_kr
        self.sum_ore = sum_ore
        self.quantity = quantity

    def to_dict(self):
        return {
            "name": self.name,
            "price_kr": self.price_kr,
            "price_ore": self.price_ore,
            "sum_kr": self.sum_kr,
            "sum_ore": self.sum_ore,
            "quantity": self.quantity,
        }
