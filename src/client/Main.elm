module Main exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Data exposing (Session)


-- Page import

import Login
import Article


-- Model


type PageModel
    = Login Login.Model
    | Article Article.Model


type alias Model =
    { session : Session
    , page : PageModel
    }


init : ( Model, Cmd Msg )
init =
    ( { session = Session ""
      , page = Login Login.init
      }
    , Cmd.none
    )



-- View


view : Model -> Html Msg
view model =
    div [ class "page-wrapper" ]
        [ case model.page of
            Login pageModel ->
                Html.map LoginMsg (Login.view pageModel)

            Article pageModel ->
                Html.map ArticleMsg (Article.view pageModel)
        ]



-- Update


type Msg
    = LoginMsg Login.Msg
    | ArticleMsg Article.Msg


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case model.page of
        Login pageModel ->
            case msg of
                LoginMsg pageMsg ->
                    let
                        ( ( newPageModel, pageCmd ), msgFromPage ) =
                            Login.update pageMsg pageModel

                        newModel =
                            { model | page = Login newPageModel }
                    in
                        case msgFromPage of
                            Login.NoOp ->
                                ( newModel, Cmd.map LoginMsg pageCmd )

                            Login.SetToken token ->
                                let
                                    newSession =
                                        Session ("Bearer " ++ token)

                                    modelWithSession =
                                        { newModel
                                            | session = newSession
                                            , page = (Article Article.init)
                                        }
                                in
                                    update (ArticleMsg Article.FetchArticles) modelWithSession

                _ ->
                    ( model, Cmd.none )

        Article pageModel ->
            case msg of
                ArticleMsg pageMsg ->
                    let
                        ( ( newPageModel, pageCmd ), msgFromPage ) =
                            Article.update model.session pageMsg pageModel

                        newModel =
                            case msgFromPage of
                                Article.NoOp ->
                                    model

                                Article.EditArticle article ->
                                    -- { model | session = Session token }
                                    model
                    in
                        ( { newModel | page = Article newPageModel }, Cmd.map ArticleMsg pageCmd )

                _ ->
                    ( model, Cmd.none )



-- Subscriptions


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none


main : Program Never Model Msg
main =
    Html.program
        { init = init
        , view = view
        , update = update
        , subscriptions = (subscriptions)
        }
