//
//  BaseRequestInterceptorTests.swift
//
//  Created by Daniil Subbotin on 07.09.2020.
//  Copyright © 2020 RedMadRobot. All rights reserved.
//

import Apexy
import ApexyAlamofire
import Alamofire
import XCTest

final class BaseRequestInterceptorTests: XCTestCase {
    
    private let url = URL(string: "https://booklibrary.com")!
    
    private var interceptor: RequestInterceptor {
        BaseRequestInterceptor(baseURL: url)
    }
    
    func testAdaptWhenURLNotContainsTrailingSlash() {
        let request = URLRequest(url: URL(string: "books/10")!)
        
        let expectation = XCTestExpectation(description: "Wait for completion")
        interceptor.adapt(request, for: .default) { result in
            switch result {
            case .success(let req):
                XCTAssertEqual(req.url?.absoluteString, "https://booklibrary.com/books/10")
            case .failure:
                XCTFail("Expected result: .success, actual result: .failure")
            }
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1)
    }
    
    func testAdaptWhenURLContainsTrailingSlash() {
        let request = URLRequest(url: URL(string: "path/")!)
        let exp = expectation(description: "Adapting url request")
        interceptor.adapt(request, for: .default) { result in
            let request = try! result.get()
            XCTAssertEqual(request.url?.absoluteString, "https://booklibrary.com/path/")
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1)
    }
    
    func testAdaptWhenURLContainsQueryItems() {
        let url = URL(string: "api/path/")!
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)!
        components.queryItems = [URLQueryItem(name: "param", value: "value")]
        
        let request = URLRequest(url: components.url!)
        let exp = expectation(description: "Adapting url request")
        interceptor.adapt(request, for: .default) { result in
            let request = try! result.get()
            XCTAssertEqual(request.url?.absoluteString, "https://booklibrary.com/api/path/?param=value")
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1)
    }
    
    func testAdaptWhenRequestContainsHeaders() {
        var request = URLRequest(url: URL(string: "books")!)
        request.addValue("application/octet-stream", forHTTPHeaderField: "Content-Type")
        
        let expectation = XCTestExpectation(description: "Wait for completion")
        interceptor.adapt(request, for: .default) { result in
            switch result {
            case .success(let req):
                XCTAssertEqual(req.value(forHTTPHeaderField: "Content-Type"), "application/octet-stream")
            case .failure:
                XCTFail("Expected result: .success, actual result: .failure")
            }
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1)
    }
}
