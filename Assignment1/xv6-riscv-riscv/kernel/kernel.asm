
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	94013103          	ld	sp,-1728(sp) # 80008940 <_GLOBAL_OFFSET_TABLE_+0x8>
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
    80000068:	fbc78793          	addi	a5,a5,-68 # 80006020 <timervec>
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
    80000130:	7f2080e7          	jalr	2034(ra) # 8000291e <either_copyin>
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
    800001d8:	1ce080e7          	jalr	462(ra) # 800023a2 <sleep>
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
    80000214:	6b8080e7          	jalr	1720(ra) # 800028c8 <either_copyout>
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
    800002f6:	682080e7          	jalr	1666(ra) # 80002974 <procdump>
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
    8000044a:	0fc080e7          	jalr	252(ra) # 80002542 <wakeup>
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
    800008a4:	ca2080e7          	jalr	-862(ra) # 80002542 <wakeup>
    
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
    80000930:	a76080e7          	jalr	-1418(ra) # 800023a2 <sleep>
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
    80000ed8:	be0080e7          	jalr	-1056(ra) # 80002ab4 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000edc:	00005097          	auipc	ra,0x5
    80000ee0:	184080e7          	jalr	388(ra) # 80006060 <plicinithart>
  }

  scheduler();        
    80000ee4:	00001097          	auipc	ra,0x1
    80000ee8:	384080e7          	jalr	900(ra) # 80002268 <scheduler>
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
    80000f58:	b38080e7          	jalr	-1224(ra) # 80002a8c <trapinit>
    trapinithart();  // install kernel trap vector
    80000f5c:	00002097          	auipc	ra,0x2
    80000f60:	b58080e7          	jalr	-1192(ra) # 80002ab4 <trapinithart>
    plicinit();      // set up interrupt controller
    80000f64:	00005097          	auipc	ra,0x5
    80000f68:	0e6080e7          	jalr	230(ra) # 8000604a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f6c:	00005097          	auipc	ra,0x5
    80000f70:	0f4080e7          	jalr	244(ra) # 80006060 <plicinithart>
    binit();         // buffer cache
    80000f74:	00002097          	auipc	ra,0x2
    80000f78:	2d0080e7          	jalr	720(ra) # 80003244 <binit>
    iinit();         // inode table
    80000f7c:	00003097          	auipc	ra,0x3
    80000f80:	960080e7          	jalr	-1696(ra) # 800038dc <iinit>
    fileinit();      // file table
    80000f84:	00004097          	auipc	ra,0x4
    80000f88:	90a080e7          	jalr	-1782(ra) # 8000488e <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f8c:	00005097          	auipc	ra,0x5
    80000f90:	1f6080e7          	jalr	502(ra) # 80006182 <virtio_disk_init>
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
    80001a1c:	ed87a783          	lw	a5,-296(a5) # 800088f0 <first.1723>
    80001a20:	eb89                	bnez	a5,80001a32 <forkret+0x32>
        // be run from main().
        first = 0;
        fsinit(ROOTDEV);
    }

    usertrapret();
    80001a22:	00001097          	auipc	ra,0x1
    80001a26:	0aa080e7          	jalr	170(ra) # 80002acc <usertrapret>
}
    80001a2a:	60a2                	ld	ra,8(sp)
    80001a2c:	6402                	ld	s0,0(sp)
    80001a2e:	0141                	addi	sp,sp,16
    80001a30:	8082                	ret
        first = 0;
    80001a32:	00007797          	auipc	a5,0x7
    80001a36:	ea07af23          	sw	zero,-322(a5) # 800088f0 <first.1723>
        fsinit(ROOTDEV);
    80001a3a:	4505                	li	a0,1
    80001a3c:	00002097          	auipc	ra,0x2
    80001a40:	e20080e7          	jalr	-480(ra) # 8000385c <fsinit>
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
    80001a68:	e9078793          	addi	a5,a5,-368 # 800088f4 <nextpid>
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
    80001ce6:	c1e58593          	addi	a1,a1,-994 # 80008900 <initcode>
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
    80001d24:	56a080e7          	jalr	1386(ra) # 8000428a <namei>
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
    80001e66:	abe080e7          	jalr	-1346(ra) # 80004920 <filedup>
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
    80001e88:	c12080e7          	jalr	-1006(ra) # 80003a96 <idup>
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
    printf("--------------------------Default-----------------------------\n");
    80001f46:	00006517          	auipc	a0,0x6
    80001f4a:	2e250513          	addi	a0,a0,738 # 80008228 <digits+0x1e8>
    80001f4e:	ffffe097          	auipc	ra,0xffffe
    80001f52:	63a080e7          	jalr	1594(ra) # 80000588 <printf>
    c->proc = 0;
    80001f56:	00749c93          	slli	s9,s1,0x7
    80001f5a:	0000f797          	auipc	a5,0xf
    80001f5e:	36678793          	addi	a5,a5,870 # 800112c0 <pid_lock>
    80001f62:	97e6                	add	a5,a5,s9
    80001f64:	0207b823          	sd	zero,48(a5)
                swtch(&c->context, &p->context);
    80001f68:	0000f797          	auipc	a5,0xf
    80001f6c:	39078793          	addi	a5,a5,912 # 800112f8 <cpus+0x8>
    80001f70:	9cbe                	add	s9,s9,a5
            if (p->state == RUNNABLE && ticks >= pauseTicks) {
    80001f72:	00007b17          	auipc	s6,0x7
    80001f76:	0deb0b13          	addi	s6,s6,222 # 80009050 <ticks>
    80001f7a:	00007a97          	auipc	s5,0x7
    80001f7e:	0c6a8a93          	addi	s5,s5,198 # 80009040 <pauseTicks>
                c->proc = p;
    80001f82:	049e                	slli	s1,s1,0x7
    80001f84:	0000fb97          	auipc	s7,0xf
    80001f88:	33cb8b93          	addi	s7,s7,828 # 800112c0 <pid_lock>
    80001f8c:	9ba6                	add	s7,s7,s1
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001f8e:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001f92:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001f96:	10079073          	csrw	sstatus,a5
        for (p = proc; p < &proc[NPROC]; p++) {
    80001f9a:	0000f497          	auipc	s1,0xf
    80001f9e:	75648493          	addi	s1,s1,1878 # 800116f0 <proc>
            if (p->state == RUNNABLE && ticks >= pauseTicks) {
    80001fa2:	4a0d                	li	s4,3
                p->state = RUNNING;
    80001fa4:	4c11                	li	s8,4
        for (p = proc; p < &proc[NPROC]; p++) {
    80001fa6:	00016997          	auipc	s3,0x16
    80001faa:	94a98993          	addi	s3,s3,-1718 # 800178f0 <tickslock>
    80001fae:	a82d                	j	80001fe8 <defScheduler+0xd8>
                p->runnable_time = p->runnable_time + ticks - p->last_time_changed;
    80001fb0:	48b8                	lw	a4,80(s1)
    80001fb2:	9f3d                	addw	a4,a4,a5
    80001fb4:	4cb4                	lw	a3,88(s1)
    80001fb6:	9f15                	subw	a4,a4,a3
    80001fb8:	c8b8                	sw	a4,80(s1)
                p->last_time_changed = ticks;      //setting the starting ticks when getting to runnable for section 4
    80001fba:	ccbc                	sw	a5,88(s1)
                p->state = RUNNING;
    80001fbc:	0184ac23          	sw	s8,24(s1)
                c->proc = p;
    80001fc0:	029bb823          	sd	s1,48(s7)
                swtch(&c->context, &p->context);
    80001fc4:	08048593          	addi	a1,s1,128
    80001fc8:	8566                	mv	a0,s9
    80001fca:	00001097          	auipc	ra,0x1
    80001fce:	a58080e7          	jalr	-1448(ra) # 80002a22 <swtch>
                c->proc = 0;
    80001fd2:	020bb823          	sd	zero,48(s7)
            release(&p->lock);
    80001fd6:	8526                	mv	a0,s1
    80001fd8:	fffff097          	auipc	ra,0xfffff
    80001fdc:	cc0080e7          	jalr	-832(ra) # 80000c98 <release>
        for (p = proc; p < &proc[NPROC]; p++) {
    80001fe0:	18848493          	addi	s1,s1,392
    80001fe4:	fb3485e3          	beq	s1,s3,80001f8e <defScheduler+0x7e>
            acquire(&p->lock);
    80001fe8:	8526                	mv	a0,s1
    80001fea:	fffff097          	auipc	ra,0xfffff
    80001fee:	bfa080e7          	jalr	-1030(ra) # 80000be4 <acquire>
            if (p->state == RUNNABLE && ticks >= pauseTicks) {
    80001ff2:	4c9c                	lw	a5,24(s1)
    80001ff4:	ff4791e3          	bne	a5,s4,80001fd6 <defScheduler+0xc6>
    80001ff8:	000b2783          	lw	a5,0(s6)
    80001ffc:	000aa703          	lw	a4,0(s5)
    80002000:	fce7ebe3          	bltu	a5,a4,80001fd6 <defScheduler+0xc6>
    80002004:	b775                	j	80001fb0 <defScheduler+0xa0>

0000000080002006 <sjfScheduler>:
void sjfScheduler(void) { //todo where do we calculate the mean and where to init with 0
    80002006:	711d                	addi	sp,sp,-96
    80002008:	ec86                	sd	ra,88(sp)
    8000200a:	e8a2                	sd	s0,80(sp)
    8000200c:	e4a6                	sd	s1,72(sp)
    8000200e:	e0ca                	sd	s2,64(sp)
    80002010:	fc4e                	sd	s3,56(sp)
    80002012:	f852                	sd	s4,48(sp)
    80002014:	f456                	sd	s5,40(sp)
    80002016:	f05a                	sd	s6,32(sp)
    80002018:	ec5e                	sd	s7,24(sp)
    8000201a:	e862                	sd	s8,16(sp)
    8000201c:	e466                	sd	s9,8(sp)
    8000201e:	e06a                	sd	s10,0(sp)
    80002020:	1080                	addi	s0,sp,96
  asm volatile("mv %0, tp" : "=r" (x) );
    80002022:	8492                	mv	s1,tp
    int id = r_tp();
    80002024:	2481                	sext.w	s1,s1
    printf("--------------------------SJF-----------------------------\n");
    80002026:	00006517          	auipc	a0,0x6
    8000202a:	24250513          	addi	a0,a0,578 # 80008268 <digits+0x228>
    8000202e:	ffffe097          	auipc	ra,0xffffe
    80002032:	55a080e7          	jalr	1370(ra) # 80000588 <printf>
    c->proc = 0;
    80002036:	00749c93          	slli	s9,s1,0x7
    8000203a:	0000f797          	auipc	a5,0xf
    8000203e:	28678793          	addi	a5,a5,646 # 800112c0 <pid_lock>
    80002042:	97e6                	add	a5,a5,s9
    80002044:	0207b823          	sd	zero,48(a5)
            swtch(&c->context, &min_proc->context);
    80002048:	0000f797          	auipc	a5,0xf
    8000204c:	2b078793          	addi	a5,a5,688 # 800112f8 <cpus+0x8>
    80002050:	9cbe                	add	s9,s9,a5
        struct proc *min_proc = proc;
    80002052:	0000fa97          	auipc	s5,0xf
    80002056:	69ea8a93          	addi	s5,s5,1694 # 800116f0 <proc>
            if (p->state == RUNNABLE && p->mean_ticks <= min_proc->mean_ticks)
    8000205a:	490d                	li	s2,3
        for (p = proc; p < &proc[NPROC]; p++) {
    8000205c:	00016997          	auipc	s3,0x16
    80002060:	89498993          	addi	s3,s3,-1900 # 800178f0 <tickslock>
        if (min_proc->state == RUNNABLE && ticks >= pauseTicks) {
    80002064:	00007b17          	auipc	s6,0x7
    80002068:	fecb0b13          	addi	s6,s6,-20 # 80009050 <ticks>
    8000206c:	00007c17          	auipc	s8,0x7
    80002070:	fd4c0c13          	addi	s8,s8,-44 # 80009040 <pauseTicks>
            c->proc = min_proc;
    80002074:	049e                	slli	s1,s1,0x7
    80002076:	0000fb97          	auipc	s7,0xf
    8000207a:	24ab8b93          	addi	s7,s7,586 # 800112c0 <pid_lock>
    8000207e:	9ba6                	add	s7,s7,s1
    80002080:	a0c1                	j	80002140 <sjfScheduler+0x13a>
            release(&p->lock);
    80002082:	8526                	mv	a0,s1
    80002084:	fffff097          	auipc	ra,0xfffff
    80002088:	c14080e7          	jalr	-1004(ra) # 80000c98 <release>
        for (p = proc; p < &proc[NPROC]; p++) {
    8000208c:	18848493          	addi	s1,s1,392
    80002090:	03348163          	beq	s1,s3,800020b2 <sjfScheduler+0xac>
            acquire(&p->lock);
    80002094:	8526                	mv	a0,s1
    80002096:	fffff097          	auipc	ra,0xfffff
    8000209a:	b4e080e7          	jalr	-1202(ra) # 80000be4 <acquire>
            if (p->state == RUNNABLE && p->mean_ticks <= min_proc->mean_ticks)
    8000209e:	4c9c                	lw	a5,24(s1)
    800020a0:	ff2791e3          	bne	a5,s2,80002082 <sjfScheduler+0x7c>
    800020a4:	40b8                	lw	a4,64(s1)
    800020a6:	040a2783          	lw	a5,64(s4)
    800020aa:	fce7cce3          	blt	a5,a4,80002082 <sjfScheduler+0x7c>
    800020ae:	8a26                	mv	s4,s1
    800020b0:	bfc9                	j	80002082 <sjfScheduler+0x7c>
        acquire(&min_proc->lock);
    800020b2:	84d2                	mv	s1,s4
    800020b4:	8552                	mv	a0,s4
    800020b6:	fffff097          	auipc	ra,0xfffff
    800020ba:	b2e080e7          	jalr	-1234(ra) # 80000be4 <acquire>
        if (min_proc->state == RUNNABLE && ticks >= pauseTicks) {
    800020be:	018a2783          	lw	a5,24(s4)
    800020c2:	07279a63          	bne	a5,s2,80002136 <sjfScheduler+0x130>
    800020c6:	000b2d03          	lw	s10,0(s6)
    800020ca:	000c2783          	lw	a5,0(s8)
    800020ce:	06fd6463          	bltu	s10,a5,80002136 <sjfScheduler+0x130>
            min_proc->runnable_time = min_proc->runnable_time + ticks - min_proc->last_time_changed;
    800020d2:	050a2783          	lw	a5,80(s4)
    800020d6:	01a787bb          	addw	a5,a5,s10
    800020da:	058a2703          	lw	a4,88(s4)
    800020de:	9f99                	subw	a5,a5,a4
    800020e0:	04fa2823          	sw	a5,80(s4)
            min_proc->last_time_changed = ticks;      //setting the starting ticks when getting to runnable for section 4
    800020e4:	05aa2c23          	sw	s10,88(s4)
            min_proc->state = RUNNING;
    800020e8:	4791                	li	a5,4
    800020ea:	00fa2c23          	sw	a5,24(s4)
            c->proc = min_proc;
    800020ee:	034bb823          	sd	s4,48(s7)
            swtch(&c->context, &min_proc->context);
    800020f2:	080a0593          	addi	a1,s4,128
    800020f6:	8566                	mv	a0,s9
    800020f8:	00001097          	auipc	ra,0x1
    800020fc:	92a080e7          	jalr	-1750(ra) # 80002a22 <swtch>
            min_proc->last_ticks = ticks - startingTicks;
    80002100:	000b2783          	lw	a5,0(s6)
    80002104:	41a78d3b          	subw	s10,a5,s10
    80002108:	05aa2223          	sw	s10,68(s4)
            min_proc->mean_ticks = ((10 - rate) * min_proc->mean_ticks + min_proc->last_ticks * (rate)) / 10;
    8000210c:	00006697          	auipc	a3,0x6
    80002110:	7ec6a683          	lw	a3,2028(a3) # 800088f8 <rate>
    80002114:	4729                	li	a4,10
    80002116:	40d707bb          	subw	a5,a4,a3
    8000211a:	040a2603          	lw	a2,64(s4)
    8000211e:	02c787bb          	mulw	a5,a5,a2
    80002122:	02dd0d3b          	mulw	s10,s10,a3
    80002126:	01a787bb          	addw	a5,a5,s10
    8000212a:	02e7c7bb          	divw	a5,a5,a4
    8000212e:	04fa2023          	sw	a5,64(s4)
            c->proc = 0;
    80002132:	020bb823          	sd	zero,48(s7)
        release(&min_proc->lock);
    80002136:	8526                	mv	a0,s1
    80002138:	fffff097          	auipc	ra,0xfffff
    8000213c:	b60080e7          	jalr	-1184(ra) # 80000c98 <release>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002140:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002144:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002148:	10079073          	csrw	sstatus,a5
        struct proc *min_proc = proc;
    8000214c:	8a56                	mv	s4,s5
        for (p = proc; p < &proc[NPROC]; p++) {
    8000214e:	84d6                	mv	s1,s5
    80002150:	b791                	j	80002094 <sjfScheduler+0x8e>

0000000080002152 <fcfsScheduler>:
void fcfsScheduler(void) {
    80002152:	711d                	addi	sp,sp,-96
    80002154:	ec86                	sd	ra,88(sp)
    80002156:	e8a2                	sd	s0,80(sp)
    80002158:	e4a6                	sd	s1,72(sp)
    8000215a:	e0ca                	sd	s2,64(sp)
    8000215c:	fc4e                	sd	s3,56(sp)
    8000215e:	f852                	sd	s4,48(sp)
    80002160:	f456                	sd	s5,40(sp)
    80002162:	f05a                	sd	s6,32(sp)
    80002164:	ec5e                	sd	s7,24(sp)
    80002166:	e862                	sd	s8,16(sp)
    80002168:	e466                	sd	s9,8(sp)
    8000216a:	1080                	addi	s0,sp,96
  asm volatile("mv %0, tp" : "=r" (x) );
    8000216c:	8492                	mv	s1,tp
    int id = r_tp();
    8000216e:	2481                	sext.w	s1,s1
    printf("--------------------------FCFS-----------------------------\n");
    80002170:	00006517          	auipc	a0,0x6
    80002174:	13850513          	addi	a0,a0,312 # 800082a8 <digits+0x268>
    80002178:	ffffe097          	auipc	ra,0xffffe
    8000217c:	410080e7          	jalr	1040(ra) # 80000588 <printf>
    c->proc = 0;
    80002180:	00749c93          	slli	s9,s1,0x7
    80002184:	0000f797          	auipc	a5,0xf
    80002188:	13c78793          	addi	a5,a5,316 # 800112c0 <pid_lock>
    8000218c:	97e6                	add	a5,a5,s9
    8000218e:	0207b823          	sd	zero,48(a5)
                swtch(&c->context, &min_lrt_proc->context);
    80002192:	0000f797          	auipc	a5,0xf
    80002196:	16678793          	addi	a5,a5,358 # 800112f8 <cpus+0x8>
    8000219a:	9cbe                	add	s9,s9,a5
            struct proc *min_lrt_proc = proc; // lrt = last runnable time
    8000219c:	0000fa97          	auipc	s5,0xf
    800021a0:	554a8a93          	addi	s5,s5,1364 # 800116f0 <proc>
                if (p->state == RUNNABLE && p->last_runnable_time <= min_lrt_proc->last_runnable_time)
    800021a4:	490d                	li	s2,3
            for (p = proc; p < &proc[NPROC]; p++) {
    800021a6:	00015997          	auipc	s3,0x15
    800021aa:	74a98993          	addi	s3,s3,1866 # 800178f0 <tickslock>
            if(min_lrt_proc->state == RUNNABLE && ticks >= pauseTicks) {
    800021ae:	00007c17          	auipc	s8,0x7
    800021b2:	ea2c0c13          	addi	s8,s8,-350 # 80009050 <ticks>
    800021b6:	00007b97          	auipc	s7,0x7
    800021ba:	e8ab8b93          	addi	s7,s7,-374 # 80009040 <pauseTicks>
                c->proc = min_lrt_proc;
    800021be:	049e                	slli	s1,s1,0x7
    800021c0:	0000fb17          	auipc	s6,0xf
    800021c4:	100b0b13          	addi	s6,s6,256 # 800112c0 <pid_lock>
    800021c8:	9b26                	add	s6,s6,s1
    800021ca:	a071                	j	80002256 <fcfsScheduler+0x104>
                release(&p->lock);
    800021cc:	8526                	mv	a0,s1
    800021ce:	fffff097          	auipc	ra,0xfffff
    800021d2:	aca080e7          	jalr	-1334(ra) # 80000c98 <release>
            for (p = proc; p < &proc[NPROC]; p++) {
    800021d6:	18848493          	addi	s1,s1,392
    800021da:	03348163          	beq	s1,s3,800021fc <fcfsScheduler+0xaa>
                acquire(&p->lock);
    800021de:	8526                	mv	a0,s1
    800021e0:	fffff097          	auipc	ra,0xfffff
    800021e4:	a04080e7          	jalr	-1532(ra) # 80000be4 <acquire>
                if (p->state == RUNNABLE && p->last_runnable_time <= min_lrt_proc->last_runnable_time)
    800021e8:	4c9c                	lw	a5,24(s1)
    800021ea:	ff2791e3          	bne	a5,s2,800021cc <fcfsScheduler+0x7a>
    800021ee:	44b8                	lw	a4,72(s1)
    800021f0:	048a2783          	lw	a5,72(s4)
    800021f4:	fce7cce3          	blt	a5,a4,800021cc <fcfsScheduler+0x7a>
    800021f8:	8a26                	mv	s4,s1
    800021fa:	bfc9                	j	800021cc <fcfsScheduler+0x7a>
            acquire(&min_lrt_proc->lock);
    800021fc:	84d2                	mv	s1,s4
    800021fe:	8552                	mv	a0,s4
    80002200:	fffff097          	auipc	ra,0xfffff
    80002204:	9e4080e7          	jalr	-1564(ra) # 80000be4 <acquire>
            if(min_lrt_proc->state == RUNNABLE && ticks >= pauseTicks) {
    80002208:	018a2783          	lw	a5,24(s4)
    8000220c:	05279063          	bne	a5,s2,8000224c <fcfsScheduler+0xfa>
    80002210:	000c2783          	lw	a5,0(s8)
    80002214:	000ba703          	lw	a4,0(s7)
    80002218:	02e7ea63          	bltu	a5,a4,8000224c <fcfsScheduler+0xfa>
                min_lrt_proc->runnable_time = min_lrt_proc->runnable_time + ticks - min_lrt_proc->last_time_changed;
    8000221c:	050a2703          	lw	a4,80(s4)
    80002220:	9f3d                	addw	a4,a4,a5
    80002222:	058a2683          	lw	a3,88(s4)
    80002226:	9f15                	subw	a4,a4,a3
    80002228:	04ea2823          	sw	a4,80(s4)
                min_lrt_proc->last_time_changed = ticks;      //setting the starting ticks when getting to runnable for section 4
    8000222c:	04fa2c23          	sw	a5,88(s4)
                min_lrt_proc->state = RUNNING;
    80002230:	4791                	li	a5,4
    80002232:	00fa2c23          	sw	a5,24(s4)
                c->proc = min_lrt_proc;
    80002236:	034b3823          	sd	s4,48(s6)
                swtch(&c->context, &min_lrt_proc->context);
    8000223a:	080a0593          	addi	a1,s4,128
    8000223e:	8566                	mv	a0,s9
    80002240:	00000097          	auipc	ra,0x0
    80002244:	7e2080e7          	jalr	2018(ra) # 80002a22 <swtch>
                c->proc = 0;
    80002248:	020b3823          	sd	zero,48(s6)
            release(&min_lrt_proc->lock);
    8000224c:	8526                	mv	a0,s1
    8000224e:	fffff097          	auipc	ra,0xfffff
    80002252:	a4a080e7          	jalr	-1462(ra) # 80000c98 <release>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002256:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    8000225a:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000225e:	10079073          	csrw	sstatus,a5
            struct proc *min_lrt_proc = proc; // lrt = last runnable time
    80002262:	8a56                	mv	s4,s5
            for (p = proc; p < &proc[NPROC]; p++) {
    80002264:	84d6                	mv	s1,s5
    80002266:	bfa5                	j	800021de <fcfsScheduler+0x8c>

0000000080002268 <scheduler>:
scheduler(void) {
    80002268:	1141                	addi	sp,sp,-16
    8000226a:	e406                	sd	ra,8(sp)
    8000226c:	e022                	sd	s0,0(sp)
    8000226e:	0800                	addi	s0,sp,16
        sjfScheduler();
    80002270:	00000097          	auipc	ra,0x0
    80002274:	d96080e7          	jalr	-618(ra) # 80002006 <sjfScheduler>

0000000080002278 <sched>:
sched(void) {
    80002278:	7179                	addi	sp,sp,-48
    8000227a:	f406                	sd	ra,40(sp)
    8000227c:	f022                	sd	s0,32(sp)
    8000227e:	ec26                	sd	s1,24(sp)
    80002280:	e84a                	sd	s2,16(sp)
    80002282:	e44e                	sd	s3,8(sp)
    80002284:	1800                	addi	s0,sp,48
    struct proc *p = myproc();
    80002286:	fffff097          	auipc	ra,0xfffff
    8000228a:	742080e7          	jalr	1858(ra) # 800019c8 <myproc>
    8000228e:	84aa                	mv	s1,a0
    if (!holding(&p->lock))
    80002290:	fffff097          	auipc	ra,0xfffff
    80002294:	8da080e7          	jalr	-1830(ra) # 80000b6a <holding>
    80002298:	c93d                	beqz	a0,8000230e <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    8000229a:	8792                	mv	a5,tp
    if (mycpu()->noff != 1)
    8000229c:	2781                	sext.w	a5,a5
    8000229e:	079e                	slli	a5,a5,0x7
    800022a0:	0000f717          	auipc	a4,0xf
    800022a4:	02070713          	addi	a4,a4,32 # 800112c0 <pid_lock>
    800022a8:	97ba                	add	a5,a5,a4
    800022aa:	0a87a703          	lw	a4,168(a5)
    800022ae:	4785                	li	a5,1
    800022b0:	06f71763          	bne	a4,a5,8000231e <sched+0xa6>
    if (p->state == RUNNING)
    800022b4:	4c98                	lw	a4,24(s1)
    800022b6:	4791                	li	a5,4
    800022b8:	06f70b63          	beq	a4,a5,8000232e <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800022bc:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    800022c0:	8b89                	andi	a5,a5,2
    if (intr_get())
    800022c2:	efb5                	bnez	a5,8000233e <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    800022c4:	8792                	mv	a5,tp
    intena = mycpu()->intena;
    800022c6:	0000f917          	auipc	s2,0xf
    800022ca:	ffa90913          	addi	s2,s2,-6 # 800112c0 <pid_lock>
    800022ce:	2781                	sext.w	a5,a5
    800022d0:	079e                	slli	a5,a5,0x7
    800022d2:	97ca                	add	a5,a5,s2
    800022d4:	0ac7a983          	lw	s3,172(a5)
    800022d8:	8792                	mv	a5,tp
    swtch(&p->context, &mycpu()->context);
    800022da:	2781                	sext.w	a5,a5
    800022dc:	079e                	slli	a5,a5,0x7
    800022de:	0000f597          	auipc	a1,0xf
    800022e2:	01a58593          	addi	a1,a1,26 # 800112f8 <cpus+0x8>
    800022e6:	95be                	add	a1,a1,a5
    800022e8:	08048513          	addi	a0,s1,128
    800022ec:	00000097          	auipc	ra,0x0
    800022f0:	736080e7          	jalr	1846(ra) # 80002a22 <swtch>
    800022f4:	8792                	mv	a5,tp
    mycpu()->intena = intena;
    800022f6:	2781                	sext.w	a5,a5
    800022f8:	079e                	slli	a5,a5,0x7
    800022fa:	97ca                	add	a5,a5,s2
    800022fc:	0b37a623          	sw	s3,172(a5)
}
    80002300:	70a2                	ld	ra,40(sp)
    80002302:	7402                	ld	s0,32(sp)
    80002304:	64e2                	ld	s1,24(sp)
    80002306:	6942                	ld	s2,16(sp)
    80002308:	69a2                	ld	s3,8(sp)
    8000230a:	6145                	addi	sp,sp,48
    8000230c:	8082                	ret
        panic("sched p->lock");
    8000230e:	00006517          	auipc	a0,0x6
    80002312:	fda50513          	addi	a0,a0,-38 # 800082e8 <digits+0x2a8>
    80002316:	ffffe097          	auipc	ra,0xffffe
    8000231a:	228080e7          	jalr	552(ra) # 8000053e <panic>
        panic("sched locks");
    8000231e:	00006517          	auipc	a0,0x6
    80002322:	fda50513          	addi	a0,a0,-38 # 800082f8 <digits+0x2b8>
    80002326:	ffffe097          	auipc	ra,0xffffe
    8000232a:	218080e7          	jalr	536(ra) # 8000053e <panic>
        panic("sched running");
    8000232e:	00006517          	auipc	a0,0x6
    80002332:	fda50513          	addi	a0,a0,-38 # 80008308 <digits+0x2c8>
    80002336:	ffffe097          	auipc	ra,0xffffe
    8000233a:	208080e7          	jalr	520(ra) # 8000053e <panic>
        panic("sched interruptible");
    8000233e:	00006517          	auipc	a0,0x6
    80002342:	fda50513          	addi	a0,a0,-38 # 80008318 <digits+0x2d8>
    80002346:	ffffe097          	auipc	ra,0xffffe
    8000234a:	1f8080e7          	jalr	504(ra) # 8000053e <panic>

000000008000234e <yield>:
yield(void) {
    8000234e:	1101                	addi	sp,sp,-32
    80002350:	ec06                	sd	ra,24(sp)
    80002352:	e822                	sd	s0,16(sp)
    80002354:	e426                	sd	s1,8(sp)
    80002356:	1000                	addi	s0,sp,32
    struct proc *p = myproc();
    80002358:	fffff097          	auipc	ra,0xfffff
    8000235c:	670080e7          	jalr	1648(ra) # 800019c8 <myproc>
    80002360:	84aa                	mv	s1,a0
    acquire(&p->lock);
    80002362:	fffff097          	auipc	ra,0xfffff
    80002366:	882080e7          	jalr	-1918(ra) # 80000be4 <acquire>
    p->state = RUNNABLE;
    8000236a:	478d                	li	a5,3
    8000236c:	cc9c                	sw	a5,24(s1)
    p->running_time = p->running_time + (ticks - p->last_time_changed);
    8000236e:	00007797          	auipc	a5,0x7
    80002372:	ce27a783          	lw	a5,-798(a5) # 80009050 <ticks>
    80002376:	48f8                	lw	a4,84(s1)
    80002378:	9f3d                	addw	a4,a4,a5
    8000237a:	4cb4                	lw	a3,88(s1)
    8000237c:	9f15                	subw	a4,a4,a3
    8000237e:	c8f8                	sw	a4,84(s1)
    p->last_runnable_time = ticks;     //added last_runnable time for fcfs
    80002380:	2781                	sext.w	a5,a5
    80002382:	c4bc                	sw	a5,72(s1)
    p->last_time_changed = ticks;      //setting the starting ticks when getting to runnable for section 4
    80002384:	ccbc                	sw	a5,88(s1)
    sched();
    80002386:	00000097          	auipc	ra,0x0
    8000238a:	ef2080e7          	jalr	-270(ra) # 80002278 <sched>
    release(&p->lock);
    8000238e:	8526                	mv	a0,s1
    80002390:	fffff097          	auipc	ra,0xfffff
    80002394:	908080e7          	jalr	-1784(ra) # 80000c98 <release>
}
    80002398:	60e2                	ld	ra,24(sp)
    8000239a:	6442                	ld	s0,16(sp)
    8000239c:	64a2                	ld	s1,8(sp)
    8000239e:	6105                	addi	sp,sp,32
    800023a0:	8082                	ret

00000000800023a2 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk) {
    800023a2:	7179                	addi	sp,sp,-48
    800023a4:	f406                	sd	ra,40(sp)
    800023a6:	f022                	sd	s0,32(sp)
    800023a8:	ec26                	sd	s1,24(sp)
    800023aa:	e84a                	sd	s2,16(sp)
    800023ac:	e44e                	sd	s3,8(sp)
    800023ae:	1800                	addi	s0,sp,48
    800023b0:	89aa                	mv	s3,a0
    800023b2:	892e                	mv	s2,a1
    struct proc *p = myproc();
    800023b4:	fffff097          	auipc	ra,0xfffff
    800023b8:	614080e7          	jalr	1556(ra) # 800019c8 <myproc>
    800023bc:	84aa                	mv	s1,a0
    // Once we hold p->lock, we can be
    // guaranteed that we won't miss any wakeup
    // (wakeup locks p->lock),
    // so it's okay to release lk.

    acquire(&p->lock);  //DOC: sleeplock1
    800023be:	fffff097          	auipc	ra,0xfffff
    800023c2:	826080e7          	jalr	-2010(ra) # 80000be4 <acquire>
    release(lk);
    800023c6:	854a                	mv	a0,s2
    800023c8:	fffff097          	auipc	ra,0xfffff
    800023cc:	8d0080e7          	jalr	-1840(ra) # 80000c98 <release>


    p->running_time = p->running_time + ticks - p->last_time_changed;
    800023d0:	00007717          	auipc	a4,0x7
    800023d4:	c8072703          	lw	a4,-896(a4) # 80009050 <ticks>
    800023d8:	48fc                	lw	a5,84(s1)
    800023da:	9fb9                	addw	a5,a5,a4
    800023dc:	4cb4                	lw	a3,88(s1)
    800023de:	9f95                	subw	a5,a5,a3
    800023e0:	c8fc                	sw	a5,84(s1)
    p->last_time_changed = ticks;      //setting the starting ticks when getting to runnable for section 4
    800023e2:	ccb8                	sw	a4,88(s1)

    // Go to sleep.
    p->chan = chan;
    800023e4:	0334b023          	sd	s3,32(s1)
    p->state = SLEEPING;
    800023e8:	4789                	li	a5,2
    800023ea:	cc9c                	sw	a5,24(s1)

    sched();
    800023ec:	00000097          	auipc	ra,0x0
    800023f0:	e8c080e7          	jalr	-372(ra) # 80002278 <sched>

    // Tidy up.
    p->chan = 0;
    800023f4:	0204b023          	sd	zero,32(s1)

    // Reacquire original lock.
    release(&p->lock);
    800023f8:	8526                	mv	a0,s1
    800023fa:	fffff097          	auipc	ra,0xfffff
    800023fe:	89e080e7          	jalr	-1890(ra) # 80000c98 <release>
    acquire(lk);
    80002402:	854a                	mv	a0,s2
    80002404:	ffffe097          	auipc	ra,0xffffe
    80002408:	7e0080e7          	jalr	2016(ra) # 80000be4 <acquire>
}
    8000240c:	70a2                	ld	ra,40(sp)
    8000240e:	7402                	ld	s0,32(sp)
    80002410:	64e2                	ld	s1,24(sp)
    80002412:	6942                	ld	s2,16(sp)
    80002414:	69a2                	ld	s3,8(sp)
    80002416:	6145                	addi	sp,sp,48
    80002418:	8082                	ret

000000008000241a <wait>:
wait(uint64 addr) {
    8000241a:	715d                	addi	sp,sp,-80
    8000241c:	e486                	sd	ra,72(sp)
    8000241e:	e0a2                	sd	s0,64(sp)
    80002420:	fc26                	sd	s1,56(sp)
    80002422:	f84a                	sd	s2,48(sp)
    80002424:	f44e                	sd	s3,40(sp)
    80002426:	f052                	sd	s4,32(sp)
    80002428:	ec56                	sd	s5,24(sp)
    8000242a:	e85a                	sd	s6,16(sp)
    8000242c:	e45e                	sd	s7,8(sp)
    8000242e:	e062                	sd	s8,0(sp)
    80002430:	0880                	addi	s0,sp,80
    80002432:	8b2a                	mv	s6,a0
    struct proc *p = myproc();
    80002434:	fffff097          	auipc	ra,0xfffff
    80002438:	594080e7          	jalr	1428(ra) # 800019c8 <myproc>
    8000243c:	892a                	mv	s2,a0
    acquire(&wait_lock);
    8000243e:	0000f517          	auipc	a0,0xf
    80002442:	e9a50513          	addi	a0,a0,-358 # 800112d8 <wait_lock>
    80002446:	ffffe097          	auipc	ra,0xffffe
    8000244a:	79e080e7          	jalr	1950(ra) # 80000be4 <acquire>
        havekids = 0;
    8000244e:	4b81                	li	s7,0
                if (np->state == ZOMBIE) {
    80002450:	4a15                	li	s4,5
        for (np = proc; np < &proc[NPROC]; np++) {
    80002452:	00015997          	auipc	s3,0x15
    80002456:	49e98993          	addi	s3,s3,1182 # 800178f0 <tickslock>
                havekids = 1;
    8000245a:	4a85                	li	s5,1
        sleep(p, &wait_lock);  //DOC: wait-sleep
    8000245c:	0000fc17          	auipc	s8,0xf
    80002460:	e7cc0c13          	addi	s8,s8,-388 # 800112d8 <wait_lock>
        havekids = 0;
    80002464:	875e                	mv	a4,s7
        for (np = proc; np < &proc[NPROC]; np++) {
    80002466:	0000f497          	auipc	s1,0xf
    8000246a:	28a48493          	addi	s1,s1,650 # 800116f0 <proc>
    8000246e:	a0bd                	j	800024dc <wait+0xc2>
                    pid = np->pid;
    80002470:	0304a983          	lw	s3,48(s1)
                    if (addr != 0 && copyout(p->pagetable, addr, (char *) &np->xstate,
    80002474:	000b0e63          	beqz	s6,80002490 <wait+0x76>
    80002478:	4691                	li	a3,4
    8000247a:	02c48613          	addi	a2,s1,44
    8000247e:	85da                	mv	a1,s6
    80002480:	07093503          	ld	a0,112(s2)
    80002484:	fffff097          	auipc	ra,0xfffff
    80002488:	1f6080e7          	jalr	502(ra) # 8000167a <copyout>
    8000248c:	02054563          	bltz	a0,800024b6 <wait+0x9c>
                    freeproc(np);
    80002490:	8526                	mv	a0,s1
    80002492:	fffff097          	auipc	ra,0xfffff
    80002496:	6e8080e7          	jalr	1768(ra) # 80001b7a <freeproc>
                    release(&np->lock);
    8000249a:	8526                	mv	a0,s1
    8000249c:	ffffe097          	auipc	ra,0xffffe
    800024a0:	7fc080e7          	jalr	2044(ra) # 80000c98 <release>
                    release(&wait_lock);
    800024a4:	0000f517          	auipc	a0,0xf
    800024a8:	e3450513          	addi	a0,a0,-460 # 800112d8 <wait_lock>
    800024ac:	ffffe097          	auipc	ra,0xffffe
    800024b0:	7ec080e7          	jalr	2028(ra) # 80000c98 <release>
                    return pid;
    800024b4:	a09d                	j	8000251a <wait+0x100>
                        release(&np->lock);
    800024b6:	8526                	mv	a0,s1
    800024b8:	ffffe097          	auipc	ra,0xffffe
    800024bc:	7e0080e7          	jalr	2016(ra) # 80000c98 <release>
                        release(&wait_lock);
    800024c0:	0000f517          	auipc	a0,0xf
    800024c4:	e1850513          	addi	a0,a0,-488 # 800112d8 <wait_lock>
    800024c8:	ffffe097          	auipc	ra,0xffffe
    800024cc:	7d0080e7          	jalr	2000(ra) # 80000c98 <release>
                        return -1;
    800024d0:	59fd                	li	s3,-1
    800024d2:	a0a1                	j	8000251a <wait+0x100>
        for (np = proc; np < &proc[NPROC]; np++) {
    800024d4:	18848493          	addi	s1,s1,392
    800024d8:	03348463          	beq	s1,s3,80002500 <wait+0xe6>
            if (np->parent == p) {
    800024dc:	7c9c                	ld	a5,56(s1)
    800024de:	ff279be3          	bne	a5,s2,800024d4 <wait+0xba>
                acquire(&np->lock);
    800024e2:	8526                	mv	a0,s1
    800024e4:	ffffe097          	auipc	ra,0xffffe
    800024e8:	700080e7          	jalr	1792(ra) # 80000be4 <acquire>
                if (np->state == ZOMBIE) {
    800024ec:	4c9c                	lw	a5,24(s1)
    800024ee:	f94781e3          	beq	a5,s4,80002470 <wait+0x56>
                release(&np->lock);
    800024f2:	8526                	mv	a0,s1
    800024f4:	ffffe097          	auipc	ra,0xffffe
    800024f8:	7a4080e7          	jalr	1956(ra) # 80000c98 <release>
                havekids = 1;
    800024fc:	8756                	mv	a4,s5
    800024fe:	bfd9                	j	800024d4 <wait+0xba>
        if (!havekids || p->killed) {
    80002500:	c701                	beqz	a4,80002508 <wait+0xee>
    80002502:	02892783          	lw	a5,40(s2)
    80002506:	c79d                	beqz	a5,80002534 <wait+0x11a>
            release(&wait_lock);
    80002508:	0000f517          	auipc	a0,0xf
    8000250c:	dd050513          	addi	a0,a0,-560 # 800112d8 <wait_lock>
    80002510:	ffffe097          	auipc	ra,0xffffe
    80002514:	788080e7          	jalr	1928(ra) # 80000c98 <release>
            return -1;
    80002518:	59fd                	li	s3,-1
}
    8000251a:	854e                	mv	a0,s3
    8000251c:	60a6                	ld	ra,72(sp)
    8000251e:	6406                	ld	s0,64(sp)
    80002520:	74e2                	ld	s1,56(sp)
    80002522:	7942                	ld	s2,48(sp)
    80002524:	79a2                	ld	s3,40(sp)
    80002526:	7a02                	ld	s4,32(sp)
    80002528:	6ae2                	ld	s5,24(sp)
    8000252a:	6b42                	ld	s6,16(sp)
    8000252c:	6ba2                	ld	s7,8(sp)
    8000252e:	6c02                	ld	s8,0(sp)
    80002530:	6161                	addi	sp,sp,80
    80002532:	8082                	ret
        sleep(p, &wait_lock);  //DOC: wait-sleep
    80002534:	85e2                	mv	a1,s8
    80002536:	854a                	mv	a0,s2
    80002538:	00000097          	auipc	ra,0x0
    8000253c:	e6a080e7          	jalr	-406(ra) # 800023a2 <sleep>
        havekids = 0;
    80002540:	b715                	j	80002464 <wait+0x4a>

0000000080002542 <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void
wakeup(void *chan) {
    80002542:	7139                	addi	sp,sp,-64
    80002544:	fc06                	sd	ra,56(sp)
    80002546:	f822                	sd	s0,48(sp)
    80002548:	f426                	sd	s1,40(sp)
    8000254a:	f04a                	sd	s2,32(sp)
    8000254c:	ec4e                	sd	s3,24(sp)
    8000254e:	e852                	sd	s4,16(sp)
    80002550:	e456                	sd	s5,8(sp)
    80002552:	e05a                	sd	s6,0(sp)
    80002554:	0080                	addi	s0,sp,64
    80002556:	8a2a                	mv	s4,a0
    struct proc *p;

    for (p = proc; p < &proc[NPROC]; p++) {
    80002558:	0000f497          	auipc	s1,0xf
    8000255c:	19848493          	addi	s1,s1,408 # 800116f0 <proc>
        if (p != myproc()) {
            acquire(&p->lock);
            if (p->state == SLEEPING && p->chan == chan) {
    80002560:	4989                	li	s3,2
                p->state = RUNNABLE;
    80002562:	4b0d                	li	s6,3

                p->sleeping_time = p->sleeping_time + ticks - p->last_time_changed;
    80002564:	00007a97          	auipc	s5,0x7
    80002568:	aeca8a93          	addi	s5,s5,-1300 # 80009050 <ticks>
    for (p = proc; p < &proc[NPROC]; p++) {
    8000256c:	00015917          	auipc	s2,0x15
    80002570:	38490913          	addi	s2,s2,900 # 800178f0 <tickslock>
    80002574:	a035                	j	800025a0 <wakeup+0x5e>
                p->state = RUNNABLE;
    80002576:	0164ac23          	sw	s6,24(s1)
                p->sleeping_time = p->sleeping_time + ticks - p->last_time_changed;
    8000257a:	000aa783          	lw	a5,0(s5)
    8000257e:	44f8                	lw	a4,76(s1)
    80002580:	9f3d                	addw	a4,a4,a5
    80002582:	4cb4                	lw	a3,88(s1)
    80002584:	9f15                	subw	a4,a4,a3
    80002586:	c4f8                	sw	a4,76(s1)
                p->last_runnable_time = ticks;     //added last_runnable time for fcfs
    80002588:	2781                	sext.w	a5,a5
    8000258a:	c4bc                	sw	a5,72(s1)
                p->last_time_changed = ticks;      //setting the starting ticks when getting to runnable for section 4
    8000258c:	ccbc                	sw	a5,88(s1)

            }
            release(&p->lock);
    8000258e:	8526                	mv	a0,s1
    80002590:	ffffe097          	auipc	ra,0xffffe
    80002594:	708080e7          	jalr	1800(ra) # 80000c98 <release>
    for (p = proc; p < &proc[NPROC]; p++) {
    80002598:	18848493          	addi	s1,s1,392
    8000259c:	03248463          	beq	s1,s2,800025c4 <wakeup+0x82>
        if (p != myproc()) {
    800025a0:	fffff097          	auipc	ra,0xfffff
    800025a4:	428080e7          	jalr	1064(ra) # 800019c8 <myproc>
    800025a8:	fea488e3          	beq	s1,a0,80002598 <wakeup+0x56>
            acquire(&p->lock);
    800025ac:	8526                	mv	a0,s1
    800025ae:	ffffe097          	auipc	ra,0xffffe
    800025b2:	636080e7          	jalr	1590(ra) # 80000be4 <acquire>
            if (p->state == SLEEPING && p->chan == chan) {
    800025b6:	4c9c                	lw	a5,24(s1)
    800025b8:	fd379be3          	bne	a5,s3,8000258e <wakeup+0x4c>
    800025bc:	709c                	ld	a5,32(s1)
    800025be:	fd4798e3          	bne	a5,s4,8000258e <wakeup+0x4c>
    800025c2:	bf55                	j	80002576 <wakeup+0x34>
        }
    }
}
    800025c4:	70e2                	ld	ra,56(sp)
    800025c6:	7442                	ld	s0,48(sp)
    800025c8:	74a2                	ld	s1,40(sp)
    800025ca:	7902                	ld	s2,32(sp)
    800025cc:	69e2                	ld	s3,24(sp)
    800025ce:	6a42                	ld	s4,16(sp)
    800025d0:	6aa2                	ld	s5,8(sp)
    800025d2:	6b02                	ld	s6,0(sp)
    800025d4:	6121                	addi	sp,sp,64
    800025d6:	8082                	ret

00000000800025d8 <reparent>:
reparent(struct proc *p) {
    800025d8:	7179                	addi	sp,sp,-48
    800025da:	f406                	sd	ra,40(sp)
    800025dc:	f022                	sd	s0,32(sp)
    800025de:	ec26                	sd	s1,24(sp)
    800025e0:	e84a                	sd	s2,16(sp)
    800025e2:	e44e                	sd	s3,8(sp)
    800025e4:	e052                	sd	s4,0(sp)
    800025e6:	1800                	addi	s0,sp,48
    800025e8:	892a                	mv	s2,a0
    for (pp = proc; pp < &proc[NPROC]; pp++) {
    800025ea:	0000f497          	auipc	s1,0xf
    800025ee:	10648493          	addi	s1,s1,262 # 800116f0 <proc>
            pp->parent = initproc;
    800025f2:	00007a17          	auipc	s4,0x7
    800025f6:	a56a0a13          	addi	s4,s4,-1450 # 80009048 <initproc>
    for (pp = proc; pp < &proc[NPROC]; pp++) {
    800025fa:	00015997          	auipc	s3,0x15
    800025fe:	2f698993          	addi	s3,s3,758 # 800178f0 <tickslock>
    80002602:	a029                	j	8000260c <reparent+0x34>
    80002604:	18848493          	addi	s1,s1,392
    80002608:	01348d63          	beq	s1,s3,80002622 <reparent+0x4a>
        if (pp->parent == p) {
    8000260c:	7c9c                	ld	a5,56(s1)
    8000260e:	ff279be3          	bne	a5,s2,80002604 <reparent+0x2c>
            pp->parent = initproc;
    80002612:	000a3503          	ld	a0,0(s4)
    80002616:	fc88                	sd	a0,56(s1)
            wakeup(initproc);
    80002618:	00000097          	auipc	ra,0x0
    8000261c:	f2a080e7          	jalr	-214(ra) # 80002542 <wakeup>
    80002620:	b7d5                	j	80002604 <reparent+0x2c>
}
    80002622:	70a2                	ld	ra,40(sp)
    80002624:	7402                	ld	s0,32(sp)
    80002626:	64e2                	ld	s1,24(sp)
    80002628:	6942                	ld	s2,16(sp)
    8000262a:	69a2                	ld	s3,8(sp)
    8000262c:	6a02                	ld	s4,0(sp)
    8000262e:	6145                	addi	sp,sp,48
    80002630:	8082                	ret

0000000080002632 <exit>:
exit(int status) {
    80002632:	7179                	addi	sp,sp,-48
    80002634:	f406                	sd	ra,40(sp)
    80002636:	f022                	sd	s0,32(sp)
    80002638:	ec26                	sd	s1,24(sp)
    8000263a:	e84a                	sd	s2,16(sp)
    8000263c:	e44e                	sd	s3,8(sp)
    8000263e:	e052                	sd	s4,0(sp)
    80002640:	1800                	addi	s0,sp,48
    80002642:	8a2a                	mv	s4,a0
    struct proc *p = myproc();
    80002644:	fffff097          	auipc	ra,0xfffff
    80002648:	384080e7          	jalr	900(ra) # 800019c8 <myproc>
    8000264c:	892a                	mv	s2,a0
    if (p == initproc)
    8000264e:	00007797          	auipc	a5,0x7
    80002652:	9fa7b783          	ld	a5,-1542(a5) # 80009048 <initproc>
    80002656:	0f050493          	addi	s1,a0,240
    8000265a:	17050993          	addi	s3,a0,368
    8000265e:	02a79363          	bne	a5,a0,80002684 <exit+0x52>
        panic("init exiting");
    80002662:	00006517          	auipc	a0,0x6
    80002666:	cce50513          	addi	a0,a0,-818 # 80008330 <digits+0x2f0>
    8000266a:	ffffe097          	auipc	ra,0xffffe
    8000266e:	ed4080e7          	jalr	-300(ra) # 8000053e <panic>
            fileclose(f);
    80002672:	00002097          	auipc	ra,0x2
    80002676:	300080e7          	jalr	768(ra) # 80004972 <fileclose>
            p->ofile[fd] = 0;
    8000267a:	0004b023          	sd	zero,0(s1)
    for (int fd = 0; fd < NOFILE; fd++) {
    8000267e:	04a1                	addi	s1,s1,8
    80002680:	01348563          	beq	s1,s3,8000268a <exit+0x58>
        if (p->ofile[fd]) {
    80002684:	6088                	ld	a0,0(s1)
    80002686:	f575                	bnez	a0,80002672 <exit+0x40>
    80002688:	bfdd                	j	8000267e <exit+0x4c>
    begin_op();
    8000268a:	00002097          	auipc	ra,0x2
    8000268e:	e1c080e7          	jalr	-484(ra) # 800044a6 <begin_op>
    iput(p->cwd);
    80002692:	17093503          	ld	a0,368(s2)
    80002696:	00001097          	auipc	ra,0x1
    8000269a:	5f8080e7          	jalr	1528(ra) # 80003c8e <iput>
    end_op();
    8000269e:	00002097          	auipc	ra,0x2
    800026a2:	e88080e7          	jalr	-376(ra) # 80004526 <end_op>
    p->cwd = 0;
    800026a6:	16093823          	sd	zero,368(s2)
    acquire(&wait_lock);
    800026aa:	0000f497          	auipc	s1,0xf
    800026ae:	c2e48493          	addi	s1,s1,-978 # 800112d8 <wait_lock>
    800026b2:	8526                	mv	a0,s1
    800026b4:	ffffe097          	auipc	ra,0xffffe
    800026b8:	530080e7          	jalr	1328(ra) # 80000be4 <acquire>
    reparent(p);
    800026bc:	854a                	mv	a0,s2
    800026be:	00000097          	auipc	ra,0x0
    800026c2:	f1a080e7          	jalr	-230(ra) # 800025d8 <reparent>
    wakeup(p->parent);
    800026c6:	03893503          	ld	a0,56(s2)
    800026ca:	00000097          	auipc	ra,0x0
    800026ce:	e78080e7          	jalr	-392(ra) # 80002542 <wakeup>
    acquire(&p->lock);
    800026d2:	854a                	mv	a0,s2
    800026d4:	ffffe097          	auipc	ra,0xffffe
    800026d8:	510080e7          	jalr	1296(ra) # 80000be4 <acquire>
    p->running_time = p->running_time + ticks - p->last_time_changed;
    800026dc:	00007617          	auipc	a2,0x7
    800026e0:	97462603          	lw	a2,-1676(a2) # 80009050 <ticks>
    800026e4:	05492703          	lw	a4,84(s2)
    800026e8:	9f31                	addw	a4,a4,a2
    800026ea:	05892683          	lw	a3,88(s2)
    800026ee:	40d706bb          	subw	a3,a4,a3
    800026f2:	04d92a23          	sw	a3,84(s2)
    program_time = program_time + p->running_time;
    800026f6:	00007717          	auipc	a4,0x7
    800026fa:	93a70713          	addi	a4,a4,-1734 # 80009030 <program_time>
    800026fe:	431c                	lw	a5,0(a4)
    80002700:	9fb5                	addw	a5,a5,a3
    80002702:	c31c                	sw	a5,0(a4)
    cpu_utilization = program_time / (ticks - start_time);
    80002704:	00007717          	auipc	a4,0x7
    80002708:	92472703          	lw	a4,-1756(a4) # 80009028 <start_time>
    8000270c:	9e19                	subw	a2,a2,a4
    8000270e:	02c7d7bb          	divuw	a5,a5,a2
    80002712:	00007717          	auipc	a4,0x7
    80002716:	90f72d23          	sw	a5,-1766(a4) # 8000902c <cpu_utilization>
    sleeping_processes_mean = (sleeping_processes_mean * (nextpid - 1) + p->sleeping_time) / (nextpid);
    8000271a:	00006617          	auipc	a2,0x6
    8000271e:	1da62603          	lw	a2,474(a2) # 800088f4 <nextpid>
    80002722:	fff6059b          	addiw	a1,a2,-1
    80002726:	00007797          	auipc	a5,0x7
    8000272a:	91678793          	addi	a5,a5,-1770 # 8000903c <sleeping_processes_mean>
    8000272e:	4398                	lw	a4,0(a5)
    80002730:	02b7073b          	mulw	a4,a4,a1
    80002734:	04c92503          	lw	a0,76(s2)
    80002738:	9f29                	addw	a4,a4,a0
    8000273a:	02c7473b          	divw	a4,a4,a2
    8000273e:	c398                	sw	a4,0(a5)
    running_processes_mean = (running_processes_mean * (nextpid - 1) + p->running_time) / (nextpid);
    80002740:	00007797          	auipc	a5,0x7
    80002744:	8f878793          	addi	a5,a5,-1800 # 80009038 <running_processes_mean>
    80002748:	4398                	lw	a4,0(a5)
    8000274a:	02b7073b          	mulw	a4,a4,a1
    8000274e:	9f35                	addw	a4,a4,a3
    80002750:	02c7473b          	divw	a4,a4,a2
    80002754:	c398                	sw	a4,0(a5)
    runnable_processes_mean = (runnable_processes_mean * (nextpid - 1) + p->runnable_time) / (nextpid);
    80002756:	00007717          	auipc	a4,0x7
    8000275a:	8de70713          	addi	a4,a4,-1826 # 80009034 <runnable_processes_mean>
    8000275e:	431c                	lw	a5,0(a4)
    80002760:	02b787bb          	mulw	a5,a5,a1
    80002764:	05092683          	lw	a3,80(s2)
    80002768:	9fb5                	addw	a5,a5,a3
    8000276a:	02c7c7bb          	divw	a5,a5,a2
    8000276e:	c31c                	sw	a5,0(a4)
    p->xstate = status;
    80002770:	03492623          	sw	s4,44(s2)
    p->state = ZOMBIE;
    80002774:	4795                	li	a5,5
    80002776:	00f92c23          	sw	a5,24(s2)
    release(&wait_lock);
    8000277a:	8526                	mv	a0,s1
    8000277c:	ffffe097          	auipc	ra,0xffffe
    80002780:	51c080e7          	jalr	1308(ra) # 80000c98 <release>
    sched();
    80002784:	00000097          	auipc	ra,0x0
    80002788:	af4080e7          	jalr	-1292(ra) # 80002278 <sched>
    panic("zombie exit");
    8000278c:	00006517          	auipc	a0,0x6
    80002790:	bb450513          	addi	a0,a0,-1100 # 80008340 <digits+0x300>
    80002794:	ffffe097          	auipc	ra,0xffffe
    80002798:	daa080e7          	jalr	-598(ra) # 8000053e <panic>

000000008000279c <kill>:

// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid) {
    8000279c:	7179                	addi	sp,sp,-48
    8000279e:	f406                	sd	ra,40(sp)
    800027a0:	f022                	sd	s0,32(sp)
    800027a2:	ec26                	sd	s1,24(sp)
    800027a4:	e84a                	sd	s2,16(sp)
    800027a6:	e44e                	sd	s3,8(sp)
    800027a8:	1800                	addi	s0,sp,48
    800027aa:	892a                	mv	s2,a0
    struct proc *p;

    for (p = proc; p < &proc[NPROC]; p++) {
    800027ac:	0000f497          	auipc	s1,0xf
    800027b0:	f4448493          	addi	s1,s1,-188 # 800116f0 <proc>
    800027b4:	00015997          	auipc	s3,0x15
    800027b8:	13c98993          	addi	s3,s3,316 # 800178f0 <tickslock>
        acquire(&p->lock);
    800027bc:	8526                	mv	a0,s1
    800027be:	ffffe097          	auipc	ra,0xffffe
    800027c2:	426080e7          	jalr	1062(ra) # 80000be4 <acquire>
        if (p->pid == pid) {
    800027c6:	589c                	lw	a5,48(s1)
    800027c8:	01278d63          	beq	a5,s2,800027e2 <kill+0x46>
                p->last_time_changed = ticks;      //setting the starting ticks when getting to runnable for section 4
            }
            release(&p->lock);
            return 0;
        }
        release(&p->lock);
    800027cc:	8526                	mv	a0,s1
    800027ce:	ffffe097          	auipc	ra,0xffffe
    800027d2:	4ca080e7          	jalr	1226(ra) # 80000c98 <release>
    for (p = proc; p < &proc[NPROC]; p++) {
    800027d6:	18848493          	addi	s1,s1,392
    800027da:	ff3491e3          	bne	s1,s3,800027bc <kill+0x20>
    }
    return -1;
    800027de:	557d                	li	a0,-1
    800027e0:	a829                	j	800027fa <kill+0x5e>
            p->killed = 1;
    800027e2:	4785                	li	a5,1
    800027e4:	d49c                	sw	a5,40(s1)
            if (p->state == SLEEPING) {
    800027e6:	4c98                	lw	a4,24(s1)
    800027e8:	4789                	li	a5,2
    800027ea:	00f70f63          	beq	a4,a5,80002808 <kill+0x6c>
            release(&p->lock);
    800027ee:	8526                	mv	a0,s1
    800027f0:	ffffe097          	auipc	ra,0xffffe
    800027f4:	4a8080e7          	jalr	1192(ra) # 80000c98 <release>
            return 0;
    800027f8:	4501                	li	a0,0
}
    800027fa:	70a2                	ld	ra,40(sp)
    800027fc:	7402                	ld	s0,32(sp)
    800027fe:	64e2                	ld	s1,24(sp)
    80002800:	6942                	ld	s2,16(sp)
    80002802:	69a2                	ld	s3,8(sp)
    80002804:	6145                	addi	sp,sp,48
    80002806:	8082                	ret
                p->state = RUNNABLE;
    80002808:	478d                	li	a5,3
    8000280a:	cc9c                	sw	a5,24(s1)
                p->sleeping_time = p->sleeping_time + ticks - p->last_time_changed;
    8000280c:	00007797          	auipc	a5,0x7
    80002810:	8447a783          	lw	a5,-1980(a5) # 80009050 <ticks>
    80002814:	44f8                	lw	a4,76(s1)
    80002816:	9f3d                	addw	a4,a4,a5
    80002818:	4cb4                	lw	a3,88(s1)
    8000281a:	9f15                	subw	a4,a4,a3
    8000281c:	c4f8                	sw	a4,76(s1)
                p->last_runnable_time = ticks;     //added last_runnable time for fcfs
    8000281e:	2781                	sext.w	a5,a5
    80002820:	c4bc                	sw	a5,72(s1)
                p->last_time_changed = ticks;      //setting the starting ticks when getting to runnable for section 4
    80002822:	ccbc                	sw	a5,88(s1)
    80002824:	b7e9                	j	800027ee <kill+0x52>

0000000080002826 <kill_system>:

int kill_system(void) {
    80002826:	7179                	addi	sp,sp,-48
    80002828:	f406                	sd	ra,40(sp)
    8000282a:	f022                	sd	s0,32(sp)
    8000282c:	ec26                	sd	s1,24(sp)
    8000282e:	e84a                	sd	s2,16(sp)
    80002830:	e44e                	sd	s3,8(sp)
    80002832:	1800                	addi	s0,sp,48
    // init pid = 1
    // shell pid = 2
    struct proc *p;
    int i = 0;
    for (p = proc; p < &proc[NPROC]; p++, i++) {
    80002834:	0000f497          	auipc	s1,0xf
    80002838:	ebc48493          	addi	s1,s1,-324 # 800116f0 <proc>
        acquire(&p->lock);
        if (p->pid != 1 && p->pid != 2) {
    8000283c:	4985                	li	s3,1
    for (p = proc; p < &proc[NPROC]; p++, i++) {
    8000283e:	00015917          	auipc	s2,0x15
    80002842:	0b290913          	addi	s2,s2,178 # 800178f0 <tickslock>
    80002846:	a811                	j	8000285a <kill_system+0x34>
            release(&p->lock);
            kill(p->pid);
        } else {
            release(&p->lock);
    80002848:	8526                	mv	a0,s1
    8000284a:	ffffe097          	auipc	ra,0xffffe
    8000284e:	44e080e7          	jalr	1102(ra) # 80000c98 <release>
    for (p = proc; p < &proc[NPROC]; p++, i++) {
    80002852:	18848493          	addi	s1,s1,392
    80002856:	03248663          	beq	s1,s2,80002882 <kill_system+0x5c>
        acquire(&p->lock);
    8000285a:	8526                	mv	a0,s1
    8000285c:	ffffe097          	auipc	ra,0xffffe
    80002860:	388080e7          	jalr	904(ra) # 80000be4 <acquire>
        if (p->pid != 1 && p->pid != 2) {
    80002864:	589c                	lw	a5,48(s1)
    80002866:	37fd                	addiw	a5,a5,-1
    80002868:	fef9f0e3          	bgeu	s3,a5,80002848 <kill_system+0x22>
            release(&p->lock);
    8000286c:	8526                	mv	a0,s1
    8000286e:	ffffe097          	auipc	ra,0xffffe
    80002872:	42a080e7          	jalr	1066(ra) # 80000c98 <release>
            kill(p->pid);
    80002876:	5888                	lw	a0,48(s1)
    80002878:	00000097          	auipc	ra,0x0
    8000287c:	f24080e7          	jalr	-220(ra) # 8000279c <kill>
    80002880:	bfc9                	j	80002852 <kill_system+0x2c>
        }
    }

    return 0;
    //todo check if need to verify kill returned 0, in case not what should we do.
}
    80002882:	4501                	li	a0,0
    80002884:	70a2                	ld	ra,40(sp)
    80002886:	7402                	ld	s0,32(sp)
    80002888:	64e2                	ld	s1,24(sp)
    8000288a:	6942                	ld	s2,16(sp)
    8000288c:	69a2                	ld	s3,8(sp)
    8000288e:	6145                	addi	sp,sp,48
    80002890:	8082                	ret

0000000080002892 <pause_system>:

//pause all user processes for the number of seconds specified by the parameter
int pause_system(int seconds) {
    80002892:	1141                	addi	sp,sp,-16
    80002894:	e406                	sd	ra,8(sp)
    80002896:	e022                	sd	s0,0(sp)
    80002898:	0800                	addi	s0,sp,16
    pauseTicks = ticks + seconds * 10; //todo check if can get 1000000 as number
    8000289a:	0025179b          	slliw	a5,a0,0x2
    8000289e:	9fa9                	addw	a5,a5,a0
    800028a0:	0017979b          	slliw	a5,a5,0x1
    800028a4:	00006517          	auipc	a0,0x6
    800028a8:	7ac52503          	lw	a0,1964(a0) # 80009050 <ticks>
    800028ac:	9fa9                	addw	a5,a5,a0
    800028ae:	00006717          	auipc	a4,0x6
    800028b2:	78f72923          	sw	a5,1938(a4) # 80009040 <pauseTicks>
    yield();
    800028b6:	00000097          	auipc	ra,0x0
    800028ba:	a98080e7          	jalr	-1384(ra) # 8000234e <yield>
    return 0;
}
    800028be:	4501                	li	a0,0
    800028c0:	60a2                	ld	ra,8(sp)
    800028c2:	6402                	ld	s0,0(sp)
    800028c4:	0141                	addi	sp,sp,16
    800028c6:	8082                	ret

00000000800028c8 <either_copyout>:

// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len) {
    800028c8:	7179                	addi	sp,sp,-48
    800028ca:	f406                	sd	ra,40(sp)
    800028cc:	f022                	sd	s0,32(sp)
    800028ce:	ec26                	sd	s1,24(sp)
    800028d0:	e84a                	sd	s2,16(sp)
    800028d2:	e44e                	sd	s3,8(sp)
    800028d4:	e052                	sd	s4,0(sp)
    800028d6:	1800                	addi	s0,sp,48
    800028d8:	84aa                	mv	s1,a0
    800028da:	892e                	mv	s2,a1
    800028dc:	89b2                	mv	s3,a2
    800028de:	8a36                	mv	s4,a3
    struct proc *p = myproc();
    800028e0:	fffff097          	auipc	ra,0xfffff
    800028e4:	0e8080e7          	jalr	232(ra) # 800019c8 <myproc>
    if (user_dst) {
    800028e8:	c08d                	beqz	s1,8000290a <either_copyout+0x42>
        return copyout(p->pagetable, dst, src, len);
    800028ea:	86d2                	mv	a3,s4
    800028ec:	864e                	mv	a2,s3
    800028ee:	85ca                	mv	a1,s2
    800028f0:	7928                	ld	a0,112(a0)
    800028f2:	fffff097          	auipc	ra,0xfffff
    800028f6:	d88080e7          	jalr	-632(ra) # 8000167a <copyout>
    } else {
        memmove((char *) dst, src, len);
        return 0;
    }
}
    800028fa:	70a2                	ld	ra,40(sp)
    800028fc:	7402                	ld	s0,32(sp)
    800028fe:	64e2                	ld	s1,24(sp)
    80002900:	6942                	ld	s2,16(sp)
    80002902:	69a2                	ld	s3,8(sp)
    80002904:	6a02                	ld	s4,0(sp)
    80002906:	6145                	addi	sp,sp,48
    80002908:	8082                	ret
        memmove((char *) dst, src, len);
    8000290a:	000a061b          	sext.w	a2,s4
    8000290e:	85ce                	mv	a1,s3
    80002910:	854a                	mv	a0,s2
    80002912:	ffffe097          	auipc	ra,0xffffe
    80002916:	42e080e7          	jalr	1070(ra) # 80000d40 <memmove>
        return 0;
    8000291a:	8526                	mv	a0,s1
    8000291c:	bff9                	j	800028fa <either_copyout+0x32>

000000008000291e <either_copyin>:

// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len) {
    8000291e:	7179                	addi	sp,sp,-48
    80002920:	f406                	sd	ra,40(sp)
    80002922:	f022                	sd	s0,32(sp)
    80002924:	ec26                	sd	s1,24(sp)
    80002926:	e84a                	sd	s2,16(sp)
    80002928:	e44e                	sd	s3,8(sp)
    8000292a:	e052                	sd	s4,0(sp)
    8000292c:	1800                	addi	s0,sp,48
    8000292e:	892a                	mv	s2,a0
    80002930:	84ae                	mv	s1,a1
    80002932:	89b2                	mv	s3,a2
    80002934:	8a36                	mv	s4,a3
    struct proc *p = myproc();
    80002936:	fffff097          	auipc	ra,0xfffff
    8000293a:	092080e7          	jalr	146(ra) # 800019c8 <myproc>
    if (user_src) {
    8000293e:	c08d                	beqz	s1,80002960 <either_copyin+0x42>
        return copyin(p->pagetable, dst, src, len);
    80002940:	86d2                	mv	a3,s4
    80002942:	864e                	mv	a2,s3
    80002944:	85ca                	mv	a1,s2
    80002946:	7928                	ld	a0,112(a0)
    80002948:	fffff097          	auipc	ra,0xfffff
    8000294c:	dbe080e7          	jalr	-578(ra) # 80001706 <copyin>
    } else {
        memmove(dst, (char *) src, len);
        return 0;
    }
}
    80002950:	70a2                	ld	ra,40(sp)
    80002952:	7402                	ld	s0,32(sp)
    80002954:	64e2                	ld	s1,24(sp)
    80002956:	6942                	ld	s2,16(sp)
    80002958:	69a2                	ld	s3,8(sp)
    8000295a:	6a02                	ld	s4,0(sp)
    8000295c:	6145                	addi	sp,sp,48
    8000295e:	8082                	ret
        memmove(dst, (char *) src, len);
    80002960:	000a061b          	sext.w	a2,s4
    80002964:	85ce                	mv	a1,s3
    80002966:	854a                	mv	a0,s2
    80002968:	ffffe097          	auipc	ra,0xffffe
    8000296c:	3d8080e7          	jalr	984(ra) # 80000d40 <memmove>
        return 0;
    80002970:	8526                	mv	a0,s1
    80002972:	bff9                	j	80002950 <either_copyin+0x32>

0000000080002974 <procdump>:

// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void) {
    80002974:	715d                	addi	sp,sp,-80
    80002976:	e486                	sd	ra,72(sp)
    80002978:	e0a2                	sd	s0,64(sp)
    8000297a:	fc26                	sd	s1,56(sp)
    8000297c:	f84a                	sd	s2,48(sp)
    8000297e:	f44e                	sd	s3,40(sp)
    80002980:	f052                	sd	s4,32(sp)
    80002982:	ec56                	sd	s5,24(sp)
    80002984:	e85a                	sd	s6,16(sp)
    80002986:	e45e                	sd	s7,8(sp)
    80002988:	0880                	addi	s0,sp,80
            [ZOMBIE]    "zombie"
    };
    struct proc *p;
    char *state;

    printf("\n");
    8000298a:	00005517          	auipc	a0,0x5
    8000298e:	73e50513          	addi	a0,a0,1854 # 800080c8 <digits+0x88>
    80002992:	ffffe097          	auipc	ra,0xffffe
    80002996:	bf6080e7          	jalr	-1034(ra) # 80000588 <printf>
    for (p = proc; p < &proc[NPROC]; p++) {
    8000299a:	0000f497          	auipc	s1,0xf
    8000299e:	ece48493          	addi	s1,s1,-306 # 80011868 <proc+0x178>
    800029a2:	00015917          	auipc	s2,0x15
    800029a6:	0c690913          	addi	s2,s2,198 # 80017a68 <bcache+0x160>
        if (p->state == UNUSED)
            continue;
        if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800029aa:	4b15                	li	s6,5
            state = states[p->state];
        else
            state = "???";
    800029ac:	00006997          	auipc	s3,0x6
    800029b0:	9a498993          	addi	s3,s3,-1628 # 80008350 <digits+0x310>
        printf("%d %s %s", p->pid, state, p->name);
    800029b4:	00006a97          	auipc	s5,0x6
    800029b8:	9a4a8a93          	addi	s5,s5,-1628 # 80008358 <digits+0x318>
        printf("\n");
    800029bc:	00005a17          	auipc	s4,0x5
    800029c0:	70ca0a13          	addi	s4,s4,1804 # 800080c8 <digits+0x88>
        if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800029c4:	00006b97          	auipc	s7,0x6
    800029c8:	9ccb8b93          	addi	s7,s7,-1588 # 80008390 <states.1771>
    800029cc:	a00d                	j	800029ee <procdump+0x7a>
        printf("%d %s %s", p->pid, state, p->name);
    800029ce:	eb86a583          	lw	a1,-328(a3)
    800029d2:	8556                	mv	a0,s5
    800029d4:	ffffe097          	auipc	ra,0xffffe
    800029d8:	bb4080e7          	jalr	-1100(ra) # 80000588 <printf>
        printf("\n");
    800029dc:	8552                	mv	a0,s4
    800029de:	ffffe097          	auipc	ra,0xffffe
    800029e2:	baa080e7          	jalr	-1110(ra) # 80000588 <printf>
    for (p = proc; p < &proc[NPROC]; p++) {
    800029e6:	18848493          	addi	s1,s1,392
    800029ea:	03248163          	beq	s1,s2,80002a0c <procdump+0x98>
        if (p->state == UNUSED)
    800029ee:	86a6                	mv	a3,s1
    800029f0:	ea04a783          	lw	a5,-352(s1)
    800029f4:	dbed                	beqz	a5,800029e6 <procdump+0x72>
            state = "???";
    800029f6:	864e                	mv	a2,s3
        if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800029f8:	fcfb6be3          	bltu	s6,a5,800029ce <procdump+0x5a>
    800029fc:	1782                	slli	a5,a5,0x20
    800029fe:	9381                	srli	a5,a5,0x20
    80002a00:	078e                	slli	a5,a5,0x3
    80002a02:	97de                	add	a5,a5,s7
    80002a04:	6390                	ld	a2,0(a5)
    80002a06:	f661                	bnez	a2,800029ce <procdump+0x5a>
            state = "???";
    80002a08:	864e                	mv	a2,s3
    80002a0a:	b7d1                	j	800029ce <procdump+0x5a>
    }
    80002a0c:	60a6                	ld	ra,72(sp)
    80002a0e:	6406                	ld	s0,64(sp)
    80002a10:	74e2                	ld	s1,56(sp)
    80002a12:	7942                	ld	s2,48(sp)
    80002a14:	79a2                	ld	s3,40(sp)
    80002a16:	7a02                	ld	s4,32(sp)
    80002a18:	6ae2                	ld	s5,24(sp)
    80002a1a:	6b42                	ld	s6,16(sp)
    80002a1c:	6ba2                	ld	s7,8(sp)
    80002a1e:	6161                	addi	sp,sp,80
    80002a20:	8082                	ret

0000000080002a22 <swtch>:
    80002a22:	00153023          	sd	ra,0(a0)
    80002a26:	00253423          	sd	sp,8(a0)
    80002a2a:	e900                	sd	s0,16(a0)
    80002a2c:	ed04                	sd	s1,24(a0)
    80002a2e:	03253023          	sd	s2,32(a0)
    80002a32:	03353423          	sd	s3,40(a0)
    80002a36:	03453823          	sd	s4,48(a0)
    80002a3a:	03553c23          	sd	s5,56(a0)
    80002a3e:	05653023          	sd	s6,64(a0)
    80002a42:	05753423          	sd	s7,72(a0)
    80002a46:	05853823          	sd	s8,80(a0)
    80002a4a:	05953c23          	sd	s9,88(a0)
    80002a4e:	07a53023          	sd	s10,96(a0)
    80002a52:	07b53423          	sd	s11,104(a0)
    80002a56:	0005b083          	ld	ra,0(a1)
    80002a5a:	0085b103          	ld	sp,8(a1)
    80002a5e:	6980                	ld	s0,16(a1)
    80002a60:	6d84                	ld	s1,24(a1)
    80002a62:	0205b903          	ld	s2,32(a1)
    80002a66:	0285b983          	ld	s3,40(a1)
    80002a6a:	0305ba03          	ld	s4,48(a1)
    80002a6e:	0385ba83          	ld	s5,56(a1)
    80002a72:	0405bb03          	ld	s6,64(a1)
    80002a76:	0485bb83          	ld	s7,72(a1)
    80002a7a:	0505bc03          	ld	s8,80(a1)
    80002a7e:	0585bc83          	ld	s9,88(a1)
    80002a82:	0605bd03          	ld	s10,96(a1)
    80002a86:	0685bd83          	ld	s11,104(a1)
    80002a8a:	8082                	ret

0000000080002a8c <trapinit>:

extern int devintr();

void
trapinit(void)
{
    80002a8c:	1141                	addi	sp,sp,-16
    80002a8e:	e406                	sd	ra,8(sp)
    80002a90:	e022                	sd	s0,0(sp)
    80002a92:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002a94:	00006597          	auipc	a1,0x6
    80002a98:	92c58593          	addi	a1,a1,-1748 # 800083c0 <states.1771+0x30>
    80002a9c:	00015517          	auipc	a0,0x15
    80002aa0:	e5450513          	addi	a0,a0,-428 # 800178f0 <tickslock>
    80002aa4:	ffffe097          	auipc	ra,0xffffe
    80002aa8:	0b0080e7          	jalr	176(ra) # 80000b54 <initlock>
}
    80002aac:	60a2                	ld	ra,8(sp)
    80002aae:	6402                	ld	s0,0(sp)
    80002ab0:	0141                	addi	sp,sp,16
    80002ab2:	8082                	ret

0000000080002ab4 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    80002ab4:	1141                	addi	sp,sp,-16
    80002ab6:	e422                	sd	s0,8(sp)
    80002ab8:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002aba:	00003797          	auipc	a5,0x3
    80002abe:	4d678793          	addi	a5,a5,1238 # 80005f90 <kernelvec>
    80002ac2:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002ac6:	6422                	ld	s0,8(sp)
    80002ac8:	0141                	addi	sp,sp,16
    80002aca:	8082                	ret

0000000080002acc <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002acc:	1141                	addi	sp,sp,-16
    80002ace:	e406                	sd	ra,8(sp)
    80002ad0:	e022                	sd	s0,0(sp)
    80002ad2:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002ad4:	fffff097          	auipc	ra,0xfffff
    80002ad8:	ef4080e7          	jalr	-268(ra) # 800019c8 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002adc:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002ae0:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002ae2:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    80002ae6:	00004617          	auipc	a2,0x4
    80002aea:	51a60613          	addi	a2,a2,1306 # 80007000 <_trampoline>
    80002aee:	00004697          	auipc	a3,0x4
    80002af2:	51268693          	addi	a3,a3,1298 # 80007000 <_trampoline>
    80002af6:	8e91                	sub	a3,a3,a2
    80002af8:	040007b7          	lui	a5,0x4000
    80002afc:	17fd                	addi	a5,a5,-1
    80002afe:	07b2                	slli	a5,a5,0xc
    80002b00:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002b02:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002b06:	7d38                	ld	a4,120(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002b08:	180026f3          	csrr	a3,satp
    80002b0c:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002b0e:	7d38                	ld	a4,120(a0)
    80002b10:	7134                	ld	a3,96(a0)
    80002b12:	6585                	lui	a1,0x1
    80002b14:	96ae                	add	a3,a3,a1
    80002b16:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002b18:	7d38                	ld	a4,120(a0)
    80002b1a:	00000697          	auipc	a3,0x0
    80002b1e:	13868693          	addi	a3,a3,312 # 80002c52 <usertrap>
    80002b22:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80002b24:	7d38                	ld	a4,120(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002b26:	8692                	mv	a3,tp
    80002b28:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002b2a:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002b2e:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002b32:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002b36:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002b3a:	7d38                	ld	a4,120(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002b3c:	6f18                	ld	a4,24(a4)
    80002b3e:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002b42:	792c                	ld	a1,112(a0)
    80002b44:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    80002b46:	00004717          	auipc	a4,0x4
    80002b4a:	54a70713          	addi	a4,a4,1354 # 80007090 <userret>
    80002b4e:	8f11                	sub	a4,a4,a2
    80002b50:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    80002b52:	577d                	li	a4,-1
    80002b54:	177e                	slli	a4,a4,0x3f
    80002b56:	8dd9                	or	a1,a1,a4
    80002b58:	02000537          	lui	a0,0x2000
    80002b5c:	157d                	addi	a0,a0,-1
    80002b5e:	0536                	slli	a0,a0,0xd
    80002b60:	9782                	jalr	a5
}
    80002b62:	60a2                	ld	ra,8(sp)
    80002b64:	6402                	ld	s0,0(sp)
    80002b66:	0141                	addi	sp,sp,16
    80002b68:	8082                	ret

0000000080002b6a <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80002b6a:	1101                	addi	sp,sp,-32
    80002b6c:	ec06                	sd	ra,24(sp)
    80002b6e:	e822                	sd	s0,16(sp)
    80002b70:	e426                	sd	s1,8(sp)
    80002b72:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002b74:	00015497          	auipc	s1,0x15
    80002b78:	d7c48493          	addi	s1,s1,-644 # 800178f0 <tickslock>
    80002b7c:	8526                	mv	a0,s1
    80002b7e:	ffffe097          	auipc	ra,0xffffe
    80002b82:	066080e7          	jalr	102(ra) # 80000be4 <acquire>
  ticks++;
    80002b86:	00006517          	auipc	a0,0x6
    80002b8a:	4ca50513          	addi	a0,a0,1226 # 80009050 <ticks>
    80002b8e:	411c                	lw	a5,0(a0)
    80002b90:	2785                	addiw	a5,a5,1
    80002b92:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80002b94:	00000097          	auipc	ra,0x0
    80002b98:	9ae080e7          	jalr	-1618(ra) # 80002542 <wakeup>
  release(&tickslock);
    80002b9c:	8526                	mv	a0,s1
    80002b9e:	ffffe097          	auipc	ra,0xffffe
    80002ba2:	0fa080e7          	jalr	250(ra) # 80000c98 <release>
}
    80002ba6:	60e2                	ld	ra,24(sp)
    80002ba8:	6442                	ld	s0,16(sp)
    80002baa:	64a2                	ld	s1,8(sp)
    80002bac:	6105                	addi	sp,sp,32
    80002bae:	8082                	ret

0000000080002bb0 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80002bb0:	1101                	addi	sp,sp,-32
    80002bb2:	ec06                	sd	ra,24(sp)
    80002bb4:	e822                	sd	s0,16(sp)
    80002bb6:	e426                	sd	s1,8(sp)
    80002bb8:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002bba:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80002bbe:	00074d63          	bltz	a4,80002bd8 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80002bc2:	57fd                	li	a5,-1
    80002bc4:	17fe                	slli	a5,a5,0x3f
    80002bc6:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002bc8:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002bca:	06f70363          	beq	a4,a5,80002c30 <devintr+0x80>
  }
}
    80002bce:	60e2                	ld	ra,24(sp)
    80002bd0:	6442                	ld	s0,16(sp)
    80002bd2:	64a2                	ld	s1,8(sp)
    80002bd4:	6105                	addi	sp,sp,32
    80002bd6:	8082                	ret
     (scause & 0xff) == 9){
    80002bd8:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    80002bdc:	46a5                	li	a3,9
    80002bde:	fed792e3          	bne	a5,a3,80002bc2 <devintr+0x12>
    int irq = plic_claim();
    80002be2:	00003097          	auipc	ra,0x3
    80002be6:	4b6080e7          	jalr	1206(ra) # 80006098 <plic_claim>
    80002bea:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002bec:	47a9                	li	a5,10
    80002bee:	02f50763          	beq	a0,a5,80002c1c <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80002bf2:	4785                	li	a5,1
    80002bf4:	02f50963          	beq	a0,a5,80002c26 <devintr+0x76>
    return 1;
    80002bf8:	4505                	li	a0,1
    } else if(irq){
    80002bfa:	d8f1                	beqz	s1,80002bce <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002bfc:	85a6                	mv	a1,s1
    80002bfe:	00005517          	auipc	a0,0x5
    80002c02:	7ca50513          	addi	a0,a0,1994 # 800083c8 <states.1771+0x38>
    80002c06:	ffffe097          	auipc	ra,0xffffe
    80002c0a:	982080e7          	jalr	-1662(ra) # 80000588 <printf>
      plic_complete(irq);
    80002c0e:	8526                	mv	a0,s1
    80002c10:	00003097          	auipc	ra,0x3
    80002c14:	4ac080e7          	jalr	1196(ra) # 800060bc <plic_complete>
    return 1;
    80002c18:	4505                	li	a0,1
    80002c1a:	bf55                	j	80002bce <devintr+0x1e>
      uartintr();
    80002c1c:	ffffe097          	auipc	ra,0xffffe
    80002c20:	d8c080e7          	jalr	-628(ra) # 800009a8 <uartintr>
    80002c24:	b7ed                	j	80002c0e <devintr+0x5e>
      virtio_disk_intr();
    80002c26:	00004097          	auipc	ra,0x4
    80002c2a:	976080e7          	jalr	-1674(ra) # 8000659c <virtio_disk_intr>
    80002c2e:	b7c5                	j	80002c0e <devintr+0x5e>
    if(cpuid() == 0){
    80002c30:	fffff097          	auipc	ra,0xfffff
    80002c34:	d6c080e7          	jalr	-660(ra) # 8000199c <cpuid>
    80002c38:	c901                	beqz	a0,80002c48 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002c3a:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002c3e:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002c40:	14479073          	csrw	sip,a5
    return 2;
    80002c44:	4509                	li	a0,2
    80002c46:	b761                	j	80002bce <devintr+0x1e>
      clockintr();
    80002c48:	00000097          	auipc	ra,0x0
    80002c4c:	f22080e7          	jalr	-222(ra) # 80002b6a <clockintr>
    80002c50:	b7ed                	j	80002c3a <devintr+0x8a>

0000000080002c52 <usertrap>:
{
    80002c52:	1101                	addi	sp,sp,-32
    80002c54:	ec06                	sd	ra,24(sp)
    80002c56:	e822                	sd	s0,16(sp)
    80002c58:	e426                	sd	s1,8(sp)
    80002c5a:	e04a                	sd	s2,0(sp)
    80002c5c:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002c5e:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002c62:	1007f793          	andi	a5,a5,256
    80002c66:	e3ad                	bnez	a5,80002cc8 <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002c68:	00003797          	auipc	a5,0x3
    80002c6c:	32878793          	addi	a5,a5,808 # 80005f90 <kernelvec>
    80002c70:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002c74:	fffff097          	auipc	ra,0xfffff
    80002c78:	d54080e7          	jalr	-684(ra) # 800019c8 <myproc>
    80002c7c:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002c7e:	7d3c                	ld	a5,120(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002c80:	14102773          	csrr	a4,sepc
    80002c84:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002c86:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002c8a:	47a1                	li	a5,8
    80002c8c:	04f71c63          	bne	a4,a5,80002ce4 <usertrap+0x92>
    if(p->killed)
    80002c90:	551c                	lw	a5,40(a0)
    80002c92:	e3b9                	bnez	a5,80002cd8 <usertrap+0x86>
    p->trapframe->epc += 4;
    80002c94:	7cb8                	ld	a4,120(s1)
    80002c96:	6f1c                	ld	a5,24(a4)
    80002c98:	0791                	addi	a5,a5,4
    80002c9a:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002c9c:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002ca0:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002ca4:	10079073          	csrw	sstatus,a5
    syscall();
    80002ca8:	00000097          	auipc	ra,0x0
    80002cac:	2e0080e7          	jalr	736(ra) # 80002f88 <syscall>
  if(p->killed)
    80002cb0:	549c                	lw	a5,40(s1)
    80002cb2:	ebc1                	bnez	a5,80002d42 <usertrap+0xf0>
  usertrapret();
    80002cb4:	00000097          	auipc	ra,0x0
    80002cb8:	e18080e7          	jalr	-488(ra) # 80002acc <usertrapret>
}
    80002cbc:	60e2                	ld	ra,24(sp)
    80002cbe:	6442                	ld	s0,16(sp)
    80002cc0:	64a2                	ld	s1,8(sp)
    80002cc2:	6902                	ld	s2,0(sp)
    80002cc4:	6105                	addi	sp,sp,32
    80002cc6:	8082                	ret
    panic("usertrap: not from user mode");
    80002cc8:	00005517          	auipc	a0,0x5
    80002ccc:	72050513          	addi	a0,a0,1824 # 800083e8 <states.1771+0x58>
    80002cd0:	ffffe097          	auipc	ra,0xffffe
    80002cd4:	86e080e7          	jalr	-1938(ra) # 8000053e <panic>
      exit(-1);
    80002cd8:	557d                	li	a0,-1
    80002cda:	00000097          	auipc	ra,0x0
    80002cde:	958080e7          	jalr	-1704(ra) # 80002632 <exit>
    80002ce2:	bf4d                	j	80002c94 <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    80002ce4:	00000097          	auipc	ra,0x0
    80002ce8:	ecc080e7          	jalr	-308(ra) # 80002bb0 <devintr>
    80002cec:	892a                	mv	s2,a0
    80002cee:	c501                	beqz	a0,80002cf6 <usertrap+0xa4>
  if(p->killed)
    80002cf0:	549c                	lw	a5,40(s1)
    80002cf2:	c3a1                	beqz	a5,80002d32 <usertrap+0xe0>
    80002cf4:	a815                	j	80002d28 <usertrap+0xd6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002cf6:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002cfa:	5890                	lw	a2,48(s1)
    80002cfc:	00005517          	auipc	a0,0x5
    80002d00:	70c50513          	addi	a0,a0,1804 # 80008408 <states.1771+0x78>
    80002d04:	ffffe097          	auipc	ra,0xffffe
    80002d08:	884080e7          	jalr	-1916(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002d0c:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002d10:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002d14:	00005517          	auipc	a0,0x5
    80002d18:	72450513          	addi	a0,a0,1828 # 80008438 <states.1771+0xa8>
    80002d1c:	ffffe097          	auipc	ra,0xffffe
    80002d20:	86c080e7          	jalr	-1940(ra) # 80000588 <printf>
    p->killed = 1;
    80002d24:	4785                	li	a5,1
    80002d26:	d49c                	sw	a5,40(s1)
    exit(-1);
    80002d28:	557d                	li	a0,-1
    80002d2a:	00000097          	auipc	ra,0x0
    80002d2e:	908080e7          	jalr	-1784(ra) # 80002632 <exit>
  if(which_dev == 2)
    80002d32:	4789                	li	a5,2
    80002d34:	f8f910e3          	bne	s2,a5,80002cb4 <usertrap+0x62>
    yield();
    80002d38:	fffff097          	auipc	ra,0xfffff
    80002d3c:	616080e7          	jalr	1558(ra) # 8000234e <yield>
    80002d40:	bf95                	j	80002cb4 <usertrap+0x62>
  int which_dev = 0;
    80002d42:	4901                	li	s2,0
    80002d44:	b7d5                	j	80002d28 <usertrap+0xd6>

0000000080002d46 <kerneltrap>:
{
    80002d46:	7179                	addi	sp,sp,-48
    80002d48:	f406                	sd	ra,40(sp)
    80002d4a:	f022                	sd	s0,32(sp)
    80002d4c:	ec26                	sd	s1,24(sp)
    80002d4e:	e84a                	sd	s2,16(sp)
    80002d50:	e44e                	sd	s3,8(sp)
    80002d52:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002d54:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002d58:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002d5c:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002d60:	1004f793          	andi	a5,s1,256
    80002d64:	cb85                	beqz	a5,80002d94 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002d66:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002d6a:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002d6c:	ef85                	bnez	a5,80002da4 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002d6e:	00000097          	auipc	ra,0x0
    80002d72:	e42080e7          	jalr	-446(ra) # 80002bb0 <devintr>
    80002d76:	cd1d                	beqz	a0,80002db4 <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002d78:	4789                	li	a5,2
    80002d7a:	06f50a63          	beq	a0,a5,80002dee <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002d7e:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002d82:	10049073          	csrw	sstatus,s1
}
    80002d86:	70a2                	ld	ra,40(sp)
    80002d88:	7402                	ld	s0,32(sp)
    80002d8a:	64e2                	ld	s1,24(sp)
    80002d8c:	6942                	ld	s2,16(sp)
    80002d8e:	69a2                	ld	s3,8(sp)
    80002d90:	6145                	addi	sp,sp,48
    80002d92:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002d94:	00005517          	auipc	a0,0x5
    80002d98:	6c450513          	addi	a0,a0,1732 # 80008458 <states.1771+0xc8>
    80002d9c:	ffffd097          	auipc	ra,0xffffd
    80002da0:	7a2080e7          	jalr	1954(ra) # 8000053e <panic>
    panic("kerneltrap: interrupts enabled");
    80002da4:	00005517          	auipc	a0,0x5
    80002da8:	6dc50513          	addi	a0,a0,1756 # 80008480 <states.1771+0xf0>
    80002dac:	ffffd097          	auipc	ra,0xffffd
    80002db0:	792080e7          	jalr	1938(ra) # 8000053e <panic>
    printf("scause %p\n", scause);
    80002db4:	85ce                	mv	a1,s3
    80002db6:	00005517          	auipc	a0,0x5
    80002dba:	6ea50513          	addi	a0,a0,1770 # 800084a0 <states.1771+0x110>
    80002dbe:	ffffd097          	auipc	ra,0xffffd
    80002dc2:	7ca080e7          	jalr	1994(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002dc6:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002dca:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002dce:	00005517          	auipc	a0,0x5
    80002dd2:	6e250513          	addi	a0,a0,1762 # 800084b0 <states.1771+0x120>
    80002dd6:	ffffd097          	auipc	ra,0xffffd
    80002dda:	7b2080e7          	jalr	1970(ra) # 80000588 <printf>
    panic("kerneltrap");
    80002dde:	00005517          	auipc	a0,0x5
    80002de2:	6ea50513          	addi	a0,a0,1770 # 800084c8 <states.1771+0x138>
    80002de6:	ffffd097          	auipc	ra,0xffffd
    80002dea:	758080e7          	jalr	1880(ra) # 8000053e <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002dee:	fffff097          	auipc	ra,0xfffff
    80002df2:	bda080e7          	jalr	-1062(ra) # 800019c8 <myproc>
    80002df6:	d541                	beqz	a0,80002d7e <kerneltrap+0x38>
    80002df8:	fffff097          	auipc	ra,0xfffff
    80002dfc:	bd0080e7          	jalr	-1072(ra) # 800019c8 <myproc>
    80002e00:	4d18                	lw	a4,24(a0)
    80002e02:	4791                	li	a5,4
    80002e04:	f6f71de3          	bne	a4,a5,80002d7e <kerneltrap+0x38>
    yield();
    80002e08:	fffff097          	auipc	ra,0xfffff
    80002e0c:	546080e7          	jalr	1350(ra) # 8000234e <yield>
    80002e10:	b7bd                	j	80002d7e <kerneltrap+0x38>

0000000080002e12 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002e12:	1101                	addi	sp,sp,-32
    80002e14:	ec06                	sd	ra,24(sp)
    80002e16:	e822                	sd	s0,16(sp)
    80002e18:	e426                	sd	s1,8(sp)
    80002e1a:	1000                	addi	s0,sp,32
    80002e1c:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002e1e:	fffff097          	auipc	ra,0xfffff
    80002e22:	baa080e7          	jalr	-1110(ra) # 800019c8 <myproc>
  switch (n) {
    80002e26:	4795                	li	a5,5
    80002e28:	0497e163          	bltu	a5,s1,80002e6a <argraw+0x58>
    80002e2c:	048a                	slli	s1,s1,0x2
    80002e2e:	00005717          	auipc	a4,0x5
    80002e32:	6d270713          	addi	a4,a4,1746 # 80008500 <states.1771+0x170>
    80002e36:	94ba                	add	s1,s1,a4
    80002e38:	409c                	lw	a5,0(s1)
    80002e3a:	97ba                	add	a5,a5,a4
    80002e3c:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002e3e:	7d3c                	ld	a5,120(a0)
    80002e40:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002e42:	60e2                	ld	ra,24(sp)
    80002e44:	6442                	ld	s0,16(sp)
    80002e46:	64a2                	ld	s1,8(sp)
    80002e48:	6105                	addi	sp,sp,32
    80002e4a:	8082                	ret
    return p->trapframe->a1;
    80002e4c:	7d3c                	ld	a5,120(a0)
    80002e4e:	7fa8                	ld	a0,120(a5)
    80002e50:	bfcd                	j	80002e42 <argraw+0x30>
    return p->trapframe->a2;
    80002e52:	7d3c                	ld	a5,120(a0)
    80002e54:	63c8                	ld	a0,128(a5)
    80002e56:	b7f5                	j	80002e42 <argraw+0x30>
    return p->trapframe->a3;
    80002e58:	7d3c                	ld	a5,120(a0)
    80002e5a:	67c8                	ld	a0,136(a5)
    80002e5c:	b7dd                	j	80002e42 <argraw+0x30>
    return p->trapframe->a4;
    80002e5e:	7d3c                	ld	a5,120(a0)
    80002e60:	6bc8                	ld	a0,144(a5)
    80002e62:	b7c5                	j	80002e42 <argraw+0x30>
    return p->trapframe->a5;
    80002e64:	7d3c                	ld	a5,120(a0)
    80002e66:	6fc8                	ld	a0,152(a5)
    80002e68:	bfe9                	j	80002e42 <argraw+0x30>
  panic("argraw");
    80002e6a:	00005517          	auipc	a0,0x5
    80002e6e:	66e50513          	addi	a0,a0,1646 # 800084d8 <states.1771+0x148>
    80002e72:	ffffd097          	auipc	ra,0xffffd
    80002e76:	6cc080e7          	jalr	1740(ra) # 8000053e <panic>

0000000080002e7a <fetchaddr>:
{
    80002e7a:	1101                	addi	sp,sp,-32
    80002e7c:	ec06                	sd	ra,24(sp)
    80002e7e:	e822                	sd	s0,16(sp)
    80002e80:	e426                	sd	s1,8(sp)
    80002e82:	e04a                	sd	s2,0(sp)
    80002e84:	1000                	addi	s0,sp,32
    80002e86:	84aa                	mv	s1,a0
    80002e88:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002e8a:	fffff097          	auipc	ra,0xfffff
    80002e8e:	b3e080e7          	jalr	-1218(ra) # 800019c8 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    80002e92:	753c                	ld	a5,104(a0)
    80002e94:	02f4f863          	bgeu	s1,a5,80002ec4 <fetchaddr+0x4a>
    80002e98:	00848713          	addi	a4,s1,8
    80002e9c:	02e7e663          	bltu	a5,a4,80002ec8 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002ea0:	46a1                	li	a3,8
    80002ea2:	8626                	mv	a2,s1
    80002ea4:	85ca                	mv	a1,s2
    80002ea6:	7928                	ld	a0,112(a0)
    80002ea8:	fffff097          	auipc	ra,0xfffff
    80002eac:	85e080e7          	jalr	-1954(ra) # 80001706 <copyin>
    80002eb0:	00a03533          	snez	a0,a0
    80002eb4:	40a00533          	neg	a0,a0
}
    80002eb8:	60e2                	ld	ra,24(sp)
    80002eba:	6442                	ld	s0,16(sp)
    80002ebc:	64a2                	ld	s1,8(sp)
    80002ebe:	6902                	ld	s2,0(sp)
    80002ec0:	6105                	addi	sp,sp,32
    80002ec2:	8082                	ret
    return -1;
    80002ec4:	557d                	li	a0,-1
    80002ec6:	bfcd                	j	80002eb8 <fetchaddr+0x3e>
    80002ec8:	557d                	li	a0,-1
    80002eca:	b7fd                	j	80002eb8 <fetchaddr+0x3e>

0000000080002ecc <fetchstr>:
{
    80002ecc:	7179                	addi	sp,sp,-48
    80002ece:	f406                	sd	ra,40(sp)
    80002ed0:	f022                	sd	s0,32(sp)
    80002ed2:	ec26                	sd	s1,24(sp)
    80002ed4:	e84a                	sd	s2,16(sp)
    80002ed6:	e44e                	sd	s3,8(sp)
    80002ed8:	1800                	addi	s0,sp,48
    80002eda:	892a                	mv	s2,a0
    80002edc:	84ae                	mv	s1,a1
    80002ede:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002ee0:	fffff097          	auipc	ra,0xfffff
    80002ee4:	ae8080e7          	jalr	-1304(ra) # 800019c8 <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80002ee8:	86ce                	mv	a3,s3
    80002eea:	864a                	mv	a2,s2
    80002eec:	85a6                	mv	a1,s1
    80002eee:	7928                	ld	a0,112(a0)
    80002ef0:	fffff097          	auipc	ra,0xfffff
    80002ef4:	8a2080e7          	jalr	-1886(ra) # 80001792 <copyinstr>
  if(err < 0)
    80002ef8:	00054763          	bltz	a0,80002f06 <fetchstr+0x3a>
  return strlen(buf);
    80002efc:	8526                	mv	a0,s1
    80002efe:	ffffe097          	auipc	ra,0xffffe
    80002f02:	f66080e7          	jalr	-154(ra) # 80000e64 <strlen>
}
    80002f06:	70a2                	ld	ra,40(sp)
    80002f08:	7402                	ld	s0,32(sp)
    80002f0a:	64e2                	ld	s1,24(sp)
    80002f0c:	6942                	ld	s2,16(sp)
    80002f0e:	69a2                	ld	s3,8(sp)
    80002f10:	6145                	addi	sp,sp,48
    80002f12:	8082                	ret

0000000080002f14 <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80002f14:	1101                	addi	sp,sp,-32
    80002f16:	ec06                	sd	ra,24(sp)
    80002f18:	e822                	sd	s0,16(sp)
    80002f1a:	e426                	sd	s1,8(sp)
    80002f1c:	1000                	addi	s0,sp,32
    80002f1e:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002f20:	00000097          	auipc	ra,0x0
    80002f24:	ef2080e7          	jalr	-270(ra) # 80002e12 <argraw>
    80002f28:	c088                	sw	a0,0(s1)
  return 0;
}
    80002f2a:	4501                	li	a0,0
    80002f2c:	60e2                	ld	ra,24(sp)
    80002f2e:	6442                	ld	s0,16(sp)
    80002f30:	64a2                	ld	s1,8(sp)
    80002f32:	6105                	addi	sp,sp,32
    80002f34:	8082                	ret

0000000080002f36 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80002f36:	1101                	addi	sp,sp,-32
    80002f38:	ec06                	sd	ra,24(sp)
    80002f3a:	e822                	sd	s0,16(sp)
    80002f3c:	e426                	sd	s1,8(sp)
    80002f3e:	1000                	addi	s0,sp,32
    80002f40:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002f42:	00000097          	auipc	ra,0x0
    80002f46:	ed0080e7          	jalr	-304(ra) # 80002e12 <argraw>
    80002f4a:	e088                	sd	a0,0(s1)
  return 0;
}
    80002f4c:	4501                	li	a0,0
    80002f4e:	60e2                	ld	ra,24(sp)
    80002f50:	6442                	ld	s0,16(sp)
    80002f52:	64a2                	ld	s1,8(sp)
    80002f54:	6105                	addi	sp,sp,32
    80002f56:	8082                	ret

0000000080002f58 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002f58:	1101                	addi	sp,sp,-32
    80002f5a:	ec06                	sd	ra,24(sp)
    80002f5c:	e822                	sd	s0,16(sp)
    80002f5e:	e426                	sd	s1,8(sp)
    80002f60:	e04a                	sd	s2,0(sp)
    80002f62:	1000                	addi	s0,sp,32
    80002f64:	84ae                	mv	s1,a1
    80002f66:	8932                	mv	s2,a2
  *ip = argraw(n);
    80002f68:	00000097          	auipc	ra,0x0
    80002f6c:	eaa080e7          	jalr	-342(ra) # 80002e12 <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80002f70:	864a                	mv	a2,s2
    80002f72:	85a6                	mv	a1,s1
    80002f74:	00000097          	auipc	ra,0x0
    80002f78:	f58080e7          	jalr	-168(ra) # 80002ecc <fetchstr>
}
    80002f7c:	60e2                	ld	ra,24(sp)
    80002f7e:	6442                	ld	s0,16(sp)
    80002f80:	64a2                	ld	s1,8(sp)
    80002f82:	6902                	ld	s2,0(sp)
    80002f84:	6105                	addi	sp,sp,32
    80002f86:	8082                	ret

0000000080002f88 <syscall>:
[SYS_kill_system] sys_kill_system,
};

void
syscall(void)
{
    80002f88:	1101                	addi	sp,sp,-32
    80002f8a:	ec06                	sd	ra,24(sp)
    80002f8c:	e822                	sd	s0,16(sp)
    80002f8e:	e426                	sd	s1,8(sp)
    80002f90:	e04a                	sd	s2,0(sp)
    80002f92:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002f94:	fffff097          	auipc	ra,0xfffff
    80002f98:	a34080e7          	jalr	-1484(ra) # 800019c8 <myproc>
    80002f9c:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002f9e:	07853903          	ld	s2,120(a0)
    80002fa2:	0a893783          	ld	a5,168(s2)
    80002fa6:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002faa:	37fd                	addiw	a5,a5,-1
    80002fac:	4759                	li	a4,22
    80002fae:	00f76f63          	bltu	a4,a5,80002fcc <syscall+0x44>
    80002fb2:	00369713          	slli	a4,a3,0x3
    80002fb6:	00005797          	auipc	a5,0x5
    80002fba:	56278793          	addi	a5,a5,1378 # 80008518 <syscalls>
    80002fbe:	97ba                	add	a5,a5,a4
    80002fc0:	639c                	ld	a5,0(a5)
    80002fc2:	c789                	beqz	a5,80002fcc <syscall+0x44>
    p->trapframe->a0 = syscalls[num]();
    80002fc4:	9782                	jalr	a5
    80002fc6:	06a93823          	sd	a0,112(s2)
    80002fca:	a839                	j	80002fe8 <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002fcc:	17848613          	addi	a2,s1,376
    80002fd0:	588c                	lw	a1,48(s1)
    80002fd2:	00005517          	auipc	a0,0x5
    80002fd6:	50e50513          	addi	a0,a0,1294 # 800084e0 <states.1771+0x150>
    80002fda:	ffffd097          	auipc	ra,0xffffd
    80002fde:	5ae080e7          	jalr	1454(ra) # 80000588 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002fe2:	7cbc                	ld	a5,120(s1)
    80002fe4:	577d                	li	a4,-1
    80002fe6:	fbb8                	sd	a4,112(a5)
  }
}
    80002fe8:	60e2                	ld	ra,24(sp)
    80002fea:	6442                	ld	s0,16(sp)
    80002fec:	64a2                	ld	s1,8(sp)
    80002fee:	6902                	ld	s2,0(sp)
    80002ff0:	6105                	addi	sp,sp,32
    80002ff2:	8082                	ret

0000000080002ff4 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002ff4:	1101                	addi	sp,sp,-32
    80002ff6:	ec06                	sd	ra,24(sp)
    80002ff8:	e822                	sd	s0,16(sp)
    80002ffa:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80002ffc:	fec40593          	addi	a1,s0,-20
    80003000:	4501                	li	a0,0
    80003002:	00000097          	auipc	ra,0x0
    80003006:	f12080e7          	jalr	-238(ra) # 80002f14 <argint>
    return -1;
    8000300a:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    8000300c:	00054963          	bltz	a0,8000301e <sys_exit+0x2a>
  exit(n);
    80003010:	fec42503          	lw	a0,-20(s0)
    80003014:	fffff097          	auipc	ra,0xfffff
    80003018:	61e080e7          	jalr	1566(ra) # 80002632 <exit>
  return 0;  // not reached
    8000301c:	4781                	li	a5,0
}
    8000301e:	853e                	mv	a0,a5
    80003020:	60e2                	ld	ra,24(sp)
    80003022:	6442                	ld	s0,16(sp)
    80003024:	6105                	addi	sp,sp,32
    80003026:	8082                	ret

0000000080003028 <sys_getpid>:

uint64
sys_getpid(void)
{
    80003028:	1141                	addi	sp,sp,-16
    8000302a:	e406                	sd	ra,8(sp)
    8000302c:	e022                	sd	s0,0(sp)
    8000302e:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80003030:	fffff097          	auipc	ra,0xfffff
    80003034:	998080e7          	jalr	-1640(ra) # 800019c8 <myproc>
}
    80003038:	5908                	lw	a0,48(a0)
    8000303a:	60a2                	ld	ra,8(sp)
    8000303c:	6402                	ld	s0,0(sp)
    8000303e:	0141                	addi	sp,sp,16
    80003040:	8082                	ret

0000000080003042 <sys_fork>:

uint64
sys_fork(void)
{
    80003042:	1141                	addi	sp,sp,-16
    80003044:	e406                	sd	ra,8(sp)
    80003046:	e022                	sd	s0,0(sp)
    80003048:	0800                	addi	s0,sp,16
  return fork();
    8000304a:	fffff097          	auipc	ra,0xfffff
    8000304e:	d7a080e7          	jalr	-646(ra) # 80001dc4 <fork>
}
    80003052:	60a2                	ld	ra,8(sp)
    80003054:	6402                	ld	s0,0(sp)
    80003056:	0141                	addi	sp,sp,16
    80003058:	8082                	ret

000000008000305a <sys_wait>:

uint64
sys_wait(void)
{
    8000305a:	1101                	addi	sp,sp,-32
    8000305c:	ec06                	sd	ra,24(sp)
    8000305e:	e822                	sd	s0,16(sp)
    80003060:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80003062:	fe840593          	addi	a1,s0,-24
    80003066:	4501                	li	a0,0
    80003068:	00000097          	auipc	ra,0x0
    8000306c:	ece080e7          	jalr	-306(ra) # 80002f36 <argaddr>
    80003070:	87aa                	mv	a5,a0
    return -1;
    80003072:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80003074:	0007c863          	bltz	a5,80003084 <sys_wait+0x2a>
  return wait(p);
    80003078:	fe843503          	ld	a0,-24(s0)
    8000307c:	fffff097          	auipc	ra,0xfffff
    80003080:	39e080e7          	jalr	926(ra) # 8000241a <wait>
}
    80003084:	60e2                	ld	ra,24(sp)
    80003086:	6442                	ld	s0,16(sp)
    80003088:	6105                	addi	sp,sp,32
    8000308a:	8082                	ret

000000008000308c <sys_sbrk>:

uint64
sys_sbrk(void)
{
    8000308c:	7179                	addi	sp,sp,-48
    8000308e:	f406                	sd	ra,40(sp)
    80003090:	f022                	sd	s0,32(sp)
    80003092:	ec26                	sd	s1,24(sp)
    80003094:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    80003096:	fdc40593          	addi	a1,s0,-36
    8000309a:	4501                	li	a0,0
    8000309c:	00000097          	auipc	ra,0x0
    800030a0:	e78080e7          	jalr	-392(ra) # 80002f14 <argint>
    800030a4:	87aa                	mv	a5,a0
    return -1;
    800030a6:	557d                	li	a0,-1
  if(argint(0, &n) < 0)
    800030a8:	0207c063          	bltz	a5,800030c8 <sys_sbrk+0x3c>
  addr = myproc()->sz;
    800030ac:	fffff097          	auipc	ra,0xfffff
    800030b0:	91c080e7          	jalr	-1764(ra) # 800019c8 <myproc>
    800030b4:	5524                	lw	s1,104(a0)
  if(growproc(n) < 0)
    800030b6:	fdc42503          	lw	a0,-36(s0)
    800030ba:	fffff097          	auipc	ra,0xfffff
    800030be:	c96080e7          	jalr	-874(ra) # 80001d50 <growproc>
    800030c2:	00054863          	bltz	a0,800030d2 <sys_sbrk+0x46>
    return -1;
  return addr;
    800030c6:	8526                	mv	a0,s1
}
    800030c8:	70a2                	ld	ra,40(sp)
    800030ca:	7402                	ld	s0,32(sp)
    800030cc:	64e2                	ld	s1,24(sp)
    800030ce:	6145                	addi	sp,sp,48
    800030d0:	8082                	ret
    return -1;
    800030d2:	557d                	li	a0,-1
    800030d4:	bfd5                	j	800030c8 <sys_sbrk+0x3c>

00000000800030d6 <sys_sleep>:

uint64
sys_sleep(void)
{
    800030d6:	7139                	addi	sp,sp,-64
    800030d8:	fc06                	sd	ra,56(sp)
    800030da:	f822                	sd	s0,48(sp)
    800030dc:	f426                	sd	s1,40(sp)
    800030de:	f04a                	sd	s2,32(sp)
    800030e0:	ec4e                	sd	s3,24(sp)
    800030e2:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    800030e4:	fcc40593          	addi	a1,s0,-52
    800030e8:	4501                	li	a0,0
    800030ea:	00000097          	auipc	ra,0x0
    800030ee:	e2a080e7          	jalr	-470(ra) # 80002f14 <argint>
    return -1;
    800030f2:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    800030f4:	06054563          	bltz	a0,8000315e <sys_sleep+0x88>
  acquire(&tickslock);
    800030f8:	00014517          	auipc	a0,0x14
    800030fc:	7f850513          	addi	a0,a0,2040 # 800178f0 <tickslock>
    80003100:	ffffe097          	auipc	ra,0xffffe
    80003104:	ae4080e7          	jalr	-1308(ra) # 80000be4 <acquire>
  ticks0 = ticks;
    80003108:	00006917          	auipc	s2,0x6
    8000310c:	f4892903          	lw	s2,-184(s2) # 80009050 <ticks>
  while(ticks - ticks0 < n){
    80003110:	fcc42783          	lw	a5,-52(s0)
    80003114:	cf85                	beqz	a5,8000314c <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80003116:	00014997          	auipc	s3,0x14
    8000311a:	7da98993          	addi	s3,s3,2010 # 800178f0 <tickslock>
    8000311e:	00006497          	auipc	s1,0x6
    80003122:	f3248493          	addi	s1,s1,-206 # 80009050 <ticks>
    if(myproc()->killed){
    80003126:	fffff097          	auipc	ra,0xfffff
    8000312a:	8a2080e7          	jalr	-1886(ra) # 800019c8 <myproc>
    8000312e:	551c                	lw	a5,40(a0)
    80003130:	ef9d                	bnez	a5,8000316e <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    80003132:	85ce                	mv	a1,s3
    80003134:	8526                	mv	a0,s1
    80003136:	fffff097          	auipc	ra,0xfffff
    8000313a:	26c080e7          	jalr	620(ra) # 800023a2 <sleep>
  while(ticks - ticks0 < n){
    8000313e:	409c                	lw	a5,0(s1)
    80003140:	412787bb          	subw	a5,a5,s2
    80003144:	fcc42703          	lw	a4,-52(s0)
    80003148:	fce7efe3          	bltu	a5,a4,80003126 <sys_sleep+0x50>
  }
  release(&tickslock);
    8000314c:	00014517          	auipc	a0,0x14
    80003150:	7a450513          	addi	a0,a0,1956 # 800178f0 <tickslock>
    80003154:	ffffe097          	auipc	ra,0xffffe
    80003158:	b44080e7          	jalr	-1212(ra) # 80000c98 <release>
  return 0;
    8000315c:	4781                	li	a5,0
}
    8000315e:	853e                	mv	a0,a5
    80003160:	70e2                	ld	ra,56(sp)
    80003162:	7442                	ld	s0,48(sp)
    80003164:	74a2                	ld	s1,40(sp)
    80003166:	7902                	ld	s2,32(sp)
    80003168:	69e2                	ld	s3,24(sp)
    8000316a:	6121                	addi	sp,sp,64
    8000316c:	8082                	ret
      release(&tickslock);
    8000316e:	00014517          	auipc	a0,0x14
    80003172:	78250513          	addi	a0,a0,1922 # 800178f0 <tickslock>
    80003176:	ffffe097          	auipc	ra,0xffffe
    8000317a:	b22080e7          	jalr	-1246(ra) # 80000c98 <release>
      return -1;
    8000317e:	57fd                	li	a5,-1
    80003180:	bff9                	j	8000315e <sys_sleep+0x88>

0000000080003182 <sys_kill>:

uint64
sys_kill(void)
{
    80003182:	1101                	addi	sp,sp,-32
    80003184:	ec06                	sd	ra,24(sp)
    80003186:	e822                	sd	s0,16(sp)
    80003188:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    8000318a:	fec40593          	addi	a1,s0,-20
    8000318e:	4501                	li	a0,0
    80003190:	00000097          	auipc	ra,0x0
    80003194:	d84080e7          	jalr	-636(ra) # 80002f14 <argint>
    80003198:	87aa                	mv	a5,a0
    return -1;
    8000319a:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    8000319c:	0007c863          	bltz	a5,800031ac <sys_kill+0x2a>
  return kill(pid);
    800031a0:	fec42503          	lw	a0,-20(s0)
    800031a4:	fffff097          	auipc	ra,0xfffff
    800031a8:	5f8080e7          	jalr	1528(ra) # 8000279c <kill>
}
    800031ac:	60e2                	ld	ra,24(sp)
    800031ae:	6442                	ld	s0,16(sp)
    800031b0:	6105                	addi	sp,sp,32
    800031b2:	8082                	ret

00000000800031b4 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    800031b4:	1101                	addi	sp,sp,-32
    800031b6:	ec06                	sd	ra,24(sp)
    800031b8:	e822                	sd	s0,16(sp)
    800031ba:	e426                	sd	s1,8(sp)
    800031bc:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    800031be:	00014517          	auipc	a0,0x14
    800031c2:	73250513          	addi	a0,a0,1842 # 800178f0 <tickslock>
    800031c6:	ffffe097          	auipc	ra,0xffffe
    800031ca:	a1e080e7          	jalr	-1506(ra) # 80000be4 <acquire>
  xticks = ticks;
    800031ce:	00006497          	auipc	s1,0x6
    800031d2:	e824a483          	lw	s1,-382(s1) # 80009050 <ticks>
  release(&tickslock);
    800031d6:	00014517          	auipc	a0,0x14
    800031da:	71a50513          	addi	a0,a0,1818 # 800178f0 <tickslock>
    800031de:	ffffe097          	auipc	ra,0xffffe
    800031e2:	aba080e7          	jalr	-1350(ra) # 80000c98 <release>
  return xticks;
}
    800031e6:	02049513          	slli	a0,s1,0x20
    800031ea:	9101                	srli	a0,a0,0x20
    800031ec:	60e2                	ld	ra,24(sp)
    800031ee:	6442                	ld	s0,16(sp)
    800031f0:	64a2                	ld	s1,8(sp)
    800031f2:	6105                	addi	sp,sp,32
    800031f4:	8082                	ret

00000000800031f6 <sys_pause_system>:

uint64 sys_pause_system(void){
    800031f6:	1101                	addi	sp,sp,-32
    800031f8:	ec06                	sd	ra,24(sp)
    800031fa:	e822                	sd	s0,16(sp)
    800031fc:	1000                	addi	s0,sp,32
    int seconds;

    if(argint(0, &seconds) < 0)
    800031fe:	fec40593          	addi	a1,s0,-20
    80003202:	4501                	li	a0,0
    80003204:	00000097          	auipc	ra,0x0
    80003208:	d10080e7          	jalr	-752(ra) # 80002f14 <argint>
        return -1;
    8000320c:	57fd                	li	a5,-1
    if(argint(0, &seconds) < 0)
    8000320e:	00054963          	bltz	a0,80003220 <sys_pause_system+0x2a>
    pause_system(seconds);
    80003212:	fec42503          	lw	a0,-20(s0)
    80003216:	fffff097          	auipc	ra,0xfffff
    8000321a:	67c080e7          	jalr	1660(ra) # 80002892 <pause_system>
    return 0;
    8000321e:	4781                	li	a5,0
}
    80003220:	853e                	mv	a0,a5
    80003222:	60e2                	ld	ra,24(sp)
    80003224:	6442                	ld	s0,16(sp)
    80003226:	6105                	addi	sp,sp,32
    80003228:	8082                	ret

000000008000322a <sys_kill_system>:

uint64 sys_kill_system(void){
    8000322a:	1141                	addi	sp,sp,-16
    8000322c:	e406                	sd	ra,8(sp)
    8000322e:	e022                	sd	s0,0(sp)
    80003230:	0800                	addi	s0,sp,16
    kill_system();
    80003232:	fffff097          	auipc	ra,0xfffff
    80003236:	5f4080e7          	jalr	1524(ra) # 80002826 <kill_system>
    return 0;
}
    8000323a:	4501                	li	a0,0
    8000323c:	60a2                	ld	ra,8(sp)
    8000323e:	6402                	ld	s0,0(sp)
    80003240:	0141                	addi	sp,sp,16
    80003242:	8082                	ret

0000000080003244 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80003244:	7179                	addi	sp,sp,-48
    80003246:	f406                	sd	ra,40(sp)
    80003248:	f022                	sd	s0,32(sp)
    8000324a:	ec26                	sd	s1,24(sp)
    8000324c:	e84a                	sd	s2,16(sp)
    8000324e:	e44e                	sd	s3,8(sp)
    80003250:	e052                	sd	s4,0(sp)
    80003252:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80003254:	00005597          	auipc	a1,0x5
    80003258:	38458593          	addi	a1,a1,900 # 800085d8 <syscalls+0xc0>
    8000325c:	00014517          	auipc	a0,0x14
    80003260:	6ac50513          	addi	a0,a0,1708 # 80017908 <bcache>
    80003264:	ffffe097          	auipc	ra,0xffffe
    80003268:	8f0080e7          	jalr	-1808(ra) # 80000b54 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    8000326c:	0001c797          	auipc	a5,0x1c
    80003270:	69c78793          	addi	a5,a5,1692 # 8001f908 <bcache+0x8000>
    80003274:	0001d717          	auipc	a4,0x1d
    80003278:	8fc70713          	addi	a4,a4,-1796 # 8001fb70 <bcache+0x8268>
    8000327c:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80003280:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003284:	00014497          	auipc	s1,0x14
    80003288:	69c48493          	addi	s1,s1,1692 # 80017920 <bcache+0x18>
    b->next = bcache.head.next;
    8000328c:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    8000328e:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80003290:	00005a17          	auipc	s4,0x5
    80003294:	350a0a13          	addi	s4,s4,848 # 800085e0 <syscalls+0xc8>
    b->next = bcache.head.next;
    80003298:	2b893783          	ld	a5,696(s2)
    8000329c:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    8000329e:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    800032a2:	85d2                	mv	a1,s4
    800032a4:	01048513          	addi	a0,s1,16
    800032a8:	00001097          	auipc	ra,0x1
    800032ac:	4bc080e7          	jalr	1212(ra) # 80004764 <initsleeplock>
    bcache.head.next->prev = b;
    800032b0:	2b893783          	ld	a5,696(s2)
    800032b4:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    800032b6:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    800032ba:	45848493          	addi	s1,s1,1112
    800032be:	fd349de3          	bne	s1,s3,80003298 <binit+0x54>
  }
}
    800032c2:	70a2                	ld	ra,40(sp)
    800032c4:	7402                	ld	s0,32(sp)
    800032c6:	64e2                	ld	s1,24(sp)
    800032c8:	6942                	ld	s2,16(sp)
    800032ca:	69a2                	ld	s3,8(sp)
    800032cc:	6a02                	ld	s4,0(sp)
    800032ce:	6145                	addi	sp,sp,48
    800032d0:	8082                	ret

00000000800032d2 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    800032d2:	7179                	addi	sp,sp,-48
    800032d4:	f406                	sd	ra,40(sp)
    800032d6:	f022                	sd	s0,32(sp)
    800032d8:	ec26                	sd	s1,24(sp)
    800032da:	e84a                	sd	s2,16(sp)
    800032dc:	e44e                	sd	s3,8(sp)
    800032de:	1800                	addi	s0,sp,48
    800032e0:	89aa                	mv	s3,a0
    800032e2:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    800032e4:	00014517          	auipc	a0,0x14
    800032e8:	62450513          	addi	a0,a0,1572 # 80017908 <bcache>
    800032ec:	ffffe097          	auipc	ra,0xffffe
    800032f0:	8f8080e7          	jalr	-1800(ra) # 80000be4 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    800032f4:	0001d497          	auipc	s1,0x1d
    800032f8:	8cc4b483          	ld	s1,-1844(s1) # 8001fbc0 <bcache+0x82b8>
    800032fc:	0001d797          	auipc	a5,0x1d
    80003300:	87478793          	addi	a5,a5,-1932 # 8001fb70 <bcache+0x8268>
    80003304:	02f48f63          	beq	s1,a5,80003342 <bread+0x70>
    80003308:	873e                	mv	a4,a5
    8000330a:	a021                	j	80003312 <bread+0x40>
    8000330c:	68a4                	ld	s1,80(s1)
    8000330e:	02e48a63          	beq	s1,a4,80003342 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80003312:	449c                	lw	a5,8(s1)
    80003314:	ff379ce3          	bne	a5,s3,8000330c <bread+0x3a>
    80003318:	44dc                	lw	a5,12(s1)
    8000331a:	ff2799e3          	bne	a5,s2,8000330c <bread+0x3a>
      b->refcnt++;
    8000331e:	40bc                	lw	a5,64(s1)
    80003320:	2785                	addiw	a5,a5,1
    80003322:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003324:	00014517          	auipc	a0,0x14
    80003328:	5e450513          	addi	a0,a0,1508 # 80017908 <bcache>
    8000332c:	ffffe097          	auipc	ra,0xffffe
    80003330:	96c080e7          	jalr	-1684(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    80003334:	01048513          	addi	a0,s1,16
    80003338:	00001097          	auipc	ra,0x1
    8000333c:	466080e7          	jalr	1126(ra) # 8000479e <acquiresleep>
      return b;
    80003340:	a8b9                	j	8000339e <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003342:	0001d497          	auipc	s1,0x1d
    80003346:	8764b483          	ld	s1,-1930(s1) # 8001fbb8 <bcache+0x82b0>
    8000334a:	0001d797          	auipc	a5,0x1d
    8000334e:	82678793          	addi	a5,a5,-2010 # 8001fb70 <bcache+0x8268>
    80003352:	00f48863          	beq	s1,a5,80003362 <bread+0x90>
    80003356:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80003358:	40bc                	lw	a5,64(s1)
    8000335a:	cf81                	beqz	a5,80003372 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    8000335c:	64a4                	ld	s1,72(s1)
    8000335e:	fee49de3          	bne	s1,a4,80003358 <bread+0x86>
  panic("bget: no buffers");
    80003362:	00005517          	auipc	a0,0x5
    80003366:	28650513          	addi	a0,a0,646 # 800085e8 <syscalls+0xd0>
    8000336a:	ffffd097          	auipc	ra,0xffffd
    8000336e:	1d4080e7          	jalr	468(ra) # 8000053e <panic>
      b->dev = dev;
    80003372:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    80003376:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    8000337a:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    8000337e:	4785                	li	a5,1
    80003380:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003382:	00014517          	auipc	a0,0x14
    80003386:	58650513          	addi	a0,a0,1414 # 80017908 <bcache>
    8000338a:	ffffe097          	auipc	ra,0xffffe
    8000338e:	90e080e7          	jalr	-1778(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    80003392:	01048513          	addi	a0,s1,16
    80003396:	00001097          	auipc	ra,0x1
    8000339a:	408080e7          	jalr	1032(ra) # 8000479e <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    8000339e:	409c                	lw	a5,0(s1)
    800033a0:	cb89                	beqz	a5,800033b2 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    800033a2:	8526                	mv	a0,s1
    800033a4:	70a2                	ld	ra,40(sp)
    800033a6:	7402                	ld	s0,32(sp)
    800033a8:	64e2                	ld	s1,24(sp)
    800033aa:	6942                	ld	s2,16(sp)
    800033ac:	69a2                	ld	s3,8(sp)
    800033ae:	6145                	addi	sp,sp,48
    800033b0:	8082                	ret
    virtio_disk_rw(b, 0);
    800033b2:	4581                	li	a1,0
    800033b4:	8526                	mv	a0,s1
    800033b6:	00003097          	auipc	ra,0x3
    800033ba:	f10080e7          	jalr	-240(ra) # 800062c6 <virtio_disk_rw>
    b->valid = 1;
    800033be:	4785                	li	a5,1
    800033c0:	c09c                	sw	a5,0(s1)
  return b;
    800033c2:	b7c5                	j	800033a2 <bread+0xd0>

00000000800033c4 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    800033c4:	1101                	addi	sp,sp,-32
    800033c6:	ec06                	sd	ra,24(sp)
    800033c8:	e822                	sd	s0,16(sp)
    800033ca:	e426                	sd	s1,8(sp)
    800033cc:	1000                	addi	s0,sp,32
    800033ce:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800033d0:	0541                	addi	a0,a0,16
    800033d2:	00001097          	auipc	ra,0x1
    800033d6:	466080e7          	jalr	1126(ra) # 80004838 <holdingsleep>
    800033da:	cd01                	beqz	a0,800033f2 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    800033dc:	4585                	li	a1,1
    800033de:	8526                	mv	a0,s1
    800033e0:	00003097          	auipc	ra,0x3
    800033e4:	ee6080e7          	jalr	-282(ra) # 800062c6 <virtio_disk_rw>
}
    800033e8:	60e2                	ld	ra,24(sp)
    800033ea:	6442                	ld	s0,16(sp)
    800033ec:	64a2                	ld	s1,8(sp)
    800033ee:	6105                	addi	sp,sp,32
    800033f0:	8082                	ret
    panic("bwrite");
    800033f2:	00005517          	auipc	a0,0x5
    800033f6:	20e50513          	addi	a0,a0,526 # 80008600 <syscalls+0xe8>
    800033fa:	ffffd097          	auipc	ra,0xffffd
    800033fe:	144080e7          	jalr	324(ra) # 8000053e <panic>

0000000080003402 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80003402:	1101                	addi	sp,sp,-32
    80003404:	ec06                	sd	ra,24(sp)
    80003406:	e822                	sd	s0,16(sp)
    80003408:	e426                	sd	s1,8(sp)
    8000340a:	e04a                	sd	s2,0(sp)
    8000340c:	1000                	addi	s0,sp,32
    8000340e:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003410:	01050913          	addi	s2,a0,16
    80003414:	854a                	mv	a0,s2
    80003416:	00001097          	auipc	ra,0x1
    8000341a:	422080e7          	jalr	1058(ra) # 80004838 <holdingsleep>
    8000341e:	c92d                	beqz	a0,80003490 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    80003420:	854a                	mv	a0,s2
    80003422:	00001097          	auipc	ra,0x1
    80003426:	3d2080e7          	jalr	978(ra) # 800047f4 <releasesleep>

  acquire(&bcache.lock);
    8000342a:	00014517          	auipc	a0,0x14
    8000342e:	4de50513          	addi	a0,a0,1246 # 80017908 <bcache>
    80003432:	ffffd097          	auipc	ra,0xffffd
    80003436:	7b2080e7          	jalr	1970(ra) # 80000be4 <acquire>
  b->refcnt--;
    8000343a:	40bc                	lw	a5,64(s1)
    8000343c:	37fd                	addiw	a5,a5,-1
    8000343e:	0007871b          	sext.w	a4,a5
    80003442:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80003444:	eb05                	bnez	a4,80003474 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80003446:	68bc                	ld	a5,80(s1)
    80003448:	64b8                	ld	a4,72(s1)
    8000344a:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    8000344c:	64bc                	ld	a5,72(s1)
    8000344e:	68b8                	ld	a4,80(s1)
    80003450:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80003452:	0001c797          	auipc	a5,0x1c
    80003456:	4b678793          	addi	a5,a5,1206 # 8001f908 <bcache+0x8000>
    8000345a:	2b87b703          	ld	a4,696(a5)
    8000345e:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80003460:	0001c717          	auipc	a4,0x1c
    80003464:	71070713          	addi	a4,a4,1808 # 8001fb70 <bcache+0x8268>
    80003468:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    8000346a:	2b87b703          	ld	a4,696(a5)
    8000346e:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80003470:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    80003474:	00014517          	auipc	a0,0x14
    80003478:	49450513          	addi	a0,a0,1172 # 80017908 <bcache>
    8000347c:	ffffe097          	auipc	ra,0xffffe
    80003480:	81c080e7          	jalr	-2020(ra) # 80000c98 <release>
}
    80003484:	60e2                	ld	ra,24(sp)
    80003486:	6442                	ld	s0,16(sp)
    80003488:	64a2                	ld	s1,8(sp)
    8000348a:	6902                	ld	s2,0(sp)
    8000348c:	6105                	addi	sp,sp,32
    8000348e:	8082                	ret
    panic("brelse");
    80003490:	00005517          	auipc	a0,0x5
    80003494:	17850513          	addi	a0,a0,376 # 80008608 <syscalls+0xf0>
    80003498:	ffffd097          	auipc	ra,0xffffd
    8000349c:	0a6080e7          	jalr	166(ra) # 8000053e <panic>

00000000800034a0 <bpin>:

void
bpin(struct buf *b) {
    800034a0:	1101                	addi	sp,sp,-32
    800034a2:	ec06                	sd	ra,24(sp)
    800034a4:	e822                	sd	s0,16(sp)
    800034a6:	e426                	sd	s1,8(sp)
    800034a8:	1000                	addi	s0,sp,32
    800034aa:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800034ac:	00014517          	auipc	a0,0x14
    800034b0:	45c50513          	addi	a0,a0,1116 # 80017908 <bcache>
    800034b4:	ffffd097          	auipc	ra,0xffffd
    800034b8:	730080e7          	jalr	1840(ra) # 80000be4 <acquire>
  b->refcnt++;
    800034bc:	40bc                	lw	a5,64(s1)
    800034be:	2785                	addiw	a5,a5,1
    800034c0:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800034c2:	00014517          	auipc	a0,0x14
    800034c6:	44650513          	addi	a0,a0,1094 # 80017908 <bcache>
    800034ca:	ffffd097          	auipc	ra,0xffffd
    800034ce:	7ce080e7          	jalr	1998(ra) # 80000c98 <release>
}
    800034d2:	60e2                	ld	ra,24(sp)
    800034d4:	6442                	ld	s0,16(sp)
    800034d6:	64a2                	ld	s1,8(sp)
    800034d8:	6105                	addi	sp,sp,32
    800034da:	8082                	ret

00000000800034dc <bunpin>:

void
bunpin(struct buf *b) {
    800034dc:	1101                	addi	sp,sp,-32
    800034de:	ec06                	sd	ra,24(sp)
    800034e0:	e822                	sd	s0,16(sp)
    800034e2:	e426                	sd	s1,8(sp)
    800034e4:	1000                	addi	s0,sp,32
    800034e6:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800034e8:	00014517          	auipc	a0,0x14
    800034ec:	42050513          	addi	a0,a0,1056 # 80017908 <bcache>
    800034f0:	ffffd097          	auipc	ra,0xffffd
    800034f4:	6f4080e7          	jalr	1780(ra) # 80000be4 <acquire>
  b->refcnt--;
    800034f8:	40bc                	lw	a5,64(s1)
    800034fa:	37fd                	addiw	a5,a5,-1
    800034fc:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800034fe:	00014517          	auipc	a0,0x14
    80003502:	40a50513          	addi	a0,a0,1034 # 80017908 <bcache>
    80003506:	ffffd097          	auipc	ra,0xffffd
    8000350a:	792080e7          	jalr	1938(ra) # 80000c98 <release>
}
    8000350e:	60e2                	ld	ra,24(sp)
    80003510:	6442                	ld	s0,16(sp)
    80003512:	64a2                	ld	s1,8(sp)
    80003514:	6105                	addi	sp,sp,32
    80003516:	8082                	ret

0000000080003518 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80003518:	1101                	addi	sp,sp,-32
    8000351a:	ec06                	sd	ra,24(sp)
    8000351c:	e822                	sd	s0,16(sp)
    8000351e:	e426                	sd	s1,8(sp)
    80003520:	e04a                	sd	s2,0(sp)
    80003522:	1000                	addi	s0,sp,32
    80003524:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80003526:	00d5d59b          	srliw	a1,a1,0xd
    8000352a:	0001d797          	auipc	a5,0x1d
    8000352e:	aba7a783          	lw	a5,-1350(a5) # 8001ffe4 <sb+0x1c>
    80003532:	9dbd                	addw	a1,a1,a5
    80003534:	00000097          	auipc	ra,0x0
    80003538:	d9e080e7          	jalr	-610(ra) # 800032d2 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    8000353c:	0074f713          	andi	a4,s1,7
    80003540:	4785                	li	a5,1
    80003542:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80003546:	14ce                	slli	s1,s1,0x33
    80003548:	90d9                	srli	s1,s1,0x36
    8000354a:	00950733          	add	a4,a0,s1
    8000354e:	05874703          	lbu	a4,88(a4)
    80003552:	00e7f6b3          	and	a3,a5,a4
    80003556:	c69d                	beqz	a3,80003584 <bfree+0x6c>
    80003558:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    8000355a:	94aa                	add	s1,s1,a0
    8000355c:	fff7c793          	not	a5,a5
    80003560:	8ff9                	and	a5,a5,a4
    80003562:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    80003566:	00001097          	auipc	ra,0x1
    8000356a:	118080e7          	jalr	280(ra) # 8000467e <log_write>
  brelse(bp);
    8000356e:	854a                	mv	a0,s2
    80003570:	00000097          	auipc	ra,0x0
    80003574:	e92080e7          	jalr	-366(ra) # 80003402 <brelse>
}
    80003578:	60e2                	ld	ra,24(sp)
    8000357a:	6442                	ld	s0,16(sp)
    8000357c:	64a2                	ld	s1,8(sp)
    8000357e:	6902                	ld	s2,0(sp)
    80003580:	6105                	addi	sp,sp,32
    80003582:	8082                	ret
    panic("freeing free block");
    80003584:	00005517          	auipc	a0,0x5
    80003588:	08c50513          	addi	a0,a0,140 # 80008610 <syscalls+0xf8>
    8000358c:	ffffd097          	auipc	ra,0xffffd
    80003590:	fb2080e7          	jalr	-78(ra) # 8000053e <panic>

0000000080003594 <balloc>:
{
    80003594:	711d                	addi	sp,sp,-96
    80003596:	ec86                	sd	ra,88(sp)
    80003598:	e8a2                	sd	s0,80(sp)
    8000359a:	e4a6                	sd	s1,72(sp)
    8000359c:	e0ca                	sd	s2,64(sp)
    8000359e:	fc4e                	sd	s3,56(sp)
    800035a0:	f852                	sd	s4,48(sp)
    800035a2:	f456                	sd	s5,40(sp)
    800035a4:	f05a                	sd	s6,32(sp)
    800035a6:	ec5e                	sd	s7,24(sp)
    800035a8:	e862                	sd	s8,16(sp)
    800035aa:	e466                	sd	s9,8(sp)
    800035ac:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    800035ae:	0001d797          	auipc	a5,0x1d
    800035b2:	a1e7a783          	lw	a5,-1506(a5) # 8001ffcc <sb+0x4>
    800035b6:	cbd1                	beqz	a5,8000364a <balloc+0xb6>
    800035b8:	8baa                	mv	s7,a0
    800035ba:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    800035bc:	0001db17          	auipc	s6,0x1d
    800035c0:	a0cb0b13          	addi	s6,s6,-1524 # 8001ffc8 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800035c4:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    800035c6:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800035c8:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    800035ca:	6c89                	lui	s9,0x2
    800035cc:	a831                	j	800035e8 <balloc+0x54>
    brelse(bp);
    800035ce:	854a                	mv	a0,s2
    800035d0:	00000097          	auipc	ra,0x0
    800035d4:	e32080e7          	jalr	-462(ra) # 80003402 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    800035d8:	015c87bb          	addw	a5,s9,s5
    800035dc:	00078a9b          	sext.w	s5,a5
    800035e0:	004b2703          	lw	a4,4(s6)
    800035e4:	06eaf363          	bgeu	s5,a4,8000364a <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    800035e8:	41fad79b          	sraiw	a5,s5,0x1f
    800035ec:	0137d79b          	srliw	a5,a5,0x13
    800035f0:	015787bb          	addw	a5,a5,s5
    800035f4:	40d7d79b          	sraiw	a5,a5,0xd
    800035f8:	01cb2583          	lw	a1,28(s6)
    800035fc:	9dbd                	addw	a1,a1,a5
    800035fe:	855e                	mv	a0,s7
    80003600:	00000097          	auipc	ra,0x0
    80003604:	cd2080e7          	jalr	-814(ra) # 800032d2 <bread>
    80003608:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000360a:	004b2503          	lw	a0,4(s6)
    8000360e:	000a849b          	sext.w	s1,s5
    80003612:	8662                	mv	a2,s8
    80003614:	faa4fde3          	bgeu	s1,a0,800035ce <balloc+0x3a>
      m = 1 << (bi % 8);
    80003618:	41f6579b          	sraiw	a5,a2,0x1f
    8000361c:	01d7d69b          	srliw	a3,a5,0x1d
    80003620:	00c6873b          	addw	a4,a3,a2
    80003624:	00777793          	andi	a5,a4,7
    80003628:	9f95                	subw	a5,a5,a3
    8000362a:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    8000362e:	4037571b          	sraiw	a4,a4,0x3
    80003632:	00e906b3          	add	a3,s2,a4
    80003636:	0586c683          	lbu	a3,88(a3)
    8000363a:	00d7f5b3          	and	a1,a5,a3
    8000363e:	cd91                	beqz	a1,8000365a <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003640:	2605                	addiw	a2,a2,1
    80003642:	2485                	addiw	s1,s1,1
    80003644:	fd4618e3          	bne	a2,s4,80003614 <balloc+0x80>
    80003648:	b759                	j	800035ce <balloc+0x3a>
  panic("balloc: out of blocks");
    8000364a:	00005517          	auipc	a0,0x5
    8000364e:	fde50513          	addi	a0,a0,-34 # 80008628 <syscalls+0x110>
    80003652:	ffffd097          	auipc	ra,0xffffd
    80003656:	eec080e7          	jalr	-276(ra) # 8000053e <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    8000365a:	974a                	add	a4,a4,s2
    8000365c:	8fd5                	or	a5,a5,a3
    8000365e:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    80003662:	854a                	mv	a0,s2
    80003664:	00001097          	auipc	ra,0x1
    80003668:	01a080e7          	jalr	26(ra) # 8000467e <log_write>
        brelse(bp);
    8000366c:	854a                	mv	a0,s2
    8000366e:	00000097          	auipc	ra,0x0
    80003672:	d94080e7          	jalr	-620(ra) # 80003402 <brelse>
  bp = bread(dev, bno);
    80003676:	85a6                	mv	a1,s1
    80003678:	855e                	mv	a0,s7
    8000367a:	00000097          	auipc	ra,0x0
    8000367e:	c58080e7          	jalr	-936(ra) # 800032d2 <bread>
    80003682:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80003684:	40000613          	li	a2,1024
    80003688:	4581                	li	a1,0
    8000368a:	05850513          	addi	a0,a0,88
    8000368e:	ffffd097          	auipc	ra,0xffffd
    80003692:	652080e7          	jalr	1618(ra) # 80000ce0 <memset>
  log_write(bp);
    80003696:	854a                	mv	a0,s2
    80003698:	00001097          	auipc	ra,0x1
    8000369c:	fe6080e7          	jalr	-26(ra) # 8000467e <log_write>
  brelse(bp);
    800036a0:	854a                	mv	a0,s2
    800036a2:	00000097          	auipc	ra,0x0
    800036a6:	d60080e7          	jalr	-672(ra) # 80003402 <brelse>
}
    800036aa:	8526                	mv	a0,s1
    800036ac:	60e6                	ld	ra,88(sp)
    800036ae:	6446                	ld	s0,80(sp)
    800036b0:	64a6                	ld	s1,72(sp)
    800036b2:	6906                	ld	s2,64(sp)
    800036b4:	79e2                	ld	s3,56(sp)
    800036b6:	7a42                	ld	s4,48(sp)
    800036b8:	7aa2                	ld	s5,40(sp)
    800036ba:	7b02                	ld	s6,32(sp)
    800036bc:	6be2                	ld	s7,24(sp)
    800036be:	6c42                	ld	s8,16(sp)
    800036c0:	6ca2                	ld	s9,8(sp)
    800036c2:	6125                	addi	sp,sp,96
    800036c4:	8082                	ret

00000000800036c6 <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    800036c6:	7179                	addi	sp,sp,-48
    800036c8:	f406                	sd	ra,40(sp)
    800036ca:	f022                	sd	s0,32(sp)
    800036cc:	ec26                	sd	s1,24(sp)
    800036ce:	e84a                	sd	s2,16(sp)
    800036d0:	e44e                	sd	s3,8(sp)
    800036d2:	e052                	sd	s4,0(sp)
    800036d4:	1800                	addi	s0,sp,48
    800036d6:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    800036d8:	47ad                	li	a5,11
    800036da:	04b7fe63          	bgeu	a5,a1,80003736 <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    800036de:	ff45849b          	addiw	s1,a1,-12
    800036e2:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    800036e6:	0ff00793          	li	a5,255
    800036ea:	0ae7e363          	bltu	a5,a4,80003790 <bmap+0xca>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    800036ee:	08052583          	lw	a1,128(a0)
    800036f2:	c5ad                	beqz	a1,8000375c <bmap+0x96>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    800036f4:	00092503          	lw	a0,0(s2)
    800036f8:	00000097          	auipc	ra,0x0
    800036fc:	bda080e7          	jalr	-1062(ra) # 800032d2 <bread>
    80003700:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003702:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003706:	02049593          	slli	a1,s1,0x20
    8000370a:	9181                	srli	a1,a1,0x20
    8000370c:	058a                	slli	a1,a1,0x2
    8000370e:	00b784b3          	add	s1,a5,a1
    80003712:	0004a983          	lw	s3,0(s1)
    80003716:	04098d63          	beqz	s3,80003770 <bmap+0xaa>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    8000371a:	8552                	mv	a0,s4
    8000371c:	00000097          	auipc	ra,0x0
    80003720:	ce6080e7          	jalr	-794(ra) # 80003402 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80003724:	854e                	mv	a0,s3
    80003726:	70a2                	ld	ra,40(sp)
    80003728:	7402                	ld	s0,32(sp)
    8000372a:	64e2                	ld	s1,24(sp)
    8000372c:	6942                	ld	s2,16(sp)
    8000372e:	69a2                	ld	s3,8(sp)
    80003730:	6a02                	ld	s4,0(sp)
    80003732:	6145                	addi	sp,sp,48
    80003734:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    80003736:	02059493          	slli	s1,a1,0x20
    8000373a:	9081                	srli	s1,s1,0x20
    8000373c:	048a                	slli	s1,s1,0x2
    8000373e:	94aa                	add	s1,s1,a0
    80003740:	0504a983          	lw	s3,80(s1)
    80003744:	fe0990e3          	bnez	s3,80003724 <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    80003748:	4108                	lw	a0,0(a0)
    8000374a:	00000097          	auipc	ra,0x0
    8000374e:	e4a080e7          	jalr	-438(ra) # 80003594 <balloc>
    80003752:	0005099b          	sext.w	s3,a0
    80003756:	0534a823          	sw	s3,80(s1)
    8000375a:	b7e9                	j	80003724 <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    8000375c:	4108                	lw	a0,0(a0)
    8000375e:	00000097          	auipc	ra,0x0
    80003762:	e36080e7          	jalr	-458(ra) # 80003594 <balloc>
    80003766:	0005059b          	sext.w	a1,a0
    8000376a:	08b92023          	sw	a1,128(s2)
    8000376e:	b759                	j	800036f4 <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    80003770:	00092503          	lw	a0,0(s2)
    80003774:	00000097          	auipc	ra,0x0
    80003778:	e20080e7          	jalr	-480(ra) # 80003594 <balloc>
    8000377c:	0005099b          	sext.w	s3,a0
    80003780:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    80003784:	8552                	mv	a0,s4
    80003786:	00001097          	auipc	ra,0x1
    8000378a:	ef8080e7          	jalr	-264(ra) # 8000467e <log_write>
    8000378e:	b771                	j	8000371a <bmap+0x54>
  panic("bmap: out of range");
    80003790:	00005517          	auipc	a0,0x5
    80003794:	eb050513          	addi	a0,a0,-336 # 80008640 <syscalls+0x128>
    80003798:	ffffd097          	auipc	ra,0xffffd
    8000379c:	da6080e7          	jalr	-602(ra) # 8000053e <panic>

00000000800037a0 <iget>:
{
    800037a0:	7179                	addi	sp,sp,-48
    800037a2:	f406                	sd	ra,40(sp)
    800037a4:	f022                	sd	s0,32(sp)
    800037a6:	ec26                	sd	s1,24(sp)
    800037a8:	e84a                	sd	s2,16(sp)
    800037aa:	e44e                	sd	s3,8(sp)
    800037ac:	e052                	sd	s4,0(sp)
    800037ae:	1800                	addi	s0,sp,48
    800037b0:	89aa                	mv	s3,a0
    800037b2:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    800037b4:	0001d517          	auipc	a0,0x1d
    800037b8:	83450513          	addi	a0,a0,-1996 # 8001ffe8 <itable>
    800037bc:	ffffd097          	auipc	ra,0xffffd
    800037c0:	428080e7          	jalr	1064(ra) # 80000be4 <acquire>
  empty = 0;
    800037c4:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800037c6:	0001d497          	auipc	s1,0x1d
    800037ca:	83a48493          	addi	s1,s1,-1990 # 80020000 <itable+0x18>
    800037ce:	0001e697          	auipc	a3,0x1e
    800037d2:	2c268693          	addi	a3,a3,706 # 80021a90 <log>
    800037d6:	a039                	j	800037e4 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800037d8:	02090b63          	beqz	s2,8000380e <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800037dc:	08848493          	addi	s1,s1,136
    800037e0:	02d48a63          	beq	s1,a3,80003814 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    800037e4:	449c                	lw	a5,8(s1)
    800037e6:	fef059e3          	blez	a5,800037d8 <iget+0x38>
    800037ea:	4098                	lw	a4,0(s1)
    800037ec:	ff3716e3          	bne	a4,s3,800037d8 <iget+0x38>
    800037f0:	40d8                	lw	a4,4(s1)
    800037f2:	ff4713e3          	bne	a4,s4,800037d8 <iget+0x38>
      ip->ref++;
    800037f6:	2785                	addiw	a5,a5,1
    800037f8:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    800037fa:	0001c517          	auipc	a0,0x1c
    800037fe:	7ee50513          	addi	a0,a0,2030 # 8001ffe8 <itable>
    80003802:	ffffd097          	auipc	ra,0xffffd
    80003806:	496080e7          	jalr	1174(ra) # 80000c98 <release>
      return ip;
    8000380a:	8926                	mv	s2,s1
    8000380c:	a03d                	j	8000383a <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    8000380e:	f7f9                	bnez	a5,800037dc <iget+0x3c>
    80003810:	8926                	mv	s2,s1
    80003812:	b7e9                	j	800037dc <iget+0x3c>
  if(empty == 0)
    80003814:	02090c63          	beqz	s2,8000384c <iget+0xac>
  ip->dev = dev;
    80003818:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    8000381c:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003820:	4785                	li	a5,1
    80003822:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003826:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    8000382a:	0001c517          	auipc	a0,0x1c
    8000382e:	7be50513          	addi	a0,a0,1982 # 8001ffe8 <itable>
    80003832:	ffffd097          	auipc	ra,0xffffd
    80003836:	466080e7          	jalr	1126(ra) # 80000c98 <release>
}
    8000383a:	854a                	mv	a0,s2
    8000383c:	70a2                	ld	ra,40(sp)
    8000383e:	7402                	ld	s0,32(sp)
    80003840:	64e2                	ld	s1,24(sp)
    80003842:	6942                	ld	s2,16(sp)
    80003844:	69a2                	ld	s3,8(sp)
    80003846:	6a02                	ld	s4,0(sp)
    80003848:	6145                	addi	sp,sp,48
    8000384a:	8082                	ret
    panic("iget: no inodes");
    8000384c:	00005517          	auipc	a0,0x5
    80003850:	e0c50513          	addi	a0,a0,-500 # 80008658 <syscalls+0x140>
    80003854:	ffffd097          	auipc	ra,0xffffd
    80003858:	cea080e7          	jalr	-790(ra) # 8000053e <panic>

000000008000385c <fsinit>:
fsinit(int dev) {
    8000385c:	7179                	addi	sp,sp,-48
    8000385e:	f406                	sd	ra,40(sp)
    80003860:	f022                	sd	s0,32(sp)
    80003862:	ec26                	sd	s1,24(sp)
    80003864:	e84a                	sd	s2,16(sp)
    80003866:	e44e                	sd	s3,8(sp)
    80003868:	1800                	addi	s0,sp,48
    8000386a:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    8000386c:	4585                	li	a1,1
    8000386e:	00000097          	auipc	ra,0x0
    80003872:	a64080e7          	jalr	-1436(ra) # 800032d2 <bread>
    80003876:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003878:	0001c997          	auipc	s3,0x1c
    8000387c:	75098993          	addi	s3,s3,1872 # 8001ffc8 <sb>
    80003880:	02000613          	li	a2,32
    80003884:	05850593          	addi	a1,a0,88
    80003888:	854e                	mv	a0,s3
    8000388a:	ffffd097          	auipc	ra,0xffffd
    8000388e:	4b6080e7          	jalr	1206(ra) # 80000d40 <memmove>
  brelse(bp);
    80003892:	8526                	mv	a0,s1
    80003894:	00000097          	auipc	ra,0x0
    80003898:	b6e080e7          	jalr	-1170(ra) # 80003402 <brelse>
  if(sb.magic != FSMAGIC)
    8000389c:	0009a703          	lw	a4,0(s3)
    800038a0:	102037b7          	lui	a5,0x10203
    800038a4:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    800038a8:	02f71263          	bne	a4,a5,800038cc <fsinit+0x70>
  initlog(dev, &sb);
    800038ac:	0001c597          	auipc	a1,0x1c
    800038b0:	71c58593          	addi	a1,a1,1820 # 8001ffc8 <sb>
    800038b4:	854a                	mv	a0,s2
    800038b6:	00001097          	auipc	ra,0x1
    800038ba:	b4c080e7          	jalr	-1204(ra) # 80004402 <initlog>
}
    800038be:	70a2                	ld	ra,40(sp)
    800038c0:	7402                	ld	s0,32(sp)
    800038c2:	64e2                	ld	s1,24(sp)
    800038c4:	6942                	ld	s2,16(sp)
    800038c6:	69a2                	ld	s3,8(sp)
    800038c8:	6145                	addi	sp,sp,48
    800038ca:	8082                	ret
    panic("invalid file system");
    800038cc:	00005517          	auipc	a0,0x5
    800038d0:	d9c50513          	addi	a0,a0,-612 # 80008668 <syscalls+0x150>
    800038d4:	ffffd097          	auipc	ra,0xffffd
    800038d8:	c6a080e7          	jalr	-918(ra) # 8000053e <panic>

00000000800038dc <iinit>:
{
    800038dc:	7179                	addi	sp,sp,-48
    800038de:	f406                	sd	ra,40(sp)
    800038e0:	f022                	sd	s0,32(sp)
    800038e2:	ec26                	sd	s1,24(sp)
    800038e4:	e84a                	sd	s2,16(sp)
    800038e6:	e44e                	sd	s3,8(sp)
    800038e8:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    800038ea:	00005597          	auipc	a1,0x5
    800038ee:	d9658593          	addi	a1,a1,-618 # 80008680 <syscalls+0x168>
    800038f2:	0001c517          	auipc	a0,0x1c
    800038f6:	6f650513          	addi	a0,a0,1782 # 8001ffe8 <itable>
    800038fa:	ffffd097          	auipc	ra,0xffffd
    800038fe:	25a080e7          	jalr	602(ra) # 80000b54 <initlock>
  for(i = 0; i < NINODE; i++) {
    80003902:	0001c497          	auipc	s1,0x1c
    80003906:	70e48493          	addi	s1,s1,1806 # 80020010 <itable+0x28>
    8000390a:	0001e997          	auipc	s3,0x1e
    8000390e:	19698993          	addi	s3,s3,406 # 80021aa0 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80003912:	00005917          	auipc	s2,0x5
    80003916:	d7690913          	addi	s2,s2,-650 # 80008688 <syscalls+0x170>
    8000391a:	85ca                	mv	a1,s2
    8000391c:	8526                	mv	a0,s1
    8000391e:	00001097          	auipc	ra,0x1
    80003922:	e46080e7          	jalr	-442(ra) # 80004764 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003926:	08848493          	addi	s1,s1,136
    8000392a:	ff3498e3          	bne	s1,s3,8000391a <iinit+0x3e>
}
    8000392e:	70a2                	ld	ra,40(sp)
    80003930:	7402                	ld	s0,32(sp)
    80003932:	64e2                	ld	s1,24(sp)
    80003934:	6942                	ld	s2,16(sp)
    80003936:	69a2                	ld	s3,8(sp)
    80003938:	6145                	addi	sp,sp,48
    8000393a:	8082                	ret

000000008000393c <ialloc>:
{
    8000393c:	715d                	addi	sp,sp,-80
    8000393e:	e486                	sd	ra,72(sp)
    80003940:	e0a2                	sd	s0,64(sp)
    80003942:	fc26                	sd	s1,56(sp)
    80003944:	f84a                	sd	s2,48(sp)
    80003946:	f44e                	sd	s3,40(sp)
    80003948:	f052                	sd	s4,32(sp)
    8000394a:	ec56                	sd	s5,24(sp)
    8000394c:	e85a                	sd	s6,16(sp)
    8000394e:	e45e                	sd	s7,8(sp)
    80003950:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003952:	0001c717          	auipc	a4,0x1c
    80003956:	68272703          	lw	a4,1666(a4) # 8001ffd4 <sb+0xc>
    8000395a:	4785                	li	a5,1
    8000395c:	04e7fa63          	bgeu	a5,a4,800039b0 <ialloc+0x74>
    80003960:	8aaa                	mv	s5,a0
    80003962:	8bae                	mv	s7,a1
    80003964:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003966:	0001ca17          	auipc	s4,0x1c
    8000396a:	662a0a13          	addi	s4,s4,1634 # 8001ffc8 <sb>
    8000396e:	00048b1b          	sext.w	s6,s1
    80003972:	0044d593          	srli	a1,s1,0x4
    80003976:	018a2783          	lw	a5,24(s4)
    8000397a:	9dbd                	addw	a1,a1,a5
    8000397c:	8556                	mv	a0,s5
    8000397e:	00000097          	auipc	ra,0x0
    80003982:	954080e7          	jalr	-1708(ra) # 800032d2 <bread>
    80003986:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003988:	05850993          	addi	s3,a0,88
    8000398c:	00f4f793          	andi	a5,s1,15
    80003990:	079a                	slli	a5,a5,0x6
    80003992:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003994:	00099783          	lh	a5,0(s3)
    80003998:	c785                	beqz	a5,800039c0 <ialloc+0x84>
    brelse(bp);
    8000399a:	00000097          	auipc	ra,0x0
    8000399e:	a68080e7          	jalr	-1432(ra) # 80003402 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    800039a2:	0485                	addi	s1,s1,1
    800039a4:	00ca2703          	lw	a4,12(s4)
    800039a8:	0004879b          	sext.w	a5,s1
    800039ac:	fce7e1e3          	bltu	a5,a4,8000396e <ialloc+0x32>
  panic("ialloc: no inodes");
    800039b0:	00005517          	auipc	a0,0x5
    800039b4:	ce050513          	addi	a0,a0,-800 # 80008690 <syscalls+0x178>
    800039b8:	ffffd097          	auipc	ra,0xffffd
    800039bc:	b86080e7          	jalr	-1146(ra) # 8000053e <panic>
      memset(dip, 0, sizeof(*dip));
    800039c0:	04000613          	li	a2,64
    800039c4:	4581                	li	a1,0
    800039c6:	854e                	mv	a0,s3
    800039c8:	ffffd097          	auipc	ra,0xffffd
    800039cc:	318080e7          	jalr	792(ra) # 80000ce0 <memset>
      dip->type = type;
    800039d0:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    800039d4:	854a                	mv	a0,s2
    800039d6:	00001097          	auipc	ra,0x1
    800039da:	ca8080e7          	jalr	-856(ra) # 8000467e <log_write>
      brelse(bp);
    800039de:	854a                	mv	a0,s2
    800039e0:	00000097          	auipc	ra,0x0
    800039e4:	a22080e7          	jalr	-1502(ra) # 80003402 <brelse>
      return iget(dev, inum);
    800039e8:	85da                	mv	a1,s6
    800039ea:	8556                	mv	a0,s5
    800039ec:	00000097          	auipc	ra,0x0
    800039f0:	db4080e7          	jalr	-588(ra) # 800037a0 <iget>
}
    800039f4:	60a6                	ld	ra,72(sp)
    800039f6:	6406                	ld	s0,64(sp)
    800039f8:	74e2                	ld	s1,56(sp)
    800039fa:	7942                	ld	s2,48(sp)
    800039fc:	79a2                	ld	s3,40(sp)
    800039fe:	7a02                	ld	s4,32(sp)
    80003a00:	6ae2                	ld	s5,24(sp)
    80003a02:	6b42                	ld	s6,16(sp)
    80003a04:	6ba2                	ld	s7,8(sp)
    80003a06:	6161                	addi	sp,sp,80
    80003a08:	8082                	ret

0000000080003a0a <iupdate>:
{
    80003a0a:	1101                	addi	sp,sp,-32
    80003a0c:	ec06                	sd	ra,24(sp)
    80003a0e:	e822                	sd	s0,16(sp)
    80003a10:	e426                	sd	s1,8(sp)
    80003a12:	e04a                	sd	s2,0(sp)
    80003a14:	1000                	addi	s0,sp,32
    80003a16:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003a18:	415c                	lw	a5,4(a0)
    80003a1a:	0047d79b          	srliw	a5,a5,0x4
    80003a1e:	0001c597          	auipc	a1,0x1c
    80003a22:	5c25a583          	lw	a1,1474(a1) # 8001ffe0 <sb+0x18>
    80003a26:	9dbd                	addw	a1,a1,a5
    80003a28:	4108                	lw	a0,0(a0)
    80003a2a:	00000097          	auipc	ra,0x0
    80003a2e:	8a8080e7          	jalr	-1880(ra) # 800032d2 <bread>
    80003a32:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003a34:	05850793          	addi	a5,a0,88
    80003a38:	40c8                	lw	a0,4(s1)
    80003a3a:	893d                	andi	a0,a0,15
    80003a3c:	051a                	slli	a0,a0,0x6
    80003a3e:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    80003a40:	04449703          	lh	a4,68(s1)
    80003a44:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    80003a48:	04649703          	lh	a4,70(s1)
    80003a4c:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    80003a50:	04849703          	lh	a4,72(s1)
    80003a54:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    80003a58:	04a49703          	lh	a4,74(s1)
    80003a5c:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    80003a60:	44f8                	lw	a4,76(s1)
    80003a62:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003a64:	03400613          	li	a2,52
    80003a68:	05048593          	addi	a1,s1,80
    80003a6c:	0531                	addi	a0,a0,12
    80003a6e:	ffffd097          	auipc	ra,0xffffd
    80003a72:	2d2080e7          	jalr	722(ra) # 80000d40 <memmove>
  log_write(bp);
    80003a76:	854a                	mv	a0,s2
    80003a78:	00001097          	auipc	ra,0x1
    80003a7c:	c06080e7          	jalr	-1018(ra) # 8000467e <log_write>
  brelse(bp);
    80003a80:	854a                	mv	a0,s2
    80003a82:	00000097          	auipc	ra,0x0
    80003a86:	980080e7          	jalr	-1664(ra) # 80003402 <brelse>
}
    80003a8a:	60e2                	ld	ra,24(sp)
    80003a8c:	6442                	ld	s0,16(sp)
    80003a8e:	64a2                	ld	s1,8(sp)
    80003a90:	6902                	ld	s2,0(sp)
    80003a92:	6105                	addi	sp,sp,32
    80003a94:	8082                	ret

0000000080003a96 <idup>:
{
    80003a96:	1101                	addi	sp,sp,-32
    80003a98:	ec06                	sd	ra,24(sp)
    80003a9a:	e822                	sd	s0,16(sp)
    80003a9c:	e426                	sd	s1,8(sp)
    80003a9e:	1000                	addi	s0,sp,32
    80003aa0:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003aa2:	0001c517          	auipc	a0,0x1c
    80003aa6:	54650513          	addi	a0,a0,1350 # 8001ffe8 <itable>
    80003aaa:	ffffd097          	auipc	ra,0xffffd
    80003aae:	13a080e7          	jalr	314(ra) # 80000be4 <acquire>
  ip->ref++;
    80003ab2:	449c                	lw	a5,8(s1)
    80003ab4:	2785                	addiw	a5,a5,1
    80003ab6:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003ab8:	0001c517          	auipc	a0,0x1c
    80003abc:	53050513          	addi	a0,a0,1328 # 8001ffe8 <itable>
    80003ac0:	ffffd097          	auipc	ra,0xffffd
    80003ac4:	1d8080e7          	jalr	472(ra) # 80000c98 <release>
}
    80003ac8:	8526                	mv	a0,s1
    80003aca:	60e2                	ld	ra,24(sp)
    80003acc:	6442                	ld	s0,16(sp)
    80003ace:	64a2                	ld	s1,8(sp)
    80003ad0:	6105                	addi	sp,sp,32
    80003ad2:	8082                	ret

0000000080003ad4 <ilock>:
{
    80003ad4:	1101                	addi	sp,sp,-32
    80003ad6:	ec06                	sd	ra,24(sp)
    80003ad8:	e822                	sd	s0,16(sp)
    80003ada:	e426                	sd	s1,8(sp)
    80003adc:	e04a                	sd	s2,0(sp)
    80003ade:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003ae0:	c115                	beqz	a0,80003b04 <ilock+0x30>
    80003ae2:	84aa                	mv	s1,a0
    80003ae4:	451c                	lw	a5,8(a0)
    80003ae6:	00f05f63          	blez	a5,80003b04 <ilock+0x30>
  acquiresleep(&ip->lock);
    80003aea:	0541                	addi	a0,a0,16
    80003aec:	00001097          	auipc	ra,0x1
    80003af0:	cb2080e7          	jalr	-846(ra) # 8000479e <acquiresleep>
  if(ip->valid == 0){
    80003af4:	40bc                	lw	a5,64(s1)
    80003af6:	cf99                	beqz	a5,80003b14 <ilock+0x40>
}
    80003af8:	60e2                	ld	ra,24(sp)
    80003afa:	6442                	ld	s0,16(sp)
    80003afc:	64a2                	ld	s1,8(sp)
    80003afe:	6902                	ld	s2,0(sp)
    80003b00:	6105                	addi	sp,sp,32
    80003b02:	8082                	ret
    panic("ilock");
    80003b04:	00005517          	auipc	a0,0x5
    80003b08:	ba450513          	addi	a0,a0,-1116 # 800086a8 <syscalls+0x190>
    80003b0c:	ffffd097          	auipc	ra,0xffffd
    80003b10:	a32080e7          	jalr	-1486(ra) # 8000053e <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003b14:	40dc                	lw	a5,4(s1)
    80003b16:	0047d79b          	srliw	a5,a5,0x4
    80003b1a:	0001c597          	auipc	a1,0x1c
    80003b1e:	4c65a583          	lw	a1,1222(a1) # 8001ffe0 <sb+0x18>
    80003b22:	9dbd                	addw	a1,a1,a5
    80003b24:	4088                	lw	a0,0(s1)
    80003b26:	fffff097          	auipc	ra,0xfffff
    80003b2a:	7ac080e7          	jalr	1964(ra) # 800032d2 <bread>
    80003b2e:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003b30:	05850593          	addi	a1,a0,88
    80003b34:	40dc                	lw	a5,4(s1)
    80003b36:	8bbd                	andi	a5,a5,15
    80003b38:	079a                	slli	a5,a5,0x6
    80003b3a:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003b3c:	00059783          	lh	a5,0(a1)
    80003b40:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003b44:	00259783          	lh	a5,2(a1)
    80003b48:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003b4c:	00459783          	lh	a5,4(a1)
    80003b50:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003b54:	00659783          	lh	a5,6(a1)
    80003b58:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003b5c:	459c                	lw	a5,8(a1)
    80003b5e:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003b60:	03400613          	li	a2,52
    80003b64:	05b1                	addi	a1,a1,12
    80003b66:	05048513          	addi	a0,s1,80
    80003b6a:	ffffd097          	auipc	ra,0xffffd
    80003b6e:	1d6080e7          	jalr	470(ra) # 80000d40 <memmove>
    brelse(bp);
    80003b72:	854a                	mv	a0,s2
    80003b74:	00000097          	auipc	ra,0x0
    80003b78:	88e080e7          	jalr	-1906(ra) # 80003402 <brelse>
    ip->valid = 1;
    80003b7c:	4785                	li	a5,1
    80003b7e:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003b80:	04449783          	lh	a5,68(s1)
    80003b84:	fbb5                	bnez	a5,80003af8 <ilock+0x24>
      panic("ilock: no type");
    80003b86:	00005517          	auipc	a0,0x5
    80003b8a:	b2a50513          	addi	a0,a0,-1238 # 800086b0 <syscalls+0x198>
    80003b8e:	ffffd097          	auipc	ra,0xffffd
    80003b92:	9b0080e7          	jalr	-1616(ra) # 8000053e <panic>

0000000080003b96 <iunlock>:
{
    80003b96:	1101                	addi	sp,sp,-32
    80003b98:	ec06                	sd	ra,24(sp)
    80003b9a:	e822                	sd	s0,16(sp)
    80003b9c:	e426                	sd	s1,8(sp)
    80003b9e:	e04a                	sd	s2,0(sp)
    80003ba0:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003ba2:	c905                	beqz	a0,80003bd2 <iunlock+0x3c>
    80003ba4:	84aa                	mv	s1,a0
    80003ba6:	01050913          	addi	s2,a0,16
    80003baa:	854a                	mv	a0,s2
    80003bac:	00001097          	auipc	ra,0x1
    80003bb0:	c8c080e7          	jalr	-884(ra) # 80004838 <holdingsleep>
    80003bb4:	cd19                	beqz	a0,80003bd2 <iunlock+0x3c>
    80003bb6:	449c                	lw	a5,8(s1)
    80003bb8:	00f05d63          	blez	a5,80003bd2 <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003bbc:	854a                	mv	a0,s2
    80003bbe:	00001097          	auipc	ra,0x1
    80003bc2:	c36080e7          	jalr	-970(ra) # 800047f4 <releasesleep>
}
    80003bc6:	60e2                	ld	ra,24(sp)
    80003bc8:	6442                	ld	s0,16(sp)
    80003bca:	64a2                	ld	s1,8(sp)
    80003bcc:	6902                	ld	s2,0(sp)
    80003bce:	6105                	addi	sp,sp,32
    80003bd0:	8082                	ret
    panic("iunlock");
    80003bd2:	00005517          	auipc	a0,0x5
    80003bd6:	aee50513          	addi	a0,a0,-1298 # 800086c0 <syscalls+0x1a8>
    80003bda:	ffffd097          	auipc	ra,0xffffd
    80003bde:	964080e7          	jalr	-1692(ra) # 8000053e <panic>

0000000080003be2 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003be2:	7179                	addi	sp,sp,-48
    80003be4:	f406                	sd	ra,40(sp)
    80003be6:	f022                	sd	s0,32(sp)
    80003be8:	ec26                	sd	s1,24(sp)
    80003bea:	e84a                	sd	s2,16(sp)
    80003bec:	e44e                	sd	s3,8(sp)
    80003bee:	e052                	sd	s4,0(sp)
    80003bf0:	1800                	addi	s0,sp,48
    80003bf2:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003bf4:	05050493          	addi	s1,a0,80
    80003bf8:	08050913          	addi	s2,a0,128
    80003bfc:	a021                	j	80003c04 <itrunc+0x22>
    80003bfe:	0491                	addi	s1,s1,4
    80003c00:	01248d63          	beq	s1,s2,80003c1a <itrunc+0x38>
    if(ip->addrs[i]){
    80003c04:	408c                	lw	a1,0(s1)
    80003c06:	dde5                	beqz	a1,80003bfe <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003c08:	0009a503          	lw	a0,0(s3)
    80003c0c:	00000097          	auipc	ra,0x0
    80003c10:	90c080e7          	jalr	-1780(ra) # 80003518 <bfree>
      ip->addrs[i] = 0;
    80003c14:	0004a023          	sw	zero,0(s1)
    80003c18:	b7dd                	j	80003bfe <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003c1a:	0809a583          	lw	a1,128(s3)
    80003c1e:	e185                	bnez	a1,80003c3e <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003c20:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003c24:	854e                	mv	a0,s3
    80003c26:	00000097          	auipc	ra,0x0
    80003c2a:	de4080e7          	jalr	-540(ra) # 80003a0a <iupdate>
}
    80003c2e:	70a2                	ld	ra,40(sp)
    80003c30:	7402                	ld	s0,32(sp)
    80003c32:	64e2                	ld	s1,24(sp)
    80003c34:	6942                	ld	s2,16(sp)
    80003c36:	69a2                	ld	s3,8(sp)
    80003c38:	6a02                	ld	s4,0(sp)
    80003c3a:	6145                	addi	sp,sp,48
    80003c3c:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003c3e:	0009a503          	lw	a0,0(s3)
    80003c42:	fffff097          	auipc	ra,0xfffff
    80003c46:	690080e7          	jalr	1680(ra) # 800032d2 <bread>
    80003c4a:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003c4c:	05850493          	addi	s1,a0,88
    80003c50:	45850913          	addi	s2,a0,1112
    80003c54:	a811                	j	80003c68 <itrunc+0x86>
        bfree(ip->dev, a[j]);
    80003c56:	0009a503          	lw	a0,0(s3)
    80003c5a:	00000097          	auipc	ra,0x0
    80003c5e:	8be080e7          	jalr	-1858(ra) # 80003518 <bfree>
    for(j = 0; j < NINDIRECT; j++){
    80003c62:	0491                	addi	s1,s1,4
    80003c64:	01248563          	beq	s1,s2,80003c6e <itrunc+0x8c>
      if(a[j])
    80003c68:	408c                	lw	a1,0(s1)
    80003c6a:	dde5                	beqz	a1,80003c62 <itrunc+0x80>
    80003c6c:	b7ed                	j	80003c56 <itrunc+0x74>
    brelse(bp);
    80003c6e:	8552                	mv	a0,s4
    80003c70:	fffff097          	auipc	ra,0xfffff
    80003c74:	792080e7          	jalr	1938(ra) # 80003402 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003c78:	0809a583          	lw	a1,128(s3)
    80003c7c:	0009a503          	lw	a0,0(s3)
    80003c80:	00000097          	auipc	ra,0x0
    80003c84:	898080e7          	jalr	-1896(ra) # 80003518 <bfree>
    ip->addrs[NDIRECT] = 0;
    80003c88:	0809a023          	sw	zero,128(s3)
    80003c8c:	bf51                	j	80003c20 <itrunc+0x3e>

0000000080003c8e <iput>:
{
    80003c8e:	1101                	addi	sp,sp,-32
    80003c90:	ec06                	sd	ra,24(sp)
    80003c92:	e822                	sd	s0,16(sp)
    80003c94:	e426                	sd	s1,8(sp)
    80003c96:	e04a                	sd	s2,0(sp)
    80003c98:	1000                	addi	s0,sp,32
    80003c9a:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003c9c:	0001c517          	auipc	a0,0x1c
    80003ca0:	34c50513          	addi	a0,a0,844 # 8001ffe8 <itable>
    80003ca4:	ffffd097          	auipc	ra,0xffffd
    80003ca8:	f40080e7          	jalr	-192(ra) # 80000be4 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003cac:	4498                	lw	a4,8(s1)
    80003cae:	4785                	li	a5,1
    80003cb0:	02f70363          	beq	a4,a5,80003cd6 <iput+0x48>
  ip->ref--;
    80003cb4:	449c                	lw	a5,8(s1)
    80003cb6:	37fd                	addiw	a5,a5,-1
    80003cb8:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003cba:	0001c517          	auipc	a0,0x1c
    80003cbe:	32e50513          	addi	a0,a0,814 # 8001ffe8 <itable>
    80003cc2:	ffffd097          	auipc	ra,0xffffd
    80003cc6:	fd6080e7          	jalr	-42(ra) # 80000c98 <release>
}
    80003cca:	60e2                	ld	ra,24(sp)
    80003ccc:	6442                	ld	s0,16(sp)
    80003cce:	64a2                	ld	s1,8(sp)
    80003cd0:	6902                	ld	s2,0(sp)
    80003cd2:	6105                	addi	sp,sp,32
    80003cd4:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003cd6:	40bc                	lw	a5,64(s1)
    80003cd8:	dff1                	beqz	a5,80003cb4 <iput+0x26>
    80003cda:	04a49783          	lh	a5,74(s1)
    80003cde:	fbf9                	bnez	a5,80003cb4 <iput+0x26>
    acquiresleep(&ip->lock);
    80003ce0:	01048913          	addi	s2,s1,16
    80003ce4:	854a                	mv	a0,s2
    80003ce6:	00001097          	auipc	ra,0x1
    80003cea:	ab8080e7          	jalr	-1352(ra) # 8000479e <acquiresleep>
    release(&itable.lock);
    80003cee:	0001c517          	auipc	a0,0x1c
    80003cf2:	2fa50513          	addi	a0,a0,762 # 8001ffe8 <itable>
    80003cf6:	ffffd097          	auipc	ra,0xffffd
    80003cfa:	fa2080e7          	jalr	-94(ra) # 80000c98 <release>
    itrunc(ip);
    80003cfe:	8526                	mv	a0,s1
    80003d00:	00000097          	auipc	ra,0x0
    80003d04:	ee2080e7          	jalr	-286(ra) # 80003be2 <itrunc>
    ip->type = 0;
    80003d08:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003d0c:	8526                	mv	a0,s1
    80003d0e:	00000097          	auipc	ra,0x0
    80003d12:	cfc080e7          	jalr	-772(ra) # 80003a0a <iupdate>
    ip->valid = 0;
    80003d16:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003d1a:	854a                	mv	a0,s2
    80003d1c:	00001097          	auipc	ra,0x1
    80003d20:	ad8080e7          	jalr	-1320(ra) # 800047f4 <releasesleep>
    acquire(&itable.lock);
    80003d24:	0001c517          	auipc	a0,0x1c
    80003d28:	2c450513          	addi	a0,a0,708 # 8001ffe8 <itable>
    80003d2c:	ffffd097          	auipc	ra,0xffffd
    80003d30:	eb8080e7          	jalr	-328(ra) # 80000be4 <acquire>
    80003d34:	b741                	j	80003cb4 <iput+0x26>

0000000080003d36 <iunlockput>:
{
    80003d36:	1101                	addi	sp,sp,-32
    80003d38:	ec06                	sd	ra,24(sp)
    80003d3a:	e822                	sd	s0,16(sp)
    80003d3c:	e426                	sd	s1,8(sp)
    80003d3e:	1000                	addi	s0,sp,32
    80003d40:	84aa                	mv	s1,a0
  iunlock(ip);
    80003d42:	00000097          	auipc	ra,0x0
    80003d46:	e54080e7          	jalr	-428(ra) # 80003b96 <iunlock>
  iput(ip);
    80003d4a:	8526                	mv	a0,s1
    80003d4c:	00000097          	auipc	ra,0x0
    80003d50:	f42080e7          	jalr	-190(ra) # 80003c8e <iput>
}
    80003d54:	60e2                	ld	ra,24(sp)
    80003d56:	6442                	ld	s0,16(sp)
    80003d58:	64a2                	ld	s1,8(sp)
    80003d5a:	6105                	addi	sp,sp,32
    80003d5c:	8082                	ret

0000000080003d5e <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003d5e:	1141                	addi	sp,sp,-16
    80003d60:	e422                	sd	s0,8(sp)
    80003d62:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003d64:	411c                	lw	a5,0(a0)
    80003d66:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003d68:	415c                	lw	a5,4(a0)
    80003d6a:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003d6c:	04451783          	lh	a5,68(a0)
    80003d70:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003d74:	04a51783          	lh	a5,74(a0)
    80003d78:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003d7c:	04c56783          	lwu	a5,76(a0)
    80003d80:	e99c                	sd	a5,16(a1)
}
    80003d82:	6422                	ld	s0,8(sp)
    80003d84:	0141                	addi	sp,sp,16
    80003d86:	8082                	ret

0000000080003d88 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003d88:	457c                	lw	a5,76(a0)
    80003d8a:	0ed7e963          	bltu	a5,a3,80003e7c <readi+0xf4>
{
    80003d8e:	7159                	addi	sp,sp,-112
    80003d90:	f486                	sd	ra,104(sp)
    80003d92:	f0a2                	sd	s0,96(sp)
    80003d94:	eca6                	sd	s1,88(sp)
    80003d96:	e8ca                	sd	s2,80(sp)
    80003d98:	e4ce                	sd	s3,72(sp)
    80003d9a:	e0d2                	sd	s4,64(sp)
    80003d9c:	fc56                	sd	s5,56(sp)
    80003d9e:	f85a                	sd	s6,48(sp)
    80003da0:	f45e                	sd	s7,40(sp)
    80003da2:	f062                	sd	s8,32(sp)
    80003da4:	ec66                	sd	s9,24(sp)
    80003da6:	e86a                	sd	s10,16(sp)
    80003da8:	e46e                	sd	s11,8(sp)
    80003daa:	1880                	addi	s0,sp,112
    80003dac:	8baa                	mv	s7,a0
    80003dae:	8c2e                	mv	s8,a1
    80003db0:	8ab2                	mv	s5,a2
    80003db2:	84b6                	mv	s1,a3
    80003db4:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003db6:	9f35                	addw	a4,a4,a3
    return 0;
    80003db8:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003dba:	0ad76063          	bltu	a4,a3,80003e5a <readi+0xd2>
  if(off + n > ip->size)
    80003dbe:	00e7f463          	bgeu	a5,a4,80003dc6 <readi+0x3e>
    n = ip->size - off;
    80003dc2:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003dc6:	0a0b0963          	beqz	s6,80003e78 <readi+0xf0>
    80003dca:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003dcc:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003dd0:	5cfd                	li	s9,-1
    80003dd2:	a82d                	j	80003e0c <readi+0x84>
    80003dd4:	020a1d93          	slli	s11,s4,0x20
    80003dd8:	020ddd93          	srli	s11,s11,0x20
    80003ddc:	05890613          	addi	a2,s2,88
    80003de0:	86ee                	mv	a3,s11
    80003de2:	963a                	add	a2,a2,a4
    80003de4:	85d6                	mv	a1,s5
    80003de6:	8562                	mv	a0,s8
    80003de8:	fffff097          	auipc	ra,0xfffff
    80003dec:	ae0080e7          	jalr	-1312(ra) # 800028c8 <either_copyout>
    80003df0:	05950d63          	beq	a0,s9,80003e4a <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003df4:	854a                	mv	a0,s2
    80003df6:	fffff097          	auipc	ra,0xfffff
    80003dfa:	60c080e7          	jalr	1548(ra) # 80003402 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003dfe:	013a09bb          	addw	s3,s4,s3
    80003e02:	009a04bb          	addw	s1,s4,s1
    80003e06:	9aee                	add	s5,s5,s11
    80003e08:	0569f763          	bgeu	s3,s6,80003e56 <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003e0c:	000ba903          	lw	s2,0(s7)
    80003e10:	00a4d59b          	srliw	a1,s1,0xa
    80003e14:	855e                	mv	a0,s7
    80003e16:	00000097          	auipc	ra,0x0
    80003e1a:	8b0080e7          	jalr	-1872(ra) # 800036c6 <bmap>
    80003e1e:	0005059b          	sext.w	a1,a0
    80003e22:	854a                	mv	a0,s2
    80003e24:	fffff097          	auipc	ra,0xfffff
    80003e28:	4ae080e7          	jalr	1198(ra) # 800032d2 <bread>
    80003e2c:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003e2e:	3ff4f713          	andi	a4,s1,1023
    80003e32:	40ed07bb          	subw	a5,s10,a4
    80003e36:	413b06bb          	subw	a3,s6,s3
    80003e3a:	8a3e                	mv	s4,a5
    80003e3c:	2781                	sext.w	a5,a5
    80003e3e:	0006861b          	sext.w	a2,a3
    80003e42:	f8f679e3          	bgeu	a2,a5,80003dd4 <readi+0x4c>
    80003e46:	8a36                	mv	s4,a3
    80003e48:	b771                	j	80003dd4 <readi+0x4c>
      brelse(bp);
    80003e4a:	854a                	mv	a0,s2
    80003e4c:	fffff097          	auipc	ra,0xfffff
    80003e50:	5b6080e7          	jalr	1462(ra) # 80003402 <brelse>
      tot = -1;
    80003e54:	59fd                	li	s3,-1
  }
  return tot;
    80003e56:	0009851b          	sext.w	a0,s3
}
    80003e5a:	70a6                	ld	ra,104(sp)
    80003e5c:	7406                	ld	s0,96(sp)
    80003e5e:	64e6                	ld	s1,88(sp)
    80003e60:	6946                	ld	s2,80(sp)
    80003e62:	69a6                	ld	s3,72(sp)
    80003e64:	6a06                	ld	s4,64(sp)
    80003e66:	7ae2                	ld	s5,56(sp)
    80003e68:	7b42                	ld	s6,48(sp)
    80003e6a:	7ba2                	ld	s7,40(sp)
    80003e6c:	7c02                	ld	s8,32(sp)
    80003e6e:	6ce2                	ld	s9,24(sp)
    80003e70:	6d42                	ld	s10,16(sp)
    80003e72:	6da2                	ld	s11,8(sp)
    80003e74:	6165                	addi	sp,sp,112
    80003e76:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003e78:	89da                	mv	s3,s6
    80003e7a:	bff1                	j	80003e56 <readi+0xce>
    return 0;
    80003e7c:	4501                	li	a0,0
}
    80003e7e:	8082                	ret

0000000080003e80 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003e80:	457c                	lw	a5,76(a0)
    80003e82:	10d7e863          	bltu	a5,a3,80003f92 <writei+0x112>
{
    80003e86:	7159                	addi	sp,sp,-112
    80003e88:	f486                	sd	ra,104(sp)
    80003e8a:	f0a2                	sd	s0,96(sp)
    80003e8c:	eca6                	sd	s1,88(sp)
    80003e8e:	e8ca                	sd	s2,80(sp)
    80003e90:	e4ce                	sd	s3,72(sp)
    80003e92:	e0d2                	sd	s4,64(sp)
    80003e94:	fc56                	sd	s5,56(sp)
    80003e96:	f85a                	sd	s6,48(sp)
    80003e98:	f45e                	sd	s7,40(sp)
    80003e9a:	f062                	sd	s8,32(sp)
    80003e9c:	ec66                	sd	s9,24(sp)
    80003e9e:	e86a                	sd	s10,16(sp)
    80003ea0:	e46e                	sd	s11,8(sp)
    80003ea2:	1880                	addi	s0,sp,112
    80003ea4:	8b2a                	mv	s6,a0
    80003ea6:	8c2e                	mv	s8,a1
    80003ea8:	8ab2                	mv	s5,a2
    80003eaa:	8936                	mv	s2,a3
    80003eac:	8bba                	mv	s7,a4
  if(off > ip->size || off + n < off)
    80003eae:	00e687bb          	addw	a5,a3,a4
    80003eb2:	0ed7e263          	bltu	a5,a3,80003f96 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003eb6:	00043737          	lui	a4,0x43
    80003eba:	0ef76063          	bltu	a4,a5,80003f9a <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003ebe:	0c0b8863          	beqz	s7,80003f8e <writei+0x10e>
    80003ec2:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003ec4:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003ec8:	5cfd                	li	s9,-1
    80003eca:	a091                	j	80003f0e <writei+0x8e>
    80003ecc:	02099d93          	slli	s11,s3,0x20
    80003ed0:	020ddd93          	srli	s11,s11,0x20
    80003ed4:	05848513          	addi	a0,s1,88
    80003ed8:	86ee                	mv	a3,s11
    80003eda:	8656                	mv	a2,s5
    80003edc:	85e2                	mv	a1,s8
    80003ede:	953a                	add	a0,a0,a4
    80003ee0:	fffff097          	auipc	ra,0xfffff
    80003ee4:	a3e080e7          	jalr	-1474(ra) # 8000291e <either_copyin>
    80003ee8:	07950263          	beq	a0,s9,80003f4c <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003eec:	8526                	mv	a0,s1
    80003eee:	00000097          	auipc	ra,0x0
    80003ef2:	790080e7          	jalr	1936(ra) # 8000467e <log_write>
    brelse(bp);
    80003ef6:	8526                	mv	a0,s1
    80003ef8:	fffff097          	auipc	ra,0xfffff
    80003efc:	50a080e7          	jalr	1290(ra) # 80003402 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003f00:	01498a3b          	addw	s4,s3,s4
    80003f04:	0129893b          	addw	s2,s3,s2
    80003f08:	9aee                	add	s5,s5,s11
    80003f0a:	057a7663          	bgeu	s4,s7,80003f56 <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003f0e:	000b2483          	lw	s1,0(s6)
    80003f12:	00a9559b          	srliw	a1,s2,0xa
    80003f16:	855a                	mv	a0,s6
    80003f18:	fffff097          	auipc	ra,0xfffff
    80003f1c:	7ae080e7          	jalr	1966(ra) # 800036c6 <bmap>
    80003f20:	0005059b          	sext.w	a1,a0
    80003f24:	8526                	mv	a0,s1
    80003f26:	fffff097          	auipc	ra,0xfffff
    80003f2a:	3ac080e7          	jalr	940(ra) # 800032d2 <bread>
    80003f2e:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003f30:	3ff97713          	andi	a4,s2,1023
    80003f34:	40ed07bb          	subw	a5,s10,a4
    80003f38:	414b86bb          	subw	a3,s7,s4
    80003f3c:	89be                	mv	s3,a5
    80003f3e:	2781                	sext.w	a5,a5
    80003f40:	0006861b          	sext.w	a2,a3
    80003f44:	f8f674e3          	bgeu	a2,a5,80003ecc <writei+0x4c>
    80003f48:	89b6                	mv	s3,a3
    80003f4a:	b749                	j	80003ecc <writei+0x4c>
      brelse(bp);
    80003f4c:	8526                	mv	a0,s1
    80003f4e:	fffff097          	auipc	ra,0xfffff
    80003f52:	4b4080e7          	jalr	1204(ra) # 80003402 <brelse>
  }

  if(off > ip->size)
    80003f56:	04cb2783          	lw	a5,76(s6)
    80003f5a:	0127f463          	bgeu	a5,s2,80003f62 <writei+0xe2>
    ip->size = off;
    80003f5e:	052b2623          	sw	s2,76(s6)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003f62:	855a                	mv	a0,s6
    80003f64:	00000097          	auipc	ra,0x0
    80003f68:	aa6080e7          	jalr	-1370(ra) # 80003a0a <iupdate>

  return tot;
    80003f6c:	000a051b          	sext.w	a0,s4
}
    80003f70:	70a6                	ld	ra,104(sp)
    80003f72:	7406                	ld	s0,96(sp)
    80003f74:	64e6                	ld	s1,88(sp)
    80003f76:	6946                	ld	s2,80(sp)
    80003f78:	69a6                	ld	s3,72(sp)
    80003f7a:	6a06                	ld	s4,64(sp)
    80003f7c:	7ae2                	ld	s5,56(sp)
    80003f7e:	7b42                	ld	s6,48(sp)
    80003f80:	7ba2                	ld	s7,40(sp)
    80003f82:	7c02                	ld	s8,32(sp)
    80003f84:	6ce2                	ld	s9,24(sp)
    80003f86:	6d42                	ld	s10,16(sp)
    80003f88:	6da2                	ld	s11,8(sp)
    80003f8a:	6165                	addi	sp,sp,112
    80003f8c:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003f8e:	8a5e                	mv	s4,s7
    80003f90:	bfc9                	j	80003f62 <writei+0xe2>
    return -1;
    80003f92:	557d                	li	a0,-1
}
    80003f94:	8082                	ret
    return -1;
    80003f96:	557d                	li	a0,-1
    80003f98:	bfe1                	j	80003f70 <writei+0xf0>
    return -1;
    80003f9a:	557d                	li	a0,-1
    80003f9c:	bfd1                	j	80003f70 <writei+0xf0>

0000000080003f9e <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003f9e:	1141                	addi	sp,sp,-16
    80003fa0:	e406                	sd	ra,8(sp)
    80003fa2:	e022                	sd	s0,0(sp)
    80003fa4:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003fa6:	4639                	li	a2,14
    80003fa8:	ffffd097          	auipc	ra,0xffffd
    80003fac:	e10080e7          	jalr	-496(ra) # 80000db8 <strncmp>
}
    80003fb0:	60a2                	ld	ra,8(sp)
    80003fb2:	6402                	ld	s0,0(sp)
    80003fb4:	0141                	addi	sp,sp,16
    80003fb6:	8082                	ret

0000000080003fb8 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003fb8:	7139                	addi	sp,sp,-64
    80003fba:	fc06                	sd	ra,56(sp)
    80003fbc:	f822                	sd	s0,48(sp)
    80003fbe:	f426                	sd	s1,40(sp)
    80003fc0:	f04a                	sd	s2,32(sp)
    80003fc2:	ec4e                	sd	s3,24(sp)
    80003fc4:	e852                	sd	s4,16(sp)
    80003fc6:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003fc8:	04451703          	lh	a4,68(a0)
    80003fcc:	4785                	li	a5,1
    80003fce:	00f71a63          	bne	a4,a5,80003fe2 <dirlookup+0x2a>
    80003fd2:	892a                	mv	s2,a0
    80003fd4:	89ae                	mv	s3,a1
    80003fd6:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003fd8:	457c                	lw	a5,76(a0)
    80003fda:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003fdc:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003fde:	e79d                	bnez	a5,8000400c <dirlookup+0x54>
    80003fe0:	a8a5                	j	80004058 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003fe2:	00004517          	auipc	a0,0x4
    80003fe6:	6e650513          	addi	a0,a0,1766 # 800086c8 <syscalls+0x1b0>
    80003fea:	ffffc097          	auipc	ra,0xffffc
    80003fee:	554080e7          	jalr	1364(ra) # 8000053e <panic>
      panic("dirlookup read");
    80003ff2:	00004517          	auipc	a0,0x4
    80003ff6:	6ee50513          	addi	a0,a0,1774 # 800086e0 <syscalls+0x1c8>
    80003ffa:	ffffc097          	auipc	ra,0xffffc
    80003ffe:	544080e7          	jalr	1348(ra) # 8000053e <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004002:	24c1                	addiw	s1,s1,16
    80004004:	04c92783          	lw	a5,76(s2)
    80004008:	04f4f763          	bgeu	s1,a5,80004056 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000400c:	4741                	li	a4,16
    8000400e:	86a6                	mv	a3,s1
    80004010:	fc040613          	addi	a2,s0,-64
    80004014:	4581                	li	a1,0
    80004016:	854a                	mv	a0,s2
    80004018:	00000097          	auipc	ra,0x0
    8000401c:	d70080e7          	jalr	-656(ra) # 80003d88 <readi>
    80004020:	47c1                	li	a5,16
    80004022:	fcf518e3          	bne	a0,a5,80003ff2 <dirlookup+0x3a>
    if(de.inum == 0)
    80004026:	fc045783          	lhu	a5,-64(s0)
    8000402a:	dfe1                	beqz	a5,80004002 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    8000402c:	fc240593          	addi	a1,s0,-62
    80004030:	854e                	mv	a0,s3
    80004032:	00000097          	auipc	ra,0x0
    80004036:	f6c080e7          	jalr	-148(ra) # 80003f9e <namecmp>
    8000403a:	f561                	bnez	a0,80004002 <dirlookup+0x4a>
      if(poff)
    8000403c:	000a0463          	beqz	s4,80004044 <dirlookup+0x8c>
        *poff = off;
    80004040:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80004044:	fc045583          	lhu	a1,-64(s0)
    80004048:	00092503          	lw	a0,0(s2)
    8000404c:	fffff097          	auipc	ra,0xfffff
    80004050:	754080e7          	jalr	1876(ra) # 800037a0 <iget>
    80004054:	a011                	j	80004058 <dirlookup+0xa0>
  return 0;
    80004056:	4501                	li	a0,0
}
    80004058:	70e2                	ld	ra,56(sp)
    8000405a:	7442                	ld	s0,48(sp)
    8000405c:	74a2                	ld	s1,40(sp)
    8000405e:	7902                	ld	s2,32(sp)
    80004060:	69e2                	ld	s3,24(sp)
    80004062:	6a42                	ld	s4,16(sp)
    80004064:	6121                	addi	sp,sp,64
    80004066:	8082                	ret

0000000080004068 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80004068:	711d                	addi	sp,sp,-96
    8000406a:	ec86                	sd	ra,88(sp)
    8000406c:	e8a2                	sd	s0,80(sp)
    8000406e:	e4a6                	sd	s1,72(sp)
    80004070:	e0ca                	sd	s2,64(sp)
    80004072:	fc4e                	sd	s3,56(sp)
    80004074:	f852                	sd	s4,48(sp)
    80004076:	f456                	sd	s5,40(sp)
    80004078:	f05a                	sd	s6,32(sp)
    8000407a:	ec5e                	sd	s7,24(sp)
    8000407c:	e862                	sd	s8,16(sp)
    8000407e:	e466                	sd	s9,8(sp)
    80004080:	1080                	addi	s0,sp,96
    80004082:	84aa                	mv	s1,a0
    80004084:	8b2e                	mv	s6,a1
    80004086:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80004088:	00054703          	lbu	a4,0(a0)
    8000408c:	02f00793          	li	a5,47
    80004090:	02f70363          	beq	a4,a5,800040b6 <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80004094:	ffffe097          	auipc	ra,0xffffe
    80004098:	934080e7          	jalr	-1740(ra) # 800019c8 <myproc>
    8000409c:	17053503          	ld	a0,368(a0)
    800040a0:	00000097          	auipc	ra,0x0
    800040a4:	9f6080e7          	jalr	-1546(ra) # 80003a96 <idup>
    800040a8:	89aa                	mv	s3,a0
  while(*path == '/')
    800040aa:	02f00913          	li	s2,47
  len = path - s;
    800040ae:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    800040b0:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    800040b2:	4c05                	li	s8,1
    800040b4:	a865                	j	8000416c <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    800040b6:	4585                	li	a1,1
    800040b8:	4505                	li	a0,1
    800040ba:	fffff097          	auipc	ra,0xfffff
    800040be:	6e6080e7          	jalr	1766(ra) # 800037a0 <iget>
    800040c2:	89aa                	mv	s3,a0
    800040c4:	b7dd                	j	800040aa <namex+0x42>
      iunlockput(ip);
    800040c6:	854e                	mv	a0,s3
    800040c8:	00000097          	auipc	ra,0x0
    800040cc:	c6e080e7          	jalr	-914(ra) # 80003d36 <iunlockput>
      return 0;
    800040d0:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    800040d2:	854e                	mv	a0,s3
    800040d4:	60e6                	ld	ra,88(sp)
    800040d6:	6446                	ld	s0,80(sp)
    800040d8:	64a6                	ld	s1,72(sp)
    800040da:	6906                	ld	s2,64(sp)
    800040dc:	79e2                	ld	s3,56(sp)
    800040de:	7a42                	ld	s4,48(sp)
    800040e0:	7aa2                	ld	s5,40(sp)
    800040e2:	7b02                	ld	s6,32(sp)
    800040e4:	6be2                	ld	s7,24(sp)
    800040e6:	6c42                	ld	s8,16(sp)
    800040e8:	6ca2                	ld	s9,8(sp)
    800040ea:	6125                	addi	sp,sp,96
    800040ec:	8082                	ret
      iunlock(ip);
    800040ee:	854e                	mv	a0,s3
    800040f0:	00000097          	auipc	ra,0x0
    800040f4:	aa6080e7          	jalr	-1370(ra) # 80003b96 <iunlock>
      return ip;
    800040f8:	bfe9                	j	800040d2 <namex+0x6a>
      iunlockput(ip);
    800040fa:	854e                	mv	a0,s3
    800040fc:	00000097          	auipc	ra,0x0
    80004100:	c3a080e7          	jalr	-966(ra) # 80003d36 <iunlockput>
      return 0;
    80004104:	89d2                	mv	s3,s4
    80004106:	b7f1                	j	800040d2 <namex+0x6a>
  len = path - s;
    80004108:	40b48633          	sub	a2,s1,a1
    8000410c:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    80004110:	094cd463          	bge	s9,s4,80004198 <namex+0x130>
    memmove(name, s, DIRSIZ);
    80004114:	4639                	li	a2,14
    80004116:	8556                	mv	a0,s5
    80004118:	ffffd097          	auipc	ra,0xffffd
    8000411c:	c28080e7          	jalr	-984(ra) # 80000d40 <memmove>
  while(*path == '/')
    80004120:	0004c783          	lbu	a5,0(s1)
    80004124:	01279763          	bne	a5,s2,80004132 <namex+0xca>
    path++;
    80004128:	0485                	addi	s1,s1,1
  while(*path == '/')
    8000412a:	0004c783          	lbu	a5,0(s1)
    8000412e:	ff278de3          	beq	a5,s2,80004128 <namex+0xc0>
    ilock(ip);
    80004132:	854e                	mv	a0,s3
    80004134:	00000097          	auipc	ra,0x0
    80004138:	9a0080e7          	jalr	-1632(ra) # 80003ad4 <ilock>
    if(ip->type != T_DIR){
    8000413c:	04499783          	lh	a5,68(s3)
    80004140:	f98793e3          	bne	a5,s8,800040c6 <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80004144:	000b0563          	beqz	s6,8000414e <namex+0xe6>
    80004148:	0004c783          	lbu	a5,0(s1)
    8000414c:	d3cd                	beqz	a5,800040ee <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    8000414e:	865e                	mv	a2,s7
    80004150:	85d6                	mv	a1,s5
    80004152:	854e                	mv	a0,s3
    80004154:	00000097          	auipc	ra,0x0
    80004158:	e64080e7          	jalr	-412(ra) # 80003fb8 <dirlookup>
    8000415c:	8a2a                	mv	s4,a0
    8000415e:	dd51                	beqz	a0,800040fa <namex+0x92>
    iunlockput(ip);
    80004160:	854e                	mv	a0,s3
    80004162:	00000097          	auipc	ra,0x0
    80004166:	bd4080e7          	jalr	-1068(ra) # 80003d36 <iunlockput>
    ip = next;
    8000416a:	89d2                	mv	s3,s4
  while(*path == '/')
    8000416c:	0004c783          	lbu	a5,0(s1)
    80004170:	05279763          	bne	a5,s2,800041be <namex+0x156>
    path++;
    80004174:	0485                	addi	s1,s1,1
  while(*path == '/')
    80004176:	0004c783          	lbu	a5,0(s1)
    8000417a:	ff278de3          	beq	a5,s2,80004174 <namex+0x10c>
  if(*path == 0)
    8000417e:	c79d                	beqz	a5,800041ac <namex+0x144>
    path++;
    80004180:	85a6                	mv	a1,s1
  len = path - s;
    80004182:	8a5e                	mv	s4,s7
    80004184:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    80004186:	01278963          	beq	a5,s2,80004198 <namex+0x130>
    8000418a:	dfbd                	beqz	a5,80004108 <namex+0xa0>
    path++;
    8000418c:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    8000418e:	0004c783          	lbu	a5,0(s1)
    80004192:	ff279ce3          	bne	a5,s2,8000418a <namex+0x122>
    80004196:	bf8d                	j	80004108 <namex+0xa0>
    memmove(name, s, len);
    80004198:	2601                	sext.w	a2,a2
    8000419a:	8556                	mv	a0,s5
    8000419c:	ffffd097          	auipc	ra,0xffffd
    800041a0:	ba4080e7          	jalr	-1116(ra) # 80000d40 <memmove>
    name[len] = 0;
    800041a4:	9a56                	add	s4,s4,s5
    800041a6:	000a0023          	sb	zero,0(s4)
    800041aa:	bf9d                	j	80004120 <namex+0xb8>
  if(nameiparent){
    800041ac:	f20b03e3          	beqz	s6,800040d2 <namex+0x6a>
    iput(ip);
    800041b0:	854e                	mv	a0,s3
    800041b2:	00000097          	auipc	ra,0x0
    800041b6:	adc080e7          	jalr	-1316(ra) # 80003c8e <iput>
    return 0;
    800041ba:	4981                	li	s3,0
    800041bc:	bf19                	j	800040d2 <namex+0x6a>
  if(*path == 0)
    800041be:	d7fd                	beqz	a5,800041ac <namex+0x144>
  while(*path != '/' && *path != 0)
    800041c0:	0004c783          	lbu	a5,0(s1)
    800041c4:	85a6                	mv	a1,s1
    800041c6:	b7d1                	j	8000418a <namex+0x122>

00000000800041c8 <dirlink>:
{
    800041c8:	7139                	addi	sp,sp,-64
    800041ca:	fc06                	sd	ra,56(sp)
    800041cc:	f822                	sd	s0,48(sp)
    800041ce:	f426                	sd	s1,40(sp)
    800041d0:	f04a                	sd	s2,32(sp)
    800041d2:	ec4e                	sd	s3,24(sp)
    800041d4:	e852                	sd	s4,16(sp)
    800041d6:	0080                	addi	s0,sp,64
    800041d8:	892a                	mv	s2,a0
    800041da:	8a2e                	mv	s4,a1
    800041dc:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    800041de:	4601                	li	a2,0
    800041e0:	00000097          	auipc	ra,0x0
    800041e4:	dd8080e7          	jalr	-552(ra) # 80003fb8 <dirlookup>
    800041e8:	e93d                	bnez	a0,8000425e <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800041ea:	04c92483          	lw	s1,76(s2)
    800041ee:	c49d                	beqz	s1,8000421c <dirlink+0x54>
    800041f0:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800041f2:	4741                	li	a4,16
    800041f4:	86a6                	mv	a3,s1
    800041f6:	fc040613          	addi	a2,s0,-64
    800041fa:	4581                	li	a1,0
    800041fc:	854a                	mv	a0,s2
    800041fe:	00000097          	auipc	ra,0x0
    80004202:	b8a080e7          	jalr	-1142(ra) # 80003d88 <readi>
    80004206:	47c1                	li	a5,16
    80004208:	06f51163          	bne	a0,a5,8000426a <dirlink+0xa2>
    if(de.inum == 0)
    8000420c:	fc045783          	lhu	a5,-64(s0)
    80004210:	c791                	beqz	a5,8000421c <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004212:	24c1                	addiw	s1,s1,16
    80004214:	04c92783          	lw	a5,76(s2)
    80004218:	fcf4ede3          	bltu	s1,a5,800041f2 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    8000421c:	4639                	li	a2,14
    8000421e:	85d2                	mv	a1,s4
    80004220:	fc240513          	addi	a0,s0,-62
    80004224:	ffffd097          	auipc	ra,0xffffd
    80004228:	bd0080e7          	jalr	-1072(ra) # 80000df4 <strncpy>
  de.inum = inum;
    8000422c:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004230:	4741                	li	a4,16
    80004232:	86a6                	mv	a3,s1
    80004234:	fc040613          	addi	a2,s0,-64
    80004238:	4581                	li	a1,0
    8000423a:	854a                	mv	a0,s2
    8000423c:	00000097          	auipc	ra,0x0
    80004240:	c44080e7          	jalr	-956(ra) # 80003e80 <writei>
    80004244:	872a                	mv	a4,a0
    80004246:	47c1                	li	a5,16
  return 0;
    80004248:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000424a:	02f71863          	bne	a4,a5,8000427a <dirlink+0xb2>
}
    8000424e:	70e2                	ld	ra,56(sp)
    80004250:	7442                	ld	s0,48(sp)
    80004252:	74a2                	ld	s1,40(sp)
    80004254:	7902                	ld	s2,32(sp)
    80004256:	69e2                	ld	s3,24(sp)
    80004258:	6a42                	ld	s4,16(sp)
    8000425a:	6121                	addi	sp,sp,64
    8000425c:	8082                	ret
    iput(ip);
    8000425e:	00000097          	auipc	ra,0x0
    80004262:	a30080e7          	jalr	-1488(ra) # 80003c8e <iput>
    return -1;
    80004266:	557d                	li	a0,-1
    80004268:	b7dd                	j	8000424e <dirlink+0x86>
      panic("dirlink read");
    8000426a:	00004517          	auipc	a0,0x4
    8000426e:	48650513          	addi	a0,a0,1158 # 800086f0 <syscalls+0x1d8>
    80004272:	ffffc097          	auipc	ra,0xffffc
    80004276:	2cc080e7          	jalr	716(ra) # 8000053e <panic>
    panic("dirlink");
    8000427a:	00004517          	auipc	a0,0x4
    8000427e:	58650513          	addi	a0,a0,1414 # 80008800 <syscalls+0x2e8>
    80004282:	ffffc097          	auipc	ra,0xffffc
    80004286:	2bc080e7          	jalr	700(ra) # 8000053e <panic>

000000008000428a <namei>:

struct inode*
namei(char *path)
{
    8000428a:	1101                	addi	sp,sp,-32
    8000428c:	ec06                	sd	ra,24(sp)
    8000428e:	e822                	sd	s0,16(sp)
    80004290:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80004292:	fe040613          	addi	a2,s0,-32
    80004296:	4581                	li	a1,0
    80004298:	00000097          	auipc	ra,0x0
    8000429c:	dd0080e7          	jalr	-560(ra) # 80004068 <namex>
}
    800042a0:	60e2                	ld	ra,24(sp)
    800042a2:	6442                	ld	s0,16(sp)
    800042a4:	6105                	addi	sp,sp,32
    800042a6:	8082                	ret

00000000800042a8 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    800042a8:	1141                	addi	sp,sp,-16
    800042aa:	e406                	sd	ra,8(sp)
    800042ac:	e022                	sd	s0,0(sp)
    800042ae:	0800                	addi	s0,sp,16
    800042b0:	862e                	mv	a2,a1
  return namex(path, 1, name);
    800042b2:	4585                	li	a1,1
    800042b4:	00000097          	auipc	ra,0x0
    800042b8:	db4080e7          	jalr	-588(ra) # 80004068 <namex>
}
    800042bc:	60a2                	ld	ra,8(sp)
    800042be:	6402                	ld	s0,0(sp)
    800042c0:	0141                	addi	sp,sp,16
    800042c2:	8082                	ret

00000000800042c4 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    800042c4:	1101                	addi	sp,sp,-32
    800042c6:	ec06                	sd	ra,24(sp)
    800042c8:	e822                	sd	s0,16(sp)
    800042ca:	e426                	sd	s1,8(sp)
    800042cc:	e04a                	sd	s2,0(sp)
    800042ce:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    800042d0:	0001d917          	auipc	s2,0x1d
    800042d4:	7c090913          	addi	s2,s2,1984 # 80021a90 <log>
    800042d8:	01892583          	lw	a1,24(s2)
    800042dc:	02892503          	lw	a0,40(s2)
    800042e0:	fffff097          	auipc	ra,0xfffff
    800042e4:	ff2080e7          	jalr	-14(ra) # 800032d2 <bread>
    800042e8:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    800042ea:	02c92683          	lw	a3,44(s2)
    800042ee:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    800042f0:	02d05763          	blez	a3,8000431e <write_head+0x5a>
    800042f4:	0001d797          	auipc	a5,0x1d
    800042f8:	7cc78793          	addi	a5,a5,1996 # 80021ac0 <log+0x30>
    800042fc:	05c50713          	addi	a4,a0,92
    80004300:	36fd                	addiw	a3,a3,-1
    80004302:	1682                	slli	a3,a3,0x20
    80004304:	9281                	srli	a3,a3,0x20
    80004306:	068a                	slli	a3,a3,0x2
    80004308:	0001d617          	auipc	a2,0x1d
    8000430c:	7bc60613          	addi	a2,a2,1980 # 80021ac4 <log+0x34>
    80004310:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80004312:	4390                	lw	a2,0(a5)
    80004314:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004316:	0791                	addi	a5,a5,4
    80004318:	0711                	addi	a4,a4,4
    8000431a:	fed79ce3          	bne	a5,a3,80004312 <write_head+0x4e>
  }
  bwrite(buf);
    8000431e:	8526                	mv	a0,s1
    80004320:	fffff097          	auipc	ra,0xfffff
    80004324:	0a4080e7          	jalr	164(ra) # 800033c4 <bwrite>
  brelse(buf);
    80004328:	8526                	mv	a0,s1
    8000432a:	fffff097          	auipc	ra,0xfffff
    8000432e:	0d8080e7          	jalr	216(ra) # 80003402 <brelse>
}
    80004332:	60e2                	ld	ra,24(sp)
    80004334:	6442                	ld	s0,16(sp)
    80004336:	64a2                	ld	s1,8(sp)
    80004338:	6902                	ld	s2,0(sp)
    8000433a:	6105                	addi	sp,sp,32
    8000433c:	8082                	ret

000000008000433e <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    8000433e:	0001d797          	auipc	a5,0x1d
    80004342:	77e7a783          	lw	a5,1918(a5) # 80021abc <log+0x2c>
    80004346:	0af05d63          	blez	a5,80004400 <install_trans+0xc2>
{
    8000434a:	7139                	addi	sp,sp,-64
    8000434c:	fc06                	sd	ra,56(sp)
    8000434e:	f822                	sd	s0,48(sp)
    80004350:	f426                	sd	s1,40(sp)
    80004352:	f04a                	sd	s2,32(sp)
    80004354:	ec4e                	sd	s3,24(sp)
    80004356:	e852                	sd	s4,16(sp)
    80004358:	e456                	sd	s5,8(sp)
    8000435a:	e05a                	sd	s6,0(sp)
    8000435c:	0080                	addi	s0,sp,64
    8000435e:	8b2a                	mv	s6,a0
    80004360:	0001da97          	auipc	s5,0x1d
    80004364:	760a8a93          	addi	s5,s5,1888 # 80021ac0 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004368:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    8000436a:	0001d997          	auipc	s3,0x1d
    8000436e:	72698993          	addi	s3,s3,1830 # 80021a90 <log>
    80004372:	a035                	j	8000439e <install_trans+0x60>
      bunpin(dbuf);
    80004374:	8526                	mv	a0,s1
    80004376:	fffff097          	auipc	ra,0xfffff
    8000437a:	166080e7          	jalr	358(ra) # 800034dc <bunpin>
    brelse(lbuf);
    8000437e:	854a                	mv	a0,s2
    80004380:	fffff097          	auipc	ra,0xfffff
    80004384:	082080e7          	jalr	130(ra) # 80003402 <brelse>
    brelse(dbuf);
    80004388:	8526                	mv	a0,s1
    8000438a:	fffff097          	auipc	ra,0xfffff
    8000438e:	078080e7          	jalr	120(ra) # 80003402 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004392:	2a05                	addiw	s4,s4,1
    80004394:	0a91                	addi	s5,s5,4
    80004396:	02c9a783          	lw	a5,44(s3)
    8000439a:	04fa5963          	bge	s4,a5,800043ec <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    8000439e:	0189a583          	lw	a1,24(s3)
    800043a2:	014585bb          	addw	a1,a1,s4
    800043a6:	2585                	addiw	a1,a1,1
    800043a8:	0289a503          	lw	a0,40(s3)
    800043ac:	fffff097          	auipc	ra,0xfffff
    800043b0:	f26080e7          	jalr	-218(ra) # 800032d2 <bread>
    800043b4:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    800043b6:	000aa583          	lw	a1,0(s5)
    800043ba:	0289a503          	lw	a0,40(s3)
    800043be:	fffff097          	auipc	ra,0xfffff
    800043c2:	f14080e7          	jalr	-236(ra) # 800032d2 <bread>
    800043c6:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    800043c8:	40000613          	li	a2,1024
    800043cc:	05890593          	addi	a1,s2,88
    800043d0:	05850513          	addi	a0,a0,88
    800043d4:	ffffd097          	auipc	ra,0xffffd
    800043d8:	96c080e7          	jalr	-1684(ra) # 80000d40 <memmove>
    bwrite(dbuf);  // write dst to disk
    800043dc:	8526                	mv	a0,s1
    800043de:	fffff097          	auipc	ra,0xfffff
    800043e2:	fe6080e7          	jalr	-26(ra) # 800033c4 <bwrite>
    if(recovering == 0)
    800043e6:	f80b1ce3          	bnez	s6,8000437e <install_trans+0x40>
    800043ea:	b769                	j	80004374 <install_trans+0x36>
}
    800043ec:	70e2                	ld	ra,56(sp)
    800043ee:	7442                	ld	s0,48(sp)
    800043f0:	74a2                	ld	s1,40(sp)
    800043f2:	7902                	ld	s2,32(sp)
    800043f4:	69e2                	ld	s3,24(sp)
    800043f6:	6a42                	ld	s4,16(sp)
    800043f8:	6aa2                	ld	s5,8(sp)
    800043fa:	6b02                	ld	s6,0(sp)
    800043fc:	6121                	addi	sp,sp,64
    800043fe:	8082                	ret
    80004400:	8082                	ret

0000000080004402 <initlog>:
{
    80004402:	7179                	addi	sp,sp,-48
    80004404:	f406                	sd	ra,40(sp)
    80004406:	f022                	sd	s0,32(sp)
    80004408:	ec26                	sd	s1,24(sp)
    8000440a:	e84a                	sd	s2,16(sp)
    8000440c:	e44e                	sd	s3,8(sp)
    8000440e:	1800                	addi	s0,sp,48
    80004410:	892a                	mv	s2,a0
    80004412:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80004414:	0001d497          	auipc	s1,0x1d
    80004418:	67c48493          	addi	s1,s1,1660 # 80021a90 <log>
    8000441c:	00004597          	auipc	a1,0x4
    80004420:	2e458593          	addi	a1,a1,740 # 80008700 <syscalls+0x1e8>
    80004424:	8526                	mv	a0,s1
    80004426:	ffffc097          	auipc	ra,0xffffc
    8000442a:	72e080e7          	jalr	1838(ra) # 80000b54 <initlock>
  log.start = sb->logstart;
    8000442e:	0149a583          	lw	a1,20(s3)
    80004432:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80004434:	0109a783          	lw	a5,16(s3)
    80004438:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    8000443a:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    8000443e:	854a                	mv	a0,s2
    80004440:	fffff097          	auipc	ra,0xfffff
    80004444:	e92080e7          	jalr	-366(ra) # 800032d2 <bread>
  log.lh.n = lh->n;
    80004448:	4d3c                	lw	a5,88(a0)
    8000444a:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    8000444c:	02f05563          	blez	a5,80004476 <initlog+0x74>
    80004450:	05c50713          	addi	a4,a0,92
    80004454:	0001d697          	auipc	a3,0x1d
    80004458:	66c68693          	addi	a3,a3,1644 # 80021ac0 <log+0x30>
    8000445c:	37fd                	addiw	a5,a5,-1
    8000445e:	1782                	slli	a5,a5,0x20
    80004460:	9381                	srli	a5,a5,0x20
    80004462:	078a                	slli	a5,a5,0x2
    80004464:	06050613          	addi	a2,a0,96
    80004468:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    8000446a:	4310                	lw	a2,0(a4)
    8000446c:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    8000446e:	0711                	addi	a4,a4,4
    80004470:	0691                	addi	a3,a3,4
    80004472:	fef71ce3          	bne	a4,a5,8000446a <initlog+0x68>
  brelse(buf);
    80004476:	fffff097          	auipc	ra,0xfffff
    8000447a:	f8c080e7          	jalr	-116(ra) # 80003402 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    8000447e:	4505                	li	a0,1
    80004480:	00000097          	auipc	ra,0x0
    80004484:	ebe080e7          	jalr	-322(ra) # 8000433e <install_trans>
  log.lh.n = 0;
    80004488:	0001d797          	auipc	a5,0x1d
    8000448c:	6207aa23          	sw	zero,1588(a5) # 80021abc <log+0x2c>
  write_head(); // clear the log
    80004490:	00000097          	auipc	ra,0x0
    80004494:	e34080e7          	jalr	-460(ra) # 800042c4 <write_head>
}
    80004498:	70a2                	ld	ra,40(sp)
    8000449a:	7402                	ld	s0,32(sp)
    8000449c:	64e2                	ld	s1,24(sp)
    8000449e:	6942                	ld	s2,16(sp)
    800044a0:	69a2                	ld	s3,8(sp)
    800044a2:	6145                	addi	sp,sp,48
    800044a4:	8082                	ret

00000000800044a6 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    800044a6:	1101                	addi	sp,sp,-32
    800044a8:	ec06                	sd	ra,24(sp)
    800044aa:	e822                	sd	s0,16(sp)
    800044ac:	e426                	sd	s1,8(sp)
    800044ae:	e04a                	sd	s2,0(sp)
    800044b0:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    800044b2:	0001d517          	auipc	a0,0x1d
    800044b6:	5de50513          	addi	a0,a0,1502 # 80021a90 <log>
    800044ba:	ffffc097          	auipc	ra,0xffffc
    800044be:	72a080e7          	jalr	1834(ra) # 80000be4 <acquire>
  while(1){
    if(log.committing){
    800044c2:	0001d497          	auipc	s1,0x1d
    800044c6:	5ce48493          	addi	s1,s1,1486 # 80021a90 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800044ca:	4979                	li	s2,30
    800044cc:	a039                	j	800044da <begin_op+0x34>
      sleep(&log, &log.lock);
    800044ce:	85a6                	mv	a1,s1
    800044d0:	8526                	mv	a0,s1
    800044d2:	ffffe097          	auipc	ra,0xffffe
    800044d6:	ed0080e7          	jalr	-304(ra) # 800023a2 <sleep>
    if(log.committing){
    800044da:	50dc                	lw	a5,36(s1)
    800044dc:	fbed                	bnez	a5,800044ce <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800044de:	509c                	lw	a5,32(s1)
    800044e0:	0017871b          	addiw	a4,a5,1
    800044e4:	0007069b          	sext.w	a3,a4
    800044e8:	0027179b          	slliw	a5,a4,0x2
    800044ec:	9fb9                	addw	a5,a5,a4
    800044ee:	0017979b          	slliw	a5,a5,0x1
    800044f2:	54d8                	lw	a4,44(s1)
    800044f4:	9fb9                	addw	a5,a5,a4
    800044f6:	00f95963          	bge	s2,a5,80004508 <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    800044fa:	85a6                	mv	a1,s1
    800044fc:	8526                	mv	a0,s1
    800044fe:	ffffe097          	auipc	ra,0xffffe
    80004502:	ea4080e7          	jalr	-348(ra) # 800023a2 <sleep>
    80004506:	bfd1                	j	800044da <begin_op+0x34>
    } else {
      log.outstanding += 1;
    80004508:	0001d517          	auipc	a0,0x1d
    8000450c:	58850513          	addi	a0,a0,1416 # 80021a90 <log>
    80004510:	d114                	sw	a3,32(a0)
      release(&log.lock);
    80004512:	ffffc097          	auipc	ra,0xffffc
    80004516:	786080e7          	jalr	1926(ra) # 80000c98 <release>
      break;
    }
  }
}
    8000451a:	60e2                	ld	ra,24(sp)
    8000451c:	6442                	ld	s0,16(sp)
    8000451e:	64a2                	ld	s1,8(sp)
    80004520:	6902                	ld	s2,0(sp)
    80004522:	6105                	addi	sp,sp,32
    80004524:	8082                	ret

0000000080004526 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80004526:	7139                	addi	sp,sp,-64
    80004528:	fc06                	sd	ra,56(sp)
    8000452a:	f822                	sd	s0,48(sp)
    8000452c:	f426                	sd	s1,40(sp)
    8000452e:	f04a                	sd	s2,32(sp)
    80004530:	ec4e                	sd	s3,24(sp)
    80004532:	e852                	sd	s4,16(sp)
    80004534:	e456                	sd	s5,8(sp)
    80004536:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80004538:	0001d497          	auipc	s1,0x1d
    8000453c:	55848493          	addi	s1,s1,1368 # 80021a90 <log>
    80004540:	8526                	mv	a0,s1
    80004542:	ffffc097          	auipc	ra,0xffffc
    80004546:	6a2080e7          	jalr	1698(ra) # 80000be4 <acquire>
  log.outstanding -= 1;
    8000454a:	509c                	lw	a5,32(s1)
    8000454c:	37fd                	addiw	a5,a5,-1
    8000454e:	0007891b          	sext.w	s2,a5
    80004552:	d09c                	sw	a5,32(s1)
  if(log.committing)
    80004554:	50dc                	lw	a5,36(s1)
    80004556:	efb9                	bnez	a5,800045b4 <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    80004558:	06091663          	bnez	s2,800045c4 <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    8000455c:	0001d497          	auipc	s1,0x1d
    80004560:	53448493          	addi	s1,s1,1332 # 80021a90 <log>
    80004564:	4785                	li	a5,1
    80004566:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    80004568:	8526                	mv	a0,s1
    8000456a:	ffffc097          	auipc	ra,0xffffc
    8000456e:	72e080e7          	jalr	1838(ra) # 80000c98 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    80004572:	54dc                	lw	a5,44(s1)
    80004574:	06f04763          	bgtz	a5,800045e2 <end_op+0xbc>
    acquire(&log.lock);
    80004578:	0001d497          	auipc	s1,0x1d
    8000457c:	51848493          	addi	s1,s1,1304 # 80021a90 <log>
    80004580:	8526                	mv	a0,s1
    80004582:	ffffc097          	auipc	ra,0xffffc
    80004586:	662080e7          	jalr	1634(ra) # 80000be4 <acquire>
    log.committing = 0;
    8000458a:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    8000458e:	8526                	mv	a0,s1
    80004590:	ffffe097          	auipc	ra,0xffffe
    80004594:	fb2080e7          	jalr	-78(ra) # 80002542 <wakeup>
    release(&log.lock);
    80004598:	8526                	mv	a0,s1
    8000459a:	ffffc097          	auipc	ra,0xffffc
    8000459e:	6fe080e7          	jalr	1790(ra) # 80000c98 <release>
}
    800045a2:	70e2                	ld	ra,56(sp)
    800045a4:	7442                	ld	s0,48(sp)
    800045a6:	74a2                	ld	s1,40(sp)
    800045a8:	7902                	ld	s2,32(sp)
    800045aa:	69e2                	ld	s3,24(sp)
    800045ac:	6a42                	ld	s4,16(sp)
    800045ae:	6aa2                	ld	s5,8(sp)
    800045b0:	6121                	addi	sp,sp,64
    800045b2:	8082                	ret
    panic("log.committing");
    800045b4:	00004517          	auipc	a0,0x4
    800045b8:	15450513          	addi	a0,a0,340 # 80008708 <syscalls+0x1f0>
    800045bc:	ffffc097          	auipc	ra,0xffffc
    800045c0:	f82080e7          	jalr	-126(ra) # 8000053e <panic>
    wakeup(&log);
    800045c4:	0001d497          	auipc	s1,0x1d
    800045c8:	4cc48493          	addi	s1,s1,1228 # 80021a90 <log>
    800045cc:	8526                	mv	a0,s1
    800045ce:	ffffe097          	auipc	ra,0xffffe
    800045d2:	f74080e7          	jalr	-140(ra) # 80002542 <wakeup>
  release(&log.lock);
    800045d6:	8526                	mv	a0,s1
    800045d8:	ffffc097          	auipc	ra,0xffffc
    800045dc:	6c0080e7          	jalr	1728(ra) # 80000c98 <release>
  if(do_commit){
    800045e0:	b7c9                	j	800045a2 <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    800045e2:	0001da97          	auipc	s5,0x1d
    800045e6:	4dea8a93          	addi	s5,s5,1246 # 80021ac0 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    800045ea:	0001da17          	auipc	s4,0x1d
    800045ee:	4a6a0a13          	addi	s4,s4,1190 # 80021a90 <log>
    800045f2:	018a2583          	lw	a1,24(s4)
    800045f6:	012585bb          	addw	a1,a1,s2
    800045fa:	2585                	addiw	a1,a1,1
    800045fc:	028a2503          	lw	a0,40(s4)
    80004600:	fffff097          	auipc	ra,0xfffff
    80004604:	cd2080e7          	jalr	-814(ra) # 800032d2 <bread>
    80004608:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    8000460a:	000aa583          	lw	a1,0(s5)
    8000460e:	028a2503          	lw	a0,40(s4)
    80004612:	fffff097          	auipc	ra,0xfffff
    80004616:	cc0080e7          	jalr	-832(ra) # 800032d2 <bread>
    8000461a:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    8000461c:	40000613          	li	a2,1024
    80004620:	05850593          	addi	a1,a0,88
    80004624:	05848513          	addi	a0,s1,88
    80004628:	ffffc097          	auipc	ra,0xffffc
    8000462c:	718080e7          	jalr	1816(ra) # 80000d40 <memmove>
    bwrite(to);  // write the log
    80004630:	8526                	mv	a0,s1
    80004632:	fffff097          	auipc	ra,0xfffff
    80004636:	d92080e7          	jalr	-622(ra) # 800033c4 <bwrite>
    brelse(from);
    8000463a:	854e                	mv	a0,s3
    8000463c:	fffff097          	auipc	ra,0xfffff
    80004640:	dc6080e7          	jalr	-570(ra) # 80003402 <brelse>
    brelse(to);
    80004644:	8526                	mv	a0,s1
    80004646:	fffff097          	auipc	ra,0xfffff
    8000464a:	dbc080e7          	jalr	-580(ra) # 80003402 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000464e:	2905                	addiw	s2,s2,1
    80004650:	0a91                	addi	s5,s5,4
    80004652:	02ca2783          	lw	a5,44(s4)
    80004656:	f8f94ee3          	blt	s2,a5,800045f2 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    8000465a:	00000097          	auipc	ra,0x0
    8000465e:	c6a080e7          	jalr	-918(ra) # 800042c4 <write_head>
    install_trans(0); // Now install writes to home locations
    80004662:	4501                	li	a0,0
    80004664:	00000097          	auipc	ra,0x0
    80004668:	cda080e7          	jalr	-806(ra) # 8000433e <install_trans>
    log.lh.n = 0;
    8000466c:	0001d797          	auipc	a5,0x1d
    80004670:	4407a823          	sw	zero,1104(a5) # 80021abc <log+0x2c>
    write_head();    // Erase the transaction from the log
    80004674:	00000097          	auipc	ra,0x0
    80004678:	c50080e7          	jalr	-944(ra) # 800042c4 <write_head>
    8000467c:	bdf5                	j	80004578 <end_op+0x52>

000000008000467e <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    8000467e:	1101                	addi	sp,sp,-32
    80004680:	ec06                	sd	ra,24(sp)
    80004682:	e822                	sd	s0,16(sp)
    80004684:	e426                	sd	s1,8(sp)
    80004686:	e04a                	sd	s2,0(sp)
    80004688:	1000                	addi	s0,sp,32
    8000468a:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    8000468c:	0001d917          	auipc	s2,0x1d
    80004690:	40490913          	addi	s2,s2,1028 # 80021a90 <log>
    80004694:	854a                	mv	a0,s2
    80004696:	ffffc097          	auipc	ra,0xffffc
    8000469a:	54e080e7          	jalr	1358(ra) # 80000be4 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    8000469e:	02c92603          	lw	a2,44(s2)
    800046a2:	47f5                	li	a5,29
    800046a4:	06c7c563          	blt	a5,a2,8000470e <log_write+0x90>
    800046a8:	0001d797          	auipc	a5,0x1d
    800046ac:	4047a783          	lw	a5,1028(a5) # 80021aac <log+0x1c>
    800046b0:	37fd                	addiw	a5,a5,-1
    800046b2:	04f65e63          	bge	a2,a5,8000470e <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    800046b6:	0001d797          	auipc	a5,0x1d
    800046ba:	3fa7a783          	lw	a5,1018(a5) # 80021ab0 <log+0x20>
    800046be:	06f05063          	blez	a5,8000471e <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    800046c2:	4781                	li	a5,0
    800046c4:	06c05563          	blez	a2,8000472e <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    800046c8:	44cc                	lw	a1,12(s1)
    800046ca:	0001d717          	auipc	a4,0x1d
    800046ce:	3f670713          	addi	a4,a4,1014 # 80021ac0 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    800046d2:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    800046d4:	4314                	lw	a3,0(a4)
    800046d6:	04b68c63          	beq	a3,a1,8000472e <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    800046da:	2785                	addiw	a5,a5,1
    800046dc:	0711                	addi	a4,a4,4
    800046de:	fef61be3          	bne	a2,a5,800046d4 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    800046e2:	0621                	addi	a2,a2,8
    800046e4:	060a                	slli	a2,a2,0x2
    800046e6:	0001d797          	auipc	a5,0x1d
    800046ea:	3aa78793          	addi	a5,a5,938 # 80021a90 <log>
    800046ee:	963e                	add	a2,a2,a5
    800046f0:	44dc                	lw	a5,12(s1)
    800046f2:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    800046f4:	8526                	mv	a0,s1
    800046f6:	fffff097          	auipc	ra,0xfffff
    800046fa:	daa080e7          	jalr	-598(ra) # 800034a0 <bpin>
    log.lh.n++;
    800046fe:	0001d717          	auipc	a4,0x1d
    80004702:	39270713          	addi	a4,a4,914 # 80021a90 <log>
    80004706:	575c                	lw	a5,44(a4)
    80004708:	2785                	addiw	a5,a5,1
    8000470a:	d75c                	sw	a5,44(a4)
    8000470c:	a835                	j	80004748 <log_write+0xca>
    panic("too big a transaction");
    8000470e:	00004517          	auipc	a0,0x4
    80004712:	00a50513          	addi	a0,a0,10 # 80008718 <syscalls+0x200>
    80004716:	ffffc097          	auipc	ra,0xffffc
    8000471a:	e28080e7          	jalr	-472(ra) # 8000053e <panic>
    panic("log_write outside of trans");
    8000471e:	00004517          	auipc	a0,0x4
    80004722:	01250513          	addi	a0,a0,18 # 80008730 <syscalls+0x218>
    80004726:	ffffc097          	auipc	ra,0xffffc
    8000472a:	e18080e7          	jalr	-488(ra) # 8000053e <panic>
  log.lh.block[i] = b->blockno;
    8000472e:	00878713          	addi	a4,a5,8
    80004732:	00271693          	slli	a3,a4,0x2
    80004736:	0001d717          	auipc	a4,0x1d
    8000473a:	35a70713          	addi	a4,a4,858 # 80021a90 <log>
    8000473e:	9736                	add	a4,a4,a3
    80004740:	44d4                	lw	a3,12(s1)
    80004742:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80004744:	faf608e3          	beq	a2,a5,800046f4 <log_write+0x76>
  }
  release(&log.lock);
    80004748:	0001d517          	auipc	a0,0x1d
    8000474c:	34850513          	addi	a0,a0,840 # 80021a90 <log>
    80004750:	ffffc097          	auipc	ra,0xffffc
    80004754:	548080e7          	jalr	1352(ra) # 80000c98 <release>
}
    80004758:	60e2                	ld	ra,24(sp)
    8000475a:	6442                	ld	s0,16(sp)
    8000475c:	64a2                	ld	s1,8(sp)
    8000475e:	6902                	ld	s2,0(sp)
    80004760:	6105                	addi	sp,sp,32
    80004762:	8082                	ret

0000000080004764 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004764:	1101                	addi	sp,sp,-32
    80004766:	ec06                	sd	ra,24(sp)
    80004768:	e822                	sd	s0,16(sp)
    8000476a:	e426                	sd	s1,8(sp)
    8000476c:	e04a                	sd	s2,0(sp)
    8000476e:	1000                	addi	s0,sp,32
    80004770:	84aa                	mv	s1,a0
    80004772:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004774:	00004597          	auipc	a1,0x4
    80004778:	fdc58593          	addi	a1,a1,-36 # 80008750 <syscalls+0x238>
    8000477c:	0521                	addi	a0,a0,8
    8000477e:	ffffc097          	auipc	ra,0xffffc
    80004782:	3d6080e7          	jalr	982(ra) # 80000b54 <initlock>
  lk->name = name;
    80004786:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    8000478a:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    8000478e:	0204a423          	sw	zero,40(s1)
}
    80004792:	60e2                	ld	ra,24(sp)
    80004794:	6442                	ld	s0,16(sp)
    80004796:	64a2                	ld	s1,8(sp)
    80004798:	6902                	ld	s2,0(sp)
    8000479a:	6105                	addi	sp,sp,32
    8000479c:	8082                	ret

000000008000479e <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    8000479e:	1101                	addi	sp,sp,-32
    800047a0:	ec06                	sd	ra,24(sp)
    800047a2:	e822                	sd	s0,16(sp)
    800047a4:	e426                	sd	s1,8(sp)
    800047a6:	e04a                	sd	s2,0(sp)
    800047a8:	1000                	addi	s0,sp,32
    800047aa:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800047ac:	00850913          	addi	s2,a0,8
    800047b0:	854a                	mv	a0,s2
    800047b2:	ffffc097          	auipc	ra,0xffffc
    800047b6:	432080e7          	jalr	1074(ra) # 80000be4 <acquire>
  while (lk->locked) {
    800047ba:	409c                	lw	a5,0(s1)
    800047bc:	cb89                	beqz	a5,800047ce <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    800047be:	85ca                	mv	a1,s2
    800047c0:	8526                	mv	a0,s1
    800047c2:	ffffe097          	auipc	ra,0xffffe
    800047c6:	be0080e7          	jalr	-1056(ra) # 800023a2 <sleep>
  while (lk->locked) {
    800047ca:	409c                	lw	a5,0(s1)
    800047cc:	fbed                	bnez	a5,800047be <acquiresleep+0x20>
  }
  lk->locked = 1;
    800047ce:	4785                	li	a5,1
    800047d0:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    800047d2:	ffffd097          	auipc	ra,0xffffd
    800047d6:	1f6080e7          	jalr	502(ra) # 800019c8 <myproc>
    800047da:	591c                	lw	a5,48(a0)
    800047dc:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    800047de:	854a                	mv	a0,s2
    800047e0:	ffffc097          	auipc	ra,0xffffc
    800047e4:	4b8080e7          	jalr	1208(ra) # 80000c98 <release>
}
    800047e8:	60e2                	ld	ra,24(sp)
    800047ea:	6442                	ld	s0,16(sp)
    800047ec:	64a2                	ld	s1,8(sp)
    800047ee:	6902                	ld	s2,0(sp)
    800047f0:	6105                	addi	sp,sp,32
    800047f2:	8082                	ret

00000000800047f4 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    800047f4:	1101                	addi	sp,sp,-32
    800047f6:	ec06                	sd	ra,24(sp)
    800047f8:	e822                	sd	s0,16(sp)
    800047fa:	e426                	sd	s1,8(sp)
    800047fc:	e04a                	sd	s2,0(sp)
    800047fe:	1000                	addi	s0,sp,32
    80004800:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004802:	00850913          	addi	s2,a0,8
    80004806:	854a                	mv	a0,s2
    80004808:	ffffc097          	auipc	ra,0xffffc
    8000480c:	3dc080e7          	jalr	988(ra) # 80000be4 <acquire>
  lk->locked = 0;
    80004810:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004814:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004818:	8526                	mv	a0,s1
    8000481a:	ffffe097          	auipc	ra,0xffffe
    8000481e:	d28080e7          	jalr	-728(ra) # 80002542 <wakeup>
  release(&lk->lk);
    80004822:	854a                	mv	a0,s2
    80004824:	ffffc097          	auipc	ra,0xffffc
    80004828:	474080e7          	jalr	1140(ra) # 80000c98 <release>
}
    8000482c:	60e2                	ld	ra,24(sp)
    8000482e:	6442                	ld	s0,16(sp)
    80004830:	64a2                	ld	s1,8(sp)
    80004832:	6902                	ld	s2,0(sp)
    80004834:	6105                	addi	sp,sp,32
    80004836:	8082                	ret

0000000080004838 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004838:	7179                	addi	sp,sp,-48
    8000483a:	f406                	sd	ra,40(sp)
    8000483c:	f022                	sd	s0,32(sp)
    8000483e:	ec26                	sd	s1,24(sp)
    80004840:	e84a                	sd	s2,16(sp)
    80004842:	e44e                	sd	s3,8(sp)
    80004844:	1800                	addi	s0,sp,48
    80004846:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004848:	00850913          	addi	s2,a0,8
    8000484c:	854a                	mv	a0,s2
    8000484e:	ffffc097          	auipc	ra,0xffffc
    80004852:	396080e7          	jalr	918(ra) # 80000be4 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004856:	409c                	lw	a5,0(s1)
    80004858:	ef99                	bnez	a5,80004876 <holdingsleep+0x3e>
    8000485a:	4481                	li	s1,0
  release(&lk->lk);
    8000485c:	854a                	mv	a0,s2
    8000485e:	ffffc097          	auipc	ra,0xffffc
    80004862:	43a080e7          	jalr	1082(ra) # 80000c98 <release>
  return r;
}
    80004866:	8526                	mv	a0,s1
    80004868:	70a2                	ld	ra,40(sp)
    8000486a:	7402                	ld	s0,32(sp)
    8000486c:	64e2                	ld	s1,24(sp)
    8000486e:	6942                	ld	s2,16(sp)
    80004870:	69a2                	ld	s3,8(sp)
    80004872:	6145                	addi	sp,sp,48
    80004874:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004876:	0284a983          	lw	s3,40(s1)
    8000487a:	ffffd097          	auipc	ra,0xffffd
    8000487e:	14e080e7          	jalr	334(ra) # 800019c8 <myproc>
    80004882:	5904                	lw	s1,48(a0)
    80004884:	413484b3          	sub	s1,s1,s3
    80004888:	0014b493          	seqz	s1,s1
    8000488c:	bfc1                	j	8000485c <holdingsleep+0x24>

000000008000488e <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    8000488e:	1141                	addi	sp,sp,-16
    80004890:	e406                	sd	ra,8(sp)
    80004892:	e022                	sd	s0,0(sp)
    80004894:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004896:	00004597          	auipc	a1,0x4
    8000489a:	eca58593          	addi	a1,a1,-310 # 80008760 <syscalls+0x248>
    8000489e:	0001d517          	auipc	a0,0x1d
    800048a2:	33a50513          	addi	a0,a0,826 # 80021bd8 <ftable>
    800048a6:	ffffc097          	auipc	ra,0xffffc
    800048aa:	2ae080e7          	jalr	686(ra) # 80000b54 <initlock>
}
    800048ae:	60a2                	ld	ra,8(sp)
    800048b0:	6402                	ld	s0,0(sp)
    800048b2:	0141                	addi	sp,sp,16
    800048b4:	8082                	ret

00000000800048b6 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    800048b6:	1101                	addi	sp,sp,-32
    800048b8:	ec06                	sd	ra,24(sp)
    800048ba:	e822                	sd	s0,16(sp)
    800048bc:	e426                	sd	s1,8(sp)
    800048be:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    800048c0:	0001d517          	auipc	a0,0x1d
    800048c4:	31850513          	addi	a0,a0,792 # 80021bd8 <ftable>
    800048c8:	ffffc097          	auipc	ra,0xffffc
    800048cc:	31c080e7          	jalr	796(ra) # 80000be4 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800048d0:	0001d497          	auipc	s1,0x1d
    800048d4:	32048493          	addi	s1,s1,800 # 80021bf0 <ftable+0x18>
    800048d8:	0001e717          	auipc	a4,0x1e
    800048dc:	2b870713          	addi	a4,a4,696 # 80022b90 <ftable+0xfb8>
    if(f->ref == 0){
    800048e0:	40dc                	lw	a5,4(s1)
    800048e2:	cf99                	beqz	a5,80004900 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800048e4:	02848493          	addi	s1,s1,40
    800048e8:	fee49ce3          	bne	s1,a4,800048e0 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    800048ec:	0001d517          	auipc	a0,0x1d
    800048f0:	2ec50513          	addi	a0,a0,748 # 80021bd8 <ftable>
    800048f4:	ffffc097          	auipc	ra,0xffffc
    800048f8:	3a4080e7          	jalr	932(ra) # 80000c98 <release>
  return 0;
    800048fc:	4481                	li	s1,0
    800048fe:	a819                	j	80004914 <filealloc+0x5e>
      f->ref = 1;
    80004900:	4785                	li	a5,1
    80004902:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004904:	0001d517          	auipc	a0,0x1d
    80004908:	2d450513          	addi	a0,a0,724 # 80021bd8 <ftable>
    8000490c:	ffffc097          	auipc	ra,0xffffc
    80004910:	38c080e7          	jalr	908(ra) # 80000c98 <release>
}
    80004914:	8526                	mv	a0,s1
    80004916:	60e2                	ld	ra,24(sp)
    80004918:	6442                	ld	s0,16(sp)
    8000491a:	64a2                	ld	s1,8(sp)
    8000491c:	6105                	addi	sp,sp,32
    8000491e:	8082                	ret

0000000080004920 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004920:	1101                	addi	sp,sp,-32
    80004922:	ec06                	sd	ra,24(sp)
    80004924:	e822                	sd	s0,16(sp)
    80004926:	e426                	sd	s1,8(sp)
    80004928:	1000                	addi	s0,sp,32
    8000492a:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    8000492c:	0001d517          	auipc	a0,0x1d
    80004930:	2ac50513          	addi	a0,a0,684 # 80021bd8 <ftable>
    80004934:	ffffc097          	auipc	ra,0xffffc
    80004938:	2b0080e7          	jalr	688(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    8000493c:	40dc                	lw	a5,4(s1)
    8000493e:	02f05263          	blez	a5,80004962 <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004942:	2785                	addiw	a5,a5,1
    80004944:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004946:	0001d517          	auipc	a0,0x1d
    8000494a:	29250513          	addi	a0,a0,658 # 80021bd8 <ftable>
    8000494e:	ffffc097          	auipc	ra,0xffffc
    80004952:	34a080e7          	jalr	842(ra) # 80000c98 <release>
  return f;
}
    80004956:	8526                	mv	a0,s1
    80004958:	60e2                	ld	ra,24(sp)
    8000495a:	6442                	ld	s0,16(sp)
    8000495c:	64a2                	ld	s1,8(sp)
    8000495e:	6105                	addi	sp,sp,32
    80004960:	8082                	ret
    panic("filedup");
    80004962:	00004517          	auipc	a0,0x4
    80004966:	e0650513          	addi	a0,a0,-506 # 80008768 <syscalls+0x250>
    8000496a:	ffffc097          	auipc	ra,0xffffc
    8000496e:	bd4080e7          	jalr	-1068(ra) # 8000053e <panic>

0000000080004972 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004972:	7139                	addi	sp,sp,-64
    80004974:	fc06                	sd	ra,56(sp)
    80004976:	f822                	sd	s0,48(sp)
    80004978:	f426                	sd	s1,40(sp)
    8000497a:	f04a                	sd	s2,32(sp)
    8000497c:	ec4e                	sd	s3,24(sp)
    8000497e:	e852                	sd	s4,16(sp)
    80004980:	e456                	sd	s5,8(sp)
    80004982:	0080                	addi	s0,sp,64
    80004984:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004986:	0001d517          	auipc	a0,0x1d
    8000498a:	25250513          	addi	a0,a0,594 # 80021bd8 <ftable>
    8000498e:	ffffc097          	auipc	ra,0xffffc
    80004992:	256080e7          	jalr	598(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    80004996:	40dc                	lw	a5,4(s1)
    80004998:	06f05163          	blez	a5,800049fa <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    8000499c:	37fd                	addiw	a5,a5,-1
    8000499e:	0007871b          	sext.w	a4,a5
    800049a2:	c0dc                	sw	a5,4(s1)
    800049a4:	06e04363          	bgtz	a4,80004a0a <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    800049a8:	0004a903          	lw	s2,0(s1)
    800049ac:	0094ca83          	lbu	s5,9(s1)
    800049b0:	0104ba03          	ld	s4,16(s1)
    800049b4:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    800049b8:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    800049bc:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    800049c0:	0001d517          	auipc	a0,0x1d
    800049c4:	21850513          	addi	a0,a0,536 # 80021bd8 <ftable>
    800049c8:	ffffc097          	auipc	ra,0xffffc
    800049cc:	2d0080e7          	jalr	720(ra) # 80000c98 <release>

  if(ff.type == FD_PIPE){
    800049d0:	4785                	li	a5,1
    800049d2:	04f90d63          	beq	s2,a5,80004a2c <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    800049d6:	3979                	addiw	s2,s2,-2
    800049d8:	4785                	li	a5,1
    800049da:	0527e063          	bltu	a5,s2,80004a1a <fileclose+0xa8>
    begin_op();
    800049de:	00000097          	auipc	ra,0x0
    800049e2:	ac8080e7          	jalr	-1336(ra) # 800044a6 <begin_op>
    iput(ff.ip);
    800049e6:	854e                	mv	a0,s3
    800049e8:	fffff097          	auipc	ra,0xfffff
    800049ec:	2a6080e7          	jalr	678(ra) # 80003c8e <iput>
    end_op();
    800049f0:	00000097          	auipc	ra,0x0
    800049f4:	b36080e7          	jalr	-1226(ra) # 80004526 <end_op>
    800049f8:	a00d                	j	80004a1a <fileclose+0xa8>
    panic("fileclose");
    800049fa:	00004517          	auipc	a0,0x4
    800049fe:	d7650513          	addi	a0,a0,-650 # 80008770 <syscalls+0x258>
    80004a02:	ffffc097          	auipc	ra,0xffffc
    80004a06:	b3c080e7          	jalr	-1220(ra) # 8000053e <panic>
    release(&ftable.lock);
    80004a0a:	0001d517          	auipc	a0,0x1d
    80004a0e:	1ce50513          	addi	a0,a0,462 # 80021bd8 <ftable>
    80004a12:	ffffc097          	auipc	ra,0xffffc
    80004a16:	286080e7          	jalr	646(ra) # 80000c98 <release>
  }
}
    80004a1a:	70e2                	ld	ra,56(sp)
    80004a1c:	7442                	ld	s0,48(sp)
    80004a1e:	74a2                	ld	s1,40(sp)
    80004a20:	7902                	ld	s2,32(sp)
    80004a22:	69e2                	ld	s3,24(sp)
    80004a24:	6a42                	ld	s4,16(sp)
    80004a26:	6aa2                	ld	s5,8(sp)
    80004a28:	6121                	addi	sp,sp,64
    80004a2a:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004a2c:	85d6                	mv	a1,s5
    80004a2e:	8552                	mv	a0,s4
    80004a30:	00000097          	auipc	ra,0x0
    80004a34:	34c080e7          	jalr	844(ra) # 80004d7c <pipeclose>
    80004a38:	b7cd                	j	80004a1a <fileclose+0xa8>

0000000080004a3a <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004a3a:	715d                	addi	sp,sp,-80
    80004a3c:	e486                	sd	ra,72(sp)
    80004a3e:	e0a2                	sd	s0,64(sp)
    80004a40:	fc26                	sd	s1,56(sp)
    80004a42:	f84a                	sd	s2,48(sp)
    80004a44:	f44e                	sd	s3,40(sp)
    80004a46:	0880                	addi	s0,sp,80
    80004a48:	84aa                	mv	s1,a0
    80004a4a:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004a4c:	ffffd097          	auipc	ra,0xffffd
    80004a50:	f7c080e7          	jalr	-132(ra) # 800019c8 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004a54:	409c                	lw	a5,0(s1)
    80004a56:	37f9                	addiw	a5,a5,-2
    80004a58:	4705                	li	a4,1
    80004a5a:	04f76763          	bltu	a4,a5,80004aa8 <filestat+0x6e>
    80004a5e:	892a                	mv	s2,a0
    ilock(f->ip);
    80004a60:	6c88                	ld	a0,24(s1)
    80004a62:	fffff097          	auipc	ra,0xfffff
    80004a66:	072080e7          	jalr	114(ra) # 80003ad4 <ilock>
    stati(f->ip, &st);
    80004a6a:	fb840593          	addi	a1,s0,-72
    80004a6e:	6c88                	ld	a0,24(s1)
    80004a70:	fffff097          	auipc	ra,0xfffff
    80004a74:	2ee080e7          	jalr	750(ra) # 80003d5e <stati>
    iunlock(f->ip);
    80004a78:	6c88                	ld	a0,24(s1)
    80004a7a:	fffff097          	auipc	ra,0xfffff
    80004a7e:	11c080e7          	jalr	284(ra) # 80003b96 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004a82:	46e1                	li	a3,24
    80004a84:	fb840613          	addi	a2,s0,-72
    80004a88:	85ce                	mv	a1,s3
    80004a8a:	07093503          	ld	a0,112(s2)
    80004a8e:	ffffd097          	auipc	ra,0xffffd
    80004a92:	bec080e7          	jalr	-1044(ra) # 8000167a <copyout>
    80004a96:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004a9a:	60a6                	ld	ra,72(sp)
    80004a9c:	6406                	ld	s0,64(sp)
    80004a9e:	74e2                	ld	s1,56(sp)
    80004aa0:	7942                	ld	s2,48(sp)
    80004aa2:	79a2                	ld	s3,40(sp)
    80004aa4:	6161                	addi	sp,sp,80
    80004aa6:	8082                	ret
  return -1;
    80004aa8:	557d                	li	a0,-1
    80004aaa:	bfc5                	j	80004a9a <filestat+0x60>

0000000080004aac <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004aac:	7179                	addi	sp,sp,-48
    80004aae:	f406                	sd	ra,40(sp)
    80004ab0:	f022                	sd	s0,32(sp)
    80004ab2:	ec26                	sd	s1,24(sp)
    80004ab4:	e84a                	sd	s2,16(sp)
    80004ab6:	e44e                	sd	s3,8(sp)
    80004ab8:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004aba:	00854783          	lbu	a5,8(a0)
    80004abe:	c3d5                	beqz	a5,80004b62 <fileread+0xb6>
    80004ac0:	84aa                	mv	s1,a0
    80004ac2:	89ae                	mv	s3,a1
    80004ac4:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004ac6:	411c                	lw	a5,0(a0)
    80004ac8:	4705                	li	a4,1
    80004aca:	04e78963          	beq	a5,a4,80004b1c <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004ace:	470d                	li	a4,3
    80004ad0:	04e78d63          	beq	a5,a4,80004b2a <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004ad4:	4709                	li	a4,2
    80004ad6:	06e79e63          	bne	a5,a4,80004b52 <fileread+0xa6>
    ilock(f->ip);
    80004ada:	6d08                	ld	a0,24(a0)
    80004adc:	fffff097          	auipc	ra,0xfffff
    80004ae0:	ff8080e7          	jalr	-8(ra) # 80003ad4 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004ae4:	874a                	mv	a4,s2
    80004ae6:	5094                	lw	a3,32(s1)
    80004ae8:	864e                	mv	a2,s3
    80004aea:	4585                	li	a1,1
    80004aec:	6c88                	ld	a0,24(s1)
    80004aee:	fffff097          	auipc	ra,0xfffff
    80004af2:	29a080e7          	jalr	666(ra) # 80003d88 <readi>
    80004af6:	892a                	mv	s2,a0
    80004af8:	00a05563          	blez	a0,80004b02 <fileread+0x56>
      f->off += r;
    80004afc:	509c                	lw	a5,32(s1)
    80004afe:	9fa9                	addw	a5,a5,a0
    80004b00:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004b02:	6c88                	ld	a0,24(s1)
    80004b04:	fffff097          	auipc	ra,0xfffff
    80004b08:	092080e7          	jalr	146(ra) # 80003b96 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004b0c:	854a                	mv	a0,s2
    80004b0e:	70a2                	ld	ra,40(sp)
    80004b10:	7402                	ld	s0,32(sp)
    80004b12:	64e2                	ld	s1,24(sp)
    80004b14:	6942                	ld	s2,16(sp)
    80004b16:	69a2                	ld	s3,8(sp)
    80004b18:	6145                	addi	sp,sp,48
    80004b1a:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004b1c:	6908                	ld	a0,16(a0)
    80004b1e:	00000097          	auipc	ra,0x0
    80004b22:	3c8080e7          	jalr	968(ra) # 80004ee6 <piperead>
    80004b26:	892a                	mv	s2,a0
    80004b28:	b7d5                	j	80004b0c <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004b2a:	02451783          	lh	a5,36(a0)
    80004b2e:	03079693          	slli	a3,a5,0x30
    80004b32:	92c1                	srli	a3,a3,0x30
    80004b34:	4725                	li	a4,9
    80004b36:	02d76863          	bltu	a4,a3,80004b66 <fileread+0xba>
    80004b3a:	0792                	slli	a5,a5,0x4
    80004b3c:	0001d717          	auipc	a4,0x1d
    80004b40:	ffc70713          	addi	a4,a4,-4 # 80021b38 <devsw>
    80004b44:	97ba                	add	a5,a5,a4
    80004b46:	639c                	ld	a5,0(a5)
    80004b48:	c38d                	beqz	a5,80004b6a <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004b4a:	4505                	li	a0,1
    80004b4c:	9782                	jalr	a5
    80004b4e:	892a                	mv	s2,a0
    80004b50:	bf75                	j	80004b0c <fileread+0x60>
    panic("fileread");
    80004b52:	00004517          	auipc	a0,0x4
    80004b56:	c2e50513          	addi	a0,a0,-978 # 80008780 <syscalls+0x268>
    80004b5a:	ffffc097          	auipc	ra,0xffffc
    80004b5e:	9e4080e7          	jalr	-1564(ra) # 8000053e <panic>
    return -1;
    80004b62:	597d                	li	s2,-1
    80004b64:	b765                	j	80004b0c <fileread+0x60>
      return -1;
    80004b66:	597d                	li	s2,-1
    80004b68:	b755                	j	80004b0c <fileread+0x60>
    80004b6a:	597d                	li	s2,-1
    80004b6c:	b745                	j	80004b0c <fileread+0x60>

0000000080004b6e <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80004b6e:	715d                	addi	sp,sp,-80
    80004b70:	e486                	sd	ra,72(sp)
    80004b72:	e0a2                	sd	s0,64(sp)
    80004b74:	fc26                	sd	s1,56(sp)
    80004b76:	f84a                	sd	s2,48(sp)
    80004b78:	f44e                	sd	s3,40(sp)
    80004b7a:	f052                	sd	s4,32(sp)
    80004b7c:	ec56                	sd	s5,24(sp)
    80004b7e:	e85a                	sd	s6,16(sp)
    80004b80:	e45e                	sd	s7,8(sp)
    80004b82:	e062                	sd	s8,0(sp)
    80004b84:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80004b86:	00954783          	lbu	a5,9(a0)
    80004b8a:	10078663          	beqz	a5,80004c96 <filewrite+0x128>
    80004b8e:	892a                	mv	s2,a0
    80004b90:	8aae                	mv	s5,a1
    80004b92:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004b94:	411c                	lw	a5,0(a0)
    80004b96:	4705                	li	a4,1
    80004b98:	02e78263          	beq	a5,a4,80004bbc <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004b9c:	470d                	li	a4,3
    80004b9e:	02e78663          	beq	a5,a4,80004bca <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004ba2:	4709                	li	a4,2
    80004ba4:	0ee79163          	bne	a5,a4,80004c86 <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004ba8:	0ac05d63          	blez	a2,80004c62 <filewrite+0xf4>
    int i = 0;
    80004bac:	4981                	li	s3,0
    80004bae:	6b05                	lui	s6,0x1
    80004bb0:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80004bb4:	6b85                	lui	s7,0x1
    80004bb6:	c00b8b9b          	addiw	s7,s7,-1024
    80004bba:	a861                	j	80004c52 <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80004bbc:	6908                	ld	a0,16(a0)
    80004bbe:	00000097          	auipc	ra,0x0
    80004bc2:	22e080e7          	jalr	558(ra) # 80004dec <pipewrite>
    80004bc6:	8a2a                	mv	s4,a0
    80004bc8:	a045                	j	80004c68 <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004bca:	02451783          	lh	a5,36(a0)
    80004bce:	03079693          	slli	a3,a5,0x30
    80004bd2:	92c1                	srli	a3,a3,0x30
    80004bd4:	4725                	li	a4,9
    80004bd6:	0cd76263          	bltu	a4,a3,80004c9a <filewrite+0x12c>
    80004bda:	0792                	slli	a5,a5,0x4
    80004bdc:	0001d717          	auipc	a4,0x1d
    80004be0:	f5c70713          	addi	a4,a4,-164 # 80021b38 <devsw>
    80004be4:	97ba                	add	a5,a5,a4
    80004be6:	679c                	ld	a5,8(a5)
    80004be8:	cbdd                	beqz	a5,80004c9e <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80004bea:	4505                	li	a0,1
    80004bec:	9782                	jalr	a5
    80004bee:	8a2a                	mv	s4,a0
    80004bf0:	a8a5                	j	80004c68 <filewrite+0xfa>
    80004bf2:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004bf6:	00000097          	auipc	ra,0x0
    80004bfa:	8b0080e7          	jalr	-1872(ra) # 800044a6 <begin_op>
      ilock(f->ip);
    80004bfe:	01893503          	ld	a0,24(s2)
    80004c02:	fffff097          	auipc	ra,0xfffff
    80004c06:	ed2080e7          	jalr	-302(ra) # 80003ad4 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004c0a:	8762                	mv	a4,s8
    80004c0c:	02092683          	lw	a3,32(s2)
    80004c10:	01598633          	add	a2,s3,s5
    80004c14:	4585                	li	a1,1
    80004c16:	01893503          	ld	a0,24(s2)
    80004c1a:	fffff097          	auipc	ra,0xfffff
    80004c1e:	266080e7          	jalr	614(ra) # 80003e80 <writei>
    80004c22:	84aa                	mv	s1,a0
    80004c24:	00a05763          	blez	a0,80004c32 <filewrite+0xc4>
        f->off += r;
    80004c28:	02092783          	lw	a5,32(s2)
    80004c2c:	9fa9                	addw	a5,a5,a0
    80004c2e:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004c32:	01893503          	ld	a0,24(s2)
    80004c36:	fffff097          	auipc	ra,0xfffff
    80004c3a:	f60080e7          	jalr	-160(ra) # 80003b96 <iunlock>
      end_op();
    80004c3e:	00000097          	auipc	ra,0x0
    80004c42:	8e8080e7          	jalr	-1816(ra) # 80004526 <end_op>

      if(r != n1){
    80004c46:	009c1f63          	bne	s8,s1,80004c64 <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80004c4a:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004c4e:	0149db63          	bge	s3,s4,80004c64 <filewrite+0xf6>
      int n1 = n - i;
    80004c52:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80004c56:	84be                	mv	s1,a5
    80004c58:	2781                	sext.w	a5,a5
    80004c5a:	f8fb5ce3          	bge	s6,a5,80004bf2 <filewrite+0x84>
    80004c5e:	84de                	mv	s1,s7
    80004c60:	bf49                	j	80004bf2 <filewrite+0x84>
    int i = 0;
    80004c62:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004c64:	013a1f63          	bne	s4,s3,80004c82 <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004c68:	8552                	mv	a0,s4
    80004c6a:	60a6                	ld	ra,72(sp)
    80004c6c:	6406                	ld	s0,64(sp)
    80004c6e:	74e2                	ld	s1,56(sp)
    80004c70:	7942                	ld	s2,48(sp)
    80004c72:	79a2                	ld	s3,40(sp)
    80004c74:	7a02                	ld	s4,32(sp)
    80004c76:	6ae2                	ld	s5,24(sp)
    80004c78:	6b42                	ld	s6,16(sp)
    80004c7a:	6ba2                	ld	s7,8(sp)
    80004c7c:	6c02                	ld	s8,0(sp)
    80004c7e:	6161                	addi	sp,sp,80
    80004c80:	8082                	ret
    ret = (i == n ? n : -1);
    80004c82:	5a7d                	li	s4,-1
    80004c84:	b7d5                	j	80004c68 <filewrite+0xfa>
    panic("filewrite");
    80004c86:	00004517          	auipc	a0,0x4
    80004c8a:	b0a50513          	addi	a0,a0,-1270 # 80008790 <syscalls+0x278>
    80004c8e:	ffffc097          	auipc	ra,0xffffc
    80004c92:	8b0080e7          	jalr	-1872(ra) # 8000053e <panic>
    return -1;
    80004c96:	5a7d                	li	s4,-1
    80004c98:	bfc1                	j	80004c68 <filewrite+0xfa>
      return -1;
    80004c9a:	5a7d                	li	s4,-1
    80004c9c:	b7f1                	j	80004c68 <filewrite+0xfa>
    80004c9e:	5a7d                	li	s4,-1
    80004ca0:	b7e1                	j	80004c68 <filewrite+0xfa>

0000000080004ca2 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004ca2:	7179                	addi	sp,sp,-48
    80004ca4:	f406                	sd	ra,40(sp)
    80004ca6:	f022                	sd	s0,32(sp)
    80004ca8:	ec26                	sd	s1,24(sp)
    80004caa:	e84a                	sd	s2,16(sp)
    80004cac:	e44e                	sd	s3,8(sp)
    80004cae:	e052                	sd	s4,0(sp)
    80004cb0:	1800                	addi	s0,sp,48
    80004cb2:	84aa                	mv	s1,a0
    80004cb4:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004cb6:	0005b023          	sd	zero,0(a1)
    80004cba:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004cbe:	00000097          	auipc	ra,0x0
    80004cc2:	bf8080e7          	jalr	-1032(ra) # 800048b6 <filealloc>
    80004cc6:	e088                	sd	a0,0(s1)
    80004cc8:	c551                	beqz	a0,80004d54 <pipealloc+0xb2>
    80004cca:	00000097          	auipc	ra,0x0
    80004cce:	bec080e7          	jalr	-1044(ra) # 800048b6 <filealloc>
    80004cd2:	00aa3023          	sd	a0,0(s4)
    80004cd6:	c92d                	beqz	a0,80004d48 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004cd8:	ffffc097          	auipc	ra,0xffffc
    80004cdc:	e1c080e7          	jalr	-484(ra) # 80000af4 <kalloc>
    80004ce0:	892a                	mv	s2,a0
    80004ce2:	c125                	beqz	a0,80004d42 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004ce4:	4985                	li	s3,1
    80004ce6:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004cea:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004cee:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004cf2:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004cf6:	00004597          	auipc	a1,0x4
    80004cfa:	aaa58593          	addi	a1,a1,-1366 # 800087a0 <syscalls+0x288>
    80004cfe:	ffffc097          	auipc	ra,0xffffc
    80004d02:	e56080e7          	jalr	-426(ra) # 80000b54 <initlock>
  (*f0)->type = FD_PIPE;
    80004d06:	609c                	ld	a5,0(s1)
    80004d08:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004d0c:	609c                	ld	a5,0(s1)
    80004d0e:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004d12:	609c                	ld	a5,0(s1)
    80004d14:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004d18:	609c                	ld	a5,0(s1)
    80004d1a:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004d1e:	000a3783          	ld	a5,0(s4)
    80004d22:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004d26:	000a3783          	ld	a5,0(s4)
    80004d2a:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004d2e:	000a3783          	ld	a5,0(s4)
    80004d32:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004d36:	000a3783          	ld	a5,0(s4)
    80004d3a:	0127b823          	sd	s2,16(a5)
  return 0;
    80004d3e:	4501                	li	a0,0
    80004d40:	a025                	j	80004d68 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004d42:	6088                	ld	a0,0(s1)
    80004d44:	e501                	bnez	a0,80004d4c <pipealloc+0xaa>
    80004d46:	a039                	j	80004d54 <pipealloc+0xb2>
    80004d48:	6088                	ld	a0,0(s1)
    80004d4a:	c51d                	beqz	a0,80004d78 <pipealloc+0xd6>
    fileclose(*f0);
    80004d4c:	00000097          	auipc	ra,0x0
    80004d50:	c26080e7          	jalr	-986(ra) # 80004972 <fileclose>
  if(*f1)
    80004d54:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004d58:	557d                	li	a0,-1
  if(*f1)
    80004d5a:	c799                	beqz	a5,80004d68 <pipealloc+0xc6>
    fileclose(*f1);
    80004d5c:	853e                	mv	a0,a5
    80004d5e:	00000097          	auipc	ra,0x0
    80004d62:	c14080e7          	jalr	-1004(ra) # 80004972 <fileclose>
  return -1;
    80004d66:	557d                	li	a0,-1
}
    80004d68:	70a2                	ld	ra,40(sp)
    80004d6a:	7402                	ld	s0,32(sp)
    80004d6c:	64e2                	ld	s1,24(sp)
    80004d6e:	6942                	ld	s2,16(sp)
    80004d70:	69a2                	ld	s3,8(sp)
    80004d72:	6a02                	ld	s4,0(sp)
    80004d74:	6145                	addi	sp,sp,48
    80004d76:	8082                	ret
  return -1;
    80004d78:	557d                	li	a0,-1
    80004d7a:	b7fd                	j	80004d68 <pipealloc+0xc6>

0000000080004d7c <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004d7c:	1101                	addi	sp,sp,-32
    80004d7e:	ec06                	sd	ra,24(sp)
    80004d80:	e822                	sd	s0,16(sp)
    80004d82:	e426                	sd	s1,8(sp)
    80004d84:	e04a                	sd	s2,0(sp)
    80004d86:	1000                	addi	s0,sp,32
    80004d88:	84aa                	mv	s1,a0
    80004d8a:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004d8c:	ffffc097          	auipc	ra,0xffffc
    80004d90:	e58080e7          	jalr	-424(ra) # 80000be4 <acquire>
  if(writable){
    80004d94:	02090d63          	beqz	s2,80004dce <pipeclose+0x52>
    pi->writeopen = 0;
    80004d98:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004d9c:	21848513          	addi	a0,s1,536
    80004da0:	ffffd097          	auipc	ra,0xffffd
    80004da4:	7a2080e7          	jalr	1954(ra) # 80002542 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004da8:	2204b783          	ld	a5,544(s1)
    80004dac:	eb95                	bnez	a5,80004de0 <pipeclose+0x64>
    release(&pi->lock);
    80004dae:	8526                	mv	a0,s1
    80004db0:	ffffc097          	auipc	ra,0xffffc
    80004db4:	ee8080e7          	jalr	-280(ra) # 80000c98 <release>
    kfree((char*)pi);
    80004db8:	8526                	mv	a0,s1
    80004dba:	ffffc097          	auipc	ra,0xffffc
    80004dbe:	c3e080e7          	jalr	-962(ra) # 800009f8 <kfree>
  } else
    release(&pi->lock);
}
    80004dc2:	60e2                	ld	ra,24(sp)
    80004dc4:	6442                	ld	s0,16(sp)
    80004dc6:	64a2                	ld	s1,8(sp)
    80004dc8:	6902                	ld	s2,0(sp)
    80004dca:	6105                	addi	sp,sp,32
    80004dcc:	8082                	ret
    pi->readopen = 0;
    80004dce:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004dd2:	21c48513          	addi	a0,s1,540
    80004dd6:	ffffd097          	auipc	ra,0xffffd
    80004dda:	76c080e7          	jalr	1900(ra) # 80002542 <wakeup>
    80004dde:	b7e9                	j	80004da8 <pipeclose+0x2c>
    release(&pi->lock);
    80004de0:	8526                	mv	a0,s1
    80004de2:	ffffc097          	auipc	ra,0xffffc
    80004de6:	eb6080e7          	jalr	-330(ra) # 80000c98 <release>
}
    80004dea:	bfe1                	j	80004dc2 <pipeclose+0x46>

0000000080004dec <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004dec:	7159                	addi	sp,sp,-112
    80004dee:	f486                	sd	ra,104(sp)
    80004df0:	f0a2                	sd	s0,96(sp)
    80004df2:	eca6                	sd	s1,88(sp)
    80004df4:	e8ca                	sd	s2,80(sp)
    80004df6:	e4ce                	sd	s3,72(sp)
    80004df8:	e0d2                	sd	s4,64(sp)
    80004dfa:	fc56                	sd	s5,56(sp)
    80004dfc:	f85a                	sd	s6,48(sp)
    80004dfe:	f45e                	sd	s7,40(sp)
    80004e00:	f062                	sd	s8,32(sp)
    80004e02:	ec66                	sd	s9,24(sp)
    80004e04:	1880                	addi	s0,sp,112
    80004e06:	84aa                	mv	s1,a0
    80004e08:	8aae                	mv	s5,a1
    80004e0a:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004e0c:	ffffd097          	auipc	ra,0xffffd
    80004e10:	bbc080e7          	jalr	-1092(ra) # 800019c8 <myproc>
    80004e14:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004e16:	8526                	mv	a0,s1
    80004e18:	ffffc097          	auipc	ra,0xffffc
    80004e1c:	dcc080e7          	jalr	-564(ra) # 80000be4 <acquire>
  while(i < n){
    80004e20:	0d405163          	blez	s4,80004ee2 <pipewrite+0xf6>
    80004e24:	8ba6                	mv	s7,s1
  int i = 0;
    80004e26:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004e28:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004e2a:	21848c93          	addi	s9,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004e2e:	21c48c13          	addi	s8,s1,540
    80004e32:	a08d                	j	80004e94 <pipewrite+0xa8>
      release(&pi->lock);
    80004e34:	8526                	mv	a0,s1
    80004e36:	ffffc097          	auipc	ra,0xffffc
    80004e3a:	e62080e7          	jalr	-414(ra) # 80000c98 <release>
      return -1;
    80004e3e:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004e40:	854a                	mv	a0,s2
    80004e42:	70a6                	ld	ra,104(sp)
    80004e44:	7406                	ld	s0,96(sp)
    80004e46:	64e6                	ld	s1,88(sp)
    80004e48:	6946                	ld	s2,80(sp)
    80004e4a:	69a6                	ld	s3,72(sp)
    80004e4c:	6a06                	ld	s4,64(sp)
    80004e4e:	7ae2                	ld	s5,56(sp)
    80004e50:	7b42                	ld	s6,48(sp)
    80004e52:	7ba2                	ld	s7,40(sp)
    80004e54:	7c02                	ld	s8,32(sp)
    80004e56:	6ce2                	ld	s9,24(sp)
    80004e58:	6165                	addi	sp,sp,112
    80004e5a:	8082                	ret
      wakeup(&pi->nread);
    80004e5c:	8566                	mv	a0,s9
    80004e5e:	ffffd097          	auipc	ra,0xffffd
    80004e62:	6e4080e7          	jalr	1764(ra) # 80002542 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004e66:	85de                	mv	a1,s7
    80004e68:	8562                	mv	a0,s8
    80004e6a:	ffffd097          	auipc	ra,0xffffd
    80004e6e:	538080e7          	jalr	1336(ra) # 800023a2 <sleep>
    80004e72:	a839                	j	80004e90 <pipewrite+0xa4>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004e74:	21c4a783          	lw	a5,540(s1)
    80004e78:	0017871b          	addiw	a4,a5,1
    80004e7c:	20e4ae23          	sw	a4,540(s1)
    80004e80:	1ff7f793          	andi	a5,a5,511
    80004e84:	97a6                	add	a5,a5,s1
    80004e86:	f9f44703          	lbu	a4,-97(s0)
    80004e8a:	00e78c23          	sb	a4,24(a5)
      i++;
    80004e8e:	2905                	addiw	s2,s2,1
  while(i < n){
    80004e90:	03495d63          	bge	s2,s4,80004eca <pipewrite+0xde>
    if(pi->readopen == 0 || pr->killed){
    80004e94:	2204a783          	lw	a5,544(s1)
    80004e98:	dfd1                	beqz	a5,80004e34 <pipewrite+0x48>
    80004e9a:	0289a783          	lw	a5,40(s3)
    80004e9e:	fbd9                	bnez	a5,80004e34 <pipewrite+0x48>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004ea0:	2184a783          	lw	a5,536(s1)
    80004ea4:	21c4a703          	lw	a4,540(s1)
    80004ea8:	2007879b          	addiw	a5,a5,512
    80004eac:	faf708e3          	beq	a4,a5,80004e5c <pipewrite+0x70>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004eb0:	4685                	li	a3,1
    80004eb2:	01590633          	add	a2,s2,s5
    80004eb6:	f9f40593          	addi	a1,s0,-97
    80004eba:	0709b503          	ld	a0,112(s3)
    80004ebe:	ffffd097          	auipc	ra,0xffffd
    80004ec2:	848080e7          	jalr	-1976(ra) # 80001706 <copyin>
    80004ec6:	fb6517e3          	bne	a0,s6,80004e74 <pipewrite+0x88>
  wakeup(&pi->nread);
    80004eca:	21848513          	addi	a0,s1,536
    80004ece:	ffffd097          	auipc	ra,0xffffd
    80004ed2:	674080e7          	jalr	1652(ra) # 80002542 <wakeup>
  release(&pi->lock);
    80004ed6:	8526                	mv	a0,s1
    80004ed8:	ffffc097          	auipc	ra,0xffffc
    80004edc:	dc0080e7          	jalr	-576(ra) # 80000c98 <release>
  return i;
    80004ee0:	b785                	j	80004e40 <pipewrite+0x54>
  int i = 0;
    80004ee2:	4901                	li	s2,0
    80004ee4:	b7dd                	j	80004eca <pipewrite+0xde>

0000000080004ee6 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004ee6:	715d                	addi	sp,sp,-80
    80004ee8:	e486                	sd	ra,72(sp)
    80004eea:	e0a2                	sd	s0,64(sp)
    80004eec:	fc26                	sd	s1,56(sp)
    80004eee:	f84a                	sd	s2,48(sp)
    80004ef0:	f44e                	sd	s3,40(sp)
    80004ef2:	f052                	sd	s4,32(sp)
    80004ef4:	ec56                	sd	s5,24(sp)
    80004ef6:	e85a                	sd	s6,16(sp)
    80004ef8:	0880                	addi	s0,sp,80
    80004efa:	84aa                	mv	s1,a0
    80004efc:	892e                	mv	s2,a1
    80004efe:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004f00:	ffffd097          	auipc	ra,0xffffd
    80004f04:	ac8080e7          	jalr	-1336(ra) # 800019c8 <myproc>
    80004f08:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004f0a:	8b26                	mv	s6,s1
    80004f0c:	8526                	mv	a0,s1
    80004f0e:	ffffc097          	auipc	ra,0xffffc
    80004f12:	cd6080e7          	jalr	-810(ra) # 80000be4 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004f16:	2184a703          	lw	a4,536(s1)
    80004f1a:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004f1e:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004f22:	02f71463          	bne	a4,a5,80004f4a <piperead+0x64>
    80004f26:	2244a783          	lw	a5,548(s1)
    80004f2a:	c385                	beqz	a5,80004f4a <piperead+0x64>
    if(pr->killed){
    80004f2c:	028a2783          	lw	a5,40(s4)
    80004f30:	ebc1                	bnez	a5,80004fc0 <piperead+0xda>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004f32:	85da                	mv	a1,s6
    80004f34:	854e                	mv	a0,s3
    80004f36:	ffffd097          	auipc	ra,0xffffd
    80004f3a:	46c080e7          	jalr	1132(ra) # 800023a2 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004f3e:	2184a703          	lw	a4,536(s1)
    80004f42:	21c4a783          	lw	a5,540(s1)
    80004f46:	fef700e3          	beq	a4,a5,80004f26 <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004f4a:	09505263          	blez	s5,80004fce <piperead+0xe8>
    80004f4e:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004f50:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    80004f52:	2184a783          	lw	a5,536(s1)
    80004f56:	21c4a703          	lw	a4,540(s1)
    80004f5a:	02f70d63          	beq	a4,a5,80004f94 <piperead+0xae>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004f5e:	0017871b          	addiw	a4,a5,1
    80004f62:	20e4ac23          	sw	a4,536(s1)
    80004f66:	1ff7f793          	andi	a5,a5,511
    80004f6a:	97a6                	add	a5,a5,s1
    80004f6c:	0187c783          	lbu	a5,24(a5)
    80004f70:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004f74:	4685                	li	a3,1
    80004f76:	fbf40613          	addi	a2,s0,-65
    80004f7a:	85ca                	mv	a1,s2
    80004f7c:	070a3503          	ld	a0,112(s4)
    80004f80:	ffffc097          	auipc	ra,0xffffc
    80004f84:	6fa080e7          	jalr	1786(ra) # 8000167a <copyout>
    80004f88:	01650663          	beq	a0,s6,80004f94 <piperead+0xae>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004f8c:	2985                	addiw	s3,s3,1
    80004f8e:	0905                	addi	s2,s2,1
    80004f90:	fd3a91e3          	bne	s5,s3,80004f52 <piperead+0x6c>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004f94:	21c48513          	addi	a0,s1,540
    80004f98:	ffffd097          	auipc	ra,0xffffd
    80004f9c:	5aa080e7          	jalr	1450(ra) # 80002542 <wakeup>
  release(&pi->lock);
    80004fa0:	8526                	mv	a0,s1
    80004fa2:	ffffc097          	auipc	ra,0xffffc
    80004fa6:	cf6080e7          	jalr	-778(ra) # 80000c98 <release>
  return i;
}
    80004faa:	854e                	mv	a0,s3
    80004fac:	60a6                	ld	ra,72(sp)
    80004fae:	6406                	ld	s0,64(sp)
    80004fb0:	74e2                	ld	s1,56(sp)
    80004fb2:	7942                	ld	s2,48(sp)
    80004fb4:	79a2                	ld	s3,40(sp)
    80004fb6:	7a02                	ld	s4,32(sp)
    80004fb8:	6ae2                	ld	s5,24(sp)
    80004fba:	6b42                	ld	s6,16(sp)
    80004fbc:	6161                	addi	sp,sp,80
    80004fbe:	8082                	ret
      release(&pi->lock);
    80004fc0:	8526                	mv	a0,s1
    80004fc2:	ffffc097          	auipc	ra,0xffffc
    80004fc6:	cd6080e7          	jalr	-810(ra) # 80000c98 <release>
      return -1;
    80004fca:	59fd                	li	s3,-1
    80004fcc:	bff9                	j	80004faa <piperead+0xc4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004fce:	4981                	li	s3,0
    80004fd0:	b7d1                	j	80004f94 <piperead+0xae>

0000000080004fd2 <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80004fd2:	df010113          	addi	sp,sp,-528
    80004fd6:	20113423          	sd	ra,520(sp)
    80004fda:	20813023          	sd	s0,512(sp)
    80004fde:	ffa6                	sd	s1,504(sp)
    80004fe0:	fbca                	sd	s2,496(sp)
    80004fe2:	f7ce                	sd	s3,488(sp)
    80004fe4:	f3d2                	sd	s4,480(sp)
    80004fe6:	efd6                	sd	s5,472(sp)
    80004fe8:	ebda                	sd	s6,464(sp)
    80004fea:	e7de                	sd	s7,456(sp)
    80004fec:	e3e2                	sd	s8,448(sp)
    80004fee:	ff66                	sd	s9,440(sp)
    80004ff0:	fb6a                	sd	s10,432(sp)
    80004ff2:	f76e                	sd	s11,424(sp)
    80004ff4:	0c00                	addi	s0,sp,528
    80004ff6:	84aa                	mv	s1,a0
    80004ff8:	dea43c23          	sd	a0,-520(s0)
    80004ffc:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80005000:	ffffd097          	auipc	ra,0xffffd
    80005004:	9c8080e7          	jalr	-1592(ra) # 800019c8 <myproc>
    80005008:	892a                	mv	s2,a0

  begin_op();
    8000500a:	fffff097          	auipc	ra,0xfffff
    8000500e:	49c080e7          	jalr	1180(ra) # 800044a6 <begin_op>

  if((ip = namei(path)) == 0){
    80005012:	8526                	mv	a0,s1
    80005014:	fffff097          	auipc	ra,0xfffff
    80005018:	276080e7          	jalr	630(ra) # 8000428a <namei>
    8000501c:	c92d                	beqz	a0,8000508e <exec+0xbc>
    8000501e:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80005020:	fffff097          	auipc	ra,0xfffff
    80005024:	ab4080e7          	jalr	-1356(ra) # 80003ad4 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80005028:	04000713          	li	a4,64
    8000502c:	4681                	li	a3,0
    8000502e:	e5040613          	addi	a2,s0,-432
    80005032:	4581                	li	a1,0
    80005034:	8526                	mv	a0,s1
    80005036:	fffff097          	auipc	ra,0xfffff
    8000503a:	d52080e7          	jalr	-686(ra) # 80003d88 <readi>
    8000503e:	04000793          	li	a5,64
    80005042:	00f51a63          	bne	a0,a5,80005056 <exec+0x84>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80005046:	e5042703          	lw	a4,-432(s0)
    8000504a:	464c47b7          	lui	a5,0x464c4
    8000504e:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80005052:	04f70463          	beq	a4,a5,8000509a <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80005056:	8526                	mv	a0,s1
    80005058:	fffff097          	auipc	ra,0xfffff
    8000505c:	cde080e7          	jalr	-802(ra) # 80003d36 <iunlockput>
    end_op();
    80005060:	fffff097          	auipc	ra,0xfffff
    80005064:	4c6080e7          	jalr	1222(ra) # 80004526 <end_op>
  }
  return -1;
    80005068:	557d                	li	a0,-1
}
    8000506a:	20813083          	ld	ra,520(sp)
    8000506e:	20013403          	ld	s0,512(sp)
    80005072:	74fe                	ld	s1,504(sp)
    80005074:	795e                	ld	s2,496(sp)
    80005076:	79be                	ld	s3,488(sp)
    80005078:	7a1e                	ld	s4,480(sp)
    8000507a:	6afe                	ld	s5,472(sp)
    8000507c:	6b5e                	ld	s6,464(sp)
    8000507e:	6bbe                	ld	s7,456(sp)
    80005080:	6c1e                	ld	s8,448(sp)
    80005082:	7cfa                	ld	s9,440(sp)
    80005084:	7d5a                	ld	s10,432(sp)
    80005086:	7dba                	ld	s11,424(sp)
    80005088:	21010113          	addi	sp,sp,528
    8000508c:	8082                	ret
    end_op();
    8000508e:	fffff097          	auipc	ra,0xfffff
    80005092:	498080e7          	jalr	1176(ra) # 80004526 <end_op>
    return -1;
    80005096:	557d                	li	a0,-1
    80005098:	bfc9                	j	8000506a <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    8000509a:	854a                	mv	a0,s2
    8000509c:	ffffd097          	auipc	ra,0xffffd
    800050a0:	9f0080e7          	jalr	-1552(ra) # 80001a8c <proc_pagetable>
    800050a4:	8baa                	mv	s7,a0
    800050a6:	d945                	beqz	a0,80005056 <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800050a8:	e7042983          	lw	s3,-400(s0)
    800050ac:	e8845783          	lhu	a5,-376(s0)
    800050b0:	c7ad                	beqz	a5,8000511a <exec+0x148>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    800050b2:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800050b4:	4b01                	li	s6,0
    if((ph.vaddr % PGSIZE) != 0)
    800050b6:	6c85                	lui	s9,0x1
    800050b8:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    800050bc:	def43823          	sd	a5,-528(s0)
    800050c0:	a42d                	j	800052ea <exec+0x318>
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    800050c2:	00003517          	auipc	a0,0x3
    800050c6:	6e650513          	addi	a0,a0,1766 # 800087a8 <syscalls+0x290>
    800050ca:	ffffb097          	auipc	ra,0xffffb
    800050ce:	474080e7          	jalr	1140(ra) # 8000053e <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    800050d2:	8756                	mv	a4,s5
    800050d4:	012d86bb          	addw	a3,s11,s2
    800050d8:	4581                	li	a1,0
    800050da:	8526                	mv	a0,s1
    800050dc:	fffff097          	auipc	ra,0xfffff
    800050e0:	cac080e7          	jalr	-852(ra) # 80003d88 <readi>
    800050e4:	2501                	sext.w	a0,a0
    800050e6:	1aaa9963          	bne	s5,a0,80005298 <exec+0x2c6>
  for(i = 0; i < sz; i += PGSIZE){
    800050ea:	6785                	lui	a5,0x1
    800050ec:	0127893b          	addw	s2,a5,s2
    800050f0:	77fd                	lui	a5,0xfffff
    800050f2:	01478a3b          	addw	s4,a5,s4
    800050f6:	1f897163          	bgeu	s2,s8,800052d8 <exec+0x306>
    pa = walkaddr(pagetable, va + i);
    800050fa:	02091593          	slli	a1,s2,0x20
    800050fe:	9181                	srli	a1,a1,0x20
    80005100:	95ea                	add	a1,a1,s10
    80005102:	855e                	mv	a0,s7
    80005104:	ffffc097          	auipc	ra,0xffffc
    80005108:	f72080e7          	jalr	-142(ra) # 80001076 <walkaddr>
    8000510c:	862a                	mv	a2,a0
    if(pa == 0)
    8000510e:	d955                	beqz	a0,800050c2 <exec+0xf0>
      n = PGSIZE;
    80005110:	8ae6                	mv	s5,s9
    if(sz - i < PGSIZE)
    80005112:	fd9a70e3          	bgeu	s4,s9,800050d2 <exec+0x100>
      n = sz - i;
    80005116:	8ad2                	mv	s5,s4
    80005118:	bf6d                	j	800050d2 <exec+0x100>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    8000511a:	4901                	li	s2,0
  iunlockput(ip);
    8000511c:	8526                	mv	a0,s1
    8000511e:	fffff097          	auipc	ra,0xfffff
    80005122:	c18080e7          	jalr	-1000(ra) # 80003d36 <iunlockput>
  end_op();
    80005126:	fffff097          	auipc	ra,0xfffff
    8000512a:	400080e7          	jalr	1024(ra) # 80004526 <end_op>
  p = myproc();
    8000512e:	ffffd097          	auipc	ra,0xffffd
    80005132:	89a080e7          	jalr	-1894(ra) # 800019c8 <myproc>
    80005136:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    80005138:	06853d03          	ld	s10,104(a0)
  sz = PGROUNDUP(sz);
    8000513c:	6785                	lui	a5,0x1
    8000513e:	17fd                	addi	a5,a5,-1
    80005140:	993e                	add	s2,s2,a5
    80005142:	757d                	lui	a0,0xfffff
    80005144:	00a977b3          	and	a5,s2,a0
    80005148:	e0f43423          	sd	a5,-504(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    8000514c:	6609                	lui	a2,0x2
    8000514e:	963e                	add	a2,a2,a5
    80005150:	85be                	mv	a1,a5
    80005152:	855e                	mv	a0,s7
    80005154:	ffffc097          	auipc	ra,0xffffc
    80005158:	2d6080e7          	jalr	726(ra) # 8000142a <uvmalloc>
    8000515c:	8b2a                	mv	s6,a0
  ip = 0;
    8000515e:	4481                	li	s1,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80005160:	12050c63          	beqz	a0,80005298 <exec+0x2c6>
  uvmclear(pagetable, sz-2*PGSIZE);
    80005164:	75f9                	lui	a1,0xffffe
    80005166:	95aa                	add	a1,a1,a0
    80005168:	855e                	mv	a0,s7
    8000516a:	ffffc097          	auipc	ra,0xffffc
    8000516e:	4de080e7          	jalr	1246(ra) # 80001648 <uvmclear>
  stackbase = sp - PGSIZE;
    80005172:	7c7d                	lui	s8,0xfffff
    80005174:	9c5a                	add	s8,s8,s6
  for(argc = 0; argv[argc]; argc++) {
    80005176:	e0043783          	ld	a5,-512(s0)
    8000517a:	6388                	ld	a0,0(a5)
    8000517c:	c535                	beqz	a0,800051e8 <exec+0x216>
    8000517e:	e9040993          	addi	s3,s0,-368
    80005182:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    80005186:	895a                	mv	s2,s6
    sp -= strlen(argv[argc]) + 1;
    80005188:	ffffc097          	auipc	ra,0xffffc
    8000518c:	cdc080e7          	jalr	-804(ra) # 80000e64 <strlen>
    80005190:	2505                	addiw	a0,a0,1
    80005192:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80005196:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    8000519a:	13896363          	bltu	s2,s8,800052c0 <exec+0x2ee>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    8000519e:	e0043d83          	ld	s11,-512(s0)
    800051a2:	000dba03          	ld	s4,0(s11)
    800051a6:	8552                	mv	a0,s4
    800051a8:	ffffc097          	auipc	ra,0xffffc
    800051ac:	cbc080e7          	jalr	-836(ra) # 80000e64 <strlen>
    800051b0:	0015069b          	addiw	a3,a0,1
    800051b4:	8652                	mv	a2,s4
    800051b6:	85ca                	mv	a1,s2
    800051b8:	855e                	mv	a0,s7
    800051ba:	ffffc097          	auipc	ra,0xffffc
    800051be:	4c0080e7          	jalr	1216(ra) # 8000167a <copyout>
    800051c2:	10054363          	bltz	a0,800052c8 <exec+0x2f6>
    ustack[argc] = sp;
    800051c6:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    800051ca:	0485                	addi	s1,s1,1
    800051cc:	008d8793          	addi	a5,s11,8
    800051d0:	e0f43023          	sd	a5,-512(s0)
    800051d4:	008db503          	ld	a0,8(s11)
    800051d8:	c911                	beqz	a0,800051ec <exec+0x21a>
    if(argc >= MAXARG)
    800051da:	09a1                	addi	s3,s3,8
    800051dc:	fb3c96e3          	bne	s9,s3,80005188 <exec+0x1b6>
  sz = sz1;
    800051e0:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800051e4:	4481                	li	s1,0
    800051e6:	a84d                	j	80005298 <exec+0x2c6>
  sp = sz;
    800051e8:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    800051ea:	4481                	li	s1,0
  ustack[argc] = 0;
    800051ec:	00349793          	slli	a5,s1,0x3
    800051f0:	f9040713          	addi	a4,s0,-112
    800051f4:	97ba                	add	a5,a5,a4
    800051f6:	f007b023          	sd	zero,-256(a5) # f00 <_entry-0x7ffff100>
  sp -= (argc+1) * sizeof(uint64);
    800051fa:	00148693          	addi	a3,s1,1
    800051fe:	068e                	slli	a3,a3,0x3
    80005200:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80005204:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80005208:	01897663          	bgeu	s2,s8,80005214 <exec+0x242>
  sz = sz1;
    8000520c:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005210:	4481                	li	s1,0
    80005212:	a059                	j	80005298 <exec+0x2c6>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80005214:	e9040613          	addi	a2,s0,-368
    80005218:	85ca                	mv	a1,s2
    8000521a:	855e                	mv	a0,s7
    8000521c:	ffffc097          	auipc	ra,0xffffc
    80005220:	45e080e7          	jalr	1118(ra) # 8000167a <copyout>
    80005224:	0a054663          	bltz	a0,800052d0 <exec+0x2fe>
  p->trapframe->a1 = sp;
    80005228:	078ab783          	ld	a5,120(s5)
    8000522c:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80005230:	df843783          	ld	a5,-520(s0)
    80005234:	0007c703          	lbu	a4,0(a5)
    80005238:	cf11                	beqz	a4,80005254 <exec+0x282>
    8000523a:	0785                	addi	a5,a5,1
    if(*s == '/')
    8000523c:	02f00693          	li	a3,47
    80005240:	a039                	j	8000524e <exec+0x27c>
      last = s+1;
    80005242:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    80005246:	0785                	addi	a5,a5,1
    80005248:	fff7c703          	lbu	a4,-1(a5)
    8000524c:	c701                	beqz	a4,80005254 <exec+0x282>
    if(*s == '/')
    8000524e:	fed71ce3          	bne	a4,a3,80005246 <exec+0x274>
    80005252:	bfc5                	j	80005242 <exec+0x270>
  safestrcpy(p->name, last, sizeof(p->name));
    80005254:	4641                	li	a2,16
    80005256:	df843583          	ld	a1,-520(s0)
    8000525a:	178a8513          	addi	a0,s5,376
    8000525e:	ffffc097          	auipc	ra,0xffffc
    80005262:	bd4080e7          	jalr	-1068(ra) # 80000e32 <safestrcpy>
  oldpagetable = p->pagetable;
    80005266:	070ab503          	ld	a0,112(s5)
  p->pagetable = pagetable;
    8000526a:	077ab823          	sd	s7,112(s5)
  p->sz = sz;
    8000526e:	076ab423          	sd	s6,104(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80005272:	078ab783          	ld	a5,120(s5)
    80005276:	e6843703          	ld	a4,-408(s0)
    8000527a:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    8000527c:	078ab783          	ld	a5,120(s5)
    80005280:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80005284:	85ea                	mv	a1,s10
    80005286:	ffffd097          	auipc	ra,0xffffd
    8000528a:	8a2080e7          	jalr	-1886(ra) # 80001b28 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    8000528e:	0004851b          	sext.w	a0,s1
    80005292:	bbe1                	j	8000506a <exec+0x98>
    80005294:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    80005298:	e0843583          	ld	a1,-504(s0)
    8000529c:	855e                	mv	a0,s7
    8000529e:	ffffd097          	auipc	ra,0xffffd
    800052a2:	88a080e7          	jalr	-1910(ra) # 80001b28 <proc_freepagetable>
  if(ip){
    800052a6:	da0498e3          	bnez	s1,80005056 <exec+0x84>
  return -1;
    800052aa:	557d                	li	a0,-1
    800052ac:	bb7d                	j	8000506a <exec+0x98>
    800052ae:	e1243423          	sd	s2,-504(s0)
    800052b2:	b7dd                	j	80005298 <exec+0x2c6>
    800052b4:	e1243423          	sd	s2,-504(s0)
    800052b8:	b7c5                	j	80005298 <exec+0x2c6>
    800052ba:	e1243423          	sd	s2,-504(s0)
    800052be:	bfe9                	j	80005298 <exec+0x2c6>
  sz = sz1;
    800052c0:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800052c4:	4481                	li	s1,0
    800052c6:	bfc9                	j	80005298 <exec+0x2c6>
  sz = sz1;
    800052c8:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800052cc:	4481                	li	s1,0
    800052ce:	b7e9                	j	80005298 <exec+0x2c6>
  sz = sz1;
    800052d0:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800052d4:	4481                	li	s1,0
    800052d6:	b7c9                	j	80005298 <exec+0x2c6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    800052d8:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800052dc:	2b05                	addiw	s6,s6,1
    800052de:	0389899b          	addiw	s3,s3,56
    800052e2:	e8845783          	lhu	a5,-376(s0)
    800052e6:	e2fb5be3          	bge	s6,a5,8000511c <exec+0x14a>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    800052ea:	2981                	sext.w	s3,s3
    800052ec:	03800713          	li	a4,56
    800052f0:	86ce                	mv	a3,s3
    800052f2:	e1840613          	addi	a2,s0,-488
    800052f6:	4581                	li	a1,0
    800052f8:	8526                	mv	a0,s1
    800052fa:	fffff097          	auipc	ra,0xfffff
    800052fe:	a8e080e7          	jalr	-1394(ra) # 80003d88 <readi>
    80005302:	03800793          	li	a5,56
    80005306:	f8f517e3          	bne	a0,a5,80005294 <exec+0x2c2>
    if(ph.type != ELF_PROG_LOAD)
    8000530a:	e1842783          	lw	a5,-488(s0)
    8000530e:	4705                	li	a4,1
    80005310:	fce796e3          	bne	a5,a4,800052dc <exec+0x30a>
    if(ph.memsz < ph.filesz)
    80005314:	e4043603          	ld	a2,-448(s0)
    80005318:	e3843783          	ld	a5,-456(s0)
    8000531c:	f8f669e3          	bltu	a2,a5,800052ae <exec+0x2dc>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80005320:	e2843783          	ld	a5,-472(s0)
    80005324:	963e                	add	a2,a2,a5
    80005326:	f8f667e3          	bltu	a2,a5,800052b4 <exec+0x2e2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    8000532a:	85ca                	mv	a1,s2
    8000532c:	855e                	mv	a0,s7
    8000532e:	ffffc097          	auipc	ra,0xffffc
    80005332:	0fc080e7          	jalr	252(ra) # 8000142a <uvmalloc>
    80005336:	e0a43423          	sd	a0,-504(s0)
    8000533a:	d141                	beqz	a0,800052ba <exec+0x2e8>
    if((ph.vaddr % PGSIZE) != 0)
    8000533c:	e2843d03          	ld	s10,-472(s0)
    80005340:	df043783          	ld	a5,-528(s0)
    80005344:	00fd77b3          	and	a5,s10,a5
    80005348:	fba1                	bnez	a5,80005298 <exec+0x2c6>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    8000534a:	e2042d83          	lw	s11,-480(s0)
    8000534e:	e3842c03          	lw	s8,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80005352:	f80c03e3          	beqz	s8,800052d8 <exec+0x306>
    80005356:	8a62                	mv	s4,s8
    80005358:	4901                	li	s2,0
    8000535a:	b345                	j	800050fa <exec+0x128>

000000008000535c <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    8000535c:	7179                	addi	sp,sp,-48
    8000535e:	f406                	sd	ra,40(sp)
    80005360:	f022                	sd	s0,32(sp)
    80005362:	ec26                	sd	s1,24(sp)
    80005364:	e84a                	sd	s2,16(sp)
    80005366:	1800                	addi	s0,sp,48
    80005368:	892e                	mv	s2,a1
    8000536a:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    8000536c:	fdc40593          	addi	a1,s0,-36
    80005370:	ffffe097          	auipc	ra,0xffffe
    80005374:	ba4080e7          	jalr	-1116(ra) # 80002f14 <argint>
    80005378:	04054063          	bltz	a0,800053b8 <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    8000537c:	fdc42703          	lw	a4,-36(s0)
    80005380:	47bd                	li	a5,15
    80005382:	02e7ed63          	bltu	a5,a4,800053bc <argfd+0x60>
    80005386:	ffffc097          	auipc	ra,0xffffc
    8000538a:	642080e7          	jalr	1602(ra) # 800019c8 <myproc>
    8000538e:	fdc42703          	lw	a4,-36(s0)
    80005392:	01e70793          	addi	a5,a4,30
    80005396:	078e                	slli	a5,a5,0x3
    80005398:	953e                	add	a0,a0,a5
    8000539a:	611c                	ld	a5,0(a0)
    8000539c:	c395                	beqz	a5,800053c0 <argfd+0x64>
    return -1;
  if(pfd)
    8000539e:	00090463          	beqz	s2,800053a6 <argfd+0x4a>
    *pfd = fd;
    800053a2:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    800053a6:	4501                	li	a0,0
  if(pf)
    800053a8:	c091                	beqz	s1,800053ac <argfd+0x50>
    *pf = f;
    800053aa:	e09c                	sd	a5,0(s1)
}
    800053ac:	70a2                	ld	ra,40(sp)
    800053ae:	7402                	ld	s0,32(sp)
    800053b0:	64e2                	ld	s1,24(sp)
    800053b2:	6942                	ld	s2,16(sp)
    800053b4:	6145                	addi	sp,sp,48
    800053b6:	8082                	ret
    return -1;
    800053b8:	557d                	li	a0,-1
    800053ba:	bfcd                	j	800053ac <argfd+0x50>
    return -1;
    800053bc:	557d                	li	a0,-1
    800053be:	b7fd                	j	800053ac <argfd+0x50>
    800053c0:	557d                	li	a0,-1
    800053c2:	b7ed                	j	800053ac <argfd+0x50>

00000000800053c4 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    800053c4:	1101                	addi	sp,sp,-32
    800053c6:	ec06                	sd	ra,24(sp)
    800053c8:	e822                	sd	s0,16(sp)
    800053ca:	e426                	sd	s1,8(sp)
    800053cc:	1000                	addi	s0,sp,32
    800053ce:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    800053d0:	ffffc097          	auipc	ra,0xffffc
    800053d4:	5f8080e7          	jalr	1528(ra) # 800019c8 <myproc>
    800053d8:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    800053da:	0f050793          	addi	a5,a0,240 # fffffffffffff0f0 <end+0xffffffff7ffd90f0>
    800053de:	4501                	li	a0,0
    800053e0:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    800053e2:	6398                	ld	a4,0(a5)
    800053e4:	cb19                	beqz	a4,800053fa <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    800053e6:	2505                	addiw	a0,a0,1
    800053e8:	07a1                	addi	a5,a5,8
    800053ea:	fed51ce3          	bne	a0,a3,800053e2 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    800053ee:	557d                	li	a0,-1
}
    800053f0:	60e2                	ld	ra,24(sp)
    800053f2:	6442                	ld	s0,16(sp)
    800053f4:	64a2                	ld	s1,8(sp)
    800053f6:	6105                	addi	sp,sp,32
    800053f8:	8082                	ret
      p->ofile[fd] = f;
    800053fa:	01e50793          	addi	a5,a0,30
    800053fe:	078e                	slli	a5,a5,0x3
    80005400:	963e                	add	a2,a2,a5
    80005402:	e204                	sd	s1,0(a2)
      return fd;
    80005404:	b7f5                	j	800053f0 <fdalloc+0x2c>

0000000080005406 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80005406:	715d                	addi	sp,sp,-80
    80005408:	e486                	sd	ra,72(sp)
    8000540a:	e0a2                	sd	s0,64(sp)
    8000540c:	fc26                	sd	s1,56(sp)
    8000540e:	f84a                	sd	s2,48(sp)
    80005410:	f44e                	sd	s3,40(sp)
    80005412:	f052                	sd	s4,32(sp)
    80005414:	ec56                	sd	s5,24(sp)
    80005416:	0880                	addi	s0,sp,80
    80005418:	89ae                	mv	s3,a1
    8000541a:	8ab2                	mv	s5,a2
    8000541c:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    8000541e:	fb040593          	addi	a1,s0,-80
    80005422:	fffff097          	auipc	ra,0xfffff
    80005426:	e86080e7          	jalr	-378(ra) # 800042a8 <nameiparent>
    8000542a:	892a                	mv	s2,a0
    8000542c:	12050f63          	beqz	a0,8000556a <create+0x164>
    return 0;

  ilock(dp);
    80005430:	ffffe097          	auipc	ra,0xffffe
    80005434:	6a4080e7          	jalr	1700(ra) # 80003ad4 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80005438:	4601                	li	a2,0
    8000543a:	fb040593          	addi	a1,s0,-80
    8000543e:	854a                	mv	a0,s2
    80005440:	fffff097          	auipc	ra,0xfffff
    80005444:	b78080e7          	jalr	-1160(ra) # 80003fb8 <dirlookup>
    80005448:	84aa                	mv	s1,a0
    8000544a:	c921                	beqz	a0,8000549a <create+0x94>
    iunlockput(dp);
    8000544c:	854a                	mv	a0,s2
    8000544e:	fffff097          	auipc	ra,0xfffff
    80005452:	8e8080e7          	jalr	-1816(ra) # 80003d36 <iunlockput>
    ilock(ip);
    80005456:	8526                	mv	a0,s1
    80005458:	ffffe097          	auipc	ra,0xffffe
    8000545c:	67c080e7          	jalr	1660(ra) # 80003ad4 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80005460:	2981                	sext.w	s3,s3
    80005462:	4789                	li	a5,2
    80005464:	02f99463          	bne	s3,a5,8000548c <create+0x86>
    80005468:	0444d783          	lhu	a5,68(s1)
    8000546c:	37f9                	addiw	a5,a5,-2
    8000546e:	17c2                	slli	a5,a5,0x30
    80005470:	93c1                	srli	a5,a5,0x30
    80005472:	4705                	li	a4,1
    80005474:	00f76c63          	bltu	a4,a5,8000548c <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    80005478:	8526                	mv	a0,s1
    8000547a:	60a6                	ld	ra,72(sp)
    8000547c:	6406                	ld	s0,64(sp)
    8000547e:	74e2                	ld	s1,56(sp)
    80005480:	7942                	ld	s2,48(sp)
    80005482:	79a2                	ld	s3,40(sp)
    80005484:	7a02                	ld	s4,32(sp)
    80005486:	6ae2                	ld	s5,24(sp)
    80005488:	6161                	addi	sp,sp,80
    8000548a:	8082                	ret
    iunlockput(ip);
    8000548c:	8526                	mv	a0,s1
    8000548e:	fffff097          	auipc	ra,0xfffff
    80005492:	8a8080e7          	jalr	-1880(ra) # 80003d36 <iunlockput>
    return 0;
    80005496:	4481                	li	s1,0
    80005498:	b7c5                	j	80005478 <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    8000549a:	85ce                	mv	a1,s3
    8000549c:	00092503          	lw	a0,0(s2)
    800054a0:	ffffe097          	auipc	ra,0xffffe
    800054a4:	49c080e7          	jalr	1180(ra) # 8000393c <ialloc>
    800054a8:	84aa                	mv	s1,a0
    800054aa:	c529                	beqz	a0,800054f4 <create+0xee>
  ilock(ip);
    800054ac:	ffffe097          	auipc	ra,0xffffe
    800054b0:	628080e7          	jalr	1576(ra) # 80003ad4 <ilock>
  ip->major = major;
    800054b4:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    800054b8:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    800054bc:	4785                	li	a5,1
    800054be:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800054c2:	8526                	mv	a0,s1
    800054c4:	ffffe097          	auipc	ra,0xffffe
    800054c8:	546080e7          	jalr	1350(ra) # 80003a0a <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    800054cc:	2981                	sext.w	s3,s3
    800054ce:	4785                	li	a5,1
    800054d0:	02f98a63          	beq	s3,a5,80005504 <create+0xfe>
  if(dirlink(dp, name, ip->inum) < 0)
    800054d4:	40d0                	lw	a2,4(s1)
    800054d6:	fb040593          	addi	a1,s0,-80
    800054da:	854a                	mv	a0,s2
    800054dc:	fffff097          	auipc	ra,0xfffff
    800054e0:	cec080e7          	jalr	-788(ra) # 800041c8 <dirlink>
    800054e4:	06054b63          	bltz	a0,8000555a <create+0x154>
  iunlockput(dp);
    800054e8:	854a                	mv	a0,s2
    800054ea:	fffff097          	auipc	ra,0xfffff
    800054ee:	84c080e7          	jalr	-1972(ra) # 80003d36 <iunlockput>
  return ip;
    800054f2:	b759                	j	80005478 <create+0x72>
    panic("create: ialloc");
    800054f4:	00003517          	auipc	a0,0x3
    800054f8:	2d450513          	addi	a0,a0,724 # 800087c8 <syscalls+0x2b0>
    800054fc:	ffffb097          	auipc	ra,0xffffb
    80005500:	042080e7          	jalr	66(ra) # 8000053e <panic>
    dp->nlink++;  // for ".."
    80005504:	04a95783          	lhu	a5,74(s2)
    80005508:	2785                	addiw	a5,a5,1
    8000550a:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    8000550e:	854a                	mv	a0,s2
    80005510:	ffffe097          	auipc	ra,0xffffe
    80005514:	4fa080e7          	jalr	1274(ra) # 80003a0a <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80005518:	40d0                	lw	a2,4(s1)
    8000551a:	00003597          	auipc	a1,0x3
    8000551e:	2be58593          	addi	a1,a1,702 # 800087d8 <syscalls+0x2c0>
    80005522:	8526                	mv	a0,s1
    80005524:	fffff097          	auipc	ra,0xfffff
    80005528:	ca4080e7          	jalr	-860(ra) # 800041c8 <dirlink>
    8000552c:	00054f63          	bltz	a0,8000554a <create+0x144>
    80005530:	00492603          	lw	a2,4(s2)
    80005534:	00003597          	auipc	a1,0x3
    80005538:	2ac58593          	addi	a1,a1,684 # 800087e0 <syscalls+0x2c8>
    8000553c:	8526                	mv	a0,s1
    8000553e:	fffff097          	auipc	ra,0xfffff
    80005542:	c8a080e7          	jalr	-886(ra) # 800041c8 <dirlink>
    80005546:	f80557e3          	bgez	a0,800054d4 <create+0xce>
      panic("create dots");
    8000554a:	00003517          	auipc	a0,0x3
    8000554e:	29e50513          	addi	a0,a0,670 # 800087e8 <syscalls+0x2d0>
    80005552:	ffffb097          	auipc	ra,0xffffb
    80005556:	fec080e7          	jalr	-20(ra) # 8000053e <panic>
    panic("create: dirlink");
    8000555a:	00003517          	auipc	a0,0x3
    8000555e:	29e50513          	addi	a0,a0,670 # 800087f8 <syscalls+0x2e0>
    80005562:	ffffb097          	auipc	ra,0xffffb
    80005566:	fdc080e7          	jalr	-36(ra) # 8000053e <panic>
    return 0;
    8000556a:	84aa                	mv	s1,a0
    8000556c:	b731                	j	80005478 <create+0x72>

000000008000556e <sys_dup>:
{
    8000556e:	7179                	addi	sp,sp,-48
    80005570:	f406                	sd	ra,40(sp)
    80005572:	f022                	sd	s0,32(sp)
    80005574:	ec26                	sd	s1,24(sp)
    80005576:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    80005578:	fd840613          	addi	a2,s0,-40
    8000557c:	4581                	li	a1,0
    8000557e:	4501                	li	a0,0
    80005580:	00000097          	auipc	ra,0x0
    80005584:	ddc080e7          	jalr	-548(ra) # 8000535c <argfd>
    return -1;
    80005588:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    8000558a:	02054363          	bltz	a0,800055b0 <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    8000558e:	fd843503          	ld	a0,-40(s0)
    80005592:	00000097          	auipc	ra,0x0
    80005596:	e32080e7          	jalr	-462(ra) # 800053c4 <fdalloc>
    8000559a:	84aa                	mv	s1,a0
    return -1;
    8000559c:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    8000559e:	00054963          	bltz	a0,800055b0 <sys_dup+0x42>
  filedup(f);
    800055a2:	fd843503          	ld	a0,-40(s0)
    800055a6:	fffff097          	auipc	ra,0xfffff
    800055aa:	37a080e7          	jalr	890(ra) # 80004920 <filedup>
  return fd;
    800055ae:	87a6                	mv	a5,s1
}
    800055b0:	853e                	mv	a0,a5
    800055b2:	70a2                	ld	ra,40(sp)
    800055b4:	7402                	ld	s0,32(sp)
    800055b6:	64e2                	ld	s1,24(sp)
    800055b8:	6145                	addi	sp,sp,48
    800055ba:	8082                	ret

00000000800055bc <sys_read>:
{
    800055bc:	7179                	addi	sp,sp,-48
    800055be:	f406                	sd	ra,40(sp)
    800055c0:	f022                	sd	s0,32(sp)
    800055c2:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800055c4:	fe840613          	addi	a2,s0,-24
    800055c8:	4581                	li	a1,0
    800055ca:	4501                	li	a0,0
    800055cc:	00000097          	auipc	ra,0x0
    800055d0:	d90080e7          	jalr	-624(ra) # 8000535c <argfd>
    return -1;
    800055d4:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800055d6:	04054163          	bltz	a0,80005618 <sys_read+0x5c>
    800055da:	fe440593          	addi	a1,s0,-28
    800055de:	4509                	li	a0,2
    800055e0:	ffffe097          	auipc	ra,0xffffe
    800055e4:	934080e7          	jalr	-1740(ra) # 80002f14 <argint>
    return -1;
    800055e8:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800055ea:	02054763          	bltz	a0,80005618 <sys_read+0x5c>
    800055ee:	fd840593          	addi	a1,s0,-40
    800055f2:	4505                	li	a0,1
    800055f4:	ffffe097          	auipc	ra,0xffffe
    800055f8:	942080e7          	jalr	-1726(ra) # 80002f36 <argaddr>
    return -1;
    800055fc:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800055fe:	00054d63          	bltz	a0,80005618 <sys_read+0x5c>
  return fileread(f, p, n);
    80005602:	fe442603          	lw	a2,-28(s0)
    80005606:	fd843583          	ld	a1,-40(s0)
    8000560a:	fe843503          	ld	a0,-24(s0)
    8000560e:	fffff097          	auipc	ra,0xfffff
    80005612:	49e080e7          	jalr	1182(ra) # 80004aac <fileread>
    80005616:	87aa                	mv	a5,a0
}
    80005618:	853e                	mv	a0,a5
    8000561a:	70a2                	ld	ra,40(sp)
    8000561c:	7402                	ld	s0,32(sp)
    8000561e:	6145                	addi	sp,sp,48
    80005620:	8082                	ret

0000000080005622 <sys_write>:
{
    80005622:	7179                	addi	sp,sp,-48
    80005624:	f406                	sd	ra,40(sp)
    80005626:	f022                	sd	s0,32(sp)
    80005628:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000562a:	fe840613          	addi	a2,s0,-24
    8000562e:	4581                	li	a1,0
    80005630:	4501                	li	a0,0
    80005632:	00000097          	auipc	ra,0x0
    80005636:	d2a080e7          	jalr	-726(ra) # 8000535c <argfd>
    return -1;
    8000563a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000563c:	04054163          	bltz	a0,8000567e <sys_write+0x5c>
    80005640:	fe440593          	addi	a1,s0,-28
    80005644:	4509                	li	a0,2
    80005646:	ffffe097          	auipc	ra,0xffffe
    8000564a:	8ce080e7          	jalr	-1842(ra) # 80002f14 <argint>
    return -1;
    8000564e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005650:	02054763          	bltz	a0,8000567e <sys_write+0x5c>
    80005654:	fd840593          	addi	a1,s0,-40
    80005658:	4505                	li	a0,1
    8000565a:	ffffe097          	auipc	ra,0xffffe
    8000565e:	8dc080e7          	jalr	-1828(ra) # 80002f36 <argaddr>
    return -1;
    80005662:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005664:	00054d63          	bltz	a0,8000567e <sys_write+0x5c>
  return filewrite(f, p, n);
    80005668:	fe442603          	lw	a2,-28(s0)
    8000566c:	fd843583          	ld	a1,-40(s0)
    80005670:	fe843503          	ld	a0,-24(s0)
    80005674:	fffff097          	auipc	ra,0xfffff
    80005678:	4fa080e7          	jalr	1274(ra) # 80004b6e <filewrite>
    8000567c:	87aa                	mv	a5,a0
}
    8000567e:	853e                	mv	a0,a5
    80005680:	70a2                	ld	ra,40(sp)
    80005682:	7402                	ld	s0,32(sp)
    80005684:	6145                	addi	sp,sp,48
    80005686:	8082                	ret

0000000080005688 <sys_close>:
{
    80005688:	1101                	addi	sp,sp,-32
    8000568a:	ec06                	sd	ra,24(sp)
    8000568c:	e822                	sd	s0,16(sp)
    8000568e:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    80005690:	fe040613          	addi	a2,s0,-32
    80005694:	fec40593          	addi	a1,s0,-20
    80005698:	4501                	li	a0,0
    8000569a:	00000097          	auipc	ra,0x0
    8000569e:	cc2080e7          	jalr	-830(ra) # 8000535c <argfd>
    return -1;
    800056a2:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    800056a4:	02054463          	bltz	a0,800056cc <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    800056a8:	ffffc097          	auipc	ra,0xffffc
    800056ac:	320080e7          	jalr	800(ra) # 800019c8 <myproc>
    800056b0:	fec42783          	lw	a5,-20(s0)
    800056b4:	07f9                	addi	a5,a5,30
    800056b6:	078e                	slli	a5,a5,0x3
    800056b8:	97aa                	add	a5,a5,a0
    800056ba:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    800056be:	fe043503          	ld	a0,-32(s0)
    800056c2:	fffff097          	auipc	ra,0xfffff
    800056c6:	2b0080e7          	jalr	688(ra) # 80004972 <fileclose>
  return 0;
    800056ca:	4781                	li	a5,0
}
    800056cc:	853e                	mv	a0,a5
    800056ce:	60e2                	ld	ra,24(sp)
    800056d0:	6442                	ld	s0,16(sp)
    800056d2:	6105                	addi	sp,sp,32
    800056d4:	8082                	ret

00000000800056d6 <sys_fstat>:
{
    800056d6:	1101                	addi	sp,sp,-32
    800056d8:	ec06                	sd	ra,24(sp)
    800056da:	e822                	sd	s0,16(sp)
    800056dc:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800056de:	fe840613          	addi	a2,s0,-24
    800056e2:	4581                	li	a1,0
    800056e4:	4501                	li	a0,0
    800056e6:	00000097          	auipc	ra,0x0
    800056ea:	c76080e7          	jalr	-906(ra) # 8000535c <argfd>
    return -1;
    800056ee:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800056f0:	02054563          	bltz	a0,8000571a <sys_fstat+0x44>
    800056f4:	fe040593          	addi	a1,s0,-32
    800056f8:	4505                	li	a0,1
    800056fa:	ffffe097          	auipc	ra,0xffffe
    800056fe:	83c080e7          	jalr	-1988(ra) # 80002f36 <argaddr>
    return -1;
    80005702:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005704:	00054b63          	bltz	a0,8000571a <sys_fstat+0x44>
  return filestat(f, st);
    80005708:	fe043583          	ld	a1,-32(s0)
    8000570c:	fe843503          	ld	a0,-24(s0)
    80005710:	fffff097          	auipc	ra,0xfffff
    80005714:	32a080e7          	jalr	810(ra) # 80004a3a <filestat>
    80005718:	87aa                	mv	a5,a0
}
    8000571a:	853e                	mv	a0,a5
    8000571c:	60e2                	ld	ra,24(sp)
    8000571e:	6442                	ld	s0,16(sp)
    80005720:	6105                	addi	sp,sp,32
    80005722:	8082                	ret

0000000080005724 <sys_link>:
{
    80005724:	7169                	addi	sp,sp,-304
    80005726:	f606                	sd	ra,296(sp)
    80005728:	f222                	sd	s0,288(sp)
    8000572a:	ee26                	sd	s1,280(sp)
    8000572c:	ea4a                	sd	s2,272(sp)
    8000572e:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005730:	08000613          	li	a2,128
    80005734:	ed040593          	addi	a1,s0,-304
    80005738:	4501                	li	a0,0
    8000573a:	ffffe097          	auipc	ra,0xffffe
    8000573e:	81e080e7          	jalr	-2018(ra) # 80002f58 <argstr>
    return -1;
    80005742:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005744:	10054e63          	bltz	a0,80005860 <sys_link+0x13c>
    80005748:	08000613          	li	a2,128
    8000574c:	f5040593          	addi	a1,s0,-176
    80005750:	4505                	li	a0,1
    80005752:	ffffe097          	auipc	ra,0xffffe
    80005756:	806080e7          	jalr	-2042(ra) # 80002f58 <argstr>
    return -1;
    8000575a:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000575c:	10054263          	bltz	a0,80005860 <sys_link+0x13c>
  begin_op();
    80005760:	fffff097          	auipc	ra,0xfffff
    80005764:	d46080e7          	jalr	-698(ra) # 800044a6 <begin_op>
  if((ip = namei(old)) == 0){
    80005768:	ed040513          	addi	a0,s0,-304
    8000576c:	fffff097          	auipc	ra,0xfffff
    80005770:	b1e080e7          	jalr	-1250(ra) # 8000428a <namei>
    80005774:	84aa                	mv	s1,a0
    80005776:	c551                	beqz	a0,80005802 <sys_link+0xde>
  ilock(ip);
    80005778:	ffffe097          	auipc	ra,0xffffe
    8000577c:	35c080e7          	jalr	860(ra) # 80003ad4 <ilock>
  if(ip->type == T_DIR){
    80005780:	04449703          	lh	a4,68(s1)
    80005784:	4785                	li	a5,1
    80005786:	08f70463          	beq	a4,a5,8000580e <sys_link+0xea>
  ip->nlink++;
    8000578a:	04a4d783          	lhu	a5,74(s1)
    8000578e:	2785                	addiw	a5,a5,1
    80005790:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005794:	8526                	mv	a0,s1
    80005796:	ffffe097          	auipc	ra,0xffffe
    8000579a:	274080e7          	jalr	628(ra) # 80003a0a <iupdate>
  iunlock(ip);
    8000579e:	8526                	mv	a0,s1
    800057a0:	ffffe097          	auipc	ra,0xffffe
    800057a4:	3f6080e7          	jalr	1014(ra) # 80003b96 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    800057a8:	fd040593          	addi	a1,s0,-48
    800057ac:	f5040513          	addi	a0,s0,-176
    800057b0:	fffff097          	auipc	ra,0xfffff
    800057b4:	af8080e7          	jalr	-1288(ra) # 800042a8 <nameiparent>
    800057b8:	892a                	mv	s2,a0
    800057ba:	c935                	beqz	a0,8000582e <sys_link+0x10a>
  ilock(dp);
    800057bc:	ffffe097          	auipc	ra,0xffffe
    800057c0:	318080e7          	jalr	792(ra) # 80003ad4 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    800057c4:	00092703          	lw	a4,0(s2)
    800057c8:	409c                	lw	a5,0(s1)
    800057ca:	04f71d63          	bne	a4,a5,80005824 <sys_link+0x100>
    800057ce:	40d0                	lw	a2,4(s1)
    800057d0:	fd040593          	addi	a1,s0,-48
    800057d4:	854a                	mv	a0,s2
    800057d6:	fffff097          	auipc	ra,0xfffff
    800057da:	9f2080e7          	jalr	-1550(ra) # 800041c8 <dirlink>
    800057de:	04054363          	bltz	a0,80005824 <sys_link+0x100>
  iunlockput(dp);
    800057e2:	854a                	mv	a0,s2
    800057e4:	ffffe097          	auipc	ra,0xffffe
    800057e8:	552080e7          	jalr	1362(ra) # 80003d36 <iunlockput>
  iput(ip);
    800057ec:	8526                	mv	a0,s1
    800057ee:	ffffe097          	auipc	ra,0xffffe
    800057f2:	4a0080e7          	jalr	1184(ra) # 80003c8e <iput>
  end_op();
    800057f6:	fffff097          	auipc	ra,0xfffff
    800057fa:	d30080e7          	jalr	-720(ra) # 80004526 <end_op>
  return 0;
    800057fe:	4781                	li	a5,0
    80005800:	a085                	j	80005860 <sys_link+0x13c>
    end_op();
    80005802:	fffff097          	auipc	ra,0xfffff
    80005806:	d24080e7          	jalr	-732(ra) # 80004526 <end_op>
    return -1;
    8000580a:	57fd                	li	a5,-1
    8000580c:	a891                	j	80005860 <sys_link+0x13c>
    iunlockput(ip);
    8000580e:	8526                	mv	a0,s1
    80005810:	ffffe097          	auipc	ra,0xffffe
    80005814:	526080e7          	jalr	1318(ra) # 80003d36 <iunlockput>
    end_op();
    80005818:	fffff097          	auipc	ra,0xfffff
    8000581c:	d0e080e7          	jalr	-754(ra) # 80004526 <end_op>
    return -1;
    80005820:	57fd                	li	a5,-1
    80005822:	a83d                	j	80005860 <sys_link+0x13c>
    iunlockput(dp);
    80005824:	854a                	mv	a0,s2
    80005826:	ffffe097          	auipc	ra,0xffffe
    8000582a:	510080e7          	jalr	1296(ra) # 80003d36 <iunlockput>
  ilock(ip);
    8000582e:	8526                	mv	a0,s1
    80005830:	ffffe097          	auipc	ra,0xffffe
    80005834:	2a4080e7          	jalr	676(ra) # 80003ad4 <ilock>
  ip->nlink--;
    80005838:	04a4d783          	lhu	a5,74(s1)
    8000583c:	37fd                	addiw	a5,a5,-1
    8000583e:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005842:	8526                	mv	a0,s1
    80005844:	ffffe097          	auipc	ra,0xffffe
    80005848:	1c6080e7          	jalr	454(ra) # 80003a0a <iupdate>
  iunlockput(ip);
    8000584c:	8526                	mv	a0,s1
    8000584e:	ffffe097          	auipc	ra,0xffffe
    80005852:	4e8080e7          	jalr	1256(ra) # 80003d36 <iunlockput>
  end_op();
    80005856:	fffff097          	auipc	ra,0xfffff
    8000585a:	cd0080e7          	jalr	-816(ra) # 80004526 <end_op>
  return -1;
    8000585e:	57fd                	li	a5,-1
}
    80005860:	853e                	mv	a0,a5
    80005862:	70b2                	ld	ra,296(sp)
    80005864:	7412                	ld	s0,288(sp)
    80005866:	64f2                	ld	s1,280(sp)
    80005868:	6952                	ld	s2,272(sp)
    8000586a:	6155                	addi	sp,sp,304
    8000586c:	8082                	ret

000000008000586e <sys_unlink>:
{
    8000586e:	7151                	addi	sp,sp,-240
    80005870:	f586                	sd	ra,232(sp)
    80005872:	f1a2                	sd	s0,224(sp)
    80005874:	eda6                	sd	s1,216(sp)
    80005876:	e9ca                	sd	s2,208(sp)
    80005878:	e5ce                	sd	s3,200(sp)
    8000587a:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    8000587c:	08000613          	li	a2,128
    80005880:	f3040593          	addi	a1,s0,-208
    80005884:	4501                	li	a0,0
    80005886:	ffffd097          	auipc	ra,0xffffd
    8000588a:	6d2080e7          	jalr	1746(ra) # 80002f58 <argstr>
    8000588e:	18054163          	bltz	a0,80005a10 <sys_unlink+0x1a2>
  begin_op();
    80005892:	fffff097          	auipc	ra,0xfffff
    80005896:	c14080e7          	jalr	-1004(ra) # 800044a6 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    8000589a:	fb040593          	addi	a1,s0,-80
    8000589e:	f3040513          	addi	a0,s0,-208
    800058a2:	fffff097          	auipc	ra,0xfffff
    800058a6:	a06080e7          	jalr	-1530(ra) # 800042a8 <nameiparent>
    800058aa:	84aa                	mv	s1,a0
    800058ac:	c979                	beqz	a0,80005982 <sys_unlink+0x114>
  ilock(dp);
    800058ae:	ffffe097          	auipc	ra,0xffffe
    800058b2:	226080e7          	jalr	550(ra) # 80003ad4 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    800058b6:	00003597          	auipc	a1,0x3
    800058ba:	f2258593          	addi	a1,a1,-222 # 800087d8 <syscalls+0x2c0>
    800058be:	fb040513          	addi	a0,s0,-80
    800058c2:	ffffe097          	auipc	ra,0xffffe
    800058c6:	6dc080e7          	jalr	1756(ra) # 80003f9e <namecmp>
    800058ca:	14050a63          	beqz	a0,80005a1e <sys_unlink+0x1b0>
    800058ce:	00003597          	auipc	a1,0x3
    800058d2:	f1258593          	addi	a1,a1,-238 # 800087e0 <syscalls+0x2c8>
    800058d6:	fb040513          	addi	a0,s0,-80
    800058da:	ffffe097          	auipc	ra,0xffffe
    800058de:	6c4080e7          	jalr	1732(ra) # 80003f9e <namecmp>
    800058e2:	12050e63          	beqz	a0,80005a1e <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    800058e6:	f2c40613          	addi	a2,s0,-212
    800058ea:	fb040593          	addi	a1,s0,-80
    800058ee:	8526                	mv	a0,s1
    800058f0:	ffffe097          	auipc	ra,0xffffe
    800058f4:	6c8080e7          	jalr	1736(ra) # 80003fb8 <dirlookup>
    800058f8:	892a                	mv	s2,a0
    800058fa:	12050263          	beqz	a0,80005a1e <sys_unlink+0x1b0>
  ilock(ip);
    800058fe:	ffffe097          	auipc	ra,0xffffe
    80005902:	1d6080e7          	jalr	470(ra) # 80003ad4 <ilock>
  if(ip->nlink < 1)
    80005906:	04a91783          	lh	a5,74(s2)
    8000590a:	08f05263          	blez	a5,8000598e <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    8000590e:	04491703          	lh	a4,68(s2)
    80005912:	4785                	li	a5,1
    80005914:	08f70563          	beq	a4,a5,8000599e <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005918:	4641                	li	a2,16
    8000591a:	4581                	li	a1,0
    8000591c:	fc040513          	addi	a0,s0,-64
    80005920:	ffffb097          	auipc	ra,0xffffb
    80005924:	3c0080e7          	jalr	960(ra) # 80000ce0 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005928:	4741                	li	a4,16
    8000592a:	f2c42683          	lw	a3,-212(s0)
    8000592e:	fc040613          	addi	a2,s0,-64
    80005932:	4581                	li	a1,0
    80005934:	8526                	mv	a0,s1
    80005936:	ffffe097          	auipc	ra,0xffffe
    8000593a:	54a080e7          	jalr	1354(ra) # 80003e80 <writei>
    8000593e:	47c1                	li	a5,16
    80005940:	0af51563          	bne	a0,a5,800059ea <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005944:	04491703          	lh	a4,68(s2)
    80005948:	4785                	li	a5,1
    8000594a:	0af70863          	beq	a4,a5,800059fa <sys_unlink+0x18c>
  iunlockput(dp);
    8000594e:	8526                	mv	a0,s1
    80005950:	ffffe097          	auipc	ra,0xffffe
    80005954:	3e6080e7          	jalr	998(ra) # 80003d36 <iunlockput>
  ip->nlink--;
    80005958:	04a95783          	lhu	a5,74(s2)
    8000595c:	37fd                	addiw	a5,a5,-1
    8000595e:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005962:	854a                	mv	a0,s2
    80005964:	ffffe097          	auipc	ra,0xffffe
    80005968:	0a6080e7          	jalr	166(ra) # 80003a0a <iupdate>
  iunlockput(ip);
    8000596c:	854a                	mv	a0,s2
    8000596e:	ffffe097          	auipc	ra,0xffffe
    80005972:	3c8080e7          	jalr	968(ra) # 80003d36 <iunlockput>
  end_op();
    80005976:	fffff097          	auipc	ra,0xfffff
    8000597a:	bb0080e7          	jalr	-1104(ra) # 80004526 <end_op>
  return 0;
    8000597e:	4501                	li	a0,0
    80005980:	a84d                	j	80005a32 <sys_unlink+0x1c4>
    end_op();
    80005982:	fffff097          	auipc	ra,0xfffff
    80005986:	ba4080e7          	jalr	-1116(ra) # 80004526 <end_op>
    return -1;
    8000598a:	557d                	li	a0,-1
    8000598c:	a05d                	j	80005a32 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    8000598e:	00003517          	auipc	a0,0x3
    80005992:	e7a50513          	addi	a0,a0,-390 # 80008808 <syscalls+0x2f0>
    80005996:	ffffb097          	auipc	ra,0xffffb
    8000599a:	ba8080e7          	jalr	-1112(ra) # 8000053e <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    8000599e:	04c92703          	lw	a4,76(s2)
    800059a2:	02000793          	li	a5,32
    800059a6:	f6e7f9e3          	bgeu	a5,a4,80005918 <sys_unlink+0xaa>
    800059aa:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800059ae:	4741                	li	a4,16
    800059b0:	86ce                	mv	a3,s3
    800059b2:	f1840613          	addi	a2,s0,-232
    800059b6:	4581                	li	a1,0
    800059b8:	854a                	mv	a0,s2
    800059ba:	ffffe097          	auipc	ra,0xffffe
    800059be:	3ce080e7          	jalr	974(ra) # 80003d88 <readi>
    800059c2:	47c1                	li	a5,16
    800059c4:	00f51b63          	bne	a0,a5,800059da <sys_unlink+0x16c>
    if(de.inum != 0)
    800059c8:	f1845783          	lhu	a5,-232(s0)
    800059cc:	e7a1                	bnez	a5,80005a14 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800059ce:	29c1                	addiw	s3,s3,16
    800059d0:	04c92783          	lw	a5,76(s2)
    800059d4:	fcf9ede3          	bltu	s3,a5,800059ae <sys_unlink+0x140>
    800059d8:	b781                	j	80005918 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    800059da:	00003517          	auipc	a0,0x3
    800059de:	e4650513          	addi	a0,a0,-442 # 80008820 <syscalls+0x308>
    800059e2:	ffffb097          	auipc	ra,0xffffb
    800059e6:	b5c080e7          	jalr	-1188(ra) # 8000053e <panic>
    panic("unlink: writei");
    800059ea:	00003517          	auipc	a0,0x3
    800059ee:	e4e50513          	addi	a0,a0,-434 # 80008838 <syscalls+0x320>
    800059f2:	ffffb097          	auipc	ra,0xffffb
    800059f6:	b4c080e7          	jalr	-1204(ra) # 8000053e <panic>
    dp->nlink--;
    800059fa:	04a4d783          	lhu	a5,74(s1)
    800059fe:	37fd                	addiw	a5,a5,-1
    80005a00:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005a04:	8526                	mv	a0,s1
    80005a06:	ffffe097          	auipc	ra,0xffffe
    80005a0a:	004080e7          	jalr	4(ra) # 80003a0a <iupdate>
    80005a0e:	b781                	j	8000594e <sys_unlink+0xe0>
    return -1;
    80005a10:	557d                	li	a0,-1
    80005a12:	a005                	j	80005a32 <sys_unlink+0x1c4>
    iunlockput(ip);
    80005a14:	854a                	mv	a0,s2
    80005a16:	ffffe097          	auipc	ra,0xffffe
    80005a1a:	320080e7          	jalr	800(ra) # 80003d36 <iunlockput>
  iunlockput(dp);
    80005a1e:	8526                	mv	a0,s1
    80005a20:	ffffe097          	auipc	ra,0xffffe
    80005a24:	316080e7          	jalr	790(ra) # 80003d36 <iunlockput>
  end_op();
    80005a28:	fffff097          	auipc	ra,0xfffff
    80005a2c:	afe080e7          	jalr	-1282(ra) # 80004526 <end_op>
  return -1;
    80005a30:	557d                	li	a0,-1
}
    80005a32:	70ae                	ld	ra,232(sp)
    80005a34:	740e                	ld	s0,224(sp)
    80005a36:	64ee                	ld	s1,216(sp)
    80005a38:	694e                	ld	s2,208(sp)
    80005a3a:	69ae                	ld	s3,200(sp)
    80005a3c:	616d                	addi	sp,sp,240
    80005a3e:	8082                	ret

0000000080005a40 <sys_open>:

uint64
sys_open(void)
{
    80005a40:	7131                	addi	sp,sp,-192
    80005a42:	fd06                	sd	ra,184(sp)
    80005a44:	f922                	sd	s0,176(sp)
    80005a46:	f526                	sd	s1,168(sp)
    80005a48:	f14a                	sd	s2,160(sp)
    80005a4a:	ed4e                	sd	s3,152(sp)
    80005a4c:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005a4e:	08000613          	li	a2,128
    80005a52:	f5040593          	addi	a1,s0,-176
    80005a56:	4501                	li	a0,0
    80005a58:	ffffd097          	auipc	ra,0xffffd
    80005a5c:	500080e7          	jalr	1280(ra) # 80002f58 <argstr>
    return -1;
    80005a60:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005a62:	0c054163          	bltz	a0,80005b24 <sys_open+0xe4>
    80005a66:	f4c40593          	addi	a1,s0,-180
    80005a6a:	4505                	li	a0,1
    80005a6c:	ffffd097          	auipc	ra,0xffffd
    80005a70:	4a8080e7          	jalr	1192(ra) # 80002f14 <argint>
    80005a74:	0a054863          	bltz	a0,80005b24 <sys_open+0xe4>

  begin_op();
    80005a78:	fffff097          	auipc	ra,0xfffff
    80005a7c:	a2e080e7          	jalr	-1490(ra) # 800044a6 <begin_op>

  if(omode & O_CREATE){
    80005a80:	f4c42783          	lw	a5,-180(s0)
    80005a84:	2007f793          	andi	a5,a5,512
    80005a88:	cbdd                	beqz	a5,80005b3e <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005a8a:	4681                	li	a3,0
    80005a8c:	4601                	li	a2,0
    80005a8e:	4589                	li	a1,2
    80005a90:	f5040513          	addi	a0,s0,-176
    80005a94:	00000097          	auipc	ra,0x0
    80005a98:	972080e7          	jalr	-1678(ra) # 80005406 <create>
    80005a9c:	892a                	mv	s2,a0
    if(ip == 0){
    80005a9e:	c959                	beqz	a0,80005b34 <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005aa0:	04491703          	lh	a4,68(s2)
    80005aa4:	478d                	li	a5,3
    80005aa6:	00f71763          	bne	a4,a5,80005ab4 <sys_open+0x74>
    80005aaa:	04695703          	lhu	a4,70(s2)
    80005aae:	47a5                	li	a5,9
    80005ab0:	0ce7ec63          	bltu	a5,a4,80005b88 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005ab4:	fffff097          	auipc	ra,0xfffff
    80005ab8:	e02080e7          	jalr	-510(ra) # 800048b6 <filealloc>
    80005abc:	89aa                	mv	s3,a0
    80005abe:	10050263          	beqz	a0,80005bc2 <sys_open+0x182>
    80005ac2:	00000097          	auipc	ra,0x0
    80005ac6:	902080e7          	jalr	-1790(ra) # 800053c4 <fdalloc>
    80005aca:	84aa                	mv	s1,a0
    80005acc:	0e054663          	bltz	a0,80005bb8 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005ad0:	04491703          	lh	a4,68(s2)
    80005ad4:	478d                	li	a5,3
    80005ad6:	0cf70463          	beq	a4,a5,80005b9e <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005ada:	4789                	li	a5,2
    80005adc:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005ae0:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005ae4:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005ae8:	f4c42783          	lw	a5,-180(s0)
    80005aec:	0017c713          	xori	a4,a5,1
    80005af0:	8b05                	andi	a4,a4,1
    80005af2:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005af6:	0037f713          	andi	a4,a5,3
    80005afa:	00e03733          	snez	a4,a4
    80005afe:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005b02:	4007f793          	andi	a5,a5,1024
    80005b06:	c791                	beqz	a5,80005b12 <sys_open+0xd2>
    80005b08:	04491703          	lh	a4,68(s2)
    80005b0c:	4789                	li	a5,2
    80005b0e:	08f70f63          	beq	a4,a5,80005bac <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005b12:	854a                	mv	a0,s2
    80005b14:	ffffe097          	auipc	ra,0xffffe
    80005b18:	082080e7          	jalr	130(ra) # 80003b96 <iunlock>
  end_op();
    80005b1c:	fffff097          	auipc	ra,0xfffff
    80005b20:	a0a080e7          	jalr	-1526(ra) # 80004526 <end_op>

  return fd;
}
    80005b24:	8526                	mv	a0,s1
    80005b26:	70ea                	ld	ra,184(sp)
    80005b28:	744a                	ld	s0,176(sp)
    80005b2a:	74aa                	ld	s1,168(sp)
    80005b2c:	790a                	ld	s2,160(sp)
    80005b2e:	69ea                	ld	s3,152(sp)
    80005b30:	6129                	addi	sp,sp,192
    80005b32:	8082                	ret
      end_op();
    80005b34:	fffff097          	auipc	ra,0xfffff
    80005b38:	9f2080e7          	jalr	-1550(ra) # 80004526 <end_op>
      return -1;
    80005b3c:	b7e5                	j	80005b24 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005b3e:	f5040513          	addi	a0,s0,-176
    80005b42:	ffffe097          	auipc	ra,0xffffe
    80005b46:	748080e7          	jalr	1864(ra) # 8000428a <namei>
    80005b4a:	892a                	mv	s2,a0
    80005b4c:	c905                	beqz	a0,80005b7c <sys_open+0x13c>
    ilock(ip);
    80005b4e:	ffffe097          	auipc	ra,0xffffe
    80005b52:	f86080e7          	jalr	-122(ra) # 80003ad4 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005b56:	04491703          	lh	a4,68(s2)
    80005b5a:	4785                	li	a5,1
    80005b5c:	f4f712e3          	bne	a4,a5,80005aa0 <sys_open+0x60>
    80005b60:	f4c42783          	lw	a5,-180(s0)
    80005b64:	dba1                	beqz	a5,80005ab4 <sys_open+0x74>
      iunlockput(ip);
    80005b66:	854a                	mv	a0,s2
    80005b68:	ffffe097          	auipc	ra,0xffffe
    80005b6c:	1ce080e7          	jalr	462(ra) # 80003d36 <iunlockput>
      end_op();
    80005b70:	fffff097          	auipc	ra,0xfffff
    80005b74:	9b6080e7          	jalr	-1610(ra) # 80004526 <end_op>
      return -1;
    80005b78:	54fd                	li	s1,-1
    80005b7a:	b76d                	j	80005b24 <sys_open+0xe4>
      end_op();
    80005b7c:	fffff097          	auipc	ra,0xfffff
    80005b80:	9aa080e7          	jalr	-1622(ra) # 80004526 <end_op>
      return -1;
    80005b84:	54fd                	li	s1,-1
    80005b86:	bf79                	j	80005b24 <sys_open+0xe4>
    iunlockput(ip);
    80005b88:	854a                	mv	a0,s2
    80005b8a:	ffffe097          	auipc	ra,0xffffe
    80005b8e:	1ac080e7          	jalr	428(ra) # 80003d36 <iunlockput>
    end_op();
    80005b92:	fffff097          	auipc	ra,0xfffff
    80005b96:	994080e7          	jalr	-1644(ra) # 80004526 <end_op>
    return -1;
    80005b9a:	54fd                	li	s1,-1
    80005b9c:	b761                	j	80005b24 <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005b9e:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005ba2:	04691783          	lh	a5,70(s2)
    80005ba6:	02f99223          	sh	a5,36(s3)
    80005baa:	bf2d                	j	80005ae4 <sys_open+0xa4>
    itrunc(ip);
    80005bac:	854a                	mv	a0,s2
    80005bae:	ffffe097          	auipc	ra,0xffffe
    80005bb2:	034080e7          	jalr	52(ra) # 80003be2 <itrunc>
    80005bb6:	bfb1                	j	80005b12 <sys_open+0xd2>
      fileclose(f);
    80005bb8:	854e                	mv	a0,s3
    80005bba:	fffff097          	auipc	ra,0xfffff
    80005bbe:	db8080e7          	jalr	-584(ra) # 80004972 <fileclose>
    iunlockput(ip);
    80005bc2:	854a                	mv	a0,s2
    80005bc4:	ffffe097          	auipc	ra,0xffffe
    80005bc8:	172080e7          	jalr	370(ra) # 80003d36 <iunlockput>
    end_op();
    80005bcc:	fffff097          	auipc	ra,0xfffff
    80005bd0:	95a080e7          	jalr	-1702(ra) # 80004526 <end_op>
    return -1;
    80005bd4:	54fd                	li	s1,-1
    80005bd6:	b7b9                	j	80005b24 <sys_open+0xe4>

0000000080005bd8 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005bd8:	7175                	addi	sp,sp,-144
    80005bda:	e506                	sd	ra,136(sp)
    80005bdc:	e122                	sd	s0,128(sp)
    80005bde:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005be0:	fffff097          	auipc	ra,0xfffff
    80005be4:	8c6080e7          	jalr	-1850(ra) # 800044a6 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005be8:	08000613          	li	a2,128
    80005bec:	f7040593          	addi	a1,s0,-144
    80005bf0:	4501                	li	a0,0
    80005bf2:	ffffd097          	auipc	ra,0xffffd
    80005bf6:	366080e7          	jalr	870(ra) # 80002f58 <argstr>
    80005bfa:	02054963          	bltz	a0,80005c2c <sys_mkdir+0x54>
    80005bfe:	4681                	li	a3,0
    80005c00:	4601                	li	a2,0
    80005c02:	4585                	li	a1,1
    80005c04:	f7040513          	addi	a0,s0,-144
    80005c08:	fffff097          	auipc	ra,0xfffff
    80005c0c:	7fe080e7          	jalr	2046(ra) # 80005406 <create>
    80005c10:	cd11                	beqz	a0,80005c2c <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005c12:	ffffe097          	auipc	ra,0xffffe
    80005c16:	124080e7          	jalr	292(ra) # 80003d36 <iunlockput>
  end_op();
    80005c1a:	fffff097          	auipc	ra,0xfffff
    80005c1e:	90c080e7          	jalr	-1780(ra) # 80004526 <end_op>
  return 0;
    80005c22:	4501                	li	a0,0
}
    80005c24:	60aa                	ld	ra,136(sp)
    80005c26:	640a                	ld	s0,128(sp)
    80005c28:	6149                	addi	sp,sp,144
    80005c2a:	8082                	ret
    end_op();
    80005c2c:	fffff097          	auipc	ra,0xfffff
    80005c30:	8fa080e7          	jalr	-1798(ra) # 80004526 <end_op>
    return -1;
    80005c34:	557d                	li	a0,-1
    80005c36:	b7fd                	j	80005c24 <sys_mkdir+0x4c>

0000000080005c38 <sys_mknod>:

uint64
sys_mknod(void)
{
    80005c38:	7135                	addi	sp,sp,-160
    80005c3a:	ed06                	sd	ra,152(sp)
    80005c3c:	e922                	sd	s0,144(sp)
    80005c3e:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005c40:	fffff097          	auipc	ra,0xfffff
    80005c44:	866080e7          	jalr	-1946(ra) # 800044a6 <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005c48:	08000613          	li	a2,128
    80005c4c:	f7040593          	addi	a1,s0,-144
    80005c50:	4501                	li	a0,0
    80005c52:	ffffd097          	auipc	ra,0xffffd
    80005c56:	306080e7          	jalr	774(ra) # 80002f58 <argstr>
    80005c5a:	04054a63          	bltz	a0,80005cae <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    80005c5e:	f6c40593          	addi	a1,s0,-148
    80005c62:	4505                	li	a0,1
    80005c64:	ffffd097          	auipc	ra,0xffffd
    80005c68:	2b0080e7          	jalr	688(ra) # 80002f14 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005c6c:	04054163          	bltz	a0,80005cae <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    80005c70:	f6840593          	addi	a1,s0,-152
    80005c74:	4509                	li	a0,2
    80005c76:	ffffd097          	auipc	ra,0xffffd
    80005c7a:	29e080e7          	jalr	670(ra) # 80002f14 <argint>
     argint(1, &major) < 0 ||
    80005c7e:	02054863          	bltz	a0,80005cae <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005c82:	f6841683          	lh	a3,-152(s0)
    80005c86:	f6c41603          	lh	a2,-148(s0)
    80005c8a:	458d                	li	a1,3
    80005c8c:	f7040513          	addi	a0,s0,-144
    80005c90:	fffff097          	auipc	ra,0xfffff
    80005c94:	776080e7          	jalr	1910(ra) # 80005406 <create>
     argint(2, &minor) < 0 ||
    80005c98:	c919                	beqz	a0,80005cae <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005c9a:	ffffe097          	auipc	ra,0xffffe
    80005c9e:	09c080e7          	jalr	156(ra) # 80003d36 <iunlockput>
  end_op();
    80005ca2:	fffff097          	auipc	ra,0xfffff
    80005ca6:	884080e7          	jalr	-1916(ra) # 80004526 <end_op>
  return 0;
    80005caa:	4501                	li	a0,0
    80005cac:	a031                	j	80005cb8 <sys_mknod+0x80>
    end_op();
    80005cae:	fffff097          	auipc	ra,0xfffff
    80005cb2:	878080e7          	jalr	-1928(ra) # 80004526 <end_op>
    return -1;
    80005cb6:	557d                	li	a0,-1
}
    80005cb8:	60ea                	ld	ra,152(sp)
    80005cba:	644a                	ld	s0,144(sp)
    80005cbc:	610d                	addi	sp,sp,160
    80005cbe:	8082                	ret

0000000080005cc0 <sys_chdir>:

uint64
sys_chdir(void)
{
    80005cc0:	7135                	addi	sp,sp,-160
    80005cc2:	ed06                	sd	ra,152(sp)
    80005cc4:	e922                	sd	s0,144(sp)
    80005cc6:	e526                	sd	s1,136(sp)
    80005cc8:	e14a                	sd	s2,128(sp)
    80005cca:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005ccc:	ffffc097          	auipc	ra,0xffffc
    80005cd0:	cfc080e7          	jalr	-772(ra) # 800019c8 <myproc>
    80005cd4:	892a                	mv	s2,a0
  
  begin_op();
    80005cd6:	ffffe097          	auipc	ra,0xffffe
    80005cda:	7d0080e7          	jalr	2000(ra) # 800044a6 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005cde:	08000613          	li	a2,128
    80005ce2:	f6040593          	addi	a1,s0,-160
    80005ce6:	4501                	li	a0,0
    80005ce8:	ffffd097          	auipc	ra,0xffffd
    80005cec:	270080e7          	jalr	624(ra) # 80002f58 <argstr>
    80005cf0:	04054b63          	bltz	a0,80005d46 <sys_chdir+0x86>
    80005cf4:	f6040513          	addi	a0,s0,-160
    80005cf8:	ffffe097          	auipc	ra,0xffffe
    80005cfc:	592080e7          	jalr	1426(ra) # 8000428a <namei>
    80005d00:	84aa                	mv	s1,a0
    80005d02:	c131                	beqz	a0,80005d46 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005d04:	ffffe097          	auipc	ra,0xffffe
    80005d08:	dd0080e7          	jalr	-560(ra) # 80003ad4 <ilock>
  if(ip->type != T_DIR){
    80005d0c:	04449703          	lh	a4,68(s1)
    80005d10:	4785                	li	a5,1
    80005d12:	04f71063          	bne	a4,a5,80005d52 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005d16:	8526                	mv	a0,s1
    80005d18:	ffffe097          	auipc	ra,0xffffe
    80005d1c:	e7e080e7          	jalr	-386(ra) # 80003b96 <iunlock>
  iput(p->cwd);
    80005d20:	17093503          	ld	a0,368(s2)
    80005d24:	ffffe097          	auipc	ra,0xffffe
    80005d28:	f6a080e7          	jalr	-150(ra) # 80003c8e <iput>
  end_op();
    80005d2c:	ffffe097          	auipc	ra,0xffffe
    80005d30:	7fa080e7          	jalr	2042(ra) # 80004526 <end_op>
  p->cwd = ip;
    80005d34:	16993823          	sd	s1,368(s2)
  return 0;
    80005d38:	4501                	li	a0,0
}
    80005d3a:	60ea                	ld	ra,152(sp)
    80005d3c:	644a                	ld	s0,144(sp)
    80005d3e:	64aa                	ld	s1,136(sp)
    80005d40:	690a                	ld	s2,128(sp)
    80005d42:	610d                	addi	sp,sp,160
    80005d44:	8082                	ret
    end_op();
    80005d46:	ffffe097          	auipc	ra,0xffffe
    80005d4a:	7e0080e7          	jalr	2016(ra) # 80004526 <end_op>
    return -1;
    80005d4e:	557d                	li	a0,-1
    80005d50:	b7ed                	j	80005d3a <sys_chdir+0x7a>
    iunlockput(ip);
    80005d52:	8526                	mv	a0,s1
    80005d54:	ffffe097          	auipc	ra,0xffffe
    80005d58:	fe2080e7          	jalr	-30(ra) # 80003d36 <iunlockput>
    end_op();
    80005d5c:	ffffe097          	auipc	ra,0xffffe
    80005d60:	7ca080e7          	jalr	1994(ra) # 80004526 <end_op>
    return -1;
    80005d64:	557d                	li	a0,-1
    80005d66:	bfd1                	j	80005d3a <sys_chdir+0x7a>

0000000080005d68 <sys_exec>:

uint64
sys_exec(void)
{
    80005d68:	7145                	addi	sp,sp,-464
    80005d6a:	e786                	sd	ra,456(sp)
    80005d6c:	e3a2                	sd	s0,448(sp)
    80005d6e:	ff26                	sd	s1,440(sp)
    80005d70:	fb4a                	sd	s2,432(sp)
    80005d72:	f74e                	sd	s3,424(sp)
    80005d74:	f352                	sd	s4,416(sp)
    80005d76:	ef56                	sd	s5,408(sp)
    80005d78:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005d7a:	08000613          	li	a2,128
    80005d7e:	f4040593          	addi	a1,s0,-192
    80005d82:	4501                	li	a0,0
    80005d84:	ffffd097          	auipc	ra,0xffffd
    80005d88:	1d4080e7          	jalr	468(ra) # 80002f58 <argstr>
    return -1;
    80005d8c:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005d8e:	0c054a63          	bltz	a0,80005e62 <sys_exec+0xfa>
    80005d92:	e3840593          	addi	a1,s0,-456
    80005d96:	4505                	li	a0,1
    80005d98:	ffffd097          	auipc	ra,0xffffd
    80005d9c:	19e080e7          	jalr	414(ra) # 80002f36 <argaddr>
    80005da0:	0c054163          	bltz	a0,80005e62 <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80005da4:	10000613          	li	a2,256
    80005da8:	4581                	li	a1,0
    80005daa:	e4040513          	addi	a0,s0,-448
    80005dae:	ffffb097          	auipc	ra,0xffffb
    80005db2:	f32080e7          	jalr	-206(ra) # 80000ce0 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005db6:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005dba:	89a6                	mv	s3,s1
    80005dbc:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005dbe:	02000a13          	li	s4,32
    80005dc2:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005dc6:	00391513          	slli	a0,s2,0x3
    80005dca:	e3040593          	addi	a1,s0,-464
    80005dce:	e3843783          	ld	a5,-456(s0)
    80005dd2:	953e                	add	a0,a0,a5
    80005dd4:	ffffd097          	auipc	ra,0xffffd
    80005dd8:	0a6080e7          	jalr	166(ra) # 80002e7a <fetchaddr>
    80005ddc:	02054a63          	bltz	a0,80005e10 <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    80005de0:	e3043783          	ld	a5,-464(s0)
    80005de4:	c3b9                	beqz	a5,80005e2a <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005de6:	ffffb097          	auipc	ra,0xffffb
    80005dea:	d0e080e7          	jalr	-754(ra) # 80000af4 <kalloc>
    80005dee:	85aa                	mv	a1,a0
    80005df0:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005df4:	cd11                	beqz	a0,80005e10 <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005df6:	6605                	lui	a2,0x1
    80005df8:	e3043503          	ld	a0,-464(s0)
    80005dfc:	ffffd097          	auipc	ra,0xffffd
    80005e00:	0d0080e7          	jalr	208(ra) # 80002ecc <fetchstr>
    80005e04:	00054663          	bltz	a0,80005e10 <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80005e08:	0905                	addi	s2,s2,1
    80005e0a:	09a1                	addi	s3,s3,8
    80005e0c:	fb491be3          	bne	s2,s4,80005dc2 <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005e10:	10048913          	addi	s2,s1,256
    80005e14:	6088                	ld	a0,0(s1)
    80005e16:	c529                	beqz	a0,80005e60 <sys_exec+0xf8>
    kfree(argv[i]);
    80005e18:	ffffb097          	auipc	ra,0xffffb
    80005e1c:	be0080e7          	jalr	-1056(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005e20:	04a1                	addi	s1,s1,8
    80005e22:	ff2499e3          	bne	s1,s2,80005e14 <sys_exec+0xac>
  return -1;
    80005e26:	597d                	li	s2,-1
    80005e28:	a82d                	j	80005e62 <sys_exec+0xfa>
      argv[i] = 0;
    80005e2a:	0a8e                	slli	s5,s5,0x3
    80005e2c:	fc040793          	addi	a5,s0,-64
    80005e30:	9abe                	add	s5,s5,a5
    80005e32:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005e36:	e4040593          	addi	a1,s0,-448
    80005e3a:	f4040513          	addi	a0,s0,-192
    80005e3e:	fffff097          	auipc	ra,0xfffff
    80005e42:	194080e7          	jalr	404(ra) # 80004fd2 <exec>
    80005e46:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005e48:	10048993          	addi	s3,s1,256
    80005e4c:	6088                	ld	a0,0(s1)
    80005e4e:	c911                	beqz	a0,80005e62 <sys_exec+0xfa>
    kfree(argv[i]);
    80005e50:	ffffb097          	auipc	ra,0xffffb
    80005e54:	ba8080e7          	jalr	-1112(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005e58:	04a1                	addi	s1,s1,8
    80005e5a:	ff3499e3          	bne	s1,s3,80005e4c <sys_exec+0xe4>
    80005e5e:	a011                	j	80005e62 <sys_exec+0xfa>
  return -1;
    80005e60:	597d                	li	s2,-1
}
    80005e62:	854a                	mv	a0,s2
    80005e64:	60be                	ld	ra,456(sp)
    80005e66:	641e                	ld	s0,448(sp)
    80005e68:	74fa                	ld	s1,440(sp)
    80005e6a:	795a                	ld	s2,432(sp)
    80005e6c:	79ba                	ld	s3,424(sp)
    80005e6e:	7a1a                	ld	s4,416(sp)
    80005e70:	6afa                	ld	s5,408(sp)
    80005e72:	6179                	addi	sp,sp,464
    80005e74:	8082                	ret

0000000080005e76 <sys_pipe>:

uint64
sys_pipe(void)
{
    80005e76:	7139                	addi	sp,sp,-64
    80005e78:	fc06                	sd	ra,56(sp)
    80005e7a:	f822                	sd	s0,48(sp)
    80005e7c:	f426                	sd	s1,40(sp)
    80005e7e:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005e80:	ffffc097          	auipc	ra,0xffffc
    80005e84:	b48080e7          	jalr	-1208(ra) # 800019c8 <myproc>
    80005e88:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80005e8a:	fd840593          	addi	a1,s0,-40
    80005e8e:	4501                	li	a0,0
    80005e90:	ffffd097          	auipc	ra,0xffffd
    80005e94:	0a6080e7          	jalr	166(ra) # 80002f36 <argaddr>
    return -1;
    80005e98:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80005e9a:	0e054063          	bltz	a0,80005f7a <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    80005e9e:	fc840593          	addi	a1,s0,-56
    80005ea2:	fd040513          	addi	a0,s0,-48
    80005ea6:	fffff097          	auipc	ra,0xfffff
    80005eaa:	dfc080e7          	jalr	-516(ra) # 80004ca2 <pipealloc>
    return -1;
    80005eae:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005eb0:	0c054563          	bltz	a0,80005f7a <sys_pipe+0x104>
  fd0 = -1;
    80005eb4:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005eb8:	fd043503          	ld	a0,-48(s0)
    80005ebc:	fffff097          	auipc	ra,0xfffff
    80005ec0:	508080e7          	jalr	1288(ra) # 800053c4 <fdalloc>
    80005ec4:	fca42223          	sw	a0,-60(s0)
    80005ec8:	08054c63          	bltz	a0,80005f60 <sys_pipe+0xea>
    80005ecc:	fc843503          	ld	a0,-56(s0)
    80005ed0:	fffff097          	auipc	ra,0xfffff
    80005ed4:	4f4080e7          	jalr	1268(ra) # 800053c4 <fdalloc>
    80005ed8:	fca42023          	sw	a0,-64(s0)
    80005edc:	06054863          	bltz	a0,80005f4c <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005ee0:	4691                	li	a3,4
    80005ee2:	fc440613          	addi	a2,s0,-60
    80005ee6:	fd843583          	ld	a1,-40(s0)
    80005eea:	78a8                	ld	a0,112(s1)
    80005eec:	ffffb097          	auipc	ra,0xffffb
    80005ef0:	78e080e7          	jalr	1934(ra) # 8000167a <copyout>
    80005ef4:	02054063          	bltz	a0,80005f14 <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005ef8:	4691                	li	a3,4
    80005efa:	fc040613          	addi	a2,s0,-64
    80005efe:	fd843583          	ld	a1,-40(s0)
    80005f02:	0591                	addi	a1,a1,4
    80005f04:	78a8                	ld	a0,112(s1)
    80005f06:	ffffb097          	auipc	ra,0xffffb
    80005f0a:	774080e7          	jalr	1908(ra) # 8000167a <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005f0e:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005f10:	06055563          	bgez	a0,80005f7a <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80005f14:	fc442783          	lw	a5,-60(s0)
    80005f18:	07f9                	addi	a5,a5,30
    80005f1a:	078e                	slli	a5,a5,0x3
    80005f1c:	97a6                	add	a5,a5,s1
    80005f1e:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005f22:	fc042503          	lw	a0,-64(s0)
    80005f26:	0579                	addi	a0,a0,30
    80005f28:	050e                	slli	a0,a0,0x3
    80005f2a:	9526                	add	a0,a0,s1
    80005f2c:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005f30:	fd043503          	ld	a0,-48(s0)
    80005f34:	fffff097          	auipc	ra,0xfffff
    80005f38:	a3e080e7          	jalr	-1474(ra) # 80004972 <fileclose>
    fileclose(wf);
    80005f3c:	fc843503          	ld	a0,-56(s0)
    80005f40:	fffff097          	auipc	ra,0xfffff
    80005f44:	a32080e7          	jalr	-1486(ra) # 80004972 <fileclose>
    return -1;
    80005f48:	57fd                	li	a5,-1
    80005f4a:	a805                	j	80005f7a <sys_pipe+0x104>
    if(fd0 >= 0)
    80005f4c:	fc442783          	lw	a5,-60(s0)
    80005f50:	0007c863          	bltz	a5,80005f60 <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80005f54:	01e78513          	addi	a0,a5,30
    80005f58:	050e                	slli	a0,a0,0x3
    80005f5a:	9526                	add	a0,a0,s1
    80005f5c:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005f60:	fd043503          	ld	a0,-48(s0)
    80005f64:	fffff097          	auipc	ra,0xfffff
    80005f68:	a0e080e7          	jalr	-1522(ra) # 80004972 <fileclose>
    fileclose(wf);
    80005f6c:	fc843503          	ld	a0,-56(s0)
    80005f70:	fffff097          	auipc	ra,0xfffff
    80005f74:	a02080e7          	jalr	-1534(ra) # 80004972 <fileclose>
    return -1;
    80005f78:	57fd                	li	a5,-1
}
    80005f7a:	853e                	mv	a0,a5
    80005f7c:	70e2                	ld	ra,56(sp)
    80005f7e:	7442                	ld	s0,48(sp)
    80005f80:	74a2                	ld	s1,40(sp)
    80005f82:	6121                	addi	sp,sp,64
    80005f84:	8082                	ret
	...

0000000080005f90 <kernelvec>:
    80005f90:	7111                	addi	sp,sp,-256
    80005f92:	e006                	sd	ra,0(sp)
    80005f94:	e40a                	sd	sp,8(sp)
    80005f96:	e80e                	sd	gp,16(sp)
    80005f98:	ec12                	sd	tp,24(sp)
    80005f9a:	f016                	sd	t0,32(sp)
    80005f9c:	f41a                	sd	t1,40(sp)
    80005f9e:	f81e                	sd	t2,48(sp)
    80005fa0:	fc22                	sd	s0,56(sp)
    80005fa2:	e0a6                	sd	s1,64(sp)
    80005fa4:	e4aa                	sd	a0,72(sp)
    80005fa6:	e8ae                	sd	a1,80(sp)
    80005fa8:	ecb2                	sd	a2,88(sp)
    80005faa:	f0b6                	sd	a3,96(sp)
    80005fac:	f4ba                	sd	a4,104(sp)
    80005fae:	f8be                	sd	a5,112(sp)
    80005fb0:	fcc2                	sd	a6,120(sp)
    80005fb2:	e146                	sd	a7,128(sp)
    80005fb4:	e54a                	sd	s2,136(sp)
    80005fb6:	e94e                	sd	s3,144(sp)
    80005fb8:	ed52                	sd	s4,152(sp)
    80005fba:	f156                	sd	s5,160(sp)
    80005fbc:	f55a                	sd	s6,168(sp)
    80005fbe:	f95e                	sd	s7,176(sp)
    80005fc0:	fd62                	sd	s8,184(sp)
    80005fc2:	e1e6                	sd	s9,192(sp)
    80005fc4:	e5ea                	sd	s10,200(sp)
    80005fc6:	e9ee                	sd	s11,208(sp)
    80005fc8:	edf2                	sd	t3,216(sp)
    80005fca:	f1f6                	sd	t4,224(sp)
    80005fcc:	f5fa                	sd	t5,232(sp)
    80005fce:	f9fe                	sd	t6,240(sp)
    80005fd0:	d77fc0ef          	jal	ra,80002d46 <kerneltrap>
    80005fd4:	6082                	ld	ra,0(sp)
    80005fd6:	6122                	ld	sp,8(sp)
    80005fd8:	61c2                	ld	gp,16(sp)
    80005fda:	7282                	ld	t0,32(sp)
    80005fdc:	7322                	ld	t1,40(sp)
    80005fde:	73c2                	ld	t2,48(sp)
    80005fe0:	7462                	ld	s0,56(sp)
    80005fe2:	6486                	ld	s1,64(sp)
    80005fe4:	6526                	ld	a0,72(sp)
    80005fe6:	65c6                	ld	a1,80(sp)
    80005fe8:	6666                	ld	a2,88(sp)
    80005fea:	7686                	ld	a3,96(sp)
    80005fec:	7726                	ld	a4,104(sp)
    80005fee:	77c6                	ld	a5,112(sp)
    80005ff0:	7866                	ld	a6,120(sp)
    80005ff2:	688a                	ld	a7,128(sp)
    80005ff4:	692a                	ld	s2,136(sp)
    80005ff6:	69ca                	ld	s3,144(sp)
    80005ff8:	6a6a                	ld	s4,152(sp)
    80005ffa:	7a8a                	ld	s5,160(sp)
    80005ffc:	7b2a                	ld	s6,168(sp)
    80005ffe:	7bca                	ld	s7,176(sp)
    80006000:	7c6a                	ld	s8,184(sp)
    80006002:	6c8e                	ld	s9,192(sp)
    80006004:	6d2e                	ld	s10,200(sp)
    80006006:	6dce                	ld	s11,208(sp)
    80006008:	6e6e                	ld	t3,216(sp)
    8000600a:	7e8e                	ld	t4,224(sp)
    8000600c:	7f2e                	ld	t5,232(sp)
    8000600e:	7fce                	ld	t6,240(sp)
    80006010:	6111                	addi	sp,sp,256
    80006012:	10200073          	sret
    80006016:	00000013          	nop
    8000601a:	00000013          	nop
    8000601e:	0001                	nop

0000000080006020 <timervec>:
    80006020:	34051573          	csrrw	a0,mscratch,a0
    80006024:	e10c                	sd	a1,0(a0)
    80006026:	e510                	sd	a2,8(a0)
    80006028:	e914                	sd	a3,16(a0)
    8000602a:	6d0c                	ld	a1,24(a0)
    8000602c:	7110                	ld	a2,32(a0)
    8000602e:	6194                	ld	a3,0(a1)
    80006030:	96b2                	add	a3,a3,a2
    80006032:	e194                	sd	a3,0(a1)
    80006034:	4589                	li	a1,2
    80006036:	14459073          	csrw	sip,a1
    8000603a:	6914                	ld	a3,16(a0)
    8000603c:	6510                	ld	a2,8(a0)
    8000603e:	610c                	ld	a1,0(a0)
    80006040:	34051573          	csrrw	a0,mscratch,a0
    80006044:	30200073          	mret
	...

000000008000604a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    8000604a:	1141                	addi	sp,sp,-16
    8000604c:	e422                	sd	s0,8(sp)
    8000604e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80006050:	0c0007b7          	lui	a5,0xc000
    80006054:	4705                	li	a4,1
    80006056:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80006058:	c3d8                	sw	a4,4(a5)
}
    8000605a:	6422                	ld	s0,8(sp)
    8000605c:	0141                	addi	sp,sp,16
    8000605e:	8082                	ret

0000000080006060 <plicinithart>:

void
plicinithart(void)
{
    80006060:	1141                	addi	sp,sp,-16
    80006062:	e406                	sd	ra,8(sp)
    80006064:	e022                	sd	s0,0(sp)
    80006066:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006068:	ffffc097          	auipc	ra,0xffffc
    8000606c:	934080e7          	jalr	-1740(ra) # 8000199c <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80006070:	0085171b          	slliw	a4,a0,0x8
    80006074:	0c0027b7          	lui	a5,0xc002
    80006078:	97ba                	add	a5,a5,a4
    8000607a:	40200713          	li	a4,1026
    8000607e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80006082:	00d5151b          	slliw	a0,a0,0xd
    80006086:	0c2017b7          	lui	a5,0xc201
    8000608a:	953e                	add	a0,a0,a5
    8000608c:	00052023          	sw	zero,0(a0)
}
    80006090:	60a2                	ld	ra,8(sp)
    80006092:	6402                	ld	s0,0(sp)
    80006094:	0141                	addi	sp,sp,16
    80006096:	8082                	ret

0000000080006098 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80006098:	1141                	addi	sp,sp,-16
    8000609a:	e406                	sd	ra,8(sp)
    8000609c:	e022                	sd	s0,0(sp)
    8000609e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    800060a0:	ffffc097          	auipc	ra,0xffffc
    800060a4:	8fc080e7          	jalr	-1796(ra) # 8000199c <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    800060a8:	00d5179b          	slliw	a5,a0,0xd
    800060ac:	0c201537          	lui	a0,0xc201
    800060b0:	953e                	add	a0,a0,a5
  return irq;
}
    800060b2:	4148                	lw	a0,4(a0)
    800060b4:	60a2                	ld	ra,8(sp)
    800060b6:	6402                	ld	s0,0(sp)
    800060b8:	0141                	addi	sp,sp,16
    800060ba:	8082                	ret

00000000800060bc <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    800060bc:	1101                	addi	sp,sp,-32
    800060be:	ec06                	sd	ra,24(sp)
    800060c0:	e822                	sd	s0,16(sp)
    800060c2:	e426                	sd	s1,8(sp)
    800060c4:	1000                	addi	s0,sp,32
    800060c6:	84aa                	mv	s1,a0
  int hart = cpuid();
    800060c8:	ffffc097          	auipc	ra,0xffffc
    800060cc:	8d4080e7          	jalr	-1836(ra) # 8000199c <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    800060d0:	00d5151b          	slliw	a0,a0,0xd
    800060d4:	0c2017b7          	lui	a5,0xc201
    800060d8:	97aa                	add	a5,a5,a0
    800060da:	c3c4                	sw	s1,4(a5)
}
    800060dc:	60e2                	ld	ra,24(sp)
    800060de:	6442                	ld	s0,16(sp)
    800060e0:	64a2                	ld	s1,8(sp)
    800060e2:	6105                	addi	sp,sp,32
    800060e4:	8082                	ret

00000000800060e6 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    800060e6:	1141                	addi	sp,sp,-16
    800060e8:	e406                	sd	ra,8(sp)
    800060ea:	e022                	sd	s0,0(sp)
    800060ec:	0800                	addi	s0,sp,16
  if(i >= NUM)
    800060ee:	479d                	li	a5,7
    800060f0:	06a7c963          	blt	a5,a0,80006162 <free_desc+0x7c>
    panic("free_desc 1");
  if(disk.free[i])
    800060f4:	0001d797          	auipc	a5,0x1d
    800060f8:	f0c78793          	addi	a5,a5,-244 # 80023000 <disk>
    800060fc:	00a78733          	add	a4,a5,a0
    80006100:	6789                	lui	a5,0x2
    80006102:	97ba                	add	a5,a5,a4
    80006104:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80006108:	e7ad                	bnez	a5,80006172 <free_desc+0x8c>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    8000610a:	00451793          	slli	a5,a0,0x4
    8000610e:	0001f717          	auipc	a4,0x1f
    80006112:	ef270713          	addi	a4,a4,-270 # 80025000 <disk+0x2000>
    80006116:	6314                	ld	a3,0(a4)
    80006118:	96be                	add	a3,a3,a5
    8000611a:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    8000611e:	6314                	ld	a3,0(a4)
    80006120:	96be                	add	a3,a3,a5
    80006122:	0006a423          	sw	zero,8(a3)
  disk.desc[i].flags = 0;
    80006126:	6314                	ld	a3,0(a4)
    80006128:	96be                	add	a3,a3,a5
    8000612a:	00069623          	sh	zero,12(a3)
  disk.desc[i].next = 0;
    8000612e:	6318                	ld	a4,0(a4)
    80006130:	97ba                	add	a5,a5,a4
    80006132:	00079723          	sh	zero,14(a5)
  disk.free[i] = 1;
    80006136:	0001d797          	auipc	a5,0x1d
    8000613a:	eca78793          	addi	a5,a5,-310 # 80023000 <disk>
    8000613e:	97aa                	add	a5,a5,a0
    80006140:	6509                	lui	a0,0x2
    80006142:	953e                	add	a0,a0,a5
    80006144:	4785                	li	a5,1
    80006146:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    8000614a:	0001f517          	auipc	a0,0x1f
    8000614e:	ece50513          	addi	a0,a0,-306 # 80025018 <disk+0x2018>
    80006152:	ffffc097          	auipc	ra,0xffffc
    80006156:	3f0080e7          	jalr	1008(ra) # 80002542 <wakeup>
}
    8000615a:	60a2                	ld	ra,8(sp)
    8000615c:	6402                	ld	s0,0(sp)
    8000615e:	0141                	addi	sp,sp,16
    80006160:	8082                	ret
    panic("free_desc 1");
    80006162:	00002517          	auipc	a0,0x2
    80006166:	6e650513          	addi	a0,a0,1766 # 80008848 <syscalls+0x330>
    8000616a:	ffffa097          	auipc	ra,0xffffa
    8000616e:	3d4080e7          	jalr	980(ra) # 8000053e <panic>
    panic("free_desc 2");
    80006172:	00002517          	auipc	a0,0x2
    80006176:	6e650513          	addi	a0,a0,1766 # 80008858 <syscalls+0x340>
    8000617a:	ffffa097          	auipc	ra,0xffffa
    8000617e:	3c4080e7          	jalr	964(ra) # 8000053e <panic>

0000000080006182 <virtio_disk_init>:
{
    80006182:	1101                	addi	sp,sp,-32
    80006184:	ec06                	sd	ra,24(sp)
    80006186:	e822                	sd	s0,16(sp)
    80006188:	e426                	sd	s1,8(sp)
    8000618a:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    8000618c:	00002597          	auipc	a1,0x2
    80006190:	6dc58593          	addi	a1,a1,1756 # 80008868 <syscalls+0x350>
    80006194:	0001f517          	auipc	a0,0x1f
    80006198:	f9450513          	addi	a0,a0,-108 # 80025128 <disk+0x2128>
    8000619c:	ffffb097          	auipc	ra,0xffffb
    800061a0:	9b8080e7          	jalr	-1608(ra) # 80000b54 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    800061a4:	100017b7          	lui	a5,0x10001
    800061a8:	4398                	lw	a4,0(a5)
    800061aa:	2701                	sext.w	a4,a4
    800061ac:	747277b7          	lui	a5,0x74727
    800061b0:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    800061b4:	0ef71163          	bne	a4,a5,80006296 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    800061b8:	100017b7          	lui	a5,0x10001
    800061bc:	43dc                	lw	a5,4(a5)
    800061be:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    800061c0:	4705                	li	a4,1
    800061c2:	0ce79a63          	bne	a5,a4,80006296 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    800061c6:	100017b7          	lui	a5,0x10001
    800061ca:	479c                	lw	a5,8(a5)
    800061cc:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    800061ce:	4709                	li	a4,2
    800061d0:	0ce79363          	bne	a5,a4,80006296 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    800061d4:	100017b7          	lui	a5,0x10001
    800061d8:	47d8                	lw	a4,12(a5)
    800061da:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    800061dc:	554d47b7          	lui	a5,0x554d4
    800061e0:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    800061e4:	0af71963          	bne	a4,a5,80006296 <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    800061e8:	100017b7          	lui	a5,0x10001
    800061ec:	4705                	li	a4,1
    800061ee:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800061f0:	470d                	li	a4,3
    800061f2:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    800061f4:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    800061f6:	c7ffe737          	lui	a4,0xc7ffe
    800061fa:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd875f>
    800061fe:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80006200:	2701                	sext.w	a4,a4
    80006202:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006204:	472d                	li	a4,11
    80006206:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006208:	473d                	li	a4,15
    8000620a:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    8000620c:	6705                	lui	a4,0x1
    8000620e:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80006210:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80006214:	5bdc                	lw	a5,52(a5)
    80006216:	2781                	sext.w	a5,a5
  if(max == 0)
    80006218:	c7d9                	beqz	a5,800062a6 <virtio_disk_init+0x124>
  if(max < NUM)
    8000621a:	471d                	li	a4,7
    8000621c:	08f77d63          	bgeu	a4,a5,800062b6 <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80006220:	100014b7          	lui	s1,0x10001
    80006224:	47a1                	li	a5,8
    80006226:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    80006228:	6609                	lui	a2,0x2
    8000622a:	4581                	li	a1,0
    8000622c:	0001d517          	auipc	a0,0x1d
    80006230:	dd450513          	addi	a0,a0,-556 # 80023000 <disk>
    80006234:	ffffb097          	auipc	ra,0xffffb
    80006238:	aac080e7          	jalr	-1364(ra) # 80000ce0 <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    8000623c:	0001d717          	auipc	a4,0x1d
    80006240:	dc470713          	addi	a4,a4,-572 # 80023000 <disk>
    80006244:	00c75793          	srli	a5,a4,0xc
    80006248:	2781                	sext.w	a5,a5
    8000624a:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    8000624c:	0001f797          	auipc	a5,0x1f
    80006250:	db478793          	addi	a5,a5,-588 # 80025000 <disk+0x2000>
    80006254:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    80006256:	0001d717          	auipc	a4,0x1d
    8000625a:	e2a70713          	addi	a4,a4,-470 # 80023080 <disk+0x80>
    8000625e:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    80006260:	0001e717          	auipc	a4,0x1e
    80006264:	da070713          	addi	a4,a4,-608 # 80024000 <disk+0x1000>
    80006268:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    8000626a:	4705                	li	a4,1
    8000626c:	00e78c23          	sb	a4,24(a5)
    80006270:	00e78ca3          	sb	a4,25(a5)
    80006274:	00e78d23          	sb	a4,26(a5)
    80006278:	00e78da3          	sb	a4,27(a5)
    8000627c:	00e78e23          	sb	a4,28(a5)
    80006280:	00e78ea3          	sb	a4,29(a5)
    80006284:	00e78f23          	sb	a4,30(a5)
    80006288:	00e78fa3          	sb	a4,31(a5)
}
    8000628c:	60e2                	ld	ra,24(sp)
    8000628e:	6442                	ld	s0,16(sp)
    80006290:	64a2                	ld	s1,8(sp)
    80006292:	6105                	addi	sp,sp,32
    80006294:	8082                	ret
    panic("could not find virtio disk");
    80006296:	00002517          	auipc	a0,0x2
    8000629a:	5e250513          	addi	a0,a0,1506 # 80008878 <syscalls+0x360>
    8000629e:	ffffa097          	auipc	ra,0xffffa
    800062a2:	2a0080e7          	jalr	672(ra) # 8000053e <panic>
    panic("virtio disk has no queue 0");
    800062a6:	00002517          	auipc	a0,0x2
    800062aa:	5f250513          	addi	a0,a0,1522 # 80008898 <syscalls+0x380>
    800062ae:	ffffa097          	auipc	ra,0xffffa
    800062b2:	290080e7          	jalr	656(ra) # 8000053e <panic>
    panic("virtio disk max queue too short");
    800062b6:	00002517          	auipc	a0,0x2
    800062ba:	60250513          	addi	a0,a0,1538 # 800088b8 <syscalls+0x3a0>
    800062be:	ffffa097          	auipc	ra,0xffffa
    800062c2:	280080e7          	jalr	640(ra) # 8000053e <panic>

00000000800062c6 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    800062c6:	7159                	addi	sp,sp,-112
    800062c8:	f486                	sd	ra,104(sp)
    800062ca:	f0a2                	sd	s0,96(sp)
    800062cc:	eca6                	sd	s1,88(sp)
    800062ce:	e8ca                	sd	s2,80(sp)
    800062d0:	e4ce                	sd	s3,72(sp)
    800062d2:	e0d2                	sd	s4,64(sp)
    800062d4:	fc56                	sd	s5,56(sp)
    800062d6:	f85a                	sd	s6,48(sp)
    800062d8:	f45e                	sd	s7,40(sp)
    800062da:	f062                	sd	s8,32(sp)
    800062dc:	ec66                	sd	s9,24(sp)
    800062de:	e86a                	sd	s10,16(sp)
    800062e0:	1880                	addi	s0,sp,112
    800062e2:	892a                	mv	s2,a0
    800062e4:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    800062e6:	00c52c83          	lw	s9,12(a0)
    800062ea:	001c9c9b          	slliw	s9,s9,0x1
    800062ee:	1c82                	slli	s9,s9,0x20
    800062f0:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    800062f4:	0001f517          	auipc	a0,0x1f
    800062f8:	e3450513          	addi	a0,a0,-460 # 80025128 <disk+0x2128>
    800062fc:	ffffb097          	auipc	ra,0xffffb
    80006300:	8e8080e7          	jalr	-1816(ra) # 80000be4 <acquire>
  for(int i = 0; i < 3; i++){
    80006304:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80006306:	4c21                	li	s8,8
      disk.free[i] = 0;
    80006308:	0001db97          	auipc	s7,0x1d
    8000630c:	cf8b8b93          	addi	s7,s7,-776 # 80023000 <disk>
    80006310:	6b09                	lui	s6,0x2
  for(int i = 0; i < 3; i++){
    80006312:	4a8d                	li	s5,3
  for(int i = 0; i < NUM; i++){
    80006314:	8a4e                	mv	s4,s3
    80006316:	a051                	j	8000639a <virtio_disk_rw+0xd4>
      disk.free[i] = 0;
    80006318:	00fb86b3          	add	a3,s7,a5
    8000631c:	96da                	add	a3,a3,s6
    8000631e:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    80006322:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    80006324:	0207c563          	bltz	a5,8000634e <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    80006328:	2485                	addiw	s1,s1,1
    8000632a:	0711                	addi	a4,a4,4
    8000632c:	25548063          	beq	s1,s5,8000656c <virtio_disk_rw+0x2a6>
    idx[i] = alloc_desc();
    80006330:	863a                	mv	a2,a4
  for(int i = 0; i < NUM; i++){
    80006332:	0001f697          	auipc	a3,0x1f
    80006336:	ce668693          	addi	a3,a3,-794 # 80025018 <disk+0x2018>
    8000633a:	87d2                	mv	a5,s4
    if(disk.free[i]){
    8000633c:	0006c583          	lbu	a1,0(a3)
    80006340:	fde1                	bnez	a1,80006318 <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    80006342:	2785                	addiw	a5,a5,1
    80006344:	0685                	addi	a3,a3,1
    80006346:	ff879be3          	bne	a5,s8,8000633c <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    8000634a:	57fd                	li	a5,-1
    8000634c:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    8000634e:	02905a63          	blez	s1,80006382 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006352:	f9042503          	lw	a0,-112(s0)
    80006356:	00000097          	auipc	ra,0x0
    8000635a:	d90080e7          	jalr	-624(ra) # 800060e6 <free_desc>
      for(int j = 0; j < i; j++)
    8000635e:	4785                	li	a5,1
    80006360:	0297d163          	bge	a5,s1,80006382 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006364:	f9442503          	lw	a0,-108(s0)
    80006368:	00000097          	auipc	ra,0x0
    8000636c:	d7e080e7          	jalr	-642(ra) # 800060e6 <free_desc>
      for(int j = 0; j < i; j++)
    80006370:	4789                	li	a5,2
    80006372:	0097d863          	bge	a5,s1,80006382 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006376:	f9842503          	lw	a0,-104(s0)
    8000637a:	00000097          	auipc	ra,0x0
    8000637e:	d6c080e7          	jalr	-660(ra) # 800060e6 <free_desc>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006382:	0001f597          	auipc	a1,0x1f
    80006386:	da658593          	addi	a1,a1,-602 # 80025128 <disk+0x2128>
    8000638a:	0001f517          	auipc	a0,0x1f
    8000638e:	c8e50513          	addi	a0,a0,-882 # 80025018 <disk+0x2018>
    80006392:	ffffc097          	auipc	ra,0xffffc
    80006396:	010080e7          	jalr	16(ra) # 800023a2 <sleep>
  for(int i = 0; i < 3; i++){
    8000639a:	f9040713          	addi	a4,s0,-112
    8000639e:	84ce                	mv	s1,s3
    800063a0:	bf41                	j	80006330 <virtio_disk_rw+0x6a>
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];

  if(write)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
    800063a2:	20058713          	addi	a4,a1,512
    800063a6:	00471693          	slli	a3,a4,0x4
    800063aa:	0001d717          	auipc	a4,0x1d
    800063ae:	c5670713          	addi	a4,a4,-938 # 80023000 <disk>
    800063b2:	9736                	add	a4,a4,a3
    800063b4:	4685                	li	a3,1
    800063b6:	0ad72423          	sw	a3,168(a4)
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    800063ba:	20058713          	addi	a4,a1,512
    800063be:	00471693          	slli	a3,a4,0x4
    800063c2:	0001d717          	auipc	a4,0x1d
    800063c6:	c3e70713          	addi	a4,a4,-962 # 80023000 <disk>
    800063ca:	9736                	add	a4,a4,a3
    800063cc:	0a072623          	sw	zero,172(a4)
  buf0->sector = sector;
    800063d0:	0b973823          	sd	s9,176(a4)

  disk.desc[idx[0]].addr = (uint64) buf0;
    800063d4:	7679                	lui	a2,0xffffe
    800063d6:	963e                	add	a2,a2,a5
    800063d8:	0001f697          	auipc	a3,0x1f
    800063dc:	c2868693          	addi	a3,a3,-984 # 80025000 <disk+0x2000>
    800063e0:	6298                	ld	a4,0(a3)
    800063e2:	9732                	add	a4,a4,a2
    800063e4:	e308                	sd	a0,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    800063e6:	6298                	ld	a4,0(a3)
    800063e8:	9732                	add	a4,a4,a2
    800063ea:	4541                	li	a0,16
    800063ec:	c708                	sw	a0,8(a4)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    800063ee:	6298                	ld	a4,0(a3)
    800063f0:	9732                	add	a4,a4,a2
    800063f2:	4505                	li	a0,1
    800063f4:	00a71623          	sh	a0,12(a4)
  disk.desc[idx[0]].next = idx[1];
    800063f8:	f9442703          	lw	a4,-108(s0)
    800063fc:	6288                	ld	a0,0(a3)
    800063fe:	962a                	add	a2,a2,a0
    80006400:	00e61723          	sh	a4,14(a2) # ffffffffffffe00e <end+0xffffffff7ffd800e>

  disk.desc[idx[1]].addr = (uint64) b->data;
    80006404:	0712                	slli	a4,a4,0x4
    80006406:	6290                	ld	a2,0(a3)
    80006408:	963a                	add	a2,a2,a4
    8000640a:	05890513          	addi	a0,s2,88
    8000640e:	e208                	sd	a0,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    80006410:	6294                	ld	a3,0(a3)
    80006412:	96ba                	add	a3,a3,a4
    80006414:	40000613          	li	a2,1024
    80006418:	c690                	sw	a2,8(a3)
  if(write)
    8000641a:	140d0063          	beqz	s10,8000655a <virtio_disk_rw+0x294>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    8000641e:	0001f697          	auipc	a3,0x1f
    80006422:	be26b683          	ld	a3,-1054(a3) # 80025000 <disk+0x2000>
    80006426:	96ba                	add	a3,a3,a4
    80006428:	00069623          	sh	zero,12(a3)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    8000642c:	0001d817          	auipc	a6,0x1d
    80006430:	bd480813          	addi	a6,a6,-1068 # 80023000 <disk>
    80006434:	0001f517          	auipc	a0,0x1f
    80006438:	bcc50513          	addi	a0,a0,-1076 # 80025000 <disk+0x2000>
    8000643c:	6114                	ld	a3,0(a0)
    8000643e:	96ba                	add	a3,a3,a4
    80006440:	00c6d603          	lhu	a2,12(a3)
    80006444:	00166613          	ori	a2,a2,1
    80006448:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    8000644c:	f9842683          	lw	a3,-104(s0)
    80006450:	6110                	ld	a2,0(a0)
    80006452:	9732                	add	a4,a4,a2
    80006454:	00d71723          	sh	a3,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80006458:	20058613          	addi	a2,a1,512
    8000645c:	0612                	slli	a2,a2,0x4
    8000645e:	9642                	add	a2,a2,a6
    80006460:	577d                	li	a4,-1
    80006462:	02e60823          	sb	a4,48(a2)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80006466:	00469713          	slli	a4,a3,0x4
    8000646a:	6114                	ld	a3,0(a0)
    8000646c:	96ba                	add	a3,a3,a4
    8000646e:	03078793          	addi	a5,a5,48
    80006472:	97c2                	add	a5,a5,a6
    80006474:	e29c                	sd	a5,0(a3)
  disk.desc[idx[2]].len = 1;
    80006476:	611c                	ld	a5,0(a0)
    80006478:	97ba                	add	a5,a5,a4
    8000647a:	4685                	li	a3,1
    8000647c:	c794                	sw	a3,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    8000647e:	611c                	ld	a5,0(a0)
    80006480:	97ba                	add	a5,a5,a4
    80006482:	4809                	li	a6,2
    80006484:	01079623          	sh	a6,12(a5)
  disk.desc[idx[2]].next = 0;
    80006488:	611c                	ld	a5,0(a0)
    8000648a:	973e                	add	a4,a4,a5
    8000648c:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80006490:	00d92223          	sw	a3,4(s2)
  disk.info[idx[0]].b = b;
    80006494:	03263423          	sd	s2,40(a2)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006498:	6518                	ld	a4,8(a0)
    8000649a:	00275783          	lhu	a5,2(a4)
    8000649e:	8b9d                	andi	a5,a5,7
    800064a0:	0786                	slli	a5,a5,0x1
    800064a2:	97ba                	add	a5,a5,a4
    800064a4:	00b79223          	sh	a1,4(a5)

  __sync_synchronize();
    800064a8:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    800064ac:	6518                	ld	a4,8(a0)
    800064ae:	00275783          	lhu	a5,2(a4)
    800064b2:	2785                	addiw	a5,a5,1
    800064b4:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    800064b8:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    800064bc:	100017b7          	lui	a5,0x10001
    800064c0:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    800064c4:	00492703          	lw	a4,4(s2)
    800064c8:	4785                	li	a5,1
    800064ca:	02f71163          	bne	a4,a5,800064ec <virtio_disk_rw+0x226>
    sleep(b, &disk.vdisk_lock);
    800064ce:	0001f997          	auipc	s3,0x1f
    800064d2:	c5a98993          	addi	s3,s3,-934 # 80025128 <disk+0x2128>
  while(b->disk == 1) {
    800064d6:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    800064d8:	85ce                	mv	a1,s3
    800064da:	854a                	mv	a0,s2
    800064dc:	ffffc097          	auipc	ra,0xffffc
    800064e0:	ec6080e7          	jalr	-314(ra) # 800023a2 <sleep>
  while(b->disk == 1) {
    800064e4:	00492783          	lw	a5,4(s2)
    800064e8:	fe9788e3          	beq	a5,s1,800064d8 <virtio_disk_rw+0x212>
  }

  disk.info[idx[0]].b = 0;
    800064ec:	f9042903          	lw	s2,-112(s0)
    800064f0:	20090793          	addi	a5,s2,512
    800064f4:	00479713          	slli	a4,a5,0x4
    800064f8:	0001d797          	auipc	a5,0x1d
    800064fc:	b0878793          	addi	a5,a5,-1272 # 80023000 <disk>
    80006500:	97ba                	add	a5,a5,a4
    80006502:	0207b423          	sd	zero,40(a5)
    int flag = disk.desc[i].flags;
    80006506:	0001f997          	auipc	s3,0x1f
    8000650a:	afa98993          	addi	s3,s3,-1286 # 80025000 <disk+0x2000>
    8000650e:	00491713          	slli	a4,s2,0x4
    80006512:	0009b783          	ld	a5,0(s3)
    80006516:	97ba                	add	a5,a5,a4
    80006518:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    8000651c:	854a                	mv	a0,s2
    8000651e:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    80006522:	00000097          	auipc	ra,0x0
    80006526:	bc4080e7          	jalr	-1084(ra) # 800060e6 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    8000652a:	8885                	andi	s1,s1,1
    8000652c:	f0ed                	bnez	s1,8000650e <virtio_disk_rw+0x248>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    8000652e:	0001f517          	auipc	a0,0x1f
    80006532:	bfa50513          	addi	a0,a0,-1030 # 80025128 <disk+0x2128>
    80006536:	ffffa097          	auipc	ra,0xffffa
    8000653a:	762080e7          	jalr	1890(ra) # 80000c98 <release>
}
    8000653e:	70a6                	ld	ra,104(sp)
    80006540:	7406                	ld	s0,96(sp)
    80006542:	64e6                	ld	s1,88(sp)
    80006544:	6946                	ld	s2,80(sp)
    80006546:	69a6                	ld	s3,72(sp)
    80006548:	6a06                	ld	s4,64(sp)
    8000654a:	7ae2                	ld	s5,56(sp)
    8000654c:	7b42                	ld	s6,48(sp)
    8000654e:	7ba2                	ld	s7,40(sp)
    80006550:	7c02                	ld	s8,32(sp)
    80006552:	6ce2                	ld	s9,24(sp)
    80006554:	6d42                	ld	s10,16(sp)
    80006556:	6165                	addi	sp,sp,112
    80006558:	8082                	ret
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    8000655a:	0001f697          	auipc	a3,0x1f
    8000655e:	aa66b683          	ld	a3,-1370(a3) # 80025000 <disk+0x2000>
    80006562:	96ba                	add	a3,a3,a4
    80006564:	4609                	li	a2,2
    80006566:	00c69623          	sh	a2,12(a3)
    8000656a:	b5c9                	j	8000642c <virtio_disk_rw+0x166>
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    8000656c:	f9042583          	lw	a1,-112(s0)
    80006570:	20058793          	addi	a5,a1,512
    80006574:	0792                	slli	a5,a5,0x4
    80006576:	0001d517          	auipc	a0,0x1d
    8000657a:	b3250513          	addi	a0,a0,-1230 # 800230a8 <disk+0xa8>
    8000657e:	953e                	add	a0,a0,a5
  if(write)
    80006580:	e20d11e3          	bnez	s10,800063a2 <virtio_disk_rw+0xdc>
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
    80006584:	20058713          	addi	a4,a1,512
    80006588:	00471693          	slli	a3,a4,0x4
    8000658c:	0001d717          	auipc	a4,0x1d
    80006590:	a7470713          	addi	a4,a4,-1420 # 80023000 <disk>
    80006594:	9736                	add	a4,a4,a3
    80006596:	0a072423          	sw	zero,168(a4)
    8000659a:	b505                	j	800063ba <virtio_disk_rw+0xf4>

000000008000659c <virtio_disk_intr>:

void
virtio_disk_intr()
{
    8000659c:	1101                	addi	sp,sp,-32
    8000659e:	ec06                	sd	ra,24(sp)
    800065a0:	e822                	sd	s0,16(sp)
    800065a2:	e426                	sd	s1,8(sp)
    800065a4:	e04a                	sd	s2,0(sp)
    800065a6:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    800065a8:	0001f517          	auipc	a0,0x1f
    800065ac:	b8050513          	addi	a0,a0,-1152 # 80025128 <disk+0x2128>
    800065b0:	ffffa097          	auipc	ra,0xffffa
    800065b4:	634080e7          	jalr	1588(ra) # 80000be4 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    800065b8:	10001737          	lui	a4,0x10001
    800065bc:	533c                	lw	a5,96(a4)
    800065be:	8b8d                	andi	a5,a5,3
    800065c0:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    800065c2:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    800065c6:	0001f797          	auipc	a5,0x1f
    800065ca:	a3a78793          	addi	a5,a5,-1478 # 80025000 <disk+0x2000>
    800065ce:	6b94                	ld	a3,16(a5)
    800065d0:	0207d703          	lhu	a4,32(a5)
    800065d4:	0026d783          	lhu	a5,2(a3)
    800065d8:	06f70163          	beq	a4,a5,8000663a <virtio_disk_intr+0x9e>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    800065dc:	0001d917          	auipc	s2,0x1d
    800065e0:	a2490913          	addi	s2,s2,-1500 # 80023000 <disk>
    800065e4:	0001f497          	auipc	s1,0x1f
    800065e8:	a1c48493          	addi	s1,s1,-1508 # 80025000 <disk+0x2000>
    __sync_synchronize();
    800065ec:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    800065f0:	6898                	ld	a4,16(s1)
    800065f2:	0204d783          	lhu	a5,32(s1)
    800065f6:	8b9d                	andi	a5,a5,7
    800065f8:	078e                	slli	a5,a5,0x3
    800065fa:	97ba                	add	a5,a5,a4
    800065fc:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    800065fe:	20078713          	addi	a4,a5,512
    80006602:	0712                	slli	a4,a4,0x4
    80006604:	974a                	add	a4,a4,s2
    80006606:	03074703          	lbu	a4,48(a4) # 10001030 <_entry-0x6fffefd0>
    8000660a:	e731                	bnez	a4,80006656 <virtio_disk_intr+0xba>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    8000660c:	20078793          	addi	a5,a5,512
    80006610:	0792                	slli	a5,a5,0x4
    80006612:	97ca                	add	a5,a5,s2
    80006614:	7788                	ld	a0,40(a5)
    b->disk = 0;   // disk is done with buf
    80006616:	00052223          	sw	zero,4(a0)
    wakeup(b);
    8000661a:	ffffc097          	auipc	ra,0xffffc
    8000661e:	f28080e7          	jalr	-216(ra) # 80002542 <wakeup>

    disk.used_idx += 1;
    80006622:	0204d783          	lhu	a5,32(s1)
    80006626:	2785                	addiw	a5,a5,1
    80006628:	17c2                	slli	a5,a5,0x30
    8000662a:	93c1                	srli	a5,a5,0x30
    8000662c:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006630:	6898                	ld	a4,16(s1)
    80006632:	00275703          	lhu	a4,2(a4)
    80006636:	faf71be3          	bne	a4,a5,800065ec <virtio_disk_intr+0x50>
  }

  release(&disk.vdisk_lock);
    8000663a:	0001f517          	auipc	a0,0x1f
    8000663e:	aee50513          	addi	a0,a0,-1298 # 80025128 <disk+0x2128>
    80006642:	ffffa097          	auipc	ra,0xffffa
    80006646:	656080e7          	jalr	1622(ra) # 80000c98 <release>
}
    8000664a:	60e2                	ld	ra,24(sp)
    8000664c:	6442                	ld	s0,16(sp)
    8000664e:	64a2                	ld	s1,8(sp)
    80006650:	6902                	ld	s2,0(sp)
    80006652:	6105                	addi	sp,sp,32
    80006654:	8082                	ret
      panic("virtio_disk_intr status");
    80006656:	00002517          	auipc	a0,0x2
    8000665a:	28250513          	addi	a0,a0,642 # 800088d8 <syscalls+0x3c0>
    8000665e:	ffffa097          	auipc	ra,0xffffa
    80006662:	ee0080e7          	jalr	-288(ra) # 8000053e <panic>
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
