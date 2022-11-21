class User:
    def __init__(self, bankId, transactions: list) -> None:
        self.bankId = bankId
        self.transactions = transactions

    def to_dict(self):
        return {
            "bankId": self.bankId,
            "transactions": [transaction.to_dict() for transaction in self.transactions],
        }
