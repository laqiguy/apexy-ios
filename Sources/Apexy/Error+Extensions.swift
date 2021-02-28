//
//  Error+Extensions.swift
//  Apexy
//
//  Created by Aleksei Tiurnin on 28.02.2021.
//

import Foundation

public enum APError<T: Error>: Error {
    case connection(APConnectionError)
    case decoding(Error)
    case endpoint(T)
}

public enum APConnectionError: Error {
    case noConnection
    case canceled
    case unknown
}

public struct ErrorInfo: Decodable {
    var error: String
    var description: String
}

public struct ErrorDescription<T: Error>: Error {
    let value: T
    
    let info: ErrorInfo
}
