( VDU Graphic routines Package  D. Lausberg  27.06.25 )
( Screen commands )
: CLS 0 0 7 CMDDEV ;
: CLL 0 0 6 CMDDEV ;
: HOME 0 0 5 CMDDEV ;
: SCR-MODE 0 SWAP 15 CMDDEV ;
: TXT_COLOR 0 SWAP 11 CMDDEV ;
: BGR_COLOR 0 SWAP 12 CMDDEV ;
: MOVE_TO 8 CMDDEV    ( Y X -  ) ;
: P_COLOR 0 SWAP 10 CMDDEV ;

-->




( VDU Graphic routines Package - line draw commands )
HEX
: PUT_PIXEL 50 CMDDEV ( Y X -  ) ;
: DEL_PIXEL 53 CMDDEV ( Y X -  ) ;
: DRAW_RECT 60 CMDDEV ( Y X -  ) ;
: DEL_RECT 63 CMDDEV  ( Y X -  ) ;
: DRAW_LINE 70 CMDDEV ( Y X -  ) ;
: DEL_LINE 73 CMDDEV  ( Y X -  ) ;






-->

( VDU Graphic routines Package - aux routines )
0 variable scal 0 variable S_MAX  ( scale )

: SCALE ( x - x_scale ) S_MAX @ scal @ */ ;











-->
( VDU Graphic routines Package - SIN/COS routines   )
decimal
0 variable sintab -2 allot ( 0..90 deg, Index in deg )
0000 , 0175 , 0349 , 0523 , 0698 , 0872 , 1045 , 1219 ,
1392 , 1564 , 1736 , 1908 , 2079 , 2250 , 2419 , 2588 ,
2756 , 2924 , 3090 , 3256 , 3420 , 3584 , 3746 , 3907 ,
4067 , 4226 , 4384 , 4540 , 4695 , 4848 , 5000 , 5150 ,
5299 , 5446 , 5592 , 5736 , 5878 , 6018 , 6157 , 6293 ,
6428 , 6561 , 6691 , 6820 , 6947 , 7071 , 7193 , 7314 ,
7431 , 7547 , 7660 , 7771 , 7880 , 7986 , 8090 , 8192 ,
8290 , 8387 , 8480 , 8572 , 8660 , 8746 , 8829 , 8910 ,
8988 , 9063 , 9135 , 9205 , 9272 , 9336 , 9397 , 9455 ,
9511 , 9563 , 9613 , 9659 , 9703 , 9744 , 9781 , 9816 ,
9848 , 9877 , 9903 , 9925 , 9945 , 9962 , 9976 , 9986 ,
9994 , 9998 , 10000 ,
-->
( SIN/COS/TAN/ATN routines                           )
: sinus@  sintab swap 2 * + @ ;
: sin           ( grad -- sinus )
    dup 0< >r abs 360 mod
    dup 180 > if 180 - 1 >r else 0 >r endif
    dup  90 > if 180 swap - endif sinus@
    r> if minus endif r> if minus endif ;
: cos 90 + sin ;
: tan 10000 swap dup sin swap cos */ ;
: cot 90 + tan minus ;
: SIN_SCALE 10000 SCAL ! S_MAX ! ;




-->
( additional graphics routines )

: CIRCLE ( CX CY DEG_END DEG_START R )
    SIN_SCALE do over over
    I SIN SCALE - swap I COS SCALE -
    PUT_PIXEL loop drop drop ;









-->
( VDU Graphic routines Package                    )
decimal

LATEST   12 +ORIGIN !
HERE     30 +ORIGIN !

;S

