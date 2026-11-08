SELECT *
FROM v_digital_nomad_boende
ORDER BY wifi_hastighet_mbps DESC;

SELECT
    r.rum_id,
    r.rumstyp,
    r.pris_per_natt
FROM rum r
WHERE NOT EXISTS (
    SELECT 1
    FROM bokning_rum br
    JOIN bokning b ON b.bokning_id = br.bokning_id
    WHERE br.rum_id = r.rum_id
      AND b.bokningsstatus IN ('reserverad','bekraftad')
);

SELECT
    namn,
    stad,
    land,
    wifi_hastighet_mbps,
    avstand_coworking_meter,
    lagsta_pris_per_natt
FROM v_boendeoversikt
WHERE wifi_hastighet_mbps >= 100
ORDER BY wifi_hastighet_mbps DESC,
         avstand_coworking_meter ASC;
         
         SELECT
    b.namn,
    bt.namn AS boendetyp,
    p.stad,
    p.land,
    b.beskrivning,
    b.wifi_hastighet_mbps,
    b.avstand_coworking_meter
FROM boende b
JOIN boendetyp bt ON bt.boendetyp_id = b.boendetyp_id
JOIN plats p ON p.plats_id = b.plats_id
WHERE b.boende_id = 1;

-- SKALLKRAV

-- Autentisering (Konto/inloggning eller liknande)

SELECT
    anvandare_id,
    epost,
    roll
FROM anvandare;

-- Beskriva sällskapet för sökning / bokning

SELECT *
FROM bokning_resenar;

-- Söka efter lediga boenden på olika orter med specificerade sökkriterier  ***

SELECT
    b.namn,
    p.stad,
    r.rumstyp,
    r.pris_per_natt
FROM boende b
JOIN plats p ON p.plats_id = b.plats_id
JOIN rum r ON r.boende_id = b.boende_id
WHERE r.tillganglig = TRUE;

-- Boenden måste kunna bli fullbokade. **************

SELECT
    b.namn,
    COUNT(DISTINCT r.rum_id) AS antal_rum,
    COUNT(DISTINCT br.rum_id) AS bokade_rum
FROM boende b
JOIN rum r ON r.boende_id = b.boende_id
LEFT JOIN bokning_rum br ON br.rum_id = r.rum_id
GROUP BY b.boende_id;

-- Skapa och hantera bokningar med ett eller flera rum.

SELECT *
FROM bokning_rum;

-- Göra enkla sökval om sådant som man önskar vid boendet

SELECT *
FROM v_digital_nomad_boende;

-- Göra komplexa sökval, t ex avstånd till strand, centrum, natur, kultur,------ 7

-- Vilka boenden ligger nära stranden?

SELECT
b.namn,
ip.namn AS intressepunkt,
bip.avstand_meter
FROM boende b
JOIN boende_intressepunkt bip
ON bip.boende_id = b.boende_id
JOIN intressepunkt ip
ON ip.intressepunkt_id = bip.intressepunkt_id
WHERE ip.kategori = 'strand'
ORDER BY bip.avstand_meter ASC;

SELECT *
FROM intressepunkt;

-- Sortera sökresultat

SELECT *
FROM v_boendeoversikt
ORDER BY lagsta_pris_per_natt;

-- Utöver vanliga resenärer behöver också systemet hantera
-- administratör eller motsvarande

SELECT *
FROM anvandare
WHERE roll='admin';

-- Systemet måste ge tillräcklig information om varje typ av resa och 
-- boendealternativ så att resenärer tydligt kan förstå vad de bokar.

SELECT
    b.namn,
    bt.namn AS boendetyp,
    p.stad,
    p.land,
    b.beskrivning,
    b.wifi_hastighet_mbps,
    b.avstand_coworking_meter
FROM boende b
JOIN boendetyp bt
    ON bt.boendetyp_id = b.boendetyp_id
JOIN plats p
    ON p.plats_id = b.plats_id;

-- Användare måste kunna se listor (med mer kortfattad information)
-- såväl som enskilda bokningsalternativ (med detaljerad information).

SELECT *
FROM v_boendeoversikt;

-- detajl

SELECT
    b.namn,
    b.beskrivning
FROM boende b
WHERE b.boende_id = 1;

-- Administratörer måste kunna se användare, boenden, aktiviteter och resor både som listor och i detalj.   ****

SELECT
    (SELECT COUNT(*) FROM anvandare) AS antal_anvandare,
    (SELECT COUNT(*) FROM boende
        WHERE publicerad = TRUE) AS antal_boenden,
    (SELECT COUNT(*) FROM aktivitet) AS antal_aktiviteter,
    (SELECT COUNT(*) FROM resplan) AS antal_resor,
    (SELECT COUNT(*) FROM bokning
        WHERE bokningsstatus = 'bekraftad') AS bekraftade_bokningar;

 -- Möjlighet att planera resor med specifika avgångstider och ankomsttider.
 
 SELECT
    resplan_id,
    fran_plats_id,
    till_plats_id,
    avgangstid,
    ankomsttid
FROM transportetapp;

-- Redovisning av kostnad för en resa 

SELECT
    bokning_id,
    kategori,
    beskrivning,
    belopp
FROM bokningskostnad;

-- Kan vi se fullbokade eller nästan fullbokade aktiviteter?

SELECT *
FROM v_aktivitetskapacitet
WHERE kapacitetsstatus IN ('fullbokad','nastan fullbokad');

-- viktigast 

-- Boendedetaljer

SELECT
b.namn,
bt.namn,
p.stad,
p.land
FROM boende b
JOIN boendetyp bt ON bt.boendetyp_id = b.boendetyp_id
JOIN plats p ON p.plats_id = b.plats_id;

-- Digital nomad-sökning

SELECT *
FROM v_digital_nomad_boende
ORDER BY wifi_hastighet_mbps DESC;

-- Lediga rum

SELECT *
FROM rum
WHERE tillganglig = TRUE;

-- Adminöversikt

SELECT *
FROM v_admin_bokningsdetalj;

-- Fullbokade aktiviteter

SELECT *
FROM v_aktivitetskapacitet
WHERE kapacitetsstatus IN ('fullbokad','nastan fullbokad');



