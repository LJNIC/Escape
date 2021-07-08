(local util (require :util))
(local anim8 (require :lib/anim8))
(local audio (require :audio))
(local timer (require :lib/batteries/timer))

(local characterImage (love.graphics.newImage "assets/astro.png"))
(local characterGrid (anim8.newGrid 8 8 128 8))
(local walk (anim8.newAnimation (characterGrid "2-7" 1) 0.1))
(local jump (anim8.newAnimation (characterGrid 5 1) 1000000))
(local airJump (anim8.newAnimation (characterGrid 16 1 5 1) 0.1 "pauseAtEnd"))
(local fall (anim8.newAnimation (characterGrid 9 1) 10000))
(local wall (anim8.newAnimation (characterGrid 11 1) 1000000))

(local explosionImage (love.graphics.newImage "assets/explosion2.png"))
(local explosionGrid (anim8.newGrid 16 16 256 16))
(local die (anim8.newAnimation (explosionGrid "6-16" 1) 0.1 "pauseAtEnd"))
(local dustImage (love.graphics.newImage "assets/dust.png"))
(local dustAnimation
  (let [grid (anim8.newGrid 8 8 88 8)]
    (anim8.newAnimation (grid "1-10" 1) 0.05 "pauseAtEnd")))
(local dusts {})
(local timers {})

(local SPEED 40)
(local WEIGHT 600)
(local JUMP_GRAVITY -80)
; speed      - horizontal speed
; direction  - a function that either adds or subtracts to the player's X position
; jumping    - whether the player is in the process of jumping (input)
; jumpTimer  - how long player has been holding jump
; hasJump    - whether the player can double jump
; onWall     - whether the player is hanging on a wall/
; onGround   - whether the player is on the ground
; gravity    - multiplier for pulling player down
; weight     - multiplier for gravity
; animation  - which animation to draw (walk, die, jump, etc)
; image      - the corresponding image for the animation
; alive      - whether the player is dead or alive
(local player {:x 16 :y (- (* GAME_HEIGHT TILE_WIDTH) 16) :speed SPEED :direction util.add :jumping false :jumpTimer 0
               :hasJump false :onWall false :onGround true :gravity 0 :weight WEIGHT
               :animation walk :image characterImage :alive true})

(fn player.init [world tilemap]
  (when tilemap.player 
    (tset player :x (* TILE_WIDTH tilemap.player.x))
    (tset player :y (* TILE_WIDTH tilemap.player.y)))
  (world:add player player.x player.y (- TILE_WIDTH 2) (- TILE_WIDTH 1)))

(fn player.kill []
  (audio.play :die)
  (audio.play :die2 {:volume 0.6})
  (set player.image explosionImage)
  (set player.animation die)
  (set player.alive false))

(fn player.normalJump []
  (audio.play :jump {:pitch (+ 0.5 (love.math.random))})
  (set player.jumping true)
  (set player.gravity JUMP_GRAVITY)
  (set player.onGround false)
  (set player.hasJump true))

(fn player.wallJump [isAir]
  (when (not isAir)
    (audio.play :jump {:pitch (+ 0.5 (love.math.random))}))
  (if (not player.onWall)
      (set player.hasJump false)
      (set player.hasJump true))
  (set player.jumping true)
  (set player.direction (util.opposite player.direction))
  (set player.gravity JUMP_GRAVITY)
  (set player.onGround false)
  (set player.onWall false)
  (set player.weight WEIGHT)
  (set player.speed SPEED))

(fn createDust [x y animation dir]
  {:pos (vec2 x y) :animation animation :dir dir})

(fn player.airJump []
  (airJump:gotoFrame 1)
  (airJump:resume)
  (set player.animation airJump)
  (set player.jet (audio.play :jet {:pitch 0.75}))
  (table.insert timers (timer 
    0.15
    nil 
    (fn [t]
      (table.insert dusts (createDust player.x player.y (let [d (dustAnimation:clone)] (d:flipV)) (vec2 0 1)))
      (table.insert dusts (createDust (+ player.x 3) player.y (let [d (dustAnimation:clone)] (d:flipH)) (vec2 0.75 1)))
      (table.insert dusts (createDust (- player.x 3) player.y (dustAnimation:clone) (vec2 -0.75 1))))))
  (player.wallJump true))

(fn player.jump []
  (set player.animation jump)
  (if player.onWall
      (player.wallJump)
      player.hasJump
      (player.airJump)
      player.onGround
      (player.normalJump)))

(fn player.handleGround [col]
  (if (or (= col.normal.x -1) (= col.normal.x 1))
      (do 
        (set player.onWall true)
        (set player.animation wall)
        (set player.weight 1)
        (set player.gravity 10)
        (set player.hasJump true))
        ; we hit the ground
      (= col.normal.y -1)
      (do 
        (set player.gravity 0)
        (when (not player.onGround)
          (table.insert dusts (createDust player.x player.y (let [d (dustAnimation:clone)] (d:flipV)) (vec2 1 0)))
          (table.insert dusts (createDust (+ player.x 3) player.y (let [d (dustAnimation:clone)] (d:flipH)) (vec2 -1 0))))
        (set player.onGround true)
        (set player.speed SPEED)
        (when (not player.onWall) (set player.animation walk))
        (set player.hasJump false))
      ; we hit a ceiling
      (= col.normal.y 1)
      (do 
        (set player.gravity 25))))

(fn player.conveyor [col]
  (player.handleGround col)
  (if (= col.normal.x -1) 
      (set player.gravity (col.other.direction 0 20))
      (= col.normal.x 1)
      (set player.gravity (col.other.direction 0 -20))))

(fn player.bounce [col]
  (set player.speed SPEED)
  (set player.animation jump)
  (if (or (= col.normal.y 1) (= col.normal.y -1))
      (player.handleGround col)
      player.onWall
      (do
        (audio.play :bounce)
        (player.wallJump) 
        (set player.gravity -100))
      (do 
        (audio.play :bounce)
        (set player.direction col.other.direction)
        (player.normalJump)
        (set player.gravity -100))))

(fn doNothing [] (+ 0 0))

(fn player.move [x y]
  (let [(actualX actualY cols len) (world:move player x y)]
    (each [index col (pairs cols)]
      (if (not player.alive)
          (doNothing)
          col.other.death
          (player.kill)
          col.other.ground 
          (player.handleGround col)
          col.other.bounce
          (player.bounce col)
          col.other.conveyor
          (player.conveyor col)))
    ; we fell off a wall
    (when (and (= len 0) player.onWall)
      (set player.animation fall)
      (set player.onWall false)
      (set player.gravity 50)
      (set player.weight WEIGHT)
      (set player.speed 0)
      (set player.direction (util.opposite player.direction)))
    (when player.alive 
      (if (> player.x (+ WIDTH 4))
          (util.updateObject player 4 player.y)
          (< player.x 4)
          (util.updateObject player (+ WIDTH 4) player.y)
          (do 
            (set player.x actualX)
            (set player.y actualY))))))

(fn updateTimers [dt]
  (for [i (# timers) 1 -1]
    (let [timer (. timers i)]
      (timer:update dt))))

(fn updateDust [dt]
  (for [i (# dusts) 1 -1]
    (let [dust (. dusts i)]
      (dust.animation:update dt)
      (tset dust :pos (dust.pos:vaddi (dust.dir:smuli (* dt 55))))
      (if (= dust.animation.status "paused") (table.remove dusts i)))))

(fn player.update [dt]
  (when player.alive (let [x (player.direction player.x (* player.speed dt))
        y (+ player.y (* player.gravity dt))]
    (if (and player.jumping (love.keyboard.isDown "space") (< player.jumpTimer 0.3)) 
      (do 
        (set player.gravity (+ player.gravity (* 150 dt)))
        (set player.jumpTimer (+ player.jumpTimer dt)))
      (do 
        (if (< player.gravity 200) (set player.gravity (+ player.gravity (* player.weight dt))))
        (set player.jumping false)
        (set player.jumpTimer 0)))
    (player.move x y)))
  (player.animation:update dt)
  (when (> (# timers) 0)
    (updateTimers dt))
  (when (> (# dusts) 0)
    (updateDust dt)))

(fn player.draw []
  (let [right (= player.direction util.add)
        dead (not player.alive)
        orientation (if right 1 -1)
        ox (if right (if dead 4 0) (if dead 12 6))]
    (each [_ dust (ipairs dusts)]
      (dust.animation:draw dustImage dust.pos.x dust.pos.y))
    (player.animation:draw player.image (math.floor player.x) (math.floor (- player.y 1)) 0 orientation 1 ox (if dead 4 0))))

player
