//
//  IP.swift
//  Sock
//
//  Created by Rasmus Kildevæld   on 26/07/15.
//  Copyright © 2015 Rasmus Kildevæld  . All rights reserved.
//

import Darwin

func ntohs(value: CUnsignedShort) -> CUnsignedShort {
    // hm, htons is not a func in OSX and the macro is not mapped
    return (value << 8) + (value >> 8);
}
let htons = ntohs // same thing, swap bytes :-)

public typealias Port = Int32


public final class CString {
    private let _len: Int
    public var count: Int {
        return _len
    }
    public let buffer: UnsafeMutablePointer<Int8>
    
    public init(_ string: String) {
        (_len, buffer) = string.withCString {
            let len = Int(strlen($0) + 1)
            let dst = strcpy(UnsafeMutablePointer<Int8>.alloc(len), $0)
            return (len, dst)
            
        }
    }
    
    public init(bytes: UnsafeMutablePointer<UInt8>) {
        let cast = UnsafeMutablePointer<Int8>(bytes)
        _len = Int(strlen(cast) + 1)
        buffer = strcpy(UnsafeMutablePointer<Int8>.alloc(_len), cast)
    }
    
    public init(bytes: UnsafePointer<UInt8>) {
        let cast = UnsafeMutablePointer<Int8>(bytes)
        _len = Int(strlen(cast) + 1)
        buffer = strcpy(UnsafeMutablePointer<Int8>.alloc(_len), cast)
    }
    
    public init(bytes: UnsafeMutablePointer<Int8>) {
        _len = Int(strlen(bytes) + 1)
        buffer = strcpy(UnsafeMutablePointer<Int8>.alloc(_len), bytes)
    }
    
    public init(bytes: UnsafePointer<Int8>) {
        _len = Int(strlen(bytes) + 1)
        buffer = strcpy(UnsafeMutablePointer<Int8>.alloc(_len), bytes)
    }
    
    deinit {
        buffer.dealloc(_len)
    }
}

extension CString : CustomStringConvertible {
    public var description: String {
        return String.fromCString(self.buffer)!
    }
}

/*extension CString: StringLiteralConvertible {
    // this allows you to do: let addr : in_addr = "192.168.0.1"
    
    public convenience init(stringLiteral value: StringLiteralType) {
        self.init(value)
    }
    
    public convenience init(extendedGraphemeClusterLiteral v: ExtendedGraphemeClusterType) {
        self.init(v)
    }
    
    public convenience init(unicodeScalarLiteral value: String) {
        // FIXME: doesn't work with UnicodeScalarLiteralType?
        self.init(value)
    }
}*/

// An array of C-style strings (e.g. char**) for easier interop.
class CStringArray {
    // Have to keep the owning CString's alive so that the pointers
    // in our buffer aren't dealloc'd out from under us.
    private let _strings: [CString]
    var pointers: [UnsafeMutablePointer<Int8>]
    
    init(_ strings: [String]) {
        _strings = strings.map { CString($0) }
        pointers = _strings.map { $0.buffer }
        // NULL-terminate our string pointer buffer since things like
        // exec*() and posix_spawn() require this.
        pointers.append(nil)
    }
}

