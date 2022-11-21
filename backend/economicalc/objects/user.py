class User:
    def __init__(self, bankId, receipts: list) -> None:
        self.bankId = bankId
        self.receipts = receipts

    def to_dict(self):
        return {
            "bankId": self.bankId,
            "receipts": [receipt.to_dict() for receipt in self.receipts],
        }
