//
//  Types.swift
//  Sock
//
//  Created by Rasmus Kildevæld   on 28/07/15.
//  Copyright © 2015 Rasmus Kildevæld  . All rights reserved.
//
import Darwin


public enum SocketFamily  {
    static func fromOption (option:Int32) -> SocketFamily {
        switch option {
        case AF_UNSPEC: return .Unspecified
        case AF_INET: return .Inet
        case AF_INET6: return .Inet6
        case AF_UNIX: return .Unix
        default: return .Unspecified
        }
    }
    var asOption: Int32 {
        switch self {
        case .Unspecified: return AF_UNSPEC
        case .Inet: return AF_INET
        case .Inet6: return AF_INET6
        case .Unix: return AF_UNIX
        }
    }
    
    case Unspecified
    case Unix
    case Inet
    case Inet6
    
}

extension SocketFamily: CustomStringConvertible {
    public var description: String {
        switch self {
        case .Unix: return "Unix"
        case .Inet: return "Inet"
        case .Inet6: return "Inet6"
        case .Unspecified: return "Unspecified"
        }
    }
}

public enum SocketType {
    static func fromOption (option:Int32) -> SocketType {
        switch option {
        case SOCK_DGRAM: return .Datagram
        case SOCK_STREAM: return .Stream
        case SOCK_RAW: return .Raw
        default: return .Unknown
        }
    }
    var asOption: Int32 {
        switch self {
        case .Stream: return SOCK_STREAM
        case .Datagram: return SOCK_DGRAM
        case .Raw: return SOCK_RAW
        case .Unknown: return -1
        }
    }
    case Stream
    case Datagram
    case Raw
    case Unknown
}

public enum SocketAddress {
    case IP6(address:String, port:Port)
    case IP4(address:String, port:Port)
    case Unix(String)
    
    
}

extension SocketAddress : CustomStringConvertible {
    public var description: String {
        switch self {
        case let IP4(address, port):
            return "\(address):\(port)"
        case let IP6(address, port):
            return "\(address):\(port)"
        case let Unix(path):
            return path
        }
    }
    
    var sockaddr: s_address? {
        switch self {
        case let IP4(address, port):
            return sockaddr_in(address: address, port: Int(port))
        case let IP6(address,port):
            return sockaddr_in6(address: address, port: port)
        case let Unix(address):
            return sockaddr_un(string: address)
        }
    }
    
    init?(inet:sockaddr_in) {
        self = SocketAddress.IP4(address: inet.address.asString,port: Port(inet.port))
    }
    
    init?(inet6:sockaddr_in6) {
        self = SocketAddress.IP6(address: inet6.address.asString, port: Port(inet6.port))
    }
    
    init?(unix:sockaddr_un) {
        self = SocketAddress.Unix(unix.asString)
    }
    
    init?(address:s_address) {
        self = address.socketAddress
    }
    
}

public enum SocketProtocol {
    case TCP
    case UDP
    case RM
    case Any
}

extension SocketProtocol {
    public static func fromOption(option:Int32) -> SocketProtocol {
        switch option {
        case 6: return .TCP
        case 17: return .UDP
        case 113: return .RM
        case 0: return .Any
        default: return .Any
        }
    }
    
    public var asOption: Int32 {
        switch self {
        case .TCP: return 6
        case .UDP: return 17
        case .RM: return 113
        case .Any: return 0
        }
    }
}
