// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
@_spi(Execution) @_spi(Unsafe) import ApolloAPI

extension AniListAPI {
  struct GetSeasonalAnimeQuery: GraphQLQuery {
    static let operationName: String = "GetSeasonalAnime"
    static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"query GetSeasonalAnime($season: MediaSeason!, $seasonYear: Int!, $page: Int, $perPage: Int) { Page(page: $page, perPage: $perPage) { __typename pageInfo { __typename currentPage hasNextPage } media( type: ANIME season: $season seasonYear: $seasonYear format: TV sort: POPULARITY_DESC ) { __typename id title { __typename romaji english } description(asHtml: false) coverImage { __typename extraLarge large } nextAiringEpisode { __typename episode airingAt } } } }"#
      ))

    public var season: GraphQLEnum<MediaSeason>
    public var seasonYear: Int32
    public var page: GraphQLNullable<Int32>
    public var perPage: GraphQLNullable<Int32>

    public init(
      season: GraphQLEnum<MediaSeason>,
      seasonYear: Int32,
      page: GraphQLNullable<Int32>,
      perPage: GraphQLNullable<Int32>
    ) {
      self.season = season
      self.seasonYear = seasonYear
      self.page = page
      self.perPage = perPage
    }

    @_spi(Unsafe) public var __variables: Variables? { [
      "season": season,
      "seasonYear": seasonYear,
      "page": page,
      "perPage": perPage
    ] }

    struct Data: AniListAPI.SelectionSet {
      let __data: DataDict
      init(_dataDict: DataDict) { __data = _dataDict }

      static var __parentType: any ApolloAPI.ParentType { AniListAPI.Objects.Query }
      static var __selections: [ApolloAPI.Selection] { [
        .field("Page", Page?.self, arguments: [
          "page": .variable("page"),
          "perPage": .variable("perPage")
        ]),
      ] }
      static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        GetSeasonalAnimeQuery.Data.self
      ] }

      var page: Page? { __data["Page"] }

      /// Page
      ///
      /// Parent Type: `Page`
      struct Page: AniListAPI.SelectionSet {
        let __data: DataDict
        init(_dataDict: DataDict) { __data = _dataDict }

        static var __parentType: any ApolloAPI.ParentType { AniListAPI.Objects.Page }
        static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("pageInfo", PageInfo?.self),
          .field("media", [Medium?]?.self, arguments: [
            "type": "ANIME",
            "season": .variable("season"),
            "seasonYear": .variable("seasonYear"),
            "format": "TV",
            "sort": "POPULARITY_DESC"
          ]),
        ] }
        static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          GetSeasonalAnimeQuery.Data.Page.self
        ] }

        /// The pagination information
        var pageInfo: PageInfo? { __data["pageInfo"] }
        var media: [Medium?]? { __data["media"] }

        /// Page.PageInfo
        ///
        /// Parent Type: `PageInfo`
        struct PageInfo: AniListAPI.SelectionSet {
          let __data: DataDict
          init(_dataDict: DataDict) { __data = _dataDict }

          static var __parentType: any ApolloAPI.ParentType { AniListAPI.Objects.PageInfo }
          static var __selections: [ApolloAPI.Selection] { [
            .field("__typename", String.self),
            .field("currentPage", Int?.self),
            .field("hasNextPage", Bool?.self),
          ] }
          static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
            GetSeasonalAnimeQuery.Data.Page.PageInfo.self
          ] }

          /// The current page
          var currentPage: Int? { __data["currentPage"] }
          /// If there is another page
          var hasNextPage: Bool? { __data["hasNextPage"] }
        }

        /// Page.Medium
        ///
        /// Parent Type: `Media`
        struct Medium: AniListAPI.SelectionSet {
          let __data: DataDict
          init(_dataDict: DataDict) { __data = _dataDict }

          static var __parentType: any ApolloAPI.ParentType { AniListAPI.Objects.Media }
          static var __selections: [ApolloAPI.Selection] { [
            .field("__typename", String.self),
            .field("id", Int.self),
            .field("title", Title?.self),
            .field("description", String?.self, arguments: ["asHtml": false]),
            .field("coverImage", CoverImage?.self),
            .field("nextAiringEpisode", NextAiringEpisode?.self),
          ] }
          static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
            GetSeasonalAnimeQuery.Data.Page.Medium.self
          ] }

          /// The id of the media
          var id: Int { __data["id"] }
          /// The official titles of the media in various languages
          var title: Title? { __data["title"] }
          /// Short description of the media's story and characters
          var description: String? { __data["description"] }
          /// The cover images of the media
          var coverImage: CoverImage? { __data["coverImage"] }
          /// The media's next episode airing schedule
          var nextAiringEpisode: NextAiringEpisode? { __data["nextAiringEpisode"] }

          /// Page.Medium.Title
          ///
          /// Parent Type: `MediaTitle`
          struct Title: AniListAPI.SelectionSet {
            let __data: DataDict
            init(_dataDict: DataDict) { __data = _dataDict }

            static var __parentType: any ApolloAPI.ParentType { AniListAPI.Objects.MediaTitle }
            static var __selections: [ApolloAPI.Selection] { [
              .field("__typename", String.self),
              .field("romaji", String?.self),
              .field("english", String?.self),
            ] }
            static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
              GetSeasonalAnimeQuery.Data.Page.Medium.Title.self
            ] }

            /// The romanization of the native language title
            var romaji: String? { __data["romaji"] }
            /// The official english title
            var english: String? { __data["english"] }
          }

          /// Page.Medium.CoverImage
          ///
          /// Parent Type: `MediaCoverImage`
          struct CoverImage: AniListAPI.SelectionSet {
            let __data: DataDict
            init(_dataDict: DataDict) { __data = _dataDict }

            static var __parentType: any ApolloAPI.ParentType { AniListAPI.Objects.MediaCoverImage }
            static var __selections: [ApolloAPI.Selection] { [
              .field("__typename", String.self),
              .field("extraLarge", String?.self),
              .field("large", String?.self),
            ] }
            static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
              GetSeasonalAnimeQuery.Data.Page.Medium.CoverImage.self
            ] }

            /// The cover image url of the media at its largest size. If this size isn't available, large will be provided instead.
            var extraLarge: String? { __data["extraLarge"] }
            /// The cover image url of the media at a large size
            var large: String? { __data["large"] }
          }

          /// Page.Medium.NextAiringEpisode
          ///
          /// Parent Type: `AiringSchedule`
          struct NextAiringEpisode: AniListAPI.SelectionSet {
            let __data: DataDict
            init(_dataDict: DataDict) { __data = _dataDict }

            static var __parentType: any ApolloAPI.ParentType { AniListAPI.Objects.AiringSchedule }
            static var __selections: [ApolloAPI.Selection] { [
              .field("__typename", String.self),
              .field("episode", Int.self),
              .field("airingAt", Int.self),
            ] }
            static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
              GetSeasonalAnimeQuery.Data.Page.Medium.NextAiringEpisode.self
            ] }

            /// The airing episode number
            var episode: Int { __data["episode"] }
            /// The time the episode airs at
            var airingAt: Int { __data["airingAt"] }
          }
        }
      }
    }
  }

}