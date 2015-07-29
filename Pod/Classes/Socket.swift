//
//  Socket.swift
//  Sock
//
//  Created by Rasmus Kildevæld   on 27/07/15.
//  Copyright © 2015 Rasmus Kildevæld  . All rights reserved.
//
import Darwin

public typealias sockfd = Int32

func errorToString (var errorcode: Int32? = nil) -> String {
    if errorcode == nil {
        errorcode = errno
    }
    return String.fromCString(strerror(errorcode!))!
}

public enum SocketError : ErrorType {
    case Error(String?)
    case AlreadyBound
    case NotBound
    case NotListening
    case AlreadyConnected
}

public class Socket {
    
    
    
    public var boundAddress: SocketAddress?
    
    var isBound: Bool  { return boundAddress != nil }
    
    var isValid: Bool { return self.descriptor != nil }
    
    var descriptor: sockfd?
    
    public init(family:SocketFamily, type: SocketType, proto: SocketProtocol = .Any) throws {
        let ret = socket(family.asOption,type.asOption, proto.asOption)
        
        if ret == -1 {
            throw SocketError.Error(errorToString())
        }
        
        self.descriptor = ret
    }
    
    init(socket: sockfd) {
        self.descriptor = socket
    }
    
    public func bind(address:s_address) throws {
        if self.isBound {
            throw SocketError.AlreadyBound
        }
        var addr = address
        let fd = self.descriptor!
        let rc = withUnsafePointer(&addr) { ptr -> Int32 in
            let bptr = UnsafePointer<sockaddr>(ptr) // cast
            return Darwin.bind(fd, bptr, socklen_t(addr.len))
        }
        
        if rc != 0 {
            throw SocketError.Error(errorToString())
        }
    
        self.boundAddress = address.socketAddress
    }
    
    public func bind(address:SocketAddress) throws {
        try self.bind(address.sockaddr!)
    }
    
    deinit {
        self.close()
    }
    
    public func close () {
        
        if self.descriptor != nil {
            Darwin.close(self.descriptor!)
            self.descriptor = nil
        }
    }
    
}



extension Socket { // Socket Flags
    
    /*public var flags : Int32? {
        get {
            let rc = ari_fcntlVi(self.descriptor!, F_GETFL, 0)
            return rc >= 0 ? rc : nil
        }
        set {
            let rc = ari_fcntlVi(self.descriptor!, F_SETFL, Int32(newValue!))
            if rc == -1 {
                println("Could not set new socket flags \(rc)")
            }
        }
    }
    
    public var isNonBlocking : Bool {
        get {
            if let f = flags {
                return (f & O_NONBLOCK) != 0 ? true : false
            }
            else {
                print("ERROR: could not get non-blocking socket property!")
                return false
            }
        }
        set {
            if newValue {
                if let f = flags {
                    flags = f | O_NONBLOCK
                }
                else {
                    flags = O_NONBLOCK
                }
            }
            else {
                flags = flags! & ~O_NONBLOCK
            }
        }
    }*/
    
}


extension Socket { // Socket Options
    
    public var reuseAddress: Bool {
        get { return getSocketOption(SO_REUSEADDR) }
        set { setSocketOption(SO_REUSEADDR, value: newValue) }
    }
    public var isSigPipeDisabled: Bool {
        get { return getSocketOption(SO_NOSIGPIPE) }
        set { setSocketOption(SO_NOSIGPIPE, value: newValue) }
    }
    public var keepAlive: Bool {
        get { return getSocketOption(SO_KEEPALIVE) }
        set { setSocketOption(SO_KEEPALIVE, value: newValue) }
    }
    public var dontRoute: Bool {
        get { return getSocketOption(SO_DONTROUTE) }
        set { setSocketOption(SO_DONTROUTE, value: newValue) }
    }
    public var socketDebug: Bool {
        get { return getSocketOption(SO_DEBUG) }
        set { setSocketOption(SO_DEBUG, value: newValue) }
    }
    
    public var sendBufferSize: Int32 {
        get { return getSocketOption(SO_SNDBUF) ?? -42    }
        set { setSocketOption(SO_SNDBUF, value: newValue) }
    }
    public var receiveBufferSize: Int32 {
        get { return getSocketOption(SO_RCVBUF) ?? -42    }
        set { setSocketOption(SO_RCVBUF, value: newValue) }
    }
    public var socketError: Int32 {
        return getSocketOption(SO_ERROR) ?? -42
    }
    
    /* socket options (TBD: would we use subscripts for such?) */
    
    
    public func setSocketOption(option: Int32, value: Int32) -> Bool {
        if !isValid {
            return false
        }
        
        var buf = value
        let rc  = setsockopt(self.descriptor!, SOL_SOCKET, option, &buf,socklen_t(sizeof(Int32)))
        
        if rc != 0 { // ps: Great Error Handling
            print("Could not set option \(option) on socket \(self)")
        }
        return rc == 0
    }
    
    // TBD: Can't overload optionals in a useful way?
    // func getSocketOption(option: Int32) -> Int32
    public func getSocketOption(option: Int32) -> Int32? {
        if !isValid {
            return nil
        }
        
        var buf    = Int32(0)
        var buflen = socklen_t(sizeof(Int32))
        
        let rc = getsockopt(self.descriptor!, SOL_SOCKET, option, &buf, &buflen)
        if rc != 0 { // ps: Great Error Handling
            print("Could not get option \(option) from socket \(self)")
            return nil
        }
        return buf
    }
    
    public func setSocketOption(option: Int32, value: Bool) -> Bool {
        return setSocketOption(option, value: value ? 1 : 0)
    }
    public func getSocketOption(option: Int32) -> Bool {
        let v: Int32? = getSocketOption(option)
        return v != nil ? (v! == 0 ? false : true) : false
    }
    
}



