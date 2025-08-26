def parse_file(filepath):
    """
    Parse un fichier avec le format <ref;query>
    Retourne un dictionnaire {query: set(refs)}
    """
    found_pairs = []
    with open(filepath, 'r', encoding='utf-8') as file:
        for line in file:
            pair = line.strip().split(";")
            found_pairs.append(tuple(pair))

    return found_pairs

def calculate_metrics(true_data, pred_data):
    """
    Calcule les métriques de classification pour une liste de tuples (query, ref).
    
    true_data: list of (query, ref) tuples (ground-truth)
    pred_data: list of (query, ref) tuples (predictions)
    """

    tp = 0  # True Positives
    fp = 0  # False Positives
    tn = 0  # True Negatives
    fn = 0  # False Negatives

    # For every possible (query, ref) pair
    tr_data = set(true_data)
    for true_d in tr_data:
        ref_t, query_t = true_d

        same = []
        for pred in pred_data:
            ref_p, query_p = pred

            if query_p == query_t:
                same.append(pred)

        for s in same:
            ref_s, query_s = s

            if ref_s == ref_t:
                tp += 1
            else:
                fp += 1
        
        if not same:
            fn += 1


    return tp, fp, tn, fn

def calculate_performance_metrics(tp, fp, tn, fn):
    """
    Calcule precision, recall, accuracy et F1-score
    """
    # Precision = TP / (TP + FP)
    precision = tp / (tp + fp) if (tp + fp) > 0 else 0
    
    # Recall = TP / (TP + FN)
    recall = tp / (tp + fn) if (tp + fn) > 0 else 0
    
    # Accuracy = (TP + TN) / (TP + TN + FP + FN)
    accuracy = (tp + tn) / (tp + tn + fp + fn) if (tp + tn + fp + fn) > 0 else 0
    
    # F1-score = 2 * (precision * recall) / (precision + recall)
    f1_score = 2 * (precision * recall) / (precision + recall) if (precision + recall) > 0 else 0
    
    return precision, recall, accuracy, f1_score

def main(true_file, pred_file):
    """
    Fonction principale
    """
    print("Chargement des fichiers...")
    
    # Parser les fichiers
    true_data = parse_file(true_file)
    pred_data = parse_file(pred_file)
    
    print(f"Données vraies: {len(true_data)} queries")
    print(f"Données prédites: {len(pred_data)} queries")
    
    # Calculer les métriques de base
    tp, fp, tn, fn = calculate_metrics(true_data, pred_data)
    
    # Calculer les métriques de performance
    precision, recall, accuracy, f1_score = calculate_performance_metrics(tp, fp, tn, fn)
    
    # Afficher les résultats
    print("\n" + "="*50)
    print("RÉSULTATS")
    print("="*50)
    print(f"True Positives (TP):  {tp}")
    print(f"False Positives (FP): {fp}")
    print(f"True Negatives (TN):  {tn}")
    print(f"False Negatives (FN): {fn}")
    print()
    print(f"Precision: {precision:.4f}")
    print(f"Recall:    {recall:.4f}")
    print(f"Accuracy:  {accuracy:.4f}")
    print(f"F1-score:  {f1_score:.4f}")
    
    return {
        'tp': tp, 'fp': fp, 'tn': tn, 'fn': fn,
        'precision': precision, 'recall': recall,
        'accuracy': accuracy, 'f1_score': f1_score
    }

if __name__ == "__main__":
    import sys
    if len(sys.argv) != 3:
        print("Usage: python script.py <fichier_vrai> <fichier_pred>")
    else:
        true_file = sys.argv[1]
        pred_file = sys.argv[2]
        try:
            results = main(true_file, pred_file)
        except FileNotFoundError as e:
            print(f"Erreur: Fichier non trouvé - {e}")
        except Exception as e:
            print(f"Erreur: {e}")
