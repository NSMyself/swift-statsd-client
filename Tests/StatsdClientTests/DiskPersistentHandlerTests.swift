//
//  DiskPersistentHandlerTests.swift
//  StatsdClient-iOS Tests
//
//  Created by Nghia Tran on 10/9/17.
//  Copyright © 2017 StatsdClient. All rights reserved.
//

import XCTest
@testable import StatsdClient

class DiskPersistentHandlerTests: XCTestCase {

    let config = DiskConfiguration.default
    let fileManager = FileManager.default
    var handler: DiskPersistentHandler!

    override func setUp() {
        super.setUp()

        handler = try? DiskPersistentHandler(config: config, fileManager: fileManager)
    }

    override func tearDown() {
        super.tearDown()

        try? handler.deleteAllFile()
    }

    func testInitialization() {
        XCTAssertNoThrow(try DiskPersistentHandler(config: DiskConfiguration.default),
                         "Able to initialize DiskPersistentHandler with default configuration")
    }

    func testTotalCountAtFreshInitialization() {
        XCTAssertEqual(handler.fileCount, 0, "File count should be 0")
    }

    func testTotalCountAfterInitializationBefore() {

        let metric = StubMetric()

        XCTAssertNoThrow(try handler.write(metric, key: metric.name, attribute: nil),
                         "Write fill successfully without any execptions")
        XCTAssertNoThrow({[unowned self] in
            let anotherHandler = try DiskPersistentHandler(config: self.config,
                                                           fileManager: self.fileManager)
            XCTAssertEqual(anotherHandler.fileCount, 1,
                           "Another Hanlder should fetch same data if same configuration")
        }, "Initialized without exception")
    }

    func testCreateCacheFolderAfterInitalization() {
        guard let pathFolder = config.folderPath else {
            XCTFail("Invalid Path Folder")
            return
        }
        let isExisted = fileManager.fileExists(atPath: pathFolder)
        XCTAssertTrue(isExisted,
                      "it should create cache folder which cooresponse with config's pathFolder")
    }

    func testMakePathFile() {

        let fileName = "Login_Stats"
        let filePath = handler.makeFilePath(fileName)
        guard let pathFolder = config.folderPath else {
            XCTFail("Invalid Path Folder")
            return
        }

        let expected = "\(pathFolder)/\(fileName)"
        XCTAssertEqual(filePath, expected, "File path should match format")
    }

    func testWriteIndividualFile() {

        let firstMetric = StubMetric()
        let secondMetric = StubMetric(name: "Aloha")

        XCTAssertNoThrow(try handler.write(firstMetric, key: firstMetric.name, attribute: nil),
                         "Write fill successfully without any execptions")
        XCTAssertEqual(handler.fileCount, 1, "File count should be 1")
        XCTAssertNoThrow(try handler.write(secondMetric, key: secondMetric.name, attribute: nil),
                         "Write fill successfully without any execptions")
        XCTAssertEqual(handler.fileCount, 2, "File count should be 2")

        XCTAssertTrue(fileManager.fileExists(atPath: handler.makeFilePath(firstMetric.name)), "File exists")
        XCTAssertTrue(fileManager.fileExists(atPath: handler.makeFilePath(secondMetric.name)), "File exists")
    }

    func testWriteManyFiles() {

        let metric = StubMetric()

        XCTAssertNoThrow(try handler.write(metric, key: metric.name,
                                           attribute: nil),
                         "Write fill successfully without any execptions")
        XCTAssertTrue(fileManager.fileExists(atPath: handler.makeFilePath(metric.name)), "File exists")
    }

    func testReceivedFile() {

        let metric = StubMetric()

        XCTAssertNoThrow(try handler.write(metric, key: metric.name, attribute: nil),
                         "Write fill successfully without any execptions")
        XCTAssertNoThrow({[unowned self] in

            let receiveFile = try self.handler.get(key: metric.name, type: StubMetric.self)
            XCTAssertEqual(receiveFile, metric, "Should be equal")

            }, "Receive file success")
        XCTAssertThrowsError(try self.handler.get(key: "Wrong key", type: StubMetric.self),
                             "Should throw exception because fetching no exist file")
    }

    func testDeleteAll() {

        let firstMetric = StubMetric()
        let secondMetric = StubMetric(name: "Aloha")

        XCTAssertNoThrow(try handler.write(firstMetric, key: firstMetric.name, attribute: nil),
                         "Write fill successfully without any execptions")
        XCTAssertNoThrow(try handler.write(secondMetric, key: secondMetric.name, attribute: nil),
                         "Write fill successfully without any execptions")

        XCTAssertNoThrow(try handler.deleteAllFile(), "Delete all without any execeptions")
        XCTAssertEqual(handler.fileCount, 0, "Should be 0")

        // After delete -> Should write success
        XCTAssertNoThrow(try handler.write(firstMetric, key: firstMetric.name, attribute: nil),
                         "Write fill successfully without any execptions")
        XCTAssertEqual(handler.fileCount, 1, "Should be 1")
    }

    func testGetAll() {

        let firstMetric = StubMetric()
        let secondMetric = StubMetric(name: "Aloha")

        XCTAssertNoThrow(try handler.write(firstMetric, key: firstMetric.name, attribute: nil),
                         "Write fill successfully without any execptions")
        XCTAssertEqual(handler.fileCount, 1, "File count should be 1")
        XCTAssertNoThrow(try handler.write(secondMetric, key: secondMetric.name, attribute: nil),
                         "Write fill successfully without any execptions")
        XCTAssertEqual(handler.fileCount, 2, "File count should be 2")

        XCTAssertNoThrow({[unowned self] in

        let items: [StubMetric] = self.handler.getAll(type: StubMetric.self)
        XCTAssertEqual(items[0], secondMetric)
        XCTAssertEqual(items[1], firstMetric)

        }, "Get all files success")
    }

}
