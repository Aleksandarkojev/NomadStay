from flask import Flask, render_template

app = Flask(__name__)


@app.route("/")
def home():
    return render_template("home.html")


@app.route("/search")
def search():
    return render_template("search.html")


@app.route("/accommodation/<int:id>")
def accommodation(id):
    return f"<h1>Accommodation {id}</h1>"


@app.route("/booking/<int:id>")
def booking(id):
    return f"<h1>Booking {id}</h1>"


@app.route("/payment/<int:id>")
def payment(id):
    return f"<h1>Payment {id}</h1>"


@app.route("/profile")
def profile():
    return "<h1>User Profile</h1>"


@app.route("/admin")
def admin():
    return "<h1>Admin Dashboard</h1>"


if __name__ == "__main__":
    app.run(debug=True)
