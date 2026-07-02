//
//  EFFArchiveUnpacker.swift
//  EFFReader
//
//  Created by Liyana on 1.7.2026.
//


// ARINC633Kit/IO/EFFArchiveUnpacker.swift
import Foundation
import ZIPFoundation

/// Handles outer .eff unzip and inner .dat extraction.
public enum EFFArchiveUnpacker {

    public struct UnpackResult {
        public let workDir: URL
        public let lstFile: URL?
        public let datFile: URL?
        public let datExtractDir: URL
        public let extractedDocs: [URL]
    }

    public static func unpack(eff effURL: URL) throws -> UnpackResult {
        let fm = FileManager.default
        let workDir = fm.temporaryDirectory
            .appendingPathComponent("EFF_\(UUID().uuidString)")
        try fm.createDirectory(at: workDir, withIntermediateDirectories: true)

        do { try fm.unzipItem(at: effURL, to: workDir) }
        catch { throw EFFReaderError.extractionFailed(error.localizedDescription) }

        let allFiles = filesRecursively(in: workDir)
        guard !allFiles.isEmpty else { throw EFFReaderError.emptyArchive }

        let lstFile = allFiles.first { $0.pathExtension.lowercased() == "lst" }
        let datFile = allFiles.first { $0.pathExtension.lowercased() == "dat" }
        guard let datFile = datFile else { throw EFFReaderError.missingDatFile }

        let datExtractDir = workDir.appendingPathComponent("__dat_extracted__")
        try fm.createDirectory(at: datExtractDir, withIntermediateDirectories: true)
        let extracted = try extractDatContents(datFile: datFile, into: datExtractDir)

        return UnpackResult(workDir: workDir,
                            lstFile: lstFile,
                            datFile: datFile,
                            datExtractDir: datExtractDir,
                            extractedDocs: extracted)
    }

    private static func extractDatContents(datFile: URL, into dest: URL) throws -> [URL] {
        let fm = FileManager.default
        do {
            try fm.unzipItem(at: datFile, to: dest)
            return filesRecursively(in: dest)
        } catch { /* fall through */ }

        let head = (try? readHead(of: datFile, bytes: 512)) ?? Data()
        let asString = String(data: head, encoding: .utf8) ?? ""

        if asString.contains("Content-Type: multipart")
            || asString.hasPrefix("MIME-Version") {
            return try MIMEMultipartExtractor.extract(from: datFile, into: dest)
        }
        if asString.trimmingCharacters(in: .whitespacesAndNewlines)
            .hasPrefix("<?xml") {
            let dst = dest.appendingPathComponent(
                datFile.deletingPathExtension().lastPathComponent + ".xml")
            try fm.copyItem(at: datFile, to: dst)
            return [dst]
        }
        let dst = dest.appendingPathComponent(datFile.lastPathComponent)
        try fm.copyItem(at: datFile, to: dst)
        return [dst]
    }

    private static func filesRecursively(in root: URL) -> [URL] {
        let fm = FileManager.default
        guard let e = fm.enumerator(at: root,
                                    includingPropertiesForKeys: [.isDirectoryKey])
        else { return [] }
        return e.compactMap { item -> URL? in
            guard let url = item as? URL else { return nil }
            let isDir = (try? url.resourceValues(forKeys: [.isDirectoryKey]))?
                .isDirectory ?? false
            return isDir ? nil : url
        }
    }

    private static func readHead(of url: URL, bytes: Int) throws -> Data {
        let handle = try FileHandle(forReadingFrom: url)
        defer { try? handle.close() }
        return handle.readData(ofLength: bytes)
    }
}