//
//  in_addr.swift
//  Sock
//
//  Created by Rasmus Kildevæld   on 27/07/15.
//  Copyright © 2015 Rasmus Kildevæld  . All rights reserved.
//

import Foundation


public extension in_addr {
    
    public init() {
        s_addr = INADDR_ANY.s_addr
    }
    
    public init(string: String?) {
        if let s = string {
            if s.isEmpty {
                s_addr = INADDR_ANY.s_addr
            }
            else {
                var buf = INADDR_ANY // Swift wants some initialization
                
                s.withCString { cs in inet_pton(AF_INET, cs, &buf) }
                s_addr = buf.s_addr
            }
        }
        else {
            s_addr = INADDR_ANY.s_addr
        }
    }
    
    public var asString: String {
        if self == INADDR_ANY {
            return "*.*.*.*"
        }
        
        let len   = Int(INET_ADDRSTRLEN) + 2
        var buf   = [CChar](count: len, repeatedValue: 0)
        
        var selfCopy = self // &self doesn't work, because it can be const?
        let cs = inet_ntop(AF_INET, &selfCopy, &buf, socklen_t(len))
        
        return String.fromCString(cs)!
    }
    
}

public func ==(lhs: in_addr, rhs: in_addr) -> Bool {
    return __uint32_t(lhs.s_addr) == __uint32_t(rhs.s_addr)
}

extension in_addr : Equatable, Hashable {
    
    public var hashValue: Int {
        // Knuth?
        return Int(UInt32(s_addr) * 2654435761 % (2^32))
    }
    
}

extension in_addr: StringLiteralConvertible {
    // this allows you to do: let addr : in_addr = "192.168.0.1"
    
    public init(stringLiteral value: StringLiteralType) {
        self.init(string: value)
    }
    
    public init(extendedGraphemeClusterLiteral v: ExtendedGraphemeClusterType) {
        self.init(string: v)
    }
    
    public init(unicodeScalarLiteral value: String) {
        // FIXME: doesn't work with UnicodeScalarLiteralType?
        self.init(string: value)
    }
}

extension in_addr: CustomStringConvertible {
    
    public var description: String {
        return asString
    }
    
}



