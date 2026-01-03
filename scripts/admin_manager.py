import firebase_admin
from firebase_admin import credentials, auth
import sys

# Initialize the "God Mode" connection
cred = credentials.Certificate("serviceAccountKey.json")
firebase_admin.initialize_app(cred)

def create_admin():
    print("--- CREATING NEW ADMIN ---")
    email = input("Enter Admin Email: ")
    password = input("Enter Temporary Password (min 6 chars): ")

    try:
        # 1. Create the user in Authentication
        user = auth.create_user(
            email=email,
            password=password,
        )

        # 2. Assign the 'admin' Custom Claim (The Magic Step)
        auth.set_custom_user_claims(user.uid, {'role': 'admin'})

        print(f"✅ Success! Admin created with UID: {user.uid}")
        print("They can now log in to the Dashboard.")

    except Exception as e:
        print(f"❌ Error: {e}")

def delete_admin():
    email = input("Enter Email to DELETE: ")
    try:
        user = auth.get_user_by_email(email)
        auth.delete_user(user.uid)
        print(f" User {email} has been deleted.")
    except Exception as e:
        print(f"❌ Error: {e}")

# Simple Menu
if __name__ == "__main__":
    while True:
        choice = input("\n1. Create Admin\n2. Delete Admin\n3. Exit\nChoose: ")
        if choice == '1':
            create_admin()
        elif choice == '2':
            delete_admin()
        elif choice == '3':
            break