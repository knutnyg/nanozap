# Nanozap

## TLDR:
Nanozap is a light GUI client to be used with an external LND lightning node.

## Setup
Nanozap uses Cocoapods for dependencies:
 1. `sudo gem install cocoapods`
 2. `pod install`
 3. open the project using the .xcworkspace file
 
## Secrets
For now Nanozap expects to find your `admin.macaroon` and `tls.cert` in the project. These are used for authenticating requests to your LND node. Copy these files into the project. They are typically located at `~/.lnd/`


