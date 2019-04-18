//
// Element.swift
//
// Copyright (c) 2014-2016 Marko Tadić <tadija@me.com> http://tadija.net
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.
//

import Foundation

/**
    This is base class for holding XML structure.

    You can access its structure by using subscript like this: `element["foo"]["bar"]` which would
    return `<bar></bar>` element from `<element><foo><bar></bar></foo></element>` XML as an `AEXMLElement` object.
*/
@objc(AEXMLElement)
open class AEXMLElement : NSObject {
    
    // MARK: - Properties
    
    /// Every `AEXMLElement` should have its parent element instead of `AEXMLDocument` which parent is `nil`.
    open internal(set) weak var parent: AEXMLElement?
    
    /// Child XML elements.
    open internal(set) var children = [AEXMLElement]()
    
    /// XML Element name.
    open var name: String
    
    open var namespaceURI: String?
    open var qualifiedName: String?

    /// XML Element value.
    open var value: String?
    
    /// XML Element attributes.
    open var attributes: [String : String]
    
    /// Error value (`nil` if there is no error).
    open var error: AEXMLError?
    
    /// String representation of `value` property (if `value` is `nil` this is empty String).
    open var string: String { return value ?? "" }
        
    /// Boolean representation of `value` property (if `value` is "true" or 1 this is `True`, otherwise `False`).
    open var bool: Bool { return string.lowercased() == "true" || Int(string) == 1 ? true : false }
    
    /// Integer representation of `value` property (this is **0** if `value` can't be represented as Integer).
    open var int: Int { return Int(string) ?? 0 }
    open var int8: Int8 { return Int8(self.int) }
    open var uint8: UInt8 { return UInt8(self.int) }
    open var int16: Int16 { return Int16(self.int) }
    open var uint16: UInt16 { return UInt16(self.int) }
    open var int32: Int32 { return Int32(self.int) }
    open var uint32: UInt32 { return UInt32(self.int) }
    open var int64: Int64 { return Int64(self.int) }
    open var uint64: UInt64 { return UInt64(self.int) }
    
    /// Double representation of `value` property (this is **0.00** if `value` can't be represented as Double).
    open var double: Double { return Double(string) ?? 0.00 }
    
    open var decimalNumber: NSDecimalNumber {
        let us = NSLocale(localeIdentifier: "en_US")
        if let value = self.value {
            return NSDecimalNumber(string: value, locale: us)
        } else {
            return NSDecimalNumber(value: 0)
        }
    }
    
    // MARK: - Lifecycle
    
    /**
        Designated initializer - all parameters are optional.
    
        - parameter name: XML element name.
        - parameter value: XML element value (defaults to `nil`).
        - parameter attributes: XML element attributes (defaults to empty dictionary).
    
        - returns: An initialized `AEXMLElement` object.
    */
    public init(name: String, value: String? = nil, namespaceURI: String? = nil, qualifiedName: String? = nil, attributes: [String : String] = [String : String]()) {
        self.name = name
        self.value = value
        self.namespaceURI = namespaceURI
        self.qualifiedName = qualifiedName
        self.attributes = attributes
    }
    
    // MARK: - XML Read
    
    /// The first element with given name **(Empty element with error if not exists)**.
    open subscript(key: String) -> AEXMLElement? {
        if let document = self.document, document.options.subscriptingShouldFollowKeyPathNotation {
            let path = key.components(separatedBy: ".")
            return path.reduce(self) { (node, key) -> AEXMLElement? in return node?.first(withName: key) }
        } else {
            return first(withName: key)
        }
    }
    
    @nonobjc open subscript(path keyPath: String) -> AEXMLElement? {
        let path = keyPath.components(separatedBy: ".")
        return path.reduce(self) { (node, key) -> AEXMLElement? in return node?.first(withName: key) }
    }
    
    open func first(withName: String) -> AEXMLElement? {
        return children.first(where: { $0.name == withName} )
//        if let f = children.first(where: { $0.name == withName} ) {
//            return f
//        } else {
//            let errorElement = AEXMLElement(name: withName)
//            errorElement.error = AEXMLError.elementNotFound
//            return errorElement
//        }
    }
    
    open var document : AEXMLDocument? {
        if self is AEXMLDocument {
            return self as? AEXMLDocument
        } else {
            return parent?.document
        }
    }
    
    /// Returns all of the elements with equal name as `self` **(nil if not exists)**.
    open var all: [AEXMLElement] { return parent == nil ? [self] : parent!.children.filter { $0.name == self.name } }
    
    /// Returns the first element with equal name as `self` **(nil if not exists)**.
    open var first: AEXMLElement { return parent == nil ? self : parent!.first(withName: self.name)! }
    
    /// Returns the last element with equal name as `self` **(nil if not exists)**.
    open var last: AEXMLElement { return all.last! }
    
    /// Returns number of all elements with equal name as `self`.
    open var count: Int { return all.count }

//    fileprivate func filter(withCondition condition: (AEXMLElement) -> Bool) -> [AEXMLElement]? {
//        guard let elements = all else { return nil }
//        
//        var found = [AEXMLElement]()
//        for element in elements {
//            if condition(element) {
//                found.append(element)
//            }
//        }
//        
//        return found.count > 0 ? found : nil
//    }
    
    /**
        Returns all elements with given value.
        
        - parameter value: XML element value.
        
        - returns: Optional Array of found XML elements.
    */
    open func all(withValue value: String) -> [AEXMLElement] {
        return all.filter{ $0.value == value }
    }
    
    /**
        Returns all elements with given attributes.
    
        - parameter attributes: Dictionary of Keys and Values of attributes.
    
        - returns: Optional Array of found XML elements.
    */
    open func all(withAttributes attributes: [String : String]) -> [AEXMLElement] {
        return all.filter { (element) -> Bool in
            var countAttributes = 0
            for (key, value) in attributes {
                if element.attributes[key] == value {
                    countAttributes += 1
                }
            }
            return countAttributes == attributes.count
        }
    }
    
    // MARK: - XML Write
    
    /**
        Adds child XML element to `self`.
    
        - parameter child: Child XML element to add.
    
        - returns: Child XML element with `self` as `parent`.
    */
    @discardableResult open func addChild(_ child: AEXMLElement) -> AEXMLElement {
        child.parent = self
        children.append(child)
        return child
    }
    
    /**
        Adds child XML element to `self`.
        
        - parameter name: Child XML element name.
        - parameter value: Child XML element value (defaults to `nil`).
        - parameter attributes: Child XML element attributes (defaults to empty dictionary).
        
        - returns: Child XML element with `self` as `parent`.
    */
    @discardableResult open func addChild(name: String,
                       value: String? = nil,
                       namespaceURI: String? = nil,
                       qualifiedName: String? = nil,
                       attributes: [String : String] = [String : String]()) -> AEXMLElement
    {
        let child = AEXMLElement(name: name, value: value, namespaceURI: namespaceURI, qualifiedName: qualifiedName, attributes: attributes)
        return addChild(child)
    }
    
    /// Removes `self` from `parent` XML element.
    open func removeFromParent() {
        parent?.removeChild(self)
    }
    
    fileprivate func removeChild(_ child: AEXMLElement) {
        if let childIndex = children.firstIndex(where: { $0 === child }) {
            children.remove(at: childIndex)
        }
    }
    
    fileprivate var parentsCount: Int {
        var count = 0
        var element = self
        
        while let parent = element.parent {
            count += 1
            element = parent
        }
        
        return count
    }
    
    fileprivate func indent(withDepth depth: Int) -> String {
        var count = depth
        var indent = String()
        
        while count > 0 {
            indent += "\t"
            count -= 1
        }
        
        return indent
    }
    
    /// Complete hierarchy of `self` and `children` in **XML** escaped and formatted String
    open var xml: String {
        var xml = String()
        
        // open element
        xml += indent(withDepth: parentsCount - 1)
        xml += "<\(name)"
        
        if attributes.count > 0 {
            // insert attributes
            for (key, value) in attributes {
                xml += " \(key)=\"\(value.xmlEscaped)\""
            }
        }
        
        if value == nil && children.count == 0 {
            // close element
            xml += " />"
        } else {
            if children.count > 0 {
                // add children
                xml += ">\n"
                for child in children {
                    xml += "\(child.xml)\n"
                }
                // add indentation
                xml += indent(withDepth: parentsCount - 1)
                xml += "</\(name)>"
            } else {
                // insert string value and close element
                xml += ">\(string.xmlEscaped)</\(name)>"
            }
        }
        
        return xml
    }
    
    /// Same as `xmlString` but without `\n` and `\t` characters
    open var xmlCompact: String {
        let chars = CharacterSet(charactersIn: "\n\t")
        return xml.components(separatedBy: chars).joined(separator: "")
    }
    
}

public extension String {
    
    /// String representation of self with XML special characters escaped.
    var xmlEscaped: String {
        // we need to make sure "&" is escaped first. Not doing this may break escaping the other characters
        var escaped = replacingOccurrences(of: "&", with: "&amp;", options: .literal)
        
        // replace the other four special characters
        let escapeChars = ["<" : "&lt;", ">" : "&gt;", "'" : "&apos;", "\"" : "&quot;"]
        for (char, echar) in escapeChars {
            escaped = escaped.replacingOccurrences(of: char, with: echar, options: .literal)
        }
        
        return escaped
    }
    
}
