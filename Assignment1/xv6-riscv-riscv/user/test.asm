
user/_test:     file format elf64-littleriscv


Disassembly of section .text:

0000000000000000 <pause_system_dem>:
#include "kernel/fcntl.h"
#include "kernel/syscall.h"
#include "kernel/memlayout.h"
#include "kernel/riscv.h"

void pause_system_dem(int interval, int pause_seconds, int loop_size) {
   0:	715d                	addi	sp,sp,-80
   2:	e486                	sd	ra,72(sp)
   4:	e0a2                	sd	s0,64(sp)
   6:	fc26                	sd	s1,56(sp)
   8:	f84a                	sd	s2,48(sp)
   a:	f44e                	sd	s3,40(sp)
   c:	f052                	sd	s4,32(sp)
   e:	ec56                	sd	s5,24(sp)
  10:	e85a                	sd	s6,16(sp)
  12:	e45e                	sd	s7,8(sp)
  14:	0880                	addi	s0,sp,80
  16:	8a2a                	mv	s4,a0
  18:	8b2e                	mv	s6,a1
  1a:	8932                	mv	s2,a2
    int pid = getpid();
  1c:	00000097          	auipc	ra,0x0
  20:	434080e7          	jalr	1076(ra) # 450 <getpid>
    for (int i = 0; i < loop_size; i++) {
  24:	05205b63          	blez	s2,7a <pause_system_dem+0x7a>
  28:	8aaa                	mv	s5,a0
        if (i % interval == 0 && pid == getpid()) {
            printf("pause system %d/%d completed.\n", i, loop_size);
        }
        if (i == loop_size / 2) {
  2a:	01f9599b          	srliw	s3,s2,0x1f
  2e:	012989bb          	addw	s3,s3,s2
  32:	4019d99b          	sraiw	s3,s3,0x1
    for (int i = 0; i < loop_size; i++) {
  36:	4481                	li	s1,0
            printf("pause system %d/%d completed.\n", i, loop_size);
  38:	00001b97          	auipc	s7,0x1
  3c:	8d0b8b93          	addi	s7,s7,-1840 # 908 <malloc+0xea>
  40:	a031                	j	4c <pause_system_dem+0x4c>
        if (i == loop_size / 2) {
  42:	02998663          	beq	s3,s1,6e <pause_system_dem+0x6e>
    for (int i = 0; i < loop_size; i++) {
  46:	2485                	addiw	s1,s1,1
  48:	02990963          	beq	s2,s1,7a <pause_system_dem+0x7a>
        if (i % interval == 0 && pid == getpid()) {
  4c:	0344e7bb          	remw	a5,s1,s4
  50:	fbed                	bnez	a5,42 <pause_system_dem+0x42>
  52:	00000097          	auipc	ra,0x0
  56:	3fe080e7          	jalr	1022(ra) # 450 <getpid>
  5a:	ff5514e3          	bne	a0,s5,42 <pause_system_dem+0x42>
            printf("pause system %d/%d completed.\n", i, loop_size);
  5e:	864a                	mv	a2,s2
  60:	85a6                	mv	a1,s1
  62:	855e                	mv	a0,s7
  64:	00000097          	auipc	ra,0x0
  68:	6fc080e7          	jalr	1788(ra) # 760 <printf>
  6c:	bfd9                	j	42 <pause_system_dem+0x42>
            pause_system(pause_seconds);
  6e:	855a                	mv	a0,s6
  70:	00000097          	auipc	ra,0x0
  74:	400080e7          	jalr	1024(ra) # 470 <pause_system>
  78:	b7f9                	j	46 <pause_system_dem+0x46>
        }
    }
    printf("\n");
  7a:	00001517          	auipc	a0,0x1
  7e:	8ae50513          	addi	a0,a0,-1874 # 928 <malloc+0x10a>
  82:	00000097          	auipc	ra,0x0
  86:	6de080e7          	jalr	1758(ra) # 760 <printf>
}
  8a:	60a6                	ld	ra,72(sp)
  8c:	6406                	ld	s0,64(sp)
  8e:	74e2                	ld	s1,56(sp)
  90:	7942                	ld	s2,48(sp)
  92:	79a2                	ld	s3,40(sp)
  94:	7a02                	ld	s4,32(sp)
  96:	6ae2                	ld	s5,24(sp)
  98:	6b42                	ld	s6,16(sp)
  9a:	6ba2                	ld	s7,8(sp)
  9c:	6161                	addi	sp,sp,80
  9e:	8082                	ret

00000000000000a0 <kill_system_dem>:

void kill_system_dem(int interval, int loop_size) {
  a0:	7139                	addi	sp,sp,-64
  a2:	fc06                	sd	ra,56(sp)
  a4:	f822                	sd	s0,48(sp)
  a6:	f426                	sd	s1,40(sp)
  a8:	f04a                	sd	s2,32(sp)
  aa:	ec4e                	sd	s3,24(sp)
  ac:	e852                	sd	s4,16(sp)
  ae:	e456                	sd	s5,8(sp)
  b0:	e05a                	sd	s6,0(sp)
  b2:	0080                	addi	s0,sp,64
  b4:	8a2a                	mv	s4,a0
  b6:	892e                	mv	s2,a1
    int pid = getpid();
  b8:	00000097          	auipc	ra,0x0
  bc:	398080e7          	jalr	920(ra) # 450 <getpid>
    for (int i = 0; i < loop_size; i++) {
  c0:	05205a63          	blez	s2,114 <kill_system_dem+0x74>
  c4:	8aaa                	mv	s5,a0
        if (i % interval == 0 && pid == getpid()) {
            printf("kill system %d/%d completed.\n", i, loop_size);
        }
        if (i == loop_size / 2) {
  c6:	01f9599b          	srliw	s3,s2,0x1f
  ca:	012989bb          	addw	s3,s3,s2
  ce:	4019d99b          	sraiw	s3,s3,0x1
    for (int i = 0; i < loop_size; i++) {
  d2:	4481                	li	s1,0
            printf("kill system %d/%d completed.\n", i, loop_size);
  d4:	00001b17          	auipc	s6,0x1
  d8:	85cb0b13          	addi	s6,s6,-1956 # 930 <malloc+0x112>
  dc:	a031                	j	e8 <kill_system_dem+0x48>
        if (i == loop_size / 2) {
  de:	02998663          	beq	s3,s1,10a <kill_system_dem+0x6a>
    for (int i = 0; i < loop_size; i++) {
  e2:	2485                	addiw	s1,s1,1
  e4:	02990863          	beq	s2,s1,114 <kill_system_dem+0x74>
        if (i % interval == 0 && pid == getpid()) {
  e8:	0344e7bb          	remw	a5,s1,s4
  ec:	fbed                	bnez	a5,de <kill_system_dem+0x3e>
  ee:	00000097          	auipc	ra,0x0
  f2:	362080e7          	jalr	866(ra) # 450 <getpid>
  f6:	ff5514e3          	bne	a0,s5,de <kill_system_dem+0x3e>
            printf("kill system %d/%d completed.\n", i, loop_size);
  fa:	864a                	mv	a2,s2
  fc:	85a6                	mv	a1,s1
  fe:	855a                	mv	a0,s6
 100:	00000097          	auipc	ra,0x0
 104:	660080e7          	jalr	1632(ra) # 760 <printf>
 108:	bfd9                	j	de <kill_system_dem+0x3e>
            kill_system();
 10a:	00000097          	auipc	ra,0x0
 10e:	36e080e7          	jalr	878(ra) # 478 <kill_system>
 112:	bfc1                	j	e2 <kill_system_dem+0x42>
        }
    }
    printf("\n");
 114:	00001517          	auipc	a0,0x1
 118:	81450513          	addi	a0,a0,-2028 # 928 <malloc+0x10a>
 11c:	00000097          	auipc	ra,0x0
 120:	644080e7          	jalr	1604(ra) # 760 <printf>
}
 124:	70e2                	ld	ra,56(sp)
 126:	7442                	ld	s0,48(sp)
 128:	74a2                	ld	s1,40(sp)
 12a:	7902                	ld	s2,32(sp)
 12c:	69e2                	ld	s3,24(sp)
 12e:	6a42                	ld	s4,16(sp)
 130:	6aa2                	ld	s5,8(sp)
 132:	6b02                	ld	s6,0(sp)
 134:	6121                	addi	sp,sp,64
 136:	8082                	ret

0000000000000138 <main>:
//    printf("\n");
//}

int
main(int argc, char *argv[])
{
 138:	1141                	addi	sp,sp,-16
 13a:	e406                	sd	ra,8(sp)
 13c:	e022                	sd	s0,0(sp)
 13e:	0800                	addi	s0,sp,16
    //set_economic_mode_dem(10, 100);
    pause_system_dem(10, 2, 100);
 140:	06400613          	li	a2,100
 144:	4589                	li	a1,2
 146:	4529                	li	a0,10
 148:	00000097          	auipc	ra,0x0
 14c:	eb8080e7          	jalr	-328(ra) # 0 <pause_system_dem>
//    kill_system_dem(10, 100);
    exit(0);
 150:	4501                	li	a0,0
 152:	00000097          	auipc	ra,0x0
 156:	27e080e7          	jalr	638(ra) # 3d0 <exit>

000000000000015a <strcpy>:
#include "kernel/fcntl.h"
#include "user/user.h"

char*
strcpy(char *s, const char *t)
{
 15a:	1141                	addi	sp,sp,-16
 15c:	e422                	sd	s0,8(sp)
 15e:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while((*s++ = *t++) != 0)
 160:	87aa                	mv	a5,a0
 162:	0585                	addi	a1,a1,1
 164:	0785                	addi	a5,a5,1
 166:	fff5c703          	lbu	a4,-1(a1)
 16a:	fee78fa3          	sb	a4,-1(a5)
 16e:	fb75                	bnez	a4,162 <strcpy+0x8>
    ;
  return os;
}
 170:	6422                	ld	s0,8(sp)
 172:	0141                	addi	sp,sp,16
 174:	8082                	ret

0000000000000176 <strcmp>:

int
strcmp(const char *p, const char *q)
{
 176:	1141                	addi	sp,sp,-16
 178:	e422                	sd	s0,8(sp)
 17a:	0800                	addi	s0,sp,16
  while(*p && *p == *q)
 17c:	00054783          	lbu	a5,0(a0)
 180:	cb91                	beqz	a5,194 <strcmp+0x1e>
 182:	0005c703          	lbu	a4,0(a1)
 186:	00f71763          	bne	a4,a5,194 <strcmp+0x1e>
    p++, q++;
 18a:	0505                	addi	a0,a0,1
 18c:	0585                	addi	a1,a1,1
  while(*p && *p == *q)
 18e:	00054783          	lbu	a5,0(a0)
 192:	fbe5                	bnez	a5,182 <strcmp+0xc>
  return (uchar)*p - (uchar)*q;
 194:	0005c503          	lbu	a0,0(a1)
}
 198:	40a7853b          	subw	a0,a5,a0
 19c:	6422                	ld	s0,8(sp)
 19e:	0141                	addi	sp,sp,16
 1a0:	8082                	ret

00000000000001a2 <strlen>:

uint
strlen(const char *s)
{
 1a2:	1141                	addi	sp,sp,-16
 1a4:	e422                	sd	s0,8(sp)
 1a6:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
 1a8:	00054783          	lbu	a5,0(a0)
 1ac:	cf91                	beqz	a5,1c8 <strlen+0x26>
 1ae:	0505                	addi	a0,a0,1
 1b0:	87aa                	mv	a5,a0
 1b2:	4685                	li	a3,1
 1b4:	9e89                	subw	a3,a3,a0
 1b6:	00f6853b          	addw	a0,a3,a5
 1ba:	0785                	addi	a5,a5,1
 1bc:	fff7c703          	lbu	a4,-1(a5)
 1c0:	fb7d                	bnez	a4,1b6 <strlen+0x14>
    ;
  return n;
}
 1c2:	6422                	ld	s0,8(sp)
 1c4:	0141                	addi	sp,sp,16
 1c6:	8082                	ret
  for(n = 0; s[n]; n++)
 1c8:	4501                	li	a0,0
 1ca:	bfe5                	j	1c2 <strlen+0x20>

00000000000001cc <memset>:

void*
memset(void *dst, int c, uint n)
{
 1cc:	1141                	addi	sp,sp,-16
 1ce:	e422                	sd	s0,8(sp)
 1d0:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
 1d2:	ce09                	beqz	a2,1ec <memset+0x20>
 1d4:	87aa                	mv	a5,a0
 1d6:	fff6071b          	addiw	a4,a2,-1
 1da:	1702                	slli	a4,a4,0x20
 1dc:	9301                	srli	a4,a4,0x20
 1de:	0705                	addi	a4,a4,1
 1e0:	972a                	add	a4,a4,a0
    cdst[i] = c;
 1e2:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
 1e6:	0785                	addi	a5,a5,1
 1e8:	fee79de3          	bne	a5,a4,1e2 <memset+0x16>
  }
  return dst;
}
 1ec:	6422                	ld	s0,8(sp)
 1ee:	0141                	addi	sp,sp,16
 1f0:	8082                	ret

00000000000001f2 <strchr>:

char*
strchr(const char *s, char c)
{
 1f2:	1141                	addi	sp,sp,-16
 1f4:	e422                	sd	s0,8(sp)
 1f6:	0800                	addi	s0,sp,16
  for(; *s; s++)
 1f8:	00054783          	lbu	a5,0(a0)
 1fc:	cb99                	beqz	a5,212 <strchr+0x20>
    if(*s == c)
 1fe:	00f58763          	beq	a1,a5,20c <strchr+0x1a>
  for(; *s; s++)
 202:	0505                	addi	a0,a0,1
 204:	00054783          	lbu	a5,0(a0)
 208:	fbfd                	bnez	a5,1fe <strchr+0xc>
      return (char*)s;
  return 0;
 20a:	4501                	li	a0,0
}
 20c:	6422                	ld	s0,8(sp)
 20e:	0141                	addi	sp,sp,16
 210:	8082                	ret
  return 0;
 212:	4501                	li	a0,0
 214:	bfe5                	j	20c <strchr+0x1a>

0000000000000216 <gets>:

char*
gets(char *buf, int max)
{
 216:	711d                	addi	sp,sp,-96
 218:	ec86                	sd	ra,88(sp)
 21a:	e8a2                	sd	s0,80(sp)
 21c:	e4a6                	sd	s1,72(sp)
 21e:	e0ca                	sd	s2,64(sp)
 220:	fc4e                	sd	s3,56(sp)
 222:	f852                	sd	s4,48(sp)
 224:	f456                	sd	s5,40(sp)
 226:	f05a                	sd	s6,32(sp)
 228:	ec5e                	sd	s7,24(sp)
 22a:	1080                	addi	s0,sp,96
 22c:	8baa                	mv	s7,a0
 22e:	8a2e                	mv	s4,a1
  int i, cc;
  char c;

  for(i=0; i+1 < max; ){
 230:	892a                	mv	s2,a0
 232:	4481                	li	s1,0
    cc = read(0, &c, 1);
    if(cc < 1)
      break;
    buf[i++] = c;
    if(c == '\n' || c == '\r')
 234:	4aa9                	li	s5,10
 236:	4b35                	li	s6,13
  for(i=0; i+1 < max; ){
 238:	89a6                	mv	s3,s1
 23a:	2485                	addiw	s1,s1,1
 23c:	0344d863          	bge	s1,s4,26c <gets+0x56>
    cc = read(0, &c, 1);
 240:	4605                	li	a2,1
 242:	faf40593          	addi	a1,s0,-81
 246:	4501                	li	a0,0
 248:	00000097          	auipc	ra,0x0
 24c:	1a0080e7          	jalr	416(ra) # 3e8 <read>
    if(cc < 1)
 250:	00a05e63          	blez	a0,26c <gets+0x56>
    buf[i++] = c;
 254:	faf44783          	lbu	a5,-81(s0)
 258:	00f90023          	sb	a5,0(s2)
    if(c == '\n' || c == '\r')
 25c:	01578763          	beq	a5,s5,26a <gets+0x54>
 260:	0905                	addi	s2,s2,1
 262:	fd679be3          	bne	a5,s6,238 <gets+0x22>
  for(i=0; i+1 < max; ){
 266:	89a6                	mv	s3,s1
 268:	a011                	j	26c <gets+0x56>
 26a:	89a6                	mv	s3,s1
      break;
  }
  buf[i] = '\0';
 26c:	99de                	add	s3,s3,s7
 26e:	00098023          	sb	zero,0(s3)
  return buf;
}
 272:	855e                	mv	a0,s7
 274:	60e6                	ld	ra,88(sp)
 276:	6446                	ld	s0,80(sp)
 278:	64a6                	ld	s1,72(sp)
 27a:	6906                	ld	s2,64(sp)
 27c:	79e2                	ld	s3,56(sp)
 27e:	7a42                	ld	s4,48(sp)
 280:	7aa2                	ld	s5,40(sp)
 282:	7b02                	ld	s6,32(sp)
 284:	6be2                	ld	s7,24(sp)
 286:	6125                	addi	sp,sp,96
 288:	8082                	ret

000000000000028a <stat>:

int
stat(const char *n, struct stat *st)
{
 28a:	1101                	addi	sp,sp,-32
 28c:	ec06                	sd	ra,24(sp)
 28e:	e822                	sd	s0,16(sp)
 290:	e426                	sd	s1,8(sp)
 292:	e04a                	sd	s2,0(sp)
 294:	1000                	addi	s0,sp,32
 296:	892e                	mv	s2,a1
  int fd;
  int r;

  fd = open(n, O_RDONLY);
 298:	4581                	li	a1,0
 29a:	00000097          	auipc	ra,0x0
 29e:	176080e7          	jalr	374(ra) # 410 <open>
  if(fd < 0)
 2a2:	02054563          	bltz	a0,2cc <stat+0x42>
 2a6:	84aa                	mv	s1,a0
    return -1;
  r = fstat(fd, st);
 2a8:	85ca                	mv	a1,s2
 2aa:	00000097          	auipc	ra,0x0
 2ae:	17e080e7          	jalr	382(ra) # 428 <fstat>
 2b2:	892a                	mv	s2,a0
  close(fd);
 2b4:	8526                	mv	a0,s1
 2b6:	00000097          	auipc	ra,0x0
 2ba:	142080e7          	jalr	322(ra) # 3f8 <close>
  return r;
}
 2be:	854a                	mv	a0,s2
 2c0:	60e2                	ld	ra,24(sp)
 2c2:	6442                	ld	s0,16(sp)
 2c4:	64a2                	ld	s1,8(sp)
 2c6:	6902                	ld	s2,0(sp)
 2c8:	6105                	addi	sp,sp,32
 2ca:	8082                	ret
    return -1;
 2cc:	597d                	li	s2,-1
 2ce:	bfc5                	j	2be <stat+0x34>

00000000000002d0 <atoi>:

int
atoi(const char *s)
{
 2d0:	1141                	addi	sp,sp,-16
 2d2:	e422                	sd	s0,8(sp)
 2d4:	0800                	addi	s0,sp,16
  int n;

  n = 0;
  while('0' <= *s && *s <= '9')
 2d6:	00054603          	lbu	a2,0(a0)
 2da:	fd06079b          	addiw	a5,a2,-48
 2de:	0ff7f793          	andi	a5,a5,255
 2e2:	4725                	li	a4,9
 2e4:	02f76963          	bltu	a4,a5,316 <atoi+0x46>
 2e8:	86aa                	mv	a3,a0
  n = 0;
 2ea:	4501                	li	a0,0
  while('0' <= *s && *s <= '9')
 2ec:	45a5                	li	a1,9
    n = n*10 + *s++ - '0';
 2ee:	0685                	addi	a3,a3,1
 2f0:	0025179b          	slliw	a5,a0,0x2
 2f4:	9fa9                	addw	a5,a5,a0
 2f6:	0017979b          	slliw	a5,a5,0x1
 2fa:	9fb1                	addw	a5,a5,a2
 2fc:	fd07851b          	addiw	a0,a5,-48
  while('0' <= *s && *s <= '9')
 300:	0006c603          	lbu	a2,0(a3)
 304:	fd06071b          	addiw	a4,a2,-48
 308:	0ff77713          	andi	a4,a4,255
 30c:	fee5f1e3          	bgeu	a1,a4,2ee <atoi+0x1e>
  return n;
}
 310:	6422                	ld	s0,8(sp)
 312:	0141                	addi	sp,sp,16
 314:	8082                	ret
  n = 0;
 316:	4501                	li	a0,0
 318:	bfe5                	j	310 <atoi+0x40>

000000000000031a <memmove>:

void*
memmove(void *vdst, const void *vsrc, int n)
{
 31a:	1141                	addi	sp,sp,-16
 31c:	e422                	sd	s0,8(sp)
 31e:	0800                	addi	s0,sp,16
  char *dst;
  const char *src;

  dst = vdst;
  src = vsrc;
  if (src > dst) {
 320:	02b57663          	bgeu	a0,a1,34c <memmove+0x32>
    while(n-- > 0)
 324:	02c05163          	blez	a2,346 <memmove+0x2c>
 328:	fff6079b          	addiw	a5,a2,-1
 32c:	1782                	slli	a5,a5,0x20
 32e:	9381                	srli	a5,a5,0x20
 330:	0785                	addi	a5,a5,1
 332:	97aa                	add	a5,a5,a0
  dst = vdst;
 334:	872a                	mv	a4,a0
      *dst++ = *src++;
 336:	0585                	addi	a1,a1,1
 338:	0705                	addi	a4,a4,1
 33a:	fff5c683          	lbu	a3,-1(a1)
 33e:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
 342:	fee79ae3          	bne	a5,a4,336 <memmove+0x1c>
    src += n;
    while(n-- > 0)
      *--dst = *--src;
  }
  return vdst;
}
 346:	6422                	ld	s0,8(sp)
 348:	0141                	addi	sp,sp,16
 34a:	8082                	ret
    dst += n;
 34c:	00c50733          	add	a4,a0,a2
    src += n;
 350:	95b2                	add	a1,a1,a2
    while(n-- > 0)
 352:	fec05ae3          	blez	a2,346 <memmove+0x2c>
 356:	fff6079b          	addiw	a5,a2,-1
 35a:	1782                	slli	a5,a5,0x20
 35c:	9381                	srli	a5,a5,0x20
 35e:	fff7c793          	not	a5,a5
 362:	97ba                	add	a5,a5,a4
      *--dst = *--src;
 364:	15fd                	addi	a1,a1,-1
 366:	177d                	addi	a4,a4,-1
 368:	0005c683          	lbu	a3,0(a1)
 36c:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
 370:	fee79ae3          	bne	a5,a4,364 <memmove+0x4a>
 374:	bfc9                	j	346 <memmove+0x2c>

0000000000000376 <memcmp>:

int
memcmp(const void *s1, const void *s2, uint n)
{
 376:	1141                	addi	sp,sp,-16
 378:	e422                	sd	s0,8(sp)
 37a:	0800                	addi	s0,sp,16
  const char *p1 = s1, *p2 = s2;
  while (n-- > 0) {
 37c:	ca05                	beqz	a2,3ac <memcmp+0x36>
 37e:	fff6069b          	addiw	a3,a2,-1
 382:	1682                	slli	a3,a3,0x20
 384:	9281                	srli	a3,a3,0x20
 386:	0685                	addi	a3,a3,1
 388:	96aa                	add	a3,a3,a0
    if (*p1 != *p2) {
 38a:	00054783          	lbu	a5,0(a0)
 38e:	0005c703          	lbu	a4,0(a1)
 392:	00e79863          	bne	a5,a4,3a2 <memcmp+0x2c>
      return *p1 - *p2;
    }
    p1++;
 396:	0505                	addi	a0,a0,1
    p2++;
 398:	0585                	addi	a1,a1,1
  while (n-- > 0) {
 39a:	fed518e3          	bne	a0,a3,38a <memcmp+0x14>
  }
  return 0;
 39e:	4501                	li	a0,0
 3a0:	a019                	j	3a6 <memcmp+0x30>
      return *p1 - *p2;
 3a2:	40e7853b          	subw	a0,a5,a4
}
 3a6:	6422                	ld	s0,8(sp)
 3a8:	0141                	addi	sp,sp,16
 3aa:	8082                	ret
  return 0;
 3ac:	4501                	li	a0,0
 3ae:	bfe5                	j	3a6 <memcmp+0x30>

00000000000003b0 <memcpy>:

void *
memcpy(void *dst, const void *src, uint n)
{
 3b0:	1141                	addi	sp,sp,-16
 3b2:	e406                	sd	ra,8(sp)
 3b4:	e022                	sd	s0,0(sp)
 3b6:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
 3b8:	00000097          	auipc	ra,0x0
 3bc:	f62080e7          	jalr	-158(ra) # 31a <memmove>
}
 3c0:	60a2                	ld	ra,8(sp)
 3c2:	6402                	ld	s0,0(sp)
 3c4:	0141                	addi	sp,sp,16
 3c6:	8082                	ret

00000000000003c8 <fork>:
# generated by usys.pl - do not edit
#include "kernel/syscall.h"
.global fork
fork:
 li a7, SYS_fork
 3c8:	4885                	li	a7,1
 ecall
 3ca:	00000073          	ecall
 ret
 3ce:	8082                	ret

00000000000003d0 <exit>:
.global exit
exit:
 li a7, SYS_exit
 3d0:	4889                	li	a7,2
 ecall
 3d2:	00000073          	ecall
 ret
 3d6:	8082                	ret

00000000000003d8 <wait>:
.global wait
wait:
 li a7, SYS_wait
 3d8:	488d                	li	a7,3
 ecall
 3da:	00000073          	ecall
 ret
 3de:	8082                	ret

00000000000003e0 <pipe>:
.global pipe
pipe:
 li a7, SYS_pipe
 3e0:	4891                	li	a7,4
 ecall
 3e2:	00000073          	ecall
 ret
 3e6:	8082                	ret

00000000000003e8 <read>:
.global read
read:
 li a7, SYS_read
 3e8:	4895                	li	a7,5
 ecall
 3ea:	00000073          	ecall
 ret
 3ee:	8082                	ret

00000000000003f0 <write>:
.global write
write:
 li a7, SYS_write
 3f0:	48c1                	li	a7,16
 ecall
 3f2:	00000073          	ecall
 ret
 3f6:	8082                	ret

00000000000003f8 <close>:
.global close
close:
 li a7, SYS_close
 3f8:	48d5                	li	a7,21
 ecall
 3fa:	00000073          	ecall
 ret
 3fe:	8082                	ret

0000000000000400 <kill>:
.global kill
kill:
 li a7, SYS_kill
 400:	4899                	li	a7,6
 ecall
 402:	00000073          	ecall
 ret
 406:	8082                	ret

0000000000000408 <exec>:
.global exec
exec:
 li a7, SYS_exec
 408:	489d                	li	a7,7
 ecall
 40a:	00000073          	ecall
 ret
 40e:	8082                	ret

0000000000000410 <open>:
.global open
open:
 li a7, SYS_open
 410:	48bd                	li	a7,15
 ecall
 412:	00000073          	ecall
 ret
 416:	8082                	ret

0000000000000418 <mknod>:
.global mknod
mknod:
 li a7, SYS_mknod
 418:	48c5                	li	a7,17
 ecall
 41a:	00000073          	ecall
 ret
 41e:	8082                	ret

0000000000000420 <unlink>:
.global unlink
unlink:
 li a7, SYS_unlink
 420:	48c9                	li	a7,18
 ecall
 422:	00000073          	ecall
 ret
 426:	8082                	ret

0000000000000428 <fstat>:
.global fstat
fstat:
 li a7, SYS_fstat
 428:	48a1                	li	a7,8
 ecall
 42a:	00000073          	ecall
 ret
 42e:	8082                	ret

0000000000000430 <link>:
.global link
link:
 li a7, SYS_link
 430:	48cd                	li	a7,19
 ecall
 432:	00000073          	ecall
 ret
 436:	8082                	ret

0000000000000438 <mkdir>:
.global mkdir
mkdir:
 li a7, SYS_mkdir
 438:	48d1                	li	a7,20
 ecall
 43a:	00000073          	ecall
 ret
 43e:	8082                	ret

0000000000000440 <chdir>:
.global chdir
chdir:
 li a7, SYS_chdir
 440:	48a5                	li	a7,9
 ecall
 442:	00000073          	ecall
 ret
 446:	8082                	ret

0000000000000448 <dup>:
.global dup
dup:
 li a7, SYS_dup
 448:	48a9                	li	a7,10
 ecall
 44a:	00000073          	ecall
 ret
 44e:	8082                	ret

0000000000000450 <getpid>:
.global getpid
getpid:
 li a7, SYS_getpid
 450:	48ad                	li	a7,11
 ecall
 452:	00000073          	ecall
 ret
 456:	8082                	ret

0000000000000458 <sbrk>:
.global sbrk
sbrk:
 li a7, SYS_sbrk
 458:	48b1                	li	a7,12
 ecall
 45a:	00000073          	ecall
 ret
 45e:	8082                	ret

0000000000000460 <sleep>:
.global sleep
sleep:
 li a7, SYS_sleep
 460:	48b5                	li	a7,13
 ecall
 462:	00000073          	ecall
 ret
 466:	8082                	ret

0000000000000468 <uptime>:
.global uptime
uptime:
 li a7, SYS_uptime
 468:	48b9                	li	a7,14
 ecall
 46a:	00000073          	ecall
 ret
 46e:	8082                	ret

0000000000000470 <pause_system>:
.global pause_system
pause_system:
 li a7, SYS_pause_system
 470:	48d9                	li	a7,22
 ecall
 472:	00000073          	ecall
 ret
 476:	8082                	ret

0000000000000478 <kill_system>:
.global kill_system
kill_system:
 li a7, SYS_kill_system
 478:	48dd                	li	a7,23
 ecall
 47a:	00000073          	ecall
 ret
 47e:	8082                	ret

0000000000000480 <print_stats>:
.global print_stats
print_stats:
 li a7, SYS_print_stats
 480:	48e1                	li	a7,24
 ecall
 482:	00000073          	ecall
 ret
 486:	8082                	ret

0000000000000488 <putc>:

static char digits[] = "0123456789ABCDEF";

static void
putc(int fd, char c)
{
 488:	1101                	addi	sp,sp,-32
 48a:	ec06                	sd	ra,24(sp)
 48c:	e822                	sd	s0,16(sp)
 48e:	1000                	addi	s0,sp,32
 490:	feb407a3          	sb	a1,-17(s0)
  write(fd, &c, 1);
 494:	4605                	li	a2,1
 496:	fef40593          	addi	a1,s0,-17
 49a:	00000097          	auipc	ra,0x0
 49e:	f56080e7          	jalr	-170(ra) # 3f0 <write>
}
 4a2:	60e2                	ld	ra,24(sp)
 4a4:	6442                	ld	s0,16(sp)
 4a6:	6105                	addi	sp,sp,32
 4a8:	8082                	ret

00000000000004aa <printint>:

static void
printint(int fd, int xx, int base, int sgn)
{
 4aa:	7139                	addi	sp,sp,-64
 4ac:	fc06                	sd	ra,56(sp)
 4ae:	f822                	sd	s0,48(sp)
 4b0:	f426                	sd	s1,40(sp)
 4b2:	f04a                	sd	s2,32(sp)
 4b4:	ec4e                	sd	s3,24(sp)
 4b6:	0080                	addi	s0,sp,64
 4b8:	84aa                	mv	s1,a0
  char buf[16];
  int i, neg;
  uint x;

  neg = 0;
  if(sgn && xx < 0){
 4ba:	c299                	beqz	a3,4c0 <printint+0x16>
 4bc:	0805c863          	bltz	a1,54c <printint+0xa2>
    neg = 1;
    x = -xx;
  } else {
    x = xx;
 4c0:	2581                	sext.w	a1,a1
  neg = 0;
 4c2:	4881                	li	a7,0
 4c4:	fc040693          	addi	a3,s0,-64
  }

  i = 0;
 4c8:	4701                	li	a4,0
  do{
    buf[i++] = digits[x % base];
 4ca:	2601                	sext.w	a2,a2
 4cc:	00000517          	auipc	a0,0x0
 4d0:	48c50513          	addi	a0,a0,1164 # 958 <digits>
 4d4:	883a                	mv	a6,a4
 4d6:	2705                	addiw	a4,a4,1
 4d8:	02c5f7bb          	remuw	a5,a1,a2
 4dc:	1782                	slli	a5,a5,0x20
 4de:	9381                	srli	a5,a5,0x20
 4e0:	97aa                	add	a5,a5,a0
 4e2:	0007c783          	lbu	a5,0(a5)
 4e6:	00f68023          	sb	a5,0(a3)
  }while((x /= base) != 0);
 4ea:	0005879b          	sext.w	a5,a1
 4ee:	02c5d5bb          	divuw	a1,a1,a2
 4f2:	0685                	addi	a3,a3,1
 4f4:	fec7f0e3          	bgeu	a5,a2,4d4 <printint+0x2a>
  if(neg)
 4f8:	00088b63          	beqz	a7,50e <printint+0x64>
    buf[i++] = '-';
 4fc:	fd040793          	addi	a5,s0,-48
 500:	973e                	add	a4,a4,a5
 502:	02d00793          	li	a5,45
 506:	fef70823          	sb	a5,-16(a4)
 50a:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
 50e:	02e05863          	blez	a4,53e <printint+0x94>
 512:	fc040793          	addi	a5,s0,-64
 516:	00e78933          	add	s2,a5,a4
 51a:	fff78993          	addi	s3,a5,-1
 51e:	99ba                	add	s3,s3,a4
 520:	377d                	addiw	a4,a4,-1
 522:	1702                	slli	a4,a4,0x20
 524:	9301                	srli	a4,a4,0x20
 526:	40e989b3          	sub	s3,s3,a4
    putc(fd, buf[i]);
 52a:	fff94583          	lbu	a1,-1(s2)
 52e:	8526                	mv	a0,s1
 530:	00000097          	auipc	ra,0x0
 534:	f58080e7          	jalr	-168(ra) # 488 <putc>
  while(--i >= 0)
 538:	197d                	addi	s2,s2,-1
 53a:	ff3918e3          	bne	s2,s3,52a <printint+0x80>
}
 53e:	70e2                	ld	ra,56(sp)
 540:	7442                	ld	s0,48(sp)
 542:	74a2                	ld	s1,40(sp)
 544:	7902                	ld	s2,32(sp)
 546:	69e2                	ld	s3,24(sp)
 548:	6121                	addi	sp,sp,64
 54a:	8082                	ret
    x = -xx;
 54c:	40b005bb          	negw	a1,a1
    neg = 1;
 550:	4885                	li	a7,1
    x = -xx;
 552:	bf8d                	j	4c4 <printint+0x1a>

0000000000000554 <vprintf>:
}

// Print to the given fd. Only understands %d, %x, %p, %s.
void
vprintf(int fd, const char *fmt, va_list ap)
{
 554:	7119                	addi	sp,sp,-128
 556:	fc86                	sd	ra,120(sp)
 558:	f8a2                	sd	s0,112(sp)
 55a:	f4a6                	sd	s1,104(sp)
 55c:	f0ca                	sd	s2,96(sp)
 55e:	ecce                	sd	s3,88(sp)
 560:	e8d2                	sd	s4,80(sp)
 562:	e4d6                	sd	s5,72(sp)
 564:	e0da                	sd	s6,64(sp)
 566:	fc5e                	sd	s7,56(sp)
 568:	f862                	sd	s8,48(sp)
 56a:	f466                	sd	s9,40(sp)
 56c:	f06a                	sd	s10,32(sp)
 56e:	ec6e                	sd	s11,24(sp)
 570:	0100                	addi	s0,sp,128
  char *s;
  int c, i, state;

  state = 0;
  for(i = 0; fmt[i]; i++){
 572:	0005c903          	lbu	s2,0(a1)
 576:	18090f63          	beqz	s2,714 <vprintf+0x1c0>
 57a:	8aaa                	mv	s5,a0
 57c:	8b32                	mv	s6,a2
 57e:	00158493          	addi	s1,a1,1
  state = 0;
 582:	4981                	li	s3,0
      if(c == '%'){
        state = '%';
      } else {
        putc(fd, c);
      }
    } else if(state == '%'){
 584:	02500a13          	li	s4,37
      if(c == 'd'){
 588:	06400c13          	li	s8,100
        printint(fd, va_arg(ap, int), 10, 1);
      } else if(c == 'l') {
 58c:	06c00c93          	li	s9,108
        printint(fd, va_arg(ap, uint64), 10, 0);
      } else if(c == 'x') {
 590:	07800d13          	li	s10,120
        printint(fd, va_arg(ap, int), 16, 0);
      } else if(c == 'p') {
 594:	07000d93          	li	s11,112
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 598:	00000b97          	auipc	s7,0x0
 59c:	3c0b8b93          	addi	s7,s7,960 # 958 <digits>
 5a0:	a839                	j	5be <vprintf+0x6a>
        putc(fd, c);
 5a2:	85ca                	mv	a1,s2
 5a4:	8556                	mv	a0,s5
 5a6:	00000097          	auipc	ra,0x0
 5aa:	ee2080e7          	jalr	-286(ra) # 488 <putc>
 5ae:	a019                	j	5b4 <vprintf+0x60>
    } else if(state == '%'){
 5b0:	01498f63          	beq	s3,s4,5ce <vprintf+0x7a>
  for(i = 0; fmt[i]; i++){
 5b4:	0485                	addi	s1,s1,1
 5b6:	fff4c903          	lbu	s2,-1(s1)
 5ba:	14090d63          	beqz	s2,714 <vprintf+0x1c0>
    c = fmt[i] & 0xff;
 5be:	0009079b          	sext.w	a5,s2
    if(state == 0){
 5c2:	fe0997e3          	bnez	s3,5b0 <vprintf+0x5c>
      if(c == '%'){
 5c6:	fd479ee3          	bne	a5,s4,5a2 <vprintf+0x4e>
        state = '%';
 5ca:	89be                	mv	s3,a5
 5cc:	b7e5                	j	5b4 <vprintf+0x60>
      if(c == 'd'){
 5ce:	05878063          	beq	a5,s8,60e <vprintf+0xba>
      } else if(c == 'l') {
 5d2:	05978c63          	beq	a5,s9,62a <vprintf+0xd6>
      } else if(c == 'x') {
 5d6:	07a78863          	beq	a5,s10,646 <vprintf+0xf2>
      } else if(c == 'p') {
 5da:	09b78463          	beq	a5,s11,662 <vprintf+0x10e>
        printptr(fd, va_arg(ap, uint64));
      } else if(c == 's'){
 5de:	07300713          	li	a4,115
 5e2:	0ce78663          	beq	a5,a4,6ae <vprintf+0x15a>
          s = "(null)";
        while(*s != 0){
          putc(fd, *s);
          s++;
        }
      } else if(c == 'c'){
 5e6:	06300713          	li	a4,99
 5ea:	0ee78e63          	beq	a5,a4,6e6 <vprintf+0x192>
        putc(fd, va_arg(ap, uint));
      } else if(c == '%'){
 5ee:	11478863          	beq	a5,s4,6fe <vprintf+0x1aa>
        putc(fd, c);
      } else {
        // Unknown % sequence.  Print it to draw attention.
        putc(fd, '%');
 5f2:	85d2                	mv	a1,s4
 5f4:	8556                	mv	a0,s5
 5f6:	00000097          	auipc	ra,0x0
 5fa:	e92080e7          	jalr	-366(ra) # 488 <putc>
        putc(fd, c);
 5fe:	85ca                	mv	a1,s2
 600:	8556                	mv	a0,s5
 602:	00000097          	auipc	ra,0x0
 606:	e86080e7          	jalr	-378(ra) # 488 <putc>
      }
      state = 0;
 60a:	4981                	li	s3,0
 60c:	b765                	j	5b4 <vprintf+0x60>
        printint(fd, va_arg(ap, int), 10, 1);
 60e:	008b0913          	addi	s2,s6,8
 612:	4685                	li	a3,1
 614:	4629                	li	a2,10
 616:	000b2583          	lw	a1,0(s6)
 61a:	8556                	mv	a0,s5
 61c:	00000097          	auipc	ra,0x0
 620:	e8e080e7          	jalr	-370(ra) # 4aa <printint>
 624:	8b4a                	mv	s6,s2
      state = 0;
 626:	4981                	li	s3,0
 628:	b771                	j	5b4 <vprintf+0x60>
        printint(fd, va_arg(ap, uint64), 10, 0);
 62a:	008b0913          	addi	s2,s6,8
 62e:	4681                	li	a3,0
 630:	4629                	li	a2,10
 632:	000b2583          	lw	a1,0(s6)
 636:	8556                	mv	a0,s5
 638:	00000097          	auipc	ra,0x0
 63c:	e72080e7          	jalr	-398(ra) # 4aa <printint>
 640:	8b4a                	mv	s6,s2
      state = 0;
 642:	4981                	li	s3,0
 644:	bf85                	j	5b4 <vprintf+0x60>
        printint(fd, va_arg(ap, int), 16, 0);
 646:	008b0913          	addi	s2,s6,8
 64a:	4681                	li	a3,0
 64c:	4641                	li	a2,16
 64e:	000b2583          	lw	a1,0(s6)
 652:	8556                	mv	a0,s5
 654:	00000097          	auipc	ra,0x0
 658:	e56080e7          	jalr	-426(ra) # 4aa <printint>
 65c:	8b4a                	mv	s6,s2
      state = 0;
 65e:	4981                	li	s3,0
 660:	bf91                	j	5b4 <vprintf+0x60>
        printptr(fd, va_arg(ap, uint64));
 662:	008b0793          	addi	a5,s6,8
 666:	f8f43423          	sd	a5,-120(s0)
 66a:	000b3983          	ld	s3,0(s6)
  putc(fd, '0');
 66e:	03000593          	li	a1,48
 672:	8556                	mv	a0,s5
 674:	00000097          	auipc	ra,0x0
 678:	e14080e7          	jalr	-492(ra) # 488 <putc>
  putc(fd, 'x');
 67c:	85ea                	mv	a1,s10
 67e:	8556                	mv	a0,s5
 680:	00000097          	auipc	ra,0x0
 684:	e08080e7          	jalr	-504(ra) # 488 <putc>
 688:	4941                	li	s2,16
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 68a:	03c9d793          	srli	a5,s3,0x3c
 68e:	97de                	add	a5,a5,s7
 690:	0007c583          	lbu	a1,0(a5)
 694:	8556                	mv	a0,s5
 696:	00000097          	auipc	ra,0x0
 69a:	df2080e7          	jalr	-526(ra) # 488 <putc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
 69e:	0992                	slli	s3,s3,0x4
 6a0:	397d                	addiw	s2,s2,-1
 6a2:	fe0914e3          	bnez	s2,68a <vprintf+0x136>
        printptr(fd, va_arg(ap, uint64));
 6a6:	f8843b03          	ld	s6,-120(s0)
      state = 0;
 6aa:	4981                	li	s3,0
 6ac:	b721                	j	5b4 <vprintf+0x60>
        s = va_arg(ap, char*);
 6ae:	008b0993          	addi	s3,s6,8
 6b2:	000b3903          	ld	s2,0(s6)
        if(s == 0)
 6b6:	02090163          	beqz	s2,6d8 <vprintf+0x184>
        while(*s != 0){
 6ba:	00094583          	lbu	a1,0(s2)
 6be:	c9a1                	beqz	a1,70e <vprintf+0x1ba>
          putc(fd, *s);
 6c0:	8556                	mv	a0,s5
 6c2:	00000097          	auipc	ra,0x0
 6c6:	dc6080e7          	jalr	-570(ra) # 488 <putc>
          s++;
 6ca:	0905                	addi	s2,s2,1
        while(*s != 0){
 6cc:	00094583          	lbu	a1,0(s2)
 6d0:	f9e5                	bnez	a1,6c0 <vprintf+0x16c>
        s = va_arg(ap, char*);
 6d2:	8b4e                	mv	s6,s3
      state = 0;
 6d4:	4981                	li	s3,0
 6d6:	bdf9                	j	5b4 <vprintf+0x60>
          s = "(null)";
 6d8:	00000917          	auipc	s2,0x0
 6dc:	27890913          	addi	s2,s2,632 # 950 <malloc+0x132>
        while(*s != 0){
 6e0:	02800593          	li	a1,40
 6e4:	bff1                	j	6c0 <vprintf+0x16c>
        putc(fd, va_arg(ap, uint));
 6e6:	008b0913          	addi	s2,s6,8
 6ea:	000b4583          	lbu	a1,0(s6)
 6ee:	8556                	mv	a0,s5
 6f0:	00000097          	auipc	ra,0x0
 6f4:	d98080e7          	jalr	-616(ra) # 488 <putc>
 6f8:	8b4a                	mv	s6,s2
      state = 0;
 6fa:	4981                	li	s3,0
 6fc:	bd65                	j	5b4 <vprintf+0x60>
        putc(fd, c);
 6fe:	85d2                	mv	a1,s4
 700:	8556                	mv	a0,s5
 702:	00000097          	auipc	ra,0x0
 706:	d86080e7          	jalr	-634(ra) # 488 <putc>
      state = 0;
 70a:	4981                	li	s3,0
 70c:	b565                	j	5b4 <vprintf+0x60>
        s = va_arg(ap, char*);
 70e:	8b4e                	mv	s6,s3
      state = 0;
 710:	4981                	li	s3,0
 712:	b54d                	j	5b4 <vprintf+0x60>
    }
  }
}
 714:	70e6                	ld	ra,120(sp)
 716:	7446                	ld	s0,112(sp)
 718:	74a6                	ld	s1,104(sp)
 71a:	7906                	ld	s2,96(sp)
 71c:	69e6                	ld	s3,88(sp)
 71e:	6a46                	ld	s4,80(sp)
 720:	6aa6                	ld	s5,72(sp)
 722:	6b06                	ld	s6,64(sp)
 724:	7be2                	ld	s7,56(sp)
 726:	7c42                	ld	s8,48(sp)
 728:	7ca2                	ld	s9,40(sp)
 72a:	7d02                	ld	s10,32(sp)
 72c:	6de2                	ld	s11,24(sp)
 72e:	6109                	addi	sp,sp,128
 730:	8082                	ret

0000000000000732 <fprintf>:

void
fprintf(int fd, const char *fmt, ...)
{
 732:	715d                	addi	sp,sp,-80
 734:	ec06                	sd	ra,24(sp)
 736:	e822                	sd	s0,16(sp)
 738:	1000                	addi	s0,sp,32
 73a:	e010                	sd	a2,0(s0)
 73c:	e414                	sd	a3,8(s0)
 73e:	e818                	sd	a4,16(s0)
 740:	ec1c                	sd	a5,24(s0)
 742:	03043023          	sd	a6,32(s0)
 746:	03143423          	sd	a7,40(s0)
  va_list ap;

  va_start(ap, fmt);
 74a:	fe843423          	sd	s0,-24(s0)
  vprintf(fd, fmt, ap);
 74e:	8622                	mv	a2,s0
 750:	00000097          	auipc	ra,0x0
 754:	e04080e7          	jalr	-508(ra) # 554 <vprintf>
}
 758:	60e2                	ld	ra,24(sp)
 75a:	6442                	ld	s0,16(sp)
 75c:	6161                	addi	sp,sp,80
 75e:	8082                	ret

0000000000000760 <printf>:

void
printf(const char *fmt, ...)
{
 760:	711d                	addi	sp,sp,-96
 762:	ec06                	sd	ra,24(sp)
 764:	e822                	sd	s0,16(sp)
 766:	1000                	addi	s0,sp,32
 768:	e40c                	sd	a1,8(s0)
 76a:	e810                	sd	a2,16(s0)
 76c:	ec14                	sd	a3,24(s0)
 76e:	f018                	sd	a4,32(s0)
 770:	f41c                	sd	a5,40(s0)
 772:	03043823          	sd	a6,48(s0)
 776:	03143c23          	sd	a7,56(s0)
  va_list ap;

  va_start(ap, fmt);
 77a:	00840613          	addi	a2,s0,8
 77e:	fec43423          	sd	a2,-24(s0)
  vprintf(1, fmt, ap);
 782:	85aa                	mv	a1,a0
 784:	4505                	li	a0,1
 786:	00000097          	auipc	ra,0x0
 78a:	dce080e7          	jalr	-562(ra) # 554 <vprintf>
}
 78e:	60e2                	ld	ra,24(sp)
 790:	6442                	ld	s0,16(sp)
 792:	6125                	addi	sp,sp,96
 794:	8082                	ret

0000000000000796 <free>:
static Header base;
static Header *freep;

void
free(void *ap)
{
 796:	1141                	addi	sp,sp,-16
 798:	e422                	sd	s0,8(sp)
 79a:	0800                	addi	s0,sp,16
  Header *bp, *p;

  bp = (Header*)ap - 1;
 79c:	ff050693          	addi	a3,a0,-16
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 7a0:	00000797          	auipc	a5,0x0
 7a4:	1d07b783          	ld	a5,464(a5) # 970 <freep>
 7a8:	a805                	j	7d8 <free+0x42>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
      break;
  if(bp + bp->s.size == p->s.ptr){
    bp->s.size += p->s.ptr->s.size;
 7aa:	4618                	lw	a4,8(a2)
 7ac:	9db9                	addw	a1,a1,a4
 7ae:	feb52c23          	sw	a1,-8(a0)
    bp->s.ptr = p->s.ptr->s.ptr;
 7b2:	6398                	ld	a4,0(a5)
 7b4:	6318                	ld	a4,0(a4)
 7b6:	fee53823          	sd	a4,-16(a0)
 7ba:	a091                	j	7fe <free+0x68>
  } else
    bp->s.ptr = p->s.ptr;
  if(p + p->s.size == bp){
    p->s.size += bp->s.size;
 7bc:	ff852703          	lw	a4,-8(a0)
 7c0:	9e39                	addw	a2,a2,a4
 7c2:	c790                	sw	a2,8(a5)
    p->s.ptr = bp->s.ptr;
 7c4:	ff053703          	ld	a4,-16(a0)
 7c8:	e398                	sd	a4,0(a5)
 7ca:	a099                	j	810 <free+0x7a>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 7cc:	6398                	ld	a4,0(a5)
 7ce:	00e7e463          	bltu	a5,a4,7d6 <free+0x40>
 7d2:	00e6ea63          	bltu	a3,a4,7e6 <free+0x50>
{
 7d6:	87ba                	mv	a5,a4
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 7d8:	fed7fae3          	bgeu	a5,a3,7cc <free+0x36>
 7dc:	6398                	ld	a4,0(a5)
 7de:	00e6e463          	bltu	a3,a4,7e6 <free+0x50>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 7e2:	fee7eae3          	bltu	a5,a4,7d6 <free+0x40>
  if(bp + bp->s.size == p->s.ptr){
 7e6:	ff852583          	lw	a1,-8(a0)
 7ea:	6390                	ld	a2,0(a5)
 7ec:	02059713          	slli	a4,a1,0x20
 7f0:	9301                	srli	a4,a4,0x20
 7f2:	0712                	slli	a4,a4,0x4
 7f4:	9736                	add	a4,a4,a3
 7f6:	fae60ae3          	beq	a2,a4,7aa <free+0x14>
    bp->s.ptr = p->s.ptr;
 7fa:	fec53823          	sd	a2,-16(a0)
  if(p + p->s.size == bp){
 7fe:	4790                	lw	a2,8(a5)
 800:	02061713          	slli	a4,a2,0x20
 804:	9301                	srli	a4,a4,0x20
 806:	0712                	slli	a4,a4,0x4
 808:	973e                	add	a4,a4,a5
 80a:	fae689e3          	beq	a3,a4,7bc <free+0x26>
  } else
    p->s.ptr = bp;
 80e:	e394                	sd	a3,0(a5)
  freep = p;
 810:	00000717          	auipc	a4,0x0
 814:	16f73023          	sd	a5,352(a4) # 970 <freep>
}
 818:	6422                	ld	s0,8(sp)
 81a:	0141                	addi	sp,sp,16
 81c:	8082                	ret

000000000000081e <malloc>:
  return freep;
}

void*
malloc(uint nbytes)
{
 81e:	7139                	addi	sp,sp,-64
 820:	fc06                	sd	ra,56(sp)
 822:	f822                	sd	s0,48(sp)
 824:	f426                	sd	s1,40(sp)
 826:	f04a                	sd	s2,32(sp)
 828:	ec4e                	sd	s3,24(sp)
 82a:	e852                	sd	s4,16(sp)
 82c:	e456                	sd	s5,8(sp)
 82e:	e05a                	sd	s6,0(sp)
 830:	0080                	addi	s0,sp,64
  Header *p, *prevp;
  uint nunits;

  nunits = (nbytes + sizeof(Header) - 1)/sizeof(Header) + 1;
 832:	02051493          	slli	s1,a0,0x20
 836:	9081                	srli	s1,s1,0x20
 838:	04bd                	addi	s1,s1,15
 83a:	8091                	srli	s1,s1,0x4
 83c:	0014899b          	addiw	s3,s1,1
 840:	0485                	addi	s1,s1,1
  if((prevp = freep) == 0){
 842:	00000517          	auipc	a0,0x0
 846:	12e53503          	ld	a0,302(a0) # 970 <freep>
 84a:	c515                	beqz	a0,876 <malloc+0x58>
    base.s.ptr = freep = prevp = &base;
    base.s.size = 0;
  }
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 84c:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 84e:	4798                	lw	a4,8(a5)
 850:	02977f63          	bgeu	a4,s1,88e <malloc+0x70>
 854:	8a4e                	mv	s4,s3
 856:	0009871b          	sext.w	a4,s3
 85a:	6685                	lui	a3,0x1
 85c:	00d77363          	bgeu	a4,a3,862 <malloc+0x44>
 860:	6a05                	lui	s4,0x1
 862:	000a0b1b          	sext.w	s6,s4
  p = sbrk(nu * sizeof(Header));
 866:	004a1a1b          	slliw	s4,s4,0x4
        p->s.size = nunits;
      }
      freep = prevp;
      return (void*)(p + 1);
    }
    if(p == freep)
 86a:	00000917          	auipc	s2,0x0
 86e:	10690913          	addi	s2,s2,262 # 970 <freep>
  if(p == (char*)-1)
 872:	5afd                	li	s5,-1
 874:	a88d                	j	8e6 <malloc+0xc8>
    base.s.ptr = freep = prevp = &base;
 876:	00000797          	auipc	a5,0x0
 87a:	10278793          	addi	a5,a5,258 # 978 <base>
 87e:	00000717          	auipc	a4,0x0
 882:	0ef73923          	sd	a5,242(a4) # 970 <freep>
 886:	e39c                	sd	a5,0(a5)
    base.s.size = 0;
 888:	0007a423          	sw	zero,8(a5)
    if(p->s.size >= nunits){
 88c:	b7e1                	j	854 <malloc+0x36>
      if(p->s.size == nunits)
 88e:	02e48b63          	beq	s1,a4,8c4 <malloc+0xa6>
        p->s.size -= nunits;
 892:	4137073b          	subw	a4,a4,s3
 896:	c798                	sw	a4,8(a5)
        p += p->s.size;
 898:	1702                	slli	a4,a4,0x20
 89a:	9301                	srli	a4,a4,0x20
 89c:	0712                	slli	a4,a4,0x4
 89e:	97ba                	add	a5,a5,a4
        p->s.size = nunits;
 8a0:	0137a423          	sw	s3,8(a5)
      freep = prevp;
 8a4:	00000717          	auipc	a4,0x0
 8a8:	0ca73623          	sd	a0,204(a4) # 970 <freep>
      return (void*)(p + 1);
 8ac:	01078513          	addi	a0,a5,16
      if((p = morecore(nunits)) == 0)
        return 0;
  }
}
 8b0:	70e2                	ld	ra,56(sp)
 8b2:	7442                	ld	s0,48(sp)
 8b4:	74a2                	ld	s1,40(sp)
 8b6:	7902                	ld	s2,32(sp)
 8b8:	69e2                	ld	s3,24(sp)
 8ba:	6a42                	ld	s4,16(sp)
 8bc:	6aa2                	ld	s5,8(sp)
 8be:	6b02                	ld	s6,0(sp)
 8c0:	6121                	addi	sp,sp,64
 8c2:	8082                	ret
        prevp->s.ptr = p->s.ptr;
 8c4:	6398                	ld	a4,0(a5)
 8c6:	e118                	sd	a4,0(a0)
 8c8:	bff1                	j	8a4 <malloc+0x86>
  hp->s.size = nu;
 8ca:	01652423          	sw	s6,8(a0)
  free((void*)(hp + 1));
 8ce:	0541                	addi	a0,a0,16
 8d0:	00000097          	auipc	ra,0x0
 8d4:	ec6080e7          	jalr	-314(ra) # 796 <free>
  return freep;
 8d8:	00093503          	ld	a0,0(s2)
      if((p = morecore(nunits)) == 0)
 8dc:	d971                	beqz	a0,8b0 <malloc+0x92>
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 8de:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 8e0:	4798                	lw	a4,8(a5)
 8e2:	fa9776e3          	bgeu	a4,s1,88e <malloc+0x70>
    if(p == freep)
 8e6:	00093703          	ld	a4,0(s2)
 8ea:	853e                	mv	a0,a5
 8ec:	fef719e3          	bne	a4,a5,8de <malloc+0xc0>
  p = sbrk(nu * sizeof(Header));
 8f0:	8552                	mv	a0,s4
 8f2:	00000097          	auipc	ra,0x0
 8f6:	b66080e7          	jalr	-1178(ra) # 458 <sbrk>
  if(p == (char*)-1)
 8fa:	fd5518e3          	bne	a0,s5,8ca <malloc+0xac>
        return 0;
 8fe:	4501                	li	a0,0
 900:	bf45                	j	8b0 <malloc+0x92>
