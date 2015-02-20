\2 3 square square square square plus stop 
5 fib jumpdest death

: square ( a -- a*a ) dup1 mul ;
: plus ( a b -- a+b ) add ;
: minus ( a b -- a-b ) sub ;
: times ( a b -- a*b ) mul ;
: fib ( n -- f ) 0 1 fibby ;
: fibby ( n a b -- n-1 b a+b) dup1 swap2 add swap2 1 swap1 sub dup1 0 GT death jumpi swap2 fibby ; 
: fib_iter ( a b -- b a+b ) dup1 swap2 add 
