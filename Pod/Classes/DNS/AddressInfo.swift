//
//  AddressInfo.swift
//  Sock
//
//  Created by Rasmus Kildevæld   on 27/07/15.
//  Copyright © 2015 Rasmus Kildevæld  . All rights reserved.
//

import Darwin

public enum AddressInfoError : ErrorType, CustomStringConvertible {
    init(option: Int32) {
        switch option {
        case EAI_ADDRFAMILY: self = .AddressFamily
        case EAI_AGAIN: self = .Again
        case EAI_BADFLAGS: self = .BadFlags
        case EAI_BADHINTS: self = .BadHints
        case EAI_FAIL: self = .Fail
        case EAI_FAMILY: self = .Family
        case EAI_MAX: self = .Max
        case EAI_MEMORY: self = .Memory
        case EAI_NODATA: self = .NoData
        case EAI_NONAME: self = .NoName
        case EAI_OVERFLOW: self = .Overflow
        case EAI_PROTOCOL: self = .Protocol
        case EAI_SERVICE: self = .Service
        case EAI_SOCKTYPE: self = .SocketType
        case EAI_SYSTEM: self = .System
        default: self = .Unknown("unknown error \(option)")
            
        }
    }
    
    var asOption: Int32 {
        switch self {
        case .AddressFamily: return EAI_ADDRFAMILY
        case .Again: return EAI_AGAIN
        case .BadFlags: return EAI_BADFLAGS
        case .BadHints: return EAI_BADHINTS
        case .Fail: return EAI_FAIL
        case .Family: return EAI_FAMILY
        case .Max: return EAI_MAX
        case .Memory: return EAI_MEMORY
        case .NoData: return EAI_NODATA
        case .NoName: return EAI_NONAME
        case .Overflow: return EAI_OVERFLOW
        case .Protocol: return EAI_PROTOCOL
        case .Service: return EAI_SERVICE
        case .SocketType: return EAI_SOCKTYPE
        case .System: return EAI_SYSTEM
        case .Unknown(let _): return -1
        }
    }
    
    case AddressFamily
    case Again
    case BadFlags
    case BadHints
    case Fail
    case Family
    case Memory
    case NoData
    case Max
    case NoName
    case Overflow
    case Protocol
    case Service
    case SocketType
    case System
    case Unknown(String)
    
    public var description: String {
        let str: String
        
        switch self {
        case .Unknown(let val):
            str = val
        default:
            str = String.fromCString(gai_strerror(self.asOption))!
        }
        
        return str
    }
}


public struct SocketAddressInfoOption : RawOptionSetType, BooleanType {
    private var value: UInt = 0
    //let rawValue: UInt
    public init(nilLiteral: ()) { self.value = 0 }
    public init(_ value: UInt = 0) { self.value = value }
    public init(rawValue value: UInt) { self.value = value }
    public var boolValue: Bool { return value != 0 }
    public var rawValue: UInt { return value }
    public static var allZeros: SocketAddressInfoOption { return self(0) }
    
    public static var None: SocketAddressInfoOption         { return self(0) }
    public static var CanonName: SocketAddressInfoOption    { return self(UInt(AI_CANONNAME)) }
    public static var Passive: SocketAddressInfoOption      { return self(UInt(AI_PASSIVE)) }
    public static var V4Mapped: SocketAddressInfoOption      { return self(UInt(AI_V4MAPPED)) }
    public static var NumericHost: SocketAddressInfoOption      { return self(UInt(AI_NUMERICHOST)) }
    public static var NumericServer: SocketAddressInfoOption  { return self(UInt(AI_NUMERICSERV)) }
    // ...
}


public struct SocketAddressInfo : CustomStringConvertible {
    public let type: SocketType
    public let proto: SocketProtocol
    public let family: SocketFamily
    public let address: SocketAddress
    public let canonicalName: String?
    
    public var description: String {
        return "[family: \(family), address: \(address), canonicalName: \(canonicalName), protocol: \(proto)]"
    }
    
}


public func getAddressInfo(port: Port, family: SocketFamily = .Unspecified, type: SocketType = .Stream) throws -> [SocketAddressInfo] {
    return try getAddressInfo(nil, port: port, family: family, type: type)
}

public func getAddressInfo(host: String?, port:Port?=nil, family: SocketFamily = .Unspecified, type: SocketType = .Stream, options: SocketAddressInfoOption = SocketAddressInfoOption.CanonName) throws -> [SocketAddressInfo] {
    
    var hints: addrinfo = addrinfo()
    var info = UnsafeMutablePointer<addrinfo>(nil)

    hints.ai_family = family.asOption
    hints.ai_socktype = type.asOption
    hints.ai_flags = Int32(options.rawValue)
    let p: CString? = port != nil ? CString(String(port!)) : nil
    let h: CString? = host != nil ? CString(host!) : nil
    
    var status: Int32 = -1
    
    if h != nil && p != nil {
        status = getaddrinfo(h!.buffer, p!.buffer, &hints, &info)
    } else if h != nil && p == nil {
        status = getaddrinfo(h!.buffer, nil, &hints, &info)
    } else if h == nil && p != nil {
        status = getaddrinfo(nil, p!.buffer, &hints, &info)
    } else if h == nil && p == nil {
        throw AddressInfoError.Unknown("either specify host or port")
    }
    
    if status != 0 {
        throw AddressInfoError(option: status)
    }
   
    var addresses: [SocketAddressInfo] = []
    
    var next: addrinfo? = info.memory
    while next != nil {
        
        let canon = next!.canonicalName
        let proto = SocketProtocol.fromOption(next!.ai_protocol)
        let type = SocketType.fromOption(next!.ai_socktype)
        let a = next!.address()
        
        let address = SocketAddressInfo(type:type, proto: proto, family: next!.family, address: a.socketAddress, canonicalName: canon)
        
        addresses.append(address)
        
        next = next!.next
        
    }
    
    freeaddrinfo(info)
    
    
    return addresses
}


