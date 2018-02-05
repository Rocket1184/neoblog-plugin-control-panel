module Route exposing (..)

import String
import Navigation exposing (Location)
import UrlParser exposing (..)


type Route
    = Login
    | Articles
    | New
    | Edit String
    | NotFound


topRoutes : String -> Route
topRoutes name =
    case name of
        "login" ->
            Login

        "new" ->
            New

        "articles" ->
            Articles

        _ ->
            NotFound


route : Parser (Route -> a) a
route =
    oneOf
        [ map topRoutes (s "!" </> string)
        , map Edit (s "!" </> s "edit" </> string)
        ]


parseRoute : Location -> Route
parseRoute location =
    if String.isEmpty location.hash then
        Login
    else
        case parseHash route location of
            Nothing ->
                NotFound

            Just route ->
                route
