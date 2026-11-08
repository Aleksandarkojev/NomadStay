-- NomadStay - MySQL 8.0+
-- Komplett databas med schema, relationer, index, vyer och simulerad data.
-- Genererad utifran ER-diagram, User Stories och BDD-scenarier.

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;
DROP DATABASE IF EXISTS nomadstay;
CREATE DATABASE nomadstay CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;
USE nomadstay;

-- ============================================================
-- GRUNDDATA OCH ANVANDARE
-- ============================================================
CREATE TABLE foretag (
    foretag_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    foretagsnamn VARCHAR(150) NOT NULL,
    organisationsnummer VARCHAR(30) NOT NULL UNIQUE,
    kontakt_epost VARCHAR(255),
    skapad_datum TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

CREATE TABLE anvandare (
    anvandare_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    foretag_id INT UNSIGNED NULL,
    epost VARCHAR(255) NOT NULL UNIQUE,
    losenord_hash VARCHAR(255) NOT NULL,
    fornamn VARCHAR(100) NOT NULL,
    efternamn VARCHAR(100) NOT NULL,
    telefon VARCHAR(30),
    roll ENUM('kund','admin','boendevard') NOT NULL DEFAULT 'kund',
    status ENUM('aktiv','blockerad','raderad') NOT NULL DEFAULT 'aktiv',
    registreringsdatum TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    senast_inloggad DATETIME NULL,
    CONSTRAINT fk_anvandare_foretag FOREIGN KEY (foretag_id)
        REFERENCES foretag(foretag_id) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB;

CREATE TABLE profil (
    profil_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    anvandare_id INT UNSIGNED NOT NULL UNIQUE,
    profilbild_url VARCHAR(500),
    telefonnummer VARCHAR(30),
    land VARCHAR(100),
    stad VARCHAR(100),
    sprak VARCHAR(10) NOT NULL DEFAULT 'sv',
    coworking_preferens BOOLEAN NOT NULL DEFAULT FALSE,
    min_wifi_mbps SMALLINT UNSIGNED NULL,
    ergonomisk_stol_preferens BOOLEAN NOT NULL DEFAULT FALSE,
    extern_skarm_preferens BOOLEAN NOT NULL DEFAULT FALSE,
    CONSTRAINT fk_profil_anvandare FOREIGN KEY (anvandare_id)
        REFERENCES anvandare(anvandare_id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

CREATE TABLE losenordsaterstallning (
    aterstallning_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    anvandare_id INT UNSIGNED NOT NULL,
    token_hash CHAR(64) NOT NULL UNIQUE,
    giltig_till DATETIME NOT NULL,
    anvand_datum DATETIME NULL,
    skapad_datum TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_aterstallning_anvandare FOREIGN KEY (anvandare_id)
        REFERENCES anvandare(anvandare_id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE avtal (
    avtal_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    foretag_id INT UNSIGNED NOT NULL,
    rabatt_procent DECIMAL(5,2) NOT NULL DEFAULT 0.00,
    startdatum DATE NOT NULL,
    slutdatum DATE NULL,
    status ENUM('utkast','aktivt','avslutat') NOT NULL DEFAULT 'aktivt',
    CONSTRAINT ck_avtal_rabatt CHECK (rabatt_procent BETWEEN 0 AND 100),
    CONSTRAINT ck_avtal_datum CHECK (slutdatum IS NULL OR slutdatum >= startdatum),
    CONSTRAINT fk_avtal_foretag FOREIGN KEY (foretag_id)
        REFERENCES foretag(foretag_id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- ============================================================
-- PLATSER OCH BOENDEN
-- ============================================================
CREATE TABLE plats (
    plats_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    land VARCHAR(100) NOT NULL,
    stad VARCHAR(100) NOT NULL,
    adress VARCHAR(255),
    postnummer VARCHAR(20),
    tidszon VARCHAR(64) NOT NULL,
    latitud DECIMAL(9,6),
    longitud DECIMAL(9,6),
    UNIQUE KEY uq_plats_adress (land, stad, adress)
) ENGINE=InnoDB;

CREATE TABLE boendetyp (
    boendetyp_id SMALLINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    namn VARCHAR(100) NOT NULL UNIQUE,
    beskrivning VARCHAR(500)
) ENGINE=InnoDB;

CREATE TABLE omrade (
    omrade_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    plats_id INT UNSIGNED NOT NULL,
    namn VARCHAR(150) NOT NULL,
    beskrivning TEXT,
    UNIQUE KEY uq_omrade (plats_id, namn),
    CONSTRAINT fk_omrade_plats FOREIGN KEY (plats_id)
        REFERENCES plats(plats_id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE boende (
    boende_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    admin_id INT UNSIGNED NOT NULL,
    boendetyp_id SMALLINT UNSIGNED NOT NULL,
    plats_id INT UNSIGNED NOT NULL,
    omrade_id INT UNSIGNED NULL,
    namn VARCHAR(150) NOT NULL,
    beskrivning TEXT NOT NULL,
    wifi_hastighet_mbps SMALLINT UNSIGNED,
    avstand_coworking_meter INT UNSIGNED,
    publicerad BOOLEAN NOT NULL DEFAULT FALSE,
    status ENUM('utkast','aktivt','avpublicerat','borttaget') NOT NULL DEFAULT 'utkast',
    skapad_datum TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    uppdaterad_datum TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_boende_admin FOREIGN KEY (admin_id)
        REFERENCES anvandare(anvandare_id) ON DELETE RESTRICT,
    CONSTRAINT fk_boende_typ FOREIGN KEY (boendetyp_id)
        REFERENCES boendetyp(boendetyp_id) ON DELETE RESTRICT,
    CONSTRAINT fk_boende_plats FOREIGN KEY (plats_id)
        REFERENCES plats(plats_id) ON DELETE RESTRICT,
    CONSTRAINT fk_boende_omrade FOREIGN KEY (omrade_id)
        REFERENCES omrade(omrade_id) ON DELETE SET NULL,
    INDEX idx_boende_sokning (plats_id, publicerad, status),
    INDEX idx_boende_wifi (wifi_hastighet_mbps)
) ENGINE=InnoDB;

CREATE TABLE rum (
    rum_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    boende_id INT UNSIGNED NOT NULL,
    rumsnummer VARCHAR(30) NOT NULL,
    rumstyp VARCHAR(100) NOT NULL,
    max_gaster TINYINT UNSIGNED NOT NULL,
    pris_per_natt DECIMAL(10,2) NOT NULL,
    valuta CHAR(3) NOT NULL DEFAULT 'SEK',
    tillganglig BOOLEAN NOT NULL DEFAULT TRUE,
    antal_sangar TINYINT UNSIGNED NOT NULL DEFAULT 1,
    CONSTRAINT ck_rum_gaster CHECK (max_gaster >= 1),
    CONSTRAINT ck_rum_pris CHECK (pris_per_natt >= 0),
    UNIQUE KEY uq_rum (boende_id, rumsnummer),
    CONSTRAINT fk_rum_boende FOREIGN KEY (boende_id)
        REFERENCES boende(boende_id) ON DELETE CASCADE,
    INDEX idx_rum_pris (pris_per_natt),
    INDEX idx_rum_tillganglig (boende_id, tillganglig)
) ENGINE=InnoDB;

CREATE TABLE bild (
    bild_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    boende_id INT UNSIGNED NOT NULL,
    bild_url VARCHAR(500) NOT NULL,
    bild_beskrivning VARCHAR(255),
    sorteringsordning SMALLINT UNSIGNED NOT NULL DEFAULT 0,
    ar_omslagsbild BOOLEAN NOT NULL DEFAULT FALSE,
    CONSTRAINT fk_bild_boende FOREIGN KEY (boende_id)
        REFERENCES boende(boende_id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE facilitet (
    facilitet_id SMALLINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    namn VARCHAR(100) NOT NULL UNIQUE,
    kategori VARCHAR(100)
) ENGINE=InnoDB;

CREATE TABLE boendefacilitet (
    boende_id INT UNSIGNED NOT NULL,
    facilitet_id SMALLINT UNSIGNED NOT NULL,
    PRIMARY KEY (boende_id, facilitet_id),
    CONSTRAINT fk_bf_boende FOREIGN KEY (boende_id)
        REFERENCES boende(boende_id) ON DELETE CASCADE,
    CONSTRAINT fk_bf_facilitet FOREIGN KEY (facilitet_id)
        REFERENCES facilitet(facilitet_id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE egenskap (
    egenskap_id SMALLINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    namn VARCHAR(100) NOT NULL UNIQUE
) ENGINE=InnoDB;

CREATE TABLE boendeegenskap (
    boende_id INT UNSIGNED NOT NULL,
    egenskap_id SMALLINT UNSIGNED NOT NULL,
    PRIMARY KEY (boende_id, egenskap_id),
    CONSTRAINT fk_be_boende FOREIGN KEY (boende_id)
        REFERENCES boende(boende_id) ON DELETE CASCADE,
    CONSTRAINT fk_be_egenskap FOREIGN KEY (egenskap_id)
        REFERENCES egenskap(egenskap_id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE boenderegel (
    regel_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    boende_id INT UNSIGNED NOT NULL,
    regeltext VARCHAR(500) NOT NULL,
    obligatorisk BOOLEAN NOT NULL DEFAULT TRUE,
    CONSTRAINT fk_regel_boende FOREIGN KEY (boende_id)
        REFERENCES boende(boende_id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE gemensamyta (
    gemensamyta_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    boende_id INT UNSIGNED NOT NULL,
    namn VARCHAR(100) NOT NULL,
    beskrivning VARCHAR(500),
    CONSTRAINT fk_gemensamyta_boende FOREIGN KEY (boende_id)
        REFERENCES boende(boende_id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE aktivitet (
    aktivitet_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    namn VARCHAR(150) NOT NULL,
    typ VARCHAR(100) NOT NULL,
    beskrivning TEXT
) ENGINE=InnoDB;

CREATE TABLE boendeaktivitet (
    boende_id INT UNSIGNED NOT NULL,
    aktivitet_id INT UNSIGNED NOT NULL,
    avstand_km DECIMAL(6,2),
    PRIMARY KEY (boende_id, aktivitet_id),
    CONSTRAINT fk_ba_boende FOREIGN KEY (boende_id)
        REFERENCES boende(boende_id) ON DELETE CASCADE,
    CONSTRAINT fk_ba_aktivitet FOREIGN KEY (aktivitet_id)
        REFERENCES aktivitet(aktivitet_id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- TILLAGG: arbetsplatser och separat bokning av coworking-plats
CREATE TABLE arbetsplats (
    arbetsplats_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    boende_id INT UNSIGNED NOT NULL,
    namn VARCHAR(100) NOT NULL,
    skrivbord BOOLEAN NOT NULL DEFAULT TRUE,
    extern_skarm BOOLEAN NOT NULL DEFAULT FALSE,
    ergonomisk_stol BOOLEAN NOT NULL DEFAULT FALSE,
    privat_rum BOOLEAN NOT NULL DEFAULT FALSE,
    antal_platser SMALLINT UNSIGNED NOT NULL DEFAULT 1,
    pris_per_timme DECIMAL(10,2) NOT NULL DEFAULT 0,
    CONSTRAINT ck_arbetsplats_antal CHECK (antal_platser >= 1),
    CONSTRAINT fk_arbetsplats_boende FOREIGN KEY (boende_id)
        REFERENCES boende(boende_id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE rabatt (
    rabatt_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    boende_id INT UNSIGNED NOT NULL,
    rabattyp ENUM('vecka','manad','kampanj') NOT NULL,
    procent DECIMAL(5,2) NOT NULL,
    minsta_antal_natter SMALLINT UNSIGNED NOT NULL,
    giltig_fran DATE NULL,
    giltig_till DATE NULL,
    CONSTRAINT ck_rabatt_procent CHECK (procent BETWEEN 0 AND 100),
    CONSTRAINT ck_rabatt_natter CHECK (minsta_antal_natter >= 1),
    CONSTRAINT fk_rabatt_boende FOREIGN KEY (boende_id)
        REFERENCES boende(boende_id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- TILLAGG: favoritlista fran User Stories/BDD
CREATE TABLE favorit (
    anvandare_id INT UNSIGNED NOT NULL,
    boende_id INT UNSIGNED NOT NULL,
    skapad_datum TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (anvandare_id, boende_id),
    CONSTRAINT fk_favorit_anvandare FOREIGN KEY (anvandare_id)
        REFERENCES anvandare(anvandare_id) ON DELETE CASCADE,
    CONSTRAINT fk_favorit_boende FOREIGN KEY (boende_id)
        REFERENCES boende(boende_id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- ============================================================
-- BOKNING, BETALNING, FAKTURA OCH RECENSION
-- ============================================================
CREATE TABLE bokning (
    bokning_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    anvandare_id INT UNSIGNED NOT NULL,
    incheckning DATE NOT NULL,
    utcheckning DATE NOT NULL,
    antal_gaster TINYINT UNSIGNED NOT NULL DEFAULT 1,
    sen_ankomst BOOLEAN NOT NULL DEFAULT FALSE,
    sen_utcheckning BOOLEAN NOT NULL DEFAULT FALSE,
    totalpris DECIMAL(12,2) NOT NULL,
    valuta CHAR(3) NOT NULL DEFAULT 'SEK',
    bokningsstatus ENUM('reserverad','bekraftad','incheckad','slutford','avbokad') NOT NULL DEFAULT 'reserverad',
    skapad_datum TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT ck_bokning_datum CHECK (utcheckning > incheckning),
    CONSTRAINT ck_bokning_gaster CHECK (antal_gaster >= 1),
    CONSTRAINT ck_bokning_pris CHECK (totalpris >= 0),
    CONSTRAINT fk_bokning_anvandare FOREIGN KEY (anvandare_id)
        REFERENCES anvandare(anvandare_id) ON DELETE RESTRICT,
    INDEX idx_bokning_datum (incheckning, utcheckning),
    INDEX idx_bokning_anvandare (anvandare_id, bokningsstatus)
) ENGINE=InnoDB;

CREATE TABLE bokning_rum (
    bokning_id BIGINT UNSIGNED NOT NULL,
    rum_id INT UNSIGNED NOT NULL,
    pris_per_natt DECIMAL(10,2) NOT NULL,
    PRIMARY KEY (bokning_id, rum_id),
    CONSTRAINT fk_br_bokning FOREIGN KEY (bokning_id)
        REFERENCES bokning(bokning_id) ON DELETE CASCADE,
    CONSTRAINT fk_br_rum FOREIGN KEY (rum_id)
        REFERENCES rum(rum_id) ON DELETE RESTRICT,
    INDEX idx_br_rum (rum_id)
) ENGINE=InnoDB;

CREATE TABLE arbetsplats_bokning (
    arbetsplats_bokning_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    anvandare_id INT UNSIGNED NOT NULL,
    arbetsplats_id INT UNSIGNED NOT NULL,
    bokning_id BIGINT UNSIGNED NULL,
    starttid DATETIME NOT NULL,
    sluttid DATETIME NOT NULL,
    antal_platser SMALLINT UNSIGNED NOT NULL DEFAULT 1,
    pris DECIMAL(10,2) NOT NULL DEFAULT 0,
    status ENUM('reserverad','bekraftad','slutford','avbokad') NOT NULL DEFAULT 'bekraftad',
    CONSTRAINT ck_ab_tid CHECK (sluttid > starttid),
    CONSTRAINT ck_ab_antal CHECK (antal_platser >= 1),
    CONSTRAINT fk_ab_anvandare FOREIGN KEY (anvandare_id)
        REFERENCES anvandare(anvandare_id) ON DELETE RESTRICT,
    CONSTRAINT fk_ab_arbetsplats FOREIGN KEY (arbetsplats_id)
        REFERENCES arbetsplats(arbetsplats_id) ON DELETE RESTRICT,
    CONSTRAINT fk_ab_bokning FOREIGN KEY (bokning_id)
        REFERENCES bokning(bokning_id) ON DELETE SET NULL,
    INDEX idx_ab_tid (arbetsplats_id, starttid, sluttid)
) ENGINE=InnoDB;

CREATE TABLE betalning (
    betalning_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    bokning_id BIGINT UNSIGNED NOT NULL,
    betalningsmetod ENUM('kort','swish','paypal','faktura') NOT NULL,
    betalningsstatus ENUM('vantande','godkand','misslyckad','aterbetald') NOT NULL DEFAULT 'vantande',
    betalningsdatum DATETIME NULL,
    belopp DECIMAL(12,2) NOT NULL,
    valuta CHAR(3) NOT NULL DEFAULT 'SEK',
    kvitto_url VARCHAR(500),
    transaktionsreferens VARCHAR(100) UNIQUE,
    CONSTRAINT ck_betalning_belopp CHECK (belopp >= 0),
    CONSTRAINT fk_betalning_bokning FOREIGN KEY (bokning_id)
        REFERENCES bokning(bokning_id) ON DELETE RESTRICT
) ENGINE=InnoDB;

CREATE TABLE faktura (
    faktura_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    foretag_id INT UNSIGNED NULL,
    bokning_id BIGINT UNSIGNED NOT NULL UNIQUE,
    fakturanummer VARCHAR(50) NOT NULL UNIQUE,
    belopp_exkl_moms DECIMAL(12,2) NOT NULL,
    moms DECIMAL(12,2) NOT NULL,
    totalbelopp DECIMAL(12,2) NOT NULL,
    status ENUM('utkast','skickad','betald','forfallen','makulerad') NOT NULL DEFAULT 'utkast',
    fakturadatum DATE NOT NULL,
    forfallodatum DATE NOT NULL,
    CONSTRAINT ck_faktura_datum CHECK (forfallodatum >= fakturadatum),
    CONSTRAINT fk_faktura_foretag FOREIGN KEY (foretag_id)
        REFERENCES foretag(foretag_id) ON DELETE SET NULL,
    CONSTRAINT fk_faktura_bokning FOREIGN KEY (bokning_id)
        REFERENCES bokning(bokning_id) ON DELETE RESTRICT
) ENGINE=InnoDB;

CREATE TABLE recension (
    recension_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    anvandare_id INT UNSIGNED NOT NULL,
    boende_id INT UNSIGNED NOT NULL,
    bokning_id BIGINT UNSIGNED NOT NULL UNIQUE,
    betyg TINYINT UNSIGNED NOT NULL,
    kommentar TEXT,
    recensionsdatum TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    publicerad BOOLEAN NOT NULL DEFAULT TRUE,
    CONSTRAINT ck_recension_betyg CHECK (betyg BETWEEN 1 AND 5),
    CONSTRAINT fk_recension_anvandare FOREIGN KEY (anvandare_id)
        REFERENCES anvandare(anvandare_id) ON DELETE RESTRICT,
    CONSTRAINT fk_recension_boende FOREIGN KEY (boende_id)
        REFERENCES boende(boende_id) ON DELETE CASCADE,
    CONSTRAINT fk_recension_bokning FOREIGN KEY (bokning_id)
        REFERENCES bokning(bokning_id) ON DELETE RESTRICT,
    INDEX idx_recension_boende (boende_id, publicerad)
) ENGINE=InnoDB;

-- Forhindrar dubbelbokning pa databassidan genom validering vid INSERT/UPDATE.
DELIMITER $$
CREATE TRIGGER trg_bokning_rum_ingen_overlapp_insert
BEFORE INSERT ON bokning_rum
FOR EACH ROW
BEGIN
    IF EXISTS (
        SELECT 1
        FROM bokning_rum br
        JOIN bokning befintlig ON befintlig.bokning_id = br.bokning_id
        JOIN bokning ny ON ny.bokning_id = NEW.bokning_id
        WHERE br.rum_id = NEW.rum_id
          AND befintlig.bokningsstatus IN ('reserverad','bekraftad','incheckad')
          AND ny.incheckning < befintlig.utcheckning
          AND ny.utcheckning > befintlig.incheckning
    ) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Rummet ar redan bokat under vald period';
    END IF;
END$$
DELIMITER ;

-- ============================================================
-- SIMULERAD DATA
-- ============================================================
INSERT INTO foretag (foretagsnamn, organisationsnummer, kontakt_epost) VALUES
('Nordic Remote AB','559100-1001','travel@nordicremote.example'),
('Cloudworks Sverige AB','559200-2002','finance@cloudworks.example');

INSERT INTO anvandare (foretag_id, epost, losenord_hash, fornamn, efternamn, telefon, roll, status, senast_inloggad) VALUES
(NULL,'admin@nomadstay.example','$2y$12$demoHashAdmin','Sara','Lind','0701000001','admin','aktiv','2026-10-21 09:15:00'),
(NULL,'vard1@nomadstay.example','$2y$12$demoHashHost1','Oliver','Berg','0701000002','boendevard','aktiv','2026-10-20 14:00:00'),
(NULL,'vard2@nomadstay.example','$2y$12$demoHashHost2','Maja','Ek','0701000003','boendevard','aktiv','2026-10-19 11:30:00'),
(1,'jonas.adelsten@example.com','$2y$12$demoHashJonas','Jonas','Adelsten','0702000001','kund','aktiv','2026-10-22 08:10:00'),
(1,'elin.svensson@example.com','$2y$12$demoHashElin','Elin','Svensson','0702000002','kund','aktiv','2026-10-18 18:45:00'),
(2,'amir.hassan@example.com','$2y$12$demoHashAmir','Amir','Hassan','0702000003','kund','aktiv','2026-10-17 13:20:00'),
(NULL,'lisa.berg@example.com','$2y$12$demoHashLisa','Lisa','Berg','0702000004','kund','aktiv',NULL),
(NULL,'noah.lind@example.com','$2y$12$demoHashNoah','Noah','Lind','0702000005','kund','aktiv','2026-10-15 10:00:00');

INSERT INTO profil (anvandare_id, profilbild_url, telefonnummer, land, stad, sprak, coworking_preferens, min_wifi_mbps, ergonomisk_stol_preferens, extern_skarm_preferens) VALUES
(4,'https://images.example/jonas.jpg','0702000001','Sverige','Helsingborg','sv',TRUE,100,TRUE,TRUE),
(5,'https://images.example/elin.jpg','0702000002','Sverige','Malmo','sv',TRUE,50,TRUE,FALSE),
(6,NULL,'0702000003','Sverige','Goteborg','sv',TRUE,200,FALSE,TRUE),
(7,NULL,'0702000004','Danmark','Kopenhamn','da',FALSE,25,FALSE,FALSE),
(8,NULL,'0702000005','Sverige','Stockholm','sv',TRUE,100,TRUE,FALSE);

INSERT INTO avtal (foretag_id, rabatt_procent, startdatum, slutdatum, status) VALUES
(1,12.00,'2026-01-01','2026-12-31','aktivt'),
(2,8.00,'2026-06-01',NULL,'aktivt');

INSERT INTO plats (land, stad, adress, postnummer, tidszon, latitud, longitud) VALUES
('Portugal','Lissabon','Rua do Sol 12','1100-001','Europe/Lisbon',38.722252,-9.139337),
('Spanien','Barcelona','Carrer de Mallorca 88','08029','Europe/Madrid',41.387397,2.168568),
('Indonesien','Canggu','Jalan Pantai Batu Bolong 45','80361','Asia/Makassar',-8.647817,115.138519),
('Sverige','Helsingborg','Drottninggatan 25','25221','Europe/Stockholm',56.046467,12.694512),
('Tyskland','Berlin','Warschauer Strasse 30','10243','Europe/Berlin',52.505000,13.449000),
('Kroatien','Split','Obala 15','21000','Europe/Zagreb',43.508133,16.440193);

INSERT INTO boendetyp (namn, beskrivning) VALUES
('Hotell','Serviceboende med reception och regelbunden stadning'),
('Lagenhet','Eget boende med kok och langre vistelser'),
('Co-living','Boende med privata rum och gemensamma sociala ytor'),
('Vandrarhem','Prisvart boende med delade eller privata rum');

INSERT INTO omrade (plats_id, namn, beskrivning) VALUES
(1,'Alfama','Historiskt omrade med restauranger och sparvagn'),
(2,'Eixample','Centralt rutnat med god kollektivtrafik'),
(3,'Batu Bolong','Nara strand, cafeer och coworking'),
(4,'Centrum','Gangavstand till station och hav'),
(5,'Friedrichshain','Kreativt omrade med cafeer och nattliv'),
(6,'Gamla stan','Nara promenadstrak och hamn');

INSERT INTO boende (admin_id, boendetyp_id, plats_id, omrade_id, namn, beskrivning, wifi_hastighet_mbps, avstand_coworking_meter, publicerad, status) VALUES
(2,3,1,1,'Nomad House Lisbon','Co-living med gemensamt kok, lounge och lugna arbetsytor.',300,150,TRUE,'aktivt'),
(2,2,2,2,'Eixample Work Apartments','Moderna lagenheter med eget kok och arbetsplats.',500,350,TRUE,'aktivt'),
(3,3,3,3,'Canggu Remote Village','Tropiskt co-living med coworking och pool.',250,0,TRUE,'aktivt'),
(3,1,4,4,'Oresund Business Hotel','Centralt hotell med frukost, reception och coworking-lounge.',1000,200,TRUE,'aktivt'),
(2,2,5,5,'Berlin Focus Studios','Tysta studios anpassade for langre arbetsvistelser.',400,500,TRUE,'aktivt'),
(3,4,6,6,'Split Social Hostel','Socialt vandrarhem med privata rum och gemensamt kok.',150,700,TRUE,'aktivt'),
(2,1,1,1,'Alfama Boutique Hotel','Mindre hotell med takterrass och frukost.',200,450,TRUE,'aktivt'),
(3,2,4,4,'Helsingborg Harbour Apartment','Lagenhet med havsutsikt, kok och stort skrivbord.',600,300,TRUE,'aktivt');

INSERT INTO rum (boende_id, rumsnummer, rumstyp, max_gaster, pris_per_natt, valuta, tillganglig, antal_sangar) VALUES
(1,'L101','Privat enkelrum',1,690,'SEK',TRUE,1),(1,'L102','Privat dubbelrum',2,890,'SEK',TRUE,1),(1,'L201','Studio',2,1090,'SEK',TRUE,1),
(2,'B11','Studio',2,1250,'SEK',TRUE,1),(2,'B12','Lagenhet med ett sovrum',3,1590,'SEK',TRUE,2),
(3,'C01','Garden room',2,720,'SEK',TRUE,1),(3,'C02','Pool room',2,860,'SEK',TRUE,1),(3,'C03','Deluxe studio',3,1120,'SEK',TRUE,2),
(4,'H301','Standard enkelrum',1,995,'SEK',TRUE,1),(4,'H302','Business dubbelrum',2,1395,'SEK',TRUE,1),
(5,'F1','Focus studio',1,980,'SEK',TRUE,1),(5,'F2','Premium studio',2,1280,'SEK',TRUE,1),
(6,'S10','Privat rum',2,640,'SEK',TRUE,1),(6,'S11','Fyrbaddsrum',4,920,'SEK',TRUE,4),
(7,'A1','Boutique dubbelrum',2,1450,'SEK',TRUE,1),(8,'HH1','Harbour apartment',3,1750,'SEK',TRUE,2);

INSERT INTO bild (boende_id, bild_url, bild_beskrivning, sorteringsordning, ar_omslagsbild) VALUES
(1,'https://images.example/nomad-lisbon-1.jpg','Lounge',1,TRUE),(1,'https://images.example/nomad-lisbon-2.jpg','Gemensamt kok',2,FALSE),
(2,'https://images.example/eixample-1.jpg','Studio med skrivbord',1,TRUE),(3,'https://images.example/canggu-1.jpg','Pool och coworking',1,TRUE),
(4,'https://images.example/oresund-1.jpg','Hotellrum',1,TRUE),(5,'https://images.example/berlin-1.jpg','Focus studio',1,TRUE),
(6,'https://images.example/split-1.jpg','Terrass',1,TRUE),(7,'https://images.example/alfama-1.jpg','Takterrass',1,TRUE),
(8,'https://images.example/harbour-1.jpg','Vardagsrum och arbetsbord',1,TRUE);

INSERT INTO facilitet (namn, kategori) VALUES
('Hoghastighets-WiFi','arbete'),('Skrivbord','arbete'),('Coworking-space','arbete'),('Extern skarm','arbete'),('Ergonomisk stol','arbete'),
('Kok','boende'),('Frukost','mat'),('Reception','service'),('Stadning','service'),('Pool','fritid'),('Tvattmaskin','boende'),('Luftkonditionering','boende');

INSERT INTO boendefacilitet VALUES
(1,1),(1,2),(1,3),(1,5),(1,6),(1,11),
(2,1),(2,2),(2,4),(2,5),(2,6),(2,11),(2,12),
(3,1),(3,2),(3,3),(3,4),(3,10),(3,12),
(4,1),(4,2),(4,3),(4,4),(4,5),(4,7),(4,8),(4,9),
(5,1),(5,2),(5,4),(5,5),(5,6),(5,11),
(6,1),(6,2),(6,6),(6,11),
(7,1),(7,2),(7,7),(7,8),(7,9),(7,12),
(8,1),(8,2),(8,4),(8,5),(8,6),(8,11);

INSERT INTO egenskap (namn) VALUES
('Tyst lage'),('Nara kollektivtrafik'),('Havsutsikt'),('Langtidsvanligt'),('Social miljo'),('Dygnet-runt-incheckning');
INSERT INTO boendeegenskap VALUES
(1,2),(1,4),(1,5),(2,1),(2,2),(2,4),(3,4),(3,5),(4,2),(4,6),(5,1),(5,2),(5,4),(6,3),(6,5),(7,2),(8,1),(8,2),(8,3),(8,4);

INSERT INTO boenderegel (boende_id, regeltext, obligatorisk) VALUES
(1,'Tystnad efter klockan 22:00',TRUE),(1,'Rokning ar inte tillaten',TRUE),(2,'Inga fester i lagenheten',TRUE),
(3,'Poolen ar oppen 07:00-22:00',TRUE),(4,'Legitimation visas vid incheckning',TRUE),(5,'Tyst arbetsmiljo 09:00-17:00',TRUE),
(6,'Gemensamt kok ska lamnas rent',TRUE),(7,'Rokfritt boende',TRUE),(8,'Inga husdjur',TRUE);

INSERT INTO gemensamyta (boende_id, namn, beskrivning) VALUES
(1,'Gemensamt kok','Fullt utrustat kok'),(1,'Lounge','Social yta med soffor'),(3,'Coworking-paviljong','Oppet arbetsrum vid poolen'),
(3,'Pool','Gemensam utomhuspool'),(4,'Business lounge','Arbetsyta for hotellgaster'),(6,'Takterrass','Gemensam terrass'),(6,'Gemensamt kok','Kok for gaster');

INSERT INTO aktivitet (namn, typ, beskrivning) VALUES
('Stadsvandring','kultur','Guidad vandring i gamla stan'),('Surflektion','sport','Lektion for nyborjare'),
('After work for nomader','socialt','Natverkstraff for distansarbetare'),('Yoga','halsa','Morgonpass'),('Kajaktur','sport','Guidad tur langs kusten');
INSERT INTO boendeaktivitet VALUES
(1,1,0.40),(1,3,0.10),(3,2,0.80),(3,4,0.00),(4,1,0.30),(5,3,0.60),(6,5,0.50),(7,1,0.20),(8,5,0.70);

INSERT INTO arbetsplats (boende_id, namn, skrivbord, extern_skarm, ergonomisk_stol, privat_rum, antal_platser, pris_per_timme) VALUES
(1,'Quiet Desk Zone',TRUE,TRUE,TRUE,FALSE,8,45),(1,'Call Booth',TRUE,TRUE,TRUE,TRUE,1,85),
(2,'Apartment Desk',TRUE,TRUE,TRUE,TRUE,1,0),(3,'Poolside Coworking',TRUE,TRUE,FALSE,FALSE,20,35),
(4,'Oresund Business Lounge',TRUE,TRUE,TRUE,FALSE,12,50),(4,'Meeting Room',TRUE,TRUE,TRUE,TRUE,6,160),
(5,'Focus Desk',TRUE,TRUE,TRUE,TRUE,1,0),(6,'Social Work Table',TRUE,FALSE,FALSE,FALSE,6,20),
(7,'Lobby Desk',TRUE,FALSE,TRUE,FALSE,4,30),(8,'Harbour Office',TRUE,TRUE,TRUE,TRUE,2,0);

INSERT INTO rabatt (boende_id, rabattyp, procent, minsta_antal_natter, giltig_fran, giltig_till) VALUES
(1,'vecka',10,7,NULL,NULL),(1,'manad',20,28,NULL,NULL),(2,'vecka',8,7,NULL,NULL),(2,'manad',18,28,NULL,NULL),
(3,'vecka',12,7,NULL,NULL),(3,'manad',25,28,NULL,NULL),(4,'vecka',7,7,NULL,NULL),(5,'manad',20,28,NULL,NULL),
(6,'vecka',10,7,NULL,NULL),(8,'manad',15,28,NULL,NULL);

INSERT INTO favorit (anvandare_id, boende_id) VALUES
(4,1),(4,3),(4,8),(5,2),(5,5),(6,3),(6,4),(7,7),(8,1),(8,5);

INSERT INTO bokning (anvandare_id, incheckning, utcheckning, antal_gaster, sen_ankomst, sen_utcheckning, totalpris, valuta, bokningsstatus, skapad_datum) VALUES
(4,'2026-11-03','2026-11-10',1,FALSE,TRUE,4347.00,'SEK','bekraftad','2026-10-10 10:00:00'),
(5,'2026-12-01','2026-12-08',2,TRUE,FALSE,8050.00,'SEK','bekraftad','2026-10-12 12:30:00'),
(6,'2026-09-10','2026-09-15',1,FALSE,FALSE,4480.00,'SEK','slutford','2026-08-20 09:00:00'),
(7,'2026-08-02','2026-08-05',2,FALSE,FALSE,4350.00,'SEK','slutford','2026-07-15 14:20:00'),
(8,'2026-11-15','2026-11-29',1,FALSE,FALSE,10976.00,'SEK','bekraftad','2026-10-15 16:40:00'),
(4,'2027-01-10','2027-01-17',2,FALSE,FALSE,10412.50,'SEK','reserverad','2026-10-21 08:10:00');

INSERT INTO bokning_rum VALUES
(1,1,690.00),(2,4,1250.00),(3,7,860.00),(4,15,1450.00),(5,11,980.00),(6,16,1750.00);

INSERT INTO arbetsplats_bokning (anvandare_id, arbetsplats_id, bokning_id, starttid, sluttid, antal_platser, pris, status) VALUES
(4,1,1,'2026-11-04 09:00:00','2026-11-04 17:00:00',1,360,'bekraftad'),
(5,3,2,'2026-12-02 09:00:00','2026-12-02 17:00:00',1,0,'bekraftad'),
(6,4,3,'2026-09-11 08:00:00','2026-09-11 16:00:00',1,280,'slutford'),
(8,7,5,'2026-11-16 08:30:00','2026-11-16 16:30:00',1,0,'bekraftad');

INSERT INTO betalning (bokning_id, betalningsmetod, betalningsstatus, betalningsdatum, belopp, valuta, kvitto_url, transaktionsreferens) VALUES
(1,'kort','godkand','2026-10-10 10:05:00',4347,'SEK','https://receipts.example/NS-1001.pdf','TX-NS-1001'),
(2,'faktura','godkand','2026-10-12 12:35:00',8050,'SEK','https://receipts.example/NS-1002.pdf','TX-NS-1002'),
(3,'paypal','godkand','2026-08-20 09:04:00',4480,'SEK','https://receipts.example/NS-1003.pdf','TX-NS-1003'),
(4,'kort','godkand','2026-07-15 14:25:00',4350,'SEK','https://receipts.example/NS-1004.pdf','TX-NS-1004'),
(5,'swish','godkand','2026-10-15 16:42:00',10976,'SEK','https://receipts.example/NS-1005.pdf','TX-NS-1005'),
(6,'kort','vantande',NULL,10412.50,'SEK',NULL,'TX-NS-1006');

INSERT INTO faktura (foretag_id, bokning_id, fakturanummer, belopp_exkl_moms, moms, totalbelopp, status, fakturadatum, forfallodatum) VALUES
(1,2,'NS-2026-0002',6440.00,1610.00,8050.00,'betald','2026-10-12','2026-11-11'),
(1,1,'NS-2026-0001',3477.60,869.40,4347.00,'betald','2026-10-10','2026-11-09');

INSERT INTO recension (anvandare_id, boende_id, bokning_id, betyg, kommentar, recensionsdatum, publicerad) VALUES
(6,3,3,5,'Mycket bra WiFi och smidig coworking.','2026-09-16 13:00:00',TRUE),
(7,7,4,4,'Bra lage och trevlig takterrass.','2026-08-06 10:30:00',TRUE);

-- ============================================================
-- VYER FOR VANLIGA NOMADSTAY-FUNKTIONER
-- ============================================================
CREATE OR REPLACE VIEW v_boendeoversikt AS
SELECT
    b.boende_id,
    b.namn,
    bt.namn AS boendetyp,
    p.land,
    p.stad,
    p.tidszon,
    b.wifi_hastighet_mbps,
    b.avstand_coworking_meter,
    MIN(r.pris_per_natt) AS lagsta_pris_per_natt,
    ROUND(AVG(rec.betyg), 1) AS snittbetyg,
    COUNT(DISTINCT rec.recension_id) AS antal_recensioner
FROM boende b
JOIN boendetyp bt ON bt.boendetyp_id = b.boendetyp_id
JOIN plats p ON p.plats_id = b.plats_id
JOIN rum r ON r.boende_id = b.boende_id
LEFT JOIN recension rec ON rec.boende_id = b.boende_id AND rec.publicerad = TRUE
WHERE b.publicerad = TRUE AND b.status = 'aktivt'
GROUP BY b.boende_id, b.namn, bt.namn, p.land, p.stad, p.tidszon,
         b.wifi_hastighet_mbps, b.avstand_coworking_meter;

CREATE OR REPLACE VIEW v_digital_nomad_boende AS
SELECT DISTINCT
    b.boende_id,
    b.namn,
    p.stad,
    p.land,
    p.tidszon,
    b.wifi_hastighet_mbps,
    b.avstand_coworking_meter,
    MAX(a.extern_skarm) AS extern_skarm,
    MAX(a.ergonomisk_stol) AS ergonomisk_stol,
    MAX(a.skrivbord) AS skrivbord
FROM boende b
JOIN plats p ON p.plats_id = b.plats_id
JOIN arbetsplats a ON a.boende_id = b.boende_id
WHERE b.publicerad = TRUE AND b.status = 'aktivt'
GROUP BY b.boende_id, b.namn, p.stad, p.land, p.tidszon,
         b.wifi_hastighet_mbps, b.avstand_coworking_meter;

-- Exempelfraga: lediga rum i Lissabon 2026-11-20 till 2026-11-27
-- SELECT r.*, b.namn
-- FROM rum r
-- JOIN boende b ON b.boende_id = r.boende_id
-- JOIN plats p ON p.plats_id = b.plats_id
-- WHERE p.stad = 'Lissabon' AND r.tillganglig = TRUE
--   AND NOT EXISTS (
--       SELECT 1 FROM bokning_rum br
--       JOIN bokning bo ON bo.bokning_id = br.bokning_id
--       WHERE br.rum_id = r.rum_id
--         AND bo.bokningsstatus IN ('reserverad','bekraftad','incheckad')
--         AND '2026-11-20' < bo.utcheckning
--         AND '2026-11-27' > bo.incheckning
--   );

SET FOREIGN_KEY_CHECKS = 1;
