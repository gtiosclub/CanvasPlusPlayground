//
//  NetworkRequestRecorder.swift
//  CanvasPlusPlayground
//
//  Created by Ethan Fox on 8/29/25.
//

import Foundation

@Observable
final class NetworkRequestRecorder {
    static let shared = NetworkRequestRecorder()
    private init() {}
    var counter = 0
    var records: [NetworkRequestResponsePair] = []
    
    func addRecord(request: URLRequest, response: URLResponse?) {
        
        let pair = NetworkRequestResponsePair(request: request, response: response, timestamp: Date.now, id: counter)
        records.append(pair)
        counter += 1
        print("Counter: \(counter)")
    }
}

struct NetworkRequestResponsePair: Identifiable, Hashable {
    let request: URLRequest
    let response: URLResponse? // who ever said we were going to get a response...
    let timestamp: Date
    let id: Int
    
}
