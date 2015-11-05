//
//  Cycle.swift
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
This class represents a HTTP request.
*/
public class HTTPRequest {
    /// The `NSMutableURLRequest` represents the primary request information.
    public let core: NSMutableURLRequest

    /// The object represents the request data, will be processed by the `HTTPProcessor` objects to build HTTP headers and body.
    public var object: AnyObject?

    /// The `NSDate` stores the time when the request is sent.
    public var timestamp: NSDate?

    /// The `NSData` to send as HTTP body.
    public var data: NSData? {
        get {
            if let body = self.core.HTTPBody {
                return body
            }
            return nil
        }
        set {
            self.core.HTTPBody = newValue
        }
    }

    /**
    Initialize a `HTTPRequest` object.

    - Parameter core: The `NSURLRequest` represents the primary request information.
    - Parameter object: The object represents the request data.
    */
    public init(core: NSURLRequest, object: AnyObject?) {
        self.core = core.mutableCopy() as! NSMutableURLRequest
        self.object = object
    }

    /**
    Initialize a `HTTPRequest` object.

    - Parameter core: The `NSURLRequest` represents the primary request information.
    */
    convenience public init(core: NSURLRequest) {
        self.init(core: core, object: nil)
    }
}

/**
This class represents a HTTP response.
*/
public class HTTPResponse {
    /// The `NSHTTPURLResponse` represents the primary response information.
    public var core: NSHTTPURLResponse!

    /// The object represents the response data. It will be created by the `HTTPProcessor` objects from response data.
    public var object: AnyObject?

    /// The `NSData` stores the received HTTP response body.
    public lazy var data: NSMutableData = NSMutableData()

    /// The `NSDate` stores the time when the response is received.
    public var timestamp: NSDate?

    /// The specific encoding to use when converting response body to text.
    public var textReadEncoding: NSStringEncoding?

    /// The encoding of the response body.
    public var textEncoding: NSStringEncoding? {
        return HTTPTextProcessor.textEncodingFromResponse(self)
    }

    /// The String representation of the HTTP response body
    public var text: String? {
        return HTTPTextProcessor.textFromResponse(self)
    }

    /// The status code of the response.
    public var statusCode: Int {
        return self.core.statusCode
    }

    /// The dictionary contains response headers.
    public var headers: [NSObject : AnyObject] {
        return self.core.allHeaderFields
    }

    /**
    Get value for a specified header. The search is case-insensitive.

    - Parameter header: The String represents the header to get the value of, case-insensitive.

    - Returns: The value of the header, or nil if not found.
    */
    public func valueForHTTPHeaderField(header: String) -> String? {
        return self.headers[header] as? String
    }

    /**
    Append the specified `NSData` to the property `data`.

    - Parameter data: The `NSData` to be appended to the property `data`.
    */
    public func appendData(data: NSData) {
        self.data.appendData(data)
    }
}

@objc public protocol HTTPSessionDelegate {
    optional func sessionShouldRetryCycle(session: HTTPSession, cycle: HTTPCycle, error: NSError?) -> Bool;
    optional func sessionShouldTreatStatusCodeAsFailure(session: HTTPSession, status: Int) -> Bool;
}

/**
This class manages `HTTPCycle` objects. You can also threat this class as a wrapper around `NSURLSession` and its delegates.
*/
@objc public class HTTPSession: NSObject, NSURLSessionDelegate, NSURLSessionTaskDelegate, NSURLSessionDataDelegate {
    public struct Constants {
        static let RetryPolicyMaximumRetryCount = 3
    }
    public weak var delegate: HTTPSessionDelegate?

    /// The `NSURLSession` takes care of the major HTTP operations.
    public var core: NSURLSession!

    /// The operation queue that the delegate related "callback" blocks will be added to. This queue will also be set as NSURLSession's delegate queue.
    public var delegateQueue: NSOperationQueue

    /// The operation queue that the work related "callback" blocks will be added to.
    public var workerQueue: NSOperationQueue

    /// An array of `HTTPProcessor` subclass objects, will be used to "process" the HTTPRequest.
    public var requestProcessors = [HTTPProcessor]()

    /// An array of `HTTPProcessor` subclass objects, will be used to "process" the HTTPResponse.
    public var responseProcessors = [HTTPProcessor]()

    /// An array of `HTTPAuthentication` subclass objects.
    public var authentications = [HTTPAuthentication]()

    /// Seconds to wait before a retry can be attempted.
    public var retryDelay = 3.0

    private var cycles = [HTTPCycle]()
    private var cyclesWithIdentifier = [String: HTTPCycle]()

    /// The singleton default HTTPSession.
    public static let defaultSession = HTTPSession()

    #if os(iOS)
    /**
    The `NetworkActivityIndicator` manages the display of network activity indicator. The default value is the singleton of the class. You can set it as nil (don't display the network spinning gear in status bar), or set it as an object of `NetworkActivityIndicator` subclass to custom the display logic.
    */
    public var networkActivityIndicator: NetworkActivityIndicator? = NetworkActivityIndicator.sharedInstance
    #endif

    /**
    Initialize a `HTTPSession` object.

    - Parameter configuration: The `NSURLSessionConfiguration` that the `NSURLSession` will be initialized with. If nil, the result of `NSURLSessionConfiguration.defaultSessionConfiguration()` will be used.
    - Parameter delegateQueue: The operation queue that the delegate related "callback" blocks will be added to. This queue will also be set as `NSURLSession`'s delegate queue. If nil, the result of `NSOperationQueue.mainQueue()` will be used.
    - Parameter workerQueue: The operation queue that the work related "callback" blocks will be added to. If nil, a `NSOperationQueue` object will be created so the blocks will be run asynchronously off the main thread.
    */
    public init(var configuration: NSURLSessionConfiguration? = nil, var delegateQueue: NSOperationQueue? = nil, var workerQueue: NSOperationQueue? = nil) {
        if configuration == nil {
            configuration = NSURLSessionConfiguration.defaultSessionConfiguration()
        }
        if delegateQueue == nil {
            delegateQueue = NSOperationQueue.mainQueue()
        }
        if workerQueue == nil {
            workerQueue = NSOperationQueue()
        }

        self.delegateQueue = delegateQueue!
        self.workerQueue = workerQueue!

        super.init()
        self.core = NSURLSession(configuration: configuration!, delegate:self, delegateQueue: self.delegateQueue)
    }

    public func indexOfCycle(cycle: HTTPCycle) -> Int? {
        return self.cycles.indexOf({ $0 === cycle })
    }

    /// Add a `HTTPCycle` to the internal collection.
    public func addCycle(cycle: HTTPCycle) {
        if let _ = self.indexOfCycle(cycle) {
            assert(false, "The HTTPCycle has already been added!")
            return
        }
        self.cycles.append(cycle)
        if let identifier = cycle.identifier {
            if self.cyclesWithIdentifier[identifier] != nil {
                assert(false, "Duplicate HTTPCycle identifier found!")
            }
            self.cyclesWithIdentifier[identifier] = cycle
        }
    }

    /// Remove a `HTTPCycle` from the internal collection.
    public func removeCycle(cycle: HTTPCycle) {
        guard let index = self.indexOfCycle(cycle) else {
            NSLog("The HTTPCycle to remove doesn't exist in the HTTPSession")
            return
        }
        self.cycles.removeAtIndex(index)
        if let identifier = cycle.identifier {
            self.cyclesWithIdentifier.removeValueForKey(identifier)
        }
    }

    public func cycleForTask(task: NSURLSessionTask) -> HTTPCycle? {
        guard let index = self.cycles.indexOf({ ($0 as HTTPCycle).core === task }) else {
            assert(false, "HTTPCycle not found for the specified NSURLSessionTask. Check if the NSURLSessionTask has been replaced, like start a HTTPCycle multiple times in the same loop")
            return nil
        }
        return self.cycles[index]
    }

    public func cycleForIdentifer(identifier: String) -> HTTPCycle? {
        return self.cyclesWithIdentifier[identifier]
    }

    public func cycleIdentifierDidChange(cycle: HTTPCycle, oldIdentifier: String?) {
        assert(cycle.identifier != nil)
        assert(!cycle.identifier!.isEmpty)

        guard let _ = self.indexOfCycle(cycle) else {
            NSLog("The HTTPCycle with changed identifier doesn't exist in the HTTPSession")
            return
        }
        if let identifier = oldIdentifier {
            self.cyclesWithIdentifier.removeValueForKey(identifier)
        }
        self.cyclesWithIdentifier[cycle.identifier!] = cycle
    }

    public func shouldRetry(solicited: Bool, retriedCount: Int, request: HTTPRequest, response:HTTPResponse, error: NSError?) -> Bool {
        if solicited {
            return true
        }

        if retriedCount > HTTPSession.Constants.RetryPolicyMaximumRetryCount {
            return false
        }

        if let e = error {
            if e.domain == NSURLErrorDomain && e.code == NSURLErrorTimedOut {
                return true
            }
        }

        if response.core != nil {
            if [408, 503].contains(response.statusCode) {
                return true
            }
        }

        return false
    }

    // MARK: NSURLSessionTaskDelegate
    public func URLSession(session: NSURLSession, task: NSURLSessionTask, didCompleteWithError error: NSError?) {
        #if os(iOS)
        if let indicator = self.networkActivityIndicator {
            indicator.decrease()
        }
        #endif

        guard let cycle = self.cycleForTask(task) else {
            NSLog("Cannot find cycle for the specific task in URLSession didCompleteWithError")
            return
        }
        if let e = error {
            if e.domain == NSURLErrorDomain && e.code == NSURLErrorCancelled {
                self.delegateQueue.addOperationWithBlock {
                    if !cycle.explicitlyCanceling {
                        cycle.completionHandler(cycle: cycle, error: error)
                    }
                }
                self.removeCycle(cycle)
                return
            }
        }

        var retry = false
        if let value = self.delegate?.sessionShouldRetryCycle?(self, cycle: cycle, error: error) {
            retry = value

        } else {
            retry = self.shouldRetry(cycle.solicited, retriedCount: cycle.retriedCount, request: cycle.request, response: cycle.response, error: error)
        }

        if retry {
            ++cycle.retriedCount
            let when = dispatch_time(DISPATCH_TIME_NOW, Int64(self.retryDelay * Double(NSEC_PER_SEC)));
            dispatch_after(when, dispatch_get_main_queue()) {
                cycle.restart()
            }
            return
        }

        if let response = task.response {
            guard let URLResponse = response as? NSHTTPURLResponse else {
                NSLog("The NSURLSessionTask's response is not a NSHTTPURLResponse")
                return
            }
            cycle.response.core = URLResponse
            cycle.response.timestamp = NSDate()

            var statusFailure = false
            if let value = self.delegate?.sessionShouldTreatStatusCodeAsFailure?(self, status: cycle.response.statusCode) {
                statusFailure = value
            } else {
                if cycle.response.statusCode >= 400 {
                    statusFailure = true
                }
            }
            if statusFailure {
                self.cycleDidFinish(cycle, error: Error.StatusCodeSeemsToHaveErred)
                return
            }
        }

        if error != nil {
            self.cycleDidFinish(cycle, error: error)
            return
        }

        self.workerQueue.addOperationWithBlock {
            for i in cycle.responseProcessors {
                do {
                    try i.processResponse(cycle.response)
                } catch {
                    self.cycleDidFinish(cycle, error: error)
                    return
                }
            }
            self.cycleDidFinish(cycle, error: nil)
        }
    }

    public func URLSession(session: NSURLSession, task: NSURLSessionTask, didSendBodyData bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64) {
        guard let cycle = self.cycleForTask(task) else {
            return
        }
        self.delegateQueue.addOperationWithBlock {
            cycle.didSendBodyDataHandler?(cycle: cycle, bytesSent: bytesSent, totalBytesSent: totalBytesSent, totalBytesExpectedToSend: totalBytesExpectedToSend)
        }
    }

    public func URLSession(session: NSURLSession, task: NSURLSessionTask, didReceiveChallenge challenge: NSURLAuthenticationChallenge, completionHandler: (NSURLSessionAuthChallengeDisposition, NSURLCredential?) -> Void) {
        guard let cycle = self.cycleForTask(task) else {
            return
        }

        var count = 0
        for handler in cycle.authentications {
            if handler.canHandleAuthenticationChallenge(challenge, cycle: cycle) {
                ++count
                let action = handler.actionForAuthenticationChallenge(challenge, cycle: cycle)
                handler.performAction(action, challenge: challenge, completionHandler: completionHandler, cycle: cycle)
            }
        }
        if count == 0 {
            completionHandler(NSURLSessionAuthChallengeDisposition.PerformDefaultHandling, nil)
        }
    }

    // MARK: NSURLSessionDataDelegate
    public func URLSession(session: NSURLSession, dataTask: NSURLSessionDataTask, didReceiveData data: NSData) {
        guard let cycle = self.cycleForTask(dataTask) else {
            return
        }
        cycle.response.appendData(data)
    }

    // MARK: NSURLSessionDownloadDelegate
    public func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didFinishDownloadingToURL location: NSURL) {
        guard let cycle = self.cycleForTask(downloadTask) else {
            return
        }
        cycle.downloadFileHandler!(cycle: cycle, location: location)
    }

    public func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        guard let cycle = self.cycleForTask(downloadTask) else {
            return
        }

        cycle.didWriteDataHandler?(cycle: cycle, bytesWritten: bytesWritten, totalBytesWritten: totalBytesWritten, totalBytesExpectedToWrite: totalBytesExpectedToWrite);
    }

    public func cycleDidFinish(cycle: HTTPCycle, error: ErrorType?) {
        self.delegateQueue.addOperationWithBlock {
            cycle.completionHandler(cycle: cycle, error: error)
            self.removeCycle(cycle)
        }
    }

    public func cycleDidStart(cycle: HTTPCycle) {
        #if os(iOS)
        if let indicator = self.networkActivityIndicator {
            indicator.increase()
        }
        #endif
    }

    /**
    Cancel an array of HTTP request operations.

    - Parameter cycles: An array of the `HTTPCycle` objects to cancel.
    - Parameter explicitly: Indicate if the operations are cancelled explicitly. The value will be stored in each `HTTPCycle`'s property `explicitlyCanceling`.
    */
    public func cancelCycles(cycles: [HTTPCycle], explicitly: Bool) {
        for cycle in cycles {
            cycle.explicitlyCanceling = explicitly
            if let core = cycle.core {
                core.cancel()
            }
        }
    }

    /**
    Cancel all outstanding tasks and then invalidates the session object. Once invalidated, references to the delegate and callback objects are broken. The session object cannot be reused.

    - Parameter explicitly: Indicate if the operations are cancelled explicitly.
    */
    public func invalidateAndCancel(explicitly: Bool) {
        for cycle in cycles {
            cycle.explicitlyCanceling = explicitly
        }
        self.core.invalidateAndCancel()
    }

    /**
    Invalidate the session, allowing any outstanding tasks to finish. This method returns immediately without waiting for tasks to finish. Once a session is invalidated, new tasks cannot be created in the session, but existing tasks continue until completion. After the last task finishes and the session makes the last delegate call, references to the delegate and callback objects are broken. Session objects cannot be reused.

    - Parameter explicitly: Indicate if the operations are cancelled explicitly.
    */
    public func finishTaskAndInvalidate(explicitly: Bool) {
        for cycle in cycles {
            cycle.explicitlyCanceling = explicitly
        }
        self.core.finishTasksAndInvalidate()
    }
}

/**
This class represents a HTTP "cycle", including request and response.
*/
@objc public class HTTPCycle: NSObject {
    public enum TaskType {
        case Data, Upload, Download
    }
    public enum UploadSource {
        case Data(NSData)
        case File(NSURL)
    }

    public typealias CompletionHandler = (cycle: HTTPCycle, error: ErrorType?) -> Void
    public typealias DidSendBodyDataHandler = (cycle: HTTPCycle, bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64) -> Void
    public typealias DidWriteBodyDataHandler = (cycle: HTTPCycle, bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) -> Void
    public typealias DownloadFileHander = (cycle: HTTPCycle, location: NSURL?) -> Void

    /// The type determines what kind of `NSURLSessionTask` to create. The default type is Data.
    public var taskType: TaskType

    /// Affect the `HTTPCycle`'s retry logic. If `solicited` is true, the number of retries is unlimited until the transfer finishes successfully.
    public var solicited = false

    /// The `NSURLSessionTask` that `HTTPCycle` creates for you.
    public var core: NSURLSessionTask?

    /// The `HTTPSession` acts as the manager of the `HTTPCycle`.
    public unowned var session: HTTPSession

    /// The identifier of a "cycle", supposed to be unique in one "service".
    public var identifier: String? {
        didSet {
            self.session.cycleIdentifierDidChange(self, oldIdentifier: oldValue)
        }
    }

    /// The `HTTPRequest` represents a HTTP request. `HTTPCycle` creates it for you, you should not create it by yourself.
    public var request: HTTPRequest

    /// The `HTTPResponse` represents a HTTP response. `HTTPCycle` creates it for you, you should not create it by yourself
    public var response: HTTPResponse!

    /// The number of retries have been attempted.
    public var retriedCount = 0

    /// Indicate if the operation was cancelled explicitly.
    public var explicitlyCanceling = false

    /// Called when the content of the given URL is retrieved or an error occurs.
    public var completionHandler: CompletionHandler!

    /// Called with upload progress information.
    public var didSendBodyDataHandler: DidSendBodyDataHandler?

    /// Called with download progress information.
    public var didWriteDataHandler: DidWriteBodyDataHandler?

    /// Called with the URL to a temporary file where the downloaded content is stored.
    public var downloadFileHandler: DownloadFileHander?

    /// The `NSData` or `NSURL` of a local file to upload for a upload task.
    public var uploadSource: UploadSource?

    /// The URL of the request.
    public var requestURL: NSURL {
        return self.request.core.URL!
    }

    /// The HTTP method of the request.
    public var requestMethod: String {
        get {
            return self.request.core.HTTPMethod
        }
        set {
            self.request.core.HTTPMethod = newValue
        }
    }

    /// An array of `HTTPAuthentication` subclass objects. If a HTTP task requires credentials, these objects will be enumerated one by one and `canHandleAuthenticationChallenge` will be invoked for each object against the same arguments. The `HTTPAuthentication` objects return true will be used to handle the authentication. If nil, the session's `authenticationHandlers` will be used.
    private var _authentications: [HTTPAuthentication]?
    public var authentications: [HTTPAuthentication] {
        get{
            if let authentications = self._authentications {
                return authentications
            }
            return self.session.authentications
        }
        set{
            self._authentications = newValue
        }
    }

    /// An array of HTTPProcessor subclass objects. Before the request is being sent, the HTTPRequest goes through all these processor objects to initialize the parameters. If nil, the session's `requestProcessors` will be used.
    private var _requestProcessors: [HTTPProcessor]?
    public var requestProcessors: [HTTPProcessor] {
        get{
            if let processors = self._requestProcessors {
                return processors
            }
            return self.session.requestProcessors
        }
        set{
            self._requestProcessors = newValue
        }
    }

    /// An array of `HTTPProcessor` subclass objects. When a transfer finishes successfully, the HTTPResponse goes through all these processor objects to build the response object. If nil, the session's `responseProcessors` will be used.
    private var _responseProcessors: [HTTPProcessor]?
    public var responseProcessors: [HTTPProcessor] {
        get{
            if let processors = self._responseProcessors {
                return processors
            }
            return self.session.responseProcessors
        }
        set{
            self._responseProcessors = newValue
        }
    }

    /**
    Initialize a `HTTPCycle` object.

    - Parameter requestURL: The `NSURL` of the request.
    - Parameter taskType: The `TaskType` indicates the type of `NSURLSessionTask` to create.
    - Parameter session: The `HTTPSession` to use for the HTTP operations.
    - Parameter requestMethod: The HTTP method for the request.
    - Parameter requestObject: The object represents the request data.
    - Parameter requestProcessors: An array of `HTTPProcessor` subclass objects.
    - Parameter responseProcessors: An array of `HTTPProcessor` subclass objects.
    */
    public init(requestURL: NSURL, taskType: HTTPCycle.TaskType = .Data, session: HTTPSession = HTTPSession.defaultSession, requestMethod: String = "GET", requestObject: AnyObject? = nil, requestProcessors: [HTTPProcessor]? = nil, responseProcessors: [HTTPProcessor]? = nil) {
        let r = NSURLRequest(URL: requestURL)
        self.request = HTTPRequest(core: r)
        self.request.object = requestObject
        self.taskType = taskType
        self.session = session
        self.request.core.HTTPMethod = requestMethod
        self._requestProcessors = requestProcessors
        self._responseProcessors = responseProcessors
        super.init()

        self.session.addCycle(self)
    }

    public func sessionTaskForType(type: TaskType) -> NSURLSessionTask {
        var task: NSURLSessionTask
        switch (self.taskType) {
        case .Data:
            task = self.session.core.dataTaskWithRequest(self.request.core)
        case .Upload:
            guard let source = self.uploadSource else {
                assert(false, "No source provided for an upload task")
            }
            switch source {
            case .Data(let data):
                task = self.session.core.uploadTaskWithRequest(self.request.core, fromData:data);
            case .File(let file):
                task = self.session.core.uploadTaskWithRequest(self.request.core, fromFile:file);
            }
        case .Download:
            assert(self.downloadFileHandler != nil);
            task = self.session.core.downloadTaskWithRequest(self.request.core);
        }
        return task
    }

    private func prepare(completionHandler: ((result: Bool, error: ErrorType?) -> Void)) {
        if self.core != nil {
            return
        }

        self.response = HTTPResponse()
        self.session.workerQueue.addOperationWithBlock {
            if (self.taskType == .Data) {
                for i in self.requestProcessors {
                    do {
                        try i.processRequest(self.request)
                    } catch {
                        NSOperationQueue.mainQueue().addOperationWithBlock {
                            completionHandler(result: false, error: error)
                        }
                    }
                }
            }

            NSOperationQueue.mainQueue().addOperationWithBlock {
                completionHandler(result: true, error: nil)
            }
        }
    }

    /**
    Start the HTTP request operation.

    - Parameter completionHandler: Called when the content of the given URL is retrieved or an error occurred.
    */
    public func start(completionHandler: CompletionHandler? = nil) {
        if completionHandler != nil {
            self.completionHandler = completionHandler
        }
        assert(self.completionHandler != nil)

        if let core = self.core {
            core.resume()
            return
        }

        guard let _ = self.session.indexOfCycle(self) else {
            // HTTPCycle already cancelled.
            // For example, cancelled when the cycle is waiting for a retry.
            return
        }

        self.prepare {(result, error) in
            if self.core != nil {
                // task could have been assigned and started in another thread
                return
            }

            if !result {
                self.session.cycleDidFinish(self, error: error)
                return
            }

            self.core = self.sessionTaskForType(self.taskType)
            self.request.timestamp = NSDate()
            self.core!.resume()
            self.session.cycleDidStart(self)
        }
        return
    }

    public func reset() {
        self.core = nil
        self.request.timestamp = nil
        self.response = nil
        self.explicitlyCanceling = false
    }

    /// Stop the current HTTP request operation and start again.
    public func restart() {
        self.cancel(true)
        self.reset()
        self.start()
    }

    /**
    Cancel the HTTP request operation.

    - Parameter explicitly: Indicate if the operation is cancelled explicitly. The value will be stored in property `explicitlyCanceling`. Your app can use this value for cancellation interface.
    */
    public func cancel(explicitly: Bool) {
        self.session.cancelCycles([self], explicitly:explicitly)
    }
}
