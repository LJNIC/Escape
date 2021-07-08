(local util {})

(fn util.add [a b] (+ a b))
(fn util.sub [a b] (- a b))
(fn util.opposite [operation]
  (if (= operation util.add) util.sub util.add))

(fn util.updateObject [object x y]
  (set object.x x)
  (set object.y y)
  (world:update object x y))

(local colors {
  [0 0 1] 246 ; wall
  [1 0 0] 211 ; left bounce
  [0 1 0] 210 ; right bounce
  [1 1 0] 298 ; 
  [0 1 1] 393 ; vertical laser
  [1 0 1] 299 ; background
  [1 1 1] 395 ; horizontal laser
  [0.5 0 0] 1 ; player
})

(fn getTile [red green blue]
  "Returns a tile id based on the RGB value"
  (var id 400)
  (each [c tile (pairs colors)]
    (let [[r g b] c]
      (when (and (= (math.to_precision red 1) r) (= (math.to_precision green 1) g) (= (math.to_precision blue 1) b))
        (set id tile))))
  id)

(fn util.loadMap [path]
  "Loads an image-level into a table and returns it"
  (let [image (love.image.newImageData path)
        newMap {}
        width (image:getWidth)
        height (image:getHeight)]
    (for [x 1 width]
      (table.insert newMap [])
      (for [y 1 height]
        (table.insert (. newMap  x) 400)))
    (image:mapPixel 
      (fn [x y r g b a] 
        (let [tile (getTile r g b)]
          (tset (. newMap (+ 1 x)) (+ 1 y) tile))
        (values r g b a)))
    newMap))

util
