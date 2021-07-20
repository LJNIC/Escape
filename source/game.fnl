(local bump (require :source.lib.bump))
(local anim8 (require :source.lib.anim8))
(local camera (require :source.lib.camera))
(local util (require :source.util))
(local timers (require :source.timers))
(local animations (require :source.animations))
(love.graphics.setDefaultFilter "nearest" "nearest")

; game width is 2 tiles wider than we actually render
(global TILE_WIDTH 8)
(global [WIDTH HEIGHT] [112 128])
(local player (require :source.player))
(local lava (require :source.lava))
(local tilemap (require :source.tilemap))

(local canvas (love.graphics.newCanvas WIDTH HEIGHT))

; again, we render 2 tiles less than our total width
(local cam (camera 0 0 (- WIDTH (* TILE_WIDTH 2)) HEIGHT))
(cam:setFollowStyle "PLATFORMER")

(global world (bump.newWorld TILE_WIDTH))

; load level id from file
(var level 0)
(when (love.filesystem.getInfo "level.txt")
  (love.filesystem.newFile "level.txt" "r")
  (love.filesystem.write "level.txt" "1"))
(let [contents (love.filesystem.read "level.txt")] (set level (tonumber contents)))

(tilemap.load-map (.. "source/levels/level-" level) cam)
(player.init world tilemap)
;(lava.init world tilemap)

(local game {})

(var paused false)
(fn game.update [self dt]
  (when (not paused)
    (player.update dt)
    (timers.update dt)
    (animations.update dt)
    (tilemap.update dt)
    ;(lava.update dt)
    (cam:update dt)
    (cam:follow (/ WIDTH 2) player.y)
    (set cam.x (math.floor cam.x))
    (set cam.y (math.floor cam.y))))

(fn update-level []
  (love.filesystem.write "level.txt" (tostring (math.wrap (+ level 1) 1 1)))
  (love.event.quit "restart"))

(fn game.keypressed [self key]
  (if (= "escape" key) 
      (love.event.quit)
      (and (= "space" key) player.alive)
      (do (player.jump) (set lava.moving true))
      (= "p" key)
      (set paused (not paused))
      (= "n" key)
      (update-level)
      (= "r" key)
      (love.event.quit "restart")))

(fn game.draw [self]
  (love.graphics.setCanvas canvas)
  (love.graphics.clear)
  (tilemap.draw-background cam)
  (cam:attach)

  (tilemap.draw)
  (player.draw)
  (animations.draw)
  ;(lava.draw)

  (cam:detach)
  (love.graphics.setCanvas)
  (love.graphics.scale 5 5)
  (love.graphics.draw canvas (- (/ (/ (love.graphics.getWidth) 5) 2) (/ WIDTH 2)) -20))
  
game
