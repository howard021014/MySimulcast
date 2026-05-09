// @generated
// This file was automatically generated and should not be edited.

import ApolloAPI

protocol AniListAPI_SelectionSet: ApolloAPI.SelectionSet & ApolloAPI.RootSelectionSet
where Schema == AniListAPI.SchemaMetadata {}

protocol AniListAPI_InlineFragment: ApolloAPI.SelectionSet & ApolloAPI.InlineFragment
where Schema == AniListAPI.SchemaMetadata {}

protocol AniListAPI_MutableSelectionSet: ApolloAPI.MutableRootSelectionSet
where Schema == AniListAPI.SchemaMetadata {}

protocol AniListAPI_MutableInlineFragment: ApolloAPI.MutableSelectionSet & ApolloAPI.InlineFragment
where Schema == AniListAPI.SchemaMetadata {}

extension AniListAPI {
  typealias SelectionSet = AniListAPI_SelectionSet

  typealias InlineFragment = AniListAPI_InlineFragment

  typealias MutableSelectionSet = AniListAPI_MutableSelectionSet

  typealias MutableInlineFragment = AniListAPI_MutableInlineFragment

  enum SchemaMetadata: ApolloAPI.SchemaMetadata {
    static let configuration: any ApolloAPI.SchemaConfiguration.Type = SchemaConfiguration.self

    static func objectType(forTypename typename: String) -> ApolloAPI.Object? {
      switch typename {
      case "AiringSchedule": return AniListAPI.Objects.AiringSchedule
      case "Media": return AniListAPI.Objects.Media
      case "MediaCoverImage": return AniListAPI.Objects.MediaCoverImage
      case "MediaTitle": return AniListAPI.Objects.MediaTitle
      case "Page": return AniListAPI.Objects.Page
      case "PageInfo": return AniListAPI.Objects.PageInfo
      case "Query": return AniListAPI.Objects.Query
      case "Studio": return AniListAPI.Objects.Studio
      case "StudioConnection": return AniListAPI.Objects.StudioConnection
      default: return nil
      }
    }
  }

  enum Objects {}
  enum Interfaces {}
  enum Unions {}

}