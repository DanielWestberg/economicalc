
class Receipt:
    def __init__(self, id: int, store: str, items: list, date_of_purchase: int, total_sum: float) -> None:
        self.id = id
        self.store = store
        self.items = items
        self.date = date_of_purchase
        self.total_sum = total_sum
