module Main exposing (..)

import Html exposing (Html, div)
import Html.Attributes exposing (class)
import Navigation exposing (Location)
import Data exposing (Session)
import Route exposing (parseRoute)
import Misc exposing ((=>))


-- Page import

import Login
import Article
import Edit
import NotFound


-- Model


type PageModel
    = Login Login.Model
    | Article Article.Model
    | Edit Edit.Model
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
    , Navigation.newUrl "#!/login"
    )


initPage : Location -> PageModel
initPage location =
    case parseRoute location of
        Route.Login ->
            Login Login.init

        Route.Articles ->
            Article Article.init

        Route.New ->
            Edit (Edit.init Edit.New "")

        Route.Edit name ->
            Edit (Edit.init Edit.Edit name)

        _ ->
            NotFound (NotFound.init location)



-- View


view : Model -> Html Msg
view model =
    div [ class "page-wrapper" ]
        [ case model.page of
            Login pageModel ->
                Html.map LoginMsg (Login.view pageModel)

            Article pageModel ->
                Html.map ArticleMsg (Article.view pageModel)

            Edit pageModel ->
                Html.map EditMsg (Edit.view pageModel)

            NotFound pageModel ->
                Html.map NotFoundMsg (NotFound.view pageModel)
        ]



-- Update


type Msg
    = UrlChange Location
    | LoginMsg Login.Msg
    | ArticleMsg Article.Msg
    | EditMsg Edit.Msg
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

                        Edit pageModel ->
                            let
                                ( modelCmdMsg, msgFromPage ) =
                                    complexSubUpdate Edit EditMsg (Edit.update session) Edit.Load pageModel
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
                    ( ( newModel, newCmdMsg ), msgFromPage ) =
                        complexSubUpdate Article ArticleMsg (Article.update session) pageMsg pageModel
                in
                    case msgFromPage of
                        Article.NewArticle ->
                            ( newModel, Navigation.newUrl "#!/new" )

                        Article.EditArticle article ->
                            ( newModel, Navigation.newUrl <| "#!/edit/" ++ article.file.base )

                        _ ->
                            ( newModel, newCmdMsg )

            ( Edit pageModel, EditMsg pageMsg ) ->
                let
                    ( ( newModel, newCmdMsg ), msgFromPage ) =
                        complexSubUpdate Edit EditMsg (Edit.update session) pageMsg pageModel
                in
                    case msgFromPage of
                        Edit.BackToList ->
                            ( newModel, Navigation.back 1 )

                        _ ->
                            ( newModel, newCmdMsg )

            ( NotFound pageModel, NotFoundMsg pageMsg ) ->
                let
                    ( ( newModel, newCmdMsg ), msgFromPage ) =
                        complexSubUpdate NotFound NotFoundMsg NotFound.update pageMsg pageModel
                in
                    case msgFromPage of
                        NotFound.GoBack ->
                            ( model, Navigation.back 1 )

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
