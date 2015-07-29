//
//  socket_addr.swift
//  Sock
//
//  Created by Rasmus Kildevæld   on 27/07/15.
//  Copyright © 2015 Rasmus Kildevæld  . All rights reserved.
//

import Foundation

let INADDR_ANY = in_addr(s_addr: 0)
let IN6ADDR_ANY = in6_addr()

extension sockaddr_in : s_address {
    public static var domain = AF_INET
    
    public var socketAddress: SocketAddress {
        get {
            return SocketAddress.IP4(address: self.address.asString, port: Port(self.port))
        }
    }
    
    public static var size   = __uint8_t(sizeof(sockaddr_in))
    public init() {
        sin_len    = sockaddr_in.size
        sin_family = sa_family_t(sockaddr_in.domain)
        sin_port   = 0
        sin_addr   = INADDR_ANY
        sin_zero   = (0,0,0,0,0,0,0,0)
    }
    
    public init(address: in_addr = INADDR_ANY, port: Int?) {
        self.init()
        
        sin_port = port != nil ? in_port_t(htons(CUnsignedShort(port!))) : 0
        sin_addr = address
    }
    
    public init(address: String?, port: Int?) {
        let isWildcard = address != nil
            ? (address! == "*" || address! == "*.*.*.*")
            : true;
        let ipv4       = isWildcard ? INADDR_ANY : in_addr(string: address)
        self.init(address: ipv4, port: port)
    }
    
    public init(string: String?) {
        if let s = string {
            if s.isEmpty {
                self.init(address: INADDR_ANY, port: nil)
            }
            else {
                // split string at colon
                let comps = s.componentsSeparatedByString(":")
                if comps.count == 2 {
                    self.init(address: comps[0], port: Int(comps[1]))
                }
                else {
                    assert(comps.count == 1)
                    let c1 = comps[0]
                    let isWildcard = (c1 == "*" || c1 == "*.*.*.*")
                    if isWildcard {
                        self.init(address: nil, port: nil)
                    }
                    else if let port = Int(c1) { // it's a number
                        self.init(address: nil, port: port)
                    }
                    else { // it's a host
                        self.init(address: c1, port: nil)
                    }
                }
            }
        }
        else {
            self.init(address: INADDR_ANY, port: nil)
        }
    }
    
    public var port: Int { // should we make that optional and use wildcard as nil
        get {
            return Int(ntohs(sin_port))
        }
        set {
            sin_port = in_port_t(htons(CUnsignedShort(newValue)))
        }
    }
    
    public var address: in_addr {
        return sin_addr
    }
    
    public var isWildcardPort:    Bool { return sin_port == 0 }
    public var isWildcardAddress: Bool { return sin_addr == INADDR_ANY }
    
    public var len: __uint8_t { return sockaddr_in.size }
    
    public var asString: String {
        let addr = address.asString
        return isWildcardPort ? addr : "\(addr):\(port)"
    }
}

public func == (lhs: sockaddr_in, rhs: sockaddr_in) -> Bool {
    return (lhs.sin_addr.s_addr == rhs.sin_addr.s_addr)
        && (lhs.sin_port        == rhs.sin_port)
}

extension sockaddr_in: Equatable, Hashable {
    
    public var hashValue: Int {
        return sin_addr.hashValue + sin_port.hashValue
    }
    
}



extension sockaddr_in6: s_address {
    
    public static var domain = AF_INET6
    public static var size   = __uint8_t(sizeof(sockaddr_in6))
    
    public var socketAddress: SocketAddress {
        get {
            return SocketAddress.IP6(address: self.address.asString, port: Port(self.port))
        }
    }

    
    
    public init() {
        sin6_len      = sockaddr_in6.size
        sin6_family   = sa_family_t(sockaddr_in6.domain)
        sin6_port     = 0
        sin6_flowinfo = 0
        sin6_addr     = IN6ADDR_ANY
        sin6_scope_id = 0
    }
    
    public init(address: in6_addr = IN6ADDR_ANY, port: Port?) {
        self.init()
        
        sin6_port = port != nil ? in_port_t(htons(CUnsignedShort(port!))) : 0
        sin6_addr = address
    }
    
    public init(string: String?) {
        if let s = string {
            if s.isEmpty {
                self.init(address: IN6ADDR_ANY, port: nil)
            }
            else {
                
                let isWildcard = (s == "*" || s == "*.*.*.*")
                if isWildcard {
                    self.init(address: nil, port: nil)
                }
                else if let port = Port(s) { // it's a number
                    self.init(address: nil, port: port)
                }
                else { // it's a host
                    self.init(address: s, port: nil)
                }
            }
        }
        else {
            self.init(address: IN6ADDR_ANY, port: nil)
        }
    }
    
    public init(address: String?, port: Port?) {
        let isWildcard: Bool = address != nil
            ? address! == "::"
            : true;
        let ipv6 = isWildcard ? IN6ADDR_ANY : in6_addr(string: address!)
    
        self.init(address: ipv6, port: port)
    }
    
    
    public var port: Int {
        get {
            return Int(ntohs(sin6_port))
        }
        set {
            sin6_port = in_port_t(htons(CUnsignedShort(newValue)))
        }
    }
    
    public var address: in6_addr {
        return self.sin6_addr
    }
    
    public var isWildcardPort: Bool { return sin6_port == 0 }
    public var len: __uint8_t { return sockaddr_in6.size }
    
    public var asString: String {
        
        
        let len   = Int(INET6_ADDRSTRLEN) + 2
        var buf   = [CChar](count: len, repeatedValue: 0)
        
        var selfCopy = self // &self doesn't work, because it can be const?
        let cs = inet_ntop(AF_INET6, &selfCopy, &buf, socklen_t(len))
        
        let addr = String.fromCString(cs)!
        return isWildcardPort ? addr : "\(addr):\(port)"
    }

}

extension sockaddr_in6: CustomStringConvertible {
    public var description: String {
        return "IP6(" + asString + ")"
    }
}


extension sockaddr_un : s_address {
    public var asString: String {
        var path = self.sun_path
        let name = withUnsafePointer(&path) {
            String.fromCString(UnsafePointer($0))!
        }
        
        return name
    }
    
    public init() {
        sun_family      = sa_family_t(sockaddr_un.domain)
        sun_len         = sockaddr_un.size
        sun_path        = (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0) as (Int8,Int8,Int8,Int8,Int8,Int8,Int8,Int8,Int8,Int8,Int8,Int8,Int8,Int8,Int8,Int8,Int8,Int8,Int8,Int8,Int8,Int8,Int8,Int8,Int8,Int8,Int8,Int8,Int8,Int8,Int8,Int8,Int8,Int8,Int8,Int8,Int8,Int8,Int8,Int8,Int8,Int8,Int8,Int8,Int8,Int8,Int8,Int8,Int8,Int8,Int8,Int8,Int8,Int8,Int8,Int8,Int8,Int8,Int8,Int8,Int8,Int8,Int8,Int8,Int8,Int8,Int8,Int8,Int8,Int8,Int8,Int8,Int8,Int8,Int8,Int8,Int8,Int8,Int8,Int8,Int8,Int8,Int8,Int8,Int8,Int8,Int8,Int8,Int8,Int8,Int8,Int8,Int8,Int8,Int8,Int8,Int8,Int8,Int8,Int8,Int8,Int8,Int8,Int8)
        
    }
    
    public init(string:String) {
        self.init()
    
        var l = self.sun_path
        var s = self
        
        let len = Int(sizeofValue(s.sun_path))
        
        let str = CString(string)
        bcopy(str.buffer, &l, len)
        self.sun_path = l
        
    }
    
    public static var domain = AF_UNIX
    
    public var socketAddress: SocketAddress {
        get {
            return SocketAddress.Unix(self.asString)
        }
    }
    
    public static var size   = __uint8_t(sizeof(sockaddr_in))
    
    public var len: __uint8_t { return sockaddr_in.size }
}

extension sockaddr_un: CustomStringConvertible {
    public var description: String {
        return "Unix(" + asString + ")"
    }
}