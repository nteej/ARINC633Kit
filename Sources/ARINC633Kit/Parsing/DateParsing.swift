//
//  DateParsing.swift
//  EFFReader
//
//  Created by Liyana on 1.7.2026.
//


// ARINC633Kit/Parsing/DateParsing.swift
import Foundation

public enum DateParsing {
    private static let iso = ISO8601DateFormatter()
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

    public static func parse(_ s: String?) -> Date? {
        guard let s = s, !s.isEmpty else { return nil }
        if let d = iso.date(from: s) { return d }
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone(identifier: "UTC")
        for fmt in formats {
            f.dateFormat = fmt
            if let d = f.date(from: s) { return d }
        }
        return nil
    }
}