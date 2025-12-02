"""
See README.md for help configuring and running this script.
"""

import sys
import datetime
from urllib.parse import urlparse
import http.client
import json
import jwt

########
# KEY CONFIGURATION - Put your API Key info here

ISSUER_ID = "###############################"
KEY_ID = "##############"
PRIVATE_KEY_PATH = "######################"

########
# GET METRICS INSIGHTS - This is where the actual API interaction happens
def get_metrics_insights(app_id):
    """
    This function does all the real work. It:
        1. Creates an Authorization header value with bearer token (JWT)
        2. Gets power & performance metrics for the app by app ID
        3. Parse insights and relevant metrics
        4. Pretty-print egregious metrics datasets

        If anything goes wrong during this process the error is reported and the script
        exists with a non-zero status.
    """

    # 1. Create an Authorization header value with bearer token (JWT)
    #    The token is set to expire in 5 minutes, and is used for all App Store
    #    Connect API calls.
    auth_header = f"Bearer {create_token()}"


    print("Find egregious metrics datasets.")


    # 2. Gets power & performance metrics for the app by app ID
    #    If the app or insights are not found, report an error and exit.
    metrics_response = make_http_request(
            "GET",
            f"https://api.appstoreconnect.apple.com/v1/apps/{app_id}/perfPowerMetrics",
            headers={
                "Authorization": auth_header,
                "Accept": "application/vnd.apple.xcode-metrics+json"
            }
        )
    product_data = json.loads(metrics_response)['productData']
    insights = json.loads(metrics_response)['insights']
    if insights:
        regressions = insights["regressions"]
    else:
        die(1, f"no regression insight found with app ID {app_id}")

    for regression in regressions:
        print(red("\ninsight regression:\n" + blue(regression["summaryString"])))

        # 3. Parse insights and relevant metrics and datasets
        #    If no metrics datasets are found, report an error and exit.
        metric_name = regression["metric"]
        target_datasets = regression["populations"]

        parsed_metric = None
        for report in product_data:
            for category in report["metricCategories"]:
                for metric in category["metrics"]:
                    if metric["identifier"] == metric_name:
                        parsed_metric = metric
        parsed_datasets = list()
        if parsed_metric:
            unit = parsed_metric["unit"]["displayName"]
            for target_dataset in target_datasets:
                device = target_dataset["device"]
                percentile = target_dataset["percentile"]
                for dataset in parsed_metric["datasets"]:
                    criteria = dataset["filterCriteria"]
                    if criteria["device"] == device and criteria["percentile"] == percentile:
                        parsed_datasets.append(dataset)
        else:
            die(1, "no metrics datasets matching the regression insight")

        # 4. Pretty-print egregious metrics datasets
        #
        print(red("============================================================================="))
        for dataset in parsed_datasets:
            criteria = dataset["filterCriteria"]
            points = dataset["points"]

            print(green("\n %s (%s), %s, %s"%(
                metric_name,
                unit,
                criteria["deviceMarketingName"],
                criteria["percentile"])))
            version_row = "version      | "
            value_row =   "value        | "
            margin_row =  "error margin | "
            for point in points:
                version_pad = " " * max(len(str(point["value"])) - len(point["version"]), 0)
                value_pad = " " * max(len(point["version"]) - len(str(point["value"])), 0)
                margin_pad = " " * max(len(str(point["value"])), len(point["version"]))

                version_row += point["version"] + version_pad + " | "
                value_row += str(point["value"]) + value_pad + " | "
                if "errorMargin" in point:
                    margin_row += str(point["errorMargin"]) + margin_pad[:-len(str(point["errorMargin"]))] + " | "
                else:
                    margin_row +=  margin_pad + " | "
            print(version_row + "\n" + value_row + "\n" + margin_row)



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
    to download metrics & diagnostics reports. In a long-running script you should adjust
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
        die(-1, "usage: python3 get-metrics-insights.py {appId}")
    get_metrics_insights(sys.argv[1])
