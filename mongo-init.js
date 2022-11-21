print("Creating users");
db.createUser({
  user: "flaskuser",
  pwd: "your_mongodb_password",
  roles: [{
    role: "readWrite",
    db: "flaskdb",
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
  }
]

test_users = [
  {
    id: 0,
    receipts: test_receipt
  }
]




db.users.insertOne(test_users[0])