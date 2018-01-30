module Request exposing (..)

import Json.Decode
import Http
import Json.Decode


request : String -> String -> String -> Http.Body -> Json.Decode.Decoder a -> Http.Request a
request method url token body decoder =
    Http.request
        { method = method
        , url = url
        , headers = [ Http.header "Authorization" token ]
        , expect = Http.expectJson decoder
        , body = body
        , timeout = Nothing
        , withCredentials = False
        }


get : String -> String -> Json.Decode.Decoder a -> Http.Request a
get url token decoder =
    request "GET" url token Http.emptyBody decoder


post : String -> String -> Http.Body -> Json.Decode.Decoder a -> Http.Request a
post url token body decoder =
    request "POST" url token body decoder


put : String -> String -> Http.Body -> Json.Decode.Decoder a -> Http.Request a
put url token body decoder =
    request "PUT" url token body decoder


delete : String -> String -> Json.Decode.Decoder a -> Http.Request a
delete url token decoder =
    request "DELETE" url token Http.emptyBody decoder
