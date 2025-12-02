"""
Usage example:

$ python3 generate-token.py {issuer id} {key id} {private key path}
"""

import sys
import datetime
import jwt

def generate(issuer_id, key_id, private_key_path):
    with open(private_key_path) as f:
        key = f.read()

    token_data = jwt.encode(
        {
            'iss': issuer_id,
            'aud': 'appstoreconnect-v1',
            'exp': datetime.datetime.utcnow() + datetime.timedelta(minutes=5)
        },
        key,
        algorithm='ES256',
        headers={
            'kid': key_id
        }
    )
    print(token_data)

if __name__ == "__main__":
    if len(sys.argv) != 4:
        print("usage: generate-token.py {issuer id} {key id} {private key path}", file=sys.stderr)
        exit(-1)

    generate(sys.argv[1], sys.argv[2], sys.argv[3])
