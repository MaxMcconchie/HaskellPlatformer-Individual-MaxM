module Game.Input where

import Control.Lens
import Control.Monad.RWS
import Control.Monad.Reader
import Control.Lens

import Game.AssetManagement
import Game.Data.Alias
import Game.Data.Enum
import Game.Data.Environment
import Game.Data.State
import Game.Init
import Game.Logic

import Graphics.Gloss.Interface.IO.Game

import System.Exit

handleKeys :: Event -> RWSIO GameState
handleKeys e = do
    scene <- use gGameScene
    heading  <- use (gPlayerState . pHeading)
    case e of
        (EventKey (SpecialKey KeyEsc) Up _ _) -> liftIO exitSuccess
        (EventKey (Char 'p') Down _ _) -> do
            pauseGame
            case heading of
                FaceRight -> stopMoveRight
                FaceLeft  -> stopMoveLeft
        _                              ->
            case scene of
                ScenePause -> return ()
                SceneStart -> 
                    case e of
                        (EventKey (SpecialKey KeyEnter) Down _ _) ->
                            updateScene SceneLevel
                        _                                         -> 
                            return ()
                SceneLose ->
                    case e of
                        (EventKey (SpecialKey KeyEnter) Down _ _) ->
                            resetGame
                        _                                         ->
                            return ()
                _           -> case e of 
                                    (EventKey (SpecialKey KeyLeft) Down _ _)  -> 
                                        moveLeft
                                    (EventKey (SpecialKey KeyRight) Down _ _) -> 
                                        moveRight
                                    (EventKey (SpecialKey KeyUp) Down _ _)    -> 
                                        moveUp
                                    (EventKey (SpecialKey KeyLeft) Up _ _)    -> 
                                        stopMoveLeft
                                    (EventKey (SpecialKey KeyRight) Up _ _)   -> 
                                        stopMoveRight
                                    _                                         ->
                                        return ()
    get -- return GameState

pauseGame :: (PureRWS m) => m ()
pauseGame = do
    scene    <- use gGameScene

    case scene of
        SceneLevel -> gGameScene .= ScenePause
        ScenePause -> gGameScene .= SceneLevel
        _          -> return ()
        
    return ()

moveUp :: (PureRWS m) => m ()
moveUp = do
    env <- ask
    let tileSize = view eTileSize env
    
    (x, y) <- use (gPlayerState . pPosition)
    let colliders = getCollidables
    
    hit <- collideWith colliders (x, y - tileSize)
    case hit of
        Nothing -> return ()
        Just _  -> do
            (currSpeedX, _) <- use (gPlayerState . pSpeed)
            gPlayerState . pSpeed .= (currSpeedX , 2000)
        
    

moveLeft :: (PureRWS m) => m ()
moveLeft = do
    gPlayerState . pMovement .= MoveLeft
    gPlayerState . pHeading  .= FaceLeft

moveRight :: (PureRWS m) => m () 
moveRight = do
    gPlayerState . pMovement .= MoveRight
    gPlayerState . pHeading  .= FaceRight 

stopMoveLeft :: (PureRWS m) => m () 
stopMoveLeft = do
    movement <- use (gPlayerState . pMovement)
    case movement of
        MoveLeft -> gPlayerState . pMovement .= MoveStop
        _        -> return ()
    

stopMoveRight :: (PureRWS m) => m () 
stopMoveRight = do
    movement <- use (gPlayerState . pMovement)
    case movement of
        MoveRight -> gPlayerState . pMovement .= MoveStop
        _         -> return ()
    

updateScene :: (PureRWS m) => GameScene -> m ()
updateScene scene = do
    gPlayerState .= initPlayer -- reset player
    gGameScene   .= scene


-- exitGame??



