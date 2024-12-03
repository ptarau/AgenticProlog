% test

/*
s-->[a],t,{write(finished),nl}.
t-->[b],{write(hello),nl}.
t-->[c],{write(bye),nl}.
*/

/*
f(g(X,X),h(Y,X),k(Y,99),a).
*/

a:-b,c.

bbb(X,X):-aaa(X).

aaa(X):-bbb(X,Y),ccc(X),ccc(Y).

ccc(f(X,X)).

b.
c.
