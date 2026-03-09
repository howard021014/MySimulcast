import Foundation
@testable import MySimulcast

final class MockNetworkStatus: NetworkStatusProviding {
    var isConnected: Bool = true
}
