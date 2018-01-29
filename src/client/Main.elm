module Main exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)


-- Page import

import Login


-- Model


type PageModel
    = Login Login.Model


type alias Model =
    { token : String
    , page : PageModel
    }


init : ( Model, Cmd Msg )
init =
    ( { token = ""
      , page = Login Login.init
      }
    , Cmd.none
    )



-- View


view : Model -> Html Msg
view model =
    div [ class "page-wrapper" ]
        [ case model.page of
            Login pageModel ->
                Login.view pageModel
                    |> Html.map LoginMsg
        , p [] [ text model.token ]
        ]



-- Update


type Msg
    = LoginMsg Login.Msg
    | SetToken String


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case model.page of
        Login pageModel ->
            case msg of
                LoginMsg pageMsg ->
                    let
                        ( ( newPageModel, pageCmd ), msgFromPage ) =
                            Login.update pageMsg pageModel

                        newModel =
                            case msgFromPage of
                                Login.NoOp ->
                                    model

                                Login.SetToken token ->
                                    { model | token = token }
                    in
                        ( { newModel | page = Login newPageModel }, Cmd.map LoginMsg pageCmd )

                SetToken token ->
                    ( { model | token = token }, Cmd.none )



-- Subscriptions


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none


main : Program Never Model Msg
main =
    Html.program
        { init = init
        , view = view
        , update = update
        , subscriptions = (subscriptions)
        }
