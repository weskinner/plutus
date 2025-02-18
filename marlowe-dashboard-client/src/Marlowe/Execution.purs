module Marlowe.Execution where

import Prelude
import Data.Array (fromFoldable)
import Data.BigInteger (BigInteger, fromInt)
import Data.Lens (Lens', view)
import Data.Lens.Iso.Newtype (_Newtype)
import Data.Lens.Record (prop)
import Data.List (List)
import Data.Map (Map)
import Data.Map as Map
import Data.Maybe (Maybe(..))
import Data.Symbol (SProxy(..))
import Marlowe.Semantics (AccountId, Action(..), Bound(..), Case(..), ChoiceId(..), ChosenNum, Contract(..), Input, Observation, Party(..), Payment, Slot(..), SlotInterval(..), State, Timeout, Token(..), TransactionInput(..), TransactionOutput(..), ValueId, _boundValues, _minSlot, computeTransaction, emptyState, evalValue, makeEnvironment)

-- Represents a historical step in a contract's life and is what you see on a Step card that is in the past,
-- that is the State as it was before it was executed and the TransactionInput that was applied.
-- We don't bother storing the Contract because it is not needed for displaying a hostorical card but this means
-- we need to store if the step timed out. This is all (possibly premature) optimization to avoid storing the
-- contract many times as it could be quite large
type ExecutionStep
  -- FIXME: If the transaction was a timeout, we don't actually have txInput and the state should be the
  -- one before or the one after.
  -- If timeout I'll need from the contract the timeout slot
  -- For the balances is still not clear if we should use the balance before, the balance after or dont display.
  = { txInput :: TransactionInput
    , state :: State
    , timedOut :: Boolean
    }

type ExecutionState
  = { steps :: Array ExecutionStep
    , state :: State
    , contract :: Contract
    , namedActions :: Array NamedAction
    }

-- | Merge ExecutionStates preferring the left over the right
-- | steps are appended left to right and everything else is
-- | replaced with the left side values
merge :: ExecutionState -> ExecutionState -> ExecutionState
merge a b =
  { steps: a.steps <> b.steps
  , state: a.state
  , contract: a.contract
  , namedActions: a.namedActions
  }

_state :: Lens' ExecutionState State
_state = prop (SProxy :: SProxy "state")

_contract :: Lens' ExecutionState Contract
_contract = prop (SProxy :: SProxy "contract")

_steps :: Lens' ExecutionState (Array ExecutionStep)
_steps = prop (SProxy :: SProxy "steps")

_namedActions :: Lens' ExecutionState (Array NamedAction)
_namedActions = prop (SProxy :: SProxy "namedActions")

initExecution :: Slot -> Contract -> ExecutionState
initExecution currentSlot contract =
  let
    steps = mempty

    state = emptyState currentSlot

    -- FIXME: We fake the namedActions for development until we fix the semantics
    -- namedActions =
    --   [ MakeDeposit (Role "alice") (Role "bob") (Token "" "") $ fromInt 200
    --   , MakeDeposit (Role "bob") (Role "alice") (Token "" "") $ fromInt 1500
    --   , MakeChoice (ChoiceId "choice" (Role "alice"))
    --       [ Bound (fromInt 0) (fromInt 3)
    --       , Bound (fromInt 2) (fromInt 4)
    --       , Bound (fromInt 6) (fromInt 8)
    --       ]
    --       Nothing
    --   , CloseContract
    --   ]
    namedActions = extractNamedActions currentSlot state contract
  in
    { steps, state, contract, namedActions }

hasTimeout :: Contract -> Maybe Timeout
hasTimeout (When _ t _) = Just t

hasTimeout _ = Nothing

mkTx :: ExecutionState -> List Input -> TransactionInput
mkTx { state } inputs =
  let
    -- FIXME: mkTx should use the current slot taken from the current time
    currentSlot = view _minSlot state

    -- interval = SlotInterval currentSlot (currentSlot + Slot (fromInt 100)) -- FIXME: should this be minSlot minSlot? We need to think about ambiguous slot error
    -- FIXME: I Should call Semantic.timeouts and make an interval of [currentSlot, minTime - 1]
    -- Should also check that minTime - 1 is bigger than (currentSlot + 100)
    -- This should be the same function that makeEnvironment uses in extractAction
    interval = SlotInterval (Slot $ fromInt 0) (Slot $ fromInt 0)
  in
    TransactionInput { interval, inputs }

-- Evaluate a Contract based on a State and a TransactionInput and return the new ExecutionState, having added a new ExecutinStep
nextState :: ExecutionState -> TransactionInput -> ExecutionState
nextState { steps, state, contract } txInput =
  let
    currentSlot = view _minSlot state

    TransactionInput { interval: SlotInterval minSlot maxSlot } = txInput

    { txOutState, txOutContract } = case computeTransaction txInput state contract of
      (TransactionOutput { txOutState, txOutContract }) -> { txOutState, txOutContract }
      -- We should not have contracts which cause errors in the dashboard so we will just ignore error cases for now
      (Error _) -> { txOutState: state, txOutContract: contract }

    -- FIXME: Check with Pablo and/or alex:
    --        To extract the possible actions a user can take I need to know if a Case has timeout. In the previous
    --        version we were using the minSlot of the Semantic state, but after discussing with Alex we needed to
    --        use "the current slot" instead.
    --        This means that extractNamedActions now receives a slot to calculate the timeout. Inside `initExecution`
    --        it makes total sense as we use the current slot of the system. But `nextState` can be used to re-create
    --        a contract history from the TransactionInput. I had three possible values I could use:
    --          * Add a Slot paramenter to nextState and make the caller to decide what's the "current slot"
    --          * Use the minSlot of the TransactionInput slot interval
    --          * Use the maxSlot of the TransactionInput slot interval
    --        For now I'm using the maxSlot of the TransactionInput, asuming that if it didn't timeout by that time,
    --        then it didn't timeout at all. But I need to confirm this decision and see what consequences it may bring.
    namedActions = extractNamedActions maxSlot txOutState txOutContract

    timedOut = case hasTimeout contract of
      Just t -> t < currentSlot
      _ -> false
  in
    { steps: steps <> [ { txInput, state, timedOut } ]
    , state: txOutState
    , contract: txOutContract
    , namedActions
    }

-- Represents the possible buttons that can be displayed on a contract stage card
data NamedAction
  -- Equivalent to Semantics.Action(Deposit)
  -- Creates IDeposit
  = MakeDeposit AccountId Party Token BigInteger
  -- Equivalent to Semantics.Action(Choice) but has ChosenNum since it is a stateful element that stores the users choice
  -- Creates IChoice
  | MakeChoice ChoiceId (Array Bound) (Maybe ChosenNum)
  -- Equivalent to Semantics.Action(Notify) (can be applied by any user)
  -- Creates INotify
  | MakeNotify Observation
  -- An empty transaction needs to be submitted in order to trigger a change in the contract
  -- and we work out the details of what will happen when this occurs, currently we are interested
  -- in any payments that will be made and new bindings that will be evaluated
  -- Creates empty tx
  | Evaluate { payments :: Array Payment, bindings :: Map ValueId BigInteger }
  -- A special case of Evaluate where the only way the Contract can progress is to apply an empty
  -- transaction which results in the contract being closed
  -- Creates empty tx
  -- FIXME: probably add {payments:: Array } and add them to the close description
  | CloseContract

derive instance eqNamedAction :: Eq NamedAction

getActionParticipant :: NamedAction -> Maybe Party
getActionParticipant (MakeDeposit _ party _ _) = Just party

getActionParticipant (MakeChoice (ChoiceId _ party) _ _) = Just party

getActionParticipant _ = Nothing

extractNamedActions :: Slot -> State -> Contract -> Array NamedAction
extractNamedActions _ _ Close = mempty

-- a When can only progress if it has timed out or has Cases
extractNamedActions currentSlot state (When cases timeout cont)
  -- in the case of a timeout we need to provide an Evaluate action to all users to "manually" progress the contract
  | currentSlot > timeout =
    let
      minSlot = view _minSlot state

      emptyTx = TransactionInput { interval: SlotInterval minSlot minSlot, inputs: mempty }

      outputs = case computeTransaction emptyTx state cont of
        TransactionOutput { txOutPayments, txOutState } ->
          let
            oldBindings = view _boundValues state

            newBindings = view _boundValues txOutState

            bindings = Map.difference newBindings oldBindings
          in
            { payments: fromFoldable txOutPayments, bindings: bindings }
        _ -> mempty
    in
      -- FIXME: Currently we don't have a way to display Evaluate so this can be dangerous.
      --        We talked with Alex that when a contract timeouts there doesn't need to be
      --        an explicity Evaluate, the next action will take care of that for us. If the
      --        continuation of a contract is a Close, then we need to extract the `CloseContract`
      --        so someone can pay to close the contract. If the continuation is a When, then we
      --        need to extract the actions as below. In any case, I think that instead of using
      --        `computeTransaction` and returning an Evaluate we should "advance" in the continuation
      --        and recursively call extractNamedActions.
      [ Evaluate outputs ]
  -- if there are no cases then there is no action that any user can take to progress the contract
  | otherwise = cases <#> \(Case action _) -> toNamedAction action
    where
    toNamedAction (Deposit a p t v) =
      let
        minSlot = view (_minSlot <<< _Newtype) state

        -- FIXME: This should be the same interval that mkTx has
        env = makeEnvironment minSlot minSlot

        amount = evalValue env state v
      in
        MakeDeposit a p t amount

    toNamedAction (Choice cid bounds) = MakeChoice cid bounds Nothing

    toNamedAction (Notify obs) = MakeNotify obs

-- In reality other situations should never occur as contracts always reduce to When or Close
-- however someone could in theory publish a contract that starts with another Contract constructor
-- and we would want to enable moving forward with Evaluate
extractNamedActions _ _ _ = [ Evaluate mempty ]
