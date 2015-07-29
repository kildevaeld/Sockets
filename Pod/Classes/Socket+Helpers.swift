//
//  Socket+Helpers.swift
//  Sock
//
//  Created by Rasmus Kildevæld   on 28/07/15.
//  Copyright © 2015 Rasmus Kildevæld  . All rights reserved.
//

import Darwin
import Dispatch

extension Socket {
    public static func connect(address:SocketAddressInfo) throws -> SocketClient {
        
        let socket = try SocketClient(family: address.family, type: address.type, proto: address.proto)
        
        try socket.connect(address.address)
        
        return socket
        
    }
    
    
    public static func connect(address:[SocketAddressInfo]) -> SocketClient? {
        var socket: SocketClient?
        var lastError: ErrorType?
        for a in address {
            do {
                socket = try self.connect(a)
                break
            } catch {
                socket = nil
                lastError = error
            }
        }
        
        return socket
        
    }
    
    public static func connect(address: SocketAddress, family: SocketFamily, type: SocketType, proto: SocketProtocol = .Any) throws -> SocketClient {
        let socket = try SocketClient(family: family, type: type, proto: proto)
        
        try socket.connect(address)
        
        return socket
    }
    
    public static func listen(address: SocketAddress, family: SocketFamily, type: SocketType, proto: SocketProtocol = .Any) throws -> SocketServer {
        let socket = try SocketServer(family: family, type: type, proto: proto)
        
        try socket.listen(address)
        
        return socket
    }
    
    public static func listen(address:SocketAddressInfo) throws -> SocketServer {
        return try self.listen(address.address, family: address.family, type: address.type, proto: address.proto)
    }
    
    public static func listen(address:[SocketAddressInfo]) -> SocketServer? {
        var socket: SocketServer?
        for a in address {
            do {
                socket = try self.listen(a)
                break
            } catch {
                socket = nil
            }
        }
        
        return socket
    }
}



extension dispatch_source_t {
    
    func onEvent(cb: (dispatch_source_t, CUnsignedLong) -> Void) {
        dispatch_source_set_event_handler(self) {
            let data = dispatch_source_get_data(self)
            cb(self, data)
        }
    }
}
