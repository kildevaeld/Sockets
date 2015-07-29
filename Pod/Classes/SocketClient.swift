//
//  File.swift
//  Sock
//
//  Created by Rasmus Kildevæld   on 28/07/15.
//  Copyright © 2015 Rasmus Kildevæld  . All rights reserved.
//

import Darwin


public class SocketClient : Socket {
    public var queue          : dispatch_queue_t?  = nil
    public var callbackQueue : dispatch_queue_t = dispatch_get_main_queue()
    var readSource     : dispatch_source_t? = nil
    var sendCount      : Int                = 0
    var closeRequested : Bool               = false
    var readCallback: ((SocketClient, Int) -> Void)?
    var didCloseRead   : Bool               = false
    var _remoteAddress: SocketAddress?
    
    public var remoteAddress: SocketAddress? {
        return _remoteAddress
    }
    // let the socket own the read buffer, what is the best buffer type?
    //var readBuffer     : [CChar] =  [CChar](count: 4096 + 2, repeatedValue: 42)
    var readBufferPtr    = UnsafeMutablePointer<UInt8>.alloc(4096 + 2)
    var readBufferSize : Int = 4096 { // available space, a bit more for '\0'
        didSet {
            if readBufferSize != oldValue {
                readBufferPtr.dealloc(oldValue + 2)
                readBufferPtr = UnsafeMutablePointer<UInt8>.alloc(readBufferSize + 2)
            }
        }
    }
    
    
    var isConnected : Bool {
        return _remoteAddress != nil
    }
    
    public init (socket:sockfd, address: SocketAddress) {
        _remoteAddress = address
        super.init(socket: socket)
    }
    
    public override init(family:SocketFamily, type: SocketType, proto: SocketProtocol = .TCP) throws  {
        try super.init(family: family, type: type, proto: proto)
    }
    
    func connect(address: s_address) throws {
        if self.isConnected {
            throw SocketError.AlreadyConnected
        }
        
        var addr = address
        let fd = self.descriptor!
        
        let rc = withUnsafePointer(&addr) { ptr -> Int32 in
            let bptr = UnsafePointer<sockaddr>(ptr) // cast
            return Darwin.connect(fd, bptr, socklen_t(addr.len))
        }
        
        if rc != 0 {
            let str = String.fromCString(strerror(errno))
            
            throw SocketError.Error(str)
        }
        
        _remoteAddress = address.socketAddress
    }
    
    func connect(address: SocketAddress) throws {
        try self.connect(address.sockaddr!)
    }
    
    func disconnect () {
        self.close()
    }
    
    public func send<T>(buffer: [T], length: Int? = nil) -> Int {
        var writeCount : Int = 0
        let bufsize    = length ?? buffer.count
        let fd         = self.descriptor!
        
        writeCount = Darwin.write(fd, buffer, bufsize)
        return writeCount
    }
    
    public func send<T>(buffer: UnsafePointer<T>, length: Int) -> Int {
        var writeCount : Int = 0
        let fd         = self.descriptor!
        
        writeCount = Darwin.write(fd, buffer, length)
        return writeCount
    }
    
    public func send(string:String) -> Int {
        let str = [UInt8](string.utf8)
        return self.send(str)
    }
    
    public func read() -> ( size: Int, block: UnsafePointer<UInt8>, error: Int32){
        let bptr = UnsafePointer<UInt8>(readBufferPtr)
        if !isValid {
            print("Called read() on closed socket \(self)")
            readBufferPtr[0] = 0
            return ( -42, bptr, EBADF )
        }
        
        var readCount: Int = 0
        let bufsize = readBufferSize
        let fd      = self.descriptor!
        
        // FIXME: If I just close the Terminal which hosts telnet this continues
        //        to read garbage from the server. Even with SIGPIPE off.
        readCount = Darwin.read(fd, readBufferPtr, bufsize)
        if readCount < 0 {
            readBufferPtr[0] = 0
            return ( readCount, bptr, errno )
        }
        
        readBufferPtr[readCount] = 0 // convenience
        return ( readCount, bptr, 0 )
    }
    
    deinit {
        readBufferPtr.dealloc(readBufferSize + 2)
    }
    
    
    /* close */
    
    override public func close() {
        let debugClose = false
        if debugClose { print("closing socket \(self)") }
        if !isValid { // already closed
            if debugClose { print("   already closed.") }
            return
        }
        
        // always shutdown receiving end, should call shutdown()
        // TBD: not sure whether we have a locking issue here, can read&write
        //      occur on different threads in GCD?
        if !didCloseRead {
            if debugClose { print("   stopping events ...") }
            stopEventHandler()
            // Seen this crash - if close() is called from within the readCB?
            readCallback = nil // break potential cycles
            if debugClose { print("   shutdown read channel ...") }
            Darwin.shutdown(self.descriptor!, SHUT_RD);
            
            didCloseRead = true
        }
        
        if sendCount > 0 {
            if debugClose { print("   sends pending, requesting close ...") }
            closeRequested = true
            return
        }
        
        queue = nil // explicitly release, might be a good idea ;-)
        
        if debugClose { print("   super close.") }
        super.close()
    }
    
}

extension SocketClient : OutputStreamType {
    
    var debugAsyncWrites : Bool { return false }
    
    public var canWrite : Bool {
        if !isValid {
            assert(isValid, "Socket closed, can't do async writes anymore")
            return false
        }
        if closeRequested {
            assert(!closeRequested, "Socket is being shutdown already!")
            return false
        }
        return true
    }
    
    
    public func write(string: String) {
        self.send(string)
    }

    
    public func write(data: dispatch_data_t, done:(() -> Void)? = nil) {
        sendCount++
        if debugAsyncWrites {
            print("async send[\(data)]")
        }
        
        // in here we capture self, which I think is right.
        dispatch_write(self.descriptor!, data, queue!) {
            asyncData, error in
            
            if self.debugAsyncWrites {
                print("did send[\(self.sendCount)] data \(data) error \(error)")
            }
            
            self.sendCount = self.sendCount - 1 // -- fails?
            
            if self.sendCount == 0 && self.closeRequested {
                if self.debugAsyncWrites {
                    print("closing after async write ...")
                }
                self.close()
                self.closeRequested = false
            }
            dispatch_async(self.callbackQueue, { () -> Void in
                done?()
            })
            
        }
        
    }
    
    public func asyncWrite<T>(buffer: [T], done: (()->Void)? = nil) -> Bool {
        // While [T] seems to convert to ConstUnsafePointer<T>, this method
        // has the added benefit of being able to derive the buffer length
        if !canWrite { return false }
        
        let writelen = buffer.count
        let bufsize  = writelen * sizeof(T)
        if bufsize < 1 { // Nothing to write ..
            return true
        }
        
        if queue == nil {
            print("No queue set, using main queue")
            queue = dispatch_get_main_queue()
        }
        
        // the default destructor is supposed to copy the data. Not good, but
        // handling ownership is going to be messy
        let asyncData = dispatch_data_create(buffer, bufsize, queue, nil)
        write(asyncData!, done:done)
        
        return true
    }
    
    public func asyncWrite<T>(buffer: UnsafePointer<T>, length:Int, done: (()->Void)? = nil) -> Bool {
        // FIXME: can we remove this dupe of the [T] version?
        if !canWrite { return false }
        
        let writelen = length
        let bufsize  = writelen * sizeof(T)
        if bufsize < 1 { // Nothing to write ..
            return true
        }
        
        if queue == nil {
            print("No queue set, using main queue")
            queue = dispatch_get_main_queue()
        }
        
        // the default destructor is supposed to copy the data. Not good, but
        // handling ownership is going to be messy
        let asyncData = dispatch_data_create(buffer, bufsize, queue, nil)
        write(asyncData!, done:done)
        
        return true
    }
    
    
}

extension SocketClient {
    /*public func read() -> ( size: Int, block: UnsafePointer<CChar>, error: Int32){
        let bptr = UnsafePointer<CChar>(readBufferPtr)
        if !isValid {
            print("Called read() on closed socket \(self)")
            readBufferPtr[0] = 0
            return ( -42, bptr, EBADF )
        }
        
        var readCount: Int = 0
        let bufsize = readBufferSize
        let fd      = self.descriptor!
        
        // FIXME: If I just close the Terminal which hosts telnet this continues
        //        to read garbage from the server. Even with SIGPIPE off.
        readCount = Darwin.read(fd, readBufferPtr, bufsize)
        if readCount < 0 {
            readBufferPtr[0] = 0
            return ( readCount, bptr, errno )
        }
        
        readBufferPtr[readCount] = 0 // convenience
        return ( readCount, bptr, 0 )
    }*/
    public func read(done: (data:UnsafePointer<UInt8>, length: Int) ->Void) {
        self.readCallback = { (soc,_) in
            let data = soc.read()
            done(data: data.block, length: data.size)
        }
        
        self.startEventHandler()
    }
    
    /* setup read event handler */
    
    func stopEventHandler() {
        if readSource != nil {
            dispatch_source_cancel(readSource!)
            readSource = nil // abort()s if source is not resumed ...
        }
    }
    
    func startEventHandler() -> Bool {
        if readSource != nil {
            print("Read source already setup?")
            return true // already setup
        }
        
        /* do we have a queue? */
        
        if queue == nil {
            print("No queue set, using main queue")
            queue = dispatch_get_main_queue()
        }
        
        /* setup GCD dispatch source */
        
        readSource = dispatch_source_create(
            DISPATCH_SOURCE_TYPE_READ,
            UInt(self.descriptor!), // is this going to bite us?
            0,
            queue
        )
        if readSource == nil {
            print("Could not create dispatch source for socket \(self)")
            return false
        }
        readSource?.onEvent({ (_, readCount) -> Void in
            if readCount == 0 {
                return
            }
            if let cb = self.readCallback  {
                cb(self,Int(readCount))
            }
        })
        
        /*readSource!.onEvent { [unowned self] _, readCount in
            if let cb = self.readCallback {
                cb(self,Int(readCount))
            }
        
        }*/
        
        /* actually start listening ... */
        dispatch_resume(readSource!)
        
        return true
    }
}
