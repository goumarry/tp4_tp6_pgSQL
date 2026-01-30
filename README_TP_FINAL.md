````sql

SELECT emp_no, MAX(to_date) as date_depart
FROM public.salaries
GROUP BY emp_no
HAVING MAX(to_date) < '9999-01-01';

````
````sql

-- Récupérer les 2 dernières fiches de paie de TOUS les employés
WITH AllSalariesRanked AS (
    SELECT 
        emp_no, 
        salary, 
        to_date,
        ROW_NUMBER() OVER (PARTITION BY emp_no ORDER BY to_date DESC) as rang
    FROM public.salaries
)
SELECT * FROM AllSalariesRanked
WHERE rang <= 2; -- On garde les 2 denriers salaires de chaques employés

````
````sql

-- Fusion flag 1 et 2
WITH RankedSalaries AS (
    SELECT
        s.emp_no,
        s.salary,
        s.to_date,
        ROW_NUMBER() OVER (PARTITION BY s.emp_no ORDER BY s.to_date DESC) as rang
    FROM public.salaries s
    WHERE s.emp_no IN (
        SELECT emp_no
        FROM public.salaries
        GROUP BY emp_no
        HAVING MAX(to_date) < '9999-01-01'
    )
)
SELECT * FROM RankedSalaries
WHERE rang <= 2

````
````sql

-- FLAG 1 + 2 + 3 

WITH ExEmployees AS (
    -- ÉTAPE 1
    SELECT emp_no
    FROM public.salaries
    GROUP BY emp_no
    HAVING MAX(to_date) < '9999-01-01'
),
     RankedSalaries AS (
         -- ÉTAPE 2
         SELECT
             s.emp_no,
             s.salary,
             s.to_date,
             ROW_NUMBER() OVER (PARTITION BY s.emp_no ORDER BY s.to_date DESC) as rang
         FROM public.salaries s
                  INNER JOIN ExEmployees e ON s.emp_no = e.emp_no
     )
-- ÉTAPE 3 
SELECT
    s1.emp_no,
    s1.salary as dernier_salaire,
    s2.salary as ancien_salaire,
    (s1.salary - s2.salary) as perte_salaire,
    s1.to_date as date_depart
FROM RankedSalaries s1
         JOIN RankedSalaries s2 ON s1.emp_no = s2.emp_no
WHERE s1.rang = 1
  AND s2.rang = 2
  AND s1.salary < s2.salary;
````

````sql

-- Fusion 1 2 3 4

WITH ExEmployees AS (
    -- FLAG 1 
    SELECT emp_no
    FROM public.salaries
    GROUP BY emp_no
    HAVING MAX(to_date) < '9999-01-01'
),
     RankedSalaries AS (
         -- FLAG 2 
         SELECT
             s.emp_no,
             s.salary,
             s.to_date,
             ROW_NUMBER() OVER (PARTITION BY s.emp_no ORDER BY s.to_date DESC) as rang
         FROM public.salaries s
                  INNER JOIN ExEmployees ex ON s.emp_no = ex.emp_no
     ),
     AngryEmployees AS (
         SELECT
             s1.emp_no,
             s1.salary as dernier_salaire,
             s2.salary as ancien_salaire,
             s1.to_date as date_depart
         FROM RankedSalaries s1
                  JOIN RankedSalaries s2 ON s1.emp_no = s2.emp_no
         WHERE s1.rang = 1
           AND s2.rang = 2
           AND s1.salary < s2.salary -- Baisse de salaire confirmée
     )
-- FLAG 4 
SELECT
    e.first_name,
    e.last_name,
    t.title as dernier_poste,
    d.dept_no as num_departement,
    dep.dept_name,
    ae.date_depart,
    ae.dernier_salaire,
    ae.ancien_salaire
FROM AngryEmployees ae
         JOIN employees e ON ae.emp_no = e.emp_no
         JOIN titles t ON ae.emp_no = t.emp_no
         JOIN dept_emp d ON ae.emp_no = d.emp_no
         JOIN departments dep ON dep.dept_no = d.dept_no
WHERE
    ae.date_depart > '2002-07-31'     
  AND t.title = 'Senior Engineer'    
  AND t.to_date = ae.date_depart;   

-- J'ai volontairement rajouuté l'info du département de l'employé en question
````

### 🔎 Resultats requete


| First Name | Last Name | Dernier Poste | Num Dept | Dept Name | Date Départ | Dernier Salaire | Ancien Salaire |
| :--- | :--- | :--- | :--- | :--- | :--- | ---: | ---: |
| **Feipei** | Reeken | Senior Engineer | `d005` | Development | 2002-08-01 | 64 047 | 64 293 |
| **Gennady** | **Raney** | **Senior Engineer** | **`d004`** | **Production** | **2002-08-01** | **46 418** | **46 555** |
| Gennady | Raney | Senior Engineer | `d005` | Development | 2002-08-01 | 46 418 | 46 555 |

### 🕵️‍♂️ Analyse et Verdict

Selon moi le coupable est donc Gennady Raney plutot que Feipei Reeken car, même s'ils présentent tout deux éxactement les memes compétences ainsi
que le même mobile, Gennady était au moment du vol dans le département de production, et avait donc selon moi accés aux vraies données, celles qu'il a volé

🚩 **FLAG FINAL :** `FLAG{Gennady_Raney}`