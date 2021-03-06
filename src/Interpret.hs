module Interpret
    ( tryInterpret
    , validate
    ) where

import           Lib
import           Lib.Prelude                  hiding (try)

import           Language.Haskell.Interpreter hiding (interpret)
import           Mueval.ArgsParse
import           Mueval.Context
import           Mueval.Interpreter
import           Network.Discord
import           Text.Megaparsec.Text         (Parser)

import           Text.Megaparsec              hiding (count, (<|>))

options :: Options
options = Options
  { expression = ""
  , modules = Just defaultModules
  , timeLimit = 5
  , user = ""
  , loadFile = ""
  , printType = False
  , typeOnly = False
  , extensions = False
  , namedExtensions = []
  , noImports = False
  , rLimits = False
  , packageTrust = False
  , trustedPackages = defaultPackages
  , help = False
  }


tryInterpret :: Bool -> Text -> IO Text
tryInterpret typeOnly' msgBody = do
    let tryParse = getExpr msgBody
    case tryParse of
        Right parsedExpr ->
            interpret typeOnly' parsedExpr
        Left err -> do
            print err
            pure $ "PLEASE FORMAT YOUR MESSAGE LIKE THIS:" </>
                   "\\`\\`\\`hs" </>
                   "[CODE]" </>
                   "\\`\\`\\`"

interpret :: Bool -> Text -> IO Text
interpret typeOnly' parsedExpr = do
    let opts = options { typeOnly = typeOnly', expression = toS parsedExpr }
    res <- runInterpreter (interpreter opts)
    pure . code $ case res of
        Right (_, exprType, result) ->
            toS $ if typeOnly' then exprType else result
        Left err -> show err

getExpr :: Text -> Either (ParseError Char Dec) Text
getExpr msgBody = fmap toS . parse parseEval "" $ toS msgBody

validate :: User -> Bool
validate author = show (userId author) `elem` bigBoys
    where bigBoys :: [Text]
          bigBoys = ["162951695469510656", "231224005149851649"]

parseEval :: Parser String
parseEval = do
    void $ string "```hs\n"
    manyTill anyChar (try (string "```"))
