//
//  EFFDocument.swift
//  EFFReader
//
//  Created by Liyana on 1.7.2026.
//


// ARINC633Kit/Models/EFFDocument.swift
import Foundation

public struct EFFDocument: Identifiable, Hashable {
    public let id = UUID()
    public let name: String
    public let path: String
    public let url: URL
    public let category: DocumentCategory
    public let mimeType: String?
    public let sizeBytes: Int64
    public let description: String?

    public init(name: String, path: String, url: URL,
                category: DocumentCategory, mimeType: String?,
                sizeBytes: Int64, description: String?) {
        self.name = name
        self.path = path
        self.url = url
        self.category = category
        self.mimeType = mimeType
        self.sizeBytes = sizeBytes
        self.description = description
    }
}