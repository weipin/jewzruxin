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

/**
 An object of this class can act as observer of Key-Value Observing, a proxy of the underlying closure (`callback`). You should not create KeyValueObserverProxy by yourself: The KeyValueObservingCenter creates KeyValueObserverProxy for you. You can use KeyValueObserverProxy objects to remove specific key-value observing.
 */
public class KeyValueObserverProxy: NSObject {
    public typealias KeyValueObserverProxyCallback = (keyPath: String?, observed: AnyObject?, change: [NSObject: AnyObject]?, contextObject: AnyObject?) -> Void
    
    weak var observed: NSObject!
    weak var contextObject: AnyObject?
    var keyPath: String
    var queue: NSOperationQueue?
    var callback: KeyValueObserverProxyCallback

    init(observed: NSObject, contextObject: AnyObject?, keyPath: String, queue: NSOperationQueue?, callback: KeyValueObserverProxyCallback) {
        self.observed = observed
        self.contextObject = contextObject
        self.keyPath = keyPath
        self.queue = queue
        self.callback = callback
    }

    override public func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        if let queue = self.queue {
            queue.addOperationWithBlock {
                self.callback(keyPath: keyPath, observed:object, change:change, contextObject:self.contextObject)
            }
        } else {
            self.callback(keyPath: keyPath, observed:object, change:change, contextObject:self.contextObject)
        }
    }
}

/**
An KeyValueObservingCenter object provides an easy way to add/remove Key-Value Observing bindings.
 */
public class KeyValueObservingCenter {
    /**
     Returns the default KeyValueObservingCenter.
     */
    public class func defaultCenter() -> KeyValueObservingCenter {
        struct Singleton {
            static let sharedInstance = KeyValueObservingCenter()
        }

        return Singleton.sharedInstance
    }

    var dict = [NSValue: NSMutableArray]()

    func addProxy(proxy: KeyValueObserverProxy, withObject object: AnyObject) {
        let k = NSValue(nonretainedObject: object)
        var proxies = self.dict[k]
        if proxies == nil {
            proxies = NSMutableArray()
            self.dict[k] = proxies
        }
        proxies!.addObject(proxy)
    }

    /**
     Adds a key-value binding to the specified object (the observed), with a closure and an optional queue, and few optional arguments.

     - Parameter keyPath: The key path, relative to `object`, to the value that has changed.
     - Parameter object: The source object of the key path keyPath.
     - Parameter queue: The operation queue to which the `callback` should be added.
     - Parameter options: A combination of the NSKeyValueObservingOptions values that specifies what is included in observation notifications.
     - Parameter contextObject: An object that is passed to the `callback` closure, can be used to remove the binding.
     - Parameter callback: The closure to be executed when the value at the specified key path relative to the given object has changed.
     
     - Returns: The KeyValueObserverProxy acts as the observer.
     */
    public func addObserverForKeyPath(keyPath: String, object obj: NSObject, queue: NSOperationQueue? = nil, options: NSKeyValueObservingOptions = .New, contextObject: AnyObject? = nil, callback: KeyValueObserverProxy.KeyValueObserverProxyCallback) -> KeyValueObserverProxy {
        let proxy = KeyValueObserverProxy(observed: obj, contextObject: contextObject, keyPath: keyPath, queue: queue, callback: callback)

        self.addProxy(proxy, withObject: proxy)
        if contextObject != nil {
            self.addProxy(proxy, withObject: contextObject!)
        }

        obj.addObserver(proxy, forKeyPath: keyPath, options: options, context: nil)
        return proxy
    }

    /**
     Breaks key-value bindings with the specified contextObject, with an optional keyPath and an optional observed object.

     - Parameter contextObject: The context object associates with the bindings.
     - Parameter keyPath: The key path of the bindings.
     - Parameter observed: The observed object of the bindings.
     */
    public func removeObserverForContextObject(contextObject: AnyObject, keyPath: String? = nil, observed: AnyObject? = nil) {
        assert(!(contextObject is KeyValueObserverProxy), "Call `removeObserverForProxy` instead!")

        let k = NSValue(nonretainedObject: contextObject)
        guard let proxies = self.dict[k] else {
            NSLog("KeyValueObserverProxy list not found for contextObject \(contextObject)!")
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
            proxy.observed.removeObserver(proxy, forKeyPath: proxy.keyPath)
        }

        for i in proxiesToRemove {
            let proxy = i as! KeyValueObserverProxy
            let k = NSValue(nonretainedObject: proxy)
            self.dict.removeValueForKey(k)
        }
        proxies.removeObjectsInArray(proxiesToRemove)
    } // func

    /**
    Breaks key-value bindings with the specified KeyValueObserverProxy.
    */
    public func removeObserverForProxy(proxy: KeyValueObserverProxy) {
        proxy.observed.removeObserver(proxy, forKeyPath: proxy.keyPath)

        let k = NSValue(nonretainedObject: proxy)
        self.dict.removeValueForKey(k)
    }
}

