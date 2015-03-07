module Loop (loop) where

import Control.Monad.Trans (lift)
import System.Console.Haskeline (InputT, MonadException, Settings, getInputLine,
                                 handleInterrupt, runInputT, withInterrupt)
import System.Exit (ExitCode(ExitSuccess))

import qualified Environment as Env
import qualified Eval.Input as Input
import qualified Eval.Command as Command
import qualified Flags
import qualified Parse


loop :: Flags.Flags -> Settings Command.Command -> IO ExitCode
loop flags settings =
    Command.run flags initialEnv $ runInputT settings (withInterrupt acceptInput)
  where
    initialEnv =
        Env.empty compiler interpreter preserveTemp 
    compiler = (Flags.compiler flags)
    interpreter = (Flags.interpreter flags)
    preserveTemp = (Flags.preserveTemp flags) /= "False"


acceptInput :: InputT Command.Command ExitCode
acceptInput =
 do rawInput <- handleInterrupt (return (Just "")) getInput
    case rawInput of
      Nothing ->
        return ExitSuccess

      Just userInput ->
        do  let input = Parse.rawInput userInput
            result <- lift (Input.eval input)
            case result of
              Just exit -> return exit
              Nothing   -> acceptInput


getInput :: (MonadException m) => InputT m (Maybe String)
getInput =
    go "> " ""
  where
    go lineStart inputSoFar =
        do  input <- getInputLine lineStart
            case input of
              Nothing  -> return Nothing
              Just new -> continueWith (inputSoFar ++ new)

    continueWith inputSoFar =
        if null inputSoFar || last inputSoFar /= '\\'
            then return (Just inputSoFar)
            else go "| " (init inputSoFar ++ "\n")
