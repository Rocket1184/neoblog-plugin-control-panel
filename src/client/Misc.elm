module Misc exposing (..)

import List
import String
import Html
import Html.Events
import Json.Decode


{-| ref: <https://github.com/rtfeldman/elm-spa-example/blob/4213d8cb6fe4d72f82b7cdd5bc43f64fab99ad12/src/Util.elm>
-}
(=>) : a -> b -> ( a, b )
(=>) =
    (,)


{-| Html 'onkeydown' event
-}
onKeyDown : (Int -> msg) -> Html.Attribute msg
onKeyDown tagger =
    Html.Events.on "keydown" (Json.Decode.map tagger Html.Events.keyCode)


{-| Convert String to Int; If there are any errors, just return the default value
-}
toIntDefault : Int -> String -> Int
toIntDefault default str =
    case String.toInt str of
        Ok int ->
            int

        Err _ ->
            default


{-| Build url with List of querystring parameters
-}
urlWithQuery : String -> List ( String, String ) -> String
urlWithQuery url params =
    String.join "?"
        [ url
        , String.join "&"
            (List.map
                (\( key, value ) -> key ++ "=" ++ value)
                params
            )
        ]
