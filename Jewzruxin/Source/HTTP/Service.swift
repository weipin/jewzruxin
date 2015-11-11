//
//  Service.swift
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
This class is an abstract class you use to represent a "service". Because it is abstract, you do not use this class directly but instead subclass.
*/
public class HTTPService {
    public enum Key: String {
        case BaseURL = "BaseURL"
        case Resources = "Resources"
        case Name = "Name"
        case URITemplate = "URITemplate"
        case Method = "Method"
    }

    /**
    - Create: Always create a new `HTTPCycle`.
    - Reuse: If there is a `HTTPCycle` with the specified identifier, the `HTTPCycle` will be reused.
    - Replace: If there is a `HTTPCycle` with the specified identifier, the `HTTPCycle` will cancelled. A new one will be created and replaces the old one.
    */
    public enum CycleForResourceOption {
        case Create
        case Reuse
        case Replace
    }

    /// The String represents the beginning common part of the endpoint URLs.
    private var _baseURLString: String!
    public var baseURLString: String {
        get {
            if (_baseURLString != nil) {
                return _baseURLString
            }
            if let str = self.profile![Key.BaseURL.rawValue] as? String {
                return str
            }
            return ""
        }
        set {
            self._baseURLString = newValue
        }
    }

    /// The dictionary describes the resources of a service.
    public var profile: [String: AnyObject]!
    public var session: HTTPSession!

    /// MUST be overridden
    public class func serviceName() -> String {
        // TODO: Find a way to obtain class name
        assert(false)
        return "Service"
    }

    public class func filenameOfDefaultProfile() -> String {
        let serviceName = self.serviceName()
        let filename = serviceName + ".plist"
        return filename
    }

    /// Override this method to return a custom `HTTPSession`
    public class func defaultSession() -> HTTPSession {
        return HTTPSession(configuration: nil, delegateQueue: nil, workerQueue: nil)
    }

    /// Override this method to customize the newly created `HTTPCycle`.
    public func cycleDidCreateWithResourceName(cycle: HTTPCycle, name: String) {

    }

    /// Find and read the service profile in the bundle with the specified filename.
    public class func profileForFilename(filename: String) throws -> [String: AnyObject] {
        let bundle = NSBundle(forClass: self)
        guard let URL = bundle.URLForResource(filename, withExtension: nil) else {
            throw Error.FileNotFound
        }

        let data = try NSData(contentsOfURL: URL, options: [])
        return try self.profileForData(data)
    }

    public class func profileForData(data: NSData) throws -> [String: AnyObject] {
        let d = try NSPropertyListSerialization.propertyListWithData(data, options: [], format: nil)
        guard let profile = d as? [String: AnyObject] else {
            throw Error.TypeNotMatch
        }
        return profile
    }

    public class func URLStringByJoiningComponents(part1: String, part2: String) -> String {
        if part1.isEmpty {
            return part2
        }

        if part2.isEmpty {
            return part1
        }

        var p1 = part1
        var p2 = part2
        if !part1.isEmpty && part1.hasSuffix("/") {

            p1 = part1[part1.startIndex ..< part1.endIndex.advancedBy(-1)]
        }
        if !part2.isEmpty && part2.hasPrefix("/") {
            p2 = part2[part2.startIndex.advancedBy(1) ..< part2.endIndex]
        }
        let result = p1 + "/" + p2
        return result
    }

    /**
    Initialize a `HTTPService` object.

    - Parameter profile: A dictionary for profile. If nil, the default bundled file will be used to create the dictionary.
    */
    public init?(profile: [String: AnyObject]? = nil) {
        self.session = self.dynamicType.defaultSession()
        if profile != nil {
            self.profile = profile!

        } else {
            do {
                try self.updateProfileFromLocalFile()
            } catch {
                NSLog("\(error)")
                return nil
            }
        }
    }

    public func updateProfileFromLocalFile(URL: NSURL? = nil) throws {
        if URL == nil {
            let filename = self.dynamicType.filenameOfDefaultProfile()
            self.profile = try self.dynamicType.profileForFilename(filename)
            return
        }

        let data = try NSData(contentsOfURL: URL!, options: [])
        self.profile = try self.dynamicType.profileForData(data)
    }

    /**
    Check if specified profile is valid.

    - Parameter profile: A dictionary as profile.

    - Returns: true if valid, or false if an error occurs.
    */
    public func verifyProfile(profile: [String: AnyObject]) -> Bool {
        var names: Set<String> = []
        guard let value: AnyObject = profile[HTTPService.Key.Resources.rawValue] else {
            NSLog("Warning: no resources found in Service profile!")
            return false
        }
        guard let resources = value as? [[String: String]] else {
            NSLog("Error: Malformed Resources in Service profile (type does not match)!")
            return false
        }

        for (index, resource) in resources.enumerate() {
            guard let name = resource[HTTPService.Key.Name.rawValue] else {
                NSLog("Error: Malformed Resources (name not found) in Service profile (resource index: \(index))!")
                return false
            }

            if names.contains(name) {
                NSLog("Error: Malformed Resources (duplicate name \(name)) in Service profile (resource index: \(index))!")
                return false
            }

            if resource[HTTPService.Key.URITemplate.rawValue] == nil {
                NSLog("Error: Malformed Resources (URL Template not found) in Service profile (resource index: \(index))!")
                return false
            }

            names.insert(name)
        }

        return true
    }

    public func resourceProfileForName(name: String) -> [String: String]? {
        guard let value: AnyObject = self.profile![HTTPService.Key.Resources.rawValue] else {
            return nil
        }
        guard let resources = value as? [[String: String]] else {
            return nil
        }

        for resource in resources {
            if let n = resource[HTTPService.Key.Name.rawValue] {
                if n == name {
                    return resource
                }
            }
        }

        return nil
    }

    public func cycleForIdentifer(identifier: String) -> HTTPCycle? {
        return self.session.cycleForIdentifer(identifier)
    }

    /**
    Create a `HTTPCycle` based on the specified resource profile and parameters.

    - Parameter name: The name of the resource, MUST presents in the profile. The name is case sensitive.
    - Parameter identifer: If presents, the identifer will be used to locate an existing `HTTPCycle`. REQUIRED if option is `Reuse` or `Replace`.
    - Parameter option: Determines the HTTPCycle creation logic.
    - Parameter URIValues: The object to provide values for the URI Template expanding.
    - Parameter requestObject: The property `object` of the `HTTPRequest` for the `HTTPCycle`.
    - Parameter solicited: The same property of `HTTPCycle`.

    - Returns: A new or existing `HTTPCycle`.
    */
    public func cycleForResourceWithIdentifer(name: String, identifier: String? = nil, option: CycleForResourceOption = .Create, URIValues: [String: AnyObject] = [:], requestObject: AnyObject? = nil, solicited: Bool = false) throws -> HTTPCycle {
        var cycle: HTTPCycle!

        switch option {
        case .Create:
            break
        case .Reuse:
            assert(identifier != nil)
            cycle = self.cycleForIdentifer(identifier!)
        case .Replace:
            assert(identifier != nil)
            cycle = self.cycleForIdentifer(identifier!)
            cycle.cancel(true)
            cycle = nil
        }

        if cycle != nil {
            return cycle
        }

        if let resourceProfile = self.resourceProfileForName(name) {
            let URITemplate = resourceProfile[HTTPService.Key.URITemplate.rawValue]
            let part2 = ExpandURITemplate(URITemplate!, values: URIValues)
            let URLString = HTTPService.URLStringByJoiningComponents(self.baseURLString, part2: part2)

            guard let URL = NSURL(string: URLString) else {
                throw Error.InvalidURL
            }

            var method = resourceProfile[HTTPService.Key.Method.rawValue]
            if method == nil {
                method = "GET"
            }

            cycle = HTTPCycle(requestURL: URL, taskType: .Data, session: self.session, requestMethod: method!, requestObject: requestObject)
            cycle.solicited = solicited
            if identifier != nil {
                cycle.identifier = identifier!
            }
            self.cycleDidCreateWithResourceName(cycle, name: name)

        } else {
            assert(false, "Endpoind \(name) not found in profile!")
        }

        return cycle
    }

    /**
    Create a new `HTTPCycle` object based on the specified resource profile and parameters.

    - Parameter name: The name of the resouce, MUST presents in the profile. The name is case sensitive.
    - Parameter URIValues: The object to provide values for the URI Template expanding.
    - Parameter requestObject: The property `object` of the `HTTPRequest` for the Cycle.
    - Parameter solicited: The same property of `HTTPCycle`.

    - Returns: A new Cycle.
    */
    public func cycleForResource(name: String, URIValues: [String: AnyObject] = [:], requestObject: AnyObject? = nil, solicited: Bool = false) throws -> HTTPCycle {
        let cycle = try self.cycleForResourceWithIdentifer(name, URIValues: URIValues, requestObject: requestObject, solicited: solicited)
        return cycle
    }

    /**
    Create a `HTTPCycle` object based on the specified resource profile and parameters, and start the `HTTPCycle`. See `cycleForResourceWithIdentifer` for details.
    */
    public func requestResourceWithIdentifer(name: String, identifier: String, URIValues: [String: AnyObject] = [:], requestObject: AnyObject? = nil, solicited: Bool = false, completionHandler: HTTPCycle.CompletionHandler) throws -> HTTPCycle {
        let cycle = try self.cycleForResourceWithIdentifer(name, identifier: identifier,
            URIValues: URIValues, requestObject: requestObject, solicited: solicited)
        cycle.start(completionHandler)
        return cycle
    }

    /**
    Create a `HTTPCycle` object based on the specified resource profile and parameters, and start the `HTTPCycle`. See `cycleForResource` for details.
    */
    public func requestResource(name: String, URIValues: [String: AnyObject] = [:],
        requestObject: AnyObject? = nil, solicited: Bool = false,
        completionHandler: HTTPCycle.CompletionHandler) throws -> HTTPCycle {
        let cycle = try self.cycleForResourceWithIdentifer(name, identifier: nil,
            URIValues: URIValues, requestObject: requestObject, solicited: solicited)
        cycle.start(completionHandler)
        return cycle
    }
}
