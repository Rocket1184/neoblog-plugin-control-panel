module Dev exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Main


stylesheet : Html msg
stylesheet =
    node "link"
        [ rel "stylesheet"
        , href "./style.css"
        ]
        []


main : Html msg
main =
    div []
        [ stylesheet
        , Main.program
        ]
