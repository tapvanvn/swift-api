//
//  ApiEndPoint.swift
//  
//
//  Created by Duy Nguyen on 05/01/2021.
//

import Foundation

public class ApiEndpoint : Hashable {
    
    public var Path : String = "/"

    public var Indexes: [String] = []

    var pragments : [String] = []
    var pragment_indices : Dictionary<String, Int> = Dictionary<String, Int>()
    var pragment_flag : Dictionary<Int,  String> = Dictionary<Int, String>()
    var pragment_sign_flag : [Int] = []

    
    init(path:String) {
        
        self.Path = path
        
        let pragments = path.split(separator: "/")
        var i = 0
        
        for pragment in pragments {
            
            let string = String(pragment)
            
            self.pragments.append(string)
            
            if string.hasPrefix(":")  {
                
                let index = String( string.dropFirst(1) )
                var index_name = index
                
                if let attrBeginIndex = index.firstIndex(of: "<"), let attrEndIndex = index.firstIndex(of: ">") {
                    
                    index_name = String( index[..<attrBeginIndex] )
                    let attributes = String( index[ attrBeginIndex..<attrEndIndex ] ).dropFirst()
                    
                    debugPrint(attributes)
                    if attributes == "sign" {
                        pragment_sign_flag.append(i)
                    }
                }
                debugPrint(index_name)
                
                pragment_indices[index_name] = i
                pragment_flag[i] =  index_name
            }
            i+=1
        }
    }
    
    public func hash(into hasher: inout Hasher) {
        
        hasher.combine(Path)
    }
    
    public static func == (lhs: ApiEndpoint, rhs: ApiEndpoint) -> Bool {
        
        return lhs.Path == rhs.Path
    }

    func getPath(indexes: Dictionary<String, String>) -> (path: String, signContent: String) {

        if self.pragment_indices.count == 0 {
            
            return (self.Path, "")
        }
        
        var path = URL.init(string: "/")!
        var signContent = ""
   
        for i in 0..<self.pragments.count {
            
            if !pragment_flag.keys.contains(i) {
                
                path.appendPathComponent( pragments[i] )
                
            } else if let name = pragment_flag[i], indexes.keys.contains(name)  {
                
                path.appendPathComponent( indexes[name]! )
                
                if pragment_sign_flag.contains(i) {
                    
                    signContent += indexes[name]!
                }
            }
        }
        
        return (path.path, signContent)
    }
}

