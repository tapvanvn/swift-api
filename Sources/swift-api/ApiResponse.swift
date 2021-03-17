//
//  ApiResponse.swift
//  
//
//  Created by Duy Nguyen on 05/01/2021.
//

import Foundation

public class ResponseVoid : Decodable {
    
    public required init(from decoder: Decoder) throws {}
}

public class BaseResponse {
    
    public var Data : Data? = nil
    public var Response: URLResponse? = nil
    public var Error: Error? = nil
    
    public init(data: Data?, response: URLResponse?, error: Error?) {
        self.Data = data
        self.Response = response
        self.Error = error
    }
}

public class ApiResponse<T: Decodable> : Decodable{
    
    public var HttpStatusCode : Int = 0
    public var Success: Bool = false
    public var ErrorCode: Int = 0
    public var Message: String = ""
    public var ResponseObject: T? = nil
    
    public var RequestResponse : BaseResponse
    
    //MARK: Implement Codable
    enum CodingKeys:CodingKey
    {
        case success    //must have
        case error_code //maybe empty
        case message    //maybe empty
        case response   //maybe empty
    }
    public init(){
        
        RequestResponse = BaseResponse.init(data: nil, response: nil, error: nil)
    }
    public func apply(data: Data?, response: URLResponse?, error: Error?){
        
        RequestResponse.Data = data
        RequestResponse.Response = response
        RequestResponse.Error = error

    }
    
    convenience init(data: Data?, response: URLResponse?, error: Error?) {
        
        self.init()
        apply(data: data, response: response, error: error)

    }
    
    convenience init(errorCode: Int, message: String, data: Data?, response: URLResponse?, error: Error?) {
        
        self.init()
        apply(data: data, response: response, error: error)
        ErrorCode = errorCode
        Message = message
        Success = false
    }
    
    required public convenience init(from decoder: Decoder) throws
    {
        self.init()
        do
        {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            
            self.Success = try container.decode(Bool.self, forKey: .success)
            
            if container.contains(.error_code) {
                
                self.ErrorCode = try container.decode(Int.self, forKey: .error_code)
            }
            if container.contains(.message) {
                
                self.Message = try container.decode(String.self, forKey: .message)
            }
            if container.contains(.response) {
                
                self.ResponseObject = try container.decode(T.self, forKey: .response)
            }
        }
        catch
        {
            print("decode response error \(error)")
        }
    }
    
    public func GetResponse<R: Decodable>(type: R.Type)->R? {
        
        if let data = self.RequestResponse.Data {
            
            do {
                
                let object = try JSONDecoder.init().decode(ApiResponse<R>.self, from: data)
                
                return object.ResponseObject
                    
            } catch {
                
                debugPrint("here2 \(error) ")
            }
        }
        return nil
    }

}
