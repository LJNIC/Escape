(local bump (require :lib.bump))
(local anim8 (require :lib.anim8))
(local push (require :lib.push))
(local camera (require :lib.camera))
(local util (require :util))
(let [batteries (require :lib.batteries)] (batteries:export))

; game width is 2 tiles wider than we actually render
(global [GAME_WIDTH GAME_HEIGHT] [14 32])
(global TILE_WIDTH 8)
(global [WIDTH HEIGHT] [96 128])
(local player (require :player))
(local lava (require :lava))
(local tilemap (require :tilemap))

(love.graphics.setDefaultFilter "nearest" "nearest")
(push:setupScreen WIDTH HEIGHT (love.graphics.getDimensions))

; again, we render 2 tiles less than our total width
(local cam (camera 0 0  (- WIDTH (* TILE_WIDTH 2)) HEIGHT))

(global world (bump.newWorld TILE_WIDTH))
(tilemap.init)

; load level id from file
(var level 0)
(when (not (love.filesystem.getInfo "level.txt"))
  (love.filesystem.newFile "level.txt" "r")
  (love.filesystem.write "level.txt" "1"))
(let [contents (love.filesystem.read "level.txt")] (set level (tonumber contents)))

(local newMap (util.loadMap (.. "assets/level" level ".png")))
(tilemap.loadMap newMap (length newMap) (length (. newMap 1)) cam)
(player.init world tilemap)
(lava.init world tilemap)

(fn love.update [dt]
  (player.update dt)
  (tilemap.update dt)
  ;(lava.update dt)
  (cam:update dt)
  (cam:follow (+ (/ WIDTH 2)) (math.floor player.y)))

(fn updateLevel []
  (love.filesystem.write "level.txt" (tostring (mathx.wrap (+ level 1) 1 10)))
  (love.event.quit "restart"))

(fn love.keypressed [key]
  (if (= "escape" key) 
      (love.event.quit)
      (and (= "space" key) player.alive)
      (do (player.jump) (set lava.moving true))
      (= "n" key)
      (updateLevel)
      (= "r" key)
      (love.event.quit "restart")))

(fn love.draw []
  (push:start)
  (cam:attach)

  (lava.draw)
  (tilemap.draw)
  (player.draw)

  (cam:detach)
  (push:finish))
  
