//
//  ServiceTests.swift
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

class FooTestService: HTTPService {
    override class func serviceName() -> String {
        return "FooTestService"
    }

    override class func defaultSession() -> HTTPSession {
        return HTTPSession()
    }

    override func cycleDidCreateWithResourceName(cycle: HTTPCycle, name: String) {
    }

}

class ServiceBasicTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testURLStringByJoiningComponentsShouldWork() {
        var result = HTTPService.URLStringByJoiningComponents("part1", part2: "part2")
        XCTAssertEqual(result, "part1/part2")

        result = HTTPService.URLStringByJoiningComponents("", part2: "part2")
        XCTAssertEqual(result, "part2")

        result = HTTPService.URLStringByJoiningComponents("part1", part2: "")
        XCTAssertEqual(result, "part1")

        result = HTTPService.URLStringByJoiningComponents("part1/", part2: "part2")
        XCTAssertEqual(result, "part1/part2")

        result = HTTPService.URLStringByJoiningComponents("part1/", part2: "/part2")
        XCTAssertEqual(result, "part1/part2")

        result = HTTPService.URLStringByJoiningComponents("part1/", part2: "")
        XCTAssertEqual(result, "part1/")
    }

    func testVerifyProfileShouldWork() {
        let bundle = NSBundle(forClass: self.dynamicType)
        let URL = bundle.URLForResource("FooTestService", withExtension: "plist")
        let service = FooTestService()
        XCTAssertNotNil(try? service!.updateProfileFromLocalFile(URL))
        XCTAssertTrue(service!.verifyProfile(service!.profile))
    }

    func testVerifyProfileShouldFailForDuplicateName() {
        let bundle = NSBundle(forClass: self.dynamicType)
        let URL = bundle.URLForResource("FooTestService_DuplicateName", withExtension: "plist")
        let service = FooTestService()
        XCTAssertNotNil(try? service!.updateProfileFromLocalFile(URL))
        XCTAssertFalse(service!.verifyProfile(service!.profile))
    }

    func testVerifyProfileShouldFailForNameNotFound() {
        let bundle = NSBundle(forClass: self.dynamicType)
        let URL = bundle.URLForResource("FooTestService_NameNotFound", withExtension: "plist")
        let service = FooTestService()
        XCTAssertNotNil(try? service!.updateProfileFromLocalFile(URL))
        XCTAssertFalse(service!.verifyProfile(service!.profile))
    }

    func testVerifyProfileShouldFailForNoResources() {
        let bundle = NSBundle(forClass: self.dynamicType)
        let URL = bundle.URLForResource("FooTestService_NoResources", withExtension: "plist")
        let service = FooTestService()
        XCTAssertNotNil(try? service!.updateProfileFromLocalFile(URL))
        XCTAssertFalse(service!.verifyProfile(service!.profile))
    }

    func testVerifyProfileShouldFailForURITemplateNotFound() {
        let bundle = NSBundle(forClass: self.dynamicType)
        let URL = bundle.URLForResource("FooTestService_URITemplateNotFound", withExtension: "plist")
        let service = FooTestService()
        XCTAssertNotNil(try? service!.updateProfileFromLocalFile(URL))
        XCTAssertFalse(service!.verifyProfile(service!.profile))
    }
}

class ServiceHTTPTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testCycleForResourceWithIdentiferShouldWork() {
        let expection = self.expectationWithDescription("")
        let service = FooTestService()
        let cycle = try! service!.cycleForResourceWithIdentifer("hello", URIValues: ["content": "hello world"])
        cycle.start {(cycle, error) in
            XCTAssertNil(error)
            XCTAssertEqual(cycle.response.text!, "hello world");
            XCTAssertEqual(cycle.response.statusCode, 200);
            expection.fulfill()
        }
        self.waitForExpectationsWithTimeout(Timeout, handler: nil)
    }

    func testCycleForResourceWithIdentiferReplaceShouldWork() {
        let expection = self.expectationWithDescription("")
        let service = FooTestService()
        let cycle1 = try! service!.cycleForResourceWithIdentifer("delay", identifier: "test_task", URIValues: ["delay": 2, "content": "hello 1"])
        cycle1.start {(cycle, error) in
            XCTAssertTrue(false) // should never reach here
        }
        // wait until cycle1 started
        WaitForWithTimeout(100.0) {
            return cycle1.core !== nil
        }

        let cycle2 = try! service!.cycleForResourceWithIdentifer("delay", identifier: "test_task", option: .Replace, URIValues: ["delay": 0, "content": "hello 2"])
        XCTAssertFalse(cycle1 === cycle2)
        cycle2.start {(cycle, error) in
            XCTAssertNil(error)
            XCTAssertEqual(cycle.response.text, "hello 2");
            XCTAssertEqual(cycle.response!.statusCode, 200);
            expection.fulfill()
        }

        self.waitForExpectationsWithTimeout(Timeout, handler: nil)
    }

    func testCycleForResourceWithIdentiferReuseShouldWork() {
        let expection = self.expectationWithDescription("")
        let service = FooTestService()
        let cycle1 = try! service!.cycleForResourceWithIdentifer("delay", identifier: "test_task", URIValues: ["delay": 2, "content": "hello 1"])
        cycle1.start {(cycle, error) in
            XCTAssertTrue(false) // should never reach here
        }
        // wait until cycle1 started
        WaitForWithTimeout(100.0) {
            return cycle1.core !== nil
        }

        let cycle2 = try! service!.cycleForResourceWithIdentifer("delay", identifier: "test_task", option: .Reuse, URIValues: ["delay": 0, "content": "hello 2"])
        XCTAssertTrue(cycle1 === cycle2)
        cycle2.start {(cycle, error) in
            XCTAssertNil(error)
            XCTAssertEqual(cycle.response.text, "hello 1");
            XCTAssertEqual(cycle.response.statusCode, 200);
            expection.fulfill()
        }

        self.waitForExpectationsWithTimeout(Timeout, handler: nil)
    }

    func testCycleForResourceShouldWork() {
        let expection = self.expectationWithDescription("")
        let service = FooTestService()
        let cycle = try! service!.cycleForResource("hello", URIValues: ["content": "hello world"])
        cycle.start {(cycle, error) in
            XCTAssertNil(error)
            XCTAssertEqual(cycle.response.text, "hello world");
            XCTAssertEqual(cycle.response!.statusCode, 200);
            expection.fulfill()
        }
        self.waitForExpectationsWithTimeout(Timeout, handler: nil)
    }

    func testRequestResourceWithIdentiferShouldWork() {
        let expection = self.expectationWithDescription("")
        let service = FooTestService()
        _ = try! service!.requestResourceWithIdentifer("hello", identifier: "test_task", URIValues: ["content": "hello world"], completionHandler: {(cycle, error) in
            XCTAssertNil(error)
            XCTAssertEqual(cycle.response.text, "hello world");
            XCTAssertEqual(cycle.response.statusCode, 200);
            expection.fulfill()
        })
        self.waitForExpectationsWithTimeout(Timeout, handler: nil)
    }

    func testRequestResourceShouldWork() {
        let expection = self.expectationWithDescription("")
        let service = FooTestService()
        _ = try! service!.requestResource("hello", URIValues: ["content": "hello world"], completionHandler: {(cycle, error) in
            XCTAssertNil(error)
            XCTAssertEqual(cycle.response.text, "hello world");
            XCTAssertEqual(cycle.response.statusCode, 200);
            expection.fulfill()
        })
        self.waitForExpectationsWithTimeout(Timeout, handler: nil)
    }
}

class FooTestMoreService: HTTPService {
    override class func serviceName() -> String {
        return "FooTestMoreService"
    }

    override class func defaultSession() -> HTTPSession {
        let session = super.defaultSession()
        session.requestProcessors = [HTTPJSONProcessor()]
        session.responseProcessors = [HTTPJSONProcessor()]

        return session
    }

    override func cycleDidCreateWithResourceName(cycle: HTTPCycle, name: String) {
        if name == "postdata" {
            cycle.requestProcessors = [HTTPDataProcessor()]
            cycle.responseProcessors = []
        }
    }
    
}

class ServiceHTTPMoreTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testRequestResourceByPOSTingJSONShouldWork() {
        let expection = self.expectationWithDescription("")
        let service = FooTestMoreService()
        try! service!.requestResource("postjson", requestObject: ["k1": "v1"], completionHandler: { (cycle, error) in
            XCTAssertNil(error)
            var dict = cycle.response.object as! Dictionary<String, String>
            XCTAssertEqual(dict["k1"]!, "v1")
            expection.fulfill()
        })
        self.waitForExpectationsWithTimeout(Timeout, handler: nil)
    }

    func testRequestResourceByPOSTingDataShouldWork() {
        let data = "hello world".dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)
        let expection = self.expectationWithDescription("")
        let service = FooTestMoreService()
        try! service!.requestResource("postdata", requestObject: data, completionHandler: { (cycle, error) in
            XCTAssertNil(error)
            XCTAssertEqual(cycle.response.text, "hello world")
            expection.fulfill()
        })
        self.waitForExpectationsWithTimeout(Timeout, handler: nil)
    }
}
