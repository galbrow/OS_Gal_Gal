
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	93013103          	ld	sp,-1744(sp) # 80008930 <_GLOBAL_OFFSET_TABLE_+0x8>
    80000008:	6505                	lui	a0,0x1
    8000000a:	f14025f3          	csrr	a1,mhartid
    8000000e:	0585                	addi	a1,a1,1
    80000010:	02b50533          	mul	a0,a0,a1
    80000014:	912a                	add	sp,sp,a0
    80000016:	078000ef          	jal	ra,8000008e <start>

000000008000001a <spin>:
    8000001a:	a001                	j	8000001a <spin>

000000008000001c <timerinit>:
// which arrive at timervec in kernelvec.S,
// which turns them into software interrupts for
// devintr() in trap.c.
void
timerinit()
{
    8000001c:	1141                	addi	sp,sp,-16
    8000001e:	e422                	sd	s0,8(sp)
    80000020:	0800                	addi	s0,sp,16
// which hart (core) is this?
static inline uint64
r_mhartid()
{
  uint64 x;
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    80000022:	f14027f3          	csrr	a5,mhartid
  // each CPU has a separate source of timer interrupts.
  int id = r_mhartid();
    80000026:	0007869b          	sext.w	a3,a5

  // ask the CLINT for a timer interrupt.
  int interval = 1000000; // cycles; about 1/10th second in qemu.
  *(uint64*)CLINT_MTIMECMP(id) = *(uint64*)CLINT_MTIME + interval;
    8000002a:	0037979b          	slliw	a5,a5,0x3
    8000002e:	02004737          	lui	a4,0x2004
    80000032:	97ba                	add	a5,a5,a4
    80000034:	0200c737          	lui	a4,0x200c
    80000038:	ff873583          	ld	a1,-8(a4) # 200bff8 <_entry-0x7dff4008>
    8000003c:	000f4637          	lui	a2,0xf4
    80000040:	24060613          	addi	a2,a2,576 # f4240 <_entry-0x7ff0bdc0>
    80000044:	95b2                	add	a1,a1,a2
    80000046:	e38c                	sd	a1,0(a5)

  // prepare information in scratch[] for timervec.
  // scratch[0..2] : space for timervec to save registers.
  // scratch[3] : address of CLINT MTIMECMP register.
  // scratch[4] : desired interval (in cycles) between timer interrupts.
  uint64 *scratch = &timer_scratch[id][0];
    80000048:	00269713          	slli	a4,a3,0x2
    8000004c:	9736                	add	a4,a4,a3
    8000004e:	00371693          	slli	a3,a4,0x3
    80000052:	00009717          	auipc	a4,0x9
    80000056:	00e70713          	addi	a4,a4,14 # 80009060 <timer_scratch>
    8000005a:	9736                	add	a4,a4,a3
  scratch[3] = CLINT_MTIMECMP(id);
    8000005c:	ef1c                	sd	a5,24(a4)
  scratch[4] = interval;
    8000005e:	f310                	sd	a2,32(a4)
}

static inline void 
w_mscratch(uint64 x)
{
  asm volatile("csrw mscratch, %0" : : "r" (x));
    80000060:	34071073          	csrw	mscratch,a4
  asm volatile("csrw mtvec, %0" : : "r" (x));
    80000064:	00006797          	auipc	a5,0x6
    80000068:	03c78793          	addi	a5,a5,60 # 800060a0 <timervec>
    8000006c:	30579073          	csrw	mtvec,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000070:	300027f3          	csrr	a5,mstatus

  // set the machine-mode trap handler.
  w_mtvec((uint64)timervec);

  // enable machine-mode interrupts.
  w_mstatus(r_mstatus() | MSTATUS_MIE);
    80000074:	0087e793          	ori	a5,a5,8
  asm volatile("csrw mstatus, %0" : : "r" (x));
    80000078:	30079073          	csrw	mstatus,a5
  asm volatile("csrr %0, mie" : "=r" (x) );
    8000007c:	304027f3          	csrr	a5,mie

  // enable machine-mode timer interrupts.
  w_mie(r_mie() | MIE_MTIE);
    80000080:	0807e793          	ori	a5,a5,128
  asm volatile("csrw mie, %0" : : "r" (x));
    80000084:	30479073          	csrw	mie,a5
}
    80000088:	6422                	ld	s0,8(sp)
    8000008a:	0141                	addi	sp,sp,16
    8000008c:	8082                	ret

000000008000008e <start>:
{
    8000008e:	1141                	addi	sp,sp,-16
    80000090:	e406                	sd	ra,8(sp)
    80000092:	e022                	sd	s0,0(sp)
    80000094:	0800                	addi	s0,sp,16
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000096:	300027f3          	csrr	a5,mstatus
  x &= ~MSTATUS_MPP_MASK;
    8000009a:	7779                	lui	a4,0xffffe
    8000009c:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffd87ff>
    800000a0:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    800000a2:	6705                	lui	a4,0x1
    800000a4:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a8:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000aa:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000ae:	00001797          	auipc	a5,0x1
    800000b2:	de078793          	addi	a5,a5,-544 # 80000e8e <main>
    800000b6:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    800000ba:	4781                	li	a5,0
    800000bc:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    800000c0:	67c1                	lui	a5,0x10
    800000c2:	17fd                	addi	a5,a5,-1
    800000c4:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    800000c8:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    800000cc:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    800000d0:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    800000d4:	10479073          	csrw	sie,a5
  asm volatile("csrw pmpaddr0, %0" : : "r" (x));
    800000d8:	57fd                	li	a5,-1
    800000da:	83a9                	srli	a5,a5,0xa
    800000dc:	3b079073          	csrw	pmpaddr0,a5
  asm volatile("csrw pmpcfg0, %0" : : "r" (x));
    800000e0:	47bd                	li	a5,15
    800000e2:	3a079073          	csrw	pmpcfg0,a5
  timerinit();
    800000e6:	00000097          	auipc	ra,0x0
    800000ea:	f36080e7          	jalr	-202(ra) # 8000001c <timerinit>
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800000ee:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    800000f2:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    800000f4:	823e                	mv	tp,a5
  asm volatile("mret");
    800000f6:	30200073          	mret
}
    800000fa:	60a2                	ld	ra,8(sp)
    800000fc:	6402                	ld	s0,0(sp)
    800000fe:	0141                	addi	sp,sp,16
    80000100:	8082                	ret

0000000080000102 <consolewrite>:
//
// user write()s to the console go here.
//
int
consolewrite(int user_src, uint64 src, int n)
{
    80000102:	715d                	addi	sp,sp,-80
    80000104:	e486                	sd	ra,72(sp)
    80000106:	e0a2                	sd	s0,64(sp)
    80000108:	fc26                	sd	s1,56(sp)
    8000010a:	f84a                	sd	s2,48(sp)
    8000010c:	f44e                	sd	s3,40(sp)
    8000010e:	f052                	sd	s4,32(sp)
    80000110:	ec56                	sd	s5,24(sp)
    80000112:	0880                	addi	s0,sp,80
  int i;

  for(i = 0; i < n; i++){
    80000114:	04c05663          	blez	a2,80000160 <consolewrite+0x5e>
    80000118:	8a2a                	mv	s4,a0
    8000011a:	84ae                	mv	s1,a1
    8000011c:	89b2                	mv	s3,a2
    8000011e:	4901                	li	s2,0
    char c;
    if(either_copyin(&c, user_src, src+i, 1) == -1)
    80000120:	5afd                	li	s5,-1
    80000122:	4685                	li	a3,1
    80000124:	8626                	mv	a2,s1
    80000126:	85d2                	mv	a1,s4
    80000128:	fbf40513          	addi	a0,s0,-65
    8000012c:	00003097          	auipc	ra,0x3
    80000130:	854080e7          	jalr	-1964(ra) # 80002980 <either_copyin>
    80000134:	01550c63          	beq	a0,s5,8000014c <consolewrite+0x4a>
      break;
    uartputc(c);
    80000138:	fbf44503          	lbu	a0,-65(s0)
    8000013c:	00000097          	auipc	ra,0x0
    80000140:	78e080e7          	jalr	1934(ra) # 800008ca <uartputc>
  for(i = 0; i < n; i++){
    80000144:	2905                	addiw	s2,s2,1
    80000146:	0485                	addi	s1,s1,1
    80000148:	fd299de3          	bne	s3,s2,80000122 <consolewrite+0x20>
  }

  return i;
}
    8000014c:	854a                	mv	a0,s2
    8000014e:	60a6                	ld	ra,72(sp)
    80000150:	6406                	ld	s0,64(sp)
    80000152:	74e2                	ld	s1,56(sp)
    80000154:	7942                	ld	s2,48(sp)
    80000156:	79a2                	ld	s3,40(sp)
    80000158:	7a02                	ld	s4,32(sp)
    8000015a:	6ae2                	ld	s5,24(sp)
    8000015c:	6161                	addi	sp,sp,80
    8000015e:	8082                	ret
  for(i = 0; i < n; i++){
    80000160:	4901                	li	s2,0
    80000162:	b7ed                	j	8000014c <consolewrite+0x4a>

0000000080000164 <consoleread>:
// user_dist indicates whether dst is a user
// or kernel address.
//
int
consoleread(int user_dst, uint64 dst, int n)
{
    80000164:	7119                	addi	sp,sp,-128
    80000166:	fc86                	sd	ra,120(sp)
    80000168:	f8a2                	sd	s0,112(sp)
    8000016a:	f4a6                	sd	s1,104(sp)
    8000016c:	f0ca                	sd	s2,96(sp)
    8000016e:	ecce                	sd	s3,88(sp)
    80000170:	e8d2                	sd	s4,80(sp)
    80000172:	e4d6                	sd	s5,72(sp)
    80000174:	e0da                	sd	s6,64(sp)
    80000176:	fc5e                	sd	s7,56(sp)
    80000178:	f862                	sd	s8,48(sp)
    8000017a:	f466                	sd	s9,40(sp)
    8000017c:	f06a                	sd	s10,32(sp)
    8000017e:	ec6e                	sd	s11,24(sp)
    80000180:	0100                	addi	s0,sp,128
    80000182:	8b2a                	mv	s6,a0
    80000184:	8aae                	mv	s5,a1
    80000186:	8a32                	mv	s4,a2
  uint target;
  int c;
  char cbuf;

  target = n;
    80000188:	00060b9b          	sext.w	s7,a2
  acquire(&cons.lock);
    8000018c:	00011517          	auipc	a0,0x11
    80000190:	01450513          	addi	a0,a0,20 # 800111a0 <cons>
    80000194:	00001097          	auipc	ra,0x1
    80000198:	a50080e7          	jalr	-1456(ra) # 80000be4 <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    8000019c:	00011497          	auipc	s1,0x11
    800001a0:	00448493          	addi	s1,s1,4 # 800111a0 <cons>
      if(myproc()->killed){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001a4:	89a6                	mv	s3,s1
    800001a6:	00011917          	auipc	s2,0x11
    800001aa:	09290913          	addi	s2,s2,146 # 80011238 <cons+0x98>
    }

    c = cons.buf[cons.r++ % INPUT_BUF];

    if(c == C('D')){  // end-of-file
    800001ae:	4c91                	li	s9,4
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    800001b0:	5d7d                	li	s10,-1
      break;

    dst++;
    --n;

    if(c == '\n'){
    800001b2:	4da9                	li	s11,10
  while(n > 0){
    800001b4:	07405863          	blez	s4,80000224 <consoleread+0xc0>
    while(cons.r == cons.w){
    800001b8:	0984a783          	lw	a5,152(s1)
    800001bc:	09c4a703          	lw	a4,156(s1)
    800001c0:	02f71463          	bne	a4,a5,800001e8 <consoleread+0x84>
      if(myproc()->killed){
    800001c4:	00002097          	auipc	ra,0x2
    800001c8:	804080e7          	jalr	-2044(ra) # 800019c8 <myproc>
    800001cc:	551c                	lw	a5,40(a0)
    800001ce:	e7b5                	bnez	a5,8000023a <consoleread+0xd6>
      sleep(&cons.r, &cons.lock);
    800001d0:	85ce                	mv	a1,s3
    800001d2:	854a                	mv	a0,s2
    800001d4:	00002097          	auipc	ra,0x2
    800001d8:	1a6080e7          	jalr	422(ra) # 8000237a <sleep>
    while(cons.r == cons.w){
    800001dc:	0984a783          	lw	a5,152(s1)
    800001e0:	09c4a703          	lw	a4,156(s1)
    800001e4:	fef700e3          	beq	a4,a5,800001c4 <consoleread+0x60>
    c = cons.buf[cons.r++ % INPUT_BUF];
    800001e8:	0017871b          	addiw	a4,a5,1
    800001ec:	08e4ac23          	sw	a4,152(s1)
    800001f0:	07f7f713          	andi	a4,a5,127
    800001f4:	9726                	add	a4,a4,s1
    800001f6:	01874703          	lbu	a4,24(a4)
    800001fa:	00070c1b          	sext.w	s8,a4
    if(c == C('D')){  // end-of-file
    800001fe:	079c0663          	beq	s8,s9,8000026a <consoleread+0x106>
    cbuf = c;
    80000202:	f8e407a3          	sb	a4,-113(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    80000206:	4685                	li	a3,1
    80000208:	f8f40613          	addi	a2,s0,-113
    8000020c:	85d6                	mv	a1,s5
    8000020e:	855a                	mv	a0,s6
    80000210:	00002097          	auipc	ra,0x2
    80000214:	71a080e7          	jalr	1818(ra) # 8000292a <either_copyout>
    80000218:	01a50663          	beq	a0,s10,80000224 <consoleread+0xc0>
    dst++;
    8000021c:	0a85                	addi	s5,s5,1
    --n;
    8000021e:	3a7d                	addiw	s4,s4,-1
    if(c == '\n'){
    80000220:	f9bc1ae3          	bne	s8,s11,800001b4 <consoleread+0x50>
      // a whole line has arrived, return to
      // the user-level read().
      break;
    }
  }
  release(&cons.lock);
    80000224:	00011517          	auipc	a0,0x11
    80000228:	f7c50513          	addi	a0,a0,-132 # 800111a0 <cons>
    8000022c:	00001097          	auipc	ra,0x1
    80000230:	a6c080e7          	jalr	-1428(ra) # 80000c98 <release>

  return target - n;
    80000234:	414b853b          	subw	a0,s7,s4
    80000238:	a811                	j	8000024c <consoleread+0xe8>
        release(&cons.lock);
    8000023a:	00011517          	auipc	a0,0x11
    8000023e:	f6650513          	addi	a0,a0,-154 # 800111a0 <cons>
    80000242:	00001097          	auipc	ra,0x1
    80000246:	a56080e7          	jalr	-1450(ra) # 80000c98 <release>
        return -1;
    8000024a:	557d                	li	a0,-1
}
    8000024c:	70e6                	ld	ra,120(sp)
    8000024e:	7446                	ld	s0,112(sp)
    80000250:	74a6                	ld	s1,104(sp)
    80000252:	7906                	ld	s2,96(sp)
    80000254:	69e6                	ld	s3,88(sp)
    80000256:	6a46                	ld	s4,80(sp)
    80000258:	6aa6                	ld	s5,72(sp)
    8000025a:	6b06                	ld	s6,64(sp)
    8000025c:	7be2                	ld	s7,56(sp)
    8000025e:	7c42                	ld	s8,48(sp)
    80000260:	7ca2                	ld	s9,40(sp)
    80000262:	7d02                	ld	s10,32(sp)
    80000264:	6de2                	ld	s11,24(sp)
    80000266:	6109                	addi	sp,sp,128
    80000268:	8082                	ret
      if(n < target){
    8000026a:	000a071b          	sext.w	a4,s4
    8000026e:	fb777be3          	bgeu	a4,s7,80000224 <consoleread+0xc0>
        cons.r--;
    80000272:	00011717          	auipc	a4,0x11
    80000276:	fcf72323          	sw	a5,-58(a4) # 80011238 <cons+0x98>
    8000027a:	b76d                	j	80000224 <consoleread+0xc0>

000000008000027c <consputc>:
{
    8000027c:	1141                	addi	sp,sp,-16
    8000027e:	e406                	sd	ra,8(sp)
    80000280:	e022                	sd	s0,0(sp)
    80000282:	0800                	addi	s0,sp,16
  if(c == BACKSPACE){
    80000284:	10000793          	li	a5,256
    80000288:	00f50a63          	beq	a0,a5,8000029c <consputc+0x20>
    uartputc_sync(c);
    8000028c:	00000097          	auipc	ra,0x0
    80000290:	564080e7          	jalr	1380(ra) # 800007f0 <uartputc_sync>
}
    80000294:	60a2                	ld	ra,8(sp)
    80000296:	6402                	ld	s0,0(sp)
    80000298:	0141                	addi	sp,sp,16
    8000029a:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    8000029c:	4521                	li	a0,8
    8000029e:	00000097          	auipc	ra,0x0
    800002a2:	552080e7          	jalr	1362(ra) # 800007f0 <uartputc_sync>
    800002a6:	02000513          	li	a0,32
    800002aa:	00000097          	auipc	ra,0x0
    800002ae:	546080e7          	jalr	1350(ra) # 800007f0 <uartputc_sync>
    800002b2:	4521                	li	a0,8
    800002b4:	00000097          	auipc	ra,0x0
    800002b8:	53c080e7          	jalr	1340(ra) # 800007f0 <uartputc_sync>
    800002bc:	bfe1                	j	80000294 <consputc+0x18>

00000000800002be <consoleintr>:
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
    800002be:	1101                	addi	sp,sp,-32
    800002c0:	ec06                	sd	ra,24(sp)
    800002c2:	e822                	sd	s0,16(sp)
    800002c4:	e426                	sd	s1,8(sp)
    800002c6:	e04a                	sd	s2,0(sp)
    800002c8:	1000                	addi	s0,sp,32
    800002ca:	84aa                	mv	s1,a0
  acquire(&cons.lock);
    800002cc:	00011517          	auipc	a0,0x11
    800002d0:	ed450513          	addi	a0,a0,-300 # 800111a0 <cons>
    800002d4:	00001097          	auipc	ra,0x1
    800002d8:	910080e7          	jalr	-1776(ra) # 80000be4 <acquire>

  switch(c){
    800002dc:	47d5                	li	a5,21
    800002de:	0af48663          	beq	s1,a5,8000038a <consoleintr+0xcc>
    800002e2:	0297ca63          	blt	a5,s1,80000316 <consoleintr+0x58>
    800002e6:	47a1                	li	a5,8
    800002e8:	0ef48763          	beq	s1,a5,800003d6 <consoleintr+0x118>
    800002ec:	47c1                	li	a5,16
    800002ee:	10f49a63          	bne	s1,a5,80000402 <consoleintr+0x144>
  case C('P'):  // Print process list.
    procdump();
    800002f2:	00002097          	auipc	ra,0x2
    800002f6:	6e4080e7          	jalr	1764(ra) # 800029d6 <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002fa:	00011517          	auipc	a0,0x11
    800002fe:	ea650513          	addi	a0,a0,-346 # 800111a0 <cons>
    80000302:	00001097          	auipc	ra,0x1
    80000306:	996080e7          	jalr	-1642(ra) # 80000c98 <release>
}
    8000030a:	60e2                	ld	ra,24(sp)
    8000030c:	6442                	ld	s0,16(sp)
    8000030e:	64a2                	ld	s1,8(sp)
    80000310:	6902                	ld	s2,0(sp)
    80000312:	6105                	addi	sp,sp,32
    80000314:	8082                	ret
  switch(c){
    80000316:	07f00793          	li	a5,127
    8000031a:	0af48e63          	beq	s1,a5,800003d6 <consoleintr+0x118>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    8000031e:	00011717          	auipc	a4,0x11
    80000322:	e8270713          	addi	a4,a4,-382 # 800111a0 <cons>
    80000326:	0a072783          	lw	a5,160(a4)
    8000032a:	09872703          	lw	a4,152(a4)
    8000032e:	9f99                	subw	a5,a5,a4
    80000330:	07f00713          	li	a4,127
    80000334:	fcf763e3          	bltu	a4,a5,800002fa <consoleintr+0x3c>
      c = (c == '\r') ? '\n' : c;
    80000338:	47b5                	li	a5,13
    8000033a:	0cf48763          	beq	s1,a5,80000408 <consoleintr+0x14a>
      consputc(c);
    8000033e:	8526                	mv	a0,s1
    80000340:	00000097          	auipc	ra,0x0
    80000344:	f3c080e7          	jalr	-196(ra) # 8000027c <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000348:	00011797          	auipc	a5,0x11
    8000034c:	e5878793          	addi	a5,a5,-424 # 800111a0 <cons>
    80000350:	0a07a703          	lw	a4,160(a5)
    80000354:	0017069b          	addiw	a3,a4,1
    80000358:	0006861b          	sext.w	a2,a3
    8000035c:	0ad7a023          	sw	a3,160(a5)
    80000360:	07f77713          	andi	a4,a4,127
    80000364:	97ba                	add	a5,a5,a4
    80000366:	00978c23          	sb	s1,24(a5)
      if(c == '\n' || c == C('D') || cons.e == cons.r+INPUT_BUF){
    8000036a:	47a9                	li	a5,10
    8000036c:	0cf48563          	beq	s1,a5,80000436 <consoleintr+0x178>
    80000370:	4791                	li	a5,4
    80000372:	0cf48263          	beq	s1,a5,80000436 <consoleintr+0x178>
    80000376:	00011797          	auipc	a5,0x11
    8000037a:	ec27a783          	lw	a5,-318(a5) # 80011238 <cons+0x98>
    8000037e:	0807879b          	addiw	a5,a5,128
    80000382:	f6f61ce3          	bne	a2,a5,800002fa <consoleintr+0x3c>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000386:	863e                	mv	a2,a5
    80000388:	a07d                	j	80000436 <consoleintr+0x178>
    while(cons.e != cons.w &&
    8000038a:	00011717          	auipc	a4,0x11
    8000038e:	e1670713          	addi	a4,a4,-490 # 800111a0 <cons>
    80000392:	0a072783          	lw	a5,160(a4)
    80000396:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    8000039a:	00011497          	auipc	s1,0x11
    8000039e:	e0648493          	addi	s1,s1,-506 # 800111a0 <cons>
    while(cons.e != cons.w &&
    800003a2:	4929                	li	s2,10
    800003a4:	f4f70be3          	beq	a4,a5,800002fa <consoleintr+0x3c>
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    800003a8:	37fd                	addiw	a5,a5,-1
    800003aa:	07f7f713          	andi	a4,a5,127
    800003ae:	9726                	add	a4,a4,s1
    while(cons.e != cons.w &&
    800003b0:	01874703          	lbu	a4,24(a4)
    800003b4:	f52703e3          	beq	a4,s2,800002fa <consoleintr+0x3c>
      cons.e--;
    800003b8:	0af4a023          	sw	a5,160(s1)
      consputc(BACKSPACE);
    800003bc:	10000513          	li	a0,256
    800003c0:	00000097          	auipc	ra,0x0
    800003c4:	ebc080e7          	jalr	-324(ra) # 8000027c <consputc>
    while(cons.e != cons.w &&
    800003c8:	0a04a783          	lw	a5,160(s1)
    800003cc:	09c4a703          	lw	a4,156(s1)
    800003d0:	fcf71ce3          	bne	a4,a5,800003a8 <consoleintr+0xea>
    800003d4:	b71d                	j	800002fa <consoleintr+0x3c>
    if(cons.e != cons.w){
    800003d6:	00011717          	auipc	a4,0x11
    800003da:	dca70713          	addi	a4,a4,-566 # 800111a0 <cons>
    800003de:	0a072783          	lw	a5,160(a4)
    800003e2:	09c72703          	lw	a4,156(a4)
    800003e6:	f0f70ae3          	beq	a4,a5,800002fa <consoleintr+0x3c>
      cons.e--;
    800003ea:	37fd                	addiw	a5,a5,-1
    800003ec:	00011717          	auipc	a4,0x11
    800003f0:	e4f72a23          	sw	a5,-428(a4) # 80011240 <cons+0xa0>
      consputc(BACKSPACE);
    800003f4:	10000513          	li	a0,256
    800003f8:	00000097          	auipc	ra,0x0
    800003fc:	e84080e7          	jalr	-380(ra) # 8000027c <consputc>
    80000400:	bded                	j	800002fa <consoleintr+0x3c>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    80000402:	ee048ce3          	beqz	s1,800002fa <consoleintr+0x3c>
    80000406:	bf21                	j	8000031e <consoleintr+0x60>
      consputc(c);
    80000408:	4529                	li	a0,10
    8000040a:	00000097          	auipc	ra,0x0
    8000040e:	e72080e7          	jalr	-398(ra) # 8000027c <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000412:	00011797          	auipc	a5,0x11
    80000416:	d8e78793          	addi	a5,a5,-626 # 800111a0 <cons>
    8000041a:	0a07a703          	lw	a4,160(a5)
    8000041e:	0017069b          	addiw	a3,a4,1
    80000422:	0006861b          	sext.w	a2,a3
    80000426:	0ad7a023          	sw	a3,160(a5)
    8000042a:	07f77713          	andi	a4,a4,127
    8000042e:	97ba                	add	a5,a5,a4
    80000430:	4729                	li	a4,10
    80000432:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    80000436:	00011797          	auipc	a5,0x11
    8000043a:	e0c7a323          	sw	a2,-506(a5) # 8001123c <cons+0x9c>
        wakeup(&cons.r);
    8000043e:	00011517          	auipc	a0,0x11
    80000442:	dfa50513          	addi	a0,a0,-518 # 80011238 <cons+0x98>
    80000446:	00002097          	auipc	ra,0x2
    8000044a:	0d4080e7          	jalr	212(ra) # 8000251a <wakeup>
    8000044e:	b575                	j	800002fa <consoleintr+0x3c>

0000000080000450 <consoleinit>:

void
consoleinit(void)
{
    80000450:	1141                	addi	sp,sp,-16
    80000452:	e406                	sd	ra,8(sp)
    80000454:	e022                	sd	s0,0(sp)
    80000456:	0800                	addi	s0,sp,16
  initlock(&cons.lock, "cons");
    80000458:	00008597          	auipc	a1,0x8
    8000045c:	bb858593          	addi	a1,a1,-1096 # 80008010 <etext+0x10>
    80000460:	00011517          	auipc	a0,0x11
    80000464:	d4050513          	addi	a0,a0,-704 # 800111a0 <cons>
    80000468:	00000097          	auipc	ra,0x0
    8000046c:	6ec080e7          	jalr	1772(ra) # 80000b54 <initlock>

  uartinit();
    80000470:	00000097          	auipc	ra,0x0
    80000474:	330080e7          	jalr	816(ra) # 800007a0 <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000478:	00021797          	auipc	a5,0x21
    8000047c:	6c078793          	addi	a5,a5,1728 # 80021b38 <devsw>
    80000480:	00000717          	auipc	a4,0x0
    80000484:	ce470713          	addi	a4,a4,-796 # 80000164 <consoleread>
    80000488:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    8000048a:	00000717          	auipc	a4,0x0
    8000048e:	c7870713          	addi	a4,a4,-904 # 80000102 <consolewrite>
    80000492:	ef98                	sd	a4,24(a5)
}
    80000494:	60a2                	ld	ra,8(sp)
    80000496:	6402                	ld	s0,0(sp)
    80000498:	0141                	addi	sp,sp,16
    8000049a:	8082                	ret

000000008000049c <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    8000049c:	7179                	addi	sp,sp,-48
    8000049e:	f406                	sd	ra,40(sp)
    800004a0:	f022                	sd	s0,32(sp)
    800004a2:	ec26                	sd	s1,24(sp)
    800004a4:	e84a                	sd	s2,16(sp)
    800004a6:	1800                	addi	s0,sp,48
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    800004a8:	c219                	beqz	a2,800004ae <printint+0x12>
    800004aa:	08054663          	bltz	a0,80000536 <printint+0x9a>
    x = -xx;
  else
    x = xx;
    800004ae:	2501                	sext.w	a0,a0
    800004b0:	4881                	li	a7,0
    800004b2:	fd040693          	addi	a3,s0,-48

  i = 0;
    800004b6:	4701                	li	a4,0
  do {
    buf[i++] = digits[x % base];
    800004b8:	2581                	sext.w	a1,a1
    800004ba:	00008617          	auipc	a2,0x8
    800004be:	b8660613          	addi	a2,a2,-1146 # 80008040 <digits>
    800004c2:	883a                	mv	a6,a4
    800004c4:	2705                	addiw	a4,a4,1
    800004c6:	02b577bb          	remuw	a5,a0,a1
    800004ca:	1782                	slli	a5,a5,0x20
    800004cc:	9381                	srli	a5,a5,0x20
    800004ce:	97b2                	add	a5,a5,a2
    800004d0:	0007c783          	lbu	a5,0(a5)
    800004d4:	00f68023          	sb	a5,0(a3)
  } while((x /= base) != 0);
    800004d8:	0005079b          	sext.w	a5,a0
    800004dc:	02b5553b          	divuw	a0,a0,a1
    800004e0:	0685                	addi	a3,a3,1
    800004e2:	feb7f0e3          	bgeu	a5,a1,800004c2 <printint+0x26>

  if(sign)
    800004e6:	00088b63          	beqz	a7,800004fc <printint+0x60>
    buf[i++] = '-';
    800004ea:	fe040793          	addi	a5,s0,-32
    800004ee:	973e                	add	a4,a4,a5
    800004f0:	02d00793          	li	a5,45
    800004f4:	fef70823          	sb	a5,-16(a4)
    800004f8:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
    800004fc:	02e05763          	blez	a4,8000052a <printint+0x8e>
    80000500:	fd040793          	addi	a5,s0,-48
    80000504:	00e784b3          	add	s1,a5,a4
    80000508:	fff78913          	addi	s2,a5,-1
    8000050c:	993a                	add	s2,s2,a4
    8000050e:	377d                	addiw	a4,a4,-1
    80000510:	1702                	slli	a4,a4,0x20
    80000512:	9301                	srli	a4,a4,0x20
    80000514:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    80000518:	fff4c503          	lbu	a0,-1(s1)
    8000051c:	00000097          	auipc	ra,0x0
    80000520:	d60080e7          	jalr	-672(ra) # 8000027c <consputc>
  while(--i >= 0)
    80000524:	14fd                	addi	s1,s1,-1
    80000526:	ff2499e3          	bne	s1,s2,80000518 <printint+0x7c>
}
    8000052a:	70a2                	ld	ra,40(sp)
    8000052c:	7402                	ld	s0,32(sp)
    8000052e:	64e2                	ld	s1,24(sp)
    80000530:	6942                	ld	s2,16(sp)
    80000532:	6145                	addi	sp,sp,48
    80000534:	8082                	ret
    x = -xx;
    80000536:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    8000053a:	4885                	li	a7,1
    x = -xx;
    8000053c:	bf9d                	j	800004b2 <printint+0x16>

000000008000053e <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
    8000053e:	1101                	addi	sp,sp,-32
    80000540:	ec06                	sd	ra,24(sp)
    80000542:	e822                	sd	s0,16(sp)
    80000544:	e426                	sd	s1,8(sp)
    80000546:	1000                	addi	s0,sp,32
    80000548:	84aa                	mv	s1,a0
  pr.locking = 0;
    8000054a:	00011797          	auipc	a5,0x11
    8000054e:	d007ab23          	sw	zero,-746(a5) # 80011260 <pr+0x18>
  printf("panic: ");
    80000552:	00008517          	auipc	a0,0x8
    80000556:	ac650513          	addi	a0,a0,-1338 # 80008018 <etext+0x18>
    8000055a:	00000097          	auipc	ra,0x0
    8000055e:	02e080e7          	jalr	46(ra) # 80000588 <printf>
  printf(s);
    80000562:	8526                	mv	a0,s1
    80000564:	00000097          	auipc	ra,0x0
    80000568:	024080e7          	jalr	36(ra) # 80000588 <printf>
  printf("\n");
    8000056c:	00008517          	auipc	a0,0x8
    80000570:	dbc50513          	addi	a0,a0,-580 # 80008328 <digits+0x2e8>
    80000574:	00000097          	auipc	ra,0x0
    80000578:	014080e7          	jalr	20(ra) # 80000588 <printf>
  panicked = 1; // freeze uart output from other CPUs
    8000057c:	4785                	li	a5,1
    8000057e:	00009717          	auipc	a4,0x9
    80000582:	a8f72123          	sw	a5,-1406(a4) # 80009000 <panicked>
  for(;;)
    80000586:	a001                	j	80000586 <panic+0x48>

0000000080000588 <printf>:
{
    80000588:	7131                	addi	sp,sp,-192
    8000058a:	fc86                	sd	ra,120(sp)
    8000058c:	f8a2                	sd	s0,112(sp)
    8000058e:	f4a6                	sd	s1,104(sp)
    80000590:	f0ca                	sd	s2,96(sp)
    80000592:	ecce                	sd	s3,88(sp)
    80000594:	e8d2                	sd	s4,80(sp)
    80000596:	e4d6                	sd	s5,72(sp)
    80000598:	e0da                	sd	s6,64(sp)
    8000059a:	fc5e                	sd	s7,56(sp)
    8000059c:	f862                	sd	s8,48(sp)
    8000059e:	f466                	sd	s9,40(sp)
    800005a0:	f06a                	sd	s10,32(sp)
    800005a2:	ec6e                	sd	s11,24(sp)
    800005a4:	0100                	addi	s0,sp,128
    800005a6:	8a2a                	mv	s4,a0
    800005a8:	e40c                	sd	a1,8(s0)
    800005aa:	e810                	sd	a2,16(s0)
    800005ac:	ec14                	sd	a3,24(s0)
    800005ae:	f018                	sd	a4,32(s0)
    800005b0:	f41c                	sd	a5,40(s0)
    800005b2:	03043823          	sd	a6,48(s0)
    800005b6:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    800005ba:	00011d97          	auipc	s11,0x11
    800005be:	ca6dad83          	lw	s11,-858(s11) # 80011260 <pr+0x18>
  if(locking)
    800005c2:	020d9b63          	bnez	s11,800005f8 <printf+0x70>
  if (fmt == 0)
    800005c6:	040a0263          	beqz	s4,8000060a <printf+0x82>
  va_start(ap, fmt);
    800005ca:	00840793          	addi	a5,s0,8
    800005ce:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800005d2:	000a4503          	lbu	a0,0(s4)
    800005d6:	16050263          	beqz	a0,8000073a <printf+0x1b2>
    800005da:	4481                	li	s1,0
    if(c != '%'){
    800005dc:	02500a93          	li	s5,37
    switch(c){
    800005e0:	07000b13          	li	s6,112
  consputc('x');
    800005e4:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800005e6:	00008b97          	auipc	s7,0x8
    800005ea:	a5ab8b93          	addi	s7,s7,-1446 # 80008040 <digits>
    switch(c){
    800005ee:	07300c93          	li	s9,115
    800005f2:	06400c13          	li	s8,100
    800005f6:	a82d                	j	80000630 <printf+0xa8>
    acquire(&pr.lock);
    800005f8:	00011517          	auipc	a0,0x11
    800005fc:	c5050513          	addi	a0,a0,-944 # 80011248 <pr>
    80000600:	00000097          	auipc	ra,0x0
    80000604:	5e4080e7          	jalr	1508(ra) # 80000be4 <acquire>
    80000608:	bf7d                	j	800005c6 <printf+0x3e>
    panic("null fmt");
    8000060a:	00008517          	auipc	a0,0x8
    8000060e:	a1e50513          	addi	a0,a0,-1506 # 80008028 <etext+0x28>
    80000612:	00000097          	auipc	ra,0x0
    80000616:	f2c080e7          	jalr	-212(ra) # 8000053e <panic>
      consputc(c);
    8000061a:	00000097          	auipc	ra,0x0
    8000061e:	c62080e7          	jalr	-926(ra) # 8000027c <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    80000622:	2485                	addiw	s1,s1,1
    80000624:	009a07b3          	add	a5,s4,s1
    80000628:	0007c503          	lbu	a0,0(a5)
    8000062c:	10050763          	beqz	a0,8000073a <printf+0x1b2>
    if(c != '%'){
    80000630:	ff5515e3          	bne	a0,s5,8000061a <printf+0x92>
    c = fmt[++i] & 0xff;
    80000634:	2485                	addiw	s1,s1,1
    80000636:	009a07b3          	add	a5,s4,s1
    8000063a:	0007c783          	lbu	a5,0(a5)
    8000063e:	0007891b          	sext.w	s2,a5
    if(c == 0)
    80000642:	cfe5                	beqz	a5,8000073a <printf+0x1b2>
    switch(c){
    80000644:	05678a63          	beq	a5,s6,80000698 <printf+0x110>
    80000648:	02fb7663          	bgeu	s6,a5,80000674 <printf+0xec>
    8000064c:	09978963          	beq	a5,s9,800006de <printf+0x156>
    80000650:	07800713          	li	a4,120
    80000654:	0ce79863          	bne	a5,a4,80000724 <printf+0x19c>
      printint(va_arg(ap, int), 16, 1);
    80000658:	f8843783          	ld	a5,-120(s0)
    8000065c:	00878713          	addi	a4,a5,8
    80000660:	f8e43423          	sd	a4,-120(s0)
    80000664:	4605                	li	a2,1
    80000666:	85ea                	mv	a1,s10
    80000668:	4388                	lw	a0,0(a5)
    8000066a:	00000097          	auipc	ra,0x0
    8000066e:	e32080e7          	jalr	-462(ra) # 8000049c <printint>
      break;
    80000672:	bf45                	j	80000622 <printf+0x9a>
    switch(c){
    80000674:	0b578263          	beq	a5,s5,80000718 <printf+0x190>
    80000678:	0b879663          	bne	a5,s8,80000724 <printf+0x19c>
      printint(va_arg(ap, int), 10, 1);
    8000067c:	f8843783          	ld	a5,-120(s0)
    80000680:	00878713          	addi	a4,a5,8
    80000684:	f8e43423          	sd	a4,-120(s0)
    80000688:	4605                	li	a2,1
    8000068a:	45a9                	li	a1,10
    8000068c:	4388                	lw	a0,0(a5)
    8000068e:	00000097          	auipc	ra,0x0
    80000692:	e0e080e7          	jalr	-498(ra) # 8000049c <printint>
      break;
    80000696:	b771                	j	80000622 <printf+0x9a>
      printptr(va_arg(ap, uint64));
    80000698:	f8843783          	ld	a5,-120(s0)
    8000069c:	00878713          	addi	a4,a5,8
    800006a0:	f8e43423          	sd	a4,-120(s0)
    800006a4:	0007b983          	ld	s3,0(a5)
  consputc('0');
    800006a8:	03000513          	li	a0,48
    800006ac:	00000097          	auipc	ra,0x0
    800006b0:	bd0080e7          	jalr	-1072(ra) # 8000027c <consputc>
  consputc('x');
    800006b4:	07800513          	li	a0,120
    800006b8:	00000097          	auipc	ra,0x0
    800006bc:	bc4080e7          	jalr	-1084(ra) # 8000027c <consputc>
    800006c0:	896a                	mv	s2,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006c2:	03c9d793          	srli	a5,s3,0x3c
    800006c6:	97de                	add	a5,a5,s7
    800006c8:	0007c503          	lbu	a0,0(a5)
    800006cc:	00000097          	auipc	ra,0x0
    800006d0:	bb0080e7          	jalr	-1104(ra) # 8000027c <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    800006d4:	0992                	slli	s3,s3,0x4
    800006d6:	397d                	addiw	s2,s2,-1
    800006d8:	fe0915e3          	bnez	s2,800006c2 <printf+0x13a>
    800006dc:	b799                	j	80000622 <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    800006de:	f8843783          	ld	a5,-120(s0)
    800006e2:	00878713          	addi	a4,a5,8
    800006e6:	f8e43423          	sd	a4,-120(s0)
    800006ea:	0007b903          	ld	s2,0(a5)
    800006ee:	00090e63          	beqz	s2,8000070a <printf+0x182>
      for(; *s; s++)
    800006f2:	00094503          	lbu	a0,0(s2)
    800006f6:	d515                	beqz	a0,80000622 <printf+0x9a>
        consputc(*s);
    800006f8:	00000097          	auipc	ra,0x0
    800006fc:	b84080e7          	jalr	-1148(ra) # 8000027c <consputc>
      for(; *s; s++)
    80000700:	0905                	addi	s2,s2,1
    80000702:	00094503          	lbu	a0,0(s2)
    80000706:	f96d                	bnez	a0,800006f8 <printf+0x170>
    80000708:	bf29                	j	80000622 <printf+0x9a>
        s = "(null)";
    8000070a:	00008917          	auipc	s2,0x8
    8000070e:	91690913          	addi	s2,s2,-1770 # 80008020 <etext+0x20>
      for(; *s; s++)
    80000712:	02800513          	li	a0,40
    80000716:	b7cd                	j	800006f8 <printf+0x170>
      consputc('%');
    80000718:	8556                	mv	a0,s5
    8000071a:	00000097          	auipc	ra,0x0
    8000071e:	b62080e7          	jalr	-1182(ra) # 8000027c <consputc>
      break;
    80000722:	b701                	j	80000622 <printf+0x9a>
      consputc('%');
    80000724:	8556                	mv	a0,s5
    80000726:	00000097          	auipc	ra,0x0
    8000072a:	b56080e7          	jalr	-1194(ra) # 8000027c <consputc>
      consputc(c);
    8000072e:	854a                	mv	a0,s2
    80000730:	00000097          	auipc	ra,0x0
    80000734:	b4c080e7          	jalr	-1204(ra) # 8000027c <consputc>
      break;
    80000738:	b5ed                	j	80000622 <printf+0x9a>
  if(locking)
    8000073a:	020d9163          	bnez	s11,8000075c <printf+0x1d4>
}
    8000073e:	70e6                	ld	ra,120(sp)
    80000740:	7446                	ld	s0,112(sp)
    80000742:	74a6                	ld	s1,104(sp)
    80000744:	7906                	ld	s2,96(sp)
    80000746:	69e6                	ld	s3,88(sp)
    80000748:	6a46                	ld	s4,80(sp)
    8000074a:	6aa6                	ld	s5,72(sp)
    8000074c:	6b06                	ld	s6,64(sp)
    8000074e:	7be2                	ld	s7,56(sp)
    80000750:	7c42                	ld	s8,48(sp)
    80000752:	7ca2                	ld	s9,40(sp)
    80000754:	7d02                	ld	s10,32(sp)
    80000756:	6de2                	ld	s11,24(sp)
    80000758:	6129                	addi	sp,sp,192
    8000075a:	8082                	ret
    release(&pr.lock);
    8000075c:	00011517          	auipc	a0,0x11
    80000760:	aec50513          	addi	a0,a0,-1300 # 80011248 <pr>
    80000764:	00000097          	auipc	ra,0x0
    80000768:	534080e7          	jalr	1332(ra) # 80000c98 <release>
}
    8000076c:	bfc9                	j	8000073e <printf+0x1b6>

000000008000076e <printfinit>:
    ;
}

void
printfinit(void)
{
    8000076e:	1101                	addi	sp,sp,-32
    80000770:	ec06                	sd	ra,24(sp)
    80000772:	e822                	sd	s0,16(sp)
    80000774:	e426                	sd	s1,8(sp)
    80000776:	1000                	addi	s0,sp,32
  initlock(&pr.lock, "pr");
    80000778:	00011497          	auipc	s1,0x11
    8000077c:	ad048493          	addi	s1,s1,-1328 # 80011248 <pr>
    80000780:	00008597          	auipc	a1,0x8
    80000784:	8b858593          	addi	a1,a1,-1864 # 80008038 <etext+0x38>
    80000788:	8526                	mv	a0,s1
    8000078a:	00000097          	auipc	ra,0x0
    8000078e:	3ca080e7          	jalr	970(ra) # 80000b54 <initlock>
  pr.locking = 1;
    80000792:	4785                	li	a5,1
    80000794:	cc9c                	sw	a5,24(s1)
}
    80000796:	60e2                	ld	ra,24(sp)
    80000798:	6442                	ld	s0,16(sp)
    8000079a:	64a2                	ld	s1,8(sp)
    8000079c:	6105                	addi	sp,sp,32
    8000079e:	8082                	ret

00000000800007a0 <uartinit>:

void uartstart();

void
uartinit(void)
{
    800007a0:	1141                	addi	sp,sp,-16
    800007a2:	e406                	sd	ra,8(sp)
    800007a4:	e022                	sd	s0,0(sp)
    800007a6:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    800007a8:	100007b7          	lui	a5,0x10000
    800007ac:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    800007b0:	f8000713          	li	a4,-128
    800007b4:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    800007b8:	470d                	li	a4,3
    800007ba:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    800007be:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    800007c2:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    800007c6:	469d                	li	a3,7
    800007c8:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    800007cc:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    800007d0:	00008597          	auipc	a1,0x8
    800007d4:	88858593          	addi	a1,a1,-1912 # 80008058 <digits+0x18>
    800007d8:	00011517          	auipc	a0,0x11
    800007dc:	a9050513          	addi	a0,a0,-1392 # 80011268 <uart_tx_lock>
    800007e0:	00000097          	auipc	ra,0x0
    800007e4:	374080e7          	jalr	884(ra) # 80000b54 <initlock>
}
    800007e8:	60a2                	ld	ra,8(sp)
    800007ea:	6402                	ld	s0,0(sp)
    800007ec:	0141                	addi	sp,sp,16
    800007ee:	8082                	ret

00000000800007f0 <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    800007f0:	1101                	addi	sp,sp,-32
    800007f2:	ec06                	sd	ra,24(sp)
    800007f4:	e822                	sd	s0,16(sp)
    800007f6:	e426                	sd	s1,8(sp)
    800007f8:	1000                	addi	s0,sp,32
    800007fa:	84aa                	mv	s1,a0
  push_off();
    800007fc:	00000097          	auipc	ra,0x0
    80000800:	39c080e7          	jalr	924(ra) # 80000b98 <push_off>

  if(panicked){
    80000804:	00008797          	auipc	a5,0x8
    80000808:	7fc7a783          	lw	a5,2044(a5) # 80009000 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    8000080c:	10000737          	lui	a4,0x10000
  if(panicked){
    80000810:	c391                	beqz	a5,80000814 <uartputc_sync+0x24>
    for(;;)
    80000812:	a001                	j	80000812 <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000814:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    80000818:	0ff7f793          	andi	a5,a5,255
    8000081c:	0207f793          	andi	a5,a5,32
    80000820:	dbf5                	beqz	a5,80000814 <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    80000822:	0ff4f793          	andi	a5,s1,255
    80000826:	10000737          	lui	a4,0x10000
    8000082a:	00f70023          	sb	a5,0(a4) # 10000000 <_entry-0x70000000>

  pop_off();
    8000082e:	00000097          	auipc	ra,0x0
    80000832:	40a080e7          	jalr	1034(ra) # 80000c38 <pop_off>
}
    80000836:	60e2                	ld	ra,24(sp)
    80000838:	6442                	ld	s0,16(sp)
    8000083a:	64a2                	ld	s1,8(sp)
    8000083c:	6105                	addi	sp,sp,32
    8000083e:	8082                	ret

0000000080000840 <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    80000840:	00008717          	auipc	a4,0x8
    80000844:	7c873703          	ld	a4,1992(a4) # 80009008 <uart_tx_r>
    80000848:	00008797          	auipc	a5,0x8
    8000084c:	7c87b783          	ld	a5,1992(a5) # 80009010 <uart_tx_w>
    80000850:	06e78c63          	beq	a5,a4,800008c8 <uartstart+0x88>
{
    80000854:	7139                	addi	sp,sp,-64
    80000856:	fc06                	sd	ra,56(sp)
    80000858:	f822                	sd	s0,48(sp)
    8000085a:	f426                	sd	s1,40(sp)
    8000085c:	f04a                	sd	s2,32(sp)
    8000085e:	ec4e                	sd	s3,24(sp)
    80000860:	e852                	sd	s4,16(sp)
    80000862:	e456                	sd	s5,8(sp)
    80000864:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000866:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    8000086a:	00011a17          	auipc	s4,0x11
    8000086e:	9fea0a13          	addi	s4,s4,-1538 # 80011268 <uart_tx_lock>
    uart_tx_r += 1;
    80000872:	00008497          	auipc	s1,0x8
    80000876:	79648493          	addi	s1,s1,1942 # 80009008 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    8000087a:	00008997          	auipc	s3,0x8
    8000087e:	79698993          	addi	s3,s3,1942 # 80009010 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000882:	00594783          	lbu	a5,5(s2) # 10000005 <_entry-0x6ffffffb>
    80000886:	0ff7f793          	andi	a5,a5,255
    8000088a:	0207f793          	andi	a5,a5,32
    8000088e:	c785                	beqz	a5,800008b6 <uartstart+0x76>
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000890:	01f77793          	andi	a5,a4,31
    80000894:	97d2                	add	a5,a5,s4
    80000896:	0187ca83          	lbu	s5,24(a5)
    uart_tx_r += 1;
    8000089a:	0705                	addi	a4,a4,1
    8000089c:	e098                	sd	a4,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    8000089e:	8526                	mv	a0,s1
    800008a0:	00002097          	auipc	ra,0x2
    800008a4:	c7a080e7          	jalr	-902(ra) # 8000251a <wakeup>
    
    WriteReg(THR, c);
    800008a8:	01590023          	sb	s5,0(s2)
    if(uart_tx_w == uart_tx_r){
    800008ac:	6098                	ld	a4,0(s1)
    800008ae:	0009b783          	ld	a5,0(s3)
    800008b2:	fce798e3          	bne	a5,a4,80000882 <uartstart+0x42>
  }
}
    800008b6:	70e2                	ld	ra,56(sp)
    800008b8:	7442                	ld	s0,48(sp)
    800008ba:	74a2                	ld	s1,40(sp)
    800008bc:	7902                	ld	s2,32(sp)
    800008be:	69e2                	ld	s3,24(sp)
    800008c0:	6a42                	ld	s4,16(sp)
    800008c2:	6aa2                	ld	s5,8(sp)
    800008c4:	6121                	addi	sp,sp,64
    800008c6:	8082                	ret
    800008c8:	8082                	ret

00000000800008ca <uartputc>:
{
    800008ca:	7179                	addi	sp,sp,-48
    800008cc:	f406                	sd	ra,40(sp)
    800008ce:	f022                	sd	s0,32(sp)
    800008d0:	ec26                	sd	s1,24(sp)
    800008d2:	e84a                	sd	s2,16(sp)
    800008d4:	e44e                	sd	s3,8(sp)
    800008d6:	e052                	sd	s4,0(sp)
    800008d8:	1800                	addi	s0,sp,48
    800008da:	89aa                	mv	s3,a0
  acquire(&uart_tx_lock);
    800008dc:	00011517          	auipc	a0,0x11
    800008e0:	98c50513          	addi	a0,a0,-1652 # 80011268 <uart_tx_lock>
    800008e4:	00000097          	auipc	ra,0x0
    800008e8:	300080e7          	jalr	768(ra) # 80000be4 <acquire>
  if(panicked){
    800008ec:	00008797          	auipc	a5,0x8
    800008f0:	7147a783          	lw	a5,1812(a5) # 80009000 <panicked>
    800008f4:	c391                	beqz	a5,800008f8 <uartputc+0x2e>
    for(;;)
    800008f6:	a001                	j	800008f6 <uartputc+0x2c>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008f8:	00008797          	auipc	a5,0x8
    800008fc:	7187b783          	ld	a5,1816(a5) # 80009010 <uart_tx_w>
    80000900:	00008717          	auipc	a4,0x8
    80000904:	70873703          	ld	a4,1800(a4) # 80009008 <uart_tx_r>
    80000908:	02070713          	addi	a4,a4,32
    8000090c:	02f71b63          	bne	a4,a5,80000942 <uartputc+0x78>
      sleep(&uart_tx_r, &uart_tx_lock);
    80000910:	00011a17          	auipc	s4,0x11
    80000914:	958a0a13          	addi	s4,s4,-1704 # 80011268 <uart_tx_lock>
    80000918:	00008497          	auipc	s1,0x8
    8000091c:	6f048493          	addi	s1,s1,1776 # 80009008 <uart_tx_r>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000920:	00008917          	auipc	s2,0x8
    80000924:	6f090913          	addi	s2,s2,1776 # 80009010 <uart_tx_w>
      sleep(&uart_tx_r, &uart_tx_lock);
    80000928:	85d2                	mv	a1,s4
    8000092a:	8526                	mv	a0,s1
    8000092c:	00002097          	auipc	ra,0x2
    80000930:	a4e080e7          	jalr	-1458(ra) # 8000237a <sleep>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000934:	00093783          	ld	a5,0(s2)
    80000938:	6098                	ld	a4,0(s1)
    8000093a:	02070713          	addi	a4,a4,32
    8000093e:	fef705e3          	beq	a4,a5,80000928 <uartputc+0x5e>
      uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000942:	00011497          	auipc	s1,0x11
    80000946:	92648493          	addi	s1,s1,-1754 # 80011268 <uart_tx_lock>
    8000094a:	01f7f713          	andi	a4,a5,31
    8000094e:	9726                	add	a4,a4,s1
    80000950:	01370c23          	sb	s3,24(a4)
      uart_tx_w += 1;
    80000954:	0785                	addi	a5,a5,1
    80000956:	00008717          	auipc	a4,0x8
    8000095a:	6af73d23          	sd	a5,1722(a4) # 80009010 <uart_tx_w>
      uartstart();
    8000095e:	00000097          	auipc	ra,0x0
    80000962:	ee2080e7          	jalr	-286(ra) # 80000840 <uartstart>
      release(&uart_tx_lock);
    80000966:	8526                	mv	a0,s1
    80000968:	00000097          	auipc	ra,0x0
    8000096c:	330080e7          	jalr	816(ra) # 80000c98 <release>
}
    80000970:	70a2                	ld	ra,40(sp)
    80000972:	7402                	ld	s0,32(sp)
    80000974:	64e2                	ld	s1,24(sp)
    80000976:	6942                	ld	s2,16(sp)
    80000978:	69a2                	ld	s3,8(sp)
    8000097a:	6a02                	ld	s4,0(sp)
    8000097c:	6145                	addi	sp,sp,48
    8000097e:	8082                	ret

0000000080000980 <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    80000980:	1141                	addi	sp,sp,-16
    80000982:	e422                	sd	s0,8(sp)
    80000984:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    80000986:	100007b7          	lui	a5,0x10000
    8000098a:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    8000098e:	8b85                	andi	a5,a5,1
    80000990:	cb91                	beqz	a5,800009a4 <uartgetc+0x24>
    // input data is ready.
    return ReadReg(RHR);
    80000992:	100007b7          	lui	a5,0x10000
    80000996:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
    8000099a:	0ff57513          	andi	a0,a0,255
  } else {
    return -1;
  }
}
    8000099e:	6422                	ld	s0,8(sp)
    800009a0:	0141                	addi	sp,sp,16
    800009a2:	8082                	ret
    return -1;
    800009a4:	557d                	li	a0,-1
    800009a6:	bfe5                	j	8000099e <uartgetc+0x1e>

00000000800009a8 <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from trap.c.
void
uartintr(void)
{
    800009a8:	1101                	addi	sp,sp,-32
    800009aa:	ec06                	sd	ra,24(sp)
    800009ac:	e822                	sd	s0,16(sp)
    800009ae:	e426                	sd	s1,8(sp)
    800009b0:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    800009b2:	54fd                	li	s1,-1
    int c = uartgetc();
    800009b4:	00000097          	auipc	ra,0x0
    800009b8:	fcc080e7          	jalr	-52(ra) # 80000980 <uartgetc>
    if(c == -1)
    800009bc:	00950763          	beq	a0,s1,800009ca <uartintr+0x22>
      break;
    consoleintr(c);
    800009c0:	00000097          	auipc	ra,0x0
    800009c4:	8fe080e7          	jalr	-1794(ra) # 800002be <consoleintr>
  while(1){
    800009c8:	b7f5                	j	800009b4 <uartintr+0xc>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    800009ca:	00011497          	auipc	s1,0x11
    800009ce:	89e48493          	addi	s1,s1,-1890 # 80011268 <uart_tx_lock>
    800009d2:	8526                	mv	a0,s1
    800009d4:	00000097          	auipc	ra,0x0
    800009d8:	210080e7          	jalr	528(ra) # 80000be4 <acquire>
  uartstart();
    800009dc:	00000097          	auipc	ra,0x0
    800009e0:	e64080e7          	jalr	-412(ra) # 80000840 <uartstart>
  release(&uart_tx_lock);
    800009e4:	8526                	mv	a0,s1
    800009e6:	00000097          	auipc	ra,0x0
    800009ea:	2b2080e7          	jalr	690(ra) # 80000c98 <release>
}
    800009ee:	60e2                	ld	ra,24(sp)
    800009f0:	6442                	ld	s0,16(sp)
    800009f2:	64a2                	ld	s1,8(sp)
    800009f4:	6105                	addi	sp,sp,32
    800009f6:	8082                	ret

00000000800009f8 <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    800009f8:	1101                	addi	sp,sp,-32
    800009fa:	ec06                	sd	ra,24(sp)
    800009fc:	e822                	sd	s0,16(sp)
    800009fe:	e426                	sd	s1,8(sp)
    80000a00:	e04a                	sd	s2,0(sp)
    80000a02:	1000                	addi	s0,sp,32
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    80000a04:	03451793          	slli	a5,a0,0x34
    80000a08:	ebb9                	bnez	a5,80000a5e <kfree+0x66>
    80000a0a:	84aa                	mv	s1,a0
    80000a0c:	00025797          	auipc	a5,0x25
    80000a10:	5f478793          	addi	a5,a5,1524 # 80026000 <end>
    80000a14:	04f56563          	bltu	a0,a5,80000a5e <kfree+0x66>
    80000a18:	47c5                	li	a5,17
    80000a1a:	07ee                	slli	a5,a5,0x1b
    80000a1c:	04f57163          	bgeu	a0,a5,80000a5e <kfree+0x66>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    80000a20:	6605                	lui	a2,0x1
    80000a22:	4585                	li	a1,1
    80000a24:	00000097          	auipc	ra,0x0
    80000a28:	2bc080e7          	jalr	700(ra) # 80000ce0 <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000a2c:	00011917          	auipc	s2,0x11
    80000a30:	87490913          	addi	s2,s2,-1932 # 800112a0 <kmem>
    80000a34:	854a                	mv	a0,s2
    80000a36:	00000097          	auipc	ra,0x0
    80000a3a:	1ae080e7          	jalr	430(ra) # 80000be4 <acquire>
  r->next = kmem.freelist;
    80000a3e:	01893783          	ld	a5,24(s2)
    80000a42:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000a44:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000a48:	854a                	mv	a0,s2
    80000a4a:	00000097          	auipc	ra,0x0
    80000a4e:	24e080e7          	jalr	590(ra) # 80000c98 <release>
}
    80000a52:	60e2                	ld	ra,24(sp)
    80000a54:	6442                	ld	s0,16(sp)
    80000a56:	64a2                	ld	s1,8(sp)
    80000a58:	6902                	ld	s2,0(sp)
    80000a5a:	6105                	addi	sp,sp,32
    80000a5c:	8082                	ret
    panic("kfree");
    80000a5e:	00007517          	auipc	a0,0x7
    80000a62:	60250513          	addi	a0,a0,1538 # 80008060 <digits+0x20>
    80000a66:	00000097          	auipc	ra,0x0
    80000a6a:	ad8080e7          	jalr	-1320(ra) # 8000053e <panic>

0000000080000a6e <freerange>:
{
    80000a6e:	7179                	addi	sp,sp,-48
    80000a70:	f406                	sd	ra,40(sp)
    80000a72:	f022                	sd	s0,32(sp)
    80000a74:	ec26                	sd	s1,24(sp)
    80000a76:	e84a                	sd	s2,16(sp)
    80000a78:	e44e                	sd	s3,8(sp)
    80000a7a:	e052                	sd	s4,0(sp)
    80000a7c:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000a7e:	6785                	lui	a5,0x1
    80000a80:	fff78493          	addi	s1,a5,-1 # fff <_entry-0x7ffff001>
    80000a84:	94aa                	add	s1,s1,a0
    80000a86:	757d                	lui	a0,0xfffff
    80000a88:	8ce9                	and	s1,s1,a0
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a8a:	94be                	add	s1,s1,a5
    80000a8c:	0095ee63          	bltu	a1,s1,80000aa8 <freerange+0x3a>
    80000a90:	892e                	mv	s2,a1
    kfree(p);
    80000a92:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a94:	6985                	lui	s3,0x1
    kfree(p);
    80000a96:	01448533          	add	a0,s1,s4
    80000a9a:	00000097          	auipc	ra,0x0
    80000a9e:	f5e080e7          	jalr	-162(ra) # 800009f8 <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000aa2:	94ce                	add	s1,s1,s3
    80000aa4:	fe9979e3          	bgeu	s2,s1,80000a96 <freerange+0x28>
}
    80000aa8:	70a2                	ld	ra,40(sp)
    80000aaa:	7402                	ld	s0,32(sp)
    80000aac:	64e2                	ld	s1,24(sp)
    80000aae:	6942                	ld	s2,16(sp)
    80000ab0:	69a2                	ld	s3,8(sp)
    80000ab2:	6a02                	ld	s4,0(sp)
    80000ab4:	6145                	addi	sp,sp,48
    80000ab6:	8082                	ret

0000000080000ab8 <kinit>:
{
    80000ab8:	1141                	addi	sp,sp,-16
    80000aba:	e406                	sd	ra,8(sp)
    80000abc:	e022                	sd	s0,0(sp)
    80000abe:	0800                	addi	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000ac0:	00007597          	auipc	a1,0x7
    80000ac4:	5a858593          	addi	a1,a1,1448 # 80008068 <digits+0x28>
    80000ac8:	00010517          	auipc	a0,0x10
    80000acc:	7d850513          	addi	a0,a0,2008 # 800112a0 <kmem>
    80000ad0:	00000097          	auipc	ra,0x0
    80000ad4:	084080e7          	jalr	132(ra) # 80000b54 <initlock>
  freerange(end, (void*)PHYSTOP);
    80000ad8:	45c5                	li	a1,17
    80000ada:	05ee                	slli	a1,a1,0x1b
    80000adc:	00025517          	auipc	a0,0x25
    80000ae0:	52450513          	addi	a0,a0,1316 # 80026000 <end>
    80000ae4:	00000097          	auipc	ra,0x0
    80000ae8:	f8a080e7          	jalr	-118(ra) # 80000a6e <freerange>
}
    80000aec:	60a2                	ld	ra,8(sp)
    80000aee:	6402                	ld	s0,0(sp)
    80000af0:	0141                	addi	sp,sp,16
    80000af2:	8082                	ret

0000000080000af4 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000af4:	1101                	addi	sp,sp,-32
    80000af6:	ec06                	sd	ra,24(sp)
    80000af8:	e822                	sd	s0,16(sp)
    80000afa:	e426                	sd	s1,8(sp)
    80000afc:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000afe:	00010497          	auipc	s1,0x10
    80000b02:	7a248493          	addi	s1,s1,1954 # 800112a0 <kmem>
    80000b06:	8526                	mv	a0,s1
    80000b08:	00000097          	auipc	ra,0x0
    80000b0c:	0dc080e7          	jalr	220(ra) # 80000be4 <acquire>
  r = kmem.freelist;
    80000b10:	6c84                	ld	s1,24(s1)
  if(r)
    80000b12:	c885                	beqz	s1,80000b42 <kalloc+0x4e>
    kmem.freelist = r->next;
    80000b14:	609c                	ld	a5,0(s1)
    80000b16:	00010517          	auipc	a0,0x10
    80000b1a:	78a50513          	addi	a0,a0,1930 # 800112a0 <kmem>
    80000b1e:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000b20:	00000097          	auipc	ra,0x0
    80000b24:	178080e7          	jalr	376(ra) # 80000c98 <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000b28:	6605                	lui	a2,0x1
    80000b2a:	4595                	li	a1,5
    80000b2c:	8526                	mv	a0,s1
    80000b2e:	00000097          	auipc	ra,0x0
    80000b32:	1b2080e7          	jalr	434(ra) # 80000ce0 <memset>
  return (void*)r;
}
    80000b36:	8526                	mv	a0,s1
    80000b38:	60e2                	ld	ra,24(sp)
    80000b3a:	6442                	ld	s0,16(sp)
    80000b3c:	64a2                	ld	s1,8(sp)
    80000b3e:	6105                	addi	sp,sp,32
    80000b40:	8082                	ret
  release(&kmem.lock);
    80000b42:	00010517          	auipc	a0,0x10
    80000b46:	75e50513          	addi	a0,a0,1886 # 800112a0 <kmem>
    80000b4a:	00000097          	auipc	ra,0x0
    80000b4e:	14e080e7          	jalr	334(ra) # 80000c98 <release>
  if(r)
    80000b52:	b7d5                	j	80000b36 <kalloc+0x42>

0000000080000b54 <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000b54:	1141                	addi	sp,sp,-16
    80000b56:	e422                	sd	s0,8(sp)
    80000b58:	0800                	addi	s0,sp,16
  lk->name = name;
    80000b5a:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000b5c:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000b60:	00053823          	sd	zero,16(a0)
}
    80000b64:	6422                	ld	s0,8(sp)
    80000b66:	0141                	addi	sp,sp,16
    80000b68:	8082                	ret

0000000080000b6a <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000b6a:	411c                	lw	a5,0(a0)
    80000b6c:	e399                	bnez	a5,80000b72 <holding+0x8>
    80000b6e:	4501                	li	a0,0
  return r;
}
    80000b70:	8082                	ret
{
    80000b72:	1101                	addi	sp,sp,-32
    80000b74:	ec06                	sd	ra,24(sp)
    80000b76:	e822                	sd	s0,16(sp)
    80000b78:	e426                	sd	s1,8(sp)
    80000b7a:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000b7c:	6904                	ld	s1,16(a0)
    80000b7e:	00001097          	auipc	ra,0x1
    80000b82:	e2e080e7          	jalr	-466(ra) # 800019ac <mycpu>
    80000b86:	40a48533          	sub	a0,s1,a0
    80000b8a:	00153513          	seqz	a0,a0
}
    80000b8e:	60e2                	ld	ra,24(sp)
    80000b90:	6442                	ld	s0,16(sp)
    80000b92:	64a2                	ld	s1,8(sp)
    80000b94:	6105                	addi	sp,sp,32
    80000b96:	8082                	ret

0000000080000b98 <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000b98:	1101                	addi	sp,sp,-32
    80000b9a:	ec06                	sd	ra,24(sp)
    80000b9c:	e822                	sd	s0,16(sp)
    80000b9e:	e426                	sd	s1,8(sp)
    80000ba0:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000ba2:	100024f3          	csrr	s1,sstatus
    80000ba6:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000baa:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000bac:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000bb0:	00001097          	auipc	ra,0x1
    80000bb4:	dfc080e7          	jalr	-516(ra) # 800019ac <mycpu>
    80000bb8:	5d3c                	lw	a5,120(a0)
    80000bba:	cf89                	beqz	a5,80000bd4 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000bbc:	00001097          	auipc	ra,0x1
    80000bc0:	df0080e7          	jalr	-528(ra) # 800019ac <mycpu>
    80000bc4:	5d3c                	lw	a5,120(a0)
    80000bc6:	2785                	addiw	a5,a5,1
    80000bc8:	dd3c                	sw	a5,120(a0)
}
    80000bca:	60e2                	ld	ra,24(sp)
    80000bcc:	6442                	ld	s0,16(sp)
    80000bce:	64a2                	ld	s1,8(sp)
    80000bd0:	6105                	addi	sp,sp,32
    80000bd2:	8082                	ret
    mycpu()->intena = old;
    80000bd4:	00001097          	auipc	ra,0x1
    80000bd8:	dd8080e7          	jalr	-552(ra) # 800019ac <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000bdc:	8085                	srli	s1,s1,0x1
    80000bde:	8885                	andi	s1,s1,1
    80000be0:	dd64                	sw	s1,124(a0)
    80000be2:	bfe9                	j	80000bbc <push_off+0x24>

0000000080000be4 <acquire>:
{
    80000be4:	1101                	addi	sp,sp,-32
    80000be6:	ec06                	sd	ra,24(sp)
    80000be8:	e822                	sd	s0,16(sp)
    80000bea:	e426                	sd	s1,8(sp)
    80000bec:	1000                	addi	s0,sp,32
    80000bee:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000bf0:	00000097          	auipc	ra,0x0
    80000bf4:	fa8080e7          	jalr	-88(ra) # 80000b98 <push_off>
  if(holding(lk))
    80000bf8:	8526                	mv	a0,s1
    80000bfa:	00000097          	auipc	ra,0x0
    80000bfe:	f70080e7          	jalr	-144(ra) # 80000b6a <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c02:	4705                	li	a4,1
  if(holding(lk))
    80000c04:	e115                	bnez	a0,80000c28 <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c06:	87ba                	mv	a5,a4
    80000c08:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000c0c:	2781                	sext.w	a5,a5
    80000c0e:	ffe5                	bnez	a5,80000c06 <acquire+0x22>
  __sync_synchronize();
    80000c10:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000c14:	00001097          	auipc	ra,0x1
    80000c18:	d98080e7          	jalr	-616(ra) # 800019ac <mycpu>
    80000c1c:	e888                	sd	a0,16(s1)
}
    80000c1e:	60e2                	ld	ra,24(sp)
    80000c20:	6442                	ld	s0,16(sp)
    80000c22:	64a2                	ld	s1,8(sp)
    80000c24:	6105                	addi	sp,sp,32
    80000c26:	8082                	ret
    panic("acquire");
    80000c28:	00007517          	auipc	a0,0x7
    80000c2c:	44850513          	addi	a0,a0,1096 # 80008070 <digits+0x30>
    80000c30:	00000097          	auipc	ra,0x0
    80000c34:	90e080e7          	jalr	-1778(ra) # 8000053e <panic>

0000000080000c38 <pop_off>:

void
pop_off(void)
{
    80000c38:	1141                	addi	sp,sp,-16
    80000c3a:	e406                	sd	ra,8(sp)
    80000c3c:	e022                	sd	s0,0(sp)
    80000c3e:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000c40:	00001097          	auipc	ra,0x1
    80000c44:	d6c080e7          	jalr	-660(ra) # 800019ac <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c48:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000c4c:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000c4e:	e78d                	bnez	a5,80000c78 <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000c50:	5d3c                	lw	a5,120(a0)
    80000c52:	02f05b63          	blez	a5,80000c88 <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000c56:	37fd                	addiw	a5,a5,-1
    80000c58:	0007871b          	sext.w	a4,a5
    80000c5c:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000c5e:	eb09                	bnez	a4,80000c70 <pop_off+0x38>
    80000c60:	5d7c                	lw	a5,124(a0)
    80000c62:	c799                	beqz	a5,80000c70 <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c64:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000c68:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000c6c:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000c70:	60a2                	ld	ra,8(sp)
    80000c72:	6402                	ld	s0,0(sp)
    80000c74:	0141                	addi	sp,sp,16
    80000c76:	8082                	ret
    panic("pop_off - interruptible");
    80000c78:	00007517          	auipc	a0,0x7
    80000c7c:	40050513          	addi	a0,a0,1024 # 80008078 <digits+0x38>
    80000c80:	00000097          	auipc	ra,0x0
    80000c84:	8be080e7          	jalr	-1858(ra) # 8000053e <panic>
    panic("pop_off");
    80000c88:	00007517          	auipc	a0,0x7
    80000c8c:	40850513          	addi	a0,a0,1032 # 80008090 <digits+0x50>
    80000c90:	00000097          	auipc	ra,0x0
    80000c94:	8ae080e7          	jalr	-1874(ra) # 8000053e <panic>

0000000080000c98 <release>:
{
    80000c98:	1101                	addi	sp,sp,-32
    80000c9a:	ec06                	sd	ra,24(sp)
    80000c9c:	e822                	sd	s0,16(sp)
    80000c9e:	e426                	sd	s1,8(sp)
    80000ca0:	1000                	addi	s0,sp,32
    80000ca2:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000ca4:	00000097          	auipc	ra,0x0
    80000ca8:	ec6080e7          	jalr	-314(ra) # 80000b6a <holding>
    80000cac:	c115                	beqz	a0,80000cd0 <release+0x38>
  lk->cpu = 0;
    80000cae:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000cb2:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000cb6:	0f50000f          	fence	iorw,ow
    80000cba:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000cbe:	00000097          	auipc	ra,0x0
    80000cc2:	f7a080e7          	jalr	-134(ra) # 80000c38 <pop_off>
}
    80000cc6:	60e2                	ld	ra,24(sp)
    80000cc8:	6442                	ld	s0,16(sp)
    80000cca:	64a2                	ld	s1,8(sp)
    80000ccc:	6105                	addi	sp,sp,32
    80000cce:	8082                	ret
    panic("release");
    80000cd0:	00007517          	auipc	a0,0x7
    80000cd4:	3c850513          	addi	a0,a0,968 # 80008098 <digits+0x58>
    80000cd8:	00000097          	auipc	ra,0x0
    80000cdc:	866080e7          	jalr	-1946(ra) # 8000053e <panic>

0000000080000ce0 <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000ce0:	1141                	addi	sp,sp,-16
    80000ce2:	e422                	sd	s0,8(sp)
    80000ce4:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000ce6:	ce09                	beqz	a2,80000d00 <memset+0x20>
    80000ce8:	87aa                	mv	a5,a0
    80000cea:	fff6071b          	addiw	a4,a2,-1
    80000cee:	1702                	slli	a4,a4,0x20
    80000cf0:	9301                	srli	a4,a4,0x20
    80000cf2:	0705                	addi	a4,a4,1
    80000cf4:	972a                	add	a4,a4,a0
    cdst[i] = c;
    80000cf6:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000cfa:	0785                	addi	a5,a5,1
    80000cfc:	fee79de3          	bne	a5,a4,80000cf6 <memset+0x16>
  }
  return dst;
}
    80000d00:	6422                	ld	s0,8(sp)
    80000d02:	0141                	addi	sp,sp,16
    80000d04:	8082                	ret

0000000080000d06 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000d06:	1141                	addi	sp,sp,-16
    80000d08:	e422                	sd	s0,8(sp)
    80000d0a:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000d0c:	ca05                	beqz	a2,80000d3c <memcmp+0x36>
    80000d0e:	fff6069b          	addiw	a3,a2,-1
    80000d12:	1682                	slli	a3,a3,0x20
    80000d14:	9281                	srli	a3,a3,0x20
    80000d16:	0685                	addi	a3,a3,1
    80000d18:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000d1a:	00054783          	lbu	a5,0(a0)
    80000d1e:	0005c703          	lbu	a4,0(a1)
    80000d22:	00e79863          	bne	a5,a4,80000d32 <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000d26:	0505                	addi	a0,a0,1
    80000d28:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000d2a:	fed518e3          	bne	a0,a3,80000d1a <memcmp+0x14>
  }

  return 0;
    80000d2e:	4501                	li	a0,0
    80000d30:	a019                	j	80000d36 <memcmp+0x30>
      return *s1 - *s2;
    80000d32:	40e7853b          	subw	a0,a5,a4
}
    80000d36:	6422                	ld	s0,8(sp)
    80000d38:	0141                	addi	sp,sp,16
    80000d3a:	8082                	ret
  return 0;
    80000d3c:	4501                	li	a0,0
    80000d3e:	bfe5                	j	80000d36 <memcmp+0x30>

0000000080000d40 <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000d40:	1141                	addi	sp,sp,-16
    80000d42:	e422                	sd	s0,8(sp)
    80000d44:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  if(n == 0)
    80000d46:	ca0d                	beqz	a2,80000d78 <memmove+0x38>
    return dst;
  
  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000d48:	00a5f963          	bgeu	a1,a0,80000d5a <memmove+0x1a>
    80000d4c:	02061693          	slli	a3,a2,0x20
    80000d50:	9281                	srli	a3,a3,0x20
    80000d52:	00d58733          	add	a4,a1,a3
    80000d56:	02e56463          	bltu	a0,a4,80000d7e <memmove+0x3e>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000d5a:	fff6079b          	addiw	a5,a2,-1
    80000d5e:	1782                	slli	a5,a5,0x20
    80000d60:	9381                	srli	a5,a5,0x20
    80000d62:	0785                	addi	a5,a5,1
    80000d64:	97ae                	add	a5,a5,a1
    80000d66:	872a                	mv	a4,a0
      *d++ = *s++;
    80000d68:	0585                	addi	a1,a1,1
    80000d6a:	0705                	addi	a4,a4,1
    80000d6c:	fff5c683          	lbu	a3,-1(a1)
    80000d70:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
    80000d74:	fef59ae3          	bne	a1,a5,80000d68 <memmove+0x28>

  return dst;
}
    80000d78:	6422                	ld	s0,8(sp)
    80000d7a:	0141                	addi	sp,sp,16
    80000d7c:	8082                	ret
    d += n;
    80000d7e:	96aa                	add	a3,a3,a0
    while(n-- > 0)
    80000d80:	fff6079b          	addiw	a5,a2,-1
    80000d84:	1782                	slli	a5,a5,0x20
    80000d86:	9381                	srli	a5,a5,0x20
    80000d88:	fff7c793          	not	a5,a5
    80000d8c:	97ba                	add	a5,a5,a4
      *--d = *--s;
    80000d8e:	177d                	addi	a4,a4,-1
    80000d90:	16fd                	addi	a3,a3,-1
    80000d92:	00074603          	lbu	a2,0(a4)
    80000d96:	00c68023          	sb	a2,0(a3)
    while(n-- > 0)
    80000d9a:	fef71ae3          	bne	a4,a5,80000d8e <memmove+0x4e>
    80000d9e:	bfe9                	j	80000d78 <memmove+0x38>

0000000080000da0 <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000da0:	1141                	addi	sp,sp,-16
    80000da2:	e406                	sd	ra,8(sp)
    80000da4:	e022                	sd	s0,0(sp)
    80000da6:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000da8:	00000097          	auipc	ra,0x0
    80000dac:	f98080e7          	jalr	-104(ra) # 80000d40 <memmove>
}
    80000db0:	60a2                	ld	ra,8(sp)
    80000db2:	6402                	ld	s0,0(sp)
    80000db4:	0141                	addi	sp,sp,16
    80000db6:	8082                	ret

0000000080000db8 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000db8:	1141                	addi	sp,sp,-16
    80000dba:	e422                	sd	s0,8(sp)
    80000dbc:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000dbe:	ce11                	beqz	a2,80000dda <strncmp+0x22>
    80000dc0:	00054783          	lbu	a5,0(a0)
    80000dc4:	cf89                	beqz	a5,80000dde <strncmp+0x26>
    80000dc6:	0005c703          	lbu	a4,0(a1)
    80000dca:	00f71a63          	bne	a4,a5,80000dde <strncmp+0x26>
    n--, p++, q++;
    80000dce:	367d                	addiw	a2,a2,-1
    80000dd0:	0505                	addi	a0,a0,1
    80000dd2:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000dd4:	f675                	bnez	a2,80000dc0 <strncmp+0x8>
  if(n == 0)
    return 0;
    80000dd6:	4501                	li	a0,0
    80000dd8:	a809                	j	80000dea <strncmp+0x32>
    80000dda:	4501                	li	a0,0
    80000ddc:	a039                	j	80000dea <strncmp+0x32>
  if(n == 0)
    80000dde:	ca09                	beqz	a2,80000df0 <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000de0:	00054503          	lbu	a0,0(a0)
    80000de4:	0005c783          	lbu	a5,0(a1)
    80000de8:	9d1d                	subw	a0,a0,a5
}
    80000dea:	6422                	ld	s0,8(sp)
    80000dec:	0141                	addi	sp,sp,16
    80000dee:	8082                	ret
    return 0;
    80000df0:	4501                	li	a0,0
    80000df2:	bfe5                	j	80000dea <strncmp+0x32>

0000000080000df4 <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000df4:	1141                	addi	sp,sp,-16
    80000df6:	e422                	sd	s0,8(sp)
    80000df8:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000dfa:	872a                	mv	a4,a0
    80000dfc:	8832                	mv	a6,a2
    80000dfe:	367d                	addiw	a2,a2,-1
    80000e00:	01005963          	blez	a6,80000e12 <strncpy+0x1e>
    80000e04:	0705                	addi	a4,a4,1
    80000e06:	0005c783          	lbu	a5,0(a1)
    80000e0a:	fef70fa3          	sb	a5,-1(a4)
    80000e0e:	0585                	addi	a1,a1,1
    80000e10:	f7f5                	bnez	a5,80000dfc <strncpy+0x8>
    ;
  while(n-- > 0)
    80000e12:	00c05d63          	blez	a2,80000e2c <strncpy+0x38>
    80000e16:	86ba                	mv	a3,a4
    *s++ = 0;
    80000e18:	0685                	addi	a3,a3,1
    80000e1a:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000e1e:	fff6c793          	not	a5,a3
    80000e22:	9fb9                	addw	a5,a5,a4
    80000e24:	010787bb          	addw	a5,a5,a6
    80000e28:	fef048e3          	bgtz	a5,80000e18 <strncpy+0x24>
  return os;
}
    80000e2c:	6422                	ld	s0,8(sp)
    80000e2e:	0141                	addi	sp,sp,16
    80000e30:	8082                	ret

0000000080000e32 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000e32:	1141                	addi	sp,sp,-16
    80000e34:	e422                	sd	s0,8(sp)
    80000e36:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000e38:	02c05363          	blez	a2,80000e5e <safestrcpy+0x2c>
    80000e3c:	fff6069b          	addiw	a3,a2,-1
    80000e40:	1682                	slli	a3,a3,0x20
    80000e42:	9281                	srli	a3,a3,0x20
    80000e44:	96ae                	add	a3,a3,a1
    80000e46:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000e48:	00d58963          	beq	a1,a3,80000e5a <safestrcpy+0x28>
    80000e4c:	0585                	addi	a1,a1,1
    80000e4e:	0785                	addi	a5,a5,1
    80000e50:	fff5c703          	lbu	a4,-1(a1)
    80000e54:	fee78fa3          	sb	a4,-1(a5)
    80000e58:	fb65                	bnez	a4,80000e48 <safestrcpy+0x16>
    ;
  *s = 0;
    80000e5a:	00078023          	sb	zero,0(a5)
  return os;
}
    80000e5e:	6422                	ld	s0,8(sp)
    80000e60:	0141                	addi	sp,sp,16
    80000e62:	8082                	ret

0000000080000e64 <strlen>:

int
strlen(const char *s)
{
    80000e64:	1141                	addi	sp,sp,-16
    80000e66:	e422                	sd	s0,8(sp)
    80000e68:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000e6a:	00054783          	lbu	a5,0(a0)
    80000e6e:	cf91                	beqz	a5,80000e8a <strlen+0x26>
    80000e70:	0505                	addi	a0,a0,1
    80000e72:	87aa                	mv	a5,a0
    80000e74:	4685                	li	a3,1
    80000e76:	9e89                	subw	a3,a3,a0
    80000e78:	00f6853b          	addw	a0,a3,a5
    80000e7c:	0785                	addi	a5,a5,1
    80000e7e:	fff7c703          	lbu	a4,-1(a5)
    80000e82:	fb7d                	bnez	a4,80000e78 <strlen+0x14>
    ;
  return n;
}
    80000e84:	6422                	ld	s0,8(sp)
    80000e86:	0141                	addi	sp,sp,16
    80000e88:	8082                	ret
  for(n = 0; s[n]; n++)
    80000e8a:	4501                	li	a0,0
    80000e8c:	bfe5                	j	80000e84 <strlen+0x20>

0000000080000e8e <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000e8e:	1141                	addi	sp,sp,-16
    80000e90:	e406                	sd	ra,8(sp)
    80000e92:	e022                	sd	s0,0(sp)
    80000e94:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000e96:	00001097          	auipc	ra,0x1
    80000e9a:	b06080e7          	jalr	-1274(ra) # 8000199c <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000e9e:	00008717          	auipc	a4,0x8
    80000ea2:	17a70713          	addi	a4,a4,378 # 80009018 <started>
  if(cpuid() == 0){
    80000ea6:	c539                	beqz	a0,80000ef4 <main+0x66>
    while(started == 0)
    80000ea8:	431c                	lw	a5,0(a4)
    80000eaa:	2781                	sext.w	a5,a5
    80000eac:	dff5                	beqz	a5,80000ea8 <main+0x1a>
      ;
    __sync_synchronize();
    80000eae:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000eb2:	00001097          	auipc	ra,0x1
    80000eb6:	aea080e7          	jalr	-1302(ra) # 8000199c <cpuid>
    80000eba:	85aa                	mv	a1,a0
    80000ebc:	00007517          	auipc	a0,0x7
    80000ec0:	1fc50513          	addi	a0,a0,508 # 800080b8 <digits+0x78>
    80000ec4:	fffff097          	auipc	ra,0xfffff
    80000ec8:	6c4080e7          	jalr	1732(ra) # 80000588 <printf>
    kvminithart();    // turn on paging
    80000ecc:	00000097          	auipc	ra,0x0
    80000ed0:	0e0080e7          	jalr	224(ra) # 80000fac <kvminithart>
    trapinithart();   // install kernel trap vector
    80000ed4:	00002097          	auipc	ra,0x2
    80000ed8:	c42080e7          	jalr	-958(ra) # 80002b16 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000edc:	00005097          	auipc	ra,0x5
    80000ee0:	204080e7          	jalr	516(ra) # 800060e0 <plicinithart>
  }

  scheduler();        
    80000ee4:	00001097          	auipc	ra,0x1
    80000ee8:	34c080e7          	jalr	844(ra) # 80002230 <scheduler>
}
    80000eec:	60a2                	ld	ra,8(sp)
    80000eee:	6402                	ld	s0,0(sp)
    80000ef0:	0141                	addi	sp,sp,16
    80000ef2:	8082                	ret
    consoleinit();
    80000ef4:	fffff097          	auipc	ra,0xfffff
    80000ef8:	55c080e7          	jalr	1372(ra) # 80000450 <consoleinit>
    printfinit();
    80000efc:	00000097          	auipc	ra,0x0
    80000f00:	872080e7          	jalr	-1934(ra) # 8000076e <printfinit>
    printf("\n");
    80000f04:	00007517          	auipc	a0,0x7
    80000f08:	42450513          	addi	a0,a0,1060 # 80008328 <digits+0x2e8>
    80000f0c:	fffff097          	auipc	ra,0xfffff
    80000f10:	67c080e7          	jalr	1660(ra) # 80000588 <printf>
    printf("xv6 kernel is booting\n");
    80000f14:	00007517          	auipc	a0,0x7
    80000f18:	18c50513          	addi	a0,a0,396 # 800080a0 <digits+0x60>
    80000f1c:	fffff097          	auipc	ra,0xfffff
    80000f20:	66c080e7          	jalr	1644(ra) # 80000588 <printf>
    printf("\n");
    80000f24:	00007517          	auipc	a0,0x7
    80000f28:	40450513          	addi	a0,a0,1028 # 80008328 <digits+0x2e8>
    80000f2c:	fffff097          	auipc	ra,0xfffff
    80000f30:	65c080e7          	jalr	1628(ra) # 80000588 <printf>
    kinit();         // physical page allocator
    80000f34:	00000097          	auipc	ra,0x0
    80000f38:	b84080e7          	jalr	-1148(ra) # 80000ab8 <kinit>
    kvminit();       // create kernel page table
    80000f3c:	00000097          	auipc	ra,0x0
    80000f40:	322080e7          	jalr	802(ra) # 8000125e <kvminit>
    kvminithart();   // turn on paging
    80000f44:	00000097          	auipc	ra,0x0
    80000f48:	068080e7          	jalr	104(ra) # 80000fac <kvminithart>
    procinit();      // process table
    80000f4c:	00001097          	auipc	ra,0x1
    80000f50:	990080e7          	jalr	-1648(ra) # 800018dc <procinit>
    trapinit();      // trap vectors
    80000f54:	00002097          	auipc	ra,0x2
    80000f58:	b9a080e7          	jalr	-1126(ra) # 80002aee <trapinit>
    trapinithart();  // install kernel trap vector
    80000f5c:	00002097          	auipc	ra,0x2
    80000f60:	bba080e7          	jalr	-1094(ra) # 80002b16 <trapinithart>
    plicinit();      // set up interrupt controller
    80000f64:	00005097          	auipc	ra,0x5
    80000f68:	166080e7          	jalr	358(ra) # 800060ca <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f6c:	00005097          	auipc	ra,0x5
    80000f70:	174080e7          	jalr	372(ra) # 800060e0 <plicinithart>
    binit();         // buffer cache
    80000f74:	00002097          	auipc	ra,0x2
    80000f78:	34c080e7          	jalr	844(ra) # 800032c0 <binit>
    iinit();         // inode table
    80000f7c:	00003097          	auipc	ra,0x3
    80000f80:	9dc080e7          	jalr	-1572(ra) # 80003958 <iinit>
    fileinit();      // file table
    80000f84:	00004097          	auipc	ra,0x4
    80000f88:	986080e7          	jalr	-1658(ra) # 8000490a <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f8c:	00005097          	auipc	ra,0x5
    80000f90:	276080e7          	jalr	630(ra) # 80006202 <virtio_disk_init>
    userinit();      // first user process
    80000f94:	00001097          	auipc	ra,0x1
    80000f98:	d2e080e7          	jalr	-722(ra) # 80001cc2 <userinit>
    __sync_synchronize();
    80000f9c:	0ff0000f          	fence
    started = 1;
    80000fa0:	4785                	li	a5,1
    80000fa2:	00008717          	auipc	a4,0x8
    80000fa6:	06f72b23          	sw	a5,118(a4) # 80009018 <started>
    80000faa:	bf2d                	j	80000ee4 <main+0x56>

0000000080000fac <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    80000fac:	1141                	addi	sp,sp,-16
    80000fae:	e422                	sd	s0,8(sp)
    80000fb0:	0800                	addi	s0,sp,16
  w_satp(MAKE_SATP(kernel_pagetable));
    80000fb2:	00008797          	auipc	a5,0x8
    80000fb6:	06e7b783          	ld	a5,110(a5) # 80009020 <kernel_pagetable>
    80000fba:	83b1                	srli	a5,a5,0xc
    80000fbc:	577d                	li	a4,-1
    80000fbe:	177e                	slli	a4,a4,0x3f
    80000fc0:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80000fc2:	18079073          	csrw	satp,a5
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80000fc6:	12000073          	sfence.vma
  sfence_vma();
}
    80000fca:	6422                	ld	s0,8(sp)
    80000fcc:	0141                	addi	sp,sp,16
    80000fce:	8082                	ret

0000000080000fd0 <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80000fd0:	7139                	addi	sp,sp,-64
    80000fd2:	fc06                	sd	ra,56(sp)
    80000fd4:	f822                	sd	s0,48(sp)
    80000fd6:	f426                	sd	s1,40(sp)
    80000fd8:	f04a                	sd	s2,32(sp)
    80000fda:	ec4e                	sd	s3,24(sp)
    80000fdc:	e852                	sd	s4,16(sp)
    80000fde:	e456                	sd	s5,8(sp)
    80000fe0:	e05a                	sd	s6,0(sp)
    80000fe2:	0080                	addi	s0,sp,64
    80000fe4:	84aa                	mv	s1,a0
    80000fe6:	89ae                	mv	s3,a1
    80000fe8:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80000fea:	57fd                	li	a5,-1
    80000fec:	83e9                	srli	a5,a5,0x1a
    80000fee:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80000ff0:	4b31                	li	s6,12
  if(va >= MAXVA)
    80000ff2:	04b7f263          	bgeu	a5,a1,80001036 <walk+0x66>
    panic("walk");
    80000ff6:	00007517          	auipc	a0,0x7
    80000ffa:	0da50513          	addi	a0,a0,218 # 800080d0 <digits+0x90>
    80000ffe:	fffff097          	auipc	ra,0xfffff
    80001002:	540080e7          	jalr	1344(ra) # 8000053e <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    80001006:	060a8663          	beqz	s5,80001072 <walk+0xa2>
    8000100a:	00000097          	auipc	ra,0x0
    8000100e:	aea080e7          	jalr	-1302(ra) # 80000af4 <kalloc>
    80001012:	84aa                	mv	s1,a0
    80001014:	c529                	beqz	a0,8000105e <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    80001016:	6605                	lui	a2,0x1
    80001018:	4581                	li	a1,0
    8000101a:	00000097          	auipc	ra,0x0
    8000101e:	cc6080e7          	jalr	-826(ra) # 80000ce0 <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    80001022:	00c4d793          	srli	a5,s1,0xc
    80001026:	07aa                	slli	a5,a5,0xa
    80001028:	0017e793          	ori	a5,a5,1
    8000102c:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    80001030:	3a5d                	addiw	s4,s4,-9
    80001032:	036a0063          	beq	s4,s6,80001052 <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    80001036:	0149d933          	srl	s2,s3,s4
    8000103a:	1ff97913          	andi	s2,s2,511
    8000103e:	090e                	slli	s2,s2,0x3
    80001040:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    80001042:	00093483          	ld	s1,0(s2)
    80001046:	0014f793          	andi	a5,s1,1
    8000104a:	dfd5                	beqz	a5,80001006 <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    8000104c:	80a9                	srli	s1,s1,0xa
    8000104e:	04b2                	slli	s1,s1,0xc
    80001050:	b7c5                	j	80001030 <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    80001052:	00c9d513          	srli	a0,s3,0xc
    80001056:	1ff57513          	andi	a0,a0,511
    8000105a:	050e                	slli	a0,a0,0x3
    8000105c:	9526                	add	a0,a0,s1
}
    8000105e:	70e2                	ld	ra,56(sp)
    80001060:	7442                	ld	s0,48(sp)
    80001062:	74a2                	ld	s1,40(sp)
    80001064:	7902                	ld	s2,32(sp)
    80001066:	69e2                	ld	s3,24(sp)
    80001068:	6a42                	ld	s4,16(sp)
    8000106a:	6aa2                	ld	s5,8(sp)
    8000106c:	6b02                	ld	s6,0(sp)
    8000106e:	6121                	addi	sp,sp,64
    80001070:	8082                	ret
        return 0;
    80001072:	4501                	li	a0,0
    80001074:	b7ed                	j	8000105e <walk+0x8e>

0000000080001076 <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    80001076:	57fd                	li	a5,-1
    80001078:	83e9                	srli	a5,a5,0x1a
    8000107a:	00b7f463          	bgeu	a5,a1,80001082 <walkaddr+0xc>
    return 0;
    8000107e:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    80001080:	8082                	ret
{
    80001082:	1141                	addi	sp,sp,-16
    80001084:	e406                	sd	ra,8(sp)
    80001086:	e022                	sd	s0,0(sp)
    80001088:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    8000108a:	4601                	li	a2,0
    8000108c:	00000097          	auipc	ra,0x0
    80001090:	f44080e7          	jalr	-188(ra) # 80000fd0 <walk>
  if(pte == 0)
    80001094:	c105                	beqz	a0,800010b4 <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    80001096:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    80001098:	0117f693          	andi	a3,a5,17
    8000109c:	4745                	li	a4,17
    return 0;
    8000109e:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    800010a0:	00e68663          	beq	a3,a4,800010ac <walkaddr+0x36>
}
    800010a4:	60a2                	ld	ra,8(sp)
    800010a6:	6402                	ld	s0,0(sp)
    800010a8:	0141                	addi	sp,sp,16
    800010aa:	8082                	ret
  pa = PTE2PA(*pte);
    800010ac:	00a7d513          	srli	a0,a5,0xa
    800010b0:	0532                	slli	a0,a0,0xc
  return pa;
    800010b2:	bfcd                	j	800010a4 <walkaddr+0x2e>
    return 0;
    800010b4:	4501                	li	a0,0
    800010b6:	b7fd                	j	800010a4 <walkaddr+0x2e>

00000000800010b8 <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    800010b8:	715d                	addi	sp,sp,-80
    800010ba:	e486                	sd	ra,72(sp)
    800010bc:	e0a2                	sd	s0,64(sp)
    800010be:	fc26                	sd	s1,56(sp)
    800010c0:	f84a                	sd	s2,48(sp)
    800010c2:	f44e                	sd	s3,40(sp)
    800010c4:	f052                	sd	s4,32(sp)
    800010c6:	ec56                	sd	s5,24(sp)
    800010c8:	e85a                	sd	s6,16(sp)
    800010ca:	e45e                	sd	s7,8(sp)
    800010cc:	0880                	addi	s0,sp,80
  uint64 a, last;
  pte_t *pte;

  if(size == 0)
    800010ce:	c205                	beqz	a2,800010ee <mappages+0x36>
    800010d0:	8aaa                	mv	s5,a0
    800010d2:	8b3a                	mv	s6,a4
    panic("mappages: size");
  
  a = PGROUNDDOWN(va);
    800010d4:	77fd                	lui	a5,0xfffff
    800010d6:	00f5fa33          	and	s4,a1,a5
  last = PGROUNDDOWN(va + size - 1);
    800010da:	15fd                	addi	a1,a1,-1
    800010dc:	00c589b3          	add	s3,a1,a2
    800010e0:	00f9f9b3          	and	s3,s3,a5
  a = PGROUNDDOWN(va);
    800010e4:	8952                	mv	s2,s4
    800010e6:	41468a33          	sub	s4,a3,s4
    if(*pte & PTE_V)
      panic("mappages: remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    800010ea:	6b85                	lui	s7,0x1
    800010ec:	a015                	j	80001110 <mappages+0x58>
    panic("mappages: size");
    800010ee:	00007517          	auipc	a0,0x7
    800010f2:	fea50513          	addi	a0,a0,-22 # 800080d8 <digits+0x98>
    800010f6:	fffff097          	auipc	ra,0xfffff
    800010fa:	448080e7          	jalr	1096(ra) # 8000053e <panic>
      panic("mappages: remap");
    800010fe:	00007517          	auipc	a0,0x7
    80001102:	fea50513          	addi	a0,a0,-22 # 800080e8 <digits+0xa8>
    80001106:	fffff097          	auipc	ra,0xfffff
    8000110a:	438080e7          	jalr	1080(ra) # 8000053e <panic>
    a += PGSIZE;
    8000110e:	995e                	add	s2,s2,s7
  for(;;){
    80001110:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    80001114:	4605                	li	a2,1
    80001116:	85ca                	mv	a1,s2
    80001118:	8556                	mv	a0,s5
    8000111a:	00000097          	auipc	ra,0x0
    8000111e:	eb6080e7          	jalr	-330(ra) # 80000fd0 <walk>
    80001122:	cd19                	beqz	a0,80001140 <mappages+0x88>
    if(*pte & PTE_V)
    80001124:	611c                	ld	a5,0(a0)
    80001126:	8b85                	andi	a5,a5,1
    80001128:	fbf9                	bnez	a5,800010fe <mappages+0x46>
    *pte = PA2PTE(pa) | perm | PTE_V;
    8000112a:	80b1                	srli	s1,s1,0xc
    8000112c:	04aa                	slli	s1,s1,0xa
    8000112e:	0164e4b3          	or	s1,s1,s6
    80001132:	0014e493          	ori	s1,s1,1
    80001136:	e104                	sd	s1,0(a0)
    if(a == last)
    80001138:	fd391be3          	bne	s2,s3,8000110e <mappages+0x56>
    pa += PGSIZE;
  }
  return 0;
    8000113c:	4501                	li	a0,0
    8000113e:	a011                	j	80001142 <mappages+0x8a>
      return -1;
    80001140:	557d                	li	a0,-1
}
    80001142:	60a6                	ld	ra,72(sp)
    80001144:	6406                	ld	s0,64(sp)
    80001146:	74e2                	ld	s1,56(sp)
    80001148:	7942                	ld	s2,48(sp)
    8000114a:	79a2                	ld	s3,40(sp)
    8000114c:	7a02                	ld	s4,32(sp)
    8000114e:	6ae2                	ld	s5,24(sp)
    80001150:	6b42                	ld	s6,16(sp)
    80001152:	6ba2                	ld	s7,8(sp)
    80001154:	6161                	addi	sp,sp,80
    80001156:	8082                	ret

0000000080001158 <kvmmap>:
{
    80001158:	1141                	addi	sp,sp,-16
    8000115a:	e406                	sd	ra,8(sp)
    8000115c:	e022                	sd	s0,0(sp)
    8000115e:	0800                	addi	s0,sp,16
    80001160:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    80001162:	86b2                	mv	a3,a2
    80001164:	863e                	mv	a2,a5
    80001166:	00000097          	auipc	ra,0x0
    8000116a:	f52080e7          	jalr	-174(ra) # 800010b8 <mappages>
    8000116e:	e509                	bnez	a0,80001178 <kvmmap+0x20>
}
    80001170:	60a2                	ld	ra,8(sp)
    80001172:	6402                	ld	s0,0(sp)
    80001174:	0141                	addi	sp,sp,16
    80001176:	8082                	ret
    panic("kvmmap");
    80001178:	00007517          	auipc	a0,0x7
    8000117c:	f8050513          	addi	a0,a0,-128 # 800080f8 <digits+0xb8>
    80001180:	fffff097          	auipc	ra,0xfffff
    80001184:	3be080e7          	jalr	958(ra) # 8000053e <panic>

0000000080001188 <kvmmake>:
{
    80001188:	1101                	addi	sp,sp,-32
    8000118a:	ec06                	sd	ra,24(sp)
    8000118c:	e822                	sd	s0,16(sp)
    8000118e:	e426                	sd	s1,8(sp)
    80001190:	e04a                	sd	s2,0(sp)
    80001192:	1000                	addi	s0,sp,32
  kpgtbl = (pagetable_t) kalloc();
    80001194:	00000097          	auipc	ra,0x0
    80001198:	960080e7          	jalr	-1696(ra) # 80000af4 <kalloc>
    8000119c:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    8000119e:	6605                	lui	a2,0x1
    800011a0:	4581                	li	a1,0
    800011a2:	00000097          	auipc	ra,0x0
    800011a6:	b3e080e7          	jalr	-1218(ra) # 80000ce0 <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    800011aa:	4719                	li	a4,6
    800011ac:	6685                	lui	a3,0x1
    800011ae:	10000637          	lui	a2,0x10000
    800011b2:	100005b7          	lui	a1,0x10000
    800011b6:	8526                	mv	a0,s1
    800011b8:	00000097          	auipc	ra,0x0
    800011bc:	fa0080e7          	jalr	-96(ra) # 80001158 <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    800011c0:	4719                	li	a4,6
    800011c2:	6685                	lui	a3,0x1
    800011c4:	10001637          	lui	a2,0x10001
    800011c8:	100015b7          	lui	a1,0x10001
    800011cc:	8526                	mv	a0,s1
    800011ce:	00000097          	auipc	ra,0x0
    800011d2:	f8a080e7          	jalr	-118(ra) # 80001158 <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    800011d6:	4719                	li	a4,6
    800011d8:	004006b7          	lui	a3,0x400
    800011dc:	0c000637          	lui	a2,0xc000
    800011e0:	0c0005b7          	lui	a1,0xc000
    800011e4:	8526                	mv	a0,s1
    800011e6:	00000097          	auipc	ra,0x0
    800011ea:	f72080e7          	jalr	-142(ra) # 80001158 <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    800011ee:	00007917          	auipc	s2,0x7
    800011f2:	e1290913          	addi	s2,s2,-494 # 80008000 <etext>
    800011f6:	4729                	li	a4,10
    800011f8:	80007697          	auipc	a3,0x80007
    800011fc:	e0868693          	addi	a3,a3,-504 # 8000 <_entry-0x7fff8000>
    80001200:	4605                	li	a2,1
    80001202:	067e                	slli	a2,a2,0x1f
    80001204:	85b2                	mv	a1,a2
    80001206:	8526                	mv	a0,s1
    80001208:	00000097          	auipc	ra,0x0
    8000120c:	f50080e7          	jalr	-176(ra) # 80001158 <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    80001210:	4719                	li	a4,6
    80001212:	46c5                	li	a3,17
    80001214:	06ee                	slli	a3,a3,0x1b
    80001216:	412686b3          	sub	a3,a3,s2
    8000121a:	864a                	mv	a2,s2
    8000121c:	85ca                	mv	a1,s2
    8000121e:	8526                	mv	a0,s1
    80001220:	00000097          	auipc	ra,0x0
    80001224:	f38080e7          	jalr	-200(ra) # 80001158 <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    80001228:	4729                	li	a4,10
    8000122a:	6685                	lui	a3,0x1
    8000122c:	00006617          	auipc	a2,0x6
    80001230:	dd460613          	addi	a2,a2,-556 # 80007000 <_trampoline>
    80001234:	040005b7          	lui	a1,0x4000
    80001238:	15fd                	addi	a1,a1,-1
    8000123a:	05b2                	slli	a1,a1,0xc
    8000123c:	8526                	mv	a0,s1
    8000123e:	00000097          	auipc	ra,0x0
    80001242:	f1a080e7          	jalr	-230(ra) # 80001158 <kvmmap>
  proc_mapstacks(kpgtbl);
    80001246:	8526                	mv	a0,s1
    80001248:	00000097          	auipc	ra,0x0
    8000124c:	5fe080e7          	jalr	1534(ra) # 80001846 <proc_mapstacks>
}
    80001250:	8526                	mv	a0,s1
    80001252:	60e2                	ld	ra,24(sp)
    80001254:	6442                	ld	s0,16(sp)
    80001256:	64a2                	ld	s1,8(sp)
    80001258:	6902                	ld	s2,0(sp)
    8000125a:	6105                	addi	sp,sp,32
    8000125c:	8082                	ret

000000008000125e <kvminit>:
{
    8000125e:	1141                	addi	sp,sp,-16
    80001260:	e406                	sd	ra,8(sp)
    80001262:	e022                	sd	s0,0(sp)
    80001264:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    80001266:	00000097          	auipc	ra,0x0
    8000126a:	f22080e7          	jalr	-222(ra) # 80001188 <kvmmake>
    8000126e:	00008797          	auipc	a5,0x8
    80001272:	daa7b923          	sd	a0,-590(a5) # 80009020 <kernel_pagetable>
}
    80001276:	60a2                	ld	ra,8(sp)
    80001278:	6402                	ld	s0,0(sp)
    8000127a:	0141                	addi	sp,sp,16
    8000127c:	8082                	ret

000000008000127e <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    8000127e:	715d                	addi	sp,sp,-80
    80001280:	e486                	sd	ra,72(sp)
    80001282:	e0a2                	sd	s0,64(sp)
    80001284:	fc26                	sd	s1,56(sp)
    80001286:	f84a                	sd	s2,48(sp)
    80001288:	f44e                	sd	s3,40(sp)
    8000128a:	f052                	sd	s4,32(sp)
    8000128c:	ec56                	sd	s5,24(sp)
    8000128e:	e85a                	sd	s6,16(sp)
    80001290:	e45e                	sd	s7,8(sp)
    80001292:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    80001294:	03459793          	slli	a5,a1,0x34
    80001298:	e795                	bnez	a5,800012c4 <uvmunmap+0x46>
    8000129a:	8a2a                	mv	s4,a0
    8000129c:	892e                	mv	s2,a1
    8000129e:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012a0:	0632                	slli	a2,a2,0xc
    800012a2:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    800012a6:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012a8:	6b05                	lui	s6,0x1
    800012aa:	0735e863          	bltu	a1,s3,8000131a <uvmunmap+0x9c>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    800012ae:	60a6                	ld	ra,72(sp)
    800012b0:	6406                	ld	s0,64(sp)
    800012b2:	74e2                	ld	s1,56(sp)
    800012b4:	7942                	ld	s2,48(sp)
    800012b6:	79a2                	ld	s3,40(sp)
    800012b8:	7a02                	ld	s4,32(sp)
    800012ba:	6ae2                	ld	s5,24(sp)
    800012bc:	6b42                	ld	s6,16(sp)
    800012be:	6ba2                	ld	s7,8(sp)
    800012c0:	6161                	addi	sp,sp,80
    800012c2:	8082                	ret
    panic("uvmunmap: not aligned");
    800012c4:	00007517          	auipc	a0,0x7
    800012c8:	e3c50513          	addi	a0,a0,-452 # 80008100 <digits+0xc0>
    800012cc:	fffff097          	auipc	ra,0xfffff
    800012d0:	272080e7          	jalr	626(ra) # 8000053e <panic>
      panic("uvmunmap: walk");
    800012d4:	00007517          	auipc	a0,0x7
    800012d8:	e4450513          	addi	a0,a0,-444 # 80008118 <digits+0xd8>
    800012dc:	fffff097          	auipc	ra,0xfffff
    800012e0:	262080e7          	jalr	610(ra) # 8000053e <panic>
      panic("uvmunmap: not mapped");
    800012e4:	00007517          	auipc	a0,0x7
    800012e8:	e4450513          	addi	a0,a0,-444 # 80008128 <digits+0xe8>
    800012ec:	fffff097          	auipc	ra,0xfffff
    800012f0:	252080e7          	jalr	594(ra) # 8000053e <panic>
      panic("uvmunmap: not a leaf");
    800012f4:	00007517          	auipc	a0,0x7
    800012f8:	e4c50513          	addi	a0,a0,-436 # 80008140 <digits+0x100>
    800012fc:	fffff097          	auipc	ra,0xfffff
    80001300:	242080e7          	jalr	578(ra) # 8000053e <panic>
      uint64 pa = PTE2PA(*pte);
    80001304:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    80001306:	0532                	slli	a0,a0,0xc
    80001308:	fffff097          	auipc	ra,0xfffff
    8000130c:	6f0080e7          	jalr	1776(ra) # 800009f8 <kfree>
    *pte = 0;
    80001310:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001314:	995a                	add	s2,s2,s6
    80001316:	f9397ce3          	bgeu	s2,s3,800012ae <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    8000131a:	4601                	li	a2,0
    8000131c:	85ca                	mv	a1,s2
    8000131e:	8552                	mv	a0,s4
    80001320:	00000097          	auipc	ra,0x0
    80001324:	cb0080e7          	jalr	-848(ra) # 80000fd0 <walk>
    80001328:	84aa                	mv	s1,a0
    8000132a:	d54d                	beqz	a0,800012d4 <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    8000132c:	6108                	ld	a0,0(a0)
    8000132e:	00157793          	andi	a5,a0,1
    80001332:	dbcd                	beqz	a5,800012e4 <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    80001334:	3ff57793          	andi	a5,a0,1023
    80001338:	fb778ee3          	beq	a5,s7,800012f4 <uvmunmap+0x76>
    if(do_free){
    8000133c:	fc0a8ae3          	beqz	s5,80001310 <uvmunmap+0x92>
    80001340:	b7d1                	j	80001304 <uvmunmap+0x86>

0000000080001342 <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    80001342:	1101                	addi	sp,sp,-32
    80001344:	ec06                	sd	ra,24(sp)
    80001346:	e822                	sd	s0,16(sp)
    80001348:	e426                	sd	s1,8(sp)
    8000134a:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    8000134c:	fffff097          	auipc	ra,0xfffff
    80001350:	7a8080e7          	jalr	1960(ra) # 80000af4 <kalloc>
    80001354:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001356:	c519                	beqz	a0,80001364 <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    80001358:	6605                	lui	a2,0x1
    8000135a:	4581                	li	a1,0
    8000135c:	00000097          	auipc	ra,0x0
    80001360:	984080e7          	jalr	-1660(ra) # 80000ce0 <memset>
  return pagetable;
}
    80001364:	8526                	mv	a0,s1
    80001366:	60e2                	ld	ra,24(sp)
    80001368:	6442                	ld	s0,16(sp)
    8000136a:	64a2                	ld	s1,8(sp)
    8000136c:	6105                	addi	sp,sp,32
    8000136e:	8082                	ret

0000000080001370 <uvminit>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvminit(pagetable_t pagetable, uchar *src, uint sz)
{
    80001370:	7179                	addi	sp,sp,-48
    80001372:	f406                	sd	ra,40(sp)
    80001374:	f022                	sd	s0,32(sp)
    80001376:	ec26                	sd	s1,24(sp)
    80001378:	e84a                	sd	s2,16(sp)
    8000137a:	e44e                	sd	s3,8(sp)
    8000137c:	e052                	sd	s4,0(sp)
    8000137e:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    80001380:	6785                	lui	a5,0x1
    80001382:	04f67863          	bgeu	a2,a5,800013d2 <uvminit+0x62>
    80001386:	8a2a                	mv	s4,a0
    80001388:	89ae                	mv	s3,a1
    8000138a:	84b2                	mv	s1,a2
    panic("inituvm: more than a page");
  mem = kalloc();
    8000138c:	fffff097          	auipc	ra,0xfffff
    80001390:	768080e7          	jalr	1896(ra) # 80000af4 <kalloc>
    80001394:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    80001396:	6605                	lui	a2,0x1
    80001398:	4581                	li	a1,0
    8000139a:	00000097          	auipc	ra,0x0
    8000139e:	946080e7          	jalr	-1722(ra) # 80000ce0 <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    800013a2:	4779                	li	a4,30
    800013a4:	86ca                	mv	a3,s2
    800013a6:	6605                	lui	a2,0x1
    800013a8:	4581                	li	a1,0
    800013aa:	8552                	mv	a0,s4
    800013ac:	00000097          	auipc	ra,0x0
    800013b0:	d0c080e7          	jalr	-756(ra) # 800010b8 <mappages>
  memmove(mem, src, sz);
    800013b4:	8626                	mv	a2,s1
    800013b6:	85ce                	mv	a1,s3
    800013b8:	854a                	mv	a0,s2
    800013ba:	00000097          	auipc	ra,0x0
    800013be:	986080e7          	jalr	-1658(ra) # 80000d40 <memmove>
}
    800013c2:	70a2                	ld	ra,40(sp)
    800013c4:	7402                	ld	s0,32(sp)
    800013c6:	64e2                	ld	s1,24(sp)
    800013c8:	6942                	ld	s2,16(sp)
    800013ca:	69a2                	ld	s3,8(sp)
    800013cc:	6a02                	ld	s4,0(sp)
    800013ce:	6145                	addi	sp,sp,48
    800013d0:	8082                	ret
    panic("inituvm: more than a page");
    800013d2:	00007517          	auipc	a0,0x7
    800013d6:	d8650513          	addi	a0,a0,-634 # 80008158 <digits+0x118>
    800013da:	fffff097          	auipc	ra,0xfffff
    800013de:	164080e7          	jalr	356(ra) # 8000053e <panic>

00000000800013e2 <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    800013e2:	1101                	addi	sp,sp,-32
    800013e4:	ec06                	sd	ra,24(sp)
    800013e6:	e822                	sd	s0,16(sp)
    800013e8:	e426                	sd	s1,8(sp)
    800013ea:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    800013ec:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    800013ee:	00b67d63          	bgeu	a2,a1,80001408 <uvmdealloc+0x26>
    800013f2:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    800013f4:	6785                	lui	a5,0x1
    800013f6:	17fd                	addi	a5,a5,-1
    800013f8:	00f60733          	add	a4,a2,a5
    800013fc:	767d                	lui	a2,0xfffff
    800013fe:	8f71                	and	a4,a4,a2
    80001400:	97ae                	add	a5,a5,a1
    80001402:	8ff1                	and	a5,a5,a2
    80001404:	00f76863          	bltu	a4,a5,80001414 <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    80001408:	8526                	mv	a0,s1
    8000140a:	60e2                	ld	ra,24(sp)
    8000140c:	6442                	ld	s0,16(sp)
    8000140e:	64a2                	ld	s1,8(sp)
    80001410:	6105                	addi	sp,sp,32
    80001412:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    80001414:	8f99                	sub	a5,a5,a4
    80001416:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    80001418:	4685                	li	a3,1
    8000141a:	0007861b          	sext.w	a2,a5
    8000141e:	85ba                	mv	a1,a4
    80001420:	00000097          	auipc	ra,0x0
    80001424:	e5e080e7          	jalr	-418(ra) # 8000127e <uvmunmap>
    80001428:	b7c5                	j	80001408 <uvmdealloc+0x26>

000000008000142a <uvmalloc>:
  if(newsz < oldsz)
    8000142a:	0ab66163          	bltu	a2,a1,800014cc <uvmalloc+0xa2>
{
    8000142e:	7139                	addi	sp,sp,-64
    80001430:	fc06                	sd	ra,56(sp)
    80001432:	f822                	sd	s0,48(sp)
    80001434:	f426                	sd	s1,40(sp)
    80001436:	f04a                	sd	s2,32(sp)
    80001438:	ec4e                	sd	s3,24(sp)
    8000143a:	e852                	sd	s4,16(sp)
    8000143c:	e456                	sd	s5,8(sp)
    8000143e:	0080                	addi	s0,sp,64
    80001440:	8aaa                	mv	s5,a0
    80001442:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    80001444:	6985                	lui	s3,0x1
    80001446:	19fd                	addi	s3,s3,-1
    80001448:	95ce                	add	a1,a1,s3
    8000144a:	79fd                	lui	s3,0xfffff
    8000144c:	0135f9b3          	and	s3,a1,s3
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001450:	08c9f063          	bgeu	s3,a2,800014d0 <uvmalloc+0xa6>
    80001454:	894e                	mv	s2,s3
    mem = kalloc();
    80001456:	fffff097          	auipc	ra,0xfffff
    8000145a:	69e080e7          	jalr	1694(ra) # 80000af4 <kalloc>
    8000145e:	84aa                	mv	s1,a0
    if(mem == 0){
    80001460:	c51d                	beqz	a0,8000148e <uvmalloc+0x64>
    memset(mem, 0, PGSIZE);
    80001462:	6605                	lui	a2,0x1
    80001464:	4581                	li	a1,0
    80001466:	00000097          	auipc	ra,0x0
    8000146a:	87a080e7          	jalr	-1926(ra) # 80000ce0 <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_W|PTE_X|PTE_R|PTE_U) != 0){
    8000146e:	4779                	li	a4,30
    80001470:	86a6                	mv	a3,s1
    80001472:	6605                	lui	a2,0x1
    80001474:	85ca                	mv	a1,s2
    80001476:	8556                	mv	a0,s5
    80001478:	00000097          	auipc	ra,0x0
    8000147c:	c40080e7          	jalr	-960(ra) # 800010b8 <mappages>
    80001480:	e905                	bnez	a0,800014b0 <uvmalloc+0x86>
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001482:	6785                	lui	a5,0x1
    80001484:	993e                	add	s2,s2,a5
    80001486:	fd4968e3          	bltu	s2,s4,80001456 <uvmalloc+0x2c>
  return newsz;
    8000148a:	8552                	mv	a0,s4
    8000148c:	a809                	j	8000149e <uvmalloc+0x74>
      uvmdealloc(pagetable, a, oldsz);
    8000148e:	864e                	mv	a2,s3
    80001490:	85ca                	mv	a1,s2
    80001492:	8556                	mv	a0,s5
    80001494:	00000097          	auipc	ra,0x0
    80001498:	f4e080e7          	jalr	-178(ra) # 800013e2 <uvmdealloc>
      return 0;
    8000149c:	4501                	li	a0,0
}
    8000149e:	70e2                	ld	ra,56(sp)
    800014a0:	7442                	ld	s0,48(sp)
    800014a2:	74a2                	ld	s1,40(sp)
    800014a4:	7902                	ld	s2,32(sp)
    800014a6:	69e2                	ld	s3,24(sp)
    800014a8:	6a42                	ld	s4,16(sp)
    800014aa:	6aa2                	ld	s5,8(sp)
    800014ac:	6121                	addi	sp,sp,64
    800014ae:	8082                	ret
      kfree(mem);
    800014b0:	8526                	mv	a0,s1
    800014b2:	fffff097          	auipc	ra,0xfffff
    800014b6:	546080e7          	jalr	1350(ra) # 800009f8 <kfree>
      uvmdealloc(pagetable, a, oldsz);
    800014ba:	864e                	mv	a2,s3
    800014bc:	85ca                	mv	a1,s2
    800014be:	8556                	mv	a0,s5
    800014c0:	00000097          	auipc	ra,0x0
    800014c4:	f22080e7          	jalr	-222(ra) # 800013e2 <uvmdealloc>
      return 0;
    800014c8:	4501                	li	a0,0
    800014ca:	bfd1                	j	8000149e <uvmalloc+0x74>
    return oldsz;
    800014cc:	852e                	mv	a0,a1
}
    800014ce:	8082                	ret
  return newsz;
    800014d0:	8532                	mv	a0,a2
    800014d2:	b7f1                	j	8000149e <uvmalloc+0x74>

00000000800014d4 <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    800014d4:	7179                	addi	sp,sp,-48
    800014d6:	f406                	sd	ra,40(sp)
    800014d8:	f022                	sd	s0,32(sp)
    800014da:	ec26                	sd	s1,24(sp)
    800014dc:	e84a                	sd	s2,16(sp)
    800014de:	e44e                	sd	s3,8(sp)
    800014e0:	e052                	sd	s4,0(sp)
    800014e2:	1800                	addi	s0,sp,48
    800014e4:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    800014e6:	84aa                	mv	s1,a0
    800014e8:	6905                	lui	s2,0x1
    800014ea:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800014ec:	4985                	li	s3,1
    800014ee:	a821                	j	80001506 <freewalk+0x32>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    800014f0:	8129                	srli	a0,a0,0xa
      freewalk((pagetable_t)child);
    800014f2:	0532                	slli	a0,a0,0xc
    800014f4:	00000097          	auipc	ra,0x0
    800014f8:	fe0080e7          	jalr	-32(ra) # 800014d4 <freewalk>
      pagetable[i] = 0;
    800014fc:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    80001500:	04a1                	addi	s1,s1,8
    80001502:	03248163          	beq	s1,s2,80001524 <freewalk+0x50>
    pte_t pte = pagetable[i];
    80001506:	6088                	ld	a0,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80001508:	00f57793          	andi	a5,a0,15
    8000150c:	ff3782e3          	beq	a5,s3,800014f0 <freewalk+0x1c>
    } else if(pte & PTE_V){
    80001510:	8905                	andi	a0,a0,1
    80001512:	d57d                	beqz	a0,80001500 <freewalk+0x2c>
      panic("freewalk: leaf");
    80001514:	00007517          	auipc	a0,0x7
    80001518:	c6450513          	addi	a0,a0,-924 # 80008178 <digits+0x138>
    8000151c:	fffff097          	auipc	ra,0xfffff
    80001520:	022080e7          	jalr	34(ra) # 8000053e <panic>
    }
  }
  kfree((void*)pagetable);
    80001524:	8552                	mv	a0,s4
    80001526:	fffff097          	auipc	ra,0xfffff
    8000152a:	4d2080e7          	jalr	1234(ra) # 800009f8 <kfree>
}
    8000152e:	70a2                	ld	ra,40(sp)
    80001530:	7402                	ld	s0,32(sp)
    80001532:	64e2                	ld	s1,24(sp)
    80001534:	6942                	ld	s2,16(sp)
    80001536:	69a2                	ld	s3,8(sp)
    80001538:	6a02                	ld	s4,0(sp)
    8000153a:	6145                	addi	sp,sp,48
    8000153c:	8082                	ret

000000008000153e <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    8000153e:	1101                	addi	sp,sp,-32
    80001540:	ec06                	sd	ra,24(sp)
    80001542:	e822                	sd	s0,16(sp)
    80001544:	e426                	sd	s1,8(sp)
    80001546:	1000                	addi	s0,sp,32
    80001548:	84aa                	mv	s1,a0
  if(sz > 0)
    8000154a:	e999                	bnez	a1,80001560 <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    8000154c:	8526                	mv	a0,s1
    8000154e:	00000097          	auipc	ra,0x0
    80001552:	f86080e7          	jalr	-122(ra) # 800014d4 <freewalk>
}
    80001556:	60e2                	ld	ra,24(sp)
    80001558:	6442                	ld	s0,16(sp)
    8000155a:	64a2                	ld	s1,8(sp)
    8000155c:	6105                	addi	sp,sp,32
    8000155e:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    80001560:	6605                	lui	a2,0x1
    80001562:	167d                	addi	a2,a2,-1
    80001564:	962e                	add	a2,a2,a1
    80001566:	4685                	li	a3,1
    80001568:	8231                	srli	a2,a2,0xc
    8000156a:	4581                	li	a1,0
    8000156c:	00000097          	auipc	ra,0x0
    80001570:	d12080e7          	jalr	-750(ra) # 8000127e <uvmunmap>
    80001574:	bfe1                	j	8000154c <uvmfree+0xe>

0000000080001576 <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    80001576:	c679                	beqz	a2,80001644 <uvmcopy+0xce>
{
    80001578:	715d                	addi	sp,sp,-80
    8000157a:	e486                	sd	ra,72(sp)
    8000157c:	e0a2                	sd	s0,64(sp)
    8000157e:	fc26                	sd	s1,56(sp)
    80001580:	f84a                	sd	s2,48(sp)
    80001582:	f44e                	sd	s3,40(sp)
    80001584:	f052                	sd	s4,32(sp)
    80001586:	ec56                	sd	s5,24(sp)
    80001588:	e85a                	sd	s6,16(sp)
    8000158a:	e45e                	sd	s7,8(sp)
    8000158c:	0880                	addi	s0,sp,80
    8000158e:	8b2a                	mv	s6,a0
    80001590:	8aae                	mv	s5,a1
    80001592:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    80001594:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    80001596:	4601                	li	a2,0
    80001598:	85ce                	mv	a1,s3
    8000159a:	855a                	mv	a0,s6
    8000159c:	00000097          	auipc	ra,0x0
    800015a0:	a34080e7          	jalr	-1484(ra) # 80000fd0 <walk>
    800015a4:	c531                	beqz	a0,800015f0 <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    800015a6:	6118                	ld	a4,0(a0)
    800015a8:	00177793          	andi	a5,a4,1
    800015ac:	cbb1                	beqz	a5,80001600 <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    800015ae:	00a75593          	srli	a1,a4,0xa
    800015b2:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    800015b6:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    800015ba:	fffff097          	auipc	ra,0xfffff
    800015be:	53a080e7          	jalr	1338(ra) # 80000af4 <kalloc>
    800015c2:	892a                	mv	s2,a0
    800015c4:	c939                	beqz	a0,8000161a <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    800015c6:	6605                	lui	a2,0x1
    800015c8:	85de                	mv	a1,s7
    800015ca:	fffff097          	auipc	ra,0xfffff
    800015ce:	776080e7          	jalr	1910(ra) # 80000d40 <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    800015d2:	8726                	mv	a4,s1
    800015d4:	86ca                	mv	a3,s2
    800015d6:	6605                	lui	a2,0x1
    800015d8:	85ce                	mv	a1,s3
    800015da:	8556                	mv	a0,s5
    800015dc:	00000097          	auipc	ra,0x0
    800015e0:	adc080e7          	jalr	-1316(ra) # 800010b8 <mappages>
    800015e4:	e515                	bnez	a0,80001610 <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    800015e6:	6785                	lui	a5,0x1
    800015e8:	99be                	add	s3,s3,a5
    800015ea:	fb49e6e3          	bltu	s3,s4,80001596 <uvmcopy+0x20>
    800015ee:	a081                	j	8000162e <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    800015f0:	00007517          	auipc	a0,0x7
    800015f4:	b9850513          	addi	a0,a0,-1128 # 80008188 <digits+0x148>
    800015f8:	fffff097          	auipc	ra,0xfffff
    800015fc:	f46080e7          	jalr	-186(ra) # 8000053e <panic>
      panic("uvmcopy: page not present");
    80001600:	00007517          	auipc	a0,0x7
    80001604:	ba850513          	addi	a0,a0,-1112 # 800081a8 <digits+0x168>
    80001608:	fffff097          	auipc	ra,0xfffff
    8000160c:	f36080e7          	jalr	-202(ra) # 8000053e <panic>
      kfree(mem);
    80001610:	854a                	mv	a0,s2
    80001612:	fffff097          	auipc	ra,0xfffff
    80001616:	3e6080e7          	jalr	998(ra) # 800009f8 <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    8000161a:	4685                	li	a3,1
    8000161c:	00c9d613          	srli	a2,s3,0xc
    80001620:	4581                	li	a1,0
    80001622:	8556                	mv	a0,s5
    80001624:	00000097          	auipc	ra,0x0
    80001628:	c5a080e7          	jalr	-934(ra) # 8000127e <uvmunmap>
  return -1;
    8000162c:	557d                	li	a0,-1
}
    8000162e:	60a6                	ld	ra,72(sp)
    80001630:	6406                	ld	s0,64(sp)
    80001632:	74e2                	ld	s1,56(sp)
    80001634:	7942                	ld	s2,48(sp)
    80001636:	79a2                	ld	s3,40(sp)
    80001638:	7a02                	ld	s4,32(sp)
    8000163a:	6ae2                	ld	s5,24(sp)
    8000163c:	6b42                	ld	s6,16(sp)
    8000163e:	6ba2                	ld	s7,8(sp)
    80001640:	6161                	addi	sp,sp,80
    80001642:	8082                	ret
  return 0;
    80001644:	4501                	li	a0,0
}
    80001646:	8082                	ret

0000000080001648 <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    80001648:	1141                	addi	sp,sp,-16
    8000164a:	e406                	sd	ra,8(sp)
    8000164c:	e022                	sd	s0,0(sp)
    8000164e:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    80001650:	4601                	li	a2,0
    80001652:	00000097          	auipc	ra,0x0
    80001656:	97e080e7          	jalr	-1666(ra) # 80000fd0 <walk>
  if(pte == 0)
    8000165a:	c901                	beqz	a0,8000166a <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    8000165c:	611c                	ld	a5,0(a0)
    8000165e:	9bbd                	andi	a5,a5,-17
    80001660:	e11c                	sd	a5,0(a0)
}
    80001662:	60a2                	ld	ra,8(sp)
    80001664:	6402                	ld	s0,0(sp)
    80001666:	0141                	addi	sp,sp,16
    80001668:	8082                	ret
    panic("uvmclear");
    8000166a:	00007517          	auipc	a0,0x7
    8000166e:	b5e50513          	addi	a0,a0,-1186 # 800081c8 <digits+0x188>
    80001672:	fffff097          	auipc	ra,0xfffff
    80001676:	ecc080e7          	jalr	-308(ra) # 8000053e <panic>

000000008000167a <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    8000167a:	c6bd                	beqz	a3,800016e8 <copyout+0x6e>
{
    8000167c:	715d                	addi	sp,sp,-80
    8000167e:	e486                	sd	ra,72(sp)
    80001680:	e0a2                	sd	s0,64(sp)
    80001682:	fc26                	sd	s1,56(sp)
    80001684:	f84a                	sd	s2,48(sp)
    80001686:	f44e                	sd	s3,40(sp)
    80001688:	f052                	sd	s4,32(sp)
    8000168a:	ec56                	sd	s5,24(sp)
    8000168c:	e85a                	sd	s6,16(sp)
    8000168e:	e45e                	sd	s7,8(sp)
    80001690:	e062                	sd	s8,0(sp)
    80001692:	0880                	addi	s0,sp,80
    80001694:	8b2a                	mv	s6,a0
    80001696:	8c2e                	mv	s8,a1
    80001698:	8a32                	mv	s4,a2
    8000169a:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    8000169c:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    8000169e:	6a85                	lui	s5,0x1
    800016a0:	a015                	j	800016c4 <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    800016a2:	9562                	add	a0,a0,s8
    800016a4:	0004861b          	sext.w	a2,s1
    800016a8:	85d2                	mv	a1,s4
    800016aa:	41250533          	sub	a0,a0,s2
    800016ae:	fffff097          	auipc	ra,0xfffff
    800016b2:	692080e7          	jalr	1682(ra) # 80000d40 <memmove>

    len -= n;
    800016b6:	409989b3          	sub	s3,s3,s1
    src += n;
    800016ba:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    800016bc:	01590c33          	add	s8,s2,s5
  while(len > 0){
    800016c0:	02098263          	beqz	s3,800016e4 <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    800016c4:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    800016c8:	85ca                	mv	a1,s2
    800016ca:	855a                	mv	a0,s6
    800016cc:	00000097          	auipc	ra,0x0
    800016d0:	9aa080e7          	jalr	-1622(ra) # 80001076 <walkaddr>
    if(pa0 == 0)
    800016d4:	cd01                	beqz	a0,800016ec <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    800016d6:	418904b3          	sub	s1,s2,s8
    800016da:	94d6                	add	s1,s1,s5
    if(n > len)
    800016dc:	fc99f3e3          	bgeu	s3,s1,800016a2 <copyout+0x28>
    800016e0:	84ce                	mv	s1,s3
    800016e2:	b7c1                	j	800016a2 <copyout+0x28>
  }
  return 0;
    800016e4:	4501                	li	a0,0
    800016e6:	a021                	j	800016ee <copyout+0x74>
    800016e8:	4501                	li	a0,0
}
    800016ea:	8082                	ret
      return -1;
    800016ec:	557d                	li	a0,-1
}
    800016ee:	60a6                	ld	ra,72(sp)
    800016f0:	6406                	ld	s0,64(sp)
    800016f2:	74e2                	ld	s1,56(sp)
    800016f4:	7942                	ld	s2,48(sp)
    800016f6:	79a2                	ld	s3,40(sp)
    800016f8:	7a02                	ld	s4,32(sp)
    800016fa:	6ae2                	ld	s5,24(sp)
    800016fc:	6b42                	ld	s6,16(sp)
    800016fe:	6ba2                	ld	s7,8(sp)
    80001700:	6c02                	ld	s8,0(sp)
    80001702:	6161                	addi	sp,sp,80
    80001704:	8082                	ret

0000000080001706 <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001706:	c6bd                	beqz	a3,80001774 <copyin+0x6e>
{
    80001708:	715d                	addi	sp,sp,-80
    8000170a:	e486                	sd	ra,72(sp)
    8000170c:	e0a2                	sd	s0,64(sp)
    8000170e:	fc26                	sd	s1,56(sp)
    80001710:	f84a                	sd	s2,48(sp)
    80001712:	f44e                	sd	s3,40(sp)
    80001714:	f052                	sd	s4,32(sp)
    80001716:	ec56                	sd	s5,24(sp)
    80001718:	e85a                	sd	s6,16(sp)
    8000171a:	e45e                	sd	s7,8(sp)
    8000171c:	e062                	sd	s8,0(sp)
    8000171e:	0880                	addi	s0,sp,80
    80001720:	8b2a                	mv	s6,a0
    80001722:	8a2e                	mv	s4,a1
    80001724:	8c32                	mv	s8,a2
    80001726:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    80001728:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    8000172a:	6a85                	lui	s5,0x1
    8000172c:	a015                	j	80001750 <copyin+0x4a>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    8000172e:	9562                	add	a0,a0,s8
    80001730:	0004861b          	sext.w	a2,s1
    80001734:	412505b3          	sub	a1,a0,s2
    80001738:	8552                	mv	a0,s4
    8000173a:	fffff097          	auipc	ra,0xfffff
    8000173e:	606080e7          	jalr	1542(ra) # 80000d40 <memmove>

    len -= n;
    80001742:	409989b3          	sub	s3,s3,s1
    dst += n;
    80001746:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    80001748:	01590c33          	add	s8,s2,s5
  while(len > 0){
    8000174c:	02098263          	beqz	s3,80001770 <copyin+0x6a>
    va0 = PGROUNDDOWN(srcva);
    80001750:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    80001754:	85ca                	mv	a1,s2
    80001756:	855a                	mv	a0,s6
    80001758:	00000097          	auipc	ra,0x0
    8000175c:	91e080e7          	jalr	-1762(ra) # 80001076 <walkaddr>
    if(pa0 == 0)
    80001760:	cd01                	beqz	a0,80001778 <copyin+0x72>
    n = PGSIZE - (srcva - va0);
    80001762:	418904b3          	sub	s1,s2,s8
    80001766:	94d6                	add	s1,s1,s5
    if(n > len)
    80001768:	fc99f3e3          	bgeu	s3,s1,8000172e <copyin+0x28>
    8000176c:	84ce                	mv	s1,s3
    8000176e:	b7c1                	j	8000172e <copyin+0x28>
  }
  return 0;
    80001770:	4501                	li	a0,0
    80001772:	a021                	j	8000177a <copyin+0x74>
    80001774:	4501                	li	a0,0
}
    80001776:	8082                	ret
      return -1;
    80001778:	557d                	li	a0,-1
}
    8000177a:	60a6                	ld	ra,72(sp)
    8000177c:	6406                	ld	s0,64(sp)
    8000177e:	74e2                	ld	s1,56(sp)
    80001780:	7942                	ld	s2,48(sp)
    80001782:	79a2                	ld	s3,40(sp)
    80001784:	7a02                	ld	s4,32(sp)
    80001786:	6ae2                	ld	s5,24(sp)
    80001788:	6b42                	ld	s6,16(sp)
    8000178a:	6ba2                	ld	s7,8(sp)
    8000178c:	6c02                	ld	s8,0(sp)
    8000178e:	6161                	addi	sp,sp,80
    80001790:	8082                	ret

0000000080001792 <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    80001792:	c6c5                	beqz	a3,8000183a <copyinstr+0xa8>
{
    80001794:	715d                	addi	sp,sp,-80
    80001796:	e486                	sd	ra,72(sp)
    80001798:	e0a2                	sd	s0,64(sp)
    8000179a:	fc26                	sd	s1,56(sp)
    8000179c:	f84a                	sd	s2,48(sp)
    8000179e:	f44e                	sd	s3,40(sp)
    800017a0:	f052                	sd	s4,32(sp)
    800017a2:	ec56                	sd	s5,24(sp)
    800017a4:	e85a                	sd	s6,16(sp)
    800017a6:	e45e                	sd	s7,8(sp)
    800017a8:	0880                	addi	s0,sp,80
    800017aa:	8a2a                	mv	s4,a0
    800017ac:	8b2e                	mv	s6,a1
    800017ae:	8bb2                	mv	s7,a2
    800017b0:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    800017b2:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800017b4:	6985                	lui	s3,0x1
    800017b6:	a035                	j	800017e2 <copyinstr+0x50>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    800017b8:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    800017bc:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    800017be:	0017b793          	seqz	a5,a5
    800017c2:	40f00533          	neg	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    800017c6:	60a6                	ld	ra,72(sp)
    800017c8:	6406                	ld	s0,64(sp)
    800017ca:	74e2                	ld	s1,56(sp)
    800017cc:	7942                	ld	s2,48(sp)
    800017ce:	79a2                	ld	s3,40(sp)
    800017d0:	7a02                	ld	s4,32(sp)
    800017d2:	6ae2                	ld	s5,24(sp)
    800017d4:	6b42                	ld	s6,16(sp)
    800017d6:	6ba2                	ld	s7,8(sp)
    800017d8:	6161                	addi	sp,sp,80
    800017da:	8082                	ret
    srcva = va0 + PGSIZE;
    800017dc:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    800017e0:	c8a9                	beqz	s1,80001832 <copyinstr+0xa0>
    va0 = PGROUNDDOWN(srcva);
    800017e2:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    800017e6:	85ca                	mv	a1,s2
    800017e8:	8552                	mv	a0,s4
    800017ea:	00000097          	auipc	ra,0x0
    800017ee:	88c080e7          	jalr	-1908(ra) # 80001076 <walkaddr>
    if(pa0 == 0)
    800017f2:	c131                	beqz	a0,80001836 <copyinstr+0xa4>
    n = PGSIZE - (srcva - va0);
    800017f4:	41790833          	sub	a6,s2,s7
    800017f8:	984e                	add	a6,a6,s3
    if(n > max)
    800017fa:	0104f363          	bgeu	s1,a6,80001800 <copyinstr+0x6e>
    800017fe:	8826                	mv	a6,s1
    char *p = (char *) (pa0 + (srcva - va0));
    80001800:	955e                	add	a0,a0,s7
    80001802:	41250533          	sub	a0,a0,s2
    while(n > 0){
    80001806:	fc080be3          	beqz	a6,800017dc <copyinstr+0x4a>
    8000180a:	985a                	add	a6,a6,s6
    8000180c:	87da                	mv	a5,s6
      if(*p == '\0'){
    8000180e:	41650633          	sub	a2,a0,s6
    80001812:	14fd                	addi	s1,s1,-1
    80001814:	9b26                	add	s6,s6,s1
    80001816:	00f60733          	add	a4,a2,a5
    8000181a:	00074703          	lbu	a4,0(a4)
    8000181e:	df49                	beqz	a4,800017b8 <copyinstr+0x26>
        *dst = *p;
    80001820:	00e78023          	sb	a4,0(a5)
      --max;
    80001824:	40fb04b3          	sub	s1,s6,a5
      dst++;
    80001828:	0785                	addi	a5,a5,1
    while(n > 0){
    8000182a:	ff0796e3          	bne	a5,a6,80001816 <copyinstr+0x84>
      dst++;
    8000182e:	8b42                	mv	s6,a6
    80001830:	b775                	j	800017dc <copyinstr+0x4a>
    80001832:	4781                	li	a5,0
    80001834:	b769                	j	800017be <copyinstr+0x2c>
      return -1;
    80001836:	557d                	li	a0,-1
    80001838:	b779                	j	800017c6 <copyinstr+0x34>
  int got_null = 0;
    8000183a:	4781                	li	a5,0
  if(got_null){
    8000183c:	0017b793          	seqz	a5,a5
    80001840:	40f00533          	neg	a0,a5
}
    80001844:	8082                	ret

0000000080001846 <proc_mapstacks>:

// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void
proc_mapstacks(pagetable_t kpgtbl) {
    80001846:	7139                	addi	sp,sp,-64
    80001848:	fc06                	sd	ra,56(sp)
    8000184a:	f822                	sd	s0,48(sp)
    8000184c:	f426                	sd	s1,40(sp)
    8000184e:	f04a                	sd	s2,32(sp)
    80001850:	ec4e                	sd	s3,24(sp)
    80001852:	e852                	sd	s4,16(sp)
    80001854:	e456                	sd	s5,8(sp)
    80001856:	e05a                	sd	s6,0(sp)
    80001858:	0080                	addi	s0,sp,64
    8000185a:	89aa                	mv	s3,a0
    struct proc *p;

    for (p = proc; p < &proc[NPROC]; p++) {
    8000185c:	00010497          	auipc	s1,0x10
    80001860:	e9448493          	addi	s1,s1,-364 # 800116f0 <proc>
        char *pa = kalloc();
        if (pa == 0)
            panic("kalloc");
        uint64 va = KSTACK((int) (p - proc));
    80001864:	8b26                	mv	s6,s1
    80001866:	00006a97          	auipc	s5,0x6
    8000186a:	79aa8a93          	addi	s5,s5,1946 # 80008000 <etext>
    8000186e:	04000937          	lui	s2,0x4000
    80001872:	197d                	addi	s2,s2,-1
    80001874:	0932                	slli	s2,s2,0xc
    for (p = proc; p < &proc[NPROC]; p++) {
    80001876:	00016a17          	auipc	s4,0x16
    8000187a:	07aa0a13          	addi	s4,s4,122 # 800178f0 <tickslock>
        char *pa = kalloc();
    8000187e:	fffff097          	auipc	ra,0xfffff
    80001882:	276080e7          	jalr	630(ra) # 80000af4 <kalloc>
    80001886:	862a                	mv	a2,a0
        if (pa == 0)
    80001888:	c131                	beqz	a0,800018cc <proc_mapstacks+0x86>
        uint64 va = KSTACK((int) (p - proc));
    8000188a:	416485b3          	sub	a1,s1,s6
    8000188e:	858d                	srai	a1,a1,0x3
    80001890:	000ab783          	ld	a5,0(s5)
    80001894:	02f585b3          	mul	a1,a1,a5
    80001898:	2585                	addiw	a1,a1,1
    8000189a:	00d5959b          	slliw	a1,a1,0xd
        kvmmap(kpgtbl, va, (uint64) pa, PGSIZE, PTE_R | PTE_W);
    8000189e:	4719                	li	a4,6
    800018a0:	6685                	lui	a3,0x1
    800018a2:	40b905b3          	sub	a1,s2,a1
    800018a6:	854e                	mv	a0,s3
    800018a8:	00000097          	auipc	ra,0x0
    800018ac:	8b0080e7          	jalr	-1872(ra) # 80001158 <kvmmap>
    for (p = proc; p < &proc[NPROC]; p++) {
    800018b0:	18848493          	addi	s1,s1,392
    800018b4:	fd4495e3          	bne	s1,s4,8000187e <proc_mapstacks+0x38>
    }
}
    800018b8:	70e2                	ld	ra,56(sp)
    800018ba:	7442                	ld	s0,48(sp)
    800018bc:	74a2                	ld	s1,40(sp)
    800018be:	7902                	ld	s2,32(sp)
    800018c0:	69e2                	ld	s3,24(sp)
    800018c2:	6a42                	ld	s4,16(sp)
    800018c4:	6aa2                	ld	s5,8(sp)
    800018c6:	6b02                	ld	s6,0(sp)
    800018c8:	6121                	addi	sp,sp,64
    800018ca:	8082                	ret
            panic("kalloc");
    800018cc:	00007517          	auipc	a0,0x7
    800018d0:	90c50513          	addi	a0,a0,-1780 # 800081d8 <digits+0x198>
    800018d4:	fffff097          	auipc	ra,0xfffff
    800018d8:	c6a080e7          	jalr	-918(ra) # 8000053e <panic>

00000000800018dc <procinit>:

// initialize the proc table at boot time.
void
procinit(void) {
    800018dc:	7139                	addi	sp,sp,-64
    800018de:	fc06                	sd	ra,56(sp)
    800018e0:	f822                	sd	s0,48(sp)
    800018e2:	f426                	sd	s1,40(sp)
    800018e4:	f04a                	sd	s2,32(sp)
    800018e6:	ec4e                	sd	s3,24(sp)
    800018e8:	e852                	sd	s4,16(sp)
    800018ea:	e456                	sd	s5,8(sp)
    800018ec:	e05a                	sd	s6,0(sp)
    800018ee:	0080                	addi	s0,sp,64
    struct proc *p;

    start_time = ticks; //initialize the starting time of the system.
    800018f0:	00007797          	auipc	a5,0x7
    800018f4:	7607a783          	lw	a5,1888(a5) # 80009050 <ticks>
    800018f8:	00007717          	auipc	a4,0x7
    800018fc:	72f72823          	sw	a5,1840(a4) # 80009028 <start_time>

    initlock(&pid_lock, "nextpid");
    80001900:	00007597          	auipc	a1,0x7
    80001904:	8e058593          	addi	a1,a1,-1824 # 800081e0 <digits+0x1a0>
    80001908:	00010517          	auipc	a0,0x10
    8000190c:	9b850513          	addi	a0,a0,-1608 # 800112c0 <pid_lock>
    80001910:	fffff097          	auipc	ra,0xfffff
    80001914:	244080e7          	jalr	580(ra) # 80000b54 <initlock>
    initlock(&wait_lock, "wait_lock");
    80001918:	00007597          	auipc	a1,0x7
    8000191c:	8d058593          	addi	a1,a1,-1840 # 800081e8 <digits+0x1a8>
    80001920:	00010517          	auipc	a0,0x10
    80001924:	9b850513          	addi	a0,a0,-1608 # 800112d8 <wait_lock>
    80001928:	fffff097          	auipc	ra,0xfffff
    8000192c:	22c080e7          	jalr	556(ra) # 80000b54 <initlock>
    for (p = proc; p < &proc[NPROC]; p++) {
    80001930:	00010497          	auipc	s1,0x10
    80001934:	dc048493          	addi	s1,s1,-576 # 800116f0 <proc>
        initlock(&p->lock, "proc");
    80001938:	00007b17          	auipc	s6,0x7
    8000193c:	8c0b0b13          	addi	s6,s6,-1856 # 800081f8 <digits+0x1b8>
        p->kstack = KSTACK((int) (p - proc));
    80001940:	8aa6                	mv	s5,s1
    80001942:	00006a17          	auipc	s4,0x6
    80001946:	6bea0a13          	addi	s4,s4,1726 # 80008000 <etext>
    8000194a:	04000937          	lui	s2,0x4000
    8000194e:	197d                	addi	s2,s2,-1
    80001950:	0932                	slli	s2,s2,0xc
    for (p = proc; p < &proc[NPROC]; p++) {
    80001952:	00016997          	auipc	s3,0x16
    80001956:	f9e98993          	addi	s3,s3,-98 # 800178f0 <tickslock>
        initlock(&p->lock, "proc");
    8000195a:	85da                	mv	a1,s6
    8000195c:	8526                	mv	a0,s1
    8000195e:	fffff097          	auipc	ra,0xfffff
    80001962:	1f6080e7          	jalr	502(ra) # 80000b54 <initlock>
        p->kstack = KSTACK((int) (p - proc));
    80001966:	415487b3          	sub	a5,s1,s5
    8000196a:	878d                	srai	a5,a5,0x3
    8000196c:	000a3703          	ld	a4,0(s4)
    80001970:	02e787b3          	mul	a5,a5,a4
    80001974:	2785                	addiw	a5,a5,1
    80001976:	00d7979b          	slliw	a5,a5,0xd
    8000197a:	40f907b3          	sub	a5,s2,a5
    8000197e:	f0bc                	sd	a5,96(s1)
    for (p = proc; p < &proc[NPROC]; p++) {
    80001980:	18848493          	addi	s1,s1,392
    80001984:	fd349be3          	bne	s1,s3,8000195a <procinit+0x7e>
    }
}
    80001988:	70e2                	ld	ra,56(sp)
    8000198a:	7442                	ld	s0,48(sp)
    8000198c:	74a2                	ld	s1,40(sp)
    8000198e:	7902                	ld	s2,32(sp)
    80001990:	69e2                	ld	s3,24(sp)
    80001992:	6a42                	ld	s4,16(sp)
    80001994:	6aa2                	ld	s5,8(sp)
    80001996:	6b02                	ld	s6,0(sp)
    80001998:	6121                	addi	sp,sp,64
    8000199a:	8082                	ret

000000008000199c <cpuid>:

// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid() {
    8000199c:	1141                	addi	sp,sp,-16
    8000199e:	e422                	sd	s0,8(sp)
    800019a0:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    800019a2:	8512                	mv	a0,tp
    int id = r_tp();
    return id;
}
    800019a4:	2501                	sext.w	a0,a0
    800019a6:	6422                	ld	s0,8(sp)
    800019a8:	0141                	addi	sp,sp,16
    800019aa:	8082                	ret

00000000800019ac <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu *
mycpu(void) {
    800019ac:	1141                	addi	sp,sp,-16
    800019ae:	e422                	sd	s0,8(sp)
    800019b0:	0800                	addi	s0,sp,16
    800019b2:	8792                	mv	a5,tp
    int id = cpuid();
    struct cpu *c = &cpus[id];
    800019b4:	2781                	sext.w	a5,a5
    800019b6:	079e                	slli	a5,a5,0x7
    return c;
}
    800019b8:	00010517          	auipc	a0,0x10
    800019bc:	93850513          	addi	a0,a0,-1736 # 800112f0 <cpus>
    800019c0:	953e                	add	a0,a0,a5
    800019c2:	6422                	ld	s0,8(sp)
    800019c4:	0141                	addi	sp,sp,16
    800019c6:	8082                	ret

00000000800019c8 <myproc>:

// Return the current struct proc *, or zero if none.
struct proc *
myproc(void) {
    800019c8:	1101                	addi	sp,sp,-32
    800019ca:	ec06                	sd	ra,24(sp)
    800019cc:	e822                	sd	s0,16(sp)
    800019ce:	e426                	sd	s1,8(sp)
    800019d0:	1000                	addi	s0,sp,32
    push_off();
    800019d2:	fffff097          	auipc	ra,0xfffff
    800019d6:	1c6080e7          	jalr	454(ra) # 80000b98 <push_off>
    800019da:	8792                	mv	a5,tp
    struct cpu *c = mycpu();
    struct proc *p = c->proc;
    800019dc:	2781                	sext.w	a5,a5
    800019de:	079e                	slli	a5,a5,0x7
    800019e0:	00010717          	auipc	a4,0x10
    800019e4:	8e070713          	addi	a4,a4,-1824 # 800112c0 <pid_lock>
    800019e8:	97ba                	add	a5,a5,a4
    800019ea:	7b84                	ld	s1,48(a5)
    pop_off();
    800019ec:	fffff097          	auipc	ra,0xfffff
    800019f0:	24c080e7          	jalr	588(ra) # 80000c38 <pop_off>
    return p;
}
    800019f4:	8526                	mv	a0,s1
    800019f6:	60e2                	ld	ra,24(sp)
    800019f8:	6442                	ld	s0,16(sp)
    800019fa:	64a2                	ld	s1,8(sp)
    800019fc:	6105                	addi	sp,sp,32
    800019fe:	8082                	ret

0000000080001a00 <forkret>:
}

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void) {
    80001a00:	1141                	addi	sp,sp,-16
    80001a02:	e406                	sd	ra,8(sp)
    80001a04:	e022                	sd	s0,0(sp)
    80001a06:	0800                	addi	s0,sp,16
    static int first = 1;

    // Still holding p->lock from scheduler.
    release(&myproc()->lock);
    80001a08:	00000097          	auipc	ra,0x0
    80001a0c:	fc0080e7          	jalr	-64(ra) # 800019c8 <myproc>
    80001a10:	fffff097          	auipc	ra,0xfffff
    80001a14:	288080e7          	jalr	648(ra) # 80000c98 <release>

    if (first) {
    80001a18:	00007797          	auipc	a5,0x7
    80001a1c:	ec87a783          	lw	a5,-312(a5) # 800088e0 <first.1717>
    80001a20:	eb89                	bnez	a5,80001a32 <forkret+0x32>
        // be run from main().
        first = 0;
        fsinit(ROOTDEV);
    }

    usertrapret();
    80001a22:	00001097          	auipc	ra,0x1
    80001a26:	10c080e7          	jalr	268(ra) # 80002b2e <usertrapret>
}
    80001a2a:	60a2                	ld	ra,8(sp)
    80001a2c:	6402                	ld	s0,0(sp)
    80001a2e:	0141                	addi	sp,sp,16
    80001a30:	8082                	ret
        first = 0;
    80001a32:	00007797          	auipc	a5,0x7
    80001a36:	ea07a723          	sw	zero,-338(a5) # 800088e0 <first.1717>
        fsinit(ROOTDEV);
    80001a3a:	4505                	li	a0,1
    80001a3c:	00002097          	auipc	ra,0x2
    80001a40:	e9c080e7          	jalr	-356(ra) # 800038d8 <fsinit>
    80001a44:	bff9                	j	80001a22 <forkret+0x22>

0000000080001a46 <allocpid>:
allocpid() {
    80001a46:	1101                	addi	sp,sp,-32
    80001a48:	ec06                	sd	ra,24(sp)
    80001a4a:	e822                	sd	s0,16(sp)
    80001a4c:	e426                	sd	s1,8(sp)
    80001a4e:	e04a                	sd	s2,0(sp)
    80001a50:	1000                	addi	s0,sp,32
    acquire(&pid_lock);
    80001a52:	00010917          	auipc	s2,0x10
    80001a56:	86e90913          	addi	s2,s2,-1938 # 800112c0 <pid_lock>
    80001a5a:	854a                	mv	a0,s2
    80001a5c:	fffff097          	auipc	ra,0xfffff
    80001a60:	188080e7          	jalr	392(ra) # 80000be4 <acquire>
    pid = nextpid;
    80001a64:	00007797          	auipc	a5,0x7
    80001a68:	e8078793          	addi	a5,a5,-384 # 800088e4 <nextpid>
    80001a6c:	4384                	lw	s1,0(a5)
    nextpid = nextpid + 1;
    80001a6e:	0014871b          	addiw	a4,s1,1
    80001a72:	c398                	sw	a4,0(a5)
    release(&pid_lock);
    80001a74:	854a                	mv	a0,s2
    80001a76:	fffff097          	auipc	ra,0xfffff
    80001a7a:	222080e7          	jalr	546(ra) # 80000c98 <release>
}
    80001a7e:	8526                	mv	a0,s1
    80001a80:	60e2                	ld	ra,24(sp)
    80001a82:	6442                	ld	s0,16(sp)
    80001a84:	64a2                	ld	s1,8(sp)
    80001a86:	6902                	ld	s2,0(sp)
    80001a88:	6105                	addi	sp,sp,32
    80001a8a:	8082                	ret

0000000080001a8c <proc_pagetable>:
proc_pagetable(struct proc *p) {
    80001a8c:	1101                	addi	sp,sp,-32
    80001a8e:	ec06                	sd	ra,24(sp)
    80001a90:	e822                	sd	s0,16(sp)
    80001a92:	e426                	sd	s1,8(sp)
    80001a94:	e04a                	sd	s2,0(sp)
    80001a96:	1000                	addi	s0,sp,32
    80001a98:	892a                	mv	s2,a0
    pagetable = uvmcreate();
    80001a9a:	00000097          	auipc	ra,0x0
    80001a9e:	8a8080e7          	jalr	-1880(ra) # 80001342 <uvmcreate>
    80001aa2:	84aa                	mv	s1,a0
    if (pagetable == 0)
    80001aa4:	c121                	beqz	a0,80001ae4 <proc_pagetable+0x58>
    if (mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001aa6:	4729                	li	a4,10
    80001aa8:	00005697          	auipc	a3,0x5
    80001aac:	55868693          	addi	a3,a3,1368 # 80007000 <_trampoline>
    80001ab0:	6605                	lui	a2,0x1
    80001ab2:	040005b7          	lui	a1,0x4000
    80001ab6:	15fd                	addi	a1,a1,-1
    80001ab8:	05b2                	slli	a1,a1,0xc
    80001aba:	fffff097          	auipc	ra,0xfffff
    80001abe:	5fe080e7          	jalr	1534(ra) # 800010b8 <mappages>
    80001ac2:	02054863          	bltz	a0,80001af2 <proc_pagetable+0x66>
    if (mappages(pagetable, TRAPFRAME, PGSIZE,
    80001ac6:	4719                	li	a4,6
    80001ac8:	07893683          	ld	a3,120(s2)
    80001acc:	6605                	lui	a2,0x1
    80001ace:	020005b7          	lui	a1,0x2000
    80001ad2:	15fd                	addi	a1,a1,-1
    80001ad4:	05b6                	slli	a1,a1,0xd
    80001ad6:	8526                	mv	a0,s1
    80001ad8:	fffff097          	auipc	ra,0xfffff
    80001adc:	5e0080e7          	jalr	1504(ra) # 800010b8 <mappages>
    80001ae0:	02054163          	bltz	a0,80001b02 <proc_pagetable+0x76>
}
    80001ae4:	8526                	mv	a0,s1
    80001ae6:	60e2                	ld	ra,24(sp)
    80001ae8:	6442                	ld	s0,16(sp)
    80001aea:	64a2                	ld	s1,8(sp)
    80001aec:	6902                	ld	s2,0(sp)
    80001aee:	6105                	addi	sp,sp,32
    80001af0:	8082                	ret
        uvmfree(pagetable, 0);
    80001af2:	4581                	li	a1,0
    80001af4:	8526                	mv	a0,s1
    80001af6:	00000097          	auipc	ra,0x0
    80001afa:	a48080e7          	jalr	-1464(ra) # 8000153e <uvmfree>
        return 0;
    80001afe:	4481                	li	s1,0
    80001b00:	b7d5                	j	80001ae4 <proc_pagetable+0x58>
        uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b02:	4681                	li	a3,0
    80001b04:	4605                	li	a2,1
    80001b06:	040005b7          	lui	a1,0x4000
    80001b0a:	15fd                	addi	a1,a1,-1
    80001b0c:	05b2                	slli	a1,a1,0xc
    80001b0e:	8526                	mv	a0,s1
    80001b10:	fffff097          	auipc	ra,0xfffff
    80001b14:	76e080e7          	jalr	1902(ra) # 8000127e <uvmunmap>
        uvmfree(pagetable, 0);
    80001b18:	4581                	li	a1,0
    80001b1a:	8526                	mv	a0,s1
    80001b1c:	00000097          	auipc	ra,0x0
    80001b20:	a22080e7          	jalr	-1502(ra) # 8000153e <uvmfree>
        return 0;
    80001b24:	4481                	li	s1,0
    80001b26:	bf7d                	j	80001ae4 <proc_pagetable+0x58>

0000000080001b28 <proc_freepagetable>:
proc_freepagetable(pagetable_t pagetable, uint64 sz) {
    80001b28:	1101                	addi	sp,sp,-32
    80001b2a:	ec06                	sd	ra,24(sp)
    80001b2c:	e822                	sd	s0,16(sp)
    80001b2e:	e426                	sd	s1,8(sp)
    80001b30:	e04a                	sd	s2,0(sp)
    80001b32:	1000                	addi	s0,sp,32
    80001b34:	84aa                	mv	s1,a0
    80001b36:	892e                	mv	s2,a1
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b38:	4681                	li	a3,0
    80001b3a:	4605                	li	a2,1
    80001b3c:	040005b7          	lui	a1,0x4000
    80001b40:	15fd                	addi	a1,a1,-1
    80001b42:	05b2                	slli	a1,a1,0xc
    80001b44:	fffff097          	auipc	ra,0xfffff
    80001b48:	73a080e7          	jalr	1850(ra) # 8000127e <uvmunmap>
    uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001b4c:	4681                	li	a3,0
    80001b4e:	4605                	li	a2,1
    80001b50:	020005b7          	lui	a1,0x2000
    80001b54:	15fd                	addi	a1,a1,-1
    80001b56:	05b6                	slli	a1,a1,0xd
    80001b58:	8526                	mv	a0,s1
    80001b5a:	fffff097          	auipc	ra,0xfffff
    80001b5e:	724080e7          	jalr	1828(ra) # 8000127e <uvmunmap>
    uvmfree(pagetable, sz);
    80001b62:	85ca                	mv	a1,s2
    80001b64:	8526                	mv	a0,s1
    80001b66:	00000097          	auipc	ra,0x0
    80001b6a:	9d8080e7          	jalr	-1576(ra) # 8000153e <uvmfree>
}
    80001b6e:	60e2                	ld	ra,24(sp)
    80001b70:	6442                	ld	s0,16(sp)
    80001b72:	64a2                	ld	s1,8(sp)
    80001b74:	6902                	ld	s2,0(sp)
    80001b76:	6105                	addi	sp,sp,32
    80001b78:	8082                	ret

0000000080001b7a <freeproc>:
freeproc(struct proc *p) {
    80001b7a:	1101                	addi	sp,sp,-32
    80001b7c:	ec06                	sd	ra,24(sp)
    80001b7e:	e822                	sd	s0,16(sp)
    80001b80:	e426                	sd	s1,8(sp)
    80001b82:	1000                	addi	s0,sp,32
    80001b84:	84aa                	mv	s1,a0
    if (p->trapframe)
    80001b86:	7d28                	ld	a0,120(a0)
    80001b88:	c509                	beqz	a0,80001b92 <freeproc+0x18>
        kfree((void *) p->trapframe);
    80001b8a:	fffff097          	auipc	ra,0xfffff
    80001b8e:	e6e080e7          	jalr	-402(ra) # 800009f8 <kfree>
    p->trapframe = 0;
    80001b92:	0604bc23          	sd	zero,120(s1)
    if (p->pagetable)
    80001b96:	78a8                	ld	a0,112(s1)
    80001b98:	c511                	beqz	a0,80001ba4 <freeproc+0x2a>
        proc_freepagetable(p->pagetable, p->sz);
    80001b9a:	74ac                	ld	a1,104(s1)
    80001b9c:	00000097          	auipc	ra,0x0
    80001ba0:	f8c080e7          	jalr	-116(ra) # 80001b28 <proc_freepagetable>
    p->pagetable = 0;
    80001ba4:	0604b823          	sd	zero,112(s1)
    p->sz = 0;
    80001ba8:	0604b423          	sd	zero,104(s1)
    p->pid = 0;
    80001bac:	0204a823          	sw	zero,48(s1)
    p->parent = 0;
    80001bb0:	0204bc23          	sd	zero,56(s1)
    p->name[0] = 0;
    80001bb4:	16048c23          	sb	zero,376(s1)
    p->chan = 0;
    80001bb8:	0204b023          	sd	zero,32(s1)
    p->killed = 0;
    80001bbc:	0204a423          	sw	zero,40(s1)
    p->xstate = 0;
    80001bc0:	0204a623          	sw	zero,44(s1)
    p->state = UNUSED;
    80001bc4:	0004ac23          	sw	zero,24(s1)
}
    80001bc8:	60e2                	ld	ra,24(sp)
    80001bca:	6442                	ld	s0,16(sp)
    80001bcc:	64a2                	ld	s1,8(sp)
    80001bce:	6105                	addi	sp,sp,32
    80001bd0:	8082                	ret

0000000080001bd2 <allocproc>:
allocproc(void) {
    80001bd2:	1101                	addi	sp,sp,-32
    80001bd4:	ec06                	sd	ra,24(sp)
    80001bd6:	e822                	sd	s0,16(sp)
    80001bd8:	e426                	sd	s1,8(sp)
    80001bda:	e04a                	sd	s2,0(sp)
    80001bdc:	1000                	addi	s0,sp,32
    for (p = proc; p < &proc[NPROC]; p++) {
    80001bde:	00010497          	auipc	s1,0x10
    80001be2:	b1248493          	addi	s1,s1,-1262 # 800116f0 <proc>
    80001be6:	00016917          	auipc	s2,0x16
    80001bea:	d0a90913          	addi	s2,s2,-758 # 800178f0 <tickslock>
        acquire(&p->lock);
    80001bee:	8526                	mv	a0,s1
    80001bf0:	fffff097          	auipc	ra,0xfffff
    80001bf4:	ff4080e7          	jalr	-12(ra) # 80000be4 <acquire>
        if (p->state == UNUSED) {
    80001bf8:	4c9c                	lw	a5,24(s1)
    80001bfa:	cf81                	beqz	a5,80001c12 <allocproc+0x40>
            release(&p->lock);
    80001bfc:	8526                	mv	a0,s1
    80001bfe:	fffff097          	auipc	ra,0xfffff
    80001c02:	09a080e7          	jalr	154(ra) # 80000c98 <release>
    for (p = proc; p < &proc[NPROC]; p++) {
    80001c06:	18848493          	addi	s1,s1,392
    80001c0a:	ff2492e3          	bne	s1,s2,80001bee <allocproc+0x1c>
    return 0;
    80001c0e:	4481                	li	s1,0
    80001c10:	a895                	j	80001c84 <allocproc+0xb2>
    p->pid = allocpid();
    80001c12:	00000097          	auipc	ra,0x0
    80001c16:	e34080e7          	jalr	-460(ra) # 80001a46 <allocpid>
    80001c1a:	d888                	sw	a0,48(s1)
    p->state = USED;
    80001c1c:	4785                	li	a5,1
    80001c1e:	cc9c                	sw	a5,24(s1)
    if ((p->trapframe = (struct trapframe *) kalloc()) == 0) {
    80001c20:	fffff097          	auipc	ra,0xfffff
    80001c24:	ed4080e7          	jalr	-300(ra) # 80000af4 <kalloc>
    80001c28:	892a                	mv	s2,a0
    80001c2a:	fca8                	sd	a0,120(s1)
    80001c2c:	c13d                	beqz	a0,80001c92 <allocproc+0xc0>
    p->pagetable = proc_pagetable(p);
    80001c2e:	8526                	mv	a0,s1
    80001c30:	00000097          	auipc	ra,0x0
    80001c34:	e5c080e7          	jalr	-420(ra) # 80001a8c <proc_pagetable>
    80001c38:	892a                	mv	s2,a0
    80001c3a:	f8a8                	sd	a0,112(s1)
    if (p->pagetable == 0) {
    80001c3c:	c53d                	beqz	a0,80001caa <allocproc+0xd8>
    memset(&p->context, 0, sizeof(p->context));
    80001c3e:	07000613          	li	a2,112
    80001c42:	4581                	li	a1,0
    80001c44:	08048513          	addi	a0,s1,128
    80001c48:	fffff097          	auipc	ra,0xfffff
    80001c4c:	098080e7          	jalr	152(ra) # 80000ce0 <memset>
    p->context.ra = (uint64) forkret;
    80001c50:	00000797          	auipc	a5,0x0
    80001c54:	db078793          	addi	a5,a5,-592 # 80001a00 <forkret>
    80001c58:	e0dc                	sd	a5,128(s1)
    p->context.sp = p->kstack + PGSIZE;
    80001c5a:	70bc                	ld	a5,96(s1)
    80001c5c:	6705                	lui	a4,0x1
    80001c5e:	97ba                	add	a5,a5,a4
    80001c60:	e4dc                	sd	a5,136(s1)
    p->mean_ticks = 0;
    80001c62:	0404a023          	sw	zero,64(s1)
    p->last_ticks = 0;
    80001c66:	0404a223          	sw	zero,68(s1)
    p->last_runnable_time = 0;
    80001c6a:	0404a423          	sw	zero,72(s1)
    p->runnable_time = 0;
    80001c6e:	0404a823          	sw	zero,80(s1)
    p->running_time = 0;
    80001c72:	0404aa23          	sw	zero,84(s1)
    p->sleeping_time = 0;
    80001c76:	0404a623          	sw	zero,76(s1)
    p->last_time_changed = ticks;
    80001c7a:	00007797          	auipc	a5,0x7
    80001c7e:	3d67a783          	lw	a5,982(a5) # 80009050 <ticks>
    80001c82:	ccbc                	sw	a5,88(s1)
}
    80001c84:	8526                	mv	a0,s1
    80001c86:	60e2                	ld	ra,24(sp)
    80001c88:	6442                	ld	s0,16(sp)
    80001c8a:	64a2                	ld	s1,8(sp)
    80001c8c:	6902                	ld	s2,0(sp)
    80001c8e:	6105                	addi	sp,sp,32
    80001c90:	8082                	ret
        freeproc(p);
    80001c92:	8526                	mv	a0,s1
    80001c94:	00000097          	auipc	ra,0x0
    80001c98:	ee6080e7          	jalr	-282(ra) # 80001b7a <freeproc>
        release(&p->lock);
    80001c9c:	8526                	mv	a0,s1
    80001c9e:	fffff097          	auipc	ra,0xfffff
    80001ca2:	ffa080e7          	jalr	-6(ra) # 80000c98 <release>
        return 0;
    80001ca6:	84ca                	mv	s1,s2
    80001ca8:	bff1                	j	80001c84 <allocproc+0xb2>
        freeproc(p);
    80001caa:	8526                	mv	a0,s1
    80001cac:	00000097          	auipc	ra,0x0
    80001cb0:	ece080e7          	jalr	-306(ra) # 80001b7a <freeproc>
        release(&p->lock);
    80001cb4:	8526                	mv	a0,s1
    80001cb6:	fffff097          	auipc	ra,0xfffff
    80001cba:	fe2080e7          	jalr	-30(ra) # 80000c98 <release>
        return 0;
    80001cbe:	84ca                	mv	s1,s2
    80001cc0:	b7d1                	j	80001c84 <allocproc+0xb2>

0000000080001cc2 <userinit>:
userinit(void) {
    80001cc2:	1101                	addi	sp,sp,-32
    80001cc4:	ec06                	sd	ra,24(sp)
    80001cc6:	e822                	sd	s0,16(sp)
    80001cc8:	e426                	sd	s1,8(sp)
    80001cca:	1000                	addi	s0,sp,32
    p = allocproc();
    80001ccc:	00000097          	auipc	ra,0x0
    80001cd0:	f06080e7          	jalr	-250(ra) # 80001bd2 <allocproc>
    80001cd4:	84aa                	mv	s1,a0
    initproc = p;
    80001cd6:	00007797          	auipc	a5,0x7
    80001cda:	36a7b923          	sd	a0,882(a5) # 80009048 <initproc>
    uvminit(p->pagetable, initcode, sizeof(initcode));
    80001cde:	03400613          	li	a2,52
    80001ce2:	00007597          	auipc	a1,0x7
    80001ce6:	c0e58593          	addi	a1,a1,-1010 # 800088f0 <initcode>
    80001cea:	7928                	ld	a0,112(a0)
    80001cec:	fffff097          	auipc	ra,0xfffff
    80001cf0:	684080e7          	jalr	1668(ra) # 80001370 <uvminit>
    p->sz = PGSIZE;
    80001cf4:	6785                	lui	a5,0x1
    80001cf6:	f4bc                	sd	a5,104(s1)
    p->trapframe->epc = 0;      // user program counter
    80001cf8:	7cb8                	ld	a4,120(s1)
    80001cfa:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
    p->trapframe->sp = PGSIZE;  // user stack pointer
    80001cfe:	7cb8                	ld	a4,120(s1)
    80001d00:	fb1c                	sd	a5,48(a4)
    safestrcpy(p->name, "initcode", sizeof(p->name));
    80001d02:	4641                	li	a2,16
    80001d04:	00006597          	auipc	a1,0x6
    80001d08:	4fc58593          	addi	a1,a1,1276 # 80008200 <digits+0x1c0>
    80001d0c:	17848513          	addi	a0,s1,376
    80001d10:	fffff097          	auipc	ra,0xfffff
    80001d14:	122080e7          	jalr	290(ra) # 80000e32 <safestrcpy>
    p->cwd = namei("/");
    80001d18:	00006517          	auipc	a0,0x6
    80001d1c:	4f850513          	addi	a0,a0,1272 # 80008210 <digits+0x1d0>
    80001d20:	00002097          	auipc	ra,0x2
    80001d24:	5e6080e7          	jalr	1510(ra) # 80004306 <namei>
    80001d28:	16a4b823          	sd	a0,368(s1)
    p->state = RUNNABLE;
    80001d2c:	478d                	li	a5,3
    80001d2e:	cc9c                	sw	a5,24(s1)
    p->last_runnable_time = ticks;     //added last_runnable time for fcfs
    80001d30:	00007797          	auipc	a5,0x7
    80001d34:	3207a783          	lw	a5,800(a5) # 80009050 <ticks>
    80001d38:	c4bc                	sw	a5,72(s1)
    p->last_time_changed = ticks;      //setting the starting ticks when getting to runnable for section 4
    80001d3a:	ccbc                	sw	a5,88(s1)
    release(&p->lock);
    80001d3c:	8526                	mv	a0,s1
    80001d3e:	fffff097          	auipc	ra,0xfffff
    80001d42:	f5a080e7          	jalr	-166(ra) # 80000c98 <release>
}
    80001d46:	60e2                	ld	ra,24(sp)
    80001d48:	6442                	ld	s0,16(sp)
    80001d4a:	64a2                	ld	s1,8(sp)
    80001d4c:	6105                	addi	sp,sp,32
    80001d4e:	8082                	ret

0000000080001d50 <growproc>:
growproc(int n) {
    80001d50:	1101                	addi	sp,sp,-32
    80001d52:	ec06                	sd	ra,24(sp)
    80001d54:	e822                	sd	s0,16(sp)
    80001d56:	e426                	sd	s1,8(sp)
    80001d58:	e04a                	sd	s2,0(sp)
    80001d5a:	1000                	addi	s0,sp,32
    80001d5c:	84aa                	mv	s1,a0
    struct proc *p = myproc();
    80001d5e:	00000097          	auipc	ra,0x0
    80001d62:	c6a080e7          	jalr	-918(ra) # 800019c8 <myproc>
    80001d66:	892a                	mv	s2,a0
    sz = p->sz;
    80001d68:	752c                	ld	a1,104(a0)
    80001d6a:	0005861b          	sext.w	a2,a1
    if (n > 0) {
    80001d6e:	00904f63          	bgtz	s1,80001d8c <growproc+0x3c>
    } else if (n < 0) {
    80001d72:	0204cc63          	bltz	s1,80001daa <growproc+0x5a>
    p->sz = sz;
    80001d76:	1602                	slli	a2,a2,0x20
    80001d78:	9201                	srli	a2,a2,0x20
    80001d7a:	06c93423          	sd	a2,104(s2)
    return 0;
    80001d7e:	4501                	li	a0,0
}
    80001d80:	60e2                	ld	ra,24(sp)
    80001d82:	6442                	ld	s0,16(sp)
    80001d84:	64a2                	ld	s1,8(sp)
    80001d86:	6902                	ld	s2,0(sp)
    80001d88:	6105                	addi	sp,sp,32
    80001d8a:	8082                	ret
        if ((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    80001d8c:	9e25                	addw	a2,a2,s1
    80001d8e:	1602                	slli	a2,a2,0x20
    80001d90:	9201                	srli	a2,a2,0x20
    80001d92:	1582                	slli	a1,a1,0x20
    80001d94:	9181                	srli	a1,a1,0x20
    80001d96:	7928                	ld	a0,112(a0)
    80001d98:	fffff097          	auipc	ra,0xfffff
    80001d9c:	692080e7          	jalr	1682(ra) # 8000142a <uvmalloc>
    80001da0:	0005061b          	sext.w	a2,a0
    80001da4:	fa69                	bnez	a2,80001d76 <growproc+0x26>
            return -1;
    80001da6:	557d                	li	a0,-1
    80001da8:	bfe1                	j	80001d80 <growproc+0x30>
        sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001daa:	9e25                	addw	a2,a2,s1
    80001dac:	1602                	slli	a2,a2,0x20
    80001dae:	9201                	srli	a2,a2,0x20
    80001db0:	1582                	slli	a1,a1,0x20
    80001db2:	9181                	srli	a1,a1,0x20
    80001db4:	7928                	ld	a0,112(a0)
    80001db6:	fffff097          	auipc	ra,0xfffff
    80001dba:	62c080e7          	jalr	1580(ra) # 800013e2 <uvmdealloc>
    80001dbe:	0005061b          	sext.w	a2,a0
    80001dc2:	bf55                	j	80001d76 <growproc+0x26>

0000000080001dc4 <fork>:
fork(void) {
    80001dc4:	7179                	addi	sp,sp,-48
    80001dc6:	f406                	sd	ra,40(sp)
    80001dc8:	f022                	sd	s0,32(sp)
    80001dca:	ec26                	sd	s1,24(sp)
    80001dcc:	e84a                	sd	s2,16(sp)
    80001dce:	e44e                	sd	s3,8(sp)
    80001dd0:	e052                	sd	s4,0(sp)
    80001dd2:	1800                	addi	s0,sp,48
    struct proc *p = myproc();
    80001dd4:	00000097          	auipc	ra,0x0
    80001dd8:	bf4080e7          	jalr	-1036(ra) # 800019c8 <myproc>
    80001ddc:	89aa                	mv	s3,a0
    if ((np = allocproc()) == 0) {
    80001dde:	00000097          	auipc	ra,0x0
    80001de2:	df4080e7          	jalr	-524(ra) # 80001bd2 <allocproc>
    80001de6:	12050363          	beqz	a0,80001f0c <fork+0x148>
    80001dea:	892a                	mv	s2,a0
    if (uvmcopy(p->pagetable, np->pagetable, p->sz) < 0) {
    80001dec:	0689b603          	ld	a2,104(s3)
    80001df0:	792c                	ld	a1,112(a0)
    80001df2:	0709b503          	ld	a0,112(s3)
    80001df6:	fffff097          	auipc	ra,0xfffff
    80001dfa:	780080e7          	jalr	1920(ra) # 80001576 <uvmcopy>
    80001dfe:	04054663          	bltz	a0,80001e4a <fork+0x86>
    np->sz = p->sz;
    80001e02:	0689b783          	ld	a5,104(s3)
    80001e06:	06f93423          	sd	a5,104(s2)
    *(np->trapframe) = *(p->trapframe);
    80001e0a:	0789b683          	ld	a3,120(s3)
    80001e0e:	87b6                	mv	a5,a3
    80001e10:	07893703          	ld	a4,120(s2)
    80001e14:	12068693          	addi	a3,a3,288
    80001e18:	0007b803          	ld	a6,0(a5)
    80001e1c:	6788                	ld	a0,8(a5)
    80001e1e:	6b8c                	ld	a1,16(a5)
    80001e20:	6f90                	ld	a2,24(a5)
    80001e22:	01073023          	sd	a6,0(a4)
    80001e26:	e708                	sd	a0,8(a4)
    80001e28:	eb0c                	sd	a1,16(a4)
    80001e2a:	ef10                	sd	a2,24(a4)
    80001e2c:	02078793          	addi	a5,a5,32
    80001e30:	02070713          	addi	a4,a4,32
    80001e34:	fed792e3          	bne	a5,a3,80001e18 <fork+0x54>
    np->trapframe->a0 = 0;
    80001e38:	07893783          	ld	a5,120(s2)
    80001e3c:	0607b823          	sd	zero,112(a5)
    80001e40:	0f000493          	li	s1,240
    for (i = 0; i < NOFILE; i++)
    80001e44:	17000a13          	li	s4,368
    80001e48:	a03d                	j	80001e76 <fork+0xb2>
        freeproc(np);
    80001e4a:	854a                	mv	a0,s2
    80001e4c:	00000097          	auipc	ra,0x0
    80001e50:	d2e080e7          	jalr	-722(ra) # 80001b7a <freeproc>
        release(&np->lock);
    80001e54:	854a                	mv	a0,s2
    80001e56:	fffff097          	auipc	ra,0xfffff
    80001e5a:	e42080e7          	jalr	-446(ra) # 80000c98 <release>
        return -1;
    80001e5e:	5a7d                	li	s4,-1
    80001e60:	a869                	j	80001efa <fork+0x136>
            np->ofile[i] = filedup(p->ofile[i]);
    80001e62:	00003097          	auipc	ra,0x3
    80001e66:	b3a080e7          	jalr	-1222(ra) # 8000499c <filedup>
    80001e6a:	009907b3          	add	a5,s2,s1
    80001e6e:	e388                	sd	a0,0(a5)
    for (i = 0; i < NOFILE; i++)
    80001e70:	04a1                	addi	s1,s1,8
    80001e72:	01448763          	beq	s1,s4,80001e80 <fork+0xbc>
        if (p->ofile[i])
    80001e76:	009987b3          	add	a5,s3,s1
    80001e7a:	6388                	ld	a0,0(a5)
    80001e7c:	f17d                	bnez	a0,80001e62 <fork+0x9e>
    80001e7e:	bfcd                	j	80001e70 <fork+0xac>
    np->cwd = idup(p->cwd);
    80001e80:	1709b503          	ld	a0,368(s3)
    80001e84:	00002097          	auipc	ra,0x2
    80001e88:	c8e080e7          	jalr	-882(ra) # 80003b12 <idup>
    80001e8c:	16a93823          	sd	a0,368(s2)
    safestrcpy(np->name, p->name, sizeof(p->name));
    80001e90:	4641                	li	a2,16
    80001e92:	17898593          	addi	a1,s3,376
    80001e96:	17890513          	addi	a0,s2,376
    80001e9a:	fffff097          	auipc	ra,0xfffff
    80001e9e:	f98080e7          	jalr	-104(ra) # 80000e32 <safestrcpy>
    pid = np->pid;
    80001ea2:	03092a03          	lw	s4,48(s2)
    release(&np->lock);
    80001ea6:	854a                	mv	a0,s2
    80001ea8:	fffff097          	auipc	ra,0xfffff
    80001eac:	df0080e7          	jalr	-528(ra) # 80000c98 <release>
    acquire(&wait_lock);
    80001eb0:	0000f497          	auipc	s1,0xf
    80001eb4:	42848493          	addi	s1,s1,1064 # 800112d8 <wait_lock>
    80001eb8:	8526                	mv	a0,s1
    80001eba:	fffff097          	auipc	ra,0xfffff
    80001ebe:	d2a080e7          	jalr	-726(ra) # 80000be4 <acquire>
    np->parent = p;
    80001ec2:	03393c23          	sd	s3,56(s2)
    release(&wait_lock);
    80001ec6:	8526                	mv	a0,s1
    80001ec8:	fffff097          	auipc	ra,0xfffff
    80001ecc:	dd0080e7          	jalr	-560(ra) # 80000c98 <release>
    acquire(&np->lock);
    80001ed0:	854a                	mv	a0,s2
    80001ed2:	fffff097          	auipc	ra,0xfffff
    80001ed6:	d12080e7          	jalr	-750(ra) # 80000be4 <acquire>
    np->state = RUNNABLE;
    80001eda:	478d                	li	a5,3
    80001edc:	00f92c23          	sw	a5,24(s2)
    np->last_runnable_time = ticks;     //added last_runnable time for fcfs
    80001ee0:	00007797          	auipc	a5,0x7
    80001ee4:	1707a783          	lw	a5,368(a5) # 80009050 <ticks>
    80001ee8:	04f92423          	sw	a5,72(s2)
    np->last_time_changed = ticks;      //setting the starting ticks when getting to runnable for section 4
    80001eec:	04f92c23          	sw	a5,88(s2)
    release(&np->lock);
    80001ef0:	854a                	mv	a0,s2
    80001ef2:	fffff097          	auipc	ra,0xfffff
    80001ef6:	da6080e7          	jalr	-602(ra) # 80000c98 <release>
}
    80001efa:	8552                	mv	a0,s4
    80001efc:	70a2                	ld	ra,40(sp)
    80001efe:	7402                	ld	s0,32(sp)
    80001f00:	64e2                	ld	s1,24(sp)
    80001f02:	6942                	ld	s2,16(sp)
    80001f04:	69a2                	ld	s3,8(sp)
    80001f06:	6a02                	ld	s4,0(sp)
    80001f08:	6145                	addi	sp,sp,48
    80001f0a:	8082                	ret
        return -1;
    80001f0c:	5a7d                	li	s4,-1
    80001f0e:	b7f5                	j	80001efa <fork+0x136>

0000000080001f10 <defScheduler>:
void defScheduler(void) {
    80001f10:	711d                	addi	sp,sp,-96
    80001f12:	ec86                	sd	ra,88(sp)
    80001f14:	e8a2                	sd	s0,80(sp)
    80001f16:	e4a6                	sd	s1,72(sp)
    80001f18:	e0ca                	sd	s2,64(sp)
    80001f1a:	fc4e                	sd	s3,56(sp)
    80001f1c:	f852                	sd	s4,48(sp)
    80001f1e:	f456                	sd	s5,40(sp)
    80001f20:	f05a                	sd	s6,32(sp)
    80001f22:	ec5e                	sd	s7,24(sp)
    80001f24:	e862                	sd	s8,16(sp)
    80001f26:	e466                	sd	s9,8(sp)
    80001f28:	1080                	addi	s0,sp,96
    80001f2a:	8492                	mv	s1,tp
    int id = r_tp();
    80001f2c:	2481                	sext.w	s1,s1
    printf("pauseTicks: %d\n", pauseTicks);
    80001f2e:	00007597          	auipc	a1,0x7
    80001f32:	1125a583          	lw	a1,274(a1) # 80009040 <pauseTicks>
    80001f36:	00006517          	auipc	a0,0x6
    80001f3a:	2e250513          	addi	a0,a0,738 # 80008218 <digits+0x1d8>
    80001f3e:	ffffe097          	auipc	ra,0xffffe
    80001f42:	64a080e7          	jalr	1610(ra) # 80000588 <printf>
    c->proc = 0;
    80001f46:	00749c93          	slli	s9,s1,0x7
    80001f4a:	0000f797          	auipc	a5,0xf
    80001f4e:	37678793          	addi	a5,a5,886 # 800112c0 <pid_lock>
    80001f52:	97e6                	add	a5,a5,s9
    80001f54:	0207b823          	sd	zero,48(a5)
                swtch(&c->context, &p->context);
    80001f58:	0000f797          	auipc	a5,0xf
    80001f5c:	3a078793          	addi	a5,a5,928 # 800112f8 <cpus+0x8>
    80001f60:	9cbe                	add	s9,s9,a5
            if (p->state == RUNNABLE && ticks >= pauseTicks) {
    80001f62:	00007b17          	auipc	s6,0x7
    80001f66:	0eeb0b13          	addi	s6,s6,238 # 80009050 <ticks>
    80001f6a:	00007a97          	auipc	s5,0x7
    80001f6e:	0d6a8a93          	addi	s5,s5,214 # 80009040 <pauseTicks>
                c->proc = p;
    80001f72:	049e                	slli	s1,s1,0x7
    80001f74:	0000fb97          	auipc	s7,0xf
    80001f78:	34cb8b93          	addi	s7,s7,844 # 800112c0 <pid_lock>
    80001f7c:	9ba6                	add	s7,s7,s1
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001f7e:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001f82:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001f86:	10079073          	csrw	sstatus,a5
        for (p = proc; p < &proc[NPROC]; p++) {
    80001f8a:	0000f497          	auipc	s1,0xf
    80001f8e:	76648493          	addi	s1,s1,1894 # 800116f0 <proc>
            if (p->state == RUNNABLE && ticks >= pauseTicks) {
    80001f92:	4a0d                	li	s4,3
                p->state = RUNNING;
    80001f94:	4c11                	li	s8,4
        for (p = proc; p < &proc[NPROC]; p++) {
    80001f96:	00016997          	auipc	s3,0x16
    80001f9a:	95a98993          	addi	s3,s3,-1702 # 800178f0 <tickslock>
    80001f9e:	a82d                	j	80001fd8 <defScheduler+0xc8>
                p->runnable_time = p->runnable_time + ticks - p->last_time_changed;
    80001fa0:	48b8                	lw	a4,80(s1)
    80001fa2:	9f3d                	addw	a4,a4,a5
    80001fa4:	4cb4                	lw	a3,88(s1)
    80001fa6:	9f15                	subw	a4,a4,a3
    80001fa8:	c8b8                	sw	a4,80(s1)
                p->last_time_changed = ticks;      //setting the starting ticks when getting to runnable for section 4
    80001faa:	ccbc                	sw	a5,88(s1)
                p->state = RUNNING;
    80001fac:	0184ac23          	sw	s8,24(s1)
                c->proc = p;
    80001fb0:	029bb823          	sd	s1,48(s7)
                swtch(&c->context, &p->context);
    80001fb4:	08048593          	addi	a1,s1,128
    80001fb8:	8566                	mv	a0,s9
    80001fba:	00001097          	auipc	ra,0x1
    80001fbe:	aca080e7          	jalr	-1334(ra) # 80002a84 <swtch>
                c->proc = 0;
    80001fc2:	020bb823          	sd	zero,48(s7)
            release(&p->lock);
    80001fc6:	8526                	mv	a0,s1
    80001fc8:	fffff097          	auipc	ra,0xfffff
    80001fcc:	cd0080e7          	jalr	-816(ra) # 80000c98 <release>
        for (p = proc; p < &proc[NPROC]; p++) {
    80001fd0:	18848493          	addi	s1,s1,392
    80001fd4:	fb3485e3          	beq	s1,s3,80001f7e <defScheduler+0x6e>
            acquire(&p->lock);
    80001fd8:	8526                	mv	a0,s1
    80001fda:	fffff097          	auipc	ra,0xfffff
    80001fde:	c0a080e7          	jalr	-1014(ra) # 80000be4 <acquire>
            if (p->state == RUNNABLE && ticks >= pauseTicks) {
    80001fe2:	4c9c                	lw	a5,24(s1)
    80001fe4:	ff4791e3          	bne	a5,s4,80001fc6 <defScheduler+0xb6>
    80001fe8:	000b2783          	lw	a5,0(s6)
    80001fec:	000aa703          	lw	a4,0(s5)
    80001ff0:	fce7ebe3          	bltu	a5,a4,80001fc6 <defScheduler+0xb6>
    80001ff4:	b775                	j	80001fa0 <defScheduler+0x90>

0000000080001ff6 <sjfScheduler>:
void sjfScheduler(void) { //todo where do we calculate the mean and where to init with 0
    80001ff6:	711d                	addi	sp,sp,-96
    80001ff8:	ec86                	sd	ra,88(sp)
    80001ffa:	e8a2                	sd	s0,80(sp)
    80001ffc:	e4a6                	sd	s1,72(sp)
    80001ffe:	e0ca                	sd	s2,64(sp)
    80002000:	fc4e                	sd	s3,56(sp)
    80002002:	f852                	sd	s4,48(sp)
    80002004:	f456                	sd	s5,40(sp)
    80002006:	f05a                	sd	s6,32(sp)
    80002008:	ec5e                	sd	s7,24(sp)
    8000200a:	e862                	sd	s8,16(sp)
    8000200c:	e466                	sd	s9,8(sp)
    8000200e:	e06a                	sd	s10,0(sp)
    80002010:	1080                	addi	s0,sp,96
  asm volatile("mv %0, tp" : "=r" (x) );
    80002012:	8792                	mv	a5,tp
    int id = r_tp();
    80002014:	2781                	sext.w	a5,a5
    c->proc = 0;
    80002016:	00779c93          	slli	s9,a5,0x7
    8000201a:	0000f717          	auipc	a4,0xf
    8000201e:	2a670713          	addi	a4,a4,678 # 800112c0 <pid_lock>
    80002022:	9766                	add	a4,a4,s9
    80002024:	02073823          	sd	zero,48(a4)
            swtch(&c->context, &min_proc->context);
    80002028:	0000f717          	auipc	a4,0xf
    8000202c:	2d070713          	addi	a4,a4,720 # 800112f8 <cpus+0x8>
    80002030:	9cba                	add	s9,s9,a4
        struct proc *min_proc = proc;
    80002032:	0000fa97          	auipc	s5,0xf
    80002036:	6bea8a93          	addi	s5,s5,1726 # 800116f0 <proc>
            if (p->state == RUNNABLE && p->mean_ticks <= min_proc->mean_ticks)
    8000203a:	490d                	li	s2,3
        for (p = proc; p < &proc[NPROC]; p++) {
    8000203c:	00016997          	auipc	s3,0x16
    80002040:	8b498993          	addi	s3,s3,-1868 # 800178f0 <tickslock>
        if (min_proc->state == RUNNABLE && ticks >= pauseTicks) {
    80002044:	00007b17          	auipc	s6,0x7
    80002048:	00cb0b13          	addi	s6,s6,12 # 80009050 <ticks>
    8000204c:	00007c17          	auipc	s8,0x7
    80002050:	ff4c0c13          	addi	s8,s8,-12 # 80009040 <pauseTicks>
            c->proc = min_proc;
    80002054:	079e                	slli	a5,a5,0x7
    80002056:	0000fb97          	auipc	s7,0xf
    8000205a:	26ab8b93          	addi	s7,s7,618 # 800112c0 <pid_lock>
    8000205e:	9bbe                	add	s7,s7,a5
    80002060:	a0c1                	j	80002120 <sjfScheduler+0x12a>
            release(&p->lock);
    80002062:	8526                	mv	a0,s1
    80002064:	fffff097          	auipc	ra,0xfffff
    80002068:	c34080e7          	jalr	-972(ra) # 80000c98 <release>
        for (p = proc; p < &proc[NPROC]; p++) {
    8000206c:	18848493          	addi	s1,s1,392
    80002070:	03348163          	beq	s1,s3,80002092 <sjfScheduler+0x9c>
            acquire(&p->lock);
    80002074:	8526                	mv	a0,s1
    80002076:	fffff097          	auipc	ra,0xfffff
    8000207a:	b6e080e7          	jalr	-1170(ra) # 80000be4 <acquire>
            if (p->state == RUNNABLE && p->mean_ticks <= min_proc->mean_ticks)
    8000207e:	4c9c                	lw	a5,24(s1)
    80002080:	ff2791e3          	bne	a5,s2,80002062 <sjfScheduler+0x6c>
    80002084:	40b8                	lw	a4,64(s1)
    80002086:	040a2783          	lw	a5,64(s4)
    8000208a:	fce7cce3          	blt	a5,a4,80002062 <sjfScheduler+0x6c>
    8000208e:	8a26                	mv	s4,s1
    80002090:	bfc9                	j	80002062 <sjfScheduler+0x6c>
        acquire(&min_proc->lock);
    80002092:	84d2                	mv	s1,s4
    80002094:	8552                	mv	a0,s4
    80002096:	fffff097          	auipc	ra,0xfffff
    8000209a:	b4e080e7          	jalr	-1202(ra) # 80000be4 <acquire>
        if (min_proc->state == RUNNABLE && ticks >= pauseTicks) {
    8000209e:	018a2783          	lw	a5,24(s4)
    800020a2:	07279a63          	bne	a5,s2,80002116 <sjfScheduler+0x120>
    800020a6:	000b2d03          	lw	s10,0(s6)
    800020aa:	000c2783          	lw	a5,0(s8)
    800020ae:	06fd6463          	bltu	s10,a5,80002116 <sjfScheduler+0x120>
            min_proc->runnable_time = min_proc->runnable_time + ticks - min_proc->last_time_changed;
    800020b2:	050a2783          	lw	a5,80(s4)
    800020b6:	01a787bb          	addw	a5,a5,s10
    800020ba:	058a2703          	lw	a4,88(s4)
    800020be:	9f99                	subw	a5,a5,a4
    800020c0:	04fa2823          	sw	a5,80(s4)
            min_proc->last_time_changed = ticks;      //setting the starting ticks when getting to runnable for section 4
    800020c4:	05aa2c23          	sw	s10,88(s4)
            min_proc->state = RUNNING;
    800020c8:	4791                	li	a5,4
    800020ca:	00fa2c23          	sw	a5,24(s4)
            c->proc = min_proc;
    800020ce:	034bb823          	sd	s4,48(s7)
            swtch(&c->context, &min_proc->context);
    800020d2:	080a0593          	addi	a1,s4,128
    800020d6:	8566                	mv	a0,s9
    800020d8:	00001097          	auipc	ra,0x1
    800020dc:	9ac080e7          	jalr	-1620(ra) # 80002a84 <swtch>
            min_proc->last_ticks = ticks - startingTicks;
    800020e0:	000b2783          	lw	a5,0(s6)
    800020e4:	41a78d3b          	subw	s10,a5,s10
    800020e8:	05aa2223          	sw	s10,68(s4)
            min_proc->mean_ticks = ((10 - rate) * min_proc->mean_ticks + min_proc->last_ticks * (rate)) / 10;
    800020ec:	00006697          	auipc	a3,0x6
    800020f0:	7fc6a683          	lw	a3,2044(a3) # 800088e8 <rate>
    800020f4:	4729                	li	a4,10
    800020f6:	40d707bb          	subw	a5,a4,a3
    800020fa:	040a2603          	lw	a2,64(s4)
    800020fe:	02c787bb          	mulw	a5,a5,a2
    80002102:	02dd0d3b          	mulw	s10,s10,a3
    80002106:	01a787bb          	addw	a5,a5,s10
    8000210a:	02e7c7bb          	divw	a5,a5,a4
    8000210e:	04fa2023          	sw	a5,64(s4)
            c->proc = 0;
    80002112:	020bb823          	sd	zero,48(s7)
        release(&min_proc->lock);
    80002116:	8526                	mv	a0,s1
    80002118:	fffff097          	auipc	ra,0xfffff
    8000211c:	b80080e7          	jalr	-1152(ra) # 80000c98 <release>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002120:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002124:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002128:	10079073          	csrw	sstatus,a5
        struct proc *min_proc = proc;
    8000212c:	8a56                	mv	s4,s5
        for (p = proc; p < &proc[NPROC]; p++) {
    8000212e:	84d6                	mv	s1,s5
    80002130:	b791                	j	80002074 <sjfScheduler+0x7e>

0000000080002132 <fcfsScheduler>:
void fcfsScheduler(void) {
    80002132:	711d                	addi	sp,sp,-96
    80002134:	ec86                	sd	ra,88(sp)
    80002136:	e8a2                	sd	s0,80(sp)
    80002138:	e4a6                	sd	s1,72(sp)
    8000213a:	e0ca                	sd	s2,64(sp)
    8000213c:	fc4e                	sd	s3,56(sp)
    8000213e:	f852                	sd	s4,48(sp)
    80002140:	f456                	sd	s5,40(sp)
    80002142:	f05a                	sd	s6,32(sp)
    80002144:	ec5e                	sd	s7,24(sp)
    80002146:	e862                	sd	s8,16(sp)
    80002148:	e466                	sd	s9,8(sp)
    8000214a:	1080                	addi	s0,sp,96
  asm volatile("mv %0, tp" : "=r" (x) );
    8000214c:	8792                	mv	a5,tp
    int id = r_tp();
    8000214e:	2781                	sext.w	a5,a5
    c->proc = 0;
    80002150:	00779c93          	slli	s9,a5,0x7
    80002154:	0000f717          	auipc	a4,0xf
    80002158:	16c70713          	addi	a4,a4,364 # 800112c0 <pid_lock>
    8000215c:	9766                	add	a4,a4,s9
    8000215e:	02073823          	sd	zero,48(a4)
            swtch(&c->context, &min_lrt_proc->context);
    80002162:	0000f717          	auipc	a4,0xf
    80002166:	19670713          	addi	a4,a4,406 # 800112f8 <cpus+0x8>
    8000216a:	9cba                	add	s9,s9,a4
        struct proc *min_lrt_proc = proc; // lrt = last runnable time
    8000216c:	0000fa97          	auipc	s5,0xf
    80002170:	584a8a93          	addi	s5,s5,1412 # 800116f0 <proc>
            if (p->state == RUNNABLE && p->last_runnable_time <= min_lrt_proc->last_runnable_time)
    80002174:	498d                	li	s3,3
        for (p = proc; p < &proc[NPROC]; p++) {
    80002176:	00015917          	auipc	s2,0x15
    8000217a:	77a90913          	addi	s2,s2,1914 # 800178f0 <tickslock>
        if (ticks >= pauseTicks) {
    8000217e:	00007c17          	auipc	s8,0x7
    80002182:	ed2c0c13          	addi	s8,s8,-302 # 80009050 <ticks>
    80002186:	00007b97          	auipc	s7,0x7
    8000218a:	ebab8b93          	addi	s7,s7,-326 # 80009040 <pauseTicks>
            c->proc = min_lrt_proc;
    8000218e:	079e                	slli	a5,a5,0x7
    80002190:	0000fb17          	auipc	s6,0xf
    80002194:	130b0b13          	addi	s6,s6,304 # 800112c0 <pid_lock>
    80002198:	9b3e                	add	s6,s6,a5
    8000219a:	a051                	j	8000221e <fcfsScheduler+0xec>
            release(&p->lock);
    8000219c:	8526                	mv	a0,s1
    8000219e:	fffff097          	auipc	ra,0xfffff
    800021a2:	afa080e7          	jalr	-1286(ra) # 80000c98 <release>
        for (p = proc; p < &proc[NPROC]; p++) {
    800021a6:	18848493          	addi	s1,s1,392
    800021aa:	03248163          	beq	s1,s2,800021cc <fcfsScheduler+0x9a>
            acquire(&p->lock);
    800021ae:	8526                	mv	a0,s1
    800021b0:	fffff097          	auipc	ra,0xfffff
    800021b4:	a34080e7          	jalr	-1484(ra) # 80000be4 <acquire>
            if (p->state == RUNNABLE && p->last_runnable_time <= min_lrt_proc->last_runnable_time)
    800021b8:	4c9c                	lw	a5,24(s1)
    800021ba:	ff3791e3          	bne	a5,s3,8000219c <fcfsScheduler+0x6a>
    800021be:	44b8                	lw	a4,72(s1)
    800021c0:	048a2783          	lw	a5,72(s4)
    800021c4:	fce7cce3          	blt	a5,a4,8000219c <fcfsScheduler+0x6a>
    800021c8:	8a26                	mv	s4,s1
    800021ca:	bfc9                	j	8000219c <fcfsScheduler+0x6a>
        acquire(&min_lrt_proc->lock);
    800021cc:	84d2                	mv	s1,s4
    800021ce:	8552                	mv	a0,s4
    800021d0:	fffff097          	auipc	ra,0xfffff
    800021d4:	a14080e7          	jalr	-1516(ra) # 80000be4 <acquire>
        if (ticks >= pauseTicks) {
    800021d8:	000c2703          	lw	a4,0(s8)
    800021dc:	000ba783          	lw	a5,0(s7)
    800021e0:	02f76a63          	bltu	a4,a5,80002214 <fcfsScheduler+0xe2>
            min_lrt_proc->runnable_time = min_lrt_proc->runnable_time + ticks - min_lrt_proc->last_time_changed;
    800021e4:	050a2783          	lw	a5,80(s4)
    800021e8:	9fb9                	addw	a5,a5,a4
    800021ea:	058a2683          	lw	a3,88(s4)
    800021ee:	9f95                	subw	a5,a5,a3
    800021f0:	04fa2823          	sw	a5,80(s4)
            min_lrt_proc->last_time_changed = ticks;      //setting the starting ticks when getting to runnable for section 4
    800021f4:	04ea2c23          	sw	a4,88(s4)
            min_lrt_proc->state = RUNNING;
    800021f8:	4791                	li	a5,4
    800021fa:	00fa2c23          	sw	a5,24(s4)
            c->proc = min_lrt_proc;
    800021fe:	034b3823          	sd	s4,48(s6)
            swtch(&c->context, &min_lrt_proc->context);
    80002202:	080a0593          	addi	a1,s4,128
    80002206:	8566                	mv	a0,s9
    80002208:	00001097          	auipc	ra,0x1
    8000220c:	87c080e7          	jalr	-1924(ra) # 80002a84 <swtch>
            c->proc = 0;
    80002210:	020b3823          	sd	zero,48(s6)
        release(&min_lrt_proc->lock);
    80002214:	8526                	mv	a0,s1
    80002216:	fffff097          	auipc	ra,0xfffff
    8000221a:	a82080e7          	jalr	-1406(ra) # 80000c98 <release>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000221e:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002222:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002226:	10079073          	csrw	sstatus,a5
        struct proc *min_lrt_proc = proc; // lrt = last runnable time
    8000222a:	8a56                	mv	s4,s5
        for (p = proc; p < &proc[NPROC]; p++) {
    8000222c:	84d6                	mv	s1,s5
    8000222e:	b741                	j	800021ae <fcfsScheduler+0x7c>

0000000080002230 <scheduler>:
scheduler(void) {
    80002230:	1141                	addi	sp,sp,-16
    80002232:	e406                	sd	ra,8(sp)
    80002234:	e022                	sd	s0,0(sp)
    80002236:	0800                	addi	s0,sp,16
    printf("DEFAULT\n");
    80002238:	00006517          	auipc	a0,0x6
    8000223c:	ff050513          	addi	a0,a0,-16 # 80008228 <digits+0x1e8>
    80002240:	ffffe097          	auipc	ra,0xffffe
    80002244:	348080e7          	jalr	840(ra) # 80000588 <printf>
    defScheduler();
    80002248:	00000097          	auipc	ra,0x0
    8000224c:	cc8080e7          	jalr	-824(ra) # 80001f10 <defScheduler>

0000000080002250 <sched>:
sched(void) {
    80002250:	7179                	addi	sp,sp,-48
    80002252:	f406                	sd	ra,40(sp)
    80002254:	f022                	sd	s0,32(sp)
    80002256:	ec26                	sd	s1,24(sp)
    80002258:	e84a                	sd	s2,16(sp)
    8000225a:	e44e                	sd	s3,8(sp)
    8000225c:	1800                	addi	s0,sp,48
    struct proc *p = myproc();
    8000225e:	fffff097          	auipc	ra,0xfffff
    80002262:	76a080e7          	jalr	1898(ra) # 800019c8 <myproc>
    80002266:	84aa                	mv	s1,a0
    if (!holding(&p->lock))
    80002268:	fffff097          	auipc	ra,0xfffff
    8000226c:	902080e7          	jalr	-1790(ra) # 80000b6a <holding>
    80002270:	c93d                	beqz	a0,800022e6 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002272:	8792                	mv	a5,tp
    if (mycpu()->noff != 1)
    80002274:	2781                	sext.w	a5,a5
    80002276:	079e                	slli	a5,a5,0x7
    80002278:	0000f717          	auipc	a4,0xf
    8000227c:	04870713          	addi	a4,a4,72 # 800112c0 <pid_lock>
    80002280:	97ba                	add	a5,a5,a4
    80002282:	0a87a703          	lw	a4,168(a5)
    80002286:	4785                	li	a5,1
    80002288:	06f71763          	bne	a4,a5,800022f6 <sched+0xa6>
    if (p->state == RUNNING)
    8000228c:	4c98                	lw	a4,24(s1)
    8000228e:	4791                	li	a5,4
    80002290:	06f70b63          	beq	a4,a5,80002306 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002294:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002298:	8b89                	andi	a5,a5,2
    if (intr_get())
    8000229a:	efb5                	bnez	a5,80002316 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    8000229c:	8792                	mv	a5,tp
    intena = mycpu()->intena;
    8000229e:	0000f917          	auipc	s2,0xf
    800022a2:	02290913          	addi	s2,s2,34 # 800112c0 <pid_lock>
    800022a6:	2781                	sext.w	a5,a5
    800022a8:	079e                	slli	a5,a5,0x7
    800022aa:	97ca                	add	a5,a5,s2
    800022ac:	0ac7a983          	lw	s3,172(a5)
    800022b0:	8792                	mv	a5,tp
    swtch(&p->context, &mycpu()->context);
    800022b2:	2781                	sext.w	a5,a5
    800022b4:	079e                	slli	a5,a5,0x7
    800022b6:	0000f597          	auipc	a1,0xf
    800022ba:	04258593          	addi	a1,a1,66 # 800112f8 <cpus+0x8>
    800022be:	95be                	add	a1,a1,a5
    800022c0:	08048513          	addi	a0,s1,128
    800022c4:	00000097          	auipc	ra,0x0
    800022c8:	7c0080e7          	jalr	1984(ra) # 80002a84 <swtch>
    800022cc:	8792                	mv	a5,tp
    mycpu()->intena = intena;
    800022ce:	2781                	sext.w	a5,a5
    800022d0:	079e                	slli	a5,a5,0x7
    800022d2:	97ca                	add	a5,a5,s2
    800022d4:	0b37a623          	sw	s3,172(a5)
}
    800022d8:	70a2                	ld	ra,40(sp)
    800022da:	7402                	ld	s0,32(sp)
    800022dc:	64e2                	ld	s1,24(sp)
    800022de:	6942                	ld	s2,16(sp)
    800022e0:	69a2                	ld	s3,8(sp)
    800022e2:	6145                	addi	sp,sp,48
    800022e4:	8082                	ret
        panic("sched p->lock");
    800022e6:	00006517          	auipc	a0,0x6
    800022ea:	f5250513          	addi	a0,a0,-174 # 80008238 <digits+0x1f8>
    800022ee:	ffffe097          	auipc	ra,0xffffe
    800022f2:	250080e7          	jalr	592(ra) # 8000053e <panic>
        panic("sched locks");
    800022f6:	00006517          	auipc	a0,0x6
    800022fa:	f5250513          	addi	a0,a0,-174 # 80008248 <digits+0x208>
    800022fe:	ffffe097          	auipc	ra,0xffffe
    80002302:	240080e7          	jalr	576(ra) # 8000053e <panic>
        panic("sched running");
    80002306:	00006517          	auipc	a0,0x6
    8000230a:	f5250513          	addi	a0,a0,-174 # 80008258 <digits+0x218>
    8000230e:	ffffe097          	auipc	ra,0xffffe
    80002312:	230080e7          	jalr	560(ra) # 8000053e <panic>
        panic("sched interruptible");
    80002316:	00006517          	auipc	a0,0x6
    8000231a:	f5250513          	addi	a0,a0,-174 # 80008268 <digits+0x228>
    8000231e:	ffffe097          	auipc	ra,0xffffe
    80002322:	220080e7          	jalr	544(ra) # 8000053e <panic>

0000000080002326 <yield>:
yield(void) {
    80002326:	1101                	addi	sp,sp,-32
    80002328:	ec06                	sd	ra,24(sp)
    8000232a:	e822                	sd	s0,16(sp)
    8000232c:	e426                	sd	s1,8(sp)
    8000232e:	1000                	addi	s0,sp,32
    struct proc *p = myproc();
    80002330:	fffff097          	auipc	ra,0xfffff
    80002334:	698080e7          	jalr	1688(ra) # 800019c8 <myproc>
    80002338:	84aa                	mv	s1,a0
    acquire(&p->lock);
    8000233a:	fffff097          	auipc	ra,0xfffff
    8000233e:	8aa080e7          	jalr	-1878(ra) # 80000be4 <acquire>
    p->state = RUNNABLE;
    80002342:	478d                	li	a5,3
    80002344:	cc9c                	sw	a5,24(s1)
    p->running_time = p->running_time + (ticks - p->last_time_changed);
    80002346:	00007797          	auipc	a5,0x7
    8000234a:	d0a7a783          	lw	a5,-758(a5) # 80009050 <ticks>
    8000234e:	48f8                	lw	a4,84(s1)
    80002350:	9f3d                	addw	a4,a4,a5
    80002352:	4cb4                	lw	a3,88(s1)
    80002354:	9f15                	subw	a4,a4,a3
    80002356:	c8f8                	sw	a4,84(s1)
    p->last_runnable_time = ticks;     //added last_runnable time for fcfs
    80002358:	2781                	sext.w	a5,a5
    8000235a:	c4bc                	sw	a5,72(s1)
    p->last_time_changed = ticks;      //setting the starting ticks when getting to runnable for section 4
    8000235c:	ccbc                	sw	a5,88(s1)
    sched();
    8000235e:	00000097          	auipc	ra,0x0
    80002362:	ef2080e7          	jalr	-270(ra) # 80002250 <sched>
    release(&p->lock);
    80002366:	8526                	mv	a0,s1
    80002368:	fffff097          	auipc	ra,0xfffff
    8000236c:	930080e7          	jalr	-1744(ra) # 80000c98 <release>
}
    80002370:	60e2                	ld	ra,24(sp)
    80002372:	6442                	ld	s0,16(sp)
    80002374:	64a2                	ld	s1,8(sp)
    80002376:	6105                	addi	sp,sp,32
    80002378:	8082                	ret

000000008000237a <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk) {
    8000237a:	7179                	addi	sp,sp,-48
    8000237c:	f406                	sd	ra,40(sp)
    8000237e:	f022                	sd	s0,32(sp)
    80002380:	ec26                	sd	s1,24(sp)
    80002382:	e84a                	sd	s2,16(sp)
    80002384:	e44e                	sd	s3,8(sp)
    80002386:	1800                	addi	s0,sp,48
    80002388:	89aa                	mv	s3,a0
    8000238a:	892e                	mv	s2,a1
    struct proc *p = myproc();
    8000238c:	fffff097          	auipc	ra,0xfffff
    80002390:	63c080e7          	jalr	1596(ra) # 800019c8 <myproc>
    80002394:	84aa                	mv	s1,a0
    // Once we hold p->lock, we can be
    // guaranteed that we won't miss any wakeup
    // (wakeup locks p->lock),
    // so it's okay to release lk.

    acquire(&p->lock);  //DOC: sleeplock1
    80002396:	fffff097          	auipc	ra,0xfffff
    8000239a:	84e080e7          	jalr	-1970(ra) # 80000be4 <acquire>
    release(lk);
    8000239e:	854a                	mv	a0,s2
    800023a0:	fffff097          	auipc	ra,0xfffff
    800023a4:	8f8080e7          	jalr	-1800(ra) # 80000c98 <release>


    p->running_time = p->running_time + ticks - p->last_time_changed;
    800023a8:	00007717          	auipc	a4,0x7
    800023ac:	ca872703          	lw	a4,-856(a4) # 80009050 <ticks>
    800023b0:	48fc                	lw	a5,84(s1)
    800023b2:	9fb9                	addw	a5,a5,a4
    800023b4:	4cb4                	lw	a3,88(s1)
    800023b6:	9f95                	subw	a5,a5,a3
    800023b8:	c8fc                	sw	a5,84(s1)
    p->last_time_changed = ticks;      //setting the starting ticks when getting to runnable for section 4
    800023ba:	ccb8                	sw	a4,88(s1)

    // Go to sleep.
    p->chan = chan;
    800023bc:	0334b023          	sd	s3,32(s1)
    p->state = SLEEPING;
    800023c0:	4789                	li	a5,2
    800023c2:	cc9c                	sw	a5,24(s1)

    sched();
    800023c4:	00000097          	auipc	ra,0x0
    800023c8:	e8c080e7          	jalr	-372(ra) # 80002250 <sched>

    // Tidy up.
    p->chan = 0;
    800023cc:	0204b023          	sd	zero,32(s1)

    // Reacquire original lock.
    release(&p->lock);
    800023d0:	8526                	mv	a0,s1
    800023d2:	fffff097          	auipc	ra,0xfffff
    800023d6:	8c6080e7          	jalr	-1850(ra) # 80000c98 <release>
    acquire(lk);
    800023da:	854a                	mv	a0,s2
    800023dc:	fffff097          	auipc	ra,0xfffff
    800023e0:	808080e7          	jalr	-2040(ra) # 80000be4 <acquire>
}
    800023e4:	70a2                	ld	ra,40(sp)
    800023e6:	7402                	ld	s0,32(sp)
    800023e8:	64e2                	ld	s1,24(sp)
    800023ea:	6942                	ld	s2,16(sp)
    800023ec:	69a2                	ld	s3,8(sp)
    800023ee:	6145                	addi	sp,sp,48
    800023f0:	8082                	ret

00000000800023f2 <wait>:
wait(uint64 addr) {
    800023f2:	715d                	addi	sp,sp,-80
    800023f4:	e486                	sd	ra,72(sp)
    800023f6:	e0a2                	sd	s0,64(sp)
    800023f8:	fc26                	sd	s1,56(sp)
    800023fa:	f84a                	sd	s2,48(sp)
    800023fc:	f44e                	sd	s3,40(sp)
    800023fe:	f052                	sd	s4,32(sp)
    80002400:	ec56                	sd	s5,24(sp)
    80002402:	e85a                	sd	s6,16(sp)
    80002404:	e45e                	sd	s7,8(sp)
    80002406:	e062                	sd	s8,0(sp)
    80002408:	0880                	addi	s0,sp,80
    8000240a:	8b2a                	mv	s6,a0
    struct proc *p = myproc();
    8000240c:	fffff097          	auipc	ra,0xfffff
    80002410:	5bc080e7          	jalr	1468(ra) # 800019c8 <myproc>
    80002414:	892a                	mv	s2,a0
    acquire(&wait_lock);
    80002416:	0000f517          	auipc	a0,0xf
    8000241a:	ec250513          	addi	a0,a0,-318 # 800112d8 <wait_lock>
    8000241e:	ffffe097          	auipc	ra,0xffffe
    80002422:	7c6080e7          	jalr	1990(ra) # 80000be4 <acquire>
        havekids = 0;
    80002426:	4b81                	li	s7,0
                if (np->state == ZOMBIE) {
    80002428:	4a15                	li	s4,5
        for (np = proc; np < &proc[NPROC]; np++) {
    8000242a:	00015997          	auipc	s3,0x15
    8000242e:	4c698993          	addi	s3,s3,1222 # 800178f0 <tickslock>
                havekids = 1;
    80002432:	4a85                	li	s5,1
        sleep(p, &wait_lock);  //DOC: wait-sleep
    80002434:	0000fc17          	auipc	s8,0xf
    80002438:	ea4c0c13          	addi	s8,s8,-348 # 800112d8 <wait_lock>
        havekids = 0;
    8000243c:	875e                	mv	a4,s7
        for (np = proc; np < &proc[NPROC]; np++) {
    8000243e:	0000f497          	auipc	s1,0xf
    80002442:	2b248493          	addi	s1,s1,690 # 800116f0 <proc>
    80002446:	a0bd                	j	800024b4 <wait+0xc2>
                    pid = np->pid;
    80002448:	0304a983          	lw	s3,48(s1)
                    if (addr != 0 && copyout(p->pagetable, addr, (char *) &np->xstate,
    8000244c:	000b0e63          	beqz	s6,80002468 <wait+0x76>
    80002450:	4691                	li	a3,4
    80002452:	02c48613          	addi	a2,s1,44
    80002456:	85da                	mv	a1,s6
    80002458:	07093503          	ld	a0,112(s2)
    8000245c:	fffff097          	auipc	ra,0xfffff
    80002460:	21e080e7          	jalr	542(ra) # 8000167a <copyout>
    80002464:	02054563          	bltz	a0,8000248e <wait+0x9c>
                    freeproc(np);
    80002468:	8526                	mv	a0,s1
    8000246a:	fffff097          	auipc	ra,0xfffff
    8000246e:	710080e7          	jalr	1808(ra) # 80001b7a <freeproc>
                    release(&np->lock);
    80002472:	8526                	mv	a0,s1
    80002474:	fffff097          	auipc	ra,0xfffff
    80002478:	824080e7          	jalr	-2012(ra) # 80000c98 <release>
                    release(&wait_lock);
    8000247c:	0000f517          	auipc	a0,0xf
    80002480:	e5c50513          	addi	a0,a0,-420 # 800112d8 <wait_lock>
    80002484:	fffff097          	auipc	ra,0xfffff
    80002488:	814080e7          	jalr	-2028(ra) # 80000c98 <release>
                    return pid;
    8000248c:	a09d                	j	800024f2 <wait+0x100>
                        release(&np->lock);
    8000248e:	8526                	mv	a0,s1
    80002490:	fffff097          	auipc	ra,0xfffff
    80002494:	808080e7          	jalr	-2040(ra) # 80000c98 <release>
                        release(&wait_lock);
    80002498:	0000f517          	auipc	a0,0xf
    8000249c:	e4050513          	addi	a0,a0,-448 # 800112d8 <wait_lock>
    800024a0:	ffffe097          	auipc	ra,0xffffe
    800024a4:	7f8080e7          	jalr	2040(ra) # 80000c98 <release>
                        return -1;
    800024a8:	59fd                	li	s3,-1
    800024aa:	a0a1                	j	800024f2 <wait+0x100>
        for (np = proc; np < &proc[NPROC]; np++) {
    800024ac:	18848493          	addi	s1,s1,392
    800024b0:	03348463          	beq	s1,s3,800024d8 <wait+0xe6>
            if (np->parent == p) {
    800024b4:	7c9c                	ld	a5,56(s1)
    800024b6:	ff279be3          	bne	a5,s2,800024ac <wait+0xba>
                acquire(&np->lock);
    800024ba:	8526                	mv	a0,s1
    800024bc:	ffffe097          	auipc	ra,0xffffe
    800024c0:	728080e7          	jalr	1832(ra) # 80000be4 <acquire>
                if (np->state == ZOMBIE) {
    800024c4:	4c9c                	lw	a5,24(s1)
    800024c6:	f94781e3          	beq	a5,s4,80002448 <wait+0x56>
                release(&np->lock);
    800024ca:	8526                	mv	a0,s1
    800024cc:	ffffe097          	auipc	ra,0xffffe
    800024d0:	7cc080e7          	jalr	1996(ra) # 80000c98 <release>
                havekids = 1;
    800024d4:	8756                	mv	a4,s5
    800024d6:	bfd9                	j	800024ac <wait+0xba>
        if (!havekids || p->killed) {
    800024d8:	c701                	beqz	a4,800024e0 <wait+0xee>
    800024da:	02892783          	lw	a5,40(s2)
    800024de:	c79d                	beqz	a5,8000250c <wait+0x11a>
            release(&wait_lock);
    800024e0:	0000f517          	auipc	a0,0xf
    800024e4:	df850513          	addi	a0,a0,-520 # 800112d8 <wait_lock>
    800024e8:	ffffe097          	auipc	ra,0xffffe
    800024ec:	7b0080e7          	jalr	1968(ra) # 80000c98 <release>
            return -1;
    800024f0:	59fd                	li	s3,-1
}
    800024f2:	854e                	mv	a0,s3
    800024f4:	60a6                	ld	ra,72(sp)
    800024f6:	6406                	ld	s0,64(sp)
    800024f8:	74e2                	ld	s1,56(sp)
    800024fa:	7942                	ld	s2,48(sp)
    800024fc:	79a2                	ld	s3,40(sp)
    800024fe:	7a02                	ld	s4,32(sp)
    80002500:	6ae2                	ld	s5,24(sp)
    80002502:	6b42                	ld	s6,16(sp)
    80002504:	6ba2                	ld	s7,8(sp)
    80002506:	6c02                	ld	s8,0(sp)
    80002508:	6161                	addi	sp,sp,80
    8000250a:	8082                	ret
        sleep(p, &wait_lock);  //DOC: wait-sleep
    8000250c:	85e2                	mv	a1,s8
    8000250e:	854a                	mv	a0,s2
    80002510:	00000097          	auipc	ra,0x0
    80002514:	e6a080e7          	jalr	-406(ra) # 8000237a <sleep>
        havekids = 0;
    80002518:	b715                	j	8000243c <wait+0x4a>

000000008000251a <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void
wakeup(void *chan) {
    8000251a:	7139                	addi	sp,sp,-64
    8000251c:	fc06                	sd	ra,56(sp)
    8000251e:	f822                	sd	s0,48(sp)
    80002520:	f426                	sd	s1,40(sp)
    80002522:	f04a                	sd	s2,32(sp)
    80002524:	ec4e                	sd	s3,24(sp)
    80002526:	e852                	sd	s4,16(sp)
    80002528:	e456                	sd	s5,8(sp)
    8000252a:	e05a                	sd	s6,0(sp)
    8000252c:	0080                	addi	s0,sp,64
    8000252e:	8a2a                	mv	s4,a0
    struct proc *p;

    for (p = proc; p < &proc[NPROC]; p++) {
    80002530:	0000f497          	auipc	s1,0xf
    80002534:	1c048493          	addi	s1,s1,448 # 800116f0 <proc>
        if (p != myproc()) {
            acquire(&p->lock);
            if (p->state == SLEEPING && p->chan == chan) {
    80002538:	4989                	li	s3,2
                p->state = RUNNABLE;
    8000253a:	4b0d                	li	s6,3

                p->sleeping_time = p->sleeping_time + ticks - p->last_time_changed;
    8000253c:	00007a97          	auipc	s5,0x7
    80002540:	b14a8a93          	addi	s5,s5,-1260 # 80009050 <ticks>
    for (p = proc; p < &proc[NPROC]; p++) {
    80002544:	00015917          	auipc	s2,0x15
    80002548:	3ac90913          	addi	s2,s2,940 # 800178f0 <tickslock>
    8000254c:	a035                	j	80002578 <wakeup+0x5e>
                p->state = RUNNABLE;
    8000254e:	0164ac23          	sw	s6,24(s1)
                p->sleeping_time = p->sleeping_time + ticks - p->last_time_changed;
    80002552:	000aa783          	lw	a5,0(s5)
    80002556:	44f8                	lw	a4,76(s1)
    80002558:	9f3d                	addw	a4,a4,a5
    8000255a:	4cb4                	lw	a3,88(s1)
    8000255c:	9f15                	subw	a4,a4,a3
    8000255e:	c4f8                	sw	a4,76(s1)
                p->last_runnable_time = ticks;     //added last_runnable time for fcfs
    80002560:	2781                	sext.w	a5,a5
    80002562:	c4bc                	sw	a5,72(s1)
                p->last_time_changed = ticks;      //setting the starting ticks when getting to runnable for section 4
    80002564:	ccbc                	sw	a5,88(s1)

            }
            release(&p->lock);
    80002566:	8526                	mv	a0,s1
    80002568:	ffffe097          	auipc	ra,0xffffe
    8000256c:	730080e7          	jalr	1840(ra) # 80000c98 <release>
    for (p = proc; p < &proc[NPROC]; p++) {
    80002570:	18848493          	addi	s1,s1,392
    80002574:	03248463          	beq	s1,s2,8000259c <wakeup+0x82>
        if (p != myproc()) {
    80002578:	fffff097          	auipc	ra,0xfffff
    8000257c:	450080e7          	jalr	1104(ra) # 800019c8 <myproc>
    80002580:	fea488e3          	beq	s1,a0,80002570 <wakeup+0x56>
            acquire(&p->lock);
    80002584:	8526                	mv	a0,s1
    80002586:	ffffe097          	auipc	ra,0xffffe
    8000258a:	65e080e7          	jalr	1630(ra) # 80000be4 <acquire>
            if (p->state == SLEEPING && p->chan == chan) {
    8000258e:	4c9c                	lw	a5,24(s1)
    80002590:	fd379be3          	bne	a5,s3,80002566 <wakeup+0x4c>
    80002594:	709c                	ld	a5,32(s1)
    80002596:	fd4798e3          	bne	a5,s4,80002566 <wakeup+0x4c>
    8000259a:	bf55                	j	8000254e <wakeup+0x34>
        }
    }
}
    8000259c:	70e2                	ld	ra,56(sp)
    8000259e:	7442                	ld	s0,48(sp)
    800025a0:	74a2                	ld	s1,40(sp)
    800025a2:	7902                	ld	s2,32(sp)
    800025a4:	69e2                	ld	s3,24(sp)
    800025a6:	6a42                	ld	s4,16(sp)
    800025a8:	6aa2                	ld	s5,8(sp)
    800025aa:	6b02                	ld	s6,0(sp)
    800025ac:	6121                	addi	sp,sp,64
    800025ae:	8082                	ret

00000000800025b0 <reparent>:
reparent(struct proc *p) {
    800025b0:	7179                	addi	sp,sp,-48
    800025b2:	f406                	sd	ra,40(sp)
    800025b4:	f022                	sd	s0,32(sp)
    800025b6:	ec26                	sd	s1,24(sp)
    800025b8:	e84a                	sd	s2,16(sp)
    800025ba:	e44e                	sd	s3,8(sp)
    800025bc:	e052                	sd	s4,0(sp)
    800025be:	1800                	addi	s0,sp,48
    800025c0:	892a                	mv	s2,a0
    for (pp = proc; pp < &proc[NPROC]; pp++) {
    800025c2:	0000f497          	auipc	s1,0xf
    800025c6:	12e48493          	addi	s1,s1,302 # 800116f0 <proc>
            pp->parent = initproc;
    800025ca:	00007a17          	auipc	s4,0x7
    800025ce:	a7ea0a13          	addi	s4,s4,-1410 # 80009048 <initproc>
    for (pp = proc; pp < &proc[NPROC]; pp++) {
    800025d2:	00015997          	auipc	s3,0x15
    800025d6:	31e98993          	addi	s3,s3,798 # 800178f0 <tickslock>
    800025da:	a029                	j	800025e4 <reparent+0x34>
    800025dc:	18848493          	addi	s1,s1,392
    800025e0:	01348d63          	beq	s1,s3,800025fa <reparent+0x4a>
        if (pp->parent == p) {
    800025e4:	7c9c                	ld	a5,56(s1)
    800025e6:	ff279be3          	bne	a5,s2,800025dc <reparent+0x2c>
            pp->parent = initproc;
    800025ea:	000a3503          	ld	a0,0(s4)
    800025ee:	fc88                	sd	a0,56(s1)
            wakeup(initproc);
    800025f0:	00000097          	auipc	ra,0x0
    800025f4:	f2a080e7          	jalr	-214(ra) # 8000251a <wakeup>
    800025f8:	b7d5                	j	800025dc <reparent+0x2c>
}
    800025fa:	70a2                	ld	ra,40(sp)
    800025fc:	7402                	ld	s0,32(sp)
    800025fe:	64e2                	ld	s1,24(sp)
    80002600:	6942                	ld	s2,16(sp)
    80002602:	69a2                	ld	s3,8(sp)
    80002604:	6a02                	ld	s4,0(sp)
    80002606:	6145                	addi	sp,sp,48
    80002608:	8082                	ret

000000008000260a <exit>:
exit(int status) {
    8000260a:	7179                	addi	sp,sp,-48
    8000260c:	f406                	sd	ra,40(sp)
    8000260e:	f022                	sd	s0,32(sp)
    80002610:	ec26                	sd	s1,24(sp)
    80002612:	e84a                	sd	s2,16(sp)
    80002614:	e44e                	sd	s3,8(sp)
    80002616:	e052                	sd	s4,0(sp)
    80002618:	1800                	addi	s0,sp,48
    8000261a:	8a2a                	mv	s4,a0
    struct proc *p = myproc();
    8000261c:	fffff097          	auipc	ra,0xfffff
    80002620:	3ac080e7          	jalr	940(ra) # 800019c8 <myproc>
    80002624:	892a                	mv	s2,a0
    if (p == initproc)
    80002626:	00007797          	auipc	a5,0x7
    8000262a:	a227b783          	ld	a5,-1502(a5) # 80009048 <initproc>
    8000262e:	0f050493          	addi	s1,a0,240
    80002632:	17050993          	addi	s3,a0,368
    80002636:	02a79363          	bne	a5,a0,8000265c <exit+0x52>
        panic("init exiting");
    8000263a:	00006517          	auipc	a0,0x6
    8000263e:	c4650513          	addi	a0,a0,-954 # 80008280 <digits+0x240>
    80002642:	ffffe097          	auipc	ra,0xffffe
    80002646:	efc080e7          	jalr	-260(ra) # 8000053e <panic>
            fileclose(f);
    8000264a:	00002097          	auipc	ra,0x2
    8000264e:	3a4080e7          	jalr	932(ra) # 800049ee <fileclose>
            p->ofile[fd] = 0;
    80002652:	0004b023          	sd	zero,0(s1)
    for (int fd = 0; fd < NOFILE; fd++) {
    80002656:	04a1                	addi	s1,s1,8
    80002658:	01348563          	beq	s1,s3,80002662 <exit+0x58>
        if (p->ofile[fd]) {
    8000265c:	6088                	ld	a0,0(s1)
    8000265e:	f575                	bnez	a0,8000264a <exit+0x40>
    80002660:	bfdd                	j	80002656 <exit+0x4c>
    begin_op();
    80002662:	00002097          	auipc	ra,0x2
    80002666:	ec0080e7          	jalr	-320(ra) # 80004522 <begin_op>
    iput(p->cwd);
    8000266a:	17093503          	ld	a0,368(s2)
    8000266e:	00001097          	auipc	ra,0x1
    80002672:	69c080e7          	jalr	1692(ra) # 80003d0a <iput>
    end_op();
    80002676:	00002097          	auipc	ra,0x2
    8000267a:	f2c080e7          	jalr	-212(ra) # 800045a2 <end_op>
    p->cwd = 0;
    8000267e:	16093823          	sd	zero,368(s2)
    acquire(&wait_lock);
    80002682:	0000f497          	auipc	s1,0xf
    80002686:	c5648493          	addi	s1,s1,-938 # 800112d8 <wait_lock>
    8000268a:	8526                	mv	a0,s1
    8000268c:	ffffe097          	auipc	ra,0xffffe
    80002690:	558080e7          	jalr	1368(ra) # 80000be4 <acquire>
    reparent(p);
    80002694:	854a                	mv	a0,s2
    80002696:	00000097          	auipc	ra,0x0
    8000269a:	f1a080e7          	jalr	-230(ra) # 800025b0 <reparent>
    wakeup(p->parent);
    8000269e:	03893503          	ld	a0,56(s2)
    800026a2:	00000097          	auipc	ra,0x0
    800026a6:	e78080e7          	jalr	-392(ra) # 8000251a <wakeup>
    acquire(&p->lock);
    800026aa:	854a                	mv	a0,s2
    800026ac:	ffffe097          	auipc	ra,0xffffe
    800026b0:	538080e7          	jalr	1336(ra) # 80000be4 <acquire>
    p->running_time = p->running_time + ticks - p->last_time_changed;
    800026b4:	00007617          	auipc	a2,0x7
    800026b8:	99c62603          	lw	a2,-1636(a2) # 80009050 <ticks>
    800026bc:	05492703          	lw	a4,84(s2)
    800026c0:	9f31                	addw	a4,a4,a2
    800026c2:	05892683          	lw	a3,88(s2)
    800026c6:	40d706bb          	subw	a3,a4,a3
    800026ca:	04d92a23          	sw	a3,84(s2)
    program_time = program_time + p->running_time;
    800026ce:	00007717          	auipc	a4,0x7
    800026d2:	96270713          	addi	a4,a4,-1694 # 80009030 <program_time>
    800026d6:	431c                	lw	a5,0(a4)
    800026d8:	9fb5                	addw	a5,a5,a3
    800026da:	c31c                	sw	a5,0(a4)
    cpu_utilization = program_time / (ticks - start_time);
    800026dc:	00007717          	auipc	a4,0x7
    800026e0:	94c72703          	lw	a4,-1716(a4) # 80009028 <start_time>
    800026e4:	9e19                	subw	a2,a2,a4
    800026e6:	02c7d7bb          	divuw	a5,a5,a2
    800026ea:	00007717          	auipc	a4,0x7
    800026ee:	94f72123          	sw	a5,-1726(a4) # 8000902c <cpu_utilization>
    sleeping_processes_mean = (sleeping_processes_mean * (nextpid - 1) + p->sleeping_time) / (nextpid);
    800026f2:	00006617          	auipc	a2,0x6
    800026f6:	1f262603          	lw	a2,498(a2) # 800088e4 <nextpid>
    800026fa:	fff6059b          	addiw	a1,a2,-1
    800026fe:	00007797          	auipc	a5,0x7
    80002702:	93e78793          	addi	a5,a5,-1730 # 8000903c <sleeping_processes_mean>
    80002706:	4398                	lw	a4,0(a5)
    80002708:	02b7073b          	mulw	a4,a4,a1
    8000270c:	04c92503          	lw	a0,76(s2)
    80002710:	9f29                	addw	a4,a4,a0
    80002712:	02c7473b          	divw	a4,a4,a2
    80002716:	c398                	sw	a4,0(a5)
    running_processes_mean = (running_processes_mean * (nextpid - 1) + p->running_time) / (nextpid);
    80002718:	00007797          	auipc	a5,0x7
    8000271c:	92078793          	addi	a5,a5,-1760 # 80009038 <running_processes_mean>
    80002720:	4398                	lw	a4,0(a5)
    80002722:	02b7073b          	mulw	a4,a4,a1
    80002726:	9f35                	addw	a4,a4,a3
    80002728:	02c7473b          	divw	a4,a4,a2
    8000272c:	c398                	sw	a4,0(a5)
    runnable_processes_mean = (runnable_processes_mean * (nextpid - 1) + p->runnable_time) / (nextpid);
    8000272e:	00007717          	auipc	a4,0x7
    80002732:	90670713          	addi	a4,a4,-1786 # 80009034 <runnable_processes_mean>
    80002736:	431c                	lw	a5,0(a4)
    80002738:	02b787bb          	mulw	a5,a5,a1
    8000273c:	05092683          	lw	a3,80(s2)
    80002740:	9fb5                	addw	a5,a5,a3
    80002742:	02c7c7bb          	divw	a5,a5,a2
    80002746:	c31c                	sw	a5,0(a4)
    p->xstate = status;
    80002748:	03492623          	sw	s4,44(s2)
    p->state = ZOMBIE;
    8000274c:	4795                	li	a5,5
    8000274e:	00f92c23          	sw	a5,24(s2)
    release(&wait_lock);
    80002752:	8526                	mv	a0,s1
    80002754:	ffffe097          	auipc	ra,0xffffe
    80002758:	544080e7          	jalr	1348(ra) # 80000c98 <release>
    sched();
    8000275c:	00000097          	auipc	ra,0x0
    80002760:	af4080e7          	jalr	-1292(ra) # 80002250 <sched>
    panic("zombie exit");
    80002764:	00006517          	auipc	a0,0x6
    80002768:	b2c50513          	addi	a0,a0,-1236 # 80008290 <digits+0x250>
    8000276c:	ffffe097          	auipc	ra,0xffffe
    80002770:	dd2080e7          	jalr	-558(ra) # 8000053e <panic>

0000000080002774 <kill>:

// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid) {
    80002774:	7179                	addi	sp,sp,-48
    80002776:	f406                	sd	ra,40(sp)
    80002778:	f022                	sd	s0,32(sp)
    8000277a:	ec26                	sd	s1,24(sp)
    8000277c:	e84a                	sd	s2,16(sp)
    8000277e:	e44e                	sd	s3,8(sp)
    80002780:	1800                	addi	s0,sp,48
    80002782:	892a                	mv	s2,a0
    struct proc *p;

    for (p = proc; p < &proc[NPROC]; p++) {
    80002784:	0000f497          	auipc	s1,0xf
    80002788:	f6c48493          	addi	s1,s1,-148 # 800116f0 <proc>
    8000278c:	00015997          	auipc	s3,0x15
    80002790:	16498993          	addi	s3,s3,356 # 800178f0 <tickslock>
        acquire(&p->lock);
    80002794:	8526                	mv	a0,s1
    80002796:	ffffe097          	auipc	ra,0xffffe
    8000279a:	44e080e7          	jalr	1102(ra) # 80000be4 <acquire>
        if (p->pid == pid) {
    8000279e:	589c                	lw	a5,48(s1)
    800027a0:	01278d63          	beq	a5,s2,800027ba <kill+0x46>
                p->last_time_changed = ticks;      //setting the starting ticks when getting to runnable for section 4
            }
            release(&p->lock);
            return 0;
        }
        release(&p->lock);
    800027a4:	8526                	mv	a0,s1
    800027a6:	ffffe097          	auipc	ra,0xffffe
    800027aa:	4f2080e7          	jalr	1266(ra) # 80000c98 <release>
    for (p = proc; p < &proc[NPROC]; p++) {
    800027ae:	18848493          	addi	s1,s1,392
    800027b2:	ff3491e3          	bne	s1,s3,80002794 <kill+0x20>
    }
    return -1;
    800027b6:	557d                	li	a0,-1
    800027b8:	a829                	j	800027d2 <kill+0x5e>
            p->killed = 1;
    800027ba:	4785                	li	a5,1
    800027bc:	d49c                	sw	a5,40(s1)
            if (p->state == SLEEPING) {
    800027be:	4c98                	lw	a4,24(s1)
    800027c0:	4789                	li	a5,2
    800027c2:	00f70f63          	beq	a4,a5,800027e0 <kill+0x6c>
            release(&p->lock);
    800027c6:	8526                	mv	a0,s1
    800027c8:	ffffe097          	auipc	ra,0xffffe
    800027cc:	4d0080e7          	jalr	1232(ra) # 80000c98 <release>
            return 0;
    800027d0:	4501                	li	a0,0
}
    800027d2:	70a2                	ld	ra,40(sp)
    800027d4:	7402                	ld	s0,32(sp)
    800027d6:	64e2                	ld	s1,24(sp)
    800027d8:	6942                	ld	s2,16(sp)
    800027da:	69a2                	ld	s3,8(sp)
    800027dc:	6145                	addi	sp,sp,48
    800027de:	8082                	ret
                p->state = RUNNABLE;
    800027e0:	478d                	li	a5,3
    800027e2:	cc9c                	sw	a5,24(s1)
                p->sleeping_time = p->sleeping_time + ticks - p->last_time_changed;
    800027e4:	00007797          	auipc	a5,0x7
    800027e8:	86c7a783          	lw	a5,-1940(a5) # 80009050 <ticks>
    800027ec:	44f8                	lw	a4,76(s1)
    800027ee:	9f3d                	addw	a4,a4,a5
    800027f0:	4cb4                	lw	a3,88(s1)
    800027f2:	9f15                	subw	a4,a4,a3
    800027f4:	c4f8                	sw	a4,76(s1)
                p->last_runnable_time = ticks;     //added last_runnable time for fcfs
    800027f6:	2781                	sext.w	a5,a5
    800027f8:	c4bc                	sw	a5,72(s1)
                p->last_time_changed = ticks;      //setting the starting ticks when getting to runnable for section 4
    800027fa:	ccbc                	sw	a5,88(s1)
    800027fc:	b7e9                	j	800027c6 <kill+0x52>

00000000800027fe <kill_system>:

int kill_system(void) {
    800027fe:	7179                	addi	sp,sp,-48
    80002800:	f406                	sd	ra,40(sp)
    80002802:	f022                	sd	s0,32(sp)
    80002804:	ec26                	sd	s1,24(sp)
    80002806:	e84a                	sd	s2,16(sp)
    80002808:	e44e                	sd	s3,8(sp)
    8000280a:	1800                	addi	s0,sp,48
    // init pid = 1
    // shell pid = 2
    struct proc *p;
    int i = 0;
    for (p = proc; p < &proc[NPROC]; p++, i++) {
    8000280c:	0000f497          	auipc	s1,0xf
    80002810:	ee448493          	addi	s1,s1,-284 # 800116f0 <proc>
        acquire(&p->lock);
        if (p->pid != 1 && p->pid != 2) {
    80002814:	4985                	li	s3,1
    for (p = proc; p < &proc[NPROC]; p++, i++) {
    80002816:	00015917          	auipc	s2,0x15
    8000281a:	0da90913          	addi	s2,s2,218 # 800178f0 <tickslock>
    8000281e:	a811                	j	80002832 <kill_system+0x34>
            release(&p->lock);
            kill(p->pid);
        } else {
            release(&p->lock);
    80002820:	8526                	mv	a0,s1
    80002822:	ffffe097          	auipc	ra,0xffffe
    80002826:	476080e7          	jalr	1142(ra) # 80000c98 <release>
    for (p = proc; p < &proc[NPROC]; p++, i++) {
    8000282a:	18848493          	addi	s1,s1,392
    8000282e:	03248663          	beq	s1,s2,8000285a <kill_system+0x5c>
        acquire(&p->lock);
    80002832:	8526                	mv	a0,s1
    80002834:	ffffe097          	auipc	ra,0xffffe
    80002838:	3b0080e7          	jalr	944(ra) # 80000be4 <acquire>
        if (p->pid != 1 && p->pid != 2) {
    8000283c:	589c                	lw	a5,48(s1)
    8000283e:	37fd                	addiw	a5,a5,-1
    80002840:	fef9f0e3          	bgeu	s3,a5,80002820 <kill_system+0x22>
            release(&p->lock);
    80002844:	8526                	mv	a0,s1
    80002846:	ffffe097          	auipc	ra,0xffffe
    8000284a:	452080e7          	jalr	1106(ra) # 80000c98 <release>
            kill(p->pid);
    8000284e:	5888                	lw	a0,48(s1)
    80002850:	00000097          	auipc	ra,0x0
    80002854:	f24080e7          	jalr	-220(ra) # 80002774 <kill>
    80002858:	bfc9                	j	8000282a <kill_system+0x2c>
        }
    }

    return 0;
    //todo check if need to verify kill returned 0, in case not what should we do.
}
    8000285a:	4501                	li	a0,0
    8000285c:	70a2                	ld	ra,40(sp)
    8000285e:	7402                	ld	s0,32(sp)
    80002860:	64e2                	ld	s1,24(sp)
    80002862:	6942                	ld	s2,16(sp)
    80002864:	69a2                	ld	s3,8(sp)
    80002866:	6145                	addi	sp,sp,48
    80002868:	8082                	ret

000000008000286a <pause_system>:

//pause all user processes for the number of seconds specified by the parameter
int pause_system(int seconds) {
    8000286a:	1141                	addi	sp,sp,-16
    8000286c:	e406                	sd	ra,8(sp)
    8000286e:	e022                	sd	s0,0(sp)
    80002870:	0800                	addi	s0,sp,16
    pauseTicks = ticks + seconds * 10; //todo check if can get 1000000 as number
    80002872:	0025179b          	slliw	a5,a0,0x2
    80002876:	9fa9                	addw	a5,a5,a0
    80002878:	0017979b          	slliw	a5,a5,0x1
    8000287c:	00006517          	auipc	a0,0x6
    80002880:	7d452503          	lw	a0,2004(a0) # 80009050 <ticks>
    80002884:	9fa9                	addw	a5,a5,a0
    80002886:	00006717          	auipc	a4,0x6
    8000288a:	7af72d23          	sw	a5,1978(a4) # 80009040 <pauseTicks>
    yield();
    8000288e:	00000097          	auipc	ra,0x0
    80002892:	a98080e7          	jalr	-1384(ra) # 80002326 <yield>
    return 0;
}
    80002896:	4501                	li	a0,0
    80002898:	60a2                	ld	ra,8(sp)
    8000289a:	6402                	ld	s0,0(sp)
    8000289c:	0141                	addi	sp,sp,16
    8000289e:	8082                	ret

00000000800028a0 <print_stats>:

int print_stats(void) {
    800028a0:	1141                	addi	sp,sp,-16
    800028a2:	e406                	sd	ra,8(sp)
    800028a4:	e022                	sd	s0,0(sp)
    800028a6:	0800                	addi	s0,sp,16
    printf("runnable_processes_mean: %d\n",runnable_processes_mean);
    800028a8:	00006597          	auipc	a1,0x6
    800028ac:	78c5a583          	lw	a1,1932(a1) # 80009034 <runnable_processes_mean>
    800028b0:	00006517          	auipc	a0,0x6
    800028b4:	9f050513          	addi	a0,a0,-1552 # 800082a0 <digits+0x260>
    800028b8:	ffffe097          	auipc	ra,0xffffe
    800028bc:	cd0080e7          	jalr	-816(ra) # 80000588 <printf>
    printf("running_processes_mean: %d\n",running_processes_mean);
    800028c0:	00006597          	auipc	a1,0x6
    800028c4:	7785a583          	lw	a1,1912(a1) # 80009038 <running_processes_mean>
    800028c8:	00006517          	auipc	a0,0x6
    800028cc:	9f850513          	addi	a0,a0,-1544 # 800082c0 <digits+0x280>
    800028d0:	ffffe097          	auipc	ra,0xffffe
    800028d4:	cb8080e7          	jalr	-840(ra) # 80000588 <printf>
    printf("sleeping_processes_mean: %d\n",sleeping_processes_mean);
    800028d8:	00006597          	auipc	a1,0x6
    800028dc:	7645a583          	lw	a1,1892(a1) # 8000903c <sleeping_processes_mean>
    800028e0:	00006517          	auipc	a0,0x6
    800028e4:	a0050513          	addi	a0,a0,-1536 # 800082e0 <digits+0x2a0>
    800028e8:	ffffe097          	auipc	ra,0xffffe
    800028ec:	ca0080e7          	jalr	-864(ra) # 80000588 <printf>
    printf("cpu_utilization: %d\n", cpu_utilization);
    800028f0:	00006597          	auipc	a1,0x6
    800028f4:	73c5a583          	lw	a1,1852(a1) # 8000902c <cpu_utilization>
    800028f8:	00006517          	auipc	a0,0x6
    800028fc:	a0850513          	addi	a0,a0,-1528 # 80008300 <digits+0x2c0>
    80002900:	ffffe097          	auipc	ra,0xffffe
    80002904:	c88080e7          	jalr	-888(ra) # 80000588 <printf>
    printf("program_time: %d\n", program_time);
    80002908:	00006597          	auipc	a1,0x6
    8000290c:	7285a583          	lw	a1,1832(a1) # 80009030 <program_time>
    80002910:	00006517          	auipc	a0,0x6
    80002914:	a0850513          	addi	a0,a0,-1528 # 80008318 <digits+0x2d8>
    80002918:	ffffe097          	auipc	ra,0xffffe
    8000291c:	c70080e7          	jalr	-912(ra) # 80000588 <printf>
    return 0;
}
    80002920:	4501                	li	a0,0
    80002922:	60a2                	ld	ra,8(sp)
    80002924:	6402                	ld	s0,0(sp)
    80002926:	0141                	addi	sp,sp,16
    80002928:	8082                	ret

000000008000292a <either_copyout>:

// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len) {
    8000292a:	7179                	addi	sp,sp,-48
    8000292c:	f406                	sd	ra,40(sp)
    8000292e:	f022                	sd	s0,32(sp)
    80002930:	ec26                	sd	s1,24(sp)
    80002932:	e84a                	sd	s2,16(sp)
    80002934:	e44e                	sd	s3,8(sp)
    80002936:	e052                	sd	s4,0(sp)
    80002938:	1800                	addi	s0,sp,48
    8000293a:	84aa                	mv	s1,a0
    8000293c:	892e                	mv	s2,a1
    8000293e:	89b2                	mv	s3,a2
    80002940:	8a36                	mv	s4,a3
    struct proc *p = myproc();
    80002942:	fffff097          	auipc	ra,0xfffff
    80002946:	086080e7          	jalr	134(ra) # 800019c8 <myproc>
    if (user_dst) {
    8000294a:	c08d                	beqz	s1,8000296c <either_copyout+0x42>
        return copyout(p->pagetable, dst, src, len);
    8000294c:	86d2                	mv	a3,s4
    8000294e:	864e                	mv	a2,s3
    80002950:	85ca                	mv	a1,s2
    80002952:	7928                	ld	a0,112(a0)
    80002954:	fffff097          	auipc	ra,0xfffff
    80002958:	d26080e7          	jalr	-730(ra) # 8000167a <copyout>
    } else {
        memmove((char *) dst, src, len);
        return 0;
    }
}
    8000295c:	70a2                	ld	ra,40(sp)
    8000295e:	7402                	ld	s0,32(sp)
    80002960:	64e2                	ld	s1,24(sp)
    80002962:	6942                	ld	s2,16(sp)
    80002964:	69a2                	ld	s3,8(sp)
    80002966:	6a02                	ld	s4,0(sp)
    80002968:	6145                	addi	sp,sp,48
    8000296a:	8082                	ret
        memmove((char *) dst, src, len);
    8000296c:	000a061b          	sext.w	a2,s4
    80002970:	85ce                	mv	a1,s3
    80002972:	854a                	mv	a0,s2
    80002974:	ffffe097          	auipc	ra,0xffffe
    80002978:	3cc080e7          	jalr	972(ra) # 80000d40 <memmove>
        return 0;
    8000297c:	8526                	mv	a0,s1
    8000297e:	bff9                	j	8000295c <either_copyout+0x32>

0000000080002980 <either_copyin>:

// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len) {
    80002980:	7179                	addi	sp,sp,-48
    80002982:	f406                	sd	ra,40(sp)
    80002984:	f022                	sd	s0,32(sp)
    80002986:	ec26                	sd	s1,24(sp)
    80002988:	e84a                	sd	s2,16(sp)
    8000298a:	e44e                	sd	s3,8(sp)
    8000298c:	e052                	sd	s4,0(sp)
    8000298e:	1800                	addi	s0,sp,48
    80002990:	892a                	mv	s2,a0
    80002992:	84ae                	mv	s1,a1
    80002994:	89b2                	mv	s3,a2
    80002996:	8a36                	mv	s4,a3
    struct proc *p = myproc();
    80002998:	fffff097          	auipc	ra,0xfffff
    8000299c:	030080e7          	jalr	48(ra) # 800019c8 <myproc>
    if (user_src) {
    800029a0:	c08d                	beqz	s1,800029c2 <either_copyin+0x42>
        return copyin(p->pagetable, dst, src, len);
    800029a2:	86d2                	mv	a3,s4
    800029a4:	864e                	mv	a2,s3
    800029a6:	85ca                	mv	a1,s2
    800029a8:	7928                	ld	a0,112(a0)
    800029aa:	fffff097          	auipc	ra,0xfffff
    800029ae:	d5c080e7          	jalr	-676(ra) # 80001706 <copyin>
    } else {
        memmove(dst, (char *) src, len);
        return 0;
    }
}
    800029b2:	70a2                	ld	ra,40(sp)
    800029b4:	7402                	ld	s0,32(sp)
    800029b6:	64e2                	ld	s1,24(sp)
    800029b8:	6942                	ld	s2,16(sp)
    800029ba:	69a2                	ld	s3,8(sp)
    800029bc:	6a02                	ld	s4,0(sp)
    800029be:	6145                	addi	sp,sp,48
    800029c0:	8082                	ret
        memmove(dst, (char *) src, len);
    800029c2:	000a061b          	sext.w	a2,s4
    800029c6:	85ce                	mv	a1,s3
    800029c8:	854a                	mv	a0,s2
    800029ca:	ffffe097          	auipc	ra,0xffffe
    800029ce:	376080e7          	jalr	886(ra) # 80000d40 <memmove>
        return 0;
    800029d2:	8526                	mv	a0,s1
    800029d4:	bff9                	j	800029b2 <either_copyin+0x32>

00000000800029d6 <procdump>:

// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void) {
    800029d6:	715d                	addi	sp,sp,-80
    800029d8:	e486                	sd	ra,72(sp)
    800029da:	e0a2                	sd	s0,64(sp)
    800029dc:	fc26                	sd	s1,56(sp)
    800029de:	f84a                	sd	s2,48(sp)
    800029e0:	f44e                	sd	s3,40(sp)
    800029e2:	f052                	sd	s4,32(sp)
    800029e4:	ec56                	sd	s5,24(sp)
    800029e6:	e85a                	sd	s6,16(sp)
    800029e8:	e45e                	sd	s7,8(sp)
    800029ea:	0880                	addi	s0,sp,80
            [ZOMBIE]    "zombie"
    };
    struct proc *p;
    char *state;

    printf("\n");
    800029ec:	00006517          	auipc	a0,0x6
    800029f0:	93c50513          	addi	a0,a0,-1732 # 80008328 <digits+0x2e8>
    800029f4:	ffffe097          	auipc	ra,0xffffe
    800029f8:	b94080e7          	jalr	-1132(ra) # 80000588 <printf>
    for (p = proc; p < &proc[NPROC]; p++) {
    800029fc:	0000f497          	auipc	s1,0xf
    80002a00:	e6c48493          	addi	s1,s1,-404 # 80011868 <proc+0x178>
    80002a04:	00015917          	auipc	s2,0x15
    80002a08:	06490913          	addi	s2,s2,100 # 80017a68 <bcache+0x160>
        if (p->state == UNUSED)
            continue;
        if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002a0c:	4b15                	li	s6,5
            state = states[p->state];
        else
            state = "???";
    80002a0e:	00006997          	auipc	s3,0x6
    80002a12:	92298993          	addi	s3,s3,-1758 # 80008330 <digits+0x2f0>
        printf("%d %s %s", p->pid, state, p->name);
    80002a16:	00006a97          	auipc	s5,0x6
    80002a1a:	922a8a93          	addi	s5,s5,-1758 # 80008338 <digits+0x2f8>
        printf("\n");
    80002a1e:	00006a17          	auipc	s4,0x6
    80002a22:	90aa0a13          	addi	s4,s4,-1782 # 80008328 <digits+0x2e8>
        if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002a26:	00006b97          	auipc	s7,0x6
    80002a2a:	94ab8b93          	addi	s7,s7,-1718 # 80008370 <states.1768>
    80002a2e:	a00d                	j	80002a50 <procdump+0x7a>
        printf("%d %s %s", p->pid, state, p->name);
    80002a30:	eb86a583          	lw	a1,-328(a3)
    80002a34:	8556                	mv	a0,s5
    80002a36:	ffffe097          	auipc	ra,0xffffe
    80002a3a:	b52080e7          	jalr	-1198(ra) # 80000588 <printf>
        printf("\n");
    80002a3e:	8552                	mv	a0,s4
    80002a40:	ffffe097          	auipc	ra,0xffffe
    80002a44:	b48080e7          	jalr	-1208(ra) # 80000588 <printf>
    for (p = proc; p < &proc[NPROC]; p++) {
    80002a48:	18848493          	addi	s1,s1,392
    80002a4c:	03248163          	beq	s1,s2,80002a6e <procdump+0x98>
        if (p->state == UNUSED)
    80002a50:	86a6                	mv	a3,s1
    80002a52:	ea04a783          	lw	a5,-352(s1)
    80002a56:	dbed                	beqz	a5,80002a48 <procdump+0x72>
            state = "???";
    80002a58:	864e                	mv	a2,s3
        if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002a5a:	fcfb6be3          	bltu	s6,a5,80002a30 <procdump+0x5a>
    80002a5e:	1782                	slli	a5,a5,0x20
    80002a60:	9381                	srli	a5,a5,0x20
    80002a62:	078e                	slli	a5,a5,0x3
    80002a64:	97de                	add	a5,a5,s7
    80002a66:	6390                	ld	a2,0(a5)
    80002a68:	f661                	bnez	a2,80002a30 <procdump+0x5a>
            state = "???";
    80002a6a:	864e                	mv	a2,s3
    80002a6c:	b7d1                	j	80002a30 <procdump+0x5a>
    }
    80002a6e:	60a6                	ld	ra,72(sp)
    80002a70:	6406                	ld	s0,64(sp)
    80002a72:	74e2                	ld	s1,56(sp)
    80002a74:	7942                	ld	s2,48(sp)
    80002a76:	79a2                	ld	s3,40(sp)
    80002a78:	7a02                	ld	s4,32(sp)
    80002a7a:	6ae2                	ld	s5,24(sp)
    80002a7c:	6b42                	ld	s6,16(sp)
    80002a7e:	6ba2                	ld	s7,8(sp)
    80002a80:	6161                	addi	sp,sp,80
    80002a82:	8082                	ret

0000000080002a84 <swtch>:
    80002a84:	00153023          	sd	ra,0(a0)
    80002a88:	00253423          	sd	sp,8(a0)
    80002a8c:	e900                	sd	s0,16(a0)
    80002a8e:	ed04                	sd	s1,24(a0)
    80002a90:	03253023          	sd	s2,32(a0)
    80002a94:	03353423          	sd	s3,40(a0)
    80002a98:	03453823          	sd	s4,48(a0)
    80002a9c:	03553c23          	sd	s5,56(a0)
    80002aa0:	05653023          	sd	s6,64(a0)
    80002aa4:	05753423          	sd	s7,72(a0)
    80002aa8:	05853823          	sd	s8,80(a0)
    80002aac:	05953c23          	sd	s9,88(a0)
    80002ab0:	07a53023          	sd	s10,96(a0)
    80002ab4:	07b53423          	sd	s11,104(a0)
    80002ab8:	0005b083          	ld	ra,0(a1)
    80002abc:	0085b103          	ld	sp,8(a1)
    80002ac0:	6980                	ld	s0,16(a1)
    80002ac2:	6d84                	ld	s1,24(a1)
    80002ac4:	0205b903          	ld	s2,32(a1)
    80002ac8:	0285b983          	ld	s3,40(a1)
    80002acc:	0305ba03          	ld	s4,48(a1)
    80002ad0:	0385ba83          	ld	s5,56(a1)
    80002ad4:	0405bb03          	ld	s6,64(a1)
    80002ad8:	0485bb83          	ld	s7,72(a1)
    80002adc:	0505bc03          	ld	s8,80(a1)
    80002ae0:	0585bc83          	ld	s9,88(a1)
    80002ae4:	0605bd03          	ld	s10,96(a1)
    80002ae8:	0685bd83          	ld	s11,104(a1)
    80002aec:	8082                	ret

0000000080002aee <trapinit>:

extern int devintr();

void
trapinit(void)
{
    80002aee:	1141                	addi	sp,sp,-16
    80002af0:	e406                	sd	ra,8(sp)
    80002af2:	e022                	sd	s0,0(sp)
    80002af4:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002af6:	00006597          	auipc	a1,0x6
    80002afa:	8aa58593          	addi	a1,a1,-1878 # 800083a0 <states.1768+0x30>
    80002afe:	00015517          	auipc	a0,0x15
    80002b02:	df250513          	addi	a0,a0,-526 # 800178f0 <tickslock>
    80002b06:	ffffe097          	auipc	ra,0xffffe
    80002b0a:	04e080e7          	jalr	78(ra) # 80000b54 <initlock>
}
    80002b0e:	60a2                	ld	ra,8(sp)
    80002b10:	6402                	ld	s0,0(sp)
    80002b12:	0141                	addi	sp,sp,16
    80002b14:	8082                	ret

0000000080002b16 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    80002b16:	1141                	addi	sp,sp,-16
    80002b18:	e422                	sd	s0,8(sp)
    80002b1a:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002b1c:	00003797          	auipc	a5,0x3
    80002b20:	4f478793          	addi	a5,a5,1268 # 80006010 <kernelvec>
    80002b24:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002b28:	6422                	ld	s0,8(sp)
    80002b2a:	0141                	addi	sp,sp,16
    80002b2c:	8082                	ret

0000000080002b2e <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002b2e:	1141                	addi	sp,sp,-16
    80002b30:	e406                	sd	ra,8(sp)
    80002b32:	e022                	sd	s0,0(sp)
    80002b34:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002b36:	fffff097          	auipc	ra,0xfffff
    80002b3a:	e92080e7          	jalr	-366(ra) # 800019c8 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002b3e:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002b42:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002b44:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    80002b48:	00004617          	auipc	a2,0x4
    80002b4c:	4b860613          	addi	a2,a2,1208 # 80007000 <_trampoline>
    80002b50:	00004697          	auipc	a3,0x4
    80002b54:	4b068693          	addi	a3,a3,1200 # 80007000 <_trampoline>
    80002b58:	8e91                	sub	a3,a3,a2
    80002b5a:	040007b7          	lui	a5,0x4000
    80002b5e:	17fd                	addi	a5,a5,-1
    80002b60:	07b2                	slli	a5,a5,0xc
    80002b62:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002b64:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002b68:	7d38                	ld	a4,120(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002b6a:	180026f3          	csrr	a3,satp
    80002b6e:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002b70:	7d38                	ld	a4,120(a0)
    80002b72:	7134                	ld	a3,96(a0)
    80002b74:	6585                	lui	a1,0x1
    80002b76:	96ae                	add	a3,a3,a1
    80002b78:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002b7a:	7d38                	ld	a4,120(a0)
    80002b7c:	00000697          	auipc	a3,0x0
    80002b80:	13868693          	addi	a3,a3,312 # 80002cb4 <usertrap>
    80002b84:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80002b86:	7d38                	ld	a4,120(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002b88:	8692                	mv	a3,tp
    80002b8a:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002b8c:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002b90:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002b94:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002b98:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002b9c:	7d38                	ld	a4,120(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002b9e:	6f18                	ld	a4,24(a4)
    80002ba0:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002ba4:	792c                	ld	a1,112(a0)
    80002ba6:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    80002ba8:	00004717          	auipc	a4,0x4
    80002bac:	4e870713          	addi	a4,a4,1256 # 80007090 <userret>
    80002bb0:	8f11                	sub	a4,a4,a2
    80002bb2:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    80002bb4:	577d                	li	a4,-1
    80002bb6:	177e                	slli	a4,a4,0x3f
    80002bb8:	8dd9                	or	a1,a1,a4
    80002bba:	02000537          	lui	a0,0x2000
    80002bbe:	157d                	addi	a0,a0,-1
    80002bc0:	0536                	slli	a0,a0,0xd
    80002bc2:	9782                	jalr	a5
}
    80002bc4:	60a2                	ld	ra,8(sp)
    80002bc6:	6402                	ld	s0,0(sp)
    80002bc8:	0141                	addi	sp,sp,16
    80002bca:	8082                	ret

0000000080002bcc <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80002bcc:	1101                	addi	sp,sp,-32
    80002bce:	ec06                	sd	ra,24(sp)
    80002bd0:	e822                	sd	s0,16(sp)
    80002bd2:	e426                	sd	s1,8(sp)
    80002bd4:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002bd6:	00015497          	auipc	s1,0x15
    80002bda:	d1a48493          	addi	s1,s1,-742 # 800178f0 <tickslock>
    80002bde:	8526                	mv	a0,s1
    80002be0:	ffffe097          	auipc	ra,0xffffe
    80002be4:	004080e7          	jalr	4(ra) # 80000be4 <acquire>
  ticks++;
    80002be8:	00006517          	auipc	a0,0x6
    80002bec:	46850513          	addi	a0,a0,1128 # 80009050 <ticks>
    80002bf0:	411c                	lw	a5,0(a0)
    80002bf2:	2785                	addiw	a5,a5,1
    80002bf4:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80002bf6:	00000097          	auipc	ra,0x0
    80002bfa:	924080e7          	jalr	-1756(ra) # 8000251a <wakeup>
  release(&tickslock);
    80002bfe:	8526                	mv	a0,s1
    80002c00:	ffffe097          	auipc	ra,0xffffe
    80002c04:	098080e7          	jalr	152(ra) # 80000c98 <release>
}
    80002c08:	60e2                	ld	ra,24(sp)
    80002c0a:	6442                	ld	s0,16(sp)
    80002c0c:	64a2                	ld	s1,8(sp)
    80002c0e:	6105                	addi	sp,sp,32
    80002c10:	8082                	ret

0000000080002c12 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80002c12:	1101                	addi	sp,sp,-32
    80002c14:	ec06                	sd	ra,24(sp)
    80002c16:	e822                	sd	s0,16(sp)
    80002c18:	e426                	sd	s1,8(sp)
    80002c1a:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002c1c:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80002c20:	00074d63          	bltz	a4,80002c3a <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80002c24:	57fd                	li	a5,-1
    80002c26:	17fe                	slli	a5,a5,0x3f
    80002c28:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002c2a:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002c2c:	06f70363          	beq	a4,a5,80002c92 <devintr+0x80>
  }
}
    80002c30:	60e2                	ld	ra,24(sp)
    80002c32:	6442                	ld	s0,16(sp)
    80002c34:	64a2                	ld	s1,8(sp)
    80002c36:	6105                	addi	sp,sp,32
    80002c38:	8082                	ret
     (scause & 0xff) == 9){
    80002c3a:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    80002c3e:	46a5                	li	a3,9
    80002c40:	fed792e3          	bne	a5,a3,80002c24 <devintr+0x12>
    int irq = plic_claim();
    80002c44:	00003097          	auipc	ra,0x3
    80002c48:	4d4080e7          	jalr	1236(ra) # 80006118 <plic_claim>
    80002c4c:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002c4e:	47a9                	li	a5,10
    80002c50:	02f50763          	beq	a0,a5,80002c7e <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80002c54:	4785                	li	a5,1
    80002c56:	02f50963          	beq	a0,a5,80002c88 <devintr+0x76>
    return 1;
    80002c5a:	4505                	li	a0,1
    } else if(irq){
    80002c5c:	d8f1                	beqz	s1,80002c30 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002c5e:	85a6                	mv	a1,s1
    80002c60:	00005517          	auipc	a0,0x5
    80002c64:	74850513          	addi	a0,a0,1864 # 800083a8 <states.1768+0x38>
    80002c68:	ffffe097          	auipc	ra,0xffffe
    80002c6c:	920080e7          	jalr	-1760(ra) # 80000588 <printf>
      plic_complete(irq);
    80002c70:	8526                	mv	a0,s1
    80002c72:	00003097          	auipc	ra,0x3
    80002c76:	4ca080e7          	jalr	1226(ra) # 8000613c <plic_complete>
    return 1;
    80002c7a:	4505                	li	a0,1
    80002c7c:	bf55                	j	80002c30 <devintr+0x1e>
      uartintr();
    80002c7e:	ffffe097          	auipc	ra,0xffffe
    80002c82:	d2a080e7          	jalr	-726(ra) # 800009a8 <uartintr>
    80002c86:	b7ed                	j	80002c70 <devintr+0x5e>
      virtio_disk_intr();
    80002c88:	00004097          	auipc	ra,0x4
    80002c8c:	994080e7          	jalr	-1644(ra) # 8000661c <virtio_disk_intr>
    80002c90:	b7c5                	j	80002c70 <devintr+0x5e>
    if(cpuid() == 0){
    80002c92:	fffff097          	auipc	ra,0xfffff
    80002c96:	d0a080e7          	jalr	-758(ra) # 8000199c <cpuid>
    80002c9a:	c901                	beqz	a0,80002caa <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002c9c:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002ca0:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002ca2:	14479073          	csrw	sip,a5
    return 2;
    80002ca6:	4509                	li	a0,2
    80002ca8:	b761                	j	80002c30 <devintr+0x1e>
      clockintr();
    80002caa:	00000097          	auipc	ra,0x0
    80002cae:	f22080e7          	jalr	-222(ra) # 80002bcc <clockintr>
    80002cb2:	b7ed                	j	80002c9c <devintr+0x8a>

0000000080002cb4 <usertrap>:
{
    80002cb4:	1101                	addi	sp,sp,-32
    80002cb6:	ec06                	sd	ra,24(sp)
    80002cb8:	e822                	sd	s0,16(sp)
    80002cba:	e426                	sd	s1,8(sp)
    80002cbc:	e04a                	sd	s2,0(sp)
    80002cbe:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002cc0:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002cc4:	1007f793          	andi	a5,a5,256
    80002cc8:	e3ad                	bnez	a5,80002d2a <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002cca:	00003797          	auipc	a5,0x3
    80002cce:	34678793          	addi	a5,a5,838 # 80006010 <kernelvec>
    80002cd2:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002cd6:	fffff097          	auipc	ra,0xfffff
    80002cda:	cf2080e7          	jalr	-782(ra) # 800019c8 <myproc>
    80002cde:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002ce0:	7d3c                	ld	a5,120(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002ce2:	14102773          	csrr	a4,sepc
    80002ce6:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002ce8:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002cec:	47a1                	li	a5,8
    80002cee:	04f71c63          	bne	a4,a5,80002d46 <usertrap+0x92>
    if(p->killed)
    80002cf2:	551c                	lw	a5,40(a0)
    80002cf4:	e3b9                	bnez	a5,80002d3a <usertrap+0x86>
    p->trapframe->epc += 4;
    80002cf6:	7cb8                	ld	a4,120(s1)
    80002cf8:	6f1c                	ld	a5,24(a4)
    80002cfa:	0791                	addi	a5,a5,4
    80002cfc:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002cfe:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002d02:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002d06:	10079073          	csrw	sstatus,a5
    syscall();
    80002d0a:	00000097          	auipc	ra,0x0
    80002d0e:	2e0080e7          	jalr	736(ra) # 80002fea <syscall>
  if(p->killed)
    80002d12:	549c                	lw	a5,40(s1)
    80002d14:	ebc1                	bnez	a5,80002da4 <usertrap+0xf0>
  usertrapret();
    80002d16:	00000097          	auipc	ra,0x0
    80002d1a:	e18080e7          	jalr	-488(ra) # 80002b2e <usertrapret>
}
    80002d1e:	60e2                	ld	ra,24(sp)
    80002d20:	6442                	ld	s0,16(sp)
    80002d22:	64a2                	ld	s1,8(sp)
    80002d24:	6902                	ld	s2,0(sp)
    80002d26:	6105                	addi	sp,sp,32
    80002d28:	8082                	ret
    panic("usertrap: not from user mode");
    80002d2a:	00005517          	auipc	a0,0x5
    80002d2e:	69e50513          	addi	a0,a0,1694 # 800083c8 <states.1768+0x58>
    80002d32:	ffffe097          	auipc	ra,0xffffe
    80002d36:	80c080e7          	jalr	-2036(ra) # 8000053e <panic>
      exit(-1);
    80002d3a:	557d                	li	a0,-1
    80002d3c:	00000097          	auipc	ra,0x0
    80002d40:	8ce080e7          	jalr	-1842(ra) # 8000260a <exit>
    80002d44:	bf4d                	j	80002cf6 <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    80002d46:	00000097          	auipc	ra,0x0
    80002d4a:	ecc080e7          	jalr	-308(ra) # 80002c12 <devintr>
    80002d4e:	892a                	mv	s2,a0
    80002d50:	c501                	beqz	a0,80002d58 <usertrap+0xa4>
  if(p->killed)
    80002d52:	549c                	lw	a5,40(s1)
    80002d54:	c3a1                	beqz	a5,80002d94 <usertrap+0xe0>
    80002d56:	a815                	j	80002d8a <usertrap+0xd6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002d58:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002d5c:	5890                	lw	a2,48(s1)
    80002d5e:	00005517          	auipc	a0,0x5
    80002d62:	68a50513          	addi	a0,a0,1674 # 800083e8 <states.1768+0x78>
    80002d66:	ffffe097          	auipc	ra,0xffffe
    80002d6a:	822080e7          	jalr	-2014(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002d6e:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002d72:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002d76:	00005517          	auipc	a0,0x5
    80002d7a:	6a250513          	addi	a0,a0,1698 # 80008418 <states.1768+0xa8>
    80002d7e:	ffffe097          	auipc	ra,0xffffe
    80002d82:	80a080e7          	jalr	-2038(ra) # 80000588 <printf>
    p->killed = 1;
    80002d86:	4785                	li	a5,1
    80002d88:	d49c                	sw	a5,40(s1)
    exit(-1);
    80002d8a:	557d                	li	a0,-1
    80002d8c:	00000097          	auipc	ra,0x0
    80002d90:	87e080e7          	jalr	-1922(ra) # 8000260a <exit>
  if(which_dev == 2)
    80002d94:	4789                	li	a5,2
    80002d96:	f8f910e3          	bne	s2,a5,80002d16 <usertrap+0x62>
    yield();
    80002d9a:	fffff097          	auipc	ra,0xfffff
    80002d9e:	58c080e7          	jalr	1420(ra) # 80002326 <yield>
    80002da2:	bf95                	j	80002d16 <usertrap+0x62>
  int which_dev = 0;
    80002da4:	4901                	li	s2,0
    80002da6:	b7d5                	j	80002d8a <usertrap+0xd6>

0000000080002da8 <kerneltrap>:
{
    80002da8:	7179                	addi	sp,sp,-48
    80002daa:	f406                	sd	ra,40(sp)
    80002dac:	f022                	sd	s0,32(sp)
    80002dae:	ec26                	sd	s1,24(sp)
    80002db0:	e84a                	sd	s2,16(sp)
    80002db2:	e44e                	sd	s3,8(sp)
    80002db4:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002db6:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002dba:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002dbe:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002dc2:	1004f793          	andi	a5,s1,256
    80002dc6:	cb85                	beqz	a5,80002df6 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002dc8:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002dcc:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002dce:	ef85                	bnez	a5,80002e06 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002dd0:	00000097          	auipc	ra,0x0
    80002dd4:	e42080e7          	jalr	-446(ra) # 80002c12 <devintr>
    80002dd8:	cd1d                	beqz	a0,80002e16 <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002dda:	4789                	li	a5,2
    80002ddc:	06f50a63          	beq	a0,a5,80002e50 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002de0:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002de4:	10049073          	csrw	sstatus,s1
}
    80002de8:	70a2                	ld	ra,40(sp)
    80002dea:	7402                	ld	s0,32(sp)
    80002dec:	64e2                	ld	s1,24(sp)
    80002dee:	6942                	ld	s2,16(sp)
    80002df0:	69a2                	ld	s3,8(sp)
    80002df2:	6145                	addi	sp,sp,48
    80002df4:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002df6:	00005517          	auipc	a0,0x5
    80002dfa:	64250513          	addi	a0,a0,1602 # 80008438 <states.1768+0xc8>
    80002dfe:	ffffd097          	auipc	ra,0xffffd
    80002e02:	740080e7          	jalr	1856(ra) # 8000053e <panic>
    panic("kerneltrap: interrupts enabled");
    80002e06:	00005517          	auipc	a0,0x5
    80002e0a:	65a50513          	addi	a0,a0,1626 # 80008460 <states.1768+0xf0>
    80002e0e:	ffffd097          	auipc	ra,0xffffd
    80002e12:	730080e7          	jalr	1840(ra) # 8000053e <panic>
    printf("scause %p\n", scause);
    80002e16:	85ce                	mv	a1,s3
    80002e18:	00005517          	auipc	a0,0x5
    80002e1c:	66850513          	addi	a0,a0,1640 # 80008480 <states.1768+0x110>
    80002e20:	ffffd097          	auipc	ra,0xffffd
    80002e24:	768080e7          	jalr	1896(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002e28:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002e2c:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002e30:	00005517          	auipc	a0,0x5
    80002e34:	66050513          	addi	a0,a0,1632 # 80008490 <states.1768+0x120>
    80002e38:	ffffd097          	auipc	ra,0xffffd
    80002e3c:	750080e7          	jalr	1872(ra) # 80000588 <printf>
    panic("kerneltrap");
    80002e40:	00005517          	auipc	a0,0x5
    80002e44:	66850513          	addi	a0,a0,1640 # 800084a8 <states.1768+0x138>
    80002e48:	ffffd097          	auipc	ra,0xffffd
    80002e4c:	6f6080e7          	jalr	1782(ra) # 8000053e <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002e50:	fffff097          	auipc	ra,0xfffff
    80002e54:	b78080e7          	jalr	-1160(ra) # 800019c8 <myproc>
    80002e58:	d541                	beqz	a0,80002de0 <kerneltrap+0x38>
    80002e5a:	fffff097          	auipc	ra,0xfffff
    80002e5e:	b6e080e7          	jalr	-1170(ra) # 800019c8 <myproc>
    80002e62:	4d18                	lw	a4,24(a0)
    80002e64:	4791                	li	a5,4
    80002e66:	f6f71de3          	bne	a4,a5,80002de0 <kerneltrap+0x38>
    yield();
    80002e6a:	fffff097          	auipc	ra,0xfffff
    80002e6e:	4bc080e7          	jalr	1212(ra) # 80002326 <yield>
    80002e72:	b7bd                	j	80002de0 <kerneltrap+0x38>

0000000080002e74 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002e74:	1101                	addi	sp,sp,-32
    80002e76:	ec06                	sd	ra,24(sp)
    80002e78:	e822                	sd	s0,16(sp)
    80002e7a:	e426                	sd	s1,8(sp)
    80002e7c:	1000                	addi	s0,sp,32
    80002e7e:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002e80:	fffff097          	auipc	ra,0xfffff
    80002e84:	b48080e7          	jalr	-1208(ra) # 800019c8 <myproc>
  switch (n) {
    80002e88:	4795                	li	a5,5
    80002e8a:	0497e163          	bltu	a5,s1,80002ecc <argraw+0x58>
    80002e8e:	048a                	slli	s1,s1,0x2
    80002e90:	00005717          	auipc	a4,0x5
    80002e94:	65070713          	addi	a4,a4,1616 # 800084e0 <states.1768+0x170>
    80002e98:	94ba                	add	s1,s1,a4
    80002e9a:	409c                	lw	a5,0(s1)
    80002e9c:	97ba                	add	a5,a5,a4
    80002e9e:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002ea0:	7d3c                	ld	a5,120(a0)
    80002ea2:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002ea4:	60e2                	ld	ra,24(sp)
    80002ea6:	6442                	ld	s0,16(sp)
    80002ea8:	64a2                	ld	s1,8(sp)
    80002eaa:	6105                	addi	sp,sp,32
    80002eac:	8082                	ret
    return p->trapframe->a1;
    80002eae:	7d3c                	ld	a5,120(a0)
    80002eb0:	7fa8                	ld	a0,120(a5)
    80002eb2:	bfcd                	j	80002ea4 <argraw+0x30>
    return p->trapframe->a2;
    80002eb4:	7d3c                	ld	a5,120(a0)
    80002eb6:	63c8                	ld	a0,128(a5)
    80002eb8:	b7f5                	j	80002ea4 <argraw+0x30>
    return p->trapframe->a3;
    80002eba:	7d3c                	ld	a5,120(a0)
    80002ebc:	67c8                	ld	a0,136(a5)
    80002ebe:	b7dd                	j	80002ea4 <argraw+0x30>
    return p->trapframe->a4;
    80002ec0:	7d3c                	ld	a5,120(a0)
    80002ec2:	6bc8                	ld	a0,144(a5)
    80002ec4:	b7c5                	j	80002ea4 <argraw+0x30>
    return p->trapframe->a5;
    80002ec6:	7d3c                	ld	a5,120(a0)
    80002ec8:	6fc8                	ld	a0,152(a5)
    80002eca:	bfe9                	j	80002ea4 <argraw+0x30>
  panic("argraw");
    80002ecc:	00005517          	auipc	a0,0x5
    80002ed0:	5ec50513          	addi	a0,a0,1516 # 800084b8 <states.1768+0x148>
    80002ed4:	ffffd097          	auipc	ra,0xffffd
    80002ed8:	66a080e7          	jalr	1642(ra) # 8000053e <panic>

0000000080002edc <fetchaddr>:
{
    80002edc:	1101                	addi	sp,sp,-32
    80002ede:	ec06                	sd	ra,24(sp)
    80002ee0:	e822                	sd	s0,16(sp)
    80002ee2:	e426                	sd	s1,8(sp)
    80002ee4:	e04a                	sd	s2,0(sp)
    80002ee6:	1000                	addi	s0,sp,32
    80002ee8:	84aa                	mv	s1,a0
    80002eea:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002eec:	fffff097          	auipc	ra,0xfffff
    80002ef0:	adc080e7          	jalr	-1316(ra) # 800019c8 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    80002ef4:	753c                	ld	a5,104(a0)
    80002ef6:	02f4f863          	bgeu	s1,a5,80002f26 <fetchaddr+0x4a>
    80002efa:	00848713          	addi	a4,s1,8
    80002efe:	02e7e663          	bltu	a5,a4,80002f2a <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002f02:	46a1                	li	a3,8
    80002f04:	8626                	mv	a2,s1
    80002f06:	85ca                	mv	a1,s2
    80002f08:	7928                	ld	a0,112(a0)
    80002f0a:	ffffe097          	auipc	ra,0xffffe
    80002f0e:	7fc080e7          	jalr	2044(ra) # 80001706 <copyin>
    80002f12:	00a03533          	snez	a0,a0
    80002f16:	40a00533          	neg	a0,a0
}
    80002f1a:	60e2                	ld	ra,24(sp)
    80002f1c:	6442                	ld	s0,16(sp)
    80002f1e:	64a2                	ld	s1,8(sp)
    80002f20:	6902                	ld	s2,0(sp)
    80002f22:	6105                	addi	sp,sp,32
    80002f24:	8082                	ret
    return -1;
    80002f26:	557d                	li	a0,-1
    80002f28:	bfcd                	j	80002f1a <fetchaddr+0x3e>
    80002f2a:	557d                	li	a0,-1
    80002f2c:	b7fd                	j	80002f1a <fetchaddr+0x3e>

0000000080002f2e <fetchstr>:
{
    80002f2e:	7179                	addi	sp,sp,-48
    80002f30:	f406                	sd	ra,40(sp)
    80002f32:	f022                	sd	s0,32(sp)
    80002f34:	ec26                	sd	s1,24(sp)
    80002f36:	e84a                	sd	s2,16(sp)
    80002f38:	e44e                	sd	s3,8(sp)
    80002f3a:	1800                	addi	s0,sp,48
    80002f3c:	892a                	mv	s2,a0
    80002f3e:	84ae                	mv	s1,a1
    80002f40:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002f42:	fffff097          	auipc	ra,0xfffff
    80002f46:	a86080e7          	jalr	-1402(ra) # 800019c8 <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80002f4a:	86ce                	mv	a3,s3
    80002f4c:	864a                	mv	a2,s2
    80002f4e:	85a6                	mv	a1,s1
    80002f50:	7928                	ld	a0,112(a0)
    80002f52:	fffff097          	auipc	ra,0xfffff
    80002f56:	840080e7          	jalr	-1984(ra) # 80001792 <copyinstr>
  if(err < 0)
    80002f5a:	00054763          	bltz	a0,80002f68 <fetchstr+0x3a>
  return strlen(buf);
    80002f5e:	8526                	mv	a0,s1
    80002f60:	ffffe097          	auipc	ra,0xffffe
    80002f64:	f04080e7          	jalr	-252(ra) # 80000e64 <strlen>
}
    80002f68:	70a2                	ld	ra,40(sp)
    80002f6a:	7402                	ld	s0,32(sp)
    80002f6c:	64e2                	ld	s1,24(sp)
    80002f6e:	6942                	ld	s2,16(sp)
    80002f70:	69a2                	ld	s3,8(sp)
    80002f72:	6145                	addi	sp,sp,48
    80002f74:	8082                	ret

0000000080002f76 <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80002f76:	1101                	addi	sp,sp,-32
    80002f78:	ec06                	sd	ra,24(sp)
    80002f7a:	e822                	sd	s0,16(sp)
    80002f7c:	e426                	sd	s1,8(sp)
    80002f7e:	1000                	addi	s0,sp,32
    80002f80:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002f82:	00000097          	auipc	ra,0x0
    80002f86:	ef2080e7          	jalr	-270(ra) # 80002e74 <argraw>
    80002f8a:	c088                	sw	a0,0(s1)
  return 0;
}
    80002f8c:	4501                	li	a0,0
    80002f8e:	60e2                	ld	ra,24(sp)
    80002f90:	6442                	ld	s0,16(sp)
    80002f92:	64a2                	ld	s1,8(sp)
    80002f94:	6105                	addi	sp,sp,32
    80002f96:	8082                	ret

0000000080002f98 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80002f98:	1101                	addi	sp,sp,-32
    80002f9a:	ec06                	sd	ra,24(sp)
    80002f9c:	e822                	sd	s0,16(sp)
    80002f9e:	e426                	sd	s1,8(sp)
    80002fa0:	1000                	addi	s0,sp,32
    80002fa2:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002fa4:	00000097          	auipc	ra,0x0
    80002fa8:	ed0080e7          	jalr	-304(ra) # 80002e74 <argraw>
    80002fac:	e088                	sd	a0,0(s1)
  return 0;
}
    80002fae:	4501                	li	a0,0
    80002fb0:	60e2                	ld	ra,24(sp)
    80002fb2:	6442                	ld	s0,16(sp)
    80002fb4:	64a2                	ld	s1,8(sp)
    80002fb6:	6105                	addi	sp,sp,32
    80002fb8:	8082                	ret

0000000080002fba <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002fba:	1101                	addi	sp,sp,-32
    80002fbc:	ec06                	sd	ra,24(sp)
    80002fbe:	e822                	sd	s0,16(sp)
    80002fc0:	e426                	sd	s1,8(sp)
    80002fc2:	e04a                	sd	s2,0(sp)
    80002fc4:	1000                	addi	s0,sp,32
    80002fc6:	84ae                	mv	s1,a1
    80002fc8:	8932                	mv	s2,a2
  *ip = argraw(n);
    80002fca:	00000097          	auipc	ra,0x0
    80002fce:	eaa080e7          	jalr	-342(ra) # 80002e74 <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80002fd2:	864a                	mv	a2,s2
    80002fd4:	85a6                	mv	a1,s1
    80002fd6:	00000097          	auipc	ra,0x0
    80002fda:	f58080e7          	jalr	-168(ra) # 80002f2e <fetchstr>
}
    80002fde:	60e2                	ld	ra,24(sp)
    80002fe0:	6442                	ld	s0,16(sp)
    80002fe2:	64a2                	ld	s1,8(sp)
    80002fe4:	6902                	ld	s2,0(sp)
    80002fe6:	6105                	addi	sp,sp,32
    80002fe8:	8082                	ret

0000000080002fea <syscall>:
[SYS_print_stats] sys_print_stats,
};

void
syscall(void)
{
    80002fea:	1101                	addi	sp,sp,-32
    80002fec:	ec06                	sd	ra,24(sp)
    80002fee:	e822                	sd	s0,16(sp)
    80002ff0:	e426                	sd	s1,8(sp)
    80002ff2:	e04a                	sd	s2,0(sp)
    80002ff4:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002ff6:	fffff097          	auipc	ra,0xfffff
    80002ffa:	9d2080e7          	jalr	-1582(ra) # 800019c8 <myproc>
    80002ffe:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80003000:	07853903          	ld	s2,120(a0)
    80003004:	0a893783          	ld	a5,168(s2)
    80003008:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    8000300c:	37fd                	addiw	a5,a5,-1
    8000300e:	475d                	li	a4,23
    80003010:	00f76f63          	bltu	a4,a5,8000302e <syscall+0x44>
    80003014:	00369713          	slli	a4,a3,0x3
    80003018:	00005797          	auipc	a5,0x5
    8000301c:	4e078793          	addi	a5,a5,1248 # 800084f8 <syscalls>
    80003020:	97ba                	add	a5,a5,a4
    80003022:	639c                	ld	a5,0(a5)
    80003024:	c789                	beqz	a5,8000302e <syscall+0x44>
    p->trapframe->a0 = syscalls[num]();
    80003026:	9782                	jalr	a5
    80003028:	06a93823          	sd	a0,112(s2)
    8000302c:	a839                	j	8000304a <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    8000302e:	17848613          	addi	a2,s1,376
    80003032:	588c                	lw	a1,48(s1)
    80003034:	00005517          	auipc	a0,0x5
    80003038:	48c50513          	addi	a0,a0,1164 # 800084c0 <states.1768+0x150>
    8000303c:	ffffd097          	auipc	ra,0xffffd
    80003040:	54c080e7          	jalr	1356(ra) # 80000588 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80003044:	7cbc                	ld	a5,120(s1)
    80003046:	577d                	li	a4,-1
    80003048:	fbb8                	sd	a4,112(a5)
  }
}
    8000304a:	60e2                	ld	ra,24(sp)
    8000304c:	6442                	ld	s0,16(sp)
    8000304e:	64a2                	ld	s1,8(sp)
    80003050:	6902                	ld	s2,0(sp)
    80003052:	6105                	addi	sp,sp,32
    80003054:	8082                	ret

0000000080003056 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80003056:	1101                	addi	sp,sp,-32
    80003058:	ec06                	sd	ra,24(sp)
    8000305a:	e822                	sd	s0,16(sp)
    8000305c:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    8000305e:	fec40593          	addi	a1,s0,-20
    80003062:	4501                	li	a0,0
    80003064:	00000097          	auipc	ra,0x0
    80003068:	f12080e7          	jalr	-238(ra) # 80002f76 <argint>
    return -1;
    8000306c:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    8000306e:	00054963          	bltz	a0,80003080 <sys_exit+0x2a>
  exit(n);
    80003072:	fec42503          	lw	a0,-20(s0)
    80003076:	fffff097          	auipc	ra,0xfffff
    8000307a:	594080e7          	jalr	1428(ra) # 8000260a <exit>
  return 0;  // not reached
    8000307e:	4781                	li	a5,0
}
    80003080:	853e                	mv	a0,a5
    80003082:	60e2                	ld	ra,24(sp)
    80003084:	6442                	ld	s0,16(sp)
    80003086:	6105                	addi	sp,sp,32
    80003088:	8082                	ret

000000008000308a <sys_getpid>:

uint64
sys_getpid(void)
{
    8000308a:	1141                	addi	sp,sp,-16
    8000308c:	e406                	sd	ra,8(sp)
    8000308e:	e022                	sd	s0,0(sp)
    80003090:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80003092:	fffff097          	auipc	ra,0xfffff
    80003096:	936080e7          	jalr	-1738(ra) # 800019c8 <myproc>
}
    8000309a:	5908                	lw	a0,48(a0)
    8000309c:	60a2                	ld	ra,8(sp)
    8000309e:	6402                	ld	s0,0(sp)
    800030a0:	0141                	addi	sp,sp,16
    800030a2:	8082                	ret

00000000800030a4 <sys_fork>:

uint64
sys_fork(void)
{
    800030a4:	1141                	addi	sp,sp,-16
    800030a6:	e406                	sd	ra,8(sp)
    800030a8:	e022                	sd	s0,0(sp)
    800030aa:	0800                	addi	s0,sp,16
  return fork();
    800030ac:	fffff097          	auipc	ra,0xfffff
    800030b0:	d18080e7          	jalr	-744(ra) # 80001dc4 <fork>
}
    800030b4:	60a2                	ld	ra,8(sp)
    800030b6:	6402                	ld	s0,0(sp)
    800030b8:	0141                	addi	sp,sp,16
    800030ba:	8082                	ret

00000000800030bc <sys_wait>:

uint64
sys_wait(void)
{
    800030bc:	1101                	addi	sp,sp,-32
    800030be:	ec06                	sd	ra,24(sp)
    800030c0:	e822                	sd	s0,16(sp)
    800030c2:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    800030c4:	fe840593          	addi	a1,s0,-24
    800030c8:	4501                	li	a0,0
    800030ca:	00000097          	auipc	ra,0x0
    800030ce:	ece080e7          	jalr	-306(ra) # 80002f98 <argaddr>
    800030d2:	87aa                	mv	a5,a0
    return -1;
    800030d4:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    800030d6:	0007c863          	bltz	a5,800030e6 <sys_wait+0x2a>
  return wait(p);
    800030da:	fe843503          	ld	a0,-24(s0)
    800030de:	fffff097          	auipc	ra,0xfffff
    800030e2:	314080e7          	jalr	788(ra) # 800023f2 <wait>
}
    800030e6:	60e2                	ld	ra,24(sp)
    800030e8:	6442                	ld	s0,16(sp)
    800030ea:	6105                	addi	sp,sp,32
    800030ec:	8082                	ret

00000000800030ee <sys_sbrk>:

uint64
sys_sbrk(void)
{
    800030ee:	7179                	addi	sp,sp,-48
    800030f0:	f406                	sd	ra,40(sp)
    800030f2:	f022                	sd	s0,32(sp)
    800030f4:	ec26                	sd	s1,24(sp)
    800030f6:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    800030f8:	fdc40593          	addi	a1,s0,-36
    800030fc:	4501                	li	a0,0
    800030fe:	00000097          	auipc	ra,0x0
    80003102:	e78080e7          	jalr	-392(ra) # 80002f76 <argint>
    80003106:	87aa                	mv	a5,a0
    return -1;
    80003108:	557d                	li	a0,-1
  if(argint(0, &n) < 0)
    8000310a:	0207c063          	bltz	a5,8000312a <sys_sbrk+0x3c>
  addr = myproc()->sz;
    8000310e:	fffff097          	auipc	ra,0xfffff
    80003112:	8ba080e7          	jalr	-1862(ra) # 800019c8 <myproc>
    80003116:	5524                	lw	s1,104(a0)
  if(growproc(n) < 0)
    80003118:	fdc42503          	lw	a0,-36(s0)
    8000311c:	fffff097          	auipc	ra,0xfffff
    80003120:	c34080e7          	jalr	-972(ra) # 80001d50 <growproc>
    80003124:	00054863          	bltz	a0,80003134 <sys_sbrk+0x46>
    return -1;
  return addr;
    80003128:	8526                	mv	a0,s1
}
    8000312a:	70a2                	ld	ra,40(sp)
    8000312c:	7402                	ld	s0,32(sp)
    8000312e:	64e2                	ld	s1,24(sp)
    80003130:	6145                	addi	sp,sp,48
    80003132:	8082                	ret
    return -1;
    80003134:	557d                	li	a0,-1
    80003136:	bfd5                	j	8000312a <sys_sbrk+0x3c>

0000000080003138 <sys_sleep>:

uint64
sys_sleep(void)
{
    80003138:	7139                	addi	sp,sp,-64
    8000313a:	fc06                	sd	ra,56(sp)
    8000313c:	f822                	sd	s0,48(sp)
    8000313e:	f426                	sd	s1,40(sp)
    80003140:	f04a                	sd	s2,32(sp)
    80003142:	ec4e                	sd	s3,24(sp)
    80003144:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    80003146:	fcc40593          	addi	a1,s0,-52
    8000314a:	4501                	li	a0,0
    8000314c:	00000097          	auipc	ra,0x0
    80003150:	e2a080e7          	jalr	-470(ra) # 80002f76 <argint>
    return -1;
    80003154:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80003156:	06054563          	bltz	a0,800031c0 <sys_sleep+0x88>
  acquire(&tickslock);
    8000315a:	00014517          	auipc	a0,0x14
    8000315e:	79650513          	addi	a0,a0,1942 # 800178f0 <tickslock>
    80003162:	ffffe097          	auipc	ra,0xffffe
    80003166:	a82080e7          	jalr	-1406(ra) # 80000be4 <acquire>
  ticks0 = ticks;
    8000316a:	00006917          	auipc	s2,0x6
    8000316e:	ee692903          	lw	s2,-282(s2) # 80009050 <ticks>
  while(ticks - ticks0 < n){
    80003172:	fcc42783          	lw	a5,-52(s0)
    80003176:	cf85                	beqz	a5,800031ae <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80003178:	00014997          	auipc	s3,0x14
    8000317c:	77898993          	addi	s3,s3,1912 # 800178f0 <tickslock>
    80003180:	00006497          	auipc	s1,0x6
    80003184:	ed048493          	addi	s1,s1,-304 # 80009050 <ticks>
    if(myproc()->killed){
    80003188:	fffff097          	auipc	ra,0xfffff
    8000318c:	840080e7          	jalr	-1984(ra) # 800019c8 <myproc>
    80003190:	551c                	lw	a5,40(a0)
    80003192:	ef9d                	bnez	a5,800031d0 <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    80003194:	85ce                	mv	a1,s3
    80003196:	8526                	mv	a0,s1
    80003198:	fffff097          	auipc	ra,0xfffff
    8000319c:	1e2080e7          	jalr	482(ra) # 8000237a <sleep>
  while(ticks - ticks0 < n){
    800031a0:	409c                	lw	a5,0(s1)
    800031a2:	412787bb          	subw	a5,a5,s2
    800031a6:	fcc42703          	lw	a4,-52(s0)
    800031aa:	fce7efe3          	bltu	a5,a4,80003188 <sys_sleep+0x50>
  }
  release(&tickslock);
    800031ae:	00014517          	auipc	a0,0x14
    800031b2:	74250513          	addi	a0,a0,1858 # 800178f0 <tickslock>
    800031b6:	ffffe097          	auipc	ra,0xffffe
    800031ba:	ae2080e7          	jalr	-1310(ra) # 80000c98 <release>
  return 0;
    800031be:	4781                	li	a5,0
}
    800031c0:	853e                	mv	a0,a5
    800031c2:	70e2                	ld	ra,56(sp)
    800031c4:	7442                	ld	s0,48(sp)
    800031c6:	74a2                	ld	s1,40(sp)
    800031c8:	7902                	ld	s2,32(sp)
    800031ca:	69e2                	ld	s3,24(sp)
    800031cc:	6121                	addi	sp,sp,64
    800031ce:	8082                	ret
      release(&tickslock);
    800031d0:	00014517          	auipc	a0,0x14
    800031d4:	72050513          	addi	a0,a0,1824 # 800178f0 <tickslock>
    800031d8:	ffffe097          	auipc	ra,0xffffe
    800031dc:	ac0080e7          	jalr	-1344(ra) # 80000c98 <release>
      return -1;
    800031e0:	57fd                	li	a5,-1
    800031e2:	bff9                	j	800031c0 <sys_sleep+0x88>

00000000800031e4 <sys_kill>:

uint64
sys_kill(void)
{
    800031e4:	1101                	addi	sp,sp,-32
    800031e6:	ec06                	sd	ra,24(sp)
    800031e8:	e822                	sd	s0,16(sp)
    800031ea:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    800031ec:	fec40593          	addi	a1,s0,-20
    800031f0:	4501                	li	a0,0
    800031f2:	00000097          	auipc	ra,0x0
    800031f6:	d84080e7          	jalr	-636(ra) # 80002f76 <argint>
    800031fa:	87aa                	mv	a5,a0
    return -1;
    800031fc:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    800031fe:	0007c863          	bltz	a5,8000320e <sys_kill+0x2a>
  return kill(pid);
    80003202:	fec42503          	lw	a0,-20(s0)
    80003206:	fffff097          	auipc	ra,0xfffff
    8000320a:	56e080e7          	jalr	1390(ra) # 80002774 <kill>
}
    8000320e:	60e2                	ld	ra,24(sp)
    80003210:	6442                	ld	s0,16(sp)
    80003212:	6105                	addi	sp,sp,32
    80003214:	8082                	ret

0000000080003216 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80003216:	1101                	addi	sp,sp,-32
    80003218:	ec06                	sd	ra,24(sp)
    8000321a:	e822                	sd	s0,16(sp)
    8000321c:	e426                	sd	s1,8(sp)
    8000321e:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80003220:	00014517          	auipc	a0,0x14
    80003224:	6d050513          	addi	a0,a0,1744 # 800178f0 <tickslock>
    80003228:	ffffe097          	auipc	ra,0xffffe
    8000322c:	9bc080e7          	jalr	-1604(ra) # 80000be4 <acquire>
  xticks = ticks;
    80003230:	00006497          	auipc	s1,0x6
    80003234:	e204a483          	lw	s1,-480(s1) # 80009050 <ticks>
  release(&tickslock);
    80003238:	00014517          	auipc	a0,0x14
    8000323c:	6b850513          	addi	a0,a0,1720 # 800178f0 <tickslock>
    80003240:	ffffe097          	auipc	ra,0xffffe
    80003244:	a58080e7          	jalr	-1448(ra) # 80000c98 <release>
  return xticks;
}
    80003248:	02049513          	slli	a0,s1,0x20
    8000324c:	9101                	srli	a0,a0,0x20
    8000324e:	60e2                	ld	ra,24(sp)
    80003250:	6442                	ld	s0,16(sp)
    80003252:	64a2                	ld	s1,8(sp)
    80003254:	6105                	addi	sp,sp,32
    80003256:	8082                	ret

0000000080003258 <sys_pause_system>:

uint64 sys_pause_system(void){
    80003258:	1101                	addi	sp,sp,-32
    8000325a:	ec06                	sd	ra,24(sp)
    8000325c:	e822                	sd	s0,16(sp)
    8000325e:	1000                	addi	s0,sp,32
    int seconds;

    if(argint(0, &seconds) < 0)
    80003260:	fec40593          	addi	a1,s0,-20
    80003264:	4501                	li	a0,0
    80003266:	00000097          	auipc	ra,0x0
    8000326a:	d10080e7          	jalr	-752(ra) # 80002f76 <argint>
        return -1;
    8000326e:	57fd                	li	a5,-1
    if(argint(0, &seconds) < 0)
    80003270:	00054963          	bltz	a0,80003282 <sys_pause_system+0x2a>
    pause_system(seconds);
    80003274:	fec42503          	lw	a0,-20(s0)
    80003278:	fffff097          	auipc	ra,0xfffff
    8000327c:	5f2080e7          	jalr	1522(ra) # 8000286a <pause_system>
    return 0;
    80003280:	4781                	li	a5,0
}
    80003282:	853e                	mv	a0,a5
    80003284:	60e2                	ld	ra,24(sp)
    80003286:	6442                	ld	s0,16(sp)
    80003288:	6105                	addi	sp,sp,32
    8000328a:	8082                	ret

000000008000328c <sys_kill_system>:

uint64 sys_kill_system(void){
    8000328c:	1141                	addi	sp,sp,-16
    8000328e:	e406                	sd	ra,8(sp)
    80003290:	e022                	sd	s0,0(sp)
    80003292:	0800                	addi	s0,sp,16
    kill_system();
    80003294:	fffff097          	auipc	ra,0xfffff
    80003298:	56a080e7          	jalr	1386(ra) # 800027fe <kill_system>
    return 0;
}
    8000329c:	4501                	li	a0,0
    8000329e:	60a2                	ld	ra,8(sp)
    800032a0:	6402                	ld	s0,0(sp)
    800032a2:	0141                	addi	sp,sp,16
    800032a4:	8082                	ret

00000000800032a6 <sys_print_stats>:

uint64 sys_print_stats(void){
    800032a6:	1141                	addi	sp,sp,-16
    800032a8:	e406                	sd	ra,8(sp)
    800032aa:	e022                	sd	s0,0(sp)
    800032ac:	0800                	addi	s0,sp,16
    print_stats();
    800032ae:	fffff097          	auipc	ra,0xfffff
    800032b2:	5f2080e7          	jalr	1522(ra) # 800028a0 <print_stats>
    return 0;
}
    800032b6:	4501                	li	a0,0
    800032b8:	60a2                	ld	ra,8(sp)
    800032ba:	6402                	ld	s0,0(sp)
    800032bc:	0141                	addi	sp,sp,16
    800032be:	8082                	ret

00000000800032c0 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    800032c0:	7179                	addi	sp,sp,-48
    800032c2:	f406                	sd	ra,40(sp)
    800032c4:	f022                	sd	s0,32(sp)
    800032c6:	ec26                	sd	s1,24(sp)
    800032c8:	e84a                	sd	s2,16(sp)
    800032ca:	e44e                	sd	s3,8(sp)
    800032cc:	e052                	sd	s4,0(sp)
    800032ce:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    800032d0:	00005597          	auipc	a1,0x5
    800032d4:	2f058593          	addi	a1,a1,752 # 800085c0 <syscalls+0xc8>
    800032d8:	00014517          	auipc	a0,0x14
    800032dc:	63050513          	addi	a0,a0,1584 # 80017908 <bcache>
    800032e0:	ffffe097          	auipc	ra,0xffffe
    800032e4:	874080e7          	jalr	-1932(ra) # 80000b54 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    800032e8:	0001c797          	auipc	a5,0x1c
    800032ec:	62078793          	addi	a5,a5,1568 # 8001f908 <bcache+0x8000>
    800032f0:	0001d717          	auipc	a4,0x1d
    800032f4:	88070713          	addi	a4,a4,-1920 # 8001fb70 <bcache+0x8268>
    800032f8:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    800032fc:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003300:	00014497          	auipc	s1,0x14
    80003304:	62048493          	addi	s1,s1,1568 # 80017920 <bcache+0x18>
    b->next = bcache.head.next;
    80003308:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    8000330a:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    8000330c:	00005a17          	auipc	s4,0x5
    80003310:	2bca0a13          	addi	s4,s4,700 # 800085c8 <syscalls+0xd0>
    b->next = bcache.head.next;
    80003314:	2b893783          	ld	a5,696(s2)
    80003318:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    8000331a:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    8000331e:	85d2                	mv	a1,s4
    80003320:	01048513          	addi	a0,s1,16
    80003324:	00001097          	auipc	ra,0x1
    80003328:	4bc080e7          	jalr	1212(ra) # 800047e0 <initsleeplock>
    bcache.head.next->prev = b;
    8000332c:	2b893783          	ld	a5,696(s2)
    80003330:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80003332:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003336:	45848493          	addi	s1,s1,1112
    8000333a:	fd349de3          	bne	s1,s3,80003314 <binit+0x54>
  }
}
    8000333e:	70a2                	ld	ra,40(sp)
    80003340:	7402                	ld	s0,32(sp)
    80003342:	64e2                	ld	s1,24(sp)
    80003344:	6942                	ld	s2,16(sp)
    80003346:	69a2                	ld	s3,8(sp)
    80003348:	6a02                	ld	s4,0(sp)
    8000334a:	6145                	addi	sp,sp,48
    8000334c:	8082                	ret

000000008000334e <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    8000334e:	7179                	addi	sp,sp,-48
    80003350:	f406                	sd	ra,40(sp)
    80003352:	f022                	sd	s0,32(sp)
    80003354:	ec26                	sd	s1,24(sp)
    80003356:	e84a                	sd	s2,16(sp)
    80003358:	e44e                	sd	s3,8(sp)
    8000335a:	1800                	addi	s0,sp,48
    8000335c:	89aa                	mv	s3,a0
    8000335e:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    80003360:	00014517          	auipc	a0,0x14
    80003364:	5a850513          	addi	a0,a0,1448 # 80017908 <bcache>
    80003368:	ffffe097          	auipc	ra,0xffffe
    8000336c:	87c080e7          	jalr	-1924(ra) # 80000be4 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80003370:	0001d497          	auipc	s1,0x1d
    80003374:	8504b483          	ld	s1,-1968(s1) # 8001fbc0 <bcache+0x82b8>
    80003378:	0001c797          	auipc	a5,0x1c
    8000337c:	7f878793          	addi	a5,a5,2040 # 8001fb70 <bcache+0x8268>
    80003380:	02f48f63          	beq	s1,a5,800033be <bread+0x70>
    80003384:	873e                	mv	a4,a5
    80003386:	a021                	j	8000338e <bread+0x40>
    80003388:	68a4                	ld	s1,80(s1)
    8000338a:	02e48a63          	beq	s1,a4,800033be <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    8000338e:	449c                	lw	a5,8(s1)
    80003390:	ff379ce3          	bne	a5,s3,80003388 <bread+0x3a>
    80003394:	44dc                	lw	a5,12(s1)
    80003396:	ff2799e3          	bne	a5,s2,80003388 <bread+0x3a>
      b->refcnt++;
    8000339a:	40bc                	lw	a5,64(s1)
    8000339c:	2785                	addiw	a5,a5,1
    8000339e:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800033a0:	00014517          	auipc	a0,0x14
    800033a4:	56850513          	addi	a0,a0,1384 # 80017908 <bcache>
    800033a8:	ffffe097          	auipc	ra,0xffffe
    800033ac:	8f0080e7          	jalr	-1808(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    800033b0:	01048513          	addi	a0,s1,16
    800033b4:	00001097          	auipc	ra,0x1
    800033b8:	466080e7          	jalr	1126(ra) # 8000481a <acquiresleep>
      return b;
    800033bc:	a8b9                	j	8000341a <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800033be:	0001c497          	auipc	s1,0x1c
    800033c2:	7fa4b483          	ld	s1,2042(s1) # 8001fbb8 <bcache+0x82b0>
    800033c6:	0001c797          	auipc	a5,0x1c
    800033ca:	7aa78793          	addi	a5,a5,1962 # 8001fb70 <bcache+0x8268>
    800033ce:	00f48863          	beq	s1,a5,800033de <bread+0x90>
    800033d2:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    800033d4:	40bc                	lw	a5,64(s1)
    800033d6:	cf81                	beqz	a5,800033ee <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800033d8:	64a4                	ld	s1,72(s1)
    800033da:	fee49de3          	bne	s1,a4,800033d4 <bread+0x86>
  panic("bget: no buffers");
    800033de:	00005517          	auipc	a0,0x5
    800033e2:	1f250513          	addi	a0,a0,498 # 800085d0 <syscalls+0xd8>
    800033e6:	ffffd097          	auipc	ra,0xffffd
    800033ea:	158080e7          	jalr	344(ra) # 8000053e <panic>
      b->dev = dev;
    800033ee:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    800033f2:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    800033f6:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    800033fa:	4785                	li	a5,1
    800033fc:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800033fe:	00014517          	auipc	a0,0x14
    80003402:	50a50513          	addi	a0,a0,1290 # 80017908 <bcache>
    80003406:	ffffe097          	auipc	ra,0xffffe
    8000340a:	892080e7          	jalr	-1902(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    8000340e:	01048513          	addi	a0,s1,16
    80003412:	00001097          	auipc	ra,0x1
    80003416:	408080e7          	jalr	1032(ra) # 8000481a <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    8000341a:	409c                	lw	a5,0(s1)
    8000341c:	cb89                	beqz	a5,8000342e <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    8000341e:	8526                	mv	a0,s1
    80003420:	70a2                	ld	ra,40(sp)
    80003422:	7402                	ld	s0,32(sp)
    80003424:	64e2                	ld	s1,24(sp)
    80003426:	6942                	ld	s2,16(sp)
    80003428:	69a2                	ld	s3,8(sp)
    8000342a:	6145                	addi	sp,sp,48
    8000342c:	8082                	ret
    virtio_disk_rw(b, 0);
    8000342e:	4581                	li	a1,0
    80003430:	8526                	mv	a0,s1
    80003432:	00003097          	auipc	ra,0x3
    80003436:	f14080e7          	jalr	-236(ra) # 80006346 <virtio_disk_rw>
    b->valid = 1;
    8000343a:	4785                	li	a5,1
    8000343c:	c09c                	sw	a5,0(s1)
  return b;
    8000343e:	b7c5                	j	8000341e <bread+0xd0>

0000000080003440 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80003440:	1101                	addi	sp,sp,-32
    80003442:	ec06                	sd	ra,24(sp)
    80003444:	e822                	sd	s0,16(sp)
    80003446:	e426                	sd	s1,8(sp)
    80003448:	1000                	addi	s0,sp,32
    8000344a:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    8000344c:	0541                	addi	a0,a0,16
    8000344e:	00001097          	auipc	ra,0x1
    80003452:	466080e7          	jalr	1126(ra) # 800048b4 <holdingsleep>
    80003456:	cd01                	beqz	a0,8000346e <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80003458:	4585                	li	a1,1
    8000345a:	8526                	mv	a0,s1
    8000345c:	00003097          	auipc	ra,0x3
    80003460:	eea080e7          	jalr	-278(ra) # 80006346 <virtio_disk_rw>
}
    80003464:	60e2                	ld	ra,24(sp)
    80003466:	6442                	ld	s0,16(sp)
    80003468:	64a2                	ld	s1,8(sp)
    8000346a:	6105                	addi	sp,sp,32
    8000346c:	8082                	ret
    panic("bwrite");
    8000346e:	00005517          	auipc	a0,0x5
    80003472:	17a50513          	addi	a0,a0,378 # 800085e8 <syscalls+0xf0>
    80003476:	ffffd097          	auipc	ra,0xffffd
    8000347a:	0c8080e7          	jalr	200(ra) # 8000053e <panic>

000000008000347e <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    8000347e:	1101                	addi	sp,sp,-32
    80003480:	ec06                	sd	ra,24(sp)
    80003482:	e822                	sd	s0,16(sp)
    80003484:	e426                	sd	s1,8(sp)
    80003486:	e04a                	sd	s2,0(sp)
    80003488:	1000                	addi	s0,sp,32
    8000348a:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    8000348c:	01050913          	addi	s2,a0,16
    80003490:	854a                	mv	a0,s2
    80003492:	00001097          	auipc	ra,0x1
    80003496:	422080e7          	jalr	1058(ra) # 800048b4 <holdingsleep>
    8000349a:	c92d                	beqz	a0,8000350c <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    8000349c:	854a                	mv	a0,s2
    8000349e:	00001097          	auipc	ra,0x1
    800034a2:	3d2080e7          	jalr	978(ra) # 80004870 <releasesleep>

  acquire(&bcache.lock);
    800034a6:	00014517          	auipc	a0,0x14
    800034aa:	46250513          	addi	a0,a0,1122 # 80017908 <bcache>
    800034ae:	ffffd097          	auipc	ra,0xffffd
    800034b2:	736080e7          	jalr	1846(ra) # 80000be4 <acquire>
  b->refcnt--;
    800034b6:	40bc                	lw	a5,64(s1)
    800034b8:	37fd                	addiw	a5,a5,-1
    800034ba:	0007871b          	sext.w	a4,a5
    800034be:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    800034c0:	eb05                	bnez	a4,800034f0 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    800034c2:	68bc                	ld	a5,80(s1)
    800034c4:	64b8                	ld	a4,72(s1)
    800034c6:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    800034c8:	64bc                	ld	a5,72(s1)
    800034ca:	68b8                	ld	a4,80(s1)
    800034cc:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    800034ce:	0001c797          	auipc	a5,0x1c
    800034d2:	43a78793          	addi	a5,a5,1082 # 8001f908 <bcache+0x8000>
    800034d6:	2b87b703          	ld	a4,696(a5)
    800034da:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    800034dc:	0001c717          	auipc	a4,0x1c
    800034e0:	69470713          	addi	a4,a4,1684 # 8001fb70 <bcache+0x8268>
    800034e4:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    800034e6:	2b87b703          	ld	a4,696(a5)
    800034ea:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    800034ec:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    800034f0:	00014517          	auipc	a0,0x14
    800034f4:	41850513          	addi	a0,a0,1048 # 80017908 <bcache>
    800034f8:	ffffd097          	auipc	ra,0xffffd
    800034fc:	7a0080e7          	jalr	1952(ra) # 80000c98 <release>
}
    80003500:	60e2                	ld	ra,24(sp)
    80003502:	6442                	ld	s0,16(sp)
    80003504:	64a2                	ld	s1,8(sp)
    80003506:	6902                	ld	s2,0(sp)
    80003508:	6105                	addi	sp,sp,32
    8000350a:	8082                	ret
    panic("brelse");
    8000350c:	00005517          	auipc	a0,0x5
    80003510:	0e450513          	addi	a0,a0,228 # 800085f0 <syscalls+0xf8>
    80003514:	ffffd097          	auipc	ra,0xffffd
    80003518:	02a080e7          	jalr	42(ra) # 8000053e <panic>

000000008000351c <bpin>:

void
bpin(struct buf *b) {
    8000351c:	1101                	addi	sp,sp,-32
    8000351e:	ec06                	sd	ra,24(sp)
    80003520:	e822                	sd	s0,16(sp)
    80003522:	e426                	sd	s1,8(sp)
    80003524:	1000                	addi	s0,sp,32
    80003526:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003528:	00014517          	auipc	a0,0x14
    8000352c:	3e050513          	addi	a0,a0,992 # 80017908 <bcache>
    80003530:	ffffd097          	auipc	ra,0xffffd
    80003534:	6b4080e7          	jalr	1716(ra) # 80000be4 <acquire>
  b->refcnt++;
    80003538:	40bc                	lw	a5,64(s1)
    8000353a:	2785                	addiw	a5,a5,1
    8000353c:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    8000353e:	00014517          	auipc	a0,0x14
    80003542:	3ca50513          	addi	a0,a0,970 # 80017908 <bcache>
    80003546:	ffffd097          	auipc	ra,0xffffd
    8000354a:	752080e7          	jalr	1874(ra) # 80000c98 <release>
}
    8000354e:	60e2                	ld	ra,24(sp)
    80003550:	6442                	ld	s0,16(sp)
    80003552:	64a2                	ld	s1,8(sp)
    80003554:	6105                	addi	sp,sp,32
    80003556:	8082                	ret

0000000080003558 <bunpin>:

void
bunpin(struct buf *b) {
    80003558:	1101                	addi	sp,sp,-32
    8000355a:	ec06                	sd	ra,24(sp)
    8000355c:	e822                	sd	s0,16(sp)
    8000355e:	e426                	sd	s1,8(sp)
    80003560:	1000                	addi	s0,sp,32
    80003562:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003564:	00014517          	auipc	a0,0x14
    80003568:	3a450513          	addi	a0,a0,932 # 80017908 <bcache>
    8000356c:	ffffd097          	auipc	ra,0xffffd
    80003570:	678080e7          	jalr	1656(ra) # 80000be4 <acquire>
  b->refcnt--;
    80003574:	40bc                	lw	a5,64(s1)
    80003576:	37fd                	addiw	a5,a5,-1
    80003578:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    8000357a:	00014517          	auipc	a0,0x14
    8000357e:	38e50513          	addi	a0,a0,910 # 80017908 <bcache>
    80003582:	ffffd097          	auipc	ra,0xffffd
    80003586:	716080e7          	jalr	1814(ra) # 80000c98 <release>
}
    8000358a:	60e2                	ld	ra,24(sp)
    8000358c:	6442                	ld	s0,16(sp)
    8000358e:	64a2                	ld	s1,8(sp)
    80003590:	6105                	addi	sp,sp,32
    80003592:	8082                	ret

0000000080003594 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80003594:	1101                	addi	sp,sp,-32
    80003596:	ec06                	sd	ra,24(sp)
    80003598:	e822                	sd	s0,16(sp)
    8000359a:	e426                	sd	s1,8(sp)
    8000359c:	e04a                	sd	s2,0(sp)
    8000359e:	1000                	addi	s0,sp,32
    800035a0:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    800035a2:	00d5d59b          	srliw	a1,a1,0xd
    800035a6:	0001d797          	auipc	a5,0x1d
    800035aa:	a3e7a783          	lw	a5,-1474(a5) # 8001ffe4 <sb+0x1c>
    800035ae:	9dbd                	addw	a1,a1,a5
    800035b0:	00000097          	auipc	ra,0x0
    800035b4:	d9e080e7          	jalr	-610(ra) # 8000334e <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    800035b8:	0074f713          	andi	a4,s1,7
    800035bc:	4785                	li	a5,1
    800035be:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    800035c2:	14ce                	slli	s1,s1,0x33
    800035c4:	90d9                	srli	s1,s1,0x36
    800035c6:	00950733          	add	a4,a0,s1
    800035ca:	05874703          	lbu	a4,88(a4)
    800035ce:	00e7f6b3          	and	a3,a5,a4
    800035d2:	c69d                	beqz	a3,80003600 <bfree+0x6c>
    800035d4:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    800035d6:	94aa                	add	s1,s1,a0
    800035d8:	fff7c793          	not	a5,a5
    800035dc:	8ff9                	and	a5,a5,a4
    800035de:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    800035e2:	00001097          	auipc	ra,0x1
    800035e6:	118080e7          	jalr	280(ra) # 800046fa <log_write>
  brelse(bp);
    800035ea:	854a                	mv	a0,s2
    800035ec:	00000097          	auipc	ra,0x0
    800035f0:	e92080e7          	jalr	-366(ra) # 8000347e <brelse>
}
    800035f4:	60e2                	ld	ra,24(sp)
    800035f6:	6442                	ld	s0,16(sp)
    800035f8:	64a2                	ld	s1,8(sp)
    800035fa:	6902                	ld	s2,0(sp)
    800035fc:	6105                	addi	sp,sp,32
    800035fe:	8082                	ret
    panic("freeing free block");
    80003600:	00005517          	auipc	a0,0x5
    80003604:	ff850513          	addi	a0,a0,-8 # 800085f8 <syscalls+0x100>
    80003608:	ffffd097          	auipc	ra,0xffffd
    8000360c:	f36080e7          	jalr	-202(ra) # 8000053e <panic>

0000000080003610 <balloc>:
{
    80003610:	711d                	addi	sp,sp,-96
    80003612:	ec86                	sd	ra,88(sp)
    80003614:	e8a2                	sd	s0,80(sp)
    80003616:	e4a6                	sd	s1,72(sp)
    80003618:	e0ca                	sd	s2,64(sp)
    8000361a:	fc4e                	sd	s3,56(sp)
    8000361c:	f852                	sd	s4,48(sp)
    8000361e:	f456                	sd	s5,40(sp)
    80003620:	f05a                	sd	s6,32(sp)
    80003622:	ec5e                	sd	s7,24(sp)
    80003624:	e862                	sd	s8,16(sp)
    80003626:	e466                	sd	s9,8(sp)
    80003628:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    8000362a:	0001d797          	auipc	a5,0x1d
    8000362e:	9a27a783          	lw	a5,-1630(a5) # 8001ffcc <sb+0x4>
    80003632:	cbd1                	beqz	a5,800036c6 <balloc+0xb6>
    80003634:	8baa                	mv	s7,a0
    80003636:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80003638:	0001db17          	auipc	s6,0x1d
    8000363c:	990b0b13          	addi	s6,s6,-1648 # 8001ffc8 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003640:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    80003642:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003644:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80003646:	6c89                	lui	s9,0x2
    80003648:	a831                	j	80003664 <balloc+0x54>
    brelse(bp);
    8000364a:	854a                	mv	a0,s2
    8000364c:	00000097          	auipc	ra,0x0
    80003650:	e32080e7          	jalr	-462(ra) # 8000347e <brelse>
  for(b = 0; b < sb.size; b += BPB){
    80003654:	015c87bb          	addw	a5,s9,s5
    80003658:	00078a9b          	sext.w	s5,a5
    8000365c:	004b2703          	lw	a4,4(s6)
    80003660:	06eaf363          	bgeu	s5,a4,800036c6 <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    80003664:	41fad79b          	sraiw	a5,s5,0x1f
    80003668:	0137d79b          	srliw	a5,a5,0x13
    8000366c:	015787bb          	addw	a5,a5,s5
    80003670:	40d7d79b          	sraiw	a5,a5,0xd
    80003674:	01cb2583          	lw	a1,28(s6)
    80003678:	9dbd                	addw	a1,a1,a5
    8000367a:	855e                	mv	a0,s7
    8000367c:	00000097          	auipc	ra,0x0
    80003680:	cd2080e7          	jalr	-814(ra) # 8000334e <bread>
    80003684:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003686:	004b2503          	lw	a0,4(s6)
    8000368a:	000a849b          	sext.w	s1,s5
    8000368e:	8662                	mv	a2,s8
    80003690:	faa4fde3          	bgeu	s1,a0,8000364a <balloc+0x3a>
      m = 1 << (bi % 8);
    80003694:	41f6579b          	sraiw	a5,a2,0x1f
    80003698:	01d7d69b          	srliw	a3,a5,0x1d
    8000369c:	00c6873b          	addw	a4,a3,a2
    800036a0:	00777793          	andi	a5,a4,7
    800036a4:	9f95                	subw	a5,a5,a3
    800036a6:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    800036aa:	4037571b          	sraiw	a4,a4,0x3
    800036ae:	00e906b3          	add	a3,s2,a4
    800036b2:	0586c683          	lbu	a3,88(a3)
    800036b6:	00d7f5b3          	and	a1,a5,a3
    800036ba:	cd91                	beqz	a1,800036d6 <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800036bc:	2605                	addiw	a2,a2,1
    800036be:	2485                	addiw	s1,s1,1
    800036c0:	fd4618e3          	bne	a2,s4,80003690 <balloc+0x80>
    800036c4:	b759                	j	8000364a <balloc+0x3a>
  panic("balloc: out of blocks");
    800036c6:	00005517          	auipc	a0,0x5
    800036ca:	f4a50513          	addi	a0,a0,-182 # 80008610 <syscalls+0x118>
    800036ce:	ffffd097          	auipc	ra,0xffffd
    800036d2:	e70080e7          	jalr	-400(ra) # 8000053e <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    800036d6:	974a                	add	a4,a4,s2
    800036d8:	8fd5                	or	a5,a5,a3
    800036da:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    800036de:	854a                	mv	a0,s2
    800036e0:	00001097          	auipc	ra,0x1
    800036e4:	01a080e7          	jalr	26(ra) # 800046fa <log_write>
        brelse(bp);
    800036e8:	854a                	mv	a0,s2
    800036ea:	00000097          	auipc	ra,0x0
    800036ee:	d94080e7          	jalr	-620(ra) # 8000347e <brelse>
  bp = bread(dev, bno);
    800036f2:	85a6                	mv	a1,s1
    800036f4:	855e                	mv	a0,s7
    800036f6:	00000097          	auipc	ra,0x0
    800036fa:	c58080e7          	jalr	-936(ra) # 8000334e <bread>
    800036fe:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80003700:	40000613          	li	a2,1024
    80003704:	4581                	li	a1,0
    80003706:	05850513          	addi	a0,a0,88
    8000370a:	ffffd097          	auipc	ra,0xffffd
    8000370e:	5d6080e7          	jalr	1494(ra) # 80000ce0 <memset>
  log_write(bp);
    80003712:	854a                	mv	a0,s2
    80003714:	00001097          	auipc	ra,0x1
    80003718:	fe6080e7          	jalr	-26(ra) # 800046fa <log_write>
  brelse(bp);
    8000371c:	854a                	mv	a0,s2
    8000371e:	00000097          	auipc	ra,0x0
    80003722:	d60080e7          	jalr	-672(ra) # 8000347e <brelse>
}
    80003726:	8526                	mv	a0,s1
    80003728:	60e6                	ld	ra,88(sp)
    8000372a:	6446                	ld	s0,80(sp)
    8000372c:	64a6                	ld	s1,72(sp)
    8000372e:	6906                	ld	s2,64(sp)
    80003730:	79e2                	ld	s3,56(sp)
    80003732:	7a42                	ld	s4,48(sp)
    80003734:	7aa2                	ld	s5,40(sp)
    80003736:	7b02                	ld	s6,32(sp)
    80003738:	6be2                	ld	s7,24(sp)
    8000373a:	6c42                	ld	s8,16(sp)
    8000373c:	6ca2                	ld	s9,8(sp)
    8000373e:	6125                	addi	sp,sp,96
    80003740:	8082                	ret

0000000080003742 <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    80003742:	7179                	addi	sp,sp,-48
    80003744:	f406                	sd	ra,40(sp)
    80003746:	f022                	sd	s0,32(sp)
    80003748:	ec26                	sd	s1,24(sp)
    8000374a:	e84a                	sd	s2,16(sp)
    8000374c:	e44e                	sd	s3,8(sp)
    8000374e:	e052                	sd	s4,0(sp)
    80003750:	1800                	addi	s0,sp,48
    80003752:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80003754:	47ad                	li	a5,11
    80003756:	04b7fe63          	bgeu	a5,a1,800037b2 <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    8000375a:	ff45849b          	addiw	s1,a1,-12
    8000375e:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003762:	0ff00793          	li	a5,255
    80003766:	0ae7e363          	bltu	a5,a4,8000380c <bmap+0xca>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    8000376a:	08052583          	lw	a1,128(a0)
    8000376e:	c5ad                	beqz	a1,800037d8 <bmap+0x96>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    80003770:	00092503          	lw	a0,0(s2)
    80003774:	00000097          	auipc	ra,0x0
    80003778:	bda080e7          	jalr	-1062(ra) # 8000334e <bread>
    8000377c:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    8000377e:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003782:	02049593          	slli	a1,s1,0x20
    80003786:	9181                	srli	a1,a1,0x20
    80003788:	058a                	slli	a1,a1,0x2
    8000378a:	00b784b3          	add	s1,a5,a1
    8000378e:	0004a983          	lw	s3,0(s1)
    80003792:	04098d63          	beqz	s3,800037ec <bmap+0xaa>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    80003796:	8552                	mv	a0,s4
    80003798:	00000097          	auipc	ra,0x0
    8000379c:	ce6080e7          	jalr	-794(ra) # 8000347e <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    800037a0:	854e                	mv	a0,s3
    800037a2:	70a2                	ld	ra,40(sp)
    800037a4:	7402                	ld	s0,32(sp)
    800037a6:	64e2                	ld	s1,24(sp)
    800037a8:	6942                	ld	s2,16(sp)
    800037aa:	69a2                	ld	s3,8(sp)
    800037ac:	6a02                	ld	s4,0(sp)
    800037ae:	6145                	addi	sp,sp,48
    800037b0:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    800037b2:	02059493          	slli	s1,a1,0x20
    800037b6:	9081                	srli	s1,s1,0x20
    800037b8:	048a                	slli	s1,s1,0x2
    800037ba:	94aa                	add	s1,s1,a0
    800037bc:	0504a983          	lw	s3,80(s1)
    800037c0:	fe0990e3          	bnez	s3,800037a0 <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    800037c4:	4108                	lw	a0,0(a0)
    800037c6:	00000097          	auipc	ra,0x0
    800037ca:	e4a080e7          	jalr	-438(ra) # 80003610 <balloc>
    800037ce:	0005099b          	sext.w	s3,a0
    800037d2:	0534a823          	sw	s3,80(s1)
    800037d6:	b7e9                	j	800037a0 <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    800037d8:	4108                	lw	a0,0(a0)
    800037da:	00000097          	auipc	ra,0x0
    800037de:	e36080e7          	jalr	-458(ra) # 80003610 <balloc>
    800037e2:	0005059b          	sext.w	a1,a0
    800037e6:	08b92023          	sw	a1,128(s2)
    800037ea:	b759                	j	80003770 <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    800037ec:	00092503          	lw	a0,0(s2)
    800037f0:	00000097          	auipc	ra,0x0
    800037f4:	e20080e7          	jalr	-480(ra) # 80003610 <balloc>
    800037f8:	0005099b          	sext.w	s3,a0
    800037fc:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    80003800:	8552                	mv	a0,s4
    80003802:	00001097          	auipc	ra,0x1
    80003806:	ef8080e7          	jalr	-264(ra) # 800046fa <log_write>
    8000380a:	b771                	j	80003796 <bmap+0x54>
  panic("bmap: out of range");
    8000380c:	00005517          	auipc	a0,0x5
    80003810:	e1c50513          	addi	a0,a0,-484 # 80008628 <syscalls+0x130>
    80003814:	ffffd097          	auipc	ra,0xffffd
    80003818:	d2a080e7          	jalr	-726(ra) # 8000053e <panic>

000000008000381c <iget>:
{
    8000381c:	7179                	addi	sp,sp,-48
    8000381e:	f406                	sd	ra,40(sp)
    80003820:	f022                	sd	s0,32(sp)
    80003822:	ec26                	sd	s1,24(sp)
    80003824:	e84a                	sd	s2,16(sp)
    80003826:	e44e                	sd	s3,8(sp)
    80003828:	e052                	sd	s4,0(sp)
    8000382a:	1800                	addi	s0,sp,48
    8000382c:	89aa                	mv	s3,a0
    8000382e:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    80003830:	0001c517          	auipc	a0,0x1c
    80003834:	7b850513          	addi	a0,a0,1976 # 8001ffe8 <itable>
    80003838:	ffffd097          	auipc	ra,0xffffd
    8000383c:	3ac080e7          	jalr	940(ra) # 80000be4 <acquire>
  empty = 0;
    80003840:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003842:	0001c497          	auipc	s1,0x1c
    80003846:	7be48493          	addi	s1,s1,1982 # 80020000 <itable+0x18>
    8000384a:	0001e697          	auipc	a3,0x1e
    8000384e:	24668693          	addi	a3,a3,582 # 80021a90 <log>
    80003852:	a039                	j	80003860 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003854:	02090b63          	beqz	s2,8000388a <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003858:	08848493          	addi	s1,s1,136
    8000385c:	02d48a63          	beq	s1,a3,80003890 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003860:	449c                	lw	a5,8(s1)
    80003862:	fef059e3          	blez	a5,80003854 <iget+0x38>
    80003866:	4098                	lw	a4,0(s1)
    80003868:	ff3716e3          	bne	a4,s3,80003854 <iget+0x38>
    8000386c:	40d8                	lw	a4,4(s1)
    8000386e:	ff4713e3          	bne	a4,s4,80003854 <iget+0x38>
      ip->ref++;
    80003872:	2785                	addiw	a5,a5,1
    80003874:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    80003876:	0001c517          	auipc	a0,0x1c
    8000387a:	77250513          	addi	a0,a0,1906 # 8001ffe8 <itable>
    8000387e:	ffffd097          	auipc	ra,0xffffd
    80003882:	41a080e7          	jalr	1050(ra) # 80000c98 <release>
      return ip;
    80003886:	8926                	mv	s2,s1
    80003888:	a03d                	j	800038b6 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    8000388a:	f7f9                	bnez	a5,80003858 <iget+0x3c>
    8000388c:	8926                	mv	s2,s1
    8000388e:	b7e9                	j	80003858 <iget+0x3c>
  if(empty == 0)
    80003890:	02090c63          	beqz	s2,800038c8 <iget+0xac>
  ip->dev = dev;
    80003894:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003898:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    8000389c:	4785                	li	a5,1
    8000389e:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    800038a2:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    800038a6:	0001c517          	auipc	a0,0x1c
    800038aa:	74250513          	addi	a0,a0,1858 # 8001ffe8 <itable>
    800038ae:	ffffd097          	auipc	ra,0xffffd
    800038b2:	3ea080e7          	jalr	1002(ra) # 80000c98 <release>
}
    800038b6:	854a                	mv	a0,s2
    800038b8:	70a2                	ld	ra,40(sp)
    800038ba:	7402                	ld	s0,32(sp)
    800038bc:	64e2                	ld	s1,24(sp)
    800038be:	6942                	ld	s2,16(sp)
    800038c0:	69a2                	ld	s3,8(sp)
    800038c2:	6a02                	ld	s4,0(sp)
    800038c4:	6145                	addi	sp,sp,48
    800038c6:	8082                	ret
    panic("iget: no inodes");
    800038c8:	00005517          	auipc	a0,0x5
    800038cc:	d7850513          	addi	a0,a0,-648 # 80008640 <syscalls+0x148>
    800038d0:	ffffd097          	auipc	ra,0xffffd
    800038d4:	c6e080e7          	jalr	-914(ra) # 8000053e <panic>

00000000800038d8 <fsinit>:
fsinit(int dev) {
    800038d8:	7179                	addi	sp,sp,-48
    800038da:	f406                	sd	ra,40(sp)
    800038dc:	f022                	sd	s0,32(sp)
    800038de:	ec26                	sd	s1,24(sp)
    800038e0:	e84a                	sd	s2,16(sp)
    800038e2:	e44e                	sd	s3,8(sp)
    800038e4:	1800                	addi	s0,sp,48
    800038e6:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    800038e8:	4585                	li	a1,1
    800038ea:	00000097          	auipc	ra,0x0
    800038ee:	a64080e7          	jalr	-1436(ra) # 8000334e <bread>
    800038f2:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    800038f4:	0001c997          	auipc	s3,0x1c
    800038f8:	6d498993          	addi	s3,s3,1748 # 8001ffc8 <sb>
    800038fc:	02000613          	li	a2,32
    80003900:	05850593          	addi	a1,a0,88
    80003904:	854e                	mv	a0,s3
    80003906:	ffffd097          	auipc	ra,0xffffd
    8000390a:	43a080e7          	jalr	1082(ra) # 80000d40 <memmove>
  brelse(bp);
    8000390e:	8526                	mv	a0,s1
    80003910:	00000097          	auipc	ra,0x0
    80003914:	b6e080e7          	jalr	-1170(ra) # 8000347e <brelse>
  if(sb.magic != FSMAGIC)
    80003918:	0009a703          	lw	a4,0(s3)
    8000391c:	102037b7          	lui	a5,0x10203
    80003920:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003924:	02f71263          	bne	a4,a5,80003948 <fsinit+0x70>
  initlog(dev, &sb);
    80003928:	0001c597          	auipc	a1,0x1c
    8000392c:	6a058593          	addi	a1,a1,1696 # 8001ffc8 <sb>
    80003930:	854a                	mv	a0,s2
    80003932:	00001097          	auipc	ra,0x1
    80003936:	b4c080e7          	jalr	-1204(ra) # 8000447e <initlog>
}
    8000393a:	70a2                	ld	ra,40(sp)
    8000393c:	7402                	ld	s0,32(sp)
    8000393e:	64e2                	ld	s1,24(sp)
    80003940:	6942                	ld	s2,16(sp)
    80003942:	69a2                	ld	s3,8(sp)
    80003944:	6145                	addi	sp,sp,48
    80003946:	8082                	ret
    panic("invalid file system");
    80003948:	00005517          	auipc	a0,0x5
    8000394c:	d0850513          	addi	a0,a0,-760 # 80008650 <syscalls+0x158>
    80003950:	ffffd097          	auipc	ra,0xffffd
    80003954:	bee080e7          	jalr	-1042(ra) # 8000053e <panic>

0000000080003958 <iinit>:
{
    80003958:	7179                	addi	sp,sp,-48
    8000395a:	f406                	sd	ra,40(sp)
    8000395c:	f022                	sd	s0,32(sp)
    8000395e:	ec26                	sd	s1,24(sp)
    80003960:	e84a                	sd	s2,16(sp)
    80003962:	e44e                	sd	s3,8(sp)
    80003964:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    80003966:	00005597          	auipc	a1,0x5
    8000396a:	d0258593          	addi	a1,a1,-766 # 80008668 <syscalls+0x170>
    8000396e:	0001c517          	auipc	a0,0x1c
    80003972:	67a50513          	addi	a0,a0,1658 # 8001ffe8 <itable>
    80003976:	ffffd097          	auipc	ra,0xffffd
    8000397a:	1de080e7          	jalr	478(ra) # 80000b54 <initlock>
  for(i = 0; i < NINODE; i++) {
    8000397e:	0001c497          	auipc	s1,0x1c
    80003982:	69248493          	addi	s1,s1,1682 # 80020010 <itable+0x28>
    80003986:	0001e997          	auipc	s3,0x1e
    8000398a:	11a98993          	addi	s3,s3,282 # 80021aa0 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    8000398e:	00005917          	auipc	s2,0x5
    80003992:	ce290913          	addi	s2,s2,-798 # 80008670 <syscalls+0x178>
    80003996:	85ca                	mv	a1,s2
    80003998:	8526                	mv	a0,s1
    8000399a:	00001097          	auipc	ra,0x1
    8000399e:	e46080e7          	jalr	-442(ra) # 800047e0 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    800039a2:	08848493          	addi	s1,s1,136
    800039a6:	ff3498e3          	bne	s1,s3,80003996 <iinit+0x3e>
}
    800039aa:	70a2                	ld	ra,40(sp)
    800039ac:	7402                	ld	s0,32(sp)
    800039ae:	64e2                	ld	s1,24(sp)
    800039b0:	6942                	ld	s2,16(sp)
    800039b2:	69a2                	ld	s3,8(sp)
    800039b4:	6145                	addi	sp,sp,48
    800039b6:	8082                	ret

00000000800039b8 <ialloc>:
{
    800039b8:	715d                	addi	sp,sp,-80
    800039ba:	e486                	sd	ra,72(sp)
    800039bc:	e0a2                	sd	s0,64(sp)
    800039be:	fc26                	sd	s1,56(sp)
    800039c0:	f84a                	sd	s2,48(sp)
    800039c2:	f44e                	sd	s3,40(sp)
    800039c4:	f052                	sd	s4,32(sp)
    800039c6:	ec56                	sd	s5,24(sp)
    800039c8:	e85a                	sd	s6,16(sp)
    800039ca:	e45e                	sd	s7,8(sp)
    800039cc:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    800039ce:	0001c717          	auipc	a4,0x1c
    800039d2:	60672703          	lw	a4,1542(a4) # 8001ffd4 <sb+0xc>
    800039d6:	4785                	li	a5,1
    800039d8:	04e7fa63          	bgeu	a5,a4,80003a2c <ialloc+0x74>
    800039dc:	8aaa                	mv	s5,a0
    800039de:	8bae                	mv	s7,a1
    800039e0:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    800039e2:	0001ca17          	auipc	s4,0x1c
    800039e6:	5e6a0a13          	addi	s4,s4,1510 # 8001ffc8 <sb>
    800039ea:	00048b1b          	sext.w	s6,s1
    800039ee:	0044d593          	srli	a1,s1,0x4
    800039f2:	018a2783          	lw	a5,24(s4)
    800039f6:	9dbd                	addw	a1,a1,a5
    800039f8:	8556                	mv	a0,s5
    800039fa:	00000097          	auipc	ra,0x0
    800039fe:	954080e7          	jalr	-1708(ra) # 8000334e <bread>
    80003a02:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003a04:	05850993          	addi	s3,a0,88
    80003a08:	00f4f793          	andi	a5,s1,15
    80003a0c:	079a                	slli	a5,a5,0x6
    80003a0e:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003a10:	00099783          	lh	a5,0(s3)
    80003a14:	c785                	beqz	a5,80003a3c <ialloc+0x84>
    brelse(bp);
    80003a16:	00000097          	auipc	ra,0x0
    80003a1a:	a68080e7          	jalr	-1432(ra) # 8000347e <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003a1e:	0485                	addi	s1,s1,1
    80003a20:	00ca2703          	lw	a4,12(s4)
    80003a24:	0004879b          	sext.w	a5,s1
    80003a28:	fce7e1e3          	bltu	a5,a4,800039ea <ialloc+0x32>
  panic("ialloc: no inodes");
    80003a2c:	00005517          	auipc	a0,0x5
    80003a30:	c4c50513          	addi	a0,a0,-948 # 80008678 <syscalls+0x180>
    80003a34:	ffffd097          	auipc	ra,0xffffd
    80003a38:	b0a080e7          	jalr	-1270(ra) # 8000053e <panic>
      memset(dip, 0, sizeof(*dip));
    80003a3c:	04000613          	li	a2,64
    80003a40:	4581                	li	a1,0
    80003a42:	854e                	mv	a0,s3
    80003a44:	ffffd097          	auipc	ra,0xffffd
    80003a48:	29c080e7          	jalr	668(ra) # 80000ce0 <memset>
      dip->type = type;
    80003a4c:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003a50:	854a                	mv	a0,s2
    80003a52:	00001097          	auipc	ra,0x1
    80003a56:	ca8080e7          	jalr	-856(ra) # 800046fa <log_write>
      brelse(bp);
    80003a5a:	854a                	mv	a0,s2
    80003a5c:	00000097          	auipc	ra,0x0
    80003a60:	a22080e7          	jalr	-1502(ra) # 8000347e <brelse>
      return iget(dev, inum);
    80003a64:	85da                	mv	a1,s6
    80003a66:	8556                	mv	a0,s5
    80003a68:	00000097          	auipc	ra,0x0
    80003a6c:	db4080e7          	jalr	-588(ra) # 8000381c <iget>
}
    80003a70:	60a6                	ld	ra,72(sp)
    80003a72:	6406                	ld	s0,64(sp)
    80003a74:	74e2                	ld	s1,56(sp)
    80003a76:	7942                	ld	s2,48(sp)
    80003a78:	79a2                	ld	s3,40(sp)
    80003a7a:	7a02                	ld	s4,32(sp)
    80003a7c:	6ae2                	ld	s5,24(sp)
    80003a7e:	6b42                	ld	s6,16(sp)
    80003a80:	6ba2                	ld	s7,8(sp)
    80003a82:	6161                	addi	sp,sp,80
    80003a84:	8082                	ret

0000000080003a86 <iupdate>:
{
    80003a86:	1101                	addi	sp,sp,-32
    80003a88:	ec06                	sd	ra,24(sp)
    80003a8a:	e822                	sd	s0,16(sp)
    80003a8c:	e426                	sd	s1,8(sp)
    80003a8e:	e04a                	sd	s2,0(sp)
    80003a90:	1000                	addi	s0,sp,32
    80003a92:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003a94:	415c                	lw	a5,4(a0)
    80003a96:	0047d79b          	srliw	a5,a5,0x4
    80003a9a:	0001c597          	auipc	a1,0x1c
    80003a9e:	5465a583          	lw	a1,1350(a1) # 8001ffe0 <sb+0x18>
    80003aa2:	9dbd                	addw	a1,a1,a5
    80003aa4:	4108                	lw	a0,0(a0)
    80003aa6:	00000097          	auipc	ra,0x0
    80003aaa:	8a8080e7          	jalr	-1880(ra) # 8000334e <bread>
    80003aae:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003ab0:	05850793          	addi	a5,a0,88
    80003ab4:	40c8                	lw	a0,4(s1)
    80003ab6:	893d                	andi	a0,a0,15
    80003ab8:	051a                	slli	a0,a0,0x6
    80003aba:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    80003abc:	04449703          	lh	a4,68(s1)
    80003ac0:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    80003ac4:	04649703          	lh	a4,70(s1)
    80003ac8:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    80003acc:	04849703          	lh	a4,72(s1)
    80003ad0:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    80003ad4:	04a49703          	lh	a4,74(s1)
    80003ad8:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    80003adc:	44f8                	lw	a4,76(s1)
    80003ade:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003ae0:	03400613          	li	a2,52
    80003ae4:	05048593          	addi	a1,s1,80
    80003ae8:	0531                	addi	a0,a0,12
    80003aea:	ffffd097          	auipc	ra,0xffffd
    80003aee:	256080e7          	jalr	598(ra) # 80000d40 <memmove>
  log_write(bp);
    80003af2:	854a                	mv	a0,s2
    80003af4:	00001097          	auipc	ra,0x1
    80003af8:	c06080e7          	jalr	-1018(ra) # 800046fa <log_write>
  brelse(bp);
    80003afc:	854a                	mv	a0,s2
    80003afe:	00000097          	auipc	ra,0x0
    80003b02:	980080e7          	jalr	-1664(ra) # 8000347e <brelse>
}
    80003b06:	60e2                	ld	ra,24(sp)
    80003b08:	6442                	ld	s0,16(sp)
    80003b0a:	64a2                	ld	s1,8(sp)
    80003b0c:	6902                	ld	s2,0(sp)
    80003b0e:	6105                	addi	sp,sp,32
    80003b10:	8082                	ret

0000000080003b12 <idup>:
{
    80003b12:	1101                	addi	sp,sp,-32
    80003b14:	ec06                	sd	ra,24(sp)
    80003b16:	e822                	sd	s0,16(sp)
    80003b18:	e426                	sd	s1,8(sp)
    80003b1a:	1000                	addi	s0,sp,32
    80003b1c:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003b1e:	0001c517          	auipc	a0,0x1c
    80003b22:	4ca50513          	addi	a0,a0,1226 # 8001ffe8 <itable>
    80003b26:	ffffd097          	auipc	ra,0xffffd
    80003b2a:	0be080e7          	jalr	190(ra) # 80000be4 <acquire>
  ip->ref++;
    80003b2e:	449c                	lw	a5,8(s1)
    80003b30:	2785                	addiw	a5,a5,1
    80003b32:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003b34:	0001c517          	auipc	a0,0x1c
    80003b38:	4b450513          	addi	a0,a0,1204 # 8001ffe8 <itable>
    80003b3c:	ffffd097          	auipc	ra,0xffffd
    80003b40:	15c080e7          	jalr	348(ra) # 80000c98 <release>
}
    80003b44:	8526                	mv	a0,s1
    80003b46:	60e2                	ld	ra,24(sp)
    80003b48:	6442                	ld	s0,16(sp)
    80003b4a:	64a2                	ld	s1,8(sp)
    80003b4c:	6105                	addi	sp,sp,32
    80003b4e:	8082                	ret

0000000080003b50 <ilock>:
{
    80003b50:	1101                	addi	sp,sp,-32
    80003b52:	ec06                	sd	ra,24(sp)
    80003b54:	e822                	sd	s0,16(sp)
    80003b56:	e426                	sd	s1,8(sp)
    80003b58:	e04a                	sd	s2,0(sp)
    80003b5a:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003b5c:	c115                	beqz	a0,80003b80 <ilock+0x30>
    80003b5e:	84aa                	mv	s1,a0
    80003b60:	451c                	lw	a5,8(a0)
    80003b62:	00f05f63          	blez	a5,80003b80 <ilock+0x30>
  acquiresleep(&ip->lock);
    80003b66:	0541                	addi	a0,a0,16
    80003b68:	00001097          	auipc	ra,0x1
    80003b6c:	cb2080e7          	jalr	-846(ra) # 8000481a <acquiresleep>
  if(ip->valid == 0){
    80003b70:	40bc                	lw	a5,64(s1)
    80003b72:	cf99                	beqz	a5,80003b90 <ilock+0x40>
}
    80003b74:	60e2                	ld	ra,24(sp)
    80003b76:	6442                	ld	s0,16(sp)
    80003b78:	64a2                	ld	s1,8(sp)
    80003b7a:	6902                	ld	s2,0(sp)
    80003b7c:	6105                	addi	sp,sp,32
    80003b7e:	8082                	ret
    panic("ilock");
    80003b80:	00005517          	auipc	a0,0x5
    80003b84:	b1050513          	addi	a0,a0,-1264 # 80008690 <syscalls+0x198>
    80003b88:	ffffd097          	auipc	ra,0xffffd
    80003b8c:	9b6080e7          	jalr	-1610(ra) # 8000053e <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003b90:	40dc                	lw	a5,4(s1)
    80003b92:	0047d79b          	srliw	a5,a5,0x4
    80003b96:	0001c597          	auipc	a1,0x1c
    80003b9a:	44a5a583          	lw	a1,1098(a1) # 8001ffe0 <sb+0x18>
    80003b9e:	9dbd                	addw	a1,a1,a5
    80003ba0:	4088                	lw	a0,0(s1)
    80003ba2:	fffff097          	auipc	ra,0xfffff
    80003ba6:	7ac080e7          	jalr	1964(ra) # 8000334e <bread>
    80003baa:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003bac:	05850593          	addi	a1,a0,88
    80003bb0:	40dc                	lw	a5,4(s1)
    80003bb2:	8bbd                	andi	a5,a5,15
    80003bb4:	079a                	slli	a5,a5,0x6
    80003bb6:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003bb8:	00059783          	lh	a5,0(a1)
    80003bbc:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003bc0:	00259783          	lh	a5,2(a1)
    80003bc4:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003bc8:	00459783          	lh	a5,4(a1)
    80003bcc:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003bd0:	00659783          	lh	a5,6(a1)
    80003bd4:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003bd8:	459c                	lw	a5,8(a1)
    80003bda:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003bdc:	03400613          	li	a2,52
    80003be0:	05b1                	addi	a1,a1,12
    80003be2:	05048513          	addi	a0,s1,80
    80003be6:	ffffd097          	auipc	ra,0xffffd
    80003bea:	15a080e7          	jalr	346(ra) # 80000d40 <memmove>
    brelse(bp);
    80003bee:	854a                	mv	a0,s2
    80003bf0:	00000097          	auipc	ra,0x0
    80003bf4:	88e080e7          	jalr	-1906(ra) # 8000347e <brelse>
    ip->valid = 1;
    80003bf8:	4785                	li	a5,1
    80003bfa:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003bfc:	04449783          	lh	a5,68(s1)
    80003c00:	fbb5                	bnez	a5,80003b74 <ilock+0x24>
      panic("ilock: no type");
    80003c02:	00005517          	auipc	a0,0x5
    80003c06:	a9650513          	addi	a0,a0,-1386 # 80008698 <syscalls+0x1a0>
    80003c0a:	ffffd097          	auipc	ra,0xffffd
    80003c0e:	934080e7          	jalr	-1740(ra) # 8000053e <panic>

0000000080003c12 <iunlock>:
{
    80003c12:	1101                	addi	sp,sp,-32
    80003c14:	ec06                	sd	ra,24(sp)
    80003c16:	e822                	sd	s0,16(sp)
    80003c18:	e426                	sd	s1,8(sp)
    80003c1a:	e04a                	sd	s2,0(sp)
    80003c1c:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003c1e:	c905                	beqz	a0,80003c4e <iunlock+0x3c>
    80003c20:	84aa                	mv	s1,a0
    80003c22:	01050913          	addi	s2,a0,16
    80003c26:	854a                	mv	a0,s2
    80003c28:	00001097          	auipc	ra,0x1
    80003c2c:	c8c080e7          	jalr	-884(ra) # 800048b4 <holdingsleep>
    80003c30:	cd19                	beqz	a0,80003c4e <iunlock+0x3c>
    80003c32:	449c                	lw	a5,8(s1)
    80003c34:	00f05d63          	blez	a5,80003c4e <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003c38:	854a                	mv	a0,s2
    80003c3a:	00001097          	auipc	ra,0x1
    80003c3e:	c36080e7          	jalr	-970(ra) # 80004870 <releasesleep>
}
    80003c42:	60e2                	ld	ra,24(sp)
    80003c44:	6442                	ld	s0,16(sp)
    80003c46:	64a2                	ld	s1,8(sp)
    80003c48:	6902                	ld	s2,0(sp)
    80003c4a:	6105                	addi	sp,sp,32
    80003c4c:	8082                	ret
    panic("iunlock");
    80003c4e:	00005517          	auipc	a0,0x5
    80003c52:	a5a50513          	addi	a0,a0,-1446 # 800086a8 <syscalls+0x1b0>
    80003c56:	ffffd097          	auipc	ra,0xffffd
    80003c5a:	8e8080e7          	jalr	-1816(ra) # 8000053e <panic>

0000000080003c5e <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003c5e:	7179                	addi	sp,sp,-48
    80003c60:	f406                	sd	ra,40(sp)
    80003c62:	f022                	sd	s0,32(sp)
    80003c64:	ec26                	sd	s1,24(sp)
    80003c66:	e84a                	sd	s2,16(sp)
    80003c68:	e44e                	sd	s3,8(sp)
    80003c6a:	e052                	sd	s4,0(sp)
    80003c6c:	1800                	addi	s0,sp,48
    80003c6e:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003c70:	05050493          	addi	s1,a0,80
    80003c74:	08050913          	addi	s2,a0,128
    80003c78:	a021                	j	80003c80 <itrunc+0x22>
    80003c7a:	0491                	addi	s1,s1,4
    80003c7c:	01248d63          	beq	s1,s2,80003c96 <itrunc+0x38>
    if(ip->addrs[i]){
    80003c80:	408c                	lw	a1,0(s1)
    80003c82:	dde5                	beqz	a1,80003c7a <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003c84:	0009a503          	lw	a0,0(s3)
    80003c88:	00000097          	auipc	ra,0x0
    80003c8c:	90c080e7          	jalr	-1780(ra) # 80003594 <bfree>
      ip->addrs[i] = 0;
    80003c90:	0004a023          	sw	zero,0(s1)
    80003c94:	b7dd                	j	80003c7a <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003c96:	0809a583          	lw	a1,128(s3)
    80003c9a:	e185                	bnez	a1,80003cba <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003c9c:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003ca0:	854e                	mv	a0,s3
    80003ca2:	00000097          	auipc	ra,0x0
    80003ca6:	de4080e7          	jalr	-540(ra) # 80003a86 <iupdate>
}
    80003caa:	70a2                	ld	ra,40(sp)
    80003cac:	7402                	ld	s0,32(sp)
    80003cae:	64e2                	ld	s1,24(sp)
    80003cb0:	6942                	ld	s2,16(sp)
    80003cb2:	69a2                	ld	s3,8(sp)
    80003cb4:	6a02                	ld	s4,0(sp)
    80003cb6:	6145                	addi	sp,sp,48
    80003cb8:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003cba:	0009a503          	lw	a0,0(s3)
    80003cbe:	fffff097          	auipc	ra,0xfffff
    80003cc2:	690080e7          	jalr	1680(ra) # 8000334e <bread>
    80003cc6:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003cc8:	05850493          	addi	s1,a0,88
    80003ccc:	45850913          	addi	s2,a0,1112
    80003cd0:	a811                	j	80003ce4 <itrunc+0x86>
        bfree(ip->dev, a[j]);
    80003cd2:	0009a503          	lw	a0,0(s3)
    80003cd6:	00000097          	auipc	ra,0x0
    80003cda:	8be080e7          	jalr	-1858(ra) # 80003594 <bfree>
    for(j = 0; j < NINDIRECT; j++){
    80003cde:	0491                	addi	s1,s1,4
    80003ce0:	01248563          	beq	s1,s2,80003cea <itrunc+0x8c>
      if(a[j])
    80003ce4:	408c                	lw	a1,0(s1)
    80003ce6:	dde5                	beqz	a1,80003cde <itrunc+0x80>
    80003ce8:	b7ed                	j	80003cd2 <itrunc+0x74>
    brelse(bp);
    80003cea:	8552                	mv	a0,s4
    80003cec:	fffff097          	auipc	ra,0xfffff
    80003cf0:	792080e7          	jalr	1938(ra) # 8000347e <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003cf4:	0809a583          	lw	a1,128(s3)
    80003cf8:	0009a503          	lw	a0,0(s3)
    80003cfc:	00000097          	auipc	ra,0x0
    80003d00:	898080e7          	jalr	-1896(ra) # 80003594 <bfree>
    ip->addrs[NDIRECT] = 0;
    80003d04:	0809a023          	sw	zero,128(s3)
    80003d08:	bf51                	j	80003c9c <itrunc+0x3e>

0000000080003d0a <iput>:
{
    80003d0a:	1101                	addi	sp,sp,-32
    80003d0c:	ec06                	sd	ra,24(sp)
    80003d0e:	e822                	sd	s0,16(sp)
    80003d10:	e426                	sd	s1,8(sp)
    80003d12:	e04a                	sd	s2,0(sp)
    80003d14:	1000                	addi	s0,sp,32
    80003d16:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003d18:	0001c517          	auipc	a0,0x1c
    80003d1c:	2d050513          	addi	a0,a0,720 # 8001ffe8 <itable>
    80003d20:	ffffd097          	auipc	ra,0xffffd
    80003d24:	ec4080e7          	jalr	-316(ra) # 80000be4 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003d28:	4498                	lw	a4,8(s1)
    80003d2a:	4785                	li	a5,1
    80003d2c:	02f70363          	beq	a4,a5,80003d52 <iput+0x48>
  ip->ref--;
    80003d30:	449c                	lw	a5,8(s1)
    80003d32:	37fd                	addiw	a5,a5,-1
    80003d34:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003d36:	0001c517          	auipc	a0,0x1c
    80003d3a:	2b250513          	addi	a0,a0,690 # 8001ffe8 <itable>
    80003d3e:	ffffd097          	auipc	ra,0xffffd
    80003d42:	f5a080e7          	jalr	-166(ra) # 80000c98 <release>
}
    80003d46:	60e2                	ld	ra,24(sp)
    80003d48:	6442                	ld	s0,16(sp)
    80003d4a:	64a2                	ld	s1,8(sp)
    80003d4c:	6902                	ld	s2,0(sp)
    80003d4e:	6105                	addi	sp,sp,32
    80003d50:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003d52:	40bc                	lw	a5,64(s1)
    80003d54:	dff1                	beqz	a5,80003d30 <iput+0x26>
    80003d56:	04a49783          	lh	a5,74(s1)
    80003d5a:	fbf9                	bnez	a5,80003d30 <iput+0x26>
    acquiresleep(&ip->lock);
    80003d5c:	01048913          	addi	s2,s1,16
    80003d60:	854a                	mv	a0,s2
    80003d62:	00001097          	auipc	ra,0x1
    80003d66:	ab8080e7          	jalr	-1352(ra) # 8000481a <acquiresleep>
    release(&itable.lock);
    80003d6a:	0001c517          	auipc	a0,0x1c
    80003d6e:	27e50513          	addi	a0,a0,638 # 8001ffe8 <itable>
    80003d72:	ffffd097          	auipc	ra,0xffffd
    80003d76:	f26080e7          	jalr	-218(ra) # 80000c98 <release>
    itrunc(ip);
    80003d7a:	8526                	mv	a0,s1
    80003d7c:	00000097          	auipc	ra,0x0
    80003d80:	ee2080e7          	jalr	-286(ra) # 80003c5e <itrunc>
    ip->type = 0;
    80003d84:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003d88:	8526                	mv	a0,s1
    80003d8a:	00000097          	auipc	ra,0x0
    80003d8e:	cfc080e7          	jalr	-772(ra) # 80003a86 <iupdate>
    ip->valid = 0;
    80003d92:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003d96:	854a                	mv	a0,s2
    80003d98:	00001097          	auipc	ra,0x1
    80003d9c:	ad8080e7          	jalr	-1320(ra) # 80004870 <releasesleep>
    acquire(&itable.lock);
    80003da0:	0001c517          	auipc	a0,0x1c
    80003da4:	24850513          	addi	a0,a0,584 # 8001ffe8 <itable>
    80003da8:	ffffd097          	auipc	ra,0xffffd
    80003dac:	e3c080e7          	jalr	-452(ra) # 80000be4 <acquire>
    80003db0:	b741                	j	80003d30 <iput+0x26>

0000000080003db2 <iunlockput>:
{
    80003db2:	1101                	addi	sp,sp,-32
    80003db4:	ec06                	sd	ra,24(sp)
    80003db6:	e822                	sd	s0,16(sp)
    80003db8:	e426                	sd	s1,8(sp)
    80003dba:	1000                	addi	s0,sp,32
    80003dbc:	84aa                	mv	s1,a0
  iunlock(ip);
    80003dbe:	00000097          	auipc	ra,0x0
    80003dc2:	e54080e7          	jalr	-428(ra) # 80003c12 <iunlock>
  iput(ip);
    80003dc6:	8526                	mv	a0,s1
    80003dc8:	00000097          	auipc	ra,0x0
    80003dcc:	f42080e7          	jalr	-190(ra) # 80003d0a <iput>
}
    80003dd0:	60e2                	ld	ra,24(sp)
    80003dd2:	6442                	ld	s0,16(sp)
    80003dd4:	64a2                	ld	s1,8(sp)
    80003dd6:	6105                	addi	sp,sp,32
    80003dd8:	8082                	ret

0000000080003dda <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003dda:	1141                	addi	sp,sp,-16
    80003ddc:	e422                	sd	s0,8(sp)
    80003dde:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003de0:	411c                	lw	a5,0(a0)
    80003de2:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003de4:	415c                	lw	a5,4(a0)
    80003de6:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003de8:	04451783          	lh	a5,68(a0)
    80003dec:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003df0:	04a51783          	lh	a5,74(a0)
    80003df4:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003df8:	04c56783          	lwu	a5,76(a0)
    80003dfc:	e99c                	sd	a5,16(a1)
}
    80003dfe:	6422                	ld	s0,8(sp)
    80003e00:	0141                	addi	sp,sp,16
    80003e02:	8082                	ret

0000000080003e04 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003e04:	457c                	lw	a5,76(a0)
    80003e06:	0ed7e963          	bltu	a5,a3,80003ef8 <readi+0xf4>
{
    80003e0a:	7159                	addi	sp,sp,-112
    80003e0c:	f486                	sd	ra,104(sp)
    80003e0e:	f0a2                	sd	s0,96(sp)
    80003e10:	eca6                	sd	s1,88(sp)
    80003e12:	e8ca                	sd	s2,80(sp)
    80003e14:	e4ce                	sd	s3,72(sp)
    80003e16:	e0d2                	sd	s4,64(sp)
    80003e18:	fc56                	sd	s5,56(sp)
    80003e1a:	f85a                	sd	s6,48(sp)
    80003e1c:	f45e                	sd	s7,40(sp)
    80003e1e:	f062                	sd	s8,32(sp)
    80003e20:	ec66                	sd	s9,24(sp)
    80003e22:	e86a                	sd	s10,16(sp)
    80003e24:	e46e                	sd	s11,8(sp)
    80003e26:	1880                	addi	s0,sp,112
    80003e28:	8baa                	mv	s7,a0
    80003e2a:	8c2e                	mv	s8,a1
    80003e2c:	8ab2                	mv	s5,a2
    80003e2e:	84b6                	mv	s1,a3
    80003e30:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003e32:	9f35                	addw	a4,a4,a3
    return 0;
    80003e34:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003e36:	0ad76063          	bltu	a4,a3,80003ed6 <readi+0xd2>
  if(off + n > ip->size)
    80003e3a:	00e7f463          	bgeu	a5,a4,80003e42 <readi+0x3e>
    n = ip->size - off;
    80003e3e:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003e42:	0a0b0963          	beqz	s6,80003ef4 <readi+0xf0>
    80003e46:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003e48:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003e4c:	5cfd                	li	s9,-1
    80003e4e:	a82d                	j	80003e88 <readi+0x84>
    80003e50:	020a1d93          	slli	s11,s4,0x20
    80003e54:	020ddd93          	srli	s11,s11,0x20
    80003e58:	05890613          	addi	a2,s2,88
    80003e5c:	86ee                	mv	a3,s11
    80003e5e:	963a                	add	a2,a2,a4
    80003e60:	85d6                	mv	a1,s5
    80003e62:	8562                	mv	a0,s8
    80003e64:	fffff097          	auipc	ra,0xfffff
    80003e68:	ac6080e7          	jalr	-1338(ra) # 8000292a <either_copyout>
    80003e6c:	05950d63          	beq	a0,s9,80003ec6 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003e70:	854a                	mv	a0,s2
    80003e72:	fffff097          	auipc	ra,0xfffff
    80003e76:	60c080e7          	jalr	1548(ra) # 8000347e <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003e7a:	013a09bb          	addw	s3,s4,s3
    80003e7e:	009a04bb          	addw	s1,s4,s1
    80003e82:	9aee                	add	s5,s5,s11
    80003e84:	0569f763          	bgeu	s3,s6,80003ed2 <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003e88:	000ba903          	lw	s2,0(s7)
    80003e8c:	00a4d59b          	srliw	a1,s1,0xa
    80003e90:	855e                	mv	a0,s7
    80003e92:	00000097          	auipc	ra,0x0
    80003e96:	8b0080e7          	jalr	-1872(ra) # 80003742 <bmap>
    80003e9a:	0005059b          	sext.w	a1,a0
    80003e9e:	854a                	mv	a0,s2
    80003ea0:	fffff097          	auipc	ra,0xfffff
    80003ea4:	4ae080e7          	jalr	1198(ra) # 8000334e <bread>
    80003ea8:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003eaa:	3ff4f713          	andi	a4,s1,1023
    80003eae:	40ed07bb          	subw	a5,s10,a4
    80003eb2:	413b06bb          	subw	a3,s6,s3
    80003eb6:	8a3e                	mv	s4,a5
    80003eb8:	2781                	sext.w	a5,a5
    80003eba:	0006861b          	sext.w	a2,a3
    80003ebe:	f8f679e3          	bgeu	a2,a5,80003e50 <readi+0x4c>
    80003ec2:	8a36                	mv	s4,a3
    80003ec4:	b771                	j	80003e50 <readi+0x4c>
      brelse(bp);
    80003ec6:	854a                	mv	a0,s2
    80003ec8:	fffff097          	auipc	ra,0xfffff
    80003ecc:	5b6080e7          	jalr	1462(ra) # 8000347e <brelse>
      tot = -1;
    80003ed0:	59fd                	li	s3,-1
  }
  return tot;
    80003ed2:	0009851b          	sext.w	a0,s3
}
    80003ed6:	70a6                	ld	ra,104(sp)
    80003ed8:	7406                	ld	s0,96(sp)
    80003eda:	64e6                	ld	s1,88(sp)
    80003edc:	6946                	ld	s2,80(sp)
    80003ede:	69a6                	ld	s3,72(sp)
    80003ee0:	6a06                	ld	s4,64(sp)
    80003ee2:	7ae2                	ld	s5,56(sp)
    80003ee4:	7b42                	ld	s6,48(sp)
    80003ee6:	7ba2                	ld	s7,40(sp)
    80003ee8:	7c02                	ld	s8,32(sp)
    80003eea:	6ce2                	ld	s9,24(sp)
    80003eec:	6d42                	ld	s10,16(sp)
    80003eee:	6da2                	ld	s11,8(sp)
    80003ef0:	6165                	addi	sp,sp,112
    80003ef2:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003ef4:	89da                	mv	s3,s6
    80003ef6:	bff1                	j	80003ed2 <readi+0xce>
    return 0;
    80003ef8:	4501                	li	a0,0
}
    80003efa:	8082                	ret

0000000080003efc <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003efc:	457c                	lw	a5,76(a0)
    80003efe:	10d7e863          	bltu	a5,a3,8000400e <writei+0x112>
{
    80003f02:	7159                	addi	sp,sp,-112
    80003f04:	f486                	sd	ra,104(sp)
    80003f06:	f0a2                	sd	s0,96(sp)
    80003f08:	eca6                	sd	s1,88(sp)
    80003f0a:	e8ca                	sd	s2,80(sp)
    80003f0c:	e4ce                	sd	s3,72(sp)
    80003f0e:	e0d2                	sd	s4,64(sp)
    80003f10:	fc56                	sd	s5,56(sp)
    80003f12:	f85a                	sd	s6,48(sp)
    80003f14:	f45e                	sd	s7,40(sp)
    80003f16:	f062                	sd	s8,32(sp)
    80003f18:	ec66                	sd	s9,24(sp)
    80003f1a:	e86a                	sd	s10,16(sp)
    80003f1c:	e46e                	sd	s11,8(sp)
    80003f1e:	1880                	addi	s0,sp,112
    80003f20:	8b2a                	mv	s6,a0
    80003f22:	8c2e                	mv	s8,a1
    80003f24:	8ab2                	mv	s5,a2
    80003f26:	8936                	mv	s2,a3
    80003f28:	8bba                	mv	s7,a4
  if(off > ip->size || off + n < off)
    80003f2a:	00e687bb          	addw	a5,a3,a4
    80003f2e:	0ed7e263          	bltu	a5,a3,80004012 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003f32:	00043737          	lui	a4,0x43
    80003f36:	0ef76063          	bltu	a4,a5,80004016 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003f3a:	0c0b8863          	beqz	s7,8000400a <writei+0x10e>
    80003f3e:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003f40:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003f44:	5cfd                	li	s9,-1
    80003f46:	a091                	j	80003f8a <writei+0x8e>
    80003f48:	02099d93          	slli	s11,s3,0x20
    80003f4c:	020ddd93          	srli	s11,s11,0x20
    80003f50:	05848513          	addi	a0,s1,88
    80003f54:	86ee                	mv	a3,s11
    80003f56:	8656                	mv	a2,s5
    80003f58:	85e2                	mv	a1,s8
    80003f5a:	953a                	add	a0,a0,a4
    80003f5c:	fffff097          	auipc	ra,0xfffff
    80003f60:	a24080e7          	jalr	-1500(ra) # 80002980 <either_copyin>
    80003f64:	07950263          	beq	a0,s9,80003fc8 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003f68:	8526                	mv	a0,s1
    80003f6a:	00000097          	auipc	ra,0x0
    80003f6e:	790080e7          	jalr	1936(ra) # 800046fa <log_write>
    brelse(bp);
    80003f72:	8526                	mv	a0,s1
    80003f74:	fffff097          	auipc	ra,0xfffff
    80003f78:	50a080e7          	jalr	1290(ra) # 8000347e <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003f7c:	01498a3b          	addw	s4,s3,s4
    80003f80:	0129893b          	addw	s2,s3,s2
    80003f84:	9aee                	add	s5,s5,s11
    80003f86:	057a7663          	bgeu	s4,s7,80003fd2 <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003f8a:	000b2483          	lw	s1,0(s6)
    80003f8e:	00a9559b          	srliw	a1,s2,0xa
    80003f92:	855a                	mv	a0,s6
    80003f94:	fffff097          	auipc	ra,0xfffff
    80003f98:	7ae080e7          	jalr	1966(ra) # 80003742 <bmap>
    80003f9c:	0005059b          	sext.w	a1,a0
    80003fa0:	8526                	mv	a0,s1
    80003fa2:	fffff097          	auipc	ra,0xfffff
    80003fa6:	3ac080e7          	jalr	940(ra) # 8000334e <bread>
    80003faa:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003fac:	3ff97713          	andi	a4,s2,1023
    80003fb0:	40ed07bb          	subw	a5,s10,a4
    80003fb4:	414b86bb          	subw	a3,s7,s4
    80003fb8:	89be                	mv	s3,a5
    80003fba:	2781                	sext.w	a5,a5
    80003fbc:	0006861b          	sext.w	a2,a3
    80003fc0:	f8f674e3          	bgeu	a2,a5,80003f48 <writei+0x4c>
    80003fc4:	89b6                	mv	s3,a3
    80003fc6:	b749                	j	80003f48 <writei+0x4c>
      brelse(bp);
    80003fc8:	8526                	mv	a0,s1
    80003fca:	fffff097          	auipc	ra,0xfffff
    80003fce:	4b4080e7          	jalr	1204(ra) # 8000347e <brelse>
  }

  if(off > ip->size)
    80003fd2:	04cb2783          	lw	a5,76(s6)
    80003fd6:	0127f463          	bgeu	a5,s2,80003fde <writei+0xe2>
    ip->size = off;
    80003fda:	052b2623          	sw	s2,76(s6)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003fde:	855a                	mv	a0,s6
    80003fe0:	00000097          	auipc	ra,0x0
    80003fe4:	aa6080e7          	jalr	-1370(ra) # 80003a86 <iupdate>

  return tot;
    80003fe8:	000a051b          	sext.w	a0,s4
}
    80003fec:	70a6                	ld	ra,104(sp)
    80003fee:	7406                	ld	s0,96(sp)
    80003ff0:	64e6                	ld	s1,88(sp)
    80003ff2:	6946                	ld	s2,80(sp)
    80003ff4:	69a6                	ld	s3,72(sp)
    80003ff6:	6a06                	ld	s4,64(sp)
    80003ff8:	7ae2                	ld	s5,56(sp)
    80003ffa:	7b42                	ld	s6,48(sp)
    80003ffc:	7ba2                	ld	s7,40(sp)
    80003ffe:	7c02                	ld	s8,32(sp)
    80004000:	6ce2                	ld	s9,24(sp)
    80004002:	6d42                	ld	s10,16(sp)
    80004004:	6da2                	ld	s11,8(sp)
    80004006:	6165                	addi	sp,sp,112
    80004008:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    8000400a:	8a5e                	mv	s4,s7
    8000400c:	bfc9                	j	80003fde <writei+0xe2>
    return -1;
    8000400e:	557d                	li	a0,-1
}
    80004010:	8082                	ret
    return -1;
    80004012:	557d                	li	a0,-1
    80004014:	bfe1                	j	80003fec <writei+0xf0>
    return -1;
    80004016:	557d                	li	a0,-1
    80004018:	bfd1                	j	80003fec <writei+0xf0>

000000008000401a <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    8000401a:	1141                	addi	sp,sp,-16
    8000401c:	e406                	sd	ra,8(sp)
    8000401e:	e022                	sd	s0,0(sp)
    80004020:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80004022:	4639                	li	a2,14
    80004024:	ffffd097          	auipc	ra,0xffffd
    80004028:	d94080e7          	jalr	-620(ra) # 80000db8 <strncmp>
}
    8000402c:	60a2                	ld	ra,8(sp)
    8000402e:	6402                	ld	s0,0(sp)
    80004030:	0141                	addi	sp,sp,16
    80004032:	8082                	ret

0000000080004034 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80004034:	7139                	addi	sp,sp,-64
    80004036:	fc06                	sd	ra,56(sp)
    80004038:	f822                	sd	s0,48(sp)
    8000403a:	f426                	sd	s1,40(sp)
    8000403c:	f04a                	sd	s2,32(sp)
    8000403e:	ec4e                	sd	s3,24(sp)
    80004040:	e852                	sd	s4,16(sp)
    80004042:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80004044:	04451703          	lh	a4,68(a0)
    80004048:	4785                	li	a5,1
    8000404a:	00f71a63          	bne	a4,a5,8000405e <dirlookup+0x2a>
    8000404e:	892a                	mv	s2,a0
    80004050:	89ae                	mv	s3,a1
    80004052:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80004054:	457c                	lw	a5,76(a0)
    80004056:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80004058:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000405a:	e79d                	bnez	a5,80004088 <dirlookup+0x54>
    8000405c:	a8a5                	j	800040d4 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    8000405e:	00004517          	auipc	a0,0x4
    80004062:	65250513          	addi	a0,a0,1618 # 800086b0 <syscalls+0x1b8>
    80004066:	ffffc097          	auipc	ra,0xffffc
    8000406a:	4d8080e7          	jalr	1240(ra) # 8000053e <panic>
      panic("dirlookup read");
    8000406e:	00004517          	auipc	a0,0x4
    80004072:	65a50513          	addi	a0,a0,1626 # 800086c8 <syscalls+0x1d0>
    80004076:	ffffc097          	auipc	ra,0xffffc
    8000407a:	4c8080e7          	jalr	1224(ra) # 8000053e <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000407e:	24c1                	addiw	s1,s1,16
    80004080:	04c92783          	lw	a5,76(s2)
    80004084:	04f4f763          	bgeu	s1,a5,800040d2 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004088:	4741                	li	a4,16
    8000408a:	86a6                	mv	a3,s1
    8000408c:	fc040613          	addi	a2,s0,-64
    80004090:	4581                	li	a1,0
    80004092:	854a                	mv	a0,s2
    80004094:	00000097          	auipc	ra,0x0
    80004098:	d70080e7          	jalr	-656(ra) # 80003e04 <readi>
    8000409c:	47c1                	li	a5,16
    8000409e:	fcf518e3          	bne	a0,a5,8000406e <dirlookup+0x3a>
    if(de.inum == 0)
    800040a2:	fc045783          	lhu	a5,-64(s0)
    800040a6:	dfe1                	beqz	a5,8000407e <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    800040a8:	fc240593          	addi	a1,s0,-62
    800040ac:	854e                	mv	a0,s3
    800040ae:	00000097          	auipc	ra,0x0
    800040b2:	f6c080e7          	jalr	-148(ra) # 8000401a <namecmp>
    800040b6:	f561                	bnez	a0,8000407e <dirlookup+0x4a>
      if(poff)
    800040b8:	000a0463          	beqz	s4,800040c0 <dirlookup+0x8c>
        *poff = off;
    800040bc:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    800040c0:	fc045583          	lhu	a1,-64(s0)
    800040c4:	00092503          	lw	a0,0(s2)
    800040c8:	fffff097          	auipc	ra,0xfffff
    800040cc:	754080e7          	jalr	1876(ra) # 8000381c <iget>
    800040d0:	a011                	j	800040d4 <dirlookup+0xa0>
  return 0;
    800040d2:	4501                	li	a0,0
}
    800040d4:	70e2                	ld	ra,56(sp)
    800040d6:	7442                	ld	s0,48(sp)
    800040d8:	74a2                	ld	s1,40(sp)
    800040da:	7902                	ld	s2,32(sp)
    800040dc:	69e2                	ld	s3,24(sp)
    800040de:	6a42                	ld	s4,16(sp)
    800040e0:	6121                	addi	sp,sp,64
    800040e2:	8082                	ret

00000000800040e4 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    800040e4:	711d                	addi	sp,sp,-96
    800040e6:	ec86                	sd	ra,88(sp)
    800040e8:	e8a2                	sd	s0,80(sp)
    800040ea:	e4a6                	sd	s1,72(sp)
    800040ec:	e0ca                	sd	s2,64(sp)
    800040ee:	fc4e                	sd	s3,56(sp)
    800040f0:	f852                	sd	s4,48(sp)
    800040f2:	f456                	sd	s5,40(sp)
    800040f4:	f05a                	sd	s6,32(sp)
    800040f6:	ec5e                	sd	s7,24(sp)
    800040f8:	e862                	sd	s8,16(sp)
    800040fa:	e466                	sd	s9,8(sp)
    800040fc:	1080                	addi	s0,sp,96
    800040fe:	84aa                	mv	s1,a0
    80004100:	8b2e                	mv	s6,a1
    80004102:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80004104:	00054703          	lbu	a4,0(a0)
    80004108:	02f00793          	li	a5,47
    8000410c:	02f70363          	beq	a4,a5,80004132 <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80004110:	ffffe097          	auipc	ra,0xffffe
    80004114:	8b8080e7          	jalr	-1864(ra) # 800019c8 <myproc>
    80004118:	17053503          	ld	a0,368(a0)
    8000411c:	00000097          	auipc	ra,0x0
    80004120:	9f6080e7          	jalr	-1546(ra) # 80003b12 <idup>
    80004124:	89aa                	mv	s3,a0
  while(*path == '/')
    80004126:	02f00913          	li	s2,47
  len = path - s;
    8000412a:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    8000412c:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    8000412e:	4c05                	li	s8,1
    80004130:	a865                	j	800041e8 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80004132:	4585                	li	a1,1
    80004134:	4505                	li	a0,1
    80004136:	fffff097          	auipc	ra,0xfffff
    8000413a:	6e6080e7          	jalr	1766(ra) # 8000381c <iget>
    8000413e:	89aa                	mv	s3,a0
    80004140:	b7dd                	j	80004126 <namex+0x42>
      iunlockput(ip);
    80004142:	854e                	mv	a0,s3
    80004144:	00000097          	auipc	ra,0x0
    80004148:	c6e080e7          	jalr	-914(ra) # 80003db2 <iunlockput>
      return 0;
    8000414c:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    8000414e:	854e                	mv	a0,s3
    80004150:	60e6                	ld	ra,88(sp)
    80004152:	6446                	ld	s0,80(sp)
    80004154:	64a6                	ld	s1,72(sp)
    80004156:	6906                	ld	s2,64(sp)
    80004158:	79e2                	ld	s3,56(sp)
    8000415a:	7a42                	ld	s4,48(sp)
    8000415c:	7aa2                	ld	s5,40(sp)
    8000415e:	7b02                	ld	s6,32(sp)
    80004160:	6be2                	ld	s7,24(sp)
    80004162:	6c42                	ld	s8,16(sp)
    80004164:	6ca2                	ld	s9,8(sp)
    80004166:	6125                	addi	sp,sp,96
    80004168:	8082                	ret
      iunlock(ip);
    8000416a:	854e                	mv	a0,s3
    8000416c:	00000097          	auipc	ra,0x0
    80004170:	aa6080e7          	jalr	-1370(ra) # 80003c12 <iunlock>
      return ip;
    80004174:	bfe9                	j	8000414e <namex+0x6a>
      iunlockput(ip);
    80004176:	854e                	mv	a0,s3
    80004178:	00000097          	auipc	ra,0x0
    8000417c:	c3a080e7          	jalr	-966(ra) # 80003db2 <iunlockput>
      return 0;
    80004180:	89d2                	mv	s3,s4
    80004182:	b7f1                	j	8000414e <namex+0x6a>
  len = path - s;
    80004184:	40b48633          	sub	a2,s1,a1
    80004188:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    8000418c:	094cd463          	bge	s9,s4,80004214 <namex+0x130>
    memmove(name, s, DIRSIZ);
    80004190:	4639                	li	a2,14
    80004192:	8556                	mv	a0,s5
    80004194:	ffffd097          	auipc	ra,0xffffd
    80004198:	bac080e7          	jalr	-1108(ra) # 80000d40 <memmove>
  while(*path == '/')
    8000419c:	0004c783          	lbu	a5,0(s1)
    800041a0:	01279763          	bne	a5,s2,800041ae <namex+0xca>
    path++;
    800041a4:	0485                	addi	s1,s1,1
  while(*path == '/')
    800041a6:	0004c783          	lbu	a5,0(s1)
    800041aa:	ff278de3          	beq	a5,s2,800041a4 <namex+0xc0>
    ilock(ip);
    800041ae:	854e                	mv	a0,s3
    800041b0:	00000097          	auipc	ra,0x0
    800041b4:	9a0080e7          	jalr	-1632(ra) # 80003b50 <ilock>
    if(ip->type != T_DIR){
    800041b8:	04499783          	lh	a5,68(s3)
    800041bc:	f98793e3          	bne	a5,s8,80004142 <namex+0x5e>
    if(nameiparent && *path == '\0'){
    800041c0:	000b0563          	beqz	s6,800041ca <namex+0xe6>
    800041c4:	0004c783          	lbu	a5,0(s1)
    800041c8:	d3cd                	beqz	a5,8000416a <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    800041ca:	865e                	mv	a2,s7
    800041cc:	85d6                	mv	a1,s5
    800041ce:	854e                	mv	a0,s3
    800041d0:	00000097          	auipc	ra,0x0
    800041d4:	e64080e7          	jalr	-412(ra) # 80004034 <dirlookup>
    800041d8:	8a2a                	mv	s4,a0
    800041da:	dd51                	beqz	a0,80004176 <namex+0x92>
    iunlockput(ip);
    800041dc:	854e                	mv	a0,s3
    800041de:	00000097          	auipc	ra,0x0
    800041e2:	bd4080e7          	jalr	-1068(ra) # 80003db2 <iunlockput>
    ip = next;
    800041e6:	89d2                	mv	s3,s4
  while(*path == '/')
    800041e8:	0004c783          	lbu	a5,0(s1)
    800041ec:	05279763          	bne	a5,s2,8000423a <namex+0x156>
    path++;
    800041f0:	0485                	addi	s1,s1,1
  while(*path == '/')
    800041f2:	0004c783          	lbu	a5,0(s1)
    800041f6:	ff278de3          	beq	a5,s2,800041f0 <namex+0x10c>
  if(*path == 0)
    800041fa:	c79d                	beqz	a5,80004228 <namex+0x144>
    path++;
    800041fc:	85a6                	mv	a1,s1
  len = path - s;
    800041fe:	8a5e                	mv	s4,s7
    80004200:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    80004202:	01278963          	beq	a5,s2,80004214 <namex+0x130>
    80004206:	dfbd                	beqz	a5,80004184 <namex+0xa0>
    path++;
    80004208:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    8000420a:	0004c783          	lbu	a5,0(s1)
    8000420e:	ff279ce3          	bne	a5,s2,80004206 <namex+0x122>
    80004212:	bf8d                	j	80004184 <namex+0xa0>
    memmove(name, s, len);
    80004214:	2601                	sext.w	a2,a2
    80004216:	8556                	mv	a0,s5
    80004218:	ffffd097          	auipc	ra,0xffffd
    8000421c:	b28080e7          	jalr	-1240(ra) # 80000d40 <memmove>
    name[len] = 0;
    80004220:	9a56                	add	s4,s4,s5
    80004222:	000a0023          	sb	zero,0(s4)
    80004226:	bf9d                	j	8000419c <namex+0xb8>
  if(nameiparent){
    80004228:	f20b03e3          	beqz	s6,8000414e <namex+0x6a>
    iput(ip);
    8000422c:	854e                	mv	a0,s3
    8000422e:	00000097          	auipc	ra,0x0
    80004232:	adc080e7          	jalr	-1316(ra) # 80003d0a <iput>
    return 0;
    80004236:	4981                	li	s3,0
    80004238:	bf19                	j	8000414e <namex+0x6a>
  if(*path == 0)
    8000423a:	d7fd                	beqz	a5,80004228 <namex+0x144>
  while(*path != '/' && *path != 0)
    8000423c:	0004c783          	lbu	a5,0(s1)
    80004240:	85a6                	mv	a1,s1
    80004242:	b7d1                	j	80004206 <namex+0x122>

0000000080004244 <dirlink>:
{
    80004244:	7139                	addi	sp,sp,-64
    80004246:	fc06                	sd	ra,56(sp)
    80004248:	f822                	sd	s0,48(sp)
    8000424a:	f426                	sd	s1,40(sp)
    8000424c:	f04a                	sd	s2,32(sp)
    8000424e:	ec4e                	sd	s3,24(sp)
    80004250:	e852                	sd	s4,16(sp)
    80004252:	0080                	addi	s0,sp,64
    80004254:	892a                	mv	s2,a0
    80004256:	8a2e                	mv	s4,a1
    80004258:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    8000425a:	4601                	li	a2,0
    8000425c:	00000097          	auipc	ra,0x0
    80004260:	dd8080e7          	jalr	-552(ra) # 80004034 <dirlookup>
    80004264:	e93d                	bnez	a0,800042da <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004266:	04c92483          	lw	s1,76(s2)
    8000426a:	c49d                	beqz	s1,80004298 <dirlink+0x54>
    8000426c:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000426e:	4741                	li	a4,16
    80004270:	86a6                	mv	a3,s1
    80004272:	fc040613          	addi	a2,s0,-64
    80004276:	4581                	li	a1,0
    80004278:	854a                	mv	a0,s2
    8000427a:	00000097          	auipc	ra,0x0
    8000427e:	b8a080e7          	jalr	-1142(ra) # 80003e04 <readi>
    80004282:	47c1                	li	a5,16
    80004284:	06f51163          	bne	a0,a5,800042e6 <dirlink+0xa2>
    if(de.inum == 0)
    80004288:	fc045783          	lhu	a5,-64(s0)
    8000428c:	c791                	beqz	a5,80004298 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000428e:	24c1                	addiw	s1,s1,16
    80004290:	04c92783          	lw	a5,76(s2)
    80004294:	fcf4ede3          	bltu	s1,a5,8000426e <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80004298:	4639                	li	a2,14
    8000429a:	85d2                	mv	a1,s4
    8000429c:	fc240513          	addi	a0,s0,-62
    800042a0:	ffffd097          	auipc	ra,0xffffd
    800042a4:	b54080e7          	jalr	-1196(ra) # 80000df4 <strncpy>
  de.inum = inum;
    800042a8:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800042ac:	4741                	li	a4,16
    800042ae:	86a6                	mv	a3,s1
    800042b0:	fc040613          	addi	a2,s0,-64
    800042b4:	4581                	li	a1,0
    800042b6:	854a                	mv	a0,s2
    800042b8:	00000097          	auipc	ra,0x0
    800042bc:	c44080e7          	jalr	-956(ra) # 80003efc <writei>
    800042c0:	872a                	mv	a4,a0
    800042c2:	47c1                	li	a5,16
  return 0;
    800042c4:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800042c6:	02f71863          	bne	a4,a5,800042f6 <dirlink+0xb2>
}
    800042ca:	70e2                	ld	ra,56(sp)
    800042cc:	7442                	ld	s0,48(sp)
    800042ce:	74a2                	ld	s1,40(sp)
    800042d0:	7902                	ld	s2,32(sp)
    800042d2:	69e2                	ld	s3,24(sp)
    800042d4:	6a42                	ld	s4,16(sp)
    800042d6:	6121                	addi	sp,sp,64
    800042d8:	8082                	ret
    iput(ip);
    800042da:	00000097          	auipc	ra,0x0
    800042de:	a30080e7          	jalr	-1488(ra) # 80003d0a <iput>
    return -1;
    800042e2:	557d                	li	a0,-1
    800042e4:	b7dd                	j	800042ca <dirlink+0x86>
      panic("dirlink read");
    800042e6:	00004517          	auipc	a0,0x4
    800042ea:	3f250513          	addi	a0,a0,1010 # 800086d8 <syscalls+0x1e0>
    800042ee:	ffffc097          	auipc	ra,0xffffc
    800042f2:	250080e7          	jalr	592(ra) # 8000053e <panic>
    panic("dirlink");
    800042f6:	00004517          	auipc	a0,0x4
    800042fa:	4f250513          	addi	a0,a0,1266 # 800087e8 <syscalls+0x2f0>
    800042fe:	ffffc097          	auipc	ra,0xffffc
    80004302:	240080e7          	jalr	576(ra) # 8000053e <panic>

0000000080004306 <namei>:

struct inode*
namei(char *path)
{
    80004306:	1101                	addi	sp,sp,-32
    80004308:	ec06                	sd	ra,24(sp)
    8000430a:	e822                	sd	s0,16(sp)
    8000430c:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    8000430e:	fe040613          	addi	a2,s0,-32
    80004312:	4581                	li	a1,0
    80004314:	00000097          	auipc	ra,0x0
    80004318:	dd0080e7          	jalr	-560(ra) # 800040e4 <namex>
}
    8000431c:	60e2                	ld	ra,24(sp)
    8000431e:	6442                	ld	s0,16(sp)
    80004320:	6105                	addi	sp,sp,32
    80004322:	8082                	ret

0000000080004324 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80004324:	1141                	addi	sp,sp,-16
    80004326:	e406                	sd	ra,8(sp)
    80004328:	e022                	sd	s0,0(sp)
    8000432a:	0800                	addi	s0,sp,16
    8000432c:	862e                	mv	a2,a1
  return namex(path, 1, name);
    8000432e:	4585                	li	a1,1
    80004330:	00000097          	auipc	ra,0x0
    80004334:	db4080e7          	jalr	-588(ra) # 800040e4 <namex>
}
    80004338:	60a2                	ld	ra,8(sp)
    8000433a:	6402                	ld	s0,0(sp)
    8000433c:	0141                	addi	sp,sp,16
    8000433e:	8082                	ret

0000000080004340 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80004340:	1101                	addi	sp,sp,-32
    80004342:	ec06                	sd	ra,24(sp)
    80004344:	e822                	sd	s0,16(sp)
    80004346:	e426                	sd	s1,8(sp)
    80004348:	e04a                	sd	s2,0(sp)
    8000434a:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    8000434c:	0001d917          	auipc	s2,0x1d
    80004350:	74490913          	addi	s2,s2,1860 # 80021a90 <log>
    80004354:	01892583          	lw	a1,24(s2)
    80004358:	02892503          	lw	a0,40(s2)
    8000435c:	fffff097          	auipc	ra,0xfffff
    80004360:	ff2080e7          	jalr	-14(ra) # 8000334e <bread>
    80004364:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80004366:	02c92683          	lw	a3,44(s2)
    8000436a:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    8000436c:	02d05763          	blez	a3,8000439a <write_head+0x5a>
    80004370:	0001d797          	auipc	a5,0x1d
    80004374:	75078793          	addi	a5,a5,1872 # 80021ac0 <log+0x30>
    80004378:	05c50713          	addi	a4,a0,92
    8000437c:	36fd                	addiw	a3,a3,-1
    8000437e:	1682                	slli	a3,a3,0x20
    80004380:	9281                	srli	a3,a3,0x20
    80004382:	068a                	slli	a3,a3,0x2
    80004384:	0001d617          	auipc	a2,0x1d
    80004388:	74060613          	addi	a2,a2,1856 # 80021ac4 <log+0x34>
    8000438c:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    8000438e:	4390                	lw	a2,0(a5)
    80004390:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004392:	0791                	addi	a5,a5,4
    80004394:	0711                	addi	a4,a4,4
    80004396:	fed79ce3          	bne	a5,a3,8000438e <write_head+0x4e>
  }
  bwrite(buf);
    8000439a:	8526                	mv	a0,s1
    8000439c:	fffff097          	auipc	ra,0xfffff
    800043a0:	0a4080e7          	jalr	164(ra) # 80003440 <bwrite>
  brelse(buf);
    800043a4:	8526                	mv	a0,s1
    800043a6:	fffff097          	auipc	ra,0xfffff
    800043aa:	0d8080e7          	jalr	216(ra) # 8000347e <brelse>
}
    800043ae:	60e2                	ld	ra,24(sp)
    800043b0:	6442                	ld	s0,16(sp)
    800043b2:	64a2                	ld	s1,8(sp)
    800043b4:	6902                	ld	s2,0(sp)
    800043b6:	6105                	addi	sp,sp,32
    800043b8:	8082                	ret

00000000800043ba <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    800043ba:	0001d797          	auipc	a5,0x1d
    800043be:	7027a783          	lw	a5,1794(a5) # 80021abc <log+0x2c>
    800043c2:	0af05d63          	blez	a5,8000447c <install_trans+0xc2>
{
    800043c6:	7139                	addi	sp,sp,-64
    800043c8:	fc06                	sd	ra,56(sp)
    800043ca:	f822                	sd	s0,48(sp)
    800043cc:	f426                	sd	s1,40(sp)
    800043ce:	f04a                	sd	s2,32(sp)
    800043d0:	ec4e                	sd	s3,24(sp)
    800043d2:	e852                	sd	s4,16(sp)
    800043d4:	e456                	sd	s5,8(sp)
    800043d6:	e05a                	sd	s6,0(sp)
    800043d8:	0080                	addi	s0,sp,64
    800043da:	8b2a                	mv	s6,a0
    800043dc:	0001da97          	auipc	s5,0x1d
    800043e0:	6e4a8a93          	addi	s5,s5,1764 # 80021ac0 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    800043e4:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800043e6:	0001d997          	auipc	s3,0x1d
    800043ea:	6aa98993          	addi	s3,s3,1706 # 80021a90 <log>
    800043ee:	a035                	j	8000441a <install_trans+0x60>
      bunpin(dbuf);
    800043f0:	8526                	mv	a0,s1
    800043f2:	fffff097          	auipc	ra,0xfffff
    800043f6:	166080e7          	jalr	358(ra) # 80003558 <bunpin>
    brelse(lbuf);
    800043fa:	854a                	mv	a0,s2
    800043fc:	fffff097          	auipc	ra,0xfffff
    80004400:	082080e7          	jalr	130(ra) # 8000347e <brelse>
    brelse(dbuf);
    80004404:	8526                	mv	a0,s1
    80004406:	fffff097          	auipc	ra,0xfffff
    8000440a:	078080e7          	jalr	120(ra) # 8000347e <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000440e:	2a05                	addiw	s4,s4,1
    80004410:	0a91                	addi	s5,s5,4
    80004412:	02c9a783          	lw	a5,44(s3)
    80004416:	04fa5963          	bge	s4,a5,80004468 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    8000441a:	0189a583          	lw	a1,24(s3)
    8000441e:	014585bb          	addw	a1,a1,s4
    80004422:	2585                	addiw	a1,a1,1
    80004424:	0289a503          	lw	a0,40(s3)
    80004428:	fffff097          	auipc	ra,0xfffff
    8000442c:	f26080e7          	jalr	-218(ra) # 8000334e <bread>
    80004430:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80004432:	000aa583          	lw	a1,0(s5)
    80004436:	0289a503          	lw	a0,40(s3)
    8000443a:	fffff097          	auipc	ra,0xfffff
    8000443e:	f14080e7          	jalr	-236(ra) # 8000334e <bread>
    80004442:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80004444:	40000613          	li	a2,1024
    80004448:	05890593          	addi	a1,s2,88
    8000444c:	05850513          	addi	a0,a0,88
    80004450:	ffffd097          	auipc	ra,0xffffd
    80004454:	8f0080e7          	jalr	-1808(ra) # 80000d40 <memmove>
    bwrite(dbuf);  // write dst to disk
    80004458:	8526                	mv	a0,s1
    8000445a:	fffff097          	auipc	ra,0xfffff
    8000445e:	fe6080e7          	jalr	-26(ra) # 80003440 <bwrite>
    if(recovering == 0)
    80004462:	f80b1ce3          	bnez	s6,800043fa <install_trans+0x40>
    80004466:	b769                	j	800043f0 <install_trans+0x36>
}
    80004468:	70e2                	ld	ra,56(sp)
    8000446a:	7442                	ld	s0,48(sp)
    8000446c:	74a2                	ld	s1,40(sp)
    8000446e:	7902                	ld	s2,32(sp)
    80004470:	69e2                	ld	s3,24(sp)
    80004472:	6a42                	ld	s4,16(sp)
    80004474:	6aa2                	ld	s5,8(sp)
    80004476:	6b02                	ld	s6,0(sp)
    80004478:	6121                	addi	sp,sp,64
    8000447a:	8082                	ret
    8000447c:	8082                	ret

000000008000447e <initlog>:
{
    8000447e:	7179                	addi	sp,sp,-48
    80004480:	f406                	sd	ra,40(sp)
    80004482:	f022                	sd	s0,32(sp)
    80004484:	ec26                	sd	s1,24(sp)
    80004486:	e84a                	sd	s2,16(sp)
    80004488:	e44e                	sd	s3,8(sp)
    8000448a:	1800                	addi	s0,sp,48
    8000448c:	892a                	mv	s2,a0
    8000448e:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80004490:	0001d497          	auipc	s1,0x1d
    80004494:	60048493          	addi	s1,s1,1536 # 80021a90 <log>
    80004498:	00004597          	auipc	a1,0x4
    8000449c:	25058593          	addi	a1,a1,592 # 800086e8 <syscalls+0x1f0>
    800044a0:	8526                	mv	a0,s1
    800044a2:	ffffc097          	auipc	ra,0xffffc
    800044a6:	6b2080e7          	jalr	1714(ra) # 80000b54 <initlock>
  log.start = sb->logstart;
    800044aa:	0149a583          	lw	a1,20(s3)
    800044ae:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    800044b0:	0109a783          	lw	a5,16(s3)
    800044b4:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    800044b6:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    800044ba:	854a                	mv	a0,s2
    800044bc:	fffff097          	auipc	ra,0xfffff
    800044c0:	e92080e7          	jalr	-366(ra) # 8000334e <bread>
  log.lh.n = lh->n;
    800044c4:	4d3c                	lw	a5,88(a0)
    800044c6:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    800044c8:	02f05563          	blez	a5,800044f2 <initlog+0x74>
    800044cc:	05c50713          	addi	a4,a0,92
    800044d0:	0001d697          	auipc	a3,0x1d
    800044d4:	5f068693          	addi	a3,a3,1520 # 80021ac0 <log+0x30>
    800044d8:	37fd                	addiw	a5,a5,-1
    800044da:	1782                	slli	a5,a5,0x20
    800044dc:	9381                	srli	a5,a5,0x20
    800044de:	078a                	slli	a5,a5,0x2
    800044e0:	06050613          	addi	a2,a0,96
    800044e4:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    800044e6:	4310                	lw	a2,0(a4)
    800044e8:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    800044ea:	0711                	addi	a4,a4,4
    800044ec:	0691                	addi	a3,a3,4
    800044ee:	fef71ce3          	bne	a4,a5,800044e6 <initlog+0x68>
  brelse(buf);
    800044f2:	fffff097          	auipc	ra,0xfffff
    800044f6:	f8c080e7          	jalr	-116(ra) # 8000347e <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    800044fa:	4505                	li	a0,1
    800044fc:	00000097          	auipc	ra,0x0
    80004500:	ebe080e7          	jalr	-322(ra) # 800043ba <install_trans>
  log.lh.n = 0;
    80004504:	0001d797          	auipc	a5,0x1d
    80004508:	5a07ac23          	sw	zero,1464(a5) # 80021abc <log+0x2c>
  write_head(); // clear the log
    8000450c:	00000097          	auipc	ra,0x0
    80004510:	e34080e7          	jalr	-460(ra) # 80004340 <write_head>
}
    80004514:	70a2                	ld	ra,40(sp)
    80004516:	7402                	ld	s0,32(sp)
    80004518:	64e2                	ld	s1,24(sp)
    8000451a:	6942                	ld	s2,16(sp)
    8000451c:	69a2                	ld	s3,8(sp)
    8000451e:	6145                	addi	sp,sp,48
    80004520:	8082                	ret

0000000080004522 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80004522:	1101                	addi	sp,sp,-32
    80004524:	ec06                	sd	ra,24(sp)
    80004526:	e822                	sd	s0,16(sp)
    80004528:	e426                	sd	s1,8(sp)
    8000452a:	e04a                	sd	s2,0(sp)
    8000452c:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    8000452e:	0001d517          	auipc	a0,0x1d
    80004532:	56250513          	addi	a0,a0,1378 # 80021a90 <log>
    80004536:	ffffc097          	auipc	ra,0xffffc
    8000453a:	6ae080e7          	jalr	1710(ra) # 80000be4 <acquire>
  while(1){
    if(log.committing){
    8000453e:	0001d497          	auipc	s1,0x1d
    80004542:	55248493          	addi	s1,s1,1362 # 80021a90 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004546:	4979                	li	s2,30
    80004548:	a039                	j	80004556 <begin_op+0x34>
      sleep(&log, &log.lock);
    8000454a:	85a6                	mv	a1,s1
    8000454c:	8526                	mv	a0,s1
    8000454e:	ffffe097          	auipc	ra,0xffffe
    80004552:	e2c080e7          	jalr	-468(ra) # 8000237a <sleep>
    if(log.committing){
    80004556:	50dc                	lw	a5,36(s1)
    80004558:	fbed                	bnez	a5,8000454a <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    8000455a:	509c                	lw	a5,32(s1)
    8000455c:	0017871b          	addiw	a4,a5,1
    80004560:	0007069b          	sext.w	a3,a4
    80004564:	0027179b          	slliw	a5,a4,0x2
    80004568:	9fb9                	addw	a5,a5,a4
    8000456a:	0017979b          	slliw	a5,a5,0x1
    8000456e:	54d8                	lw	a4,44(s1)
    80004570:	9fb9                	addw	a5,a5,a4
    80004572:	00f95963          	bge	s2,a5,80004584 <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80004576:	85a6                	mv	a1,s1
    80004578:	8526                	mv	a0,s1
    8000457a:	ffffe097          	auipc	ra,0xffffe
    8000457e:	e00080e7          	jalr	-512(ra) # 8000237a <sleep>
    80004582:	bfd1                	j	80004556 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    80004584:	0001d517          	auipc	a0,0x1d
    80004588:	50c50513          	addi	a0,a0,1292 # 80021a90 <log>
    8000458c:	d114                	sw	a3,32(a0)
      release(&log.lock);
    8000458e:	ffffc097          	auipc	ra,0xffffc
    80004592:	70a080e7          	jalr	1802(ra) # 80000c98 <release>
      break;
    }
  }
}
    80004596:	60e2                	ld	ra,24(sp)
    80004598:	6442                	ld	s0,16(sp)
    8000459a:	64a2                	ld	s1,8(sp)
    8000459c:	6902                	ld	s2,0(sp)
    8000459e:	6105                	addi	sp,sp,32
    800045a0:	8082                	ret

00000000800045a2 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    800045a2:	7139                	addi	sp,sp,-64
    800045a4:	fc06                	sd	ra,56(sp)
    800045a6:	f822                	sd	s0,48(sp)
    800045a8:	f426                	sd	s1,40(sp)
    800045aa:	f04a                	sd	s2,32(sp)
    800045ac:	ec4e                	sd	s3,24(sp)
    800045ae:	e852                	sd	s4,16(sp)
    800045b0:	e456                	sd	s5,8(sp)
    800045b2:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    800045b4:	0001d497          	auipc	s1,0x1d
    800045b8:	4dc48493          	addi	s1,s1,1244 # 80021a90 <log>
    800045bc:	8526                	mv	a0,s1
    800045be:	ffffc097          	auipc	ra,0xffffc
    800045c2:	626080e7          	jalr	1574(ra) # 80000be4 <acquire>
  log.outstanding -= 1;
    800045c6:	509c                	lw	a5,32(s1)
    800045c8:	37fd                	addiw	a5,a5,-1
    800045ca:	0007891b          	sext.w	s2,a5
    800045ce:	d09c                	sw	a5,32(s1)
  if(log.committing)
    800045d0:	50dc                	lw	a5,36(s1)
    800045d2:	efb9                	bnez	a5,80004630 <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    800045d4:	06091663          	bnez	s2,80004640 <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    800045d8:	0001d497          	auipc	s1,0x1d
    800045dc:	4b848493          	addi	s1,s1,1208 # 80021a90 <log>
    800045e0:	4785                	li	a5,1
    800045e2:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    800045e4:	8526                	mv	a0,s1
    800045e6:	ffffc097          	auipc	ra,0xffffc
    800045ea:	6b2080e7          	jalr	1714(ra) # 80000c98 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    800045ee:	54dc                	lw	a5,44(s1)
    800045f0:	06f04763          	bgtz	a5,8000465e <end_op+0xbc>
    acquire(&log.lock);
    800045f4:	0001d497          	auipc	s1,0x1d
    800045f8:	49c48493          	addi	s1,s1,1180 # 80021a90 <log>
    800045fc:	8526                	mv	a0,s1
    800045fe:	ffffc097          	auipc	ra,0xffffc
    80004602:	5e6080e7          	jalr	1510(ra) # 80000be4 <acquire>
    log.committing = 0;
    80004606:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    8000460a:	8526                	mv	a0,s1
    8000460c:	ffffe097          	auipc	ra,0xffffe
    80004610:	f0e080e7          	jalr	-242(ra) # 8000251a <wakeup>
    release(&log.lock);
    80004614:	8526                	mv	a0,s1
    80004616:	ffffc097          	auipc	ra,0xffffc
    8000461a:	682080e7          	jalr	1666(ra) # 80000c98 <release>
}
    8000461e:	70e2                	ld	ra,56(sp)
    80004620:	7442                	ld	s0,48(sp)
    80004622:	74a2                	ld	s1,40(sp)
    80004624:	7902                	ld	s2,32(sp)
    80004626:	69e2                	ld	s3,24(sp)
    80004628:	6a42                	ld	s4,16(sp)
    8000462a:	6aa2                	ld	s5,8(sp)
    8000462c:	6121                	addi	sp,sp,64
    8000462e:	8082                	ret
    panic("log.committing");
    80004630:	00004517          	auipc	a0,0x4
    80004634:	0c050513          	addi	a0,a0,192 # 800086f0 <syscalls+0x1f8>
    80004638:	ffffc097          	auipc	ra,0xffffc
    8000463c:	f06080e7          	jalr	-250(ra) # 8000053e <panic>
    wakeup(&log);
    80004640:	0001d497          	auipc	s1,0x1d
    80004644:	45048493          	addi	s1,s1,1104 # 80021a90 <log>
    80004648:	8526                	mv	a0,s1
    8000464a:	ffffe097          	auipc	ra,0xffffe
    8000464e:	ed0080e7          	jalr	-304(ra) # 8000251a <wakeup>
  release(&log.lock);
    80004652:	8526                	mv	a0,s1
    80004654:	ffffc097          	auipc	ra,0xffffc
    80004658:	644080e7          	jalr	1604(ra) # 80000c98 <release>
  if(do_commit){
    8000465c:	b7c9                	j	8000461e <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000465e:	0001da97          	auipc	s5,0x1d
    80004662:	462a8a93          	addi	s5,s5,1122 # 80021ac0 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80004666:	0001da17          	auipc	s4,0x1d
    8000466a:	42aa0a13          	addi	s4,s4,1066 # 80021a90 <log>
    8000466e:	018a2583          	lw	a1,24(s4)
    80004672:	012585bb          	addw	a1,a1,s2
    80004676:	2585                	addiw	a1,a1,1
    80004678:	028a2503          	lw	a0,40(s4)
    8000467c:	fffff097          	auipc	ra,0xfffff
    80004680:	cd2080e7          	jalr	-814(ra) # 8000334e <bread>
    80004684:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004686:	000aa583          	lw	a1,0(s5)
    8000468a:	028a2503          	lw	a0,40(s4)
    8000468e:	fffff097          	auipc	ra,0xfffff
    80004692:	cc0080e7          	jalr	-832(ra) # 8000334e <bread>
    80004696:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004698:	40000613          	li	a2,1024
    8000469c:	05850593          	addi	a1,a0,88
    800046a0:	05848513          	addi	a0,s1,88
    800046a4:	ffffc097          	auipc	ra,0xffffc
    800046a8:	69c080e7          	jalr	1692(ra) # 80000d40 <memmove>
    bwrite(to);  // write the log
    800046ac:	8526                	mv	a0,s1
    800046ae:	fffff097          	auipc	ra,0xfffff
    800046b2:	d92080e7          	jalr	-622(ra) # 80003440 <bwrite>
    brelse(from);
    800046b6:	854e                	mv	a0,s3
    800046b8:	fffff097          	auipc	ra,0xfffff
    800046bc:	dc6080e7          	jalr	-570(ra) # 8000347e <brelse>
    brelse(to);
    800046c0:	8526                	mv	a0,s1
    800046c2:	fffff097          	auipc	ra,0xfffff
    800046c6:	dbc080e7          	jalr	-580(ra) # 8000347e <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800046ca:	2905                	addiw	s2,s2,1
    800046cc:	0a91                	addi	s5,s5,4
    800046ce:	02ca2783          	lw	a5,44(s4)
    800046d2:	f8f94ee3          	blt	s2,a5,8000466e <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    800046d6:	00000097          	auipc	ra,0x0
    800046da:	c6a080e7          	jalr	-918(ra) # 80004340 <write_head>
    install_trans(0); // Now install writes to home locations
    800046de:	4501                	li	a0,0
    800046e0:	00000097          	auipc	ra,0x0
    800046e4:	cda080e7          	jalr	-806(ra) # 800043ba <install_trans>
    log.lh.n = 0;
    800046e8:	0001d797          	auipc	a5,0x1d
    800046ec:	3c07aa23          	sw	zero,980(a5) # 80021abc <log+0x2c>
    write_head();    // Erase the transaction from the log
    800046f0:	00000097          	auipc	ra,0x0
    800046f4:	c50080e7          	jalr	-944(ra) # 80004340 <write_head>
    800046f8:	bdf5                	j	800045f4 <end_op+0x52>

00000000800046fa <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    800046fa:	1101                	addi	sp,sp,-32
    800046fc:	ec06                	sd	ra,24(sp)
    800046fe:	e822                	sd	s0,16(sp)
    80004700:	e426                	sd	s1,8(sp)
    80004702:	e04a                	sd	s2,0(sp)
    80004704:	1000                	addi	s0,sp,32
    80004706:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    80004708:	0001d917          	auipc	s2,0x1d
    8000470c:	38890913          	addi	s2,s2,904 # 80021a90 <log>
    80004710:	854a                	mv	a0,s2
    80004712:	ffffc097          	auipc	ra,0xffffc
    80004716:	4d2080e7          	jalr	1234(ra) # 80000be4 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    8000471a:	02c92603          	lw	a2,44(s2)
    8000471e:	47f5                	li	a5,29
    80004720:	06c7c563          	blt	a5,a2,8000478a <log_write+0x90>
    80004724:	0001d797          	auipc	a5,0x1d
    80004728:	3887a783          	lw	a5,904(a5) # 80021aac <log+0x1c>
    8000472c:	37fd                	addiw	a5,a5,-1
    8000472e:	04f65e63          	bge	a2,a5,8000478a <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80004732:	0001d797          	auipc	a5,0x1d
    80004736:	37e7a783          	lw	a5,894(a5) # 80021ab0 <log+0x20>
    8000473a:	06f05063          	blez	a5,8000479a <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    8000473e:	4781                	li	a5,0
    80004740:	06c05563          	blez	a2,800047aa <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004744:	44cc                	lw	a1,12(s1)
    80004746:	0001d717          	auipc	a4,0x1d
    8000474a:	37a70713          	addi	a4,a4,890 # 80021ac0 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    8000474e:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004750:	4314                	lw	a3,0(a4)
    80004752:	04b68c63          	beq	a3,a1,800047aa <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    80004756:	2785                	addiw	a5,a5,1
    80004758:	0711                	addi	a4,a4,4
    8000475a:	fef61be3          	bne	a2,a5,80004750 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    8000475e:	0621                	addi	a2,a2,8
    80004760:	060a                	slli	a2,a2,0x2
    80004762:	0001d797          	auipc	a5,0x1d
    80004766:	32e78793          	addi	a5,a5,814 # 80021a90 <log>
    8000476a:	963e                	add	a2,a2,a5
    8000476c:	44dc                	lw	a5,12(s1)
    8000476e:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004770:	8526                	mv	a0,s1
    80004772:	fffff097          	auipc	ra,0xfffff
    80004776:	daa080e7          	jalr	-598(ra) # 8000351c <bpin>
    log.lh.n++;
    8000477a:	0001d717          	auipc	a4,0x1d
    8000477e:	31670713          	addi	a4,a4,790 # 80021a90 <log>
    80004782:	575c                	lw	a5,44(a4)
    80004784:	2785                	addiw	a5,a5,1
    80004786:	d75c                	sw	a5,44(a4)
    80004788:	a835                	j	800047c4 <log_write+0xca>
    panic("too big a transaction");
    8000478a:	00004517          	auipc	a0,0x4
    8000478e:	f7650513          	addi	a0,a0,-138 # 80008700 <syscalls+0x208>
    80004792:	ffffc097          	auipc	ra,0xffffc
    80004796:	dac080e7          	jalr	-596(ra) # 8000053e <panic>
    panic("log_write outside of trans");
    8000479a:	00004517          	auipc	a0,0x4
    8000479e:	f7e50513          	addi	a0,a0,-130 # 80008718 <syscalls+0x220>
    800047a2:	ffffc097          	auipc	ra,0xffffc
    800047a6:	d9c080e7          	jalr	-612(ra) # 8000053e <panic>
  log.lh.block[i] = b->blockno;
    800047aa:	00878713          	addi	a4,a5,8
    800047ae:	00271693          	slli	a3,a4,0x2
    800047b2:	0001d717          	auipc	a4,0x1d
    800047b6:	2de70713          	addi	a4,a4,734 # 80021a90 <log>
    800047ba:	9736                	add	a4,a4,a3
    800047bc:	44d4                	lw	a3,12(s1)
    800047be:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    800047c0:	faf608e3          	beq	a2,a5,80004770 <log_write+0x76>
  }
  release(&log.lock);
    800047c4:	0001d517          	auipc	a0,0x1d
    800047c8:	2cc50513          	addi	a0,a0,716 # 80021a90 <log>
    800047cc:	ffffc097          	auipc	ra,0xffffc
    800047d0:	4cc080e7          	jalr	1228(ra) # 80000c98 <release>
}
    800047d4:	60e2                	ld	ra,24(sp)
    800047d6:	6442                	ld	s0,16(sp)
    800047d8:	64a2                	ld	s1,8(sp)
    800047da:	6902                	ld	s2,0(sp)
    800047dc:	6105                	addi	sp,sp,32
    800047de:	8082                	ret

00000000800047e0 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    800047e0:	1101                	addi	sp,sp,-32
    800047e2:	ec06                	sd	ra,24(sp)
    800047e4:	e822                	sd	s0,16(sp)
    800047e6:	e426                	sd	s1,8(sp)
    800047e8:	e04a                	sd	s2,0(sp)
    800047ea:	1000                	addi	s0,sp,32
    800047ec:	84aa                	mv	s1,a0
    800047ee:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    800047f0:	00004597          	auipc	a1,0x4
    800047f4:	f4858593          	addi	a1,a1,-184 # 80008738 <syscalls+0x240>
    800047f8:	0521                	addi	a0,a0,8
    800047fa:	ffffc097          	auipc	ra,0xffffc
    800047fe:	35a080e7          	jalr	858(ra) # 80000b54 <initlock>
  lk->name = name;
    80004802:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80004806:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    8000480a:	0204a423          	sw	zero,40(s1)
}
    8000480e:	60e2                	ld	ra,24(sp)
    80004810:	6442                	ld	s0,16(sp)
    80004812:	64a2                	ld	s1,8(sp)
    80004814:	6902                	ld	s2,0(sp)
    80004816:	6105                	addi	sp,sp,32
    80004818:	8082                	ret

000000008000481a <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    8000481a:	1101                	addi	sp,sp,-32
    8000481c:	ec06                	sd	ra,24(sp)
    8000481e:	e822                	sd	s0,16(sp)
    80004820:	e426                	sd	s1,8(sp)
    80004822:	e04a                	sd	s2,0(sp)
    80004824:	1000                	addi	s0,sp,32
    80004826:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004828:	00850913          	addi	s2,a0,8
    8000482c:	854a                	mv	a0,s2
    8000482e:	ffffc097          	auipc	ra,0xffffc
    80004832:	3b6080e7          	jalr	950(ra) # 80000be4 <acquire>
  while (lk->locked) {
    80004836:	409c                	lw	a5,0(s1)
    80004838:	cb89                	beqz	a5,8000484a <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    8000483a:	85ca                	mv	a1,s2
    8000483c:	8526                	mv	a0,s1
    8000483e:	ffffe097          	auipc	ra,0xffffe
    80004842:	b3c080e7          	jalr	-1220(ra) # 8000237a <sleep>
  while (lk->locked) {
    80004846:	409c                	lw	a5,0(s1)
    80004848:	fbed                	bnez	a5,8000483a <acquiresleep+0x20>
  }
  lk->locked = 1;
    8000484a:	4785                	li	a5,1
    8000484c:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    8000484e:	ffffd097          	auipc	ra,0xffffd
    80004852:	17a080e7          	jalr	378(ra) # 800019c8 <myproc>
    80004856:	591c                	lw	a5,48(a0)
    80004858:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    8000485a:	854a                	mv	a0,s2
    8000485c:	ffffc097          	auipc	ra,0xffffc
    80004860:	43c080e7          	jalr	1084(ra) # 80000c98 <release>
}
    80004864:	60e2                	ld	ra,24(sp)
    80004866:	6442                	ld	s0,16(sp)
    80004868:	64a2                	ld	s1,8(sp)
    8000486a:	6902                	ld	s2,0(sp)
    8000486c:	6105                	addi	sp,sp,32
    8000486e:	8082                	ret

0000000080004870 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004870:	1101                	addi	sp,sp,-32
    80004872:	ec06                	sd	ra,24(sp)
    80004874:	e822                	sd	s0,16(sp)
    80004876:	e426                	sd	s1,8(sp)
    80004878:	e04a                	sd	s2,0(sp)
    8000487a:	1000                	addi	s0,sp,32
    8000487c:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    8000487e:	00850913          	addi	s2,a0,8
    80004882:	854a                	mv	a0,s2
    80004884:	ffffc097          	auipc	ra,0xffffc
    80004888:	360080e7          	jalr	864(ra) # 80000be4 <acquire>
  lk->locked = 0;
    8000488c:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004890:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004894:	8526                	mv	a0,s1
    80004896:	ffffe097          	auipc	ra,0xffffe
    8000489a:	c84080e7          	jalr	-892(ra) # 8000251a <wakeup>
  release(&lk->lk);
    8000489e:	854a                	mv	a0,s2
    800048a0:	ffffc097          	auipc	ra,0xffffc
    800048a4:	3f8080e7          	jalr	1016(ra) # 80000c98 <release>
}
    800048a8:	60e2                	ld	ra,24(sp)
    800048aa:	6442                	ld	s0,16(sp)
    800048ac:	64a2                	ld	s1,8(sp)
    800048ae:	6902                	ld	s2,0(sp)
    800048b0:	6105                	addi	sp,sp,32
    800048b2:	8082                	ret

00000000800048b4 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    800048b4:	7179                	addi	sp,sp,-48
    800048b6:	f406                	sd	ra,40(sp)
    800048b8:	f022                	sd	s0,32(sp)
    800048ba:	ec26                	sd	s1,24(sp)
    800048bc:	e84a                	sd	s2,16(sp)
    800048be:	e44e                	sd	s3,8(sp)
    800048c0:	1800                	addi	s0,sp,48
    800048c2:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    800048c4:	00850913          	addi	s2,a0,8
    800048c8:	854a                	mv	a0,s2
    800048ca:	ffffc097          	auipc	ra,0xffffc
    800048ce:	31a080e7          	jalr	794(ra) # 80000be4 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    800048d2:	409c                	lw	a5,0(s1)
    800048d4:	ef99                	bnez	a5,800048f2 <holdingsleep+0x3e>
    800048d6:	4481                	li	s1,0
  release(&lk->lk);
    800048d8:	854a                	mv	a0,s2
    800048da:	ffffc097          	auipc	ra,0xffffc
    800048de:	3be080e7          	jalr	958(ra) # 80000c98 <release>
  return r;
}
    800048e2:	8526                	mv	a0,s1
    800048e4:	70a2                	ld	ra,40(sp)
    800048e6:	7402                	ld	s0,32(sp)
    800048e8:	64e2                	ld	s1,24(sp)
    800048ea:	6942                	ld	s2,16(sp)
    800048ec:	69a2                	ld	s3,8(sp)
    800048ee:	6145                	addi	sp,sp,48
    800048f0:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    800048f2:	0284a983          	lw	s3,40(s1)
    800048f6:	ffffd097          	auipc	ra,0xffffd
    800048fa:	0d2080e7          	jalr	210(ra) # 800019c8 <myproc>
    800048fe:	5904                	lw	s1,48(a0)
    80004900:	413484b3          	sub	s1,s1,s3
    80004904:	0014b493          	seqz	s1,s1
    80004908:	bfc1                	j	800048d8 <holdingsleep+0x24>

000000008000490a <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    8000490a:	1141                	addi	sp,sp,-16
    8000490c:	e406                	sd	ra,8(sp)
    8000490e:	e022                	sd	s0,0(sp)
    80004910:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004912:	00004597          	auipc	a1,0x4
    80004916:	e3658593          	addi	a1,a1,-458 # 80008748 <syscalls+0x250>
    8000491a:	0001d517          	auipc	a0,0x1d
    8000491e:	2be50513          	addi	a0,a0,702 # 80021bd8 <ftable>
    80004922:	ffffc097          	auipc	ra,0xffffc
    80004926:	232080e7          	jalr	562(ra) # 80000b54 <initlock>
}
    8000492a:	60a2                	ld	ra,8(sp)
    8000492c:	6402                	ld	s0,0(sp)
    8000492e:	0141                	addi	sp,sp,16
    80004930:	8082                	ret

0000000080004932 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004932:	1101                	addi	sp,sp,-32
    80004934:	ec06                	sd	ra,24(sp)
    80004936:	e822                	sd	s0,16(sp)
    80004938:	e426                	sd	s1,8(sp)
    8000493a:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    8000493c:	0001d517          	auipc	a0,0x1d
    80004940:	29c50513          	addi	a0,a0,668 # 80021bd8 <ftable>
    80004944:	ffffc097          	auipc	ra,0xffffc
    80004948:	2a0080e7          	jalr	672(ra) # 80000be4 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    8000494c:	0001d497          	auipc	s1,0x1d
    80004950:	2a448493          	addi	s1,s1,676 # 80021bf0 <ftable+0x18>
    80004954:	0001e717          	auipc	a4,0x1e
    80004958:	23c70713          	addi	a4,a4,572 # 80022b90 <ftable+0xfb8>
    if(f->ref == 0){
    8000495c:	40dc                	lw	a5,4(s1)
    8000495e:	cf99                	beqz	a5,8000497c <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004960:	02848493          	addi	s1,s1,40
    80004964:	fee49ce3          	bne	s1,a4,8000495c <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004968:	0001d517          	auipc	a0,0x1d
    8000496c:	27050513          	addi	a0,a0,624 # 80021bd8 <ftable>
    80004970:	ffffc097          	auipc	ra,0xffffc
    80004974:	328080e7          	jalr	808(ra) # 80000c98 <release>
  return 0;
    80004978:	4481                	li	s1,0
    8000497a:	a819                	j	80004990 <filealloc+0x5e>
      f->ref = 1;
    8000497c:	4785                	li	a5,1
    8000497e:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004980:	0001d517          	auipc	a0,0x1d
    80004984:	25850513          	addi	a0,a0,600 # 80021bd8 <ftable>
    80004988:	ffffc097          	auipc	ra,0xffffc
    8000498c:	310080e7          	jalr	784(ra) # 80000c98 <release>
}
    80004990:	8526                	mv	a0,s1
    80004992:	60e2                	ld	ra,24(sp)
    80004994:	6442                	ld	s0,16(sp)
    80004996:	64a2                	ld	s1,8(sp)
    80004998:	6105                	addi	sp,sp,32
    8000499a:	8082                	ret

000000008000499c <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    8000499c:	1101                	addi	sp,sp,-32
    8000499e:	ec06                	sd	ra,24(sp)
    800049a0:	e822                	sd	s0,16(sp)
    800049a2:	e426                	sd	s1,8(sp)
    800049a4:	1000                	addi	s0,sp,32
    800049a6:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    800049a8:	0001d517          	auipc	a0,0x1d
    800049ac:	23050513          	addi	a0,a0,560 # 80021bd8 <ftable>
    800049b0:	ffffc097          	auipc	ra,0xffffc
    800049b4:	234080e7          	jalr	564(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    800049b8:	40dc                	lw	a5,4(s1)
    800049ba:	02f05263          	blez	a5,800049de <filedup+0x42>
    panic("filedup");
  f->ref++;
    800049be:	2785                	addiw	a5,a5,1
    800049c0:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    800049c2:	0001d517          	auipc	a0,0x1d
    800049c6:	21650513          	addi	a0,a0,534 # 80021bd8 <ftable>
    800049ca:	ffffc097          	auipc	ra,0xffffc
    800049ce:	2ce080e7          	jalr	718(ra) # 80000c98 <release>
  return f;
}
    800049d2:	8526                	mv	a0,s1
    800049d4:	60e2                	ld	ra,24(sp)
    800049d6:	6442                	ld	s0,16(sp)
    800049d8:	64a2                	ld	s1,8(sp)
    800049da:	6105                	addi	sp,sp,32
    800049dc:	8082                	ret
    panic("filedup");
    800049de:	00004517          	auipc	a0,0x4
    800049e2:	d7250513          	addi	a0,a0,-654 # 80008750 <syscalls+0x258>
    800049e6:	ffffc097          	auipc	ra,0xffffc
    800049ea:	b58080e7          	jalr	-1192(ra) # 8000053e <panic>

00000000800049ee <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    800049ee:	7139                	addi	sp,sp,-64
    800049f0:	fc06                	sd	ra,56(sp)
    800049f2:	f822                	sd	s0,48(sp)
    800049f4:	f426                	sd	s1,40(sp)
    800049f6:	f04a                	sd	s2,32(sp)
    800049f8:	ec4e                	sd	s3,24(sp)
    800049fa:	e852                	sd	s4,16(sp)
    800049fc:	e456                	sd	s5,8(sp)
    800049fe:	0080                	addi	s0,sp,64
    80004a00:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004a02:	0001d517          	auipc	a0,0x1d
    80004a06:	1d650513          	addi	a0,a0,470 # 80021bd8 <ftable>
    80004a0a:	ffffc097          	auipc	ra,0xffffc
    80004a0e:	1da080e7          	jalr	474(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    80004a12:	40dc                	lw	a5,4(s1)
    80004a14:	06f05163          	blez	a5,80004a76 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004a18:	37fd                	addiw	a5,a5,-1
    80004a1a:	0007871b          	sext.w	a4,a5
    80004a1e:	c0dc                	sw	a5,4(s1)
    80004a20:	06e04363          	bgtz	a4,80004a86 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004a24:	0004a903          	lw	s2,0(s1)
    80004a28:	0094ca83          	lbu	s5,9(s1)
    80004a2c:	0104ba03          	ld	s4,16(s1)
    80004a30:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004a34:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004a38:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004a3c:	0001d517          	auipc	a0,0x1d
    80004a40:	19c50513          	addi	a0,a0,412 # 80021bd8 <ftable>
    80004a44:	ffffc097          	auipc	ra,0xffffc
    80004a48:	254080e7          	jalr	596(ra) # 80000c98 <release>

  if(ff.type == FD_PIPE){
    80004a4c:	4785                	li	a5,1
    80004a4e:	04f90d63          	beq	s2,a5,80004aa8 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004a52:	3979                	addiw	s2,s2,-2
    80004a54:	4785                	li	a5,1
    80004a56:	0527e063          	bltu	a5,s2,80004a96 <fileclose+0xa8>
    begin_op();
    80004a5a:	00000097          	auipc	ra,0x0
    80004a5e:	ac8080e7          	jalr	-1336(ra) # 80004522 <begin_op>
    iput(ff.ip);
    80004a62:	854e                	mv	a0,s3
    80004a64:	fffff097          	auipc	ra,0xfffff
    80004a68:	2a6080e7          	jalr	678(ra) # 80003d0a <iput>
    end_op();
    80004a6c:	00000097          	auipc	ra,0x0
    80004a70:	b36080e7          	jalr	-1226(ra) # 800045a2 <end_op>
    80004a74:	a00d                	j	80004a96 <fileclose+0xa8>
    panic("fileclose");
    80004a76:	00004517          	auipc	a0,0x4
    80004a7a:	ce250513          	addi	a0,a0,-798 # 80008758 <syscalls+0x260>
    80004a7e:	ffffc097          	auipc	ra,0xffffc
    80004a82:	ac0080e7          	jalr	-1344(ra) # 8000053e <panic>
    release(&ftable.lock);
    80004a86:	0001d517          	auipc	a0,0x1d
    80004a8a:	15250513          	addi	a0,a0,338 # 80021bd8 <ftable>
    80004a8e:	ffffc097          	auipc	ra,0xffffc
    80004a92:	20a080e7          	jalr	522(ra) # 80000c98 <release>
  }
}
    80004a96:	70e2                	ld	ra,56(sp)
    80004a98:	7442                	ld	s0,48(sp)
    80004a9a:	74a2                	ld	s1,40(sp)
    80004a9c:	7902                	ld	s2,32(sp)
    80004a9e:	69e2                	ld	s3,24(sp)
    80004aa0:	6a42                	ld	s4,16(sp)
    80004aa2:	6aa2                	ld	s5,8(sp)
    80004aa4:	6121                	addi	sp,sp,64
    80004aa6:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004aa8:	85d6                	mv	a1,s5
    80004aaa:	8552                	mv	a0,s4
    80004aac:	00000097          	auipc	ra,0x0
    80004ab0:	34c080e7          	jalr	844(ra) # 80004df8 <pipeclose>
    80004ab4:	b7cd                	j	80004a96 <fileclose+0xa8>

0000000080004ab6 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004ab6:	715d                	addi	sp,sp,-80
    80004ab8:	e486                	sd	ra,72(sp)
    80004aba:	e0a2                	sd	s0,64(sp)
    80004abc:	fc26                	sd	s1,56(sp)
    80004abe:	f84a                	sd	s2,48(sp)
    80004ac0:	f44e                	sd	s3,40(sp)
    80004ac2:	0880                	addi	s0,sp,80
    80004ac4:	84aa                	mv	s1,a0
    80004ac6:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004ac8:	ffffd097          	auipc	ra,0xffffd
    80004acc:	f00080e7          	jalr	-256(ra) # 800019c8 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004ad0:	409c                	lw	a5,0(s1)
    80004ad2:	37f9                	addiw	a5,a5,-2
    80004ad4:	4705                	li	a4,1
    80004ad6:	04f76763          	bltu	a4,a5,80004b24 <filestat+0x6e>
    80004ada:	892a                	mv	s2,a0
    ilock(f->ip);
    80004adc:	6c88                	ld	a0,24(s1)
    80004ade:	fffff097          	auipc	ra,0xfffff
    80004ae2:	072080e7          	jalr	114(ra) # 80003b50 <ilock>
    stati(f->ip, &st);
    80004ae6:	fb840593          	addi	a1,s0,-72
    80004aea:	6c88                	ld	a0,24(s1)
    80004aec:	fffff097          	auipc	ra,0xfffff
    80004af0:	2ee080e7          	jalr	750(ra) # 80003dda <stati>
    iunlock(f->ip);
    80004af4:	6c88                	ld	a0,24(s1)
    80004af6:	fffff097          	auipc	ra,0xfffff
    80004afa:	11c080e7          	jalr	284(ra) # 80003c12 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004afe:	46e1                	li	a3,24
    80004b00:	fb840613          	addi	a2,s0,-72
    80004b04:	85ce                	mv	a1,s3
    80004b06:	07093503          	ld	a0,112(s2)
    80004b0a:	ffffd097          	auipc	ra,0xffffd
    80004b0e:	b70080e7          	jalr	-1168(ra) # 8000167a <copyout>
    80004b12:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004b16:	60a6                	ld	ra,72(sp)
    80004b18:	6406                	ld	s0,64(sp)
    80004b1a:	74e2                	ld	s1,56(sp)
    80004b1c:	7942                	ld	s2,48(sp)
    80004b1e:	79a2                	ld	s3,40(sp)
    80004b20:	6161                	addi	sp,sp,80
    80004b22:	8082                	ret
  return -1;
    80004b24:	557d                	li	a0,-1
    80004b26:	bfc5                	j	80004b16 <filestat+0x60>

0000000080004b28 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004b28:	7179                	addi	sp,sp,-48
    80004b2a:	f406                	sd	ra,40(sp)
    80004b2c:	f022                	sd	s0,32(sp)
    80004b2e:	ec26                	sd	s1,24(sp)
    80004b30:	e84a                	sd	s2,16(sp)
    80004b32:	e44e                	sd	s3,8(sp)
    80004b34:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004b36:	00854783          	lbu	a5,8(a0)
    80004b3a:	c3d5                	beqz	a5,80004bde <fileread+0xb6>
    80004b3c:	84aa                	mv	s1,a0
    80004b3e:	89ae                	mv	s3,a1
    80004b40:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004b42:	411c                	lw	a5,0(a0)
    80004b44:	4705                	li	a4,1
    80004b46:	04e78963          	beq	a5,a4,80004b98 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004b4a:	470d                	li	a4,3
    80004b4c:	04e78d63          	beq	a5,a4,80004ba6 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004b50:	4709                	li	a4,2
    80004b52:	06e79e63          	bne	a5,a4,80004bce <fileread+0xa6>
    ilock(f->ip);
    80004b56:	6d08                	ld	a0,24(a0)
    80004b58:	fffff097          	auipc	ra,0xfffff
    80004b5c:	ff8080e7          	jalr	-8(ra) # 80003b50 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004b60:	874a                	mv	a4,s2
    80004b62:	5094                	lw	a3,32(s1)
    80004b64:	864e                	mv	a2,s3
    80004b66:	4585                	li	a1,1
    80004b68:	6c88                	ld	a0,24(s1)
    80004b6a:	fffff097          	auipc	ra,0xfffff
    80004b6e:	29a080e7          	jalr	666(ra) # 80003e04 <readi>
    80004b72:	892a                	mv	s2,a0
    80004b74:	00a05563          	blez	a0,80004b7e <fileread+0x56>
      f->off += r;
    80004b78:	509c                	lw	a5,32(s1)
    80004b7a:	9fa9                	addw	a5,a5,a0
    80004b7c:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004b7e:	6c88                	ld	a0,24(s1)
    80004b80:	fffff097          	auipc	ra,0xfffff
    80004b84:	092080e7          	jalr	146(ra) # 80003c12 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004b88:	854a                	mv	a0,s2
    80004b8a:	70a2                	ld	ra,40(sp)
    80004b8c:	7402                	ld	s0,32(sp)
    80004b8e:	64e2                	ld	s1,24(sp)
    80004b90:	6942                	ld	s2,16(sp)
    80004b92:	69a2                	ld	s3,8(sp)
    80004b94:	6145                	addi	sp,sp,48
    80004b96:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004b98:	6908                	ld	a0,16(a0)
    80004b9a:	00000097          	auipc	ra,0x0
    80004b9e:	3c8080e7          	jalr	968(ra) # 80004f62 <piperead>
    80004ba2:	892a                	mv	s2,a0
    80004ba4:	b7d5                	j	80004b88 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004ba6:	02451783          	lh	a5,36(a0)
    80004baa:	03079693          	slli	a3,a5,0x30
    80004bae:	92c1                	srli	a3,a3,0x30
    80004bb0:	4725                	li	a4,9
    80004bb2:	02d76863          	bltu	a4,a3,80004be2 <fileread+0xba>
    80004bb6:	0792                	slli	a5,a5,0x4
    80004bb8:	0001d717          	auipc	a4,0x1d
    80004bbc:	f8070713          	addi	a4,a4,-128 # 80021b38 <devsw>
    80004bc0:	97ba                	add	a5,a5,a4
    80004bc2:	639c                	ld	a5,0(a5)
    80004bc4:	c38d                	beqz	a5,80004be6 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004bc6:	4505                	li	a0,1
    80004bc8:	9782                	jalr	a5
    80004bca:	892a                	mv	s2,a0
    80004bcc:	bf75                	j	80004b88 <fileread+0x60>
    panic("fileread");
    80004bce:	00004517          	auipc	a0,0x4
    80004bd2:	b9a50513          	addi	a0,a0,-1126 # 80008768 <syscalls+0x270>
    80004bd6:	ffffc097          	auipc	ra,0xffffc
    80004bda:	968080e7          	jalr	-1688(ra) # 8000053e <panic>
    return -1;
    80004bde:	597d                	li	s2,-1
    80004be0:	b765                	j	80004b88 <fileread+0x60>
      return -1;
    80004be2:	597d                	li	s2,-1
    80004be4:	b755                	j	80004b88 <fileread+0x60>
    80004be6:	597d                	li	s2,-1
    80004be8:	b745                	j	80004b88 <fileread+0x60>

0000000080004bea <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80004bea:	715d                	addi	sp,sp,-80
    80004bec:	e486                	sd	ra,72(sp)
    80004bee:	e0a2                	sd	s0,64(sp)
    80004bf0:	fc26                	sd	s1,56(sp)
    80004bf2:	f84a                	sd	s2,48(sp)
    80004bf4:	f44e                	sd	s3,40(sp)
    80004bf6:	f052                	sd	s4,32(sp)
    80004bf8:	ec56                	sd	s5,24(sp)
    80004bfa:	e85a                	sd	s6,16(sp)
    80004bfc:	e45e                	sd	s7,8(sp)
    80004bfe:	e062                	sd	s8,0(sp)
    80004c00:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80004c02:	00954783          	lbu	a5,9(a0)
    80004c06:	10078663          	beqz	a5,80004d12 <filewrite+0x128>
    80004c0a:	892a                	mv	s2,a0
    80004c0c:	8aae                	mv	s5,a1
    80004c0e:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004c10:	411c                	lw	a5,0(a0)
    80004c12:	4705                	li	a4,1
    80004c14:	02e78263          	beq	a5,a4,80004c38 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004c18:	470d                	li	a4,3
    80004c1a:	02e78663          	beq	a5,a4,80004c46 <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004c1e:	4709                	li	a4,2
    80004c20:	0ee79163          	bne	a5,a4,80004d02 <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004c24:	0ac05d63          	blez	a2,80004cde <filewrite+0xf4>
    int i = 0;
    80004c28:	4981                	li	s3,0
    80004c2a:	6b05                	lui	s6,0x1
    80004c2c:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80004c30:	6b85                	lui	s7,0x1
    80004c32:	c00b8b9b          	addiw	s7,s7,-1024
    80004c36:	a861                	j	80004cce <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80004c38:	6908                	ld	a0,16(a0)
    80004c3a:	00000097          	auipc	ra,0x0
    80004c3e:	22e080e7          	jalr	558(ra) # 80004e68 <pipewrite>
    80004c42:	8a2a                	mv	s4,a0
    80004c44:	a045                	j	80004ce4 <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004c46:	02451783          	lh	a5,36(a0)
    80004c4a:	03079693          	slli	a3,a5,0x30
    80004c4e:	92c1                	srli	a3,a3,0x30
    80004c50:	4725                	li	a4,9
    80004c52:	0cd76263          	bltu	a4,a3,80004d16 <filewrite+0x12c>
    80004c56:	0792                	slli	a5,a5,0x4
    80004c58:	0001d717          	auipc	a4,0x1d
    80004c5c:	ee070713          	addi	a4,a4,-288 # 80021b38 <devsw>
    80004c60:	97ba                	add	a5,a5,a4
    80004c62:	679c                	ld	a5,8(a5)
    80004c64:	cbdd                	beqz	a5,80004d1a <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80004c66:	4505                	li	a0,1
    80004c68:	9782                	jalr	a5
    80004c6a:	8a2a                	mv	s4,a0
    80004c6c:	a8a5                	j	80004ce4 <filewrite+0xfa>
    80004c6e:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004c72:	00000097          	auipc	ra,0x0
    80004c76:	8b0080e7          	jalr	-1872(ra) # 80004522 <begin_op>
      ilock(f->ip);
    80004c7a:	01893503          	ld	a0,24(s2)
    80004c7e:	fffff097          	auipc	ra,0xfffff
    80004c82:	ed2080e7          	jalr	-302(ra) # 80003b50 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004c86:	8762                	mv	a4,s8
    80004c88:	02092683          	lw	a3,32(s2)
    80004c8c:	01598633          	add	a2,s3,s5
    80004c90:	4585                	li	a1,1
    80004c92:	01893503          	ld	a0,24(s2)
    80004c96:	fffff097          	auipc	ra,0xfffff
    80004c9a:	266080e7          	jalr	614(ra) # 80003efc <writei>
    80004c9e:	84aa                	mv	s1,a0
    80004ca0:	00a05763          	blez	a0,80004cae <filewrite+0xc4>
        f->off += r;
    80004ca4:	02092783          	lw	a5,32(s2)
    80004ca8:	9fa9                	addw	a5,a5,a0
    80004caa:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004cae:	01893503          	ld	a0,24(s2)
    80004cb2:	fffff097          	auipc	ra,0xfffff
    80004cb6:	f60080e7          	jalr	-160(ra) # 80003c12 <iunlock>
      end_op();
    80004cba:	00000097          	auipc	ra,0x0
    80004cbe:	8e8080e7          	jalr	-1816(ra) # 800045a2 <end_op>

      if(r != n1){
    80004cc2:	009c1f63          	bne	s8,s1,80004ce0 <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80004cc6:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004cca:	0149db63          	bge	s3,s4,80004ce0 <filewrite+0xf6>
      int n1 = n - i;
    80004cce:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80004cd2:	84be                	mv	s1,a5
    80004cd4:	2781                	sext.w	a5,a5
    80004cd6:	f8fb5ce3          	bge	s6,a5,80004c6e <filewrite+0x84>
    80004cda:	84de                	mv	s1,s7
    80004cdc:	bf49                	j	80004c6e <filewrite+0x84>
    int i = 0;
    80004cde:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004ce0:	013a1f63          	bne	s4,s3,80004cfe <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004ce4:	8552                	mv	a0,s4
    80004ce6:	60a6                	ld	ra,72(sp)
    80004ce8:	6406                	ld	s0,64(sp)
    80004cea:	74e2                	ld	s1,56(sp)
    80004cec:	7942                	ld	s2,48(sp)
    80004cee:	79a2                	ld	s3,40(sp)
    80004cf0:	7a02                	ld	s4,32(sp)
    80004cf2:	6ae2                	ld	s5,24(sp)
    80004cf4:	6b42                	ld	s6,16(sp)
    80004cf6:	6ba2                	ld	s7,8(sp)
    80004cf8:	6c02                	ld	s8,0(sp)
    80004cfa:	6161                	addi	sp,sp,80
    80004cfc:	8082                	ret
    ret = (i == n ? n : -1);
    80004cfe:	5a7d                	li	s4,-1
    80004d00:	b7d5                	j	80004ce4 <filewrite+0xfa>
    panic("filewrite");
    80004d02:	00004517          	auipc	a0,0x4
    80004d06:	a7650513          	addi	a0,a0,-1418 # 80008778 <syscalls+0x280>
    80004d0a:	ffffc097          	auipc	ra,0xffffc
    80004d0e:	834080e7          	jalr	-1996(ra) # 8000053e <panic>
    return -1;
    80004d12:	5a7d                	li	s4,-1
    80004d14:	bfc1                	j	80004ce4 <filewrite+0xfa>
      return -1;
    80004d16:	5a7d                	li	s4,-1
    80004d18:	b7f1                	j	80004ce4 <filewrite+0xfa>
    80004d1a:	5a7d                	li	s4,-1
    80004d1c:	b7e1                	j	80004ce4 <filewrite+0xfa>

0000000080004d1e <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004d1e:	7179                	addi	sp,sp,-48
    80004d20:	f406                	sd	ra,40(sp)
    80004d22:	f022                	sd	s0,32(sp)
    80004d24:	ec26                	sd	s1,24(sp)
    80004d26:	e84a                	sd	s2,16(sp)
    80004d28:	e44e                	sd	s3,8(sp)
    80004d2a:	e052                	sd	s4,0(sp)
    80004d2c:	1800                	addi	s0,sp,48
    80004d2e:	84aa                	mv	s1,a0
    80004d30:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004d32:	0005b023          	sd	zero,0(a1)
    80004d36:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004d3a:	00000097          	auipc	ra,0x0
    80004d3e:	bf8080e7          	jalr	-1032(ra) # 80004932 <filealloc>
    80004d42:	e088                	sd	a0,0(s1)
    80004d44:	c551                	beqz	a0,80004dd0 <pipealloc+0xb2>
    80004d46:	00000097          	auipc	ra,0x0
    80004d4a:	bec080e7          	jalr	-1044(ra) # 80004932 <filealloc>
    80004d4e:	00aa3023          	sd	a0,0(s4)
    80004d52:	c92d                	beqz	a0,80004dc4 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004d54:	ffffc097          	auipc	ra,0xffffc
    80004d58:	da0080e7          	jalr	-608(ra) # 80000af4 <kalloc>
    80004d5c:	892a                	mv	s2,a0
    80004d5e:	c125                	beqz	a0,80004dbe <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004d60:	4985                	li	s3,1
    80004d62:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004d66:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004d6a:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004d6e:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004d72:	00004597          	auipc	a1,0x4
    80004d76:	a1658593          	addi	a1,a1,-1514 # 80008788 <syscalls+0x290>
    80004d7a:	ffffc097          	auipc	ra,0xffffc
    80004d7e:	dda080e7          	jalr	-550(ra) # 80000b54 <initlock>
  (*f0)->type = FD_PIPE;
    80004d82:	609c                	ld	a5,0(s1)
    80004d84:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004d88:	609c                	ld	a5,0(s1)
    80004d8a:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004d8e:	609c                	ld	a5,0(s1)
    80004d90:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004d94:	609c                	ld	a5,0(s1)
    80004d96:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004d9a:	000a3783          	ld	a5,0(s4)
    80004d9e:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004da2:	000a3783          	ld	a5,0(s4)
    80004da6:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004daa:	000a3783          	ld	a5,0(s4)
    80004dae:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004db2:	000a3783          	ld	a5,0(s4)
    80004db6:	0127b823          	sd	s2,16(a5)
  return 0;
    80004dba:	4501                	li	a0,0
    80004dbc:	a025                	j	80004de4 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004dbe:	6088                	ld	a0,0(s1)
    80004dc0:	e501                	bnez	a0,80004dc8 <pipealloc+0xaa>
    80004dc2:	a039                	j	80004dd0 <pipealloc+0xb2>
    80004dc4:	6088                	ld	a0,0(s1)
    80004dc6:	c51d                	beqz	a0,80004df4 <pipealloc+0xd6>
    fileclose(*f0);
    80004dc8:	00000097          	auipc	ra,0x0
    80004dcc:	c26080e7          	jalr	-986(ra) # 800049ee <fileclose>
  if(*f1)
    80004dd0:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004dd4:	557d                	li	a0,-1
  if(*f1)
    80004dd6:	c799                	beqz	a5,80004de4 <pipealloc+0xc6>
    fileclose(*f1);
    80004dd8:	853e                	mv	a0,a5
    80004dda:	00000097          	auipc	ra,0x0
    80004dde:	c14080e7          	jalr	-1004(ra) # 800049ee <fileclose>
  return -1;
    80004de2:	557d                	li	a0,-1
}
    80004de4:	70a2                	ld	ra,40(sp)
    80004de6:	7402                	ld	s0,32(sp)
    80004de8:	64e2                	ld	s1,24(sp)
    80004dea:	6942                	ld	s2,16(sp)
    80004dec:	69a2                	ld	s3,8(sp)
    80004dee:	6a02                	ld	s4,0(sp)
    80004df0:	6145                	addi	sp,sp,48
    80004df2:	8082                	ret
  return -1;
    80004df4:	557d                	li	a0,-1
    80004df6:	b7fd                	j	80004de4 <pipealloc+0xc6>

0000000080004df8 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004df8:	1101                	addi	sp,sp,-32
    80004dfa:	ec06                	sd	ra,24(sp)
    80004dfc:	e822                	sd	s0,16(sp)
    80004dfe:	e426                	sd	s1,8(sp)
    80004e00:	e04a                	sd	s2,0(sp)
    80004e02:	1000                	addi	s0,sp,32
    80004e04:	84aa                	mv	s1,a0
    80004e06:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004e08:	ffffc097          	auipc	ra,0xffffc
    80004e0c:	ddc080e7          	jalr	-548(ra) # 80000be4 <acquire>
  if(writable){
    80004e10:	02090d63          	beqz	s2,80004e4a <pipeclose+0x52>
    pi->writeopen = 0;
    80004e14:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004e18:	21848513          	addi	a0,s1,536
    80004e1c:	ffffd097          	auipc	ra,0xffffd
    80004e20:	6fe080e7          	jalr	1790(ra) # 8000251a <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004e24:	2204b783          	ld	a5,544(s1)
    80004e28:	eb95                	bnez	a5,80004e5c <pipeclose+0x64>
    release(&pi->lock);
    80004e2a:	8526                	mv	a0,s1
    80004e2c:	ffffc097          	auipc	ra,0xffffc
    80004e30:	e6c080e7          	jalr	-404(ra) # 80000c98 <release>
    kfree((char*)pi);
    80004e34:	8526                	mv	a0,s1
    80004e36:	ffffc097          	auipc	ra,0xffffc
    80004e3a:	bc2080e7          	jalr	-1086(ra) # 800009f8 <kfree>
  } else
    release(&pi->lock);
}
    80004e3e:	60e2                	ld	ra,24(sp)
    80004e40:	6442                	ld	s0,16(sp)
    80004e42:	64a2                	ld	s1,8(sp)
    80004e44:	6902                	ld	s2,0(sp)
    80004e46:	6105                	addi	sp,sp,32
    80004e48:	8082                	ret
    pi->readopen = 0;
    80004e4a:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004e4e:	21c48513          	addi	a0,s1,540
    80004e52:	ffffd097          	auipc	ra,0xffffd
    80004e56:	6c8080e7          	jalr	1736(ra) # 8000251a <wakeup>
    80004e5a:	b7e9                	j	80004e24 <pipeclose+0x2c>
    release(&pi->lock);
    80004e5c:	8526                	mv	a0,s1
    80004e5e:	ffffc097          	auipc	ra,0xffffc
    80004e62:	e3a080e7          	jalr	-454(ra) # 80000c98 <release>
}
    80004e66:	bfe1                	j	80004e3e <pipeclose+0x46>

0000000080004e68 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004e68:	7159                	addi	sp,sp,-112
    80004e6a:	f486                	sd	ra,104(sp)
    80004e6c:	f0a2                	sd	s0,96(sp)
    80004e6e:	eca6                	sd	s1,88(sp)
    80004e70:	e8ca                	sd	s2,80(sp)
    80004e72:	e4ce                	sd	s3,72(sp)
    80004e74:	e0d2                	sd	s4,64(sp)
    80004e76:	fc56                	sd	s5,56(sp)
    80004e78:	f85a                	sd	s6,48(sp)
    80004e7a:	f45e                	sd	s7,40(sp)
    80004e7c:	f062                	sd	s8,32(sp)
    80004e7e:	ec66                	sd	s9,24(sp)
    80004e80:	1880                	addi	s0,sp,112
    80004e82:	84aa                	mv	s1,a0
    80004e84:	8aae                	mv	s5,a1
    80004e86:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004e88:	ffffd097          	auipc	ra,0xffffd
    80004e8c:	b40080e7          	jalr	-1216(ra) # 800019c8 <myproc>
    80004e90:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004e92:	8526                	mv	a0,s1
    80004e94:	ffffc097          	auipc	ra,0xffffc
    80004e98:	d50080e7          	jalr	-688(ra) # 80000be4 <acquire>
  while(i < n){
    80004e9c:	0d405163          	blez	s4,80004f5e <pipewrite+0xf6>
    80004ea0:	8ba6                	mv	s7,s1
  int i = 0;
    80004ea2:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004ea4:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004ea6:	21848c93          	addi	s9,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004eaa:	21c48c13          	addi	s8,s1,540
    80004eae:	a08d                	j	80004f10 <pipewrite+0xa8>
      release(&pi->lock);
    80004eb0:	8526                	mv	a0,s1
    80004eb2:	ffffc097          	auipc	ra,0xffffc
    80004eb6:	de6080e7          	jalr	-538(ra) # 80000c98 <release>
      return -1;
    80004eba:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004ebc:	854a                	mv	a0,s2
    80004ebe:	70a6                	ld	ra,104(sp)
    80004ec0:	7406                	ld	s0,96(sp)
    80004ec2:	64e6                	ld	s1,88(sp)
    80004ec4:	6946                	ld	s2,80(sp)
    80004ec6:	69a6                	ld	s3,72(sp)
    80004ec8:	6a06                	ld	s4,64(sp)
    80004eca:	7ae2                	ld	s5,56(sp)
    80004ecc:	7b42                	ld	s6,48(sp)
    80004ece:	7ba2                	ld	s7,40(sp)
    80004ed0:	7c02                	ld	s8,32(sp)
    80004ed2:	6ce2                	ld	s9,24(sp)
    80004ed4:	6165                	addi	sp,sp,112
    80004ed6:	8082                	ret
      wakeup(&pi->nread);
    80004ed8:	8566                	mv	a0,s9
    80004eda:	ffffd097          	auipc	ra,0xffffd
    80004ede:	640080e7          	jalr	1600(ra) # 8000251a <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004ee2:	85de                	mv	a1,s7
    80004ee4:	8562                	mv	a0,s8
    80004ee6:	ffffd097          	auipc	ra,0xffffd
    80004eea:	494080e7          	jalr	1172(ra) # 8000237a <sleep>
    80004eee:	a839                	j	80004f0c <pipewrite+0xa4>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004ef0:	21c4a783          	lw	a5,540(s1)
    80004ef4:	0017871b          	addiw	a4,a5,1
    80004ef8:	20e4ae23          	sw	a4,540(s1)
    80004efc:	1ff7f793          	andi	a5,a5,511
    80004f00:	97a6                	add	a5,a5,s1
    80004f02:	f9f44703          	lbu	a4,-97(s0)
    80004f06:	00e78c23          	sb	a4,24(a5)
      i++;
    80004f0a:	2905                	addiw	s2,s2,1
  while(i < n){
    80004f0c:	03495d63          	bge	s2,s4,80004f46 <pipewrite+0xde>
    if(pi->readopen == 0 || pr->killed){
    80004f10:	2204a783          	lw	a5,544(s1)
    80004f14:	dfd1                	beqz	a5,80004eb0 <pipewrite+0x48>
    80004f16:	0289a783          	lw	a5,40(s3)
    80004f1a:	fbd9                	bnez	a5,80004eb0 <pipewrite+0x48>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004f1c:	2184a783          	lw	a5,536(s1)
    80004f20:	21c4a703          	lw	a4,540(s1)
    80004f24:	2007879b          	addiw	a5,a5,512
    80004f28:	faf708e3          	beq	a4,a5,80004ed8 <pipewrite+0x70>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004f2c:	4685                	li	a3,1
    80004f2e:	01590633          	add	a2,s2,s5
    80004f32:	f9f40593          	addi	a1,s0,-97
    80004f36:	0709b503          	ld	a0,112(s3)
    80004f3a:	ffffc097          	auipc	ra,0xffffc
    80004f3e:	7cc080e7          	jalr	1996(ra) # 80001706 <copyin>
    80004f42:	fb6517e3          	bne	a0,s6,80004ef0 <pipewrite+0x88>
  wakeup(&pi->nread);
    80004f46:	21848513          	addi	a0,s1,536
    80004f4a:	ffffd097          	auipc	ra,0xffffd
    80004f4e:	5d0080e7          	jalr	1488(ra) # 8000251a <wakeup>
  release(&pi->lock);
    80004f52:	8526                	mv	a0,s1
    80004f54:	ffffc097          	auipc	ra,0xffffc
    80004f58:	d44080e7          	jalr	-700(ra) # 80000c98 <release>
  return i;
    80004f5c:	b785                	j	80004ebc <pipewrite+0x54>
  int i = 0;
    80004f5e:	4901                	li	s2,0
    80004f60:	b7dd                	j	80004f46 <pipewrite+0xde>

0000000080004f62 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004f62:	715d                	addi	sp,sp,-80
    80004f64:	e486                	sd	ra,72(sp)
    80004f66:	e0a2                	sd	s0,64(sp)
    80004f68:	fc26                	sd	s1,56(sp)
    80004f6a:	f84a                	sd	s2,48(sp)
    80004f6c:	f44e                	sd	s3,40(sp)
    80004f6e:	f052                	sd	s4,32(sp)
    80004f70:	ec56                	sd	s5,24(sp)
    80004f72:	e85a                	sd	s6,16(sp)
    80004f74:	0880                	addi	s0,sp,80
    80004f76:	84aa                	mv	s1,a0
    80004f78:	892e                	mv	s2,a1
    80004f7a:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004f7c:	ffffd097          	auipc	ra,0xffffd
    80004f80:	a4c080e7          	jalr	-1460(ra) # 800019c8 <myproc>
    80004f84:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004f86:	8b26                	mv	s6,s1
    80004f88:	8526                	mv	a0,s1
    80004f8a:	ffffc097          	auipc	ra,0xffffc
    80004f8e:	c5a080e7          	jalr	-934(ra) # 80000be4 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004f92:	2184a703          	lw	a4,536(s1)
    80004f96:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004f9a:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004f9e:	02f71463          	bne	a4,a5,80004fc6 <piperead+0x64>
    80004fa2:	2244a783          	lw	a5,548(s1)
    80004fa6:	c385                	beqz	a5,80004fc6 <piperead+0x64>
    if(pr->killed){
    80004fa8:	028a2783          	lw	a5,40(s4)
    80004fac:	ebc1                	bnez	a5,8000503c <piperead+0xda>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004fae:	85da                	mv	a1,s6
    80004fb0:	854e                	mv	a0,s3
    80004fb2:	ffffd097          	auipc	ra,0xffffd
    80004fb6:	3c8080e7          	jalr	968(ra) # 8000237a <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004fba:	2184a703          	lw	a4,536(s1)
    80004fbe:	21c4a783          	lw	a5,540(s1)
    80004fc2:	fef700e3          	beq	a4,a5,80004fa2 <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004fc6:	09505263          	blez	s5,8000504a <piperead+0xe8>
    80004fca:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004fcc:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    80004fce:	2184a783          	lw	a5,536(s1)
    80004fd2:	21c4a703          	lw	a4,540(s1)
    80004fd6:	02f70d63          	beq	a4,a5,80005010 <piperead+0xae>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004fda:	0017871b          	addiw	a4,a5,1
    80004fde:	20e4ac23          	sw	a4,536(s1)
    80004fe2:	1ff7f793          	andi	a5,a5,511
    80004fe6:	97a6                	add	a5,a5,s1
    80004fe8:	0187c783          	lbu	a5,24(a5)
    80004fec:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004ff0:	4685                	li	a3,1
    80004ff2:	fbf40613          	addi	a2,s0,-65
    80004ff6:	85ca                	mv	a1,s2
    80004ff8:	070a3503          	ld	a0,112(s4)
    80004ffc:	ffffc097          	auipc	ra,0xffffc
    80005000:	67e080e7          	jalr	1662(ra) # 8000167a <copyout>
    80005004:	01650663          	beq	a0,s6,80005010 <piperead+0xae>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005008:	2985                	addiw	s3,s3,1
    8000500a:	0905                	addi	s2,s2,1
    8000500c:	fd3a91e3          	bne	s5,s3,80004fce <piperead+0x6c>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80005010:	21c48513          	addi	a0,s1,540
    80005014:	ffffd097          	auipc	ra,0xffffd
    80005018:	506080e7          	jalr	1286(ra) # 8000251a <wakeup>
  release(&pi->lock);
    8000501c:	8526                	mv	a0,s1
    8000501e:	ffffc097          	auipc	ra,0xffffc
    80005022:	c7a080e7          	jalr	-902(ra) # 80000c98 <release>
  return i;
}
    80005026:	854e                	mv	a0,s3
    80005028:	60a6                	ld	ra,72(sp)
    8000502a:	6406                	ld	s0,64(sp)
    8000502c:	74e2                	ld	s1,56(sp)
    8000502e:	7942                	ld	s2,48(sp)
    80005030:	79a2                	ld	s3,40(sp)
    80005032:	7a02                	ld	s4,32(sp)
    80005034:	6ae2                	ld	s5,24(sp)
    80005036:	6b42                	ld	s6,16(sp)
    80005038:	6161                	addi	sp,sp,80
    8000503a:	8082                	ret
      release(&pi->lock);
    8000503c:	8526                	mv	a0,s1
    8000503e:	ffffc097          	auipc	ra,0xffffc
    80005042:	c5a080e7          	jalr	-934(ra) # 80000c98 <release>
      return -1;
    80005046:	59fd                	li	s3,-1
    80005048:	bff9                	j	80005026 <piperead+0xc4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    8000504a:	4981                	li	s3,0
    8000504c:	b7d1                	j	80005010 <piperead+0xae>

000000008000504e <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    8000504e:	df010113          	addi	sp,sp,-528
    80005052:	20113423          	sd	ra,520(sp)
    80005056:	20813023          	sd	s0,512(sp)
    8000505a:	ffa6                	sd	s1,504(sp)
    8000505c:	fbca                	sd	s2,496(sp)
    8000505e:	f7ce                	sd	s3,488(sp)
    80005060:	f3d2                	sd	s4,480(sp)
    80005062:	efd6                	sd	s5,472(sp)
    80005064:	ebda                	sd	s6,464(sp)
    80005066:	e7de                	sd	s7,456(sp)
    80005068:	e3e2                	sd	s8,448(sp)
    8000506a:	ff66                	sd	s9,440(sp)
    8000506c:	fb6a                	sd	s10,432(sp)
    8000506e:	f76e                	sd	s11,424(sp)
    80005070:	0c00                	addi	s0,sp,528
    80005072:	84aa                	mv	s1,a0
    80005074:	dea43c23          	sd	a0,-520(s0)
    80005078:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    8000507c:	ffffd097          	auipc	ra,0xffffd
    80005080:	94c080e7          	jalr	-1716(ra) # 800019c8 <myproc>
    80005084:	892a                	mv	s2,a0

  begin_op();
    80005086:	fffff097          	auipc	ra,0xfffff
    8000508a:	49c080e7          	jalr	1180(ra) # 80004522 <begin_op>

  if((ip = namei(path)) == 0){
    8000508e:	8526                	mv	a0,s1
    80005090:	fffff097          	auipc	ra,0xfffff
    80005094:	276080e7          	jalr	630(ra) # 80004306 <namei>
    80005098:	c92d                	beqz	a0,8000510a <exec+0xbc>
    8000509a:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    8000509c:	fffff097          	auipc	ra,0xfffff
    800050a0:	ab4080e7          	jalr	-1356(ra) # 80003b50 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    800050a4:	04000713          	li	a4,64
    800050a8:	4681                	li	a3,0
    800050aa:	e5040613          	addi	a2,s0,-432
    800050ae:	4581                	li	a1,0
    800050b0:	8526                	mv	a0,s1
    800050b2:	fffff097          	auipc	ra,0xfffff
    800050b6:	d52080e7          	jalr	-686(ra) # 80003e04 <readi>
    800050ba:	04000793          	li	a5,64
    800050be:	00f51a63          	bne	a0,a5,800050d2 <exec+0x84>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    800050c2:	e5042703          	lw	a4,-432(s0)
    800050c6:	464c47b7          	lui	a5,0x464c4
    800050ca:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    800050ce:	04f70463          	beq	a4,a5,80005116 <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    800050d2:	8526                	mv	a0,s1
    800050d4:	fffff097          	auipc	ra,0xfffff
    800050d8:	cde080e7          	jalr	-802(ra) # 80003db2 <iunlockput>
    end_op();
    800050dc:	fffff097          	auipc	ra,0xfffff
    800050e0:	4c6080e7          	jalr	1222(ra) # 800045a2 <end_op>
  }
  return -1;
    800050e4:	557d                	li	a0,-1
}
    800050e6:	20813083          	ld	ra,520(sp)
    800050ea:	20013403          	ld	s0,512(sp)
    800050ee:	74fe                	ld	s1,504(sp)
    800050f0:	795e                	ld	s2,496(sp)
    800050f2:	79be                	ld	s3,488(sp)
    800050f4:	7a1e                	ld	s4,480(sp)
    800050f6:	6afe                	ld	s5,472(sp)
    800050f8:	6b5e                	ld	s6,464(sp)
    800050fa:	6bbe                	ld	s7,456(sp)
    800050fc:	6c1e                	ld	s8,448(sp)
    800050fe:	7cfa                	ld	s9,440(sp)
    80005100:	7d5a                	ld	s10,432(sp)
    80005102:	7dba                	ld	s11,424(sp)
    80005104:	21010113          	addi	sp,sp,528
    80005108:	8082                	ret
    end_op();
    8000510a:	fffff097          	auipc	ra,0xfffff
    8000510e:	498080e7          	jalr	1176(ra) # 800045a2 <end_op>
    return -1;
    80005112:	557d                	li	a0,-1
    80005114:	bfc9                	j	800050e6 <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    80005116:	854a                	mv	a0,s2
    80005118:	ffffd097          	auipc	ra,0xffffd
    8000511c:	974080e7          	jalr	-1676(ra) # 80001a8c <proc_pagetable>
    80005120:	8baa                	mv	s7,a0
    80005122:	d945                	beqz	a0,800050d2 <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005124:	e7042983          	lw	s3,-400(s0)
    80005128:	e8845783          	lhu	a5,-376(s0)
    8000512c:	c7ad                	beqz	a5,80005196 <exec+0x148>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    8000512e:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005130:	4b01                	li	s6,0
    if((ph.vaddr % PGSIZE) != 0)
    80005132:	6c85                	lui	s9,0x1
    80005134:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    80005138:	def43823          	sd	a5,-528(s0)
    8000513c:	a42d                	j	80005366 <exec+0x318>
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    8000513e:	00003517          	auipc	a0,0x3
    80005142:	65250513          	addi	a0,a0,1618 # 80008790 <syscalls+0x298>
    80005146:	ffffb097          	auipc	ra,0xffffb
    8000514a:	3f8080e7          	jalr	1016(ra) # 8000053e <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    8000514e:	8756                	mv	a4,s5
    80005150:	012d86bb          	addw	a3,s11,s2
    80005154:	4581                	li	a1,0
    80005156:	8526                	mv	a0,s1
    80005158:	fffff097          	auipc	ra,0xfffff
    8000515c:	cac080e7          	jalr	-852(ra) # 80003e04 <readi>
    80005160:	2501                	sext.w	a0,a0
    80005162:	1aaa9963          	bne	s5,a0,80005314 <exec+0x2c6>
  for(i = 0; i < sz; i += PGSIZE){
    80005166:	6785                	lui	a5,0x1
    80005168:	0127893b          	addw	s2,a5,s2
    8000516c:	77fd                	lui	a5,0xfffff
    8000516e:	01478a3b          	addw	s4,a5,s4
    80005172:	1f897163          	bgeu	s2,s8,80005354 <exec+0x306>
    pa = walkaddr(pagetable, va + i);
    80005176:	02091593          	slli	a1,s2,0x20
    8000517a:	9181                	srli	a1,a1,0x20
    8000517c:	95ea                	add	a1,a1,s10
    8000517e:	855e                	mv	a0,s7
    80005180:	ffffc097          	auipc	ra,0xffffc
    80005184:	ef6080e7          	jalr	-266(ra) # 80001076 <walkaddr>
    80005188:	862a                	mv	a2,a0
    if(pa == 0)
    8000518a:	d955                	beqz	a0,8000513e <exec+0xf0>
      n = PGSIZE;
    8000518c:	8ae6                	mv	s5,s9
    if(sz - i < PGSIZE)
    8000518e:	fd9a70e3          	bgeu	s4,s9,8000514e <exec+0x100>
      n = sz - i;
    80005192:	8ad2                	mv	s5,s4
    80005194:	bf6d                	j	8000514e <exec+0x100>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80005196:	4901                	li	s2,0
  iunlockput(ip);
    80005198:	8526                	mv	a0,s1
    8000519a:	fffff097          	auipc	ra,0xfffff
    8000519e:	c18080e7          	jalr	-1000(ra) # 80003db2 <iunlockput>
  end_op();
    800051a2:	fffff097          	auipc	ra,0xfffff
    800051a6:	400080e7          	jalr	1024(ra) # 800045a2 <end_op>
  p = myproc();
    800051aa:	ffffd097          	auipc	ra,0xffffd
    800051ae:	81e080e7          	jalr	-2018(ra) # 800019c8 <myproc>
    800051b2:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    800051b4:	06853d03          	ld	s10,104(a0)
  sz = PGROUNDUP(sz);
    800051b8:	6785                	lui	a5,0x1
    800051ba:	17fd                	addi	a5,a5,-1
    800051bc:	993e                	add	s2,s2,a5
    800051be:	757d                	lui	a0,0xfffff
    800051c0:	00a977b3          	and	a5,s2,a0
    800051c4:	e0f43423          	sd	a5,-504(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    800051c8:	6609                	lui	a2,0x2
    800051ca:	963e                	add	a2,a2,a5
    800051cc:	85be                	mv	a1,a5
    800051ce:	855e                	mv	a0,s7
    800051d0:	ffffc097          	auipc	ra,0xffffc
    800051d4:	25a080e7          	jalr	602(ra) # 8000142a <uvmalloc>
    800051d8:	8b2a                	mv	s6,a0
  ip = 0;
    800051da:	4481                	li	s1,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    800051dc:	12050c63          	beqz	a0,80005314 <exec+0x2c6>
  uvmclear(pagetable, sz-2*PGSIZE);
    800051e0:	75f9                	lui	a1,0xffffe
    800051e2:	95aa                	add	a1,a1,a0
    800051e4:	855e                	mv	a0,s7
    800051e6:	ffffc097          	auipc	ra,0xffffc
    800051ea:	462080e7          	jalr	1122(ra) # 80001648 <uvmclear>
  stackbase = sp - PGSIZE;
    800051ee:	7c7d                	lui	s8,0xfffff
    800051f0:	9c5a                	add	s8,s8,s6
  for(argc = 0; argv[argc]; argc++) {
    800051f2:	e0043783          	ld	a5,-512(s0)
    800051f6:	6388                	ld	a0,0(a5)
    800051f8:	c535                	beqz	a0,80005264 <exec+0x216>
    800051fa:	e9040993          	addi	s3,s0,-368
    800051fe:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    80005202:	895a                	mv	s2,s6
    sp -= strlen(argv[argc]) + 1;
    80005204:	ffffc097          	auipc	ra,0xffffc
    80005208:	c60080e7          	jalr	-928(ra) # 80000e64 <strlen>
    8000520c:	2505                	addiw	a0,a0,1
    8000520e:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80005212:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80005216:	13896363          	bltu	s2,s8,8000533c <exec+0x2ee>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    8000521a:	e0043d83          	ld	s11,-512(s0)
    8000521e:	000dba03          	ld	s4,0(s11)
    80005222:	8552                	mv	a0,s4
    80005224:	ffffc097          	auipc	ra,0xffffc
    80005228:	c40080e7          	jalr	-960(ra) # 80000e64 <strlen>
    8000522c:	0015069b          	addiw	a3,a0,1
    80005230:	8652                	mv	a2,s4
    80005232:	85ca                	mv	a1,s2
    80005234:	855e                	mv	a0,s7
    80005236:	ffffc097          	auipc	ra,0xffffc
    8000523a:	444080e7          	jalr	1092(ra) # 8000167a <copyout>
    8000523e:	10054363          	bltz	a0,80005344 <exec+0x2f6>
    ustack[argc] = sp;
    80005242:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80005246:	0485                	addi	s1,s1,1
    80005248:	008d8793          	addi	a5,s11,8
    8000524c:	e0f43023          	sd	a5,-512(s0)
    80005250:	008db503          	ld	a0,8(s11)
    80005254:	c911                	beqz	a0,80005268 <exec+0x21a>
    if(argc >= MAXARG)
    80005256:	09a1                	addi	s3,s3,8
    80005258:	fb3c96e3          	bne	s9,s3,80005204 <exec+0x1b6>
  sz = sz1;
    8000525c:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005260:	4481                	li	s1,0
    80005262:	a84d                	j	80005314 <exec+0x2c6>
  sp = sz;
    80005264:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    80005266:	4481                	li	s1,0
  ustack[argc] = 0;
    80005268:	00349793          	slli	a5,s1,0x3
    8000526c:	f9040713          	addi	a4,s0,-112
    80005270:	97ba                	add	a5,a5,a4
    80005272:	f007b023          	sd	zero,-256(a5) # f00 <_entry-0x7ffff100>
  sp -= (argc+1) * sizeof(uint64);
    80005276:	00148693          	addi	a3,s1,1
    8000527a:	068e                	slli	a3,a3,0x3
    8000527c:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80005280:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80005284:	01897663          	bgeu	s2,s8,80005290 <exec+0x242>
  sz = sz1;
    80005288:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    8000528c:	4481                	li	s1,0
    8000528e:	a059                	j	80005314 <exec+0x2c6>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80005290:	e9040613          	addi	a2,s0,-368
    80005294:	85ca                	mv	a1,s2
    80005296:	855e                	mv	a0,s7
    80005298:	ffffc097          	auipc	ra,0xffffc
    8000529c:	3e2080e7          	jalr	994(ra) # 8000167a <copyout>
    800052a0:	0a054663          	bltz	a0,8000534c <exec+0x2fe>
  p->trapframe->a1 = sp;
    800052a4:	078ab783          	ld	a5,120(s5)
    800052a8:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    800052ac:	df843783          	ld	a5,-520(s0)
    800052b0:	0007c703          	lbu	a4,0(a5)
    800052b4:	cf11                	beqz	a4,800052d0 <exec+0x282>
    800052b6:	0785                	addi	a5,a5,1
    if(*s == '/')
    800052b8:	02f00693          	li	a3,47
    800052bc:	a039                	j	800052ca <exec+0x27c>
      last = s+1;
    800052be:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    800052c2:	0785                	addi	a5,a5,1
    800052c4:	fff7c703          	lbu	a4,-1(a5)
    800052c8:	c701                	beqz	a4,800052d0 <exec+0x282>
    if(*s == '/')
    800052ca:	fed71ce3          	bne	a4,a3,800052c2 <exec+0x274>
    800052ce:	bfc5                	j	800052be <exec+0x270>
  safestrcpy(p->name, last, sizeof(p->name));
    800052d0:	4641                	li	a2,16
    800052d2:	df843583          	ld	a1,-520(s0)
    800052d6:	178a8513          	addi	a0,s5,376
    800052da:	ffffc097          	auipc	ra,0xffffc
    800052de:	b58080e7          	jalr	-1192(ra) # 80000e32 <safestrcpy>
  oldpagetable = p->pagetable;
    800052e2:	070ab503          	ld	a0,112(s5)
  p->pagetable = pagetable;
    800052e6:	077ab823          	sd	s7,112(s5)
  p->sz = sz;
    800052ea:	076ab423          	sd	s6,104(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    800052ee:	078ab783          	ld	a5,120(s5)
    800052f2:	e6843703          	ld	a4,-408(s0)
    800052f6:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    800052f8:	078ab783          	ld	a5,120(s5)
    800052fc:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80005300:	85ea                	mv	a1,s10
    80005302:	ffffd097          	auipc	ra,0xffffd
    80005306:	826080e7          	jalr	-2010(ra) # 80001b28 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    8000530a:	0004851b          	sext.w	a0,s1
    8000530e:	bbe1                	j	800050e6 <exec+0x98>
    80005310:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    80005314:	e0843583          	ld	a1,-504(s0)
    80005318:	855e                	mv	a0,s7
    8000531a:	ffffd097          	auipc	ra,0xffffd
    8000531e:	80e080e7          	jalr	-2034(ra) # 80001b28 <proc_freepagetable>
  if(ip){
    80005322:	da0498e3          	bnez	s1,800050d2 <exec+0x84>
  return -1;
    80005326:	557d                	li	a0,-1
    80005328:	bb7d                	j	800050e6 <exec+0x98>
    8000532a:	e1243423          	sd	s2,-504(s0)
    8000532e:	b7dd                	j	80005314 <exec+0x2c6>
    80005330:	e1243423          	sd	s2,-504(s0)
    80005334:	b7c5                	j	80005314 <exec+0x2c6>
    80005336:	e1243423          	sd	s2,-504(s0)
    8000533a:	bfe9                	j	80005314 <exec+0x2c6>
  sz = sz1;
    8000533c:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005340:	4481                	li	s1,0
    80005342:	bfc9                	j	80005314 <exec+0x2c6>
  sz = sz1;
    80005344:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005348:	4481                	li	s1,0
    8000534a:	b7e9                	j	80005314 <exec+0x2c6>
  sz = sz1;
    8000534c:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005350:	4481                	li	s1,0
    80005352:	b7c9                	j	80005314 <exec+0x2c6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80005354:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005358:	2b05                	addiw	s6,s6,1
    8000535a:	0389899b          	addiw	s3,s3,56
    8000535e:	e8845783          	lhu	a5,-376(s0)
    80005362:	e2fb5be3          	bge	s6,a5,80005198 <exec+0x14a>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80005366:	2981                	sext.w	s3,s3
    80005368:	03800713          	li	a4,56
    8000536c:	86ce                	mv	a3,s3
    8000536e:	e1840613          	addi	a2,s0,-488
    80005372:	4581                	li	a1,0
    80005374:	8526                	mv	a0,s1
    80005376:	fffff097          	auipc	ra,0xfffff
    8000537a:	a8e080e7          	jalr	-1394(ra) # 80003e04 <readi>
    8000537e:	03800793          	li	a5,56
    80005382:	f8f517e3          	bne	a0,a5,80005310 <exec+0x2c2>
    if(ph.type != ELF_PROG_LOAD)
    80005386:	e1842783          	lw	a5,-488(s0)
    8000538a:	4705                	li	a4,1
    8000538c:	fce796e3          	bne	a5,a4,80005358 <exec+0x30a>
    if(ph.memsz < ph.filesz)
    80005390:	e4043603          	ld	a2,-448(s0)
    80005394:	e3843783          	ld	a5,-456(s0)
    80005398:	f8f669e3          	bltu	a2,a5,8000532a <exec+0x2dc>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    8000539c:	e2843783          	ld	a5,-472(s0)
    800053a0:	963e                	add	a2,a2,a5
    800053a2:	f8f667e3          	bltu	a2,a5,80005330 <exec+0x2e2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    800053a6:	85ca                	mv	a1,s2
    800053a8:	855e                	mv	a0,s7
    800053aa:	ffffc097          	auipc	ra,0xffffc
    800053ae:	080080e7          	jalr	128(ra) # 8000142a <uvmalloc>
    800053b2:	e0a43423          	sd	a0,-504(s0)
    800053b6:	d141                	beqz	a0,80005336 <exec+0x2e8>
    if((ph.vaddr % PGSIZE) != 0)
    800053b8:	e2843d03          	ld	s10,-472(s0)
    800053bc:	df043783          	ld	a5,-528(s0)
    800053c0:	00fd77b3          	and	a5,s10,a5
    800053c4:	fba1                	bnez	a5,80005314 <exec+0x2c6>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    800053c6:	e2042d83          	lw	s11,-480(s0)
    800053ca:	e3842c03          	lw	s8,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    800053ce:	f80c03e3          	beqz	s8,80005354 <exec+0x306>
    800053d2:	8a62                	mv	s4,s8
    800053d4:	4901                	li	s2,0
    800053d6:	b345                	j	80005176 <exec+0x128>

00000000800053d8 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    800053d8:	7179                	addi	sp,sp,-48
    800053da:	f406                	sd	ra,40(sp)
    800053dc:	f022                	sd	s0,32(sp)
    800053de:	ec26                	sd	s1,24(sp)
    800053e0:	e84a                	sd	s2,16(sp)
    800053e2:	1800                	addi	s0,sp,48
    800053e4:	892e                	mv	s2,a1
    800053e6:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    800053e8:	fdc40593          	addi	a1,s0,-36
    800053ec:	ffffe097          	auipc	ra,0xffffe
    800053f0:	b8a080e7          	jalr	-1142(ra) # 80002f76 <argint>
    800053f4:	04054063          	bltz	a0,80005434 <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    800053f8:	fdc42703          	lw	a4,-36(s0)
    800053fc:	47bd                	li	a5,15
    800053fe:	02e7ed63          	bltu	a5,a4,80005438 <argfd+0x60>
    80005402:	ffffc097          	auipc	ra,0xffffc
    80005406:	5c6080e7          	jalr	1478(ra) # 800019c8 <myproc>
    8000540a:	fdc42703          	lw	a4,-36(s0)
    8000540e:	01e70793          	addi	a5,a4,30
    80005412:	078e                	slli	a5,a5,0x3
    80005414:	953e                	add	a0,a0,a5
    80005416:	611c                	ld	a5,0(a0)
    80005418:	c395                	beqz	a5,8000543c <argfd+0x64>
    return -1;
  if(pfd)
    8000541a:	00090463          	beqz	s2,80005422 <argfd+0x4a>
    *pfd = fd;
    8000541e:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80005422:	4501                	li	a0,0
  if(pf)
    80005424:	c091                	beqz	s1,80005428 <argfd+0x50>
    *pf = f;
    80005426:	e09c                	sd	a5,0(s1)
}
    80005428:	70a2                	ld	ra,40(sp)
    8000542a:	7402                	ld	s0,32(sp)
    8000542c:	64e2                	ld	s1,24(sp)
    8000542e:	6942                	ld	s2,16(sp)
    80005430:	6145                	addi	sp,sp,48
    80005432:	8082                	ret
    return -1;
    80005434:	557d                	li	a0,-1
    80005436:	bfcd                	j	80005428 <argfd+0x50>
    return -1;
    80005438:	557d                	li	a0,-1
    8000543a:	b7fd                	j	80005428 <argfd+0x50>
    8000543c:	557d                	li	a0,-1
    8000543e:	b7ed                	j	80005428 <argfd+0x50>

0000000080005440 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80005440:	1101                	addi	sp,sp,-32
    80005442:	ec06                	sd	ra,24(sp)
    80005444:	e822                	sd	s0,16(sp)
    80005446:	e426                	sd	s1,8(sp)
    80005448:	1000                	addi	s0,sp,32
    8000544a:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    8000544c:	ffffc097          	auipc	ra,0xffffc
    80005450:	57c080e7          	jalr	1404(ra) # 800019c8 <myproc>
    80005454:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80005456:	0f050793          	addi	a5,a0,240 # fffffffffffff0f0 <end+0xffffffff7ffd90f0>
    8000545a:	4501                	li	a0,0
    8000545c:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    8000545e:	6398                	ld	a4,0(a5)
    80005460:	cb19                	beqz	a4,80005476 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80005462:	2505                	addiw	a0,a0,1
    80005464:	07a1                	addi	a5,a5,8
    80005466:	fed51ce3          	bne	a0,a3,8000545e <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    8000546a:	557d                	li	a0,-1
}
    8000546c:	60e2                	ld	ra,24(sp)
    8000546e:	6442                	ld	s0,16(sp)
    80005470:	64a2                	ld	s1,8(sp)
    80005472:	6105                	addi	sp,sp,32
    80005474:	8082                	ret
      p->ofile[fd] = f;
    80005476:	01e50793          	addi	a5,a0,30
    8000547a:	078e                	slli	a5,a5,0x3
    8000547c:	963e                	add	a2,a2,a5
    8000547e:	e204                	sd	s1,0(a2)
      return fd;
    80005480:	b7f5                	j	8000546c <fdalloc+0x2c>

0000000080005482 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80005482:	715d                	addi	sp,sp,-80
    80005484:	e486                	sd	ra,72(sp)
    80005486:	e0a2                	sd	s0,64(sp)
    80005488:	fc26                	sd	s1,56(sp)
    8000548a:	f84a                	sd	s2,48(sp)
    8000548c:	f44e                	sd	s3,40(sp)
    8000548e:	f052                	sd	s4,32(sp)
    80005490:	ec56                	sd	s5,24(sp)
    80005492:	0880                	addi	s0,sp,80
    80005494:	89ae                	mv	s3,a1
    80005496:	8ab2                	mv	s5,a2
    80005498:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    8000549a:	fb040593          	addi	a1,s0,-80
    8000549e:	fffff097          	auipc	ra,0xfffff
    800054a2:	e86080e7          	jalr	-378(ra) # 80004324 <nameiparent>
    800054a6:	892a                	mv	s2,a0
    800054a8:	12050f63          	beqz	a0,800055e6 <create+0x164>
    return 0;

  ilock(dp);
    800054ac:	ffffe097          	auipc	ra,0xffffe
    800054b0:	6a4080e7          	jalr	1700(ra) # 80003b50 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    800054b4:	4601                	li	a2,0
    800054b6:	fb040593          	addi	a1,s0,-80
    800054ba:	854a                	mv	a0,s2
    800054bc:	fffff097          	auipc	ra,0xfffff
    800054c0:	b78080e7          	jalr	-1160(ra) # 80004034 <dirlookup>
    800054c4:	84aa                	mv	s1,a0
    800054c6:	c921                	beqz	a0,80005516 <create+0x94>
    iunlockput(dp);
    800054c8:	854a                	mv	a0,s2
    800054ca:	fffff097          	auipc	ra,0xfffff
    800054ce:	8e8080e7          	jalr	-1816(ra) # 80003db2 <iunlockput>
    ilock(ip);
    800054d2:	8526                	mv	a0,s1
    800054d4:	ffffe097          	auipc	ra,0xffffe
    800054d8:	67c080e7          	jalr	1660(ra) # 80003b50 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    800054dc:	2981                	sext.w	s3,s3
    800054de:	4789                	li	a5,2
    800054e0:	02f99463          	bne	s3,a5,80005508 <create+0x86>
    800054e4:	0444d783          	lhu	a5,68(s1)
    800054e8:	37f9                	addiw	a5,a5,-2
    800054ea:	17c2                	slli	a5,a5,0x30
    800054ec:	93c1                	srli	a5,a5,0x30
    800054ee:	4705                	li	a4,1
    800054f0:	00f76c63          	bltu	a4,a5,80005508 <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    800054f4:	8526                	mv	a0,s1
    800054f6:	60a6                	ld	ra,72(sp)
    800054f8:	6406                	ld	s0,64(sp)
    800054fa:	74e2                	ld	s1,56(sp)
    800054fc:	7942                	ld	s2,48(sp)
    800054fe:	79a2                	ld	s3,40(sp)
    80005500:	7a02                	ld	s4,32(sp)
    80005502:	6ae2                	ld	s5,24(sp)
    80005504:	6161                	addi	sp,sp,80
    80005506:	8082                	ret
    iunlockput(ip);
    80005508:	8526                	mv	a0,s1
    8000550a:	fffff097          	auipc	ra,0xfffff
    8000550e:	8a8080e7          	jalr	-1880(ra) # 80003db2 <iunlockput>
    return 0;
    80005512:	4481                	li	s1,0
    80005514:	b7c5                	j	800054f4 <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    80005516:	85ce                	mv	a1,s3
    80005518:	00092503          	lw	a0,0(s2)
    8000551c:	ffffe097          	auipc	ra,0xffffe
    80005520:	49c080e7          	jalr	1180(ra) # 800039b8 <ialloc>
    80005524:	84aa                	mv	s1,a0
    80005526:	c529                	beqz	a0,80005570 <create+0xee>
  ilock(ip);
    80005528:	ffffe097          	auipc	ra,0xffffe
    8000552c:	628080e7          	jalr	1576(ra) # 80003b50 <ilock>
  ip->major = major;
    80005530:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    80005534:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    80005538:	4785                	li	a5,1
    8000553a:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000553e:	8526                	mv	a0,s1
    80005540:	ffffe097          	auipc	ra,0xffffe
    80005544:	546080e7          	jalr	1350(ra) # 80003a86 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    80005548:	2981                	sext.w	s3,s3
    8000554a:	4785                	li	a5,1
    8000554c:	02f98a63          	beq	s3,a5,80005580 <create+0xfe>
  if(dirlink(dp, name, ip->inum) < 0)
    80005550:	40d0                	lw	a2,4(s1)
    80005552:	fb040593          	addi	a1,s0,-80
    80005556:	854a                	mv	a0,s2
    80005558:	fffff097          	auipc	ra,0xfffff
    8000555c:	cec080e7          	jalr	-788(ra) # 80004244 <dirlink>
    80005560:	06054b63          	bltz	a0,800055d6 <create+0x154>
  iunlockput(dp);
    80005564:	854a                	mv	a0,s2
    80005566:	fffff097          	auipc	ra,0xfffff
    8000556a:	84c080e7          	jalr	-1972(ra) # 80003db2 <iunlockput>
  return ip;
    8000556e:	b759                	j	800054f4 <create+0x72>
    panic("create: ialloc");
    80005570:	00003517          	auipc	a0,0x3
    80005574:	24050513          	addi	a0,a0,576 # 800087b0 <syscalls+0x2b8>
    80005578:	ffffb097          	auipc	ra,0xffffb
    8000557c:	fc6080e7          	jalr	-58(ra) # 8000053e <panic>
    dp->nlink++;  // for ".."
    80005580:	04a95783          	lhu	a5,74(s2)
    80005584:	2785                	addiw	a5,a5,1
    80005586:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    8000558a:	854a                	mv	a0,s2
    8000558c:	ffffe097          	auipc	ra,0xffffe
    80005590:	4fa080e7          	jalr	1274(ra) # 80003a86 <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80005594:	40d0                	lw	a2,4(s1)
    80005596:	00003597          	auipc	a1,0x3
    8000559a:	22a58593          	addi	a1,a1,554 # 800087c0 <syscalls+0x2c8>
    8000559e:	8526                	mv	a0,s1
    800055a0:	fffff097          	auipc	ra,0xfffff
    800055a4:	ca4080e7          	jalr	-860(ra) # 80004244 <dirlink>
    800055a8:	00054f63          	bltz	a0,800055c6 <create+0x144>
    800055ac:	00492603          	lw	a2,4(s2)
    800055b0:	00003597          	auipc	a1,0x3
    800055b4:	21858593          	addi	a1,a1,536 # 800087c8 <syscalls+0x2d0>
    800055b8:	8526                	mv	a0,s1
    800055ba:	fffff097          	auipc	ra,0xfffff
    800055be:	c8a080e7          	jalr	-886(ra) # 80004244 <dirlink>
    800055c2:	f80557e3          	bgez	a0,80005550 <create+0xce>
      panic("create dots");
    800055c6:	00003517          	auipc	a0,0x3
    800055ca:	20a50513          	addi	a0,a0,522 # 800087d0 <syscalls+0x2d8>
    800055ce:	ffffb097          	auipc	ra,0xffffb
    800055d2:	f70080e7          	jalr	-144(ra) # 8000053e <panic>
    panic("create: dirlink");
    800055d6:	00003517          	auipc	a0,0x3
    800055da:	20a50513          	addi	a0,a0,522 # 800087e0 <syscalls+0x2e8>
    800055de:	ffffb097          	auipc	ra,0xffffb
    800055e2:	f60080e7          	jalr	-160(ra) # 8000053e <panic>
    return 0;
    800055e6:	84aa                	mv	s1,a0
    800055e8:	b731                	j	800054f4 <create+0x72>

00000000800055ea <sys_dup>:
{
    800055ea:	7179                	addi	sp,sp,-48
    800055ec:	f406                	sd	ra,40(sp)
    800055ee:	f022                	sd	s0,32(sp)
    800055f0:	ec26                	sd	s1,24(sp)
    800055f2:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    800055f4:	fd840613          	addi	a2,s0,-40
    800055f8:	4581                	li	a1,0
    800055fa:	4501                	li	a0,0
    800055fc:	00000097          	auipc	ra,0x0
    80005600:	ddc080e7          	jalr	-548(ra) # 800053d8 <argfd>
    return -1;
    80005604:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80005606:	02054363          	bltz	a0,8000562c <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    8000560a:	fd843503          	ld	a0,-40(s0)
    8000560e:	00000097          	auipc	ra,0x0
    80005612:	e32080e7          	jalr	-462(ra) # 80005440 <fdalloc>
    80005616:	84aa                	mv	s1,a0
    return -1;
    80005618:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    8000561a:	00054963          	bltz	a0,8000562c <sys_dup+0x42>
  filedup(f);
    8000561e:	fd843503          	ld	a0,-40(s0)
    80005622:	fffff097          	auipc	ra,0xfffff
    80005626:	37a080e7          	jalr	890(ra) # 8000499c <filedup>
  return fd;
    8000562a:	87a6                	mv	a5,s1
}
    8000562c:	853e                	mv	a0,a5
    8000562e:	70a2                	ld	ra,40(sp)
    80005630:	7402                	ld	s0,32(sp)
    80005632:	64e2                	ld	s1,24(sp)
    80005634:	6145                	addi	sp,sp,48
    80005636:	8082                	ret

0000000080005638 <sys_read>:
{
    80005638:	7179                	addi	sp,sp,-48
    8000563a:	f406                	sd	ra,40(sp)
    8000563c:	f022                	sd	s0,32(sp)
    8000563e:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005640:	fe840613          	addi	a2,s0,-24
    80005644:	4581                	li	a1,0
    80005646:	4501                	li	a0,0
    80005648:	00000097          	auipc	ra,0x0
    8000564c:	d90080e7          	jalr	-624(ra) # 800053d8 <argfd>
    return -1;
    80005650:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005652:	04054163          	bltz	a0,80005694 <sys_read+0x5c>
    80005656:	fe440593          	addi	a1,s0,-28
    8000565a:	4509                	li	a0,2
    8000565c:	ffffe097          	auipc	ra,0xffffe
    80005660:	91a080e7          	jalr	-1766(ra) # 80002f76 <argint>
    return -1;
    80005664:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005666:	02054763          	bltz	a0,80005694 <sys_read+0x5c>
    8000566a:	fd840593          	addi	a1,s0,-40
    8000566e:	4505                	li	a0,1
    80005670:	ffffe097          	auipc	ra,0xffffe
    80005674:	928080e7          	jalr	-1752(ra) # 80002f98 <argaddr>
    return -1;
    80005678:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000567a:	00054d63          	bltz	a0,80005694 <sys_read+0x5c>
  return fileread(f, p, n);
    8000567e:	fe442603          	lw	a2,-28(s0)
    80005682:	fd843583          	ld	a1,-40(s0)
    80005686:	fe843503          	ld	a0,-24(s0)
    8000568a:	fffff097          	auipc	ra,0xfffff
    8000568e:	49e080e7          	jalr	1182(ra) # 80004b28 <fileread>
    80005692:	87aa                	mv	a5,a0
}
    80005694:	853e                	mv	a0,a5
    80005696:	70a2                	ld	ra,40(sp)
    80005698:	7402                	ld	s0,32(sp)
    8000569a:	6145                	addi	sp,sp,48
    8000569c:	8082                	ret

000000008000569e <sys_write>:
{
    8000569e:	7179                	addi	sp,sp,-48
    800056a0:	f406                	sd	ra,40(sp)
    800056a2:	f022                	sd	s0,32(sp)
    800056a4:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800056a6:	fe840613          	addi	a2,s0,-24
    800056aa:	4581                	li	a1,0
    800056ac:	4501                	li	a0,0
    800056ae:	00000097          	auipc	ra,0x0
    800056b2:	d2a080e7          	jalr	-726(ra) # 800053d8 <argfd>
    return -1;
    800056b6:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800056b8:	04054163          	bltz	a0,800056fa <sys_write+0x5c>
    800056bc:	fe440593          	addi	a1,s0,-28
    800056c0:	4509                	li	a0,2
    800056c2:	ffffe097          	auipc	ra,0xffffe
    800056c6:	8b4080e7          	jalr	-1868(ra) # 80002f76 <argint>
    return -1;
    800056ca:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800056cc:	02054763          	bltz	a0,800056fa <sys_write+0x5c>
    800056d0:	fd840593          	addi	a1,s0,-40
    800056d4:	4505                	li	a0,1
    800056d6:	ffffe097          	auipc	ra,0xffffe
    800056da:	8c2080e7          	jalr	-1854(ra) # 80002f98 <argaddr>
    return -1;
    800056de:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800056e0:	00054d63          	bltz	a0,800056fa <sys_write+0x5c>
  return filewrite(f, p, n);
    800056e4:	fe442603          	lw	a2,-28(s0)
    800056e8:	fd843583          	ld	a1,-40(s0)
    800056ec:	fe843503          	ld	a0,-24(s0)
    800056f0:	fffff097          	auipc	ra,0xfffff
    800056f4:	4fa080e7          	jalr	1274(ra) # 80004bea <filewrite>
    800056f8:	87aa                	mv	a5,a0
}
    800056fa:	853e                	mv	a0,a5
    800056fc:	70a2                	ld	ra,40(sp)
    800056fe:	7402                	ld	s0,32(sp)
    80005700:	6145                	addi	sp,sp,48
    80005702:	8082                	ret

0000000080005704 <sys_close>:
{
    80005704:	1101                	addi	sp,sp,-32
    80005706:	ec06                	sd	ra,24(sp)
    80005708:	e822                	sd	s0,16(sp)
    8000570a:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    8000570c:	fe040613          	addi	a2,s0,-32
    80005710:	fec40593          	addi	a1,s0,-20
    80005714:	4501                	li	a0,0
    80005716:	00000097          	auipc	ra,0x0
    8000571a:	cc2080e7          	jalr	-830(ra) # 800053d8 <argfd>
    return -1;
    8000571e:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005720:	02054463          	bltz	a0,80005748 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    80005724:	ffffc097          	auipc	ra,0xffffc
    80005728:	2a4080e7          	jalr	676(ra) # 800019c8 <myproc>
    8000572c:	fec42783          	lw	a5,-20(s0)
    80005730:	07f9                	addi	a5,a5,30
    80005732:	078e                	slli	a5,a5,0x3
    80005734:	97aa                	add	a5,a5,a0
    80005736:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    8000573a:	fe043503          	ld	a0,-32(s0)
    8000573e:	fffff097          	auipc	ra,0xfffff
    80005742:	2b0080e7          	jalr	688(ra) # 800049ee <fileclose>
  return 0;
    80005746:	4781                	li	a5,0
}
    80005748:	853e                	mv	a0,a5
    8000574a:	60e2                	ld	ra,24(sp)
    8000574c:	6442                	ld	s0,16(sp)
    8000574e:	6105                	addi	sp,sp,32
    80005750:	8082                	ret

0000000080005752 <sys_fstat>:
{
    80005752:	1101                	addi	sp,sp,-32
    80005754:	ec06                	sd	ra,24(sp)
    80005756:	e822                	sd	s0,16(sp)
    80005758:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    8000575a:	fe840613          	addi	a2,s0,-24
    8000575e:	4581                	li	a1,0
    80005760:	4501                	li	a0,0
    80005762:	00000097          	auipc	ra,0x0
    80005766:	c76080e7          	jalr	-906(ra) # 800053d8 <argfd>
    return -1;
    8000576a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    8000576c:	02054563          	bltz	a0,80005796 <sys_fstat+0x44>
    80005770:	fe040593          	addi	a1,s0,-32
    80005774:	4505                	li	a0,1
    80005776:	ffffe097          	auipc	ra,0xffffe
    8000577a:	822080e7          	jalr	-2014(ra) # 80002f98 <argaddr>
    return -1;
    8000577e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005780:	00054b63          	bltz	a0,80005796 <sys_fstat+0x44>
  return filestat(f, st);
    80005784:	fe043583          	ld	a1,-32(s0)
    80005788:	fe843503          	ld	a0,-24(s0)
    8000578c:	fffff097          	auipc	ra,0xfffff
    80005790:	32a080e7          	jalr	810(ra) # 80004ab6 <filestat>
    80005794:	87aa                	mv	a5,a0
}
    80005796:	853e                	mv	a0,a5
    80005798:	60e2                	ld	ra,24(sp)
    8000579a:	6442                	ld	s0,16(sp)
    8000579c:	6105                	addi	sp,sp,32
    8000579e:	8082                	ret

00000000800057a0 <sys_link>:
{
    800057a0:	7169                	addi	sp,sp,-304
    800057a2:	f606                	sd	ra,296(sp)
    800057a4:	f222                	sd	s0,288(sp)
    800057a6:	ee26                	sd	s1,280(sp)
    800057a8:	ea4a                	sd	s2,272(sp)
    800057aa:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800057ac:	08000613          	li	a2,128
    800057b0:	ed040593          	addi	a1,s0,-304
    800057b4:	4501                	li	a0,0
    800057b6:	ffffe097          	auipc	ra,0xffffe
    800057ba:	804080e7          	jalr	-2044(ra) # 80002fba <argstr>
    return -1;
    800057be:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800057c0:	10054e63          	bltz	a0,800058dc <sys_link+0x13c>
    800057c4:	08000613          	li	a2,128
    800057c8:	f5040593          	addi	a1,s0,-176
    800057cc:	4505                	li	a0,1
    800057ce:	ffffd097          	auipc	ra,0xffffd
    800057d2:	7ec080e7          	jalr	2028(ra) # 80002fba <argstr>
    return -1;
    800057d6:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800057d8:	10054263          	bltz	a0,800058dc <sys_link+0x13c>
  begin_op();
    800057dc:	fffff097          	auipc	ra,0xfffff
    800057e0:	d46080e7          	jalr	-698(ra) # 80004522 <begin_op>
  if((ip = namei(old)) == 0){
    800057e4:	ed040513          	addi	a0,s0,-304
    800057e8:	fffff097          	auipc	ra,0xfffff
    800057ec:	b1e080e7          	jalr	-1250(ra) # 80004306 <namei>
    800057f0:	84aa                	mv	s1,a0
    800057f2:	c551                	beqz	a0,8000587e <sys_link+0xde>
  ilock(ip);
    800057f4:	ffffe097          	auipc	ra,0xffffe
    800057f8:	35c080e7          	jalr	860(ra) # 80003b50 <ilock>
  if(ip->type == T_DIR){
    800057fc:	04449703          	lh	a4,68(s1)
    80005800:	4785                	li	a5,1
    80005802:	08f70463          	beq	a4,a5,8000588a <sys_link+0xea>
  ip->nlink++;
    80005806:	04a4d783          	lhu	a5,74(s1)
    8000580a:	2785                	addiw	a5,a5,1
    8000580c:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005810:	8526                	mv	a0,s1
    80005812:	ffffe097          	auipc	ra,0xffffe
    80005816:	274080e7          	jalr	628(ra) # 80003a86 <iupdate>
  iunlock(ip);
    8000581a:	8526                	mv	a0,s1
    8000581c:	ffffe097          	auipc	ra,0xffffe
    80005820:	3f6080e7          	jalr	1014(ra) # 80003c12 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80005824:	fd040593          	addi	a1,s0,-48
    80005828:	f5040513          	addi	a0,s0,-176
    8000582c:	fffff097          	auipc	ra,0xfffff
    80005830:	af8080e7          	jalr	-1288(ra) # 80004324 <nameiparent>
    80005834:	892a                	mv	s2,a0
    80005836:	c935                	beqz	a0,800058aa <sys_link+0x10a>
  ilock(dp);
    80005838:	ffffe097          	auipc	ra,0xffffe
    8000583c:	318080e7          	jalr	792(ra) # 80003b50 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005840:	00092703          	lw	a4,0(s2)
    80005844:	409c                	lw	a5,0(s1)
    80005846:	04f71d63          	bne	a4,a5,800058a0 <sys_link+0x100>
    8000584a:	40d0                	lw	a2,4(s1)
    8000584c:	fd040593          	addi	a1,s0,-48
    80005850:	854a                	mv	a0,s2
    80005852:	fffff097          	auipc	ra,0xfffff
    80005856:	9f2080e7          	jalr	-1550(ra) # 80004244 <dirlink>
    8000585a:	04054363          	bltz	a0,800058a0 <sys_link+0x100>
  iunlockput(dp);
    8000585e:	854a                	mv	a0,s2
    80005860:	ffffe097          	auipc	ra,0xffffe
    80005864:	552080e7          	jalr	1362(ra) # 80003db2 <iunlockput>
  iput(ip);
    80005868:	8526                	mv	a0,s1
    8000586a:	ffffe097          	auipc	ra,0xffffe
    8000586e:	4a0080e7          	jalr	1184(ra) # 80003d0a <iput>
  end_op();
    80005872:	fffff097          	auipc	ra,0xfffff
    80005876:	d30080e7          	jalr	-720(ra) # 800045a2 <end_op>
  return 0;
    8000587a:	4781                	li	a5,0
    8000587c:	a085                	j	800058dc <sys_link+0x13c>
    end_op();
    8000587e:	fffff097          	auipc	ra,0xfffff
    80005882:	d24080e7          	jalr	-732(ra) # 800045a2 <end_op>
    return -1;
    80005886:	57fd                	li	a5,-1
    80005888:	a891                	j	800058dc <sys_link+0x13c>
    iunlockput(ip);
    8000588a:	8526                	mv	a0,s1
    8000588c:	ffffe097          	auipc	ra,0xffffe
    80005890:	526080e7          	jalr	1318(ra) # 80003db2 <iunlockput>
    end_op();
    80005894:	fffff097          	auipc	ra,0xfffff
    80005898:	d0e080e7          	jalr	-754(ra) # 800045a2 <end_op>
    return -1;
    8000589c:	57fd                	li	a5,-1
    8000589e:	a83d                	j	800058dc <sys_link+0x13c>
    iunlockput(dp);
    800058a0:	854a                	mv	a0,s2
    800058a2:	ffffe097          	auipc	ra,0xffffe
    800058a6:	510080e7          	jalr	1296(ra) # 80003db2 <iunlockput>
  ilock(ip);
    800058aa:	8526                	mv	a0,s1
    800058ac:	ffffe097          	auipc	ra,0xffffe
    800058b0:	2a4080e7          	jalr	676(ra) # 80003b50 <ilock>
  ip->nlink--;
    800058b4:	04a4d783          	lhu	a5,74(s1)
    800058b8:	37fd                	addiw	a5,a5,-1
    800058ba:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800058be:	8526                	mv	a0,s1
    800058c0:	ffffe097          	auipc	ra,0xffffe
    800058c4:	1c6080e7          	jalr	454(ra) # 80003a86 <iupdate>
  iunlockput(ip);
    800058c8:	8526                	mv	a0,s1
    800058ca:	ffffe097          	auipc	ra,0xffffe
    800058ce:	4e8080e7          	jalr	1256(ra) # 80003db2 <iunlockput>
  end_op();
    800058d2:	fffff097          	auipc	ra,0xfffff
    800058d6:	cd0080e7          	jalr	-816(ra) # 800045a2 <end_op>
  return -1;
    800058da:	57fd                	li	a5,-1
}
    800058dc:	853e                	mv	a0,a5
    800058de:	70b2                	ld	ra,296(sp)
    800058e0:	7412                	ld	s0,288(sp)
    800058e2:	64f2                	ld	s1,280(sp)
    800058e4:	6952                	ld	s2,272(sp)
    800058e6:	6155                	addi	sp,sp,304
    800058e8:	8082                	ret

00000000800058ea <sys_unlink>:
{
    800058ea:	7151                	addi	sp,sp,-240
    800058ec:	f586                	sd	ra,232(sp)
    800058ee:	f1a2                	sd	s0,224(sp)
    800058f0:	eda6                	sd	s1,216(sp)
    800058f2:	e9ca                	sd	s2,208(sp)
    800058f4:	e5ce                	sd	s3,200(sp)
    800058f6:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    800058f8:	08000613          	li	a2,128
    800058fc:	f3040593          	addi	a1,s0,-208
    80005900:	4501                	li	a0,0
    80005902:	ffffd097          	auipc	ra,0xffffd
    80005906:	6b8080e7          	jalr	1720(ra) # 80002fba <argstr>
    8000590a:	18054163          	bltz	a0,80005a8c <sys_unlink+0x1a2>
  begin_op();
    8000590e:	fffff097          	auipc	ra,0xfffff
    80005912:	c14080e7          	jalr	-1004(ra) # 80004522 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005916:	fb040593          	addi	a1,s0,-80
    8000591a:	f3040513          	addi	a0,s0,-208
    8000591e:	fffff097          	auipc	ra,0xfffff
    80005922:	a06080e7          	jalr	-1530(ra) # 80004324 <nameiparent>
    80005926:	84aa                	mv	s1,a0
    80005928:	c979                	beqz	a0,800059fe <sys_unlink+0x114>
  ilock(dp);
    8000592a:	ffffe097          	auipc	ra,0xffffe
    8000592e:	226080e7          	jalr	550(ra) # 80003b50 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005932:	00003597          	auipc	a1,0x3
    80005936:	e8e58593          	addi	a1,a1,-370 # 800087c0 <syscalls+0x2c8>
    8000593a:	fb040513          	addi	a0,s0,-80
    8000593e:	ffffe097          	auipc	ra,0xffffe
    80005942:	6dc080e7          	jalr	1756(ra) # 8000401a <namecmp>
    80005946:	14050a63          	beqz	a0,80005a9a <sys_unlink+0x1b0>
    8000594a:	00003597          	auipc	a1,0x3
    8000594e:	e7e58593          	addi	a1,a1,-386 # 800087c8 <syscalls+0x2d0>
    80005952:	fb040513          	addi	a0,s0,-80
    80005956:	ffffe097          	auipc	ra,0xffffe
    8000595a:	6c4080e7          	jalr	1732(ra) # 8000401a <namecmp>
    8000595e:	12050e63          	beqz	a0,80005a9a <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005962:	f2c40613          	addi	a2,s0,-212
    80005966:	fb040593          	addi	a1,s0,-80
    8000596a:	8526                	mv	a0,s1
    8000596c:	ffffe097          	auipc	ra,0xffffe
    80005970:	6c8080e7          	jalr	1736(ra) # 80004034 <dirlookup>
    80005974:	892a                	mv	s2,a0
    80005976:	12050263          	beqz	a0,80005a9a <sys_unlink+0x1b0>
  ilock(ip);
    8000597a:	ffffe097          	auipc	ra,0xffffe
    8000597e:	1d6080e7          	jalr	470(ra) # 80003b50 <ilock>
  if(ip->nlink < 1)
    80005982:	04a91783          	lh	a5,74(s2)
    80005986:	08f05263          	blez	a5,80005a0a <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    8000598a:	04491703          	lh	a4,68(s2)
    8000598e:	4785                	li	a5,1
    80005990:	08f70563          	beq	a4,a5,80005a1a <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005994:	4641                	li	a2,16
    80005996:	4581                	li	a1,0
    80005998:	fc040513          	addi	a0,s0,-64
    8000599c:	ffffb097          	auipc	ra,0xffffb
    800059a0:	344080e7          	jalr	836(ra) # 80000ce0 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800059a4:	4741                	li	a4,16
    800059a6:	f2c42683          	lw	a3,-212(s0)
    800059aa:	fc040613          	addi	a2,s0,-64
    800059ae:	4581                	li	a1,0
    800059b0:	8526                	mv	a0,s1
    800059b2:	ffffe097          	auipc	ra,0xffffe
    800059b6:	54a080e7          	jalr	1354(ra) # 80003efc <writei>
    800059ba:	47c1                	li	a5,16
    800059bc:	0af51563          	bne	a0,a5,80005a66 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    800059c0:	04491703          	lh	a4,68(s2)
    800059c4:	4785                	li	a5,1
    800059c6:	0af70863          	beq	a4,a5,80005a76 <sys_unlink+0x18c>
  iunlockput(dp);
    800059ca:	8526                	mv	a0,s1
    800059cc:	ffffe097          	auipc	ra,0xffffe
    800059d0:	3e6080e7          	jalr	998(ra) # 80003db2 <iunlockput>
  ip->nlink--;
    800059d4:	04a95783          	lhu	a5,74(s2)
    800059d8:	37fd                	addiw	a5,a5,-1
    800059da:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    800059de:	854a                	mv	a0,s2
    800059e0:	ffffe097          	auipc	ra,0xffffe
    800059e4:	0a6080e7          	jalr	166(ra) # 80003a86 <iupdate>
  iunlockput(ip);
    800059e8:	854a                	mv	a0,s2
    800059ea:	ffffe097          	auipc	ra,0xffffe
    800059ee:	3c8080e7          	jalr	968(ra) # 80003db2 <iunlockput>
  end_op();
    800059f2:	fffff097          	auipc	ra,0xfffff
    800059f6:	bb0080e7          	jalr	-1104(ra) # 800045a2 <end_op>
  return 0;
    800059fa:	4501                	li	a0,0
    800059fc:	a84d                	j	80005aae <sys_unlink+0x1c4>
    end_op();
    800059fe:	fffff097          	auipc	ra,0xfffff
    80005a02:	ba4080e7          	jalr	-1116(ra) # 800045a2 <end_op>
    return -1;
    80005a06:	557d                	li	a0,-1
    80005a08:	a05d                	j	80005aae <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005a0a:	00003517          	auipc	a0,0x3
    80005a0e:	de650513          	addi	a0,a0,-538 # 800087f0 <syscalls+0x2f8>
    80005a12:	ffffb097          	auipc	ra,0xffffb
    80005a16:	b2c080e7          	jalr	-1236(ra) # 8000053e <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005a1a:	04c92703          	lw	a4,76(s2)
    80005a1e:	02000793          	li	a5,32
    80005a22:	f6e7f9e3          	bgeu	a5,a4,80005994 <sys_unlink+0xaa>
    80005a26:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005a2a:	4741                	li	a4,16
    80005a2c:	86ce                	mv	a3,s3
    80005a2e:	f1840613          	addi	a2,s0,-232
    80005a32:	4581                	li	a1,0
    80005a34:	854a                	mv	a0,s2
    80005a36:	ffffe097          	auipc	ra,0xffffe
    80005a3a:	3ce080e7          	jalr	974(ra) # 80003e04 <readi>
    80005a3e:	47c1                	li	a5,16
    80005a40:	00f51b63          	bne	a0,a5,80005a56 <sys_unlink+0x16c>
    if(de.inum != 0)
    80005a44:	f1845783          	lhu	a5,-232(s0)
    80005a48:	e7a1                	bnez	a5,80005a90 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005a4a:	29c1                	addiw	s3,s3,16
    80005a4c:	04c92783          	lw	a5,76(s2)
    80005a50:	fcf9ede3          	bltu	s3,a5,80005a2a <sys_unlink+0x140>
    80005a54:	b781                	j	80005994 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005a56:	00003517          	auipc	a0,0x3
    80005a5a:	db250513          	addi	a0,a0,-590 # 80008808 <syscalls+0x310>
    80005a5e:	ffffb097          	auipc	ra,0xffffb
    80005a62:	ae0080e7          	jalr	-1312(ra) # 8000053e <panic>
    panic("unlink: writei");
    80005a66:	00003517          	auipc	a0,0x3
    80005a6a:	dba50513          	addi	a0,a0,-582 # 80008820 <syscalls+0x328>
    80005a6e:	ffffb097          	auipc	ra,0xffffb
    80005a72:	ad0080e7          	jalr	-1328(ra) # 8000053e <panic>
    dp->nlink--;
    80005a76:	04a4d783          	lhu	a5,74(s1)
    80005a7a:	37fd                	addiw	a5,a5,-1
    80005a7c:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005a80:	8526                	mv	a0,s1
    80005a82:	ffffe097          	auipc	ra,0xffffe
    80005a86:	004080e7          	jalr	4(ra) # 80003a86 <iupdate>
    80005a8a:	b781                	j	800059ca <sys_unlink+0xe0>
    return -1;
    80005a8c:	557d                	li	a0,-1
    80005a8e:	a005                	j	80005aae <sys_unlink+0x1c4>
    iunlockput(ip);
    80005a90:	854a                	mv	a0,s2
    80005a92:	ffffe097          	auipc	ra,0xffffe
    80005a96:	320080e7          	jalr	800(ra) # 80003db2 <iunlockput>
  iunlockput(dp);
    80005a9a:	8526                	mv	a0,s1
    80005a9c:	ffffe097          	auipc	ra,0xffffe
    80005aa0:	316080e7          	jalr	790(ra) # 80003db2 <iunlockput>
  end_op();
    80005aa4:	fffff097          	auipc	ra,0xfffff
    80005aa8:	afe080e7          	jalr	-1282(ra) # 800045a2 <end_op>
  return -1;
    80005aac:	557d                	li	a0,-1
}
    80005aae:	70ae                	ld	ra,232(sp)
    80005ab0:	740e                	ld	s0,224(sp)
    80005ab2:	64ee                	ld	s1,216(sp)
    80005ab4:	694e                	ld	s2,208(sp)
    80005ab6:	69ae                	ld	s3,200(sp)
    80005ab8:	616d                	addi	sp,sp,240
    80005aba:	8082                	ret

0000000080005abc <sys_open>:

uint64
sys_open(void)
{
    80005abc:	7131                	addi	sp,sp,-192
    80005abe:	fd06                	sd	ra,184(sp)
    80005ac0:	f922                	sd	s0,176(sp)
    80005ac2:	f526                	sd	s1,168(sp)
    80005ac4:	f14a                	sd	s2,160(sp)
    80005ac6:	ed4e                	sd	s3,152(sp)
    80005ac8:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005aca:	08000613          	li	a2,128
    80005ace:	f5040593          	addi	a1,s0,-176
    80005ad2:	4501                	li	a0,0
    80005ad4:	ffffd097          	auipc	ra,0xffffd
    80005ad8:	4e6080e7          	jalr	1254(ra) # 80002fba <argstr>
    return -1;
    80005adc:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005ade:	0c054163          	bltz	a0,80005ba0 <sys_open+0xe4>
    80005ae2:	f4c40593          	addi	a1,s0,-180
    80005ae6:	4505                	li	a0,1
    80005ae8:	ffffd097          	auipc	ra,0xffffd
    80005aec:	48e080e7          	jalr	1166(ra) # 80002f76 <argint>
    80005af0:	0a054863          	bltz	a0,80005ba0 <sys_open+0xe4>

  begin_op();
    80005af4:	fffff097          	auipc	ra,0xfffff
    80005af8:	a2e080e7          	jalr	-1490(ra) # 80004522 <begin_op>

  if(omode & O_CREATE){
    80005afc:	f4c42783          	lw	a5,-180(s0)
    80005b00:	2007f793          	andi	a5,a5,512
    80005b04:	cbdd                	beqz	a5,80005bba <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005b06:	4681                	li	a3,0
    80005b08:	4601                	li	a2,0
    80005b0a:	4589                	li	a1,2
    80005b0c:	f5040513          	addi	a0,s0,-176
    80005b10:	00000097          	auipc	ra,0x0
    80005b14:	972080e7          	jalr	-1678(ra) # 80005482 <create>
    80005b18:	892a                	mv	s2,a0
    if(ip == 0){
    80005b1a:	c959                	beqz	a0,80005bb0 <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005b1c:	04491703          	lh	a4,68(s2)
    80005b20:	478d                	li	a5,3
    80005b22:	00f71763          	bne	a4,a5,80005b30 <sys_open+0x74>
    80005b26:	04695703          	lhu	a4,70(s2)
    80005b2a:	47a5                	li	a5,9
    80005b2c:	0ce7ec63          	bltu	a5,a4,80005c04 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005b30:	fffff097          	auipc	ra,0xfffff
    80005b34:	e02080e7          	jalr	-510(ra) # 80004932 <filealloc>
    80005b38:	89aa                	mv	s3,a0
    80005b3a:	10050263          	beqz	a0,80005c3e <sys_open+0x182>
    80005b3e:	00000097          	auipc	ra,0x0
    80005b42:	902080e7          	jalr	-1790(ra) # 80005440 <fdalloc>
    80005b46:	84aa                	mv	s1,a0
    80005b48:	0e054663          	bltz	a0,80005c34 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005b4c:	04491703          	lh	a4,68(s2)
    80005b50:	478d                	li	a5,3
    80005b52:	0cf70463          	beq	a4,a5,80005c1a <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005b56:	4789                	li	a5,2
    80005b58:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005b5c:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005b60:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005b64:	f4c42783          	lw	a5,-180(s0)
    80005b68:	0017c713          	xori	a4,a5,1
    80005b6c:	8b05                	andi	a4,a4,1
    80005b6e:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005b72:	0037f713          	andi	a4,a5,3
    80005b76:	00e03733          	snez	a4,a4
    80005b7a:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005b7e:	4007f793          	andi	a5,a5,1024
    80005b82:	c791                	beqz	a5,80005b8e <sys_open+0xd2>
    80005b84:	04491703          	lh	a4,68(s2)
    80005b88:	4789                	li	a5,2
    80005b8a:	08f70f63          	beq	a4,a5,80005c28 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005b8e:	854a                	mv	a0,s2
    80005b90:	ffffe097          	auipc	ra,0xffffe
    80005b94:	082080e7          	jalr	130(ra) # 80003c12 <iunlock>
  end_op();
    80005b98:	fffff097          	auipc	ra,0xfffff
    80005b9c:	a0a080e7          	jalr	-1526(ra) # 800045a2 <end_op>

  return fd;
}
    80005ba0:	8526                	mv	a0,s1
    80005ba2:	70ea                	ld	ra,184(sp)
    80005ba4:	744a                	ld	s0,176(sp)
    80005ba6:	74aa                	ld	s1,168(sp)
    80005ba8:	790a                	ld	s2,160(sp)
    80005baa:	69ea                	ld	s3,152(sp)
    80005bac:	6129                	addi	sp,sp,192
    80005bae:	8082                	ret
      end_op();
    80005bb0:	fffff097          	auipc	ra,0xfffff
    80005bb4:	9f2080e7          	jalr	-1550(ra) # 800045a2 <end_op>
      return -1;
    80005bb8:	b7e5                	j	80005ba0 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005bba:	f5040513          	addi	a0,s0,-176
    80005bbe:	ffffe097          	auipc	ra,0xffffe
    80005bc2:	748080e7          	jalr	1864(ra) # 80004306 <namei>
    80005bc6:	892a                	mv	s2,a0
    80005bc8:	c905                	beqz	a0,80005bf8 <sys_open+0x13c>
    ilock(ip);
    80005bca:	ffffe097          	auipc	ra,0xffffe
    80005bce:	f86080e7          	jalr	-122(ra) # 80003b50 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005bd2:	04491703          	lh	a4,68(s2)
    80005bd6:	4785                	li	a5,1
    80005bd8:	f4f712e3          	bne	a4,a5,80005b1c <sys_open+0x60>
    80005bdc:	f4c42783          	lw	a5,-180(s0)
    80005be0:	dba1                	beqz	a5,80005b30 <sys_open+0x74>
      iunlockput(ip);
    80005be2:	854a                	mv	a0,s2
    80005be4:	ffffe097          	auipc	ra,0xffffe
    80005be8:	1ce080e7          	jalr	462(ra) # 80003db2 <iunlockput>
      end_op();
    80005bec:	fffff097          	auipc	ra,0xfffff
    80005bf0:	9b6080e7          	jalr	-1610(ra) # 800045a2 <end_op>
      return -1;
    80005bf4:	54fd                	li	s1,-1
    80005bf6:	b76d                	j	80005ba0 <sys_open+0xe4>
      end_op();
    80005bf8:	fffff097          	auipc	ra,0xfffff
    80005bfc:	9aa080e7          	jalr	-1622(ra) # 800045a2 <end_op>
      return -1;
    80005c00:	54fd                	li	s1,-1
    80005c02:	bf79                	j	80005ba0 <sys_open+0xe4>
    iunlockput(ip);
    80005c04:	854a                	mv	a0,s2
    80005c06:	ffffe097          	auipc	ra,0xffffe
    80005c0a:	1ac080e7          	jalr	428(ra) # 80003db2 <iunlockput>
    end_op();
    80005c0e:	fffff097          	auipc	ra,0xfffff
    80005c12:	994080e7          	jalr	-1644(ra) # 800045a2 <end_op>
    return -1;
    80005c16:	54fd                	li	s1,-1
    80005c18:	b761                	j	80005ba0 <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005c1a:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005c1e:	04691783          	lh	a5,70(s2)
    80005c22:	02f99223          	sh	a5,36(s3)
    80005c26:	bf2d                	j	80005b60 <sys_open+0xa4>
    itrunc(ip);
    80005c28:	854a                	mv	a0,s2
    80005c2a:	ffffe097          	auipc	ra,0xffffe
    80005c2e:	034080e7          	jalr	52(ra) # 80003c5e <itrunc>
    80005c32:	bfb1                	j	80005b8e <sys_open+0xd2>
      fileclose(f);
    80005c34:	854e                	mv	a0,s3
    80005c36:	fffff097          	auipc	ra,0xfffff
    80005c3a:	db8080e7          	jalr	-584(ra) # 800049ee <fileclose>
    iunlockput(ip);
    80005c3e:	854a                	mv	a0,s2
    80005c40:	ffffe097          	auipc	ra,0xffffe
    80005c44:	172080e7          	jalr	370(ra) # 80003db2 <iunlockput>
    end_op();
    80005c48:	fffff097          	auipc	ra,0xfffff
    80005c4c:	95a080e7          	jalr	-1702(ra) # 800045a2 <end_op>
    return -1;
    80005c50:	54fd                	li	s1,-1
    80005c52:	b7b9                	j	80005ba0 <sys_open+0xe4>

0000000080005c54 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005c54:	7175                	addi	sp,sp,-144
    80005c56:	e506                	sd	ra,136(sp)
    80005c58:	e122                	sd	s0,128(sp)
    80005c5a:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005c5c:	fffff097          	auipc	ra,0xfffff
    80005c60:	8c6080e7          	jalr	-1850(ra) # 80004522 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005c64:	08000613          	li	a2,128
    80005c68:	f7040593          	addi	a1,s0,-144
    80005c6c:	4501                	li	a0,0
    80005c6e:	ffffd097          	auipc	ra,0xffffd
    80005c72:	34c080e7          	jalr	844(ra) # 80002fba <argstr>
    80005c76:	02054963          	bltz	a0,80005ca8 <sys_mkdir+0x54>
    80005c7a:	4681                	li	a3,0
    80005c7c:	4601                	li	a2,0
    80005c7e:	4585                	li	a1,1
    80005c80:	f7040513          	addi	a0,s0,-144
    80005c84:	fffff097          	auipc	ra,0xfffff
    80005c88:	7fe080e7          	jalr	2046(ra) # 80005482 <create>
    80005c8c:	cd11                	beqz	a0,80005ca8 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005c8e:	ffffe097          	auipc	ra,0xffffe
    80005c92:	124080e7          	jalr	292(ra) # 80003db2 <iunlockput>
  end_op();
    80005c96:	fffff097          	auipc	ra,0xfffff
    80005c9a:	90c080e7          	jalr	-1780(ra) # 800045a2 <end_op>
  return 0;
    80005c9e:	4501                	li	a0,0
}
    80005ca0:	60aa                	ld	ra,136(sp)
    80005ca2:	640a                	ld	s0,128(sp)
    80005ca4:	6149                	addi	sp,sp,144
    80005ca6:	8082                	ret
    end_op();
    80005ca8:	fffff097          	auipc	ra,0xfffff
    80005cac:	8fa080e7          	jalr	-1798(ra) # 800045a2 <end_op>
    return -1;
    80005cb0:	557d                	li	a0,-1
    80005cb2:	b7fd                	j	80005ca0 <sys_mkdir+0x4c>

0000000080005cb4 <sys_mknod>:

uint64
sys_mknod(void)
{
    80005cb4:	7135                	addi	sp,sp,-160
    80005cb6:	ed06                	sd	ra,152(sp)
    80005cb8:	e922                	sd	s0,144(sp)
    80005cba:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005cbc:	fffff097          	auipc	ra,0xfffff
    80005cc0:	866080e7          	jalr	-1946(ra) # 80004522 <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005cc4:	08000613          	li	a2,128
    80005cc8:	f7040593          	addi	a1,s0,-144
    80005ccc:	4501                	li	a0,0
    80005cce:	ffffd097          	auipc	ra,0xffffd
    80005cd2:	2ec080e7          	jalr	748(ra) # 80002fba <argstr>
    80005cd6:	04054a63          	bltz	a0,80005d2a <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    80005cda:	f6c40593          	addi	a1,s0,-148
    80005cde:	4505                	li	a0,1
    80005ce0:	ffffd097          	auipc	ra,0xffffd
    80005ce4:	296080e7          	jalr	662(ra) # 80002f76 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005ce8:	04054163          	bltz	a0,80005d2a <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    80005cec:	f6840593          	addi	a1,s0,-152
    80005cf0:	4509                	li	a0,2
    80005cf2:	ffffd097          	auipc	ra,0xffffd
    80005cf6:	284080e7          	jalr	644(ra) # 80002f76 <argint>
     argint(1, &major) < 0 ||
    80005cfa:	02054863          	bltz	a0,80005d2a <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005cfe:	f6841683          	lh	a3,-152(s0)
    80005d02:	f6c41603          	lh	a2,-148(s0)
    80005d06:	458d                	li	a1,3
    80005d08:	f7040513          	addi	a0,s0,-144
    80005d0c:	fffff097          	auipc	ra,0xfffff
    80005d10:	776080e7          	jalr	1910(ra) # 80005482 <create>
     argint(2, &minor) < 0 ||
    80005d14:	c919                	beqz	a0,80005d2a <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005d16:	ffffe097          	auipc	ra,0xffffe
    80005d1a:	09c080e7          	jalr	156(ra) # 80003db2 <iunlockput>
  end_op();
    80005d1e:	fffff097          	auipc	ra,0xfffff
    80005d22:	884080e7          	jalr	-1916(ra) # 800045a2 <end_op>
  return 0;
    80005d26:	4501                	li	a0,0
    80005d28:	a031                	j	80005d34 <sys_mknod+0x80>
    end_op();
    80005d2a:	fffff097          	auipc	ra,0xfffff
    80005d2e:	878080e7          	jalr	-1928(ra) # 800045a2 <end_op>
    return -1;
    80005d32:	557d                	li	a0,-1
}
    80005d34:	60ea                	ld	ra,152(sp)
    80005d36:	644a                	ld	s0,144(sp)
    80005d38:	610d                	addi	sp,sp,160
    80005d3a:	8082                	ret

0000000080005d3c <sys_chdir>:

uint64
sys_chdir(void)
{
    80005d3c:	7135                	addi	sp,sp,-160
    80005d3e:	ed06                	sd	ra,152(sp)
    80005d40:	e922                	sd	s0,144(sp)
    80005d42:	e526                	sd	s1,136(sp)
    80005d44:	e14a                	sd	s2,128(sp)
    80005d46:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005d48:	ffffc097          	auipc	ra,0xffffc
    80005d4c:	c80080e7          	jalr	-896(ra) # 800019c8 <myproc>
    80005d50:	892a                	mv	s2,a0
  
  begin_op();
    80005d52:	ffffe097          	auipc	ra,0xffffe
    80005d56:	7d0080e7          	jalr	2000(ra) # 80004522 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005d5a:	08000613          	li	a2,128
    80005d5e:	f6040593          	addi	a1,s0,-160
    80005d62:	4501                	li	a0,0
    80005d64:	ffffd097          	auipc	ra,0xffffd
    80005d68:	256080e7          	jalr	598(ra) # 80002fba <argstr>
    80005d6c:	04054b63          	bltz	a0,80005dc2 <sys_chdir+0x86>
    80005d70:	f6040513          	addi	a0,s0,-160
    80005d74:	ffffe097          	auipc	ra,0xffffe
    80005d78:	592080e7          	jalr	1426(ra) # 80004306 <namei>
    80005d7c:	84aa                	mv	s1,a0
    80005d7e:	c131                	beqz	a0,80005dc2 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005d80:	ffffe097          	auipc	ra,0xffffe
    80005d84:	dd0080e7          	jalr	-560(ra) # 80003b50 <ilock>
  if(ip->type != T_DIR){
    80005d88:	04449703          	lh	a4,68(s1)
    80005d8c:	4785                	li	a5,1
    80005d8e:	04f71063          	bne	a4,a5,80005dce <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005d92:	8526                	mv	a0,s1
    80005d94:	ffffe097          	auipc	ra,0xffffe
    80005d98:	e7e080e7          	jalr	-386(ra) # 80003c12 <iunlock>
  iput(p->cwd);
    80005d9c:	17093503          	ld	a0,368(s2)
    80005da0:	ffffe097          	auipc	ra,0xffffe
    80005da4:	f6a080e7          	jalr	-150(ra) # 80003d0a <iput>
  end_op();
    80005da8:	ffffe097          	auipc	ra,0xffffe
    80005dac:	7fa080e7          	jalr	2042(ra) # 800045a2 <end_op>
  p->cwd = ip;
    80005db0:	16993823          	sd	s1,368(s2)
  return 0;
    80005db4:	4501                	li	a0,0
}
    80005db6:	60ea                	ld	ra,152(sp)
    80005db8:	644a                	ld	s0,144(sp)
    80005dba:	64aa                	ld	s1,136(sp)
    80005dbc:	690a                	ld	s2,128(sp)
    80005dbe:	610d                	addi	sp,sp,160
    80005dc0:	8082                	ret
    end_op();
    80005dc2:	ffffe097          	auipc	ra,0xffffe
    80005dc6:	7e0080e7          	jalr	2016(ra) # 800045a2 <end_op>
    return -1;
    80005dca:	557d                	li	a0,-1
    80005dcc:	b7ed                	j	80005db6 <sys_chdir+0x7a>
    iunlockput(ip);
    80005dce:	8526                	mv	a0,s1
    80005dd0:	ffffe097          	auipc	ra,0xffffe
    80005dd4:	fe2080e7          	jalr	-30(ra) # 80003db2 <iunlockput>
    end_op();
    80005dd8:	ffffe097          	auipc	ra,0xffffe
    80005ddc:	7ca080e7          	jalr	1994(ra) # 800045a2 <end_op>
    return -1;
    80005de0:	557d                	li	a0,-1
    80005de2:	bfd1                	j	80005db6 <sys_chdir+0x7a>

0000000080005de4 <sys_exec>:

uint64
sys_exec(void)
{
    80005de4:	7145                	addi	sp,sp,-464
    80005de6:	e786                	sd	ra,456(sp)
    80005de8:	e3a2                	sd	s0,448(sp)
    80005dea:	ff26                	sd	s1,440(sp)
    80005dec:	fb4a                	sd	s2,432(sp)
    80005dee:	f74e                	sd	s3,424(sp)
    80005df0:	f352                	sd	s4,416(sp)
    80005df2:	ef56                	sd	s5,408(sp)
    80005df4:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005df6:	08000613          	li	a2,128
    80005dfa:	f4040593          	addi	a1,s0,-192
    80005dfe:	4501                	li	a0,0
    80005e00:	ffffd097          	auipc	ra,0xffffd
    80005e04:	1ba080e7          	jalr	442(ra) # 80002fba <argstr>
    return -1;
    80005e08:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005e0a:	0c054a63          	bltz	a0,80005ede <sys_exec+0xfa>
    80005e0e:	e3840593          	addi	a1,s0,-456
    80005e12:	4505                	li	a0,1
    80005e14:	ffffd097          	auipc	ra,0xffffd
    80005e18:	184080e7          	jalr	388(ra) # 80002f98 <argaddr>
    80005e1c:	0c054163          	bltz	a0,80005ede <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80005e20:	10000613          	li	a2,256
    80005e24:	4581                	li	a1,0
    80005e26:	e4040513          	addi	a0,s0,-448
    80005e2a:	ffffb097          	auipc	ra,0xffffb
    80005e2e:	eb6080e7          	jalr	-330(ra) # 80000ce0 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005e32:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005e36:	89a6                	mv	s3,s1
    80005e38:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005e3a:	02000a13          	li	s4,32
    80005e3e:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005e42:	00391513          	slli	a0,s2,0x3
    80005e46:	e3040593          	addi	a1,s0,-464
    80005e4a:	e3843783          	ld	a5,-456(s0)
    80005e4e:	953e                	add	a0,a0,a5
    80005e50:	ffffd097          	auipc	ra,0xffffd
    80005e54:	08c080e7          	jalr	140(ra) # 80002edc <fetchaddr>
    80005e58:	02054a63          	bltz	a0,80005e8c <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    80005e5c:	e3043783          	ld	a5,-464(s0)
    80005e60:	c3b9                	beqz	a5,80005ea6 <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005e62:	ffffb097          	auipc	ra,0xffffb
    80005e66:	c92080e7          	jalr	-878(ra) # 80000af4 <kalloc>
    80005e6a:	85aa                	mv	a1,a0
    80005e6c:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005e70:	cd11                	beqz	a0,80005e8c <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005e72:	6605                	lui	a2,0x1
    80005e74:	e3043503          	ld	a0,-464(s0)
    80005e78:	ffffd097          	auipc	ra,0xffffd
    80005e7c:	0b6080e7          	jalr	182(ra) # 80002f2e <fetchstr>
    80005e80:	00054663          	bltz	a0,80005e8c <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80005e84:	0905                	addi	s2,s2,1
    80005e86:	09a1                	addi	s3,s3,8
    80005e88:	fb491be3          	bne	s2,s4,80005e3e <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005e8c:	10048913          	addi	s2,s1,256
    80005e90:	6088                	ld	a0,0(s1)
    80005e92:	c529                	beqz	a0,80005edc <sys_exec+0xf8>
    kfree(argv[i]);
    80005e94:	ffffb097          	auipc	ra,0xffffb
    80005e98:	b64080e7          	jalr	-1180(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005e9c:	04a1                	addi	s1,s1,8
    80005e9e:	ff2499e3          	bne	s1,s2,80005e90 <sys_exec+0xac>
  return -1;
    80005ea2:	597d                	li	s2,-1
    80005ea4:	a82d                	j	80005ede <sys_exec+0xfa>
      argv[i] = 0;
    80005ea6:	0a8e                	slli	s5,s5,0x3
    80005ea8:	fc040793          	addi	a5,s0,-64
    80005eac:	9abe                	add	s5,s5,a5
    80005eae:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005eb2:	e4040593          	addi	a1,s0,-448
    80005eb6:	f4040513          	addi	a0,s0,-192
    80005eba:	fffff097          	auipc	ra,0xfffff
    80005ebe:	194080e7          	jalr	404(ra) # 8000504e <exec>
    80005ec2:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005ec4:	10048993          	addi	s3,s1,256
    80005ec8:	6088                	ld	a0,0(s1)
    80005eca:	c911                	beqz	a0,80005ede <sys_exec+0xfa>
    kfree(argv[i]);
    80005ecc:	ffffb097          	auipc	ra,0xffffb
    80005ed0:	b2c080e7          	jalr	-1236(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005ed4:	04a1                	addi	s1,s1,8
    80005ed6:	ff3499e3          	bne	s1,s3,80005ec8 <sys_exec+0xe4>
    80005eda:	a011                	j	80005ede <sys_exec+0xfa>
  return -1;
    80005edc:	597d                	li	s2,-1
}
    80005ede:	854a                	mv	a0,s2
    80005ee0:	60be                	ld	ra,456(sp)
    80005ee2:	641e                	ld	s0,448(sp)
    80005ee4:	74fa                	ld	s1,440(sp)
    80005ee6:	795a                	ld	s2,432(sp)
    80005ee8:	79ba                	ld	s3,424(sp)
    80005eea:	7a1a                	ld	s4,416(sp)
    80005eec:	6afa                	ld	s5,408(sp)
    80005eee:	6179                	addi	sp,sp,464
    80005ef0:	8082                	ret

0000000080005ef2 <sys_pipe>:

uint64
sys_pipe(void)
{
    80005ef2:	7139                	addi	sp,sp,-64
    80005ef4:	fc06                	sd	ra,56(sp)
    80005ef6:	f822                	sd	s0,48(sp)
    80005ef8:	f426                	sd	s1,40(sp)
    80005efa:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005efc:	ffffc097          	auipc	ra,0xffffc
    80005f00:	acc080e7          	jalr	-1332(ra) # 800019c8 <myproc>
    80005f04:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80005f06:	fd840593          	addi	a1,s0,-40
    80005f0a:	4501                	li	a0,0
    80005f0c:	ffffd097          	auipc	ra,0xffffd
    80005f10:	08c080e7          	jalr	140(ra) # 80002f98 <argaddr>
    return -1;
    80005f14:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80005f16:	0e054063          	bltz	a0,80005ff6 <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    80005f1a:	fc840593          	addi	a1,s0,-56
    80005f1e:	fd040513          	addi	a0,s0,-48
    80005f22:	fffff097          	auipc	ra,0xfffff
    80005f26:	dfc080e7          	jalr	-516(ra) # 80004d1e <pipealloc>
    return -1;
    80005f2a:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005f2c:	0c054563          	bltz	a0,80005ff6 <sys_pipe+0x104>
  fd0 = -1;
    80005f30:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005f34:	fd043503          	ld	a0,-48(s0)
    80005f38:	fffff097          	auipc	ra,0xfffff
    80005f3c:	508080e7          	jalr	1288(ra) # 80005440 <fdalloc>
    80005f40:	fca42223          	sw	a0,-60(s0)
    80005f44:	08054c63          	bltz	a0,80005fdc <sys_pipe+0xea>
    80005f48:	fc843503          	ld	a0,-56(s0)
    80005f4c:	fffff097          	auipc	ra,0xfffff
    80005f50:	4f4080e7          	jalr	1268(ra) # 80005440 <fdalloc>
    80005f54:	fca42023          	sw	a0,-64(s0)
    80005f58:	06054863          	bltz	a0,80005fc8 <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005f5c:	4691                	li	a3,4
    80005f5e:	fc440613          	addi	a2,s0,-60
    80005f62:	fd843583          	ld	a1,-40(s0)
    80005f66:	78a8                	ld	a0,112(s1)
    80005f68:	ffffb097          	auipc	ra,0xffffb
    80005f6c:	712080e7          	jalr	1810(ra) # 8000167a <copyout>
    80005f70:	02054063          	bltz	a0,80005f90 <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005f74:	4691                	li	a3,4
    80005f76:	fc040613          	addi	a2,s0,-64
    80005f7a:	fd843583          	ld	a1,-40(s0)
    80005f7e:	0591                	addi	a1,a1,4
    80005f80:	78a8                	ld	a0,112(s1)
    80005f82:	ffffb097          	auipc	ra,0xffffb
    80005f86:	6f8080e7          	jalr	1784(ra) # 8000167a <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005f8a:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005f8c:	06055563          	bgez	a0,80005ff6 <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80005f90:	fc442783          	lw	a5,-60(s0)
    80005f94:	07f9                	addi	a5,a5,30
    80005f96:	078e                	slli	a5,a5,0x3
    80005f98:	97a6                	add	a5,a5,s1
    80005f9a:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005f9e:	fc042503          	lw	a0,-64(s0)
    80005fa2:	0579                	addi	a0,a0,30
    80005fa4:	050e                	slli	a0,a0,0x3
    80005fa6:	9526                	add	a0,a0,s1
    80005fa8:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005fac:	fd043503          	ld	a0,-48(s0)
    80005fb0:	fffff097          	auipc	ra,0xfffff
    80005fb4:	a3e080e7          	jalr	-1474(ra) # 800049ee <fileclose>
    fileclose(wf);
    80005fb8:	fc843503          	ld	a0,-56(s0)
    80005fbc:	fffff097          	auipc	ra,0xfffff
    80005fc0:	a32080e7          	jalr	-1486(ra) # 800049ee <fileclose>
    return -1;
    80005fc4:	57fd                	li	a5,-1
    80005fc6:	a805                	j	80005ff6 <sys_pipe+0x104>
    if(fd0 >= 0)
    80005fc8:	fc442783          	lw	a5,-60(s0)
    80005fcc:	0007c863          	bltz	a5,80005fdc <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80005fd0:	01e78513          	addi	a0,a5,30
    80005fd4:	050e                	slli	a0,a0,0x3
    80005fd6:	9526                	add	a0,a0,s1
    80005fd8:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005fdc:	fd043503          	ld	a0,-48(s0)
    80005fe0:	fffff097          	auipc	ra,0xfffff
    80005fe4:	a0e080e7          	jalr	-1522(ra) # 800049ee <fileclose>
    fileclose(wf);
    80005fe8:	fc843503          	ld	a0,-56(s0)
    80005fec:	fffff097          	auipc	ra,0xfffff
    80005ff0:	a02080e7          	jalr	-1534(ra) # 800049ee <fileclose>
    return -1;
    80005ff4:	57fd                	li	a5,-1
}
    80005ff6:	853e                	mv	a0,a5
    80005ff8:	70e2                	ld	ra,56(sp)
    80005ffa:	7442                	ld	s0,48(sp)
    80005ffc:	74a2                	ld	s1,40(sp)
    80005ffe:	6121                	addi	sp,sp,64
    80006000:	8082                	ret
	...

0000000080006010 <kernelvec>:
    80006010:	7111                	addi	sp,sp,-256
    80006012:	e006                	sd	ra,0(sp)
    80006014:	e40a                	sd	sp,8(sp)
    80006016:	e80e                	sd	gp,16(sp)
    80006018:	ec12                	sd	tp,24(sp)
    8000601a:	f016                	sd	t0,32(sp)
    8000601c:	f41a                	sd	t1,40(sp)
    8000601e:	f81e                	sd	t2,48(sp)
    80006020:	fc22                	sd	s0,56(sp)
    80006022:	e0a6                	sd	s1,64(sp)
    80006024:	e4aa                	sd	a0,72(sp)
    80006026:	e8ae                	sd	a1,80(sp)
    80006028:	ecb2                	sd	a2,88(sp)
    8000602a:	f0b6                	sd	a3,96(sp)
    8000602c:	f4ba                	sd	a4,104(sp)
    8000602e:	f8be                	sd	a5,112(sp)
    80006030:	fcc2                	sd	a6,120(sp)
    80006032:	e146                	sd	a7,128(sp)
    80006034:	e54a                	sd	s2,136(sp)
    80006036:	e94e                	sd	s3,144(sp)
    80006038:	ed52                	sd	s4,152(sp)
    8000603a:	f156                	sd	s5,160(sp)
    8000603c:	f55a                	sd	s6,168(sp)
    8000603e:	f95e                	sd	s7,176(sp)
    80006040:	fd62                	sd	s8,184(sp)
    80006042:	e1e6                	sd	s9,192(sp)
    80006044:	e5ea                	sd	s10,200(sp)
    80006046:	e9ee                	sd	s11,208(sp)
    80006048:	edf2                	sd	t3,216(sp)
    8000604a:	f1f6                	sd	t4,224(sp)
    8000604c:	f5fa                	sd	t5,232(sp)
    8000604e:	f9fe                	sd	t6,240(sp)
    80006050:	d59fc0ef          	jal	ra,80002da8 <kerneltrap>
    80006054:	6082                	ld	ra,0(sp)
    80006056:	6122                	ld	sp,8(sp)
    80006058:	61c2                	ld	gp,16(sp)
    8000605a:	7282                	ld	t0,32(sp)
    8000605c:	7322                	ld	t1,40(sp)
    8000605e:	73c2                	ld	t2,48(sp)
    80006060:	7462                	ld	s0,56(sp)
    80006062:	6486                	ld	s1,64(sp)
    80006064:	6526                	ld	a0,72(sp)
    80006066:	65c6                	ld	a1,80(sp)
    80006068:	6666                	ld	a2,88(sp)
    8000606a:	7686                	ld	a3,96(sp)
    8000606c:	7726                	ld	a4,104(sp)
    8000606e:	77c6                	ld	a5,112(sp)
    80006070:	7866                	ld	a6,120(sp)
    80006072:	688a                	ld	a7,128(sp)
    80006074:	692a                	ld	s2,136(sp)
    80006076:	69ca                	ld	s3,144(sp)
    80006078:	6a6a                	ld	s4,152(sp)
    8000607a:	7a8a                	ld	s5,160(sp)
    8000607c:	7b2a                	ld	s6,168(sp)
    8000607e:	7bca                	ld	s7,176(sp)
    80006080:	7c6a                	ld	s8,184(sp)
    80006082:	6c8e                	ld	s9,192(sp)
    80006084:	6d2e                	ld	s10,200(sp)
    80006086:	6dce                	ld	s11,208(sp)
    80006088:	6e6e                	ld	t3,216(sp)
    8000608a:	7e8e                	ld	t4,224(sp)
    8000608c:	7f2e                	ld	t5,232(sp)
    8000608e:	7fce                	ld	t6,240(sp)
    80006090:	6111                	addi	sp,sp,256
    80006092:	10200073          	sret
    80006096:	00000013          	nop
    8000609a:	00000013          	nop
    8000609e:	0001                	nop

00000000800060a0 <timervec>:
    800060a0:	34051573          	csrrw	a0,mscratch,a0
    800060a4:	e10c                	sd	a1,0(a0)
    800060a6:	e510                	sd	a2,8(a0)
    800060a8:	e914                	sd	a3,16(a0)
    800060aa:	6d0c                	ld	a1,24(a0)
    800060ac:	7110                	ld	a2,32(a0)
    800060ae:	6194                	ld	a3,0(a1)
    800060b0:	96b2                	add	a3,a3,a2
    800060b2:	e194                	sd	a3,0(a1)
    800060b4:	4589                	li	a1,2
    800060b6:	14459073          	csrw	sip,a1
    800060ba:	6914                	ld	a3,16(a0)
    800060bc:	6510                	ld	a2,8(a0)
    800060be:	610c                	ld	a1,0(a0)
    800060c0:	34051573          	csrrw	a0,mscratch,a0
    800060c4:	30200073          	mret
	...

00000000800060ca <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    800060ca:	1141                	addi	sp,sp,-16
    800060cc:	e422                	sd	s0,8(sp)
    800060ce:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    800060d0:	0c0007b7          	lui	a5,0xc000
    800060d4:	4705                	li	a4,1
    800060d6:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    800060d8:	c3d8                	sw	a4,4(a5)
}
    800060da:	6422                	ld	s0,8(sp)
    800060dc:	0141                	addi	sp,sp,16
    800060de:	8082                	ret

00000000800060e0 <plicinithart>:

void
plicinithart(void)
{
    800060e0:	1141                	addi	sp,sp,-16
    800060e2:	e406                	sd	ra,8(sp)
    800060e4:	e022                	sd	s0,0(sp)
    800060e6:	0800                	addi	s0,sp,16
  int hart = cpuid();
    800060e8:	ffffc097          	auipc	ra,0xffffc
    800060ec:	8b4080e7          	jalr	-1868(ra) # 8000199c <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    800060f0:	0085171b          	slliw	a4,a0,0x8
    800060f4:	0c0027b7          	lui	a5,0xc002
    800060f8:	97ba                	add	a5,a5,a4
    800060fa:	40200713          	li	a4,1026
    800060fe:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80006102:	00d5151b          	slliw	a0,a0,0xd
    80006106:	0c2017b7          	lui	a5,0xc201
    8000610a:	953e                	add	a0,a0,a5
    8000610c:	00052023          	sw	zero,0(a0)
}
    80006110:	60a2                	ld	ra,8(sp)
    80006112:	6402                	ld	s0,0(sp)
    80006114:	0141                	addi	sp,sp,16
    80006116:	8082                	ret

0000000080006118 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80006118:	1141                	addi	sp,sp,-16
    8000611a:	e406                	sd	ra,8(sp)
    8000611c:	e022                	sd	s0,0(sp)
    8000611e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006120:	ffffc097          	auipc	ra,0xffffc
    80006124:	87c080e7          	jalr	-1924(ra) # 8000199c <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80006128:	00d5179b          	slliw	a5,a0,0xd
    8000612c:	0c201537          	lui	a0,0xc201
    80006130:	953e                	add	a0,a0,a5
  return irq;
}
    80006132:	4148                	lw	a0,4(a0)
    80006134:	60a2                	ld	ra,8(sp)
    80006136:	6402                	ld	s0,0(sp)
    80006138:	0141                	addi	sp,sp,16
    8000613a:	8082                	ret

000000008000613c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    8000613c:	1101                	addi	sp,sp,-32
    8000613e:	ec06                	sd	ra,24(sp)
    80006140:	e822                	sd	s0,16(sp)
    80006142:	e426                	sd	s1,8(sp)
    80006144:	1000                	addi	s0,sp,32
    80006146:	84aa                	mv	s1,a0
  int hart = cpuid();
    80006148:	ffffc097          	auipc	ra,0xffffc
    8000614c:	854080e7          	jalr	-1964(ra) # 8000199c <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80006150:	00d5151b          	slliw	a0,a0,0xd
    80006154:	0c2017b7          	lui	a5,0xc201
    80006158:	97aa                	add	a5,a5,a0
    8000615a:	c3c4                	sw	s1,4(a5)
}
    8000615c:	60e2                	ld	ra,24(sp)
    8000615e:	6442                	ld	s0,16(sp)
    80006160:	64a2                	ld	s1,8(sp)
    80006162:	6105                	addi	sp,sp,32
    80006164:	8082                	ret

0000000080006166 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80006166:	1141                	addi	sp,sp,-16
    80006168:	e406                	sd	ra,8(sp)
    8000616a:	e022                	sd	s0,0(sp)
    8000616c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    8000616e:	479d                	li	a5,7
    80006170:	06a7c963          	blt	a5,a0,800061e2 <free_desc+0x7c>
    panic("free_desc 1");
  if(disk.free[i])
    80006174:	0001d797          	auipc	a5,0x1d
    80006178:	e8c78793          	addi	a5,a5,-372 # 80023000 <disk>
    8000617c:	00a78733          	add	a4,a5,a0
    80006180:	6789                	lui	a5,0x2
    80006182:	97ba                	add	a5,a5,a4
    80006184:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80006188:	e7ad                	bnez	a5,800061f2 <free_desc+0x8c>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    8000618a:	00451793          	slli	a5,a0,0x4
    8000618e:	0001f717          	auipc	a4,0x1f
    80006192:	e7270713          	addi	a4,a4,-398 # 80025000 <disk+0x2000>
    80006196:	6314                	ld	a3,0(a4)
    80006198:	96be                	add	a3,a3,a5
    8000619a:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    8000619e:	6314                	ld	a3,0(a4)
    800061a0:	96be                	add	a3,a3,a5
    800061a2:	0006a423          	sw	zero,8(a3)
  disk.desc[i].flags = 0;
    800061a6:	6314                	ld	a3,0(a4)
    800061a8:	96be                	add	a3,a3,a5
    800061aa:	00069623          	sh	zero,12(a3)
  disk.desc[i].next = 0;
    800061ae:	6318                	ld	a4,0(a4)
    800061b0:	97ba                	add	a5,a5,a4
    800061b2:	00079723          	sh	zero,14(a5)
  disk.free[i] = 1;
    800061b6:	0001d797          	auipc	a5,0x1d
    800061ba:	e4a78793          	addi	a5,a5,-438 # 80023000 <disk>
    800061be:	97aa                	add	a5,a5,a0
    800061c0:	6509                	lui	a0,0x2
    800061c2:	953e                	add	a0,a0,a5
    800061c4:	4785                	li	a5,1
    800061c6:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    800061ca:	0001f517          	auipc	a0,0x1f
    800061ce:	e4e50513          	addi	a0,a0,-434 # 80025018 <disk+0x2018>
    800061d2:	ffffc097          	auipc	ra,0xffffc
    800061d6:	348080e7          	jalr	840(ra) # 8000251a <wakeup>
}
    800061da:	60a2                	ld	ra,8(sp)
    800061dc:	6402                	ld	s0,0(sp)
    800061de:	0141                	addi	sp,sp,16
    800061e0:	8082                	ret
    panic("free_desc 1");
    800061e2:	00002517          	auipc	a0,0x2
    800061e6:	64e50513          	addi	a0,a0,1614 # 80008830 <syscalls+0x338>
    800061ea:	ffffa097          	auipc	ra,0xffffa
    800061ee:	354080e7          	jalr	852(ra) # 8000053e <panic>
    panic("free_desc 2");
    800061f2:	00002517          	auipc	a0,0x2
    800061f6:	64e50513          	addi	a0,a0,1614 # 80008840 <syscalls+0x348>
    800061fa:	ffffa097          	auipc	ra,0xffffa
    800061fe:	344080e7          	jalr	836(ra) # 8000053e <panic>

0000000080006202 <virtio_disk_init>:
{
    80006202:	1101                	addi	sp,sp,-32
    80006204:	ec06                	sd	ra,24(sp)
    80006206:	e822                	sd	s0,16(sp)
    80006208:	e426                	sd	s1,8(sp)
    8000620a:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    8000620c:	00002597          	auipc	a1,0x2
    80006210:	64458593          	addi	a1,a1,1604 # 80008850 <syscalls+0x358>
    80006214:	0001f517          	auipc	a0,0x1f
    80006218:	f1450513          	addi	a0,a0,-236 # 80025128 <disk+0x2128>
    8000621c:	ffffb097          	auipc	ra,0xffffb
    80006220:	938080e7          	jalr	-1736(ra) # 80000b54 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006224:	100017b7          	lui	a5,0x10001
    80006228:	4398                	lw	a4,0(a5)
    8000622a:	2701                	sext.w	a4,a4
    8000622c:	747277b7          	lui	a5,0x74727
    80006230:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80006234:	0ef71163          	bne	a4,a5,80006316 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80006238:	100017b7          	lui	a5,0x10001
    8000623c:	43dc                	lw	a5,4(a5)
    8000623e:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006240:	4705                	li	a4,1
    80006242:	0ce79a63          	bne	a5,a4,80006316 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80006246:	100017b7          	lui	a5,0x10001
    8000624a:	479c                	lw	a5,8(a5)
    8000624c:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    8000624e:	4709                	li	a4,2
    80006250:	0ce79363          	bne	a5,a4,80006316 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80006254:	100017b7          	lui	a5,0x10001
    80006258:	47d8                	lw	a4,12(a5)
    8000625a:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    8000625c:	554d47b7          	lui	a5,0x554d4
    80006260:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80006264:	0af71963          	bne	a4,a5,80006316 <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    80006268:	100017b7          	lui	a5,0x10001
    8000626c:	4705                	li	a4,1
    8000626e:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006270:	470d                	li	a4,3
    80006272:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80006274:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80006276:	c7ffe737          	lui	a4,0xc7ffe
    8000627a:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd875f>
    8000627e:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80006280:	2701                	sext.w	a4,a4
    80006282:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006284:	472d                	li	a4,11
    80006286:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006288:	473d                	li	a4,15
    8000628a:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    8000628c:	6705                	lui	a4,0x1
    8000628e:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80006290:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80006294:	5bdc                	lw	a5,52(a5)
    80006296:	2781                	sext.w	a5,a5
  if(max == 0)
    80006298:	c7d9                	beqz	a5,80006326 <virtio_disk_init+0x124>
  if(max < NUM)
    8000629a:	471d                	li	a4,7
    8000629c:	08f77d63          	bgeu	a4,a5,80006336 <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    800062a0:	100014b7          	lui	s1,0x10001
    800062a4:	47a1                	li	a5,8
    800062a6:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    800062a8:	6609                	lui	a2,0x2
    800062aa:	4581                	li	a1,0
    800062ac:	0001d517          	auipc	a0,0x1d
    800062b0:	d5450513          	addi	a0,a0,-684 # 80023000 <disk>
    800062b4:	ffffb097          	auipc	ra,0xffffb
    800062b8:	a2c080e7          	jalr	-1492(ra) # 80000ce0 <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    800062bc:	0001d717          	auipc	a4,0x1d
    800062c0:	d4470713          	addi	a4,a4,-700 # 80023000 <disk>
    800062c4:	00c75793          	srli	a5,a4,0xc
    800062c8:	2781                	sext.w	a5,a5
    800062ca:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    800062cc:	0001f797          	auipc	a5,0x1f
    800062d0:	d3478793          	addi	a5,a5,-716 # 80025000 <disk+0x2000>
    800062d4:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    800062d6:	0001d717          	auipc	a4,0x1d
    800062da:	daa70713          	addi	a4,a4,-598 # 80023080 <disk+0x80>
    800062de:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    800062e0:	0001e717          	auipc	a4,0x1e
    800062e4:	d2070713          	addi	a4,a4,-736 # 80024000 <disk+0x1000>
    800062e8:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    800062ea:	4705                	li	a4,1
    800062ec:	00e78c23          	sb	a4,24(a5)
    800062f0:	00e78ca3          	sb	a4,25(a5)
    800062f4:	00e78d23          	sb	a4,26(a5)
    800062f8:	00e78da3          	sb	a4,27(a5)
    800062fc:	00e78e23          	sb	a4,28(a5)
    80006300:	00e78ea3          	sb	a4,29(a5)
    80006304:	00e78f23          	sb	a4,30(a5)
    80006308:	00e78fa3          	sb	a4,31(a5)
}
    8000630c:	60e2                	ld	ra,24(sp)
    8000630e:	6442                	ld	s0,16(sp)
    80006310:	64a2                	ld	s1,8(sp)
    80006312:	6105                	addi	sp,sp,32
    80006314:	8082                	ret
    panic("could not find virtio disk");
    80006316:	00002517          	auipc	a0,0x2
    8000631a:	54a50513          	addi	a0,a0,1354 # 80008860 <syscalls+0x368>
    8000631e:	ffffa097          	auipc	ra,0xffffa
    80006322:	220080e7          	jalr	544(ra) # 8000053e <panic>
    panic("virtio disk has no queue 0");
    80006326:	00002517          	auipc	a0,0x2
    8000632a:	55a50513          	addi	a0,a0,1370 # 80008880 <syscalls+0x388>
    8000632e:	ffffa097          	auipc	ra,0xffffa
    80006332:	210080e7          	jalr	528(ra) # 8000053e <panic>
    panic("virtio disk max queue too short");
    80006336:	00002517          	auipc	a0,0x2
    8000633a:	56a50513          	addi	a0,a0,1386 # 800088a0 <syscalls+0x3a8>
    8000633e:	ffffa097          	auipc	ra,0xffffa
    80006342:	200080e7          	jalr	512(ra) # 8000053e <panic>

0000000080006346 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80006346:	7159                	addi	sp,sp,-112
    80006348:	f486                	sd	ra,104(sp)
    8000634a:	f0a2                	sd	s0,96(sp)
    8000634c:	eca6                	sd	s1,88(sp)
    8000634e:	e8ca                	sd	s2,80(sp)
    80006350:	e4ce                	sd	s3,72(sp)
    80006352:	e0d2                	sd	s4,64(sp)
    80006354:	fc56                	sd	s5,56(sp)
    80006356:	f85a                	sd	s6,48(sp)
    80006358:	f45e                	sd	s7,40(sp)
    8000635a:	f062                	sd	s8,32(sp)
    8000635c:	ec66                	sd	s9,24(sp)
    8000635e:	e86a                	sd	s10,16(sp)
    80006360:	1880                	addi	s0,sp,112
    80006362:	892a                	mv	s2,a0
    80006364:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80006366:	00c52c83          	lw	s9,12(a0)
    8000636a:	001c9c9b          	slliw	s9,s9,0x1
    8000636e:	1c82                	slli	s9,s9,0x20
    80006370:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80006374:	0001f517          	auipc	a0,0x1f
    80006378:	db450513          	addi	a0,a0,-588 # 80025128 <disk+0x2128>
    8000637c:	ffffb097          	auipc	ra,0xffffb
    80006380:	868080e7          	jalr	-1944(ra) # 80000be4 <acquire>
  for(int i = 0; i < 3; i++){
    80006384:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80006386:	4c21                	li	s8,8
      disk.free[i] = 0;
    80006388:	0001db97          	auipc	s7,0x1d
    8000638c:	c78b8b93          	addi	s7,s7,-904 # 80023000 <disk>
    80006390:	6b09                	lui	s6,0x2
  for(int i = 0; i < 3; i++){
    80006392:	4a8d                	li	s5,3
  for(int i = 0; i < NUM; i++){
    80006394:	8a4e                	mv	s4,s3
    80006396:	a051                	j	8000641a <virtio_disk_rw+0xd4>
      disk.free[i] = 0;
    80006398:	00fb86b3          	add	a3,s7,a5
    8000639c:	96da                	add	a3,a3,s6
    8000639e:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    800063a2:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    800063a4:	0207c563          	bltz	a5,800063ce <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    800063a8:	2485                	addiw	s1,s1,1
    800063aa:	0711                	addi	a4,a4,4
    800063ac:	25548063          	beq	s1,s5,800065ec <virtio_disk_rw+0x2a6>
    idx[i] = alloc_desc();
    800063b0:	863a                	mv	a2,a4
  for(int i = 0; i < NUM; i++){
    800063b2:	0001f697          	auipc	a3,0x1f
    800063b6:	c6668693          	addi	a3,a3,-922 # 80025018 <disk+0x2018>
    800063ba:	87d2                	mv	a5,s4
    if(disk.free[i]){
    800063bc:	0006c583          	lbu	a1,0(a3)
    800063c0:	fde1                	bnez	a1,80006398 <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    800063c2:	2785                	addiw	a5,a5,1
    800063c4:	0685                	addi	a3,a3,1
    800063c6:	ff879be3          	bne	a5,s8,800063bc <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    800063ca:	57fd                	li	a5,-1
    800063cc:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    800063ce:	02905a63          	blez	s1,80006402 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    800063d2:	f9042503          	lw	a0,-112(s0)
    800063d6:	00000097          	auipc	ra,0x0
    800063da:	d90080e7          	jalr	-624(ra) # 80006166 <free_desc>
      for(int j = 0; j < i; j++)
    800063de:	4785                	li	a5,1
    800063e0:	0297d163          	bge	a5,s1,80006402 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    800063e4:	f9442503          	lw	a0,-108(s0)
    800063e8:	00000097          	auipc	ra,0x0
    800063ec:	d7e080e7          	jalr	-642(ra) # 80006166 <free_desc>
      for(int j = 0; j < i; j++)
    800063f0:	4789                	li	a5,2
    800063f2:	0097d863          	bge	a5,s1,80006402 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    800063f6:	f9842503          	lw	a0,-104(s0)
    800063fa:	00000097          	auipc	ra,0x0
    800063fe:	d6c080e7          	jalr	-660(ra) # 80006166 <free_desc>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006402:	0001f597          	auipc	a1,0x1f
    80006406:	d2658593          	addi	a1,a1,-730 # 80025128 <disk+0x2128>
    8000640a:	0001f517          	auipc	a0,0x1f
    8000640e:	c0e50513          	addi	a0,a0,-1010 # 80025018 <disk+0x2018>
    80006412:	ffffc097          	auipc	ra,0xffffc
    80006416:	f68080e7          	jalr	-152(ra) # 8000237a <sleep>
  for(int i = 0; i < 3; i++){
    8000641a:	f9040713          	addi	a4,s0,-112
    8000641e:	84ce                	mv	s1,s3
    80006420:	bf41                	j	800063b0 <virtio_disk_rw+0x6a>
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];

  if(write)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
    80006422:	20058713          	addi	a4,a1,512
    80006426:	00471693          	slli	a3,a4,0x4
    8000642a:	0001d717          	auipc	a4,0x1d
    8000642e:	bd670713          	addi	a4,a4,-1066 # 80023000 <disk>
    80006432:	9736                	add	a4,a4,a3
    80006434:	4685                	li	a3,1
    80006436:	0ad72423          	sw	a3,168(a4)
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    8000643a:	20058713          	addi	a4,a1,512
    8000643e:	00471693          	slli	a3,a4,0x4
    80006442:	0001d717          	auipc	a4,0x1d
    80006446:	bbe70713          	addi	a4,a4,-1090 # 80023000 <disk>
    8000644a:	9736                	add	a4,a4,a3
    8000644c:	0a072623          	sw	zero,172(a4)
  buf0->sector = sector;
    80006450:	0b973823          	sd	s9,176(a4)

  disk.desc[idx[0]].addr = (uint64) buf0;
    80006454:	7679                	lui	a2,0xffffe
    80006456:	963e                	add	a2,a2,a5
    80006458:	0001f697          	auipc	a3,0x1f
    8000645c:	ba868693          	addi	a3,a3,-1112 # 80025000 <disk+0x2000>
    80006460:	6298                	ld	a4,0(a3)
    80006462:	9732                	add	a4,a4,a2
    80006464:	e308                	sd	a0,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    80006466:	6298                	ld	a4,0(a3)
    80006468:	9732                	add	a4,a4,a2
    8000646a:	4541                	li	a0,16
    8000646c:	c708                	sw	a0,8(a4)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    8000646e:	6298                	ld	a4,0(a3)
    80006470:	9732                	add	a4,a4,a2
    80006472:	4505                	li	a0,1
    80006474:	00a71623          	sh	a0,12(a4)
  disk.desc[idx[0]].next = idx[1];
    80006478:	f9442703          	lw	a4,-108(s0)
    8000647c:	6288                	ld	a0,0(a3)
    8000647e:	962a                	add	a2,a2,a0
    80006480:	00e61723          	sh	a4,14(a2) # ffffffffffffe00e <end+0xffffffff7ffd800e>

  disk.desc[idx[1]].addr = (uint64) b->data;
    80006484:	0712                	slli	a4,a4,0x4
    80006486:	6290                	ld	a2,0(a3)
    80006488:	963a                	add	a2,a2,a4
    8000648a:	05890513          	addi	a0,s2,88
    8000648e:	e208                	sd	a0,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    80006490:	6294                	ld	a3,0(a3)
    80006492:	96ba                	add	a3,a3,a4
    80006494:	40000613          	li	a2,1024
    80006498:	c690                	sw	a2,8(a3)
  if(write)
    8000649a:	140d0063          	beqz	s10,800065da <virtio_disk_rw+0x294>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    8000649e:	0001f697          	auipc	a3,0x1f
    800064a2:	b626b683          	ld	a3,-1182(a3) # 80025000 <disk+0x2000>
    800064a6:	96ba                	add	a3,a3,a4
    800064a8:	00069623          	sh	zero,12(a3)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    800064ac:	0001d817          	auipc	a6,0x1d
    800064b0:	b5480813          	addi	a6,a6,-1196 # 80023000 <disk>
    800064b4:	0001f517          	auipc	a0,0x1f
    800064b8:	b4c50513          	addi	a0,a0,-1204 # 80025000 <disk+0x2000>
    800064bc:	6114                	ld	a3,0(a0)
    800064be:	96ba                	add	a3,a3,a4
    800064c0:	00c6d603          	lhu	a2,12(a3)
    800064c4:	00166613          	ori	a2,a2,1
    800064c8:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    800064cc:	f9842683          	lw	a3,-104(s0)
    800064d0:	6110                	ld	a2,0(a0)
    800064d2:	9732                	add	a4,a4,a2
    800064d4:	00d71723          	sh	a3,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    800064d8:	20058613          	addi	a2,a1,512
    800064dc:	0612                	slli	a2,a2,0x4
    800064de:	9642                	add	a2,a2,a6
    800064e0:	577d                	li	a4,-1
    800064e2:	02e60823          	sb	a4,48(a2)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    800064e6:	00469713          	slli	a4,a3,0x4
    800064ea:	6114                	ld	a3,0(a0)
    800064ec:	96ba                	add	a3,a3,a4
    800064ee:	03078793          	addi	a5,a5,48
    800064f2:	97c2                	add	a5,a5,a6
    800064f4:	e29c                	sd	a5,0(a3)
  disk.desc[idx[2]].len = 1;
    800064f6:	611c                	ld	a5,0(a0)
    800064f8:	97ba                	add	a5,a5,a4
    800064fa:	4685                	li	a3,1
    800064fc:	c794                	sw	a3,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    800064fe:	611c                	ld	a5,0(a0)
    80006500:	97ba                	add	a5,a5,a4
    80006502:	4809                	li	a6,2
    80006504:	01079623          	sh	a6,12(a5)
  disk.desc[idx[2]].next = 0;
    80006508:	611c                	ld	a5,0(a0)
    8000650a:	973e                	add	a4,a4,a5
    8000650c:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80006510:	00d92223          	sw	a3,4(s2)
  disk.info[idx[0]].b = b;
    80006514:	03263423          	sd	s2,40(a2)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006518:	6518                	ld	a4,8(a0)
    8000651a:	00275783          	lhu	a5,2(a4)
    8000651e:	8b9d                	andi	a5,a5,7
    80006520:	0786                	slli	a5,a5,0x1
    80006522:	97ba                	add	a5,a5,a4
    80006524:	00b79223          	sh	a1,4(a5)

  __sync_synchronize();
    80006528:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    8000652c:	6518                	ld	a4,8(a0)
    8000652e:	00275783          	lhu	a5,2(a4)
    80006532:	2785                	addiw	a5,a5,1
    80006534:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006538:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    8000653c:	100017b7          	lui	a5,0x10001
    80006540:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006544:	00492703          	lw	a4,4(s2)
    80006548:	4785                	li	a5,1
    8000654a:	02f71163          	bne	a4,a5,8000656c <virtio_disk_rw+0x226>
    sleep(b, &disk.vdisk_lock);
    8000654e:	0001f997          	auipc	s3,0x1f
    80006552:	bda98993          	addi	s3,s3,-1062 # 80025128 <disk+0x2128>
  while(b->disk == 1) {
    80006556:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80006558:	85ce                	mv	a1,s3
    8000655a:	854a                	mv	a0,s2
    8000655c:	ffffc097          	auipc	ra,0xffffc
    80006560:	e1e080e7          	jalr	-482(ra) # 8000237a <sleep>
  while(b->disk == 1) {
    80006564:	00492783          	lw	a5,4(s2)
    80006568:	fe9788e3          	beq	a5,s1,80006558 <virtio_disk_rw+0x212>
  }

  disk.info[idx[0]].b = 0;
    8000656c:	f9042903          	lw	s2,-112(s0)
    80006570:	20090793          	addi	a5,s2,512
    80006574:	00479713          	slli	a4,a5,0x4
    80006578:	0001d797          	auipc	a5,0x1d
    8000657c:	a8878793          	addi	a5,a5,-1400 # 80023000 <disk>
    80006580:	97ba                	add	a5,a5,a4
    80006582:	0207b423          	sd	zero,40(a5)
    int flag = disk.desc[i].flags;
    80006586:	0001f997          	auipc	s3,0x1f
    8000658a:	a7a98993          	addi	s3,s3,-1414 # 80025000 <disk+0x2000>
    8000658e:	00491713          	slli	a4,s2,0x4
    80006592:	0009b783          	ld	a5,0(s3)
    80006596:	97ba                	add	a5,a5,a4
    80006598:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    8000659c:	854a                	mv	a0,s2
    8000659e:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    800065a2:	00000097          	auipc	ra,0x0
    800065a6:	bc4080e7          	jalr	-1084(ra) # 80006166 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    800065aa:	8885                	andi	s1,s1,1
    800065ac:	f0ed                	bnez	s1,8000658e <virtio_disk_rw+0x248>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    800065ae:	0001f517          	auipc	a0,0x1f
    800065b2:	b7a50513          	addi	a0,a0,-1158 # 80025128 <disk+0x2128>
    800065b6:	ffffa097          	auipc	ra,0xffffa
    800065ba:	6e2080e7          	jalr	1762(ra) # 80000c98 <release>
}
    800065be:	70a6                	ld	ra,104(sp)
    800065c0:	7406                	ld	s0,96(sp)
    800065c2:	64e6                	ld	s1,88(sp)
    800065c4:	6946                	ld	s2,80(sp)
    800065c6:	69a6                	ld	s3,72(sp)
    800065c8:	6a06                	ld	s4,64(sp)
    800065ca:	7ae2                	ld	s5,56(sp)
    800065cc:	7b42                	ld	s6,48(sp)
    800065ce:	7ba2                	ld	s7,40(sp)
    800065d0:	7c02                	ld	s8,32(sp)
    800065d2:	6ce2                	ld	s9,24(sp)
    800065d4:	6d42                	ld	s10,16(sp)
    800065d6:	6165                	addi	sp,sp,112
    800065d8:	8082                	ret
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    800065da:	0001f697          	auipc	a3,0x1f
    800065de:	a266b683          	ld	a3,-1498(a3) # 80025000 <disk+0x2000>
    800065e2:	96ba                	add	a3,a3,a4
    800065e4:	4609                	li	a2,2
    800065e6:	00c69623          	sh	a2,12(a3)
    800065ea:	b5c9                	j	800064ac <virtio_disk_rw+0x166>
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    800065ec:	f9042583          	lw	a1,-112(s0)
    800065f0:	20058793          	addi	a5,a1,512
    800065f4:	0792                	slli	a5,a5,0x4
    800065f6:	0001d517          	auipc	a0,0x1d
    800065fa:	ab250513          	addi	a0,a0,-1358 # 800230a8 <disk+0xa8>
    800065fe:	953e                	add	a0,a0,a5
  if(write)
    80006600:	e20d11e3          	bnez	s10,80006422 <virtio_disk_rw+0xdc>
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
    80006604:	20058713          	addi	a4,a1,512
    80006608:	00471693          	slli	a3,a4,0x4
    8000660c:	0001d717          	auipc	a4,0x1d
    80006610:	9f470713          	addi	a4,a4,-1548 # 80023000 <disk>
    80006614:	9736                	add	a4,a4,a3
    80006616:	0a072423          	sw	zero,168(a4)
    8000661a:	b505                	j	8000643a <virtio_disk_rw+0xf4>

000000008000661c <virtio_disk_intr>:

void
virtio_disk_intr()
{
    8000661c:	1101                	addi	sp,sp,-32
    8000661e:	ec06                	sd	ra,24(sp)
    80006620:	e822                	sd	s0,16(sp)
    80006622:	e426                	sd	s1,8(sp)
    80006624:	e04a                	sd	s2,0(sp)
    80006626:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80006628:	0001f517          	auipc	a0,0x1f
    8000662c:	b0050513          	addi	a0,a0,-1280 # 80025128 <disk+0x2128>
    80006630:	ffffa097          	auipc	ra,0xffffa
    80006634:	5b4080e7          	jalr	1460(ra) # 80000be4 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80006638:	10001737          	lui	a4,0x10001
    8000663c:	533c                	lw	a5,96(a4)
    8000663e:	8b8d                	andi	a5,a5,3
    80006640:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    80006642:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006646:	0001f797          	auipc	a5,0x1f
    8000664a:	9ba78793          	addi	a5,a5,-1606 # 80025000 <disk+0x2000>
    8000664e:	6b94                	ld	a3,16(a5)
    80006650:	0207d703          	lhu	a4,32(a5)
    80006654:	0026d783          	lhu	a5,2(a3)
    80006658:	06f70163          	beq	a4,a5,800066ba <virtio_disk_intr+0x9e>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    8000665c:	0001d917          	auipc	s2,0x1d
    80006660:	9a490913          	addi	s2,s2,-1628 # 80023000 <disk>
    80006664:	0001f497          	auipc	s1,0x1f
    80006668:	99c48493          	addi	s1,s1,-1636 # 80025000 <disk+0x2000>
    __sync_synchronize();
    8000666c:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006670:	6898                	ld	a4,16(s1)
    80006672:	0204d783          	lhu	a5,32(s1)
    80006676:	8b9d                	andi	a5,a5,7
    80006678:	078e                	slli	a5,a5,0x3
    8000667a:	97ba                	add	a5,a5,a4
    8000667c:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    8000667e:	20078713          	addi	a4,a5,512
    80006682:	0712                	slli	a4,a4,0x4
    80006684:	974a                	add	a4,a4,s2
    80006686:	03074703          	lbu	a4,48(a4) # 10001030 <_entry-0x6fffefd0>
    8000668a:	e731                	bnez	a4,800066d6 <virtio_disk_intr+0xba>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    8000668c:	20078793          	addi	a5,a5,512
    80006690:	0792                	slli	a5,a5,0x4
    80006692:	97ca                	add	a5,a5,s2
    80006694:	7788                	ld	a0,40(a5)
    b->disk = 0;   // disk is done with buf
    80006696:	00052223          	sw	zero,4(a0)
    wakeup(b);
    8000669a:	ffffc097          	auipc	ra,0xffffc
    8000669e:	e80080e7          	jalr	-384(ra) # 8000251a <wakeup>

    disk.used_idx += 1;
    800066a2:	0204d783          	lhu	a5,32(s1)
    800066a6:	2785                	addiw	a5,a5,1
    800066a8:	17c2                	slli	a5,a5,0x30
    800066aa:	93c1                	srli	a5,a5,0x30
    800066ac:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    800066b0:	6898                	ld	a4,16(s1)
    800066b2:	00275703          	lhu	a4,2(a4)
    800066b6:	faf71be3          	bne	a4,a5,8000666c <virtio_disk_intr+0x50>
  }

  release(&disk.vdisk_lock);
    800066ba:	0001f517          	auipc	a0,0x1f
    800066be:	a6e50513          	addi	a0,a0,-1426 # 80025128 <disk+0x2128>
    800066c2:	ffffa097          	auipc	ra,0xffffa
    800066c6:	5d6080e7          	jalr	1494(ra) # 80000c98 <release>
}
    800066ca:	60e2                	ld	ra,24(sp)
    800066cc:	6442                	ld	s0,16(sp)
    800066ce:	64a2                	ld	s1,8(sp)
    800066d0:	6902                	ld	s2,0(sp)
    800066d2:	6105                	addi	sp,sp,32
    800066d4:	8082                	ret
      panic("virtio_disk_intr status");
    800066d6:	00002517          	auipc	a0,0x2
    800066da:	1ea50513          	addi	a0,a0,490 # 800088c0 <syscalls+0x3c8>
    800066de:	ffffa097          	auipc	ra,0xffffa
    800066e2:	e60080e7          	jalr	-416(ra) # 8000053e <panic>
	...

0000000080007000 <_trampoline>:
    80007000:	14051573          	csrrw	a0,sscratch,a0
    80007004:	02153423          	sd	ra,40(a0)
    80007008:	02253823          	sd	sp,48(a0)
    8000700c:	02353c23          	sd	gp,56(a0)
    80007010:	04453023          	sd	tp,64(a0)
    80007014:	04553423          	sd	t0,72(a0)
    80007018:	04653823          	sd	t1,80(a0)
    8000701c:	04753c23          	sd	t2,88(a0)
    80007020:	f120                	sd	s0,96(a0)
    80007022:	f524                	sd	s1,104(a0)
    80007024:	fd2c                	sd	a1,120(a0)
    80007026:	e150                	sd	a2,128(a0)
    80007028:	e554                	sd	a3,136(a0)
    8000702a:	e958                	sd	a4,144(a0)
    8000702c:	ed5c                	sd	a5,152(a0)
    8000702e:	0b053023          	sd	a6,160(a0)
    80007032:	0b153423          	sd	a7,168(a0)
    80007036:	0b253823          	sd	s2,176(a0)
    8000703a:	0b353c23          	sd	s3,184(a0)
    8000703e:	0d453023          	sd	s4,192(a0)
    80007042:	0d553423          	sd	s5,200(a0)
    80007046:	0d653823          	sd	s6,208(a0)
    8000704a:	0d753c23          	sd	s7,216(a0)
    8000704e:	0f853023          	sd	s8,224(a0)
    80007052:	0f953423          	sd	s9,232(a0)
    80007056:	0fa53823          	sd	s10,240(a0)
    8000705a:	0fb53c23          	sd	s11,248(a0)
    8000705e:	11c53023          	sd	t3,256(a0)
    80007062:	11d53423          	sd	t4,264(a0)
    80007066:	11e53823          	sd	t5,272(a0)
    8000706a:	11f53c23          	sd	t6,280(a0)
    8000706e:	140022f3          	csrr	t0,sscratch
    80007072:	06553823          	sd	t0,112(a0)
    80007076:	00853103          	ld	sp,8(a0)
    8000707a:	02053203          	ld	tp,32(a0)
    8000707e:	01053283          	ld	t0,16(a0)
    80007082:	00053303          	ld	t1,0(a0)
    80007086:	18031073          	csrw	satp,t1
    8000708a:	12000073          	sfence.vma
    8000708e:	8282                	jr	t0

0000000080007090 <userret>:
    80007090:	18059073          	csrw	satp,a1
    80007094:	12000073          	sfence.vma
    80007098:	07053283          	ld	t0,112(a0)
    8000709c:	14029073          	csrw	sscratch,t0
    800070a0:	02853083          	ld	ra,40(a0)
    800070a4:	03053103          	ld	sp,48(a0)
    800070a8:	03853183          	ld	gp,56(a0)
    800070ac:	04053203          	ld	tp,64(a0)
    800070b0:	04853283          	ld	t0,72(a0)
    800070b4:	05053303          	ld	t1,80(a0)
    800070b8:	05853383          	ld	t2,88(a0)
    800070bc:	7120                	ld	s0,96(a0)
    800070be:	7524                	ld	s1,104(a0)
    800070c0:	7d2c                	ld	a1,120(a0)
    800070c2:	6150                	ld	a2,128(a0)
    800070c4:	6554                	ld	a3,136(a0)
    800070c6:	6958                	ld	a4,144(a0)
    800070c8:	6d5c                	ld	a5,152(a0)
    800070ca:	0a053803          	ld	a6,160(a0)
    800070ce:	0a853883          	ld	a7,168(a0)
    800070d2:	0b053903          	ld	s2,176(a0)
    800070d6:	0b853983          	ld	s3,184(a0)
    800070da:	0c053a03          	ld	s4,192(a0)
    800070de:	0c853a83          	ld	s5,200(a0)
    800070e2:	0d053b03          	ld	s6,208(a0)
    800070e6:	0d853b83          	ld	s7,216(a0)
    800070ea:	0e053c03          	ld	s8,224(a0)
    800070ee:	0e853c83          	ld	s9,232(a0)
    800070f2:	0f053d03          	ld	s10,240(a0)
    800070f6:	0f853d83          	ld	s11,248(a0)
    800070fa:	10053e03          	ld	t3,256(a0)
    800070fe:	10853e83          	ld	t4,264(a0)
    80007102:	11053f03          	ld	t5,272(a0)
    80007106:	11853f83          	ld	t6,280(a0)
    8000710a:	14051573          	csrrw	a0,sscratch,a0
    8000710e:	10200073          	sret
	...
