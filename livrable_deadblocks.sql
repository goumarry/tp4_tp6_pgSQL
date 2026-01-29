-- Partie 1

-- Création de la table Comptes
CREATE TABLE Comptes (
                         id_compte SERIAL PRIMARY KEY,
                         nom_titulaire VARCHAR(100) NOT NULL,
                         solde DECIMAL(10, 2) NOT NULL CHECK (solde >= 0)
);

-- Insertion des données initiales (Alice et Bob)
INSERT INTO Comptes (nom_titulaire, solde)
VALUES ('Alice', 1000.00), ('Bob', 1000.00);

SELECT * FROM Comptes;
-- Alice et Bob ont chacun 1000 euros


-- Partie 2

-- Conseole 1

BEGIN;
UPDATE Comptes SET solde = solde - 100.00 WHERE id_compte = 1;
SELECT pg_sleep(5);
-- -> console 2

UPDATE Comptes SET solde = solde + 100.00 WHERE id_compte = 2;
COMMIT;
-- -> console 2

-- Console 2

BEGIN;
UPDATE Comptes SET solde = solde - 50.00 WHERE id_compte = 2;
-- -> console1

SELECT pg_sleep(5);
-- DEADLOCK
UPDATE Comptes SET solde = solde + 50.00 WHERE id_compte = 1;
COMMIT;

-- Partie 3 ( voir README )

-- Partie 4
UPDATE Comptes SET solde = solde + 100.00 WHERE id_compte = 1;
UPDATE Comptes SET solde = solde - 100.00 WHERE id_compte = 2;



-- Console 1
BEGIN;
SELECT id_compte FROM Comptes WHERE id_compte IN (1, 2) ORDER BY id_compte ASC FOR UPDATE;
UPDATE Comptes SET solde = solde - 100.00 WHERE id_compte = 1;
SELECT pg_sleep(5);
-- -> console 2


UPDATE Comptes SET solde = solde + 100.00 WHERE id_compte = 2;
COMMIT;
-- -> console 2

-- Console 2
BEGIN;
SELECT id_compte FROM Comptes WHERE id_compte IN (1, 2) ORDER BY id_compte ASC FOR UPDATE;
-- -> console 1

UPDATE Comptes SET solde = solde - 50.00 WHERE id_compte = 2;
UPDATE Comptes SET solde = solde + 50.00 WHERE id_compte = 1;
COMMIT;


-- Les comptes sont bien de 950 pour Alice et 1050 pour Bob
SELECT * FROM Comptes;