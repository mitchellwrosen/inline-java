{-# LANGUAGE DataKinds #-}
{-# LANGUAGE QuasiQuotes #-}
{-# LANGUAGE ScopedTypeVariables #-}
-- Test that inline-java produces code without warnings.
{-# OPTIONS_GHC -Wall -Werror #-}

module Language.Java.InlineSpec(spec) where

import Data.Int
import Foreign.JNI.Types (JObject)
import Language.Java
import Language.Java.Inline
import Test.Hspec

type ObjectClass = 'Class "java.lang.Object"

type JJObject = JObject

spec :: Spec
spec = do
    describe "Java quasiquoter" $ do
      it "Evaluates simple expressions" $ do
        ([java| 1 + 1 |] >>= reify) `shouldReturn` (2 :: Int32)

      it "Evaluates simple blocks" $ do
        ([java| {
             int x = 1;
             int y = 2;
             return x + y;
           } |] >>= reify) `shouldReturn` (3 :: Int32)

      it "Supports antiquotation variables" $ do
        let x = 1 :: Int32
        ([java| $x + 1 |] >>= reify) `shouldReturn` (2 :: Int32)

      describe "Type synonyms" $ do
        it "Supports top-level type synonym'ed antiquotation variables" $ do
          obj <- [java| new Object() {} |]
          let obj1 = obj :: JObject
          _ :: JObject <- [java| $obj1 |]
          return ()

        it "Supports inner type synonym'ed antiquotation variables" $ do
          obj <- [java| new Object() {} |]
          let obj1 = obj :: J ObjectClass
          _ :: J ObjectClass <- [java| $obj1 |]
          return ()

        it "Supports chained type synonym'ed antiquotation variables" $ do
          obj <- [java| new Object() {} |]
          let obj1 = obj :: JJObject
          _ :: JJObject <- [java| $obj1 |]
          return ()

      it "Supports multiple antiquotation variables" $ do
        let foo = 1 :: Int32
            bar = 2 :: Int32
        ([java| $foo + $bar |] >>= reify) `shouldReturn` (3 :: Int32)

      it "Supports antiquotation variables in blocks" $ do
        let z = 1 :: Int32
        ([java| { return $z + 1; } |] >>= reify) `shouldReturn` (2 :: Int32)

      it "Supports anonymous classes" $ do
        _ :: JObject <- [java| new Object() {} |]
        return ()

      it "Supports multiple anonymous classes" $ do
        ([java| new Object() {}.equals(new Object() {}) |] >>= reify) `shouldReturn` False
