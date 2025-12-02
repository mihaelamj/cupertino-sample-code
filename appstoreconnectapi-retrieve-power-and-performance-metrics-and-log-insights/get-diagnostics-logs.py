"""
See README.md for help configuring and running this script.
"""

import sys
import datetime
import json
from urllib.parse import urlparse
import http.client
import jwt

########
# KEY CONFIGURATION - Put your API Key info here

ISSUER_ID = "###############################"
KEY_ID = "##############"
PRIVATE_KEY_PATH = "######################"

########
# GET DIAGNOTICS LOGS - This is where the actual API interaction happens
def get_diagnostics_logs(build_id):
    """
    This function does all the real work. It:
        1. Creates an Authorization header value with bearer token (JWT)
        2. Gets disk writes diagnostics signatures by build id
        3. Gets disk writes IO exception logs for the top signature
        4. Pretty-print function callstacks causing disk writes IO exception

        If anything goes wrong during this process the error is reported and the script
        exists with a non-zero status.
    """

    # 1. Create an Authorization header value with bearer token (JWT)
    #    The token is set to expire in 5 minutes, and is used for all App Store
    #    Connect API calls.
    auth_header = f"Bearer {create_token()}"


    print("\nGet top disk writes diagnostic signature and related logs.\n")


    # 2. Gets disk writes IO exception signatures for the app build id
    #    If the build is not released to public, or if there is no disk writes IO exceptions
    #    reported for the build or the app version, report an error and exit.
    diagnostic_signatures = make_http_request(
            "GET",
            f"https://api.appstoreconnect.apple.com/v1/builds/{build_id}/diagnosticSignatures",
            headers={
                "Authorization": auth_header,
            }
        )
    data = json.loads(diagnostic_signatures)['data']
    if data and len(data) > 0:
        top_signature = data[0]
        logs_relationship = top_signature["relationships"]["logs"]
    else:
        die(1, f"no signature was found with build id {build_id}")


    # 3. Gets disk writes IO exception logs for the top signature (limit=5)
    #    If no diagnostic log is found, report an error and exist.
    diagnostic_logs = make_http_request(
            "GET",
            logs_relationship["links"]["related"] + "?limit=5",
            headers={
                "Authorization": auth_header,
                "Accept": "application/vnd.apple.xcode-metrics+json"
            }
        )
    product_data = json.loads(diagnostic_logs)['productData'][0]
    if product_data:
        signature_id = product_data["signatureId"]
    else:
        die(1, "empty diagnostic logs response was returned")
    if product_data and len(product_data['diagnosticLogs']) > 0:
        logs = product_data['diagnosticLogs']
        print("\nGot %s logs to parse"%len(logs))
    else:
        die(1, f"no diagnostic log was found for signature id {signature_id}")


    # 4. Pretty-print function callstack causing high disk writes IO exception
    for log in logs:
        input(green("\nPress Enter to pretty-print callstack.\n"))
        metadata = log['diagnosticMetaData']
        callstack_tree = log['callStackTree'][0]

        print(red("Metadata: %s (%s), %s"%(metadata["deviceType"],
              metadata["osVersion"],
              metadata["appVersion"])))
        print(blue("Detail: %s"%metadata["eventDetail"]))
        print("callStackPerThread: ", callstack_tree["callStackPerThread"])
        print(red("============================================================================="))

        for callstack in callstack_tree["callStacks"]:
            for root_frame in callstack["callStackRootFrames"]:
                preorder_traversal(root_frame, 0)


########
# UI SUPPORT - Code to support pretty-print callstack

def preorder_traversal(frame, indent_level):

    print(" " * 2 * indent_level + frame["rawFrame"])

    if "subFrames" not in frame:
        return

    for subframe in frame["subFrames"]:
        preorder_traversal(subframe, indent_level + 1)

########
# API SUPPORT - Code to support HTTP API calls and logging

def make_http_request(method, url, **kwargs):

    print(green(method), blue(url))

    parsed_url = urlparse(url)
    path_plus_query = parsed_url.path + (f"?{parsed_url.query}" if parsed_url.query else '')

    try:
        connection = http.client.HTTPSConnection(parsed_url.netloc)
        connection.request(method, path_plus_query, **kwargs)
        response = connection.getresponse()
        body = response.read().decode('UTF-8')
    finally:
        if connection:
            connection.close()

    if response.status >= 200 and response.status < 300:
        return body
    else:
        message = "An error occurred calling the App Store Connect API"
        message += "\nStatus:" + str(response.status)
        if "x-request-id" in response.headers.keys():
            message += "\nRequest ID:" + response.headers['x-request-id']
        message += "\nResponse:\n" + body
        die(3, message)


def create_token():
    """
    Creates a token that lives for 5 minutes, which should be long enough
    to download metrics and diagnostics reports. In a long-running script you should adjust
    the code to issue a new token periodically.
    """
    if PRIVATE_KEY_PATH == "XXXXXXXXXX":
        die(-2, "You need to configure your key information at the top of the file first.")

    with open(PRIVATE_KEY_PATH) as f:
        key = f.read()

    expiry = datetime.datetime.utcnow() + datetime.timedelta(minutes=5)
    token_data = jwt.encode(
        {
            'iss': ISSUER_ID,
            'aud': 'appstoreconnect-v1',
            'exp': expiry
        },
        key,
        algorithm='ES256',
        headers={
            'kid': KEY_ID
        }
    )
    return token_data


def die(status, message):
    print(red(message), file=sys.stderr)
    sys.exit(status)


########
# TEXT COLORS - Functions to color text for pretty output
def red(text):
    return f"\033[91m{text}\033[0m"

def green(text):
    return f"\033[92m{text}\033[0m"

def blue(text):
    return f"\033[94m{text}\033[0m"


########
# ENTRY POINT
if __name__ == "__main__":
    if len(sys.argv) != 2:
        die(-1, "usage: python3 get-diagnostics-logs.py {buildId}")
    get_diagnostics_logs(sys.argv[1])
