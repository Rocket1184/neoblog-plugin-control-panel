module Article exposing (..)

import String exposing (toInt)
import List
import Result exposing (withDefault)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Http
import Json.Decode
import Misc exposing ((=>), onKeyDown, urlWithQuery, formatDate)
import Data exposing (Session, Article, ArticleMeta, decodeArticle)
import Request


-- Model


type alias Model =
    { articles : List Article
    , maxPage : Int
    , pageNumber : Int
    , numberInput : String
    }


init : Model
init =
    Model [] 1 1 ""



-- Update


type Msg
    = GotArticles (Result Http.Error ArticlesResponse)
    | SetPageNumber Int
    | InputPageNumber String
    | GoToPage
    | FetchArticles
    | NewClick
    | TitleClick Article
    | PrevPage
    | NextPage
    | Ignore


type ExternalMsg
    = NoOp
    | NewArticle
    | EditArticle Article


update : Session -> Msg -> Model -> ( ( Model, Cmd Msg ), ExternalMsg )
update session msg model =
    case msg of
        GotArticles (Ok result) ->
            { model
                | articles = result.articles
                , maxPage = ceiling ((toFloat result.total) / 10)
            }
                => Cmd.none
                => NoOp

        GotArticles (Err _) ->
            model
                => Cmd.none
                => NoOp

        SetPageNumber number ->
            update session FetchArticles { model | pageNumber = number }

        InputPageNumber input ->
            { model | numberInput = input }
                => Cmd.none
                => NoOp

        TitleClick article ->
            model
                => Cmd.none
                => EditArticle article

        GoToPage ->
            let
                inputPage =
                    withDefault model.pageNumber <| toInt model.numberInput

                newPage =
                    if inputPage >= model.maxPage then
                        model.maxPage
                    else if inputPage <= 0 then
                        1
                    else
                        inputPage

                newMsg =
                    SetPageNumber newPage

                newModel =
                    { model | numberInput = "" }
            in
                update session newMsg newModel

        FetchArticles ->
            model
                => (requestArticles session.token model.pageNumber)
                => NoOp

        NewClick ->
            model
                => Cmd.none
                => NewArticle

        PrevPage ->
            let
                newMsg =
                    SetPageNumber (model.pageNumber - 1)
            in
                update session newMsg model

        NextPage ->
            let
                newMsg =
                    SetPageNumber (model.pageNumber + 1)
            in
                update session newMsg model

        Ignore ->
            model
                => Cmd.none
                => NoOp



-- View


viewArticleTags : ArticleMeta -> Html Msg
viewArticleTags meta =
    div [ class "tags" ]
        (List.map (\tag -> span [] [ text tag ]) meta.tags)


viewArticle : Article -> Html Msg
viewArticle article =
    div [ class "article" ]
        [ a [ class "title", onClick (TitleClick article) ]
            [ text article.meta.title ]
        , viewArticleTags article.meta
        , span [ class "date" ] [ text <| formatDate article.meta.date ]
        ]


viewPagination : Model -> Html Msg
viewPagination model =
    let
        prev =
            if model.pageNumber == 1 then
                []
            else
                a
                    [ class "prev"
                    , onClick PrevPage
                    ]
                    [ span [] [ text "<" ]
                    ]
                    |> List.singleton

        next =
            if model.pageNumber >= model.maxPage then
                []
            else
                a
                    [ class "next"
                    , onClick NextPage
                    ]
                    [ span [] [ text ">" ]
                    ]
                    |> List.singleton

        number =
            [ input
                [ class "number"
                , type_ "number"
                , placeholder (toString model.pageNumber)
                , value model.numberInput
                , onInput InputPageNumber
                , onKeyDown
                    (\code ->
                        if code == 13 then
                            GoToPage
                        else
                            Ignore
                    )
                ]
                []
            , span [ class "number" ] [ text "/" ]
            , span [ class "number max" ]
                [ text <| toString model.maxPage
                ]
            ]
    in
        div [ class "pagination" ] (List.concat [ prev, number, next ])


view : Model -> Html Msg
view model =
    div [ class "manage-article" ]
        [ div [ class "operation" ]
            [ button [ onClick NewClick ] [ text "New Article" ]
            ]
        , div [ class "article-list" ] (List.map viewArticle model.articles)
        , viewPagination model
        ]



-- Http


type alias ArticlesResponse =
    { total : Int
    , articles : List Article
    }


decodeArticles : Json.Decode.Decoder ArticlesResponse
decodeArticles =
    Json.Decode.map2 ArticlesResponse
        (Json.Decode.field "total" Json.Decode.int)
        (Json.Decode.field "articles" (Json.Decode.list decodeArticle))


requestArticles : String -> Int -> Cmd Msg
requestArticles token page =
    let
        offset =
            (page - 1) * 10

        limit =
            10

        url =
            urlWithQuery "api/articles"
                [ ( "offset", toString offset )
                , ( "limit", toString limit )
                ]
    in
        Request.get url token decodeArticles
            |> Http.send GotArticles
