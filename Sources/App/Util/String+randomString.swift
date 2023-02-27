//
//  String+randomString.swift
//
//
//  Created by Ralph Küpper on 02/27/2023.
//

import Foundation

public extension String {
    static func randomString(length: Int) -> String {
        let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0 ..< length).map { _ in letters.randomElement()! })
    }

    static func randomStringSmall(length: Int) -> String {
        let letters = "abcdefghijklmnopqrstuvwxyz0123456789"
        return String((0 ..< length).map { _ in letters.randomElement()! })
    }

    static func randomString2(length: Int) -> String {
        let letters = "0123456789"
        return String((0 ..< length).map { _ in letters.randomElement()! })
    }

    var cleanNumber: String {
        "+1\(self.replacingOccurrences(of: "+1", with: ""))".replacingOccurrences(of: "(", with: "").replacingOccurrences(of: ")", with: "").replacingOccurrences(of: " ", with: "") //
    }
}
