module Main exposing (..)

import Html exposing (Html, div)
import Html.Attributes exposing (class)
import Navigation exposing (Location)
import UrlParser exposing (parseHash, s, (</>), string)
import Data exposing (Session)
import Misc exposing ((=>))


-- Page import

import Login
import Article
import NotFound


-- Model


type PageModel
    = Login Login.Model
    | Article Article.Model
    | NotFound NotFound.Model


type alias Model =
    { session : Session
    , page : PageModel
    }


init : Location -> ( Model, Cmd Msg )
init location =
    ( { session = Session ""
      , page = initPage location
      }
    , Cmd.none
    )


initPage : Location -> PageModel
initPage location =
    case parseHash (s "!" </> string) location of
        Nothing ->
            Login Login.init

        Just "login" ->
            Login Login.init

        Just "articles" ->
            Article Article.init

        _ ->
            NotFound (NotFound.init location)


view : Model -> Html Msg
view model =
    div [ class "page-wrapper" ]
        [ case model.page of
            Login pageModel ->
                Html.map LoginMsg (Login.view pageModel)

            Article pageModel ->
                Html.map ArticleMsg (Article.view pageModel)

            NotFound pageModel ->
                Html.map NotFoundMsg (NotFound.view pageModel)
        ]



-- Update


type Msg
    = UrlChange Location
    | LoginMsg Login.Msg
    | ArticleMsg Article.Msg
    | NotFoundMsg NotFound.Msg


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    let
        page =
            model.page

        session =
            model.session

        simpleSubUpdate toModel toMsg subUpdate subMsg subModel =
            let
                ( newModel, newCmd ) =
                    subUpdate subMsg subModel
            in
                { model | page = toModel newModel }
                    => Cmd.map toMsg newCmd

        complexSubUpdate toModel toMsg subUpdate subMsg subModel =
            let
                ( ( newModel, newCmd ), msgFromPage ) =
                    subUpdate subMsg subModel
            in
                { model | page = toModel newModel }
                    => Cmd.map toMsg newCmd
                    => msgFromPage
    in
        case ( page, msg ) of
            ( _, UrlChange location ) ->
                let
                    page =
                        initPage location
                in
                    case page of
                        Article pageModel ->
                            let
                                ( modelCmdMsg, msgFromPage ) =
                                    complexSubUpdate Article ArticleMsg (Article.update session) Article.FetchArticles pageModel
                            in
                                modelCmdMsg

                        _ ->
                            { model | page = page } => Cmd.none

            ( Login pageModel, LoginMsg pageMsg ) ->
                let
                    ( ( newModel, newCmdMsg ), msgFromPage ) =
                        complexSubUpdate Login LoginMsg Login.update pageMsg pageModel
                in
                    case msgFromPage of
                        Login.SetToken token ->
                            let
                                modelWithSession =
                                    { newModel | session = Session ("Bearer " ++ token) }

                                locationCmd =
                                    Navigation.newUrl "#!/articles"
                            in
                                ( modelWithSession, locationCmd )

                        _ ->
                            ( newModel, newCmdMsg )

            ( Article pageModel, ArticleMsg pageMsg ) ->
                let
                    ( modelCmdMsg, msgFromPage ) =
                        complexSubUpdate Article ArticleMsg (Article.update session) pageMsg pageModel
                in
                    modelCmdMsg

            ( NotFound pageModel, NotFoundMsg pageMsg ) ->
                let
                    ( ( newModel, newCmdMsg ), msgFromPage ) =
                        complexSubUpdate NotFound NotFoundMsg NotFound.update pageMsg pageModel
                in
                    case msgFromPage of
                        NotFound.GoBack ->
                            let
                                locationCmd =
                                    Navigation.back 1
                            in
                                ( model, locationCmd )

            _ ->
                ( model, Cmd.none )



-- Subscriptions


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none


main : Program Never Model Msg
main =
    Navigation.program UrlChange
        { init = init
        , view = view
        , update = update
        , subscriptions = (subscriptions)
        }
