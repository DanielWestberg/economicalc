import os
from flask import Flask, request, jsonify
#from Objects import Receipt, Item, User
from flask_pymongo import PyMongo



application = Flask(__name__)

application.config["MONGO_URI"] = 'mongodb://' + os.environ['MONGODB_USERNAME'] + ':' + os.environ['MONGODB_PASSWORD'] + '@' + os.environ['MONGODB_HOSTNAME'] + ':27017/' + os.environ['MONGODB_DATABASE']

mongo = PyMongo(application)
db = mongo.db


class User:
    def __init__(self, id, receipts : list) -> None:
        self.id = id
        self.receipts = receipts
    
    def add_receipt(self):
        pass

    def delete_reciept(self):
        pass


class Receipt:
    def __init__(self, id : int, store : str, items : list, date_of_purchase : int, total_sum : float) -> None:
        self.id = id
        self.store = store
        self.items = items
        self.date = date_of_purchase
        self.total_sum = total_sum

class Item:
    def __init__(self, item_name : str, price : float) -> None:
        self.item_name = item_name
        self.price = price
        

@application.route('/')
def index():
    return jsonify(
        status=True,
        message='Welcome to the Dockerized Flask MongoDB app!'
    )


@application.route('/recipt', methods=["POST"])
def post_receipt():
    pass

@application.route('/recipt')
def fetch_recipts():
    user = db.users.find_one()

    
    print(user, flush=True)
    return jsonify(
        status=True,
        data=user['receipts']
    )
    

@application.route('/todo')
def todo():
    _todos = db.todo.find()

    item = {}
    data = []
    for todo in _todos:
        item = {
            'id': str(todo['_id']),
            'todo': todo['todo']
        }
        data.append(item)

    return jsonify(
        status=True,
        data=data
    )

@application.route('/todo', methods=['POST'])
def createTodo():
    data = request.get_json(force=True)
    item = {
        'todo': data['todo']
    }
    db.todo.insert_one(item)

    return jsonify(
        status=True,
        message='To-do saved successfully!'
    ), 201

if __name__ == "__main__":
    ENVIRONMENT_DEBUG = os.environ.get("APP_DEBUG", True)
    ENVIRONMENT_PORT = os.environ.get("APP_PORT", 5000)
    application.run(host='0.0.0.0', port=ENVIRONMENT_PORT, debug=ENVIRONMENT_DEBUG)