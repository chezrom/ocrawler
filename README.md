Here is 'Ophidian Crawler' (version 0.06) a small snake game without right angles.
It is powered by the löve 2D game engine (lua based)

The head of the snake is the yellow circle, and to grow you must eat 'vitamin' (the yellow and red circles).
The yellow vitamin become red two seconds before disapear.
Each vitamin add one green circle to the snake's body.

You loose when your head hit your body

The score computation :

Each time you eat 'vitamin' your earn 50 points (yellow) or 100 points (red) and a bonus about the half of the length of your snake.
The bonus is earn in five parts, each second after the fifth second you ate the 'vitamin'
Those bonus are cumulative, and the number in red shows you the ammount of bonus to earn

The snake wrap around the screen

If no movement (right or left) is done during five seconds, the snake becomes 'ghost' and can not eat vitamin. Any movement terminate this mode.

The snake body avoid to travel across the vitamin.

URL of the löve forum thread : http://love2d.org/forums/viewtopic.php?f=5&t=36591
