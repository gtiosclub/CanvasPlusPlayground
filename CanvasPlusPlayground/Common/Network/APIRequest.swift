//
//  APIRequest.swift
//  CanvasPlusPlayground
//
//  Created by Abdulaziz Albahar on 12/17/24.
//

import Foundation

protocol APIRequest {
    associatedtype Subject: APIResponse
    associatedtype QueryResult: Codable = Subject

    typealias QueryParameter = (name: String, value: Any?)

    var path: String { get }
    var queryParameters: [QueryParameter] { get }
    var method: RequestMethod { get }
    var perPage: Int { get }
}

protocol ArrayAPIRequest: APIRequest {
    associatedtype QueryResult = [Subject]
}

protocol CacheableAPIRequest: APIRequest where Subject.Model: Cacheable {
    typealias PersistedModel = Subject.Model

    associatedtype KeyType: Equatable

    var requestId: KeyType { get }
    var requestIdKey: ParentKeyPath<Subject.Model, KeyType> { get }
    var idPredicate: Predicate<Subject.Model> { get }
    var customPredicate: Predicate<Subject.Model> { get }
}

protocol CacheableArrayAPIRequest: CacheableAPIRequest where QueryResult == [Subject] {}

protocol NoReturnAPIRequest: APIRequest {
    associatedtype Subject = Empty
}

extension APIRequest {
    var baseURL: URL {
        if let baseURL = URL(string: "https://gatech.instructure.com/api/v1") {
            return baseURL
        } else {
            fatalError("Invalid base Canvas URL")
        }
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

    var method: RequestMethod { .GET }

    var perPage: Int { 50 }
}
