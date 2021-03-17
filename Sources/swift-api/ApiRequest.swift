//
//  ApiRequest.swift
//  
//
//  Created by Duy Nguyen on 05/01/2021.
//

import Foundation

public protocol ApiDelegate {

    var Host: String {get}
    var DefaultHeaders: Dictionary<String, String> {get}
    func sign(content: String) -> Dictionary<String,String>
}

public enum ApiRequestMethod : String {
    
    case post = "POST"
    case get = "GET"
    case put = "PUT"
    case patch = "PATCH"
    case del = "DELETE"
}

public typealias ApiCallback<R: Decodable> = (ApiResponse<R>)->Void

public class ApiRequest<T:Form & Encodable, R:  Decodable> {
    
    public var delegate: ApiDelegate!
    
    var endPoint : ApiEndpoint
    
    var needSignature : Bool = false
    var method : String = ApiRequestMethod.get.rawValue
    
    public init(delegate: ApiDelegate, endPoint: ApiEndpoint, method: String, needSignature: Bool){
        
        self.delegate = delegate
        self.endPoint = endPoint
        
        self.method = method.uppercased()
        self.needSignature = needSignature

    }
    
    public convenience init( delegate: ApiDelegate, endPoint: ApiEndpoint, method: String) {
        
        self.init(delegate: delegate, endPoint:endPoint, method:method, needSignature: false)
    }
    

    public convenience init( delegate: ApiDelegate, endPoint: ApiEndpoint) {
        
        self.init(delegate: delegate, endPoint:endPoint, method: ApiRequestMethod.post.rawValue, needSignature: false)
    }
    
    
    public func request(form: T?,  callback: @escaping ApiCallback<R>) {

        request(form: form, indexes: Dictionary<String, String>(), callback: callback)
    }

    public func request(form: T?, indexes:Dictionary<String, String>, callback: @escaping ApiCallback<R>) {
        
        var params : Dictionary<String, String> = Dictionary<String, String>.init()
        var headers : Dictionary<String, String> = Dictionary<String, String>.init()
        
        if let headerKeys = form?.Header?() {
            
            for key in headerKeys{
                
                guard let value = indexes[key] else {
                    
                    callback(ApiResponse<R>.init(errorCode: 5000, message: "header \(key) is missing", data: nil, response: nil, error: nil))
                    
                    return
                }
                headers[key] = value
            }
        }
        
        if let paramKeys = form?.Param?() {
            
            for key in paramKeys{
                
                guard let value = indexes[key] else {
                    
                    callback(ApiResponse<R>.init(errorCode: 5000, message: "param \(key) is missing", data: nil, response: nil, error: nil))
                    
                    return
                }
                params[key] = value
            }
        }
        
        let pathInfo = endPoint.getPath(indexes: indexes)
        
        if needSignature {
            
            let signContent = pathInfo.signContent + (form?.SignatureContent() ?? "")
            if let signatureHeader = delegate?.sign(content: signContent) {
                for pair in signatureHeader {
                    headers[pair.key] = pair.value
                }
            }
        }
        
        var scheme = "https"
        
        var host = delegate.Host
        
        var port = 80
        
        if host.starts(with: "http://") {
            
            scheme = "http"
            
            host = String(host.dropFirst(7))
            
        } else if host.starts(with: "https://") {
            
            port = 443
            host = String(host.dropFirst(8))
        }
        let hostPart = host.split(separator: ":")
        
        if hostPart.count > 1 {
            
            host = String(hostPart[0])
            
            let portString = String(hostPart[1])
            
            if let testPort = Int.init(portString) {
                
                port = testPort
            }
        }
        
        
        var components = URLComponents()
        components.scheme = scheme
        components.host = host
        components.path = pathInfo.path
        components.port = port
        
        components.queryItems = []

        for param in params {
            let queryParam = URLQueryItem.init(name: param.key, value: param.value)
            components.queryItems?.append(queryParam)
        }
        
        var request = URLRequest.init(url: components.url!)
        
        request.httpMethod = self.method
        
        request.cachePolicy = NSURLRequest.CachePolicy.reloadIgnoringCacheData
        
        for header in headers {
            
            request.addValue(header.value, forHTTPHeaderField: header.key)
        }
        
        do {
        
            if form == nil || self.method == "GET" {
                
                request.httpBody = nil
                
            } else {

                request.httpBody = try JSONEncoder.init().encode(form!)
            }

            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                
                if let err = error {
                    
                    let apiResponse = ApiResponse<R>.init(errorCode: 5001, message: "Request Fail: \(err.localizedDescription)", data: data, response: response, error:  error)
                    
                    callback(apiResponse)
                    return
                }
                
                do {
                    let apiResponse : ApiResponse<R>!
                    
                    if let http_response = response as? HTTPURLResponse {

                        
                        if http_response.statusCode == 200, let data = data {
                            
                            apiResponse = try JSONDecoder.init().decode(ApiResponse<R>.self, from: data)
                            

                        } else {
                            
                            apiResponse = ApiResponse<R>.init(data: data, response: response, error: error)
                        }
                        
                        apiResponse.HttpStatusCode = http_response.statusCode
                        
                    } else {
                        
                        apiResponse = ApiResponse<R>.init(data: data, response: response, error: error)
                    }
                    
                    callback(apiResponse)
                    
                } catch {
                    
                    let apiResponse = ApiResponse<R>.init(errorCode: 5003, message: "Request Fail: \(error.localizedDescription)", data: data, response: response, error: error)
                    callback(apiResponse)
                }
            }
            task.resume()
            
        } catch {
            
            let apiResponse = ApiResponse<R>.init(errorCode: 5002, message: "Request Fail: \(error.localizedDescription)", data: nil, response: nil, error: nil)
            
            callback(apiResponse)
        }

    }
}


