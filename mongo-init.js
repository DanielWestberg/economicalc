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

print("Inserting dummy data");
db.image.insertOne({
  name: "dummy.jpg",
  lastModified: Timestamp(),
});
print("Finished inserting dummy data");
