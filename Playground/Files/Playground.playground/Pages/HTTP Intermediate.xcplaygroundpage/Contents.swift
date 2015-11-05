//: [Previous](@previous)

import Foundation
import XCPlayground

import JewzruxinMac

XCPlaygroundPage.currentPage.needsIndefiniteExecution = true

/*:
### Formal methods
Using the formal methods is less convenient but more flexible, unleashing the full ability.
*/

/*:
1. GET content from the specified URL.
*/
let URL = NSURL(string: BaseURL + "/core/playground/hello/")!
let cycle = HTTPCycle(requestURL: URL)

cycle.start {(cycle, error) in
    if error != nil {
        print(error)
        return
    }
    let text = cycle.response.text!
}


//: [Next](@next)
