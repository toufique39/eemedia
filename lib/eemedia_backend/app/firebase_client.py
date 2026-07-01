import os
import firebase_admin
from firebase_admin import credentials, firestore

def get_firestore_client():

  if not firebase_admin._apps:
    base_dir = os.path.dirname(
        os.path.dirname(os.path.abspath(__file__)),
    )

    service_account_path = os.path.join(
        base_dir,
        "serviceAccountKey.json",
    )


    if not os.path.exists(service_account_path):
        raise FileNotFoundError(
            "serviceAccountKey.json not found in eemedia_backend folder.",
        )

    credential = credentials.Certificate(service_account_path)

    firebase_admin.initialize_app(credential)

  return firestore.client()

