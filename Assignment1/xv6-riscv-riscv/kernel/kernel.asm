
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
    80000068:	f8c78793          	addi	a5,a5,-116 # 80005ff0 <timervec>
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
    8000012c:	00002097          	auipc	ra,0x2
    80000130:	7c8080e7          	jalr	1992(ra) # 800028f4 <either_copyin>
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
    800001d8:	1a4080e7          	jalr	420(ra) # 80002378 <sleep>
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
    80000214:	68e080e7          	jalr	1678(ra) # 8000289e <either_copyout>
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
    800002f6:	658080e7          	jalr	1624(ra) # 8000294a <procdump>
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
    8000044a:	0d2080e7          	jalr	210(ra) # 80002518 <wakeup>
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
    800008a4:	c78080e7          	jalr	-904(ra) # 80002518 <wakeup>
    
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
    80000930:	a4c080e7          	jalr	-1460(ra) # 80002378 <sleep>
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
    80000ed8:	bb6080e7          	jalr	-1098(ra) # 80002a8a <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000edc:	00005097          	auipc	ra,0x5
    80000ee0:	154080e7          	jalr	340(ra) # 80006030 <plicinithart>
  }

  scheduler();        
    80000ee4:	00001097          	auipc	ra,0x1
    80000ee8:	35a080e7          	jalr	858(ra) # 8000223e <scheduler>
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
    80000f58:	b0e080e7          	jalr	-1266(ra) # 80002a62 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f5c:	00002097          	auipc	ra,0x2
    80000f60:	b2e080e7          	jalr	-1234(ra) # 80002a8a <trapinithart>
    plicinit();      // set up interrupt controller
    80000f64:	00005097          	auipc	ra,0x5
    80000f68:	0b6080e7          	jalr	182(ra) # 8000601a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f6c:	00005097          	auipc	ra,0x5
    80000f70:	0c4080e7          	jalr	196(ra) # 80006030 <plicinithart>
    binit();         // buffer cache
    80000f74:	00002097          	auipc	ra,0x2
    80000f78:	2a6080e7          	jalr	678(ra) # 8000321a <binit>
    iinit();         // inode table
    80000f7c:	00003097          	auipc	ra,0x3
    80000f80:	936080e7          	jalr	-1738(ra) # 800038b2 <iinit>
    fileinit();      // file table
    80000f84:	00004097          	auipc	ra,0x4
    80000f88:	8e0080e7          	jalr	-1824(ra) # 80004864 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f8c:	00005097          	auipc	ra,0x5
    80000f90:	1c6080e7          	jalr	454(ra) # 80006152 <virtio_disk_init>
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
    80001a1c:	e187a783          	lw	a5,-488(a5) # 80008830 <first.1723>
    80001a20:	eb89                	bnez	a5,80001a32 <forkret+0x32>
        // be run from main().
        first = 0;
        fsinit(ROOTDEV);
    }

    usertrapret();
    80001a22:	00001097          	auipc	ra,0x1
    80001a26:	080080e7          	jalr	128(ra) # 80002aa2 <usertrapret>
}
    80001a2a:	60a2                	ld	ra,8(sp)
    80001a2c:	6402                	ld	s0,0(sp)
    80001a2e:	0141                	addi	sp,sp,16
    80001a30:	8082                	ret
        first = 0;
    80001a32:	00007797          	auipc	a5,0x7
    80001a36:	de07af23          	sw	zero,-514(a5) # 80008830 <first.1723>
        fsinit(ROOTDEV);
    80001a3a:	4505                	li	a0,1
    80001a3c:	00002097          	auipc	ra,0x2
    80001a40:	df6080e7          	jalr	-522(ra) # 80003832 <fsinit>
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
    80001d24:	540080e7          	jalr	1344(ra) # 80004260 <namei>
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
    80001e66:	a94080e7          	jalr	-1388(ra) # 800048f6 <filedup>
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
    80001e88:	be8080e7          	jalr	-1048(ra) # 80003a6c <idup>
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
    80001fbe:	a3e080e7          	jalr	-1474(ra) # 800029f8 <swtch>
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
    80001ff6:	7159                	addi	sp,sp,-112
    80001ff8:	f486                	sd	ra,104(sp)
    80001ffa:	f0a2                	sd	s0,96(sp)
    80001ffc:	eca6                	sd	s1,88(sp)
    80001ffe:	e8ca                	sd	s2,80(sp)
    80002000:	e4ce                	sd	s3,72(sp)
    80002002:	e0d2                	sd	s4,64(sp)
    80002004:	fc56                	sd	s5,56(sp)
    80002006:	f85a                	sd	s6,48(sp)
    80002008:	f45e                	sd	s7,40(sp)
    8000200a:	f062                	sd	s8,32(sp)
    8000200c:	ec66                	sd	s9,24(sp)
    8000200e:	e86a                	sd	s10,16(sp)
    80002010:	e46e                	sd	s11,8(sp)
    80002012:	1880                	addi	s0,sp,112
  asm volatile("mv %0, tp" : "=r" (x) );
    80002014:	8792                	mv	a5,tp
    int id = r_tp();
    80002016:	2781                	sext.w	a5,a5
    c->proc = 0;
    80002018:	00779c93          	slli	s9,a5,0x7
    8000201c:	0000f717          	auipc	a4,0xf
    80002020:	2a470713          	addi	a4,a4,676 # 800112c0 <pid_lock>
    80002024:	9766                	add	a4,a4,s9
    80002026:	02073823          	sd	zero,48(a4)
            swtch(&c->context, &min_proc->context);
    8000202a:	0000f717          	auipc	a4,0xf
    8000202e:	2ce70713          	addi	a4,a4,718 # 800112f8 <cpus+0x8>
    80002032:	9cba                	add	s9,s9,a4
        if (ticks >= pauseTicks) {
    80002034:	00007b17          	auipc	s6,0x7
    80002038:	01cb0b13          	addi	s6,s6,28 # 80009050 <ticks>
    8000203c:	00007d97          	auipc	s11,0x7
    80002040:	004d8d93          	addi	s11,s11,4 # 80009040 <pauseTicks>
        struct proc *min_proc = proc;
    80002044:	0000fc17          	auipc	s8,0xf
    80002048:	6acc0c13          	addi	s8,s8,1708 # 800116f0 <proc>
            for (p = proc; p < &proc[NPROC]; p++) {
    8000204c:	00016997          	auipc	s3,0x16
    80002050:	8a498993          	addi	s3,s3,-1884 # 800178f0 <tickslock>
            p->runnable_time = p->runnable_time + ticks - p->last_time_changed;
    80002054:	00015a97          	auipc	s5,0x15
    80002058:	69ca8a93          	addi	s5,s5,1692 # 800176f0 <proc+0x6000>
            c->proc = min_proc;
    8000205c:	079e                	slli	a5,a5,0x7
    8000205e:	0000fb97          	auipc	s7,0xf
    80002062:	262b8b93          	addi	s7,s7,610 # 800112c0 <pid_lock>
    80002066:	9bbe                	add	s7,s7,a5
            p->mean_ticks = ((10 - rate) * p->mean_ticks + p->last_ticks * (rate)) / 10;
    80002068:	00006d17          	auipc	s10,0x6
    8000206c:	7d0d0d13          	addi	s10,s10,2000 # 80008838 <rate>
    80002070:	a055                	j	80002114 <sjfScheduler+0x11e>
                release(&p->lock);
    80002072:	8526                	mv	a0,s1
    80002074:	fffff097          	auipc	ra,0xfffff
    80002078:	c24080e7          	jalr	-988(ra) # 80000c98 <release>
            for (p = proc; p < &proc[NPROC]; p++) {
    8000207c:	18848493          	addi	s1,s1,392
    80002080:	03348163          	beq	s1,s3,800020a2 <sjfScheduler+0xac>
                acquire(&p->lock);
    80002084:	8526                	mv	a0,s1
    80002086:	fffff097          	auipc	ra,0xfffff
    8000208a:	b5e080e7          	jalr	-1186(ra) # 80000be4 <acquire>
                if (p->state == RUNNABLE && p->mean_ticks < min_proc->mean_ticks)
    8000208e:	4c9c                	lw	a5,24(s1)
    80002090:	ff2791e3          	bne	a5,s2,80002072 <sjfScheduler+0x7c>
    80002094:	40b8                	lw	a4,64(s1)
    80002096:	040a2783          	lw	a5,64(s4)
    8000209a:	fcf75ce3          	bge	a4,a5,80002072 <sjfScheduler+0x7c>
    8000209e:	8a26                	mv	s4,s1
    800020a0:	bfc9                	j	80002072 <sjfScheduler+0x7c>
            acquire(&min_proc->lock);
    800020a2:	8552                	mv	a0,s4
    800020a4:	fffff097          	auipc	ra,0xfffff
    800020a8:	b40080e7          	jalr	-1216(ra) # 80000be4 <acquire>
            p->runnable_time = p->runnable_time + ticks - p->last_time_changed;
    800020ac:	000b2483          	lw	s1,0(s6)
    800020b0:	250aa783          	lw	a5,592(s5)
    800020b4:	9fa5                	addw	a5,a5,s1
    800020b6:	258aa703          	lw	a4,600(s5)
    800020ba:	9f99                	subw	a5,a5,a4
    800020bc:	24faa823          	sw	a5,592(s5)
            p->last_time_changed = ticks;      //setting the starting ticks when getting to runnable for section 4
    800020c0:	249aac23          	sw	s1,600(s5)
            min_proc->state = RUNNING;
    800020c4:	4791                	li	a5,4
    800020c6:	00fa2c23          	sw	a5,24(s4)
            c->proc = min_proc;
    800020ca:	034bb823          	sd	s4,48(s7)
            swtch(&c->context, &min_proc->context);
    800020ce:	080a0593          	addi	a1,s4,128
    800020d2:	8566                	mv	a0,s9
    800020d4:	00001097          	auipc	ra,0x1
    800020d8:	924080e7          	jalr	-1756(ra) # 800029f8 <swtch>
            p->last_ticks = ticks - startingTicks;
    800020dc:	000b2703          	lw	a4,0(s6)
    800020e0:	9f05                	subw	a4,a4,s1
    800020e2:	24eaa223          	sw	a4,580(s5)
            p->mean_ticks = ((10 - rate) * p->mean_ticks + p->last_ticks * (rate)) / 10;
    800020e6:	000d2603          	lw	a2,0(s10)
    800020ea:	46a9                	li	a3,10
    800020ec:	40c687bb          	subw	a5,a3,a2
    800020f0:	240aa583          	lw	a1,576(s5)
    800020f4:	02b787bb          	mulw	a5,a5,a1
    800020f8:	02c7073b          	mulw	a4,a4,a2
    800020fc:	9fb9                	addw	a5,a5,a4
    800020fe:	02d7c7bb          	divw	a5,a5,a3
    80002102:	24faa023          	sw	a5,576(s5)
            c->proc = 0;
    80002106:	020bb823          	sd	zero,48(s7)
            release(&min_proc->lock);
    8000210a:	8552                	mv	a0,s4
    8000210c:	fffff097          	auipc	ra,0xfffff
    80002110:	b8c080e7          	jalr	-1140(ra) # 80000c98 <release>
        if (ticks >= pauseTicks) {
    80002114:	000b2683          	lw	a3,0(s6)
    80002118:	000da703          	lw	a4,0(s11)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000211c:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002120:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002124:	10079073          	csrw	sstatus,a5
    80002128:	fee6eae3          	bltu	a3,a4,8000211c <sjfScheduler+0x126>
        struct proc *min_proc = proc;
    8000212c:	8a62                	mv	s4,s8
            for (p = proc; p < &proc[NPROC]; p++) {
    8000212e:	84e2                	mv	s1,s8
                if (p->state == RUNNABLE && p->mean_ticks < min_proc->mean_ticks)
    80002130:	490d                	li	s2,3
    80002132:	bf89                	j	80002084 <sjfScheduler+0x8e>

0000000080002134 <fcfs>:
void fcfs(void) {
    80002134:	711d                	addi	sp,sp,-96
    80002136:	ec86                	sd	ra,88(sp)
    80002138:	e8a2                	sd	s0,80(sp)
    8000213a:	e4a6                	sd	s1,72(sp)
    8000213c:	e0ca                	sd	s2,64(sp)
    8000213e:	fc4e                	sd	s3,56(sp)
    80002140:	f852                	sd	s4,48(sp)
    80002142:	f456                	sd	s5,40(sp)
    80002144:	f05a                	sd	s6,32(sp)
    80002146:	ec5e                	sd	s7,24(sp)
    80002148:	e862                	sd	s8,16(sp)
    8000214a:	e466                	sd	s9,8(sp)
    8000214c:	e06a                	sd	s10,0(sp)
    8000214e:	1080                	addi	s0,sp,96
  asm volatile("mv %0, tp" : "=r" (x) );
    80002150:	8792                	mv	a5,tp
    int id = r_tp();
    80002152:	2781                	sext.w	a5,a5
    c->proc = 0;
    80002154:	00779c93          	slli	s9,a5,0x7
    80002158:	0000f717          	auipc	a4,0xf
    8000215c:	16870713          	addi	a4,a4,360 # 800112c0 <pid_lock>
    80002160:	9766                	add	a4,a4,s9
    80002162:	02073823          	sd	zero,48(a4)
            swtch(&c->context, &max_lrt_proc->context);
    80002166:	0000f717          	auipc	a4,0xf
    8000216a:	19270713          	addi	a4,a4,402 # 800112f8 <cpus+0x8>
    8000216e:	9cba                	add	s9,s9,a4
        if (ticks >= pauseTicks) {
    80002170:	00007c17          	auipc	s8,0x7
    80002174:	ee0c0c13          	addi	s8,s8,-288 # 80009050 <ticks>
    80002178:	00007d17          	auipc	s10,0x7
    8000217c:	ec8d0d13          	addi	s10,s10,-312 # 80009040 <pauseTicks>
            struct proc *max_lrt_proc = proc; // lrt = last runnable time
    80002180:	0000fb97          	auipc	s7,0xf
    80002184:	570b8b93          	addi	s7,s7,1392 # 800116f0 <proc>
                if (p->state == RUNNABLE && p->mean_ticks > max_lrt_proc->mean_ticks)
    80002188:	498d                	li	s3,3
            for (p = proc; p < &proc[NPROC]; p++) {
    8000218a:	00015917          	auipc	s2,0x15
    8000218e:	76690913          	addi	s2,s2,1894 # 800178f0 <tickslock>
            p->runnable_time = p->runnable_time + ticks - p->last_time_changed;
    80002192:	00015a97          	auipc	s5,0x15
    80002196:	55ea8a93          	addi	s5,s5,1374 # 800176f0 <proc+0x6000>
            c->proc = max_lrt_proc;
    8000219a:	079e                	slli	a5,a5,0x7
    8000219c:	0000fb17          	auipc	s6,0xf
    800021a0:	124b0b13          	addi	s6,s6,292 # 800112c0 <pid_lock>
    800021a4:	9b3e                	add	s6,s6,a5
    800021a6:	a8ad                	j	80002220 <fcfs+0xec>
                release(&p->lock);
    800021a8:	8526                	mv	a0,s1
    800021aa:	fffff097          	auipc	ra,0xfffff
    800021ae:	aee080e7          	jalr	-1298(ra) # 80000c98 <release>
            for (p = proc; p < &proc[NPROC]; p++) {
    800021b2:	18848493          	addi	s1,s1,392
    800021b6:	03248163          	beq	s1,s2,800021d8 <fcfs+0xa4>
                acquire(&p->lock);
    800021ba:	8526                	mv	a0,s1
    800021bc:	fffff097          	auipc	ra,0xfffff
    800021c0:	a28080e7          	jalr	-1496(ra) # 80000be4 <acquire>
                if (p->state == RUNNABLE && p->mean_ticks > max_lrt_proc->mean_ticks)
    800021c4:	4c9c                	lw	a5,24(s1)
    800021c6:	ff3791e3          	bne	a5,s3,800021a8 <fcfs+0x74>
    800021ca:	40b8                	lw	a4,64(s1)
    800021cc:	040a2783          	lw	a5,64(s4)
    800021d0:	fce7dce3          	bge	a5,a4,800021a8 <fcfs+0x74>
    800021d4:	8a26                	mv	s4,s1
    800021d6:	bfc9                	j	800021a8 <fcfs+0x74>
            acquire(&max_lrt_proc->lock);
    800021d8:	8552                	mv	a0,s4
    800021da:	fffff097          	auipc	ra,0xfffff
    800021de:	a0a080e7          	jalr	-1526(ra) # 80000be4 <acquire>
            p->runnable_time = p->runnable_time + ticks - p->last_time_changed;
    800021e2:	000c2703          	lw	a4,0(s8)
    800021e6:	250aa783          	lw	a5,592(s5)
    800021ea:	9fb9                	addw	a5,a5,a4
    800021ec:	258aa683          	lw	a3,600(s5)
    800021f0:	9f95                	subw	a5,a5,a3
    800021f2:	24faa823          	sw	a5,592(s5)
            p->last_time_changed = ticks;      //setting the starting ticks when getting to runnable for section 4
    800021f6:	24eaac23          	sw	a4,600(s5)
            max_lrt_proc->state = RUNNING;
    800021fa:	4791                	li	a5,4
    800021fc:	00fa2c23          	sw	a5,24(s4)
            c->proc = max_lrt_proc;
    80002200:	034b3823          	sd	s4,48(s6)
            swtch(&c->context, &max_lrt_proc->context);
    80002204:	080a0593          	addi	a1,s4,128
    80002208:	8566                	mv	a0,s9
    8000220a:	00000097          	auipc	ra,0x0
    8000220e:	7ee080e7          	jalr	2030(ra) # 800029f8 <swtch>
            c->proc = 0;
    80002212:	020b3823          	sd	zero,48(s6)
            release(&max_lrt_proc->lock);
    80002216:	8552                	mv	a0,s4
    80002218:	fffff097          	auipc	ra,0xfffff
    8000221c:	a80080e7          	jalr	-1408(ra) # 80000c98 <release>
        if (ticks >= pauseTicks) {
    80002220:	000c2683          	lw	a3,0(s8)
    80002224:	000d2703          	lw	a4,0(s10)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002228:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    8000222c:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002230:	10079073          	csrw	sstatus,a5
    80002234:	fee6eae3          	bltu	a3,a4,80002228 <fcfs+0xf4>
            struct proc *max_lrt_proc = proc; // lrt = last runnable time
    80002238:	8a5e                	mv	s4,s7
            for (p = proc; p < &proc[NPROC]; p++) {
    8000223a:	84de                	mv	s1,s7
    8000223c:	bfbd                	j	800021ba <fcfs+0x86>

000000008000223e <scheduler>:
scheduler(void) {
    8000223e:	1141                	addi	sp,sp,-16
    80002240:	e406                	sd	ra,8(sp)
    80002242:	e022                	sd	s0,0(sp)
    80002244:	0800                	addi	s0,sp,16
    defScheduler();
    80002246:	00000097          	auipc	ra,0x0
    8000224a:	cca080e7          	jalr	-822(ra) # 80001f10 <defScheduler>

000000008000224e <sched>:
sched(void) {
    8000224e:	7179                	addi	sp,sp,-48
    80002250:	f406                	sd	ra,40(sp)
    80002252:	f022                	sd	s0,32(sp)
    80002254:	ec26                	sd	s1,24(sp)
    80002256:	e84a                	sd	s2,16(sp)
    80002258:	e44e                	sd	s3,8(sp)
    8000225a:	1800                	addi	s0,sp,48
    struct proc *p = myproc();
    8000225c:	fffff097          	auipc	ra,0xfffff
    80002260:	76c080e7          	jalr	1900(ra) # 800019c8 <myproc>
    80002264:	84aa                	mv	s1,a0
    if (!holding(&p->lock))
    80002266:	fffff097          	auipc	ra,0xfffff
    8000226a:	904080e7          	jalr	-1788(ra) # 80000b6a <holding>
    8000226e:	c93d                	beqz	a0,800022e4 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002270:	8792                	mv	a5,tp
    if (mycpu()->noff != 1)
    80002272:	2781                	sext.w	a5,a5
    80002274:	079e                	slli	a5,a5,0x7
    80002276:	0000f717          	auipc	a4,0xf
    8000227a:	04a70713          	addi	a4,a4,74 # 800112c0 <pid_lock>
    8000227e:	97ba                	add	a5,a5,a4
    80002280:	0a87a703          	lw	a4,168(a5)
    80002284:	4785                	li	a5,1
    80002286:	06f71763          	bne	a4,a5,800022f4 <sched+0xa6>
    if (p->state == RUNNING)
    8000228a:	4c98                	lw	a4,24(s1)
    8000228c:	4791                	li	a5,4
    8000228e:	06f70b63          	beq	a4,a5,80002304 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002292:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002296:	8b89                	andi	a5,a5,2
    if (intr_get())
    80002298:	efb5                	bnez	a5,80002314 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    8000229a:	8792                	mv	a5,tp
    intena = mycpu()->intena;
    8000229c:	0000f917          	auipc	s2,0xf
    800022a0:	02490913          	addi	s2,s2,36 # 800112c0 <pid_lock>
    800022a4:	2781                	sext.w	a5,a5
    800022a6:	079e                	slli	a5,a5,0x7
    800022a8:	97ca                	add	a5,a5,s2
    800022aa:	0ac7a983          	lw	s3,172(a5)
    800022ae:	8792                	mv	a5,tp
    swtch(&p->context, &mycpu()->context);
    800022b0:	2781                	sext.w	a5,a5
    800022b2:	079e                	slli	a5,a5,0x7
    800022b4:	0000f597          	auipc	a1,0xf
    800022b8:	04458593          	addi	a1,a1,68 # 800112f8 <cpus+0x8>
    800022bc:	95be                	add	a1,a1,a5
    800022be:	08048513          	addi	a0,s1,128
    800022c2:	00000097          	auipc	ra,0x0
    800022c6:	736080e7          	jalr	1846(ra) # 800029f8 <swtch>
    800022ca:	8792                	mv	a5,tp
    mycpu()->intena = intena;
    800022cc:	2781                	sext.w	a5,a5
    800022ce:	079e                	slli	a5,a5,0x7
    800022d0:	97ca                	add	a5,a5,s2
    800022d2:	0b37a623          	sw	s3,172(a5)
}
    800022d6:	70a2                	ld	ra,40(sp)
    800022d8:	7402                	ld	s0,32(sp)
    800022da:	64e2                	ld	s1,24(sp)
    800022dc:	6942                	ld	s2,16(sp)
    800022de:	69a2                	ld	s3,8(sp)
    800022e0:	6145                	addi	sp,sp,48
    800022e2:	8082                	ret
        panic("sched p->lock");
    800022e4:	00006517          	auipc	a0,0x6
    800022e8:	f4450513          	addi	a0,a0,-188 # 80008228 <digits+0x1e8>
    800022ec:	ffffe097          	auipc	ra,0xffffe
    800022f0:	252080e7          	jalr	594(ra) # 8000053e <panic>
        panic("sched locks");
    800022f4:	00006517          	auipc	a0,0x6
    800022f8:	f4450513          	addi	a0,a0,-188 # 80008238 <digits+0x1f8>
    800022fc:	ffffe097          	auipc	ra,0xffffe
    80002300:	242080e7          	jalr	578(ra) # 8000053e <panic>
        panic("sched running");
    80002304:	00006517          	auipc	a0,0x6
    80002308:	f4450513          	addi	a0,a0,-188 # 80008248 <digits+0x208>
    8000230c:	ffffe097          	auipc	ra,0xffffe
    80002310:	232080e7          	jalr	562(ra) # 8000053e <panic>
        panic("sched interruptible");
    80002314:	00006517          	auipc	a0,0x6
    80002318:	f4450513          	addi	a0,a0,-188 # 80008258 <digits+0x218>
    8000231c:	ffffe097          	auipc	ra,0xffffe
    80002320:	222080e7          	jalr	546(ra) # 8000053e <panic>

0000000080002324 <yield>:
yield(void) {
    80002324:	1101                	addi	sp,sp,-32
    80002326:	ec06                	sd	ra,24(sp)
    80002328:	e822                	sd	s0,16(sp)
    8000232a:	e426                	sd	s1,8(sp)
    8000232c:	1000                	addi	s0,sp,32
    struct proc *p = myproc();
    8000232e:	fffff097          	auipc	ra,0xfffff
    80002332:	69a080e7          	jalr	1690(ra) # 800019c8 <myproc>
    80002336:	84aa                	mv	s1,a0
    acquire(&p->lock);
    80002338:	fffff097          	auipc	ra,0xfffff
    8000233c:	8ac080e7          	jalr	-1876(ra) # 80000be4 <acquire>
    p->state = RUNNABLE;
    80002340:	478d                	li	a5,3
    80002342:	cc9c                	sw	a5,24(s1)
    p->running_time = p->running_time + (ticks - p->last_time_changed);
    80002344:	00007797          	auipc	a5,0x7
    80002348:	d0c7a783          	lw	a5,-756(a5) # 80009050 <ticks>
    8000234c:	48f8                	lw	a4,84(s1)
    8000234e:	9f3d                	addw	a4,a4,a5
    80002350:	4cb4                	lw	a3,88(s1)
    80002352:	9f15                	subw	a4,a4,a3
    80002354:	c8f8                	sw	a4,84(s1)
    p->last_runnable_time = ticks;     //added last_runnable time for fcfs
    80002356:	2781                	sext.w	a5,a5
    80002358:	c4bc                	sw	a5,72(s1)
    p->last_time_changed = ticks;      //setting the starting ticks when getting to runnable for section 4
    8000235a:	ccbc                	sw	a5,88(s1)
    sched();
    8000235c:	00000097          	auipc	ra,0x0
    80002360:	ef2080e7          	jalr	-270(ra) # 8000224e <sched>
    release(&p->lock);
    80002364:	8526                	mv	a0,s1
    80002366:	fffff097          	auipc	ra,0xfffff
    8000236a:	932080e7          	jalr	-1742(ra) # 80000c98 <release>
}
    8000236e:	60e2                	ld	ra,24(sp)
    80002370:	6442                	ld	s0,16(sp)
    80002372:	64a2                	ld	s1,8(sp)
    80002374:	6105                	addi	sp,sp,32
    80002376:	8082                	ret

0000000080002378 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk) {
    80002378:	7179                	addi	sp,sp,-48
    8000237a:	f406                	sd	ra,40(sp)
    8000237c:	f022                	sd	s0,32(sp)
    8000237e:	ec26                	sd	s1,24(sp)
    80002380:	e84a                	sd	s2,16(sp)
    80002382:	e44e                	sd	s3,8(sp)
    80002384:	1800                	addi	s0,sp,48
    80002386:	89aa                	mv	s3,a0
    80002388:	892e                	mv	s2,a1
    struct proc *p = myproc();
    8000238a:	fffff097          	auipc	ra,0xfffff
    8000238e:	63e080e7          	jalr	1598(ra) # 800019c8 <myproc>
    80002392:	84aa                	mv	s1,a0
    // Once we hold p->lock, we can be
    // guaranteed that we won't miss any wakeup
    // (wakeup locks p->lock),
    // so it's okay to release lk.

    acquire(&p->lock);  //DOC: sleeplock1
    80002394:	fffff097          	auipc	ra,0xfffff
    80002398:	850080e7          	jalr	-1968(ra) # 80000be4 <acquire>
    release(lk);
    8000239c:	854a                	mv	a0,s2
    8000239e:	fffff097          	auipc	ra,0xfffff
    800023a2:	8fa080e7          	jalr	-1798(ra) # 80000c98 <release>

//    acquire(&tickslock);
    p->running_time = p->running_time + ticks - p->last_time_changed;
    800023a6:	00007717          	auipc	a4,0x7
    800023aa:	caa72703          	lw	a4,-854(a4) # 80009050 <ticks>
    800023ae:	48fc                	lw	a5,84(s1)
    800023b0:	9fb9                	addw	a5,a5,a4
    800023b2:	4cb4                	lw	a3,88(s1)
    800023b4:	9f95                	subw	a5,a5,a3
    800023b6:	c8fc                	sw	a5,84(s1)
    p->last_time_changed = ticks;      //setting the starting ticks when getting to runnable for section 4
    800023b8:	ccb8                	sw	a4,88(s1)
//    release(&tickslock);

    // Go to sleep.
    p->chan = chan;
    800023ba:	0334b023          	sd	s3,32(s1)
    p->state = SLEEPING;
    800023be:	4789                	li	a5,2
    800023c0:	cc9c                	sw	a5,24(s1)

    sched();
    800023c2:	00000097          	auipc	ra,0x0
    800023c6:	e8c080e7          	jalr	-372(ra) # 8000224e <sched>

    // Tidy up.
    p->chan = 0;
    800023ca:	0204b023          	sd	zero,32(s1)

    // Reacquire original lock.
    release(&p->lock);
    800023ce:	8526                	mv	a0,s1
    800023d0:	fffff097          	auipc	ra,0xfffff
    800023d4:	8c8080e7          	jalr	-1848(ra) # 80000c98 <release>
    acquire(lk);
    800023d8:	854a                	mv	a0,s2
    800023da:	fffff097          	auipc	ra,0xfffff
    800023de:	80a080e7          	jalr	-2038(ra) # 80000be4 <acquire>
}
    800023e2:	70a2                	ld	ra,40(sp)
    800023e4:	7402                	ld	s0,32(sp)
    800023e6:	64e2                	ld	s1,24(sp)
    800023e8:	6942                	ld	s2,16(sp)
    800023ea:	69a2                	ld	s3,8(sp)
    800023ec:	6145                	addi	sp,sp,48
    800023ee:	8082                	ret

00000000800023f0 <wait>:
wait(uint64 addr) {
    800023f0:	715d                	addi	sp,sp,-80
    800023f2:	e486                	sd	ra,72(sp)
    800023f4:	e0a2                	sd	s0,64(sp)
    800023f6:	fc26                	sd	s1,56(sp)
    800023f8:	f84a                	sd	s2,48(sp)
    800023fa:	f44e                	sd	s3,40(sp)
    800023fc:	f052                	sd	s4,32(sp)
    800023fe:	ec56                	sd	s5,24(sp)
    80002400:	e85a                	sd	s6,16(sp)
    80002402:	e45e                	sd	s7,8(sp)
    80002404:	e062                	sd	s8,0(sp)
    80002406:	0880                	addi	s0,sp,80
    80002408:	8b2a                	mv	s6,a0
    struct proc *p = myproc();
    8000240a:	fffff097          	auipc	ra,0xfffff
    8000240e:	5be080e7          	jalr	1470(ra) # 800019c8 <myproc>
    80002412:	892a                	mv	s2,a0
    acquire(&wait_lock);
    80002414:	0000f517          	auipc	a0,0xf
    80002418:	ec450513          	addi	a0,a0,-316 # 800112d8 <wait_lock>
    8000241c:	ffffe097          	auipc	ra,0xffffe
    80002420:	7c8080e7          	jalr	1992(ra) # 80000be4 <acquire>
        havekids = 0;
    80002424:	4b81                	li	s7,0
                if (np->state == ZOMBIE) {
    80002426:	4a15                	li	s4,5
        for (np = proc; np < &proc[NPROC]; np++) {
    80002428:	00015997          	auipc	s3,0x15
    8000242c:	4c898993          	addi	s3,s3,1224 # 800178f0 <tickslock>
                havekids = 1;
    80002430:	4a85                	li	s5,1
        sleep(p, &wait_lock);  //DOC: wait-sleep
    80002432:	0000fc17          	auipc	s8,0xf
    80002436:	ea6c0c13          	addi	s8,s8,-346 # 800112d8 <wait_lock>
        havekids = 0;
    8000243a:	875e                	mv	a4,s7
        for (np = proc; np < &proc[NPROC]; np++) {
    8000243c:	0000f497          	auipc	s1,0xf
    80002440:	2b448493          	addi	s1,s1,692 # 800116f0 <proc>
    80002444:	a0bd                	j	800024b2 <wait+0xc2>
                    pid = np->pid;
    80002446:	0304a983          	lw	s3,48(s1)
                    if (addr != 0 && copyout(p->pagetable, addr, (char *) &np->xstate,
    8000244a:	000b0e63          	beqz	s6,80002466 <wait+0x76>
    8000244e:	4691                	li	a3,4
    80002450:	02c48613          	addi	a2,s1,44
    80002454:	85da                	mv	a1,s6
    80002456:	07093503          	ld	a0,112(s2)
    8000245a:	fffff097          	auipc	ra,0xfffff
    8000245e:	220080e7          	jalr	544(ra) # 8000167a <copyout>
    80002462:	02054563          	bltz	a0,8000248c <wait+0x9c>
                    freeproc(np);
    80002466:	8526                	mv	a0,s1
    80002468:	fffff097          	auipc	ra,0xfffff
    8000246c:	712080e7          	jalr	1810(ra) # 80001b7a <freeproc>
                    release(&np->lock);
    80002470:	8526                	mv	a0,s1
    80002472:	fffff097          	auipc	ra,0xfffff
    80002476:	826080e7          	jalr	-2010(ra) # 80000c98 <release>
                    release(&wait_lock);
    8000247a:	0000f517          	auipc	a0,0xf
    8000247e:	e5e50513          	addi	a0,a0,-418 # 800112d8 <wait_lock>
    80002482:	fffff097          	auipc	ra,0xfffff
    80002486:	816080e7          	jalr	-2026(ra) # 80000c98 <release>
                    return pid;
    8000248a:	a09d                	j	800024f0 <wait+0x100>
                        release(&np->lock);
    8000248c:	8526                	mv	a0,s1
    8000248e:	fffff097          	auipc	ra,0xfffff
    80002492:	80a080e7          	jalr	-2038(ra) # 80000c98 <release>
                        release(&wait_lock);
    80002496:	0000f517          	auipc	a0,0xf
    8000249a:	e4250513          	addi	a0,a0,-446 # 800112d8 <wait_lock>
    8000249e:	ffffe097          	auipc	ra,0xffffe
    800024a2:	7fa080e7          	jalr	2042(ra) # 80000c98 <release>
                        return -1;
    800024a6:	59fd                	li	s3,-1
    800024a8:	a0a1                	j	800024f0 <wait+0x100>
        for (np = proc; np < &proc[NPROC]; np++) {
    800024aa:	18848493          	addi	s1,s1,392
    800024ae:	03348463          	beq	s1,s3,800024d6 <wait+0xe6>
            if (np->parent == p) {
    800024b2:	7c9c                	ld	a5,56(s1)
    800024b4:	ff279be3          	bne	a5,s2,800024aa <wait+0xba>
                acquire(&np->lock);
    800024b8:	8526                	mv	a0,s1
    800024ba:	ffffe097          	auipc	ra,0xffffe
    800024be:	72a080e7          	jalr	1834(ra) # 80000be4 <acquire>
                if (np->state == ZOMBIE) {
    800024c2:	4c9c                	lw	a5,24(s1)
    800024c4:	f94781e3          	beq	a5,s4,80002446 <wait+0x56>
                release(&np->lock);
    800024c8:	8526                	mv	a0,s1
    800024ca:	ffffe097          	auipc	ra,0xffffe
    800024ce:	7ce080e7          	jalr	1998(ra) # 80000c98 <release>
                havekids = 1;
    800024d2:	8756                	mv	a4,s5
    800024d4:	bfd9                	j	800024aa <wait+0xba>
        if (!havekids || p->killed) {
    800024d6:	c701                	beqz	a4,800024de <wait+0xee>
    800024d8:	02892783          	lw	a5,40(s2)
    800024dc:	c79d                	beqz	a5,8000250a <wait+0x11a>
            release(&wait_lock);
    800024de:	0000f517          	auipc	a0,0xf
    800024e2:	dfa50513          	addi	a0,a0,-518 # 800112d8 <wait_lock>
    800024e6:	ffffe097          	auipc	ra,0xffffe
    800024ea:	7b2080e7          	jalr	1970(ra) # 80000c98 <release>
            return -1;
    800024ee:	59fd                	li	s3,-1
}
    800024f0:	854e                	mv	a0,s3
    800024f2:	60a6                	ld	ra,72(sp)
    800024f4:	6406                	ld	s0,64(sp)
    800024f6:	74e2                	ld	s1,56(sp)
    800024f8:	7942                	ld	s2,48(sp)
    800024fa:	79a2                	ld	s3,40(sp)
    800024fc:	7a02                	ld	s4,32(sp)
    800024fe:	6ae2                	ld	s5,24(sp)
    80002500:	6b42                	ld	s6,16(sp)
    80002502:	6ba2                	ld	s7,8(sp)
    80002504:	6c02                	ld	s8,0(sp)
    80002506:	6161                	addi	sp,sp,80
    80002508:	8082                	ret
        sleep(p, &wait_lock);  //DOC: wait-sleep
    8000250a:	85e2                	mv	a1,s8
    8000250c:	854a                	mv	a0,s2
    8000250e:	00000097          	auipc	ra,0x0
    80002512:	e6a080e7          	jalr	-406(ra) # 80002378 <sleep>
        havekids = 0;
    80002516:	b715                	j	8000243a <wait+0x4a>

0000000080002518 <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void
wakeup(void *chan) {
    80002518:	7139                	addi	sp,sp,-64
    8000251a:	fc06                	sd	ra,56(sp)
    8000251c:	f822                	sd	s0,48(sp)
    8000251e:	f426                	sd	s1,40(sp)
    80002520:	f04a                	sd	s2,32(sp)
    80002522:	ec4e                	sd	s3,24(sp)
    80002524:	e852                	sd	s4,16(sp)
    80002526:	e456                	sd	s5,8(sp)
    80002528:	e05a                	sd	s6,0(sp)
    8000252a:	0080                	addi	s0,sp,64
    8000252c:	8a2a                	mv	s4,a0
    struct proc *p;

    for (p = proc; p < &proc[NPROC]; p++) {
    8000252e:	0000f497          	auipc	s1,0xf
    80002532:	1c248493          	addi	s1,s1,450 # 800116f0 <proc>
        if (p != myproc()) {
            acquire(&p->lock);
            if (p->state == SLEEPING && p->chan == chan) {
    80002536:	4989                	li	s3,2
                p->state = RUNNABLE;
    80002538:	4b0d                	li	s6,3

//                acquire(&tickslock);
                p->sleeping_time = p->sleeping_time + ticks - p->last_time_changed;
    8000253a:	00007a97          	auipc	s5,0x7
    8000253e:	b16a8a93          	addi	s5,s5,-1258 # 80009050 <ticks>
    for (p = proc; p < &proc[NPROC]; p++) {
    80002542:	00015917          	auipc	s2,0x15
    80002546:	3ae90913          	addi	s2,s2,942 # 800178f0 <tickslock>
    8000254a:	a035                	j	80002576 <wakeup+0x5e>
                p->state = RUNNABLE;
    8000254c:	0164ac23          	sw	s6,24(s1)
                p->sleeping_time = p->sleeping_time + ticks - p->last_time_changed;
    80002550:	000aa783          	lw	a5,0(s5)
    80002554:	44f8                	lw	a4,76(s1)
    80002556:	9f3d                	addw	a4,a4,a5
    80002558:	4cb4                	lw	a3,88(s1)
    8000255a:	9f15                	subw	a4,a4,a3
    8000255c:	c4f8                	sw	a4,76(s1)
                p->last_runnable_time = ticks;     //added last_runnable time for fcfs
    8000255e:	2781                	sext.w	a5,a5
    80002560:	c4bc                	sw	a5,72(s1)
                p->last_time_changed = ticks;      //setting the starting ticks when getting to runnable for section 4
    80002562:	ccbc                	sw	a5,88(s1)
//                release(&tickslock);

            }
            release(&p->lock);
    80002564:	8526                	mv	a0,s1
    80002566:	ffffe097          	auipc	ra,0xffffe
    8000256a:	732080e7          	jalr	1842(ra) # 80000c98 <release>
    for (p = proc; p < &proc[NPROC]; p++) {
    8000256e:	18848493          	addi	s1,s1,392
    80002572:	03248463          	beq	s1,s2,8000259a <wakeup+0x82>
        if (p != myproc()) {
    80002576:	fffff097          	auipc	ra,0xfffff
    8000257a:	452080e7          	jalr	1106(ra) # 800019c8 <myproc>
    8000257e:	fea488e3          	beq	s1,a0,8000256e <wakeup+0x56>
            acquire(&p->lock);
    80002582:	8526                	mv	a0,s1
    80002584:	ffffe097          	auipc	ra,0xffffe
    80002588:	660080e7          	jalr	1632(ra) # 80000be4 <acquire>
            if (p->state == SLEEPING && p->chan == chan) {
    8000258c:	4c9c                	lw	a5,24(s1)
    8000258e:	fd379be3          	bne	a5,s3,80002564 <wakeup+0x4c>
    80002592:	709c                	ld	a5,32(s1)
    80002594:	fd4798e3          	bne	a5,s4,80002564 <wakeup+0x4c>
    80002598:	bf55                	j	8000254c <wakeup+0x34>
        }
    }
}
    8000259a:	70e2                	ld	ra,56(sp)
    8000259c:	7442                	ld	s0,48(sp)
    8000259e:	74a2                	ld	s1,40(sp)
    800025a0:	7902                	ld	s2,32(sp)
    800025a2:	69e2                	ld	s3,24(sp)
    800025a4:	6a42                	ld	s4,16(sp)
    800025a6:	6aa2                	ld	s5,8(sp)
    800025a8:	6b02                	ld	s6,0(sp)
    800025aa:	6121                	addi	sp,sp,64
    800025ac:	8082                	ret

00000000800025ae <reparent>:
reparent(struct proc *p) {
    800025ae:	7179                	addi	sp,sp,-48
    800025b0:	f406                	sd	ra,40(sp)
    800025b2:	f022                	sd	s0,32(sp)
    800025b4:	ec26                	sd	s1,24(sp)
    800025b6:	e84a                	sd	s2,16(sp)
    800025b8:	e44e                	sd	s3,8(sp)
    800025ba:	e052                	sd	s4,0(sp)
    800025bc:	1800                	addi	s0,sp,48
    800025be:	892a                	mv	s2,a0
    for (pp = proc; pp < &proc[NPROC]; pp++) {
    800025c0:	0000f497          	auipc	s1,0xf
    800025c4:	13048493          	addi	s1,s1,304 # 800116f0 <proc>
            pp->parent = initproc;
    800025c8:	00007a17          	auipc	s4,0x7
    800025cc:	a80a0a13          	addi	s4,s4,-1408 # 80009048 <initproc>
    for (pp = proc; pp < &proc[NPROC]; pp++) {
    800025d0:	00015997          	auipc	s3,0x15
    800025d4:	32098993          	addi	s3,s3,800 # 800178f0 <tickslock>
    800025d8:	a029                	j	800025e2 <reparent+0x34>
    800025da:	18848493          	addi	s1,s1,392
    800025de:	01348d63          	beq	s1,s3,800025f8 <reparent+0x4a>
        if (pp->parent == p) {
    800025e2:	7c9c                	ld	a5,56(s1)
    800025e4:	ff279be3          	bne	a5,s2,800025da <reparent+0x2c>
            pp->parent = initproc;
    800025e8:	000a3503          	ld	a0,0(s4)
    800025ec:	fc88                	sd	a0,56(s1)
            wakeup(initproc);
    800025ee:	00000097          	auipc	ra,0x0
    800025f2:	f2a080e7          	jalr	-214(ra) # 80002518 <wakeup>
    800025f6:	b7d5                	j	800025da <reparent+0x2c>
}
    800025f8:	70a2                	ld	ra,40(sp)
    800025fa:	7402                	ld	s0,32(sp)
    800025fc:	64e2                	ld	s1,24(sp)
    800025fe:	6942                	ld	s2,16(sp)
    80002600:	69a2                	ld	s3,8(sp)
    80002602:	6a02                	ld	s4,0(sp)
    80002604:	6145                	addi	sp,sp,48
    80002606:	8082                	ret

0000000080002608 <exit>:
exit(int status) {
    80002608:	7179                	addi	sp,sp,-48
    8000260a:	f406                	sd	ra,40(sp)
    8000260c:	f022                	sd	s0,32(sp)
    8000260e:	ec26                	sd	s1,24(sp)
    80002610:	e84a                	sd	s2,16(sp)
    80002612:	e44e                	sd	s3,8(sp)
    80002614:	e052                	sd	s4,0(sp)
    80002616:	1800                	addi	s0,sp,48
    80002618:	8a2a                	mv	s4,a0
    struct proc *p = myproc();
    8000261a:	fffff097          	auipc	ra,0xfffff
    8000261e:	3ae080e7          	jalr	942(ra) # 800019c8 <myproc>
    80002622:	892a                	mv	s2,a0
    if (p == initproc)
    80002624:	00007797          	auipc	a5,0x7
    80002628:	a247b783          	ld	a5,-1500(a5) # 80009048 <initproc>
    8000262c:	0f050493          	addi	s1,a0,240
    80002630:	17050993          	addi	s3,a0,368
    80002634:	02a79363          	bne	a5,a0,8000265a <exit+0x52>
        panic("init exiting");
    80002638:	00006517          	auipc	a0,0x6
    8000263c:	c3850513          	addi	a0,a0,-968 # 80008270 <digits+0x230>
    80002640:	ffffe097          	auipc	ra,0xffffe
    80002644:	efe080e7          	jalr	-258(ra) # 8000053e <panic>
            fileclose(f);
    80002648:	00002097          	auipc	ra,0x2
    8000264c:	300080e7          	jalr	768(ra) # 80004948 <fileclose>
            p->ofile[fd] = 0;
    80002650:	0004b023          	sd	zero,0(s1)
    for (int fd = 0; fd < NOFILE; fd++) {
    80002654:	04a1                	addi	s1,s1,8
    80002656:	01348563          	beq	s1,s3,80002660 <exit+0x58>
        if (p->ofile[fd]) {
    8000265a:	6088                	ld	a0,0(s1)
    8000265c:	f575                	bnez	a0,80002648 <exit+0x40>
    8000265e:	bfdd                	j	80002654 <exit+0x4c>
    begin_op();
    80002660:	00002097          	auipc	ra,0x2
    80002664:	e1c080e7          	jalr	-484(ra) # 8000447c <begin_op>
    iput(p->cwd);
    80002668:	17093503          	ld	a0,368(s2)
    8000266c:	00001097          	auipc	ra,0x1
    80002670:	5f8080e7          	jalr	1528(ra) # 80003c64 <iput>
    end_op();
    80002674:	00002097          	auipc	ra,0x2
    80002678:	e88080e7          	jalr	-376(ra) # 800044fc <end_op>
    p->cwd = 0;
    8000267c:	16093823          	sd	zero,368(s2)
    acquire(&wait_lock);
    80002680:	0000f497          	auipc	s1,0xf
    80002684:	c5848493          	addi	s1,s1,-936 # 800112d8 <wait_lock>
    80002688:	8526                	mv	a0,s1
    8000268a:	ffffe097          	auipc	ra,0xffffe
    8000268e:	55a080e7          	jalr	1370(ra) # 80000be4 <acquire>
    reparent(p);
    80002692:	854a                	mv	a0,s2
    80002694:	00000097          	auipc	ra,0x0
    80002698:	f1a080e7          	jalr	-230(ra) # 800025ae <reparent>
    wakeup(p->parent);
    8000269c:	03893503          	ld	a0,56(s2)
    800026a0:	00000097          	auipc	ra,0x0
    800026a4:	e78080e7          	jalr	-392(ra) # 80002518 <wakeup>
    acquire(&p->lock);
    800026a8:	854a                	mv	a0,s2
    800026aa:	ffffe097          	auipc	ra,0xffffe
    800026ae:	53a080e7          	jalr	1338(ra) # 80000be4 <acquire>
    p->running_time = p->running_time + ticks - p->last_time_changed;
    800026b2:	00007617          	auipc	a2,0x7
    800026b6:	99e62603          	lw	a2,-1634(a2) # 80009050 <ticks>
    800026ba:	05492703          	lw	a4,84(s2)
    800026be:	9f31                	addw	a4,a4,a2
    800026c0:	05892683          	lw	a3,88(s2)
    800026c4:	40d706bb          	subw	a3,a4,a3
    800026c8:	04d92a23          	sw	a3,84(s2)
    program_time = program_time + p->running_time;
    800026cc:	00007717          	auipc	a4,0x7
    800026d0:	96470713          	addi	a4,a4,-1692 # 80009030 <program_time>
    800026d4:	431c                	lw	a5,0(a4)
    800026d6:	9fb5                	addw	a5,a5,a3
    800026d8:	c31c                	sw	a5,0(a4)
    cpu_utilization = program_time / (ticks - start_time);
    800026da:	00007717          	auipc	a4,0x7
    800026de:	94e72703          	lw	a4,-1714(a4) # 80009028 <start_time>
    800026e2:	9e19                	subw	a2,a2,a4
    800026e4:	02c7d7bb          	divuw	a5,a5,a2
    800026e8:	00007717          	auipc	a4,0x7
    800026ec:	94f72223          	sw	a5,-1724(a4) # 8000902c <cpu_utilization>
    sleeping_processes_mean = (sleeping_processes_mean * (nextpid - 1) + p->sleeping_time) / (nextpid);
    800026f0:	00006617          	auipc	a2,0x6
    800026f4:	14462603          	lw	a2,324(a2) # 80008834 <nextpid>
    800026f8:	fff6059b          	addiw	a1,a2,-1
    800026fc:	00007797          	auipc	a5,0x7
    80002700:	94078793          	addi	a5,a5,-1728 # 8000903c <sleeping_processes_mean>
    80002704:	4398                	lw	a4,0(a5)
    80002706:	02b7073b          	mulw	a4,a4,a1
    8000270a:	04c92503          	lw	a0,76(s2)
    8000270e:	9f29                	addw	a4,a4,a0
    80002710:	02c7473b          	divw	a4,a4,a2
    80002714:	c398                	sw	a4,0(a5)
    running_processes_mean = (running_processes_mean * (nextpid - 1) + p->running_time) / (nextpid);
    80002716:	00007797          	auipc	a5,0x7
    8000271a:	92278793          	addi	a5,a5,-1758 # 80009038 <running_processes_mean>
    8000271e:	4398                	lw	a4,0(a5)
    80002720:	02b7073b          	mulw	a4,a4,a1
    80002724:	9f35                	addw	a4,a4,a3
    80002726:	02c7473b          	divw	a4,a4,a2
    8000272a:	c398                	sw	a4,0(a5)
    runnable_processes_mean = (runnable_processes_mean * (nextpid - 1) + p->runnable_time) / (nextpid);
    8000272c:	00007717          	auipc	a4,0x7
    80002730:	90870713          	addi	a4,a4,-1784 # 80009034 <runnable_processes_mean>
    80002734:	431c                	lw	a5,0(a4)
    80002736:	02b787bb          	mulw	a5,a5,a1
    8000273a:	05092683          	lw	a3,80(s2)
    8000273e:	9fb5                	addw	a5,a5,a3
    80002740:	02c7c7bb          	divw	a5,a5,a2
    80002744:	c31c                	sw	a5,0(a4)
    p->xstate = status;
    80002746:	03492623          	sw	s4,44(s2)
    p->state = ZOMBIE;
    8000274a:	4795                	li	a5,5
    8000274c:	00f92c23          	sw	a5,24(s2)
    release(&wait_lock);
    80002750:	8526                	mv	a0,s1
    80002752:	ffffe097          	auipc	ra,0xffffe
    80002756:	546080e7          	jalr	1350(ra) # 80000c98 <release>
    sched();
    8000275a:	00000097          	auipc	ra,0x0
    8000275e:	af4080e7          	jalr	-1292(ra) # 8000224e <sched>
    panic("zombie exit");
    80002762:	00006517          	auipc	a0,0x6
    80002766:	b1e50513          	addi	a0,a0,-1250 # 80008280 <digits+0x240>
    8000276a:	ffffe097          	auipc	ra,0xffffe
    8000276e:	dd4080e7          	jalr	-556(ra) # 8000053e <panic>

0000000080002772 <kill>:

// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid) {
    80002772:	7179                	addi	sp,sp,-48
    80002774:	f406                	sd	ra,40(sp)
    80002776:	f022                	sd	s0,32(sp)
    80002778:	ec26                	sd	s1,24(sp)
    8000277a:	e84a                	sd	s2,16(sp)
    8000277c:	e44e                	sd	s3,8(sp)
    8000277e:	1800                	addi	s0,sp,48
    80002780:	892a                	mv	s2,a0
    struct proc *p;

    for (p = proc; p < &proc[NPROC]; p++) {
    80002782:	0000f497          	auipc	s1,0xf
    80002786:	f6e48493          	addi	s1,s1,-146 # 800116f0 <proc>
    8000278a:	00015997          	auipc	s3,0x15
    8000278e:	16698993          	addi	s3,s3,358 # 800178f0 <tickslock>
        acquire(&p->lock);
    80002792:	8526                	mv	a0,s1
    80002794:	ffffe097          	auipc	ra,0xffffe
    80002798:	450080e7          	jalr	1104(ra) # 80000be4 <acquire>
        if (p->pid == pid) {
    8000279c:	589c                	lw	a5,48(s1)
    8000279e:	01278d63          	beq	a5,s2,800027b8 <kill+0x46>
//                release(&tickslock);
            }
            release(&p->lock);
            return 0;
        }
        release(&p->lock);
    800027a2:	8526                	mv	a0,s1
    800027a4:	ffffe097          	auipc	ra,0xffffe
    800027a8:	4f4080e7          	jalr	1268(ra) # 80000c98 <release>
    for (p = proc; p < &proc[NPROC]; p++) {
    800027ac:	18848493          	addi	s1,s1,392
    800027b0:	ff3491e3          	bne	s1,s3,80002792 <kill+0x20>
    }
    return -1;
    800027b4:	557d                	li	a0,-1
    800027b6:	a829                	j	800027d0 <kill+0x5e>
            p->killed = 1;
    800027b8:	4785                	li	a5,1
    800027ba:	d49c                	sw	a5,40(s1)
            if (p->state == SLEEPING) {
    800027bc:	4c98                	lw	a4,24(s1)
    800027be:	4789                	li	a5,2
    800027c0:	00f70f63          	beq	a4,a5,800027de <kill+0x6c>
            release(&p->lock);
    800027c4:	8526                	mv	a0,s1
    800027c6:	ffffe097          	auipc	ra,0xffffe
    800027ca:	4d2080e7          	jalr	1234(ra) # 80000c98 <release>
            return 0;
    800027ce:	4501                	li	a0,0
}
    800027d0:	70a2                	ld	ra,40(sp)
    800027d2:	7402                	ld	s0,32(sp)
    800027d4:	64e2                	ld	s1,24(sp)
    800027d6:	6942                	ld	s2,16(sp)
    800027d8:	69a2                	ld	s3,8(sp)
    800027da:	6145                	addi	sp,sp,48
    800027dc:	8082                	ret
                p->state = RUNNABLE;
    800027de:	478d                	li	a5,3
    800027e0:	cc9c                	sw	a5,24(s1)
                p->sleeping_time = p->sleeping_time + ticks - p->last_time_changed;
    800027e2:	00007797          	auipc	a5,0x7
    800027e6:	86e7a783          	lw	a5,-1938(a5) # 80009050 <ticks>
    800027ea:	44f8                	lw	a4,76(s1)
    800027ec:	9f3d                	addw	a4,a4,a5
    800027ee:	4cb4                	lw	a3,88(s1)
    800027f0:	9f15                	subw	a4,a4,a3
    800027f2:	c4f8                	sw	a4,76(s1)
                p->last_runnable_time = ticks;     //added last_runnable time for fcfs
    800027f4:	2781                	sext.w	a5,a5
    800027f6:	c4bc                	sw	a5,72(s1)
                p->last_time_changed = ticks;      //setting the starting ticks when getting to runnable for section 4
    800027f8:	ccbc                	sw	a5,88(s1)
    800027fa:	b7e9                	j	800027c4 <kill+0x52>

00000000800027fc <kill_system>:

int kill_system(void) {
    800027fc:	7179                	addi	sp,sp,-48
    800027fe:	f406                	sd	ra,40(sp)
    80002800:	f022                	sd	s0,32(sp)
    80002802:	ec26                	sd	s1,24(sp)
    80002804:	e84a                	sd	s2,16(sp)
    80002806:	e44e                	sd	s3,8(sp)
    80002808:	1800                	addi	s0,sp,48
    // init pid = 1
    // shell pid = 2
    struct proc *p;
    int i = 0;
    for (p = proc; p < &proc[NPROC]; p++, i++) {
    8000280a:	0000f497          	auipc	s1,0xf
    8000280e:	ee648493          	addi	s1,s1,-282 # 800116f0 <proc>
        acquire(&p->lock);
        if (p->pid != 1 && p->pid != 2) {
    80002812:	4985                	li	s3,1
    for (p = proc; p < &proc[NPROC]; p++, i++) {
    80002814:	00015917          	auipc	s2,0x15
    80002818:	0dc90913          	addi	s2,s2,220 # 800178f0 <tickslock>
    8000281c:	a811                	j	80002830 <kill_system+0x34>
            release(&p->lock);
            kill(p->pid);
        } else {
            release(&p->lock);
    8000281e:	8526                	mv	a0,s1
    80002820:	ffffe097          	auipc	ra,0xffffe
    80002824:	478080e7          	jalr	1144(ra) # 80000c98 <release>
    for (p = proc; p < &proc[NPROC]; p++, i++) {
    80002828:	18848493          	addi	s1,s1,392
    8000282c:	03248663          	beq	s1,s2,80002858 <kill_system+0x5c>
        acquire(&p->lock);
    80002830:	8526                	mv	a0,s1
    80002832:	ffffe097          	auipc	ra,0xffffe
    80002836:	3b2080e7          	jalr	946(ra) # 80000be4 <acquire>
        if (p->pid != 1 && p->pid != 2) {
    8000283a:	589c                	lw	a5,48(s1)
    8000283c:	37fd                	addiw	a5,a5,-1
    8000283e:	fef9f0e3          	bgeu	s3,a5,8000281e <kill_system+0x22>
            release(&p->lock);
    80002842:	8526                	mv	a0,s1
    80002844:	ffffe097          	auipc	ra,0xffffe
    80002848:	454080e7          	jalr	1108(ra) # 80000c98 <release>
            kill(p->pid);
    8000284c:	5888                	lw	a0,48(s1)
    8000284e:	00000097          	auipc	ra,0x0
    80002852:	f24080e7          	jalr	-220(ra) # 80002772 <kill>
    80002856:	bfc9                	j	80002828 <kill_system+0x2c>
        }
    }

    return 0;
    //todo check if need to verify kill returned 0, in case not what should we do.
}
    80002858:	4501                	li	a0,0
    8000285a:	70a2                	ld	ra,40(sp)
    8000285c:	7402                	ld	s0,32(sp)
    8000285e:	64e2                	ld	s1,24(sp)
    80002860:	6942                	ld	s2,16(sp)
    80002862:	69a2                	ld	s3,8(sp)
    80002864:	6145                	addi	sp,sp,48
    80002866:	8082                	ret

0000000080002868 <pause_system>:

//pause all user processes for the number of seconds specified by the parameter
int pause_system(int seconds) {
    80002868:	1141                	addi	sp,sp,-16
    8000286a:	e406                	sd	ra,8(sp)
    8000286c:	e022                	sd	s0,0(sp)
    8000286e:	0800                	addi	s0,sp,16
    pauseTicks = ticks + seconds * 10; //todo check if can get 1000000 as number
    80002870:	0025179b          	slliw	a5,a0,0x2
    80002874:	9fa9                	addw	a5,a5,a0
    80002876:	0017979b          	slliw	a5,a5,0x1
    8000287a:	00006517          	auipc	a0,0x6
    8000287e:	7d652503          	lw	a0,2006(a0) # 80009050 <ticks>
    80002882:	9fa9                	addw	a5,a5,a0
    80002884:	00006717          	auipc	a4,0x6
    80002888:	7af72e23          	sw	a5,1980(a4) # 80009040 <pauseTicks>
    yield();
    8000288c:	00000097          	auipc	ra,0x0
    80002890:	a98080e7          	jalr	-1384(ra) # 80002324 <yield>
    return 0;
}
    80002894:	4501                	li	a0,0
    80002896:	60a2                	ld	ra,8(sp)
    80002898:	6402                	ld	s0,0(sp)
    8000289a:	0141                	addi	sp,sp,16
    8000289c:	8082                	ret

000000008000289e <either_copyout>:

// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len) {
    8000289e:	7179                	addi	sp,sp,-48
    800028a0:	f406                	sd	ra,40(sp)
    800028a2:	f022                	sd	s0,32(sp)
    800028a4:	ec26                	sd	s1,24(sp)
    800028a6:	e84a                	sd	s2,16(sp)
    800028a8:	e44e                	sd	s3,8(sp)
    800028aa:	e052                	sd	s4,0(sp)
    800028ac:	1800                	addi	s0,sp,48
    800028ae:	84aa                	mv	s1,a0
    800028b0:	892e                	mv	s2,a1
    800028b2:	89b2                	mv	s3,a2
    800028b4:	8a36                	mv	s4,a3
    struct proc *p = myproc();
    800028b6:	fffff097          	auipc	ra,0xfffff
    800028ba:	112080e7          	jalr	274(ra) # 800019c8 <myproc>
    if (user_dst) {
    800028be:	c08d                	beqz	s1,800028e0 <either_copyout+0x42>
        return copyout(p->pagetable, dst, src, len);
    800028c0:	86d2                	mv	a3,s4
    800028c2:	864e                	mv	a2,s3
    800028c4:	85ca                	mv	a1,s2
    800028c6:	7928                	ld	a0,112(a0)
    800028c8:	fffff097          	auipc	ra,0xfffff
    800028cc:	db2080e7          	jalr	-590(ra) # 8000167a <copyout>
    } else {
        memmove((char *) dst, src, len);
        return 0;
    }
}
    800028d0:	70a2                	ld	ra,40(sp)
    800028d2:	7402                	ld	s0,32(sp)
    800028d4:	64e2                	ld	s1,24(sp)
    800028d6:	6942                	ld	s2,16(sp)
    800028d8:	69a2                	ld	s3,8(sp)
    800028da:	6a02                	ld	s4,0(sp)
    800028dc:	6145                	addi	sp,sp,48
    800028de:	8082                	ret
        memmove((char *) dst, src, len);
    800028e0:	000a061b          	sext.w	a2,s4
    800028e4:	85ce                	mv	a1,s3
    800028e6:	854a                	mv	a0,s2
    800028e8:	ffffe097          	auipc	ra,0xffffe
    800028ec:	458080e7          	jalr	1112(ra) # 80000d40 <memmove>
        return 0;
    800028f0:	8526                	mv	a0,s1
    800028f2:	bff9                	j	800028d0 <either_copyout+0x32>

00000000800028f4 <either_copyin>:

// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len) {
    800028f4:	7179                	addi	sp,sp,-48
    800028f6:	f406                	sd	ra,40(sp)
    800028f8:	f022                	sd	s0,32(sp)
    800028fa:	ec26                	sd	s1,24(sp)
    800028fc:	e84a                	sd	s2,16(sp)
    800028fe:	e44e                	sd	s3,8(sp)
    80002900:	e052                	sd	s4,0(sp)
    80002902:	1800                	addi	s0,sp,48
    80002904:	892a                	mv	s2,a0
    80002906:	84ae                	mv	s1,a1
    80002908:	89b2                	mv	s3,a2
    8000290a:	8a36                	mv	s4,a3
    struct proc *p = myproc();
    8000290c:	fffff097          	auipc	ra,0xfffff
    80002910:	0bc080e7          	jalr	188(ra) # 800019c8 <myproc>
    if (user_src) {
    80002914:	c08d                	beqz	s1,80002936 <either_copyin+0x42>
        return copyin(p->pagetable, dst, src, len);
    80002916:	86d2                	mv	a3,s4
    80002918:	864e                	mv	a2,s3
    8000291a:	85ca                	mv	a1,s2
    8000291c:	7928                	ld	a0,112(a0)
    8000291e:	fffff097          	auipc	ra,0xfffff
    80002922:	de8080e7          	jalr	-536(ra) # 80001706 <copyin>
    } else {
        memmove(dst, (char *) src, len);
        return 0;
    }
}
    80002926:	70a2                	ld	ra,40(sp)
    80002928:	7402                	ld	s0,32(sp)
    8000292a:	64e2                	ld	s1,24(sp)
    8000292c:	6942                	ld	s2,16(sp)
    8000292e:	69a2                	ld	s3,8(sp)
    80002930:	6a02                	ld	s4,0(sp)
    80002932:	6145                	addi	sp,sp,48
    80002934:	8082                	ret
        memmove(dst, (char *) src, len);
    80002936:	000a061b          	sext.w	a2,s4
    8000293a:	85ce                	mv	a1,s3
    8000293c:	854a                	mv	a0,s2
    8000293e:	ffffe097          	auipc	ra,0xffffe
    80002942:	402080e7          	jalr	1026(ra) # 80000d40 <memmove>
        return 0;
    80002946:	8526                	mv	a0,s1
    80002948:	bff9                	j	80002926 <either_copyin+0x32>

000000008000294a <procdump>:

// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void) {
    8000294a:	715d                	addi	sp,sp,-80
    8000294c:	e486                	sd	ra,72(sp)
    8000294e:	e0a2                	sd	s0,64(sp)
    80002950:	fc26                	sd	s1,56(sp)
    80002952:	f84a                	sd	s2,48(sp)
    80002954:	f44e                	sd	s3,40(sp)
    80002956:	f052                	sd	s4,32(sp)
    80002958:	ec56                	sd	s5,24(sp)
    8000295a:	e85a                	sd	s6,16(sp)
    8000295c:	e45e                	sd	s7,8(sp)
    8000295e:	0880                	addi	s0,sp,80
            [ZOMBIE]    "zombie"
    };
    struct proc *p;
    char *state;

    printf("\n");
    80002960:	00005517          	auipc	a0,0x5
    80002964:	76850513          	addi	a0,a0,1896 # 800080c8 <digits+0x88>
    80002968:	ffffe097          	auipc	ra,0xffffe
    8000296c:	c20080e7          	jalr	-992(ra) # 80000588 <printf>
    for (p = proc; p < &proc[NPROC]; p++) {
    80002970:	0000f497          	auipc	s1,0xf
    80002974:	ef848493          	addi	s1,s1,-264 # 80011868 <proc+0x178>
    80002978:	00015917          	auipc	s2,0x15
    8000297c:	0f090913          	addi	s2,s2,240 # 80017a68 <bcache+0x160>
        if (p->state == UNUSED)
            continue;
        if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002980:	4b15                	li	s6,5
            state = states[p->state];
        else
            state = "???";
    80002982:	00006997          	auipc	s3,0x6
    80002986:	90e98993          	addi	s3,s3,-1778 # 80008290 <digits+0x250>
        printf("%d %s %s", p->pid, state, p->name);
    8000298a:	00006a97          	auipc	s5,0x6
    8000298e:	90ea8a93          	addi	s5,s5,-1778 # 80008298 <digits+0x258>
        printf("\n");
    80002992:	00005a17          	auipc	s4,0x5
    80002996:	736a0a13          	addi	s4,s4,1846 # 800080c8 <digits+0x88>
        if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000299a:	00006b97          	auipc	s7,0x6
    8000299e:	936b8b93          	addi	s7,s7,-1738 # 800082d0 <states.1771>
    800029a2:	a00d                	j	800029c4 <procdump+0x7a>
        printf("%d %s %s", p->pid, state, p->name);
    800029a4:	eb86a583          	lw	a1,-328(a3)
    800029a8:	8556                	mv	a0,s5
    800029aa:	ffffe097          	auipc	ra,0xffffe
    800029ae:	bde080e7          	jalr	-1058(ra) # 80000588 <printf>
        printf("\n");
    800029b2:	8552                	mv	a0,s4
    800029b4:	ffffe097          	auipc	ra,0xffffe
    800029b8:	bd4080e7          	jalr	-1068(ra) # 80000588 <printf>
    for (p = proc; p < &proc[NPROC]; p++) {
    800029bc:	18848493          	addi	s1,s1,392
    800029c0:	03248163          	beq	s1,s2,800029e2 <procdump+0x98>
        if (p->state == UNUSED)
    800029c4:	86a6                	mv	a3,s1
    800029c6:	ea04a783          	lw	a5,-352(s1)
    800029ca:	dbed                	beqz	a5,800029bc <procdump+0x72>
            state = "???";
    800029cc:	864e                	mv	a2,s3
        if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800029ce:	fcfb6be3          	bltu	s6,a5,800029a4 <procdump+0x5a>
    800029d2:	1782                	slli	a5,a5,0x20
    800029d4:	9381                	srli	a5,a5,0x20
    800029d6:	078e                	slli	a5,a5,0x3
    800029d8:	97de                	add	a5,a5,s7
    800029da:	6390                	ld	a2,0(a5)
    800029dc:	f661                	bnez	a2,800029a4 <procdump+0x5a>
            state = "???";
    800029de:	864e                	mv	a2,s3
    800029e0:	b7d1                	j	800029a4 <procdump+0x5a>
    }
    800029e2:	60a6                	ld	ra,72(sp)
    800029e4:	6406                	ld	s0,64(sp)
    800029e6:	74e2                	ld	s1,56(sp)
    800029e8:	7942                	ld	s2,48(sp)
    800029ea:	79a2                	ld	s3,40(sp)
    800029ec:	7a02                	ld	s4,32(sp)
    800029ee:	6ae2                	ld	s5,24(sp)
    800029f0:	6b42                	ld	s6,16(sp)
    800029f2:	6ba2                	ld	s7,8(sp)
    800029f4:	6161                	addi	sp,sp,80
    800029f6:	8082                	ret

00000000800029f8 <swtch>:
    800029f8:	00153023          	sd	ra,0(a0)
    800029fc:	00253423          	sd	sp,8(a0)
    80002a00:	e900                	sd	s0,16(a0)
    80002a02:	ed04                	sd	s1,24(a0)
    80002a04:	03253023          	sd	s2,32(a0)
    80002a08:	03353423          	sd	s3,40(a0)
    80002a0c:	03453823          	sd	s4,48(a0)
    80002a10:	03553c23          	sd	s5,56(a0)
    80002a14:	05653023          	sd	s6,64(a0)
    80002a18:	05753423          	sd	s7,72(a0)
    80002a1c:	05853823          	sd	s8,80(a0)
    80002a20:	05953c23          	sd	s9,88(a0)
    80002a24:	07a53023          	sd	s10,96(a0)
    80002a28:	07b53423          	sd	s11,104(a0)
    80002a2c:	0005b083          	ld	ra,0(a1)
    80002a30:	0085b103          	ld	sp,8(a1)
    80002a34:	6980                	ld	s0,16(a1)
    80002a36:	6d84                	ld	s1,24(a1)
    80002a38:	0205b903          	ld	s2,32(a1)
    80002a3c:	0285b983          	ld	s3,40(a1)
    80002a40:	0305ba03          	ld	s4,48(a1)
    80002a44:	0385ba83          	ld	s5,56(a1)
    80002a48:	0405bb03          	ld	s6,64(a1)
    80002a4c:	0485bb83          	ld	s7,72(a1)
    80002a50:	0505bc03          	ld	s8,80(a1)
    80002a54:	0585bc83          	ld	s9,88(a1)
    80002a58:	0605bd03          	ld	s10,96(a1)
    80002a5c:	0685bd83          	ld	s11,104(a1)
    80002a60:	8082                	ret

0000000080002a62 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    80002a62:	1141                	addi	sp,sp,-16
    80002a64:	e406                	sd	ra,8(sp)
    80002a66:	e022                	sd	s0,0(sp)
    80002a68:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002a6a:	00006597          	auipc	a1,0x6
    80002a6e:	89658593          	addi	a1,a1,-1898 # 80008300 <states.1771+0x30>
    80002a72:	00015517          	auipc	a0,0x15
    80002a76:	e7e50513          	addi	a0,a0,-386 # 800178f0 <tickslock>
    80002a7a:	ffffe097          	auipc	ra,0xffffe
    80002a7e:	0da080e7          	jalr	218(ra) # 80000b54 <initlock>
}
    80002a82:	60a2                	ld	ra,8(sp)
    80002a84:	6402                	ld	s0,0(sp)
    80002a86:	0141                	addi	sp,sp,16
    80002a88:	8082                	ret

0000000080002a8a <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    80002a8a:	1141                	addi	sp,sp,-16
    80002a8c:	e422                	sd	s0,8(sp)
    80002a8e:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002a90:	00003797          	auipc	a5,0x3
    80002a94:	4d078793          	addi	a5,a5,1232 # 80005f60 <kernelvec>
    80002a98:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002a9c:	6422                	ld	s0,8(sp)
    80002a9e:	0141                	addi	sp,sp,16
    80002aa0:	8082                	ret

0000000080002aa2 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002aa2:	1141                	addi	sp,sp,-16
    80002aa4:	e406                	sd	ra,8(sp)
    80002aa6:	e022                	sd	s0,0(sp)
    80002aa8:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002aaa:	fffff097          	auipc	ra,0xfffff
    80002aae:	f1e080e7          	jalr	-226(ra) # 800019c8 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002ab2:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002ab6:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002ab8:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    80002abc:	00004617          	auipc	a2,0x4
    80002ac0:	54460613          	addi	a2,a2,1348 # 80007000 <_trampoline>
    80002ac4:	00004697          	auipc	a3,0x4
    80002ac8:	53c68693          	addi	a3,a3,1340 # 80007000 <_trampoline>
    80002acc:	8e91                	sub	a3,a3,a2
    80002ace:	040007b7          	lui	a5,0x4000
    80002ad2:	17fd                	addi	a5,a5,-1
    80002ad4:	07b2                	slli	a5,a5,0xc
    80002ad6:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002ad8:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002adc:	7d38                	ld	a4,120(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002ade:	180026f3          	csrr	a3,satp
    80002ae2:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002ae4:	7d38                	ld	a4,120(a0)
    80002ae6:	7134                	ld	a3,96(a0)
    80002ae8:	6585                	lui	a1,0x1
    80002aea:	96ae                	add	a3,a3,a1
    80002aec:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002aee:	7d38                	ld	a4,120(a0)
    80002af0:	00000697          	auipc	a3,0x0
    80002af4:	13868693          	addi	a3,a3,312 # 80002c28 <usertrap>
    80002af8:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80002afa:	7d38                	ld	a4,120(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002afc:	8692                	mv	a3,tp
    80002afe:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002b00:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002b04:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002b08:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002b0c:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002b10:	7d38                	ld	a4,120(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002b12:	6f18                	ld	a4,24(a4)
    80002b14:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002b18:	792c                	ld	a1,112(a0)
    80002b1a:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    80002b1c:	00004717          	auipc	a4,0x4
    80002b20:	57470713          	addi	a4,a4,1396 # 80007090 <userret>
    80002b24:	8f11                	sub	a4,a4,a2
    80002b26:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    80002b28:	577d                	li	a4,-1
    80002b2a:	177e                	slli	a4,a4,0x3f
    80002b2c:	8dd9                	or	a1,a1,a4
    80002b2e:	02000537          	lui	a0,0x2000
    80002b32:	157d                	addi	a0,a0,-1
    80002b34:	0536                	slli	a0,a0,0xd
    80002b36:	9782                	jalr	a5
}
    80002b38:	60a2                	ld	ra,8(sp)
    80002b3a:	6402                	ld	s0,0(sp)
    80002b3c:	0141                	addi	sp,sp,16
    80002b3e:	8082                	ret

0000000080002b40 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80002b40:	1101                	addi	sp,sp,-32
    80002b42:	ec06                	sd	ra,24(sp)
    80002b44:	e822                	sd	s0,16(sp)
    80002b46:	e426                	sd	s1,8(sp)
    80002b48:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002b4a:	00015497          	auipc	s1,0x15
    80002b4e:	da648493          	addi	s1,s1,-602 # 800178f0 <tickslock>
    80002b52:	8526                	mv	a0,s1
    80002b54:	ffffe097          	auipc	ra,0xffffe
    80002b58:	090080e7          	jalr	144(ra) # 80000be4 <acquire>
  ticks++;
    80002b5c:	00006517          	auipc	a0,0x6
    80002b60:	4f450513          	addi	a0,a0,1268 # 80009050 <ticks>
    80002b64:	411c                	lw	a5,0(a0)
    80002b66:	2785                	addiw	a5,a5,1
    80002b68:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80002b6a:	00000097          	auipc	ra,0x0
    80002b6e:	9ae080e7          	jalr	-1618(ra) # 80002518 <wakeup>
  release(&tickslock);
    80002b72:	8526                	mv	a0,s1
    80002b74:	ffffe097          	auipc	ra,0xffffe
    80002b78:	124080e7          	jalr	292(ra) # 80000c98 <release>
}
    80002b7c:	60e2                	ld	ra,24(sp)
    80002b7e:	6442                	ld	s0,16(sp)
    80002b80:	64a2                	ld	s1,8(sp)
    80002b82:	6105                	addi	sp,sp,32
    80002b84:	8082                	ret

0000000080002b86 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80002b86:	1101                	addi	sp,sp,-32
    80002b88:	ec06                	sd	ra,24(sp)
    80002b8a:	e822                	sd	s0,16(sp)
    80002b8c:	e426                	sd	s1,8(sp)
    80002b8e:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002b90:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80002b94:	00074d63          	bltz	a4,80002bae <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80002b98:	57fd                	li	a5,-1
    80002b9a:	17fe                	slli	a5,a5,0x3f
    80002b9c:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002b9e:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002ba0:	06f70363          	beq	a4,a5,80002c06 <devintr+0x80>
  }
}
    80002ba4:	60e2                	ld	ra,24(sp)
    80002ba6:	6442                	ld	s0,16(sp)
    80002ba8:	64a2                	ld	s1,8(sp)
    80002baa:	6105                	addi	sp,sp,32
    80002bac:	8082                	ret
     (scause & 0xff) == 9){
    80002bae:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    80002bb2:	46a5                	li	a3,9
    80002bb4:	fed792e3          	bne	a5,a3,80002b98 <devintr+0x12>
    int irq = plic_claim();
    80002bb8:	00003097          	auipc	ra,0x3
    80002bbc:	4b0080e7          	jalr	1200(ra) # 80006068 <plic_claim>
    80002bc0:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002bc2:	47a9                	li	a5,10
    80002bc4:	02f50763          	beq	a0,a5,80002bf2 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80002bc8:	4785                	li	a5,1
    80002bca:	02f50963          	beq	a0,a5,80002bfc <devintr+0x76>
    return 1;
    80002bce:	4505                	li	a0,1
    } else if(irq){
    80002bd0:	d8f1                	beqz	s1,80002ba4 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002bd2:	85a6                	mv	a1,s1
    80002bd4:	00005517          	auipc	a0,0x5
    80002bd8:	73450513          	addi	a0,a0,1844 # 80008308 <states.1771+0x38>
    80002bdc:	ffffe097          	auipc	ra,0xffffe
    80002be0:	9ac080e7          	jalr	-1620(ra) # 80000588 <printf>
      plic_complete(irq);
    80002be4:	8526                	mv	a0,s1
    80002be6:	00003097          	auipc	ra,0x3
    80002bea:	4a6080e7          	jalr	1190(ra) # 8000608c <plic_complete>
    return 1;
    80002bee:	4505                	li	a0,1
    80002bf0:	bf55                	j	80002ba4 <devintr+0x1e>
      uartintr();
    80002bf2:	ffffe097          	auipc	ra,0xffffe
    80002bf6:	db6080e7          	jalr	-586(ra) # 800009a8 <uartintr>
    80002bfa:	b7ed                	j	80002be4 <devintr+0x5e>
      virtio_disk_intr();
    80002bfc:	00004097          	auipc	ra,0x4
    80002c00:	970080e7          	jalr	-1680(ra) # 8000656c <virtio_disk_intr>
    80002c04:	b7c5                	j	80002be4 <devintr+0x5e>
    if(cpuid() == 0){
    80002c06:	fffff097          	auipc	ra,0xfffff
    80002c0a:	d96080e7          	jalr	-618(ra) # 8000199c <cpuid>
    80002c0e:	c901                	beqz	a0,80002c1e <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002c10:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002c14:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002c16:	14479073          	csrw	sip,a5
    return 2;
    80002c1a:	4509                	li	a0,2
    80002c1c:	b761                	j	80002ba4 <devintr+0x1e>
      clockintr();
    80002c1e:	00000097          	auipc	ra,0x0
    80002c22:	f22080e7          	jalr	-222(ra) # 80002b40 <clockintr>
    80002c26:	b7ed                	j	80002c10 <devintr+0x8a>

0000000080002c28 <usertrap>:
{
    80002c28:	1101                	addi	sp,sp,-32
    80002c2a:	ec06                	sd	ra,24(sp)
    80002c2c:	e822                	sd	s0,16(sp)
    80002c2e:	e426                	sd	s1,8(sp)
    80002c30:	e04a                	sd	s2,0(sp)
    80002c32:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002c34:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002c38:	1007f793          	andi	a5,a5,256
    80002c3c:	e3ad                	bnez	a5,80002c9e <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002c3e:	00003797          	auipc	a5,0x3
    80002c42:	32278793          	addi	a5,a5,802 # 80005f60 <kernelvec>
    80002c46:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002c4a:	fffff097          	auipc	ra,0xfffff
    80002c4e:	d7e080e7          	jalr	-642(ra) # 800019c8 <myproc>
    80002c52:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002c54:	7d3c                	ld	a5,120(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002c56:	14102773          	csrr	a4,sepc
    80002c5a:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002c5c:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002c60:	47a1                	li	a5,8
    80002c62:	04f71c63          	bne	a4,a5,80002cba <usertrap+0x92>
    if(p->killed)
    80002c66:	551c                	lw	a5,40(a0)
    80002c68:	e3b9                	bnez	a5,80002cae <usertrap+0x86>
    p->trapframe->epc += 4;
    80002c6a:	7cb8                	ld	a4,120(s1)
    80002c6c:	6f1c                	ld	a5,24(a4)
    80002c6e:	0791                	addi	a5,a5,4
    80002c70:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002c72:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002c76:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002c7a:	10079073          	csrw	sstatus,a5
    syscall();
    80002c7e:	00000097          	auipc	ra,0x0
    80002c82:	2e0080e7          	jalr	736(ra) # 80002f5e <syscall>
  if(p->killed)
    80002c86:	549c                	lw	a5,40(s1)
    80002c88:	ebc1                	bnez	a5,80002d18 <usertrap+0xf0>
  usertrapret();
    80002c8a:	00000097          	auipc	ra,0x0
    80002c8e:	e18080e7          	jalr	-488(ra) # 80002aa2 <usertrapret>
}
    80002c92:	60e2                	ld	ra,24(sp)
    80002c94:	6442                	ld	s0,16(sp)
    80002c96:	64a2                	ld	s1,8(sp)
    80002c98:	6902                	ld	s2,0(sp)
    80002c9a:	6105                	addi	sp,sp,32
    80002c9c:	8082                	ret
    panic("usertrap: not from user mode");
    80002c9e:	00005517          	auipc	a0,0x5
    80002ca2:	68a50513          	addi	a0,a0,1674 # 80008328 <states.1771+0x58>
    80002ca6:	ffffe097          	auipc	ra,0xffffe
    80002caa:	898080e7          	jalr	-1896(ra) # 8000053e <panic>
      exit(-1);
    80002cae:	557d                	li	a0,-1
    80002cb0:	00000097          	auipc	ra,0x0
    80002cb4:	958080e7          	jalr	-1704(ra) # 80002608 <exit>
    80002cb8:	bf4d                	j	80002c6a <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    80002cba:	00000097          	auipc	ra,0x0
    80002cbe:	ecc080e7          	jalr	-308(ra) # 80002b86 <devintr>
    80002cc2:	892a                	mv	s2,a0
    80002cc4:	c501                	beqz	a0,80002ccc <usertrap+0xa4>
  if(p->killed)
    80002cc6:	549c                	lw	a5,40(s1)
    80002cc8:	c3a1                	beqz	a5,80002d08 <usertrap+0xe0>
    80002cca:	a815                	j	80002cfe <usertrap+0xd6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002ccc:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002cd0:	5890                	lw	a2,48(s1)
    80002cd2:	00005517          	auipc	a0,0x5
    80002cd6:	67650513          	addi	a0,a0,1654 # 80008348 <states.1771+0x78>
    80002cda:	ffffe097          	auipc	ra,0xffffe
    80002cde:	8ae080e7          	jalr	-1874(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002ce2:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002ce6:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002cea:	00005517          	auipc	a0,0x5
    80002cee:	68e50513          	addi	a0,a0,1678 # 80008378 <states.1771+0xa8>
    80002cf2:	ffffe097          	auipc	ra,0xffffe
    80002cf6:	896080e7          	jalr	-1898(ra) # 80000588 <printf>
    p->killed = 1;
    80002cfa:	4785                	li	a5,1
    80002cfc:	d49c                	sw	a5,40(s1)
    exit(-1);
    80002cfe:	557d                	li	a0,-1
    80002d00:	00000097          	auipc	ra,0x0
    80002d04:	908080e7          	jalr	-1784(ra) # 80002608 <exit>
  if(which_dev == 2)
    80002d08:	4789                	li	a5,2
    80002d0a:	f8f910e3          	bne	s2,a5,80002c8a <usertrap+0x62>
    yield();
    80002d0e:	fffff097          	auipc	ra,0xfffff
    80002d12:	616080e7          	jalr	1558(ra) # 80002324 <yield>
    80002d16:	bf95                	j	80002c8a <usertrap+0x62>
  int which_dev = 0;
    80002d18:	4901                	li	s2,0
    80002d1a:	b7d5                	j	80002cfe <usertrap+0xd6>

0000000080002d1c <kerneltrap>:
{
    80002d1c:	7179                	addi	sp,sp,-48
    80002d1e:	f406                	sd	ra,40(sp)
    80002d20:	f022                	sd	s0,32(sp)
    80002d22:	ec26                	sd	s1,24(sp)
    80002d24:	e84a                	sd	s2,16(sp)
    80002d26:	e44e                	sd	s3,8(sp)
    80002d28:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002d2a:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002d2e:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002d32:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002d36:	1004f793          	andi	a5,s1,256
    80002d3a:	cb85                	beqz	a5,80002d6a <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002d3c:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002d40:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002d42:	ef85                	bnez	a5,80002d7a <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002d44:	00000097          	auipc	ra,0x0
    80002d48:	e42080e7          	jalr	-446(ra) # 80002b86 <devintr>
    80002d4c:	cd1d                	beqz	a0,80002d8a <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002d4e:	4789                	li	a5,2
    80002d50:	06f50a63          	beq	a0,a5,80002dc4 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002d54:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002d58:	10049073          	csrw	sstatus,s1
}
    80002d5c:	70a2                	ld	ra,40(sp)
    80002d5e:	7402                	ld	s0,32(sp)
    80002d60:	64e2                	ld	s1,24(sp)
    80002d62:	6942                	ld	s2,16(sp)
    80002d64:	69a2                	ld	s3,8(sp)
    80002d66:	6145                	addi	sp,sp,48
    80002d68:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002d6a:	00005517          	auipc	a0,0x5
    80002d6e:	62e50513          	addi	a0,a0,1582 # 80008398 <states.1771+0xc8>
    80002d72:	ffffd097          	auipc	ra,0xffffd
    80002d76:	7cc080e7          	jalr	1996(ra) # 8000053e <panic>
    panic("kerneltrap: interrupts enabled");
    80002d7a:	00005517          	auipc	a0,0x5
    80002d7e:	64650513          	addi	a0,a0,1606 # 800083c0 <states.1771+0xf0>
    80002d82:	ffffd097          	auipc	ra,0xffffd
    80002d86:	7bc080e7          	jalr	1980(ra) # 8000053e <panic>
    printf("scause %p\n", scause);
    80002d8a:	85ce                	mv	a1,s3
    80002d8c:	00005517          	auipc	a0,0x5
    80002d90:	65450513          	addi	a0,a0,1620 # 800083e0 <states.1771+0x110>
    80002d94:	ffffd097          	auipc	ra,0xffffd
    80002d98:	7f4080e7          	jalr	2036(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002d9c:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002da0:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002da4:	00005517          	auipc	a0,0x5
    80002da8:	64c50513          	addi	a0,a0,1612 # 800083f0 <states.1771+0x120>
    80002dac:	ffffd097          	auipc	ra,0xffffd
    80002db0:	7dc080e7          	jalr	2012(ra) # 80000588 <printf>
    panic("kerneltrap");
    80002db4:	00005517          	auipc	a0,0x5
    80002db8:	65450513          	addi	a0,a0,1620 # 80008408 <states.1771+0x138>
    80002dbc:	ffffd097          	auipc	ra,0xffffd
    80002dc0:	782080e7          	jalr	1922(ra) # 8000053e <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002dc4:	fffff097          	auipc	ra,0xfffff
    80002dc8:	c04080e7          	jalr	-1020(ra) # 800019c8 <myproc>
    80002dcc:	d541                	beqz	a0,80002d54 <kerneltrap+0x38>
    80002dce:	fffff097          	auipc	ra,0xfffff
    80002dd2:	bfa080e7          	jalr	-1030(ra) # 800019c8 <myproc>
    80002dd6:	4d18                	lw	a4,24(a0)
    80002dd8:	4791                	li	a5,4
    80002dda:	f6f71de3          	bne	a4,a5,80002d54 <kerneltrap+0x38>
    yield();
    80002dde:	fffff097          	auipc	ra,0xfffff
    80002de2:	546080e7          	jalr	1350(ra) # 80002324 <yield>
    80002de6:	b7bd                	j	80002d54 <kerneltrap+0x38>

0000000080002de8 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002de8:	1101                	addi	sp,sp,-32
    80002dea:	ec06                	sd	ra,24(sp)
    80002dec:	e822                	sd	s0,16(sp)
    80002dee:	e426                	sd	s1,8(sp)
    80002df0:	1000                	addi	s0,sp,32
    80002df2:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002df4:	fffff097          	auipc	ra,0xfffff
    80002df8:	bd4080e7          	jalr	-1068(ra) # 800019c8 <myproc>
  switch (n) {
    80002dfc:	4795                	li	a5,5
    80002dfe:	0497e163          	bltu	a5,s1,80002e40 <argraw+0x58>
    80002e02:	048a                	slli	s1,s1,0x2
    80002e04:	00005717          	auipc	a4,0x5
    80002e08:	63c70713          	addi	a4,a4,1596 # 80008440 <states.1771+0x170>
    80002e0c:	94ba                	add	s1,s1,a4
    80002e0e:	409c                	lw	a5,0(s1)
    80002e10:	97ba                	add	a5,a5,a4
    80002e12:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002e14:	7d3c                	ld	a5,120(a0)
    80002e16:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002e18:	60e2                	ld	ra,24(sp)
    80002e1a:	6442                	ld	s0,16(sp)
    80002e1c:	64a2                	ld	s1,8(sp)
    80002e1e:	6105                	addi	sp,sp,32
    80002e20:	8082                	ret
    return p->trapframe->a1;
    80002e22:	7d3c                	ld	a5,120(a0)
    80002e24:	7fa8                	ld	a0,120(a5)
    80002e26:	bfcd                	j	80002e18 <argraw+0x30>
    return p->trapframe->a2;
    80002e28:	7d3c                	ld	a5,120(a0)
    80002e2a:	63c8                	ld	a0,128(a5)
    80002e2c:	b7f5                	j	80002e18 <argraw+0x30>
    return p->trapframe->a3;
    80002e2e:	7d3c                	ld	a5,120(a0)
    80002e30:	67c8                	ld	a0,136(a5)
    80002e32:	b7dd                	j	80002e18 <argraw+0x30>
    return p->trapframe->a4;
    80002e34:	7d3c                	ld	a5,120(a0)
    80002e36:	6bc8                	ld	a0,144(a5)
    80002e38:	b7c5                	j	80002e18 <argraw+0x30>
    return p->trapframe->a5;
    80002e3a:	7d3c                	ld	a5,120(a0)
    80002e3c:	6fc8                	ld	a0,152(a5)
    80002e3e:	bfe9                	j	80002e18 <argraw+0x30>
  panic("argraw");
    80002e40:	00005517          	auipc	a0,0x5
    80002e44:	5d850513          	addi	a0,a0,1496 # 80008418 <states.1771+0x148>
    80002e48:	ffffd097          	auipc	ra,0xffffd
    80002e4c:	6f6080e7          	jalr	1782(ra) # 8000053e <panic>

0000000080002e50 <fetchaddr>:
{
    80002e50:	1101                	addi	sp,sp,-32
    80002e52:	ec06                	sd	ra,24(sp)
    80002e54:	e822                	sd	s0,16(sp)
    80002e56:	e426                	sd	s1,8(sp)
    80002e58:	e04a                	sd	s2,0(sp)
    80002e5a:	1000                	addi	s0,sp,32
    80002e5c:	84aa                	mv	s1,a0
    80002e5e:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002e60:	fffff097          	auipc	ra,0xfffff
    80002e64:	b68080e7          	jalr	-1176(ra) # 800019c8 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    80002e68:	753c                	ld	a5,104(a0)
    80002e6a:	02f4f863          	bgeu	s1,a5,80002e9a <fetchaddr+0x4a>
    80002e6e:	00848713          	addi	a4,s1,8
    80002e72:	02e7e663          	bltu	a5,a4,80002e9e <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002e76:	46a1                	li	a3,8
    80002e78:	8626                	mv	a2,s1
    80002e7a:	85ca                	mv	a1,s2
    80002e7c:	7928                	ld	a0,112(a0)
    80002e7e:	fffff097          	auipc	ra,0xfffff
    80002e82:	888080e7          	jalr	-1912(ra) # 80001706 <copyin>
    80002e86:	00a03533          	snez	a0,a0
    80002e8a:	40a00533          	neg	a0,a0
}
    80002e8e:	60e2                	ld	ra,24(sp)
    80002e90:	6442                	ld	s0,16(sp)
    80002e92:	64a2                	ld	s1,8(sp)
    80002e94:	6902                	ld	s2,0(sp)
    80002e96:	6105                	addi	sp,sp,32
    80002e98:	8082                	ret
    return -1;
    80002e9a:	557d                	li	a0,-1
    80002e9c:	bfcd                	j	80002e8e <fetchaddr+0x3e>
    80002e9e:	557d                	li	a0,-1
    80002ea0:	b7fd                	j	80002e8e <fetchaddr+0x3e>

0000000080002ea2 <fetchstr>:
{
    80002ea2:	7179                	addi	sp,sp,-48
    80002ea4:	f406                	sd	ra,40(sp)
    80002ea6:	f022                	sd	s0,32(sp)
    80002ea8:	ec26                	sd	s1,24(sp)
    80002eaa:	e84a                	sd	s2,16(sp)
    80002eac:	e44e                	sd	s3,8(sp)
    80002eae:	1800                	addi	s0,sp,48
    80002eb0:	892a                	mv	s2,a0
    80002eb2:	84ae                	mv	s1,a1
    80002eb4:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002eb6:	fffff097          	auipc	ra,0xfffff
    80002eba:	b12080e7          	jalr	-1262(ra) # 800019c8 <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80002ebe:	86ce                	mv	a3,s3
    80002ec0:	864a                	mv	a2,s2
    80002ec2:	85a6                	mv	a1,s1
    80002ec4:	7928                	ld	a0,112(a0)
    80002ec6:	fffff097          	auipc	ra,0xfffff
    80002eca:	8cc080e7          	jalr	-1844(ra) # 80001792 <copyinstr>
  if(err < 0)
    80002ece:	00054763          	bltz	a0,80002edc <fetchstr+0x3a>
  return strlen(buf);
    80002ed2:	8526                	mv	a0,s1
    80002ed4:	ffffe097          	auipc	ra,0xffffe
    80002ed8:	f90080e7          	jalr	-112(ra) # 80000e64 <strlen>
}
    80002edc:	70a2                	ld	ra,40(sp)
    80002ede:	7402                	ld	s0,32(sp)
    80002ee0:	64e2                	ld	s1,24(sp)
    80002ee2:	6942                	ld	s2,16(sp)
    80002ee4:	69a2                	ld	s3,8(sp)
    80002ee6:	6145                	addi	sp,sp,48
    80002ee8:	8082                	ret

0000000080002eea <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80002eea:	1101                	addi	sp,sp,-32
    80002eec:	ec06                	sd	ra,24(sp)
    80002eee:	e822                	sd	s0,16(sp)
    80002ef0:	e426                	sd	s1,8(sp)
    80002ef2:	1000                	addi	s0,sp,32
    80002ef4:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002ef6:	00000097          	auipc	ra,0x0
    80002efa:	ef2080e7          	jalr	-270(ra) # 80002de8 <argraw>
    80002efe:	c088                	sw	a0,0(s1)
  return 0;
}
    80002f00:	4501                	li	a0,0
    80002f02:	60e2                	ld	ra,24(sp)
    80002f04:	6442                	ld	s0,16(sp)
    80002f06:	64a2                	ld	s1,8(sp)
    80002f08:	6105                	addi	sp,sp,32
    80002f0a:	8082                	ret

0000000080002f0c <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80002f0c:	1101                	addi	sp,sp,-32
    80002f0e:	ec06                	sd	ra,24(sp)
    80002f10:	e822                	sd	s0,16(sp)
    80002f12:	e426                	sd	s1,8(sp)
    80002f14:	1000                	addi	s0,sp,32
    80002f16:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002f18:	00000097          	auipc	ra,0x0
    80002f1c:	ed0080e7          	jalr	-304(ra) # 80002de8 <argraw>
    80002f20:	e088                	sd	a0,0(s1)
  return 0;
}
    80002f22:	4501                	li	a0,0
    80002f24:	60e2                	ld	ra,24(sp)
    80002f26:	6442                	ld	s0,16(sp)
    80002f28:	64a2                	ld	s1,8(sp)
    80002f2a:	6105                	addi	sp,sp,32
    80002f2c:	8082                	ret

0000000080002f2e <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002f2e:	1101                	addi	sp,sp,-32
    80002f30:	ec06                	sd	ra,24(sp)
    80002f32:	e822                	sd	s0,16(sp)
    80002f34:	e426                	sd	s1,8(sp)
    80002f36:	e04a                	sd	s2,0(sp)
    80002f38:	1000                	addi	s0,sp,32
    80002f3a:	84ae                	mv	s1,a1
    80002f3c:	8932                	mv	s2,a2
  *ip = argraw(n);
    80002f3e:	00000097          	auipc	ra,0x0
    80002f42:	eaa080e7          	jalr	-342(ra) # 80002de8 <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80002f46:	864a                	mv	a2,s2
    80002f48:	85a6                	mv	a1,s1
    80002f4a:	00000097          	auipc	ra,0x0
    80002f4e:	f58080e7          	jalr	-168(ra) # 80002ea2 <fetchstr>
}
    80002f52:	60e2                	ld	ra,24(sp)
    80002f54:	6442                	ld	s0,16(sp)
    80002f56:	64a2                	ld	s1,8(sp)
    80002f58:	6902                	ld	s2,0(sp)
    80002f5a:	6105                	addi	sp,sp,32
    80002f5c:	8082                	ret

0000000080002f5e <syscall>:
[SYS_kill_system] sys_kill_system,
};

void
syscall(void)
{
    80002f5e:	1101                	addi	sp,sp,-32
    80002f60:	ec06                	sd	ra,24(sp)
    80002f62:	e822                	sd	s0,16(sp)
    80002f64:	e426                	sd	s1,8(sp)
    80002f66:	e04a                	sd	s2,0(sp)
    80002f68:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002f6a:	fffff097          	auipc	ra,0xfffff
    80002f6e:	a5e080e7          	jalr	-1442(ra) # 800019c8 <myproc>
    80002f72:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002f74:	07853903          	ld	s2,120(a0)
    80002f78:	0a893783          	ld	a5,168(s2)
    80002f7c:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002f80:	37fd                	addiw	a5,a5,-1
    80002f82:	4759                	li	a4,22
    80002f84:	00f76f63          	bltu	a4,a5,80002fa2 <syscall+0x44>
    80002f88:	00369713          	slli	a4,a3,0x3
    80002f8c:	00005797          	auipc	a5,0x5
    80002f90:	4cc78793          	addi	a5,a5,1228 # 80008458 <syscalls>
    80002f94:	97ba                	add	a5,a5,a4
    80002f96:	639c                	ld	a5,0(a5)
    80002f98:	c789                	beqz	a5,80002fa2 <syscall+0x44>
    p->trapframe->a0 = syscalls[num]();
    80002f9a:	9782                	jalr	a5
    80002f9c:	06a93823          	sd	a0,112(s2)
    80002fa0:	a839                	j	80002fbe <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002fa2:	17848613          	addi	a2,s1,376
    80002fa6:	588c                	lw	a1,48(s1)
    80002fa8:	00005517          	auipc	a0,0x5
    80002fac:	47850513          	addi	a0,a0,1144 # 80008420 <states.1771+0x150>
    80002fb0:	ffffd097          	auipc	ra,0xffffd
    80002fb4:	5d8080e7          	jalr	1496(ra) # 80000588 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002fb8:	7cbc                	ld	a5,120(s1)
    80002fba:	577d                	li	a4,-1
    80002fbc:	fbb8                	sd	a4,112(a5)
  }
}
    80002fbe:	60e2                	ld	ra,24(sp)
    80002fc0:	6442                	ld	s0,16(sp)
    80002fc2:	64a2                	ld	s1,8(sp)
    80002fc4:	6902                	ld	s2,0(sp)
    80002fc6:	6105                	addi	sp,sp,32
    80002fc8:	8082                	ret

0000000080002fca <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002fca:	1101                	addi	sp,sp,-32
    80002fcc:	ec06                	sd	ra,24(sp)
    80002fce:	e822                	sd	s0,16(sp)
    80002fd0:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80002fd2:	fec40593          	addi	a1,s0,-20
    80002fd6:	4501                	li	a0,0
    80002fd8:	00000097          	auipc	ra,0x0
    80002fdc:	f12080e7          	jalr	-238(ra) # 80002eea <argint>
    return -1;
    80002fe0:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002fe2:	00054963          	bltz	a0,80002ff4 <sys_exit+0x2a>
  exit(n);
    80002fe6:	fec42503          	lw	a0,-20(s0)
    80002fea:	fffff097          	auipc	ra,0xfffff
    80002fee:	61e080e7          	jalr	1566(ra) # 80002608 <exit>
  return 0;  // not reached
    80002ff2:	4781                	li	a5,0
}
    80002ff4:	853e                	mv	a0,a5
    80002ff6:	60e2                	ld	ra,24(sp)
    80002ff8:	6442                	ld	s0,16(sp)
    80002ffa:	6105                	addi	sp,sp,32
    80002ffc:	8082                	ret

0000000080002ffe <sys_getpid>:

uint64
sys_getpid(void)
{
    80002ffe:	1141                	addi	sp,sp,-16
    80003000:	e406                	sd	ra,8(sp)
    80003002:	e022                	sd	s0,0(sp)
    80003004:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80003006:	fffff097          	auipc	ra,0xfffff
    8000300a:	9c2080e7          	jalr	-1598(ra) # 800019c8 <myproc>
}
    8000300e:	5908                	lw	a0,48(a0)
    80003010:	60a2                	ld	ra,8(sp)
    80003012:	6402                	ld	s0,0(sp)
    80003014:	0141                	addi	sp,sp,16
    80003016:	8082                	ret

0000000080003018 <sys_fork>:

uint64
sys_fork(void)
{
    80003018:	1141                	addi	sp,sp,-16
    8000301a:	e406                	sd	ra,8(sp)
    8000301c:	e022                	sd	s0,0(sp)
    8000301e:	0800                	addi	s0,sp,16
  return fork();
    80003020:	fffff097          	auipc	ra,0xfffff
    80003024:	da4080e7          	jalr	-604(ra) # 80001dc4 <fork>
}
    80003028:	60a2                	ld	ra,8(sp)
    8000302a:	6402                	ld	s0,0(sp)
    8000302c:	0141                	addi	sp,sp,16
    8000302e:	8082                	ret

0000000080003030 <sys_wait>:

uint64
sys_wait(void)
{
    80003030:	1101                	addi	sp,sp,-32
    80003032:	ec06                	sd	ra,24(sp)
    80003034:	e822                	sd	s0,16(sp)
    80003036:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80003038:	fe840593          	addi	a1,s0,-24
    8000303c:	4501                	li	a0,0
    8000303e:	00000097          	auipc	ra,0x0
    80003042:	ece080e7          	jalr	-306(ra) # 80002f0c <argaddr>
    80003046:	87aa                	mv	a5,a0
    return -1;
    80003048:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    8000304a:	0007c863          	bltz	a5,8000305a <sys_wait+0x2a>
  return wait(p);
    8000304e:	fe843503          	ld	a0,-24(s0)
    80003052:	fffff097          	auipc	ra,0xfffff
    80003056:	39e080e7          	jalr	926(ra) # 800023f0 <wait>
}
    8000305a:	60e2                	ld	ra,24(sp)
    8000305c:	6442                	ld	s0,16(sp)
    8000305e:	6105                	addi	sp,sp,32
    80003060:	8082                	ret

0000000080003062 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80003062:	7179                	addi	sp,sp,-48
    80003064:	f406                	sd	ra,40(sp)
    80003066:	f022                	sd	s0,32(sp)
    80003068:	ec26                	sd	s1,24(sp)
    8000306a:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    8000306c:	fdc40593          	addi	a1,s0,-36
    80003070:	4501                	li	a0,0
    80003072:	00000097          	auipc	ra,0x0
    80003076:	e78080e7          	jalr	-392(ra) # 80002eea <argint>
    8000307a:	87aa                	mv	a5,a0
    return -1;
    8000307c:	557d                	li	a0,-1
  if(argint(0, &n) < 0)
    8000307e:	0207c063          	bltz	a5,8000309e <sys_sbrk+0x3c>
  addr = myproc()->sz;
    80003082:	fffff097          	auipc	ra,0xfffff
    80003086:	946080e7          	jalr	-1722(ra) # 800019c8 <myproc>
    8000308a:	5524                	lw	s1,104(a0)
  if(growproc(n) < 0)
    8000308c:	fdc42503          	lw	a0,-36(s0)
    80003090:	fffff097          	auipc	ra,0xfffff
    80003094:	cc0080e7          	jalr	-832(ra) # 80001d50 <growproc>
    80003098:	00054863          	bltz	a0,800030a8 <sys_sbrk+0x46>
    return -1;
  return addr;
    8000309c:	8526                	mv	a0,s1
}
    8000309e:	70a2                	ld	ra,40(sp)
    800030a0:	7402                	ld	s0,32(sp)
    800030a2:	64e2                	ld	s1,24(sp)
    800030a4:	6145                	addi	sp,sp,48
    800030a6:	8082                	ret
    return -1;
    800030a8:	557d                	li	a0,-1
    800030aa:	bfd5                	j	8000309e <sys_sbrk+0x3c>

00000000800030ac <sys_sleep>:

uint64
sys_sleep(void)
{
    800030ac:	7139                	addi	sp,sp,-64
    800030ae:	fc06                	sd	ra,56(sp)
    800030b0:	f822                	sd	s0,48(sp)
    800030b2:	f426                	sd	s1,40(sp)
    800030b4:	f04a                	sd	s2,32(sp)
    800030b6:	ec4e                	sd	s3,24(sp)
    800030b8:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    800030ba:	fcc40593          	addi	a1,s0,-52
    800030be:	4501                	li	a0,0
    800030c0:	00000097          	auipc	ra,0x0
    800030c4:	e2a080e7          	jalr	-470(ra) # 80002eea <argint>
    return -1;
    800030c8:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    800030ca:	06054563          	bltz	a0,80003134 <sys_sleep+0x88>
  acquire(&tickslock);
    800030ce:	00015517          	auipc	a0,0x15
    800030d2:	82250513          	addi	a0,a0,-2014 # 800178f0 <tickslock>
    800030d6:	ffffe097          	auipc	ra,0xffffe
    800030da:	b0e080e7          	jalr	-1266(ra) # 80000be4 <acquire>
  ticks0 = ticks;
    800030de:	00006917          	auipc	s2,0x6
    800030e2:	f7292903          	lw	s2,-142(s2) # 80009050 <ticks>
  while(ticks - ticks0 < n){
    800030e6:	fcc42783          	lw	a5,-52(s0)
    800030ea:	cf85                	beqz	a5,80003122 <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    800030ec:	00015997          	auipc	s3,0x15
    800030f0:	80498993          	addi	s3,s3,-2044 # 800178f0 <tickslock>
    800030f4:	00006497          	auipc	s1,0x6
    800030f8:	f5c48493          	addi	s1,s1,-164 # 80009050 <ticks>
    if(myproc()->killed){
    800030fc:	fffff097          	auipc	ra,0xfffff
    80003100:	8cc080e7          	jalr	-1844(ra) # 800019c8 <myproc>
    80003104:	551c                	lw	a5,40(a0)
    80003106:	ef9d                	bnez	a5,80003144 <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    80003108:	85ce                	mv	a1,s3
    8000310a:	8526                	mv	a0,s1
    8000310c:	fffff097          	auipc	ra,0xfffff
    80003110:	26c080e7          	jalr	620(ra) # 80002378 <sleep>
  while(ticks - ticks0 < n){
    80003114:	409c                	lw	a5,0(s1)
    80003116:	412787bb          	subw	a5,a5,s2
    8000311a:	fcc42703          	lw	a4,-52(s0)
    8000311e:	fce7efe3          	bltu	a5,a4,800030fc <sys_sleep+0x50>
  }
  release(&tickslock);
    80003122:	00014517          	auipc	a0,0x14
    80003126:	7ce50513          	addi	a0,a0,1998 # 800178f0 <tickslock>
    8000312a:	ffffe097          	auipc	ra,0xffffe
    8000312e:	b6e080e7          	jalr	-1170(ra) # 80000c98 <release>
  return 0;
    80003132:	4781                	li	a5,0
}
    80003134:	853e                	mv	a0,a5
    80003136:	70e2                	ld	ra,56(sp)
    80003138:	7442                	ld	s0,48(sp)
    8000313a:	74a2                	ld	s1,40(sp)
    8000313c:	7902                	ld	s2,32(sp)
    8000313e:	69e2                	ld	s3,24(sp)
    80003140:	6121                	addi	sp,sp,64
    80003142:	8082                	ret
      release(&tickslock);
    80003144:	00014517          	auipc	a0,0x14
    80003148:	7ac50513          	addi	a0,a0,1964 # 800178f0 <tickslock>
    8000314c:	ffffe097          	auipc	ra,0xffffe
    80003150:	b4c080e7          	jalr	-1204(ra) # 80000c98 <release>
      return -1;
    80003154:	57fd                	li	a5,-1
    80003156:	bff9                	j	80003134 <sys_sleep+0x88>

0000000080003158 <sys_kill>:

uint64
sys_kill(void)
{
    80003158:	1101                	addi	sp,sp,-32
    8000315a:	ec06                	sd	ra,24(sp)
    8000315c:	e822                	sd	s0,16(sp)
    8000315e:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    80003160:	fec40593          	addi	a1,s0,-20
    80003164:	4501                	li	a0,0
    80003166:	00000097          	auipc	ra,0x0
    8000316a:	d84080e7          	jalr	-636(ra) # 80002eea <argint>
    8000316e:	87aa                	mv	a5,a0
    return -1;
    80003170:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    80003172:	0007c863          	bltz	a5,80003182 <sys_kill+0x2a>
  return kill(pid);
    80003176:	fec42503          	lw	a0,-20(s0)
    8000317a:	fffff097          	auipc	ra,0xfffff
    8000317e:	5f8080e7          	jalr	1528(ra) # 80002772 <kill>
}
    80003182:	60e2                	ld	ra,24(sp)
    80003184:	6442                	ld	s0,16(sp)
    80003186:	6105                	addi	sp,sp,32
    80003188:	8082                	ret

000000008000318a <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    8000318a:	1101                	addi	sp,sp,-32
    8000318c:	ec06                	sd	ra,24(sp)
    8000318e:	e822                	sd	s0,16(sp)
    80003190:	e426                	sd	s1,8(sp)
    80003192:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80003194:	00014517          	auipc	a0,0x14
    80003198:	75c50513          	addi	a0,a0,1884 # 800178f0 <tickslock>
    8000319c:	ffffe097          	auipc	ra,0xffffe
    800031a0:	a48080e7          	jalr	-1464(ra) # 80000be4 <acquire>
  xticks = ticks;
    800031a4:	00006497          	auipc	s1,0x6
    800031a8:	eac4a483          	lw	s1,-340(s1) # 80009050 <ticks>
  release(&tickslock);
    800031ac:	00014517          	auipc	a0,0x14
    800031b0:	74450513          	addi	a0,a0,1860 # 800178f0 <tickslock>
    800031b4:	ffffe097          	auipc	ra,0xffffe
    800031b8:	ae4080e7          	jalr	-1308(ra) # 80000c98 <release>
  return xticks;
}
    800031bc:	02049513          	slli	a0,s1,0x20
    800031c0:	9101                	srli	a0,a0,0x20
    800031c2:	60e2                	ld	ra,24(sp)
    800031c4:	6442                	ld	s0,16(sp)
    800031c6:	64a2                	ld	s1,8(sp)
    800031c8:	6105                	addi	sp,sp,32
    800031ca:	8082                	ret

00000000800031cc <sys_pause_system>:

uint64 sys_pause_system(void){
    800031cc:	1101                	addi	sp,sp,-32
    800031ce:	ec06                	sd	ra,24(sp)
    800031d0:	e822                	sd	s0,16(sp)
    800031d2:	1000                	addi	s0,sp,32
    int seconds;

    if(argint(0, &seconds) < 0)
    800031d4:	fec40593          	addi	a1,s0,-20
    800031d8:	4501                	li	a0,0
    800031da:	00000097          	auipc	ra,0x0
    800031de:	d10080e7          	jalr	-752(ra) # 80002eea <argint>
        return -1;
    800031e2:	57fd                	li	a5,-1
    if(argint(0, &seconds) < 0)
    800031e4:	00054963          	bltz	a0,800031f6 <sys_pause_system+0x2a>
    pause_system(seconds);
    800031e8:	fec42503          	lw	a0,-20(s0)
    800031ec:	fffff097          	auipc	ra,0xfffff
    800031f0:	67c080e7          	jalr	1660(ra) # 80002868 <pause_system>
    return 0;
    800031f4:	4781                	li	a5,0
}
    800031f6:	853e                	mv	a0,a5
    800031f8:	60e2                	ld	ra,24(sp)
    800031fa:	6442                	ld	s0,16(sp)
    800031fc:	6105                	addi	sp,sp,32
    800031fe:	8082                	ret

0000000080003200 <sys_kill_system>:

uint64 sys_kill_system(void){
    80003200:	1141                	addi	sp,sp,-16
    80003202:	e406                	sd	ra,8(sp)
    80003204:	e022                	sd	s0,0(sp)
    80003206:	0800                	addi	s0,sp,16
    kill_system();
    80003208:	fffff097          	auipc	ra,0xfffff
    8000320c:	5f4080e7          	jalr	1524(ra) # 800027fc <kill_system>
    return 0;
}
    80003210:	4501                	li	a0,0
    80003212:	60a2                	ld	ra,8(sp)
    80003214:	6402                	ld	s0,0(sp)
    80003216:	0141                	addi	sp,sp,16
    80003218:	8082                	ret

000000008000321a <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    8000321a:	7179                	addi	sp,sp,-48
    8000321c:	f406                	sd	ra,40(sp)
    8000321e:	f022                	sd	s0,32(sp)
    80003220:	ec26                	sd	s1,24(sp)
    80003222:	e84a                	sd	s2,16(sp)
    80003224:	e44e                	sd	s3,8(sp)
    80003226:	e052                	sd	s4,0(sp)
    80003228:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    8000322a:	00005597          	auipc	a1,0x5
    8000322e:	2ee58593          	addi	a1,a1,750 # 80008518 <syscalls+0xc0>
    80003232:	00014517          	auipc	a0,0x14
    80003236:	6d650513          	addi	a0,a0,1750 # 80017908 <bcache>
    8000323a:	ffffe097          	auipc	ra,0xffffe
    8000323e:	91a080e7          	jalr	-1766(ra) # 80000b54 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80003242:	0001c797          	auipc	a5,0x1c
    80003246:	6c678793          	addi	a5,a5,1734 # 8001f908 <bcache+0x8000>
    8000324a:	0001d717          	auipc	a4,0x1d
    8000324e:	92670713          	addi	a4,a4,-1754 # 8001fb70 <bcache+0x8268>
    80003252:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80003256:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    8000325a:	00014497          	auipc	s1,0x14
    8000325e:	6c648493          	addi	s1,s1,1734 # 80017920 <bcache+0x18>
    b->next = bcache.head.next;
    80003262:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80003264:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80003266:	00005a17          	auipc	s4,0x5
    8000326a:	2baa0a13          	addi	s4,s4,698 # 80008520 <syscalls+0xc8>
    b->next = bcache.head.next;
    8000326e:	2b893783          	ld	a5,696(s2)
    80003272:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80003274:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80003278:	85d2                	mv	a1,s4
    8000327a:	01048513          	addi	a0,s1,16
    8000327e:	00001097          	auipc	ra,0x1
    80003282:	4bc080e7          	jalr	1212(ra) # 8000473a <initsleeplock>
    bcache.head.next->prev = b;
    80003286:	2b893783          	ld	a5,696(s2)
    8000328a:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    8000328c:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003290:	45848493          	addi	s1,s1,1112
    80003294:	fd349de3          	bne	s1,s3,8000326e <binit+0x54>
  }
}
    80003298:	70a2                	ld	ra,40(sp)
    8000329a:	7402                	ld	s0,32(sp)
    8000329c:	64e2                	ld	s1,24(sp)
    8000329e:	6942                	ld	s2,16(sp)
    800032a0:	69a2                	ld	s3,8(sp)
    800032a2:	6a02                	ld	s4,0(sp)
    800032a4:	6145                	addi	sp,sp,48
    800032a6:	8082                	ret

00000000800032a8 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    800032a8:	7179                	addi	sp,sp,-48
    800032aa:	f406                	sd	ra,40(sp)
    800032ac:	f022                	sd	s0,32(sp)
    800032ae:	ec26                	sd	s1,24(sp)
    800032b0:	e84a                	sd	s2,16(sp)
    800032b2:	e44e                	sd	s3,8(sp)
    800032b4:	1800                	addi	s0,sp,48
    800032b6:	89aa                	mv	s3,a0
    800032b8:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    800032ba:	00014517          	auipc	a0,0x14
    800032be:	64e50513          	addi	a0,a0,1614 # 80017908 <bcache>
    800032c2:	ffffe097          	auipc	ra,0xffffe
    800032c6:	922080e7          	jalr	-1758(ra) # 80000be4 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    800032ca:	0001d497          	auipc	s1,0x1d
    800032ce:	8f64b483          	ld	s1,-1802(s1) # 8001fbc0 <bcache+0x82b8>
    800032d2:	0001d797          	auipc	a5,0x1d
    800032d6:	89e78793          	addi	a5,a5,-1890 # 8001fb70 <bcache+0x8268>
    800032da:	02f48f63          	beq	s1,a5,80003318 <bread+0x70>
    800032de:	873e                	mv	a4,a5
    800032e0:	a021                	j	800032e8 <bread+0x40>
    800032e2:	68a4                	ld	s1,80(s1)
    800032e4:	02e48a63          	beq	s1,a4,80003318 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    800032e8:	449c                	lw	a5,8(s1)
    800032ea:	ff379ce3          	bne	a5,s3,800032e2 <bread+0x3a>
    800032ee:	44dc                	lw	a5,12(s1)
    800032f0:	ff2799e3          	bne	a5,s2,800032e2 <bread+0x3a>
      b->refcnt++;
    800032f4:	40bc                	lw	a5,64(s1)
    800032f6:	2785                	addiw	a5,a5,1
    800032f8:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800032fa:	00014517          	auipc	a0,0x14
    800032fe:	60e50513          	addi	a0,a0,1550 # 80017908 <bcache>
    80003302:	ffffe097          	auipc	ra,0xffffe
    80003306:	996080e7          	jalr	-1642(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    8000330a:	01048513          	addi	a0,s1,16
    8000330e:	00001097          	auipc	ra,0x1
    80003312:	466080e7          	jalr	1126(ra) # 80004774 <acquiresleep>
      return b;
    80003316:	a8b9                	j	80003374 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003318:	0001d497          	auipc	s1,0x1d
    8000331c:	8a04b483          	ld	s1,-1888(s1) # 8001fbb8 <bcache+0x82b0>
    80003320:	0001d797          	auipc	a5,0x1d
    80003324:	85078793          	addi	a5,a5,-1968 # 8001fb70 <bcache+0x8268>
    80003328:	00f48863          	beq	s1,a5,80003338 <bread+0x90>
    8000332c:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    8000332e:	40bc                	lw	a5,64(s1)
    80003330:	cf81                	beqz	a5,80003348 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003332:	64a4                	ld	s1,72(s1)
    80003334:	fee49de3          	bne	s1,a4,8000332e <bread+0x86>
  panic("bget: no buffers");
    80003338:	00005517          	auipc	a0,0x5
    8000333c:	1f050513          	addi	a0,a0,496 # 80008528 <syscalls+0xd0>
    80003340:	ffffd097          	auipc	ra,0xffffd
    80003344:	1fe080e7          	jalr	510(ra) # 8000053e <panic>
      b->dev = dev;
    80003348:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    8000334c:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    80003350:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80003354:	4785                	li	a5,1
    80003356:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003358:	00014517          	auipc	a0,0x14
    8000335c:	5b050513          	addi	a0,a0,1456 # 80017908 <bcache>
    80003360:	ffffe097          	auipc	ra,0xffffe
    80003364:	938080e7          	jalr	-1736(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    80003368:	01048513          	addi	a0,s1,16
    8000336c:	00001097          	auipc	ra,0x1
    80003370:	408080e7          	jalr	1032(ra) # 80004774 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80003374:	409c                	lw	a5,0(s1)
    80003376:	cb89                	beqz	a5,80003388 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80003378:	8526                	mv	a0,s1
    8000337a:	70a2                	ld	ra,40(sp)
    8000337c:	7402                	ld	s0,32(sp)
    8000337e:	64e2                	ld	s1,24(sp)
    80003380:	6942                	ld	s2,16(sp)
    80003382:	69a2                	ld	s3,8(sp)
    80003384:	6145                	addi	sp,sp,48
    80003386:	8082                	ret
    virtio_disk_rw(b, 0);
    80003388:	4581                	li	a1,0
    8000338a:	8526                	mv	a0,s1
    8000338c:	00003097          	auipc	ra,0x3
    80003390:	f0a080e7          	jalr	-246(ra) # 80006296 <virtio_disk_rw>
    b->valid = 1;
    80003394:	4785                	li	a5,1
    80003396:	c09c                	sw	a5,0(s1)
  return b;
    80003398:	b7c5                	j	80003378 <bread+0xd0>

000000008000339a <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    8000339a:	1101                	addi	sp,sp,-32
    8000339c:	ec06                	sd	ra,24(sp)
    8000339e:	e822                	sd	s0,16(sp)
    800033a0:	e426                	sd	s1,8(sp)
    800033a2:	1000                	addi	s0,sp,32
    800033a4:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800033a6:	0541                	addi	a0,a0,16
    800033a8:	00001097          	auipc	ra,0x1
    800033ac:	466080e7          	jalr	1126(ra) # 8000480e <holdingsleep>
    800033b0:	cd01                	beqz	a0,800033c8 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    800033b2:	4585                	li	a1,1
    800033b4:	8526                	mv	a0,s1
    800033b6:	00003097          	auipc	ra,0x3
    800033ba:	ee0080e7          	jalr	-288(ra) # 80006296 <virtio_disk_rw>
}
    800033be:	60e2                	ld	ra,24(sp)
    800033c0:	6442                	ld	s0,16(sp)
    800033c2:	64a2                	ld	s1,8(sp)
    800033c4:	6105                	addi	sp,sp,32
    800033c6:	8082                	ret
    panic("bwrite");
    800033c8:	00005517          	auipc	a0,0x5
    800033cc:	17850513          	addi	a0,a0,376 # 80008540 <syscalls+0xe8>
    800033d0:	ffffd097          	auipc	ra,0xffffd
    800033d4:	16e080e7          	jalr	366(ra) # 8000053e <panic>

00000000800033d8 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    800033d8:	1101                	addi	sp,sp,-32
    800033da:	ec06                	sd	ra,24(sp)
    800033dc:	e822                	sd	s0,16(sp)
    800033de:	e426                	sd	s1,8(sp)
    800033e0:	e04a                	sd	s2,0(sp)
    800033e2:	1000                	addi	s0,sp,32
    800033e4:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800033e6:	01050913          	addi	s2,a0,16
    800033ea:	854a                	mv	a0,s2
    800033ec:	00001097          	auipc	ra,0x1
    800033f0:	422080e7          	jalr	1058(ra) # 8000480e <holdingsleep>
    800033f4:	c92d                	beqz	a0,80003466 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    800033f6:	854a                	mv	a0,s2
    800033f8:	00001097          	auipc	ra,0x1
    800033fc:	3d2080e7          	jalr	978(ra) # 800047ca <releasesleep>

  acquire(&bcache.lock);
    80003400:	00014517          	auipc	a0,0x14
    80003404:	50850513          	addi	a0,a0,1288 # 80017908 <bcache>
    80003408:	ffffd097          	auipc	ra,0xffffd
    8000340c:	7dc080e7          	jalr	2012(ra) # 80000be4 <acquire>
  b->refcnt--;
    80003410:	40bc                	lw	a5,64(s1)
    80003412:	37fd                	addiw	a5,a5,-1
    80003414:	0007871b          	sext.w	a4,a5
    80003418:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    8000341a:	eb05                	bnez	a4,8000344a <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    8000341c:	68bc                	ld	a5,80(s1)
    8000341e:	64b8                	ld	a4,72(s1)
    80003420:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    80003422:	64bc                	ld	a5,72(s1)
    80003424:	68b8                	ld	a4,80(s1)
    80003426:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80003428:	0001c797          	auipc	a5,0x1c
    8000342c:	4e078793          	addi	a5,a5,1248 # 8001f908 <bcache+0x8000>
    80003430:	2b87b703          	ld	a4,696(a5)
    80003434:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80003436:	0001c717          	auipc	a4,0x1c
    8000343a:	73a70713          	addi	a4,a4,1850 # 8001fb70 <bcache+0x8268>
    8000343e:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80003440:	2b87b703          	ld	a4,696(a5)
    80003444:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80003446:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    8000344a:	00014517          	auipc	a0,0x14
    8000344e:	4be50513          	addi	a0,a0,1214 # 80017908 <bcache>
    80003452:	ffffe097          	auipc	ra,0xffffe
    80003456:	846080e7          	jalr	-1978(ra) # 80000c98 <release>
}
    8000345a:	60e2                	ld	ra,24(sp)
    8000345c:	6442                	ld	s0,16(sp)
    8000345e:	64a2                	ld	s1,8(sp)
    80003460:	6902                	ld	s2,0(sp)
    80003462:	6105                	addi	sp,sp,32
    80003464:	8082                	ret
    panic("brelse");
    80003466:	00005517          	auipc	a0,0x5
    8000346a:	0e250513          	addi	a0,a0,226 # 80008548 <syscalls+0xf0>
    8000346e:	ffffd097          	auipc	ra,0xffffd
    80003472:	0d0080e7          	jalr	208(ra) # 8000053e <panic>

0000000080003476 <bpin>:

void
bpin(struct buf *b) {
    80003476:	1101                	addi	sp,sp,-32
    80003478:	ec06                	sd	ra,24(sp)
    8000347a:	e822                	sd	s0,16(sp)
    8000347c:	e426                	sd	s1,8(sp)
    8000347e:	1000                	addi	s0,sp,32
    80003480:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003482:	00014517          	auipc	a0,0x14
    80003486:	48650513          	addi	a0,a0,1158 # 80017908 <bcache>
    8000348a:	ffffd097          	auipc	ra,0xffffd
    8000348e:	75a080e7          	jalr	1882(ra) # 80000be4 <acquire>
  b->refcnt++;
    80003492:	40bc                	lw	a5,64(s1)
    80003494:	2785                	addiw	a5,a5,1
    80003496:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003498:	00014517          	auipc	a0,0x14
    8000349c:	47050513          	addi	a0,a0,1136 # 80017908 <bcache>
    800034a0:	ffffd097          	auipc	ra,0xffffd
    800034a4:	7f8080e7          	jalr	2040(ra) # 80000c98 <release>
}
    800034a8:	60e2                	ld	ra,24(sp)
    800034aa:	6442                	ld	s0,16(sp)
    800034ac:	64a2                	ld	s1,8(sp)
    800034ae:	6105                	addi	sp,sp,32
    800034b0:	8082                	ret

00000000800034b2 <bunpin>:

void
bunpin(struct buf *b) {
    800034b2:	1101                	addi	sp,sp,-32
    800034b4:	ec06                	sd	ra,24(sp)
    800034b6:	e822                	sd	s0,16(sp)
    800034b8:	e426                	sd	s1,8(sp)
    800034ba:	1000                	addi	s0,sp,32
    800034bc:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800034be:	00014517          	auipc	a0,0x14
    800034c2:	44a50513          	addi	a0,a0,1098 # 80017908 <bcache>
    800034c6:	ffffd097          	auipc	ra,0xffffd
    800034ca:	71e080e7          	jalr	1822(ra) # 80000be4 <acquire>
  b->refcnt--;
    800034ce:	40bc                	lw	a5,64(s1)
    800034d0:	37fd                	addiw	a5,a5,-1
    800034d2:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800034d4:	00014517          	auipc	a0,0x14
    800034d8:	43450513          	addi	a0,a0,1076 # 80017908 <bcache>
    800034dc:	ffffd097          	auipc	ra,0xffffd
    800034e0:	7bc080e7          	jalr	1980(ra) # 80000c98 <release>
}
    800034e4:	60e2                	ld	ra,24(sp)
    800034e6:	6442                	ld	s0,16(sp)
    800034e8:	64a2                	ld	s1,8(sp)
    800034ea:	6105                	addi	sp,sp,32
    800034ec:	8082                	ret

00000000800034ee <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    800034ee:	1101                	addi	sp,sp,-32
    800034f0:	ec06                	sd	ra,24(sp)
    800034f2:	e822                	sd	s0,16(sp)
    800034f4:	e426                	sd	s1,8(sp)
    800034f6:	e04a                	sd	s2,0(sp)
    800034f8:	1000                	addi	s0,sp,32
    800034fa:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    800034fc:	00d5d59b          	srliw	a1,a1,0xd
    80003500:	0001d797          	auipc	a5,0x1d
    80003504:	ae47a783          	lw	a5,-1308(a5) # 8001ffe4 <sb+0x1c>
    80003508:	9dbd                	addw	a1,a1,a5
    8000350a:	00000097          	auipc	ra,0x0
    8000350e:	d9e080e7          	jalr	-610(ra) # 800032a8 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003512:	0074f713          	andi	a4,s1,7
    80003516:	4785                	li	a5,1
    80003518:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    8000351c:	14ce                	slli	s1,s1,0x33
    8000351e:	90d9                	srli	s1,s1,0x36
    80003520:	00950733          	add	a4,a0,s1
    80003524:	05874703          	lbu	a4,88(a4)
    80003528:	00e7f6b3          	and	a3,a5,a4
    8000352c:	c69d                	beqz	a3,8000355a <bfree+0x6c>
    8000352e:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80003530:	94aa                	add	s1,s1,a0
    80003532:	fff7c793          	not	a5,a5
    80003536:	8ff9                	and	a5,a5,a4
    80003538:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    8000353c:	00001097          	auipc	ra,0x1
    80003540:	118080e7          	jalr	280(ra) # 80004654 <log_write>
  brelse(bp);
    80003544:	854a                	mv	a0,s2
    80003546:	00000097          	auipc	ra,0x0
    8000354a:	e92080e7          	jalr	-366(ra) # 800033d8 <brelse>
}
    8000354e:	60e2                	ld	ra,24(sp)
    80003550:	6442                	ld	s0,16(sp)
    80003552:	64a2                	ld	s1,8(sp)
    80003554:	6902                	ld	s2,0(sp)
    80003556:	6105                	addi	sp,sp,32
    80003558:	8082                	ret
    panic("freeing free block");
    8000355a:	00005517          	auipc	a0,0x5
    8000355e:	ff650513          	addi	a0,a0,-10 # 80008550 <syscalls+0xf8>
    80003562:	ffffd097          	auipc	ra,0xffffd
    80003566:	fdc080e7          	jalr	-36(ra) # 8000053e <panic>

000000008000356a <balloc>:
{
    8000356a:	711d                	addi	sp,sp,-96
    8000356c:	ec86                	sd	ra,88(sp)
    8000356e:	e8a2                	sd	s0,80(sp)
    80003570:	e4a6                	sd	s1,72(sp)
    80003572:	e0ca                	sd	s2,64(sp)
    80003574:	fc4e                	sd	s3,56(sp)
    80003576:	f852                	sd	s4,48(sp)
    80003578:	f456                	sd	s5,40(sp)
    8000357a:	f05a                	sd	s6,32(sp)
    8000357c:	ec5e                	sd	s7,24(sp)
    8000357e:	e862                	sd	s8,16(sp)
    80003580:	e466                	sd	s9,8(sp)
    80003582:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80003584:	0001d797          	auipc	a5,0x1d
    80003588:	a487a783          	lw	a5,-1464(a5) # 8001ffcc <sb+0x4>
    8000358c:	cbd1                	beqz	a5,80003620 <balloc+0xb6>
    8000358e:	8baa                	mv	s7,a0
    80003590:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80003592:	0001db17          	auipc	s6,0x1d
    80003596:	a36b0b13          	addi	s6,s6,-1482 # 8001ffc8 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000359a:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    8000359c:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000359e:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    800035a0:	6c89                	lui	s9,0x2
    800035a2:	a831                	j	800035be <balloc+0x54>
    brelse(bp);
    800035a4:	854a                	mv	a0,s2
    800035a6:	00000097          	auipc	ra,0x0
    800035aa:	e32080e7          	jalr	-462(ra) # 800033d8 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    800035ae:	015c87bb          	addw	a5,s9,s5
    800035b2:	00078a9b          	sext.w	s5,a5
    800035b6:	004b2703          	lw	a4,4(s6)
    800035ba:	06eaf363          	bgeu	s5,a4,80003620 <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    800035be:	41fad79b          	sraiw	a5,s5,0x1f
    800035c2:	0137d79b          	srliw	a5,a5,0x13
    800035c6:	015787bb          	addw	a5,a5,s5
    800035ca:	40d7d79b          	sraiw	a5,a5,0xd
    800035ce:	01cb2583          	lw	a1,28(s6)
    800035d2:	9dbd                	addw	a1,a1,a5
    800035d4:	855e                	mv	a0,s7
    800035d6:	00000097          	auipc	ra,0x0
    800035da:	cd2080e7          	jalr	-814(ra) # 800032a8 <bread>
    800035de:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800035e0:	004b2503          	lw	a0,4(s6)
    800035e4:	000a849b          	sext.w	s1,s5
    800035e8:	8662                	mv	a2,s8
    800035ea:	faa4fde3          	bgeu	s1,a0,800035a4 <balloc+0x3a>
      m = 1 << (bi % 8);
    800035ee:	41f6579b          	sraiw	a5,a2,0x1f
    800035f2:	01d7d69b          	srliw	a3,a5,0x1d
    800035f6:	00c6873b          	addw	a4,a3,a2
    800035fa:	00777793          	andi	a5,a4,7
    800035fe:	9f95                	subw	a5,a5,a3
    80003600:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003604:	4037571b          	sraiw	a4,a4,0x3
    80003608:	00e906b3          	add	a3,s2,a4
    8000360c:	0586c683          	lbu	a3,88(a3)
    80003610:	00d7f5b3          	and	a1,a5,a3
    80003614:	cd91                	beqz	a1,80003630 <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003616:	2605                	addiw	a2,a2,1
    80003618:	2485                	addiw	s1,s1,1
    8000361a:	fd4618e3          	bne	a2,s4,800035ea <balloc+0x80>
    8000361e:	b759                	j	800035a4 <balloc+0x3a>
  panic("balloc: out of blocks");
    80003620:	00005517          	auipc	a0,0x5
    80003624:	f4850513          	addi	a0,a0,-184 # 80008568 <syscalls+0x110>
    80003628:	ffffd097          	auipc	ra,0xffffd
    8000362c:	f16080e7          	jalr	-234(ra) # 8000053e <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    80003630:	974a                	add	a4,a4,s2
    80003632:	8fd5                	or	a5,a5,a3
    80003634:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    80003638:	854a                	mv	a0,s2
    8000363a:	00001097          	auipc	ra,0x1
    8000363e:	01a080e7          	jalr	26(ra) # 80004654 <log_write>
        brelse(bp);
    80003642:	854a                	mv	a0,s2
    80003644:	00000097          	auipc	ra,0x0
    80003648:	d94080e7          	jalr	-620(ra) # 800033d8 <brelse>
  bp = bread(dev, bno);
    8000364c:	85a6                	mv	a1,s1
    8000364e:	855e                	mv	a0,s7
    80003650:	00000097          	auipc	ra,0x0
    80003654:	c58080e7          	jalr	-936(ra) # 800032a8 <bread>
    80003658:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    8000365a:	40000613          	li	a2,1024
    8000365e:	4581                	li	a1,0
    80003660:	05850513          	addi	a0,a0,88
    80003664:	ffffd097          	auipc	ra,0xffffd
    80003668:	67c080e7          	jalr	1660(ra) # 80000ce0 <memset>
  log_write(bp);
    8000366c:	854a                	mv	a0,s2
    8000366e:	00001097          	auipc	ra,0x1
    80003672:	fe6080e7          	jalr	-26(ra) # 80004654 <log_write>
  brelse(bp);
    80003676:	854a                	mv	a0,s2
    80003678:	00000097          	auipc	ra,0x0
    8000367c:	d60080e7          	jalr	-672(ra) # 800033d8 <brelse>
}
    80003680:	8526                	mv	a0,s1
    80003682:	60e6                	ld	ra,88(sp)
    80003684:	6446                	ld	s0,80(sp)
    80003686:	64a6                	ld	s1,72(sp)
    80003688:	6906                	ld	s2,64(sp)
    8000368a:	79e2                	ld	s3,56(sp)
    8000368c:	7a42                	ld	s4,48(sp)
    8000368e:	7aa2                	ld	s5,40(sp)
    80003690:	7b02                	ld	s6,32(sp)
    80003692:	6be2                	ld	s7,24(sp)
    80003694:	6c42                	ld	s8,16(sp)
    80003696:	6ca2                	ld	s9,8(sp)
    80003698:	6125                	addi	sp,sp,96
    8000369a:	8082                	ret

000000008000369c <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    8000369c:	7179                	addi	sp,sp,-48
    8000369e:	f406                	sd	ra,40(sp)
    800036a0:	f022                	sd	s0,32(sp)
    800036a2:	ec26                	sd	s1,24(sp)
    800036a4:	e84a                	sd	s2,16(sp)
    800036a6:	e44e                	sd	s3,8(sp)
    800036a8:	e052                	sd	s4,0(sp)
    800036aa:	1800                	addi	s0,sp,48
    800036ac:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    800036ae:	47ad                	li	a5,11
    800036b0:	04b7fe63          	bgeu	a5,a1,8000370c <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    800036b4:	ff45849b          	addiw	s1,a1,-12
    800036b8:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    800036bc:	0ff00793          	li	a5,255
    800036c0:	0ae7e363          	bltu	a5,a4,80003766 <bmap+0xca>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    800036c4:	08052583          	lw	a1,128(a0)
    800036c8:	c5ad                	beqz	a1,80003732 <bmap+0x96>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    800036ca:	00092503          	lw	a0,0(s2)
    800036ce:	00000097          	auipc	ra,0x0
    800036d2:	bda080e7          	jalr	-1062(ra) # 800032a8 <bread>
    800036d6:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    800036d8:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    800036dc:	02049593          	slli	a1,s1,0x20
    800036e0:	9181                	srli	a1,a1,0x20
    800036e2:	058a                	slli	a1,a1,0x2
    800036e4:	00b784b3          	add	s1,a5,a1
    800036e8:	0004a983          	lw	s3,0(s1)
    800036ec:	04098d63          	beqz	s3,80003746 <bmap+0xaa>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    800036f0:	8552                	mv	a0,s4
    800036f2:	00000097          	auipc	ra,0x0
    800036f6:	ce6080e7          	jalr	-794(ra) # 800033d8 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    800036fa:	854e                	mv	a0,s3
    800036fc:	70a2                	ld	ra,40(sp)
    800036fe:	7402                	ld	s0,32(sp)
    80003700:	64e2                	ld	s1,24(sp)
    80003702:	6942                	ld	s2,16(sp)
    80003704:	69a2                	ld	s3,8(sp)
    80003706:	6a02                	ld	s4,0(sp)
    80003708:	6145                	addi	sp,sp,48
    8000370a:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    8000370c:	02059493          	slli	s1,a1,0x20
    80003710:	9081                	srli	s1,s1,0x20
    80003712:	048a                	slli	s1,s1,0x2
    80003714:	94aa                	add	s1,s1,a0
    80003716:	0504a983          	lw	s3,80(s1)
    8000371a:	fe0990e3          	bnez	s3,800036fa <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    8000371e:	4108                	lw	a0,0(a0)
    80003720:	00000097          	auipc	ra,0x0
    80003724:	e4a080e7          	jalr	-438(ra) # 8000356a <balloc>
    80003728:	0005099b          	sext.w	s3,a0
    8000372c:	0534a823          	sw	s3,80(s1)
    80003730:	b7e9                	j	800036fa <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    80003732:	4108                	lw	a0,0(a0)
    80003734:	00000097          	auipc	ra,0x0
    80003738:	e36080e7          	jalr	-458(ra) # 8000356a <balloc>
    8000373c:	0005059b          	sext.w	a1,a0
    80003740:	08b92023          	sw	a1,128(s2)
    80003744:	b759                	j	800036ca <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    80003746:	00092503          	lw	a0,0(s2)
    8000374a:	00000097          	auipc	ra,0x0
    8000374e:	e20080e7          	jalr	-480(ra) # 8000356a <balloc>
    80003752:	0005099b          	sext.w	s3,a0
    80003756:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    8000375a:	8552                	mv	a0,s4
    8000375c:	00001097          	auipc	ra,0x1
    80003760:	ef8080e7          	jalr	-264(ra) # 80004654 <log_write>
    80003764:	b771                	j	800036f0 <bmap+0x54>
  panic("bmap: out of range");
    80003766:	00005517          	auipc	a0,0x5
    8000376a:	e1a50513          	addi	a0,a0,-486 # 80008580 <syscalls+0x128>
    8000376e:	ffffd097          	auipc	ra,0xffffd
    80003772:	dd0080e7          	jalr	-560(ra) # 8000053e <panic>

0000000080003776 <iget>:
{
    80003776:	7179                	addi	sp,sp,-48
    80003778:	f406                	sd	ra,40(sp)
    8000377a:	f022                	sd	s0,32(sp)
    8000377c:	ec26                	sd	s1,24(sp)
    8000377e:	e84a                	sd	s2,16(sp)
    80003780:	e44e                	sd	s3,8(sp)
    80003782:	e052                	sd	s4,0(sp)
    80003784:	1800                	addi	s0,sp,48
    80003786:	89aa                	mv	s3,a0
    80003788:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    8000378a:	0001d517          	auipc	a0,0x1d
    8000378e:	85e50513          	addi	a0,a0,-1954 # 8001ffe8 <itable>
    80003792:	ffffd097          	auipc	ra,0xffffd
    80003796:	452080e7          	jalr	1106(ra) # 80000be4 <acquire>
  empty = 0;
    8000379a:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    8000379c:	0001d497          	auipc	s1,0x1d
    800037a0:	86448493          	addi	s1,s1,-1948 # 80020000 <itable+0x18>
    800037a4:	0001e697          	auipc	a3,0x1e
    800037a8:	2ec68693          	addi	a3,a3,748 # 80021a90 <log>
    800037ac:	a039                	j	800037ba <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800037ae:	02090b63          	beqz	s2,800037e4 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800037b2:	08848493          	addi	s1,s1,136
    800037b6:	02d48a63          	beq	s1,a3,800037ea <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    800037ba:	449c                	lw	a5,8(s1)
    800037bc:	fef059e3          	blez	a5,800037ae <iget+0x38>
    800037c0:	4098                	lw	a4,0(s1)
    800037c2:	ff3716e3          	bne	a4,s3,800037ae <iget+0x38>
    800037c6:	40d8                	lw	a4,4(s1)
    800037c8:	ff4713e3          	bne	a4,s4,800037ae <iget+0x38>
      ip->ref++;
    800037cc:	2785                	addiw	a5,a5,1
    800037ce:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    800037d0:	0001d517          	auipc	a0,0x1d
    800037d4:	81850513          	addi	a0,a0,-2024 # 8001ffe8 <itable>
    800037d8:	ffffd097          	auipc	ra,0xffffd
    800037dc:	4c0080e7          	jalr	1216(ra) # 80000c98 <release>
      return ip;
    800037e0:	8926                	mv	s2,s1
    800037e2:	a03d                	j	80003810 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800037e4:	f7f9                	bnez	a5,800037b2 <iget+0x3c>
    800037e6:	8926                	mv	s2,s1
    800037e8:	b7e9                	j	800037b2 <iget+0x3c>
  if(empty == 0)
    800037ea:	02090c63          	beqz	s2,80003822 <iget+0xac>
  ip->dev = dev;
    800037ee:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    800037f2:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    800037f6:	4785                	li	a5,1
    800037f8:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    800037fc:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80003800:	0001c517          	auipc	a0,0x1c
    80003804:	7e850513          	addi	a0,a0,2024 # 8001ffe8 <itable>
    80003808:	ffffd097          	auipc	ra,0xffffd
    8000380c:	490080e7          	jalr	1168(ra) # 80000c98 <release>
}
    80003810:	854a                	mv	a0,s2
    80003812:	70a2                	ld	ra,40(sp)
    80003814:	7402                	ld	s0,32(sp)
    80003816:	64e2                	ld	s1,24(sp)
    80003818:	6942                	ld	s2,16(sp)
    8000381a:	69a2                	ld	s3,8(sp)
    8000381c:	6a02                	ld	s4,0(sp)
    8000381e:	6145                	addi	sp,sp,48
    80003820:	8082                	ret
    panic("iget: no inodes");
    80003822:	00005517          	auipc	a0,0x5
    80003826:	d7650513          	addi	a0,a0,-650 # 80008598 <syscalls+0x140>
    8000382a:	ffffd097          	auipc	ra,0xffffd
    8000382e:	d14080e7          	jalr	-748(ra) # 8000053e <panic>

0000000080003832 <fsinit>:
fsinit(int dev) {
    80003832:	7179                	addi	sp,sp,-48
    80003834:	f406                	sd	ra,40(sp)
    80003836:	f022                	sd	s0,32(sp)
    80003838:	ec26                	sd	s1,24(sp)
    8000383a:	e84a                	sd	s2,16(sp)
    8000383c:	e44e                	sd	s3,8(sp)
    8000383e:	1800                	addi	s0,sp,48
    80003840:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003842:	4585                	li	a1,1
    80003844:	00000097          	auipc	ra,0x0
    80003848:	a64080e7          	jalr	-1436(ra) # 800032a8 <bread>
    8000384c:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    8000384e:	0001c997          	auipc	s3,0x1c
    80003852:	77a98993          	addi	s3,s3,1914 # 8001ffc8 <sb>
    80003856:	02000613          	li	a2,32
    8000385a:	05850593          	addi	a1,a0,88
    8000385e:	854e                	mv	a0,s3
    80003860:	ffffd097          	auipc	ra,0xffffd
    80003864:	4e0080e7          	jalr	1248(ra) # 80000d40 <memmove>
  brelse(bp);
    80003868:	8526                	mv	a0,s1
    8000386a:	00000097          	auipc	ra,0x0
    8000386e:	b6e080e7          	jalr	-1170(ra) # 800033d8 <brelse>
  if(sb.magic != FSMAGIC)
    80003872:	0009a703          	lw	a4,0(s3)
    80003876:	102037b7          	lui	a5,0x10203
    8000387a:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    8000387e:	02f71263          	bne	a4,a5,800038a2 <fsinit+0x70>
  initlog(dev, &sb);
    80003882:	0001c597          	auipc	a1,0x1c
    80003886:	74658593          	addi	a1,a1,1862 # 8001ffc8 <sb>
    8000388a:	854a                	mv	a0,s2
    8000388c:	00001097          	auipc	ra,0x1
    80003890:	b4c080e7          	jalr	-1204(ra) # 800043d8 <initlog>
}
    80003894:	70a2                	ld	ra,40(sp)
    80003896:	7402                	ld	s0,32(sp)
    80003898:	64e2                	ld	s1,24(sp)
    8000389a:	6942                	ld	s2,16(sp)
    8000389c:	69a2                	ld	s3,8(sp)
    8000389e:	6145                	addi	sp,sp,48
    800038a0:	8082                	ret
    panic("invalid file system");
    800038a2:	00005517          	auipc	a0,0x5
    800038a6:	d0650513          	addi	a0,a0,-762 # 800085a8 <syscalls+0x150>
    800038aa:	ffffd097          	auipc	ra,0xffffd
    800038ae:	c94080e7          	jalr	-876(ra) # 8000053e <panic>

00000000800038b2 <iinit>:
{
    800038b2:	7179                	addi	sp,sp,-48
    800038b4:	f406                	sd	ra,40(sp)
    800038b6:	f022                	sd	s0,32(sp)
    800038b8:	ec26                	sd	s1,24(sp)
    800038ba:	e84a                	sd	s2,16(sp)
    800038bc:	e44e                	sd	s3,8(sp)
    800038be:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    800038c0:	00005597          	auipc	a1,0x5
    800038c4:	d0058593          	addi	a1,a1,-768 # 800085c0 <syscalls+0x168>
    800038c8:	0001c517          	auipc	a0,0x1c
    800038cc:	72050513          	addi	a0,a0,1824 # 8001ffe8 <itable>
    800038d0:	ffffd097          	auipc	ra,0xffffd
    800038d4:	284080e7          	jalr	644(ra) # 80000b54 <initlock>
  for(i = 0; i < NINODE; i++) {
    800038d8:	0001c497          	auipc	s1,0x1c
    800038dc:	73848493          	addi	s1,s1,1848 # 80020010 <itable+0x28>
    800038e0:	0001e997          	auipc	s3,0x1e
    800038e4:	1c098993          	addi	s3,s3,448 # 80021aa0 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    800038e8:	00005917          	auipc	s2,0x5
    800038ec:	ce090913          	addi	s2,s2,-800 # 800085c8 <syscalls+0x170>
    800038f0:	85ca                	mv	a1,s2
    800038f2:	8526                	mv	a0,s1
    800038f4:	00001097          	auipc	ra,0x1
    800038f8:	e46080e7          	jalr	-442(ra) # 8000473a <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    800038fc:	08848493          	addi	s1,s1,136
    80003900:	ff3498e3          	bne	s1,s3,800038f0 <iinit+0x3e>
}
    80003904:	70a2                	ld	ra,40(sp)
    80003906:	7402                	ld	s0,32(sp)
    80003908:	64e2                	ld	s1,24(sp)
    8000390a:	6942                	ld	s2,16(sp)
    8000390c:	69a2                	ld	s3,8(sp)
    8000390e:	6145                	addi	sp,sp,48
    80003910:	8082                	ret

0000000080003912 <ialloc>:
{
    80003912:	715d                	addi	sp,sp,-80
    80003914:	e486                	sd	ra,72(sp)
    80003916:	e0a2                	sd	s0,64(sp)
    80003918:	fc26                	sd	s1,56(sp)
    8000391a:	f84a                	sd	s2,48(sp)
    8000391c:	f44e                	sd	s3,40(sp)
    8000391e:	f052                	sd	s4,32(sp)
    80003920:	ec56                	sd	s5,24(sp)
    80003922:	e85a                	sd	s6,16(sp)
    80003924:	e45e                	sd	s7,8(sp)
    80003926:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003928:	0001c717          	auipc	a4,0x1c
    8000392c:	6ac72703          	lw	a4,1708(a4) # 8001ffd4 <sb+0xc>
    80003930:	4785                	li	a5,1
    80003932:	04e7fa63          	bgeu	a5,a4,80003986 <ialloc+0x74>
    80003936:	8aaa                	mv	s5,a0
    80003938:	8bae                	mv	s7,a1
    8000393a:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    8000393c:	0001ca17          	auipc	s4,0x1c
    80003940:	68ca0a13          	addi	s4,s4,1676 # 8001ffc8 <sb>
    80003944:	00048b1b          	sext.w	s6,s1
    80003948:	0044d593          	srli	a1,s1,0x4
    8000394c:	018a2783          	lw	a5,24(s4)
    80003950:	9dbd                	addw	a1,a1,a5
    80003952:	8556                	mv	a0,s5
    80003954:	00000097          	auipc	ra,0x0
    80003958:	954080e7          	jalr	-1708(ra) # 800032a8 <bread>
    8000395c:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    8000395e:	05850993          	addi	s3,a0,88
    80003962:	00f4f793          	andi	a5,s1,15
    80003966:	079a                	slli	a5,a5,0x6
    80003968:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    8000396a:	00099783          	lh	a5,0(s3)
    8000396e:	c785                	beqz	a5,80003996 <ialloc+0x84>
    brelse(bp);
    80003970:	00000097          	auipc	ra,0x0
    80003974:	a68080e7          	jalr	-1432(ra) # 800033d8 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003978:	0485                	addi	s1,s1,1
    8000397a:	00ca2703          	lw	a4,12(s4)
    8000397e:	0004879b          	sext.w	a5,s1
    80003982:	fce7e1e3          	bltu	a5,a4,80003944 <ialloc+0x32>
  panic("ialloc: no inodes");
    80003986:	00005517          	auipc	a0,0x5
    8000398a:	c4a50513          	addi	a0,a0,-950 # 800085d0 <syscalls+0x178>
    8000398e:	ffffd097          	auipc	ra,0xffffd
    80003992:	bb0080e7          	jalr	-1104(ra) # 8000053e <panic>
      memset(dip, 0, sizeof(*dip));
    80003996:	04000613          	li	a2,64
    8000399a:	4581                	li	a1,0
    8000399c:	854e                	mv	a0,s3
    8000399e:	ffffd097          	auipc	ra,0xffffd
    800039a2:	342080e7          	jalr	834(ra) # 80000ce0 <memset>
      dip->type = type;
    800039a6:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    800039aa:	854a                	mv	a0,s2
    800039ac:	00001097          	auipc	ra,0x1
    800039b0:	ca8080e7          	jalr	-856(ra) # 80004654 <log_write>
      brelse(bp);
    800039b4:	854a                	mv	a0,s2
    800039b6:	00000097          	auipc	ra,0x0
    800039ba:	a22080e7          	jalr	-1502(ra) # 800033d8 <brelse>
      return iget(dev, inum);
    800039be:	85da                	mv	a1,s6
    800039c0:	8556                	mv	a0,s5
    800039c2:	00000097          	auipc	ra,0x0
    800039c6:	db4080e7          	jalr	-588(ra) # 80003776 <iget>
}
    800039ca:	60a6                	ld	ra,72(sp)
    800039cc:	6406                	ld	s0,64(sp)
    800039ce:	74e2                	ld	s1,56(sp)
    800039d0:	7942                	ld	s2,48(sp)
    800039d2:	79a2                	ld	s3,40(sp)
    800039d4:	7a02                	ld	s4,32(sp)
    800039d6:	6ae2                	ld	s5,24(sp)
    800039d8:	6b42                	ld	s6,16(sp)
    800039da:	6ba2                	ld	s7,8(sp)
    800039dc:	6161                	addi	sp,sp,80
    800039de:	8082                	ret

00000000800039e0 <iupdate>:
{
    800039e0:	1101                	addi	sp,sp,-32
    800039e2:	ec06                	sd	ra,24(sp)
    800039e4:	e822                	sd	s0,16(sp)
    800039e6:	e426                	sd	s1,8(sp)
    800039e8:	e04a                	sd	s2,0(sp)
    800039ea:	1000                	addi	s0,sp,32
    800039ec:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800039ee:	415c                	lw	a5,4(a0)
    800039f0:	0047d79b          	srliw	a5,a5,0x4
    800039f4:	0001c597          	auipc	a1,0x1c
    800039f8:	5ec5a583          	lw	a1,1516(a1) # 8001ffe0 <sb+0x18>
    800039fc:	9dbd                	addw	a1,a1,a5
    800039fe:	4108                	lw	a0,0(a0)
    80003a00:	00000097          	auipc	ra,0x0
    80003a04:	8a8080e7          	jalr	-1880(ra) # 800032a8 <bread>
    80003a08:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003a0a:	05850793          	addi	a5,a0,88
    80003a0e:	40c8                	lw	a0,4(s1)
    80003a10:	893d                	andi	a0,a0,15
    80003a12:	051a                	slli	a0,a0,0x6
    80003a14:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    80003a16:	04449703          	lh	a4,68(s1)
    80003a1a:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    80003a1e:	04649703          	lh	a4,70(s1)
    80003a22:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    80003a26:	04849703          	lh	a4,72(s1)
    80003a2a:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    80003a2e:	04a49703          	lh	a4,74(s1)
    80003a32:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    80003a36:	44f8                	lw	a4,76(s1)
    80003a38:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003a3a:	03400613          	li	a2,52
    80003a3e:	05048593          	addi	a1,s1,80
    80003a42:	0531                	addi	a0,a0,12
    80003a44:	ffffd097          	auipc	ra,0xffffd
    80003a48:	2fc080e7          	jalr	764(ra) # 80000d40 <memmove>
  log_write(bp);
    80003a4c:	854a                	mv	a0,s2
    80003a4e:	00001097          	auipc	ra,0x1
    80003a52:	c06080e7          	jalr	-1018(ra) # 80004654 <log_write>
  brelse(bp);
    80003a56:	854a                	mv	a0,s2
    80003a58:	00000097          	auipc	ra,0x0
    80003a5c:	980080e7          	jalr	-1664(ra) # 800033d8 <brelse>
}
    80003a60:	60e2                	ld	ra,24(sp)
    80003a62:	6442                	ld	s0,16(sp)
    80003a64:	64a2                	ld	s1,8(sp)
    80003a66:	6902                	ld	s2,0(sp)
    80003a68:	6105                	addi	sp,sp,32
    80003a6a:	8082                	ret

0000000080003a6c <idup>:
{
    80003a6c:	1101                	addi	sp,sp,-32
    80003a6e:	ec06                	sd	ra,24(sp)
    80003a70:	e822                	sd	s0,16(sp)
    80003a72:	e426                	sd	s1,8(sp)
    80003a74:	1000                	addi	s0,sp,32
    80003a76:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003a78:	0001c517          	auipc	a0,0x1c
    80003a7c:	57050513          	addi	a0,a0,1392 # 8001ffe8 <itable>
    80003a80:	ffffd097          	auipc	ra,0xffffd
    80003a84:	164080e7          	jalr	356(ra) # 80000be4 <acquire>
  ip->ref++;
    80003a88:	449c                	lw	a5,8(s1)
    80003a8a:	2785                	addiw	a5,a5,1
    80003a8c:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003a8e:	0001c517          	auipc	a0,0x1c
    80003a92:	55a50513          	addi	a0,a0,1370 # 8001ffe8 <itable>
    80003a96:	ffffd097          	auipc	ra,0xffffd
    80003a9a:	202080e7          	jalr	514(ra) # 80000c98 <release>
}
    80003a9e:	8526                	mv	a0,s1
    80003aa0:	60e2                	ld	ra,24(sp)
    80003aa2:	6442                	ld	s0,16(sp)
    80003aa4:	64a2                	ld	s1,8(sp)
    80003aa6:	6105                	addi	sp,sp,32
    80003aa8:	8082                	ret

0000000080003aaa <ilock>:
{
    80003aaa:	1101                	addi	sp,sp,-32
    80003aac:	ec06                	sd	ra,24(sp)
    80003aae:	e822                	sd	s0,16(sp)
    80003ab0:	e426                	sd	s1,8(sp)
    80003ab2:	e04a                	sd	s2,0(sp)
    80003ab4:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003ab6:	c115                	beqz	a0,80003ada <ilock+0x30>
    80003ab8:	84aa                	mv	s1,a0
    80003aba:	451c                	lw	a5,8(a0)
    80003abc:	00f05f63          	blez	a5,80003ada <ilock+0x30>
  acquiresleep(&ip->lock);
    80003ac0:	0541                	addi	a0,a0,16
    80003ac2:	00001097          	auipc	ra,0x1
    80003ac6:	cb2080e7          	jalr	-846(ra) # 80004774 <acquiresleep>
  if(ip->valid == 0){
    80003aca:	40bc                	lw	a5,64(s1)
    80003acc:	cf99                	beqz	a5,80003aea <ilock+0x40>
}
    80003ace:	60e2                	ld	ra,24(sp)
    80003ad0:	6442                	ld	s0,16(sp)
    80003ad2:	64a2                	ld	s1,8(sp)
    80003ad4:	6902                	ld	s2,0(sp)
    80003ad6:	6105                	addi	sp,sp,32
    80003ad8:	8082                	ret
    panic("ilock");
    80003ada:	00005517          	auipc	a0,0x5
    80003ade:	b0e50513          	addi	a0,a0,-1266 # 800085e8 <syscalls+0x190>
    80003ae2:	ffffd097          	auipc	ra,0xffffd
    80003ae6:	a5c080e7          	jalr	-1444(ra) # 8000053e <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003aea:	40dc                	lw	a5,4(s1)
    80003aec:	0047d79b          	srliw	a5,a5,0x4
    80003af0:	0001c597          	auipc	a1,0x1c
    80003af4:	4f05a583          	lw	a1,1264(a1) # 8001ffe0 <sb+0x18>
    80003af8:	9dbd                	addw	a1,a1,a5
    80003afa:	4088                	lw	a0,0(s1)
    80003afc:	fffff097          	auipc	ra,0xfffff
    80003b00:	7ac080e7          	jalr	1964(ra) # 800032a8 <bread>
    80003b04:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003b06:	05850593          	addi	a1,a0,88
    80003b0a:	40dc                	lw	a5,4(s1)
    80003b0c:	8bbd                	andi	a5,a5,15
    80003b0e:	079a                	slli	a5,a5,0x6
    80003b10:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003b12:	00059783          	lh	a5,0(a1)
    80003b16:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003b1a:	00259783          	lh	a5,2(a1)
    80003b1e:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003b22:	00459783          	lh	a5,4(a1)
    80003b26:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003b2a:	00659783          	lh	a5,6(a1)
    80003b2e:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003b32:	459c                	lw	a5,8(a1)
    80003b34:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003b36:	03400613          	li	a2,52
    80003b3a:	05b1                	addi	a1,a1,12
    80003b3c:	05048513          	addi	a0,s1,80
    80003b40:	ffffd097          	auipc	ra,0xffffd
    80003b44:	200080e7          	jalr	512(ra) # 80000d40 <memmove>
    brelse(bp);
    80003b48:	854a                	mv	a0,s2
    80003b4a:	00000097          	auipc	ra,0x0
    80003b4e:	88e080e7          	jalr	-1906(ra) # 800033d8 <brelse>
    ip->valid = 1;
    80003b52:	4785                	li	a5,1
    80003b54:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003b56:	04449783          	lh	a5,68(s1)
    80003b5a:	fbb5                	bnez	a5,80003ace <ilock+0x24>
      panic("ilock: no type");
    80003b5c:	00005517          	auipc	a0,0x5
    80003b60:	a9450513          	addi	a0,a0,-1388 # 800085f0 <syscalls+0x198>
    80003b64:	ffffd097          	auipc	ra,0xffffd
    80003b68:	9da080e7          	jalr	-1574(ra) # 8000053e <panic>

0000000080003b6c <iunlock>:
{
    80003b6c:	1101                	addi	sp,sp,-32
    80003b6e:	ec06                	sd	ra,24(sp)
    80003b70:	e822                	sd	s0,16(sp)
    80003b72:	e426                	sd	s1,8(sp)
    80003b74:	e04a                	sd	s2,0(sp)
    80003b76:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003b78:	c905                	beqz	a0,80003ba8 <iunlock+0x3c>
    80003b7a:	84aa                	mv	s1,a0
    80003b7c:	01050913          	addi	s2,a0,16
    80003b80:	854a                	mv	a0,s2
    80003b82:	00001097          	auipc	ra,0x1
    80003b86:	c8c080e7          	jalr	-884(ra) # 8000480e <holdingsleep>
    80003b8a:	cd19                	beqz	a0,80003ba8 <iunlock+0x3c>
    80003b8c:	449c                	lw	a5,8(s1)
    80003b8e:	00f05d63          	blez	a5,80003ba8 <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003b92:	854a                	mv	a0,s2
    80003b94:	00001097          	auipc	ra,0x1
    80003b98:	c36080e7          	jalr	-970(ra) # 800047ca <releasesleep>
}
    80003b9c:	60e2                	ld	ra,24(sp)
    80003b9e:	6442                	ld	s0,16(sp)
    80003ba0:	64a2                	ld	s1,8(sp)
    80003ba2:	6902                	ld	s2,0(sp)
    80003ba4:	6105                	addi	sp,sp,32
    80003ba6:	8082                	ret
    panic("iunlock");
    80003ba8:	00005517          	auipc	a0,0x5
    80003bac:	a5850513          	addi	a0,a0,-1448 # 80008600 <syscalls+0x1a8>
    80003bb0:	ffffd097          	auipc	ra,0xffffd
    80003bb4:	98e080e7          	jalr	-1650(ra) # 8000053e <panic>

0000000080003bb8 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003bb8:	7179                	addi	sp,sp,-48
    80003bba:	f406                	sd	ra,40(sp)
    80003bbc:	f022                	sd	s0,32(sp)
    80003bbe:	ec26                	sd	s1,24(sp)
    80003bc0:	e84a                	sd	s2,16(sp)
    80003bc2:	e44e                	sd	s3,8(sp)
    80003bc4:	e052                	sd	s4,0(sp)
    80003bc6:	1800                	addi	s0,sp,48
    80003bc8:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003bca:	05050493          	addi	s1,a0,80
    80003bce:	08050913          	addi	s2,a0,128
    80003bd2:	a021                	j	80003bda <itrunc+0x22>
    80003bd4:	0491                	addi	s1,s1,4
    80003bd6:	01248d63          	beq	s1,s2,80003bf0 <itrunc+0x38>
    if(ip->addrs[i]){
    80003bda:	408c                	lw	a1,0(s1)
    80003bdc:	dde5                	beqz	a1,80003bd4 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003bde:	0009a503          	lw	a0,0(s3)
    80003be2:	00000097          	auipc	ra,0x0
    80003be6:	90c080e7          	jalr	-1780(ra) # 800034ee <bfree>
      ip->addrs[i] = 0;
    80003bea:	0004a023          	sw	zero,0(s1)
    80003bee:	b7dd                	j	80003bd4 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003bf0:	0809a583          	lw	a1,128(s3)
    80003bf4:	e185                	bnez	a1,80003c14 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003bf6:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003bfa:	854e                	mv	a0,s3
    80003bfc:	00000097          	auipc	ra,0x0
    80003c00:	de4080e7          	jalr	-540(ra) # 800039e0 <iupdate>
}
    80003c04:	70a2                	ld	ra,40(sp)
    80003c06:	7402                	ld	s0,32(sp)
    80003c08:	64e2                	ld	s1,24(sp)
    80003c0a:	6942                	ld	s2,16(sp)
    80003c0c:	69a2                	ld	s3,8(sp)
    80003c0e:	6a02                	ld	s4,0(sp)
    80003c10:	6145                	addi	sp,sp,48
    80003c12:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003c14:	0009a503          	lw	a0,0(s3)
    80003c18:	fffff097          	auipc	ra,0xfffff
    80003c1c:	690080e7          	jalr	1680(ra) # 800032a8 <bread>
    80003c20:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003c22:	05850493          	addi	s1,a0,88
    80003c26:	45850913          	addi	s2,a0,1112
    80003c2a:	a811                	j	80003c3e <itrunc+0x86>
        bfree(ip->dev, a[j]);
    80003c2c:	0009a503          	lw	a0,0(s3)
    80003c30:	00000097          	auipc	ra,0x0
    80003c34:	8be080e7          	jalr	-1858(ra) # 800034ee <bfree>
    for(j = 0; j < NINDIRECT; j++){
    80003c38:	0491                	addi	s1,s1,4
    80003c3a:	01248563          	beq	s1,s2,80003c44 <itrunc+0x8c>
      if(a[j])
    80003c3e:	408c                	lw	a1,0(s1)
    80003c40:	dde5                	beqz	a1,80003c38 <itrunc+0x80>
    80003c42:	b7ed                	j	80003c2c <itrunc+0x74>
    brelse(bp);
    80003c44:	8552                	mv	a0,s4
    80003c46:	fffff097          	auipc	ra,0xfffff
    80003c4a:	792080e7          	jalr	1938(ra) # 800033d8 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003c4e:	0809a583          	lw	a1,128(s3)
    80003c52:	0009a503          	lw	a0,0(s3)
    80003c56:	00000097          	auipc	ra,0x0
    80003c5a:	898080e7          	jalr	-1896(ra) # 800034ee <bfree>
    ip->addrs[NDIRECT] = 0;
    80003c5e:	0809a023          	sw	zero,128(s3)
    80003c62:	bf51                	j	80003bf6 <itrunc+0x3e>

0000000080003c64 <iput>:
{
    80003c64:	1101                	addi	sp,sp,-32
    80003c66:	ec06                	sd	ra,24(sp)
    80003c68:	e822                	sd	s0,16(sp)
    80003c6a:	e426                	sd	s1,8(sp)
    80003c6c:	e04a                	sd	s2,0(sp)
    80003c6e:	1000                	addi	s0,sp,32
    80003c70:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003c72:	0001c517          	auipc	a0,0x1c
    80003c76:	37650513          	addi	a0,a0,886 # 8001ffe8 <itable>
    80003c7a:	ffffd097          	auipc	ra,0xffffd
    80003c7e:	f6a080e7          	jalr	-150(ra) # 80000be4 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003c82:	4498                	lw	a4,8(s1)
    80003c84:	4785                	li	a5,1
    80003c86:	02f70363          	beq	a4,a5,80003cac <iput+0x48>
  ip->ref--;
    80003c8a:	449c                	lw	a5,8(s1)
    80003c8c:	37fd                	addiw	a5,a5,-1
    80003c8e:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003c90:	0001c517          	auipc	a0,0x1c
    80003c94:	35850513          	addi	a0,a0,856 # 8001ffe8 <itable>
    80003c98:	ffffd097          	auipc	ra,0xffffd
    80003c9c:	000080e7          	jalr	ra # 80000c98 <release>
}
    80003ca0:	60e2                	ld	ra,24(sp)
    80003ca2:	6442                	ld	s0,16(sp)
    80003ca4:	64a2                	ld	s1,8(sp)
    80003ca6:	6902                	ld	s2,0(sp)
    80003ca8:	6105                	addi	sp,sp,32
    80003caa:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003cac:	40bc                	lw	a5,64(s1)
    80003cae:	dff1                	beqz	a5,80003c8a <iput+0x26>
    80003cb0:	04a49783          	lh	a5,74(s1)
    80003cb4:	fbf9                	bnez	a5,80003c8a <iput+0x26>
    acquiresleep(&ip->lock);
    80003cb6:	01048913          	addi	s2,s1,16
    80003cba:	854a                	mv	a0,s2
    80003cbc:	00001097          	auipc	ra,0x1
    80003cc0:	ab8080e7          	jalr	-1352(ra) # 80004774 <acquiresleep>
    release(&itable.lock);
    80003cc4:	0001c517          	auipc	a0,0x1c
    80003cc8:	32450513          	addi	a0,a0,804 # 8001ffe8 <itable>
    80003ccc:	ffffd097          	auipc	ra,0xffffd
    80003cd0:	fcc080e7          	jalr	-52(ra) # 80000c98 <release>
    itrunc(ip);
    80003cd4:	8526                	mv	a0,s1
    80003cd6:	00000097          	auipc	ra,0x0
    80003cda:	ee2080e7          	jalr	-286(ra) # 80003bb8 <itrunc>
    ip->type = 0;
    80003cde:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003ce2:	8526                	mv	a0,s1
    80003ce4:	00000097          	auipc	ra,0x0
    80003ce8:	cfc080e7          	jalr	-772(ra) # 800039e0 <iupdate>
    ip->valid = 0;
    80003cec:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003cf0:	854a                	mv	a0,s2
    80003cf2:	00001097          	auipc	ra,0x1
    80003cf6:	ad8080e7          	jalr	-1320(ra) # 800047ca <releasesleep>
    acquire(&itable.lock);
    80003cfa:	0001c517          	auipc	a0,0x1c
    80003cfe:	2ee50513          	addi	a0,a0,750 # 8001ffe8 <itable>
    80003d02:	ffffd097          	auipc	ra,0xffffd
    80003d06:	ee2080e7          	jalr	-286(ra) # 80000be4 <acquire>
    80003d0a:	b741                	j	80003c8a <iput+0x26>

0000000080003d0c <iunlockput>:
{
    80003d0c:	1101                	addi	sp,sp,-32
    80003d0e:	ec06                	sd	ra,24(sp)
    80003d10:	e822                	sd	s0,16(sp)
    80003d12:	e426                	sd	s1,8(sp)
    80003d14:	1000                	addi	s0,sp,32
    80003d16:	84aa                	mv	s1,a0
  iunlock(ip);
    80003d18:	00000097          	auipc	ra,0x0
    80003d1c:	e54080e7          	jalr	-428(ra) # 80003b6c <iunlock>
  iput(ip);
    80003d20:	8526                	mv	a0,s1
    80003d22:	00000097          	auipc	ra,0x0
    80003d26:	f42080e7          	jalr	-190(ra) # 80003c64 <iput>
}
    80003d2a:	60e2                	ld	ra,24(sp)
    80003d2c:	6442                	ld	s0,16(sp)
    80003d2e:	64a2                	ld	s1,8(sp)
    80003d30:	6105                	addi	sp,sp,32
    80003d32:	8082                	ret

0000000080003d34 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003d34:	1141                	addi	sp,sp,-16
    80003d36:	e422                	sd	s0,8(sp)
    80003d38:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003d3a:	411c                	lw	a5,0(a0)
    80003d3c:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003d3e:	415c                	lw	a5,4(a0)
    80003d40:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003d42:	04451783          	lh	a5,68(a0)
    80003d46:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003d4a:	04a51783          	lh	a5,74(a0)
    80003d4e:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003d52:	04c56783          	lwu	a5,76(a0)
    80003d56:	e99c                	sd	a5,16(a1)
}
    80003d58:	6422                	ld	s0,8(sp)
    80003d5a:	0141                	addi	sp,sp,16
    80003d5c:	8082                	ret

0000000080003d5e <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003d5e:	457c                	lw	a5,76(a0)
    80003d60:	0ed7e963          	bltu	a5,a3,80003e52 <readi+0xf4>
{
    80003d64:	7159                	addi	sp,sp,-112
    80003d66:	f486                	sd	ra,104(sp)
    80003d68:	f0a2                	sd	s0,96(sp)
    80003d6a:	eca6                	sd	s1,88(sp)
    80003d6c:	e8ca                	sd	s2,80(sp)
    80003d6e:	e4ce                	sd	s3,72(sp)
    80003d70:	e0d2                	sd	s4,64(sp)
    80003d72:	fc56                	sd	s5,56(sp)
    80003d74:	f85a                	sd	s6,48(sp)
    80003d76:	f45e                	sd	s7,40(sp)
    80003d78:	f062                	sd	s8,32(sp)
    80003d7a:	ec66                	sd	s9,24(sp)
    80003d7c:	e86a                	sd	s10,16(sp)
    80003d7e:	e46e                	sd	s11,8(sp)
    80003d80:	1880                	addi	s0,sp,112
    80003d82:	8baa                	mv	s7,a0
    80003d84:	8c2e                	mv	s8,a1
    80003d86:	8ab2                	mv	s5,a2
    80003d88:	84b6                	mv	s1,a3
    80003d8a:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003d8c:	9f35                	addw	a4,a4,a3
    return 0;
    80003d8e:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003d90:	0ad76063          	bltu	a4,a3,80003e30 <readi+0xd2>
  if(off + n > ip->size)
    80003d94:	00e7f463          	bgeu	a5,a4,80003d9c <readi+0x3e>
    n = ip->size - off;
    80003d98:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003d9c:	0a0b0963          	beqz	s6,80003e4e <readi+0xf0>
    80003da0:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003da2:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003da6:	5cfd                	li	s9,-1
    80003da8:	a82d                	j	80003de2 <readi+0x84>
    80003daa:	020a1d93          	slli	s11,s4,0x20
    80003dae:	020ddd93          	srli	s11,s11,0x20
    80003db2:	05890613          	addi	a2,s2,88
    80003db6:	86ee                	mv	a3,s11
    80003db8:	963a                	add	a2,a2,a4
    80003dba:	85d6                	mv	a1,s5
    80003dbc:	8562                	mv	a0,s8
    80003dbe:	fffff097          	auipc	ra,0xfffff
    80003dc2:	ae0080e7          	jalr	-1312(ra) # 8000289e <either_copyout>
    80003dc6:	05950d63          	beq	a0,s9,80003e20 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003dca:	854a                	mv	a0,s2
    80003dcc:	fffff097          	auipc	ra,0xfffff
    80003dd0:	60c080e7          	jalr	1548(ra) # 800033d8 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003dd4:	013a09bb          	addw	s3,s4,s3
    80003dd8:	009a04bb          	addw	s1,s4,s1
    80003ddc:	9aee                	add	s5,s5,s11
    80003dde:	0569f763          	bgeu	s3,s6,80003e2c <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003de2:	000ba903          	lw	s2,0(s7)
    80003de6:	00a4d59b          	srliw	a1,s1,0xa
    80003dea:	855e                	mv	a0,s7
    80003dec:	00000097          	auipc	ra,0x0
    80003df0:	8b0080e7          	jalr	-1872(ra) # 8000369c <bmap>
    80003df4:	0005059b          	sext.w	a1,a0
    80003df8:	854a                	mv	a0,s2
    80003dfa:	fffff097          	auipc	ra,0xfffff
    80003dfe:	4ae080e7          	jalr	1198(ra) # 800032a8 <bread>
    80003e02:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003e04:	3ff4f713          	andi	a4,s1,1023
    80003e08:	40ed07bb          	subw	a5,s10,a4
    80003e0c:	413b06bb          	subw	a3,s6,s3
    80003e10:	8a3e                	mv	s4,a5
    80003e12:	2781                	sext.w	a5,a5
    80003e14:	0006861b          	sext.w	a2,a3
    80003e18:	f8f679e3          	bgeu	a2,a5,80003daa <readi+0x4c>
    80003e1c:	8a36                	mv	s4,a3
    80003e1e:	b771                	j	80003daa <readi+0x4c>
      brelse(bp);
    80003e20:	854a                	mv	a0,s2
    80003e22:	fffff097          	auipc	ra,0xfffff
    80003e26:	5b6080e7          	jalr	1462(ra) # 800033d8 <brelse>
      tot = -1;
    80003e2a:	59fd                	li	s3,-1
  }
  return tot;
    80003e2c:	0009851b          	sext.w	a0,s3
}
    80003e30:	70a6                	ld	ra,104(sp)
    80003e32:	7406                	ld	s0,96(sp)
    80003e34:	64e6                	ld	s1,88(sp)
    80003e36:	6946                	ld	s2,80(sp)
    80003e38:	69a6                	ld	s3,72(sp)
    80003e3a:	6a06                	ld	s4,64(sp)
    80003e3c:	7ae2                	ld	s5,56(sp)
    80003e3e:	7b42                	ld	s6,48(sp)
    80003e40:	7ba2                	ld	s7,40(sp)
    80003e42:	7c02                	ld	s8,32(sp)
    80003e44:	6ce2                	ld	s9,24(sp)
    80003e46:	6d42                	ld	s10,16(sp)
    80003e48:	6da2                	ld	s11,8(sp)
    80003e4a:	6165                	addi	sp,sp,112
    80003e4c:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003e4e:	89da                	mv	s3,s6
    80003e50:	bff1                	j	80003e2c <readi+0xce>
    return 0;
    80003e52:	4501                	li	a0,0
}
    80003e54:	8082                	ret

0000000080003e56 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003e56:	457c                	lw	a5,76(a0)
    80003e58:	10d7e863          	bltu	a5,a3,80003f68 <writei+0x112>
{
    80003e5c:	7159                	addi	sp,sp,-112
    80003e5e:	f486                	sd	ra,104(sp)
    80003e60:	f0a2                	sd	s0,96(sp)
    80003e62:	eca6                	sd	s1,88(sp)
    80003e64:	e8ca                	sd	s2,80(sp)
    80003e66:	e4ce                	sd	s3,72(sp)
    80003e68:	e0d2                	sd	s4,64(sp)
    80003e6a:	fc56                	sd	s5,56(sp)
    80003e6c:	f85a                	sd	s6,48(sp)
    80003e6e:	f45e                	sd	s7,40(sp)
    80003e70:	f062                	sd	s8,32(sp)
    80003e72:	ec66                	sd	s9,24(sp)
    80003e74:	e86a                	sd	s10,16(sp)
    80003e76:	e46e                	sd	s11,8(sp)
    80003e78:	1880                	addi	s0,sp,112
    80003e7a:	8b2a                	mv	s6,a0
    80003e7c:	8c2e                	mv	s8,a1
    80003e7e:	8ab2                	mv	s5,a2
    80003e80:	8936                	mv	s2,a3
    80003e82:	8bba                	mv	s7,a4
  if(off > ip->size || off + n < off)
    80003e84:	00e687bb          	addw	a5,a3,a4
    80003e88:	0ed7e263          	bltu	a5,a3,80003f6c <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003e8c:	00043737          	lui	a4,0x43
    80003e90:	0ef76063          	bltu	a4,a5,80003f70 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003e94:	0c0b8863          	beqz	s7,80003f64 <writei+0x10e>
    80003e98:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003e9a:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003e9e:	5cfd                	li	s9,-1
    80003ea0:	a091                	j	80003ee4 <writei+0x8e>
    80003ea2:	02099d93          	slli	s11,s3,0x20
    80003ea6:	020ddd93          	srli	s11,s11,0x20
    80003eaa:	05848513          	addi	a0,s1,88
    80003eae:	86ee                	mv	a3,s11
    80003eb0:	8656                	mv	a2,s5
    80003eb2:	85e2                	mv	a1,s8
    80003eb4:	953a                	add	a0,a0,a4
    80003eb6:	fffff097          	auipc	ra,0xfffff
    80003eba:	a3e080e7          	jalr	-1474(ra) # 800028f4 <either_copyin>
    80003ebe:	07950263          	beq	a0,s9,80003f22 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003ec2:	8526                	mv	a0,s1
    80003ec4:	00000097          	auipc	ra,0x0
    80003ec8:	790080e7          	jalr	1936(ra) # 80004654 <log_write>
    brelse(bp);
    80003ecc:	8526                	mv	a0,s1
    80003ece:	fffff097          	auipc	ra,0xfffff
    80003ed2:	50a080e7          	jalr	1290(ra) # 800033d8 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003ed6:	01498a3b          	addw	s4,s3,s4
    80003eda:	0129893b          	addw	s2,s3,s2
    80003ede:	9aee                	add	s5,s5,s11
    80003ee0:	057a7663          	bgeu	s4,s7,80003f2c <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003ee4:	000b2483          	lw	s1,0(s6)
    80003ee8:	00a9559b          	srliw	a1,s2,0xa
    80003eec:	855a                	mv	a0,s6
    80003eee:	fffff097          	auipc	ra,0xfffff
    80003ef2:	7ae080e7          	jalr	1966(ra) # 8000369c <bmap>
    80003ef6:	0005059b          	sext.w	a1,a0
    80003efa:	8526                	mv	a0,s1
    80003efc:	fffff097          	auipc	ra,0xfffff
    80003f00:	3ac080e7          	jalr	940(ra) # 800032a8 <bread>
    80003f04:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003f06:	3ff97713          	andi	a4,s2,1023
    80003f0a:	40ed07bb          	subw	a5,s10,a4
    80003f0e:	414b86bb          	subw	a3,s7,s4
    80003f12:	89be                	mv	s3,a5
    80003f14:	2781                	sext.w	a5,a5
    80003f16:	0006861b          	sext.w	a2,a3
    80003f1a:	f8f674e3          	bgeu	a2,a5,80003ea2 <writei+0x4c>
    80003f1e:	89b6                	mv	s3,a3
    80003f20:	b749                	j	80003ea2 <writei+0x4c>
      brelse(bp);
    80003f22:	8526                	mv	a0,s1
    80003f24:	fffff097          	auipc	ra,0xfffff
    80003f28:	4b4080e7          	jalr	1204(ra) # 800033d8 <brelse>
  }

  if(off > ip->size)
    80003f2c:	04cb2783          	lw	a5,76(s6)
    80003f30:	0127f463          	bgeu	a5,s2,80003f38 <writei+0xe2>
    ip->size = off;
    80003f34:	052b2623          	sw	s2,76(s6)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003f38:	855a                	mv	a0,s6
    80003f3a:	00000097          	auipc	ra,0x0
    80003f3e:	aa6080e7          	jalr	-1370(ra) # 800039e0 <iupdate>

  return tot;
    80003f42:	000a051b          	sext.w	a0,s4
}
    80003f46:	70a6                	ld	ra,104(sp)
    80003f48:	7406                	ld	s0,96(sp)
    80003f4a:	64e6                	ld	s1,88(sp)
    80003f4c:	6946                	ld	s2,80(sp)
    80003f4e:	69a6                	ld	s3,72(sp)
    80003f50:	6a06                	ld	s4,64(sp)
    80003f52:	7ae2                	ld	s5,56(sp)
    80003f54:	7b42                	ld	s6,48(sp)
    80003f56:	7ba2                	ld	s7,40(sp)
    80003f58:	7c02                	ld	s8,32(sp)
    80003f5a:	6ce2                	ld	s9,24(sp)
    80003f5c:	6d42                	ld	s10,16(sp)
    80003f5e:	6da2                	ld	s11,8(sp)
    80003f60:	6165                	addi	sp,sp,112
    80003f62:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003f64:	8a5e                	mv	s4,s7
    80003f66:	bfc9                	j	80003f38 <writei+0xe2>
    return -1;
    80003f68:	557d                	li	a0,-1
}
    80003f6a:	8082                	ret
    return -1;
    80003f6c:	557d                	li	a0,-1
    80003f6e:	bfe1                	j	80003f46 <writei+0xf0>
    return -1;
    80003f70:	557d                	li	a0,-1
    80003f72:	bfd1                	j	80003f46 <writei+0xf0>

0000000080003f74 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003f74:	1141                	addi	sp,sp,-16
    80003f76:	e406                	sd	ra,8(sp)
    80003f78:	e022                	sd	s0,0(sp)
    80003f7a:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003f7c:	4639                	li	a2,14
    80003f7e:	ffffd097          	auipc	ra,0xffffd
    80003f82:	e3a080e7          	jalr	-454(ra) # 80000db8 <strncmp>
}
    80003f86:	60a2                	ld	ra,8(sp)
    80003f88:	6402                	ld	s0,0(sp)
    80003f8a:	0141                	addi	sp,sp,16
    80003f8c:	8082                	ret

0000000080003f8e <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003f8e:	7139                	addi	sp,sp,-64
    80003f90:	fc06                	sd	ra,56(sp)
    80003f92:	f822                	sd	s0,48(sp)
    80003f94:	f426                	sd	s1,40(sp)
    80003f96:	f04a                	sd	s2,32(sp)
    80003f98:	ec4e                	sd	s3,24(sp)
    80003f9a:	e852                	sd	s4,16(sp)
    80003f9c:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003f9e:	04451703          	lh	a4,68(a0)
    80003fa2:	4785                	li	a5,1
    80003fa4:	00f71a63          	bne	a4,a5,80003fb8 <dirlookup+0x2a>
    80003fa8:	892a                	mv	s2,a0
    80003faa:	89ae                	mv	s3,a1
    80003fac:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003fae:	457c                	lw	a5,76(a0)
    80003fb0:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003fb2:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003fb4:	e79d                	bnez	a5,80003fe2 <dirlookup+0x54>
    80003fb6:	a8a5                	j	8000402e <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003fb8:	00004517          	auipc	a0,0x4
    80003fbc:	65050513          	addi	a0,a0,1616 # 80008608 <syscalls+0x1b0>
    80003fc0:	ffffc097          	auipc	ra,0xffffc
    80003fc4:	57e080e7          	jalr	1406(ra) # 8000053e <panic>
      panic("dirlookup read");
    80003fc8:	00004517          	auipc	a0,0x4
    80003fcc:	65850513          	addi	a0,a0,1624 # 80008620 <syscalls+0x1c8>
    80003fd0:	ffffc097          	auipc	ra,0xffffc
    80003fd4:	56e080e7          	jalr	1390(ra) # 8000053e <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003fd8:	24c1                	addiw	s1,s1,16
    80003fda:	04c92783          	lw	a5,76(s2)
    80003fde:	04f4f763          	bgeu	s1,a5,8000402c <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003fe2:	4741                	li	a4,16
    80003fe4:	86a6                	mv	a3,s1
    80003fe6:	fc040613          	addi	a2,s0,-64
    80003fea:	4581                	li	a1,0
    80003fec:	854a                	mv	a0,s2
    80003fee:	00000097          	auipc	ra,0x0
    80003ff2:	d70080e7          	jalr	-656(ra) # 80003d5e <readi>
    80003ff6:	47c1                	li	a5,16
    80003ff8:	fcf518e3          	bne	a0,a5,80003fc8 <dirlookup+0x3a>
    if(de.inum == 0)
    80003ffc:	fc045783          	lhu	a5,-64(s0)
    80004000:	dfe1                	beqz	a5,80003fd8 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80004002:	fc240593          	addi	a1,s0,-62
    80004006:	854e                	mv	a0,s3
    80004008:	00000097          	auipc	ra,0x0
    8000400c:	f6c080e7          	jalr	-148(ra) # 80003f74 <namecmp>
    80004010:	f561                	bnez	a0,80003fd8 <dirlookup+0x4a>
      if(poff)
    80004012:	000a0463          	beqz	s4,8000401a <dirlookup+0x8c>
        *poff = off;
    80004016:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    8000401a:	fc045583          	lhu	a1,-64(s0)
    8000401e:	00092503          	lw	a0,0(s2)
    80004022:	fffff097          	auipc	ra,0xfffff
    80004026:	754080e7          	jalr	1876(ra) # 80003776 <iget>
    8000402a:	a011                	j	8000402e <dirlookup+0xa0>
  return 0;
    8000402c:	4501                	li	a0,0
}
    8000402e:	70e2                	ld	ra,56(sp)
    80004030:	7442                	ld	s0,48(sp)
    80004032:	74a2                	ld	s1,40(sp)
    80004034:	7902                	ld	s2,32(sp)
    80004036:	69e2                	ld	s3,24(sp)
    80004038:	6a42                	ld	s4,16(sp)
    8000403a:	6121                	addi	sp,sp,64
    8000403c:	8082                	ret

000000008000403e <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    8000403e:	711d                	addi	sp,sp,-96
    80004040:	ec86                	sd	ra,88(sp)
    80004042:	e8a2                	sd	s0,80(sp)
    80004044:	e4a6                	sd	s1,72(sp)
    80004046:	e0ca                	sd	s2,64(sp)
    80004048:	fc4e                	sd	s3,56(sp)
    8000404a:	f852                	sd	s4,48(sp)
    8000404c:	f456                	sd	s5,40(sp)
    8000404e:	f05a                	sd	s6,32(sp)
    80004050:	ec5e                	sd	s7,24(sp)
    80004052:	e862                	sd	s8,16(sp)
    80004054:	e466                	sd	s9,8(sp)
    80004056:	1080                	addi	s0,sp,96
    80004058:	84aa                	mv	s1,a0
    8000405a:	8b2e                	mv	s6,a1
    8000405c:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    8000405e:	00054703          	lbu	a4,0(a0)
    80004062:	02f00793          	li	a5,47
    80004066:	02f70363          	beq	a4,a5,8000408c <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    8000406a:	ffffe097          	auipc	ra,0xffffe
    8000406e:	95e080e7          	jalr	-1698(ra) # 800019c8 <myproc>
    80004072:	17053503          	ld	a0,368(a0)
    80004076:	00000097          	auipc	ra,0x0
    8000407a:	9f6080e7          	jalr	-1546(ra) # 80003a6c <idup>
    8000407e:	89aa                	mv	s3,a0
  while(*path == '/')
    80004080:	02f00913          	li	s2,47
  len = path - s;
    80004084:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    80004086:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80004088:	4c05                	li	s8,1
    8000408a:	a865                	j	80004142 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    8000408c:	4585                	li	a1,1
    8000408e:	4505                	li	a0,1
    80004090:	fffff097          	auipc	ra,0xfffff
    80004094:	6e6080e7          	jalr	1766(ra) # 80003776 <iget>
    80004098:	89aa                	mv	s3,a0
    8000409a:	b7dd                	j	80004080 <namex+0x42>
      iunlockput(ip);
    8000409c:	854e                	mv	a0,s3
    8000409e:	00000097          	auipc	ra,0x0
    800040a2:	c6e080e7          	jalr	-914(ra) # 80003d0c <iunlockput>
      return 0;
    800040a6:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    800040a8:	854e                	mv	a0,s3
    800040aa:	60e6                	ld	ra,88(sp)
    800040ac:	6446                	ld	s0,80(sp)
    800040ae:	64a6                	ld	s1,72(sp)
    800040b0:	6906                	ld	s2,64(sp)
    800040b2:	79e2                	ld	s3,56(sp)
    800040b4:	7a42                	ld	s4,48(sp)
    800040b6:	7aa2                	ld	s5,40(sp)
    800040b8:	7b02                	ld	s6,32(sp)
    800040ba:	6be2                	ld	s7,24(sp)
    800040bc:	6c42                	ld	s8,16(sp)
    800040be:	6ca2                	ld	s9,8(sp)
    800040c0:	6125                	addi	sp,sp,96
    800040c2:	8082                	ret
      iunlock(ip);
    800040c4:	854e                	mv	a0,s3
    800040c6:	00000097          	auipc	ra,0x0
    800040ca:	aa6080e7          	jalr	-1370(ra) # 80003b6c <iunlock>
      return ip;
    800040ce:	bfe9                	j	800040a8 <namex+0x6a>
      iunlockput(ip);
    800040d0:	854e                	mv	a0,s3
    800040d2:	00000097          	auipc	ra,0x0
    800040d6:	c3a080e7          	jalr	-966(ra) # 80003d0c <iunlockput>
      return 0;
    800040da:	89d2                	mv	s3,s4
    800040dc:	b7f1                	j	800040a8 <namex+0x6a>
  len = path - s;
    800040de:	40b48633          	sub	a2,s1,a1
    800040e2:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    800040e6:	094cd463          	bge	s9,s4,8000416e <namex+0x130>
    memmove(name, s, DIRSIZ);
    800040ea:	4639                	li	a2,14
    800040ec:	8556                	mv	a0,s5
    800040ee:	ffffd097          	auipc	ra,0xffffd
    800040f2:	c52080e7          	jalr	-942(ra) # 80000d40 <memmove>
  while(*path == '/')
    800040f6:	0004c783          	lbu	a5,0(s1)
    800040fa:	01279763          	bne	a5,s2,80004108 <namex+0xca>
    path++;
    800040fe:	0485                	addi	s1,s1,1
  while(*path == '/')
    80004100:	0004c783          	lbu	a5,0(s1)
    80004104:	ff278de3          	beq	a5,s2,800040fe <namex+0xc0>
    ilock(ip);
    80004108:	854e                	mv	a0,s3
    8000410a:	00000097          	auipc	ra,0x0
    8000410e:	9a0080e7          	jalr	-1632(ra) # 80003aaa <ilock>
    if(ip->type != T_DIR){
    80004112:	04499783          	lh	a5,68(s3)
    80004116:	f98793e3          	bne	a5,s8,8000409c <namex+0x5e>
    if(nameiparent && *path == '\0'){
    8000411a:	000b0563          	beqz	s6,80004124 <namex+0xe6>
    8000411e:	0004c783          	lbu	a5,0(s1)
    80004122:	d3cd                	beqz	a5,800040c4 <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80004124:	865e                	mv	a2,s7
    80004126:	85d6                	mv	a1,s5
    80004128:	854e                	mv	a0,s3
    8000412a:	00000097          	auipc	ra,0x0
    8000412e:	e64080e7          	jalr	-412(ra) # 80003f8e <dirlookup>
    80004132:	8a2a                	mv	s4,a0
    80004134:	dd51                	beqz	a0,800040d0 <namex+0x92>
    iunlockput(ip);
    80004136:	854e                	mv	a0,s3
    80004138:	00000097          	auipc	ra,0x0
    8000413c:	bd4080e7          	jalr	-1068(ra) # 80003d0c <iunlockput>
    ip = next;
    80004140:	89d2                	mv	s3,s4
  while(*path == '/')
    80004142:	0004c783          	lbu	a5,0(s1)
    80004146:	05279763          	bne	a5,s2,80004194 <namex+0x156>
    path++;
    8000414a:	0485                	addi	s1,s1,1
  while(*path == '/')
    8000414c:	0004c783          	lbu	a5,0(s1)
    80004150:	ff278de3          	beq	a5,s2,8000414a <namex+0x10c>
  if(*path == 0)
    80004154:	c79d                	beqz	a5,80004182 <namex+0x144>
    path++;
    80004156:	85a6                	mv	a1,s1
  len = path - s;
    80004158:	8a5e                	mv	s4,s7
    8000415a:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    8000415c:	01278963          	beq	a5,s2,8000416e <namex+0x130>
    80004160:	dfbd                	beqz	a5,800040de <namex+0xa0>
    path++;
    80004162:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80004164:	0004c783          	lbu	a5,0(s1)
    80004168:	ff279ce3          	bne	a5,s2,80004160 <namex+0x122>
    8000416c:	bf8d                	j	800040de <namex+0xa0>
    memmove(name, s, len);
    8000416e:	2601                	sext.w	a2,a2
    80004170:	8556                	mv	a0,s5
    80004172:	ffffd097          	auipc	ra,0xffffd
    80004176:	bce080e7          	jalr	-1074(ra) # 80000d40 <memmove>
    name[len] = 0;
    8000417a:	9a56                	add	s4,s4,s5
    8000417c:	000a0023          	sb	zero,0(s4)
    80004180:	bf9d                	j	800040f6 <namex+0xb8>
  if(nameiparent){
    80004182:	f20b03e3          	beqz	s6,800040a8 <namex+0x6a>
    iput(ip);
    80004186:	854e                	mv	a0,s3
    80004188:	00000097          	auipc	ra,0x0
    8000418c:	adc080e7          	jalr	-1316(ra) # 80003c64 <iput>
    return 0;
    80004190:	4981                	li	s3,0
    80004192:	bf19                	j	800040a8 <namex+0x6a>
  if(*path == 0)
    80004194:	d7fd                	beqz	a5,80004182 <namex+0x144>
  while(*path != '/' && *path != 0)
    80004196:	0004c783          	lbu	a5,0(s1)
    8000419a:	85a6                	mv	a1,s1
    8000419c:	b7d1                	j	80004160 <namex+0x122>

000000008000419e <dirlink>:
{
    8000419e:	7139                	addi	sp,sp,-64
    800041a0:	fc06                	sd	ra,56(sp)
    800041a2:	f822                	sd	s0,48(sp)
    800041a4:	f426                	sd	s1,40(sp)
    800041a6:	f04a                	sd	s2,32(sp)
    800041a8:	ec4e                	sd	s3,24(sp)
    800041aa:	e852                	sd	s4,16(sp)
    800041ac:	0080                	addi	s0,sp,64
    800041ae:	892a                	mv	s2,a0
    800041b0:	8a2e                	mv	s4,a1
    800041b2:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    800041b4:	4601                	li	a2,0
    800041b6:	00000097          	auipc	ra,0x0
    800041ba:	dd8080e7          	jalr	-552(ra) # 80003f8e <dirlookup>
    800041be:	e93d                	bnez	a0,80004234 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800041c0:	04c92483          	lw	s1,76(s2)
    800041c4:	c49d                	beqz	s1,800041f2 <dirlink+0x54>
    800041c6:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800041c8:	4741                	li	a4,16
    800041ca:	86a6                	mv	a3,s1
    800041cc:	fc040613          	addi	a2,s0,-64
    800041d0:	4581                	li	a1,0
    800041d2:	854a                	mv	a0,s2
    800041d4:	00000097          	auipc	ra,0x0
    800041d8:	b8a080e7          	jalr	-1142(ra) # 80003d5e <readi>
    800041dc:	47c1                	li	a5,16
    800041de:	06f51163          	bne	a0,a5,80004240 <dirlink+0xa2>
    if(de.inum == 0)
    800041e2:	fc045783          	lhu	a5,-64(s0)
    800041e6:	c791                	beqz	a5,800041f2 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800041e8:	24c1                	addiw	s1,s1,16
    800041ea:	04c92783          	lw	a5,76(s2)
    800041ee:	fcf4ede3          	bltu	s1,a5,800041c8 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    800041f2:	4639                	li	a2,14
    800041f4:	85d2                	mv	a1,s4
    800041f6:	fc240513          	addi	a0,s0,-62
    800041fa:	ffffd097          	auipc	ra,0xffffd
    800041fe:	bfa080e7          	jalr	-1030(ra) # 80000df4 <strncpy>
  de.inum = inum;
    80004202:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004206:	4741                	li	a4,16
    80004208:	86a6                	mv	a3,s1
    8000420a:	fc040613          	addi	a2,s0,-64
    8000420e:	4581                	li	a1,0
    80004210:	854a                	mv	a0,s2
    80004212:	00000097          	auipc	ra,0x0
    80004216:	c44080e7          	jalr	-956(ra) # 80003e56 <writei>
    8000421a:	872a                	mv	a4,a0
    8000421c:	47c1                	li	a5,16
  return 0;
    8000421e:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004220:	02f71863          	bne	a4,a5,80004250 <dirlink+0xb2>
}
    80004224:	70e2                	ld	ra,56(sp)
    80004226:	7442                	ld	s0,48(sp)
    80004228:	74a2                	ld	s1,40(sp)
    8000422a:	7902                	ld	s2,32(sp)
    8000422c:	69e2                	ld	s3,24(sp)
    8000422e:	6a42                	ld	s4,16(sp)
    80004230:	6121                	addi	sp,sp,64
    80004232:	8082                	ret
    iput(ip);
    80004234:	00000097          	auipc	ra,0x0
    80004238:	a30080e7          	jalr	-1488(ra) # 80003c64 <iput>
    return -1;
    8000423c:	557d                	li	a0,-1
    8000423e:	b7dd                	j	80004224 <dirlink+0x86>
      panic("dirlink read");
    80004240:	00004517          	auipc	a0,0x4
    80004244:	3f050513          	addi	a0,a0,1008 # 80008630 <syscalls+0x1d8>
    80004248:	ffffc097          	auipc	ra,0xffffc
    8000424c:	2f6080e7          	jalr	758(ra) # 8000053e <panic>
    panic("dirlink");
    80004250:	00004517          	auipc	a0,0x4
    80004254:	4f050513          	addi	a0,a0,1264 # 80008740 <syscalls+0x2e8>
    80004258:	ffffc097          	auipc	ra,0xffffc
    8000425c:	2e6080e7          	jalr	742(ra) # 8000053e <panic>

0000000080004260 <namei>:

struct inode*
namei(char *path)
{
    80004260:	1101                	addi	sp,sp,-32
    80004262:	ec06                	sd	ra,24(sp)
    80004264:	e822                	sd	s0,16(sp)
    80004266:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80004268:	fe040613          	addi	a2,s0,-32
    8000426c:	4581                	li	a1,0
    8000426e:	00000097          	auipc	ra,0x0
    80004272:	dd0080e7          	jalr	-560(ra) # 8000403e <namex>
}
    80004276:	60e2                	ld	ra,24(sp)
    80004278:	6442                	ld	s0,16(sp)
    8000427a:	6105                	addi	sp,sp,32
    8000427c:	8082                	ret

000000008000427e <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    8000427e:	1141                	addi	sp,sp,-16
    80004280:	e406                	sd	ra,8(sp)
    80004282:	e022                	sd	s0,0(sp)
    80004284:	0800                	addi	s0,sp,16
    80004286:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80004288:	4585                	li	a1,1
    8000428a:	00000097          	auipc	ra,0x0
    8000428e:	db4080e7          	jalr	-588(ra) # 8000403e <namex>
}
    80004292:	60a2                	ld	ra,8(sp)
    80004294:	6402                	ld	s0,0(sp)
    80004296:	0141                	addi	sp,sp,16
    80004298:	8082                	ret

000000008000429a <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    8000429a:	1101                	addi	sp,sp,-32
    8000429c:	ec06                	sd	ra,24(sp)
    8000429e:	e822                	sd	s0,16(sp)
    800042a0:	e426                	sd	s1,8(sp)
    800042a2:	e04a                	sd	s2,0(sp)
    800042a4:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    800042a6:	0001d917          	auipc	s2,0x1d
    800042aa:	7ea90913          	addi	s2,s2,2026 # 80021a90 <log>
    800042ae:	01892583          	lw	a1,24(s2)
    800042b2:	02892503          	lw	a0,40(s2)
    800042b6:	fffff097          	auipc	ra,0xfffff
    800042ba:	ff2080e7          	jalr	-14(ra) # 800032a8 <bread>
    800042be:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    800042c0:	02c92683          	lw	a3,44(s2)
    800042c4:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    800042c6:	02d05763          	blez	a3,800042f4 <write_head+0x5a>
    800042ca:	0001d797          	auipc	a5,0x1d
    800042ce:	7f678793          	addi	a5,a5,2038 # 80021ac0 <log+0x30>
    800042d2:	05c50713          	addi	a4,a0,92
    800042d6:	36fd                	addiw	a3,a3,-1
    800042d8:	1682                	slli	a3,a3,0x20
    800042da:	9281                	srli	a3,a3,0x20
    800042dc:	068a                	slli	a3,a3,0x2
    800042de:	0001d617          	auipc	a2,0x1d
    800042e2:	7e660613          	addi	a2,a2,2022 # 80021ac4 <log+0x34>
    800042e6:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    800042e8:	4390                	lw	a2,0(a5)
    800042ea:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    800042ec:	0791                	addi	a5,a5,4
    800042ee:	0711                	addi	a4,a4,4
    800042f0:	fed79ce3          	bne	a5,a3,800042e8 <write_head+0x4e>
  }
  bwrite(buf);
    800042f4:	8526                	mv	a0,s1
    800042f6:	fffff097          	auipc	ra,0xfffff
    800042fa:	0a4080e7          	jalr	164(ra) # 8000339a <bwrite>
  brelse(buf);
    800042fe:	8526                	mv	a0,s1
    80004300:	fffff097          	auipc	ra,0xfffff
    80004304:	0d8080e7          	jalr	216(ra) # 800033d8 <brelse>
}
    80004308:	60e2                	ld	ra,24(sp)
    8000430a:	6442                	ld	s0,16(sp)
    8000430c:	64a2                	ld	s1,8(sp)
    8000430e:	6902                	ld	s2,0(sp)
    80004310:	6105                	addi	sp,sp,32
    80004312:	8082                	ret

0000000080004314 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80004314:	0001d797          	auipc	a5,0x1d
    80004318:	7a87a783          	lw	a5,1960(a5) # 80021abc <log+0x2c>
    8000431c:	0af05d63          	blez	a5,800043d6 <install_trans+0xc2>
{
    80004320:	7139                	addi	sp,sp,-64
    80004322:	fc06                	sd	ra,56(sp)
    80004324:	f822                	sd	s0,48(sp)
    80004326:	f426                	sd	s1,40(sp)
    80004328:	f04a                	sd	s2,32(sp)
    8000432a:	ec4e                	sd	s3,24(sp)
    8000432c:	e852                	sd	s4,16(sp)
    8000432e:	e456                	sd	s5,8(sp)
    80004330:	e05a                	sd	s6,0(sp)
    80004332:	0080                	addi	s0,sp,64
    80004334:	8b2a                	mv	s6,a0
    80004336:	0001da97          	auipc	s5,0x1d
    8000433a:	78aa8a93          	addi	s5,s5,1930 # 80021ac0 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000433e:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004340:	0001d997          	auipc	s3,0x1d
    80004344:	75098993          	addi	s3,s3,1872 # 80021a90 <log>
    80004348:	a035                	j	80004374 <install_trans+0x60>
      bunpin(dbuf);
    8000434a:	8526                	mv	a0,s1
    8000434c:	fffff097          	auipc	ra,0xfffff
    80004350:	166080e7          	jalr	358(ra) # 800034b2 <bunpin>
    brelse(lbuf);
    80004354:	854a                	mv	a0,s2
    80004356:	fffff097          	auipc	ra,0xfffff
    8000435a:	082080e7          	jalr	130(ra) # 800033d8 <brelse>
    brelse(dbuf);
    8000435e:	8526                	mv	a0,s1
    80004360:	fffff097          	auipc	ra,0xfffff
    80004364:	078080e7          	jalr	120(ra) # 800033d8 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004368:	2a05                	addiw	s4,s4,1
    8000436a:	0a91                	addi	s5,s5,4
    8000436c:	02c9a783          	lw	a5,44(s3)
    80004370:	04fa5963          	bge	s4,a5,800043c2 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004374:	0189a583          	lw	a1,24(s3)
    80004378:	014585bb          	addw	a1,a1,s4
    8000437c:	2585                	addiw	a1,a1,1
    8000437e:	0289a503          	lw	a0,40(s3)
    80004382:	fffff097          	auipc	ra,0xfffff
    80004386:	f26080e7          	jalr	-218(ra) # 800032a8 <bread>
    8000438a:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    8000438c:	000aa583          	lw	a1,0(s5)
    80004390:	0289a503          	lw	a0,40(s3)
    80004394:	fffff097          	auipc	ra,0xfffff
    80004398:	f14080e7          	jalr	-236(ra) # 800032a8 <bread>
    8000439c:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    8000439e:	40000613          	li	a2,1024
    800043a2:	05890593          	addi	a1,s2,88
    800043a6:	05850513          	addi	a0,a0,88
    800043aa:	ffffd097          	auipc	ra,0xffffd
    800043ae:	996080e7          	jalr	-1642(ra) # 80000d40 <memmove>
    bwrite(dbuf);  // write dst to disk
    800043b2:	8526                	mv	a0,s1
    800043b4:	fffff097          	auipc	ra,0xfffff
    800043b8:	fe6080e7          	jalr	-26(ra) # 8000339a <bwrite>
    if(recovering == 0)
    800043bc:	f80b1ce3          	bnez	s6,80004354 <install_trans+0x40>
    800043c0:	b769                	j	8000434a <install_trans+0x36>
}
    800043c2:	70e2                	ld	ra,56(sp)
    800043c4:	7442                	ld	s0,48(sp)
    800043c6:	74a2                	ld	s1,40(sp)
    800043c8:	7902                	ld	s2,32(sp)
    800043ca:	69e2                	ld	s3,24(sp)
    800043cc:	6a42                	ld	s4,16(sp)
    800043ce:	6aa2                	ld	s5,8(sp)
    800043d0:	6b02                	ld	s6,0(sp)
    800043d2:	6121                	addi	sp,sp,64
    800043d4:	8082                	ret
    800043d6:	8082                	ret

00000000800043d8 <initlog>:
{
    800043d8:	7179                	addi	sp,sp,-48
    800043da:	f406                	sd	ra,40(sp)
    800043dc:	f022                	sd	s0,32(sp)
    800043de:	ec26                	sd	s1,24(sp)
    800043e0:	e84a                	sd	s2,16(sp)
    800043e2:	e44e                	sd	s3,8(sp)
    800043e4:	1800                	addi	s0,sp,48
    800043e6:	892a                	mv	s2,a0
    800043e8:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    800043ea:	0001d497          	auipc	s1,0x1d
    800043ee:	6a648493          	addi	s1,s1,1702 # 80021a90 <log>
    800043f2:	00004597          	auipc	a1,0x4
    800043f6:	24e58593          	addi	a1,a1,590 # 80008640 <syscalls+0x1e8>
    800043fa:	8526                	mv	a0,s1
    800043fc:	ffffc097          	auipc	ra,0xffffc
    80004400:	758080e7          	jalr	1880(ra) # 80000b54 <initlock>
  log.start = sb->logstart;
    80004404:	0149a583          	lw	a1,20(s3)
    80004408:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    8000440a:	0109a783          	lw	a5,16(s3)
    8000440e:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    80004410:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80004414:	854a                	mv	a0,s2
    80004416:	fffff097          	auipc	ra,0xfffff
    8000441a:	e92080e7          	jalr	-366(ra) # 800032a8 <bread>
  log.lh.n = lh->n;
    8000441e:	4d3c                	lw	a5,88(a0)
    80004420:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80004422:	02f05563          	blez	a5,8000444c <initlog+0x74>
    80004426:	05c50713          	addi	a4,a0,92
    8000442a:	0001d697          	auipc	a3,0x1d
    8000442e:	69668693          	addi	a3,a3,1686 # 80021ac0 <log+0x30>
    80004432:	37fd                	addiw	a5,a5,-1
    80004434:	1782                	slli	a5,a5,0x20
    80004436:	9381                	srli	a5,a5,0x20
    80004438:	078a                	slli	a5,a5,0x2
    8000443a:	06050613          	addi	a2,a0,96
    8000443e:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    80004440:	4310                	lw	a2,0(a4)
    80004442:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    80004444:	0711                	addi	a4,a4,4
    80004446:	0691                	addi	a3,a3,4
    80004448:	fef71ce3          	bne	a4,a5,80004440 <initlog+0x68>
  brelse(buf);
    8000444c:	fffff097          	auipc	ra,0xfffff
    80004450:	f8c080e7          	jalr	-116(ra) # 800033d8 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    80004454:	4505                	li	a0,1
    80004456:	00000097          	auipc	ra,0x0
    8000445a:	ebe080e7          	jalr	-322(ra) # 80004314 <install_trans>
  log.lh.n = 0;
    8000445e:	0001d797          	auipc	a5,0x1d
    80004462:	6407af23          	sw	zero,1630(a5) # 80021abc <log+0x2c>
  write_head(); // clear the log
    80004466:	00000097          	auipc	ra,0x0
    8000446a:	e34080e7          	jalr	-460(ra) # 8000429a <write_head>
}
    8000446e:	70a2                	ld	ra,40(sp)
    80004470:	7402                	ld	s0,32(sp)
    80004472:	64e2                	ld	s1,24(sp)
    80004474:	6942                	ld	s2,16(sp)
    80004476:	69a2                	ld	s3,8(sp)
    80004478:	6145                	addi	sp,sp,48
    8000447a:	8082                	ret

000000008000447c <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    8000447c:	1101                	addi	sp,sp,-32
    8000447e:	ec06                	sd	ra,24(sp)
    80004480:	e822                	sd	s0,16(sp)
    80004482:	e426                	sd	s1,8(sp)
    80004484:	e04a                	sd	s2,0(sp)
    80004486:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80004488:	0001d517          	auipc	a0,0x1d
    8000448c:	60850513          	addi	a0,a0,1544 # 80021a90 <log>
    80004490:	ffffc097          	auipc	ra,0xffffc
    80004494:	754080e7          	jalr	1876(ra) # 80000be4 <acquire>
  while(1){
    if(log.committing){
    80004498:	0001d497          	auipc	s1,0x1d
    8000449c:	5f848493          	addi	s1,s1,1528 # 80021a90 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800044a0:	4979                	li	s2,30
    800044a2:	a039                	j	800044b0 <begin_op+0x34>
      sleep(&log, &log.lock);
    800044a4:	85a6                	mv	a1,s1
    800044a6:	8526                	mv	a0,s1
    800044a8:	ffffe097          	auipc	ra,0xffffe
    800044ac:	ed0080e7          	jalr	-304(ra) # 80002378 <sleep>
    if(log.committing){
    800044b0:	50dc                	lw	a5,36(s1)
    800044b2:	fbed                	bnez	a5,800044a4 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800044b4:	509c                	lw	a5,32(s1)
    800044b6:	0017871b          	addiw	a4,a5,1
    800044ba:	0007069b          	sext.w	a3,a4
    800044be:	0027179b          	slliw	a5,a4,0x2
    800044c2:	9fb9                	addw	a5,a5,a4
    800044c4:	0017979b          	slliw	a5,a5,0x1
    800044c8:	54d8                	lw	a4,44(s1)
    800044ca:	9fb9                	addw	a5,a5,a4
    800044cc:	00f95963          	bge	s2,a5,800044de <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    800044d0:	85a6                	mv	a1,s1
    800044d2:	8526                	mv	a0,s1
    800044d4:	ffffe097          	auipc	ra,0xffffe
    800044d8:	ea4080e7          	jalr	-348(ra) # 80002378 <sleep>
    800044dc:	bfd1                	j	800044b0 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    800044de:	0001d517          	auipc	a0,0x1d
    800044e2:	5b250513          	addi	a0,a0,1458 # 80021a90 <log>
    800044e6:	d114                	sw	a3,32(a0)
      release(&log.lock);
    800044e8:	ffffc097          	auipc	ra,0xffffc
    800044ec:	7b0080e7          	jalr	1968(ra) # 80000c98 <release>
      break;
    }
  }
}
    800044f0:	60e2                	ld	ra,24(sp)
    800044f2:	6442                	ld	s0,16(sp)
    800044f4:	64a2                	ld	s1,8(sp)
    800044f6:	6902                	ld	s2,0(sp)
    800044f8:	6105                	addi	sp,sp,32
    800044fa:	8082                	ret

00000000800044fc <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    800044fc:	7139                	addi	sp,sp,-64
    800044fe:	fc06                	sd	ra,56(sp)
    80004500:	f822                	sd	s0,48(sp)
    80004502:	f426                	sd	s1,40(sp)
    80004504:	f04a                	sd	s2,32(sp)
    80004506:	ec4e                	sd	s3,24(sp)
    80004508:	e852                	sd	s4,16(sp)
    8000450a:	e456                	sd	s5,8(sp)
    8000450c:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    8000450e:	0001d497          	auipc	s1,0x1d
    80004512:	58248493          	addi	s1,s1,1410 # 80021a90 <log>
    80004516:	8526                	mv	a0,s1
    80004518:	ffffc097          	auipc	ra,0xffffc
    8000451c:	6cc080e7          	jalr	1740(ra) # 80000be4 <acquire>
  log.outstanding -= 1;
    80004520:	509c                	lw	a5,32(s1)
    80004522:	37fd                	addiw	a5,a5,-1
    80004524:	0007891b          	sext.w	s2,a5
    80004528:	d09c                	sw	a5,32(s1)
  if(log.committing)
    8000452a:	50dc                	lw	a5,36(s1)
    8000452c:	efb9                	bnez	a5,8000458a <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    8000452e:	06091663          	bnez	s2,8000459a <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    80004532:	0001d497          	auipc	s1,0x1d
    80004536:	55e48493          	addi	s1,s1,1374 # 80021a90 <log>
    8000453a:	4785                	li	a5,1
    8000453c:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    8000453e:	8526                	mv	a0,s1
    80004540:	ffffc097          	auipc	ra,0xffffc
    80004544:	758080e7          	jalr	1880(ra) # 80000c98 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    80004548:	54dc                	lw	a5,44(s1)
    8000454a:	06f04763          	bgtz	a5,800045b8 <end_op+0xbc>
    acquire(&log.lock);
    8000454e:	0001d497          	auipc	s1,0x1d
    80004552:	54248493          	addi	s1,s1,1346 # 80021a90 <log>
    80004556:	8526                	mv	a0,s1
    80004558:	ffffc097          	auipc	ra,0xffffc
    8000455c:	68c080e7          	jalr	1676(ra) # 80000be4 <acquire>
    log.committing = 0;
    80004560:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    80004564:	8526                	mv	a0,s1
    80004566:	ffffe097          	auipc	ra,0xffffe
    8000456a:	fb2080e7          	jalr	-78(ra) # 80002518 <wakeup>
    release(&log.lock);
    8000456e:	8526                	mv	a0,s1
    80004570:	ffffc097          	auipc	ra,0xffffc
    80004574:	728080e7          	jalr	1832(ra) # 80000c98 <release>
}
    80004578:	70e2                	ld	ra,56(sp)
    8000457a:	7442                	ld	s0,48(sp)
    8000457c:	74a2                	ld	s1,40(sp)
    8000457e:	7902                	ld	s2,32(sp)
    80004580:	69e2                	ld	s3,24(sp)
    80004582:	6a42                	ld	s4,16(sp)
    80004584:	6aa2                	ld	s5,8(sp)
    80004586:	6121                	addi	sp,sp,64
    80004588:	8082                	ret
    panic("log.committing");
    8000458a:	00004517          	auipc	a0,0x4
    8000458e:	0be50513          	addi	a0,a0,190 # 80008648 <syscalls+0x1f0>
    80004592:	ffffc097          	auipc	ra,0xffffc
    80004596:	fac080e7          	jalr	-84(ra) # 8000053e <panic>
    wakeup(&log);
    8000459a:	0001d497          	auipc	s1,0x1d
    8000459e:	4f648493          	addi	s1,s1,1270 # 80021a90 <log>
    800045a2:	8526                	mv	a0,s1
    800045a4:	ffffe097          	auipc	ra,0xffffe
    800045a8:	f74080e7          	jalr	-140(ra) # 80002518 <wakeup>
  release(&log.lock);
    800045ac:	8526                	mv	a0,s1
    800045ae:	ffffc097          	auipc	ra,0xffffc
    800045b2:	6ea080e7          	jalr	1770(ra) # 80000c98 <release>
  if(do_commit){
    800045b6:	b7c9                	j	80004578 <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    800045b8:	0001da97          	auipc	s5,0x1d
    800045bc:	508a8a93          	addi	s5,s5,1288 # 80021ac0 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    800045c0:	0001da17          	auipc	s4,0x1d
    800045c4:	4d0a0a13          	addi	s4,s4,1232 # 80021a90 <log>
    800045c8:	018a2583          	lw	a1,24(s4)
    800045cc:	012585bb          	addw	a1,a1,s2
    800045d0:	2585                	addiw	a1,a1,1
    800045d2:	028a2503          	lw	a0,40(s4)
    800045d6:	fffff097          	auipc	ra,0xfffff
    800045da:	cd2080e7          	jalr	-814(ra) # 800032a8 <bread>
    800045de:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    800045e0:	000aa583          	lw	a1,0(s5)
    800045e4:	028a2503          	lw	a0,40(s4)
    800045e8:	fffff097          	auipc	ra,0xfffff
    800045ec:	cc0080e7          	jalr	-832(ra) # 800032a8 <bread>
    800045f0:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    800045f2:	40000613          	li	a2,1024
    800045f6:	05850593          	addi	a1,a0,88
    800045fa:	05848513          	addi	a0,s1,88
    800045fe:	ffffc097          	auipc	ra,0xffffc
    80004602:	742080e7          	jalr	1858(ra) # 80000d40 <memmove>
    bwrite(to);  // write the log
    80004606:	8526                	mv	a0,s1
    80004608:	fffff097          	auipc	ra,0xfffff
    8000460c:	d92080e7          	jalr	-622(ra) # 8000339a <bwrite>
    brelse(from);
    80004610:	854e                	mv	a0,s3
    80004612:	fffff097          	auipc	ra,0xfffff
    80004616:	dc6080e7          	jalr	-570(ra) # 800033d8 <brelse>
    brelse(to);
    8000461a:	8526                	mv	a0,s1
    8000461c:	fffff097          	auipc	ra,0xfffff
    80004620:	dbc080e7          	jalr	-580(ra) # 800033d8 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004624:	2905                	addiw	s2,s2,1
    80004626:	0a91                	addi	s5,s5,4
    80004628:	02ca2783          	lw	a5,44(s4)
    8000462c:	f8f94ee3          	blt	s2,a5,800045c8 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004630:	00000097          	auipc	ra,0x0
    80004634:	c6a080e7          	jalr	-918(ra) # 8000429a <write_head>
    install_trans(0); // Now install writes to home locations
    80004638:	4501                	li	a0,0
    8000463a:	00000097          	auipc	ra,0x0
    8000463e:	cda080e7          	jalr	-806(ra) # 80004314 <install_trans>
    log.lh.n = 0;
    80004642:	0001d797          	auipc	a5,0x1d
    80004646:	4607ad23          	sw	zero,1146(a5) # 80021abc <log+0x2c>
    write_head();    // Erase the transaction from the log
    8000464a:	00000097          	auipc	ra,0x0
    8000464e:	c50080e7          	jalr	-944(ra) # 8000429a <write_head>
    80004652:	bdf5                	j	8000454e <end_op+0x52>

0000000080004654 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004654:	1101                	addi	sp,sp,-32
    80004656:	ec06                	sd	ra,24(sp)
    80004658:	e822                	sd	s0,16(sp)
    8000465a:	e426                	sd	s1,8(sp)
    8000465c:	e04a                	sd	s2,0(sp)
    8000465e:	1000                	addi	s0,sp,32
    80004660:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    80004662:	0001d917          	auipc	s2,0x1d
    80004666:	42e90913          	addi	s2,s2,1070 # 80021a90 <log>
    8000466a:	854a                	mv	a0,s2
    8000466c:	ffffc097          	auipc	ra,0xffffc
    80004670:	578080e7          	jalr	1400(ra) # 80000be4 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004674:	02c92603          	lw	a2,44(s2)
    80004678:	47f5                	li	a5,29
    8000467a:	06c7c563          	blt	a5,a2,800046e4 <log_write+0x90>
    8000467e:	0001d797          	auipc	a5,0x1d
    80004682:	42e7a783          	lw	a5,1070(a5) # 80021aac <log+0x1c>
    80004686:	37fd                	addiw	a5,a5,-1
    80004688:	04f65e63          	bge	a2,a5,800046e4 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    8000468c:	0001d797          	auipc	a5,0x1d
    80004690:	4247a783          	lw	a5,1060(a5) # 80021ab0 <log+0x20>
    80004694:	06f05063          	blez	a5,800046f4 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    80004698:	4781                	li	a5,0
    8000469a:	06c05563          	blez	a2,80004704 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    8000469e:	44cc                	lw	a1,12(s1)
    800046a0:	0001d717          	auipc	a4,0x1d
    800046a4:	42070713          	addi	a4,a4,1056 # 80021ac0 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    800046a8:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    800046aa:	4314                	lw	a3,0(a4)
    800046ac:	04b68c63          	beq	a3,a1,80004704 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    800046b0:	2785                	addiw	a5,a5,1
    800046b2:	0711                	addi	a4,a4,4
    800046b4:	fef61be3          	bne	a2,a5,800046aa <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    800046b8:	0621                	addi	a2,a2,8
    800046ba:	060a                	slli	a2,a2,0x2
    800046bc:	0001d797          	auipc	a5,0x1d
    800046c0:	3d478793          	addi	a5,a5,980 # 80021a90 <log>
    800046c4:	963e                	add	a2,a2,a5
    800046c6:	44dc                	lw	a5,12(s1)
    800046c8:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    800046ca:	8526                	mv	a0,s1
    800046cc:	fffff097          	auipc	ra,0xfffff
    800046d0:	daa080e7          	jalr	-598(ra) # 80003476 <bpin>
    log.lh.n++;
    800046d4:	0001d717          	auipc	a4,0x1d
    800046d8:	3bc70713          	addi	a4,a4,956 # 80021a90 <log>
    800046dc:	575c                	lw	a5,44(a4)
    800046de:	2785                	addiw	a5,a5,1
    800046e0:	d75c                	sw	a5,44(a4)
    800046e2:	a835                	j	8000471e <log_write+0xca>
    panic("too big a transaction");
    800046e4:	00004517          	auipc	a0,0x4
    800046e8:	f7450513          	addi	a0,a0,-140 # 80008658 <syscalls+0x200>
    800046ec:	ffffc097          	auipc	ra,0xffffc
    800046f0:	e52080e7          	jalr	-430(ra) # 8000053e <panic>
    panic("log_write outside of trans");
    800046f4:	00004517          	auipc	a0,0x4
    800046f8:	f7c50513          	addi	a0,a0,-132 # 80008670 <syscalls+0x218>
    800046fc:	ffffc097          	auipc	ra,0xffffc
    80004700:	e42080e7          	jalr	-446(ra) # 8000053e <panic>
  log.lh.block[i] = b->blockno;
    80004704:	00878713          	addi	a4,a5,8
    80004708:	00271693          	slli	a3,a4,0x2
    8000470c:	0001d717          	auipc	a4,0x1d
    80004710:	38470713          	addi	a4,a4,900 # 80021a90 <log>
    80004714:	9736                	add	a4,a4,a3
    80004716:	44d4                	lw	a3,12(s1)
    80004718:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    8000471a:	faf608e3          	beq	a2,a5,800046ca <log_write+0x76>
  }
  release(&log.lock);
    8000471e:	0001d517          	auipc	a0,0x1d
    80004722:	37250513          	addi	a0,a0,882 # 80021a90 <log>
    80004726:	ffffc097          	auipc	ra,0xffffc
    8000472a:	572080e7          	jalr	1394(ra) # 80000c98 <release>
}
    8000472e:	60e2                	ld	ra,24(sp)
    80004730:	6442                	ld	s0,16(sp)
    80004732:	64a2                	ld	s1,8(sp)
    80004734:	6902                	ld	s2,0(sp)
    80004736:	6105                	addi	sp,sp,32
    80004738:	8082                	ret

000000008000473a <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    8000473a:	1101                	addi	sp,sp,-32
    8000473c:	ec06                	sd	ra,24(sp)
    8000473e:	e822                	sd	s0,16(sp)
    80004740:	e426                	sd	s1,8(sp)
    80004742:	e04a                	sd	s2,0(sp)
    80004744:	1000                	addi	s0,sp,32
    80004746:	84aa                	mv	s1,a0
    80004748:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    8000474a:	00004597          	auipc	a1,0x4
    8000474e:	f4658593          	addi	a1,a1,-186 # 80008690 <syscalls+0x238>
    80004752:	0521                	addi	a0,a0,8
    80004754:	ffffc097          	auipc	ra,0xffffc
    80004758:	400080e7          	jalr	1024(ra) # 80000b54 <initlock>
  lk->name = name;
    8000475c:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80004760:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004764:	0204a423          	sw	zero,40(s1)
}
    80004768:	60e2                	ld	ra,24(sp)
    8000476a:	6442                	ld	s0,16(sp)
    8000476c:	64a2                	ld	s1,8(sp)
    8000476e:	6902                	ld	s2,0(sp)
    80004770:	6105                	addi	sp,sp,32
    80004772:	8082                	ret

0000000080004774 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004774:	1101                	addi	sp,sp,-32
    80004776:	ec06                	sd	ra,24(sp)
    80004778:	e822                	sd	s0,16(sp)
    8000477a:	e426                	sd	s1,8(sp)
    8000477c:	e04a                	sd	s2,0(sp)
    8000477e:	1000                	addi	s0,sp,32
    80004780:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004782:	00850913          	addi	s2,a0,8
    80004786:	854a                	mv	a0,s2
    80004788:	ffffc097          	auipc	ra,0xffffc
    8000478c:	45c080e7          	jalr	1116(ra) # 80000be4 <acquire>
  while (lk->locked) {
    80004790:	409c                	lw	a5,0(s1)
    80004792:	cb89                	beqz	a5,800047a4 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004794:	85ca                	mv	a1,s2
    80004796:	8526                	mv	a0,s1
    80004798:	ffffe097          	auipc	ra,0xffffe
    8000479c:	be0080e7          	jalr	-1056(ra) # 80002378 <sleep>
  while (lk->locked) {
    800047a0:	409c                	lw	a5,0(s1)
    800047a2:	fbed                	bnez	a5,80004794 <acquiresleep+0x20>
  }
  lk->locked = 1;
    800047a4:	4785                	li	a5,1
    800047a6:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    800047a8:	ffffd097          	auipc	ra,0xffffd
    800047ac:	220080e7          	jalr	544(ra) # 800019c8 <myproc>
    800047b0:	591c                	lw	a5,48(a0)
    800047b2:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    800047b4:	854a                	mv	a0,s2
    800047b6:	ffffc097          	auipc	ra,0xffffc
    800047ba:	4e2080e7          	jalr	1250(ra) # 80000c98 <release>
}
    800047be:	60e2                	ld	ra,24(sp)
    800047c0:	6442                	ld	s0,16(sp)
    800047c2:	64a2                	ld	s1,8(sp)
    800047c4:	6902                	ld	s2,0(sp)
    800047c6:	6105                	addi	sp,sp,32
    800047c8:	8082                	ret

00000000800047ca <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    800047ca:	1101                	addi	sp,sp,-32
    800047cc:	ec06                	sd	ra,24(sp)
    800047ce:	e822                	sd	s0,16(sp)
    800047d0:	e426                	sd	s1,8(sp)
    800047d2:	e04a                	sd	s2,0(sp)
    800047d4:	1000                	addi	s0,sp,32
    800047d6:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800047d8:	00850913          	addi	s2,a0,8
    800047dc:	854a                	mv	a0,s2
    800047de:	ffffc097          	auipc	ra,0xffffc
    800047e2:	406080e7          	jalr	1030(ra) # 80000be4 <acquire>
  lk->locked = 0;
    800047e6:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800047ea:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    800047ee:	8526                	mv	a0,s1
    800047f0:	ffffe097          	auipc	ra,0xffffe
    800047f4:	d28080e7          	jalr	-728(ra) # 80002518 <wakeup>
  release(&lk->lk);
    800047f8:	854a                	mv	a0,s2
    800047fa:	ffffc097          	auipc	ra,0xffffc
    800047fe:	49e080e7          	jalr	1182(ra) # 80000c98 <release>
}
    80004802:	60e2                	ld	ra,24(sp)
    80004804:	6442                	ld	s0,16(sp)
    80004806:	64a2                	ld	s1,8(sp)
    80004808:	6902                	ld	s2,0(sp)
    8000480a:	6105                	addi	sp,sp,32
    8000480c:	8082                	ret

000000008000480e <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    8000480e:	7179                	addi	sp,sp,-48
    80004810:	f406                	sd	ra,40(sp)
    80004812:	f022                	sd	s0,32(sp)
    80004814:	ec26                	sd	s1,24(sp)
    80004816:	e84a                	sd	s2,16(sp)
    80004818:	e44e                	sd	s3,8(sp)
    8000481a:	1800                	addi	s0,sp,48
    8000481c:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    8000481e:	00850913          	addi	s2,a0,8
    80004822:	854a                	mv	a0,s2
    80004824:	ffffc097          	auipc	ra,0xffffc
    80004828:	3c0080e7          	jalr	960(ra) # 80000be4 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    8000482c:	409c                	lw	a5,0(s1)
    8000482e:	ef99                	bnez	a5,8000484c <holdingsleep+0x3e>
    80004830:	4481                	li	s1,0
  release(&lk->lk);
    80004832:	854a                	mv	a0,s2
    80004834:	ffffc097          	auipc	ra,0xffffc
    80004838:	464080e7          	jalr	1124(ra) # 80000c98 <release>
  return r;
}
    8000483c:	8526                	mv	a0,s1
    8000483e:	70a2                	ld	ra,40(sp)
    80004840:	7402                	ld	s0,32(sp)
    80004842:	64e2                	ld	s1,24(sp)
    80004844:	6942                	ld	s2,16(sp)
    80004846:	69a2                	ld	s3,8(sp)
    80004848:	6145                	addi	sp,sp,48
    8000484a:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    8000484c:	0284a983          	lw	s3,40(s1)
    80004850:	ffffd097          	auipc	ra,0xffffd
    80004854:	178080e7          	jalr	376(ra) # 800019c8 <myproc>
    80004858:	5904                	lw	s1,48(a0)
    8000485a:	413484b3          	sub	s1,s1,s3
    8000485e:	0014b493          	seqz	s1,s1
    80004862:	bfc1                	j	80004832 <holdingsleep+0x24>

0000000080004864 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004864:	1141                	addi	sp,sp,-16
    80004866:	e406                	sd	ra,8(sp)
    80004868:	e022                	sd	s0,0(sp)
    8000486a:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    8000486c:	00004597          	auipc	a1,0x4
    80004870:	e3458593          	addi	a1,a1,-460 # 800086a0 <syscalls+0x248>
    80004874:	0001d517          	auipc	a0,0x1d
    80004878:	36450513          	addi	a0,a0,868 # 80021bd8 <ftable>
    8000487c:	ffffc097          	auipc	ra,0xffffc
    80004880:	2d8080e7          	jalr	728(ra) # 80000b54 <initlock>
}
    80004884:	60a2                	ld	ra,8(sp)
    80004886:	6402                	ld	s0,0(sp)
    80004888:	0141                	addi	sp,sp,16
    8000488a:	8082                	ret

000000008000488c <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    8000488c:	1101                	addi	sp,sp,-32
    8000488e:	ec06                	sd	ra,24(sp)
    80004890:	e822                	sd	s0,16(sp)
    80004892:	e426                	sd	s1,8(sp)
    80004894:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004896:	0001d517          	auipc	a0,0x1d
    8000489a:	34250513          	addi	a0,a0,834 # 80021bd8 <ftable>
    8000489e:	ffffc097          	auipc	ra,0xffffc
    800048a2:	346080e7          	jalr	838(ra) # 80000be4 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800048a6:	0001d497          	auipc	s1,0x1d
    800048aa:	34a48493          	addi	s1,s1,842 # 80021bf0 <ftable+0x18>
    800048ae:	0001e717          	auipc	a4,0x1e
    800048b2:	2e270713          	addi	a4,a4,738 # 80022b90 <ftable+0xfb8>
    if(f->ref == 0){
    800048b6:	40dc                	lw	a5,4(s1)
    800048b8:	cf99                	beqz	a5,800048d6 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800048ba:	02848493          	addi	s1,s1,40
    800048be:	fee49ce3          	bne	s1,a4,800048b6 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    800048c2:	0001d517          	auipc	a0,0x1d
    800048c6:	31650513          	addi	a0,a0,790 # 80021bd8 <ftable>
    800048ca:	ffffc097          	auipc	ra,0xffffc
    800048ce:	3ce080e7          	jalr	974(ra) # 80000c98 <release>
  return 0;
    800048d2:	4481                	li	s1,0
    800048d4:	a819                	j	800048ea <filealloc+0x5e>
      f->ref = 1;
    800048d6:	4785                	li	a5,1
    800048d8:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    800048da:	0001d517          	auipc	a0,0x1d
    800048de:	2fe50513          	addi	a0,a0,766 # 80021bd8 <ftable>
    800048e2:	ffffc097          	auipc	ra,0xffffc
    800048e6:	3b6080e7          	jalr	950(ra) # 80000c98 <release>
}
    800048ea:	8526                	mv	a0,s1
    800048ec:	60e2                	ld	ra,24(sp)
    800048ee:	6442                	ld	s0,16(sp)
    800048f0:	64a2                	ld	s1,8(sp)
    800048f2:	6105                	addi	sp,sp,32
    800048f4:	8082                	ret

00000000800048f6 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    800048f6:	1101                	addi	sp,sp,-32
    800048f8:	ec06                	sd	ra,24(sp)
    800048fa:	e822                	sd	s0,16(sp)
    800048fc:	e426                	sd	s1,8(sp)
    800048fe:	1000                	addi	s0,sp,32
    80004900:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004902:	0001d517          	auipc	a0,0x1d
    80004906:	2d650513          	addi	a0,a0,726 # 80021bd8 <ftable>
    8000490a:	ffffc097          	auipc	ra,0xffffc
    8000490e:	2da080e7          	jalr	730(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    80004912:	40dc                	lw	a5,4(s1)
    80004914:	02f05263          	blez	a5,80004938 <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004918:	2785                	addiw	a5,a5,1
    8000491a:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    8000491c:	0001d517          	auipc	a0,0x1d
    80004920:	2bc50513          	addi	a0,a0,700 # 80021bd8 <ftable>
    80004924:	ffffc097          	auipc	ra,0xffffc
    80004928:	374080e7          	jalr	884(ra) # 80000c98 <release>
  return f;
}
    8000492c:	8526                	mv	a0,s1
    8000492e:	60e2                	ld	ra,24(sp)
    80004930:	6442                	ld	s0,16(sp)
    80004932:	64a2                	ld	s1,8(sp)
    80004934:	6105                	addi	sp,sp,32
    80004936:	8082                	ret
    panic("filedup");
    80004938:	00004517          	auipc	a0,0x4
    8000493c:	d7050513          	addi	a0,a0,-656 # 800086a8 <syscalls+0x250>
    80004940:	ffffc097          	auipc	ra,0xffffc
    80004944:	bfe080e7          	jalr	-1026(ra) # 8000053e <panic>

0000000080004948 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004948:	7139                	addi	sp,sp,-64
    8000494a:	fc06                	sd	ra,56(sp)
    8000494c:	f822                	sd	s0,48(sp)
    8000494e:	f426                	sd	s1,40(sp)
    80004950:	f04a                	sd	s2,32(sp)
    80004952:	ec4e                	sd	s3,24(sp)
    80004954:	e852                	sd	s4,16(sp)
    80004956:	e456                	sd	s5,8(sp)
    80004958:	0080                	addi	s0,sp,64
    8000495a:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    8000495c:	0001d517          	auipc	a0,0x1d
    80004960:	27c50513          	addi	a0,a0,636 # 80021bd8 <ftable>
    80004964:	ffffc097          	auipc	ra,0xffffc
    80004968:	280080e7          	jalr	640(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    8000496c:	40dc                	lw	a5,4(s1)
    8000496e:	06f05163          	blez	a5,800049d0 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004972:	37fd                	addiw	a5,a5,-1
    80004974:	0007871b          	sext.w	a4,a5
    80004978:	c0dc                	sw	a5,4(s1)
    8000497a:	06e04363          	bgtz	a4,800049e0 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    8000497e:	0004a903          	lw	s2,0(s1)
    80004982:	0094ca83          	lbu	s5,9(s1)
    80004986:	0104ba03          	ld	s4,16(s1)
    8000498a:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    8000498e:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004992:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004996:	0001d517          	auipc	a0,0x1d
    8000499a:	24250513          	addi	a0,a0,578 # 80021bd8 <ftable>
    8000499e:	ffffc097          	auipc	ra,0xffffc
    800049a2:	2fa080e7          	jalr	762(ra) # 80000c98 <release>

  if(ff.type == FD_PIPE){
    800049a6:	4785                	li	a5,1
    800049a8:	04f90d63          	beq	s2,a5,80004a02 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    800049ac:	3979                	addiw	s2,s2,-2
    800049ae:	4785                	li	a5,1
    800049b0:	0527e063          	bltu	a5,s2,800049f0 <fileclose+0xa8>
    begin_op();
    800049b4:	00000097          	auipc	ra,0x0
    800049b8:	ac8080e7          	jalr	-1336(ra) # 8000447c <begin_op>
    iput(ff.ip);
    800049bc:	854e                	mv	a0,s3
    800049be:	fffff097          	auipc	ra,0xfffff
    800049c2:	2a6080e7          	jalr	678(ra) # 80003c64 <iput>
    end_op();
    800049c6:	00000097          	auipc	ra,0x0
    800049ca:	b36080e7          	jalr	-1226(ra) # 800044fc <end_op>
    800049ce:	a00d                	j	800049f0 <fileclose+0xa8>
    panic("fileclose");
    800049d0:	00004517          	auipc	a0,0x4
    800049d4:	ce050513          	addi	a0,a0,-800 # 800086b0 <syscalls+0x258>
    800049d8:	ffffc097          	auipc	ra,0xffffc
    800049dc:	b66080e7          	jalr	-1178(ra) # 8000053e <panic>
    release(&ftable.lock);
    800049e0:	0001d517          	auipc	a0,0x1d
    800049e4:	1f850513          	addi	a0,a0,504 # 80021bd8 <ftable>
    800049e8:	ffffc097          	auipc	ra,0xffffc
    800049ec:	2b0080e7          	jalr	688(ra) # 80000c98 <release>
  }
}
    800049f0:	70e2                	ld	ra,56(sp)
    800049f2:	7442                	ld	s0,48(sp)
    800049f4:	74a2                	ld	s1,40(sp)
    800049f6:	7902                	ld	s2,32(sp)
    800049f8:	69e2                	ld	s3,24(sp)
    800049fa:	6a42                	ld	s4,16(sp)
    800049fc:	6aa2                	ld	s5,8(sp)
    800049fe:	6121                	addi	sp,sp,64
    80004a00:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004a02:	85d6                	mv	a1,s5
    80004a04:	8552                	mv	a0,s4
    80004a06:	00000097          	auipc	ra,0x0
    80004a0a:	34c080e7          	jalr	844(ra) # 80004d52 <pipeclose>
    80004a0e:	b7cd                	j	800049f0 <fileclose+0xa8>

0000000080004a10 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004a10:	715d                	addi	sp,sp,-80
    80004a12:	e486                	sd	ra,72(sp)
    80004a14:	e0a2                	sd	s0,64(sp)
    80004a16:	fc26                	sd	s1,56(sp)
    80004a18:	f84a                	sd	s2,48(sp)
    80004a1a:	f44e                	sd	s3,40(sp)
    80004a1c:	0880                	addi	s0,sp,80
    80004a1e:	84aa                	mv	s1,a0
    80004a20:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004a22:	ffffd097          	auipc	ra,0xffffd
    80004a26:	fa6080e7          	jalr	-90(ra) # 800019c8 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004a2a:	409c                	lw	a5,0(s1)
    80004a2c:	37f9                	addiw	a5,a5,-2
    80004a2e:	4705                	li	a4,1
    80004a30:	04f76763          	bltu	a4,a5,80004a7e <filestat+0x6e>
    80004a34:	892a                	mv	s2,a0
    ilock(f->ip);
    80004a36:	6c88                	ld	a0,24(s1)
    80004a38:	fffff097          	auipc	ra,0xfffff
    80004a3c:	072080e7          	jalr	114(ra) # 80003aaa <ilock>
    stati(f->ip, &st);
    80004a40:	fb840593          	addi	a1,s0,-72
    80004a44:	6c88                	ld	a0,24(s1)
    80004a46:	fffff097          	auipc	ra,0xfffff
    80004a4a:	2ee080e7          	jalr	750(ra) # 80003d34 <stati>
    iunlock(f->ip);
    80004a4e:	6c88                	ld	a0,24(s1)
    80004a50:	fffff097          	auipc	ra,0xfffff
    80004a54:	11c080e7          	jalr	284(ra) # 80003b6c <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004a58:	46e1                	li	a3,24
    80004a5a:	fb840613          	addi	a2,s0,-72
    80004a5e:	85ce                	mv	a1,s3
    80004a60:	07093503          	ld	a0,112(s2)
    80004a64:	ffffd097          	auipc	ra,0xffffd
    80004a68:	c16080e7          	jalr	-1002(ra) # 8000167a <copyout>
    80004a6c:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004a70:	60a6                	ld	ra,72(sp)
    80004a72:	6406                	ld	s0,64(sp)
    80004a74:	74e2                	ld	s1,56(sp)
    80004a76:	7942                	ld	s2,48(sp)
    80004a78:	79a2                	ld	s3,40(sp)
    80004a7a:	6161                	addi	sp,sp,80
    80004a7c:	8082                	ret
  return -1;
    80004a7e:	557d                	li	a0,-1
    80004a80:	bfc5                	j	80004a70 <filestat+0x60>

0000000080004a82 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004a82:	7179                	addi	sp,sp,-48
    80004a84:	f406                	sd	ra,40(sp)
    80004a86:	f022                	sd	s0,32(sp)
    80004a88:	ec26                	sd	s1,24(sp)
    80004a8a:	e84a                	sd	s2,16(sp)
    80004a8c:	e44e                	sd	s3,8(sp)
    80004a8e:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004a90:	00854783          	lbu	a5,8(a0)
    80004a94:	c3d5                	beqz	a5,80004b38 <fileread+0xb6>
    80004a96:	84aa                	mv	s1,a0
    80004a98:	89ae                	mv	s3,a1
    80004a9a:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004a9c:	411c                	lw	a5,0(a0)
    80004a9e:	4705                	li	a4,1
    80004aa0:	04e78963          	beq	a5,a4,80004af2 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004aa4:	470d                	li	a4,3
    80004aa6:	04e78d63          	beq	a5,a4,80004b00 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004aaa:	4709                	li	a4,2
    80004aac:	06e79e63          	bne	a5,a4,80004b28 <fileread+0xa6>
    ilock(f->ip);
    80004ab0:	6d08                	ld	a0,24(a0)
    80004ab2:	fffff097          	auipc	ra,0xfffff
    80004ab6:	ff8080e7          	jalr	-8(ra) # 80003aaa <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004aba:	874a                	mv	a4,s2
    80004abc:	5094                	lw	a3,32(s1)
    80004abe:	864e                	mv	a2,s3
    80004ac0:	4585                	li	a1,1
    80004ac2:	6c88                	ld	a0,24(s1)
    80004ac4:	fffff097          	auipc	ra,0xfffff
    80004ac8:	29a080e7          	jalr	666(ra) # 80003d5e <readi>
    80004acc:	892a                	mv	s2,a0
    80004ace:	00a05563          	blez	a0,80004ad8 <fileread+0x56>
      f->off += r;
    80004ad2:	509c                	lw	a5,32(s1)
    80004ad4:	9fa9                	addw	a5,a5,a0
    80004ad6:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004ad8:	6c88                	ld	a0,24(s1)
    80004ada:	fffff097          	auipc	ra,0xfffff
    80004ade:	092080e7          	jalr	146(ra) # 80003b6c <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004ae2:	854a                	mv	a0,s2
    80004ae4:	70a2                	ld	ra,40(sp)
    80004ae6:	7402                	ld	s0,32(sp)
    80004ae8:	64e2                	ld	s1,24(sp)
    80004aea:	6942                	ld	s2,16(sp)
    80004aec:	69a2                	ld	s3,8(sp)
    80004aee:	6145                	addi	sp,sp,48
    80004af0:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004af2:	6908                	ld	a0,16(a0)
    80004af4:	00000097          	auipc	ra,0x0
    80004af8:	3c8080e7          	jalr	968(ra) # 80004ebc <piperead>
    80004afc:	892a                	mv	s2,a0
    80004afe:	b7d5                	j	80004ae2 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004b00:	02451783          	lh	a5,36(a0)
    80004b04:	03079693          	slli	a3,a5,0x30
    80004b08:	92c1                	srli	a3,a3,0x30
    80004b0a:	4725                	li	a4,9
    80004b0c:	02d76863          	bltu	a4,a3,80004b3c <fileread+0xba>
    80004b10:	0792                	slli	a5,a5,0x4
    80004b12:	0001d717          	auipc	a4,0x1d
    80004b16:	02670713          	addi	a4,a4,38 # 80021b38 <devsw>
    80004b1a:	97ba                	add	a5,a5,a4
    80004b1c:	639c                	ld	a5,0(a5)
    80004b1e:	c38d                	beqz	a5,80004b40 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004b20:	4505                	li	a0,1
    80004b22:	9782                	jalr	a5
    80004b24:	892a                	mv	s2,a0
    80004b26:	bf75                	j	80004ae2 <fileread+0x60>
    panic("fileread");
    80004b28:	00004517          	auipc	a0,0x4
    80004b2c:	b9850513          	addi	a0,a0,-1128 # 800086c0 <syscalls+0x268>
    80004b30:	ffffc097          	auipc	ra,0xffffc
    80004b34:	a0e080e7          	jalr	-1522(ra) # 8000053e <panic>
    return -1;
    80004b38:	597d                	li	s2,-1
    80004b3a:	b765                	j	80004ae2 <fileread+0x60>
      return -1;
    80004b3c:	597d                	li	s2,-1
    80004b3e:	b755                	j	80004ae2 <fileread+0x60>
    80004b40:	597d                	li	s2,-1
    80004b42:	b745                	j	80004ae2 <fileread+0x60>

0000000080004b44 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80004b44:	715d                	addi	sp,sp,-80
    80004b46:	e486                	sd	ra,72(sp)
    80004b48:	e0a2                	sd	s0,64(sp)
    80004b4a:	fc26                	sd	s1,56(sp)
    80004b4c:	f84a                	sd	s2,48(sp)
    80004b4e:	f44e                	sd	s3,40(sp)
    80004b50:	f052                	sd	s4,32(sp)
    80004b52:	ec56                	sd	s5,24(sp)
    80004b54:	e85a                	sd	s6,16(sp)
    80004b56:	e45e                	sd	s7,8(sp)
    80004b58:	e062                	sd	s8,0(sp)
    80004b5a:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80004b5c:	00954783          	lbu	a5,9(a0)
    80004b60:	10078663          	beqz	a5,80004c6c <filewrite+0x128>
    80004b64:	892a                	mv	s2,a0
    80004b66:	8aae                	mv	s5,a1
    80004b68:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004b6a:	411c                	lw	a5,0(a0)
    80004b6c:	4705                	li	a4,1
    80004b6e:	02e78263          	beq	a5,a4,80004b92 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004b72:	470d                	li	a4,3
    80004b74:	02e78663          	beq	a5,a4,80004ba0 <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004b78:	4709                	li	a4,2
    80004b7a:	0ee79163          	bne	a5,a4,80004c5c <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004b7e:	0ac05d63          	blez	a2,80004c38 <filewrite+0xf4>
    int i = 0;
    80004b82:	4981                	li	s3,0
    80004b84:	6b05                	lui	s6,0x1
    80004b86:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80004b8a:	6b85                	lui	s7,0x1
    80004b8c:	c00b8b9b          	addiw	s7,s7,-1024
    80004b90:	a861                	j	80004c28 <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80004b92:	6908                	ld	a0,16(a0)
    80004b94:	00000097          	auipc	ra,0x0
    80004b98:	22e080e7          	jalr	558(ra) # 80004dc2 <pipewrite>
    80004b9c:	8a2a                	mv	s4,a0
    80004b9e:	a045                	j	80004c3e <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004ba0:	02451783          	lh	a5,36(a0)
    80004ba4:	03079693          	slli	a3,a5,0x30
    80004ba8:	92c1                	srli	a3,a3,0x30
    80004baa:	4725                	li	a4,9
    80004bac:	0cd76263          	bltu	a4,a3,80004c70 <filewrite+0x12c>
    80004bb0:	0792                	slli	a5,a5,0x4
    80004bb2:	0001d717          	auipc	a4,0x1d
    80004bb6:	f8670713          	addi	a4,a4,-122 # 80021b38 <devsw>
    80004bba:	97ba                	add	a5,a5,a4
    80004bbc:	679c                	ld	a5,8(a5)
    80004bbe:	cbdd                	beqz	a5,80004c74 <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80004bc0:	4505                	li	a0,1
    80004bc2:	9782                	jalr	a5
    80004bc4:	8a2a                	mv	s4,a0
    80004bc6:	a8a5                	j	80004c3e <filewrite+0xfa>
    80004bc8:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004bcc:	00000097          	auipc	ra,0x0
    80004bd0:	8b0080e7          	jalr	-1872(ra) # 8000447c <begin_op>
      ilock(f->ip);
    80004bd4:	01893503          	ld	a0,24(s2)
    80004bd8:	fffff097          	auipc	ra,0xfffff
    80004bdc:	ed2080e7          	jalr	-302(ra) # 80003aaa <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004be0:	8762                	mv	a4,s8
    80004be2:	02092683          	lw	a3,32(s2)
    80004be6:	01598633          	add	a2,s3,s5
    80004bea:	4585                	li	a1,1
    80004bec:	01893503          	ld	a0,24(s2)
    80004bf0:	fffff097          	auipc	ra,0xfffff
    80004bf4:	266080e7          	jalr	614(ra) # 80003e56 <writei>
    80004bf8:	84aa                	mv	s1,a0
    80004bfa:	00a05763          	blez	a0,80004c08 <filewrite+0xc4>
        f->off += r;
    80004bfe:	02092783          	lw	a5,32(s2)
    80004c02:	9fa9                	addw	a5,a5,a0
    80004c04:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004c08:	01893503          	ld	a0,24(s2)
    80004c0c:	fffff097          	auipc	ra,0xfffff
    80004c10:	f60080e7          	jalr	-160(ra) # 80003b6c <iunlock>
      end_op();
    80004c14:	00000097          	auipc	ra,0x0
    80004c18:	8e8080e7          	jalr	-1816(ra) # 800044fc <end_op>

      if(r != n1){
    80004c1c:	009c1f63          	bne	s8,s1,80004c3a <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80004c20:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004c24:	0149db63          	bge	s3,s4,80004c3a <filewrite+0xf6>
      int n1 = n - i;
    80004c28:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80004c2c:	84be                	mv	s1,a5
    80004c2e:	2781                	sext.w	a5,a5
    80004c30:	f8fb5ce3          	bge	s6,a5,80004bc8 <filewrite+0x84>
    80004c34:	84de                	mv	s1,s7
    80004c36:	bf49                	j	80004bc8 <filewrite+0x84>
    int i = 0;
    80004c38:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004c3a:	013a1f63          	bne	s4,s3,80004c58 <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004c3e:	8552                	mv	a0,s4
    80004c40:	60a6                	ld	ra,72(sp)
    80004c42:	6406                	ld	s0,64(sp)
    80004c44:	74e2                	ld	s1,56(sp)
    80004c46:	7942                	ld	s2,48(sp)
    80004c48:	79a2                	ld	s3,40(sp)
    80004c4a:	7a02                	ld	s4,32(sp)
    80004c4c:	6ae2                	ld	s5,24(sp)
    80004c4e:	6b42                	ld	s6,16(sp)
    80004c50:	6ba2                	ld	s7,8(sp)
    80004c52:	6c02                	ld	s8,0(sp)
    80004c54:	6161                	addi	sp,sp,80
    80004c56:	8082                	ret
    ret = (i == n ? n : -1);
    80004c58:	5a7d                	li	s4,-1
    80004c5a:	b7d5                	j	80004c3e <filewrite+0xfa>
    panic("filewrite");
    80004c5c:	00004517          	auipc	a0,0x4
    80004c60:	a7450513          	addi	a0,a0,-1420 # 800086d0 <syscalls+0x278>
    80004c64:	ffffc097          	auipc	ra,0xffffc
    80004c68:	8da080e7          	jalr	-1830(ra) # 8000053e <panic>
    return -1;
    80004c6c:	5a7d                	li	s4,-1
    80004c6e:	bfc1                	j	80004c3e <filewrite+0xfa>
      return -1;
    80004c70:	5a7d                	li	s4,-1
    80004c72:	b7f1                	j	80004c3e <filewrite+0xfa>
    80004c74:	5a7d                	li	s4,-1
    80004c76:	b7e1                	j	80004c3e <filewrite+0xfa>

0000000080004c78 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004c78:	7179                	addi	sp,sp,-48
    80004c7a:	f406                	sd	ra,40(sp)
    80004c7c:	f022                	sd	s0,32(sp)
    80004c7e:	ec26                	sd	s1,24(sp)
    80004c80:	e84a                	sd	s2,16(sp)
    80004c82:	e44e                	sd	s3,8(sp)
    80004c84:	e052                	sd	s4,0(sp)
    80004c86:	1800                	addi	s0,sp,48
    80004c88:	84aa                	mv	s1,a0
    80004c8a:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004c8c:	0005b023          	sd	zero,0(a1)
    80004c90:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004c94:	00000097          	auipc	ra,0x0
    80004c98:	bf8080e7          	jalr	-1032(ra) # 8000488c <filealloc>
    80004c9c:	e088                	sd	a0,0(s1)
    80004c9e:	c551                	beqz	a0,80004d2a <pipealloc+0xb2>
    80004ca0:	00000097          	auipc	ra,0x0
    80004ca4:	bec080e7          	jalr	-1044(ra) # 8000488c <filealloc>
    80004ca8:	00aa3023          	sd	a0,0(s4)
    80004cac:	c92d                	beqz	a0,80004d1e <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004cae:	ffffc097          	auipc	ra,0xffffc
    80004cb2:	e46080e7          	jalr	-442(ra) # 80000af4 <kalloc>
    80004cb6:	892a                	mv	s2,a0
    80004cb8:	c125                	beqz	a0,80004d18 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004cba:	4985                	li	s3,1
    80004cbc:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004cc0:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004cc4:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004cc8:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004ccc:	00004597          	auipc	a1,0x4
    80004cd0:	a1458593          	addi	a1,a1,-1516 # 800086e0 <syscalls+0x288>
    80004cd4:	ffffc097          	auipc	ra,0xffffc
    80004cd8:	e80080e7          	jalr	-384(ra) # 80000b54 <initlock>
  (*f0)->type = FD_PIPE;
    80004cdc:	609c                	ld	a5,0(s1)
    80004cde:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004ce2:	609c                	ld	a5,0(s1)
    80004ce4:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004ce8:	609c                	ld	a5,0(s1)
    80004cea:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004cee:	609c                	ld	a5,0(s1)
    80004cf0:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004cf4:	000a3783          	ld	a5,0(s4)
    80004cf8:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004cfc:	000a3783          	ld	a5,0(s4)
    80004d00:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004d04:	000a3783          	ld	a5,0(s4)
    80004d08:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004d0c:	000a3783          	ld	a5,0(s4)
    80004d10:	0127b823          	sd	s2,16(a5)
  return 0;
    80004d14:	4501                	li	a0,0
    80004d16:	a025                	j	80004d3e <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004d18:	6088                	ld	a0,0(s1)
    80004d1a:	e501                	bnez	a0,80004d22 <pipealloc+0xaa>
    80004d1c:	a039                	j	80004d2a <pipealloc+0xb2>
    80004d1e:	6088                	ld	a0,0(s1)
    80004d20:	c51d                	beqz	a0,80004d4e <pipealloc+0xd6>
    fileclose(*f0);
    80004d22:	00000097          	auipc	ra,0x0
    80004d26:	c26080e7          	jalr	-986(ra) # 80004948 <fileclose>
  if(*f1)
    80004d2a:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004d2e:	557d                	li	a0,-1
  if(*f1)
    80004d30:	c799                	beqz	a5,80004d3e <pipealloc+0xc6>
    fileclose(*f1);
    80004d32:	853e                	mv	a0,a5
    80004d34:	00000097          	auipc	ra,0x0
    80004d38:	c14080e7          	jalr	-1004(ra) # 80004948 <fileclose>
  return -1;
    80004d3c:	557d                	li	a0,-1
}
    80004d3e:	70a2                	ld	ra,40(sp)
    80004d40:	7402                	ld	s0,32(sp)
    80004d42:	64e2                	ld	s1,24(sp)
    80004d44:	6942                	ld	s2,16(sp)
    80004d46:	69a2                	ld	s3,8(sp)
    80004d48:	6a02                	ld	s4,0(sp)
    80004d4a:	6145                	addi	sp,sp,48
    80004d4c:	8082                	ret
  return -1;
    80004d4e:	557d                	li	a0,-1
    80004d50:	b7fd                	j	80004d3e <pipealloc+0xc6>

0000000080004d52 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004d52:	1101                	addi	sp,sp,-32
    80004d54:	ec06                	sd	ra,24(sp)
    80004d56:	e822                	sd	s0,16(sp)
    80004d58:	e426                	sd	s1,8(sp)
    80004d5a:	e04a                	sd	s2,0(sp)
    80004d5c:	1000                	addi	s0,sp,32
    80004d5e:	84aa                	mv	s1,a0
    80004d60:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004d62:	ffffc097          	auipc	ra,0xffffc
    80004d66:	e82080e7          	jalr	-382(ra) # 80000be4 <acquire>
  if(writable){
    80004d6a:	02090d63          	beqz	s2,80004da4 <pipeclose+0x52>
    pi->writeopen = 0;
    80004d6e:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004d72:	21848513          	addi	a0,s1,536
    80004d76:	ffffd097          	auipc	ra,0xffffd
    80004d7a:	7a2080e7          	jalr	1954(ra) # 80002518 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004d7e:	2204b783          	ld	a5,544(s1)
    80004d82:	eb95                	bnez	a5,80004db6 <pipeclose+0x64>
    release(&pi->lock);
    80004d84:	8526                	mv	a0,s1
    80004d86:	ffffc097          	auipc	ra,0xffffc
    80004d8a:	f12080e7          	jalr	-238(ra) # 80000c98 <release>
    kfree((char*)pi);
    80004d8e:	8526                	mv	a0,s1
    80004d90:	ffffc097          	auipc	ra,0xffffc
    80004d94:	c68080e7          	jalr	-920(ra) # 800009f8 <kfree>
  } else
    release(&pi->lock);
}
    80004d98:	60e2                	ld	ra,24(sp)
    80004d9a:	6442                	ld	s0,16(sp)
    80004d9c:	64a2                	ld	s1,8(sp)
    80004d9e:	6902                	ld	s2,0(sp)
    80004da0:	6105                	addi	sp,sp,32
    80004da2:	8082                	ret
    pi->readopen = 0;
    80004da4:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004da8:	21c48513          	addi	a0,s1,540
    80004dac:	ffffd097          	auipc	ra,0xffffd
    80004db0:	76c080e7          	jalr	1900(ra) # 80002518 <wakeup>
    80004db4:	b7e9                	j	80004d7e <pipeclose+0x2c>
    release(&pi->lock);
    80004db6:	8526                	mv	a0,s1
    80004db8:	ffffc097          	auipc	ra,0xffffc
    80004dbc:	ee0080e7          	jalr	-288(ra) # 80000c98 <release>
}
    80004dc0:	bfe1                	j	80004d98 <pipeclose+0x46>

0000000080004dc2 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004dc2:	7159                	addi	sp,sp,-112
    80004dc4:	f486                	sd	ra,104(sp)
    80004dc6:	f0a2                	sd	s0,96(sp)
    80004dc8:	eca6                	sd	s1,88(sp)
    80004dca:	e8ca                	sd	s2,80(sp)
    80004dcc:	e4ce                	sd	s3,72(sp)
    80004dce:	e0d2                	sd	s4,64(sp)
    80004dd0:	fc56                	sd	s5,56(sp)
    80004dd2:	f85a                	sd	s6,48(sp)
    80004dd4:	f45e                	sd	s7,40(sp)
    80004dd6:	f062                	sd	s8,32(sp)
    80004dd8:	ec66                	sd	s9,24(sp)
    80004dda:	1880                	addi	s0,sp,112
    80004ddc:	84aa                	mv	s1,a0
    80004dde:	8aae                	mv	s5,a1
    80004de0:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004de2:	ffffd097          	auipc	ra,0xffffd
    80004de6:	be6080e7          	jalr	-1050(ra) # 800019c8 <myproc>
    80004dea:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004dec:	8526                	mv	a0,s1
    80004dee:	ffffc097          	auipc	ra,0xffffc
    80004df2:	df6080e7          	jalr	-522(ra) # 80000be4 <acquire>
  while(i < n){
    80004df6:	0d405163          	blez	s4,80004eb8 <pipewrite+0xf6>
    80004dfa:	8ba6                	mv	s7,s1
  int i = 0;
    80004dfc:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004dfe:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004e00:	21848c93          	addi	s9,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004e04:	21c48c13          	addi	s8,s1,540
    80004e08:	a08d                	j	80004e6a <pipewrite+0xa8>
      release(&pi->lock);
    80004e0a:	8526                	mv	a0,s1
    80004e0c:	ffffc097          	auipc	ra,0xffffc
    80004e10:	e8c080e7          	jalr	-372(ra) # 80000c98 <release>
      return -1;
    80004e14:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004e16:	854a                	mv	a0,s2
    80004e18:	70a6                	ld	ra,104(sp)
    80004e1a:	7406                	ld	s0,96(sp)
    80004e1c:	64e6                	ld	s1,88(sp)
    80004e1e:	6946                	ld	s2,80(sp)
    80004e20:	69a6                	ld	s3,72(sp)
    80004e22:	6a06                	ld	s4,64(sp)
    80004e24:	7ae2                	ld	s5,56(sp)
    80004e26:	7b42                	ld	s6,48(sp)
    80004e28:	7ba2                	ld	s7,40(sp)
    80004e2a:	7c02                	ld	s8,32(sp)
    80004e2c:	6ce2                	ld	s9,24(sp)
    80004e2e:	6165                	addi	sp,sp,112
    80004e30:	8082                	ret
      wakeup(&pi->nread);
    80004e32:	8566                	mv	a0,s9
    80004e34:	ffffd097          	auipc	ra,0xffffd
    80004e38:	6e4080e7          	jalr	1764(ra) # 80002518 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004e3c:	85de                	mv	a1,s7
    80004e3e:	8562                	mv	a0,s8
    80004e40:	ffffd097          	auipc	ra,0xffffd
    80004e44:	538080e7          	jalr	1336(ra) # 80002378 <sleep>
    80004e48:	a839                	j	80004e66 <pipewrite+0xa4>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004e4a:	21c4a783          	lw	a5,540(s1)
    80004e4e:	0017871b          	addiw	a4,a5,1
    80004e52:	20e4ae23          	sw	a4,540(s1)
    80004e56:	1ff7f793          	andi	a5,a5,511
    80004e5a:	97a6                	add	a5,a5,s1
    80004e5c:	f9f44703          	lbu	a4,-97(s0)
    80004e60:	00e78c23          	sb	a4,24(a5)
      i++;
    80004e64:	2905                	addiw	s2,s2,1
  while(i < n){
    80004e66:	03495d63          	bge	s2,s4,80004ea0 <pipewrite+0xde>
    if(pi->readopen == 0 || pr->killed){
    80004e6a:	2204a783          	lw	a5,544(s1)
    80004e6e:	dfd1                	beqz	a5,80004e0a <pipewrite+0x48>
    80004e70:	0289a783          	lw	a5,40(s3)
    80004e74:	fbd9                	bnez	a5,80004e0a <pipewrite+0x48>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004e76:	2184a783          	lw	a5,536(s1)
    80004e7a:	21c4a703          	lw	a4,540(s1)
    80004e7e:	2007879b          	addiw	a5,a5,512
    80004e82:	faf708e3          	beq	a4,a5,80004e32 <pipewrite+0x70>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004e86:	4685                	li	a3,1
    80004e88:	01590633          	add	a2,s2,s5
    80004e8c:	f9f40593          	addi	a1,s0,-97
    80004e90:	0709b503          	ld	a0,112(s3)
    80004e94:	ffffd097          	auipc	ra,0xffffd
    80004e98:	872080e7          	jalr	-1934(ra) # 80001706 <copyin>
    80004e9c:	fb6517e3          	bne	a0,s6,80004e4a <pipewrite+0x88>
  wakeup(&pi->nread);
    80004ea0:	21848513          	addi	a0,s1,536
    80004ea4:	ffffd097          	auipc	ra,0xffffd
    80004ea8:	674080e7          	jalr	1652(ra) # 80002518 <wakeup>
  release(&pi->lock);
    80004eac:	8526                	mv	a0,s1
    80004eae:	ffffc097          	auipc	ra,0xffffc
    80004eb2:	dea080e7          	jalr	-534(ra) # 80000c98 <release>
  return i;
    80004eb6:	b785                	j	80004e16 <pipewrite+0x54>
  int i = 0;
    80004eb8:	4901                	li	s2,0
    80004eba:	b7dd                	j	80004ea0 <pipewrite+0xde>

0000000080004ebc <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004ebc:	715d                	addi	sp,sp,-80
    80004ebe:	e486                	sd	ra,72(sp)
    80004ec0:	e0a2                	sd	s0,64(sp)
    80004ec2:	fc26                	sd	s1,56(sp)
    80004ec4:	f84a                	sd	s2,48(sp)
    80004ec6:	f44e                	sd	s3,40(sp)
    80004ec8:	f052                	sd	s4,32(sp)
    80004eca:	ec56                	sd	s5,24(sp)
    80004ecc:	e85a                	sd	s6,16(sp)
    80004ece:	0880                	addi	s0,sp,80
    80004ed0:	84aa                	mv	s1,a0
    80004ed2:	892e                	mv	s2,a1
    80004ed4:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004ed6:	ffffd097          	auipc	ra,0xffffd
    80004eda:	af2080e7          	jalr	-1294(ra) # 800019c8 <myproc>
    80004ede:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004ee0:	8b26                	mv	s6,s1
    80004ee2:	8526                	mv	a0,s1
    80004ee4:	ffffc097          	auipc	ra,0xffffc
    80004ee8:	d00080e7          	jalr	-768(ra) # 80000be4 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004eec:	2184a703          	lw	a4,536(s1)
    80004ef0:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004ef4:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004ef8:	02f71463          	bne	a4,a5,80004f20 <piperead+0x64>
    80004efc:	2244a783          	lw	a5,548(s1)
    80004f00:	c385                	beqz	a5,80004f20 <piperead+0x64>
    if(pr->killed){
    80004f02:	028a2783          	lw	a5,40(s4)
    80004f06:	ebc1                	bnez	a5,80004f96 <piperead+0xda>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004f08:	85da                	mv	a1,s6
    80004f0a:	854e                	mv	a0,s3
    80004f0c:	ffffd097          	auipc	ra,0xffffd
    80004f10:	46c080e7          	jalr	1132(ra) # 80002378 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004f14:	2184a703          	lw	a4,536(s1)
    80004f18:	21c4a783          	lw	a5,540(s1)
    80004f1c:	fef700e3          	beq	a4,a5,80004efc <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004f20:	09505263          	blez	s5,80004fa4 <piperead+0xe8>
    80004f24:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004f26:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    80004f28:	2184a783          	lw	a5,536(s1)
    80004f2c:	21c4a703          	lw	a4,540(s1)
    80004f30:	02f70d63          	beq	a4,a5,80004f6a <piperead+0xae>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004f34:	0017871b          	addiw	a4,a5,1
    80004f38:	20e4ac23          	sw	a4,536(s1)
    80004f3c:	1ff7f793          	andi	a5,a5,511
    80004f40:	97a6                	add	a5,a5,s1
    80004f42:	0187c783          	lbu	a5,24(a5)
    80004f46:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004f4a:	4685                	li	a3,1
    80004f4c:	fbf40613          	addi	a2,s0,-65
    80004f50:	85ca                	mv	a1,s2
    80004f52:	070a3503          	ld	a0,112(s4)
    80004f56:	ffffc097          	auipc	ra,0xffffc
    80004f5a:	724080e7          	jalr	1828(ra) # 8000167a <copyout>
    80004f5e:	01650663          	beq	a0,s6,80004f6a <piperead+0xae>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004f62:	2985                	addiw	s3,s3,1
    80004f64:	0905                	addi	s2,s2,1
    80004f66:	fd3a91e3          	bne	s5,s3,80004f28 <piperead+0x6c>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004f6a:	21c48513          	addi	a0,s1,540
    80004f6e:	ffffd097          	auipc	ra,0xffffd
    80004f72:	5aa080e7          	jalr	1450(ra) # 80002518 <wakeup>
  release(&pi->lock);
    80004f76:	8526                	mv	a0,s1
    80004f78:	ffffc097          	auipc	ra,0xffffc
    80004f7c:	d20080e7          	jalr	-736(ra) # 80000c98 <release>
  return i;
}
    80004f80:	854e                	mv	a0,s3
    80004f82:	60a6                	ld	ra,72(sp)
    80004f84:	6406                	ld	s0,64(sp)
    80004f86:	74e2                	ld	s1,56(sp)
    80004f88:	7942                	ld	s2,48(sp)
    80004f8a:	79a2                	ld	s3,40(sp)
    80004f8c:	7a02                	ld	s4,32(sp)
    80004f8e:	6ae2                	ld	s5,24(sp)
    80004f90:	6b42                	ld	s6,16(sp)
    80004f92:	6161                	addi	sp,sp,80
    80004f94:	8082                	ret
      release(&pi->lock);
    80004f96:	8526                	mv	a0,s1
    80004f98:	ffffc097          	auipc	ra,0xffffc
    80004f9c:	d00080e7          	jalr	-768(ra) # 80000c98 <release>
      return -1;
    80004fa0:	59fd                	li	s3,-1
    80004fa2:	bff9                	j	80004f80 <piperead+0xc4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004fa4:	4981                	li	s3,0
    80004fa6:	b7d1                	j	80004f6a <piperead+0xae>

0000000080004fa8 <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80004fa8:	df010113          	addi	sp,sp,-528
    80004fac:	20113423          	sd	ra,520(sp)
    80004fb0:	20813023          	sd	s0,512(sp)
    80004fb4:	ffa6                	sd	s1,504(sp)
    80004fb6:	fbca                	sd	s2,496(sp)
    80004fb8:	f7ce                	sd	s3,488(sp)
    80004fba:	f3d2                	sd	s4,480(sp)
    80004fbc:	efd6                	sd	s5,472(sp)
    80004fbe:	ebda                	sd	s6,464(sp)
    80004fc0:	e7de                	sd	s7,456(sp)
    80004fc2:	e3e2                	sd	s8,448(sp)
    80004fc4:	ff66                	sd	s9,440(sp)
    80004fc6:	fb6a                	sd	s10,432(sp)
    80004fc8:	f76e                	sd	s11,424(sp)
    80004fca:	0c00                	addi	s0,sp,528
    80004fcc:	84aa                	mv	s1,a0
    80004fce:	dea43c23          	sd	a0,-520(s0)
    80004fd2:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004fd6:	ffffd097          	auipc	ra,0xffffd
    80004fda:	9f2080e7          	jalr	-1550(ra) # 800019c8 <myproc>
    80004fde:	892a                	mv	s2,a0

  begin_op();
    80004fe0:	fffff097          	auipc	ra,0xfffff
    80004fe4:	49c080e7          	jalr	1180(ra) # 8000447c <begin_op>

  if((ip = namei(path)) == 0){
    80004fe8:	8526                	mv	a0,s1
    80004fea:	fffff097          	auipc	ra,0xfffff
    80004fee:	276080e7          	jalr	630(ra) # 80004260 <namei>
    80004ff2:	c92d                	beqz	a0,80005064 <exec+0xbc>
    80004ff4:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004ff6:	fffff097          	auipc	ra,0xfffff
    80004ffa:	ab4080e7          	jalr	-1356(ra) # 80003aaa <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004ffe:	04000713          	li	a4,64
    80005002:	4681                	li	a3,0
    80005004:	e5040613          	addi	a2,s0,-432
    80005008:	4581                	li	a1,0
    8000500a:	8526                	mv	a0,s1
    8000500c:	fffff097          	auipc	ra,0xfffff
    80005010:	d52080e7          	jalr	-686(ra) # 80003d5e <readi>
    80005014:	04000793          	li	a5,64
    80005018:	00f51a63          	bne	a0,a5,8000502c <exec+0x84>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    8000501c:	e5042703          	lw	a4,-432(s0)
    80005020:	464c47b7          	lui	a5,0x464c4
    80005024:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80005028:	04f70463          	beq	a4,a5,80005070 <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    8000502c:	8526                	mv	a0,s1
    8000502e:	fffff097          	auipc	ra,0xfffff
    80005032:	cde080e7          	jalr	-802(ra) # 80003d0c <iunlockput>
    end_op();
    80005036:	fffff097          	auipc	ra,0xfffff
    8000503a:	4c6080e7          	jalr	1222(ra) # 800044fc <end_op>
  }
  return -1;
    8000503e:	557d                	li	a0,-1
}
    80005040:	20813083          	ld	ra,520(sp)
    80005044:	20013403          	ld	s0,512(sp)
    80005048:	74fe                	ld	s1,504(sp)
    8000504a:	795e                	ld	s2,496(sp)
    8000504c:	79be                	ld	s3,488(sp)
    8000504e:	7a1e                	ld	s4,480(sp)
    80005050:	6afe                	ld	s5,472(sp)
    80005052:	6b5e                	ld	s6,464(sp)
    80005054:	6bbe                	ld	s7,456(sp)
    80005056:	6c1e                	ld	s8,448(sp)
    80005058:	7cfa                	ld	s9,440(sp)
    8000505a:	7d5a                	ld	s10,432(sp)
    8000505c:	7dba                	ld	s11,424(sp)
    8000505e:	21010113          	addi	sp,sp,528
    80005062:	8082                	ret
    end_op();
    80005064:	fffff097          	auipc	ra,0xfffff
    80005068:	498080e7          	jalr	1176(ra) # 800044fc <end_op>
    return -1;
    8000506c:	557d                	li	a0,-1
    8000506e:	bfc9                	j	80005040 <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    80005070:	854a                	mv	a0,s2
    80005072:	ffffd097          	auipc	ra,0xffffd
    80005076:	a1a080e7          	jalr	-1510(ra) # 80001a8c <proc_pagetable>
    8000507a:	8baa                	mv	s7,a0
    8000507c:	d945                	beqz	a0,8000502c <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    8000507e:	e7042983          	lw	s3,-400(s0)
    80005082:	e8845783          	lhu	a5,-376(s0)
    80005086:	c7ad                	beqz	a5,800050f0 <exec+0x148>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80005088:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    8000508a:	4b01                	li	s6,0
    if((ph.vaddr % PGSIZE) != 0)
    8000508c:	6c85                	lui	s9,0x1
    8000508e:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    80005092:	def43823          	sd	a5,-528(s0)
    80005096:	a42d                	j	800052c0 <exec+0x318>
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80005098:	00003517          	auipc	a0,0x3
    8000509c:	65050513          	addi	a0,a0,1616 # 800086e8 <syscalls+0x290>
    800050a0:	ffffb097          	auipc	ra,0xffffb
    800050a4:	49e080e7          	jalr	1182(ra) # 8000053e <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    800050a8:	8756                	mv	a4,s5
    800050aa:	012d86bb          	addw	a3,s11,s2
    800050ae:	4581                	li	a1,0
    800050b0:	8526                	mv	a0,s1
    800050b2:	fffff097          	auipc	ra,0xfffff
    800050b6:	cac080e7          	jalr	-852(ra) # 80003d5e <readi>
    800050ba:	2501                	sext.w	a0,a0
    800050bc:	1aaa9963          	bne	s5,a0,8000526e <exec+0x2c6>
  for(i = 0; i < sz; i += PGSIZE){
    800050c0:	6785                	lui	a5,0x1
    800050c2:	0127893b          	addw	s2,a5,s2
    800050c6:	77fd                	lui	a5,0xfffff
    800050c8:	01478a3b          	addw	s4,a5,s4
    800050cc:	1f897163          	bgeu	s2,s8,800052ae <exec+0x306>
    pa = walkaddr(pagetable, va + i);
    800050d0:	02091593          	slli	a1,s2,0x20
    800050d4:	9181                	srli	a1,a1,0x20
    800050d6:	95ea                	add	a1,a1,s10
    800050d8:	855e                	mv	a0,s7
    800050da:	ffffc097          	auipc	ra,0xffffc
    800050de:	f9c080e7          	jalr	-100(ra) # 80001076 <walkaddr>
    800050e2:	862a                	mv	a2,a0
    if(pa == 0)
    800050e4:	d955                	beqz	a0,80005098 <exec+0xf0>
      n = PGSIZE;
    800050e6:	8ae6                	mv	s5,s9
    if(sz - i < PGSIZE)
    800050e8:	fd9a70e3          	bgeu	s4,s9,800050a8 <exec+0x100>
      n = sz - i;
    800050ec:	8ad2                	mv	s5,s4
    800050ee:	bf6d                	j	800050a8 <exec+0x100>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    800050f0:	4901                	li	s2,0
  iunlockput(ip);
    800050f2:	8526                	mv	a0,s1
    800050f4:	fffff097          	auipc	ra,0xfffff
    800050f8:	c18080e7          	jalr	-1000(ra) # 80003d0c <iunlockput>
  end_op();
    800050fc:	fffff097          	auipc	ra,0xfffff
    80005100:	400080e7          	jalr	1024(ra) # 800044fc <end_op>
  p = myproc();
    80005104:	ffffd097          	auipc	ra,0xffffd
    80005108:	8c4080e7          	jalr	-1852(ra) # 800019c8 <myproc>
    8000510c:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    8000510e:	06853d03          	ld	s10,104(a0)
  sz = PGROUNDUP(sz);
    80005112:	6785                	lui	a5,0x1
    80005114:	17fd                	addi	a5,a5,-1
    80005116:	993e                	add	s2,s2,a5
    80005118:	757d                	lui	a0,0xfffff
    8000511a:	00a977b3          	and	a5,s2,a0
    8000511e:	e0f43423          	sd	a5,-504(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80005122:	6609                	lui	a2,0x2
    80005124:	963e                	add	a2,a2,a5
    80005126:	85be                	mv	a1,a5
    80005128:	855e                	mv	a0,s7
    8000512a:	ffffc097          	auipc	ra,0xffffc
    8000512e:	300080e7          	jalr	768(ra) # 8000142a <uvmalloc>
    80005132:	8b2a                	mv	s6,a0
  ip = 0;
    80005134:	4481                	li	s1,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80005136:	12050c63          	beqz	a0,8000526e <exec+0x2c6>
  uvmclear(pagetable, sz-2*PGSIZE);
    8000513a:	75f9                	lui	a1,0xffffe
    8000513c:	95aa                	add	a1,a1,a0
    8000513e:	855e                	mv	a0,s7
    80005140:	ffffc097          	auipc	ra,0xffffc
    80005144:	508080e7          	jalr	1288(ra) # 80001648 <uvmclear>
  stackbase = sp - PGSIZE;
    80005148:	7c7d                	lui	s8,0xfffff
    8000514a:	9c5a                	add	s8,s8,s6
  for(argc = 0; argv[argc]; argc++) {
    8000514c:	e0043783          	ld	a5,-512(s0)
    80005150:	6388                	ld	a0,0(a5)
    80005152:	c535                	beqz	a0,800051be <exec+0x216>
    80005154:	e9040993          	addi	s3,s0,-368
    80005158:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    8000515c:	895a                	mv	s2,s6
    sp -= strlen(argv[argc]) + 1;
    8000515e:	ffffc097          	auipc	ra,0xffffc
    80005162:	d06080e7          	jalr	-762(ra) # 80000e64 <strlen>
    80005166:	2505                	addiw	a0,a0,1
    80005168:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    8000516c:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80005170:	13896363          	bltu	s2,s8,80005296 <exec+0x2ee>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80005174:	e0043d83          	ld	s11,-512(s0)
    80005178:	000dba03          	ld	s4,0(s11)
    8000517c:	8552                	mv	a0,s4
    8000517e:	ffffc097          	auipc	ra,0xffffc
    80005182:	ce6080e7          	jalr	-794(ra) # 80000e64 <strlen>
    80005186:	0015069b          	addiw	a3,a0,1
    8000518a:	8652                	mv	a2,s4
    8000518c:	85ca                	mv	a1,s2
    8000518e:	855e                	mv	a0,s7
    80005190:	ffffc097          	auipc	ra,0xffffc
    80005194:	4ea080e7          	jalr	1258(ra) # 8000167a <copyout>
    80005198:	10054363          	bltz	a0,8000529e <exec+0x2f6>
    ustack[argc] = sp;
    8000519c:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    800051a0:	0485                	addi	s1,s1,1
    800051a2:	008d8793          	addi	a5,s11,8
    800051a6:	e0f43023          	sd	a5,-512(s0)
    800051aa:	008db503          	ld	a0,8(s11)
    800051ae:	c911                	beqz	a0,800051c2 <exec+0x21a>
    if(argc >= MAXARG)
    800051b0:	09a1                	addi	s3,s3,8
    800051b2:	fb3c96e3          	bne	s9,s3,8000515e <exec+0x1b6>
  sz = sz1;
    800051b6:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800051ba:	4481                	li	s1,0
    800051bc:	a84d                	j	8000526e <exec+0x2c6>
  sp = sz;
    800051be:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    800051c0:	4481                	li	s1,0
  ustack[argc] = 0;
    800051c2:	00349793          	slli	a5,s1,0x3
    800051c6:	f9040713          	addi	a4,s0,-112
    800051ca:	97ba                	add	a5,a5,a4
    800051cc:	f007b023          	sd	zero,-256(a5) # f00 <_entry-0x7ffff100>
  sp -= (argc+1) * sizeof(uint64);
    800051d0:	00148693          	addi	a3,s1,1
    800051d4:	068e                	slli	a3,a3,0x3
    800051d6:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    800051da:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    800051de:	01897663          	bgeu	s2,s8,800051ea <exec+0x242>
  sz = sz1;
    800051e2:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800051e6:	4481                	li	s1,0
    800051e8:	a059                	j	8000526e <exec+0x2c6>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    800051ea:	e9040613          	addi	a2,s0,-368
    800051ee:	85ca                	mv	a1,s2
    800051f0:	855e                	mv	a0,s7
    800051f2:	ffffc097          	auipc	ra,0xffffc
    800051f6:	488080e7          	jalr	1160(ra) # 8000167a <copyout>
    800051fa:	0a054663          	bltz	a0,800052a6 <exec+0x2fe>
  p->trapframe->a1 = sp;
    800051fe:	078ab783          	ld	a5,120(s5)
    80005202:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80005206:	df843783          	ld	a5,-520(s0)
    8000520a:	0007c703          	lbu	a4,0(a5)
    8000520e:	cf11                	beqz	a4,8000522a <exec+0x282>
    80005210:	0785                	addi	a5,a5,1
    if(*s == '/')
    80005212:	02f00693          	li	a3,47
    80005216:	a039                	j	80005224 <exec+0x27c>
      last = s+1;
    80005218:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    8000521c:	0785                	addi	a5,a5,1
    8000521e:	fff7c703          	lbu	a4,-1(a5)
    80005222:	c701                	beqz	a4,8000522a <exec+0x282>
    if(*s == '/')
    80005224:	fed71ce3          	bne	a4,a3,8000521c <exec+0x274>
    80005228:	bfc5                	j	80005218 <exec+0x270>
  safestrcpy(p->name, last, sizeof(p->name));
    8000522a:	4641                	li	a2,16
    8000522c:	df843583          	ld	a1,-520(s0)
    80005230:	178a8513          	addi	a0,s5,376
    80005234:	ffffc097          	auipc	ra,0xffffc
    80005238:	bfe080e7          	jalr	-1026(ra) # 80000e32 <safestrcpy>
  oldpagetable = p->pagetable;
    8000523c:	070ab503          	ld	a0,112(s5)
  p->pagetable = pagetable;
    80005240:	077ab823          	sd	s7,112(s5)
  p->sz = sz;
    80005244:	076ab423          	sd	s6,104(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80005248:	078ab783          	ld	a5,120(s5)
    8000524c:	e6843703          	ld	a4,-408(s0)
    80005250:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80005252:	078ab783          	ld	a5,120(s5)
    80005256:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    8000525a:	85ea                	mv	a1,s10
    8000525c:	ffffd097          	auipc	ra,0xffffd
    80005260:	8cc080e7          	jalr	-1844(ra) # 80001b28 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80005264:	0004851b          	sext.w	a0,s1
    80005268:	bbe1                	j	80005040 <exec+0x98>
    8000526a:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    8000526e:	e0843583          	ld	a1,-504(s0)
    80005272:	855e                	mv	a0,s7
    80005274:	ffffd097          	auipc	ra,0xffffd
    80005278:	8b4080e7          	jalr	-1868(ra) # 80001b28 <proc_freepagetable>
  if(ip){
    8000527c:	da0498e3          	bnez	s1,8000502c <exec+0x84>
  return -1;
    80005280:	557d                	li	a0,-1
    80005282:	bb7d                	j	80005040 <exec+0x98>
    80005284:	e1243423          	sd	s2,-504(s0)
    80005288:	b7dd                	j	8000526e <exec+0x2c6>
    8000528a:	e1243423          	sd	s2,-504(s0)
    8000528e:	b7c5                	j	8000526e <exec+0x2c6>
    80005290:	e1243423          	sd	s2,-504(s0)
    80005294:	bfe9                	j	8000526e <exec+0x2c6>
  sz = sz1;
    80005296:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    8000529a:	4481                	li	s1,0
    8000529c:	bfc9                	j	8000526e <exec+0x2c6>
  sz = sz1;
    8000529e:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800052a2:	4481                	li	s1,0
    800052a4:	b7e9                	j	8000526e <exec+0x2c6>
  sz = sz1;
    800052a6:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800052aa:	4481                	li	s1,0
    800052ac:	b7c9                	j	8000526e <exec+0x2c6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    800052ae:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800052b2:	2b05                	addiw	s6,s6,1
    800052b4:	0389899b          	addiw	s3,s3,56
    800052b8:	e8845783          	lhu	a5,-376(s0)
    800052bc:	e2fb5be3          	bge	s6,a5,800050f2 <exec+0x14a>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    800052c0:	2981                	sext.w	s3,s3
    800052c2:	03800713          	li	a4,56
    800052c6:	86ce                	mv	a3,s3
    800052c8:	e1840613          	addi	a2,s0,-488
    800052cc:	4581                	li	a1,0
    800052ce:	8526                	mv	a0,s1
    800052d0:	fffff097          	auipc	ra,0xfffff
    800052d4:	a8e080e7          	jalr	-1394(ra) # 80003d5e <readi>
    800052d8:	03800793          	li	a5,56
    800052dc:	f8f517e3          	bne	a0,a5,8000526a <exec+0x2c2>
    if(ph.type != ELF_PROG_LOAD)
    800052e0:	e1842783          	lw	a5,-488(s0)
    800052e4:	4705                	li	a4,1
    800052e6:	fce796e3          	bne	a5,a4,800052b2 <exec+0x30a>
    if(ph.memsz < ph.filesz)
    800052ea:	e4043603          	ld	a2,-448(s0)
    800052ee:	e3843783          	ld	a5,-456(s0)
    800052f2:	f8f669e3          	bltu	a2,a5,80005284 <exec+0x2dc>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    800052f6:	e2843783          	ld	a5,-472(s0)
    800052fa:	963e                	add	a2,a2,a5
    800052fc:	f8f667e3          	bltu	a2,a5,8000528a <exec+0x2e2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80005300:	85ca                	mv	a1,s2
    80005302:	855e                	mv	a0,s7
    80005304:	ffffc097          	auipc	ra,0xffffc
    80005308:	126080e7          	jalr	294(ra) # 8000142a <uvmalloc>
    8000530c:	e0a43423          	sd	a0,-504(s0)
    80005310:	d141                	beqz	a0,80005290 <exec+0x2e8>
    if((ph.vaddr % PGSIZE) != 0)
    80005312:	e2843d03          	ld	s10,-472(s0)
    80005316:	df043783          	ld	a5,-528(s0)
    8000531a:	00fd77b3          	and	a5,s10,a5
    8000531e:	fba1                	bnez	a5,8000526e <exec+0x2c6>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80005320:	e2042d83          	lw	s11,-480(s0)
    80005324:	e3842c03          	lw	s8,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80005328:	f80c03e3          	beqz	s8,800052ae <exec+0x306>
    8000532c:	8a62                	mv	s4,s8
    8000532e:	4901                	li	s2,0
    80005330:	b345                	j	800050d0 <exec+0x128>

0000000080005332 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80005332:	7179                	addi	sp,sp,-48
    80005334:	f406                	sd	ra,40(sp)
    80005336:	f022                	sd	s0,32(sp)
    80005338:	ec26                	sd	s1,24(sp)
    8000533a:	e84a                	sd	s2,16(sp)
    8000533c:	1800                	addi	s0,sp,48
    8000533e:	892e                	mv	s2,a1
    80005340:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    80005342:	fdc40593          	addi	a1,s0,-36
    80005346:	ffffe097          	auipc	ra,0xffffe
    8000534a:	ba4080e7          	jalr	-1116(ra) # 80002eea <argint>
    8000534e:	04054063          	bltz	a0,8000538e <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80005352:	fdc42703          	lw	a4,-36(s0)
    80005356:	47bd                	li	a5,15
    80005358:	02e7ed63          	bltu	a5,a4,80005392 <argfd+0x60>
    8000535c:	ffffc097          	auipc	ra,0xffffc
    80005360:	66c080e7          	jalr	1644(ra) # 800019c8 <myproc>
    80005364:	fdc42703          	lw	a4,-36(s0)
    80005368:	01e70793          	addi	a5,a4,30
    8000536c:	078e                	slli	a5,a5,0x3
    8000536e:	953e                	add	a0,a0,a5
    80005370:	611c                	ld	a5,0(a0)
    80005372:	c395                	beqz	a5,80005396 <argfd+0x64>
    return -1;
  if(pfd)
    80005374:	00090463          	beqz	s2,8000537c <argfd+0x4a>
    *pfd = fd;
    80005378:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    8000537c:	4501                	li	a0,0
  if(pf)
    8000537e:	c091                	beqz	s1,80005382 <argfd+0x50>
    *pf = f;
    80005380:	e09c                	sd	a5,0(s1)
}
    80005382:	70a2                	ld	ra,40(sp)
    80005384:	7402                	ld	s0,32(sp)
    80005386:	64e2                	ld	s1,24(sp)
    80005388:	6942                	ld	s2,16(sp)
    8000538a:	6145                	addi	sp,sp,48
    8000538c:	8082                	ret
    return -1;
    8000538e:	557d                	li	a0,-1
    80005390:	bfcd                	j	80005382 <argfd+0x50>
    return -1;
    80005392:	557d                	li	a0,-1
    80005394:	b7fd                	j	80005382 <argfd+0x50>
    80005396:	557d                	li	a0,-1
    80005398:	b7ed                	j	80005382 <argfd+0x50>

000000008000539a <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    8000539a:	1101                	addi	sp,sp,-32
    8000539c:	ec06                	sd	ra,24(sp)
    8000539e:	e822                	sd	s0,16(sp)
    800053a0:	e426                	sd	s1,8(sp)
    800053a2:	1000                	addi	s0,sp,32
    800053a4:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    800053a6:	ffffc097          	auipc	ra,0xffffc
    800053aa:	622080e7          	jalr	1570(ra) # 800019c8 <myproc>
    800053ae:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    800053b0:	0f050793          	addi	a5,a0,240 # fffffffffffff0f0 <end+0xffffffff7ffd90f0>
    800053b4:	4501                	li	a0,0
    800053b6:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    800053b8:	6398                	ld	a4,0(a5)
    800053ba:	cb19                	beqz	a4,800053d0 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    800053bc:	2505                	addiw	a0,a0,1
    800053be:	07a1                	addi	a5,a5,8
    800053c0:	fed51ce3          	bne	a0,a3,800053b8 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    800053c4:	557d                	li	a0,-1
}
    800053c6:	60e2                	ld	ra,24(sp)
    800053c8:	6442                	ld	s0,16(sp)
    800053ca:	64a2                	ld	s1,8(sp)
    800053cc:	6105                	addi	sp,sp,32
    800053ce:	8082                	ret
      p->ofile[fd] = f;
    800053d0:	01e50793          	addi	a5,a0,30
    800053d4:	078e                	slli	a5,a5,0x3
    800053d6:	963e                	add	a2,a2,a5
    800053d8:	e204                	sd	s1,0(a2)
      return fd;
    800053da:	b7f5                	j	800053c6 <fdalloc+0x2c>

00000000800053dc <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    800053dc:	715d                	addi	sp,sp,-80
    800053de:	e486                	sd	ra,72(sp)
    800053e0:	e0a2                	sd	s0,64(sp)
    800053e2:	fc26                	sd	s1,56(sp)
    800053e4:	f84a                	sd	s2,48(sp)
    800053e6:	f44e                	sd	s3,40(sp)
    800053e8:	f052                	sd	s4,32(sp)
    800053ea:	ec56                	sd	s5,24(sp)
    800053ec:	0880                	addi	s0,sp,80
    800053ee:	89ae                	mv	s3,a1
    800053f0:	8ab2                	mv	s5,a2
    800053f2:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    800053f4:	fb040593          	addi	a1,s0,-80
    800053f8:	fffff097          	auipc	ra,0xfffff
    800053fc:	e86080e7          	jalr	-378(ra) # 8000427e <nameiparent>
    80005400:	892a                	mv	s2,a0
    80005402:	12050f63          	beqz	a0,80005540 <create+0x164>
    return 0;

  ilock(dp);
    80005406:	ffffe097          	auipc	ra,0xffffe
    8000540a:	6a4080e7          	jalr	1700(ra) # 80003aaa <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    8000540e:	4601                	li	a2,0
    80005410:	fb040593          	addi	a1,s0,-80
    80005414:	854a                	mv	a0,s2
    80005416:	fffff097          	auipc	ra,0xfffff
    8000541a:	b78080e7          	jalr	-1160(ra) # 80003f8e <dirlookup>
    8000541e:	84aa                	mv	s1,a0
    80005420:	c921                	beqz	a0,80005470 <create+0x94>
    iunlockput(dp);
    80005422:	854a                	mv	a0,s2
    80005424:	fffff097          	auipc	ra,0xfffff
    80005428:	8e8080e7          	jalr	-1816(ra) # 80003d0c <iunlockput>
    ilock(ip);
    8000542c:	8526                	mv	a0,s1
    8000542e:	ffffe097          	auipc	ra,0xffffe
    80005432:	67c080e7          	jalr	1660(ra) # 80003aaa <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80005436:	2981                	sext.w	s3,s3
    80005438:	4789                	li	a5,2
    8000543a:	02f99463          	bne	s3,a5,80005462 <create+0x86>
    8000543e:	0444d783          	lhu	a5,68(s1)
    80005442:	37f9                	addiw	a5,a5,-2
    80005444:	17c2                	slli	a5,a5,0x30
    80005446:	93c1                	srli	a5,a5,0x30
    80005448:	4705                	li	a4,1
    8000544a:	00f76c63          	bltu	a4,a5,80005462 <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    8000544e:	8526                	mv	a0,s1
    80005450:	60a6                	ld	ra,72(sp)
    80005452:	6406                	ld	s0,64(sp)
    80005454:	74e2                	ld	s1,56(sp)
    80005456:	7942                	ld	s2,48(sp)
    80005458:	79a2                	ld	s3,40(sp)
    8000545a:	7a02                	ld	s4,32(sp)
    8000545c:	6ae2                	ld	s5,24(sp)
    8000545e:	6161                	addi	sp,sp,80
    80005460:	8082                	ret
    iunlockput(ip);
    80005462:	8526                	mv	a0,s1
    80005464:	fffff097          	auipc	ra,0xfffff
    80005468:	8a8080e7          	jalr	-1880(ra) # 80003d0c <iunlockput>
    return 0;
    8000546c:	4481                	li	s1,0
    8000546e:	b7c5                	j	8000544e <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    80005470:	85ce                	mv	a1,s3
    80005472:	00092503          	lw	a0,0(s2)
    80005476:	ffffe097          	auipc	ra,0xffffe
    8000547a:	49c080e7          	jalr	1180(ra) # 80003912 <ialloc>
    8000547e:	84aa                	mv	s1,a0
    80005480:	c529                	beqz	a0,800054ca <create+0xee>
  ilock(ip);
    80005482:	ffffe097          	auipc	ra,0xffffe
    80005486:	628080e7          	jalr	1576(ra) # 80003aaa <ilock>
  ip->major = major;
    8000548a:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    8000548e:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    80005492:	4785                	li	a5,1
    80005494:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005498:	8526                	mv	a0,s1
    8000549a:	ffffe097          	auipc	ra,0xffffe
    8000549e:	546080e7          	jalr	1350(ra) # 800039e0 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    800054a2:	2981                	sext.w	s3,s3
    800054a4:	4785                	li	a5,1
    800054a6:	02f98a63          	beq	s3,a5,800054da <create+0xfe>
  if(dirlink(dp, name, ip->inum) < 0)
    800054aa:	40d0                	lw	a2,4(s1)
    800054ac:	fb040593          	addi	a1,s0,-80
    800054b0:	854a                	mv	a0,s2
    800054b2:	fffff097          	auipc	ra,0xfffff
    800054b6:	cec080e7          	jalr	-788(ra) # 8000419e <dirlink>
    800054ba:	06054b63          	bltz	a0,80005530 <create+0x154>
  iunlockput(dp);
    800054be:	854a                	mv	a0,s2
    800054c0:	fffff097          	auipc	ra,0xfffff
    800054c4:	84c080e7          	jalr	-1972(ra) # 80003d0c <iunlockput>
  return ip;
    800054c8:	b759                	j	8000544e <create+0x72>
    panic("create: ialloc");
    800054ca:	00003517          	auipc	a0,0x3
    800054ce:	23e50513          	addi	a0,a0,574 # 80008708 <syscalls+0x2b0>
    800054d2:	ffffb097          	auipc	ra,0xffffb
    800054d6:	06c080e7          	jalr	108(ra) # 8000053e <panic>
    dp->nlink++;  // for ".."
    800054da:	04a95783          	lhu	a5,74(s2)
    800054de:	2785                	addiw	a5,a5,1
    800054e0:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    800054e4:	854a                	mv	a0,s2
    800054e6:	ffffe097          	auipc	ra,0xffffe
    800054ea:	4fa080e7          	jalr	1274(ra) # 800039e0 <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    800054ee:	40d0                	lw	a2,4(s1)
    800054f0:	00003597          	auipc	a1,0x3
    800054f4:	22858593          	addi	a1,a1,552 # 80008718 <syscalls+0x2c0>
    800054f8:	8526                	mv	a0,s1
    800054fa:	fffff097          	auipc	ra,0xfffff
    800054fe:	ca4080e7          	jalr	-860(ra) # 8000419e <dirlink>
    80005502:	00054f63          	bltz	a0,80005520 <create+0x144>
    80005506:	00492603          	lw	a2,4(s2)
    8000550a:	00003597          	auipc	a1,0x3
    8000550e:	21658593          	addi	a1,a1,534 # 80008720 <syscalls+0x2c8>
    80005512:	8526                	mv	a0,s1
    80005514:	fffff097          	auipc	ra,0xfffff
    80005518:	c8a080e7          	jalr	-886(ra) # 8000419e <dirlink>
    8000551c:	f80557e3          	bgez	a0,800054aa <create+0xce>
      panic("create dots");
    80005520:	00003517          	auipc	a0,0x3
    80005524:	20850513          	addi	a0,a0,520 # 80008728 <syscalls+0x2d0>
    80005528:	ffffb097          	auipc	ra,0xffffb
    8000552c:	016080e7          	jalr	22(ra) # 8000053e <panic>
    panic("create: dirlink");
    80005530:	00003517          	auipc	a0,0x3
    80005534:	20850513          	addi	a0,a0,520 # 80008738 <syscalls+0x2e0>
    80005538:	ffffb097          	auipc	ra,0xffffb
    8000553c:	006080e7          	jalr	6(ra) # 8000053e <panic>
    return 0;
    80005540:	84aa                	mv	s1,a0
    80005542:	b731                	j	8000544e <create+0x72>

0000000080005544 <sys_dup>:
{
    80005544:	7179                	addi	sp,sp,-48
    80005546:	f406                	sd	ra,40(sp)
    80005548:	f022                	sd	s0,32(sp)
    8000554a:	ec26                	sd	s1,24(sp)
    8000554c:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    8000554e:	fd840613          	addi	a2,s0,-40
    80005552:	4581                	li	a1,0
    80005554:	4501                	li	a0,0
    80005556:	00000097          	auipc	ra,0x0
    8000555a:	ddc080e7          	jalr	-548(ra) # 80005332 <argfd>
    return -1;
    8000555e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80005560:	02054363          	bltz	a0,80005586 <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    80005564:	fd843503          	ld	a0,-40(s0)
    80005568:	00000097          	auipc	ra,0x0
    8000556c:	e32080e7          	jalr	-462(ra) # 8000539a <fdalloc>
    80005570:	84aa                	mv	s1,a0
    return -1;
    80005572:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80005574:	00054963          	bltz	a0,80005586 <sys_dup+0x42>
  filedup(f);
    80005578:	fd843503          	ld	a0,-40(s0)
    8000557c:	fffff097          	auipc	ra,0xfffff
    80005580:	37a080e7          	jalr	890(ra) # 800048f6 <filedup>
  return fd;
    80005584:	87a6                	mv	a5,s1
}
    80005586:	853e                	mv	a0,a5
    80005588:	70a2                	ld	ra,40(sp)
    8000558a:	7402                	ld	s0,32(sp)
    8000558c:	64e2                	ld	s1,24(sp)
    8000558e:	6145                	addi	sp,sp,48
    80005590:	8082                	ret

0000000080005592 <sys_read>:
{
    80005592:	7179                	addi	sp,sp,-48
    80005594:	f406                	sd	ra,40(sp)
    80005596:	f022                	sd	s0,32(sp)
    80005598:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000559a:	fe840613          	addi	a2,s0,-24
    8000559e:	4581                	li	a1,0
    800055a0:	4501                	li	a0,0
    800055a2:	00000097          	auipc	ra,0x0
    800055a6:	d90080e7          	jalr	-624(ra) # 80005332 <argfd>
    return -1;
    800055aa:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800055ac:	04054163          	bltz	a0,800055ee <sys_read+0x5c>
    800055b0:	fe440593          	addi	a1,s0,-28
    800055b4:	4509                	li	a0,2
    800055b6:	ffffe097          	auipc	ra,0xffffe
    800055ba:	934080e7          	jalr	-1740(ra) # 80002eea <argint>
    return -1;
    800055be:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800055c0:	02054763          	bltz	a0,800055ee <sys_read+0x5c>
    800055c4:	fd840593          	addi	a1,s0,-40
    800055c8:	4505                	li	a0,1
    800055ca:	ffffe097          	auipc	ra,0xffffe
    800055ce:	942080e7          	jalr	-1726(ra) # 80002f0c <argaddr>
    return -1;
    800055d2:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800055d4:	00054d63          	bltz	a0,800055ee <sys_read+0x5c>
  return fileread(f, p, n);
    800055d8:	fe442603          	lw	a2,-28(s0)
    800055dc:	fd843583          	ld	a1,-40(s0)
    800055e0:	fe843503          	ld	a0,-24(s0)
    800055e4:	fffff097          	auipc	ra,0xfffff
    800055e8:	49e080e7          	jalr	1182(ra) # 80004a82 <fileread>
    800055ec:	87aa                	mv	a5,a0
}
    800055ee:	853e                	mv	a0,a5
    800055f0:	70a2                	ld	ra,40(sp)
    800055f2:	7402                	ld	s0,32(sp)
    800055f4:	6145                	addi	sp,sp,48
    800055f6:	8082                	ret

00000000800055f8 <sys_write>:
{
    800055f8:	7179                	addi	sp,sp,-48
    800055fa:	f406                	sd	ra,40(sp)
    800055fc:	f022                	sd	s0,32(sp)
    800055fe:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005600:	fe840613          	addi	a2,s0,-24
    80005604:	4581                	li	a1,0
    80005606:	4501                	li	a0,0
    80005608:	00000097          	auipc	ra,0x0
    8000560c:	d2a080e7          	jalr	-726(ra) # 80005332 <argfd>
    return -1;
    80005610:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005612:	04054163          	bltz	a0,80005654 <sys_write+0x5c>
    80005616:	fe440593          	addi	a1,s0,-28
    8000561a:	4509                	li	a0,2
    8000561c:	ffffe097          	auipc	ra,0xffffe
    80005620:	8ce080e7          	jalr	-1842(ra) # 80002eea <argint>
    return -1;
    80005624:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005626:	02054763          	bltz	a0,80005654 <sys_write+0x5c>
    8000562a:	fd840593          	addi	a1,s0,-40
    8000562e:	4505                	li	a0,1
    80005630:	ffffe097          	auipc	ra,0xffffe
    80005634:	8dc080e7          	jalr	-1828(ra) # 80002f0c <argaddr>
    return -1;
    80005638:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000563a:	00054d63          	bltz	a0,80005654 <sys_write+0x5c>
  return filewrite(f, p, n);
    8000563e:	fe442603          	lw	a2,-28(s0)
    80005642:	fd843583          	ld	a1,-40(s0)
    80005646:	fe843503          	ld	a0,-24(s0)
    8000564a:	fffff097          	auipc	ra,0xfffff
    8000564e:	4fa080e7          	jalr	1274(ra) # 80004b44 <filewrite>
    80005652:	87aa                	mv	a5,a0
}
    80005654:	853e                	mv	a0,a5
    80005656:	70a2                	ld	ra,40(sp)
    80005658:	7402                	ld	s0,32(sp)
    8000565a:	6145                	addi	sp,sp,48
    8000565c:	8082                	ret

000000008000565e <sys_close>:
{
    8000565e:	1101                	addi	sp,sp,-32
    80005660:	ec06                	sd	ra,24(sp)
    80005662:	e822                	sd	s0,16(sp)
    80005664:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    80005666:	fe040613          	addi	a2,s0,-32
    8000566a:	fec40593          	addi	a1,s0,-20
    8000566e:	4501                	li	a0,0
    80005670:	00000097          	auipc	ra,0x0
    80005674:	cc2080e7          	jalr	-830(ra) # 80005332 <argfd>
    return -1;
    80005678:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    8000567a:	02054463          	bltz	a0,800056a2 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    8000567e:	ffffc097          	auipc	ra,0xffffc
    80005682:	34a080e7          	jalr	842(ra) # 800019c8 <myproc>
    80005686:	fec42783          	lw	a5,-20(s0)
    8000568a:	07f9                	addi	a5,a5,30
    8000568c:	078e                	slli	a5,a5,0x3
    8000568e:	97aa                	add	a5,a5,a0
    80005690:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    80005694:	fe043503          	ld	a0,-32(s0)
    80005698:	fffff097          	auipc	ra,0xfffff
    8000569c:	2b0080e7          	jalr	688(ra) # 80004948 <fileclose>
  return 0;
    800056a0:	4781                	li	a5,0
}
    800056a2:	853e                	mv	a0,a5
    800056a4:	60e2                	ld	ra,24(sp)
    800056a6:	6442                	ld	s0,16(sp)
    800056a8:	6105                	addi	sp,sp,32
    800056aa:	8082                	ret

00000000800056ac <sys_fstat>:
{
    800056ac:	1101                	addi	sp,sp,-32
    800056ae:	ec06                	sd	ra,24(sp)
    800056b0:	e822                	sd	s0,16(sp)
    800056b2:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800056b4:	fe840613          	addi	a2,s0,-24
    800056b8:	4581                	li	a1,0
    800056ba:	4501                	li	a0,0
    800056bc:	00000097          	auipc	ra,0x0
    800056c0:	c76080e7          	jalr	-906(ra) # 80005332 <argfd>
    return -1;
    800056c4:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800056c6:	02054563          	bltz	a0,800056f0 <sys_fstat+0x44>
    800056ca:	fe040593          	addi	a1,s0,-32
    800056ce:	4505                	li	a0,1
    800056d0:	ffffe097          	auipc	ra,0xffffe
    800056d4:	83c080e7          	jalr	-1988(ra) # 80002f0c <argaddr>
    return -1;
    800056d8:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800056da:	00054b63          	bltz	a0,800056f0 <sys_fstat+0x44>
  return filestat(f, st);
    800056de:	fe043583          	ld	a1,-32(s0)
    800056e2:	fe843503          	ld	a0,-24(s0)
    800056e6:	fffff097          	auipc	ra,0xfffff
    800056ea:	32a080e7          	jalr	810(ra) # 80004a10 <filestat>
    800056ee:	87aa                	mv	a5,a0
}
    800056f0:	853e                	mv	a0,a5
    800056f2:	60e2                	ld	ra,24(sp)
    800056f4:	6442                	ld	s0,16(sp)
    800056f6:	6105                	addi	sp,sp,32
    800056f8:	8082                	ret

00000000800056fa <sys_link>:
{
    800056fa:	7169                	addi	sp,sp,-304
    800056fc:	f606                	sd	ra,296(sp)
    800056fe:	f222                	sd	s0,288(sp)
    80005700:	ee26                	sd	s1,280(sp)
    80005702:	ea4a                	sd	s2,272(sp)
    80005704:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005706:	08000613          	li	a2,128
    8000570a:	ed040593          	addi	a1,s0,-304
    8000570e:	4501                	li	a0,0
    80005710:	ffffe097          	auipc	ra,0xffffe
    80005714:	81e080e7          	jalr	-2018(ra) # 80002f2e <argstr>
    return -1;
    80005718:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000571a:	10054e63          	bltz	a0,80005836 <sys_link+0x13c>
    8000571e:	08000613          	li	a2,128
    80005722:	f5040593          	addi	a1,s0,-176
    80005726:	4505                	li	a0,1
    80005728:	ffffe097          	auipc	ra,0xffffe
    8000572c:	806080e7          	jalr	-2042(ra) # 80002f2e <argstr>
    return -1;
    80005730:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005732:	10054263          	bltz	a0,80005836 <sys_link+0x13c>
  begin_op();
    80005736:	fffff097          	auipc	ra,0xfffff
    8000573a:	d46080e7          	jalr	-698(ra) # 8000447c <begin_op>
  if((ip = namei(old)) == 0){
    8000573e:	ed040513          	addi	a0,s0,-304
    80005742:	fffff097          	auipc	ra,0xfffff
    80005746:	b1e080e7          	jalr	-1250(ra) # 80004260 <namei>
    8000574a:	84aa                	mv	s1,a0
    8000574c:	c551                	beqz	a0,800057d8 <sys_link+0xde>
  ilock(ip);
    8000574e:	ffffe097          	auipc	ra,0xffffe
    80005752:	35c080e7          	jalr	860(ra) # 80003aaa <ilock>
  if(ip->type == T_DIR){
    80005756:	04449703          	lh	a4,68(s1)
    8000575a:	4785                	li	a5,1
    8000575c:	08f70463          	beq	a4,a5,800057e4 <sys_link+0xea>
  ip->nlink++;
    80005760:	04a4d783          	lhu	a5,74(s1)
    80005764:	2785                	addiw	a5,a5,1
    80005766:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000576a:	8526                	mv	a0,s1
    8000576c:	ffffe097          	auipc	ra,0xffffe
    80005770:	274080e7          	jalr	628(ra) # 800039e0 <iupdate>
  iunlock(ip);
    80005774:	8526                	mv	a0,s1
    80005776:	ffffe097          	auipc	ra,0xffffe
    8000577a:	3f6080e7          	jalr	1014(ra) # 80003b6c <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    8000577e:	fd040593          	addi	a1,s0,-48
    80005782:	f5040513          	addi	a0,s0,-176
    80005786:	fffff097          	auipc	ra,0xfffff
    8000578a:	af8080e7          	jalr	-1288(ra) # 8000427e <nameiparent>
    8000578e:	892a                	mv	s2,a0
    80005790:	c935                	beqz	a0,80005804 <sys_link+0x10a>
  ilock(dp);
    80005792:	ffffe097          	auipc	ra,0xffffe
    80005796:	318080e7          	jalr	792(ra) # 80003aaa <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    8000579a:	00092703          	lw	a4,0(s2)
    8000579e:	409c                	lw	a5,0(s1)
    800057a0:	04f71d63          	bne	a4,a5,800057fa <sys_link+0x100>
    800057a4:	40d0                	lw	a2,4(s1)
    800057a6:	fd040593          	addi	a1,s0,-48
    800057aa:	854a                	mv	a0,s2
    800057ac:	fffff097          	auipc	ra,0xfffff
    800057b0:	9f2080e7          	jalr	-1550(ra) # 8000419e <dirlink>
    800057b4:	04054363          	bltz	a0,800057fa <sys_link+0x100>
  iunlockput(dp);
    800057b8:	854a                	mv	a0,s2
    800057ba:	ffffe097          	auipc	ra,0xffffe
    800057be:	552080e7          	jalr	1362(ra) # 80003d0c <iunlockput>
  iput(ip);
    800057c2:	8526                	mv	a0,s1
    800057c4:	ffffe097          	auipc	ra,0xffffe
    800057c8:	4a0080e7          	jalr	1184(ra) # 80003c64 <iput>
  end_op();
    800057cc:	fffff097          	auipc	ra,0xfffff
    800057d0:	d30080e7          	jalr	-720(ra) # 800044fc <end_op>
  return 0;
    800057d4:	4781                	li	a5,0
    800057d6:	a085                	j	80005836 <sys_link+0x13c>
    end_op();
    800057d8:	fffff097          	auipc	ra,0xfffff
    800057dc:	d24080e7          	jalr	-732(ra) # 800044fc <end_op>
    return -1;
    800057e0:	57fd                	li	a5,-1
    800057e2:	a891                	j	80005836 <sys_link+0x13c>
    iunlockput(ip);
    800057e4:	8526                	mv	a0,s1
    800057e6:	ffffe097          	auipc	ra,0xffffe
    800057ea:	526080e7          	jalr	1318(ra) # 80003d0c <iunlockput>
    end_op();
    800057ee:	fffff097          	auipc	ra,0xfffff
    800057f2:	d0e080e7          	jalr	-754(ra) # 800044fc <end_op>
    return -1;
    800057f6:	57fd                	li	a5,-1
    800057f8:	a83d                	j	80005836 <sys_link+0x13c>
    iunlockput(dp);
    800057fa:	854a                	mv	a0,s2
    800057fc:	ffffe097          	auipc	ra,0xffffe
    80005800:	510080e7          	jalr	1296(ra) # 80003d0c <iunlockput>
  ilock(ip);
    80005804:	8526                	mv	a0,s1
    80005806:	ffffe097          	auipc	ra,0xffffe
    8000580a:	2a4080e7          	jalr	676(ra) # 80003aaa <ilock>
  ip->nlink--;
    8000580e:	04a4d783          	lhu	a5,74(s1)
    80005812:	37fd                	addiw	a5,a5,-1
    80005814:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005818:	8526                	mv	a0,s1
    8000581a:	ffffe097          	auipc	ra,0xffffe
    8000581e:	1c6080e7          	jalr	454(ra) # 800039e0 <iupdate>
  iunlockput(ip);
    80005822:	8526                	mv	a0,s1
    80005824:	ffffe097          	auipc	ra,0xffffe
    80005828:	4e8080e7          	jalr	1256(ra) # 80003d0c <iunlockput>
  end_op();
    8000582c:	fffff097          	auipc	ra,0xfffff
    80005830:	cd0080e7          	jalr	-816(ra) # 800044fc <end_op>
  return -1;
    80005834:	57fd                	li	a5,-1
}
    80005836:	853e                	mv	a0,a5
    80005838:	70b2                	ld	ra,296(sp)
    8000583a:	7412                	ld	s0,288(sp)
    8000583c:	64f2                	ld	s1,280(sp)
    8000583e:	6952                	ld	s2,272(sp)
    80005840:	6155                	addi	sp,sp,304
    80005842:	8082                	ret

0000000080005844 <sys_unlink>:
{
    80005844:	7151                	addi	sp,sp,-240
    80005846:	f586                	sd	ra,232(sp)
    80005848:	f1a2                	sd	s0,224(sp)
    8000584a:	eda6                	sd	s1,216(sp)
    8000584c:	e9ca                	sd	s2,208(sp)
    8000584e:	e5ce                	sd	s3,200(sp)
    80005850:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005852:	08000613          	li	a2,128
    80005856:	f3040593          	addi	a1,s0,-208
    8000585a:	4501                	li	a0,0
    8000585c:	ffffd097          	auipc	ra,0xffffd
    80005860:	6d2080e7          	jalr	1746(ra) # 80002f2e <argstr>
    80005864:	18054163          	bltz	a0,800059e6 <sys_unlink+0x1a2>
  begin_op();
    80005868:	fffff097          	auipc	ra,0xfffff
    8000586c:	c14080e7          	jalr	-1004(ra) # 8000447c <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005870:	fb040593          	addi	a1,s0,-80
    80005874:	f3040513          	addi	a0,s0,-208
    80005878:	fffff097          	auipc	ra,0xfffff
    8000587c:	a06080e7          	jalr	-1530(ra) # 8000427e <nameiparent>
    80005880:	84aa                	mv	s1,a0
    80005882:	c979                	beqz	a0,80005958 <sys_unlink+0x114>
  ilock(dp);
    80005884:	ffffe097          	auipc	ra,0xffffe
    80005888:	226080e7          	jalr	550(ra) # 80003aaa <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    8000588c:	00003597          	auipc	a1,0x3
    80005890:	e8c58593          	addi	a1,a1,-372 # 80008718 <syscalls+0x2c0>
    80005894:	fb040513          	addi	a0,s0,-80
    80005898:	ffffe097          	auipc	ra,0xffffe
    8000589c:	6dc080e7          	jalr	1756(ra) # 80003f74 <namecmp>
    800058a0:	14050a63          	beqz	a0,800059f4 <sys_unlink+0x1b0>
    800058a4:	00003597          	auipc	a1,0x3
    800058a8:	e7c58593          	addi	a1,a1,-388 # 80008720 <syscalls+0x2c8>
    800058ac:	fb040513          	addi	a0,s0,-80
    800058b0:	ffffe097          	auipc	ra,0xffffe
    800058b4:	6c4080e7          	jalr	1732(ra) # 80003f74 <namecmp>
    800058b8:	12050e63          	beqz	a0,800059f4 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    800058bc:	f2c40613          	addi	a2,s0,-212
    800058c0:	fb040593          	addi	a1,s0,-80
    800058c4:	8526                	mv	a0,s1
    800058c6:	ffffe097          	auipc	ra,0xffffe
    800058ca:	6c8080e7          	jalr	1736(ra) # 80003f8e <dirlookup>
    800058ce:	892a                	mv	s2,a0
    800058d0:	12050263          	beqz	a0,800059f4 <sys_unlink+0x1b0>
  ilock(ip);
    800058d4:	ffffe097          	auipc	ra,0xffffe
    800058d8:	1d6080e7          	jalr	470(ra) # 80003aaa <ilock>
  if(ip->nlink < 1)
    800058dc:	04a91783          	lh	a5,74(s2)
    800058e0:	08f05263          	blez	a5,80005964 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    800058e4:	04491703          	lh	a4,68(s2)
    800058e8:	4785                	li	a5,1
    800058ea:	08f70563          	beq	a4,a5,80005974 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    800058ee:	4641                	li	a2,16
    800058f0:	4581                	li	a1,0
    800058f2:	fc040513          	addi	a0,s0,-64
    800058f6:	ffffb097          	auipc	ra,0xffffb
    800058fa:	3ea080e7          	jalr	1002(ra) # 80000ce0 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800058fe:	4741                	li	a4,16
    80005900:	f2c42683          	lw	a3,-212(s0)
    80005904:	fc040613          	addi	a2,s0,-64
    80005908:	4581                	li	a1,0
    8000590a:	8526                	mv	a0,s1
    8000590c:	ffffe097          	auipc	ra,0xffffe
    80005910:	54a080e7          	jalr	1354(ra) # 80003e56 <writei>
    80005914:	47c1                	li	a5,16
    80005916:	0af51563          	bne	a0,a5,800059c0 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    8000591a:	04491703          	lh	a4,68(s2)
    8000591e:	4785                	li	a5,1
    80005920:	0af70863          	beq	a4,a5,800059d0 <sys_unlink+0x18c>
  iunlockput(dp);
    80005924:	8526                	mv	a0,s1
    80005926:	ffffe097          	auipc	ra,0xffffe
    8000592a:	3e6080e7          	jalr	998(ra) # 80003d0c <iunlockput>
  ip->nlink--;
    8000592e:	04a95783          	lhu	a5,74(s2)
    80005932:	37fd                	addiw	a5,a5,-1
    80005934:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005938:	854a                	mv	a0,s2
    8000593a:	ffffe097          	auipc	ra,0xffffe
    8000593e:	0a6080e7          	jalr	166(ra) # 800039e0 <iupdate>
  iunlockput(ip);
    80005942:	854a                	mv	a0,s2
    80005944:	ffffe097          	auipc	ra,0xffffe
    80005948:	3c8080e7          	jalr	968(ra) # 80003d0c <iunlockput>
  end_op();
    8000594c:	fffff097          	auipc	ra,0xfffff
    80005950:	bb0080e7          	jalr	-1104(ra) # 800044fc <end_op>
  return 0;
    80005954:	4501                	li	a0,0
    80005956:	a84d                	j	80005a08 <sys_unlink+0x1c4>
    end_op();
    80005958:	fffff097          	auipc	ra,0xfffff
    8000595c:	ba4080e7          	jalr	-1116(ra) # 800044fc <end_op>
    return -1;
    80005960:	557d                	li	a0,-1
    80005962:	a05d                	j	80005a08 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005964:	00003517          	auipc	a0,0x3
    80005968:	de450513          	addi	a0,a0,-540 # 80008748 <syscalls+0x2f0>
    8000596c:	ffffb097          	auipc	ra,0xffffb
    80005970:	bd2080e7          	jalr	-1070(ra) # 8000053e <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005974:	04c92703          	lw	a4,76(s2)
    80005978:	02000793          	li	a5,32
    8000597c:	f6e7f9e3          	bgeu	a5,a4,800058ee <sys_unlink+0xaa>
    80005980:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005984:	4741                	li	a4,16
    80005986:	86ce                	mv	a3,s3
    80005988:	f1840613          	addi	a2,s0,-232
    8000598c:	4581                	li	a1,0
    8000598e:	854a                	mv	a0,s2
    80005990:	ffffe097          	auipc	ra,0xffffe
    80005994:	3ce080e7          	jalr	974(ra) # 80003d5e <readi>
    80005998:	47c1                	li	a5,16
    8000599a:	00f51b63          	bne	a0,a5,800059b0 <sys_unlink+0x16c>
    if(de.inum != 0)
    8000599e:	f1845783          	lhu	a5,-232(s0)
    800059a2:	e7a1                	bnez	a5,800059ea <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800059a4:	29c1                	addiw	s3,s3,16
    800059a6:	04c92783          	lw	a5,76(s2)
    800059aa:	fcf9ede3          	bltu	s3,a5,80005984 <sys_unlink+0x140>
    800059ae:	b781                	j	800058ee <sys_unlink+0xaa>
      panic("isdirempty: readi");
    800059b0:	00003517          	auipc	a0,0x3
    800059b4:	db050513          	addi	a0,a0,-592 # 80008760 <syscalls+0x308>
    800059b8:	ffffb097          	auipc	ra,0xffffb
    800059bc:	b86080e7          	jalr	-1146(ra) # 8000053e <panic>
    panic("unlink: writei");
    800059c0:	00003517          	auipc	a0,0x3
    800059c4:	db850513          	addi	a0,a0,-584 # 80008778 <syscalls+0x320>
    800059c8:	ffffb097          	auipc	ra,0xffffb
    800059cc:	b76080e7          	jalr	-1162(ra) # 8000053e <panic>
    dp->nlink--;
    800059d0:	04a4d783          	lhu	a5,74(s1)
    800059d4:	37fd                	addiw	a5,a5,-1
    800059d6:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    800059da:	8526                	mv	a0,s1
    800059dc:	ffffe097          	auipc	ra,0xffffe
    800059e0:	004080e7          	jalr	4(ra) # 800039e0 <iupdate>
    800059e4:	b781                	j	80005924 <sys_unlink+0xe0>
    return -1;
    800059e6:	557d                	li	a0,-1
    800059e8:	a005                	j	80005a08 <sys_unlink+0x1c4>
    iunlockput(ip);
    800059ea:	854a                	mv	a0,s2
    800059ec:	ffffe097          	auipc	ra,0xffffe
    800059f0:	320080e7          	jalr	800(ra) # 80003d0c <iunlockput>
  iunlockput(dp);
    800059f4:	8526                	mv	a0,s1
    800059f6:	ffffe097          	auipc	ra,0xffffe
    800059fa:	316080e7          	jalr	790(ra) # 80003d0c <iunlockput>
  end_op();
    800059fe:	fffff097          	auipc	ra,0xfffff
    80005a02:	afe080e7          	jalr	-1282(ra) # 800044fc <end_op>
  return -1;
    80005a06:	557d                	li	a0,-1
}
    80005a08:	70ae                	ld	ra,232(sp)
    80005a0a:	740e                	ld	s0,224(sp)
    80005a0c:	64ee                	ld	s1,216(sp)
    80005a0e:	694e                	ld	s2,208(sp)
    80005a10:	69ae                	ld	s3,200(sp)
    80005a12:	616d                	addi	sp,sp,240
    80005a14:	8082                	ret

0000000080005a16 <sys_open>:

uint64
sys_open(void)
{
    80005a16:	7131                	addi	sp,sp,-192
    80005a18:	fd06                	sd	ra,184(sp)
    80005a1a:	f922                	sd	s0,176(sp)
    80005a1c:	f526                	sd	s1,168(sp)
    80005a1e:	f14a                	sd	s2,160(sp)
    80005a20:	ed4e                	sd	s3,152(sp)
    80005a22:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005a24:	08000613          	li	a2,128
    80005a28:	f5040593          	addi	a1,s0,-176
    80005a2c:	4501                	li	a0,0
    80005a2e:	ffffd097          	auipc	ra,0xffffd
    80005a32:	500080e7          	jalr	1280(ra) # 80002f2e <argstr>
    return -1;
    80005a36:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005a38:	0c054163          	bltz	a0,80005afa <sys_open+0xe4>
    80005a3c:	f4c40593          	addi	a1,s0,-180
    80005a40:	4505                	li	a0,1
    80005a42:	ffffd097          	auipc	ra,0xffffd
    80005a46:	4a8080e7          	jalr	1192(ra) # 80002eea <argint>
    80005a4a:	0a054863          	bltz	a0,80005afa <sys_open+0xe4>

  begin_op();
    80005a4e:	fffff097          	auipc	ra,0xfffff
    80005a52:	a2e080e7          	jalr	-1490(ra) # 8000447c <begin_op>

  if(omode & O_CREATE){
    80005a56:	f4c42783          	lw	a5,-180(s0)
    80005a5a:	2007f793          	andi	a5,a5,512
    80005a5e:	cbdd                	beqz	a5,80005b14 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005a60:	4681                	li	a3,0
    80005a62:	4601                	li	a2,0
    80005a64:	4589                	li	a1,2
    80005a66:	f5040513          	addi	a0,s0,-176
    80005a6a:	00000097          	auipc	ra,0x0
    80005a6e:	972080e7          	jalr	-1678(ra) # 800053dc <create>
    80005a72:	892a                	mv	s2,a0
    if(ip == 0){
    80005a74:	c959                	beqz	a0,80005b0a <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005a76:	04491703          	lh	a4,68(s2)
    80005a7a:	478d                	li	a5,3
    80005a7c:	00f71763          	bne	a4,a5,80005a8a <sys_open+0x74>
    80005a80:	04695703          	lhu	a4,70(s2)
    80005a84:	47a5                	li	a5,9
    80005a86:	0ce7ec63          	bltu	a5,a4,80005b5e <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005a8a:	fffff097          	auipc	ra,0xfffff
    80005a8e:	e02080e7          	jalr	-510(ra) # 8000488c <filealloc>
    80005a92:	89aa                	mv	s3,a0
    80005a94:	10050263          	beqz	a0,80005b98 <sys_open+0x182>
    80005a98:	00000097          	auipc	ra,0x0
    80005a9c:	902080e7          	jalr	-1790(ra) # 8000539a <fdalloc>
    80005aa0:	84aa                	mv	s1,a0
    80005aa2:	0e054663          	bltz	a0,80005b8e <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005aa6:	04491703          	lh	a4,68(s2)
    80005aaa:	478d                	li	a5,3
    80005aac:	0cf70463          	beq	a4,a5,80005b74 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005ab0:	4789                	li	a5,2
    80005ab2:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005ab6:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005aba:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005abe:	f4c42783          	lw	a5,-180(s0)
    80005ac2:	0017c713          	xori	a4,a5,1
    80005ac6:	8b05                	andi	a4,a4,1
    80005ac8:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005acc:	0037f713          	andi	a4,a5,3
    80005ad0:	00e03733          	snez	a4,a4
    80005ad4:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005ad8:	4007f793          	andi	a5,a5,1024
    80005adc:	c791                	beqz	a5,80005ae8 <sys_open+0xd2>
    80005ade:	04491703          	lh	a4,68(s2)
    80005ae2:	4789                	li	a5,2
    80005ae4:	08f70f63          	beq	a4,a5,80005b82 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005ae8:	854a                	mv	a0,s2
    80005aea:	ffffe097          	auipc	ra,0xffffe
    80005aee:	082080e7          	jalr	130(ra) # 80003b6c <iunlock>
  end_op();
    80005af2:	fffff097          	auipc	ra,0xfffff
    80005af6:	a0a080e7          	jalr	-1526(ra) # 800044fc <end_op>

  return fd;
}
    80005afa:	8526                	mv	a0,s1
    80005afc:	70ea                	ld	ra,184(sp)
    80005afe:	744a                	ld	s0,176(sp)
    80005b00:	74aa                	ld	s1,168(sp)
    80005b02:	790a                	ld	s2,160(sp)
    80005b04:	69ea                	ld	s3,152(sp)
    80005b06:	6129                	addi	sp,sp,192
    80005b08:	8082                	ret
      end_op();
    80005b0a:	fffff097          	auipc	ra,0xfffff
    80005b0e:	9f2080e7          	jalr	-1550(ra) # 800044fc <end_op>
      return -1;
    80005b12:	b7e5                	j	80005afa <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005b14:	f5040513          	addi	a0,s0,-176
    80005b18:	ffffe097          	auipc	ra,0xffffe
    80005b1c:	748080e7          	jalr	1864(ra) # 80004260 <namei>
    80005b20:	892a                	mv	s2,a0
    80005b22:	c905                	beqz	a0,80005b52 <sys_open+0x13c>
    ilock(ip);
    80005b24:	ffffe097          	auipc	ra,0xffffe
    80005b28:	f86080e7          	jalr	-122(ra) # 80003aaa <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005b2c:	04491703          	lh	a4,68(s2)
    80005b30:	4785                	li	a5,1
    80005b32:	f4f712e3          	bne	a4,a5,80005a76 <sys_open+0x60>
    80005b36:	f4c42783          	lw	a5,-180(s0)
    80005b3a:	dba1                	beqz	a5,80005a8a <sys_open+0x74>
      iunlockput(ip);
    80005b3c:	854a                	mv	a0,s2
    80005b3e:	ffffe097          	auipc	ra,0xffffe
    80005b42:	1ce080e7          	jalr	462(ra) # 80003d0c <iunlockput>
      end_op();
    80005b46:	fffff097          	auipc	ra,0xfffff
    80005b4a:	9b6080e7          	jalr	-1610(ra) # 800044fc <end_op>
      return -1;
    80005b4e:	54fd                	li	s1,-1
    80005b50:	b76d                	j	80005afa <sys_open+0xe4>
      end_op();
    80005b52:	fffff097          	auipc	ra,0xfffff
    80005b56:	9aa080e7          	jalr	-1622(ra) # 800044fc <end_op>
      return -1;
    80005b5a:	54fd                	li	s1,-1
    80005b5c:	bf79                	j	80005afa <sys_open+0xe4>
    iunlockput(ip);
    80005b5e:	854a                	mv	a0,s2
    80005b60:	ffffe097          	auipc	ra,0xffffe
    80005b64:	1ac080e7          	jalr	428(ra) # 80003d0c <iunlockput>
    end_op();
    80005b68:	fffff097          	auipc	ra,0xfffff
    80005b6c:	994080e7          	jalr	-1644(ra) # 800044fc <end_op>
    return -1;
    80005b70:	54fd                	li	s1,-1
    80005b72:	b761                	j	80005afa <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005b74:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005b78:	04691783          	lh	a5,70(s2)
    80005b7c:	02f99223          	sh	a5,36(s3)
    80005b80:	bf2d                	j	80005aba <sys_open+0xa4>
    itrunc(ip);
    80005b82:	854a                	mv	a0,s2
    80005b84:	ffffe097          	auipc	ra,0xffffe
    80005b88:	034080e7          	jalr	52(ra) # 80003bb8 <itrunc>
    80005b8c:	bfb1                	j	80005ae8 <sys_open+0xd2>
      fileclose(f);
    80005b8e:	854e                	mv	a0,s3
    80005b90:	fffff097          	auipc	ra,0xfffff
    80005b94:	db8080e7          	jalr	-584(ra) # 80004948 <fileclose>
    iunlockput(ip);
    80005b98:	854a                	mv	a0,s2
    80005b9a:	ffffe097          	auipc	ra,0xffffe
    80005b9e:	172080e7          	jalr	370(ra) # 80003d0c <iunlockput>
    end_op();
    80005ba2:	fffff097          	auipc	ra,0xfffff
    80005ba6:	95a080e7          	jalr	-1702(ra) # 800044fc <end_op>
    return -1;
    80005baa:	54fd                	li	s1,-1
    80005bac:	b7b9                	j	80005afa <sys_open+0xe4>

0000000080005bae <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005bae:	7175                	addi	sp,sp,-144
    80005bb0:	e506                	sd	ra,136(sp)
    80005bb2:	e122                	sd	s0,128(sp)
    80005bb4:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005bb6:	fffff097          	auipc	ra,0xfffff
    80005bba:	8c6080e7          	jalr	-1850(ra) # 8000447c <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005bbe:	08000613          	li	a2,128
    80005bc2:	f7040593          	addi	a1,s0,-144
    80005bc6:	4501                	li	a0,0
    80005bc8:	ffffd097          	auipc	ra,0xffffd
    80005bcc:	366080e7          	jalr	870(ra) # 80002f2e <argstr>
    80005bd0:	02054963          	bltz	a0,80005c02 <sys_mkdir+0x54>
    80005bd4:	4681                	li	a3,0
    80005bd6:	4601                	li	a2,0
    80005bd8:	4585                	li	a1,1
    80005bda:	f7040513          	addi	a0,s0,-144
    80005bde:	fffff097          	auipc	ra,0xfffff
    80005be2:	7fe080e7          	jalr	2046(ra) # 800053dc <create>
    80005be6:	cd11                	beqz	a0,80005c02 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005be8:	ffffe097          	auipc	ra,0xffffe
    80005bec:	124080e7          	jalr	292(ra) # 80003d0c <iunlockput>
  end_op();
    80005bf0:	fffff097          	auipc	ra,0xfffff
    80005bf4:	90c080e7          	jalr	-1780(ra) # 800044fc <end_op>
  return 0;
    80005bf8:	4501                	li	a0,0
}
    80005bfa:	60aa                	ld	ra,136(sp)
    80005bfc:	640a                	ld	s0,128(sp)
    80005bfe:	6149                	addi	sp,sp,144
    80005c00:	8082                	ret
    end_op();
    80005c02:	fffff097          	auipc	ra,0xfffff
    80005c06:	8fa080e7          	jalr	-1798(ra) # 800044fc <end_op>
    return -1;
    80005c0a:	557d                	li	a0,-1
    80005c0c:	b7fd                	j	80005bfa <sys_mkdir+0x4c>

0000000080005c0e <sys_mknod>:

uint64
sys_mknod(void)
{
    80005c0e:	7135                	addi	sp,sp,-160
    80005c10:	ed06                	sd	ra,152(sp)
    80005c12:	e922                	sd	s0,144(sp)
    80005c14:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005c16:	fffff097          	auipc	ra,0xfffff
    80005c1a:	866080e7          	jalr	-1946(ra) # 8000447c <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005c1e:	08000613          	li	a2,128
    80005c22:	f7040593          	addi	a1,s0,-144
    80005c26:	4501                	li	a0,0
    80005c28:	ffffd097          	auipc	ra,0xffffd
    80005c2c:	306080e7          	jalr	774(ra) # 80002f2e <argstr>
    80005c30:	04054a63          	bltz	a0,80005c84 <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    80005c34:	f6c40593          	addi	a1,s0,-148
    80005c38:	4505                	li	a0,1
    80005c3a:	ffffd097          	auipc	ra,0xffffd
    80005c3e:	2b0080e7          	jalr	688(ra) # 80002eea <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005c42:	04054163          	bltz	a0,80005c84 <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    80005c46:	f6840593          	addi	a1,s0,-152
    80005c4a:	4509                	li	a0,2
    80005c4c:	ffffd097          	auipc	ra,0xffffd
    80005c50:	29e080e7          	jalr	670(ra) # 80002eea <argint>
     argint(1, &major) < 0 ||
    80005c54:	02054863          	bltz	a0,80005c84 <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005c58:	f6841683          	lh	a3,-152(s0)
    80005c5c:	f6c41603          	lh	a2,-148(s0)
    80005c60:	458d                	li	a1,3
    80005c62:	f7040513          	addi	a0,s0,-144
    80005c66:	fffff097          	auipc	ra,0xfffff
    80005c6a:	776080e7          	jalr	1910(ra) # 800053dc <create>
     argint(2, &minor) < 0 ||
    80005c6e:	c919                	beqz	a0,80005c84 <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005c70:	ffffe097          	auipc	ra,0xffffe
    80005c74:	09c080e7          	jalr	156(ra) # 80003d0c <iunlockput>
  end_op();
    80005c78:	fffff097          	auipc	ra,0xfffff
    80005c7c:	884080e7          	jalr	-1916(ra) # 800044fc <end_op>
  return 0;
    80005c80:	4501                	li	a0,0
    80005c82:	a031                	j	80005c8e <sys_mknod+0x80>
    end_op();
    80005c84:	fffff097          	auipc	ra,0xfffff
    80005c88:	878080e7          	jalr	-1928(ra) # 800044fc <end_op>
    return -1;
    80005c8c:	557d                	li	a0,-1
}
    80005c8e:	60ea                	ld	ra,152(sp)
    80005c90:	644a                	ld	s0,144(sp)
    80005c92:	610d                	addi	sp,sp,160
    80005c94:	8082                	ret

0000000080005c96 <sys_chdir>:

uint64
sys_chdir(void)
{
    80005c96:	7135                	addi	sp,sp,-160
    80005c98:	ed06                	sd	ra,152(sp)
    80005c9a:	e922                	sd	s0,144(sp)
    80005c9c:	e526                	sd	s1,136(sp)
    80005c9e:	e14a                	sd	s2,128(sp)
    80005ca0:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005ca2:	ffffc097          	auipc	ra,0xffffc
    80005ca6:	d26080e7          	jalr	-730(ra) # 800019c8 <myproc>
    80005caa:	892a                	mv	s2,a0
  
  begin_op();
    80005cac:	ffffe097          	auipc	ra,0xffffe
    80005cb0:	7d0080e7          	jalr	2000(ra) # 8000447c <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005cb4:	08000613          	li	a2,128
    80005cb8:	f6040593          	addi	a1,s0,-160
    80005cbc:	4501                	li	a0,0
    80005cbe:	ffffd097          	auipc	ra,0xffffd
    80005cc2:	270080e7          	jalr	624(ra) # 80002f2e <argstr>
    80005cc6:	04054b63          	bltz	a0,80005d1c <sys_chdir+0x86>
    80005cca:	f6040513          	addi	a0,s0,-160
    80005cce:	ffffe097          	auipc	ra,0xffffe
    80005cd2:	592080e7          	jalr	1426(ra) # 80004260 <namei>
    80005cd6:	84aa                	mv	s1,a0
    80005cd8:	c131                	beqz	a0,80005d1c <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005cda:	ffffe097          	auipc	ra,0xffffe
    80005cde:	dd0080e7          	jalr	-560(ra) # 80003aaa <ilock>
  if(ip->type != T_DIR){
    80005ce2:	04449703          	lh	a4,68(s1)
    80005ce6:	4785                	li	a5,1
    80005ce8:	04f71063          	bne	a4,a5,80005d28 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005cec:	8526                	mv	a0,s1
    80005cee:	ffffe097          	auipc	ra,0xffffe
    80005cf2:	e7e080e7          	jalr	-386(ra) # 80003b6c <iunlock>
  iput(p->cwd);
    80005cf6:	17093503          	ld	a0,368(s2)
    80005cfa:	ffffe097          	auipc	ra,0xffffe
    80005cfe:	f6a080e7          	jalr	-150(ra) # 80003c64 <iput>
  end_op();
    80005d02:	ffffe097          	auipc	ra,0xffffe
    80005d06:	7fa080e7          	jalr	2042(ra) # 800044fc <end_op>
  p->cwd = ip;
    80005d0a:	16993823          	sd	s1,368(s2)
  return 0;
    80005d0e:	4501                	li	a0,0
}
    80005d10:	60ea                	ld	ra,152(sp)
    80005d12:	644a                	ld	s0,144(sp)
    80005d14:	64aa                	ld	s1,136(sp)
    80005d16:	690a                	ld	s2,128(sp)
    80005d18:	610d                	addi	sp,sp,160
    80005d1a:	8082                	ret
    end_op();
    80005d1c:	ffffe097          	auipc	ra,0xffffe
    80005d20:	7e0080e7          	jalr	2016(ra) # 800044fc <end_op>
    return -1;
    80005d24:	557d                	li	a0,-1
    80005d26:	b7ed                	j	80005d10 <sys_chdir+0x7a>
    iunlockput(ip);
    80005d28:	8526                	mv	a0,s1
    80005d2a:	ffffe097          	auipc	ra,0xffffe
    80005d2e:	fe2080e7          	jalr	-30(ra) # 80003d0c <iunlockput>
    end_op();
    80005d32:	ffffe097          	auipc	ra,0xffffe
    80005d36:	7ca080e7          	jalr	1994(ra) # 800044fc <end_op>
    return -1;
    80005d3a:	557d                	li	a0,-1
    80005d3c:	bfd1                	j	80005d10 <sys_chdir+0x7a>

0000000080005d3e <sys_exec>:

uint64
sys_exec(void)
{
    80005d3e:	7145                	addi	sp,sp,-464
    80005d40:	e786                	sd	ra,456(sp)
    80005d42:	e3a2                	sd	s0,448(sp)
    80005d44:	ff26                	sd	s1,440(sp)
    80005d46:	fb4a                	sd	s2,432(sp)
    80005d48:	f74e                	sd	s3,424(sp)
    80005d4a:	f352                	sd	s4,416(sp)
    80005d4c:	ef56                	sd	s5,408(sp)
    80005d4e:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005d50:	08000613          	li	a2,128
    80005d54:	f4040593          	addi	a1,s0,-192
    80005d58:	4501                	li	a0,0
    80005d5a:	ffffd097          	auipc	ra,0xffffd
    80005d5e:	1d4080e7          	jalr	468(ra) # 80002f2e <argstr>
    return -1;
    80005d62:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005d64:	0c054a63          	bltz	a0,80005e38 <sys_exec+0xfa>
    80005d68:	e3840593          	addi	a1,s0,-456
    80005d6c:	4505                	li	a0,1
    80005d6e:	ffffd097          	auipc	ra,0xffffd
    80005d72:	19e080e7          	jalr	414(ra) # 80002f0c <argaddr>
    80005d76:	0c054163          	bltz	a0,80005e38 <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80005d7a:	10000613          	li	a2,256
    80005d7e:	4581                	li	a1,0
    80005d80:	e4040513          	addi	a0,s0,-448
    80005d84:	ffffb097          	auipc	ra,0xffffb
    80005d88:	f5c080e7          	jalr	-164(ra) # 80000ce0 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005d8c:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005d90:	89a6                	mv	s3,s1
    80005d92:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005d94:	02000a13          	li	s4,32
    80005d98:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005d9c:	00391513          	slli	a0,s2,0x3
    80005da0:	e3040593          	addi	a1,s0,-464
    80005da4:	e3843783          	ld	a5,-456(s0)
    80005da8:	953e                	add	a0,a0,a5
    80005daa:	ffffd097          	auipc	ra,0xffffd
    80005dae:	0a6080e7          	jalr	166(ra) # 80002e50 <fetchaddr>
    80005db2:	02054a63          	bltz	a0,80005de6 <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    80005db6:	e3043783          	ld	a5,-464(s0)
    80005dba:	c3b9                	beqz	a5,80005e00 <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005dbc:	ffffb097          	auipc	ra,0xffffb
    80005dc0:	d38080e7          	jalr	-712(ra) # 80000af4 <kalloc>
    80005dc4:	85aa                	mv	a1,a0
    80005dc6:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005dca:	cd11                	beqz	a0,80005de6 <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005dcc:	6605                	lui	a2,0x1
    80005dce:	e3043503          	ld	a0,-464(s0)
    80005dd2:	ffffd097          	auipc	ra,0xffffd
    80005dd6:	0d0080e7          	jalr	208(ra) # 80002ea2 <fetchstr>
    80005dda:	00054663          	bltz	a0,80005de6 <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80005dde:	0905                	addi	s2,s2,1
    80005de0:	09a1                	addi	s3,s3,8
    80005de2:	fb491be3          	bne	s2,s4,80005d98 <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005de6:	10048913          	addi	s2,s1,256
    80005dea:	6088                	ld	a0,0(s1)
    80005dec:	c529                	beqz	a0,80005e36 <sys_exec+0xf8>
    kfree(argv[i]);
    80005dee:	ffffb097          	auipc	ra,0xffffb
    80005df2:	c0a080e7          	jalr	-1014(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005df6:	04a1                	addi	s1,s1,8
    80005df8:	ff2499e3          	bne	s1,s2,80005dea <sys_exec+0xac>
  return -1;
    80005dfc:	597d                	li	s2,-1
    80005dfe:	a82d                	j	80005e38 <sys_exec+0xfa>
      argv[i] = 0;
    80005e00:	0a8e                	slli	s5,s5,0x3
    80005e02:	fc040793          	addi	a5,s0,-64
    80005e06:	9abe                	add	s5,s5,a5
    80005e08:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005e0c:	e4040593          	addi	a1,s0,-448
    80005e10:	f4040513          	addi	a0,s0,-192
    80005e14:	fffff097          	auipc	ra,0xfffff
    80005e18:	194080e7          	jalr	404(ra) # 80004fa8 <exec>
    80005e1c:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005e1e:	10048993          	addi	s3,s1,256
    80005e22:	6088                	ld	a0,0(s1)
    80005e24:	c911                	beqz	a0,80005e38 <sys_exec+0xfa>
    kfree(argv[i]);
    80005e26:	ffffb097          	auipc	ra,0xffffb
    80005e2a:	bd2080e7          	jalr	-1070(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005e2e:	04a1                	addi	s1,s1,8
    80005e30:	ff3499e3          	bne	s1,s3,80005e22 <sys_exec+0xe4>
    80005e34:	a011                	j	80005e38 <sys_exec+0xfa>
  return -1;
    80005e36:	597d                	li	s2,-1
}
    80005e38:	854a                	mv	a0,s2
    80005e3a:	60be                	ld	ra,456(sp)
    80005e3c:	641e                	ld	s0,448(sp)
    80005e3e:	74fa                	ld	s1,440(sp)
    80005e40:	795a                	ld	s2,432(sp)
    80005e42:	79ba                	ld	s3,424(sp)
    80005e44:	7a1a                	ld	s4,416(sp)
    80005e46:	6afa                	ld	s5,408(sp)
    80005e48:	6179                	addi	sp,sp,464
    80005e4a:	8082                	ret

0000000080005e4c <sys_pipe>:

uint64
sys_pipe(void)
{
    80005e4c:	7139                	addi	sp,sp,-64
    80005e4e:	fc06                	sd	ra,56(sp)
    80005e50:	f822                	sd	s0,48(sp)
    80005e52:	f426                	sd	s1,40(sp)
    80005e54:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005e56:	ffffc097          	auipc	ra,0xffffc
    80005e5a:	b72080e7          	jalr	-1166(ra) # 800019c8 <myproc>
    80005e5e:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80005e60:	fd840593          	addi	a1,s0,-40
    80005e64:	4501                	li	a0,0
    80005e66:	ffffd097          	auipc	ra,0xffffd
    80005e6a:	0a6080e7          	jalr	166(ra) # 80002f0c <argaddr>
    return -1;
    80005e6e:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80005e70:	0e054063          	bltz	a0,80005f50 <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    80005e74:	fc840593          	addi	a1,s0,-56
    80005e78:	fd040513          	addi	a0,s0,-48
    80005e7c:	fffff097          	auipc	ra,0xfffff
    80005e80:	dfc080e7          	jalr	-516(ra) # 80004c78 <pipealloc>
    return -1;
    80005e84:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005e86:	0c054563          	bltz	a0,80005f50 <sys_pipe+0x104>
  fd0 = -1;
    80005e8a:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005e8e:	fd043503          	ld	a0,-48(s0)
    80005e92:	fffff097          	auipc	ra,0xfffff
    80005e96:	508080e7          	jalr	1288(ra) # 8000539a <fdalloc>
    80005e9a:	fca42223          	sw	a0,-60(s0)
    80005e9e:	08054c63          	bltz	a0,80005f36 <sys_pipe+0xea>
    80005ea2:	fc843503          	ld	a0,-56(s0)
    80005ea6:	fffff097          	auipc	ra,0xfffff
    80005eaa:	4f4080e7          	jalr	1268(ra) # 8000539a <fdalloc>
    80005eae:	fca42023          	sw	a0,-64(s0)
    80005eb2:	06054863          	bltz	a0,80005f22 <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005eb6:	4691                	li	a3,4
    80005eb8:	fc440613          	addi	a2,s0,-60
    80005ebc:	fd843583          	ld	a1,-40(s0)
    80005ec0:	78a8                	ld	a0,112(s1)
    80005ec2:	ffffb097          	auipc	ra,0xffffb
    80005ec6:	7b8080e7          	jalr	1976(ra) # 8000167a <copyout>
    80005eca:	02054063          	bltz	a0,80005eea <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005ece:	4691                	li	a3,4
    80005ed0:	fc040613          	addi	a2,s0,-64
    80005ed4:	fd843583          	ld	a1,-40(s0)
    80005ed8:	0591                	addi	a1,a1,4
    80005eda:	78a8                	ld	a0,112(s1)
    80005edc:	ffffb097          	auipc	ra,0xffffb
    80005ee0:	79e080e7          	jalr	1950(ra) # 8000167a <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005ee4:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005ee6:	06055563          	bgez	a0,80005f50 <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80005eea:	fc442783          	lw	a5,-60(s0)
    80005eee:	07f9                	addi	a5,a5,30
    80005ef0:	078e                	slli	a5,a5,0x3
    80005ef2:	97a6                	add	a5,a5,s1
    80005ef4:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005ef8:	fc042503          	lw	a0,-64(s0)
    80005efc:	0579                	addi	a0,a0,30
    80005efe:	050e                	slli	a0,a0,0x3
    80005f00:	9526                	add	a0,a0,s1
    80005f02:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005f06:	fd043503          	ld	a0,-48(s0)
    80005f0a:	fffff097          	auipc	ra,0xfffff
    80005f0e:	a3e080e7          	jalr	-1474(ra) # 80004948 <fileclose>
    fileclose(wf);
    80005f12:	fc843503          	ld	a0,-56(s0)
    80005f16:	fffff097          	auipc	ra,0xfffff
    80005f1a:	a32080e7          	jalr	-1486(ra) # 80004948 <fileclose>
    return -1;
    80005f1e:	57fd                	li	a5,-1
    80005f20:	a805                	j	80005f50 <sys_pipe+0x104>
    if(fd0 >= 0)
    80005f22:	fc442783          	lw	a5,-60(s0)
    80005f26:	0007c863          	bltz	a5,80005f36 <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80005f2a:	01e78513          	addi	a0,a5,30
    80005f2e:	050e                	slli	a0,a0,0x3
    80005f30:	9526                	add	a0,a0,s1
    80005f32:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005f36:	fd043503          	ld	a0,-48(s0)
    80005f3a:	fffff097          	auipc	ra,0xfffff
    80005f3e:	a0e080e7          	jalr	-1522(ra) # 80004948 <fileclose>
    fileclose(wf);
    80005f42:	fc843503          	ld	a0,-56(s0)
    80005f46:	fffff097          	auipc	ra,0xfffff
    80005f4a:	a02080e7          	jalr	-1534(ra) # 80004948 <fileclose>
    return -1;
    80005f4e:	57fd                	li	a5,-1
}
    80005f50:	853e                	mv	a0,a5
    80005f52:	70e2                	ld	ra,56(sp)
    80005f54:	7442                	ld	s0,48(sp)
    80005f56:	74a2                	ld	s1,40(sp)
    80005f58:	6121                	addi	sp,sp,64
    80005f5a:	8082                	ret
    80005f5c:	0000                	unimp
	...

0000000080005f60 <kernelvec>:
    80005f60:	7111                	addi	sp,sp,-256
    80005f62:	e006                	sd	ra,0(sp)
    80005f64:	e40a                	sd	sp,8(sp)
    80005f66:	e80e                	sd	gp,16(sp)
    80005f68:	ec12                	sd	tp,24(sp)
    80005f6a:	f016                	sd	t0,32(sp)
    80005f6c:	f41a                	sd	t1,40(sp)
    80005f6e:	f81e                	sd	t2,48(sp)
    80005f70:	fc22                	sd	s0,56(sp)
    80005f72:	e0a6                	sd	s1,64(sp)
    80005f74:	e4aa                	sd	a0,72(sp)
    80005f76:	e8ae                	sd	a1,80(sp)
    80005f78:	ecb2                	sd	a2,88(sp)
    80005f7a:	f0b6                	sd	a3,96(sp)
    80005f7c:	f4ba                	sd	a4,104(sp)
    80005f7e:	f8be                	sd	a5,112(sp)
    80005f80:	fcc2                	sd	a6,120(sp)
    80005f82:	e146                	sd	a7,128(sp)
    80005f84:	e54a                	sd	s2,136(sp)
    80005f86:	e94e                	sd	s3,144(sp)
    80005f88:	ed52                	sd	s4,152(sp)
    80005f8a:	f156                	sd	s5,160(sp)
    80005f8c:	f55a                	sd	s6,168(sp)
    80005f8e:	f95e                	sd	s7,176(sp)
    80005f90:	fd62                	sd	s8,184(sp)
    80005f92:	e1e6                	sd	s9,192(sp)
    80005f94:	e5ea                	sd	s10,200(sp)
    80005f96:	e9ee                	sd	s11,208(sp)
    80005f98:	edf2                	sd	t3,216(sp)
    80005f9a:	f1f6                	sd	t4,224(sp)
    80005f9c:	f5fa                	sd	t5,232(sp)
    80005f9e:	f9fe                	sd	t6,240(sp)
    80005fa0:	d7dfc0ef          	jal	ra,80002d1c <kerneltrap>
    80005fa4:	6082                	ld	ra,0(sp)
    80005fa6:	6122                	ld	sp,8(sp)
    80005fa8:	61c2                	ld	gp,16(sp)
    80005faa:	7282                	ld	t0,32(sp)
    80005fac:	7322                	ld	t1,40(sp)
    80005fae:	73c2                	ld	t2,48(sp)
    80005fb0:	7462                	ld	s0,56(sp)
    80005fb2:	6486                	ld	s1,64(sp)
    80005fb4:	6526                	ld	a0,72(sp)
    80005fb6:	65c6                	ld	a1,80(sp)
    80005fb8:	6666                	ld	a2,88(sp)
    80005fba:	7686                	ld	a3,96(sp)
    80005fbc:	7726                	ld	a4,104(sp)
    80005fbe:	77c6                	ld	a5,112(sp)
    80005fc0:	7866                	ld	a6,120(sp)
    80005fc2:	688a                	ld	a7,128(sp)
    80005fc4:	692a                	ld	s2,136(sp)
    80005fc6:	69ca                	ld	s3,144(sp)
    80005fc8:	6a6a                	ld	s4,152(sp)
    80005fca:	7a8a                	ld	s5,160(sp)
    80005fcc:	7b2a                	ld	s6,168(sp)
    80005fce:	7bca                	ld	s7,176(sp)
    80005fd0:	7c6a                	ld	s8,184(sp)
    80005fd2:	6c8e                	ld	s9,192(sp)
    80005fd4:	6d2e                	ld	s10,200(sp)
    80005fd6:	6dce                	ld	s11,208(sp)
    80005fd8:	6e6e                	ld	t3,216(sp)
    80005fda:	7e8e                	ld	t4,224(sp)
    80005fdc:	7f2e                	ld	t5,232(sp)
    80005fde:	7fce                	ld	t6,240(sp)
    80005fe0:	6111                	addi	sp,sp,256
    80005fe2:	10200073          	sret
    80005fe6:	00000013          	nop
    80005fea:	00000013          	nop
    80005fee:	0001                	nop

0000000080005ff0 <timervec>:
    80005ff0:	34051573          	csrrw	a0,mscratch,a0
    80005ff4:	e10c                	sd	a1,0(a0)
    80005ff6:	e510                	sd	a2,8(a0)
    80005ff8:	e914                	sd	a3,16(a0)
    80005ffa:	6d0c                	ld	a1,24(a0)
    80005ffc:	7110                	ld	a2,32(a0)
    80005ffe:	6194                	ld	a3,0(a1)
    80006000:	96b2                	add	a3,a3,a2
    80006002:	e194                	sd	a3,0(a1)
    80006004:	4589                	li	a1,2
    80006006:	14459073          	csrw	sip,a1
    8000600a:	6914                	ld	a3,16(a0)
    8000600c:	6510                	ld	a2,8(a0)
    8000600e:	610c                	ld	a1,0(a0)
    80006010:	34051573          	csrrw	a0,mscratch,a0
    80006014:	30200073          	mret
	...

000000008000601a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    8000601a:	1141                	addi	sp,sp,-16
    8000601c:	e422                	sd	s0,8(sp)
    8000601e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80006020:	0c0007b7          	lui	a5,0xc000
    80006024:	4705                	li	a4,1
    80006026:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80006028:	c3d8                	sw	a4,4(a5)
}
    8000602a:	6422                	ld	s0,8(sp)
    8000602c:	0141                	addi	sp,sp,16
    8000602e:	8082                	ret

0000000080006030 <plicinithart>:

void
plicinithart(void)
{
    80006030:	1141                	addi	sp,sp,-16
    80006032:	e406                	sd	ra,8(sp)
    80006034:	e022                	sd	s0,0(sp)
    80006036:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006038:	ffffc097          	auipc	ra,0xffffc
    8000603c:	964080e7          	jalr	-1692(ra) # 8000199c <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80006040:	0085171b          	slliw	a4,a0,0x8
    80006044:	0c0027b7          	lui	a5,0xc002
    80006048:	97ba                	add	a5,a5,a4
    8000604a:	40200713          	li	a4,1026
    8000604e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80006052:	00d5151b          	slliw	a0,a0,0xd
    80006056:	0c2017b7          	lui	a5,0xc201
    8000605a:	953e                	add	a0,a0,a5
    8000605c:	00052023          	sw	zero,0(a0)
}
    80006060:	60a2                	ld	ra,8(sp)
    80006062:	6402                	ld	s0,0(sp)
    80006064:	0141                	addi	sp,sp,16
    80006066:	8082                	ret

0000000080006068 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80006068:	1141                	addi	sp,sp,-16
    8000606a:	e406                	sd	ra,8(sp)
    8000606c:	e022                	sd	s0,0(sp)
    8000606e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006070:	ffffc097          	auipc	ra,0xffffc
    80006074:	92c080e7          	jalr	-1748(ra) # 8000199c <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80006078:	00d5179b          	slliw	a5,a0,0xd
    8000607c:	0c201537          	lui	a0,0xc201
    80006080:	953e                	add	a0,a0,a5
  return irq;
}
    80006082:	4148                	lw	a0,4(a0)
    80006084:	60a2                	ld	ra,8(sp)
    80006086:	6402                	ld	s0,0(sp)
    80006088:	0141                	addi	sp,sp,16
    8000608a:	8082                	ret

000000008000608c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    8000608c:	1101                	addi	sp,sp,-32
    8000608e:	ec06                	sd	ra,24(sp)
    80006090:	e822                	sd	s0,16(sp)
    80006092:	e426                	sd	s1,8(sp)
    80006094:	1000                	addi	s0,sp,32
    80006096:	84aa                	mv	s1,a0
  int hart = cpuid();
    80006098:	ffffc097          	auipc	ra,0xffffc
    8000609c:	904080e7          	jalr	-1788(ra) # 8000199c <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    800060a0:	00d5151b          	slliw	a0,a0,0xd
    800060a4:	0c2017b7          	lui	a5,0xc201
    800060a8:	97aa                	add	a5,a5,a0
    800060aa:	c3c4                	sw	s1,4(a5)
}
    800060ac:	60e2                	ld	ra,24(sp)
    800060ae:	6442                	ld	s0,16(sp)
    800060b0:	64a2                	ld	s1,8(sp)
    800060b2:	6105                	addi	sp,sp,32
    800060b4:	8082                	ret

00000000800060b6 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    800060b6:	1141                	addi	sp,sp,-16
    800060b8:	e406                	sd	ra,8(sp)
    800060ba:	e022                	sd	s0,0(sp)
    800060bc:	0800                	addi	s0,sp,16
  if(i >= NUM)
    800060be:	479d                	li	a5,7
    800060c0:	06a7c963          	blt	a5,a0,80006132 <free_desc+0x7c>
    panic("free_desc 1");
  if(disk.free[i])
    800060c4:	0001d797          	auipc	a5,0x1d
    800060c8:	f3c78793          	addi	a5,a5,-196 # 80023000 <disk>
    800060cc:	00a78733          	add	a4,a5,a0
    800060d0:	6789                	lui	a5,0x2
    800060d2:	97ba                	add	a5,a5,a4
    800060d4:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    800060d8:	e7ad                	bnez	a5,80006142 <free_desc+0x8c>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    800060da:	00451793          	slli	a5,a0,0x4
    800060de:	0001f717          	auipc	a4,0x1f
    800060e2:	f2270713          	addi	a4,a4,-222 # 80025000 <disk+0x2000>
    800060e6:	6314                	ld	a3,0(a4)
    800060e8:	96be                	add	a3,a3,a5
    800060ea:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    800060ee:	6314                	ld	a3,0(a4)
    800060f0:	96be                	add	a3,a3,a5
    800060f2:	0006a423          	sw	zero,8(a3)
  disk.desc[i].flags = 0;
    800060f6:	6314                	ld	a3,0(a4)
    800060f8:	96be                	add	a3,a3,a5
    800060fa:	00069623          	sh	zero,12(a3)
  disk.desc[i].next = 0;
    800060fe:	6318                	ld	a4,0(a4)
    80006100:	97ba                	add	a5,a5,a4
    80006102:	00079723          	sh	zero,14(a5)
  disk.free[i] = 1;
    80006106:	0001d797          	auipc	a5,0x1d
    8000610a:	efa78793          	addi	a5,a5,-262 # 80023000 <disk>
    8000610e:	97aa                	add	a5,a5,a0
    80006110:	6509                	lui	a0,0x2
    80006112:	953e                	add	a0,a0,a5
    80006114:	4785                	li	a5,1
    80006116:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    8000611a:	0001f517          	auipc	a0,0x1f
    8000611e:	efe50513          	addi	a0,a0,-258 # 80025018 <disk+0x2018>
    80006122:	ffffc097          	auipc	ra,0xffffc
    80006126:	3f6080e7          	jalr	1014(ra) # 80002518 <wakeup>
}
    8000612a:	60a2                	ld	ra,8(sp)
    8000612c:	6402                	ld	s0,0(sp)
    8000612e:	0141                	addi	sp,sp,16
    80006130:	8082                	ret
    panic("free_desc 1");
    80006132:	00002517          	auipc	a0,0x2
    80006136:	65650513          	addi	a0,a0,1622 # 80008788 <syscalls+0x330>
    8000613a:	ffffa097          	auipc	ra,0xffffa
    8000613e:	404080e7          	jalr	1028(ra) # 8000053e <panic>
    panic("free_desc 2");
    80006142:	00002517          	auipc	a0,0x2
    80006146:	65650513          	addi	a0,a0,1622 # 80008798 <syscalls+0x340>
    8000614a:	ffffa097          	auipc	ra,0xffffa
    8000614e:	3f4080e7          	jalr	1012(ra) # 8000053e <panic>

0000000080006152 <virtio_disk_init>:
{
    80006152:	1101                	addi	sp,sp,-32
    80006154:	ec06                	sd	ra,24(sp)
    80006156:	e822                	sd	s0,16(sp)
    80006158:	e426                	sd	s1,8(sp)
    8000615a:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    8000615c:	00002597          	auipc	a1,0x2
    80006160:	64c58593          	addi	a1,a1,1612 # 800087a8 <syscalls+0x350>
    80006164:	0001f517          	auipc	a0,0x1f
    80006168:	fc450513          	addi	a0,a0,-60 # 80025128 <disk+0x2128>
    8000616c:	ffffb097          	auipc	ra,0xffffb
    80006170:	9e8080e7          	jalr	-1560(ra) # 80000b54 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006174:	100017b7          	lui	a5,0x10001
    80006178:	4398                	lw	a4,0(a5)
    8000617a:	2701                	sext.w	a4,a4
    8000617c:	747277b7          	lui	a5,0x74727
    80006180:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80006184:	0ef71163          	bne	a4,a5,80006266 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80006188:	100017b7          	lui	a5,0x10001
    8000618c:	43dc                	lw	a5,4(a5)
    8000618e:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006190:	4705                	li	a4,1
    80006192:	0ce79a63          	bne	a5,a4,80006266 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80006196:	100017b7          	lui	a5,0x10001
    8000619a:	479c                	lw	a5,8(a5)
    8000619c:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    8000619e:	4709                	li	a4,2
    800061a0:	0ce79363          	bne	a5,a4,80006266 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    800061a4:	100017b7          	lui	a5,0x10001
    800061a8:	47d8                	lw	a4,12(a5)
    800061aa:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    800061ac:	554d47b7          	lui	a5,0x554d4
    800061b0:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    800061b4:	0af71963          	bne	a4,a5,80006266 <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    800061b8:	100017b7          	lui	a5,0x10001
    800061bc:	4705                	li	a4,1
    800061be:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800061c0:	470d                	li	a4,3
    800061c2:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    800061c4:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    800061c6:	c7ffe737          	lui	a4,0xc7ffe
    800061ca:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd875f>
    800061ce:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    800061d0:	2701                	sext.w	a4,a4
    800061d2:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800061d4:	472d                	li	a4,11
    800061d6:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800061d8:	473d                	li	a4,15
    800061da:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    800061dc:	6705                	lui	a4,0x1
    800061de:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    800061e0:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    800061e4:	5bdc                	lw	a5,52(a5)
    800061e6:	2781                	sext.w	a5,a5
  if(max == 0)
    800061e8:	c7d9                	beqz	a5,80006276 <virtio_disk_init+0x124>
  if(max < NUM)
    800061ea:	471d                	li	a4,7
    800061ec:	08f77d63          	bgeu	a4,a5,80006286 <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    800061f0:	100014b7          	lui	s1,0x10001
    800061f4:	47a1                	li	a5,8
    800061f6:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    800061f8:	6609                	lui	a2,0x2
    800061fa:	4581                	li	a1,0
    800061fc:	0001d517          	auipc	a0,0x1d
    80006200:	e0450513          	addi	a0,a0,-508 # 80023000 <disk>
    80006204:	ffffb097          	auipc	ra,0xffffb
    80006208:	adc080e7          	jalr	-1316(ra) # 80000ce0 <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    8000620c:	0001d717          	auipc	a4,0x1d
    80006210:	df470713          	addi	a4,a4,-524 # 80023000 <disk>
    80006214:	00c75793          	srli	a5,a4,0xc
    80006218:	2781                	sext.w	a5,a5
    8000621a:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    8000621c:	0001f797          	auipc	a5,0x1f
    80006220:	de478793          	addi	a5,a5,-540 # 80025000 <disk+0x2000>
    80006224:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    80006226:	0001d717          	auipc	a4,0x1d
    8000622a:	e5a70713          	addi	a4,a4,-422 # 80023080 <disk+0x80>
    8000622e:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    80006230:	0001e717          	auipc	a4,0x1e
    80006234:	dd070713          	addi	a4,a4,-560 # 80024000 <disk+0x1000>
    80006238:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    8000623a:	4705                	li	a4,1
    8000623c:	00e78c23          	sb	a4,24(a5)
    80006240:	00e78ca3          	sb	a4,25(a5)
    80006244:	00e78d23          	sb	a4,26(a5)
    80006248:	00e78da3          	sb	a4,27(a5)
    8000624c:	00e78e23          	sb	a4,28(a5)
    80006250:	00e78ea3          	sb	a4,29(a5)
    80006254:	00e78f23          	sb	a4,30(a5)
    80006258:	00e78fa3          	sb	a4,31(a5)
}
    8000625c:	60e2                	ld	ra,24(sp)
    8000625e:	6442                	ld	s0,16(sp)
    80006260:	64a2                	ld	s1,8(sp)
    80006262:	6105                	addi	sp,sp,32
    80006264:	8082                	ret
    panic("could not find virtio disk");
    80006266:	00002517          	auipc	a0,0x2
    8000626a:	55250513          	addi	a0,a0,1362 # 800087b8 <syscalls+0x360>
    8000626e:	ffffa097          	auipc	ra,0xffffa
    80006272:	2d0080e7          	jalr	720(ra) # 8000053e <panic>
    panic("virtio disk has no queue 0");
    80006276:	00002517          	auipc	a0,0x2
    8000627a:	56250513          	addi	a0,a0,1378 # 800087d8 <syscalls+0x380>
    8000627e:	ffffa097          	auipc	ra,0xffffa
    80006282:	2c0080e7          	jalr	704(ra) # 8000053e <panic>
    panic("virtio disk max queue too short");
    80006286:	00002517          	auipc	a0,0x2
    8000628a:	57250513          	addi	a0,a0,1394 # 800087f8 <syscalls+0x3a0>
    8000628e:	ffffa097          	auipc	ra,0xffffa
    80006292:	2b0080e7          	jalr	688(ra) # 8000053e <panic>

0000000080006296 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80006296:	7159                	addi	sp,sp,-112
    80006298:	f486                	sd	ra,104(sp)
    8000629a:	f0a2                	sd	s0,96(sp)
    8000629c:	eca6                	sd	s1,88(sp)
    8000629e:	e8ca                	sd	s2,80(sp)
    800062a0:	e4ce                	sd	s3,72(sp)
    800062a2:	e0d2                	sd	s4,64(sp)
    800062a4:	fc56                	sd	s5,56(sp)
    800062a6:	f85a                	sd	s6,48(sp)
    800062a8:	f45e                	sd	s7,40(sp)
    800062aa:	f062                	sd	s8,32(sp)
    800062ac:	ec66                	sd	s9,24(sp)
    800062ae:	e86a                	sd	s10,16(sp)
    800062b0:	1880                	addi	s0,sp,112
    800062b2:	892a                	mv	s2,a0
    800062b4:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    800062b6:	00c52c83          	lw	s9,12(a0)
    800062ba:	001c9c9b          	slliw	s9,s9,0x1
    800062be:	1c82                	slli	s9,s9,0x20
    800062c0:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    800062c4:	0001f517          	auipc	a0,0x1f
    800062c8:	e6450513          	addi	a0,a0,-412 # 80025128 <disk+0x2128>
    800062cc:	ffffb097          	auipc	ra,0xffffb
    800062d0:	918080e7          	jalr	-1768(ra) # 80000be4 <acquire>
  for(int i = 0; i < 3; i++){
    800062d4:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    800062d6:	4c21                	li	s8,8
      disk.free[i] = 0;
    800062d8:	0001db97          	auipc	s7,0x1d
    800062dc:	d28b8b93          	addi	s7,s7,-728 # 80023000 <disk>
    800062e0:	6b09                	lui	s6,0x2
  for(int i = 0; i < 3; i++){
    800062e2:	4a8d                	li	s5,3
  for(int i = 0; i < NUM; i++){
    800062e4:	8a4e                	mv	s4,s3
    800062e6:	a051                	j	8000636a <virtio_disk_rw+0xd4>
      disk.free[i] = 0;
    800062e8:	00fb86b3          	add	a3,s7,a5
    800062ec:	96da                	add	a3,a3,s6
    800062ee:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    800062f2:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    800062f4:	0207c563          	bltz	a5,8000631e <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    800062f8:	2485                	addiw	s1,s1,1
    800062fa:	0711                	addi	a4,a4,4
    800062fc:	25548063          	beq	s1,s5,8000653c <virtio_disk_rw+0x2a6>
    idx[i] = alloc_desc();
    80006300:	863a                	mv	a2,a4
  for(int i = 0; i < NUM; i++){
    80006302:	0001f697          	auipc	a3,0x1f
    80006306:	d1668693          	addi	a3,a3,-746 # 80025018 <disk+0x2018>
    8000630a:	87d2                	mv	a5,s4
    if(disk.free[i]){
    8000630c:	0006c583          	lbu	a1,0(a3)
    80006310:	fde1                	bnez	a1,800062e8 <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    80006312:	2785                	addiw	a5,a5,1
    80006314:	0685                	addi	a3,a3,1
    80006316:	ff879be3          	bne	a5,s8,8000630c <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    8000631a:	57fd                	li	a5,-1
    8000631c:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    8000631e:	02905a63          	blez	s1,80006352 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006322:	f9042503          	lw	a0,-112(s0)
    80006326:	00000097          	auipc	ra,0x0
    8000632a:	d90080e7          	jalr	-624(ra) # 800060b6 <free_desc>
      for(int j = 0; j < i; j++)
    8000632e:	4785                	li	a5,1
    80006330:	0297d163          	bge	a5,s1,80006352 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006334:	f9442503          	lw	a0,-108(s0)
    80006338:	00000097          	auipc	ra,0x0
    8000633c:	d7e080e7          	jalr	-642(ra) # 800060b6 <free_desc>
      for(int j = 0; j < i; j++)
    80006340:	4789                	li	a5,2
    80006342:	0097d863          	bge	a5,s1,80006352 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006346:	f9842503          	lw	a0,-104(s0)
    8000634a:	00000097          	auipc	ra,0x0
    8000634e:	d6c080e7          	jalr	-660(ra) # 800060b6 <free_desc>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006352:	0001f597          	auipc	a1,0x1f
    80006356:	dd658593          	addi	a1,a1,-554 # 80025128 <disk+0x2128>
    8000635a:	0001f517          	auipc	a0,0x1f
    8000635e:	cbe50513          	addi	a0,a0,-834 # 80025018 <disk+0x2018>
    80006362:	ffffc097          	auipc	ra,0xffffc
    80006366:	016080e7          	jalr	22(ra) # 80002378 <sleep>
  for(int i = 0; i < 3; i++){
    8000636a:	f9040713          	addi	a4,s0,-112
    8000636e:	84ce                	mv	s1,s3
    80006370:	bf41                	j	80006300 <virtio_disk_rw+0x6a>
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];

  if(write)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
    80006372:	20058713          	addi	a4,a1,512
    80006376:	00471693          	slli	a3,a4,0x4
    8000637a:	0001d717          	auipc	a4,0x1d
    8000637e:	c8670713          	addi	a4,a4,-890 # 80023000 <disk>
    80006382:	9736                	add	a4,a4,a3
    80006384:	4685                	li	a3,1
    80006386:	0ad72423          	sw	a3,168(a4)
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    8000638a:	20058713          	addi	a4,a1,512
    8000638e:	00471693          	slli	a3,a4,0x4
    80006392:	0001d717          	auipc	a4,0x1d
    80006396:	c6e70713          	addi	a4,a4,-914 # 80023000 <disk>
    8000639a:	9736                	add	a4,a4,a3
    8000639c:	0a072623          	sw	zero,172(a4)
  buf0->sector = sector;
    800063a0:	0b973823          	sd	s9,176(a4)

  disk.desc[idx[0]].addr = (uint64) buf0;
    800063a4:	7679                	lui	a2,0xffffe
    800063a6:	963e                	add	a2,a2,a5
    800063a8:	0001f697          	auipc	a3,0x1f
    800063ac:	c5868693          	addi	a3,a3,-936 # 80025000 <disk+0x2000>
    800063b0:	6298                	ld	a4,0(a3)
    800063b2:	9732                	add	a4,a4,a2
    800063b4:	e308                	sd	a0,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    800063b6:	6298                	ld	a4,0(a3)
    800063b8:	9732                	add	a4,a4,a2
    800063ba:	4541                	li	a0,16
    800063bc:	c708                	sw	a0,8(a4)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    800063be:	6298                	ld	a4,0(a3)
    800063c0:	9732                	add	a4,a4,a2
    800063c2:	4505                	li	a0,1
    800063c4:	00a71623          	sh	a0,12(a4)
  disk.desc[idx[0]].next = idx[1];
    800063c8:	f9442703          	lw	a4,-108(s0)
    800063cc:	6288                	ld	a0,0(a3)
    800063ce:	962a                	add	a2,a2,a0
    800063d0:	00e61723          	sh	a4,14(a2) # ffffffffffffe00e <end+0xffffffff7ffd800e>

  disk.desc[idx[1]].addr = (uint64) b->data;
    800063d4:	0712                	slli	a4,a4,0x4
    800063d6:	6290                	ld	a2,0(a3)
    800063d8:	963a                	add	a2,a2,a4
    800063da:	05890513          	addi	a0,s2,88
    800063de:	e208                	sd	a0,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    800063e0:	6294                	ld	a3,0(a3)
    800063e2:	96ba                	add	a3,a3,a4
    800063e4:	40000613          	li	a2,1024
    800063e8:	c690                	sw	a2,8(a3)
  if(write)
    800063ea:	140d0063          	beqz	s10,8000652a <virtio_disk_rw+0x294>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    800063ee:	0001f697          	auipc	a3,0x1f
    800063f2:	c126b683          	ld	a3,-1006(a3) # 80025000 <disk+0x2000>
    800063f6:	96ba                	add	a3,a3,a4
    800063f8:	00069623          	sh	zero,12(a3)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    800063fc:	0001d817          	auipc	a6,0x1d
    80006400:	c0480813          	addi	a6,a6,-1020 # 80023000 <disk>
    80006404:	0001f517          	auipc	a0,0x1f
    80006408:	bfc50513          	addi	a0,a0,-1028 # 80025000 <disk+0x2000>
    8000640c:	6114                	ld	a3,0(a0)
    8000640e:	96ba                	add	a3,a3,a4
    80006410:	00c6d603          	lhu	a2,12(a3)
    80006414:	00166613          	ori	a2,a2,1
    80006418:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    8000641c:	f9842683          	lw	a3,-104(s0)
    80006420:	6110                	ld	a2,0(a0)
    80006422:	9732                	add	a4,a4,a2
    80006424:	00d71723          	sh	a3,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80006428:	20058613          	addi	a2,a1,512
    8000642c:	0612                	slli	a2,a2,0x4
    8000642e:	9642                	add	a2,a2,a6
    80006430:	577d                	li	a4,-1
    80006432:	02e60823          	sb	a4,48(a2)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80006436:	00469713          	slli	a4,a3,0x4
    8000643a:	6114                	ld	a3,0(a0)
    8000643c:	96ba                	add	a3,a3,a4
    8000643e:	03078793          	addi	a5,a5,48
    80006442:	97c2                	add	a5,a5,a6
    80006444:	e29c                	sd	a5,0(a3)
  disk.desc[idx[2]].len = 1;
    80006446:	611c                	ld	a5,0(a0)
    80006448:	97ba                	add	a5,a5,a4
    8000644a:	4685                	li	a3,1
    8000644c:	c794                	sw	a3,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    8000644e:	611c                	ld	a5,0(a0)
    80006450:	97ba                	add	a5,a5,a4
    80006452:	4809                	li	a6,2
    80006454:	01079623          	sh	a6,12(a5)
  disk.desc[idx[2]].next = 0;
    80006458:	611c                	ld	a5,0(a0)
    8000645a:	973e                	add	a4,a4,a5
    8000645c:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80006460:	00d92223          	sw	a3,4(s2)
  disk.info[idx[0]].b = b;
    80006464:	03263423          	sd	s2,40(a2)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006468:	6518                	ld	a4,8(a0)
    8000646a:	00275783          	lhu	a5,2(a4)
    8000646e:	8b9d                	andi	a5,a5,7
    80006470:	0786                	slli	a5,a5,0x1
    80006472:	97ba                	add	a5,a5,a4
    80006474:	00b79223          	sh	a1,4(a5)

  __sync_synchronize();
    80006478:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    8000647c:	6518                	ld	a4,8(a0)
    8000647e:	00275783          	lhu	a5,2(a4)
    80006482:	2785                	addiw	a5,a5,1
    80006484:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006488:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    8000648c:	100017b7          	lui	a5,0x10001
    80006490:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006494:	00492703          	lw	a4,4(s2)
    80006498:	4785                	li	a5,1
    8000649a:	02f71163          	bne	a4,a5,800064bc <virtio_disk_rw+0x226>
    sleep(b, &disk.vdisk_lock);
    8000649e:	0001f997          	auipc	s3,0x1f
    800064a2:	c8a98993          	addi	s3,s3,-886 # 80025128 <disk+0x2128>
  while(b->disk == 1) {
    800064a6:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    800064a8:	85ce                	mv	a1,s3
    800064aa:	854a                	mv	a0,s2
    800064ac:	ffffc097          	auipc	ra,0xffffc
    800064b0:	ecc080e7          	jalr	-308(ra) # 80002378 <sleep>
  while(b->disk == 1) {
    800064b4:	00492783          	lw	a5,4(s2)
    800064b8:	fe9788e3          	beq	a5,s1,800064a8 <virtio_disk_rw+0x212>
  }

  disk.info[idx[0]].b = 0;
    800064bc:	f9042903          	lw	s2,-112(s0)
    800064c0:	20090793          	addi	a5,s2,512
    800064c4:	00479713          	slli	a4,a5,0x4
    800064c8:	0001d797          	auipc	a5,0x1d
    800064cc:	b3878793          	addi	a5,a5,-1224 # 80023000 <disk>
    800064d0:	97ba                	add	a5,a5,a4
    800064d2:	0207b423          	sd	zero,40(a5)
    int flag = disk.desc[i].flags;
    800064d6:	0001f997          	auipc	s3,0x1f
    800064da:	b2a98993          	addi	s3,s3,-1238 # 80025000 <disk+0x2000>
    800064de:	00491713          	slli	a4,s2,0x4
    800064e2:	0009b783          	ld	a5,0(s3)
    800064e6:	97ba                	add	a5,a5,a4
    800064e8:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    800064ec:	854a                	mv	a0,s2
    800064ee:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    800064f2:	00000097          	auipc	ra,0x0
    800064f6:	bc4080e7          	jalr	-1084(ra) # 800060b6 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    800064fa:	8885                	andi	s1,s1,1
    800064fc:	f0ed                	bnez	s1,800064de <virtio_disk_rw+0x248>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    800064fe:	0001f517          	auipc	a0,0x1f
    80006502:	c2a50513          	addi	a0,a0,-982 # 80025128 <disk+0x2128>
    80006506:	ffffa097          	auipc	ra,0xffffa
    8000650a:	792080e7          	jalr	1938(ra) # 80000c98 <release>
}
    8000650e:	70a6                	ld	ra,104(sp)
    80006510:	7406                	ld	s0,96(sp)
    80006512:	64e6                	ld	s1,88(sp)
    80006514:	6946                	ld	s2,80(sp)
    80006516:	69a6                	ld	s3,72(sp)
    80006518:	6a06                	ld	s4,64(sp)
    8000651a:	7ae2                	ld	s5,56(sp)
    8000651c:	7b42                	ld	s6,48(sp)
    8000651e:	7ba2                	ld	s7,40(sp)
    80006520:	7c02                	ld	s8,32(sp)
    80006522:	6ce2                	ld	s9,24(sp)
    80006524:	6d42                	ld	s10,16(sp)
    80006526:	6165                	addi	sp,sp,112
    80006528:	8082                	ret
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    8000652a:	0001f697          	auipc	a3,0x1f
    8000652e:	ad66b683          	ld	a3,-1322(a3) # 80025000 <disk+0x2000>
    80006532:	96ba                	add	a3,a3,a4
    80006534:	4609                	li	a2,2
    80006536:	00c69623          	sh	a2,12(a3)
    8000653a:	b5c9                	j	800063fc <virtio_disk_rw+0x166>
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    8000653c:	f9042583          	lw	a1,-112(s0)
    80006540:	20058793          	addi	a5,a1,512
    80006544:	0792                	slli	a5,a5,0x4
    80006546:	0001d517          	auipc	a0,0x1d
    8000654a:	b6250513          	addi	a0,a0,-1182 # 800230a8 <disk+0xa8>
    8000654e:	953e                	add	a0,a0,a5
  if(write)
    80006550:	e20d11e3          	bnez	s10,80006372 <virtio_disk_rw+0xdc>
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
    80006554:	20058713          	addi	a4,a1,512
    80006558:	00471693          	slli	a3,a4,0x4
    8000655c:	0001d717          	auipc	a4,0x1d
    80006560:	aa470713          	addi	a4,a4,-1372 # 80023000 <disk>
    80006564:	9736                	add	a4,a4,a3
    80006566:	0a072423          	sw	zero,168(a4)
    8000656a:	b505                	j	8000638a <virtio_disk_rw+0xf4>

000000008000656c <virtio_disk_intr>:

void
virtio_disk_intr()
{
    8000656c:	1101                	addi	sp,sp,-32
    8000656e:	ec06                	sd	ra,24(sp)
    80006570:	e822                	sd	s0,16(sp)
    80006572:	e426                	sd	s1,8(sp)
    80006574:	e04a                	sd	s2,0(sp)
    80006576:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80006578:	0001f517          	auipc	a0,0x1f
    8000657c:	bb050513          	addi	a0,a0,-1104 # 80025128 <disk+0x2128>
    80006580:	ffffa097          	auipc	ra,0xffffa
    80006584:	664080e7          	jalr	1636(ra) # 80000be4 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80006588:	10001737          	lui	a4,0x10001
    8000658c:	533c                	lw	a5,96(a4)
    8000658e:	8b8d                	andi	a5,a5,3
    80006590:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    80006592:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006596:	0001f797          	auipc	a5,0x1f
    8000659a:	a6a78793          	addi	a5,a5,-1430 # 80025000 <disk+0x2000>
    8000659e:	6b94                	ld	a3,16(a5)
    800065a0:	0207d703          	lhu	a4,32(a5)
    800065a4:	0026d783          	lhu	a5,2(a3)
    800065a8:	06f70163          	beq	a4,a5,8000660a <virtio_disk_intr+0x9e>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    800065ac:	0001d917          	auipc	s2,0x1d
    800065b0:	a5490913          	addi	s2,s2,-1452 # 80023000 <disk>
    800065b4:	0001f497          	auipc	s1,0x1f
    800065b8:	a4c48493          	addi	s1,s1,-1460 # 80025000 <disk+0x2000>
    __sync_synchronize();
    800065bc:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    800065c0:	6898                	ld	a4,16(s1)
    800065c2:	0204d783          	lhu	a5,32(s1)
    800065c6:	8b9d                	andi	a5,a5,7
    800065c8:	078e                	slli	a5,a5,0x3
    800065ca:	97ba                	add	a5,a5,a4
    800065cc:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    800065ce:	20078713          	addi	a4,a5,512
    800065d2:	0712                	slli	a4,a4,0x4
    800065d4:	974a                	add	a4,a4,s2
    800065d6:	03074703          	lbu	a4,48(a4) # 10001030 <_entry-0x6fffefd0>
    800065da:	e731                	bnez	a4,80006626 <virtio_disk_intr+0xba>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    800065dc:	20078793          	addi	a5,a5,512
    800065e0:	0792                	slli	a5,a5,0x4
    800065e2:	97ca                	add	a5,a5,s2
    800065e4:	7788                	ld	a0,40(a5)
    b->disk = 0;   // disk is done with buf
    800065e6:	00052223          	sw	zero,4(a0)
    wakeup(b);
    800065ea:	ffffc097          	auipc	ra,0xffffc
    800065ee:	f2e080e7          	jalr	-210(ra) # 80002518 <wakeup>

    disk.used_idx += 1;
    800065f2:	0204d783          	lhu	a5,32(s1)
    800065f6:	2785                	addiw	a5,a5,1
    800065f8:	17c2                	slli	a5,a5,0x30
    800065fa:	93c1                	srli	a5,a5,0x30
    800065fc:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006600:	6898                	ld	a4,16(s1)
    80006602:	00275703          	lhu	a4,2(a4)
    80006606:	faf71be3          	bne	a4,a5,800065bc <virtio_disk_intr+0x50>
  }

  release(&disk.vdisk_lock);
    8000660a:	0001f517          	auipc	a0,0x1f
    8000660e:	b1e50513          	addi	a0,a0,-1250 # 80025128 <disk+0x2128>
    80006612:	ffffa097          	auipc	ra,0xffffa
    80006616:	686080e7          	jalr	1670(ra) # 80000c98 <release>
}
    8000661a:	60e2                	ld	ra,24(sp)
    8000661c:	6442                	ld	s0,16(sp)
    8000661e:	64a2                	ld	s1,8(sp)
    80006620:	6902                	ld	s2,0(sp)
    80006622:	6105                	addi	sp,sp,32
    80006624:	8082                	ret
      panic("virtio_disk_intr status");
    80006626:	00002517          	auipc	a0,0x2
    8000662a:	1f250513          	addi	a0,a0,498 # 80008818 <syscalls+0x3c0>
    8000662e:	ffffa097          	auipc	ra,0xffffa
    80006632:	f10080e7          	jalr	-240(ra) # 8000053e <panic>
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
