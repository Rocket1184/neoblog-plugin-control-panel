module Article exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Http
import String
import Json.Encode
import Json.Decode
import List
import Misc exposing ((=>))
import Data
import Request


-- Model


type alias Model =
    { articles : List Data.Article
    , total : Int
    , pageNumber : Int
    , numberInput : String
    }


init : Model
init =
    Model [] 1 1 ""



-- Update


type Msg
    = GotArticles (Result Http.Error ArticlesReponse)
    | SetPageNumber Int
    | InputPageNumber String
    | GoToPage
    | FetchArticles
    | TitleClick Data.Article
    | Ignore


type ExternalMsg
    = NoOp
    | EditArticle Data.Article


update : Data.Session -> Msg -> Model -> ( ( Model, Cmd Msg ), ExternalMsg )
update session msg model =
    case msg of
        GotArticles (Ok result) ->
            { model
                | articles = result.articles
                , total = result.total
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
                newNum =
                    case (String.toInt model.numberInput) of
                        Ok number ->
                            number

                        Err msg ->
                            model.pageNumber
            in
                update session (SetPageNumber model.pageNumber) model

        FetchArticles ->
            model
                => (requestArticles session.token)
                => NoOp

        Ignore ->
            model
                => Cmd.none
                => NoOp



-- View


onKeyDown : (Int -> msg) -> Attribute msg
onKeyDown tagger =
    on "keydown" (Json.Decode.map tagger keyCode)


viewArticleTags : Data.ArticleMeta -> Html Msg
viewArticleTags meta =
    div [ class "tags" ]
        (List.map (\tag -> span [] [ text tag ]) meta.tags)


viewArticle : Data.Article -> Html Msg
viewArticle article =
    div [ class "article" ]
        [ a [ class "title", onClick (TitleClick article) ]
            [ text article.meta.title ]
        , viewArticleTags article.meta
        , span [ class "date" ] [ text article.meta.date ]
        ]


viewPaignation : Int -> Int -> Html Msg
viewPaignation total current =
    let
        prev =
            if current == 1 then
                []
            else
                [ span [ class "button" ] [ text "<" ] ]

        next =
            if current == total then
                []
            else
                [ span [ class "button" ] [ text ">" ] ]

        number =
            [ input
                [ class "number"
                , value (toString current)
                , type_ "number"
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
            ]
    in
        div [ class "pagination" ] (List.concat [ prev, number, next ])


view : Model -> Html Msg
view model =
    div [ class "manage-article" ]
        [ div [ class "article-list" ] (List.map viewArticle model.articles)
        , viewPaignation model.total model.pageNumber
        ]



-- Http


type alias ArticlesReponse =
    { total : Int
    , articles : List Data.Article
    }


decodeArticles : Json.Decode.Decoder ArticlesReponse
decodeArticles =
    Json.Decode.map2 ArticlesReponse
        (Json.Decode.field "total" Json.Decode.int)
        (Json.Decode.field "aritcles" (Json.Decode.list Data.decodeArticle))


requestArticles : String -> Cmd Msg
requestArticles token =
    Request.get "api/articles" token decodeArticles
        |> Http.send GotArticles
