{-# LANGUAGE DataKinds #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE ScopedTypeVariables #-}

module Main where

import Data.Int
import Language.Java
import Foreign.JNI
import Criterion.Main as Criterion

incrementExact :: Int32 -> IO Int32
incrementExact x = callStatic (sing :: Sing "java.lang.Math") "incrementExact" [coerce x]

jniIncrementExact :: JClass -> JMethodID -> Int32 -> IO Int32
jniIncrementExact klass method x = callStaticIntMethod klass method [coerce x]

intValue :: Int32 -> IO Int32
intValue x = do
    jx <- reflect x
    call jx "intValue" []

compareTo :: Int32 -> Int32 -> IO Int32
compareTo x y = do
    jx <- reflect x
    jy <- reflect y
    call jx "compareTo" [coerce jy]

incrHaskell :: Int32 -> IO Int32
incrHaskell x = return (x + 1)

foreign import ccall unsafe getpid :: IO Int

main :: IO ()
main = withJVM [] $ do
    klass <- findClass "java/lang/Math"
    method <- getStaticMethodID klass "incrementExact" "(I)I"
    Criterion.defaultMain
      [ bgroup "Java calls"
        [ bench "static method call: unboxed single arg / unboxed return" $ nfIO $ incrementExact 1
        , bench "jni static method call: unboxed single arg / unboxed return" $ nfIO $ jniIncrementExact klass method 1
        , bench "method call: no args / unboxed return" $ nfIO $ intValue 1
        , bench "method call: boxed single arg / unboxed return" $ nfIO $ compareTo 1 1
        ]
      , bgroup "Haskell calls"
        [ bench "incr haskell" $ nfIO $ incrHaskell 1
        , bench "ffi haskell" $ nfIO $ getpid
        ]
      ]
