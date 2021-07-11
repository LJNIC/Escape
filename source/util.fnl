(local util {})

(fn util.add [a b] (+ a b))
(fn util.sub [a b] (- a b))
(fn util.opposite [operation]
  (if (= operation util.add) util.sub util.add))

(fn util.update-object [object x y]
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

util
