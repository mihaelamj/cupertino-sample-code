/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Main handler for HTTP requests to the server for generating subscription offer signatures.
*/

const express = require('express');
const router = express.Router();

const crypto = require('crypto');
const ECKey = require('ec-key');
const secp256k1 = require('secp256k1');
const uuidv4 = require('uuid/v4');

const KeyEncoder = require('key-encoder');
const keyEncoder = new KeyEncoder('secp256k1');

function getKeyID() {
    /*
        If you have multiple key IDs and apps, implement logic here to choose a key ID based on criteria such as which
        app is requesting a signature. You can also use this function to swap out key IDs if you determine that one of
        your keys has been compromised.

        This key ID was injected into an environment variable in the 'start-server' script using a value you provided.
    */
    return process.env.SUBSCRIPTION_OFFERS_KEY_ID;
}

function getKeyStringForID(keyID) {
    if (keyID === process.env.SUBSCRIPTION_OFFERS_KEY_ID) {
        /*
            This key was injected into an environment variable using the value you provided
            in the 'start-server' script.
        */
        return process.env.SUBSCRIPTION_OFFERS_PRIVATE_KEY;
    }
    else {
        throw "Key ID not recognized";
    }
}

router.get('/offer', function(req, res) {
	/*
        You can add code here to filter the requests or determine if the customer is eligible for this offer,
        based on App Store rules and your own business logic.

        For example, you may want to enable or disable certain bundle IDs, or perform different behavior or
        logging depending on the given bundle ID.
    */

    const appBundleID = req.body.appBundleID;
    const productIdentifier = req.body.productIdentifier;
    const subscriptionOfferID = req.body.offerID;
    const applicationUsername = req.body.applicationUsername;

    /*
        The nonce is a lowercase random UUID string that ensures the payload is unique.
        The App Store checks the nonce when your app starts a transaction with SKPaymentQueue,
        to prevent replay attacks.
    */
    const nonce = uuidv4();
    
    /*
        Get the current time and create a UNIX epoch timestamp in milliseconds.
        The timestamp ensures the signature was generated recently. The App Store also uses this
        information help prevent replay attacks.
    */
    const currentDate = new Date();
    const timestamp = currentDate.getTime();

    /*
        The key ID is for the key generated in App Store Connect that is associated with your account.
        For information on how to generate a key ID and key, see:
        "Generate keys for auto-renewable subscriptions" https://help.apple.com/app-store-connect/#/dev689c93225
    */
    const keyID = getKeyID();

    /*
        Combine the parameters into the payload string to be signed. These are the same parameters you provide
        in SKPaymentDiscount.
    */
	const payload = appBundleID + '\u2063' +
                  keyID + '\u2063' +
                  productIdentifier + '\u2063' +
                  subscriptionOfferID + '\u2063' +
                  applicationUsername  + '\u2063'+
                  nonce + '\u2063' +
                  timestamp;

    // Get the PEM-formatted private key string associated with the Key ID.
    const keyString = getKeyStringForID(keyID);

    // Create an Elliptic Curve Digital Signature Algorithm (ECDSA) object using the private key.
    const key = new ECKey(keyString, 'pem');

    // Set up the cryptographic format used to sign the key with the SHA-256 hashing algorithm.
    const cryptoSign = key.createSign('SHA256');

    // Add the payload string to sign.
    cryptoSign.update(payload);

    /*
        The Node.js crypto library creates a DER-formatted binary value signature,
        and then base-64 encodes it to create the string that you will use in StoreKit.
    */
    const signature = cryptoSign.sign('base64');

    /*
        Check that the signature passes verification by using the ec-key library.
        The verification process is similar to creating the signature, except it uses 'createVerify'
        instead of 'createSign', and after updating it with the payload, it uses `verify` to pass in
        the signature and encoding, instead of `sign` to get the signature.

        This step is not required, but it's useful to check when implementing your signature code.
        This helps debug issues with signing before sending transactions to Apple.
        If verification succeeds, the next recommended testing step is attempting a purchase
        in the Sandbox environment.
    */
    const verificationResult = key.createVerify('SHA256').update(payload).verify(signature, 'base64');
    console.log("Verification result: " + verificationResult)

    // Send the response.
    res.setHeader('Content-Type', 'application/json');
    res.json({ 'keyID': keyID, 'nonce': nonce, 'timestamp': timestamp, 'signature': signature });

});	

module.exports = router;
