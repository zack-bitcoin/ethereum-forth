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
	def words_code(file) do
		{:ok, text} = File.read "test.fs"
		text = text |> outside("\\", "\n") |> String.replace(";", "\\;") |> outside("(", ")")
		words = text |> inside(":", ";") |> String.split("\\") |> Enum.filter(&(&1!=""))
		code = text |> outside(":", ";") |> String.replace("\n", " ")
		{words, code}
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
end
