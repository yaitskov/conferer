{-# LANGUAGE RecordWildCards #-}
module Conferer.Source.Namespaced
  (
    -- * Namespaced source
    -- | This source takes a source and returns a new source that
    -- always checks that the 'Key' given always starts with certain 'Key'
    -- and then strips that prefix before consulting its inner Source
    fromConfig
    , fromInner
  ) where

import Conferer.Source

data NamespacedSource =
  NamespacedSource
  { scopeKey :: Key
  , innerSource :: Source
  } deriving (Show)

instance IsSource NamespacedSource where
  getKeyInSource NamespacedSource{..} key = do
    case keyPrefixOf scopeKey key of
      Just innerKey -> getKeyInSource innerSource innerKey
      Nothing -> return Nothing
  getSubkeysInSource NamespacedSource{..} key = do
    case keyPrefixOf scopeKey key of
      Just innerKey -> do
        fmap (scopeKey /.) <$> getSubkeysInSource innerSource innerKey
      Nothing -> return []

-- | Create a 'SourceCreator' from a prefix and another 'SourceCreator'
fromConfig :: Key -> SourceCreator -> SourceCreator
fromConfig scopeKey configCreator = \config -> do
  innerSource <- configCreator config
  return $ fromInner scopeKey innerSource

fromInner :: Key -> Source -> Source
fromInner scopeKey innerSource = do
  Source $ NamespacedSource{..}