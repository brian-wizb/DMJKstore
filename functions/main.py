import functions_framework
import torch
import clip
from PIL import Image
import requests
from flask import jsonify
import firebase_admin
from firebase_admin import credentials, firestore

cred = credentials.ApplicationDefault()
firebase_admin.initialize_app(cred)
db = firestore.client()

device = "cuda" if torch.cuda.is_available() else "cpu"
model, preprocess = clip.load("ViT-B/32", device=device)

def compute_similarity(query_vector, db_vectors):
    from sklearn.metrics.pairwise import cosine_similarity
    return cosine_similarity([query_vector], db_vectors)[0]

@functions_framework.http
def match_product(request):
    if request.method != 'POST':
        return jsonify({"error": "Only POST allowed"}), 405

    try:
        image_url = request.json["imageUrl"]
        response = requests.get(image_url, stream=True)
        image = preprocess(Image.open(response.raw)).unsqueeze(0).to(device)

        with torch.no_grad():
            query_embedding = model.encode_image(image).cpu().numpy()[0]

        products_ref = db.collection("products").stream()
        db_embeddings = []
        ids = []

        for doc in products_ref:
            data = doc.to_dict()
            if 'embedding' in data:
                db_embeddings.append(data['embedding'])
                ids.append(doc.id)

        similarities = compute_similarity(query_embedding, db_embeddings)
        top_indices = sorted(range(len(similarities)), key=lambda i: similarities[i], reverse=True)[:5]

        matches = [{"productId": ids[i], "score": float(similarities[i])} for i in top_indices]

        return jsonify({"matches": matches})
    except Exception as e:
        return jsonify({"error": str(e)}), 500
