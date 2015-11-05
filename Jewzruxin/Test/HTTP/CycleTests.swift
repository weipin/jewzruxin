//
//  CycleTests.swift
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

class HTTPCycleTests: XCTestCase {
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testGETShouldWork() {
        let expection = self.expectationWithDescription("")
        let URL = tu_("/core/hello/")
        let cycle = HTTPCycle(requestURL: URL)

        cycle.start {(cycle, error) in
            XCTAssertNil(error)
            XCTAssertEqual(cycle.response.text, "Hello World");
            XCTAssertEqual(cycle.response.statusCode, 200);
            expection.fulfill()
        }
        self.waitForExpectationsWithTimeout(Timeout, handler: nil)
    }

    func testGETTextEncodingFromHeaderShouldWork() {
        let expection = self.expectationWithDescription("")
        let URL = tu_("/core/echo?header=Content-Type%3Atext%2Fhtml%3B%20charset%3Dgb2312")
        let cycle = HTTPCycle(requestURL: URL)

        cycle.start {(cycle, error) in
            XCTAssertNil(error)

            let enc = CFStringEncoding(CFStringEncodings.EUC_CN.rawValue)
            let encoding = cycle.response.textEncoding
            XCTAssertTrue(encoding == CFStringConvertEncodingToNSStringEncoding(enc));
            expection.fulfill()
        }
        self.waitForExpectationsWithTimeout(Timeout, handler: nil)
    }

    func testGetTextEncodingWhenContentTypeContainsTextAndCharsetIsMissingShouldWork() {
        let expection = self.expectationWithDescription("")
        let URL = tu_("/core/echo?header=Content-Type%3Atext%2Fhtml")
        let cycle = HTTPCycle(requestURL: URL)

        cycle.start {(cycle, error) in
            XCTAssertNil(error)

            let enc = CFStringEncoding(CFStringBuiltInEncodings.ISOLatin1.rawValue)
            let encoding = cycle.response.textEncoding
            XCTAssertTrue(encoding == CFStringConvertEncodingToNSStringEncoding(enc));
            expection.fulfill()
        }
        self.waitForExpectationsWithTimeout(Timeout, handler: nil)
    }

    func testGetTextEncodingWithDetectionShouldWork() {
        let expection = self.expectationWithDescription("")
        let URL = tu_("/core/echo?header=Content-Type%3AXXXXXXX&content=%E4%BD%A0%E5%A5%BD&encoding=gb2312")
        let cycle = HTTPCycle(requestURL: URL)

        cycle.start {(cycle, error) in
            XCTAssertNil(error)

            let enc = CFStringEncoding(CFStringEncodings.GB_18030_2000.rawValue)
            let encoding = cycle.response.textEncoding
            XCTAssertTrue(encoding == CFStringConvertEncodingToNSStringEncoding(enc));
            expection.fulfill()
        }
        self.waitForExpectationsWithTimeout(Timeout, handler: nil)
    }

    func testGetTextEncodingWithLastFallBackShouldWork() {
        let expection = self.expectationWithDescription("")
        let URL = tu_("/core/echo?header=Content-Type%3AXXXXXXX")
        let cycle = HTTPCycle(requestURL: URL)

        cycle.start {(cycle, error) in
            XCTAssertNil(error)

            let encoding = cycle.response.textEncoding
            XCTAssertTrue(encoding == NSUTF8StringEncoding);
            expection.fulfill()
        }
        self.waitForExpectationsWithTimeout(Timeout, handler: nil)
    }

    // MARK: Requests
    func testUploadDataShouldWork() {
        let data = "Hello World".dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)
        let expection = self.expectationWithDescription("")
        let URL = tu_("/core/dumpupload/")
        let cycle = HTTPCycle(requestURL: URL, taskType: .Upload, requestMethod: "POST")
        cycle.uploadSource = .Data(data!)

        cycle.start {(cycle, error) in
            XCTAssertNil(error)

            XCTAssertEqual(cycle.response.text!, "Hello World")
            expection.fulfill()
        }
        self.waitForExpectationsWithTimeout(Timeout, handler: nil)
    }

    func testUploadFileShouldWork() {
        let bundle = NSBundle(forClass: self.dynamicType)
        let fileURL = bundle.URLForResource("upload", withExtension: "txt")
        XCTAssertNotNil(fileURL)

        let expection = self.expectationWithDescription("")
        let URL = tu_("/core/dumpupload/")
        let cycle = HTTPCycle(requestURL: URL, taskType: .Upload, requestMethod: "POST")
        cycle.uploadSource = .File(fileURL!)

        cycle.start {(cycle, error) in
            XCTAssertNil(error)

            XCTAssertEqual(cycle.response.text!, "Hello World File")
            expection.fulfill()
        }
        self.waitForExpectationsWithTimeout(Timeout, handler: nil)
    }

    func testDownloadShouldWork() {
        let expection = self.expectationWithDescription("")
        let URL = tu_("/core/echo?content=helloworld")
        let cycle = HTTPCycle(requestURL: URL, taskType: .Download)
        cycle.downloadFileHandler = {(cycle: HTTPCycle, location: NSURL?) in
            XCTAssertNotNil(location)
            let content = try! NSString(contentsOfURL: location!, encoding: NSUTF8StringEncoding)
            XCTAssertEqual(content, "helloworld")
        }
        cycle.start {(cycle, error) in
            XCTAssertNil(error)

            expection.fulfill()
        }
        self.waitForExpectationsWithTimeout(Timeout, handler: nil)
    }

    // MARK: Auth
    func testBasicAuthShouldFail() {
        let expection = self.expectationWithDescription("")
        let URL = tu_("/core/hello_with_basic_auth")
        let cycle = HTTPCycle(requestURL: URL)

        cycle.start {(cycle, error) in
            XCTAssertNotNil(error)
            XCTAssertEqual(cycle.response.statusCode, NSInteger(401))
            expection.fulfill()
        }
        self.waitForExpectationsWithTimeout(Timeout, handler: nil)
    }

    func testBasicAuthShouldWork() {
        let auth = BasicAuthentication(username: "test", password: "12345")
        let expection = self.expectationWithDescription("")
        let URL = tu_("/core/hello_with_basic_auth")
        let cycle = HTTPCycle(requestURL: URL)
        cycle.authentications = [auth]

        cycle.start {(cycle, error) in
            XCTAssertNil(error)
            XCTAssertEqual(cycle.response.statusCode, NSInteger(200))
            XCTAssertEqual(cycle.response.text!, "Hello World")
            expection.fulfill()
        }
        self.waitForExpectationsWithTimeout(Timeout, handler: nil)
    }

    func testDigestAuthShouldFail() {
        let expection = self.expectationWithDescription("")
        let URL = tu_("/core/hello_with_digest_auth")
        let cycle = HTTPCycle(requestURL: URL)

        cycle.start {(cycle, error) in
            XCTAssertNotNil(error)
            XCTAssertEqual(cycle.response.statusCode, NSInteger(401))
            expection.fulfill()
        }
        self.waitForExpectationsWithTimeout(Timeout, handler: nil)
    }

    func testDigestAuthShouldWork() {
        let auth = BasicAuthentication(username: "test", password: "12345")
        let expection = self.expectationWithDescription("")
        let URL = tu_("/core/hello_with_digest_auth")
        let cycle = HTTPCycle(requestURL: URL)
        cycle.authentications = [auth]

        cycle.start {(cycle, error) in
            XCTAssertNil(error)
            XCTAssertEqual(cycle.response.statusCode, NSInteger(200))
            XCTAssertEqual(cycle.response.text!, "Hello World")
            expection.fulfill()
        }
        self.waitForExpectationsWithTimeout(Timeout, handler: nil)
    }

    // MARK: Retry
    func testRetryForSolicitedShouldWork() {
        let URL = tu_("/core/echo?code=500")
        let cycle = HTTPCycle(requestURL: URL)
        cycle.solicited = true

        cycle.start {(cycle, error) in

        }
        WaitForWithTimeout(30.0) {
            return false
        }
        XCTAssertTrue(cycle.retriedCount > HTTPSession.Constants.RetryPolicyMaximumRetryCount);
    }

    func testRetryAboveMaxCountShouldFail() {
        let expection = self.expectationWithDescription("")
        let URL = tu_("/core/echo?code=408")
        let cycle = HTTPCycle(requestURL: URL)

        cycle.start {(cycle, error) in
            XCTAssertEqual(cycle.response.statusCode, NSInteger(408));
            expection.fulfill()
        }
        self.waitForExpectationsWithTimeout(30.0, handler: nil)
    }

    func testRetryOnTimeoutAboveMaxCountShouldFail() {
        let expection = self.expectationWithDescription("")
        let configuration = NSURLSessionConfiguration.defaultSessionConfiguration()
        configuration.timeoutIntervalForRequest = 1;
        configuration.timeoutIntervalForResource = 1
        let session = HTTPSession(configuration: configuration)

        let URL = tu_("/core/echo?delay=2")
        let cycle = HTTPCycle(requestURL: URL, session: session)

        cycle.start {(cycle, error) in
            XCTAssertNotNil(error)
            let e = error as! NSError
            XCTAssertTrue(e.domain == NSURLErrorDomain)
            XCTAssertEqual(e.code, NSURLErrorTimedOut)
            XCTAssertTrue(cycle.retriedCount > HTTPSession.Constants.RetryPolicyMaximumRetryCount)

            expection.fulfill()
        }
        self.waitForExpectationsWithTimeout(20.0, handler: nil)
    }

    // MARK: Processor
    func testJSONProcessorShouldWork() {
        let expection = self.expectationWithDescription("")
        let URL = tu_("/core/dumpupload/")
        let cycle = HTTPCycle(requestURL: URL, requestMethod: "POST",
            requestObject: NSDictionary(object: "v1", forKey: "k1"),
            requestProcessors: [HTTPJSONProcessor()],
            responseProcessors: [HTTPJSONProcessor()])
        cycle.start {(cycle, error) in
            XCTAssertNil(error)
            let dict = cycle.response.object as? NSDictionary
            XCTAssertNotNil(dict)
            let value = dict!.objectForKey("k1") as? String
            XCTAssertNotNil(value)
            XCTAssertEqual(value!, "v1")
            expection.fulfill()
        }
        self.waitForExpectationsWithTimeout(Timeout, handler: nil)
    }


}