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
