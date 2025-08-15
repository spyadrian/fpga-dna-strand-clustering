import sys

def load_file(filepath, separator=';'):
    """
    Charge un fichier et retourne un dictionnaire {query: [liste_de_références]}
    Gère maintenant les queries qui ont plusieurs références équidistantes
    """
    data = {}
    try:
        with open(filepath, 'r', encoding='utf-8') as file:
            for line_num, line in enumerate(file, 1):
                line = line.strip()
                if not line:
                    continue
                
                parts = line.split(separator)
                if len(parts) != 2:
                    print(f"Attention: ligne {line_num} mal formatée: {line}")
                    continue
                
                query, reference = parts[0].strip(), parts[1].strip()
                
                # Si la query existe déjà, ajouter la référence à la liste
                if query in data:
                    if reference not in data[query]:  # Éviter les doublons
                        data[query].append(reference)
                else:
                    data[query] = [reference]
                    
    except FileNotFoundError:
        print(f"Erreur: Le fichier {filepath} n'a pas été trouvé.")
        return {}
    except Exception as e:
        print(f"Erreur lors de la lecture du fichier {filepath}: {e}")
        return {}
    
    return data

def calculate_metrics(attendu_dict, trouve_dict):
    """
    Calcule les métriques en gérant les références équidistantes
    """
    all_queries = set(attendu_dict.keys()) | set(trouve_dict.keys())
    
    tp = 0  # Correspondances correctes
    fp = 0  # Correspondances incorrectes
    fn = 0  # Correspondances manquées
    
    details = []
    
    for query in all_queries:
        references_attendues = set(attendu_dict.get(query, []))
        references_trouvees = set(trouve_dict.get(query, []))
        
        if references_attendues and references_trouvees:
            # Calculer l'intersection (références correctement trouvées)
            correctes = references_attendues & references_trouvees
            incorrectes = references_trouvees - references_attendues
            manquees = references_attendues - references_trouvees
            
            tp += len(correctes)
            fp += len(incorrectes)
            fn += len(manquees)
            
            # Détails pour debug
            if correctes:
                details.append(f"TP: '{query}' -> Correctes: {correctes}")
            if incorrectes:
                details.append(f"FP: '{query}' -> Incorrectes: {incorrectes}")
            if manquees:
                details.append(f"FN: '{query}' -> Manquées: {manquees}")
                
        elif references_attendues and not references_trouvees:
            # Toutes les références attendues sont manquées
            fn += len(references_attendues)
            details.append(f"FN: '{query}' -> Toutes manquées: {references_attendues}")
            
        elif not references_attendues and references_trouvees:
            # Toutes les références trouvées sont incorrectes
            fp += len(references_trouvees)
            details.append(f"FP: '{query}' -> Toutes incorrectes: {references_trouvees}")
    
    return tp, fp, fn, details

def print_confusion_matrix(tp, fp, fn, tn):
    """
    Affiche la matrice de confusion
    """
    print("\n" + "="*50)
    print("MATRICE DE CONFUSION")
    print("="*50)
    print(f"{'':>15} {'Prédit Positif':>15} {'Prédit Négatif':>15}")
    print(f"{'Réel Positif':>15} {'TP: ' + str(tp):>15} {'FN: ' + str(fn):>15}")
    print(f"{'Réel Négatif':>15} {'FP: ' + str(fp):>15} {'TN: ' + str(tn):>15}")

def calculate_performance_metrics(tp, fp, fn, tn):
    """
    Calcule précision, rappel et exactitude
    """
    # Précision = TP / (TP + FP)
    precision = tp / (tp + fp) if (tp + fp) > 0 else 0
    
    # Rappel (Sensibilité) = TP / (TP + FN)
    recall = tp / (tp + fn) if (tp + fn) > 0 else 0
    
    # Exactitude = (TP + TN) / (TP + TN + FP + FN)
    accuracy = (tp + tn) / (tp + tn + fp + fn) if (tp + tn + fp + fn) > 0 else 0
    
    # F1-Score = 2 * (Précision * Rappel) / (Précision + Rappel)
    f1_score = 2 * (precision * recall) / (precision + recall) if (precision + recall) > 0 else 0
    
    return precision, recall, accuracy, f1_score

def main():
    # Check command-line arguments
    if len(sys.argv) != 3:
        print("Usage: python results-analyzer.py <expected_results_file> <found_results_file>")
        print("Example: python results-analyzer.py resultats_attendus.txt resultats_trouves.txt")
        sys.exit(1)
    
    # Get file paths from command-line arguments
    fichier_attendu = sys.argv[1]
    fichier_trouve = sys.argv[2]
    
    print("Chargement des fichiers...")
    
    # Chargement des données avec support des références multiples
    attendu_dict = load_file(fichier_attendu)
    trouve_dict = load_file(fichier_trouve)
    
    print(f"Résultats attendus: {len(attendu_dict)} queries uniques")
    print(f"Résultats trouvés: {len(trouve_dict)} queries uniques")
    
    # Statistiques sur les références multiples
    total_expected_pairs = sum(len(refs) for refs in attendu_dict.values())
    total_found_pairs = sum(len(refs) for refs in trouve_dict.values())
    
    print(f"Total de paires attendues: {total_expected_pairs}")
    print(f"Total de paires trouvées: {total_found_pairs}")
    
    if not attendu_dict or not trouve_dict:
        print("Erreur: Impossible de charger les fichiers.")
        return
    
    # Calcul des métriques adaptées
    tp, fp, fn, details = calculate_metrics(attendu_dict, trouve_dict)
    tn = 0  # Difficile à définir dans ce contexte
    
    # Affichage des résultats
    print_confusion_matrix(tp, fp, fn, tn)
    
    print("\n" + "="*50)
    print("MÉTRIQUES DE PERFORMANCE (avec équidistances)")
    print("="*50)
    
    precision, recall, accuracy, f1_score = calculate_performance_metrics(tp, fp, fn, tn)
    
    print(f"True Positives (TP): {tp}")
    print(f"False Positives (FP): {fp}")
    print(f"False Negatives (FN): {fn}")
    print(f"True Negatives (TN): {tn}")
    
    print(f"\nPrécision: {precision:.4f} ({precision*100:.2f}%)")
    print(f"Rappel: {recall:.4f} ({recall*100:.2f}%)")
    print(f"Exactitude: {accuracy:.4f} ({accuracy*100:.2f}%)")
    print(f"F1-Score: {f1_score:.4f}")
    
    # Affichage optionnel des détails
    print(f"\n" + "="*50)
    print("DÉTAILS DES CLASSIFICATIONS")
    print("="*50)
    show_details = input("Voulez-vous voir le détail de chaque classification? (o/n): ").lower()
    if show_details == 'o':
        for detail in details:
            print(detail)

if __name__ == "__main__":
    main()
