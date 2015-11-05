//
//  Authentication.swift
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
This class is an abstract class you use to encapsulate the code and data associated with HTTP authentication. Because it's abstract, you do not use this class directly but instead subclass or use one of the existing subclasses (like BasicAuthentication) to perform the actual handling.
*/
public class HTTPAuthentication {
    /**
    Types of authentication action.

    - ProvidingCredentials: Use the specified credential.
    - ProvidingCredentialsWithInteraction: Display an interface for user to input the credential.
    - PerformDefaultHandling: Default handling for the challenge - as if this handler were not implemented; the credential parameter is ignored.
    - RejectProtectionSpace: This challenge is rejected and the next authentication protection space should be tried;the credential parameter is ignored.
    - CancelingConnection: The entire request will be canceled; the credential parameter is ignored.
    */

    public enum Action {
        case ProvidingCredentials
        case ProvidingCredentialsWithInteraction
        case PerformDefaultHandling
        case RejectProtectionSpace
        case CancelingConnection
    }

    public typealias CompletionHandler = (disposition: NSURLSessionAuthChallengeDisposition, credential: NSURLCredential!) -> Void
    public typealias InteractionCompletionHandler = (action: Action) -> Void


    var challenge: NSURLAuthenticationChallenge!
    var completionHandler: CompletionHandler!
    weak var cycle: HTTPCycle!
    var interacting = false

    func perform(action: Action) {
        switch (action) {
        case .ProvidingCredentials:
            self.createAndUseCredential()

        case .ProvidingCredentialsWithInteraction:
            if self.interacting {
                // interacting with another task, cancel this one
                self.completionHandler(disposition: .CancelAuthenticationChallenge,
                                       credential: nil)
                return
            }
            self.interacting = true
            self.startInteraction {(action: Action) -> Void in
                self.interacting = false
                self.perform(action)
            }
        case .PerformDefaultHandling:
            self.completionHandler(disposition: .PerformDefaultHandling, credential: nil)
        case .RejectProtectionSpace:
            self.completionHandler(disposition: .RejectProtectionSpace, credential: nil)
        case .CancelingConnection:
            self.completionHandler(disposition: .CancelAuthenticationChallenge, credential: nil)
        }
    }

    /**
    Perform an action for the specified authentication.

    - Parameter action: The type of action to perform.
    - Parameter challenge: The `NSURLAuthenticationChallenge` to use.
    - Parameter completionHandler: The closure to execute when the action is complete.
    - Parameter cycle: The `HTTPCycle` requires the authentication.
    */
    public func performAction(action: Action, challenge: NSURLAuthenticationChallenge, completionHandler: CompletionHandler, cycle: HTTPCycle) {
        self.challenge = challenge
        self.completionHandler = completionHandler
        self.cycle = cycle

        self.perform(action)
    }

    /**
    Determine the action to take for the specified authentication. The result will be passed to the method `performAction` as the parameter `action`.

    - Parameter challenge: The `NSURLAuthenticationChallenge` to use.
    - Parameter cycle: The `HTTPCycle` requires the authentication.

    - Returns: An `Action` value.
    */
    public func actionForAuthenticationChallenge(challenge: NSURLAuthenticationChallenge, cycle: HTTPCycle) -> Action {
        if challenge.previousFailureCount == 0 {
            return .ProvidingCredentials
        }

        return .ProvidingCredentialsWithInteraction;
    }

    /**
    Determine if the specified authentication can be handled.

    - Parameter challenge: The `NSURLAuthenticationChallenge` to use.
    - Parameter cycle: The `HTTPCycle` requires the authentication handling.

    - Returns: true or false. The determination result.
    */
    public func canHandleAuthenticationChallenge(challenge: NSURLAuthenticationChallenge, cycle: HTTPCycle) -> Bool {
        assert(false)
        return false
    }

    func createAndUseCredential() {
        assert(false)
    }

    func startInteraction(completionHandler: InteractionCompletionHandler) {
        assert(false);
    }
}

/**
A `HTTPAuthentication` subclass handles the basic HTTP authentication challenges, supported types listed as below:

- NSURLAuthenticationMethodHTTPBasic
- NSURLAuthenticationMethodHTTPDigest
- NSURLAuthenticationMethodNTLM
*/
public class BasicAuthentication: HTTPAuthentication {
    var username: String
    var password: String
    var interactionCompletionHandler: InteractionCompletionHandler!
    static let SupportedMethods: Set<String> = [NSURLAuthenticationMethodHTTPBasic, NSURLAuthenticationMethodHTTPDigest, NSURLAuthenticationMethodNTLM]

    public init(username: String, password: String) {
        self.username = username
        self.password = password
        super.init()
    }

    public convenience override init() {
        self.init(username: "", password: "")
    }

    override public func canHandleAuthenticationChallenge(challenge: NSURLAuthenticationChallenge, cycle: HTTPCycle) -> Bool {
        if BasicAuthentication.SupportedMethods.contains(challenge.protectionSpace.authenticationMethod) {
            return true
        }

        return false
    }

    override public func createAndUseCredential() {
        let credential = NSURLCredential(user: self.username, password: self.password, persistence: .None)
        self.completionHandler(disposition: .UseCredential, credential: credential)
    }

    override public func startInteraction(completionHandler: InteractionCompletionHandler) {
        self.interactionCompletionHandler = completionHandler
        dispatch_async(dispatch_get_main_queue()) {
            // TODO:
        }
    }
}
