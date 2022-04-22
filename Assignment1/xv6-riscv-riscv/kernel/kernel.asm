
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	8c013103          	ld	sp,-1856(sp) # 800088c0 <_GLOBAL_OFFSET_TABLE_+0x8>
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
    80000068:	fdc78793          	addi	a5,a5,-36 # 80006040 <timervec>
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
    80000130:	812080e7          	jalr	-2030(ra) # 8000293e <either_copyin>
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
    800001d8:	1ee080e7          	jalr	494(ra) # 800023c2 <sleep>
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
    80000214:	6d8080e7          	jalr	1752(ra) # 800028e8 <either_copyout>
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
    800002f6:	6a2080e7          	jalr	1698(ra) # 80002994 <procdump>
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
    8000044a:	11c080e7          	jalr	284(ra) # 80002562 <wakeup>
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
    800008a4:	cc2080e7          	jalr	-830(ra) # 80002562 <wakeup>
    
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
    80000930:	a96080e7          	jalr	-1386(ra) # 800023c2 <sleep>
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
    80000ed8:	c00080e7          	jalr	-1024(ra) # 80002ad4 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000edc:	00005097          	auipc	ra,0x5
    80000ee0:	1a4080e7          	jalr	420(ra) # 80006080 <plicinithart>
  }

  scheduler();        
    80000ee4:	00001097          	auipc	ra,0x1
    80000ee8:	3a4080e7          	jalr	932(ra) # 80002288 <scheduler>
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
    80000f58:	b58080e7          	jalr	-1192(ra) # 80002aac <trapinit>
    trapinithart();  // install kernel trap vector
    80000f5c:	00002097          	auipc	ra,0x2
    80000f60:	b78080e7          	jalr	-1160(ra) # 80002ad4 <trapinithart>
    plicinit();      // set up interrupt controller
    80000f64:	00005097          	auipc	ra,0x5
    80000f68:	106080e7          	jalr	262(ra) # 8000606a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f6c:	00005097          	auipc	ra,0x5
    80000f70:	114080e7          	jalr	276(ra) # 80006080 <plicinithart>
    binit();         // buffer cache
    80000f74:	00002097          	auipc	ra,0x2
    80000f78:	2f0080e7          	jalr	752(ra) # 80003264 <binit>
    iinit();         // inode table
    80000f7c:	00003097          	auipc	ra,0x3
    80000f80:	980080e7          	jalr	-1664(ra) # 800038fc <iinit>
    fileinit();      // file table
    80000f84:	00004097          	auipc	ra,0x4
    80000f88:	92a080e7          	jalr	-1750(ra) # 800048ae <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f8c:	00005097          	auipc	ra,0x5
    80000f90:	216080e7          	jalr	534(ra) # 800061a2 <virtio_disk_init>
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
    80001a1c:	e587a783          	lw	a5,-424(a5) # 80008870 <first.1723>
    80001a20:	eb89                	bnez	a5,80001a32 <forkret+0x32>
        // be run from main().
        first = 0;
        fsinit(ROOTDEV);
    }

    usertrapret();
    80001a22:	00001097          	auipc	ra,0x1
    80001a26:	0ca080e7          	jalr	202(ra) # 80002aec <usertrapret>
}
    80001a2a:	60a2                	ld	ra,8(sp)
    80001a2c:	6402                	ld	s0,0(sp)
    80001a2e:	0141                	addi	sp,sp,16
    80001a30:	8082                	ret
        first = 0;
    80001a32:	00007797          	auipc	a5,0x7
    80001a36:	e207af23          	sw	zero,-450(a5) # 80008870 <first.1723>
        fsinit(ROOTDEV);
    80001a3a:	4505                	li	a0,1
    80001a3c:	00002097          	auipc	ra,0x2
    80001a40:	e40080e7          	jalr	-448(ra) # 8000387c <fsinit>
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
    80001a68:	e1078793          	addi	a5,a5,-496 # 80008874 <nextpid>
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
    80001ce6:	b9e58593          	addi	a1,a1,-1122 # 80008880 <initcode>
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
    80001d24:	58a080e7          	jalr	1418(ra) # 800042aa <namei>
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
    80001e66:	ade080e7          	jalr	-1314(ra) # 80004940 <filedup>
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
    80001e88:	c32080e7          	jalr	-974(ra) # 80003ab6 <idup>
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
    80001fbe:	a88080e7          	jalr	-1400(ra) # 80002a42 <swtch>
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
        struct proc *min_proc = proc;
    80002034:	0000fa97          	auipc	s5,0xf
    80002038:	6bca8a93          	addi	s5,s5,1724 # 800116f0 <proc>
            if (p->state == RUNNABLE && p->mean_ticks < min_proc->mean_ticks)
    8000203c:	490d                	li	s2,3
        for (p = proc; p < &proc[NPROC]; p++) {
    8000203e:	00016997          	auipc	s3,0x16
    80002042:	8b298993          	addi	s3,s3,-1870 # 800178f0 <tickslock>
        if (min_proc->state == RUNNABLE && ticks >= pauseTicks) {
    80002046:	00007b17          	auipc	s6,0x7
    8000204a:	00ab0b13          	addi	s6,s6,10 # 80009050 <ticks>
    8000204e:	00007c17          	auipc	s8,0x7
    80002052:	ff2c0c13          	addi	s8,s8,-14 # 80009040 <pauseTicks>
            c->proc = min_proc;
    80002056:	079e                	slli	a5,a5,0x7
    80002058:	0000fb97          	auipc	s7,0xf
    8000205c:	268b8b93          	addi	s7,s7,616 # 800112c0 <pid_lock>
    80002060:	9bbe                	add	s7,s7,a5
    80002062:	a229                	j	8000216c <sjfScheduler+0x176>
            release(&p->lock);
    80002064:	8526                	mv	a0,s1
    80002066:	fffff097          	auipc	ra,0xfffff
    8000206a:	c32080e7          	jalr	-974(ra) # 80000c98 <release>
        for (p = proc; p < &proc[NPROC]; p++) {
    8000206e:	18848493          	addi	s1,s1,392
    80002072:	03348163          	beq	s1,s3,80002094 <sjfScheduler+0x9e>
            acquire(&p->lock);
    80002076:	8526                	mv	a0,s1
    80002078:	fffff097          	auipc	ra,0xfffff
    8000207c:	b6c080e7          	jalr	-1172(ra) # 80000be4 <acquire>
            if (p->state == RUNNABLE && p->mean_ticks < min_proc->mean_ticks)
    80002080:	4c9c                	lw	a5,24(s1)
    80002082:	ff2791e3          	bne	a5,s2,80002064 <sjfScheduler+0x6e>
    80002086:	40b8                	lw	a4,64(s1)
    80002088:	040a2783          	lw	a5,64(s4)
    8000208c:	fcf75ce3          	bge	a4,a5,80002064 <sjfScheduler+0x6e>
    80002090:	8a26                	mv	s4,s1
    80002092:	bfc9                	j	80002064 <sjfScheduler+0x6e>
        printf("after loop");
    80002094:	00006517          	auipc	a0,0x6
    80002098:	19450513          	addi	a0,a0,404 # 80008228 <digits+0x1e8>
    8000209c:	ffffe097          	auipc	ra,0xffffe
    800020a0:	4ec080e7          	jalr	1260(ra) # 80000588 <printf>
        acquire(&min_proc->lock);
    800020a4:	84d2                	mv	s1,s4
    800020a6:	8552                	mv	a0,s4
    800020a8:	fffff097          	auipc	ra,0xfffff
    800020ac:	b3c080e7          	jalr	-1220(ra) # 80000be4 <acquire>
        if (min_proc->state == RUNNABLE && ticks >= pauseTicks) {
    800020b0:	018a2783          	lw	a5,24(s4)
    800020b4:	0b279763          	bne	a5,s2,80002162 <sjfScheduler+0x16c>
    800020b8:	000b2703          	lw	a4,0(s6)
    800020bc:	000c2783          	lw	a5,0(s8)
    800020c0:	0af76163          	bltu	a4,a5,80002162 <sjfScheduler+0x16c>
            printf("after acuire\n");
    800020c4:	00006517          	auipc	a0,0x6
    800020c8:	17450513          	addi	a0,a0,372 # 80008238 <digits+0x1f8>
    800020cc:	ffffe097          	auipc	ra,0xffffe
    800020d0:	4bc080e7          	jalr	1212(ra) # 80000588 <printf>
            p->runnable_time = p->runnable_time + ticks - p->last_time_changed;
    800020d4:	000b2d83          	lw	s11,0(s6)
    800020d8:	00015d17          	auipc	s10,0x15
    800020dc:	618d0d13          	addi	s10,s10,1560 # 800176f0 <proc+0x6000>
    800020e0:	250d2783          	lw	a5,592(s10)
    800020e4:	01b787bb          	addw	a5,a5,s11
    800020e8:	258d2703          	lw	a4,600(s10)
    800020ec:	9f99                	subw	a5,a5,a4
    800020ee:	24fd2823          	sw	a5,592(s10)
            p->last_time_changed = ticks;      //setting the starting ticks when getting to runnable for section 4
    800020f2:	25bd2c23          	sw	s11,600(s10)
            min_proc->state = RUNNING;
    800020f6:	4791                	li	a5,4
    800020f8:	00fa2c23          	sw	a5,24(s4)
            c->proc = min_proc;
    800020fc:	034bb823          	sd	s4,48(s7)
            printf("before swtch \n");
    80002100:	00006517          	auipc	a0,0x6
    80002104:	14850513          	addi	a0,a0,328 # 80008248 <digits+0x208>
    80002108:	ffffe097          	auipc	ra,0xffffe
    8000210c:	480080e7          	jalr	1152(ra) # 80000588 <printf>
            swtch(&c->context, &min_proc->context);
    80002110:	080a0593          	addi	a1,s4,128
    80002114:	8566                	mv	a0,s9
    80002116:	00001097          	auipc	ra,0x1
    8000211a:	92c080e7          	jalr	-1748(ra) # 80002a42 <swtch>
            printf("after swtch\n");
    8000211e:	00006517          	auipc	a0,0x6
    80002122:	13a50513          	addi	a0,a0,314 # 80008258 <digits+0x218>
    80002126:	ffffe097          	auipc	ra,0xffffe
    8000212a:	462080e7          	jalr	1122(ra) # 80000588 <printf>
            p->last_ticks = ticks - startingTicks;
    8000212e:	000b2703          	lw	a4,0(s6)
    80002132:	41b7073b          	subw	a4,a4,s11
    80002136:	24ed2223          	sw	a4,580(s10)
            p->mean_ticks = ((10 - rate) * p->mean_ticks + p->last_ticks * (rate)) / 10;
    8000213a:	00006617          	auipc	a2,0x6
    8000213e:	73e62603          	lw	a2,1854(a2) # 80008878 <rate>
    80002142:	46a9                	li	a3,10
    80002144:	40c687bb          	subw	a5,a3,a2
    80002148:	240d2583          	lw	a1,576(s10)
    8000214c:	02b787bb          	mulw	a5,a5,a1
    80002150:	02c7073b          	mulw	a4,a4,a2
    80002154:	9fb9                	addw	a5,a5,a4
    80002156:	02d7c7bb          	divw	a5,a5,a3
    8000215a:	24fd2023          	sw	a5,576(s10)
            c->proc = 0;
    8000215e:	020bb823          	sd	zero,48(s7)
        release(&min_proc->lock);
    80002162:	8526                	mv	a0,s1
    80002164:	fffff097          	auipc	ra,0xfffff
    80002168:	b34080e7          	jalr	-1228(ra) # 80000c98 <release>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000216c:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002170:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002174:	10079073          	csrw	sstatus,a5
        struct proc *min_proc = proc;
    80002178:	8a56                	mv	s4,s5
        for (p = proc; p < &proc[NPROC]; p++) {
    8000217a:	84d6                	mv	s1,s5
    8000217c:	bded                	j	80002076 <sjfScheduler+0x80>

000000008000217e <fcfs>:
void fcfs(void) {
    8000217e:	711d                	addi	sp,sp,-96
    80002180:	ec86                	sd	ra,88(sp)
    80002182:	e8a2                	sd	s0,80(sp)
    80002184:	e4a6                	sd	s1,72(sp)
    80002186:	e0ca                	sd	s2,64(sp)
    80002188:	fc4e                	sd	s3,56(sp)
    8000218a:	f852                	sd	s4,48(sp)
    8000218c:	f456                	sd	s5,40(sp)
    8000218e:	f05a                	sd	s6,32(sp)
    80002190:	ec5e                	sd	s7,24(sp)
    80002192:	e862                	sd	s8,16(sp)
    80002194:	e466                	sd	s9,8(sp)
    80002196:	e06a                	sd	s10,0(sp)
    80002198:	1080                	addi	s0,sp,96
  asm volatile("mv %0, tp" : "=r" (x) );
    8000219a:	8792                	mv	a5,tp
    int id = r_tp();
    8000219c:	2781                	sext.w	a5,a5
    c->proc = 0;
    8000219e:	00779c93          	slli	s9,a5,0x7
    800021a2:	0000f717          	auipc	a4,0xf
    800021a6:	11e70713          	addi	a4,a4,286 # 800112c0 <pid_lock>
    800021aa:	9766                	add	a4,a4,s9
    800021ac:	02073823          	sd	zero,48(a4)
            swtch(&c->context, &max_lrt_proc->context);
    800021b0:	0000f717          	auipc	a4,0xf
    800021b4:	14870713          	addi	a4,a4,328 # 800112f8 <cpus+0x8>
    800021b8:	9cba                	add	s9,s9,a4
        if (ticks >= pauseTicks && ticks >= pauseTicks) {
    800021ba:	00007c17          	auipc	s8,0x7
    800021be:	e96c0c13          	addi	s8,s8,-362 # 80009050 <ticks>
    800021c2:	00007d17          	auipc	s10,0x7
    800021c6:	e7ed0d13          	addi	s10,s10,-386 # 80009040 <pauseTicks>
            struct proc *max_lrt_proc = proc; // lrt = last runnable time
    800021ca:	0000fb97          	auipc	s7,0xf
    800021ce:	526b8b93          	addi	s7,s7,1318 # 800116f0 <proc>
                if (p->state == RUNNABLE && p->mean_ticks > max_lrt_proc->mean_ticks)
    800021d2:	498d                	li	s3,3
            for (p = proc; p < &proc[NPROC]; p++) {
    800021d4:	00015917          	auipc	s2,0x15
    800021d8:	71c90913          	addi	s2,s2,1820 # 800178f0 <tickslock>
            p->runnable_time = p->runnable_time + ticks - p->last_time_changed;
    800021dc:	00015a97          	auipc	s5,0x15
    800021e0:	514a8a93          	addi	s5,s5,1300 # 800176f0 <proc+0x6000>
            c->proc = max_lrt_proc;
    800021e4:	079e                	slli	a5,a5,0x7
    800021e6:	0000fb17          	auipc	s6,0xf
    800021ea:	0dab0b13          	addi	s6,s6,218 # 800112c0 <pid_lock>
    800021ee:	9b3e                	add	s6,s6,a5
    800021f0:	a8ad                	j	8000226a <fcfs+0xec>
                release(&p->lock);
    800021f2:	8526                	mv	a0,s1
    800021f4:	fffff097          	auipc	ra,0xfffff
    800021f8:	aa4080e7          	jalr	-1372(ra) # 80000c98 <release>
            for (p = proc; p < &proc[NPROC]; p++) {
    800021fc:	18848493          	addi	s1,s1,392
    80002200:	03248163          	beq	s1,s2,80002222 <fcfs+0xa4>
                acquire(&p->lock);
    80002204:	8526                	mv	a0,s1
    80002206:	fffff097          	auipc	ra,0xfffff
    8000220a:	9de080e7          	jalr	-1570(ra) # 80000be4 <acquire>
                if (p->state == RUNNABLE && p->mean_ticks > max_lrt_proc->mean_ticks)
    8000220e:	4c9c                	lw	a5,24(s1)
    80002210:	ff3791e3          	bne	a5,s3,800021f2 <fcfs+0x74>
    80002214:	40b8                	lw	a4,64(s1)
    80002216:	040a2783          	lw	a5,64(s4)
    8000221a:	fce7dce3          	bge	a5,a4,800021f2 <fcfs+0x74>
    8000221e:	8a26                	mv	s4,s1
    80002220:	bfc9                	j	800021f2 <fcfs+0x74>
            acquire(&max_lrt_proc->lock);
    80002222:	8552                	mv	a0,s4
    80002224:	fffff097          	auipc	ra,0xfffff
    80002228:	9c0080e7          	jalr	-1600(ra) # 80000be4 <acquire>
            p->runnable_time = p->runnable_time + ticks - p->last_time_changed;
    8000222c:	000c2703          	lw	a4,0(s8)
    80002230:	250aa783          	lw	a5,592(s5)
    80002234:	9fb9                	addw	a5,a5,a4
    80002236:	258aa683          	lw	a3,600(s5)
    8000223a:	9f95                	subw	a5,a5,a3
    8000223c:	24faa823          	sw	a5,592(s5)
            p->last_time_changed = ticks;      //setting the starting ticks when getting to runnable for section 4
    80002240:	24eaac23          	sw	a4,600(s5)
            max_lrt_proc->state = RUNNING;
    80002244:	4791                	li	a5,4
    80002246:	00fa2c23          	sw	a5,24(s4)
            c->proc = max_lrt_proc;
    8000224a:	034b3823          	sd	s4,48(s6)
            swtch(&c->context, &max_lrt_proc->context);
    8000224e:	080a0593          	addi	a1,s4,128
    80002252:	8566                	mv	a0,s9
    80002254:	00000097          	auipc	ra,0x0
    80002258:	7ee080e7          	jalr	2030(ra) # 80002a42 <swtch>
            c->proc = 0;
    8000225c:	020b3823          	sd	zero,48(s6)
            release(&max_lrt_proc->lock);
    80002260:	8552                	mv	a0,s4
    80002262:	fffff097          	auipc	ra,0xfffff
    80002266:	a36080e7          	jalr	-1482(ra) # 80000c98 <release>
        if (ticks >= pauseTicks && ticks >= pauseTicks) {
    8000226a:	000c2683          	lw	a3,0(s8)
    8000226e:	000d2703          	lw	a4,0(s10)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002272:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002276:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000227a:	10079073          	csrw	sstatus,a5
    8000227e:	fee6eae3          	bltu	a3,a4,80002272 <fcfs+0xf4>
            struct proc *max_lrt_proc = proc; // lrt = last runnable time
    80002282:	8a5e                	mv	s4,s7
            for (p = proc; p < &proc[NPROC]; p++) {
    80002284:	84de                	mv	s1,s7
    80002286:	bfbd                	j	80002204 <fcfs+0x86>

0000000080002288 <scheduler>:
scheduler(void) {
    80002288:	1141                	addi	sp,sp,-16
    8000228a:	e406                	sd	ra,8(sp)
    8000228c:	e022                	sd	s0,0(sp)
    8000228e:	0800                	addi	s0,sp,16
    sjfScheduler();
    80002290:	00000097          	auipc	ra,0x0
    80002294:	d66080e7          	jalr	-666(ra) # 80001ff6 <sjfScheduler>

0000000080002298 <sched>:
sched(void) {
    80002298:	7179                	addi	sp,sp,-48
    8000229a:	f406                	sd	ra,40(sp)
    8000229c:	f022                	sd	s0,32(sp)
    8000229e:	ec26                	sd	s1,24(sp)
    800022a0:	e84a                	sd	s2,16(sp)
    800022a2:	e44e                	sd	s3,8(sp)
    800022a4:	1800                	addi	s0,sp,48
    struct proc *p = myproc();
    800022a6:	fffff097          	auipc	ra,0xfffff
    800022aa:	722080e7          	jalr	1826(ra) # 800019c8 <myproc>
    800022ae:	84aa                	mv	s1,a0
    if (!holding(&p->lock))
    800022b0:	fffff097          	auipc	ra,0xfffff
    800022b4:	8ba080e7          	jalr	-1862(ra) # 80000b6a <holding>
    800022b8:	c93d                	beqz	a0,8000232e <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    800022ba:	8792                	mv	a5,tp
    if (mycpu()->noff != 1)
    800022bc:	2781                	sext.w	a5,a5
    800022be:	079e                	slli	a5,a5,0x7
    800022c0:	0000f717          	auipc	a4,0xf
    800022c4:	00070713          	mv	a4,a4
    800022c8:	97ba                	add	a5,a5,a4
    800022ca:	0a87a703          	lw	a4,168(a5)
    800022ce:	4785                	li	a5,1
    800022d0:	06f71763          	bne	a4,a5,8000233e <sched+0xa6>
    if (p->state == RUNNING)
    800022d4:	4c98                	lw	a4,24(s1)
    800022d6:	4791                	li	a5,4
    800022d8:	06f70b63          	beq	a4,a5,8000234e <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800022dc:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    800022e0:	8b89                	andi	a5,a5,2
    if (intr_get())
    800022e2:	efb5                	bnez	a5,8000235e <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    800022e4:	8792                	mv	a5,tp
    intena = mycpu()->intena;
    800022e6:	0000f917          	auipc	s2,0xf
    800022ea:	fda90913          	addi	s2,s2,-38 # 800112c0 <pid_lock>
    800022ee:	2781                	sext.w	a5,a5
    800022f0:	079e                	slli	a5,a5,0x7
    800022f2:	97ca                	add	a5,a5,s2
    800022f4:	0ac7a983          	lw	s3,172(a5)
    800022f8:	8792                	mv	a5,tp
    swtch(&p->context, &mycpu()->context);
    800022fa:	2781                	sext.w	a5,a5
    800022fc:	079e                	slli	a5,a5,0x7
    800022fe:	0000f597          	auipc	a1,0xf
    80002302:	ffa58593          	addi	a1,a1,-6 # 800112f8 <cpus+0x8>
    80002306:	95be                	add	a1,a1,a5
    80002308:	08048513          	addi	a0,s1,128
    8000230c:	00000097          	auipc	ra,0x0
    80002310:	736080e7          	jalr	1846(ra) # 80002a42 <swtch>
    80002314:	8792                	mv	a5,tp
    mycpu()->intena = intena;
    80002316:	2781                	sext.w	a5,a5
    80002318:	079e                	slli	a5,a5,0x7
    8000231a:	97ca                	add	a5,a5,s2
    8000231c:	0b37a623          	sw	s3,172(a5)
}
    80002320:	70a2                	ld	ra,40(sp)
    80002322:	7402                	ld	s0,32(sp)
    80002324:	64e2                	ld	s1,24(sp)
    80002326:	6942                	ld	s2,16(sp)
    80002328:	69a2                	ld	s3,8(sp)
    8000232a:	6145                	addi	sp,sp,48
    8000232c:	8082                	ret
        panic("sched p->lock");
    8000232e:	00006517          	auipc	a0,0x6
    80002332:	f3a50513          	addi	a0,a0,-198 # 80008268 <digits+0x228>
    80002336:	ffffe097          	auipc	ra,0xffffe
    8000233a:	208080e7          	jalr	520(ra) # 8000053e <panic>
        panic("sched locks");
    8000233e:	00006517          	auipc	a0,0x6
    80002342:	f3a50513          	addi	a0,a0,-198 # 80008278 <digits+0x238>
    80002346:	ffffe097          	auipc	ra,0xffffe
    8000234a:	1f8080e7          	jalr	504(ra) # 8000053e <panic>
        panic("sched running");
    8000234e:	00006517          	auipc	a0,0x6
    80002352:	f3a50513          	addi	a0,a0,-198 # 80008288 <digits+0x248>
    80002356:	ffffe097          	auipc	ra,0xffffe
    8000235a:	1e8080e7          	jalr	488(ra) # 8000053e <panic>
        panic("sched interruptible");
    8000235e:	00006517          	auipc	a0,0x6
    80002362:	f3a50513          	addi	a0,a0,-198 # 80008298 <digits+0x258>
    80002366:	ffffe097          	auipc	ra,0xffffe
    8000236a:	1d8080e7          	jalr	472(ra) # 8000053e <panic>

000000008000236e <yield>:
yield(void) {
    8000236e:	1101                	addi	sp,sp,-32
    80002370:	ec06                	sd	ra,24(sp)
    80002372:	e822                	sd	s0,16(sp)
    80002374:	e426                	sd	s1,8(sp)
    80002376:	1000                	addi	s0,sp,32
    struct proc *p = myproc();
    80002378:	fffff097          	auipc	ra,0xfffff
    8000237c:	650080e7          	jalr	1616(ra) # 800019c8 <myproc>
    80002380:	84aa                	mv	s1,a0
    acquire(&p->lock);
    80002382:	fffff097          	auipc	ra,0xfffff
    80002386:	862080e7          	jalr	-1950(ra) # 80000be4 <acquire>
    p->state = RUNNABLE;
    8000238a:	478d                	li	a5,3
    8000238c:	cc9c                	sw	a5,24(s1)
    p->running_time = p->running_time + (ticks - p->last_time_changed);
    8000238e:	00007797          	auipc	a5,0x7
    80002392:	cc27a783          	lw	a5,-830(a5) # 80009050 <ticks>
    80002396:	48f8                	lw	a4,84(s1)
    80002398:	9f3d                	addw	a4,a4,a5
    8000239a:	4cb4                	lw	a3,88(s1)
    8000239c:	9f15                	subw	a4,a4,a3
    8000239e:	c8f8                	sw	a4,84(s1)
    p->last_runnable_time = ticks;     //added last_runnable time for fcfs
    800023a0:	2781                	sext.w	a5,a5
    800023a2:	c4bc                	sw	a5,72(s1)
    p->last_time_changed = ticks;      //setting the starting ticks when getting to runnable for section 4
    800023a4:	ccbc                	sw	a5,88(s1)
    sched();
    800023a6:	00000097          	auipc	ra,0x0
    800023aa:	ef2080e7          	jalr	-270(ra) # 80002298 <sched>
    release(&p->lock);
    800023ae:	8526                	mv	a0,s1
    800023b0:	fffff097          	auipc	ra,0xfffff
    800023b4:	8e8080e7          	jalr	-1816(ra) # 80000c98 <release>
}
    800023b8:	60e2                	ld	ra,24(sp)
    800023ba:	6442                	ld	s0,16(sp)
    800023bc:	64a2                	ld	s1,8(sp)
    800023be:	6105                	addi	sp,sp,32
    800023c0:	8082                	ret

00000000800023c2 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk) {
    800023c2:	7179                	addi	sp,sp,-48
    800023c4:	f406                	sd	ra,40(sp)
    800023c6:	f022                	sd	s0,32(sp)
    800023c8:	ec26                	sd	s1,24(sp)
    800023ca:	e84a                	sd	s2,16(sp)
    800023cc:	e44e                	sd	s3,8(sp)
    800023ce:	1800                	addi	s0,sp,48
    800023d0:	89aa                	mv	s3,a0
    800023d2:	892e                	mv	s2,a1
    struct proc *p = myproc();
    800023d4:	fffff097          	auipc	ra,0xfffff
    800023d8:	5f4080e7          	jalr	1524(ra) # 800019c8 <myproc>
    800023dc:	84aa                	mv	s1,a0
    // Once we hold p->lock, we can be
    // guaranteed that we won't miss any wakeup
    // (wakeup locks p->lock),
    // so it's okay to release lk.

    acquire(&p->lock);  //DOC: sleeplock1
    800023de:	fffff097          	auipc	ra,0xfffff
    800023e2:	806080e7          	jalr	-2042(ra) # 80000be4 <acquire>
    release(lk);
    800023e6:	854a                	mv	a0,s2
    800023e8:	fffff097          	auipc	ra,0xfffff
    800023ec:	8b0080e7          	jalr	-1872(ra) # 80000c98 <release>


    p->running_time = p->running_time + ticks - p->last_time_changed;
    800023f0:	00007717          	auipc	a4,0x7
    800023f4:	c6072703          	lw	a4,-928(a4) # 80009050 <ticks>
    800023f8:	48fc                	lw	a5,84(s1)
    800023fa:	9fb9                	addw	a5,a5,a4
    800023fc:	4cb4                	lw	a3,88(s1)
    800023fe:	9f95                	subw	a5,a5,a3
    80002400:	c8fc                	sw	a5,84(s1)
    p->last_time_changed = ticks;      //setting the starting ticks when getting to runnable for section 4
    80002402:	ccb8                	sw	a4,88(s1)

    // Go to sleep.
    p->chan = chan;
    80002404:	0334b023          	sd	s3,32(s1)
    p->state = SLEEPING;
    80002408:	4789                	li	a5,2
    8000240a:	cc9c                	sw	a5,24(s1)

    sched();
    8000240c:	00000097          	auipc	ra,0x0
    80002410:	e8c080e7          	jalr	-372(ra) # 80002298 <sched>

    // Tidy up.
    p->chan = 0;
    80002414:	0204b023          	sd	zero,32(s1)

    // Reacquire original lock.
    release(&p->lock);
    80002418:	8526                	mv	a0,s1
    8000241a:	fffff097          	auipc	ra,0xfffff
    8000241e:	87e080e7          	jalr	-1922(ra) # 80000c98 <release>
    acquire(lk);
    80002422:	854a                	mv	a0,s2
    80002424:	ffffe097          	auipc	ra,0xffffe
    80002428:	7c0080e7          	jalr	1984(ra) # 80000be4 <acquire>
}
    8000242c:	70a2                	ld	ra,40(sp)
    8000242e:	7402                	ld	s0,32(sp)
    80002430:	64e2                	ld	s1,24(sp)
    80002432:	6942                	ld	s2,16(sp)
    80002434:	69a2                	ld	s3,8(sp)
    80002436:	6145                	addi	sp,sp,48
    80002438:	8082                	ret

000000008000243a <wait>:
wait(uint64 addr) {
    8000243a:	715d                	addi	sp,sp,-80
    8000243c:	e486                	sd	ra,72(sp)
    8000243e:	e0a2                	sd	s0,64(sp)
    80002440:	fc26                	sd	s1,56(sp)
    80002442:	f84a                	sd	s2,48(sp)
    80002444:	f44e                	sd	s3,40(sp)
    80002446:	f052                	sd	s4,32(sp)
    80002448:	ec56                	sd	s5,24(sp)
    8000244a:	e85a                	sd	s6,16(sp)
    8000244c:	e45e                	sd	s7,8(sp)
    8000244e:	e062                	sd	s8,0(sp)
    80002450:	0880                	addi	s0,sp,80
    80002452:	8b2a                	mv	s6,a0
    struct proc *p = myproc();
    80002454:	fffff097          	auipc	ra,0xfffff
    80002458:	574080e7          	jalr	1396(ra) # 800019c8 <myproc>
    8000245c:	892a                	mv	s2,a0
    acquire(&wait_lock);
    8000245e:	0000f517          	auipc	a0,0xf
    80002462:	e7a50513          	addi	a0,a0,-390 # 800112d8 <wait_lock>
    80002466:	ffffe097          	auipc	ra,0xffffe
    8000246a:	77e080e7          	jalr	1918(ra) # 80000be4 <acquire>
        havekids = 0;
    8000246e:	4b81                	li	s7,0
                if (np->state == ZOMBIE) {
    80002470:	4a15                	li	s4,5
        for (np = proc; np < &proc[NPROC]; np++) {
    80002472:	00015997          	auipc	s3,0x15
    80002476:	47e98993          	addi	s3,s3,1150 # 800178f0 <tickslock>
                havekids = 1;
    8000247a:	4a85                	li	s5,1
        sleep(p, &wait_lock);  //DOC: wait-sleep
    8000247c:	0000fc17          	auipc	s8,0xf
    80002480:	e5cc0c13          	addi	s8,s8,-420 # 800112d8 <wait_lock>
        havekids = 0;
    80002484:	875e                	mv	a4,s7
        for (np = proc; np < &proc[NPROC]; np++) {
    80002486:	0000f497          	auipc	s1,0xf
    8000248a:	26a48493          	addi	s1,s1,618 # 800116f0 <proc>
    8000248e:	a0bd                	j	800024fc <wait+0xc2>
                    pid = np->pid;
    80002490:	0304a983          	lw	s3,48(s1)
                    if (addr != 0 && copyout(p->pagetable, addr, (char *) &np->xstate,
    80002494:	000b0e63          	beqz	s6,800024b0 <wait+0x76>
    80002498:	4691                	li	a3,4
    8000249a:	02c48613          	addi	a2,s1,44
    8000249e:	85da                	mv	a1,s6
    800024a0:	07093503          	ld	a0,112(s2)
    800024a4:	fffff097          	auipc	ra,0xfffff
    800024a8:	1d6080e7          	jalr	470(ra) # 8000167a <copyout>
    800024ac:	02054563          	bltz	a0,800024d6 <wait+0x9c>
                    freeproc(np);
    800024b0:	8526                	mv	a0,s1
    800024b2:	fffff097          	auipc	ra,0xfffff
    800024b6:	6c8080e7          	jalr	1736(ra) # 80001b7a <freeproc>
                    release(&np->lock);
    800024ba:	8526                	mv	a0,s1
    800024bc:	ffffe097          	auipc	ra,0xffffe
    800024c0:	7dc080e7          	jalr	2012(ra) # 80000c98 <release>
                    release(&wait_lock);
    800024c4:	0000f517          	auipc	a0,0xf
    800024c8:	e1450513          	addi	a0,a0,-492 # 800112d8 <wait_lock>
    800024cc:	ffffe097          	auipc	ra,0xffffe
    800024d0:	7cc080e7          	jalr	1996(ra) # 80000c98 <release>
                    return pid;
    800024d4:	a09d                	j	8000253a <wait+0x100>
                        release(&np->lock);
    800024d6:	8526                	mv	a0,s1
    800024d8:	ffffe097          	auipc	ra,0xffffe
    800024dc:	7c0080e7          	jalr	1984(ra) # 80000c98 <release>
                        release(&wait_lock);
    800024e0:	0000f517          	auipc	a0,0xf
    800024e4:	df850513          	addi	a0,a0,-520 # 800112d8 <wait_lock>
    800024e8:	ffffe097          	auipc	ra,0xffffe
    800024ec:	7b0080e7          	jalr	1968(ra) # 80000c98 <release>
                        return -1;
    800024f0:	59fd                	li	s3,-1
    800024f2:	a0a1                	j	8000253a <wait+0x100>
        for (np = proc; np < &proc[NPROC]; np++) {
    800024f4:	18848493          	addi	s1,s1,392
    800024f8:	03348463          	beq	s1,s3,80002520 <wait+0xe6>
            if (np->parent == p) {
    800024fc:	7c9c                	ld	a5,56(s1)
    800024fe:	ff279be3          	bne	a5,s2,800024f4 <wait+0xba>
                acquire(&np->lock);
    80002502:	8526                	mv	a0,s1
    80002504:	ffffe097          	auipc	ra,0xffffe
    80002508:	6e0080e7          	jalr	1760(ra) # 80000be4 <acquire>
                if (np->state == ZOMBIE) {
    8000250c:	4c9c                	lw	a5,24(s1)
    8000250e:	f94781e3          	beq	a5,s4,80002490 <wait+0x56>
                release(&np->lock);
    80002512:	8526                	mv	a0,s1
    80002514:	ffffe097          	auipc	ra,0xffffe
    80002518:	784080e7          	jalr	1924(ra) # 80000c98 <release>
                havekids = 1;
    8000251c:	8756                	mv	a4,s5
    8000251e:	bfd9                	j	800024f4 <wait+0xba>
        if (!havekids || p->killed) {
    80002520:	c701                	beqz	a4,80002528 <wait+0xee>
    80002522:	02892783          	lw	a5,40(s2)
    80002526:	c79d                	beqz	a5,80002554 <wait+0x11a>
            release(&wait_lock);
    80002528:	0000f517          	auipc	a0,0xf
    8000252c:	db050513          	addi	a0,a0,-592 # 800112d8 <wait_lock>
    80002530:	ffffe097          	auipc	ra,0xffffe
    80002534:	768080e7          	jalr	1896(ra) # 80000c98 <release>
            return -1;
    80002538:	59fd                	li	s3,-1
}
    8000253a:	854e                	mv	a0,s3
    8000253c:	60a6                	ld	ra,72(sp)
    8000253e:	6406                	ld	s0,64(sp)
    80002540:	74e2                	ld	s1,56(sp)
    80002542:	7942                	ld	s2,48(sp)
    80002544:	79a2                	ld	s3,40(sp)
    80002546:	7a02                	ld	s4,32(sp)
    80002548:	6ae2                	ld	s5,24(sp)
    8000254a:	6b42                	ld	s6,16(sp)
    8000254c:	6ba2                	ld	s7,8(sp)
    8000254e:	6c02                	ld	s8,0(sp)
    80002550:	6161                	addi	sp,sp,80
    80002552:	8082                	ret
        sleep(p, &wait_lock);  //DOC: wait-sleep
    80002554:	85e2                	mv	a1,s8
    80002556:	854a                	mv	a0,s2
    80002558:	00000097          	auipc	ra,0x0
    8000255c:	e6a080e7          	jalr	-406(ra) # 800023c2 <sleep>
        havekids = 0;
    80002560:	b715                	j	80002484 <wait+0x4a>

0000000080002562 <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void
wakeup(void *chan) {
    80002562:	7139                	addi	sp,sp,-64
    80002564:	fc06                	sd	ra,56(sp)
    80002566:	f822                	sd	s0,48(sp)
    80002568:	f426                	sd	s1,40(sp)
    8000256a:	f04a                	sd	s2,32(sp)
    8000256c:	ec4e                	sd	s3,24(sp)
    8000256e:	e852                	sd	s4,16(sp)
    80002570:	e456                	sd	s5,8(sp)
    80002572:	e05a                	sd	s6,0(sp)
    80002574:	0080                	addi	s0,sp,64
    80002576:	8a2a                	mv	s4,a0
    struct proc *p;

    for (p = proc; p < &proc[NPROC]; p++) {
    80002578:	0000f497          	auipc	s1,0xf
    8000257c:	17848493          	addi	s1,s1,376 # 800116f0 <proc>
        if (p != myproc()) {
            acquire(&p->lock);
            if (p->state == SLEEPING && p->chan == chan) {
    80002580:	4989                	li	s3,2
                p->state = RUNNABLE;
    80002582:	4b0d                	li	s6,3

                p->sleeping_time = p->sleeping_time + ticks - p->last_time_changed;
    80002584:	00007a97          	auipc	s5,0x7
    80002588:	acca8a93          	addi	s5,s5,-1332 # 80009050 <ticks>
    for (p = proc; p < &proc[NPROC]; p++) {
    8000258c:	00015917          	auipc	s2,0x15
    80002590:	36490913          	addi	s2,s2,868 # 800178f0 <tickslock>
    80002594:	a035                	j	800025c0 <wakeup+0x5e>
                p->state = RUNNABLE;
    80002596:	0164ac23          	sw	s6,24(s1)
                p->sleeping_time = p->sleeping_time + ticks - p->last_time_changed;
    8000259a:	000aa783          	lw	a5,0(s5)
    8000259e:	44f8                	lw	a4,76(s1)
    800025a0:	9f3d                	addw	a4,a4,a5
    800025a2:	4cb4                	lw	a3,88(s1)
    800025a4:	9f15                	subw	a4,a4,a3
    800025a6:	c4f8                	sw	a4,76(s1)
                p->last_runnable_time = ticks;     //added last_runnable time for fcfs
    800025a8:	2781                	sext.w	a5,a5
    800025aa:	c4bc                	sw	a5,72(s1)
                p->last_time_changed = ticks;      //setting the starting ticks when getting to runnable for section 4
    800025ac:	ccbc                	sw	a5,88(s1)

            }
            release(&p->lock);
    800025ae:	8526                	mv	a0,s1
    800025b0:	ffffe097          	auipc	ra,0xffffe
    800025b4:	6e8080e7          	jalr	1768(ra) # 80000c98 <release>
    for (p = proc; p < &proc[NPROC]; p++) {
    800025b8:	18848493          	addi	s1,s1,392
    800025bc:	03248463          	beq	s1,s2,800025e4 <wakeup+0x82>
        if (p != myproc()) {
    800025c0:	fffff097          	auipc	ra,0xfffff
    800025c4:	408080e7          	jalr	1032(ra) # 800019c8 <myproc>
    800025c8:	fea488e3          	beq	s1,a0,800025b8 <wakeup+0x56>
            acquire(&p->lock);
    800025cc:	8526                	mv	a0,s1
    800025ce:	ffffe097          	auipc	ra,0xffffe
    800025d2:	616080e7          	jalr	1558(ra) # 80000be4 <acquire>
            if (p->state == SLEEPING && p->chan == chan) {
    800025d6:	4c9c                	lw	a5,24(s1)
    800025d8:	fd379be3          	bne	a5,s3,800025ae <wakeup+0x4c>
    800025dc:	709c                	ld	a5,32(s1)
    800025de:	fd4798e3          	bne	a5,s4,800025ae <wakeup+0x4c>
    800025e2:	bf55                	j	80002596 <wakeup+0x34>
        }
    }
}
    800025e4:	70e2                	ld	ra,56(sp)
    800025e6:	7442                	ld	s0,48(sp)
    800025e8:	74a2                	ld	s1,40(sp)
    800025ea:	7902                	ld	s2,32(sp)
    800025ec:	69e2                	ld	s3,24(sp)
    800025ee:	6a42                	ld	s4,16(sp)
    800025f0:	6aa2                	ld	s5,8(sp)
    800025f2:	6b02                	ld	s6,0(sp)
    800025f4:	6121                	addi	sp,sp,64
    800025f6:	8082                	ret

00000000800025f8 <reparent>:
reparent(struct proc *p) {
    800025f8:	7179                	addi	sp,sp,-48
    800025fa:	f406                	sd	ra,40(sp)
    800025fc:	f022                	sd	s0,32(sp)
    800025fe:	ec26                	sd	s1,24(sp)
    80002600:	e84a                	sd	s2,16(sp)
    80002602:	e44e                	sd	s3,8(sp)
    80002604:	e052                	sd	s4,0(sp)
    80002606:	1800                	addi	s0,sp,48
    80002608:	892a                	mv	s2,a0
    for (pp = proc; pp < &proc[NPROC]; pp++) {
    8000260a:	0000f497          	auipc	s1,0xf
    8000260e:	0e648493          	addi	s1,s1,230 # 800116f0 <proc>
            pp->parent = initproc;
    80002612:	00007a17          	auipc	s4,0x7
    80002616:	a36a0a13          	addi	s4,s4,-1482 # 80009048 <initproc>
    for (pp = proc; pp < &proc[NPROC]; pp++) {
    8000261a:	00015997          	auipc	s3,0x15
    8000261e:	2d698993          	addi	s3,s3,726 # 800178f0 <tickslock>
    80002622:	a029                	j	8000262c <reparent+0x34>
    80002624:	18848493          	addi	s1,s1,392
    80002628:	01348d63          	beq	s1,s3,80002642 <reparent+0x4a>
        if (pp->parent == p) {
    8000262c:	7c9c                	ld	a5,56(s1)
    8000262e:	ff279be3          	bne	a5,s2,80002624 <reparent+0x2c>
            pp->parent = initproc;
    80002632:	000a3503          	ld	a0,0(s4)
    80002636:	fc88                	sd	a0,56(s1)
            wakeup(initproc);
    80002638:	00000097          	auipc	ra,0x0
    8000263c:	f2a080e7          	jalr	-214(ra) # 80002562 <wakeup>
    80002640:	b7d5                	j	80002624 <reparent+0x2c>
}
    80002642:	70a2                	ld	ra,40(sp)
    80002644:	7402                	ld	s0,32(sp)
    80002646:	64e2                	ld	s1,24(sp)
    80002648:	6942                	ld	s2,16(sp)
    8000264a:	69a2                	ld	s3,8(sp)
    8000264c:	6a02                	ld	s4,0(sp)
    8000264e:	6145                	addi	sp,sp,48
    80002650:	8082                	ret

0000000080002652 <exit>:
exit(int status) {
    80002652:	7179                	addi	sp,sp,-48
    80002654:	f406                	sd	ra,40(sp)
    80002656:	f022                	sd	s0,32(sp)
    80002658:	ec26                	sd	s1,24(sp)
    8000265a:	e84a                	sd	s2,16(sp)
    8000265c:	e44e                	sd	s3,8(sp)
    8000265e:	e052                	sd	s4,0(sp)
    80002660:	1800                	addi	s0,sp,48
    80002662:	8a2a                	mv	s4,a0
    struct proc *p = myproc();
    80002664:	fffff097          	auipc	ra,0xfffff
    80002668:	364080e7          	jalr	868(ra) # 800019c8 <myproc>
    8000266c:	892a                	mv	s2,a0
    if (p == initproc)
    8000266e:	00007797          	auipc	a5,0x7
    80002672:	9da7b783          	ld	a5,-1574(a5) # 80009048 <initproc>
    80002676:	0f050493          	addi	s1,a0,240
    8000267a:	17050993          	addi	s3,a0,368
    8000267e:	02a79363          	bne	a5,a0,800026a4 <exit+0x52>
        panic("init exiting");
    80002682:	00006517          	auipc	a0,0x6
    80002686:	c2e50513          	addi	a0,a0,-978 # 800082b0 <digits+0x270>
    8000268a:	ffffe097          	auipc	ra,0xffffe
    8000268e:	eb4080e7          	jalr	-332(ra) # 8000053e <panic>
            fileclose(f);
    80002692:	00002097          	auipc	ra,0x2
    80002696:	300080e7          	jalr	768(ra) # 80004992 <fileclose>
            p->ofile[fd] = 0;
    8000269a:	0004b023          	sd	zero,0(s1)
    for (int fd = 0; fd < NOFILE; fd++) {
    8000269e:	04a1                	addi	s1,s1,8
    800026a0:	01348563          	beq	s1,s3,800026aa <exit+0x58>
        if (p->ofile[fd]) {
    800026a4:	6088                	ld	a0,0(s1)
    800026a6:	f575                	bnez	a0,80002692 <exit+0x40>
    800026a8:	bfdd                	j	8000269e <exit+0x4c>
    begin_op();
    800026aa:	00002097          	auipc	ra,0x2
    800026ae:	e1c080e7          	jalr	-484(ra) # 800044c6 <begin_op>
    iput(p->cwd);
    800026b2:	17093503          	ld	a0,368(s2)
    800026b6:	00001097          	auipc	ra,0x1
    800026ba:	5f8080e7          	jalr	1528(ra) # 80003cae <iput>
    end_op();
    800026be:	00002097          	auipc	ra,0x2
    800026c2:	e88080e7          	jalr	-376(ra) # 80004546 <end_op>
    p->cwd = 0;
    800026c6:	16093823          	sd	zero,368(s2)
    acquire(&wait_lock);
    800026ca:	0000f497          	auipc	s1,0xf
    800026ce:	c0e48493          	addi	s1,s1,-1010 # 800112d8 <wait_lock>
    800026d2:	8526                	mv	a0,s1
    800026d4:	ffffe097          	auipc	ra,0xffffe
    800026d8:	510080e7          	jalr	1296(ra) # 80000be4 <acquire>
    reparent(p);
    800026dc:	854a                	mv	a0,s2
    800026de:	00000097          	auipc	ra,0x0
    800026e2:	f1a080e7          	jalr	-230(ra) # 800025f8 <reparent>
    wakeup(p->parent);
    800026e6:	03893503          	ld	a0,56(s2)
    800026ea:	00000097          	auipc	ra,0x0
    800026ee:	e78080e7          	jalr	-392(ra) # 80002562 <wakeup>
    acquire(&p->lock);
    800026f2:	854a                	mv	a0,s2
    800026f4:	ffffe097          	auipc	ra,0xffffe
    800026f8:	4f0080e7          	jalr	1264(ra) # 80000be4 <acquire>
    p->running_time = p->running_time + ticks - p->last_time_changed;
    800026fc:	00007617          	auipc	a2,0x7
    80002700:	95462603          	lw	a2,-1708(a2) # 80009050 <ticks>
    80002704:	05492703          	lw	a4,84(s2)
    80002708:	9f31                	addw	a4,a4,a2
    8000270a:	05892683          	lw	a3,88(s2)
    8000270e:	40d706bb          	subw	a3,a4,a3
    80002712:	04d92a23          	sw	a3,84(s2)
    program_time = program_time + p->running_time;
    80002716:	00007717          	auipc	a4,0x7
    8000271a:	91a70713          	addi	a4,a4,-1766 # 80009030 <program_time>
    8000271e:	431c                	lw	a5,0(a4)
    80002720:	9fb5                	addw	a5,a5,a3
    80002722:	c31c                	sw	a5,0(a4)
    cpu_utilization = program_time / (ticks - start_time);
    80002724:	00007717          	auipc	a4,0x7
    80002728:	90472703          	lw	a4,-1788(a4) # 80009028 <start_time>
    8000272c:	9e19                	subw	a2,a2,a4
    8000272e:	02c7d7bb          	divuw	a5,a5,a2
    80002732:	00007717          	auipc	a4,0x7
    80002736:	8ef72d23          	sw	a5,-1798(a4) # 8000902c <cpu_utilization>
    sleeping_processes_mean = (sleeping_processes_mean * (nextpid - 1) + p->sleeping_time) / (nextpid);
    8000273a:	00006617          	auipc	a2,0x6
    8000273e:	13a62603          	lw	a2,314(a2) # 80008874 <nextpid>
    80002742:	fff6059b          	addiw	a1,a2,-1
    80002746:	00007797          	auipc	a5,0x7
    8000274a:	8f678793          	addi	a5,a5,-1802 # 8000903c <sleeping_processes_mean>
    8000274e:	4398                	lw	a4,0(a5)
    80002750:	02b7073b          	mulw	a4,a4,a1
    80002754:	04c92503          	lw	a0,76(s2)
    80002758:	9f29                	addw	a4,a4,a0
    8000275a:	02c7473b          	divw	a4,a4,a2
    8000275e:	c398                	sw	a4,0(a5)
    running_processes_mean = (running_processes_mean * (nextpid - 1) + p->running_time) / (nextpid);
    80002760:	00007797          	auipc	a5,0x7
    80002764:	8d878793          	addi	a5,a5,-1832 # 80009038 <running_processes_mean>
    80002768:	4398                	lw	a4,0(a5)
    8000276a:	02b7073b          	mulw	a4,a4,a1
    8000276e:	9f35                	addw	a4,a4,a3
    80002770:	02c7473b          	divw	a4,a4,a2
    80002774:	c398                	sw	a4,0(a5)
    runnable_processes_mean = (runnable_processes_mean * (nextpid - 1) + p->runnable_time) / (nextpid);
    80002776:	00007717          	auipc	a4,0x7
    8000277a:	8be70713          	addi	a4,a4,-1858 # 80009034 <runnable_processes_mean>
    8000277e:	431c                	lw	a5,0(a4)
    80002780:	02b787bb          	mulw	a5,a5,a1
    80002784:	05092683          	lw	a3,80(s2)
    80002788:	9fb5                	addw	a5,a5,a3
    8000278a:	02c7c7bb          	divw	a5,a5,a2
    8000278e:	c31c                	sw	a5,0(a4)
    p->xstate = status;
    80002790:	03492623          	sw	s4,44(s2)
    p->state = ZOMBIE;
    80002794:	4795                	li	a5,5
    80002796:	00f92c23          	sw	a5,24(s2)
    release(&wait_lock);
    8000279a:	8526                	mv	a0,s1
    8000279c:	ffffe097          	auipc	ra,0xffffe
    800027a0:	4fc080e7          	jalr	1276(ra) # 80000c98 <release>
    sched();
    800027a4:	00000097          	auipc	ra,0x0
    800027a8:	af4080e7          	jalr	-1292(ra) # 80002298 <sched>
    panic("zombie exit");
    800027ac:	00006517          	auipc	a0,0x6
    800027b0:	b1450513          	addi	a0,a0,-1260 # 800082c0 <digits+0x280>
    800027b4:	ffffe097          	auipc	ra,0xffffe
    800027b8:	d8a080e7          	jalr	-630(ra) # 8000053e <panic>

00000000800027bc <kill>:

// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid) {
    800027bc:	7179                	addi	sp,sp,-48
    800027be:	f406                	sd	ra,40(sp)
    800027c0:	f022                	sd	s0,32(sp)
    800027c2:	ec26                	sd	s1,24(sp)
    800027c4:	e84a                	sd	s2,16(sp)
    800027c6:	e44e                	sd	s3,8(sp)
    800027c8:	1800                	addi	s0,sp,48
    800027ca:	892a                	mv	s2,a0
    struct proc *p;

    for (p = proc; p < &proc[NPROC]; p++) {
    800027cc:	0000f497          	auipc	s1,0xf
    800027d0:	f2448493          	addi	s1,s1,-220 # 800116f0 <proc>
    800027d4:	00015997          	auipc	s3,0x15
    800027d8:	11c98993          	addi	s3,s3,284 # 800178f0 <tickslock>
        acquire(&p->lock);
    800027dc:	8526                	mv	a0,s1
    800027de:	ffffe097          	auipc	ra,0xffffe
    800027e2:	406080e7          	jalr	1030(ra) # 80000be4 <acquire>
        if (p->pid == pid) {
    800027e6:	589c                	lw	a5,48(s1)
    800027e8:	01278d63          	beq	a5,s2,80002802 <kill+0x46>
                p->last_time_changed = ticks;      //setting the starting ticks when getting to runnable for section 4
            }
            release(&p->lock);
            return 0;
        }
        release(&p->lock);
    800027ec:	8526                	mv	a0,s1
    800027ee:	ffffe097          	auipc	ra,0xffffe
    800027f2:	4aa080e7          	jalr	1194(ra) # 80000c98 <release>
    for (p = proc; p < &proc[NPROC]; p++) {
    800027f6:	18848493          	addi	s1,s1,392
    800027fa:	ff3491e3          	bne	s1,s3,800027dc <kill+0x20>
    }
    return -1;
    800027fe:	557d                	li	a0,-1
    80002800:	a829                	j	8000281a <kill+0x5e>
            p->killed = 1;
    80002802:	4785                	li	a5,1
    80002804:	d49c                	sw	a5,40(s1)
            if (p->state == SLEEPING) {
    80002806:	4c98                	lw	a4,24(s1)
    80002808:	4789                	li	a5,2
    8000280a:	00f70f63          	beq	a4,a5,80002828 <kill+0x6c>
            release(&p->lock);
    8000280e:	8526                	mv	a0,s1
    80002810:	ffffe097          	auipc	ra,0xffffe
    80002814:	488080e7          	jalr	1160(ra) # 80000c98 <release>
            return 0;
    80002818:	4501                	li	a0,0
}
    8000281a:	70a2                	ld	ra,40(sp)
    8000281c:	7402                	ld	s0,32(sp)
    8000281e:	64e2                	ld	s1,24(sp)
    80002820:	6942                	ld	s2,16(sp)
    80002822:	69a2                	ld	s3,8(sp)
    80002824:	6145                	addi	sp,sp,48
    80002826:	8082                	ret
                p->state = RUNNABLE;
    80002828:	478d                	li	a5,3
    8000282a:	cc9c                	sw	a5,24(s1)
                p->sleeping_time = p->sleeping_time + ticks - p->last_time_changed;
    8000282c:	00007797          	auipc	a5,0x7
    80002830:	8247a783          	lw	a5,-2012(a5) # 80009050 <ticks>
    80002834:	44f8                	lw	a4,76(s1)
    80002836:	9f3d                	addw	a4,a4,a5
    80002838:	4cb4                	lw	a3,88(s1)
    8000283a:	9f15                	subw	a4,a4,a3
    8000283c:	c4f8                	sw	a4,76(s1)
                p->last_runnable_time = ticks;     //added last_runnable time for fcfs
    8000283e:	2781                	sext.w	a5,a5
    80002840:	c4bc                	sw	a5,72(s1)
                p->last_time_changed = ticks;      //setting the starting ticks when getting to runnable for section 4
    80002842:	ccbc                	sw	a5,88(s1)
    80002844:	b7e9                	j	8000280e <kill+0x52>

0000000080002846 <kill_system>:

int kill_system(void) {
    80002846:	7179                	addi	sp,sp,-48
    80002848:	f406                	sd	ra,40(sp)
    8000284a:	f022                	sd	s0,32(sp)
    8000284c:	ec26                	sd	s1,24(sp)
    8000284e:	e84a                	sd	s2,16(sp)
    80002850:	e44e                	sd	s3,8(sp)
    80002852:	1800                	addi	s0,sp,48
    // init pid = 1
    // shell pid = 2
    struct proc *p;
    int i = 0;
    for (p = proc; p < &proc[NPROC]; p++, i++) {
    80002854:	0000f497          	auipc	s1,0xf
    80002858:	e9c48493          	addi	s1,s1,-356 # 800116f0 <proc>
        acquire(&p->lock);
        if (p->pid != 1 && p->pid != 2) {
    8000285c:	4985                	li	s3,1
    for (p = proc; p < &proc[NPROC]; p++, i++) {
    8000285e:	00015917          	auipc	s2,0x15
    80002862:	09290913          	addi	s2,s2,146 # 800178f0 <tickslock>
    80002866:	a811                	j	8000287a <kill_system+0x34>
            release(&p->lock);
            kill(p->pid);
        } else {
            release(&p->lock);
    80002868:	8526                	mv	a0,s1
    8000286a:	ffffe097          	auipc	ra,0xffffe
    8000286e:	42e080e7          	jalr	1070(ra) # 80000c98 <release>
    for (p = proc; p < &proc[NPROC]; p++, i++) {
    80002872:	18848493          	addi	s1,s1,392
    80002876:	03248663          	beq	s1,s2,800028a2 <kill_system+0x5c>
        acquire(&p->lock);
    8000287a:	8526                	mv	a0,s1
    8000287c:	ffffe097          	auipc	ra,0xffffe
    80002880:	368080e7          	jalr	872(ra) # 80000be4 <acquire>
        if (p->pid != 1 && p->pid != 2) {
    80002884:	589c                	lw	a5,48(s1)
    80002886:	37fd                	addiw	a5,a5,-1
    80002888:	fef9f0e3          	bgeu	s3,a5,80002868 <kill_system+0x22>
            release(&p->lock);
    8000288c:	8526                	mv	a0,s1
    8000288e:	ffffe097          	auipc	ra,0xffffe
    80002892:	40a080e7          	jalr	1034(ra) # 80000c98 <release>
            kill(p->pid);
    80002896:	5888                	lw	a0,48(s1)
    80002898:	00000097          	auipc	ra,0x0
    8000289c:	f24080e7          	jalr	-220(ra) # 800027bc <kill>
    800028a0:	bfc9                	j	80002872 <kill_system+0x2c>
        }
    }

    return 0;
    //todo check if need to verify kill returned 0, in case not what should we do.
}
    800028a2:	4501                	li	a0,0
    800028a4:	70a2                	ld	ra,40(sp)
    800028a6:	7402                	ld	s0,32(sp)
    800028a8:	64e2                	ld	s1,24(sp)
    800028aa:	6942                	ld	s2,16(sp)
    800028ac:	69a2                	ld	s3,8(sp)
    800028ae:	6145                	addi	sp,sp,48
    800028b0:	8082                	ret

00000000800028b2 <pause_system>:

//pause all user processes for the number of seconds specified by the parameter
int pause_system(int seconds) {
    800028b2:	1141                	addi	sp,sp,-16
    800028b4:	e406                	sd	ra,8(sp)
    800028b6:	e022                	sd	s0,0(sp)
    800028b8:	0800                	addi	s0,sp,16
    pauseTicks = ticks + seconds * 10; //todo check if can get 1000000 as number
    800028ba:	0025179b          	slliw	a5,a0,0x2
    800028be:	9fa9                	addw	a5,a5,a0
    800028c0:	0017979b          	slliw	a5,a5,0x1
    800028c4:	00006517          	auipc	a0,0x6
    800028c8:	78c52503          	lw	a0,1932(a0) # 80009050 <ticks>
    800028cc:	9fa9                	addw	a5,a5,a0
    800028ce:	00006717          	auipc	a4,0x6
    800028d2:	76f72923          	sw	a5,1906(a4) # 80009040 <pauseTicks>
    yield();
    800028d6:	00000097          	auipc	ra,0x0
    800028da:	a98080e7          	jalr	-1384(ra) # 8000236e <yield>
    return 0;
}
    800028de:	4501                	li	a0,0
    800028e0:	60a2                	ld	ra,8(sp)
    800028e2:	6402                	ld	s0,0(sp)
    800028e4:	0141                	addi	sp,sp,16
    800028e6:	8082                	ret

00000000800028e8 <either_copyout>:

// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len) {
    800028e8:	7179                	addi	sp,sp,-48
    800028ea:	f406                	sd	ra,40(sp)
    800028ec:	f022                	sd	s0,32(sp)
    800028ee:	ec26                	sd	s1,24(sp)
    800028f0:	e84a                	sd	s2,16(sp)
    800028f2:	e44e                	sd	s3,8(sp)
    800028f4:	e052                	sd	s4,0(sp)
    800028f6:	1800                	addi	s0,sp,48
    800028f8:	84aa                	mv	s1,a0
    800028fa:	892e                	mv	s2,a1
    800028fc:	89b2                	mv	s3,a2
    800028fe:	8a36                	mv	s4,a3
    struct proc *p = myproc();
    80002900:	fffff097          	auipc	ra,0xfffff
    80002904:	0c8080e7          	jalr	200(ra) # 800019c8 <myproc>
    if (user_dst) {
    80002908:	c08d                	beqz	s1,8000292a <either_copyout+0x42>
        return copyout(p->pagetable, dst, src, len);
    8000290a:	86d2                	mv	a3,s4
    8000290c:	864e                	mv	a2,s3
    8000290e:	85ca                	mv	a1,s2
    80002910:	7928                	ld	a0,112(a0)
    80002912:	fffff097          	auipc	ra,0xfffff
    80002916:	d68080e7          	jalr	-664(ra) # 8000167a <copyout>
    } else {
        memmove((char *) dst, src, len);
        return 0;
    }
}
    8000291a:	70a2                	ld	ra,40(sp)
    8000291c:	7402                	ld	s0,32(sp)
    8000291e:	64e2                	ld	s1,24(sp)
    80002920:	6942                	ld	s2,16(sp)
    80002922:	69a2                	ld	s3,8(sp)
    80002924:	6a02                	ld	s4,0(sp)
    80002926:	6145                	addi	sp,sp,48
    80002928:	8082                	ret
        memmove((char *) dst, src, len);
    8000292a:	000a061b          	sext.w	a2,s4
    8000292e:	85ce                	mv	a1,s3
    80002930:	854a                	mv	a0,s2
    80002932:	ffffe097          	auipc	ra,0xffffe
    80002936:	40e080e7          	jalr	1038(ra) # 80000d40 <memmove>
        return 0;
    8000293a:	8526                	mv	a0,s1
    8000293c:	bff9                	j	8000291a <either_copyout+0x32>

000000008000293e <either_copyin>:

// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len) {
    8000293e:	7179                	addi	sp,sp,-48
    80002940:	f406                	sd	ra,40(sp)
    80002942:	f022                	sd	s0,32(sp)
    80002944:	ec26                	sd	s1,24(sp)
    80002946:	e84a                	sd	s2,16(sp)
    80002948:	e44e                	sd	s3,8(sp)
    8000294a:	e052                	sd	s4,0(sp)
    8000294c:	1800                	addi	s0,sp,48
    8000294e:	892a                	mv	s2,a0
    80002950:	84ae                	mv	s1,a1
    80002952:	89b2                	mv	s3,a2
    80002954:	8a36                	mv	s4,a3
    struct proc *p = myproc();
    80002956:	fffff097          	auipc	ra,0xfffff
    8000295a:	072080e7          	jalr	114(ra) # 800019c8 <myproc>
    if (user_src) {
    8000295e:	c08d                	beqz	s1,80002980 <either_copyin+0x42>
        return copyin(p->pagetable, dst, src, len);
    80002960:	86d2                	mv	a3,s4
    80002962:	864e                	mv	a2,s3
    80002964:	85ca                	mv	a1,s2
    80002966:	7928                	ld	a0,112(a0)
    80002968:	fffff097          	auipc	ra,0xfffff
    8000296c:	d9e080e7          	jalr	-610(ra) # 80001706 <copyin>
    } else {
        memmove(dst, (char *) src, len);
        return 0;
    }
}
    80002970:	70a2                	ld	ra,40(sp)
    80002972:	7402                	ld	s0,32(sp)
    80002974:	64e2                	ld	s1,24(sp)
    80002976:	6942                	ld	s2,16(sp)
    80002978:	69a2                	ld	s3,8(sp)
    8000297a:	6a02                	ld	s4,0(sp)
    8000297c:	6145                	addi	sp,sp,48
    8000297e:	8082                	ret
        memmove(dst, (char *) src, len);
    80002980:	000a061b          	sext.w	a2,s4
    80002984:	85ce                	mv	a1,s3
    80002986:	854a                	mv	a0,s2
    80002988:	ffffe097          	auipc	ra,0xffffe
    8000298c:	3b8080e7          	jalr	952(ra) # 80000d40 <memmove>
        return 0;
    80002990:	8526                	mv	a0,s1
    80002992:	bff9                	j	80002970 <either_copyin+0x32>

0000000080002994 <procdump>:

// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void) {
    80002994:	715d                	addi	sp,sp,-80
    80002996:	e486                	sd	ra,72(sp)
    80002998:	e0a2                	sd	s0,64(sp)
    8000299a:	fc26                	sd	s1,56(sp)
    8000299c:	f84a                	sd	s2,48(sp)
    8000299e:	f44e                	sd	s3,40(sp)
    800029a0:	f052                	sd	s4,32(sp)
    800029a2:	ec56                	sd	s5,24(sp)
    800029a4:	e85a                	sd	s6,16(sp)
    800029a6:	e45e                	sd	s7,8(sp)
    800029a8:	0880                	addi	s0,sp,80
            [ZOMBIE]    "zombie"
    };
    struct proc *p;
    char *state;

    printf("\n");
    800029aa:	00005517          	auipc	a0,0x5
    800029ae:	71e50513          	addi	a0,a0,1822 # 800080c8 <digits+0x88>
    800029b2:	ffffe097          	auipc	ra,0xffffe
    800029b6:	bd6080e7          	jalr	-1066(ra) # 80000588 <printf>
    for (p = proc; p < &proc[NPROC]; p++) {
    800029ba:	0000f497          	auipc	s1,0xf
    800029be:	eae48493          	addi	s1,s1,-338 # 80011868 <proc+0x178>
    800029c2:	00015917          	auipc	s2,0x15
    800029c6:	0a690913          	addi	s2,s2,166 # 80017a68 <bcache+0x160>
        if (p->state == UNUSED)
            continue;
        if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800029ca:	4b15                	li	s6,5
            state = states[p->state];
        else
            state = "???";
    800029cc:	00006997          	auipc	s3,0x6
    800029d0:	90498993          	addi	s3,s3,-1788 # 800082d0 <digits+0x290>
        printf("%d %s %s", p->pid, state, p->name);
    800029d4:	00006a97          	auipc	s5,0x6
    800029d8:	904a8a93          	addi	s5,s5,-1788 # 800082d8 <digits+0x298>
        printf("\n");
    800029dc:	00005a17          	auipc	s4,0x5
    800029e0:	6eca0a13          	addi	s4,s4,1772 # 800080c8 <digits+0x88>
        if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800029e4:	00006b97          	auipc	s7,0x6
    800029e8:	92cb8b93          	addi	s7,s7,-1748 # 80008310 <states.1771>
    800029ec:	a00d                	j	80002a0e <procdump+0x7a>
        printf("%d %s %s", p->pid, state, p->name);
    800029ee:	eb86a583          	lw	a1,-328(a3)
    800029f2:	8556                	mv	a0,s5
    800029f4:	ffffe097          	auipc	ra,0xffffe
    800029f8:	b94080e7          	jalr	-1132(ra) # 80000588 <printf>
        printf("\n");
    800029fc:	8552                	mv	a0,s4
    800029fe:	ffffe097          	auipc	ra,0xffffe
    80002a02:	b8a080e7          	jalr	-1142(ra) # 80000588 <printf>
    for (p = proc; p < &proc[NPROC]; p++) {
    80002a06:	18848493          	addi	s1,s1,392
    80002a0a:	03248163          	beq	s1,s2,80002a2c <procdump+0x98>
        if (p->state == UNUSED)
    80002a0e:	86a6                	mv	a3,s1
    80002a10:	ea04a783          	lw	a5,-352(s1)
    80002a14:	dbed                	beqz	a5,80002a06 <procdump+0x72>
            state = "???";
    80002a16:	864e                	mv	a2,s3
        if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002a18:	fcfb6be3          	bltu	s6,a5,800029ee <procdump+0x5a>
    80002a1c:	1782                	slli	a5,a5,0x20
    80002a1e:	9381                	srli	a5,a5,0x20
    80002a20:	078e                	slli	a5,a5,0x3
    80002a22:	97de                	add	a5,a5,s7
    80002a24:	6390                	ld	a2,0(a5)
    80002a26:	f661                	bnez	a2,800029ee <procdump+0x5a>
            state = "???";
    80002a28:	864e                	mv	a2,s3
    80002a2a:	b7d1                	j	800029ee <procdump+0x5a>
    }
    80002a2c:	60a6                	ld	ra,72(sp)
    80002a2e:	6406                	ld	s0,64(sp)
    80002a30:	74e2                	ld	s1,56(sp)
    80002a32:	7942                	ld	s2,48(sp)
    80002a34:	79a2                	ld	s3,40(sp)
    80002a36:	7a02                	ld	s4,32(sp)
    80002a38:	6ae2                	ld	s5,24(sp)
    80002a3a:	6b42                	ld	s6,16(sp)
    80002a3c:	6ba2                	ld	s7,8(sp)
    80002a3e:	6161                	addi	sp,sp,80
    80002a40:	8082                	ret

0000000080002a42 <swtch>:
    80002a42:	00153023          	sd	ra,0(a0)
    80002a46:	00253423          	sd	sp,8(a0)
    80002a4a:	e900                	sd	s0,16(a0)
    80002a4c:	ed04                	sd	s1,24(a0)
    80002a4e:	03253023          	sd	s2,32(a0)
    80002a52:	03353423          	sd	s3,40(a0)
    80002a56:	03453823          	sd	s4,48(a0)
    80002a5a:	03553c23          	sd	s5,56(a0)
    80002a5e:	05653023          	sd	s6,64(a0)
    80002a62:	05753423          	sd	s7,72(a0)
    80002a66:	05853823          	sd	s8,80(a0)
    80002a6a:	05953c23          	sd	s9,88(a0)
    80002a6e:	07a53023          	sd	s10,96(a0)
    80002a72:	07b53423          	sd	s11,104(a0)
    80002a76:	0005b083          	ld	ra,0(a1)
    80002a7a:	0085b103          	ld	sp,8(a1)
    80002a7e:	6980                	ld	s0,16(a1)
    80002a80:	6d84                	ld	s1,24(a1)
    80002a82:	0205b903          	ld	s2,32(a1)
    80002a86:	0285b983          	ld	s3,40(a1)
    80002a8a:	0305ba03          	ld	s4,48(a1)
    80002a8e:	0385ba83          	ld	s5,56(a1)
    80002a92:	0405bb03          	ld	s6,64(a1)
    80002a96:	0485bb83          	ld	s7,72(a1)
    80002a9a:	0505bc03          	ld	s8,80(a1)
    80002a9e:	0585bc83          	ld	s9,88(a1)
    80002aa2:	0605bd03          	ld	s10,96(a1)
    80002aa6:	0685bd83          	ld	s11,104(a1)
    80002aaa:	8082                	ret

0000000080002aac <trapinit>:

extern int devintr();

void
trapinit(void)
{
    80002aac:	1141                	addi	sp,sp,-16
    80002aae:	e406                	sd	ra,8(sp)
    80002ab0:	e022                	sd	s0,0(sp)
    80002ab2:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002ab4:	00006597          	auipc	a1,0x6
    80002ab8:	88c58593          	addi	a1,a1,-1908 # 80008340 <states.1771+0x30>
    80002abc:	00015517          	auipc	a0,0x15
    80002ac0:	e3450513          	addi	a0,a0,-460 # 800178f0 <tickslock>
    80002ac4:	ffffe097          	auipc	ra,0xffffe
    80002ac8:	090080e7          	jalr	144(ra) # 80000b54 <initlock>
}
    80002acc:	60a2                	ld	ra,8(sp)
    80002ace:	6402                	ld	s0,0(sp)
    80002ad0:	0141                	addi	sp,sp,16
    80002ad2:	8082                	ret

0000000080002ad4 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    80002ad4:	1141                	addi	sp,sp,-16
    80002ad6:	e422                	sd	s0,8(sp)
    80002ad8:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002ada:	00003797          	auipc	a5,0x3
    80002ade:	4d678793          	addi	a5,a5,1238 # 80005fb0 <kernelvec>
    80002ae2:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002ae6:	6422                	ld	s0,8(sp)
    80002ae8:	0141                	addi	sp,sp,16
    80002aea:	8082                	ret

0000000080002aec <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002aec:	1141                	addi	sp,sp,-16
    80002aee:	e406                	sd	ra,8(sp)
    80002af0:	e022                	sd	s0,0(sp)
    80002af2:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002af4:	fffff097          	auipc	ra,0xfffff
    80002af8:	ed4080e7          	jalr	-300(ra) # 800019c8 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002afc:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002b00:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002b02:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    80002b06:	00004617          	auipc	a2,0x4
    80002b0a:	4fa60613          	addi	a2,a2,1274 # 80007000 <_trampoline>
    80002b0e:	00004697          	auipc	a3,0x4
    80002b12:	4f268693          	addi	a3,a3,1266 # 80007000 <_trampoline>
    80002b16:	8e91                	sub	a3,a3,a2
    80002b18:	040007b7          	lui	a5,0x4000
    80002b1c:	17fd                	addi	a5,a5,-1
    80002b1e:	07b2                	slli	a5,a5,0xc
    80002b20:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002b22:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002b26:	7d38                	ld	a4,120(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002b28:	180026f3          	csrr	a3,satp
    80002b2c:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002b2e:	7d38                	ld	a4,120(a0)
    80002b30:	7134                	ld	a3,96(a0)
    80002b32:	6585                	lui	a1,0x1
    80002b34:	96ae                	add	a3,a3,a1
    80002b36:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002b38:	7d38                	ld	a4,120(a0)
    80002b3a:	00000697          	auipc	a3,0x0
    80002b3e:	13868693          	addi	a3,a3,312 # 80002c72 <usertrap>
    80002b42:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80002b44:	7d38                	ld	a4,120(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002b46:	8692                	mv	a3,tp
    80002b48:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002b4a:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002b4e:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002b52:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002b56:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002b5a:	7d38                	ld	a4,120(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002b5c:	6f18                	ld	a4,24(a4)
    80002b5e:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002b62:	792c                	ld	a1,112(a0)
    80002b64:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    80002b66:	00004717          	auipc	a4,0x4
    80002b6a:	52a70713          	addi	a4,a4,1322 # 80007090 <userret>
    80002b6e:	8f11                	sub	a4,a4,a2
    80002b70:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    80002b72:	577d                	li	a4,-1
    80002b74:	177e                	slli	a4,a4,0x3f
    80002b76:	8dd9                	or	a1,a1,a4
    80002b78:	02000537          	lui	a0,0x2000
    80002b7c:	157d                	addi	a0,a0,-1
    80002b7e:	0536                	slli	a0,a0,0xd
    80002b80:	9782                	jalr	a5
}
    80002b82:	60a2                	ld	ra,8(sp)
    80002b84:	6402                	ld	s0,0(sp)
    80002b86:	0141                	addi	sp,sp,16
    80002b88:	8082                	ret

0000000080002b8a <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80002b8a:	1101                	addi	sp,sp,-32
    80002b8c:	ec06                	sd	ra,24(sp)
    80002b8e:	e822                	sd	s0,16(sp)
    80002b90:	e426                	sd	s1,8(sp)
    80002b92:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002b94:	00015497          	auipc	s1,0x15
    80002b98:	d5c48493          	addi	s1,s1,-676 # 800178f0 <tickslock>
    80002b9c:	8526                	mv	a0,s1
    80002b9e:	ffffe097          	auipc	ra,0xffffe
    80002ba2:	046080e7          	jalr	70(ra) # 80000be4 <acquire>
  ticks++;
    80002ba6:	00006517          	auipc	a0,0x6
    80002baa:	4aa50513          	addi	a0,a0,1194 # 80009050 <ticks>
    80002bae:	411c                	lw	a5,0(a0)
    80002bb0:	2785                	addiw	a5,a5,1
    80002bb2:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80002bb4:	00000097          	auipc	ra,0x0
    80002bb8:	9ae080e7          	jalr	-1618(ra) # 80002562 <wakeup>
  release(&tickslock);
    80002bbc:	8526                	mv	a0,s1
    80002bbe:	ffffe097          	auipc	ra,0xffffe
    80002bc2:	0da080e7          	jalr	218(ra) # 80000c98 <release>
}
    80002bc6:	60e2                	ld	ra,24(sp)
    80002bc8:	6442                	ld	s0,16(sp)
    80002bca:	64a2                	ld	s1,8(sp)
    80002bcc:	6105                	addi	sp,sp,32
    80002bce:	8082                	ret

0000000080002bd0 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80002bd0:	1101                	addi	sp,sp,-32
    80002bd2:	ec06                	sd	ra,24(sp)
    80002bd4:	e822                	sd	s0,16(sp)
    80002bd6:	e426                	sd	s1,8(sp)
    80002bd8:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002bda:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80002bde:	00074d63          	bltz	a4,80002bf8 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80002be2:	57fd                	li	a5,-1
    80002be4:	17fe                	slli	a5,a5,0x3f
    80002be6:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002be8:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002bea:	06f70363          	beq	a4,a5,80002c50 <devintr+0x80>
  }
}
    80002bee:	60e2                	ld	ra,24(sp)
    80002bf0:	6442                	ld	s0,16(sp)
    80002bf2:	64a2                	ld	s1,8(sp)
    80002bf4:	6105                	addi	sp,sp,32
    80002bf6:	8082                	ret
     (scause & 0xff) == 9){
    80002bf8:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    80002bfc:	46a5                	li	a3,9
    80002bfe:	fed792e3          	bne	a5,a3,80002be2 <devintr+0x12>
    int irq = plic_claim();
    80002c02:	00003097          	auipc	ra,0x3
    80002c06:	4b6080e7          	jalr	1206(ra) # 800060b8 <plic_claim>
    80002c0a:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002c0c:	47a9                	li	a5,10
    80002c0e:	02f50763          	beq	a0,a5,80002c3c <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80002c12:	4785                	li	a5,1
    80002c14:	02f50963          	beq	a0,a5,80002c46 <devintr+0x76>
    return 1;
    80002c18:	4505                	li	a0,1
    } else if(irq){
    80002c1a:	d8f1                	beqz	s1,80002bee <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002c1c:	85a6                	mv	a1,s1
    80002c1e:	00005517          	auipc	a0,0x5
    80002c22:	72a50513          	addi	a0,a0,1834 # 80008348 <states.1771+0x38>
    80002c26:	ffffe097          	auipc	ra,0xffffe
    80002c2a:	962080e7          	jalr	-1694(ra) # 80000588 <printf>
      plic_complete(irq);
    80002c2e:	8526                	mv	a0,s1
    80002c30:	00003097          	auipc	ra,0x3
    80002c34:	4ac080e7          	jalr	1196(ra) # 800060dc <plic_complete>
    return 1;
    80002c38:	4505                	li	a0,1
    80002c3a:	bf55                	j	80002bee <devintr+0x1e>
      uartintr();
    80002c3c:	ffffe097          	auipc	ra,0xffffe
    80002c40:	d6c080e7          	jalr	-660(ra) # 800009a8 <uartintr>
    80002c44:	b7ed                	j	80002c2e <devintr+0x5e>
      virtio_disk_intr();
    80002c46:	00004097          	auipc	ra,0x4
    80002c4a:	976080e7          	jalr	-1674(ra) # 800065bc <virtio_disk_intr>
    80002c4e:	b7c5                	j	80002c2e <devintr+0x5e>
    if(cpuid() == 0){
    80002c50:	fffff097          	auipc	ra,0xfffff
    80002c54:	d4c080e7          	jalr	-692(ra) # 8000199c <cpuid>
    80002c58:	c901                	beqz	a0,80002c68 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002c5a:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002c5e:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002c60:	14479073          	csrw	sip,a5
    return 2;
    80002c64:	4509                	li	a0,2
    80002c66:	b761                	j	80002bee <devintr+0x1e>
      clockintr();
    80002c68:	00000097          	auipc	ra,0x0
    80002c6c:	f22080e7          	jalr	-222(ra) # 80002b8a <clockintr>
    80002c70:	b7ed                	j	80002c5a <devintr+0x8a>

0000000080002c72 <usertrap>:
{
    80002c72:	1101                	addi	sp,sp,-32
    80002c74:	ec06                	sd	ra,24(sp)
    80002c76:	e822                	sd	s0,16(sp)
    80002c78:	e426                	sd	s1,8(sp)
    80002c7a:	e04a                	sd	s2,0(sp)
    80002c7c:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002c7e:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002c82:	1007f793          	andi	a5,a5,256
    80002c86:	e3ad                	bnez	a5,80002ce8 <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002c88:	00003797          	auipc	a5,0x3
    80002c8c:	32878793          	addi	a5,a5,808 # 80005fb0 <kernelvec>
    80002c90:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002c94:	fffff097          	auipc	ra,0xfffff
    80002c98:	d34080e7          	jalr	-716(ra) # 800019c8 <myproc>
    80002c9c:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002c9e:	7d3c                	ld	a5,120(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002ca0:	14102773          	csrr	a4,sepc
    80002ca4:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002ca6:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002caa:	47a1                	li	a5,8
    80002cac:	04f71c63          	bne	a4,a5,80002d04 <usertrap+0x92>
    if(p->killed)
    80002cb0:	551c                	lw	a5,40(a0)
    80002cb2:	e3b9                	bnez	a5,80002cf8 <usertrap+0x86>
    p->trapframe->epc += 4;
    80002cb4:	7cb8                	ld	a4,120(s1)
    80002cb6:	6f1c                	ld	a5,24(a4)
    80002cb8:	0791                	addi	a5,a5,4
    80002cba:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002cbc:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002cc0:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002cc4:	10079073          	csrw	sstatus,a5
    syscall();
    80002cc8:	00000097          	auipc	ra,0x0
    80002ccc:	2e0080e7          	jalr	736(ra) # 80002fa8 <syscall>
  if(p->killed)
    80002cd0:	549c                	lw	a5,40(s1)
    80002cd2:	ebc1                	bnez	a5,80002d62 <usertrap+0xf0>
  usertrapret();
    80002cd4:	00000097          	auipc	ra,0x0
    80002cd8:	e18080e7          	jalr	-488(ra) # 80002aec <usertrapret>
}
    80002cdc:	60e2                	ld	ra,24(sp)
    80002cde:	6442                	ld	s0,16(sp)
    80002ce0:	64a2                	ld	s1,8(sp)
    80002ce2:	6902                	ld	s2,0(sp)
    80002ce4:	6105                	addi	sp,sp,32
    80002ce6:	8082                	ret
    panic("usertrap: not from user mode");
    80002ce8:	00005517          	auipc	a0,0x5
    80002cec:	68050513          	addi	a0,a0,1664 # 80008368 <states.1771+0x58>
    80002cf0:	ffffe097          	auipc	ra,0xffffe
    80002cf4:	84e080e7          	jalr	-1970(ra) # 8000053e <panic>
      exit(-1);
    80002cf8:	557d                	li	a0,-1
    80002cfa:	00000097          	auipc	ra,0x0
    80002cfe:	958080e7          	jalr	-1704(ra) # 80002652 <exit>
    80002d02:	bf4d                	j	80002cb4 <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    80002d04:	00000097          	auipc	ra,0x0
    80002d08:	ecc080e7          	jalr	-308(ra) # 80002bd0 <devintr>
    80002d0c:	892a                	mv	s2,a0
    80002d0e:	c501                	beqz	a0,80002d16 <usertrap+0xa4>
  if(p->killed)
    80002d10:	549c                	lw	a5,40(s1)
    80002d12:	c3a1                	beqz	a5,80002d52 <usertrap+0xe0>
    80002d14:	a815                	j	80002d48 <usertrap+0xd6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002d16:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002d1a:	5890                	lw	a2,48(s1)
    80002d1c:	00005517          	auipc	a0,0x5
    80002d20:	66c50513          	addi	a0,a0,1644 # 80008388 <states.1771+0x78>
    80002d24:	ffffe097          	auipc	ra,0xffffe
    80002d28:	864080e7          	jalr	-1948(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002d2c:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002d30:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002d34:	00005517          	auipc	a0,0x5
    80002d38:	68450513          	addi	a0,a0,1668 # 800083b8 <states.1771+0xa8>
    80002d3c:	ffffe097          	auipc	ra,0xffffe
    80002d40:	84c080e7          	jalr	-1972(ra) # 80000588 <printf>
    p->killed = 1;
    80002d44:	4785                	li	a5,1
    80002d46:	d49c                	sw	a5,40(s1)
    exit(-1);
    80002d48:	557d                	li	a0,-1
    80002d4a:	00000097          	auipc	ra,0x0
    80002d4e:	908080e7          	jalr	-1784(ra) # 80002652 <exit>
  if(which_dev == 2)
    80002d52:	4789                	li	a5,2
    80002d54:	f8f910e3          	bne	s2,a5,80002cd4 <usertrap+0x62>
    yield();
    80002d58:	fffff097          	auipc	ra,0xfffff
    80002d5c:	616080e7          	jalr	1558(ra) # 8000236e <yield>
    80002d60:	bf95                	j	80002cd4 <usertrap+0x62>
  int which_dev = 0;
    80002d62:	4901                	li	s2,0
    80002d64:	b7d5                	j	80002d48 <usertrap+0xd6>

0000000080002d66 <kerneltrap>:
{
    80002d66:	7179                	addi	sp,sp,-48
    80002d68:	f406                	sd	ra,40(sp)
    80002d6a:	f022                	sd	s0,32(sp)
    80002d6c:	ec26                	sd	s1,24(sp)
    80002d6e:	e84a                	sd	s2,16(sp)
    80002d70:	e44e                	sd	s3,8(sp)
    80002d72:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002d74:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002d78:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002d7c:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002d80:	1004f793          	andi	a5,s1,256
    80002d84:	cb85                	beqz	a5,80002db4 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002d86:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002d8a:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002d8c:	ef85                	bnez	a5,80002dc4 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002d8e:	00000097          	auipc	ra,0x0
    80002d92:	e42080e7          	jalr	-446(ra) # 80002bd0 <devintr>
    80002d96:	cd1d                	beqz	a0,80002dd4 <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002d98:	4789                	li	a5,2
    80002d9a:	06f50a63          	beq	a0,a5,80002e0e <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002d9e:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002da2:	10049073          	csrw	sstatus,s1
}
    80002da6:	70a2                	ld	ra,40(sp)
    80002da8:	7402                	ld	s0,32(sp)
    80002daa:	64e2                	ld	s1,24(sp)
    80002dac:	6942                	ld	s2,16(sp)
    80002dae:	69a2                	ld	s3,8(sp)
    80002db0:	6145                	addi	sp,sp,48
    80002db2:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002db4:	00005517          	auipc	a0,0x5
    80002db8:	62450513          	addi	a0,a0,1572 # 800083d8 <states.1771+0xc8>
    80002dbc:	ffffd097          	auipc	ra,0xffffd
    80002dc0:	782080e7          	jalr	1922(ra) # 8000053e <panic>
    panic("kerneltrap: interrupts enabled");
    80002dc4:	00005517          	auipc	a0,0x5
    80002dc8:	63c50513          	addi	a0,a0,1596 # 80008400 <states.1771+0xf0>
    80002dcc:	ffffd097          	auipc	ra,0xffffd
    80002dd0:	772080e7          	jalr	1906(ra) # 8000053e <panic>
    printf("scause %p\n", scause);
    80002dd4:	85ce                	mv	a1,s3
    80002dd6:	00005517          	auipc	a0,0x5
    80002dda:	64a50513          	addi	a0,a0,1610 # 80008420 <states.1771+0x110>
    80002dde:	ffffd097          	auipc	ra,0xffffd
    80002de2:	7aa080e7          	jalr	1962(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002de6:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002dea:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002dee:	00005517          	auipc	a0,0x5
    80002df2:	64250513          	addi	a0,a0,1602 # 80008430 <states.1771+0x120>
    80002df6:	ffffd097          	auipc	ra,0xffffd
    80002dfa:	792080e7          	jalr	1938(ra) # 80000588 <printf>
    panic("kerneltrap");
    80002dfe:	00005517          	auipc	a0,0x5
    80002e02:	64a50513          	addi	a0,a0,1610 # 80008448 <states.1771+0x138>
    80002e06:	ffffd097          	auipc	ra,0xffffd
    80002e0a:	738080e7          	jalr	1848(ra) # 8000053e <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002e0e:	fffff097          	auipc	ra,0xfffff
    80002e12:	bba080e7          	jalr	-1094(ra) # 800019c8 <myproc>
    80002e16:	d541                	beqz	a0,80002d9e <kerneltrap+0x38>
    80002e18:	fffff097          	auipc	ra,0xfffff
    80002e1c:	bb0080e7          	jalr	-1104(ra) # 800019c8 <myproc>
    80002e20:	4d18                	lw	a4,24(a0)
    80002e22:	4791                	li	a5,4
    80002e24:	f6f71de3          	bne	a4,a5,80002d9e <kerneltrap+0x38>
    yield();
    80002e28:	fffff097          	auipc	ra,0xfffff
    80002e2c:	546080e7          	jalr	1350(ra) # 8000236e <yield>
    80002e30:	b7bd                	j	80002d9e <kerneltrap+0x38>

0000000080002e32 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002e32:	1101                	addi	sp,sp,-32
    80002e34:	ec06                	sd	ra,24(sp)
    80002e36:	e822                	sd	s0,16(sp)
    80002e38:	e426                	sd	s1,8(sp)
    80002e3a:	1000                	addi	s0,sp,32
    80002e3c:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002e3e:	fffff097          	auipc	ra,0xfffff
    80002e42:	b8a080e7          	jalr	-1142(ra) # 800019c8 <myproc>
  switch (n) {
    80002e46:	4795                	li	a5,5
    80002e48:	0497e163          	bltu	a5,s1,80002e8a <argraw+0x58>
    80002e4c:	048a                	slli	s1,s1,0x2
    80002e4e:	00005717          	auipc	a4,0x5
    80002e52:	63270713          	addi	a4,a4,1586 # 80008480 <states.1771+0x170>
    80002e56:	94ba                	add	s1,s1,a4
    80002e58:	409c                	lw	a5,0(s1)
    80002e5a:	97ba                	add	a5,a5,a4
    80002e5c:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002e5e:	7d3c                	ld	a5,120(a0)
    80002e60:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002e62:	60e2                	ld	ra,24(sp)
    80002e64:	6442                	ld	s0,16(sp)
    80002e66:	64a2                	ld	s1,8(sp)
    80002e68:	6105                	addi	sp,sp,32
    80002e6a:	8082                	ret
    return p->trapframe->a1;
    80002e6c:	7d3c                	ld	a5,120(a0)
    80002e6e:	7fa8                	ld	a0,120(a5)
    80002e70:	bfcd                	j	80002e62 <argraw+0x30>
    return p->trapframe->a2;
    80002e72:	7d3c                	ld	a5,120(a0)
    80002e74:	63c8                	ld	a0,128(a5)
    80002e76:	b7f5                	j	80002e62 <argraw+0x30>
    return p->trapframe->a3;
    80002e78:	7d3c                	ld	a5,120(a0)
    80002e7a:	67c8                	ld	a0,136(a5)
    80002e7c:	b7dd                	j	80002e62 <argraw+0x30>
    return p->trapframe->a4;
    80002e7e:	7d3c                	ld	a5,120(a0)
    80002e80:	6bc8                	ld	a0,144(a5)
    80002e82:	b7c5                	j	80002e62 <argraw+0x30>
    return p->trapframe->a5;
    80002e84:	7d3c                	ld	a5,120(a0)
    80002e86:	6fc8                	ld	a0,152(a5)
    80002e88:	bfe9                	j	80002e62 <argraw+0x30>
  panic("argraw");
    80002e8a:	00005517          	auipc	a0,0x5
    80002e8e:	5ce50513          	addi	a0,a0,1486 # 80008458 <states.1771+0x148>
    80002e92:	ffffd097          	auipc	ra,0xffffd
    80002e96:	6ac080e7          	jalr	1708(ra) # 8000053e <panic>

0000000080002e9a <fetchaddr>:
{
    80002e9a:	1101                	addi	sp,sp,-32
    80002e9c:	ec06                	sd	ra,24(sp)
    80002e9e:	e822                	sd	s0,16(sp)
    80002ea0:	e426                	sd	s1,8(sp)
    80002ea2:	e04a                	sd	s2,0(sp)
    80002ea4:	1000                	addi	s0,sp,32
    80002ea6:	84aa                	mv	s1,a0
    80002ea8:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002eaa:	fffff097          	auipc	ra,0xfffff
    80002eae:	b1e080e7          	jalr	-1250(ra) # 800019c8 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    80002eb2:	753c                	ld	a5,104(a0)
    80002eb4:	02f4f863          	bgeu	s1,a5,80002ee4 <fetchaddr+0x4a>
    80002eb8:	00848713          	addi	a4,s1,8
    80002ebc:	02e7e663          	bltu	a5,a4,80002ee8 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002ec0:	46a1                	li	a3,8
    80002ec2:	8626                	mv	a2,s1
    80002ec4:	85ca                	mv	a1,s2
    80002ec6:	7928                	ld	a0,112(a0)
    80002ec8:	fffff097          	auipc	ra,0xfffff
    80002ecc:	83e080e7          	jalr	-1986(ra) # 80001706 <copyin>
    80002ed0:	00a03533          	snez	a0,a0
    80002ed4:	40a00533          	neg	a0,a0
}
    80002ed8:	60e2                	ld	ra,24(sp)
    80002eda:	6442                	ld	s0,16(sp)
    80002edc:	64a2                	ld	s1,8(sp)
    80002ede:	6902                	ld	s2,0(sp)
    80002ee0:	6105                	addi	sp,sp,32
    80002ee2:	8082                	ret
    return -1;
    80002ee4:	557d                	li	a0,-1
    80002ee6:	bfcd                	j	80002ed8 <fetchaddr+0x3e>
    80002ee8:	557d                	li	a0,-1
    80002eea:	b7fd                	j	80002ed8 <fetchaddr+0x3e>

0000000080002eec <fetchstr>:
{
    80002eec:	7179                	addi	sp,sp,-48
    80002eee:	f406                	sd	ra,40(sp)
    80002ef0:	f022                	sd	s0,32(sp)
    80002ef2:	ec26                	sd	s1,24(sp)
    80002ef4:	e84a                	sd	s2,16(sp)
    80002ef6:	e44e                	sd	s3,8(sp)
    80002ef8:	1800                	addi	s0,sp,48
    80002efa:	892a                	mv	s2,a0
    80002efc:	84ae                	mv	s1,a1
    80002efe:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002f00:	fffff097          	auipc	ra,0xfffff
    80002f04:	ac8080e7          	jalr	-1336(ra) # 800019c8 <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80002f08:	86ce                	mv	a3,s3
    80002f0a:	864a                	mv	a2,s2
    80002f0c:	85a6                	mv	a1,s1
    80002f0e:	7928                	ld	a0,112(a0)
    80002f10:	fffff097          	auipc	ra,0xfffff
    80002f14:	882080e7          	jalr	-1918(ra) # 80001792 <copyinstr>
  if(err < 0)
    80002f18:	00054763          	bltz	a0,80002f26 <fetchstr+0x3a>
  return strlen(buf);
    80002f1c:	8526                	mv	a0,s1
    80002f1e:	ffffe097          	auipc	ra,0xffffe
    80002f22:	f46080e7          	jalr	-186(ra) # 80000e64 <strlen>
}
    80002f26:	70a2                	ld	ra,40(sp)
    80002f28:	7402                	ld	s0,32(sp)
    80002f2a:	64e2                	ld	s1,24(sp)
    80002f2c:	6942                	ld	s2,16(sp)
    80002f2e:	69a2                	ld	s3,8(sp)
    80002f30:	6145                	addi	sp,sp,48
    80002f32:	8082                	ret

0000000080002f34 <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80002f34:	1101                	addi	sp,sp,-32
    80002f36:	ec06                	sd	ra,24(sp)
    80002f38:	e822                	sd	s0,16(sp)
    80002f3a:	e426                	sd	s1,8(sp)
    80002f3c:	1000                	addi	s0,sp,32
    80002f3e:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002f40:	00000097          	auipc	ra,0x0
    80002f44:	ef2080e7          	jalr	-270(ra) # 80002e32 <argraw>
    80002f48:	c088                	sw	a0,0(s1)
  return 0;
}
    80002f4a:	4501                	li	a0,0
    80002f4c:	60e2                	ld	ra,24(sp)
    80002f4e:	6442                	ld	s0,16(sp)
    80002f50:	64a2                	ld	s1,8(sp)
    80002f52:	6105                	addi	sp,sp,32
    80002f54:	8082                	ret

0000000080002f56 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80002f56:	1101                	addi	sp,sp,-32
    80002f58:	ec06                	sd	ra,24(sp)
    80002f5a:	e822                	sd	s0,16(sp)
    80002f5c:	e426                	sd	s1,8(sp)
    80002f5e:	1000                	addi	s0,sp,32
    80002f60:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002f62:	00000097          	auipc	ra,0x0
    80002f66:	ed0080e7          	jalr	-304(ra) # 80002e32 <argraw>
    80002f6a:	e088                	sd	a0,0(s1)
  return 0;
}
    80002f6c:	4501                	li	a0,0
    80002f6e:	60e2                	ld	ra,24(sp)
    80002f70:	6442                	ld	s0,16(sp)
    80002f72:	64a2                	ld	s1,8(sp)
    80002f74:	6105                	addi	sp,sp,32
    80002f76:	8082                	ret

0000000080002f78 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002f78:	1101                	addi	sp,sp,-32
    80002f7a:	ec06                	sd	ra,24(sp)
    80002f7c:	e822                	sd	s0,16(sp)
    80002f7e:	e426                	sd	s1,8(sp)
    80002f80:	e04a                	sd	s2,0(sp)
    80002f82:	1000                	addi	s0,sp,32
    80002f84:	84ae                	mv	s1,a1
    80002f86:	8932                	mv	s2,a2
  *ip = argraw(n);
    80002f88:	00000097          	auipc	ra,0x0
    80002f8c:	eaa080e7          	jalr	-342(ra) # 80002e32 <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80002f90:	864a                	mv	a2,s2
    80002f92:	85a6                	mv	a1,s1
    80002f94:	00000097          	auipc	ra,0x0
    80002f98:	f58080e7          	jalr	-168(ra) # 80002eec <fetchstr>
}
    80002f9c:	60e2                	ld	ra,24(sp)
    80002f9e:	6442                	ld	s0,16(sp)
    80002fa0:	64a2                	ld	s1,8(sp)
    80002fa2:	6902                	ld	s2,0(sp)
    80002fa4:	6105                	addi	sp,sp,32
    80002fa6:	8082                	ret

0000000080002fa8 <syscall>:
[SYS_kill_system] sys_kill_system,
};

void
syscall(void)
{
    80002fa8:	1101                	addi	sp,sp,-32
    80002faa:	ec06                	sd	ra,24(sp)
    80002fac:	e822                	sd	s0,16(sp)
    80002fae:	e426                	sd	s1,8(sp)
    80002fb0:	e04a                	sd	s2,0(sp)
    80002fb2:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002fb4:	fffff097          	auipc	ra,0xfffff
    80002fb8:	a14080e7          	jalr	-1516(ra) # 800019c8 <myproc>
    80002fbc:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002fbe:	07853903          	ld	s2,120(a0)
    80002fc2:	0a893783          	ld	a5,168(s2)
    80002fc6:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002fca:	37fd                	addiw	a5,a5,-1
    80002fcc:	4759                	li	a4,22
    80002fce:	00f76f63          	bltu	a4,a5,80002fec <syscall+0x44>
    80002fd2:	00369713          	slli	a4,a3,0x3
    80002fd6:	00005797          	auipc	a5,0x5
    80002fda:	4c278793          	addi	a5,a5,1218 # 80008498 <syscalls>
    80002fde:	97ba                	add	a5,a5,a4
    80002fe0:	639c                	ld	a5,0(a5)
    80002fe2:	c789                	beqz	a5,80002fec <syscall+0x44>
    p->trapframe->a0 = syscalls[num]();
    80002fe4:	9782                	jalr	a5
    80002fe6:	06a93823          	sd	a0,112(s2)
    80002fea:	a839                	j	80003008 <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002fec:	17848613          	addi	a2,s1,376
    80002ff0:	588c                	lw	a1,48(s1)
    80002ff2:	00005517          	auipc	a0,0x5
    80002ff6:	46e50513          	addi	a0,a0,1134 # 80008460 <states.1771+0x150>
    80002ffa:	ffffd097          	auipc	ra,0xffffd
    80002ffe:	58e080e7          	jalr	1422(ra) # 80000588 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80003002:	7cbc                	ld	a5,120(s1)
    80003004:	577d                	li	a4,-1
    80003006:	fbb8                	sd	a4,112(a5)
  }
}
    80003008:	60e2                	ld	ra,24(sp)
    8000300a:	6442                	ld	s0,16(sp)
    8000300c:	64a2                	ld	s1,8(sp)
    8000300e:	6902                	ld	s2,0(sp)
    80003010:	6105                	addi	sp,sp,32
    80003012:	8082                	ret

0000000080003014 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80003014:	1101                	addi	sp,sp,-32
    80003016:	ec06                	sd	ra,24(sp)
    80003018:	e822                	sd	s0,16(sp)
    8000301a:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    8000301c:	fec40593          	addi	a1,s0,-20
    80003020:	4501                	li	a0,0
    80003022:	00000097          	auipc	ra,0x0
    80003026:	f12080e7          	jalr	-238(ra) # 80002f34 <argint>
    return -1;
    8000302a:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    8000302c:	00054963          	bltz	a0,8000303e <sys_exit+0x2a>
  exit(n);
    80003030:	fec42503          	lw	a0,-20(s0)
    80003034:	fffff097          	auipc	ra,0xfffff
    80003038:	61e080e7          	jalr	1566(ra) # 80002652 <exit>
  return 0;  // not reached
    8000303c:	4781                	li	a5,0
}
    8000303e:	853e                	mv	a0,a5
    80003040:	60e2                	ld	ra,24(sp)
    80003042:	6442                	ld	s0,16(sp)
    80003044:	6105                	addi	sp,sp,32
    80003046:	8082                	ret

0000000080003048 <sys_getpid>:

uint64
sys_getpid(void)
{
    80003048:	1141                	addi	sp,sp,-16
    8000304a:	e406                	sd	ra,8(sp)
    8000304c:	e022                	sd	s0,0(sp)
    8000304e:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80003050:	fffff097          	auipc	ra,0xfffff
    80003054:	978080e7          	jalr	-1672(ra) # 800019c8 <myproc>
}
    80003058:	5908                	lw	a0,48(a0)
    8000305a:	60a2                	ld	ra,8(sp)
    8000305c:	6402                	ld	s0,0(sp)
    8000305e:	0141                	addi	sp,sp,16
    80003060:	8082                	ret

0000000080003062 <sys_fork>:

uint64
sys_fork(void)
{
    80003062:	1141                	addi	sp,sp,-16
    80003064:	e406                	sd	ra,8(sp)
    80003066:	e022                	sd	s0,0(sp)
    80003068:	0800                	addi	s0,sp,16
  return fork();
    8000306a:	fffff097          	auipc	ra,0xfffff
    8000306e:	d5a080e7          	jalr	-678(ra) # 80001dc4 <fork>
}
    80003072:	60a2                	ld	ra,8(sp)
    80003074:	6402                	ld	s0,0(sp)
    80003076:	0141                	addi	sp,sp,16
    80003078:	8082                	ret

000000008000307a <sys_wait>:

uint64
sys_wait(void)
{
    8000307a:	1101                	addi	sp,sp,-32
    8000307c:	ec06                	sd	ra,24(sp)
    8000307e:	e822                	sd	s0,16(sp)
    80003080:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80003082:	fe840593          	addi	a1,s0,-24
    80003086:	4501                	li	a0,0
    80003088:	00000097          	auipc	ra,0x0
    8000308c:	ece080e7          	jalr	-306(ra) # 80002f56 <argaddr>
    80003090:	87aa                	mv	a5,a0
    return -1;
    80003092:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80003094:	0007c863          	bltz	a5,800030a4 <sys_wait+0x2a>
  return wait(p);
    80003098:	fe843503          	ld	a0,-24(s0)
    8000309c:	fffff097          	auipc	ra,0xfffff
    800030a0:	39e080e7          	jalr	926(ra) # 8000243a <wait>
}
    800030a4:	60e2                	ld	ra,24(sp)
    800030a6:	6442                	ld	s0,16(sp)
    800030a8:	6105                	addi	sp,sp,32
    800030aa:	8082                	ret

00000000800030ac <sys_sbrk>:

uint64
sys_sbrk(void)
{
    800030ac:	7179                	addi	sp,sp,-48
    800030ae:	f406                	sd	ra,40(sp)
    800030b0:	f022                	sd	s0,32(sp)
    800030b2:	ec26                	sd	s1,24(sp)
    800030b4:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    800030b6:	fdc40593          	addi	a1,s0,-36
    800030ba:	4501                	li	a0,0
    800030bc:	00000097          	auipc	ra,0x0
    800030c0:	e78080e7          	jalr	-392(ra) # 80002f34 <argint>
    800030c4:	87aa                	mv	a5,a0
    return -1;
    800030c6:	557d                	li	a0,-1
  if(argint(0, &n) < 0)
    800030c8:	0207c063          	bltz	a5,800030e8 <sys_sbrk+0x3c>
  addr = myproc()->sz;
    800030cc:	fffff097          	auipc	ra,0xfffff
    800030d0:	8fc080e7          	jalr	-1796(ra) # 800019c8 <myproc>
    800030d4:	5524                	lw	s1,104(a0)
  if(growproc(n) < 0)
    800030d6:	fdc42503          	lw	a0,-36(s0)
    800030da:	fffff097          	auipc	ra,0xfffff
    800030de:	c76080e7          	jalr	-906(ra) # 80001d50 <growproc>
    800030e2:	00054863          	bltz	a0,800030f2 <sys_sbrk+0x46>
    return -1;
  return addr;
    800030e6:	8526                	mv	a0,s1
}
    800030e8:	70a2                	ld	ra,40(sp)
    800030ea:	7402                	ld	s0,32(sp)
    800030ec:	64e2                	ld	s1,24(sp)
    800030ee:	6145                	addi	sp,sp,48
    800030f0:	8082                	ret
    return -1;
    800030f2:	557d                	li	a0,-1
    800030f4:	bfd5                	j	800030e8 <sys_sbrk+0x3c>

00000000800030f6 <sys_sleep>:

uint64
sys_sleep(void)
{
    800030f6:	7139                	addi	sp,sp,-64
    800030f8:	fc06                	sd	ra,56(sp)
    800030fa:	f822                	sd	s0,48(sp)
    800030fc:	f426                	sd	s1,40(sp)
    800030fe:	f04a                	sd	s2,32(sp)
    80003100:	ec4e                	sd	s3,24(sp)
    80003102:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    80003104:	fcc40593          	addi	a1,s0,-52
    80003108:	4501                	li	a0,0
    8000310a:	00000097          	auipc	ra,0x0
    8000310e:	e2a080e7          	jalr	-470(ra) # 80002f34 <argint>
    return -1;
    80003112:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80003114:	06054563          	bltz	a0,8000317e <sys_sleep+0x88>
  acquire(&tickslock);
    80003118:	00014517          	auipc	a0,0x14
    8000311c:	7d850513          	addi	a0,a0,2008 # 800178f0 <tickslock>
    80003120:	ffffe097          	auipc	ra,0xffffe
    80003124:	ac4080e7          	jalr	-1340(ra) # 80000be4 <acquire>
  ticks0 = ticks;
    80003128:	00006917          	auipc	s2,0x6
    8000312c:	f2892903          	lw	s2,-216(s2) # 80009050 <ticks>
  while(ticks - ticks0 < n){
    80003130:	fcc42783          	lw	a5,-52(s0)
    80003134:	cf85                	beqz	a5,8000316c <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80003136:	00014997          	auipc	s3,0x14
    8000313a:	7ba98993          	addi	s3,s3,1978 # 800178f0 <tickslock>
    8000313e:	00006497          	auipc	s1,0x6
    80003142:	f1248493          	addi	s1,s1,-238 # 80009050 <ticks>
    if(myproc()->killed){
    80003146:	fffff097          	auipc	ra,0xfffff
    8000314a:	882080e7          	jalr	-1918(ra) # 800019c8 <myproc>
    8000314e:	551c                	lw	a5,40(a0)
    80003150:	ef9d                	bnez	a5,8000318e <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    80003152:	85ce                	mv	a1,s3
    80003154:	8526                	mv	a0,s1
    80003156:	fffff097          	auipc	ra,0xfffff
    8000315a:	26c080e7          	jalr	620(ra) # 800023c2 <sleep>
  while(ticks - ticks0 < n){
    8000315e:	409c                	lw	a5,0(s1)
    80003160:	412787bb          	subw	a5,a5,s2
    80003164:	fcc42703          	lw	a4,-52(s0)
    80003168:	fce7efe3          	bltu	a5,a4,80003146 <sys_sleep+0x50>
  }
  release(&tickslock);
    8000316c:	00014517          	auipc	a0,0x14
    80003170:	78450513          	addi	a0,a0,1924 # 800178f0 <tickslock>
    80003174:	ffffe097          	auipc	ra,0xffffe
    80003178:	b24080e7          	jalr	-1244(ra) # 80000c98 <release>
  return 0;
    8000317c:	4781                	li	a5,0
}
    8000317e:	853e                	mv	a0,a5
    80003180:	70e2                	ld	ra,56(sp)
    80003182:	7442                	ld	s0,48(sp)
    80003184:	74a2                	ld	s1,40(sp)
    80003186:	7902                	ld	s2,32(sp)
    80003188:	69e2                	ld	s3,24(sp)
    8000318a:	6121                	addi	sp,sp,64
    8000318c:	8082                	ret
      release(&tickslock);
    8000318e:	00014517          	auipc	a0,0x14
    80003192:	76250513          	addi	a0,a0,1890 # 800178f0 <tickslock>
    80003196:	ffffe097          	auipc	ra,0xffffe
    8000319a:	b02080e7          	jalr	-1278(ra) # 80000c98 <release>
      return -1;
    8000319e:	57fd                	li	a5,-1
    800031a0:	bff9                	j	8000317e <sys_sleep+0x88>

00000000800031a2 <sys_kill>:

uint64
sys_kill(void)
{
    800031a2:	1101                	addi	sp,sp,-32
    800031a4:	ec06                	sd	ra,24(sp)
    800031a6:	e822                	sd	s0,16(sp)
    800031a8:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    800031aa:	fec40593          	addi	a1,s0,-20
    800031ae:	4501                	li	a0,0
    800031b0:	00000097          	auipc	ra,0x0
    800031b4:	d84080e7          	jalr	-636(ra) # 80002f34 <argint>
    800031b8:	87aa                	mv	a5,a0
    return -1;
    800031ba:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    800031bc:	0007c863          	bltz	a5,800031cc <sys_kill+0x2a>
  return kill(pid);
    800031c0:	fec42503          	lw	a0,-20(s0)
    800031c4:	fffff097          	auipc	ra,0xfffff
    800031c8:	5f8080e7          	jalr	1528(ra) # 800027bc <kill>
}
    800031cc:	60e2                	ld	ra,24(sp)
    800031ce:	6442                	ld	s0,16(sp)
    800031d0:	6105                	addi	sp,sp,32
    800031d2:	8082                	ret

00000000800031d4 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    800031d4:	1101                	addi	sp,sp,-32
    800031d6:	ec06                	sd	ra,24(sp)
    800031d8:	e822                	sd	s0,16(sp)
    800031da:	e426                	sd	s1,8(sp)
    800031dc:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    800031de:	00014517          	auipc	a0,0x14
    800031e2:	71250513          	addi	a0,a0,1810 # 800178f0 <tickslock>
    800031e6:	ffffe097          	auipc	ra,0xffffe
    800031ea:	9fe080e7          	jalr	-1538(ra) # 80000be4 <acquire>
  xticks = ticks;
    800031ee:	00006497          	auipc	s1,0x6
    800031f2:	e624a483          	lw	s1,-414(s1) # 80009050 <ticks>
  release(&tickslock);
    800031f6:	00014517          	auipc	a0,0x14
    800031fa:	6fa50513          	addi	a0,a0,1786 # 800178f0 <tickslock>
    800031fe:	ffffe097          	auipc	ra,0xffffe
    80003202:	a9a080e7          	jalr	-1382(ra) # 80000c98 <release>
  return xticks;
}
    80003206:	02049513          	slli	a0,s1,0x20
    8000320a:	9101                	srli	a0,a0,0x20
    8000320c:	60e2                	ld	ra,24(sp)
    8000320e:	6442                	ld	s0,16(sp)
    80003210:	64a2                	ld	s1,8(sp)
    80003212:	6105                	addi	sp,sp,32
    80003214:	8082                	ret

0000000080003216 <sys_pause_system>:

uint64 sys_pause_system(void){
    80003216:	1101                	addi	sp,sp,-32
    80003218:	ec06                	sd	ra,24(sp)
    8000321a:	e822                	sd	s0,16(sp)
    8000321c:	1000                	addi	s0,sp,32
    int seconds;

    if(argint(0, &seconds) < 0)
    8000321e:	fec40593          	addi	a1,s0,-20
    80003222:	4501                	li	a0,0
    80003224:	00000097          	auipc	ra,0x0
    80003228:	d10080e7          	jalr	-752(ra) # 80002f34 <argint>
        return -1;
    8000322c:	57fd                	li	a5,-1
    if(argint(0, &seconds) < 0)
    8000322e:	00054963          	bltz	a0,80003240 <sys_pause_system+0x2a>
    pause_system(seconds);
    80003232:	fec42503          	lw	a0,-20(s0)
    80003236:	fffff097          	auipc	ra,0xfffff
    8000323a:	67c080e7          	jalr	1660(ra) # 800028b2 <pause_system>
    return 0;
    8000323e:	4781                	li	a5,0
}
    80003240:	853e                	mv	a0,a5
    80003242:	60e2                	ld	ra,24(sp)
    80003244:	6442                	ld	s0,16(sp)
    80003246:	6105                	addi	sp,sp,32
    80003248:	8082                	ret

000000008000324a <sys_kill_system>:

uint64 sys_kill_system(void){
    8000324a:	1141                	addi	sp,sp,-16
    8000324c:	e406                	sd	ra,8(sp)
    8000324e:	e022                	sd	s0,0(sp)
    80003250:	0800                	addi	s0,sp,16
    kill_system();
    80003252:	fffff097          	auipc	ra,0xfffff
    80003256:	5f4080e7          	jalr	1524(ra) # 80002846 <kill_system>
    return 0;
}
    8000325a:	4501                	li	a0,0
    8000325c:	60a2                	ld	ra,8(sp)
    8000325e:	6402                	ld	s0,0(sp)
    80003260:	0141                	addi	sp,sp,16
    80003262:	8082                	ret

0000000080003264 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80003264:	7179                	addi	sp,sp,-48
    80003266:	f406                	sd	ra,40(sp)
    80003268:	f022                	sd	s0,32(sp)
    8000326a:	ec26                	sd	s1,24(sp)
    8000326c:	e84a                	sd	s2,16(sp)
    8000326e:	e44e                	sd	s3,8(sp)
    80003270:	e052                	sd	s4,0(sp)
    80003272:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80003274:	00005597          	auipc	a1,0x5
    80003278:	2e458593          	addi	a1,a1,740 # 80008558 <syscalls+0xc0>
    8000327c:	00014517          	auipc	a0,0x14
    80003280:	68c50513          	addi	a0,a0,1676 # 80017908 <bcache>
    80003284:	ffffe097          	auipc	ra,0xffffe
    80003288:	8d0080e7          	jalr	-1840(ra) # 80000b54 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    8000328c:	0001c797          	auipc	a5,0x1c
    80003290:	67c78793          	addi	a5,a5,1660 # 8001f908 <bcache+0x8000>
    80003294:	0001d717          	auipc	a4,0x1d
    80003298:	8dc70713          	addi	a4,a4,-1828 # 8001fb70 <bcache+0x8268>
    8000329c:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    800032a0:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    800032a4:	00014497          	auipc	s1,0x14
    800032a8:	67c48493          	addi	s1,s1,1660 # 80017920 <bcache+0x18>
    b->next = bcache.head.next;
    800032ac:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    800032ae:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    800032b0:	00005a17          	auipc	s4,0x5
    800032b4:	2b0a0a13          	addi	s4,s4,688 # 80008560 <syscalls+0xc8>
    b->next = bcache.head.next;
    800032b8:	2b893783          	ld	a5,696(s2)
    800032bc:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    800032be:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    800032c2:	85d2                	mv	a1,s4
    800032c4:	01048513          	addi	a0,s1,16
    800032c8:	00001097          	auipc	ra,0x1
    800032cc:	4bc080e7          	jalr	1212(ra) # 80004784 <initsleeplock>
    bcache.head.next->prev = b;
    800032d0:	2b893783          	ld	a5,696(s2)
    800032d4:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    800032d6:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    800032da:	45848493          	addi	s1,s1,1112
    800032de:	fd349de3          	bne	s1,s3,800032b8 <binit+0x54>
  }
}
    800032e2:	70a2                	ld	ra,40(sp)
    800032e4:	7402                	ld	s0,32(sp)
    800032e6:	64e2                	ld	s1,24(sp)
    800032e8:	6942                	ld	s2,16(sp)
    800032ea:	69a2                	ld	s3,8(sp)
    800032ec:	6a02                	ld	s4,0(sp)
    800032ee:	6145                	addi	sp,sp,48
    800032f0:	8082                	ret

00000000800032f2 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    800032f2:	7179                	addi	sp,sp,-48
    800032f4:	f406                	sd	ra,40(sp)
    800032f6:	f022                	sd	s0,32(sp)
    800032f8:	ec26                	sd	s1,24(sp)
    800032fa:	e84a                	sd	s2,16(sp)
    800032fc:	e44e                	sd	s3,8(sp)
    800032fe:	1800                	addi	s0,sp,48
    80003300:	89aa                	mv	s3,a0
    80003302:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    80003304:	00014517          	auipc	a0,0x14
    80003308:	60450513          	addi	a0,a0,1540 # 80017908 <bcache>
    8000330c:	ffffe097          	auipc	ra,0xffffe
    80003310:	8d8080e7          	jalr	-1832(ra) # 80000be4 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80003314:	0001d497          	auipc	s1,0x1d
    80003318:	8ac4b483          	ld	s1,-1876(s1) # 8001fbc0 <bcache+0x82b8>
    8000331c:	0001d797          	auipc	a5,0x1d
    80003320:	85478793          	addi	a5,a5,-1964 # 8001fb70 <bcache+0x8268>
    80003324:	02f48f63          	beq	s1,a5,80003362 <bread+0x70>
    80003328:	873e                	mv	a4,a5
    8000332a:	a021                	j	80003332 <bread+0x40>
    8000332c:	68a4                	ld	s1,80(s1)
    8000332e:	02e48a63          	beq	s1,a4,80003362 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80003332:	449c                	lw	a5,8(s1)
    80003334:	ff379ce3          	bne	a5,s3,8000332c <bread+0x3a>
    80003338:	44dc                	lw	a5,12(s1)
    8000333a:	ff2799e3          	bne	a5,s2,8000332c <bread+0x3a>
      b->refcnt++;
    8000333e:	40bc                	lw	a5,64(s1)
    80003340:	2785                	addiw	a5,a5,1
    80003342:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003344:	00014517          	auipc	a0,0x14
    80003348:	5c450513          	addi	a0,a0,1476 # 80017908 <bcache>
    8000334c:	ffffe097          	auipc	ra,0xffffe
    80003350:	94c080e7          	jalr	-1716(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    80003354:	01048513          	addi	a0,s1,16
    80003358:	00001097          	auipc	ra,0x1
    8000335c:	466080e7          	jalr	1126(ra) # 800047be <acquiresleep>
      return b;
    80003360:	a8b9                	j	800033be <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003362:	0001d497          	auipc	s1,0x1d
    80003366:	8564b483          	ld	s1,-1962(s1) # 8001fbb8 <bcache+0x82b0>
    8000336a:	0001d797          	auipc	a5,0x1d
    8000336e:	80678793          	addi	a5,a5,-2042 # 8001fb70 <bcache+0x8268>
    80003372:	00f48863          	beq	s1,a5,80003382 <bread+0x90>
    80003376:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80003378:	40bc                	lw	a5,64(s1)
    8000337a:	cf81                	beqz	a5,80003392 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    8000337c:	64a4                	ld	s1,72(s1)
    8000337e:	fee49de3          	bne	s1,a4,80003378 <bread+0x86>
  panic("bget: no buffers");
    80003382:	00005517          	auipc	a0,0x5
    80003386:	1e650513          	addi	a0,a0,486 # 80008568 <syscalls+0xd0>
    8000338a:	ffffd097          	auipc	ra,0xffffd
    8000338e:	1b4080e7          	jalr	436(ra) # 8000053e <panic>
      b->dev = dev;
    80003392:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    80003396:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    8000339a:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    8000339e:	4785                	li	a5,1
    800033a0:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800033a2:	00014517          	auipc	a0,0x14
    800033a6:	56650513          	addi	a0,a0,1382 # 80017908 <bcache>
    800033aa:	ffffe097          	auipc	ra,0xffffe
    800033ae:	8ee080e7          	jalr	-1810(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    800033b2:	01048513          	addi	a0,s1,16
    800033b6:	00001097          	auipc	ra,0x1
    800033ba:	408080e7          	jalr	1032(ra) # 800047be <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    800033be:	409c                	lw	a5,0(s1)
    800033c0:	cb89                	beqz	a5,800033d2 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    800033c2:	8526                	mv	a0,s1
    800033c4:	70a2                	ld	ra,40(sp)
    800033c6:	7402                	ld	s0,32(sp)
    800033c8:	64e2                	ld	s1,24(sp)
    800033ca:	6942                	ld	s2,16(sp)
    800033cc:	69a2                	ld	s3,8(sp)
    800033ce:	6145                	addi	sp,sp,48
    800033d0:	8082                	ret
    virtio_disk_rw(b, 0);
    800033d2:	4581                	li	a1,0
    800033d4:	8526                	mv	a0,s1
    800033d6:	00003097          	auipc	ra,0x3
    800033da:	f10080e7          	jalr	-240(ra) # 800062e6 <virtio_disk_rw>
    b->valid = 1;
    800033de:	4785                	li	a5,1
    800033e0:	c09c                	sw	a5,0(s1)
  return b;
    800033e2:	b7c5                	j	800033c2 <bread+0xd0>

00000000800033e4 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    800033e4:	1101                	addi	sp,sp,-32
    800033e6:	ec06                	sd	ra,24(sp)
    800033e8:	e822                	sd	s0,16(sp)
    800033ea:	e426                	sd	s1,8(sp)
    800033ec:	1000                	addi	s0,sp,32
    800033ee:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800033f0:	0541                	addi	a0,a0,16
    800033f2:	00001097          	auipc	ra,0x1
    800033f6:	466080e7          	jalr	1126(ra) # 80004858 <holdingsleep>
    800033fa:	cd01                	beqz	a0,80003412 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    800033fc:	4585                	li	a1,1
    800033fe:	8526                	mv	a0,s1
    80003400:	00003097          	auipc	ra,0x3
    80003404:	ee6080e7          	jalr	-282(ra) # 800062e6 <virtio_disk_rw>
}
    80003408:	60e2                	ld	ra,24(sp)
    8000340a:	6442                	ld	s0,16(sp)
    8000340c:	64a2                	ld	s1,8(sp)
    8000340e:	6105                	addi	sp,sp,32
    80003410:	8082                	ret
    panic("bwrite");
    80003412:	00005517          	auipc	a0,0x5
    80003416:	16e50513          	addi	a0,a0,366 # 80008580 <syscalls+0xe8>
    8000341a:	ffffd097          	auipc	ra,0xffffd
    8000341e:	124080e7          	jalr	292(ra) # 8000053e <panic>

0000000080003422 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80003422:	1101                	addi	sp,sp,-32
    80003424:	ec06                	sd	ra,24(sp)
    80003426:	e822                	sd	s0,16(sp)
    80003428:	e426                	sd	s1,8(sp)
    8000342a:	e04a                	sd	s2,0(sp)
    8000342c:	1000                	addi	s0,sp,32
    8000342e:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003430:	01050913          	addi	s2,a0,16
    80003434:	854a                	mv	a0,s2
    80003436:	00001097          	auipc	ra,0x1
    8000343a:	422080e7          	jalr	1058(ra) # 80004858 <holdingsleep>
    8000343e:	c92d                	beqz	a0,800034b0 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    80003440:	854a                	mv	a0,s2
    80003442:	00001097          	auipc	ra,0x1
    80003446:	3d2080e7          	jalr	978(ra) # 80004814 <releasesleep>

  acquire(&bcache.lock);
    8000344a:	00014517          	auipc	a0,0x14
    8000344e:	4be50513          	addi	a0,a0,1214 # 80017908 <bcache>
    80003452:	ffffd097          	auipc	ra,0xffffd
    80003456:	792080e7          	jalr	1938(ra) # 80000be4 <acquire>
  b->refcnt--;
    8000345a:	40bc                	lw	a5,64(s1)
    8000345c:	37fd                	addiw	a5,a5,-1
    8000345e:	0007871b          	sext.w	a4,a5
    80003462:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80003464:	eb05                	bnez	a4,80003494 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80003466:	68bc                	ld	a5,80(s1)
    80003468:	64b8                	ld	a4,72(s1)
    8000346a:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    8000346c:	64bc                	ld	a5,72(s1)
    8000346e:	68b8                	ld	a4,80(s1)
    80003470:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80003472:	0001c797          	auipc	a5,0x1c
    80003476:	49678793          	addi	a5,a5,1174 # 8001f908 <bcache+0x8000>
    8000347a:	2b87b703          	ld	a4,696(a5)
    8000347e:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80003480:	0001c717          	auipc	a4,0x1c
    80003484:	6f070713          	addi	a4,a4,1776 # 8001fb70 <bcache+0x8268>
    80003488:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    8000348a:	2b87b703          	ld	a4,696(a5)
    8000348e:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80003490:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    80003494:	00014517          	auipc	a0,0x14
    80003498:	47450513          	addi	a0,a0,1140 # 80017908 <bcache>
    8000349c:	ffffd097          	auipc	ra,0xffffd
    800034a0:	7fc080e7          	jalr	2044(ra) # 80000c98 <release>
}
    800034a4:	60e2                	ld	ra,24(sp)
    800034a6:	6442                	ld	s0,16(sp)
    800034a8:	64a2                	ld	s1,8(sp)
    800034aa:	6902                	ld	s2,0(sp)
    800034ac:	6105                	addi	sp,sp,32
    800034ae:	8082                	ret
    panic("brelse");
    800034b0:	00005517          	auipc	a0,0x5
    800034b4:	0d850513          	addi	a0,a0,216 # 80008588 <syscalls+0xf0>
    800034b8:	ffffd097          	auipc	ra,0xffffd
    800034bc:	086080e7          	jalr	134(ra) # 8000053e <panic>

00000000800034c0 <bpin>:

void
bpin(struct buf *b) {
    800034c0:	1101                	addi	sp,sp,-32
    800034c2:	ec06                	sd	ra,24(sp)
    800034c4:	e822                	sd	s0,16(sp)
    800034c6:	e426                	sd	s1,8(sp)
    800034c8:	1000                	addi	s0,sp,32
    800034ca:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800034cc:	00014517          	auipc	a0,0x14
    800034d0:	43c50513          	addi	a0,a0,1084 # 80017908 <bcache>
    800034d4:	ffffd097          	auipc	ra,0xffffd
    800034d8:	710080e7          	jalr	1808(ra) # 80000be4 <acquire>
  b->refcnt++;
    800034dc:	40bc                	lw	a5,64(s1)
    800034de:	2785                	addiw	a5,a5,1
    800034e0:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800034e2:	00014517          	auipc	a0,0x14
    800034e6:	42650513          	addi	a0,a0,1062 # 80017908 <bcache>
    800034ea:	ffffd097          	auipc	ra,0xffffd
    800034ee:	7ae080e7          	jalr	1966(ra) # 80000c98 <release>
}
    800034f2:	60e2                	ld	ra,24(sp)
    800034f4:	6442                	ld	s0,16(sp)
    800034f6:	64a2                	ld	s1,8(sp)
    800034f8:	6105                	addi	sp,sp,32
    800034fa:	8082                	ret

00000000800034fc <bunpin>:

void
bunpin(struct buf *b) {
    800034fc:	1101                	addi	sp,sp,-32
    800034fe:	ec06                	sd	ra,24(sp)
    80003500:	e822                	sd	s0,16(sp)
    80003502:	e426                	sd	s1,8(sp)
    80003504:	1000                	addi	s0,sp,32
    80003506:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003508:	00014517          	auipc	a0,0x14
    8000350c:	40050513          	addi	a0,a0,1024 # 80017908 <bcache>
    80003510:	ffffd097          	auipc	ra,0xffffd
    80003514:	6d4080e7          	jalr	1748(ra) # 80000be4 <acquire>
  b->refcnt--;
    80003518:	40bc                	lw	a5,64(s1)
    8000351a:	37fd                	addiw	a5,a5,-1
    8000351c:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    8000351e:	00014517          	auipc	a0,0x14
    80003522:	3ea50513          	addi	a0,a0,1002 # 80017908 <bcache>
    80003526:	ffffd097          	auipc	ra,0xffffd
    8000352a:	772080e7          	jalr	1906(ra) # 80000c98 <release>
}
    8000352e:	60e2                	ld	ra,24(sp)
    80003530:	6442                	ld	s0,16(sp)
    80003532:	64a2                	ld	s1,8(sp)
    80003534:	6105                	addi	sp,sp,32
    80003536:	8082                	ret

0000000080003538 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80003538:	1101                	addi	sp,sp,-32
    8000353a:	ec06                	sd	ra,24(sp)
    8000353c:	e822                	sd	s0,16(sp)
    8000353e:	e426                	sd	s1,8(sp)
    80003540:	e04a                	sd	s2,0(sp)
    80003542:	1000                	addi	s0,sp,32
    80003544:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80003546:	00d5d59b          	srliw	a1,a1,0xd
    8000354a:	0001d797          	auipc	a5,0x1d
    8000354e:	a9a7a783          	lw	a5,-1382(a5) # 8001ffe4 <sb+0x1c>
    80003552:	9dbd                	addw	a1,a1,a5
    80003554:	00000097          	auipc	ra,0x0
    80003558:	d9e080e7          	jalr	-610(ra) # 800032f2 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    8000355c:	0074f713          	andi	a4,s1,7
    80003560:	4785                	li	a5,1
    80003562:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80003566:	14ce                	slli	s1,s1,0x33
    80003568:	90d9                	srli	s1,s1,0x36
    8000356a:	00950733          	add	a4,a0,s1
    8000356e:	05874703          	lbu	a4,88(a4)
    80003572:	00e7f6b3          	and	a3,a5,a4
    80003576:	c69d                	beqz	a3,800035a4 <bfree+0x6c>
    80003578:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    8000357a:	94aa                	add	s1,s1,a0
    8000357c:	fff7c793          	not	a5,a5
    80003580:	8ff9                	and	a5,a5,a4
    80003582:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    80003586:	00001097          	auipc	ra,0x1
    8000358a:	118080e7          	jalr	280(ra) # 8000469e <log_write>
  brelse(bp);
    8000358e:	854a                	mv	a0,s2
    80003590:	00000097          	auipc	ra,0x0
    80003594:	e92080e7          	jalr	-366(ra) # 80003422 <brelse>
}
    80003598:	60e2                	ld	ra,24(sp)
    8000359a:	6442                	ld	s0,16(sp)
    8000359c:	64a2                	ld	s1,8(sp)
    8000359e:	6902                	ld	s2,0(sp)
    800035a0:	6105                	addi	sp,sp,32
    800035a2:	8082                	ret
    panic("freeing free block");
    800035a4:	00005517          	auipc	a0,0x5
    800035a8:	fec50513          	addi	a0,a0,-20 # 80008590 <syscalls+0xf8>
    800035ac:	ffffd097          	auipc	ra,0xffffd
    800035b0:	f92080e7          	jalr	-110(ra) # 8000053e <panic>

00000000800035b4 <balloc>:
{
    800035b4:	711d                	addi	sp,sp,-96
    800035b6:	ec86                	sd	ra,88(sp)
    800035b8:	e8a2                	sd	s0,80(sp)
    800035ba:	e4a6                	sd	s1,72(sp)
    800035bc:	e0ca                	sd	s2,64(sp)
    800035be:	fc4e                	sd	s3,56(sp)
    800035c0:	f852                	sd	s4,48(sp)
    800035c2:	f456                	sd	s5,40(sp)
    800035c4:	f05a                	sd	s6,32(sp)
    800035c6:	ec5e                	sd	s7,24(sp)
    800035c8:	e862                	sd	s8,16(sp)
    800035ca:	e466                	sd	s9,8(sp)
    800035cc:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    800035ce:	0001d797          	auipc	a5,0x1d
    800035d2:	9fe7a783          	lw	a5,-1538(a5) # 8001ffcc <sb+0x4>
    800035d6:	cbd1                	beqz	a5,8000366a <balloc+0xb6>
    800035d8:	8baa                	mv	s7,a0
    800035da:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    800035dc:	0001db17          	auipc	s6,0x1d
    800035e0:	9ecb0b13          	addi	s6,s6,-1556 # 8001ffc8 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800035e4:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    800035e6:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800035e8:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    800035ea:	6c89                	lui	s9,0x2
    800035ec:	a831                	j	80003608 <balloc+0x54>
    brelse(bp);
    800035ee:	854a                	mv	a0,s2
    800035f0:	00000097          	auipc	ra,0x0
    800035f4:	e32080e7          	jalr	-462(ra) # 80003422 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    800035f8:	015c87bb          	addw	a5,s9,s5
    800035fc:	00078a9b          	sext.w	s5,a5
    80003600:	004b2703          	lw	a4,4(s6)
    80003604:	06eaf363          	bgeu	s5,a4,8000366a <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    80003608:	41fad79b          	sraiw	a5,s5,0x1f
    8000360c:	0137d79b          	srliw	a5,a5,0x13
    80003610:	015787bb          	addw	a5,a5,s5
    80003614:	40d7d79b          	sraiw	a5,a5,0xd
    80003618:	01cb2583          	lw	a1,28(s6)
    8000361c:	9dbd                	addw	a1,a1,a5
    8000361e:	855e                	mv	a0,s7
    80003620:	00000097          	auipc	ra,0x0
    80003624:	cd2080e7          	jalr	-814(ra) # 800032f2 <bread>
    80003628:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000362a:	004b2503          	lw	a0,4(s6)
    8000362e:	000a849b          	sext.w	s1,s5
    80003632:	8662                	mv	a2,s8
    80003634:	faa4fde3          	bgeu	s1,a0,800035ee <balloc+0x3a>
      m = 1 << (bi % 8);
    80003638:	41f6579b          	sraiw	a5,a2,0x1f
    8000363c:	01d7d69b          	srliw	a3,a5,0x1d
    80003640:	00c6873b          	addw	a4,a3,a2
    80003644:	00777793          	andi	a5,a4,7
    80003648:	9f95                	subw	a5,a5,a3
    8000364a:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    8000364e:	4037571b          	sraiw	a4,a4,0x3
    80003652:	00e906b3          	add	a3,s2,a4
    80003656:	0586c683          	lbu	a3,88(a3)
    8000365a:	00d7f5b3          	and	a1,a5,a3
    8000365e:	cd91                	beqz	a1,8000367a <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003660:	2605                	addiw	a2,a2,1
    80003662:	2485                	addiw	s1,s1,1
    80003664:	fd4618e3          	bne	a2,s4,80003634 <balloc+0x80>
    80003668:	b759                	j	800035ee <balloc+0x3a>
  panic("balloc: out of blocks");
    8000366a:	00005517          	auipc	a0,0x5
    8000366e:	f3e50513          	addi	a0,a0,-194 # 800085a8 <syscalls+0x110>
    80003672:	ffffd097          	auipc	ra,0xffffd
    80003676:	ecc080e7          	jalr	-308(ra) # 8000053e <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    8000367a:	974a                	add	a4,a4,s2
    8000367c:	8fd5                	or	a5,a5,a3
    8000367e:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    80003682:	854a                	mv	a0,s2
    80003684:	00001097          	auipc	ra,0x1
    80003688:	01a080e7          	jalr	26(ra) # 8000469e <log_write>
        brelse(bp);
    8000368c:	854a                	mv	a0,s2
    8000368e:	00000097          	auipc	ra,0x0
    80003692:	d94080e7          	jalr	-620(ra) # 80003422 <brelse>
  bp = bread(dev, bno);
    80003696:	85a6                	mv	a1,s1
    80003698:	855e                	mv	a0,s7
    8000369a:	00000097          	auipc	ra,0x0
    8000369e:	c58080e7          	jalr	-936(ra) # 800032f2 <bread>
    800036a2:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    800036a4:	40000613          	li	a2,1024
    800036a8:	4581                	li	a1,0
    800036aa:	05850513          	addi	a0,a0,88
    800036ae:	ffffd097          	auipc	ra,0xffffd
    800036b2:	632080e7          	jalr	1586(ra) # 80000ce0 <memset>
  log_write(bp);
    800036b6:	854a                	mv	a0,s2
    800036b8:	00001097          	auipc	ra,0x1
    800036bc:	fe6080e7          	jalr	-26(ra) # 8000469e <log_write>
  brelse(bp);
    800036c0:	854a                	mv	a0,s2
    800036c2:	00000097          	auipc	ra,0x0
    800036c6:	d60080e7          	jalr	-672(ra) # 80003422 <brelse>
}
    800036ca:	8526                	mv	a0,s1
    800036cc:	60e6                	ld	ra,88(sp)
    800036ce:	6446                	ld	s0,80(sp)
    800036d0:	64a6                	ld	s1,72(sp)
    800036d2:	6906                	ld	s2,64(sp)
    800036d4:	79e2                	ld	s3,56(sp)
    800036d6:	7a42                	ld	s4,48(sp)
    800036d8:	7aa2                	ld	s5,40(sp)
    800036da:	7b02                	ld	s6,32(sp)
    800036dc:	6be2                	ld	s7,24(sp)
    800036de:	6c42                	ld	s8,16(sp)
    800036e0:	6ca2                	ld	s9,8(sp)
    800036e2:	6125                	addi	sp,sp,96
    800036e4:	8082                	ret

00000000800036e6 <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    800036e6:	7179                	addi	sp,sp,-48
    800036e8:	f406                	sd	ra,40(sp)
    800036ea:	f022                	sd	s0,32(sp)
    800036ec:	ec26                	sd	s1,24(sp)
    800036ee:	e84a                	sd	s2,16(sp)
    800036f0:	e44e                	sd	s3,8(sp)
    800036f2:	e052                	sd	s4,0(sp)
    800036f4:	1800                	addi	s0,sp,48
    800036f6:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    800036f8:	47ad                	li	a5,11
    800036fa:	04b7fe63          	bgeu	a5,a1,80003756 <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    800036fe:	ff45849b          	addiw	s1,a1,-12
    80003702:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003706:	0ff00793          	li	a5,255
    8000370a:	0ae7e363          	bltu	a5,a4,800037b0 <bmap+0xca>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    8000370e:	08052583          	lw	a1,128(a0)
    80003712:	c5ad                	beqz	a1,8000377c <bmap+0x96>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    80003714:	00092503          	lw	a0,0(s2)
    80003718:	00000097          	auipc	ra,0x0
    8000371c:	bda080e7          	jalr	-1062(ra) # 800032f2 <bread>
    80003720:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003722:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003726:	02049593          	slli	a1,s1,0x20
    8000372a:	9181                	srli	a1,a1,0x20
    8000372c:	058a                	slli	a1,a1,0x2
    8000372e:	00b784b3          	add	s1,a5,a1
    80003732:	0004a983          	lw	s3,0(s1)
    80003736:	04098d63          	beqz	s3,80003790 <bmap+0xaa>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    8000373a:	8552                	mv	a0,s4
    8000373c:	00000097          	auipc	ra,0x0
    80003740:	ce6080e7          	jalr	-794(ra) # 80003422 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80003744:	854e                	mv	a0,s3
    80003746:	70a2                	ld	ra,40(sp)
    80003748:	7402                	ld	s0,32(sp)
    8000374a:	64e2                	ld	s1,24(sp)
    8000374c:	6942                	ld	s2,16(sp)
    8000374e:	69a2                	ld	s3,8(sp)
    80003750:	6a02                	ld	s4,0(sp)
    80003752:	6145                	addi	sp,sp,48
    80003754:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    80003756:	02059493          	slli	s1,a1,0x20
    8000375a:	9081                	srli	s1,s1,0x20
    8000375c:	048a                	slli	s1,s1,0x2
    8000375e:	94aa                	add	s1,s1,a0
    80003760:	0504a983          	lw	s3,80(s1)
    80003764:	fe0990e3          	bnez	s3,80003744 <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    80003768:	4108                	lw	a0,0(a0)
    8000376a:	00000097          	auipc	ra,0x0
    8000376e:	e4a080e7          	jalr	-438(ra) # 800035b4 <balloc>
    80003772:	0005099b          	sext.w	s3,a0
    80003776:	0534a823          	sw	s3,80(s1)
    8000377a:	b7e9                	j	80003744 <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    8000377c:	4108                	lw	a0,0(a0)
    8000377e:	00000097          	auipc	ra,0x0
    80003782:	e36080e7          	jalr	-458(ra) # 800035b4 <balloc>
    80003786:	0005059b          	sext.w	a1,a0
    8000378a:	08b92023          	sw	a1,128(s2)
    8000378e:	b759                	j	80003714 <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    80003790:	00092503          	lw	a0,0(s2)
    80003794:	00000097          	auipc	ra,0x0
    80003798:	e20080e7          	jalr	-480(ra) # 800035b4 <balloc>
    8000379c:	0005099b          	sext.w	s3,a0
    800037a0:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    800037a4:	8552                	mv	a0,s4
    800037a6:	00001097          	auipc	ra,0x1
    800037aa:	ef8080e7          	jalr	-264(ra) # 8000469e <log_write>
    800037ae:	b771                	j	8000373a <bmap+0x54>
  panic("bmap: out of range");
    800037b0:	00005517          	auipc	a0,0x5
    800037b4:	e1050513          	addi	a0,a0,-496 # 800085c0 <syscalls+0x128>
    800037b8:	ffffd097          	auipc	ra,0xffffd
    800037bc:	d86080e7          	jalr	-634(ra) # 8000053e <panic>

00000000800037c0 <iget>:
{
    800037c0:	7179                	addi	sp,sp,-48
    800037c2:	f406                	sd	ra,40(sp)
    800037c4:	f022                	sd	s0,32(sp)
    800037c6:	ec26                	sd	s1,24(sp)
    800037c8:	e84a                	sd	s2,16(sp)
    800037ca:	e44e                	sd	s3,8(sp)
    800037cc:	e052                	sd	s4,0(sp)
    800037ce:	1800                	addi	s0,sp,48
    800037d0:	89aa                	mv	s3,a0
    800037d2:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    800037d4:	0001d517          	auipc	a0,0x1d
    800037d8:	81450513          	addi	a0,a0,-2028 # 8001ffe8 <itable>
    800037dc:	ffffd097          	auipc	ra,0xffffd
    800037e0:	408080e7          	jalr	1032(ra) # 80000be4 <acquire>
  empty = 0;
    800037e4:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800037e6:	0001d497          	auipc	s1,0x1d
    800037ea:	81a48493          	addi	s1,s1,-2022 # 80020000 <itable+0x18>
    800037ee:	0001e697          	auipc	a3,0x1e
    800037f2:	2a268693          	addi	a3,a3,674 # 80021a90 <log>
    800037f6:	a039                	j	80003804 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800037f8:	02090b63          	beqz	s2,8000382e <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800037fc:	08848493          	addi	s1,s1,136
    80003800:	02d48a63          	beq	s1,a3,80003834 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003804:	449c                	lw	a5,8(s1)
    80003806:	fef059e3          	blez	a5,800037f8 <iget+0x38>
    8000380a:	4098                	lw	a4,0(s1)
    8000380c:	ff3716e3          	bne	a4,s3,800037f8 <iget+0x38>
    80003810:	40d8                	lw	a4,4(s1)
    80003812:	ff4713e3          	bne	a4,s4,800037f8 <iget+0x38>
      ip->ref++;
    80003816:	2785                	addiw	a5,a5,1
    80003818:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    8000381a:	0001c517          	auipc	a0,0x1c
    8000381e:	7ce50513          	addi	a0,a0,1998 # 8001ffe8 <itable>
    80003822:	ffffd097          	auipc	ra,0xffffd
    80003826:	476080e7          	jalr	1142(ra) # 80000c98 <release>
      return ip;
    8000382a:	8926                	mv	s2,s1
    8000382c:	a03d                	j	8000385a <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    8000382e:	f7f9                	bnez	a5,800037fc <iget+0x3c>
    80003830:	8926                	mv	s2,s1
    80003832:	b7e9                	j	800037fc <iget+0x3c>
  if(empty == 0)
    80003834:	02090c63          	beqz	s2,8000386c <iget+0xac>
  ip->dev = dev;
    80003838:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    8000383c:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003840:	4785                	li	a5,1
    80003842:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003846:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    8000384a:	0001c517          	auipc	a0,0x1c
    8000384e:	79e50513          	addi	a0,a0,1950 # 8001ffe8 <itable>
    80003852:	ffffd097          	auipc	ra,0xffffd
    80003856:	446080e7          	jalr	1094(ra) # 80000c98 <release>
}
    8000385a:	854a                	mv	a0,s2
    8000385c:	70a2                	ld	ra,40(sp)
    8000385e:	7402                	ld	s0,32(sp)
    80003860:	64e2                	ld	s1,24(sp)
    80003862:	6942                	ld	s2,16(sp)
    80003864:	69a2                	ld	s3,8(sp)
    80003866:	6a02                	ld	s4,0(sp)
    80003868:	6145                	addi	sp,sp,48
    8000386a:	8082                	ret
    panic("iget: no inodes");
    8000386c:	00005517          	auipc	a0,0x5
    80003870:	d6c50513          	addi	a0,a0,-660 # 800085d8 <syscalls+0x140>
    80003874:	ffffd097          	auipc	ra,0xffffd
    80003878:	cca080e7          	jalr	-822(ra) # 8000053e <panic>

000000008000387c <fsinit>:
fsinit(int dev) {
    8000387c:	7179                	addi	sp,sp,-48
    8000387e:	f406                	sd	ra,40(sp)
    80003880:	f022                	sd	s0,32(sp)
    80003882:	ec26                	sd	s1,24(sp)
    80003884:	e84a                	sd	s2,16(sp)
    80003886:	e44e                	sd	s3,8(sp)
    80003888:	1800                	addi	s0,sp,48
    8000388a:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    8000388c:	4585                	li	a1,1
    8000388e:	00000097          	auipc	ra,0x0
    80003892:	a64080e7          	jalr	-1436(ra) # 800032f2 <bread>
    80003896:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003898:	0001c997          	auipc	s3,0x1c
    8000389c:	73098993          	addi	s3,s3,1840 # 8001ffc8 <sb>
    800038a0:	02000613          	li	a2,32
    800038a4:	05850593          	addi	a1,a0,88
    800038a8:	854e                	mv	a0,s3
    800038aa:	ffffd097          	auipc	ra,0xffffd
    800038ae:	496080e7          	jalr	1174(ra) # 80000d40 <memmove>
  brelse(bp);
    800038b2:	8526                	mv	a0,s1
    800038b4:	00000097          	auipc	ra,0x0
    800038b8:	b6e080e7          	jalr	-1170(ra) # 80003422 <brelse>
  if(sb.magic != FSMAGIC)
    800038bc:	0009a703          	lw	a4,0(s3)
    800038c0:	102037b7          	lui	a5,0x10203
    800038c4:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    800038c8:	02f71263          	bne	a4,a5,800038ec <fsinit+0x70>
  initlog(dev, &sb);
    800038cc:	0001c597          	auipc	a1,0x1c
    800038d0:	6fc58593          	addi	a1,a1,1788 # 8001ffc8 <sb>
    800038d4:	854a                	mv	a0,s2
    800038d6:	00001097          	auipc	ra,0x1
    800038da:	b4c080e7          	jalr	-1204(ra) # 80004422 <initlog>
}
    800038de:	70a2                	ld	ra,40(sp)
    800038e0:	7402                	ld	s0,32(sp)
    800038e2:	64e2                	ld	s1,24(sp)
    800038e4:	6942                	ld	s2,16(sp)
    800038e6:	69a2                	ld	s3,8(sp)
    800038e8:	6145                	addi	sp,sp,48
    800038ea:	8082                	ret
    panic("invalid file system");
    800038ec:	00005517          	auipc	a0,0x5
    800038f0:	cfc50513          	addi	a0,a0,-772 # 800085e8 <syscalls+0x150>
    800038f4:	ffffd097          	auipc	ra,0xffffd
    800038f8:	c4a080e7          	jalr	-950(ra) # 8000053e <panic>

00000000800038fc <iinit>:
{
    800038fc:	7179                	addi	sp,sp,-48
    800038fe:	f406                	sd	ra,40(sp)
    80003900:	f022                	sd	s0,32(sp)
    80003902:	ec26                	sd	s1,24(sp)
    80003904:	e84a                	sd	s2,16(sp)
    80003906:	e44e                	sd	s3,8(sp)
    80003908:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    8000390a:	00005597          	auipc	a1,0x5
    8000390e:	cf658593          	addi	a1,a1,-778 # 80008600 <syscalls+0x168>
    80003912:	0001c517          	auipc	a0,0x1c
    80003916:	6d650513          	addi	a0,a0,1750 # 8001ffe8 <itable>
    8000391a:	ffffd097          	auipc	ra,0xffffd
    8000391e:	23a080e7          	jalr	570(ra) # 80000b54 <initlock>
  for(i = 0; i < NINODE; i++) {
    80003922:	0001c497          	auipc	s1,0x1c
    80003926:	6ee48493          	addi	s1,s1,1774 # 80020010 <itable+0x28>
    8000392a:	0001e997          	auipc	s3,0x1e
    8000392e:	17698993          	addi	s3,s3,374 # 80021aa0 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80003932:	00005917          	auipc	s2,0x5
    80003936:	cd690913          	addi	s2,s2,-810 # 80008608 <syscalls+0x170>
    8000393a:	85ca                	mv	a1,s2
    8000393c:	8526                	mv	a0,s1
    8000393e:	00001097          	auipc	ra,0x1
    80003942:	e46080e7          	jalr	-442(ra) # 80004784 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003946:	08848493          	addi	s1,s1,136
    8000394a:	ff3498e3          	bne	s1,s3,8000393a <iinit+0x3e>
}
    8000394e:	70a2                	ld	ra,40(sp)
    80003950:	7402                	ld	s0,32(sp)
    80003952:	64e2                	ld	s1,24(sp)
    80003954:	6942                	ld	s2,16(sp)
    80003956:	69a2                	ld	s3,8(sp)
    80003958:	6145                	addi	sp,sp,48
    8000395a:	8082                	ret

000000008000395c <ialloc>:
{
    8000395c:	715d                	addi	sp,sp,-80
    8000395e:	e486                	sd	ra,72(sp)
    80003960:	e0a2                	sd	s0,64(sp)
    80003962:	fc26                	sd	s1,56(sp)
    80003964:	f84a                	sd	s2,48(sp)
    80003966:	f44e                	sd	s3,40(sp)
    80003968:	f052                	sd	s4,32(sp)
    8000396a:	ec56                	sd	s5,24(sp)
    8000396c:	e85a                	sd	s6,16(sp)
    8000396e:	e45e                	sd	s7,8(sp)
    80003970:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003972:	0001c717          	auipc	a4,0x1c
    80003976:	66272703          	lw	a4,1634(a4) # 8001ffd4 <sb+0xc>
    8000397a:	4785                	li	a5,1
    8000397c:	04e7fa63          	bgeu	a5,a4,800039d0 <ialloc+0x74>
    80003980:	8aaa                	mv	s5,a0
    80003982:	8bae                	mv	s7,a1
    80003984:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003986:	0001ca17          	auipc	s4,0x1c
    8000398a:	642a0a13          	addi	s4,s4,1602 # 8001ffc8 <sb>
    8000398e:	00048b1b          	sext.w	s6,s1
    80003992:	0044d593          	srli	a1,s1,0x4
    80003996:	018a2783          	lw	a5,24(s4)
    8000399a:	9dbd                	addw	a1,a1,a5
    8000399c:	8556                	mv	a0,s5
    8000399e:	00000097          	auipc	ra,0x0
    800039a2:	954080e7          	jalr	-1708(ra) # 800032f2 <bread>
    800039a6:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    800039a8:	05850993          	addi	s3,a0,88
    800039ac:	00f4f793          	andi	a5,s1,15
    800039b0:	079a                	slli	a5,a5,0x6
    800039b2:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    800039b4:	00099783          	lh	a5,0(s3)
    800039b8:	c785                	beqz	a5,800039e0 <ialloc+0x84>
    brelse(bp);
    800039ba:	00000097          	auipc	ra,0x0
    800039be:	a68080e7          	jalr	-1432(ra) # 80003422 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    800039c2:	0485                	addi	s1,s1,1
    800039c4:	00ca2703          	lw	a4,12(s4)
    800039c8:	0004879b          	sext.w	a5,s1
    800039cc:	fce7e1e3          	bltu	a5,a4,8000398e <ialloc+0x32>
  panic("ialloc: no inodes");
    800039d0:	00005517          	auipc	a0,0x5
    800039d4:	c4050513          	addi	a0,a0,-960 # 80008610 <syscalls+0x178>
    800039d8:	ffffd097          	auipc	ra,0xffffd
    800039dc:	b66080e7          	jalr	-1178(ra) # 8000053e <panic>
      memset(dip, 0, sizeof(*dip));
    800039e0:	04000613          	li	a2,64
    800039e4:	4581                	li	a1,0
    800039e6:	854e                	mv	a0,s3
    800039e8:	ffffd097          	auipc	ra,0xffffd
    800039ec:	2f8080e7          	jalr	760(ra) # 80000ce0 <memset>
      dip->type = type;
    800039f0:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    800039f4:	854a                	mv	a0,s2
    800039f6:	00001097          	auipc	ra,0x1
    800039fa:	ca8080e7          	jalr	-856(ra) # 8000469e <log_write>
      brelse(bp);
    800039fe:	854a                	mv	a0,s2
    80003a00:	00000097          	auipc	ra,0x0
    80003a04:	a22080e7          	jalr	-1502(ra) # 80003422 <brelse>
      return iget(dev, inum);
    80003a08:	85da                	mv	a1,s6
    80003a0a:	8556                	mv	a0,s5
    80003a0c:	00000097          	auipc	ra,0x0
    80003a10:	db4080e7          	jalr	-588(ra) # 800037c0 <iget>
}
    80003a14:	60a6                	ld	ra,72(sp)
    80003a16:	6406                	ld	s0,64(sp)
    80003a18:	74e2                	ld	s1,56(sp)
    80003a1a:	7942                	ld	s2,48(sp)
    80003a1c:	79a2                	ld	s3,40(sp)
    80003a1e:	7a02                	ld	s4,32(sp)
    80003a20:	6ae2                	ld	s5,24(sp)
    80003a22:	6b42                	ld	s6,16(sp)
    80003a24:	6ba2                	ld	s7,8(sp)
    80003a26:	6161                	addi	sp,sp,80
    80003a28:	8082                	ret

0000000080003a2a <iupdate>:
{
    80003a2a:	1101                	addi	sp,sp,-32
    80003a2c:	ec06                	sd	ra,24(sp)
    80003a2e:	e822                	sd	s0,16(sp)
    80003a30:	e426                	sd	s1,8(sp)
    80003a32:	e04a                	sd	s2,0(sp)
    80003a34:	1000                	addi	s0,sp,32
    80003a36:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003a38:	415c                	lw	a5,4(a0)
    80003a3a:	0047d79b          	srliw	a5,a5,0x4
    80003a3e:	0001c597          	auipc	a1,0x1c
    80003a42:	5a25a583          	lw	a1,1442(a1) # 8001ffe0 <sb+0x18>
    80003a46:	9dbd                	addw	a1,a1,a5
    80003a48:	4108                	lw	a0,0(a0)
    80003a4a:	00000097          	auipc	ra,0x0
    80003a4e:	8a8080e7          	jalr	-1880(ra) # 800032f2 <bread>
    80003a52:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003a54:	05850793          	addi	a5,a0,88
    80003a58:	40c8                	lw	a0,4(s1)
    80003a5a:	893d                	andi	a0,a0,15
    80003a5c:	051a                	slli	a0,a0,0x6
    80003a5e:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    80003a60:	04449703          	lh	a4,68(s1)
    80003a64:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    80003a68:	04649703          	lh	a4,70(s1)
    80003a6c:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    80003a70:	04849703          	lh	a4,72(s1)
    80003a74:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    80003a78:	04a49703          	lh	a4,74(s1)
    80003a7c:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    80003a80:	44f8                	lw	a4,76(s1)
    80003a82:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003a84:	03400613          	li	a2,52
    80003a88:	05048593          	addi	a1,s1,80
    80003a8c:	0531                	addi	a0,a0,12
    80003a8e:	ffffd097          	auipc	ra,0xffffd
    80003a92:	2b2080e7          	jalr	690(ra) # 80000d40 <memmove>
  log_write(bp);
    80003a96:	854a                	mv	a0,s2
    80003a98:	00001097          	auipc	ra,0x1
    80003a9c:	c06080e7          	jalr	-1018(ra) # 8000469e <log_write>
  brelse(bp);
    80003aa0:	854a                	mv	a0,s2
    80003aa2:	00000097          	auipc	ra,0x0
    80003aa6:	980080e7          	jalr	-1664(ra) # 80003422 <brelse>
}
    80003aaa:	60e2                	ld	ra,24(sp)
    80003aac:	6442                	ld	s0,16(sp)
    80003aae:	64a2                	ld	s1,8(sp)
    80003ab0:	6902                	ld	s2,0(sp)
    80003ab2:	6105                	addi	sp,sp,32
    80003ab4:	8082                	ret

0000000080003ab6 <idup>:
{
    80003ab6:	1101                	addi	sp,sp,-32
    80003ab8:	ec06                	sd	ra,24(sp)
    80003aba:	e822                	sd	s0,16(sp)
    80003abc:	e426                	sd	s1,8(sp)
    80003abe:	1000                	addi	s0,sp,32
    80003ac0:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003ac2:	0001c517          	auipc	a0,0x1c
    80003ac6:	52650513          	addi	a0,a0,1318 # 8001ffe8 <itable>
    80003aca:	ffffd097          	auipc	ra,0xffffd
    80003ace:	11a080e7          	jalr	282(ra) # 80000be4 <acquire>
  ip->ref++;
    80003ad2:	449c                	lw	a5,8(s1)
    80003ad4:	2785                	addiw	a5,a5,1
    80003ad6:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003ad8:	0001c517          	auipc	a0,0x1c
    80003adc:	51050513          	addi	a0,a0,1296 # 8001ffe8 <itable>
    80003ae0:	ffffd097          	auipc	ra,0xffffd
    80003ae4:	1b8080e7          	jalr	440(ra) # 80000c98 <release>
}
    80003ae8:	8526                	mv	a0,s1
    80003aea:	60e2                	ld	ra,24(sp)
    80003aec:	6442                	ld	s0,16(sp)
    80003aee:	64a2                	ld	s1,8(sp)
    80003af0:	6105                	addi	sp,sp,32
    80003af2:	8082                	ret

0000000080003af4 <ilock>:
{
    80003af4:	1101                	addi	sp,sp,-32
    80003af6:	ec06                	sd	ra,24(sp)
    80003af8:	e822                	sd	s0,16(sp)
    80003afa:	e426                	sd	s1,8(sp)
    80003afc:	e04a                	sd	s2,0(sp)
    80003afe:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003b00:	c115                	beqz	a0,80003b24 <ilock+0x30>
    80003b02:	84aa                	mv	s1,a0
    80003b04:	451c                	lw	a5,8(a0)
    80003b06:	00f05f63          	blez	a5,80003b24 <ilock+0x30>
  acquiresleep(&ip->lock);
    80003b0a:	0541                	addi	a0,a0,16
    80003b0c:	00001097          	auipc	ra,0x1
    80003b10:	cb2080e7          	jalr	-846(ra) # 800047be <acquiresleep>
  if(ip->valid == 0){
    80003b14:	40bc                	lw	a5,64(s1)
    80003b16:	cf99                	beqz	a5,80003b34 <ilock+0x40>
}
    80003b18:	60e2                	ld	ra,24(sp)
    80003b1a:	6442                	ld	s0,16(sp)
    80003b1c:	64a2                	ld	s1,8(sp)
    80003b1e:	6902                	ld	s2,0(sp)
    80003b20:	6105                	addi	sp,sp,32
    80003b22:	8082                	ret
    panic("ilock");
    80003b24:	00005517          	auipc	a0,0x5
    80003b28:	b0450513          	addi	a0,a0,-1276 # 80008628 <syscalls+0x190>
    80003b2c:	ffffd097          	auipc	ra,0xffffd
    80003b30:	a12080e7          	jalr	-1518(ra) # 8000053e <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003b34:	40dc                	lw	a5,4(s1)
    80003b36:	0047d79b          	srliw	a5,a5,0x4
    80003b3a:	0001c597          	auipc	a1,0x1c
    80003b3e:	4a65a583          	lw	a1,1190(a1) # 8001ffe0 <sb+0x18>
    80003b42:	9dbd                	addw	a1,a1,a5
    80003b44:	4088                	lw	a0,0(s1)
    80003b46:	fffff097          	auipc	ra,0xfffff
    80003b4a:	7ac080e7          	jalr	1964(ra) # 800032f2 <bread>
    80003b4e:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003b50:	05850593          	addi	a1,a0,88
    80003b54:	40dc                	lw	a5,4(s1)
    80003b56:	8bbd                	andi	a5,a5,15
    80003b58:	079a                	slli	a5,a5,0x6
    80003b5a:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003b5c:	00059783          	lh	a5,0(a1)
    80003b60:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003b64:	00259783          	lh	a5,2(a1)
    80003b68:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003b6c:	00459783          	lh	a5,4(a1)
    80003b70:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003b74:	00659783          	lh	a5,6(a1)
    80003b78:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003b7c:	459c                	lw	a5,8(a1)
    80003b7e:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003b80:	03400613          	li	a2,52
    80003b84:	05b1                	addi	a1,a1,12
    80003b86:	05048513          	addi	a0,s1,80
    80003b8a:	ffffd097          	auipc	ra,0xffffd
    80003b8e:	1b6080e7          	jalr	438(ra) # 80000d40 <memmove>
    brelse(bp);
    80003b92:	854a                	mv	a0,s2
    80003b94:	00000097          	auipc	ra,0x0
    80003b98:	88e080e7          	jalr	-1906(ra) # 80003422 <brelse>
    ip->valid = 1;
    80003b9c:	4785                	li	a5,1
    80003b9e:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003ba0:	04449783          	lh	a5,68(s1)
    80003ba4:	fbb5                	bnez	a5,80003b18 <ilock+0x24>
      panic("ilock: no type");
    80003ba6:	00005517          	auipc	a0,0x5
    80003baa:	a8a50513          	addi	a0,a0,-1398 # 80008630 <syscalls+0x198>
    80003bae:	ffffd097          	auipc	ra,0xffffd
    80003bb2:	990080e7          	jalr	-1648(ra) # 8000053e <panic>

0000000080003bb6 <iunlock>:
{
    80003bb6:	1101                	addi	sp,sp,-32
    80003bb8:	ec06                	sd	ra,24(sp)
    80003bba:	e822                	sd	s0,16(sp)
    80003bbc:	e426                	sd	s1,8(sp)
    80003bbe:	e04a                	sd	s2,0(sp)
    80003bc0:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003bc2:	c905                	beqz	a0,80003bf2 <iunlock+0x3c>
    80003bc4:	84aa                	mv	s1,a0
    80003bc6:	01050913          	addi	s2,a0,16
    80003bca:	854a                	mv	a0,s2
    80003bcc:	00001097          	auipc	ra,0x1
    80003bd0:	c8c080e7          	jalr	-884(ra) # 80004858 <holdingsleep>
    80003bd4:	cd19                	beqz	a0,80003bf2 <iunlock+0x3c>
    80003bd6:	449c                	lw	a5,8(s1)
    80003bd8:	00f05d63          	blez	a5,80003bf2 <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003bdc:	854a                	mv	a0,s2
    80003bde:	00001097          	auipc	ra,0x1
    80003be2:	c36080e7          	jalr	-970(ra) # 80004814 <releasesleep>
}
    80003be6:	60e2                	ld	ra,24(sp)
    80003be8:	6442                	ld	s0,16(sp)
    80003bea:	64a2                	ld	s1,8(sp)
    80003bec:	6902                	ld	s2,0(sp)
    80003bee:	6105                	addi	sp,sp,32
    80003bf0:	8082                	ret
    panic("iunlock");
    80003bf2:	00005517          	auipc	a0,0x5
    80003bf6:	a4e50513          	addi	a0,a0,-1458 # 80008640 <syscalls+0x1a8>
    80003bfa:	ffffd097          	auipc	ra,0xffffd
    80003bfe:	944080e7          	jalr	-1724(ra) # 8000053e <panic>

0000000080003c02 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003c02:	7179                	addi	sp,sp,-48
    80003c04:	f406                	sd	ra,40(sp)
    80003c06:	f022                	sd	s0,32(sp)
    80003c08:	ec26                	sd	s1,24(sp)
    80003c0a:	e84a                	sd	s2,16(sp)
    80003c0c:	e44e                	sd	s3,8(sp)
    80003c0e:	e052                	sd	s4,0(sp)
    80003c10:	1800                	addi	s0,sp,48
    80003c12:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003c14:	05050493          	addi	s1,a0,80
    80003c18:	08050913          	addi	s2,a0,128
    80003c1c:	a021                	j	80003c24 <itrunc+0x22>
    80003c1e:	0491                	addi	s1,s1,4
    80003c20:	01248d63          	beq	s1,s2,80003c3a <itrunc+0x38>
    if(ip->addrs[i]){
    80003c24:	408c                	lw	a1,0(s1)
    80003c26:	dde5                	beqz	a1,80003c1e <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003c28:	0009a503          	lw	a0,0(s3)
    80003c2c:	00000097          	auipc	ra,0x0
    80003c30:	90c080e7          	jalr	-1780(ra) # 80003538 <bfree>
      ip->addrs[i] = 0;
    80003c34:	0004a023          	sw	zero,0(s1)
    80003c38:	b7dd                	j	80003c1e <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003c3a:	0809a583          	lw	a1,128(s3)
    80003c3e:	e185                	bnez	a1,80003c5e <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003c40:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003c44:	854e                	mv	a0,s3
    80003c46:	00000097          	auipc	ra,0x0
    80003c4a:	de4080e7          	jalr	-540(ra) # 80003a2a <iupdate>
}
    80003c4e:	70a2                	ld	ra,40(sp)
    80003c50:	7402                	ld	s0,32(sp)
    80003c52:	64e2                	ld	s1,24(sp)
    80003c54:	6942                	ld	s2,16(sp)
    80003c56:	69a2                	ld	s3,8(sp)
    80003c58:	6a02                	ld	s4,0(sp)
    80003c5a:	6145                	addi	sp,sp,48
    80003c5c:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003c5e:	0009a503          	lw	a0,0(s3)
    80003c62:	fffff097          	auipc	ra,0xfffff
    80003c66:	690080e7          	jalr	1680(ra) # 800032f2 <bread>
    80003c6a:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003c6c:	05850493          	addi	s1,a0,88
    80003c70:	45850913          	addi	s2,a0,1112
    80003c74:	a811                	j	80003c88 <itrunc+0x86>
        bfree(ip->dev, a[j]);
    80003c76:	0009a503          	lw	a0,0(s3)
    80003c7a:	00000097          	auipc	ra,0x0
    80003c7e:	8be080e7          	jalr	-1858(ra) # 80003538 <bfree>
    for(j = 0; j < NINDIRECT; j++){
    80003c82:	0491                	addi	s1,s1,4
    80003c84:	01248563          	beq	s1,s2,80003c8e <itrunc+0x8c>
      if(a[j])
    80003c88:	408c                	lw	a1,0(s1)
    80003c8a:	dde5                	beqz	a1,80003c82 <itrunc+0x80>
    80003c8c:	b7ed                	j	80003c76 <itrunc+0x74>
    brelse(bp);
    80003c8e:	8552                	mv	a0,s4
    80003c90:	fffff097          	auipc	ra,0xfffff
    80003c94:	792080e7          	jalr	1938(ra) # 80003422 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003c98:	0809a583          	lw	a1,128(s3)
    80003c9c:	0009a503          	lw	a0,0(s3)
    80003ca0:	00000097          	auipc	ra,0x0
    80003ca4:	898080e7          	jalr	-1896(ra) # 80003538 <bfree>
    ip->addrs[NDIRECT] = 0;
    80003ca8:	0809a023          	sw	zero,128(s3)
    80003cac:	bf51                	j	80003c40 <itrunc+0x3e>

0000000080003cae <iput>:
{
    80003cae:	1101                	addi	sp,sp,-32
    80003cb0:	ec06                	sd	ra,24(sp)
    80003cb2:	e822                	sd	s0,16(sp)
    80003cb4:	e426                	sd	s1,8(sp)
    80003cb6:	e04a                	sd	s2,0(sp)
    80003cb8:	1000                	addi	s0,sp,32
    80003cba:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003cbc:	0001c517          	auipc	a0,0x1c
    80003cc0:	32c50513          	addi	a0,a0,812 # 8001ffe8 <itable>
    80003cc4:	ffffd097          	auipc	ra,0xffffd
    80003cc8:	f20080e7          	jalr	-224(ra) # 80000be4 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003ccc:	4498                	lw	a4,8(s1)
    80003cce:	4785                	li	a5,1
    80003cd0:	02f70363          	beq	a4,a5,80003cf6 <iput+0x48>
  ip->ref--;
    80003cd4:	449c                	lw	a5,8(s1)
    80003cd6:	37fd                	addiw	a5,a5,-1
    80003cd8:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003cda:	0001c517          	auipc	a0,0x1c
    80003cde:	30e50513          	addi	a0,a0,782 # 8001ffe8 <itable>
    80003ce2:	ffffd097          	auipc	ra,0xffffd
    80003ce6:	fb6080e7          	jalr	-74(ra) # 80000c98 <release>
}
    80003cea:	60e2                	ld	ra,24(sp)
    80003cec:	6442                	ld	s0,16(sp)
    80003cee:	64a2                	ld	s1,8(sp)
    80003cf0:	6902                	ld	s2,0(sp)
    80003cf2:	6105                	addi	sp,sp,32
    80003cf4:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003cf6:	40bc                	lw	a5,64(s1)
    80003cf8:	dff1                	beqz	a5,80003cd4 <iput+0x26>
    80003cfa:	04a49783          	lh	a5,74(s1)
    80003cfe:	fbf9                	bnez	a5,80003cd4 <iput+0x26>
    acquiresleep(&ip->lock);
    80003d00:	01048913          	addi	s2,s1,16
    80003d04:	854a                	mv	a0,s2
    80003d06:	00001097          	auipc	ra,0x1
    80003d0a:	ab8080e7          	jalr	-1352(ra) # 800047be <acquiresleep>
    release(&itable.lock);
    80003d0e:	0001c517          	auipc	a0,0x1c
    80003d12:	2da50513          	addi	a0,a0,730 # 8001ffe8 <itable>
    80003d16:	ffffd097          	auipc	ra,0xffffd
    80003d1a:	f82080e7          	jalr	-126(ra) # 80000c98 <release>
    itrunc(ip);
    80003d1e:	8526                	mv	a0,s1
    80003d20:	00000097          	auipc	ra,0x0
    80003d24:	ee2080e7          	jalr	-286(ra) # 80003c02 <itrunc>
    ip->type = 0;
    80003d28:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003d2c:	8526                	mv	a0,s1
    80003d2e:	00000097          	auipc	ra,0x0
    80003d32:	cfc080e7          	jalr	-772(ra) # 80003a2a <iupdate>
    ip->valid = 0;
    80003d36:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003d3a:	854a                	mv	a0,s2
    80003d3c:	00001097          	auipc	ra,0x1
    80003d40:	ad8080e7          	jalr	-1320(ra) # 80004814 <releasesleep>
    acquire(&itable.lock);
    80003d44:	0001c517          	auipc	a0,0x1c
    80003d48:	2a450513          	addi	a0,a0,676 # 8001ffe8 <itable>
    80003d4c:	ffffd097          	auipc	ra,0xffffd
    80003d50:	e98080e7          	jalr	-360(ra) # 80000be4 <acquire>
    80003d54:	b741                	j	80003cd4 <iput+0x26>

0000000080003d56 <iunlockput>:
{
    80003d56:	1101                	addi	sp,sp,-32
    80003d58:	ec06                	sd	ra,24(sp)
    80003d5a:	e822                	sd	s0,16(sp)
    80003d5c:	e426                	sd	s1,8(sp)
    80003d5e:	1000                	addi	s0,sp,32
    80003d60:	84aa                	mv	s1,a0
  iunlock(ip);
    80003d62:	00000097          	auipc	ra,0x0
    80003d66:	e54080e7          	jalr	-428(ra) # 80003bb6 <iunlock>
  iput(ip);
    80003d6a:	8526                	mv	a0,s1
    80003d6c:	00000097          	auipc	ra,0x0
    80003d70:	f42080e7          	jalr	-190(ra) # 80003cae <iput>
}
    80003d74:	60e2                	ld	ra,24(sp)
    80003d76:	6442                	ld	s0,16(sp)
    80003d78:	64a2                	ld	s1,8(sp)
    80003d7a:	6105                	addi	sp,sp,32
    80003d7c:	8082                	ret

0000000080003d7e <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003d7e:	1141                	addi	sp,sp,-16
    80003d80:	e422                	sd	s0,8(sp)
    80003d82:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003d84:	411c                	lw	a5,0(a0)
    80003d86:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003d88:	415c                	lw	a5,4(a0)
    80003d8a:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003d8c:	04451783          	lh	a5,68(a0)
    80003d90:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003d94:	04a51783          	lh	a5,74(a0)
    80003d98:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003d9c:	04c56783          	lwu	a5,76(a0)
    80003da0:	e99c                	sd	a5,16(a1)
}
    80003da2:	6422                	ld	s0,8(sp)
    80003da4:	0141                	addi	sp,sp,16
    80003da6:	8082                	ret

0000000080003da8 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003da8:	457c                	lw	a5,76(a0)
    80003daa:	0ed7e963          	bltu	a5,a3,80003e9c <readi+0xf4>
{
    80003dae:	7159                	addi	sp,sp,-112
    80003db0:	f486                	sd	ra,104(sp)
    80003db2:	f0a2                	sd	s0,96(sp)
    80003db4:	eca6                	sd	s1,88(sp)
    80003db6:	e8ca                	sd	s2,80(sp)
    80003db8:	e4ce                	sd	s3,72(sp)
    80003dba:	e0d2                	sd	s4,64(sp)
    80003dbc:	fc56                	sd	s5,56(sp)
    80003dbe:	f85a                	sd	s6,48(sp)
    80003dc0:	f45e                	sd	s7,40(sp)
    80003dc2:	f062                	sd	s8,32(sp)
    80003dc4:	ec66                	sd	s9,24(sp)
    80003dc6:	e86a                	sd	s10,16(sp)
    80003dc8:	e46e                	sd	s11,8(sp)
    80003dca:	1880                	addi	s0,sp,112
    80003dcc:	8baa                	mv	s7,a0
    80003dce:	8c2e                	mv	s8,a1
    80003dd0:	8ab2                	mv	s5,a2
    80003dd2:	84b6                	mv	s1,a3
    80003dd4:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003dd6:	9f35                	addw	a4,a4,a3
    return 0;
    80003dd8:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003dda:	0ad76063          	bltu	a4,a3,80003e7a <readi+0xd2>
  if(off + n > ip->size)
    80003dde:	00e7f463          	bgeu	a5,a4,80003de6 <readi+0x3e>
    n = ip->size - off;
    80003de2:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003de6:	0a0b0963          	beqz	s6,80003e98 <readi+0xf0>
    80003dea:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003dec:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003df0:	5cfd                	li	s9,-1
    80003df2:	a82d                	j	80003e2c <readi+0x84>
    80003df4:	020a1d93          	slli	s11,s4,0x20
    80003df8:	020ddd93          	srli	s11,s11,0x20
    80003dfc:	05890613          	addi	a2,s2,88
    80003e00:	86ee                	mv	a3,s11
    80003e02:	963a                	add	a2,a2,a4
    80003e04:	85d6                	mv	a1,s5
    80003e06:	8562                	mv	a0,s8
    80003e08:	fffff097          	auipc	ra,0xfffff
    80003e0c:	ae0080e7          	jalr	-1312(ra) # 800028e8 <either_copyout>
    80003e10:	05950d63          	beq	a0,s9,80003e6a <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003e14:	854a                	mv	a0,s2
    80003e16:	fffff097          	auipc	ra,0xfffff
    80003e1a:	60c080e7          	jalr	1548(ra) # 80003422 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003e1e:	013a09bb          	addw	s3,s4,s3
    80003e22:	009a04bb          	addw	s1,s4,s1
    80003e26:	9aee                	add	s5,s5,s11
    80003e28:	0569f763          	bgeu	s3,s6,80003e76 <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003e2c:	000ba903          	lw	s2,0(s7)
    80003e30:	00a4d59b          	srliw	a1,s1,0xa
    80003e34:	855e                	mv	a0,s7
    80003e36:	00000097          	auipc	ra,0x0
    80003e3a:	8b0080e7          	jalr	-1872(ra) # 800036e6 <bmap>
    80003e3e:	0005059b          	sext.w	a1,a0
    80003e42:	854a                	mv	a0,s2
    80003e44:	fffff097          	auipc	ra,0xfffff
    80003e48:	4ae080e7          	jalr	1198(ra) # 800032f2 <bread>
    80003e4c:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003e4e:	3ff4f713          	andi	a4,s1,1023
    80003e52:	40ed07bb          	subw	a5,s10,a4
    80003e56:	413b06bb          	subw	a3,s6,s3
    80003e5a:	8a3e                	mv	s4,a5
    80003e5c:	2781                	sext.w	a5,a5
    80003e5e:	0006861b          	sext.w	a2,a3
    80003e62:	f8f679e3          	bgeu	a2,a5,80003df4 <readi+0x4c>
    80003e66:	8a36                	mv	s4,a3
    80003e68:	b771                	j	80003df4 <readi+0x4c>
      brelse(bp);
    80003e6a:	854a                	mv	a0,s2
    80003e6c:	fffff097          	auipc	ra,0xfffff
    80003e70:	5b6080e7          	jalr	1462(ra) # 80003422 <brelse>
      tot = -1;
    80003e74:	59fd                	li	s3,-1
  }
  return tot;
    80003e76:	0009851b          	sext.w	a0,s3
}
    80003e7a:	70a6                	ld	ra,104(sp)
    80003e7c:	7406                	ld	s0,96(sp)
    80003e7e:	64e6                	ld	s1,88(sp)
    80003e80:	6946                	ld	s2,80(sp)
    80003e82:	69a6                	ld	s3,72(sp)
    80003e84:	6a06                	ld	s4,64(sp)
    80003e86:	7ae2                	ld	s5,56(sp)
    80003e88:	7b42                	ld	s6,48(sp)
    80003e8a:	7ba2                	ld	s7,40(sp)
    80003e8c:	7c02                	ld	s8,32(sp)
    80003e8e:	6ce2                	ld	s9,24(sp)
    80003e90:	6d42                	ld	s10,16(sp)
    80003e92:	6da2                	ld	s11,8(sp)
    80003e94:	6165                	addi	sp,sp,112
    80003e96:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003e98:	89da                	mv	s3,s6
    80003e9a:	bff1                	j	80003e76 <readi+0xce>
    return 0;
    80003e9c:	4501                	li	a0,0
}
    80003e9e:	8082                	ret

0000000080003ea0 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003ea0:	457c                	lw	a5,76(a0)
    80003ea2:	10d7e863          	bltu	a5,a3,80003fb2 <writei+0x112>
{
    80003ea6:	7159                	addi	sp,sp,-112
    80003ea8:	f486                	sd	ra,104(sp)
    80003eaa:	f0a2                	sd	s0,96(sp)
    80003eac:	eca6                	sd	s1,88(sp)
    80003eae:	e8ca                	sd	s2,80(sp)
    80003eb0:	e4ce                	sd	s3,72(sp)
    80003eb2:	e0d2                	sd	s4,64(sp)
    80003eb4:	fc56                	sd	s5,56(sp)
    80003eb6:	f85a                	sd	s6,48(sp)
    80003eb8:	f45e                	sd	s7,40(sp)
    80003eba:	f062                	sd	s8,32(sp)
    80003ebc:	ec66                	sd	s9,24(sp)
    80003ebe:	e86a                	sd	s10,16(sp)
    80003ec0:	e46e                	sd	s11,8(sp)
    80003ec2:	1880                	addi	s0,sp,112
    80003ec4:	8b2a                	mv	s6,a0
    80003ec6:	8c2e                	mv	s8,a1
    80003ec8:	8ab2                	mv	s5,a2
    80003eca:	8936                	mv	s2,a3
    80003ecc:	8bba                	mv	s7,a4
  if(off > ip->size || off + n < off)
    80003ece:	00e687bb          	addw	a5,a3,a4
    80003ed2:	0ed7e263          	bltu	a5,a3,80003fb6 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003ed6:	00043737          	lui	a4,0x43
    80003eda:	0ef76063          	bltu	a4,a5,80003fba <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003ede:	0c0b8863          	beqz	s7,80003fae <writei+0x10e>
    80003ee2:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003ee4:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003ee8:	5cfd                	li	s9,-1
    80003eea:	a091                	j	80003f2e <writei+0x8e>
    80003eec:	02099d93          	slli	s11,s3,0x20
    80003ef0:	020ddd93          	srli	s11,s11,0x20
    80003ef4:	05848513          	addi	a0,s1,88
    80003ef8:	86ee                	mv	a3,s11
    80003efa:	8656                	mv	a2,s5
    80003efc:	85e2                	mv	a1,s8
    80003efe:	953a                	add	a0,a0,a4
    80003f00:	fffff097          	auipc	ra,0xfffff
    80003f04:	a3e080e7          	jalr	-1474(ra) # 8000293e <either_copyin>
    80003f08:	07950263          	beq	a0,s9,80003f6c <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003f0c:	8526                	mv	a0,s1
    80003f0e:	00000097          	auipc	ra,0x0
    80003f12:	790080e7          	jalr	1936(ra) # 8000469e <log_write>
    brelse(bp);
    80003f16:	8526                	mv	a0,s1
    80003f18:	fffff097          	auipc	ra,0xfffff
    80003f1c:	50a080e7          	jalr	1290(ra) # 80003422 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003f20:	01498a3b          	addw	s4,s3,s4
    80003f24:	0129893b          	addw	s2,s3,s2
    80003f28:	9aee                	add	s5,s5,s11
    80003f2a:	057a7663          	bgeu	s4,s7,80003f76 <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003f2e:	000b2483          	lw	s1,0(s6)
    80003f32:	00a9559b          	srliw	a1,s2,0xa
    80003f36:	855a                	mv	a0,s6
    80003f38:	fffff097          	auipc	ra,0xfffff
    80003f3c:	7ae080e7          	jalr	1966(ra) # 800036e6 <bmap>
    80003f40:	0005059b          	sext.w	a1,a0
    80003f44:	8526                	mv	a0,s1
    80003f46:	fffff097          	auipc	ra,0xfffff
    80003f4a:	3ac080e7          	jalr	940(ra) # 800032f2 <bread>
    80003f4e:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003f50:	3ff97713          	andi	a4,s2,1023
    80003f54:	40ed07bb          	subw	a5,s10,a4
    80003f58:	414b86bb          	subw	a3,s7,s4
    80003f5c:	89be                	mv	s3,a5
    80003f5e:	2781                	sext.w	a5,a5
    80003f60:	0006861b          	sext.w	a2,a3
    80003f64:	f8f674e3          	bgeu	a2,a5,80003eec <writei+0x4c>
    80003f68:	89b6                	mv	s3,a3
    80003f6a:	b749                	j	80003eec <writei+0x4c>
      brelse(bp);
    80003f6c:	8526                	mv	a0,s1
    80003f6e:	fffff097          	auipc	ra,0xfffff
    80003f72:	4b4080e7          	jalr	1204(ra) # 80003422 <brelse>
  }

  if(off > ip->size)
    80003f76:	04cb2783          	lw	a5,76(s6)
    80003f7a:	0127f463          	bgeu	a5,s2,80003f82 <writei+0xe2>
    ip->size = off;
    80003f7e:	052b2623          	sw	s2,76(s6)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003f82:	855a                	mv	a0,s6
    80003f84:	00000097          	auipc	ra,0x0
    80003f88:	aa6080e7          	jalr	-1370(ra) # 80003a2a <iupdate>

  return tot;
    80003f8c:	000a051b          	sext.w	a0,s4
}
    80003f90:	70a6                	ld	ra,104(sp)
    80003f92:	7406                	ld	s0,96(sp)
    80003f94:	64e6                	ld	s1,88(sp)
    80003f96:	6946                	ld	s2,80(sp)
    80003f98:	69a6                	ld	s3,72(sp)
    80003f9a:	6a06                	ld	s4,64(sp)
    80003f9c:	7ae2                	ld	s5,56(sp)
    80003f9e:	7b42                	ld	s6,48(sp)
    80003fa0:	7ba2                	ld	s7,40(sp)
    80003fa2:	7c02                	ld	s8,32(sp)
    80003fa4:	6ce2                	ld	s9,24(sp)
    80003fa6:	6d42                	ld	s10,16(sp)
    80003fa8:	6da2                	ld	s11,8(sp)
    80003faa:	6165                	addi	sp,sp,112
    80003fac:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003fae:	8a5e                	mv	s4,s7
    80003fb0:	bfc9                	j	80003f82 <writei+0xe2>
    return -1;
    80003fb2:	557d                	li	a0,-1
}
    80003fb4:	8082                	ret
    return -1;
    80003fb6:	557d                	li	a0,-1
    80003fb8:	bfe1                	j	80003f90 <writei+0xf0>
    return -1;
    80003fba:	557d                	li	a0,-1
    80003fbc:	bfd1                	j	80003f90 <writei+0xf0>

0000000080003fbe <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003fbe:	1141                	addi	sp,sp,-16
    80003fc0:	e406                	sd	ra,8(sp)
    80003fc2:	e022                	sd	s0,0(sp)
    80003fc4:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003fc6:	4639                	li	a2,14
    80003fc8:	ffffd097          	auipc	ra,0xffffd
    80003fcc:	df0080e7          	jalr	-528(ra) # 80000db8 <strncmp>
}
    80003fd0:	60a2                	ld	ra,8(sp)
    80003fd2:	6402                	ld	s0,0(sp)
    80003fd4:	0141                	addi	sp,sp,16
    80003fd6:	8082                	ret

0000000080003fd8 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003fd8:	7139                	addi	sp,sp,-64
    80003fda:	fc06                	sd	ra,56(sp)
    80003fdc:	f822                	sd	s0,48(sp)
    80003fde:	f426                	sd	s1,40(sp)
    80003fe0:	f04a                	sd	s2,32(sp)
    80003fe2:	ec4e                	sd	s3,24(sp)
    80003fe4:	e852                	sd	s4,16(sp)
    80003fe6:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003fe8:	04451703          	lh	a4,68(a0)
    80003fec:	4785                	li	a5,1
    80003fee:	00f71a63          	bne	a4,a5,80004002 <dirlookup+0x2a>
    80003ff2:	892a                	mv	s2,a0
    80003ff4:	89ae                	mv	s3,a1
    80003ff6:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003ff8:	457c                	lw	a5,76(a0)
    80003ffa:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003ffc:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003ffe:	e79d                	bnez	a5,8000402c <dirlookup+0x54>
    80004000:	a8a5                	j	80004078 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80004002:	00004517          	auipc	a0,0x4
    80004006:	64650513          	addi	a0,a0,1606 # 80008648 <syscalls+0x1b0>
    8000400a:	ffffc097          	auipc	ra,0xffffc
    8000400e:	534080e7          	jalr	1332(ra) # 8000053e <panic>
      panic("dirlookup read");
    80004012:	00004517          	auipc	a0,0x4
    80004016:	64e50513          	addi	a0,a0,1614 # 80008660 <syscalls+0x1c8>
    8000401a:	ffffc097          	auipc	ra,0xffffc
    8000401e:	524080e7          	jalr	1316(ra) # 8000053e <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004022:	24c1                	addiw	s1,s1,16
    80004024:	04c92783          	lw	a5,76(s2)
    80004028:	04f4f763          	bgeu	s1,a5,80004076 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000402c:	4741                	li	a4,16
    8000402e:	86a6                	mv	a3,s1
    80004030:	fc040613          	addi	a2,s0,-64
    80004034:	4581                	li	a1,0
    80004036:	854a                	mv	a0,s2
    80004038:	00000097          	auipc	ra,0x0
    8000403c:	d70080e7          	jalr	-656(ra) # 80003da8 <readi>
    80004040:	47c1                	li	a5,16
    80004042:	fcf518e3          	bne	a0,a5,80004012 <dirlookup+0x3a>
    if(de.inum == 0)
    80004046:	fc045783          	lhu	a5,-64(s0)
    8000404a:	dfe1                	beqz	a5,80004022 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    8000404c:	fc240593          	addi	a1,s0,-62
    80004050:	854e                	mv	a0,s3
    80004052:	00000097          	auipc	ra,0x0
    80004056:	f6c080e7          	jalr	-148(ra) # 80003fbe <namecmp>
    8000405a:	f561                	bnez	a0,80004022 <dirlookup+0x4a>
      if(poff)
    8000405c:	000a0463          	beqz	s4,80004064 <dirlookup+0x8c>
        *poff = off;
    80004060:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80004064:	fc045583          	lhu	a1,-64(s0)
    80004068:	00092503          	lw	a0,0(s2)
    8000406c:	fffff097          	auipc	ra,0xfffff
    80004070:	754080e7          	jalr	1876(ra) # 800037c0 <iget>
    80004074:	a011                	j	80004078 <dirlookup+0xa0>
  return 0;
    80004076:	4501                	li	a0,0
}
    80004078:	70e2                	ld	ra,56(sp)
    8000407a:	7442                	ld	s0,48(sp)
    8000407c:	74a2                	ld	s1,40(sp)
    8000407e:	7902                	ld	s2,32(sp)
    80004080:	69e2                	ld	s3,24(sp)
    80004082:	6a42                	ld	s4,16(sp)
    80004084:	6121                	addi	sp,sp,64
    80004086:	8082                	ret

0000000080004088 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80004088:	711d                	addi	sp,sp,-96
    8000408a:	ec86                	sd	ra,88(sp)
    8000408c:	e8a2                	sd	s0,80(sp)
    8000408e:	e4a6                	sd	s1,72(sp)
    80004090:	e0ca                	sd	s2,64(sp)
    80004092:	fc4e                	sd	s3,56(sp)
    80004094:	f852                	sd	s4,48(sp)
    80004096:	f456                	sd	s5,40(sp)
    80004098:	f05a                	sd	s6,32(sp)
    8000409a:	ec5e                	sd	s7,24(sp)
    8000409c:	e862                	sd	s8,16(sp)
    8000409e:	e466                	sd	s9,8(sp)
    800040a0:	1080                	addi	s0,sp,96
    800040a2:	84aa                	mv	s1,a0
    800040a4:	8b2e                	mv	s6,a1
    800040a6:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    800040a8:	00054703          	lbu	a4,0(a0)
    800040ac:	02f00793          	li	a5,47
    800040b0:	02f70363          	beq	a4,a5,800040d6 <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    800040b4:	ffffe097          	auipc	ra,0xffffe
    800040b8:	914080e7          	jalr	-1772(ra) # 800019c8 <myproc>
    800040bc:	17053503          	ld	a0,368(a0)
    800040c0:	00000097          	auipc	ra,0x0
    800040c4:	9f6080e7          	jalr	-1546(ra) # 80003ab6 <idup>
    800040c8:	89aa                	mv	s3,a0
  while(*path == '/')
    800040ca:	02f00913          	li	s2,47
  len = path - s;
    800040ce:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    800040d0:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    800040d2:	4c05                	li	s8,1
    800040d4:	a865                	j	8000418c <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    800040d6:	4585                	li	a1,1
    800040d8:	4505                	li	a0,1
    800040da:	fffff097          	auipc	ra,0xfffff
    800040de:	6e6080e7          	jalr	1766(ra) # 800037c0 <iget>
    800040e2:	89aa                	mv	s3,a0
    800040e4:	b7dd                	j	800040ca <namex+0x42>
      iunlockput(ip);
    800040e6:	854e                	mv	a0,s3
    800040e8:	00000097          	auipc	ra,0x0
    800040ec:	c6e080e7          	jalr	-914(ra) # 80003d56 <iunlockput>
      return 0;
    800040f0:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    800040f2:	854e                	mv	a0,s3
    800040f4:	60e6                	ld	ra,88(sp)
    800040f6:	6446                	ld	s0,80(sp)
    800040f8:	64a6                	ld	s1,72(sp)
    800040fa:	6906                	ld	s2,64(sp)
    800040fc:	79e2                	ld	s3,56(sp)
    800040fe:	7a42                	ld	s4,48(sp)
    80004100:	7aa2                	ld	s5,40(sp)
    80004102:	7b02                	ld	s6,32(sp)
    80004104:	6be2                	ld	s7,24(sp)
    80004106:	6c42                	ld	s8,16(sp)
    80004108:	6ca2                	ld	s9,8(sp)
    8000410a:	6125                	addi	sp,sp,96
    8000410c:	8082                	ret
      iunlock(ip);
    8000410e:	854e                	mv	a0,s3
    80004110:	00000097          	auipc	ra,0x0
    80004114:	aa6080e7          	jalr	-1370(ra) # 80003bb6 <iunlock>
      return ip;
    80004118:	bfe9                	j	800040f2 <namex+0x6a>
      iunlockput(ip);
    8000411a:	854e                	mv	a0,s3
    8000411c:	00000097          	auipc	ra,0x0
    80004120:	c3a080e7          	jalr	-966(ra) # 80003d56 <iunlockput>
      return 0;
    80004124:	89d2                	mv	s3,s4
    80004126:	b7f1                	j	800040f2 <namex+0x6a>
  len = path - s;
    80004128:	40b48633          	sub	a2,s1,a1
    8000412c:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    80004130:	094cd463          	bge	s9,s4,800041b8 <namex+0x130>
    memmove(name, s, DIRSIZ);
    80004134:	4639                	li	a2,14
    80004136:	8556                	mv	a0,s5
    80004138:	ffffd097          	auipc	ra,0xffffd
    8000413c:	c08080e7          	jalr	-1016(ra) # 80000d40 <memmove>
  while(*path == '/')
    80004140:	0004c783          	lbu	a5,0(s1)
    80004144:	01279763          	bne	a5,s2,80004152 <namex+0xca>
    path++;
    80004148:	0485                	addi	s1,s1,1
  while(*path == '/')
    8000414a:	0004c783          	lbu	a5,0(s1)
    8000414e:	ff278de3          	beq	a5,s2,80004148 <namex+0xc0>
    ilock(ip);
    80004152:	854e                	mv	a0,s3
    80004154:	00000097          	auipc	ra,0x0
    80004158:	9a0080e7          	jalr	-1632(ra) # 80003af4 <ilock>
    if(ip->type != T_DIR){
    8000415c:	04499783          	lh	a5,68(s3)
    80004160:	f98793e3          	bne	a5,s8,800040e6 <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80004164:	000b0563          	beqz	s6,8000416e <namex+0xe6>
    80004168:	0004c783          	lbu	a5,0(s1)
    8000416c:	d3cd                	beqz	a5,8000410e <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    8000416e:	865e                	mv	a2,s7
    80004170:	85d6                	mv	a1,s5
    80004172:	854e                	mv	a0,s3
    80004174:	00000097          	auipc	ra,0x0
    80004178:	e64080e7          	jalr	-412(ra) # 80003fd8 <dirlookup>
    8000417c:	8a2a                	mv	s4,a0
    8000417e:	dd51                	beqz	a0,8000411a <namex+0x92>
    iunlockput(ip);
    80004180:	854e                	mv	a0,s3
    80004182:	00000097          	auipc	ra,0x0
    80004186:	bd4080e7          	jalr	-1068(ra) # 80003d56 <iunlockput>
    ip = next;
    8000418a:	89d2                	mv	s3,s4
  while(*path == '/')
    8000418c:	0004c783          	lbu	a5,0(s1)
    80004190:	05279763          	bne	a5,s2,800041de <namex+0x156>
    path++;
    80004194:	0485                	addi	s1,s1,1
  while(*path == '/')
    80004196:	0004c783          	lbu	a5,0(s1)
    8000419a:	ff278de3          	beq	a5,s2,80004194 <namex+0x10c>
  if(*path == 0)
    8000419e:	c79d                	beqz	a5,800041cc <namex+0x144>
    path++;
    800041a0:	85a6                	mv	a1,s1
  len = path - s;
    800041a2:	8a5e                	mv	s4,s7
    800041a4:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    800041a6:	01278963          	beq	a5,s2,800041b8 <namex+0x130>
    800041aa:	dfbd                	beqz	a5,80004128 <namex+0xa0>
    path++;
    800041ac:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    800041ae:	0004c783          	lbu	a5,0(s1)
    800041b2:	ff279ce3          	bne	a5,s2,800041aa <namex+0x122>
    800041b6:	bf8d                	j	80004128 <namex+0xa0>
    memmove(name, s, len);
    800041b8:	2601                	sext.w	a2,a2
    800041ba:	8556                	mv	a0,s5
    800041bc:	ffffd097          	auipc	ra,0xffffd
    800041c0:	b84080e7          	jalr	-1148(ra) # 80000d40 <memmove>
    name[len] = 0;
    800041c4:	9a56                	add	s4,s4,s5
    800041c6:	000a0023          	sb	zero,0(s4)
    800041ca:	bf9d                	j	80004140 <namex+0xb8>
  if(nameiparent){
    800041cc:	f20b03e3          	beqz	s6,800040f2 <namex+0x6a>
    iput(ip);
    800041d0:	854e                	mv	a0,s3
    800041d2:	00000097          	auipc	ra,0x0
    800041d6:	adc080e7          	jalr	-1316(ra) # 80003cae <iput>
    return 0;
    800041da:	4981                	li	s3,0
    800041dc:	bf19                	j	800040f2 <namex+0x6a>
  if(*path == 0)
    800041de:	d7fd                	beqz	a5,800041cc <namex+0x144>
  while(*path != '/' && *path != 0)
    800041e0:	0004c783          	lbu	a5,0(s1)
    800041e4:	85a6                	mv	a1,s1
    800041e6:	b7d1                	j	800041aa <namex+0x122>

00000000800041e8 <dirlink>:
{
    800041e8:	7139                	addi	sp,sp,-64
    800041ea:	fc06                	sd	ra,56(sp)
    800041ec:	f822                	sd	s0,48(sp)
    800041ee:	f426                	sd	s1,40(sp)
    800041f0:	f04a                	sd	s2,32(sp)
    800041f2:	ec4e                	sd	s3,24(sp)
    800041f4:	e852                	sd	s4,16(sp)
    800041f6:	0080                	addi	s0,sp,64
    800041f8:	892a                	mv	s2,a0
    800041fa:	8a2e                	mv	s4,a1
    800041fc:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    800041fe:	4601                	li	a2,0
    80004200:	00000097          	auipc	ra,0x0
    80004204:	dd8080e7          	jalr	-552(ra) # 80003fd8 <dirlookup>
    80004208:	e93d                	bnez	a0,8000427e <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000420a:	04c92483          	lw	s1,76(s2)
    8000420e:	c49d                	beqz	s1,8000423c <dirlink+0x54>
    80004210:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004212:	4741                	li	a4,16
    80004214:	86a6                	mv	a3,s1
    80004216:	fc040613          	addi	a2,s0,-64
    8000421a:	4581                	li	a1,0
    8000421c:	854a                	mv	a0,s2
    8000421e:	00000097          	auipc	ra,0x0
    80004222:	b8a080e7          	jalr	-1142(ra) # 80003da8 <readi>
    80004226:	47c1                	li	a5,16
    80004228:	06f51163          	bne	a0,a5,8000428a <dirlink+0xa2>
    if(de.inum == 0)
    8000422c:	fc045783          	lhu	a5,-64(s0)
    80004230:	c791                	beqz	a5,8000423c <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004232:	24c1                	addiw	s1,s1,16
    80004234:	04c92783          	lw	a5,76(s2)
    80004238:	fcf4ede3          	bltu	s1,a5,80004212 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    8000423c:	4639                	li	a2,14
    8000423e:	85d2                	mv	a1,s4
    80004240:	fc240513          	addi	a0,s0,-62
    80004244:	ffffd097          	auipc	ra,0xffffd
    80004248:	bb0080e7          	jalr	-1104(ra) # 80000df4 <strncpy>
  de.inum = inum;
    8000424c:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004250:	4741                	li	a4,16
    80004252:	86a6                	mv	a3,s1
    80004254:	fc040613          	addi	a2,s0,-64
    80004258:	4581                	li	a1,0
    8000425a:	854a                	mv	a0,s2
    8000425c:	00000097          	auipc	ra,0x0
    80004260:	c44080e7          	jalr	-956(ra) # 80003ea0 <writei>
    80004264:	872a                	mv	a4,a0
    80004266:	47c1                	li	a5,16
  return 0;
    80004268:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000426a:	02f71863          	bne	a4,a5,8000429a <dirlink+0xb2>
}
    8000426e:	70e2                	ld	ra,56(sp)
    80004270:	7442                	ld	s0,48(sp)
    80004272:	74a2                	ld	s1,40(sp)
    80004274:	7902                	ld	s2,32(sp)
    80004276:	69e2                	ld	s3,24(sp)
    80004278:	6a42                	ld	s4,16(sp)
    8000427a:	6121                	addi	sp,sp,64
    8000427c:	8082                	ret
    iput(ip);
    8000427e:	00000097          	auipc	ra,0x0
    80004282:	a30080e7          	jalr	-1488(ra) # 80003cae <iput>
    return -1;
    80004286:	557d                	li	a0,-1
    80004288:	b7dd                	j	8000426e <dirlink+0x86>
      panic("dirlink read");
    8000428a:	00004517          	auipc	a0,0x4
    8000428e:	3e650513          	addi	a0,a0,998 # 80008670 <syscalls+0x1d8>
    80004292:	ffffc097          	auipc	ra,0xffffc
    80004296:	2ac080e7          	jalr	684(ra) # 8000053e <panic>
    panic("dirlink");
    8000429a:	00004517          	auipc	a0,0x4
    8000429e:	4e650513          	addi	a0,a0,1254 # 80008780 <syscalls+0x2e8>
    800042a2:	ffffc097          	auipc	ra,0xffffc
    800042a6:	29c080e7          	jalr	668(ra) # 8000053e <panic>

00000000800042aa <namei>:

struct inode*
namei(char *path)
{
    800042aa:	1101                	addi	sp,sp,-32
    800042ac:	ec06                	sd	ra,24(sp)
    800042ae:	e822                	sd	s0,16(sp)
    800042b0:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    800042b2:	fe040613          	addi	a2,s0,-32
    800042b6:	4581                	li	a1,0
    800042b8:	00000097          	auipc	ra,0x0
    800042bc:	dd0080e7          	jalr	-560(ra) # 80004088 <namex>
}
    800042c0:	60e2                	ld	ra,24(sp)
    800042c2:	6442                	ld	s0,16(sp)
    800042c4:	6105                	addi	sp,sp,32
    800042c6:	8082                	ret

00000000800042c8 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    800042c8:	1141                	addi	sp,sp,-16
    800042ca:	e406                	sd	ra,8(sp)
    800042cc:	e022                	sd	s0,0(sp)
    800042ce:	0800                	addi	s0,sp,16
    800042d0:	862e                	mv	a2,a1
  return namex(path, 1, name);
    800042d2:	4585                	li	a1,1
    800042d4:	00000097          	auipc	ra,0x0
    800042d8:	db4080e7          	jalr	-588(ra) # 80004088 <namex>
}
    800042dc:	60a2                	ld	ra,8(sp)
    800042de:	6402                	ld	s0,0(sp)
    800042e0:	0141                	addi	sp,sp,16
    800042e2:	8082                	ret

00000000800042e4 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    800042e4:	1101                	addi	sp,sp,-32
    800042e6:	ec06                	sd	ra,24(sp)
    800042e8:	e822                	sd	s0,16(sp)
    800042ea:	e426                	sd	s1,8(sp)
    800042ec:	e04a                	sd	s2,0(sp)
    800042ee:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    800042f0:	0001d917          	auipc	s2,0x1d
    800042f4:	7a090913          	addi	s2,s2,1952 # 80021a90 <log>
    800042f8:	01892583          	lw	a1,24(s2)
    800042fc:	02892503          	lw	a0,40(s2)
    80004300:	fffff097          	auipc	ra,0xfffff
    80004304:	ff2080e7          	jalr	-14(ra) # 800032f2 <bread>
    80004308:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    8000430a:	02c92683          	lw	a3,44(s2)
    8000430e:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80004310:	02d05763          	blez	a3,8000433e <write_head+0x5a>
    80004314:	0001d797          	auipc	a5,0x1d
    80004318:	7ac78793          	addi	a5,a5,1964 # 80021ac0 <log+0x30>
    8000431c:	05c50713          	addi	a4,a0,92
    80004320:	36fd                	addiw	a3,a3,-1
    80004322:	1682                	slli	a3,a3,0x20
    80004324:	9281                	srli	a3,a3,0x20
    80004326:	068a                	slli	a3,a3,0x2
    80004328:	0001d617          	auipc	a2,0x1d
    8000432c:	79c60613          	addi	a2,a2,1948 # 80021ac4 <log+0x34>
    80004330:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80004332:	4390                	lw	a2,0(a5)
    80004334:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004336:	0791                	addi	a5,a5,4
    80004338:	0711                	addi	a4,a4,4
    8000433a:	fed79ce3          	bne	a5,a3,80004332 <write_head+0x4e>
  }
  bwrite(buf);
    8000433e:	8526                	mv	a0,s1
    80004340:	fffff097          	auipc	ra,0xfffff
    80004344:	0a4080e7          	jalr	164(ra) # 800033e4 <bwrite>
  brelse(buf);
    80004348:	8526                	mv	a0,s1
    8000434a:	fffff097          	auipc	ra,0xfffff
    8000434e:	0d8080e7          	jalr	216(ra) # 80003422 <brelse>
}
    80004352:	60e2                	ld	ra,24(sp)
    80004354:	6442                	ld	s0,16(sp)
    80004356:	64a2                	ld	s1,8(sp)
    80004358:	6902                	ld	s2,0(sp)
    8000435a:	6105                	addi	sp,sp,32
    8000435c:	8082                	ret

000000008000435e <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    8000435e:	0001d797          	auipc	a5,0x1d
    80004362:	75e7a783          	lw	a5,1886(a5) # 80021abc <log+0x2c>
    80004366:	0af05d63          	blez	a5,80004420 <install_trans+0xc2>
{
    8000436a:	7139                	addi	sp,sp,-64
    8000436c:	fc06                	sd	ra,56(sp)
    8000436e:	f822                	sd	s0,48(sp)
    80004370:	f426                	sd	s1,40(sp)
    80004372:	f04a                	sd	s2,32(sp)
    80004374:	ec4e                	sd	s3,24(sp)
    80004376:	e852                	sd	s4,16(sp)
    80004378:	e456                	sd	s5,8(sp)
    8000437a:	e05a                	sd	s6,0(sp)
    8000437c:	0080                	addi	s0,sp,64
    8000437e:	8b2a                	mv	s6,a0
    80004380:	0001da97          	auipc	s5,0x1d
    80004384:	740a8a93          	addi	s5,s5,1856 # 80021ac0 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004388:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    8000438a:	0001d997          	auipc	s3,0x1d
    8000438e:	70698993          	addi	s3,s3,1798 # 80021a90 <log>
    80004392:	a035                	j	800043be <install_trans+0x60>
      bunpin(dbuf);
    80004394:	8526                	mv	a0,s1
    80004396:	fffff097          	auipc	ra,0xfffff
    8000439a:	166080e7          	jalr	358(ra) # 800034fc <bunpin>
    brelse(lbuf);
    8000439e:	854a                	mv	a0,s2
    800043a0:	fffff097          	auipc	ra,0xfffff
    800043a4:	082080e7          	jalr	130(ra) # 80003422 <brelse>
    brelse(dbuf);
    800043a8:	8526                	mv	a0,s1
    800043aa:	fffff097          	auipc	ra,0xfffff
    800043ae:	078080e7          	jalr	120(ra) # 80003422 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800043b2:	2a05                	addiw	s4,s4,1
    800043b4:	0a91                	addi	s5,s5,4
    800043b6:	02c9a783          	lw	a5,44(s3)
    800043ba:	04fa5963          	bge	s4,a5,8000440c <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800043be:	0189a583          	lw	a1,24(s3)
    800043c2:	014585bb          	addw	a1,a1,s4
    800043c6:	2585                	addiw	a1,a1,1
    800043c8:	0289a503          	lw	a0,40(s3)
    800043cc:	fffff097          	auipc	ra,0xfffff
    800043d0:	f26080e7          	jalr	-218(ra) # 800032f2 <bread>
    800043d4:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    800043d6:	000aa583          	lw	a1,0(s5)
    800043da:	0289a503          	lw	a0,40(s3)
    800043de:	fffff097          	auipc	ra,0xfffff
    800043e2:	f14080e7          	jalr	-236(ra) # 800032f2 <bread>
    800043e6:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    800043e8:	40000613          	li	a2,1024
    800043ec:	05890593          	addi	a1,s2,88
    800043f0:	05850513          	addi	a0,a0,88
    800043f4:	ffffd097          	auipc	ra,0xffffd
    800043f8:	94c080e7          	jalr	-1716(ra) # 80000d40 <memmove>
    bwrite(dbuf);  // write dst to disk
    800043fc:	8526                	mv	a0,s1
    800043fe:	fffff097          	auipc	ra,0xfffff
    80004402:	fe6080e7          	jalr	-26(ra) # 800033e4 <bwrite>
    if(recovering == 0)
    80004406:	f80b1ce3          	bnez	s6,8000439e <install_trans+0x40>
    8000440a:	b769                	j	80004394 <install_trans+0x36>
}
    8000440c:	70e2                	ld	ra,56(sp)
    8000440e:	7442                	ld	s0,48(sp)
    80004410:	74a2                	ld	s1,40(sp)
    80004412:	7902                	ld	s2,32(sp)
    80004414:	69e2                	ld	s3,24(sp)
    80004416:	6a42                	ld	s4,16(sp)
    80004418:	6aa2                	ld	s5,8(sp)
    8000441a:	6b02                	ld	s6,0(sp)
    8000441c:	6121                	addi	sp,sp,64
    8000441e:	8082                	ret
    80004420:	8082                	ret

0000000080004422 <initlog>:
{
    80004422:	7179                	addi	sp,sp,-48
    80004424:	f406                	sd	ra,40(sp)
    80004426:	f022                	sd	s0,32(sp)
    80004428:	ec26                	sd	s1,24(sp)
    8000442a:	e84a                	sd	s2,16(sp)
    8000442c:	e44e                	sd	s3,8(sp)
    8000442e:	1800                	addi	s0,sp,48
    80004430:	892a                	mv	s2,a0
    80004432:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80004434:	0001d497          	auipc	s1,0x1d
    80004438:	65c48493          	addi	s1,s1,1628 # 80021a90 <log>
    8000443c:	00004597          	auipc	a1,0x4
    80004440:	24458593          	addi	a1,a1,580 # 80008680 <syscalls+0x1e8>
    80004444:	8526                	mv	a0,s1
    80004446:	ffffc097          	auipc	ra,0xffffc
    8000444a:	70e080e7          	jalr	1806(ra) # 80000b54 <initlock>
  log.start = sb->logstart;
    8000444e:	0149a583          	lw	a1,20(s3)
    80004452:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80004454:	0109a783          	lw	a5,16(s3)
    80004458:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    8000445a:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    8000445e:	854a                	mv	a0,s2
    80004460:	fffff097          	auipc	ra,0xfffff
    80004464:	e92080e7          	jalr	-366(ra) # 800032f2 <bread>
  log.lh.n = lh->n;
    80004468:	4d3c                	lw	a5,88(a0)
    8000446a:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    8000446c:	02f05563          	blez	a5,80004496 <initlog+0x74>
    80004470:	05c50713          	addi	a4,a0,92
    80004474:	0001d697          	auipc	a3,0x1d
    80004478:	64c68693          	addi	a3,a3,1612 # 80021ac0 <log+0x30>
    8000447c:	37fd                	addiw	a5,a5,-1
    8000447e:	1782                	slli	a5,a5,0x20
    80004480:	9381                	srli	a5,a5,0x20
    80004482:	078a                	slli	a5,a5,0x2
    80004484:	06050613          	addi	a2,a0,96
    80004488:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    8000448a:	4310                	lw	a2,0(a4)
    8000448c:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    8000448e:	0711                	addi	a4,a4,4
    80004490:	0691                	addi	a3,a3,4
    80004492:	fef71ce3          	bne	a4,a5,8000448a <initlog+0x68>
  brelse(buf);
    80004496:	fffff097          	auipc	ra,0xfffff
    8000449a:	f8c080e7          	jalr	-116(ra) # 80003422 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    8000449e:	4505                	li	a0,1
    800044a0:	00000097          	auipc	ra,0x0
    800044a4:	ebe080e7          	jalr	-322(ra) # 8000435e <install_trans>
  log.lh.n = 0;
    800044a8:	0001d797          	auipc	a5,0x1d
    800044ac:	6007aa23          	sw	zero,1556(a5) # 80021abc <log+0x2c>
  write_head(); // clear the log
    800044b0:	00000097          	auipc	ra,0x0
    800044b4:	e34080e7          	jalr	-460(ra) # 800042e4 <write_head>
}
    800044b8:	70a2                	ld	ra,40(sp)
    800044ba:	7402                	ld	s0,32(sp)
    800044bc:	64e2                	ld	s1,24(sp)
    800044be:	6942                	ld	s2,16(sp)
    800044c0:	69a2                	ld	s3,8(sp)
    800044c2:	6145                	addi	sp,sp,48
    800044c4:	8082                	ret

00000000800044c6 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    800044c6:	1101                	addi	sp,sp,-32
    800044c8:	ec06                	sd	ra,24(sp)
    800044ca:	e822                	sd	s0,16(sp)
    800044cc:	e426                	sd	s1,8(sp)
    800044ce:	e04a                	sd	s2,0(sp)
    800044d0:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    800044d2:	0001d517          	auipc	a0,0x1d
    800044d6:	5be50513          	addi	a0,a0,1470 # 80021a90 <log>
    800044da:	ffffc097          	auipc	ra,0xffffc
    800044de:	70a080e7          	jalr	1802(ra) # 80000be4 <acquire>
  while(1){
    if(log.committing){
    800044e2:	0001d497          	auipc	s1,0x1d
    800044e6:	5ae48493          	addi	s1,s1,1454 # 80021a90 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800044ea:	4979                	li	s2,30
    800044ec:	a039                	j	800044fa <begin_op+0x34>
      sleep(&log, &log.lock);
    800044ee:	85a6                	mv	a1,s1
    800044f0:	8526                	mv	a0,s1
    800044f2:	ffffe097          	auipc	ra,0xffffe
    800044f6:	ed0080e7          	jalr	-304(ra) # 800023c2 <sleep>
    if(log.committing){
    800044fa:	50dc                	lw	a5,36(s1)
    800044fc:	fbed                	bnez	a5,800044ee <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800044fe:	509c                	lw	a5,32(s1)
    80004500:	0017871b          	addiw	a4,a5,1
    80004504:	0007069b          	sext.w	a3,a4
    80004508:	0027179b          	slliw	a5,a4,0x2
    8000450c:	9fb9                	addw	a5,a5,a4
    8000450e:	0017979b          	slliw	a5,a5,0x1
    80004512:	54d8                	lw	a4,44(s1)
    80004514:	9fb9                	addw	a5,a5,a4
    80004516:	00f95963          	bge	s2,a5,80004528 <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    8000451a:	85a6                	mv	a1,s1
    8000451c:	8526                	mv	a0,s1
    8000451e:	ffffe097          	auipc	ra,0xffffe
    80004522:	ea4080e7          	jalr	-348(ra) # 800023c2 <sleep>
    80004526:	bfd1                	j	800044fa <begin_op+0x34>
    } else {
      log.outstanding += 1;
    80004528:	0001d517          	auipc	a0,0x1d
    8000452c:	56850513          	addi	a0,a0,1384 # 80021a90 <log>
    80004530:	d114                	sw	a3,32(a0)
      release(&log.lock);
    80004532:	ffffc097          	auipc	ra,0xffffc
    80004536:	766080e7          	jalr	1894(ra) # 80000c98 <release>
      break;
    }
  }
}
    8000453a:	60e2                	ld	ra,24(sp)
    8000453c:	6442                	ld	s0,16(sp)
    8000453e:	64a2                	ld	s1,8(sp)
    80004540:	6902                	ld	s2,0(sp)
    80004542:	6105                	addi	sp,sp,32
    80004544:	8082                	ret

0000000080004546 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80004546:	7139                	addi	sp,sp,-64
    80004548:	fc06                	sd	ra,56(sp)
    8000454a:	f822                	sd	s0,48(sp)
    8000454c:	f426                	sd	s1,40(sp)
    8000454e:	f04a                	sd	s2,32(sp)
    80004550:	ec4e                	sd	s3,24(sp)
    80004552:	e852                	sd	s4,16(sp)
    80004554:	e456                	sd	s5,8(sp)
    80004556:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80004558:	0001d497          	auipc	s1,0x1d
    8000455c:	53848493          	addi	s1,s1,1336 # 80021a90 <log>
    80004560:	8526                	mv	a0,s1
    80004562:	ffffc097          	auipc	ra,0xffffc
    80004566:	682080e7          	jalr	1666(ra) # 80000be4 <acquire>
  log.outstanding -= 1;
    8000456a:	509c                	lw	a5,32(s1)
    8000456c:	37fd                	addiw	a5,a5,-1
    8000456e:	0007891b          	sext.w	s2,a5
    80004572:	d09c                	sw	a5,32(s1)
  if(log.committing)
    80004574:	50dc                	lw	a5,36(s1)
    80004576:	efb9                	bnez	a5,800045d4 <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    80004578:	06091663          	bnez	s2,800045e4 <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    8000457c:	0001d497          	auipc	s1,0x1d
    80004580:	51448493          	addi	s1,s1,1300 # 80021a90 <log>
    80004584:	4785                	li	a5,1
    80004586:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    80004588:	8526                	mv	a0,s1
    8000458a:	ffffc097          	auipc	ra,0xffffc
    8000458e:	70e080e7          	jalr	1806(ra) # 80000c98 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    80004592:	54dc                	lw	a5,44(s1)
    80004594:	06f04763          	bgtz	a5,80004602 <end_op+0xbc>
    acquire(&log.lock);
    80004598:	0001d497          	auipc	s1,0x1d
    8000459c:	4f848493          	addi	s1,s1,1272 # 80021a90 <log>
    800045a0:	8526                	mv	a0,s1
    800045a2:	ffffc097          	auipc	ra,0xffffc
    800045a6:	642080e7          	jalr	1602(ra) # 80000be4 <acquire>
    log.committing = 0;
    800045aa:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    800045ae:	8526                	mv	a0,s1
    800045b0:	ffffe097          	auipc	ra,0xffffe
    800045b4:	fb2080e7          	jalr	-78(ra) # 80002562 <wakeup>
    release(&log.lock);
    800045b8:	8526                	mv	a0,s1
    800045ba:	ffffc097          	auipc	ra,0xffffc
    800045be:	6de080e7          	jalr	1758(ra) # 80000c98 <release>
}
    800045c2:	70e2                	ld	ra,56(sp)
    800045c4:	7442                	ld	s0,48(sp)
    800045c6:	74a2                	ld	s1,40(sp)
    800045c8:	7902                	ld	s2,32(sp)
    800045ca:	69e2                	ld	s3,24(sp)
    800045cc:	6a42                	ld	s4,16(sp)
    800045ce:	6aa2                	ld	s5,8(sp)
    800045d0:	6121                	addi	sp,sp,64
    800045d2:	8082                	ret
    panic("log.committing");
    800045d4:	00004517          	auipc	a0,0x4
    800045d8:	0b450513          	addi	a0,a0,180 # 80008688 <syscalls+0x1f0>
    800045dc:	ffffc097          	auipc	ra,0xffffc
    800045e0:	f62080e7          	jalr	-158(ra) # 8000053e <panic>
    wakeup(&log);
    800045e4:	0001d497          	auipc	s1,0x1d
    800045e8:	4ac48493          	addi	s1,s1,1196 # 80021a90 <log>
    800045ec:	8526                	mv	a0,s1
    800045ee:	ffffe097          	auipc	ra,0xffffe
    800045f2:	f74080e7          	jalr	-140(ra) # 80002562 <wakeup>
  release(&log.lock);
    800045f6:	8526                	mv	a0,s1
    800045f8:	ffffc097          	auipc	ra,0xffffc
    800045fc:	6a0080e7          	jalr	1696(ra) # 80000c98 <release>
  if(do_commit){
    80004600:	b7c9                	j	800045c2 <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004602:	0001da97          	auipc	s5,0x1d
    80004606:	4bea8a93          	addi	s5,s5,1214 # 80021ac0 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    8000460a:	0001da17          	auipc	s4,0x1d
    8000460e:	486a0a13          	addi	s4,s4,1158 # 80021a90 <log>
    80004612:	018a2583          	lw	a1,24(s4)
    80004616:	012585bb          	addw	a1,a1,s2
    8000461a:	2585                	addiw	a1,a1,1
    8000461c:	028a2503          	lw	a0,40(s4)
    80004620:	fffff097          	auipc	ra,0xfffff
    80004624:	cd2080e7          	jalr	-814(ra) # 800032f2 <bread>
    80004628:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    8000462a:	000aa583          	lw	a1,0(s5)
    8000462e:	028a2503          	lw	a0,40(s4)
    80004632:	fffff097          	auipc	ra,0xfffff
    80004636:	cc0080e7          	jalr	-832(ra) # 800032f2 <bread>
    8000463a:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    8000463c:	40000613          	li	a2,1024
    80004640:	05850593          	addi	a1,a0,88
    80004644:	05848513          	addi	a0,s1,88
    80004648:	ffffc097          	auipc	ra,0xffffc
    8000464c:	6f8080e7          	jalr	1784(ra) # 80000d40 <memmove>
    bwrite(to);  // write the log
    80004650:	8526                	mv	a0,s1
    80004652:	fffff097          	auipc	ra,0xfffff
    80004656:	d92080e7          	jalr	-622(ra) # 800033e4 <bwrite>
    brelse(from);
    8000465a:	854e                	mv	a0,s3
    8000465c:	fffff097          	auipc	ra,0xfffff
    80004660:	dc6080e7          	jalr	-570(ra) # 80003422 <brelse>
    brelse(to);
    80004664:	8526                	mv	a0,s1
    80004666:	fffff097          	auipc	ra,0xfffff
    8000466a:	dbc080e7          	jalr	-580(ra) # 80003422 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000466e:	2905                	addiw	s2,s2,1
    80004670:	0a91                	addi	s5,s5,4
    80004672:	02ca2783          	lw	a5,44(s4)
    80004676:	f8f94ee3          	blt	s2,a5,80004612 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    8000467a:	00000097          	auipc	ra,0x0
    8000467e:	c6a080e7          	jalr	-918(ra) # 800042e4 <write_head>
    install_trans(0); // Now install writes to home locations
    80004682:	4501                	li	a0,0
    80004684:	00000097          	auipc	ra,0x0
    80004688:	cda080e7          	jalr	-806(ra) # 8000435e <install_trans>
    log.lh.n = 0;
    8000468c:	0001d797          	auipc	a5,0x1d
    80004690:	4207a823          	sw	zero,1072(a5) # 80021abc <log+0x2c>
    write_head();    // Erase the transaction from the log
    80004694:	00000097          	auipc	ra,0x0
    80004698:	c50080e7          	jalr	-944(ra) # 800042e4 <write_head>
    8000469c:	bdf5                	j	80004598 <end_op+0x52>

000000008000469e <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    8000469e:	1101                	addi	sp,sp,-32
    800046a0:	ec06                	sd	ra,24(sp)
    800046a2:	e822                	sd	s0,16(sp)
    800046a4:	e426                	sd	s1,8(sp)
    800046a6:	e04a                	sd	s2,0(sp)
    800046a8:	1000                	addi	s0,sp,32
    800046aa:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    800046ac:	0001d917          	auipc	s2,0x1d
    800046b0:	3e490913          	addi	s2,s2,996 # 80021a90 <log>
    800046b4:	854a                	mv	a0,s2
    800046b6:	ffffc097          	auipc	ra,0xffffc
    800046ba:	52e080e7          	jalr	1326(ra) # 80000be4 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    800046be:	02c92603          	lw	a2,44(s2)
    800046c2:	47f5                	li	a5,29
    800046c4:	06c7c563          	blt	a5,a2,8000472e <log_write+0x90>
    800046c8:	0001d797          	auipc	a5,0x1d
    800046cc:	3e47a783          	lw	a5,996(a5) # 80021aac <log+0x1c>
    800046d0:	37fd                	addiw	a5,a5,-1
    800046d2:	04f65e63          	bge	a2,a5,8000472e <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    800046d6:	0001d797          	auipc	a5,0x1d
    800046da:	3da7a783          	lw	a5,986(a5) # 80021ab0 <log+0x20>
    800046de:	06f05063          	blez	a5,8000473e <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    800046e2:	4781                	li	a5,0
    800046e4:	06c05563          	blez	a2,8000474e <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    800046e8:	44cc                	lw	a1,12(s1)
    800046ea:	0001d717          	auipc	a4,0x1d
    800046ee:	3d670713          	addi	a4,a4,982 # 80021ac0 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    800046f2:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    800046f4:	4314                	lw	a3,0(a4)
    800046f6:	04b68c63          	beq	a3,a1,8000474e <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    800046fa:	2785                	addiw	a5,a5,1
    800046fc:	0711                	addi	a4,a4,4
    800046fe:	fef61be3          	bne	a2,a5,800046f4 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004702:	0621                	addi	a2,a2,8
    80004704:	060a                	slli	a2,a2,0x2
    80004706:	0001d797          	auipc	a5,0x1d
    8000470a:	38a78793          	addi	a5,a5,906 # 80021a90 <log>
    8000470e:	963e                	add	a2,a2,a5
    80004710:	44dc                	lw	a5,12(s1)
    80004712:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004714:	8526                	mv	a0,s1
    80004716:	fffff097          	auipc	ra,0xfffff
    8000471a:	daa080e7          	jalr	-598(ra) # 800034c0 <bpin>
    log.lh.n++;
    8000471e:	0001d717          	auipc	a4,0x1d
    80004722:	37270713          	addi	a4,a4,882 # 80021a90 <log>
    80004726:	575c                	lw	a5,44(a4)
    80004728:	2785                	addiw	a5,a5,1
    8000472a:	d75c                	sw	a5,44(a4)
    8000472c:	a835                	j	80004768 <log_write+0xca>
    panic("too big a transaction");
    8000472e:	00004517          	auipc	a0,0x4
    80004732:	f6a50513          	addi	a0,a0,-150 # 80008698 <syscalls+0x200>
    80004736:	ffffc097          	auipc	ra,0xffffc
    8000473a:	e08080e7          	jalr	-504(ra) # 8000053e <panic>
    panic("log_write outside of trans");
    8000473e:	00004517          	auipc	a0,0x4
    80004742:	f7250513          	addi	a0,a0,-142 # 800086b0 <syscalls+0x218>
    80004746:	ffffc097          	auipc	ra,0xffffc
    8000474a:	df8080e7          	jalr	-520(ra) # 8000053e <panic>
  log.lh.block[i] = b->blockno;
    8000474e:	00878713          	addi	a4,a5,8
    80004752:	00271693          	slli	a3,a4,0x2
    80004756:	0001d717          	auipc	a4,0x1d
    8000475a:	33a70713          	addi	a4,a4,826 # 80021a90 <log>
    8000475e:	9736                	add	a4,a4,a3
    80004760:	44d4                	lw	a3,12(s1)
    80004762:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80004764:	faf608e3          	beq	a2,a5,80004714 <log_write+0x76>
  }
  release(&log.lock);
    80004768:	0001d517          	auipc	a0,0x1d
    8000476c:	32850513          	addi	a0,a0,808 # 80021a90 <log>
    80004770:	ffffc097          	auipc	ra,0xffffc
    80004774:	528080e7          	jalr	1320(ra) # 80000c98 <release>
}
    80004778:	60e2                	ld	ra,24(sp)
    8000477a:	6442                	ld	s0,16(sp)
    8000477c:	64a2                	ld	s1,8(sp)
    8000477e:	6902                	ld	s2,0(sp)
    80004780:	6105                	addi	sp,sp,32
    80004782:	8082                	ret

0000000080004784 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004784:	1101                	addi	sp,sp,-32
    80004786:	ec06                	sd	ra,24(sp)
    80004788:	e822                	sd	s0,16(sp)
    8000478a:	e426                	sd	s1,8(sp)
    8000478c:	e04a                	sd	s2,0(sp)
    8000478e:	1000                	addi	s0,sp,32
    80004790:	84aa                	mv	s1,a0
    80004792:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004794:	00004597          	auipc	a1,0x4
    80004798:	f3c58593          	addi	a1,a1,-196 # 800086d0 <syscalls+0x238>
    8000479c:	0521                	addi	a0,a0,8
    8000479e:	ffffc097          	auipc	ra,0xffffc
    800047a2:	3b6080e7          	jalr	950(ra) # 80000b54 <initlock>
  lk->name = name;
    800047a6:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    800047aa:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800047ae:	0204a423          	sw	zero,40(s1)
}
    800047b2:	60e2                	ld	ra,24(sp)
    800047b4:	6442                	ld	s0,16(sp)
    800047b6:	64a2                	ld	s1,8(sp)
    800047b8:	6902                	ld	s2,0(sp)
    800047ba:	6105                	addi	sp,sp,32
    800047bc:	8082                	ret

00000000800047be <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    800047be:	1101                	addi	sp,sp,-32
    800047c0:	ec06                	sd	ra,24(sp)
    800047c2:	e822                	sd	s0,16(sp)
    800047c4:	e426                	sd	s1,8(sp)
    800047c6:	e04a                	sd	s2,0(sp)
    800047c8:	1000                	addi	s0,sp,32
    800047ca:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800047cc:	00850913          	addi	s2,a0,8
    800047d0:	854a                	mv	a0,s2
    800047d2:	ffffc097          	auipc	ra,0xffffc
    800047d6:	412080e7          	jalr	1042(ra) # 80000be4 <acquire>
  while (lk->locked) {
    800047da:	409c                	lw	a5,0(s1)
    800047dc:	cb89                	beqz	a5,800047ee <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    800047de:	85ca                	mv	a1,s2
    800047e0:	8526                	mv	a0,s1
    800047e2:	ffffe097          	auipc	ra,0xffffe
    800047e6:	be0080e7          	jalr	-1056(ra) # 800023c2 <sleep>
  while (lk->locked) {
    800047ea:	409c                	lw	a5,0(s1)
    800047ec:	fbed                	bnez	a5,800047de <acquiresleep+0x20>
  }
  lk->locked = 1;
    800047ee:	4785                	li	a5,1
    800047f0:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    800047f2:	ffffd097          	auipc	ra,0xffffd
    800047f6:	1d6080e7          	jalr	470(ra) # 800019c8 <myproc>
    800047fa:	591c                	lw	a5,48(a0)
    800047fc:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    800047fe:	854a                	mv	a0,s2
    80004800:	ffffc097          	auipc	ra,0xffffc
    80004804:	498080e7          	jalr	1176(ra) # 80000c98 <release>
}
    80004808:	60e2                	ld	ra,24(sp)
    8000480a:	6442                	ld	s0,16(sp)
    8000480c:	64a2                	ld	s1,8(sp)
    8000480e:	6902                	ld	s2,0(sp)
    80004810:	6105                	addi	sp,sp,32
    80004812:	8082                	ret

0000000080004814 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004814:	1101                	addi	sp,sp,-32
    80004816:	ec06                	sd	ra,24(sp)
    80004818:	e822                	sd	s0,16(sp)
    8000481a:	e426                	sd	s1,8(sp)
    8000481c:	e04a                	sd	s2,0(sp)
    8000481e:	1000                	addi	s0,sp,32
    80004820:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004822:	00850913          	addi	s2,a0,8
    80004826:	854a                	mv	a0,s2
    80004828:	ffffc097          	auipc	ra,0xffffc
    8000482c:	3bc080e7          	jalr	956(ra) # 80000be4 <acquire>
  lk->locked = 0;
    80004830:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004834:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004838:	8526                	mv	a0,s1
    8000483a:	ffffe097          	auipc	ra,0xffffe
    8000483e:	d28080e7          	jalr	-728(ra) # 80002562 <wakeup>
  release(&lk->lk);
    80004842:	854a                	mv	a0,s2
    80004844:	ffffc097          	auipc	ra,0xffffc
    80004848:	454080e7          	jalr	1108(ra) # 80000c98 <release>
}
    8000484c:	60e2                	ld	ra,24(sp)
    8000484e:	6442                	ld	s0,16(sp)
    80004850:	64a2                	ld	s1,8(sp)
    80004852:	6902                	ld	s2,0(sp)
    80004854:	6105                	addi	sp,sp,32
    80004856:	8082                	ret

0000000080004858 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004858:	7179                	addi	sp,sp,-48
    8000485a:	f406                	sd	ra,40(sp)
    8000485c:	f022                	sd	s0,32(sp)
    8000485e:	ec26                	sd	s1,24(sp)
    80004860:	e84a                	sd	s2,16(sp)
    80004862:	e44e                	sd	s3,8(sp)
    80004864:	1800                	addi	s0,sp,48
    80004866:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004868:	00850913          	addi	s2,a0,8
    8000486c:	854a                	mv	a0,s2
    8000486e:	ffffc097          	auipc	ra,0xffffc
    80004872:	376080e7          	jalr	886(ra) # 80000be4 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004876:	409c                	lw	a5,0(s1)
    80004878:	ef99                	bnez	a5,80004896 <holdingsleep+0x3e>
    8000487a:	4481                	li	s1,0
  release(&lk->lk);
    8000487c:	854a                	mv	a0,s2
    8000487e:	ffffc097          	auipc	ra,0xffffc
    80004882:	41a080e7          	jalr	1050(ra) # 80000c98 <release>
  return r;
}
    80004886:	8526                	mv	a0,s1
    80004888:	70a2                	ld	ra,40(sp)
    8000488a:	7402                	ld	s0,32(sp)
    8000488c:	64e2                	ld	s1,24(sp)
    8000488e:	6942                	ld	s2,16(sp)
    80004890:	69a2                	ld	s3,8(sp)
    80004892:	6145                	addi	sp,sp,48
    80004894:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004896:	0284a983          	lw	s3,40(s1)
    8000489a:	ffffd097          	auipc	ra,0xffffd
    8000489e:	12e080e7          	jalr	302(ra) # 800019c8 <myproc>
    800048a2:	5904                	lw	s1,48(a0)
    800048a4:	413484b3          	sub	s1,s1,s3
    800048a8:	0014b493          	seqz	s1,s1
    800048ac:	bfc1                	j	8000487c <holdingsleep+0x24>

00000000800048ae <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    800048ae:	1141                	addi	sp,sp,-16
    800048b0:	e406                	sd	ra,8(sp)
    800048b2:	e022                	sd	s0,0(sp)
    800048b4:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    800048b6:	00004597          	auipc	a1,0x4
    800048ba:	e2a58593          	addi	a1,a1,-470 # 800086e0 <syscalls+0x248>
    800048be:	0001d517          	auipc	a0,0x1d
    800048c2:	31a50513          	addi	a0,a0,794 # 80021bd8 <ftable>
    800048c6:	ffffc097          	auipc	ra,0xffffc
    800048ca:	28e080e7          	jalr	654(ra) # 80000b54 <initlock>
}
    800048ce:	60a2                	ld	ra,8(sp)
    800048d0:	6402                	ld	s0,0(sp)
    800048d2:	0141                	addi	sp,sp,16
    800048d4:	8082                	ret

00000000800048d6 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    800048d6:	1101                	addi	sp,sp,-32
    800048d8:	ec06                	sd	ra,24(sp)
    800048da:	e822                	sd	s0,16(sp)
    800048dc:	e426                	sd	s1,8(sp)
    800048de:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    800048e0:	0001d517          	auipc	a0,0x1d
    800048e4:	2f850513          	addi	a0,a0,760 # 80021bd8 <ftable>
    800048e8:	ffffc097          	auipc	ra,0xffffc
    800048ec:	2fc080e7          	jalr	764(ra) # 80000be4 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800048f0:	0001d497          	auipc	s1,0x1d
    800048f4:	30048493          	addi	s1,s1,768 # 80021bf0 <ftable+0x18>
    800048f8:	0001e717          	auipc	a4,0x1e
    800048fc:	29870713          	addi	a4,a4,664 # 80022b90 <ftable+0xfb8>
    if(f->ref == 0){
    80004900:	40dc                	lw	a5,4(s1)
    80004902:	cf99                	beqz	a5,80004920 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004904:	02848493          	addi	s1,s1,40
    80004908:	fee49ce3          	bne	s1,a4,80004900 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    8000490c:	0001d517          	auipc	a0,0x1d
    80004910:	2cc50513          	addi	a0,a0,716 # 80021bd8 <ftable>
    80004914:	ffffc097          	auipc	ra,0xffffc
    80004918:	384080e7          	jalr	900(ra) # 80000c98 <release>
  return 0;
    8000491c:	4481                	li	s1,0
    8000491e:	a819                	j	80004934 <filealloc+0x5e>
      f->ref = 1;
    80004920:	4785                	li	a5,1
    80004922:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004924:	0001d517          	auipc	a0,0x1d
    80004928:	2b450513          	addi	a0,a0,692 # 80021bd8 <ftable>
    8000492c:	ffffc097          	auipc	ra,0xffffc
    80004930:	36c080e7          	jalr	876(ra) # 80000c98 <release>
}
    80004934:	8526                	mv	a0,s1
    80004936:	60e2                	ld	ra,24(sp)
    80004938:	6442                	ld	s0,16(sp)
    8000493a:	64a2                	ld	s1,8(sp)
    8000493c:	6105                	addi	sp,sp,32
    8000493e:	8082                	ret

0000000080004940 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004940:	1101                	addi	sp,sp,-32
    80004942:	ec06                	sd	ra,24(sp)
    80004944:	e822                	sd	s0,16(sp)
    80004946:	e426                	sd	s1,8(sp)
    80004948:	1000                	addi	s0,sp,32
    8000494a:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    8000494c:	0001d517          	auipc	a0,0x1d
    80004950:	28c50513          	addi	a0,a0,652 # 80021bd8 <ftable>
    80004954:	ffffc097          	auipc	ra,0xffffc
    80004958:	290080e7          	jalr	656(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    8000495c:	40dc                	lw	a5,4(s1)
    8000495e:	02f05263          	blez	a5,80004982 <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004962:	2785                	addiw	a5,a5,1
    80004964:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004966:	0001d517          	auipc	a0,0x1d
    8000496a:	27250513          	addi	a0,a0,626 # 80021bd8 <ftable>
    8000496e:	ffffc097          	auipc	ra,0xffffc
    80004972:	32a080e7          	jalr	810(ra) # 80000c98 <release>
  return f;
}
    80004976:	8526                	mv	a0,s1
    80004978:	60e2                	ld	ra,24(sp)
    8000497a:	6442                	ld	s0,16(sp)
    8000497c:	64a2                	ld	s1,8(sp)
    8000497e:	6105                	addi	sp,sp,32
    80004980:	8082                	ret
    panic("filedup");
    80004982:	00004517          	auipc	a0,0x4
    80004986:	d6650513          	addi	a0,a0,-666 # 800086e8 <syscalls+0x250>
    8000498a:	ffffc097          	auipc	ra,0xffffc
    8000498e:	bb4080e7          	jalr	-1100(ra) # 8000053e <panic>

0000000080004992 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004992:	7139                	addi	sp,sp,-64
    80004994:	fc06                	sd	ra,56(sp)
    80004996:	f822                	sd	s0,48(sp)
    80004998:	f426                	sd	s1,40(sp)
    8000499a:	f04a                	sd	s2,32(sp)
    8000499c:	ec4e                	sd	s3,24(sp)
    8000499e:	e852                	sd	s4,16(sp)
    800049a0:	e456                	sd	s5,8(sp)
    800049a2:	0080                	addi	s0,sp,64
    800049a4:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    800049a6:	0001d517          	auipc	a0,0x1d
    800049aa:	23250513          	addi	a0,a0,562 # 80021bd8 <ftable>
    800049ae:	ffffc097          	auipc	ra,0xffffc
    800049b2:	236080e7          	jalr	566(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    800049b6:	40dc                	lw	a5,4(s1)
    800049b8:	06f05163          	blez	a5,80004a1a <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    800049bc:	37fd                	addiw	a5,a5,-1
    800049be:	0007871b          	sext.w	a4,a5
    800049c2:	c0dc                	sw	a5,4(s1)
    800049c4:	06e04363          	bgtz	a4,80004a2a <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    800049c8:	0004a903          	lw	s2,0(s1)
    800049cc:	0094ca83          	lbu	s5,9(s1)
    800049d0:	0104ba03          	ld	s4,16(s1)
    800049d4:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    800049d8:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    800049dc:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    800049e0:	0001d517          	auipc	a0,0x1d
    800049e4:	1f850513          	addi	a0,a0,504 # 80021bd8 <ftable>
    800049e8:	ffffc097          	auipc	ra,0xffffc
    800049ec:	2b0080e7          	jalr	688(ra) # 80000c98 <release>

  if(ff.type == FD_PIPE){
    800049f0:	4785                	li	a5,1
    800049f2:	04f90d63          	beq	s2,a5,80004a4c <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    800049f6:	3979                	addiw	s2,s2,-2
    800049f8:	4785                	li	a5,1
    800049fa:	0527e063          	bltu	a5,s2,80004a3a <fileclose+0xa8>
    begin_op();
    800049fe:	00000097          	auipc	ra,0x0
    80004a02:	ac8080e7          	jalr	-1336(ra) # 800044c6 <begin_op>
    iput(ff.ip);
    80004a06:	854e                	mv	a0,s3
    80004a08:	fffff097          	auipc	ra,0xfffff
    80004a0c:	2a6080e7          	jalr	678(ra) # 80003cae <iput>
    end_op();
    80004a10:	00000097          	auipc	ra,0x0
    80004a14:	b36080e7          	jalr	-1226(ra) # 80004546 <end_op>
    80004a18:	a00d                	j	80004a3a <fileclose+0xa8>
    panic("fileclose");
    80004a1a:	00004517          	auipc	a0,0x4
    80004a1e:	cd650513          	addi	a0,a0,-810 # 800086f0 <syscalls+0x258>
    80004a22:	ffffc097          	auipc	ra,0xffffc
    80004a26:	b1c080e7          	jalr	-1252(ra) # 8000053e <panic>
    release(&ftable.lock);
    80004a2a:	0001d517          	auipc	a0,0x1d
    80004a2e:	1ae50513          	addi	a0,a0,430 # 80021bd8 <ftable>
    80004a32:	ffffc097          	auipc	ra,0xffffc
    80004a36:	266080e7          	jalr	614(ra) # 80000c98 <release>
  }
}
    80004a3a:	70e2                	ld	ra,56(sp)
    80004a3c:	7442                	ld	s0,48(sp)
    80004a3e:	74a2                	ld	s1,40(sp)
    80004a40:	7902                	ld	s2,32(sp)
    80004a42:	69e2                	ld	s3,24(sp)
    80004a44:	6a42                	ld	s4,16(sp)
    80004a46:	6aa2                	ld	s5,8(sp)
    80004a48:	6121                	addi	sp,sp,64
    80004a4a:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004a4c:	85d6                	mv	a1,s5
    80004a4e:	8552                	mv	a0,s4
    80004a50:	00000097          	auipc	ra,0x0
    80004a54:	34c080e7          	jalr	844(ra) # 80004d9c <pipeclose>
    80004a58:	b7cd                	j	80004a3a <fileclose+0xa8>

0000000080004a5a <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004a5a:	715d                	addi	sp,sp,-80
    80004a5c:	e486                	sd	ra,72(sp)
    80004a5e:	e0a2                	sd	s0,64(sp)
    80004a60:	fc26                	sd	s1,56(sp)
    80004a62:	f84a                	sd	s2,48(sp)
    80004a64:	f44e                	sd	s3,40(sp)
    80004a66:	0880                	addi	s0,sp,80
    80004a68:	84aa                	mv	s1,a0
    80004a6a:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004a6c:	ffffd097          	auipc	ra,0xffffd
    80004a70:	f5c080e7          	jalr	-164(ra) # 800019c8 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004a74:	409c                	lw	a5,0(s1)
    80004a76:	37f9                	addiw	a5,a5,-2
    80004a78:	4705                	li	a4,1
    80004a7a:	04f76763          	bltu	a4,a5,80004ac8 <filestat+0x6e>
    80004a7e:	892a                	mv	s2,a0
    ilock(f->ip);
    80004a80:	6c88                	ld	a0,24(s1)
    80004a82:	fffff097          	auipc	ra,0xfffff
    80004a86:	072080e7          	jalr	114(ra) # 80003af4 <ilock>
    stati(f->ip, &st);
    80004a8a:	fb840593          	addi	a1,s0,-72
    80004a8e:	6c88                	ld	a0,24(s1)
    80004a90:	fffff097          	auipc	ra,0xfffff
    80004a94:	2ee080e7          	jalr	750(ra) # 80003d7e <stati>
    iunlock(f->ip);
    80004a98:	6c88                	ld	a0,24(s1)
    80004a9a:	fffff097          	auipc	ra,0xfffff
    80004a9e:	11c080e7          	jalr	284(ra) # 80003bb6 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004aa2:	46e1                	li	a3,24
    80004aa4:	fb840613          	addi	a2,s0,-72
    80004aa8:	85ce                	mv	a1,s3
    80004aaa:	07093503          	ld	a0,112(s2)
    80004aae:	ffffd097          	auipc	ra,0xffffd
    80004ab2:	bcc080e7          	jalr	-1076(ra) # 8000167a <copyout>
    80004ab6:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004aba:	60a6                	ld	ra,72(sp)
    80004abc:	6406                	ld	s0,64(sp)
    80004abe:	74e2                	ld	s1,56(sp)
    80004ac0:	7942                	ld	s2,48(sp)
    80004ac2:	79a2                	ld	s3,40(sp)
    80004ac4:	6161                	addi	sp,sp,80
    80004ac6:	8082                	ret
  return -1;
    80004ac8:	557d                	li	a0,-1
    80004aca:	bfc5                	j	80004aba <filestat+0x60>

0000000080004acc <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004acc:	7179                	addi	sp,sp,-48
    80004ace:	f406                	sd	ra,40(sp)
    80004ad0:	f022                	sd	s0,32(sp)
    80004ad2:	ec26                	sd	s1,24(sp)
    80004ad4:	e84a                	sd	s2,16(sp)
    80004ad6:	e44e                	sd	s3,8(sp)
    80004ad8:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004ada:	00854783          	lbu	a5,8(a0)
    80004ade:	c3d5                	beqz	a5,80004b82 <fileread+0xb6>
    80004ae0:	84aa                	mv	s1,a0
    80004ae2:	89ae                	mv	s3,a1
    80004ae4:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004ae6:	411c                	lw	a5,0(a0)
    80004ae8:	4705                	li	a4,1
    80004aea:	04e78963          	beq	a5,a4,80004b3c <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004aee:	470d                	li	a4,3
    80004af0:	04e78d63          	beq	a5,a4,80004b4a <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004af4:	4709                	li	a4,2
    80004af6:	06e79e63          	bne	a5,a4,80004b72 <fileread+0xa6>
    ilock(f->ip);
    80004afa:	6d08                	ld	a0,24(a0)
    80004afc:	fffff097          	auipc	ra,0xfffff
    80004b00:	ff8080e7          	jalr	-8(ra) # 80003af4 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004b04:	874a                	mv	a4,s2
    80004b06:	5094                	lw	a3,32(s1)
    80004b08:	864e                	mv	a2,s3
    80004b0a:	4585                	li	a1,1
    80004b0c:	6c88                	ld	a0,24(s1)
    80004b0e:	fffff097          	auipc	ra,0xfffff
    80004b12:	29a080e7          	jalr	666(ra) # 80003da8 <readi>
    80004b16:	892a                	mv	s2,a0
    80004b18:	00a05563          	blez	a0,80004b22 <fileread+0x56>
      f->off += r;
    80004b1c:	509c                	lw	a5,32(s1)
    80004b1e:	9fa9                	addw	a5,a5,a0
    80004b20:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004b22:	6c88                	ld	a0,24(s1)
    80004b24:	fffff097          	auipc	ra,0xfffff
    80004b28:	092080e7          	jalr	146(ra) # 80003bb6 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004b2c:	854a                	mv	a0,s2
    80004b2e:	70a2                	ld	ra,40(sp)
    80004b30:	7402                	ld	s0,32(sp)
    80004b32:	64e2                	ld	s1,24(sp)
    80004b34:	6942                	ld	s2,16(sp)
    80004b36:	69a2                	ld	s3,8(sp)
    80004b38:	6145                	addi	sp,sp,48
    80004b3a:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004b3c:	6908                	ld	a0,16(a0)
    80004b3e:	00000097          	auipc	ra,0x0
    80004b42:	3c8080e7          	jalr	968(ra) # 80004f06 <piperead>
    80004b46:	892a                	mv	s2,a0
    80004b48:	b7d5                	j	80004b2c <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004b4a:	02451783          	lh	a5,36(a0)
    80004b4e:	03079693          	slli	a3,a5,0x30
    80004b52:	92c1                	srli	a3,a3,0x30
    80004b54:	4725                	li	a4,9
    80004b56:	02d76863          	bltu	a4,a3,80004b86 <fileread+0xba>
    80004b5a:	0792                	slli	a5,a5,0x4
    80004b5c:	0001d717          	auipc	a4,0x1d
    80004b60:	fdc70713          	addi	a4,a4,-36 # 80021b38 <devsw>
    80004b64:	97ba                	add	a5,a5,a4
    80004b66:	639c                	ld	a5,0(a5)
    80004b68:	c38d                	beqz	a5,80004b8a <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004b6a:	4505                	li	a0,1
    80004b6c:	9782                	jalr	a5
    80004b6e:	892a                	mv	s2,a0
    80004b70:	bf75                	j	80004b2c <fileread+0x60>
    panic("fileread");
    80004b72:	00004517          	auipc	a0,0x4
    80004b76:	b8e50513          	addi	a0,a0,-1138 # 80008700 <syscalls+0x268>
    80004b7a:	ffffc097          	auipc	ra,0xffffc
    80004b7e:	9c4080e7          	jalr	-1596(ra) # 8000053e <panic>
    return -1;
    80004b82:	597d                	li	s2,-1
    80004b84:	b765                	j	80004b2c <fileread+0x60>
      return -1;
    80004b86:	597d                	li	s2,-1
    80004b88:	b755                	j	80004b2c <fileread+0x60>
    80004b8a:	597d                	li	s2,-1
    80004b8c:	b745                	j	80004b2c <fileread+0x60>

0000000080004b8e <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80004b8e:	715d                	addi	sp,sp,-80
    80004b90:	e486                	sd	ra,72(sp)
    80004b92:	e0a2                	sd	s0,64(sp)
    80004b94:	fc26                	sd	s1,56(sp)
    80004b96:	f84a                	sd	s2,48(sp)
    80004b98:	f44e                	sd	s3,40(sp)
    80004b9a:	f052                	sd	s4,32(sp)
    80004b9c:	ec56                	sd	s5,24(sp)
    80004b9e:	e85a                	sd	s6,16(sp)
    80004ba0:	e45e                	sd	s7,8(sp)
    80004ba2:	e062                	sd	s8,0(sp)
    80004ba4:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80004ba6:	00954783          	lbu	a5,9(a0)
    80004baa:	10078663          	beqz	a5,80004cb6 <filewrite+0x128>
    80004bae:	892a                	mv	s2,a0
    80004bb0:	8aae                	mv	s5,a1
    80004bb2:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004bb4:	411c                	lw	a5,0(a0)
    80004bb6:	4705                	li	a4,1
    80004bb8:	02e78263          	beq	a5,a4,80004bdc <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004bbc:	470d                	li	a4,3
    80004bbe:	02e78663          	beq	a5,a4,80004bea <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004bc2:	4709                	li	a4,2
    80004bc4:	0ee79163          	bne	a5,a4,80004ca6 <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004bc8:	0ac05d63          	blez	a2,80004c82 <filewrite+0xf4>
    int i = 0;
    80004bcc:	4981                	li	s3,0
    80004bce:	6b05                	lui	s6,0x1
    80004bd0:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80004bd4:	6b85                	lui	s7,0x1
    80004bd6:	c00b8b9b          	addiw	s7,s7,-1024
    80004bda:	a861                	j	80004c72 <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80004bdc:	6908                	ld	a0,16(a0)
    80004bde:	00000097          	auipc	ra,0x0
    80004be2:	22e080e7          	jalr	558(ra) # 80004e0c <pipewrite>
    80004be6:	8a2a                	mv	s4,a0
    80004be8:	a045                	j	80004c88 <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004bea:	02451783          	lh	a5,36(a0)
    80004bee:	03079693          	slli	a3,a5,0x30
    80004bf2:	92c1                	srli	a3,a3,0x30
    80004bf4:	4725                	li	a4,9
    80004bf6:	0cd76263          	bltu	a4,a3,80004cba <filewrite+0x12c>
    80004bfa:	0792                	slli	a5,a5,0x4
    80004bfc:	0001d717          	auipc	a4,0x1d
    80004c00:	f3c70713          	addi	a4,a4,-196 # 80021b38 <devsw>
    80004c04:	97ba                	add	a5,a5,a4
    80004c06:	679c                	ld	a5,8(a5)
    80004c08:	cbdd                	beqz	a5,80004cbe <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80004c0a:	4505                	li	a0,1
    80004c0c:	9782                	jalr	a5
    80004c0e:	8a2a                	mv	s4,a0
    80004c10:	a8a5                	j	80004c88 <filewrite+0xfa>
    80004c12:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004c16:	00000097          	auipc	ra,0x0
    80004c1a:	8b0080e7          	jalr	-1872(ra) # 800044c6 <begin_op>
      ilock(f->ip);
    80004c1e:	01893503          	ld	a0,24(s2)
    80004c22:	fffff097          	auipc	ra,0xfffff
    80004c26:	ed2080e7          	jalr	-302(ra) # 80003af4 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004c2a:	8762                	mv	a4,s8
    80004c2c:	02092683          	lw	a3,32(s2)
    80004c30:	01598633          	add	a2,s3,s5
    80004c34:	4585                	li	a1,1
    80004c36:	01893503          	ld	a0,24(s2)
    80004c3a:	fffff097          	auipc	ra,0xfffff
    80004c3e:	266080e7          	jalr	614(ra) # 80003ea0 <writei>
    80004c42:	84aa                	mv	s1,a0
    80004c44:	00a05763          	blez	a0,80004c52 <filewrite+0xc4>
        f->off += r;
    80004c48:	02092783          	lw	a5,32(s2)
    80004c4c:	9fa9                	addw	a5,a5,a0
    80004c4e:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004c52:	01893503          	ld	a0,24(s2)
    80004c56:	fffff097          	auipc	ra,0xfffff
    80004c5a:	f60080e7          	jalr	-160(ra) # 80003bb6 <iunlock>
      end_op();
    80004c5e:	00000097          	auipc	ra,0x0
    80004c62:	8e8080e7          	jalr	-1816(ra) # 80004546 <end_op>

      if(r != n1){
    80004c66:	009c1f63          	bne	s8,s1,80004c84 <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80004c6a:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004c6e:	0149db63          	bge	s3,s4,80004c84 <filewrite+0xf6>
      int n1 = n - i;
    80004c72:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80004c76:	84be                	mv	s1,a5
    80004c78:	2781                	sext.w	a5,a5
    80004c7a:	f8fb5ce3          	bge	s6,a5,80004c12 <filewrite+0x84>
    80004c7e:	84de                	mv	s1,s7
    80004c80:	bf49                	j	80004c12 <filewrite+0x84>
    int i = 0;
    80004c82:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004c84:	013a1f63          	bne	s4,s3,80004ca2 <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004c88:	8552                	mv	a0,s4
    80004c8a:	60a6                	ld	ra,72(sp)
    80004c8c:	6406                	ld	s0,64(sp)
    80004c8e:	74e2                	ld	s1,56(sp)
    80004c90:	7942                	ld	s2,48(sp)
    80004c92:	79a2                	ld	s3,40(sp)
    80004c94:	7a02                	ld	s4,32(sp)
    80004c96:	6ae2                	ld	s5,24(sp)
    80004c98:	6b42                	ld	s6,16(sp)
    80004c9a:	6ba2                	ld	s7,8(sp)
    80004c9c:	6c02                	ld	s8,0(sp)
    80004c9e:	6161                	addi	sp,sp,80
    80004ca0:	8082                	ret
    ret = (i == n ? n : -1);
    80004ca2:	5a7d                	li	s4,-1
    80004ca4:	b7d5                	j	80004c88 <filewrite+0xfa>
    panic("filewrite");
    80004ca6:	00004517          	auipc	a0,0x4
    80004caa:	a6a50513          	addi	a0,a0,-1430 # 80008710 <syscalls+0x278>
    80004cae:	ffffc097          	auipc	ra,0xffffc
    80004cb2:	890080e7          	jalr	-1904(ra) # 8000053e <panic>
    return -1;
    80004cb6:	5a7d                	li	s4,-1
    80004cb8:	bfc1                	j	80004c88 <filewrite+0xfa>
      return -1;
    80004cba:	5a7d                	li	s4,-1
    80004cbc:	b7f1                	j	80004c88 <filewrite+0xfa>
    80004cbe:	5a7d                	li	s4,-1
    80004cc0:	b7e1                	j	80004c88 <filewrite+0xfa>

0000000080004cc2 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004cc2:	7179                	addi	sp,sp,-48
    80004cc4:	f406                	sd	ra,40(sp)
    80004cc6:	f022                	sd	s0,32(sp)
    80004cc8:	ec26                	sd	s1,24(sp)
    80004cca:	e84a                	sd	s2,16(sp)
    80004ccc:	e44e                	sd	s3,8(sp)
    80004cce:	e052                	sd	s4,0(sp)
    80004cd0:	1800                	addi	s0,sp,48
    80004cd2:	84aa                	mv	s1,a0
    80004cd4:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004cd6:	0005b023          	sd	zero,0(a1)
    80004cda:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004cde:	00000097          	auipc	ra,0x0
    80004ce2:	bf8080e7          	jalr	-1032(ra) # 800048d6 <filealloc>
    80004ce6:	e088                	sd	a0,0(s1)
    80004ce8:	c551                	beqz	a0,80004d74 <pipealloc+0xb2>
    80004cea:	00000097          	auipc	ra,0x0
    80004cee:	bec080e7          	jalr	-1044(ra) # 800048d6 <filealloc>
    80004cf2:	00aa3023          	sd	a0,0(s4)
    80004cf6:	c92d                	beqz	a0,80004d68 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004cf8:	ffffc097          	auipc	ra,0xffffc
    80004cfc:	dfc080e7          	jalr	-516(ra) # 80000af4 <kalloc>
    80004d00:	892a                	mv	s2,a0
    80004d02:	c125                	beqz	a0,80004d62 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004d04:	4985                	li	s3,1
    80004d06:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004d0a:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004d0e:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004d12:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004d16:	00004597          	auipc	a1,0x4
    80004d1a:	a0a58593          	addi	a1,a1,-1526 # 80008720 <syscalls+0x288>
    80004d1e:	ffffc097          	auipc	ra,0xffffc
    80004d22:	e36080e7          	jalr	-458(ra) # 80000b54 <initlock>
  (*f0)->type = FD_PIPE;
    80004d26:	609c                	ld	a5,0(s1)
    80004d28:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004d2c:	609c                	ld	a5,0(s1)
    80004d2e:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004d32:	609c                	ld	a5,0(s1)
    80004d34:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004d38:	609c                	ld	a5,0(s1)
    80004d3a:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004d3e:	000a3783          	ld	a5,0(s4)
    80004d42:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004d46:	000a3783          	ld	a5,0(s4)
    80004d4a:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004d4e:	000a3783          	ld	a5,0(s4)
    80004d52:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004d56:	000a3783          	ld	a5,0(s4)
    80004d5a:	0127b823          	sd	s2,16(a5)
  return 0;
    80004d5e:	4501                	li	a0,0
    80004d60:	a025                	j	80004d88 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004d62:	6088                	ld	a0,0(s1)
    80004d64:	e501                	bnez	a0,80004d6c <pipealloc+0xaa>
    80004d66:	a039                	j	80004d74 <pipealloc+0xb2>
    80004d68:	6088                	ld	a0,0(s1)
    80004d6a:	c51d                	beqz	a0,80004d98 <pipealloc+0xd6>
    fileclose(*f0);
    80004d6c:	00000097          	auipc	ra,0x0
    80004d70:	c26080e7          	jalr	-986(ra) # 80004992 <fileclose>
  if(*f1)
    80004d74:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004d78:	557d                	li	a0,-1
  if(*f1)
    80004d7a:	c799                	beqz	a5,80004d88 <pipealloc+0xc6>
    fileclose(*f1);
    80004d7c:	853e                	mv	a0,a5
    80004d7e:	00000097          	auipc	ra,0x0
    80004d82:	c14080e7          	jalr	-1004(ra) # 80004992 <fileclose>
  return -1;
    80004d86:	557d                	li	a0,-1
}
    80004d88:	70a2                	ld	ra,40(sp)
    80004d8a:	7402                	ld	s0,32(sp)
    80004d8c:	64e2                	ld	s1,24(sp)
    80004d8e:	6942                	ld	s2,16(sp)
    80004d90:	69a2                	ld	s3,8(sp)
    80004d92:	6a02                	ld	s4,0(sp)
    80004d94:	6145                	addi	sp,sp,48
    80004d96:	8082                	ret
  return -1;
    80004d98:	557d                	li	a0,-1
    80004d9a:	b7fd                	j	80004d88 <pipealloc+0xc6>

0000000080004d9c <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004d9c:	1101                	addi	sp,sp,-32
    80004d9e:	ec06                	sd	ra,24(sp)
    80004da0:	e822                	sd	s0,16(sp)
    80004da2:	e426                	sd	s1,8(sp)
    80004da4:	e04a                	sd	s2,0(sp)
    80004da6:	1000                	addi	s0,sp,32
    80004da8:	84aa                	mv	s1,a0
    80004daa:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004dac:	ffffc097          	auipc	ra,0xffffc
    80004db0:	e38080e7          	jalr	-456(ra) # 80000be4 <acquire>
  if(writable){
    80004db4:	02090d63          	beqz	s2,80004dee <pipeclose+0x52>
    pi->writeopen = 0;
    80004db8:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004dbc:	21848513          	addi	a0,s1,536
    80004dc0:	ffffd097          	auipc	ra,0xffffd
    80004dc4:	7a2080e7          	jalr	1954(ra) # 80002562 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004dc8:	2204b783          	ld	a5,544(s1)
    80004dcc:	eb95                	bnez	a5,80004e00 <pipeclose+0x64>
    release(&pi->lock);
    80004dce:	8526                	mv	a0,s1
    80004dd0:	ffffc097          	auipc	ra,0xffffc
    80004dd4:	ec8080e7          	jalr	-312(ra) # 80000c98 <release>
    kfree((char*)pi);
    80004dd8:	8526                	mv	a0,s1
    80004dda:	ffffc097          	auipc	ra,0xffffc
    80004dde:	c1e080e7          	jalr	-994(ra) # 800009f8 <kfree>
  } else
    release(&pi->lock);
}
    80004de2:	60e2                	ld	ra,24(sp)
    80004de4:	6442                	ld	s0,16(sp)
    80004de6:	64a2                	ld	s1,8(sp)
    80004de8:	6902                	ld	s2,0(sp)
    80004dea:	6105                	addi	sp,sp,32
    80004dec:	8082                	ret
    pi->readopen = 0;
    80004dee:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004df2:	21c48513          	addi	a0,s1,540
    80004df6:	ffffd097          	auipc	ra,0xffffd
    80004dfa:	76c080e7          	jalr	1900(ra) # 80002562 <wakeup>
    80004dfe:	b7e9                	j	80004dc8 <pipeclose+0x2c>
    release(&pi->lock);
    80004e00:	8526                	mv	a0,s1
    80004e02:	ffffc097          	auipc	ra,0xffffc
    80004e06:	e96080e7          	jalr	-362(ra) # 80000c98 <release>
}
    80004e0a:	bfe1                	j	80004de2 <pipeclose+0x46>

0000000080004e0c <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004e0c:	7159                	addi	sp,sp,-112
    80004e0e:	f486                	sd	ra,104(sp)
    80004e10:	f0a2                	sd	s0,96(sp)
    80004e12:	eca6                	sd	s1,88(sp)
    80004e14:	e8ca                	sd	s2,80(sp)
    80004e16:	e4ce                	sd	s3,72(sp)
    80004e18:	e0d2                	sd	s4,64(sp)
    80004e1a:	fc56                	sd	s5,56(sp)
    80004e1c:	f85a                	sd	s6,48(sp)
    80004e1e:	f45e                	sd	s7,40(sp)
    80004e20:	f062                	sd	s8,32(sp)
    80004e22:	ec66                	sd	s9,24(sp)
    80004e24:	1880                	addi	s0,sp,112
    80004e26:	84aa                	mv	s1,a0
    80004e28:	8aae                	mv	s5,a1
    80004e2a:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004e2c:	ffffd097          	auipc	ra,0xffffd
    80004e30:	b9c080e7          	jalr	-1124(ra) # 800019c8 <myproc>
    80004e34:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004e36:	8526                	mv	a0,s1
    80004e38:	ffffc097          	auipc	ra,0xffffc
    80004e3c:	dac080e7          	jalr	-596(ra) # 80000be4 <acquire>
  while(i < n){
    80004e40:	0d405163          	blez	s4,80004f02 <pipewrite+0xf6>
    80004e44:	8ba6                	mv	s7,s1
  int i = 0;
    80004e46:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004e48:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004e4a:	21848c93          	addi	s9,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004e4e:	21c48c13          	addi	s8,s1,540
    80004e52:	a08d                	j	80004eb4 <pipewrite+0xa8>
      release(&pi->lock);
    80004e54:	8526                	mv	a0,s1
    80004e56:	ffffc097          	auipc	ra,0xffffc
    80004e5a:	e42080e7          	jalr	-446(ra) # 80000c98 <release>
      return -1;
    80004e5e:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004e60:	854a                	mv	a0,s2
    80004e62:	70a6                	ld	ra,104(sp)
    80004e64:	7406                	ld	s0,96(sp)
    80004e66:	64e6                	ld	s1,88(sp)
    80004e68:	6946                	ld	s2,80(sp)
    80004e6a:	69a6                	ld	s3,72(sp)
    80004e6c:	6a06                	ld	s4,64(sp)
    80004e6e:	7ae2                	ld	s5,56(sp)
    80004e70:	7b42                	ld	s6,48(sp)
    80004e72:	7ba2                	ld	s7,40(sp)
    80004e74:	7c02                	ld	s8,32(sp)
    80004e76:	6ce2                	ld	s9,24(sp)
    80004e78:	6165                	addi	sp,sp,112
    80004e7a:	8082                	ret
      wakeup(&pi->nread);
    80004e7c:	8566                	mv	a0,s9
    80004e7e:	ffffd097          	auipc	ra,0xffffd
    80004e82:	6e4080e7          	jalr	1764(ra) # 80002562 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004e86:	85de                	mv	a1,s7
    80004e88:	8562                	mv	a0,s8
    80004e8a:	ffffd097          	auipc	ra,0xffffd
    80004e8e:	538080e7          	jalr	1336(ra) # 800023c2 <sleep>
    80004e92:	a839                	j	80004eb0 <pipewrite+0xa4>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004e94:	21c4a783          	lw	a5,540(s1)
    80004e98:	0017871b          	addiw	a4,a5,1
    80004e9c:	20e4ae23          	sw	a4,540(s1)
    80004ea0:	1ff7f793          	andi	a5,a5,511
    80004ea4:	97a6                	add	a5,a5,s1
    80004ea6:	f9f44703          	lbu	a4,-97(s0)
    80004eaa:	00e78c23          	sb	a4,24(a5)
      i++;
    80004eae:	2905                	addiw	s2,s2,1
  while(i < n){
    80004eb0:	03495d63          	bge	s2,s4,80004eea <pipewrite+0xde>
    if(pi->readopen == 0 || pr->killed){
    80004eb4:	2204a783          	lw	a5,544(s1)
    80004eb8:	dfd1                	beqz	a5,80004e54 <pipewrite+0x48>
    80004eba:	0289a783          	lw	a5,40(s3)
    80004ebe:	fbd9                	bnez	a5,80004e54 <pipewrite+0x48>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004ec0:	2184a783          	lw	a5,536(s1)
    80004ec4:	21c4a703          	lw	a4,540(s1)
    80004ec8:	2007879b          	addiw	a5,a5,512
    80004ecc:	faf708e3          	beq	a4,a5,80004e7c <pipewrite+0x70>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004ed0:	4685                	li	a3,1
    80004ed2:	01590633          	add	a2,s2,s5
    80004ed6:	f9f40593          	addi	a1,s0,-97
    80004eda:	0709b503          	ld	a0,112(s3)
    80004ede:	ffffd097          	auipc	ra,0xffffd
    80004ee2:	828080e7          	jalr	-2008(ra) # 80001706 <copyin>
    80004ee6:	fb6517e3          	bne	a0,s6,80004e94 <pipewrite+0x88>
  wakeup(&pi->nread);
    80004eea:	21848513          	addi	a0,s1,536
    80004eee:	ffffd097          	auipc	ra,0xffffd
    80004ef2:	674080e7          	jalr	1652(ra) # 80002562 <wakeup>
  release(&pi->lock);
    80004ef6:	8526                	mv	a0,s1
    80004ef8:	ffffc097          	auipc	ra,0xffffc
    80004efc:	da0080e7          	jalr	-608(ra) # 80000c98 <release>
  return i;
    80004f00:	b785                	j	80004e60 <pipewrite+0x54>
  int i = 0;
    80004f02:	4901                	li	s2,0
    80004f04:	b7dd                	j	80004eea <pipewrite+0xde>

0000000080004f06 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004f06:	715d                	addi	sp,sp,-80
    80004f08:	e486                	sd	ra,72(sp)
    80004f0a:	e0a2                	sd	s0,64(sp)
    80004f0c:	fc26                	sd	s1,56(sp)
    80004f0e:	f84a                	sd	s2,48(sp)
    80004f10:	f44e                	sd	s3,40(sp)
    80004f12:	f052                	sd	s4,32(sp)
    80004f14:	ec56                	sd	s5,24(sp)
    80004f16:	e85a                	sd	s6,16(sp)
    80004f18:	0880                	addi	s0,sp,80
    80004f1a:	84aa                	mv	s1,a0
    80004f1c:	892e                	mv	s2,a1
    80004f1e:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004f20:	ffffd097          	auipc	ra,0xffffd
    80004f24:	aa8080e7          	jalr	-1368(ra) # 800019c8 <myproc>
    80004f28:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004f2a:	8b26                	mv	s6,s1
    80004f2c:	8526                	mv	a0,s1
    80004f2e:	ffffc097          	auipc	ra,0xffffc
    80004f32:	cb6080e7          	jalr	-842(ra) # 80000be4 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004f36:	2184a703          	lw	a4,536(s1)
    80004f3a:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004f3e:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004f42:	02f71463          	bne	a4,a5,80004f6a <piperead+0x64>
    80004f46:	2244a783          	lw	a5,548(s1)
    80004f4a:	c385                	beqz	a5,80004f6a <piperead+0x64>
    if(pr->killed){
    80004f4c:	028a2783          	lw	a5,40(s4)
    80004f50:	ebc1                	bnez	a5,80004fe0 <piperead+0xda>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004f52:	85da                	mv	a1,s6
    80004f54:	854e                	mv	a0,s3
    80004f56:	ffffd097          	auipc	ra,0xffffd
    80004f5a:	46c080e7          	jalr	1132(ra) # 800023c2 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004f5e:	2184a703          	lw	a4,536(s1)
    80004f62:	21c4a783          	lw	a5,540(s1)
    80004f66:	fef700e3          	beq	a4,a5,80004f46 <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004f6a:	09505263          	blez	s5,80004fee <piperead+0xe8>
    80004f6e:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004f70:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    80004f72:	2184a783          	lw	a5,536(s1)
    80004f76:	21c4a703          	lw	a4,540(s1)
    80004f7a:	02f70d63          	beq	a4,a5,80004fb4 <piperead+0xae>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004f7e:	0017871b          	addiw	a4,a5,1
    80004f82:	20e4ac23          	sw	a4,536(s1)
    80004f86:	1ff7f793          	andi	a5,a5,511
    80004f8a:	97a6                	add	a5,a5,s1
    80004f8c:	0187c783          	lbu	a5,24(a5)
    80004f90:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004f94:	4685                	li	a3,1
    80004f96:	fbf40613          	addi	a2,s0,-65
    80004f9a:	85ca                	mv	a1,s2
    80004f9c:	070a3503          	ld	a0,112(s4)
    80004fa0:	ffffc097          	auipc	ra,0xffffc
    80004fa4:	6da080e7          	jalr	1754(ra) # 8000167a <copyout>
    80004fa8:	01650663          	beq	a0,s6,80004fb4 <piperead+0xae>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004fac:	2985                	addiw	s3,s3,1
    80004fae:	0905                	addi	s2,s2,1
    80004fb0:	fd3a91e3          	bne	s5,s3,80004f72 <piperead+0x6c>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004fb4:	21c48513          	addi	a0,s1,540
    80004fb8:	ffffd097          	auipc	ra,0xffffd
    80004fbc:	5aa080e7          	jalr	1450(ra) # 80002562 <wakeup>
  release(&pi->lock);
    80004fc0:	8526                	mv	a0,s1
    80004fc2:	ffffc097          	auipc	ra,0xffffc
    80004fc6:	cd6080e7          	jalr	-810(ra) # 80000c98 <release>
  return i;
}
    80004fca:	854e                	mv	a0,s3
    80004fcc:	60a6                	ld	ra,72(sp)
    80004fce:	6406                	ld	s0,64(sp)
    80004fd0:	74e2                	ld	s1,56(sp)
    80004fd2:	7942                	ld	s2,48(sp)
    80004fd4:	79a2                	ld	s3,40(sp)
    80004fd6:	7a02                	ld	s4,32(sp)
    80004fd8:	6ae2                	ld	s5,24(sp)
    80004fda:	6b42                	ld	s6,16(sp)
    80004fdc:	6161                	addi	sp,sp,80
    80004fde:	8082                	ret
      release(&pi->lock);
    80004fe0:	8526                	mv	a0,s1
    80004fe2:	ffffc097          	auipc	ra,0xffffc
    80004fe6:	cb6080e7          	jalr	-842(ra) # 80000c98 <release>
      return -1;
    80004fea:	59fd                	li	s3,-1
    80004fec:	bff9                	j	80004fca <piperead+0xc4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004fee:	4981                	li	s3,0
    80004ff0:	b7d1                	j	80004fb4 <piperead+0xae>

0000000080004ff2 <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80004ff2:	df010113          	addi	sp,sp,-528
    80004ff6:	20113423          	sd	ra,520(sp)
    80004ffa:	20813023          	sd	s0,512(sp)
    80004ffe:	ffa6                	sd	s1,504(sp)
    80005000:	fbca                	sd	s2,496(sp)
    80005002:	f7ce                	sd	s3,488(sp)
    80005004:	f3d2                	sd	s4,480(sp)
    80005006:	efd6                	sd	s5,472(sp)
    80005008:	ebda                	sd	s6,464(sp)
    8000500a:	e7de                	sd	s7,456(sp)
    8000500c:	e3e2                	sd	s8,448(sp)
    8000500e:	ff66                	sd	s9,440(sp)
    80005010:	fb6a                	sd	s10,432(sp)
    80005012:	f76e                	sd	s11,424(sp)
    80005014:	0c00                	addi	s0,sp,528
    80005016:	84aa                	mv	s1,a0
    80005018:	dea43c23          	sd	a0,-520(s0)
    8000501c:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80005020:	ffffd097          	auipc	ra,0xffffd
    80005024:	9a8080e7          	jalr	-1624(ra) # 800019c8 <myproc>
    80005028:	892a                	mv	s2,a0

  begin_op();
    8000502a:	fffff097          	auipc	ra,0xfffff
    8000502e:	49c080e7          	jalr	1180(ra) # 800044c6 <begin_op>

  if((ip = namei(path)) == 0){
    80005032:	8526                	mv	a0,s1
    80005034:	fffff097          	auipc	ra,0xfffff
    80005038:	276080e7          	jalr	630(ra) # 800042aa <namei>
    8000503c:	c92d                	beqz	a0,800050ae <exec+0xbc>
    8000503e:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80005040:	fffff097          	auipc	ra,0xfffff
    80005044:	ab4080e7          	jalr	-1356(ra) # 80003af4 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80005048:	04000713          	li	a4,64
    8000504c:	4681                	li	a3,0
    8000504e:	e5040613          	addi	a2,s0,-432
    80005052:	4581                	li	a1,0
    80005054:	8526                	mv	a0,s1
    80005056:	fffff097          	auipc	ra,0xfffff
    8000505a:	d52080e7          	jalr	-686(ra) # 80003da8 <readi>
    8000505e:	04000793          	li	a5,64
    80005062:	00f51a63          	bne	a0,a5,80005076 <exec+0x84>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80005066:	e5042703          	lw	a4,-432(s0)
    8000506a:	464c47b7          	lui	a5,0x464c4
    8000506e:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80005072:	04f70463          	beq	a4,a5,800050ba <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80005076:	8526                	mv	a0,s1
    80005078:	fffff097          	auipc	ra,0xfffff
    8000507c:	cde080e7          	jalr	-802(ra) # 80003d56 <iunlockput>
    end_op();
    80005080:	fffff097          	auipc	ra,0xfffff
    80005084:	4c6080e7          	jalr	1222(ra) # 80004546 <end_op>
  }
  return -1;
    80005088:	557d                	li	a0,-1
}
    8000508a:	20813083          	ld	ra,520(sp)
    8000508e:	20013403          	ld	s0,512(sp)
    80005092:	74fe                	ld	s1,504(sp)
    80005094:	795e                	ld	s2,496(sp)
    80005096:	79be                	ld	s3,488(sp)
    80005098:	7a1e                	ld	s4,480(sp)
    8000509a:	6afe                	ld	s5,472(sp)
    8000509c:	6b5e                	ld	s6,464(sp)
    8000509e:	6bbe                	ld	s7,456(sp)
    800050a0:	6c1e                	ld	s8,448(sp)
    800050a2:	7cfa                	ld	s9,440(sp)
    800050a4:	7d5a                	ld	s10,432(sp)
    800050a6:	7dba                	ld	s11,424(sp)
    800050a8:	21010113          	addi	sp,sp,528
    800050ac:	8082                	ret
    end_op();
    800050ae:	fffff097          	auipc	ra,0xfffff
    800050b2:	498080e7          	jalr	1176(ra) # 80004546 <end_op>
    return -1;
    800050b6:	557d                	li	a0,-1
    800050b8:	bfc9                	j	8000508a <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    800050ba:	854a                	mv	a0,s2
    800050bc:	ffffd097          	auipc	ra,0xffffd
    800050c0:	9d0080e7          	jalr	-1584(ra) # 80001a8c <proc_pagetable>
    800050c4:	8baa                	mv	s7,a0
    800050c6:	d945                	beqz	a0,80005076 <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800050c8:	e7042983          	lw	s3,-400(s0)
    800050cc:	e8845783          	lhu	a5,-376(s0)
    800050d0:	c7ad                	beqz	a5,8000513a <exec+0x148>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    800050d2:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800050d4:	4b01                	li	s6,0
    if((ph.vaddr % PGSIZE) != 0)
    800050d6:	6c85                	lui	s9,0x1
    800050d8:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    800050dc:	def43823          	sd	a5,-528(s0)
    800050e0:	a42d                	j	8000530a <exec+0x318>
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    800050e2:	00003517          	auipc	a0,0x3
    800050e6:	64650513          	addi	a0,a0,1606 # 80008728 <syscalls+0x290>
    800050ea:	ffffb097          	auipc	ra,0xffffb
    800050ee:	454080e7          	jalr	1108(ra) # 8000053e <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    800050f2:	8756                	mv	a4,s5
    800050f4:	012d86bb          	addw	a3,s11,s2
    800050f8:	4581                	li	a1,0
    800050fa:	8526                	mv	a0,s1
    800050fc:	fffff097          	auipc	ra,0xfffff
    80005100:	cac080e7          	jalr	-852(ra) # 80003da8 <readi>
    80005104:	2501                	sext.w	a0,a0
    80005106:	1aaa9963          	bne	s5,a0,800052b8 <exec+0x2c6>
  for(i = 0; i < sz; i += PGSIZE){
    8000510a:	6785                	lui	a5,0x1
    8000510c:	0127893b          	addw	s2,a5,s2
    80005110:	77fd                	lui	a5,0xfffff
    80005112:	01478a3b          	addw	s4,a5,s4
    80005116:	1f897163          	bgeu	s2,s8,800052f8 <exec+0x306>
    pa = walkaddr(pagetable, va + i);
    8000511a:	02091593          	slli	a1,s2,0x20
    8000511e:	9181                	srli	a1,a1,0x20
    80005120:	95ea                	add	a1,a1,s10
    80005122:	855e                	mv	a0,s7
    80005124:	ffffc097          	auipc	ra,0xffffc
    80005128:	f52080e7          	jalr	-174(ra) # 80001076 <walkaddr>
    8000512c:	862a                	mv	a2,a0
    if(pa == 0)
    8000512e:	d955                	beqz	a0,800050e2 <exec+0xf0>
      n = PGSIZE;
    80005130:	8ae6                	mv	s5,s9
    if(sz - i < PGSIZE)
    80005132:	fd9a70e3          	bgeu	s4,s9,800050f2 <exec+0x100>
      n = sz - i;
    80005136:	8ad2                	mv	s5,s4
    80005138:	bf6d                	j	800050f2 <exec+0x100>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    8000513a:	4901                	li	s2,0
  iunlockput(ip);
    8000513c:	8526                	mv	a0,s1
    8000513e:	fffff097          	auipc	ra,0xfffff
    80005142:	c18080e7          	jalr	-1000(ra) # 80003d56 <iunlockput>
  end_op();
    80005146:	fffff097          	auipc	ra,0xfffff
    8000514a:	400080e7          	jalr	1024(ra) # 80004546 <end_op>
  p = myproc();
    8000514e:	ffffd097          	auipc	ra,0xffffd
    80005152:	87a080e7          	jalr	-1926(ra) # 800019c8 <myproc>
    80005156:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    80005158:	06853d03          	ld	s10,104(a0)
  sz = PGROUNDUP(sz);
    8000515c:	6785                	lui	a5,0x1
    8000515e:	17fd                	addi	a5,a5,-1
    80005160:	993e                	add	s2,s2,a5
    80005162:	757d                	lui	a0,0xfffff
    80005164:	00a977b3          	and	a5,s2,a0
    80005168:	e0f43423          	sd	a5,-504(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    8000516c:	6609                	lui	a2,0x2
    8000516e:	963e                	add	a2,a2,a5
    80005170:	85be                	mv	a1,a5
    80005172:	855e                	mv	a0,s7
    80005174:	ffffc097          	auipc	ra,0xffffc
    80005178:	2b6080e7          	jalr	694(ra) # 8000142a <uvmalloc>
    8000517c:	8b2a                	mv	s6,a0
  ip = 0;
    8000517e:	4481                	li	s1,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80005180:	12050c63          	beqz	a0,800052b8 <exec+0x2c6>
  uvmclear(pagetable, sz-2*PGSIZE);
    80005184:	75f9                	lui	a1,0xffffe
    80005186:	95aa                	add	a1,a1,a0
    80005188:	855e                	mv	a0,s7
    8000518a:	ffffc097          	auipc	ra,0xffffc
    8000518e:	4be080e7          	jalr	1214(ra) # 80001648 <uvmclear>
  stackbase = sp - PGSIZE;
    80005192:	7c7d                	lui	s8,0xfffff
    80005194:	9c5a                	add	s8,s8,s6
  for(argc = 0; argv[argc]; argc++) {
    80005196:	e0043783          	ld	a5,-512(s0)
    8000519a:	6388                	ld	a0,0(a5)
    8000519c:	c535                	beqz	a0,80005208 <exec+0x216>
    8000519e:	e9040993          	addi	s3,s0,-368
    800051a2:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    800051a6:	895a                	mv	s2,s6
    sp -= strlen(argv[argc]) + 1;
    800051a8:	ffffc097          	auipc	ra,0xffffc
    800051ac:	cbc080e7          	jalr	-836(ra) # 80000e64 <strlen>
    800051b0:	2505                	addiw	a0,a0,1
    800051b2:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    800051b6:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    800051ba:	13896363          	bltu	s2,s8,800052e0 <exec+0x2ee>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    800051be:	e0043d83          	ld	s11,-512(s0)
    800051c2:	000dba03          	ld	s4,0(s11)
    800051c6:	8552                	mv	a0,s4
    800051c8:	ffffc097          	auipc	ra,0xffffc
    800051cc:	c9c080e7          	jalr	-868(ra) # 80000e64 <strlen>
    800051d0:	0015069b          	addiw	a3,a0,1
    800051d4:	8652                	mv	a2,s4
    800051d6:	85ca                	mv	a1,s2
    800051d8:	855e                	mv	a0,s7
    800051da:	ffffc097          	auipc	ra,0xffffc
    800051de:	4a0080e7          	jalr	1184(ra) # 8000167a <copyout>
    800051e2:	10054363          	bltz	a0,800052e8 <exec+0x2f6>
    ustack[argc] = sp;
    800051e6:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    800051ea:	0485                	addi	s1,s1,1
    800051ec:	008d8793          	addi	a5,s11,8
    800051f0:	e0f43023          	sd	a5,-512(s0)
    800051f4:	008db503          	ld	a0,8(s11)
    800051f8:	c911                	beqz	a0,8000520c <exec+0x21a>
    if(argc >= MAXARG)
    800051fa:	09a1                	addi	s3,s3,8
    800051fc:	fb3c96e3          	bne	s9,s3,800051a8 <exec+0x1b6>
  sz = sz1;
    80005200:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005204:	4481                	li	s1,0
    80005206:	a84d                	j	800052b8 <exec+0x2c6>
  sp = sz;
    80005208:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    8000520a:	4481                	li	s1,0
  ustack[argc] = 0;
    8000520c:	00349793          	slli	a5,s1,0x3
    80005210:	f9040713          	addi	a4,s0,-112
    80005214:	97ba                	add	a5,a5,a4
    80005216:	f007b023          	sd	zero,-256(a5) # f00 <_entry-0x7ffff100>
  sp -= (argc+1) * sizeof(uint64);
    8000521a:	00148693          	addi	a3,s1,1
    8000521e:	068e                	slli	a3,a3,0x3
    80005220:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80005224:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80005228:	01897663          	bgeu	s2,s8,80005234 <exec+0x242>
  sz = sz1;
    8000522c:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005230:	4481                	li	s1,0
    80005232:	a059                	j	800052b8 <exec+0x2c6>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80005234:	e9040613          	addi	a2,s0,-368
    80005238:	85ca                	mv	a1,s2
    8000523a:	855e                	mv	a0,s7
    8000523c:	ffffc097          	auipc	ra,0xffffc
    80005240:	43e080e7          	jalr	1086(ra) # 8000167a <copyout>
    80005244:	0a054663          	bltz	a0,800052f0 <exec+0x2fe>
  p->trapframe->a1 = sp;
    80005248:	078ab783          	ld	a5,120(s5)
    8000524c:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80005250:	df843783          	ld	a5,-520(s0)
    80005254:	0007c703          	lbu	a4,0(a5)
    80005258:	cf11                	beqz	a4,80005274 <exec+0x282>
    8000525a:	0785                	addi	a5,a5,1
    if(*s == '/')
    8000525c:	02f00693          	li	a3,47
    80005260:	a039                	j	8000526e <exec+0x27c>
      last = s+1;
    80005262:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    80005266:	0785                	addi	a5,a5,1
    80005268:	fff7c703          	lbu	a4,-1(a5)
    8000526c:	c701                	beqz	a4,80005274 <exec+0x282>
    if(*s == '/')
    8000526e:	fed71ce3          	bne	a4,a3,80005266 <exec+0x274>
    80005272:	bfc5                	j	80005262 <exec+0x270>
  safestrcpy(p->name, last, sizeof(p->name));
    80005274:	4641                	li	a2,16
    80005276:	df843583          	ld	a1,-520(s0)
    8000527a:	178a8513          	addi	a0,s5,376
    8000527e:	ffffc097          	auipc	ra,0xffffc
    80005282:	bb4080e7          	jalr	-1100(ra) # 80000e32 <safestrcpy>
  oldpagetable = p->pagetable;
    80005286:	070ab503          	ld	a0,112(s5)
  p->pagetable = pagetable;
    8000528a:	077ab823          	sd	s7,112(s5)
  p->sz = sz;
    8000528e:	076ab423          	sd	s6,104(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80005292:	078ab783          	ld	a5,120(s5)
    80005296:	e6843703          	ld	a4,-408(s0)
    8000529a:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    8000529c:	078ab783          	ld	a5,120(s5)
    800052a0:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    800052a4:	85ea                	mv	a1,s10
    800052a6:	ffffd097          	auipc	ra,0xffffd
    800052aa:	882080e7          	jalr	-1918(ra) # 80001b28 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    800052ae:	0004851b          	sext.w	a0,s1
    800052b2:	bbe1                	j	8000508a <exec+0x98>
    800052b4:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    800052b8:	e0843583          	ld	a1,-504(s0)
    800052bc:	855e                	mv	a0,s7
    800052be:	ffffd097          	auipc	ra,0xffffd
    800052c2:	86a080e7          	jalr	-1942(ra) # 80001b28 <proc_freepagetable>
  if(ip){
    800052c6:	da0498e3          	bnez	s1,80005076 <exec+0x84>
  return -1;
    800052ca:	557d                	li	a0,-1
    800052cc:	bb7d                	j	8000508a <exec+0x98>
    800052ce:	e1243423          	sd	s2,-504(s0)
    800052d2:	b7dd                	j	800052b8 <exec+0x2c6>
    800052d4:	e1243423          	sd	s2,-504(s0)
    800052d8:	b7c5                	j	800052b8 <exec+0x2c6>
    800052da:	e1243423          	sd	s2,-504(s0)
    800052de:	bfe9                	j	800052b8 <exec+0x2c6>
  sz = sz1;
    800052e0:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800052e4:	4481                	li	s1,0
    800052e6:	bfc9                	j	800052b8 <exec+0x2c6>
  sz = sz1;
    800052e8:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800052ec:	4481                	li	s1,0
    800052ee:	b7e9                	j	800052b8 <exec+0x2c6>
  sz = sz1;
    800052f0:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800052f4:	4481                	li	s1,0
    800052f6:	b7c9                	j	800052b8 <exec+0x2c6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    800052f8:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800052fc:	2b05                	addiw	s6,s6,1
    800052fe:	0389899b          	addiw	s3,s3,56
    80005302:	e8845783          	lhu	a5,-376(s0)
    80005306:	e2fb5be3          	bge	s6,a5,8000513c <exec+0x14a>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    8000530a:	2981                	sext.w	s3,s3
    8000530c:	03800713          	li	a4,56
    80005310:	86ce                	mv	a3,s3
    80005312:	e1840613          	addi	a2,s0,-488
    80005316:	4581                	li	a1,0
    80005318:	8526                	mv	a0,s1
    8000531a:	fffff097          	auipc	ra,0xfffff
    8000531e:	a8e080e7          	jalr	-1394(ra) # 80003da8 <readi>
    80005322:	03800793          	li	a5,56
    80005326:	f8f517e3          	bne	a0,a5,800052b4 <exec+0x2c2>
    if(ph.type != ELF_PROG_LOAD)
    8000532a:	e1842783          	lw	a5,-488(s0)
    8000532e:	4705                	li	a4,1
    80005330:	fce796e3          	bne	a5,a4,800052fc <exec+0x30a>
    if(ph.memsz < ph.filesz)
    80005334:	e4043603          	ld	a2,-448(s0)
    80005338:	e3843783          	ld	a5,-456(s0)
    8000533c:	f8f669e3          	bltu	a2,a5,800052ce <exec+0x2dc>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80005340:	e2843783          	ld	a5,-472(s0)
    80005344:	963e                	add	a2,a2,a5
    80005346:	f8f667e3          	bltu	a2,a5,800052d4 <exec+0x2e2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    8000534a:	85ca                	mv	a1,s2
    8000534c:	855e                	mv	a0,s7
    8000534e:	ffffc097          	auipc	ra,0xffffc
    80005352:	0dc080e7          	jalr	220(ra) # 8000142a <uvmalloc>
    80005356:	e0a43423          	sd	a0,-504(s0)
    8000535a:	d141                	beqz	a0,800052da <exec+0x2e8>
    if((ph.vaddr % PGSIZE) != 0)
    8000535c:	e2843d03          	ld	s10,-472(s0)
    80005360:	df043783          	ld	a5,-528(s0)
    80005364:	00fd77b3          	and	a5,s10,a5
    80005368:	fba1                	bnez	a5,800052b8 <exec+0x2c6>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    8000536a:	e2042d83          	lw	s11,-480(s0)
    8000536e:	e3842c03          	lw	s8,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80005372:	f80c03e3          	beqz	s8,800052f8 <exec+0x306>
    80005376:	8a62                	mv	s4,s8
    80005378:	4901                	li	s2,0
    8000537a:	b345                	j	8000511a <exec+0x128>

000000008000537c <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    8000537c:	7179                	addi	sp,sp,-48
    8000537e:	f406                	sd	ra,40(sp)
    80005380:	f022                	sd	s0,32(sp)
    80005382:	ec26                	sd	s1,24(sp)
    80005384:	e84a                	sd	s2,16(sp)
    80005386:	1800                	addi	s0,sp,48
    80005388:	892e                	mv	s2,a1
    8000538a:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    8000538c:	fdc40593          	addi	a1,s0,-36
    80005390:	ffffe097          	auipc	ra,0xffffe
    80005394:	ba4080e7          	jalr	-1116(ra) # 80002f34 <argint>
    80005398:	04054063          	bltz	a0,800053d8 <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    8000539c:	fdc42703          	lw	a4,-36(s0)
    800053a0:	47bd                	li	a5,15
    800053a2:	02e7ed63          	bltu	a5,a4,800053dc <argfd+0x60>
    800053a6:	ffffc097          	auipc	ra,0xffffc
    800053aa:	622080e7          	jalr	1570(ra) # 800019c8 <myproc>
    800053ae:	fdc42703          	lw	a4,-36(s0)
    800053b2:	01e70793          	addi	a5,a4,30
    800053b6:	078e                	slli	a5,a5,0x3
    800053b8:	953e                	add	a0,a0,a5
    800053ba:	611c                	ld	a5,0(a0)
    800053bc:	c395                	beqz	a5,800053e0 <argfd+0x64>
    return -1;
  if(pfd)
    800053be:	00090463          	beqz	s2,800053c6 <argfd+0x4a>
    *pfd = fd;
    800053c2:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    800053c6:	4501                	li	a0,0
  if(pf)
    800053c8:	c091                	beqz	s1,800053cc <argfd+0x50>
    *pf = f;
    800053ca:	e09c                	sd	a5,0(s1)
}
    800053cc:	70a2                	ld	ra,40(sp)
    800053ce:	7402                	ld	s0,32(sp)
    800053d0:	64e2                	ld	s1,24(sp)
    800053d2:	6942                	ld	s2,16(sp)
    800053d4:	6145                	addi	sp,sp,48
    800053d6:	8082                	ret
    return -1;
    800053d8:	557d                	li	a0,-1
    800053da:	bfcd                	j	800053cc <argfd+0x50>
    return -1;
    800053dc:	557d                	li	a0,-1
    800053de:	b7fd                	j	800053cc <argfd+0x50>
    800053e0:	557d                	li	a0,-1
    800053e2:	b7ed                	j	800053cc <argfd+0x50>

00000000800053e4 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    800053e4:	1101                	addi	sp,sp,-32
    800053e6:	ec06                	sd	ra,24(sp)
    800053e8:	e822                	sd	s0,16(sp)
    800053ea:	e426                	sd	s1,8(sp)
    800053ec:	1000                	addi	s0,sp,32
    800053ee:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    800053f0:	ffffc097          	auipc	ra,0xffffc
    800053f4:	5d8080e7          	jalr	1496(ra) # 800019c8 <myproc>
    800053f8:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    800053fa:	0f050793          	addi	a5,a0,240 # fffffffffffff0f0 <end+0xffffffff7ffd90f0>
    800053fe:	4501                	li	a0,0
    80005400:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80005402:	6398                	ld	a4,0(a5)
    80005404:	cb19                	beqz	a4,8000541a <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80005406:	2505                	addiw	a0,a0,1
    80005408:	07a1                	addi	a5,a5,8
    8000540a:	fed51ce3          	bne	a0,a3,80005402 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    8000540e:	557d                	li	a0,-1
}
    80005410:	60e2                	ld	ra,24(sp)
    80005412:	6442                	ld	s0,16(sp)
    80005414:	64a2                	ld	s1,8(sp)
    80005416:	6105                	addi	sp,sp,32
    80005418:	8082                	ret
      p->ofile[fd] = f;
    8000541a:	01e50793          	addi	a5,a0,30
    8000541e:	078e                	slli	a5,a5,0x3
    80005420:	963e                	add	a2,a2,a5
    80005422:	e204                	sd	s1,0(a2)
      return fd;
    80005424:	b7f5                	j	80005410 <fdalloc+0x2c>

0000000080005426 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80005426:	715d                	addi	sp,sp,-80
    80005428:	e486                	sd	ra,72(sp)
    8000542a:	e0a2                	sd	s0,64(sp)
    8000542c:	fc26                	sd	s1,56(sp)
    8000542e:	f84a                	sd	s2,48(sp)
    80005430:	f44e                	sd	s3,40(sp)
    80005432:	f052                	sd	s4,32(sp)
    80005434:	ec56                	sd	s5,24(sp)
    80005436:	0880                	addi	s0,sp,80
    80005438:	89ae                	mv	s3,a1
    8000543a:	8ab2                	mv	s5,a2
    8000543c:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    8000543e:	fb040593          	addi	a1,s0,-80
    80005442:	fffff097          	auipc	ra,0xfffff
    80005446:	e86080e7          	jalr	-378(ra) # 800042c8 <nameiparent>
    8000544a:	892a                	mv	s2,a0
    8000544c:	12050f63          	beqz	a0,8000558a <create+0x164>
    return 0;

  ilock(dp);
    80005450:	ffffe097          	auipc	ra,0xffffe
    80005454:	6a4080e7          	jalr	1700(ra) # 80003af4 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80005458:	4601                	li	a2,0
    8000545a:	fb040593          	addi	a1,s0,-80
    8000545e:	854a                	mv	a0,s2
    80005460:	fffff097          	auipc	ra,0xfffff
    80005464:	b78080e7          	jalr	-1160(ra) # 80003fd8 <dirlookup>
    80005468:	84aa                	mv	s1,a0
    8000546a:	c921                	beqz	a0,800054ba <create+0x94>
    iunlockput(dp);
    8000546c:	854a                	mv	a0,s2
    8000546e:	fffff097          	auipc	ra,0xfffff
    80005472:	8e8080e7          	jalr	-1816(ra) # 80003d56 <iunlockput>
    ilock(ip);
    80005476:	8526                	mv	a0,s1
    80005478:	ffffe097          	auipc	ra,0xffffe
    8000547c:	67c080e7          	jalr	1660(ra) # 80003af4 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80005480:	2981                	sext.w	s3,s3
    80005482:	4789                	li	a5,2
    80005484:	02f99463          	bne	s3,a5,800054ac <create+0x86>
    80005488:	0444d783          	lhu	a5,68(s1)
    8000548c:	37f9                	addiw	a5,a5,-2
    8000548e:	17c2                	slli	a5,a5,0x30
    80005490:	93c1                	srli	a5,a5,0x30
    80005492:	4705                	li	a4,1
    80005494:	00f76c63          	bltu	a4,a5,800054ac <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    80005498:	8526                	mv	a0,s1
    8000549a:	60a6                	ld	ra,72(sp)
    8000549c:	6406                	ld	s0,64(sp)
    8000549e:	74e2                	ld	s1,56(sp)
    800054a0:	7942                	ld	s2,48(sp)
    800054a2:	79a2                	ld	s3,40(sp)
    800054a4:	7a02                	ld	s4,32(sp)
    800054a6:	6ae2                	ld	s5,24(sp)
    800054a8:	6161                	addi	sp,sp,80
    800054aa:	8082                	ret
    iunlockput(ip);
    800054ac:	8526                	mv	a0,s1
    800054ae:	fffff097          	auipc	ra,0xfffff
    800054b2:	8a8080e7          	jalr	-1880(ra) # 80003d56 <iunlockput>
    return 0;
    800054b6:	4481                	li	s1,0
    800054b8:	b7c5                	j	80005498 <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    800054ba:	85ce                	mv	a1,s3
    800054bc:	00092503          	lw	a0,0(s2)
    800054c0:	ffffe097          	auipc	ra,0xffffe
    800054c4:	49c080e7          	jalr	1180(ra) # 8000395c <ialloc>
    800054c8:	84aa                	mv	s1,a0
    800054ca:	c529                	beqz	a0,80005514 <create+0xee>
  ilock(ip);
    800054cc:	ffffe097          	auipc	ra,0xffffe
    800054d0:	628080e7          	jalr	1576(ra) # 80003af4 <ilock>
  ip->major = major;
    800054d4:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    800054d8:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    800054dc:	4785                	li	a5,1
    800054de:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800054e2:	8526                	mv	a0,s1
    800054e4:	ffffe097          	auipc	ra,0xffffe
    800054e8:	546080e7          	jalr	1350(ra) # 80003a2a <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    800054ec:	2981                	sext.w	s3,s3
    800054ee:	4785                	li	a5,1
    800054f0:	02f98a63          	beq	s3,a5,80005524 <create+0xfe>
  if(dirlink(dp, name, ip->inum) < 0)
    800054f4:	40d0                	lw	a2,4(s1)
    800054f6:	fb040593          	addi	a1,s0,-80
    800054fa:	854a                	mv	a0,s2
    800054fc:	fffff097          	auipc	ra,0xfffff
    80005500:	cec080e7          	jalr	-788(ra) # 800041e8 <dirlink>
    80005504:	06054b63          	bltz	a0,8000557a <create+0x154>
  iunlockput(dp);
    80005508:	854a                	mv	a0,s2
    8000550a:	fffff097          	auipc	ra,0xfffff
    8000550e:	84c080e7          	jalr	-1972(ra) # 80003d56 <iunlockput>
  return ip;
    80005512:	b759                	j	80005498 <create+0x72>
    panic("create: ialloc");
    80005514:	00003517          	auipc	a0,0x3
    80005518:	23450513          	addi	a0,a0,564 # 80008748 <syscalls+0x2b0>
    8000551c:	ffffb097          	auipc	ra,0xffffb
    80005520:	022080e7          	jalr	34(ra) # 8000053e <panic>
    dp->nlink++;  // for ".."
    80005524:	04a95783          	lhu	a5,74(s2)
    80005528:	2785                	addiw	a5,a5,1
    8000552a:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    8000552e:	854a                	mv	a0,s2
    80005530:	ffffe097          	auipc	ra,0xffffe
    80005534:	4fa080e7          	jalr	1274(ra) # 80003a2a <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80005538:	40d0                	lw	a2,4(s1)
    8000553a:	00003597          	auipc	a1,0x3
    8000553e:	21e58593          	addi	a1,a1,542 # 80008758 <syscalls+0x2c0>
    80005542:	8526                	mv	a0,s1
    80005544:	fffff097          	auipc	ra,0xfffff
    80005548:	ca4080e7          	jalr	-860(ra) # 800041e8 <dirlink>
    8000554c:	00054f63          	bltz	a0,8000556a <create+0x144>
    80005550:	00492603          	lw	a2,4(s2)
    80005554:	00003597          	auipc	a1,0x3
    80005558:	20c58593          	addi	a1,a1,524 # 80008760 <syscalls+0x2c8>
    8000555c:	8526                	mv	a0,s1
    8000555e:	fffff097          	auipc	ra,0xfffff
    80005562:	c8a080e7          	jalr	-886(ra) # 800041e8 <dirlink>
    80005566:	f80557e3          	bgez	a0,800054f4 <create+0xce>
      panic("create dots");
    8000556a:	00003517          	auipc	a0,0x3
    8000556e:	1fe50513          	addi	a0,a0,510 # 80008768 <syscalls+0x2d0>
    80005572:	ffffb097          	auipc	ra,0xffffb
    80005576:	fcc080e7          	jalr	-52(ra) # 8000053e <panic>
    panic("create: dirlink");
    8000557a:	00003517          	auipc	a0,0x3
    8000557e:	1fe50513          	addi	a0,a0,510 # 80008778 <syscalls+0x2e0>
    80005582:	ffffb097          	auipc	ra,0xffffb
    80005586:	fbc080e7          	jalr	-68(ra) # 8000053e <panic>
    return 0;
    8000558a:	84aa                	mv	s1,a0
    8000558c:	b731                	j	80005498 <create+0x72>

000000008000558e <sys_dup>:
{
    8000558e:	7179                	addi	sp,sp,-48
    80005590:	f406                	sd	ra,40(sp)
    80005592:	f022                	sd	s0,32(sp)
    80005594:	ec26                	sd	s1,24(sp)
    80005596:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    80005598:	fd840613          	addi	a2,s0,-40
    8000559c:	4581                	li	a1,0
    8000559e:	4501                	li	a0,0
    800055a0:	00000097          	auipc	ra,0x0
    800055a4:	ddc080e7          	jalr	-548(ra) # 8000537c <argfd>
    return -1;
    800055a8:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    800055aa:	02054363          	bltz	a0,800055d0 <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    800055ae:	fd843503          	ld	a0,-40(s0)
    800055b2:	00000097          	auipc	ra,0x0
    800055b6:	e32080e7          	jalr	-462(ra) # 800053e4 <fdalloc>
    800055ba:	84aa                	mv	s1,a0
    return -1;
    800055bc:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    800055be:	00054963          	bltz	a0,800055d0 <sys_dup+0x42>
  filedup(f);
    800055c2:	fd843503          	ld	a0,-40(s0)
    800055c6:	fffff097          	auipc	ra,0xfffff
    800055ca:	37a080e7          	jalr	890(ra) # 80004940 <filedup>
  return fd;
    800055ce:	87a6                	mv	a5,s1
}
    800055d0:	853e                	mv	a0,a5
    800055d2:	70a2                	ld	ra,40(sp)
    800055d4:	7402                	ld	s0,32(sp)
    800055d6:	64e2                	ld	s1,24(sp)
    800055d8:	6145                	addi	sp,sp,48
    800055da:	8082                	ret

00000000800055dc <sys_read>:
{
    800055dc:	7179                	addi	sp,sp,-48
    800055de:	f406                	sd	ra,40(sp)
    800055e0:	f022                	sd	s0,32(sp)
    800055e2:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800055e4:	fe840613          	addi	a2,s0,-24
    800055e8:	4581                	li	a1,0
    800055ea:	4501                	li	a0,0
    800055ec:	00000097          	auipc	ra,0x0
    800055f0:	d90080e7          	jalr	-624(ra) # 8000537c <argfd>
    return -1;
    800055f4:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800055f6:	04054163          	bltz	a0,80005638 <sys_read+0x5c>
    800055fa:	fe440593          	addi	a1,s0,-28
    800055fe:	4509                	li	a0,2
    80005600:	ffffe097          	auipc	ra,0xffffe
    80005604:	934080e7          	jalr	-1740(ra) # 80002f34 <argint>
    return -1;
    80005608:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000560a:	02054763          	bltz	a0,80005638 <sys_read+0x5c>
    8000560e:	fd840593          	addi	a1,s0,-40
    80005612:	4505                	li	a0,1
    80005614:	ffffe097          	auipc	ra,0xffffe
    80005618:	942080e7          	jalr	-1726(ra) # 80002f56 <argaddr>
    return -1;
    8000561c:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000561e:	00054d63          	bltz	a0,80005638 <sys_read+0x5c>
  return fileread(f, p, n);
    80005622:	fe442603          	lw	a2,-28(s0)
    80005626:	fd843583          	ld	a1,-40(s0)
    8000562a:	fe843503          	ld	a0,-24(s0)
    8000562e:	fffff097          	auipc	ra,0xfffff
    80005632:	49e080e7          	jalr	1182(ra) # 80004acc <fileread>
    80005636:	87aa                	mv	a5,a0
}
    80005638:	853e                	mv	a0,a5
    8000563a:	70a2                	ld	ra,40(sp)
    8000563c:	7402                	ld	s0,32(sp)
    8000563e:	6145                	addi	sp,sp,48
    80005640:	8082                	ret

0000000080005642 <sys_write>:
{
    80005642:	7179                	addi	sp,sp,-48
    80005644:	f406                	sd	ra,40(sp)
    80005646:	f022                	sd	s0,32(sp)
    80005648:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000564a:	fe840613          	addi	a2,s0,-24
    8000564e:	4581                	li	a1,0
    80005650:	4501                	li	a0,0
    80005652:	00000097          	auipc	ra,0x0
    80005656:	d2a080e7          	jalr	-726(ra) # 8000537c <argfd>
    return -1;
    8000565a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000565c:	04054163          	bltz	a0,8000569e <sys_write+0x5c>
    80005660:	fe440593          	addi	a1,s0,-28
    80005664:	4509                	li	a0,2
    80005666:	ffffe097          	auipc	ra,0xffffe
    8000566a:	8ce080e7          	jalr	-1842(ra) # 80002f34 <argint>
    return -1;
    8000566e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005670:	02054763          	bltz	a0,8000569e <sys_write+0x5c>
    80005674:	fd840593          	addi	a1,s0,-40
    80005678:	4505                	li	a0,1
    8000567a:	ffffe097          	auipc	ra,0xffffe
    8000567e:	8dc080e7          	jalr	-1828(ra) # 80002f56 <argaddr>
    return -1;
    80005682:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005684:	00054d63          	bltz	a0,8000569e <sys_write+0x5c>
  return filewrite(f, p, n);
    80005688:	fe442603          	lw	a2,-28(s0)
    8000568c:	fd843583          	ld	a1,-40(s0)
    80005690:	fe843503          	ld	a0,-24(s0)
    80005694:	fffff097          	auipc	ra,0xfffff
    80005698:	4fa080e7          	jalr	1274(ra) # 80004b8e <filewrite>
    8000569c:	87aa                	mv	a5,a0
}
    8000569e:	853e                	mv	a0,a5
    800056a0:	70a2                	ld	ra,40(sp)
    800056a2:	7402                	ld	s0,32(sp)
    800056a4:	6145                	addi	sp,sp,48
    800056a6:	8082                	ret

00000000800056a8 <sys_close>:
{
    800056a8:	1101                	addi	sp,sp,-32
    800056aa:	ec06                	sd	ra,24(sp)
    800056ac:	e822                	sd	s0,16(sp)
    800056ae:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    800056b0:	fe040613          	addi	a2,s0,-32
    800056b4:	fec40593          	addi	a1,s0,-20
    800056b8:	4501                	li	a0,0
    800056ba:	00000097          	auipc	ra,0x0
    800056be:	cc2080e7          	jalr	-830(ra) # 8000537c <argfd>
    return -1;
    800056c2:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    800056c4:	02054463          	bltz	a0,800056ec <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    800056c8:	ffffc097          	auipc	ra,0xffffc
    800056cc:	300080e7          	jalr	768(ra) # 800019c8 <myproc>
    800056d0:	fec42783          	lw	a5,-20(s0)
    800056d4:	07f9                	addi	a5,a5,30
    800056d6:	078e                	slli	a5,a5,0x3
    800056d8:	97aa                	add	a5,a5,a0
    800056da:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    800056de:	fe043503          	ld	a0,-32(s0)
    800056e2:	fffff097          	auipc	ra,0xfffff
    800056e6:	2b0080e7          	jalr	688(ra) # 80004992 <fileclose>
  return 0;
    800056ea:	4781                	li	a5,0
}
    800056ec:	853e                	mv	a0,a5
    800056ee:	60e2                	ld	ra,24(sp)
    800056f0:	6442                	ld	s0,16(sp)
    800056f2:	6105                	addi	sp,sp,32
    800056f4:	8082                	ret

00000000800056f6 <sys_fstat>:
{
    800056f6:	1101                	addi	sp,sp,-32
    800056f8:	ec06                	sd	ra,24(sp)
    800056fa:	e822                	sd	s0,16(sp)
    800056fc:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800056fe:	fe840613          	addi	a2,s0,-24
    80005702:	4581                	li	a1,0
    80005704:	4501                	li	a0,0
    80005706:	00000097          	auipc	ra,0x0
    8000570a:	c76080e7          	jalr	-906(ra) # 8000537c <argfd>
    return -1;
    8000570e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005710:	02054563          	bltz	a0,8000573a <sys_fstat+0x44>
    80005714:	fe040593          	addi	a1,s0,-32
    80005718:	4505                	li	a0,1
    8000571a:	ffffe097          	auipc	ra,0xffffe
    8000571e:	83c080e7          	jalr	-1988(ra) # 80002f56 <argaddr>
    return -1;
    80005722:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005724:	00054b63          	bltz	a0,8000573a <sys_fstat+0x44>
  return filestat(f, st);
    80005728:	fe043583          	ld	a1,-32(s0)
    8000572c:	fe843503          	ld	a0,-24(s0)
    80005730:	fffff097          	auipc	ra,0xfffff
    80005734:	32a080e7          	jalr	810(ra) # 80004a5a <filestat>
    80005738:	87aa                	mv	a5,a0
}
    8000573a:	853e                	mv	a0,a5
    8000573c:	60e2                	ld	ra,24(sp)
    8000573e:	6442                	ld	s0,16(sp)
    80005740:	6105                	addi	sp,sp,32
    80005742:	8082                	ret

0000000080005744 <sys_link>:
{
    80005744:	7169                	addi	sp,sp,-304
    80005746:	f606                	sd	ra,296(sp)
    80005748:	f222                	sd	s0,288(sp)
    8000574a:	ee26                	sd	s1,280(sp)
    8000574c:	ea4a                	sd	s2,272(sp)
    8000574e:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005750:	08000613          	li	a2,128
    80005754:	ed040593          	addi	a1,s0,-304
    80005758:	4501                	li	a0,0
    8000575a:	ffffe097          	auipc	ra,0xffffe
    8000575e:	81e080e7          	jalr	-2018(ra) # 80002f78 <argstr>
    return -1;
    80005762:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005764:	10054e63          	bltz	a0,80005880 <sys_link+0x13c>
    80005768:	08000613          	li	a2,128
    8000576c:	f5040593          	addi	a1,s0,-176
    80005770:	4505                	li	a0,1
    80005772:	ffffe097          	auipc	ra,0xffffe
    80005776:	806080e7          	jalr	-2042(ra) # 80002f78 <argstr>
    return -1;
    8000577a:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000577c:	10054263          	bltz	a0,80005880 <sys_link+0x13c>
  begin_op();
    80005780:	fffff097          	auipc	ra,0xfffff
    80005784:	d46080e7          	jalr	-698(ra) # 800044c6 <begin_op>
  if((ip = namei(old)) == 0){
    80005788:	ed040513          	addi	a0,s0,-304
    8000578c:	fffff097          	auipc	ra,0xfffff
    80005790:	b1e080e7          	jalr	-1250(ra) # 800042aa <namei>
    80005794:	84aa                	mv	s1,a0
    80005796:	c551                	beqz	a0,80005822 <sys_link+0xde>
  ilock(ip);
    80005798:	ffffe097          	auipc	ra,0xffffe
    8000579c:	35c080e7          	jalr	860(ra) # 80003af4 <ilock>
  if(ip->type == T_DIR){
    800057a0:	04449703          	lh	a4,68(s1)
    800057a4:	4785                	li	a5,1
    800057a6:	08f70463          	beq	a4,a5,8000582e <sys_link+0xea>
  ip->nlink++;
    800057aa:	04a4d783          	lhu	a5,74(s1)
    800057ae:	2785                	addiw	a5,a5,1
    800057b0:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800057b4:	8526                	mv	a0,s1
    800057b6:	ffffe097          	auipc	ra,0xffffe
    800057ba:	274080e7          	jalr	628(ra) # 80003a2a <iupdate>
  iunlock(ip);
    800057be:	8526                	mv	a0,s1
    800057c0:	ffffe097          	auipc	ra,0xffffe
    800057c4:	3f6080e7          	jalr	1014(ra) # 80003bb6 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    800057c8:	fd040593          	addi	a1,s0,-48
    800057cc:	f5040513          	addi	a0,s0,-176
    800057d0:	fffff097          	auipc	ra,0xfffff
    800057d4:	af8080e7          	jalr	-1288(ra) # 800042c8 <nameiparent>
    800057d8:	892a                	mv	s2,a0
    800057da:	c935                	beqz	a0,8000584e <sys_link+0x10a>
  ilock(dp);
    800057dc:	ffffe097          	auipc	ra,0xffffe
    800057e0:	318080e7          	jalr	792(ra) # 80003af4 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    800057e4:	00092703          	lw	a4,0(s2)
    800057e8:	409c                	lw	a5,0(s1)
    800057ea:	04f71d63          	bne	a4,a5,80005844 <sys_link+0x100>
    800057ee:	40d0                	lw	a2,4(s1)
    800057f0:	fd040593          	addi	a1,s0,-48
    800057f4:	854a                	mv	a0,s2
    800057f6:	fffff097          	auipc	ra,0xfffff
    800057fa:	9f2080e7          	jalr	-1550(ra) # 800041e8 <dirlink>
    800057fe:	04054363          	bltz	a0,80005844 <sys_link+0x100>
  iunlockput(dp);
    80005802:	854a                	mv	a0,s2
    80005804:	ffffe097          	auipc	ra,0xffffe
    80005808:	552080e7          	jalr	1362(ra) # 80003d56 <iunlockput>
  iput(ip);
    8000580c:	8526                	mv	a0,s1
    8000580e:	ffffe097          	auipc	ra,0xffffe
    80005812:	4a0080e7          	jalr	1184(ra) # 80003cae <iput>
  end_op();
    80005816:	fffff097          	auipc	ra,0xfffff
    8000581a:	d30080e7          	jalr	-720(ra) # 80004546 <end_op>
  return 0;
    8000581e:	4781                	li	a5,0
    80005820:	a085                	j	80005880 <sys_link+0x13c>
    end_op();
    80005822:	fffff097          	auipc	ra,0xfffff
    80005826:	d24080e7          	jalr	-732(ra) # 80004546 <end_op>
    return -1;
    8000582a:	57fd                	li	a5,-1
    8000582c:	a891                	j	80005880 <sys_link+0x13c>
    iunlockput(ip);
    8000582e:	8526                	mv	a0,s1
    80005830:	ffffe097          	auipc	ra,0xffffe
    80005834:	526080e7          	jalr	1318(ra) # 80003d56 <iunlockput>
    end_op();
    80005838:	fffff097          	auipc	ra,0xfffff
    8000583c:	d0e080e7          	jalr	-754(ra) # 80004546 <end_op>
    return -1;
    80005840:	57fd                	li	a5,-1
    80005842:	a83d                	j	80005880 <sys_link+0x13c>
    iunlockput(dp);
    80005844:	854a                	mv	a0,s2
    80005846:	ffffe097          	auipc	ra,0xffffe
    8000584a:	510080e7          	jalr	1296(ra) # 80003d56 <iunlockput>
  ilock(ip);
    8000584e:	8526                	mv	a0,s1
    80005850:	ffffe097          	auipc	ra,0xffffe
    80005854:	2a4080e7          	jalr	676(ra) # 80003af4 <ilock>
  ip->nlink--;
    80005858:	04a4d783          	lhu	a5,74(s1)
    8000585c:	37fd                	addiw	a5,a5,-1
    8000585e:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005862:	8526                	mv	a0,s1
    80005864:	ffffe097          	auipc	ra,0xffffe
    80005868:	1c6080e7          	jalr	454(ra) # 80003a2a <iupdate>
  iunlockput(ip);
    8000586c:	8526                	mv	a0,s1
    8000586e:	ffffe097          	auipc	ra,0xffffe
    80005872:	4e8080e7          	jalr	1256(ra) # 80003d56 <iunlockput>
  end_op();
    80005876:	fffff097          	auipc	ra,0xfffff
    8000587a:	cd0080e7          	jalr	-816(ra) # 80004546 <end_op>
  return -1;
    8000587e:	57fd                	li	a5,-1
}
    80005880:	853e                	mv	a0,a5
    80005882:	70b2                	ld	ra,296(sp)
    80005884:	7412                	ld	s0,288(sp)
    80005886:	64f2                	ld	s1,280(sp)
    80005888:	6952                	ld	s2,272(sp)
    8000588a:	6155                	addi	sp,sp,304
    8000588c:	8082                	ret

000000008000588e <sys_unlink>:
{
    8000588e:	7151                	addi	sp,sp,-240
    80005890:	f586                	sd	ra,232(sp)
    80005892:	f1a2                	sd	s0,224(sp)
    80005894:	eda6                	sd	s1,216(sp)
    80005896:	e9ca                	sd	s2,208(sp)
    80005898:	e5ce                	sd	s3,200(sp)
    8000589a:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    8000589c:	08000613          	li	a2,128
    800058a0:	f3040593          	addi	a1,s0,-208
    800058a4:	4501                	li	a0,0
    800058a6:	ffffd097          	auipc	ra,0xffffd
    800058aa:	6d2080e7          	jalr	1746(ra) # 80002f78 <argstr>
    800058ae:	18054163          	bltz	a0,80005a30 <sys_unlink+0x1a2>
  begin_op();
    800058b2:	fffff097          	auipc	ra,0xfffff
    800058b6:	c14080e7          	jalr	-1004(ra) # 800044c6 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    800058ba:	fb040593          	addi	a1,s0,-80
    800058be:	f3040513          	addi	a0,s0,-208
    800058c2:	fffff097          	auipc	ra,0xfffff
    800058c6:	a06080e7          	jalr	-1530(ra) # 800042c8 <nameiparent>
    800058ca:	84aa                	mv	s1,a0
    800058cc:	c979                	beqz	a0,800059a2 <sys_unlink+0x114>
  ilock(dp);
    800058ce:	ffffe097          	auipc	ra,0xffffe
    800058d2:	226080e7          	jalr	550(ra) # 80003af4 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    800058d6:	00003597          	auipc	a1,0x3
    800058da:	e8258593          	addi	a1,a1,-382 # 80008758 <syscalls+0x2c0>
    800058de:	fb040513          	addi	a0,s0,-80
    800058e2:	ffffe097          	auipc	ra,0xffffe
    800058e6:	6dc080e7          	jalr	1756(ra) # 80003fbe <namecmp>
    800058ea:	14050a63          	beqz	a0,80005a3e <sys_unlink+0x1b0>
    800058ee:	00003597          	auipc	a1,0x3
    800058f2:	e7258593          	addi	a1,a1,-398 # 80008760 <syscalls+0x2c8>
    800058f6:	fb040513          	addi	a0,s0,-80
    800058fa:	ffffe097          	auipc	ra,0xffffe
    800058fe:	6c4080e7          	jalr	1732(ra) # 80003fbe <namecmp>
    80005902:	12050e63          	beqz	a0,80005a3e <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005906:	f2c40613          	addi	a2,s0,-212
    8000590a:	fb040593          	addi	a1,s0,-80
    8000590e:	8526                	mv	a0,s1
    80005910:	ffffe097          	auipc	ra,0xffffe
    80005914:	6c8080e7          	jalr	1736(ra) # 80003fd8 <dirlookup>
    80005918:	892a                	mv	s2,a0
    8000591a:	12050263          	beqz	a0,80005a3e <sys_unlink+0x1b0>
  ilock(ip);
    8000591e:	ffffe097          	auipc	ra,0xffffe
    80005922:	1d6080e7          	jalr	470(ra) # 80003af4 <ilock>
  if(ip->nlink < 1)
    80005926:	04a91783          	lh	a5,74(s2)
    8000592a:	08f05263          	blez	a5,800059ae <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    8000592e:	04491703          	lh	a4,68(s2)
    80005932:	4785                	li	a5,1
    80005934:	08f70563          	beq	a4,a5,800059be <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005938:	4641                	li	a2,16
    8000593a:	4581                	li	a1,0
    8000593c:	fc040513          	addi	a0,s0,-64
    80005940:	ffffb097          	auipc	ra,0xffffb
    80005944:	3a0080e7          	jalr	928(ra) # 80000ce0 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005948:	4741                	li	a4,16
    8000594a:	f2c42683          	lw	a3,-212(s0)
    8000594e:	fc040613          	addi	a2,s0,-64
    80005952:	4581                	li	a1,0
    80005954:	8526                	mv	a0,s1
    80005956:	ffffe097          	auipc	ra,0xffffe
    8000595a:	54a080e7          	jalr	1354(ra) # 80003ea0 <writei>
    8000595e:	47c1                	li	a5,16
    80005960:	0af51563          	bne	a0,a5,80005a0a <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005964:	04491703          	lh	a4,68(s2)
    80005968:	4785                	li	a5,1
    8000596a:	0af70863          	beq	a4,a5,80005a1a <sys_unlink+0x18c>
  iunlockput(dp);
    8000596e:	8526                	mv	a0,s1
    80005970:	ffffe097          	auipc	ra,0xffffe
    80005974:	3e6080e7          	jalr	998(ra) # 80003d56 <iunlockput>
  ip->nlink--;
    80005978:	04a95783          	lhu	a5,74(s2)
    8000597c:	37fd                	addiw	a5,a5,-1
    8000597e:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005982:	854a                	mv	a0,s2
    80005984:	ffffe097          	auipc	ra,0xffffe
    80005988:	0a6080e7          	jalr	166(ra) # 80003a2a <iupdate>
  iunlockput(ip);
    8000598c:	854a                	mv	a0,s2
    8000598e:	ffffe097          	auipc	ra,0xffffe
    80005992:	3c8080e7          	jalr	968(ra) # 80003d56 <iunlockput>
  end_op();
    80005996:	fffff097          	auipc	ra,0xfffff
    8000599a:	bb0080e7          	jalr	-1104(ra) # 80004546 <end_op>
  return 0;
    8000599e:	4501                	li	a0,0
    800059a0:	a84d                	j	80005a52 <sys_unlink+0x1c4>
    end_op();
    800059a2:	fffff097          	auipc	ra,0xfffff
    800059a6:	ba4080e7          	jalr	-1116(ra) # 80004546 <end_op>
    return -1;
    800059aa:	557d                	li	a0,-1
    800059ac:	a05d                	j	80005a52 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    800059ae:	00003517          	auipc	a0,0x3
    800059b2:	dda50513          	addi	a0,a0,-550 # 80008788 <syscalls+0x2f0>
    800059b6:	ffffb097          	auipc	ra,0xffffb
    800059ba:	b88080e7          	jalr	-1144(ra) # 8000053e <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800059be:	04c92703          	lw	a4,76(s2)
    800059c2:	02000793          	li	a5,32
    800059c6:	f6e7f9e3          	bgeu	a5,a4,80005938 <sys_unlink+0xaa>
    800059ca:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800059ce:	4741                	li	a4,16
    800059d0:	86ce                	mv	a3,s3
    800059d2:	f1840613          	addi	a2,s0,-232
    800059d6:	4581                	li	a1,0
    800059d8:	854a                	mv	a0,s2
    800059da:	ffffe097          	auipc	ra,0xffffe
    800059de:	3ce080e7          	jalr	974(ra) # 80003da8 <readi>
    800059e2:	47c1                	li	a5,16
    800059e4:	00f51b63          	bne	a0,a5,800059fa <sys_unlink+0x16c>
    if(de.inum != 0)
    800059e8:	f1845783          	lhu	a5,-232(s0)
    800059ec:	e7a1                	bnez	a5,80005a34 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800059ee:	29c1                	addiw	s3,s3,16
    800059f0:	04c92783          	lw	a5,76(s2)
    800059f4:	fcf9ede3          	bltu	s3,a5,800059ce <sys_unlink+0x140>
    800059f8:	b781                	j	80005938 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    800059fa:	00003517          	auipc	a0,0x3
    800059fe:	da650513          	addi	a0,a0,-602 # 800087a0 <syscalls+0x308>
    80005a02:	ffffb097          	auipc	ra,0xffffb
    80005a06:	b3c080e7          	jalr	-1220(ra) # 8000053e <panic>
    panic("unlink: writei");
    80005a0a:	00003517          	auipc	a0,0x3
    80005a0e:	dae50513          	addi	a0,a0,-594 # 800087b8 <syscalls+0x320>
    80005a12:	ffffb097          	auipc	ra,0xffffb
    80005a16:	b2c080e7          	jalr	-1236(ra) # 8000053e <panic>
    dp->nlink--;
    80005a1a:	04a4d783          	lhu	a5,74(s1)
    80005a1e:	37fd                	addiw	a5,a5,-1
    80005a20:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005a24:	8526                	mv	a0,s1
    80005a26:	ffffe097          	auipc	ra,0xffffe
    80005a2a:	004080e7          	jalr	4(ra) # 80003a2a <iupdate>
    80005a2e:	b781                	j	8000596e <sys_unlink+0xe0>
    return -1;
    80005a30:	557d                	li	a0,-1
    80005a32:	a005                	j	80005a52 <sys_unlink+0x1c4>
    iunlockput(ip);
    80005a34:	854a                	mv	a0,s2
    80005a36:	ffffe097          	auipc	ra,0xffffe
    80005a3a:	320080e7          	jalr	800(ra) # 80003d56 <iunlockput>
  iunlockput(dp);
    80005a3e:	8526                	mv	a0,s1
    80005a40:	ffffe097          	auipc	ra,0xffffe
    80005a44:	316080e7          	jalr	790(ra) # 80003d56 <iunlockput>
  end_op();
    80005a48:	fffff097          	auipc	ra,0xfffff
    80005a4c:	afe080e7          	jalr	-1282(ra) # 80004546 <end_op>
  return -1;
    80005a50:	557d                	li	a0,-1
}
    80005a52:	70ae                	ld	ra,232(sp)
    80005a54:	740e                	ld	s0,224(sp)
    80005a56:	64ee                	ld	s1,216(sp)
    80005a58:	694e                	ld	s2,208(sp)
    80005a5a:	69ae                	ld	s3,200(sp)
    80005a5c:	616d                	addi	sp,sp,240
    80005a5e:	8082                	ret

0000000080005a60 <sys_open>:

uint64
sys_open(void)
{
    80005a60:	7131                	addi	sp,sp,-192
    80005a62:	fd06                	sd	ra,184(sp)
    80005a64:	f922                	sd	s0,176(sp)
    80005a66:	f526                	sd	s1,168(sp)
    80005a68:	f14a                	sd	s2,160(sp)
    80005a6a:	ed4e                	sd	s3,152(sp)
    80005a6c:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005a6e:	08000613          	li	a2,128
    80005a72:	f5040593          	addi	a1,s0,-176
    80005a76:	4501                	li	a0,0
    80005a78:	ffffd097          	auipc	ra,0xffffd
    80005a7c:	500080e7          	jalr	1280(ra) # 80002f78 <argstr>
    return -1;
    80005a80:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005a82:	0c054163          	bltz	a0,80005b44 <sys_open+0xe4>
    80005a86:	f4c40593          	addi	a1,s0,-180
    80005a8a:	4505                	li	a0,1
    80005a8c:	ffffd097          	auipc	ra,0xffffd
    80005a90:	4a8080e7          	jalr	1192(ra) # 80002f34 <argint>
    80005a94:	0a054863          	bltz	a0,80005b44 <sys_open+0xe4>

  begin_op();
    80005a98:	fffff097          	auipc	ra,0xfffff
    80005a9c:	a2e080e7          	jalr	-1490(ra) # 800044c6 <begin_op>

  if(omode & O_CREATE){
    80005aa0:	f4c42783          	lw	a5,-180(s0)
    80005aa4:	2007f793          	andi	a5,a5,512
    80005aa8:	cbdd                	beqz	a5,80005b5e <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005aaa:	4681                	li	a3,0
    80005aac:	4601                	li	a2,0
    80005aae:	4589                	li	a1,2
    80005ab0:	f5040513          	addi	a0,s0,-176
    80005ab4:	00000097          	auipc	ra,0x0
    80005ab8:	972080e7          	jalr	-1678(ra) # 80005426 <create>
    80005abc:	892a                	mv	s2,a0
    if(ip == 0){
    80005abe:	c959                	beqz	a0,80005b54 <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005ac0:	04491703          	lh	a4,68(s2)
    80005ac4:	478d                	li	a5,3
    80005ac6:	00f71763          	bne	a4,a5,80005ad4 <sys_open+0x74>
    80005aca:	04695703          	lhu	a4,70(s2)
    80005ace:	47a5                	li	a5,9
    80005ad0:	0ce7ec63          	bltu	a5,a4,80005ba8 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005ad4:	fffff097          	auipc	ra,0xfffff
    80005ad8:	e02080e7          	jalr	-510(ra) # 800048d6 <filealloc>
    80005adc:	89aa                	mv	s3,a0
    80005ade:	10050263          	beqz	a0,80005be2 <sys_open+0x182>
    80005ae2:	00000097          	auipc	ra,0x0
    80005ae6:	902080e7          	jalr	-1790(ra) # 800053e4 <fdalloc>
    80005aea:	84aa                	mv	s1,a0
    80005aec:	0e054663          	bltz	a0,80005bd8 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005af0:	04491703          	lh	a4,68(s2)
    80005af4:	478d                	li	a5,3
    80005af6:	0cf70463          	beq	a4,a5,80005bbe <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005afa:	4789                	li	a5,2
    80005afc:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005b00:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005b04:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005b08:	f4c42783          	lw	a5,-180(s0)
    80005b0c:	0017c713          	xori	a4,a5,1
    80005b10:	8b05                	andi	a4,a4,1
    80005b12:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005b16:	0037f713          	andi	a4,a5,3
    80005b1a:	00e03733          	snez	a4,a4
    80005b1e:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005b22:	4007f793          	andi	a5,a5,1024
    80005b26:	c791                	beqz	a5,80005b32 <sys_open+0xd2>
    80005b28:	04491703          	lh	a4,68(s2)
    80005b2c:	4789                	li	a5,2
    80005b2e:	08f70f63          	beq	a4,a5,80005bcc <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005b32:	854a                	mv	a0,s2
    80005b34:	ffffe097          	auipc	ra,0xffffe
    80005b38:	082080e7          	jalr	130(ra) # 80003bb6 <iunlock>
  end_op();
    80005b3c:	fffff097          	auipc	ra,0xfffff
    80005b40:	a0a080e7          	jalr	-1526(ra) # 80004546 <end_op>

  return fd;
}
    80005b44:	8526                	mv	a0,s1
    80005b46:	70ea                	ld	ra,184(sp)
    80005b48:	744a                	ld	s0,176(sp)
    80005b4a:	74aa                	ld	s1,168(sp)
    80005b4c:	790a                	ld	s2,160(sp)
    80005b4e:	69ea                	ld	s3,152(sp)
    80005b50:	6129                	addi	sp,sp,192
    80005b52:	8082                	ret
      end_op();
    80005b54:	fffff097          	auipc	ra,0xfffff
    80005b58:	9f2080e7          	jalr	-1550(ra) # 80004546 <end_op>
      return -1;
    80005b5c:	b7e5                	j	80005b44 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005b5e:	f5040513          	addi	a0,s0,-176
    80005b62:	ffffe097          	auipc	ra,0xffffe
    80005b66:	748080e7          	jalr	1864(ra) # 800042aa <namei>
    80005b6a:	892a                	mv	s2,a0
    80005b6c:	c905                	beqz	a0,80005b9c <sys_open+0x13c>
    ilock(ip);
    80005b6e:	ffffe097          	auipc	ra,0xffffe
    80005b72:	f86080e7          	jalr	-122(ra) # 80003af4 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005b76:	04491703          	lh	a4,68(s2)
    80005b7a:	4785                	li	a5,1
    80005b7c:	f4f712e3          	bne	a4,a5,80005ac0 <sys_open+0x60>
    80005b80:	f4c42783          	lw	a5,-180(s0)
    80005b84:	dba1                	beqz	a5,80005ad4 <sys_open+0x74>
      iunlockput(ip);
    80005b86:	854a                	mv	a0,s2
    80005b88:	ffffe097          	auipc	ra,0xffffe
    80005b8c:	1ce080e7          	jalr	462(ra) # 80003d56 <iunlockput>
      end_op();
    80005b90:	fffff097          	auipc	ra,0xfffff
    80005b94:	9b6080e7          	jalr	-1610(ra) # 80004546 <end_op>
      return -1;
    80005b98:	54fd                	li	s1,-1
    80005b9a:	b76d                	j	80005b44 <sys_open+0xe4>
      end_op();
    80005b9c:	fffff097          	auipc	ra,0xfffff
    80005ba0:	9aa080e7          	jalr	-1622(ra) # 80004546 <end_op>
      return -1;
    80005ba4:	54fd                	li	s1,-1
    80005ba6:	bf79                	j	80005b44 <sys_open+0xe4>
    iunlockput(ip);
    80005ba8:	854a                	mv	a0,s2
    80005baa:	ffffe097          	auipc	ra,0xffffe
    80005bae:	1ac080e7          	jalr	428(ra) # 80003d56 <iunlockput>
    end_op();
    80005bb2:	fffff097          	auipc	ra,0xfffff
    80005bb6:	994080e7          	jalr	-1644(ra) # 80004546 <end_op>
    return -1;
    80005bba:	54fd                	li	s1,-1
    80005bbc:	b761                	j	80005b44 <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005bbe:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005bc2:	04691783          	lh	a5,70(s2)
    80005bc6:	02f99223          	sh	a5,36(s3)
    80005bca:	bf2d                	j	80005b04 <sys_open+0xa4>
    itrunc(ip);
    80005bcc:	854a                	mv	a0,s2
    80005bce:	ffffe097          	auipc	ra,0xffffe
    80005bd2:	034080e7          	jalr	52(ra) # 80003c02 <itrunc>
    80005bd6:	bfb1                	j	80005b32 <sys_open+0xd2>
      fileclose(f);
    80005bd8:	854e                	mv	a0,s3
    80005bda:	fffff097          	auipc	ra,0xfffff
    80005bde:	db8080e7          	jalr	-584(ra) # 80004992 <fileclose>
    iunlockput(ip);
    80005be2:	854a                	mv	a0,s2
    80005be4:	ffffe097          	auipc	ra,0xffffe
    80005be8:	172080e7          	jalr	370(ra) # 80003d56 <iunlockput>
    end_op();
    80005bec:	fffff097          	auipc	ra,0xfffff
    80005bf0:	95a080e7          	jalr	-1702(ra) # 80004546 <end_op>
    return -1;
    80005bf4:	54fd                	li	s1,-1
    80005bf6:	b7b9                	j	80005b44 <sys_open+0xe4>

0000000080005bf8 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005bf8:	7175                	addi	sp,sp,-144
    80005bfa:	e506                	sd	ra,136(sp)
    80005bfc:	e122                	sd	s0,128(sp)
    80005bfe:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005c00:	fffff097          	auipc	ra,0xfffff
    80005c04:	8c6080e7          	jalr	-1850(ra) # 800044c6 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005c08:	08000613          	li	a2,128
    80005c0c:	f7040593          	addi	a1,s0,-144
    80005c10:	4501                	li	a0,0
    80005c12:	ffffd097          	auipc	ra,0xffffd
    80005c16:	366080e7          	jalr	870(ra) # 80002f78 <argstr>
    80005c1a:	02054963          	bltz	a0,80005c4c <sys_mkdir+0x54>
    80005c1e:	4681                	li	a3,0
    80005c20:	4601                	li	a2,0
    80005c22:	4585                	li	a1,1
    80005c24:	f7040513          	addi	a0,s0,-144
    80005c28:	fffff097          	auipc	ra,0xfffff
    80005c2c:	7fe080e7          	jalr	2046(ra) # 80005426 <create>
    80005c30:	cd11                	beqz	a0,80005c4c <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005c32:	ffffe097          	auipc	ra,0xffffe
    80005c36:	124080e7          	jalr	292(ra) # 80003d56 <iunlockput>
  end_op();
    80005c3a:	fffff097          	auipc	ra,0xfffff
    80005c3e:	90c080e7          	jalr	-1780(ra) # 80004546 <end_op>
  return 0;
    80005c42:	4501                	li	a0,0
}
    80005c44:	60aa                	ld	ra,136(sp)
    80005c46:	640a                	ld	s0,128(sp)
    80005c48:	6149                	addi	sp,sp,144
    80005c4a:	8082                	ret
    end_op();
    80005c4c:	fffff097          	auipc	ra,0xfffff
    80005c50:	8fa080e7          	jalr	-1798(ra) # 80004546 <end_op>
    return -1;
    80005c54:	557d                	li	a0,-1
    80005c56:	b7fd                	j	80005c44 <sys_mkdir+0x4c>

0000000080005c58 <sys_mknod>:

uint64
sys_mknod(void)
{
    80005c58:	7135                	addi	sp,sp,-160
    80005c5a:	ed06                	sd	ra,152(sp)
    80005c5c:	e922                	sd	s0,144(sp)
    80005c5e:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005c60:	fffff097          	auipc	ra,0xfffff
    80005c64:	866080e7          	jalr	-1946(ra) # 800044c6 <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005c68:	08000613          	li	a2,128
    80005c6c:	f7040593          	addi	a1,s0,-144
    80005c70:	4501                	li	a0,0
    80005c72:	ffffd097          	auipc	ra,0xffffd
    80005c76:	306080e7          	jalr	774(ra) # 80002f78 <argstr>
    80005c7a:	04054a63          	bltz	a0,80005cce <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    80005c7e:	f6c40593          	addi	a1,s0,-148
    80005c82:	4505                	li	a0,1
    80005c84:	ffffd097          	auipc	ra,0xffffd
    80005c88:	2b0080e7          	jalr	688(ra) # 80002f34 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005c8c:	04054163          	bltz	a0,80005cce <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    80005c90:	f6840593          	addi	a1,s0,-152
    80005c94:	4509                	li	a0,2
    80005c96:	ffffd097          	auipc	ra,0xffffd
    80005c9a:	29e080e7          	jalr	670(ra) # 80002f34 <argint>
     argint(1, &major) < 0 ||
    80005c9e:	02054863          	bltz	a0,80005cce <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005ca2:	f6841683          	lh	a3,-152(s0)
    80005ca6:	f6c41603          	lh	a2,-148(s0)
    80005caa:	458d                	li	a1,3
    80005cac:	f7040513          	addi	a0,s0,-144
    80005cb0:	fffff097          	auipc	ra,0xfffff
    80005cb4:	776080e7          	jalr	1910(ra) # 80005426 <create>
     argint(2, &minor) < 0 ||
    80005cb8:	c919                	beqz	a0,80005cce <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005cba:	ffffe097          	auipc	ra,0xffffe
    80005cbe:	09c080e7          	jalr	156(ra) # 80003d56 <iunlockput>
  end_op();
    80005cc2:	fffff097          	auipc	ra,0xfffff
    80005cc6:	884080e7          	jalr	-1916(ra) # 80004546 <end_op>
  return 0;
    80005cca:	4501                	li	a0,0
    80005ccc:	a031                	j	80005cd8 <sys_mknod+0x80>
    end_op();
    80005cce:	fffff097          	auipc	ra,0xfffff
    80005cd2:	878080e7          	jalr	-1928(ra) # 80004546 <end_op>
    return -1;
    80005cd6:	557d                	li	a0,-1
}
    80005cd8:	60ea                	ld	ra,152(sp)
    80005cda:	644a                	ld	s0,144(sp)
    80005cdc:	610d                	addi	sp,sp,160
    80005cde:	8082                	ret

0000000080005ce0 <sys_chdir>:

uint64
sys_chdir(void)
{
    80005ce0:	7135                	addi	sp,sp,-160
    80005ce2:	ed06                	sd	ra,152(sp)
    80005ce4:	e922                	sd	s0,144(sp)
    80005ce6:	e526                	sd	s1,136(sp)
    80005ce8:	e14a                	sd	s2,128(sp)
    80005cea:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005cec:	ffffc097          	auipc	ra,0xffffc
    80005cf0:	cdc080e7          	jalr	-804(ra) # 800019c8 <myproc>
    80005cf4:	892a                	mv	s2,a0
  
  begin_op();
    80005cf6:	ffffe097          	auipc	ra,0xffffe
    80005cfa:	7d0080e7          	jalr	2000(ra) # 800044c6 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005cfe:	08000613          	li	a2,128
    80005d02:	f6040593          	addi	a1,s0,-160
    80005d06:	4501                	li	a0,0
    80005d08:	ffffd097          	auipc	ra,0xffffd
    80005d0c:	270080e7          	jalr	624(ra) # 80002f78 <argstr>
    80005d10:	04054b63          	bltz	a0,80005d66 <sys_chdir+0x86>
    80005d14:	f6040513          	addi	a0,s0,-160
    80005d18:	ffffe097          	auipc	ra,0xffffe
    80005d1c:	592080e7          	jalr	1426(ra) # 800042aa <namei>
    80005d20:	84aa                	mv	s1,a0
    80005d22:	c131                	beqz	a0,80005d66 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005d24:	ffffe097          	auipc	ra,0xffffe
    80005d28:	dd0080e7          	jalr	-560(ra) # 80003af4 <ilock>
  if(ip->type != T_DIR){
    80005d2c:	04449703          	lh	a4,68(s1)
    80005d30:	4785                	li	a5,1
    80005d32:	04f71063          	bne	a4,a5,80005d72 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005d36:	8526                	mv	a0,s1
    80005d38:	ffffe097          	auipc	ra,0xffffe
    80005d3c:	e7e080e7          	jalr	-386(ra) # 80003bb6 <iunlock>
  iput(p->cwd);
    80005d40:	17093503          	ld	a0,368(s2)
    80005d44:	ffffe097          	auipc	ra,0xffffe
    80005d48:	f6a080e7          	jalr	-150(ra) # 80003cae <iput>
  end_op();
    80005d4c:	ffffe097          	auipc	ra,0xffffe
    80005d50:	7fa080e7          	jalr	2042(ra) # 80004546 <end_op>
  p->cwd = ip;
    80005d54:	16993823          	sd	s1,368(s2)
  return 0;
    80005d58:	4501                	li	a0,0
}
    80005d5a:	60ea                	ld	ra,152(sp)
    80005d5c:	644a                	ld	s0,144(sp)
    80005d5e:	64aa                	ld	s1,136(sp)
    80005d60:	690a                	ld	s2,128(sp)
    80005d62:	610d                	addi	sp,sp,160
    80005d64:	8082                	ret
    end_op();
    80005d66:	ffffe097          	auipc	ra,0xffffe
    80005d6a:	7e0080e7          	jalr	2016(ra) # 80004546 <end_op>
    return -1;
    80005d6e:	557d                	li	a0,-1
    80005d70:	b7ed                	j	80005d5a <sys_chdir+0x7a>
    iunlockput(ip);
    80005d72:	8526                	mv	a0,s1
    80005d74:	ffffe097          	auipc	ra,0xffffe
    80005d78:	fe2080e7          	jalr	-30(ra) # 80003d56 <iunlockput>
    end_op();
    80005d7c:	ffffe097          	auipc	ra,0xffffe
    80005d80:	7ca080e7          	jalr	1994(ra) # 80004546 <end_op>
    return -1;
    80005d84:	557d                	li	a0,-1
    80005d86:	bfd1                	j	80005d5a <sys_chdir+0x7a>

0000000080005d88 <sys_exec>:

uint64
sys_exec(void)
{
    80005d88:	7145                	addi	sp,sp,-464
    80005d8a:	e786                	sd	ra,456(sp)
    80005d8c:	e3a2                	sd	s0,448(sp)
    80005d8e:	ff26                	sd	s1,440(sp)
    80005d90:	fb4a                	sd	s2,432(sp)
    80005d92:	f74e                	sd	s3,424(sp)
    80005d94:	f352                	sd	s4,416(sp)
    80005d96:	ef56                	sd	s5,408(sp)
    80005d98:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005d9a:	08000613          	li	a2,128
    80005d9e:	f4040593          	addi	a1,s0,-192
    80005da2:	4501                	li	a0,0
    80005da4:	ffffd097          	auipc	ra,0xffffd
    80005da8:	1d4080e7          	jalr	468(ra) # 80002f78 <argstr>
    return -1;
    80005dac:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005dae:	0c054a63          	bltz	a0,80005e82 <sys_exec+0xfa>
    80005db2:	e3840593          	addi	a1,s0,-456
    80005db6:	4505                	li	a0,1
    80005db8:	ffffd097          	auipc	ra,0xffffd
    80005dbc:	19e080e7          	jalr	414(ra) # 80002f56 <argaddr>
    80005dc0:	0c054163          	bltz	a0,80005e82 <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80005dc4:	10000613          	li	a2,256
    80005dc8:	4581                	li	a1,0
    80005dca:	e4040513          	addi	a0,s0,-448
    80005dce:	ffffb097          	auipc	ra,0xffffb
    80005dd2:	f12080e7          	jalr	-238(ra) # 80000ce0 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005dd6:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005dda:	89a6                	mv	s3,s1
    80005ddc:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005dde:	02000a13          	li	s4,32
    80005de2:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005de6:	00391513          	slli	a0,s2,0x3
    80005dea:	e3040593          	addi	a1,s0,-464
    80005dee:	e3843783          	ld	a5,-456(s0)
    80005df2:	953e                	add	a0,a0,a5
    80005df4:	ffffd097          	auipc	ra,0xffffd
    80005df8:	0a6080e7          	jalr	166(ra) # 80002e9a <fetchaddr>
    80005dfc:	02054a63          	bltz	a0,80005e30 <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    80005e00:	e3043783          	ld	a5,-464(s0)
    80005e04:	c3b9                	beqz	a5,80005e4a <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005e06:	ffffb097          	auipc	ra,0xffffb
    80005e0a:	cee080e7          	jalr	-786(ra) # 80000af4 <kalloc>
    80005e0e:	85aa                	mv	a1,a0
    80005e10:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005e14:	cd11                	beqz	a0,80005e30 <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005e16:	6605                	lui	a2,0x1
    80005e18:	e3043503          	ld	a0,-464(s0)
    80005e1c:	ffffd097          	auipc	ra,0xffffd
    80005e20:	0d0080e7          	jalr	208(ra) # 80002eec <fetchstr>
    80005e24:	00054663          	bltz	a0,80005e30 <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80005e28:	0905                	addi	s2,s2,1
    80005e2a:	09a1                	addi	s3,s3,8
    80005e2c:	fb491be3          	bne	s2,s4,80005de2 <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005e30:	10048913          	addi	s2,s1,256
    80005e34:	6088                	ld	a0,0(s1)
    80005e36:	c529                	beqz	a0,80005e80 <sys_exec+0xf8>
    kfree(argv[i]);
    80005e38:	ffffb097          	auipc	ra,0xffffb
    80005e3c:	bc0080e7          	jalr	-1088(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005e40:	04a1                	addi	s1,s1,8
    80005e42:	ff2499e3          	bne	s1,s2,80005e34 <sys_exec+0xac>
  return -1;
    80005e46:	597d                	li	s2,-1
    80005e48:	a82d                	j	80005e82 <sys_exec+0xfa>
      argv[i] = 0;
    80005e4a:	0a8e                	slli	s5,s5,0x3
    80005e4c:	fc040793          	addi	a5,s0,-64
    80005e50:	9abe                	add	s5,s5,a5
    80005e52:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005e56:	e4040593          	addi	a1,s0,-448
    80005e5a:	f4040513          	addi	a0,s0,-192
    80005e5e:	fffff097          	auipc	ra,0xfffff
    80005e62:	194080e7          	jalr	404(ra) # 80004ff2 <exec>
    80005e66:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005e68:	10048993          	addi	s3,s1,256
    80005e6c:	6088                	ld	a0,0(s1)
    80005e6e:	c911                	beqz	a0,80005e82 <sys_exec+0xfa>
    kfree(argv[i]);
    80005e70:	ffffb097          	auipc	ra,0xffffb
    80005e74:	b88080e7          	jalr	-1144(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005e78:	04a1                	addi	s1,s1,8
    80005e7a:	ff3499e3          	bne	s1,s3,80005e6c <sys_exec+0xe4>
    80005e7e:	a011                	j	80005e82 <sys_exec+0xfa>
  return -1;
    80005e80:	597d                	li	s2,-1
}
    80005e82:	854a                	mv	a0,s2
    80005e84:	60be                	ld	ra,456(sp)
    80005e86:	641e                	ld	s0,448(sp)
    80005e88:	74fa                	ld	s1,440(sp)
    80005e8a:	795a                	ld	s2,432(sp)
    80005e8c:	79ba                	ld	s3,424(sp)
    80005e8e:	7a1a                	ld	s4,416(sp)
    80005e90:	6afa                	ld	s5,408(sp)
    80005e92:	6179                	addi	sp,sp,464
    80005e94:	8082                	ret

0000000080005e96 <sys_pipe>:

uint64
sys_pipe(void)
{
    80005e96:	7139                	addi	sp,sp,-64
    80005e98:	fc06                	sd	ra,56(sp)
    80005e9a:	f822                	sd	s0,48(sp)
    80005e9c:	f426                	sd	s1,40(sp)
    80005e9e:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005ea0:	ffffc097          	auipc	ra,0xffffc
    80005ea4:	b28080e7          	jalr	-1240(ra) # 800019c8 <myproc>
    80005ea8:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80005eaa:	fd840593          	addi	a1,s0,-40
    80005eae:	4501                	li	a0,0
    80005eb0:	ffffd097          	auipc	ra,0xffffd
    80005eb4:	0a6080e7          	jalr	166(ra) # 80002f56 <argaddr>
    return -1;
    80005eb8:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80005eba:	0e054063          	bltz	a0,80005f9a <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    80005ebe:	fc840593          	addi	a1,s0,-56
    80005ec2:	fd040513          	addi	a0,s0,-48
    80005ec6:	fffff097          	auipc	ra,0xfffff
    80005eca:	dfc080e7          	jalr	-516(ra) # 80004cc2 <pipealloc>
    return -1;
    80005ece:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005ed0:	0c054563          	bltz	a0,80005f9a <sys_pipe+0x104>
  fd0 = -1;
    80005ed4:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005ed8:	fd043503          	ld	a0,-48(s0)
    80005edc:	fffff097          	auipc	ra,0xfffff
    80005ee0:	508080e7          	jalr	1288(ra) # 800053e4 <fdalloc>
    80005ee4:	fca42223          	sw	a0,-60(s0)
    80005ee8:	08054c63          	bltz	a0,80005f80 <sys_pipe+0xea>
    80005eec:	fc843503          	ld	a0,-56(s0)
    80005ef0:	fffff097          	auipc	ra,0xfffff
    80005ef4:	4f4080e7          	jalr	1268(ra) # 800053e4 <fdalloc>
    80005ef8:	fca42023          	sw	a0,-64(s0)
    80005efc:	06054863          	bltz	a0,80005f6c <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005f00:	4691                	li	a3,4
    80005f02:	fc440613          	addi	a2,s0,-60
    80005f06:	fd843583          	ld	a1,-40(s0)
    80005f0a:	78a8                	ld	a0,112(s1)
    80005f0c:	ffffb097          	auipc	ra,0xffffb
    80005f10:	76e080e7          	jalr	1902(ra) # 8000167a <copyout>
    80005f14:	02054063          	bltz	a0,80005f34 <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005f18:	4691                	li	a3,4
    80005f1a:	fc040613          	addi	a2,s0,-64
    80005f1e:	fd843583          	ld	a1,-40(s0)
    80005f22:	0591                	addi	a1,a1,4
    80005f24:	78a8                	ld	a0,112(s1)
    80005f26:	ffffb097          	auipc	ra,0xffffb
    80005f2a:	754080e7          	jalr	1876(ra) # 8000167a <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005f2e:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005f30:	06055563          	bgez	a0,80005f9a <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80005f34:	fc442783          	lw	a5,-60(s0)
    80005f38:	07f9                	addi	a5,a5,30
    80005f3a:	078e                	slli	a5,a5,0x3
    80005f3c:	97a6                	add	a5,a5,s1
    80005f3e:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005f42:	fc042503          	lw	a0,-64(s0)
    80005f46:	0579                	addi	a0,a0,30
    80005f48:	050e                	slli	a0,a0,0x3
    80005f4a:	9526                	add	a0,a0,s1
    80005f4c:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005f50:	fd043503          	ld	a0,-48(s0)
    80005f54:	fffff097          	auipc	ra,0xfffff
    80005f58:	a3e080e7          	jalr	-1474(ra) # 80004992 <fileclose>
    fileclose(wf);
    80005f5c:	fc843503          	ld	a0,-56(s0)
    80005f60:	fffff097          	auipc	ra,0xfffff
    80005f64:	a32080e7          	jalr	-1486(ra) # 80004992 <fileclose>
    return -1;
    80005f68:	57fd                	li	a5,-1
    80005f6a:	a805                	j	80005f9a <sys_pipe+0x104>
    if(fd0 >= 0)
    80005f6c:	fc442783          	lw	a5,-60(s0)
    80005f70:	0007c863          	bltz	a5,80005f80 <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80005f74:	01e78513          	addi	a0,a5,30
    80005f78:	050e                	slli	a0,a0,0x3
    80005f7a:	9526                	add	a0,a0,s1
    80005f7c:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005f80:	fd043503          	ld	a0,-48(s0)
    80005f84:	fffff097          	auipc	ra,0xfffff
    80005f88:	a0e080e7          	jalr	-1522(ra) # 80004992 <fileclose>
    fileclose(wf);
    80005f8c:	fc843503          	ld	a0,-56(s0)
    80005f90:	fffff097          	auipc	ra,0xfffff
    80005f94:	a02080e7          	jalr	-1534(ra) # 80004992 <fileclose>
    return -1;
    80005f98:	57fd                	li	a5,-1
}
    80005f9a:	853e                	mv	a0,a5
    80005f9c:	70e2                	ld	ra,56(sp)
    80005f9e:	7442                	ld	s0,48(sp)
    80005fa0:	74a2                	ld	s1,40(sp)
    80005fa2:	6121                	addi	sp,sp,64
    80005fa4:	8082                	ret
	...

0000000080005fb0 <kernelvec>:
    80005fb0:	7111                	addi	sp,sp,-256
    80005fb2:	e006                	sd	ra,0(sp)
    80005fb4:	e40a                	sd	sp,8(sp)
    80005fb6:	e80e                	sd	gp,16(sp)
    80005fb8:	ec12                	sd	tp,24(sp)
    80005fba:	f016                	sd	t0,32(sp)
    80005fbc:	f41a                	sd	t1,40(sp)
    80005fbe:	f81e                	sd	t2,48(sp)
    80005fc0:	fc22                	sd	s0,56(sp)
    80005fc2:	e0a6                	sd	s1,64(sp)
    80005fc4:	e4aa                	sd	a0,72(sp)
    80005fc6:	e8ae                	sd	a1,80(sp)
    80005fc8:	ecb2                	sd	a2,88(sp)
    80005fca:	f0b6                	sd	a3,96(sp)
    80005fcc:	f4ba                	sd	a4,104(sp)
    80005fce:	f8be                	sd	a5,112(sp)
    80005fd0:	fcc2                	sd	a6,120(sp)
    80005fd2:	e146                	sd	a7,128(sp)
    80005fd4:	e54a                	sd	s2,136(sp)
    80005fd6:	e94e                	sd	s3,144(sp)
    80005fd8:	ed52                	sd	s4,152(sp)
    80005fda:	f156                	sd	s5,160(sp)
    80005fdc:	f55a                	sd	s6,168(sp)
    80005fde:	f95e                	sd	s7,176(sp)
    80005fe0:	fd62                	sd	s8,184(sp)
    80005fe2:	e1e6                	sd	s9,192(sp)
    80005fe4:	e5ea                	sd	s10,200(sp)
    80005fe6:	e9ee                	sd	s11,208(sp)
    80005fe8:	edf2                	sd	t3,216(sp)
    80005fea:	f1f6                	sd	t4,224(sp)
    80005fec:	f5fa                	sd	t5,232(sp)
    80005fee:	f9fe                	sd	t6,240(sp)
    80005ff0:	d77fc0ef          	jal	ra,80002d66 <kerneltrap>
    80005ff4:	6082                	ld	ra,0(sp)
    80005ff6:	6122                	ld	sp,8(sp)
    80005ff8:	61c2                	ld	gp,16(sp)
    80005ffa:	7282                	ld	t0,32(sp)
    80005ffc:	7322                	ld	t1,40(sp)
    80005ffe:	73c2                	ld	t2,48(sp)
    80006000:	7462                	ld	s0,56(sp)
    80006002:	6486                	ld	s1,64(sp)
    80006004:	6526                	ld	a0,72(sp)
    80006006:	65c6                	ld	a1,80(sp)
    80006008:	6666                	ld	a2,88(sp)
    8000600a:	7686                	ld	a3,96(sp)
    8000600c:	7726                	ld	a4,104(sp)
    8000600e:	77c6                	ld	a5,112(sp)
    80006010:	7866                	ld	a6,120(sp)
    80006012:	688a                	ld	a7,128(sp)
    80006014:	692a                	ld	s2,136(sp)
    80006016:	69ca                	ld	s3,144(sp)
    80006018:	6a6a                	ld	s4,152(sp)
    8000601a:	7a8a                	ld	s5,160(sp)
    8000601c:	7b2a                	ld	s6,168(sp)
    8000601e:	7bca                	ld	s7,176(sp)
    80006020:	7c6a                	ld	s8,184(sp)
    80006022:	6c8e                	ld	s9,192(sp)
    80006024:	6d2e                	ld	s10,200(sp)
    80006026:	6dce                	ld	s11,208(sp)
    80006028:	6e6e                	ld	t3,216(sp)
    8000602a:	7e8e                	ld	t4,224(sp)
    8000602c:	7f2e                	ld	t5,232(sp)
    8000602e:	7fce                	ld	t6,240(sp)
    80006030:	6111                	addi	sp,sp,256
    80006032:	10200073          	sret
    80006036:	00000013          	nop
    8000603a:	00000013          	nop
    8000603e:	0001                	nop

0000000080006040 <timervec>:
    80006040:	34051573          	csrrw	a0,mscratch,a0
    80006044:	e10c                	sd	a1,0(a0)
    80006046:	e510                	sd	a2,8(a0)
    80006048:	e914                	sd	a3,16(a0)
    8000604a:	6d0c                	ld	a1,24(a0)
    8000604c:	7110                	ld	a2,32(a0)
    8000604e:	6194                	ld	a3,0(a1)
    80006050:	96b2                	add	a3,a3,a2
    80006052:	e194                	sd	a3,0(a1)
    80006054:	4589                	li	a1,2
    80006056:	14459073          	csrw	sip,a1
    8000605a:	6914                	ld	a3,16(a0)
    8000605c:	6510                	ld	a2,8(a0)
    8000605e:	610c                	ld	a1,0(a0)
    80006060:	34051573          	csrrw	a0,mscratch,a0
    80006064:	30200073          	mret
	...

000000008000606a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    8000606a:	1141                	addi	sp,sp,-16
    8000606c:	e422                	sd	s0,8(sp)
    8000606e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80006070:	0c0007b7          	lui	a5,0xc000
    80006074:	4705                	li	a4,1
    80006076:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80006078:	c3d8                	sw	a4,4(a5)
}
    8000607a:	6422                	ld	s0,8(sp)
    8000607c:	0141                	addi	sp,sp,16
    8000607e:	8082                	ret

0000000080006080 <plicinithart>:

void
plicinithart(void)
{
    80006080:	1141                	addi	sp,sp,-16
    80006082:	e406                	sd	ra,8(sp)
    80006084:	e022                	sd	s0,0(sp)
    80006086:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006088:	ffffc097          	auipc	ra,0xffffc
    8000608c:	914080e7          	jalr	-1772(ra) # 8000199c <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80006090:	0085171b          	slliw	a4,a0,0x8
    80006094:	0c0027b7          	lui	a5,0xc002
    80006098:	97ba                	add	a5,a5,a4
    8000609a:	40200713          	li	a4,1026
    8000609e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    800060a2:	00d5151b          	slliw	a0,a0,0xd
    800060a6:	0c2017b7          	lui	a5,0xc201
    800060aa:	953e                	add	a0,a0,a5
    800060ac:	00052023          	sw	zero,0(a0)
}
    800060b0:	60a2                	ld	ra,8(sp)
    800060b2:	6402                	ld	s0,0(sp)
    800060b4:	0141                	addi	sp,sp,16
    800060b6:	8082                	ret

00000000800060b8 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    800060b8:	1141                	addi	sp,sp,-16
    800060ba:	e406                	sd	ra,8(sp)
    800060bc:	e022                	sd	s0,0(sp)
    800060be:	0800                	addi	s0,sp,16
  int hart = cpuid();
    800060c0:	ffffc097          	auipc	ra,0xffffc
    800060c4:	8dc080e7          	jalr	-1828(ra) # 8000199c <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    800060c8:	00d5179b          	slliw	a5,a0,0xd
    800060cc:	0c201537          	lui	a0,0xc201
    800060d0:	953e                	add	a0,a0,a5
  return irq;
}
    800060d2:	4148                	lw	a0,4(a0)
    800060d4:	60a2                	ld	ra,8(sp)
    800060d6:	6402                	ld	s0,0(sp)
    800060d8:	0141                	addi	sp,sp,16
    800060da:	8082                	ret

00000000800060dc <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    800060dc:	1101                	addi	sp,sp,-32
    800060de:	ec06                	sd	ra,24(sp)
    800060e0:	e822                	sd	s0,16(sp)
    800060e2:	e426                	sd	s1,8(sp)
    800060e4:	1000                	addi	s0,sp,32
    800060e6:	84aa                	mv	s1,a0
  int hart = cpuid();
    800060e8:	ffffc097          	auipc	ra,0xffffc
    800060ec:	8b4080e7          	jalr	-1868(ra) # 8000199c <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    800060f0:	00d5151b          	slliw	a0,a0,0xd
    800060f4:	0c2017b7          	lui	a5,0xc201
    800060f8:	97aa                	add	a5,a5,a0
    800060fa:	c3c4                	sw	s1,4(a5)
}
    800060fc:	60e2                	ld	ra,24(sp)
    800060fe:	6442                	ld	s0,16(sp)
    80006100:	64a2                	ld	s1,8(sp)
    80006102:	6105                	addi	sp,sp,32
    80006104:	8082                	ret

0000000080006106 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80006106:	1141                	addi	sp,sp,-16
    80006108:	e406                	sd	ra,8(sp)
    8000610a:	e022                	sd	s0,0(sp)
    8000610c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    8000610e:	479d                	li	a5,7
    80006110:	06a7c963          	blt	a5,a0,80006182 <free_desc+0x7c>
    panic("free_desc 1");
  if(disk.free[i])
    80006114:	0001d797          	auipc	a5,0x1d
    80006118:	eec78793          	addi	a5,a5,-276 # 80023000 <disk>
    8000611c:	00a78733          	add	a4,a5,a0
    80006120:	6789                	lui	a5,0x2
    80006122:	97ba                	add	a5,a5,a4
    80006124:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80006128:	e7ad                	bnez	a5,80006192 <free_desc+0x8c>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    8000612a:	00451793          	slli	a5,a0,0x4
    8000612e:	0001f717          	auipc	a4,0x1f
    80006132:	ed270713          	addi	a4,a4,-302 # 80025000 <disk+0x2000>
    80006136:	6314                	ld	a3,0(a4)
    80006138:	96be                	add	a3,a3,a5
    8000613a:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    8000613e:	6314                	ld	a3,0(a4)
    80006140:	96be                	add	a3,a3,a5
    80006142:	0006a423          	sw	zero,8(a3)
  disk.desc[i].flags = 0;
    80006146:	6314                	ld	a3,0(a4)
    80006148:	96be                	add	a3,a3,a5
    8000614a:	00069623          	sh	zero,12(a3)
  disk.desc[i].next = 0;
    8000614e:	6318                	ld	a4,0(a4)
    80006150:	97ba                	add	a5,a5,a4
    80006152:	00079723          	sh	zero,14(a5)
  disk.free[i] = 1;
    80006156:	0001d797          	auipc	a5,0x1d
    8000615a:	eaa78793          	addi	a5,a5,-342 # 80023000 <disk>
    8000615e:	97aa                	add	a5,a5,a0
    80006160:	6509                	lui	a0,0x2
    80006162:	953e                	add	a0,a0,a5
    80006164:	4785                	li	a5,1
    80006166:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    8000616a:	0001f517          	auipc	a0,0x1f
    8000616e:	eae50513          	addi	a0,a0,-338 # 80025018 <disk+0x2018>
    80006172:	ffffc097          	auipc	ra,0xffffc
    80006176:	3f0080e7          	jalr	1008(ra) # 80002562 <wakeup>
}
    8000617a:	60a2                	ld	ra,8(sp)
    8000617c:	6402                	ld	s0,0(sp)
    8000617e:	0141                	addi	sp,sp,16
    80006180:	8082                	ret
    panic("free_desc 1");
    80006182:	00002517          	auipc	a0,0x2
    80006186:	64650513          	addi	a0,a0,1606 # 800087c8 <syscalls+0x330>
    8000618a:	ffffa097          	auipc	ra,0xffffa
    8000618e:	3b4080e7          	jalr	948(ra) # 8000053e <panic>
    panic("free_desc 2");
    80006192:	00002517          	auipc	a0,0x2
    80006196:	64650513          	addi	a0,a0,1606 # 800087d8 <syscalls+0x340>
    8000619a:	ffffa097          	auipc	ra,0xffffa
    8000619e:	3a4080e7          	jalr	932(ra) # 8000053e <panic>

00000000800061a2 <virtio_disk_init>:
{
    800061a2:	1101                	addi	sp,sp,-32
    800061a4:	ec06                	sd	ra,24(sp)
    800061a6:	e822                	sd	s0,16(sp)
    800061a8:	e426                	sd	s1,8(sp)
    800061aa:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    800061ac:	00002597          	auipc	a1,0x2
    800061b0:	63c58593          	addi	a1,a1,1596 # 800087e8 <syscalls+0x350>
    800061b4:	0001f517          	auipc	a0,0x1f
    800061b8:	f7450513          	addi	a0,a0,-140 # 80025128 <disk+0x2128>
    800061bc:	ffffb097          	auipc	ra,0xffffb
    800061c0:	998080e7          	jalr	-1640(ra) # 80000b54 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    800061c4:	100017b7          	lui	a5,0x10001
    800061c8:	4398                	lw	a4,0(a5)
    800061ca:	2701                	sext.w	a4,a4
    800061cc:	747277b7          	lui	a5,0x74727
    800061d0:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    800061d4:	0ef71163          	bne	a4,a5,800062b6 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    800061d8:	100017b7          	lui	a5,0x10001
    800061dc:	43dc                	lw	a5,4(a5)
    800061de:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    800061e0:	4705                	li	a4,1
    800061e2:	0ce79a63          	bne	a5,a4,800062b6 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    800061e6:	100017b7          	lui	a5,0x10001
    800061ea:	479c                	lw	a5,8(a5)
    800061ec:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    800061ee:	4709                	li	a4,2
    800061f0:	0ce79363          	bne	a5,a4,800062b6 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    800061f4:	100017b7          	lui	a5,0x10001
    800061f8:	47d8                	lw	a4,12(a5)
    800061fa:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    800061fc:	554d47b7          	lui	a5,0x554d4
    80006200:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80006204:	0af71963          	bne	a4,a5,800062b6 <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    80006208:	100017b7          	lui	a5,0x10001
    8000620c:	4705                	li	a4,1
    8000620e:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006210:	470d                	li	a4,3
    80006212:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80006214:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80006216:	c7ffe737          	lui	a4,0xc7ffe
    8000621a:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd875f>
    8000621e:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80006220:	2701                	sext.w	a4,a4
    80006222:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006224:	472d                	li	a4,11
    80006226:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006228:	473d                	li	a4,15
    8000622a:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    8000622c:	6705                	lui	a4,0x1
    8000622e:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80006230:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80006234:	5bdc                	lw	a5,52(a5)
    80006236:	2781                	sext.w	a5,a5
  if(max == 0)
    80006238:	c7d9                	beqz	a5,800062c6 <virtio_disk_init+0x124>
  if(max < NUM)
    8000623a:	471d                	li	a4,7
    8000623c:	08f77d63          	bgeu	a4,a5,800062d6 <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80006240:	100014b7          	lui	s1,0x10001
    80006244:	47a1                	li	a5,8
    80006246:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    80006248:	6609                	lui	a2,0x2
    8000624a:	4581                	li	a1,0
    8000624c:	0001d517          	auipc	a0,0x1d
    80006250:	db450513          	addi	a0,a0,-588 # 80023000 <disk>
    80006254:	ffffb097          	auipc	ra,0xffffb
    80006258:	a8c080e7          	jalr	-1396(ra) # 80000ce0 <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    8000625c:	0001d717          	auipc	a4,0x1d
    80006260:	da470713          	addi	a4,a4,-604 # 80023000 <disk>
    80006264:	00c75793          	srli	a5,a4,0xc
    80006268:	2781                	sext.w	a5,a5
    8000626a:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    8000626c:	0001f797          	auipc	a5,0x1f
    80006270:	d9478793          	addi	a5,a5,-620 # 80025000 <disk+0x2000>
    80006274:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    80006276:	0001d717          	auipc	a4,0x1d
    8000627a:	e0a70713          	addi	a4,a4,-502 # 80023080 <disk+0x80>
    8000627e:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    80006280:	0001e717          	auipc	a4,0x1e
    80006284:	d8070713          	addi	a4,a4,-640 # 80024000 <disk+0x1000>
    80006288:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    8000628a:	4705                	li	a4,1
    8000628c:	00e78c23          	sb	a4,24(a5)
    80006290:	00e78ca3          	sb	a4,25(a5)
    80006294:	00e78d23          	sb	a4,26(a5)
    80006298:	00e78da3          	sb	a4,27(a5)
    8000629c:	00e78e23          	sb	a4,28(a5)
    800062a0:	00e78ea3          	sb	a4,29(a5)
    800062a4:	00e78f23          	sb	a4,30(a5)
    800062a8:	00e78fa3          	sb	a4,31(a5)
}
    800062ac:	60e2                	ld	ra,24(sp)
    800062ae:	6442                	ld	s0,16(sp)
    800062b0:	64a2                	ld	s1,8(sp)
    800062b2:	6105                	addi	sp,sp,32
    800062b4:	8082                	ret
    panic("could not find virtio disk");
    800062b6:	00002517          	auipc	a0,0x2
    800062ba:	54250513          	addi	a0,a0,1346 # 800087f8 <syscalls+0x360>
    800062be:	ffffa097          	auipc	ra,0xffffa
    800062c2:	280080e7          	jalr	640(ra) # 8000053e <panic>
    panic("virtio disk has no queue 0");
    800062c6:	00002517          	auipc	a0,0x2
    800062ca:	55250513          	addi	a0,a0,1362 # 80008818 <syscalls+0x380>
    800062ce:	ffffa097          	auipc	ra,0xffffa
    800062d2:	270080e7          	jalr	624(ra) # 8000053e <panic>
    panic("virtio disk max queue too short");
    800062d6:	00002517          	auipc	a0,0x2
    800062da:	56250513          	addi	a0,a0,1378 # 80008838 <syscalls+0x3a0>
    800062de:	ffffa097          	auipc	ra,0xffffa
    800062e2:	260080e7          	jalr	608(ra) # 8000053e <panic>

00000000800062e6 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    800062e6:	7159                	addi	sp,sp,-112
    800062e8:	f486                	sd	ra,104(sp)
    800062ea:	f0a2                	sd	s0,96(sp)
    800062ec:	eca6                	sd	s1,88(sp)
    800062ee:	e8ca                	sd	s2,80(sp)
    800062f0:	e4ce                	sd	s3,72(sp)
    800062f2:	e0d2                	sd	s4,64(sp)
    800062f4:	fc56                	sd	s5,56(sp)
    800062f6:	f85a                	sd	s6,48(sp)
    800062f8:	f45e                	sd	s7,40(sp)
    800062fa:	f062                	sd	s8,32(sp)
    800062fc:	ec66                	sd	s9,24(sp)
    800062fe:	e86a                	sd	s10,16(sp)
    80006300:	1880                	addi	s0,sp,112
    80006302:	892a                	mv	s2,a0
    80006304:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80006306:	00c52c83          	lw	s9,12(a0)
    8000630a:	001c9c9b          	slliw	s9,s9,0x1
    8000630e:	1c82                	slli	s9,s9,0x20
    80006310:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80006314:	0001f517          	auipc	a0,0x1f
    80006318:	e1450513          	addi	a0,a0,-492 # 80025128 <disk+0x2128>
    8000631c:	ffffb097          	auipc	ra,0xffffb
    80006320:	8c8080e7          	jalr	-1848(ra) # 80000be4 <acquire>
  for(int i = 0; i < 3; i++){
    80006324:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80006326:	4c21                	li	s8,8
      disk.free[i] = 0;
    80006328:	0001db97          	auipc	s7,0x1d
    8000632c:	cd8b8b93          	addi	s7,s7,-808 # 80023000 <disk>
    80006330:	6b09                	lui	s6,0x2
  for(int i = 0; i < 3; i++){
    80006332:	4a8d                	li	s5,3
  for(int i = 0; i < NUM; i++){
    80006334:	8a4e                	mv	s4,s3
    80006336:	a051                	j	800063ba <virtio_disk_rw+0xd4>
      disk.free[i] = 0;
    80006338:	00fb86b3          	add	a3,s7,a5
    8000633c:	96da                	add	a3,a3,s6
    8000633e:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    80006342:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    80006344:	0207c563          	bltz	a5,8000636e <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    80006348:	2485                	addiw	s1,s1,1
    8000634a:	0711                	addi	a4,a4,4
    8000634c:	25548063          	beq	s1,s5,8000658c <virtio_disk_rw+0x2a6>
    idx[i] = alloc_desc();
    80006350:	863a                	mv	a2,a4
  for(int i = 0; i < NUM; i++){
    80006352:	0001f697          	auipc	a3,0x1f
    80006356:	cc668693          	addi	a3,a3,-826 # 80025018 <disk+0x2018>
    8000635a:	87d2                	mv	a5,s4
    if(disk.free[i]){
    8000635c:	0006c583          	lbu	a1,0(a3)
    80006360:	fde1                	bnez	a1,80006338 <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    80006362:	2785                	addiw	a5,a5,1
    80006364:	0685                	addi	a3,a3,1
    80006366:	ff879be3          	bne	a5,s8,8000635c <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    8000636a:	57fd                	li	a5,-1
    8000636c:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    8000636e:	02905a63          	blez	s1,800063a2 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006372:	f9042503          	lw	a0,-112(s0)
    80006376:	00000097          	auipc	ra,0x0
    8000637a:	d90080e7          	jalr	-624(ra) # 80006106 <free_desc>
      for(int j = 0; j < i; j++)
    8000637e:	4785                	li	a5,1
    80006380:	0297d163          	bge	a5,s1,800063a2 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006384:	f9442503          	lw	a0,-108(s0)
    80006388:	00000097          	auipc	ra,0x0
    8000638c:	d7e080e7          	jalr	-642(ra) # 80006106 <free_desc>
      for(int j = 0; j < i; j++)
    80006390:	4789                	li	a5,2
    80006392:	0097d863          	bge	a5,s1,800063a2 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006396:	f9842503          	lw	a0,-104(s0)
    8000639a:	00000097          	auipc	ra,0x0
    8000639e:	d6c080e7          	jalr	-660(ra) # 80006106 <free_desc>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    800063a2:	0001f597          	auipc	a1,0x1f
    800063a6:	d8658593          	addi	a1,a1,-634 # 80025128 <disk+0x2128>
    800063aa:	0001f517          	auipc	a0,0x1f
    800063ae:	c6e50513          	addi	a0,a0,-914 # 80025018 <disk+0x2018>
    800063b2:	ffffc097          	auipc	ra,0xffffc
    800063b6:	010080e7          	jalr	16(ra) # 800023c2 <sleep>
  for(int i = 0; i < 3; i++){
    800063ba:	f9040713          	addi	a4,s0,-112
    800063be:	84ce                	mv	s1,s3
    800063c0:	bf41                	j	80006350 <virtio_disk_rw+0x6a>
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];

  if(write)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
    800063c2:	20058713          	addi	a4,a1,512
    800063c6:	00471693          	slli	a3,a4,0x4
    800063ca:	0001d717          	auipc	a4,0x1d
    800063ce:	c3670713          	addi	a4,a4,-970 # 80023000 <disk>
    800063d2:	9736                	add	a4,a4,a3
    800063d4:	4685                	li	a3,1
    800063d6:	0ad72423          	sw	a3,168(a4)
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    800063da:	20058713          	addi	a4,a1,512
    800063de:	00471693          	slli	a3,a4,0x4
    800063e2:	0001d717          	auipc	a4,0x1d
    800063e6:	c1e70713          	addi	a4,a4,-994 # 80023000 <disk>
    800063ea:	9736                	add	a4,a4,a3
    800063ec:	0a072623          	sw	zero,172(a4)
  buf0->sector = sector;
    800063f0:	0b973823          	sd	s9,176(a4)

  disk.desc[idx[0]].addr = (uint64) buf0;
    800063f4:	7679                	lui	a2,0xffffe
    800063f6:	963e                	add	a2,a2,a5
    800063f8:	0001f697          	auipc	a3,0x1f
    800063fc:	c0868693          	addi	a3,a3,-1016 # 80025000 <disk+0x2000>
    80006400:	6298                	ld	a4,0(a3)
    80006402:	9732                	add	a4,a4,a2
    80006404:	e308                	sd	a0,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    80006406:	6298                	ld	a4,0(a3)
    80006408:	9732                	add	a4,a4,a2
    8000640a:	4541                	li	a0,16
    8000640c:	c708                	sw	a0,8(a4)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    8000640e:	6298                	ld	a4,0(a3)
    80006410:	9732                	add	a4,a4,a2
    80006412:	4505                	li	a0,1
    80006414:	00a71623          	sh	a0,12(a4)
  disk.desc[idx[0]].next = idx[1];
    80006418:	f9442703          	lw	a4,-108(s0)
    8000641c:	6288                	ld	a0,0(a3)
    8000641e:	962a                	add	a2,a2,a0
    80006420:	00e61723          	sh	a4,14(a2) # ffffffffffffe00e <end+0xffffffff7ffd800e>

  disk.desc[idx[1]].addr = (uint64) b->data;
    80006424:	0712                	slli	a4,a4,0x4
    80006426:	6290                	ld	a2,0(a3)
    80006428:	963a                	add	a2,a2,a4
    8000642a:	05890513          	addi	a0,s2,88
    8000642e:	e208                	sd	a0,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    80006430:	6294                	ld	a3,0(a3)
    80006432:	96ba                	add	a3,a3,a4
    80006434:	40000613          	li	a2,1024
    80006438:	c690                	sw	a2,8(a3)
  if(write)
    8000643a:	140d0063          	beqz	s10,8000657a <virtio_disk_rw+0x294>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    8000643e:	0001f697          	auipc	a3,0x1f
    80006442:	bc26b683          	ld	a3,-1086(a3) # 80025000 <disk+0x2000>
    80006446:	96ba                	add	a3,a3,a4
    80006448:	00069623          	sh	zero,12(a3)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    8000644c:	0001d817          	auipc	a6,0x1d
    80006450:	bb480813          	addi	a6,a6,-1100 # 80023000 <disk>
    80006454:	0001f517          	auipc	a0,0x1f
    80006458:	bac50513          	addi	a0,a0,-1108 # 80025000 <disk+0x2000>
    8000645c:	6114                	ld	a3,0(a0)
    8000645e:	96ba                	add	a3,a3,a4
    80006460:	00c6d603          	lhu	a2,12(a3)
    80006464:	00166613          	ori	a2,a2,1
    80006468:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    8000646c:	f9842683          	lw	a3,-104(s0)
    80006470:	6110                	ld	a2,0(a0)
    80006472:	9732                	add	a4,a4,a2
    80006474:	00d71723          	sh	a3,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80006478:	20058613          	addi	a2,a1,512
    8000647c:	0612                	slli	a2,a2,0x4
    8000647e:	9642                	add	a2,a2,a6
    80006480:	577d                	li	a4,-1
    80006482:	02e60823          	sb	a4,48(a2)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80006486:	00469713          	slli	a4,a3,0x4
    8000648a:	6114                	ld	a3,0(a0)
    8000648c:	96ba                	add	a3,a3,a4
    8000648e:	03078793          	addi	a5,a5,48
    80006492:	97c2                	add	a5,a5,a6
    80006494:	e29c                	sd	a5,0(a3)
  disk.desc[idx[2]].len = 1;
    80006496:	611c                	ld	a5,0(a0)
    80006498:	97ba                	add	a5,a5,a4
    8000649a:	4685                	li	a3,1
    8000649c:	c794                	sw	a3,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    8000649e:	611c                	ld	a5,0(a0)
    800064a0:	97ba                	add	a5,a5,a4
    800064a2:	4809                	li	a6,2
    800064a4:	01079623          	sh	a6,12(a5)
  disk.desc[idx[2]].next = 0;
    800064a8:	611c                	ld	a5,0(a0)
    800064aa:	973e                	add	a4,a4,a5
    800064ac:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    800064b0:	00d92223          	sw	a3,4(s2)
  disk.info[idx[0]].b = b;
    800064b4:	03263423          	sd	s2,40(a2)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    800064b8:	6518                	ld	a4,8(a0)
    800064ba:	00275783          	lhu	a5,2(a4)
    800064be:	8b9d                	andi	a5,a5,7
    800064c0:	0786                	slli	a5,a5,0x1
    800064c2:	97ba                	add	a5,a5,a4
    800064c4:	00b79223          	sh	a1,4(a5)

  __sync_synchronize();
    800064c8:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    800064cc:	6518                	ld	a4,8(a0)
    800064ce:	00275783          	lhu	a5,2(a4)
    800064d2:	2785                	addiw	a5,a5,1
    800064d4:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    800064d8:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    800064dc:	100017b7          	lui	a5,0x10001
    800064e0:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    800064e4:	00492703          	lw	a4,4(s2)
    800064e8:	4785                	li	a5,1
    800064ea:	02f71163          	bne	a4,a5,8000650c <virtio_disk_rw+0x226>
    sleep(b, &disk.vdisk_lock);
    800064ee:	0001f997          	auipc	s3,0x1f
    800064f2:	c3a98993          	addi	s3,s3,-966 # 80025128 <disk+0x2128>
  while(b->disk == 1) {
    800064f6:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    800064f8:	85ce                	mv	a1,s3
    800064fa:	854a                	mv	a0,s2
    800064fc:	ffffc097          	auipc	ra,0xffffc
    80006500:	ec6080e7          	jalr	-314(ra) # 800023c2 <sleep>
  while(b->disk == 1) {
    80006504:	00492783          	lw	a5,4(s2)
    80006508:	fe9788e3          	beq	a5,s1,800064f8 <virtio_disk_rw+0x212>
  }

  disk.info[idx[0]].b = 0;
    8000650c:	f9042903          	lw	s2,-112(s0)
    80006510:	20090793          	addi	a5,s2,512
    80006514:	00479713          	slli	a4,a5,0x4
    80006518:	0001d797          	auipc	a5,0x1d
    8000651c:	ae878793          	addi	a5,a5,-1304 # 80023000 <disk>
    80006520:	97ba                	add	a5,a5,a4
    80006522:	0207b423          	sd	zero,40(a5)
    int flag = disk.desc[i].flags;
    80006526:	0001f997          	auipc	s3,0x1f
    8000652a:	ada98993          	addi	s3,s3,-1318 # 80025000 <disk+0x2000>
    8000652e:	00491713          	slli	a4,s2,0x4
    80006532:	0009b783          	ld	a5,0(s3)
    80006536:	97ba                	add	a5,a5,a4
    80006538:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    8000653c:	854a                	mv	a0,s2
    8000653e:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    80006542:	00000097          	auipc	ra,0x0
    80006546:	bc4080e7          	jalr	-1084(ra) # 80006106 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    8000654a:	8885                	andi	s1,s1,1
    8000654c:	f0ed                	bnez	s1,8000652e <virtio_disk_rw+0x248>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    8000654e:	0001f517          	auipc	a0,0x1f
    80006552:	bda50513          	addi	a0,a0,-1062 # 80025128 <disk+0x2128>
    80006556:	ffffa097          	auipc	ra,0xffffa
    8000655a:	742080e7          	jalr	1858(ra) # 80000c98 <release>
}
    8000655e:	70a6                	ld	ra,104(sp)
    80006560:	7406                	ld	s0,96(sp)
    80006562:	64e6                	ld	s1,88(sp)
    80006564:	6946                	ld	s2,80(sp)
    80006566:	69a6                	ld	s3,72(sp)
    80006568:	6a06                	ld	s4,64(sp)
    8000656a:	7ae2                	ld	s5,56(sp)
    8000656c:	7b42                	ld	s6,48(sp)
    8000656e:	7ba2                	ld	s7,40(sp)
    80006570:	7c02                	ld	s8,32(sp)
    80006572:	6ce2                	ld	s9,24(sp)
    80006574:	6d42                	ld	s10,16(sp)
    80006576:	6165                	addi	sp,sp,112
    80006578:	8082                	ret
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    8000657a:	0001f697          	auipc	a3,0x1f
    8000657e:	a866b683          	ld	a3,-1402(a3) # 80025000 <disk+0x2000>
    80006582:	96ba                	add	a3,a3,a4
    80006584:	4609                	li	a2,2
    80006586:	00c69623          	sh	a2,12(a3)
    8000658a:	b5c9                	j	8000644c <virtio_disk_rw+0x166>
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    8000658c:	f9042583          	lw	a1,-112(s0)
    80006590:	20058793          	addi	a5,a1,512
    80006594:	0792                	slli	a5,a5,0x4
    80006596:	0001d517          	auipc	a0,0x1d
    8000659a:	b1250513          	addi	a0,a0,-1262 # 800230a8 <disk+0xa8>
    8000659e:	953e                	add	a0,a0,a5
  if(write)
    800065a0:	e20d11e3          	bnez	s10,800063c2 <virtio_disk_rw+0xdc>
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
    800065a4:	20058713          	addi	a4,a1,512
    800065a8:	00471693          	slli	a3,a4,0x4
    800065ac:	0001d717          	auipc	a4,0x1d
    800065b0:	a5470713          	addi	a4,a4,-1452 # 80023000 <disk>
    800065b4:	9736                	add	a4,a4,a3
    800065b6:	0a072423          	sw	zero,168(a4)
    800065ba:	b505                	j	800063da <virtio_disk_rw+0xf4>

00000000800065bc <virtio_disk_intr>:

void
virtio_disk_intr()
{
    800065bc:	1101                	addi	sp,sp,-32
    800065be:	ec06                	sd	ra,24(sp)
    800065c0:	e822                	sd	s0,16(sp)
    800065c2:	e426                	sd	s1,8(sp)
    800065c4:	e04a                	sd	s2,0(sp)
    800065c6:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    800065c8:	0001f517          	auipc	a0,0x1f
    800065cc:	b6050513          	addi	a0,a0,-1184 # 80025128 <disk+0x2128>
    800065d0:	ffffa097          	auipc	ra,0xffffa
    800065d4:	614080e7          	jalr	1556(ra) # 80000be4 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    800065d8:	10001737          	lui	a4,0x10001
    800065dc:	533c                	lw	a5,96(a4)
    800065de:	8b8d                	andi	a5,a5,3
    800065e0:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    800065e2:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    800065e6:	0001f797          	auipc	a5,0x1f
    800065ea:	a1a78793          	addi	a5,a5,-1510 # 80025000 <disk+0x2000>
    800065ee:	6b94                	ld	a3,16(a5)
    800065f0:	0207d703          	lhu	a4,32(a5)
    800065f4:	0026d783          	lhu	a5,2(a3)
    800065f8:	06f70163          	beq	a4,a5,8000665a <virtio_disk_intr+0x9e>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    800065fc:	0001d917          	auipc	s2,0x1d
    80006600:	a0490913          	addi	s2,s2,-1532 # 80023000 <disk>
    80006604:	0001f497          	auipc	s1,0x1f
    80006608:	9fc48493          	addi	s1,s1,-1540 # 80025000 <disk+0x2000>
    __sync_synchronize();
    8000660c:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006610:	6898                	ld	a4,16(s1)
    80006612:	0204d783          	lhu	a5,32(s1)
    80006616:	8b9d                	andi	a5,a5,7
    80006618:	078e                	slli	a5,a5,0x3
    8000661a:	97ba                	add	a5,a5,a4
    8000661c:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    8000661e:	20078713          	addi	a4,a5,512
    80006622:	0712                	slli	a4,a4,0x4
    80006624:	974a                	add	a4,a4,s2
    80006626:	03074703          	lbu	a4,48(a4) # 10001030 <_entry-0x6fffefd0>
    8000662a:	e731                	bnez	a4,80006676 <virtio_disk_intr+0xba>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    8000662c:	20078793          	addi	a5,a5,512
    80006630:	0792                	slli	a5,a5,0x4
    80006632:	97ca                	add	a5,a5,s2
    80006634:	7788                	ld	a0,40(a5)
    b->disk = 0;   // disk is done with buf
    80006636:	00052223          	sw	zero,4(a0)
    wakeup(b);
    8000663a:	ffffc097          	auipc	ra,0xffffc
    8000663e:	f28080e7          	jalr	-216(ra) # 80002562 <wakeup>

    disk.used_idx += 1;
    80006642:	0204d783          	lhu	a5,32(s1)
    80006646:	2785                	addiw	a5,a5,1
    80006648:	17c2                	slli	a5,a5,0x30
    8000664a:	93c1                	srli	a5,a5,0x30
    8000664c:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006650:	6898                	ld	a4,16(s1)
    80006652:	00275703          	lhu	a4,2(a4)
    80006656:	faf71be3          	bne	a4,a5,8000660c <virtio_disk_intr+0x50>
  }

  release(&disk.vdisk_lock);
    8000665a:	0001f517          	auipc	a0,0x1f
    8000665e:	ace50513          	addi	a0,a0,-1330 # 80025128 <disk+0x2128>
    80006662:	ffffa097          	auipc	ra,0xffffa
    80006666:	636080e7          	jalr	1590(ra) # 80000c98 <release>
}
    8000666a:	60e2                	ld	ra,24(sp)
    8000666c:	6442                	ld	s0,16(sp)
    8000666e:	64a2                	ld	s1,8(sp)
    80006670:	6902                	ld	s2,0(sp)
    80006672:	6105                	addi	sp,sp,32
    80006674:	8082                	ret
      panic("virtio_disk_intr status");
    80006676:	00002517          	auipc	a0,0x2
    8000667a:	1e250513          	addi	a0,a0,482 # 80008858 <syscalls+0x3c0>
    8000667e:	ffffa097          	auipc	ra,0xffffa
    80006682:	ec0080e7          	jalr	-320(ra) # 8000053e <panic>
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
