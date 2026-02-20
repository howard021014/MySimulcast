import Apollo
import Foundation

struct ApolloClientProvider {
    static let shared = ApolloClient(url: URL(string: "https://graphql.anilist.co")!)
}
