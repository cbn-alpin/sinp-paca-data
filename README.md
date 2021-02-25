# sinp-paca-data
Scripts d'intégration des données pour le SINP PACA.

## Outils et commandes utiles

Lors de l'intégration des données [au format d'échange](https://wiki-sinp.cbn-alpin.fr/database/import-formats), 
il peut être nécessaire d'analyser ou corriger les fichiers csv reçus. 
Ci-dessous sont indiqués différentes commandes et outils permettant de 
travailler avec ces fichiers.

### Extraction de lignes d'un fichier

L'ouverture du fichier `synthese.csv` dans un éditeur de texte peut poser
problème contenu de sa taille.
Il est possible d'extraire un nombre réduit de lignes du début du fichier 
à l'aide de la commande suivante :
```
head -1000 synthese.csv > synthese.extract.csv
```
Pour extraire des lignes de la fin du fichier, utiliser la commande
:
```
tail -1000 synthese.csv > synthese.extract_end.csv
```

### Extraire les lignes comprenant un nombre de tabulation anormal

Dans le fichier synthese.csv, il peut être utile de commencer par repérer
les lignes possédant un nombre de tabulation anormal. La tabulation servant
à séparer les colonnes, il devrait toujours y en avoir le même nombre
pour chaque ligne.

Si ce nombre est supérieur à la normale, cela indique qu'au moins une 
valeur d'au moins un champ exporté contient une ou plusieurs tabulations.

Si ce nombre est inférieur à la normale, cela indique qu'au moins une 
valeur d'au moins un champ exporté contient un ou plusieurs caractères 
de fin de ligne (CR et/ou LF).

Il est possible de répérer les lignes posant problème avec la succession
de commandes suivantes :

```
# Extraire le nombre de tabulation anormal (différent de 56) et le numéro de la ligne correspondante :
grep -n -o -P "\t" synthese.csv | sort -n -T /data-nvme/jpm/ | uniq -c | cut -d : -f 1 | grep -P -v "^\s+56 " > ./synthese.tab_errors.txt

# Supprimer le nombre de tabulation et ne garder ques les numéros de ligne dans un fichier synthese.line_numbers.txt

# Ajouter des 0 initiaux aux numéros des lignes dans une nouveau fichier synthese.padded_line_numbers.txt :
while read rownum; do \
    printf '%.12d\n' "$rownum" \
done < synthese.line_numbers.txt > synthese.padded_line_numbers.txt

# Extraire les lignes qui posent problème (Attention : ordre des lignes non respecté !)
join <(sort synthese.padded_line_numbers.txt) <(nl -w 12 -n rz synthese.csv) | cut -d ' ' -f 2- > synthese.tab_errors.csv
```

### Afficher les lignes dupliquées pour une colonne donnée dans Libre Office

En ouvrant les fichiers csv à l'aide de Libre Office, il est posible de répérer
les doublons présent dans une colonne.

Pour cela sélectionner une colone, puis ouvrir le menu `Format > Conditionnel > Condition...`.

Dans la fenêtre qui s'ouvre sélectionner :
- "La valeur de la cellule est"
- puis "dupliquer" à la place de "égale à".
- dans "Appliquer le style" choisir le style "Warning"

Cliquer sur OK.

Les lignes possédant une valeur dupliquée dans la colonne sélectionnée devraient
apparaître avec un texte rouge.

### Affichage/Extraction de lignes contenant une chaine particulière

Par exemple, pour extraire les lignes du fichier `synthese.csv` contenant 
la chaine `'BENCE Stéphane\t\tpointage'` (noter la présence de tabulation `\t`)
dans un nouveau fichier `synthese.problems.csv` contenant l'entête des colonnes, 
utiliser les commandes suivantes :
```
head -1 synthese.csv > synthese.problems.csv
grep -P 'BENCE Stéphane\t\tpointage' synthese.csv >> synthese.problems.csv
```

### Remplacement de chaine

Pour remplacer une chaine dans un fichier texte donnée, il est possible d'utiliser
`sed` avec l'option `-i`.
Par exemple, pour remplacer `BENCE Stéphane\t\tpointage` par `BENCE Stéphane\tpointage`
utiliser la commande :
```
sed -i 's#BENCE Stéphane\t\tpointage#BENCE Stéphane\tpointage#g' synthese.csv
```
