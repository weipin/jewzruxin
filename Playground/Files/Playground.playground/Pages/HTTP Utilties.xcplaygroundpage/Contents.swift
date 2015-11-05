//: [Previous](@previous)

import Foundation
import XCPlayground

import JewzruxinMac

/*:
### HTTP utilities
*/

/*:
1. Expanding a URI Template with values.
*/
let str = ExpandURITemplate("{?x,y,list*}", values: ["x": "hello world", "y": 7, "list": ["red", "green", "blue"]])


/*:
2. Escape to URL argument string.
*/
let escaped = "& hello -_ world".stringByEscapingToURLArgumentString()

/*:
3. Unescape from URL argument string.
*/
let unescaped = "%26%20hello%20-_%20world".stringByUnescapingFromURLArgumentString()

/*:
4. Parse URL with query parameters.
*/
let (base, parameters) = "http://mydomain.com?k1=v1&k1=v11&k2=v2".queryParametersByParsingURLString()
print(base!)
print(parameters)

/*:
5. URL encode a dictionary.
*/
let d = ["k1": "v1", "k2": ["&;", "hello"], "k3": ["world"], "k4": [1, "v4"], "k5": 7]
let formEncoded = FormURLEncodeDictionary(d)

//: [Next](@next)
