//
//  File.swift
//  
//
//  Created by Duy Nguyen on 05/01/2021.
//

import Foundation

@objc
public protocol Form {
    
    func Validate()->Bool
    func SignatureContent()->String
    @objc optional func Header()->[String]
    @objc optional func Param()->[String]
}

open class EmptyForm : Form, Encodable {

    public init(){}
    
    public func encode(to encoder: Encoder) throws
    {

    }
    
    public func Validate()->Bool {
        return true
        
    }
    public func SignatureContent()->String {
        return ""
    }
    public func Header() -> [String] {
        
        return []
    }
    public func Param()->[String] {
        return []
    }
}


public var emptyForm: EmptyForm = EmptyForm.init()

