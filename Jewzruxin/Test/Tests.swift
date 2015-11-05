//
//  Tests.swift
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

import Foundation

let Timeout = 20.0

func t_(lastComponent: String) -> String {
    let base = "http://127.0.0.1:8000"
    let str = base + lastComponent

    return str
}

func tu_(lastComponent: String) -> NSURL {
    let str = t_(lastComponent)
    let URL = NSURL(string: str)!

    return URL
}

/*
http://www.mikeash.com/pyblog/friday-qa-2011-07-22-writing-unit-tests.html
*/
func WaitForWithTimeout(timeout: NSTimeInterval, run: (Void) -> Bool) -> Bool {
    let start = NSProcessInfo().systemUptime
    while !run() && NSProcessInfo().systemUptime - start <= timeout {
        NSRunLoop.currentRunLoop().runMode(NSDefaultRunLoopMode, beforeDate: NSDate())
    }
    return run()
}
