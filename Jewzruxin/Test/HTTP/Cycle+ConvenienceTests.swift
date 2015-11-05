//
//  Cycle+ConvenienceTests.swift
//
//  Copyright (c) 2015 Weipin Xia
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy of
//  this software and associated documentation files (the "Software"), to deal in
//  the Software without restriction, including without limitation the rights to
//  use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
//  the Software, and to permit persons to whom the Software is furnished to do so,
//  subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
//  FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
//  COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
//  IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
//  CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

import XCTest
#if os(iOS)
@testable import JewzruxiniOS
#endif
#if os(OSX)
@testable import JewzruxinMac
#endif

class CycleConvenienceTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testURLForStringShouldWork() {
        var URL = HTTPCycle.URLForString("http://test.com")
        XCTAssertNotNil(URL)

        URL = HTTPCycle.URLForString("http://test.com?q=测试")
        XCTAssertNotNil(URL)

        URL = HTTPCycle.URLForString("http://test.com/测试/")
        XCTAssertNotNil(URL)

        URL = HTTPCycle.URLForString("http://test.com/测试/?q=测试")
        XCTAssertNotNil(URL)
    }

    func testInvalidURLShouldIssueAnError() {
        var e: Error!
        do {
            _ = try HTTPCycle.get("", completionHandler: {(cycle, error) in
            })
        } catch {
            e = error as! Error
        }
        XCTAssertEqual(e, Error.InvalidURL)
    }

    func testGETShouldWork() {
        let expection = self.expectationWithDescription("")
        let URLString = t_("/core/hello/")
        try! HTTPCycle.get(URLString, completionHandler: {(cycle, error) in
            XCTAssertNil(error)
            XCTAssertEqual(cycle.response.text, "Hello World");
            XCTAssertEqual(cycle.response.statusCode, 200);
            expection.fulfill()
        })

        self.waitForExpectationsWithTimeout(Timeout, handler: nil)
    }

    func testGETWithParametersShouldWork() {
        let expection = self.expectationWithDescription("")
        let URLString = t_("/core/echo/")
        try! HTTPCycle.get(URLString, parameters: ["content": ["helloworld"]],
                  completionHandler: {(cycle, error) in
                    XCTAssertNil(error)
                    XCTAssertEqual(cycle.response.text, "helloworld");
                    XCTAssertEqual(cycle.response.statusCode, 200);
                    expection.fulfill()
            })

        self.waitForExpectationsWithTimeout(Timeout, handler: nil)
    }

    func testPOSTShouldWork() {
        let expection = self.expectationWithDescription("")
        let URLStrng = t_("/core/dumpupload/")
        let requestObject = NSDictionary(object: "v1", forKey: "k1")
        try! HTTPCycle.post(URLStrng, requestObject: requestObject, requestProcessors: [HTTPJSONProcessor()], responseProcessors: [HTTPJSONProcessor()], completionHandler: {(cycle, error) in
                XCTAssertNil(error)
                let dict = cycle.response.object as! NSDictionary
                XCTAssertNotNil(dict)
                let value = dict.objectForKey("k1") as? String
                XCTAssertNotNil(value)
                XCTAssertEqual(value!, "v1")
                expection.fulfill()
        })

        self.waitForExpectationsWithTimeout(Timeout, handler: nil)
    }

    func testUploadShouldWork() {
        let data = "Hello World".dataUsingEncoding(NSUTF8StringEncoding)!
        let expection = self.expectationWithDescription("")
        let URLString = t_("/core/dumpupload/")
        try! HTTPCycle.upload(URLString, source: .Data(data), completionHandler: {
            (cycle, error) in
            XCTAssertNil(error)

            XCTAssertEqual(cycle.response.text, "Hello World")
            expection.fulfill()
        })
        self.waitForExpectationsWithTimeout(Timeout, handler: nil)
    }

    func testDownloadShouldWork() {
        let expection = self.expectationWithDescription("")
        let URLString = t_("/core/echo/?content=helloworld")
        try! HTTPCycle.download(URLString,
            downloadFileHandler: {(cycle, location) in
                XCTAssertNotNil(location)
                let content = try! NSString(contentsOfURL: location!, encoding: NSUTF8StringEncoding)
                XCTAssertEqual(content, "helloworld")
            },
            completionHandler: {(cycle, error) in
                XCTAssertNil(error)
                expection.fulfill()
            })
        self.waitForExpectationsWithTimeout(Timeout, handler: nil)
    }
}

