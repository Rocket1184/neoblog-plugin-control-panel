module Login exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Http
import Json.Encode
import Json.Decode
import Crypto.Hash
import Misc exposing ((=>))


-- Model


type alias Model =
    { username : String
    , password : String
    }


init : Model
init =
    Model "" ""



-- Update


type Msg
    = Login
    | UsernameInput String
    | PasswordInput String
    | LoginComplete (Result Http.Error String)


type ExternalMsg
    = NoOp
    | SetToken String


update : Msg -> Model -> ( ( Model, Cmd Msg ), ExternalMsg )
update msg model =
    case msg of
        UsernameInput value ->
            { model | username = value }
                => Cmd.none
                => NoOp

        PasswordInput value ->
            { model | password = value }
                => Cmd.none
                => NoOp

        Login ->
            model
                => tryLogin model
                => NoOp

        LoginComplete (Ok token) ->
            model
                => Cmd.none
                => (SetToken token)

        LoginComplete (Err _) ->
            model
                => Cmd.none
                => NoOp



-- View


view : Model -> Html Msg
view model =
    div []
        [ h1 [] [ text "Login" ]
        , p []
            [ label [ for "usr" ] [ text "Username" ]
            , input [ name "username", id "usr", onInput UsernameInput ] []
            ]
        , p []
            [ label [ for "pwd" ] [ text "Password" ]
            , input [ name "password", id "pwd", type_ "password", onInput PasswordInput ] []
            ]
        , p [] [ button [ onClick Login ] [ text "Login" ] ]
        ]



-- HTTP


getJsonBody : Model -> Http.Body
getJsonBody model =
    let
        hashed =
            Crypto.Hash.sha384 model.password
    in
        Json.Encode.object
            [ ( "usr", Json.Encode.string model.username )
            , ( "pwd", Json.Encode.string hashed )
            ]
            |> Http.jsonBody


tryLogin : Model -> Cmd Msg
tryLogin model =
    let
        url =
            "api/token"

        body =
            getJsonBody model
    in
        Http.send LoginComplete (Http.post url body decodeToken)


decodeToken : Json.Decode.Decoder String
decodeToken =
    Json.Decode.field "token" Json.Decode.string
