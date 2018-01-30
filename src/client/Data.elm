module Data exposing (..)

import Json.Decode exposing (..)


type alias Session =
    { token : String }


type alias FileMeta =
    { path : String
    , base : String
    , ext : String
    }


decodeFileMeta : Decoder FileMeta
decodeFileMeta =
    map3
        FileMeta
        (field "path" string)
        (field "base" string)
        (field "ext" string)


type alias ArticleMeta =
    { title : String
    , date : String
    , tags : List String
    }


decodeArticleMeta : Decoder ArticleMeta
decodeArticleMeta =
    map3
        ArticleMeta
        (field "title" string)
        (field "date" string)
        (field "tags" (list string))


type alias Article =
    { file : FileMeta
    , meta : ArticleMeta
    }


decodeArticle : Decoder Article
decodeArticle =
    map2
        Article
        (field "file" decodeFileMeta)
        (field "meta" decodeArticleMeta)


type alias ArticleDetail =
    { file : FileMeta
    , meta : ArticleMeta
    , src : String
    , excerpt : String
    , more : Bool
    }


deocdeArticleDetail : Decoder ArticleDetail
deocdeArticleDetail =
    map5
        ArticleDetail
        (field "file" decodeFileMeta)
        (field "meta" decodeArticleMeta)
        (field "src" string)
        (field "excerpt" string)
        (field "more" bool)
