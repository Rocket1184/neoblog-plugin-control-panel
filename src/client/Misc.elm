module Misc exposing ((=>))

{-| ref: <https://github.com/rtfeldman/elm-spa-example/blob/4213d8cb6fe4d72f82b7cdd5bc43f64fab99ad12/src/Util.elm>
-}


(=>) : a -> b -> ( a, b )
(=>) =
    (,)
