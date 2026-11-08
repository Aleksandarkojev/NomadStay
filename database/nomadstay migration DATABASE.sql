-- NomadStay v1 -> v2 migration (MySQL 8.0+)
-- Kor detta EFTER nomadstay_mysql.sql.
USE nomadstay;
SET NAMES utf8mb4;

-- 1. Beskriv resesallskapet mer detaljerat an endast antal_gaster.
CREATE TABLE IF NOT EXISTS bokning_resenar (
    bokning_resenar_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    bokning_id BIGINT UNSIGNED NOT NULL,
    fornamn VARCHAR(100) NOT NULL,
    efternamn VARCHAR(100) NOT NULL,
    resenarstyp ENUM('vuxen','barn','spadbarn') NOT NULL DEFAULT 'vuxen',
    fodelsedatum DATE NULL,
    huvudresenar BOOLEAN NOT NULL DEFAULT FALSE,
    specialbehov VARCHAR(500) NULL,
    CONSTRAINT fk_bokning_resenar_bokning FOREIGN KEY (bokning_id)
        REFERENCES bokning(bokning_id) ON DELETE CASCADE ON UPDATE CASCADE,
    INDEX idx_bokning_resenar_bokning (bokning_id)
) ENGINE=InnoDB;

-- 2. Komplexa sokval: avstand till strand, centrum, natur och kultur.
CREATE TABLE IF NOT EXISTS intressepunkt (
    intressepunkt_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    plats_id INT UNSIGNED NOT NULL,
    namn VARCHAR(150) NOT NULL,
    kategori ENUM('strand','centrum','natur','kultur','transport','coworking','restaurang','ovrigt') NOT NULL,
    latitud DECIMAL(9,6) NULL,
    longitud DECIMAL(9,6) NULL,
    beskrivning VARCHAR(500) NULL,
    CONSTRAINT fk_intressepunkt_plats FOREIGN KEY (plats_id)
        REFERENCES plats(plats_id) ON DELETE CASCADE ON UPDATE CASCADE,
    INDEX idx_intressepunkt_plats_kategori (plats_id, kategori)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS boende_intressepunkt (
    boende_id INT UNSIGNED NOT NULL,
    intressepunkt_id INT UNSIGNED NOT NULL,
    avstand_meter INT UNSIGNED NOT NULL,
    gangtid_minuter SMALLINT UNSIGNED NULL,
    PRIMARY KEY (boende_id, intressepunkt_id),
    CONSTRAINT fk_bip_boende FOREIGN KEY (boende_id)
        REFERENCES boende(boende_id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_bip_intressepunkt FOREIGN KEY (intressepunkt_id)
        REFERENCES intressepunkt(intressepunkt_id) ON DELETE CASCADE ON UPDATE CASCADE,
    INDEX idx_bip_avstand (boende_id, avstand_meter)
) ENGINE=InnoDB;

-- 3. Aktiviteter maste kunna bokas och bli fullbokade.
ALTER TABLE aktivitet
    ADD COLUMN plats_id INT UNSIGNED NULL AFTER aktivitet_id,
    ADD COLUMN starttid DATETIME NULL AFTER beskrivning,
    ADD COLUMN sluttid DATETIME NULL AFTER starttid,
    ADD COLUMN max_deltagare SMALLINT UNSIGNED NULL AFTER sluttid,
    ADD COLUMN pris_per_person DECIMAL(10,2) NOT NULL DEFAULT 0 AFTER max_deltagare,
    ADD COLUMN valuta CHAR(3) NOT NULL DEFAULT 'SEK' AFTER pris_per_person,
    ADD COLUMN status ENUM('planerad','oppen','fullbokad','installld','slutford') NOT NULL DEFAULT 'oppen' AFTER valuta,
    ADD CONSTRAINT fk_aktivitet_plats FOREIGN KEY (plats_id)
        REFERENCES plats(plats_id) ON DELETE SET NULL ON UPDATE CASCADE,
    ADD CONSTRAINT ck_aktivitet_tid CHECK (sluttid IS NULL OR starttid IS NULL OR sluttid > starttid),
    ADD CONSTRAINT ck_aktivitet_kapacitet CHECK (max_deltagare IS NULL OR max_deltagare > 0),
    ADD INDEX idx_aktivitet_tid_status (starttid, status);

CREATE TABLE IF NOT EXISTS aktivitetsbokning (
    aktivitetsbokning_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    aktivitet_id INT UNSIGNED NOT NULL,
    anvandare_id INT UNSIGNED NOT NULL,
    bokning_id BIGINT UNSIGNED NULL,
    antal_deltagare SMALLINT UNSIGNED NOT NULL DEFAULT 1,
    totalpris DECIMAL(10,2) NOT NULL DEFAULT 0,
    status ENUM('reserverad','bekraftad','avbokad','slutford') NOT NULL DEFAULT 'bekraftad',
    skapad_datum TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT ck_aktivitetsbokning_antal CHECK (antal_deltagare > 0),
    CONSTRAINT fk_aktivitetsbokning_aktivitet FOREIGN KEY (aktivitet_id)
        REFERENCES aktivitet(aktivitet_id) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_aktivitetsbokning_anvandare FOREIGN KEY (anvandare_id)
        REFERENCES anvandare(anvandare_id) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_aktivitetsbokning_bokning FOREIGN KEY (bokning_id)
        REFERENCES bokning(bokning_id) ON DELETE SET NULL ON UPDATE CASCADE,
    INDEX idx_aktivitetsbokning_kapacitet (aktivitet_id, status)
) ENGINE=InnoDB;

-- 4. Resplaner med delmal samt avgangs- och ankomsttider.
CREATE TABLE IF NOT EXISTS resplan (
    resplan_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    anvandare_id INT UNSIGNED NOT NULL,
    namn VARCHAR(150) NOT NULL,
    beskrivning TEXT NULL,
    startdatum DATE NOT NULL,
    slutdatum DATE NOT NULL,
    status ENUM('utkast','planerad','bokad','pagaende','slutford','avbokad') NOT NULL DEFAULT 'utkast',
    total_kostnad DECIMAL(12,2) NOT NULL DEFAULT 0,
    valuta CHAR(3) NOT NULL DEFAULT 'SEK',
    skapad_datum TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT ck_resplan_datum CHECK (slutdatum >= startdatum),
    CONSTRAINT fk_resplan_anvandare FOREIGN KEY (anvandare_id)
        REFERENCES anvandare(anvandare_id) ON DELETE CASCADE ON UPDATE CASCADE,
    INDEX idx_resplan_anvandare (anvandare_id, status)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS resplan_delmal (
    delmal_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    resplan_id BIGINT UNSIGNED NOT NULL,
    plats_id INT UNSIGNED NOT NULL,
    ordningsnummer SMALLINT UNSIGNED NOT NULL,
    namn VARCHAR(150) NOT NULL,
    ankomsttid DATETIME NULL,
    avgangstid DATETIME NULL,
    max_deltagare SMALLINT UNSIGNED NULL,
    beskrivning VARCHAR(1000) NULL,
    CONSTRAINT ck_delmal_tid CHECK (avgangstid IS NULL OR ankomsttid IS NULL OR avgangstid >= ankomsttid),
    CONSTRAINT ck_delmal_kapacitet CHECK (max_deltagare IS NULL OR max_deltagare > 0),
    CONSTRAINT fk_delmal_resplan FOREIGN KEY (resplan_id)
        REFERENCES resplan(resplan_id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_delmal_plats FOREIGN KEY (plats_id)
        REFERENCES plats(plats_id) ON DELETE RESTRICT ON UPDATE CASCADE,
    UNIQUE KEY uq_delmal_ordning (resplan_id, ordningsnummer)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS delmal_anmalan (
    delmal_id BIGINT UNSIGNED NOT NULL,
    anvandare_id INT UNSIGNED NOT NULL,
    antal_platser SMALLINT UNSIGNED NOT NULL DEFAULT 1,
    status ENUM('reserverad','bekraftad','avbokad') NOT NULL DEFAULT 'bekraftad',
    PRIMARY KEY (delmal_id, anvandare_id),
    CONSTRAINT ck_delmal_anmalan_antal CHECK (antal_platser > 0),
    CONSTRAINT fk_da_delmal FOREIGN KEY (delmal_id)
        REFERENCES resplan_delmal(delmal_id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_da_anvandare FOREIGN KEY (anvandare_id)
        REFERENCES anvandare(anvandare_id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS transportetapp (
    transportetapp_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    resplan_id BIGINT UNSIGNED NOT NULL,
    fran_plats_id INT UNSIGNED NOT NULL,
    till_plats_id INT UNSIGNED NOT NULL,
    transportsatt ENUM('flyg','tag','buss','bat','bil','cykel','gang','ovrigt') NOT NULL,
    operator_namn VARCHAR(150) NULL,
    referensnummer VARCHAR(100) NULL,
    avgangstid DATETIME NOT NULL,
    ankomsttid DATETIME NOT NULL,
    kostnad DECIMAL(10,2) NOT NULL DEFAULT 0,
    valuta CHAR(3) NOT NULL DEFAULT 'SEK',
    CONSTRAINT ck_transport_tid CHECK (ankomsttid > avgangstid),
    CONSTRAINT ck_transport_plats CHECK (fran_plats_id <> till_plats_id),
    CONSTRAINT fk_transport_resplan FOREIGN KEY (resplan_id)
        REFERENCES resplan(resplan_id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_transport_fran FOREIGN KEY (fran_plats_id)
        REFERENCES plats(plats_id) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_transport_till FOREIGN KEY (till_plats_id)
        REFERENCES plats(plats_id) ON DELETE RESTRICT ON UPDATE CASCADE,
    INDEX idx_transport_tid (avgangstid, ankomsttid)
) ENGINE=InnoDB;

-- 5. Kostnader per kategori ger detaljredovisning.
CREATE TABLE IF NOT EXISTS bokningskostnad (
    bokningskostnad_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    bokning_id BIGINT UNSIGNED NOT NULL,
    kategori ENUM('rum','aktivitet','transport','coworking','tillagg','rabatt','skatt','avgift') NOT NULL,
    beskrivning VARCHAR(255) NOT NULL,
    antal DECIMAL(10,2) NOT NULL DEFAULT 1,
    enhetspris DECIMAL(12,2) NOT NULL,
    belopp DECIMAL(12,2) GENERATED ALWAYS AS (antal * enhetspris) STORED,
    CONSTRAINT fk_bokningskostnad_bokning FOREIGN KEY (bokning_id)
        REFERENCES bokning(bokning_id) ON DELETE CASCADE ON UPDATE CASCADE,
    INDEX idx_bokningskostnad_bokning (bokning_id, kategori)
) ENGINE=InnoDB;

-- 6. Simulerad data for fullbokat/nastan fullbokat och komplexa sokningar.
INSERT INTO bokning_resenar (bokning_id, fornamn, efternamn, resenarstyp, huvudresenar) VALUES
(1,'Jonas','Adelsten','vuxen',TRUE),
(2,'Elin','Svensson','vuxen',TRUE),(2,'Mira','Svensson','barn',FALSE),
(3,'Amir','Hassan','vuxen',TRUE),(4,'Lisa','Berg','vuxen',TRUE),(5,'Noah','Lind','vuxen',TRUE),
(6,'Jonas','Adelsten','vuxen',TRUE),(6,'Alex','Adelsten','vuxen',FALSE);

INSERT INTO intressepunkt (plats_id, namn, kategori, latitud, longitud, beskrivning) VALUES
(1,'Praca do Comercio','centrum',38.707750,-9.136591,'Centralt torg'),
(1,'Castelo de Sao Jorge','kultur',38.713909,-9.133476,'Historiskt slott'),
(2,'Playa de la Barceloneta','strand',41.378371,2.192468,'Stadsstrand'),
(3,'Batu Bolong Beach','strand',-8.659556,115.130224,'Strand och surf'),
(4,'Karnan','kultur',56.048781,12.696952,'Historiskt landmarke'),
(4,'Helsingborg C','transport',56.044174,12.694072,'Centralstation'),
(5,'Volkspark Friedrichshain','natur',52.528004,13.437045,'Stadspark'),
(6,'Diocletianus palats','kultur',43.508133,16.440193,'Historiskt centrum');

INSERT INTO boende_intressepunkt (boende_id, intressepunkt_id, avstand_meter, gangtid_minuter) VALUES
(1,1,900,12),(1,2,450,6),(2,3,3200,42),(3,4,650,8),(4,5,500,7),(4,6,250,3),
(5,7,1100,15),(6,8,400,5),(7,1,700,9),(7,2,350,5),(8,5,600,8),(8,6,300,4);

UPDATE aktivitet SET plats_id=1,starttid='2026-11-05 10:00:00',sluttid='2026-11-05 12:00:00',max_deltagare=12,pris_per_person=180,status='oppen' WHERE aktivitet_id=1;
UPDATE aktivitet SET plats_id=3,starttid='2026-11-08 08:00:00',sluttid='2026-11-08 10:00:00',max_deltagare=6,pris_per_person=350,status='fullbokad' WHERE aktivitet_id=2;
UPDATE aktivitet SET plats_id=5,starttid='2026-11-12 18:00:00',sluttid='2026-11-12 20:00:00',max_deltagare=20,pris_per_person=0,status='oppen' WHERE aktivitet_id=3;
UPDATE aktivitet SET plats_id=3,starttid='2026-11-09 07:00:00',sluttid='2026-11-09 08:00:00',max_deltagare=10,pris_per_person=120,status='oppen' WHERE aktivitet_id=4;
UPDATE aktivitet SET plats_id=4,starttid='2026-11-18 13:00:00',sluttid='2026-11-18 16:00:00',max_deltagare=8,pris_per_person=450,status='oppen' WHERE aktivitet_id=5;

-- Aktivitet 2 ar fullbokad: 6 av 6 platser. Aktivitet 5 ar nastan fullbokad: 7 av 8.
INSERT INTO aktivitetsbokning (aktivitet_id, anvandare_id, bokning_id, antal_deltagare, totalpris, status) VALUES
(2,4,1,2,700,'bekraftad'),(2,5,2,2,700,'bekraftad'),(2,6,3,2,700,'bekraftad'),
(5,4,1,2,900,'bekraftad'),(5,5,2,2,900,'bekraftad'),(5,6,3,2,900,'bekraftad'),(5,7,4,1,450,'bekraftad');

INSERT INTO resplan (anvandare_id, namn, beskrivning, startdatum, slutdatum, status, total_kostnad) VALUES
(4,'Arbetsresa: Lissabon och Barcelona','Tva destinationer med boende, arbete och kultur.','2026-11-03','2026-11-17','bokad',12850.00);
INSERT INTO resplan_delmal (resplan_id, plats_id, ordningsnummer, namn, ankomsttid, avgangstid, max_deltagare, beskrivning) VALUES
(1,1,1,'Lissabon','2026-11-03 14:30:00','2026-11-10 08:00:00',10,'Boende och coworking i Alfama'),
(1,2,2,'Barcelona','2026-11-10 11:30:00','2026-11-17 16:00:00',10,'Arbetsvecka och kultur i Eixample');
INSERT INTO delmal_anmalan VALUES (1,4,1,'bekraftad'),(2,4,1,'bekraftad');
INSERT INTO transportetapp (resplan_id, fran_plats_id, till_plats_id, transportsatt, operator_namn, referensnummer, avgangstid, ankomsttid, kostnad) VALUES
(1,1,2,'flyg','TAP Air Portugal','NS-DEMO-TP1030','2026-11-10 09:15:00','2026-11-10 11:10:00',1250.00);

INSERT INTO bokningskostnad (bokning_id, kategori, beskrivning, antal, enhetspris) VALUES
(1,'rum','7 natter i privat enkelrum',7,690.00),(1,'rabatt','Veckorabatt 10 procent',1,-483.00),
(1,'coworking','Coworking 8 timmar',8,45.00),(2,'rum','7 natter i studio',7,1250.00),(2,'rabatt','Veckorabatt',1,-700.00);

-- 7. Vyer och queries som direkt motsvarar skallkraven.
CREATE OR REPLACE VIEW v_aktivitetskapacitet AS
SELECT a.aktivitet_id,a.namn,a.starttid,a.max_deltagare,
       COALESCE(SUM(CASE WHEN ab.status IN ('reserverad','bekraftad') THEN ab.antal_deltagare ELSE 0 END),0) AS bokade_platser,
       a.max_deltagare-COALESCE(SUM(CASE WHEN ab.status IN ('reserverad','bekraftad') THEN ab.antal_deltagare ELSE 0 END),0) AS lediga_platser,
       CASE
         WHEN a.max_deltagare IS NULL THEN 'obegransad'
         WHEN COALESCE(SUM(CASE WHEN ab.status IN ('reserverad','bekraftad') THEN ab.antal_deltagare ELSE 0 END),0) >= a.max_deltagare THEN 'fullbokad'
         WHEN COALESCE(SUM(CASE WHEN ab.status IN ('reserverad','bekraftad') THEN ab.antal_deltagare ELSE 0 END),0) >= a.max_deltagare*0.8 THEN 'nastan fullbokad'
         ELSE 'ledig'
       END AS kapacitetsstatus
FROM aktivitet a
LEFT JOIN aktivitetsbokning ab ON ab.aktivitet_id=a.aktivitet_id
GROUP BY a.aktivitet_id,a.namn,a.starttid,a.max_deltagare;

CREATE OR REPLACE VIEW v_bokningskostnad AS
SELECT b.bokning_id,b.anvandare_id,b.totalpris,b.valuta,
       COALESCE(SUM(bk.belopp),0) AS beraknad_detaljsumma
FROM bokning b
LEFT JOIN bokningskostnad bk ON bk.bokning_id=b.bokning_id
GROUP BY b.bokning_id,b.anvandare_id,b.totalpris,b.valuta;

CREATE OR REPLACE VIEW v_admin_bokningsdetalj AS
SELECT b.bokning_id,b.bokningsstatus,b.incheckning,b.utcheckning,b.antal_gaster,
       CONCAT(a.fornamn,' ',a.efternamn) AS kund,
       GROUP_CONCAT(DISTINCT bo.namn ORDER BY bo.namn SEPARATOR ', ') AS boenden,
       GROUP_CONCAT(DISTINCT r.rumsnummer ORDER BY r.rumsnummer SEPARATOR ', ') AS rum,
       b.totalpris,b.valuta
FROM bokning b
JOIN anvandare a ON a.anvandare_id=b.anvandare_id
LEFT JOIN bokning_rum br ON br.bokning_id=b.bokning_id
LEFT JOIN rum r ON r.rum_id=br.rum_id
LEFT JOIN boende bo ON bo.boende_id=r.boende_id
GROUP BY b.bokning_id,b.bokningsstatus,b.incheckning,b.utcheckning,b.antal_gaster,a.fornamn,a.efternamn,b.totalpris,b.valuta;

CREATE OR REPLACE VIEW v_resplan_tidslinje AS
SELECT rp.resplan_id,rp.namn AS resplan,rd.ordningsnummer,rd.namn AS delmal,
       p.stad,p.land,rd.ankomsttid,rd.avgangstid,rd.max_deltagare
FROM resplan rp
JOIN resplan_delmal rd ON rd.resplan_id=rp.resplan_id
JOIN plats p ON p.plats_id=rd.plats_id;

-- Exempel: komplex sokning och sortering efter pris.
-- SELECT DISTINCT v.*, bip.avstand_meter
-- FROM v_boendeoversikt v
-- JOIN boende_intressepunkt bip ON bip.boende_id=v.boende_id
-- JOIN intressepunkt ip ON ip.intressepunkt_id=bip.intressepunkt_id
-- WHERE ip.kategori='strand' AND bip.avstand_meter<=1000
--   AND v.wifi_hastighet_mbps>=100
-- ORDER BY v.lagsta_pris_per_natt ASC, v.snittbetyg DESC;

-- Exempel: fullbokade och nastan fullbokade aktiviteter.
-- SELECT * FROM v_aktivitetskapacitet
-- WHERE kapacitetsstatus IN ('fullbokad','nastan fullbokad');
