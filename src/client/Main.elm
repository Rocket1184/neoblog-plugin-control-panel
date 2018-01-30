module Main exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Data exposing (Session)


-- Page import

import Login


-- Model


type PageModel
    = Login Login.Model


type alias Model =
    { session : Session
    , page : PageModel
    }


init : ( Model, Cmd Msg )
init =
    ( { session = Session ""
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
                Html.map LoginMsg (Login.view pageModel)
        ]



-- Update


type Msg
    = LoginMsg Login.Msg


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
                                    { model | session = Session token }
                    in
                        ( { newModel | page = Login newPageModel }, Cmd.map LoginMsg pageCmd )



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
