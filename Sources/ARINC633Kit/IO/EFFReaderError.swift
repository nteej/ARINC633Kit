//
//  EFFReaderError.swift
//  EFFReader
//
//  Created by Liyana on 1.7.2026.
//


public import Foundation

public enum EFFReaderError: LocalizedError {
    case cannotOpenArchive
    case extractionFailed(String)
    case emptyArchive
    case missingDatFile

    public var errorDescription: String? {
        switch self {
        case .cannotOpenArchive:           return "Could not open the .eff archive."
        case .extractionFailed(let msg):   return "Extraction failed: \(msg)"
        case .emptyArchive:                return "The .eff archive is empty."
        case .missingDatFile:              return "No .dat payload file found inside the .eff."
        }
    }
}