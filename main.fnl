(local bump (require :lib/bump))
(local anim8 (require :lib/anim8))
(local push (require :lib/push))

(love.graphics.setDefaultFilter "nearest" "nearest")
(local (WIDTH HEIGHT) (love.graphics.getDimensions))
(local [GAME_WIDTH GAME_HEIGHT] [12 16])
(push:setupScreen (* GAME_WIDTH 8) (* GAME_HEIGHT 8) WIDTH HEIGHT)

(local world (bump.newWorld 8))

(local tileSheet (love.graphics.newImage "assets/tiles.png"))
(local tileAtlas {})
(for [i 0 19]
  (for [j 0 19]
    (table.insert tileAtlas (love.graphics.newQuad (* j 8) (* i 8) 8 8 160 160))))

(local map {})
(for [x 1 GAME_WIDTH]
  (table.insert map [])
  (for [y 1 GAME_HEIGHT]
    (table.insert (. map x) 400)))

(fn setTile [x y tile]
  (tset (. map x) y tile)
  (world:add {} (* 8 (- x 1)) (* 8 (- y 1)) 8 8))

(for [x 1 GAME_WIDTH]
  (setTile x GAME_HEIGHT 181))
(for [y 1 GAME_HEIGHT]
  (setTile 1 y 181)
  (setTile GAME_WIDTH y 181))
(setTile 4 9 181)
(setTile 4 8 181)
(setTile 4 7 181)
(setTile 9 13 181)
(setTile 10 13 181)
(setTile 11 13 181)
(setTile 12 13 181)
(setTile 6 9 181)
(setTile 7 9 181)
(setTile 8 9 181)

(local characterImage (love.graphics.newImage "assets/astro.png"))
(local characterGrid (anim8.newGrid 8 8 120 8))
(local walk (anim8.newAnimation (characterGrid "2-7" 1) 0.1))

(local explosionImage (love.graphics.newImage "assets/explosion2.png"))
(local explosionGrid (anim8.newGrid 16 16 240 16))
(local die (anim8.newAnimation (explosionGrid "6-15" 1) 0.1))

(fn sub [a b] (- a b))
(fn add [a b] (+ a b))
(fn opposite [operation]
  (if (= operation add) sub add))

(local SPEED 40)
(local WEIGHT 456)
(local JUMP_GRAVITY -80)
; speed      - horizontal speed
; jumping    - whether the player is in the process of jumping (input)
; jumpTimer - how long player has been holding jump
; hasJump   - whether the player can double jump
; onWall    - whether the player is hanging on a wall
; onGround  - whether the player is on the ground
; gravity    - multiplier for pulling player down
; weight     - multiplier for gravity
; direction  - moving left or right 
(local player {:x 16 :y 112 :speed SPEED :direction add :jumping false
               :onWall false :onGround true :hasJump false :gravity 0 :weight WEIGHT
               :jumpTimer 0})

(world:add player player.x player.y 8 8)

(fn filter [item other] "slide")

(fn move-player [x y]
  (let [(actualX actualY cols len) (world:move player x y)]
    (each [index col (pairs cols)]
      ; we hit a wall
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
    ; we fell off a wall
    (when (and (= len 0) player.onWall)
      (set player.onWall false)
      (set player.gravity 50)
      (set player.weight WEIGHT)
      (set player.speed 0)
      (set player.direction (opposite player.direction)))
    (set player.x actualX)
    (set player.y actualY)))

(fn normalJump []
  (set player.jumping true)
  (set player.gravity JUMP_GRAVITY)
  (set player.onGround false)
  (set player.hasJump true))

(fn wallJump []
  (when (not player.onWall)
    (set player.hasJump false))
  (set player.jumping true)
  (set player.direction (opposite player.direction))
  (set player.gravity JUMP_GRAVITY)
  (set player.onGround false)
  (set player.onWall false)
  (set player.weight WEIGHT)
  (set player.speed SPEED))

(fn jumpPlayer []
  (set player.animation die)
  (if (or player.onWall player.hasJump)
      (wallJump)
      player.onGround
      (normalJump)))

(fn love.update [dt]
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
    (move-player x y))
  (walk:update dt))

(fn love.keypressed [key]
  (if (= "escape" key) 
      (love.event.quit)
      (= "space" key)
      (jumpPlayer)))

(fn draw-ground [rect]
  (love.graphics.rectangle "line" rect.x rect.y rect.width rect.height))

(fn love.draw []
  (push:start)
  (love.graphics.setLineWidth 2)
  (for [x 1 GAME_WIDTH]
    (for [y 1 GAME_HEIGHT]
      (love.graphics.draw tileSheet (. tileAtlas (. (. map x) y)) (* (- x 1) 8) (* (- y 1) 8))))
  (let [orientation (if (= player.direction add) 1 -1)
        ox (if (= player.direction add) 0 8)]
    (walk:draw characterImage player.x player.y 0 orientation 1 ox))
  (push:finish))
  