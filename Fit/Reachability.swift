//
//  Reachability.swift
//  POW
//
//  Created by Gabriela Villalobos on 26.07.17.
//  Copyright © 2017 Apple. All rights reserved.
//

import Foundation
import SystemConfiguration

// Internet Vaidation Helper...
public class Reachability {
    
    struct globalVariables {
        static var internetConnection = false
    }
    
    @objc public func isInternetAvailable() -> Bool
    {
        var zeroAddress = sockaddr_in()
        zeroAddress.sin_len = UInt8(MemoryLayout.size(ofValue: zeroAddress))
        zeroAddress.sin_family = sa_family_t(AF_INET)
        
        let defaultRouteReachability = withUnsafePointer(to: &zeroAddress) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {zeroSockAddress in
                SCNetworkReachabilityCreateWithAddress(nil, zeroSockAddress)
            }
        }
        
        var flags = SCNetworkReachabilityFlags()
        if !SCNetworkReachabilityGetFlags(defaultRouteReachability!, &flags) {
            return false
        }
        let isReachable = flags.contains(.reachable)
        let needsConnection = flags.contains(.connectionRequired)
        
        globalVariables.internetConnection = isReachable && !needsConnection
        return globalVariables.internetConnection
    }
    
}
