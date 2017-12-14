# https://challenge.synacor.com/ - Dec'2017

const LIMIT = 32768
const NR = 8 # number of registers

var memory: array[LIMIT,int] # 16-bit value actually
var reg: array[NR,int]
var stack: seq[int] = @[] # stack, initially empty

proc read_into_memory( address: int, filename: string ): int =
  var a = address
  var b: int
  var evenbyte = true
  for c in readFile filename: # it reads chars
    if evenbyte:
      b = ord(c)
    else:
      memory[a] = (ord(c) shl 8) + b
      a += 1
    evenbyte = not evenbyte
  return 2*(a-address)

proc fill_memory( address: int, sz: int, value: int ) =
  for a in address..<LIMIT:
    memory[a] = value

proc value( val: int ): int = # imm value or from register
  if val<LIMIT: return val
  return reg[val-LIMIT]

var outbuf: string = ""
var inbuf: string = ""
var incnt: int = -1 # -1 -- to read, -2 -- eof/error
var inpos: int = 0 # next char index

proc execute( pc: int ): int =
  # return <0 if must stop, otherwise it's next pc
  let op = memory[pc]
  case op:
  of 0:  # halt -- stop execution and terminate the program
    return -1
  of 1: # set a b -- set register <a> to the value of <b>
    reg[memory[pc+1]-LIMIT] = value(memory[pc+2])
    return pc+3
  of 2: # push a -- push <a> onto the stack
    let c = value(memory[pc+1])
    stack.add c
    return pc+2
  of 3: # pop a -- remove the top element from the stack and write it into <a>; empty stack = error
    if stack.len == 0: echo "pop from empty stack"; return -1
    let c = stack[^1]
    stack.del(stack.len-1)
    reg[memory[pc+1]-LIMIT] = c
    return pc+2
  of 4: # eq a b c -- set <a> to 1 if <b> is equal to <c>; set it to 0 otherwise
    let v = value(memory[pc+2]) == value(memory[pc+3])
    reg[memory[pc+1]-LIMIT] = if v: 1 else: 0
    return pc+4
  of 5: # gt a b c -- set <a> to 1 if <b> is greater than <c>; set it to 0 otherwise
    let v = value(memory[pc+2]) > value(memory[pc+3])
    reg[memory[pc+1]-LIMIT] = if v: 1 else: 0
    return pc+4
  of 6: # jmp a -- jump to <a>
    return value(memory[pc+1]) # new pc
  of 7: # jt a b -- if <a> is nonzero, jump to <b>
    if value(memory[pc+1]) != 0:
      return value(memory[pc+2])
    return pc+3
  of 8: # jf a b -- if <a> is zero, jump to <b>
    if value(memory[pc+1]) == 0:
      return value(memory[pc+2])
    return pc+3
  of 9: # add a b c -- assign into <a> the sum of <b> and <c> (modulo 32768)
    let v = value(memory[pc+2]) + value(memory[pc+3])
    reg[memory[pc+1]-LIMIT] = v mod LIMIT
    return pc+4
  of 10: # mult a b c -- store into <a> the product of <b> and <c> (modulo 32768)
    let v = value(memory[pc+2]) * value(memory[pc+3])
    reg[memory[pc+1]-LIMIT] = v mod LIMIT
    return pc+4
  of 11: # mod a b c -- store into <a> the remainder of <b> divided by <c>
    let v = value(memory[pc+2]) mod value(memory[pc+3])
    reg[memory[pc+1]-LIMIT] = v
    return pc+4
  of 12: # and a b c -- stores into <a> the bitwise and of <b> and <c>
    let v = value(memory[pc+2]) and value(memory[pc+3])
    reg[memory[pc+1]-LIMIT] = v
    return pc+4
  of 13: # or a b c -- stores into <a> the bitwise or of <b> and <c>
    let v = value(memory[pc+2]) or value(memory[pc+3])
    reg[memory[pc+1]-LIMIT] = v
    return pc+4
  of 14: # not a b -- stores 15-bit bitwise inverse of <b> in <a>
    let v = not value(memory[pc+2])
    reg[memory[pc+1]-LIMIT] = v and 0x7FFF
    return pc+3
  of 15: # rmem a b -- read memory at address <b> and write it to <a>
    let v = value(memory[pc+2])
    let w = memory[v]
    reg[memory[pc+1]-LIMIT] = w
    return pc+3
  of 16: # wmem a b -- write the value from <b> into memory at address <a>
    let v = value(memory[pc+2])
    let a = value(memory[pc+1])
    memory[a] = v
    return pc+3
  of 17: # call a -- write the address of the next instruction to the stack and jump to <a>
    stack.add pc+2
    return value(memory[pc+1]) # new pc
  of 18: # ret -- remove the top element from the stack and jump to it; empty stack = halt
    if stack.len == 0: echo "ret with empty stack"; return -1
    let c = stack[^1]
    stack.del(stack.len-1)
    return c # new pc
  of 19: # out a -- write the character represented by ascii code <a> to the terminal
    let c = value(memory[pc+1])
    if c==10: echo outbuf; outbuf = ""
    else: outbuf &= chr(c)
    return pc+2
  of 20: # in a -- read a character from the terminal and write its ascii code to <a>
    # it can be assumed that once input starts, it will continue until a newline is encountered;
    # this means that you can safely read whole lines from the keyboard and trust that
    # they will be fully read
    if incnt==-1 or (incnt>=0 and inpos>=incnt):
      inbuf = readLine(stdin)
      incnt = inbuf.len
      inpos = 0
    let a = value(memory[pc+1])
    memory[a] = inbuf[inpos]
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

var sz = read_into_memory( 0, "challenge.bin" )
#fill_memory( sz, LIMIT-sz, 0 )
run( 0 )

# vhiYqHRHsOct - start breathing
# QbtRsOmZrHKg - self-test passed
