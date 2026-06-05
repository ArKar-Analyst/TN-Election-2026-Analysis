-- ============================================================
-- Database creation
-- ============================================================

create database tn_db;

use tn_db;

-- ============================================================
-- table & views creation
-- ============================================================

CREATE TABLE tn_2021_results (
    constituency VARCHAR(255) NOT NULL,
    ac_number INT NOT NULL,
    candidate VARCHAR(255) NOT NULL,
    party VARCHAR(100) NOT NULL,
    votes INT NOT NULL,
    turnout DECIMAL(5, 2) NOT NULL,
    reserved VARCHAR(50),
    region VARCHAR(500)
);

CREATE TABLE tn_2026_results (
    constituency VARCHAR(255) NOT NULL,
    ac_number INT NOT NULL,
    candidate VARCHAR(255) NOT NULL,
    party VARCHAR(100) NOT NULL,
    votes INT NOT NULL,
    turnout DECIMAL(5, 2) NOT NULL,
    reserved VARCHAR(50),
    region VARCHAR(500)
);



-- VIEW A: Winner per constituency — 2021
-- Logic: candidate with highest votes in each ac_number wins
CREATE OR REPLACE VIEW winners_2021 AS
SELECT *
FROM (
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY ac_number ORDER BY votes DESC) AS rank_in_constituency
    FROM   tn_2021_results
) ranked
WHERE rank_in_constituency = 1;

-- VIEW B: Winner per constituency — 2026
CREATE OR REPLACE VIEW winners_2026 AS
SELECT *
FROM (
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY ac_number ORDER BY votes DESC) AS rank_in_constituency
    FROM   tn_2026_results
) ranked
WHERE rank_in_constituency = 1;

-- Quick sanity check — should return 234 rows each
SELECT COUNT(*) AS total_winners_2021 FROM winners_2021;
SELECT COUNT(*) AS total_winners_2026 FROM winners_2026;

-- ============================================================
-- Slide 1 : Cover page (headline stats for the cover slide)
-- ============================================================

-- Total constituencies

SELECT COUNT(*) AS total_constituencies
FROM constituency_master;

-- TVK seats won

SELECT COUNT(*)
FROM winners_2026
WHERE party = 'TVK';

-- Seats flipped

WITH w21 AS (
    SELECT ac_number, party
    FROM  (SELECT ac_number, party,
                  ROW_NUMBER() OVER (PARTITION BY ac_number ORDER BY votes DESC) AS r
           FROM tn_2021_results) x WHERE r=1
),
w26 AS (
    SELECT ac_number, party
    FROM  (SELECT ac_number, party,
                  ROW_NUMBER() OVER (PARTITION BY ac_number ORDER BY votes DESC) AS r
           FROM tn_2026_results) x WHERE r=1
)
SELECT COUNT(*) AS seats_flipped
FROM  w21 JOIN w26 USING (ac_number)
WHERE w21.party <> w26.party;

-- TVK vote share

SELECT
    'TVK' AS party,
    ROUND(
        (
            SELECT SUM(votes)
            FROM tn_2026_results
            WHERE party = 'TVK'
        ) * 100.0
        /
        (
            SELECT SUM(votes)
            FROM tn_2026_results
        ),
        1
    ) AS vote_share_pct;
    
-- ============================================================
-- Slide 2 : Three questions one verdict
-- ============================================================

-- All numbers (108, 163, 34.9%) come
-- from the 4 queries on Slide 1.

-- ============================================================
-- Slide 3 : A New Political Order in 234 Constituencies
-- ============================================================

-- 2021 seat tally
SELECT party, COUNT(*) AS seats_2021
FROM  (
    SELECT party,
           ROW_NUMBER() OVER (
               PARTITION BY ac_number
               ORDER BY votes DESC
           ) AS rnk
    FROM  tn_2021_results
) r
WHERE rnk = 1
GROUP  BY party
ORDER  BY seats_2021 DESC;

-- 2026 seat tally
SELECT party, COUNT(*) AS seats_2026
FROM  (
    SELECT party,
           ROW_NUMBER() OVER (
               PARTITION BY ac_number
               ORDER BY votes DESC
           ) AS rnk
    FROM  tn_2026_results
) r
WHERE rnk = 1
GROUP  BY party
ORDER  BY seats_2026 DESC;

-- Right side panel

WITH s21 AS (
    SELECT party, COUNT(*) AS seats
    FROM (
        SELECT party,
               ROW_NUMBER() OVER (
                   PARTITION BY ac_number
                   ORDER BY votes DESC
               ) AS r
        FROM tn_2021_results
    ) x
    WHERE r = 1
    GROUP BY party
),

s26 AS (
    SELECT party, COUNT(*) AS seats
    FROM (
        SELECT party,
               ROW_NUMBER() OVER (
                   PARTITION BY ac_number
                   ORDER BY votes DESC
               ) AS r
        FROM tn_2026_results
    ) x
    WHERE r = 1
    GROUP BY party
)

SELECT
    COALESCE(s21.party, s26.party) AS party,
    COALESCE(s21.seats, 0) AS seats_2021,
    COALESCE(s26.seats, 0) AS seats_2026,
    COALESCE(s26.seats, 0) - COALESCE(s21.seats, 0) AS seat_change,
    ROUND(
        (COALESCE(s26.seats, 0) - COALESCE(s21.seats, 0))
        * 100.0 / NULLIF(COALESCE(s21.seats, 0), 0),
        1
    ) AS change_pct
FROM s21
LEFT JOIN s26
ON s21.party = s26.party

UNION

SELECT
    COALESCE(s21.party, s26.party) AS party,
    COALESCE(s21.seats, 0) AS seats_2021,
    COALESCE(s26.seats, 0) AS seats_2026,
    COALESCE(s26.seats, 0) - COALESCE(s21.seats, 0) AS seat_change,
    ROUND(
        (COALESCE(s26.seats, 0) - COALESCE(s21.seats, 0))
        * 100.0 / NULLIF(COALESCE(s21.seats, 0), 0),
        1
    ) AS change_pct
FROM s21
RIGHT JOIN s26
ON s21.party = s26.party

ORDER BY seats_2026 DESC;

-- Magic figure 

SELECT FLOOR((
SELECT COUNT(*) 
FROM tn_db.constituency_master
)* 1/2 +1)  AS Magic_figure;

-- ============================================================
-- Slide 4 : TVK Topped Every Region — But Not Equally
-- ============================================================

SELECT
    region,
    SUM(CASE WHEN party = 'TVK'    THEN 1 ELSE 0 END) AS TVK,
    SUM(CASE WHEN party = 'DMK'    THEN 1 ELSE 0 END) AS DMK,
    SUM(CASE WHEN party = 'AIADMK' THEN 1 ELSE 0 END) AS AIADMK,
    SUM(CASE WHEN party NOT IN
        ('TVK','DMK','AIADMK') THEN 1 ELSE 0 END) AS Others,
    COUNT(*) AS Total_seats
FROM  (
    SELECT region, party,
           ROW_NUMBER() OVER (
               PARTITION BY ac_number
               ORDER BY votes DESC
           ) AS rnk
    FROM  tn_2026_results
) r
WHERE  rnk = 1
GROUP  BY region
ORDER  BY Total_seats DESC;

-- ============================================================
-- Slide 5 : 163 of 234 Seats Changed Hands
-- ============================================================

-- Seats flipped vs retained

WITH flip AS (
    SELECT
        w21.ac_number,
        CASE WHEN w21.party <> w26.party
             THEN 'Flipped'
             ELSE 'Retained'
        END AS status
    FROM
      (SELECT ac_number, party
       FROM  (SELECT ac_number, party,
                     ROW_NUMBER() OVER (PARTITION BY ac_number ORDER BY votes DESC) AS r
              FROM tn_2021_results) x WHERE r=1) w21
    JOIN
      (SELECT ac_number, party
       FROM  (SELECT ac_number, party,
                     ROW_NUMBER() OVER (PARTITION BY ac_number ORDER BY votes DESC) AS r
              FROM tn_2026_results) x WHERE r=1) w26
    USING (ac_number)
)
SELECT
    status,
    COUNT(*) AS seats,
    ROUND(COUNT(*) * 100.0 / 234, 1) AS pct
FROM  flip
GROUP  BY status;

-- Partywise seat flow

WITH w21 AS (
    SELECT ac_number, party AS party_2021
    FROM  (SELECT ac_number, party,
                  ROW_NUMBER() OVER (PARTITION BY ac_number ORDER BY votes DESC) AS r
           FROM tn_2021_results) x WHERE r=1
),
w26 AS (
    SELECT ac_number, party AS party_2026
    FROM  (SELECT ac_number, party,
                  ROW_NUMBER() OVER (PARTITION BY ac_number ORDER BY votes DESC) AS r
           FROM tn_2026_results) x WHERE r=1
)
SELECT
    party_2021,
    party_2026,
    COUNT(*) AS seats_transferred
FROM   w21 JOIN w26 USING (ac_number)
WHERE  party_2021 <> party_2026
GROUP  BY party_2021, party_2026
ORDER  BY seats_transferred DESC;

-- Smallest margin

WITH ranked AS (
    SELECT
        ac_number, constituency, party, votes,
        ROW_NUMBER() OVER (
            PARTITION BY ac_number
            ORDER BY votes DESC
        ) AS rnk
    FROM  tn_2026_results
)
SELECT
    r1.constituency,
    r1.party    AS winner_party,
    r2.party    AS runner_up,
    r1.votes    AS winner_votes,
    r2.votes    AS runner_up_votes,
    r1.votes - r2.votes AS margin
FROM   ranked r1
JOIN   ranked r2
    ON  r1.ac_number = r2.ac_number
    AND r2.rnk = 2
WHERE  r1.rnk = 1
ORDER  BY margin ASC
LIMIT  5;

-- Biggest margin

WITH ranked AS (
    SELECT
        ac_number, constituency, party, votes,
        ROW_NUMBER() OVER (
            PARTITION BY ac_number
            ORDER BY votes DESC
        ) AS rnk
    FROM  tn_2026_results
)
SELECT
    r1.constituency,
    r1.party    AS winner_party,
    r2.party    AS runner_up,
    r1.votes    AS winner_votes,
    r2.votes    AS runner_up_votes,
    r1.votes - r2.votes AS margin
FROM   ranked r1
JOIN   ranked r2
    ON  r1.ac_number = r2.ac_number
    AND r2.rnk = 2
WHERE  r1.rnk = 1
ORDER  BY margin DESC
LIMIT  5;

-- ============================================================
-- Slide 6 : Seat Flow 2021 → 2026: TVK Absorbed From Everyone
-- ============================================================

-- Full transfer matrix including retained seats for node sizing

WITH w21 AS (
    SELECT
        ac_number,
        CASE
            WHEN party IN ('TVK','DMK','AIADMK','INC')
            THEN party
            ELSE 'Others'
        END AS party
    FROM (
        SELECT *,
               ROW_NUMBER() OVER (
                   PARTITION BY ac_number
                   ORDER BY votes DESC
               ) rn
        FROM tn_2021_results
    ) x
    WHERE rn = 1
),

w26 AS (
    SELECT
        ac_number,
        CASE
            WHEN party IN ('TVK','DMK','AIADMK','INC')
            THEN party
            ELSE 'Others'
        END AS party
    FROM (
        SELECT *,
               ROW_NUMBER() OVER (
                   PARTITION BY ac_number
                   ORDER BY votes DESC
               ) rn
        FROM tn_2026_results
    ) x
    WHERE rn = 1
)

SELECT
    CONCAT(w21.party, ' 2021') AS Source,
    CONCAT(w26.party, ' 2026') AS Destination,
    COUNT(*) AS Seats
FROM w21
JOIN w26
    ON w21.ac_number = w26.ac_number
GROUP BY
    w21.party,
    w26.party
HAVING COUNT(*) > 0
ORDER BY Seats DESC;

-- ============================================================
-- Slide 7 : Decoding TVK's vote percentage
-- ============================================================

-- vote share 2021 vs 2026

WITH share_2021 AS (
    SELECT party,
           ROUND(SUM(votes)*100.0 /
                (SELECT SUM(votes) FROM tn_2021_results),1) AS share
    FROM tn_2021_results
    GROUP BY party
),
share_2026 AS (
    SELECT party,
           ROUND(SUM(votes)*100.0 /
                (SELECT SUM(votes) FROM tn_2026_results),1) AS share
    FROM tn_2026_results
    GROUP BY party
)

SELECT
    COALESCE(s21.party,s26.party) AS party,
    COALESCE(s21.share,0) AS share_2021,
    COALESCE(s26.share,0) AS share_2026,
    COALESCE(s26.share,0)-COALESCE(s21.share,0) AS swing_pp
FROM share_2021 s21
LEFT JOIN share_2026 s26
ON s21.party = s26.party

UNION

SELECT
    COALESCE(s21.party,s26.party) AS party,
    COALESCE(s21.share,0) AS share_2021,
    COALESCE(s26.share,0) AS share_2026,
    COALESCE(s26.share,0)-COALESCE(s21.share,0) AS swing_pp
FROM share_2021 s21
RIGHT JOIN share_2026 s26
ON s21.party = s26.party

ORDER BY share_2026 DESC;

-- Right-panel erosion cards: DMK lost ~13.5pp

WITH v21 AS (
    SELECT
        party,
        ROUND(
            SUM(votes) * 100.0 /
            (SELECT SUM(votes) FROM tn_2021_results),
            2
        ) AS vote_pct
    FROM tn_2021_results
    GROUP BY party
),

v26 AS (
    SELECT
        party,
        ROUND(
            SUM(votes) * 100.0 /
            (SELECT SUM(votes) FROM tn_2026_results),
            2
        ) AS vote_pct
    FROM tn_2026_results
    GROUP BY party
)

SELECT
    COALESCE(v21.party, v26.party) AS party,
    COALESCE(v21.vote_pct, 0) AS vote_pct_2021,
    COALESCE(v26.vote_pct, 0) AS vote_pct_2026,
    ROUND(
        COALESCE(v26.vote_pct, 0) -
        COALESCE(v21.vote_pct, 0),
        2
    ) AS swing_pp
FROM v21
LEFT JOIN v26
ON v21.party = v26.party

UNION

SELECT
    COALESCE(v21.party, v26.party) AS party,
    COALESCE(v21.vote_pct, 0) AS vote_pct_2021,
    COALESCE(v26.vote_pct, 0) AS vote_pct_2026,
    ROUND(
        COALESCE(v26.vote_pct, 0) -
        COALESCE(v21.vote_pct, 0),
        2
    ) AS swing_pp
FROM v21
RIGHT JOIN v26
ON v21.party = v26.party

ORDER BY vote_pct_2026 DESC;


-- ============================================================
-- Slide 8 : A Uniform Wave — Not a Chennai Phenomenon
-- ============================================================

WITH region_totals AS (
    SELECT region,
           SUM(votes) AS total_2026,
           '2026'     AS yr
    FROM   tn_2026_results
    GROUP  BY region
    UNION ALL
    SELECT region,
           SUM(votes),
           '2021'
    FROM   tn_2021_results
    GROUP  BY region
),
party_votes AS (
    SELECT region, party,
           SUM(votes) AS pv,
           '2026'     AS yr
    FROM   tn_2026_results
    WHERE  party = 'TVK'
    GROUP  BY region, party
    UNION ALL
    SELECT region, party,
           SUM(votes),
           '2021'
    FROM   tn_2021_results
    WHERE  party = 'DMK'
    GROUP  BY region, party
)
SELECT
    pv.region,
    pv.yr,
    pv.party,
    ROUND(pv.pv * 100.0 / rt.total_2026, 1) AS vote_share_pct
FROM   party_votes pv
JOIN   region_totals rt
    ON  pv.region = rt.region
    AND pv.yr     = rt.yr
ORDER  BY pv.region, pv.yr;

-- ============================================================
-- Slide 9 : Decoding TVK's vote percentage
-- ============================================================

-- all queries for this page were done previously