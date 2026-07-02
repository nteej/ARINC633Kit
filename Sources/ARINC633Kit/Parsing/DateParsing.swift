//
//  DateParsing.swift
//  EFFReader
//
//  Created by Liyana on 1.7.2026.
//


// ARINC633Kit/Parsing/DateParsing.swift
import Foundation

public enum DateParsing {
    // nonisolated(unsafe): these formatters are used only within synchronous parse()
    // calls and are never mutated concurrently. DateFormatter is not thread-safe,
    // but read is single-threaded at the call site (EFFReader.read is synchronous).
    nonisolated(unsafe) private static let iso = ISO8601DateFormatter()
    private static let formats = [
        "yyyy-MM-dd'T'HH:mm:ssZ",
        "yyyy-MM-dd'T'HH:mm:ss.SSSZ",
        "yyyy-MM-dd'T'HH:mm:ss",
        "yyyy-MM-dd HH:mm:ss",
        "yyyyMMddHHmmss",
        "yyyyMMddHHmm",
        "yyMMddHHmm",
        "ddMMMyy HHmm",
        "dd/MM/yyyy HH:mm"
    ]

    // A single cached formatter reused across all calls in the same context.
    nonisolated(unsafe) private static let formatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone(identifier: "UTC")
        return f
    }()

    public static func parse(_ s: String?) -> Date? {
        guard let s = s, !s.isEmpty else { return nil }
        if let d = iso.date(from: s) { return d }
        for fmt in formats {
            formatter.dateFormat = fmt
            if let d = formatter.date(from: s) { return d }
        }
        return nil
    }
}
