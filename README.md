# tp4_pgSQL

### 1. État des ressources
Nous observons un conflit croisé sur les verrous exclusifs (*row-level locks*) :
* La **Transaction 1 (T1)** détient le verrou sur le **Compte 1 (Alice)** et se met en attente pour obtenir le **Compte 2**.
* La **Transaction 2 (T2)** détient le verrou sur le **Compte 2 (Bob)** et se met en attente pour obtenir le **Compte 1**.

**2. L'Attente Circulaire (Circular Wait)**
C'est la cause racine du blocage. T1 attend que T2 libère une ressource, mais T2 attend que T1 libère la sienne. Ce cycle de dépendance (`T1 -> attend -> T2 -> attend -> T1`) crée une situation figée où aucune transaction ne peut avancer ni se terminer naturellement.



**3. Rôle du détecteur de Deadlock**
Le SGBD (PostgreSQL) possède un processus de fond qui surveille les temps d'attente des verrous.
* **Identification :** Lorsqu'il détecte que le graphe d'attente forme un cycle fermé, il identifie formellement le deadlock.
* **Résolution :** Pour briser ce cycle, le SGBD force l'annulation (**ROLLBACK**) d'une des deux transactions (la "victime"). Cela libère immédiatement ses verrous et permet à l'autre transaction (la "survivante") de se terminer correctement. Ceci explique pourquoi seul le virement d'Alice est effectué.
* **Implication applicative :** L'application reçoit une erreur fatale (`deadlock detected`) pour la transaction annulée. Elle doit être conçue pour capturer cette erreur et relancer l'opération (*retry logic*).

### 2. Correction
Pour corriger ce défaut de conception sans supprimer la concurrence, j'ai appliqué la stratégie du **Global Locking Order** (Ordre de Verrouillage Global).

**Le principe :**
Peu importe le sens du virement (Alice vers Bob ou Bob vers Alice), les transactions doivent **toujours acquérir les verrous dans le même ordre** (ici, par ordre croissant des identifiants : ID 1, puis ID 2).

**Implémentation technique :**
J'ai ajouté au début de chaque transaction une clause de verrouillage explicite et triée :
`SELECT ... FROM Comptes ... ORDER BY id_compte ASC FOR UPDATE;`

**Résultat :**
Au lieu de se croiser et de se bloquer mutuellement, la deuxième transaction se met désormais simplement en **file d'attente** dès le début, attendant que la première libère les ressources. Le système est passé d'un état instable (crash) à un état robuste (sérialisation temporaire).