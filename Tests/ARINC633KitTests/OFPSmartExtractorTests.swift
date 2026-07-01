//
//  OFPSmartExtractorTests.swift
//  ARINC633Kit
//
//  Created by Liyana on 2.7.2026.
//


// Tests/ARINC633KitTests/OFPSmartExtractorTests.swift
import XCTest
@testable import ARINC633Kit

final class OFPSmartExtractorTests: XCTestCase {

    func testExtractsFlightNumberFromVendorA() throws {
        let url = try fixture("vendorA_ofp.xml")
        let ofp = try XCTUnwrap(OFPSmartExtractor.extract(from: url))
        XCTAssertEqual(ofp.flightInfo.flightNumber, "LH441")
        XCTAssertEqual(ofp.flightInfo.departureICAO, "EDDF")
        XCTAssertEqual(ofp.flightInfo.arrivalICAO, "KIAD")
    }

    func testExtractsFlightNumberFromVendorB() throws {
        let url = try fixture("vendorB_ofp.xml")
        let ofp = try XCTUnwrap(OFPSmartExtractor.extract(from: url))
        XCTAssertEqual(ofp.flightInfo.flightNumber, "BA279")
    }

    func testFuelTotalsParseCorrectly() throws {
        let url = try fixture("vendorA_ofp.xml")
        let ofp = try XCTUnwrap(OFPSmartExtractor.extract(from: url))
        XCTAssertEqual(ofp.fuel?.tripFuel?.contains("12450"), true)
    }

    func testReturnsNilForEmptyXML() throws {
        let url = try fixture("empty.xml")
        XCTAssertNil(OFPSmartExtractor.extract(from: url))
    }

    private func fixture(_ name: String) throws -> URL {
        let bundle = Bundle.module
        return try XCTUnwrap(bundle.url(forResource: name, withExtension: nil,
                                         subdirectory: "Fixtures"))
    }
}