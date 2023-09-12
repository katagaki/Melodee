//
//  Bundle.swift
//  Melodee
//
//  Created by シン・ジャスティン on 2023/09/12.
//

import Foundation

extension Bundle {

    func plist(named filename: String) -> [String: String]? {
        let filename = filename.replacingOccurrences(of: ".plist", with: "")
        if let path = self.path(forResource: filename, ofType: "plist") {
            return NSDictionary(contentsOfFile: path)! as? [String: String]
        } else {
            return nil
        }
    }

}
