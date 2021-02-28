//
//  NewBookListEndpoint.swift
//  ExampleAPI
//
//  Created by Aleksei Tiurnin on 21.01.2021.
//  Copyright © 2021 RedMadRobot. All rights reserved.
//

import Apexy
import Foundation

public enum BookError: Error {
    case makeRequestFail
    case forbidden
    case unknown
}

/// Example of GET request.
public struct NewBookListEndpoint: Endpoint, URLRequestBuildable {
    
    public typealias Content = [Book]
    public typealias Failure = APError<BookError>
    
    private let page: Int
    
    public init(page: Int) {
        self.page = page
    }
    
    public func makeRequest() -> Result<URLRequest, Failure> {
        guard page > 0 else {
            return .failure(.endpoint(.makeRequestFail))
        }
        return .success(get(URL(string: "books")!))
    }
    
    
    
    public func decode(
        fromResponse response: URLResponse?,
        withResult result: Result<Data, Error>) -> Result<[Book], Failure> {
        
        guard let response = response as? HTTPURLResponse else {
            return .failure(.connection(.unknown))
        }
        
        guard response.statusCode == 200 else {
            switch response.statusCode {
            case 503:
                return .failure(.endpoint(.forbidden))
            default:
                return .failure(.endpoint(.unknown))
            }
        }
        
        return result.mapError({ error -> Failure in
            return .connection(.unknown)
        }).flatMap { body -> Result<Content, Failure> in
            do {
                try ResponseValidator.validate(response, with: body)
                let resource = try JSONDecoder.default.decode(ResponseData<[Book]>.self, from: body)
                return .success(resource.data)
            } catch {
                return .failure(.decoding(error))
            }
        }
    }
    
    
}
