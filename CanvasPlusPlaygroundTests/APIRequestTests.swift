@testable import CanvasPlusPlayground
import Foundation
import Testing

struct APIRequestTests {
    @Test func usersSelfRequestsBypassLocalHTTPCache() {
        #expect(CanvasRequest.getUser().makeURLRequest().cachePolicy == .reloadIgnoringLocalCacheData)
        #expect(CanvasRequest.getUser(id: "self").makeURLRequest().cachePolicy == .reloadIgnoringLocalCacheData)
    }

    @Test func otherRequestsKeepDefaultHTTPCachePolicy() {
        #expect(CanvasRequest.getUser(id: "1001").makeURLRequest().cachePolicy == .useProtocolCachePolicy)
        #expect(CanvasRequest.getUserProfile().makeURLRequest().cachePolicy == .useProtocolCachePolicy)
        #expect(CanvasRequest.getCourse(id: "1001").makeURLRequest().cachePolicy == .useProtocolCachePolicy)
    }
}
