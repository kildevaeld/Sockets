# Sockets

[![CI Status](http://img.shields.io/travis/Softshag & Me/Sockets.svg?style=flat)](https://travis-ci.org/Softshag & Me/Sockets)
[![Version](https://img.shields.io/cocoapods/v/Sockets.svg?style=flat)](http://cocoapods.org/pods/Sockets)
[![License](https://img.shields.io/cocoapods/l/Sockets.svg?style=flat)](http://cocoapods.org/pods/Sockets)
[![Platform](https://img.shields.io/cocoapods/p/Sockets.svg?style=flat)](http://cocoapods.org/pods/Sockets)

## Usage

To run the example project, clone the repo, and run `pod install` from the Example directory first.

### AddressInfo

```swift

import Sockets

do {
  let addresses = GetAddressInfo(3000, options: SocketAddressInfoOption.Passive|SocketAddressInfoOption.CanonName)

} catch {
  print("Got error: \(error)")
  exit(1)
}


let server = Sockets.listen(addresses, accept: { (client) -> Void in 
  
  client.send("Hello client \(client.remoteAddress)")
  
  client.read { (data, length)
    let str = CSString(data)
    print("Got from client: \(str)")
  }
  
})



let client = Sockets.connect(addreses)
let data = client.read()

print(CSString(data))

client.send("Hello server")

```

## Requirements

## Installation

Sockets is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod "Sockets"
```

## Author

Softshag & Me, admin@softshag.dk

## License

Sockets is available under the MIT license. See the LICENSE file for more info.
