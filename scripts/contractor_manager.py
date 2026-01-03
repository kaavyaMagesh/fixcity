import firebase_admin
from firebase_admin import credentials, auth

# 1. Use your existing JSON key
if not firebase_admin._apps:
    cred = credentials.Certificate("serviceAccountKey.json") # Ensure path is correct
    firebase_admin.initialize_app(cred)

def set_contractor_role(uid, dept):
    try:
        # This sets the "Badge" on the account
        auth.set_custom_user_claims(uid, {
            'role': 'contractor',
            'department': dept
        })
        print(f"✅ Success: User {uid} is now a Contractor for {dept}")
    except Exception as e:
        print(f"❌ Error: {e}")

# 2. Add your contractor UIDs here (Copy these from Firebase Auth Console)
contractors = {
    "LeZAof1zTnZtrIwC0ylg7YhpDDo2": "Roads",
    "ugdNpzSiCDN0va94oImw5nhCbMi1": "Water",
    "jgH50fde1zfB7uAwWV4eilqv3o43": "Power"
}

for uid, dept in contractors.items():
    set_contractor_role(uid, dept)