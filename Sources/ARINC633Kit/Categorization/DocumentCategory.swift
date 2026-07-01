//
//  DocumentCategory.swift
//  EFFReader
//
//  Created by Liyana on 1.7.2026.
//


// ARINC633Kit/Categorization/DocumentCategory.swift
import Foundation

public enum DocumentCategory: String, Codable, CaseIterable, Hashable {
    case ofp          = "OFP"
    case flightPlan   = "FlightPlan"
    case weather      = "Weather"
    case notam        = "NOTAM"
    case loadsheet    = "Loadsheet"
    case chart        = "Chart"
    case image        = "Image"
    case xml          = "XML"
    case pdf          = "PDF"
    case other        = "Other"

    public var displayName: String { rawValue }

    public var systemIcon: String {
        switch self {
        case .ofp:        return "doc.text.image.fill"
        case .flightPlan: return "paperplane.fill"
        case .weather:    return "cloud.sun.fill"
        case .notam:      return "exclamationmark.triangle.fill"
        case .loadsheet:  return "scalemass.fill"
        case .chart:      return "map.fill"
        case .image:      return "photo.fill"
        case .xml:        return "chevron.left.forwardslash.chevron.right"
        case .pdf:        return "doc.richtext.fill"
        case .other:      return "doc.fill"
        }
    }
}