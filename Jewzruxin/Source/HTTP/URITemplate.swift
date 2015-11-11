//
//  URITemplate.swift
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
Expand a URITemplate. This is a convenient version of the method `process` for the class `URITemplate`

- Parameter template: The URITemplate to expand.
- Parameter values: The object to provide values when the function expands the URI Template. It can be a Swift Dictionary, a NSDictionary, a NSDictionary subclass, or any object has method `objectForKey`.

- Returns: The expanded URITemplate.
*/
public func ExpandURITemplate(template: String, values: [String: AnyObject] = [:]) -> String {
    let (URLString, errors) = URITemplate().process(template, values: values)
    if errors.count > 0 {
        NSLog("ExpandURITemplate error for template: \(template)")
        for (error, position) in errors {
            NSLog("ExpandURITemplate error: \(error), position: \(position).")
        }
    }

    return URLString
}

/**
This class is an implementation of URI Template (RFC6570). You probably wouldn't need to use this class directly but the convenient function `ExpandURITemplate`.
*/
public class URITemplate {
    public enum Error {
        case MalformedPctEncodedInLiteral
        case NonLiteralsCharacterFoundInLiteral
        case ExpressionEndedWithoutClosing
        case NonExpressionFound
        case InvalidOperator
        case MalformedVarSpec
    }

    enum State {
        case ScanningLiteral
        case ScanningExpression
    }

    enum ExpressionState {
        case ScanningVarName
        case ScanningModifier
    }

    enum BehaviorAllow {
        case U // any character not in the unreserved set will be encoded
        case UR // any character not in the union of (unreserved / reserved / pct-encoding) will be encoded
    }

    struct Behavior {
        var first: String
        var sep: String
        var named: Bool
        var ifemp: String
        var allow: BehaviorAllow
    }

    struct Constants {
        static let BehaviorTable = [
            "NUL": Behavior(first: "",  sep: ",", named: false, ifemp: "",  allow: .U),
            "+"  : Behavior(first: "",  sep: ",", named: false, ifemp: "",  allow: .UR),
            "."  : Behavior(first: ".", sep: ".", named: false, ifemp: "",  allow: .U),
            "/"  : Behavior(first: "/", sep: "/", named: false, ifemp: "",  allow: .U),
            ";"  : Behavior(first: ";", sep: ";", named: true,  ifemp: "",  allow: .U),
            "?"  : Behavior(first: "?", sep: "&", named: true,  ifemp: "=", allow: .U),
            "&"  : Behavior(first: "&", sep: "&", named: true,  ifemp: "=", allow: .U),
            "#"  : Behavior(first: "#", sep: ",", named: false, ifemp: "",  allow: .UR),
        ]

        static let LEGAL = "!*'();:@&=+$,/?%#[]" // Legal URL characters (based on RFC 3986)
        static let HEXDIG = "0123456789abcdefABCDEF"
        static let DIGIT = "0123456789"
        static let RESERVED = ":/?#[]@!$&'()*+,;="
        static let UNRESERVED = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-._~" // 66
        static let VARCHAR = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_" // exclude pct-encoded
    }

    // Pct-encoded ignored
    func encodeLiteralString(string: String) -> String {
        let charactersToLeaveUnescaped = Constants.RESERVED + Constants.UNRESERVED
        let set = NSCharacterSet(charactersInString: charactersToLeaveUnescaped)
        guard let s = string.stringByAddingPercentEncodingWithAllowedCharacters(set) else {
            NSLog("encodeLiteralString failed: \(string)")
            return ""
        }

        return s
    }

    func encodeLiteralCharacter(character: Character) -> String {
        return encodeLiteralString(String(character))
    }

    func encodeStringWithBehaviorAllowSet(string: String, allow: BehaviorAllow) -> String {
        var result = ""

        switch allow {
        case .U:
            let s = CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault, string, Constants.UNRESERVED as NSString, Constants.LEGAL as NSString, CFStringBuiltInEncodings.UTF8.rawValue)
            result = s as String
        case .UR:
            result = encodeLiteralString(string)
        }

        return result
    }

    func stringOfAnyObject(object: AnyObject?) -> String? {
        if object == nil {
            return nil
        }

        if let str = object as? String {
            return str
        }

        if let str = object?.stringValue {
            return str
        }

        return nil
    }

    func findOperatorInExpression(expression: String) -> (op: Character?, error: URITemplate.Error?) {
        if expression.isEmpty {
            return (nil, .InvalidOperator)
        }

        let c = expression.characters.count
        var op: Character? = nil
        let startCharacher = expression[expression.startIndex]
        if startCharacher == "%" {
            if c < 3 {
                return (nil, .InvalidOperator)
            }
            let c1 = expression[expression.startIndex.advancedBy(1)]
            let c2 = expression[expression.startIndex.advancedBy(2)]
            if Constants.HEXDIG.characters.indexOf(c1) == nil {
                return (nil, .InvalidOperator)
            }
            if Constants.HEXDIG.characters.indexOf(c2) == nil {
                return (nil, .InvalidOperator)
            }
            var str = "%" + String(c1) + String(c2)
            str = str.stringByRemovingPercentEncoding ?? ""
            op = str[str.startIndex]

        } else {
            op = startCharacher
        }

        if op != nil {
            if (Constants.BehaviorTable[String(op!)] == nil) {
                if Constants.VARCHAR.characters.indexOf(op!) == nil {
                    return (nil, .InvalidOperator)
                } else {
                    return (nil, nil)
                }
            }
        }

        return (op, nil)
    }

    func expandVarSpec(varName: String, modifier: Character?, prefixLength :Int, behavior: Behavior, values: AnyObject) -> String {
        var result = ""
        if varName == "" {
            return result
        }

        var value: AnyObject?
        if let d = values as? [String: AnyObject] {
            value = d[varName]
        } else {
            value = values.objectForKey?(varName)
        }

        if let str = stringOfAnyObject(value) {
            if behavior.named {
                result += encodeLiteralString(varName)
                if str == "" {
                    result += behavior.ifemp
                    return result
                } else {
                    result += "="
                }
            }
            if modifier == ":" && prefixLength < str.characters.count {
                let prefix = str[str.startIndex ..< str.startIndex.advancedBy(prefixLength)]
                result += encodeStringWithBehaviorAllowSet(prefix, allow: behavior.allow)
            } else {
                result += encodeStringWithBehaviorAllowSet(str, allow: behavior.allow)
            }

        } else {
            if modifier == "*" {
                if behavior.named {
                    if let ary = value as? [AnyObject] {
                        var c = 0
                        for v in ary {
                            let str = stringOfAnyObject(v)
                            if str == nil {
                                continue
                            }
                            if c > 0 {
                                result += behavior.sep
                            }
                            result += encodeLiteralString(varName)
                            if str! == "" {
                                result += behavior.ifemp
                            } else {
                                result += "="
                                result += encodeStringWithBehaviorAllowSet(str!, allow: behavior.allow)

                            }
                            ++c
                        }

                    } else if let dict = value as? Dictionary<String, AnyObject> {
                        var keys = Array(dict.keys)
                        keys = keys.sort {
                            $0.localizedCaseInsensitiveCompare($1) == NSComparisonResult.OrderedDescending
                        }

                        var c = 0
                        for k in keys {
                            var str: String? = nil
                            if let v: AnyObject = dict[k] {
                                str = stringOfAnyObject(v)
                            }
                            if str == nil {
                                continue
                            }
                            if c > 0 {
                                result += behavior.sep
                            }
                            result += encodeLiteralString(k)
                            if str == "" {
                                result += behavior.ifemp
                            } else {
                                result += "="
                                result += encodeStringWithBehaviorAllowSet(str!, allow: behavior.allow)
                            }
                            ++c
                        }

                    } else {
                        NSLog("Value for varName %@ is not a list or a pair", varName)
                    }

                } else {
                    if let ary = value as? [AnyObject] {
                        var c = 0
                        for v in ary {
                            let str = stringOfAnyObject(v)
                            if str == nil {
                                continue
                            }
                            if c > 0 {
                                result += behavior.sep
                            }
                            result += encodeStringWithBehaviorAllowSet(str!, allow: behavior.allow)
                            ++c
                        }

                    } else if let dict = value as? Dictionary<String, AnyObject> {
                        var keys = Array(dict.keys)
                        keys = keys.sort() {
                            $0.localizedCaseInsensitiveCompare($1) == NSComparisonResult.OrderedDescending
                        }

                        var c = 0
                        for k in keys {
                            var str: String? = nil
                            if let v: AnyObject = dict[k] {
                                str = stringOfAnyObject(v)
                            }
                            if str == nil {
                                continue
                            }
                            if c > 0 {
                                result += behavior.sep
                            }
                            result += encodeLiteralString(k)
                            result += "="
                            result += encodeStringWithBehaviorAllowSet(str!, allow: behavior.allow)
                            ++c
                        }

                    } else {
                        NSLog("Value for varName %@ is not a list or a pair", varName)
                    }
                } // if behavior.named

            } else {
                // no explode modifier is given
                var flag = true
                if behavior.named {
                    result += encodeLiteralString(varName)
                    if value == nil {
                        result += behavior.ifemp
                        flag = false
                    } else {
                        result += "="
                    }

                    if flag {

                    }
                } // if behavior.named

                if let ary = value as? [AnyObject] {
                    var c = 0
                    for v in ary {
                        guard let str = stringOfAnyObject(v) else {
                            continue
                        }
                        if c > 0 {
                            result += ","
                        }
                        result += encodeStringWithBehaviorAllowSet(str, allow: behavior.allow)
                        ++c
                    }

                } else if let dict = value as? Dictionary<String, AnyObject> {
                    var keys = Array(dict.keys)
                    keys = keys.sort() {
                        $0.localizedCaseInsensitiveCompare($1) == NSComparisonResult.OrderedDescending
                    }

                    var c = 0
                    for k in keys {
                        var str: String? = nil
                        if let v: AnyObject = dict[k] {
                            str = stringOfAnyObject(v)
                        }
                        if str == nil {
                            continue
                        }
                        if c > 0 {
                            result += ","
                        }
                        result += encodeStringWithBehaviorAllowSet(k, allow: behavior.allow)
                        result += ","
                        result += encodeStringWithBehaviorAllowSet(str!, allow: behavior.allow)
                        ++c
                    }
                    
                } else {
                    
                }
                
            } // if modifier == "*"
            
        }
        return result
    }

    /**
    Expand a URITemplate.

    - Parameter template: The URITemplate to expand
    - Parameter values: The object to provide values when the method expands the URITemplate. It can be a Swift Dictionary, a NSDictionary, a NSDictionary subclass, or any object has method `objectForKey`.

    - Returns: (result, errors)
      - result: The expanded URITemplate
      - errors: An array of tuple (URITemplateError, Int) which represents the errors this method recorded in expanding the URITemplate. The first element indicates the type of error, the second element indicates the position (index) of the error in the URITemplate.
    */
    public func process(template: String, values: AnyObject) -> (String, [(URITemplate.Error, Int)]) {
        var state: State = .ScanningLiteral
        var result = ""
        var pctEncoded = ""
        var expression = ""
        var expressionCount = 0
        var errors = [(Error, Int)]()

        for (index, c) in template.characters.enumerate() {
            switch state {
            case .ScanningLiteral:
                if c == "{" {
                    state = .ScanningExpression
                    ++expressionCount

                } else if (!pctEncoded.isEmpty) {
                    switch pctEncoded.characters.count {
                    case 1:
                        if Constants.HEXDIG.characters.indexOf(c) != nil {
                            pctEncoded += String(c)
                        } else {
                            errors.append((.MalformedPctEncodedInLiteral, index))
                            result += encodeLiteralString(pctEncoded)
                            result += encodeLiteralCharacter(c)
                            state = .ScanningLiteral
                            pctEncoded = ""
                        }

                    case 2:
                        if Constants.HEXDIG.characters.indexOf(c) != nil {
                            pctEncoded += String(c)
                            result += pctEncoded
                            state = .ScanningLiteral
                            pctEncoded = ""

                        } else {
                            errors.append((.MalformedPctEncodedInLiteral, index))
                            result += encodeLiteralString(pctEncoded)
                            result += encodeLiteralCharacter(c)
                            state = .ScanningLiteral
                            pctEncoded = ""
                        }

                    default:
                        assert(false)
                    }

                } else if c == "%" {
                    pctEncoded += String(c)
                    state = .ScanningLiteral

                } else if Constants.UNRESERVED.characters.indexOf(c) != nil || Constants.RESERVED.characters.indexOf(c) != nil {
                    result += String(c)

                } else {
                    errors.append((.NonLiteralsCharacterFoundInLiteral, index))
                    result += String(c)
                }

            case .ScanningExpression:
                if c == "}" {
                    state = .ScanningLiteral
                    // Process expression
                    let (op, error) = findOperatorInExpression(expression)
                    if error != nil {
                        errors.append((.MalformedPctEncodedInLiteral, index))
                        result = result + "{" + expression + "}"

                    } else {
                        let operatorString = (op != nil) ? String(op!) : "NUL"
                        let behavior = Constants.BehaviorTable[operatorString]!;
                        // Skip the operator
                        var skipCount = 0
                        if op != nil {
                            if expression.hasPrefix("%") {
                                skipCount = 3
                            } else {
                                skipCount = 1
                            }
                        }
                        // Process varspec-list
                        var varCount = 0
                        var eError: URITemplate.Error?
                        var estate = ExpressionState.ScanningVarName
                        var varName = ""
                        var modifier: Character?
                        var prefixLength :Int = 0
                        var str = expression[expression.startIndex.advancedBy(skipCount) ..< expression.endIndex]
                        str = str.stringByRemovingPercentEncoding ?? ""
                        var jIndex = 0
                        for (index, j) in str.characters.enumerate() {
                            jIndex = index
                            if j == "," {
                                // Process VarSpec
                                if varCount == 0 {
                                    result += behavior.first
                                } else {
                                    result += behavior.sep
                                }
                                let expanded = expandVarSpec(varName, modifier:modifier, prefixLength:prefixLength, behavior:behavior, values:values)
                                result += expanded
                                ++varCount

                                // Reset for next VarSpec
                                eError = nil
                                estate = .ScanningVarName
                                varName = ""
                                modifier = nil
                                prefixLength = 0
                                
                                continue
                            }

                            switch estate {
                            case .ScanningVarName:
                                if (j == "*" || j == ":") {
                                    if varName.isEmpty {
                                        eError = .MalformedVarSpec
                                        break;
                                    }
                                    modifier = j
                                    estate = .ScanningModifier
                                    continue
                                }
                                if Constants.VARCHAR.characters.indexOf(j) != nil || j == "." {
                                    varName += String(j)
                                } else {
                                    eError = .MalformedVarSpec
                                    break;
                                }
                            case .ScanningModifier:
                                if modifier == "*" {
                                    eError = .MalformedVarSpec
                                    break;
                                } else if modifier == ":" {
                                    if Constants.DIGIT.characters.indexOf(j) != nil {
                                        let intValue = Int(String(j))
                                        prefixLength = prefixLength * 10 + intValue!
                                        if prefixLength >= 1000 {
                                            eError = .MalformedVarSpec
                                            break;
                                        }

                                    } else {
                                        eError = .MalformedVarSpec
                                        break;
                                    }
                                } else {
                                    assert(false)
                                }
                            }
                        } // for expression

                        if (eError != nil) {
                            let e = eError!
                            let ti = index + jIndex
                            errors.append((e, ti))
                            let remainingExpression = str[str.startIndex.advancedBy(jIndex) ..< str.endIndex]
                            if op != nil {
                                result = result + "{" + String(op!) + remainingExpression + "}"
                            } else {
                                result = result + "{" + remainingExpression + "}"
                            }

                        } else {
                            // Process VarSpec
                            if varCount == 0 {
                                result += behavior.first
                            } else {
                                result += behavior.sep
                            }
                            let expanded = expandVarSpec(varName, modifier: modifier, prefixLength: prefixLength, behavior: behavior, values: values)
                            result += expanded
                        }
                    } // varspec-list

                } else {
                    expression += String(c)
                }
            } // switch
        } // for

        // Handle ending
        let endingIndex: Int = template.characters.count
        switch state {
        case .ScanningLiteral:
            if !pctEncoded.isEmpty {
                errors.append((.MalformedPctEncodedInLiteral, endingIndex))
                result += encodeLiteralString(pctEncoded)
            }
        case .ScanningExpression:
            errors.append((.ExpressionEndedWithoutClosing, endingIndex))
            result = result + "{" + expression
        }
        if expressionCount == 0 {
            errors.append((.NonExpressionFound, endingIndex))
        }

        return (result, errors)
    } // process

} // URITemplate

