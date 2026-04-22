# LINFO1104/LSINC1104: PROJET

**À LIRE AVANT DE COMMENCER LE PROJET**

## Structure

La structure du projet est la suivante:

```text
.
├── Main.oz                         # Contient la logic d'exécution (programme principal vous ne devez rien y ajouter)
├── (Main.ozf)                      # Binaire compilé du programme principal 
├── Makefile                        # all, clean, run, zip
├── README.md                       # Documentation du projet
├── library/                        # Modules utilitaires réutilisables implémenté pour vous (pas besoin d'y toucher)
│   ├── FileHelperModule.oz         # Gestion des fichiers
│   └── (FileHelperModule.ozf)      # Binaire du helper
├── src/                            # 
│   ├── BaseModule.oz               # Source de l'implémentation de base, là où vous implémenterai vos fonctions
│   └── (BaseModule.oz)             # Binaire du module de base
└── data/                           # 
    ├── genesis.txt                 # État génesis
    └── transactions.txt            # List des transactions
```


## Makefile

Pour vous faciliter les choses, le Makefile permet de compiler et d'exécuter votre code.

- `make`: compile votre code source (`.oz`) en binaire (`.ozf`)
- `make clean`: nettoie le repository en supprimant les fichiers binaires (`.ozf`)
- `make run`: compile si nécessaire puis exécute votre code (correspond à `ozengine Main.ozf`)
- `make zip`: Crée une archive `zip` de votre code pour la soumission. 

**MERCI DE MODIFIER NOMA1 ET NOMA2 DANS LE MAKEFILE POUR QU'ILS CORRESPONDENT AUX VOTRES !**

## Implémentation


## Soumission

La soumission du projet se fait via la soumission d'une archive `zip` de votre projet sur une tâche INGInious. Pour se faire, veuillez:

1. Modifier les champs `NOMA1` et `NOMA2` dans le fichier [Makefile](./Makefile). Dans l'éventualité ou vous seriez seul(e), indiquez `00000000` pour le champ `NOMA2`.
   - **Pour rappel, le projet est à faire en groupe de 2, sauf circonstances exceptionnelles et approuvées.**
2. Ajouter votre rapport, au format `.pdf`, à la racine du projet. Il doit être nommé `rapport.pdf`, sans quoi l'archive ne sera pas crée.
   - Référez-vous à [projet.pdf] pour les consignes du rapport.
3. Créer l'archive zip à l'aide de la commande `make zip` (exécutée à la racine de votre projet).

Une fois l'archive `zip` générée, allez sur INGInious:

1. Rejoignez un groupe avec votre binôme.
2. Soumettez l'archive zip sur la tâche de soumission (une fois par groupe c'est suffisant).
