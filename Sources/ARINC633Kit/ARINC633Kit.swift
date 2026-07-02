//
//  ARINC633Kit.swift
//  EFFReader
//
//  Created by Liyana on 1.7.2026.
//
// ARINC633Kit/ARINC633Kit.swift
// Public, stable surface area. Anything not exported here is implementation detail.

import Foundation

// Models
public typealias EFFPackageRef = EFFPackage
public typealias OFPDocumentRef = OFPDocument
public typealias DocumentCategoryRef = DocumentCategory

// Entry points
// Use: ARINC633Kit.read(from:)
public enum ARINC633Kit {
    public static func read(from url: URL) throws -> EFFPackage {
        try EFFReader.read(from: url)
    }
}
