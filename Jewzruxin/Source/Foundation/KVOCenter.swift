//
//  KVOCenter.swift
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

import Foundation

public typealias KeyValueObserverProxyCallback = (keyPath: String?, observed: AnyObject?, change: [NSObject: AnyObject]?, context: UnsafeMutablePointer<Void>) -> Void

public class KeyValueObserverProxy: NSObject {
    weak var observed: NSObject!
    weak var observer: AnyObject!
    var keyPath: String!
    var queue: NSOperationQueue?
    var context: UnsafeMutablePointer<Void>!
    var callback: KeyValueObserverProxyCallback!

    override public func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        if let queue = self.queue {
            queue.addOperationWithBlock {
                self.callback(keyPath: keyPath, observed:object, change:change, context:context)
            }
        } else {
            self.callback(keyPath: keyPath, observed:object, change:change, context:context)
        }
    }
}

public class KeyValueObservingCenter {
    class func defaultCenter() -> KeyValueObservingCenter {
        struct Singleton {
            static let sharedInstance = KeyValueObservingCenter()
        }

        return Singleton.sharedInstance
    }

    var dict = [NSValue: NSMutableArray]()

    public func addObserverForKeyPath(keyPath: String, object obj: NSObject, queue: NSOperationQueue? = nil, options: NSKeyValueObservingOptions = .New, context: UnsafeMutablePointer<Void> = nil, observer: NSObject? = nil, callback: KeyValueObserverProxyCallback) -> KeyValueObserverProxy {
        let proxy = KeyValueObserverProxy()
        proxy.observed = obj
        proxy.observer = observer ?? proxy
        proxy.keyPath = keyPath
        proxy.queue = queue
        proxy.context = context
        proxy.callback = callback

        let k = NSValue(nonretainedObject: proxy.observer)
        let proxies = self.dict[k] ?? NSMutableArray()
        proxies.addObject(proxy)

        obj.addObserver(proxy, forKeyPath: keyPath, options: options, context: context)
        return proxy
    }

    public func removeObserver(observer: NSObject, keyPath: String? = nil, observed: AnyObject? = nil) {
        if let _ = observer as? KeyValueObserverProxy {
            if observed != nil {
                assert(false, "The argument `observed` is supposed to be nil if the argument `observer` is a KeyValueObserverProxy!")
            }
        }

        let k = NSValue(nonretainedObject: observer)
        guard let proxies = self.dict[k] else {
            return
        }
        var proxiesToRemove = [AnyObject]()
        for i in proxies {
            let proxy = i as! KeyValueObserverProxy
            if keyPath != nil && keyPath != proxy.keyPath {
                continue
            }
            if observed != nil && observed !== proxy.observed {
                continue
            }
            proxiesToRemove.append(proxy)
            proxy.observed.removeObserver(proxy, forKeyPath: proxy.keyPath, context: proxy.context)
        }

        proxies.removeObjectsInArray(proxiesToRemove)
    } // func
}

