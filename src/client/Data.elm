module Data exposing (..)

import List
import Date exposing (Date)
import Json.Decode as D exposing (Decoder)
import Json.Decode.Extra as DE
import Json.Encode as E exposing (Value)


type alias Session =
    { token : String }


type alias ErrorMsg =
    { message : String }


decodeErrMsg : Decoder ErrorMsg
decodeErrMsg =
    D.map
        ErrorMsg
        (D.field "message" D.string)


type alias FileMeta =
    { path : String
    , base : String
    , ext : String
    }


decodeFileMeta : Decoder FileMeta
decodeFileMeta =
    D.map3
        FileMeta
        (D.field "path" D.string)
        (D.field "base" D.string)
        (D.field "ext" D.string)


type alias ArticleMeta =
    { title : String
    , date : Date
    , tags : List String
    }


decodeArticleMeta : Decoder ArticleMeta
decodeArticleMeta =
    D.map3
        ArticleMeta
        (D.field "title" D.string)
        (D.field "date" DE.date)
        (D.field "tags" (D.list D.string))


encodeArticleMeta : ArticleMeta -> E.Value
encodeArticleMeta meta =
    E.object
        [ ( "title", E.string meta.title )
        , ( "date", E.string <| toString meta.date )
        , ( "tags", E.list <| List.map E.string meta.tags )
        ]


type alias Article =
    { file : FileMeta
    , meta : ArticleMeta
    }


decodeArticle : Decoder Article
decodeArticle =
    D.map2
        Article
        (D.field "file" decodeFileMeta)
        (D.field "meta" decodeArticleMeta)


type alias ArticleDetail =
    { file : FileMeta
    , meta : ArticleMeta
    , src : String
    , excerpt : String
    , more : Bool
    }


deocdeArticleDetail : Decoder ArticleDetail
deocdeArticleDetail =
    D.map5
        ArticleDetail
        (D.field "file" decodeFileMeta)
        (D.field "meta" decodeArticleMeta)
        (D.field "src" D.string)
        (D.field "excerpt" D.string)
        (D.field "more" D.bool)


type alias ArticleForSend =
    { ext : String
    , src : String
    }


encodeArticleSend : ArticleForSend -> E.Value
encodeArticleSend article =
    E.object
        [ ( "type", E.string article.ext )
        , ( "src", E.string article.src )
        ]
