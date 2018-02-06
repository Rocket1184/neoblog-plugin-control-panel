module Dev exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Navigation
import Main


view : Main.Model -> Html Main.Msg
view model =
    div []
        [ node "link" [ rel "stylesheet", href "./style.css" ] []
        , Main.view model
        ]


main : Program Never Main.Model Main.Msg
main =
    Navigation.program Main.UrlChange
        { init = Main.init
        , view = view
        , update = Main.update
        , subscriptions = Main.subscriptions
        }
