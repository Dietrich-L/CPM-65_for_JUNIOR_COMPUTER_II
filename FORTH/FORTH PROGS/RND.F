( RND random nr generator )

0 variable rnd-seed
HEX
: SEED 12 100 * 1A BDOS drop rnd-seed ! ;
DECIMAL
: RND RND-SEED @ 31421 * 6927 + dup RND-SEED ! ;



;S





                                                                             