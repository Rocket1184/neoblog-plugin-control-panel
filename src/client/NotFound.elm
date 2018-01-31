module NotFound exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Navigation exposing (..)
import Misc exposing ((=>))


-- Model


type alias Model =
    { location : Location
    }


init : Location -> Model
init location =
    Model location



-- Update


type Msg
    = BackClick


type ExternalMsg
    = GoBack


update : Msg -> Model -> ( ( Model, Cmd Msg ), ExternalMsg )
update msg model =
    case msg of
        BackClick ->
            model
                => Cmd.none
                => GoBack



-- View


view : Model -> Html Msg
view model =
    div [ class "manage-notfound" ]
        [ p [] [ text "The page requested could not be found!" ]
        , p [] [ text model.location.hash ]
        , p [] [ button [ class "back", onClick BackClick ] [ text "GoBack" ] ]
        ]
