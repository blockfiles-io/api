//
//  File.swift
//  
//
//  Created by Ralph Küpper on 3/7/23.
//

import Foundation

extension StringProtocol {
    func dropping<S: StringProtocol>(prefix: S) -> SubSequence { hasPrefix(prefix) ? dropFirst(prefix.count) : self[...] }
    var hexaToDecimal: Int { Int(dropping(prefix: "0x"), radix: 16) ?? 0 }
    var hexaToDecimalString: String { "\(hexaToDecimal)" }
}
