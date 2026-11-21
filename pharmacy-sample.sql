-- SQLite example. Run in a new in-memory database.
-- All rows below are fictional and independent of the published dashboard.

CREATE TABLE prescription_items (
    item_id INTEGER PRIMARY KEY,
    medicine TEXT NOT NULL,
    units_prescribed INTEGER NOT NULL CHECK (units_prescribed > 0)
);

CREATE TABLE dispensing (
    dispense_id INTEGER PRIMARY KEY,
    item_id INTEGER NOT NULL REFERENCES prescription_items(item_id),
    units_dispensed INTEGER NOT NULL CHECK (units_dispensed >= 0)
);

INSERT INTO prescription_items VALUES
    (1, 'Amoxicillin', 10),
    (2, 'Amoxicillin', 5),
    (3, 'Cetirizine', 10),
    (4, 'Cetirizine', 5);

INSERT INTO dispensing VALUES
    (1, 1, 4),
    (2, 1, 8),
    (3, 3, 7),
    (4, 4, 2);

-- Aggregate dispensing before the join so split fills count as one item.
-- Keep unfilled items via LEFT JOIN and cap fulfilled units per item.
WITH dispensed_by_item AS (
    SELECT item_id, SUM(units_dispensed) AS recorded_units
    FROM dispensing
    GROUP BY item_id
), item_totals AS (
    SELECT p.medicine,
           p.units_prescribed,
           MIN(p.units_prescribed, COALESCE(d.recorded_units, 0)) AS fulfilled_units,
           COALESCE(d.recorded_units, 0) > p.units_prescribed AS over_dispensed
    FROM prescription_items AS p
    LEFT JOIN dispensed_by_item AS d ON d.item_id = p.item_id
)
SELECT medicine,
       SUM(units_prescribed) AS prescribed_units,
       SUM(fulfilled_units) AS fulfilled_units,
       SUM(units_prescribed - fulfilled_units) AS outstanding_units,
       ROUND(100.0 * SUM(fulfilled_units) / SUM(units_prescribed), 1) AS fulfillment_pct,
       SUM(over_dispensed) AS items_over_dispensed
FROM item_totals
GROUP BY medicine
ORDER BY fulfillment_pct, medicine;
