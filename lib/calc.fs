\ 2 3 square square square square plus stop jumpdest death 0 0 log2
4 fib 0 0 log1 stop jumpdest death

: square ( a -- a*a ) dup1 mul ;
: plus ( a b -- a+b ) add ;
: minus ( a b -- a-b ) sub ;
: times ( a b -- a*b ) mul ;
: fib ( n -- f ) 0 1 fibby ;
: fibby ( n a b -- n-1 b a+b) dup1 swap2 add swap2 1 swap1 sub dup1 1 GT death jumpi swap2 fibby ; 

