{-# LANGUAGE DataKinds           #-}
{-# LANGUAGE FlexibleContexts    #-}
{-# LANGUAGE LambdaCase          #-}
{-# LANGUAGE MonoLocalBinds      #-}
{-# LANGUAGE OverloadedStrings   #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE TemplateHaskell     #-}
{-# LANGUAGE TypeApplications    #-}
{-# OPTIONS_GHC -fno-strictness  #-}
{-# OPTIONS_GHC -fno-ignore-interface-pragmas #-}
{-# OPTIONS -fplugin-opt PlutusTx.Plugin:debug-context #-}
module Spec.Governance(tests, doVoting) where

import           Test.Tasty                  (TestTree, testGroup)
import qualified Test.Tasty.HUnit            as HUnit

import           Data.Foldable               (traverse_)

import           Spec.Lib                    as Lib

import qualified Ledger
import qualified Ledger.Typed.Scripts        as Scripts
import qualified Wallet.Emulator             as EM

import           Plutus.Contract.Test
-- import qualified Plutus.Contract.StateMachine as SM
import qualified Plutus.Contracts.Governance as Gov
import           Plutus.Trace.Emulator       (EmulatorTrace)
import qualified Plutus.Trace.Emulator       as Trace
import qualified PlutusTx                    as PlutusTx
import           PlutusTx.Prelude            (ByteString)

tests :: TestTree
tests =
    testGroup "governance tests"
    [ checkPredicate "vote all in favor - SUCCESS"
        (assertNoFailedTransactions)
        (doVoting 10 0 1)

    , checkPredicate "vote all againts - SUCCESS"
        (assertNoFailedTransactions)
        (doVoting 0 10 1)

    , checkPredicate "vote 50/50 - SUCCESS"
        (assertNoFailedTransactions)
        (doVoting 5 5 1)

    , Lib.goldenPir "test/Spec/governance.pir" $$(PlutusTx.compile [|| Gov.mkValidator ||])
    , HUnit.testCase "script size is reasonable" (Lib.reasonable (Scripts.validatorScript $ Gov.scriptInstance params) 25000)
    ]

numberOfHolders :: Integer
numberOfHolders = 10

-- | A governance contract that requires 6 votes out of 10
params :: Gov.Params
params = Gov.Params holders 6 "TestLaw" where
    holders = Ledger.pubKeyHash . EM.walletPubKey . EM.Wallet <$> [1..numberOfHolders]

lawv1, lawv2 :: ByteString
lawv1 = "Law v1"
lawv2 = "Law v2"

doVoting :: Int -> Int -> Integer -> EmulatorTrace ()
doVoting ayes nays rounds = do
    let activate w = Trace.activateContractWallet (EM.Wallet w) (Gov.contract @Gov.GovError params)
    handles <- traverse activate [1..numberOfHolders]
    let handle1 = handles !! 0
    let handle2 = handles !! 1
    _ <- Trace.callEndpoint @"new-law" handle1 lawv1
    _ <- Trace.waitNSlots 10
    let votingRound = do
            Trace.callEndpoint @"propose-change" handle2 Gov.Proposal{ Gov.newLaw = lawv2, Gov.votingDeadline = 20 }
            _ <- Trace.waitNSlots 1
            traverse_ (\hdl -> Trace.callEndpoint @"add-vote" hdl True  >> Trace.waitNSlots 1) (take ayes handles)
            traverse_ (\hdl -> Trace.callEndpoint @"add-vote" hdl False >> Trace.waitNSlots 1) (take nays $ drop ayes handles)

            Trace.callEndpoint @"finish-voting" handle1 ()
            Trace.waitNSlots 1

    traverse_ (\_ -> votingRound) [1..rounds]