import csv
import sys

if __name__ == "__main__":

        # Ouvrir le fichier CSV en mode lecture ('r') et le fichier TXT en mode écriture ('w')
    with open('Book2.csv', 'r') as fichier_csv, open('result.txt', 'w') as fichier_txt:
        # Lire toutes les lignes du fichier CSV
        lignes = fichier_csv.readlines()
        
        # Pour chaque ligne dans le fichier CSV
        for i in range(len(lignes)):
            # Supprimer les caractères de nouvelle ligne
            ligne = lignes[i].strip()
            
            # Ajouter une virgule après chaque ligne, sauf pour la dernière ligne
            if i < len(lignes) - 1:
                ligne += ','
            
            # Ajouter un saut de ligne ('\n') tous les 500 lignes, sauf après la dernière ligne
            if (i + 1) % 500 == 0 and i < len(lignes) - 1:
                ligne += '\n'
            
            # Écrire la ligne modifiée dans le fichier texte
            fichier_txt.write(ligne)
