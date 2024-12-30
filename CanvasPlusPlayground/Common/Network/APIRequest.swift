//
//  APIRequest.swift
//  CanvasPlusPlayground
//
//  Created by Abdulaziz Albahar on 12/17/24.
//

import Foundation

protocol APIRequest {
    associatedtype Subject: Codable
    associatedtype QueryResult: Codable = Subject

    typealias QueryParameter = (name: String, value: Any?)

    var path: String { get }
    var queryParameters: [QueryParameter] { get }
}

extension APIRequest {
    var baseURL: URL {
        URL(string: "https://gatech.instructure.com/api/v1")!
    }

    var combinedQueryParams: [(String, String)] {
        ([(name: "access_token", value: StorageKeys.accessTokenValue)] + queryParameters).compactMap {
            let (key, val) = $0
            guard let val else {
                return nil
            }
            return (key, "\(val)")
        }
    }

    var url: URL {
        baseURL
            .appendingPathComponent(path)
            .appending(queryItems: combinedQueryParams.map { name, val in
                URLQueryItem(name: name, value: "\(val)")
            })
    }
}

protocol ArrayAPIRequest: APIRequest {
    associatedtype QueryResult = [Subject]
}

protocol CacheableAPIRequest: APIRequest where Subject: Cacheable {
    associatedtype KeyType: Equatable

    var requestId: KeyType { get }
    var requestIdKey: ParentKeyPath<Subject, KeyType> { get }
    var idPredicate: Predicate<Subject> { get }
    var customPredicate: Predicate<Subject> { get }
}

protocol CacheableArrayAPIRequest: CacheableAPIRequest where QueryResult == [Subject] {}
