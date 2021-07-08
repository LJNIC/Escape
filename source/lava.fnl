(local anim8 (require :lib/anim8))
(local util (require :util))

(local lava {:moving false :death true :x TILE_WIDTH :y TILE_WIDTH
             :image (love.graphics.newImage "assets/lava_wave.png")
             :background (love.graphics.newImage "assets/lava.png")})
(local lavaGrid (anim8.newGrid 16 8 128 8))
(fn animation [frames duration]
  (anim8.newAnimation frames duration))
(set lava.animation (animation (lavaGrid "1-8" 1) 0.15))

; Initialize lava
(fn lava.init [world tilemap]
  (let [height (* tilemap.height TILE_WIDTH)]
    (tset lava :y height)
    (world:add lava lava.x lava.y WIDTH height)))

(fn lava.update [dt]
  (when lava.moving
    (util.updateObject lava lava.x (- lava.y (* 10 dt)))
    (lava.animation:update dt)))

(fn lava.draw [] 
  (love.graphics.draw lava.background 0 lava.y)
  (for [x 0 128 16]
    (lava.animation:draw lava.image x lava.y)))

lava
