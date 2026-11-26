"""Run locally with administrator Application Default Credentials, never in the app."""
import argparse
from firebase_admin import initialize_app, auth

parser = argparse.ArgumentParser(description='Assign a verified doctor role in your Firebase project.')
parser.add_argument('uid')
parser.add_argument('--project', required=True)
args = parser.parse_args()
initialize_app(options={'projectId': args.project})
user = auth.get_user(args.uid)
auth.set_custom_user_claims(args.uid, {**(user.custom_claims or {}), 'role': 'doctor'})
print('Doctor role assigned. Sign out and back in to refresh the account token.')
