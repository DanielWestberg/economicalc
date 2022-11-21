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
