//
//  Processor.swift
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

/**
The protocol you use to update `HTTPRequest` or `HTTPResponse`. Classes conform to this protocol convert
* data between request/response raw data and specific model object.
*/
public protocol HTTPProcessor {
    /**
    Process the specified `HTTPRequest`.

    - Parameter request: The `HTTPRequest` to process.
    */
    func processRequest(request: HTTPRequest) throws

    /**
    Process the specified `HTTPResponse`.

    - Parameter response: The `HTTPResponse` to process.
    */
    func processResponse(response: HTTPResponse) throws
}

/// This class add "Basic Authentication" header to the `HTTPRequest`.
public class HTTPBasicAuthProcessor: HTTPProcessor {
    public var username: String
    public var password: String

    public init(username: String, password: String) {
        self.username = username
        self.password = password
    }

    class func headerForUsername(username: String, password: String) -> String? {
        let str = "\(username):\(password)"
        guard let data = str.dataUsingEncoding(NSUTF8StringEncoding) else {
            return nil
        }
        let value = data.base64EncodedStringWithOptions([])
        return "Basic \(value)"
    }

    public func processRequest(request: HTTPRequest) throws {
        guard let header = HTTPBasicAuthProcessor.headerForUsername(self.username, password: self.password) else {
            throw Error.CannotEncodeString
        }

        request.core.setValue(header, forHTTPHeaderField: "Authorization")
    }

    public func processResponse(response: HTTPResponse) {
        fatalError("Not Implemented")
    }
}

/// This class add OAuth2 header `Authorization: Bearer [TOKEN]` to the `HTTPRequest`.
public class HTTPOAuth2Processor: HTTPProcessor {
    public var token: String

    public init(token: String) {
        self.token = token
    }

    class func headerForToken(token: String) -> String {
        return "Bearer \(token)"
    }

    public func processRequest(request: HTTPRequest) throws {
        let header = self.dynamicType.headerForToken(self.token)

        request.core.setValue(header, forHTTPHeaderField: "Authorization")
    }

    public func processResponse(response: HTTPResponse) {
        fatalError("Not Implemented")
    }
}

/// This class does nothing but assigns objects between `data` and `object`. For request, it assigns `object` to `data`, you need to ensure that `object` is a `NSData`. For response, it assigns `data` to `object`.
public class HTTPDataProcessor: HTTPProcessor {
    public init() {
    }

    public func processRequest(request: HTTPRequest) throws {
        if request.object == nil {
            request.data = nil
            return
        }

        if let object = request.object as? NSData {
            request.data = object
        } else {
            throw Error.TypeNotMatch
        }
    }

    public func processResponse(response: HTTPResponse) throws {
        response.object = response.data
    }
}

/// This class converts your String to request data, or converts the response data to a String. You probably don't need to use this class because HTTPResponse has built-in support for obtaining text and encoding. Use this class if you want to process the data off the main queue.
public class HTTPTextProcessor: HTTPProcessor {
    /// The encoding to use when converts your String to request data.
    public var writeEncoding = NSUTF8StringEncoding

    /// The encoding to use when converts request data to your String. If you don't specify a value, the encoding will be determine by examining the response.
    public var readEncoding: NSStringEncoding?

    public init() {
    }

    /// Determine the text encoding by examining the response.
    public static func textEncodingFromResponse(response: HTTPResponse) -> NSStringEncoding? {
        var charset: String?
        let contentType = response.valueForHTTPHeaderField("content-type")

        // Try charset in the header
        if contentType != nil {
            let (_, parameters) = contentType!.parametersByParsingHTTPContentTypeLikeHeader()
            charset = parameters["charset"]
            if charset != nil {
                let enc = CFStringConvertIANACharSetNameToEncoding(charset! as NSString)
                if enc != kCFStringEncodingInvalidId {
                    return CFStringConvertEncodingToNSStringEncoding(enc)
                }
            }
        }

        // Defaults to "ISO-8859-1" if there is no charset in header and
        // Content-Type contains "text" (RFC 2616, 3.7.1)
        if charset == nil && contentType != nil {
            if (contentType! as NSString).containsString("text") {
                let enc = CFStringBuiltInEncodings.ISOLatin1.rawValue
                return CFStringConvertEncodingToNSStringEncoding(enc)
            }
        }

        // Make a guess from the response body
        return NSString.stringEncodingForData(response.data, encodingOptions: nil, convertedString: nil, usedLossyConversion: nil)
    }

    /// String representation of the response body
    public static func textFromResponse(response: HTTPResponse) -> String? {
        let textEncoding = HTTPTextProcessor.textEncodingFromResponse(response)
        let encoding = response.textReadEncoding ?? textEncoding ?? NSUTF8StringEncoding
        return NSString(data: response.data, encoding: encoding) as? String
    }

    public func processRequest(request: HTTPRequest) throws {
        guard let str = request.object as? NSString else {
            throw Error.TypeNotMatch
        }

        if let data = str.dataUsingEncoding(self.writeEncoding) {
            request.data = data
        } else {
            throw Error.CannotEncodeString
        }
    }

    public func processResponse(response: HTTPResponse) throws {
        if let text = HTTPTextProcessor.textFromResponse(response) {
            response.object = text
        } else {
            throw Error.CannotEncodeString
        }
    }
}

/// This class converts objects between your dictionary and request data with JSON format. For request, header "Content-Type: application/json" will be added.
public class HTTPJSONProcessor: HTTPProcessor {
    public init() {
    }

    public func processRequest(request: HTTPRequest) throws {
        if let object = request.object {
            let data = try NSJSONSerialization.dataWithJSONObject(object, options: [])
            request.data = data
            request.core.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
    }

    public func processResponse(response: HTTPResponse) throws {
        response.object = try NSJSONSerialization.JSONObjectWithData(response.data, options: [.AllowFragments])
    }
}

/// This class converts your dictionary to a form encoded string as request body. For request, header "Content-Type: application/x-www-form-urlencoded" will be added.
public class HTTPFormProcessor: HTTPProcessor {
    public init() {
    }

    public func processRequest(request: HTTPRequest) throws {
        guard let d = request.object as? [String: AnyObject] else {
            throw Error.TypeNotMatch
        }

        request.data = FormURLEncodeDictionary(d).dataUsingEncoding(NSUTF8StringEncoding)
        request.core.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
    }

    public func processResponse(response: HTTPResponse) throws {
        fatalError("Not Implemented")
    }
}



