module Edit exposing (..)

import String
import List
import Regex exposing (regex, replace)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Html.Attributes.Extra exposing (innerHtml)
import Json.Encode exposing (encode)
import Task
import Time
import Date exposing (Date)
import Http
import Data exposing (..)
import Request
import Misc exposing ((=>), dateString)


-- Model


type SaveMode
    = New
    | Edit


type alias Model =
    { mode : SaveMode
    , url : String
    , meta : ArticleMeta
    , dateInput : String
    , content : String
    , preview : Bool
    , html : String
    }


init : SaveMode -> String -> Model
init mode url =
    Model
        mode
        url
        (ArticleMeta "" (Date.fromTime 0) [])
        ""
        ""
        False
        ""



-- Update


type Msg
    = Load
    | LoadResponse (Result Http.Error ArticleDetail)
    | SetURL String
    | SetTitle String
    | SetDate String
    | DateBlur
    | SetTags String
    | SetContent String
    | SetPreivew (Result Http.Error String)
    | TogglePreview
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
                    { model | meta = ArticleMeta "" (Date.fromTime 0) [] }
                        => updateDateNow
                        => NoOp

                Edit ->
                    model
                        => requestDetail session.token model.url
                        => NoOp

        LoadResponse response ->
            case response of
                Ok detail ->
                    let
                        regexp =
                            regex "^```(meta)?\n[^`]+\n```\n"

                        content =
                            replace Regex.All regexp (\_ -> "") detail.src

                        dateInput =
                            dateString detail.meta.date
                    in
                        { model
                            | meta = detail.meta
                            , dateInput = dateInput
                            , content = content
                        }
                            => Cmd.none
                            => NoOp

                Err _ ->
                    model
                        => Cmd.none
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

        SetDate str ->
            let
                newModel =
                    { model | dateInput = str }

                newMeta =
                    newModel.meta
            in
                case Date.fromString str of
                    Ok date ->
                        { newModel | meta = { newMeta | date = date } }
                            => Cmd.none
                            => NoOp

                    Err _ ->
                        newModel
                            => Cmd.none
                            => NoOp

        DateBlur ->
            { model | dateInput = dateString model.meta.date }
                => Cmd.none
                => NoOp

        SetTags tags ->
            let
                newTags =
                    String.split "," tags
                        |> List.map String.trim

                meta =
                    model.meta

                newMeta =
                    { meta | tags = newTags }
            in
                { model | meta = newMeta }
                    => Cmd.none
                    => NoOp

        SetContent content ->
            { model | content = content }
                => Cmd.none
                => NoOp

        SetPreivew response ->
            case response of
                Ok html ->
                    { model | html = html }
                        => Cmd.none
                        => NoOp

                Err (Http.BadStatus response) ->
                    { model | html = "<pre>" ++ response.body ++ "</pre>" }
                        => Cmd.none
                        => NoOp

                Err _ ->
                    model
                        => Cmd.none
                        => NoOp

        TogglePreview ->
            let
                preview =
                    not model.preview

                cmd =
                    case preview of
                        True ->
                            requestPreview "md" model.content

                        False ->
                            Cmd.none
            in
                { model | preview = preview }
                    => cmd
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


{-| set model.meta.date as now
-}
updateDateNow : Cmd Msg
updateDateNow =
    Task.perform (Date.fromTime >> dateString >> SetDate) Time.now



-- View


viewInput : String -> String -> (String -> msg) -> Bool -> Html msg
viewInput hint val toMsg bind =
    let
        attr1 =
            [ value val, type_ "text", placeholder hint ]

        attr2 =
            case bind of
                True ->
                    [ onInput toMsg ]

                False ->
                    [ disabled True ]
    in
        input (List.concat [ attr1, attr2 ]) []


viewInputDate : String -> Html Msg
viewInputDate val =
    input
        [ type_ "text"
        , placeholder "Date"
        , onInput SetDate
        , onBlur DateBlur
        , value val
        ]
        []


viewEditor : String -> Html Msg
viewEditor src =
    textarea
        [ placeholder "Your Article Here :)"
        , value src
        , onInput SetContent
        ]
        []


viewPreview : String -> Html Msg
viewPreview html =
    div [ class "preview", innerHtml html ] []


view : Model -> Html Msg
view model =
    let
        editorArea =
            case model.preview of
                True ->
                    viewPreview model.html

                False ->
                    viewEditor model.content

        activeClass active =
            case active of
                True ->
                    class "active"

                False ->
                    class ""
    in
        div [ class "manage-edit" ]
            [ div [ class "wrapper" ]
                [ viewInput "URL" model.url SetURL (model.mode == New)
                , viewInput "Title" model.meta.title SetTitle True
                , viewInputDate model.dateInput
                , viewInput "Tags, separate by ',' ." (String.join "," model.meta.tags) SetTags True
                , div [ class "editor-area" ]
                    [ div [ class "tab" ]
                        [ span [ onClick TogglePreview, activeClass <| not model.preview ] [ text "Compose" ]
                        , span [ onClick TogglePreview, activeClass model.preview ] [ text "Preview" ]
                        ]
                    , editorArea
                    ]
                , div [ class "operation" ]
                    [ button [ onClick Back ] [ text "Back" ]
                    , button [ onClick Save ] [ text "Save" ]
                    ]
                ]
            ]



-- Http


requestDetail : String -> String -> Cmd Msg
requestDetail token name =
    let
        url =
            "api/articles/" ++ name
    in
        Request.get url token decodeArticleDetail
            |> Http.send LoadResponse


requestPreview : String -> String -> Cmd Msg
requestPreview ext src =
    Http.request
        { method = "POST"
        , headers = []
        , url = "/api/preview/" ++ ext
        , body = Http.stringBody "text/plain" src
        , expect = Http.expectString
        , timeout = Nothing
        , withCredentials = False
        }
        |> Http.send SetPreivew


{-| encode ArticleMeta and content String into POST/PUT body
-}
buildBody : String -> ArticleMeta -> String -> Http.Body
buildBody ext meta content =
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


{-| request create or update article following current SaveMode
-}
requestSave : String -> Model -> Cmd Msg
requestSave token model =
    let
        url =
            "api/articles/" ++ model.url

        body =
            buildBody "md" model.meta model.content
    in
        case model.mode of
            New ->
                Request.post url token body decodeErrMsg
                    |> Http.send SaveResponse

            Edit ->
                Request.put url token body decodeErrMsg
                    |> Http.send SaveResponse
