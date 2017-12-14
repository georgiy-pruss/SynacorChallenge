# https://challenge.synacor.com/ - Dec'2017

const LIMIT = 32768 # memory size, int limit
const NR = 8 # number of registers

var M: array[LIMIT,int] # 15-bit value actually
var R: array[NR,int]    # registers
var S: seq[int] = @[]   # stack, initially empty

proc read_into_memory( address: int, filename: string ): int {. discardable .} =
  var a = address
  var b: int
  for i,c in readFile filename: # it reads chars
    if i mod 2 == 0: b = ord(c)
    else: M[a] = (ord(c) shl 8) + b; a += 1
  return 2*(a-address)

#proc fill_memory( address: int, sz: int, value: int ) =
#  for a in address..<LIMIT:
#    M[a] = value

proc value( v: int ): int = (if v<LIMIT: v else: R[v-LIMIT]) # imm value or from register

var outbuf: string = ""
var inbuf: string = ""
var incnt: int = -1 # -1 -- to read, -2 -- eof/error
var inpos: int = 0 # next char index

proc execute( pc: int ): int =
  # return <0 if must stop, otherwise it's next pc
  let op = M[pc]
  case op:
  of 0:  # halt -- stop execution and terminate the program
    return -1
  of 1: # set a b -- set register <a> to the value of <b>
    R[M[pc+1]-LIMIT] = value(M[pc+2])
    return pc+3
  of 2: # push a -- push <a> onto the stack
    S.add value(M[pc+1])
    return pc+2
  of 3: # pop a -- remove the top element from the stack and write it into <a>; empty stack = error
    if S.len == 0: echo "pop from empty stack"; return -1
    let c = S[^1]
    S.del(S.len-1)
    R[M[pc+1]-LIMIT] = c
    return pc+2
  of 4: # eq a b c -- set <a> to 1 if <b> is equal to <c>; set it to 0 otherwise
    R[M[pc+1]-LIMIT] = if value(M[pc+2]) == value(M[pc+3]): 1 else: 0
    return pc+4
  of 5: # gt a b c -- set <a> to 1 if <b> is greater than <c>; set it to 0 otherwise
    R[M[pc+1]-LIMIT] = if value(M[pc+2]) > value(M[pc+3]): 1 else: 0
    return pc+4
  of 6: # jmp a -- jump to <a>
    return value(M[pc+1]) # new pc
  of 7: # jt a b -- if <a> is nonzero, jump to <b>
    return if value(M[pc+1]) != 0: value(M[pc+2]) else: pc+3
  of 8: # jf a b -- if <a> is zero, jump to <b>
    return if value(M[pc+1]) == 0: value(M[pc+2]) else: pc+3
  of 9: # add a b c -- assign into <a> the sum of <b> and <c> (modulo 32768)
    R[M[pc+1]-LIMIT] = (value(M[pc+2]) + value(M[pc+3])) mod LIMIT
    return pc+4
  of 10: # mult a b c -- store into <a> the product of <b> and <c> (modulo 32768)
    R[M[pc+1]-LIMIT] = value(M[pc+2]) * value(M[pc+3]) mod LIMIT
    return pc+4
  of 11: # mod a b c -- store into <a> the remainder of <b> divided by <c>
    R[M[pc+1]-LIMIT] = value(M[pc+2]) mod value(M[pc+3])
    return pc+4
  of 12: # and a b c -- stores into <a> the bitwise and of <b> and <c>
    R[M[pc+1]-LIMIT] = value(M[pc+2]) and value(M[pc+3])
    return pc+4
  of 13: # or a b c -- stores into <a> the bitwise or of <b> and <c>
    R[M[pc+1]-LIMIT] = value(M[pc+2]) or value(M[pc+3])
    return pc+4
  of 14: # not a b -- stores 15-bit bitwise inverse of <b> in <a>
    R[M[pc+1]-LIMIT] = not value(M[pc+2]) and 0x7FFF
    return pc+3
  of 15: # rmem a b -- read M at address <b> and write it to <a>
    R[M[pc+1]-LIMIT] = M[value(M[pc+2])]
    return pc+3
  of 16: # wmem a b -- write the value from <b> into M at address <a>
    M[value(M[pc+1])] = value(M[pc+2])
    return pc+3
  of 17: # call a -- write the address of the next instruction to the stack and jump to <a>
    S.add pc+2
    return value(M[pc+1]) # new pc
  of 18: # ret -- remove the top element from the stack and jump to it; empty stack = halt
    if S.len == 0: echo "ret with empty stack"; return -1
    let c = S[^1]
    S.del(S.len-1)
    return c # new pc
  of 19: # out a -- write the character represented by ascii code <a> to the terminal
    let c = value(M[pc+1])
    if c==10: echo outbuf; outbuf = "" else: outbuf &= chr(c)
    return pc+2
  of 20: # in a -- read a character from the terminal and write its ascii code to <a>
    # it can be assumed that once input starts, it will continue until a newline is encountered;
    # this means that you can safely read whole lines from the keyboard and trust that
    # they will be fully read
    if incnt<0 or inpos>=incnt:
      inbuf = readLine(stdin)
      if inbuf.len==0 or inbuf[^1]!='\10': inbuf &= '\10'
      incnt = inbuf.len
      inpos = 0
    R[M[pc+1]-LIMIT] = inbuf[inpos].ord
    inpos += 1
    return pc+2
  of 21: # noop -- no operation
    return pc+1
  else:
    echo "unknown op: ",op," at address: ",pc
    return -1

proc run( address: uint ) =
  var pc: int = 0
  var cnt: int = 0
  while pc>=0:
    cnt += 1
    pc = execute( pc )
  if outbuf.len>0:
    echo outbuf; outbuf = ""
  echo "executed commands: ",cnt

read_into_memory( 0, "challenge.bin" )
run( 0 )

# vhiYqHRHsOct - start breathing
# QbtRsOmZrHKg - self-test passed
# nQUUBNhKGafz - on tablet
