defmodule Forth do
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
	def test do
		{:ok, text} = File.read "test.fs"
		IO.puts inspect text
		text=outside(text, "\\", "\n")
		IO.puts inspect text
		String.replace(text, ";", "\\;")
		text=outside(text, "(", ")")
		IO.puts inspect text
		words=inside(text, ":", ";")
		IO.puts "words: #{inspect words}"
		String.split(words, "\\")
		IO.puts "words: #{inspect words}"
	end
	def test_out_in do
		{:ok, text} = File.read "test.fs"
		IO.puts inspect text
		IO.puts inspect inside(text, "(", ")")
		IO.puts inspect outside(text, "(", ")")
	end
end
