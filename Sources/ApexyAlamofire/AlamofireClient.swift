//
//  AlamofireClient.swift
//
//  Created by Alexander Ignatev on 12/02/2019.
//  Copyright © 2019 RedMadRobot. All rights reserved.
//

import Apexy
import Foundation
import Alamofire

/// API Client.
open class AlamofireClient: Client {

    /// A closure used to observe result of every response from the server.
    public typealias ResponseObserver = (URLRequest?, HTTPURLResponse?, Data?, Error?) -> Void

    /// Session network manager.
    private let sessionManager: Alamofire.Session

    /// The queue on which the network response handler is dispatched.
    private let responseQueue = DispatchQueue(
        label: "Apexy.responseQueue",
        qos: .utility)

    /// The queue on which the completion handler is dispatched.
    private let completionQueue: DispatchQueue

    /// This closure to be called after each response from the server for the request.
    private let responseObserver: ResponseObserver?

    /// Look more at Alamofire.RequestInterceptor.
    public let requestInterceptor: RequestInterceptor

    /// Creates new 'AlamofireClient' instance.
    ///
    /// - Parameters:
    ///   - requestInterceptor: Alamofire Request Interceptor.
    ///   - configuration: The configuration used to construct the managed session.
    ///   - completionQueue: The serial operation queue used to dispatch all completion handlers. `.main` by default.
    ///   - publicKeys:  Dictionary with 1..n public keys used for SSL-pinning: ["example1.com": [PK1], "example2": [PK2, PK3]].
    ///   - responseObserver: The closure to be called after each response.
    public init(
        requestInterceptor: RequestInterceptor,
        configuration: URLSessionConfiguration,
        completionQueue: DispatchQueue = .main,
        publicKeys: [String: [SecKey]] = [:],
        responseObserver: ResponseObserver? = nil) {

        var securityManager: ServerTrustManager?
        /// All requests will cancelled if `ServerTrustManager` will initialized with empty evaluators
        if !publicKeys.isEmpty {
            let evaluators = publicKeys.mapValues { keys in
                return PublicKeysTrustEvaluator(keys: keys, performDefaultValidation: true, validateHost: true)
            }
            securityManager = ServerTrustManager(evaluators: evaluators)
        }

        self.completionQueue = completionQueue
        self.requestInterceptor = requestInterceptor
        self.sessionManager = Session(
            configuration: configuration,
            interceptor: requestInterceptor,
            serverTrustManager: securityManager)
        self.responseObserver = responseObserver
    }
    
    /// Creates new 'AlamofireClient' instance.
    ///
    /// - Parameters:
    ///   - baseURL: Base `URL`.
    ///   - configuration: The configuration used to construct the managed session.
    ///   - completionQueue: The serial operation queue used to dispatch all completion handlers. `.main` by default.
    ///   - publicKeys: Dictionary with 1..n public keys used for SSL-pinning: ["example1.com": [PK1], "example2": [PK2, PK3]].
    ///   - responseObserver: The closure to be called after each response.
    public convenience init(
        baseURL: URL,
        configuration: URLSessionConfiguration,
        completionQueue: DispatchQueue = .main,
        publicKeys: [String: [SecKey]] = [:],
        responseObserver: ResponseObserver? = nil) {
        self.init(
            requestInterceptor: BaseRequestInterceptor(baseURL: baseURL),
            configuration: configuration,
            completionQueue: completionQueue,
            publicKeys: publicKeys,
            responseObserver: responseObserver)
    }

    /// Send request to specified endpoint.
    ///
    /// - Parameters:
    ///   - endpoint: endpoint of remote content.
    ///   - completionHandler: The completion closure to be executed when request is completed.
    /// - Returns: The progress of fetching the response data from the server for the request.
    open func request<T>(
        _ endpoint: T,
        completionHandler: @escaping (Result<T.Content, T.Failure>) -> Void
    ) -> Progress where T: Endpoint {

        let urlRequestResult = endpoint.makeRequest()
        guard case let .success(urlRequest) = urlRequestResult else {
            if case let .failure(error) = urlRequestResult {
                completionHandler(.failure(error))
            }
            return Progress()
        }
        let request = sessionManager.request(urlRequest)
            .responseData(
                queue: responseQueue,
                completionHandler: { (response: DataResponse<Data, AFError>) in

                    let result = endpoint.decode(
                        fromResponse: response.response,
                        withResult: response.result.mapError({ $0 }))

                    self.completionQueue.async {
                        self.responseObserver?(response.request, response.response, response.data, result.error)
                        completionHandler(result)
                    }
            })

        return progress(for: request)
    }
    
    /// Upload data to specified endpoint.
    ///
    /// - Parameters:
    ///   - endpoint: The remote endpoint and data to upload.
    ///   - completionHandler: The completion closure to be executed when request is completed.
    /// - Returns: The progress of uploading data to the server.
    open func upload<T>(
        _ endpoint: T,
        completionHandler: @escaping (Result<T.Content, T.Failure>) -> Void
    ) -> Progress where T: UploadEndpoint {
        
        let urlRequestResult = endpoint.makeRequest()
        guard case let .success(urlRequestTuple) = urlRequestResult else {
            if case let .failure(error) = urlRequestResult {
                completionHandler(.failure(error))
            }
            return Progress()
        }
        let (urlRequest, body) = urlRequestTuple
        
        let request: UploadRequest
        switch body {
        case .data(let data):
            request = sessionManager.upload(data, with: urlRequest)
        case .file(let url):
            request = sessionManager.upload(url, with: urlRequest)
        case .stream(let stream):
            request = sessionManager.upload(stream, with: urlRequest)
        }
        
        request.responseData(
            queue: responseQueue,
            completionHandler: { (response: DataResponse<Data, AFError>) in

                let result = endpoint.decode(
                    fromResponse: response.response,
                    withResult: response.result.mapError({ $0 }))

                self.completionQueue.async {
                    self.responseObserver?(response.request, response.response, response.data, result.error)
                    completionHandler(result)
                }
            })

        let progress = request.uploadProgress
        progress.cancellationHandler = { [weak request] in request?.cancel() }
        return progress
    }

    // MARK: - Private

    private func progress(for request: Alamofire.Request) -> Progress {
        let progress = Progress()
        progress.cancellationHandler = { request.cancel() }
        return progress
    }
}

// MARK: - Helper

/// Wrapper for `URLRequestConvertible` from `Alamofire`.
private struct AnyRequest: Alamofire.URLRequestConvertible {
    let create: () throws -> URLRequest

    func asURLRequest() throws -> URLRequest {
        return try create()
    }
}

private extension Result {
    var error: Error? {
        switch self {
        case .failure(let error):
            return error
        default:
            return nil
        }
    }
}
