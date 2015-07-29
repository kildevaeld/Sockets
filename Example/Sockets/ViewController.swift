//
//  ViewController.swift
//  Sockets
//
//  Created by Softshag & Me on 07/29/2015.
//  Copyright (c) 2015 Softshag & Me. All rights reserved.
//

import UIKit
import Sockets

func after(delay: Double, _ fn: () -> Void) {
    let delayTime = dispatch_time(DISPATCH_TIME_NOW,
        Int64(delay * Double(NSEC_PER_SEC)))
    dispatch_after(delayTime, dispatch_get_main_queue()) {
        fn()
    }
}

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        var address: [SocketAddressInfo] = []
        var s: SocketServer?
        do {
            address = try getAddressInfo(nil, port:3000, family: .Inet, type: .Stream, options: SocketAddressInfoOption.Passive)
            s = try SocketServer(family: address.first!.family, type: .Stream)
        } catch {
            
        }
        
        let server = s
        //let server = Socket.listen(address)
        
        
        server?.acceptQueue = dispatch_queue_create("something", DISPATCH_QUEUE_CONCURRENT)
        server?.listen(address.first!.address, accept: { (client) -> Void in
            let bytes = Bytes("Hello client \(client.remoteAddress)")
            client.send(bytes)
            
            let b = client.read()
            
            print(CString(bytes:b.block))
            client.send("Harry")
            
            after(5, { () -> Void in
                client.send("Somethin good")
                client.close()
            })
            
        })
        
        
        let client = Socket.connect(address)
        client?.queue = dispatch_queue_create("read", DISPATCH_QUEUE_CONCURRENT)
        client?.read({ (data, length) -> Void in
            let str = CString(bytes:data)
            print("Go from server \(str)")
        })
        
        
        
        client?.send("Rapper")
        //let data = client?.read()
        //let str = CString(bytes:data!.block)
        //let dd = str.description.dataUsingEncoding(NSUTF8StringEncoding)
        //var bytes = Bytes(void: dd!.bytes, length: dd!.length)
        //print("Got from server \(str)")
        //client?.send(bytes)
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

