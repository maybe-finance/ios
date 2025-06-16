//
//  Data+Extensions.swift
//  Maybe
//
//  Created by Josh Pigford on 6/13/25.
//

import Foundation

// MARK: - Extensions
extension Data {
    func base64URLEncodedString() -> String {
        return base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
}