//: [Previous](@previous)

import Foundation
import XCPlayground

import JewzruxinMac

XCPlaygroundPage.currentPage.needsIndefiniteExecution = true

/*:
### Sandbox endpoints
Before jumping into the playground, it's necessary to introduce the sandbox endpoints. We will use these endpoints throughout the pages.

    URL          |   Method   |  Parameters  |  Response
    -------------|------------|--------------|-------------
    /hello/      |   GET      |     n/a      | Return string "Hello World"
    /dumpupload/ |   POST     |     n/a      | Return request body
    /echo/       |   GET      |     n/a      | See the explain below

The endpoint "/echo/" has few query parameters, each affects a particular part of the response:
1. "code": The status code to return, 200 by default.
1. "content": The response body to return.
1. "encoding": If presents, the content will be converted to binary data with the specified encoding.
1. "header": The headers to be added to the response.
*/


/*:
### Convenience methods
HTTPCycle provides few convenience methods for the common HTTP tasks.
*/

/*:
1. GET content from the specified the URL.
*/
try? HTTPCycle.get(BaseURL + "/core/playground/hello/") {
    cycle, error in
    if error != nil {
        print(error)
        return
    }
    let text = cycle.response.text!
}

/*:
2. The convenience methods will throw an error immediately if the specified URL is invalid.
*/
do {
    try HTTPCycle.get("") {
        cycle, error in
        // Will never reach here
    }
} catch {
    print("2. The convenience methods return nil immediately for an invalid URL." )
}

/*:
3. POST data as "form submission".
   The HTTPFormProcessor specified in the argument `requestProcessors` converts the `requestObject` into urlencoded string and sets Content-Type as "application/x-www-form-urlencoded".
*/
try? HTTPCycle.post(BaseURL + "/core/playground/dumpupload/", requestObject: ["k1": "v1", "k2": 9, "k3": [17, "v3"]], requestProcessors: [HTTPFormProcessor()]) {
    cycle, error in
    if error != nil {
        print(error!)
        return
    }
    let text = cycle.response.text!
}

/*:
4. POST data in JSON format and parse the JSON response into a dictionary.
The HTTPJSONProcessor specified in the argument `requestProcessors` converts the `requestObject` into JSON string and sets Content-Type as "application/json". The other HTTPJSONProcessor specified in the argument `responseProcessors` converts the response data (in JSON format) back to a dictionary.
*/
try? HTTPCycle.post(BaseURL + "/core/playground/dumpupload/", requestObject: ["k1": "v1", "k2": 9, "k3": [17, "v3"]], requestProcessors: [HTTPJSONProcessor()], responseProcessors: [HTTPJSONProcessor()]) {
    cycle, error in
    if error != nil {
        print(error!)
        return
    }
    let text = cycle.response.text!
    let obj = cycle.response.object!
}

/*:
5. Upload data.
*/
let dataUploadSource = HTTPCycle.UploadSource.Data("Hello World".dataUsingEncoding(NSUTF8StringEncoding)!)
try? HTTPCycle.upload(BaseURL + "/core/playground/dumpupload/", source: dataUploadSource) {
    cycle, error in
    if error != nil {
        print(error!)
        return
    }
    let text = cycle.response.text!
}

/*:
6. Upload a local file.
*/
let fileURL = NSBundle.mainBundle().URLForResource("hello", withExtension: "txt")!
let fileUploadSource = HTTPCycle.UploadSource.File(fileURL)
try? HTTPCycle.upload(BaseURL + "/core/playground/dumpupload/", source: fileUploadSource) {
    cycle, error in
    if error != nil {
        print(error!)
        return
    }
    let text = cycle.response.text!
}

/*:
7. Download content
*/
let downloadFileHandler: HTTPCycle.DownloadFileHander = {
    (cycle: HTTPCycle, location: NSURL?) in
    let content = try! NSString(contentsOfURL: location!, encoding: NSUTF8StringEncoding)
}
try? HTTPCycle.download(BaseURL + "/core/playground/echo?content=helloworld", downloadFileHandler: downloadFileHandler) {
    cycle, error in
    if error != nil {
        print(error!)
        return
    }
}

/*:
8. GET content from the specified URL with "Basic Authentication".
*/
let basicAuth = BasicAuthentication(username: "test", password: "12345")
try? HTTPCycle.get(BaseURL + "/core/playground/hello/", authentications: [basicAuth]) {
    cycle, error in
    if error != nil {
        print(error)
        return
    }
    let text = cycle.response.text!
}

//: [Next](@next)
