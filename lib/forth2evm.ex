defmodule Forth2EVM do
	#comments are \ to \n and ( to )
	#functions are : to ;
	def skip_till(text, symbol) do
		cond do 
			text == "" -> ""
			true ->
				<<a::size(8), text::binary>> = text
				l=<<a>>
				cond do
					l==symbol -> text
					true -> skip_till(text, symbol)
				end
		end
	end
	def outside(text, left, right) do
		cond do
			text=="" -> ""
			true ->
				<<a::size(8), text::binary>> = text
				l=<<a>>
				cond do
					l==left -> outside(skip_till(text, right), left, right)
					not(text=="") -> l <> outside(text, left, right)
					true -> l
				end
		end
	end
	def inside(text, left, right) do outside(skip_till(text, left), right, left) end
	def words_code(text) do
		words = text |> String.replace(";", "\\;") |> inside(":", ";") |> String.split("\\") |> Enum.filter(&(&1!=""))
		code = text 
		code = outside(code, ":", ";")
		code = String.replace(code, "\n", " ")
		{words, code}
	end 
	def encode_word(c, jumpdests) do 
		b=prettify(c)
	" jumpdest "<>hd(b)<>" "<>jumps_helper(tl(b), jumpdests)<>" 0 mload dup1 32 swap1 sub 0 mstore mload jump " end 
	def is_string_int(x) do
		cond do
			x=="" -> true
			true -> 
				<<a::size(8), b::binary>>=x
				cond do
					a<48 or a>57 -> false
					true -> is_string_int(b)
				end
		end
	end
	def opcodes do Enum.map(Dict.keys(Assembler.opcodes), &(to_string(&1))) end
		#def opcodes do 	["STOP", "ADD", "MUL", "SUB","DIV","SDIV","MOD","SMOD","ADDMOD","MULMOD","EXP","SIGNEXTEND","LT","GT","SLT","SGT","EQ","ISZERO","AND","OR","XOR","NOT","BYTE","SHA3","ADDRESS","BALANCE","ORIGIN","CALLER","CALLVALUE","CALLDATALOAD","CALLDATASIZE","CALLDATACOPY","CODESIZE","CODECOPY","GASPRICE","EXTCODESIZE","EXTCODECOPY","BLOCKHASH","COINBASE","TIMESTAMP","NUMBER","DIFFICULTY","GASLIMIT","POP","MLOAD","MSTORE","MSTORES","SLOAD","SSTORE","JUMP","JUMPI","PC","MSIZE","GAS","JUMPDEST","PUSH1","PUSH2","PUSH3","PUSH4","PUSH5","PUSH6","PUSH7","PUSH8","PUSH9","PUSH10","PUSH11","PUSH12","PUSH13","PUSH14","PUSH15","PUSH16","PUSH17","PUSH18","PUSH19","PUSH20","PUSH21","PUSH22","PUSH23","PUSH24","PUSH25","PUSH26","PUSH27","PUSH28","PUSH29","PUSH30","PUSH31","PUSH32","DUP1","DUP2","DUP3","DUP4","DUP5","DUP6","DUP7","DUP8","DUP9","DUP10","DUP11","DUP12","DUP13","DUP14","DUP15","DUP16","SWAP1","SWAP2","SWAP3","SWAP4","SWAP5","SWAP6","SWAP7","SWAP8","SWAP9","SWAP10","SWAP11","SWAP12","SWAP13","SWAP14","SWAP15","SWAP16","LOG0","LOG1","LOG2","LOG3","LOG4"] end
	def jumps_helper(c, jumps) do
		cond do 
			c==[] -> ""
			hd(c)==" " or hd(c)=="" -> jumps_helper(tl(c), jumps)
			is_string_int(hd(c)) -> hd(c)<>" "<>jumps_helper(tl(c), jumps)
			String.upcase(hd(c))=="JUMPDEST" -> 
				hd(c)<>" "<>hd(tl(c))<>" "<>jumps_helper(tl(tl(c)), [hd(tl(c))|jumps])
			String.upcase(hd(c)) in jumps and (length(c)==1 or String.upcase(hd(tl(c))))=="ELSE" -> #tail call optimization!
				hd(c)<>" JUMPI "<>jumps_helper(tl(c), jumps)
			String.upcase(hd(c)) in ["ELSE"|opcodes] ->  
				hd(c)<>" "<>jumps_helper(tl(c), jumps)
			length(c) == 1 -> hd(c)<>" jump " 
			true -> 
				r=" "<>Enum.reduce(Enum.map(0..10, fn(x)-> 
							<<:crypto.rand_uniform(66, 90)>> end), "", &(&1<>&2))<>" "
				r<>" 0 mload 32 add dup1 0 mstore mstore "<> hd(c) <> " Jump jumpdest "<>r<>jumps_helper(tl(c), jumps)
		end
	end
	def jds(t, d \\ []) do
		#IO.puts inspect t
		cond do
			t==[] -> d
			String.upcase(hd(t)) == "JUMPDEST" ->
				jds(tl(tl(t)), [hd(tl(t))|d])
			true -> jds(tl(t), d)
		end
	end
	def prettify(c) do c |> String.split(" ") |> Enum.filter(&(&1!=""))end
	def concat(l) do l |> Enum.reduce("", &(&2<>" "<>&1)) end
	def apply_macros(macros, text) do
		#IO.puts "text #{inspect text}"
		#IO.puts "macros #{inspect macros}"
		cond do
			macros==[] -> text
			true -> apply_macros(tl(macros), apply_macro(text, hd(macros)))
		end
	end
	def apply_macro(text, macro) do
		macro= macro |> String.split(" ") |> Enum.filter(&(&1!=""))
		key=hd(macro)
		String.replace(text, key, concat(tl(macro)))
	end
	def compile(text) do
		text=text<>" stop"
		text = text |> outside("\\", "\n") |> outside("(", ")") |> String.replace("\n", " ")#remove comments
		#jumpdests = jds(String.split(String.replace(text, "\n", " "), " ")) #need to use this everywhere!!!!
		#IO.puts "text #{inspect text}"
		macros=text |> String.replace(";", "\\;") 
		#IO.puts "macros #{inspect macros}"
		macros = macros |> inside("#", ";") 
		text = text |> outside("#", ";")
		#IO.puts "text without macro #{inspect text}"
		#IO.puts "macros #{inspect macros}"
		macros = macros |> String.split("\\")
		#IO.puts "macros #{inspect macros}"
		macros = macros |> Enum.filter(&(&1!=""))
		#IO.puts "macros #{inspect macros}"
		text=text |> outside("#", ";")
		text=apply_macros(macros, text)
		{w, c} = words_code(text)
		#IO.puts "w c #{inspect w} #{inspect c}"
		jumpdests = w |> Enum.map(&(hd(prettify(&1)))) |> Enum.map(&(String.upcase(&1)))
		#IO.puts "jumpdests #{inspect jumpdests}"
		#IO.puts "w c #{inspect w} #{inspect c}"
		w = Enum.reduce(Enum.map(w, &(encode_word(&1, jumpdests))), &(&1<>&2))
		c = prettify(c)
		c = jumps_helper(c, jumpdests)
		t=" 0 0 mstore "<>c<>" 0 0 log1 stop "<>w
		t = t |> prettify |> Enum.filter(&(String.upcase(&1)!="ELSE")) |> concat
		IO.puts "before assembler:  "<>t
		Assembler.compile(t)
	end
	def test do
		{:ok, text} = File.read("calc2.fs")
		IO.puts compile(text)
	end
	def test_words_code do
		IO.puts inspect words_code("test.fs")
	end
	def test_out_in do
		{:ok, text} = File.read "test.fs"
		IO.puts inspect text
		IO.puts inspect inside(text, "(", ")")
		IO.puts inspect outside(text, "(", ")")
	end
	def main(args) do
		args=hd(args)
		cond do 
			args==[] -> IO.puts "not enough args. example: ./assembler file.asm"
			args=="-h" -> IO.puts "usage: ./assembler code.asm"
			args=="--help" -> IO.puts "usage: ./assembler code.asm"
			true ->
				{:ok, text} = File.read args
				IO.puts compile(text)
		end
	end
end
