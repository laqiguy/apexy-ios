//
//  FileUploadEndpoint.swift
//  ExampleAPI
//
//  Created by Anton Glezman on 17.06.2020.
//  Copyright © 2020 RedMadRobot. All rights reserved.
//

import Apexy

/// Endpoint for uploading a file
public struct FileUploadEndpoint: UploadEndpoint {

    public typealias Content = Void
    
    private let fileURL: URL
    
    public init(fileURL: URL) {
        self.fileURL = fileURL
    }
    
    public func makeRequest() -> Result<(URLRequest, UploadEndpointBody), Failure> {
        var request = URLRequest(url: URL(string: "upload")!)
        request.httpMethod = "POST"
        request.setValue("application/octet-stream", forHTTPHeaderField: "Content-Type")
        return .success((request, .file(fileURL)))
    }
    
    public func decode(fromResponse response: URLResponse?, withResult result: Result<Data, Failure>) -> Result<Void, Error> {
        return result.flatMap { body -> Result<Void, Failure> in
            do {
                return .success(try ResponseValidator.validate(response, with: body))
            } catch {
                return .failure(error)
            }
        }
    }
}
