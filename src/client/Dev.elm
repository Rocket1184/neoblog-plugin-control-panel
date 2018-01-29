module Dev exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Main


{-| Attach stylesheet to Dev html
-}
stylesheet : Html msg
stylesheet =
    node "link"
        [ rel "stylesheet"
        , href "./style.css"
        ]
        []


view : Main.Model -> Html Main.Msg
view model =
    div []
        [ Main.view model
        , stylesheet
        ]


main : Program Never Main.Model Main.Msg
main =
    Html.program
        { init = Main.init
        , view = view
        , update = Main.update
        , subscriptions = Main.subscriptions
        }
