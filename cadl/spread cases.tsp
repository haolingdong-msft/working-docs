model A {
 p1: string;
 p2: string;  
}

case1:
op op1(...A);

TCGC return:
A: {
  access: internal
  usage: spread
}

code-model expected return:
A: {
    usage: ["internal", "input"]
}   

case2:
op op1(s: string, ...A);

TCGC return:
Op1Request: {
    access: internal
    usage: spread
}

code-model expected return:
Op1Request: {
    usage: ["internal", "input"]
}


case3:
op op1(s: string, ...A);
op op2(a: A);

TCGC return:
A: {
  access: public
  usage: [input]
}

Op1Request: {
    access: internal
    usage: spread
}

Op2Request: {
    access: internal
    usage: spread
}

code-model expected return:
A: {
    usage: ["public", "input"]
}

Op1Request: {
    usage: ["public", "input"]
}


Case4:
op op1(...A);
op op2(a: A);

TCGC return:

A: {
  access: public
  usage: [input, spread]

}

Op2Request: {
   access: internal
   usage: spread
}

code-model expected return:
