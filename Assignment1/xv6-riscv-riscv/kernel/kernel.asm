
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	88013103          	ld	sp,-1920(sp) # 80008880 <_GLOBAL_OFFSET_TABLE_+0x8>
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
    80000068:	0dc78793          	addi	a5,a5,220 # 80006140 <timervec>
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
    80000130:	912080e7          	jalr	-1774(ra) # 80002a3e <either_copyin>
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
    800001d8:	26e080e7          	jalr	622(ra) # 80002442 <sleep>
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
    80000214:	7d8080e7          	jalr	2008(ra) # 800029e8 <either_copyout>
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
    800002f6:	7a2080e7          	jalr	1954(ra) # 80002a94 <procdump>
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
    8000044a:	1bc080e7          	jalr	444(ra) # 80002602 <wakeup>
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
    80000570:	b5c50513          	addi	a0,a0,-1188 # 800080c8 <digits+0x88>
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
    800008a4:	d62080e7          	jalr	-670(ra) # 80002602 <wakeup>
    
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
    80000930:	b16080e7          	jalr	-1258(ra) # 80002442 <sleep>
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
    80000ed8:	d00080e7          	jalr	-768(ra) # 80002bd4 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000edc:	00005097          	auipc	ra,0x5
    80000ee0:	2a4080e7          	jalr	676(ra) # 80006180 <plicinithart>
  }

  scheduler();        
    80000ee4:	00001097          	auipc	ra,0x1
    80000ee8:	404080e7          	jalr	1028(ra) # 800022e8 <scheduler>
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
    80000f08:	1c450513          	addi	a0,a0,452 # 800080c8 <digits+0x88>
    80000f0c:	fffff097          	auipc	ra,0xfffff
    80000f10:	67c080e7          	jalr	1660(ra) # 80000588 <printf>
    printf("xv6 kernel is booting\n");
    80000f14:	00007517          	auipc	a0,0x7
    80000f18:	18c50513          	addi	a0,a0,396 # 800080a0 <digits+0x60>
    80000f1c:	fffff097          	auipc	ra,0xfffff
    80000f20:	66c080e7          	jalr	1644(ra) # 80000588 <printf>
    printf("\n");
    80000f24:	00007517          	auipc	a0,0x7
    80000f28:	1a450513          	addi	a0,a0,420 # 800080c8 <digits+0x88>
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
    80000f58:	c58080e7          	jalr	-936(ra) # 80002bac <trapinit>
    trapinithart();  // install kernel trap vector
    80000f5c:	00002097          	auipc	ra,0x2
    80000f60:	c78080e7          	jalr	-904(ra) # 80002bd4 <trapinithart>
    plicinit();      // set up interrupt controller
    80000f64:	00005097          	auipc	ra,0x5
    80000f68:	206080e7          	jalr	518(ra) # 8000616a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f6c:	00005097          	auipc	ra,0x5
    80000f70:	214080e7          	jalr	532(ra) # 80006180 <plicinithart>
    binit();         // buffer cache
    80000f74:	00002097          	auipc	ra,0x2
    80000f78:	3f0080e7          	jalr	1008(ra) # 80003364 <binit>
    iinit();         // inode table
    80000f7c:	00003097          	auipc	ra,0x3
    80000f80:	a80080e7          	jalr	-1408(ra) # 800039fc <iinit>
    fileinit();      // file table
    80000f84:	00004097          	auipc	ra,0x4
    80000f88:	a2a080e7          	jalr	-1494(ra) # 800049ae <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f8c:	00005097          	auipc	ra,0x5
    80000f90:	316080e7          	jalr	790(ra) # 800062a2 <virtio_disk_init>
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

    for(p = proc; p < &proc[NPROC]; p++) {
    8000185c:	00010497          	auipc	s1,0x10
    80001860:	e9448493          	addi	s1,s1,-364 # 800116f0 <proc>
        char *pa = kalloc();
        if(pa == 0)
            panic("kalloc");
        uint64 va = KSTACK((int) (p - proc));
    80001864:	8b26                	mv	s6,s1
    80001866:	00006a97          	auipc	s5,0x6
    8000186a:	79aa8a93          	addi	s5,s5,1946 # 80008000 <etext>
    8000186e:	04000937          	lui	s2,0x4000
    80001872:	197d                	addi	s2,s2,-1
    80001874:	0932                	slli	s2,s2,0xc
    for(p = proc; p < &proc[NPROC]; p++) {
    80001876:	00016a17          	auipc	s4,0x16
    8000187a:	07aa0a13          	addi	s4,s4,122 # 800178f0 <tickslock>
        char *pa = kalloc();
    8000187e:	fffff097          	auipc	ra,0xfffff
    80001882:	276080e7          	jalr	630(ra) # 80000af4 <kalloc>
    80001886:	862a                	mv	a2,a0
        if(pa == 0)
    80001888:	c131                	beqz	a0,800018cc <proc_mapstacks+0x86>
        uint64 va = KSTACK((int) (p - proc));
    8000188a:	416485b3          	sub	a1,s1,s6
    8000188e:	858d                	srai	a1,a1,0x3
    80001890:	000ab783          	ld	a5,0(s5)
    80001894:	02f585b3          	mul	a1,a1,a5
    80001898:	2585                	addiw	a1,a1,1
    8000189a:	00d5959b          	slliw	a1,a1,0xd
        kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    8000189e:	4719                	li	a4,6
    800018a0:	6685                	lui	a3,0x1
    800018a2:	40b905b3          	sub	a1,s2,a1
    800018a6:	854e                	mv	a0,s3
    800018a8:	00000097          	auipc	ra,0x0
    800018ac:	8b0080e7          	jalr	-1872(ra) # 80001158 <kvmmap>
    for(p = proc; p < &proc[NPROC]; p++) {
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
procinit(void)
{
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
    for(p = proc; p < &proc[NPROC]; p++) {
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
    for(p = proc; p < &proc[NPROC]; p++) {
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
    for(p = proc; p < &proc[NPROC]; p++) {
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
cpuid()
{
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
struct cpu*
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
struct proc*
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

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
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
    80001a1c:	e187a783          	lw	a5,-488(a5) # 80008830 <first.1732>
    80001a20:	eb89                	bnez	a5,80001a32 <forkret+0x32>
        // be run from main().
        first = 0;
        fsinit(ROOTDEV);
    }

    usertrapret();
    80001a22:	00001097          	auipc	ra,0x1
    80001a26:	1ca080e7          	jalr	458(ra) # 80002bec <usertrapret>
}
    80001a2a:	60a2                	ld	ra,8(sp)
    80001a2c:	6402                	ld	s0,0(sp)
    80001a2e:	0141                	addi	sp,sp,16
    80001a30:	8082                	ret
        first = 0;
    80001a32:	00007797          	auipc	a5,0x7
    80001a36:	de07af23          	sw	zero,-514(a5) # 80008830 <first.1732>
        fsinit(ROOTDEV);
    80001a3a:	4505                	li	a0,1
    80001a3c:	00002097          	auipc	ra,0x2
    80001a40:	f40080e7          	jalr	-192(ra) # 8000397c <fsinit>
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
    80001a68:	dd078793          	addi	a5,a5,-560 # 80008834 <nextpid>
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
{
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
    if(pagetable == 0)
    80001aa4:	c121                	beqz	a0,80001ae4 <proc_pagetable+0x58>
    if(mappages(pagetable, TRAMPOLINE, PGSIZE,
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
    if(mappages(pagetable, TRAPFRAME, PGSIZE,
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
{
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
{
    80001b7a:	1101                	addi	sp,sp,-32
    80001b7c:	ec06                	sd	ra,24(sp)
    80001b7e:	e822                	sd	s0,16(sp)
    80001b80:	e426                	sd	s1,8(sp)
    80001b82:	1000                	addi	s0,sp,32
    80001b84:	84aa                	mv	s1,a0
    if(p->trapframe)
    80001b86:	7d28                	ld	a0,120(a0)
    80001b88:	c509                	beqz	a0,80001b92 <freeproc+0x18>
        kfree((void*)p->trapframe);
    80001b8a:	fffff097          	auipc	ra,0xfffff
    80001b8e:	e6e080e7          	jalr	-402(ra) # 800009f8 <kfree>
    p->trapframe = 0;
    80001b92:	0604bc23          	sd	zero,120(s1)
    if(p->pagetable)
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
{
    80001bd2:	1101                	addi	sp,sp,-32
    80001bd4:	ec06                	sd	ra,24(sp)
    80001bd6:	e822                	sd	s0,16(sp)
    80001bd8:	e426                	sd	s1,8(sp)
    80001bda:	e04a                	sd	s2,0(sp)
    80001bdc:	1000                	addi	s0,sp,32
    for(p = proc; p < &proc[NPROC]; p++) {
    80001bde:	00010497          	auipc	s1,0x10
    80001be2:	b1248493          	addi	s1,s1,-1262 # 800116f0 <proc>
    80001be6:	00016917          	auipc	s2,0x16
    80001bea:	d0a90913          	addi	s2,s2,-758 # 800178f0 <tickslock>
        acquire(&p->lock);
    80001bee:	8526                	mv	a0,s1
    80001bf0:	fffff097          	auipc	ra,0xfffff
    80001bf4:	ff4080e7          	jalr	-12(ra) # 80000be4 <acquire>
        if(p->state == UNUSED) {
    80001bf8:	4c9c                	lw	a5,24(s1)
    80001bfa:	cf81                	beqz	a5,80001c12 <allocproc+0x40>
            release(&p->lock);
    80001bfc:	8526                	mv	a0,s1
    80001bfe:	fffff097          	auipc	ra,0xfffff
    80001c02:	09a080e7          	jalr	154(ra) # 80000c98 <release>
    for(p = proc; p < &proc[NPROC]; p++) {
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
    if((p->trapframe = (struct trapframe *)kalloc()) == 0){
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
    if(p->pagetable == 0){
    80001c3c:	c53d                	beqz	a0,80001caa <allocproc+0xd8>
    memset(&p->context, 0, sizeof(p->context));
    80001c3e:	07000613          	li	a2,112
    80001c42:	4581                	li	a1,0
    80001c44:	08048513          	addi	a0,s1,128
    80001c48:	fffff097          	auipc	ra,0xfffff
    80001c4c:	098080e7          	jalr	152(ra) # 80000ce0 <memset>
    p->context.ra = (uint64)forkret;
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
{
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
    80001ce6:	b5e58593          	addi	a1,a1,-1186 # 80008840 <initcode>
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
    80001d24:	68a080e7          	jalr	1674(ra) # 800043aa <namei>
    80001d28:	16a4b823          	sd	a0,368(s1)
    p->state = RUNNABLE;
    80001d2c:	478d                	li	a5,3
    80001d2e:	cc9c                	sw	a5,24(s1)
    acquire(&tickslock);
    80001d30:	00016517          	auipc	a0,0x16
    80001d34:	bc050513          	addi	a0,a0,-1088 # 800178f0 <tickslock>
    80001d38:	fffff097          	auipc	ra,0xfffff
    80001d3c:	eac080e7          	jalr	-340(ra) # 80000be4 <acquire>
    p->last_runnable_time = ticks;     //added last_runnable time for fcfs
    80001d40:	00007797          	auipc	a5,0x7
    80001d44:	3107a783          	lw	a5,784(a5) # 80009050 <ticks>
    80001d48:	c4bc                	sw	a5,72(s1)
    p->last_time_changed = ticks;      //setting the starting ticks when getting to runnable for section 4
    80001d4a:	ccbc                	sw	a5,88(s1)
    release(&tickslock);
    80001d4c:	00016517          	auipc	a0,0x16
    80001d50:	ba450513          	addi	a0,a0,-1116 # 800178f0 <tickslock>
    80001d54:	fffff097          	auipc	ra,0xfffff
    80001d58:	f44080e7          	jalr	-188(ra) # 80000c98 <release>
    release(&p->lock);
    80001d5c:	8526                	mv	a0,s1
    80001d5e:	fffff097          	auipc	ra,0xfffff
    80001d62:	f3a080e7          	jalr	-198(ra) # 80000c98 <release>
}
    80001d66:	60e2                	ld	ra,24(sp)
    80001d68:	6442                	ld	s0,16(sp)
    80001d6a:	64a2                	ld	s1,8(sp)
    80001d6c:	6105                	addi	sp,sp,32
    80001d6e:	8082                	ret

0000000080001d70 <growproc>:
{
    80001d70:	1101                	addi	sp,sp,-32
    80001d72:	ec06                	sd	ra,24(sp)
    80001d74:	e822                	sd	s0,16(sp)
    80001d76:	e426                	sd	s1,8(sp)
    80001d78:	e04a                	sd	s2,0(sp)
    80001d7a:	1000                	addi	s0,sp,32
    80001d7c:	84aa                	mv	s1,a0
    struct proc *p = myproc();
    80001d7e:	00000097          	auipc	ra,0x0
    80001d82:	c4a080e7          	jalr	-950(ra) # 800019c8 <myproc>
    80001d86:	892a                	mv	s2,a0
    sz = p->sz;
    80001d88:	752c                	ld	a1,104(a0)
    80001d8a:	0005861b          	sext.w	a2,a1
    if(n > 0){
    80001d8e:	00904f63          	bgtz	s1,80001dac <growproc+0x3c>
    } else if(n < 0){
    80001d92:	0204cc63          	bltz	s1,80001dca <growproc+0x5a>
    p->sz = sz;
    80001d96:	1602                	slli	a2,a2,0x20
    80001d98:	9201                	srli	a2,a2,0x20
    80001d9a:	06c93423          	sd	a2,104(s2)
    return 0;
    80001d9e:	4501                	li	a0,0
}
    80001da0:	60e2                	ld	ra,24(sp)
    80001da2:	6442                	ld	s0,16(sp)
    80001da4:	64a2                	ld	s1,8(sp)
    80001da6:	6902                	ld	s2,0(sp)
    80001da8:	6105                	addi	sp,sp,32
    80001daa:	8082                	ret
        if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    80001dac:	9e25                	addw	a2,a2,s1
    80001dae:	1602                	slli	a2,a2,0x20
    80001db0:	9201                	srli	a2,a2,0x20
    80001db2:	1582                	slli	a1,a1,0x20
    80001db4:	9181                	srli	a1,a1,0x20
    80001db6:	7928                	ld	a0,112(a0)
    80001db8:	fffff097          	auipc	ra,0xfffff
    80001dbc:	672080e7          	jalr	1650(ra) # 8000142a <uvmalloc>
    80001dc0:	0005061b          	sext.w	a2,a0
    80001dc4:	fa69                	bnez	a2,80001d96 <growproc+0x26>
            return -1;
    80001dc6:	557d                	li	a0,-1
    80001dc8:	bfe1                	j	80001da0 <growproc+0x30>
        sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001dca:	9e25                	addw	a2,a2,s1
    80001dcc:	1602                	slli	a2,a2,0x20
    80001dce:	9201                	srli	a2,a2,0x20
    80001dd0:	1582                	slli	a1,a1,0x20
    80001dd2:	9181                	srli	a1,a1,0x20
    80001dd4:	7928                	ld	a0,112(a0)
    80001dd6:	fffff097          	auipc	ra,0xfffff
    80001dda:	60c080e7          	jalr	1548(ra) # 800013e2 <uvmdealloc>
    80001dde:	0005061b          	sext.w	a2,a0
    80001de2:	bf55                	j	80001d96 <growproc+0x26>

0000000080001de4 <fork>:
{
    80001de4:	7179                	addi	sp,sp,-48
    80001de6:	f406                	sd	ra,40(sp)
    80001de8:	f022                	sd	s0,32(sp)
    80001dea:	ec26                	sd	s1,24(sp)
    80001dec:	e84a                	sd	s2,16(sp)
    80001dee:	e44e                	sd	s3,8(sp)
    80001df0:	e052                	sd	s4,0(sp)
    80001df2:	1800                	addi	s0,sp,48
    struct proc *p = myproc();
    80001df4:	00000097          	auipc	ra,0x0
    80001df8:	bd4080e7          	jalr	-1068(ra) # 800019c8 <myproc>
    80001dfc:	89aa                	mv	s3,a0
    if((np = allocproc()) == 0){
    80001dfe:	00000097          	auipc	ra,0x0
    80001e02:	dd4080e7          	jalr	-556(ra) # 80001bd2 <allocproc>
    80001e06:	14050363          	beqz	a0,80001f4c <fork+0x168>
    80001e0a:	892a                	mv	s2,a0
    if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001e0c:	0689b603          	ld	a2,104(s3)
    80001e10:	792c                	ld	a1,112(a0)
    80001e12:	0709b503          	ld	a0,112(s3)
    80001e16:	fffff097          	auipc	ra,0xfffff
    80001e1a:	760080e7          	jalr	1888(ra) # 80001576 <uvmcopy>
    80001e1e:	04054663          	bltz	a0,80001e6a <fork+0x86>
    np->sz = p->sz;
    80001e22:	0689b783          	ld	a5,104(s3)
    80001e26:	06f93423          	sd	a5,104(s2)
    *(np->trapframe) = *(p->trapframe);
    80001e2a:	0789b683          	ld	a3,120(s3)
    80001e2e:	87b6                	mv	a5,a3
    80001e30:	07893703          	ld	a4,120(s2)
    80001e34:	12068693          	addi	a3,a3,288
    80001e38:	0007b803          	ld	a6,0(a5)
    80001e3c:	6788                	ld	a0,8(a5)
    80001e3e:	6b8c                	ld	a1,16(a5)
    80001e40:	6f90                	ld	a2,24(a5)
    80001e42:	01073023          	sd	a6,0(a4)
    80001e46:	e708                	sd	a0,8(a4)
    80001e48:	eb0c                	sd	a1,16(a4)
    80001e4a:	ef10                	sd	a2,24(a4)
    80001e4c:	02078793          	addi	a5,a5,32
    80001e50:	02070713          	addi	a4,a4,32
    80001e54:	fed792e3          	bne	a5,a3,80001e38 <fork+0x54>
    np->trapframe->a0 = 0;
    80001e58:	07893783          	ld	a5,120(s2)
    80001e5c:	0607b823          	sd	zero,112(a5)
    80001e60:	0f000493          	li	s1,240
    for(i = 0; i < NOFILE; i++)
    80001e64:	17000a13          	li	s4,368
    80001e68:	a03d                	j	80001e96 <fork+0xb2>
        freeproc(np);
    80001e6a:	854a                	mv	a0,s2
    80001e6c:	00000097          	auipc	ra,0x0
    80001e70:	d0e080e7          	jalr	-754(ra) # 80001b7a <freeproc>
        release(&np->lock);
    80001e74:	854a                	mv	a0,s2
    80001e76:	fffff097          	auipc	ra,0xfffff
    80001e7a:	e22080e7          	jalr	-478(ra) # 80000c98 <release>
        return -1;
    80001e7e:	5a7d                	li	s4,-1
    80001e80:	a86d                	j	80001f3a <fork+0x156>
            np->ofile[i] = filedup(p->ofile[i]);
    80001e82:	00003097          	auipc	ra,0x3
    80001e86:	bbe080e7          	jalr	-1090(ra) # 80004a40 <filedup>
    80001e8a:	009907b3          	add	a5,s2,s1
    80001e8e:	e388                	sd	a0,0(a5)
    for(i = 0; i < NOFILE; i++)
    80001e90:	04a1                	addi	s1,s1,8
    80001e92:	01448763          	beq	s1,s4,80001ea0 <fork+0xbc>
        if(p->ofile[i])
    80001e96:	009987b3          	add	a5,s3,s1
    80001e9a:	6388                	ld	a0,0(a5)
    80001e9c:	f17d                	bnez	a0,80001e82 <fork+0x9e>
    80001e9e:	bfcd                	j	80001e90 <fork+0xac>
    np->cwd = idup(p->cwd);
    80001ea0:	1709b503          	ld	a0,368(s3)
    80001ea4:	00002097          	auipc	ra,0x2
    80001ea8:	d12080e7          	jalr	-750(ra) # 80003bb6 <idup>
    80001eac:	16a93823          	sd	a0,368(s2)
    safestrcpy(np->name, p->name, sizeof(p->name));
    80001eb0:	4641                	li	a2,16
    80001eb2:	17898593          	addi	a1,s3,376
    80001eb6:	17890513          	addi	a0,s2,376
    80001eba:	fffff097          	auipc	ra,0xfffff
    80001ebe:	f78080e7          	jalr	-136(ra) # 80000e32 <safestrcpy>
    pid = np->pid;
    80001ec2:	03092a03          	lw	s4,48(s2)
    release(&np->lock);
    80001ec6:	854a                	mv	a0,s2
    80001ec8:	fffff097          	auipc	ra,0xfffff
    80001ecc:	dd0080e7          	jalr	-560(ra) # 80000c98 <release>
    acquire(&wait_lock);
    80001ed0:	0000f497          	auipc	s1,0xf
    80001ed4:	40848493          	addi	s1,s1,1032 # 800112d8 <wait_lock>
    80001ed8:	8526                	mv	a0,s1
    80001eda:	fffff097          	auipc	ra,0xfffff
    80001ede:	d0a080e7          	jalr	-758(ra) # 80000be4 <acquire>
    np->parent = p;
    80001ee2:	03393c23          	sd	s3,56(s2)
    release(&wait_lock);
    80001ee6:	8526                	mv	a0,s1
    80001ee8:	fffff097          	auipc	ra,0xfffff
    80001eec:	db0080e7          	jalr	-592(ra) # 80000c98 <release>
    acquire(&np->lock);
    80001ef0:	854a                	mv	a0,s2
    80001ef2:	fffff097          	auipc	ra,0xfffff
    80001ef6:	cf2080e7          	jalr	-782(ra) # 80000be4 <acquire>
    np->state = RUNNABLE;
    80001efa:	478d                	li	a5,3
    80001efc:	00f92c23          	sw	a5,24(s2)
    acquire(&tickslock);
    80001f00:	00016517          	auipc	a0,0x16
    80001f04:	9f050513          	addi	a0,a0,-1552 # 800178f0 <tickslock>
    80001f08:	fffff097          	auipc	ra,0xfffff
    80001f0c:	cdc080e7          	jalr	-804(ra) # 80000be4 <acquire>
    np->last_runnable_time = ticks;     //added last_runnable time for fcfs
    80001f10:	00007797          	auipc	a5,0x7
    80001f14:	1407a783          	lw	a5,320(a5) # 80009050 <ticks>
    80001f18:	04f92423          	sw	a5,72(s2)
    np->last_time_changed = ticks;      //setting the starting ticks when getting to runnable for section 4
    80001f1c:	04f92c23          	sw	a5,88(s2)
    release(&tickslock);
    80001f20:	00016517          	auipc	a0,0x16
    80001f24:	9d050513          	addi	a0,a0,-1584 # 800178f0 <tickslock>
    80001f28:	fffff097          	auipc	ra,0xfffff
    80001f2c:	d70080e7          	jalr	-656(ra) # 80000c98 <release>
    release(&np->lock);
    80001f30:	854a                	mv	a0,s2
    80001f32:	fffff097          	auipc	ra,0xfffff
    80001f36:	d66080e7          	jalr	-666(ra) # 80000c98 <release>
}
    80001f3a:	8552                	mv	a0,s4
    80001f3c:	70a2                	ld	ra,40(sp)
    80001f3e:	7402                	ld	s0,32(sp)
    80001f40:	64e2                	ld	s1,24(sp)
    80001f42:	6942                	ld	s2,16(sp)
    80001f44:	69a2                	ld	s3,8(sp)
    80001f46:	6a02                	ld	s4,0(sp)
    80001f48:	6145                	addi	sp,sp,48
    80001f4a:	8082                	ret
        return -1;
    80001f4c:	5a7d                	li	s4,-1
    80001f4e:	b7f5                	j	80001f3a <fork+0x156>

0000000080001f50 <defScheduler>:
void defScheduler(void){
    80001f50:	711d                	addi	sp,sp,-96
    80001f52:	ec86                	sd	ra,88(sp)
    80001f54:	e8a2                	sd	s0,80(sp)
    80001f56:	e4a6                	sd	s1,72(sp)
    80001f58:	e0ca                	sd	s2,64(sp)
    80001f5a:	fc4e                	sd	s3,56(sp)
    80001f5c:	f852                	sd	s4,48(sp)
    80001f5e:	f456                	sd	s5,40(sp)
    80001f60:	f05a                	sd	s6,32(sp)
    80001f62:	ec5e                	sd	s7,24(sp)
    80001f64:	e862                	sd	s8,16(sp)
    80001f66:	e466                	sd	s9,8(sp)
    80001f68:	1080                	addi	s0,sp,96
    80001f6a:	8792                	mv	a5,tp
    int id = r_tp();
    80001f6c:	2781                	sext.w	a5,a5
    c->proc = 0;
    80001f6e:	00779c93          	slli	s9,a5,0x7
    80001f72:	0000f717          	auipc	a4,0xf
    80001f76:	34e70713          	addi	a4,a4,846 # 800112c0 <pid_lock>
    80001f7a:	9766                	add	a4,a4,s9
    80001f7c:	02073823          	sd	zero,48(a4)
                swtch(&c->context, &p->context);
    80001f80:	0000f717          	auipc	a4,0xf
    80001f84:	37870713          	addi	a4,a4,888 # 800112f8 <cpus+0x8>
    80001f88:	9cba                	add	s9,s9,a4
                while(ticks < pauseTicks) {
    80001f8a:	00007917          	auipc	s2,0x7
    80001f8e:	0c690913          	addi	s2,s2,198 # 80009050 <ticks>
    80001f92:	00007997          	auipc	s3,0x7
    80001f96:	0ae98993          	addi	s3,s3,174 # 80009040 <pauseTicks>
                c->proc = p;
    80001f9a:	079e                	slli	a5,a5,0x7
    80001f9c:	0000fc17          	auipc	s8,0xf
    80001fa0:	324c0c13          	addi	s8,s8,804 # 800112c0 <pid_lock>
    80001fa4:	9c3e                	add	s8,s8,a5
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001fa6:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001faa:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001fae:	10079073          	csrw	sstatus,a5
        for(p = proc; p < &proc[NPROC]; p++) {
    80001fb2:	0000f497          	auipc	s1,0xf
    80001fb6:	73e48493          	addi	s1,s1,1854 # 800116f0 <proc>
            if(p->state == RUNNABLE) {
    80001fba:	4b8d                	li	s7,3
                    printf("%d \n", ticks); //todo remove
    80001fbc:	00006a17          	auipc	s4,0x6
    80001fc0:	25ca0a13          	addi	s4,s4,604 # 80008218 <digits+0x1d8>
        for(p = proc; p < &proc[NPROC]; p++) {
    80001fc4:	00016b17          	auipc	s6,0x16
    80001fc8:	92cb0b13          	addi	s6,s6,-1748 # 800178f0 <tickslock>
    80001fcc:	a895                	j	80002040 <defScheduler+0xf0>
                    printf("%d \n", ticks); //todo remove
    80001fce:	8552                	mv	a0,s4
    80001fd0:	ffffe097          	auipc	ra,0xffffe
    80001fd4:	5b8080e7          	jalr	1464(ra) # 80000588 <printf>
                while(ticks < pauseTicks) {
    80001fd8:	00092583          	lw	a1,0(s2)
    80001fdc:	0009a783          	lw	a5,0(s3)
    80001fe0:	fef5e7e3          	bltu	a1,a5,80001fce <defScheduler+0x7e>
                acquire(&tickslock);
    80001fe4:	00016517          	auipc	a0,0x16
    80001fe8:	90c50513          	addi	a0,a0,-1780 # 800178f0 <tickslock>
    80001fec:	fffff097          	auipc	ra,0xfffff
    80001ff0:	bf8080e7          	jalr	-1032(ra) # 80000be4 <acquire>
                p->runnable_time = p->runnable_time + ticks - p->last_time_changed;
    80001ff4:	00092703          	lw	a4,0(s2)
    80001ff8:	48bc                	lw	a5,80(s1)
    80001ffa:	9fb9                	addw	a5,a5,a4
    80001ffc:	4cb4                	lw	a3,88(s1)
    80001ffe:	9f95                	subw	a5,a5,a3
    80002000:	c8bc                	sw	a5,80(s1)
                p->last_time_changed = ticks;      //setting the starting ticks when getting to runnable for section 4
    80002002:	ccb8                	sw	a4,88(s1)
                release(&tickslock);
    80002004:	00016517          	auipc	a0,0x16
    80002008:	8ec50513          	addi	a0,a0,-1812 # 800178f0 <tickslock>
    8000200c:	fffff097          	auipc	ra,0xfffff
    80002010:	c8c080e7          	jalr	-884(ra) # 80000c98 <release>
                p->state = RUNNING;
    80002014:	4791                	li	a5,4
    80002016:	cc9c                	sw	a5,24(s1)
                c->proc = p;
    80002018:	029c3823          	sd	s1,48(s8)
                swtch(&c->context, &p->context);
    8000201c:	080a8593          	addi	a1,s5,128
    80002020:	8566                	mv	a0,s9
    80002022:	00001097          	auipc	ra,0x1
    80002026:	b20080e7          	jalr	-1248(ra) # 80002b42 <swtch>
                c->proc = 0;
    8000202a:	020c3823          	sd	zero,48(s8)
            release(&p->lock);
    8000202e:	8526                	mv	a0,s1
    80002030:	fffff097          	auipc	ra,0xfffff
    80002034:	c68080e7          	jalr	-920(ra) # 80000c98 <release>
        for(p = proc; p < &proc[NPROC]; p++) {
    80002038:	18848493          	addi	s1,s1,392
    8000203c:	f76485e3          	beq	s1,s6,80001fa6 <defScheduler+0x56>
            acquire(&p->lock);
    80002040:	8aa6                	mv	s5,s1
    80002042:	8526                	mv	a0,s1
    80002044:	fffff097          	auipc	ra,0xfffff
    80002048:	ba0080e7          	jalr	-1120(ra) # 80000be4 <acquire>
            if(p->state == RUNNABLE) {
    8000204c:	4c9c                	lw	a5,24(s1)
    8000204e:	ff7790e3          	bne	a5,s7,8000202e <defScheduler+0xde>
                while(ticks < pauseTicks) {
    80002052:	00092583          	lw	a1,0(s2)
    80002056:	0009a783          	lw	a5,0(s3)
    8000205a:	f6f5eae3          	bltu	a1,a5,80001fce <defScheduler+0x7e>
    8000205e:	b759                	j	80001fe4 <defScheduler+0x94>

0000000080002060 <sjfScheduler>:
void sjfScheduler(void){ //todo where do we calculate the mean and where to init with 0
    80002060:	7159                	addi	sp,sp,-112
    80002062:	f486                	sd	ra,104(sp)
    80002064:	f0a2                	sd	s0,96(sp)
    80002066:	eca6                	sd	s1,88(sp)
    80002068:	e8ca                	sd	s2,80(sp)
    8000206a:	e4ce                	sd	s3,72(sp)
    8000206c:	e0d2                	sd	s4,64(sp)
    8000206e:	fc56                	sd	s5,56(sp)
    80002070:	f85a                	sd	s6,48(sp)
    80002072:	f45e                	sd	s7,40(sp)
    80002074:	f062                	sd	s8,32(sp)
    80002076:	ec66                	sd	s9,24(sp)
    80002078:	e86a                	sd	s10,16(sp)
    8000207a:	e46e                	sd	s11,8(sp)
    8000207c:	1880                	addi	s0,sp,112
  asm volatile("mv %0, tp" : "=r" (x) );
    8000207e:	8792                	mv	a5,tp
    int id = r_tp();
    80002080:	2781                	sext.w	a5,a5
    c->proc = 0;
    80002082:	00779d13          	slli	s10,a5,0x7
    80002086:	0000f717          	auipc	a4,0xf
    8000208a:	23a70713          	addi	a4,a4,570 # 800112c0 <pid_lock>
    8000208e:	976a                	add	a4,a4,s10
    80002090:	02073823          	sd	zero,48(a4)
        swtch(&c->context, &min_proc->context);
    80002094:	0000f717          	auipc	a4,0xf
    80002098:	26470713          	addi	a4,a4,612 # 800112f8 <cpus+0x8>
    8000209c:	9d3a                	add	s10,s10,a4
        struct proc* min_proc = proc;
    8000209e:	0000fc97          	auipc	s9,0xf
    800020a2:	652c8c93          	addi	s9,s9,1618 # 800116f0 <proc>
        for(p = proc; p < &proc[NPROC]; p++) {
    800020a6:	00016997          	auipc	s3,0x16
    800020aa:	84a98993          	addi	s3,s3,-1974 # 800178f0 <tickslock>
        while(ticks < pauseTicks);        //busy wait until pause time ended
    800020ae:	00007b17          	auipc	s6,0x7
    800020b2:	fa2b0b13          	addi	s6,s6,-94 # 80009050 <ticks>
    800020b6:	00007d97          	auipc	s11,0x7
    800020ba:	f8ad8d93          	addi	s11,s11,-118 # 80009040 <pauseTicks>
        acquire(&tickslock);
    800020be:	00016c17          	auipc	s8,0x16
    800020c2:	832c0c13          	addi	s8,s8,-1998 # 800178f0 <tickslock>
        p->runnable_time = p->runnable_time + ticks - p->last_time_changed;
    800020c6:	00015a97          	auipc	s5,0x15
    800020ca:	62aa8a93          	addi	s5,s5,1578 # 800176f0 <proc+0x6000>
        c->proc = min_proc;
    800020ce:	079e                	slli	a5,a5,0x7
    800020d0:	0000fb97          	auipc	s7,0xf
    800020d4:	1f0b8b93          	addi	s7,s7,496 # 800112c0 <pid_lock>
    800020d8:	9bbe                	add	s7,s7,a5
    800020da:	a8c1                	j	800021aa <sjfScheduler+0x14a>
            release(&p->lock);
    800020dc:	8526                	mv	a0,s1
    800020de:	fffff097          	auipc	ra,0xfffff
    800020e2:	bba080e7          	jalr	-1094(ra) # 80000c98 <release>
        for(p = proc; p < &proc[NPROC]; p++) {
    800020e6:	18848493          	addi	s1,s1,392
    800020ea:	03348163          	beq	s1,s3,8000210c <sjfScheduler+0xac>
            acquire(&p->lock);
    800020ee:	8526                	mv	a0,s1
    800020f0:	fffff097          	auipc	ra,0xfffff
    800020f4:	af4080e7          	jalr	-1292(ra) # 80000be4 <acquire>
            if(p->state == RUNNABLE && p->mean_ticks < min_proc->mean_ticks)
    800020f8:	4c9c                	lw	a5,24(s1)
    800020fa:	ff2791e3          	bne	a5,s2,800020dc <sjfScheduler+0x7c>
    800020fe:	40b8                	lw	a4,64(s1)
    80002100:	040a2783          	lw	a5,64(s4)
    80002104:	fcf75ce3          	bge	a4,a5,800020dc <sjfScheduler+0x7c>
    80002108:	8a26                	mv	s4,s1
    8000210a:	bfc9                	j	800020dc <sjfScheduler+0x7c>
        acquire(&min_proc->lock);
    8000210c:	84d2                	mv	s1,s4
    8000210e:	8552                	mv	a0,s4
    80002110:	fffff097          	auipc	ra,0xfffff
    80002114:	ad4080e7          	jalr	-1324(ra) # 80000be4 <acquire>
        while(ticks < pauseTicks);        //busy wait until pause time ended
    80002118:	000b2703          	lw	a4,0(s6)
    8000211c:	000da783          	lw	a5,0(s11)
    80002120:	00f76063          	bltu	a4,a5,80002120 <sjfScheduler+0xc0>
        acquire(&tickslock);
    80002124:	8562                	mv	a0,s8
    80002126:	fffff097          	auipc	ra,0xfffff
    8000212a:	abe080e7          	jalr	-1346(ra) # 80000be4 <acquire>
        p->runnable_time = p->runnable_time + ticks - p->last_time_changed;
    8000212e:	000b2703          	lw	a4,0(s6)
    80002132:	250aa783          	lw	a5,592(s5)
    80002136:	9fb9                	addw	a5,a5,a4
    80002138:	258aa683          	lw	a3,600(s5)
    8000213c:	9f95                	subw	a5,a5,a3
    8000213e:	24faa823          	sw	a5,592(s5)
        p->last_time_changed = ticks;      //setting the starting ticks when getting to runnable for section 4
    80002142:	24eaac23          	sw	a4,600(s5)
        release(&tickslock);
    80002146:	8562                	mv	a0,s8
    80002148:	fffff097          	auipc	ra,0xfffff
    8000214c:	b50080e7          	jalr	-1200(ra) # 80000c98 <release>
        min_proc->state = RUNNING;
    80002150:	4791                	li	a5,4
    80002152:	00fa2c23          	sw	a5,24(s4)
        c->proc = min_proc;
    80002156:	034bb823          	sd	s4,48(s7)
        int startingTicks = ticks;        //starting ticks for sjf priority
    8000215a:	000b2903          	lw	s2,0(s6)
        swtch(&c->context, &min_proc->context);
    8000215e:	080a0593          	addi	a1,s4,128
    80002162:	856a                	mv	a0,s10
    80002164:	00001097          	auipc	ra,0x1
    80002168:	9de080e7          	jalr	-1570(ra) # 80002b42 <swtch>
        p->last_ticks = ticks - startingTicks;
    8000216c:	000b2703          	lw	a4,0(s6)
    80002170:	4127073b          	subw	a4,a4,s2
    80002174:	24eaa223          	sw	a4,580(s5)
        p->mean_ticks = ((10 - rate) * p->mean_ticks + p->last_ticks * (rate)) / 10;
    80002178:	00006617          	auipc	a2,0x6
    8000217c:	6c062603          	lw	a2,1728(a2) # 80008838 <rate>
    80002180:	46a9                	li	a3,10
    80002182:	40c687bb          	subw	a5,a3,a2
    80002186:	240aa583          	lw	a1,576(s5)
    8000218a:	02b787bb          	mulw	a5,a5,a1
    8000218e:	02c7073b          	mulw	a4,a4,a2
    80002192:	9fb9                	addw	a5,a5,a4
    80002194:	02d7c7bb          	divw	a5,a5,a3
    80002198:	24faa023          	sw	a5,576(s5)
        c->proc = 0;
    8000219c:	020bb823          	sd	zero,48(s7)
        release(&min_proc->lock);
    800021a0:	8526                	mv	a0,s1
    800021a2:	fffff097          	auipc	ra,0xfffff
    800021a6:	af6080e7          	jalr	-1290(ra) # 80000c98 <release>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800021aa:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800021ae:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800021b2:	10079073          	csrw	sstatus,a5
        struct proc* min_proc = proc;
    800021b6:	8a66                	mv	s4,s9
        for(p = proc; p < &proc[NPROC]; p++) {
    800021b8:	84e6                	mv	s1,s9
            if(p->state == RUNNABLE && p->mean_ticks < min_proc->mean_ticks)
    800021ba:	490d                	li	s2,3
    800021bc:	bf0d                	j	800020ee <sjfScheduler+0x8e>

00000000800021be <fcfs>:
void fcfs(void){
    800021be:	7159                	addi	sp,sp,-112
    800021c0:	f486                	sd	ra,104(sp)
    800021c2:	f0a2                	sd	s0,96(sp)
    800021c4:	eca6                	sd	s1,88(sp)
    800021c6:	e8ca                	sd	s2,80(sp)
    800021c8:	e4ce                	sd	s3,72(sp)
    800021ca:	e0d2                	sd	s4,64(sp)
    800021cc:	fc56                	sd	s5,56(sp)
    800021ce:	f85a                	sd	s6,48(sp)
    800021d0:	f45e                	sd	s7,40(sp)
    800021d2:	f062                	sd	s8,32(sp)
    800021d4:	ec66                	sd	s9,24(sp)
    800021d6:	e86a                	sd	s10,16(sp)
    800021d8:	e46e                	sd	s11,8(sp)
    800021da:	1880                	addi	s0,sp,112
  asm volatile("mv %0, tp" : "=r" (x) );
    800021dc:	8792                	mv	a5,tp
    int id = r_tp();
    800021de:	2781                	sext.w	a5,a5
    c->proc = 0;
    800021e0:	00779d13          	slli	s10,a5,0x7
    800021e4:	0000f717          	auipc	a4,0xf
    800021e8:	0dc70713          	addi	a4,a4,220 # 800112c0 <pid_lock>
    800021ec:	976a                	add	a4,a4,s10
    800021ee:	02073823          	sd	zero,48(a4)
        swtch(&c->context, &max_lrt_proc->context);
    800021f2:	0000f717          	auipc	a4,0xf
    800021f6:	10670713          	addi	a4,a4,262 # 800112f8 <cpus+0x8>
    800021fa:	9d3a                	add	s10,s10,a4
        struct proc* max_lrt_proc = proc; // lrt = last runnable time
    800021fc:	0000fc97          	auipc	s9,0xf
    80002200:	4f4c8c93          	addi	s9,s9,1268 # 800116f0 <proc>
        for(p = proc; p < &proc[NPROC]; p++) {
    80002204:	00015997          	auipc	s3,0x15
    80002208:	6ec98993          	addi	s3,s3,1772 # 800178f0 <tickslock>
        while(ticks < pauseTicks);         //busy wait until pause time ended
    8000220c:	00007c17          	auipc	s8,0x7
    80002210:	e44c0c13          	addi	s8,s8,-444 # 80009050 <ticks>
    80002214:	00007d97          	auipc	s11,0x7
    80002218:	e2cd8d93          	addi	s11,s11,-468 # 80009040 <pauseTicks>
        acquire(&tickslock);
    8000221c:	00015b97          	auipc	s7,0x15
    80002220:	6d4b8b93          	addi	s7,s7,1748 # 800178f0 <tickslock>
        p->runnable_time = p->runnable_time + ticks - p->last_time_changed;
    80002224:	00015a97          	auipc	s5,0x15
    80002228:	4cca8a93          	addi	s5,s5,1228 # 800176f0 <proc+0x6000>
        c->proc = max_lrt_proc;
    8000222c:	079e                	slli	a5,a5,0x7
    8000222e:	0000fb17          	auipc	s6,0xf
    80002232:	092b0b13          	addi	s6,s6,146 # 800112c0 <pid_lock>
    80002236:	9b3e                	add	s6,s6,a5
    80002238:	a871                	j	800022d4 <fcfs+0x116>
            release(&p->lock);
    8000223a:	8526                	mv	a0,s1
    8000223c:	fffff097          	auipc	ra,0xfffff
    80002240:	a5c080e7          	jalr	-1444(ra) # 80000c98 <release>
        for(p = proc; p < &proc[NPROC]; p++) {
    80002244:	18848493          	addi	s1,s1,392
    80002248:	03348163          	beq	s1,s3,8000226a <fcfs+0xac>
            acquire(&p->lock);
    8000224c:	8526                	mv	a0,s1
    8000224e:	fffff097          	auipc	ra,0xfffff
    80002252:	996080e7          	jalr	-1642(ra) # 80000be4 <acquire>
            if(p->state == RUNNABLE && p->mean_ticks > max_lrt_proc->mean_ticks)
    80002256:	4c9c                	lw	a5,24(s1)
    80002258:	ff2791e3          	bne	a5,s2,8000223a <fcfs+0x7c>
    8000225c:	40b8                	lw	a4,64(s1)
    8000225e:	040a2783          	lw	a5,64(s4)
    80002262:	fce7dce3          	bge	a5,a4,8000223a <fcfs+0x7c>
    80002266:	8a26                	mv	s4,s1
    80002268:	bfc9                	j	8000223a <fcfs+0x7c>
        acquire(&max_lrt_proc->lock);
    8000226a:	84d2                	mv	s1,s4
    8000226c:	8552                	mv	a0,s4
    8000226e:	fffff097          	auipc	ra,0xfffff
    80002272:	976080e7          	jalr	-1674(ra) # 80000be4 <acquire>
        while(ticks < pauseTicks);         //busy wait until pause time ended
    80002276:	000c2703          	lw	a4,0(s8)
    8000227a:	000da783          	lw	a5,0(s11)
    8000227e:	00f76063          	bltu	a4,a5,8000227e <fcfs+0xc0>
        acquire(&tickslock);
    80002282:	855e                	mv	a0,s7
    80002284:	fffff097          	auipc	ra,0xfffff
    80002288:	960080e7          	jalr	-1696(ra) # 80000be4 <acquire>
        p->runnable_time = p->runnable_time + ticks - p->last_time_changed;
    8000228c:	000c2703          	lw	a4,0(s8)
    80002290:	250aa783          	lw	a5,592(s5)
    80002294:	9fb9                	addw	a5,a5,a4
    80002296:	258aa683          	lw	a3,600(s5)
    8000229a:	9f95                	subw	a5,a5,a3
    8000229c:	24faa823          	sw	a5,592(s5)
        p->last_time_changed = ticks;      //setting the starting ticks when getting to runnable for section 4
    800022a0:	24eaac23          	sw	a4,600(s5)
        release(&tickslock);
    800022a4:	855e                	mv	a0,s7
    800022a6:	fffff097          	auipc	ra,0xfffff
    800022aa:	9f2080e7          	jalr	-1550(ra) # 80000c98 <release>
        max_lrt_proc->state = RUNNING;
    800022ae:	4791                	li	a5,4
    800022b0:	00fa2c23          	sw	a5,24(s4)
        c->proc = max_lrt_proc;
    800022b4:	034b3823          	sd	s4,48(s6)
        swtch(&c->context, &max_lrt_proc->context);
    800022b8:	080a0593          	addi	a1,s4,128
    800022bc:	856a                	mv	a0,s10
    800022be:	00001097          	auipc	ra,0x1
    800022c2:	884080e7          	jalr	-1916(ra) # 80002b42 <swtch>
        c->proc = 0;
    800022c6:	020b3823          	sd	zero,48(s6)
        release(&max_lrt_proc->lock);
    800022ca:	8526                	mv	a0,s1
    800022cc:	fffff097          	auipc	ra,0xfffff
    800022d0:	9cc080e7          	jalr	-1588(ra) # 80000c98 <release>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800022d4:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800022d8:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800022dc:	10079073          	csrw	sstatus,a5
        struct proc* max_lrt_proc = proc; // lrt = last runnable time
    800022e0:	8a66                	mv	s4,s9
        for(p = proc; p < &proc[NPROC]; p++) {
    800022e2:	84e6                	mv	s1,s9
            if(p->state == RUNNABLE && p->mean_ticks > max_lrt_proc->mean_ticks)
    800022e4:	490d                	li	s2,3
    800022e6:	b79d                	j	8000224c <fcfs+0x8e>

00000000800022e8 <scheduler>:
{
    800022e8:	1141                	addi	sp,sp,-16
    800022ea:	e406                	sd	ra,8(sp)
    800022ec:	e022                	sd	s0,0(sp)
    800022ee:	0800                	addi	s0,sp,16
    defScheduler();
    800022f0:	00000097          	auipc	ra,0x0
    800022f4:	c60080e7          	jalr	-928(ra) # 80001f50 <defScheduler>

00000000800022f8 <sched>:
{
    800022f8:	7179                	addi	sp,sp,-48
    800022fa:	f406                	sd	ra,40(sp)
    800022fc:	f022                	sd	s0,32(sp)
    800022fe:	ec26                	sd	s1,24(sp)
    80002300:	e84a                	sd	s2,16(sp)
    80002302:	e44e                	sd	s3,8(sp)
    80002304:	1800                	addi	s0,sp,48
    struct proc *p = myproc();
    80002306:	fffff097          	auipc	ra,0xfffff
    8000230a:	6c2080e7          	jalr	1730(ra) # 800019c8 <myproc>
    8000230e:	84aa                	mv	s1,a0
    if(!holding(&p->lock))
    80002310:	fffff097          	auipc	ra,0xfffff
    80002314:	85a080e7          	jalr	-1958(ra) # 80000b6a <holding>
    80002318:	c93d                	beqz	a0,8000238e <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    8000231a:	8792                	mv	a5,tp
    if(mycpu()->noff != 1)
    8000231c:	2781                	sext.w	a5,a5
    8000231e:	079e                	slli	a5,a5,0x7
    80002320:	0000f717          	auipc	a4,0xf
    80002324:	fa070713          	addi	a4,a4,-96 # 800112c0 <pid_lock>
    80002328:	97ba                	add	a5,a5,a4
    8000232a:	0a87a703          	lw	a4,168(a5)
    8000232e:	4785                	li	a5,1
    80002330:	06f71763          	bne	a4,a5,8000239e <sched+0xa6>
    if(p->state == RUNNING)
    80002334:	4c98                	lw	a4,24(s1)
    80002336:	4791                	li	a5,4
    80002338:	06f70b63          	beq	a4,a5,800023ae <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000233c:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002340:	8b89                	andi	a5,a5,2
    if(intr_get())
    80002342:	efb5                	bnez	a5,800023be <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002344:	8792                	mv	a5,tp
    intena = mycpu()->intena;
    80002346:	0000f917          	auipc	s2,0xf
    8000234a:	f7a90913          	addi	s2,s2,-134 # 800112c0 <pid_lock>
    8000234e:	2781                	sext.w	a5,a5
    80002350:	079e                	slli	a5,a5,0x7
    80002352:	97ca                	add	a5,a5,s2
    80002354:	0ac7a983          	lw	s3,172(a5)
    80002358:	8792                	mv	a5,tp
    swtch(&p->context, &mycpu()->context);
    8000235a:	2781                	sext.w	a5,a5
    8000235c:	079e                	slli	a5,a5,0x7
    8000235e:	0000f597          	auipc	a1,0xf
    80002362:	f9a58593          	addi	a1,a1,-102 # 800112f8 <cpus+0x8>
    80002366:	95be                	add	a1,a1,a5
    80002368:	08048513          	addi	a0,s1,128
    8000236c:	00000097          	auipc	ra,0x0
    80002370:	7d6080e7          	jalr	2006(ra) # 80002b42 <swtch>
    80002374:	8792                	mv	a5,tp
    mycpu()->intena = intena;
    80002376:	2781                	sext.w	a5,a5
    80002378:	079e                	slli	a5,a5,0x7
    8000237a:	97ca                	add	a5,a5,s2
    8000237c:	0b37a623          	sw	s3,172(a5)
}
    80002380:	70a2                	ld	ra,40(sp)
    80002382:	7402                	ld	s0,32(sp)
    80002384:	64e2                	ld	s1,24(sp)
    80002386:	6942                	ld	s2,16(sp)
    80002388:	69a2                	ld	s3,8(sp)
    8000238a:	6145                	addi	sp,sp,48
    8000238c:	8082                	ret
        panic("sched p->lock");
    8000238e:	00006517          	auipc	a0,0x6
    80002392:	e9250513          	addi	a0,a0,-366 # 80008220 <digits+0x1e0>
    80002396:	ffffe097          	auipc	ra,0xffffe
    8000239a:	1a8080e7          	jalr	424(ra) # 8000053e <panic>
        panic("sched locks");
    8000239e:	00006517          	auipc	a0,0x6
    800023a2:	e9250513          	addi	a0,a0,-366 # 80008230 <digits+0x1f0>
    800023a6:	ffffe097          	auipc	ra,0xffffe
    800023aa:	198080e7          	jalr	408(ra) # 8000053e <panic>
        panic("sched running");
    800023ae:	00006517          	auipc	a0,0x6
    800023b2:	e9250513          	addi	a0,a0,-366 # 80008240 <digits+0x200>
    800023b6:	ffffe097          	auipc	ra,0xffffe
    800023ba:	188080e7          	jalr	392(ra) # 8000053e <panic>
        panic("sched interruptible");
    800023be:	00006517          	auipc	a0,0x6
    800023c2:	e9250513          	addi	a0,a0,-366 # 80008250 <digits+0x210>
    800023c6:	ffffe097          	auipc	ra,0xffffe
    800023ca:	178080e7          	jalr	376(ra) # 8000053e <panic>

00000000800023ce <yield>:
{
    800023ce:	1101                	addi	sp,sp,-32
    800023d0:	ec06                	sd	ra,24(sp)
    800023d2:	e822                	sd	s0,16(sp)
    800023d4:	e426                	sd	s1,8(sp)
    800023d6:	1000                	addi	s0,sp,32
    struct proc *p = myproc();
    800023d8:	fffff097          	auipc	ra,0xfffff
    800023dc:	5f0080e7          	jalr	1520(ra) # 800019c8 <myproc>
    800023e0:	84aa                	mv	s1,a0
    acquire(&p->lock);
    800023e2:	fffff097          	auipc	ra,0xfffff
    800023e6:	802080e7          	jalr	-2046(ra) # 80000be4 <acquire>
    p->state = RUNNABLE;
    800023ea:	478d                	li	a5,3
    800023ec:	cc9c                	sw	a5,24(s1)
    acquire(&tickslock);
    800023ee:	00015517          	auipc	a0,0x15
    800023f2:	50250513          	addi	a0,a0,1282 # 800178f0 <tickslock>
    800023f6:	ffffe097          	auipc	ra,0xffffe
    800023fa:	7ee080e7          	jalr	2030(ra) # 80000be4 <acquire>
    p->running_time = p->running_time + (ticks - p->last_time_changed);
    800023fe:	00007797          	auipc	a5,0x7
    80002402:	c527a783          	lw	a5,-942(a5) # 80009050 <ticks>
    80002406:	48f8                	lw	a4,84(s1)
    80002408:	9f3d                	addw	a4,a4,a5
    8000240a:	4cb4                	lw	a3,88(s1)
    8000240c:	9f15                	subw	a4,a4,a3
    8000240e:	c8f8                	sw	a4,84(s1)
    p->last_runnable_time = ticks;     //added last_runnable time for fcfs
    80002410:	2781                	sext.w	a5,a5
    80002412:	c4bc                	sw	a5,72(s1)
    p->last_time_changed = ticks;      //setting the starting ticks when getting to runnable for section 4
    80002414:	ccbc                	sw	a5,88(s1)
    release(&tickslock);
    80002416:	00015517          	auipc	a0,0x15
    8000241a:	4da50513          	addi	a0,a0,1242 # 800178f0 <tickslock>
    8000241e:	fffff097          	auipc	ra,0xfffff
    80002422:	87a080e7          	jalr	-1926(ra) # 80000c98 <release>
    sched();
    80002426:	00000097          	auipc	ra,0x0
    8000242a:	ed2080e7          	jalr	-302(ra) # 800022f8 <sched>
    release(&p->lock);
    8000242e:	8526                	mv	a0,s1
    80002430:	fffff097          	auipc	ra,0xfffff
    80002434:	868080e7          	jalr	-1944(ra) # 80000c98 <release>
}
    80002438:	60e2                	ld	ra,24(sp)
    8000243a:	6442                	ld	s0,16(sp)
    8000243c:	64a2                	ld	s1,8(sp)
    8000243e:	6105                	addi	sp,sp,32
    80002440:	8082                	ret

0000000080002442 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    80002442:	7179                	addi	sp,sp,-48
    80002444:	f406                	sd	ra,40(sp)
    80002446:	f022                	sd	s0,32(sp)
    80002448:	ec26                	sd	s1,24(sp)
    8000244a:	e84a                	sd	s2,16(sp)
    8000244c:	e44e                	sd	s3,8(sp)
    8000244e:	1800                	addi	s0,sp,48
    80002450:	89aa                	mv	s3,a0
    80002452:	892e                	mv	s2,a1
    struct proc *p = myproc();
    80002454:	fffff097          	auipc	ra,0xfffff
    80002458:	574080e7          	jalr	1396(ra) # 800019c8 <myproc>
    8000245c:	84aa                	mv	s1,a0
    // Once we hold p->lock, we can be
    // guaranteed that we won't miss any wakeup
    // (wakeup locks p->lock),
    // so it's okay to release lk.

    acquire(&p->lock);  //DOC: sleeplock1
    8000245e:	ffffe097          	auipc	ra,0xffffe
    80002462:	786080e7          	jalr	1926(ra) # 80000be4 <acquire>
    release(lk);
    80002466:	854a                	mv	a0,s2
    80002468:	fffff097          	auipc	ra,0xfffff
    8000246c:	830080e7          	jalr	-2000(ra) # 80000c98 <release>

    acquire(&tickslock);
    80002470:	00015517          	auipc	a0,0x15
    80002474:	48050513          	addi	a0,a0,1152 # 800178f0 <tickslock>
    80002478:	ffffe097          	auipc	ra,0xffffe
    8000247c:	76c080e7          	jalr	1900(ra) # 80000be4 <acquire>
    p->running_time = p->running_time + ticks - p->last_time_changed;
    80002480:	00007717          	auipc	a4,0x7
    80002484:	bd072703          	lw	a4,-1072(a4) # 80009050 <ticks>
    80002488:	48fc                	lw	a5,84(s1)
    8000248a:	9fb9                	addw	a5,a5,a4
    8000248c:	4cb4                	lw	a3,88(s1)
    8000248e:	9f95                	subw	a5,a5,a3
    80002490:	c8fc                	sw	a5,84(s1)
    p->last_time_changed = ticks;      //setting the starting ticks when getting to runnable for section 4
    80002492:	ccb8                	sw	a4,88(s1)
    release(&tickslock);
    80002494:	00015517          	auipc	a0,0x15
    80002498:	45c50513          	addi	a0,a0,1116 # 800178f0 <tickslock>
    8000249c:	ffffe097          	auipc	ra,0xffffe
    800024a0:	7fc080e7          	jalr	2044(ra) # 80000c98 <release>

    // Go to sleep.
    p->chan = chan;
    800024a4:	0334b023          	sd	s3,32(s1)
    p->state = SLEEPING;
    800024a8:	4789                	li	a5,2
    800024aa:	cc9c                	sw	a5,24(s1)

    sched();
    800024ac:	00000097          	auipc	ra,0x0
    800024b0:	e4c080e7          	jalr	-436(ra) # 800022f8 <sched>

    // Tidy up.
    p->chan = 0;
    800024b4:	0204b023          	sd	zero,32(s1)

    // Reacquire original lock.
    release(&p->lock);
    800024b8:	8526                	mv	a0,s1
    800024ba:	ffffe097          	auipc	ra,0xffffe
    800024be:	7de080e7          	jalr	2014(ra) # 80000c98 <release>
    acquire(lk);
    800024c2:	854a                	mv	a0,s2
    800024c4:	ffffe097          	auipc	ra,0xffffe
    800024c8:	720080e7          	jalr	1824(ra) # 80000be4 <acquire>
}
    800024cc:	70a2                	ld	ra,40(sp)
    800024ce:	7402                	ld	s0,32(sp)
    800024d0:	64e2                	ld	s1,24(sp)
    800024d2:	6942                	ld	s2,16(sp)
    800024d4:	69a2                	ld	s3,8(sp)
    800024d6:	6145                	addi	sp,sp,48
    800024d8:	8082                	ret

00000000800024da <wait>:
{
    800024da:	715d                	addi	sp,sp,-80
    800024dc:	e486                	sd	ra,72(sp)
    800024de:	e0a2                	sd	s0,64(sp)
    800024e0:	fc26                	sd	s1,56(sp)
    800024e2:	f84a                	sd	s2,48(sp)
    800024e4:	f44e                	sd	s3,40(sp)
    800024e6:	f052                	sd	s4,32(sp)
    800024e8:	ec56                	sd	s5,24(sp)
    800024ea:	e85a                	sd	s6,16(sp)
    800024ec:	e45e                	sd	s7,8(sp)
    800024ee:	e062                	sd	s8,0(sp)
    800024f0:	0880                	addi	s0,sp,80
    800024f2:	8b2a                	mv	s6,a0
    struct proc *p = myproc();
    800024f4:	fffff097          	auipc	ra,0xfffff
    800024f8:	4d4080e7          	jalr	1236(ra) # 800019c8 <myproc>
    800024fc:	892a                	mv	s2,a0
    acquire(&wait_lock);
    800024fe:	0000f517          	auipc	a0,0xf
    80002502:	dda50513          	addi	a0,a0,-550 # 800112d8 <wait_lock>
    80002506:	ffffe097          	auipc	ra,0xffffe
    8000250a:	6de080e7          	jalr	1758(ra) # 80000be4 <acquire>
        havekids = 0;
    8000250e:	4b81                	li	s7,0
                if(np->state == ZOMBIE){
    80002510:	4a15                	li	s4,5
        for(np = proc; np < &proc[NPROC]; np++){
    80002512:	00015997          	auipc	s3,0x15
    80002516:	3de98993          	addi	s3,s3,990 # 800178f0 <tickslock>
                havekids = 1;
    8000251a:	4a85                	li	s5,1
        sleep(p, &wait_lock);  //DOC: wait-sleep
    8000251c:	0000fc17          	auipc	s8,0xf
    80002520:	dbcc0c13          	addi	s8,s8,-580 # 800112d8 <wait_lock>
        havekids = 0;
    80002524:	875e                	mv	a4,s7
        for(np = proc; np < &proc[NPROC]; np++){
    80002526:	0000f497          	auipc	s1,0xf
    8000252a:	1ca48493          	addi	s1,s1,458 # 800116f0 <proc>
    8000252e:	a0bd                	j	8000259c <wait+0xc2>
                    pid = np->pid;
    80002530:	0304a983          	lw	s3,48(s1)
                    if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    80002534:	000b0e63          	beqz	s6,80002550 <wait+0x76>
    80002538:	4691                	li	a3,4
    8000253a:	02c48613          	addi	a2,s1,44
    8000253e:	85da                	mv	a1,s6
    80002540:	07093503          	ld	a0,112(s2)
    80002544:	fffff097          	auipc	ra,0xfffff
    80002548:	136080e7          	jalr	310(ra) # 8000167a <copyout>
    8000254c:	02054563          	bltz	a0,80002576 <wait+0x9c>
                    freeproc(np);
    80002550:	8526                	mv	a0,s1
    80002552:	fffff097          	auipc	ra,0xfffff
    80002556:	628080e7          	jalr	1576(ra) # 80001b7a <freeproc>
                    release(&np->lock);
    8000255a:	8526                	mv	a0,s1
    8000255c:	ffffe097          	auipc	ra,0xffffe
    80002560:	73c080e7          	jalr	1852(ra) # 80000c98 <release>
                    release(&wait_lock);
    80002564:	0000f517          	auipc	a0,0xf
    80002568:	d7450513          	addi	a0,a0,-652 # 800112d8 <wait_lock>
    8000256c:	ffffe097          	auipc	ra,0xffffe
    80002570:	72c080e7          	jalr	1836(ra) # 80000c98 <release>
                    return pid;
    80002574:	a09d                	j	800025da <wait+0x100>
                        release(&np->lock);
    80002576:	8526                	mv	a0,s1
    80002578:	ffffe097          	auipc	ra,0xffffe
    8000257c:	720080e7          	jalr	1824(ra) # 80000c98 <release>
                        release(&wait_lock);
    80002580:	0000f517          	auipc	a0,0xf
    80002584:	d5850513          	addi	a0,a0,-680 # 800112d8 <wait_lock>
    80002588:	ffffe097          	auipc	ra,0xffffe
    8000258c:	710080e7          	jalr	1808(ra) # 80000c98 <release>
                        return -1;
    80002590:	59fd                	li	s3,-1
    80002592:	a0a1                	j	800025da <wait+0x100>
        for(np = proc; np < &proc[NPROC]; np++){
    80002594:	18848493          	addi	s1,s1,392
    80002598:	03348463          	beq	s1,s3,800025c0 <wait+0xe6>
            if(np->parent == p){
    8000259c:	7c9c                	ld	a5,56(s1)
    8000259e:	ff279be3          	bne	a5,s2,80002594 <wait+0xba>
                acquire(&np->lock);
    800025a2:	8526                	mv	a0,s1
    800025a4:	ffffe097          	auipc	ra,0xffffe
    800025a8:	640080e7          	jalr	1600(ra) # 80000be4 <acquire>
                if(np->state == ZOMBIE){
    800025ac:	4c9c                	lw	a5,24(s1)
    800025ae:	f94781e3          	beq	a5,s4,80002530 <wait+0x56>
                release(&np->lock);
    800025b2:	8526                	mv	a0,s1
    800025b4:	ffffe097          	auipc	ra,0xffffe
    800025b8:	6e4080e7          	jalr	1764(ra) # 80000c98 <release>
                havekids = 1;
    800025bc:	8756                	mv	a4,s5
    800025be:	bfd9                	j	80002594 <wait+0xba>
        if(!havekids || p->killed){
    800025c0:	c701                	beqz	a4,800025c8 <wait+0xee>
    800025c2:	02892783          	lw	a5,40(s2)
    800025c6:	c79d                	beqz	a5,800025f4 <wait+0x11a>
            release(&wait_lock);
    800025c8:	0000f517          	auipc	a0,0xf
    800025cc:	d1050513          	addi	a0,a0,-752 # 800112d8 <wait_lock>
    800025d0:	ffffe097          	auipc	ra,0xffffe
    800025d4:	6c8080e7          	jalr	1736(ra) # 80000c98 <release>
            return -1;
    800025d8:	59fd                	li	s3,-1
}
    800025da:	854e                	mv	a0,s3
    800025dc:	60a6                	ld	ra,72(sp)
    800025de:	6406                	ld	s0,64(sp)
    800025e0:	74e2                	ld	s1,56(sp)
    800025e2:	7942                	ld	s2,48(sp)
    800025e4:	79a2                	ld	s3,40(sp)
    800025e6:	7a02                	ld	s4,32(sp)
    800025e8:	6ae2                	ld	s5,24(sp)
    800025ea:	6b42                	ld	s6,16(sp)
    800025ec:	6ba2                	ld	s7,8(sp)
    800025ee:	6c02                	ld	s8,0(sp)
    800025f0:	6161                	addi	sp,sp,80
    800025f2:	8082                	ret
        sleep(p, &wait_lock);  //DOC: wait-sleep
    800025f4:	85e2                	mv	a1,s8
    800025f6:	854a                	mv	a0,s2
    800025f8:	00000097          	auipc	ra,0x0
    800025fc:	e4a080e7          	jalr	-438(ra) # 80002442 <sleep>
        havekids = 0;
    80002600:	b715                	j	80002524 <wait+0x4a>

0000000080002602 <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void
wakeup(void *chan)
{
    80002602:	715d                	addi	sp,sp,-80
    80002604:	e486                	sd	ra,72(sp)
    80002606:	e0a2                	sd	s0,64(sp)
    80002608:	fc26                	sd	s1,56(sp)
    8000260a:	f84a                	sd	s2,48(sp)
    8000260c:	f44e                	sd	s3,40(sp)
    8000260e:	f052                	sd	s4,32(sp)
    80002610:	ec56                	sd	s5,24(sp)
    80002612:	e85a                	sd	s6,16(sp)
    80002614:	e45e                	sd	s7,8(sp)
    80002616:	0880                	addi	s0,sp,80
    80002618:	8a2a                	mv	s4,a0
    struct proc *p;

    for(p = proc; p < &proc[NPROC]; p++) {
    8000261a:	0000f497          	auipc	s1,0xf
    8000261e:	0d648493          	addi	s1,s1,214 # 800116f0 <proc>
        if(p != myproc()){
            acquire(&p->lock);
            if(p->state == SLEEPING && p->chan == chan) {
    80002622:	4989                	li	s3,2
                p->state = RUNNABLE;
    80002624:	4b8d                	li	s7,3

                acquire(&tickslock);
    80002626:	00015a97          	auipc	s5,0x15
    8000262a:	2caa8a93          	addi	s5,s5,714 # 800178f0 <tickslock>
                p->sleeping_time = p->sleeping_time + ticks - p->last_time_changed;
    8000262e:	00007b17          	auipc	s6,0x7
    80002632:	a22b0b13          	addi	s6,s6,-1502 # 80009050 <ticks>
    for(p = proc; p < &proc[NPROC]; p++) {
    80002636:	00015917          	auipc	s2,0x15
    8000263a:	2ba90913          	addi	s2,s2,698 # 800178f0 <tickslock>
    8000263e:	a811                	j	80002652 <wakeup+0x50>
                p->last_runnable_time = ticks;     //added last_runnable time for fcfs
                p->last_time_changed = ticks;      //setting the starting ticks when getting to runnable for section 4
                release(&tickslock);

            }
            release(&p->lock);
    80002640:	8526                	mv	a0,s1
    80002642:	ffffe097          	auipc	ra,0xffffe
    80002646:	656080e7          	jalr	1622(ra) # 80000c98 <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    8000264a:	18848493          	addi	s1,s1,392
    8000264e:	05248a63          	beq	s1,s2,800026a2 <wakeup+0xa0>
        if(p != myproc()){
    80002652:	fffff097          	auipc	ra,0xfffff
    80002656:	376080e7          	jalr	886(ra) # 800019c8 <myproc>
    8000265a:	fea488e3          	beq	s1,a0,8000264a <wakeup+0x48>
            acquire(&p->lock);
    8000265e:	8526                	mv	a0,s1
    80002660:	ffffe097          	auipc	ra,0xffffe
    80002664:	584080e7          	jalr	1412(ra) # 80000be4 <acquire>
            if(p->state == SLEEPING && p->chan == chan) {
    80002668:	4c9c                	lw	a5,24(s1)
    8000266a:	fd379be3          	bne	a5,s3,80002640 <wakeup+0x3e>
    8000266e:	709c                	ld	a5,32(s1)
    80002670:	fd4798e3          	bne	a5,s4,80002640 <wakeup+0x3e>
                p->state = RUNNABLE;
    80002674:	0174ac23          	sw	s7,24(s1)
                acquire(&tickslock);
    80002678:	8556                	mv	a0,s5
    8000267a:	ffffe097          	auipc	ra,0xffffe
    8000267e:	56a080e7          	jalr	1386(ra) # 80000be4 <acquire>
                p->sleeping_time = p->sleeping_time + ticks - p->last_time_changed;
    80002682:	000b2783          	lw	a5,0(s6)
    80002686:	44f8                	lw	a4,76(s1)
    80002688:	9f3d                	addw	a4,a4,a5
    8000268a:	4cb4                	lw	a3,88(s1)
    8000268c:	9f15                	subw	a4,a4,a3
    8000268e:	c4f8                	sw	a4,76(s1)
                p->last_runnable_time = ticks;     //added last_runnable time for fcfs
    80002690:	2781                	sext.w	a5,a5
    80002692:	c4bc                	sw	a5,72(s1)
                p->last_time_changed = ticks;      //setting the starting ticks when getting to runnable for section 4
    80002694:	ccbc                	sw	a5,88(s1)
                release(&tickslock);
    80002696:	8556                	mv	a0,s5
    80002698:	ffffe097          	auipc	ra,0xffffe
    8000269c:	600080e7          	jalr	1536(ra) # 80000c98 <release>
    800026a0:	b745                	j	80002640 <wakeup+0x3e>
        }
    }
}
    800026a2:	60a6                	ld	ra,72(sp)
    800026a4:	6406                	ld	s0,64(sp)
    800026a6:	74e2                	ld	s1,56(sp)
    800026a8:	7942                	ld	s2,48(sp)
    800026aa:	79a2                	ld	s3,40(sp)
    800026ac:	7a02                	ld	s4,32(sp)
    800026ae:	6ae2                	ld	s5,24(sp)
    800026b0:	6b42                	ld	s6,16(sp)
    800026b2:	6ba2                	ld	s7,8(sp)
    800026b4:	6161                	addi	sp,sp,80
    800026b6:	8082                	ret

00000000800026b8 <reparent>:
{
    800026b8:	7179                	addi	sp,sp,-48
    800026ba:	f406                	sd	ra,40(sp)
    800026bc:	f022                	sd	s0,32(sp)
    800026be:	ec26                	sd	s1,24(sp)
    800026c0:	e84a                	sd	s2,16(sp)
    800026c2:	e44e                	sd	s3,8(sp)
    800026c4:	e052                	sd	s4,0(sp)
    800026c6:	1800                	addi	s0,sp,48
    800026c8:	892a                	mv	s2,a0
    for(pp = proc; pp < &proc[NPROC]; pp++){
    800026ca:	0000f497          	auipc	s1,0xf
    800026ce:	02648493          	addi	s1,s1,38 # 800116f0 <proc>
            pp->parent = initproc;
    800026d2:	00007a17          	auipc	s4,0x7
    800026d6:	976a0a13          	addi	s4,s4,-1674 # 80009048 <initproc>
    for(pp = proc; pp < &proc[NPROC]; pp++){
    800026da:	00015997          	auipc	s3,0x15
    800026de:	21698993          	addi	s3,s3,534 # 800178f0 <tickslock>
    800026e2:	a029                	j	800026ec <reparent+0x34>
    800026e4:	18848493          	addi	s1,s1,392
    800026e8:	01348d63          	beq	s1,s3,80002702 <reparent+0x4a>
        if(pp->parent == p){
    800026ec:	7c9c                	ld	a5,56(s1)
    800026ee:	ff279be3          	bne	a5,s2,800026e4 <reparent+0x2c>
            pp->parent = initproc;
    800026f2:	000a3503          	ld	a0,0(s4)
    800026f6:	fc88                	sd	a0,56(s1)
            wakeup(initproc);
    800026f8:	00000097          	auipc	ra,0x0
    800026fc:	f0a080e7          	jalr	-246(ra) # 80002602 <wakeup>
    80002700:	b7d5                	j	800026e4 <reparent+0x2c>
}
    80002702:	70a2                	ld	ra,40(sp)
    80002704:	7402                	ld	s0,32(sp)
    80002706:	64e2                	ld	s1,24(sp)
    80002708:	6942                	ld	s2,16(sp)
    8000270a:	69a2                	ld	s3,8(sp)
    8000270c:	6a02                	ld	s4,0(sp)
    8000270e:	6145                	addi	sp,sp,48
    80002710:	8082                	ret

0000000080002712 <exit>:
{
    80002712:	7179                	addi	sp,sp,-48
    80002714:	f406                	sd	ra,40(sp)
    80002716:	f022                	sd	s0,32(sp)
    80002718:	ec26                	sd	s1,24(sp)
    8000271a:	e84a                	sd	s2,16(sp)
    8000271c:	e44e                	sd	s3,8(sp)
    8000271e:	e052                	sd	s4,0(sp)
    80002720:	1800                	addi	s0,sp,48
    80002722:	8a2a                	mv	s4,a0
    struct proc *p = myproc();
    80002724:	fffff097          	auipc	ra,0xfffff
    80002728:	2a4080e7          	jalr	676(ra) # 800019c8 <myproc>
    8000272c:	892a                	mv	s2,a0
    if(p == initproc)
    8000272e:	00007797          	auipc	a5,0x7
    80002732:	91a7b783          	ld	a5,-1766(a5) # 80009048 <initproc>
    80002736:	0f050493          	addi	s1,a0,240
    8000273a:	17050993          	addi	s3,a0,368
    8000273e:	02a79363          	bne	a5,a0,80002764 <exit+0x52>
        panic("init exiting");
    80002742:	00006517          	auipc	a0,0x6
    80002746:	b2650513          	addi	a0,a0,-1242 # 80008268 <digits+0x228>
    8000274a:	ffffe097          	auipc	ra,0xffffe
    8000274e:	df4080e7          	jalr	-524(ra) # 8000053e <panic>
            fileclose(f);
    80002752:	00002097          	auipc	ra,0x2
    80002756:	340080e7          	jalr	832(ra) # 80004a92 <fileclose>
            p->ofile[fd] = 0;
    8000275a:	0004b023          	sd	zero,0(s1)
    for(int fd = 0; fd < NOFILE; fd++){
    8000275e:	04a1                	addi	s1,s1,8
    80002760:	01348563          	beq	s1,s3,8000276a <exit+0x58>
        if(p->ofile[fd]){
    80002764:	6088                	ld	a0,0(s1)
    80002766:	f575                	bnez	a0,80002752 <exit+0x40>
    80002768:	bfdd                	j	8000275e <exit+0x4c>
    begin_op();
    8000276a:	00002097          	auipc	ra,0x2
    8000276e:	e5c080e7          	jalr	-420(ra) # 800045c6 <begin_op>
    iput(p->cwd);
    80002772:	17093503          	ld	a0,368(s2)
    80002776:	00001097          	auipc	ra,0x1
    8000277a:	638080e7          	jalr	1592(ra) # 80003dae <iput>
    end_op();
    8000277e:	00002097          	auipc	ra,0x2
    80002782:	ec8080e7          	jalr	-312(ra) # 80004646 <end_op>
    p->cwd = 0;
    80002786:	16093823          	sd	zero,368(s2)
    acquire(&wait_lock);
    8000278a:	0000f497          	auipc	s1,0xf
    8000278e:	b4e48493          	addi	s1,s1,-1202 # 800112d8 <wait_lock>
    80002792:	8526                	mv	a0,s1
    80002794:	ffffe097          	auipc	ra,0xffffe
    80002798:	450080e7          	jalr	1104(ra) # 80000be4 <acquire>
    reparent(p);
    8000279c:	854a                	mv	a0,s2
    8000279e:	00000097          	auipc	ra,0x0
    800027a2:	f1a080e7          	jalr	-230(ra) # 800026b8 <reparent>
    wakeup(p->parent);
    800027a6:	03893503          	ld	a0,56(s2)
    800027aa:	00000097          	auipc	ra,0x0
    800027ae:	e58080e7          	jalr	-424(ra) # 80002602 <wakeup>
    acquire(&p->lock);
    800027b2:	854a                	mv	a0,s2
    800027b4:	ffffe097          	auipc	ra,0xffffe
    800027b8:	430080e7          	jalr	1072(ra) # 80000be4 <acquire>
    acquire(&tickslock);
    800027bc:	00015517          	auipc	a0,0x15
    800027c0:	13450513          	addi	a0,a0,308 # 800178f0 <tickslock>
    800027c4:	ffffe097          	auipc	ra,0xffffe
    800027c8:	420080e7          	jalr	1056(ra) # 80000be4 <acquire>
    p->running_time = p->running_time + ticks - p->last_time_changed;
    800027cc:	00007617          	auipc	a2,0x7
    800027d0:	88462603          	lw	a2,-1916(a2) # 80009050 <ticks>
    800027d4:	05492703          	lw	a4,84(s2)
    800027d8:	9f31                	addw	a4,a4,a2
    800027da:	05892683          	lw	a3,88(s2)
    800027de:	40d706bb          	subw	a3,a4,a3
    800027e2:	04d92a23          	sw	a3,84(s2)
    program_time = program_time + p->running_time;
    800027e6:	00007717          	auipc	a4,0x7
    800027ea:	84a70713          	addi	a4,a4,-1974 # 80009030 <program_time>
    800027ee:	431c                	lw	a5,0(a4)
    800027f0:	9fb5                	addw	a5,a5,a3
    800027f2:	c31c                	sw	a5,0(a4)
    cpu_utilization = program_time / (ticks - start_time);
    800027f4:	00007717          	auipc	a4,0x7
    800027f8:	83472703          	lw	a4,-1996(a4) # 80009028 <start_time>
    800027fc:	9e19                	subw	a2,a2,a4
    800027fe:	02c7d7bb          	divuw	a5,a5,a2
    80002802:	00007717          	auipc	a4,0x7
    80002806:	82f72523          	sw	a5,-2006(a4) # 8000902c <cpu_utilization>
    sleeping_processes_mean = (sleeping_processes_mean*(nextpid-1) + p->sleeping_time)/(nextpid);
    8000280a:	00006617          	auipc	a2,0x6
    8000280e:	02a62603          	lw	a2,42(a2) # 80008834 <nextpid>
    80002812:	fff6059b          	addiw	a1,a2,-1
    80002816:	00007797          	auipc	a5,0x7
    8000281a:	82678793          	addi	a5,a5,-2010 # 8000903c <sleeping_processes_mean>
    8000281e:	4398                	lw	a4,0(a5)
    80002820:	02b7073b          	mulw	a4,a4,a1
    80002824:	04c92503          	lw	a0,76(s2)
    80002828:	9f29                	addw	a4,a4,a0
    8000282a:	02c7473b          	divw	a4,a4,a2
    8000282e:	c398                	sw	a4,0(a5)
    running_processes_mean = (running_processes_mean*(nextpid-1) + p->running_time)/(nextpid);
    80002830:	00007797          	auipc	a5,0x7
    80002834:	80878793          	addi	a5,a5,-2040 # 80009038 <running_processes_mean>
    80002838:	4398                	lw	a4,0(a5)
    8000283a:	02b7073b          	mulw	a4,a4,a1
    8000283e:	9f35                	addw	a4,a4,a3
    80002840:	02c7473b          	divw	a4,a4,a2
    80002844:	c398                	sw	a4,0(a5)
    runnable_processes_mean = (runnable_processes_mean*(nextpid-1) + p->runnable_time)/(nextpid);
    80002846:	00006717          	auipc	a4,0x6
    8000284a:	7ee70713          	addi	a4,a4,2030 # 80009034 <runnable_processes_mean>
    8000284e:	431c                	lw	a5,0(a4)
    80002850:	02b787bb          	mulw	a5,a5,a1
    80002854:	05092683          	lw	a3,80(s2)
    80002858:	9fb5                	addw	a5,a5,a3
    8000285a:	02c7c7bb          	divw	a5,a5,a2
    8000285e:	c31c                	sw	a5,0(a4)
    release(&tickslock);
    80002860:	00015517          	auipc	a0,0x15
    80002864:	09050513          	addi	a0,a0,144 # 800178f0 <tickslock>
    80002868:	ffffe097          	auipc	ra,0xffffe
    8000286c:	430080e7          	jalr	1072(ra) # 80000c98 <release>
    p->xstate = status;
    80002870:	03492623          	sw	s4,44(s2)
    p->state = ZOMBIE;
    80002874:	4795                	li	a5,5
    80002876:	00f92c23          	sw	a5,24(s2)
    release(&wait_lock);
    8000287a:	8526                	mv	a0,s1
    8000287c:	ffffe097          	auipc	ra,0xffffe
    80002880:	41c080e7          	jalr	1052(ra) # 80000c98 <release>
    sched();
    80002884:	00000097          	auipc	ra,0x0
    80002888:	a74080e7          	jalr	-1420(ra) # 800022f8 <sched>
    panic("zombie exit");
    8000288c:	00006517          	auipc	a0,0x6
    80002890:	9ec50513          	addi	a0,a0,-1556 # 80008278 <digits+0x238>
    80002894:	ffffe097          	auipc	ra,0xffffe
    80002898:	caa080e7          	jalr	-854(ra) # 8000053e <panic>

000000008000289c <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    8000289c:	7179                	addi	sp,sp,-48
    8000289e:	f406                	sd	ra,40(sp)
    800028a0:	f022                	sd	s0,32(sp)
    800028a2:	ec26                	sd	s1,24(sp)
    800028a4:	e84a                	sd	s2,16(sp)
    800028a6:	e44e                	sd	s3,8(sp)
    800028a8:	1800                	addi	s0,sp,48
    800028aa:	892a                	mv	s2,a0
    struct proc *p;

    for(p = proc; p < &proc[NPROC]; p++){
    800028ac:	0000f497          	auipc	s1,0xf
    800028b0:	e4448493          	addi	s1,s1,-444 # 800116f0 <proc>
    800028b4:	00015997          	auipc	s3,0x15
    800028b8:	03c98993          	addi	s3,s3,60 # 800178f0 <tickslock>
        acquire(&p->lock);
    800028bc:	8526                	mv	a0,s1
    800028be:	ffffe097          	auipc	ra,0xffffe
    800028c2:	326080e7          	jalr	806(ra) # 80000be4 <acquire>
        if(p->pid == pid){
    800028c6:	589c                	lw	a5,48(s1)
    800028c8:	01278d63          	beq	a5,s2,800028e2 <kill+0x46>
                release(&tickslock);
            }
            release(&p->lock);
            return 0;
        }
        release(&p->lock);
    800028cc:	8526                	mv	a0,s1
    800028ce:	ffffe097          	auipc	ra,0xffffe
    800028d2:	3ca080e7          	jalr	970(ra) # 80000c98 <release>
    for(p = proc; p < &proc[NPROC]; p++){
    800028d6:	18848493          	addi	s1,s1,392
    800028da:	ff3491e3          	bne	s1,s3,800028bc <kill+0x20>
    }
    return -1;
    800028de:	557d                	li	a0,-1
    800028e0:	a829                	j	800028fa <kill+0x5e>
            p->killed = 1;
    800028e2:	4785                	li	a5,1
    800028e4:	d49c                	sw	a5,40(s1)
            if(p->state == SLEEPING){
    800028e6:	4c98                	lw	a4,24(s1)
    800028e8:	4789                	li	a5,2
    800028ea:	00f70f63          	beq	a4,a5,80002908 <kill+0x6c>
            release(&p->lock);
    800028ee:	8526                	mv	a0,s1
    800028f0:	ffffe097          	auipc	ra,0xffffe
    800028f4:	3a8080e7          	jalr	936(ra) # 80000c98 <release>
            return 0;
    800028f8:	4501                	li	a0,0
}
    800028fa:	70a2                	ld	ra,40(sp)
    800028fc:	7402                	ld	s0,32(sp)
    800028fe:	64e2                	ld	s1,24(sp)
    80002900:	6942                	ld	s2,16(sp)
    80002902:	69a2                	ld	s3,8(sp)
    80002904:	6145                	addi	sp,sp,48
    80002906:	8082                	ret
                p->state = RUNNABLE;
    80002908:	478d                	li	a5,3
    8000290a:	cc9c                	sw	a5,24(s1)
                acquire(&tickslock);
    8000290c:	00015517          	auipc	a0,0x15
    80002910:	fe450513          	addi	a0,a0,-28 # 800178f0 <tickslock>
    80002914:	ffffe097          	auipc	ra,0xffffe
    80002918:	2d0080e7          	jalr	720(ra) # 80000be4 <acquire>
                p->sleeping_time = p->sleeping_time + ticks - p->last_time_changed;
    8000291c:	00006797          	auipc	a5,0x6
    80002920:	7347a783          	lw	a5,1844(a5) # 80009050 <ticks>
    80002924:	44f8                	lw	a4,76(s1)
    80002926:	9f3d                	addw	a4,a4,a5
    80002928:	4cb4                	lw	a3,88(s1)
    8000292a:	9f15                	subw	a4,a4,a3
    8000292c:	c4f8                	sw	a4,76(s1)
                p->last_runnable_time = ticks;     //added last_runnable time for fcfs
    8000292e:	2781                	sext.w	a5,a5
    80002930:	c4bc                	sw	a5,72(s1)
                p->last_time_changed = ticks;      //setting the starting ticks when getting to runnable for section 4
    80002932:	ccbc                	sw	a5,88(s1)
                release(&tickslock);
    80002934:	00015517          	auipc	a0,0x15
    80002938:	fbc50513          	addi	a0,a0,-68 # 800178f0 <tickslock>
    8000293c:	ffffe097          	auipc	ra,0xffffe
    80002940:	35c080e7          	jalr	860(ra) # 80000c98 <release>
    80002944:	b76d                	j	800028ee <kill+0x52>

0000000080002946 <kill_system>:

int kill_system(void){
    80002946:	7179                	addi	sp,sp,-48
    80002948:	f406                	sd	ra,40(sp)
    8000294a:	f022                	sd	s0,32(sp)
    8000294c:	ec26                	sd	s1,24(sp)
    8000294e:	e84a                	sd	s2,16(sp)
    80002950:	e44e                	sd	s3,8(sp)
    80002952:	1800                	addi	s0,sp,48
    // init pid = 1
    // shell pid = 2
    struct proc *p;
    int i = 0;
    for(p = proc; p < &proc[NPROC]; p++, i++) {
    80002954:	0000f497          	auipc	s1,0xf
    80002958:	d9c48493          	addi	s1,s1,-612 # 800116f0 <proc>
        acquire(&p->lock);
        if(p->pid != 1 && p->pid != 2) {
    8000295c:	4985                	li	s3,1
    for(p = proc; p < &proc[NPROC]; p++, i++) {
    8000295e:	00015917          	auipc	s2,0x15
    80002962:	f9290913          	addi	s2,s2,-110 # 800178f0 <tickslock>
    80002966:	a811                	j	8000297a <kill_system+0x34>
            release(&p->lock);
            kill(p->pid);
        } else{
            release(&p->lock);
    80002968:	8526                	mv	a0,s1
    8000296a:	ffffe097          	auipc	ra,0xffffe
    8000296e:	32e080e7          	jalr	814(ra) # 80000c98 <release>
    for(p = proc; p < &proc[NPROC]; p++, i++) {
    80002972:	18848493          	addi	s1,s1,392
    80002976:	03248663          	beq	s1,s2,800029a2 <kill_system+0x5c>
        acquire(&p->lock);
    8000297a:	8526                	mv	a0,s1
    8000297c:	ffffe097          	auipc	ra,0xffffe
    80002980:	268080e7          	jalr	616(ra) # 80000be4 <acquire>
        if(p->pid != 1 && p->pid != 2) {
    80002984:	589c                	lw	a5,48(s1)
    80002986:	37fd                	addiw	a5,a5,-1
    80002988:	fef9f0e3          	bgeu	s3,a5,80002968 <kill_system+0x22>
            release(&p->lock);
    8000298c:	8526                	mv	a0,s1
    8000298e:	ffffe097          	auipc	ra,0xffffe
    80002992:	30a080e7          	jalr	778(ra) # 80000c98 <release>
            kill(p->pid);
    80002996:	5888                	lw	a0,48(s1)
    80002998:	00000097          	auipc	ra,0x0
    8000299c:	f04080e7          	jalr	-252(ra) # 8000289c <kill>
    800029a0:	bfc9                	j	80002972 <kill_system+0x2c>
        }
    }

    return 0;
    //todo check if need to verify kill returned 0, in case not what should we do.
}
    800029a2:	4501                	li	a0,0
    800029a4:	70a2                	ld	ra,40(sp)
    800029a6:	7402                	ld	s0,32(sp)
    800029a8:	64e2                	ld	s1,24(sp)
    800029aa:	6942                	ld	s2,16(sp)
    800029ac:	69a2                	ld	s3,8(sp)
    800029ae:	6145                	addi	sp,sp,48
    800029b0:	8082                	ret

00000000800029b2 <pause_system>:

//pause all user processes for the number of seconds specified by the parameter
int pause_system(int seconds){
    800029b2:	1141                	addi	sp,sp,-16
    800029b4:	e406                	sd	ra,8(sp)
    800029b6:	e022                	sd	s0,0(sp)
    800029b8:	0800                	addi	s0,sp,16
    pauseTicks = ticks + seconds*10; //todo check if can get 1000000 as number
    800029ba:	0025179b          	slliw	a5,a0,0x2
    800029be:	9fa9                	addw	a5,a5,a0
    800029c0:	0017979b          	slliw	a5,a5,0x1
    800029c4:	00006517          	auipc	a0,0x6
    800029c8:	68c52503          	lw	a0,1676(a0) # 80009050 <ticks>
    800029cc:	9fa9                	addw	a5,a5,a0
    800029ce:	00006717          	auipc	a4,0x6
    800029d2:	66f72923          	sw	a5,1650(a4) # 80009040 <pauseTicks>
    yield();
    800029d6:	00000097          	auipc	ra,0x0
    800029da:	9f8080e7          	jalr	-1544(ra) # 800023ce <yield>
    return 0;
}
    800029de:	4501                	li	a0,0
    800029e0:	60a2                	ld	ra,8(sp)
    800029e2:	6402                	ld	s0,0(sp)
    800029e4:	0141                	addi	sp,sp,16
    800029e6:	8082                	ret

00000000800029e8 <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    800029e8:	7179                	addi	sp,sp,-48
    800029ea:	f406                	sd	ra,40(sp)
    800029ec:	f022                	sd	s0,32(sp)
    800029ee:	ec26                	sd	s1,24(sp)
    800029f0:	e84a                	sd	s2,16(sp)
    800029f2:	e44e                	sd	s3,8(sp)
    800029f4:	e052                	sd	s4,0(sp)
    800029f6:	1800                	addi	s0,sp,48
    800029f8:	84aa                	mv	s1,a0
    800029fa:	892e                	mv	s2,a1
    800029fc:	89b2                	mv	s3,a2
    800029fe:	8a36                	mv	s4,a3
    struct proc *p = myproc();
    80002a00:	fffff097          	auipc	ra,0xfffff
    80002a04:	fc8080e7          	jalr	-56(ra) # 800019c8 <myproc>
    if(user_dst){
    80002a08:	c08d                	beqz	s1,80002a2a <either_copyout+0x42>
        return copyout(p->pagetable, dst, src, len);
    80002a0a:	86d2                	mv	a3,s4
    80002a0c:	864e                	mv	a2,s3
    80002a0e:	85ca                	mv	a1,s2
    80002a10:	7928                	ld	a0,112(a0)
    80002a12:	fffff097          	auipc	ra,0xfffff
    80002a16:	c68080e7          	jalr	-920(ra) # 8000167a <copyout>
    } else {
        memmove((char *)dst, src, len);
        return 0;
    }
}
    80002a1a:	70a2                	ld	ra,40(sp)
    80002a1c:	7402                	ld	s0,32(sp)
    80002a1e:	64e2                	ld	s1,24(sp)
    80002a20:	6942                	ld	s2,16(sp)
    80002a22:	69a2                	ld	s3,8(sp)
    80002a24:	6a02                	ld	s4,0(sp)
    80002a26:	6145                	addi	sp,sp,48
    80002a28:	8082                	ret
        memmove((char *)dst, src, len);
    80002a2a:	000a061b          	sext.w	a2,s4
    80002a2e:	85ce                	mv	a1,s3
    80002a30:	854a                	mv	a0,s2
    80002a32:	ffffe097          	auipc	ra,0xffffe
    80002a36:	30e080e7          	jalr	782(ra) # 80000d40 <memmove>
        return 0;
    80002a3a:	8526                	mv	a0,s1
    80002a3c:	bff9                	j	80002a1a <either_copyout+0x32>

0000000080002a3e <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    80002a3e:	7179                	addi	sp,sp,-48
    80002a40:	f406                	sd	ra,40(sp)
    80002a42:	f022                	sd	s0,32(sp)
    80002a44:	ec26                	sd	s1,24(sp)
    80002a46:	e84a                	sd	s2,16(sp)
    80002a48:	e44e                	sd	s3,8(sp)
    80002a4a:	e052                	sd	s4,0(sp)
    80002a4c:	1800                	addi	s0,sp,48
    80002a4e:	892a                	mv	s2,a0
    80002a50:	84ae                	mv	s1,a1
    80002a52:	89b2                	mv	s3,a2
    80002a54:	8a36                	mv	s4,a3
    struct proc *p = myproc();
    80002a56:	fffff097          	auipc	ra,0xfffff
    80002a5a:	f72080e7          	jalr	-142(ra) # 800019c8 <myproc>
    if(user_src){
    80002a5e:	c08d                	beqz	s1,80002a80 <either_copyin+0x42>
        return copyin(p->pagetable, dst, src, len);
    80002a60:	86d2                	mv	a3,s4
    80002a62:	864e                	mv	a2,s3
    80002a64:	85ca                	mv	a1,s2
    80002a66:	7928                	ld	a0,112(a0)
    80002a68:	fffff097          	auipc	ra,0xfffff
    80002a6c:	c9e080e7          	jalr	-866(ra) # 80001706 <copyin>
    } else {
        memmove(dst, (char*)src, len);
        return 0;
    }
}
    80002a70:	70a2                	ld	ra,40(sp)
    80002a72:	7402                	ld	s0,32(sp)
    80002a74:	64e2                	ld	s1,24(sp)
    80002a76:	6942                	ld	s2,16(sp)
    80002a78:	69a2                	ld	s3,8(sp)
    80002a7a:	6a02                	ld	s4,0(sp)
    80002a7c:	6145                	addi	sp,sp,48
    80002a7e:	8082                	ret
        memmove(dst, (char*)src, len);
    80002a80:	000a061b          	sext.w	a2,s4
    80002a84:	85ce                	mv	a1,s3
    80002a86:	854a                	mv	a0,s2
    80002a88:	ffffe097          	auipc	ra,0xffffe
    80002a8c:	2b8080e7          	jalr	696(ra) # 80000d40 <memmove>
        return 0;
    80002a90:	8526                	mv	a0,s1
    80002a92:	bff9                	j	80002a70 <either_copyin+0x32>

0000000080002a94 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    80002a94:	715d                	addi	sp,sp,-80
    80002a96:	e486                	sd	ra,72(sp)
    80002a98:	e0a2                	sd	s0,64(sp)
    80002a9a:	fc26                	sd	s1,56(sp)
    80002a9c:	f84a                	sd	s2,48(sp)
    80002a9e:	f44e                	sd	s3,40(sp)
    80002aa0:	f052                	sd	s4,32(sp)
    80002aa2:	ec56                	sd	s5,24(sp)
    80002aa4:	e85a                	sd	s6,16(sp)
    80002aa6:	e45e                	sd	s7,8(sp)
    80002aa8:	0880                	addi	s0,sp,80
            [ZOMBIE]    "zombie"
    };
    struct proc *p;
    char *state;

    printf("\n");
    80002aaa:	00005517          	auipc	a0,0x5
    80002aae:	61e50513          	addi	a0,a0,1566 # 800080c8 <digits+0x88>
    80002ab2:	ffffe097          	auipc	ra,0xffffe
    80002ab6:	ad6080e7          	jalr	-1322(ra) # 80000588 <printf>
    for(p = proc; p < &proc[NPROC]; p++){
    80002aba:	0000f497          	auipc	s1,0xf
    80002abe:	dae48493          	addi	s1,s1,-594 # 80011868 <proc+0x178>
    80002ac2:	00015917          	auipc	s2,0x15
    80002ac6:	fa690913          	addi	s2,s2,-90 # 80017a68 <bcache+0x160>
        if(p->state == UNUSED)
            continue;
        if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002aca:	4b15                	li	s6,5
            state = states[p->state];
        else
            state = "???";
    80002acc:	00005997          	auipc	s3,0x5
    80002ad0:	7bc98993          	addi	s3,s3,1980 # 80008288 <digits+0x248>
        printf("%d %s %s", p->pid, state, p->name);
    80002ad4:	00005a97          	auipc	s5,0x5
    80002ad8:	7bca8a93          	addi	s5,s5,1980 # 80008290 <digits+0x250>
        printf("\n");
    80002adc:	00005a17          	auipc	s4,0x5
    80002ae0:	5eca0a13          	addi	s4,s4,1516 # 800080c8 <digits+0x88>
        if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002ae4:	00005b97          	auipc	s7,0x5
    80002ae8:	7e4b8b93          	addi	s7,s7,2020 # 800082c8 <states.1780>
    80002aec:	a00d                	j	80002b0e <procdump+0x7a>
        printf("%d %s %s", p->pid, state, p->name);
    80002aee:	eb86a583          	lw	a1,-328(a3)
    80002af2:	8556                	mv	a0,s5
    80002af4:	ffffe097          	auipc	ra,0xffffe
    80002af8:	a94080e7          	jalr	-1388(ra) # 80000588 <printf>
        printf("\n");
    80002afc:	8552                	mv	a0,s4
    80002afe:	ffffe097          	auipc	ra,0xffffe
    80002b02:	a8a080e7          	jalr	-1398(ra) # 80000588 <printf>
    for(p = proc; p < &proc[NPROC]; p++){
    80002b06:	18848493          	addi	s1,s1,392
    80002b0a:	03248163          	beq	s1,s2,80002b2c <procdump+0x98>
        if(p->state == UNUSED)
    80002b0e:	86a6                	mv	a3,s1
    80002b10:	ea04a783          	lw	a5,-352(s1)
    80002b14:	dbed                	beqz	a5,80002b06 <procdump+0x72>
            state = "???";
    80002b16:	864e                	mv	a2,s3
        if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002b18:	fcfb6be3          	bltu	s6,a5,80002aee <procdump+0x5a>
    80002b1c:	1782                	slli	a5,a5,0x20
    80002b1e:	9381                	srli	a5,a5,0x20
    80002b20:	078e                	slli	a5,a5,0x3
    80002b22:	97de                	add	a5,a5,s7
    80002b24:	6390                	ld	a2,0(a5)
    80002b26:	f661                	bnez	a2,80002aee <procdump+0x5a>
            state = "???";
    80002b28:	864e                	mv	a2,s3
    80002b2a:	b7d1                	j	80002aee <procdump+0x5a>
    }
    80002b2c:	60a6                	ld	ra,72(sp)
    80002b2e:	6406                	ld	s0,64(sp)
    80002b30:	74e2                	ld	s1,56(sp)
    80002b32:	7942                	ld	s2,48(sp)
    80002b34:	79a2                	ld	s3,40(sp)
    80002b36:	7a02                	ld	s4,32(sp)
    80002b38:	6ae2                	ld	s5,24(sp)
    80002b3a:	6b42                	ld	s6,16(sp)
    80002b3c:	6ba2                	ld	s7,8(sp)
    80002b3e:	6161                	addi	sp,sp,80
    80002b40:	8082                	ret

0000000080002b42 <swtch>:
    80002b42:	00153023          	sd	ra,0(a0)
    80002b46:	00253423          	sd	sp,8(a0)
    80002b4a:	e900                	sd	s0,16(a0)
    80002b4c:	ed04                	sd	s1,24(a0)
    80002b4e:	03253023          	sd	s2,32(a0)
    80002b52:	03353423          	sd	s3,40(a0)
    80002b56:	03453823          	sd	s4,48(a0)
    80002b5a:	03553c23          	sd	s5,56(a0)
    80002b5e:	05653023          	sd	s6,64(a0)
    80002b62:	05753423          	sd	s7,72(a0)
    80002b66:	05853823          	sd	s8,80(a0)
    80002b6a:	05953c23          	sd	s9,88(a0)
    80002b6e:	07a53023          	sd	s10,96(a0)
    80002b72:	07b53423          	sd	s11,104(a0)
    80002b76:	0005b083          	ld	ra,0(a1)
    80002b7a:	0085b103          	ld	sp,8(a1)
    80002b7e:	6980                	ld	s0,16(a1)
    80002b80:	6d84                	ld	s1,24(a1)
    80002b82:	0205b903          	ld	s2,32(a1)
    80002b86:	0285b983          	ld	s3,40(a1)
    80002b8a:	0305ba03          	ld	s4,48(a1)
    80002b8e:	0385ba83          	ld	s5,56(a1)
    80002b92:	0405bb03          	ld	s6,64(a1)
    80002b96:	0485bb83          	ld	s7,72(a1)
    80002b9a:	0505bc03          	ld	s8,80(a1)
    80002b9e:	0585bc83          	ld	s9,88(a1)
    80002ba2:	0605bd03          	ld	s10,96(a1)
    80002ba6:	0685bd83          	ld	s11,104(a1)
    80002baa:	8082                	ret

0000000080002bac <trapinit>:

extern int devintr();

void
trapinit(void)
{
    80002bac:	1141                	addi	sp,sp,-16
    80002bae:	e406                	sd	ra,8(sp)
    80002bb0:	e022                	sd	s0,0(sp)
    80002bb2:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002bb4:	00005597          	auipc	a1,0x5
    80002bb8:	74458593          	addi	a1,a1,1860 # 800082f8 <states.1780+0x30>
    80002bbc:	00015517          	auipc	a0,0x15
    80002bc0:	d3450513          	addi	a0,a0,-716 # 800178f0 <tickslock>
    80002bc4:	ffffe097          	auipc	ra,0xffffe
    80002bc8:	f90080e7          	jalr	-112(ra) # 80000b54 <initlock>
}
    80002bcc:	60a2                	ld	ra,8(sp)
    80002bce:	6402                	ld	s0,0(sp)
    80002bd0:	0141                	addi	sp,sp,16
    80002bd2:	8082                	ret

0000000080002bd4 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    80002bd4:	1141                	addi	sp,sp,-16
    80002bd6:	e422                	sd	s0,8(sp)
    80002bd8:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002bda:	00003797          	auipc	a5,0x3
    80002bde:	4d678793          	addi	a5,a5,1238 # 800060b0 <kernelvec>
    80002be2:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002be6:	6422                	ld	s0,8(sp)
    80002be8:	0141                	addi	sp,sp,16
    80002bea:	8082                	ret

0000000080002bec <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002bec:	1141                	addi	sp,sp,-16
    80002bee:	e406                	sd	ra,8(sp)
    80002bf0:	e022                	sd	s0,0(sp)
    80002bf2:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002bf4:	fffff097          	auipc	ra,0xfffff
    80002bf8:	dd4080e7          	jalr	-556(ra) # 800019c8 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002bfc:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002c00:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002c02:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    80002c06:	00004617          	auipc	a2,0x4
    80002c0a:	3fa60613          	addi	a2,a2,1018 # 80007000 <_trampoline>
    80002c0e:	00004697          	auipc	a3,0x4
    80002c12:	3f268693          	addi	a3,a3,1010 # 80007000 <_trampoline>
    80002c16:	8e91                	sub	a3,a3,a2
    80002c18:	040007b7          	lui	a5,0x4000
    80002c1c:	17fd                	addi	a5,a5,-1
    80002c1e:	07b2                	slli	a5,a5,0xc
    80002c20:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002c22:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002c26:	7d38                	ld	a4,120(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002c28:	180026f3          	csrr	a3,satp
    80002c2c:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002c2e:	7d38                	ld	a4,120(a0)
    80002c30:	7134                	ld	a3,96(a0)
    80002c32:	6585                	lui	a1,0x1
    80002c34:	96ae                	add	a3,a3,a1
    80002c36:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002c38:	7d38                	ld	a4,120(a0)
    80002c3a:	00000697          	auipc	a3,0x0
    80002c3e:	13868693          	addi	a3,a3,312 # 80002d72 <usertrap>
    80002c42:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80002c44:	7d38                	ld	a4,120(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002c46:	8692                	mv	a3,tp
    80002c48:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002c4a:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002c4e:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002c52:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002c56:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002c5a:	7d38                	ld	a4,120(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002c5c:	6f18                	ld	a4,24(a4)
    80002c5e:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002c62:	792c                	ld	a1,112(a0)
    80002c64:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    80002c66:	00004717          	auipc	a4,0x4
    80002c6a:	42a70713          	addi	a4,a4,1066 # 80007090 <userret>
    80002c6e:	8f11                	sub	a4,a4,a2
    80002c70:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    80002c72:	577d                	li	a4,-1
    80002c74:	177e                	slli	a4,a4,0x3f
    80002c76:	8dd9                	or	a1,a1,a4
    80002c78:	02000537          	lui	a0,0x2000
    80002c7c:	157d                	addi	a0,a0,-1
    80002c7e:	0536                	slli	a0,a0,0xd
    80002c80:	9782                	jalr	a5
}
    80002c82:	60a2                	ld	ra,8(sp)
    80002c84:	6402                	ld	s0,0(sp)
    80002c86:	0141                	addi	sp,sp,16
    80002c88:	8082                	ret

0000000080002c8a <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80002c8a:	1101                	addi	sp,sp,-32
    80002c8c:	ec06                	sd	ra,24(sp)
    80002c8e:	e822                	sd	s0,16(sp)
    80002c90:	e426                	sd	s1,8(sp)
    80002c92:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002c94:	00015497          	auipc	s1,0x15
    80002c98:	c5c48493          	addi	s1,s1,-932 # 800178f0 <tickslock>
    80002c9c:	8526                	mv	a0,s1
    80002c9e:	ffffe097          	auipc	ra,0xffffe
    80002ca2:	f46080e7          	jalr	-186(ra) # 80000be4 <acquire>
  ticks++;
    80002ca6:	00006517          	auipc	a0,0x6
    80002caa:	3aa50513          	addi	a0,a0,938 # 80009050 <ticks>
    80002cae:	411c                	lw	a5,0(a0)
    80002cb0:	2785                	addiw	a5,a5,1
    80002cb2:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80002cb4:	00000097          	auipc	ra,0x0
    80002cb8:	94e080e7          	jalr	-1714(ra) # 80002602 <wakeup>
  release(&tickslock);
    80002cbc:	8526                	mv	a0,s1
    80002cbe:	ffffe097          	auipc	ra,0xffffe
    80002cc2:	fda080e7          	jalr	-38(ra) # 80000c98 <release>
}
    80002cc6:	60e2                	ld	ra,24(sp)
    80002cc8:	6442                	ld	s0,16(sp)
    80002cca:	64a2                	ld	s1,8(sp)
    80002ccc:	6105                	addi	sp,sp,32
    80002cce:	8082                	ret

0000000080002cd0 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80002cd0:	1101                	addi	sp,sp,-32
    80002cd2:	ec06                	sd	ra,24(sp)
    80002cd4:	e822                	sd	s0,16(sp)
    80002cd6:	e426                	sd	s1,8(sp)
    80002cd8:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002cda:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80002cde:	00074d63          	bltz	a4,80002cf8 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80002ce2:	57fd                	li	a5,-1
    80002ce4:	17fe                	slli	a5,a5,0x3f
    80002ce6:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002ce8:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002cea:	06f70363          	beq	a4,a5,80002d50 <devintr+0x80>
  }
}
    80002cee:	60e2                	ld	ra,24(sp)
    80002cf0:	6442                	ld	s0,16(sp)
    80002cf2:	64a2                	ld	s1,8(sp)
    80002cf4:	6105                	addi	sp,sp,32
    80002cf6:	8082                	ret
     (scause & 0xff) == 9){
    80002cf8:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    80002cfc:	46a5                	li	a3,9
    80002cfe:	fed792e3          	bne	a5,a3,80002ce2 <devintr+0x12>
    int irq = plic_claim();
    80002d02:	00003097          	auipc	ra,0x3
    80002d06:	4b6080e7          	jalr	1206(ra) # 800061b8 <plic_claim>
    80002d0a:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002d0c:	47a9                	li	a5,10
    80002d0e:	02f50763          	beq	a0,a5,80002d3c <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80002d12:	4785                	li	a5,1
    80002d14:	02f50963          	beq	a0,a5,80002d46 <devintr+0x76>
    return 1;
    80002d18:	4505                	li	a0,1
    } else if(irq){
    80002d1a:	d8f1                	beqz	s1,80002cee <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002d1c:	85a6                	mv	a1,s1
    80002d1e:	00005517          	auipc	a0,0x5
    80002d22:	5e250513          	addi	a0,a0,1506 # 80008300 <states.1780+0x38>
    80002d26:	ffffe097          	auipc	ra,0xffffe
    80002d2a:	862080e7          	jalr	-1950(ra) # 80000588 <printf>
      plic_complete(irq);
    80002d2e:	8526                	mv	a0,s1
    80002d30:	00003097          	auipc	ra,0x3
    80002d34:	4ac080e7          	jalr	1196(ra) # 800061dc <plic_complete>
    return 1;
    80002d38:	4505                	li	a0,1
    80002d3a:	bf55                	j	80002cee <devintr+0x1e>
      uartintr();
    80002d3c:	ffffe097          	auipc	ra,0xffffe
    80002d40:	c6c080e7          	jalr	-916(ra) # 800009a8 <uartintr>
    80002d44:	b7ed                	j	80002d2e <devintr+0x5e>
      virtio_disk_intr();
    80002d46:	00004097          	auipc	ra,0x4
    80002d4a:	976080e7          	jalr	-1674(ra) # 800066bc <virtio_disk_intr>
    80002d4e:	b7c5                	j	80002d2e <devintr+0x5e>
    if(cpuid() == 0){
    80002d50:	fffff097          	auipc	ra,0xfffff
    80002d54:	c4c080e7          	jalr	-948(ra) # 8000199c <cpuid>
    80002d58:	c901                	beqz	a0,80002d68 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002d5a:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002d5e:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002d60:	14479073          	csrw	sip,a5
    return 2;
    80002d64:	4509                	li	a0,2
    80002d66:	b761                	j	80002cee <devintr+0x1e>
      clockintr();
    80002d68:	00000097          	auipc	ra,0x0
    80002d6c:	f22080e7          	jalr	-222(ra) # 80002c8a <clockintr>
    80002d70:	b7ed                	j	80002d5a <devintr+0x8a>

0000000080002d72 <usertrap>:
{
    80002d72:	1101                	addi	sp,sp,-32
    80002d74:	ec06                	sd	ra,24(sp)
    80002d76:	e822                	sd	s0,16(sp)
    80002d78:	e426                	sd	s1,8(sp)
    80002d7a:	e04a                	sd	s2,0(sp)
    80002d7c:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002d7e:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002d82:	1007f793          	andi	a5,a5,256
    80002d86:	e3ad                	bnez	a5,80002de8 <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002d88:	00003797          	auipc	a5,0x3
    80002d8c:	32878793          	addi	a5,a5,808 # 800060b0 <kernelvec>
    80002d90:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002d94:	fffff097          	auipc	ra,0xfffff
    80002d98:	c34080e7          	jalr	-972(ra) # 800019c8 <myproc>
    80002d9c:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002d9e:	7d3c                	ld	a5,120(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002da0:	14102773          	csrr	a4,sepc
    80002da4:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002da6:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002daa:	47a1                	li	a5,8
    80002dac:	04f71c63          	bne	a4,a5,80002e04 <usertrap+0x92>
    if(p->killed)
    80002db0:	551c                	lw	a5,40(a0)
    80002db2:	e3b9                	bnez	a5,80002df8 <usertrap+0x86>
    p->trapframe->epc += 4;
    80002db4:	7cb8                	ld	a4,120(s1)
    80002db6:	6f1c                	ld	a5,24(a4)
    80002db8:	0791                	addi	a5,a5,4
    80002dba:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002dbc:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002dc0:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002dc4:	10079073          	csrw	sstatus,a5
    syscall();
    80002dc8:	00000097          	auipc	ra,0x0
    80002dcc:	2e0080e7          	jalr	736(ra) # 800030a8 <syscall>
  if(p->killed)
    80002dd0:	549c                	lw	a5,40(s1)
    80002dd2:	ebc1                	bnez	a5,80002e62 <usertrap+0xf0>
  usertrapret();
    80002dd4:	00000097          	auipc	ra,0x0
    80002dd8:	e18080e7          	jalr	-488(ra) # 80002bec <usertrapret>
}
    80002ddc:	60e2                	ld	ra,24(sp)
    80002dde:	6442                	ld	s0,16(sp)
    80002de0:	64a2                	ld	s1,8(sp)
    80002de2:	6902                	ld	s2,0(sp)
    80002de4:	6105                	addi	sp,sp,32
    80002de6:	8082                	ret
    panic("usertrap: not from user mode");
    80002de8:	00005517          	auipc	a0,0x5
    80002dec:	53850513          	addi	a0,a0,1336 # 80008320 <states.1780+0x58>
    80002df0:	ffffd097          	auipc	ra,0xffffd
    80002df4:	74e080e7          	jalr	1870(ra) # 8000053e <panic>
      exit(-1);
    80002df8:	557d                	li	a0,-1
    80002dfa:	00000097          	auipc	ra,0x0
    80002dfe:	918080e7          	jalr	-1768(ra) # 80002712 <exit>
    80002e02:	bf4d                	j	80002db4 <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    80002e04:	00000097          	auipc	ra,0x0
    80002e08:	ecc080e7          	jalr	-308(ra) # 80002cd0 <devintr>
    80002e0c:	892a                	mv	s2,a0
    80002e0e:	c501                	beqz	a0,80002e16 <usertrap+0xa4>
  if(p->killed)
    80002e10:	549c                	lw	a5,40(s1)
    80002e12:	c3a1                	beqz	a5,80002e52 <usertrap+0xe0>
    80002e14:	a815                	j	80002e48 <usertrap+0xd6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002e16:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002e1a:	5890                	lw	a2,48(s1)
    80002e1c:	00005517          	auipc	a0,0x5
    80002e20:	52450513          	addi	a0,a0,1316 # 80008340 <states.1780+0x78>
    80002e24:	ffffd097          	auipc	ra,0xffffd
    80002e28:	764080e7          	jalr	1892(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002e2c:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002e30:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002e34:	00005517          	auipc	a0,0x5
    80002e38:	53c50513          	addi	a0,a0,1340 # 80008370 <states.1780+0xa8>
    80002e3c:	ffffd097          	auipc	ra,0xffffd
    80002e40:	74c080e7          	jalr	1868(ra) # 80000588 <printf>
    p->killed = 1;
    80002e44:	4785                	li	a5,1
    80002e46:	d49c                	sw	a5,40(s1)
    exit(-1);
    80002e48:	557d                	li	a0,-1
    80002e4a:	00000097          	auipc	ra,0x0
    80002e4e:	8c8080e7          	jalr	-1848(ra) # 80002712 <exit>
  if(which_dev == 2)
    80002e52:	4789                	li	a5,2
    80002e54:	f8f910e3          	bne	s2,a5,80002dd4 <usertrap+0x62>
    yield();
    80002e58:	fffff097          	auipc	ra,0xfffff
    80002e5c:	576080e7          	jalr	1398(ra) # 800023ce <yield>
    80002e60:	bf95                	j	80002dd4 <usertrap+0x62>
  int which_dev = 0;
    80002e62:	4901                	li	s2,0
    80002e64:	b7d5                	j	80002e48 <usertrap+0xd6>

0000000080002e66 <kerneltrap>:
{
    80002e66:	7179                	addi	sp,sp,-48
    80002e68:	f406                	sd	ra,40(sp)
    80002e6a:	f022                	sd	s0,32(sp)
    80002e6c:	ec26                	sd	s1,24(sp)
    80002e6e:	e84a                	sd	s2,16(sp)
    80002e70:	e44e                	sd	s3,8(sp)
    80002e72:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002e74:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002e78:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002e7c:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002e80:	1004f793          	andi	a5,s1,256
    80002e84:	cb85                	beqz	a5,80002eb4 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002e86:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002e8a:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002e8c:	ef85                	bnez	a5,80002ec4 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002e8e:	00000097          	auipc	ra,0x0
    80002e92:	e42080e7          	jalr	-446(ra) # 80002cd0 <devintr>
    80002e96:	cd1d                	beqz	a0,80002ed4 <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002e98:	4789                	li	a5,2
    80002e9a:	06f50a63          	beq	a0,a5,80002f0e <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002e9e:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002ea2:	10049073          	csrw	sstatus,s1
}
    80002ea6:	70a2                	ld	ra,40(sp)
    80002ea8:	7402                	ld	s0,32(sp)
    80002eaa:	64e2                	ld	s1,24(sp)
    80002eac:	6942                	ld	s2,16(sp)
    80002eae:	69a2                	ld	s3,8(sp)
    80002eb0:	6145                	addi	sp,sp,48
    80002eb2:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002eb4:	00005517          	auipc	a0,0x5
    80002eb8:	4dc50513          	addi	a0,a0,1244 # 80008390 <states.1780+0xc8>
    80002ebc:	ffffd097          	auipc	ra,0xffffd
    80002ec0:	682080e7          	jalr	1666(ra) # 8000053e <panic>
    panic("kerneltrap: interrupts enabled");
    80002ec4:	00005517          	auipc	a0,0x5
    80002ec8:	4f450513          	addi	a0,a0,1268 # 800083b8 <states.1780+0xf0>
    80002ecc:	ffffd097          	auipc	ra,0xffffd
    80002ed0:	672080e7          	jalr	1650(ra) # 8000053e <panic>
    printf("scause %p\n", scause);
    80002ed4:	85ce                	mv	a1,s3
    80002ed6:	00005517          	auipc	a0,0x5
    80002eda:	50250513          	addi	a0,a0,1282 # 800083d8 <states.1780+0x110>
    80002ede:	ffffd097          	auipc	ra,0xffffd
    80002ee2:	6aa080e7          	jalr	1706(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002ee6:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002eea:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002eee:	00005517          	auipc	a0,0x5
    80002ef2:	4fa50513          	addi	a0,a0,1274 # 800083e8 <states.1780+0x120>
    80002ef6:	ffffd097          	auipc	ra,0xffffd
    80002efa:	692080e7          	jalr	1682(ra) # 80000588 <printf>
    panic("kerneltrap");
    80002efe:	00005517          	auipc	a0,0x5
    80002f02:	50250513          	addi	a0,a0,1282 # 80008400 <states.1780+0x138>
    80002f06:	ffffd097          	auipc	ra,0xffffd
    80002f0a:	638080e7          	jalr	1592(ra) # 8000053e <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002f0e:	fffff097          	auipc	ra,0xfffff
    80002f12:	aba080e7          	jalr	-1350(ra) # 800019c8 <myproc>
    80002f16:	d541                	beqz	a0,80002e9e <kerneltrap+0x38>
    80002f18:	fffff097          	auipc	ra,0xfffff
    80002f1c:	ab0080e7          	jalr	-1360(ra) # 800019c8 <myproc>
    80002f20:	4d18                	lw	a4,24(a0)
    80002f22:	4791                	li	a5,4
    80002f24:	f6f71de3          	bne	a4,a5,80002e9e <kerneltrap+0x38>
    yield();
    80002f28:	fffff097          	auipc	ra,0xfffff
    80002f2c:	4a6080e7          	jalr	1190(ra) # 800023ce <yield>
    80002f30:	b7bd                	j	80002e9e <kerneltrap+0x38>

0000000080002f32 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002f32:	1101                	addi	sp,sp,-32
    80002f34:	ec06                	sd	ra,24(sp)
    80002f36:	e822                	sd	s0,16(sp)
    80002f38:	e426                	sd	s1,8(sp)
    80002f3a:	1000                	addi	s0,sp,32
    80002f3c:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002f3e:	fffff097          	auipc	ra,0xfffff
    80002f42:	a8a080e7          	jalr	-1398(ra) # 800019c8 <myproc>
  switch (n) {
    80002f46:	4795                	li	a5,5
    80002f48:	0497e163          	bltu	a5,s1,80002f8a <argraw+0x58>
    80002f4c:	048a                	slli	s1,s1,0x2
    80002f4e:	00005717          	auipc	a4,0x5
    80002f52:	4ea70713          	addi	a4,a4,1258 # 80008438 <states.1780+0x170>
    80002f56:	94ba                	add	s1,s1,a4
    80002f58:	409c                	lw	a5,0(s1)
    80002f5a:	97ba                	add	a5,a5,a4
    80002f5c:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002f5e:	7d3c                	ld	a5,120(a0)
    80002f60:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002f62:	60e2                	ld	ra,24(sp)
    80002f64:	6442                	ld	s0,16(sp)
    80002f66:	64a2                	ld	s1,8(sp)
    80002f68:	6105                	addi	sp,sp,32
    80002f6a:	8082                	ret
    return p->trapframe->a1;
    80002f6c:	7d3c                	ld	a5,120(a0)
    80002f6e:	7fa8                	ld	a0,120(a5)
    80002f70:	bfcd                	j	80002f62 <argraw+0x30>
    return p->trapframe->a2;
    80002f72:	7d3c                	ld	a5,120(a0)
    80002f74:	63c8                	ld	a0,128(a5)
    80002f76:	b7f5                	j	80002f62 <argraw+0x30>
    return p->trapframe->a3;
    80002f78:	7d3c                	ld	a5,120(a0)
    80002f7a:	67c8                	ld	a0,136(a5)
    80002f7c:	b7dd                	j	80002f62 <argraw+0x30>
    return p->trapframe->a4;
    80002f7e:	7d3c                	ld	a5,120(a0)
    80002f80:	6bc8                	ld	a0,144(a5)
    80002f82:	b7c5                	j	80002f62 <argraw+0x30>
    return p->trapframe->a5;
    80002f84:	7d3c                	ld	a5,120(a0)
    80002f86:	6fc8                	ld	a0,152(a5)
    80002f88:	bfe9                	j	80002f62 <argraw+0x30>
  panic("argraw");
    80002f8a:	00005517          	auipc	a0,0x5
    80002f8e:	48650513          	addi	a0,a0,1158 # 80008410 <states.1780+0x148>
    80002f92:	ffffd097          	auipc	ra,0xffffd
    80002f96:	5ac080e7          	jalr	1452(ra) # 8000053e <panic>

0000000080002f9a <fetchaddr>:
{
    80002f9a:	1101                	addi	sp,sp,-32
    80002f9c:	ec06                	sd	ra,24(sp)
    80002f9e:	e822                	sd	s0,16(sp)
    80002fa0:	e426                	sd	s1,8(sp)
    80002fa2:	e04a                	sd	s2,0(sp)
    80002fa4:	1000                	addi	s0,sp,32
    80002fa6:	84aa                	mv	s1,a0
    80002fa8:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002faa:	fffff097          	auipc	ra,0xfffff
    80002fae:	a1e080e7          	jalr	-1506(ra) # 800019c8 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    80002fb2:	753c                	ld	a5,104(a0)
    80002fb4:	02f4f863          	bgeu	s1,a5,80002fe4 <fetchaddr+0x4a>
    80002fb8:	00848713          	addi	a4,s1,8
    80002fbc:	02e7e663          	bltu	a5,a4,80002fe8 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002fc0:	46a1                	li	a3,8
    80002fc2:	8626                	mv	a2,s1
    80002fc4:	85ca                	mv	a1,s2
    80002fc6:	7928                	ld	a0,112(a0)
    80002fc8:	ffffe097          	auipc	ra,0xffffe
    80002fcc:	73e080e7          	jalr	1854(ra) # 80001706 <copyin>
    80002fd0:	00a03533          	snez	a0,a0
    80002fd4:	40a00533          	neg	a0,a0
}
    80002fd8:	60e2                	ld	ra,24(sp)
    80002fda:	6442                	ld	s0,16(sp)
    80002fdc:	64a2                	ld	s1,8(sp)
    80002fde:	6902                	ld	s2,0(sp)
    80002fe0:	6105                	addi	sp,sp,32
    80002fe2:	8082                	ret
    return -1;
    80002fe4:	557d                	li	a0,-1
    80002fe6:	bfcd                	j	80002fd8 <fetchaddr+0x3e>
    80002fe8:	557d                	li	a0,-1
    80002fea:	b7fd                	j	80002fd8 <fetchaddr+0x3e>

0000000080002fec <fetchstr>:
{
    80002fec:	7179                	addi	sp,sp,-48
    80002fee:	f406                	sd	ra,40(sp)
    80002ff0:	f022                	sd	s0,32(sp)
    80002ff2:	ec26                	sd	s1,24(sp)
    80002ff4:	e84a                	sd	s2,16(sp)
    80002ff6:	e44e                	sd	s3,8(sp)
    80002ff8:	1800                	addi	s0,sp,48
    80002ffa:	892a                	mv	s2,a0
    80002ffc:	84ae                	mv	s1,a1
    80002ffe:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80003000:	fffff097          	auipc	ra,0xfffff
    80003004:	9c8080e7          	jalr	-1592(ra) # 800019c8 <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80003008:	86ce                	mv	a3,s3
    8000300a:	864a                	mv	a2,s2
    8000300c:	85a6                	mv	a1,s1
    8000300e:	7928                	ld	a0,112(a0)
    80003010:	ffffe097          	auipc	ra,0xffffe
    80003014:	782080e7          	jalr	1922(ra) # 80001792 <copyinstr>
  if(err < 0)
    80003018:	00054763          	bltz	a0,80003026 <fetchstr+0x3a>
  return strlen(buf);
    8000301c:	8526                	mv	a0,s1
    8000301e:	ffffe097          	auipc	ra,0xffffe
    80003022:	e46080e7          	jalr	-442(ra) # 80000e64 <strlen>
}
    80003026:	70a2                	ld	ra,40(sp)
    80003028:	7402                	ld	s0,32(sp)
    8000302a:	64e2                	ld	s1,24(sp)
    8000302c:	6942                	ld	s2,16(sp)
    8000302e:	69a2                	ld	s3,8(sp)
    80003030:	6145                	addi	sp,sp,48
    80003032:	8082                	ret

0000000080003034 <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80003034:	1101                	addi	sp,sp,-32
    80003036:	ec06                	sd	ra,24(sp)
    80003038:	e822                	sd	s0,16(sp)
    8000303a:	e426                	sd	s1,8(sp)
    8000303c:	1000                	addi	s0,sp,32
    8000303e:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80003040:	00000097          	auipc	ra,0x0
    80003044:	ef2080e7          	jalr	-270(ra) # 80002f32 <argraw>
    80003048:	c088                	sw	a0,0(s1)
  return 0;
}
    8000304a:	4501                	li	a0,0
    8000304c:	60e2                	ld	ra,24(sp)
    8000304e:	6442                	ld	s0,16(sp)
    80003050:	64a2                	ld	s1,8(sp)
    80003052:	6105                	addi	sp,sp,32
    80003054:	8082                	ret

0000000080003056 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80003056:	1101                	addi	sp,sp,-32
    80003058:	ec06                	sd	ra,24(sp)
    8000305a:	e822                	sd	s0,16(sp)
    8000305c:	e426                	sd	s1,8(sp)
    8000305e:	1000                	addi	s0,sp,32
    80003060:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80003062:	00000097          	auipc	ra,0x0
    80003066:	ed0080e7          	jalr	-304(ra) # 80002f32 <argraw>
    8000306a:	e088                	sd	a0,0(s1)
  return 0;
}
    8000306c:	4501                	li	a0,0
    8000306e:	60e2                	ld	ra,24(sp)
    80003070:	6442                	ld	s0,16(sp)
    80003072:	64a2                	ld	s1,8(sp)
    80003074:	6105                	addi	sp,sp,32
    80003076:	8082                	ret

0000000080003078 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80003078:	1101                	addi	sp,sp,-32
    8000307a:	ec06                	sd	ra,24(sp)
    8000307c:	e822                	sd	s0,16(sp)
    8000307e:	e426                	sd	s1,8(sp)
    80003080:	e04a                	sd	s2,0(sp)
    80003082:	1000                	addi	s0,sp,32
    80003084:	84ae                	mv	s1,a1
    80003086:	8932                	mv	s2,a2
  *ip = argraw(n);
    80003088:	00000097          	auipc	ra,0x0
    8000308c:	eaa080e7          	jalr	-342(ra) # 80002f32 <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80003090:	864a                	mv	a2,s2
    80003092:	85a6                	mv	a1,s1
    80003094:	00000097          	auipc	ra,0x0
    80003098:	f58080e7          	jalr	-168(ra) # 80002fec <fetchstr>
}
    8000309c:	60e2                	ld	ra,24(sp)
    8000309e:	6442                	ld	s0,16(sp)
    800030a0:	64a2                	ld	s1,8(sp)
    800030a2:	6902                	ld	s2,0(sp)
    800030a4:	6105                	addi	sp,sp,32
    800030a6:	8082                	ret

00000000800030a8 <syscall>:
[SYS_kill_system] sys_kill_system,
};

void
syscall(void)
{
    800030a8:	1101                	addi	sp,sp,-32
    800030aa:	ec06                	sd	ra,24(sp)
    800030ac:	e822                	sd	s0,16(sp)
    800030ae:	e426                	sd	s1,8(sp)
    800030b0:	e04a                	sd	s2,0(sp)
    800030b2:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    800030b4:	fffff097          	auipc	ra,0xfffff
    800030b8:	914080e7          	jalr	-1772(ra) # 800019c8 <myproc>
    800030bc:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    800030be:	07853903          	ld	s2,120(a0)
    800030c2:	0a893783          	ld	a5,168(s2)
    800030c6:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    800030ca:	37fd                	addiw	a5,a5,-1
    800030cc:	4759                	li	a4,22
    800030ce:	00f76f63          	bltu	a4,a5,800030ec <syscall+0x44>
    800030d2:	00369713          	slli	a4,a3,0x3
    800030d6:	00005797          	auipc	a5,0x5
    800030da:	37a78793          	addi	a5,a5,890 # 80008450 <syscalls>
    800030de:	97ba                	add	a5,a5,a4
    800030e0:	639c                	ld	a5,0(a5)
    800030e2:	c789                	beqz	a5,800030ec <syscall+0x44>
    p->trapframe->a0 = syscalls[num]();
    800030e4:	9782                	jalr	a5
    800030e6:	06a93823          	sd	a0,112(s2)
    800030ea:	a839                	j	80003108 <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    800030ec:	17848613          	addi	a2,s1,376
    800030f0:	588c                	lw	a1,48(s1)
    800030f2:	00005517          	auipc	a0,0x5
    800030f6:	32650513          	addi	a0,a0,806 # 80008418 <states.1780+0x150>
    800030fa:	ffffd097          	auipc	ra,0xffffd
    800030fe:	48e080e7          	jalr	1166(ra) # 80000588 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80003102:	7cbc                	ld	a5,120(s1)
    80003104:	577d                	li	a4,-1
    80003106:	fbb8                	sd	a4,112(a5)
  }
}
    80003108:	60e2                	ld	ra,24(sp)
    8000310a:	6442                	ld	s0,16(sp)
    8000310c:	64a2                	ld	s1,8(sp)
    8000310e:	6902                	ld	s2,0(sp)
    80003110:	6105                	addi	sp,sp,32
    80003112:	8082                	ret

0000000080003114 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80003114:	1101                	addi	sp,sp,-32
    80003116:	ec06                	sd	ra,24(sp)
    80003118:	e822                	sd	s0,16(sp)
    8000311a:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    8000311c:	fec40593          	addi	a1,s0,-20
    80003120:	4501                	li	a0,0
    80003122:	00000097          	auipc	ra,0x0
    80003126:	f12080e7          	jalr	-238(ra) # 80003034 <argint>
    return -1;
    8000312a:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    8000312c:	00054963          	bltz	a0,8000313e <sys_exit+0x2a>
  exit(n);
    80003130:	fec42503          	lw	a0,-20(s0)
    80003134:	fffff097          	auipc	ra,0xfffff
    80003138:	5de080e7          	jalr	1502(ra) # 80002712 <exit>
  return 0;  // not reached
    8000313c:	4781                	li	a5,0
}
    8000313e:	853e                	mv	a0,a5
    80003140:	60e2                	ld	ra,24(sp)
    80003142:	6442                	ld	s0,16(sp)
    80003144:	6105                	addi	sp,sp,32
    80003146:	8082                	ret

0000000080003148 <sys_getpid>:

uint64
sys_getpid(void)
{
    80003148:	1141                	addi	sp,sp,-16
    8000314a:	e406                	sd	ra,8(sp)
    8000314c:	e022                	sd	s0,0(sp)
    8000314e:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80003150:	fffff097          	auipc	ra,0xfffff
    80003154:	878080e7          	jalr	-1928(ra) # 800019c8 <myproc>
}
    80003158:	5908                	lw	a0,48(a0)
    8000315a:	60a2                	ld	ra,8(sp)
    8000315c:	6402                	ld	s0,0(sp)
    8000315e:	0141                	addi	sp,sp,16
    80003160:	8082                	ret

0000000080003162 <sys_fork>:

uint64
sys_fork(void)
{
    80003162:	1141                	addi	sp,sp,-16
    80003164:	e406                	sd	ra,8(sp)
    80003166:	e022                	sd	s0,0(sp)
    80003168:	0800                	addi	s0,sp,16
  return fork();
    8000316a:	fffff097          	auipc	ra,0xfffff
    8000316e:	c7a080e7          	jalr	-902(ra) # 80001de4 <fork>
}
    80003172:	60a2                	ld	ra,8(sp)
    80003174:	6402                	ld	s0,0(sp)
    80003176:	0141                	addi	sp,sp,16
    80003178:	8082                	ret

000000008000317a <sys_wait>:

uint64
sys_wait(void)
{
    8000317a:	1101                	addi	sp,sp,-32
    8000317c:	ec06                	sd	ra,24(sp)
    8000317e:	e822                	sd	s0,16(sp)
    80003180:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80003182:	fe840593          	addi	a1,s0,-24
    80003186:	4501                	li	a0,0
    80003188:	00000097          	auipc	ra,0x0
    8000318c:	ece080e7          	jalr	-306(ra) # 80003056 <argaddr>
    80003190:	87aa                	mv	a5,a0
    return -1;
    80003192:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80003194:	0007c863          	bltz	a5,800031a4 <sys_wait+0x2a>
  return wait(p);
    80003198:	fe843503          	ld	a0,-24(s0)
    8000319c:	fffff097          	auipc	ra,0xfffff
    800031a0:	33e080e7          	jalr	830(ra) # 800024da <wait>
}
    800031a4:	60e2                	ld	ra,24(sp)
    800031a6:	6442                	ld	s0,16(sp)
    800031a8:	6105                	addi	sp,sp,32
    800031aa:	8082                	ret

00000000800031ac <sys_sbrk>:

uint64
sys_sbrk(void)
{
    800031ac:	7179                	addi	sp,sp,-48
    800031ae:	f406                	sd	ra,40(sp)
    800031b0:	f022                	sd	s0,32(sp)
    800031b2:	ec26                	sd	s1,24(sp)
    800031b4:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    800031b6:	fdc40593          	addi	a1,s0,-36
    800031ba:	4501                	li	a0,0
    800031bc:	00000097          	auipc	ra,0x0
    800031c0:	e78080e7          	jalr	-392(ra) # 80003034 <argint>
    800031c4:	87aa                	mv	a5,a0
    return -1;
    800031c6:	557d                	li	a0,-1
  if(argint(0, &n) < 0)
    800031c8:	0207c063          	bltz	a5,800031e8 <sys_sbrk+0x3c>
  addr = myproc()->sz;
    800031cc:	ffffe097          	auipc	ra,0xffffe
    800031d0:	7fc080e7          	jalr	2044(ra) # 800019c8 <myproc>
    800031d4:	5524                	lw	s1,104(a0)
  if(growproc(n) < 0)
    800031d6:	fdc42503          	lw	a0,-36(s0)
    800031da:	fffff097          	auipc	ra,0xfffff
    800031de:	b96080e7          	jalr	-1130(ra) # 80001d70 <growproc>
    800031e2:	00054863          	bltz	a0,800031f2 <sys_sbrk+0x46>
    return -1;
  return addr;
    800031e6:	8526                	mv	a0,s1
}
    800031e8:	70a2                	ld	ra,40(sp)
    800031ea:	7402                	ld	s0,32(sp)
    800031ec:	64e2                	ld	s1,24(sp)
    800031ee:	6145                	addi	sp,sp,48
    800031f0:	8082                	ret
    return -1;
    800031f2:	557d                	li	a0,-1
    800031f4:	bfd5                	j	800031e8 <sys_sbrk+0x3c>

00000000800031f6 <sys_sleep>:

uint64
sys_sleep(void)
{
    800031f6:	7139                	addi	sp,sp,-64
    800031f8:	fc06                	sd	ra,56(sp)
    800031fa:	f822                	sd	s0,48(sp)
    800031fc:	f426                	sd	s1,40(sp)
    800031fe:	f04a                	sd	s2,32(sp)
    80003200:	ec4e                	sd	s3,24(sp)
    80003202:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    80003204:	fcc40593          	addi	a1,s0,-52
    80003208:	4501                	li	a0,0
    8000320a:	00000097          	auipc	ra,0x0
    8000320e:	e2a080e7          	jalr	-470(ra) # 80003034 <argint>
    return -1;
    80003212:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80003214:	06054563          	bltz	a0,8000327e <sys_sleep+0x88>
  acquire(&tickslock);
    80003218:	00014517          	auipc	a0,0x14
    8000321c:	6d850513          	addi	a0,a0,1752 # 800178f0 <tickslock>
    80003220:	ffffe097          	auipc	ra,0xffffe
    80003224:	9c4080e7          	jalr	-1596(ra) # 80000be4 <acquire>
  ticks0 = ticks;
    80003228:	00006917          	auipc	s2,0x6
    8000322c:	e2892903          	lw	s2,-472(s2) # 80009050 <ticks>
  while(ticks - ticks0 < n){
    80003230:	fcc42783          	lw	a5,-52(s0)
    80003234:	cf85                	beqz	a5,8000326c <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80003236:	00014997          	auipc	s3,0x14
    8000323a:	6ba98993          	addi	s3,s3,1722 # 800178f0 <tickslock>
    8000323e:	00006497          	auipc	s1,0x6
    80003242:	e1248493          	addi	s1,s1,-494 # 80009050 <ticks>
    if(myproc()->killed){
    80003246:	ffffe097          	auipc	ra,0xffffe
    8000324a:	782080e7          	jalr	1922(ra) # 800019c8 <myproc>
    8000324e:	551c                	lw	a5,40(a0)
    80003250:	ef9d                	bnez	a5,8000328e <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    80003252:	85ce                	mv	a1,s3
    80003254:	8526                	mv	a0,s1
    80003256:	fffff097          	auipc	ra,0xfffff
    8000325a:	1ec080e7          	jalr	492(ra) # 80002442 <sleep>
  while(ticks - ticks0 < n){
    8000325e:	409c                	lw	a5,0(s1)
    80003260:	412787bb          	subw	a5,a5,s2
    80003264:	fcc42703          	lw	a4,-52(s0)
    80003268:	fce7efe3          	bltu	a5,a4,80003246 <sys_sleep+0x50>
  }
  release(&tickslock);
    8000326c:	00014517          	auipc	a0,0x14
    80003270:	68450513          	addi	a0,a0,1668 # 800178f0 <tickslock>
    80003274:	ffffe097          	auipc	ra,0xffffe
    80003278:	a24080e7          	jalr	-1500(ra) # 80000c98 <release>
  return 0;
    8000327c:	4781                	li	a5,0
}
    8000327e:	853e                	mv	a0,a5
    80003280:	70e2                	ld	ra,56(sp)
    80003282:	7442                	ld	s0,48(sp)
    80003284:	74a2                	ld	s1,40(sp)
    80003286:	7902                	ld	s2,32(sp)
    80003288:	69e2                	ld	s3,24(sp)
    8000328a:	6121                	addi	sp,sp,64
    8000328c:	8082                	ret
      release(&tickslock);
    8000328e:	00014517          	auipc	a0,0x14
    80003292:	66250513          	addi	a0,a0,1634 # 800178f0 <tickslock>
    80003296:	ffffe097          	auipc	ra,0xffffe
    8000329a:	a02080e7          	jalr	-1534(ra) # 80000c98 <release>
      return -1;
    8000329e:	57fd                	li	a5,-1
    800032a0:	bff9                	j	8000327e <sys_sleep+0x88>

00000000800032a2 <sys_kill>:

uint64
sys_kill(void)
{
    800032a2:	1101                	addi	sp,sp,-32
    800032a4:	ec06                	sd	ra,24(sp)
    800032a6:	e822                	sd	s0,16(sp)
    800032a8:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    800032aa:	fec40593          	addi	a1,s0,-20
    800032ae:	4501                	li	a0,0
    800032b0:	00000097          	auipc	ra,0x0
    800032b4:	d84080e7          	jalr	-636(ra) # 80003034 <argint>
    800032b8:	87aa                	mv	a5,a0
    return -1;
    800032ba:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    800032bc:	0007c863          	bltz	a5,800032cc <sys_kill+0x2a>
  return kill(pid);
    800032c0:	fec42503          	lw	a0,-20(s0)
    800032c4:	fffff097          	auipc	ra,0xfffff
    800032c8:	5d8080e7          	jalr	1496(ra) # 8000289c <kill>
}
    800032cc:	60e2                	ld	ra,24(sp)
    800032ce:	6442                	ld	s0,16(sp)
    800032d0:	6105                	addi	sp,sp,32
    800032d2:	8082                	ret

00000000800032d4 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    800032d4:	1101                	addi	sp,sp,-32
    800032d6:	ec06                	sd	ra,24(sp)
    800032d8:	e822                	sd	s0,16(sp)
    800032da:	e426                	sd	s1,8(sp)
    800032dc:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    800032de:	00014517          	auipc	a0,0x14
    800032e2:	61250513          	addi	a0,a0,1554 # 800178f0 <tickslock>
    800032e6:	ffffe097          	auipc	ra,0xffffe
    800032ea:	8fe080e7          	jalr	-1794(ra) # 80000be4 <acquire>
  xticks = ticks;
    800032ee:	00006497          	auipc	s1,0x6
    800032f2:	d624a483          	lw	s1,-670(s1) # 80009050 <ticks>
  release(&tickslock);
    800032f6:	00014517          	auipc	a0,0x14
    800032fa:	5fa50513          	addi	a0,a0,1530 # 800178f0 <tickslock>
    800032fe:	ffffe097          	auipc	ra,0xffffe
    80003302:	99a080e7          	jalr	-1638(ra) # 80000c98 <release>
  return xticks;
}
    80003306:	02049513          	slli	a0,s1,0x20
    8000330a:	9101                	srli	a0,a0,0x20
    8000330c:	60e2                	ld	ra,24(sp)
    8000330e:	6442                	ld	s0,16(sp)
    80003310:	64a2                	ld	s1,8(sp)
    80003312:	6105                	addi	sp,sp,32
    80003314:	8082                	ret

0000000080003316 <sys_pause_system>:

uint64 sys_pause_system(void){
    80003316:	1101                	addi	sp,sp,-32
    80003318:	ec06                	sd	ra,24(sp)
    8000331a:	e822                	sd	s0,16(sp)
    8000331c:	1000                	addi	s0,sp,32
    int seconds;

    if(argint(0, &seconds) < 0)
    8000331e:	fec40593          	addi	a1,s0,-20
    80003322:	4501                	li	a0,0
    80003324:	00000097          	auipc	ra,0x0
    80003328:	d10080e7          	jalr	-752(ra) # 80003034 <argint>
        return -1;
    8000332c:	57fd                	li	a5,-1
    if(argint(0, &seconds) < 0)
    8000332e:	00054963          	bltz	a0,80003340 <sys_pause_system+0x2a>
    pause_system(seconds);
    80003332:	fec42503          	lw	a0,-20(s0)
    80003336:	fffff097          	auipc	ra,0xfffff
    8000333a:	67c080e7          	jalr	1660(ra) # 800029b2 <pause_system>
    return 0;
    8000333e:	4781                	li	a5,0
}
    80003340:	853e                	mv	a0,a5
    80003342:	60e2                	ld	ra,24(sp)
    80003344:	6442                	ld	s0,16(sp)
    80003346:	6105                	addi	sp,sp,32
    80003348:	8082                	ret

000000008000334a <sys_kill_system>:

uint64 sys_kill_system(void){
    8000334a:	1141                	addi	sp,sp,-16
    8000334c:	e406                	sd	ra,8(sp)
    8000334e:	e022                	sd	s0,0(sp)
    80003350:	0800                	addi	s0,sp,16
    kill_system();
    80003352:	fffff097          	auipc	ra,0xfffff
    80003356:	5f4080e7          	jalr	1524(ra) # 80002946 <kill_system>
    return 0;
}
    8000335a:	4501                	li	a0,0
    8000335c:	60a2                	ld	ra,8(sp)
    8000335e:	6402                	ld	s0,0(sp)
    80003360:	0141                	addi	sp,sp,16
    80003362:	8082                	ret

0000000080003364 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80003364:	7179                	addi	sp,sp,-48
    80003366:	f406                	sd	ra,40(sp)
    80003368:	f022                	sd	s0,32(sp)
    8000336a:	ec26                	sd	s1,24(sp)
    8000336c:	e84a                	sd	s2,16(sp)
    8000336e:	e44e                	sd	s3,8(sp)
    80003370:	e052                	sd	s4,0(sp)
    80003372:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80003374:	00005597          	auipc	a1,0x5
    80003378:	19c58593          	addi	a1,a1,412 # 80008510 <syscalls+0xc0>
    8000337c:	00014517          	auipc	a0,0x14
    80003380:	58c50513          	addi	a0,a0,1420 # 80017908 <bcache>
    80003384:	ffffd097          	auipc	ra,0xffffd
    80003388:	7d0080e7          	jalr	2000(ra) # 80000b54 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    8000338c:	0001c797          	auipc	a5,0x1c
    80003390:	57c78793          	addi	a5,a5,1404 # 8001f908 <bcache+0x8000>
    80003394:	0001c717          	auipc	a4,0x1c
    80003398:	7dc70713          	addi	a4,a4,2012 # 8001fb70 <bcache+0x8268>
    8000339c:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    800033a0:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    800033a4:	00014497          	auipc	s1,0x14
    800033a8:	57c48493          	addi	s1,s1,1404 # 80017920 <bcache+0x18>
    b->next = bcache.head.next;
    800033ac:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    800033ae:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    800033b0:	00005a17          	auipc	s4,0x5
    800033b4:	168a0a13          	addi	s4,s4,360 # 80008518 <syscalls+0xc8>
    b->next = bcache.head.next;
    800033b8:	2b893783          	ld	a5,696(s2)
    800033bc:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    800033be:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    800033c2:	85d2                	mv	a1,s4
    800033c4:	01048513          	addi	a0,s1,16
    800033c8:	00001097          	auipc	ra,0x1
    800033cc:	4bc080e7          	jalr	1212(ra) # 80004884 <initsleeplock>
    bcache.head.next->prev = b;
    800033d0:	2b893783          	ld	a5,696(s2)
    800033d4:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    800033d6:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    800033da:	45848493          	addi	s1,s1,1112
    800033de:	fd349de3          	bne	s1,s3,800033b8 <binit+0x54>
  }
}
    800033e2:	70a2                	ld	ra,40(sp)
    800033e4:	7402                	ld	s0,32(sp)
    800033e6:	64e2                	ld	s1,24(sp)
    800033e8:	6942                	ld	s2,16(sp)
    800033ea:	69a2                	ld	s3,8(sp)
    800033ec:	6a02                	ld	s4,0(sp)
    800033ee:	6145                	addi	sp,sp,48
    800033f0:	8082                	ret

00000000800033f2 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    800033f2:	7179                	addi	sp,sp,-48
    800033f4:	f406                	sd	ra,40(sp)
    800033f6:	f022                	sd	s0,32(sp)
    800033f8:	ec26                	sd	s1,24(sp)
    800033fa:	e84a                	sd	s2,16(sp)
    800033fc:	e44e                	sd	s3,8(sp)
    800033fe:	1800                	addi	s0,sp,48
    80003400:	89aa                	mv	s3,a0
    80003402:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    80003404:	00014517          	auipc	a0,0x14
    80003408:	50450513          	addi	a0,a0,1284 # 80017908 <bcache>
    8000340c:	ffffd097          	auipc	ra,0xffffd
    80003410:	7d8080e7          	jalr	2008(ra) # 80000be4 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80003414:	0001c497          	auipc	s1,0x1c
    80003418:	7ac4b483          	ld	s1,1964(s1) # 8001fbc0 <bcache+0x82b8>
    8000341c:	0001c797          	auipc	a5,0x1c
    80003420:	75478793          	addi	a5,a5,1876 # 8001fb70 <bcache+0x8268>
    80003424:	02f48f63          	beq	s1,a5,80003462 <bread+0x70>
    80003428:	873e                	mv	a4,a5
    8000342a:	a021                	j	80003432 <bread+0x40>
    8000342c:	68a4                	ld	s1,80(s1)
    8000342e:	02e48a63          	beq	s1,a4,80003462 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80003432:	449c                	lw	a5,8(s1)
    80003434:	ff379ce3          	bne	a5,s3,8000342c <bread+0x3a>
    80003438:	44dc                	lw	a5,12(s1)
    8000343a:	ff2799e3          	bne	a5,s2,8000342c <bread+0x3a>
      b->refcnt++;
    8000343e:	40bc                	lw	a5,64(s1)
    80003440:	2785                	addiw	a5,a5,1
    80003442:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003444:	00014517          	auipc	a0,0x14
    80003448:	4c450513          	addi	a0,a0,1220 # 80017908 <bcache>
    8000344c:	ffffe097          	auipc	ra,0xffffe
    80003450:	84c080e7          	jalr	-1972(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    80003454:	01048513          	addi	a0,s1,16
    80003458:	00001097          	auipc	ra,0x1
    8000345c:	466080e7          	jalr	1126(ra) # 800048be <acquiresleep>
      return b;
    80003460:	a8b9                	j	800034be <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003462:	0001c497          	auipc	s1,0x1c
    80003466:	7564b483          	ld	s1,1878(s1) # 8001fbb8 <bcache+0x82b0>
    8000346a:	0001c797          	auipc	a5,0x1c
    8000346e:	70678793          	addi	a5,a5,1798 # 8001fb70 <bcache+0x8268>
    80003472:	00f48863          	beq	s1,a5,80003482 <bread+0x90>
    80003476:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80003478:	40bc                	lw	a5,64(s1)
    8000347a:	cf81                	beqz	a5,80003492 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    8000347c:	64a4                	ld	s1,72(s1)
    8000347e:	fee49de3          	bne	s1,a4,80003478 <bread+0x86>
  panic("bget: no buffers");
    80003482:	00005517          	auipc	a0,0x5
    80003486:	09e50513          	addi	a0,a0,158 # 80008520 <syscalls+0xd0>
    8000348a:	ffffd097          	auipc	ra,0xffffd
    8000348e:	0b4080e7          	jalr	180(ra) # 8000053e <panic>
      b->dev = dev;
    80003492:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    80003496:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    8000349a:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    8000349e:	4785                	li	a5,1
    800034a0:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800034a2:	00014517          	auipc	a0,0x14
    800034a6:	46650513          	addi	a0,a0,1126 # 80017908 <bcache>
    800034aa:	ffffd097          	auipc	ra,0xffffd
    800034ae:	7ee080e7          	jalr	2030(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    800034b2:	01048513          	addi	a0,s1,16
    800034b6:	00001097          	auipc	ra,0x1
    800034ba:	408080e7          	jalr	1032(ra) # 800048be <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    800034be:	409c                	lw	a5,0(s1)
    800034c0:	cb89                	beqz	a5,800034d2 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    800034c2:	8526                	mv	a0,s1
    800034c4:	70a2                	ld	ra,40(sp)
    800034c6:	7402                	ld	s0,32(sp)
    800034c8:	64e2                	ld	s1,24(sp)
    800034ca:	6942                	ld	s2,16(sp)
    800034cc:	69a2                	ld	s3,8(sp)
    800034ce:	6145                	addi	sp,sp,48
    800034d0:	8082                	ret
    virtio_disk_rw(b, 0);
    800034d2:	4581                	li	a1,0
    800034d4:	8526                	mv	a0,s1
    800034d6:	00003097          	auipc	ra,0x3
    800034da:	f10080e7          	jalr	-240(ra) # 800063e6 <virtio_disk_rw>
    b->valid = 1;
    800034de:	4785                	li	a5,1
    800034e0:	c09c                	sw	a5,0(s1)
  return b;
    800034e2:	b7c5                	j	800034c2 <bread+0xd0>

00000000800034e4 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    800034e4:	1101                	addi	sp,sp,-32
    800034e6:	ec06                	sd	ra,24(sp)
    800034e8:	e822                	sd	s0,16(sp)
    800034ea:	e426                	sd	s1,8(sp)
    800034ec:	1000                	addi	s0,sp,32
    800034ee:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800034f0:	0541                	addi	a0,a0,16
    800034f2:	00001097          	auipc	ra,0x1
    800034f6:	466080e7          	jalr	1126(ra) # 80004958 <holdingsleep>
    800034fa:	cd01                	beqz	a0,80003512 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    800034fc:	4585                	li	a1,1
    800034fe:	8526                	mv	a0,s1
    80003500:	00003097          	auipc	ra,0x3
    80003504:	ee6080e7          	jalr	-282(ra) # 800063e6 <virtio_disk_rw>
}
    80003508:	60e2                	ld	ra,24(sp)
    8000350a:	6442                	ld	s0,16(sp)
    8000350c:	64a2                	ld	s1,8(sp)
    8000350e:	6105                	addi	sp,sp,32
    80003510:	8082                	ret
    panic("bwrite");
    80003512:	00005517          	auipc	a0,0x5
    80003516:	02650513          	addi	a0,a0,38 # 80008538 <syscalls+0xe8>
    8000351a:	ffffd097          	auipc	ra,0xffffd
    8000351e:	024080e7          	jalr	36(ra) # 8000053e <panic>

0000000080003522 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80003522:	1101                	addi	sp,sp,-32
    80003524:	ec06                	sd	ra,24(sp)
    80003526:	e822                	sd	s0,16(sp)
    80003528:	e426                	sd	s1,8(sp)
    8000352a:	e04a                	sd	s2,0(sp)
    8000352c:	1000                	addi	s0,sp,32
    8000352e:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003530:	01050913          	addi	s2,a0,16
    80003534:	854a                	mv	a0,s2
    80003536:	00001097          	auipc	ra,0x1
    8000353a:	422080e7          	jalr	1058(ra) # 80004958 <holdingsleep>
    8000353e:	c92d                	beqz	a0,800035b0 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    80003540:	854a                	mv	a0,s2
    80003542:	00001097          	auipc	ra,0x1
    80003546:	3d2080e7          	jalr	978(ra) # 80004914 <releasesleep>

  acquire(&bcache.lock);
    8000354a:	00014517          	auipc	a0,0x14
    8000354e:	3be50513          	addi	a0,a0,958 # 80017908 <bcache>
    80003552:	ffffd097          	auipc	ra,0xffffd
    80003556:	692080e7          	jalr	1682(ra) # 80000be4 <acquire>
  b->refcnt--;
    8000355a:	40bc                	lw	a5,64(s1)
    8000355c:	37fd                	addiw	a5,a5,-1
    8000355e:	0007871b          	sext.w	a4,a5
    80003562:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80003564:	eb05                	bnez	a4,80003594 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80003566:	68bc                	ld	a5,80(s1)
    80003568:	64b8                	ld	a4,72(s1)
    8000356a:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    8000356c:	64bc                	ld	a5,72(s1)
    8000356e:	68b8                	ld	a4,80(s1)
    80003570:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80003572:	0001c797          	auipc	a5,0x1c
    80003576:	39678793          	addi	a5,a5,918 # 8001f908 <bcache+0x8000>
    8000357a:	2b87b703          	ld	a4,696(a5)
    8000357e:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80003580:	0001c717          	auipc	a4,0x1c
    80003584:	5f070713          	addi	a4,a4,1520 # 8001fb70 <bcache+0x8268>
    80003588:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    8000358a:	2b87b703          	ld	a4,696(a5)
    8000358e:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80003590:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    80003594:	00014517          	auipc	a0,0x14
    80003598:	37450513          	addi	a0,a0,884 # 80017908 <bcache>
    8000359c:	ffffd097          	auipc	ra,0xffffd
    800035a0:	6fc080e7          	jalr	1788(ra) # 80000c98 <release>
}
    800035a4:	60e2                	ld	ra,24(sp)
    800035a6:	6442                	ld	s0,16(sp)
    800035a8:	64a2                	ld	s1,8(sp)
    800035aa:	6902                	ld	s2,0(sp)
    800035ac:	6105                	addi	sp,sp,32
    800035ae:	8082                	ret
    panic("brelse");
    800035b0:	00005517          	auipc	a0,0x5
    800035b4:	f9050513          	addi	a0,a0,-112 # 80008540 <syscalls+0xf0>
    800035b8:	ffffd097          	auipc	ra,0xffffd
    800035bc:	f86080e7          	jalr	-122(ra) # 8000053e <panic>

00000000800035c0 <bpin>:

void
bpin(struct buf *b) {
    800035c0:	1101                	addi	sp,sp,-32
    800035c2:	ec06                	sd	ra,24(sp)
    800035c4:	e822                	sd	s0,16(sp)
    800035c6:	e426                	sd	s1,8(sp)
    800035c8:	1000                	addi	s0,sp,32
    800035ca:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800035cc:	00014517          	auipc	a0,0x14
    800035d0:	33c50513          	addi	a0,a0,828 # 80017908 <bcache>
    800035d4:	ffffd097          	auipc	ra,0xffffd
    800035d8:	610080e7          	jalr	1552(ra) # 80000be4 <acquire>
  b->refcnt++;
    800035dc:	40bc                	lw	a5,64(s1)
    800035de:	2785                	addiw	a5,a5,1
    800035e0:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800035e2:	00014517          	auipc	a0,0x14
    800035e6:	32650513          	addi	a0,a0,806 # 80017908 <bcache>
    800035ea:	ffffd097          	auipc	ra,0xffffd
    800035ee:	6ae080e7          	jalr	1710(ra) # 80000c98 <release>
}
    800035f2:	60e2                	ld	ra,24(sp)
    800035f4:	6442                	ld	s0,16(sp)
    800035f6:	64a2                	ld	s1,8(sp)
    800035f8:	6105                	addi	sp,sp,32
    800035fa:	8082                	ret

00000000800035fc <bunpin>:

void
bunpin(struct buf *b) {
    800035fc:	1101                	addi	sp,sp,-32
    800035fe:	ec06                	sd	ra,24(sp)
    80003600:	e822                	sd	s0,16(sp)
    80003602:	e426                	sd	s1,8(sp)
    80003604:	1000                	addi	s0,sp,32
    80003606:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003608:	00014517          	auipc	a0,0x14
    8000360c:	30050513          	addi	a0,a0,768 # 80017908 <bcache>
    80003610:	ffffd097          	auipc	ra,0xffffd
    80003614:	5d4080e7          	jalr	1492(ra) # 80000be4 <acquire>
  b->refcnt--;
    80003618:	40bc                	lw	a5,64(s1)
    8000361a:	37fd                	addiw	a5,a5,-1
    8000361c:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    8000361e:	00014517          	auipc	a0,0x14
    80003622:	2ea50513          	addi	a0,a0,746 # 80017908 <bcache>
    80003626:	ffffd097          	auipc	ra,0xffffd
    8000362a:	672080e7          	jalr	1650(ra) # 80000c98 <release>
}
    8000362e:	60e2                	ld	ra,24(sp)
    80003630:	6442                	ld	s0,16(sp)
    80003632:	64a2                	ld	s1,8(sp)
    80003634:	6105                	addi	sp,sp,32
    80003636:	8082                	ret

0000000080003638 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80003638:	1101                	addi	sp,sp,-32
    8000363a:	ec06                	sd	ra,24(sp)
    8000363c:	e822                	sd	s0,16(sp)
    8000363e:	e426                	sd	s1,8(sp)
    80003640:	e04a                	sd	s2,0(sp)
    80003642:	1000                	addi	s0,sp,32
    80003644:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80003646:	00d5d59b          	srliw	a1,a1,0xd
    8000364a:	0001d797          	auipc	a5,0x1d
    8000364e:	99a7a783          	lw	a5,-1638(a5) # 8001ffe4 <sb+0x1c>
    80003652:	9dbd                	addw	a1,a1,a5
    80003654:	00000097          	auipc	ra,0x0
    80003658:	d9e080e7          	jalr	-610(ra) # 800033f2 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    8000365c:	0074f713          	andi	a4,s1,7
    80003660:	4785                	li	a5,1
    80003662:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80003666:	14ce                	slli	s1,s1,0x33
    80003668:	90d9                	srli	s1,s1,0x36
    8000366a:	00950733          	add	a4,a0,s1
    8000366e:	05874703          	lbu	a4,88(a4)
    80003672:	00e7f6b3          	and	a3,a5,a4
    80003676:	c69d                	beqz	a3,800036a4 <bfree+0x6c>
    80003678:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    8000367a:	94aa                	add	s1,s1,a0
    8000367c:	fff7c793          	not	a5,a5
    80003680:	8ff9                	and	a5,a5,a4
    80003682:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    80003686:	00001097          	auipc	ra,0x1
    8000368a:	118080e7          	jalr	280(ra) # 8000479e <log_write>
  brelse(bp);
    8000368e:	854a                	mv	a0,s2
    80003690:	00000097          	auipc	ra,0x0
    80003694:	e92080e7          	jalr	-366(ra) # 80003522 <brelse>
}
    80003698:	60e2                	ld	ra,24(sp)
    8000369a:	6442                	ld	s0,16(sp)
    8000369c:	64a2                	ld	s1,8(sp)
    8000369e:	6902                	ld	s2,0(sp)
    800036a0:	6105                	addi	sp,sp,32
    800036a2:	8082                	ret
    panic("freeing free block");
    800036a4:	00005517          	auipc	a0,0x5
    800036a8:	ea450513          	addi	a0,a0,-348 # 80008548 <syscalls+0xf8>
    800036ac:	ffffd097          	auipc	ra,0xffffd
    800036b0:	e92080e7          	jalr	-366(ra) # 8000053e <panic>

00000000800036b4 <balloc>:
{
    800036b4:	711d                	addi	sp,sp,-96
    800036b6:	ec86                	sd	ra,88(sp)
    800036b8:	e8a2                	sd	s0,80(sp)
    800036ba:	e4a6                	sd	s1,72(sp)
    800036bc:	e0ca                	sd	s2,64(sp)
    800036be:	fc4e                	sd	s3,56(sp)
    800036c0:	f852                	sd	s4,48(sp)
    800036c2:	f456                	sd	s5,40(sp)
    800036c4:	f05a                	sd	s6,32(sp)
    800036c6:	ec5e                	sd	s7,24(sp)
    800036c8:	e862                	sd	s8,16(sp)
    800036ca:	e466                	sd	s9,8(sp)
    800036cc:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    800036ce:	0001d797          	auipc	a5,0x1d
    800036d2:	8fe7a783          	lw	a5,-1794(a5) # 8001ffcc <sb+0x4>
    800036d6:	cbd1                	beqz	a5,8000376a <balloc+0xb6>
    800036d8:	8baa                	mv	s7,a0
    800036da:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    800036dc:	0001db17          	auipc	s6,0x1d
    800036e0:	8ecb0b13          	addi	s6,s6,-1812 # 8001ffc8 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800036e4:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    800036e6:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800036e8:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    800036ea:	6c89                	lui	s9,0x2
    800036ec:	a831                	j	80003708 <balloc+0x54>
    brelse(bp);
    800036ee:	854a                	mv	a0,s2
    800036f0:	00000097          	auipc	ra,0x0
    800036f4:	e32080e7          	jalr	-462(ra) # 80003522 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    800036f8:	015c87bb          	addw	a5,s9,s5
    800036fc:	00078a9b          	sext.w	s5,a5
    80003700:	004b2703          	lw	a4,4(s6)
    80003704:	06eaf363          	bgeu	s5,a4,8000376a <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    80003708:	41fad79b          	sraiw	a5,s5,0x1f
    8000370c:	0137d79b          	srliw	a5,a5,0x13
    80003710:	015787bb          	addw	a5,a5,s5
    80003714:	40d7d79b          	sraiw	a5,a5,0xd
    80003718:	01cb2583          	lw	a1,28(s6)
    8000371c:	9dbd                	addw	a1,a1,a5
    8000371e:	855e                	mv	a0,s7
    80003720:	00000097          	auipc	ra,0x0
    80003724:	cd2080e7          	jalr	-814(ra) # 800033f2 <bread>
    80003728:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000372a:	004b2503          	lw	a0,4(s6)
    8000372e:	000a849b          	sext.w	s1,s5
    80003732:	8662                	mv	a2,s8
    80003734:	faa4fde3          	bgeu	s1,a0,800036ee <balloc+0x3a>
      m = 1 << (bi % 8);
    80003738:	41f6579b          	sraiw	a5,a2,0x1f
    8000373c:	01d7d69b          	srliw	a3,a5,0x1d
    80003740:	00c6873b          	addw	a4,a3,a2
    80003744:	00777793          	andi	a5,a4,7
    80003748:	9f95                	subw	a5,a5,a3
    8000374a:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    8000374e:	4037571b          	sraiw	a4,a4,0x3
    80003752:	00e906b3          	add	a3,s2,a4
    80003756:	0586c683          	lbu	a3,88(a3)
    8000375a:	00d7f5b3          	and	a1,a5,a3
    8000375e:	cd91                	beqz	a1,8000377a <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003760:	2605                	addiw	a2,a2,1
    80003762:	2485                	addiw	s1,s1,1
    80003764:	fd4618e3          	bne	a2,s4,80003734 <balloc+0x80>
    80003768:	b759                	j	800036ee <balloc+0x3a>
  panic("balloc: out of blocks");
    8000376a:	00005517          	auipc	a0,0x5
    8000376e:	df650513          	addi	a0,a0,-522 # 80008560 <syscalls+0x110>
    80003772:	ffffd097          	auipc	ra,0xffffd
    80003776:	dcc080e7          	jalr	-564(ra) # 8000053e <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    8000377a:	974a                	add	a4,a4,s2
    8000377c:	8fd5                	or	a5,a5,a3
    8000377e:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    80003782:	854a                	mv	a0,s2
    80003784:	00001097          	auipc	ra,0x1
    80003788:	01a080e7          	jalr	26(ra) # 8000479e <log_write>
        brelse(bp);
    8000378c:	854a                	mv	a0,s2
    8000378e:	00000097          	auipc	ra,0x0
    80003792:	d94080e7          	jalr	-620(ra) # 80003522 <brelse>
  bp = bread(dev, bno);
    80003796:	85a6                	mv	a1,s1
    80003798:	855e                	mv	a0,s7
    8000379a:	00000097          	auipc	ra,0x0
    8000379e:	c58080e7          	jalr	-936(ra) # 800033f2 <bread>
    800037a2:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    800037a4:	40000613          	li	a2,1024
    800037a8:	4581                	li	a1,0
    800037aa:	05850513          	addi	a0,a0,88
    800037ae:	ffffd097          	auipc	ra,0xffffd
    800037b2:	532080e7          	jalr	1330(ra) # 80000ce0 <memset>
  log_write(bp);
    800037b6:	854a                	mv	a0,s2
    800037b8:	00001097          	auipc	ra,0x1
    800037bc:	fe6080e7          	jalr	-26(ra) # 8000479e <log_write>
  brelse(bp);
    800037c0:	854a                	mv	a0,s2
    800037c2:	00000097          	auipc	ra,0x0
    800037c6:	d60080e7          	jalr	-672(ra) # 80003522 <brelse>
}
    800037ca:	8526                	mv	a0,s1
    800037cc:	60e6                	ld	ra,88(sp)
    800037ce:	6446                	ld	s0,80(sp)
    800037d0:	64a6                	ld	s1,72(sp)
    800037d2:	6906                	ld	s2,64(sp)
    800037d4:	79e2                	ld	s3,56(sp)
    800037d6:	7a42                	ld	s4,48(sp)
    800037d8:	7aa2                	ld	s5,40(sp)
    800037da:	7b02                	ld	s6,32(sp)
    800037dc:	6be2                	ld	s7,24(sp)
    800037de:	6c42                	ld	s8,16(sp)
    800037e0:	6ca2                	ld	s9,8(sp)
    800037e2:	6125                	addi	sp,sp,96
    800037e4:	8082                	ret

00000000800037e6 <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    800037e6:	7179                	addi	sp,sp,-48
    800037e8:	f406                	sd	ra,40(sp)
    800037ea:	f022                	sd	s0,32(sp)
    800037ec:	ec26                	sd	s1,24(sp)
    800037ee:	e84a                	sd	s2,16(sp)
    800037f0:	e44e                	sd	s3,8(sp)
    800037f2:	e052                	sd	s4,0(sp)
    800037f4:	1800                	addi	s0,sp,48
    800037f6:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    800037f8:	47ad                	li	a5,11
    800037fa:	04b7fe63          	bgeu	a5,a1,80003856 <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    800037fe:	ff45849b          	addiw	s1,a1,-12
    80003802:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003806:	0ff00793          	li	a5,255
    8000380a:	0ae7e363          	bltu	a5,a4,800038b0 <bmap+0xca>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    8000380e:	08052583          	lw	a1,128(a0)
    80003812:	c5ad                	beqz	a1,8000387c <bmap+0x96>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    80003814:	00092503          	lw	a0,0(s2)
    80003818:	00000097          	auipc	ra,0x0
    8000381c:	bda080e7          	jalr	-1062(ra) # 800033f2 <bread>
    80003820:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003822:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003826:	02049593          	slli	a1,s1,0x20
    8000382a:	9181                	srli	a1,a1,0x20
    8000382c:	058a                	slli	a1,a1,0x2
    8000382e:	00b784b3          	add	s1,a5,a1
    80003832:	0004a983          	lw	s3,0(s1)
    80003836:	04098d63          	beqz	s3,80003890 <bmap+0xaa>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    8000383a:	8552                	mv	a0,s4
    8000383c:	00000097          	auipc	ra,0x0
    80003840:	ce6080e7          	jalr	-794(ra) # 80003522 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80003844:	854e                	mv	a0,s3
    80003846:	70a2                	ld	ra,40(sp)
    80003848:	7402                	ld	s0,32(sp)
    8000384a:	64e2                	ld	s1,24(sp)
    8000384c:	6942                	ld	s2,16(sp)
    8000384e:	69a2                	ld	s3,8(sp)
    80003850:	6a02                	ld	s4,0(sp)
    80003852:	6145                	addi	sp,sp,48
    80003854:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    80003856:	02059493          	slli	s1,a1,0x20
    8000385a:	9081                	srli	s1,s1,0x20
    8000385c:	048a                	slli	s1,s1,0x2
    8000385e:	94aa                	add	s1,s1,a0
    80003860:	0504a983          	lw	s3,80(s1)
    80003864:	fe0990e3          	bnez	s3,80003844 <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    80003868:	4108                	lw	a0,0(a0)
    8000386a:	00000097          	auipc	ra,0x0
    8000386e:	e4a080e7          	jalr	-438(ra) # 800036b4 <balloc>
    80003872:	0005099b          	sext.w	s3,a0
    80003876:	0534a823          	sw	s3,80(s1)
    8000387a:	b7e9                	j	80003844 <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    8000387c:	4108                	lw	a0,0(a0)
    8000387e:	00000097          	auipc	ra,0x0
    80003882:	e36080e7          	jalr	-458(ra) # 800036b4 <balloc>
    80003886:	0005059b          	sext.w	a1,a0
    8000388a:	08b92023          	sw	a1,128(s2)
    8000388e:	b759                	j	80003814 <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    80003890:	00092503          	lw	a0,0(s2)
    80003894:	00000097          	auipc	ra,0x0
    80003898:	e20080e7          	jalr	-480(ra) # 800036b4 <balloc>
    8000389c:	0005099b          	sext.w	s3,a0
    800038a0:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    800038a4:	8552                	mv	a0,s4
    800038a6:	00001097          	auipc	ra,0x1
    800038aa:	ef8080e7          	jalr	-264(ra) # 8000479e <log_write>
    800038ae:	b771                	j	8000383a <bmap+0x54>
  panic("bmap: out of range");
    800038b0:	00005517          	auipc	a0,0x5
    800038b4:	cc850513          	addi	a0,a0,-824 # 80008578 <syscalls+0x128>
    800038b8:	ffffd097          	auipc	ra,0xffffd
    800038bc:	c86080e7          	jalr	-890(ra) # 8000053e <panic>

00000000800038c0 <iget>:
{
    800038c0:	7179                	addi	sp,sp,-48
    800038c2:	f406                	sd	ra,40(sp)
    800038c4:	f022                	sd	s0,32(sp)
    800038c6:	ec26                	sd	s1,24(sp)
    800038c8:	e84a                	sd	s2,16(sp)
    800038ca:	e44e                	sd	s3,8(sp)
    800038cc:	e052                	sd	s4,0(sp)
    800038ce:	1800                	addi	s0,sp,48
    800038d0:	89aa                	mv	s3,a0
    800038d2:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    800038d4:	0001c517          	auipc	a0,0x1c
    800038d8:	71450513          	addi	a0,a0,1812 # 8001ffe8 <itable>
    800038dc:	ffffd097          	auipc	ra,0xffffd
    800038e0:	308080e7          	jalr	776(ra) # 80000be4 <acquire>
  empty = 0;
    800038e4:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800038e6:	0001c497          	auipc	s1,0x1c
    800038ea:	71a48493          	addi	s1,s1,1818 # 80020000 <itable+0x18>
    800038ee:	0001e697          	auipc	a3,0x1e
    800038f2:	1a268693          	addi	a3,a3,418 # 80021a90 <log>
    800038f6:	a039                	j	80003904 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800038f8:	02090b63          	beqz	s2,8000392e <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800038fc:	08848493          	addi	s1,s1,136
    80003900:	02d48a63          	beq	s1,a3,80003934 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003904:	449c                	lw	a5,8(s1)
    80003906:	fef059e3          	blez	a5,800038f8 <iget+0x38>
    8000390a:	4098                	lw	a4,0(s1)
    8000390c:	ff3716e3          	bne	a4,s3,800038f8 <iget+0x38>
    80003910:	40d8                	lw	a4,4(s1)
    80003912:	ff4713e3          	bne	a4,s4,800038f8 <iget+0x38>
      ip->ref++;
    80003916:	2785                	addiw	a5,a5,1
    80003918:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    8000391a:	0001c517          	auipc	a0,0x1c
    8000391e:	6ce50513          	addi	a0,a0,1742 # 8001ffe8 <itable>
    80003922:	ffffd097          	auipc	ra,0xffffd
    80003926:	376080e7          	jalr	886(ra) # 80000c98 <release>
      return ip;
    8000392a:	8926                	mv	s2,s1
    8000392c:	a03d                	j	8000395a <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    8000392e:	f7f9                	bnez	a5,800038fc <iget+0x3c>
    80003930:	8926                	mv	s2,s1
    80003932:	b7e9                	j	800038fc <iget+0x3c>
  if(empty == 0)
    80003934:	02090c63          	beqz	s2,8000396c <iget+0xac>
  ip->dev = dev;
    80003938:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    8000393c:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003940:	4785                	li	a5,1
    80003942:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003946:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    8000394a:	0001c517          	auipc	a0,0x1c
    8000394e:	69e50513          	addi	a0,a0,1694 # 8001ffe8 <itable>
    80003952:	ffffd097          	auipc	ra,0xffffd
    80003956:	346080e7          	jalr	838(ra) # 80000c98 <release>
}
    8000395a:	854a                	mv	a0,s2
    8000395c:	70a2                	ld	ra,40(sp)
    8000395e:	7402                	ld	s0,32(sp)
    80003960:	64e2                	ld	s1,24(sp)
    80003962:	6942                	ld	s2,16(sp)
    80003964:	69a2                	ld	s3,8(sp)
    80003966:	6a02                	ld	s4,0(sp)
    80003968:	6145                	addi	sp,sp,48
    8000396a:	8082                	ret
    panic("iget: no inodes");
    8000396c:	00005517          	auipc	a0,0x5
    80003970:	c2450513          	addi	a0,a0,-988 # 80008590 <syscalls+0x140>
    80003974:	ffffd097          	auipc	ra,0xffffd
    80003978:	bca080e7          	jalr	-1078(ra) # 8000053e <panic>

000000008000397c <fsinit>:
fsinit(int dev) {
    8000397c:	7179                	addi	sp,sp,-48
    8000397e:	f406                	sd	ra,40(sp)
    80003980:	f022                	sd	s0,32(sp)
    80003982:	ec26                	sd	s1,24(sp)
    80003984:	e84a                	sd	s2,16(sp)
    80003986:	e44e                	sd	s3,8(sp)
    80003988:	1800                	addi	s0,sp,48
    8000398a:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    8000398c:	4585                	li	a1,1
    8000398e:	00000097          	auipc	ra,0x0
    80003992:	a64080e7          	jalr	-1436(ra) # 800033f2 <bread>
    80003996:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003998:	0001c997          	auipc	s3,0x1c
    8000399c:	63098993          	addi	s3,s3,1584 # 8001ffc8 <sb>
    800039a0:	02000613          	li	a2,32
    800039a4:	05850593          	addi	a1,a0,88
    800039a8:	854e                	mv	a0,s3
    800039aa:	ffffd097          	auipc	ra,0xffffd
    800039ae:	396080e7          	jalr	918(ra) # 80000d40 <memmove>
  brelse(bp);
    800039b2:	8526                	mv	a0,s1
    800039b4:	00000097          	auipc	ra,0x0
    800039b8:	b6e080e7          	jalr	-1170(ra) # 80003522 <brelse>
  if(sb.magic != FSMAGIC)
    800039bc:	0009a703          	lw	a4,0(s3)
    800039c0:	102037b7          	lui	a5,0x10203
    800039c4:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    800039c8:	02f71263          	bne	a4,a5,800039ec <fsinit+0x70>
  initlog(dev, &sb);
    800039cc:	0001c597          	auipc	a1,0x1c
    800039d0:	5fc58593          	addi	a1,a1,1532 # 8001ffc8 <sb>
    800039d4:	854a                	mv	a0,s2
    800039d6:	00001097          	auipc	ra,0x1
    800039da:	b4c080e7          	jalr	-1204(ra) # 80004522 <initlog>
}
    800039de:	70a2                	ld	ra,40(sp)
    800039e0:	7402                	ld	s0,32(sp)
    800039e2:	64e2                	ld	s1,24(sp)
    800039e4:	6942                	ld	s2,16(sp)
    800039e6:	69a2                	ld	s3,8(sp)
    800039e8:	6145                	addi	sp,sp,48
    800039ea:	8082                	ret
    panic("invalid file system");
    800039ec:	00005517          	auipc	a0,0x5
    800039f0:	bb450513          	addi	a0,a0,-1100 # 800085a0 <syscalls+0x150>
    800039f4:	ffffd097          	auipc	ra,0xffffd
    800039f8:	b4a080e7          	jalr	-1206(ra) # 8000053e <panic>

00000000800039fc <iinit>:
{
    800039fc:	7179                	addi	sp,sp,-48
    800039fe:	f406                	sd	ra,40(sp)
    80003a00:	f022                	sd	s0,32(sp)
    80003a02:	ec26                	sd	s1,24(sp)
    80003a04:	e84a                	sd	s2,16(sp)
    80003a06:	e44e                	sd	s3,8(sp)
    80003a08:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    80003a0a:	00005597          	auipc	a1,0x5
    80003a0e:	bae58593          	addi	a1,a1,-1106 # 800085b8 <syscalls+0x168>
    80003a12:	0001c517          	auipc	a0,0x1c
    80003a16:	5d650513          	addi	a0,a0,1494 # 8001ffe8 <itable>
    80003a1a:	ffffd097          	auipc	ra,0xffffd
    80003a1e:	13a080e7          	jalr	314(ra) # 80000b54 <initlock>
  for(i = 0; i < NINODE; i++) {
    80003a22:	0001c497          	auipc	s1,0x1c
    80003a26:	5ee48493          	addi	s1,s1,1518 # 80020010 <itable+0x28>
    80003a2a:	0001e997          	auipc	s3,0x1e
    80003a2e:	07698993          	addi	s3,s3,118 # 80021aa0 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80003a32:	00005917          	auipc	s2,0x5
    80003a36:	b8e90913          	addi	s2,s2,-1138 # 800085c0 <syscalls+0x170>
    80003a3a:	85ca                	mv	a1,s2
    80003a3c:	8526                	mv	a0,s1
    80003a3e:	00001097          	auipc	ra,0x1
    80003a42:	e46080e7          	jalr	-442(ra) # 80004884 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003a46:	08848493          	addi	s1,s1,136
    80003a4a:	ff3498e3          	bne	s1,s3,80003a3a <iinit+0x3e>
}
    80003a4e:	70a2                	ld	ra,40(sp)
    80003a50:	7402                	ld	s0,32(sp)
    80003a52:	64e2                	ld	s1,24(sp)
    80003a54:	6942                	ld	s2,16(sp)
    80003a56:	69a2                	ld	s3,8(sp)
    80003a58:	6145                	addi	sp,sp,48
    80003a5a:	8082                	ret

0000000080003a5c <ialloc>:
{
    80003a5c:	715d                	addi	sp,sp,-80
    80003a5e:	e486                	sd	ra,72(sp)
    80003a60:	e0a2                	sd	s0,64(sp)
    80003a62:	fc26                	sd	s1,56(sp)
    80003a64:	f84a                	sd	s2,48(sp)
    80003a66:	f44e                	sd	s3,40(sp)
    80003a68:	f052                	sd	s4,32(sp)
    80003a6a:	ec56                	sd	s5,24(sp)
    80003a6c:	e85a                	sd	s6,16(sp)
    80003a6e:	e45e                	sd	s7,8(sp)
    80003a70:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003a72:	0001c717          	auipc	a4,0x1c
    80003a76:	56272703          	lw	a4,1378(a4) # 8001ffd4 <sb+0xc>
    80003a7a:	4785                	li	a5,1
    80003a7c:	04e7fa63          	bgeu	a5,a4,80003ad0 <ialloc+0x74>
    80003a80:	8aaa                	mv	s5,a0
    80003a82:	8bae                	mv	s7,a1
    80003a84:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003a86:	0001ca17          	auipc	s4,0x1c
    80003a8a:	542a0a13          	addi	s4,s4,1346 # 8001ffc8 <sb>
    80003a8e:	00048b1b          	sext.w	s6,s1
    80003a92:	0044d593          	srli	a1,s1,0x4
    80003a96:	018a2783          	lw	a5,24(s4)
    80003a9a:	9dbd                	addw	a1,a1,a5
    80003a9c:	8556                	mv	a0,s5
    80003a9e:	00000097          	auipc	ra,0x0
    80003aa2:	954080e7          	jalr	-1708(ra) # 800033f2 <bread>
    80003aa6:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003aa8:	05850993          	addi	s3,a0,88
    80003aac:	00f4f793          	andi	a5,s1,15
    80003ab0:	079a                	slli	a5,a5,0x6
    80003ab2:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003ab4:	00099783          	lh	a5,0(s3)
    80003ab8:	c785                	beqz	a5,80003ae0 <ialloc+0x84>
    brelse(bp);
    80003aba:	00000097          	auipc	ra,0x0
    80003abe:	a68080e7          	jalr	-1432(ra) # 80003522 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003ac2:	0485                	addi	s1,s1,1
    80003ac4:	00ca2703          	lw	a4,12(s4)
    80003ac8:	0004879b          	sext.w	a5,s1
    80003acc:	fce7e1e3          	bltu	a5,a4,80003a8e <ialloc+0x32>
  panic("ialloc: no inodes");
    80003ad0:	00005517          	auipc	a0,0x5
    80003ad4:	af850513          	addi	a0,a0,-1288 # 800085c8 <syscalls+0x178>
    80003ad8:	ffffd097          	auipc	ra,0xffffd
    80003adc:	a66080e7          	jalr	-1434(ra) # 8000053e <panic>
      memset(dip, 0, sizeof(*dip));
    80003ae0:	04000613          	li	a2,64
    80003ae4:	4581                	li	a1,0
    80003ae6:	854e                	mv	a0,s3
    80003ae8:	ffffd097          	auipc	ra,0xffffd
    80003aec:	1f8080e7          	jalr	504(ra) # 80000ce0 <memset>
      dip->type = type;
    80003af0:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003af4:	854a                	mv	a0,s2
    80003af6:	00001097          	auipc	ra,0x1
    80003afa:	ca8080e7          	jalr	-856(ra) # 8000479e <log_write>
      brelse(bp);
    80003afe:	854a                	mv	a0,s2
    80003b00:	00000097          	auipc	ra,0x0
    80003b04:	a22080e7          	jalr	-1502(ra) # 80003522 <brelse>
      return iget(dev, inum);
    80003b08:	85da                	mv	a1,s6
    80003b0a:	8556                	mv	a0,s5
    80003b0c:	00000097          	auipc	ra,0x0
    80003b10:	db4080e7          	jalr	-588(ra) # 800038c0 <iget>
}
    80003b14:	60a6                	ld	ra,72(sp)
    80003b16:	6406                	ld	s0,64(sp)
    80003b18:	74e2                	ld	s1,56(sp)
    80003b1a:	7942                	ld	s2,48(sp)
    80003b1c:	79a2                	ld	s3,40(sp)
    80003b1e:	7a02                	ld	s4,32(sp)
    80003b20:	6ae2                	ld	s5,24(sp)
    80003b22:	6b42                	ld	s6,16(sp)
    80003b24:	6ba2                	ld	s7,8(sp)
    80003b26:	6161                	addi	sp,sp,80
    80003b28:	8082                	ret

0000000080003b2a <iupdate>:
{
    80003b2a:	1101                	addi	sp,sp,-32
    80003b2c:	ec06                	sd	ra,24(sp)
    80003b2e:	e822                	sd	s0,16(sp)
    80003b30:	e426                	sd	s1,8(sp)
    80003b32:	e04a                	sd	s2,0(sp)
    80003b34:	1000                	addi	s0,sp,32
    80003b36:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003b38:	415c                	lw	a5,4(a0)
    80003b3a:	0047d79b          	srliw	a5,a5,0x4
    80003b3e:	0001c597          	auipc	a1,0x1c
    80003b42:	4a25a583          	lw	a1,1186(a1) # 8001ffe0 <sb+0x18>
    80003b46:	9dbd                	addw	a1,a1,a5
    80003b48:	4108                	lw	a0,0(a0)
    80003b4a:	00000097          	auipc	ra,0x0
    80003b4e:	8a8080e7          	jalr	-1880(ra) # 800033f2 <bread>
    80003b52:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003b54:	05850793          	addi	a5,a0,88
    80003b58:	40c8                	lw	a0,4(s1)
    80003b5a:	893d                	andi	a0,a0,15
    80003b5c:	051a                	slli	a0,a0,0x6
    80003b5e:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    80003b60:	04449703          	lh	a4,68(s1)
    80003b64:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    80003b68:	04649703          	lh	a4,70(s1)
    80003b6c:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    80003b70:	04849703          	lh	a4,72(s1)
    80003b74:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    80003b78:	04a49703          	lh	a4,74(s1)
    80003b7c:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    80003b80:	44f8                	lw	a4,76(s1)
    80003b82:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003b84:	03400613          	li	a2,52
    80003b88:	05048593          	addi	a1,s1,80
    80003b8c:	0531                	addi	a0,a0,12
    80003b8e:	ffffd097          	auipc	ra,0xffffd
    80003b92:	1b2080e7          	jalr	434(ra) # 80000d40 <memmove>
  log_write(bp);
    80003b96:	854a                	mv	a0,s2
    80003b98:	00001097          	auipc	ra,0x1
    80003b9c:	c06080e7          	jalr	-1018(ra) # 8000479e <log_write>
  brelse(bp);
    80003ba0:	854a                	mv	a0,s2
    80003ba2:	00000097          	auipc	ra,0x0
    80003ba6:	980080e7          	jalr	-1664(ra) # 80003522 <brelse>
}
    80003baa:	60e2                	ld	ra,24(sp)
    80003bac:	6442                	ld	s0,16(sp)
    80003bae:	64a2                	ld	s1,8(sp)
    80003bb0:	6902                	ld	s2,0(sp)
    80003bb2:	6105                	addi	sp,sp,32
    80003bb4:	8082                	ret

0000000080003bb6 <idup>:
{
    80003bb6:	1101                	addi	sp,sp,-32
    80003bb8:	ec06                	sd	ra,24(sp)
    80003bba:	e822                	sd	s0,16(sp)
    80003bbc:	e426                	sd	s1,8(sp)
    80003bbe:	1000                	addi	s0,sp,32
    80003bc0:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003bc2:	0001c517          	auipc	a0,0x1c
    80003bc6:	42650513          	addi	a0,a0,1062 # 8001ffe8 <itable>
    80003bca:	ffffd097          	auipc	ra,0xffffd
    80003bce:	01a080e7          	jalr	26(ra) # 80000be4 <acquire>
  ip->ref++;
    80003bd2:	449c                	lw	a5,8(s1)
    80003bd4:	2785                	addiw	a5,a5,1
    80003bd6:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003bd8:	0001c517          	auipc	a0,0x1c
    80003bdc:	41050513          	addi	a0,a0,1040 # 8001ffe8 <itable>
    80003be0:	ffffd097          	auipc	ra,0xffffd
    80003be4:	0b8080e7          	jalr	184(ra) # 80000c98 <release>
}
    80003be8:	8526                	mv	a0,s1
    80003bea:	60e2                	ld	ra,24(sp)
    80003bec:	6442                	ld	s0,16(sp)
    80003bee:	64a2                	ld	s1,8(sp)
    80003bf0:	6105                	addi	sp,sp,32
    80003bf2:	8082                	ret

0000000080003bf4 <ilock>:
{
    80003bf4:	1101                	addi	sp,sp,-32
    80003bf6:	ec06                	sd	ra,24(sp)
    80003bf8:	e822                	sd	s0,16(sp)
    80003bfa:	e426                	sd	s1,8(sp)
    80003bfc:	e04a                	sd	s2,0(sp)
    80003bfe:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003c00:	c115                	beqz	a0,80003c24 <ilock+0x30>
    80003c02:	84aa                	mv	s1,a0
    80003c04:	451c                	lw	a5,8(a0)
    80003c06:	00f05f63          	blez	a5,80003c24 <ilock+0x30>
  acquiresleep(&ip->lock);
    80003c0a:	0541                	addi	a0,a0,16
    80003c0c:	00001097          	auipc	ra,0x1
    80003c10:	cb2080e7          	jalr	-846(ra) # 800048be <acquiresleep>
  if(ip->valid == 0){
    80003c14:	40bc                	lw	a5,64(s1)
    80003c16:	cf99                	beqz	a5,80003c34 <ilock+0x40>
}
    80003c18:	60e2                	ld	ra,24(sp)
    80003c1a:	6442                	ld	s0,16(sp)
    80003c1c:	64a2                	ld	s1,8(sp)
    80003c1e:	6902                	ld	s2,0(sp)
    80003c20:	6105                	addi	sp,sp,32
    80003c22:	8082                	ret
    panic("ilock");
    80003c24:	00005517          	auipc	a0,0x5
    80003c28:	9bc50513          	addi	a0,a0,-1604 # 800085e0 <syscalls+0x190>
    80003c2c:	ffffd097          	auipc	ra,0xffffd
    80003c30:	912080e7          	jalr	-1774(ra) # 8000053e <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003c34:	40dc                	lw	a5,4(s1)
    80003c36:	0047d79b          	srliw	a5,a5,0x4
    80003c3a:	0001c597          	auipc	a1,0x1c
    80003c3e:	3a65a583          	lw	a1,934(a1) # 8001ffe0 <sb+0x18>
    80003c42:	9dbd                	addw	a1,a1,a5
    80003c44:	4088                	lw	a0,0(s1)
    80003c46:	fffff097          	auipc	ra,0xfffff
    80003c4a:	7ac080e7          	jalr	1964(ra) # 800033f2 <bread>
    80003c4e:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003c50:	05850593          	addi	a1,a0,88
    80003c54:	40dc                	lw	a5,4(s1)
    80003c56:	8bbd                	andi	a5,a5,15
    80003c58:	079a                	slli	a5,a5,0x6
    80003c5a:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003c5c:	00059783          	lh	a5,0(a1)
    80003c60:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003c64:	00259783          	lh	a5,2(a1)
    80003c68:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003c6c:	00459783          	lh	a5,4(a1)
    80003c70:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003c74:	00659783          	lh	a5,6(a1)
    80003c78:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003c7c:	459c                	lw	a5,8(a1)
    80003c7e:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003c80:	03400613          	li	a2,52
    80003c84:	05b1                	addi	a1,a1,12
    80003c86:	05048513          	addi	a0,s1,80
    80003c8a:	ffffd097          	auipc	ra,0xffffd
    80003c8e:	0b6080e7          	jalr	182(ra) # 80000d40 <memmove>
    brelse(bp);
    80003c92:	854a                	mv	a0,s2
    80003c94:	00000097          	auipc	ra,0x0
    80003c98:	88e080e7          	jalr	-1906(ra) # 80003522 <brelse>
    ip->valid = 1;
    80003c9c:	4785                	li	a5,1
    80003c9e:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003ca0:	04449783          	lh	a5,68(s1)
    80003ca4:	fbb5                	bnez	a5,80003c18 <ilock+0x24>
      panic("ilock: no type");
    80003ca6:	00005517          	auipc	a0,0x5
    80003caa:	94250513          	addi	a0,a0,-1726 # 800085e8 <syscalls+0x198>
    80003cae:	ffffd097          	auipc	ra,0xffffd
    80003cb2:	890080e7          	jalr	-1904(ra) # 8000053e <panic>

0000000080003cb6 <iunlock>:
{
    80003cb6:	1101                	addi	sp,sp,-32
    80003cb8:	ec06                	sd	ra,24(sp)
    80003cba:	e822                	sd	s0,16(sp)
    80003cbc:	e426                	sd	s1,8(sp)
    80003cbe:	e04a                	sd	s2,0(sp)
    80003cc0:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003cc2:	c905                	beqz	a0,80003cf2 <iunlock+0x3c>
    80003cc4:	84aa                	mv	s1,a0
    80003cc6:	01050913          	addi	s2,a0,16
    80003cca:	854a                	mv	a0,s2
    80003ccc:	00001097          	auipc	ra,0x1
    80003cd0:	c8c080e7          	jalr	-884(ra) # 80004958 <holdingsleep>
    80003cd4:	cd19                	beqz	a0,80003cf2 <iunlock+0x3c>
    80003cd6:	449c                	lw	a5,8(s1)
    80003cd8:	00f05d63          	blez	a5,80003cf2 <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003cdc:	854a                	mv	a0,s2
    80003cde:	00001097          	auipc	ra,0x1
    80003ce2:	c36080e7          	jalr	-970(ra) # 80004914 <releasesleep>
}
    80003ce6:	60e2                	ld	ra,24(sp)
    80003ce8:	6442                	ld	s0,16(sp)
    80003cea:	64a2                	ld	s1,8(sp)
    80003cec:	6902                	ld	s2,0(sp)
    80003cee:	6105                	addi	sp,sp,32
    80003cf0:	8082                	ret
    panic("iunlock");
    80003cf2:	00005517          	auipc	a0,0x5
    80003cf6:	90650513          	addi	a0,a0,-1786 # 800085f8 <syscalls+0x1a8>
    80003cfa:	ffffd097          	auipc	ra,0xffffd
    80003cfe:	844080e7          	jalr	-1980(ra) # 8000053e <panic>

0000000080003d02 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003d02:	7179                	addi	sp,sp,-48
    80003d04:	f406                	sd	ra,40(sp)
    80003d06:	f022                	sd	s0,32(sp)
    80003d08:	ec26                	sd	s1,24(sp)
    80003d0a:	e84a                	sd	s2,16(sp)
    80003d0c:	e44e                	sd	s3,8(sp)
    80003d0e:	e052                	sd	s4,0(sp)
    80003d10:	1800                	addi	s0,sp,48
    80003d12:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003d14:	05050493          	addi	s1,a0,80
    80003d18:	08050913          	addi	s2,a0,128
    80003d1c:	a021                	j	80003d24 <itrunc+0x22>
    80003d1e:	0491                	addi	s1,s1,4
    80003d20:	01248d63          	beq	s1,s2,80003d3a <itrunc+0x38>
    if(ip->addrs[i]){
    80003d24:	408c                	lw	a1,0(s1)
    80003d26:	dde5                	beqz	a1,80003d1e <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003d28:	0009a503          	lw	a0,0(s3)
    80003d2c:	00000097          	auipc	ra,0x0
    80003d30:	90c080e7          	jalr	-1780(ra) # 80003638 <bfree>
      ip->addrs[i] = 0;
    80003d34:	0004a023          	sw	zero,0(s1)
    80003d38:	b7dd                	j	80003d1e <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003d3a:	0809a583          	lw	a1,128(s3)
    80003d3e:	e185                	bnez	a1,80003d5e <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003d40:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003d44:	854e                	mv	a0,s3
    80003d46:	00000097          	auipc	ra,0x0
    80003d4a:	de4080e7          	jalr	-540(ra) # 80003b2a <iupdate>
}
    80003d4e:	70a2                	ld	ra,40(sp)
    80003d50:	7402                	ld	s0,32(sp)
    80003d52:	64e2                	ld	s1,24(sp)
    80003d54:	6942                	ld	s2,16(sp)
    80003d56:	69a2                	ld	s3,8(sp)
    80003d58:	6a02                	ld	s4,0(sp)
    80003d5a:	6145                	addi	sp,sp,48
    80003d5c:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003d5e:	0009a503          	lw	a0,0(s3)
    80003d62:	fffff097          	auipc	ra,0xfffff
    80003d66:	690080e7          	jalr	1680(ra) # 800033f2 <bread>
    80003d6a:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003d6c:	05850493          	addi	s1,a0,88
    80003d70:	45850913          	addi	s2,a0,1112
    80003d74:	a811                	j	80003d88 <itrunc+0x86>
        bfree(ip->dev, a[j]);
    80003d76:	0009a503          	lw	a0,0(s3)
    80003d7a:	00000097          	auipc	ra,0x0
    80003d7e:	8be080e7          	jalr	-1858(ra) # 80003638 <bfree>
    for(j = 0; j < NINDIRECT; j++){
    80003d82:	0491                	addi	s1,s1,4
    80003d84:	01248563          	beq	s1,s2,80003d8e <itrunc+0x8c>
      if(a[j])
    80003d88:	408c                	lw	a1,0(s1)
    80003d8a:	dde5                	beqz	a1,80003d82 <itrunc+0x80>
    80003d8c:	b7ed                	j	80003d76 <itrunc+0x74>
    brelse(bp);
    80003d8e:	8552                	mv	a0,s4
    80003d90:	fffff097          	auipc	ra,0xfffff
    80003d94:	792080e7          	jalr	1938(ra) # 80003522 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003d98:	0809a583          	lw	a1,128(s3)
    80003d9c:	0009a503          	lw	a0,0(s3)
    80003da0:	00000097          	auipc	ra,0x0
    80003da4:	898080e7          	jalr	-1896(ra) # 80003638 <bfree>
    ip->addrs[NDIRECT] = 0;
    80003da8:	0809a023          	sw	zero,128(s3)
    80003dac:	bf51                	j	80003d40 <itrunc+0x3e>

0000000080003dae <iput>:
{
    80003dae:	1101                	addi	sp,sp,-32
    80003db0:	ec06                	sd	ra,24(sp)
    80003db2:	e822                	sd	s0,16(sp)
    80003db4:	e426                	sd	s1,8(sp)
    80003db6:	e04a                	sd	s2,0(sp)
    80003db8:	1000                	addi	s0,sp,32
    80003dba:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003dbc:	0001c517          	auipc	a0,0x1c
    80003dc0:	22c50513          	addi	a0,a0,556 # 8001ffe8 <itable>
    80003dc4:	ffffd097          	auipc	ra,0xffffd
    80003dc8:	e20080e7          	jalr	-480(ra) # 80000be4 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003dcc:	4498                	lw	a4,8(s1)
    80003dce:	4785                	li	a5,1
    80003dd0:	02f70363          	beq	a4,a5,80003df6 <iput+0x48>
  ip->ref--;
    80003dd4:	449c                	lw	a5,8(s1)
    80003dd6:	37fd                	addiw	a5,a5,-1
    80003dd8:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003dda:	0001c517          	auipc	a0,0x1c
    80003dde:	20e50513          	addi	a0,a0,526 # 8001ffe8 <itable>
    80003de2:	ffffd097          	auipc	ra,0xffffd
    80003de6:	eb6080e7          	jalr	-330(ra) # 80000c98 <release>
}
    80003dea:	60e2                	ld	ra,24(sp)
    80003dec:	6442                	ld	s0,16(sp)
    80003dee:	64a2                	ld	s1,8(sp)
    80003df0:	6902                	ld	s2,0(sp)
    80003df2:	6105                	addi	sp,sp,32
    80003df4:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003df6:	40bc                	lw	a5,64(s1)
    80003df8:	dff1                	beqz	a5,80003dd4 <iput+0x26>
    80003dfa:	04a49783          	lh	a5,74(s1)
    80003dfe:	fbf9                	bnez	a5,80003dd4 <iput+0x26>
    acquiresleep(&ip->lock);
    80003e00:	01048913          	addi	s2,s1,16
    80003e04:	854a                	mv	a0,s2
    80003e06:	00001097          	auipc	ra,0x1
    80003e0a:	ab8080e7          	jalr	-1352(ra) # 800048be <acquiresleep>
    release(&itable.lock);
    80003e0e:	0001c517          	auipc	a0,0x1c
    80003e12:	1da50513          	addi	a0,a0,474 # 8001ffe8 <itable>
    80003e16:	ffffd097          	auipc	ra,0xffffd
    80003e1a:	e82080e7          	jalr	-382(ra) # 80000c98 <release>
    itrunc(ip);
    80003e1e:	8526                	mv	a0,s1
    80003e20:	00000097          	auipc	ra,0x0
    80003e24:	ee2080e7          	jalr	-286(ra) # 80003d02 <itrunc>
    ip->type = 0;
    80003e28:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003e2c:	8526                	mv	a0,s1
    80003e2e:	00000097          	auipc	ra,0x0
    80003e32:	cfc080e7          	jalr	-772(ra) # 80003b2a <iupdate>
    ip->valid = 0;
    80003e36:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003e3a:	854a                	mv	a0,s2
    80003e3c:	00001097          	auipc	ra,0x1
    80003e40:	ad8080e7          	jalr	-1320(ra) # 80004914 <releasesleep>
    acquire(&itable.lock);
    80003e44:	0001c517          	auipc	a0,0x1c
    80003e48:	1a450513          	addi	a0,a0,420 # 8001ffe8 <itable>
    80003e4c:	ffffd097          	auipc	ra,0xffffd
    80003e50:	d98080e7          	jalr	-616(ra) # 80000be4 <acquire>
    80003e54:	b741                	j	80003dd4 <iput+0x26>

0000000080003e56 <iunlockput>:
{
    80003e56:	1101                	addi	sp,sp,-32
    80003e58:	ec06                	sd	ra,24(sp)
    80003e5a:	e822                	sd	s0,16(sp)
    80003e5c:	e426                	sd	s1,8(sp)
    80003e5e:	1000                	addi	s0,sp,32
    80003e60:	84aa                	mv	s1,a0
  iunlock(ip);
    80003e62:	00000097          	auipc	ra,0x0
    80003e66:	e54080e7          	jalr	-428(ra) # 80003cb6 <iunlock>
  iput(ip);
    80003e6a:	8526                	mv	a0,s1
    80003e6c:	00000097          	auipc	ra,0x0
    80003e70:	f42080e7          	jalr	-190(ra) # 80003dae <iput>
}
    80003e74:	60e2                	ld	ra,24(sp)
    80003e76:	6442                	ld	s0,16(sp)
    80003e78:	64a2                	ld	s1,8(sp)
    80003e7a:	6105                	addi	sp,sp,32
    80003e7c:	8082                	ret

0000000080003e7e <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003e7e:	1141                	addi	sp,sp,-16
    80003e80:	e422                	sd	s0,8(sp)
    80003e82:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003e84:	411c                	lw	a5,0(a0)
    80003e86:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003e88:	415c                	lw	a5,4(a0)
    80003e8a:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003e8c:	04451783          	lh	a5,68(a0)
    80003e90:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003e94:	04a51783          	lh	a5,74(a0)
    80003e98:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003e9c:	04c56783          	lwu	a5,76(a0)
    80003ea0:	e99c                	sd	a5,16(a1)
}
    80003ea2:	6422                	ld	s0,8(sp)
    80003ea4:	0141                	addi	sp,sp,16
    80003ea6:	8082                	ret

0000000080003ea8 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003ea8:	457c                	lw	a5,76(a0)
    80003eaa:	0ed7e963          	bltu	a5,a3,80003f9c <readi+0xf4>
{
    80003eae:	7159                	addi	sp,sp,-112
    80003eb0:	f486                	sd	ra,104(sp)
    80003eb2:	f0a2                	sd	s0,96(sp)
    80003eb4:	eca6                	sd	s1,88(sp)
    80003eb6:	e8ca                	sd	s2,80(sp)
    80003eb8:	e4ce                	sd	s3,72(sp)
    80003eba:	e0d2                	sd	s4,64(sp)
    80003ebc:	fc56                	sd	s5,56(sp)
    80003ebe:	f85a                	sd	s6,48(sp)
    80003ec0:	f45e                	sd	s7,40(sp)
    80003ec2:	f062                	sd	s8,32(sp)
    80003ec4:	ec66                	sd	s9,24(sp)
    80003ec6:	e86a                	sd	s10,16(sp)
    80003ec8:	e46e                	sd	s11,8(sp)
    80003eca:	1880                	addi	s0,sp,112
    80003ecc:	8baa                	mv	s7,a0
    80003ece:	8c2e                	mv	s8,a1
    80003ed0:	8ab2                	mv	s5,a2
    80003ed2:	84b6                	mv	s1,a3
    80003ed4:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003ed6:	9f35                	addw	a4,a4,a3
    return 0;
    80003ed8:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003eda:	0ad76063          	bltu	a4,a3,80003f7a <readi+0xd2>
  if(off + n > ip->size)
    80003ede:	00e7f463          	bgeu	a5,a4,80003ee6 <readi+0x3e>
    n = ip->size - off;
    80003ee2:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003ee6:	0a0b0963          	beqz	s6,80003f98 <readi+0xf0>
    80003eea:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003eec:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003ef0:	5cfd                	li	s9,-1
    80003ef2:	a82d                	j	80003f2c <readi+0x84>
    80003ef4:	020a1d93          	slli	s11,s4,0x20
    80003ef8:	020ddd93          	srli	s11,s11,0x20
    80003efc:	05890613          	addi	a2,s2,88
    80003f00:	86ee                	mv	a3,s11
    80003f02:	963a                	add	a2,a2,a4
    80003f04:	85d6                	mv	a1,s5
    80003f06:	8562                	mv	a0,s8
    80003f08:	fffff097          	auipc	ra,0xfffff
    80003f0c:	ae0080e7          	jalr	-1312(ra) # 800029e8 <either_copyout>
    80003f10:	05950d63          	beq	a0,s9,80003f6a <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003f14:	854a                	mv	a0,s2
    80003f16:	fffff097          	auipc	ra,0xfffff
    80003f1a:	60c080e7          	jalr	1548(ra) # 80003522 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003f1e:	013a09bb          	addw	s3,s4,s3
    80003f22:	009a04bb          	addw	s1,s4,s1
    80003f26:	9aee                	add	s5,s5,s11
    80003f28:	0569f763          	bgeu	s3,s6,80003f76 <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003f2c:	000ba903          	lw	s2,0(s7)
    80003f30:	00a4d59b          	srliw	a1,s1,0xa
    80003f34:	855e                	mv	a0,s7
    80003f36:	00000097          	auipc	ra,0x0
    80003f3a:	8b0080e7          	jalr	-1872(ra) # 800037e6 <bmap>
    80003f3e:	0005059b          	sext.w	a1,a0
    80003f42:	854a                	mv	a0,s2
    80003f44:	fffff097          	auipc	ra,0xfffff
    80003f48:	4ae080e7          	jalr	1198(ra) # 800033f2 <bread>
    80003f4c:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003f4e:	3ff4f713          	andi	a4,s1,1023
    80003f52:	40ed07bb          	subw	a5,s10,a4
    80003f56:	413b06bb          	subw	a3,s6,s3
    80003f5a:	8a3e                	mv	s4,a5
    80003f5c:	2781                	sext.w	a5,a5
    80003f5e:	0006861b          	sext.w	a2,a3
    80003f62:	f8f679e3          	bgeu	a2,a5,80003ef4 <readi+0x4c>
    80003f66:	8a36                	mv	s4,a3
    80003f68:	b771                	j	80003ef4 <readi+0x4c>
      brelse(bp);
    80003f6a:	854a                	mv	a0,s2
    80003f6c:	fffff097          	auipc	ra,0xfffff
    80003f70:	5b6080e7          	jalr	1462(ra) # 80003522 <brelse>
      tot = -1;
    80003f74:	59fd                	li	s3,-1
  }
  return tot;
    80003f76:	0009851b          	sext.w	a0,s3
}
    80003f7a:	70a6                	ld	ra,104(sp)
    80003f7c:	7406                	ld	s0,96(sp)
    80003f7e:	64e6                	ld	s1,88(sp)
    80003f80:	6946                	ld	s2,80(sp)
    80003f82:	69a6                	ld	s3,72(sp)
    80003f84:	6a06                	ld	s4,64(sp)
    80003f86:	7ae2                	ld	s5,56(sp)
    80003f88:	7b42                	ld	s6,48(sp)
    80003f8a:	7ba2                	ld	s7,40(sp)
    80003f8c:	7c02                	ld	s8,32(sp)
    80003f8e:	6ce2                	ld	s9,24(sp)
    80003f90:	6d42                	ld	s10,16(sp)
    80003f92:	6da2                	ld	s11,8(sp)
    80003f94:	6165                	addi	sp,sp,112
    80003f96:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003f98:	89da                	mv	s3,s6
    80003f9a:	bff1                	j	80003f76 <readi+0xce>
    return 0;
    80003f9c:	4501                	li	a0,0
}
    80003f9e:	8082                	ret

0000000080003fa0 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003fa0:	457c                	lw	a5,76(a0)
    80003fa2:	10d7e863          	bltu	a5,a3,800040b2 <writei+0x112>
{
    80003fa6:	7159                	addi	sp,sp,-112
    80003fa8:	f486                	sd	ra,104(sp)
    80003faa:	f0a2                	sd	s0,96(sp)
    80003fac:	eca6                	sd	s1,88(sp)
    80003fae:	e8ca                	sd	s2,80(sp)
    80003fb0:	e4ce                	sd	s3,72(sp)
    80003fb2:	e0d2                	sd	s4,64(sp)
    80003fb4:	fc56                	sd	s5,56(sp)
    80003fb6:	f85a                	sd	s6,48(sp)
    80003fb8:	f45e                	sd	s7,40(sp)
    80003fba:	f062                	sd	s8,32(sp)
    80003fbc:	ec66                	sd	s9,24(sp)
    80003fbe:	e86a                	sd	s10,16(sp)
    80003fc0:	e46e                	sd	s11,8(sp)
    80003fc2:	1880                	addi	s0,sp,112
    80003fc4:	8b2a                	mv	s6,a0
    80003fc6:	8c2e                	mv	s8,a1
    80003fc8:	8ab2                	mv	s5,a2
    80003fca:	8936                	mv	s2,a3
    80003fcc:	8bba                	mv	s7,a4
  if(off > ip->size || off + n < off)
    80003fce:	00e687bb          	addw	a5,a3,a4
    80003fd2:	0ed7e263          	bltu	a5,a3,800040b6 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003fd6:	00043737          	lui	a4,0x43
    80003fda:	0ef76063          	bltu	a4,a5,800040ba <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003fde:	0c0b8863          	beqz	s7,800040ae <writei+0x10e>
    80003fe2:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003fe4:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003fe8:	5cfd                	li	s9,-1
    80003fea:	a091                	j	8000402e <writei+0x8e>
    80003fec:	02099d93          	slli	s11,s3,0x20
    80003ff0:	020ddd93          	srli	s11,s11,0x20
    80003ff4:	05848513          	addi	a0,s1,88
    80003ff8:	86ee                	mv	a3,s11
    80003ffa:	8656                	mv	a2,s5
    80003ffc:	85e2                	mv	a1,s8
    80003ffe:	953a                	add	a0,a0,a4
    80004000:	fffff097          	auipc	ra,0xfffff
    80004004:	a3e080e7          	jalr	-1474(ra) # 80002a3e <either_copyin>
    80004008:	07950263          	beq	a0,s9,8000406c <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    8000400c:	8526                	mv	a0,s1
    8000400e:	00000097          	auipc	ra,0x0
    80004012:	790080e7          	jalr	1936(ra) # 8000479e <log_write>
    brelse(bp);
    80004016:	8526                	mv	a0,s1
    80004018:	fffff097          	auipc	ra,0xfffff
    8000401c:	50a080e7          	jalr	1290(ra) # 80003522 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80004020:	01498a3b          	addw	s4,s3,s4
    80004024:	0129893b          	addw	s2,s3,s2
    80004028:	9aee                	add	s5,s5,s11
    8000402a:	057a7663          	bgeu	s4,s7,80004076 <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    8000402e:	000b2483          	lw	s1,0(s6)
    80004032:	00a9559b          	srliw	a1,s2,0xa
    80004036:	855a                	mv	a0,s6
    80004038:	fffff097          	auipc	ra,0xfffff
    8000403c:	7ae080e7          	jalr	1966(ra) # 800037e6 <bmap>
    80004040:	0005059b          	sext.w	a1,a0
    80004044:	8526                	mv	a0,s1
    80004046:	fffff097          	auipc	ra,0xfffff
    8000404a:	3ac080e7          	jalr	940(ra) # 800033f2 <bread>
    8000404e:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80004050:	3ff97713          	andi	a4,s2,1023
    80004054:	40ed07bb          	subw	a5,s10,a4
    80004058:	414b86bb          	subw	a3,s7,s4
    8000405c:	89be                	mv	s3,a5
    8000405e:	2781                	sext.w	a5,a5
    80004060:	0006861b          	sext.w	a2,a3
    80004064:	f8f674e3          	bgeu	a2,a5,80003fec <writei+0x4c>
    80004068:	89b6                	mv	s3,a3
    8000406a:	b749                	j	80003fec <writei+0x4c>
      brelse(bp);
    8000406c:	8526                	mv	a0,s1
    8000406e:	fffff097          	auipc	ra,0xfffff
    80004072:	4b4080e7          	jalr	1204(ra) # 80003522 <brelse>
  }

  if(off > ip->size)
    80004076:	04cb2783          	lw	a5,76(s6)
    8000407a:	0127f463          	bgeu	a5,s2,80004082 <writei+0xe2>
    ip->size = off;
    8000407e:	052b2623          	sw	s2,76(s6)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80004082:	855a                	mv	a0,s6
    80004084:	00000097          	auipc	ra,0x0
    80004088:	aa6080e7          	jalr	-1370(ra) # 80003b2a <iupdate>

  return tot;
    8000408c:	000a051b          	sext.w	a0,s4
}
    80004090:	70a6                	ld	ra,104(sp)
    80004092:	7406                	ld	s0,96(sp)
    80004094:	64e6                	ld	s1,88(sp)
    80004096:	6946                	ld	s2,80(sp)
    80004098:	69a6                	ld	s3,72(sp)
    8000409a:	6a06                	ld	s4,64(sp)
    8000409c:	7ae2                	ld	s5,56(sp)
    8000409e:	7b42                	ld	s6,48(sp)
    800040a0:	7ba2                	ld	s7,40(sp)
    800040a2:	7c02                	ld	s8,32(sp)
    800040a4:	6ce2                	ld	s9,24(sp)
    800040a6:	6d42                	ld	s10,16(sp)
    800040a8:	6da2                	ld	s11,8(sp)
    800040aa:	6165                	addi	sp,sp,112
    800040ac:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    800040ae:	8a5e                	mv	s4,s7
    800040b0:	bfc9                	j	80004082 <writei+0xe2>
    return -1;
    800040b2:	557d                	li	a0,-1
}
    800040b4:	8082                	ret
    return -1;
    800040b6:	557d                	li	a0,-1
    800040b8:	bfe1                	j	80004090 <writei+0xf0>
    return -1;
    800040ba:	557d                	li	a0,-1
    800040bc:	bfd1                	j	80004090 <writei+0xf0>

00000000800040be <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    800040be:	1141                	addi	sp,sp,-16
    800040c0:	e406                	sd	ra,8(sp)
    800040c2:	e022                	sd	s0,0(sp)
    800040c4:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    800040c6:	4639                	li	a2,14
    800040c8:	ffffd097          	auipc	ra,0xffffd
    800040cc:	cf0080e7          	jalr	-784(ra) # 80000db8 <strncmp>
}
    800040d0:	60a2                	ld	ra,8(sp)
    800040d2:	6402                	ld	s0,0(sp)
    800040d4:	0141                	addi	sp,sp,16
    800040d6:	8082                	ret

00000000800040d8 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    800040d8:	7139                	addi	sp,sp,-64
    800040da:	fc06                	sd	ra,56(sp)
    800040dc:	f822                	sd	s0,48(sp)
    800040de:	f426                	sd	s1,40(sp)
    800040e0:	f04a                	sd	s2,32(sp)
    800040e2:	ec4e                	sd	s3,24(sp)
    800040e4:	e852                	sd	s4,16(sp)
    800040e6:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    800040e8:	04451703          	lh	a4,68(a0)
    800040ec:	4785                	li	a5,1
    800040ee:	00f71a63          	bne	a4,a5,80004102 <dirlookup+0x2a>
    800040f2:	892a                	mv	s2,a0
    800040f4:	89ae                	mv	s3,a1
    800040f6:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    800040f8:	457c                	lw	a5,76(a0)
    800040fa:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    800040fc:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    800040fe:	e79d                	bnez	a5,8000412c <dirlookup+0x54>
    80004100:	a8a5                	j	80004178 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80004102:	00004517          	auipc	a0,0x4
    80004106:	4fe50513          	addi	a0,a0,1278 # 80008600 <syscalls+0x1b0>
    8000410a:	ffffc097          	auipc	ra,0xffffc
    8000410e:	434080e7          	jalr	1076(ra) # 8000053e <panic>
      panic("dirlookup read");
    80004112:	00004517          	auipc	a0,0x4
    80004116:	50650513          	addi	a0,a0,1286 # 80008618 <syscalls+0x1c8>
    8000411a:	ffffc097          	auipc	ra,0xffffc
    8000411e:	424080e7          	jalr	1060(ra) # 8000053e <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004122:	24c1                	addiw	s1,s1,16
    80004124:	04c92783          	lw	a5,76(s2)
    80004128:	04f4f763          	bgeu	s1,a5,80004176 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000412c:	4741                	li	a4,16
    8000412e:	86a6                	mv	a3,s1
    80004130:	fc040613          	addi	a2,s0,-64
    80004134:	4581                	li	a1,0
    80004136:	854a                	mv	a0,s2
    80004138:	00000097          	auipc	ra,0x0
    8000413c:	d70080e7          	jalr	-656(ra) # 80003ea8 <readi>
    80004140:	47c1                	li	a5,16
    80004142:	fcf518e3          	bne	a0,a5,80004112 <dirlookup+0x3a>
    if(de.inum == 0)
    80004146:	fc045783          	lhu	a5,-64(s0)
    8000414a:	dfe1                	beqz	a5,80004122 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    8000414c:	fc240593          	addi	a1,s0,-62
    80004150:	854e                	mv	a0,s3
    80004152:	00000097          	auipc	ra,0x0
    80004156:	f6c080e7          	jalr	-148(ra) # 800040be <namecmp>
    8000415a:	f561                	bnez	a0,80004122 <dirlookup+0x4a>
      if(poff)
    8000415c:	000a0463          	beqz	s4,80004164 <dirlookup+0x8c>
        *poff = off;
    80004160:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80004164:	fc045583          	lhu	a1,-64(s0)
    80004168:	00092503          	lw	a0,0(s2)
    8000416c:	fffff097          	auipc	ra,0xfffff
    80004170:	754080e7          	jalr	1876(ra) # 800038c0 <iget>
    80004174:	a011                	j	80004178 <dirlookup+0xa0>
  return 0;
    80004176:	4501                	li	a0,0
}
    80004178:	70e2                	ld	ra,56(sp)
    8000417a:	7442                	ld	s0,48(sp)
    8000417c:	74a2                	ld	s1,40(sp)
    8000417e:	7902                	ld	s2,32(sp)
    80004180:	69e2                	ld	s3,24(sp)
    80004182:	6a42                	ld	s4,16(sp)
    80004184:	6121                	addi	sp,sp,64
    80004186:	8082                	ret

0000000080004188 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80004188:	711d                	addi	sp,sp,-96
    8000418a:	ec86                	sd	ra,88(sp)
    8000418c:	e8a2                	sd	s0,80(sp)
    8000418e:	e4a6                	sd	s1,72(sp)
    80004190:	e0ca                	sd	s2,64(sp)
    80004192:	fc4e                	sd	s3,56(sp)
    80004194:	f852                	sd	s4,48(sp)
    80004196:	f456                	sd	s5,40(sp)
    80004198:	f05a                	sd	s6,32(sp)
    8000419a:	ec5e                	sd	s7,24(sp)
    8000419c:	e862                	sd	s8,16(sp)
    8000419e:	e466                	sd	s9,8(sp)
    800041a0:	1080                	addi	s0,sp,96
    800041a2:	84aa                	mv	s1,a0
    800041a4:	8b2e                	mv	s6,a1
    800041a6:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    800041a8:	00054703          	lbu	a4,0(a0)
    800041ac:	02f00793          	li	a5,47
    800041b0:	02f70363          	beq	a4,a5,800041d6 <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    800041b4:	ffffe097          	auipc	ra,0xffffe
    800041b8:	814080e7          	jalr	-2028(ra) # 800019c8 <myproc>
    800041bc:	17053503          	ld	a0,368(a0)
    800041c0:	00000097          	auipc	ra,0x0
    800041c4:	9f6080e7          	jalr	-1546(ra) # 80003bb6 <idup>
    800041c8:	89aa                	mv	s3,a0
  while(*path == '/')
    800041ca:	02f00913          	li	s2,47
  len = path - s;
    800041ce:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    800041d0:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    800041d2:	4c05                	li	s8,1
    800041d4:	a865                	j	8000428c <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    800041d6:	4585                	li	a1,1
    800041d8:	4505                	li	a0,1
    800041da:	fffff097          	auipc	ra,0xfffff
    800041de:	6e6080e7          	jalr	1766(ra) # 800038c0 <iget>
    800041e2:	89aa                	mv	s3,a0
    800041e4:	b7dd                	j	800041ca <namex+0x42>
      iunlockput(ip);
    800041e6:	854e                	mv	a0,s3
    800041e8:	00000097          	auipc	ra,0x0
    800041ec:	c6e080e7          	jalr	-914(ra) # 80003e56 <iunlockput>
      return 0;
    800041f0:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    800041f2:	854e                	mv	a0,s3
    800041f4:	60e6                	ld	ra,88(sp)
    800041f6:	6446                	ld	s0,80(sp)
    800041f8:	64a6                	ld	s1,72(sp)
    800041fa:	6906                	ld	s2,64(sp)
    800041fc:	79e2                	ld	s3,56(sp)
    800041fe:	7a42                	ld	s4,48(sp)
    80004200:	7aa2                	ld	s5,40(sp)
    80004202:	7b02                	ld	s6,32(sp)
    80004204:	6be2                	ld	s7,24(sp)
    80004206:	6c42                	ld	s8,16(sp)
    80004208:	6ca2                	ld	s9,8(sp)
    8000420a:	6125                	addi	sp,sp,96
    8000420c:	8082                	ret
      iunlock(ip);
    8000420e:	854e                	mv	a0,s3
    80004210:	00000097          	auipc	ra,0x0
    80004214:	aa6080e7          	jalr	-1370(ra) # 80003cb6 <iunlock>
      return ip;
    80004218:	bfe9                	j	800041f2 <namex+0x6a>
      iunlockput(ip);
    8000421a:	854e                	mv	a0,s3
    8000421c:	00000097          	auipc	ra,0x0
    80004220:	c3a080e7          	jalr	-966(ra) # 80003e56 <iunlockput>
      return 0;
    80004224:	89d2                	mv	s3,s4
    80004226:	b7f1                	j	800041f2 <namex+0x6a>
  len = path - s;
    80004228:	40b48633          	sub	a2,s1,a1
    8000422c:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    80004230:	094cd463          	bge	s9,s4,800042b8 <namex+0x130>
    memmove(name, s, DIRSIZ);
    80004234:	4639                	li	a2,14
    80004236:	8556                	mv	a0,s5
    80004238:	ffffd097          	auipc	ra,0xffffd
    8000423c:	b08080e7          	jalr	-1272(ra) # 80000d40 <memmove>
  while(*path == '/')
    80004240:	0004c783          	lbu	a5,0(s1)
    80004244:	01279763          	bne	a5,s2,80004252 <namex+0xca>
    path++;
    80004248:	0485                	addi	s1,s1,1
  while(*path == '/')
    8000424a:	0004c783          	lbu	a5,0(s1)
    8000424e:	ff278de3          	beq	a5,s2,80004248 <namex+0xc0>
    ilock(ip);
    80004252:	854e                	mv	a0,s3
    80004254:	00000097          	auipc	ra,0x0
    80004258:	9a0080e7          	jalr	-1632(ra) # 80003bf4 <ilock>
    if(ip->type != T_DIR){
    8000425c:	04499783          	lh	a5,68(s3)
    80004260:	f98793e3          	bne	a5,s8,800041e6 <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80004264:	000b0563          	beqz	s6,8000426e <namex+0xe6>
    80004268:	0004c783          	lbu	a5,0(s1)
    8000426c:	d3cd                	beqz	a5,8000420e <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    8000426e:	865e                	mv	a2,s7
    80004270:	85d6                	mv	a1,s5
    80004272:	854e                	mv	a0,s3
    80004274:	00000097          	auipc	ra,0x0
    80004278:	e64080e7          	jalr	-412(ra) # 800040d8 <dirlookup>
    8000427c:	8a2a                	mv	s4,a0
    8000427e:	dd51                	beqz	a0,8000421a <namex+0x92>
    iunlockput(ip);
    80004280:	854e                	mv	a0,s3
    80004282:	00000097          	auipc	ra,0x0
    80004286:	bd4080e7          	jalr	-1068(ra) # 80003e56 <iunlockput>
    ip = next;
    8000428a:	89d2                	mv	s3,s4
  while(*path == '/')
    8000428c:	0004c783          	lbu	a5,0(s1)
    80004290:	05279763          	bne	a5,s2,800042de <namex+0x156>
    path++;
    80004294:	0485                	addi	s1,s1,1
  while(*path == '/')
    80004296:	0004c783          	lbu	a5,0(s1)
    8000429a:	ff278de3          	beq	a5,s2,80004294 <namex+0x10c>
  if(*path == 0)
    8000429e:	c79d                	beqz	a5,800042cc <namex+0x144>
    path++;
    800042a0:	85a6                	mv	a1,s1
  len = path - s;
    800042a2:	8a5e                	mv	s4,s7
    800042a4:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    800042a6:	01278963          	beq	a5,s2,800042b8 <namex+0x130>
    800042aa:	dfbd                	beqz	a5,80004228 <namex+0xa0>
    path++;
    800042ac:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    800042ae:	0004c783          	lbu	a5,0(s1)
    800042b2:	ff279ce3          	bne	a5,s2,800042aa <namex+0x122>
    800042b6:	bf8d                	j	80004228 <namex+0xa0>
    memmove(name, s, len);
    800042b8:	2601                	sext.w	a2,a2
    800042ba:	8556                	mv	a0,s5
    800042bc:	ffffd097          	auipc	ra,0xffffd
    800042c0:	a84080e7          	jalr	-1404(ra) # 80000d40 <memmove>
    name[len] = 0;
    800042c4:	9a56                	add	s4,s4,s5
    800042c6:	000a0023          	sb	zero,0(s4)
    800042ca:	bf9d                	j	80004240 <namex+0xb8>
  if(nameiparent){
    800042cc:	f20b03e3          	beqz	s6,800041f2 <namex+0x6a>
    iput(ip);
    800042d0:	854e                	mv	a0,s3
    800042d2:	00000097          	auipc	ra,0x0
    800042d6:	adc080e7          	jalr	-1316(ra) # 80003dae <iput>
    return 0;
    800042da:	4981                	li	s3,0
    800042dc:	bf19                	j	800041f2 <namex+0x6a>
  if(*path == 0)
    800042de:	d7fd                	beqz	a5,800042cc <namex+0x144>
  while(*path != '/' && *path != 0)
    800042e0:	0004c783          	lbu	a5,0(s1)
    800042e4:	85a6                	mv	a1,s1
    800042e6:	b7d1                	j	800042aa <namex+0x122>

00000000800042e8 <dirlink>:
{
    800042e8:	7139                	addi	sp,sp,-64
    800042ea:	fc06                	sd	ra,56(sp)
    800042ec:	f822                	sd	s0,48(sp)
    800042ee:	f426                	sd	s1,40(sp)
    800042f0:	f04a                	sd	s2,32(sp)
    800042f2:	ec4e                	sd	s3,24(sp)
    800042f4:	e852                	sd	s4,16(sp)
    800042f6:	0080                	addi	s0,sp,64
    800042f8:	892a                	mv	s2,a0
    800042fa:	8a2e                	mv	s4,a1
    800042fc:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    800042fe:	4601                	li	a2,0
    80004300:	00000097          	auipc	ra,0x0
    80004304:	dd8080e7          	jalr	-552(ra) # 800040d8 <dirlookup>
    80004308:	e93d                	bnez	a0,8000437e <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000430a:	04c92483          	lw	s1,76(s2)
    8000430e:	c49d                	beqz	s1,8000433c <dirlink+0x54>
    80004310:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004312:	4741                	li	a4,16
    80004314:	86a6                	mv	a3,s1
    80004316:	fc040613          	addi	a2,s0,-64
    8000431a:	4581                	li	a1,0
    8000431c:	854a                	mv	a0,s2
    8000431e:	00000097          	auipc	ra,0x0
    80004322:	b8a080e7          	jalr	-1142(ra) # 80003ea8 <readi>
    80004326:	47c1                	li	a5,16
    80004328:	06f51163          	bne	a0,a5,8000438a <dirlink+0xa2>
    if(de.inum == 0)
    8000432c:	fc045783          	lhu	a5,-64(s0)
    80004330:	c791                	beqz	a5,8000433c <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004332:	24c1                	addiw	s1,s1,16
    80004334:	04c92783          	lw	a5,76(s2)
    80004338:	fcf4ede3          	bltu	s1,a5,80004312 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    8000433c:	4639                	li	a2,14
    8000433e:	85d2                	mv	a1,s4
    80004340:	fc240513          	addi	a0,s0,-62
    80004344:	ffffd097          	auipc	ra,0xffffd
    80004348:	ab0080e7          	jalr	-1360(ra) # 80000df4 <strncpy>
  de.inum = inum;
    8000434c:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004350:	4741                	li	a4,16
    80004352:	86a6                	mv	a3,s1
    80004354:	fc040613          	addi	a2,s0,-64
    80004358:	4581                	li	a1,0
    8000435a:	854a                	mv	a0,s2
    8000435c:	00000097          	auipc	ra,0x0
    80004360:	c44080e7          	jalr	-956(ra) # 80003fa0 <writei>
    80004364:	872a                	mv	a4,a0
    80004366:	47c1                	li	a5,16
  return 0;
    80004368:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000436a:	02f71863          	bne	a4,a5,8000439a <dirlink+0xb2>
}
    8000436e:	70e2                	ld	ra,56(sp)
    80004370:	7442                	ld	s0,48(sp)
    80004372:	74a2                	ld	s1,40(sp)
    80004374:	7902                	ld	s2,32(sp)
    80004376:	69e2                	ld	s3,24(sp)
    80004378:	6a42                	ld	s4,16(sp)
    8000437a:	6121                	addi	sp,sp,64
    8000437c:	8082                	ret
    iput(ip);
    8000437e:	00000097          	auipc	ra,0x0
    80004382:	a30080e7          	jalr	-1488(ra) # 80003dae <iput>
    return -1;
    80004386:	557d                	li	a0,-1
    80004388:	b7dd                	j	8000436e <dirlink+0x86>
      panic("dirlink read");
    8000438a:	00004517          	auipc	a0,0x4
    8000438e:	29e50513          	addi	a0,a0,670 # 80008628 <syscalls+0x1d8>
    80004392:	ffffc097          	auipc	ra,0xffffc
    80004396:	1ac080e7          	jalr	428(ra) # 8000053e <panic>
    panic("dirlink");
    8000439a:	00004517          	auipc	a0,0x4
    8000439e:	39e50513          	addi	a0,a0,926 # 80008738 <syscalls+0x2e8>
    800043a2:	ffffc097          	auipc	ra,0xffffc
    800043a6:	19c080e7          	jalr	412(ra) # 8000053e <panic>

00000000800043aa <namei>:

struct inode*
namei(char *path)
{
    800043aa:	1101                	addi	sp,sp,-32
    800043ac:	ec06                	sd	ra,24(sp)
    800043ae:	e822                	sd	s0,16(sp)
    800043b0:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    800043b2:	fe040613          	addi	a2,s0,-32
    800043b6:	4581                	li	a1,0
    800043b8:	00000097          	auipc	ra,0x0
    800043bc:	dd0080e7          	jalr	-560(ra) # 80004188 <namex>
}
    800043c0:	60e2                	ld	ra,24(sp)
    800043c2:	6442                	ld	s0,16(sp)
    800043c4:	6105                	addi	sp,sp,32
    800043c6:	8082                	ret

00000000800043c8 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    800043c8:	1141                	addi	sp,sp,-16
    800043ca:	e406                	sd	ra,8(sp)
    800043cc:	e022                	sd	s0,0(sp)
    800043ce:	0800                	addi	s0,sp,16
    800043d0:	862e                	mv	a2,a1
  return namex(path, 1, name);
    800043d2:	4585                	li	a1,1
    800043d4:	00000097          	auipc	ra,0x0
    800043d8:	db4080e7          	jalr	-588(ra) # 80004188 <namex>
}
    800043dc:	60a2                	ld	ra,8(sp)
    800043de:	6402                	ld	s0,0(sp)
    800043e0:	0141                	addi	sp,sp,16
    800043e2:	8082                	ret

00000000800043e4 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    800043e4:	1101                	addi	sp,sp,-32
    800043e6:	ec06                	sd	ra,24(sp)
    800043e8:	e822                	sd	s0,16(sp)
    800043ea:	e426                	sd	s1,8(sp)
    800043ec:	e04a                	sd	s2,0(sp)
    800043ee:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    800043f0:	0001d917          	auipc	s2,0x1d
    800043f4:	6a090913          	addi	s2,s2,1696 # 80021a90 <log>
    800043f8:	01892583          	lw	a1,24(s2)
    800043fc:	02892503          	lw	a0,40(s2)
    80004400:	fffff097          	auipc	ra,0xfffff
    80004404:	ff2080e7          	jalr	-14(ra) # 800033f2 <bread>
    80004408:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    8000440a:	02c92683          	lw	a3,44(s2)
    8000440e:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80004410:	02d05763          	blez	a3,8000443e <write_head+0x5a>
    80004414:	0001d797          	auipc	a5,0x1d
    80004418:	6ac78793          	addi	a5,a5,1708 # 80021ac0 <log+0x30>
    8000441c:	05c50713          	addi	a4,a0,92
    80004420:	36fd                	addiw	a3,a3,-1
    80004422:	1682                	slli	a3,a3,0x20
    80004424:	9281                	srli	a3,a3,0x20
    80004426:	068a                	slli	a3,a3,0x2
    80004428:	0001d617          	auipc	a2,0x1d
    8000442c:	69c60613          	addi	a2,a2,1692 # 80021ac4 <log+0x34>
    80004430:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80004432:	4390                	lw	a2,0(a5)
    80004434:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004436:	0791                	addi	a5,a5,4
    80004438:	0711                	addi	a4,a4,4
    8000443a:	fed79ce3          	bne	a5,a3,80004432 <write_head+0x4e>
  }
  bwrite(buf);
    8000443e:	8526                	mv	a0,s1
    80004440:	fffff097          	auipc	ra,0xfffff
    80004444:	0a4080e7          	jalr	164(ra) # 800034e4 <bwrite>
  brelse(buf);
    80004448:	8526                	mv	a0,s1
    8000444a:	fffff097          	auipc	ra,0xfffff
    8000444e:	0d8080e7          	jalr	216(ra) # 80003522 <brelse>
}
    80004452:	60e2                	ld	ra,24(sp)
    80004454:	6442                	ld	s0,16(sp)
    80004456:	64a2                	ld	s1,8(sp)
    80004458:	6902                	ld	s2,0(sp)
    8000445a:	6105                	addi	sp,sp,32
    8000445c:	8082                	ret

000000008000445e <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    8000445e:	0001d797          	auipc	a5,0x1d
    80004462:	65e7a783          	lw	a5,1630(a5) # 80021abc <log+0x2c>
    80004466:	0af05d63          	blez	a5,80004520 <install_trans+0xc2>
{
    8000446a:	7139                	addi	sp,sp,-64
    8000446c:	fc06                	sd	ra,56(sp)
    8000446e:	f822                	sd	s0,48(sp)
    80004470:	f426                	sd	s1,40(sp)
    80004472:	f04a                	sd	s2,32(sp)
    80004474:	ec4e                	sd	s3,24(sp)
    80004476:	e852                	sd	s4,16(sp)
    80004478:	e456                	sd	s5,8(sp)
    8000447a:	e05a                	sd	s6,0(sp)
    8000447c:	0080                	addi	s0,sp,64
    8000447e:	8b2a                	mv	s6,a0
    80004480:	0001da97          	auipc	s5,0x1d
    80004484:	640a8a93          	addi	s5,s5,1600 # 80021ac0 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004488:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    8000448a:	0001d997          	auipc	s3,0x1d
    8000448e:	60698993          	addi	s3,s3,1542 # 80021a90 <log>
    80004492:	a035                	j	800044be <install_trans+0x60>
      bunpin(dbuf);
    80004494:	8526                	mv	a0,s1
    80004496:	fffff097          	auipc	ra,0xfffff
    8000449a:	166080e7          	jalr	358(ra) # 800035fc <bunpin>
    brelse(lbuf);
    8000449e:	854a                	mv	a0,s2
    800044a0:	fffff097          	auipc	ra,0xfffff
    800044a4:	082080e7          	jalr	130(ra) # 80003522 <brelse>
    brelse(dbuf);
    800044a8:	8526                	mv	a0,s1
    800044aa:	fffff097          	auipc	ra,0xfffff
    800044ae:	078080e7          	jalr	120(ra) # 80003522 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800044b2:	2a05                	addiw	s4,s4,1
    800044b4:	0a91                	addi	s5,s5,4
    800044b6:	02c9a783          	lw	a5,44(s3)
    800044ba:	04fa5963          	bge	s4,a5,8000450c <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800044be:	0189a583          	lw	a1,24(s3)
    800044c2:	014585bb          	addw	a1,a1,s4
    800044c6:	2585                	addiw	a1,a1,1
    800044c8:	0289a503          	lw	a0,40(s3)
    800044cc:	fffff097          	auipc	ra,0xfffff
    800044d0:	f26080e7          	jalr	-218(ra) # 800033f2 <bread>
    800044d4:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    800044d6:	000aa583          	lw	a1,0(s5)
    800044da:	0289a503          	lw	a0,40(s3)
    800044de:	fffff097          	auipc	ra,0xfffff
    800044e2:	f14080e7          	jalr	-236(ra) # 800033f2 <bread>
    800044e6:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    800044e8:	40000613          	li	a2,1024
    800044ec:	05890593          	addi	a1,s2,88
    800044f0:	05850513          	addi	a0,a0,88
    800044f4:	ffffd097          	auipc	ra,0xffffd
    800044f8:	84c080e7          	jalr	-1972(ra) # 80000d40 <memmove>
    bwrite(dbuf);  // write dst to disk
    800044fc:	8526                	mv	a0,s1
    800044fe:	fffff097          	auipc	ra,0xfffff
    80004502:	fe6080e7          	jalr	-26(ra) # 800034e4 <bwrite>
    if(recovering == 0)
    80004506:	f80b1ce3          	bnez	s6,8000449e <install_trans+0x40>
    8000450a:	b769                	j	80004494 <install_trans+0x36>
}
    8000450c:	70e2                	ld	ra,56(sp)
    8000450e:	7442                	ld	s0,48(sp)
    80004510:	74a2                	ld	s1,40(sp)
    80004512:	7902                	ld	s2,32(sp)
    80004514:	69e2                	ld	s3,24(sp)
    80004516:	6a42                	ld	s4,16(sp)
    80004518:	6aa2                	ld	s5,8(sp)
    8000451a:	6b02                	ld	s6,0(sp)
    8000451c:	6121                	addi	sp,sp,64
    8000451e:	8082                	ret
    80004520:	8082                	ret

0000000080004522 <initlog>:
{
    80004522:	7179                	addi	sp,sp,-48
    80004524:	f406                	sd	ra,40(sp)
    80004526:	f022                	sd	s0,32(sp)
    80004528:	ec26                	sd	s1,24(sp)
    8000452a:	e84a                	sd	s2,16(sp)
    8000452c:	e44e                	sd	s3,8(sp)
    8000452e:	1800                	addi	s0,sp,48
    80004530:	892a                	mv	s2,a0
    80004532:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80004534:	0001d497          	auipc	s1,0x1d
    80004538:	55c48493          	addi	s1,s1,1372 # 80021a90 <log>
    8000453c:	00004597          	auipc	a1,0x4
    80004540:	0fc58593          	addi	a1,a1,252 # 80008638 <syscalls+0x1e8>
    80004544:	8526                	mv	a0,s1
    80004546:	ffffc097          	auipc	ra,0xffffc
    8000454a:	60e080e7          	jalr	1550(ra) # 80000b54 <initlock>
  log.start = sb->logstart;
    8000454e:	0149a583          	lw	a1,20(s3)
    80004552:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80004554:	0109a783          	lw	a5,16(s3)
    80004558:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    8000455a:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    8000455e:	854a                	mv	a0,s2
    80004560:	fffff097          	auipc	ra,0xfffff
    80004564:	e92080e7          	jalr	-366(ra) # 800033f2 <bread>
  log.lh.n = lh->n;
    80004568:	4d3c                	lw	a5,88(a0)
    8000456a:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    8000456c:	02f05563          	blez	a5,80004596 <initlog+0x74>
    80004570:	05c50713          	addi	a4,a0,92
    80004574:	0001d697          	auipc	a3,0x1d
    80004578:	54c68693          	addi	a3,a3,1356 # 80021ac0 <log+0x30>
    8000457c:	37fd                	addiw	a5,a5,-1
    8000457e:	1782                	slli	a5,a5,0x20
    80004580:	9381                	srli	a5,a5,0x20
    80004582:	078a                	slli	a5,a5,0x2
    80004584:	06050613          	addi	a2,a0,96
    80004588:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    8000458a:	4310                	lw	a2,0(a4)
    8000458c:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    8000458e:	0711                	addi	a4,a4,4
    80004590:	0691                	addi	a3,a3,4
    80004592:	fef71ce3          	bne	a4,a5,8000458a <initlog+0x68>
  brelse(buf);
    80004596:	fffff097          	auipc	ra,0xfffff
    8000459a:	f8c080e7          	jalr	-116(ra) # 80003522 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    8000459e:	4505                	li	a0,1
    800045a0:	00000097          	auipc	ra,0x0
    800045a4:	ebe080e7          	jalr	-322(ra) # 8000445e <install_trans>
  log.lh.n = 0;
    800045a8:	0001d797          	auipc	a5,0x1d
    800045ac:	5007aa23          	sw	zero,1300(a5) # 80021abc <log+0x2c>
  write_head(); // clear the log
    800045b0:	00000097          	auipc	ra,0x0
    800045b4:	e34080e7          	jalr	-460(ra) # 800043e4 <write_head>
}
    800045b8:	70a2                	ld	ra,40(sp)
    800045ba:	7402                	ld	s0,32(sp)
    800045bc:	64e2                	ld	s1,24(sp)
    800045be:	6942                	ld	s2,16(sp)
    800045c0:	69a2                	ld	s3,8(sp)
    800045c2:	6145                	addi	sp,sp,48
    800045c4:	8082                	ret

00000000800045c6 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    800045c6:	1101                	addi	sp,sp,-32
    800045c8:	ec06                	sd	ra,24(sp)
    800045ca:	e822                	sd	s0,16(sp)
    800045cc:	e426                	sd	s1,8(sp)
    800045ce:	e04a                	sd	s2,0(sp)
    800045d0:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    800045d2:	0001d517          	auipc	a0,0x1d
    800045d6:	4be50513          	addi	a0,a0,1214 # 80021a90 <log>
    800045da:	ffffc097          	auipc	ra,0xffffc
    800045de:	60a080e7          	jalr	1546(ra) # 80000be4 <acquire>
  while(1){
    if(log.committing){
    800045e2:	0001d497          	auipc	s1,0x1d
    800045e6:	4ae48493          	addi	s1,s1,1198 # 80021a90 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800045ea:	4979                	li	s2,30
    800045ec:	a039                	j	800045fa <begin_op+0x34>
      sleep(&log, &log.lock);
    800045ee:	85a6                	mv	a1,s1
    800045f0:	8526                	mv	a0,s1
    800045f2:	ffffe097          	auipc	ra,0xffffe
    800045f6:	e50080e7          	jalr	-432(ra) # 80002442 <sleep>
    if(log.committing){
    800045fa:	50dc                	lw	a5,36(s1)
    800045fc:	fbed                	bnez	a5,800045ee <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800045fe:	509c                	lw	a5,32(s1)
    80004600:	0017871b          	addiw	a4,a5,1
    80004604:	0007069b          	sext.w	a3,a4
    80004608:	0027179b          	slliw	a5,a4,0x2
    8000460c:	9fb9                	addw	a5,a5,a4
    8000460e:	0017979b          	slliw	a5,a5,0x1
    80004612:	54d8                	lw	a4,44(s1)
    80004614:	9fb9                	addw	a5,a5,a4
    80004616:	00f95963          	bge	s2,a5,80004628 <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    8000461a:	85a6                	mv	a1,s1
    8000461c:	8526                	mv	a0,s1
    8000461e:	ffffe097          	auipc	ra,0xffffe
    80004622:	e24080e7          	jalr	-476(ra) # 80002442 <sleep>
    80004626:	bfd1                	j	800045fa <begin_op+0x34>
    } else {
      log.outstanding += 1;
    80004628:	0001d517          	auipc	a0,0x1d
    8000462c:	46850513          	addi	a0,a0,1128 # 80021a90 <log>
    80004630:	d114                	sw	a3,32(a0)
      release(&log.lock);
    80004632:	ffffc097          	auipc	ra,0xffffc
    80004636:	666080e7          	jalr	1638(ra) # 80000c98 <release>
      break;
    }
  }
}
    8000463a:	60e2                	ld	ra,24(sp)
    8000463c:	6442                	ld	s0,16(sp)
    8000463e:	64a2                	ld	s1,8(sp)
    80004640:	6902                	ld	s2,0(sp)
    80004642:	6105                	addi	sp,sp,32
    80004644:	8082                	ret

0000000080004646 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80004646:	7139                	addi	sp,sp,-64
    80004648:	fc06                	sd	ra,56(sp)
    8000464a:	f822                	sd	s0,48(sp)
    8000464c:	f426                	sd	s1,40(sp)
    8000464e:	f04a                	sd	s2,32(sp)
    80004650:	ec4e                	sd	s3,24(sp)
    80004652:	e852                	sd	s4,16(sp)
    80004654:	e456                	sd	s5,8(sp)
    80004656:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80004658:	0001d497          	auipc	s1,0x1d
    8000465c:	43848493          	addi	s1,s1,1080 # 80021a90 <log>
    80004660:	8526                	mv	a0,s1
    80004662:	ffffc097          	auipc	ra,0xffffc
    80004666:	582080e7          	jalr	1410(ra) # 80000be4 <acquire>
  log.outstanding -= 1;
    8000466a:	509c                	lw	a5,32(s1)
    8000466c:	37fd                	addiw	a5,a5,-1
    8000466e:	0007891b          	sext.w	s2,a5
    80004672:	d09c                	sw	a5,32(s1)
  if(log.committing)
    80004674:	50dc                	lw	a5,36(s1)
    80004676:	efb9                	bnez	a5,800046d4 <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    80004678:	06091663          	bnez	s2,800046e4 <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    8000467c:	0001d497          	auipc	s1,0x1d
    80004680:	41448493          	addi	s1,s1,1044 # 80021a90 <log>
    80004684:	4785                	li	a5,1
    80004686:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    80004688:	8526                	mv	a0,s1
    8000468a:	ffffc097          	auipc	ra,0xffffc
    8000468e:	60e080e7          	jalr	1550(ra) # 80000c98 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    80004692:	54dc                	lw	a5,44(s1)
    80004694:	06f04763          	bgtz	a5,80004702 <end_op+0xbc>
    acquire(&log.lock);
    80004698:	0001d497          	auipc	s1,0x1d
    8000469c:	3f848493          	addi	s1,s1,1016 # 80021a90 <log>
    800046a0:	8526                	mv	a0,s1
    800046a2:	ffffc097          	auipc	ra,0xffffc
    800046a6:	542080e7          	jalr	1346(ra) # 80000be4 <acquire>
    log.committing = 0;
    800046aa:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    800046ae:	8526                	mv	a0,s1
    800046b0:	ffffe097          	auipc	ra,0xffffe
    800046b4:	f52080e7          	jalr	-174(ra) # 80002602 <wakeup>
    release(&log.lock);
    800046b8:	8526                	mv	a0,s1
    800046ba:	ffffc097          	auipc	ra,0xffffc
    800046be:	5de080e7          	jalr	1502(ra) # 80000c98 <release>
}
    800046c2:	70e2                	ld	ra,56(sp)
    800046c4:	7442                	ld	s0,48(sp)
    800046c6:	74a2                	ld	s1,40(sp)
    800046c8:	7902                	ld	s2,32(sp)
    800046ca:	69e2                	ld	s3,24(sp)
    800046cc:	6a42                	ld	s4,16(sp)
    800046ce:	6aa2                	ld	s5,8(sp)
    800046d0:	6121                	addi	sp,sp,64
    800046d2:	8082                	ret
    panic("log.committing");
    800046d4:	00004517          	auipc	a0,0x4
    800046d8:	f6c50513          	addi	a0,a0,-148 # 80008640 <syscalls+0x1f0>
    800046dc:	ffffc097          	auipc	ra,0xffffc
    800046e0:	e62080e7          	jalr	-414(ra) # 8000053e <panic>
    wakeup(&log);
    800046e4:	0001d497          	auipc	s1,0x1d
    800046e8:	3ac48493          	addi	s1,s1,940 # 80021a90 <log>
    800046ec:	8526                	mv	a0,s1
    800046ee:	ffffe097          	auipc	ra,0xffffe
    800046f2:	f14080e7          	jalr	-236(ra) # 80002602 <wakeup>
  release(&log.lock);
    800046f6:	8526                	mv	a0,s1
    800046f8:	ffffc097          	auipc	ra,0xffffc
    800046fc:	5a0080e7          	jalr	1440(ra) # 80000c98 <release>
  if(do_commit){
    80004700:	b7c9                	j	800046c2 <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004702:	0001da97          	auipc	s5,0x1d
    80004706:	3bea8a93          	addi	s5,s5,958 # 80021ac0 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    8000470a:	0001da17          	auipc	s4,0x1d
    8000470e:	386a0a13          	addi	s4,s4,902 # 80021a90 <log>
    80004712:	018a2583          	lw	a1,24(s4)
    80004716:	012585bb          	addw	a1,a1,s2
    8000471a:	2585                	addiw	a1,a1,1
    8000471c:	028a2503          	lw	a0,40(s4)
    80004720:	fffff097          	auipc	ra,0xfffff
    80004724:	cd2080e7          	jalr	-814(ra) # 800033f2 <bread>
    80004728:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    8000472a:	000aa583          	lw	a1,0(s5)
    8000472e:	028a2503          	lw	a0,40(s4)
    80004732:	fffff097          	auipc	ra,0xfffff
    80004736:	cc0080e7          	jalr	-832(ra) # 800033f2 <bread>
    8000473a:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    8000473c:	40000613          	li	a2,1024
    80004740:	05850593          	addi	a1,a0,88
    80004744:	05848513          	addi	a0,s1,88
    80004748:	ffffc097          	auipc	ra,0xffffc
    8000474c:	5f8080e7          	jalr	1528(ra) # 80000d40 <memmove>
    bwrite(to);  // write the log
    80004750:	8526                	mv	a0,s1
    80004752:	fffff097          	auipc	ra,0xfffff
    80004756:	d92080e7          	jalr	-622(ra) # 800034e4 <bwrite>
    brelse(from);
    8000475a:	854e                	mv	a0,s3
    8000475c:	fffff097          	auipc	ra,0xfffff
    80004760:	dc6080e7          	jalr	-570(ra) # 80003522 <brelse>
    brelse(to);
    80004764:	8526                	mv	a0,s1
    80004766:	fffff097          	auipc	ra,0xfffff
    8000476a:	dbc080e7          	jalr	-580(ra) # 80003522 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000476e:	2905                	addiw	s2,s2,1
    80004770:	0a91                	addi	s5,s5,4
    80004772:	02ca2783          	lw	a5,44(s4)
    80004776:	f8f94ee3          	blt	s2,a5,80004712 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    8000477a:	00000097          	auipc	ra,0x0
    8000477e:	c6a080e7          	jalr	-918(ra) # 800043e4 <write_head>
    install_trans(0); // Now install writes to home locations
    80004782:	4501                	li	a0,0
    80004784:	00000097          	auipc	ra,0x0
    80004788:	cda080e7          	jalr	-806(ra) # 8000445e <install_trans>
    log.lh.n = 0;
    8000478c:	0001d797          	auipc	a5,0x1d
    80004790:	3207a823          	sw	zero,816(a5) # 80021abc <log+0x2c>
    write_head();    // Erase the transaction from the log
    80004794:	00000097          	auipc	ra,0x0
    80004798:	c50080e7          	jalr	-944(ra) # 800043e4 <write_head>
    8000479c:	bdf5                	j	80004698 <end_op+0x52>

000000008000479e <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    8000479e:	1101                	addi	sp,sp,-32
    800047a0:	ec06                	sd	ra,24(sp)
    800047a2:	e822                	sd	s0,16(sp)
    800047a4:	e426                	sd	s1,8(sp)
    800047a6:	e04a                	sd	s2,0(sp)
    800047a8:	1000                	addi	s0,sp,32
    800047aa:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    800047ac:	0001d917          	auipc	s2,0x1d
    800047b0:	2e490913          	addi	s2,s2,740 # 80021a90 <log>
    800047b4:	854a                	mv	a0,s2
    800047b6:	ffffc097          	auipc	ra,0xffffc
    800047ba:	42e080e7          	jalr	1070(ra) # 80000be4 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    800047be:	02c92603          	lw	a2,44(s2)
    800047c2:	47f5                	li	a5,29
    800047c4:	06c7c563          	blt	a5,a2,8000482e <log_write+0x90>
    800047c8:	0001d797          	auipc	a5,0x1d
    800047cc:	2e47a783          	lw	a5,740(a5) # 80021aac <log+0x1c>
    800047d0:	37fd                	addiw	a5,a5,-1
    800047d2:	04f65e63          	bge	a2,a5,8000482e <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    800047d6:	0001d797          	auipc	a5,0x1d
    800047da:	2da7a783          	lw	a5,730(a5) # 80021ab0 <log+0x20>
    800047de:	06f05063          	blez	a5,8000483e <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    800047e2:	4781                	li	a5,0
    800047e4:	06c05563          	blez	a2,8000484e <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    800047e8:	44cc                	lw	a1,12(s1)
    800047ea:	0001d717          	auipc	a4,0x1d
    800047ee:	2d670713          	addi	a4,a4,726 # 80021ac0 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    800047f2:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    800047f4:	4314                	lw	a3,0(a4)
    800047f6:	04b68c63          	beq	a3,a1,8000484e <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    800047fa:	2785                	addiw	a5,a5,1
    800047fc:	0711                	addi	a4,a4,4
    800047fe:	fef61be3          	bne	a2,a5,800047f4 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004802:	0621                	addi	a2,a2,8
    80004804:	060a                	slli	a2,a2,0x2
    80004806:	0001d797          	auipc	a5,0x1d
    8000480a:	28a78793          	addi	a5,a5,650 # 80021a90 <log>
    8000480e:	963e                	add	a2,a2,a5
    80004810:	44dc                	lw	a5,12(s1)
    80004812:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004814:	8526                	mv	a0,s1
    80004816:	fffff097          	auipc	ra,0xfffff
    8000481a:	daa080e7          	jalr	-598(ra) # 800035c0 <bpin>
    log.lh.n++;
    8000481e:	0001d717          	auipc	a4,0x1d
    80004822:	27270713          	addi	a4,a4,626 # 80021a90 <log>
    80004826:	575c                	lw	a5,44(a4)
    80004828:	2785                	addiw	a5,a5,1
    8000482a:	d75c                	sw	a5,44(a4)
    8000482c:	a835                	j	80004868 <log_write+0xca>
    panic("too big a transaction");
    8000482e:	00004517          	auipc	a0,0x4
    80004832:	e2250513          	addi	a0,a0,-478 # 80008650 <syscalls+0x200>
    80004836:	ffffc097          	auipc	ra,0xffffc
    8000483a:	d08080e7          	jalr	-760(ra) # 8000053e <panic>
    panic("log_write outside of trans");
    8000483e:	00004517          	auipc	a0,0x4
    80004842:	e2a50513          	addi	a0,a0,-470 # 80008668 <syscalls+0x218>
    80004846:	ffffc097          	auipc	ra,0xffffc
    8000484a:	cf8080e7          	jalr	-776(ra) # 8000053e <panic>
  log.lh.block[i] = b->blockno;
    8000484e:	00878713          	addi	a4,a5,8
    80004852:	00271693          	slli	a3,a4,0x2
    80004856:	0001d717          	auipc	a4,0x1d
    8000485a:	23a70713          	addi	a4,a4,570 # 80021a90 <log>
    8000485e:	9736                	add	a4,a4,a3
    80004860:	44d4                	lw	a3,12(s1)
    80004862:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80004864:	faf608e3          	beq	a2,a5,80004814 <log_write+0x76>
  }
  release(&log.lock);
    80004868:	0001d517          	auipc	a0,0x1d
    8000486c:	22850513          	addi	a0,a0,552 # 80021a90 <log>
    80004870:	ffffc097          	auipc	ra,0xffffc
    80004874:	428080e7          	jalr	1064(ra) # 80000c98 <release>
}
    80004878:	60e2                	ld	ra,24(sp)
    8000487a:	6442                	ld	s0,16(sp)
    8000487c:	64a2                	ld	s1,8(sp)
    8000487e:	6902                	ld	s2,0(sp)
    80004880:	6105                	addi	sp,sp,32
    80004882:	8082                	ret

0000000080004884 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004884:	1101                	addi	sp,sp,-32
    80004886:	ec06                	sd	ra,24(sp)
    80004888:	e822                	sd	s0,16(sp)
    8000488a:	e426                	sd	s1,8(sp)
    8000488c:	e04a                	sd	s2,0(sp)
    8000488e:	1000                	addi	s0,sp,32
    80004890:	84aa                	mv	s1,a0
    80004892:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004894:	00004597          	auipc	a1,0x4
    80004898:	df458593          	addi	a1,a1,-524 # 80008688 <syscalls+0x238>
    8000489c:	0521                	addi	a0,a0,8
    8000489e:	ffffc097          	auipc	ra,0xffffc
    800048a2:	2b6080e7          	jalr	694(ra) # 80000b54 <initlock>
  lk->name = name;
    800048a6:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    800048aa:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800048ae:	0204a423          	sw	zero,40(s1)
}
    800048b2:	60e2                	ld	ra,24(sp)
    800048b4:	6442                	ld	s0,16(sp)
    800048b6:	64a2                	ld	s1,8(sp)
    800048b8:	6902                	ld	s2,0(sp)
    800048ba:	6105                	addi	sp,sp,32
    800048bc:	8082                	ret

00000000800048be <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    800048be:	1101                	addi	sp,sp,-32
    800048c0:	ec06                	sd	ra,24(sp)
    800048c2:	e822                	sd	s0,16(sp)
    800048c4:	e426                	sd	s1,8(sp)
    800048c6:	e04a                	sd	s2,0(sp)
    800048c8:	1000                	addi	s0,sp,32
    800048ca:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800048cc:	00850913          	addi	s2,a0,8
    800048d0:	854a                	mv	a0,s2
    800048d2:	ffffc097          	auipc	ra,0xffffc
    800048d6:	312080e7          	jalr	786(ra) # 80000be4 <acquire>
  while (lk->locked) {
    800048da:	409c                	lw	a5,0(s1)
    800048dc:	cb89                	beqz	a5,800048ee <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    800048de:	85ca                	mv	a1,s2
    800048e0:	8526                	mv	a0,s1
    800048e2:	ffffe097          	auipc	ra,0xffffe
    800048e6:	b60080e7          	jalr	-1184(ra) # 80002442 <sleep>
  while (lk->locked) {
    800048ea:	409c                	lw	a5,0(s1)
    800048ec:	fbed                	bnez	a5,800048de <acquiresleep+0x20>
  }
  lk->locked = 1;
    800048ee:	4785                	li	a5,1
    800048f0:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    800048f2:	ffffd097          	auipc	ra,0xffffd
    800048f6:	0d6080e7          	jalr	214(ra) # 800019c8 <myproc>
    800048fa:	591c                	lw	a5,48(a0)
    800048fc:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    800048fe:	854a                	mv	a0,s2
    80004900:	ffffc097          	auipc	ra,0xffffc
    80004904:	398080e7          	jalr	920(ra) # 80000c98 <release>
}
    80004908:	60e2                	ld	ra,24(sp)
    8000490a:	6442                	ld	s0,16(sp)
    8000490c:	64a2                	ld	s1,8(sp)
    8000490e:	6902                	ld	s2,0(sp)
    80004910:	6105                	addi	sp,sp,32
    80004912:	8082                	ret

0000000080004914 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004914:	1101                	addi	sp,sp,-32
    80004916:	ec06                	sd	ra,24(sp)
    80004918:	e822                	sd	s0,16(sp)
    8000491a:	e426                	sd	s1,8(sp)
    8000491c:	e04a                	sd	s2,0(sp)
    8000491e:	1000                	addi	s0,sp,32
    80004920:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004922:	00850913          	addi	s2,a0,8
    80004926:	854a                	mv	a0,s2
    80004928:	ffffc097          	auipc	ra,0xffffc
    8000492c:	2bc080e7          	jalr	700(ra) # 80000be4 <acquire>
  lk->locked = 0;
    80004930:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004934:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004938:	8526                	mv	a0,s1
    8000493a:	ffffe097          	auipc	ra,0xffffe
    8000493e:	cc8080e7          	jalr	-824(ra) # 80002602 <wakeup>
  release(&lk->lk);
    80004942:	854a                	mv	a0,s2
    80004944:	ffffc097          	auipc	ra,0xffffc
    80004948:	354080e7          	jalr	852(ra) # 80000c98 <release>
}
    8000494c:	60e2                	ld	ra,24(sp)
    8000494e:	6442                	ld	s0,16(sp)
    80004950:	64a2                	ld	s1,8(sp)
    80004952:	6902                	ld	s2,0(sp)
    80004954:	6105                	addi	sp,sp,32
    80004956:	8082                	ret

0000000080004958 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004958:	7179                	addi	sp,sp,-48
    8000495a:	f406                	sd	ra,40(sp)
    8000495c:	f022                	sd	s0,32(sp)
    8000495e:	ec26                	sd	s1,24(sp)
    80004960:	e84a                	sd	s2,16(sp)
    80004962:	e44e                	sd	s3,8(sp)
    80004964:	1800                	addi	s0,sp,48
    80004966:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004968:	00850913          	addi	s2,a0,8
    8000496c:	854a                	mv	a0,s2
    8000496e:	ffffc097          	auipc	ra,0xffffc
    80004972:	276080e7          	jalr	630(ra) # 80000be4 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004976:	409c                	lw	a5,0(s1)
    80004978:	ef99                	bnez	a5,80004996 <holdingsleep+0x3e>
    8000497a:	4481                	li	s1,0
  release(&lk->lk);
    8000497c:	854a                	mv	a0,s2
    8000497e:	ffffc097          	auipc	ra,0xffffc
    80004982:	31a080e7          	jalr	794(ra) # 80000c98 <release>
  return r;
}
    80004986:	8526                	mv	a0,s1
    80004988:	70a2                	ld	ra,40(sp)
    8000498a:	7402                	ld	s0,32(sp)
    8000498c:	64e2                	ld	s1,24(sp)
    8000498e:	6942                	ld	s2,16(sp)
    80004990:	69a2                	ld	s3,8(sp)
    80004992:	6145                	addi	sp,sp,48
    80004994:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004996:	0284a983          	lw	s3,40(s1)
    8000499a:	ffffd097          	auipc	ra,0xffffd
    8000499e:	02e080e7          	jalr	46(ra) # 800019c8 <myproc>
    800049a2:	5904                	lw	s1,48(a0)
    800049a4:	413484b3          	sub	s1,s1,s3
    800049a8:	0014b493          	seqz	s1,s1
    800049ac:	bfc1                	j	8000497c <holdingsleep+0x24>

00000000800049ae <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    800049ae:	1141                	addi	sp,sp,-16
    800049b0:	e406                	sd	ra,8(sp)
    800049b2:	e022                	sd	s0,0(sp)
    800049b4:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    800049b6:	00004597          	auipc	a1,0x4
    800049ba:	ce258593          	addi	a1,a1,-798 # 80008698 <syscalls+0x248>
    800049be:	0001d517          	auipc	a0,0x1d
    800049c2:	21a50513          	addi	a0,a0,538 # 80021bd8 <ftable>
    800049c6:	ffffc097          	auipc	ra,0xffffc
    800049ca:	18e080e7          	jalr	398(ra) # 80000b54 <initlock>
}
    800049ce:	60a2                	ld	ra,8(sp)
    800049d0:	6402                	ld	s0,0(sp)
    800049d2:	0141                	addi	sp,sp,16
    800049d4:	8082                	ret

00000000800049d6 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    800049d6:	1101                	addi	sp,sp,-32
    800049d8:	ec06                	sd	ra,24(sp)
    800049da:	e822                	sd	s0,16(sp)
    800049dc:	e426                	sd	s1,8(sp)
    800049de:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    800049e0:	0001d517          	auipc	a0,0x1d
    800049e4:	1f850513          	addi	a0,a0,504 # 80021bd8 <ftable>
    800049e8:	ffffc097          	auipc	ra,0xffffc
    800049ec:	1fc080e7          	jalr	508(ra) # 80000be4 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800049f0:	0001d497          	auipc	s1,0x1d
    800049f4:	20048493          	addi	s1,s1,512 # 80021bf0 <ftable+0x18>
    800049f8:	0001e717          	auipc	a4,0x1e
    800049fc:	19870713          	addi	a4,a4,408 # 80022b90 <ftable+0xfb8>
    if(f->ref == 0){
    80004a00:	40dc                	lw	a5,4(s1)
    80004a02:	cf99                	beqz	a5,80004a20 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004a04:	02848493          	addi	s1,s1,40
    80004a08:	fee49ce3          	bne	s1,a4,80004a00 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004a0c:	0001d517          	auipc	a0,0x1d
    80004a10:	1cc50513          	addi	a0,a0,460 # 80021bd8 <ftable>
    80004a14:	ffffc097          	auipc	ra,0xffffc
    80004a18:	284080e7          	jalr	644(ra) # 80000c98 <release>
  return 0;
    80004a1c:	4481                	li	s1,0
    80004a1e:	a819                	j	80004a34 <filealloc+0x5e>
      f->ref = 1;
    80004a20:	4785                	li	a5,1
    80004a22:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004a24:	0001d517          	auipc	a0,0x1d
    80004a28:	1b450513          	addi	a0,a0,436 # 80021bd8 <ftable>
    80004a2c:	ffffc097          	auipc	ra,0xffffc
    80004a30:	26c080e7          	jalr	620(ra) # 80000c98 <release>
}
    80004a34:	8526                	mv	a0,s1
    80004a36:	60e2                	ld	ra,24(sp)
    80004a38:	6442                	ld	s0,16(sp)
    80004a3a:	64a2                	ld	s1,8(sp)
    80004a3c:	6105                	addi	sp,sp,32
    80004a3e:	8082                	ret

0000000080004a40 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004a40:	1101                	addi	sp,sp,-32
    80004a42:	ec06                	sd	ra,24(sp)
    80004a44:	e822                	sd	s0,16(sp)
    80004a46:	e426                	sd	s1,8(sp)
    80004a48:	1000                	addi	s0,sp,32
    80004a4a:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004a4c:	0001d517          	auipc	a0,0x1d
    80004a50:	18c50513          	addi	a0,a0,396 # 80021bd8 <ftable>
    80004a54:	ffffc097          	auipc	ra,0xffffc
    80004a58:	190080e7          	jalr	400(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    80004a5c:	40dc                	lw	a5,4(s1)
    80004a5e:	02f05263          	blez	a5,80004a82 <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004a62:	2785                	addiw	a5,a5,1
    80004a64:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004a66:	0001d517          	auipc	a0,0x1d
    80004a6a:	17250513          	addi	a0,a0,370 # 80021bd8 <ftable>
    80004a6e:	ffffc097          	auipc	ra,0xffffc
    80004a72:	22a080e7          	jalr	554(ra) # 80000c98 <release>
  return f;
}
    80004a76:	8526                	mv	a0,s1
    80004a78:	60e2                	ld	ra,24(sp)
    80004a7a:	6442                	ld	s0,16(sp)
    80004a7c:	64a2                	ld	s1,8(sp)
    80004a7e:	6105                	addi	sp,sp,32
    80004a80:	8082                	ret
    panic("filedup");
    80004a82:	00004517          	auipc	a0,0x4
    80004a86:	c1e50513          	addi	a0,a0,-994 # 800086a0 <syscalls+0x250>
    80004a8a:	ffffc097          	auipc	ra,0xffffc
    80004a8e:	ab4080e7          	jalr	-1356(ra) # 8000053e <panic>

0000000080004a92 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004a92:	7139                	addi	sp,sp,-64
    80004a94:	fc06                	sd	ra,56(sp)
    80004a96:	f822                	sd	s0,48(sp)
    80004a98:	f426                	sd	s1,40(sp)
    80004a9a:	f04a                	sd	s2,32(sp)
    80004a9c:	ec4e                	sd	s3,24(sp)
    80004a9e:	e852                	sd	s4,16(sp)
    80004aa0:	e456                	sd	s5,8(sp)
    80004aa2:	0080                	addi	s0,sp,64
    80004aa4:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004aa6:	0001d517          	auipc	a0,0x1d
    80004aaa:	13250513          	addi	a0,a0,306 # 80021bd8 <ftable>
    80004aae:	ffffc097          	auipc	ra,0xffffc
    80004ab2:	136080e7          	jalr	310(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    80004ab6:	40dc                	lw	a5,4(s1)
    80004ab8:	06f05163          	blez	a5,80004b1a <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004abc:	37fd                	addiw	a5,a5,-1
    80004abe:	0007871b          	sext.w	a4,a5
    80004ac2:	c0dc                	sw	a5,4(s1)
    80004ac4:	06e04363          	bgtz	a4,80004b2a <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004ac8:	0004a903          	lw	s2,0(s1)
    80004acc:	0094ca83          	lbu	s5,9(s1)
    80004ad0:	0104ba03          	ld	s4,16(s1)
    80004ad4:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004ad8:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004adc:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004ae0:	0001d517          	auipc	a0,0x1d
    80004ae4:	0f850513          	addi	a0,a0,248 # 80021bd8 <ftable>
    80004ae8:	ffffc097          	auipc	ra,0xffffc
    80004aec:	1b0080e7          	jalr	432(ra) # 80000c98 <release>

  if(ff.type == FD_PIPE){
    80004af0:	4785                	li	a5,1
    80004af2:	04f90d63          	beq	s2,a5,80004b4c <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004af6:	3979                	addiw	s2,s2,-2
    80004af8:	4785                	li	a5,1
    80004afa:	0527e063          	bltu	a5,s2,80004b3a <fileclose+0xa8>
    begin_op();
    80004afe:	00000097          	auipc	ra,0x0
    80004b02:	ac8080e7          	jalr	-1336(ra) # 800045c6 <begin_op>
    iput(ff.ip);
    80004b06:	854e                	mv	a0,s3
    80004b08:	fffff097          	auipc	ra,0xfffff
    80004b0c:	2a6080e7          	jalr	678(ra) # 80003dae <iput>
    end_op();
    80004b10:	00000097          	auipc	ra,0x0
    80004b14:	b36080e7          	jalr	-1226(ra) # 80004646 <end_op>
    80004b18:	a00d                	j	80004b3a <fileclose+0xa8>
    panic("fileclose");
    80004b1a:	00004517          	auipc	a0,0x4
    80004b1e:	b8e50513          	addi	a0,a0,-1138 # 800086a8 <syscalls+0x258>
    80004b22:	ffffc097          	auipc	ra,0xffffc
    80004b26:	a1c080e7          	jalr	-1508(ra) # 8000053e <panic>
    release(&ftable.lock);
    80004b2a:	0001d517          	auipc	a0,0x1d
    80004b2e:	0ae50513          	addi	a0,a0,174 # 80021bd8 <ftable>
    80004b32:	ffffc097          	auipc	ra,0xffffc
    80004b36:	166080e7          	jalr	358(ra) # 80000c98 <release>
  }
}
    80004b3a:	70e2                	ld	ra,56(sp)
    80004b3c:	7442                	ld	s0,48(sp)
    80004b3e:	74a2                	ld	s1,40(sp)
    80004b40:	7902                	ld	s2,32(sp)
    80004b42:	69e2                	ld	s3,24(sp)
    80004b44:	6a42                	ld	s4,16(sp)
    80004b46:	6aa2                	ld	s5,8(sp)
    80004b48:	6121                	addi	sp,sp,64
    80004b4a:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004b4c:	85d6                	mv	a1,s5
    80004b4e:	8552                	mv	a0,s4
    80004b50:	00000097          	auipc	ra,0x0
    80004b54:	34c080e7          	jalr	844(ra) # 80004e9c <pipeclose>
    80004b58:	b7cd                	j	80004b3a <fileclose+0xa8>

0000000080004b5a <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004b5a:	715d                	addi	sp,sp,-80
    80004b5c:	e486                	sd	ra,72(sp)
    80004b5e:	e0a2                	sd	s0,64(sp)
    80004b60:	fc26                	sd	s1,56(sp)
    80004b62:	f84a                	sd	s2,48(sp)
    80004b64:	f44e                	sd	s3,40(sp)
    80004b66:	0880                	addi	s0,sp,80
    80004b68:	84aa                	mv	s1,a0
    80004b6a:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004b6c:	ffffd097          	auipc	ra,0xffffd
    80004b70:	e5c080e7          	jalr	-420(ra) # 800019c8 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004b74:	409c                	lw	a5,0(s1)
    80004b76:	37f9                	addiw	a5,a5,-2
    80004b78:	4705                	li	a4,1
    80004b7a:	04f76763          	bltu	a4,a5,80004bc8 <filestat+0x6e>
    80004b7e:	892a                	mv	s2,a0
    ilock(f->ip);
    80004b80:	6c88                	ld	a0,24(s1)
    80004b82:	fffff097          	auipc	ra,0xfffff
    80004b86:	072080e7          	jalr	114(ra) # 80003bf4 <ilock>
    stati(f->ip, &st);
    80004b8a:	fb840593          	addi	a1,s0,-72
    80004b8e:	6c88                	ld	a0,24(s1)
    80004b90:	fffff097          	auipc	ra,0xfffff
    80004b94:	2ee080e7          	jalr	750(ra) # 80003e7e <stati>
    iunlock(f->ip);
    80004b98:	6c88                	ld	a0,24(s1)
    80004b9a:	fffff097          	auipc	ra,0xfffff
    80004b9e:	11c080e7          	jalr	284(ra) # 80003cb6 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004ba2:	46e1                	li	a3,24
    80004ba4:	fb840613          	addi	a2,s0,-72
    80004ba8:	85ce                	mv	a1,s3
    80004baa:	07093503          	ld	a0,112(s2)
    80004bae:	ffffd097          	auipc	ra,0xffffd
    80004bb2:	acc080e7          	jalr	-1332(ra) # 8000167a <copyout>
    80004bb6:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004bba:	60a6                	ld	ra,72(sp)
    80004bbc:	6406                	ld	s0,64(sp)
    80004bbe:	74e2                	ld	s1,56(sp)
    80004bc0:	7942                	ld	s2,48(sp)
    80004bc2:	79a2                	ld	s3,40(sp)
    80004bc4:	6161                	addi	sp,sp,80
    80004bc6:	8082                	ret
  return -1;
    80004bc8:	557d                	li	a0,-1
    80004bca:	bfc5                	j	80004bba <filestat+0x60>

0000000080004bcc <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004bcc:	7179                	addi	sp,sp,-48
    80004bce:	f406                	sd	ra,40(sp)
    80004bd0:	f022                	sd	s0,32(sp)
    80004bd2:	ec26                	sd	s1,24(sp)
    80004bd4:	e84a                	sd	s2,16(sp)
    80004bd6:	e44e                	sd	s3,8(sp)
    80004bd8:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004bda:	00854783          	lbu	a5,8(a0)
    80004bde:	c3d5                	beqz	a5,80004c82 <fileread+0xb6>
    80004be0:	84aa                	mv	s1,a0
    80004be2:	89ae                	mv	s3,a1
    80004be4:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004be6:	411c                	lw	a5,0(a0)
    80004be8:	4705                	li	a4,1
    80004bea:	04e78963          	beq	a5,a4,80004c3c <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004bee:	470d                	li	a4,3
    80004bf0:	04e78d63          	beq	a5,a4,80004c4a <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004bf4:	4709                	li	a4,2
    80004bf6:	06e79e63          	bne	a5,a4,80004c72 <fileread+0xa6>
    ilock(f->ip);
    80004bfa:	6d08                	ld	a0,24(a0)
    80004bfc:	fffff097          	auipc	ra,0xfffff
    80004c00:	ff8080e7          	jalr	-8(ra) # 80003bf4 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004c04:	874a                	mv	a4,s2
    80004c06:	5094                	lw	a3,32(s1)
    80004c08:	864e                	mv	a2,s3
    80004c0a:	4585                	li	a1,1
    80004c0c:	6c88                	ld	a0,24(s1)
    80004c0e:	fffff097          	auipc	ra,0xfffff
    80004c12:	29a080e7          	jalr	666(ra) # 80003ea8 <readi>
    80004c16:	892a                	mv	s2,a0
    80004c18:	00a05563          	blez	a0,80004c22 <fileread+0x56>
      f->off += r;
    80004c1c:	509c                	lw	a5,32(s1)
    80004c1e:	9fa9                	addw	a5,a5,a0
    80004c20:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004c22:	6c88                	ld	a0,24(s1)
    80004c24:	fffff097          	auipc	ra,0xfffff
    80004c28:	092080e7          	jalr	146(ra) # 80003cb6 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004c2c:	854a                	mv	a0,s2
    80004c2e:	70a2                	ld	ra,40(sp)
    80004c30:	7402                	ld	s0,32(sp)
    80004c32:	64e2                	ld	s1,24(sp)
    80004c34:	6942                	ld	s2,16(sp)
    80004c36:	69a2                	ld	s3,8(sp)
    80004c38:	6145                	addi	sp,sp,48
    80004c3a:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004c3c:	6908                	ld	a0,16(a0)
    80004c3e:	00000097          	auipc	ra,0x0
    80004c42:	3c8080e7          	jalr	968(ra) # 80005006 <piperead>
    80004c46:	892a                	mv	s2,a0
    80004c48:	b7d5                	j	80004c2c <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004c4a:	02451783          	lh	a5,36(a0)
    80004c4e:	03079693          	slli	a3,a5,0x30
    80004c52:	92c1                	srli	a3,a3,0x30
    80004c54:	4725                	li	a4,9
    80004c56:	02d76863          	bltu	a4,a3,80004c86 <fileread+0xba>
    80004c5a:	0792                	slli	a5,a5,0x4
    80004c5c:	0001d717          	auipc	a4,0x1d
    80004c60:	edc70713          	addi	a4,a4,-292 # 80021b38 <devsw>
    80004c64:	97ba                	add	a5,a5,a4
    80004c66:	639c                	ld	a5,0(a5)
    80004c68:	c38d                	beqz	a5,80004c8a <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004c6a:	4505                	li	a0,1
    80004c6c:	9782                	jalr	a5
    80004c6e:	892a                	mv	s2,a0
    80004c70:	bf75                	j	80004c2c <fileread+0x60>
    panic("fileread");
    80004c72:	00004517          	auipc	a0,0x4
    80004c76:	a4650513          	addi	a0,a0,-1466 # 800086b8 <syscalls+0x268>
    80004c7a:	ffffc097          	auipc	ra,0xffffc
    80004c7e:	8c4080e7          	jalr	-1852(ra) # 8000053e <panic>
    return -1;
    80004c82:	597d                	li	s2,-1
    80004c84:	b765                	j	80004c2c <fileread+0x60>
      return -1;
    80004c86:	597d                	li	s2,-1
    80004c88:	b755                	j	80004c2c <fileread+0x60>
    80004c8a:	597d                	li	s2,-1
    80004c8c:	b745                	j	80004c2c <fileread+0x60>

0000000080004c8e <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80004c8e:	715d                	addi	sp,sp,-80
    80004c90:	e486                	sd	ra,72(sp)
    80004c92:	e0a2                	sd	s0,64(sp)
    80004c94:	fc26                	sd	s1,56(sp)
    80004c96:	f84a                	sd	s2,48(sp)
    80004c98:	f44e                	sd	s3,40(sp)
    80004c9a:	f052                	sd	s4,32(sp)
    80004c9c:	ec56                	sd	s5,24(sp)
    80004c9e:	e85a                	sd	s6,16(sp)
    80004ca0:	e45e                	sd	s7,8(sp)
    80004ca2:	e062                	sd	s8,0(sp)
    80004ca4:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80004ca6:	00954783          	lbu	a5,9(a0)
    80004caa:	10078663          	beqz	a5,80004db6 <filewrite+0x128>
    80004cae:	892a                	mv	s2,a0
    80004cb0:	8aae                	mv	s5,a1
    80004cb2:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004cb4:	411c                	lw	a5,0(a0)
    80004cb6:	4705                	li	a4,1
    80004cb8:	02e78263          	beq	a5,a4,80004cdc <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004cbc:	470d                	li	a4,3
    80004cbe:	02e78663          	beq	a5,a4,80004cea <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004cc2:	4709                	li	a4,2
    80004cc4:	0ee79163          	bne	a5,a4,80004da6 <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004cc8:	0ac05d63          	blez	a2,80004d82 <filewrite+0xf4>
    int i = 0;
    80004ccc:	4981                	li	s3,0
    80004cce:	6b05                	lui	s6,0x1
    80004cd0:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80004cd4:	6b85                	lui	s7,0x1
    80004cd6:	c00b8b9b          	addiw	s7,s7,-1024
    80004cda:	a861                	j	80004d72 <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80004cdc:	6908                	ld	a0,16(a0)
    80004cde:	00000097          	auipc	ra,0x0
    80004ce2:	22e080e7          	jalr	558(ra) # 80004f0c <pipewrite>
    80004ce6:	8a2a                	mv	s4,a0
    80004ce8:	a045                	j	80004d88 <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004cea:	02451783          	lh	a5,36(a0)
    80004cee:	03079693          	slli	a3,a5,0x30
    80004cf2:	92c1                	srli	a3,a3,0x30
    80004cf4:	4725                	li	a4,9
    80004cf6:	0cd76263          	bltu	a4,a3,80004dba <filewrite+0x12c>
    80004cfa:	0792                	slli	a5,a5,0x4
    80004cfc:	0001d717          	auipc	a4,0x1d
    80004d00:	e3c70713          	addi	a4,a4,-452 # 80021b38 <devsw>
    80004d04:	97ba                	add	a5,a5,a4
    80004d06:	679c                	ld	a5,8(a5)
    80004d08:	cbdd                	beqz	a5,80004dbe <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80004d0a:	4505                	li	a0,1
    80004d0c:	9782                	jalr	a5
    80004d0e:	8a2a                	mv	s4,a0
    80004d10:	a8a5                	j	80004d88 <filewrite+0xfa>
    80004d12:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004d16:	00000097          	auipc	ra,0x0
    80004d1a:	8b0080e7          	jalr	-1872(ra) # 800045c6 <begin_op>
      ilock(f->ip);
    80004d1e:	01893503          	ld	a0,24(s2)
    80004d22:	fffff097          	auipc	ra,0xfffff
    80004d26:	ed2080e7          	jalr	-302(ra) # 80003bf4 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004d2a:	8762                	mv	a4,s8
    80004d2c:	02092683          	lw	a3,32(s2)
    80004d30:	01598633          	add	a2,s3,s5
    80004d34:	4585                	li	a1,1
    80004d36:	01893503          	ld	a0,24(s2)
    80004d3a:	fffff097          	auipc	ra,0xfffff
    80004d3e:	266080e7          	jalr	614(ra) # 80003fa0 <writei>
    80004d42:	84aa                	mv	s1,a0
    80004d44:	00a05763          	blez	a0,80004d52 <filewrite+0xc4>
        f->off += r;
    80004d48:	02092783          	lw	a5,32(s2)
    80004d4c:	9fa9                	addw	a5,a5,a0
    80004d4e:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004d52:	01893503          	ld	a0,24(s2)
    80004d56:	fffff097          	auipc	ra,0xfffff
    80004d5a:	f60080e7          	jalr	-160(ra) # 80003cb6 <iunlock>
      end_op();
    80004d5e:	00000097          	auipc	ra,0x0
    80004d62:	8e8080e7          	jalr	-1816(ra) # 80004646 <end_op>

      if(r != n1){
    80004d66:	009c1f63          	bne	s8,s1,80004d84 <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80004d6a:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004d6e:	0149db63          	bge	s3,s4,80004d84 <filewrite+0xf6>
      int n1 = n - i;
    80004d72:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80004d76:	84be                	mv	s1,a5
    80004d78:	2781                	sext.w	a5,a5
    80004d7a:	f8fb5ce3          	bge	s6,a5,80004d12 <filewrite+0x84>
    80004d7e:	84de                	mv	s1,s7
    80004d80:	bf49                	j	80004d12 <filewrite+0x84>
    int i = 0;
    80004d82:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004d84:	013a1f63          	bne	s4,s3,80004da2 <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004d88:	8552                	mv	a0,s4
    80004d8a:	60a6                	ld	ra,72(sp)
    80004d8c:	6406                	ld	s0,64(sp)
    80004d8e:	74e2                	ld	s1,56(sp)
    80004d90:	7942                	ld	s2,48(sp)
    80004d92:	79a2                	ld	s3,40(sp)
    80004d94:	7a02                	ld	s4,32(sp)
    80004d96:	6ae2                	ld	s5,24(sp)
    80004d98:	6b42                	ld	s6,16(sp)
    80004d9a:	6ba2                	ld	s7,8(sp)
    80004d9c:	6c02                	ld	s8,0(sp)
    80004d9e:	6161                	addi	sp,sp,80
    80004da0:	8082                	ret
    ret = (i == n ? n : -1);
    80004da2:	5a7d                	li	s4,-1
    80004da4:	b7d5                	j	80004d88 <filewrite+0xfa>
    panic("filewrite");
    80004da6:	00004517          	auipc	a0,0x4
    80004daa:	92250513          	addi	a0,a0,-1758 # 800086c8 <syscalls+0x278>
    80004dae:	ffffb097          	auipc	ra,0xffffb
    80004db2:	790080e7          	jalr	1936(ra) # 8000053e <panic>
    return -1;
    80004db6:	5a7d                	li	s4,-1
    80004db8:	bfc1                	j	80004d88 <filewrite+0xfa>
      return -1;
    80004dba:	5a7d                	li	s4,-1
    80004dbc:	b7f1                	j	80004d88 <filewrite+0xfa>
    80004dbe:	5a7d                	li	s4,-1
    80004dc0:	b7e1                	j	80004d88 <filewrite+0xfa>

0000000080004dc2 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004dc2:	7179                	addi	sp,sp,-48
    80004dc4:	f406                	sd	ra,40(sp)
    80004dc6:	f022                	sd	s0,32(sp)
    80004dc8:	ec26                	sd	s1,24(sp)
    80004dca:	e84a                	sd	s2,16(sp)
    80004dcc:	e44e                	sd	s3,8(sp)
    80004dce:	e052                	sd	s4,0(sp)
    80004dd0:	1800                	addi	s0,sp,48
    80004dd2:	84aa                	mv	s1,a0
    80004dd4:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004dd6:	0005b023          	sd	zero,0(a1)
    80004dda:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004dde:	00000097          	auipc	ra,0x0
    80004de2:	bf8080e7          	jalr	-1032(ra) # 800049d6 <filealloc>
    80004de6:	e088                	sd	a0,0(s1)
    80004de8:	c551                	beqz	a0,80004e74 <pipealloc+0xb2>
    80004dea:	00000097          	auipc	ra,0x0
    80004dee:	bec080e7          	jalr	-1044(ra) # 800049d6 <filealloc>
    80004df2:	00aa3023          	sd	a0,0(s4)
    80004df6:	c92d                	beqz	a0,80004e68 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004df8:	ffffc097          	auipc	ra,0xffffc
    80004dfc:	cfc080e7          	jalr	-772(ra) # 80000af4 <kalloc>
    80004e00:	892a                	mv	s2,a0
    80004e02:	c125                	beqz	a0,80004e62 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004e04:	4985                	li	s3,1
    80004e06:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004e0a:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004e0e:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004e12:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004e16:	00004597          	auipc	a1,0x4
    80004e1a:	8c258593          	addi	a1,a1,-1854 # 800086d8 <syscalls+0x288>
    80004e1e:	ffffc097          	auipc	ra,0xffffc
    80004e22:	d36080e7          	jalr	-714(ra) # 80000b54 <initlock>
  (*f0)->type = FD_PIPE;
    80004e26:	609c                	ld	a5,0(s1)
    80004e28:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004e2c:	609c                	ld	a5,0(s1)
    80004e2e:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004e32:	609c                	ld	a5,0(s1)
    80004e34:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004e38:	609c                	ld	a5,0(s1)
    80004e3a:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004e3e:	000a3783          	ld	a5,0(s4)
    80004e42:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004e46:	000a3783          	ld	a5,0(s4)
    80004e4a:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004e4e:	000a3783          	ld	a5,0(s4)
    80004e52:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004e56:	000a3783          	ld	a5,0(s4)
    80004e5a:	0127b823          	sd	s2,16(a5)
  return 0;
    80004e5e:	4501                	li	a0,0
    80004e60:	a025                	j	80004e88 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004e62:	6088                	ld	a0,0(s1)
    80004e64:	e501                	bnez	a0,80004e6c <pipealloc+0xaa>
    80004e66:	a039                	j	80004e74 <pipealloc+0xb2>
    80004e68:	6088                	ld	a0,0(s1)
    80004e6a:	c51d                	beqz	a0,80004e98 <pipealloc+0xd6>
    fileclose(*f0);
    80004e6c:	00000097          	auipc	ra,0x0
    80004e70:	c26080e7          	jalr	-986(ra) # 80004a92 <fileclose>
  if(*f1)
    80004e74:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004e78:	557d                	li	a0,-1
  if(*f1)
    80004e7a:	c799                	beqz	a5,80004e88 <pipealloc+0xc6>
    fileclose(*f1);
    80004e7c:	853e                	mv	a0,a5
    80004e7e:	00000097          	auipc	ra,0x0
    80004e82:	c14080e7          	jalr	-1004(ra) # 80004a92 <fileclose>
  return -1;
    80004e86:	557d                	li	a0,-1
}
    80004e88:	70a2                	ld	ra,40(sp)
    80004e8a:	7402                	ld	s0,32(sp)
    80004e8c:	64e2                	ld	s1,24(sp)
    80004e8e:	6942                	ld	s2,16(sp)
    80004e90:	69a2                	ld	s3,8(sp)
    80004e92:	6a02                	ld	s4,0(sp)
    80004e94:	6145                	addi	sp,sp,48
    80004e96:	8082                	ret
  return -1;
    80004e98:	557d                	li	a0,-1
    80004e9a:	b7fd                	j	80004e88 <pipealloc+0xc6>

0000000080004e9c <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004e9c:	1101                	addi	sp,sp,-32
    80004e9e:	ec06                	sd	ra,24(sp)
    80004ea0:	e822                	sd	s0,16(sp)
    80004ea2:	e426                	sd	s1,8(sp)
    80004ea4:	e04a                	sd	s2,0(sp)
    80004ea6:	1000                	addi	s0,sp,32
    80004ea8:	84aa                	mv	s1,a0
    80004eaa:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004eac:	ffffc097          	auipc	ra,0xffffc
    80004eb0:	d38080e7          	jalr	-712(ra) # 80000be4 <acquire>
  if(writable){
    80004eb4:	02090d63          	beqz	s2,80004eee <pipeclose+0x52>
    pi->writeopen = 0;
    80004eb8:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004ebc:	21848513          	addi	a0,s1,536
    80004ec0:	ffffd097          	auipc	ra,0xffffd
    80004ec4:	742080e7          	jalr	1858(ra) # 80002602 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004ec8:	2204b783          	ld	a5,544(s1)
    80004ecc:	eb95                	bnez	a5,80004f00 <pipeclose+0x64>
    release(&pi->lock);
    80004ece:	8526                	mv	a0,s1
    80004ed0:	ffffc097          	auipc	ra,0xffffc
    80004ed4:	dc8080e7          	jalr	-568(ra) # 80000c98 <release>
    kfree((char*)pi);
    80004ed8:	8526                	mv	a0,s1
    80004eda:	ffffc097          	auipc	ra,0xffffc
    80004ede:	b1e080e7          	jalr	-1250(ra) # 800009f8 <kfree>
  } else
    release(&pi->lock);
}
    80004ee2:	60e2                	ld	ra,24(sp)
    80004ee4:	6442                	ld	s0,16(sp)
    80004ee6:	64a2                	ld	s1,8(sp)
    80004ee8:	6902                	ld	s2,0(sp)
    80004eea:	6105                	addi	sp,sp,32
    80004eec:	8082                	ret
    pi->readopen = 0;
    80004eee:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004ef2:	21c48513          	addi	a0,s1,540
    80004ef6:	ffffd097          	auipc	ra,0xffffd
    80004efa:	70c080e7          	jalr	1804(ra) # 80002602 <wakeup>
    80004efe:	b7e9                	j	80004ec8 <pipeclose+0x2c>
    release(&pi->lock);
    80004f00:	8526                	mv	a0,s1
    80004f02:	ffffc097          	auipc	ra,0xffffc
    80004f06:	d96080e7          	jalr	-618(ra) # 80000c98 <release>
}
    80004f0a:	bfe1                	j	80004ee2 <pipeclose+0x46>

0000000080004f0c <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004f0c:	7159                	addi	sp,sp,-112
    80004f0e:	f486                	sd	ra,104(sp)
    80004f10:	f0a2                	sd	s0,96(sp)
    80004f12:	eca6                	sd	s1,88(sp)
    80004f14:	e8ca                	sd	s2,80(sp)
    80004f16:	e4ce                	sd	s3,72(sp)
    80004f18:	e0d2                	sd	s4,64(sp)
    80004f1a:	fc56                	sd	s5,56(sp)
    80004f1c:	f85a                	sd	s6,48(sp)
    80004f1e:	f45e                	sd	s7,40(sp)
    80004f20:	f062                	sd	s8,32(sp)
    80004f22:	ec66                	sd	s9,24(sp)
    80004f24:	1880                	addi	s0,sp,112
    80004f26:	84aa                	mv	s1,a0
    80004f28:	8aae                	mv	s5,a1
    80004f2a:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004f2c:	ffffd097          	auipc	ra,0xffffd
    80004f30:	a9c080e7          	jalr	-1380(ra) # 800019c8 <myproc>
    80004f34:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004f36:	8526                	mv	a0,s1
    80004f38:	ffffc097          	auipc	ra,0xffffc
    80004f3c:	cac080e7          	jalr	-852(ra) # 80000be4 <acquire>
  while(i < n){
    80004f40:	0d405163          	blez	s4,80005002 <pipewrite+0xf6>
    80004f44:	8ba6                	mv	s7,s1
  int i = 0;
    80004f46:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004f48:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004f4a:	21848c93          	addi	s9,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004f4e:	21c48c13          	addi	s8,s1,540
    80004f52:	a08d                	j	80004fb4 <pipewrite+0xa8>
      release(&pi->lock);
    80004f54:	8526                	mv	a0,s1
    80004f56:	ffffc097          	auipc	ra,0xffffc
    80004f5a:	d42080e7          	jalr	-702(ra) # 80000c98 <release>
      return -1;
    80004f5e:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004f60:	854a                	mv	a0,s2
    80004f62:	70a6                	ld	ra,104(sp)
    80004f64:	7406                	ld	s0,96(sp)
    80004f66:	64e6                	ld	s1,88(sp)
    80004f68:	6946                	ld	s2,80(sp)
    80004f6a:	69a6                	ld	s3,72(sp)
    80004f6c:	6a06                	ld	s4,64(sp)
    80004f6e:	7ae2                	ld	s5,56(sp)
    80004f70:	7b42                	ld	s6,48(sp)
    80004f72:	7ba2                	ld	s7,40(sp)
    80004f74:	7c02                	ld	s8,32(sp)
    80004f76:	6ce2                	ld	s9,24(sp)
    80004f78:	6165                	addi	sp,sp,112
    80004f7a:	8082                	ret
      wakeup(&pi->nread);
    80004f7c:	8566                	mv	a0,s9
    80004f7e:	ffffd097          	auipc	ra,0xffffd
    80004f82:	684080e7          	jalr	1668(ra) # 80002602 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004f86:	85de                	mv	a1,s7
    80004f88:	8562                	mv	a0,s8
    80004f8a:	ffffd097          	auipc	ra,0xffffd
    80004f8e:	4b8080e7          	jalr	1208(ra) # 80002442 <sleep>
    80004f92:	a839                	j	80004fb0 <pipewrite+0xa4>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004f94:	21c4a783          	lw	a5,540(s1)
    80004f98:	0017871b          	addiw	a4,a5,1
    80004f9c:	20e4ae23          	sw	a4,540(s1)
    80004fa0:	1ff7f793          	andi	a5,a5,511
    80004fa4:	97a6                	add	a5,a5,s1
    80004fa6:	f9f44703          	lbu	a4,-97(s0)
    80004faa:	00e78c23          	sb	a4,24(a5)
      i++;
    80004fae:	2905                	addiw	s2,s2,1
  while(i < n){
    80004fb0:	03495d63          	bge	s2,s4,80004fea <pipewrite+0xde>
    if(pi->readopen == 0 || pr->killed){
    80004fb4:	2204a783          	lw	a5,544(s1)
    80004fb8:	dfd1                	beqz	a5,80004f54 <pipewrite+0x48>
    80004fba:	0289a783          	lw	a5,40(s3)
    80004fbe:	fbd9                	bnez	a5,80004f54 <pipewrite+0x48>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004fc0:	2184a783          	lw	a5,536(s1)
    80004fc4:	21c4a703          	lw	a4,540(s1)
    80004fc8:	2007879b          	addiw	a5,a5,512
    80004fcc:	faf708e3          	beq	a4,a5,80004f7c <pipewrite+0x70>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004fd0:	4685                	li	a3,1
    80004fd2:	01590633          	add	a2,s2,s5
    80004fd6:	f9f40593          	addi	a1,s0,-97
    80004fda:	0709b503          	ld	a0,112(s3)
    80004fde:	ffffc097          	auipc	ra,0xffffc
    80004fe2:	728080e7          	jalr	1832(ra) # 80001706 <copyin>
    80004fe6:	fb6517e3          	bne	a0,s6,80004f94 <pipewrite+0x88>
  wakeup(&pi->nread);
    80004fea:	21848513          	addi	a0,s1,536
    80004fee:	ffffd097          	auipc	ra,0xffffd
    80004ff2:	614080e7          	jalr	1556(ra) # 80002602 <wakeup>
  release(&pi->lock);
    80004ff6:	8526                	mv	a0,s1
    80004ff8:	ffffc097          	auipc	ra,0xffffc
    80004ffc:	ca0080e7          	jalr	-864(ra) # 80000c98 <release>
  return i;
    80005000:	b785                	j	80004f60 <pipewrite+0x54>
  int i = 0;
    80005002:	4901                	li	s2,0
    80005004:	b7dd                	j	80004fea <pipewrite+0xde>

0000000080005006 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80005006:	715d                	addi	sp,sp,-80
    80005008:	e486                	sd	ra,72(sp)
    8000500a:	e0a2                	sd	s0,64(sp)
    8000500c:	fc26                	sd	s1,56(sp)
    8000500e:	f84a                	sd	s2,48(sp)
    80005010:	f44e                	sd	s3,40(sp)
    80005012:	f052                	sd	s4,32(sp)
    80005014:	ec56                	sd	s5,24(sp)
    80005016:	e85a                	sd	s6,16(sp)
    80005018:	0880                	addi	s0,sp,80
    8000501a:	84aa                	mv	s1,a0
    8000501c:	892e                	mv	s2,a1
    8000501e:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80005020:	ffffd097          	auipc	ra,0xffffd
    80005024:	9a8080e7          	jalr	-1624(ra) # 800019c8 <myproc>
    80005028:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    8000502a:	8b26                	mv	s6,s1
    8000502c:	8526                	mv	a0,s1
    8000502e:	ffffc097          	auipc	ra,0xffffc
    80005032:	bb6080e7          	jalr	-1098(ra) # 80000be4 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005036:	2184a703          	lw	a4,536(s1)
    8000503a:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    8000503e:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005042:	02f71463          	bne	a4,a5,8000506a <piperead+0x64>
    80005046:	2244a783          	lw	a5,548(s1)
    8000504a:	c385                	beqz	a5,8000506a <piperead+0x64>
    if(pr->killed){
    8000504c:	028a2783          	lw	a5,40(s4)
    80005050:	ebc1                	bnez	a5,800050e0 <piperead+0xda>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80005052:	85da                	mv	a1,s6
    80005054:	854e                	mv	a0,s3
    80005056:	ffffd097          	auipc	ra,0xffffd
    8000505a:	3ec080e7          	jalr	1004(ra) # 80002442 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    8000505e:	2184a703          	lw	a4,536(s1)
    80005062:	21c4a783          	lw	a5,540(s1)
    80005066:	fef700e3          	beq	a4,a5,80005046 <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    8000506a:	09505263          	blez	s5,800050ee <piperead+0xe8>
    8000506e:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80005070:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    80005072:	2184a783          	lw	a5,536(s1)
    80005076:	21c4a703          	lw	a4,540(s1)
    8000507a:	02f70d63          	beq	a4,a5,800050b4 <piperead+0xae>
    ch = pi->data[pi->nread++ % PIPESIZE];
    8000507e:	0017871b          	addiw	a4,a5,1
    80005082:	20e4ac23          	sw	a4,536(s1)
    80005086:	1ff7f793          	andi	a5,a5,511
    8000508a:	97a6                	add	a5,a5,s1
    8000508c:	0187c783          	lbu	a5,24(a5)
    80005090:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80005094:	4685                	li	a3,1
    80005096:	fbf40613          	addi	a2,s0,-65
    8000509a:	85ca                	mv	a1,s2
    8000509c:	070a3503          	ld	a0,112(s4)
    800050a0:	ffffc097          	auipc	ra,0xffffc
    800050a4:	5da080e7          	jalr	1498(ra) # 8000167a <copyout>
    800050a8:	01650663          	beq	a0,s6,800050b4 <piperead+0xae>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    800050ac:	2985                	addiw	s3,s3,1
    800050ae:	0905                	addi	s2,s2,1
    800050b0:	fd3a91e3          	bne	s5,s3,80005072 <piperead+0x6c>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    800050b4:	21c48513          	addi	a0,s1,540
    800050b8:	ffffd097          	auipc	ra,0xffffd
    800050bc:	54a080e7          	jalr	1354(ra) # 80002602 <wakeup>
  release(&pi->lock);
    800050c0:	8526                	mv	a0,s1
    800050c2:	ffffc097          	auipc	ra,0xffffc
    800050c6:	bd6080e7          	jalr	-1066(ra) # 80000c98 <release>
  return i;
}
    800050ca:	854e                	mv	a0,s3
    800050cc:	60a6                	ld	ra,72(sp)
    800050ce:	6406                	ld	s0,64(sp)
    800050d0:	74e2                	ld	s1,56(sp)
    800050d2:	7942                	ld	s2,48(sp)
    800050d4:	79a2                	ld	s3,40(sp)
    800050d6:	7a02                	ld	s4,32(sp)
    800050d8:	6ae2                	ld	s5,24(sp)
    800050da:	6b42                	ld	s6,16(sp)
    800050dc:	6161                	addi	sp,sp,80
    800050de:	8082                	ret
      release(&pi->lock);
    800050e0:	8526                	mv	a0,s1
    800050e2:	ffffc097          	auipc	ra,0xffffc
    800050e6:	bb6080e7          	jalr	-1098(ra) # 80000c98 <release>
      return -1;
    800050ea:	59fd                	li	s3,-1
    800050ec:	bff9                	j	800050ca <piperead+0xc4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    800050ee:	4981                	li	s3,0
    800050f0:	b7d1                	j	800050b4 <piperead+0xae>

00000000800050f2 <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    800050f2:	df010113          	addi	sp,sp,-528
    800050f6:	20113423          	sd	ra,520(sp)
    800050fa:	20813023          	sd	s0,512(sp)
    800050fe:	ffa6                	sd	s1,504(sp)
    80005100:	fbca                	sd	s2,496(sp)
    80005102:	f7ce                	sd	s3,488(sp)
    80005104:	f3d2                	sd	s4,480(sp)
    80005106:	efd6                	sd	s5,472(sp)
    80005108:	ebda                	sd	s6,464(sp)
    8000510a:	e7de                	sd	s7,456(sp)
    8000510c:	e3e2                	sd	s8,448(sp)
    8000510e:	ff66                	sd	s9,440(sp)
    80005110:	fb6a                	sd	s10,432(sp)
    80005112:	f76e                	sd	s11,424(sp)
    80005114:	0c00                	addi	s0,sp,528
    80005116:	84aa                	mv	s1,a0
    80005118:	dea43c23          	sd	a0,-520(s0)
    8000511c:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80005120:	ffffd097          	auipc	ra,0xffffd
    80005124:	8a8080e7          	jalr	-1880(ra) # 800019c8 <myproc>
    80005128:	892a                	mv	s2,a0

  begin_op();
    8000512a:	fffff097          	auipc	ra,0xfffff
    8000512e:	49c080e7          	jalr	1180(ra) # 800045c6 <begin_op>

  if((ip = namei(path)) == 0){
    80005132:	8526                	mv	a0,s1
    80005134:	fffff097          	auipc	ra,0xfffff
    80005138:	276080e7          	jalr	630(ra) # 800043aa <namei>
    8000513c:	c92d                	beqz	a0,800051ae <exec+0xbc>
    8000513e:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80005140:	fffff097          	auipc	ra,0xfffff
    80005144:	ab4080e7          	jalr	-1356(ra) # 80003bf4 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80005148:	04000713          	li	a4,64
    8000514c:	4681                	li	a3,0
    8000514e:	e5040613          	addi	a2,s0,-432
    80005152:	4581                	li	a1,0
    80005154:	8526                	mv	a0,s1
    80005156:	fffff097          	auipc	ra,0xfffff
    8000515a:	d52080e7          	jalr	-686(ra) # 80003ea8 <readi>
    8000515e:	04000793          	li	a5,64
    80005162:	00f51a63          	bne	a0,a5,80005176 <exec+0x84>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80005166:	e5042703          	lw	a4,-432(s0)
    8000516a:	464c47b7          	lui	a5,0x464c4
    8000516e:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80005172:	04f70463          	beq	a4,a5,800051ba <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80005176:	8526                	mv	a0,s1
    80005178:	fffff097          	auipc	ra,0xfffff
    8000517c:	cde080e7          	jalr	-802(ra) # 80003e56 <iunlockput>
    end_op();
    80005180:	fffff097          	auipc	ra,0xfffff
    80005184:	4c6080e7          	jalr	1222(ra) # 80004646 <end_op>
  }
  return -1;
    80005188:	557d                	li	a0,-1
}
    8000518a:	20813083          	ld	ra,520(sp)
    8000518e:	20013403          	ld	s0,512(sp)
    80005192:	74fe                	ld	s1,504(sp)
    80005194:	795e                	ld	s2,496(sp)
    80005196:	79be                	ld	s3,488(sp)
    80005198:	7a1e                	ld	s4,480(sp)
    8000519a:	6afe                	ld	s5,472(sp)
    8000519c:	6b5e                	ld	s6,464(sp)
    8000519e:	6bbe                	ld	s7,456(sp)
    800051a0:	6c1e                	ld	s8,448(sp)
    800051a2:	7cfa                	ld	s9,440(sp)
    800051a4:	7d5a                	ld	s10,432(sp)
    800051a6:	7dba                	ld	s11,424(sp)
    800051a8:	21010113          	addi	sp,sp,528
    800051ac:	8082                	ret
    end_op();
    800051ae:	fffff097          	auipc	ra,0xfffff
    800051b2:	498080e7          	jalr	1176(ra) # 80004646 <end_op>
    return -1;
    800051b6:	557d                	li	a0,-1
    800051b8:	bfc9                	j	8000518a <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    800051ba:	854a                	mv	a0,s2
    800051bc:	ffffd097          	auipc	ra,0xffffd
    800051c0:	8d0080e7          	jalr	-1840(ra) # 80001a8c <proc_pagetable>
    800051c4:	8baa                	mv	s7,a0
    800051c6:	d945                	beqz	a0,80005176 <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800051c8:	e7042983          	lw	s3,-400(s0)
    800051cc:	e8845783          	lhu	a5,-376(s0)
    800051d0:	c7ad                	beqz	a5,8000523a <exec+0x148>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    800051d2:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800051d4:	4b01                	li	s6,0
    if((ph.vaddr % PGSIZE) != 0)
    800051d6:	6c85                	lui	s9,0x1
    800051d8:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    800051dc:	def43823          	sd	a5,-528(s0)
    800051e0:	a42d                	j	8000540a <exec+0x318>
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    800051e2:	00003517          	auipc	a0,0x3
    800051e6:	4fe50513          	addi	a0,a0,1278 # 800086e0 <syscalls+0x290>
    800051ea:	ffffb097          	auipc	ra,0xffffb
    800051ee:	354080e7          	jalr	852(ra) # 8000053e <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    800051f2:	8756                	mv	a4,s5
    800051f4:	012d86bb          	addw	a3,s11,s2
    800051f8:	4581                	li	a1,0
    800051fa:	8526                	mv	a0,s1
    800051fc:	fffff097          	auipc	ra,0xfffff
    80005200:	cac080e7          	jalr	-852(ra) # 80003ea8 <readi>
    80005204:	2501                	sext.w	a0,a0
    80005206:	1aaa9963          	bne	s5,a0,800053b8 <exec+0x2c6>
  for(i = 0; i < sz; i += PGSIZE){
    8000520a:	6785                	lui	a5,0x1
    8000520c:	0127893b          	addw	s2,a5,s2
    80005210:	77fd                	lui	a5,0xfffff
    80005212:	01478a3b          	addw	s4,a5,s4
    80005216:	1f897163          	bgeu	s2,s8,800053f8 <exec+0x306>
    pa = walkaddr(pagetable, va + i);
    8000521a:	02091593          	slli	a1,s2,0x20
    8000521e:	9181                	srli	a1,a1,0x20
    80005220:	95ea                	add	a1,a1,s10
    80005222:	855e                	mv	a0,s7
    80005224:	ffffc097          	auipc	ra,0xffffc
    80005228:	e52080e7          	jalr	-430(ra) # 80001076 <walkaddr>
    8000522c:	862a                	mv	a2,a0
    if(pa == 0)
    8000522e:	d955                	beqz	a0,800051e2 <exec+0xf0>
      n = PGSIZE;
    80005230:	8ae6                	mv	s5,s9
    if(sz - i < PGSIZE)
    80005232:	fd9a70e3          	bgeu	s4,s9,800051f2 <exec+0x100>
      n = sz - i;
    80005236:	8ad2                	mv	s5,s4
    80005238:	bf6d                	j	800051f2 <exec+0x100>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    8000523a:	4901                	li	s2,0
  iunlockput(ip);
    8000523c:	8526                	mv	a0,s1
    8000523e:	fffff097          	auipc	ra,0xfffff
    80005242:	c18080e7          	jalr	-1000(ra) # 80003e56 <iunlockput>
  end_op();
    80005246:	fffff097          	auipc	ra,0xfffff
    8000524a:	400080e7          	jalr	1024(ra) # 80004646 <end_op>
  p = myproc();
    8000524e:	ffffc097          	auipc	ra,0xffffc
    80005252:	77a080e7          	jalr	1914(ra) # 800019c8 <myproc>
    80005256:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    80005258:	06853d03          	ld	s10,104(a0)
  sz = PGROUNDUP(sz);
    8000525c:	6785                	lui	a5,0x1
    8000525e:	17fd                	addi	a5,a5,-1
    80005260:	993e                	add	s2,s2,a5
    80005262:	757d                	lui	a0,0xfffff
    80005264:	00a977b3          	and	a5,s2,a0
    80005268:	e0f43423          	sd	a5,-504(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    8000526c:	6609                	lui	a2,0x2
    8000526e:	963e                	add	a2,a2,a5
    80005270:	85be                	mv	a1,a5
    80005272:	855e                	mv	a0,s7
    80005274:	ffffc097          	auipc	ra,0xffffc
    80005278:	1b6080e7          	jalr	438(ra) # 8000142a <uvmalloc>
    8000527c:	8b2a                	mv	s6,a0
  ip = 0;
    8000527e:	4481                	li	s1,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80005280:	12050c63          	beqz	a0,800053b8 <exec+0x2c6>
  uvmclear(pagetable, sz-2*PGSIZE);
    80005284:	75f9                	lui	a1,0xffffe
    80005286:	95aa                	add	a1,a1,a0
    80005288:	855e                	mv	a0,s7
    8000528a:	ffffc097          	auipc	ra,0xffffc
    8000528e:	3be080e7          	jalr	958(ra) # 80001648 <uvmclear>
  stackbase = sp - PGSIZE;
    80005292:	7c7d                	lui	s8,0xfffff
    80005294:	9c5a                	add	s8,s8,s6
  for(argc = 0; argv[argc]; argc++) {
    80005296:	e0043783          	ld	a5,-512(s0)
    8000529a:	6388                	ld	a0,0(a5)
    8000529c:	c535                	beqz	a0,80005308 <exec+0x216>
    8000529e:	e9040993          	addi	s3,s0,-368
    800052a2:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    800052a6:	895a                	mv	s2,s6
    sp -= strlen(argv[argc]) + 1;
    800052a8:	ffffc097          	auipc	ra,0xffffc
    800052ac:	bbc080e7          	jalr	-1092(ra) # 80000e64 <strlen>
    800052b0:	2505                	addiw	a0,a0,1
    800052b2:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    800052b6:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    800052ba:	13896363          	bltu	s2,s8,800053e0 <exec+0x2ee>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    800052be:	e0043d83          	ld	s11,-512(s0)
    800052c2:	000dba03          	ld	s4,0(s11)
    800052c6:	8552                	mv	a0,s4
    800052c8:	ffffc097          	auipc	ra,0xffffc
    800052cc:	b9c080e7          	jalr	-1124(ra) # 80000e64 <strlen>
    800052d0:	0015069b          	addiw	a3,a0,1
    800052d4:	8652                	mv	a2,s4
    800052d6:	85ca                	mv	a1,s2
    800052d8:	855e                	mv	a0,s7
    800052da:	ffffc097          	auipc	ra,0xffffc
    800052de:	3a0080e7          	jalr	928(ra) # 8000167a <copyout>
    800052e2:	10054363          	bltz	a0,800053e8 <exec+0x2f6>
    ustack[argc] = sp;
    800052e6:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    800052ea:	0485                	addi	s1,s1,1
    800052ec:	008d8793          	addi	a5,s11,8
    800052f0:	e0f43023          	sd	a5,-512(s0)
    800052f4:	008db503          	ld	a0,8(s11)
    800052f8:	c911                	beqz	a0,8000530c <exec+0x21a>
    if(argc >= MAXARG)
    800052fa:	09a1                	addi	s3,s3,8
    800052fc:	fb3c96e3          	bne	s9,s3,800052a8 <exec+0x1b6>
  sz = sz1;
    80005300:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005304:	4481                	li	s1,0
    80005306:	a84d                	j	800053b8 <exec+0x2c6>
  sp = sz;
    80005308:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    8000530a:	4481                	li	s1,0
  ustack[argc] = 0;
    8000530c:	00349793          	slli	a5,s1,0x3
    80005310:	f9040713          	addi	a4,s0,-112
    80005314:	97ba                	add	a5,a5,a4
    80005316:	f007b023          	sd	zero,-256(a5) # f00 <_entry-0x7ffff100>
  sp -= (argc+1) * sizeof(uint64);
    8000531a:	00148693          	addi	a3,s1,1
    8000531e:	068e                	slli	a3,a3,0x3
    80005320:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80005324:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80005328:	01897663          	bgeu	s2,s8,80005334 <exec+0x242>
  sz = sz1;
    8000532c:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005330:	4481                	li	s1,0
    80005332:	a059                	j	800053b8 <exec+0x2c6>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80005334:	e9040613          	addi	a2,s0,-368
    80005338:	85ca                	mv	a1,s2
    8000533a:	855e                	mv	a0,s7
    8000533c:	ffffc097          	auipc	ra,0xffffc
    80005340:	33e080e7          	jalr	830(ra) # 8000167a <copyout>
    80005344:	0a054663          	bltz	a0,800053f0 <exec+0x2fe>
  p->trapframe->a1 = sp;
    80005348:	078ab783          	ld	a5,120(s5)
    8000534c:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80005350:	df843783          	ld	a5,-520(s0)
    80005354:	0007c703          	lbu	a4,0(a5)
    80005358:	cf11                	beqz	a4,80005374 <exec+0x282>
    8000535a:	0785                	addi	a5,a5,1
    if(*s == '/')
    8000535c:	02f00693          	li	a3,47
    80005360:	a039                	j	8000536e <exec+0x27c>
      last = s+1;
    80005362:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    80005366:	0785                	addi	a5,a5,1
    80005368:	fff7c703          	lbu	a4,-1(a5)
    8000536c:	c701                	beqz	a4,80005374 <exec+0x282>
    if(*s == '/')
    8000536e:	fed71ce3          	bne	a4,a3,80005366 <exec+0x274>
    80005372:	bfc5                	j	80005362 <exec+0x270>
  safestrcpy(p->name, last, sizeof(p->name));
    80005374:	4641                	li	a2,16
    80005376:	df843583          	ld	a1,-520(s0)
    8000537a:	178a8513          	addi	a0,s5,376
    8000537e:	ffffc097          	auipc	ra,0xffffc
    80005382:	ab4080e7          	jalr	-1356(ra) # 80000e32 <safestrcpy>
  oldpagetable = p->pagetable;
    80005386:	070ab503          	ld	a0,112(s5)
  p->pagetable = pagetable;
    8000538a:	077ab823          	sd	s7,112(s5)
  p->sz = sz;
    8000538e:	076ab423          	sd	s6,104(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80005392:	078ab783          	ld	a5,120(s5)
    80005396:	e6843703          	ld	a4,-408(s0)
    8000539a:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    8000539c:	078ab783          	ld	a5,120(s5)
    800053a0:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    800053a4:	85ea                	mv	a1,s10
    800053a6:	ffffc097          	auipc	ra,0xffffc
    800053aa:	782080e7          	jalr	1922(ra) # 80001b28 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    800053ae:	0004851b          	sext.w	a0,s1
    800053b2:	bbe1                	j	8000518a <exec+0x98>
    800053b4:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    800053b8:	e0843583          	ld	a1,-504(s0)
    800053bc:	855e                	mv	a0,s7
    800053be:	ffffc097          	auipc	ra,0xffffc
    800053c2:	76a080e7          	jalr	1898(ra) # 80001b28 <proc_freepagetable>
  if(ip){
    800053c6:	da0498e3          	bnez	s1,80005176 <exec+0x84>
  return -1;
    800053ca:	557d                	li	a0,-1
    800053cc:	bb7d                	j	8000518a <exec+0x98>
    800053ce:	e1243423          	sd	s2,-504(s0)
    800053d2:	b7dd                	j	800053b8 <exec+0x2c6>
    800053d4:	e1243423          	sd	s2,-504(s0)
    800053d8:	b7c5                	j	800053b8 <exec+0x2c6>
    800053da:	e1243423          	sd	s2,-504(s0)
    800053de:	bfe9                	j	800053b8 <exec+0x2c6>
  sz = sz1;
    800053e0:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800053e4:	4481                	li	s1,0
    800053e6:	bfc9                	j	800053b8 <exec+0x2c6>
  sz = sz1;
    800053e8:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800053ec:	4481                	li	s1,0
    800053ee:	b7e9                	j	800053b8 <exec+0x2c6>
  sz = sz1;
    800053f0:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800053f4:	4481                	li	s1,0
    800053f6:	b7c9                	j	800053b8 <exec+0x2c6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    800053f8:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800053fc:	2b05                	addiw	s6,s6,1
    800053fe:	0389899b          	addiw	s3,s3,56
    80005402:	e8845783          	lhu	a5,-376(s0)
    80005406:	e2fb5be3          	bge	s6,a5,8000523c <exec+0x14a>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    8000540a:	2981                	sext.w	s3,s3
    8000540c:	03800713          	li	a4,56
    80005410:	86ce                	mv	a3,s3
    80005412:	e1840613          	addi	a2,s0,-488
    80005416:	4581                	li	a1,0
    80005418:	8526                	mv	a0,s1
    8000541a:	fffff097          	auipc	ra,0xfffff
    8000541e:	a8e080e7          	jalr	-1394(ra) # 80003ea8 <readi>
    80005422:	03800793          	li	a5,56
    80005426:	f8f517e3          	bne	a0,a5,800053b4 <exec+0x2c2>
    if(ph.type != ELF_PROG_LOAD)
    8000542a:	e1842783          	lw	a5,-488(s0)
    8000542e:	4705                	li	a4,1
    80005430:	fce796e3          	bne	a5,a4,800053fc <exec+0x30a>
    if(ph.memsz < ph.filesz)
    80005434:	e4043603          	ld	a2,-448(s0)
    80005438:	e3843783          	ld	a5,-456(s0)
    8000543c:	f8f669e3          	bltu	a2,a5,800053ce <exec+0x2dc>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80005440:	e2843783          	ld	a5,-472(s0)
    80005444:	963e                	add	a2,a2,a5
    80005446:	f8f667e3          	bltu	a2,a5,800053d4 <exec+0x2e2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    8000544a:	85ca                	mv	a1,s2
    8000544c:	855e                	mv	a0,s7
    8000544e:	ffffc097          	auipc	ra,0xffffc
    80005452:	fdc080e7          	jalr	-36(ra) # 8000142a <uvmalloc>
    80005456:	e0a43423          	sd	a0,-504(s0)
    8000545a:	d141                	beqz	a0,800053da <exec+0x2e8>
    if((ph.vaddr % PGSIZE) != 0)
    8000545c:	e2843d03          	ld	s10,-472(s0)
    80005460:	df043783          	ld	a5,-528(s0)
    80005464:	00fd77b3          	and	a5,s10,a5
    80005468:	fba1                	bnez	a5,800053b8 <exec+0x2c6>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    8000546a:	e2042d83          	lw	s11,-480(s0)
    8000546e:	e3842c03          	lw	s8,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80005472:	f80c03e3          	beqz	s8,800053f8 <exec+0x306>
    80005476:	8a62                	mv	s4,s8
    80005478:	4901                	li	s2,0
    8000547a:	b345                	j	8000521a <exec+0x128>

000000008000547c <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    8000547c:	7179                	addi	sp,sp,-48
    8000547e:	f406                	sd	ra,40(sp)
    80005480:	f022                	sd	s0,32(sp)
    80005482:	ec26                	sd	s1,24(sp)
    80005484:	e84a                	sd	s2,16(sp)
    80005486:	1800                	addi	s0,sp,48
    80005488:	892e                	mv	s2,a1
    8000548a:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    8000548c:	fdc40593          	addi	a1,s0,-36
    80005490:	ffffe097          	auipc	ra,0xffffe
    80005494:	ba4080e7          	jalr	-1116(ra) # 80003034 <argint>
    80005498:	04054063          	bltz	a0,800054d8 <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    8000549c:	fdc42703          	lw	a4,-36(s0)
    800054a0:	47bd                	li	a5,15
    800054a2:	02e7ed63          	bltu	a5,a4,800054dc <argfd+0x60>
    800054a6:	ffffc097          	auipc	ra,0xffffc
    800054aa:	522080e7          	jalr	1314(ra) # 800019c8 <myproc>
    800054ae:	fdc42703          	lw	a4,-36(s0)
    800054b2:	01e70793          	addi	a5,a4,30
    800054b6:	078e                	slli	a5,a5,0x3
    800054b8:	953e                	add	a0,a0,a5
    800054ba:	611c                	ld	a5,0(a0)
    800054bc:	c395                	beqz	a5,800054e0 <argfd+0x64>
    return -1;
  if(pfd)
    800054be:	00090463          	beqz	s2,800054c6 <argfd+0x4a>
    *pfd = fd;
    800054c2:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    800054c6:	4501                	li	a0,0
  if(pf)
    800054c8:	c091                	beqz	s1,800054cc <argfd+0x50>
    *pf = f;
    800054ca:	e09c                	sd	a5,0(s1)
}
    800054cc:	70a2                	ld	ra,40(sp)
    800054ce:	7402                	ld	s0,32(sp)
    800054d0:	64e2                	ld	s1,24(sp)
    800054d2:	6942                	ld	s2,16(sp)
    800054d4:	6145                	addi	sp,sp,48
    800054d6:	8082                	ret
    return -1;
    800054d8:	557d                	li	a0,-1
    800054da:	bfcd                	j	800054cc <argfd+0x50>
    return -1;
    800054dc:	557d                	li	a0,-1
    800054de:	b7fd                	j	800054cc <argfd+0x50>
    800054e0:	557d                	li	a0,-1
    800054e2:	b7ed                	j	800054cc <argfd+0x50>

00000000800054e4 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    800054e4:	1101                	addi	sp,sp,-32
    800054e6:	ec06                	sd	ra,24(sp)
    800054e8:	e822                	sd	s0,16(sp)
    800054ea:	e426                	sd	s1,8(sp)
    800054ec:	1000                	addi	s0,sp,32
    800054ee:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    800054f0:	ffffc097          	auipc	ra,0xffffc
    800054f4:	4d8080e7          	jalr	1240(ra) # 800019c8 <myproc>
    800054f8:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    800054fa:	0f050793          	addi	a5,a0,240 # fffffffffffff0f0 <end+0xffffffff7ffd90f0>
    800054fe:	4501                	li	a0,0
    80005500:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80005502:	6398                	ld	a4,0(a5)
    80005504:	cb19                	beqz	a4,8000551a <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80005506:	2505                	addiw	a0,a0,1
    80005508:	07a1                	addi	a5,a5,8
    8000550a:	fed51ce3          	bne	a0,a3,80005502 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    8000550e:	557d                	li	a0,-1
}
    80005510:	60e2                	ld	ra,24(sp)
    80005512:	6442                	ld	s0,16(sp)
    80005514:	64a2                	ld	s1,8(sp)
    80005516:	6105                	addi	sp,sp,32
    80005518:	8082                	ret
      p->ofile[fd] = f;
    8000551a:	01e50793          	addi	a5,a0,30
    8000551e:	078e                	slli	a5,a5,0x3
    80005520:	963e                	add	a2,a2,a5
    80005522:	e204                	sd	s1,0(a2)
      return fd;
    80005524:	b7f5                	j	80005510 <fdalloc+0x2c>

0000000080005526 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80005526:	715d                	addi	sp,sp,-80
    80005528:	e486                	sd	ra,72(sp)
    8000552a:	e0a2                	sd	s0,64(sp)
    8000552c:	fc26                	sd	s1,56(sp)
    8000552e:	f84a                	sd	s2,48(sp)
    80005530:	f44e                	sd	s3,40(sp)
    80005532:	f052                	sd	s4,32(sp)
    80005534:	ec56                	sd	s5,24(sp)
    80005536:	0880                	addi	s0,sp,80
    80005538:	89ae                	mv	s3,a1
    8000553a:	8ab2                	mv	s5,a2
    8000553c:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    8000553e:	fb040593          	addi	a1,s0,-80
    80005542:	fffff097          	auipc	ra,0xfffff
    80005546:	e86080e7          	jalr	-378(ra) # 800043c8 <nameiparent>
    8000554a:	892a                	mv	s2,a0
    8000554c:	12050f63          	beqz	a0,8000568a <create+0x164>
    return 0;

  ilock(dp);
    80005550:	ffffe097          	auipc	ra,0xffffe
    80005554:	6a4080e7          	jalr	1700(ra) # 80003bf4 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80005558:	4601                	li	a2,0
    8000555a:	fb040593          	addi	a1,s0,-80
    8000555e:	854a                	mv	a0,s2
    80005560:	fffff097          	auipc	ra,0xfffff
    80005564:	b78080e7          	jalr	-1160(ra) # 800040d8 <dirlookup>
    80005568:	84aa                	mv	s1,a0
    8000556a:	c921                	beqz	a0,800055ba <create+0x94>
    iunlockput(dp);
    8000556c:	854a                	mv	a0,s2
    8000556e:	fffff097          	auipc	ra,0xfffff
    80005572:	8e8080e7          	jalr	-1816(ra) # 80003e56 <iunlockput>
    ilock(ip);
    80005576:	8526                	mv	a0,s1
    80005578:	ffffe097          	auipc	ra,0xffffe
    8000557c:	67c080e7          	jalr	1660(ra) # 80003bf4 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80005580:	2981                	sext.w	s3,s3
    80005582:	4789                	li	a5,2
    80005584:	02f99463          	bne	s3,a5,800055ac <create+0x86>
    80005588:	0444d783          	lhu	a5,68(s1)
    8000558c:	37f9                	addiw	a5,a5,-2
    8000558e:	17c2                	slli	a5,a5,0x30
    80005590:	93c1                	srli	a5,a5,0x30
    80005592:	4705                	li	a4,1
    80005594:	00f76c63          	bltu	a4,a5,800055ac <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    80005598:	8526                	mv	a0,s1
    8000559a:	60a6                	ld	ra,72(sp)
    8000559c:	6406                	ld	s0,64(sp)
    8000559e:	74e2                	ld	s1,56(sp)
    800055a0:	7942                	ld	s2,48(sp)
    800055a2:	79a2                	ld	s3,40(sp)
    800055a4:	7a02                	ld	s4,32(sp)
    800055a6:	6ae2                	ld	s5,24(sp)
    800055a8:	6161                	addi	sp,sp,80
    800055aa:	8082                	ret
    iunlockput(ip);
    800055ac:	8526                	mv	a0,s1
    800055ae:	fffff097          	auipc	ra,0xfffff
    800055b2:	8a8080e7          	jalr	-1880(ra) # 80003e56 <iunlockput>
    return 0;
    800055b6:	4481                	li	s1,0
    800055b8:	b7c5                	j	80005598 <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    800055ba:	85ce                	mv	a1,s3
    800055bc:	00092503          	lw	a0,0(s2)
    800055c0:	ffffe097          	auipc	ra,0xffffe
    800055c4:	49c080e7          	jalr	1180(ra) # 80003a5c <ialloc>
    800055c8:	84aa                	mv	s1,a0
    800055ca:	c529                	beqz	a0,80005614 <create+0xee>
  ilock(ip);
    800055cc:	ffffe097          	auipc	ra,0xffffe
    800055d0:	628080e7          	jalr	1576(ra) # 80003bf4 <ilock>
  ip->major = major;
    800055d4:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    800055d8:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    800055dc:	4785                	li	a5,1
    800055de:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800055e2:	8526                	mv	a0,s1
    800055e4:	ffffe097          	auipc	ra,0xffffe
    800055e8:	546080e7          	jalr	1350(ra) # 80003b2a <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    800055ec:	2981                	sext.w	s3,s3
    800055ee:	4785                	li	a5,1
    800055f0:	02f98a63          	beq	s3,a5,80005624 <create+0xfe>
  if(dirlink(dp, name, ip->inum) < 0)
    800055f4:	40d0                	lw	a2,4(s1)
    800055f6:	fb040593          	addi	a1,s0,-80
    800055fa:	854a                	mv	a0,s2
    800055fc:	fffff097          	auipc	ra,0xfffff
    80005600:	cec080e7          	jalr	-788(ra) # 800042e8 <dirlink>
    80005604:	06054b63          	bltz	a0,8000567a <create+0x154>
  iunlockput(dp);
    80005608:	854a                	mv	a0,s2
    8000560a:	fffff097          	auipc	ra,0xfffff
    8000560e:	84c080e7          	jalr	-1972(ra) # 80003e56 <iunlockput>
  return ip;
    80005612:	b759                	j	80005598 <create+0x72>
    panic("create: ialloc");
    80005614:	00003517          	auipc	a0,0x3
    80005618:	0ec50513          	addi	a0,a0,236 # 80008700 <syscalls+0x2b0>
    8000561c:	ffffb097          	auipc	ra,0xffffb
    80005620:	f22080e7          	jalr	-222(ra) # 8000053e <panic>
    dp->nlink++;  // for ".."
    80005624:	04a95783          	lhu	a5,74(s2)
    80005628:	2785                	addiw	a5,a5,1
    8000562a:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    8000562e:	854a                	mv	a0,s2
    80005630:	ffffe097          	auipc	ra,0xffffe
    80005634:	4fa080e7          	jalr	1274(ra) # 80003b2a <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80005638:	40d0                	lw	a2,4(s1)
    8000563a:	00003597          	auipc	a1,0x3
    8000563e:	0d658593          	addi	a1,a1,214 # 80008710 <syscalls+0x2c0>
    80005642:	8526                	mv	a0,s1
    80005644:	fffff097          	auipc	ra,0xfffff
    80005648:	ca4080e7          	jalr	-860(ra) # 800042e8 <dirlink>
    8000564c:	00054f63          	bltz	a0,8000566a <create+0x144>
    80005650:	00492603          	lw	a2,4(s2)
    80005654:	00003597          	auipc	a1,0x3
    80005658:	0c458593          	addi	a1,a1,196 # 80008718 <syscalls+0x2c8>
    8000565c:	8526                	mv	a0,s1
    8000565e:	fffff097          	auipc	ra,0xfffff
    80005662:	c8a080e7          	jalr	-886(ra) # 800042e8 <dirlink>
    80005666:	f80557e3          	bgez	a0,800055f4 <create+0xce>
      panic("create dots");
    8000566a:	00003517          	auipc	a0,0x3
    8000566e:	0b650513          	addi	a0,a0,182 # 80008720 <syscalls+0x2d0>
    80005672:	ffffb097          	auipc	ra,0xffffb
    80005676:	ecc080e7          	jalr	-308(ra) # 8000053e <panic>
    panic("create: dirlink");
    8000567a:	00003517          	auipc	a0,0x3
    8000567e:	0b650513          	addi	a0,a0,182 # 80008730 <syscalls+0x2e0>
    80005682:	ffffb097          	auipc	ra,0xffffb
    80005686:	ebc080e7          	jalr	-324(ra) # 8000053e <panic>
    return 0;
    8000568a:	84aa                	mv	s1,a0
    8000568c:	b731                	j	80005598 <create+0x72>

000000008000568e <sys_dup>:
{
    8000568e:	7179                	addi	sp,sp,-48
    80005690:	f406                	sd	ra,40(sp)
    80005692:	f022                	sd	s0,32(sp)
    80005694:	ec26                	sd	s1,24(sp)
    80005696:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    80005698:	fd840613          	addi	a2,s0,-40
    8000569c:	4581                	li	a1,0
    8000569e:	4501                	li	a0,0
    800056a0:	00000097          	auipc	ra,0x0
    800056a4:	ddc080e7          	jalr	-548(ra) # 8000547c <argfd>
    return -1;
    800056a8:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    800056aa:	02054363          	bltz	a0,800056d0 <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    800056ae:	fd843503          	ld	a0,-40(s0)
    800056b2:	00000097          	auipc	ra,0x0
    800056b6:	e32080e7          	jalr	-462(ra) # 800054e4 <fdalloc>
    800056ba:	84aa                	mv	s1,a0
    return -1;
    800056bc:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    800056be:	00054963          	bltz	a0,800056d0 <sys_dup+0x42>
  filedup(f);
    800056c2:	fd843503          	ld	a0,-40(s0)
    800056c6:	fffff097          	auipc	ra,0xfffff
    800056ca:	37a080e7          	jalr	890(ra) # 80004a40 <filedup>
  return fd;
    800056ce:	87a6                	mv	a5,s1
}
    800056d0:	853e                	mv	a0,a5
    800056d2:	70a2                	ld	ra,40(sp)
    800056d4:	7402                	ld	s0,32(sp)
    800056d6:	64e2                	ld	s1,24(sp)
    800056d8:	6145                	addi	sp,sp,48
    800056da:	8082                	ret

00000000800056dc <sys_read>:
{
    800056dc:	7179                	addi	sp,sp,-48
    800056de:	f406                	sd	ra,40(sp)
    800056e0:	f022                	sd	s0,32(sp)
    800056e2:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800056e4:	fe840613          	addi	a2,s0,-24
    800056e8:	4581                	li	a1,0
    800056ea:	4501                	li	a0,0
    800056ec:	00000097          	auipc	ra,0x0
    800056f0:	d90080e7          	jalr	-624(ra) # 8000547c <argfd>
    return -1;
    800056f4:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800056f6:	04054163          	bltz	a0,80005738 <sys_read+0x5c>
    800056fa:	fe440593          	addi	a1,s0,-28
    800056fe:	4509                	li	a0,2
    80005700:	ffffe097          	auipc	ra,0xffffe
    80005704:	934080e7          	jalr	-1740(ra) # 80003034 <argint>
    return -1;
    80005708:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000570a:	02054763          	bltz	a0,80005738 <sys_read+0x5c>
    8000570e:	fd840593          	addi	a1,s0,-40
    80005712:	4505                	li	a0,1
    80005714:	ffffe097          	auipc	ra,0xffffe
    80005718:	942080e7          	jalr	-1726(ra) # 80003056 <argaddr>
    return -1;
    8000571c:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000571e:	00054d63          	bltz	a0,80005738 <sys_read+0x5c>
  return fileread(f, p, n);
    80005722:	fe442603          	lw	a2,-28(s0)
    80005726:	fd843583          	ld	a1,-40(s0)
    8000572a:	fe843503          	ld	a0,-24(s0)
    8000572e:	fffff097          	auipc	ra,0xfffff
    80005732:	49e080e7          	jalr	1182(ra) # 80004bcc <fileread>
    80005736:	87aa                	mv	a5,a0
}
    80005738:	853e                	mv	a0,a5
    8000573a:	70a2                	ld	ra,40(sp)
    8000573c:	7402                	ld	s0,32(sp)
    8000573e:	6145                	addi	sp,sp,48
    80005740:	8082                	ret

0000000080005742 <sys_write>:
{
    80005742:	7179                	addi	sp,sp,-48
    80005744:	f406                	sd	ra,40(sp)
    80005746:	f022                	sd	s0,32(sp)
    80005748:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000574a:	fe840613          	addi	a2,s0,-24
    8000574e:	4581                	li	a1,0
    80005750:	4501                	li	a0,0
    80005752:	00000097          	auipc	ra,0x0
    80005756:	d2a080e7          	jalr	-726(ra) # 8000547c <argfd>
    return -1;
    8000575a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000575c:	04054163          	bltz	a0,8000579e <sys_write+0x5c>
    80005760:	fe440593          	addi	a1,s0,-28
    80005764:	4509                	li	a0,2
    80005766:	ffffe097          	auipc	ra,0xffffe
    8000576a:	8ce080e7          	jalr	-1842(ra) # 80003034 <argint>
    return -1;
    8000576e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005770:	02054763          	bltz	a0,8000579e <sys_write+0x5c>
    80005774:	fd840593          	addi	a1,s0,-40
    80005778:	4505                	li	a0,1
    8000577a:	ffffe097          	auipc	ra,0xffffe
    8000577e:	8dc080e7          	jalr	-1828(ra) # 80003056 <argaddr>
    return -1;
    80005782:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005784:	00054d63          	bltz	a0,8000579e <sys_write+0x5c>
  return filewrite(f, p, n);
    80005788:	fe442603          	lw	a2,-28(s0)
    8000578c:	fd843583          	ld	a1,-40(s0)
    80005790:	fe843503          	ld	a0,-24(s0)
    80005794:	fffff097          	auipc	ra,0xfffff
    80005798:	4fa080e7          	jalr	1274(ra) # 80004c8e <filewrite>
    8000579c:	87aa                	mv	a5,a0
}
    8000579e:	853e                	mv	a0,a5
    800057a0:	70a2                	ld	ra,40(sp)
    800057a2:	7402                	ld	s0,32(sp)
    800057a4:	6145                	addi	sp,sp,48
    800057a6:	8082                	ret

00000000800057a8 <sys_close>:
{
    800057a8:	1101                	addi	sp,sp,-32
    800057aa:	ec06                	sd	ra,24(sp)
    800057ac:	e822                	sd	s0,16(sp)
    800057ae:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    800057b0:	fe040613          	addi	a2,s0,-32
    800057b4:	fec40593          	addi	a1,s0,-20
    800057b8:	4501                	li	a0,0
    800057ba:	00000097          	auipc	ra,0x0
    800057be:	cc2080e7          	jalr	-830(ra) # 8000547c <argfd>
    return -1;
    800057c2:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    800057c4:	02054463          	bltz	a0,800057ec <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    800057c8:	ffffc097          	auipc	ra,0xffffc
    800057cc:	200080e7          	jalr	512(ra) # 800019c8 <myproc>
    800057d0:	fec42783          	lw	a5,-20(s0)
    800057d4:	07f9                	addi	a5,a5,30
    800057d6:	078e                	slli	a5,a5,0x3
    800057d8:	97aa                	add	a5,a5,a0
    800057da:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    800057de:	fe043503          	ld	a0,-32(s0)
    800057e2:	fffff097          	auipc	ra,0xfffff
    800057e6:	2b0080e7          	jalr	688(ra) # 80004a92 <fileclose>
  return 0;
    800057ea:	4781                	li	a5,0
}
    800057ec:	853e                	mv	a0,a5
    800057ee:	60e2                	ld	ra,24(sp)
    800057f0:	6442                	ld	s0,16(sp)
    800057f2:	6105                	addi	sp,sp,32
    800057f4:	8082                	ret

00000000800057f6 <sys_fstat>:
{
    800057f6:	1101                	addi	sp,sp,-32
    800057f8:	ec06                	sd	ra,24(sp)
    800057fa:	e822                	sd	s0,16(sp)
    800057fc:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800057fe:	fe840613          	addi	a2,s0,-24
    80005802:	4581                	li	a1,0
    80005804:	4501                	li	a0,0
    80005806:	00000097          	auipc	ra,0x0
    8000580a:	c76080e7          	jalr	-906(ra) # 8000547c <argfd>
    return -1;
    8000580e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005810:	02054563          	bltz	a0,8000583a <sys_fstat+0x44>
    80005814:	fe040593          	addi	a1,s0,-32
    80005818:	4505                	li	a0,1
    8000581a:	ffffe097          	auipc	ra,0xffffe
    8000581e:	83c080e7          	jalr	-1988(ra) # 80003056 <argaddr>
    return -1;
    80005822:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005824:	00054b63          	bltz	a0,8000583a <sys_fstat+0x44>
  return filestat(f, st);
    80005828:	fe043583          	ld	a1,-32(s0)
    8000582c:	fe843503          	ld	a0,-24(s0)
    80005830:	fffff097          	auipc	ra,0xfffff
    80005834:	32a080e7          	jalr	810(ra) # 80004b5a <filestat>
    80005838:	87aa                	mv	a5,a0
}
    8000583a:	853e                	mv	a0,a5
    8000583c:	60e2                	ld	ra,24(sp)
    8000583e:	6442                	ld	s0,16(sp)
    80005840:	6105                	addi	sp,sp,32
    80005842:	8082                	ret

0000000080005844 <sys_link>:
{
    80005844:	7169                	addi	sp,sp,-304
    80005846:	f606                	sd	ra,296(sp)
    80005848:	f222                	sd	s0,288(sp)
    8000584a:	ee26                	sd	s1,280(sp)
    8000584c:	ea4a                	sd	s2,272(sp)
    8000584e:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005850:	08000613          	li	a2,128
    80005854:	ed040593          	addi	a1,s0,-304
    80005858:	4501                	li	a0,0
    8000585a:	ffffe097          	auipc	ra,0xffffe
    8000585e:	81e080e7          	jalr	-2018(ra) # 80003078 <argstr>
    return -1;
    80005862:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005864:	10054e63          	bltz	a0,80005980 <sys_link+0x13c>
    80005868:	08000613          	li	a2,128
    8000586c:	f5040593          	addi	a1,s0,-176
    80005870:	4505                	li	a0,1
    80005872:	ffffe097          	auipc	ra,0xffffe
    80005876:	806080e7          	jalr	-2042(ra) # 80003078 <argstr>
    return -1;
    8000587a:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000587c:	10054263          	bltz	a0,80005980 <sys_link+0x13c>
  begin_op();
    80005880:	fffff097          	auipc	ra,0xfffff
    80005884:	d46080e7          	jalr	-698(ra) # 800045c6 <begin_op>
  if((ip = namei(old)) == 0){
    80005888:	ed040513          	addi	a0,s0,-304
    8000588c:	fffff097          	auipc	ra,0xfffff
    80005890:	b1e080e7          	jalr	-1250(ra) # 800043aa <namei>
    80005894:	84aa                	mv	s1,a0
    80005896:	c551                	beqz	a0,80005922 <sys_link+0xde>
  ilock(ip);
    80005898:	ffffe097          	auipc	ra,0xffffe
    8000589c:	35c080e7          	jalr	860(ra) # 80003bf4 <ilock>
  if(ip->type == T_DIR){
    800058a0:	04449703          	lh	a4,68(s1)
    800058a4:	4785                	li	a5,1
    800058a6:	08f70463          	beq	a4,a5,8000592e <sys_link+0xea>
  ip->nlink++;
    800058aa:	04a4d783          	lhu	a5,74(s1)
    800058ae:	2785                	addiw	a5,a5,1
    800058b0:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800058b4:	8526                	mv	a0,s1
    800058b6:	ffffe097          	auipc	ra,0xffffe
    800058ba:	274080e7          	jalr	628(ra) # 80003b2a <iupdate>
  iunlock(ip);
    800058be:	8526                	mv	a0,s1
    800058c0:	ffffe097          	auipc	ra,0xffffe
    800058c4:	3f6080e7          	jalr	1014(ra) # 80003cb6 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    800058c8:	fd040593          	addi	a1,s0,-48
    800058cc:	f5040513          	addi	a0,s0,-176
    800058d0:	fffff097          	auipc	ra,0xfffff
    800058d4:	af8080e7          	jalr	-1288(ra) # 800043c8 <nameiparent>
    800058d8:	892a                	mv	s2,a0
    800058da:	c935                	beqz	a0,8000594e <sys_link+0x10a>
  ilock(dp);
    800058dc:	ffffe097          	auipc	ra,0xffffe
    800058e0:	318080e7          	jalr	792(ra) # 80003bf4 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    800058e4:	00092703          	lw	a4,0(s2)
    800058e8:	409c                	lw	a5,0(s1)
    800058ea:	04f71d63          	bne	a4,a5,80005944 <sys_link+0x100>
    800058ee:	40d0                	lw	a2,4(s1)
    800058f0:	fd040593          	addi	a1,s0,-48
    800058f4:	854a                	mv	a0,s2
    800058f6:	fffff097          	auipc	ra,0xfffff
    800058fa:	9f2080e7          	jalr	-1550(ra) # 800042e8 <dirlink>
    800058fe:	04054363          	bltz	a0,80005944 <sys_link+0x100>
  iunlockput(dp);
    80005902:	854a                	mv	a0,s2
    80005904:	ffffe097          	auipc	ra,0xffffe
    80005908:	552080e7          	jalr	1362(ra) # 80003e56 <iunlockput>
  iput(ip);
    8000590c:	8526                	mv	a0,s1
    8000590e:	ffffe097          	auipc	ra,0xffffe
    80005912:	4a0080e7          	jalr	1184(ra) # 80003dae <iput>
  end_op();
    80005916:	fffff097          	auipc	ra,0xfffff
    8000591a:	d30080e7          	jalr	-720(ra) # 80004646 <end_op>
  return 0;
    8000591e:	4781                	li	a5,0
    80005920:	a085                	j	80005980 <sys_link+0x13c>
    end_op();
    80005922:	fffff097          	auipc	ra,0xfffff
    80005926:	d24080e7          	jalr	-732(ra) # 80004646 <end_op>
    return -1;
    8000592a:	57fd                	li	a5,-1
    8000592c:	a891                	j	80005980 <sys_link+0x13c>
    iunlockput(ip);
    8000592e:	8526                	mv	a0,s1
    80005930:	ffffe097          	auipc	ra,0xffffe
    80005934:	526080e7          	jalr	1318(ra) # 80003e56 <iunlockput>
    end_op();
    80005938:	fffff097          	auipc	ra,0xfffff
    8000593c:	d0e080e7          	jalr	-754(ra) # 80004646 <end_op>
    return -1;
    80005940:	57fd                	li	a5,-1
    80005942:	a83d                	j	80005980 <sys_link+0x13c>
    iunlockput(dp);
    80005944:	854a                	mv	a0,s2
    80005946:	ffffe097          	auipc	ra,0xffffe
    8000594a:	510080e7          	jalr	1296(ra) # 80003e56 <iunlockput>
  ilock(ip);
    8000594e:	8526                	mv	a0,s1
    80005950:	ffffe097          	auipc	ra,0xffffe
    80005954:	2a4080e7          	jalr	676(ra) # 80003bf4 <ilock>
  ip->nlink--;
    80005958:	04a4d783          	lhu	a5,74(s1)
    8000595c:	37fd                	addiw	a5,a5,-1
    8000595e:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005962:	8526                	mv	a0,s1
    80005964:	ffffe097          	auipc	ra,0xffffe
    80005968:	1c6080e7          	jalr	454(ra) # 80003b2a <iupdate>
  iunlockput(ip);
    8000596c:	8526                	mv	a0,s1
    8000596e:	ffffe097          	auipc	ra,0xffffe
    80005972:	4e8080e7          	jalr	1256(ra) # 80003e56 <iunlockput>
  end_op();
    80005976:	fffff097          	auipc	ra,0xfffff
    8000597a:	cd0080e7          	jalr	-816(ra) # 80004646 <end_op>
  return -1;
    8000597e:	57fd                	li	a5,-1
}
    80005980:	853e                	mv	a0,a5
    80005982:	70b2                	ld	ra,296(sp)
    80005984:	7412                	ld	s0,288(sp)
    80005986:	64f2                	ld	s1,280(sp)
    80005988:	6952                	ld	s2,272(sp)
    8000598a:	6155                	addi	sp,sp,304
    8000598c:	8082                	ret

000000008000598e <sys_unlink>:
{
    8000598e:	7151                	addi	sp,sp,-240
    80005990:	f586                	sd	ra,232(sp)
    80005992:	f1a2                	sd	s0,224(sp)
    80005994:	eda6                	sd	s1,216(sp)
    80005996:	e9ca                	sd	s2,208(sp)
    80005998:	e5ce                	sd	s3,200(sp)
    8000599a:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    8000599c:	08000613          	li	a2,128
    800059a0:	f3040593          	addi	a1,s0,-208
    800059a4:	4501                	li	a0,0
    800059a6:	ffffd097          	auipc	ra,0xffffd
    800059aa:	6d2080e7          	jalr	1746(ra) # 80003078 <argstr>
    800059ae:	18054163          	bltz	a0,80005b30 <sys_unlink+0x1a2>
  begin_op();
    800059b2:	fffff097          	auipc	ra,0xfffff
    800059b6:	c14080e7          	jalr	-1004(ra) # 800045c6 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    800059ba:	fb040593          	addi	a1,s0,-80
    800059be:	f3040513          	addi	a0,s0,-208
    800059c2:	fffff097          	auipc	ra,0xfffff
    800059c6:	a06080e7          	jalr	-1530(ra) # 800043c8 <nameiparent>
    800059ca:	84aa                	mv	s1,a0
    800059cc:	c979                	beqz	a0,80005aa2 <sys_unlink+0x114>
  ilock(dp);
    800059ce:	ffffe097          	auipc	ra,0xffffe
    800059d2:	226080e7          	jalr	550(ra) # 80003bf4 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    800059d6:	00003597          	auipc	a1,0x3
    800059da:	d3a58593          	addi	a1,a1,-710 # 80008710 <syscalls+0x2c0>
    800059de:	fb040513          	addi	a0,s0,-80
    800059e2:	ffffe097          	auipc	ra,0xffffe
    800059e6:	6dc080e7          	jalr	1756(ra) # 800040be <namecmp>
    800059ea:	14050a63          	beqz	a0,80005b3e <sys_unlink+0x1b0>
    800059ee:	00003597          	auipc	a1,0x3
    800059f2:	d2a58593          	addi	a1,a1,-726 # 80008718 <syscalls+0x2c8>
    800059f6:	fb040513          	addi	a0,s0,-80
    800059fa:	ffffe097          	auipc	ra,0xffffe
    800059fe:	6c4080e7          	jalr	1732(ra) # 800040be <namecmp>
    80005a02:	12050e63          	beqz	a0,80005b3e <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005a06:	f2c40613          	addi	a2,s0,-212
    80005a0a:	fb040593          	addi	a1,s0,-80
    80005a0e:	8526                	mv	a0,s1
    80005a10:	ffffe097          	auipc	ra,0xffffe
    80005a14:	6c8080e7          	jalr	1736(ra) # 800040d8 <dirlookup>
    80005a18:	892a                	mv	s2,a0
    80005a1a:	12050263          	beqz	a0,80005b3e <sys_unlink+0x1b0>
  ilock(ip);
    80005a1e:	ffffe097          	auipc	ra,0xffffe
    80005a22:	1d6080e7          	jalr	470(ra) # 80003bf4 <ilock>
  if(ip->nlink < 1)
    80005a26:	04a91783          	lh	a5,74(s2)
    80005a2a:	08f05263          	blez	a5,80005aae <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005a2e:	04491703          	lh	a4,68(s2)
    80005a32:	4785                	li	a5,1
    80005a34:	08f70563          	beq	a4,a5,80005abe <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005a38:	4641                	li	a2,16
    80005a3a:	4581                	li	a1,0
    80005a3c:	fc040513          	addi	a0,s0,-64
    80005a40:	ffffb097          	auipc	ra,0xffffb
    80005a44:	2a0080e7          	jalr	672(ra) # 80000ce0 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005a48:	4741                	li	a4,16
    80005a4a:	f2c42683          	lw	a3,-212(s0)
    80005a4e:	fc040613          	addi	a2,s0,-64
    80005a52:	4581                	li	a1,0
    80005a54:	8526                	mv	a0,s1
    80005a56:	ffffe097          	auipc	ra,0xffffe
    80005a5a:	54a080e7          	jalr	1354(ra) # 80003fa0 <writei>
    80005a5e:	47c1                	li	a5,16
    80005a60:	0af51563          	bne	a0,a5,80005b0a <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005a64:	04491703          	lh	a4,68(s2)
    80005a68:	4785                	li	a5,1
    80005a6a:	0af70863          	beq	a4,a5,80005b1a <sys_unlink+0x18c>
  iunlockput(dp);
    80005a6e:	8526                	mv	a0,s1
    80005a70:	ffffe097          	auipc	ra,0xffffe
    80005a74:	3e6080e7          	jalr	998(ra) # 80003e56 <iunlockput>
  ip->nlink--;
    80005a78:	04a95783          	lhu	a5,74(s2)
    80005a7c:	37fd                	addiw	a5,a5,-1
    80005a7e:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005a82:	854a                	mv	a0,s2
    80005a84:	ffffe097          	auipc	ra,0xffffe
    80005a88:	0a6080e7          	jalr	166(ra) # 80003b2a <iupdate>
  iunlockput(ip);
    80005a8c:	854a                	mv	a0,s2
    80005a8e:	ffffe097          	auipc	ra,0xffffe
    80005a92:	3c8080e7          	jalr	968(ra) # 80003e56 <iunlockput>
  end_op();
    80005a96:	fffff097          	auipc	ra,0xfffff
    80005a9a:	bb0080e7          	jalr	-1104(ra) # 80004646 <end_op>
  return 0;
    80005a9e:	4501                	li	a0,0
    80005aa0:	a84d                	j	80005b52 <sys_unlink+0x1c4>
    end_op();
    80005aa2:	fffff097          	auipc	ra,0xfffff
    80005aa6:	ba4080e7          	jalr	-1116(ra) # 80004646 <end_op>
    return -1;
    80005aaa:	557d                	li	a0,-1
    80005aac:	a05d                	j	80005b52 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005aae:	00003517          	auipc	a0,0x3
    80005ab2:	c9250513          	addi	a0,a0,-878 # 80008740 <syscalls+0x2f0>
    80005ab6:	ffffb097          	auipc	ra,0xffffb
    80005aba:	a88080e7          	jalr	-1400(ra) # 8000053e <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005abe:	04c92703          	lw	a4,76(s2)
    80005ac2:	02000793          	li	a5,32
    80005ac6:	f6e7f9e3          	bgeu	a5,a4,80005a38 <sys_unlink+0xaa>
    80005aca:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005ace:	4741                	li	a4,16
    80005ad0:	86ce                	mv	a3,s3
    80005ad2:	f1840613          	addi	a2,s0,-232
    80005ad6:	4581                	li	a1,0
    80005ad8:	854a                	mv	a0,s2
    80005ada:	ffffe097          	auipc	ra,0xffffe
    80005ade:	3ce080e7          	jalr	974(ra) # 80003ea8 <readi>
    80005ae2:	47c1                	li	a5,16
    80005ae4:	00f51b63          	bne	a0,a5,80005afa <sys_unlink+0x16c>
    if(de.inum != 0)
    80005ae8:	f1845783          	lhu	a5,-232(s0)
    80005aec:	e7a1                	bnez	a5,80005b34 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005aee:	29c1                	addiw	s3,s3,16
    80005af0:	04c92783          	lw	a5,76(s2)
    80005af4:	fcf9ede3          	bltu	s3,a5,80005ace <sys_unlink+0x140>
    80005af8:	b781                	j	80005a38 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005afa:	00003517          	auipc	a0,0x3
    80005afe:	c5e50513          	addi	a0,a0,-930 # 80008758 <syscalls+0x308>
    80005b02:	ffffb097          	auipc	ra,0xffffb
    80005b06:	a3c080e7          	jalr	-1476(ra) # 8000053e <panic>
    panic("unlink: writei");
    80005b0a:	00003517          	auipc	a0,0x3
    80005b0e:	c6650513          	addi	a0,a0,-922 # 80008770 <syscalls+0x320>
    80005b12:	ffffb097          	auipc	ra,0xffffb
    80005b16:	a2c080e7          	jalr	-1492(ra) # 8000053e <panic>
    dp->nlink--;
    80005b1a:	04a4d783          	lhu	a5,74(s1)
    80005b1e:	37fd                	addiw	a5,a5,-1
    80005b20:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005b24:	8526                	mv	a0,s1
    80005b26:	ffffe097          	auipc	ra,0xffffe
    80005b2a:	004080e7          	jalr	4(ra) # 80003b2a <iupdate>
    80005b2e:	b781                	j	80005a6e <sys_unlink+0xe0>
    return -1;
    80005b30:	557d                	li	a0,-1
    80005b32:	a005                	j	80005b52 <sys_unlink+0x1c4>
    iunlockput(ip);
    80005b34:	854a                	mv	a0,s2
    80005b36:	ffffe097          	auipc	ra,0xffffe
    80005b3a:	320080e7          	jalr	800(ra) # 80003e56 <iunlockput>
  iunlockput(dp);
    80005b3e:	8526                	mv	a0,s1
    80005b40:	ffffe097          	auipc	ra,0xffffe
    80005b44:	316080e7          	jalr	790(ra) # 80003e56 <iunlockput>
  end_op();
    80005b48:	fffff097          	auipc	ra,0xfffff
    80005b4c:	afe080e7          	jalr	-1282(ra) # 80004646 <end_op>
  return -1;
    80005b50:	557d                	li	a0,-1
}
    80005b52:	70ae                	ld	ra,232(sp)
    80005b54:	740e                	ld	s0,224(sp)
    80005b56:	64ee                	ld	s1,216(sp)
    80005b58:	694e                	ld	s2,208(sp)
    80005b5a:	69ae                	ld	s3,200(sp)
    80005b5c:	616d                	addi	sp,sp,240
    80005b5e:	8082                	ret

0000000080005b60 <sys_open>:

uint64
sys_open(void)
{
    80005b60:	7131                	addi	sp,sp,-192
    80005b62:	fd06                	sd	ra,184(sp)
    80005b64:	f922                	sd	s0,176(sp)
    80005b66:	f526                	sd	s1,168(sp)
    80005b68:	f14a                	sd	s2,160(sp)
    80005b6a:	ed4e                	sd	s3,152(sp)
    80005b6c:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005b6e:	08000613          	li	a2,128
    80005b72:	f5040593          	addi	a1,s0,-176
    80005b76:	4501                	li	a0,0
    80005b78:	ffffd097          	auipc	ra,0xffffd
    80005b7c:	500080e7          	jalr	1280(ra) # 80003078 <argstr>
    return -1;
    80005b80:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005b82:	0c054163          	bltz	a0,80005c44 <sys_open+0xe4>
    80005b86:	f4c40593          	addi	a1,s0,-180
    80005b8a:	4505                	li	a0,1
    80005b8c:	ffffd097          	auipc	ra,0xffffd
    80005b90:	4a8080e7          	jalr	1192(ra) # 80003034 <argint>
    80005b94:	0a054863          	bltz	a0,80005c44 <sys_open+0xe4>

  begin_op();
    80005b98:	fffff097          	auipc	ra,0xfffff
    80005b9c:	a2e080e7          	jalr	-1490(ra) # 800045c6 <begin_op>

  if(omode & O_CREATE){
    80005ba0:	f4c42783          	lw	a5,-180(s0)
    80005ba4:	2007f793          	andi	a5,a5,512
    80005ba8:	cbdd                	beqz	a5,80005c5e <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005baa:	4681                	li	a3,0
    80005bac:	4601                	li	a2,0
    80005bae:	4589                	li	a1,2
    80005bb0:	f5040513          	addi	a0,s0,-176
    80005bb4:	00000097          	auipc	ra,0x0
    80005bb8:	972080e7          	jalr	-1678(ra) # 80005526 <create>
    80005bbc:	892a                	mv	s2,a0
    if(ip == 0){
    80005bbe:	c959                	beqz	a0,80005c54 <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005bc0:	04491703          	lh	a4,68(s2)
    80005bc4:	478d                	li	a5,3
    80005bc6:	00f71763          	bne	a4,a5,80005bd4 <sys_open+0x74>
    80005bca:	04695703          	lhu	a4,70(s2)
    80005bce:	47a5                	li	a5,9
    80005bd0:	0ce7ec63          	bltu	a5,a4,80005ca8 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005bd4:	fffff097          	auipc	ra,0xfffff
    80005bd8:	e02080e7          	jalr	-510(ra) # 800049d6 <filealloc>
    80005bdc:	89aa                	mv	s3,a0
    80005bde:	10050263          	beqz	a0,80005ce2 <sys_open+0x182>
    80005be2:	00000097          	auipc	ra,0x0
    80005be6:	902080e7          	jalr	-1790(ra) # 800054e4 <fdalloc>
    80005bea:	84aa                	mv	s1,a0
    80005bec:	0e054663          	bltz	a0,80005cd8 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005bf0:	04491703          	lh	a4,68(s2)
    80005bf4:	478d                	li	a5,3
    80005bf6:	0cf70463          	beq	a4,a5,80005cbe <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005bfa:	4789                	li	a5,2
    80005bfc:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005c00:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005c04:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005c08:	f4c42783          	lw	a5,-180(s0)
    80005c0c:	0017c713          	xori	a4,a5,1
    80005c10:	8b05                	andi	a4,a4,1
    80005c12:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005c16:	0037f713          	andi	a4,a5,3
    80005c1a:	00e03733          	snez	a4,a4
    80005c1e:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005c22:	4007f793          	andi	a5,a5,1024
    80005c26:	c791                	beqz	a5,80005c32 <sys_open+0xd2>
    80005c28:	04491703          	lh	a4,68(s2)
    80005c2c:	4789                	li	a5,2
    80005c2e:	08f70f63          	beq	a4,a5,80005ccc <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005c32:	854a                	mv	a0,s2
    80005c34:	ffffe097          	auipc	ra,0xffffe
    80005c38:	082080e7          	jalr	130(ra) # 80003cb6 <iunlock>
  end_op();
    80005c3c:	fffff097          	auipc	ra,0xfffff
    80005c40:	a0a080e7          	jalr	-1526(ra) # 80004646 <end_op>

  return fd;
}
    80005c44:	8526                	mv	a0,s1
    80005c46:	70ea                	ld	ra,184(sp)
    80005c48:	744a                	ld	s0,176(sp)
    80005c4a:	74aa                	ld	s1,168(sp)
    80005c4c:	790a                	ld	s2,160(sp)
    80005c4e:	69ea                	ld	s3,152(sp)
    80005c50:	6129                	addi	sp,sp,192
    80005c52:	8082                	ret
      end_op();
    80005c54:	fffff097          	auipc	ra,0xfffff
    80005c58:	9f2080e7          	jalr	-1550(ra) # 80004646 <end_op>
      return -1;
    80005c5c:	b7e5                	j	80005c44 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005c5e:	f5040513          	addi	a0,s0,-176
    80005c62:	ffffe097          	auipc	ra,0xffffe
    80005c66:	748080e7          	jalr	1864(ra) # 800043aa <namei>
    80005c6a:	892a                	mv	s2,a0
    80005c6c:	c905                	beqz	a0,80005c9c <sys_open+0x13c>
    ilock(ip);
    80005c6e:	ffffe097          	auipc	ra,0xffffe
    80005c72:	f86080e7          	jalr	-122(ra) # 80003bf4 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005c76:	04491703          	lh	a4,68(s2)
    80005c7a:	4785                	li	a5,1
    80005c7c:	f4f712e3          	bne	a4,a5,80005bc0 <sys_open+0x60>
    80005c80:	f4c42783          	lw	a5,-180(s0)
    80005c84:	dba1                	beqz	a5,80005bd4 <sys_open+0x74>
      iunlockput(ip);
    80005c86:	854a                	mv	a0,s2
    80005c88:	ffffe097          	auipc	ra,0xffffe
    80005c8c:	1ce080e7          	jalr	462(ra) # 80003e56 <iunlockput>
      end_op();
    80005c90:	fffff097          	auipc	ra,0xfffff
    80005c94:	9b6080e7          	jalr	-1610(ra) # 80004646 <end_op>
      return -1;
    80005c98:	54fd                	li	s1,-1
    80005c9a:	b76d                	j	80005c44 <sys_open+0xe4>
      end_op();
    80005c9c:	fffff097          	auipc	ra,0xfffff
    80005ca0:	9aa080e7          	jalr	-1622(ra) # 80004646 <end_op>
      return -1;
    80005ca4:	54fd                	li	s1,-1
    80005ca6:	bf79                	j	80005c44 <sys_open+0xe4>
    iunlockput(ip);
    80005ca8:	854a                	mv	a0,s2
    80005caa:	ffffe097          	auipc	ra,0xffffe
    80005cae:	1ac080e7          	jalr	428(ra) # 80003e56 <iunlockput>
    end_op();
    80005cb2:	fffff097          	auipc	ra,0xfffff
    80005cb6:	994080e7          	jalr	-1644(ra) # 80004646 <end_op>
    return -1;
    80005cba:	54fd                	li	s1,-1
    80005cbc:	b761                	j	80005c44 <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005cbe:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005cc2:	04691783          	lh	a5,70(s2)
    80005cc6:	02f99223          	sh	a5,36(s3)
    80005cca:	bf2d                	j	80005c04 <sys_open+0xa4>
    itrunc(ip);
    80005ccc:	854a                	mv	a0,s2
    80005cce:	ffffe097          	auipc	ra,0xffffe
    80005cd2:	034080e7          	jalr	52(ra) # 80003d02 <itrunc>
    80005cd6:	bfb1                	j	80005c32 <sys_open+0xd2>
      fileclose(f);
    80005cd8:	854e                	mv	a0,s3
    80005cda:	fffff097          	auipc	ra,0xfffff
    80005cde:	db8080e7          	jalr	-584(ra) # 80004a92 <fileclose>
    iunlockput(ip);
    80005ce2:	854a                	mv	a0,s2
    80005ce4:	ffffe097          	auipc	ra,0xffffe
    80005ce8:	172080e7          	jalr	370(ra) # 80003e56 <iunlockput>
    end_op();
    80005cec:	fffff097          	auipc	ra,0xfffff
    80005cf0:	95a080e7          	jalr	-1702(ra) # 80004646 <end_op>
    return -1;
    80005cf4:	54fd                	li	s1,-1
    80005cf6:	b7b9                	j	80005c44 <sys_open+0xe4>

0000000080005cf8 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005cf8:	7175                	addi	sp,sp,-144
    80005cfa:	e506                	sd	ra,136(sp)
    80005cfc:	e122                	sd	s0,128(sp)
    80005cfe:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005d00:	fffff097          	auipc	ra,0xfffff
    80005d04:	8c6080e7          	jalr	-1850(ra) # 800045c6 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005d08:	08000613          	li	a2,128
    80005d0c:	f7040593          	addi	a1,s0,-144
    80005d10:	4501                	li	a0,0
    80005d12:	ffffd097          	auipc	ra,0xffffd
    80005d16:	366080e7          	jalr	870(ra) # 80003078 <argstr>
    80005d1a:	02054963          	bltz	a0,80005d4c <sys_mkdir+0x54>
    80005d1e:	4681                	li	a3,0
    80005d20:	4601                	li	a2,0
    80005d22:	4585                	li	a1,1
    80005d24:	f7040513          	addi	a0,s0,-144
    80005d28:	fffff097          	auipc	ra,0xfffff
    80005d2c:	7fe080e7          	jalr	2046(ra) # 80005526 <create>
    80005d30:	cd11                	beqz	a0,80005d4c <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005d32:	ffffe097          	auipc	ra,0xffffe
    80005d36:	124080e7          	jalr	292(ra) # 80003e56 <iunlockput>
  end_op();
    80005d3a:	fffff097          	auipc	ra,0xfffff
    80005d3e:	90c080e7          	jalr	-1780(ra) # 80004646 <end_op>
  return 0;
    80005d42:	4501                	li	a0,0
}
    80005d44:	60aa                	ld	ra,136(sp)
    80005d46:	640a                	ld	s0,128(sp)
    80005d48:	6149                	addi	sp,sp,144
    80005d4a:	8082                	ret
    end_op();
    80005d4c:	fffff097          	auipc	ra,0xfffff
    80005d50:	8fa080e7          	jalr	-1798(ra) # 80004646 <end_op>
    return -1;
    80005d54:	557d                	li	a0,-1
    80005d56:	b7fd                	j	80005d44 <sys_mkdir+0x4c>

0000000080005d58 <sys_mknod>:

uint64
sys_mknod(void)
{
    80005d58:	7135                	addi	sp,sp,-160
    80005d5a:	ed06                	sd	ra,152(sp)
    80005d5c:	e922                	sd	s0,144(sp)
    80005d5e:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005d60:	fffff097          	auipc	ra,0xfffff
    80005d64:	866080e7          	jalr	-1946(ra) # 800045c6 <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005d68:	08000613          	li	a2,128
    80005d6c:	f7040593          	addi	a1,s0,-144
    80005d70:	4501                	li	a0,0
    80005d72:	ffffd097          	auipc	ra,0xffffd
    80005d76:	306080e7          	jalr	774(ra) # 80003078 <argstr>
    80005d7a:	04054a63          	bltz	a0,80005dce <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    80005d7e:	f6c40593          	addi	a1,s0,-148
    80005d82:	4505                	li	a0,1
    80005d84:	ffffd097          	auipc	ra,0xffffd
    80005d88:	2b0080e7          	jalr	688(ra) # 80003034 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005d8c:	04054163          	bltz	a0,80005dce <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    80005d90:	f6840593          	addi	a1,s0,-152
    80005d94:	4509                	li	a0,2
    80005d96:	ffffd097          	auipc	ra,0xffffd
    80005d9a:	29e080e7          	jalr	670(ra) # 80003034 <argint>
     argint(1, &major) < 0 ||
    80005d9e:	02054863          	bltz	a0,80005dce <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005da2:	f6841683          	lh	a3,-152(s0)
    80005da6:	f6c41603          	lh	a2,-148(s0)
    80005daa:	458d                	li	a1,3
    80005dac:	f7040513          	addi	a0,s0,-144
    80005db0:	fffff097          	auipc	ra,0xfffff
    80005db4:	776080e7          	jalr	1910(ra) # 80005526 <create>
     argint(2, &minor) < 0 ||
    80005db8:	c919                	beqz	a0,80005dce <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005dba:	ffffe097          	auipc	ra,0xffffe
    80005dbe:	09c080e7          	jalr	156(ra) # 80003e56 <iunlockput>
  end_op();
    80005dc2:	fffff097          	auipc	ra,0xfffff
    80005dc6:	884080e7          	jalr	-1916(ra) # 80004646 <end_op>
  return 0;
    80005dca:	4501                	li	a0,0
    80005dcc:	a031                	j	80005dd8 <sys_mknod+0x80>
    end_op();
    80005dce:	fffff097          	auipc	ra,0xfffff
    80005dd2:	878080e7          	jalr	-1928(ra) # 80004646 <end_op>
    return -1;
    80005dd6:	557d                	li	a0,-1
}
    80005dd8:	60ea                	ld	ra,152(sp)
    80005dda:	644a                	ld	s0,144(sp)
    80005ddc:	610d                	addi	sp,sp,160
    80005dde:	8082                	ret

0000000080005de0 <sys_chdir>:

uint64
sys_chdir(void)
{
    80005de0:	7135                	addi	sp,sp,-160
    80005de2:	ed06                	sd	ra,152(sp)
    80005de4:	e922                	sd	s0,144(sp)
    80005de6:	e526                	sd	s1,136(sp)
    80005de8:	e14a                	sd	s2,128(sp)
    80005dea:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005dec:	ffffc097          	auipc	ra,0xffffc
    80005df0:	bdc080e7          	jalr	-1060(ra) # 800019c8 <myproc>
    80005df4:	892a                	mv	s2,a0
  
  begin_op();
    80005df6:	ffffe097          	auipc	ra,0xffffe
    80005dfa:	7d0080e7          	jalr	2000(ra) # 800045c6 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005dfe:	08000613          	li	a2,128
    80005e02:	f6040593          	addi	a1,s0,-160
    80005e06:	4501                	li	a0,0
    80005e08:	ffffd097          	auipc	ra,0xffffd
    80005e0c:	270080e7          	jalr	624(ra) # 80003078 <argstr>
    80005e10:	04054b63          	bltz	a0,80005e66 <sys_chdir+0x86>
    80005e14:	f6040513          	addi	a0,s0,-160
    80005e18:	ffffe097          	auipc	ra,0xffffe
    80005e1c:	592080e7          	jalr	1426(ra) # 800043aa <namei>
    80005e20:	84aa                	mv	s1,a0
    80005e22:	c131                	beqz	a0,80005e66 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005e24:	ffffe097          	auipc	ra,0xffffe
    80005e28:	dd0080e7          	jalr	-560(ra) # 80003bf4 <ilock>
  if(ip->type != T_DIR){
    80005e2c:	04449703          	lh	a4,68(s1)
    80005e30:	4785                	li	a5,1
    80005e32:	04f71063          	bne	a4,a5,80005e72 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005e36:	8526                	mv	a0,s1
    80005e38:	ffffe097          	auipc	ra,0xffffe
    80005e3c:	e7e080e7          	jalr	-386(ra) # 80003cb6 <iunlock>
  iput(p->cwd);
    80005e40:	17093503          	ld	a0,368(s2)
    80005e44:	ffffe097          	auipc	ra,0xffffe
    80005e48:	f6a080e7          	jalr	-150(ra) # 80003dae <iput>
  end_op();
    80005e4c:	ffffe097          	auipc	ra,0xffffe
    80005e50:	7fa080e7          	jalr	2042(ra) # 80004646 <end_op>
  p->cwd = ip;
    80005e54:	16993823          	sd	s1,368(s2)
  return 0;
    80005e58:	4501                	li	a0,0
}
    80005e5a:	60ea                	ld	ra,152(sp)
    80005e5c:	644a                	ld	s0,144(sp)
    80005e5e:	64aa                	ld	s1,136(sp)
    80005e60:	690a                	ld	s2,128(sp)
    80005e62:	610d                	addi	sp,sp,160
    80005e64:	8082                	ret
    end_op();
    80005e66:	ffffe097          	auipc	ra,0xffffe
    80005e6a:	7e0080e7          	jalr	2016(ra) # 80004646 <end_op>
    return -1;
    80005e6e:	557d                	li	a0,-1
    80005e70:	b7ed                	j	80005e5a <sys_chdir+0x7a>
    iunlockput(ip);
    80005e72:	8526                	mv	a0,s1
    80005e74:	ffffe097          	auipc	ra,0xffffe
    80005e78:	fe2080e7          	jalr	-30(ra) # 80003e56 <iunlockput>
    end_op();
    80005e7c:	ffffe097          	auipc	ra,0xffffe
    80005e80:	7ca080e7          	jalr	1994(ra) # 80004646 <end_op>
    return -1;
    80005e84:	557d                	li	a0,-1
    80005e86:	bfd1                	j	80005e5a <sys_chdir+0x7a>

0000000080005e88 <sys_exec>:

uint64
sys_exec(void)
{
    80005e88:	7145                	addi	sp,sp,-464
    80005e8a:	e786                	sd	ra,456(sp)
    80005e8c:	e3a2                	sd	s0,448(sp)
    80005e8e:	ff26                	sd	s1,440(sp)
    80005e90:	fb4a                	sd	s2,432(sp)
    80005e92:	f74e                	sd	s3,424(sp)
    80005e94:	f352                	sd	s4,416(sp)
    80005e96:	ef56                	sd	s5,408(sp)
    80005e98:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005e9a:	08000613          	li	a2,128
    80005e9e:	f4040593          	addi	a1,s0,-192
    80005ea2:	4501                	li	a0,0
    80005ea4:	ffffd097          	auipc	ra,0xffffd
    80005ea8:	1d4080e7          	jalr	468(ra) # 80003078 <argstr>
    return -1;
    80005eac:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005eae:	0c054a63          	bltz	a0,80005f82 <sys_exec+0xfa>
    80005eb2:	e3840593          	addi	a1,s0,-456
    80005eb6:	4505                	li	a0,1
    80005eb8:	ffffd097          	auipc	ra,0xffffd
    80005ebc:	19e080e7          	jalr	414(ra) # 80003056 <argaddr>
    80005ec0:	0c054163          	bltz	a0,80005f82 <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80005ec4:	10000613          	li	a2,256
    80005ec8:	4581                	li	a1,0
    80005eca:	e4040513          	addi	a0,s0,-448
    80005ece:	ffffb097          	auipc	ra,0xffffb
    80005ed2:	e12080e7          	jalr	-494(ra) # 80000ce0 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005ed6:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005eda:	89a6                	mv	s3,s1
    80005edc:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005ede:	02000a13          	li	s4,32
    80005ee2:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005ee6:	00391513          	slli	a0,s2,0x3
    80005eea:	e3040593          	addi	a1,s0,-464
    80005eee:	e3843783          	ld	a5,-456(s0)
    80005ef2:	953e                	add	a0,a0,a5
    80005ef4:	ffffd097          	auipc	ra,0xffffd
    80005ef8:	0a6080e7          	jalr	166(ra) # 80002f9a <fetchaddr>
    80005efc:	02054a63          	bltz	a0,80005f30 <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    80005f00:	e3043783          	ld	a5,-464(s0)
    80005f04:	c3b9                	beqz	a5,80005f4a <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005f06:	ffffb097          	auipc	ra,0xffffb
    80005f0a:	bee080e7          	jalr	-1042(ra) # 80000af4 <kalloc>
    80005f0e:	85aa                	mv	a1,a0
    80005f10:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005f14:	cd11                	beqz	a0,80005f30 <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005f16:	6605                	lui	a2,0x1
    80005f18:	e3043503          	ld	a0,-464(s0)
    80005f1c:	ffffd097          	auipc	ra,0xffffd
    80005f20:	0d0080e7          	jalr	208(ra) # 80002fec <fetchstr>
    80005f24:	00054663          	bltz	a0,80005f30 <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80005f28:	0905                	addi	s2,s2,1
    80005f2a:	09a1                	addi	s3,s3,8
    80005f2c:	fb491be3          	bne	s2,s4,80005ee2 <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005f30:	10048913          	addi	s2,s1,256
    80005f34:	6088                	ld	a0,0(s1)
    80005f36:	c529                	beqz	a0,80005f80 <sys_exec+0xf8>
    kfree(argv[i]);
    80005f38:	ffffb097          	auipc	ra,0xffffb
    80005f3c:	ac0080e7          	jalr	-1344(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005f40:	04a1                	addi	s1,s1,8
    80005f42:	ff2499e3          	bne	s1,s2,80005f34 <sys_exec+0xac>
  return -1;
    80005f46:	597d                	li	s2,-1
    80005f48:	a82d                	j	80005f82 <sys_exec+0xfa>
      argv[i] = 0;
    80005f4a:	0a8e                	slli	s5,s5,0x3
    80005f4c:	fc040793          	addi	a5,s0,-64
    80005f50:	9abe                	add	s5,s5,a5
    80005f52:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005f56:	e4040593          	addi	a1,s0,-448
    80005f5a:	f4040513          	addi	a0,s0,-192
    80005f5e:	fffff097          	auipc	ra,0xfffff
    80005f62:	194080e7          	jalr	404(ra) # 800050f2 <exec>
    80005f66:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005f68:	10048993          	addi	s3,s1,256
    80005f6c:	6088                	ld	a0,0(s1)
    80005f6e:	c911                	beqz	a0,80005f82 <sys_exec+0xfa>
    kfree(argv[i]);
    80005f70:	ffffb097          	auipc	ra,0xffffb
    80005f74:	a88080e7          	jalr	-1400(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005f78:	04a1                	addi	s1,s1,8
    80005f7a:	ff3499e3          	bne	s1,s3,80005f6c <sys_exec+0xe4>
    80005f7e:	a011                	j	80005f82 <sys_exec+0xfa>
  return -1;
    80005f80:	597d                	li	s2,-1
}
    80005f82:	854a                	mv	a0,s2
    80005f84:	60be                	ld	ra,456(sp)
    80005f86:	641e                	ld	s0,448(sp)
    80005f88:	74fa                	ld	s1,440(sp)
    80005f8a:	795a                	ld	s2,432(sp)
    80005f8c:	79ba                	ld	s3,424(sp)
    80005f8e:	7a1a                	ld	s4,416(sp)
    80005f90:	6afa                	ld	s5,408(sp)
    80005f92:	6179                	addi	sp,sp,464
    80005f94:	8082                	ret

0000000080005f96 <sys_pipe>:

uint64
sys_pipe(void)
{
    80005f96:	7139                	addi	sp,sp,-64
    80005f98:	fc06                	sd	ra,56(sp)
    80005f9a:	f822                	sd	s0,48(sp)
    80005f9c:	f426                	sd	s1,40(sp)
    80005f9e:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005fa0:	ffffc097          	auipc	ra,0xffffc
    80005fa4:	a28080e7          	jalr	-1496(ra) # 800019c8 <myproc>
    80005fa8:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80005faa:	fd840593          	addi	a1,s0,-40
    80005fae:	4501                	li	a0,0
    80005fb0:	ffffd097          	auipc	ra,0xffffd
    80005fb4:	0a6080e7          	jalr	166(ra) # 80003056 <argaddr>
    return -1;
    80005fb8:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80005fba:	0e054063          	bltz	a0,8000609a <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    80005fbe:	fc840593          	addi	a1,s0,-56
    80005fc2:	fd040513          	addi	a0,s0,-48
    80005fc6:	fffff097          	auipc	ra,0xfffff
    80005fca:	dfc080e7          	jalr	-516(ra) # 80004dc2 <pipealloc>
    return -1;
    80005fce:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005fd0:	0c054563          	bltz	a0,8000609a <sys_pipe+0x104>
  fd0 = -1;
    80005fd4:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005fd8:	fd043503          	ld	a0,-48(s0)
    80005fdc:	fffff097          	auipc	ra,0xfffff
    80005fe0:	508080e7          	jalr	1288(ra) # 800054e4 <fdalloc>
    80005fe4:	fca42223          	sw	a0,-60(s0)
    80005fe8:	08054c63          	bltz	a0,80006080 <sys_pipe+0xea>
    80005fec:	fc843503          	ld	a0,-56(s0)
    80005ff0:	fffff097          	auipc	ra,0xfffff
    80005ff4:	4f4080e7          	jalr	1268(ra) # 800054e4 <fdalloc>
    80005ff8:	fca42023          	sw	a0,-64(s0)
    80005ffc:	06054863          	bltz	a0,8000606c <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80006000:	4691                	li	a3,4
    80006002:	fc440613          	addi	a2,s0,-60
    80006006:	fd843583          	ld	a1,-40(s0)
    8000600a:	78a8                	ld	a0,112(s1)
    8000600c:	ffffb097          	auipc	ra,0xffffb
    80006010:	66e080e7          	jalr	1646(ra) # 8000167a <copyout>
    80006014:	02054063          	bltz	a0,80006034 <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80006018:	4691                	li	a3,4
    8000601a:	fc040613          	addi	a2,s0,-64
    8000601e:	fd843583          	ld	a1,-40(s0)
    80006022:	0591                	addi	a1,a1,4
    80006024:	78a8                	ld	a0,112(s1)
    80006026:	ffffb097          	auipc	ra,0xffffb
    8000602a:	654080e7          	jalr	1620(ra) # 8000167a <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    8000602e:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80006030:	06055563          	bgez	a0,8000609a <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80006034:	fc442783          	lw	a5,-60(s0)
    80006038:	07f9                	addi	a5,a5,30
    8000603a:	078e                	slli	a5,a5,0x3
    8000603c:	97a6                	add	a5,a5,s1
    8000603e:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80006042:	fc042503          	lw	a0,-64(s0)
    80006046:	0579                	addi	a0,a0,30
    80006048:	050e                	slli	a0,a0,0x3
    8000604a:	9526                	add	a0,a0,s1
    8000604c:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80006050:	fd043503          	ld	a0,-48(s0)
    80006054:	fffff097          	auipc	ra,0xfffff
    80006058:	a3e080e7          	jalr	-1474(ra) # 80004a92 <fileclose>
    fileclose(wf);
    8000605c:	fc843503          	ld	a0,-56(s0)
    80006060:	fffff097          	auipc	ra,0xfffff
    80006064:	a32080e7          	jalr	-1486(ra) # 80004a92 <fileclose>
    return -1;
    80006068:	57fd                	li	a5,-1
    8000606a:	a805                	j	8000609a <sys_pipe+0x104>
    if(fd0 >= 0)
    8000606c:	fc442783          	lw	a5,-60(s0)
    80006070:	0007c863          	bltz	a5,80006080 <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80006074:	01e78513          	addi	a0,a5,30
    80006078:	050e                	slli	a0,a0,0x3
    8000607a:	9526                	add	a0,a0,s1
    8000607c:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80006080:	fd043503          	ld	a0,-48(s0)
    80006084:	fffff097          	auipc	ra,0xfffff
    80006088:	a0e080e7          	jalr	-1522(ra) # 80004a92 <fileclose>
    fileclose(wf);
    8000608c:	fc843503          	ld	a0,-56(s0)
    80006090:	fffff097          	auipc	ra,0xfffff
    80006094:	a02080e7          	jalr	-1534(ra) # 80004a92 <fileclose>
    return -1;
    80006098:	57fd                	li	a5,-1
}
    8000609a:	853e                	mv	a0,a5
    8000609c:	70e2                	ld	ra,56(sp)
    8000609e:	7442                	ld	s0,48(sp)
    800060a0:	74a2                	ld	s1,40(sp)
    800060a2:	6121                	addi	sp,sp,64
    800060a4:	8082                	ret
	...

00000000800060b0 <kernelvec>:
    800060b0:	7111                	addi	sp,sp,-256
    800060b2:	e006                	sd	ra,0(sp)
    800060b4:	e40a                	sd	sp,8(sp)
    800060b6:	e80e                	sd	gp,16(sp)
    800060b8:	ec12                	sd	tp,24(sp)
    800060ba:	f016                	sd	t0,32(sp)
    800060bc:	f41a                	sd	t1,40(sp)
    800060be:	f81e                	sd	t2,48(sp)
    800060c0:	fc22                	sd	s0,56(sp)
    800060c2:	e0a6                	sd	s1,64(sp)
    800060c4:	e4aa                	sd	a0,72(sp)
    800060c6:	e8ae                	sd	a1,80(sp)
    800060c8:	ecb2                	sd	a2,88(sp)
    800060ca:	f0b6                	sd	a3,96(sp)
    800060cc:	f4ba                	sd	a4,104(sp)
    800060ce:	f8be                	sd	a5,112(sp)
    800060d0:	fcc2                	sd	a6,120(sp)
    800060d2:	e146                	sd	a7,128(sp)
    800060d4:	e54a                	sd	s2,136(sp)
    800060d6:	e94e                	sd	s3,144(sp)
    800060d8:	ed52                	sd	s4,152(sp)
    800060da:	f156                	sd	s5,160(sp)
    800060dc:	f55a                	sd	s6,168(sp)
    800060de:	f95e                	sd	s7,176(sp)
    800060e0:	fd62                	sd	s8,184(sp)
    800060e2:	e1e6                	sd	s9,192(sp)
    800060e4:	e5ea                	sd	s10,200(sp)
    800060e6:	e9ee                	sd	s11,208(sp)
    800060e8:	edf2                	sd	t3,216(sp)
    800060ea:	f1f6                	sd	t4,224(sp)
    800060ec:	f5fa                	sd	t5,232(sp)
    800060ee:	f9fe                	sd	t6,240(sp)
    800060f0:	d77fc0ef          	jal	ra,80002e66 <kerneltrap>
    800060f4:	6082                	ld	ra,0(sp)
    800060f6:	6122                	ld	sp,8(sp)
    800060f8:	61c2                	ld	gp,16(sp)
    800060fa:	7282                	ld	t0,32(sp)
    800060fc:	7322                	ld	t1,40(sp)
    800060fe:	73c2                	ld	t2,48(sp)
    80006100:	7462                	ld	s0,56(sp)
    80006102:	6486                	ld	s1,64(sp)
    80006104:	6526                	ld	a0,72(sp)
    80006106:	65c6                	ld	a1,80(sp)
    80006108:	6666                	ld	a2,88(sp)
    8000610a:	7686                	ld	a3,96(sp)
    8000610c:	7726                	ld	a4,104(sp)
    8000610e:	77c6                	ld	a5,112(sp)
    80006110:	7866                	ld	a6,120(sp)
    80006112:	688a                	ld	a7,128(sp)
    80006114:	692a                	ld	s2,136(sp)
    80006116:	69ca                	ld	s3,144(sp)
    80006118:	6a6a                	ld	s4,152(sp)
    8000611a:	7a8a                	ld	s5,160(sp)
    8000611c:	7b2a                	ld	s6,168(sp)
    8000611e:	7bca                	ld	s7,176(sp)
    80006120:	7c6a                	ld	s8,184(sp)
    80006122:	6c8e                	ld	s9,192(sp)
    80006124:	6d2e                	ld	s10,200(sp)
    80006126:	6dce                	ld	s11,208(sp)
    80006128:	6e6e                	ld	t3,216(sp)
    8000612a:	7e8e                	ld	t4,224(sp)
    8000612c:	7f2e                	ld	t5,232(sp)
    8000612e:	7fce                	ld	t6,240(sp)
    80006130:	6111                	addi	sp,sp,256
    80006132:	10200073          	sret
    80006136:	00000013          	nop
    8000613a:	00000013          	nop
    8000613e:	0001                	nop

0000000080006140 <timervec>:
    80006140:	34051573          	csrrw	a0,mscratch,a0
    80006144:	e10c                	sd	a1,0(a0)
    80006146:	e510                	sd	a2,8(a0)
    80006148:	e914                	sd	a3,16(a0)
    8000614a:	6d0c                	ld	a1,24(a0)
    8000614c:	7110                	ld	a2,32(a0)
    8000614e:	6194                	ld	a3,0(a1)
    80006150:	96b2                	add	a3,a3,a2
    80006152:	e194                	sd	a3,0(a1)
    80006154:	4589                	li	a1,2
    80006156:	14459073          	csrw	sip,a1
    8000615a:	6914                	ld	a3,16(a0)
    8000615c:	6510                	ld	a2,8(a0)
    8000615e:	610c                	ld	a1,0(a0)
    80006160:	34051573          	csrrw	a0,mscratch,a0
    80006164:	30200073          	mret
	...

000000008000616a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    8000616a:	1141                	addi	sp,sp,-16
    8000616c:	e422                	sd	s0,8(sp)
    8000616e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80006170:	0c0007b7          	lui	a5,0xc000
    80006174:	4705                	li	a4,1
    80006176:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80006178:	c3d8                	sw	a4,4(a5)
}
    8000617a:	6422                	ld	s0,8(sp)
    8000617c:	0141                	addi	sp,sp,16
    8000617e:	8082                	ret

0000000080006180 <plicinithart>:

void
plicinithart(void)
{
    80006180:	1141                	addi	sp,sp,-16
    80006182:	e406                	sd	ra,8(sp)
    80006184:	e022                	sd	s0,0(sp)
    80006186:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006188:	ffffc097          	auipc	ra,0xffffc
    8000618c:	814080e7          	jalr	-2028(ra) # 8000199c <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80006190:	0085171b          	slliw	a4,a0,0x8
    80006194:	0c0027b7          	lui	a5,0xc002
    80006198:	97ba                	add	a5,a5,a4
    8000619a:	40200713          	li	a4,1026
    8000619e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    800061a2:	00d5151b          	slliw	a0,a0,0xd
    800061a6:	0c2017b7          	lui	a5,0xc201
    800061aa:	953e                	add	a0,a0,a5
    800061ac:	00052023          	sw	zero,0(a0)
}
    800061b0:	60a2                	ld	ra,8(sp)
    800061b2:	6402                	ld	s0,0(sp)
    800061b4:	0141                	addi	sp,sp,16
    800061b6:	8082                	ret

00000000800061b8 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    800061b8:	1141                	addi	sp,sp,-16
    800061ba:	e406                	sd	ra,8(sp)
    800061bc:	e022                	sd	s0,0(sp)
    800061be:	0800                	addi	s0,sp,16
  int hart = cpuid();
    800061c0:	ffffb097          	auipc	ra,0xffffb
    800061c4:	7dc080e7          	jalr	2012(ra) # 8000199c <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    800061c8:	00d5179b          	slliw	a5,a0,0xd
    800061cc:	0c201537          	lui	a0,0xc201
    800061d0:	953e                	add	a0,a0,a5
  return irq;
}
    800061d2:	4148                	lw	a0,4(a0)
    800061d4:	60a2                	ld	ra,8(sp)
    800061d6:	6402                	ld	s0,0(sp)
    800061d8:	0141                	addi	sp,sp,16
    800061da:	8082                	ret

00000000800061dc <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    800061dc:	1101                	addi	sp,sp,-32
    800061de:	ec06                	sd	ra,24(sp)
    800061e0:	e822                	sd	s0,16(sp)
    800061e2:	e426                	sd	s1,8(sp)
    800061e4:	1000                	addi	s0,sp,32
    800061e6:	84aa                	mv	s1,a0
  int hart = cpuid();
    800061e8:	ffffb097          	auipc	ra,0xffffb
    800061ec:	7b4080e7          	jalr	1972(ra) # 8000199c <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    800061f0:	00d5151b          	slliw	a0,a0,0xd
    800061f4:	0c2017b7          	lui	a5,0xc201
    800061f8:	97aa                	add	a5,a5,a0
    800061fa:	c3c4                	sw	s1,4(a5)
}
    800061fc:	60e2                	ld	ra,24(sp)
    800061fe:	6442                	ld	s0,16(sp)
    80006200:	64a2                	ld	s1,8(sp)
    80006202:	6105                	addi	sp,sp,32
    80006204:	8082                	ret

0000000080006206 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80006206:	1141                	addi	sp,sp,-16
    80006208:	e406                	sd	ra,8(sp)
    8000620a:	e022                	sd	s0,0(sp)
    8000620c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    8000620e:	479d                	li	a5,7
    80006210:	06a7c963          	blt	a5,a0,80006282 <free_desc+0x7c>
    panic("free_desc 1");
  if(disk.free[i])
    80006214:	0001d797          	auipc	a5,0x1d
    80006218:	dec78793          	addi	a5,a5,-532 # 80023000 <disk>
    8000621c:	00a78733          	add	a4,a5,a0
    80006220:	6789                	lui	a5,0x2
    80006222:	97ba                	add	a5,a5,a4
    80006224:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80006228:	e7ad                	bnez	a5,80006292 <free_desc+0x8c>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    8000622a:	00451793          	slli	a5,a0,0x4
    8000622e:	0001f717          	auipc	a4,0x1f
    80006232:	dd270713          	addi	a4,a4,-558 # 80025000 <disk+0x2000>
    80006236:	6314                	ld	a3,0(a4)
    80006238:	96be                	add	a3,a3,a5
    8000623a:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    8000623e:	6314                	ld	a3,0(a4)
    80006240:	96be                	add	a3,a3,a5
    80006242:	0006a423          	sw	zero,8(a3)
  disk.desc[i].flags = 0;
    80006246:	6314                	ld	a3,0(a4)
    80006248:	96be                	add	a3,a3,a5
    8000624a:	00069623          	sh	zero,12(a3)
  disk.desc[i].next = 0;
    8000624e:	6318                	ld	a4,0(a4)
    80006250:	97ba                	add	a5,a5,a4
    80006252:	00079723          	sh	zero,14(a5)
  disk.free[i] = 1;
    80006256:	0001d797          	auipc	a5,0x1d
    8000625a:	daa78793          	addi	a5,a5,-598 # 80023000 <disk>
    8000625e:	97aa                	add	a5,a5,a0
    80006260:	6509                	lui	a0,0x2
    80006262:	953e                	add	a0,a0,a5
    80006264:	4785                	li	a5,1
    80006266:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    8000626a:	0001f517          	auipc	a0,0x1f
    8000626e:	dae50513          	addi	a0,a0,-594 # 80025018 <disk+0x2018>
    80006272:	ffffc097          	auipc	ra,0xffffc
    80006276:	390080e7          	jalr	912(ra) # 80002602 <wakeup>
}
    8000627a:	60a2                	ld	ra,8(sp)
    8000627c:	6402                	ld	s0,0(sp)
    8000627e:	0141                	addi	sp,sp,16
    80006280:	8082                	ret
    panic("free_desc 1");
    80006282:	00002517          	auipc	a0,0x2
    80006286:	4fe50513          	addi	a0,a0,1278 # 80008780 <syscalls+0x330>
    8000628a:	ffffa097          	auipc	ra,0xffffa
    8000628e:	2b4080e7          	jalr	692(ra) # 8000053e <panic>
    panic("free_desc 2");
    80006292:	00002517          	auipc	a0,0x2
    80006296:	4fe50513          	addi	a0,a0,1278 # 80008790 <syscalls+0x340>
    8000629a:	ffffa097          	auipc	ra,0xffffa
    8000629e:	2a4080e7          	jalr	676(ra) # 8000053e <panic>

00000000800062a2 <virtio_disk_init>:
{
    800062a2:	1101                	addi	sp,sp,-32
    800062a4:	ec06                	sd	ra,24(sp)
    800062a6:	e822                	sd	s0,16(sp)
    800062a8:	e426                	sd	s1,8(sp)
    800062aa:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    800062ac:	00002597          	auipc	a1,0x2
    800062b0:	4f458593          	addi	a1,a1,1268 # 800087a0 <syscalls+0x350>
    800062b4:	0001f517          	auipc	a0,0x1f
    800062b8:	e7450513          	addi	a0,a0,-396 # 80025128 <disk+0x2128>
    800062bc:	ffffb097          	auipc	ra,0xffffb
    800062c0:	898080e7          	jalr	-1896(ra) # 80000b54 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    800062c4:	100017b7          	lui	a5,0x10001
    800062c8:	4398                	lw	a4,0(a5)
    800062ca:	2701                	sext.w	a4,a4
    800062cc:	747277b7          	lui	a5,0x74727
    800062d0:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    800062d4:	0ef71163          	bne	a4,a5,800063b6 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    800062d8:	100017b7          	lui	a5,0x10001
    800062dc:	43dc                	lw	a5,4(a5)
    800062de:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    800062e0:	4705                	li	a4,1
    800062e2:	0ce79a63          	bne	a5,a4,800063b6 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    800062e6:	100017b7          	lui	a5,0x10001
    800062ea:	479c                	lw	a5,8(a5)
    800062ec:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    800062ee:	4709                	li	a4,2
    800062f0:	0ce79363          	bne	a5,a4,800063b6 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    800062f4:	100017b7          	lui	a5,0x10001
    800062f8:	47d8                	lw	a4,12(a5)
    800062fa:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    800062fc:	554d47b7          	lui	a5,0x554d4
    80006300:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80006304:	0af71963          	bne	a4,a5,800063b6 <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    80006308:	100017b7          	lui	a5,0x10001
    8000630c:	4705                	li	a4,1
    8000630e:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006310:	470d                	li	a4,3
    80006312:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80006314:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80006316:	c7ffe737          	lui	a4,0xc7ffe
    8000631a:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd875f>
    8000631e:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80006320:	2701                	sext.w	a4,a4
    80006322:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006324:	472d                	li	a4,11
    80006326:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006328:	473d                	li	a4,15
    8000632a:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    8000632c:	6705                	lui	a4,0x1
    8000632e:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80006330:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80006334:	5bdc                	lw	a5,52(a5)
    80006336:	2781                	sext.w	a5,a5
  if(max == 0)
    80006338:	c7d9                	beqz	a5,800063c6 <virtio_disk_init+0x124>
  if(max < NUM)
    8000633a:	471d                	li	a4,7
    8000633c:	08f77d63          	bgeu	a4,a5,800063d6 <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80006340:	100014b7          	lui	s1,0x10001
    80006344:	47a1                	li	a5,8
    80006346:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    80006348:	6609                	lui	a2,0x2
    8000634a:	4581                	li	a1,0
    8000634c:	0001d517          	auipc	a0,0x1d
    80006350:	cb450513          	addi	a0,a0,-844 # 80023000 <disk>
    80006354:	ffffb097          	auipc	ra,0xffffb
    80006358:	98c080e7          	jalr	-1652(ra) # 80000ce0 <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    8000635c:	0001d717          	auipc	a4,0x1d
    80006360:	ca470713          	addi	a4,a4,-860 # 80023000 <disk>
    80006364:	00c75793          	srli	a5,a4,0xc
    80006368:	2781                	sext.w	a5,a5
    8000636a:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    8000636c:	0001f797          	auipc	a5,0x1f
    80006370:	c9478793          	addi	a5,a5,-876 # 80025000 <disk+0x2000>
    80006374:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    80006376:	0001d717          	auipc	a4,0x1d
    8000637a:	d0a70713          	addi	a4,a4,-758 # 80023080 <disk+0x80>
    8000637e:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    80006380:	0001e717          	auipc	a4,0x1e
    80006384:	c8070713          	addi	a4,a4,-896 # 80024000 <disk+0x1000>
    80006388:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    8000638a:	4705                	li	a4,1
    8000638c:	00e78c23          	sb	a4,24(a5)
    80006390:	00e78ca3          	sb	a4,25(a5)
    80006394:	00e78d23          	sb	a4,26(a5)
    80006398:	00e78da3          	sb	a4,27(a5)
    8000639c:	00e78e23          	sb	a4,28(a5)
    800063a0:	00e78ea3          	sb	a4,29(a5)
    800063a4:	00e78f23          	sb	a4,30(a5)
    800063a8:	00e78fa3          	sb	a4,31(a5)
}
    800063ac:	60e2                	ld	ra,24(sp)
    800063ae:	6442                	ld	s0,16(sp)
    800063b0:	64a2                	ld	s1,8(sp)
    800063b2:	6105                	addi	sp,sp,32
    800063b4:	8082                	ret
    panic("could not find virtio disk");
    800063b6:	00002517          	auipc	a0,0x2
    800063ba:	3fa50513          	addi	a0,a0,1018 # 800087b0 <syscalls+0x360>
    800063be:	ffffa097          	auipc	ra,0xffffa
    800063c2:	180080e7          	jalr	384(ra) # 8000053e <panic>
    panic("virtio disk has no queue 0");
    800063c6:	00002517          	auipc	a0,0x2
    800063ca:	40a50513          	addi	a0,a0,1034 # 800087d0 <syscalls+0x380>
    800063ce:	ffffa097          	auipc	ra,0xffffa
    800063d2:	170080e7          	jalr	368(ra) # 8000053e <panic>
    panic("virtio disk max queue too short");
    800063d6:	00002517          	auipc	a0,0x2
    800063da:	41a50513          	addi	a0,a0,1050 # 800087f0 <syscalls+0x3a0>
    800063de:	ffffa097          	auipc	ra,0xffffa
    800063e2:	160080e7          	jalr	352(ra) # 8000053e <panic>

00000000800063e6 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    800063e6:	7159                	addi	sp,sp,-112
    800063e8:	f486                	sd	ra,104(sp)
    800063ea:	f0a2                	sd	s0,96(sp)
    800063ec:	eca6                	sd	s1,88(sp)
    800063ee:	e8ca                	sd	s2,80(sp)
    800063f0:	e4ce                	sd	s3,72(sp)
    800063f2:	e0d2                	sd	s4,64(sp)
    800063f4:	fc56                	sd	s5,56(sp)
    800063f6:	f85a                	sd	s6,48(sp)
    800063f8:	f45e                	sd	s7,40(sp)
    800063fa:	f062                	sd	s8,32(sp)
    800063fc:	ec66                	sd	s9,24(sp)
    800063fe:	e86a                	sd	s10,16(sp)
    80006400:	1880                	addi	s0,sp,112
    80006402:	892a                	mv	s2,a0
    80006404:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80006406:	00c52c83          	lw	s9,12(a0)
    8000640a:	001c9c9b          	slliw	s9,s9,0x1
    8000640e:	1c82                	slli	s9,s9,0x20
    80006410:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80006414:	0001f517          	auipc	a0,0x1f
    80006418:	d1450513          	addi	a0,a0,-748 # 80025128 <disk+0x2128>
    8000641c:	ffffa097          	auipc	ra,0xffffa
    80006420:	7c8080e7          	jalr	1992(ra) # 80000be4 <acquire>
  for(int i = 0; i < 3; i++){
    80006424:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80006426:	4c21                	li	s8,8
      disk.free[i] = 0;
    80006428:	0001db97          	auipc	s7,0x1d
    8000642c:	bd8b8b93          	addi	s7,s7,-1064 # 80023000 <disk>
    80006430:	6b09                	lui	s6,0x2
  for(int i = 0; i < 3; i++){
    80006432:	4a8d                	li	s5,3
  for(int i = 0; i < NUM; i++){
    80006434:	8a4e                	mv	s4,s3
    80006436:	a051                	j	800064ba <virtio_disk_rw+0xd4>
      disk.free[i] = 0;
    80006438:	00fb86b3          	add	a3,s7,a5
    8000643c:	96da                	add	a3,a3,s6
    8000643e:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    80006442:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    80006444:	0207c563          	bltz	a5,8000646e <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    80006448:	2485                	addiw	s1,s1,1
    8000644a:	0711                	addi	a4,a4,4
    8000644c:	25548063          	beq	s1,s5,8000668c <virtio_disk_rw+0x2a6>
    idx[i] = alloc_desc();
    80006450:	863a                	mv	a2,a4
  for(int i = 0; i < NUM; i++){
    80006452:	0001f697          	auipc	a3,0x1f
    80006456:	bc668693          	addi	a3,a3,-1082 # 80025018 <disk+0x2018>
    8000645a:	87d2                	mv	a5,s4
    if(disk.free[i]){
    8000645c:	0006c583          	lbu	a1,0(a3)
    80006460:	fde1                	bnez	a1,80006438 <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    80006462:	2785                	addiw	a5,a5,1
    80006464:	0685                	addi	a3,a3,1
    80006466:	ff879be3          	bne	a5,s8,8000645c <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    8000646a:	57fd                	li	a5,-1
    8000646c:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    8000646e:	02905a63          	blez	s1,800064a2 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006472:	f9042503          	lw	a0,-112(s0)
    80006476:	00000097          	auipc	ra,0x0
    8000647a:	d90080e7          	jalr	-624(ra) # 80006206 <free_desc>
      for(int j = 0; j < i; j++)
    8000647e:	4785                	li	a5,1
    80006480:	0297d163          	bge	a5,s1,800064a2 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006484:	f9442503          	lw	a0,-108(s0)
    80006488:	00000097          	auipc	ra,0x0
    8000648c:	d7e080e7          	jalr	-642(ra) # 80006206 <free_desc>
      for(int j = 0; j < i; j++)
    80006490:	4789                	li	a5,2
    80006492:	0097d863          	bge	a5,s1,800064a2 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006496:	f9842503          	lw	a0,-104(s0)
    8000649a:	00000097          	auipc	ra,0x0
    8000649e:	d6c080e7          	jalr	-660(ra) # 80006206 <free_desc>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    800064a2:	0001f597          	auipc	a1,0x1f
    800064a6:	c8658593          	addi	a1,a1,-890 # 80025128 <disk+0x2128>
    800064aa:	0001f517          	auipc	a0,0x1f
    800064ae:	b6e50513          	addi	a0,a0,-1170 # 80025018 <disk+0x2018>
    800064b2:	ffffc097          	auipc	ra,0xffffc
    800064b6:	f90080e7          	jalr	-112(ra) # 80002442 <sleep>
  for(int i = 0; i < 3; i++){
    800064ba:	f9040713          	addi	a4,s0,-112
    800064be:	84ce                	mv	s1,s3
    800064c0:	bf41                	j	80006450 <virtio_disk_rw+0x6a>
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];

  if(write)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
    800064c2:	20058713          	addi	a4,a1,512
    800064c6:	00471693          	slli	a3,a4,0x4
    800064ca:	0001d717          	auipc	a4,0x1d
    800064ce:	b3670713          	addi	a4,a4,-1226 # 80023000 <disk>
    800064d2:	9736                	add	a4,a4,a3
    800064d4:	4685                	li	a3,1
    800064d6:	0ad72423          	sw	a3,168(a4)
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    800064da:	20058713          	addi	a4,a1,512
    800064de:	00471693          	slli	a3,a4,0x4
    800064e2:	0001d717          	auipc	a4,0x1d
    800064e6:	b1e70713          	addi	a4,a4,-1250 # 80023000 <disk>
    800064ea:	9736                	add	a4,a4,a3
    800064ec:	0a072623          	sw	zero,172(a4)
  buf0->sector = sector;
    800064f0:	0b973823          	sd	s9,176(a4)

  disk.desc[idx[0]].addr = (uint64) buf0;
    800064f4:	7679                	lui	a2,0xffffe
    800064f6:	963e                	add	a2,a2,a5
    800064f8:	0001f697          	auipc	a3,0x1f
    800064fc:	b0868693          	addi	a3,a3,-1272 # 80025000 <disk+0x2000>
    80006500:	6298                	ld	a4,0(a3)
    80006502:	9732                	add	a4,a4,a2
    80006504:	e308                	sd	a0,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    80006506:	6298                	ld	a4,0(a3)
    80006508:	9732                	add	a4,a4,a2
    8000650a:	4541                	li	a0,16
    8000650c:	c708                	sw	a0,8(a4)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    8000650e:	6298                	ld	a4,0(a3)
    80006510:	9732                	add	a4,a4,a2
    80006512:	4505                	li	a0,1
    80006514:	00a71623          	sh	a0,12(a4)
  disk.desc[idx[0]].next = idx[1];
    80006518:	f9442703          	lw	a4,-108(s0)
    8000651c:	6288                	ld	a0,0(a3)
    8000651e:	962a                	add	a2,a2,a0
    80006520:	00e61723          	sh	a4,14(a2) # ffffffffffffe00e <end+0xffffffff7ffd800e>

  disk.desc[idx[1]].addr = (uint64) b->data;
    80006524:	0712                	slli	a4,a4,0x4
    80006526:	6290                	ld	a2,0(a3)
    80006528:	963a                	add	a2,a2,a4
    8000652a:	05890513          	addi	a0,s2,88
    8000652e:	e208                	sd	a0,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    80006530:	6294                	ld	a3,0(a3)
    80006532:	96ba                	add	a3,a3,a4
    80006534:	40000613          	li	a2,1024
    80006538:	c690                	sw	a2,8(a3)
  if(write)
    8000653a:	140d0063          	beqz	s10,8000667a <virtio_disk_rw+0x294>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    8000653e:	0001f697          	auipc	a3,0x1f
    80006542:	ac26b683          	ld	a3,-1342(a3) # 80025000 <disk+0x2000>
    80006546:	96ba                	add	a3,a3,a4
    80006548:	00069623          	sh	zero,12(a3)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    8000654c:	0001d817          	auipc	a6,0x1d
    80006550:	ab480813          	addi	a6,a6,-1356 # 80023000 <disk>
    80006554:	0001f517          	auipc	a0,0x1f
    80006558:	aac50513          	addi	a0,a0,-1364 # 80025000 <disk+0x2000>
    8000655c:	6114                	ld	a3,0(a0)
    8000655e:	96ba                	add	a3,a3,a4
    80006560:	00c6d603          	lhu	a2,12(a3)
    80006564:	00166613          	ori	a2,a2,1
    80006568:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    8000656c:	f9842683          	lw	a3,-104(s0)
    80006570:	6110                	ld	a2,0(a0)
    80006572:	9732                	add	a4,a4,a2
    80006574:	00d71723          	sh	a3,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80006578:	20058613          	addi	a2,a1,512
    8000657c:	0612                	slli	a2,a2,0x4
    8000657e:	9642                	add	a2,a2,a6
    80006580:	577d                	li	a4,-1
    80006582:	02e60823          	sb	a4,48(a2)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80006586:	00469713          	slli	a4,a3,0x4
    8000658a:	6114                	ld	a3,0(a0)
    8000658c:	96ba                	add	a3,a3,a4
    8000658e:	03078793          	addi	a5,a5,48
    80006592:	97c2                	add	a5,a5,a6
    80006594:	e29c                	sd	a5,0(a3)
  disk.desc[idx[2]].len = 1;
    80006596:	611c                	ld	a5,0(a0)
    80006598:	97ba                	add	a5,a5,a4
    8000659a:	4685                	li	a3,1
    8000659c:	c794                	sw	a3,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    8000659e:	611c                	ld	a5,0(a0)
    800065a0:	97ba                	add	a5,a5,a4
    800065a2:	4809                	li	a6,2
    800065a4:	01079623          	sh	a6,12(a5)
  disk.desc[idx[2]].next = 0;
    800065a8:	611c                	ld	a5,0(a0)
    800065aa:	973e                	add	a4,a4,a5
    800065ac:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    800065b0:	00d92223          	sw	a3,4(s2)
  disk.info[idx[0]].b = b;
    800065b4:	03263423          	sd	s2,40(a2)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    800065b8:	6518                	ld	a4,8(a0)
    800065ba:	00275783          	lhu	a5,2(a4)
    800065be:	8b9d                	andi	a5,a5,7
    800065c0:	0786                	slli	a5,a5,0x1
    800065c2:	97ba                	add	a5,a5,a4
    800065c4:	00b79223          	sh	a1,4(a5)

  __sync_synchronize();
    800065c8:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    800065cc:	6518                	ld	a4,8(a0)
    800065ce:	00275783          	lhu	a5,2(a4)
    800065d2:	2785                	addiw	a5,a5,1
    800065d4:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    800065d8:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    800065dc:	100017b7          	lui	a5,0x10001
    800065e0:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    800065e4:	00492703          	lw	a4,4(s2)
    800065e8:	4785                	li	a5,1
    800065ea:	02f71163          	bne	a4,a5,8000660c <virtio_disk_rw+0x226>
    sleep(b, &disk.vdisk_lock);
    800065ee:	0001f997          	auipc	s3,0x1f
    800065f2:	b3a98993          	addi	s3,s3,-1222 # 80025128 <disk+0x2128>
  while(b->disk == 1) {
    800065f6:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    800065f8:	85ce                	mv	a1,s3
    800065fa:	854a                	mv	a0,s2
    800065fc:	ffffc097          	auipc	ra,0xffffc
    80006600:	e46080e7          	jalr	-442(ra) # 80002442 <sleep>
  while(b->disk == 1) {
    80006604:	00492783          	lw	a5,4(s2)
    80006608:	fe9788e3          	beq	a5,s1,800065f8 <virtio_disk_rw+0x212>
  }

  disk.info[idx[0]].b = 0;
    8000660c:	f9042903          	lw	s2,-112(s0)
    80006610:	20090793          	addi	a5,s2,512
    80006614:	00479713          	slli	a4,a5,0x4
    80006618:	0001d797          	auipc	a5,0x1d
    8000661c:	9e878793          	addi	a5,a5,-1560 # 80023000 <disk>
    80006620:	97ba                	add	a5,a5,a4
    80006622:	0207b423          	sd	zero,40(a5)
    int flag = disk.desc[i].flags;
    80006626:	0001f997          	auipc	s3,0x1f
    8000662a:	9da98993          	addi	s3,s3,-1574 # 80025000 <disk+0x2000>
    8000662e:	00491713          	slli	a4,s2,0x4
    80006632:	0009b783          	ld	a5,0(s3)
    80006636:	97ba                	add	a5,a5,a4
    80006638:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    8000663c:	854a                	mv	a0,s2
    8000663e:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    80006642:	00000097          	auipc	ra,0x0
    80006646:	bc4080e7          	jalr	-1084(ra) # 80006206 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    8000664a:	8885                	andi	s1,s1,1
    8000664c:	f0ed                	bnez	s1,8000662e <virtio_disk_rw+0x248>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    8000664e:	0001f517          	auipc	a0,0x1f
    80006652:	ada50513          	addi	a0,a0,-1318 # 80025128 <disk+0x2128>
    80006656:	ffffa097          	auipc	ra,0xffffa
    8000665a:	642080e7          	jalr	1602(ra) # 80000c98 <release>
}
    8000665e:	70a6                	ld	ra,104(sp)
    80006660:	7406                	ld	s0,96(sp)
    80006662:	64e6                	ld	s1,88(sp)
    80006664:	6946                	ld	s2,80(sp)
    80006666:	69a6                	ld	s3,72(sp)
    80006668:	6a06                	ld	s4,64(sp)
    8000666a:	7ae2                	ld	s5,56(sp)
    8000666c:	7b42                	ld	s6,48(sp)
    8000666e:	7ba2                	ld	s7,40(sp)
    80006670:	7c02                	ld	s8,32(sp)
    80006672:	6ce2                	ld	s9,24(sp)
    80006674:	6d42                	ld	s10,16(sp)
    80006676:	6165                	addi	sp,sp,112
    80006678:	8082                	ret
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    8000667a:	0001f697          	auipc	a3,0x1f
    8000667e:	9866b683          	ld	a3,-1658(a3) # 80025000 <disk+0x2000>
    80006682:	96ba                	add	a3,a3,a4
    80006684:	4609                	li	a2,2
    80006686:	00c69623          	sh	a2,12(a3)
    8000668a:	b5c9                	j	8000654c <virtio_disk_rw+0x166>
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    8000668c:	f9042583          	lw	a1,-112(s0)
    80006690:	20058793          	addi	a5,a1,512
    80006694:	0792                	slli	a5,a5,0x4
    80006696:	0001d517          	auipc	a0,0x1d
    8000669a:	a1250513          	addi	a0,a0,-1518 # 800230a8 <disk+0xa8>
    8000669e:	953e                	add	a0,a0,a5
  if(write)
    800066a0:	e20d11e3          	bnez	s10,800064c2 <virtio_disk_rw+0xdc>
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
    800066a4:	20058713          	addi	a4,a1,512
    800066a8:	00471693          	slli	a3,a4,0x4
    800066ac:	0001d717          	auipc	a4,0x1d
    800066b0:	95470713          	addi	a4,a4,-1708 # 80023000 <disk>
    800066b4:	9736                	add	a4,a4,a3
    800066b6:	0a072423          	sw	zero,168(a4)
    800066ba:	b505                	j	800064da <virtio_disk_rw+0xf4>

00000000800066bc <virtio_disk_intr>:

void
virtio_disk_intr()
{
    800066bc:	1101                	addi	sp,sp,-32
    800066be:	ec06                	sd	ra,24(sp)
    800066c0:	e822                	sd	s0,16(sp)
    800066c2:	e426                	sd	s1,8(sp)
    800066c4:	e04a                	sd	s2,0(sp)
    800066c6:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    800066c8:	0001f517          	auipc	a0,0x1f
    800066cc:	a6050513          	addi	a0,a0,-1440 # 80025128 <disk+0x2128>
    800066d0:	ffffa097          	auipc	ra,0xffffa
    800066d4:	514080e7          	jalr	1300(ra) # 80000be4 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    800066d8:	10001737          	lui	a4,0x10001
    800066dc:	533c                	lw	a5,96(a4)
    800066de:	8b8d                	andi	a5,a5,3
    800066e0:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    800066e2:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    800066e6:	0001f797          	auipc	a5,0x1f
    800066ea:	91a78793          	addi	a5,a5,-1766 # 80025000 <disk+0x2000>
    800066ee:	6b94                	ld	a3,16(a5)
    800066f0:	0207d703          	lhu	a4,32(a5)
    800066f4:	0026d783          	lhu	a5,2(a3)
    800066f8:	06f70163          	beq	a4,a5,8000675a <virtio_disk_intr+0x9e>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    800066fc:	0001d917          	auipc	s2,0x1d
    80006700:	90490913          	addi	s2,s2,-1788 # 80023000 <disk>
    80006704:	0001f497          	auipc	s1,0x1f
    80006708:	8fc48493          	addi	s1,s1,-1796 # 80025000 <disk+0x2000>
    __sync_synchronize();
    8000670c:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006710:	6898                	ld	a4,16(s1)
    80006712:	0204d783          	lhu	a5,32(s1)
    80006716:	8b9d                	andi	a5,a5,7
    80006718:	078e                	slli	a5,a5,0x3
    8000671a:	97ba                	add	a5,a5,a4
    8000671c:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    8000671e:	20078713          	addi	a4,a5,512
    80006722:	0712                	slli	a4,a4,0x4
    80006724:	974a                	add	a4,a4,s2
    80006726:	03074703          	lbu	a4,48(a4) # 10001030 <_entry-0x6fffefd0>
    8000672a:	e731                	bnez	a4,80006776 <virtio_disk_intr+0xba>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    8000672c:	20078793          	addi	a5,a5,512
    80006730:	0792                	slli	a5,a5,0x4
    80006732:	97ca                	add	a5,a5,s2
    80006734:	7788                	ld	a0,40(a5)
    b->disk = 0;   // disk is done with buf
    80006736:	00052223          	sw	zero,4(a0)
    wakeup(b);
    8000673a:	ffffc097          	auipc	ra,0xffffc
    8000673e:	ec8080e7          	jalr	-312(ra) # 80002602 <wakeup>

    disk.used_idx += 1;
    80006742:	0204d783          	lhu	a5,32(s1)
    80006746:	2785                	addiw	a5,a5,1
    80006748:	17c2                	slli	a5,a5,0x30
    8000674a:	93c1                	srli	a5,a5,0x30
    8000674c:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006750:	6898                	ld	a4,16(s1)
    80006752:	00275703          	lhu	a4,2(a4)
    80006756:	faf71be3          	bne	a4,a5,8000670c <virtio_disk_intr+0x50>
  }

  release(&disk.vdisk_lock);
    8000675a:	0001f517          	auipc	a0,0x1f
    8000675e:	9ce50513          	addi	a0,a0,-1586 # 80025128 <disk+0x2128>
    80006762:	ffffa097          	auipc	ra,0xffffa
    80006766:	536080e7          	jalr	1334(ra) # 80000c98 <release>
}
    8000676a:	60e2                	ld	ra,24(sp)
    8000676c:	6442                	ld	s0,16(sp)
    8000676e:	64a2                	ld	s1,8(sp)
    80006770:	6902                	ld	s2,0(sp)
    80006772:	6105                	addi	sp,sp,32
    80006774:	8082                	ret
      panic("virtio_disk_intr status");
    80006776:	00002517          	auipc	a0,0x2
    8000677a:	09a50513          	addi	a0,a0,154 # 80008810 <syscalls+0x3c0>
    8000677e:	ffffa097          	auipc	ra,0xffffa
    80006782:	dc0080e7          	jalr	-576(ra) # 8000053e <panic>
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
