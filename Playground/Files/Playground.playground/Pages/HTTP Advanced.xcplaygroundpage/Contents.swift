//: [Previous](@previous)

import Foundation

import Foundation
import XCPlayground

import JewzruxinMac

XCPlaygroundPage.currentPage.needsIndefiniteExecution = true

/*:
### Service
*/

/*:
1. A subclass of HTTPService to interact with the GitHub API endpoints.
   To examine the "profile", find the file "github.plist" in the Resource group of this Playground page. This sample "profile" only describes one endpoint "search".
*/
class GitHubService: HTTPService {
    override class func serviceName() -> String {
        return "github"
    }

    override class func defaultSession() -> HTTPSession {
        let session = HTTPSession(configuration: nil, delegateQueue: nil, workerQueue: nil)
        session.requestProcessors = [HTTPJSONProcessor()]
        session.responseProcessors = [HTTPJSONProcessor()]
        return session
    }
}

/*:
2. Search repositories
   * Step 1: create a dictionary for the query parameters (URIValues).
   * Step 2: send request through the method `requestResource` with "search" as the resource name.

   The response data in JSON will be parsed into a dictionary and can be accessed as the property `object` of HTTPResponse.
*/
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

//: [Next](@next)
