//
//  Common.swift
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

public extension String {
    // 4 + 26 + 26 + 10 = 66
    static let URIUnreservedCharacterSet = NSCharacterSet(charactersInString: "-._~abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890")

    /**
    Parse a Content-Type like string (e.g. "text/html; charset=UTF-8").

    - Returns: (type, parameters)
      - type: The Content-Type part of the string, or nil if not available.
      - parameters: A dictionary of the value pairs (the part after character ';').
    */
    public func parametersByParsingHTTPContentTypeLikeHeader() -> (type: String, parameters: [String: String]) {
        var type = ""
        var parameters = [String: String]()
        let ary = self.componentsSeparatedByString(";")
        let wset = NSCharacterSet.whitespaceCharacterSet()
        let qset = NSCharacterSet(charactersInString: "\"'")
        for (index, str) in ary.enumerate() {
            if index == 0 {
                type = str.stringByTrimmingCharactersInSet(wset)
            } else {
                guard let loc = str.characters.indexOf("=") else {
                    continue
                }

                var k = str[str.startIndex ..< loc]
                k = k.stringByTrimmingCharactersInSet(wset)
                if k.isEmpty {
                    continue
                }
                var v = str[loc.successor() ..< str.endIndex]
                v = v.stringByTrimmingCharactersInSet(wset)
                v = v.stringByTrimmingCharactersInSet(qset)
                parameters[k.lowercaseString] = v
            }
        }
        
        return (type, parameters)
    }

    /**
    Escape a string to an URL argument (RFC 3986).

    - Returns: Escaped string.
    */
    public func stringByEscapingToURLArgumentString() -> String? {
        // For maximum interoperability, URI producers are discouraged from percent-encoding unreserved characters.
        // https://tools.ietf.org/html/rfc3986
        // unreserved  = ALPHA / DIGIT / "-" / "." / "_" / "~"
        return self.stringByAddingPercentEncodingWithAllowedCharacters(String.URIUnreservedCharacterSet)
    }

    /**
    Unescape a URL argument (RFC 3986).

    - Returns: Unescaped version of the URL argument.
    */
    public func stringByUnescapingFromURLArgumentString() -> String? {
        let s = self.stringByReplacingOccurrencesOfString("+", withString: " ")
        return s.stringByRemovingPercentEncoding
    }

    /**
    Parse an URL string for query parameters.

    ```
    let (base, parameters) = "http://mydomain.com?k1=v1&k1=v11&k2=v2".queryParametersByParsingURLString()
    print(base!) // http://mydomain.com
    print(parameters) // ["k2": ["v2"], "k1": ["v1", "v11"]]
    ```

    - Returns: (URL, parameters)
      - URL: The none query part of the URL.
      - parameters: A dictionary contains the parameter pairs. The value of the pair is an array of String
    */
    public func queryParametersByParsingURLString() -> (URL: String?, parameters: [String: [String]]) {
        var base: String?
        var query: String
        var parameters = [String: [String]]()
        if let loc = self.characters.indexOf("?") {
            base = self[self.startIndex ..< loc]
            query = self[loc.successor() ..< self.endIndex]
        } else {
            query = self
        }
        let set = NSCharacterSet(charactersInString: "&;")
        let ary = query.componentsSeparatedByCharactersInSet(set)
        for str in ary {
            if let loc = str.characters.indexOf("=") {
                var k = str[str.startIndex ..< loc]
                if k.isEmpty {
                    continue
                }
                k = k.lowercaseString
                let s = str[loc.successor() ..< str.endIndex]
                if let v = s.stringByUnescapingFromURLArgumentString() {
                    if var values = parameters[k] {
                        values.append(v)
                        parameters[k] = values
                    } else {
                        parameters[k] = [v]
                    }
                } else {
                    NSLog("stringByUnescapingFromURLArgumentString failed for \(s)")
                }
            }
        }

        if base == nil && parameters.count == 0 {
            base = self
        }
        return (base, parameters)
    }

    /**
    Join the keys and values in the specified dictionary to build a "form-urlencoded" string, merge the result with `self` as an URL string. Duplicate keys appear in the URL and parameters will be merged properly.

    - Parameter parameters: A dictionary of key/value pairs to be merged to the URL string. The value of the pair can be an array of objects.

    - Returns: A new URL string with query merged from the original URL and the parameters.
    */
    public func stringByMergingQueryParameters(parameters: [String: AnyObject]) -> String {
        var (base, existing_params) = self.queryParametersByParsingURLString()
        var mergedParameters = existing_params as [String: AnyObject]
        for (var k, v) in parameters {
            k = k.lowercaseString
            if let values = existing_params[k] {
                var mergedValues = [AnyObject]()
                mergedValues.appendContentsOf(values as [AnyObject])
                if let ary = v as? [AnyObject] {
                    mergedValues.appendContentsOf(ary)
                } else {
                    mergedValues.append(v)
                }
                mergedParameters[k] = mergedValues
            } else {
                mergedParameters[k] = v
            }
        }

        let query = FormURLEncodeDictionary(mergedParameters)
        var ary = [String]()
        if base != nil {
            ary.append(base!)
        }
        if !query.isEmpty {
            ary.append(query)
        }
        return (ary as NSArray).componentsJoinedByString("?")
    }

}

/**
Join the keys and values in the specified dictioanry to build a "form-urlencoded" string. The key is separated from the value by `=' and key/value pairs are separated from each other by `&'. The value will be escaped before it joins the string. The order of the pairs in the joined string is sorted.

```
let d = ["k1": "v1", "k2": ["&;", "hello"], "k3": ["world"], "k4": [1, "v4"], "k5": 7]
let formEncoded = FormURLEncodeDictionary(d) // k1=v1&k2=%26%3B&k2=hello&k3=world&k4=1&k4=v4&k5=7
```

- Parameter dict: The dictionary to provide the key/value pairs. The key MUST be String and the value MUST be String (or value can be convert to String). The value can also be an array of objects.

- Returns: "form-urlencoded" string of the dictionary.
*/
public func FormURLEncodeDictionary(dict: [String: AnyObject]) -> String {
    var result = [String]()
    let keys = Array(dict.keys).sort {
        $0.localizedCaseInsensitiveCompare($1) == NSComparisonResult.OrderedAscending
    }

    for k in keys {
        guard let v = dict[k] else {
            result.append("\(k)=")
            continue
        }

        if let ary = v as? [AnyObject] {
            let v = (ary).map { String($0) }
            let value_list = v.sort {
                $0.localizedCaseInsensitiveCompare($1) == NSComparisonResult.OrderedAscending
            }
            for i in value_list {
                if let escaped = i.stringByEscapingToURLArgumentString() {
                    result.append("\(k)=\(escaped)")
                } else {
                    NSLog("Escaping \(i) for key \(k) returns nil")
                    result.append("\(k)=")
                }
            }
        } else {
            let s = String(v)
            if let escaped = s.stringByEscapingToURLArgumentString() {
                result.append("\(k)=\(escaped)")
            } else {
                NSLog("Escaping \(s) for key \(k) returns nil")
                result.append("\(k)=")
            }

        }
    }

    return (result as NSArray).componentsJoinedByString("&")
}


