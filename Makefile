OZ=ozc # OZ Compiler
OZE=ozengine # OZ Emulator

NOMA1=00002400
NOMA2=00002400
ZIP_NAME=$(NOMA1)_$(NOMA2).zip

# Fichiers sources
BASE_SRC=src/BaseModule.oz
HELPER_SRC=library/FileHelperModule.oz
MAIN_SRC=Main.oz

# Fichiers compilés (foncteurs)
BASE_OZF=$(BASE_SRC:.oz=.ozf)
HELPER_OZF=$(HELPER_SRC:.oz=.ozf)
MAIN_OZF=$(MAIN_SRC:.oz=.ozf)

# Cible par défaut : tout compiler
all: $(BASE_OZF) $(HELPER_OZF) $(MAIN_OZF)

# Règle pour compiler les fichiers .oz en .ozf
%.ozf: %.oz
	$(OZ) -c $< -o $@

# Dépendances spécifiques (Main a besoin des modules pour être testé, 
# même si ozc -c ne vérifie pas les imports à la compilation)
$(MAIN_OZF): $(MAIN_SRC) $(BASE_OZF) $(HELPER_OZF)
	$(OZ) -c $(MAIN_SRC) -o $(MAIN_OZF)

# Commande pour nettoyer les fichiers compilés
clean:
	rm -f $(BASE_OZF) $(HELPER_OZF) $(MAIN_OZF)

# Commande pour exécuter le programme (exemple avec arguments)
run: all
	$(OZE) $(MAIN_OZF)

zip: clean
	@if [ ! -f "rapport.pdf" ]; then \
		echo "ERREUR : Le fichier 'rapport.pdf' est manquant à la racine !"; \
		exit 1; \
	fi
	zip -r $(ZIP_NAME) . -x "*.ozf" "*.git*" "*/.*" "Makefile"
	@echo "L'archive $(ZIP_NAME) a été créée avec succès."