//
//  Cycle+Convenience.swift
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

public extension HTTPCycle {
    public static func URLForString(URLString: String, parameters: [String: AnyObject]? = nil) -> NSURL? {
        var str = URLString
        if URLString == "" {
            return nil
        }
        if parameters != nil {
            // To leave the original URL as it was, only "merge" if `parameters` isn't empty.
            str = URLString.stringByMergingQueryParameters(parameters!)
        }
        var URL = NSURL(string: str)
        if URL == nil {
            // May have illegal parts in the URL parameters, try merge first
            // (so the query parameters in the URL part can be encoded) if we haven't.
            if parameters == nil {
                str = URLString.stringByMergingQueryParameters([:])
            }
            URL = NSURL(string: str)
            if URL == nil {
                // If still fails, the base URL could also have illegal parts,
                // encode the entire URL anyway
                if let s = str.stringByEscapingToURLArgumentString() {
                    URL = NSURL(string: s)
                }
            }
        }

        return URL
    }

    public class func createAndStartCycle(URLString: String, method: String, parameters: [String: AnyObject]? = nil, requestObject: AnyObject? = nil, requestProcessors: [HTTPProcessor]? = nil, responseProcessors: [HTTPProcessor]? = nil, authentications: [HTTPAuthentication]? = nil, solicited: Bool = false, completionHandler: HTTPCycle.CompletionHandler) throws -> HTTPCycle {
        guard let URL = self.URLForString(URLString, parameters: parameters) else {
            throw Error.InvalidURL
        }
        let cycle = HTTPCycle(requestURL: URL, taskType: .Data, requestMethod: method, requestObject: requestObject, requestProcessors: requestProcessors, responseProcessors: responseProcessors)
        if authentications != nil {
            cycle.authentications = authentications!
        }
        cycle.solicited = solicited
        cycle.start(completionHandler)
        return cycle
    }

    /**
    Send a GET request and retrieve the content of the given URL.

    - Parameter URLString: The URL string of the request.
    - Parameter parameters: The parameters of the query.
    - Parameter requestProcessors: An array of `HTTPProcessor` subclass objects.
    - Parameter responseProcessors: An array of `HTTPProcessor` subclass objects.
    - Parameter authentications: An array of `HTTPAuthentication` objects.
    - Parameter solicited: Affect the `HTTPCycle`'s retry logic. If solicited is true, the number of retries is unlimited until the transfer finishes successfully.
    - Parameter completionHandler: Called when the content of the given URL is retrieved or an error occurs.
     
    - Throws: `Error.InvalidURL` if the parameter `URLString` is invalid.
    */
    public class func get(URLString: String, parameters: [String: AnyObject]? = nil, requestProcessors: [HTTPProcessor]? = nil, responseProcessors: [HTTPProcessor]? = nil, authentications: [HTTPAuthentication]? = nil, solicited: Bool = false, completionHandler: HTTPCycle.CompletionHandler) throws -> HTTPCycle {
        return try self.createAndStartCycle(URLString, method: "GET", parameters: parameters, requestProcessors: requestProcessors, responseProcessors:responseProcessors, authentications: authentications, solicited: solicited, completionHandler: completionHandler)
    }

    /// Send a HEAD request and retrieve the content of the given URL.
    public class func head(URLString: String, parameters: [String: AnyObject]? = nil, requestProcessors: [HTTPProcessor]? = nil, responseProcessors: [HTTPProcessor]? = nil, authentications: [HTTPAuthentication]? = nil, solicited: Bool = false, completionHandler: HTTPCycle.CompletionHandler) throws -> HTTPCycle {
        return try self.createAndStartCycle(URLString, method: "HEAD", parameters: parameters, requestProcessors: requestProcessors, responseProcessors: responseProcessors, authentications: authentications, solicited: solicited, completionHandler: completionHandler)
    }

    /// Send a POST request and retrieve the content of the given URL.
    public class func post(URLString: String, parameters: [String: AnyObject]? = nil, requestObject: AnyObject? = nil, requestProcessors: [HTTPProcessor]? = nil, responseProcessors: [HTTPProcessor]? = nil, authentications: [HTTPAuthentication]? = nil, solicited: Bool = false, completionHandler: HTTPCycle.CompletionHandler) throws -> HTTPCycle {
        return try self.createAndStartCycle(URLString, method: "POST", parameters: parameters, requestObject: requestObject, requestProcessors: requestProcessors, responseProcessors: responseProcessors, authentications: authentications, solicited: solicited, completionHandler: completionHandler)
    }

    /// Send a PUT request and retrieve the content of the given URL.
    public class func put(URLString: String, parameters: [String: AnyObject]? = nil, requestObject: AnyObject? = nil, requestProcessors: [HTTPProcessor]? = nil, responseProcessors: [HTTPProcessor]? = nil, authentications: [HTTPAuthentication]? = nil, solicited: Bool = false, completionHandler: HTTPCycle.CompletionHandler) throws -> HTTPCycle {
        return try self.createAndStartCycle(URLString, method: "PUT", parameters: parameters, requestObject: requestObject, requestProcessors: requestProcessors, responseProcessors: responseProcessors, authentications: authentications, solicited: solicited, completionHandler: completionHandler)
    }

    /// Send a PATCH request and retrieve the content of the given URL.
    public class func patch(URLString: String, parameters: [String: AnyObject]? = nil, requestObject: AnyObject? = nil, requestProcessors: [HTTPProcessor]? = nil, responseProcessors: [HTTPProcessor]? = nil, authentications: [HTTPAuthentication]? = nil, solicited: Bool = false, completionHandler: HTTPCycle.CompletionHandler) throws -> HTTPCycle {
        return try self.createAndStartCycle(URLString, method: "PATCH", parameters: parameters, requestObject: requestObject, requestProcessors: requestProcessors, responseProcessors: responseProcessors, authentications: authentications, solicited: solicited, completionHandler: completionHandler)
    }

    /// Send a DELETE request and retrieve the content of the given URL.
    public class func delete(URLString: String, parameters: [String: AnyObject]? = nil, requestObject: AnyObject? = nil, requestProcessors: [HTTPProcessor]? = nil, responseProcessors: [HTTPProcessor]? = nil, authentications: [HTTPAuthentication]? = nil, solicited: Bool = false, completionHandler: HTTPCycle.CompletionHandler) throws -> HTTPCycle {
        return try self.createAndStartCycle(URLString, method: "DELETE", parameters: parameters, requestObject: requestObject, requestProcessors: requestProcessors, responseProcessors: responseProcessors, authentications: authentications, solicited: solicited, completionHandler: completionHandler)
    }

    /**
    Upload data to the given URL.

    - Parameter URLString: The URL of the request.
    - Parameter source: The data to upload.
    - Parameter parameters: The parameters of the query.
    - Parameter authentications: An array of `HTTPAuthentication` objects.
    - Parameter didSendDataHandler: Called with upload progress information.
    - Parameter completionHandler: Called when the content of the given URL is retrieved or an error occurs.

    - Throws: `Error.InvalidURL` if the parameter `URLString` is invalid.

    - Returns: A new `HTTPCycle`.
    */
    public class func upload(URLString: String, source: HTTPCycle.UploadSource, parameters: [String: AnyObject]? = nil, authentications: [HTTPAuthentication]? = nil, didSendBodyDataHandler: HTTPCycle.DidSendBodyDataHandler? = nil, completionHandler: HTTPCycle.CompletionHandler) throws -> HTTPCycle {
        var str = URLString
        if parameters != nil {
            str = URLString.stringByMergingQueryParameters(parameters!)
        }
        guard let URL = NSURL(string: str) else {
            throw Error.InvalidURL
        }
        let cycle = HTTPCycle(requestURL: URL, taskType: .Upload, requestMethod: "POST")
        if authentications != nil {
            cycle.authentications = authentications!
        }
        cycle.uploadSource = source
        cycle.didSendBodyDataHandler = didSendBodyDataHandler
        cycle.start(completionHandler)
        return cycle
    }

    /**
    Download data from the given URL.

    - Parameter URLString: The URL of the request.
    - Parameter parameters: The parameters of the query.
    - Parameter authentications: An array of `HTTPAuthentication` objects.
    - Parameter didWriteDataHandler: Called with download progress information.
    - Parameter downloadFileHandler: Called with the URL to a temporary file where the downloaded content is stored.
    - Parameter completionHandler: Called when the content of the given URL is retrieved or an error occurs.

    - Throws: `Error.InvalidURL` if the parameter `URLString` is invalid.

    - Returns: A new `HTTPCycle`.
    */
    public class func download(URLString: String, parameters: [String: AnyObject]? = nil, authentications: [HTTPAuthentication]? = nil, didWriteDataHandler: HTTPCycle.DidWriteBodyDataHandler? = nil, downloadFileHandler: HTTPCycle.DownloadFileHander, completionHandler: HTTPCycle.CompletionHandler) throws -> HTTPCycle {
        var str = URLString
        if parameters != nil {
            str = URLString.stringByMergingQueryParameters(parameters!)
        }
        guard let URL = NSURL(string: str) else {
            throw Error.InvalidURL
        }
        let cycle = HTTPCycle(requestURL: URL, taskType: .Download, requestMethod: "GET")
        if authentications != nil {
            cycle.authentications = authentications!
        }
        cycle.didWriteDataHandler = didWriteDataHandler
        cycle.downloadFileHandler = downloadFileHandler
        cycle.start(completionHandler)
        return cycle
    }
}
