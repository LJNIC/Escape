(local bump (require :lib.bump))
(local anim8 (require :lib.anim8))
(local push (require :lib.push))
(local camera (require :lib.camera))
(local util (require :util))
(let [batteries (require :lib.batteries)] (batteries:export))
(local timers (require :timers))
(local animations (require :animations))

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
(cam:setFollowStyle "PLATFORMER")

(global world (bump.newWorld TILE_WIDTH))

; load level id from file
(var level 0)
(when (love.filesystem.getInfo "level.txt")
  (love.filesystem.newFile "level.txt" "r")
  (love.filesystem.write "level.txt" "1"))
(let [contents (love.filesystem.read "level.txt")] (set level (tonumber contents)))

(tilemap.load-map (.. "levels/level-" level) cam)
(player.init world tilemap)
(lava.init world tilemap)

(fn love.update [dt]
  (player.update dt)
  (timers.update dt)
  (animations.update dt)
  (tilemap.update dt)
  (lava.update dt)
  (cam:update dt)
  (cam:follow (/ WIDTH 2) player.y)
  (set cam.x (math.floor cam.x))
  (set cam.y (math.floor cam.y)))

(fn update-level []
  (love.filesystem.write "level.txt" (tostring (math.wrap (+ level 1) 1 1)))
  (love.event.quit "restart"))

(fn love.keypressed [key]
  (if (= "escape" key) 
      (love.event.quit)
      (and (= "space" key) player.alive)
      (do (player.jump) (set lava.moving true))
      (= "n" key)
      (update-level)
      (= "r" key)
      (love.event.quit "restart")))

(fn love.draw []
  (push:start)
  (tilemap.draw-background cam)
  (cam:attach)

  (tilemap.draw)
  (player.draw)
  (animations.draw)
  (lava.draw)

  (cam:detach)
  (push:finish))
  
