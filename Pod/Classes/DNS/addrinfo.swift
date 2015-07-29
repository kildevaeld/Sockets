//
//  addrinfo.swift
//  Sock
//
//  Created by Rasmus Kildevæld   on 27/07/15.
//  Copyright © 2015 Rasmus Kildevæld  . All rights reserved.
//

import Foundation



public protocol s_address {
    static var domain: Int32 { get }
    var socketAddress: SocketAddress { get }
    var len: __uint8_t { get }
    init()
}


extension s_address {
    // Get at empty struct
    var empty: s_address {
        return self.dynamicType()
    }
}

extension addrinfo {
    
    
    public var canonicalName : String? {
        if ai_canonname != nil && ai_canonname[0] != 0 {
            return String.fromCString(ai_canonname)
        }
        return nil
    }
    
    public var hasAddress : Bool {
        return ai_addr != nil
    }
    
    public var isIPv4 : Bool {
        return hasAddress &&
            (ai_addr.memory.sa_family == sa_family_t(sockaddr_in.domain))
    }
    
    public func address<T: s_address>() -> T? {
        if ai_addr == nil {
            return nil
        }
        if ai_addr.memory.sa_family != sa_family_t(T.domain) {
            return nil
        }
        let aiptr = UnsafePointer<T>(ai_addr) // cast
        return aiptr.memory // copies the address to the return value
    }
    
    public func address() -> s_address {
        //let addr: s_address
        
        if self.isIPv4 {
            let a: sockaddr_in = self.address()!
            return a
        } else {
            let a: sockaddr_in6 = self.address()!
            return a
        }
        //return address
    }
    
    public var hasNext : Bool {
        return self.ai_next != nil
    }
    public var next : addrinfo? {
        return self.hasNext ? self.ai_next.memory : nil
    }
    

    public var family: SocketFamily {
        return SocketFamily.fromOption(self.ai_family)
    }
    
}
