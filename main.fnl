(local bump (require :lib.bump))
(local anim8 (require :lib.anim8))
(local push (require :lib.push))
(local camera (require :lib.camera))
(local util (require :util))
(local player (require :player))
(local level (require :level))
(let [batteries (require :lib.batteries)] (batteries:export))

; game width is 2 tiles wider than we actually render
(global [GAME_WIDTH GAME_HEIGHT] [14 32])
(global TILE_WIDTH 8)
(global [WIDTH HEIGHT] [96 128])

(love.graphics.setDefaultFilter "nearest" "nearest")
(push:setupScreen WIDTH HEIGHT (love.graphics.getDimensions))

; again, we render 2 tiles less than our total width
(local cam (camera 0 0 (- WIDTH (* TILE_WIDTH 2)) HEIGHT))
; shift the camera bound up one tile, and shrink it one tile
(cam:setBounds TILE_WIDTH 0 (- WIDTH TILE_WIDTH) (* GAME_HEIGHT TILE_WIDTH))

(global tileSheet (love.graphics.newImage "assets/tiles.png"))
(global tileAtlas {})
(for [i 0 19]
  (for [j 0 19]
    (table.insert tileAtlas (love.graphics.newQuad (* j 8) (* i 8) 8 8 160 160))))

(local map (require :map))
(local lava {:moving false :death true :x 8 :y (+ 8 (* GAME_HEIGHT TILE_WIDTH))})
(local lavaViewport {:x 0 :y 0})
(local lavaQuad (love.graphics.newQuad 0 0 WIDTH HEIGHT WIDTH (* GAME_HEIGHT TILE_WIDTH)))
(local lavaImage (love.graphics.newImage "assets/lava.png"))
(lavaImage:setWrap "repeat")

(global world (bump.newWorld TILE_WIDTH))
(world:add player player.x player.y (- TILE_WIDTH 2) (- TILE_WIDTH 1))
(map.init)
(map.loadMap (util.loadMap "assets/level5.png"))
(world:add lava lava.x lava.y WIDTH (* GAME_HEIGHT TILE_WIDTH))

(fn love.update [dt]
  (player.update dt)
  (map.update dt)
  (set lavaViewport.x (+ lavaViewport.x (* dt 25)))
  (lavaQuad:setViewport lavaViewport.x 0 WIDTH (* GAME_HEIGHT TILE_WIDTH))
  (if (and lava.moving (>= lava.y 0)) (util.updateObject lava lava.x (- lava.y (* 10 dt))))
  (cam:update dt)
  (cam:follow (+ (/ WIDTH 2)) (math.floor player.y)))

(fn love.keypressed [key]
  (if (= "escape" key) 
      (love.event.quit)
      (and (= "space" key) player.alive)
      (do (player.jump) (set lava.moving true))
      (= "r" key)
      (love.event.quit "restart")))

(fn draw []
  (map.draw)
  (love.graphics.draw lavaImage lavaQuad lava.x lava.y)
  (let [right (= player.direction util.add)
        dead (not player.alive)
        orientation (if right 1 -1)
        ox (if right (if dead 4 0) (if dead 12 6))]
    (player.animation:draw player.image (math.floor player.x) (math.floor (- player.y 1)) 0 orientation 1 ox (if dead 4 0))))

(fn love.draw []
  (push:start)
  (cam:attach)
  (draw)
  (cam:detach)
  (push:finish))
  