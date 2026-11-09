from flask import Flask

app = Flask(__name__)


@app.route("/")
def home():
    return "<h1>NomadStay</h1><p>Homepage coming soon.</p>"


@app.route("/search")
def search():
    return "<h1>Search Results</h1>"


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
