(local anim8 (require :lib/anim8))
(local util (require :util))

(local lava {:moving false :death true :x 8 :y (+ 8 (* GAME_HEIGHT TILE_WIDTH))
             :image (love.graphics.newImage "assets/lava_wave.png")
             :background (love.graphics.newImage "assets/lava.png")})
(local lavaGrid (anim8.newGrid 16 8 128 8))
(fn animation [frames duration]
  (anim8.newAnimation frames duration))
(set lava.animation (animation (lavaGrid "1-8" 1) 0.15))

(fn lava.update [dt]
  (when lava.moving
    (util.updateObject lava lava.x (- lava.y (* 10 dt)))
    (lava.animation:update dt)))

(fn lava.draw [] 
  (love.graphics.draw lava.background 0 lava.y)
  (lava.animation:draw lava.image 16 lava.y)
  (lava.animation:draw lava.image 32 lava.y)
  (lava.animation:draw lava.image 48 lava.y)
  (lava.animation:draw lava.image 64 lava.y)
  (lava.animation:draw lava.image 80 lava.y)
  (lava.animation:draw lava.image 96 lava.y))

lava
