# README — BaseModule.oz
---> README généré par IA 

## Structure du module

`src/BaseModule.oz` est un functor Oz qui exporte deux fonctions :
- `ExecuteBlockchain` : construit la blockchain à partir du genesis et des transactions.
- `Decode` : décode la phrase secrète depuis la blockchain finale.

---

## Fonctions auxiliaires

### Hachage

**`TransactionHash Nonce Sender Receiver Value`**
Retourne `(Nonce + Sender + Receiver + Value) mod 10^6`.

**`BlockHash Number PreviousHash Transactions`**
Retourne `(Number + PreviousHash + somme des hashes des transactions) mod 10^6`.

**`SumTransactionsHashes Transactions`**
Somme récursive des champs `.hash` de chaque transaction — utilisée par `BlockHash`.

---

### Effort

**`ComputeEffort Value`**
L'effort vaut `2^0 + 2^1 + ... + 2^(d-1)` où `d` est le nombre de chiffres décimaux de `value`.

Implémenté avec une boucle interne qui consomme un chiffre à la fois (`N div 10`) et accumule via la relation `S(n+1) = 2*S(n) + 1`, évitant ainsi de calculer des puissances explicitement.

---

### État

**`InitialState Genesis`**
Convertit le record genesis `(adresse:solde ...)` en `(adresse:user(balance:X nonce:0) ...)` via `Record.map`.

**`GetUser State UserId`**
Retourne `State.UserId` si l'utilisateur existe, sinon `user(balance:0 nonce:0)`. Permet de gérer les nouveaux utilisateurs sans erreur.

---

### Validation et exécution

**`IsTransactionValid Transaction State`**
Vérifie dans l'ordre : nonce == dernier nonce émetteur + 1, hash correct, solde suffisant, value >= 0, max_effort > 0, effort <= max_effort. Retourne `true` ou `false`.

**`MakeTransaction Transaction State`**
Applique une transaction valide sur l'état : débite l'émetteur (`value` + nonce+1), crédite le destinataire. Utilise `Adjoin` pour mettre à jour les deux entrées du state record sans recréer tout le record.

---

### Construction des blocs

**`GetBlockTransactions Transactions BlockNumber`**
Retourne le préfixe de la liste dont le `block_number` correspond. S'arrête au premier élément d'un autre bloc (les transactions sont triées par bloc croissant).

**`SkipBlockTransactions Transactions BlockNumber`**
Retourne le suffixe de la liste après le bloc `BlockNumber` — le complément de `GetBlockTransactions`.

**`FilterBlockTransactions Transactions State TotalEffort`**
Parcourt les transactions d'un bloc et retourne `result(transactions:ValidTxs state:NewState)`.
Pour chaque transaction :
- Si `TotalEffort + effort > 300` → ignorée (mais les suivantes sont examinées).
- Si valide → acceptée, état mis à jour, effort accumulé.
- Sinon → rejetée.

**`AppendBlock Blockchain NewBlock`**
Ajoute `NewBlock` en queue de la liste `Blockchain` par récursion.

**`AppendToBlockchain Transactions State PreviousHash Blockchain`**
Boucle récursive principale. À chaque itération :
1. Identifie le bloc courant (`H.block_number`).
2. Extrait ses transactions (`GetBlockTransactions`) et celles des blocs suivants (`SkipBlockTransactions`).
3. Filtre les transactions valides (`FilterBlockTransactions`).
4. Crée le bloc avec son hash et l'ajoute à la blockchain.
5. Rappel récursif avec l'état mis à jour et le hash du nouveau bloc comme `PreviousHash`.

Retourne `result(blockchain:B state:S)` quand la liste de transactions est vide.

---

## Point d'entrée

**`ExecuteBlockchain GenesisState Transactions FinalState FinalBlockchain`** (procédure)

```oz
proc {ExecuteBlockchain GenesisState Transactions FinalState FinalBlockchain}
    State  = {InitialState GenesisState}
    Result = {AppendToBlockchain Transactions State 0 nil}
in
    FinalState      = Result.state
    FinalBlockchain = Result.blockchain
end
```

Initialise l'état depuis le genesis, lance la construction de la blockchain (hash initial = 0, blockchain initiale = nil), puis lie les sorties par unification. C'est une `proc` et non une `fun` car les sorties sont des variables logiques passées en paramètre.

---

## Flux d'appel

```
ExecuteBlockchain
 └─ InitialState
 └─ AppendToBlockchain  [récursion sur les blocs]
       └─ GetBlockTransactions
       └─ SkipBlockTransactions
       └─ FilterBlockTransactions  [récursion sur les transactions]
             └─ ComputeEffort
             └─ IsTransactionValid
                   └─ GetUser, TransactionHash, ComputeEffort
             └─ MakeTransaction
                   └─ GetUser, Adjoin
       └─ BlockHash
             └─ SumTransactionsHashes
       └─ AppendBlock
```
