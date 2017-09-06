module Main exposing (..)

import Html
import Task
import Time
import Html.Attributes as A
import Html.Events as E

main =
  Html.program
    { init = init
    , subscriptions = subscriptions
    , update = update
    , view = view
    }

-- model

type Guest
  = NormalGuest String
  | CompedGuest String

type alias MenuItem =
  { name: String
  , priceInCents: Int
  }

type alias Request =
  { guest: Guest
  , item: MenuItem
  }

type OrderStatus
  = Open
  | Ordered
  | Served

type alias Order =
  { requests: List Request
  , status: OrderStatus
  }

type alias Model =
  { guests : List Guest
  , newGuestComped : Bool
  , newGuestName : String
  , newGuestSubmitted : Bool
  , orders : List Order
  , requests : List Request
  }

-- init

hamburger    = MenuItem "Hambrger"      100
cheeseburger = MenuItem "Cheeseburger"  149
fries        = MenuItem "Fries"         125
soda         = MenuItem "Soda"          199

menuItems = [ hamburger, cheeseburger, fries, soda ]

ben : Guest
ben = NormalGuest "Ben"

charlie : Guest
charlie = CompedGuest "Charlie"

guests : List Guest
guests = [ ben, charlie ]

requests : List Request
requests = [ Request ben cheeseburger, Request charlie hamburger ]

firstOrder : Order
firstOrder =
  { requests = []
  , status = Open
  }

model : Model
model = Model guests False "" False [ firstOrder ] requests

init = (model, Cmd.none)

-- subscriptions

subscriptions : Model -> Sub Msg
subscriptions model =
  Sub.none

-- update

type Msg
  = SubmitGuest 
  | AddRequest Guest MenuItem
  | NewOrder
  | NewGuestName String
  | NewGuestComped
  | DeleteGuest Guest
  | OnTime Time.Time

getTime =
  Task.perform OnTime Time.now

without predicate list =
  ( Tuple.second ( List.partition predicate list ) )

update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
  case msg of
    SubmitGuest ->
      let
        newGuestType = if model.newGuestComped then CompedGuest else NormalGuest
        newModel = { model | newGuestSubmitted = True }
        newGuest = newGuestType model.newGuestName
      in
        if validateGuest newGuest then
          ({ model |
              guests = newGuest :: model.guests,
              newGuestName = ""
          }, Cmd.none)
        else
          (newModel, Cmd.none)
    NewOrder ->
      if List.isEmpty model.requests then
        (model, Cmd.none)
      else
        let
          requests = model.requests
          newOrder =
          { requests = requests
          , status = Open
          }
        in
          ({ model |
              orders = newOrder :: model.orders,
              requests = []
          }, Cmd.none )
    NewGuestName name ->
      ({ model | newGuestName = name }, Cmd.none )
    NewGuestComped ->
      ({ model | newGuestComped = True }, Cmd.none )
    AddRequest guest menuItem ->
      ({ model | requests = Request guest menuItem :: model.requests }, Cmd.none )
    DeleteGuest guest ->
      ({ model | guests = without (\g -> g == guest) model.guests }, Cmd.none )
    OnTime time ->
      ( model, Cmd.none )


-- view

validateGuest : Guest -> Bool
validateGuest guest =
  True
  -- not ( String.isEmpty guest )

guestValidationMessage : Model -> String
guestValidationMessage model =
  let
    guestIsValid = validateGuest (NormalGuest model.newGuestName)
    untouched = not model.newGuestSubmitted
  in
    if guestIsValid || untouched then
      ""
    else
      "Guest name cannot be empty"

css : String -> Html.Html msg
css path =
  Html.node "link" [ A.rel "stylesheet", A.href path ] []

viewRequest: Request -> Html.Html Msg
viewRequest request =
  Html.li [] [
    Html.text ( compedText( request.guest ) ++ " wants a " ++ request.item.name )
  ]

viewOrder: Order -> Html.Html Msg
viewOrder order =
  Html.li [] [
    Html.ul [] (List.map viewRequest order.requests)
  ]

viewOrderRequest: Request -> Html.Html Msg
viewOrderRequest request =
  Html.li [] [
    Html.text "foo"
  ]

compedText : Guest -> String
compedText guest =
  case guest of
    CompedGuest guest ->
      guest ++ "*"
    NormalGuest guest ->
      guest

menuItemButton : Guest -> MenuItem -> Html.Html Msg
menuItemButton guest menuItem =
  Html.li [] [
    Html.button [E.onClick ( AddRequest guest menuItem)] [ Html.text ("request " ++ menuItem.name )]
  ]

viewGuest : Guest -> Html.Html Msg
viewGuest guest =
  Html.li []
    [ Html.h4 [] [ Html.text (compedText guest )]
    , Html.button [ E.onClick ( DeleteGuest guest ) ] [ Html.text " delete" ]
    , Html.ul [] (List.map (menuItemButton guest) menuItems)
    ]

view : Model -> Html.Html Msg
view model =
  let
    text s = Html.text (String.left 1 s)
  in
  Html.div []
    [ css "style.css"
    , Html.h1 [] [ text "BBB" ]
    , Html.div [ A.id "guests" ]
      [ Html.h2 [] [ Html.text "Guests" ]
      , Html.ul [] (List.map viewGuest model.guests)
      , Html.div []
        [ Html.h3 [] [ Html.text "Add Guest" ]
        , Html.p [ A.class "error" ] [ Html.text ( guestValidationMessage model ) ]
        , Html.input [ E.onInput NewGuestName, A.type_ "text", A.value model.newGuestName ] []
        , Html.input [ E.onClick NewGuestComped, A.type_ "checkbox" ] []
        , Html.button [ E.onClick SubmitGuest ] [ Html.text "submit" ]
        ]
      ]
    , Html.div [ A.id "requests" ]
      [ Html.h2 [] [ Html.text "Requests" ]
      , Html.ul [] (List.map viewRequest model.requests) ]
      , Html.button [ E.onClick NewOrder ] [ Html.text "move to new order" ]
    , Html.div [ A.id "orders" ]
      [ Html.h2 [] [ Html.text "Orders" ]
      , Html.ul [] (List.map viewOrder model.orders) ]
    ]
