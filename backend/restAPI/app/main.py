# main.py

from flask import Flask

app = Flask(__name__)

@app.route("/")

def hello_world():
    return "Hello, World from flask adsadsa"

if __name__ == "__main__":
    #only for debugging
    app.run(host="0.0.0.0", debug=True, port=80)
