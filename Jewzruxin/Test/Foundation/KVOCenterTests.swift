//
//  KVOCenterTests.swift
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

class MyObjectToObserve: NSObject {
    dynamic var iVar = 123
    dynamic var anotheriVar = "abc"
}


class KVOCenterTests: XCTestCase {
    let objectToObserve = MyObjectToObserve()

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testAddObserverShouldWork() {
        var result = 0
        var callbackContextObject: AnyObject?

        let center = KeyValueObservingCenter.defaultCenter()
        let callback: KeyValueObserverProxy.KeyValueObserverProxyCallback = {
            keyPath, observed, change, contextObject in
            result = observed!.iVar
            callbackContextObject = contextObject
        }
        let proxy = center.addObserverForKeyPath("iVar", object: self.objectToObserve, callback: callback)
        self.objectToObserve.iVar = 456
        XCTAssertEqual(result, 456)
        XCTAssertNil(callbackContextObject)

        center.removeObserver(proxy)
        self.objectToObserve.iVar = 789
        XCTAssertEqual(result, 456)
    }

    func testRemoveWithObserverShouldWork() {
        var result1 = 0
        var result2 = ""
        var callbackContextObject1: AnyObject?
        var callbackContextObject2: AnyObject?

        let center = KeyValueObservingCenter.defaultCenter()
        let callback1: KeyValueObserverProxy.KeyValueObserverProxyCallback = {
            keyPath, observed, change, contextObject in
            result1 = observed!.iVar
            callbackContextObject1 = contextObject
        }
        let callback2: KeyValueObserverProxy.KeyValueObserverProxyCallback = {
            keyPath, observed, change, contextObject in
            result2 = observed!.anotheriVar
            callbackContextObject2 = contextObject
        }
        center.addObserverForKeyPath("iVar", object: self.objectToObserve, contextObject:self, callback: callback1)
        center.addObserverForKeyPath("anotheriVar", object: self.objectToObserve, contextObject:self, callback: callback2)
        self.objectToObserve.iVar = 456
        self.objectToObserve.anotheriVar = "def"
        XCTAssertEqual(result1, 456)
        XCTAssertEqual(result2, "def")
        XCTAssertTrue(callbackContextObject1 === self)
        XCTAssertTrue(callbackContextObject2 === self)

        center.removeObserver(self)
        self.objectToObserve.iVar = 789
        self.objectToObserve.anotheriVar = "ghi"
        XCTAssertEqual(result1, 456)
        XCTAssertEqual(result2, "def")
    }

    func testRemoveWithKeyPathShouldWork() {
        var result1 = 0
        var result2 = ""
        var callbackContextObject1: AnyObject?
        var callbackContextObject2: AnyObject?

        let center = KeyValueObservingCenter.defaultCenter()
        let callback1: KeyValueObserverProxy.KeyValueObserverProxyCallback = {
            keyPath, observed, change, contextObject in
            result1 = observed!.iVar
            callbackContextObject1 = contextObject
        }
        let callback2: KeyValueObserverProxy.KeyValueObserverProxyCallback = {
            keyPath, observed, change, contextObject in
            result2 = observed!.anotheriVar
            callbackContextObject2 = contextObject
        }
        center.addObserverForKeyPath("iVar", object: self.objectToObserve, contextObject:self, callback: callback1)
        center.addObserverForKeyPath("anotheriVar", object: self.objectToObserve, contextObject:self, callback: callback2)
        self.objectToObserve.iVar = 456
        self.objectToObserve.anotheriVar = "def"
        XCTAssertEqual(result1, 456)
        XCTAssertEqual(result2, "def")
        XCTAssertTrue(callbackContextObject1 === self)
        XCTAssertTrue(callbackContextObject2 === self)

        center.removeObserver(self, keyPath: "anotheriVar")
        self.objectToObserve.iVar = 789
        self.objectToObserve.anotheriVar = "ghi"
        XCTAssertEqual(result1, 789)
        XCTAssertEqual(result2, "def")
    }

}
