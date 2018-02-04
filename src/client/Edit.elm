module Edit exposing (..)

import String
import List
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Json.Encode exposing (encode)
import Task
import Time
import Date
import Http
import Data exposing (..)
import Request
import Misc exposing ((=>))


-- Model


type SaveMode
    = New
    | Edit


type alias Model =
    { mode : SaveMode
    , url : String
    , meta : ArticleMeta
    , content : String
    }


init : SaveMode -> String -> Model
init mode url =
    Model
        mode
        url
        (ArticleMeta "" "" [])
        ""



-- Update


type Msg
    = Load
    | LoadResponse (Result Http.Error ArticleDetail)
    | SetURL String
    | SetTitle String
    | SetDate String
    | SetTags String
    | SetContent String
    | Save
    | SaveResponse (Result Http.Error ErrorMsg)
    | Back
    | Ignore String


type ExternalMsg
    = NoOp
    | BackToList


update : Session -> Msg -> Model -> ( ( Model, Cmd Msg ), ExternalMsg )
update session msg model =
    case msg of
        Load ->
            case model.mode of
                New ->
                    { model | meta = ArticleMeta "" "" [] }
                        => updateDateNow
                        => NoOp

                Edit ->
                    model
                        => requestDetail session.token model.url
                        => NoOp

        SetURL url ->
            { model | url = url }
                => Cmd.none
                => NoOp

        SetTitle title ->
            let
                meta =
                    model.meta

                newMeta =
                    { meta | title = title }
            in
                { model | meta = newMeta }
                    => Cmd.none
                    => NoOp

        SetDate now ->
            let
                meta =
                    model.meta

                newMeta =
                    { meta | date = now }
            in
                { model | meta = newMeta }
                    => Cmd.none
                    => NoOp

        SetTags tags ->
            let
                meta =
                    model.meta

                newMeta =
                    { meta | tags = String.split "," tags }
            in
                { model | meta = newMeta }
                    => Cmd.none
                    => NoOp

        SetContent content ->
            { model | content = content }
                => Cmd.none
                => NoOp

        Back ->
            model
                => Cmd.none
                => BackToList

        Save ->
            model
                => requestSave session.token model
                => NoOp

        _ ->
            model
                => Cmd.none
                => NoOp


updateDateNow : Cmd Msg
updateDateNow =
    Task.perform (Date.fromTime >> toString >> SetDate) Time.now



-- View


viewInput : String -> String -> (String -> msg) -> Bool -> Html msg
viewInput hint val toMsg bind =
    let
        attr1 =
            [ defaultValue val, type_ "text", placeholder hint ]

        attr2 =
            case bind of
                True ->
                    [ onInput toMsg ]

                False ->
                    [ readonly True ]
    in
        input (List.concat [ attr1, attr2 ]) []


view : Model -> Html Msg
view model =
    let
        viewInputURL =
            case model.mode of
                New ->
                    viewInput "URL" model.url SetURL True

                Edit ->
                    viewInput "URL" model.url Ignore False
    in
        div [ class "manage-edit" ]
            [ div [ class "editor" ]
                [ viewInputURL
                , viewInput "Title" model.meta.title SetTitle True
                , viewInput "Date" model.meta.date SetDate True
                , viewInput "Tags, separate by ',' ." (String.join "," model.meta.tags) SetTags True
                , textarea [ placeholder "Your Article Here :)", onInput SetContent ] []
                , div [ class "operation" ]
                    [ button [ onClick Back ] [ text "Back" ]
                    , button [ onClick Save ] [ text "Save" ]
                    ]
                ]
            , div [ class "preview" ] []
            ]



-- Http


requestDetail : String -> String -> Cmd Msg
requestDetail token name =
    let
        url =
            "api/articles/" ++ name
    in
        Request.get url token deocdeArticleDetail
            |> Http.send LoadResponse


jsonBody : String -> ArticleMeta -> String -> Http.Body
jsonBody ext meta content =
    let
        src =
            String.join "\n"
                [ "```meta"
                , encode 4 <| encodeArticleMeta meta
                , "```"
                , content
                ]

        payload =
            ArticleForSend ext src
    in
        encodeArticleSend payload
            |> Http.jsonBody


requestSave : String -> Model -> Cmd Msg
requestSave token model =
    let
        url =
            "api/articles/" ++ model.url

        body =
            jsonBody "md" model.meta model.content
    in
        case model.mode of
            New ->
                Request.post url token body decodeErrMsg
                    |> Http.send SaveResponse

            _ ->
                Cmd.none
