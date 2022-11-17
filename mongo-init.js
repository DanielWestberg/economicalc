print("Creating users");

db.createUser({
  user: "flaskuser",
  pwd: "your_mongodb_password",
  roles: [{
    role: "readWrite",
    db: "flaskdb",
  }],
});

db.createUser({
  user: "test",
  pwd: "weak",
  roles: [{
    role: "readWrite",
    db: "testdb",
  }],
});

print("Finished creating users");

test_items = [
  {
    item_name: "gurka",
    price: 100
  },
  {
    item_name: "tomat",
    price: 50,
  }
]
test_receipt = [
  {
    id: 0,
    store: "Ica",
    items: test_items,
    date_of_purchase: 221115,
    total_sum: 150
  },
  {
    id: 1,
    store: "willys",
    items: test_items,
    date_of_purchase: 221115,
    total_sum: 150
  }
]

test_users = [
  {
    bankId: "hej",
    receipts: test_receipt
  },
  {
    bankId: "hej1",
    receipts: test_receipt
  }
]

db.users.insert(test_users)
