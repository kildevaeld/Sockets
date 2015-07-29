//
//  in6_addr.swift
//  Sock
//
//  Created by Rasmus Kildevæld   on 28/07/15.
//  Copyright © 2015 Rasmus Kildevæld  . All rights reserved.
//

import Darwin


extension in6_addr {
    public var asString: String {
        let len   = Int(INET6_ADDRSTRLEN) + 2
        var buf   = [CChar](count: len, repeatedValue: 0)
        
        var selfCopy = self // &self doesn't work, because it can be const?
        let cs = inet_ntop(AF_INET6, &selfCopy, &buf, socklen_t(len))
        
        let addr = String.fromCString(cs)!
        
        return addr
    }
    
    /*static func fromString(string: String) -> in6_addr {
        var buf = IN6ADDR_ANY // Swift wants some initialization
        string.withCString { cs in inet_pton(AF_INET6, cs, &buf) }
        return buf
    }*/
    
    init(string:String) {
        //self = in6_addr.fromString(string)
        var buf = IN6ADDR_ANY // Swift wants some initialization
        string.withCString { cs in inet_pton(AF_INET6, cs, &buf) }
        self = buf
    }
    
}

extension in6_addr: CustomStringConvertible {
    
    public var description: String {
        return asString
    }
    
}
