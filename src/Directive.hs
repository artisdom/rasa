module Directive (
      getFocusedBuffer
    , exit
    , overState
    , overBuffer
    , overText
    , insertText
    , deleteChar
    , killWord
    , switchBuf
    , moveCursor
    , moveCursorCoord
    , startOfLine
    , endOfLine
    , startOfBuffer
    , endOfBuffer
    , findNext
    , findPrev
    , deleteTillEOL
) where

import State
import TextLens
import Buffer
import Alteration

import Control.Lens
import qualified Data.Text as T
import Control.Monad.State
import Data.List.Extra (dropEnd)


getFocusedBuffer :: Alteration (Buffer Offset)
getFocusedBuffer = zoom (editor.focusedBuf) get

embed :: (St -> St) -> Alteration ()
embed = zoom editor . modify

exit :: Alteration ()
exit = zoom editor $ exiting .= True


overState :: (St -> St) -> Alteration ()
overState = embed

overBuffer :: (Buffer Offset -> Buffer Offset) -> Alteration ()
overBuffer = embed . over focusedBuf

overText :: (T.Text -> T.Text) -> Alteration ()
overText = embed . over (focusedBuf.text)

insertText :: T.Text -> Alteration ()
insertText txt = embed $ focusedBuf %~ appendText txt

deleteChar :: Alteration ()
deleteChar = embed $ focusedBuf %~ (withOffset before %~ T.dropEnd 1)

killWord :: Alteration ()
killWord = embed $ focusedBuf.text %~ (T.unwords . dropEnd 1 . T.words)

switchBuf :: Int -> Alteration ()
switchBuf n = embed $ execState $ do
    currentBuffer <- use focused
    numBuffers <- use (buffers.to length)
    focused .= (n + currentBuffer) `mod` numBuffers

moveCursor :: Int -> Alteration ()
moveCursor n = embed $ focusedBuf %~ moveCursorBy n

moveCursorCoord :: Coord -> Alteration ()
moveCursorCoord crd = embed $ focusedBuf %~ moveCursorCoordBy crd

startOfLine :: Alteration ()
startOfLine = embed $ focusedBuf %~ findPrev' "\n"

endOfLine :: Alteration ()
endOfLine = embed $ focusedBuf %~ findNext' "\n"

startOfBuffer :: Alteration ()
startOfBuffer = embed $ focusedBuf %~ moveCursorTo 0

endOfBuffer :: Alteration ()
endOfBuffer = embed $ focusedBuf %~ useCountFor text moveCursorTo


findNext' :: T.Text -> Buffer Offset -> Buffer Offset
findNext' txt = useCountFor (withOffset after.tillNext txt) moveCursorBy

findNext :: T.Text -> Alteration ()
findNext txt = embed $ focusedBuf %~ findNext' txt

findPrev' :: T.Text -> Buffer Offset -> Buffer Offset
findPrev' txt = useCountFor (withOffset before.tillPrev txt) moveCursorBackBy

findPrev :: T.Text -> Alteration ()
findPrev txt = embed $ focusedBuf %~ findPrev' txt

deleteTillEOL' :: Buffer Offset -> Buffer Offset
deleteTillEOL' =  withOffset after.tillNext "\n" .~ ""

deleteTillEOL :: Alteration ()
deleteTillEOL = embed $ focusedBuf %~ deleteTillEOL'
