Jewzruxin -- a Swift toolkit
====

[![Build Status](https://travis-ci.org/weipin/jewzruxin.svg)](https://travis-ci.org/weipin/jewzruxin)

At the moment of writing this README, Jewzruxin focuses on providing extensive HTTP utilities.

Jewzruxin follows the Swift convention and is compatible with the latest version of Swift.

[ I'd like to point out that I am not a native English speak: likely you will find mistakes in grammar here and there. Please don't give me a hard time for this, and feel free to correct me! ]

HTTP
----
Jewzruxin provides extensive HTTP utilities, helping you accomplish HTTP tasks easily and quickly. The resulting code is straightforward and easy to maintain. The routes are designed with MVC and user interface in mind: the `HTTCycle` family classes can be referenced and used individually, making it easy to embed `HTTCycle` into model objects. Options like `solicited`, `explicitlyCanceling`, and "creation option" (`Create`, `Reuse`, or `Replace`) encourage you to build friendly user interface.

Features:
- Straightforward interfaces make the resulting code easy to read and maintain.
- Thin wrappers around the NSURLSession family classes, no magic, no black boxes.
- Authentication support.
- "HTTPProcessors" help you build requests and handle responses, so you don't have to deal with form encoding, JSON serialization/deserialization, adding headers, parsing response, etc. In most cases, a dictionary is the only argument to provide, and the job will be done off the main thread.
- URI Template support, a full Swift implementation of RFC6570: can expand templates up to and including Level 4 in that specification.
- Profile-driven HTTP API routes: creating a library to interact with API endpoints becomes as simple as creating a configure file.

Requirements
====
- Mac OS X 10.10+, iOS 8.0+
- Xcode 7.1+

Playground
====
A [playground](https://developer.apple.com/library/ios/recipes/Playground_Help/Chapters/AboutPlaygrounds.html) is provided to help you explore the toolkit. The way to use the playground is a little bit different from the normal ones due to the involvement of the custom framework.

![](https://github.com/weipin/jewzruxin/blob/master/Docs/images/playground.png)

[IMPORTANT] If the project file "Jewzruxin.xcodeproj" is already open in Xcode, close it first before you open the playground workspace.

To interact with the sandbox environment, follow the steps below:
- Navigate to the folder Playground, open the workspace "Playground.xcworkspace" with Xcode.
- Build the framework (Command + B). To be more specific, you need to build the target "JewzruxinMac" (the playground only uses JewzruxinMac, the target selected by default).
- Now you can navigate between the playground pages, making changes and examining results.

Install
====
Jewzruxin, intended for internal, should be installed inside the application (Mac OS X app or iOS app) that uses it. The instruction below explains the steps to embed Jewzruxin in your application bundle.

- It's not necessary to create a workspace, using a single Xcode project for both your application and framework target simplifies setup.
- [IMPORTANT] If the project file "Jewzruxin.xcodeproj" is already open in Xcode, close it first.
- Navigate to the folder "Jewzruxin", drag the project file "Jewzruxin.xcodeproj" into the Project Navigator of your application's Xcode project.
 
  ![](https://github.com/weipin/jewzruxin/blob/master/Docs/images/add_framework.gif)

- Select your application target and switch to the "Build Phases" tab. In the "Target Dependencies" section, click + and choose the framework matches your deployment system: JewzruxiniOS for iOS or JewzruxinMac for Mac OS X. In the "Link Binary With Libraries" section, repeat the same action.

  ![](https://github.com/weipin/jewzruxin/blob/master/Docs/images/setup_framework.gif)
  
- Import the framework at the top of your code: `import JewzruxiniOS` for iOS or `import JewzruxinMac` for Mac OS X.
  
HTTP
====
Sandbox endpoints
----
Before jumping into the tutorial, it's necessary to introduce the sandbox endpoints. We will use these endpoints throughout the content below.

URL          |   Method   |  Parameters  |  Response
-------------|------------|--------------|-------------
/hello/      |   GET      |     n/a      | Return string "Hello World"
/dumpupload/ |   POST     |     n/a      | Return request body
/echo/       |   GET      |     n/a      | See the explanation below
scr
The endpoint "/echo/" has few parameters, each affects a particular part of the response:

1. "code": The status code to return, 200 by default.
1. "content": The response body to return.
1. "encoding": If presents, the content will be converted to binary data with the specified encoding.
1. "header": The headers to be added to the response.

Making requests
----
Making HTTP requests and handling HTTP responses is straightforward through a set of convenience methods:
```
try? HTTPCycle.get("http://jewzrux.in/core/playground/hello/") {
    cycle, error in
    if error != nil {
        print(error)
        return
    }
    let text = cycle.response.text // Hello World
}
```

You handle response or error in the closure, the last argument `completionHandler`. In the closure, the argument `cycle`, a HTTPCycle, contains the necessary data on both request and response.

The convenience methods return a HTTPCycle immediately and will throw an error if the specified URL is invalid.
```
do {
    try HTTPCycle.get("") {
        cycle, error in
        // Will never reach here
    }
} catch {
    print("The convenience methods return nil immediately for an invalid URL." )
}
```

Besides "GET", the rest of the convenience methods cover the other HTTP methods:
```
try? HTTPCycle.post("http://httpbin.org/post") {
    (cycle, error) in
}

try? HTTPCycle.put("http://httpbin.org/put") {
    (cycle, error) in
}

try? HTTPCycle.delete("http://httpbin.org/delete") {
    (cycle, error) in
}

try? HTTPCycle.head("http://httpbin.org/get") {
    (cycle, error) in
}
```

Architecture
----
### The `HTTPCycle` object
A `HTTPCycle` represents both HTTP request and HTTP response. To send a request, you create, configure, and start a `HTTPCycle`. To handle the response data, you examine the same `HTTPCycle`.

A `HTTPCycle` preserves the data of the request to be sent and the response retrieves. You can resend a request by simply invoking the method `restart` on a "prepared" `HTTPCycle`, even if it has already been "used".

### Thin wrappers
The HTTPCycle family classes are thin wrappers around the NSURLSession classes, all having a property `core`, pointing to the underlying Cocoa object. The table below explains the relationships:

  HTTPCycle family class  | Cocoa class
  ----------------------- | -----------------
  HTTPCycle               | NSURLSessionTask
  HTTPRequest             | NSMutableURLRequest
  HTTPResponse            | NSHTTPURLResponse
  HTTPSession             | NSURLSession


### Diagram

      +----------------------------------------+
      |                                        |
      |   +-------------+    +---------------+ |
      |   |             |    |               | |
      |   | HTTPRequest |    | HTTPResponse  | |
      |   +-------------+    +---------------+ |
      |                                        |
      |   HTTPCycle                            |
      |                                        |
      +----------------------------------------+
                         |
                         |
                   +-------------+
                   |             |
                   | HTTPSession |
                   +-------------+


Start a HTTPCycle
----

### Through convenience methods
The convenience methods create a `HTTPCycle` for you and send the request immediately. For example, to send a GET request, use the type method `get` of HTTPCycle:

```
try? HTTPCycle.get("http://jewzrux.in/core/playground/hello/") {
    cycle, error in
    if error != nil {
        print(error)
        return
    }
    let text = cycle.response.text // Hello World
}
```

`URLString` and `completionHandler` are required arguments, the rest ones are all optional and have default values. Because
`completionHandler` is the last argument, the code can be simplified with
[Trailing Closures](https://developer.apple.com/library/ios/documentation/Swift/Conceptual/Swift_Programming_Language/Closures.html#//apple_ref/doc/uid/TP40014097-CH11-ID102).

More type methods are available for the rest of the HTTP methods such as POST, PUT, DELETE, etc. Find the file "Cycle+Convenience.swift" for a complete list.

These convenience methods provide limited customization ability, and the request will be sent immediately. If you have needs beyond basic URL fetching, such as adding custom headers or delaying the request, you can make requests in two separate steps. The next section explains the details.

### Through two separate steps
* Create and configure a `HTTPCycle`.
* "Start" the `HTTPCycle`.

Creating a `HTTPCycle` is simple -- the only required argument is `requestURL`:
```
let URL = NSURL(string: "http://jewzrux.in/core/playground/hello/")!
let cycle = HTTPCycle(requestURL: URL)
```

The rest of the optional arguments will be discussed in the following sections.

With the newly created `HTTPCycle`, you call the method `start` to send a HTTP request:

```
cycle.start({(cycle, error) in
    if error != nil {
        print(error)
        return
    }
    let text = cycle.response.text!
}) 
```

You handle the response in the closure `completionHandler`. Because
`completionHandler` is the last argument, the code can be simplified with
[Trailing Closures](https://developer.apple.com/library/ios/documentation/Swift/Conceptual/Swift_Programming_Language/Closures.html#//apple_ref/doc/uid/TP40014097-CH11-ID102). The parentheses can also be omitted entirely because the closure is the only argument to the method:

```
cycle.start {(cycle, error) in
    // handle response or error
}
```

In the closure, you examine the argument `error` for the requesting result. Errors can be caused by HTTP connection, HTTPProcessor operations, HTTP status code, etc.

Custom headers
----
There is no way to add HTTP headers through the convenience methods. You need to create a `HTTPCycle` by yourself first:

```
let URL = NSURL(string: "http://jewzrux.in/core/playground/hello/")!
let cycle = HTTPCycle(requestURL: URL)
cycle.request.core.setValue("Jewzruxin/0.1.0", forHTTPHeaderField: "User-Agent")
cycle.start {(cycle, error) in
    // handle response or error
}
```

Cancelling
----
To cancel a request you need the `HTTPCycle` that the request associates to. If the request is issued by a convenience method, keep a reference of the `HTTPCycle` returns from the method:

```
let cycle = try? HTTPCycle.get("http://jewzrux.in/core/playground/hello/") {
    (cycle, error) in
    // ...
}
```

Call the method `cancel` of `HTTPCycle` to cancel the request. The argument `explicitly` indicates if the request is cancelled explicitly. The `explicitly` here is a user interface concept: whether or not the cancelling is issued by user. If `explicitly` is true, the closure `completionHandler` won't be called at the moment a connection is cancelled and it's your responsibility to perform the necessary actions "explicitly". 

To handle "implicitly" cancelling, you examine the argument `error` in the closure `completionHandler`:
```
let cycle = try? HTTPCycle.get("http://jewzrux.in/core/playground/hello/") {
    (cycle, error) in
    if let e = error as? NSError {
        if e.domain == NSURLErrorDomain && e.code == NSURLErrorCancelled {
            // Process cancelling
        }
    }
}
```

Adding query parameters to URL
----
To add query parameters to URL, pass a dictionary as the argument `parameters` to the convenience methods. The code snippet below adds a query parameter "content=dummy", making the URL become "http://jewzrux.in/core/playground/echo/?content=dummy":

```
try? HTTPCycle.get("http://jewzrux.in/core/playground/echo/", parameters: ["content": "dummy"]) {
    cycle, error in
    let text = cycle.response.text! // "dummy"
}
```

The type of the argument `parameter` is `[String: AnyObject]`. The value can be a single object or an array of objects that can be converted to String.

```
try? HTTPCycle.get("http://jewzrux.in/core/playground/echo/", parameters: ["content": ["dummy", 71]]) {
    cycle, error in
    let text = cycle.response.text! // "71, dummy"
}
```

If you choose to create a `HTTPCycle` by yourself, there is no such argument `parameters` to pass into a `HTTPCycle` initializer. It's easy to build an URL through the helper method `stringByMergingQueryParameters` (provided as String extension):
```
let URLString = "http://jewzrux.in/core/playground/echo/".stringByMergingQueryParameters(["content": "dummy"])
```

The method `stringByMergingQueryParameters` encodes the values, join the parameter pairs with character `&` and concatenate the following parts: the original URL, a character `?` and the query.

As the method name indicates, `stringByMergingQueryParameters` preserves the query in the original URL. The method parses the original query and merge them with the new ones. In the code snippet below, `key2` in the original URL and `key1` in the new parameters will both appear in the final URL:
```
// result: /hello/?key1=value1&key2=value2
let URLString = "/hello/?key2=value2".stringByMergingQueryParameters(["key1": "value1"])
```

Send request
----
### POST "raw" data

```
try? HTTPCycle.post("http://jewzrux.in/core/playground/dumpupload/",
    requestObject: "Hello World".dataUsingEncoding(NSUTF8StringEncoding),
    requestProcessors: [HTTPDataProcessor()]) {
        (cycle, error) in
        let text = cycle.response.text // Hello World
}
```

In the code snippet above, a NSData is past as the argument `requestObject` and a `HTTPDataProcessor` is created and passed in an array as the argument `requestProcessors`. The relationship between `requestObject` and `requestProcessors` will be explained in the following section.

Here is another example by creating a `HTTPCycle` manually:

```
let URL = NSURL(string: "http://jewzrux.in/core/playground/dumpupload/")!
let cycle = HTTPCycle(requestURL: URL, requestMethod: "POST")
cycle.request.data = "Hello World".dataUsingEncoding(NSUTF8StringEncoding)
cycle.start {
    (cycle, error) in
    let text = cycle.response.text // Hello World
}
```

### Send JSON request
By following the steps below, you can send requests in JSON format easily:

* Create a collection object and pass it as the argument `requestObject`.
* Create a `HTTPJSONProcessor`, put it into an array and pass the array as the argument `requestProcessors`.

```
try? HTTPCycle.post("http://jewzrux.in/core/playground/dumpupload/", requestObject: ["key1": "value1"], requestProcessors: [HTTPJSONProcessor()]) {
    (cycle, error) in
    let text = cycle.response.text // {"key1":"value1"}
}
```

The dictionary will be converted to a NSData in JSON format through the HTTPJSONProcessor. The NSData will then be assigned to the property `data` of HTTPRequest. The HTTPJSONProcessor will also set header "Content-Type" to "application/json".

### Send request with processors
There is always preparation work before a request can be sent. Take "Send JSON request" as an example, the tasks listed below are required:

* Create a NSData in JSON format from a collection object.
* Assign the NSData to the property `data` of HTTPRequest.
* Set header "Content-Type" to "application/json".

With Jewzruxin, you use `HTTPProcessor` subclass objects to complete such tasks. Each subclass of `HTTPProcessor` can handle a certain type of objects and prepare the `HTTPRequest` for you. `HTTPCycle` accepts an array of `HTTPProcessor` objects as the property `requestProcessors`. Before a request is being sent, each `HTTPProcessor` object in the `requestProcessors` will be given an opportunity to process the "HTTPRequest".

Handle response
----
### Status code
After a `HTTPCycle` successfully retrieves response, you can examine the HTTP status code through the property `statusCode` of HTTPResponse:
```
cycle.response.statusCode
```

`statusCode` is a [Computed Property](https://developer.apple.com/library/prerelease/ios/documentation/Swift/Conceptual/Swift_Programming_Language/Properties.html#//apple_ref/doc/uid/TP40014097-CH14-XID_329) which obtains its value from a `NSHTTPURLResponse`.

### Content
Use the property `text` of HTTPResponse to access the retrieved content.

```
print("\(cycle.response.text)") // Hello World
```

The property `text` is a `String` created from response data (the property
`data` of HTTPResponse). To properly create the String, the encoding of the content is required. Jewzruxin will try to find the encoding by examining the HTTP headers first. If the encoding cannot be determined, the response data itself will be examined to guess the encoding. There is one exception: if there is no "charset" in the headers and the Content-Type contains "text", the encoding will be defaulted to "ISO-8859-1" according to RFC 2616, 3.7.1. You can also explicitly specify the encoding through the property `textReadEncoding` of HTTPResponse.

### Headers
Response headers can be accessed through the method `valueForHTTPHeaderField` of HTTPResponse:

```
let value = cycle.response.valueForHTTPHeaderField("Content-Type")
```

The search is case-insensitive
```
let value = cycle.response.valueForHTTPHeaderField("cOnTEnt-Type")
```

The headers are also available as the property `headers` of HTTPResponse. `headers` is a Computed Property which obtains its value from a NSHTTPURLResponse.

### Error
Examine the argument `error` of the closure `completionHandler` for errors. Errors can be caused by network connection (NSURLErrorDomain), the HTTPCycle family classes, etc.

###  JSON response
For response data in JSON format, a common task is to convert the data back to a collection object. You can ask Jewzruxin do the job for your by creating a `HTTPJSONProcessor`, putting it into an array and passing the array as the argument `responseProcessors`:

```
try? HTTPCycle.post("http://jewzrux.in/core/playground/dumpupload/", requestObject: ["k1": "v1", "k2": 9, "k3": [17, "v3"]], requestProcessors: [HTTPJSONProcessor()], responseProcessors: [HTTPJSONProcessor()]) {
    cycle, error in
    if error != nil {
        print(error!)
        return
    }
    let text = cycle.response.text!
    let obj = cycle.response.object! // ["k3": [17, "v3"], "k2": 9, "k1": "v1"]
}
```

Jewzruxin converts the response data into a collection object through the HTTPJSONProcessor and then assign the object to the property `object` of HTTPResponse.

### Handle response with processors
Like HTTPRequest objects, HTTPResponse objects often require some extra work before you can use the data received. Take "JSON response" as an example, the tasks listed below are required:

* Create a collection object from response data in JSON format.
* Assign the collection object to the property `object` of HTTPResponse.

You still use HTTPProcessor subclass objects to "process" HTTPResponse. Each subclass of HTTPProcessor can handle a certain type of response data and prepare the HTTPResponse for you. A `HTTPCycle` accepts an array of HTTPProcessor subclass objects as the property `responseProcessors`. As soon as a response is received, each HTTPProcessor subclass object in the `responseProcessors` will be given an opportunity to "process" the HTTPResponse.

`object` and `data`
----
The property `object` and the property `data` are available in both classes `HTTPRequest` and `HTTPResponse`.

The `object`, a `AnyObject` type property, represents a "model". Depending on the context, it can be any type. For `HTTPRequest`, the `object` will be used to create request data. For `HTTPResponse`, the `object` will be used to store the model converted from the response data.

The `data`, a `NSData` type property, represents raw data. For `HTTPRequest`, the `data` is the request body to be sent. For `HTTPResponse`, the `data` is the response data received.

The converting between `object` and `data` is performed by the HTTPProcessor subclass objects. For `HTTPRequest`, the processors (`requestProcessors`) convert `object` into `data`. For `HTTPResponse`, the processors (`responseProcessors`) convert `data` into `object`.

Subclass HTTPProcessor 
----
You can subclass HTTPProcessor to fit your requirements. For example, new HTTPProcessor subclasses can be created to handle specific authentication types (adding headers or appending query parameters), or to handle response data in a particular format.

There are two methods to override: `processRequest` and `processResponse`. You don't have to override both if one of the methods is never going to be used.

Upload
----
The convenience method `upload` offers an easy way to upload a local file or a NSData.

Upload a local file:
```
let URL = NSBundle.mainBundle().URLForResource("hello", withExtension: "txt")!
let fileUploadSource = HTTPCycle.UploadSource.File(URL)
try? HTTPCycle.upload("http://jewzrux.in/core/playground/dumpupload/", source: fileUploadSource) {
    cycle, error in
    if error != nil {
        print(error!)
        return
    }
    let text = cycle.response.text! // "Hello World (FILE)"
}
```

Upload a NSData:
```
let data = "Hello World".dataUsingEncoding(NSUTF8StringEncoding)!
let dataUploadSource = HTTPCycle.UploadSource.Data(data)
try? HTTPCycle.upload("http://jewzrux.in/core/playground/dumpupload/", source: dataUploadSource) {
    cycle, error in
    if error != nil {
        print(error!)
        return
    }
    let text = cycle.response.text! // "Hello World"
}
```

To obtain upload progress information, pass a closure of type `HTTPCycle.DidSendBodyDataHandler` as the argument `didSendBodyDataHandler`:
```
let URL = NSBundle.mainBundle().URLForResource("hello", withExtension: "txt")!
let fileUploadSource = HTTPCycle.UploadSource.File(URL)
let didSendBodyDataHandler: HTTPCycle.DidSendBodyDataHandler = {
    (cycle, bytesSent, totalBytesSent, totalBytesExpectedToSend) in
    // handle progress
}
try? HTTPCycle.upload("http://jewzrux.in/core/playground/dumpupload/", source: fileUploadSource, didSendBodyDataHandler: didSendBodyDataHandler) {
    cycle, error in
    if error != nil {
        print(error!)
        return
    }
    let text = cycle.response.text!
}
```

Download
----
The convenience method `download` offers an easy way to download data from a specified URL.
```
let downloadFileHandler: HTTPCycle.DownloadFileHander = {
    (cycle: HTTPCycle, location: NSURL?) in
    let content = try! NSString(contentsOfURL: location!, encoding: NSUTF8StringEncoding) // helloworld
}
try? HTTPCycle.download("http://jewzrux.in/core/playground/echo?content=helloworld", downloadFileHandler: downloadFileHandler) {
    cycle, error in
    if error != nil {
        print(error!)
        return
    }
}
```

The closure `downloadFileHandler` will be called with the URL (`location`) to a
temporary file where the downloaded content is stored. At the time
`downloadFileHandler` is called, you are guaranteed that the content has been
fetched successfully. Errors can be examined in the closure `completionHandler`.

To obtain download progress information, pass a closure of type  `HTTPCycle.DidWriteBodyDataHandler` as the argument `didWriteDataHandler`:

```
let downloadFileHandler: HTTPCycle.DownloadFileHander = {
    (cycle: HTTPCycle, location: NSURL?) in
    let content = try! NSString(contentsOfURL: location!, encoding: NSUTF8StringEncoding)
}
let didWriteDataHandler: HTTPCycle.DidWriteBodyDataHandler = {
    (cycle, bytesWritten, totalBytesWritten, totalBytesExpectedToWrite) in
    // handle progress
} 
try? HTTPCycle.download("http://jewzrux.in/core/playground/echo?content=helloworld", didWriteDataHandler: didWriteDataHandler, downloadFileHandler: downloadFileHandler) {
    cycle, error in
    if error != nil {
        print(error!)
        return
    }
}
```

Auto retry
----
Jewzruxin will resend a request if one of the following conditions matches:

* The connection timed out.
* The response status code is 408 or 503.

Jewzruxin stops resending if the retried number exceeds the limit. The limit is controlled by the constant `HTTPSession.Constants.RetryPolicyMaximumRetryCount`. There is
one exception: if the property `solicited` of a `HTTPCycle` is true, the HTTPCycle will keep resending request, no matter what error happens, and without number limit, until data is received.

There is a delay before a new retry can be attempted. The interval is
controlled by the property `retryDelay` of HTTPSession.

Timeout
----
While you don't need to worry about the timeout because Jewzruxin will resend a request for you, it's possible to specify a custom timeout period. To accomplish the task, you create a NSURLSessionConfiguration, update the property `timeoutIntervalForRequest` and `timeoutIntervalForResource`, create a HTTPSession with this NSURLSessionConfiguration and create a HTTPCycle with the HTTPSession. The code snippet listed below sets the timeout to an unrealistic value of 1.0 second (Note: the query parameter `delay` of the sandbox endpoint is NOT publicly available). 
```
let configuration = NSURLSessionConfiguration.defaultSessionConfiguration()
configuration.timeoutIntervalForRequest = 1
configuration.timeoutIntervalForResource = 1
let session = HTTPSession(configuration: configuration)

let URL = NSURL(string: "http://jewzrux.in/core/playground/echo?delay=2")!
let cycle = HTTPCycle(requestURL: URL, session: session)
cycle.start {(cycle, error) in
...
}
```

Solicited request
----
`Solicited request` and `unsolicited request` is more of an user interface
concept. A `solicited request` is an operation specifically issued by user,
like tapping a button to reload a list. In such case, it's ideal for your app to keep resending the request no matter what error happens, until the response data is received successfully.

The solicited state is represented by the property `solicited` of HTTPCycle. If the value of `solicited` is true, Jewzruxin will keep resending the request until it receives the response data.

Most of the convenience methods accept an argument `solicited` which will be assigned as the property `solicited` of HTTPCycle.

HTTPSession
----
Each HTTPCycle references to a HTTPSession which does all the heavy lifting. The class HTTPSession is a thin wrapper around the class NSURLSession.

### The default session
If you don't pass in a HTTPSession when you create a HTTPCycle, the default HTTPSession will be used. The default HTTPSession is a singleton returned by the type method `defaultSession` of HTTPSession. If you change a property of this HTTPSession, the change will affect all the HTTPCycle objects reference to this session.

### Backing HTTPCycle properties through HTTPSession
It's common to have the same values for certain properties across multiple HTTPCycle objects. Jewzruxin offers a way to make this task easier. For these
properties, you can assign the values to a HTTPSession and leave the corresponding properties of the HTTPCycle objects as nil. The HTTPSession object these HTTPCycle objects reference to will provide the values.

For example, if you set an array of HTTPProcessor subclass objects as the property `requestProcessors` of a HTTPSession, all the HTTPCycle objects reference to this HTTPSession will return this array as the value of the property `requestProcessors`, as long as the property `requestProcessors` of the HTTPCycle is nil.

Here is the list of the properties that HTTPSession can back HTTPCycle:
* `requestProcessors`
* `responseProcessors`
* `authentications`

### Create and use HTTPSession
It's often necessary to create a HTTPSession by yourself and let the HTTPCycle objects reference to it. Creating a HTTPSession is easy: the arguments of the initializer are all optional.
```
let session = HTTPSession()
```

For further customization, you can create/configure a NSURLSessionConfiguration and pass it as the argument `configuration` of HTTPSession's initializer:

```
let configuration = NSURLSessionConfiguration.defaultSessionConfiguration()
let session = HTTPSession(configuration: configuration)
```
The other two arguments `delegateQueue` and `workerQueue` will be discussed in the next section.

Operation queues
----
Each HTTPSession has two properties for queues: `delegateQueue` and `workerQueue`. HTTPSession uses `delegateQueue` to schedule the "handlers", such as  `completionHandler` and `downloadFileHander`. The default value of `delegateQueue` is the main queue. `workerQueue` will be used to schedule tasks that require some time to finish, such as executing the HTTPProcessor objects. The default value of `workerQueue` is a new `NSOperationQueue`, to execute the tasks off the main thread.

The property `delegateQueue` of `HTTPSession` will also be passed as the argument `queue` of NSURLSession's initializer, making the same `delegateQueue` the queue for scheduling NSURLSession's delegate calls and completion handlers.

Authentication
----
Jewzruxin offers two different approaches for authentication handling. One is provided through the URL loading system with classes such as `NSURLCredential`, `NSURLProtectionSpace`, `NSURLAuthenticationChallenge`, etc. The other is provided by preparing the request manually or through HTTPProcessor objects.

### Authentication through URL loading system
To add authentication support through URL loading system, you create a
`Authentication` subclass object such as `BasicAuthentication`, add the object to an array and then pass the array to the convenience method as the argument `authentications`. If the `HTTPCycle` is created by yourself, assign the array to the property `authentications`:
```
let auth = BasicAuthentication(username: "test", password: "12345")
try? HTTPCycle.get("http://jewzrux.in/core/playground/hello_with_basic_auth", authentications: [auth]) {
    (cycle, error) in
    if error != nil {
        print(error!)
        return
    }
    let text = cycle.response.text! // "Hello World"
}
```

A BasicAuthentication can handle three authentication methods: Basic,
Digest and NTLM.

### Prepare request manually for authentication
For the authentication mechanisms that the `Authentication` subclasses don't support, you can prepare the requests by yourself. Take GitHub API's Basic Authentication as an example, the GitHub API responds with `404 Not Found` for unauthenticated requests, instead of `401 Unauthorized`. In such case, URL loading system's authentication routes won't be triggered.

The solution is to manually craft the `Authorization` header. Creating and using a HTTPProcessor subclass would be a perfect choice here:
```
let processor = HTTPBasicAuthProcessor(username: "user", password: "pass")
try? HTTPCycle.get("https://api.github.com/user/", requestProcessors: [processor], responseProcessors: [JSONProcessor()]) {
    (cycle, error) in
    // cycle.response.statusCode == 200
}
```
In this code snippet, a HTTPBasicAuthProcessor is created and passed to the convenience method as the argument `requestProcessors`. Before the request is being sent, the HTTPBasicAuthProcessor object will craft and set the `Authorization` header.

Resend
----
It's easy to resend (restart) a HTTPCycle because the object holds enough information to send a HTTP request. "Restart" means Jewzruxin will first cancel the current request if necessary and then resend. The ability of resending a request can be very helpful in certain situations. For example, if a request fails with an authentication problem like incorrect token, you can retain the HTTPCycle somewhere in your code. Once the issue is solved, the HTTPCycle can be picked up and restarted to continue the previous action.

```
cycle.restart()
```

HTTPService
----
Interacting with API endpoints is a common task. By subclassing `HTTPService` and constructing a configure file, the job can be dramatically simplified. The resulting code is straightforward and easy to maintain, plus all the HTTP features Jewzruxin provides.

We will use GitHub's ["repositories searching" endpoint](https://developer.github.com/v3/search/#search-repositories) to demonstrate how you can take advantage the routes. The demo can also be found in the playground page "HTTP Advanced".

```
let github = GitHubService()!
let URIValues = ["q": "jewzruxin", "sort": "updated", "order":"desc"]
try? github.requestResource("search", URIValues:URIValues) {
    cycle, error in
    if error != nil {
        print(error!)
        return
    }
    let text = cycle.response.text!
    let object = cycle.response.object!
}
```

The GitHub API endpoints share the same base URL, URI templates, request processors and response processors. By subclassing HTTPService (GitHubService) and constructing a configure file (github.plist), we can put things together and make requests in a unified way.

![](https://github.com/weipin/jewzruxin/blob/master/Docs/images/github.plist.png)

Subclass HTTPService
----
The type method `serviceName` is the method you MUST override. The method `defaultSession` can be overridden to provide a custom `HTTPSession`. 

```
class GitHubService: HTTPService {
    override class func serviceName() -> String {
        return "github"
    }

    override class func defaultSession() -> HTTPSession {
        let session = HTTPSession()
        session.requestProcessors = [HTTPJSONProcessor()]
        session.responseProcessors = [HTTPJSONProcessor()]
        return session
    }
}
```

The return value of `serviceName` will be used to locate the default profile. For example, the default profile filename of `GitHubService` is github.plist.

The other method you may want to override is `cycleDidCreateWithResourceName`. Override this method to customize the specific HTTPCycle objects created by the HTTPService. `cycleDidCreateWithResourceName` will be called immediately after a HTTPCycle is created by the HTTPService, giving you a chance to customize the HTTPCycle which doesn't share the same behavior as the rest ones. For example, if there would be an GitHub endpoint doesn't use JSON for both request and response, you can make an exception as below:
```
override func cycleDidCreateWithResourceName(cycle: HTTPCycle, name: String) {
    if name == "upload" {
        cycle.requestProcessors = [HTTPDataProcessor()]
        cycle.responseProcessors = []
    }
}
```

HTTPService profile
----
A HTTPService profile is a dictionary which describes a "service" with base  URL, endpoints, etc. Here is a [profile example](https://github.com/weipin/jewzruxin/blob/master/Playground/Files/Playground.playground/Pages/HTTP%20Advanced.xcplaygroundpage/Resources/github.plist) of the GitHub service.

### Define profile with Property Lists
You construct a profile with [Property Lists](https://developer.apple.com/library/mac/documentation/Cocoa/Conceptual/PropertyLists/Introduction/Introduction.html) and bundle the file into the app. The Property Lists file should be named after the return value of the method `serviceName`. 

### Assign a profile
Besides the implicit convention discussed above, you can assign the profile (a dictionary) explicitly, as long as the profile is valid. The dictionary can be passed to the initializer of a HTTPSession subclass, or be assigned to the property `profile`.

In such situation, the way to create the profile dictionary is completely under your control. You can create it from code, from another local file or even a remote file fetched from web.

Pass a profile through initializer:
```
// `dict` is a dictionary with valid profile data
let session = GitHubService(profile: dict)
```

Replace the existing profile:
```
session.profile = dict
```

### Profile specification
The specification is simple enough, see [github.plist](https://github.com/weipin/jewzruxin/blob/master/Playground/Files/Playground.playground/Pages/HTTP%20Advanced.xcplaygroundpage/Resources/github.plist) for an example.

Key           | Type   |  Required  | Default
--------------|--------|------------|-----------
BaseURL       | String |  no        | ""
Resources     | Array  |  yes       | n/a

And for the items of the `Resources` array:

Key           | Type   |  Required  |  Default
--------------|--------|------------|-----------
Name          | String |  yes       | n/a
URITemplate   | String |  yes       | n/a
Method        | String |  no        | "GET"

### Verifying
Use the method `verifyProfile` of HTTPService to verify a specified profile. If the profile isn't valid, the method will return `false` and print error messages in the console. Profiles are supposed to be verified in the "debug mode" of your applications. But if the data is from web or other unsafe sources, verifying and rejecting the invalid ones in the "production mode" is necessary.

Base URL
----
With the ability of switching base URL, Jewzruxin makes HTTP testing in 
different environments easy. For example, if you want to run your app against 
a local development environment, the base URL can be changed easily:

```
service.baseURL = "http://127.0.0.1:8000"
```

Hint: Consider using the host part of the URLs as base URL. "http://MYDOMAIN" could be a better choice than "http://MYDOMAIN/api/v1/" as a base URL.

Creating/starting HTTPCycle
---
- To create a HTTPCycle without starting, use `cycleForResourceWithIdentifer` or `cycleForResource`.
- To create and start a HTTPCycle, use `requestResourceWithIdentifer` or `requestResource`.

HTTPService creates a new HTTPCycle for each request. To change the default behavior, pass `CycleForResourceOption.Reuse` or `CycleForResourceOption.Replace` as the argument `option`. The argument `identifier` is also required to locate an existing HTTPCycle in the service scope. If found, the existing one will be reused or replaced.

The "reusing" and "replacing" behaviors are handy if your app only requires one "connection" for a specific HTTP task. A good example is "timeline refreshing in a social app": if your app allows user keep tapping the refresh button, passing an unique identifier and specify the option `CycleForResourceOption.Reuse` can prevent the app from creating unnecessary connections.

Display network activity
----
To show network activity on iOS, your app can ask the system display a spinning indicator in the status bar. The indicator helps your users learn that your app is making network connections. Jewzruxin can show/hide the indicator for you automatically.

Jewzruxin achieves the task by sharing a singleton of the class `NetworkActivityIndicator` among all the HTTPSession objects. The NetworkActivityIndicator has an internal count starts from 0. Each time a request is sent, the NetworkActivityIndicator increases the count by 1. Each time a response is received or ended with an error, the NetworkActivityIndicator decreases the count by 1. The network activity will be displayed if the count is larger than 0, and hidden if the count reaches 0 again.

To disable this automatic behavior, set the property `networkActivityIndicator`
of the HTTPSession objects to nil:

```
HTTPSession.defaultSession().networkActivityIndicator = nil
```

Note: If your app only uses the default HTTPSession, the code snippet above is
sufficient. But if there are HTTPSession objects created explicitly, don't forget to nil the `networkActivityIndicator` of these objects as well.

Customize retry policy
----
Jewzruxin will resend requests in certain conditions. If your needs
beyond the default behavior, you can customize the retry policy through
the delegate of the HTTPSession. Here are the steps:

1. Create a class conforms to HTTPSessionDelegate.
1. Implement the optional method `sessionShouldRetryCycle`.
1. Create an object of the new class and assign it to the property `delegate`
   of the HTTPSession.

```
class SessionDelegateNoneRetry: HTTPSessionDelegate {
    @objc func sessionShouldRetryCycle(session: HTTPSession, cycle: HTTPCycle, error: NSError?) -> Bool {
        return false
    }
}

let TheDelegate = SessionDelegateNoneRetry()

func foo() {
    let URL = NSURL(string: "http://jewzrux.in/core/playground/echo/?code=500")!
    let cycle = HTTPCycle(requestURL: URL)
    cycle.solicited = true
    // Make sure the SessionDelegateNoneRetry exists until the response is received
    cycle.session.delegate = TheDelegate

    cycle.start { (cycle, error) in
        let code = cycle.response.statusCode // 500
    }
}

foo()
```

In the code snippet above, the method `sessionShouldRetryCycle` of SessionDelegateNoneRetry always returns false, meaning that no retry will be attempted in any situation.

Note: The property `delegate` is a weak reference. Make sure the object it references to exists until the response is received.

Error originates from HTTP status
----
Jewzruxin treats a response with HTTP status above 400 (including 400) as a failure by default -- an ErrorType will be created and passed as the argument `error` to `completionHandler`:

```
try? HTTPCycle.get("http://jewzrux.in/core/playground/echo/?code=404") {
    cycle, error in
    print(error) // Error.StatusCodeSeemsToHaveErred
    print(cycle.response.statusCode) // 404
}
```

This behavior helps you write less code because you don't have to examine status code for "logic errors".

To handle the status code all by yourself (no longer treats status above 400 as error), you can change the behavior through the delegate of HTTPSession. Here are the steps:

1. Create a class conforms to HTTPSessionDelegate.
1. Implement the optional method `sessionShouldTreatStatusCodeAsFailure`.
1. Create an object of the new class and assign it to the property `delegate`
   of the HTTPSession.

```  
class SessionDelegateNoneStatusFailure: HTTPSessionDelegate {
    @objc func sessionShouldTreatStatusCodeAsFailure(session: HTTPSession, status: Int) -> Bool {
        return false
    }
}

let TheDelegate = SessionDelegateNoneStatusFailure()

func foo() {
    let URL = NSURL(string: "http://jewzrux.in/core/playground/echo/?code=404")!
    let cycle = HTTPCycle(requestURL: URL)
    // Make sure the SessionDelegateNoneStatusFailure exists until the response is received
    cycle.session.delegate = TheDelegate

    cycle.start { (cycle, error) in
        print(error) // nil
        print(cycle.response.statusCode) // 404
    }
}

foo()
```

In the code snippet above, the method `sessionShouldTreatStatusCodeAsFailure` of
SessionDelegateNoneStatusFailure always returns false, meaning that no status
code will be treated as error.

