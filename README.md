# Nanozap

## TLDR:
Nanozap is a light GUI client to be used with a private, fully validating LND lightning node.

## Setup
Nanozap uses Cocoapods for dependencies:
 1. `sudo gem install cocoapods`
 2. `pod install`
 3. open the project using the .xcworkspace file
 
## Secrets
To use this app, it needs to be able to talk to your LND process.

To do this, 3 thinks are needed:

- hostname: {ip|dns}:port, e.g. 1.2.3.4:10009 or mynode.lightning.org:10009

- Certificate from your node, signed with the address you are connecting via.
  - lnd option `--tlsextraip=[externalIP]` could be useful here.

- The security token, called macaroon.

To load these into the app, the easiest is to generate a qr code from them and take a photo with your phone.
This way the secrets never leave your devices.

Example using qrencode to generate images:

```brew install qrencode

qrencode -o macaroon.png $(base64 -i ~/.lnd/admin.macaroon | tr -d '\n')
qrencode -o cert.png ~/.lnd/tls.cert
``` 

Go to settings in the app and take a photo of them.

Try go to the homescreen and check if your balance shows.

## Fastlane
Use fastlane for building and testing:
`sudo gem install fastlane -NV`
`fastlane test`

