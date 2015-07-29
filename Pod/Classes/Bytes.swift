//
//  Bytes.swift
//  Sock
//
//  Created by Rasmus Kildevæld   on 29/07/15.
//  Copyright © 2015 Rasmus Kildevæld  . All rights reserved.
//

import Darwin
import Foundation
public protocol ByteConvertible {
    func toBytes() -> Bytes
    init(_ bytes: Bytes)
}

public class Bytes {
    private var _len: Int
    public var count: Int {
        return _len
    }
    public var buffer: UnsafeMutablePointer<UInt8>
    init() {
        _len = 0
        self.buffer = UnsafeMutablePointer.alloc(_len)
    }
    
    public init(bytes: UnsafeMutablePointer<UInt8>, length: Int) {
        let b = UnsafeMutablePointer<UInt8>.alloc(length)
        b.initializeFrom(bytes, count: length)
        self.buffer = b
        self._len = length
    }
    
    public convenience init(_ bytes: ByteConvertible) {
        self.init(bytes.toBytes())
    }
    
    public init(void: UnsafeMutablePointer<Void>, length: Int) {
        let b = UnsafeMutablePointer<UInt8>(void)
        self.buffer = b
        self._len = length
    }
    
    public init(void: UnsafePointer<Void>, length: Int) {
        let b = UnsafeMutablePointer<UInt8>(void)
        self.buffer = b
        self._len = length
    }
    
    public init(_ bytes: Bytes) {
        let buf = UnsafeMutablePointer<UInt8>.alloc(bytes.count)
        bcopy(bytes.buffer,buf, bytes.count)
        self.buffer = buf
        _len = bytes.count
    }
    
    public init(_ bytes: [UInt8]) {
        let buf = UnsafeMutablePointer<UInt8>.alloc(bytes.count)
        (0..<bytes.count).map { buf[$0] = bytes[$0] }
        self.buffer = buf
        _len = bytes.count
    }
    
    func write (bytes: ByteConvertible) {
        self.write(bytes.toBytes())
        
    }
    
    func write (bytes:Bytes) {
        let len = self.count + bytes.count
        
        let buf = UnsafeMutablePointer<UInt8>.alloc(len)
        buf.moveInitializeFrom(self.buffer, count: len)
        let b = buf.advancedBy(self.count - 1)
        bcopy(bytes.buffer, b, bytes.count)
        self.buffer.dealloc(_len)
        
        self.buffer = buf
        _len = len
    }
    
    public var UInt8Array: [UInt8] {
        var a = [UInt8](count: self.count, repeatedValue: 0)
        var index = 0;
        while index < self.count {
            a[index] = self.buffer[index++]
        }
        return a
    }
    public var copy: Bytes {
        return Bytes(bytes:self.buffer, length: self.count)
    }
    
    deinit {
        self.buffer.dealloc(_len)
    }
    
}


extension String : ByteConvertible {
    public func toBytes () -> Bytes {
        let cs = CString(self)
        let cast = UnsafeMutablePointer<UInt8>(cs.buffer)
        return Bytes(bytes: cast , length: cs.count)
    }
    
    public init(_ bytes: Bytes) {
        let cast = UnsafeMutablePointer<Int8>(bytes.buffer)
        let str = String.fromCString(cast)
        self = ""
        if str != nil {
            self = str!
        }
    }
    
}

extension SocketClient {
    public func send(bytes: Bytes) -> Bool {
        let int = self.send(bytes.UInt8Array, length: bytes.count)
        return int == bytes.count
    }
}





