# README — BaseModule.oz

Ce README décrit le fonctionnement du module principal `BaseModule.oz`, l’implémentation de la fonction `Decode`, ainsi que les trois extensions ajoutées au projet.

## Structure du module

`src/BaseModule.oz` est un functor Oz qui exporte deux éléments :

- `executeBlockchain:ExecuteBlockchain`, construit la blockchain finale à partir du genesis et des transactions.
- `decode:Decode`, décode la phrase secrète à partir de la blockchain finale.

Les extensions sont placées dans des fichiers séparés :

- `ExtensionDenylist.oz`, ajout de la denylist d’utilisateurs malveillants.
- `ExtensionEffort.oz`, prise en compte du coût monétaire de l’effort.
- `ExtensionStats.oz`, fonctions statistiques sur la blockchain.

---

## Fonctionnement de base

### Hachage

**`TransactionHash Nonce Sender Receiver Value`**

Retourne le hash d’une transaction :

```oz
(Nonce + Sender + Receiver + Value) mod 1000000
```

**`SumTransactionsHashes Transactions`**

Parcourt récursivement la liste des transactions validées d’un bloc et additionne leur champ `.hash`.

**`BlockHash Number PreviousHash Transactions`**

Retourne le hash d’un bloc :

```oz
(Number + PreviousHash + {SumTransactionsHashes Transactions}) mod 1000000
```

---

### Effort

**`ComputeEffort Value`**

Calcule l’effort nécessaire pour exécuter une transaction. Pour une valeur ayant `d` chiffres, l’effort vaut :

```text
2^0 + 2^1 + ... + 2^(d-1)
```

L’implémentation utilise une fonction interne `Loop` qui parcourt les chiffres par divisions successives par 10. L’accumulateur est mis à jour avec la relation :

```oz
2 * Accumulator + 1
```

Cela évite de calculer explicitement les puissances de 2.

---

### État des utilisateurs

**`InitialState Genesis`**

Convertit le record genesis en un record d’utilisateurs. Chaque entrée devient :

```oz
user(balance:Balance nonce:0)
```

Par exemple, un genesis contenant des soldes initiaux est transformé en un `State` de la forme :

```oz
state(
   1:user(balance:100 nonce:0)
   2:user(balance:50 nonce:0)
)
```

**`GetUser State User`**

Retourne l’utilisateur présent dans le `State`. Si l’utilisateur n’existe pas encore, la fonction retourne :

```oz
user(balance:0 nonce:0)
```

Cela permet de traiter des utilisateurs qui apparaissent pour la première fois dans une transaction.

---

### Validation et exécution des transactions

**`IsTransactionValid Transaction State`**

Vérifie qu’une transaction peut être acceptée. La validation contrôle notamment :

- le nonce du sender ;
- le hash de la transaction ;
- le solde disponible du sender ;
- la valeur de la transaction ;
- la valeur maximale d’effort autorisée ;
- l’effort réellement nécessaire.

La fonction retourne `true` si la transaction est valide, sinon `false`.

**`MakeTransaction Transaction State`**

Applique une transaction valide au `State` courant :

- le sender est débité du montant de la transaction ;
- son nonce est incrémenté ;
- le receiver est crédité du montant de la transaction.

La mise à jour est faite avec `Adjoin`, ce qui permet de créer un nouveau record d’état sans modifier directement l’ancien.

---

### Construction des blocs

**`GetBlockTransactions Transactions BlockNumber`**

Récupère toutes les transactions consécutives appartenant au même bloc.

**`SkipBlockTransactions Transactions BlockNumber`**

Ignore les transactions du bloc courant et retourne le reste de la liste, c’est à dire les transactions des blocs suivants.

**`FilterBlockTransactions Transactions State TotalEffort`**

Parcourt les transactions d’un bloc et retourne :

```oz
result(transactions:ValidTransactions state:NewState)
```

Pour chaque transaction :

- si l’effort total du bloc dépasse 300, la transaction est ignorée ;
- si la transaction est valide, elle est ajoutée au bloc et le `State` est mis à jour ;
- sinon, elle est rejetée.

**`AppendBlock Blockchain NewBlock`**

Ajoute un bloc à la fin de la blockchain.

**`AppendToBlockchain Transactions State PreviousHash Blockchain`**

Fonction récursive principale de construction de la blockchain. À chaque étape :

1. elle identifie le numéro du bloc courant ;
2. elle extrait les transactions du bloc ;
3. elle filtre les transactions valides ;
4. elle crée un nouveau bloc si au moins une transaction est valide ;
5. elle met à jour le hash précédent ;
6. elle continue avec les transactions restantes.

Quand il n’y a plus de transactions à traiter, elle retourne :

```oz
result(blockchain:Blockchain state:State)
```

---

## Fonction `Decode`

La fonction `Decode` prend la blockchain finale et retourne la phrase secrète encodée dans les hashes des blocs.

### Principe général

Pour chaque bloc de la blockchain :

1. récupérer le hash du bloc ;
2. convertir ce hash en string ;
3. lire les chiffres deux par deux ;
4. convertir chaque paire avec `mod 37` ;
5. remplacer les résultats inférieurs à 10 par 36 ;
6. convertir le nombre obtenu en caractère ;
7. ajouter le caractère au message final.

Si le hash contient un nombre impair de chiffres, le dernier chiffre isolé est ignoré.

### Fonctions utilisées

**`Decode Blockchain`**

Lance le décodage avec un accumulateur vide :

```oz
fun {Decode Blockchain}
   {DecodeAcc Blockchain ""}
end
```

**`DecodeAcc Blockchain Acc`**

Parcourt récursivement les blocs. Pour chaque bloc, elle récupère `H.hash`, le décode avec `DecodeHash`, puis concatène le résultat à l’accumulateur.

**`DecodeHash Hash`**

Convertit le hash entier en string avec `Int.toString`, afin de pouvoir parcourir ses chiffres.

**`DecodeHashAcc Digits Acc`**

Lit les chiffres deux par deux avec le pattern :

```oz
D1|D2|Rest
```

La paire `[D1 D2]` est transformée en entier, puis décodée. L’appel récursif continue avec `Rest`, ce qui garantit que les paires ne se chevauchent pas.

Exemple :

```text
281410 devient 28, 14, 10
```

**`DecodeNumberPair Number`**

Convertit un nombre en caractère selon le tableau de Sharelock :

- `10` à `35` correspondent aux lettres `a` à `z` ;
- `36` correspond à un espace ;
- les autres valeurs retournent une string vide.

---

## Extension 1 — Denylist

L’extension denylist ajoute une liste d’utilisateurs considérés comme malveillants. Une fois qu’un utilisateur est dans cette liste, ses transactions suivantes sont ignorées.

### Règle appliquée

Un utilisateur est ajouté à la denylist lorsqu’il atteint trois transactions envoyées dans un même bloc. Le comptage prend en compte les transactions du bloc, qu’elles soient valides ou non.

Dans l’implémentation, ce contrôle est fait dans `FilterBlockTransactions`, avant la validation de la transaction.

### Données supplémentaires

La fonction `FilterBlockTransactions` reçoit deux paramètres supplémentaires :

```oz
Denylist
Counts
```

- `Denylist` est la liste globale des utilisateurs bloqués.
- `Counts` est un record local au bloc courant, utilisé pour compter les transactions envoyées par chaque sender.

La fonction retourne aussi la denylist mise à jour :

```oz
result(transactions:ValidTransactions state:NewState denylist:NewDenylist)
```

### Fonctions auxiliaires

**`IsInList User List`**

Vérifie récursivement si un utilisateur est présent dans une liste.

**`AddToDenylist User Denylist`**

Ajoute un utilisateur à la denylist seulement s’il n’y est pas déjà.

**`GetSenderCount Counts Sender`**

Retourne le nombre de transactions déjà envoyées par un sender dans le bloc courant. Si le sender n’est pas encore présent, la fonction retourne `0`.

**`IncrementSenderCount Counts Sender`**

Incrémente le compteur local du sender dans le bloc courant.

### Propagation dans la blockchain

`AppendToBlockchain` transporte la denylist d’un bloc au suivant. En revanche, `Counts` est réinitialisé avec `counts()` pour chaque nouveau bloc, car la règle des trois transactions s’applique bloc par bloc.

---

## Extension 2 — Coût monétaire de l’effort

Cette extension ajoute un coût financier à l’effort. Chaque unité d’effort coûte une unité monétaire au sender.

### Validation modifiée

Dans `IsTransactionValid`, le sender doit maintenant avoir assez de fonds pour payer :

```oz
Transaction.value + Effort
```

La fonction vérifie d’abord que la valeur de la transaction n’est pas négative, puis calcule l’effort avec :

```oz
Effort = {ComputeEffort Transaction.value}
```

La transaction est rejetée si :

```oz
Sender.balance < Transaction.value + Effort
```

### Exécution modifiée

Dans `MakeTransaction`, le sender est débité du montant de la transaction plus le coût de l’effort :

```oz
Sender.balance - (Transaction.value + Effort)
```

Le receiver reçoit uniquement le montant de la transaction :

```oz
Receiver.balance + Transaction.value
```

Le coût de l’effort est donc consommé par l’exécution, mais il n’est pas transféré au receiver.

### Interaction avec l’effort maximal du bloc

L’effort continue aussi d’être utilisé pour vérifier la limite de bloc de 300. Une transaction valide peut donc être refusée si son ajout dépasse l’effort maximal autorisé pour le bloc.

---

## Extension 3 — Statistiques

Cette extension ajoute trois fonctions de statistiques sur la blockchain finale.

Les trois fonctions utilisent uniquement les transactions validées, car elles parcourent les transactions déjà présentes dans les blocs de la blockchain finale.

---

### `BiggestSenders Blockchain N`

Retourne la liste des `N` utilisateurs ayant envoyé le plus grand nombre de transactions validées.

L’implémentation :

1. parcourt tous les blocs ;
2. parcourt toutes les transactions validées de chaque bloc ;
3. compte le nombre de transactions par sender ;
4. trie les résultats par nombre décroissant ;
5. retourne les `N` premiers utilisateurs.

Le comptage est fait par :

```oz
IncrementSenderTransactionCount
```

Cette fonction maintient une liste de paires :

```oz
User#Count
```

La fonction `Take` retourne seulement les IDs utilisateurs, pas les compteurs.

---

### `ReceivedMost Blockchain N`

Retourne la liste des `N` utilisateurs ayant reçu la plus grande valeur totale de transactions.

L’implémentation :

1. parcourt toutes les transactions validées ;
2. additionne les valeurs reçues par receiver ;
3. trie les résultats par montant décroissant ;
4. retourne les `N` premiers utilisateurs.

Le cumul est fait par :

```oz
IncrementReceiverBalance
```

Cette fonction maintient une liste de paires :

```oz
User#TotalReceived
```

---

### `MoneyPeak Blockchain`

Retourne l’utilisateur qui a atteint le solde le plus élevé à un moment donné de la blockchain, ainsi que ce solde.

Le résultat est de la forme :

```oz
User#Balance
```

Exemple :

```oz
32#450
```

Cela signifie que l’utilisateur `32` a atteint un solde maximal de `450` à un moment de la blockchain.

L’implémentation :

1. part d’un `state()` vide, car l’extension considère que toutes les balances commencent à 0 ;
2. parcourt les blocs dans l’ordre ;
3. parcourt les transactions validées dans chaque bloc ;
4. applique chaque transaction avec `MakeTransaction` ;
5. parcourt le `State` après chaque transaction avec `Record.toListInd` ;
6. conserve le plus grand solde observé.

Les fonctions principales sont :

- `MoneyPeakBlockchainAcc`, parcourt les blocs ;
- `MoneyPeakTransactionsAcc`, parcourt les transactions d’un bloc ;
- `MaxBalanceInState`, transforme le state en liste de paires utilisateur et record utilisateur ;
- `MaxBalanceInList`, compare les balances une par une.

---

### Tri et cas limites

Les fonctions statistiques utilisent `SortNumberDescending`, un tri par insertion décroissant.

Le tri suit deux règles :

1. d’abord trier par valeur décroissante ;
2. en cas d’égalité, trier par ID utilisateur croissant.

Comme les utilisateurs sont représentés par des IDs numériques, ce second critère joue le rôle de l’ordre alphabétique demandé dans la consigne.

Si `N` est supérieur au nombre d’utilisateurs disponibles, `Take` retourne simplement tous les utilisateurs disponibles.

Si `N =< 0`, les fonctions `BiggestSenders` et `ReceivedMost` retournent :

```oz
~1
```

En Oz, `~1` correspond à `-1`.

---

## Point d’entrée

**`ExecuteBlockchain GenesisState Transactions FinalState FinalBlockchain`**

```oz
proc {ExecuteBlockchain GenesisState Transactions FinalState FinalBlockchain}
   State = {InitialState GenesisState}
   Result = {AppendToBlockchain Transactions State 0 nil}
in
   FinalState = Result.state
   FinalBlockchain = Result.blockchain
end
```

La procédure initialise le state à partir du genesis, construit la blockchain, puis lie les variables de sortie `FinalState` et `FinalBlockchain`.

Dans la version avec statistiques, des appels de debug peuvent être ajoutés avec `System.show` pour afficher les résultats des fonctions statistiques.

---

## Flux d’appel principal

```text
ExecuteBlockchain
 ├─ InitialState
 └─ AppendToBlockchain
     ├─ GetBlockTransactions
     ├─ SkipBlockTransactions
     ├─ FilterBlockTransactions
     │   ├─ ComputeEffort
     │   ├─ IsTransactionValid
     │   │   ├─ GetUser
     │   │   ├─ TransactionHash
     │   │   └─ ComputeEffort
     │   └─ MakeTransaction
     │       ├─ GetUser
     │       └─ Adjoin
     ├─ BlockHash
     │   └─ SumTransactionsHashes
     └─ AppendBlock
```

## Flux d’appel du décodage

```text
Decode
 └─ DecodeAcc
     └─ DecodeHash
         └─ DecodeHashAcc
             └─ DecodeNumberPair
```

## Flux d’appel des statistiques

```text
BiggestSenders
 ├─ ApplyTransactionsBlockchain
 │   └─ ApplyTransactions
 │       └─ IncrementSenderTransactionCount
 ├─ SortNumberDescending
 └─ Take

ReceivedMost
 ├─ ApplyTransactionsBlockchain
 │   └─ ApplyTransactions
 │       └─ IncrementReceiverBalance
 ├─ SortNumberDescending
 └─ Take

MoneyPeak
 └─ MoneyPeakBlockchainAcc
     └─ MoneyPeakTransactionsAcc
         ├─ MakeTransaction
         └─ MaxBalanceInState
             └─ MaxBalanceInList
```
