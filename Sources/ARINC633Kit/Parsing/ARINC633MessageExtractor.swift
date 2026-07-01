//
//  ARINC633MessageExtractor.swift
//  EFFReader
//
//  Created by Liyana on 1.7.2026.
//


// ARINC633Kit/Parsing/ARINC633MessageExtractor.swift
import Foundation

/// Anything that turns an XML file into a typed ARINC 633 document.
public protocol ARINC633MessageExtractor {
    associatedtype Output
    static var category: DocumentCategory { get }
    static func canHandle(fileName: String) -> Bool
    static func extract(from url: URL) -> Output?
}

extension OFPSmartExtractor: ARINC633MessageExtractor {
    public static var category: DocumentCategory { .ofp }
    public static func canHandle(fileName: String) -> Bool {
        let n = fileName.lowercased()
        return n.hasSuffix("_ofp.xml") || n.contains("_ofp.")
    }
}