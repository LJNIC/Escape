(local bump (require :lib/bump))
(local anim8 (require :lib/anim8))
(local push (require :lib/push))
(local camera (require :lib/camera))
(local util (require :util))
(local player (require :player))

; game width is 2 tiles wider than we actually render
(global [GAME_WIDTH GAME_HEIGHT] [14 32])
(global [WIDTH HEIGHT] [96 128])

(love.graphics.setDefaultFilter "nearest" "nearest")
(push:setupScreen WIDTH HEIGHT (love.graphics.getDimensions))

; again, we render 2 tiles less than our total width
(local cam (camera 0 0 (- WIDTH 16) HEIGHT))
; shift the camera bound up one tile, and shrink it one tile
(cam:setBounds 8 0 (- WIDTH 8) (* GAME_HEIGHT 8))

(global tileSheet (love.graphics.newImage "assets/tiles.png"))
(global tileAtlas {})
(for [i 0 19]
  (for [j 0 19]
    (table.insert tileAtlas (love.graphics.newQuad (* j 8) (* i 8) 8 8 160 160))))

(local map (require :map))
(local lava {:death true :x 8 :y (* GAME_HEIGHT 8)})
(fn love.load []
  (global world (bump.newWorld 8))
  (world:add player player.x player.y 6 8)
  (map.init)
  (for [x 1  GAME_WIDTH]
    (map.setTile x GAME_HEIGHT 181))
  (for [y 1 (- GAME_HEIGHT 6)]
    (map.setTile 2 y 181)
    (map.setTile (- GAME_WIDTH 1) y 181))
  (world:add lava lava.x lava.y WIDTH (* GAME_HEIGHT 8))
  (map.setTile 10 28 181)
  (map.setTile 5 25 181)
  (map.setTile 9 28 211)
  (map.setTile 6 25 210))


(fn love.update [dt]
  (player.update dt)
  (util.updateObject lava lava.x (- lava.y 0.1))
  (cam:update dt)
  (cam:follow (+ (/ WIDTH 2)) player.y))

(fn love.keypressed [key]
  (if (= "escape" key) 
      (love.event.quit)
      (= "space" key)
      (player.jump)
      (= "i" key)
      (print player.x player.y player.gravity)
      (= "r" key)
      (love.event.quit "restart")))

(fn draw []
  (map.draw)
  (love.graphics.rectangle "fill" lava.x lava.y WIDTH (* GAME_HEIGHT 8))
  (let [right (= player.direction util.add)
        dead (not player.alive)
        orientation (if right 1 -1)
        ox (if right (if dead 4 0) (if dead 12 6))]
    (player.animation:draw player.image player.x player.y 0 orientation 1 ox (if dead 4 0))))

(fn love.draw []
  (push:start)
  (cam:attach)
  (draw)
  (cam:detach)
  (push:finish))
  