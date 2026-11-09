from flask import Flask, render_template, request
import pymysql

app = Flask(__name__)

DB_CONFIG = {
    "host": "localhost",
    "user": "nomadstay_user",
    "password": "NomadStay123!",
    "database": "nomadstay"
}


@app.route("/test-db")
def test_db():

    connection = pymysql.connect(**DB_CONFIG)

    cursor = connection.cursor()

    cursor.execute("SELECT COUNT(*) FROM boende")

    result = cursor.fetchone()

    connection.close()

    return f"Accommodations in database: {result[0]}"


@app.route("/")
def home():

    connection = pymysql.connect(**DB_CONFIG)

    cursor = connection.cursor()

    cursor.execute("""
        SELECT
            boende_id,
            namn,
            wifi_hastighet_mbps,
            avstand_coworking_meter,
            bild_filnamn
        FROM boende
        WHERE status = 'aktivt'
        ORDER BY namn
    """)

    accommodations = cursor.fetchall()

    connection.close()

    return render_template(
        "home.html",
        accommodations=accommodations
    )


@app.route("/search")
def search():

    wifi = request.args.get("wifi", 0)
    coworking = request.args.get("coworking", 99999)

    connection = pymysql.connect(**DB_CONFIG)

    cursor = connection.cursor()

    cursor.execute("""
      SELECT DISTINCT
    b.boende_id,
    b.namn,
    b.wifi_hastighet_mbps,
    b.avstand_coworking_meter,
    b.bild_filnamn,
    ROUND(AVG(r.betyg),1)
FROM boende b
LEFT JOIN recension r
    ON b.boende_id = r.boende_id
JOIN arbetsplats a
    ON b.boende_id = a.boende_id
WHERE b.status='aktivt'
  AND b.wifi_hastighet_mbps >= %s
  AND b.avstand_coworking_meter <= %s
  AND a.skrivbord = 1
GROUP BY
    b.boende_id,
    b.namn,
    b.wifi_hastighet_mbps,
    b.avstand_coworking_meter,
    b.bild_filnamn
ORDER BY b.wifi_hastighet_mbps DESC
    """, (wifi, coworking))

    accommodations = cursor.fetchall()

    connection.close()

    return render_template(
        "search.html",
        accommodations=accommodations,
        wifi=wifi,
        coworking=coworking
    )


@app.route("/accommodation/<int:id>")
def accommodation(id):

    connection = pymysql.connect(**DB_CONFIG)

    cursor = connection.cursor()

    cursor.execute("""
        SELECT
            namn,
            beskrivning,
            wifi_hastighet_mbps,
            avstand_coworking_meter,
            bild_filnamn
        FROM boende
        WHERE boende_id = %s
    """, (id,))

    accommodation = cursor.fetchone()

    cursor.execute("""
        SELECT
            f.namn
        FROM boendefacilitet bf
        JOIN facilitet f
            ON bf.facilitet_id = f.facilitet_id
        WHERE bf.boende_id = %s
    """, (id,))

    facilities = cursor.fetchall()

    cursor.execute("""
        SELECT
            betyg,
            kommentar
        FROM recension
        WHERE boende_id = %s
    """, (id,))

    reviews = cursor.fetchall()

    cursor.execute("""
        SELECT
            rum_id,
            rumstyp,
            pris_per_natt
        FROM rum
        WHERE boende_id = %s
    """, (id,))

    rooms = cursor.fetchall()

    cursor.execute("""
        SELECT
            namn,
            skrivbord,
            extern_skarm,
            ergonomisk_stol,
            antal_platser,
            pris_per_timme
        FROM arbetsplats
        WHERE boende_id = %s
    """, (id,))

    workspaces = cursor.fetchall()

    connection.close()

    return render_template(
        "accommodation.html",
        accommodation=accommodation,
        facilities=facilities,
        reviews=reviews,
        rooms=rooms,
        workspaces=workspaces
    )


@app.route("/booking/<int:id>")
def booking(id):

    connection = pymysql.connect(**DB_CONFIG)

    cursor = connection.cursor()

    cursor.execute("""
        SELECT
            rum_id,
            rumstyp,
            pris_per_natt
        FROM rum
        WHERE rum_id = %s
    """, (id,))

    room = cursor.fetchone()

    connection.close()

    return render_template(
        "booking.html",
        room=room
    )


@app.route("/payment/<int:id>")
def payment(id):

    connection = pymysql.connect(**DB_CONFIG)

    cursor = connection.cursor()

    cursor.execute("""
        SELECT
            rum_id,
            rumstyp,
            pris_per_natt
        FROM rum
        WHERE rum_id = %s
    """, (id,))

    room = cursor.fetchone()

    connection.close()

    return render_template(
        "payment.html",
        room=room
    )


@app.route("/profile")
def profile():
    return render_template("profile.html")


@app.route("/admin")
def admin():
    return render_template("admin.html")


if __name__ == "__main__":
    app.run(debug=True)