//
//  Server.swift
//  Sock
//
//  Created by Rasmus Kildevæld   on 28/07/15.
//  Copyright © 2015 Rasmus Kildevæld  . All rights reserved.
//

import Darwin

func _accept (sock:sockfd, address: SocketAddress) throws -> SocketClient {
    
    
    var baddr    = address.sockaddr!.empty
    var baddrlen = socklen_t(baddr.len)
    
    let newFD = withUnsafeMutablePointer(&baddr) {
        ptr -> Int32 in
        let bptr = UnsafeMutablePointer<sockaddr>(ptr) // cast
        return Darwin.accept(sock, bptr, &baddrlen);// buflenptr)
    }
    
    if newFD == -1 {
        throw SocketError.Error(errorToString())
    }
    
    let client = SocketClient(socket: newFD, address: baddr.socketAddress)
    
    return client
}


public class SocketServer : Socket {
    public var listenSource : dispatch_source_t? = nil
    public var acceptQueue: dispatch_queue_t = dispatch_get_main_queue()
    private var isListening: Bool = false
    
    
    public override init(family:SocketFamily, type: SocketType, proto: SocketProtocol = .TCP) throws {
        try super.init(family: family, type: type, proto: proto)
    }
    
    
    func listen (address: SocketAddress? = nil, backlog: Int32 = 5) throws {
        
        if self.isListening  {
            return
        }
        
        if !self.isBound {
            
            if address == nil {
                throw SocketError.NotBound
            }
            
            try self.bind(address!)
        }
        
        let rc = Darwin.listen(self.descriptor!, backlog)
        
        if rc != 0 {
            throw SocketError.Error(errorToString())
        }
        
        self.isListening = true
        
    }
    
    func listen (backlog: Int32) throws {
        try self.listen(nil, backlog: backlog)
    }
    
    public func accept () throws -> SocketClient  {
        if !self.isListening {
            throw SocketError.NotListening
        }
        
        let client = try _accept(self.descriptor!, address: self.boundAddress!)
        return client
    }
    
    override public func close() {
        if listenSource != nil {
            dispatch_source_cancel(listenSource!)
            listenSource = nil
        }
        super.close()
    }
}


extension SocketServer {
    
    public func listen(address:SocketAddress, backlog: Int32 = 5, accept: (client: SocketClient) -> Void) -> SocketError? {
        var err : SocketError? = nil
        
        
        listenSource = dispatch_source_create(
            DISPATCH_SOURCE_TYPE_READ,
            UInt(self.descriptor!), // is this going to bite us?
            0,
            self.acceptQueue
        )
        
        /*guard let source = listenSource else {
            err = SocketError.Error("Failed to create dispatch source")
        }*/
        let source = listenSource!
        
        let fd = self.descriptor!
        let a = address
        
        source.onEvent { _, _ in
            repeat {
                
                do {
                    let client = try _accept(fd, address: a)
                    client.isSigPipeDisabled = true
                    accept(client: client)
                } catch {
                    
                }
            
                
                
            } while true
        }
        
        dispatch_resume(source)
        
        do {
            try self.listen(address, backlog: backlog)
        }  catch {
            err = error as? SocketError
        }
        
        if err != nil {
            dispatch_source_cancel(listenSource!)
            listenSource = nil
            return err
        }
        
        return err
    }
    
    
    
}


