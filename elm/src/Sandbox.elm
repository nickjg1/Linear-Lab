module Sandbox exposing (third)

{--------------------------------------- IMPORTS ---------------------------------------}

import Time as Time

import IVVL as IVVL exposing (Msg)

import GraphicSVG exposing (..)
import GraphicSVG.Widget as Widget exposing (..)
import GraphicSVG.App exposing (..)

import Browser exposing (..)
import Browser.Events as Events exposing (..)
import Browser.Dom as Dom exposing (..)

import Element as E exposing (..)
import Element exposing (Element)
import Element.Background as Background
import Element.Input as Input exposing (..)
import Element.Font as Font exposing (..)
import Element.Border as Border exposing (..)

import Task

import Html exposing (Html)

import Dict exposing (..)
import IVVL exposing (..)
import Html exposing (..) 

{------------------------------------------------------------------------------
                             _    _ _______ __  __ _      
                            | |  | |__   __|  \/  | |     
                            | |__| |  | |  | \  / | |     
                            |  __  |  | |  | |\/| | |      
                            | |  | |  | |  | |  | | |____ 
                            |_|  |_|  |_|  |_|  |_|______|
 ------------------------------------------------------------------------------}

{--------------------------------------- Final ---------------------------------------}

htmlOutput : Model -> List (Html Msg)
htmlOutput model = 
  [ E.layout 
      [ E.width E.fill, E.height E.fill
      , E.inFront (elementsMenu model)
      , E.inFront (zoomMenu model)
      ]
      ( widgetDisplay model [ E.width E.fill, E.height E.fill ] model.focusedEmbed
      )
  ]

{--------------------------------------- MENUS ---------------------------------------}

zoomMenu : Model -> Element Msg
zoomMenu model =
  E.column
    [ E.alignRight, E.alignBottom, E.moveUp 20, E.moveLeft 20 ]
    [ Input.button
        [ Border.width 1, E.width (E.px 30), E.height (E.px 30)
        , Background.color (rgb255 255 255 255)
        ]
        { onPress = Just (IVVLMsg model.focusedEmbed (IVVL.ScaleG2 1.5 1))
        , label = 
            E.el
              [ E.centerX ]
              ( E.text "+" )
        } 
    , Input.button
        [ Border.width 1, E.width (E.px 30), E.height (E.px 30)
        , Background.color (rgb255 255 255 255)
        ]
        { onPress = Just (IVVLMsg model.focusedEmbed (IVVL.ScaleG2 0.666 1))
        , label = 
            E.el
              [ E.centerX]
              ( E.text "-" )
        } 
    ]

elementsMenu : Model -> Element Msg
elementsMenu model =
  let
    visuals = Dict.toList model.visualElements
    targetedVisuals = 
      List.filter (\((e, _, _), _) -> (e == model.focusedEmbed)) visuals

    currentLibModel = getVisualModel model.focusedEmbed model.ivvlDict
    currentGrid = 
      case (Dict.get 1 currentLibModel.grids) of
        Nothing -> defaultGrid2D
        Just g -> g

    convertToElement ( veIndex, ve ) =
      case ve of
        Vector vID _ _ -> 
          let
            vector = 
              case Dict.get vID currentGrid.vectorObjects of
                Nothing -> defaultVisVector2D
                Just vv -> vv
          in
            vectorElement model veIndex vector ve
        VectorSum vID _ _ -> 
          let
            vector =
              case Dict.get vID currentGrid.vectorObjects of
                Nothing -> defaultVisVector2D
                Just vv -> vv
          in
            vectorSumElement model veIndex vector ve

    listOfElements = List.map convertToElement targetedVisuals
    
  in
    E.column
      [ E.width (E.fill |> maximum (round (toFloat model.width / 5))), E.height (E.fill)
      , E.alignLeft, E.scrollbars, Background.color (E.rgb 0.7 0.5 1) 
      ]
      ( E.el
          [ Font.size 40, E.centerX, paddingXY 0 20 ]
          ( E.text "Elements" )
        :: 
        listOfElements
        ++ 
        [creationMenu model]
      ) 

{--------------------------------------- SUB-MENUS ---------------------------------------}

creationMenu : Model -> Element Msg
creationMenu model =
  E.column
    [ E.width E.fill, E.paddingXY 0 10 ]
    ( let
        optionButton = 
          (\title message ->
            E.el
              [ E.width E.fill ]
              ( Input.button
                  [ E.width (px 250), E.centerX, Border.width 1
                  , E.focused [ Background.color (E.rgb255 150 80 255) ]
                  ]
                  { onPress = message
                  , label = 
                      E.el
                        [ E.centerX, paddingXY 0 5 ]
                        ( E.text title )
                  }
              )
          )

        myVector =
          newVV2
              |> endTypeVV2 Directional
      in
        List.map2 
          optionButton 
          ["Add Vector Element", "Add VectorSum Element"] 
          [ Just (AddElement VectorType (IVVLMsg model.focusedEmbed (IVVL.AddVVectorG2 myVector 1)))
          , Just (AddElement VectorSumType (IVVLMsg model.focusedEmbed (IVVL.AddVVectorG2 myVector 1))) 
          ]
    )

{--------------------------------------- ELEMENTS ---------------------------------------}

vectorElement : Model -> VisualElementIndex -> VisVector2D -> VisualElement -> Element Msg
vectorElement model (eID, gID, veID) vv2 ve = 
  case ve of
    Vector vID (iX, iY) pass ->
      let
        veIndex = (eID, gID, veID)
        passClr =
          if pass
            then rgb255 0 0 0
            else rgb255 255 0 0

        visualElement = (Vector vID (iX, iY) pass)
      in
        ( E.row
          [ E.centerX, Background.color (E.rgb 1 0.5 1), E.spacingXY 10 0, E.paddingXY 5 0 ]
          [ E.el
              []
              ( Input.button
                  ( [ E.width (px 20), E.height (px 20)
                    , Background.color (E.rgb255 238 238 238)
                    , E.focused [ Background.color (E.rgb255 238 23 238) ]
                    ]
                  ) 
                  { onPress = Just (RemoveElement veIndex (IVVLMsg model.focusedEmbed (IVVL.RemoveVVectorG2 vID 1)))
                  , label = E.el [ E.centerX, E.centerY ] (E.text "X")
                  } 
              )
          , E.el
              [ Font.size 24 ]
              ( E.text "vector" )
          , E.el
              [ Font.size 32 ]
              ( E.text (String.fromInt veID) )
          , E.el
              [ ]
              ( E.text "=" )
          , E.el
              [ E.height E.fill, E.centerY, Font.size 70, Font.hairline ]
              ( E.text "[" )
          , E.column
              [ ]
              [ E.el
                  [ E.paddingXY 0 2 ]
                  ( Input.text
                      [ E.width (E.px 45), E.height (E.px 45), Font.center, Font.size 13, Font.center, Font.color passClr ] 
                      { onChange = \value -> ParseVectorInput veIndex vID X value
                      , text = iX
                      , placeholder = Just (Input.placeholder [ E.centerX ] ( E.el [ E.centerX, E.centerY, Font.size 16 ] ( E.text "X" ) ) )
                      , label = Input.labelHidden "An X vector input"
                      }
                  )
              , E.el
                  [ E.paddingXY 0 2 ]
                  ( Input.text
                      [ E.width (E.px 45), E.height (E.px 45), Font.center, Font.size 13, Font.center, Font.color passClr ]
                      { onChange = \value -> ParseVectorInput veIndex vID Y value
                      , text = iY
                      , placeholder = Just (Input.placeholder [ E.centerX ] ( E.el [ E.centerX, E.centerY, Font.size 16 ] ( E.text "X" ) ) )
                      , label = Input.labelHidden "A Y vector input"
                      }
                  )
              ]
          , E.el
              [ E.height E.fill, E.centerY, Font.size 70, Font.hairline ]
              ( E.text "]")
          ]
        )
    _ -> ( E.text "broken" )

vectorSumElement : Model -> VisualElementIndex -> VisVector2D -> VisualElement -> Element Msg
vectorSumElement model (eID, gID, veID) vv2 ve = 
  case ve of
    VectorSum vID (iV1, iV2) pass ->
      let
        veIndex = (eID, gID, veID)
        passClr =
          if pass
            then rgb255 0 0 0
            else rgb255 255 0 0

        visualElement = (Vector vID (iV1, iV2) pass)
        theModel = getVisualModel model.focusedEmbed model.ivvlDict
        theGrid = 
          case (Dict.get 1 theModel.grids) of
            Just x -> x
            _ -> defaultGrid2D

        theVector =
          case (Dict.get vID theGrid.vectorObjects) of
            Just x -> x
            _ -> defaultVisVector2D
      in
        ( E.row
          [ E.centerX, Background.color (E.rgb 1 0.5 1), E.spacingXY 10 0, E.paddingXY 5 0 ]
          [ E.el
              [ ]
              ( Input.button
                  ( [ E.width (px 20), E.height (px 20)
                    , Background.color (E.rgb255 238 238 238)
                    , E.focused [ Background.color (E.rgb255 238 23 238) ]
                    ]
                  ) 
                  { onPress = Just (RemoveElement veIndex (IVVLMsg model.focusedEmbed (IVVL.RemoveVVectorG2 vID 1)))
                  , label = E.el [ E.centerX, E.centerY ] (E.text "X")
                  } 
              )
          , E.el
              [ Font.size 18 ]
              ( E.text "vectorSum" )
          , E.el
              [ Font.size 24 ]
              ( E.text (String.fromInt veID) )
          , E.el
                  [ ]
                  ( Input.text
                      [ E.width (E.px 35), E.height (E.px 35), Font.center, Font.size 13, Font.center, Font.color passClr ] 
                      { onChange = \value -> ParseVectorSumInput veIndex vID X value
                      , text = iV1
                      , placeholder = Just (Input.placeholder [ E.centerX ] ( E.el [ E.centerX, E.centerY, Font.size 16 ] ( E.text "V#" ) ) )
                      , label = Input.labelHidden "A vectorID input"
                      }
                  )
          , E.el
              [ ]
              ( E.text "+" )
          , E.el
                  [ E.paddingXY 0 2 ]
                  ( Input.text
                      [ E.width (E.px 35), E.height (E.px 35), Font.center, Font.size 13, Font.center, Font.color passClr ] 
                      { onChange = \value -> ParseVectorSumInput veIndex vID Y value
                      , text = iV2
                      , placeholder = Just (Input.placeholder [ E.centerX ] ( E.el [ E.centerX, E.centerY, Font.size 16 ] ( E.text "V#" ) ) )
                      , label = Input.labelHidden "A vectorID input"
                      }
                  )
          , E.el
              [ ]
              ( E.text "=" )
          , E.el
              [ E.height E.fill, E.centerY, Font.size 70, Font.hairline, E.moveUp 8 ]
              ( E.text "[" )
          , E.column
              [ E.spacingXY 0 10 ]
              [ E.el
                  [ Font.size 18, E.moveUp 4 ]
                  ( E.text (String.fromFloat (firstV2 theVector.vector)) )
              , E.el
                  [ Font.size 18 ]
                  ( E.text (String.fromFloat (secondV2 theVector.vector)) )
              ]
          , E.el
              [ E.height E.fill, E.centerY, Font.size 70, Font.hairline, E.moveUp 8 ]
              ( E.text "]")
          ]
        )
    _ -> ( E.text "broken" )

{--------------------------------------- WIDGET DISPLAY ---------------------------------------}

widgetDisplay : Model -> List (E.Attribute Msg) -> String -> Element Msg
widgetDisplay model style widgetId = 
  E.el 
    style
    <| E.html (Widget.view (getWidgetModel widgetId model.widgetDict) (renderIVVL (getVisualModel widgetId model.ivvlDict) widgetId) )

{--------------------------------------- MESSAGES ---------------------------------------}

type XY = X | Y

type alias VisualElementIndex = (String, Int, Int) -- EmbedId, GridId, VisualElementId
type VisualElement = Vector Int (String, String) Bool -- VectorId, VectorInputString, Pass
                   | VectorSum Int (String, String) Bool -- VectorId, VectorInputString, Pass

type ElementType = VectorType
                 | VectorSumType

--type VectorElements = Vector
--                    | VectorSum

type Msg = Tick Time.Posix
         | WindowResize Int Int
         | Blank

         | AddElement ElementType Msg
         | RemoveElement VisualElementIndex Msg
         | ParseVectorInput VisualElementIndex Int XY String
         | ParseVectorSumInput VisualElementIndex Int XY String

         | UpdateContinuous

         | IVVLMsg String IVVL.Msg
         | IVVLMoveMsg String (Float, Float)

         | WidgetMsg String (Widget.Msg)
    
update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
  case msg of
    WindowResize width height ->
      let
        newWidgetDict = Dict.map (\k _ -> Widget.init (toFloat width) (toFloat height) k) model.ivvlDict
        newWidgetCommands = (List.map (\(k,v) -> Cmd.map (WidgetMsg k) (Tuple.second v)) (Dict.toList newWidgetDict))
      in
        ( { model | width = width, height = height, widgetDict = newWidgetDict }, Cmd.batch newWidgetCommands)
    Tick _ -> ( model, Task.perform (\_-> UpdateContinuous) Time.now )

    AddElement elementType message ->
      let
        gID = 1
        eID = model.focusedEmbed
        currentVisual = getVisualModel eID model.ivvlDict
        currentGrid = 
          case Dict.get gID currentVisual.grids of
            Nothing -> defaultGrid2D
            Just a -> a

        newModel = 
          case message of
            IVVLMsg _ (IVVL.AddVVectorG2 _ _) -> 
              let
                nextVID = IVVL.getNextVectorObjectKey currentGrid.vectorObjects
                newEKey = getNextVisualElementIndex model.visualElements model.focusedEmbed gID

                ve = 
                  case elementType of
                    VectorType -> Vector nextVID ("0", "0") True
                    VectorSumType -> VectorSum nextVID (Debug.toString nextVID, "") False

                newVisualElements = Dict.insert newEKey ve model.visualElements
              in
                { model | visualElements = newVisualElements }
            _ -> model
      in
        ( newModel, Task.perform (\_-> message) Time.now )

    RemoveElement (eID, gID, veID) message ->
      let
        newModel =
          case message of
            IVVLMsg _ (IVVL.RemoveVVectorG2 _ _) ->
              let
                vID = 
                  case (Dict.get (eID, gID, veID) model.visualElements) of
                    Just (Vector vID2 _ _) -> vID2
                    Just (VectorSum vID2 _ _) -> vID2
                    Nothing -> 0
                removedVisualElements = Dict.remove (eID, gID, veID) model.visualElements

                filteredVisualElements =
                  Dict.filter
                    (\_ ve ->
                      case ve of
                        Vector vevID _ _ ->
                          if (vevID > vID)
                            then True
                            else False
                        VectorSum vevID _ _ ->
                          if (vevID > vID)
                            then True
                            else False
                        --_ -> False
                    ) removedVisualElements

                shiftedVisualElements =
                  Dict.fromList
                    ( List.map 
                        (\((a,b,c), ve) ->
                          case ve of
                            Vector vevID d e ->
                              ((a,b,(c - 1)), (Vector (vevID - 1) d e))
                            VectorSum vevID d e -> ((a,b, (c - 1)), (VectorSum (vevID - 1) d e) )
                        )
                        (Dict.toList filteredVisualElements)
                    )

                updatedVisualElements = Dict.union shiftedVisualElements removedVisualElements

                finalVisualElements = 
                  if (Dict.size model.visualElements == Dict.size removedVisualElements)
                    then model.visualElements
                    else Dict.remove (eID, gID, (Dict.size model.visualElements)) updatedVisualElements

                x = Debug.log "5" finalVisualElements
              in
                { model | visualElements = finalVisualElements }
            _ -> model
      in
        ( newModel, Task.perform (\_-> message) Time.now )

    ParseVectorInput (eID, gID, veID) vID xy input ->
      let
        veIndex = (eID, gID, veID)
        vElement = 
          case (Dict.get veIndex model.visualElements) of
            Nothing -> Vector vID ("0", "0") True
            Just a -> a

        parseInputXY = String.toFloat input
        parseInputOther = 
          case xy of
            X -> 
              (\ve ->
                case ve of 
                  Vector _ (_, input2) _ -> (String.toFloat input2) 
                  _ -> Nothing
              ) vElement
            Y -> 
              (\ve ->
                case ve of
                  Vector _ (input1, _) _ -> (String.toFloat input1)
                  _ -> Nothing
              ) vElement

        invisibilityCheck =
          case ( Dict.get veIndex model.visualElements ) of
            Nothing -> Dict.insert veIndex (Vector vID ("0","0") True) model.visualElements
            Just _ -> model.visualElements

        updatedVectorInputs = 
          Dict.update 
          veIndex
          ( case xy of
              X -> 
                Maybe.map
                  (\ve ->
                    case ve of 
                      Vector v (_, y) p -> Vector v (input,y) p
                      _ -> Vector -1 ("err", "err") False
                  ) 
              
              Y -> 
                Maybe.map 
                  (\ve ->
                    case ve of 
                      Vector v (x, _) p -> Vector v (x,input) p
                      _ -> Vector -1 ("err", "err") False
                  ) 
          )
          invisibilityCheck

        finalVectorInputs = 
          Dict.update 
          veIndex
          ( if ( parseInputXY == Nothing || parseInputOther == Nothing )
              then 
                Maybe.map 
                  (\ve ->
                    case ve of
                      Vector v (x,y) _ -> Vector v (x,y) False
                      _ -> Vector -1 ("err", "err") False
                  )
              else 
                Maybe.map
                (\ve ->
                  case ve of
                    Vector v (x,y) _ -> Vector v (x,y) True
                    _ -> Vector -1 ("err", "err") False
                )
          )
          updatedVectorInputs

        theModel = getVisualModel eID model.ivvlDict
        theGrid = 
          case (Dict.get gID (theModel.grids) ) of
            Nothing -> defaultGrid2D
            Just x -> x

        currentVisVectorValue =
          case (Dict.get vID (theGrid.vectorObjects) ) of
            Nothing -> defaultVisVector2D
            Just x -> x

        newVectorValue =
          if ( parseInputXY == Nothing || parseInputOther == Nothing )
            then currentVisVectorValue.vector
            else 
              case xy of
                X -> (Maybe.withDefault 0 parseInputXY, Maybe.withDefault 0 parseInputOther)
                Y -> (Maybe.withDefault 0 parseInputOther, Maybe.withDefault 0 parseInputXY)        

        newVisVectorValue = { currentVisVectorValue | vector = newVectorValue }
        newVectorObjects = Dict.insert vID newVisVectorValue theGrid.vectorObjects
        newGrid = { theGrid | vectorObjects = newVectorObjects }
        newGridDict = Dict.insert gID newGrid theModel.grids
        newIVVLModel = { theModel | grids = newGridDict }
        newIVVLModelDict = Dict.insert eID newIVVLModel model.ivvlDict
      in
        ( { model | ivvlDict = newIVVLModelDict, visualElements = finalVectorInputs }, Cmd.none )

    ParseVectorSumInput (eID, gID, veID) vID xy input ->
      let
        veIndex = (eID, gID, veID)
        vElement = 
          case (Dict.get veIndex model.visualElements) of
            Nothing -> VectorSum vID ("", "") False
            Just a -> a

        parseInputXY = String.toInt input
        parseInputOther = 
          case xy of
            X -> 
              (\ve ->
                case ve of 
                  VectorSum _ (_, input2) _ -> (String.toInt input2) 
                  _ -> Nothing
              ) vElement
            Y -> 
              (\ve ->
                case ve of
                  VectorSum _ (input1, _) _ -> (String.toInt input1)
                  _ -> Nothing
              ) vElement

        testInputXY = 
          case parseInputXY of
            Nothing -> Nothing
            Just value -> 
              case (Dict.get (eID, gID, value) model.visualElements) of
                Just (Vector vID2 _ _) -> Just vID2
                Just (VectorSum vID2 _ _) ->
                  if (vID2 == veID)
                    then Nothing
                    else Just vID2
                _ -> Nothing
        testInputOther =
          case parseInputOther of
            Nothing -> Nothing
            Just value ->
              case (Dict.get (eID, gID, value) model.visualElements) of
                Just (Vector vID2 _ _) -> 
                  if (vID2 == veID)
                    then Nothing
                    else Just vID2
                _ -> Nothing

        invisibilityCheck =
          case ( Dict.get veIndex model.visualElements ) of
            Nothing -> Dict.insert veIndex (VectorSum vID ("", "") False) model.visualElements
            Just _ -> model.visualElements

        updatedVectorInputs = 
          Dict.update 
          veIndex
          ( case xy of
              X -> 
                Maybe.map
                  (\ve ->
                    case ve of 
                      VectorSum v (_, y) p -> VectorSum v (input,y) p
                      _ -> VectorSum -1 ("err", "err") False
                  ) 
              
              Y -> 
                Maybe.map 
                  (\ve ->
                    case ve of 
                      VectorSum v (x, _) p -> VectorSum v (x,input) p
                      _ -> VectorSum -1 ("err", "err") False
                  ) 
          )
          invisibilityCheck

        finalVectorInputs = 
          Dict.update 
          veIndex
          ( if ( testInputXY == Nothing || testInputOther == Nothing )
              then 
                Maybe.map 
                  (\ve ->
                    case ve of
                      VectorSum v (x,y) _ -> VectorSum v (x,y) False
                      _ -> VectorSum -1 ("err", "err") False
                  )
              else 
                Maybe.map
                (\ve ->
                  case ve of
                    VectorSum v (x,y) _ -> VectorSum v (x,y) True
                    _ -> VectorSum -1 ("err", "err") False
                )
          )
          updatedVectorInputs

        theModel = getVisualModel eID model.ivvlDict
        theGrid = 
          case (Dict.get gID (theModel.grids) ) of
            Nothing -> defaultGrid2D
            Just x -> x

        currentVisVectorValue =
          case (Dict.get vID (theGrid.vectorObjects) ) of
            Nothing -> defaultVisVector2D
            Just x -> x


        accessVector =
          (\vID2 ->
            case (Dict.get vID2 theGrid.vectorObjects) of
              Just v -> v
              Nothing -> defaultVisVector2D
          )

        vectorXY = 
          case (Maybe.map accessVector testInputXY) of
            Nothing -> defaultVisVector2D
            Just y -> y
        vectorOther = 
          case (Maybe.map accessVector testInputOther) of
            Nothing -> defaultVisVector2D
            Just y -> y


        newVectorValue =
          if ( parseInputXY == Nothing || parseInputOther == Nothing )
            then currentVisVectorValue.vector
            else addV2 vectorOther.vector vectorXY.vector

        newVisVectorValue = { currentVisVectorValue | vector = newVectorValue }
        newVectorObjects = Dict.insert vID newVisVectorValue theGrid.vectorObjects
        newGrid = { theGrid | vectorObjects = newVectorObjects }
        newGridDict = Dict.insert gID newGrid theModel.grids
        newIVVLModel = { theModel | grids = newGridDict }
        newIVVLModelDict = Dict.insert eID newIVVLModel model.ivvlDict
      in
        ( { model | ivvlDict = newIVVLModelDict, visualElements = finalVectorInputs }, Cmd.none )

    UpdateContinuous ->
      let
        vectorSumsToTest = 
          Dict.filter 
            (\(eID, gID, _) value ->
              if (eID == model.focusedEmbed && gID == 1)
                then
                  case value of
                    VectorSum _ _ _ -> True
                    _ -> False
                else False
            )
            model.visualElements

        --ParseVectorSumInput (eID, gID, veID) vID xy input
        vectorSumsList = Dict.toList vectorSumsToTest
        firstParam = List.map Tuple.first vectorSumsList
        secondParam = 
          List.map (\(_,_,z) -> z) firstParam
        
        thirdParam = List.repeat (List.length firstParam) X

        fourthParam = 
          List.map 
            (\key -> 
              case (Dict.get key model.visualElements) of
                Just (VectorSum _ (a, b) _) -> a
                _ -> "err"
            )
            firstParam

        listOfMessages = List.map4 (ParseVectorSumInput) firstParam secondParam thirdParam fourthParam
        finalBatch = List.map ( \message -> Task.perform (\_-> message) Time.now ) listOfMessages

      in 
        ( model, Cmd.batch finalBatch )

    IVVLMsg k messageForParent ->
      let
        originalDict = model.ivvlDict
        updatedDict = Dict.update k ( Maybe.map (\value -> Tuple.first (IVVL.updateLibModel messageForParent value)) ) originalDict 
      in
        ( { model | ivvlDict = updatedDict }, Cmd.none)
    
    IVVLMoveMsg k (x, y) -> 
      let
        originalDict = model.ivvlDict
        updatedDict = Dict.update k (Maybe.map (\value -> Tuple.first (IVVL.updateLibModel (IVVL.HoldMove (x, y)) value))) originalDict
      in
        ( { model | ivvlDict = updatedDict }, Cmd.none )

    WidgetMsg k wMsg -> 
      let
        (newWState, wCmd) = Widget.update wMsg (getWidgetModel k model.widgetDict)

        newWidgetModel = Dict.update k (Maybe.map (\_ -> (newWState, wCmd))) model.widgetDict
      in
        ( { model | widgetDict = newWidgetModel}, Cmd.map (WidgetMsg k) wCmd)

    Blank -> ( model, Cmd.none )
    
{--------------------------------------- HELPERS ---------------------------------------}

renderIVVL : IVVL.LibModel -> String -> List (Shape Msg)
renderIVVL model k = 
  [ IVVL.renderLibModel model (IVVLMoveMsg k) (IVVLMsg k (ReleaseMove)) ]

getNextVisualElementIndex : Dict VisualElementIndex a -> String -> Int -> VisualElementIndex --Create next visual element index given the embedId and gridId
getNextVisualElementIndex theDict embedId gridId =
  let
    filteredDict = 
      Dict.filter 
        (\(eId, gId, _) _ -> eId == embedId && gId == gridId)
        theDict

    maxKeys =
      case (List.maximum (List.map third (Dict.keys filteredDict))) of
        Nothing -> 0
        Just x -> x

  in
    (embedId, gridId, maxKeys+1)

third : (a, b, c) -> c
third (a, b, c) = c

failureWidget : (Widget.Model, Cmd Widget.Msg)
failureWidget = Widget.init 150 150 "failure"

getWidgetModel : comparable -> Dict comparable (Widget.Model, Cmd Widget.Msg) -> Widget.Model
getWidgetModel index dict =
  let
    maybe = Dict.get index dict
    final = 
      case maybe of
          Just m -> m
          Nothing -> failureWidget
  in
    Tuple.first final

getVisualModel : comparable -> Dict comparable (IVVL.LibModel) -> IVVL.LibModel
getVisualModel index dict =
  let
    maybe = Dict.get index dict
    final =
      case maybe of
        Just m -> m
        Nothing -> IVVL.defaultLibModel
  in
    final

{--------------------------------------- MODEL ---------------------------------------}

type alias Model =
  { width : Int
  , height : Int 
  , widgetDict : Dict String (Widget.Model, Cmd Widget.Msg) 
  , ivvlDict : Dict String (IVVL.LibModel)

  , visualElements : Dict VisualElementIndex VisualElement

  , focusedEmbed : String
  }
    
initialModel : (Model, Cmd Msg)
initialModel =
  let
    preset = IVVL.defaultLibModel
    preset2 = { preset | grids = Dict.insert 1 
                                 ( newG2
                                    |> IVVL.addVVectorG2 
                                      ( newVV2
                                       |> setVV2 (1, 1)
                                       |> endTypeVV2 Directional
                                      ) 
                                    
                                 )
                                 preset.grids
              }

    preVModel = 
      Dict.fromList [ ("embed1", preset2)
                    ]

    visualWidgets = Dict.fromList [ ("embed1", Widget.init 1920 1080 "embed1") ]

    model =  
      { width = 1920
      , height =  1080
      , widgetDict = visualWidgets
      , ivvlDict = preVModel
      , visualElements = Dict.fromList [(("embed1", 1, 1), Vector 1 ("1", "1") True)]
      , focusedEmbed = "embed1"
      }

    widgetCommands = (List.map (\(k,v) -> Cmd.map (WidgetMsg k) (Tuple.second v)) (Dict.toList visualWidgets))
    viewPortCommand = Task.perform ( \ vp -> WindowResize (round vp.viewport.width) (round vp.viewport.height)) Dom.getViewport
    finalCmd = Cmd.batch (widgetCommands ++ [viewPortCommand])
  in
    ( model, finalCmd )

{--------------------------------------- BOILERPLATE ---------------------------------------}  

view : Model -> { title : String, body : List (Html Msg) } 
view model =
  { title = "Sandbox"
  , body = htmlOutput model
  }   

main : Program () Model Msg
main =
  Browser.document
    { init = \ _ -> initialModel
    , view = view
    , update = update
    , subscriptions = 
        \ _ -> 
          Sub.batch 
            [ Events.onResize WindowResize
            , Events.onAnimationFrame Tick
            ]
    }