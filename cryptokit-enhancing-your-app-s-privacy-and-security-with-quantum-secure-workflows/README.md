# Enhancing your app's privacy and security with quantum-secure workflows

Use quantum-secure cryptography to protect your app from quantum-computer attacks.

## Overview

Quantum-secure cryptography is based on mathematical operations that are expensive to perform, even for an attacker with access to a quantum computer.
This sample uses round-trip processes — encrypting then decrypting data, or generating a signature then verifying it — to demonstrate how to adopt quantum-secure cryptographic algorithms using [Apple CryptoKit](https://developer.apple.com/documentation/cryptokit/).
In your app, implement the two stages separately; for example, one person might encrypt a message and send it to another person who decrypts it.
The sample demonstrates how to use quantum-secure hybrid public-key encryption (HPKE) to securely share a secret between two people.

For more information, see [Enhancing your app’s privacy and security with quantum-secure workflows](https://developer.apple.com/documentation/cryptokit/enhancing-your-app-s-privacy-and-security-with-quantum-secure-workflows).