-module(tut).
-export([double/1, factorial/1, multiply/2, convert/2, convert_length/1, list_length/1]).

double(X) ->
	2 * X.

factorial(1) ->
	1;

factorial(N) ->
	N * factorial(N - 1).


multiply(X, Y) ->
	X * Y.

convert(M,inch) ->
	M/2.54;
convert(N, centimeter) ->
	N*2.54.

convert_length({centimeter, X}) -> 
	{inch, X/2.54};
convert_length({inch, Y}) ->
	{centimeter, Y*2.54}.

list_length([]) ->
	0;
list_length([H|T]) ->
	1 + list_length(T).
