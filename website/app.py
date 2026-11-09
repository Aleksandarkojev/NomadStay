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
    return render_template("accommodation.html")

@app.route("/booking/<int:id>")
def booking(id):
    return render_template("booking.html")

@app.route("/payment/<int:id>")
def payment(id):
    return render_template("payment.html")

@app.route("/profile")
def profile():
    return render_template("profile.html")

@app.route("/admin")
def admin():
    return render_template("admin.html")

if __name__ == "__main__":
    app.run(debug=True)
