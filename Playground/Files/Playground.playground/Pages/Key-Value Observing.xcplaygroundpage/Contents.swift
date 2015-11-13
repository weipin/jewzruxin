//: [Previous](@previous)

import Foundation

import Foundation
import XCPlayground

import JewzruxinMac

/*:
### Helper classes for Key-Value Observing
*/

class MyObjectToObserve: NSObject {
    dynamic var iVar = 123
    dynamic var anotheriVar = "abc"
}
let objectToObserve = MyObjectToObserve()

class Foo {

}
let foo = Foo()

/*:
1. Add Key-Value Observing bindings
*/
var result1 = 0
var result2 = ""

let center = KeyValueObservingCenter.defaultCenter()
let callback1: KeyValueObserverProxy.KeyValueObserverProxyCallback = {
    keyPath, observed, change, contextObject in
    result1 = observed!.iVar
}
let callback2: KeyValueObserverProxy.KeyValueObserverProxyCallback = {
    keyPath, observed, change, contextObject in
    result2 = observed!.anotheriVar
}
let proxy = center.addObserverForKeyPath("iVar", object: objectToObserve, contextObject: foo, callback: callback1)
center.addObserverForKeyPath("anotheriVar", object: objectToObserve, contextObject: foo, callback: callback2)
objectToObserve.iVar = 123
objectToObserve.anotheriVar = "abc"
print("1. result1: \(result1), result2: \(result2)")

/*:
2. Remove binding with the context object
*/
center.removeObserverForContextObject(foo, keyPath: "anotheriVar")
objectToObserve.iVar = 456
objectToObserve.anotheriVar = "def"
print("1. result1: \(result1), result2: \(result2)")

/*:
3. Remove binding with the KeyValueObserverProxy
*/
center.removeObserverForProxy(proxy)
objectToObserve.iVar = 789
objectToObserve.anotheriVar = "ghi"
print("1. result1: \(result1), result2: \(result2)")

//: [Next](@next)
