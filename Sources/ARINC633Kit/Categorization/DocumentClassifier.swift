//
//  DocumentClassifier.swift
//  EFFReader
//
//  Created by Liyana on 1.7.2026.
//


// ARINC633Kit/Categorization/DocumentClassifier.swift
import Foundation

public enum DocumentClassifier {

    public static func classify(fileName: String) -> DocumentCategory {
        let n = fileName.lowercased()
        if n.hasSuffix("_ofp.xml") || n.contains("_ofp.")    { return .ofp }
        if n.contains("flightplan")                          { return .flightPlan }
        if n.contains("weather") || n.contains("metar")
            || n.contains("taf")                             { return .weather }
        if n.contains("notam")                               { return .notam }
        if n.contains("loadsheet") || n.contains("weight")   { return .loadsheet }
        if n.contains("chart")                               { return .chart }
        if n.hasSuffix(".pdf")                               { return .pdf }
        if n.hasSuffix(".png") || n.hasSuffix(".jpg")
            || n.hasSuffix(".jpeg")                          { return .image }
        if n.hasSuffix(".xml")                               { return .xml }
        return .other
    }

    public static func mimeType(for url: URL) -> String? {
        switch url.pathExtension.lowercased() {
        case "pdf":         return "application/pdf"
        case "xml":         return "application/xml"
        case "png":         return "image/png"
        case "jpg", "jpeg": return "image/jpeg"
        case "json":        return "application/json"
        case "txt":         return "text/plain"
        default:            return nil
        }
    }
}