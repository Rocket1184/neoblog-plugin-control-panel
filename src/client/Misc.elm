module Misc exposing (..)

import String
import Html
import Html.Events
import Json.Decode


{-| ref: <https://github.com/rtfeldman/elm-spa-example/blob/4213d8cb6fe4d72f82b7cdd5bc43f64fab99ad12/src/Util.elm>
-}
(=>) : a -> b -> ( a, b )
(=>) =
    (,)


onKeyDown : (Int -> msg) -> Html.Attribute msg
onKeyDown tagger =
    Html.Events.on "keydown" (Json.Decode.map tagger Html.Events.keyCode)

toIntDefault : Int -> String -> Int
toIntDefault default str =
    case String.toInt str of
        Ok int ->
            int

        Err _ ->
            default
