//
//  URITemplate.swift
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

class HTTPCommonTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testParsingHTTPContentTypeLikeHeader() {
        var (type, parameters) = "text/html; charset=UTF-8".parametersByParsingHTTPContentTypeLikeHeader()
        XCTAssertEqual(type, "text/html")
        XCTAssertEqual(parameters["charset"]!, "UTF-8")

        (type, parameters) = "text/html; charset=\"UTF-8\"".parametersByParsingHTTPContentTypeLikeHeader()
        XCTAssertEqual(type, "text/html")
        XCTAssertEqual(parameters["charset"]!, "UTF-8")

        (type, parameters) = "text/html; charset='UTF-8'".parametersByParsingHTTPContentTypeLikeHeader()
        XCTAssertEqual(type, "text/html")
        XCTAssertEqual(parameters["charset"]!, "UTF-8")

        (type, parameters) = "something invalid".parametersByParsingHTTPContentTypeLikeHeader()
        XCTAssertEqual(type, "something invalid")
        XCTAssertNil(parameters["charset"])
    }

    func testEscapingToURLArgumentString() {
        var s = "& hello -_ world".stringByEscapingToURLArgumentString()
        XCTAssertEqual(s!, "%26%20hello%20-_%20world")

        s = " -._~abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890".stringByEscapingToURLArgumentString()
        XCTAssertEqual(s!, "%20-._~abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890")
    }

    func testUnescapingFromURLArgumentString() {
        var s = "%26%20hello%20-_%20world".stringByUnescapingFromURLArgumentString()
        XCTAssertEqual(s!, "& hello -_ world")

        s = "%20-._~abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890".stringByUnescapingFromURLArgumentString()
        XCTAssertEqual(s!, " -._~abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890")
    }

    func testFormURLEncodeDictionary() {
        let d = ["k1": ["v1"], "k2": ["&;", "hello"], "k3": ["world"], "k4": [1], "k5": [1, "v1"], "k6": "v6", "k7": 9]
        let s = FormURLEncodeDictionary(d)
        XCTAssertEqual(s, "k1=v1&k2=%26%3B&k2=hello&k3=world&k4=1&k5=1&k5=v1&k6=v6&k7=9")
    }

    func testQueryParametersByParsingURLString() {
        var (base, parameters) = "http://mydomain.com?k1=v1&k1=v11&k2=v2".queryParametersByParsingURLString()
        XCTAssertEqual(base!, "http://mydomain.com")
        XCTAssertEqual(FormURLEncodeDictionary(parameters), "k1=v1&k1=v11&k2=v2")

        (base, parameters) = "k1=v1&k1=v11&k2=v2".queryParametersByParsingURLString()
        XCTAssertNil(base)
        XCTAssertEqual(FormURLEncodeDictionary(parameters), "k1=v1&k1=v11&k2=v2")

        (base, parameters) = "http://mydomain.com".queryParametersByParsingURLString()
        XCTAssertEqual(base!, "http://mydomain.com")
        XCTAssertEqual(FormURLEncodeDictionary(parameters), "")
    }

    func testStringByMergingQueryParameters() {
        var URL = "http://domain.com?k1=v1&K2=v2".stringByMergingQueryParameters(["k3": ["v3"]])
        XCTAssertEqual(URL, "http://domain.com?k1=v1&k2=v2&k3=v3")

        // keys in both URL and parameters ("k1")
        URL = "http://domain.com?k1=v1&K2=v2".stringByMergingQueryParameters(["k3": ["v3"], "k1": ["v11"]])
        XCTAssertEqual(URL, "http://domain.com?k1=v1&k1=v11&k2=v2&k3=v3")

        // escapsed characters
        URL = "http://domain.com?k1=Content-Type%3Atext".stringByMergingQueryParameters(["k1": ["v1"]])
        XCTAssertEqual(URL, "http://domain.com?k1=Content-Type%3Atext&k1=v1")

        // values are single number
        URL = "http://domain.com?k1=Content-Type%3Atext".stringByMergingQueryParameters(["k1": 1])
        XCTAssertEqual(URL, "http://domain.com?k1=1&k1=Content-Type%3Atext")
    }

}
