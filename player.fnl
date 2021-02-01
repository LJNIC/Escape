(local util (require :util))
(local anim8 (require :lib/anim8))

(local characterImage (love.graphics.newImage "assets/astro.png"))
(local characterGrid (anim8.newGrid 8 8 120 8))
(local walk (anim8.newAnimation (characterGrid "2-7" 1) 0.1))

(local explosionImage (love.graphics.newImage "assets/explosion2.png"))
(local explosionGrid (anim8.newGrid 16 16 256 16))
(local die (anim8.newAnimation (explosionGrid "6-16" 1) 0.1 "pauseAtEnd"))

(local SPEED 40)
(local WEIGHT 456)
(local JUMP_GRAVITY -80)
; speed      - horizontal speed
; direction  - a function that either adds or subtracts to the player's X position
; jumping    - whether the player is in the process of jumping (input)
; jumpTimer  - how long player has been holding jump
; hasJump    - whether the player can double jump
; onWall     - whether the player is hanging on a wall
; onGround   - whether the player is on the ground
; gravity    - multiplier for pulling player down
; weight     - multiplier for gravity
; animation  - which animation to draw (walk, die, jump, etc)
; image      - the corresponding image for the animation
; alive      - whether the player is dead or alive
(local player {:x 16 :y 240 :speed SPEED :direction util.add :jumping false :jumpTimer 0
               :hasJump false :onWall false :onGround true :gravity 0 :weight WEIGHT
               :animation walk :image characterImage :alive true})

(fn player.kill []
  (set player.image explosionImage)
  (set player.animation die)
  (set player.alive false))

(fn player.normalJump []
  (set player.jumping true)
  (set player.gravity JUMP_GRAVITY)
  (set player.onGround false)
  (set player.hasJump true))

(fn player.wallJump []
  (when (not player.onWall)
    (set player.hasJump false))
  (set player.jumping true)
  (set player.direction (util.opposite player.direction))
  (set player.gravity JUMP_GRAVITY)
  (set player.onGround false)
  (set player.onWall false)
  (set player.weight WEIGHT)
  (set player.speed SPEED))

(fn player.jump []
  (if (or player.onWall player.hasJump)
      (player.wallJump)
      player.onGround
      (player.normalJump)))

(fn player.handleGround [col]
  (if (or (= col.normal.x -1) (= col.normal.x 1))
      (do 
        (set player.onWall true)
        (set player.weight 1)
        (set player.gravity 10)
        (set player.hasJump true))
        ; we hit the ground
      (= col.normal.y -1)
      (do 
        (set player.gravity 0)
        (set player.onGround true)
        (set player.speed SPEED)
        (set player.hasJump false))
      ; we hit a ceiling
      (= col.normal.y 1)
      (do 
        (set player.gravity 25))))

(fn player.bounce [col]
  (if (= col.normal.y 1) 
      (player.handleGround col)
      player.onWall
      (do
        (player.wallJump) 
        (set player.gravity -100))
      (do 
        (set player.direction col.other.direction)
        (player.normalJump)
        (set player.gravity -100))))

(fn player.updateCollider [x y]
  (set player.x x)
  (set player.y y)
  (world:update player player.x player.y))

(fn player.move [x y]
  (let [(actualX actualY cols len) (world:move player x y)]
    (each [index col (pairs cols)]
      (if 
        col.other.ground 
        (player.handleGround col)
        col.other.death
        (player.kill)
        col.other.bounce
        (player.bounce col)))
    ; we fell off a wall
    (when (and (= len 0) player.onWall)
      (set player.onWall false)
      (set player.gravity 50)
      (set player.weight WEIGHT)
      (set player.speed 0)
      (set player.direction (util.opposite player.direction)))
    (when player.alive 
      (if (> player.x (+ WIDTH 4))
          (player.updateCollider 4 player.y)
          (< player.x 4)
          (player.updateCollider (+ WIDTH 4) player.y)
          (do 
            (set player.x actualX)
            (set player.y actualY))))))

(fn player.update [dt]
  (let [x (player.direction player.x (* player.speed dt))
        y (+ player.y (* player.gravity dt))]
    (if (and player.jumping (love.keyboard.isDown "space") (< player.jumpTimer 0.3)) 
      (do 
        (set player.gravity (+ player.gravity 2))
        (set player.jumpTimer (+ player.jumpTimer dt)))
      (do 
        (set player.gravity (+ player.gravity (* player.weight dt)))
        (set player.jumping false)
        (set player.jumpTimer 0)))
    (player.move x y))
  (player.animation:update dt))

player