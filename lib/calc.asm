
	1 0
	mstore
	2 3 callback 0           
		     mload dup1 
	      	           swap2 
		           swap1
	    mstore 1 
	    add 0 mstore
	 plus jump jumpdest callback stop
	jumpdest plus add jump
	jumpdest minus sub jump
	jumpdest times mul jump



