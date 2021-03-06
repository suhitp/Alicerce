//
//  JSONLogItemFormatterTests.swift
//  Alicerce
//
//  Created by Meik Schutz on 04/04/17.
//  Copyright © 2017 Mindera. All rights reserved.
//

import XCTest
@testable import Alicerce

class JSONLogItemFormatterTests: XCTestCase {

    fileprivate var log: Log!
    fileprivate var queue: Log.Queue!
    fileprivate let expectationTimeout: TimeInterval = 5
    fileprivate let expectationHandler: XCWaitCompletionHandler = { error in
        if let error = error {
            XCTFail("🔥: Test expectation wait timed out: \(error)")
        }
    }

    override func setUp() {
        super.setUp()

        log = Log(qos: .default)
        queue = Log.Queue(label: "JSONLogItemFormatterTests")
    }

    override func tearDown() {
        log = nil
        queue = nil

        super.tearDown()
    }

    func testLogItemJSONFormatter() {

        // preparation of the test subject

        let destination = Log.StringLogDestination(minLevel: .verbose,
                                                   formatter: Log.JSONLogItemFormatter(),
                                                   queue: queue)
        destination.linefeed = ","

        // execute test

        log.register(destination)
        log.verbose("verbose message")
        log.debug("debug message")
        log.info("info message")
        log.warning("warning message")
        log.error("error message")

        queue.dispatchQueue.sync {

            let jsonString = "[\(destination.output)]"
            let jsonData = jsonString.data(using: .utf8)

            do {
                let obj = try JSONSerialization.jsonObject(with: jsonData!, options: .allowFragments)

                guard let arr = obj as? [[String : Any]] else {
                    return XCTFail("🔥: expected a dictionary from JSON serialization but got something different") }
                XCTAssertEqual(arr.count, 5)

                let verboseItem = arr.first
                XCTAssertNotNil(verboseItem)
                XCTAssertEqual(verboseItem!["level"] as? Int, Log.Level.verbose.rawValue)

                let errorItem = arr.last
                XCTAssertNotNil(errorItem)
                XCTAssertEqual(errorItem!["level"] as? Int, Log.Level.error.rawValue)
            }
            catch {
                XCTFail()
            }
        }
    }
}
