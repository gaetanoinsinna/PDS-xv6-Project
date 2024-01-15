
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	0000b117          	auipc	sp,0xb
    80000004:	1f013103          	ld	sp,496(sp) # 8000b1f0 <_GLOBAL_OFFSET_TABLE_+0x8>
    80000008:	6505                	lui	a0,0x1
    8000000a:	f14025f3          	csrr	a1,mhartid
    8000000e:	0585                	addi	a1,a1,1
    80000010:	02b50533          	mul	a0,a0,a1
    80000014:	912a                	add	sp,sp,a0
    80000016:	076000ef          	jal	8000008c <start>

000000008000001a <spin>:
    8000001a:	a001                	j	8000001a <spin>

000000008000001c <timerinit>:
// at timervec in kernelvec.S,
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
    80000026:	0007859b          	sext.w	a1,a5

  // ask the CLINT for a timer interrupt.
  int interval = 1000000; // cycles; about 1/10th second in qemu.
  *(uint64*)CLINT_MTIMECMP(id) = *(uint64*)CLINT_MTIME + interval;
    8000002a:	0037979b          	slliw	a5,a5,0x3
    8000002e:	02004737          	lui	a4,0x2004
    80000032:	97ba                	add	a5,a5,a4
    80000034:	0200c737          	lui	a4,0x200c
    80000038:	1761                	addi	a4,a4,-8 # 200bff8 <_entry-0x7dff4008>
    8000003a:	6318                	ld	a4,0(a4)
    8000003c:	000f4637          	lui	a2,0xf4
    80000040:	24060613          	addi	a2,a2,576 # f4240 <_entry-0x7ff0bdc0>
    80000044:	9732                	add	a4,a4,a2
    80000046:	e398                	sd	a4,0(a5)

  // prepare information in scratch[] for timervec.
  // scratch[0..2] : space for timervec to save registers.
  // scratch[3] : address of CLINT MTIMECMP register.
  // scratch[4] : desired interval (in cycles) between timer interrupts.
  uint64 *scratch = &timer_scratch[id][0];
    80000048:	00259693          	slli	a3,a1,0x2
    8000004c:	96ae                	add	a3,a3,a1
    8000004e:	068e                	slli	a3,a3,0x3
    80000050:	0000b717          	auipc	a4,0xb
    80000054:	20070713          	addi	a4,a4,512 # 8000b250 <timer_scratch>
    80000058:	9736                	add	a4,a4,a3
  scratch[3] = CLINT_MTIMECMP(id);
    8000005a:	ef1c                	sd	a5,24(a4)
  scratch[4] = interval;
    8000005c:	f310                	sd	a2,32(a4)
}

static inline void 
w_mscratch(uint64 x)
{
  asm volatile("csrw mscratch, %0" : : "r" (x));
    8000005e:	34071073          	csrw	mscratch,a4
  asm volatile("csrw mtvec, %0" : : "r" (x));
    80000062:	00006797          	auipc	a5,0x6
    80000066:	d4e78793          	addi	a5,a5,-690 # 80005db0 <timervec>
    8000006a:	30579073          	csrw	mtvec,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    8000006e:	300027f3          	csrr	a5,mstatus

  // set the machine-mode trap handler.
  w_mtvec((uint64)timervec);

  // enable machine-mode interrupts.
  w_mstatus(r_mstatus() | MSTATUS_MIE);
    80000072:	0087e793          	ori	a5,a5,8
  asm volatile("csrw mstatus, %0" : : "r" (x));
    80000076:	30079073          	csrw	mstatus,a5
  asm volatile("csrr %0, mie" : "=r" (x) );
    8000007a:	304027f3          	csrr	a5,mie

  // enable machine-mode timer interrupts.
  w_mie(r_mie() | MIE_MTIE);
    8000007e:	0807e793          	ori	a5,a5,128
  asm volatile("csrw mie, %0" : : "r" (x));
    80000082:	30479073          	csrw	mie,a5
}
    80000086:	6422                	ld	s0,8(sp)
    80000088:	0141                	addi	sp,sp,16
    8000008a:	8082                	ret

000000008000008c <start>:
{
    8000008c:	1141                	addi	sp,sp,-16
    8000008e:	e406                	sd	ra,8(sp)
    80000090:	e022                	sd	s0,0(sp)
    80000092:	0800                	addi	s0,sp,16
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000094:	300027f3          	csrr	a5,mstatus
  x &= ~MSTATUS_MPP_MASK;
    80000098:	7779                	lui	a4,0xffffe
    8000009a:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffda13f>
    8000009e:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    800000a0:	6705                	lui	a4,0x1
    800000a2:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a6:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000a8:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000ac:	00001797          	auipc	a5,0x1
    800000b0:	e6e78793          	addi	a5,a5,-402 # 80000f1a <main>
    800000b4:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    800000b8:	4781                	li	a5,0
    800000ba:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    800000be:	67c1                	lui	a5,0x10
    800000c0:	17fd                	addi	a5,a5,-1 # ffff <_entry-0x7fff0001>
    800000c2:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    800000c6:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    800000ca:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    800000ce:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    800000d2:	10479073          	csrw	sie,a5
  asm volatile("csrw pmpaddr0, %0" : : "r" (x));
    800000d6:	57fd                	li	a5,-1
    800000d8:	83a9                	srli	a5,a5,0xa
    800000da:	3b079073          	csrw	pmpaddr0,a5
  asm volatile("csrw pmpcfg0, %0" : : "r" (x));
    800000de:	47bd                	li	a5,15
    800000e0:	3a079073          	csrw	pmpcfg0,a5
  timerinit();
    800000e4:	00000097          	auipc	ra,0x0
    800000e8:	f38080e7          	jalr	-200(ra) # 8000001c <timerinit>
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800000ec:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    800000f0:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    800000f2:	823e                	mv	tp,a5
  asm volatile("mret");
    800000f4:	30200073          	mret
}
    800000f8:	60a2                	ld	ra,8(sp)
    800000fa:	6402                	ld	s0,0(sp)
    800000fc:	0141                	addi	sp,sp,16
    800000fe:	8082                	ret

0000000080000100 <consolewrite>:
//
// user write()s to the console go here.
//
int
consolewrite(int user_src, uint64 src, int n)
{
    80000100:	715d                	addi	sp,sp,-80
    80000102:	e486                	sd	ra,72(sp)
    80000104:	e0a2                	sd	s0,64(sp)
    80000106:	f84a                	sd	s2,48(sp)
    80000108:	0880                	addi	s0,sp,80
  int i;

  for(i = 0; i < n; i++){
    8000010a:	04c05663          	blez	a2,80000156 <consolewrite+0x56>
    8000010e:	fc26                	sd	s1,56(sp)
    80000110:	f44e                	sd	s3,40(sp)
    80000112:	f052                	sd	s4,32(sp)
    80000114:	ec56                	sd	s5,24(sp)
    80000116:	8a2a                	mv	s4,a0
    80000118:	84ae                	mv	s1,a1
    8000011a:	89b2                	mv	s3,a2
    8000011c:	4901                	li	s2,0
    char c;
    if(either_copyin(&c, user_src, src+i, 1) == -1)
    8000011e:	5afd                	li	s5,-1
    80000120:	4685                	li	a3,1
    80000122:	8626                	mv	a2,s1
    80000124:	85d2                	mv	a1,s4
    80000126:	fbf40513          	addi	a0,s0,-65
    8000012a:	00002097          	auipc	ra,0x2
    8000012e:	48a080e7          	jalr	1162(ra) # 800025b4 <either_copyin>
    80000132:	03550463          	beq	a0,s5,8000015a <consolewrite+0x5a>
      break;
    uartputc(c);
    80000136:	fbf44503          	lbu	a0,-65(s0)
    8000013a:	00000097          	auipc	ra,0x0
    8000013e:	7e4080e7          	jalr	2020(ra) # 8000091e <uartputc>
  for(i = 0; i < n; i++){
    80000142:	2905                	addiw	s2,s2,1
    80000144:	0485                	addi	s1,s1,1
    80000146:	fd299de3          	bne	s3,s2,80000120 <consolewrite+0x20>
    8000014a:	894e                	mv	s2,s3
    8000014c:	74e2                	ld	s1,56(sp)
    8000014e:	79a2                	ld	s3,40(sp)
    80000150:	7a02                	ld	s4,32(sp)
    80000152:	6ae2                	ld	s5,24(sp)
    80000154:	a039                	j	80000162 <consolewrite+0x62>
    80000156:	4901                	li	s2,0
    80000158:	a029                	j	80000162 <consolewrite+0x62>
    8000015a:	74e2                	ld	s1,56(sp)
    8000015c:	79a2                	ld	s3,40(sp)
    8000015e:	7a02                	ld	s4,32(sp)
    80000160:	6ae2                	ld	s5,24(sp)
  }

  return i;
}
    80000162:	854a                	mv	a0,s2
    80000164:	60a6                	ld	ra,72(sp)
    80000166:	6406                	ld	s0,64(sp)
    80000168:	7942                	ld	s2,48(sp)
    8000016a:	6161                	addi	sp,sp,80
    8000016c:	8082                	ret

000000008000016e <consoleread>:
// user_dist indicates whether dst is a user
// or kernel address.
//
int
consoleread(int user_dst, uint64 dst, int n)
{
    8000016e:	711d                	addi	sp,sp,-96
    80000170:	ec86                	sd	ra,88(sp)
    80000172:	e8a2                	sd	s0,80(sp)
    80000174:	e4a6                	sd	s1,72(sp)
    80000176:	e0ca                	sd	s2,64(sp)
    80000178:	fc4e                	sd	s3,56(sp)
    8000017a:	f852                	sd	s4,48(sp)
    8000017c:	f456                	sd	s5,40(sp)
    8000017e:	f05a                	sd	s6,32(sp)
    80000180:	1080                	addi	s0,sp,96
    80000182:	8aaa                	mv	s5,a0
    80000184:	8a2e                	mv	s4,a1
    80000186:	89b2                	mv	s3,a2
  uint target;
  int c;
  char cbuf;

  target = n;
    80000188:	00060b1b          	sext.w	s6,a2
  acquire(&cons.lock);
    8000018c:	00013517          	auipc	a0,0x13
    80000190:	20450513          	addi	a0,a0,516 # 80013390 <cons>
    80000194:	00001097          	auipc	ra,0x1
    80000198:	aec080e7          	jalr	-1300(ra) # 80000c80 <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    8000019c:	00013497          	auipc	s1,0x13
    800001a0:	1f448493          	addi	s1,s1,500 # 80013390 <cons>
      if(killed(myproc())){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001a4:	00013917          	auipc	s2,0x13
    800001a8:	28490913          	addi	s2,s2,644 # 80013428 <cons+0x98>
  while(n > 0){
    800001ac:	0d305763          	blez	s3,8000027a <consoleread+0x10c>
    while(cons.r == cons.w){
    800001b0:	0984a783          	lw	a5,152(s1)
    800001b4:	09c4a703          	lw	a4,156(s1)
    800001b8:	0af71c63          	bne	a4,a5,80000270 <consoleread+0x102>
      if(killed(myproc())){
    800001bc:	00002097          	auipc	ra,0x2
    800001c0:	8f0080e7          	jalr	-1808(ra) # 80001aac <myproc>
    800001c4:	00002097          	auipc	ra,0x2
    800001c8:	23a080e7          	jalr	570(ra) # 800023fe <killed>
    800001cc:	e52d                	bnez	a0,80000236 <consoleread+0xc8>
      sleep(&cons.r, &cons.lock);
    800001ce:	85a6                	mv	a1,s1
    800001d0:	854a                	mv	a0,s2
    800001d2:	00002097          	auipc	ra,0x2
    800001d6:	f84080e7          	jalr	-124(ra) # 80002156 <sleep>
    while(cons.r == cons.w){
    800001da:	0984a783          	lw	a5,152(s1)
    800001de:	09c4a703          	lw	a4,156(s1)
    800001e2:	fcf70de3          	beq	a4,a5,800001bc <consoleread+0x4e>
    800001e6:	ec5e                	sd	s7,24(sp)
    }

    c = cons.buf[cons.r++ % INPUT_BUF_SIZE];
    800001e8:	00013717          	auipc	a4,0x13
    800001ec:	1a870713          	addi	a4,a4,424 # 80013390 <cons>
    800001f0:	0017869b          	addiw	a3,a5,1
    800001f4:	08d72c23          	sw	a3,152(a4)
    800001f8:	07f7f693          	andi	a3,a5,127
    800001fc:	9736                	add	a4,a4,a3
    800001fe:	01874703          	lbu	a4,24(a4)
    80000202:	00070b9b          	sext.w	s7,a4

    if(c == C('D')){  // end-of-file
    80000206:	4691                	li	a3,4
    80000208:	04db8a63          	beq	s7,a3,8000025c <consoleread+0xee>
      }
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    8000020c:	fae407a3          	sb	a4,-81(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    80000210:	4685                	li	a3,1
    80000212:	faf40613          	addi	a2,s0,-81
    80000216:	85d2                	mv	a1,s4
    80000218:	8556                	mv	a0,s5
    8000021a:	00002097          	auipc	ra,0x2
    8000021e:	344080e7          	jalr	836(ra) # 8000255e <either_copyout>
    80000222:	57fd                	li	a5,-1
    80000224:	04f50a63          	beq	a0,a5,80000278 <consoleread+0x10a>
      break;

    dst++;
    80000228:	0a05                	addi	s4,s4,1
    --n;
    8000022a:	39fd                	addiw	s3,s3,-1

    if(c == '\n'){
    8000022c:	47a9                	li	a5,10
    8000022e:	06fb8163          	beq	s7,a5,80000290 <consoleread+0x122>
    80000232:	6be2                	ld	s7,24(sp)
    80000234:	bfa5                	j	800001ac <consoleread+0x3e>
        release(&cons.lock);
    80000236:	00013517          	auipc	a0,0x13
    8000023a:	15a50513          	addi	a0,a0,346 # 80013390 <cons>
    8000023e:	00001097          	auipc	ra,0x1
    80000242:	af6080e7          	jalr	-1290(ra) # 80000d34 <release>
        return -1;
    80000246:	557d                	li	a0,-1
    }
  }
  release(&cons.lock);

  return target - n;
}
    80000248:	60e6                	ld	ra,88(sp)
    8000024a:	6446                	ld	s0,80(sp)
    8000024c:	64a6                	ld	s1,72(sp)
    8000024e:	6906                	ld	s2,64(sp)
    80000250:	79e2                	ld	s3,56(sp)
    80000252:	7a42                	ld	s4,48(sp)
    80000254:	7aa2                	ld	s5,40(sp)
    80000256:	7b02                	ld	s6,32(sp)
    80000258:	6125                	addi	sp,sp,96
    8000025a:	8082                	ret
      if(n < target){
    8000025c:	0009871b          	sext.w	a4,s3
    80000260:	01677a63          	bgeu	a4,s6,80000274 <consoleread+0x106>
        cons.r--;
    80000264:	00013717          	auipc	a4,0x13
    80000268:	1cf72223          	sw	a5,452(a4) # 80013428 <cons+0x98>
    8000026c:	6be2                	ld	s7,24(sp)
    8000026e:	a031                	j	8000027a <consoleread+0x10c>
    80000270:	ec5e                	sd	s7,24(sp)
    80000272:	bf9d                	j	800001e8 <consoleread+0x7a>
    80000274:	6be2                	ld	s7,24(sp)
    80000276:	a011                	j	8000027a <consoleread+0x10c>
    80000278:	6be2                	ld	s7,24(sp)
  release(&cons.lock);
    8000027a:	00013517          	auipc	a0,0x13
    8000027e:	11650513          	addi	a0,a0,278 # 80013390 <cons>
    80000282:	00001097          	auipc	ra,0x1
    80000286:	ab2080e7          	jalr	-1358(ra) # 80000d34 <release>
  return target - n;
    8000028a:	413b053b          	subw	a0,s6,s3
    8000028e:	bf6d                	j	80000248 <consoleread+0xda>
    80000290:	6be2                	ld	s7,24(sp)
    80000292:	b7e5                	j	8000027a <consoleread+0x10c>

0000000080000294 <consputc>:
{
    80000294:	1141                	addi	sp,sp,-16
    80000296:	e406                	sd	ra,8(sp)
    80000298:	e022                	sd	s0,0(sp)
    8000029a:	0800                	addi	s0,sp,16
  if(c == BACKSPACE){
    8000029c:	10000793          	li	a5,256
    800002a0:	00f50a63          	beq	a0,a5,800002b4 <consputc+0x20>
    uartputc_sync(c);
    800002a4:	00000097          	auipc	ra,0x0
    800002a8:	59c080e7          	jalr	1436(ra) # 80000840 <uartputc_sync>
}
    800002ac:	60a2                	ld	ra,8(sp)
    800002ae:	6402                	ld	s0,0(sp)
    800002b0:	0141                	addi	sp,sp,16
    800002b2:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    800002b4:	4521                	li	a0,8
    800002b6:	00000097          	auipc	ra,0x0
    800002ba:	58a080e7          	jalr	1418(ra) # 80000840 <uartputc_sync>
    800002be:	02000513          	li	a0,32
    800002c2:	00000097          	auipc	ra,0x0
    800002c6:	57e080e7          	jalr	1406(ra) # 80000840 <uartputc_sync>
    800002ca:	4521                	li	a0,8
    800002cc:	00000097          	auipc	ra,0x0
    800002d0:	574080e7          	jalr	1396(ra) # 80000840 <uartputc_sync>
    800002d4:	bfe1                	j	800002ac <consputc+0x18>

00000000800002d6 <consoleintr>:
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
    800002d6:	1101                	addi	sp,sp,-32
    800002d8:	ec06                	sd	ra,24(sp)
    800002da:	e822                	sd	s0,16(sp)
    800002dc:	e426                	sd	s1,8(sp)
    800002de:	1000                	addi	s0,sp,32
    800002e0:	84aa                	mv	s1,a0
  acquire(&cons.lock);
    800002e2:	00013517          	auipc	a0,0x13
    800002e6:	0ae50513          	addi	a0,a0,174 # 80013390 <cons>
    800002ea:	00001097          	auipc	ra,0x1
    800002ee:	996080e7          	jalr	-1642(ra) # 80000c80 <acquire>

  switch(c){
    800002f2:	47d5                	li	a5,21
    800002f4:	0af48563          	beq	s1,a5,8000039e <consoleintr+0xc8>
    800002f8:	0297c963          	blt	a5,s1,8000032a <consoleintr+0x54>
    800002fc:	47a1                	li	a5,8
    800002fe:	0ef48c63          	beq	s1,a5,800003f6 <consoleintr+0x120>
    80000302:	47c1                	li	a5,16
    80000304:	10f49f63          	bne	s1,a5,80000422 <consoleintr+0x14c>
  case C('P'):  // Print process list.
    procdump();
    80000308:	00002097          	auipc	ra,0x2
    8000030c:	302080e7          	jalr	770(ra) # 8000260a <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    80000310:	00013517          	auipc	a0,0x13
    80000314:	08050513          	addi	a0,a0,128 # 80013390 <cons>
    80000318:	00001097          	auipc	ra,0x1
    8000031c:	a1c080e7          	jalr	-1508(ra) # 80000d34 <release>
}
    80000320:	60e2                	ld	ra,24(sp)
    80000322:	6442                	ld	s0,16(sp)
    80000324:	64a2                	ld	s1,8(sp)
    80000326:	6105                	addi	sp,sp,32
    80000328:	8082                	ret
  switch(c){
    8000032a:	07f00793          	li	a5,127
    8000032e:	0cf48463          	beq	s1,a5,800003f6 <consoleintr+0x120>
    if(c != 0 && cons.e-cons.r < INPUT_BUF_SIZE){
    80000332:	00013717          	auipc	a4,0x13
    80000336:	05e70713          	addi	a4,a4,94 # 80013390 <cons>
    8000033a:	0a072783          	lw	a5,160(a4)
    8000033e:	09872703          	lw	a4,152(a4)
    80000342:	9f99                	subw	a5,a5,a4
    80000344:	07f00713          	li	a4,127
    80000348:	fcf764e3          	bltu	a4,a5,80000310 <consoleintr+0x3a>
      c = (c == '\r') ? '\n' : c;
    8000034c:	47b5                	li	a5,13
    8000034e:	0cf48d63          	beq	s1,a5,80000428 <consoleintr+0x152>
      consputc(c);
    80000352:	8526                	mv	a0,s1
    80000354:	00000097          	auipc	ra,0x0
    80000358:	f40080e7          	jalr	-192(ra) # 80000294 <consputc>
      cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    8000035c:	00013797          	auipc	a5,0x13
    80000360:	03478793          	addi	a5,a5,52 # 80013390 <cons>
    80000364:	0a07a683          	lw	a3,160(a5)
    80000368:	0016871b          	addiw	a4,a3,1
    8000036c:	0007061b          	sext.w	a2,a4
    80000370:	0ae7a023          	sw	a4,160(a5)
    80000374:	07f6f693          	andi	a3,a3,127
    80000378:	97b6                	add	a5,a5,a3
    8000037a:	00978c23          	sb	s1,24(a5)
      if(c == '\n' || c == C('D') || cons.e-cons.r == INPUT_BUF_SIZE){
    8000037e:	47a9                	li	a5,10
    80000380:	0cf48b63          	beq	s1,a5,80000456 <consoleintr+0x180>
    80000384:	4791                	li	a5,4
    80000386:	0cf48863          	beq	s1,a5,80000456 <consoleintr+0x180>
    8000038a:	00013797          	auipc	a5,0x13
    8000038e:	09e7a783          	lw	a5,158(a5) # 80013428 <cons+0x98>
    80000392:	9f1d                	subw	a4,a4,a5
    80000394:	08000793          	li	a5,128
    80000398:	f6f71ce3          	bne	a4,a5,80000310 <consoleintr+0x3a>
    8000039c:	a86d                	j	80000456 <consoleintr+0x180>
    8000039e:	e04a                	sd	s2,0(sp)
    while(cons.e != cons.w &&
    800003a0:	00013717          	auipc	a4,0x13
    800003a4:	ff070713          	addi	a4,a4,-16 # 80013390 <cons>
    800003a8:	0a072783          	lw	a5,160(a4)
    800003ac:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    800003b0:	00013497          	auipc	s1,0x13
    800003b4:	fe048493          	addi	s1,s1,-32 # 80013390 <cons>
    while(cons.e != cons.w &&
    800003b8:	4929                	li	s2,10
    800003ba:	02f70a63          	beq	a4,a5,800003ee <consoleintr+0x118>
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    800003be:	37fd                	addiw	a5,a5,-1
    800003c0:	07f7f713          	andi	a4,a5,127
    800003c4:	9726                	add	a4,a4,s1
    while(cons.e != cons.w &&
    800003c6:	01874703          	lbu	a4,24(a4)
    800003ca:	03270463          	beq	a4,s2,800003f2 <consoleintr+0x11c>
      cons.e--;
    800003ce:	0af4a023          	sw	a5,160(s1)
      consputc(BACKSPACE);
    800003d2:	10000513          	li	a0,256
    800003d6:	00000097          	auipc	ra,0x0
    800003da:	ebe080e7          	jalr	-322(ra) # 80000294 <consputc>
    while(cons.e != cons.w &&
    800003de:	0a04a783          	lw	a5,160(s1)
    800003e2:	09c4a703          	lw	a4,156(s1)
    800003e6:	fcf71ce3          	bne	a4,a5,800003be <consoleintr+0xe8>
    800003ea:	6902                	ld	s2,0(sp)
    800003ec:	b715                	j	80000310 <consoleintr+0x3a>
    800003ee:	6902                	ld	s2,0(sp)
    800003f0:	b705                	j	80000310 <consoleintr+0x3a>
    800003f2:	6902                	ld	s2,0(sp)
    800003f4:	bf31                	j	80000310 <consoleintr+0x3a>
    if(cons.e != cons.w){
    800003f6:	00013717          	auipc	a4,0x13
    800003fa:	f9a70713          	addi	a4,a4,-102 # 80013390 <cons>
    800003fe:	0a072783          	lw	a5,160(a4)
    80000402:	09c72703          	lw	a4,156(a4)
    80000406:	f0f705e3          	beq	a4,a5,80000310 <consoleintr+0x3a>
      cons.e--;
    8000040a:	37fd                	addiw	a5,a5,-1
    8000040c:	00013717          	auipc	a4,0x13
    80000410:	02f72223          	sw	a5,36(a4) # 80013430 <cons+0xa0>
      consputc(BACKSPACE);
    80000414:	10000513          	li	a0,256
    80000418:	00000097          	auipc	ra,0x0
    8000041c:	e7c080e7          	jalr	-388(ra) # 80000294 <consputc>
    80000420:	bdc5                	j	80000310 <consoleintr+0x3a>
    if(c != 0 && cons.e-cons.r < INPUT_BUF_SIZE){
    80000422:	ee0487e3          	beqz	s1,80000310 <consoleintr+0x3a>
    80000426:	b731                	j	80000332 <consoleintr+0x5c>
      consputc(c);
    80000428:	4529                	li	a0,10
    8000042a:	00000097          	auipc	ra,0x0
    8000042e:	e6a080e7          	jalr	-406(ra) # 80000294 <consputc>
      cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    80000432:	00013797          	auipc	a5,0x13
    80000436:	f5e78793          	addi	a5,a5,-162 # 80013390 <cons>
    8000043a:	0a07a703          	lw	a4,160(a5)
    8000043e:	0017069b          	addiw	a3,a4,1
    80000442:	0006861b          	sext.w	a2,a3
    80000446:	0ad7a023          	sw	a3,160(a5)
    8000044a:	07f77713          	andi	a4,a4,127
    8000044e:	97ba                	add	a5,a5,a4
    80000450:	4729                	li	a4,10
    80000452:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    80000456:	00013797          	auipc	a5,0x13
    8000045a:	fcc7ab23          	sw	a2,-42(a5) # 8001342c <cons+0x9c>
        wakeup(&cons.r);
    8000045e:	00013517          	auipc	a0,0x13
    80000462:	fca50513          	addi	a0,a0,-54 # 80013428 <cons+0x98>
    80000466:	00002097          	auipc	ra,0x2
    8000046a:	d54080e7          	jalr	-684(ra) # 800021ba <wakeup>
    8000046e:	b54d                	j	80000310 <consoleintr+0x3a>

0000000080000470 <consoleinit>:

void
consoleinit(void)
{
    80000470:	1141                	addi	sp,sp,-16
    80000472:	e406                	sd	ra,8(sp)
    80000474:	e022                	sd	s0,0(sp)
    80000476:	0800                	addi	s0,sp,16
  initlock(&cons.lock, "cons");
    80000478:	00008597          	auipc	a1,0x8
    8000047c:	b8858593          	addi	a1,a1,-1144 # 80008000 <etext>
    80000480:	00013517          	auipc	a0,0x13
    80000484:	f1050513          	addi	a0,a0,-240 # 80013390 <cons>
    80000488:	00000097          	auipc	ra,0x0
    8000048c:	768080e7          	jalr	1896(ra) # 80000bf0 <initlock>

  uartinit();
    80000490:	00000097          	auipc	ra,0x0
    80000494:	354080e7          	jalr	852(ra) # 800007e4 <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000498:	00023797          	auipc	a5,0x23
    8000049c:	09078793          	addi	a5,a5,144 # 80023528 <devsw>
    800004a0:	00000717          	auipc	a4,0x0
    800004a4:	cce70713          	addi	a4,a4,-818 # 8000016e <consoleread>
    800004a8:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    800004aa:	00000717          	auipc	a4,0x0
    800004ae:	c5670713          	addi	a4,a4,-938 # 80000100 <consolewrite>
    800004b2:	ef98                	sd	a4,24(a5)
}
    800004b4:	60a2                	ld	ra,8(sp)
    800004b6:	6402                	ld	s0,0(sp)
    800004b8:	0141                	addi	sp,sp,16
    800004ba:	8082                	ret

00000000800004bc <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    800004bc:	7179                	addi	sp,sp,-48
    800004be:	f406                	sd	ra,40(sp)
    800004c0:	f022                	sd	s0,32(sp)
    800004c2:	1800                	addi	s0,sp,48
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    800004c4:	c219                	beqz	a2,800004ca <printint+0xe>
    800004c6:	08054963          	bltz	a0,80000558 <printint+0x9c>
    x = -xx;
  else
    x = xx;
    800004ca:	2501                	sext.w	a0,a0
    800004cc:	4881                	li	a7,0
    800004ce:	fd040693          	addi	a3,s0,-48

  i = 0;
    800004d2:	4701                	li	a4,0
  do {
    buf[i++] = digits[x % base];
    800004d4:	2581                	sext.w	a1,a1
    800004d6:	00008617          	auipc	a2,0x8
    800004da:	27260613          	addi	a2,a2,626 # 80008748 <digits>
    800004de:	883a                	mv	a6,a4
    800004e0:	2705                	addiw	a4,a4,1
    800004e2:	02b577bb          	remuw	a5,a0,a1
    800004e6:	1782                	slli	a5,a5,0x20
    800004e8:	9381                	srli	a5,a5,0x20
    800004ea:	97b2                	add	a5,a5,a2
    800004ec:	0007c783          	lbu	a5,0(a5)
    800004f0:	00f68023          	sb	a5,0(a3)
  } while((x /= base) != 0);
    800004f4:	0005079b          	sext.w	a5,a0
    800004f8:	02b5553b          	divuw	a0,a0,a1
    800004fc:	0685                	addi	a3,a3,1
    800004fe:	feb7f0e3          	bgeu	a5,a1,800004de <printint+0x22>

  if(sign)
    80000502:	00088c63          	beqz	a7,8000051a <printint+0x5e>
    buf[i++] = '-';
    80000506:	fe070793          	addi	a5,a4,-32
    8000050a:	00878733          	add	a4,a5,s0
    8000050e:	02d00793          	li	a5,45
    80000512:	fef70823          	sb	a5,-16(a4)
    80000516:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
    8000051a:	02e05b63          	blez	a4,80000550 <printint+0x94>
    8000051e:	ec26                	sd	s1,24(sp)
    80000520:	e84a                	sd	s2,16(sp)
    80000522:	fd040793          	addi	a5,s0,-48
    80000526:	00e784b3          	add	s1,a5,a4
    8000052a:	fff78913          	addi	s2,a5,-1
    8000052e:	993a                	add	s2,s2,a4
    80000530:	377d                	addiw	a4,a4,-1
    80000532:	1702                	slli	a4,a4,0x20
    80000534:	9301                	srli	a4,a4,0x20
    80000536:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    8000053a:	fff4c503          	lbu	a0,-1(s1)
    8000053e:	00000097          	auipc	ra,0x0
    80000542:	d56080e7          	jalr	-682(ra) # 80000294 <consputc>
  while(--i >= 0)
    80000546:	14fd                	addi	s1,s1,-1
    80000548:	ff2499e3          	bne	s1,s2,8000053a <printint+0x7e>
    8000054c:	64e2                	ld	s1,24(sp)
    8000054e:	6942                	ld	s2,16(sp)
}
    80000550:	70a2                	ld	ra,40(sp)
    80000552:	7402                	ld	s0,32(sp)
    80000554:	6145                	addi	sp,sp,48
    80000556:	8082                	ret
    x = -xx;
    80000558:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    8000055c:	4885                	li	a7,1
    x = -xx;
    8000055e:	bf85                	j	800004ce <printint+0x12>

0000000080000560 <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
    80000560:	1101                	addi	sp,sp,-32
    80000562:	ec06                	sd	ra,24(sp)
    80000564:	e822                	sd	s0,16(sp)
    80000566:	e426                	sd	s1,8(sp)
    80000568:	1000                	addi	s0,sp,32
    8000056a:	84aa                	mv	s1,a0
  pr.locking = 0;
    8000056c:	00013797          	auipc	a5,0x13
    80000570:	ee07a223          	sw	zero,-284(a5) # 80013450 <pr+0x18>
  printf("panic: ");
    80000574:	00008517          	auipc	a0,0x8
    80000578:	a9450513          	addi	a0,a0,-1388 # 80008008 <etext+0x8>
    8000057c:	00000097          	auipc	ra,0x0
    80000580:	02e080e7          	jalr	46(ra) # 800005aa <printf>
  printf(s);
    80000584:	8526                	mv	a0,s1
    80000586:	00000097          	auipc	ra,0x0
    8000058a:	024080e7          	jalr	36(ra) # 800005aa <printf>
  printf("\n");
    8000058e:	00008517          	auipc	a0,0x8
    80000592:	a8250513          	addi	a0,a0,-1406 # 80008010 <etext+0x10>
    80000596:	00000097          	auipc	ra,0x0
    8000059a:	014080e7          	jalr	20(ra) # 800005aa <printf>
  panicked = 1; // freeze uart output from other CPUs
    8000059e:	4785                	li	a5,1
    800005a0:	0000b717          	auipc	a4,0xb
    800005a4:	c6f72823          	sw	a5,-912(a4) # 8000b210 <panicked>
  for(;;)
    800005a8:	a001                	j	800005a8 <panic+0x48>

00000000800005aa <printf>:
{
    800005aa:	7131                	addi	sp,sp,-192
    800005ac:	fc86                	sd	ra,120(sp)
    800005ae:	f8a2                	sd	s0,112(sp)
    800005b0:	e8d2                	sd	s4,80(sp)
    800005b2:	f06a                	sd	s10,32(sp)
    800005b4:	0100                	addi	s0,sp,128
    800005b6:	8a2a                	mv	s4,a0
    800005b8:	e40c                	sd	a1,8(s0)
    800005ba:	e810                	sd	a2,16(s0)
    800005bc:	ec14                	sd	a3,24(s0)
    800005be:	f018                	sd	a4,32(s0)
    800005c0:	f41c                	sd	a5,40(s0)
    800005c2:	03043823          	sd	a6,48(s0)
    800005c6:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    800005ca:	00013d17          	auipc	s10,0x13
    800005ce:	e86d2d03          	lw	s10,-378(s10) # 80013450 <pr+0x18>
  if(locking)
    800005d2:	040d1463          	bnez	s10,8000061a <printf+0x70>
  if (fmt == 0)
    800005d6:	040a0b63          	beqz	s4,8000062c <printf+0x82>
  va_start(ap, fmt);
    800005da:	00840793          	addi	a5,s0,8
    800005de:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800005e2:	000a4503          	lbu	a0,0(s4)
    800005e6:	18050b63          	beqz	a0,8000077c <printf+0x1d2>
    800005ea:	f4a6                	sd	s1,104(sp)
    800005ec:	f0ca                	sd	s2,96(sp)
    800005ee:	ecce                	sd	s3,88(sp)
    800005f0:	e4d6                	sd	s5,72(sp)
    800005f2:	e0da                	sd	s6,64(sp)
    800005f4:	fc5e                	sd	s7,56(sp)
    800005f6:	f862                	sd	s8,48(sp)
    800005f8:	f466                	sd	s9,40(sp)
    800005fa:	ec6e                	sd	s11,24(sp)
    800005fc:	4981                	li	s3,0
    if(c != '%'){
    800005fe:	02500b13          	li	s6,37
    switch(c){
    80000602:	07000b93          	li	s7,112
  consputc('x');
    80000606:	4cc1                	li	s9,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    80000608:	00008a97          	auipc	s5,0x8
    8000060c:	140a8a93          	addi	s5,s5,320 # 80008748 <digits>
    switch(c){
    80000610:	07300c13          	li	s8,115
    80000614:	06400d93          	li	s11,100
    80000618:	a0b1                	j	80000664 <printf+0xba>
    acquire(&pr.lock);
    8000061a:	00013517          	auipc	a0,0x13
    8000061e:	e1e50513          	addi	a0,a0,-482 # 80013438 <pr>
    80000622:	00000097          	auipc	ra,0x0
    80000626:	65e080e7          	jalr	1630(ra) # 80000c80 <acquire>
    8000062a:	b775                	j	800005d6 <printf+0x2c>
    8000062c:	f4a6                	sd	s1,104(sp)
    8000062e:	f0ca                	sd	s2,96(sp)
    80000630:	ecce                	sd	s3,88(sp)
    80000632:	e4d6                	sd	s5,72(sp)
    80000634:	e0da                	sd	s6,64(sp)
    80000636:	fc5e                	sd	s7,56(sp)
    80000638:	f862                	sd	s8,48(sp)
    8000063a:	f466                	sd	s9,40(sp)
    8000063c:	ec6e                	sd	s11,24(sp)
    panic("null fmt");
    8000063e:	00008517          	auipc	a0,0x8
    80000642:	9e250513          	addi	a0,a0,-1566 # 80008020 <etext+0x20>
    80000646:	00000097          	auipc	ra,0x0
    8000064a:	f1a080e7          	jalr	-230(ra) # 80000560 <panic>
      consputc(c);
    8000064e:	00000097          	auipc	ra,0x0
    80000652:	c46080e7          	jalr	-954(ra) # 80000294 <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    80000656:	2985                	addiw	s3,s3,1
    80000658:	013a07b3          	add	a5,s4,s3
    8000065c:	0007c503          	lbu	a0,0(a5)
    80000660:	10050563          	beqz	a0,8000076a <printf+0x1c0>
    if(c != '%'){
    80000664:	ff6515e3          	bne	a0,s6,8000064e <printf+0xa4>
    c = fmt[++i] & 0xff;
    80000668:	2985                	addiw	s3,s3,1
    8000066a:	013a07b3          	add	a5,s4,s3
    8000066e:	0007c783          	lbu	a5,0(a5)
    80000672:	0007849b          	sext.w	s1,a5
    if(c == 0)
    80000676:	10078b63          	beqz	a5,8000078c <printf+0x1e2>
    switch(c){
    8000067a:	05778a63          	beq	a5,s7,800006ce <printf+0x124>
    8000067e:	02fbf663          	bgeu	s7,a5,800006aa <printf+0x100>
    80000682:	09878863          	beq	a5,s8,80000712 <printf+0x168>
    80000686:	07800713          	li	a4,120
    8000068a:	0ce79563          	bne	a5,a4,80000754 <printf+0x1aa>
      printint(va_arg(ap, int), 16, 1);
    8000068e:	f8843783          	ld	a5,-120(s0)
    80000692:	00878713          	addi	a4,a5,8
    80000696:	f8e43423          	sd	a4,-120(s0)
    8000069a:	4605                	li	a2,1
    8000069c:	85e6                	mv	a1,s9
    8000069e:	4388                	lw	a0,0(a5)
    800006a0:	00000097          	auipc	ra,0x0
    800006a4:	e1c080e7          	jalr	-484(ra) # 800004bc <printint>
      break;
    800006a8:	b77d                	j	80000656 <printf+0xac>
    switch(c){
    800006aa:	09678f63          	beq	a5,s6,80000748 <printf+0x19e>
    800006ae:	0bb79363          	bne	a5,s11,80000754 <printf+0x1aa>
      printint(va_arg(ap, int), 10, 1);
    800006b2:	f8843783          	ld	a5,-120(s0)
    800006b6:	00878713          	addi	a4,a5,8
    800006ba:	f8e43423          	sd	a4,-120(s0)
    800006be:	4605                	li	a2,1
    800006c0:	45a9                	li	a1,10
    800006c2:	4388                	lw	a0,0(a5)
    800006c4:	00000097          	auipc	ra,0x0
    800006c8:	df8080e7          	jalr	-520(ra) # 800004bc <printint>
      break;
    800006cc:	b769                	j	80000656 <printf+0xac>
      printptr(va_arg(ap, uint64));
    800006ce:	f8843783          	ld	a5,-120(s0)
    800006d2:	00878713          	addi	a4,a5,8
    800006d6:	f8e43423          	sd	a4,-120(s0)
    800006da:	0007b903          	ld	s2,0(a5)
  consputc('0');
    800006de:	03000513          	li	a0,48
    800006e2:	00000097          	auipc	ra,0x0
    800006e6:	bb2080e7          	jalr	-1102(ra) # 80000294 <consputc>
  consputc('x');
    800006ea:	07800513          	li	a0,120
    800006ee:	00000097          	auipc	ra,0x0
    800006f2:	ba6080e7          	jalr	-1114(ra) # 80000294 <consputc>
    800006f6:	84e6                	mv	s1,s9
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006f8:	03c95793          	srli	a5,s2,0x3c
    800006fc:	97d6                	add	a5,a5,s5
    800006fe:	0007c503          	lbu	a0,0(a5)
    80000702:	00000097          	auipc	ra,0x0
    80000706:	b92080e7          	jalr	-1134(ra) # 80000294 <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    8000070a:	0912                	slli	s2,s2,0x4
    8000070c:	34fd                	addiw	s1,s1,-1
    8000070e:	f4ed                	bnez	s1,800006f8 <printf+0x14e>
    80000710:	b799                	j	80000656 <printf+0xac>
      if((s = va_arg(ap, char*)) == 0)
    80000712:	f8843783          	ld	a5,-120(s0)
    80000716:	00878713          	addi	a4,a5,8
    8000071a:	f8e43423          	sd	a4,-120(s0)
    8000071e:	6384                	ld	s1,0(a5)
    80000720:	cc89                	beqz	s1,8000073a <printf+0x190>
      for(; *s; s++)
    80000722:	0004c503          	lbu	a0,0(s1)
    80000726:	d905                	beqz	a0,80000656 <printf+0xac>
        consputc(*s);
    80000728:	00000097          	auipc	ra,0x0
    8000072c:	b6c080e7          	jalr	-1172(ra) # 80000294 <consputc>
      for(; *s; s++)
    80000730:	0485                	addi	s1,s1,1
    80000732:	0004c503          	lbu	a0,0(s1)
    80000736:	f96d                	bnez	a0,80000728 <printf+0x17e>
    80000738:	bf39                	j	80000656 <printf+0xac>
        s = "(null)";
    8000073a:	00008497          	auipc	s1,0x8
    8000073e:	8de48493          	addi	s1,s1,-1826 # 80008018 <etext+0x18>
      for(; *s; s++)
    80000742:	02800513          	li	a0,40
    80000746:	b7cd                	j	80000728 <printf+0x17e>
      consputc('%');
    80000748:	855a                	mv	a0,s6
    8000074a:	00000097          	auipc	ra,0x0
    8000074e:	b4a080e7          	jalr	-1206(ra) # 80000294 <consputc>
      break;
    80000752:	b711                	j	80000656 <printf+0xac>
      consputc('%');
    80000754:	855a                	mv	a0,s6
    80000756:	00000097          	auipc	ra,0x0
    8000075a:	b3e080e7          	jalr	-1218(ra) # 80000294 <consputc>
      consputc(c);
    8000075e:	8526                	mv	a0,s1
    80000760:	00000097          	auipc	ra,0x0
    80000764:	b34080e7          	jalr	-1228(ra) # 80000294 <consputc>
      break;
    80000768:	b5fd                	j	80000656 <printf+0xac>
    8000076a:	74a6                	ld	s1,104(sp)
    8000076c:	7906                	ld	s2,96(sp)
    8000076e:	69e6                	ld	s3,88(sp)
    80000770:	6aa6                	ld	s5,72(sp)
    80000772:	6b06                	ld	s6,64(sp)
    80000774:	7be2                	ld	s7,56(sp)
    80000776:	7c42                	ld	s8,48(sp)
    80000778:	7ca2                	ld	s9,40(sp)
    8000077a:	6de2                	ld	s11,24(sp)
  if(locking)
    8000077c:	020d1263          	bnez	s10,800007a0 <printf+0x1f6>
}
    80000780:	70e6                	ld	ra,120(sp)
    80000782:	7446                	ld	s0,112(sp)
    80000784:	6a46                	ld	s4,80(sp)
    80000786:	7d02                	ld	s10,32(sp)
    80000788:	6129                	addi	sp,sp,192
    8000078a:	8082                	ret
    8000078c:	74a6                	ld	s1,104(sp)
    8000078e:	7906                	ld	s2,96(sp)
    80000790:	69e6                	ld	s3,88(sp)
    80000792:	6aa6                	ld	s5,72(sp)
    80000794:	6b06                	ld	s6,64(sp)
    80000796:	7be2                	ld	s7,56(sp)
    80000798:	7c42                	ld	s8,48(sp)
    8000079a:	7ca2                	ld	s9,40(sp)
    8000079c:	6de2                	ld	s11,24(sp)
    8000079e:	bff9                	j	8000077c <printf+0x1d2>
    release(&pr.lock);
    800007a0:	00013517          	auipc	a0,0x13
    800007a4:	c9850513          	addi	a0,a0,-872 # 80013438 <pr>
    800007a8:	00000097          	auipc	ra,0x0
    800007ac:	58c080e7          	jalr	1420(ra) # 80000d34 <release>
}
    800007b0:	bfc1                	j	80000780 <printf+0x1d6>

00000000800007b2 <printfinit>:
    ;
}

void
printfinit(void)
{
    800007b2:	1101                	addi	sp,sp,-32
    800007b4:	ec06                	sd	ra,24(sp)
    800007b6:	e822                	sd	s0,16(sp)
    800007b8:	e426                	sd	s1,8(sp)
    800007ba:	1000                	addi	s0,sp,32
  initlock(&pr.lock, "pr");
    800007bc:	00013497          	auipc	s1,0x13
    800007c0:	c7c48493          	addi	s1,s1,-900 # 80013438 <pr>
    800007c4:	00008597          	auipc	a1,0x8
    800007c8:	86c58593          	addi	a1,a1,-1940 # 80008030 <etext+0x30>
    800007cc:	8526                	mv	a0,s1
    800007ce:	00000097          	auipc	ra,0x0
    800007d2:	422080e7          	jalr	1058(ra) # 80000bf0 <initlock>
  pr.locking = 1;
    800007d6:	4785                	li	a5,1
    800007d8:	cc9c                	sw	a5,24(s1)
}
    800007da:	60e2                	ld	ra,24(sp)
    800007dc:	6442                	ld	s0,16(sp)
    800007de:	64a2                	ld	s1,8(sp)
    800007e0:	6105                	addi	sp,sp,32
    800007e2:	8082                	ret

00000000800007e4 <uartinit>:

void uartstart();

void
uartinit(void)
{
    800007e4:	1141                	addi	sp,sp,-16
    800007e6:	e406                	sd	ra,8(sp)
    800007e8:	e022                	sd	s0,0(sp)
    800007ea:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    800007ec:	100007b7          	lui	a5,0x10000
    800007f0:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    800007f4:	10000737          	lui	a4,0x10000
    800007f8:	f8000693          	li	a3,-128
    800007fc:	00d701a3          	sb	a3,3(a4) # 10000003 <_entry-0x6ffffffd>

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    80000800:	468d                	li	a3,3
    80000802:	10000637          	lui	a2,0x10000
    80000806:	00d60023          	sb	a3,0(a2) # 10000000 <_entry-0x70000000>

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    8000080a:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    8000080e:	00d701a3          	sb	a3,3(a4)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    80000812:	10000737          	lui	a4,0x10000
    80000816:	461d                	li	a2,7
    80000818:	00c70123          	sb	a2,2(a4) # 10000002 <_entry-0x6ffffffe>

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    8000081c:	00d780a3          	sb	a3,1(a5)

  initlock(&uart_tx_lock, "uart");
    80000820:	00008597          	auipc	a1,0x8
    80000824:	81858593          	addi	a1,a1,-2024 # 80008038 <etext+0x38>
    80000828:	00013517          	auipc	a0,0x13
    8000082c:	c3050513          	addi	a0,a0,-976 # 80013458 <uart_tx_lock>
    80000830:	00000097          	auipc	ra,0x0
    80000834:	3c0080e7          	jalr	960(ra) # 80000bf0 <initlock>
}
    80000838:	60a2                	ld	ra,8(sp)
    8000083a:	6402                	ld	s0,0(sp)
    8000083c:	0141                	addi	sp,sp,16
    8000083e:	8082                	ret

0000000080000840 <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    80000840:	1101                	addi	sp,sp,-32
    80000842:	ec06                	sd	ra,24(sp)
    80000844:	e822                	sd	s0,16(sp)
    80000846:	e426                	sd	s1,8(sp)
    80000848:	1000                	addi	s0,sp,32
    8000084a:	84aa                	mv	s1,a0
  push_off();
    8000084c:	00000097          	auipc	ra,0x0
    80000850:	3e8080e7          	jalr	1000(ra) # 80000c34 <push_off>

  if(panicked){
    80000854:	0000b797          	auipc	a5,0xb
    80000858:	9bc7a783          	lw	a5,-1604(a5) # 8000b210 <panicked>
    8000085c:	eb85                	bnez	a5,8000088c <uartputc_sync+0x4c>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    8000085e:	10000737          	lui	a4,0x10000
    80000862:	0715                	addi	a4,a4,5 # 10000005 <_entry-0x6ffffffb>
    80000864:	00074783          	lbu	a5,0(a4)
    80000868:	0207f793          	andi	a5,a5,32
    8000086c:	dfe5                	beqz	a5,80000864 <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    8000086e:	0ff4f513          	zext.b	a0,s1
    80000872:	100007b7          	lui	a5,0x10000
    80000876:	00a78023          	sb	a0,0(a5) # 10000000 <_entry-0x70000000>

  pop_off();
    8000087a:	00000097          	auipc	ra,0x0
    8000087e:	45a080e7          	jalr	1114(ra) # 80000cd4 <pop_off>
}
    80000882:	60e2                	ld	ra,24(sp)
    80000884:	6442                	ld	s0,16(sp)
    80000886:	64a2                	ld	s1,8(sp)
    80000888:	6105                	addi	sp,sp,32
    8000088a:	8082                	ret
    for(;;)
    8000088c:	a001                	j	8000088c <uartputc_sync+0x4c>

000000008000088e <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    8000088e:	0000b797          	auipc	a5,0xb
    80000892:	98a7b783          	ld	a5,-1654(a5) # 8000b218 <uart_tx_r>
    80000896:	0000b717          	auipc	a4,0xb
    8000089a:	98a73703          	ld	a4,-1654(a4) # 8000b220 <uart_tx_w>
    8000089e:	06f70f63          	beq	a4,a5,8000091c <uartstart+0x8e>
{
    800008a2:	7139                	addi	sp,sp,-64
    800008a4:	fc06                	sd	ra,56(sp)
    800008a6:	f822                	sd	s0,48(sp)
    800008a8:	f426                	sd	s1,40(sp)
    800008aa:	f04a                	sd	s2,32(sp)
    800008ac:	ec4e                	sd	s3,24(sp)
    800008ae:	e852                	sd	s4,16(sp)
    800008b0:	e456                	sd	s5,8(sp)
    800008b2:	e05a                	sd	s6,0(sp)
    800008b4:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    800008b6:	10000937          	lui	s2,0x10000
    800008ba:	0915                	addi	s2,s2,5 # 10000005 <_entry-0x6ffffffb>
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    800008bc:	00013a97          	auipc	s5,0x13
    800008c0:	b9ca8a93          	addi	s5,s5,-1124 # 80013458 <uart_tx_lock>
    uart_tx_r += 1;
    800008c4:	0000b497          	auipc	s1,0xb
    800008c8:	95448493          	addi	s1,s1,-1708 # 8000b218 <uart_tx_r>
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    
    WriteReg(THR, c);
    800008cc:	10000a37          	lui	s4,0x10000
    if(uart_tx_w == uart_tx_r){
    800008d0:	0000b997          	auipc	s3,0xb
    800008d4:	95098993          	addi	s3,s3,-1712 # 8000b220 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    800008d8:	00094703          	lbu	a4,0(s2)
    800008dc:	02077713          	andi	a4,a4,32
    800008e0:	c705                	beqz	a4,80000908 <uartstart+0x7a>
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    800008e2:	01f7f713          	andi	a4,a5,31
    800008e6:	9756                	add	a4,a4,s5
    800008e8:	01874b03          	lbu	s6,24(a4)
    uart_tx_r += 1;
    800008ec:	0785                	addi	a5,a5,1
    800008ee:	e09c                	sd	a5,0(s1)
    wakeup(&uart_tx_r);
    800008f0:	8526                	mv	a0,s1
    800008f2:	00002097          	auipc	ra,0x2
    800008f6:	8c8080e7          	jalr	-1848(ra) # 800021ba <wakeup>
    WriteReg(THR, c);
    800008fa:	016a0023          	sb	s6,0(s4) # 10000000 <_entry-0x70000000>
    if(uart_tx_w == uart_tx_r){
    800008fe:	609c                	ld	a5,0(s1)
    80000900:	0009b703          	ld	a4,0(s3)
    80000904:	fcf71ae3          	bne	a4,a5,800008d8 <uartstart+0x4a>
  }
}
    80000908:	70e2                	ld	ra,56(sp)
    8000090a:	7442                	ld	s0,48(sp)
    8000090c:	74a2                	ld	s1,40(sp)
    8000090e:	7902                	ld	s2,32(sp)
    80000910:	69e2                	ld	s3,24(sp)
    80000912:	6a42                	ld	s4,16(sp)
    80000914:	6aa2                	ld	s5,8(sp)
    80000916:	6b02                	ld	s6,0(sp)
    80000918:	6121                	addi	sp,sp,64
    8000091a:	8082                	ret
    8000091c:	8082                	ret

000000008000091e <uartputc>:
{
    8000091e:	7179                	addi	sp,sp,-48
    80000920:	f406                	sd	ra,40(sp)
    80000922:	f022                	sd	s0,32(sp)
    80000924:	ec26                	sd	s1,24(sp)
    80000926:	e84a                	sd	s2,16(sp)
    80000928:	e44e                	sd	s3,8(sp)
    8000092a:	e052                	sd	s4,0(sp)
    8000092c:	1800                	addi	s0,sp,48
    8000092e:	8a2a                	mv	s4,a0
  acquire(&uart_tx_lock);
    80000930:	00013517          	auipc	a0,0x13
    80000934:	b2850513          	addi	a0,a0,-1240 # 80013458 <uart_tx_lock>
    80000938:	00000097          	auipc	ra,0x0
    8000093c:	348080e7          	jalr	840(ra) # 80000c80 <acquire>
  if(panicked){
    80000940:	0000b797          	auipc	a5,0xb
    80000944:	8d07a783          	lw	a5,-1840(a5) # 8000b210 <panicked>
    80000948:	e7c9                	bnez	a5,800009d2 <uartputc+0xb4>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    8000094a:	0000b717          	auipc	a4,0xb
    8000094e:	8d673703          	ld	a4,-1834(a4) # 8000b220 <uart_tx_w>
    80000952:	0000b797          	auipc	a5,0xb
    80000956:	8c67b783          	ld	a5,-1850(a5) # 8000b218 <uart_tx_r>
    8000095a:	02078793          	addi	a5,a5,32
    sleep(&uart_tx_r, &uart_tx_lock);
    8000095e:	00013997          	auipc	s3,0x13
    80000962:	afa98993          	addi	s3,s3,-1286 # 80013458 <uart_tx_lock>
    80000966:	0000b497          	auipc	s1,0xb
    8000096a:	8b248493          	addi	s1,s1,-1870 # 8000b218 <uart_tx_r>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    8000096e:	0000b917          	auipc	s2,0xb
    80000972:	8b290913          	addi	s2,s2,-1870 # 8000b220 <uart_tx_w>
    80000976:	00e79f63          	bne	a5,a4,80000994 <uartputc+0x76>
    sleep(&uart_tx_r, &uart_tx_lock);
    8000097a:	85ce                	mv	a1,s3
    8000097c:	8526                	mv	a0,s1
    8000097e:	00001097          	auipc	ra,0x1
    80000982:	7d8080e7          	jalr	2008(ra) # 80002156 <sleep>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000986:	00093703          	ld	a4,0(s2)
    8000098a:	609c                	ld	a5,0(s1)
    8000098c:	02078793          	addi	a5,a5,32
    80000990:	fee785e3          	beq	a5,a4,8000097a <uartputc+0x5c>
  uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000994:	00013497          	auipc	s1,0x13
    80000998:	ac448493          	addi	s1,s1,-1340 # 80013458 <uart_tx_lock>
    8000099c:	01f77793          	andi	a5,a4,31
    800009a0:	97a6                	add	a5,a5,s1
    800009a2:	01478c23          	sb	s4,24(a5)
  uart_tx_w += 1;
    800009a6:	0705                	addi	a4,a4,1
    800009a8:	0000b797          	auipc	a5,0xb
    800009ac:	86e7bc23          	sd	a4,-1928(a5) # 8000b220 <uart_tx_w>
  uartstart();
    800009b0:	00000097          	auipc	ra,0x0
    800009b4:	ede080e7          	jalr	-290(ra) # 8000088e <uartstart>
  release(&uart_tx_lock);
    800009b8:	8526                	mv	a0,s1
    800009ba:	00000097          	auipc	ra,0x0
    800009be:	37a080e7          	jalr	890(ra) # 80000d34 <release>
}
    800009c2:	70a2                	ld	ra,40(sp)
    800009c4:	7402                	ld	s0,32(sp)
    800009c6:	64e2                	ld	s1,24(sp)
    800009c8:	6942                	ld	s2,16(sp)
    800009ca:	69a2                	ld	s3,8(sp)
    800009cc:	6a02                	ld	s4,0(sp)
    800009ce:	6145                	addi	sp,sp,48
    800009d0:	8082                	ret
    for(;;)
    800009d2:	a001                	j	800009d2 <uartputc+0xb4>

00000000800009d4 <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    800009d4:	1141                	addi	sp,sp,-16
    800009d6:	e422                	sd	s0,8(sp)
    800009d8:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    800009da:	100007b7          	lui	a5,0x10000
    800009de:	0795                	addi	a5,a5,5 # 10000005 <_entry-0x6ffffffb>
    800009e0:	0007c783          	lbu	a5,0(a5)
    800009e4:	8b85                	andi	a5,a5,1
    800009e6:	cb81                	beqz	a5,800009f6 <uartgetc+0x22>
    // input data is ready.
    return ReadReg(RHR);
    800009e8:	100007b7          	lui	a5,0x10000
    800009ec:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
  } else {
    return -1;
  }
}
    800009f0:	6422                	ld	s0,8(sp)
    800009f2:	0141                	addi	sp,sp,16
    800009f4:	8082                	ret
    return -1;
    800009f6:	557d                	li	a0,-1
    800009f8:	bfe5                	j	800009f0 <uartgetc+0x1c>

00000000800009fa <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from devintr().
void
uartintr(void)
{
    800009fa:	1101                	addi	sp,sp,-32
    800009fc:	ec06                	sd	ra,24(sp)
    800009fe:	e822                	sd	s0,16(sp)
    80000a00:	e426                	sd	s1,8(sp)
    80000a02:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    80000a04:	54fd                	li	s1,-1
    80000a06:	a029                	j	80000a10 <uartintr+0x16>
      break;
    consoleintr(c);
    80000a08:	00000097          	auipc	ra,0x0
    80000a0c:	8ce080e7          	jalr	-1842(ra) # 800002d6 <consoleintr>
    int c = uartgetc();
    80000a10:	00000097          	auipc	ra,0x0
    80000a14:	fc4080e7          	jalr	-60(ra) # 800009d4 <uartgetc>
    if(c == -1)
    80000a18:	fe9518e3          	bne	a0,s1,80000a08 <uartintr+0xe>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    80000a1c:	00013497          	auipc	s1,0x13
    80000a20:	a3c48493          	addi	s1,s1,-1476 # 80013458 <uart_tx_lock>
    80000a24:	8526                	mv	a0,s1
    80000a26:	00000097          	auipc	ra,0x0
    80000a2a:	25a080e7          	jalr	602(ra) # 80000c80 <acquire>
  uartstart();
    80000a2e:	00000097          	auipc	ra,0x0
    80000a32:	e60080e7          	jalr	-416(ra) # 8000088e <uartstart>
  release(&uart_tx_lock);
    80000a36:	8526                	mv	a0,s1
    80000a38:	00000097          	auipc	ra,0x0
    80000a3c:	2fc080e7          	jalr	764(ra) # 80000d34 <release>
}
    80000a40:	60e2                	ld	ra,24(sp)
    80000a42:	6442                	ld	s0,16(sp)
    80000a44:	64a2                	ld	s1,8(sp)
    80000a46:	6105                	addi	sp,sp,32
    80000a48:	8082                	ret

0000000080000a4a <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    80000a4a:	1101                	addi	sp,sp,-32
    80000a4c:	ec06                	sd	ra,24(sp)
    80000a4e:	e822                	sd	s0,16(sp)
    80000a50:	e426                	sd	s1,8(sp)
    80000a52:	e04a                	sd	s2,0(sp)
    80000a54:	1000                	addi	s0,sp,32
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    80000a56:	03451793          	slli	a5,a0,0x34
    80000a5a:	ebb9                	bnez	a5,80000ab0 <kfree+0x66>
    80000a5c:	84aa                	mv	s1,a0
    80000a5e:	00024797          	auipc	a5,0x24
    80000a62:	c6278793          	addi	a5,a5,-926 # 800246c0 <end>
    80000a66:	04f56563          	bltu	a0,a5,80000ab0 <kfree+0x66>
    80000a6a:	47c5                	li	a5,17
    80000a6c:	07ee                	slli	a5,a5,0x1b
    80000a6e:	04f57163          	bgeu	a0,a5,80000ab0 <kfree+0x66>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    80000a72:	6605                	lui	a2,0x1
    80000a74:	4585                	li	a1,1
    80000a76:	00000097          	auipc	ra,0x0
    80000a7a:	306080e7          	jalr	774(ra) # 80000d7c <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000a7e:	00013917          	auipc	s2,0x13
    80000a82:	a1290913          	addi	s2,s2,-1518 # 80013490 <kmem>
    80000a86:	854a                	mv	a0,s2
    80000a88:	00000097          	auipc	ra,0x0
    80000a8c:	1f8080e7          	jalr	504(ra) # 80000c80 <acquire>
  r->next = kmem.freelist;
    80000a90:	01893783          	ld	a5,24(s2)
    80000a94:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000a96:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000a9a:	854a                	mv	a0,s2
    80000a9c:	00000097          	auipc	ra,0x0
    80000aa0:	298080e7          	jalr	664(ra) # 80000d34 <release>
}
    80000aa4:	60e2                	ld	ra,24(sp)
    80000aa6:	6442                	ld	s0,16(sp)
    80000aa8:	64a2                	ld	s1,8(sp)
    80000aaa:	6902                	ld	s2,0(sp)
    80000aac:	6105                	addi	sp,sp,32
    80000aae:	8082                	ret
    panic("kfree");
    80000ab0:	00007517          	auipc	a0,0x7
    80000ab4:	59050513          	addi	a0,a0,1424 # 80008040 <etext+0x40>
    80000ab8:	00000097          	auipc	ra,0x0
    80000abc:	aa8080e7          	jalr	-1368(ra) # 80000560 <panic>

0000000080000ac0 <freerange>:
{
    80000ac0:	7179                	addi	sp,sp,-48
    80000ac2:	f406                	sd	ra,40(sp)
    80000ac4:	f022                	sd	s0,32(sp)
    80000ac6:	ec26                	sd	s1,24(sp)
    80000ac8:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000aca:	6785                	lui	a5,0x1
    80000acc:	fff78713          	addi	a4,a5,-1 # fff <_entry-0x7ffff001>
    80000ad0:	00e504b3          	add	s1,a0,a4
    80000ad4:	777d                	lui	a4,0xfffff
    80000ad6:	8cf9                	and	s1,s1,a4
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000ad8:	94be                	add	s1,s1,a5
    80000ada:	0295e463          	bltu	a1,s1,80000b02 <freerange+0x42>
    80000ade:	e84a                	sd	s2,16(sp)
    80000ae0:	e44e                	sd	s3,8(sp)
    80000ae2:	e052                	sd	s4,0(sp)
    80000ae4:	892e                	mv	s2,a1
    kfree(p);
    80000ae6:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000ae8:	6985                	lui	s3,0x1
    kfree(p);
    80000aea:	01448533          	add	a0,s1,s4
    80000aee:	00000097          	auipc	ra,0x0
    80000af2:	f5c080e7          	jalr	-164(ra) # 80000a4a <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000af6:	94ce                	add	s1,s1,s3
    80000af8:	fe9979e3          	bgeu	s2,s1,80000aea <freerange+0x2a>
    80000afc:	6942                	ld	s2,16(sp)
    80000afe:	69a2                	ld	s3,8(sp)
    80000b00:	6a02                	ld	s4,0(sp)
}
    80000b02:	70a2                	ld	ra,40(sp)
    80000b04:	7402                	ld	s0,32(sp)
    80000b06:	64e2                	ld	s1,24(sp)
    80000b08:	6145                	addi	sp,sp,48
    80000b0a:	8082                	ret

0000000080000b0c <kinit>:
{
    80000b0c:	1141                	addi	sp,sp,-16
    80000b0e:	e406                	sd	ra,8(sp)
    80000b10:	e022                	sd	s0,0(sp)
    80000b12:	0800                	addi	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000b14:	00007597          	auipc	a1,0x7
    80000b18:	53458593          	addi	a1,a1,1332 # 80008048 <etext+0x48>
    80000b1c:	00013517          	auipc	a0,0x13
    80000b20:	97450513          	addi	a0,a0,-1676 # 80013490 <kmem>
    80000b24:	00000097          	auipc	ra,0x0
    80000b28:	0cc080e7          	jalr	204(ra) # 80000bf0 <initlock>
  freerange(end, (void*)PHYSTOP);
    80000b2c:	45c5                	li	a1,17
    80000b2e:	05ee                	slli	a1,a1,0x1b
    80000b30:	00024517          	auipc	a0,0x24
    80000b34:	b9050513          	addi	a0,a0,-1136 # 800246c0 <end>
    80000b38:	00000097          	auipc	ra,0x0
    80000b3c:	f88080e7          	jalr	-120(ra) # 80000ac0 <freerange>
}
    80000b40:	60a2                	ld	ra,8(sp)
    80000b42:	6402                	ld	s0,0(sp)
    80000b44:	0141                	addi	sp,sp,16
    80000b46:	8082                	ret

0000000080000b48 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000b48:	1101                	addi	sp,sp,-32
    80000b4a:	ec06                	sd	ra,24(sp)
    80000b4c:	e822                	sd	s0,16(sp)
    80000b4e:	e426                	sd	s1,8(sp)
    80000b50:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000b52:	00013497          	auipc	s1,0x13
    80000b56:	93e48493          	addi	s1,s1,-1730 # 80013490 <kmem>
    80000b5a:	8526                	mv	a0,s1
    80000b5c:	00000097          	auipc	ra,0x0
    80000b60:	124080e7          	jalr	292(ra) # 80000c80 <acquire>
  r = kmem.freelist;
    80000b64:	6c84                	ld	s1,24(s1)
  if(r)
    80000b66:	c885                	beqz	s1,80000b96 <kalloc+0x4e>
    kmem.freelist = r->next;
    80000b68:	609c                	ld	a5,0(s1)
    80000b6a:	00013517          	auipc	a0,0x13
    80000b6e:	92650513          	addi	a0,a0,-1754 # 80013490 <kmem>
    80000b72:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000b74:	00000097          	auipc	ra,0x0
    80000b78:	1c0080e7          	jalr	448(ra) # 80000d34 <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000b7c:	6605                	lui	a2,0x1
    80000b7e:	4595                	li	a1,5
    80000b80:	8526                	mv	a0,s1
    80000b82:	00000097          	auipc	ra,0x0
    80000b86:	1fa080e7          	jalr	506(ra) # 80000d7c <memset>
  return (void*)r;
}
    80000b8a:	8526                	mv	a0,s1
    80000b8c:	60e2                	ld	ra,24(sp)
    80000b8e:	6442                	ld	s0,16(sp)
    80000b90:	64a2                	ld	s1,8(sp)
    80000b92:	6105                	addi	sp,sp,32
    80000b94:	8082                	ret
  release(&kmem.lock);
    80000b96:	00013517          	auipc	a0,0x13
    80000b9a:	8fa50513          	addi	a0,a0,-1798 # 80013490 <kmem>
    80000b9e:	00000097          	auipc	ra,0x0
    80000ba2:	196080e7          	jalr	406(ra) # 80000d34 <release>
  if(r)
    80000ba6:	b7d5                	j	80000b8a <kalloc+0x42>

0000000080000ba8 <kfreepages>:

int
kfreepages()
{
    80000ba8:	1101                	addi	sp,sp,-32
    80000baa:	ec06                	sd	ra,24(sp)
    80000bac:	e822                	sd	s0,16(sp)
    80000bae:	e426                	sd	s1,8(sp)
    80000bb0:	1000                	addi	s0,sp,32
    int counter = 0;
    struct run *list;
    acquire(&kmem.lock);
    80000bb2:	00013497          	auipc	s1,0x13
    80000bb6:	8de48493          	addi	s1,s1,-1826 # 80013490 <kmem>
    80000bba:	8526                	mv	a0,s1
    80000bbc:	00000097          	auipc	ra,0x0
    80000bc0:	0c4080e7          	jalr	196(ra) # 80000c80 <acquire>
    list = kmem.freelist;
    80000bc4:	6c9c                	ld	a5,24(s1)
    while (list != 0) {
    80000bc6:	c39d                	beqz	a5,80000bec <kfreepages+0x44>
    int counter = 0;
    80000bc8:	4481                	li	s1,0
        counter += 1;
    80000bca:	2485                	addiw	s1,s1,1
        list = list->next;
    80000bcc:	639c                	ld	a5,0(a5)
    while (list != 0) {
    80000bce:	fff5                	bnez	a5,80000bca <kfreepages+0x22>
    }
    release(&kmem.lock);
    80000bd0:	00013517          	auipc	a0,0x13
    80000bd4:	8c050513          	addi	a0,a0,-1856 # 80013490 <kmem>
    80000bd8:	00000097          	auipc	ra,0x0
    80000bdc:	15c080e7          	jalr	348(ra) # 80000d34 <release>
    return counter;
}
    80000be0:	8526                	mv	a0,s1
    80000be2:	60e2                	ld	ra,24(sp)
    80000be4:	6442                	ld	s0,16(sp)
    80000be6:	64a2                	ld	s1,8(sp)
    80000be8:	6105                	addi	sp,sp,32
    80000bea:	8082                	ret
    int counter = 0;
    80000bec:	4481                	li	s1,0
    80000bee:	b7cd                	j	80000bd0 <kfreepages+0x28>

0000000080000bf0 <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000bf0:	1141                	addi	sp,sp,-16
    80000bf2:	e422                	sd	s0,8(sp)
    80000bf4:	0800                	addi	s0,sp,16
  lk->name = name;
    80000bf6:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000bf8:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000bfc:	00053823          	sd	zero,16(a0)
}
    80000c00:	6422                	ld	s0,8(sp)
    80000c02:	0141                	addi	sp,sp,16
    80000c04:	8082                	ret

0000000080000c06 <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000c06:	411c                	lw	a5,0(a0)
    80000c08:	e399                	bnez	a5,80000c0e <holding+0x8>
    80000c0a:	4501                	li	a0,0
  return r;
}
    80000c0c:	8082                	ret
{
    80000c0e:	1101                	addi	sp,sp,-32
    80000c10:	ec06                	sd	ra,24(sp)
    80000c12:	e822                	sd	s0,16(sp)
    80000c14:	e426                	sd	s1,8(sp)
    80000c16:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000c18:	6904                	ld	s1,16(a0)
    80000c1a:	00001097          	auipc	ra,0x1
    80000c1e:	e76080e7          	jalr	-394(ra) # 80001a90 <mycpu>
    80000c22:	40a48533          	sub	a0,s1,a0
    80000c26:	00153513          	seqz	a0,a0
}
    80000c2a:	60e2                	ld	ra,24(sp)
    80000c2c:	6442                	ld	s0,16(sp)
    80000c2e:	64a2                	ld	s1,8(sp)
    80000c30:	6105                	addi	sp,sp,32
    80000c32:	8082                	ret

0000000080000c34 <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000c34:	1101                	addi	sp,sp,-32
    80000c36:	ec06                	sd	ra,24(sp)
    80000c38:	e822                	sd	s0,16(sp)
    80000c3a:	e426                	sd	s1,8(sp)
    80000c3c:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c3e:	100024f3          	csrr	s1,sstatus
    80000c42:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000c46:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000c48:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000c4c:	00001097          	auipc	ra,0x1
    80000c50:	e44080e7          	jalr	-444(ra) # 80001a90 <mycpu>
    80000c54:	5d3c                	lw	a5,120(a0)
    80000c56:	cf89                	beqz	a5,80000c70 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000c58:	00001097          	auipc	ra,0x1
    80000c5c:	e38080e7          	jalr	-456(ra) # 80001a90 <mycpu>
    80000c60:	5d3c                	lw	a5,120(a0)
    80000c62:	2785                	addiw	a5,a5,1
    80000c64:	dd3c                	sw	a5,120(a0)
}
    80000c66:	60e2                	ld	ra,24(sp)
    80000c68:	6442                	ld	s0,16(sp)
    80000c6a:	64a2                	ld	s1,8(sp)
    80000c6c:	6105                	addi	sp,sp,32
    80000c6e:	8082                	ret
    mycpu()->intena = old;
    80000c70:	00001097          	auipc	ra,0x1
    80000c74:	e20080e7          	jalr	-480(ra) # 80001a90 <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000c78:	8085                	srli	s1,s1,0x1
    80000c7a:	8885                	andi	s1,s1,1
    80000c7c:	dd64                	sw	s1,124(a0)
    80000c7e:	bfe9                	j	80000c58 <push_off+0x24>

0000000080000c80 <acquire>:
{
    80000c80:	1101                	addi	sp,sp,-32
    80000c82:	ec06                	sd	ra,24(sp)
    80000c84:	e822                	sd	s0,16(sp)
    80000c86:	e426                	sd	s1,8(sp)
    80000c88:	1000                	addi	s0,sp,32
    80000c8a:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000c8c:	00000097          	auipc	ra,0x0
    80000c90:	fa8080e7          	jalr	-88(ra) # 80000c34 <push_off>
  if(holding(lk))
    80000c94:	8526                	mv	a0,s1
    80000c96:	00000097          	auipc	ra,0x0
    80000c9a:	f70080e7          	jalr	-144(ra) # 80000c06 <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c9e:	4705                	li	a4,1
  if(holding(lk))
    80000ca0:	e115                	bnez	a0,80000cc4 <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000ca2:	87ba                	mv	a5,a4
    80000ca4:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000ca8:	2781                	sext.w	a5,a5
    80000caa:	ffe5                	bnez	a5,80000ca2 <acquire+0x22>
  __sync_synchronize();
    80000cac:	0330000f          	fence	rw,rw
  lk->cpu = mycpu();
    80000cb0:	00001097          	auipc	ra,0x1
    80000cb4:	de0080e7          	jalr	-544(ra) # 80001a90 <mycpu>
    80000cb8:	e888                	sd	a0,16(s1)
}
    80000cba:	60e2                	ld	ra,24(sp)
    80000cbc:	6442                	ld	s0,16(sp)
    80000cbe:	64a2                	ld	s1,8(sp)
    80000cc0:	6105                	addi	sp,sp,32
    80000cc2:	8082                	ret
    panic("acquire");
    80000cc4:	00007517          	auipc	a0,0x7
    80000cc8:	38c50513          	addi	a0,a0,908 # 80008050 <etext+0x50>
    80000ccc:	00000097          	auipc	ra,0x0
    80000cd0:	894080e7          	jalr	-1900(ra) # 80000560 <panic>

0000000080000cd4 <pop_off>:

void
pop_off(void)
{
    80000cd4:	1141                	addi	sp,sp,-16
    80000cd6:	e406                	sd	ra,8(sp)
    80000cd8:	e022                	sd	s0,0(sp)
    80000cda:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000cdc:	00001097          	auipc	ra,0x1
    80000ce0:	db4080e7          	jalr	-588(ra) # 80001a90 <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000ce4:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000ce8:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000cea:	e78d                	bnez	a5,80000d14 <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000cec:	5d3c                	lw	a5,120(a0)
    80000cee:	02f05b63          	blez	a5,80000d24 <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000cf2:	37fd                	addiw	a5,a5,-1
    80000cf4:	0007871b          	sext.w	a4,a5
    80000cf8:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000cfa:	eb09                	bnez	a4,80000d0c <pop_off+0x38>
    80000cfc:	5d7c                	lw	a5,124(a0)
    80000cfe:	c799                	beqz	a5,80000d0c <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000d00:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000d04:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000d08:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000d0c:	60a2                	ld	ra,8(sp)
    80000d0e:	6402                	ld	s0,0(sp)
    80000d10:	0141                	addi	sp,sp,16
    80000d12:	8082                	ret
    panic("pop_off - interruptible");
    80000d14:	00007517          	auipc	a0,0x7
    80000d18:	34450513          	addi	a0,a0,836 # 80008058 <etext+0x58>
    80000d1c:	00000097          	auipc	ra,0x0
    80000d20:	844080e7          	jalr	-1980(ra) # 80000560 <panic>
    panic("pop_off");
    80000d24:	00007517          	auipc	a0,0x7
    80000d28:	34c50513          	addi	a0,a0,844 # 80008070 <etext+0x70>
    80000d2c:	00000097          	auipc	ra,0x0
    80000d30:	834080e7          	jalr	-1996(ra) # 80000560 <panic>

0000000080000d34 <release>:
{
    80000d34:	1101                	addi	sp,sp,-32
    80000d36:	ec06                	sd	ra,24(sp)
    80000d38:	e822                	sd	s0,16(sp)
    80000d3a:	e426                	sd	s1,8(sp)
    80000d3c:	1000                	addi	s0,sp,32
    80000d3e:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000d40:	00000097          	auipc	ra,0x0
    80000d44:	ec6080e7          	jalr	-314(ra) # 80000c06 <holding>
    80000d48:	c115                	beqz	a0,80000d6c <release+0x38>
  lk->cpu = 0;
    80000d4a:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000d4e:	0330000f          	fence	rw,rw
  __sync_lock_release(&lk->locked);
    80000d52:	0310000f          	fence	rw,w
    80000d56:	0004a023          	sw	zero,0(s1)
  pop_off();
    80000d5a:	00000097          	auipc	ra,0x0
    80000d5e:	f7a080e7          	jalr	-134(ra) # 80000cd4 <pop_off>
}
    80000d62:	60e2                	ld	ra,24(sp)
    80000d64:	6442                	ld	s0,16(sp)
    80000d66:	64a2                	ld	s1,8(sp)
    80000d68:	6105                	addi	sp,sp,32
    80000d6a:	8082                	ret
    panic("release");
    80000d6c:	00007517          	auipc	a0,0x7
    80000d70:	30c50513          	addi	a0,a0,780 # 80008078 <etext+0x78>
    80000d74:	fffff097          	auipc	ra,0xfffff
    80000d78:	7ec080e7          	jalr	2028(ra) # 80000560 <panic>

0000000080000d7c <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000d7c:	1141                	addi	sp,sp,-16
    80000d7e:	e422                	sd	s0,8(sp)
    80000d80:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000d82:	ca19                	beqz	a2,80000d98 <memset+0x1c>
    80000d84:	87aa                	mv	a5,a0
    80000d86:	1602                	slli	a2,a2,0x20
    80000d88:	9201                	srli	a2,a2,0x20
    80000d8a:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
    80000d8e:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000d92:	0785                	addi	a5,a5,1
    80000d94:	fee79de3          	bne	a5,a4,80000d8e <memset+0x12>
  }
  return dst;
}
    80000d98:	6422                	ld	s0,8(sp)
    80000d9a:	0141                	addi	sp,sp,16
    80000d9c:	8082                	ret

0000000080000d9e <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000d9e:	1141                	addi	sp,sp,-16
    80000da0:	e422                	sd	s0,8(sp)
    80000da2:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000da4:	ca05                	beqz	a2,80000dd4 <memcmp+0x36>
    80000da6:	fff6069b          	addiw	a3,a2,-1 # fff <_entry-0x7ffff001>
    80000daa:	1682                	slli	a3,a3,0x20
    80000dac:	9281                	srli	a3,a3,0x20
    80000dae:	0685                	addi	a3,a3,1
    80000db0:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000db2:	00054783          	lbu	a5,0(a0)
    80000db6:	0005c703          	lbu	a4,0(a1)
    80000dba:	00e79863          	bne	a5,a4,80000dca <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000dbe:	0505                	addi	a0,a0,1
    80000dc0:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000dc2:	fed518e3          	bne	a0,a3,80000db2 <memcmp+0x14>
  }

  return 0;
    80000dc6:	4501                	li	a0,0
    80000dc8:	a019                	j	80000dce <memcmp+0x30>
      return *s1 - *s2;
    80000dca:	40e7853b          	subw	a0,a5,a4
}
    80000dce:	6422                	ld	s0,8(sp)
    80000dd0:	0141                	addi	sp,sp,16
    80000dd2:	8082                	ret
  return 0;
    80000dd4:	4501                	li	a0,0
    80000dd6:	bfe5                	j	80000dce <memcmp+0x30>

0000000080000dd8 <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000dd8:	1141                	addi	sp,sp,-16
    80000dda:	e422                	sd	s0,8(sp)
    80000ddc:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  if(n == 0)
    80000dde:	c205                	beqz	a2,80000dfe <memmove+0x26>
    return dst;
  
  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000de0:	02a5e263          	bltu	a1,a0,80000e04 <memmove+0x2c>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000de4:	1602                	slli	a2,a2,0x20
    80000de6:	9201                	srli	a2,a2,0x20
    80000de8:	00c587b3          	add	a5,a1,a2
{
    80000dec:	872a                	mv	a4,a0
      *d++ = *s++;
    80000dee:	0585                	addi	a1,a1,1
    80000df0:	0705                	addi	a4,a4,1 # fffffffffffff001 <end+0xffffffff7ffda941>
    80000df2:	fff5c683          	lbu	a3,-1(a1)
    80000df6:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
    80000dfa:	feb79ae3          	bne	a5,a1,80000dee <memmove+0x16>

  return dst;
}
    80000dfe:	6422                	ld	s0,8(sp)
    80000e00:	0141                	addi	sp,sp,16
    80000e02:	8082                	ret
  if(s < d && s + n > d){
    80000e04:	02061693          	slli	a3,a2,0x20
    80000e08:	9281                	srli	a3,a3,0x20
    80000e0a:	00d58733          	add	a4,a1,a3
    80000e0e:	fce57be3          	bgeu	a0,a4,80000de4 <memmove+0xc>
    d += n;
    80000e12:	96aa                	add	a3,a3,a0
    while(n-- > 0)
    80000e14:	fff6079b          	addiw	a5,a2,-1
    80000e18:	1782                	slli	a5,a5,0x20
    80000e1a:	9381                	srli	a5,a5,0x20
    80000e1c:	fff7c793          	not	a5,a5
    80000e20:	97ba                	add	a5,a5,a4
      *--d = *--s;
    80000e22:	177d                	addi	a4,a4,-1
    80000e24:	16fd                	addi	a3,a3,-1
    80000e26:	00074603          	lbu	a2,0(a4)
    80000e2a:	00c68023          	sb	a2,0(a3)
    while(n-- > 0)
    80000e2e:	fef71ae3          	bne	a4,a5,80000e22 <memmove+0x4a>
    80000e32:	b7f1                	j	80000dfe <memmove+0x26>

0000000080000e34 <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000e34:	1141                	addi	sp,sp,-16
    80000e36:	e406                	sd	ra,8(sp)
    80000e38:	e022                	sd	s0,0(sp)
    80000e3a:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000e3c:	00000097          	auipc	ra,0x0
    80000e40:	f9c080e7          	jalr	-100(ra) # 80000dd8 <memmove>
}
    80000e44:	60a2                	ld	ra,8(sp)
    80000e46:	6402                	ld	s0,0(sp)
    80000e48:	0141                	addi	sp,sp,16
    80000e4a:	8082                	ret

0000000080000e4c <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000e4c:	1141                	addi	sp,sp,-16
    80000e4e:	e422                	sd	s0,8(sp)
    80000e50:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000e52:	ce11                	beqz	a2,80000e6e <strncmp+0x22>
    80000e54:	00054783          	lbu	a5,0(a0)
    80000e58:	cf89                	beqz	a5,80000e72 <strncmp+0x26>
    80000e5a:	0005c703          	lbu	a4,0(a1)
    80000e5e:	00f71a63          	bne	a4,a5,80000e72 <strncmp+0x26>
    n--, p++, q++;
    80000e62:	367d                	addiw	a2,a2,-1
    80000e64:	0505                	addi	a0,a0,1
    80000e66:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000e68:	f675                	bnez	a2,80000e54 <strncmp+0x8>
  if(n == 0)
    return 0;
    80000e6a:	4501                	li	a0,0
    80000e6c:	a801                	j	80000e7c <strncmp+0x30>
    80000e6e:	4501                	li	a0,0
    80000e70:	a031                	j	80000e7c <strncmp+0x30>
  return (uchar)*p - (uchar)*q;
    80000e72:	00054503          	lbu	a0,0(a0)
    80000e76:	0005c783          	lbu	a5,0(a1)
    80000e7a:	9d1d                	subw	a0,a0,a5
}
    80000e7c:	6422                	ld	s0,8(sp)
    80000e7e:	0141                	addi	sp,sp,16
    80000e80:	8082                	ret

0000000080000e82 <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000e82:	1141                	addi	sp,sp,-16
    80000e84:	e422                	sd	s0,8(sp)
    80000e86:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000e88:	87aa                	mv	a5,a0
    80000e8a:	86b2                	mv	a3,a2
    80000e8c:	367d                	addiw	a2,a2,-1
    80000e8e:	02d05563          	blez	a3,80000eb8 <strncpy+0x36>
    80000e92:	0785                	addi	a5,a5,1
    80000e94:	0005c703          	lbu	a4,0(a1)
    80000e98:	fee78fa3          	sb	a4,-1(a5)
    80000e9c:	0585                	addi	a1,a1,1
    80000e9e:	f775                	bnez	a4,80000e8a <strncpy+0x8>
    ;
  while(n-- > 0)
    80000ea0:	873e                	mv	a4,a5
    80000ea2:	9fb5                	addw	a5,a5,a3
    80000ea4:	37fd                	addiw	a5,a5,-1
    80000ea6:	00c05963          	blez	a2,80000eb8 <strncpy+0x36>
    *s++ = 0;
    80000eaa:	0705                	addi	a4,a4,1
    80000eac:	fe070fa3          	sb	zero,-1(a4)
  while(n-- > 0)
    80000eb0:	40e786bb          	subw	a3,a5,a4
    80000eb4:	fed04be3          	bgtz	a3,80000eaa <strncpy+0x28>
  return os;
}
    80000eb8:	6422                	ld	s0,8(sp)
    80000eba:	0141                	addi	sp,sp,16
    80000ebc:	8082                	ret

0000000080000ebe <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000ebe:	1141                	addi	sp,sp,-16
    80000ec0:	e422                	sd	s0,8(sp)
    80000ec2:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000ec4:	02c05363          	blez	a2,80000eea <safestrcpy+0x2c>
    80000ec8:	fff6069b          	addiw	a3,a2,-1
    80000ecc:	1682                	slli	a3,a3,0x20
    80000ece:	9281                	srli	a3,a3,0x20
    80000ed0:	96ae                	add	a3,a3,a1
    80000ed2:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000ed4:	00d58963          	beq	a1,a3,80000ee6 <safestrcpy+0x28>
    80000ed8:	0585                	addi	a1,a1,1
    80000eda:	0785                	addi	a5,a5,1
    80000edc:	fff5c703          	lbu	a4,-1(a1)
    80000ee0:	fee78fa3          	sb	a4,-1(a5)
    80000ee4:	fb65                	bnez	a4,80000ed4 <safestrcpy+0x16>
    ;
  *s = 0;
    80000ee6:	00078023          	sb	zero,0(a5)
  return os;
}
    80000eea:	6422                	ld	s0,8(sp)
    80000eec:	0141                	addi	sp,sp,16
    80000eee:	8082                	ret

0000000080000ef0 <strlen>:

int
strlen(const char *s)
{
    80000ef0:	1141                	addi	sp,sp,-16
    80000ef2:	e422                	sd	s0,8(sp)
    80000ef4:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000ef6:	00054783          	lbu	a5,0(a0)
    80000efa:	cf91                	beqz	a5,80000f16 <strlen+0x26>
    80000efc:	0505                	addi	a0,a0,1
    80000efe:	87aa                	mv	a5,a0
    80000f00:	86be                	mv	a3,a5
    80000f02:	0785                	addi	a5,a5,1
    80000f04:	fff7c703          	lbu	a4,-1(a5)
    80000f08:	ff65                	bnez	a4,80000f00 <strlen+0x10>
    80000f0a:	40a6853b          	subw	a0,a3,a0
    80000f0e:	2505                	addiw	a0,a0,1
    ;
  return n;
}
    80000f10:	6422                	ld	s0,8(sp)
    80000f12:	0141                	addi	sp,sp,16
    80000f14:	8082                	ret
  for(n = 0; s[n]; n++)
    80000f16:	4501                	li	a0,0
    80000f18:	bfe5                	j	80000f10 <strlen+0x20>

0000000080000f1a <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000f1a:	1141                	addi	sp,sp,-16
    80000f1c:	e406                	sd	ra,8(sp)
    80000f1e:	e022                	sd	s0,0(sp)
    80000f20:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000f22:	00001097          	auipc	ra,0x1
    80000f26:	b5e080e7          	jalr	-1186(ra) # 80001a80 <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000f2a:	0000a717          	auipc	a4,0xa
    80000f2e:	2fe70713          	addi	a4,a4,766 # 8000b228 <started>
  if(cpuid() == 0){
    80000f32:	c139                	beqz	a0,80000f78 <main+0x5e>
    while(started == 0)
    80000f34:	431c                	lw	a5,0(a4)
    80000f36:	2781                	sext.w	a5,a5
    80000f38:	dff5                	beqz	a5,80000f34 <main+0x1a>
      ;
    __sync_synchronize();
    80000f3a:	0330000f          	fence	rw,rw
    printf("hart %d starting\n", cpuid());
    80000f3e:	00001097          	auipc	ra,0x1
    80000f42:	b42080e7          	jalr	-1214(ra) # 80001a80 <cpuid>
    80000f46:	85aa                	mv	a1,a0
    80000f48:	00007517          	auipc	a0,0x7
    80000f4c:	17050513          	addi	a0,a0,368 # 800080b8 <etext+0xb8>
    80000f50:	fffff097          	auipc	ra,0xfffff
    80000f54:	65a080e7          	jalr	1626(ra) # 800005aa <printf>
    kvminithart();    // turn on paging
    80000f58:	00000097          	auipc	ra,0x0
    80000f5c:	0f2080e7          	jalr	242(ra) # 8000104a <kvminithart>
    trapinithart();   // install kernel trap vector
    80000f60:	00001097          	auipc	ra,0x1
    80000f64:	7ec080e7          	jalr	2028(ra) # 8000274c <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000f68:	00005097          	auipc	ra,0x5
    80000f6c:	e8c080e7          	jalr	-372(ra) # 80005df4 <plicinithart>
  }

  scheduler();        
    80000f70:	00001097          	auipc	ra,0x1
    80000f74:	034080e7          	jalr	52(ra) # 80001fa4 <scheduler>
    consoleinit();
    80000f78:	fffff097          	auipc	ra,0xfffff
    80000f7c:	4f8080e7          	jalr	1272(ra) # 80000470 <consoleinit>
    printfinit();
    80000f80:	00000097          	auipc	ra,0x0
    80000f84:	832080e7          	jalr	-1998(ra) # 800007b2 <printfinit>
    printf("\n");
    80000f88:	00007517          	auipc	a0,0x7
    80000f8c:	08850513          	addi	a0,a0,136 # 80008010 <etext+0x10>
    80000f90:	fffff097          	auipc	ra,0xfffff
    80000f94:	61a080e7          	jalr	1562(ra) # 800005aa <printf>
    printf("xv6 kernel is booting\n");
    80000f98:	00007517          	auipc	a0,0x7
    80000f9c:	0e850513          	addi	a0,a0,232 # 80008080 <etext+0x80>
    80000fa0:	fffff097          	auipc	ra,0xfffff
    80000fa4:	60a080e7          	jalr	1546(ra) # 800005aa <printf>
    printf("\n");
    80000fa8:	00007517          	auipc	a0,0x7
    80000fac:	06850513          	addi	a0,a0,104 # 80008010 <etext+0x10>
    80000fb0:	fffff097          	auipc	ra,0xfffff
    80000fb4:	5fa080e7          	jalr	1530(ra) # 800005aa <printf>
    kinit();         // physical page allocator
    80000fb8:	00000097          	auipc	ra,0x0
    80000fbc:	b54080e7          	jalr	-1196(ra) # 80000b0c <kinit>
    printf("xv6 free pages before init: %d\n",kfreepages());
    80000fc0:	00000097          	auipc	ra,0x0
    80000fc4:	be8080e7          	jalr	-1048(ra) # 80000ba8 <kfreepages>
    80000fc8:	85aa                	mv	a1,a0
    80000fca:	00007517          	auipc	a0,0x7
    80000fce:	0ce50513          	addi	a0,a0,206 # 80008098 <etext+0x98>
    80000fd2:	fffff097          	auipc	ra,0xfffff
    80000fd6:	5d8080e7          	jalr	1496(ra) # 800005aa <printf>
    kvminit();       // create kernel page table
    80000fda:	00000097          	auipc	ra,0x0
    80000fde:	326080e7          	jalr	806(ra) # 80001300 <kvminit>
    kvminithart();   // turn on paging
    80000fe2:	00000097          	auipc	ra,0x0
    80000fe6:	068080e7          	jalr	104(ra) # 8000104a <kvminithart>
    procinit();      // process table
    80000fea:	00001097          	auipc	ra,0x1
    80000fee:	9d4080e7          	jalr	-1580(ra) # 800019be <procinit>
    trapinit();      // trap vectors
    80000ff2:	00001097          	auipc	ra,0x1
    80000ff6:	732080e7          	jalr	1842(ra) # 80002724 <trapinit>
    trapinithart();  // install kernel trap vector
    80000ffa:	00001097          	auipc	ra,0x1
    80000ffe:	752080e7          	jalr	1874(ra) # 8000274c <trapinithart>
    plicinit();      // set up interrupt controller
    80001002:	00005097          	auipc	ra,0x5
    80001006:	dd8080e7          	jalr	-552(ra) # 80005dda <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    8000100a:	00005097          	auipc	ra,0x5
    8000100e:	dea080e7          	jalr	-534(ra) # 80005df4 <plicinithart>
    binit();         // buffer cache
    80001012:	00002097          	auipc	ra,0x2
    80001016:	eb4080e7          	jalr	-332(ra) # 80002ec6 <binit>
    iinit();         // inode table
    8000101a:	00002097          	auipc	ra,0x2
    8000101e:	56a080e7          	jalr	1386(ra) # 80003584 <iinit>
    fileinit();      // file table
    80001022:	00003097          	auipc	ra,0x3
    80001026:	51a080e7          	jalr	1306(ra) # 8000453c <fileinit>
    virtio_disk_init(); // emulated hard disk
    8000102a:	00005097          	auipc	ra,0x5
    8000102e:	ed2080e7          	jalr	-302(ra) # 80005efc <virtio_disk_init>
    userinit();      // first user process
    80001032:	00001097          	auipc	ra,0x1
    80001036:	d52080e7          	jalr	-686(ra) # 80001d84 <userinit>
    __sync_synchronize();
    8000103a:	0330000f          	fence	rw,rw
    started = 1;
    8000103e:	4785                	li	a5,1
    80001040:	0000a717          	auipc	a4,0xa
    80001044:	1ef72423          	sw	a5,488(a4) # 8000b228 <started>
    80001048:	b725                	j	80000f70 <main+0x56>

000000008000104a <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    8000104a:	1141                	addi	sp,sp,-16
    8000104c:	e422                	sd	s0,8(sp)
    8000104e:	0800                	addi	s0,sp,16
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80001050:	12000073          	sfence.vma
  // wait for any previous writes to the page table memory to finish.
  sfence_vma();

  w_satp(MAKE_SATP(kernel_pagetable));
    80001054:	0000a797          	auipc	a5,0xa
    80001058:	1dc7b783          	ld	a5,476(a5) # 8000b230 <kernel_pagetable>
    8000105c:	83b1                	srli	a5,a5,0xc
    8000105e:	577d                	li	a4,-1
    80001060:	177e                	slli	a4,a4,0x3f
    80001062:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80001064:	18079073          	csrw	satp,a5
  asm volatile("sfence.vma zero, zero");
    80001068:	12000073          	sfence.vma

  // flush stale entries from the TLB.
  sfence_vma();
}
    8000106c:	6422                	ld	s0,8(sp)
    8000106e:	0141                	addi	sp,sp,16
    80001070:	8082                	ret

0000000080001072 <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80001072:	7139                	addi	sp,sp,-64
    80001074:	fc06                	sd	ra,56(sp)
    80001076:	f822                	sd	s0,48(sp)
    80001078:	f426                	sd	s1,40(sp)
    8000107a:	f04a                	sd	s2,32(sp)
    8000107c:	ec4e                	sd	s3,24(sp)
    8000107e:	e852                	sd	s4,16(sp)
    80001080:	e456                	sd	s5,8(sp)
    80001082:	e05a                	sd	s6,0(sp)
    80001084:	0080                	addi	s0,sp,64
    80001086:	84aa                	mv	s1,a0
    80001088:	89ae                	mv	s3,a1
    8000108a:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    8000108c:	57fd                	li	a5,-1
    8000108e:	83e9                	srli	a5,a5,0x1a
    80001090:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80001092:	4b31                	li	s6,12
  if(va >= MAXVA)
    80001094:	04b7f263          	bgeu	a5,a1,800010d8 <walk+0x66>
    panic("walk");
    80001098:	00007517          	auipc	a0,0x7
    8000109c:	03850513          	addi	a0,a0,56 # 800080d0 <etext+0xd0>
    800010a0:	fffff097          	auipc	ra,0xfffff
    800010a4:	4c0080e7          	jalr	1216(ra) # 80000560 <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    800010a8:	060a8663          	beqz	s5,80001114 <walk+0xa2>
    800010ac:	00000097          	auipc	ra,0x0
    800010b0:	a9c080e7          	jalr	-1380(ra) # 80000b48 <kalloc>
    800010b4:	84aa                	mv	s1,a0
    800010b6:	c529                	beqz	a0,80001100 <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    800010b8:	6605                	lui	a2,0x1
    800010ba:	4581                	li	a1,0
    800010bc:	00000097          	auipc	ra,0x0
    800010c0:	cc0080e7          	jalr	-832(ra) # 80000d7c <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    800010c4:	00c4d793          	srli	a5,s1,0xc
    800010c8:	07aa                	slli	a5,a5,0xa
    800010ca:	0017e793          	ori	a5,a5,1
    800010ce:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    800010d2:	3a5d                	addiw	s4,s4,-9 # ffffffffffffeff7 <end+0xffffffff7ffda937>
    800010d4:	036a0063          	beq	s4,s6,800010f4 <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    800010d8:	0149d933          	srl	s2,s3,s4
    800010dc:	1ff97913          	andi	s2,s2,511
    800010e0:	090e                	slli	s2,s2,0x3
    800010e2:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    800010e4:	00093483          	ld	s1,0(s2)
    800010e8:	0014f793          	andi	a5,s1,1
    800010ec:	dfd5                	beqz	a5,800010a8 <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    800010ee:	80a9                	srli	s1,s1,0xa
    800010f0:	04b2                	slli	s1,s1,0xc
    800010f2:	b7c5                	j	800010d2 <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    800010f4:	00c9d513          	srli	a0,s3,0xc
    800010f8:	1ff57513          	andi	a0,a0,511
    800010fc:	050e                	slli	a0,a0,0x3
    800010fe:	9526                	add	a0,a0,s1
}
    80001100:	70e2                	ld	ra,56(sp)
    80001102:	7442                	ld	s0,48(sp)
    80001104:	74a2                	ld	s1,40(sp)
    80001106:	7902                	ld	s2,32(sp)
    80001108:	69e2                	ld	s3,24(sp)
    8000110a:	6a42                	ld	s4,16(sp)
    8000110c:	6aa2                	ld	s5,8(sp)
    8000110e:	6b02                	ld	s6,0(sp)
    80001110:	6121                	addi	sp,sp,64
    80001112:	8082                	ret
        return 0;
    80001114:	4501                	li	a0,0
    80001116:	b7ed                	j	80001100 <walk+0x8e>

0000000080001118 <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    80001118:	57fd                	li	a5,-1
    8000111a:	83e9                	srli	a5,a5,0x1a
    8000111c:	00b7f463          	bgeu	a5,a1,80001124 <walkaddr+0xc>
    return 0;
    80001120:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    80001122:	8082                	ret
{
    80001124:	1141                	addi	sp,sp,-16
    80001126:	e406                	sd	ra,8(sp)
    80001128:	e022                	sd	s0,0(sp)
    8000112a:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    8000112c:	4601                	li	a2,0
    8000112e:	00000097          	auipc	ra,0x0
    80001132:	f44080e7          	jalr	-188(ra) # 80001072 <walk>
  if(pte == 0)
    80001136:	c105                	beqz	a0,80001156 <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    80001138:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    8000113a:	0117f693          	andi	a3,a5,17
    8000113e:	4745                	li	a4,17
    return 0;
    80001140:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    80001142:	00e68663          	beq	a3,a4,8000114e <walkaddr+0x36>
}
    80001146:	60a2                	ld	ra,8(sp)
    80001148:	6402                	ld	s0,0(sp)
    8000114a:	0141                	addi	sp,sp,16
    8000114c:	8082                	ret
  pa = PTE2PA(*pte);
    8000114e:	83a9                	srli	a5,a5,0xa
    80001150:	00c79513          	slli	a0,a5,0xc
  return pa;
    80001154:	bfcd                	j	80001146 <walkaddr+0x2e>
    return 0;
    80001156:	4501                	li	a0,0
    80001158:	b7fd                	j	80001146 <walkaddr+0x2e>

000000008000115a <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    8000115a:	715d                	addi	sp,sp,-80
    8000115c:	e486                	sd	ra,72(sp)
    8000115e:	e0a2                	sd	s0,64(sp)
    80001160:	fc26                	sd	s1,56(sp)
    80001162:	f84a                	sd	s2,48(sp)
    80001164:	f44e                	sd	s3,40(sp)
    80001166:	f052                	sd	s4,32(sp)
    80001168:	ec56                	sd	s5,24(sp)
    8000116a:	e85a                	sd	s6,16(sp)
    8000116c:	e45e                	sd	s7,8(sp)
    8000116e:	0880                	addi	s0,sp,80
  uint64 a, last;
  pte_t *pte;

  if(size == 0)
    80001170:	c639                	beqz	a2,800011be <mappages+0x64>
    80001172:	8aaa                	mv	s5,a0
    80001174:	8b3a                	mv	s6,a4
    panic("mappages: size");
  
  a = PGROUNDDOWN(va);
    80001176:	777d                	lui	a4,0xfffff
    80001178:	00e5f7b3          	and	a5,a1,a4
  last = PGROUNDDOWN(va + size - 1);
    8000117c:	fff58993          	addi	s3,a1,-1
    80001180:	99b2                	add	s3,s3,a2
    80001182:	00e9f9b3          	and	s3,s3,a4
  a = PGROUNDDOWN(va);
    80001186:	893e                	mv	s2,a5
    80001188:	40f68a33          	sub	s4,a3,a5
    if(*pte & PTE_V)
      panic("mappages: remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    8000118c:	6b85                	lui	s7,0x1
    8000118e:	014904b3          	add	s1,s2,s4
    if((pte = walk(pagetable, a, 1)) == 0)
    80001192:	4605                	li	a2,1
    80001194:	85ca                	mv	a1,s2
    80001196:	8556                	mv	a0,s5
    80001198:	00000097          	auipc	ra,0x0
    8000119c:	eda080e7          	jalr	-294(ra) # 80001072 <walk>
    800011a0:	cd1d                	beqz	a0,800011de <mappages+0x84>
    if(*pte & PTE_V)
    800011a2:	611c                	ld	a5,0(a0)
    800011a4:	8b85                	andi	a5,a5,1
    800011a6:	e785                	bnez	a5,800011ce <mappages+0x74>
    *pte = PA2PTE(pa) | perm | PTE_V;
    800011a8:	80b1                	srli	s1,s1,0xc
    800011aa:	04aa                	slli	s1,s1,0xa
    800011ac:	0164e4b3          	or	s1,s1,s6
    800011b0:	0014e493          	ori	s1,s1,1
    800011b4:	e104                	sd	s1,0(a0)
    if(a == last)
    800011b6:	05390063          	beq	s2,s3,800011f6 <mappages+0x9c>
    a += PGSIZE;
    800011ba:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0)
    800011bc:	bfc9                	j	8000118e <mappages+0x34>
    panic("mappages: size");
    800011be:	00007517          	auipc	a0,0x7
    800011c2:	f1a50513          	addi	a0,a0,-230 # 800080d8 <etext+0xd8>
    800011c6:	fffff097          	auipc	ra,0xfffff
    800011ca:	39a080e7          	jalr	922(ra) # 80000560 <panic>
      panic("mappages: remap");
    800011ce:	00007517          	auipc	a0,0x7
    800011d2:	f1a50513          	addi	a0,a0,-230 # 800080e8 <etext+0xe8>
    800011d6:	fffff097          	auipc	ra,0xfffff
    800011da:	38a080e7          	jalr	906(ra) # 80000560 <panic>
      return -1;
    800011de:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    800011e0:	60a6                	ld	ra,72(sp)
    800011e2:	6406                	ld	s0,64(sp)
    800011e4:	74e2                	ld	s1,56(sp)
    800011e6:	7942                	ld	s2,48(sp)
    800011e8:	79a2                	ld	s3,40(sp)
    800011ea:	7a02                	ld	s4,32(sp)
    800011ec:	6ae2                	ld	s5,24(sp)
    800011ee:	6b42                	ld	s6,16(sp)
    800011f0:	6ba2                	ld	s7,8(sp)
    800011f2:	6161                	addi	sp,sp,80
    800011f4:	8082                	ret
  return 0;
    800011f6:	4501                	li	a0,0
    800011f8:	b7e5                	j	800011e0 <mappages+0x86>

00000000800011fa <kvmmap>:
{
    800011fa:	1141                	addi	sp,sp,-16
    800011fc:	e406                	sd	ra,8(sp)
    800011fe:	e022                	sd	s0,0(sp)
    80001200:	0800                	addi	s0,sp,16
    80001202:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    80001204:	86b2                	mv	a3,a2
    80001206:	863e                	mv	a2,a5
    80001208:	00000097          	auipc	ra,0x0
    8000120c:	f52080e7          	jalr	-174(ra) # 8000115a <mappages>
    80001210:	e509                	bnez	a0,8000121a <kvmmap+0x20>
}
    80001212:	60a2                	ld	ra,8(sp)
    80001214:	6402                	ld	s0,0(sp)
    80001216:	0141                	addi	sp,sp,16
    80001218:	8082                	ret
    panic("kvmmap");
    8000121a:	00007517          	auipc	a0,0x7
    8000121e:	ede50513          	addi	a0,a0,-290 # 800080f8 <etext+0xf8>
    80001222:	fffff097          	auipc	ra,0xfffff
    80001226:	33e080e7          	jalr	830(ra) # 80000560 <panic>

000000008000122a <kvmmake>:
{
    8000122a:	1101                	addi	sp,sp,-32
    8000122c:	ec06                	sd	ra,24(sp)
    8000122e:	e822                	sd	s0,16(sp)
    80001230:	e426                	sd	s1,8(sp)
    80001232:	e04a                	sd	s2,0(sp)
    80001234:	1000                	addi	s0,sp,32
  kpgtbl = (pagetable_t) kalloc();
    80001236:	00000097          	auipc	ra,0x0
    8000123a:	912080e7          	jalr	-1774(ra) # 80000b48 <kalloc>
    8000123e:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    80001240:	6605                	lui	a2,0x1
    80001242:	4581                	li	a1,0
    80001244:	00000097          	auipc	ra,0x0
    80001248:	b38080e7          	jalr	-1224(ra) # 80000d7c <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    8000124c:	4719                	li	a4,6
    8000124e:	6685                	lui	a3,0x1
    80001250:	10000637          	lui	a2,0x10000
    80001254:	100005b7          	lui	a1,0x10000
    80001258:	8526                	mv	a0,s1
    8000125a:	00000097          	auipc	ra,0x0
    8000125e:	fa0080e7          	jalr	-96(ra) # 800011fa <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    80001262:	4719                	li	a4,6
    80001264:	6685                	lui	a3,0x1
    80001266:	10001637          	lui	a2,0x10001
    8000126a:	100015b7          	lui	a1,0x10001
    8000126e:	8526                	mv	a0,s1
    80001270:	00000097          	auipc	ra,0x0
    80001274:	f8a080e7          	jalr	-118(ra) # 800011fa <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    80001278:	4719                	li	a4,6
    8000127a:	004006b7          	lui	a3,0x400
    8000127e:	0c000637          	lui	a2,0xc000
    80001282:	0c0005b7          	lui	a1,0xc000
    80001286:	8526                	mv	a0,s1
    80001288:	00000097          	auipc	ra,0x0
    8000128c:	f72080e7          	jalr	-142(ra) # 800011fa <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    80001290:	00007917          	auipc	s2,0x7
    80001294:	d7090913          	addi	s2,s2,-656 # 80008000 <etext>
    80001298:	4729                	li	a4,10
    8000129a:	80007697          	auipc	a3,0x80007
    8000129e:	d6668693          	addi	a3,a3,-666 # 8000 <_entry-0x7fff8000>
    800012a2:	4605                	li	a2,1
    800012a4:	067e                	slli	a2,a2,0x1f
    800012a6:	85b2                	mv	a1,a2
    800012a8:	8526                	mv	a0,s1
    800012aa:	00000097          	auipc	ra,0x0
    800012ae:	f50080e7          	jalr	-176(ra) # 800011fa <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    800012b2:	46c5                	li	a3,17
    800012b4:	06ee                	slli	a3,a3,0x1b
    800012b6:	4719                	li	a4,6
    800012b8:	412686b3          	sub	a3,a3,s2
    800012bc:	864a                	mv	a2,s2
    800012be:	85ca                	mv	a1,s2
    800012c0:	8526                	mv	a0,s1
    800012c2:	00000097          	auipc	ra,0x0
    800012c6:	f38080e7          	jalr	-200(ra) # 800011fa <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    800012ca:	4729                	li	a4,10
    800012cc:	6685                	lui	a3,0x1
    800012ce:	00006617          	auipc	a2,0x6
    800012d2:	d3260613          	addi	a2,a2,-718 # 80007000 <_trampoline>
    800012d6:	040005b7          	lui	a1,0x4000
    800012da:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    800012dc:	05b2                	slli	a1,a1,0xc
    800012de:	8526                	mv	a0,s1
    800012e0:	00000097          	auipc	ra,0x0
    800012e4:	f1a080e7          	jalr	-230(ra) # 800011fa <kvmmap>
  proc_mapstacks(kpgtbl);
    800012e8:	8526                	mv	a0,s1
    800012ea:	00000097          	auipc	ra,0x0
    800012ee:	630080e7          	jalr	1584(ra) # 8000191a <proc_mapstacks>
}
    800012f2:	8526                	mv	a0,s1
    800012f4:	60e2                	ld	ra,24(sp)
    800012f6:	6442                	ld	s0,16(sp)
    800012f8:	64a2                	ld	s1,8(sp)
    800012fa:	6902                	ld	s2,0(sp)
    800012fc:	6105                	addi	sp,sp,32
    800012fe:	8082                	ret

0000000080001300 <kvminit>:
{
    80001300:	1141                	addi	sp,sp,-16
    80001302:	e406                	sd	ra,8(sp)
    80001304:	e022                	sd	s0,0(sp)
    80001306:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    80001308:	00000097          	auipc	ra,0x0
    8000130c:	f22080e7          	jalr	-222(ra) # 8000122a <kvmmake>
    80001310:	0000a797          	auipc	a5,0xa
    80001314:	f2a7b023          	sd	a0,-224(a5) # 8000b230 <kernel_pagetable>
}
    80001318:	60a2                	ld	ra,8(sp)
    8000131a:	6402                	ld	s0,0(sp)
    8000131c:	0141                	addi	sp,sp,16
    8000131e:	8082                	ret

0000000080001320 <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    80001320:	715d                	addi	sp,sp,-80
    80001322:	e486                	sd	ra,72(sp)
    80001324:	e0a2                	sd	s0,64(sp)
    80001326:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    80001328:	03459793          	slli	a5,a1,0x34
    8000132c:	e39d                	bnez	a5,80001352 <uvmunmap+0x32>
    8000132e:	f84a                	sd	s2,48(sp)
    80001330:	f44e                	sd	s3,40(sp)
    80001332:	f052                	sd	s4,32(sp)
    80001334:	ec56                	sd	s5,24(sp)
    80001336:	e85a                	sd	s6,16(sp)
    80001338:	e45e                	sd	s7,8(sp)
    8000133a:	8a2a                	mv	s4,a0
    8000133c:	892e                	mv	s2,a1
    8000133e:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001340:	0632                	slli	a2,a2,0xc
    80001342:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    80001346:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001348:	6b05                	lui	s6,0x1
    8000134a:	0935fb63          	bgeu	a1,s3,800013e0 <uvmunmap+0xc0>
    8000134e:	fc26                	sd	s1,56(sp)
    80001350:	a8a9                	j	800013aa <uvmunmap+0x8a>
    80001352:	fc26                	sd	s1,56(sp)
    80001354:	f84a                	sd	s2,48(sp)
    80001356:	f44e                	sd	s3,40(sp)
    80001358:	f052                	sd	s4,32(sp)
    8000135a:	ec56                	sd	s5,24(sp)
    8000135c:	e85a                	sd	s6,16(sp)
    8000135e:	e45e                	sd	s7,8(sp)
    panic("uvmunmap: not aligned");
    80001360:	00007517          	auipc	a0,0x7
    80001364:	da050513          	addi	a0,a0,-608 # 80008100 <etext+0x100>
    80001368:	fffff097          	auipc	ra,0xfffff
    8000136c:	1f8080e7          	jalr	504(ra) # 80000560 <panic>
      panic("uvmunmap: walk");
    80001370:	00007517          	auipc	a0,0x7
    80001374:	da850513          	addi	a0,a0,-600 # 80008118 <etext+0x118>
    80001378:	fffff097          	auipc	ra,0xfffff
    8000137c:	1e8080e7          	jalr	488(ra) # 80000560 <panic>
      panic("uvmunmap: not mapped");
    80001380:	00007517          	auipc	a0,0x7
    80001384:	da850513          	addi	a0,a0,-600 # 80008128 <etext+0x128>
    80001388:	fffff097          	auipc	ra,0xfffff
    8000138c:	1d8080e7          	jalr	472(ra) # 80000560 <panic>
      panic("uvmunmap: not a leaf");
    80001390:	00007517          	auipc	a0,0x7
    80001394:	db050513          	addi	a0,a0,-592 # 80008140 <etext+0x140>
    80001398:	fffff097          	auipc	ra,0xfffff
    8000139c:	1c8080e7          	jalr	456(ra) # 80000560 <panic>
    if(do_free){
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
    800013a0:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800013a4:	995a                	add	s2,s2,s6
    800013a6:	03397c63          	bgeu	s2,s3,800013de <uvmunmap+0xbe>
    if((pte = walk(pagetable, a, 0)) == 0)
    800013aa:	4601                	li	a2,0
    800013ac:	85ca                	mv	a1,s2
    800013ae:	8552                	mv	a0,s4
    800013b0:	00000097          	auipc	ra,0x0
    800013b4:	cc2080e7          	jalr	-830(ra) # 80001072 <walk>
    800013b8:	84aa                	mv	s1,a0
    800013ba:	d95d                	beqz	a0,80001370 <uvmunmap+0x50>
    if((*pte & PTE_V) == 0)
    800013bc:	6108                	ld	a0,0(a0)
    800013be:	00157793          	andi	a5,a0,1
    800013c2:	dfdd                	beqz	a5,80001380 <uvmunmap+0x60>
    if(PTE_FLAGS(*pte) == PTE_V)
    800013c4:	3ff57793          	andi	a5,a0,1023
    800013c8:	fd7784e3          	beq	a5,s7,80001390 <uvmunmap+0x70>
    if(do_free){
    800013cc:	fc0a8ae3          	beqz	s5,800013a0 <uvmunmap+0x80>
      uint64 pa = PTE2PA(*pte);
    800013d0:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    800013d2:	0532                	slli	a0,a0,0xc
    800013d4:	fffff097          	auipc	ra,0xfffff
    800013d8:	676080e7          	jalr	1654(ra) # 80000a4a <kfree>
    800013dc:	b7d1                	j	800013a0 <uvmunmap+0x80>
    800013de:	74e2                	ld	s1,56(sp)
    800013e0:	7942                	ld	s2,48(sp)
    800013e2:	79a2                	ld	s3,40(sp)
    800013e4:	7a02                	ld	s4,32(sp)
    800013e6:	6ae2                	ld	s5,24(sp)
    800013e8:	6b42                	ld	s6,16(sp)
    800013ea:	6ba2                	ld	s7,8(sp)
  }
}
    800013ec:	60a6                	ld	ra,72(sp)
    800013ee:	6406                	ld	s0,64(sp)
    800013f0:	6161                	addi	sp,sp,80
    800013f2:	8082                	ret

00000000800013f4 <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    800013f4:	1101                	addi	sp,sp,-32
    800013f6:	ec06                	sd	ra,24(sp)
    800013f8:	e822                	sd	s0,16(sp)
    800013fa:	e426                	sd	s1,8(sp)
    800013fc:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    800013fe:	fffff097          	auipc	ra,0xfffff
    80001402:	74a080e7          	jalr	1866(ra) # 80000b48 <kalloc>
    80001406:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001408:	c519                	beqz	a0,80001416 <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    8000140a:	6605                	lui	a2,0x1
    8000140c:	4581                	li	a1,0
    8000140e:	00000097          	auipc	ra,0x0
    80001412:	96e080e7          	jalr	-1682(ra) # 80000d7c <memset>
  return pagetable;
}
    80001416:	8526                	mv	a0,s1
    80001418:	60e2                	ld	ra,24(sp)
    8000141a:	6442                	ld	s0,16(sp)
    8000141c:	64a2                	ld	s1,8(sp)
    8000141e:	6105                	addi	sp,sp,32
    80001420:	8082                	ret

0000000080001422 <uvmfirst>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvmfirst(pagetable_t pagetable, uchar *src, uint sz)
{
    80001422:	7179                	addi	sp,sp,-48
    80001424:	f406                	sd	ra,40(sp)
    80001426:	f022                	sd	s0,32(sp)
    80001428:	ec26                	sd	s1,24(sp)
    8000142a:	e84a                	sd	s2,16(sp)
    8000142c:	e44e                	sd	s3,8(sp)
    8000142e:	e052                	sd	s4,0(sp)
    80001430:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    80001432:	6785                	lui	a5,0x1
    80001434:	04f67863          	bgeu	a2,a5,80001484 <uvmfirst+0x62>
    80001438:	8a2a                	mv	s4,a0
    8000143a:	89ae                	mv	s3,a1
    8000143c:	84b2                	mv	s1,a2
    panic("uvmfirst: more than a page");
  mem = kalloc();
    8000143e:	fffff097          	auipc	ra,0xfffff
    80001442:	70a080e7          	jalr	1802(ra) # 80000b48 <kalloc>
    80001446:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    80001448:	6605                	lui	a2,0x1
    8000144a:	4581                	li	a1,0
    8000144c:	00000097          	auipc	ra,0x0
    80001450:	930080e7          	jalr	-1744(ra) # 80000d7c <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    80001454:	4779                	li	a4,30
    80001456:	86ca                	mv	a3,s2
    80001458:	6605                	lui	a2,0x1
    8000145a:	4581                	li	a1,0
    8000145c:	8552                	mv	a0,s4
    8000145e:	00000097          	auipc	ra,0x0
    80001462:	cfc080e7          	jalr	-772(ra) # 8000115a <mappages>
  memmove(mem, src, sz);
    80001466:	8626                	mv	a2,s1
    80001468:	85ce                	mv	a1,s3
    8000146a:	854a                	mv	a0,s2
    8000146c:	00000097          	auipc	ra,0x0
    80001470:	96c080e7          	jalr	-1684(ra) # 80000dd8 <memmove>
}
    80001474:	70a2                	ld	ra,40(sp)
    80001476:	7402                	ld	s0,32(sp)
    80001478:	64e2                	ld	s1,24(sp)
    8000147a:	6942                	ld	s2,16(sp)
    8000147c:	69a2                	ld	s3,8(sp)
    8000147e:	6a02                	ld	s4,0(sp)
    80001480:	6145                	addi	sp,sp,48
    80001482:	8082                	ret
    panic("uvmfirst: more than a page");
    80001484:	00007517          	auipc	a0,0x7
    80001488:	cd450513          	addi	a0,a0,-812 # 80008158 <etext+0x158>
    8000148c:	fffff097          	auipc	ra,0xfffff
    80001490:	0d4080e7          	jalr	212(ra) # 80000560 <panic>

0000000080001494 <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    80001494:	1101                	addi	sp,sp,-32
    80001496:	ec06                	sd	ra,24(sp)
    80001498:	e822                	sd	s0,16(sp)
    8000149a:	e426                	sd	s1,8(sp)
    8000149c:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    8000149e:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    800014a0:	00b67d63          	bgeu	a2,a1,800014ba <uvmdealloc+0x26>
    800014a4:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    800014a6:	6785                	lui	a5,0x1
    800014a8:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    800014aa:	00f60733          	add	a4,a2,a5
    800014ae:	76fd                	lui	a3,0xfffff
    800014b0:	8f75                	and	a4,a4,a3
    800014b2:	97ae                	add	a5,a5,a1
    800014b4:	8ff5                	and	a5,a5,a3
    800014b6:	00f76863          	bltu	a4,a5,800014c6 <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    800014ba:	8526                	mv	a0,s1
    800014bc:	60e2                	ld	ra,24(sp)
    800014be:	6442                	ld	s0,16(sp)
    800014c0:	64a2                	ld	s1,8(sp)
    800014c2:	6105                	addi	sp,sp,32
    800014c4:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    800014c6:	8f99                	sub	a5,a5,a4
    800014c8:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    800014ca:	4685                	li	a3,1
    800014cc:	0007861b          	sext.w	a2,a5
    800014d0:	85ba                	mv	a1,a4
    800014d2:	00000097          	auipc	ra,0x0
    800014d6:	e4e080e7          	jalr	-434(ra) # 80001320 <uvmunmap>
    800014da:	b7c5                	j	800014ba <uvmdealloc+0x26>

00000000800014dc <uvmalloc>:
  if(newsz < oldsz)
    800014dc:	0ab66b63          	bltu	a2,a1,80001592 <uvmalloc+0xb6>
{
    800014e0:	7139                	addi	sp,sp,-64
    800014e2:	fc06                	sd	ra,56(sp)
    800014e4:	f822                	sd	s0,48(sp)
    800014e6:	ec4e                	sd	s3,24(sp)
    800014e8:	e852                	sd	s4,16(sp)
    800014ea:	e456                	sd	s5,8(sp)
    800014ec:	0080                	addi	s0,sp,64
    800014ee:	8aaa                	mv	s5,a0
    800014f0:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    800014f2:	6785                	lui	a5,0x1
    800014f4:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    800014f6:	95be                	add	a1,a1,a5
    800014f8:	77fd                	lui	a5,0xfffff
    800014fa:	00f5f9b3          	and	s3,a1,a5
  for(a = oldsz; a < newsz; a += PGSIZE){
    800014fe:	08c9fc63          	bgeu	s3,a2,80001596 <uvmalloc+0xba>
    80001502:	f426                	sd	s1,40(sp)
    80001504:	f04a                	sd	s2,32(sp)
    80001506:	e05a                	sd	s6,0(sp)
    80001508:	894e                	mv	s2,s3
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    8000150a:	0126eb13          	ori	s6,a3,18
    mem = kalloc();
    8000150e:	fffff097          	auipc	ra,0xfffff
    80001512:	63a080e7          	jalr	1594(ra) # 80000b48 <kalloc>
    80001516:	84aa                	mv	s1,a0
    if(mem == 0){
    80001518:	c915                	beqz	a0,8000154c <uvmalloc+0x70>
    memset(mem, 0, PGSIZE);
    8000151a:	6605                	lui	a2,0x1
    8000151c:	4581                	li	a1,0
    8000151e:	00000097          	auipc	ra,0x0
    80001522:	85e080e7          	jalr	-1954(ra) # 80000d7c <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    80001526:	875a                	mv	a4,s6
    80001528:	86a6                	mv	a3,s1
    8000152a:	6605                	lui	a2,0x1
    8000152c:	85ca                	mv	a1,s2
    8000152e:	8556                	mv	a0,s5
    80001530:	00000097          	auipc	ra,0x0
    80001534:	c2a080e7          	jalr	-982(ra) # 8000115a <mappages>
    80001538:	ed05                	bnez	a0,80001570 <uvmalloc+0x94>
  for(a = oldsz; a < newsz; a += PGSIZE){
    8000153a:	6785                	lui	a5,0x1
    8000153c:	993e                	add	s2,s2,a5
    8000153e:	fd4968e3          	bltu	s2,s4,8000150e <uvmalloc+0x32>
  return newsz;
    80001542:	8552                	mv	a0,s4
    80001544:	74a2                	ld	s1,40(sp)
    80001546:	7902                	ld	s2,32(sp)
    80001548:	6b02                	ld	s6,0(sp)
    8000154a:	a821                	j	80001562 <uvmalloc+0x86>
      uvmdealloc(pagetable, a, oldsz);
    8000154c:	864e                	mv	a2,s3
    8000154e:	85ca                	mv	a1,s2
    80001550:	8556                	mv	a0,s5
    80001552:	00000097          	auipc	ra,0x0
    80001556:	f42080e7          	jalr	-190(ra) # 80001494 <uvmdealloc>
      return 0;
    8000155a:	4501                	li	a0,0
    8000155c:	74a2                	ld	s1,40(sp)
    8000155e:	7902                	ld	s2,32(sp)
    80001560:	6b02                	ld	s6,0(sp)
}
    80001562:	70e2                	ld	ra,56(sp)
    80001564:	7442                	ld	s0,48(sp)
    80001566:	69e2                	ld	s3,24(sp)
    80001568:	6a42                	ld	s4,16(sp)
    8000156a:	6aa2                	ld	s5,8(sp)
    8000156c:	6121                	addi	sp,sp,64
    8000156e:	8082                	ret
      kfree(mem);
    80001570:	8526                	mv	a0,s1
    80001572:	fffff097          	auipc	ra,0xfffff
    80001576:	4d8080e7          	jalr	1240(ra) # 80000a4a <kfree>
      uvmdealloc(pagetable, a, oldsz);
    8000157a:	864e                	mv	a2,s3
    8000157c:	85ca                	mv	a1,s2
    8000157e:	8556                	mv	a0,s5
    80001580:	00000097          	auipc	ra,0x0
    80001584:	f14080e7          	jalr	-236(ra) # 80001494 <uvmdealloc>
      return 0;
    80001588:	4501                	li	a0,0
    8000158a:	74a2                	ld	s1,40(sp)
    8000158c:	7902                	ld	s2,32(sp)
    8000158e:	6b02                	ld	s6,0(sp)
    80001590:	bfc9                	j	80001562 <uvmalloc+0x86>
    return oldsz;
    80001592:	852e                	mv	a0,a1
}
    80001594:	8082                	ret
  return newsz;
    80001596:	8532                	mv	a0,a2
    80001598:	b7e9                	j	80001562 <uvmalloc+0x86>

000000008000159a <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    8000159a:	7179                	addi	sp,sp,-48
    8000159c:	f406                	sd	ra,40(sp)
    8000159e:	f022                	sd	s0,32(sp)
    800015a0:	ec26                	sd	s1,24(sp)
    800015a2:	e84a                	sd	s2,16(sp)
    800015a4:	e44e                	sd	s3,8(sp)
    800015a6:	e052                	sd	s4,0(sp)
    800015a8:	1800                	addi	s0,sp,48
    800015aa:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    800015ac:	84aa                	mv	s1,a0
    800015ae:	6905                	lui	s2,0x1
    800015b0:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800015b2:	4985                	li	s3,1
    800015b4:	a829                	j	800015ce <freewalk+0x34>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    800015b6:	83a9                	srli	a5,a5,0xa
      freewalk((pagetable_t)child);
    800015b8:	00c79513          	slli	a0,a5,0xc
    800015bc:	00000097          	auipc	ra,0x0
    800015c0:	fde080e7          	jalr	-34(ra) # 8000159a <freewalk>
      pagetable[i] = 0;
    800015c4:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    800015c8:	04a1                	addi	s1,s1,8
    800015ca:	03248163          	beq	s1,s2,800015ec <freewalk+0x52>
    pte_t pte = pagetable[i];
    800015ce:	609c                	ld	a5,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800015d0:	00f7f713          	andi	a4,a5,15
    800015d4:	ff3701e3          	beq	a4,s3,800015b6 <freewalk+0x1c>
    } else if(pte & PTE_V){
    800015d8:	8b85                	andi	a5,a5,1
    800015da:	d7fd                	beqz	a5,800015c8 <freewalk+0x2e>
      panic("freewalk: leaf");
    800015dc:	00007517          	auipc	a0,0x7
    800015e0:	b9c50513          	addi	a0,a0,-1124 # 80008178 <etext+0x178>
    800015e4:	fffff097          	auipc	ra,0xfffff
    800015e8:	f7c080e7          	jalr	-132(ra) # 80000560 <panic>
    }
  }
  kfree((void*)pagetable);
    800015ec:	8552                	mv	a0,s4
    800015ee:	fffff097          	auipc	ra,0xfffff
    800015f2:	45c080e7          	jalr	1116(ra) # 80000a4a <kfree>
}
    800015f6:	70a2                	ld	ra,40(sp)
    800015f8:	7402                	ld	s0,32(sp)
    800015fa:	64e2                	ld	s1,24(sp)
    800015fc:	6942                	ld	s2,16(sp)
    800015fe:	69a2                	ld	s3,8(sp)
    80001600:	6a02                	ld	s4,0(sp)
    80001602:	6145                	addi	sp,sp,48
    80001604:	8082                	ret

0000000080001606 <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    80001606:	1101                	addi	sp,sp,-32
    80001608:	ec06                	sd	ra,24(sp)
    8000160a:	e822                	sd	s0,16(sp)
    8000160c:	e426                	sd	s1,8(sp)
    8000160e:	1000                	addi	s0,sp,32
    80001610:	84aa                	mv	s1,a0
  if(sz > 0)
    80001612:	e999                	bnez	a1,80001628 <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    80001614:	8526                	mv	a0,s1
    80001616:	00000097          	auipc	ra,0x0
    8000161a:	f84080e7          	jalr	-124(ra) # 8000159a <freewalk>
}
    8000161e:	60e2                	ld	ra,24(sp)
    80001620:	6442                	ld	s0,16(sp)
    80001622:	64a2                	ld	s1,8(sp)
    80001624:	6105                	addi	sp,sp,32
    80001626:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    80001628:	6785                	lui	a5,0x1
    8000162a:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    8000162c:	95be                	add	a1,a1,a5
    8000162e:	4685                	li	a3,1
    80001630:	00c5d613          	srli	a2,a1,0xc
    80001634:	4581                	li	a1,0
    80001636:	00000097          	auipc	ra,0x0
    8000163a:	cea080e7          	jalr	-790(ra) # 80001320 <uvmunmap>
    8000163e:	bfd9                	j	80001614 <uvmfree+0xe>

0000000080001640 <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    80001640:	c679                	beqz	a2,8000170e <uvmcopy+0xce>
{
    80001642:	715d                	addi	sp,sp,-80
    80001644:	e486                	sd	ra,72(sp)
    80001646:	e0a2                	sd	s0,64(sp)
    80001648:	fc26                	sd	s1,56(sp)
    8000164a:	f84a                	sd	s2,48(sp)
    8000164c:	f44e                	sd	s3,40(sp)
    8000164e:	f052                	sd	s4,32(sp)
    80001650:	ec56                	sd	s5,24(sp)
    80001652:	e85a                	sd	s6,16(sp)
    80001654:	e45e                	sd	s7,8(sp)
    80001656:	0880                	addi	s0,sp,80
    80001658:	8b2a                	mv	s6,a0
    8000165a:	8aae                	mv	s5,a1
    8000165c:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    8000165e:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    80001660:	4601                	li	a2,0
    80001662:	85ce                	mv	a1,s3
    80001664:	855a                	mv	a0,s6
    80001666:	00000097          	auipc	ra,0x0
    8000166a:	a0c080e7          	jalr	-1524(ra) # 80001072 <walk>
    8000166e:	c531                	beqz	a0,800016ba <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    80001670:	6118                	ld	a4,0(a0)
    80001672:	00177793          	andi	a5,a4,1
    80001676:	cbb1                	beqz	a5,800016ca <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    80001678:	00a75593          	srli	a1,a4,0xa
    8000167c:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    80001680:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    80001684:	fffff097          	auipc	ra,0xfffff
    80001688:	4c4080e7          	jalr	1220(ra) # 80000b48 <kalloc>
    8000168c:	892a                	mv	s2,a0
    8000168e:	c939                	beqz	a0,800016e4 <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    80001690:	6605                	lui	a2,0x1
    80001692:	85de                	mv	a1,s7
    80001694:	fffff097          	auipc	ra,0xfffff
    80001698:	744080e7          	jalr	1860(ra) # 80000dd8 <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    8000169c:	8726                	mv	a4,s1
    8000169e:	86ca                	mv	a3,s2
    800016a0:	6605                	lui	a2,0x1
    800016a2:	85ce                	mv	a1,s3
    800016a4:	8556                	mv	a0,s5
    800016a6:	00000097          	auipc	ra,0x0
    800016aa:	ab4080e7          	jalr	-1356(ra) # 8000115a <mappages>
    800016ae:	e515                	bnez	a0,800016da <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    800016b0:	6785                	lui	a5,0x1
    800016b2:	99be                	add	s3,s3,a5
    800016b4:	fb49e6e3          	bltu	s3,s4,80001660 <uvmcopy+0x20>
    800016b8:	a081                	j	800016f8 <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    800016ba:	00007517          	auipc	a0,0x7
    800016be:	ace50513          	addi	a0,a0,-1330 # 80008188 <etext+0x188>
    800016c2:	fffff097          	auipc	ra,0xfffff
    800016c6:	e9e080e7          	jalr	-354(ra) # 80000560 <panic>
      panic("uvmcopy: page not present");
    800016ca:	00007517          	auipc	a0,0x7
    800016ce:	ade50513          	addi	a0,a0,-1314 # 800081a8 <etext+0x1a8>
    800016d2:	fffff097          	auipc	ra,0xfffff
    800016d6:	e8e080e7          	jalr	-370(ra) # 80000560 <panic>
      kfree(mem);
    800016da:	854a                	mv	a0,s2
    800016dc:	fffff097          	auipc	ra,0xfffff
    800016e0:	36e080e7          	jalr	878(ra) # 80000a4a <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    800016e4:	4685                	li	a3,1
    800016e6:	00c9d613          	srli	a2,s3,0xc
    800016ea:	4581                	li	a1,0
    800016ec:	8556                	mv	a0,s5
    800016ee:	00000097          	auipc	ra,0x0
    800016f2:	c32080e7          	jalr	-974(ra) # 80001320 <uvmunmap>
  return -1;
    800016f6:	557d                	li	a0,-1
}
    800016f8:	60a6                	ld	ra,72(sp)
    800016fa:	6406                	ld	s0,64(sp)
    800016fc:	74e2                	ld	s1,56(sp)
    800016fe:	7942                	ld	s2,48(sp)
    80001700:	79a2                	ld	s3,40(sp)
    80001702:	7a02                	ld	s4,32(sp)
    80001704:	6ae2                	ld	s5,24(sp)
    80001706:	6b42                	ld	s6,16(sp)
    80001708:	6ba2                	ld	s7,8(sp)
    8000170a:	6161                	addi	sp,sp,80
    8000170c:	8082                	ret
  return 0;
    8000170e:	4501                	li	a0,0
}
    80001710:	8082                	ret

0000000080001712 <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    80001712:	1141                	addi	sp,sp,-16
    80001714:	e406                	sd	ra,8(sp)
    80001716:	e022                	sd	s0,0(sp)
    80001718:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    8000171a:	4601                	li	a2,0
    8000171c:	00000097          	auipc	ra,0x0
    80001720:	956080e7          	jalr	-1706(ra) # 80001072 <walk>
  if(pte == 0)
    80001724:	c901                	beqz	a0,80001734 <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    80001726:	611c                	ld	a5,0(a0)
    80001728:	9bbd                	andi	a5,a5,-17
    8000172a:	e11c                	sd	a5,0(a0)
}
    8000172c:	60a2                	ld	ra,8(sp)
    8000172e:	6402                	ld	s0,0(sp)
    80001730:	0141                	addi	sp,sp,16
    80001732:	8082                	ret
    panic("uvmclear");
    80001734:	00007517          	auipc	a0,0x7
    80001738:	a9450513          	addi	a0,a0,-1388 # 800081c8 <etext+0x1c8>
    8000173c:	fffff097          	auipc	ra,0xfffff
    80001740:	e24080e7          	jalr	-476(ra) # 80000560 <panic>

0000000080001744 <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001744:	c6bd                	beqz	a3,800017b2 <copyout+0x6e>
{
    80001746:	715d                	addi	sp,sp,-80
    80001748:	e486                	sd	ra,72(sp)
    8000174a:	e0a2                	sd	s0,64(sp)
    8000174c:	fc26                	sd	s1,56(sp)
    8000174e:	f84a                	sd	s2,48(sp)
    80001750:	f44e                	sd	s3,40(sp)
    80001752:	f052                	sd	s4,32(sp)
    80001754:	ec56                	sd	s5,24(sp)
    80001756:	e85a                	sd	s6,16(sp)
    80001758:	e45e                	sd	s7,8(sp)
    8000175a:	e062                	sd	s8,0(sp)
    8000175c:	0880                	addi	s0,sp,80
    8000175e:	8b2a                	mv	s6,a0
    80001760:	8c2e                	mv	s8,a1
    80001762:	8a32                	mv	s4,a2
    80001764:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    80001766:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    80001768:	6a85                	lui	s5,0x1
    8000176a:	a015                	j	8000178e <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    8000176c:	9562                	add	a0,a0,s8
    8000176e:	0004861b          	sext.w	a2,s1
    80001772:	85d2                	mv	a1,s4
    80001774:	41250533          	sub	a0,a0,s2
    80001778:	fffff097          	auipc	ra,0xfffff
    8000177c:	660080e7          	jalr	1632(ra) # 80000dd8 <memmove>

    len -= n;
    80001780:	409989b3          	sub	s3,s3,s1
    src += n;
    80001784:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    80001786:	01590c33          	add	s8,s2,s5
  while(len > 0){
    8000178a:	02098263          	beqz	s3,800017ae <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    8000178e:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    80001792:	85ca                	mv	a1,s2
    80001794:	855a                	mv	a0,s6
    80001796:	00000097          	auipc	ra,0x0
    8000179a:	982080e7          	jalr	-1662(ra) # 80001118 <walkaddr>
    if(pa0 == 0)
    8000179e:	cd01                	beqz	a0,800017b6 <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    800017a0:	418904b3          	sub	s1,s2,s8
    800017a4:	94d6                	add	s1,s1,s5
    if(n > len)
    800017a6:	fc99f3e3          	bgeu	s3,s1,8000176c <copyout+0x28>
    800017aa:	84ce                	mv	s1,s3
    800017ac:	b7c1                	j	8000176c <copyout+0x28>
  }
  return 0;
    800017ae:	4501                	li	a0,0
    800017b0:	a021                	j	800017b8 <copyout+0x74>
    800017b2:	4501                	li	a0,0
}
    800017b4:	8082                	ret
      return -1;
    800017b6:	557d                	li	a0,-1
}
    800017b8:	60a6                	ld	ra,72(sp)
    800017ba:	6406                	ld	s0,64(sp)
    800017bc:	74e2                	ld	s1,56(sp)
    800017be:	7942                	ld	s2,48(sp)
    800017c0:	79a2                	ld	s3,40(sp)
    800017c2:	7a02                	ld	s4,32(sp)
    800017c4:	6ae2                	ld	s5,24(sp)
    800017c6:	6b42                	ld	s6,16(sp)
    800017c8:	6ba2                	ld	s7,8(sp)
    800017ca:	6c02                	ld	s8,0(sp)
    800017cc:	6161                	addi	sp,sp,80
    800017ce:	8082                	ret

00000000800017d0 <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    800017d0:	caa5                	beqz	a3,80001840 <copyin+0x70>
{
    800017d2:	715d                	addi	sp,sp,-80
    800017d4:	e486                	sd	ra,72(sp)
    800017d6:	e0a2                	sd	s0,64(sp)
    800017d8:	fc26                	sd	s1,56(sp)
    800017da:	f84a                	sd	s2,48(sp)
    800017dc:	f44e                	sd	s3,40(sp)
    800017de:	f052                	sd	s4,32(sp)
    800017e0:	ec56                	sd	s5,24(sp)
    800017e2:	e85a                	sd	s6,16(sp)
    800017e4:	e45e                	sd	s7,8(sp)
    800017e6:	e062                	sd	s8,0(sp)
    800017e8:	0880                	addi	s0,sp,80
    800017ea:	8b2a                	mv	s6,a0
    800017ec:	8a2e                	mv	s4,a1
    800017ee:	8c32                	mv	s8,a2
    800017f0:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    800017f2:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800017f4:	6a85                	lui	s5,0x1
    800017f6:	a01d                	j	8000181c <copyin+0x4c>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    800017f8:	018505b3          	add	a1,a0,s8
    800017fc:	0004861b          	sext.w	a2,s1
    80001800:	412585b3          	sub	a1,a1,s2
    80001804:	8552                	mv	a0,s4
    80001806:	fffff097          	auipc	ra,0xfffff
    8000180a:	5d2080e7          	jalr	1490(ra) # 80000dd8 <memmove>

    len -= n;
    8000180e:	409989b3          	sub	s3,s3,s1
    dst += n;
    80001812:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    80001814:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001818:	02098263          	beqz	s3,8000183c <copyin+0x6c>
    va0 = PGROUNDDOWN(srcva);
    8000181c:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    80001820:	85ca                	mv	a1,s2
    80001822:	855a                	mv	a0,s6
    80001824:	00000097          	auipc	ra,0x0
    80001828:	8f4080e7          	jalr	-1804(ra) # 80001118 <walkaddr>
    if(pa0 == 0)
    8000182c:	cd01                	beqz	a0,80001844 <copyin+0x74>
    n = PGSIZE - (srcva - va0);
    8000182e:	418904b3          	sub	s1,s2,s8
    80001832:	94d6                	add	s1,s1,s5
    if(n > len)
    80001834:	fc99f2e3          	bgeu	s3,s1,800017f8 <copyin+0x28>
    80001838:	84ce                	mv	s1,s3
    8000183a:	bf7d                	j	800017f8 <copyin+0x28>
  }
  return 0;
    8000183c:	4501                	li	a0,0
    8000183e:	a021                	j	80001846 <copyin+0x76>
    80001840:	4501                	li	a0,0
}
    80001842:	8082                	ret
      return -1;
    80001844:	557d                	li	a0,-1
}
    80001846:	60a6                	ld	ra,72(sp)
    80001848:	6406                	ld	s0,64(sp)
    8000184a:	74e2                	ld	s1,56(sp)
    8000184c:	7942                	ld	s2,48(sp)
    8000184e:	79a2                	ld	s3,40(sp)
    80001850:	7a02                	ld	s4,32(sp)
    80001852:	6ae2                	ld	s5,24(sp)
    80001854:	6b42                	ld	s6,16(sp)
    80001856:	6ba2                	ld	s7,8(sp)
    80001858:	6c02                	ld	s8,0(sp)
    8000185a:	6161                	addi	sp,sp,80
    8000185c:	8082                	ret

000000008000185e <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    8000185e:	cacd                	beqz	a3,80001910 <copyinstr+0xb2>
{
    80001860:	715d                	addi	sp,sp,-80
    80001862:	e486                	sd	ra,72(sp)
    80001864:	e0a2                	sd	s0,64(sp)
    80001866:	fc26                	sd	s1,56(sp)
    80001868:	f84a                	sd	s2,48(sp)
    8000186a:	f44e                	sd	s3,40(sp)
    8000186c:	f052                	sd	s4,32(sp)
    8000186e:	ec56                	sd	s5,24(sp)
    80001870:	e85a                	sd	s6,16(sp)
    80001872:	e45e                	sd	s7,8(sp)
    80001874:	0880                	addi	s0,sp,80
    80001876:	8a2a                	mv	s4,a0
    80001878:	8b2e                	mv	s6,a1
    8000187a:	8bb2                	mv	s7,a2
    8000187c:	8936                	mv	s2,a3
    va0 = PGROUNDDOWN(srcva);
    8000187e:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001880:	6985                	lui	s3,0x1
    80001882:	a825                	j	800018ba <copyinstr+0x5c>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    80001884:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    80001888:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    8000188a:	37fd                	addiw	a5,a5,-1
    8000188c:	0007851b          	sext.w	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    80001890:	60a6                	ld	ra,72(sp)
    80001892:	6406                	ld	s0,64(sp)
    80001894:	74e2                	ld	s1,56(sp)
    80001896:	7942                	ld	s2,48(sp)
    80001898:	79a2                	ld	s3,40(sp)
    8000189a:	7a02                	ld	s4,32(sp)
    8000189c:	6ae2                	ld	s5,24(sp)
    8000189e:	6b42                	ld	s6,16(sp)
    800018a0:	6ba2                	ld	s7,8(sp)
    800018a2:	6161                	addi	sp,sp,80
    800018a4:	8082                	ret
    800018a6:	fff90713          	addi	a4,s2,-1 # fff <_entry-0x7ffff001>
    800018aa:	9742                	add	a4,a4,a6
      --max;
    800018ac:	40b70933          	sub	s2,a4,a1
    srcva = va0 + PGSIZE;
    800018b0:	01348bb3          	add	s7,s1,s3
  while(got_null == 0 && max > 0){
    800018b4:	04e58663          	beq	a1,a4,80001900 <copyinstr+0xa2>
{
    800018b8:	8b3e                	mv	s6,a5
    va0 = PGROUNDDOWN(srcva);
    800018ba:	015bf4b3          	and	s1,s7,s5
    pa0 = walkaddr(pagetable, va0);
    800018be:	85a6                	mv	a1,s1
    800018c0:	8552                	mv	a0,s4
    800018c2:	00000097          	auipc	ra,0x0
    800018c6:	856080e7          	jalr	-1962(ra) # 80001118 <walkaddr>
    if(pa0 == 0)
    800018ca:	cd0d                	beqz	a0,80001904 <copyinstr+0xa6>
    n = PGSIZE - (srcva - va0);
    800018cc:	417486b3          	sub	a3,s1,s7
    800018d0:	96ce                	add	a3,a3,s3
    if(n > max)
    800018d2:	00d97363          	bgeu	s2,a3,800018d8 <copyinstr+0x7a>
    800018d6:	86ca                	mv	a3,s2
    char *p = (char *) (pa0 + (srcva - va0));
    800018d8:	955e                	add	a0,a0,s7
    800018da:	8d05                	sub	a0,a0,s1
    while(n > 0){
    800018dc:	c695                	beqz	a3,80001908 <copyinstr+0xaa>
    800018de:	87da                	mv	a5,s6
    800018e0:	885a                	mv	a6,s6
      if(*p == '\0'){
    800018e2:	41650633          	sub	a2,a0,s6
    while(n > 0){
    800018e6:	96da                	add	a3,a3,s6
    800018e8:	85be                	mv	a1,a5
      if(*p == '\0'){
    800018ea:	00f60733          	add	a4,a2,a5
    800018ee:	00074703          	lbu	a4,0(a4) # fffffffffffff000 <end+0xffffffff7ffda940>
    800018f2:	db49                	beqz	a4,80001884 <copyinstr+0x26>
        *dst = *p;
    800018f4:	00e78023          	sb	a4,0(a5)
      dst++;
    800018f8:	0785                	addi	a5,a5,1
    while(n > 0){
    800018fa:	fed797e3          	bne	a5,a3,800018e8 <copyinstr+0x8a>
    800018fe:	b765                	j	800018a6 <copyinstr+0x48>
    80001900:	4781                	li	a5,0
    80001902:	b761                	j	8000188a <copyinstr+0x2c>
      return -1;
    80001904:	557d                	li	a0,-1
    80001906:	b769                	j	80001890 <copyinstr+0x32>
    srcva = va0 + PGSIZE;
    80001908:	6b85                	lui	s7,0x1
    8000190a:	9ba6                	add	s7,s7,s1
    8000190c:	87da                	mv	a5,s6
    8000190e:	b76d                	j	800018b8 <copyinstr+0x5a>
  int got_null = 0;
    80001910:	4781                	li	a5,0
  if(got_null){
    80001912:	37fd                	addiw	a5,a5,-1
    80001914:	0007851b          	sext.w	a0,a5
}
    80001918:	8082                	ret

000000008000191a <proc_mapstacks>:
// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void
proc_mapstacks(pagetable_t kpgtbl)
{
    8000191a:	7139                	addi	sp,sp,-64
    8000191c:	fc06                	sd	ra,56(sp)
    8000191e:	f822                	sd	s0,48(sp)
    80001920:	f426                	sd	s1,40(sp)
    80001922:	f04a                	sd	s2,32(sp)
    80001924:	ec4e                	sd	s3,24(sp)
    80001926:	e852                	sd	s4,16(sp)
    80001928:	e456                	sd	s5,8(sp)
    8000192a:	e05a                	sd	s6,0(sp)
    8000192c:	0080                	addi	s0,sp,64
    8000192e:	8a2a                	mv	s4,a0
  struct proc *p;
  
  for(p = proc; p < &proc[NPROC]; p++) {
    80001930:	00012497          	auipc	s1,0x12
    80001934:	fb048493          	addi	s1,s1,-80 # 800138e0 <proc>
    char *pa = kalloc();
    if(pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int) (p - proc));
    80001938:	8b26                	mv	s6,s1
    8000193a:	04fa5937          	lui	s2,0x4fa5
    8000193e:	fa590913          	addi	s2,s2,-91 # 4fa4fa5 <_entry-0x7b05b05b>
    80001942:	0932                	slli	s2,s2,0xc
    80001944:	fa590913          	addi	s2,s2,-91
    80001948:	0932                	slli	s2,s2,0xc
    8000194a:	fa590913          	addi	s2,s2,-91
    8000194e:	0932                	slli	s2,s2,0xc
    80001950:	fa590913          	addi	s2,s2,-91
    80001954:	040009b7          	lui	s3,0x4000
    80001958:	19fd                	addi	s3,s3,-1 # 3ffffff <_entry-0x7c000001>
    8000195a:	09b2                	slli	s3,s3,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    8000195c:	00018a97          	auipc	s5,0x18
    80001960:	984a8a93          	addi	s5,s5,-1660 # 800192e0 <tickslock>
    char *pa = kalloc();
    80001964:	fffff097          	auipc	ra,0xfffff
    80001968:	1e4080e7          	jalr	484(ra) # 80000b48 <kalloc>
    8000196c:	862a                	mv	a2,a0
    if(pa == 0)
    8000196e:	c121                	beqz	a0,800019ae <proc_mapstacks+0x94>
    uint64 va = KSTACK((int) (p - proc));
    80001970:	416485b3          	sub	a1,s1,s6
    80001974:	858d                	srai	a1,a1,0x3
    80001976:	032585b3          	mul	a1,a1,s2
    8000197a:	2585                	addiw	a1,a1,1
    8000197c:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    80001980:	4719                	li	a4,6
    80001982:	6685                	lui	a3,0x1
    80001984:	40b985b3          	sub	a1,s3,a1
    80001988:	8552                	mv	a0,s4
    8000198a:	00000097          	auipc	ra,0x0
    8000198e:	870080e7          	jalr	-1936(ra) # 800011fa <kvmmap>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001992:	16848493          	addi	s1,s1,360
    80001996:	fd5497e3          	bne	s1,s5,80001964 <proc_mapstacks+0x4a>
  }
}
    8000199a:	70e2                	ld	ra,56(sp)
    8000199c:	7442                	ld	s0,48(sp)
    8000199e:	74a2                	ld	s1,40(sp)
    800019a0:	7902                	ld	s2,32(sp)
    800019a2:	69e2                	ld	s3,24(sp)
    800019a4:	6a42                	ld	s4,16(sp)
    800019a6:	6aa2                	ld	s5,8(sp)
    800019a8:	6b02                	ld	s6,0(sp)
    800019aa:	6121                	addi	sp,sp,64
    800019ac:	8082                	ret
      panic("kalloc");
    800019ae:	00007517          	auipc	a0,0x7
    800019b2:	82a50513          	addi	a0,a0,-2006 # 800081d8 <etext+0x1d8>
    800019b6:	fffff097          	auipc	ra,0xfffff
    800019ba:	baa080e7          	jalr	-1110(ra) # 80000560 <panic>

00000000800019be <procinit>:

// initialize the proc table.
void
procinit(void)
{
    800019be:	7139                	addi	sp,sp,-64
    800019c0:	fc06                	sd	ra,56(sp)
    800019c2:	f822                	sd	s0,48(sp)
    800019c4:	f426                	sd	s1,40(sp)
    800019c6:	f04a                	sd	s2,32(sp)
    800019c8:	ec4e                	sd	s3,24(sp)
    800019ca:	e852                	sd	s4,16(sp)
    800019cc:	e456                	sd	s5,8(sp)
    800019ce:	e05a                	sd	s6,0(sp)
    800019d0:	0080                	addi	s0,sp,64
  struct proc *p;
  
  initlock(&pid_lock, "nextpid");
    800019d2:	00007597          	auipc	a1,0x7
    800019d6:	80e58593          	addi	a1,a1,-2034 # 800081e0 <etext+0x1e0>
    800019da:	00012517          	auipc	a0,0x12
    800019de:	ad650513          	addi	a0,a0,-1322 # 800134b0 <pid_lock>
    800019e2:	fffff097          	auipc	ra,0xfffff
    800019e6:	20e080e7          	jalr	526(ra) # 80000bf0 <initlock>
  initlock(&wait_lock, "wait_lock");
    800019ea:	00006597          	auipc	a1,0x6
    800019ee:	7fe58593          	addi	a1,a1,2046 # 800081e8 <etext+0x1e8>
    800019f2:	00012517          	auipc	a0,0x12
    800019f6:	ad650513          	addi	a0,a0,-1322 # 800134c8 <wait_lock>
    800019fa:	fffff097          	auipc	ra,0xfffff
    800019fe:	1f6080e7          	jalr	502(ra) # 80000bf0 <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001a02:	00012497          	auipc	s1,0x12
    80001a06:	ede48493          	addi	s1,s1,-290 # 800138e0 <proc>
      initlock(&p->lock, "proc");
    80001a0a:	00006b17          	auipc	s6,0x6
    80001a0e:	7eeb0b13          	addi	s6,s6,2030 # 800081f8 <etext+0x1f8>
      p->state = UNUSED;
      p->kstack = KSTACK((int) (p - proc));
    80001a12:	8aa6                	mv	s5,s1
    80001a14:	04fa5937          	lui	s2,0x4fa5
    80001a18:	fa590913          	addi	s2,s2,-91 # 4fa4fa5 <_entry-0x7b05b05b>
    80001a1c:	0932                	slli	s2,s2,0xc
    80001a1e:	fa590913          	addi	s2,s2,-91
    80001a22:	0932                	slli	s2,s2,0xc
    80001a24:	fa590913          	addi	s2,s2,-91
    80001a28:	0932                	slli	s2,s2,0xc
    80001a2a:	fa590913          	addi	s2,s2,-91
    80001a2e:	040009b7          	lui	s3,0x4000
    80001a32:	19fd                	addi	s3,s3,-1 # 3ffffff <_entry-0x7c000001>
    80001a34:	09b2                	slli	s3,s3,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001a36:	00018a17          	auipc	s4,0x18
    80001a3a:	8aaa0a13          	addi	s4,s4,-1878 # 800192e0 <tickslock>
      initlock(&p->lock, "proc");
    80001a3e:	85da                	mv	a1,s6
    80001a40:	8526                	mv	a0,s1
    80001a42:	fffff097          	auipc	ra,0xfffff
    80001a46:	1ae080e7          	jalr	430(ra) # 80000bf0 <initlock>
      p->state = UNUSED;
    80001a4a:	0004ac23          	sw	zero,24(s1)
      p->kstack = KSTACK((int) (p - proc));
    80001a4e:	415487b3          	sub	a5,s1,s5
    80001a52:	878d                	srai	a5,a5,0x3
    80001a54:	032787b3          	mul	a5,a5,s2
    80001a58:	2785                	addiw	a5,a5,1
    80001a5a:	00d7979b          	slliw	a5,a5,0xd
    80001a5e:	40f987b3          	sub	a5,s3,a5
    80001a62:	e0bc                	sd	a5,64(s1)
  for(p = proc; p < &proc[NPROC]; p++) {
    80001a64:	16848493          	addi	s1,s1,360
    80001a68:	fd449be3          	bne	s1,s4,80001a3e <procinit+0x80>
  }
}
    80001a6c:	70e2                	ld	ra,56(sp)
    80001a6e:	7442                	ld	s0,48(sp)
    80001a70:	74a2                	ld	s1,40(sp)
    80001a72:	7902                	ld	s2,32(sp)
    80001a74:	69e2                	ld	s3,24(sp)
    80001a76:	6a42                	ld	s4,16(sp)
    80001a78:	6aa2                	ld	s5,8(sp)
    80001a7a:	6b02                	ld	s6,0(sp)
    80001a7c:	6121                	addi	sp,sp,64
    80001a7e:	8082                	ret

0000000080001a80 <cpuid>:
// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
    80001a80:	1141                	addi	sp,sp,-16
    80001a82:	e422                	sd	s0,8(sp)
    80001a84:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001a86:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    80001a88:	2501                	sext.w	a0,a0
    80001a8a:	6422                	ld	s0,8(sp)
    80001a8c:	0141                	addi	sp,sp,16
    80001a8e:	8082                	ret

0000000080001a90 <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void)
{
    80001a90:	1141                	addi	sp,sp,-16
    80001a92:	e422                	sd	s0,8(sp)
    80001a94:	0800                	addi	s0,sp,16
    80001a96:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    80001a98:	2781                	sext.w	a5,a5
    80001a9a:	079e                	slli	a5,a5,0x7
  return c;
}
    80001a9c:	00012517          	auipc	a0,0x12
    80001aa0:	a4450513          	addi	a0,a0,-1468 # 800134e0 <cpus>
    80001aa4:	953e                	add	a0,a0,a5
    80001aa6:	6422                	ld	s0,8(sp)
    80001aa8:	0141                	addi	sp,sp,16
    80001aaa:	8082                	ret

0000000080001aac <myproc>:

// Return the current struct proc *, or zero if none.
struct proc*
myproc(void)
{
    80001aac:	1101                	addi	sp,sp,-32
    80001aae:	ec06                	sd	ra,24(sp)
    80001ab0:	e822                	sd	s0,16(sp)
    80001ab2:	e426                	sd	s1,8(sp)
    80001ab4:	1000                	addi	s0,sp,32
  push_off();
    80001ab6:	fffff097          	auipc	ra,0xfffff
    80001aba:	17e080e7          	jalr	382(ra) # 80000c34 <push_off>
    80001abe:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    80001ac0:	2781                	sext.w	a5,a5
    80001ac2:	079e                	slli	a5,a5,0x7
    80001ac4:	00012717          	auipc	a4,0x12
    80001ac8:	9ec70713          	addi	a4,a4,-1556 # 800134b0 <pid_lock>
    80001acc:	97ba                	add	a5,a5,a4
    80001ace:	7b84                	ld	s1,48(a5)
  pop_off();
    80001ad0:	fffff097          	auipc	ra,0xfffff
    80001ad4:	204080e7          	jalr	516(ra) # 80000cd4 <pop_off>
  return p;
}
    80001ad8:	8526                	mv	a0,s1
    80001ada:	60e2                	ld	ra,24(sp)
    80001adc:	6442                	ld	s0,16(sp)
    80001ade:	64a2                	ld	s1,8(sp)
    80001ae0:	6105                	addi	sp,sp,32
    80001ae2:	8082                	ret

0000000080001ae4 <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
    80001ae4:	1141                	addi	sp,sp,-16
    80001ae6:	e406                	sd	ra,8(sp)
    80001ae8:	e022                	sd	s0,0(sp)
    80001aea:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    80001aec:	00000097          	auipc	ra,0x0
    80001af0:	fc0080e7          	jalr	-64(ra) # 80001aac <myproc>
    80001af4:	fffff097          	auipc	ra,0xfffff
    80001af8:	240080e7          	jalr	576(ra) # 80000d34 <release>

  if (first) {
    80001afc:	00009797          	auipc	a5,0x9
    80001b00:	6a47a783          	lw	a5,1700(a5) # 8000b1a0 <first.1>
    80001b04:	eb89                	bnez	a5,80001b16 <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001b06:	00001097          	auipc	ra,0x1
    80001b0a:	c5e080e7          	jalr	-930(ra) # 80002764 <usertrapret>
}
    80001b0e:	60a2                	ld	ra,8(sp)
    80001b10:	6402                	ld	s0,0(sp)
    80001b12:	0141                	addi	sp,sp,16
    80001b14:	8082                	ret
    first = 0;
    80001b16:	00009797          	auipc	a5,0x9
    80001b1a:	6807a523          	sw	zero,1674(a5) # 8000b1a0 <first.1>
    fsinit(ROOTDEV);
    80001b1e:	4505                	li	a0,1
    80001b20:	00002097          	auipc	ra,0x2
    80001b24:	9e4080e7          	jalr	-1564(ra) # 80003504 <fsinit>
    80001b28:	bff9                	j	80001b06 <forkret+0x22>

0000000080001b2a <allocpid>:
{
    80001b2a:	1101                	addi	sp,sp,-32
    80001b2c:	ec06                	sd	ra,24(sp)
    80001b2e:	e822                	sd	s0,16(sp)
    80001b30:	e426                	sd	s1,8(sp)
    80001b32:	e04a                	sd	s2,0(sp)
    80001b34:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001b36:	00012917          	auipc	s2,0x12
    80001b3a:	97a90913          	addi	s2,s2,-1670 # 800134b0 <pid_lock>
    80001b3e:	854a                	mv	a0,s2
    80001b40:	fffff097          	auipc	ra,0xfffff
    80001b44:	140080e7          	jalr	320(ra) # 80000c80 <acquire>
  pid = nextpid;
    80001b48:	00009797          	auipc	a5,0x9
    80001b4c:	65c78793          	addi	a5,a5,1628 # 8000b1a4 <nextpid>
    80001b50:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001b52:	0014871b          	addiw	a4,s1,1
    80001b56:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001b58:	854a                	mv	a0,s2
    80001b5a:	fffff097          	auipc	ra,0xfffff
    80001b5e:	1da080e7          	jalr	474(ra) # 80000d34 <release>
}
    80001b62:	8526                	mv	a0,s1
    80001b64:	60e2                	ld	ra,24(sp)
    80001b66:	6442                	ld	s0,16(sp)
    80001b68:	64a2                	ld	s1,8(sp)
    80001b6a:	6902                	ld	s2,0(sp)
    80001b6c:	6105                	addi	sp,sp,32
    80001b6e:	8082                	ret

0000000080001b70 <proc_pagetable>:
{
    80001b70:	1101                	addi	sp,sp,-32
    80001b72:	ec06                	sd	ra,24(sp)
    80001b74:	e822                	sd	s0,16(sp)
    80001b76:	e426                	sd	s1,8(sp)
    80001b78:	e04a                	sd	s2,0(sp)
    80001b7a:	1000                	addi	s0,sp,32
    80001b7c:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001b7e:	00000097          	auipc	ra,0x0
    80001b82:	876080e7          	jalr	-1930(ra) # 800013f4 <uvmcreate>
    80001b86:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001b88:	c121                	beqz	a0,80001bc8 <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001b8a:	4729                	li	a4,10
    80001b8c:	00005697          	auipc	a3,0x5
    80001b90:	47468693          	addi	a3,a3,1140 # 80007000 <_trampoline>
    80001b94:	6605                	lui	a2,0x1
    80001b96:	040005b7          	lui	a1,0x4000
    80001b9a:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001b9c:	05b2                	slli	a1,a1,0xc
    80001b9e:	fffff097          	auipc	ra,0xfffff
    80001ba2:	5bc080e7          	jalr	1468(ra) # 8000115a <mappages>
    80001ba6:	02054863          	bltz	a0,80001bd6 <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001baa:	4719                	li	a4,6
    80001bac:	05893683          	ld	a3,88(s2)
    80001bb0:	6605                	lui	a2,0x1
    80001bb2:	020005b7          	lui	a1,0x2000
    80001bb6:	15fd                	addi	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001bb8:	05b6                	slli	a1,a1,0xd
    80001bba:	8526                	mv	a0,s1
    80001bbc:	fffff097          	auipc	ra,0xfffff
    80001bc0:	59e080e7          	jalr	1438(ra) # 8000115a <mappages>
    80001bc4:	02054163          	bltz	a0,80001be6 <proc_pagetable+0x76>
}
    80001bc8:	8526                	mv	a0,s1
    80001bca:	60e2                	ld	ra,24(sp)
    80001bcc:	6442                	ld	s0,16(sp)
    80001bce:	64a2                	ld	s1,8(sp)
    80001bd0:	6902                	ld	s2,0(sp)
    80001bd2:	6105                	addi	sp,sp,32
    80001bd4:	8082                	ret
    uvmfree(pagetable, 0);
    80001bd6:	4581                	li	a1,0
    80001bd8:	8526                	mv	a0,s1
    80001bda:	00000097          	auipc	ra,0x0
    80001bde:	a2c080e7          	jalr	-1492(ra) # 80001606 <uvmfree>
    return 0;
    80001be2:	4481                	li	s1,0
    80001be4:	b7d5                	j	80001bc8 <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001be6:	4681                	li	a3,0
    80001be8:	4605                	li	a2,1
    80001bea:	040005b7          	lui	a1,0x4000
    80001bee:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001bf0:	05b2                	slli	a1,a1,0xc
    80001bf2:	8526                	mv	a0,s1
    80001bf4:	fffff097          	auipc	ra,0xfffff
    80001bf8:	72c080e7          	jalr	1836(ra) # 80001320 <uvmunmap>
    uvmfree(pagetable, 0);
    80001bfc:	4581                	li	a1,0
    80001bfe:	8526                	mv	a0,s1
    80001c00:	00000097          	auipc	ra,0x0
    80001c04:	a06080e7          	jalr	-1530(ra) # 80001606 <uvmfree>
    return 0;
    80001c08:	4481                	li	s1,0
    80001c0a:	bf7d                	j	80001bc8 <proc_pagetable+0x58>

0000000080001c0c <proc_freepagetable>:
{
    80001c0c:	1101                	addi	sp,sp,-32
    80001c0e:	ec06                	sd	ra,24(sp)
    80001c10:	e822                	sd	s0,16(sp)
    80001c12:	e426                	sd	s1,8(sp)
    80001c14:	e04a                	sd	s2,0(sp)
    80001c16:	1000                	addi	s0,sp,32
    80001c18:	84aa                	mv	s1,a0
    80001c1a:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001c1c:	4681                	li	a3,0
    80001c1e:	4605                	li	a2,1
    80001c20:	040005b7          	lui	a1,0x4000
    80001c24:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001c26:	05b2                	slli	a1,a1,0xc
    80001c28:	fffff097          	auipc	ra,0xfffff
    80001c2c:	6f8080e7          	jalr	1784(ra) # 80001320 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001c30:	4681                	li	a3,0
    80001c32:	4605                	li	a2,1
    80001c34:	020005b7          	lui	a1,0x2000
    80001c38:	15fd                	addi	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001c3a:	05b6                	slli	a1,a1,0xd
    80001c3c:	8526                	mv	a0,s1
    80001c3e:	fffff097          	auipc	ra,0xfffff
    80001c42:	6e2080e7          	jalr	1762(ra) # 80001320 <uvmunmap>
  uvmfree(pagetable, sz);
    80001c46:	85ca                	mv	a1,s2
    80001c48:	8526                	mv	a0,s1
    80001c4a:	00000097          	auipc	ra,0x0
    80001c4e:	9bc080e7          	jalr	-1604(ra) # 80001606 <uvmfree>
}
    80001c52:	60e2                	ld	ra,24(sp)
    80001c54:	6442                	ld	s0,16(sp)
    80001c56:	64a2                	ld	s1,8(sp)
    80001c58:	6902                	ld	s2,0(sp)
    80001c5a:	6105                	addi	sp,sp,32
    80001c5c:	8082                	ret

0000000080001c5e <freeproc>:
{
    80001c5e:	1101                	addi	sp,sp,-32
    80001c60:	ec06                	sd	ra,24(sp)
    80001c62:	e822                	sd	s0,16(sp)
    80001c64:	e426                	sd	s1,8(sp)
    80001c66:	1000                	addi	s0,sp,32
    80001c68:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001c6a:	6d28                	ld	a0,88(a0)
    80001c6c:	c509                	beqz	a0,80001c76 <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001c6e:	fffff097          	auipc	ra,0xfffff
    80001c72:	ddc080e7          	jalr	-548(ra) # 80000a4a <kfree>
  p->trapframe = 0;
    80001c76:	0404bc23          	sd	zero,88(s1)
  if(p->pagetable)
    80001c7a:	68a8                	ld	a0,80(s1)
    80001c7c:	c511                	beqz	a0,80001c88 <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001c7e:	64ac                	ld	a1,72(s1)
    80001c80:	00000097          	auipc	ra,0x0
    80001c84:	f8c080e7          	jalr	-116(ra) # 80001c0c <proc_freepagetable>
  p->pagetable = 0;
    80001c88:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001c8c:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001c90:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001c94:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    80001c98:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001c9c:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001ca0:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001ca4:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001ca8:	0004ac23          	sw	zero,24(s1)
}
    80001cac:	60e2                	ld	ra,24(sp)
    80001cae:	6442                	ld	s0,16(sp)
    80001cb0:	64a2                	ld	s1,8(sp)
    80001cb2:	6105                	addi	sp,sp,32
    80001cb4:	8082                	ret

0000000080001cb6 <allocproc>:
{
    80001cb6:	1101                	addi	sp,sp,-32
    80001cb8:	ec06                	sd	ra,24(sp)
    80001cba:	e822                	sd	s0,16(sp)
    80001cbc:	e426                	sd	s1,8(sp)
    80001cbe:	e04a                	sd	s2,0(sp)
    80001cc0:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001cc2:	00012497          	auipc	s1,0x12
    80001cc6:	c1e48493          	addi	s1,s1,-994 # 800138e0 <proc>
    80001cca:	00017917          	auipc	s2,0x17
    80001cce:	61690913          	addi	s2,s2,1558 # 800192e0 <tickslock>
    acquire(&p->lock);
    80001cd2:	8526                	mv	a0,s1
    80001cd4:	fffff097          	auipc	ra,0xfffff
    80001cd8:	fac080e7          	jalr	-84(ra) # 80000c80 <acquire>
    if(p->state == UNUSED) {
    80001cdc:	4c9c                	lw	a5,24(s1)
    80001cde:	cf81                	beqz	a5,80001cf6 <allocproc+0x40>
      release(&p->lock);
    80001ce0:	8526                	mv	a0,s1
    80001ce2:	fffff097          	auipc	ra,0xfffff
    80001ce6:	052080e7          	jalr	82(ra) # 80000d34 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001cea:	16848493          	addi	s1,s1,360
    80001cee:	ff2492e3          	bne	s1,s2,80001cd2 <allocproc+0x1c>
  return 0;
    80001cf2:	4481                	li	s1,0
    80001cf4:	a889                	j	80001d46 <allocproc+0x90>
  p->pid = allocpid();
    80001cf6:	00000097          	auipc	ra,0x0
    80001cfa:	e34080e7          	jalr	-460(ra) # 80001b2a <allocpid>
    80001cfe:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001d00:	4785                	li	a5,1
    80001d02:	cc9c                	sw	a5,24(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001d04:	fffff097          	auipc	ra,0xfffff
    80001d08:	e44080e7          	jalr	-444(ra) # 80000b48 <kalloc>
    80001d0c:	892a                	mv	s2,a0
    80001d0e:	eca8                	sd	a0,88(s1)
    80001d10:	c131                	beqz	a0,80001d54 <allocproc+0x9e>
  p->pagetable = proc_pagetable(p);
    80001d12:	8526                	mv	a0,s1
    80001d14:	00000097          	auipc	ra,0x0
    80001d18:	e5c080e7          	jalr	-420(ra) # 80001b70 <proc_pagetable>
    80001d1c:	892a                	mv	s2,a0
    80001d1e:	e8a8                	sd	a0,80(s1)
  if(p->pagetable == 0){
    80001d20:	c531                	beqz	a0,80001d6c <allocproc+0xb6>
  memset(&p->context, 0, sizeof(p->context));
    80001d22:	07000613          	li	a2,112
    80001d26:	4581                	li	a1,0
    80001d28:	06048513          	addi	a0,s1,96
    80001d2c:	fffff097          	auipc	ra,0xfffff
    80001d30:	050080e7          	jalr	80(ra) # 80000d7c <memset>
  p->context.ra = (uint64)forkret;
    80001d34:	00000797          	auipc	a5,0x0
    80001d38:	db078793          	addi	a5,a5,-592 # 80001ae4 <forkret>
    80001d3c:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001d3e:	60bc                	ld	a5,64(s1)
    80001d40:	6705                	lui	a4,0x1
    80001d42:	97ba                	add	a5,a5,a4
    80001d44:	f4bc                	sd	a5,104(s1)
}
    80001d46:	8526                	mv	a0,s1
    80001d48:	60e2                	ld	ra,24(sp)
    80001d4a:	6442                	ld	s0,16(sp)
    80001d4c:	64a2                	ld	s1,8(sp)
    80001d4e:	6902                	ld	s2,0(sp)
    80001d50:	6105                	addi	sp,sp,32
    80001d52:	8082                	ret
    freeproc(p);
    80001d54:	8526                	mv	a0,s1
    80001d56:	00000097          	auipc	ra,0x0
    80001d5a:	f08080e7          	jalr	-248(ra) # 80001c5e <freeproc>
    release(&p->lock);
    80001d5e:	8526                	mv	a0,s1
    80001d60:	fffff097          	auipc	ra,0xfffff
    80001d64:	fd4080e7          	jalr	-44(ra) # 80000d34 <release>
    return 0;
    80001d68:	84ca                	mv	s1,s2
    80001d6a:	bff1                	j	80001d46 <allocproc+0x90>
    freeproc(p);
    80001d6c:	8526                	mv	a0,s1
    80001d6e:	00000097          	auipc	ra,0x0
    80001d72:	ef0080e7          	jalr	-272(ra) # 80001c5e <freeproc>
    release(&p->lock);
    80001d76:	8526                	mv	a0,s1
    80001d78:	fffff097          	auipc	ra,0xfffff
    80001d7c:	fbc080e7          	jalr	-68(ra) # 80000d34 <release>
    return 0;
    80001d80:	84ca                	mv	s1,s2
    80001d82:	b7d1                	j	80001d46 <allocproc+0x90>

0000000080001d84 <userinit>:
{
    80001d84:	1101                	addi	sp,sp,-32
    80001d86:	ec06                	sd	ra,24(sp)
    80001d88:	e822                	sd	s0,16(sp)
    80001d8a:	e426                	sd	s1,8(sp)
    80001d8c:	1000                	addi	s0,sp,32
  p = allocproc();
    80001d8e:	00000097          	auipc	ra,0x0
    80001d92:	f28080e7          	jalr	-216(ra) # 80001cb6 <allocproc>
    80001d96:	84aa                	mv	s1,a0
  initproc = p;
    80001d98:	00009797          	auipc	a5,0x9
    80001d9c:	4aa7b023          	sd	a0,1184(a5) # 8000b238 <initproc>
  uvmfirst(p->pagetable, initcode, sizeof(initcode));
    80001da0:	03400613          	li	a2,52
    80001da4:	00009597          	auipc	a1,0x9
    80001da8:	40c58593          	addi	a1,a1,1036 # 8000b1b0 <initcode>
    80001dac:	6928                	ld	a0,80(a0)
    80001dae:	fffff097          	auipc	ra,0xfffff
    80001db2:	674080e7          	jalr	1652(ra) # 80001422 <uvmfirst>
  p->sz = PGSIZE;
    80001db6:	6785                	lui	a5,0x1
    80001db8:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;      // user program counter
    80001dba:	6cb8                	ld	a4,88(s1)
    80001dbc:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001dc0:	6cb8                	ld	a4,88(s1)
    80001dc2:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001dc4:	4641                	li	a2,16
    80001dc6:	00006597          	auipc	a1,0x6
    80001dca:	43a58593          	addi	a1,a1,1082 # 80008200 <etext+0x200>
    80001dce:	15848513          	addi	a0,s1,344
    80001dd2:	fffff097          	auipc	ra,0xfffff
    80001dd6:	0ec080e7          	jalr	236(ra) # 80000ebe <safestrcpy>
  p->cwd = namei("/");
    80001dda:	00006517          	auipc	a0,0x6
    80001dde:	43650513          	addi	a0,a0,1078 # 80008210 <etext+0x210>
    80001de2:	00002097          	auipc	ra,0x2
    80001de6:	174080e7          	jalr	372(ra) # 80003f56 <namei>
    80001dea:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001dee:	478d                	li	a5,3
    80001df0:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001df2:	8526                	mv	a0,s1
    80001df4:	fffff097          	auipc	ra,0xfffff
    80001df8:	f40080e7          	jalr	-192(ra) # 80000d34 <release>
}
    80001dfc:	60e2                	ld	ra,24(sp)
    80001dfe:	6442                	ld	s0,16(sp)
    80001e00:	64a2                	ld	s1,8(sp)
    80001e02:	6105                	addi	sp,sp,32
    80001e04:	8082                	ret

0000000080001e06 <growproc>:
{
    80001e06:	1101                	addi	sp,sp,-32
    80001e08:	ec06                	sd	ra,24(sp)
    80001e0a:	e822                	sd	s0,16(sp)
    80001e0c:	e426                	sd	s1,8(sp)
    80001e0e:	e04a                	sd	s2,0(sp)
    80001e10:	1000                	addi	s0,sp,32
    80001e12:	892a                	mv	s2,a0
  struct proc *p = myproc();
    80001e14:	00000097          	auipc	ra,0x0
    80001e18:	c98080e7          	jalr	-872(ra) # 80001aac <myproc>
    80001e1c:	84aa                	mv	s1,a0
  sz = p->sz;
    80001e1e:	652c                	ld	a1,72(a0)
  if(n > 0){
    80001e20:	01204c63          	bgtz	s2,80001e38 <growproc+0x32>
  } else if(n < 0){
    80001e24:	02094663          	bltz	s2,80001e50 <growproc+0x4a>
  p->sz = sz;
    80001e28:	e4ac                	sd	a1,72(s1)
  return 0;
    80001e2a:	4501                	li	a0,0
}
    80001e2c:	60e2                	ld	ra,24(sp)
    80001e2e:	6442                	ld	s0,16(sp)
    80001e30:	64a2                	ld	s1,8(sp)
    80001e32:	6902                	ld	s2,0(sp)
    80001e34:	6105                	addi	sp,sp,32
    80001e36:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n, PTE_W)) == 0) {
    80001e38:	4691                	li	a3,4
    80001e3a:	00b90633          	add	a2,s2,a1
    80001e3e:	6928                	ld	a0,80(a0)
    80001e40:	fffff097          	auipc	ra,0xfffff
    80001e44:	69c080e7          	jalr	1692(ra) # 800014dc <uvmalloc>
    80001e48:	85aa                	mv	a1,a0
    80001e4a:	fd79                	bnez	a0,80001e28 <growproc+0x22>
      return -1;
    80001e4c:	557d                	li	a0,-1
    80001e4e:	bff9                	j	80001e2c <growproc+0x26>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001e50:	00b90633          	add	a2,s2,a1
    80001e54:	6928                	ld	a0,80(a0)
    80001e56:	fffff097          	auipc	ra,0xfffff
    80001e5a:	63e080e7          	jalr	1598(ra) # 80001494 <uvmdealloc>
    80001e5e:	85aa                	mv	a1,a0
    80001e60:	b7e1                	j	80001e28 <growproc+0x22>

0000000080001e62 <fork>:
{
    80001e62:	7139                	addi	sp,sp,-64
    80001e64:	fc06                	sd	ra,56(sp)
    80001e66:	f822                	sd	s0,48(sp)
    80001e68:	f04a                	sd	s2,32(sp)
    80001e6a:	e456                	sd	s5,8(sp)
    80001e6c:	0080                	addi	s0,sp,64
  struct proc *p = myproc();
    80001e6e:	00000097          	auipc	ra,0x0
    80001e72:	c3e080e7          	jalr	-962(ra) # 80001aac <myproc>
    80001e76:	8aaa                	mv	s5,a0
  if((np = allocproc()) == 0){
    80001e78:	00000097          	auipc	ra,0x0
    80001e7c:	e3e080e7          	jalr	-450(ra) # 80001cb6 <allocproc>
    80001e80:	12050063          	beqz	a0,80001fa0 <fork+0x13e>
    80001e84:	e852                	sd	s4,16(sp)
    80001e86:	8a2a                	mv	s4,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001e88:	048ab603          	ld	a2,72(s5)
    80001e8c:	692c                	ld	a1,80(a0)
    80001e8e:	050ab503          	ld	a0,80(s5)
    80001e92:	fffff097          	auipc	ra,0xfffff
    80001e96:	7ae080e7          	jalr	1966(ra) # 80001640 <uvmcopy>
    80001e9a:	04054a63          	bltz	a0,80001eee <fork+0x8c>
    80001e9e:	f426                	sd	s1,40(sp)
    80001ea0:	ec4e                	sd	s3,24(sp)
  np->sz = p->sz;
    80001ea2:	048ab783          	ld	a5,72(s5)
    80001ea6:	04fa3423          	sd	a5,72(s4)
  *(np->trapframe) = *(p->trapframe);
    80001eaa:	058ab683          	ld	a3,88(s5)
    80001eae:	87b6                	mv	a5,a3
    80001eb0:	058a3703          	ld	a4,88(s4)
    80001eb4:	12068693          	addi	a3,a3,288
    80001eb8:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001ebc:	6788                	ld	a0,8(a5)
    80001ebe:	6b8c                	ld	a1,16(a5)
    80001ec0:	6f90                	ld	a2,24(a5)
    80001ec2:	01073023          	sd	a6,0(a4)
    80001ec6:	e708                	sd	a0,8(a4)
    80001ec8:	eb0c                	sd	a1,16(a4)
    80001eca:	ef10                	sd	a2,24(a4)
    80001ecc:	02078793          	addi	a5,a5,32
    80001ed0:	02070713          	addi	a4,a4,32
    80001ed4:	fed792e3          	bne	a5,a3,80001eb8 <fork+0x56>
  np->trapframe->a0 = 0;
    80001ed8:	058a3783          	ld	a5,88(s4)
    80001edc:	0607b823          	sd	zero,112(a5)
  for(i = 0; i < NOFILE; i++)
    80001ee0:	0d0a8493          	addi	s1,s5,208
    80001ee4:	0d0a0913          	addi	s2,s4,208
    80001ee8:	150a8993          	addi	s3,s5,336
    80001eec:	a015                	j	80001f10 <fork+0xae>
    freeproc(np);
    80001eee:	8552                	mv	a0,s4
    80001ef0:	00000097          	auipc	ra,0x0
    80001ef4:	d6e080e7          	jalr	-658(ra) # 80001c5e <freeproc>
    release(&np->lock);
    80001ef8:	8552                	mv	a0,s4
    80001efa:	fffff097          	auipc	ra,0xfffff
    80001efe:	e3a080e7          	jalr	-454(ra) # 80000d34 <release>
    return -1;
    80001f02:	597d                	li	s2,-1
    80001f04:	6a42                	ld	s4,16(sp)
    80001f06:	a071                	j	80001f92 <fork+0x130>
  for(i = 0; i < NOFILE; i++)
    80001f08:	04a1                	addi	s1,s1,8
    80001f0a:	0921                	addi	s2,s2,8
    80001f0c:	01348b63          	beq	s1,s3,80001f22 <fork+0xc0>
    if(p->ofile[i])
    80001f10:	6088                	ld	a0,0(s1)
    80001f12:	d97d                	beqz	a0,80001f08 <fork+0xa6>
      np->ofile[i] = filedup(p->ofile[i]);
    80001f14:	00002097          	auipc	ra,0x2
    80001f18:	6ba080e7          	jalr	1722(ra) # 800045ce <filedup>
    80001f1c:	00a93023          	sd	a0,0(s2)
    80001f20:	b7e5                	j	80001f08 <fork+0xa6>
  np->cwd = idup(p->cwd);
    80001f22:	150ab503          	ld	a0,336(s5)
    80001f26:	00002097          	auipc	ra,0x2
    80001f2a:	824080e7          	jalr	-2012(ra) # 8000374a <idup>
    80001f2e:	14aa3823          	sd	a0,336(s4)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001f32:	4641                	li	a2,16
    80001f34:	158a8593          	addi	a1,s5,344
    80001f38:	158a0513          	addi	a0,s4,344
    80001f3c:	fffff097          	auipc	ra,0xfffff
    80001f40:	f82080e7          	jalr	-126(ra) # 80000ebe <safestrcpy>
  pid = np->pid;
    80001f44:	030a2903          	lw	s2,48(s4)
  release(&np->lock);
    80001f48:	8552                	mv	a0,s4
    80001f4a:	fffff097          	auipc	ra,0xfffff
    80001f4e:	dea080e7          	jalr	-534(ra) # 80000d34 <release>
  acquire(&wait_lock);
    80001f52:	00011497          	auipc	s1,0x11
    80001f56:	57648493          	addi	s1,s1,1398 # 800134c8 <wait_lock>
    80001f5a:	8526                	mv	a0,s1
    80001f5c:	fffff097          	auipc	ra,0xfffff
    80001f60:	d24080e7          	jalr	-732(ra) # 80000c80 <acquire>
  np->parent = p;
    80001f64:	035a3c23          	sd	s5,56(s4)
  release(&wait_lock);
    80001f68:	8526                	mv	a0,s1
    80001f6a:	fffff097          	auipc	ra,0xfffff
    80001f6e:	dca080e7          	jalr	-566(ra) # 80000d34 <release>
  acquire(&np->lock);
    80001f72:	8552                	mv	a0,s4
    80001f74:	fffff097          	auipc	ra,0xfffff
    80001f78:	d0c080e7          	jalr	-756(ra) # 80000c80 <acquire>
  np->state = RUNNABLE;
    80001f7c:	478d                	li	a5,3
    80001f7e:	00fa2c23          	sw	a5,24(s4)
  release(&np->lock);
    80001f82:	8552                	mv	a0,s4
    80001f84:	fffff097          	auipc	ra,0xfffff
    80001f88:	db0080e7          	jalr	-592(ra) # 80000d34 <release>
  return pid;
    80001f8c:	74a2                	ld	s1,40(sp)
    80001f8e:	69e2                	ld	s3,24(sp)
    80001f90:	6a42                	ld	s4,16(sp)
}
    80001f92:	854a                	mv	a0,s2
    80001f94:	70e2                	ld	ra,56(sp)
    80001f96:	7442                	ld	s0,48(sp)
    80001f98:	7902                	ld	s2,32(sp)
    80001f9a:	6aa2                	ld	s5,8(sp)
    80001f9c:	6121                	addi	sp,sp,64
    80001f9e:	8082                	ret
    return -1;
    80001fa0:	597d                	li	s2,-1
    80001fa2:	bfc5                	j	80001f92 <fork+0x130>

0000000080001fa4 <scheduler>:
{
    80001fa4:	7139                	addi	sp,sp,-64
    80001fa6:	fc06                	sd	ra,56(sp)
    80001fa8:	f822                	sd	s0,48(sp)
    80001faa:	f426                	sd	s1,40(sp)
    80001fac:	f04a                	sd	s2,32(sp)
    80001fae:	ec4e                	sd	s3,24(sp)
    80001fb0:	e852                	sd	s4,16(sp)
    80001fb2:	e456                	sd	s5,8(sp)
    80001fb4:	e05a                	sd	s6,0(sp)
    80001fb6:	0080                	addi	s0,sp,64
    80001fb8:	8792                	mv	a5,tp
  int id = r_tp();
    80001fba:	2781                	sext.w	a5,a5
  c->proc = 0;
    80001fbc:	00779a93          	slli	s5,a5,0x7
    80001fc0:	00011717          	auipc	a4,0x11
    80001fc4:	4f070713          	addi	a4,a4,1264 # 800134b0 <pid_lock>
    80001fc8:	9756                	add	a4,a4,s5
    80001fca:	02073823          	sd	zero,48(a4)
        swtch(&c->context, &p->context);
    80001fce:	00011717          	auipc	a4,0x11
    80001fd2:	51a70713          	addi	a4,a4,1306 # 800134e8 <cpus+0x8>
    80001fd6:	9aba                	add	s5,s5,a4
      if(p->state == RUNNABLE) {
    80001fd8:	498d                	li	s3,3
        p->state = RUNNING;
    80001fda:	4b11                	li	s6,4
        c->proc = p;
    80001fdc:	079e                	slli	a5,a5,0x7
    80001fde:	00011a17          	auipc	s4,0x11
    80001fe2:	4d2a0a13          	addi	s4,s4,1234 # 800134b0 <pid_lock>
    80001fe6:	9a3e                	add	s4,s4,a5
    for(p = proc; p < &proc[NPROC]; p++) {
    80001fe8:	00017917          	auipc	s2,0x17
    80001fec:	2f890913          	addi	s2,s2,760 # 800192e0 <tickslock>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001ff0:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001ff4:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001ff8:	10079073          	csrw	sstatus,a5
    80001ffc:	00012497          	auipc	s1,0x12
    80002000:	8e448493          	addi	s1,s1,-1820 # 800138e0 <proc>
    80002004:	a811                	j	80002018 <scheduler+0x74>
      release(&p->lock);
    80002006:	8526                	mv	a0,s1
    80002008:	fffff097          	auipc	ra,0xfffff
    8000200c:	d2c080e7          	jalr	-724(ra) # 80000d34 <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    80002010:	16848493          	addi	s1,s1,360
    80002014:	fd248ee3          	beq	s1,s2,80001ff0 <scheduler+0x4c>
      acquire(&p->lock);
    80002018:	8526                	mv	a0,s1
    8000201a:	fffff097          	auipc	ra,0xfffff
    8000201e:	c66080e7          	jalr	-922(ra) # 80000c80 <acquire>
      if(p->state == RUNNABLE) {
    80002022:	4c9c                	lw	a5,24(s1)
    80002024:	ff3791e3          	bne	a5,s3,80002006 <scheduler+0x62>
        p->state = RUNNING;
    80002028:	0164ac23          	sw	s6,24(s1)
        c->proc = p;
    8000202c:	029a3823          	sd	s1,48(s4)
        swtch(&c->context, &p->context);
    80002030:	06048593          	addi	a1,s1,96
    80002034:	8556                	mv	a0,s5
    80002036:	00000097          	auipc	ra,0x0
    8000203a:	684080e7          	jalr	1668(ra) # 800026ba <swtch>
        c->proc = 0;
    8000203e:	020a3823          	sd	zero,48(s4)
    80002042:	b7d1                	j	80002006 <scheduler+0x62>

0000000080002044 <sched>:
{
    80002044:	7179                	addi	sp,sp,-48
    80002046:	f406                	sd	ra,40(sp)
    80002048:	f022                	sd	s0,32(sp)
    8000204a:	ec26                	sd	s1,24(sp)
    8000204c:	e84a                	sd	s2,16(sp)
    8000204e:	e44e                	sd	s3,8(sp)
    80002050:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80002052:	00000097          	auipc	ra,0x0
    80002056:	a5a080e7          	jalr	-1446(ra) # 80001aac <myproc>
    8000205a:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    8000205c:	fffff097          	auipc	ra,0xfffff
    80002060:	baa080e7          	jalr	-1110(ra) # 80000c06 <holding>
    80002064:	c93d                	beqz	a0,800020da <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002066:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    80002068:	2781                	sext.w	a5,a5
    8000206a:	079e                	slli	a5,a5,0x7
    8000206c:	00011717          	auipc	a4,0x11
    80002070:	44470713          	addi	a4,a4,1092 # 800134b0 <pid_lock>
    80002074:	97ba                	add	a5,a5,a4
    80002076:	0a87a703          	lw	a4,168(a5)
    8000207a:	4785                	li	a5,1
    8000207c:	06f71763          	bne	a4,a5,800020ea <sched+0xa6>
  if(p->state == RUNNING)
    80002080:	4c98                	lw	a4,24(s1)
    80002082:	4791                	li	a5,4
    80002084:	06f70b63          	beq	a4,a5,800020fa <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002088:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    8000208c:	8b89                	andi	a5,a5,2
  if(intr_get())
    8000208e:	efb5                	bnez	a5,8000210a <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002090:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80002092:	00011917          	auipc	s2,0x11
    80002096:	41e90913          	addi	s2,s2,1054 # 800134b0 <pid_lock>
    8000209a:	2781                	sext.w	a5,a5
    8000209c:	079e                	slli	a5,a5,0x7
    8000209e:	97ca                	add	a5,a5,s2
    800020a0:	0ac7a983          	lw	s3,172(a5)
    800020a4:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    800020a6:	2781                	sext.w	a5,a5
    800020a8:	079e                	slli	a5,a5,0x7
    800020aa:	00011597          	auipc	a1,0x11
    800020ae:	43e58593          	addi	a1,a1,1086 # 800134e8 <cpus+0x8>
    800020b2:	95be                	add	a1,a1,a5
    800020b4:	06048513          	addi	a0,s1,96
    800020b8:	00000097          	auipc	ra,0x0
    800020bc:	602080e7          	jalr	1538(ra) # 800026ba <swtch>
    800020c0:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    800020c2:	2781                	sext.w	a5,a5
    800020c4:	079e                	slli	a5,a5,0x7
    800020c6:	993e                	add	s2,s2,a5
    800020c8:	0b392623          	sw	s3,172(s2)
}
    800020cc:	70a2                	ld	ra,40(sp)
    800020ce:	7402                	ld	s0,32(sp)
    800020d0:	64e2                	ld	s1,24(sp)
    800020d2:	6942                	ld	s2,16(sp)
    800020d4:	69a2                	ld	s3,8(sp)
    800020d6:	6145                	addi	sp,sp,48
    800020d8:	8082                	ret
    panic("sched p->lock");
    800020da:	00006517          	auipc	a0,0x6
    800020de:	13e50513          	addi	a0,a0,318 # 80008218 <etext+0x218>
    800020e2:	ffffe097          	auipc	ra,0xffffe
    800020e6:	47e080e7          	jalr	1150(ra) # 80000560 <panic>
    panic("sched locks");
    800020ea:	00006517          	auipc	a0,0x6
    800020ee:	13e50513          	addi	a0,a0,318 # 80008228 <etext+0x228>
    800020f2:	ffffe097          	auipc	ra,0xffffe
    800020f6:	46e080e7          	jalr	1134(ra) # 80000560 <panic>
    panic("sched running");
    800020fa:	00006517          	auipc	a0,0x6
    800020fe:	13e50513          	addi	a0,a0,318 # 80008238 <etext+0x238>
    80002102:	ffffe097          	auipc	ra,0xffffe
    80002106:	45e080e7          	jalr	1118(ra) # 80000560 <panic>
    panic("sched interruptible");
    8000210a:	00006517          	auipc	a0,0x6
    8000210e:	13e50513          	addi	a0,a0,318 # 80008248 <etext+0x248>
    80002112:	ffffe097          	auipc	ra,0xffffe
    80002116:	44e080e7          	jalr	1102(ra) # 80000560 <panic>

000000008000211a <yield>:
{
    8000211a:	1101                	addi	sp,sp,-32
    8000211c:	ec06                	sd	ra,24(sp)
    8000211e:	e822                	sd	s0,16(sp)
    80002120:	e426                	sd	s1,8(sp)
    80002122:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80002124:	00000097          	auipc	ra,0x0
    80002128:	988080e7          	jalr	-1656(ra) # 80001aac <myproc>
    8000212c:	84aa                	mv	s1,a0
  acquire(&p->lock);
    8000212e:	fffff097          	auipc	ra,0xfffff
    80002132:	b52080e7          	jalr	-1198(ra) # 80000c80 <acquire>
  p->state = RUNNABLE;
    80002136:	478d                	li	a5,3
    80002138:	cc9c                	sw	a5,24(s1)
  sched();
    8000213a:	00000097          	auipc	ra,0x0
    8000213e:	f0a080e7          	jalr	-246(ra) # 80002044 <sched>
  release(&p->lock);
    80002142:	8526                	mv	a0,s1
    80002144:	fffff097          	auipc	ra,0xfffff
    80002148:	bf0080e7          	jalr	-1040(ra) # 80000d34 <release>
}
    8000214c:	60e2                	ld	ra,24(sp)
    8000214e:	6442                	ld	s0,16(sp)
    80002150:	64a2                	ld	s1,8(sp)
    80002152:	6105                	addi	sp,sp,32
    80002154:	8082                	ret

0000000080002156 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    80002156:	7179                	addi	sp,sp,-48
    80002158:	f406                	sd	ra,40(sp)
    8000215a:	f022                	sd	s0,32(sp)
    8000215c:	ec26                	sd	s1,24(sp)
    8000215e:	e84a                	sd	s2,16(sp)
    80002160:	e44e                	sd	s3,8(sp)
    80002162:	1800                	addi	s0,sp,48
    80002164:	89aa                	mv	s3,a0
    80002166:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002168:	00000097          	auipc	ra,0x0
    8000216c:	944080e7          	jalr	-1724(ra) # 80001aac <myproc>
    80002170:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    80002172:	fffff097          	auipc	ra,0xfffff
    80002176:	b0e080e7          	jalr	-1266(ra) # 80000c80 <acquire>
  release(lk);
    8000217a:	854a                	mv	a0,s2
    8000217c:	fffff097          	auipc	ra,0xfffff
    80002180:	bb8080e7          	jalr	-1096(ra) # 80000d34 <release>

  // Go to sleep.
  p->chan = chan;
    80002184:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    80002188:	4789                	li	a5,2
    8000218a:	cc9c                	sw	a5,24(s1)

  sched();
    8000218c:	00000097          	auipc	ra,0x0
    80002190:	eb8080e7          	jalr	-328(ra) # 80002044 <sched>

  // Tidy up.
  p->chan = 0;
    80002194:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    80002198:	8526                	mv	a0,s1
    8000219a:	fffff097          	auipc	ra,0xfffff
    8000219e:	b9a080e7          	jalr	-1126(ra) # 80000d34 <release>
  acquire(lk);
    800021a2:	854a                	mv	a0,s2
    800021a4:	fffff097          	auipc	ra,0xfffff
    800021a8:	adc080e7          	jalr	-1316(ra) # 80000c80 <acquire>
}
    800021ac:	70a2                	ld	ra,40(sp)
    800021ae:	7402                	ld	s0,32(sp)
    800021b0:	64e2                	ld	s1,24(sp)
    800021b2:	6942                	ld	s2,16(sp)
    800021b4:	69a2                	ld	s3,8(sp)
    800021b6:	6145                	addi	sp,sp,48
    800021b8:	8082                	ret

00000000800021ba <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void
wakeup(void *chan)
{
    800021ba:	7139                	addi	sp,sp,-64
    800021bc:	fc06                	sd	ra,56(sp)
    800021be:	f822                	sd	s0,48(sp)
    800021c0:	f426                	sd	s1,40(sp)
    800021c2:	f04a                	sd	s2,32(sp)
    800021c4:	ec4e                	sd	s3,24(sp)
    800021c6:	e852                	sd	s4,16(sp)
    800021c8:	e456                	sd	s5,8(sp)
    800021ca:	0080                	addi	s0,sp,64
    800021cc:	8a2a                	mv	s4,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++) {
    800021ce:	00011497          	auipc	s1,0x11
    800021d2:	71248493          	addi	s1,s1,1810 # 800138e0 <proc>
    if(p != myproc()){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
    800021d6:	4989                	li	s3,2
        p->state = RUNNABLE;
    800021d8:	4a8d                	li	s5,3
  for(p = proc; p < &proc[NPROC]; p++) {
    800021da:	00017917          	auipc	s2,0x17
    800021de:	10690913          	addi	s2,s2,262 # 800192e0 <tickslock>
    800021e2:	a811                	j	800021f6 <wakeup+0x3c>
      }
      release(&p->lock);
    800021e4:	8526                	mv	a0,s1
    800021e6:	fffff097          	auipc	ra,0xfffff
    800021ea:	b4e080e7          	jalr	-1202(ra) # 80000d34 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    800021ee:	16848493          	addi	s1,s1,360
    800021f2:	03248663          	beq	s1,s2,8000221e <wakeup+0x64>
    if(p != myproc()){
    800021f6:	00000097          	auipc	ra,0x0
    800021fa:	8b6080e7          	jalr	-1866(ra) # 80001aac <myproc>
    800021fe:	fea488e3          	beq	s1,a0,800021ee <wakeup+0x34>
      acquire(&p->lock);
    80002202:	8526                	mv	a0,s1
    80002204:	fffff097          	auipc	ra,0xfffff
    80002208:	a7c080e7          	jalr	-1412(ra) # 80000c80 <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    8000220c:	4c9c                	lw	a5,24(s1)
    8000220e:	fd379be3          	bne	a5,s3,800021e4 <wakeup+0x2a>
    80002212:	709c                	ld	a5,32(s1)
    80002214:	fd4798e3          	bne	a5,s4,800021e4 <wakeup+0x2a>
        p->state = RUNNABLE;
    80002218:	0154ac23          	sw	s5,24(s1)
    8000221c:	b7e1                	j	800021e4 <wakeup+0x2a>
    }
  }
}
    8000221e:	70e2                	ld	ra,56(sp)
    80002220:	7442                	ld	s0,48(sp)
    80002222:	74a2                	ld	s1,40(sp)
    80002224:	7902                	ld	s2,32(sp)
    80002226:	69e2                	ld	s3,24(sp)
    80002228:	6a42                	ld	s4,16(sp)
    8000222a:	6aa2                	ld	s5,8(sp)
    8000222c:	6121                	addi	sp,sp,64
    8000222e:	8082                	ret

0000000080002230 <reparent>:
{
    80002230:	7179                	addi	sp,sp,-48
    80002232:	f406                	sd	ra,40(sp)
    80002234:	f022                	sd	s0,32(sp)
    80002236:	ec26                	sd	s1,24(sp)
    80002238:	e84a                	sd	s2,16(sp)
    8000223a:	e44e                	sd	s3,8(sp)
    8000223c:	e052                	sd	s4,0(sp)
    8000223e:	1800                	addi	s0,sp,48
    80002240:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002242:	00011497          	auipc	s1,0x11
    80002246:	69e48493          	addi	s1,s1,1694 # 800138e0 <proc>
      pp->parent = initproc;
    8000224a:	00009a17          	auipc	s4,0x9
    8000224e:	feea0a13          	addi	s4,s4,-18 # 8000b238 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002252:	00017997          	auipc	s3,0x17
    80002256:	08e98993          	addi	s3,s3,142 # 800192e0 <tickslock>
    8000225a:	a029                	j	80002264 <reparent+0x34>
    8000225c:	16848493          	addi	s1,s1,360
    80002260:	01348d63          	beq	s1,s3,8000227a <reparent+0x4a>
    if(pp->parent == p){
    80002264:	7c9c                	ld	a5,56(s1)
    80002266:	ff279be3          	bne	a5,s2,8000225c <reparent+0x2c>
      pp->parent = initproc;
    8000226a:	000a3503          	ld	a0,0(s4)
    8000226e:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    80002270:	00000097          	auipc	ra,0x0
    80002274:	f4a080e7          	jalr	-182(ra) # 800021ba <wakeup>
    80002278:	b7d5                	j	8000225c <reparent+0x2c>
}
    8000227a:	70a2                	ld	ra,40(sp)
    8000227c:	7402                	ld	s0,32(sp)
    8000227e:	64e2                	ld	s1,24(sp)
    80002280:	6942                	ld	s2,16(sp)
    80002282:	69a2                	ld	s3,8(sp)
    80002284:	6a02                	ld	s4,0(sp)
    80002286:	6145                	addi	sp,sp,48
    80002288:	8082                	ret

000000008000228a <exit>:
{
    8000228a:	7179                	addi	sp,sp,-48
    8000228c:	f406                	sd	ra,40(sp)
    8000228e:	f022                	sd	s0,32(sp)
    80002290:	ec26                	sd	s1,24(sp)
    80002292:	e84a                	sd	s2,16(sp)
    80002294:	e44e                	sd	s3,8(sp)
    80002296:	e052                	sd	s4,0(sp)
    80002298:	1800                	addi	s0,sp,48
    8000229a:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    8000229c:	00000097          	auipc	ra,0x0
    800022a0:	810080e7          	jalr	-2032(ra) # 80001aac <myproc>
    800022a4:	89aa                	mv	s3,a0
  if(p == initproc)
    800022a6:	00009797          	auipc	a5,0x9
    800022aa:	f927b783          	ld	a5,-110(a5) # 8000b238 <initproc>
    800022ae:	0d050493          	addi	s1,a0,208
    800022b2:	15050913          	addi	s2,a0,336
    800022b6:	02a79363          	bne	a5,a0,800022dc <exit+0x52>
    panic("init exiting");
    800022ba:	00006517          	auipc	a0,0x6
    800022be:	fa650513          	addi	a0,a0,-90 # 80008260 <etext+0x260>
    800022c2:	ffffe097          	auipc	ra,0xffffe
    800022c6:	29e080e7          	jalr	670(ra) # 80000560 <panic>
      fileclose(f);
    800022ca:	00002097          	auipc	ra,0x2
    800022ce:	356080e7          	jalr	854(ra) # 80004620 <fileclose>
      p->ofile[fd] = 0;
    800022d2:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    800022d6:	04a1                	addi	s1,s1,8
    800022d8:	01248563          	beq	s1,s2,800022e2 <exit+0x58>
    if(p->ofile[fd]){
    800022dc:	6088                	ld	a0,0(s1)
    800022de:	f575                	bnez	a0,800022ca <exit+0x40>
    800022e0:	bfdd                	j	800022d6 <exit+0x4c>
  begin_op();
    800022e2:	00002097          	auipc	ra,0x2
    800022e6:	e74080e7          	jalr	-396(ra) # 80004156 <begin_op>
  iput(p->cwd);
    800022ea:	1509b503          	ld	a0,336(s3)
    800022ee:	00001097          	auipc	ra,0x1
    800022f2:	658080e7          	jalr	1624(ra) # 80003946 <iput>
  end_op();
    800022f6:	00002097          	auipc	ra,0x2
    800022fa:	eda080e7          	jalr	-294(ra) # 800041d0 <end_op>
  p->cwd = 0;
    800022fe:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    80002302:	00011497          	auipc	s1,0x11
    80002306:	1c648493          	addi	s1,s1,454 # 800134c8 <wait_lock>
    8000230a:	8526                	mv	a0,s1
    8000230c:	fffff097          	auipc	ra,0xfffff
    80002310:	974080e7          	jalr	-1676(ra) # 80000c80 <acquire>
  reparent(p);
    80002314:	854e                	mv	a0,s3
    80002316:	00000097          	auipc	ra,0x0
    8000231a:	f1a080e7          	jalr	-230(ra) # 80002230 <reparent>
  wakeup(p->parent);
    8000231e:	0389b503          	ld	a0,56(s3)
    80002322:	00000097          	auipc	ra,0x0
    80002326:	e98080e7          	jalr	-360(ra) # 800021ba <wakeup>
  acquire(&p->lock);
    8000232a:	854e                	mv	a0,s3
    8000232c:	fffff097          	auipc	ra,0xfffff
    80002330:	954080e7          	jalr	-1708(ra) # 80000c80 <acquire>
  p->xstate = status;
    80002334:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    80002338:	4795                	li	a5,5
    8000233a:	00f9ac23          	sw	a5,24(s3)
  release(&wait_lock);
    8000233e:	8526                	mv	a0,s1
    80002340:	fffff097          	auipc	ra,0xfffff
    80002344:	9f4080e7          	jalr	-1548(ra) # 80000d34 <release>
  sched();
    80002348:	00000097          	auipc	ra,0x0
    8000234c:	cfc080e7          	jalr	-772(ra) # 80002044 <sched>
  panic("zombie exit");
    80002350:	00006517          	auipc	a0,0x6
    80002354:	f2050513          	addi	a0,a0,-224 # 80008270 <etext+0x270>
    80002358:	ffffe097          	auipc	ra,0xffffe
    8000235c:	208080e7          	jalr	520(ra) # 80000560 <panic>

0000000080002360 <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    80002360:	7179                	addi	sp,sp,-48
    80002362:	f406                	sd	ra,40(sp)
    80002364:	f022                	sd	s0,32(sp)
    80002366:	ec26                	sd	s1,24(sp)
    80002368:	e84a                	sd	s2,16(sp)
    8000236a:	e44e                	sd	s3,8(sp)
    8000236c:	1800                	addi	s0,sp,48
    8000236e:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    80002370:	00011497          	auipc	s1,0x11
    80002374:	57048493          	addi	s1,s1,1392 # 800138e0 <proc>
    80002378:	00017997          	auipc	s3,0x17
    8000237c:	f6898993          	addi	s3,s3,-152 # 800192e0 <tickslock>
    acquire(&p->lock);
    80002380:	8526                	mv	a0,s1
    80002382:	fffff097          	auipc	ra,0xfffff
    80002386:	8fe080e7          	jalr	-1794(ra) # 80000c80 <acquire>
    if(p->pid == pid){
    8000238a:	589c                	lw	a5,48(s1)
    8000238c:	01278d63          	beq	a5,s2,800023a6 <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    80002390:	8526                	mv	a0,s1
    80002392:	fffff097          	auipc	ra,0xfffff
    80002396:	9a2080e7          	jalr	-1630(ra) # 80000d34 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    8000239a:	16848493          	addi	s1,s1,360
    8000239e:	ff3491e3          	bne	s1,s3,80002380 <kill+0x20>
  }
  return -1;
    800023a2:	557d                	li	a0,-1
    800023a4:	a829                	j	800023be <kill+0x5e>
      p->killed = 1;
    800023a6:	4785                	li	a5,1
    800023a8:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    800023aa:	4c98                	lw	a4,24(s1)
    800023ac:	4789                	li	a5,2
    800023ae:	00f70f63          	beq	a4,a5,800023cc <kill+0x6c>
      release(&p->lock);
    800023b2:	8526                	mv	a0,s1
    800023b4:	fffff097          	auipc	ra,0xfffff
    800023b8:	980080e7          	jalr	-1664(ra) # 80000d34 <release>
      return 0;
    800023bc:	4501                	li	a0,0
}
    800023be:	70a2                	ld	ra,40(sp)
    800023c0:	7402                	ld	s0,32(sp)
    800023c2:	64e2                	ld	s1,24(sp)
    800023c4:	6942                	ld	s2,16(sp)
    800023c6:	69a2                	ld	s3,8(sp)
    800023c8:	6145                	addi	sp,sp,48
    800023ca:	8082                	ret
        p->state = RUNNABLE;
    800023cc:	478d                	li	a5,3
    800023ce:	cc9c                	sw	a5,24(s1)
    800023d0:	b7cd                	j	800023b2 <kill+0x52>

00000000800023d2 <setkilled>:

void
setkilled(struct proc *p)
{
    800023d2:	1101                	addi	sp,sp,-32
    800023d4:	ec06                	sd	ra,24(sp)
    800023d6:	e822                	sd	s0,16(sp)
    800023d8:	e426                	sd	s1,8(sp)
    800023da:	1000                	addi	s0,sp,32
    800023dc:	84aa                	mv	s1,a0
  acquire(&p->lock);
    800023de:	fffff097          	auipc	ra,0xfffff
    800023e2:	8a2080e7          	jalr	-1886(ra) # 80000c80 <acquire>
  p->killed = 1;
    800023e6:	4785                	li	a5,1
    800023e8:	d49c                	sw	a5,40(s1)
  release(&p->lock);
    800023ea:	8526                	mv	a0,s1
    800023ec:	fffff097          	auipc	ra,0xfffff
    800023f0:	948080e7          	jalr	-1720(ra) # 80000d34 <release>
}
    800023f4:	60e2                	ld	ra,24(sp)
    800023f6:	6442                	ld	s0,16(sp)
    800023f8:	64a2                	ld	s1,8(sp)
    800023fa:	6105                	addi	sp,sp,32
    800023fc:	8082                	ret

00000000800023fe <killed>:

int
killed(struct proc *p)
{
    800023fe:	1101                	addi	sp,sp,-32
    80002400:	ec06                	sd	ra,24(sp)
    80002402:	e822                	sd	s0,16(sp)
    80002404:	e426                	sd	s1,8(sp)
    80002406:	e04a                	sd	s2,0(sp)
    80002408:	1000                	addi	s0,sp,32
    8000240a:	84aa                	mv	s1,a0
  int k;
  
  acquire(&p->lock);
    8000240c:	fffff097          	auipc	ra,0xfffff
    80002410:	874080e7          	jalr	-1932(ra) # 80000c80 <acquire>
  k = p->killed;
    80002414:	0284a903          	lw	s2,40(s1)
  release(&p->lock);
    80002418:	8526                	mv	a0,s1
    8000241a:	fffff097          	auipc	ra,0xfffff
    8000241e:	91a080e7          	jalr	-1766(ra) # 80000d34 <release>
  return k;
}
    80002422:	854a                	mv	a0,s2
    80002424:	60e2                	ld	ra,24(sp)
    80002426:	6442                	ld	s0,16(sp)
    80002428:	64a2                	ld	s1,8(sp)
    8000242a:	6902                	ld	s2,0(sp)
    8000242c:	6105                	addi	sp,sp,32
    8000242e:	8082                	ret

0000000080002430 <wait>:
{
    80002430:	715d                	addi	sp,sp,-80
    80002432:	e486                	sd	ra,72(sp)
    80002434:	e0a2                	sd	s0,64(sp)
    80002436:	fc26                	sd	s1,56(sp)
    80002438:	f84a                	sd	s2,48(sp)
    8000243a:	f44e                	sd	s3,40(sp)
    8000243c:	f052                	sd	s4,32(sp)
    8000243e:	ec56                	sd	s5,24(sp)
    80002440:	e85a                	sd	s6,16(sp)
    80002442:	e45e                	sd	s7,8(sp)
    80002444:	e062                	sd	s8,0(sp)
    80002446:	0880                	addi	s0,sp,80
    80002448:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    8000244a:	fffff097          	auipc	ra,0xfffff
    8000244e:	662080e7          	jalr	1634(ra) # 80001aac <myproc>
    80002452:	892a                	mv	s2,a0
  acquire(&wait_lock);
    80002454:	00011517          	auipc	a0,0x11
    80002458:	07450513          	addi	a0,a0,116 # 800134c8 <wait_lock>
    8000245c:	fffff097          	auipc	ra,0xfffff
    80002460:	824080e7          	jalr	-2012(ra) # 80000c80 <acquire>
    havekids = 0;
    80002464:	4b81                	li	s7,0
        if(pp->state == ZOMBIE){
    80002466:	4a15                	li	s4,5
        havekids = 1;
    80002468:	4a85                	li	s5,1
    for(pp = proc; pp < &proc[NPROC]; pp++){
    8000246a:	00017997          	auipc	s3,0x17
    8000246e:	e7698993          	addi	s3,s3,-394 # 800192e0 <tickslock>
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002472:	00011c17          	auipc	s8,0x11
    80002476:	056c0c13          	addi	s8,s8,86 # 800134c8 <wait_lock>
    8000247a:	a0d1                	j	8000253e <wait+0x10e>
          pid = pp->pid;
    8000247c:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&pp->xstate,
    80002480:	000b0e63          	beqz	s6,8000249c <wait+0x6c>
    80002484:	4691                	li	a3,4
    80002486:	02c48613          	addi	a2,s1,44
    8000248a:	85da                	mv	a1,s6
    8000248c:	05093503          	ld	a0,80(s2)
    80002490:	fffff097          	auipc	ra,0xfffff
    80002494:	2b4080e7          	jalr	692(ra) # 80001744 <copyout>
    80002498:	04054163          	bltz	a0,800024da <wait+0xaa>
          freeproc(pp);
    8000249c:	8526                	mv	a0,s1
    8000249e:	fffff097          	auipc	ra,0xfffff
    800024a2:	7c0080e7          	jalr	1984(ra) # 80001c5e <freeproc>
          release(&pp->lock);
    800024a6:	8526                	mv	a0,s1
    800024a8:	fffff097          	auipc	ra,0xfffff
    800024ac:	88c080e7          	jalr	-1908(ra) # 80000d34 <release>
          release(&wait_lock);
    800024b0:	00011517          	auipc	a0,0x11
    800024b4:	01850513          	addi	a0,a0,24 # 800134c8 <wait_lock>
    800024b8:	fffff097          	auipc	ra,0xfffff
    800024bc:	87c080e7          	jalr	-1924(ra) # 80000d34 <release>
}
    800024c0:	854e                	mv	a0,s3
    800024c2:	60a6                	ld	ra,72(sp)
    800024c4:	6406                	ld	s0,64(sp)
    800024c6:	74e2                	ld	s1,56(sp)
    800024c8:	7942                	ld	s2,48(sp)
    800024ca:	79a2                	ld	s3,40(sp)
    800024cc:	7a02                	ld	s4,32(sp)
    800024ce:	6ae2                	ld	s5,24(sp)
    800024d0:	6b42                	ld	s6,16(sp)
    800024d2:	6ba2                	ld	s7,8(sp)
    800024d4:	6c02                	ld	s8,0(sp)
    800024d6:	6161                	addi	sp,sp,80
    800024d8:	8082                	ret
            release(&pp->lock);
    800024da:	8526                	mv	a0,s1
    800024dc:	fffff097          	auipc	ra,0xfffff
    800024e0:	858080e7          	jalr	-1960(ra) # 80000d34 <release>
            release(&wait_lock);
    800024e4:	00011517          	auipc	a0,0x11
    800024e8:	fe450513          	addi	a0,a0,-28 # 800134c8 <wait_lock>
    800024ec:	fffff097          	auipc	ra,0xfffff
    800024f0:	848080e7          	jalr	-1976(ra) # 80000d34 <release>
            return -1;
    800024f4:	59fd                	li	s3,-1
    800024f6:	b7e9                	j	800024c0 <wait+0x90>
    for(pp = proc; pp < &proc[NPROC]; pp++){
    800024f8:	16848493          	addi	s1,s1,360
    800024fc:	03348463          	beq	s1,s3,80002524 <wait+0xf4>
      if(pp->parent == p){
    80002500:	7c9c                	ld	a5,56(s1)
    80002502:	ff279be3          	bne	a5,s2,800024f8 <wait+0xc8>
        acquire(&pp->lock);
    80002506:	8526                	mv	a0,s1
    80002508:	ffffe097          	auipc	ra,0xffffe
    8000250c:	778080e7          	jalr	1912(ra) # 80000c80 <acquire>
        if(pp->state == ZOMBIE){
    80002510:	4c9c                	lw	a5,24(s1)
    80002512:	f74785e3          	beq	a5,s4,8000247c <wait+0x4c>
        release(&pp->lock);
    80002516:	8526                	mv	a0,s1
    80002518:	fffff097          	auipc	ra,0xfffff
    8000251c:	81c080e7          	jalr	-2020(ra) # 80000d34 <release>
        havekids = 1;
    80002520:	8756                	mv	a4,s5
    80002522:	bfd9                	j	800024f8 <wait+0xc8>
    if(!havekids || killed(p)){
    80002524:	c31d                	beqz	a4,8000254a <wait+0x11a>
    80002526:	854a                	mv	a0,s2
    80002528:	00000097          	auipc	ra,0x0
    8000252c:	ed6080e7          	jalr	-298(ra) # 800023fe <killed>
    80002530:	ed09                	bnez	a0,8000254a <wait+0x11a>
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002532:	85e2                	mv	a1,s8
    80002534:	854a                	mv	a0,s2
    80002536:	00000097          	auipc	ra,0x0
    8000253a:	c20080e7          	jalr	-992(ra) # 80002156 <sleep>
    havekids = 0;
    8000253e:	875e                	mv	a4,s7
    for(pp = proc; pp < &proc[NPROC]; pp++){
    80002540:	00011497          	auipc	s1,0x11
    80002544:	3a048493          	addi	s1,s1,928 # 800138e0 <proc>
    80002548:	bf65                	j	80002500 <wait+0xd0>
      release(&wait_lock);
    8000254a:	00011517          	auipc	a0,0x11
    8000254e:	f7e50513          	addi	a0,a0,-130 # 800134c8 <wait_lock>
    80002552:	ffffe097          	auipc	ra,0xffffe
    80002556:	7e2080e7          	jalr	2018(ra) # 80000d34 <release>
      return -1;
    8000255a:	59fd                	li	s3,-1
    8000255c:	b795                	j	800024c0 <wait+0x90>

000000008000255e <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    8000255e:	7179                	addi	sp,sp,-48
    80002560:	f406                	sd	ra,40(sp)
    80002562:	f022                	sd	s0,32(sp)
    80002564:	ec26                	sd	s1,24(sp)
    80002566:	e84a                	sd	s2,16(sp)
    80002568:	e44e                	sd	s3,8(sp)
    8000256a:	e052                	sd	s4,0(sp)
    8000256c:	1800                	addi	s0,sp,48
    8000256e:	84aa                	mv	s1,a0
    80002570:	892e                	mv	s2,a1
    80002572:	89b2                	mv	s3,a2
    80002574:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002576:	fffff097          	auipc	ra,0xfffff
    8000257a:	536080e7          	jalr	1334(ra) # 80001aac <myproc>
  if(user_dst){
    8000257e:	c08d                	beqz	s1,800025a0 <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    80002580:	86d2                	mv	a3,s4
    80002582:	864e                	mv	a2,s3
    80002584:	85ca                	mv	a1,s2
    80002586:	6928                	ld	a0,80(a0)
    80002588:	fffff097          	auipc	ra,0xfffff
    8000258c:	1bc080e7          	jalr	444(ra) # 80001744 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    80002590:	70a2                	ld	ra,40(sp)
    80002592:	7402                	ld	s0,32(sp)
    80002594:	64e2                	ld	s1,24(sp)
    80002596:	6942                	ld	s2,16(sp)
    80002598:	69a2                	ld	s3,8(sp)
    8000259a:	6a02                	ld	s4,0(sp)
    8000259c:	6145                	addi	sp,sp,48
    8000259e:	8082                	ret
    memmove((char *)dst, src, len);
    800025a0:	000a061b          	sext.w	a2,s4
    800025a4:	85ce                	mv	a1,s3
    800025a6:	854a                	mv	a0,s2
    800025a8:	fffff097          	auipc	ra,0xfffff
    800025ac:	830080e7          	jalr	-2000(ra) # 80000dd8 <memmove>
    return 0;
    800025b0:	8526                	mv	a0,s1
    800025b2:	bff9                	j	80002590 <either_copyout+0x32>

00000000800025b4 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    800025b4:	7179                	addi	sp,sp,-48
    800025b6:	f406                	sd	ra,40(sp)
    800025b8:	f022                	sd	s0,32(sp)
    800025ba:	ec26                	sd	s1,24(sp)
    800025bc:	e84a                	sd	s2,16(sp)
    800025be:	e44e                	sd	s3,8(sp)
    800025c0:	e052                	sd	s4,0(sp)
    800025c2:	1800                	addi	s0,sp,48
    800025c4:	892a                	mv	s2,a0
    800025c6:	84ae                	mv	s1,a1
    800025c8:	89b2                	mv	s3,a2
    800025ca:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800025cc:	fffff097          	auipc	ra,0xfffff
    800025d0:	4e0080e7          	jalr	1248(ra) # 80001aac <myproc>
  if(user_src){
    800025d4:	c08d                	beqz	s1,800025f6 <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    800025d6:	86d2                	mv	a3,s4
    800025d8:	864e                	mv	a2,s3
    800025da:	85ca                	mv	a1,s2
    800025dc:	6928                	ld	a0,80(a0)
    800025de:	fffff097          	auipc	ra,0xfffff
    800025e2:	1f2080e7          	jalr	498(ra) # 800017d0 <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    800025e6:	70a2                	ld	ra,40(sp)
    800025e8:	7402                	ld	s0,32(sp)
    800025ea:	64e2                	ld	s1,24(sp)
    800025ec:	6942                	ld	s2,16(sp)
    800025ee:	69a2                	ld	s3,8(sp)
    800025f0:	6a02                	ld	s4,0(sp)
    800025f2:	6145                	addi	sp,sp,48
    800025f4:	8082                	ret
    memmove(dst, (char*)src, len);
    800025f6:	000a061b          	sext.w	a2,s4
    800025fa:	85ce                	mv	a1,s3
    800025fc:	854a                	mv	a0,s2
    800025fe:	ffffe097          	auipc	ra,0xffffe
    80002602:	7da080e7          	jalr	2010(ra) # 80000dd8 <memmove>
    return 0;
    80002606:	8526                	mv	a0,s1
    80002608:	bff9                	j	800025e6 <either_copyin+0x32>

000000008000260a <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    8000260a:	715d                	addi	sp,sp,-80
    8000260c:	e486                	sd	ra,72(sp)
    8000260e:	e0a2                	sd	s0,64(sp)
    80002610:	fc26                	sd	s1,56(sp)
    80002612:	f84a                	sd	s2,48(sp)
    80002614:	f44e                	sd	s3,40(sp)
    80002616:	f052                	sd	s4,32(sp)
    80002618:	ec56                	sd	s5,24(sp)
    8000261a:	e85a                	sd	s6,16(sp)
    8000261c:	e45e                	sd	s7,8(sp)
    8000261e:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    80002620:	00006517          	auipc	a0,0x6
    80002624:	9f050513          	addi	a0,a0,-1552 # 80008010 <etext+0x10>
    80002628:	ffffe097          	auipc	ra,0xffffe
    8000262c:	f82080e7          	jalr	-126(ra) # 800005aa <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002630:	00011497          	auipc	s1,0x11
    80002634:	40848493          	addi	s1,s1,1032 # 80013a38 <proc+0x158>
    80002638:	00017917          	auipc	s2,0x17
    8000263c:	e0090913          	addi	s2,s2,-512 # 80019438 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002640:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    80002642:	00006997          	auipc	s3,0x6
    80002646:	c3e98993          	addi	s3,s3,-962 # 80008280 <etext+0x280>
    printf("%d %s %s", p->pid, state, p->name);
    8000264a:	00006a97          	auipc	s5,0x6
    8000264e:	c3ea8a93          	addi	s5,s5,-962 # 80008288 <etext+0x288>
    printf("\n");
    80002652:	00006a17          	auipc	s4,0x6
    80002656:	9bea0a13          	addi	s4,s4,-1602 # 80008010 <etext+0x10>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000265a:	00006b97          	auipc	s7,0x6
    8000265e:	106b8b93          	addi	s7,s7,262 # 80008760 <states.0>
    80002662:	a00d                	j	80002684 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    80002664:	ed86a583          	lw	a1,-296(a3)
    80002668:	8556                	mv	a0,s5
    8000266a:	ffffe097          	auipc	ra,0xffffe
    8000266e:	f40080e7          	jalr	-192(ra) # 800005aa <printf>
    printf("\n");
    80002672:	8552                	mv	a0,s4
    80002674:	ffffe097          	auipc	ra,0xffffe
    80002678:	f36080e7          	jalr	-202(ra) # 800005aa <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    8000267c:	16848493          	addi	s1,s1,360
    80002680:	03248263          	beq	s1,s2,800026a4 <procdump+0x9a>
    if(p->state == UNUSED)
    80002684:	86a6                	mv	a3,s1
    80002686:	ec04a783          	lw	a5,-320(s1)
    8000268a:	dbed                	beqz	a5,8000267c <procdump+0x72>
      state = "???";
    8000268c:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000268e:	fcfb6be3          	bltu	s6,a5,80002664 <procdump+0x5a>
    80002692:	02079713          	slli	a4,a5,0x20
    80002696:	01d75793          	srli	a5,a4,0x1d
    8000269a:	97de                	add	a5,a5,s7
    8000269c:	6390                	ld	a2,0(a5)
    8000269e:	f279                	bnez	a2,80002664 <procdump+0x5a>
      state = "???";
    800026a0:	864e                	mv	a2,s3
    800026a2:	b7c9                	j	80002664 <procdump+0x5a>
  }
}
    800026a4:	60a6                	ld	ra,72(sp)
    800026a6:	6406                	ld	s0,64(sp)
    800026a8:	74e2                	ld	s1,56(sp)
    800026aa:	7942                	ld	s2,48(sp)
    800026ac:	79a2                	ld	s3,40(sp)
    800026ae:	7a02                	ld	s4,32(sp)
    800026b0:	6ae2                	ld	s5,24(sp)
    800026b2:	6b42                	ld	s6,16(sp)
    800026b4:	6ba2                	ld	s7,8(sp)
    800026b6:	6161                	addi	sp,sp,80
    800026b8:	8082                	ret

00000000800026ba <swtch>:
    800026ba:	00153023          	sd	ra,0(a0)
    800026be:	00253423          	sd	sp,8(a0)
    800026c2:	e900                	sd	s0,16(a0)
    800026c4:	ed04                	sd	s1,24(a0)
    800026c6:	03253023          	sd	s2,32(a0)
    800026ca:	03353423          	sd	s3,40(a0)
    800026ce:	03453823          	sd	s4,48(a0)
    800026d2:	03553c23          	sd	s5,56(a0)
    800026d6:	05653023          	sd	s6,64(a0)
    800026da:	05753423          	sd	s7,72(a0)
    800026de:	05853823          	sd	s8,80(a0)
    800026e2:	05953c23          	sd	s9,88(a0)
    800026e6:	07a53023          	sd	s10,96(a0)
    800026ea:	07b53423          	sd	s11,104(a0)
    800026ee:	0005b083          	ld	ra,0(a1)
    800026f2:	0085b103          	ld	sp,8(a1)
    800026f6:	6980                	ld	s0,16(a1)
    800026f8:	6d84                	ld	s1,24(a1)
    800026fa:	0205b903          	ld	s2,32(a1)
    800026fe:	0285b983          	ld	s3,40(a1)
    80002702:	0305ba03          	ld	s4,48(a1)
    80002706:	0385ba83          	ld	s5,56(a1)
    8000270a:	0405bb03          	ld	s6,64(a1)
    8000270e:	0485bb83          	ld	s7,72(a1)
    80002712:	0505bc03          	ld	s8,80(a1)
    80002716:	0585bc83          	ld	s9,88(a1)
    8000271a:	0605bd03          	ld	s10,96(a1)
    8000271e:	0685bd83          	ld	s11,104(a1)
    80002722:	8082                	ret

0000000080002724 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    80002724:	1141                	addi	sp,sp,-16
    80002726:	e406                	sd	ra,8(sp)
    80002728:	e022                	sd	s0,0(sp)
    8000272a:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    8000272c:	00006597          	auipc	a1,0x6
    80002730:	b9c58593          	addi	a1,a1,-1124 # 800082c8 <etext+0x2c8>
    80002734:	00017517          	auipc	a0,0x17
    80002738:	bac50513          	addi	a0,a0,-1108 # 800192e0 <tickslock>
    8000273c:	ffffe097          	auipc	ra,0xffffe
    80002740:	4b4080e7          	jalr	1204(ra) # 80000bf0 <initlock>
}
    80002744:	60a2                	ld	ra,8(sp)
    80002746:	6402                	ld	s0,0(sp)
    80002748:	0141                	addi	sp,sp,16
    8000274a:	8082                	ret

000000008000274c <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    8000274c:	1141                	addi	sp,sp,-16
    8000274e:	e422                	sd	s0,8(sp)
    80002750:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002752:	00003797          	auipc	a5,0x3
    80002756:	5ce78793          	addi	a5,a5,1486 # 80005d20 <kernelvec>
    8000275a:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    8000275e:	6422                	ld	s0,8(sp)
    80002760:	0141                	addi	sp,sp,16
    80002762:	8082                	ret

0000000080002764 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002764:	1141                	addi	sp,sp,-16
    80002766:	e406                	sd	ra,8(sp)
    80002768:	e022                	sd	s0,0(sp)
    8000276a:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    8000276c:	fffff097          	auipc	ra,0xfffff
    80002770:	340080e7          	jalr	832(ra) # 80001aac <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002774:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002778:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000277a:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to uservec in trampoline.S
  uint64 trampoline_uservec = TRAMPOLINE + (uservec - trampoline);
    8000277e:	00005697          	auipc	a3,0x5
    80002782:	88268693          	addi	a3,a3,-1918 # 80007000 <_trampoline>
    80002786:	00005717          	auipc	a4,0x5
    8000278a:	87a70713          	addi	a4,a4,-1926 # 80007000 <_trampoline>
    8000278e:	8f15                	sub	a4,a4,a3
    80002790:	040007b7          	lui	a5,0x4000
    80002794:	17fd                	addi	a5,a5,-1 # 3ffffff <_entry-0x7c000001>
    80002796:	07b2                	slli	a5,a5,0xc
    80002798:	973e                	add	a4,a4,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    8000279a:	10571073          	csrw	stvec,a4
  w_stvec(trampoline_uservec);

  // set up trapframe values that uservec will need when
  // the process next traps into the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    8000279e:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    800027a0:	18002673          	csrr	a2,satp
    800027a4:	e310                	sd	a2,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    800027a6:	6d30                	ld	a2,88(a0)
    800027a8:	6138                	ld	a4,64(a0)
    800027aa:	6585                	lui	a1,0x1
    800027ac:	972e                	add	a4,a4,a1
    800027ae:	e618                	sd	a4,8(a2)
  p->trapframe->kernel_trap = (uint64)usertrap;
    800027b0:	6d38                	ld	a4,88(a0)
    800027b2:	00000617          	auipc	a2,0x0
    800027b6:	13860613          	addi	a2,a2,312 # 800028ea <usertrap>
    800027ba:	eb10                	sd	a2,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    800027bc:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    800027be:	8612                	mv	a2,tp
    800027c0:	f310                	sd	a2,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800027c2:	10002773          	csrr	a4,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    800027c6:	eff77713          	andi	a4,a4,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    800027ca:	02076713          	ori	a4,a4,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800027ce:	10071073          	csrw	sstatus,a4
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    800027d2:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    800027d4:	6f18                	ld	a4,24(a4)
    800027d6:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    800027da:	6928                	ld	a0,80(a0)
    800027dc:	8131                	srli	a0,a0,0xc

  // jump to userret in trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 trampoline_userret = TRAMPOLINE + (userret - trampoline);
    800027de:	00005717          	auipc	a4,0x5
    800027e2:	8be70713          	addi	a4,a4,-1858 # 8000709c <userret>
    800027e6:	8f15                	sub	a4,a4,a3
    800027e8:	97ba                	add	a5,a5,a4
  ((void (*)(uint64))trampoline_userret)(satp);
    800027ea:	577d                	li	a4,-1
    800027ec:	177e                	slli	a4,a4,0x3f
    800027ee:	8d59                	or	a0,a0,a4
    800027f0:	9782                	jalr	a5
}
    800027f2:	60a2                	ld	ra,8(sp)
    800027f4:	6402                	ld	s0,0(sp)
    800027f6:	0141                	addi	sp,sp,16
    800027f8:	8082                	ret

00000000800027fa <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    800027fa:	1101                	addi	sp,sp,-32
    800027fc:	ec06                	sd	ra,24(sp)
    800027fe:	e822                	sd	s0,16(sp)
    80002800:	e426                	sd	s1,8(sp)
    80002802:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002804:	00017497          	auipc	s1,0x17
    80002808:	adc48493          	addi	s1,s1,-1316 # 800192e0 <tickslock>
    8000280c:	8526                	mv	a0,s1
    8000280e:	ffffe097          	auipc	ra,0xffffe
    80002812:	472080e7          	jalr	1138(ra) # 80000c80 <acquire>
  ticks++;
    80002816:	00009517          	auipc	a0,0x9
    8000281a:	a2a50513          	addi	a0,a0,-1494 # 8000b240 <ticks>
    8000281e:	411c                	lw	a5,0(a0)
    80002820:	2785                	addiw	a5,a5,1
    80002822:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80002824:	00000097          	auipc	ra,0x0
    80002828:	996080e7          	jalr	-1642(ra) # 800021ba <wakeup>
  release(&tickslock);
    8000282c:	8526                	mv	a0,s1
    8000282e:	ffffe097          	auipc	ra,0xffffe
    80002832:	506080e7          	jalr	1286(ra) # 80000d34 <release>
}
    80002836:	60e2                	ld	ra,24(sp)
    80002838:	6442                	ld	s0,16(sp)
    8000283a:	64a2                	ld	s1,8(sp)
    8000283c:	6105                	addi	sp,sp,32
    8000283e:	8082                	ret

0000000080002840 <devintr>:
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002840:	142027f3          	csrr	a5,scause
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002844:	4501                	li	a0,0
  if((scause & 0x8000000000000000L) &&
    80002846:	0a07d163          	bgez	a5,800028e8 <devintr+0xa8>
{
    8000284a:	1101                	addi	sp,sp,-32
    8000284c:	ec06                	sd	ra,24(sp)
    8000284e:	e822                	sd	s0,16(sp)
    80002850:	1000                	addi	s0,sp,32
     (scause & 0xff) == 9){
    80002852:	0ff7f713          	zext.b	a4,a5
  if((scause & 0x8000000000000000L) &&
    80002856:	46a5                	li	a3,9
    80002858:	00d70c63          	beq	a4,a3,80002870 <devintr+0x30>
  } else if(scause == 0x8000000000000001L){
    8000285c:	577d                	li	a4,-1
    8000285e:	177e                	slli	a4,a4,0x3f
    80002860:	0705                	addi	a4,a4,1
    return 0;
    80002862:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002864:	06e78163          	beq	a5,a4,800028c6 <devintr+0x86>
  }
}
    80002868:	60e2                	ld	ra,24(sp)
    8000286a:	6442                	ld	s0,16(sp)
    8000286c:	6105                	addi	sp,sp,32
    8000286e:	8082                	ret
    80002870:	e426                	sd	s1,8(sp)
    int irq = plic_claim();
    80002872:	00003097          	auipc	ra,0x3
    80002876:	5ba080e7          	jalr	1466(ra) # 80005e2c <plic_claim>
    8000287a:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    8000287c:	47a9                	li	a5,10
    8000287e:	00f50963          	beq	a0,a5,80002890 <devintr+0x50>
    } else if(irq == VIRTIO0_IRQ){
    80002882:	4785                	li	a5,1
    80002884:	00f50b63          	beq	a0,a5,8000289a <devintr+0x5a>
    return 1;
    80002888:	4505                	li	a0,1
    } else if(irq){
    8000288a:	ec89                	bnez	s1,800028a4 <devintr+0x64>
    8000288c:	64a2                	ld	s1,8(sp)
    8000288e:	bfe9                	j	80002868 <devintr+0x28>
      uartintr();
    80002890:	ffffe097          	auipc	ra,0xffffe
    80002894:	16a080e7          	jalr	362(ra) # 800009fa <uartintr>
    if(irq)
    80002898:	a839                	j	800028b6 <devintr+0x76>
      virtio_disk_intr();
    8000289a:	00004097          	auipc	ra,0x4
    8000289e:	abc080e7          	jalr	-1348(ra) # 80006356 <virtio_disk_intr>
    if(irq)
    800028a2:	a811                	j	800028b6 <devintr+0x76>
      printf("unexpected interrupt irq=%d\n", irq);
    800028a4:	85a6                	mv	a1,s1
    800028a6:	00006517          	auipc	a0,0x6
    800028aa:	a2a50513          	addi	a0,a0,-1494 # 800082d0 <etext+0x2d0>
    800028ae:	ffffe097          	auipc	ra,0xffffe
    800028b2:	cfc080e7          	jalr	-772(ra) # 800005aa <printf>
      plic_complete(irq);
    800028b6:	8526                	mv	a0,s1
    800028b8:	00003097          	auipc	ra,0x3
    800028bc:	598080e7          	jalr	1432(ra) # 80005e50 <plic_complete>
    return 1;
    800028c0:	4505                	li	a0,1
    800028c2:	64a2                	ld	s1,8(sp)
    800028c4:	b755                	j	80002868 <devintr+0x28>
    if(cpuid() == 0){
    800028c6:	fffff097          	auipc	ra,0xfffff
    800028ca:	1ba080e7          	jalr	442(ra) # 80001a80 <cpuid>
    800028ce:	c901                	beqz	a0,800028de <devintr+0x9e>
  asm volatile("csrr %0, sip" : "=r" (x) );
    800028d0:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    800028d4:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    800028d6:	14479073          	csrw	sip,a5
    return 2;
    800028da:	4509                	li	a0,2
    800028dc:	b771                	j	80002868 <devintr+0x28>
      clockintr();
    800028de:	00000097          	auipc	ra,0x0
    800028e2:	f1c080e7          	jalr	-228(ra) # 800027fa <clockintr>
    800028e6:	b7ed                	j	800028d0 <devintr+0x90>
}
    800028e8:	8082                	ret

00000000800028ea <usertrap>:
{
    800028ea:	1101                	addi	sp,sp,-32
    800028ec:	ec06                	sd	ra,24(sp)
    800028ee:	e822                	sd	s0,16(sp)
    800028f0:	e426                	sd	s1,8(sp)
    800028f2:	e04a                	sd	s2,0(sp)
    800028f4:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800028f6:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    800028fa:	1007f793          	andi	a5,a5,256
    800028fe:	e3b1                	bnez	a5,80002942 <usertrap+0x58>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002900:	00003797          	auipc	a5,0x3
    80002904:	42078793          	addi	a5,a5,1056 # 80005d20 <kernelvec>
    80002908:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    8000290c:	fffff097          	auipc	ra,0xfffff
    80002910:	1a0080e7          	jalr	416(ra) # 80001aac <myproc>
    80002914:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002916:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002918:	14102773          	csrr	a4,sepc
    8000291c:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    8000291e:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002922:	47a1                	li	a5,8
    80002924:	02f70763          	beq	a4,a5,80002952 <usertrap+0x68>
  } else if((which_dev = devintr()) != 0){
    80002928:	00000097          	auipc	ra,0x0
    8000292c:	f18080e7          	jalr	-232(ra) # 80002840 <devintr>
    80002930:	892a                	mv	s2,a0
    80002932:	c151                	beqz	a0,800029b6 <usertrap+0xcc>
  if(killed(p))
    80002934:	8526                	mv	a0,s1
    80002936:	00000097          	auipc	ra,0x0
    8000293a:	ac8080e7          	jalr	-1336(ra) # 800023fe <killed>
    8000293e:	c929                	beqz	a0,80002990 <usertrap+0xa6>
    80002940:	a099                	j	80002986 <usertrap+0x9c>
    panic("usertrap: not from user mode");
    80002942:	00006517          	auipc	a0,0x6
    80002946:	9ae50513          	addi	a0,a0,-1618 # 800082f0 <etext+0x2f0>
    8000294a:	ffffe097          	auipc	ra,0xffffe
    8000294e:	c16080e7          	jalr	-1002(ra) # 80000560 <panic>
    if(killed(p))
    80002952:	00000097          	auipc	ra,0x0
    80002956:	aac080e7          	jalr	-1364(ra) # 800023fe <killed>
    8000295a:	e921                	bnez	a0,800029aa <usertrap+0xc0>
    p->trapframe->epc += 4;
    8000295c:	6cb8                	ld	a4,88(s1)
    8000295e:	6f1c                	ld	a5,24(a4)
    80002960:	0791                	addi	a5,a5,4
    80002962:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002964:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002968:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000296c:	10079073          	csrw	sstatus,a5
    syscall();
    80002970:	00000097          	auipc	ra,0x0
    80002974:	2d4080e7          	jalr	724(ra) # 80002c44 <syscall>
  if(killed(p))
    80002978:	8526                	mv	a0,s1
    8000297a:	00000097          	auipc	ra,0x0
    8000297e:	a84080e7          	jalr	-1404(ra) # 800023fe <killed>
    80002982:	c911                	beqz	a0,80002996 <usertrap+0xac>
    80002984:	4901                	li	s2,0
    exit(-1);
    80002986:	557d                	li	a0,-1
    80002988:	00000097          	auipc	ra,0x0
    8000298c:	902080e7          	jalr	-1790(ra) # 8000228a <exit>
  if(which_dev == 2)
    80002990:	4789                	li	a5,2
    80002992:	04f90f63          	beq	s2,a5,800029f0 <usertrap+0x106>
  usertrapret();
    80002996:	00000097          	auipc	ra,0x0
    8000299a:	dce080e7          	jalr	-562(ra) # 80002764 <usertrapret>
}
    8000299e:	60e2                	ld	ra,24(sp)
    800029a0:	6442                	ld	s0,16(sp)
    800029a2:	64a2                	ld	s1,8(sp)
    800029a4:	6902                	ld	s2,0(sp)
    800029a6:	6105                	addi	sp,sp,32
    800029a8:	8082                	ret
      exit(-1);
    800029aa:	557d                	li	a0,-1
    800029ac:	00000097          	auipc	ra,0x0
    800029b0:	8de080e7          	jalr	-1826(ra) # 8000228a <exit>
    800029b4:	b765                	j	8000295c <usertrap+0x72>
  asm volatile("csrr %0, scause" : "=r" (x) );
    800029b6:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    800029ba:	5890                	lw	a2,48(s1)
    800029bc:	00006517          	auipc	a0,0x6
    800029c0:	95450513          	addi	a0,a0,-1708 # 80008310 <etext+0x310>
    800029c4:	ffffe097          	auipc	ra,0xffffe
    800029c8:	be6080e7          	jalr	-1050(ra) # 800005aa <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800029cc:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    800029d0:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    800029d4:	00006517          	auipc	a0,0x6
    800029d8:	96c50513          	addi	a0,a0,-1684 # 80008340 <etext+0x340>
    800029dc:	ffffe097          	auipc	ra,0xffffe
    800029e0:	bce080e7          	jalr	-1074(ra) # 800005aa <printf>
    setkilled(p);
    800029e4:	8526                	mv	a0,s1
    800029e6:	00000097          	auipc	ra,0x0
    800029ea:	9ec080e7          	jalr	-1556(ra) # 800023d2 <setkilled>
    800029ee:	b769                	j	80002978 <usertrap+0x8e>
    yield();
    800029f0:	fffff097          	auipc	ra,0xfffff
    800029f4:	72a080e7          	jalr	1834(ra) # 8000211a <yield>
    800029f8:	bf79                	j	80002996 <usertrap+0xac>

00000000800029fa <kerneltrap>:
{
    800029fa:	7179                	addi	sp,sp,-48
    800029fc:	f406                	sd	ra,40(sp)
    800029fe:	f022                	sd	s0,32(sp)
    80002a00:	ec26                	sd	s1,24(sp)
    80002a02:	e84a                	sd	s2,16(sp)
    80002a04:	e44e                	sd	s3,8(sp)
    80002a06:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002a08:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a0c:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002a10:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002a14:	1004f793          	andi	a5,s1,256
    80002a18:	cb85                	beqz	a5,80002a48 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a1a:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002a1e:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002a20:	ef85                	bnez	a5,80002a58 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002a22:	00000097          	auipc	ra,0x0
    80002a26:	e1e080e7          	jalr	-482(ra) # 80002840 <devintr>
    80002a2a:	cd1d                	beqz	a0,80002a68 <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002a2c:	4789                	li	a5,2
    80002a2e:	06f50a63          	beq	a0,a5,80002aa2 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002a32:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002a36:	10049073          	csrw	sstatus,s1
}
    80002a3a:	70a2                	ld	ra,40(sp)
    80002a3c:	7402                	ld	s0,32(sp)
    80002a3e:	64e2                	ld	s1,24(sp)
    80002a40:	6942                	ld	s2,16(sp)
    80002a42:	69a2                	ld	s3,8(sp)
    80002a44:	6145                	addi	sp,sp,48
    80002a46:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002a48:	00006517          	auipc	a0,0x6
    80002a4c:	91850513          	addi	a0,a0,-1768 # 80008360 <etext+0x360>
    80002a50:	ffffe097          	auipc	ra,0xffffe
    80002a54:	b10080e7          	jalr	-1264(ra) # 80000560 <panic>
    panic("kerneltrap: interrupts enabled");
    80002a58:	00006517          	auipc	a0,0x6
    80002a5c:	93050513          	addi	a0,a0,-1744 # 80008388 <etext+0x388>
    80002a60:	ffffe097          	auipc	ra,0xffffe
    80002a64:	b00080e7          	jalr	-1280(ra) # 80000560 <panic>
    printf("scause %p\n", scause);
    80002a68:	85ce                	mv	a1,s3
    80002a6a:	00006517          	auipc	a0,0x6
    80002a6e:	93e50513          	addi	a0,a0,-1730 # 800083a8 <etext+0x3a8>
    80002a72:	ffffe097          	auipc	ra,0xffffe
    80002a76:	b38080e7          	jalr	-1224(ra) # 800005aa <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002a7a:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002a7e:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002a82:	00006517          	auipc	a0,0x6
    80002a86:	93650513          	addi	a0,a0,-1738 # 800083b8 <etext+0x3b8>
    80002a8a:	ffffe097          	auipc	ra,0xffffe
    80002a8e:	b20080e7          	jalr	-1248(ra) # 800005aa <printf>
    panic("kerneltrap");
    80002a92:	00006517          	auipc	a0,0x6
    80002a96:	93e50513          	addi	a0,a0,-1730 # 800083d0 <etext+0x3d0>
    80002a9a:	ffffe097          	auipc	ra,0xffffe
    80002a9e:	ac6080e7          	jalr	-1338(ra) # 80000560 <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002aa2:	fffff097          	auipc	ra,0xfffff
    80002aa6:	00a080e7          	jalr	10(ra) # 80001aac <myproc>
    80002aaa:	d541                	beqz	a0,80002a32 <kerneltrap+0x38>
    80002aac:	fffff097          	auipc	ra,0xfffff
    80002ab0:	000080e7          	jalr	ra # 80001aac <myproc>
    80002ab4:	4d18                	lw	a4,24(a0)
    80002ab6:	4791                	li	a5,4
    80002ab8:	f6f71de3          	bne	a4,a5,80002a32 <kerneltrap+0x38>
    yield();
    80002abc:	fffff097          	auipc	ra,0xfffff
    80002ac0:	65e080e7          	jalr	1630(ra) # 8000211a <yield>
    80002ac4:	b7bd                	j	80002a32 <kerneltrap+0x38>

0000000080002ac6 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002ac6:	1101                	addi	sp,sp,-32
    80002ac8:	ec06                	sd	ra,24(sp)
    80002aca:	e822                	sd	s0,16(sp)
    80002acc:	e426                	sd	s1,8(sp)
    80002ace:	1000                	addi	s0,sp,32
    80002ad0:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002ad2:	fffff097          	auipc	ra,0xfffff
    80002ad6:	fda080e7          	jalr	-38(ra) # 80001aac <myproc>
  switch (n) {
    80002ada:	4795                	li	a5,5
    80002adc:	0497e163          	bltu	a5,s1,80002b1e <argraw+0x58>
    80002ae0:	048a                	slli	s1,s1,0x2
    80002ae2:	00006717          	auipc	a4,0x6
    80002ae6:	cae70713          	addi	a4,a4,-850 # 80008790 <states.0+0x30>
    80002aea:	94ba                	add	s1,s1,a4
    80002aec:	409c                	lw	a5,0(s1)
    80002aee:	97ba                	add	a5,a5,a4
    80002af0:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002af2:	6d3c                	ld	a5,88(a0)
    80002af4:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002af6:	60e2                	ld	ra,24(sp)
    80002af8:	6442                	ld	s0,16(sp)
    80002afa:	64a2                	ld	s1,8(sp)
    80002afc:	6105                	addi	sp,sp,32
    80002afe:	8082                	ret
    return p->trapframe->a1;
    80002b00:	6d3c                	ld	a5,88(a0)
    80002b02:	7fa8                	ld	a0,120(a5)
    80002b04:	bfcd                	j	80002af6 <argraw+0x30>
    return p->trapframe->a2;
    80002b06:	6d3c                	ld	a5,88(a0)
    80002b08:	63c8                	ld	a0,128(a5)
    80002b0a:	b7f5                	j	80002af6 <argraw+0x30>
    return p->trapframe->a3;
    80002b0c:	6d3c                	ld	a5,88(a0)
    80002b0e:	67c8                	ld	a0,136(a5)
    80002b10:	b7dd                	j	80002af6 <argraw+0x30>
    return p->trapframe->a4;
    80002b12:	6d3c                	ld	a5,88(a0)
    80002b14:	6bc8                	ld	a0,144(a5)
    80002b16:	b7c5                	j	80002af6 <argraw+0x30>
    return p->trapframe->a5;
    80002b18:	6d3c                	ld	a5,88(a0)
    80002b1a:	6fc8                	ld	a0,152(a5)
    80002b1c:	bfe9                	j	80002af6 <argraw+0x30>
  panic("argraw");
    80002b1e:	00006517          	auipc	a0,0x6
    80002b22:	8c250513          	addi	a0,a0,-1854 # 800083e0 <etext+0x3e0>
    80002b26:	ffffe097          	auipc	ra,0xffffe
    80002b2a:	a3a080e7          	jalr	-1478(ra) # 80000560 <panic>

0000000080002b2e <fetchaddr>:
{
    80002b2e:	1101                	addi	sp,sp,-32
    80002b30:	ec06                	sd	ra,24(sp)
    80002b32:	e822                	sd	s0,16(sp)
    80002b34:	e426                	sd	s1,8(sp)
    80002b36:	e04a                	sd	s2,0(sp)
    80002b38:	1000                	addi	s0,sp,32
    80002b3a:	84aa                	mv	s1,a0
    80002b3c:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002b3e:	fffff097          	auipc	ra,0xfffff
    80002b42:	f6e080e7          	jalr	-146(ra) # 80001aac <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz) // both tests needed, in case of overflow
    80002b46:	653c                	ld	a5,72(a0)
    80002b48:	02f4f863          	bgeu	s1,a5,80002b78 <fetchaddr+0x4a>
    80002b4c:	00848713          	addi	a4,s1,8
    80002b50:	02e7e663          	bltu	a5,a4,80002b7c <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002b54:	46a1                	li	a3,8
    80002b56:	8626                	mv	a2,s1
    80002b58:	85ca                	mv	a1,s2
    80002b5a:	6928                	ld	a0,80(a0)
    80002b5c:	fffff097          	auipc	ra,0xfffff
    80002b60:	c74080e7          	jalr	-908(ra) # 800017d0 <copyin>
    80002b64:	00a03533          	snez	a0,a0
    80002b68:	40a00533          	neg	a0,a0
}
    80002b6c:	60e2                	ld	ra,24(sp)
    80002b6e:	6442                	ld	s0,16(sp)
    80002b70:	64a2                	ld	s1,8(sp)
    80002b72:	6902                	ld	s2,0(sp)
    80002b74:	6105                	addi	sp,sp,32
    80002b76:	8082                	ret
    return -1;
    80002b78:	557d                	li	a0,-1
    80002b7a:	bfcd                	j	80002b6c <fetchaddr+0x3e>
    80002b7c:	557d                	li	a0,-1
    80002b7e:	b7fd                	j	80002b6c <fetchaddr+0x3e>

0000000080002b80 <fetchstr>:
{
    80002b80:	7179                	addi	sp,sp,-48
    80002b82:	f406                	sd	ra,40(sp)
    80002b84:	f022                	sd	s0,32(sp)
    80002b86:	ec26                	sd	s1,24(sp)
    80002b88:	e84a                	sd	s2,16(sp)
    80002b8a:	e44e                	sd	s3,8(sp)
    80002b8c:	1800                	addi	s0,sp,48
    80002b8e:	892a                	mv	s2,a0
    80002b90:	84ae                	mv	s1,a1
    80002b92:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002b94:	fffff097          	auipc	ra,0xfffff
    80002b98:	f18080e7          	jalr	-232(ra) # 80001aac <myproc>
  if(copyinstr(p->pagetable, buf, addr, max) < 0)
    80002b9c:	86ce                	mv	a3,s3
    80002b9e:	864a                	mv	a2,s2
    80002ba0:	85a6                	mv	a1,s1
    80002ba2:	6928                	ld	a0,80(a0)
    80002ba4:	fffff097          	auipc	ra,0xfffff
    80002ba8:	cba080e7          	jalr	-838(ra) # 8000185e <copyinstr>
    80002bac:	00054e63          	bltz	a0,80002bc8 <fetchstr+0x48>
  return strlen(buf);
    80002bb0:	8526                	mv	a0,s1
    80002bb2:	ffffe097          	auipc	ra,0xffffe
    80002bb6:	33e080e7          	jalr	830(ra) # 80000ef0 <strlen>
}
    80002bba:	70a2                	ld	ra,40(sp)
    80002bbc:	7402                	ld	s0,32(sp)
    80002bbe:	64e2                	ld	s1,24(sp)
    80002bc0:	6942                	ld	s2,16(sp)
    80002bc2:	69a2                	ld	s3,8(sp)
    80002bc4:	6145                	addi	sp,sp,48
    80002bc6:	8082                	ret
    return -1;
    80002bc8:	557d                	li	a0,-1
    80002bca:	bfc5                	j	80002bba <fetchstr+0x3a>

0000000080002bcc <argint>:

// Fetch the nth 32-bit system call argument.
void
argint(int n, int *ip)
{
    80002bcc:	1101                	addi	sp,sp,-32
    80002bce:	ec06                	sd	ra,24(sp)
    80002bd0:	e822                	sd	s0,16(sp)
    80002bd2:	e426                	sd	s1,8(sp)
    80002bd4:	1000                	addi	s0,sp,32
    80002bd6:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002bd8:	00000097          	auipc	ra,0x0
    80002bdc:	eee080e7          	jalr	-274(ra) # 80002ac6 <argraw>
    80002be0:	c088                	sw	a0,0(s1)
}
    80002be2:	60e2                	ld	ra,24(sp)
    80002be4:	6442                	ld	s0,16(sp)
    80002be6:	64a2                	ld	s1,8(sp)
    80002be8:	6105                	addi	sp,sp,32
    80002bea:	8082                	ret

0000000080002bec <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
void
argaddr(int n, uint64 *ip)
{
    80002bec:	1101                	addi	sp,sp,-32
    80002bee:	ec06                	sd	ra,24(sp)
    80002bf0:	e822                	sd	s0,16(sp)
    80002bf2:	e426                	sd	s1,8(sp)
    80002bf4:	1000                	addi	s0,sp,32
    80002bf6:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002bf8:	00000097          	auipc	ra,0x0
    80002bfc:	ece080e7          	jalr	-306(ra) # 80002ac6 <argraw>
    80002c00:	e088                	sd	a0,0(s1)
}
    80002c02:	60e2                	ld	ra,24(sp)
    80002c04:	6442                	ld	s0,16(sp)
    80002c06:	64a2                	ld	s1,8(sp)
    80002c08:	6105                	addi	sp,sp,32
    80002c0a:	8082                	ret

0000000080002c0c <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002c0c:	7179                	addi	sp,sp,-48
    80002c0e:	f406                	sd	ra,40(sp)
    80002c10:	f022                	sd	s0,32(sp)
    80002c12:	ec26                	sd	s1,24(sp)
    80002c14:	e84a                	sd	s2,16(sp)
    80002c16:	1800                	addi	s0,sp,48
    80002c18:	84ae                	mv	s1,a1
    80002c1a:	8932                	mv	s2,a2
  uint64 addr;
  argaddr(n, &addr);
    80002c1c:	fd840593          	addi	a1,s0,-40
    80002c20:	00000097          	auipc	ra,0x0
    80002c24:	fcc080e7          	jalr	-52(ra) # 80002bec <argaddr>
  return fetchstr(addr, buf, max);
    80002c28:	864a                	mv	a2,s2
    80002c2a:	85a6                	mv	a1,s1
    80002c2c:	fd843503          	ld	a0,-40(s0)
    80002c30:	00000097          	auipc	ra,0x0
    80002c34:	f50080e7          	jalr	-176(ra) # 80002b80 <fetchstr>
}
    80002c38:	70a2                	ld	ra,40(sp)
    80002c3a:	7402                	ld	s0,32(sp)
    80002c3c:	64e2                	ld	s1,24(sp)
    80002c3e:	6942                	ld	s2,16(sp)
    80002c40:	6145                	addi	sp,sp,48
    80002c42:	8082                	ret

0000000080002c44 <syscall>:
[SYS_testkalloc]     sys_testkalloc,
};

void
syscall(void)
{
    80002c44:	1101                	addi	sp,sp,-32
    80002c46:	ec06                	sd	ra,24(sp)
    80002c48:	e822                	sd	s0,16(sp)
    80002c4a:	e426                	sd	s1,8(sp)
    80002c4c:	e04a                	sd	s2,0(sp)
    80002c4e:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002c50:	fffff097          	auipc	ra,0xfffff
    80002c54:	e5c080e7          	jalr	-420(ra) # 80001aac <myproc>
    80002c58:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002c5a:	05853903          	ld	s2,88(a0)
    80002c5e:	0a893783          	ld	a5,168(s2)
    80002c62:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002c66:	37fd                	addiw	a5,a5,-1
    80002c68:	4759                	li	a4,22
    80002c6a:	00f76f63          	bltu	a4,a5,80002c88 <syscall+0x44>
    80002c6e:	00369713          	slli	a4,a3,0x3
    80002c72:	00006797          	auipc	a5,0x6
    80002c76:	b3678793          	addi	a5,a5,-1226 # 800087a8 <syscalls>
    80002c7a:	97ba                	add	a5,a5,a4
    80002c7c:	639c                	ld	a5,0(a5)
    80002c7e:	c789                	beqz	a5,80002c88 <syscall+0x44>
    // Use num to lookup the system call function for num, call it,
    // and store its return value in p->trapframe->a0
    p->trapframe->a0 = syscalls[num]();
    80002c80:	9782                	jalr	a5
    80002c82:	06a93823          	sd	a0,112(s2)
    80002c86:	a839                	j	80002ca4 <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002c88:	15848613          	addi	a2,s1,344
    80002c8c:	588c                	lw	a1,48(s1)
    80002c8e:	00005517          	auipc	a0,0x5
    80002c92:	75a50513          	addi	a0,a0,1882 # 800083e8 <etext+0x3e8>
    80002c96:	ffffe097          	auipc	ra,0xffffe
    80002c9a:	914080e7          	jalr	-1772(ra) # 800005aa <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002c9e:	6cbc                	ld	a5,88(s1)
    80002ca0:	577d                	li	a4,-1
    80002ca2:	fbb8                	sd	a4,112(a5)
  }
}
    80002ca4:	60e2                	ld	ra,24(sp)
    80002ca6:	6442                	ld	s0,16(sp)
    80002ca8:	64a2                	ld	s1,8(sp)
    80002caa:	6902                	ld	s2,0(sp)
    80002cac:	6105                	addi	sp,sp,32
    80002cae:	8082                	ret

0000000080002cb0 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002cb0:	1101                	addi	sp,sp,-32
    80002cb2:	ec06                	sd	ra,24(sp)
    80002cb4:	e822                	sd	s0,16(sp)
    80002cb6:	1000                	addi	s0,sp,32
  int n;
  argint(0, &n);
    80002cb8:	fec40593          	addi	a1,s0,-20
    80002cbc:	4501                	li	a0,0
    80002cbe:	00000097          	auipc	ra,0x0
    80002cc2:	f0e080e7          	jalr	-242(ra) # 80002bcc <argint>
  exit(n);
    80002cc6:	fec42503          	lw	a0,-20(s0)
    80002cca:	fffff097          	auipc	ra,0xfffff
    80002cce:	5c0080e7          	jalr	1472(ra) # 8000228a <exit>
  return 0;  // not reached
}
    80002cd2:	4501                	li	a0,0
    80002cd4:	60e2                	ld	ra,24(sp)
    80002cd6:	6442                	ld	s0,16(sp)
    80002cd8:	6105                	addi	sp,sp,32
    80002cda:	8082                	ret

0000000080002cdc <sys_getpid>:

uint64
sys_getpid(void)
{
    80002cdc:	1141                	addi	sp,sp,-16
    80002cde:	e406                	sd	ra,8(sp)
    80002ce0:	e022                	sd	s0,0(sp)
    80002ce2:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002ce4:	fffff097          	auipc	ra,0xfffff
    80002ce8:	dc8080e7          	jalr	-568(ra) # 80001aac <myproc>
}
    80002cec:	5908                	lw	a0,48(a0)
    80002cee:	60a2                	ld	ra,8(sp)
    80002cf0:	6402                	ld	s0,0(sp)
    80002cf2:	0141                	addi	sp,sp,16
    80002cf4:	8082                	ret

0000000080002cf6 <sys_fork>:

uint64
sys_fork(void)
{
    80002cf6:	1141                	addi	sp,sp,-16
    80002cf8:	e406                	sd	ra,8(sp)
    80002cfa:	e022                	sd	s0,0(sp)
    80002cfc:	0800                	addi	s0,sp,16
  return fork();
    80002cfe:	fffff097          	auipc	ra,0xfffff
    80002d02:	164080e7          	jalr	356(ra) # 80001e62 <fork>
}
    80002d06:	60a2                	ld	ra,8(sp)
    80002d08:	6402                	ld	s0,0(sp)
    80002d0a:	0141                	addi	sp,sp,16
    80002d0c:	8082                	ret

0000000080002d0e <sys_wait>:

uint64
sys_wait(void)
{
    80002d0e:	1101                	addi	sp,sp,-32
    80002d10:	ec06                	sd	ra,24(sp)
    80002d12:	e822                	sd	s0,16(sp)
    80002d14:	1000                	addi	s0,sp,32
  uint64 p;
  argaddr(0, &p);
    80002d16:	fe840593          	addi	a1,s0,-24
    80002d1a:	4501                	li	a0,0
    80002d1c:	00000097          	auipc	ra,0x0
    80002d20:	ed0080e7          	jalr	-304(ra) # 80002bec <argaddr>
  return wait(p);
    80002d24:	fe843503          	ld	a0,-24(s0)
    80002d28:	fffff097          	auipc	ra,0xfffff
    80002d2c:	708080e7          	jalr	1800(ra) # 80002430 <wait>
}
    80002d30:	60e2                	ld	ra,24(sp)
    80002d32:	6442                	ld	s0,16(sp)
    80002d34:	6105                	addi	sp,sp,32
    80002d36:	8082                	ret

0000000080002d38 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002d38:	7179                	addi	sp,sp,-48
    80002d3a:	f406                	sd	ra,40(sp)
    80002d3c:	f022                	sd	s0,32(sp)
    80002d3e:	ec26                	sd	s1,24(sp)
    80002d40:	1800                	addi	s0,sp,48
  uint64 addr;
  int n;

  argint(0, &n);
    80002d42:	fdc40593          	addi	a1,s0,-36
    80002d46:	4501                	li	a0,0
    80002d48:	00000097          	auipc	ra,0x0
    80002d4c:	e84080e7          	jalr	-380(ra) # 80002bcc <argint>
  addr = myproc()->sz;
    80002d50:	fffff097          	auipc	ra,0xfffff
    80002d54:	d5c080e7          	jalr	-676(ra) # 80001aac <myproc>
    80002d58:	6524                	ld	s1,72(a0)
  if(growproc(n) < 0)
    80002d5a:	fdc42503          	lw	a0,-36(s0)
    80002d5e:	fffff097          	auipc	ra,0xfffff
    80002d62:	0a8080e7          	jalr	168(ra) # 80001e06 <growproc>
    80002d66:	00054863          	bltz	a0,80002d76 <sys_sbrk+0x3e>
    return -1;
  return addr;
}
    80002d6a:	8526                	mv	a0,s1
    80002d6c:	70a2                	ld	ra,40(sp)
    80002d6e:	7402                	ld	s0,32(sp)
    80002d70:	64e2                	ld	s1,24(sp)
    80002d72:	6145                	addi	sp,sp,48
    80002d74:	8082                	ret
    return -1;
    80002d76:	54fd                	li	s1,-1
    80002d78:	bfcd                	j	80002d6a <sys_sbrk+0x32>

0000000080002d7a <sys_sleep>:

uint64
sys_sleep(void)
{
    80002d7a:	7139                	addi	sp,sp,-64
    80002d7c:	fc06                	sd	ra,56(sp)
    80002d7e:	f822                	sd	s0,48(sp)
    80002d80:	f04a                	sd	s2,32(sp)
    80002d82:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  argint(0, &n);
    80002d84:	fcc40593          	addi	a1,s0,-52
    80002d88:	4501                	li	a0,0
    80002d8a:	00000097          	auipc	ra,0x0
    80002d8e:	e42080e7          	jalr	-446(ra) # 80002bcc <argint>
  acquire(&tickslock);
    80002d92:	00016517          	auipc	a0,0x16
    80002d96:	54e50513          	addi	a0,a0,1358 # 800192e0 <tickslock>
    80002d9a:	ffffe097          	auipc	ra,0xffffe
    80002d9e:	ee6080e7          	jalr	-282(ra) # 80000c80 <acquire>
  ticks0 = ticks;
    80002da2:	00008917          	auipc	s2,0x8
    80002da6:	49e92903          	lw	s2,1182(s2) # 8000b240 <ticks>
  while(ticks - ticks0 < n){
    80002daa:	fcc42783          	lw	a5,-52(s0)
    80002dae:	c3b9                	beqz	a5,80002df4 <sys_sleep+0x7a>
    80002db0:	f426                	sd	s1,40(sp)
    80002db2:	ec4e                	sd	s3,24(sp)
    if(killed(myproc())){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002db4:	00016997          	auipc	s3,0x16
    80002db8:	52c98993          	addi	s3,s3,1324 # 800192e0 <tickslock>
    80002dbc:	00008497          	auipc	s1,0x8
    80002dc0:	48448493          	addi	s1,s1,1156 # 8000b240 <ticks>
    if(killed(myproc())){
    80002dc4:	fffff097          	auipc	ra,0xfffff
    80002dc8:	ce8080e7          	jalr	-792(ra) # 80001aac <myproc>
    80002dcc:	fffff097          	auipc	ra,0xfffff
    80002dd0:	632080e7          	jalr	1586(ra) # 800023fe <killed>
    80002dd4:	ed15                	bnez	a0,80002e10 <sys_sleep+0x96>
    sleep(&ticks, &tickslock);
    80002dd6:	85ce                	mv	a1,s3
    80002dd8:	8526                	mv	a0,s1
    80002dda:	fffff097          	auipc	ra,0xfffff
    80002dde:	37c080e7          	jalr	892(ra) # 80002156 <sleep>
  while(ticks - ticks0 < n){
    80002de2:	409c                	lw	a5,0(s1)
    80002de4:	412787bb          	subw	a5,a5,s2
    80002de8:	fcc42703          	lw	a4,-52(s0)
    80002dec:	fce7ece3          	bltu	a5,a4,80002dc4 <sys_sleep+0x4a>
    80002df0:	74a2                	ld	s1,40(sp)
    80002df2:	69e2                	ld	s3,24(sp)
  }
  release(&tickslock);
    80002df4:	00016517          	auipc	a0,0x16
    80002df8:	4ec50513          	addi	a0,a0,1260 # 800192e0 <tickslock>
    80002dfc:	ffffe097          	auipc	ra,0xffffe
    80002e00:	f38080e7          	jalr	-200(ra) # 80000d34 <release>
  return 0;
    80002e04:	4501                	li	a0,0
}
    80002e06:	70e2                	ld	ra,56(sp)
    80002e08:	7442                	ld	s0,48(sp)
    80002e0a:	7902                	ld	s2,32(sp)
    80002e0c:	6121                	addi	sp,sp,64
    80002e0e:	8082                	ret
      release(&tickslock);
    80002e10:	00016517          	auipc	a0,0x16
    80002e14:	4d050513          	addi	a0,a0,1232 # 800192e0 <tickslock>
    80002e18:	ffffe097          	auipc	ra,0xffffe
    80002e1c:	f1c080e7          	jalr	-228(ra) # 80000d34 <release>
      return -1;
    80002e20:	557d                	li	a0,-1
    80002e22:	74a2                	ld	s1,40(sp)
    80002e24:	69e2                	ld	s3,24(sp)
    80002e26:	b7c5                	j	80002e06 <sys_sleep+0x8c>

0000000080002e28 <sys_kill>:

uint64
sys_kill(void)
{
    80002e28:	1101                	addi	sp,sp,-32
    80002e2a:	ec06                	sd	ra,24(sp)
    80002e2c:	e822                	sd	s0,16(sp)
    80002e2e:	1000                	addi	s0,sp,32
  int pid;

  argint(0, &pid);
    80002e30:	fec40593          	addi	a1,s0,-20
    80002e34:	4501                	li	a0,0
    80002e36:	00000097          	auipc	ra,0x0
    80002e3a:	d96080e7          	jalr	-618(ra) # 80002bcc <argint>
  return kill(pid);
    80002e3e:	fec42503          	lw	a0,-20(s0)
    80002e42:	fffff097          	auipc	ra,0xfffff
    80002e46:	51e080e7          	jalr	1310(ra) # 80002360 <kill>
}
    80002e4a:	60e2                	ld	ra,24(sp)
    80002e4c:	6442                	ld	s0,16(sp)
    80002e4e:	6105                	addi	sp,sp,32
    80002e50:	8082                	ret

0000000080002e52 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80002e52:	1101                	addi	sp,sp,-32
    80002e54:	ec06                	sd	ra,24(sp)
    80002e56:	e822                	sd	s0,16(sp)
    80002e58:	e426                	sd	s1,8(sp)
    80002e5a:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80002e5c:	00016517          	auipc	a0,0x16
    80002e60:	48450513          	addi	a0,a0,1156 # 800192e0 <tickslock>
    80002e64:	ffffe097          	auipc	ra,0xffffe
    80002e68:	e1c080e7          	jalr	-484(ra) # 80000c80 <acquire>
  xticks = ticks;
    80002e6c:	00008497          	auipc	s1,0x8
    80002e70:	3d44a483          	lw	s1,980(s1) # 8000b240 <ticks>
  release(&tickslock);
    80002e74:	00016517          	auipc	a0,0x16
    80002e78:	46c50513          	addi	a0,a0,1132 # 800192e0 <tickslock>
    80002e7c:	ffffe097          	auipc	ra,0xffffe
    80002e80:	eb8080e7          	jalr	-328(ra) # 80000d34 <release>
  return xticks;
}
    80002e84:	02049513          	slli	a0,s1,0x20
    80002e88:	9101                	srli	a0,a0,0x20
    80002e8a:	60e2                	ld	ra,24(sp)
    80002e8c:	6442                	ld	s0,16(sp)
    80002e8e:	64a2                	ld	s1,8(sp)
    80002e90:	6105                	addi	sp,sp,32
    80002e92:	8082                	ret

0000000080002e94 <sys_freepages>:

uint64
sys_freepages(void)
{  
    80002e94:	1141                	addi	sp,sp,-16
    80002e96:	e406                	sd	ra,8(sp)
    80002e98:	e022                	sd	s0,0(sp)
    80002e9a:	0800                	addi	s0,sp,16
  return kfreepages();
    80002e9c:	ffffe097          	auipc	ra,0xffffe
    80002ea0:	d0c080e7          	jalr	-756(ra) # 80000ba8 <kfreepages>
}
    80002ea4:	60a2                	ld	ra,8(sp)
    80002ea6:	6402                	ld	s0,0(sp)
    80002ea8:	0141                	addi	sp,sp,16
    80002eaa:	8082                	ret

0000000080002eac <sys_testkalloc>:

uint64
sys_testkalloc(void){
    80002eac:	1141                	addi	sp,sp,-16
    80002eae:	e406                	sd	ra,8(sp)
    80002eb0:	e022                	sd	s0,0(sp)
    80002eb2:	0800                	addi	s0,sp,16
  kalloc();
    80002eb4:	ffffe097          	auipc	ra,0xffffe
    80002eb8:	c94080e7          	jalr	-876(ra) # 80000b48 <kalloc>
  return 0;
    80002ebc:	4501                	li	a0,0
    80002ebe:	60a2                	ld	ra,8(sp)
    80002ec0:	6402                	ld	s0,0(sp)
    80002ec2:	0141                	addi	sp,sp,16
    80002ec4:	8082                	ret

0000000080002ec6 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80002ec6:	7179                	addi	sp,sp,-48
    80002ec8:	f406                	sd	ra,40(sp)
    80002eca:	f022                	sd	s0,32(sp)
    80002ecc:	ec26                	sd	s1,24(sp)
    80002ece:	e84a                	sd	s2,16(sp)
    80002ed0:	e44e                	sd	s3,8(sp)
    80002ed2:	e052                	sd	s4,0(sp)
    80002ed4:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80002ed6:	00005597          	auipc	a1,0x5
    80002eda:	53258593          	addi	a1,a1,1330 # 80008408 <etext+0x408>
    80002ede:	00016517          	auipc	a0,0x16
    80002ee2:	41a50513          	addi	a0,a0,1050 # 800192f8 <bcache>
    80002ee6:	ffffe097          	auipc	ra,0xffffe
    80002eea:	d0a080e7          	jalr	-758(ra) # 80000bf0 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80002eee:	0001e797          	auipc	a5,0x1e
    80002ef2:	40a78793          	addi	a5,a5,1034 # 800212f8 <bcache+0x8000>
    80002ef6:	0001e717          	auipc	a4,0x1e
    80002efa:	66a70713          	addi	a4,a4,1642 # 80021560 <bcache+0x8268>
    80002efe:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80002f02:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002f06:	00016497          	auipc	s1,0x16
    80002f0a:	40a48493          	addi	s1,s1,1034 # 80019310 <bcache+0x18>
    b->next = bcache.head.next;
    80002f0e:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80002f10:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80002f12:	00005a17          	auipc	s4,0x5
    80002f16:	4fea0a13          	addi	s4,s4,1278 # 80008410 <etext+0x410>
    b->next = bcache.head.next;
    80002f1a:	2b893783          	ld	a5,696(s2)
    80002f1e:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80002f20:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80002f24:	85d2                	mv	a1,s4
    80002f26:	01048513          	addi	a0,s1,16
    80002f2a:	00001097          	auipc	ra,0x1
    80002f2e:	4e8080e7          	jalr	1256(ra) # 80004412 <initsleeplock>
    bcache.head.next->prev = b;
    80002f32:	2b893783          	ld	a5,696(s2)
    80002f36:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80002f38:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002f3c:	45848493          	addi	s1,s1,1112
    80002f40:	fd349de3          	bne	s1,s3,80002f1a <binit+0x54>
  }
}
    80002f44:	70a2                	ld	ra,40(sp)
    80002f46:	7402                	ld	s0,32(sp)
    80002f48:	64e2                	ld	s1,24(sp)
    80002f4a:	6942                	ld	s2,16(sp)
    80002f4c:	69a2                	ld	s3,8(sp)
    80002f4e:	6a02                	ld	s4,0(sp)
    80002f50:	6145                	addi	sp,sp,48
    80002f52:	8082                	ret

0000000080002f54 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80002f54:	7179                	addi	sp,sp,-48
    80002f56:	f406                	sd	ra,40(sp)
    80002f58:	f022                	sd	s0,32(sp)
    80002f5a:	ec26                	sd	s1,24(sp)
    80002f5c:	e84a                	sd	s2,16(sp)
    80002f5e:	e44e                	sd	s3,8(sp)
    80002f60:	1800                	addi	s0,sp,48
    80002f62:	892a                	mv	s2,a0
    80002f64:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    80002f66:	00016517          	auipc	a0,0x16
    80002f6a:	39250513          	addi	a0,a0,914 # 800192f8 <bcache>
    80002f6e:	ffffe097          	auipc	ra,0xffffe
    80002f72:	d12080e7          	jalr	-750(ra) # 80000c80 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80002f76:	0001e497          	auipc	s1,0x1e
    80002f7a:	63a4b483          	ld	s1,1594(s1) # 800215b0 <bcache+0x82b8>
    80002f7e:	0001e797          	auipc	a5,0x1e
    80002f82:	5e278793          	addi	a5,a5,1506 # 80021560 <bcache+0x8268>
    80002f86:	02f48f63          	beq	s1,a5,80002fc4 <bread+0x70>
    80002f8a:	873e                	mv	a4,a5
    80002f8c:	a021                	j	80002f94 <bread+0x40>
    80002f8e:	68a4                	ld	s1,80(s1)
    80002f90:	02e48a63          	beq	s1,a4,80002fc4 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80002f94:	449c                	lw	a5,8(s1)
    80002f96:	ff279ce3          	bne	a5,s2,80002f8e <bread+0x3a>
    80002f9a:	44dc                	lw	a5,12(s1)
    80002f9c:	ff3799e3          	bne	a5,s3,80002f8e <bread+0x3a>
      b->refcnt++;
    80002fa0:	40bc                	lw	a5,64(s1)
    80002fa2:	2785                	addiw	a5,a5,1
    80002fa4:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80002fa6:	00016517          	auipc	a0,0x16
    80002faa:	35250513          	addi	a0,a0,850 # 800192f8 <bcache>
    80002fae:	ffffe097          	auipc	ra,0xffffe
    80002fb2:	d86080e7          	jalr	-634(ra) # 80000d34 <release>
      acquiresleep(&b->lock);
    80002fb6:	01048513          	addi	a0,s1,16
    80002fba:	00001097          	auipc	ra,0x1
    80002fbe:	492080e7          	jalr	1170(ra) # 8000444c <acquiresleep>
      return b;
    80002fc2:	a8b9                	j	80003020 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002fc4:	0001e497          	auipc	s1,0x1e
    80002fc8:	5e44b483          	ld	s1,1508(s1) # 800215a8 <bcache+0x82b0>
    80002fcc:	0001e797          	auipc	a5,0x1e
    80002fd0:	59478793          	addi	a5,a5,1428 # 80021560 <bcache+0x8268>
    80002fd4:	00f48863          	beq	s1,a5,80002fe4 <bread+0x90>
    80002fd8:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80002fda:	40bc                	lw	a5,64(s1)
    80002fdc:	cf81                	beqz	a5,80002ff4 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002fde:	64a4                	ld	s1,72(s1)
    80002fe0:	fee49de3          	bne	s1,a4,80002fda <bread+0x86>
  panic("bget: no buffers");
    80002fe4:	00005517          	auipc	a0,0x5
    80002fe8:	43450513          	addi	a0,a0,1076 # 80008418 <etext+0x418>
    80002fec:	ffffd097          	auipc	ra,0xffffd
    80002ff0:	574080e7          	jalr	1396(ra) # 80000560 <panic>
      b->dev = dev;
    80002ff4:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    80002ff8:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    80002ffc:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80003000:	4785                	li	a5,1
    80003002:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003004:	00016517          	auipc	a0,0x16
    80003008:	2f450513          	addi	a0,a0,756 # 800192f8 <bcache>
    8000300c:	ffffe097          	auipc	ra,0xffffe
    80003010:	d28080e7          	jalr	-728(ra) # 80000d34 <release>
      acquiresleep(&b->lock);
    80003014:	01048513          	addi	a0,s1,16
    80003018:	00001097          	auipc	ra,0x1
    8000301c:	434080e7          	jalr	1076(ra) # 8000444c <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80003020:	409c                	lw	a5,0(s1)
    80003022:	cb89                	beqz	a5,80003034 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80003024:	8526                	mv	a0,s1
    80003026:	70a2                	ld	ra,40(sp)
    80003028:	7402                	ld	s0,32(sp)
    8000302a:	64e2                	ld	s1,24(sp)
    8000302c:	6942                	ld	s2,16(sp)
    8000302e:	69a2                	ld	s3,8(sp)
    80003030:	6145                	addi	sp,sp,48
    80003032:	8082                	ret
    virtio_disk_rw(b, 0);
    80003034:	4581                	li	a1,0
    80003036:	8526                	mv	a0,s1
    80003038:	00003097          	auipc	ra,0x3
    8000303c:	0f0080e7          	jalr	240(ra) # 80006128 <virtio_disk_rw>
    b->valid = 1;
    80003040:	4785                	li	a5,1
    80003042:	c09c                	sw	a5,0(s1)
  return b;
    80003044:	b7c5                	j	80003024 <bread+0xd0>

0000000080003046 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80003046:	1101                	addi	sp,sp,-32
    80003048:	ec06                	sd	ra,24(sp)
    8000304a:	e822                	sd	s0,16(sp)
    8000304c:	e426                	sd	s1,8(sp)
    8000304e:	1000                	addi	s0,sp,32
    80003050:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003052:	0541                	addi	a0,a0,16
    80003054:	00001097          	auipc	ra,0x1
    80003058:	492080e7          	jalr	1170(ra) # 800044e6 <holdingsleep>
    8000305c:	cd01                	beqz	a0,80003074 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    8000305e:	4585                	li	a1,1
    80003060:	8526                	mv	a0,s1
    80003062:	00003097          	auipc	ra,0x3
    80003066:	0c6080e7          	jalr	198(ra) # 80006128 <virtio_disk_rw>
}
    8000306a:	60e2                	ld	ra,24(sp)
    8000306c:	6442                	ld	s0,16(sp)
    8000306e:	64a2                	ld	s1,8(sp)
    80003070:	6105                	addi	sp,sp,32
    80003072:	8082                	ret
    panic("bwrite");
    80003074:	00005517          	auipc	a0,0x5
    80003078:	3bc50513          	addi	a0,a0,956 # 80008430 <etext+0x430>
    8000307c:	ffffd097          	auipc	ra,0xffffd
    80003080:	4e4080e7          	jalr	1252(ra) # 80000560 <panic>

0000000080003084 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80003084:	1101                	addi	sp,sp,-32
    80003086:	ec06                	sd	ra,24(sp)
    80003088:	e822                	sd	s0,16(sp)
    8000308a:	e426                	sd	s1,8(sp)
    8000308c:	e04a                	sd	s2,0(sp)
    8000308e:	1000                	addi	s0,sp,32
    80003090:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003092:	01050913          	addi	s2,a0,16
    80003096:	854a                	mv	a0,s2
    80003098:	00001097          	auipc	ra,0x1
    8000309c:	44e080e7          	jalr	1102(ra) # 800044e6 <holdingsleep>
    800030a0:	c925                	beqz	a0,80003110 <brelse+0x8c>
    panic("brelse");

  releasesleep(&b->lock);
    800030a2:	854a                	mv	a0,s2
    800030a4:	00001097          	auipc	ra,0x1
    800030a8:	3fe080e7          	jalr	1022(ra) # 800044a2 <releasesleep>

  acquire(&bcache.lock);
    800030ac:	00016517          	auipc	a0,0x16
    800030b0:	24c50513          	addi	a0,a0,588 # 800192f8 <bcache>
    800030b4:	ffffe097          	auipc	ra,0xffffe
    800030b8:	bcc080e7          	jalr	-1076(ra) # 80000c80 <acquire>
  b->refcnt--;
    800030bc:	40bc                	lw	a5,64(s1)
    800030be:	37fd                	addiw	a5,a5,-1
    800030c0:	0007871b          	sext.w	a4,a5
    800030c4:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    800030c6:	e71d                	bnez	a4,800030f4 <brelse+0x70>
    // no one is waiting for it.
    b->next->prev = b->prev;
    800030c8:	68b8                	ld	a4,80(s1)
    800030ca:	64bc                	ld	a5,72(s1)
    800030cc:	e73c                	sd	a5,72(a4)
    b->prev->next = b->next;
    800030ce:	68b8                	ld	a4,80(s1)
    800030d0:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    800030d2:	0001e797          	auipc	a5,0x1e
    800030d6:	22678793          	addi	a5,a5,550 # 800212f8 <bcache+0x8000>
    800030da:	2b87b703          	ld	a4,696(a5)
    800030de:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    800030e0:	0001e717          	auipc	a4,0x1e
    800030e4:	48070713          	addi	a4,a4,1152 # 80021560 <bcache+0x8268>
    800030e8:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    800030ea:	2b87b703          	ld	a4,696(a5)
    800030ee:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    800030f0:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    800030f4:	00016517          	auipc	a0,0x16
    800030f8:	20450513          	addi	a0,a0,516 # 800192f8 <bcache>
    800030fc:	ffffe097          	auipc	ra,0xffffe
    80003100:	c38080e7          	jalr	-968(ra) # 80000d34 <release>
}
    80003104:	60e2                	ld	ra,24(sp)
    80003106:	6442                	ld	s0,16(sp)
    80003108:	64a2                	ld	s1,8(sp)
    8000310a:	6902                	ld	s2,0(sp)
    8000310c:	6105                	addi	sp,sp,32
    8000310e:	8082                	ret
    panic("brelse");
    80003110:	00005517          	auipc	a0,0x5
    80003114:	32850513          	addi	a0,a0,808 # 80008438 <etext+0x438>
    80003118:	ffffd097          	auipc	ra,0xffffd
    8000311c:	448080e7          	jalr	1096(ra) # 80000560 <panic>

0000000080003120 <bpin>:

void
bpin(struct buf *b) {
    80003120:	1101                	addi	sp,sp,-32
    80003122:	ec06                	sd	ra,24(sp)
    80003124:	e822                	sd	s0,16(sp)
    80003126:	e426                	sd	s1,8(sp)
    80003128:	1000                	addi	s0,sp,32
    8000312a:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    8000312c:	00016517          	auipc	a0,0x16
    80003130:	1cc50513          	addi	a0,a0,460 # 800192f8 <bcache>
    80003134:	ffffe097          	auipc	ra,0xffffe
    80003138:	b4c080e7          	jalr	-1204(ra) # 80000c80 <acquire>
  b->refcnt++;
    8000313c:	40bc                	lw	a5,64(s1)
    8000313e:	2785                	addiw	a5,a5,1
    80003140:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003142:	00016517          	auipc	a0,0x16
    80003146:	1b650513          	addi	a0,a0,438 # 800192f8 <bcache>
    8000314a:	ffffe097          	auipc	ra,0xffffe
    8000314e:	bea080e7          	jalr	-1046(ra) # 80000d34 <release>
}
    80003152:	60e2                	ld	ra,24(sp)
    80003154:	6442                	ld	s0,16(sp)
    80003156:	64a2                	ld	s1,8(sp)
    80003158:	6105                	addi	sp,sp,32
    8000315a:	8082                	ret

000000008000315c <bunpin>:

void
bunpin(struct buf *b) {
    8000315c:	1101                	addi	sp,sp,-32
    8000315e:	ec06                	sd	ra,24(sp)
    80003160:	e822                	sd	s0,16(sp)
    80003162:	e426                	sd	s1,8(sp)
    80003164:	1000                	addi	s0,sp,32
    80003166:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003168:	00016517          	auipc	a0,0x16
    8000316c:	19050513          	addi	a0,a0,400 # 800192f8 <bcache>
    80003170:	ffffe097          	auipc	ra,0xffffe
    80003174:	b10080e7          	jalr	-1264(ra) # 80000c80 <acquire>
  b->refcnt--;
    80003178:	40bc                	lw	a5,64(s1)
    8000317a:	37fd                	addiw	a5,a5,-1
    8000317c:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    8000317e:	00016517          	auipc	a0,0x16
    80003182:	17a50513          	addi	a0,a0,378 # 800192f8 <bcache>
    80003186:	ffffe097          	auipc	ra,0xffffe
    8000318a:	bae080e7          	jalr	-1106(ra) # 80000d34 <release>
}
    8000318e:	60e2                	ld	ra,24(sp)
    80003190:	6442                	ld	s0,16(sp)
    80003192:	64a2                	ld	s1,8(sp)
    80003194:	6105                	addi	sp,sp,32
    80003196:	8082                	ret

0000000080003198 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80003198:	1101                	addi	sp,sp,-32
    8000319a:	ec06                	sd	ra,24(sp)
    8000319c:	e822                	sd	s0,16(sp)
    8000319e:	e426                	sd	s1,8(sp)
    800031a0:	e04a                	sd	s2,0(sp)
    800031a2:	1000                	addi	s0,sp,32
    800031a4:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    800031a6:	00d5d59b          	srliw	a1,a1,0xd
    800031aa:	0001f797          	auipc	a5,0x1f
    800031ae:	82a7a783          	lw	a5,-2006(a5) # 800219d4 <sb+0x1c>
    800031b2:	9dbd                	addw	a1,a1,a5
    800031b4:	00000097          	auipc	ra,0x0
    800031b8:	da0080e7          	jalr	-608(ra) # 80002f54 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    800031bc:	0074f713          	andi	a4,s1,7
    800031c0:	4785                	li	a5,1
    800031c2:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    800031c6:	14ce                	slli	s1,s1,0x33
    800031c8:	90d9                	srli	s1,s1,0x36
    800031ca:	00950733          	add	a4,a0,s1
    800031ce:	05874703          	lbu	a4,88(a4)
    800031d2:	00e7f6b3          	and	a3,a5,a4
    800031d6:	c69d                	beqz	a3,80003204 <bfree+0x6c>
    800031d8:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    800031da:	94aa                	add	s1,s1,a0
    800031dc:	fff7c793          	not	a5,a5
    800031e0:	8f7d                	and	a4,a4,a5
    800031e2:	04e48c23          	sb	a4,88(s1)
  log_write(bp);
    800031e6:	00001097          	auipc	ra,0x1
    800031ea:	148080e7          	jalr	328(ra) # 8000432e <log_write>
  brelse(bp);
    800031ee:	854a                	mv	a0,s2
    800031f0:	00000097          	auipc	ra,0x0
    800031f4:	e94080e7          	jalr	-364(ra) # 80003084 <brelse>
}
    800031f8:	60e2                	ld	ra,24(sp)
    800031fa:	6442                	ld	s0,16(sp)
    800031fc:	64a2                	ld	s1,8(sp)
    800031fe:	6902                	ld	s2,0(sp)
    80003200:	6105                	addi	sp,sp,32
    80003202:	8082                	ret
    panic("freeing free block");
    80003204:	00005517          	auipc	a0,0x5
    80003208:	23c50513          	addi	a0,a0,572 # 80008440 <etext+0x440>
    8000320c:	ffffd097          	auipc	ra,0xffffd
    80003210:	354080e7          	jalr	852(ra) # 80000560 <panic>

0000000080003214 <balloc>:
{
    80003214:	711d                	addi	sp,sp,-96
    80003216:	ec86                	sd	ra,88(sp)
    80003218:	e8a2                	sd	s0,80(sp)
    8000321a:	e4a6                	sd	s1,72(sp)
    8000321c:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    8000321e:	0001e797          	auipc	a5,0x1e
    80003222:	79e7a783          	lw	a5,1950(a5) # 800219bc <sb+0x4>
    80003226:	10078f63          	beqz	a5,80003344 <balloc+0x130>
    8000322a:	e0ca                	sd	s2,64(sp)
    8000322c:	fc4e                	sd	s3,56(sp)
    8000322e:	f852                	sd	s4,48(sp)
    80003230:	f456                	sd	s5,40(sp)
    80003232:	f05a                	sd	s6,32(sp)
    80003234:	ec5e                	sd	s7,24(sp)
    80003236:	e862                	sd	s8,16(sp)
    80003238:	e466                	sd	s9,8(sp)
    8000323a:	8baa                	mv	s7,a0
    8000323c:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    8000323e:	0001eb17          	auipc	s6,0x1e
    80003242:	77ab0b13          	addi	s6,s6,1914 # 800219b8 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003246:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    80003248:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000324a:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    8000324c:	6c89                	lui	s9,0x2
    8000324e:	a061                	j	800032d6 <balloc+0xc2>
        bp->data[bi/8] |= m;  // Mark block in use.
    80003250:	97ca                	add	a5,a5,s2
    80003252:	8e55                	or	a2,a2,a3
    80003254:	04c78c23          	sb	a2,88(a5)
        log_write(bp);
    80003258:	854a                	mv	a0,s2
    8000325a:	00001097          	auipc	ra,0x1
    8000325e:	0d4080e7          	jalr	212(ra) # 8000432e <log_write>
        brelse(bp);
    80003262:	854a                	mv	a0,s2
    80003264:	00000097          	auipc	ra,0x0
    80003268:	e20080e7          	jalr	-480(ra) # 80003084 <brelse>
  bp = bread(dev, bno);
    8000326c:	85a6                	mv	a1,s1
    8000326e:	855e                	mv	a0,s7
    80003270:	00000097          	auipc	ra,0x0
    80003274:	ce4080e7          	jalr	-796(ra) # 80002f54 <bread>
    80003278:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    8000327a:	40000613          	li	a2,1024
    8000327e:	4581                	li	a1,0
    80003280:	05850513          	addi	a0,a0,88
    80003284:	ffffe097          	auipc	ra,0xffffe
    80003288:	af8080e7          	jalr	-1288(ra) # 80000d7c <memset>
  log_write(bp);
    8000328c:	854a                	mv	a0,s2
    8000328e:	00001097          	auipc	ra,0x1
    80003292:	0a0080e7          	jalr	160(ra) # 8000432e <log_write>
  brelse(bp);
    80003296:	854a                	mv	a0,s2
    80003298:	00000097          	auipc	ra,0x0
    8000329c:	dec080e7          	jalr	-532(ra) # 80003084 <brelse>
}
    800032a0:	6906                	ld	s2,64(sp)
    800032a2:	79e2                	ld	s3,56(sp)
    800032a4:	7a42                	ld	s4,48(sp)
    800032a6:	7aa2                	ld	s5,40(sp)
    800032a8:	7b02                	ld	s6,32(sp)
    800032aa:	6be2                	ld	s7,24(sp)
    800032ac:	6c42                	ld	s8,16(sp)
    800032ae:	6ca2                	ld	s9,8(sp)
}
    800032b0:	8526                	mv	a0,s1
    800032b2:	60e6                	ld	ra,88(sp)
    800032b4:	6446                	ld	s0,80(sp)
    800032b6:	64a6                	ld	s1,72(sp)
    800032b8:	6125                	addi	sp,sp,96
    800032ba:	8082                	ret
    brelse(bp);
    800032bc:	854a                	mv	a0,s2
    800032be:	00000097          	auipc	ra,0x0
    800032c2:	dc6080e7          	jalr	-570(ra) # 80003084 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    800032c6:	015c87bb          	addw	a5,s9,s5
    800032ca:	00078a9b          	sext.w	s5,a5
    800032ce:	004b2703          	lw	a4,4(s6)
    800032d2:	06eaf163          	bgeu	s5,a4,80003334 <balloc+0x120>
    bp = bread(dev, BBLOCK(b, sb));
    800032d6:	41fad79b          	sraiw	a5,s5,0x1f
    800032da:	0137d79b          	srliw	a5,a5,0x13
    800032de:	015787bb          	addw	a5,a5,s5
    800032e2:	40d7d79b          	sraiw	a5,a5,0xd
    800032e6:	01cb2583          	lw	a1,28(s6)
    800032ea:	9dbd                	addw	a1,a1,a5
    800032ec:	855e                	mv	a0,s7
    800032ee:	00000097          	auipc	ra,0x0
    800032f2:	c66080e7          	jalr	-922(ra) # 80002f54 <bread>
    800032f6:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800032f8:	004b2503          	lw	a0,4(s6)
    800032fc:	000a849b          	sext.w	s1,s5
    80003300:	8762                	mv	a4,s8
    80003302:	faa4fde3          	bgeu	s1,a0,800032bc <balloc+0xa8>
      m = 1 << (bi % 8);
    80003306:	00777693          	andi	a3,a4,7
    8000330a:	00d996bb          	sllw	a3,s3,a3
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    8000330e:	41f7579b          	sraiw	a5,a4,0x1f
    80003312:	01d7d79b          	srliw	a5,a5,0x1d
    80003316:	9fb9                	addw	a5,a5,a4
    80003318:	4037d79b          	sraiw	a5,a5,0x3
    8000331c:	00f90633          	add	a2,s2,a5
    80003320:	05864603          	lbu	a2,88(a2)
    80003324:	00c6f5b3          	and	a1,a3,a2
    80003328:	d585                	beqz	a1,80003250 <balloc+0x3c>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000332a:	2705                	addiw	a4,a4,1
    8000332c:	2485                	addiw	s1,s1,1
    8000332e:	fd471ae3          	bne	a4,s4,80003302 <balloc+0xee>
    80003332:	b769                	j	800032bc <balloc+0xa8>
    80003334:	6906                	ld	s2,64(sp)
    80003336:	79e2                	ld	s3,56(sp)
    80003338:	7a42                	ld	s4,48(sp)
    8000333a:	7aa2                	ld	s5,40(sp)
    8000333c:	7b02                	ld	s6,32(sp)
    8000333e:	6be2                	ld	s7,24(sp)
    80003340:	6c42                	ld	s8,16(sp)
    80003342:	6ca2                	ld	s9,8(sp)
  printf("balloc: out of blocks\n");
    80003344:	00005517          	auipc	a0,0x5
    80003348:	11450513          	addi	a0,a0,276 # 80008458 <etext+0x458>
    8000334c:	ffffd097          	auipc	ra,0xffffd
    80003350:	25e080e7          	jalr	606(ra) # 800005aa <printf>
  return 0;
    80003354:	4481                	li	s1,0
    80003356:	bfa9                	j	800032b0 <balloc+0x9c>

0000000080003358 <bmap>:
// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
// returns 0 if out of disk space.
static uint
bmap(struct inode *ip, uint bn)
{
    80003358:	7179                	addi	sp,sp,-48
    8000335a:	f406                	sd	ra,40(sp)
    8000335c:	f022                	sd	s0,32(sp)
    8000335e:	ec26                	sd	s1,24(sp)
    80003360:	e84a                	sd	s2,16(sp)
    80003362:	e44e                	sd	s3,8(sp)
    80003364:	1800                	addi	s0,sp,48
    80003366:	89aa                	mv	s3,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80003368:	47ad                	li	a5,11
    8000336a:	02b7e863          	bltu	a5,a1,8000339a <bmap+0x42>
    if((addr = ip->addrs[bn]) == 0){
    8000336e:	02059793          	slli	a5,a1,0x20
    80003372:	01e7d593          	srli	a1,a5,0x1e
    80003376:	00b504b3          	add	s1,a0,a1
    8000337a:	0504a903          	lw	s2,80(s1)
    8000337e:	08091263          	bnez	s2,80003402 <bmap+0xaa>
      addr = balloc(ip->dev);
    80003382:	4108                	lw	a0,0(a0)
    80003384:	00000097          	auipc	ra,0x0
    80003388:	e90080e7          	jalr	-368(ra) # 80003214 <balloc>
    8000338c:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    80003390:	06090963          	beqz	s2,80003402 <bmap+0xaa>
        return 0;
      ip->addrs[bn] = addr;
    80003394:	0524a823          	sw	s2,80(s1)
    80003398:	a0ad                	j	80003402 <bmap+0xaa>
    }
    return addr;
  }
  bn -= NDIRECT;
    8000339a:	ff45849b          	addiw	s1,a1,-12
    8000339e:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    800033a2:	0ff00793          	li	a5,255
    800033a6:	08e7e863          	bltu	a5,a4,80003436 <bmap+0xde>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0){
    800033aa:	08052903          	lw	s2,128(a0)
    800033ae:	00091f63          	bnez	s2,800033cc <bmap+0x74>
      addr = balloc(ip->dev);
    800033b2:	4108                	lw	a0,0(a0)
    800033b4:	00000097          	auipc	ra,0x0
    800033b8:	e60080e7          	jalr	-416(ra) # 80003214 <balloc>
    800033bc:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    800033c0:	04090163          	beqz	s2,80003402 <bmap+0xaa>
    800033c4:	e052                	sd	s4,0(sp)
        return 0;
      ip->addrs[NDIRECT] = addr;
    800033c6:	0929a023          	sw	s2,128(s3)
    800033ca:	a011                	j	800033ce <bmap+0x76>
    800033cc:	e052                	sd	s4,0(sp)
    }
    bp = bread(ip->dev, addr);
    800033ce:	85ca                	mv	a1,s2
    800033d0:	0009a503          	lw	a0,0(s3)
    800033d4:	00000097          	auipc	ra,0x0
    800033d8:	b80080e7          	jalr	-1152(ra) # 80002f54 <bread>
    800033dc:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    800033de:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    800033e2:	02049713          	slli	a4,s1,0x20
    800033e6:	01e75593          	srli	a1,a4,0x1e
    800033ea:	00b784b3          	add	s1,a5,a1
    800033ee:	0004a903          	lw	s2,0(s1)
    800033f2:	02090063          	beqz	s2,80003412 <bmap+0xba>
      if(addr){
        a[bn] = addr;
        log_write(bp);
      }
    }
    brelse(bp);
    800033f6:	8552                	mv	a0,s4
    800033f8:	00000097          	auipc	ra,0x0
    800033fc:	c8c080e7          	jalr	-884(ra) # 80003084 <brelse>
    return addr;
    80003400:	6a02                	ld	s4,0(sp)
  }

  panic("bmap: out of range");
}
    80003402:	854a                	mv	a0,s2
    80003404:	70a2                	ld	ra,40(sp)
    80003406:	7402                	ld	s0,32(sp)
    80003408:	64e2                	ld	s1,24(sp)
    8000340a:	6942                	ld	s2,16(sp)
    8000340c:	69a2                	ld	s3,8(sp)
    8000340e:	6145                	addi	sp,sp,48
    80003410:	8082                	ret
      addr = balloc(ip->dev);
    80003412:	0009a503          	lw	a0,0(s3)
    80003416:	00000097          	auipc	ra,0x0
    8000341a:	dfe080e7          	jalr	-514(ra) # 80003214 <balloc>
    8000341e:	0005091b          	sext.w	s2,a0
      if(addr){
    80003422:	fc090ae3          	beqz	s2,800033f6 <bmap+0x9e>
        a[bn] = addr;
    80003426:	0124a023          	sw	s2,0(s1)
        log_write(bp);
    8000342a:	8552                	mv	a0,s4
    8000342c:	00001097          	auipc	ra,0x1
    80003430:	f02080e7          	jalr	-254(ra) # 8000432e <log_write>
    80003434:	b7c9                	j	800033f6 <bmap+0x9e>
    80003436:	e052                	sd	s4,0(sp)
  panic("bmap: out of range");
    80003438:	00005517          	auipc	a0,0x5
    8000343c:	03850513          	addi	a0,a0,56 # 80008470 <etext+0x470>
    80003440:	ffffd097          	auipc	ra,0xffffd
    80003444:	120080e7          	jalr	288(ra) # 80000560 <panic>

0000000080003448 <iget>:
{
    80003448:	7179                	addi	sp,sp,-48
    8000344a:	f406                	sd	ra,40(sp)
    8000344c:	f022                	sd	s0,32(sp)
    8000344e:	ec26                	sd	s1,24(sp)
    80003450:	e84a                	sd	s2,16(sp)
    80003452:	e44e                	sd	s3,8(sp)
    80003454:	e052                	sd	s4,0(sp)
    80003456:	1800                	addi	s0,sp,48
    80003458:	89aa                	mv	s3,a0
    8000345a:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    8000345c:	0001e517          	auipc	a0,0x1e
    80003460:	57c50513          	addi	a0,a0,1404 # 800219d8 <itable>
    80003464:	ffffe097          	auipc	ra,0xffffe
    80003468:	81c080e7          	jalr	-2020(ra) # 80000c80 <acquire>
  empty = 0;
    8000346c:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    8000346e:	0001e497          	auipc	s1,0x1e
    80003472:	58248493          	addi	s1,s1,1410 # 800219f0 <itable+0x18>
    80003476:	00020697          	auipc	a3,0x20
    8000347a:	00a68693          	addi	a3,a3,10 # 80023480 <log>
    8000347e:	a039                	j	8000348c <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003480:	02090b63          	beqz	s2,800034b6 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003484:	08848493          	addi	s1,s1,136
    80003488:	02d48a63          	beq	s1,a3,800034bc <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    8000348c:	449c                	lw	a5,8(s1)
    8000348e:	fef059e3          	blez	a5,80003480 <iget+0x38>
    80003492:	4098                	lw	a4,0(s1)
    80003494:	ff3716e3          	bne	a4,s3,80003480 <iget+0x38>
    80003498:	40d8                	lw	a4,4(s1)
    8000349a:	ff4713e3          	bne	a4,s4,80003480 <iget+0x38>
      ip->ref++;
    8000349e:	2785                	addiw	a5,a5,1
    800034a0:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    800034a2:	0001e517          	auipc	a0,0x1e
    800034a6:	53650513          	addi	a0,a0,1334 # 800219d8 <itable>
    800034aa:	ffffe097          	auipc	ra,0xffffe
    800034ae:	88a080e7          	jalr	-1910(ra) # 80000d34 <release>
      return ip;
    800034b2:	8926                	mv	s2,s1
    800034b4:	a03d                	j	800034e2 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800034b6:	f7f9                	bnez	a5,80003484 <iget+0x3c>
      empty = ip;
    800034b8:	8926                	mv	s2,s1
    800034ba:	b7e9                	j	80003484 <iget+0x3c>
  if(empty == 0)
    800034bc:	02090c63          	beqz	s2,800034f4 <iget+0xac>
  ip->dev = dev;
    800034c0:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    800034c4:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    800034c8:	4785                	li	a5,1
    800034ca:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    800034ce:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    800034d2:	0001e517          	auipc	a0,0x1e
    800034d6:	50650513          	addi	a0,a0,1286 # 800219d8 <itable>
    800034da:	ffffe097          	auipc	ra,0xffffe
    800034de:	85a080e7          	jalr	-1958(ra) # 80000d34 <release>
}
    800034e2:	854a                	mv	a0,s2
    800034e4:	70a2                	ld	ra,40(sp)
    800034e6:	7402                	ld	s0,32(sp)
    800034e8:	64e2                	ld	s1,24(sp)
    800034ea:	6942                	ld	s2,16(sp)
    800034ec:	69a2                	ld	s3,8(sp)
    800034ee:	6a02                	ld	s4,0(sp)
    800034f0:	6145                	addi	sp,sp,48
    800034f2:	8082                	ret
    panic("iget: no inodes");
    800034f4:	00005517          	auipc	a0,0x5
    800034f8:	f9450513          	addi	a0,a0,-108 # 80008488 <etext+0x488>
    800034fc:	ffffd097          	auipc	ra,0xffffd
    80003500:	064080e7          	jalr	100(ra) # 80000560 <panic>

0000000080003504 <fsinit>:
fsinit(int dev) {
    80003504:	7179                	addi	sp,sp,-48
    80003506:	f406                	sd	ra,40(sp)
    80003508:	f022                	sd	s0,32(sp)
    8000350a:	ec26                	sd	s1,24(sp)
    8000350c:	e84a                	sd	s2,16(sp)
    8000350e:	e44e                	sd	s3,8(sp)
    80003510:	1800                	addi	s0,sp,48
    80003512:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003514:	4585                	li	a1,1
    80003516:	00000097          	auipc	ra,0x0
    8000351a:	a3e080e7          	jalr	-1474(ra) # 80002f54 <bread>
    8000351e:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003520:	0001e997          	auipc	s3,0x1e
    80003524:	49898993          	addi	s3,s3,1176 # 800219b8 <sb>
    80003528:	02000613          	li	a2,32
    8000352c:	05850593          	addi	a1,a0,88
    80003530:	854e                	mv	a0,s3
    80003532:	ffffe097          	auipc	ra,0xffffe
    80003536:	8a6080e7          	jalr	-1882(ra) # 80000dd8 <memmove>
  brelse(bp);
    8000353a:	8526                	mv	a0,s1
    8000353c:	00000097          	auipc	ra,0x0
    80003540:	b48080e7          	jalr	-1208(ra) # 80003084 <brelse>
  if(sb.magic != FSMAGIC)
    80003544:	0009a703          	lw	a4,0(s3)
    80003548:	102037b7          	lui	a5,0x10203
    8000354c:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003550:	02f71263          	bne	a4,a5,80003574 <fsinit+0x70>
  initlog(dev, &sb);
    80003554:	0001e597          	auipc	a1,0x1e
    80003558:	46458593          	addi	a1,a1,1124 # 800219b8 <sb>
    8000355c:	854a                	mv	a0,s2
    8000355e:	00001097          	auipc	ra,0x1
    80003562:	b60080e7          	jalr	-1184(ra) # 800040be <initlog>
}
    80003566:	70a2                	ld	ra,40(sp)
    80003568:	7402                	ld	s0,32(sp)
    8000356a:	64e2                	ld	s1,24(sp)
    8000356c:	6942                	ld	s2,16(sp)
    8000356e:	69a2                	ld	s3,8(sp)
    80003570:	6145                	addi	sp,sp,48
    80003572:	8082                	ret
    panic("invalid file system");
    80003574:	00005517          	auipc	a0,0x5
    80003578:	f2450513          	addi	a0,a0,-220 # 80008498 <etext+0x498>
    8000357c:	ffffd097          	auipc	ra,0xffffd
    80003580:	fe4080e7          	jalr	-28(ra) # 80000560 <panic>

0000000080003584 <iinit>:
{
    80003584:	7179                	addi	sp,sp,-48
    80003586:	f406                	sd	ra,40(sp)
    80003588:	f022                	sd	s0,32(sp)
    8000358a:	ec26                	sd	s1,24(sp)
    8000358c:	e84a                	sd	s2,16(sp)
    8000358e:	e44e                	sd	s3,8(sp)
    80003590:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    80003592:	00005597          	auipc	a1,0x5
    80003596:	f1e58593          	addi	a1,a1,-226 # 800084b0 <etext+0x4b0>
    8000359a:	0001e517          	auipc	a0,0x1e
    8000359e:	43e50513          	addi	a0,a0,1086 # 800219d8 <itable>
    800035a2:	ffffd097          	auipc	ra,0xffffd
    800035a6:	64e080e7          	jalr	1614(ra) # 80000bf0 <initlock>
  for(i = 0; i < NINODE; i++) {
    800035aa:	0001e497          	auipc	s1,0x1e
    800035ae:	45648493          	addi	s1,s1,1110 # 80021a00 <itable+0x28>
    800035b2:	00020997          	auipc	s3,0x20
    800035b6:	ede98993          	addi	s3,s3,-290 # 80023490 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    800035ba:	00005917          	auipc	s2,0x5
    800035be:	efe90913          	addi	s2,s2,-258 # 800084b8 <etext+0x4b8>
    800035c2:	85ca                	mv	a1,s2
    800035c4:	8526                	mv	a0,s1
    800035c6:	00001097          	auipc	ra,0x1
    800035ca:	e4c080e7          	jalr	-436(ra) # 80004412 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    800035ce:	08848493          	addi	s1,s1,136
    800035d2:	ff3498e3          	bne	s1,s3,800035c2 <iinit+0x3e>
}
    800035d6:	70a2                	ld	ra,40(sp)
    800035d8:	7402                	ld	s0,32(sp)
    800035da:	64e2                	ld	s1,24(sp)
    800035dc:	6942                	ld	s2,16(sp)
    800035de:	69a2                	ld	s3,8(sp)
    800035e0:	6145                	addi	sp,sp,48
    800035e2:	8082                	ret

00000000800035e4 <ialloc>:
{
    800035e4:	7139                	addi	sp,sp,-64
    800035e6:	fc06                	sd	ra,56(sp)
    800035e8:	f822                	sd	s0,48(sp)
    800035ea:	0080                	addi	s0,sp,64
  for(inum = 1; inum < sb.ninodes; inum++){
    800035ec:	0001e717          	auipc	a4,0x1e
    800035f0:	3d872703          	lw	a4,984(a4) # 800219c4 <sb+0xc>
    800035f4:	4785                	li	a5,1
    800035f6:	06e7f463          	bgeu	a5,a4,8000365e <ialloc+0x7a>
    800035fa:	f426                	sd	s1,40(sp)
    800035fc:	f04a                	sd	s2,32(sp)
    800035fe:	ec4e                	sd	s3,24(sp)
    80003600:	e852                	sd	s4,16(sp)
    80003602:	e456                	sd	s5,8(sp)
    80003604:	e05a                	sd	s6,0(sp)
    80003606:	8aaa                	mv	s5,a0
    80003608:	8b2e                	mv	s6,a1
    8000360a:	4905                	li	s2,1
    bp = bread(dev, IBLOCK(inum, sb));
    8000360c:	0001ea17          	auipc	s4,0x1e
    80003610:	3aca0a13          	addi	s4,s4,940 # 800219b8 <sb>
    80003614:	00495593          	srli	a1,s2,0x4
    80003618:	018a2783          	lw	a5,24(s4)
    8000361c:	9dbd                	addw	a1,a1,a5
    8000361e:	8556                	mv	a0,s5
    80003620:	00000097          	auipc	ra,0x0
    80003624:	934080e7          	jalr	-1740(ra) # 80002f54 <bread>
    80003628:	84aa                	mv	s1,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    8000362a:	05850993          	addi	s3,a0,88
    8000362e:	00f97793          	andi	a5,s2,15
    80003632:	079a                	slli	a5,a5,0x6
    80003634:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003636:	00099783          	lh	a5,0(s3)
    8000363a:	cf9d                	beqz	a5,80003678 <ialloc+0x94>
    brelse(bp);
    8000363c:	00000097          	auipc	ra,0x0
    80003640:	a48080e7          	jalr	-1464(ra) # 80003084 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003644:	0905                	addi	s2,s2,1
    80003646:	00ca2703          	lw	a4,12(s4)
    8000364a:	0009079b          	sext.w	a5,s2
    8000364e:	fce7e3e3          	bltu	a5,a4,80003614 <ialloc+0x30>
    80003652:	74a2                	ld	s1,40(sp)
    80003654:	7902                	ld	s2,32(sp)
    80003656:	69e2                	ld	s3,24(sp)
    80003658:	6a42                	ld	s4,16(sp)
    8000365a:	6aa2                	ld	s5,8(sp)
    8000365c:	6b02                	ld	s6,0(sp)
  printf("ialloc: no inodes\n");
    8000365e:	00005517          	auipc	a0,0x5
    80003662:	e6250513          	addi	a0,a0,-414 # 800084c0 <etext+0x4c0>
    80003666:	ffffd097          	auipc	ra,0xffffd
    8000366a:	f44080e7          	jalr	-188(ra) # 800005aa <printf>
  return 0;
    8000366e:	4501                	li	a0,0
}
    80003670:	70e2                	ld	ra,56(sp)
    80003672:	7442                	ld	s0,48(sp)
    80003674:	6121                	addi	sp,sp,64
    80003676:	8082                	ret
      memset(dip, 0, sizeof(*dip));
    80003678:	04000613          	li	a2,64
    8000367c:	4581                	li	a1,0
    8000367e:	854e                	mv	a0,s3
    80003680:	ffffd097          	auipc	ra,0xffffd
    80003684:	6fc080e7          	jalr	1788(ra) # 80000d7c <memset>
      dip->type = type;
    80003688:	01699023          	sh	s6,0(s3)
      log_write(bp);   // mark it allocated on the disk
    8000368c:	8526                	mv	a0,s1
    8000368e:	00001097          	auipc	ra,0x1
    80003692:	ca0080e7          	jalr	-864(ra) # 8000432e <log_write>
      brelse(bp);
    80003696:	8526                	mv	a0,s1
    80003698:	00000097          	auipc	ra,0x0
    8000369c:	9ec080e7          	jalr	-1556(ra) # 80003084 <brelse>
      return iget(dev, inum);
    800036a0:	0009059b          	sext.w	a1,s2
    800036a4:	8556                	mv	a0,s5
    800036a6:	00000097          	auipc	ra,0x0
    800036aa:	da2080e7          	jalr	-606(ra) # 80003448 <iget>
    800036ae:	74a2                	ld	s1,40(sp)
    800036b0:	7902                	ld	s2,32(sp)
    800036b2:	69e2                	ld	s3,24(sp)
    800036b4:	6a42                	ld	s4,16(sp)
    800036b6:	6aa2                	ld	s5,8(sp)
    800036b8:	6b02                	ld	s6,0(sp)
    800036ba:	bf5d                	j	80003670 <ialloc+0x8c>

00000000800036bc <iupdate>:
{
    800036bc:	1101                	addi	sp,sp,-32
    800036be:	ec06                	sd	ra,24(sp)
    800036c0:	e822                	sd	s0,16(sp)
    800036c2:	e426                	sd	s1,8(sp)
    800036c4:	e04a                	sd	s2,0(sp)
    800036c6:	1000                	addi	s0,sp,32
    800036c8:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800036ca:	415c                	lw	a5,4(a0)
    800036cc:	0047d79b          	srliw	a5,a5,0x4
    800036d0:	0001e597          	auipc	a1,0x1e
    800036d4:	3005a583          	lw	a1,768(a1) # 800219d0 <sb+0x18>
    800036d8:	9dbd                	addw	a1,a1,a5
    800036da:	4108                	lw	a0,0(a0)
    800036dc:	00000097          	auipc	ra,0x0
    800036e0:	878080e7          	jalr	-1928(ra) # 80002f54 <bread>
    800036e4:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    800036e6:	05850793          	addi	a5,a0,88
    800036ea:	40d8                	lw	a4,4(s1)
    800036ec:	8b3d                	andi	a4,a4,15
    800036ee:	071a                	slli	a4,a4,0x6
    800036f0:	97ba                	add	a5,a5,a4
  dip->type = ip->type;
    800036f2:	04449703          	lh	a4,68(s1)
    800036f6:	00e79023          	sh	a4,0(a5)
  dip->major = ip->major;
    800036fa:	04649703          	lh	a4,70(s1)
    800036fe:	00e79123          	sh	a4,2(a5)
  dip->minor = ip->minor;
    80003702:	04849703          	lh	a4,72(s1)
    80003706:	00e79223          	sh	a4,4(a5)
  dip->nlink = ip->nlink;
    8000370a:	04a49703          	lh	a4,74(s1)
    8000370e:	00e79323          	sh	a4,6(a5)
  dip->size = ip->size;
    80003712:	44f8                	lw	a4,76(s1)
    80003714:	c798                	sw	a4,8(a5)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003716:	03400613          	li	a2,52
    8000371a:	05048593          	addi	a1,s1,80
    8000371e:	00c78513          	addi	a0,a5,12
    80003722:	ffffd097          	auipc	ra,0xffffd
    80003726:	6b6080e7          	jalr	1718(ra) # 80000dd8 <memmove>
  log_write(bp);
    8000372a:	854a                	mv	a0,s2
    8000372c:	00001097          	auipc	ra,0x1
    80003730:	c02080e7          	jalr	-1022(ra) # 8000432e <log_write>
  brelse(bp);
    80003734:	854a                	mv	a0,s2
    80003736:	00000097          	auipc	ra,0x0
    8000373a:	94e080e7          	jalr	-1714(ra) # 80003084 <brelse>
}
    8000373e:	60e2                	ld	ra,24(sp)
    80003740:	6442                	ld	s0,16(sp)
    80003742:	64a2                	ld	s1,8(sp)
    80003744:	6902                	ld	s2,0(sp)
    80003746:	6105                	addi	sp,sp,32
    80003748:	8082                	ret

000000008000374a <idup>:
{
    8000374a:	1101                	addi	sp,sp,-32
    8000374c:	ec06                	sd	ra,24(sp)
    8000374e:	e822                	sd	s0,16(sp)
    80003750:	e426                	sd	s1,8(sp)
    80003752:	1000                	addi	s0,sp,32
    80003754:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003756:	0001e517          	auipc	a0,0x1e
    8000375a:	28250513          	addi	a0,a0,642 # 800219d8 <itable>
    8000375e:	ffffd097          	auipc	ra,0xffffd
    80003762:	522080e7          	jalr	1314(ra) # 80000c80 <acquire>
  ip->ref++;
    80003766:	449c                	lw	a5,8(s1)
    80003768:	2785                	addiw	a5,a5,1
    8000376a:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    8000376c:	0001e517          	auipc	a0,0x1e
    80003770:	26c50513          	addi	a0,a0,620 # 800219d8 <itable>
    80003774:	ffffd097          	auipc	ra,0xffffd
    80003778:	5c0080e7          	jalr	1472(ra) # 80000d34 <release>
}
    8000377c:	8526                	mv	a0,s1
    8000377e:	60e2                	ld	ra,24(sp)
    80003780:	6442                	ld	s0,16(sp)
    80003782:	64a2                	ld	s1,8(sp)
    80003784:	6105                	addi	sp,sp,32
    80003786:	8082                	ret

0000000080003788 <ilock>:
{
    80003788:	1101                	addi	sp,sp,-32
    8000378a:	ec06                	sd	ra,24(sp)
    8000378c:	e822                	sd	s0,16(sp)
    8000378e:	e426                	sd	s1,8(sp)
    80003790:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003792:	c10d                	beqz	a0,800037b4 <ilock+0x2c>
    80003794:	84aa                	mv	s1,a0
    80003796:	451c                	lw	a5,8(a0)
    80003798:	00f05e63          	blez	a5,800037b4 <ilock+0x2c>
  acquiresleep(&ip->lock);
    8000379c:	0541                	addi	a0,a0,16
    8000379e:	00001097          	auipc	ra,0x1
    800037a2:	cae080e7          	jalr	-850(ra) # 8000444c <acquiresleep>
  if(ip->valid == 0){
    800037a6:	40bc                	lw	a5,64(s1)
    800037a8:	cf99                	beqz	a5,800037c6 <ilock+0x3e>
}
    800037aa:	60e2                	ld	ra,24(sp)
    800037ac:	6442                	ld	s0,16(sp)
    800037ae:	64a2                	ld	s1,8(sp)
    800037b0:	6105                	addi	sp,sp,32
    800037b2:	8082                	ret
    800037b4:	e04a                	sd	s2,0(sp)
    panic("ilock");
    800037b6:	00005517          	auipc	a0,0x5
    800037ba:	d2250513          	addi	a0,a0,-734 # 800084d8 <etext+0x4d8>
    800037be:	ffffd097          	auipc	ra,0xffffd
    800037c2:	da2080e7          	jalr	-606(ra) # 80000560 <panic>
    800037c6:	e04a                	sd	s2,0(sp)
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800037c8:	40dc                	lw	a5,4(s1)
    800037ca:	0047d79b          	srliw	a5,a5,0x4
    800037ce:	0001e597          	auipc	a1,0x1e
    800037d2:	2025a583          	lw	a1,514(a1) # 800219d0 <sb+0x18>
    800037d6:	9dbd                	addw	a1,a1,a5
    800037d8:	4088                	lw	a0,0(s1)
    800037da:	fffff097          	auipc	ra,0xfffff
    800037de:	77a080e7          	jalr	1914(ra) # 80002f54 <bread>
    800037e2:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    800037e4:	05850593          	addi	a1,a0,88
    800037e8:	40dc                	lw	a5,4(s1)
    800037ea:	8bbd                	andi	a5,a5,15
    800037ec:	079a                	slli	a5,a5,0x6
    800037ee:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    800037f0:	00059783          	lh	a5,0(a1)
    800037f4:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    800037f8:	00259783          	lh	a5,2(a1)
    800037fc:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003800:	00459783          	lh	a5,4(a1)
    80003804:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003808:	00659783          	lh	a5,6(a1)
    8000380c:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003810:	459c                	lw	a5,8(a1)
    80003812:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003814:	03400613          	li	a2,52
    80003818:	05b1                	addi	a1,a1,12
    8000381a:	05048513          	addi	a0,s1,80
    8000381e:	ffffd097          	auipc	ra,0xffffd
    80003822:	5ba080e7          	jalr	1466(ra) # 80000dd8 <memmove>
    brelse(bp);
    80003826:	854a                	mv	a0,s2
    80003828:	00000097          	auipc	ra,0x0
    8000382c:	85c080e7          	jalr	-1956(ra) # 80003084 <brelse>
    ip->valid = 1;
    80003830:	4785                	li	a5,1
    80003832:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003834:	04449783          	lh	a5,68(s1)
    80003838:	c399                	beqz	a5,8000383e <ilock+0xb6>
    8000383a:	6902                	ld	s2,0(sp)
    8000383c:	b7bd                	j	800037aa <ilock+0x22>
      panic("ilock: no type");
    8000383e:	00005517          	auipc	a0,0x5
    80003842:	ca250513          	addi	a0,a0,-862 # 800084e0 <etext+0x4e0>
    80003846:	ffffd097          	auipc	ra,0xffffd
    8000384a:	d1a080e7          	jalr	-742(ra) # 80000560 <panic>

000000008000384e <iunlock>:
{
    8000384e:	1101                	addi	sp,sp,-32
    80003850:	ec06                	sd	ra,24(sp)
    80003852:	e822                	sd	s0,16(sp)
    80003854:	e426                	sd	s1,8(sp)
    80003856:	e04a                	sd	s2,0(sp)
    80003858:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    8000385a:	c905                	beqz	a0,8000388a <iunlock+0x3c>
    8000385c:	84aa                	mv	s1,a0
    8000385e:	01050913          	addi	s2,a0,16
    80003862:	854a                	mv	a0,s2
    80003864:	00001097          	auipc	ra,0x1
    80003868:	c82080e7          	jalr	-894(ra) # 800044e6 <holdingsleep>
    8000386c:	cd19                	beqz	a0,8000388a <iunlock+0x3c>
    8000386e:	449c                	lw	a5,8(s1)
    80003870:	00f05d63          	blez	a5,8000388a <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003874:	854a                	mv	a0,s2
    80003876:	00001097          	auipc	ra,0x1
    8000387a:	c2c080e7          	jalr	-980(ra) # 800044a2 <releasesleep>
}
    8000387e:	60e2                	ld	ra,24(sp)
    80003880:	6442                	ld	s0,16(sp)
    80003882:	64a2                	ld	s1,8(sp)
    80003884:	6902                	ld	s2,0(sp)
    80003886:	6105                	addi	sp,sp,32
    80003888:	8082                	ret
    panic("iunlock");
    8000388a:	00005517          	auipc	a0,0x5
    8000388e:	c6650513          	addi	a0,a0,-922 # 800084f0 <etext+0x4f0>
    80003892:	ffffd097          	auipc	ra,0xffffd
    80003896:	cce080e7          	jalr	-818(ra) # 80000560 <panic>

000000008000389a <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    8000389a:	7179                	addi	sp,sp,-48
    8000389c:	f406                	sd	ra,40(sp)
    8000389e:	f022                	sd	s0,32(sp)
    800038a0:	ec26                	sd	s1,24(sp)
    800038a2:	e84a                	sd	s2,16(sp)
    800038a4:	e44e                	sd	s3,8(sp)
    800038a6:	1800                	addi	s0,sp,48
    800038a8:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    800038aa:	05050493          	addi	s1,a0,80
    800038ae:	08050913          	addi	s2,a0,128
    800038b2:	a021                	j	800038ba <itrunc+0x20>
    800038b4:	0491                	addi	s1,s1,4
    800038b6:	01248d63          	beq	s1,s2,800038d0 <itrunc+0x36>
    if(ip->addrs[i]){
    800038ba:	408c                	lw	a1,0(s1)
    800038bc:	dde5                	beqz	a1,800038b4 <itrunc+0x1a>
      bfree(ip->dev, ip->addrs[i]);
    800038be:	0009a503          	lw	a0,0(s3)
    800038c2:	00000097          	auipc	ra,0x0
    800038c6:	8d6080e7          	jalr	-1834(ra) # 80003198 <bfree>
      ip->addrs[i] = 0;
    800038ca:	0004a023          	sw	zero,0(s1)
    800038ce:	b7dd                	j	800038b4 <itrunc+0x1a>
    }
  }

  if(ip->addrs[NDIRECT]){
    800038d0:	0809a583          	lw	a1,128(s3)
    800038d4:	ed99                	bnez	a1,800038f2 <itrunc+0x58>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    800038d6:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    800038da:	854e                	mv	a0,s3
    800038dc:	00000097          	auipc	ra,0x0
    800038e0:	de0080e7          	jalr	-544(ra) # 800036bc <iupdate>
}
    800038e4:	70a2                	ld	ra,40(sp)
    800038e6:	7402                	ld	s0,32(sp)
    800038e8:	64e2                	ld	s1,24(sp)
    800038ea:	6942                	ld	s2,16(sp)
    800038ec:	69a2                	ld	s3,8(sp)
    800038ee:	6145                	addi	sp,sp,48
    800038f0:	8082                	ret
    800038f2:	e052                	sd	s4,0(sp)
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    800038f4:	0009a503          	lw	a0,0(s3)
    800038f8:	fffff097          	auipc	ra,0xfffff
    800038fc:	65c080e7          	jalr	1628(ra) # 80002f54 <bread>
    80003900:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003902:	05850493          	addi	s1,a0,88
    80003906:	45850913          	addi	s2,a0,1112
    8000390a:	a021                	j	80003912 <itrunc+0x78>
    8000390c:	0491                	addi	s1,s1,4
    8000390e:	01248b63          	beq	s1,s2,80003924 <itrunc+0x8a>
      if(a[j])
    80003912:	408c                	lw	a1,0(s1)
    80003914:	dde5                	beqz	a1,8000390c <itrunc+0x72>
        bfree(ip->dev, a[j]);
    80003916:	0009a503          	lw	a0,0(s3)
    8000391a:	00000097          	auipc	ra,0x0
    8000391e:	87e080e7          	jalr	-1922(ra) # 80003198 <bfree>
    80003922:	b7ed                	j	8000390c <itrunc+0x72>
    brelse(bp);
    80003924:	8552                	mv	a0,s4
    80003926:	fffff097          	auipc	ra,0xfffff
    8000392a:	75e080e7          	jalr	1886(ra) # 80003084 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    8000392e:	0809a583          	lw	a1,128(s3)
    80003932:	0009a503          	lw	a0,0(s3)
    80003936:	00000097          	auipc	ra,0x0
    8000393a:	862080e7          	jalr	-1950(ra) # 80003198 <bfree>
    ip->addrs[NDIRECT] = 0;
    8000393e:	0809a023          	sw	zero,128(s3)
    80003942:	6a02                	ld	s4,0(sp)
    80003944:	bf49                	j	800038d6 <itrunc+0x3c>

0000000080003946 <iput>:
{
    80003946:	1101                	addi	sp,sp,-32
    80003948:	ec06                	sd	ra,24(sp)
    8000394a:	e822                	sd	s0,16(sp)
    8000394c:	e426                	sd	s1,8(sp)
    8000394e:	1000                	addi	s0,sp,32
    80003950:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003952:	0001e517          	auipc	a0,0x1e
    80003956:	08650513          	addi	a0,a0,134 # 800219d8 <itable>
    8000395a:	ffffd097          	auipc	ra,0xffffd
    8000395e:	326080e7          	jalr	806(ra) # 80000c80 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003962:	4498                	lw	a4,8(s1)
    80003964:	4785                	li	a5,1
    80003966:	02f70263          	beq	a4,a5,8000398a <iput+0x44>
  ip->ref--;
    8000396a:	449c                	lw	a5,8(s1)
    8000396c:	37fd                	addiw	a5,a5,-1
    8000396e:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003970:	0001e517          	auipc	a0,0x1e
    80003974:	06850513          	addi	a0,a0,104 # 800219d8 <itable>
    80003978:	ffffd097          	auipc	ra,0xffffd
    8000397c:	3bc080e7          	jalr	956(ra) # 80000d34 <release>
}
    80003980:	60e2                	ld	ra,24(sp)
    80003982:	6442                	ld	s0,16(sp)
    80003984:	64a2                	ld	s1,8(sp)
    80003986:	6105                	addi	sp,sp,32
    80003988:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    8000398a:	40bc                	lw	a5,64(s1)
    8000398c:	dff9                	beqz	a5,8000396a <iput+0x24>
    8000398e:	04a49783          	lh	a5,74(s1)
    80003992:	ffe1                	bnez	a5,8000396a <iput+0x24>
    80003994:	e04a                	sd	s2,0(sp)
    acquiresleep(&ip->lock);
    80003996:	01048913          	addi	s2,s1,16
    8000399a:	854a                	mv	a0,s2
    8000399c:	00001097          	auipc	ra,0x1
    800039a0:	ab0080e7          	jalr	-1360(ra) # 8000444c <acquiresleep>
    release(&itable.lock);
    800039a4:	0001e517          	auipc	a0,0x1e
    800039a8:	03450513          	addi	a0,a0,52 # 800219d8 <itable>
    800039ac:	ffffd097          	auipc	ra,0xffffd
    800039b0:	388080e7          	jalr	904(ra) # 80000d34 <release>
    itrunc(ip);
    800039b4:	8526                	mv	a0,s1
    800039b6:	00000097          	auipc	ra,0x0
    800039ba:	ee4080e7          	jalr	-284(ra) # 8000389a <itrunc>
    ip->type = 0;
    800039be:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    800039c2:	8526                	mv	a0,s1
    800039c4:	00000097          	auipc	ra,0x0
    800039c8:	cf8080e7          	jalr	-776(ra) # 800036bc <iupdate>
    ip->valid = 0;
    800039cc:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    800039d0:	854a                	mv	a0,s2
    800039d2:	00001097          	auipc	ra,0x1
    800039d6:	ad0080e7          	jalr	-1328(ra) # 800044a2 <releasesleep>
    acquire(&itable.lock);
    800039da:	0001e517          	auipc	a0,0x1e
    800039de:	ffe50513          	addi	a0,a0,-2 # 800219d8 <itable>
    800039e2:	ffffd097          	auipc	ra,0xffffd
    800039e6:	29e080e7          	jalr	670(ra) # 80000c80 <acquire>
    800039ea:	6902                	ld	s2,0(sp)
    800039ec:	bfbd                	j	8000396a <iput+0x24>

00000000800039ee <iunlockput>:
{
    800039ee:	1101                	addi	sp,sp,-32
    800039f0:	ec06                	sd	ra,24(sp)
    800039f2:	e822                	sd	s0,16(sp)
    800039f4:	e426                	sd	s1,8(sp)
    800039f6:	1000                	addi	s0,sp,32
    800039f8:	84aa                	mv	s1,a0
  iunlock(ip);
    800039fa:	00000097          	auipc	ra,0x0
    800039fe:	e54080e7          	jalr	-428(ra) # 8000384e <iunlock>
  iput(ip);
    80003a02:	8526                	mv	a0,s1
    80003a04:	00000097          	auipc	ra,0x0
    80003a08:	f42080e7          	jalr	-190(ra) # 80003946 <iput>
}
    80003a0c:	60e2                	ld	ra,24(sp)
    80003a0e:	6442                	ld	s0,16(sp)
    80003a10:	64a2                	ld	s1,8(sp)
    80003a12:	6105                	addi	sp,sp,32
    80003a14:	8082                	ret

0000000080003a16 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003a16:	1141                	addi	sp,sp,-16
    80003a18:	e422                	sd	s0,8(sp)
    80003a1a:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003a1c:	411c                	lw	a5,0(a0)
    80003a1e:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003a20:	415c                	lw	a5,4(a0)
    80003a22:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003a24:	04451783          	lh	a5,68(a0)
    80003a28:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003a2c:	04a51783          	lh	a5,74(a0)
    80003a30:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003a34:	04c56783          	lwu	a5,76(a0)
    80003a38:	e99c                	sd	a5,16(a1)
}
    80003a3a:	6422                	ld	s0,8(sp)
    80003a3c:	0141                	addi	sp,sp,16
    80003a3e:	8082                	ret

0000000080003a40 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003a40:	457c                	lw	a5,76(a0)
    80003a42:	10d7e563          	bltu	a5,a3,80003b4c <readi+0x10c>
{
    80003a46:	7159                	addi	sp,sp,-112
    80003a48:	f486                	sd	ra,104(sp)
    80003a4a:	f0a2                	sd	s0,96(sp)
    80003a4c:	eca6                	sd	s1,88(sp)
    80003a4e:	e0d2                	sd	s4,64(sp)
    80003a50:	fc56                	sd	s5,56(sp)
    80003a52:	f85a                	sd	s6,48(sp)
    80003a54:	f45e                	sd	s7,40(sp)
    80003a56:	1880                	addi	s0,sp,112
    80003a58:	8b2a                	mv	s6,a0
    80003a5a:	8bae                	mv	s7,a1
    80003a5c:	8a32                	mv	s4,a2
    80003a5e:	84b6                	mv	s1,a3
    80003a60:	8aba                	mv	s5,a4
  if(off > ip->size || off + n < off)
    80003a62:	9f35                	addw	a4,a4,a3
    return 0;
    80003a64:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003a66:	0cd76a63          	bltu	a4,a3,80003b3a <readi+0xfa>
    80003a6a:	e4ce                	sd	s3,72(sp)
  if(off + n > ip->size)
    80003a6c:	00e7f463          	bgeu	a5,a4,80003a74 <readi+0x34>
    n = ip->size - off;
    80003a70:	40d78abb          	subw	s5,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003a74:	0a0a8963          	beqz	s5,80003b26 <readi+0xe6>
    80003a78:	e8ca                	sd	s2,80(sp)
    80003a7a:	f062                	sd	s8,32(sp)
    80003a7c:	ec66                	sd	s9,24(sp)
    80003a7e:	e86a                	sd	s10,16(sp)
    80003a80:	e46e                	sd	s11,8(sp)
    80003a82:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003a84:	40000c93          	li	s9,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003a88:	5c7d                	li	s8,-1
    80003a8a:	a82d                	j	80003ac4 <readi+0x84>
    80003a8c:	020d1d93          	slli	s11,s10,0x20
    80003a90:	020ddd93          	srli	s11,s11,0x20
    80003a94:	05890613          	addi	a2,s2,88
    80003a98:	86ee                	mv	a3,s11
    80003a9a:	963a                	add	a2,a2,a4
    80003a9c:	85d2                	mv	a1,s4
    80003a9e:	855e                	mv	a0,s7
    80003aa0:	fffff097          	auipc	ra,0xfffff
    80003aa4:	abe080e7          	jalr	-1346(ra) # 8000255e <either_copyout>
    80003aa8:	05850d63          	beq	a0,s8,80003b02 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003aac:	854a                	mv	a0,s2
    80003aae:	fffff097          	auipc	ra,0xfffff
    80003ab2:	5d6080e7          	jalr	1494(ra) # 80003084 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003ab6:	013d09bb          	addw	s3,s10,s3
    80003aba:	009d04bb          	addw	s1,s10,s1
    80003abe:	9a6e                	add	s4,s4,s11
    80003ac0:	0559fd63          	bgeu	s3,s5,80003b1a <readi+0xda>
    uint addr = bmap(ip, off/BSIZE);
    80003ac4:	00a4d59b          	srliw	a1,s1,0xa
    80003ac8:	855a                	mv	a0,s6
    80003aca:	00000097          	auipc	ra,0x0
    80003ace:	88e080e7          	jalr	-1906(ra) # 80003358 <bmap>
    80003ad2:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003ad6:	c9b1                	beqz	a1,80003b2a <readi+0xea>
    bp = bread(ip->dev, addr);
    80003ad8:	000b2503          	lw	a0,0(s6)
    80003adc:	fffff097          	auipc	ra,0xfffff
    80003ae0:	478080e7          	jalr	1144(ra) # 80002f54 <bread>
    80003ae4:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003ae6:	3ff4f713          	andi	a4,s1,1023
    80003aea:	40ec87bb          	subw	a5,s9,a4
    80003aee:	413a86bb          	subw	a3,s5,s3
    80003af2:	8d3e                	mv	s10,a5
    80003af4:	2781                	sext.w	a5,a5
    80003af6:	0006861b          	sext.w	a2,a3
    80003afa:	f8f679e3          	bgeu	a2,a5,80003a8c <readi+0x4c>
    80003afe:	8d36                	mv	s10,a3
    80003b00:	b771                	j	80003a8c <readi+0x4c>
      brelse(bp);
    80003b02:	854a                	mv	a0,s2
    80003b04:	fffff097          	auipc	ra,0xfffff
    80003b08:	580080e7          	jalr	1408(ra) # 80003084 <brelse>
      tot = -1;
    80003b0c:	59fd                	li	s3,-1
      break;
    80003b0e:	6946                	ld	s2,80(sp)
    80003b10:	7c02                	ld	s8,32(sp)
    80003b12:	6ce2                	ld	s9,24(sp)
    80003b14:	6d42                	ld	s10,16(sp)
    80003b16:	6da2                	ld	s11,8(sp)
    80003b18:	a831                	j	80003b34 <readi+0xf4>
    80003b1a:	6946                	ld	s2,80(sp)
    80003b1c:	7c02                	ld	s8,32(sp)
    80003b1e:	6ce2                	ld	s9,24(sp)
    80003b20:	6d42                	ld	s10,16(sp)
    80003b22:	6da2                	ld	s11,8(sp)
    80003b24:	a801                	j	80003b34 <readi+0xf4>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003b26:	89d6                	mv	s3,s5
    80003b28:	a031                	j	80003b34 <readi+0xf4>
    80003b2a:	6946                	ld	s2,80(sp)
    80003b2c:	7c02                	ld	s8,32(sp)
    80003b2e:	6ce2                	ld	s9,24(sp)
    80003b30:	6d42                	ld	s10,16(sp)
    80003b32:	6da2                	ld	s11,8(sp)
  }
  return tot;
    80003b34:	0009851b          	sext.w	a0,s3
    80003b38:	69a6                	ld	s3,72(sp)
}
    80003b3a:	70a6                	ld	ra,104(sp)
    80003b3c:	7406                	ld	s0,96(sp)
    80003b3e:	64e6                	ld	s1,88(sp)
    80003b40:	6a06                	ld	s4,64(sp)
    80003b42:	7ae2                	ld	s5,56(sp)
    80003b44:	7b42                	ld	s6,48(sp)
    80003b46:	7ba2                	ld	s7,40(sp)
    80003b48:	6165                	addi	sp,sp,112
    80003b4a:	8082                	ret
    return 0;
    80003b4c:	4501                	li	a0,0
}
    80003b4e:	8082                	ret

0000000080003b50 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003b50:	457c                	lw	a5,76(a0)
    80003b52:	10d7ee63          	bltu	a5,a3,80003c6e <writei+0x11e>
{
    80003b56:	7159                	addi	sp,sp,-112
    80003b58:	f486                	sd	ra,104(sp)
    80003b5a:	f0a2                	sd	s0,96(sp)
    80003b5c:	e8ca                	sd	s2,80(sp)
    80003b5e:	e0d2                	sd	s4,64(sp)
    80003b60:	fc56                	sd	s5,56(sp)
    80003b62:	f85a                	sd	s6,48(sp)
    80003b64:	f45e                	sd	s7,40(sp)
    80003b66:	1880                	addi	s0,sp,112
    80003b68:	8aaa                	mv	s5,a0
    80003b6a:	8bae                	mv	s7,a1
    80003b6c:	8a32                	mv	s4,a2
    80003b6e:	8936                	mv	s2,a3
    80003b70:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003b72:	00e687bb          	addw	a5,a3,a4
    80003b76:	0ed7ee63          	bltu	a5,a3,80003c72 <writei+0x122>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003b7a:	00043737          	lui	a4,0x43
    80003b7e:	0ef76c63          	bltu	a4,a5,80003c76 <writei+0x126>
    80003b82:	e4ce                	sd	s3,72(sp)
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003b84:	0c0b0d63          	beqz	s6,80003c5e <writei+0x10e>
    80003b88:	eca6                	sd	s1,88(sp)
    80003b8a:	f062                	sd	s8,32(sp)
    80003b8c:	ec66                	sd	s9,24(sp)
    80003b8e:	e86a                	sd	s10,16(sp)
    80003b90:	e46e                	sd	s11,8(sp)
    80003b92:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003b94:	40000c93          	li	s9,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003b98:	5c7d                	li	s8,-1
    80003b9a:	a091                	j	80003bde <writei+0x8e>
    80003b9c:	020d1d93          	slli	s11,s10,0x20
    80003ba0:	020ddd93          	srli	s11,s11,0x20
    80003ba4:	05848513          	addi	a0,s1,88
    80003ba8:	86ee                	mv	a3,s11
    80003baa:	8652                	mv	a2,s4
    80003bac:	85de                	mv	a1,s7
    80003bae:	953a                	add	a0,a0,a4
    80003bb0:	fffff097          	auipc	ra,0xfffff
    80003bb4:	a04080e7          	jalr	-1532(ra) # 800025b4 <either_copyin>
    80003bb8:	07850263          	beq	a0,s8,80003c1c <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003bbc:	8526                	mv	a0,s1
    80003bbe:	00000097          	auipc	ra,0x0
    80003bc2:	770080e7          	jalr	1904(ra) # 8000432e <log_write>
    brelse(bp);
    80003bc6:	8526                	mv	a0,s1
    80003bc8:	fffff097          	auipc	ra,0xfffff
    80003bcc:	4bc080e7          	jalr	1212(ra) # 80003084 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003bd0:	013d09bb          	addw	s3,s10,s3
    80003bd4:	012d093b          	addw	s2,s10,s2
    80003bd8:	9a6e                	add	s4,s4,s11
    80003bda:	0569f663          	bgeu	s3,s6,80003c26 <writei+0xd6>
    uint addr = bmap(ip, off/BSIZE);
    80003bde:	00a9559b          	srliw	a1,s2,0xa
    80003be2:	8556                	mv	a0,s5
    80003be4:	fffff097          	auipc	ra,0xfffff
    80003be8:	774080e7          	jalr	1908(ra) # 80003358 <bmap>
    80003bec:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003bf0:	c99d                	beqz	a1,80003c26 <writei+0xd6>
    bp = bread(ip->dev, addr);
    80003bf2:	000aa503          	lw	a0,0(s5)
    80003bf6:	fffff097          	auipc	ra,0xfffff
    80003bfa:	35e080e7          	jalr	862(ra) # 80002f54 <bread>
    80003bfe:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003c00:	3ff97713          	andi	a4,s2,1023
    80003c04:	40ec87bb          	subw	a5,s9,a4
    80003c08:	413b06bb          	subw	a3,s6,s3
    80003c0c:	8d3e                	mv	s10,a5
    80003c0e:	2781                	sext.w	a5,a5
    80003c10:	0006861b          	sext.w	a2,a3
    80003c14:	f8f674e3          	bgeu	a2,a5,80003b9c <writei+0x4c>
    80003c18:	8d36                	mv	s10,a3
    80003c1a:	b749                	j	80003b9c <writei+0x4c>
      brelse(bp);
    80003c1c:	8526                	mv	a0,s1
    80003c1e:	fffff097          	auipc	ra,0xfffff
    80003c22:	466080e7          	jalr	1126(ra) # 80003084 <brelse>
  }

  if(off > ip->size)
    80003c26:	04caa783          	lw	a5,76(s5)
    80003c2a:	0327fc63          	bgeu	a5,s2,80003c62 <writei+0x112>
    ip->size = off;
    80003c2e:	052aa623          	sw	s2,76(s5)
    80003c32:	64e6                	ld	s1,88(sp)
    80003c34:	7c02                	ld	s8,32(sp)
    80003c36:	6ce2                	ld	s9,24(sp)
    80003c38:	6d42                	ld	s10,16(sp)
    80003c3a:	6da2                	ld	s11,8(sp)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003c3c:	8556                	mv	a0,s5
    80003c3e:	00000097          	auipc	ra,0x0
    80003c42:	a7e080e7          	jalr	-1410(ra) # 800036bc <iupdate>

  return tot;
    80003c46:	0009851b          	sext.w	a0,s3
    80003c4a:	69a6                	ld	s3,72(sp)
}
    80003c4c:	70a6                	ld	ra,104(sp)
    80003c4e:	7406                	ld	s0,96(sp)
    80003c50:	6946                	ld	s2,80(sp)
    80003c52:	6a06                	ld	s4,64(sp)
    80003c54:	7ae2                	ld	s5,56(sp)
    80003c56:	7b42                	ld	s6,48(sp)
    80003c58:	7ba2                	ld	s7,40(sp)
    80003c5a:	6165                	addi	sp,sp,112
    80003c5c:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003c5e:	89da                	mv	s3,s6
    80003c60:	bff1                	j	80003c3c <writei+0xec>
    80003c62:	64e6                	ld	s1,88(sp)
    80003c64:	7c02                	ld	s8,32(sp)
    80003c66:	6ce2                	ld	s9,24(sp)
    80003c68:	6d42                	ld	s10,16(sp)
    80003c6a:	6da2                	ld	s11,8(sp)
    80003c6c:	bfc1                	j	80003c3c <writei+0xec>
    return -1;
    80003c6e:	557d                	li	a0,-1
}
    80003c70:	8082                	ret
    return -1;
    80003c72:	557d                	li	a0,-1
    80003c74:	bfe1                	j	80003c4c <writei+0xfc>
    return -1;
    80003c76:	557d                	li	a0,-1
    80003c78:	bfd1                	j	80003c4c <writei+0xfc>

0000000080003c7a <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003c7a:	1141                	addi	sp,sp,-16
    80003c7c:	e406                	sd	ra,8(sp)
    80003c7e:	e022                	sd	s0,0(sp)
    80003c80:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003c82:	4639                	li	a2,14
    80003c84:	ffffd097          	auipc	ra,0xffffd
    80003c88:	1c8080e7          	jalr	456(ra) # 80000e4c <strncmp>
}
    80003c8c:	60a2                	ld	ra,8(sp)
    80003c8e:	6402                	ld	s0,0(sp)
    80003c90:	0141                	addi	sp,sp,16
    80003c92:	8082                	ret

0000000080003c94 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003c94:	7139                	addi	sp,sp,-64
    80003c96:	fc06                	sd	ra,56(sp)
    80003c98:	f822                	sd	s0,48(sp)
    80003c9a:	f426                	sd	s1,40(sp)
    80003c9c:	f04a                	sd	s2,32(sp)
    80003c9e:	ec4e                	sd	s3,24(sp)
    80003ca0:	e852                	sd	s4,16(sp)
    80003ca2:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003ca4:	04451703          	lh	a4,68(a0)
    80003ca8:	4785                	li	a5,1
    80003caa:	00f71a63          	bne	a4,a5,80003cbe <dirlookup+0x2a>
    80003cae:	892a                	mv	s2,a0
    80003cb0:	89ae                	mv	s3,a1
    80003cb2:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003cb4:	457c                	lw	a5,76(a0)
    80003cb6:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003cb8:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003cba:	e79d                	bnez	a5,80003ce8 <dirlookup+0x54>
    80003cbc:	a8a5                	j	80003d34 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003cbe:	00005517          	auipc	a0,0x5
    80003cc2:	83a50513          	addi	a0,a0,-1990 # 800084f8 <etext+0x4f8>
    80003cc6:	ffffd097          	auipc	ra,0xffffd
    80003cca:	89a080e7          	jalr	-1894(ra) # 80000560 <panic>
      panic("dirlookup read");
    80003cce:	00005517          	auipc	a0,0x5
    80003cd2:	84250513          	addi	a0,a0,-1982 # 80008510 <etext+0x510>
    80003cd6:	ffffd097          	auipc	ra,0xffffd
    80003cda:	88a080e7          	jalr	-1910(ra) # 80000560 <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003cde:	24c1                	addiw	s1,s1,16
    80003ce0:	04c92783          	lw	a5,76(s2)
    80003ce4:	04f4f763          	bgeu	s1,a5,80003d32 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003ce8:	4741                	li	a4,16
    80003cea:	86a6                	mv	a3,s1
    80003cec:	fc040613          	addi	a2,s0,-64
    80003cf0:	4581                	li	a1,0
    80003cf2:	854a                	mv	a0,s2
    80003cf4:	00000097          	auipc	ra,0x0
    80003cf8:	d4c080e7          	jalr	-692(ra) # 80003a40 <readi>
    80003cfc:	47c1                	li	a5,16
    80003cfe:	fcf518e3          	bne	a0,a5,80003cce <dirlookup+0x3a>
    if(de.inum == 0)
    80003d02:	fc045783          	lhu	a5,-64(s0)
    80003d06:	dfe1                	beqz	a5,80003cde <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003d08:	fc240593          	addi	a1,s0,-62
    80003d0c:	854e                	mv	a0,s3
    80003d0e:	00000097          	auipc	ra,0x0
    80003d12:	f6c080e7          	jalr	-148(ra) # 80003c7a <namecmp>
    80003d16:	f561                	bnez	a0,80003cde <dirlookup+0x4a>
      if(poff)
    80003d18:	000a0463          	beqz	s4,80003d20 <dirlookup+0x8c>
        *poff = off;
    80003d1c:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003d20:	fc045583          	lhu	a1,-64(s0)
    80003d24:	00092503          	lw	a0,0(s2)
    80003d28:	fffff097          	auipc	ra,0xfffff
    80003d2c:	720080e7          	jalr	1824(ra) # 80003448 <iget>
    80003d30:	a011                	j	80003d34 <dirlookup+0xa0>
  return 0;
    80003d32:	4501                	li	a0,0
}
    80003d34:	70e2                	ld	ra,56(sp)
    80003d36:	7442                	ld	s0,48(sp)
    80003d38:	74a2                	ld	s1,40(sp)
    80003d3a:	7902                	ld	s2,32(sp)
    80003d3c:	69e2                	ld	s3,24(sp)
    80003d3e:	6a42                	ld	s4,16(sp)
    80003d40:	6121                	addi	sp,sp,64
    80003d42:	8082                	ret

0000000080003d44 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003d44:	711d                	addi	sp,sp,-96
    80003d46:	ec86                	sd	ra,88(sp)
    80003d48:	e8a2                	sd	s0,80(sp)
    80003d4a:	e4a6                	sd	s1,72(sp)
    80003d4c:	e0ca                	sd	s2,64(sp)
    80003d4e:	fc4e                	sd	s3,56(sp)
    80003d50:	f852                	sd	s4,48(sp)
    80003d52:	f456                	sd	s5,40(sp)
    80003d54:	f05a                	sd	s6,32(sp)
    80003d56:	ec5e                	sd	s7,24(sp)
    80003d58:	e862                	sd	s8,16(sp)
    80003d5a:	e466                	sd	s9,8(sp)
    80003d5c:	1080                	addi	s0,sp,96
    80003d5e:	84aa                	mv	s1,a0
    80003d60:	8b2e                	mv	s6,a1
    80003d62:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003d64:	00054703          	lbu	a4,0(a0)
    80003d68:	02f00793          	li	a5,47
    80003d6c:	02f70263          	beq	a4,a5,80003d90 <namex+0x4c>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003d70:	ffffe097          	auipc	ra,0xffffe
    80003d74:	d3c080e7          	jalr	-708(ra) # 80001aac <myproc>
    80003d78:	15053503          	ld	a0,336(a0)
    80003d7c:	00000097          	auipc	ra,0x0
    80003d80:	9ce080e7          	jalr	-1586(ra) # 8000374a <idup>
    80003d84:	8a2a                	mv	s4,a0
  while(*path == '/')
    80003d86:	02f00913          	li	s2,47
  if(len >= DIRSIZ)
    80003d8a:	4c35                	li	s8,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003d8c:	4b85                	li	s7,1
    80003d8e:	a875                	j	80003e4a <namex+0x106>
    ip = iget(ROOTDEV, ROOTINO);
    80003d90:	4585                	li	a1,1
    80003d92:	4505                	li	a0,1
    80003d94:	fffff097          	auipc	ra,0xfffff
    80003d98:	6b4080e7          	jalr	1716(ra) # 80003448 <iget>
    80003d9c:	8a2a                	mv	s4,a0
    80003d9e:	b7e5                	j	80003d86 <namex+0x42>
      iunlockput(ip);
    80003da0:	8552                	mv	a0,s4
    80003da2:	00000097          	auipc	ra,0x0
    80003da6:	c4c080e7          	jalr	-948(ra) # 800039ee <iunlockput>
      return 0;
    80003daa:	4a01                	li	s4,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003dac:	8552                	mv	a0,s4
    80003dae:	60e6                	ld	ra,88(sp)
    80003db0:	6446                	ld	s0,80(sp)
    80003db2:	64a6                	ld	s1,72(sp)
    80003db4:	6906                	ld	s2,64(sp)
    80003db6:	79e2                	ld	s3,56(sp)
    80003db8:	7a42                	ld	s4,48(sp)
    80003dba:	7aa2                	ld	s5,40(sp)
    80003dbc:	7b02                	ld	s6,32(sp)
    80003dbe:	6be2                	ld	s7,24(sp)
    80003dc0:	6c42                	ld	s8,16(sp)
    80003dc2:	6ca2                	ld	s9,8(sp)
    80003dc4:	6125                	addi	sp,sp,96
    80003dc6:	8082                	ret
      iunlock(ip);
    80003dc8:	8552                	mv	a0,s4
    80003dca:	00000097          	auipc	ra,0x0
    80003dce:	a84080e7          	jalr	-1404(ra) # 8000384e <iunlock>
      return ip;
    80003dd2:	bfe9                	j	80003dac <namex+0x68>
      iunlockput(ip);
    80003dd4:	8552                	mv	a0,s4
    80003dd6:	00000097          	auipc	ra,0x0
    80003dda:	c18080e7          	jalr	-1000(ra) # 800039ee <iunlockput>
      return 0;
    80003dde:	8a4e                	mv	s4,s3
    80003de0:	b7f1                	j	80003dac <namex+0x68>
  len = path - s;
    80003de2:	40998633          	sub	a2,s3,s1
    80003de6:	00060c9b          	sext.w	s9,a2
  if(len >= DIRSIZ)
    80003dea:	099c5863          	bge	s8,s9,80003e7a <namex+0x136>
    memmove(name, s, DIRSIZ);
    80003dee:	4639                	li	a2,14
    80003df0:	85a6                	mv	a1,s1
    80003df2:	8556                	mv	a0,s5
    80003df4:	ffffd097          	auipc	ra,0xffffd
    80003df8:	fe4080e7          	jalr	-28(ra) # 80000dd8 <memmove>
    80003dfc:	84ce                	mv	s1,s3
  while(*path == '/')
    80003dfe:	0004c783          	lbu	a5,0(s1)
    80003e02:	01279763          	bne	a5,s2,80003e10 <namex+0xcc>
    path++;
    80003e06:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003e08:	0004c783          	lbu	a5,0(s1)
    80003e0c:	ff278de3          	beq	a5,s2,80003e06 <namex+0xc2>
    ilock(ip);
    80003e10:	8552                	mv	a0,s4
    80003e12:	00000097          	auipc	ra,0x0
    80003e16:	976080e7          	jalr	-1674(ra) # 80003788 <ilock>
    if(ip->type != T_DIR){
    80003e1a:	044a1783          	lh	a5,68(s4)
    80003e1e:	f97791e3          	bne	a5,s7,80003da0 <namex+0x5c>
    if(nameiparent && *path == '\0'){
    80003e22:	000b0563          	beqz	s6,80003e2c <namex+0xe8>
    80003e26:	0004c783          	lbu	a5,0(s1)
    80003e2a:	dfd9                	beqz	a5,80003dc8 <namex+0x84>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003e2c:	4601                	li	a2,0
    80003e2e:	85d6                	mv	a1,s5
    80003e30:	8552                	mv	a0,s4
    80003e32:	00000097          	auipc	ra,0x0
    80003e36:	e62080e7          	jalr	-414(ra) # 80003c94 <dirlookup>
    80003e3a:	89aa                	mv	s3,a0
    80003e3c:	dd41                	beqz	a0,80003dd4 <namex+0x90>
    iunlockput(ip);
    80003e3e:	8552                	mv	a0,s4
    80003e40:	00000097          	auipc	ra,0x0
    80003e44:	bae080e7          	jalr	-1106(ra) # 800039ee <iunlockput>
    ip = next;
    80003e48:	8a4e                	mv	s4,s3
  while(*path == '/')
    80003e4a:	0004c783          	lbu	a5,0(s1)
    80003e4e:	01279763          	bne	a5,s2,80003e5c <namex+0x118>
    path++;
    80003e52:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003e54:	0004c783          	lbu	a5,0(s1)
    80003e58:	ff278de3          	beq	a5,s2,80003e52 <namex+0x10e>
  if(*path == 0)
    80003e5c:	cb9d                	beqz	a5,80003e92 <namex+0x14e>
  while(*path != '/' && *path != 0)
    80003e5e:	0004c783          	lbu	a5,0(s1)
    80003e62:	89a6                	mv	s3,s1
  len = path - s;
    80003e64:	4c81                	li	s9,0
    80003e66:	4601                	li	a2,0
  while(*path != '/' && *path != 0)
    80003e68:	01278963          	beq	a5,s2,80003e7a <namex+0x136>
    80003e6c:	dbbd                	beqz	a5,80003de2 <namex+0x9e>
    path++;
    80003e6e:	0985                	addi	s3,s3,1
  while(*path != '/' && *path != 0)
    80003e70:	0009c783          	lbu	a5,0(s3)
    80003e74:	ff279ce3          	bne	a5,s2,80003e6c <namex+0x128>
    80003e78:	b7ad                	j	80003de2 <namex+0x9e>
    memmove(name, s, len);
    80003e7a:	2601                	sext.w	a2,a2
    80003e7c:	85a6                	mv	a1,s1
    80003e7e:	8556                	mv	a0,s5
    80003e80:	ffffd097          	auipc	ra,0xffffd
    80003e84:	f58080e7          	jalr	-168(ra) # 80000dd8 <memmove>
    name[len] = 0;
    80003e88:	9cd6                	add	s9,s9,s5
    80003e8a:	000c8023          	sb	zero,0(s9) # 2000 <_entry-0x7fffe000>
    80003e8e:	84ce                	mv	s1,s3
    80003e90:	b7bd                	j	80003dfe <namex+0xba>
  if(nameiparent){
    80003e92:	f00b0de3          	beqz	s6,80003dac <namex+0x68>
    iput(ip);
    80003e96:	8552                	mv	a0,s4
    80003e98:	00000097          	auipc	ra,0x0
    80003e9c:	aae080e7          	jalr	-1362(ra) # 80003946 <iput>
    return 0;
    80003ea0:	4a01                	li	s4,0
    80003ea2:	b729                	j	80003dac <namex+0x68>

0000000080003ea4 <dirlink>:
{
    80003ea4:	7139                	addi	sp,sp,-64
    80003ea6:	fc06                	sd	ra,56(sp)
    80003ea8:	f822                	sd	s0,48(sp)
    80003eaa:	f04a                	sd	s2,32(sp)
    80003eac:	ec4e                	sd	s3,24(sp)
    80003eae:	e852                	sd	s4,16(sp)
    80003eb0:	0080                	addi	s0,sp,64
    80003eb2:	892a                	mv	s2,a0
    80003eb4:	8a2e                	mv	s4,a1
    80003eb6:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80003eb8:	4601                	li	a2,0
    80003eba:	00000097          	auipc	ra,0x0
    80003ebe:	dda080e7          	jalr	-550(ra) # 80003c94 <dirlookup>
    80003ec2:	ed25                	bnez	a0,80003f3a <dirlink+0x96>
    80003ec4:	f426                	sd	s1,40(sp)
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003ec6:	04c92483          	lw	s1,76(s2)
    80003eca:	c49d                	beqz	s1,80003ef8 <dirlink+0x54>
    80003ecc:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003ece:	4741                	li	a4,16
    80003ed0:	86a6                	mv	a3,s1
    80003ed2:	fc040613          	addi	a2,s0,-64
    80003ed6:	4581                	li	a1,0
    80003ed8:	854a                	mv	a0,s2
    80003eda:	00000097          	auipc	ra,0x0
    80003ede:	b66080e7          	jalr	-1178(ra) # 80003a40 <readi>
    80003ee2:	47c1                	li	a5,16
    80003ee4:	06f51163          	bne	a0,a5,80003f46 <dirlink+0xa2>
    if(de.inum == 0)
    80003ee8:	fc045783          	lhu	a5,-64(s0)
    80003eec:	c791                	beqz	a5,80003ef8 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003eee:	24c1                	addiw	s1,s1,16
    80003ef0:	04c92783          	lw	a5,76(s2)
    80003ef4:	fcf4ede3          	bltu	s1,a5,80003ece <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80003ef8:	4639                	li	a2,14
    80003efa:	85d2                	mv	a1,s4
    80003efc:	fc240513          	addi	a0,s0,-62
    80003f00:	ffffd097          	auipc	ra,0xffffd
    80003f04:	f82080e7          	jalr	-126(ra) # 80000e82 <strncpy>
  de.inum = inum;
    80003f08:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003f0c:	4741                	li	a4,16
    80003f0e:	86a6                	mv	a3,s1
    80003f10:	fc040613          	addi	a2,s0,-64
    80003f14:	4581                	li	a1,0
    80003f16:	854a                	mv	a0,s2
    80003f18:	00000097          	auipc	ra,0x0
    80003f1c:	c38080e7          	jalr	-968(ra) # 80003b50 <writei>
    80003f20:	1541                	addi	a0,a0,-16
    80003f22:	00a03533          	snez	a0,a0
    80003f26:	40a00533          	neg	a0,a0
    80003f2a:	74a2                	ld	s1,40(sp)
}
    80003f2c:	70e2                	ld	ra,56(sp)
    80003f2e:	7442                	ld	s0,48(sp)
    80003f30:	7902                	ld	s2,32(sp)
    80003f32:	69e2                	ld	s3,24(sp)
    80003f34:	6a42                	ld	s4,16(sp)
    80003f36:	6121                	addi	sp,sp,64
    80003f38:	8082                	ret
    iput(ip);
    80003f3a:	00000097          	auipc	ra,0x0
    80003f3e:	a0c080e7          	jalr	-1524(ra) # 80003946 <iput>
    return -1;
    80003f42:	557d                	li	a0,-1
    80003f44:	b7e5                	j	80003f2c <dirlink+0x88>
      panic("dirlink read");
    80003f46:	00004517          	auipc	a0,0x4
    80003f4a:	5da50513          	addi	a0,a0,1498 # 80008520 <etext+0x520>
    80003f4e:	ffffc097          	auipc	ra,0xffffc
    80003f52:	612080e7          	jalr	1554(ra) # 80000560 <panic>

0000000080003f56 <namei>:

struct inode*
namei(char *path)
{
    80003f56:	1101                	addi	sp,sp,-32
    80003f58:	ec06                	sd	ra,24(sp)
    80003f5a:	e822                	sd	s0,16(sp)
    80003f5c:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80003f5e:	fe040613          	addi	a2,s0,-32
    80003f62:	4581                	li	a1,0
    80003f64:	00000097          	auipc	ra,0x0
    80003f68:	de0080e7          	jalr	-544(ra) # 80003d44 <namex>
}
    80003f6c:	60e2                	ld	ra,24(sp)
    80003f6e:	6442                	ld	s0,16(sp)
    80003f70:	6105                	addi	sp,sp,32
    80003f72:	8082                	ret

0000000080003f74 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80003f74:	1141                	addi	sp,sp,-16
    80003f76:	e406                	sd	ra,8(sp)
    80003f78:	e022                	sd	s0,0(sp)
    80003f7a:	0800                	addi	s0,sp,16
    80003f7c:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80003f7e:	4585                	li	a1,1
    80003f80:	00000097          	auipc	ra,0x0
    80003f84:	dc4080e7          	jalr	-572(ra) # 80003d44 <namex>
}
    80003f88:	60a2                	ld	ra,8(sp)
    80003f8a:	6402                	ld	s0,0(sp)
    80003f8c:	0141                	addi	sp,sp,16
    80003f8e:	8082                	ret

0000000080003f90 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80003f90:	1101                	addi	sp,sp,-32
    80003f92:	ec06                	sd	ra,24(sp)
    80003f94:	e822                	sd	s0,16(sp)
    80003f96:	e426                	sd	s1,8(sp)
    80003f98:	e04a                	sd	s2,0(sp)
    80003f9a:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80003f9c:	0001f917          	auipc	s2,0x1f
    80003fa0:	4e490913          	addi	s2,s2,1252 # 80023480 <log>
    80003fa4:	01892583          	lw	a1,24(s2)
    80003fa8:	02892503          	lw	a0,40(s2)
    80003fac:	fffff097          	auipc	ra,0xfffff
    80003fb0:	fa8080e7          	jalr	-88(ra) # 80002f54 <bread>
    80003fb4:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80003fb6:	02c92603          	lw	a2,44(s2)
    80003fba:	cd30                	sw	a2,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80003fbc:	00c05f63          	blez	a2,80003fda <write_head+0x4a>
    80003fc0:	0001f717          	auipc	a4,0x1f
    80003fc4:	4f070713          	addi	a4,a4,1264 # 800234b0 <log+0x30>
    80003fc8:	87aa                	mv	a5,a0
    80003fca:	060a                	slli	a2,a2,0x2
    80003fcc:	962a                	add	a2,a2,a0
    hb->block[i] = log.lh.block[i];
    80003fce:	4314                	lw	a3,0(a4)
    80003fd0:	cff4                	sw	a3,92(a5)
  for (i = 0; i < log.lh.n; i++) {
    80003fd2:	0711                	addi	a4,a4,4
    80003fd4:	0791                	addi	a5,a5,4
    80003fd6:	fec79ce3          	bne	a5,a2,80003fce <write_head+0x3e>
  }
  bwrite(buf);
    80003fda:	8526                	mv	a0,s1
    80003fdc:	fffff097          	auipc	ra,0xfffff
    80003fe0:	06a080e7          	jalr	106(ra) # 80003046 <bwrite>
  brelse(buf);
    80003fe4:	8526                	mv	a0,s1
    80003fe6:	fffff097          	auipc	ra,0xfffff
    80003fea:	09e080e7          	jalr	158(ra) # 80003084 <brelse>
}
    80003fee:	60e2                	ld	ra,24(sp)
    80003ff0:	6442                	ld	s0,16(sp)
    80003ff2:	64a2                	ld	s1,8(sp)
    80003ff4:	6902                	ld	s2,0(sp)
    80003ff6:	6105                	addi	sp,sp,32
    80003ff8:	8082                	ret

0000000080003ffa <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80003ffa:	0001f797          	auipc	a5,0x1f
    80003ffe:	4b27a783          	lw	a5,1202(a5) # 800234ac <log+0x2c>
    80004002:	0af05d63          	blez	a5,800040bc <install_trans+0xc2>
{
    80004006:	7139                	addi	sp,sp,-64
    80004008:	fc06                	sd	ra,56(sp)
    8000400a:	f822                	sd	s0,48(sp)
    8000400c:	f426                	sd	s1,40(sp)
    8000400e:	f04a                	sd	s2,32(sp)
    80004010:	ec4e                	sd	s3,24(sp)
    80004012:	e852                	sd	s4,16(sp)
    80004014:	e456                	sd	s5,8(sp)
    80004016:	e05a                	sd	s6,0(sp)
    80004018:	0080                	addi	s0,sp,64
    8000401a:	8b2a                	mv	s6,a0
    8000401c:	0001fa97          	auipc	s5,0x1f
    80004020:	494a8a93          	addi	s5,s5,1172 # 800234b0 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004024:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004026:	0001f997          	auipc	s3,0x1f
    8000402a:	45a98993          	addi	s3,s3,1114 # 80023480 <log>
    8000402e:	a00d                	j	80004050 <install_trans+0x56>
    brelse(lbuf);
    80004030:	854a                	mv	a0,s2
    80004032:	fffff097          	auipc	ra,0xfffff
    80004036:	052080e7          	jalr	82(ra) # 80003084 <brelse>
    brelse(dbuf);
    8000403a:	8526                	mv	a0,s1
    8000403c:	fffff097          	auipc	ra,0xfffff
    80004040:	048080e7          	jalr	72(ra) # 80003084 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004044:	2a05                	addiw	s4,s4,1
    80004046:	0a91                	addi	s5,s5,4
    80004048:	02c9a783          	lw	a5,44(s3)
    8000404c:	04fa5e63          	bge	s4,a5,800040a8 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004050:	0189a583          	lw	a1,24(s3)
    80004054:	014585bb          	addw	a1,a1,s4
    80004058:	2585                	addiw	a1,a1,1
    8000405a:	0289a503          	lw	a0,40(s3)
    8000405e:	fffff097          	auipc	ra,0xfffff
    80004062:	ef6080e7          	jalr	-266(ra) # 80002f54 <bread>
    80004066:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80004068:	000aa583          	lw	a1,0(s5)
    8000406c:	0289a503          	lw	a0,40(s3)
    80004070:	fffff097          	auipc	ra,0xfffff
    80004074:	ee4080e7          	jalr	-284(ra) # 80002f54 <bread>
    80004078:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    8000407a:	40000613          	li	a2,1024
    8000407e:	05890593          	addi	a1,s2,88
    80004082:	05850513          	addi	a0,a0,88
    80004086:	ffffd097          	auipc	ra,0xffffd
    8000408a:	d52080e7          	jalr	-686(ra) # 80000dd8 <memmove>
    bwrite(dbuf);  // write dst to disk
    8000408e:	8526                	mv	a0,s1
    80004090:	fffff097          	auipc	ra,0xfffff
    80004094:	fb6080e7          	jalr	-74(ra) # 80003046 <bwrite>
    if(recovering == 0)
    80004098:	f80b1ce3          	bnez	s6,80004030 <install_trans+0x36>
      bunpin(dbuf);
    8000409c:	8526                	mv	a0,s1
    8000409e:	fffff097          	auipc	ra,0xfffff
    800040a2:	0be080e7          	jalr	190(ra) # 8000315c <bunpin>
    800040a6:	b769                	j	80004030 <install_trans+0x36>
}
    800040a8:	70e2                	ld	ra,56(sp)
    800040aa:	7442                	ld	s0,48(sp)
    800040ac:	74a2                	ld	s1,40(sp)
    800040ae:	7902                	ld	s2,32(sp)
    800040b0:	69e2                	ld	s3,24(sp)
    800040b2:	6a42                	ld	s4,16(sp)
    800040b4:	6aa2                	ld	s5,8(sp)
    800040b6:	6b02                	ld	s6,0(sp)
    800040b8:	6121                	addi	sp,sp,64
    800040ba:	8082                	ret
    800040bc:	8082                	ret

00000000800040be <initlog>:
{
    800040be:	7179                	addi	sp,sp,-48
    800040c0:	f406                	sd	ra,40(sp)
    800040c2:	f022                	sd	s0,32(sp)
    800040c4:	ec26                	sd	s1,24(sp)
    800040c6:	e84a                	sd	s2,16(sp)
    800040c8:	e44e                	sd	s3,8(sp)
    800040ca:	1800                	addi	s0,sp,48
    800040cc:	892a                	mv	s2,a0
    800040ce:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    800040d0:	0001f497          	auipc	s1,0x1f
    800040d4:	3b048493          	addi	s1,s1,944 # 80023480 <log>
    800040d8:	00004597          	auipc	a1,0x4
    800040dc:	45858593          	addi	a1,a1,1112 # 80008530 <etext+0x530>
    800040e0:	8526                	mv	a0,s1
    800040e2:	ffffd097          	auipc	ra,0xffffd
    800040e6:	b0e080e7          	jalr	-1266(ra) # 80000bf0 <initlock>
  log.start = sb->logstart;
    800040ea:	0149a583          	lw	a1,20(s3)
    800040ee:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    800040f0:	0109a783          	lw	a5,16(s3)
    800040f4:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    800040f6:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    800040fa:	854a                	mv	a0,s2
    800040fc:	fffff097          	auipc	ra,0xfffff
    80004100:	e58080e7          	jalr	-424(ra) # 80002f54 <bread>
  log.lh.n = lh->n;
    80004104:	4d30                	lw	a2,88(a0)
    80004106:	d4d0                	sw	a2,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80004108:	00c05f63          	blez	a2,80004126 <initlog+0x68>
    8000410c:	87aa                	mv	a5,a0
    8000410e:	0001f717          	auipc	a4,0x1f
    80004112:	3a270713          	addi	a4,a4,930 # 800234b0 <log+0x30>
    80004116:	060a                	slli	a2,a2,0x2
    80004118:	962a                	add	a2,a2,a0
    log.lh.block[i] = lh->block[i];
    8000411a:	4ff4                	lw	a3,92(a5)
    8000411c:	c314                	sw	a3,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    8000411e:	0791                	addi	a5,a5,4
    80004120:	0711                	addi	a4,a4,4
    80004122:	fec79ce3          	bne	a5,a2,8000411a <initlog+0x5c>
  brelse(buf);
    80004126:	fffff097          	auipc	ra,0xfffff
    8000412a:	f5e080e7          	jalr	-162(ra) # 80003084 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    8000412e:	4505                	li	a0,1
    80004130:	00000097          	auipc	ra,0x0
    80004134:	eca080e7          	jalr	-310(ra) # 80003ffa <install_trans>
  log.lh.n = 0;
    80004138:	0001f797          	auipc	a5,0x1f
    8000413c:	3607aa23          	sw	zero,884(a5) # 800234ac <log+0x2c>
  write_head(); // clear the log
    80004140:	00000097          	auipc	ra,0x0
    80004144:	e50080e7          	jalr	-432(ra) # 80003f90 <write_head>
}
    80004148:	70a2                	ld	ra,40(sp)
    8000414a:	7402                	ld	s0,32(sp)
    8000414c:	64e2                	ld	s1,24(sp)
    8000414e:	6942                	ld	s2,16(sp)
    80004150:	69a2                	ld	s3,8(sp)
    80004152:	6145                	addi	sp,sp,48
    80004154:	8082                	ret

0000000080004156 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80004156:	1101                	addi	sp,sp,-32
    80004158:	ec06                	sd	ra,24(sp)
    8000415a:	e822                	sd	s0,16(sp)
    8000415c:	e426                	sd	s1,8(sp)
    8000415e:	e04a                	sd	s2,0(sp)
    80004160:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80004162:	0001f517          	auipc	a0,0x1f
    80004166:	31e50513          	addi	a0,a0,798 # 80023480 <log>
    8000416a:	ffffd097          	auipc	ra,0xffffd
    8000416e:	b16080e7          	jalr	-1258(ra) # 80000c80 <acquire>
  while(1){
    if(log.committing){
    80004172:	0001f497          	auipc	s1,0x1f
    80004176:	30e48493          	addi	s1,s1,782 # 80023480 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    8000417a:	4979                	li	s2,30
    8000417c:	a039                	j	8000418a <begin_op+0x34>
      sleep(&log, &log.lock);
    8000417e:	85a6                	mv	a1,s1
    80004180:	8526                	mv	a0,s1
    80004182:	ffffe097          	auipc	ra,0xffffe
    80004186:	fd4080e7          	jalr	-44(ra) # 80002156 <sleep>
    if(log.committing){
    8000418a:	50dc                	lw	a5,36(s1)
    8000418c:	fbed                	bnez	a5,8000417e <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    8000418e:	5098                	lw	a4,32(s1)
    80004190:	2705                	addiw	a4,a4,1
    80004192:	0027179b          	slliw	a5,a4,0x2
    80004196:	9fb9                	addw	a5,a5,a4
    80004198:	0017979b          	slliw	a5,a5,0x1
    8000419c:	54d4                	lw	a3,44(s1)
    8000419e:	9fb5                	addw	a5,a5,a3
    800041a0:	00f95963          	bge	s2,a5,800041b2 <begin_op+0x5c>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    800041a4:	85a6                	mv	a1,s1
    800041a6:	8526                	mv	a0,s1
    800041a8:	ffffe097          	auipc	ra,0xffffe
    800041ac:	fae080e7          	jalr	-82(ra) # 80002156 <sleep>
    800041b0:	bfe9                	j	8000418a <begin_op+0x34>
    } else {
      log.outstanding += 1;
    800041b2:	0001f517          	auipc	a0,0x1f
    800041b6:	2ce50513          	addi	a0,a0,718 # 80023480 <log>
    800041ba:	d118                	sw	a4,32(a0)
      release(&log.lock);
    800041bc:	ffffd097          	auipc	ra,0xffffd
    800041c0:	b78080e7          	jalr	-1160(ra) # 80000d34 <release>
      break;
    }
  }
}
    800041c4:	60e2                	ld	ra,24(sp)
    800041c6:	6442                	ld	s0,16(sp)
    800041c8:	64a2                	ld	s1,8(sp)
    800041ca:	6902                	ld	s2,0(sp)
    800041cc:	6105                	addi	sp,sp,32
    800041ce:	8082                	ret

00000000800041d0 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    800041d0:	7139                	addi	sp,sp,-64
    800041d2:	fc06                	sd	ra,56(sp)
    800041d4:	f822                	sd	s0,48(sp)
    800041d6:	f426                	sd	s1,40(sp)
    800041d8:	f04a                	sd	s2,32(sp)
    800041da:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    800041dc:	0001f497          	auipc	s1,0x1f
    800041e0:	2a448493          	addi	s1,s1,676 # 80023480 <log>
    800041e4:	8526                	mv	a0,s1
    800041e6:	ffffd097          	auipc	ra,0xffffd
    800041ea:	a9a080e7          	jalr	-1382(ra) # 80000c80 <acquire>
  log.outstanding -= 1;
    800041ee:	509c                	lw	a5,32(s1)
    800041f0:	37fd                	addiw	a5,a5,-1
    800041f2:	0007891b          	sext.w	s2,a5
    800041f6:	d09c                	sw	a5,32(s1)
  if(log.committing)
    800041f8:	50dc                	lw	a5,36(s1)
    800041fa:	e7b9                	bnez	a5,80004248 <end_op+0x78>
    panic("log.committing");
  if(log.outstanding == 0){
    800041fc:	06091163          	bnez	s2,8000425e <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    80004200:	0001f497          	auipc	s1,0x1f
    80004204:	28048493          	addi	s1,s1,640 # 80023480 <log>
    80004208:	4785                	li	a5,1
    8000420a:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    8000420c:	8526                	mv	a0,s1
    8000420e:	ffffd097          	auipc	ra,0xffffd
    80004212:	b26080e7          	jalr	-1242(ra) # 80000d34 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    80004216:	54dc                	lw	a5,44(s1)
    80004218:	06f04763          	bgtz	a5,80004286 <end_op+0xb6>
    acquire(&log.lock);
    8000421c:	0001f497          	auipc	s1,0x1f
    80004220:	26448493          	addi	s1,s1,612 # 80023480 <log>
    80004224:	8526                	mv	a0,s1
    80004226:	ffffd097          	auipc	ra,0xffffd
    8000422a:	a5a080e7          	jalr	-1446(ra) # 80000c80 <acquire>
    log.committing = 0;
    8000422e:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    80004232:	8526                	mv	a0,s1
    80004234:	ffffe097          	auipc	ra,0xffffe
    80004238:	f86080e7          	jalr	-122(ra) # 800021ba <wakeup>
    release(&log.lock);
    8000423c:	8526                	mv	a0,s1
    8000423e:	ffffd097          	auipc	ra,0xffffd
    80004242:	af6080e7          	jalr	-1290(ra) # 80000d34 <release>
}
    80004246:	a815                	j	8000427a <end_op+0xaa>
    80004248:	ec4e                	sd	s3,24(sp)
    8000424a:	e852                	sd	s4,16(sp)
    8000424c:	e456                	sd	s5,8(sp)
    panic("log.committing");
    8000424e:	00004517          	auipc	a0,0x4
    80004252:	2ea50513          	addi	a0,a0,746 # 80008538 <etext+0x538>
    80004256:	ffffc097          	auipc	ra,0xffffc
    8000425a:	30a080e7          	jalr	778(ra) # 80000560 <panic>
    wakeup(&log);
    8000425e:	0001f497          	auipc	s1,0x1f
    80004262:	22248493          	addi	s1,s1,546 # 80023480 <log>
    80004266:	8526                	mv	a0,s1
    80004268:	ffffe097          	auipc	ra,0xffffe
    8000426c:	f52080e7          	jalr	-174(ra) # 800021ba <wakeup>
  release(&log.lock);
    80004270:	8526                	mv	a0,s1
    80004272:	ffffd097          	auipc	ra,0xffffd
    80004276:	ac2080e7          	jalr	-1342(ra) # 80000d34 <release>
}
    8000427a:	70e2                	ld	ra,56(sp)
    8000427c:	7442                	ld	s0,48(sp)
    8000427e:	74a2                	ld	s1,40(sp)
    80004280:	7902                	ld	s2,32(sp)
    80004282:	6121                	addi	sp,sp,64
    80004284:	8082                	ret
    80004286:	ec4e                	sd	s3,24(sp)
    80004288:	e852                	sd	s4,16(sp)
    8000428a:	e456                	sd	s5,8(sp)
  for (tail = 0; tail < log.lh.n; tail++) {
    8000428c:	0001fa97          	auipc	s5,0x1f
    80004290:	224a8a93          	addi	s5,s5,548 # 800234b0 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80004294:	0001fa17          	auipc	s4,0x1f
    80004298:	1eca0a13          	addi	s4,s4,492 # 80023480 <log>
    8000429c:	018a2583          	lw	a1,24(s4)
    800042a0:	012585bb          	addw	a1,a1,s2
    800042a4:	2585                	addiw	a1,a1,1
    800042a6:	028a2503          	lw	a0,40(s4)
    800042aa:	fffff097          	auipc	ra,0xfffff
    800042ae:	caa080e7          	jalr	-854(ra) # 80002f54 <bread>
    800042b2:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    800042b4:	000aa583          	lw	a1,0(s5)
    800042b8:	028a2503          	lw	a0,40(s4)
    800042bc:	fffff097          	auipc	ra,0xfffff
    800042c0:	c98080e7          	jalr	-872(ra) # 80002f54 <bread>
    800042c4:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    800042c6:	40000613          	li	a2,1024
    800042ca:	05850593          	addi	a1,a0,88
    800042ce:	05848513          	addi	a0,s1,88
    800042d2:	ffffd097          	auipc	ra,0xffffd
    800042d6:	b06080e7          	jalr	-1274(ra) # 80000dd8 <memmove>
    bwrite(to);  // write the log
    800042da:	8526                	mv	a0,s1
    800042dc:	fffff097          	auipc	ra,0xfffff
    800042e0:	d6a080e7          	jalr	-662(ra) # 80003046 <bwrite>
    brelse(from);
    800042e4:	854e                	mv	a0,s3
    800042e6:	fffff097          	auipc	ra,0xfffff
    800042ea:	d9e080e7          	jalr	-610(ra) # 80003084 <brelse>
    brelse(to);
    800042ee:	8526                	mv	a0,s1
    800042f0:	fffff097          	auipc	ra,0xfffff
    800042f4:	d94080e7          	jalr	-620(ra) # 80003084 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800042f8:	2905                	addiw	s2,s2,1
    800042fa:	0a91                	addi	s5,s5,4
    800042fc:	02ca2783          	lw	a5,44(s4)
    80004300:	f8f94ee3          	blt	s2,a5,8000429c <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004304:	00000097          	auipc	ra,0x0
    80004308:	c8c080e7          	jalr	-884(ra) # 80003f90 <write_head>
    install_trans(0); // Now install writes to home locations
    8000430c:	4501                	li	a0,0
    8000430e:	00000097          	auipc	ra,0x0
    80004312:	cec080e7          	jalr	-788(ra) # 80003ffa <install_trans>
    log.lh.n = 0;
    80004316:	0001f797          	auipc	a5,0x1f
    8000431a:	1807ab23          	sw	zero,406(a5) # 800234ac <log+0x2c>
    write_head();    // Erase the transaction from the log
    8000431e:	00000097          	auipc	ra,0x0
    80004322:	c72080e7          	jalr	-910(ra) # 80003f90 <write_head>
    80004326:	69e2                	ld	s3,24(sp)
    80004328:	6a42                	ld	s4,16(sp)
    8000432a:	6aa2                	ld	s5,8(sp)
    8000432c:	bdc5                	j	8000421c <end_op+0x4c>

000000008000432e <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    8000432e:	1101                	addi	sp,sp,-32
    80004330:	ec06                	sd	ra,24(sp)
    80004332:	e822                	sd	s0,16(sp)
    80004334:	e426                	sd	s1,8(sp)
    80004336:	e04a                	sd	s2,0(sp)
    80004338:	1000                	addi	s0,sp,32
    8000433a:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    8000433c:	0001f917          	auipc	s2,0x1f
    80004340:	14490913          	addi	s2,s2,324 # 80023480 <log>
    80004344:	854a                	mv	a0,s2
    80004346:	ffffd097          	auipc	ra,0xffffd
    8000434a:	93a080e7          	jalr	-1734(ra) # 80000c80 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    8000434e:	02c92603          	lw	a2,44(s2)
    80004352:	47f5                	li	a5,29
    80004354:	06c7c563          	blt	a5,a2,800043be <log_write+0x90>
    80004358:	0001f797          	auipc	a5,0x1f
    8000435c:	1447a783          	lw	a5,324(a5) # 8002349c <log+0x1c>
    80004360:	37fd                	addiw	a5,a5,-1
    80004362:	04f65e63          	bge	a2,a5,800043be <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80004366:	0001f797          	auipc	a5,0x1f
    8000436a:	13a7a783          	lw	a5,314(a5) # 800234a0 <log+0x20>
    8000436e:	06f05063          	blez	a5,800043ce <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    80004372:	4781                	li	a5,0
    80004374:	06c05563          	blez	a2,800043de <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004378:	44cc                	lw	a1,12(s1)
    8000437a:	0001f717          	auipc	a4,0x1f
    8000437e:	13670713          	addi	a4,a4,310 # 800234b0 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80004382:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004384:	4314                	lw	a3,0(a4)
    80004386:	04b68c63          	beq	a3,a1,800043de <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    8000438a:	2785                	addiw	a5,a5,1
    8000438c:	0711                	addi	a4,a4,4
    8000438e:	fef61be3          	bne	a2,a5,80004384 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004392:	0621                	addi	a2,a2,8
    80004394:	060a                	slli	a2,a2,0x2
    80004396:	0001f797          	auipc	a5,0x1f
    8000439a:	0ea78793          	addi	a5,a5,234 # 80023480 <log>
    8000439e:	97b2                	add	a5,a5,a2
    800043a0:	44d8                	lw	a4,12(s1)
    800043a2:	cb98                	sw	a4,16(a5)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    800043a4:	8526                	mv	a0,s1
    800043a6:	fffff097          	auipc	ra,0xfffff
    800043aa:	d7a080e7          	jalr	-646(ra) # 80003120 <bpin>
    log.lh.n++;
    800043ae:	0001f717          	auipc	a4,0x1f
    800043b2:	0d270713          	addi	a4,a4,210 # 80023480 <log>
    800043b6:	575c                	lw	a5,44(a4)
    800043b8:	2785                	addiw	a5,a5,1
    800043ba:	d75c                	sw	a5,44(a4)
    800043bc:	a82d                	j	800043f6 <log_write+0xc8>
    panic("too big a transaction");
    800043be:	00004517          	auipc	a0,0x4
    800043c2:	18a50513          	addi	a0,a0,394 # 80008548 <etext+0x548>
    800043c6:	ffffc097          	auipc	ra,0xffffc
    800043ca:	19a080e7          	jalr	410(ra) # 80000560 <panic>
    panic("log_write outside of trans");
    800043ce:	00004517          	auipc	a0,0x4
    800043d2:	19250513          	addi	a0,a0,402 # 80008560 <etext+0x560>
    800043d6:	ffffc097          	auipc	ra,0xffffc
    800043da:	18a080e7          	jalr	394(ra) # 80000560 <panic>
  log.lh.block[i] = b->blockno;
    800043de:	00878693          	addi	a3,a5,8
    800043e2:	068a                	slli	a3,a3,0x2
    800043e4:	0001f717          	auipc	a4,0x1f
    800043e8:	09c70713          	addi	a4,a4,156 # 80023480 <log>
    800043ec:	9736                	add	a4,a4,a3
    800043ee:	44d4                	lw	a3,12(s1)
    800043f0:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    800043f2:	faf609e3          	beq	a2,a5,800043a4 <log_write+0x76>
  }
  release(&log.lock);
    800043f6:	0001f517          	auipc	a0,0x1f
    800043fa:	08a50513          	addi	a0,a0,138 # 80023480 <log>
    800043fe:	ffffd097          	auipc	ra,0xffffd
    80004402:	936080e7          	jalr	-1738(ra) # 80000d34 <release>
}
    80004406:	60e2                	ld	ra,24(sp)
    80004408:	6442                	ld	s0,16(sp)
    8000440a:	64a2                	ld	s1,8(sp)
    8000440c:	6902                	ld	s2,0(sp)
    8000440e:	6105                	addi	sp,sp,32
    80004410:	8082                	ret

0000000080004412 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004412:	1101                	addi	sp,sp,-32
    80004414:	ec06                	sd	ra,24(sp)
    80004416:	e822                	sd	s0,16(sp)
    80004418:	e426                	sd	s1,8(sp)
    8000441a:	e04a                	sd	s2,0(sp)
    8000441c:	1000                	addi	s0,sp,32
    8000441e:	84aa                	mv	s1,a0
    80004420:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004422:	00004597          	auipc	a1,0x4
    80004426:	15e58593          	addi	a1,a1,350 # 80008580 <etext+0x580>
    8000442a:	0521                	addi	a0,a0,8
    8000442c:	ffffc097          	auipc	ra,0xffffc
    80004430:	7c4080e7          	jalr	1988(ra) # 80000bf0 <initlock>
  lk->name = name;
    80004434:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80004438:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    8000443c:	0204a423          	sw	zero,40(s1)
}
    80004440:	60e2                	ld	ra,24(sp)
    80004442:	6442                	ld	s0,16(sp)
    80004444:	64a2                	ld	s1,8(sp)
    80004446:	6902                	ld	s2,0(sp)
    80004448:	6105                	addi	sp,sp,32
    8000444a:	8082                	ret

000000008000444c <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    8000444c:	1101                	addi	sp,sp,-32
    8000444e:	ec06                	sd	ra,24(sp)
    80004450:	e822                	sd	s0,16(sp)
    80004452:	e426                	sd	s1,8(sp)
    80004454:	e04a                	sd	s2,0(sp)
    80004456:	1000                	addi	s0,sp,32
    80004458:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    8000445a:	00850913          	addi	s2,a0,8
    8000445e:	854a                	mv	a0,s2
    80004460:	ffffd097          	auipc	ra,0xffffd
    80004464:	820080e7          	jalr	-2016(ra) # 80000c80 <acquire>
  while (lk->locked) {
    80004468:	409c                	lw	a5,0(s1)
    8000446a:	cb89                	beqz	a5,8000447c <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    8000446c:	85ca                	mv	a1,s2
    8000446e:	8526                	mv	a0,s1
    80004470:	ffffe097          	auipc	ra,0xffffe
    80004474:	ce6080e7          	jalr	-794(ra) # 80002156 <sleep>
  while (lk->locked) {
    80004478:	409c                	lw	a5,0(s1)
    8000447a:	fbed                	bnez	a5,8000446c <acquiresleep+0x20>
  }
  lk->locked = 1;
    8000447c:	4785                	li	a5,1
    8000447e:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004480:	ffffd097          	auipc	ra,0xffffd
    80004484:	62c080e7          	jalr	1580(ra) # 80001aac <myproc>
    80004488:	591c                	lw	a5,48(a0)
    8000448a:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    8000448c:	854a                	mv	a0,s2
    8000448e:	ffffd097          	auipc	ra,0xffffd
    80004492:	8a6080e7          	jalr	-1882(ra) # 80000d34 <release>
}
    80004496:	60e2                	ld	ra,24(sp)
    80004498:	6442                	ld	s0,16(sp)
    8000449a:	64a2                	ld	s1,8(sp)
    8000449c:	6902                	ld	s2,0(sp)
    8000449e:	6105                	addi	sp,sp,32
    800044a0:	8082                	ret

00000000800044a2 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    800044a2:	1101                	addi	sp,sp,-32
    800044a4:	ec06                	sd	ra,24(sp)
    800044a6:	e822                	sd	s0,16(sp)
    800044a8:	e426                	sd	s1,8(sp)
    800044aa:	e04a                	sd	s2,0(sp)
    800044ac:	1000                	addi	s0,sp,32
    800044ae:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800044b0:	00850913          	addi	s2,a0,8
    800044b4:	854a                	mv	a0,s2
    800044b6:	ffffc097          	auipc	ra,0xffffc
    800044ba:	7ca080e7          	jalr	1994(ra) # 80000c80 <acquire>
  lk->locked = 0;
    800044be:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800044c2:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    800044c6:	8526                	mv	a0,s1
    800044c8:	ffffe097          	auipc	ra,0xffffe
    800044cc:	cf2080e7          	jalr	-782(ra) # 800021ba <wakeup>
  release(&lk->lk);
    800044d0:	854a                	mv	a0,s2
    800044d2:	ffffd097          	auipc	ra,0xffffd
    800044d6:	862080e7          	jalr	-1950(ra) # 80000d34 <release>
}
    800044da:	60e2                	ld	ra,24(sp)
    800044dc:	6442                	ld	s0,16(sp)
    800044de:	64a2                	ld	s1,8(sp)
    800044e0:	6902                	ld	s2,0(sp)
    800044e2:	6105                	addi	sp,sp,32
    800044e4:	8082                	ret

00000000800044e6 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    800044e6:	7179                	addi	sp,sp,-48
    800044e8:	f406                	sd	ra,40(sp)
    800044ea:	f022                	sd	s0,32(sp)
    800044ec:	ec26                	sd	s1,24(sp)
    800044ee:	e84a                	sd	s2,16(sp)
    800044f0:	1800                	addi	s0,sp,48
    800044f2:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    800044f4:	00850913          	addi	s2,a0,8
    800044f8:	854a                	mv	a0,s2
    800044fa:	ffffc097          	auipc	ra,0xffffc
    800044fe:	786080e7          	jalr	1926(ra) # 80000c80 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004502:	409c                	lw	a5,0(s1)
    80004504:	ef91                	bnez	a5,80004520 <holdingsleep+0x3a>
    80004506:	4481                	li	s1,0
  release(&lk->lk);
    80004508:	854a                	mv	a0,s2
    8000450a:	ffffd097          	auipc	ra,0xffffd
    8000450e:	82a080e7          	jalr	-2006(ra) # 80000d34 <release>
  return r;
}
    80004512:	8526                	mv	a0,s1
    80004514:	70a2                	ld	ra,40(sp)
    80004516:	7402                	ld	s0,32(sp)
    80004518:	64e2                	ld	s1,24(sp)
    8000451a:	6942                	ld	s2,16(sp)
    8000451c:	6145                	addi	sp,sp,48
    8000451e:	8082                	ret
    80004520:	e44e                	sd	s3,8(sp)
  r = lk->locked && (lk->pid == myproc()->pid);
    80004522:	0284a983          	lw	s3,40(s1)
    80004526:	ffffd097          	auipc	ra,0xffffd
    8000452a:	586080e7          	jalr	1414(ra) # 80001aac <myproc>
    8000452e:	5904                	lw	s1,48(a0)
    80004530:	413484b3          	sub	s1,s1,s3
    80004534:	0014b493          	seqz	s1,s1
    80004538:	69a2                	ld	s3,8(sp)
    8000453a:	b7f9                	j	80004508 <holdingsleep+0x22>

000000008000453c <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    8000453c:	1141                	addi	sp,sp,-16
    8000453e:	e406                	sd	ra,8(sp)
    80004540:	e022                	sd	s0,0(sp)
    80004542:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004544:	00004597          	auipc	a1,0x4
    80004548:	04c58593          	addi	a1,a1,76 # 80008590 <etext+0x590>
    8000454c:	0001f517          	auipc	a0,0x1f
    80004550:	07c50513          	addi	a0,a0,124 # 800235c8 <ftable>
    80004554:	ffffc097          	auipc	ra,0xffffc
    80004558:	69c080e7          	jalr	1692(ra) # 80000bf0 <initlock>
}
    8000455c:	60a2                	ld	ra,8(sp)
    8000455e:	6402                	ld	s0,0(sp)
    80004560:	0141                	addi	sp,sp,16
    80004562:	8082                	ret

0000000080004564 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004564:	1101                	addi	sp,sp,-32
    80004566:	ec06                	sd	ra,24(sp)
    80004568:	e822                	sd	s0,16(sp)
    8000456a:	e426                	sd	s1,8(sp)
    8000456c:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    8000456e:	0001f517          	auipc	a0,0x1f
    80004572:	05a50513          	addi	a0,a0,90 # 800235c8 <ftable>
    80004576:	ffffc097          	auipc	ra,0xffffc
    8000457a:	70a080e7          	jalr	1802(ra) # 80000c80 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    8000457e:	0001f497          	auipc	s1,0x1f
    80004582:	06248493          	addi	s1,s1,98 # 800235e0 <ftable+0x18>
    80004586:	00020717          	auipc	a4,0x20
    8000458a:	ffa70713          	addi	a4,a4,-6 # 80024580 <disk>
    if(f->ref == 0){
    8000458e:	40dc                	lw	a5,4(s1)
    80004590:	cf99                	beqz	a5,800045ae <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004592:	02848493          	addi	s1,s1,40
    80004596:	fee49ce3          	bne	s1,a4,8000458e <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    8000459a:	0001f517          	auipc	a0,0x1f
    8000459e:	02e50513          	addi	a0,a0,46 # 800235c8 <ftable>
    800045a2:	ffffc097          	auipc	ra,0xffffc
    800045a6:	792080e7          	jalr	1938(ra) # 80000d34 <release>
  return 0;
    800045aa:	4481                	li	s1,0
    800045ac:	a819                	j	800045c2 <filealloc+0x5e>
      f->ref = 1;
    800045ae:	4785                	li	a5,1
    800045b0:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    800045b2:	0001f517          	auipc	a0,0x1f
    800045b6:	01650513          	addi	a0,a0,22 # 800235c8 <ftable>
    800045ba:	ffffc097          	auipc	ra,0xffffc
    800045be:	77a080e7          	jalr	1914(ra) # 80000d34 <release>
}
    800045c2:	8526                	mv	a0,s1
    800045c4:	60e2                	ld	ra,24(sp)
    800045c6:	6442                	ld	s0,16(sp)
    800045c8:	64a2                	ld	s1,8(sp)
    800045ca:	6105                	addi	sp,sp,32
    800045cc:	8082                	ret

00000000800045ce <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    800045ce:	1101                	addi	sp,sp,-32
    800045d0:	ec06                	sd	ra,24(sp)
    800045d2:	e822                	sd	s0,16(sp)
    800045d4:	e426                	sd	s1,8(sp)
    800045d6:	1000                	addi	s0,sp,32
    800045d8:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    800045da:	0001f517          	auipc	a0,0x1f
    800045de:	fee50513          	addi	a0,a0,-18 # 800235c8 <ftable>
    800045e2:	ffffc097          	auipc	ra,0xffffc
    800045e6:	69e080e7          	jalr	1694(ra) # 80000c80 <acquire>
  if(f->ref < 1)
    800045ea:	40dc                	lw	a5,4(s1)
    800045ec:	02f05263          	blez	a5,80004610 <filedup+0x42>
    panic("filedup");
  f->ref++;
    800045f0:	2785                	addiw	a5,a5,1
    800045f2:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    800045f4:	0001f517          	auipc	a0,0x1f
    800045f8:	fd450513          	addi	a0,a0,-44 # 800235c8 <ftable>
    800045fc:	ffffc097          	auipc	ra,0xffffc
    80004600:	738080e7          	jalr	1848(ra) # 80000d34 <release>
  return f;
}
    80004604:	8526                	mv	a0,s1
    80004606:	60e2                	ld	ra,24(sp)
    80004608:	6442                	ld	s0,16(sp)
    8000460a:	64a2                	ld	s1,8(sp)
    8000460c:	6105                	addi	sp,sp,32
    8000460e:	8082                	ret
    panic("filedup");
    80004610:	00004517          	auipc	a0,0x4
    80004614:	f8850513          	addi	a0,a0,-120 # 80008598 <etext+0x598>
    80004618:	ffffc097          	auipc	ra,0xffffc
    8000461c:	f48080e7          	jalr	-184(ra) # 80000560 <panic>

0000000080004620 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004620:	7139                	addi	sp,sp,-64
    80004622:	fc06                	sd	ra,56(sp)
    80004624:	f822                	sd	s0,48(sp)
    80004626:	f426                	sd	s1,40(sp)
    80004628:	0080                	addi	s0,sp,64
    8000462a:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    8000462c:	0001f517          	auipc	a0,0x1f
    80004630:	f9c50513          	addi	a0,a0,-100 # 800235c8 <ftable>
    80004634:	ffffc097          	auipc	ra,0xffffc
    80004638:	64c080e7          	jalr	1612(ra) # 80000c80 <acquire>
  if(f->ref < 1)
    8000463c:	40dc                	lw	a5,4(s1)
    8000463e:	04f05c63          	blez	a5,80004696 <fileclose+0x76>
    panic("fileclose");
  if(--f->ref > 0){
    80004642:	37fd                	addiw	a5,a5,-1
    80004644:	0007871b          	sext.w	a4,a5
    80004648:	c0dc                	sw	a5,4(s1)
    8000464a:	06e04263          	bgtz	a4,800046ae <fileclose+0x8e>
    8000464e:	f04a                	sd	s2,32(sp)
    80004650:	ec4e                	sd	s3,24(sp)
    80004652:	e852                	sd	s4,16(sp)
    80004654:	e456                	sd	s5,8(sp)
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004656:	0004a903          	lw	s2,0(s1)
    8000465a:	0094ca83          	lbu	s5,9(s1)
    8000465e:	0104ba03          	ld	s4,16(s1)
    80004662:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004666:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    8000466a:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    8000466e:	0001f517          	auipc	a0,0x1f
    80004672:	f5a50513          	addi	a0,a0,-166 # 800235c8 <ftable>
    80004676:	ffffc097          	auipc	ra,0xffffc
    8000467a:	6be080e7          	jalr	1726(ra) # 80000d34 <release>

  if(ff.type == FD_PIPE){
    8000467e:	4785                	li	a5,1
    80004680:	04f90463          	beq	s2,a5,800046c8 <fileclose+0xa8>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004684:	3979                	addiw	s2,s2,-2
    80004686:	4785                	li	a5,1
    80004688:	0527fb63          	bgeu	a5,s2,800046de <fileclose+0xbe>
    8000468c:	7902                	ld	s2,32(sp)
    8000468e:	69e2                	ld	s3,24(sp)
    80004690:	6a42                	ld	s4,16(sp)
    80004692:	6aa2                	ld	s5,8(sp)
    80004694:	a02d                	j	800046be <fileclose+0x9e>
    80004696:	f04a                	sd	s2,32(sp)
    80004698:	ec4e                	sd	s3,24(sp)
    8000469a:	e852                	sd	s4,16(sp)
    8000469c:	e456                	sd	s5,8(sp)
    panic("fileclose");
    8000469e:	00004517          	auipc	a0,0x4
    800046a2:	f0250513          	addi	a0,a0,-254 # 800085a0 <etext+0x5a0>
    800046a6:	ffffc097          	auipc	ra,0xffffc
    800046aa:	eba080e7          	jalr	-326(ra) # 80000560 <panic>
    release(&ftable.lock);
    800046ae:	0001f517          	auipc	a0,0x1f
    800046b2:	f1a50513          	addi	a0,a0,-230 # 800235c8 <ftable>
    800046b6:	ffffc097          	auipc	ra,0xffffc
    800046ba:	67e080e7          	jalr	1662(ra) # 80000d34 <release>
    begin_op();
    iput(ff.ip);
    end_op();
  }
}
    800046be:	70e2                	ld	ra,56(sp)
    800046c0:	7442                	ld	s0,48(sp)
    800046c2:	74a2                	ld	s1,40(sp)
    800046c4:	6121                	addi	sp,sp,64
    800046c6:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    800046c8:	85d6                	mv	a1,s5
    800046ca:	8552                	mv	a0,s4
    800046cc:	00000097          	auipc	ra,0x0
    800046d0:	3a2080e7          	jalr	930(ra) # 80004a6e <pipeclose>
    800046d4:	7902                	ld	s2,32(sp)
    800046d6:	69e2                	ld	s3,24(sp)
    800046d8:	6a42                	ld	s4,16(sp)
    800046da:	6aa2                	ld	s5,8(sp)
    800046dc:	b7cd                	j	800046be <fileclose+0x9e>
    begin_op();
    800046de:	00000097          	auipc	ra,0x0
    800046e2:	a78080e7          	jalr	-1416(ra) # 80004156 <begin_op>
    iput(ff.ip);
    800046e6:	854e                	mv	a0,s3
    800046e8:	fffff097          	auipc	ra,0xfffff
    800046ec:	25e080e7          	jalr	606(ra) # 80003946 <iput>
    end_op();
    800046f0:	00000097          	auipc	ra,0x0
    800046f4:	ae0080e7          	jalr	-1312(ra) # 800041d0 <end_op>
    800046f8:	7902                	ld	s2,32(sp)
    800046fa:	69e2                	ld	s3,24(sp)
    800046fc:	6a42                	ld	s4,16(sp)
    800046fe:	6aa2                	ld	s5,8(sp)
    80004700:	bf7d                	j	800046be <fileclose+0x9e>

0000000080004702 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004702:	715d                	addi	sp,sp,-80
    80004704:	e486                	sd	ra,72(sp)
    80004706:	e0a2                	sd	s0,64(sp)
    80004708:	fc26                	sd	s1,56(sp)
    8000470a:	f44e                	sd	s3,40(sp)
    8000470c:	0880                	addi	s0,sp,80
    8000470e:	84aa                	mv	s1,a0
    80004710:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004712:	ffffd097          	auipc	ra,0xffffd
    80004716:	39a080e7          	jalr	922(ra) # 80001aac <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    8000471a:	409c                	lw	a5,0(s1)
    8000471c:	37f9                	addiw	a5,a5,-2
    8000471e:	4705                	li	a4,1
    80004720:	04f76863          	bltu	a4,a5,80004770 <filestat+0x6e>
    80004724:	f84a                	sd	s2,48(sp)
    80004726:	892a                	mv	s2,a0
    ilock(f->ip);
    80004728:	6c88                	ld	a0,24(s1)
    8000472a:	fffff097          	auipc	ra,0xfffff
    8000472e:	05e080e7          	jalr	94(ra) # 80003788 <ilock>
    stati(f->ip, &st);
    80004732:	fb840593          	addi	a1,s0,-72
    80004736:	6c88                	ld	a0,24(s1)
    80004738:	fffff097          	auipc	ra,0xfffff
    8000473c:	2de080e7          	jalr	734(ra) # 80003a16 <stati>
    iunlock(f->ip);
    80004740:	6c88                	ld	a0,24(s1)
    80004742:	fffff097          	auipc	ra,0xfffff
    80004746:	10c080e7          	jalr	268(ra) # 8000384e <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    8000474a:	46e1                	li	a3,24
    8000474c:	fb840613          	addi	a2,s0,-72
    80004750:	85ce                	mv	a1,s3
    80004752:	05093503          	ld	a0,80(s2)
    80004756:	ffffd097          	auipc	ra,0xffffd
    8000475a:	fee080e7          	jalr	-18(ra) # 80001744 <copyout>
    8000475e:	41f5551b          	sraiw	a0,a0,0x1f
    80004762:	7942                	ld	s2,48(sp)
      return -1;
    return 0;
  }
  return -1;
}
    80004764:	60a6                	ld	ra,72(sp)
    80004766:	6406                	ld	s0,64(sp)
    80004768:	74e2                	ld	s1,56(sp)
    8000476a:	79a2                	ld	s3,40(sp)
    8000476c:	6161                	addi	sp,sp,80
    8000476e:	8082                	ret
  return -1;
    80004770:	557d                	li	a0,-1
    80004772:	bfcd                	j	80004764 <filestat+0x62>

0000000080004774 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004774:	7179                	addi	sp,sp,-48
    80004776:	f406                	sd	ra,40(sp)
    80004778:	f022                	sd	s0,32(sp)
    8000477a:	e84a                	sd	s2,16(sp)
    8000477c:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    8000477e:	00854783          	lbu	a5,8(a0)
    80004782:	cbc5                	beqz	a5,80004832 <fileread+0xbe>
    80004784:	ec26                	sd	s1,24(sp)
    80004786:	e44e                	sd	s3,8(sp)
    80004788:	84aa                	mv	s1,a0
    8000478a:	89ae                	mv	s3,a1
    8000478c:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    8000478e:	411c                	lw	a5,0(a0)
    80004790:	4705                	li	a4,1
    80004792:	04e78963          	beq	a5,a4,800047e4 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004796:	470d                	li	a4,3
    80004798:	04e78f63          	beq	a5,a4,800047f6 <fileread+0x82>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    8000479c:	4709                	li	a4,2
    8000479e:	08e79263          	bne	a5,a4,80004822 <fileread+0xae>
    ilock(f->ip);
    800047a2:	6d08                	ld	a0,24(a0)
    800047a4:	fffff097          	auipc	ra,0xfffff
    800047a8:	fe4080e7          	jalr	-28(ra) # 80003788 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    800047ac:	874a                	mv	a4,s2
    800047ae:	5094                	lw	a3,32(s1)
    800047b0:	864e                	mv	a2,s3
    800047b2:	4585                	li	a1,1
    800047b4:	6c88                	ld	a0,24(s1)
    800047b6:	fffff097          	auipc	ra,0xfffff
    800047ba:	28a080e7          	jalr	650(ra) # 80003a40 <readi>
    800047be:	892a                	mv	s2,a0
    800047c0:	00a05563          	blez	a0,800047ca <fileread+0x56>
      f->off += r;
    800047c4:	509c                	lw	a5,32(s1)
    800047c6:	9fa9                	addw	a5,a5,a0
    800047c8:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    800047ca:	6c88                	ld	a0,24(s1)
    800047cc:	fffff097          	auipc	ra,0xfffff
    800047d0:	082080e7          	jalr	130(ra) # 8000384e <iunlock>
    800047d4:	64e2                	ld	s1,24(sp)
    800047d6:	69a2                	ld	s3,8(sp)
  } else {
    panic("fileread");
  }

  return r;
}
    800047d8:	854a                	mv	a0,s2
    800047da:	70a2                	ld	ra,40(sp)
    800047dc:	7402                	ld	s0,32(sp)
    800047de:	6942                	ld	s2,16(sp)
    800047e0:	6145                	addi	sp,sp,48
    800047e2:	8082                	ret
    r = piperead(f->pipe, addr, n);
    800047e4:	6908                	ld	a0,16(a0)
    800047e6:	00000097          	auipc	ra,0x0
    800047ea:	400080e7          	jalr	1024(ra) # 80004be6 <piperead>
    800047ee:	892a                	mv	s2,a0
    800047f0:	64e2                	ld	s1,24(sp)
    800047f2:	69a2                	ld	s3,8(sp)
    800047f4:	b7d5                	j	800047d8 <fileread+0x64>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    800047f6:	02451783          	lh	a5,36(a0)
    800047fa:	03079693          	slli	a3,a5,0x30
    800047fe:	92c1                	srli	a3,a3,0x30
    80004800:	4725                	li	a4,9
    80004802:	02d76a63          	bltu	a4,a3,80004836 <fileread+0xc2>
    80004806:	0792                	slli	a5,a5,0x4
    80004808:	0001f717          	auipc	a4,0x1f
    8000480c:	d2070713          	addi	a4,a4,-736 # 80023528 <devsw>
    80004810:	97ba                	add	a5,a5,a4
    80004812:	639c                	ld	a5,0(a5)
    80004814:	c78d                	beqz	a5,8000483e <fileread+0xca>
    r = devsw[f->major].read(1, addr, n);
    80004816:	4505                	li	a0,1
    80004818:	9782                	jalr	a5
    8000481a:	892a                	mv	s2,a0
    8000481c:	64e2                	ld	s1,24(sp)
    8000481e:	69a2                	ld	s3,8(sp)
    80004820:	bf65                	j	800047d8 <fileread+0x64>
    panic("fileread");
    80004822:	00004517          	auipc	a0,0x4
    80004826:	d8e50513          	addi	a0,a0,-626 # 800085b0 <etext+0x5b0>
    8000482a:	ffffc097          	auipc	ra,0xffffc
    8000482e:	d36080e7          	jalr	-714(ra) # 80000560 <panic>
    return -1;
    80004832:	597d                	li	s2,-1
    80004834:	b755                	j	800047d8 <fileread+0x64>
      return -1;
    80004836:	597d                	li	s2,-1
    80004838:	64e2                	ld	s1,24(sp)
    8000483a:	69a2                	ld	s3,8(sp)
    8000483c:	bf71                	j	800047d8 <fileread+0x64>
    8000483e:	597d                	li	s2,-1
    80004840:	64e2                	ld	s1,24(sp)
    80004842:	69a2                	ld	s3,8(sp)
    80004844:	bf51                	j	800047d8 <fileread+0x64>

0000000080004846 <filewrite>:
int
filewrite(struct file *f, uint64 addr, int n)
{
  int r, ret = 0;

  if(f->writable == 0)
    80004846:	00954783          	lbu	a5,9(a0)
    8000484a:	12078963          	beqz	a5,8000497c <filewrite+0x136>
{
    8000484e:	715d                	addi	sp,sp,-80
    80004850:	e486                	sd	ra,72(sp)
    80004852:	e0a2                	sd	s0,64(sp)
    80004854:	f84a                	sd	s2,48(sp)
    80004856:	f052                	sd	s4,32(sp)
    80004858:	e85a                	sd	s6,16(sp)
    8000485a:	0880                	addi	s0,sp,80
    8000485c:	892a                	mv	s2,a0
    8000485e:	8b2e                	mv	s6,a1
    80004860:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004862:	411c                	lw	a5,0(a0)
    80004864:	4705                	li	a4,1
    80004866:	02e78763          	beq	a5,a4,80004894 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    8000486a:	470d                	li	a4,3
    8000486c:	02e78a63          	beq	a5,a4,800048a0 <filewrite+0x5a>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004870:	4709                	li	a4,2
    80004872:	0ee79863          	bne	a5,a4,80004962 <filewrite+0x11c>
    80004876:	f44e                	sd	s3,40(sp)
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004878:	0cc05463          	blez	a2,80004940 <filewrite+0xfa>
    8000487c:	fc26                	sd	s1,56(sp)
    8000487e:	ec56                	sd	s5,24(sp)
    80004880:	e45e                	sd	s7,8(sp)
    80004882:	e062                	sd	s8,0(sp)
    int i = 0;
    80004884:	4981                	li	s3,0
      int n1 = n - i;
      if(n1 > max)
    80004886:	6b85                	lui	s7,0x1
    80004888:	c00b8b93          	addi	s7,s7,-1024 # c00 <_entry-0x7ffff400>
    8000488c:	6c05                	lui	s8,0x1
    8000488e:	c00c0c1b          	addiw	s8,s8,-1024 # c00 <_entry-0x7ffff400>
    80004892:	a851                	j	80004926 <filewrite+0xe0>
    ret = pipewrite(f->pipe, addr, n);
    80004894:	6908                	ld	a0,16(a0)
    80004896:	00000097          	auipc	ra,0x0
    8000489a:	248080e7          	jalr	584(ra) # 80004ade <pipewrite>
    8000489e:	a85d                	j	80004954 <filewrite+0x10e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    800048a0:	02451783          	lh	a5,36(a0)
    800048a4:	03079693          	slli	a3,a5,0x30
    800048a8:	92c1                	srli	a3,a3,0x30
    800048aa:	4725                	li	a4,9
    800048ac:	0cd76a63          	bltu	a4,a3,80004980 <filewrite+0x13a>
    800048b0:	0792                	slli	a5,a5,0x4
    800048b2:	0001f717          	auipc	a4,0x1f
    800048b6:	c7670713          	addi	a4,a4,-906 # 80023528 <devsw>
    800048ba:	97ba                	add	a5,a5,a4
    800048bc:	679c                	ld	a5,8(a5)
    800048be:	c3f9                	beqz	a5,80004984 <filewrite+0x13e>
    ret = devsw[f->major].write(1, addr, n);
    800048c0:	4505                	li	a0,1
    800048c2:	9782                	jalr	a5
    800048c4:	a841                	j	80004954 <filewrite+0x10e>
      if(n1 > max)
    800048c6:	00048a9b          	sext.w	s5,s1
        n1 = max;

      begin_op();
    800048ca:	00000097          	auipc	ra,0x0
    800048ce:	88c080e7          	jalr	-1908(ra) # 80004156 <begin_op>
      ilock(f->ip);
    800048d2:	01893503          	ld	a0,24(s2)
    800048d6:	fffff097          	auipc	ra,0xfffff
    800048da:	eb2080e7          	jalr	-334(ra) # 80003788 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    800048de:	8756                	mv	a4,s5
    800048e0:	02092683          	lw	a3,32(s2)
    800048e4:	01698633          	add	a2,s3,s6
    800048e8:	4585                	li	a1,1
    800048ea:	01893503          	ld	a0,24(s2)
    800048ee:	fffff097          	auipc	ra,0xfffff
    800048f2:	262080e7          	jalr	610(ra) # 80003b50 <writei>
    800048f6:	84aa                	mv	s1,a0
    800048f8:	00a05763          	blez	a0,80004906 <filewrite+0xc0>
        f->off += r;
    800048fc:	02092783          	lw	a5,32(s2)
    80004900:	9fa9                	addw	a5,a5,a0
    80004902:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004906:	01893503          	ld	a0,24(s2)
    8000490a:	fffff097          	auipc	ra,0xfffff
    8000490e:	f44080e7          	jalr	-188(ra) # 8000384e <iunlock>
      end_op();
    80004912:	00000097          	auipc	ra,0x0
    80004916:	8be080e7          	jalr	-1858(ra) # 800041d0 <end_op>

      if(r != n1){
    8000491a:	029a9563          	bne	s5,s1,80004944 <filewrite+0xfe>
        // error from writei
        break;
      }
      i += r;
    8000491e:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004922:	0149da63          	bge	s3,s4,80004936 <filewrite+0xf0>
      int n1 = n - i;
    80004926:	413a04bb          	subw	s1,s4,s3
      if(n1 > max)
    8000492a:	0004879b          	sext.w	a5,s1
    8000492e:	f8fbdce3          	bge	s7,a5,800048c6 <filewrite+0x80>
    80004932:	84e2                	mv	s1,s8
    80004934:	bf49                	j	800048c6 <filewrite+0x80>
    80004936:	74e2                	ld	s1,56(sp)
    80004938:	6ae2                	ld	s5,24(sp)
    8000493a:	6ba2                	ld	s7,8(sp)
    8000493c:	6c02                	ld	s8,0(sp)
    8000493e:	a039                	j	8000494c <filewrite+0x106>
    int i = 0;
    80004940:	4981                	li	s3,0
    80004942:	a029                	j	8000494c <filewrite+0x106>
    80004944:	74e2                	ld	s1,56(sp)
    80004946:	6ae2                	ld	s5,24(sp)
    80004948:	6ba2                	ld	s7,8(sp)
    8000494a:	6c02                	ld	s8,0(sp)
    }
    ret = (i == n ? n : -1);
    8000494c:	033a1e63          	bne	s4,s3,80004988 <filewrite+0x142>
    80004950:	8552                	mv	a0,s4
    80004952:	79a2                	ld	s3,40(sp)
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004954:	60a6                	ld	ra,72(sp)
    80004956:	6406                	ld	s0,64(sp)
    80004958:	7942                	ld	s2,48(sp)
    8000495a:	7a02                	ld	s4,32(sp)
    8000495c:	6b42                	ld	s6,16(sp)
    8000495e:	6161                	addi	sp,sp,80
    80004960:	8082                	ret
    80004962:	fc26                	sd	s1,56(sp)
    80004964:	f44e                	sd	s3,40(sp)
    80004966:	ec56                	sd	s5,24(sp)
    80004968:	e45e                	sd	s7,8(sp)
    8000496a:	e062                	sd	s8,0(sp)
    panic("filewrite");
    8000496c:	00004517          	auipc	a0,0x4
    80004970:	c5450513          	addi	a0,a0,-940 # 800085c0 <etext+0x5c0>
    80004974:	ffffc097          	auipc	ra,0xffffc
    80004978:	bec080e7          	jalr	-1044(ra) # 80000560 <panic>
    return -1;
    8000497c:	557d                	li	a0,-1
}
    8000497e:	8082                	ret
      return -1;
    80004980:	557d                	li	a0,-1
    80004982:	bfc9                	j	80004954 <filewrite+0x10e>
    80004984:	557d                	li	a0,-1
    80004986:	b7f9                	j	80004954 <filewrite+0x10e>
    ret = (i == n ? n : -1);
    80004988:	557d                	li	a0,-1
    8000498a:	79a2                	ld	s3,40(sp)
    8000498c:	b7e1                	j	80004954 <filewrite+0x10e>

000000008000498e <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    8000498e:	7179                	addi	sp,sp,-48
    80004990:	f406                	sd	ra,40(sp)
    80004992:	f022                	sd	s0,32(sp)
    80004994:	ec26                	sd	s1,24(sp)
    80004996:	e052                	sd	s4,0(sp)
    80004998:	1800                	addi	s0,sp,48
    8000499a:	84aa                	mv	s1,a0
    8000499c:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    8000499e:	0005b023          	sd	zero,0(a1)
    800049a2:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    800049a6:	00000097          	auipc	ra,0x0
    800049aa:	bbe080e7          	jalr	-1090(ra) # 80004564 <filealloc>
    800049ae:	e088                	sd	a0,0(s1)
    800049b0:	cd49                	beqz	a0,80004a4a <pipealloc+0xbc>
    800049b2:	00000097          	auipc	ra,0x0
    800049b6:	bb2080e7          	jalr	-1102(ra) # 80004564 <filealloc>
    800049ba:	00aa3023          	sd	a0,0(s4)
    800049be:	c141                	beqz	a0,80004a3e <pipealloc+0xb0>
    800049c0:	e84a                	sd	s2,16(sp)
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    800049c2:	ffffc097          	auipc	ra,0xffffc
    800049c6:	186080e7          	jalr	390(ra) # 80000b48 <kalloc>
    800049ca:	892a                	mv	s2,a0
    800049cc:	c13d                	beqz	a0,80004a32 <pipealloc+0xa4>
    800049ce:	e44e                	sd	s3,8(sp)
    goto bad;
  pi->readopen = 1;
    800049d0:	4985                	li	s3,1
    800049d2:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    800049d6:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    800049da:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    800049de:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    800049e2:	00004597          	auipc	a1,0x4
    800049e6:	bee58593          	addi	a1,a1,-1042 # 800085d0 <etext+0x5d0>
    800049ea:	ffffc097          	auipc	ra,0xffffc
    800049ee:	206080e7          	jalr	518(ra) # 80000bf0 <initlock>
  (*f0)->type = FD_PIPE;
    800049f2:	609c                	ld	a5,0(s1)
    800049f4:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    800049f8:	609c                	ld	a5,0(s1)
    800049fa:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    800049fe:	609c                	ld	a5,0(s1)
    80004a00:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004a04:	609c                	ld	a5,0(s1)
    80004a06:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004a0a:	000a3783          	ld	a5,0(s4)
    80004a0e:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004a12:	000a3783          	ld	a5,0(s4)
    80004a16:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004a1a:	000a3783          	ld	a5,0(s4)
    80004a1e:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004a22:	000a3783          	ld	a5,0(s4)
    80004a26:	0127b823          	sd	s2,16(a5)
  return 0;
    80004a2a:	4501                	li	a0,0
    80004a2c:	6942                	ld	s2,16(sp)
    80004a2e:	69a2                	ld	s3,8(sp)
    80004a30:	a03d                	j	80004a5e <pipealloc+0xd0>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004a32:	6088                	ld	a0,0(s1)
    80004a34:	c119                	beqz	a0,80004a3a <pipealloc+0xac>
    80004a36:	6942                	ld	s2,16(sp)
    80004a38:	a029                	j	80004a42 <pipealloc+0xb4>
    80004a3a:	6942                	ld	s2,16(sp)
    80004a3c:	a039                	j	80004a4a <pipealloc+0xbc>
    80004a3e:	6088                	ld	a0,0(s1)
    80004a40:	c50d                	beqz	a0,80004a6a <pipealloc+0xdc>
    fileclose(*f0);
    80004a42:	00000097          	auipc	ra,0x0
    80004a46:	bde080e7          	jalr	-1058(ra) # 80004620 <fileclose>
  if(*f1)
    80004a4a:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004a4e:	557d                	li	a0,-1
  if(*f1)
    80004a50:	c799                	beqz	a5,80004a5e <pipealloc+0xd0>
    fileclose(*f1);
    80004a52:	853e                	mv	a0,a5
    80004a54:	00000097          	auipc	ra,0x0
    80004a58:	bcc080e7          	jalr	-1076(ra) # 80004620 <fileclose>
  return -1;
    80004a5c:	557d                	li	a0,-1
}
    80004a5e:	70a2                	ld	ra,40(sp)
    80004a60:	7402                	ld	s0,32(sp)
    80004a62:	64e2                	ld	s1,24(sp)
    80004a64:	6a02                	ld	s4,0(sp)
    80004a66:	6145                	addi	sp,sp,48
    80004a68:	8082                	ret
  return -1;
    80004a6a:	557d                	li	a0,-1
    80004a6c:	bfcd                	j	80004a5e <pipealloc+0xd0>

0000000080004a6e <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004a6e:	1101                	addi	sp,sp,-32
    80004a70:	ec06                	sd	ra,24(sp)
    80004a72:	e822                	sd	s0,16(sp)
    80004a74:	e426                	sd	s1,8(sp)
    80004a76:	e04a                	sd	s2,0(sp)
    80004a78:	1000                	addi	s0,sp,32
    80004a7a:	84aa                	mv	s1,a0
    80004a7c:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004a7e:	ffffc097          	auipc	ra,0xffffc
    80004a82:	202080e7          	jalr	514(ra) # 80000c80 <acquire>
  if(writable){
    80004a86:	02090d63          	beqz	s2,80004ac0 <pipeclose+0x52>
    pi->writeopen = 0;
    80004a8a:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004a8e:	21848513          	addi	a0,s1,536
    80004a92:	ffffd097          	auipc	ra,0xffffd
    80004a96:	728080e7          	jalr	1832(ra) # 800021ba <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004a9a:	2204b783          	ld	a5,544(s1)
    80004a9e:	eb95                	bnez	a5,80004ad2 <pipeclose+0x64>
    release(&pi->lock);
    80004aa0:	8526                	mv	a0,s1
    80004aa2:	ffffc097          	auipc	ra,0xffffc
    80004aa6:	292080e7          	jalr	658(ra) # 80000d34 <release>
    kfree((char*)pi);
    80004aaa:	8526                	mv	a0,s1
    80004aac:	ffffc097          	auipc	ra,0xffffc
    80004ab0:	f9e080e7          	jalr	-98(ra) # 80000a4a <kfree>
  } else
    release(&pi->lock);
}
    80004ab4:	60e2                	ld	ra,24(sp)
    80004ab6:	6442                	ld	s0,16(sp)
    80004ab8:	64a2                	ld	s1,8(sp)
    80004aba:	6902                	ld	s2,0(sp)
    80004abc:	6105                	addi	sp,sp,32
    80004abe:	8082                	ret
    pi->readopen = 0;
    80004ac0:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004ac4:	21c48513          	addi	a0,s1,540
    80004ac8:	ffffd097          	auipc	ra,0xffffd
    80004acc:	6f2080e7          	jalr	1778(ra) # 800021ba <wakeup>
    80004ad0:	b7e9                	j	80004a9a <pipeclose+0x2c>
    release(&pi->lock);
    80004ad2:	8526                	mv	a0,s1
    80004ad4:	ffffc097          	auipc	ra,0xffffc
    80004ad8:	260080e7          	jalr	608(ra) # 80000d34 <release>
}
    80004adc:	bfe1                	j	80004ab4 <pipeclose+0x46>

0000000080004ade <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004ade:	711d                	addi	sp,sp,-96
    80004ae0:	ec86                	sd	ra,88(sp)
    80004ae2:	e8a2                	sd	s0,80(sp)
    80004ae4:	e4a6                	sd	s1,72(sp)
    80004ae6:	e0ca                	sd	s2,64(sp)
    80004ae8:	fc4e                	sd	s3,56(sp)
    80004aea:	f852                	sd	s4,48(sp)
    80004aec:	f456                	sd	s5,40(sp)
    80004aee:	1080                	addi	s0,sp,96
    80004af0:	84aa                	mv	s1,a0
    80004af2:	8aae                	mv	s5,a1
    80004af4:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004af6:	ffffd097          	auipc	ra,0xffffd
    80004afa:	fb6080e7          	jalr	-74(ra) # 80001aac <myproc>
    80004afe:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004b00:	8526                	mv	a0,s1
    80004b02:	ffffc097          	auipc	ra,0xffffc
    80004b06:	17e080e7          	jalr	382(ra) # 80000c80 <acquire>
  while(i < n){
    80004b0a:	0d405863          	blez	s4,80004bda <pipewrite+0xfc>
    80004b0e:	f05a                	sd	s6,32(sp)
    80004b10:	ec5e                	sd	s7,24(sp)
    80004b12:	e862                	sd	s8,16(sp)
  int i = 0;
    80004b14:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004b16:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004b18:	21848c13          	addi	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004b1c:	21c48b93          	addi	s7,s1,540
    80004b20:	a089                	j	80004b62 <pipewrite+0x84>
      release(&pi->lock);
    80004b22:	8526                	mv	a0,s1
    80004b24:	ffffc097          	auipc	ra,0xffffc
    80004b28:	210080e7          	jalr	528(ra) # 80000d34 <release>
      return -1;
    80004b2c:	597d                	li	s2,-1
    80004b2e:	7b02                	ld	s6,32(sp)
    80004b30:	6be2                	ld	s7,24(sp)
    80004b32:	6c42                	ld	s8,16(sp)
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004b34:	854a                	mv	a0,s2
    80004b36:	60e6                	ld	ra,88(sp)
    80004b38:	6446                	ld	s0,80(sp)
    80004b3a:	64a6                	ld	s1,72(sp)
    80004b3c:	6906                	ld	s2,64(sp)
    80004b3e:	79e2                	ld	s3,56(sp)
    80004b40:	7a42                	ld	s4,48(sp)
    80004b42:	7aa2                	ld	s5,40(sp)
    80004b44:	6125                	addi	sp,sp,96
    80004b46:	8082                	ret
      wakeup(&pi->nread);
    80004b48:	8562                	mv	a0,s8
    80004b4a:	ffffd097          	auipc	ra,0xffffd
    80004b4e:	670080e7          	jalr	1648(ra) # 800021ba <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004b52:	85a6                	mv	a1,s1
    80004b54:	855e                	mv	a0,s7
    80004b56:	ffffd097          	auipc	ra,0xffffd
    80004b5a:	600080e7          	jalr	1536(ra) # 80002156 <sleep>
  while(i < n){
    80004b5e:	05495f63          	bge	s2,s4,80004bbc <pipewrite+0xde>
    if(pi->readopen == 0 || killed(pr)){
    80004b62:	2204a783          	lw	a5,544(s1)
    80004b66:	dfd5                	beqz	a5,80004b22 <pipewrite+0x44>
    80004b68:	854e                	mv	a0,s3
    80004b6a:	ffffe097          	auipc	ra,0xffffe
    80004b6e:	894080e7          	jalr	-1900(ra) # 800023fe <killed>
    80004b72:	f945                	bnez	a0,80004b22 <pipewrite+0x44>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004b74:	2184a783          	lw	a5,536(s1)
    80004b78:	21c4a703          	lw	a4,540(s1)
    80004b7c:	2007879b          	addiw	a5,a5,512
    80004b80:	fcf704e3          	beq	a4,a5,80004b48 <pipewrite+0x6a>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004b84:	4685                	li	a3,1
    80004b86:	01590633          	add	a2,s2,s5
    80004b8a:	faf40593          	addi	a1,s0,-81
    80004b8e:	0509b503          	ld	a0,80(s3)
    80004b92:	ffffd097          	auipc	ra,0xffffd
    80004b96:	c3e080e7          	jalr	-962(ra) # 800017d0 <copyin>
    80004b9a:	05650263          	beq	a0,s6,80004bde <pipewrite+0x100>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004b9e:	21c4a783          	lw	a5,540(s1)
    80004ba2:	0017871b          	addiw	a4,a5,1
    80004ba6:	20e4ae23          	sw	a4,540(s1)
    80004baa:	1ff7f793          	andi	a5,a5,511
    80004bae:	97a6                	add	a5,a5,s1
    80004bb0:	faf44703          	lbu	a4,-81(s0)
    80004bb4:	00e78c23          	sb	a4,24(a5)
      i++;
    80004bb8:	2905                	addiw	s2,s2,1
    80004bba:	b755                	j	80004b5e <pipewrite+0x80>
    80004bbc:	7b02                	ld	s6,32(sp)
    80004bbe:	6be2                	ld	s7,24(sp)
    80004bc0:	6c42                	ld	s8,16(sp)
  wakeup(&pi->nread);
    80004bc2:	21848513          	addi	a0,s1,536
    80004bc6:	ffffd097          	auipc	ra,0xffffd
    80004bca:	5f4080e7          	jalr	1524(ra) # 800021ba <wakeup>
  release(&pi->lock);
    80004bce:	8526                	mv	a0,s1
    80004bd0:	ffffc097          	auipc	ra,0xffffc
    80004bd4:	164080e7          	jalr	356(ra) # 80000d34 <release>
  return i;
    80004bd8:	bfb1                	j	80004b34 <pipewrite+0x56>
  int i = 0;
    80004bda:	4901                	li	s2,0
    80004bdc:	b7dd                	j	80004bc2 <pipewrite+0xe4>
    80004bde:	7b02                	ld	s6,32(sp)
    80004be0:	6be2                	ld	s7,24(sp)
    80004be2:	6c42                	ld	s8,16(sp)
    80004be4:	bff9                	j	80004bc2 <pipewrite+0xe4>

0000000080004be6 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004be6:	715d                	addi	sp,sp,-80
    80004be8:	e486                	sd	ra,72(sp)
    80004bea:	e0a2                	sd	s0,64(sp)
    80004bec:	fc26                	sd	s1,56(sp)
    80004bee:	f84a                	sd	s2,48(sp)
    80004bf0:	f44e                	sd	s3,40(sp)
    80004bf2:	f052                	sd	s4,32(sp)
    80004bf4:	ec56                	sd	s5,24(sp)
    80004bf6:	0880                	addi	s0,sp,80
    80004bf8:	84aa                	mv	s1,a0
    80004bfa:	892e                	mv	s2,a1
    80004bfc:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004bfe:	ffffd097          	auipc	ra,0xffffd
    80004c02:	eae080e7          	jalr	-338(ra) # 80001aac <myproc>
    80004c06:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004c08:	8526                	mv	a0,s1
    80004c0a:	ffffc097          	auipc	ra,0xffffc
    80004c0e:	076080e7          	jalr	118(ra) # 80000c80 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004c12:	2184a703          	lw	a4,536(s1)
    80004c16:	21c4a783          	lw	a5,540(s1)
    if(killed(pr)){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004c1a:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004c1e:	02f71963          	bne	a4,a5,80004c50 <piperead+0x6a>
    80004c22:	2244a783          	lw	a5,548(s1)
    80004c26:	cf95                	beqz	a5,80004c62 <piperead+0x7c>
    if(killed(pr)){
    80004c28:	8552                	mv	a0,s4
    80004c2a:	ffffd097          	auipc	ra,0xffffd
    80004c2e:	7d4080e7          	jalr	2004(ra) # 800023fe <killed>
    80004c32:	e10d                	bnez	a0,80004c54 <piperead+0x6e>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004c34:	85a6                	mv	a1,s1
    80004c36:	854e                	mv	a0,s3
    80004c38:	ffffd097          	auipc	ra,0xffffd
    80004c3c:	51e080e7          	jalr	1310(ra) # 80002156 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004c40:	2184a703          	lw	a4,536(s1)
    80004c44:	21c4a783          	lw	a5,540(s1)
    80004c48:	fcf70de3          	beq	a4,a5,80004c22 <piperead+0x3c>
    80004c4c:	e85a                	sd	s6,16(sp)
    80004c4e:	a819                	j	80004c64 <piperead+0x7e>
    80004c50:	e85a                	sd	s6,16(sp)
    80004c52:	a809                	j	80004c64 <piperead+0x7e>
      release(&pi->lock);
    80004c54:	8526                	mv	a0,s1
    80004c56:	ffffc097          	auipc	ra,0xffffc
    80004c5a:	0de080e7          	jalr	222(ra) # 80000d34 <release>
      return -1;
    80004c5e:	59fd                	li	s3,-1
    80004c60:	a0a5                	j	80004cc8 <piperead+0xe2>
    80004c62:	e85a                	sd	s6,16(sp)
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004c64:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004c66:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004c68:	05505463          	blez	s5,80004cb0 <piperead+0xca>
    if(pi->nread == pi->nwrite)
    80004c6c:	2184a783          	lw	a5,536(s1)
    80004c70:	21c4a703          	lw	a4,540(s1)
    80004c74:	02f70e63          	beq	a4,a5,80004cb0 <piperead+0xca>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004c78:	0017871b          	addiw	a4,a5,1
    80004c7c:	20e4ac23          	sw	a4,536(s1)
    80004c80:	1ff7f793          	andi	a5,a5,511
    80004c84:	97a6                	add	a5,a5,s1
    80004c86:	0187c783          	lbu	a5,24(a5)
    80004c8a:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004c8e:	4685                	li	a3,1
    80004c90:	fbf40613          	addi	a2,s0,-65
    80004c94:	85ca                	mv	a1,s2
    80004c96:	050a3503          	ld	a0,80(s4)
    80004c9a:	ffffd097          	auipc	ra,0xffffd
    80004c9e:	aaa080e7          	jalr	-1366(ra) # 80001744 <copyout>
    80004ca2:	01650763          	beq	a0,s6,80004cb0 <piperead+0xca>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004ca6:	2985                	addiw	s3,s3,1
    80004ca8:	0905                	addi	s2,s2,1
    80004caa:	fd3a91e3          	bne	s5,s3,80004c6c <piperead+0x86>
    80004cae:	89d6                	mv	s3,s5
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004cb0:	21c48513          	addi	a0,s1,540
    80004cb4:	ffffd097          	auipc	ra,0xffffd
    80004cb8:	506080e7          	jalr	1286(ra) # 800021ba <wakeup>
  release(&pi->lock);
    80004cbc:	8526                	mv	a0,s1
    80004cbe:	ffffc097          	auipc	ra,0xffffc
    80004cc2:	076080e7          	jalr	118(ra) # 80000d34 <release>
    80004cc6:	6b42                	ld	s6,16(sp)
  return i;
}
    80004cc8:	854e                	mv	a0,s3
    80004cca:	60a6                	ld	ra,72(sp)
    80004ccc:	6406                	ld	s0,64(sp)
    80004cce:	74e2                	ld	s1,56(sp)
    80004cd0:	7942                	ld	s2,48(sp)
    80004cd2:	79a2                	ld	s3,40(sp)
    80004cd4:	7a02                	ld	s4,32(sp)
    80004cd6:	6ae2                	ld	s5,24(sp)
    80004cd8:	6161                	addi	sp,sp,80
    80004cda:	8082                	ret

0000000080004cdc <flags2perm>:
#include "elf.h"

static int loadseg(pde_t *, uint64, struct inode *, uint, uint);

int flags2perm(int flags)
{
    80004cdc:	1141                	addi	sp,sp,-16
    80004cde:	e422                	sd	s0,8(sp)
    80004ce0:	0800                	addi	s0,sp,16
    80004ce2:	87aa                	mv	a5,a0
    int perm = 0;
    if(flags & 0x1)
    80004ce4:	8905                	andi	a0,a0,1
    80004ce6:	050e                	slli	a0,a0,0x3
      perm = PTE_X;
    if(flags & 0x2)
    80004ce8:	8b89                	andi	a5,a5,2
    80004cea:	c399                	beqz	a5,80004cf0 <flags2perm+0x14>
      perm |= PTE_W;
    80004cec:	00456513          	ori	a0,a0,4
    return perm;
}
    80004cf0:	6422                	ld	s0,8(sp)
    80004cf2:	0141                	addi	sp,sp,16
    80004cf4:	8082                	ret

0000000080004cf6 <exec>:

int
exec(char *path, char **argv)
{
    80004cf6:	df010113          	addi	sp,sp,-528
    80004cfa:	20113423          	sd	ra,520(sp)
    80004cfe:	20813023          	sd	s0,512(sp)
    80004d02:	ffa6                	sd	s1,504(sp)
    80004d04:	fbca                	sd	s2,496(sp)
    80004d06:	0c00                	addi	s0,sp,528
    80004d08:	892a                	mv	s2,a0
    80004d0a:	dea43c23          	sd	a0,-520(s0)
    80004d0e:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004d12:	ffffd097          	auipc	ra,0xffffd
    80004d16:	d9a080e7          	jalr	-614(ra) # 80001aac <myproc>
    80004d1a:	84aa                	mv	s1,a0

  begin_op();
    80004d1c:	fffff097          	auipc	ra,0xfffff
    80004d20:	43a080e7          	jalr	1082(ra) # 80004156 <begin_op>

  if((ip = namei(path)) == 0){
    80004d24:	854a                	mv	a0,s2
    80004d26:	fffff097          	auipc	ra,0xfffff
    80004d2a:	230080e7          	jalr	560(ra) # 80003f56 <namei>
    80004d2e:	c135                	beqz	a0,80004d92 <exec+0x9c>
    80004d30:	f3d2                	sd	s4,480(sp)
    80004d32:	8a2a                	mv	s4,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004d34:	fffff097          	auipc	ra,0xfffff
    80004d38:	a54080e7          	jalr	-1452(ra) # 80003788 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004d3c:	04000713          	li	a4,64
    80004d40:	4681                	li	a3,0
    80004d42:	e5040613          	addi	a2,s0,-432
    80004d46:	4581                	li	a1,0
    80004d48:	8552                	mv	a0,s4
    80004d4a:	fffff097          	auipc	ra,0xfffff
    80004d4e:	cf6080e7          	jalr	-778(ra) # 80003a40 <readi>
    80004d52:	04000793          	li	a5,64
    80004d56:	00f51a63          	bne	a0,a5,80004d6a <exec+0x74>
    goto bad;

  if(elf.magic != ELF_MAGIC)
    80004d5a:	e5042703          	lw	a4,-432(s0)
    80004d5e:	464c47b7          	lui	a5,0x464c4
    80004d62:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004d66:	02f70c63          	beq	a4,a5,80004d9e <exec+0xa8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004d6a:	8552                	mv	a0,s4
    80004d6c:	fffff097          	auipc	ra,0xfffff
    80004d70:	c82080e7          	jalr	-894(ra) # 800039ee <iunlockput>
    end_op();
    80004d74:	fffff097          	auipc	ra,0xfffff
    80004d78:	45c080e7          	jalr	1116(ra) # 800041d0 <end_op>
  }
  return -1;
    80004d7c:	557d                	li	a0,-1
    80004d7e:	7a1e                	ld	s4,480(sp)
}
    80004d80:	20813083          	ld	ra,520(sp)
    80004d84:	20013403          	ld	s0,512(sp)
    80004d88:	74fe                	ld	s1,504(sp)
    80004d8a:	795e                	ld	s2,496(sp)
    80004d8c:	21010113          	addi	sp,sp,528
    80004d90:	8082                	ret
    end_op();
    80004d92:	fffff097          	auipc	ra,0xfffff
    80004d96:	43e080e7          	jalr	1086(ra) # 800041d0 <end_op>
    return -1;
    80004d9a:	557d                	li	a0,-1
    80004d9c:	b7d5                	j	80004d80 <exec+0x8a>
    80004d9e:	ebda                	sd	s6,464(sp)
  if((pagetable = proc_pagetable(p)) == 0)
    80004da0:	8526                	mv	a0,s1
    80004da2:	ffffd097          	auipc	ra,0xffffd
    80004da6:	dce080e7          	jalr	-562(ra) # 80001b70 <proc_pagetable>
    80004daa:	8b2a                	mv	s6,a0
    80004dac:	30050f63          	beqz	a0,800050ca <exec+0x3d4>
    80004db0:	f7ce                	sd	s3,488(sp)
    80004db2:	efd6                	sd	s5,472(sp)
    80004db4:	e7de                	sd	s7,456(sp)
    80004db6:	e3e2                	sd	s8,448(sp)
    80004db8:	ff66                	sd	s9,440(sp)
    80004dba:	fb6a                	sd	s10,432(sp)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004dbc:	e7042d03          	lw	s10,-400(s0)
    80004dc0:	e8845783          	lhu	a5,-376(s0)
    80004dc4:	14078d63          	beqz	a5,80004f1e <exec+0x228>
    80004dc8:	f76e                	sd	s11,424(sp)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004dca:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004dcc:	4d81                	li	s11,0
    if(ph.vaddr % PGSIZE != 0)
    80004dce:	6c85                	lui	s9,0x1
    80004dd0:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    80004dd4:	def43823          	sd	a5,-528(s0)

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    if(sz - i < PGSIZE)
    80004dd8:	6a85                	lui	s5,0x1
    80004dda:	a0b5                	j	80004e46 <exec+0x150>
      panic("loadseg: address should exist");
    80004ddc:	00003517          	auipc	a0,0x3
    80004de0:	7fc50513          	addi	a0,a0,2044 # 800085d8 <etext+0x5d8>
    80004de4:	ffffb097          	auipc	ra,0xffffb
    80004de8:	77c080e7          	jalr	1916(ra) # 80000560 <panic>
    if(sz - i < PGSIZE)
    80004dec:	2481                	sext.w	s1,s1
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004dee:	8726                	mv	a4,s1
    80004df0:	012c06bb          	addw	a3,s8,s2
    80004df4:	4581                	li	a1,0
    80004df6:	8552                	mv	a0,s4
    80004df8:	fffff097          	auipc	ra,0xfffff
    80004dfc:	c48080e7          	jalr	-952(ra) # 80003a40 <readi>
    80004e00:	2501                	sext.w	a0,a0
    80004e02:	28a49863          	bne	s1,a0,80005092 <exec+0x39c>
  for(i = 0; i < sz; i += PGSIZE){
    80004e06:	012a893b          	addw	s2,s5,s2
    80004e0a:	03397563          	bgeu	s2,s3,80004e34 <exec+0x13e>
    pa = walkaddr(pagetable, va + i);
    80004e0e:	02091593          	slli	a1,s2,0x20
    80004e12:	9181                	srli	a1,a1,0x20
    80004e14:	95de                	add	a1,a1,s7
    80004e16:	855a                	mv	a0,s6
    80004e18:	ffffc097          	auipc	ra,0xffffc
    80004e1c:	300080e7          	jalr	768(ra) # 80001118 <walkaddr>
    80004e20:	862a                	mv	a2,a0
    if(pa == 0)
    80004e22:	dd4d                	beqz	a0,80004ddc <exec+0xe6>
    if(sz - i < PGSIZE)
    80004e24:	412984bb          	subw	s1,s3,s2
    80004e28:	0004879b          	sext.w	a5,s1
    80004e2c:	fcfcf0e3          	bgeu	s9,a5,80004dec <exec+0xf6>
    80004e30:	84d6                	mv	s1,s5
    80004e32:	bf6d                	j	80004dec <exec+0xf6>
    sz = sz1;
    80004e34:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004e38:	2d85                	addiw	s11,s11,1
    80004e3a:	038d0d1b          	addiw	s10,s10,56
    80004e3e:	e8845783          	lhu	a5,-376(s0)
    80004e42:	08fdd663          	bge	s11,a5,80004ece <exec+0x1d8>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80004e46:	2d01                	sext.w	s10,s10
    80004e48:	03800713          	li	a4,56
    80004e4c:	86ea                	mv	a3,s10
    80004e4e:	e1840613          	addi	a2,s0,-488
    80004e52:	4581                	li	a1,0
    80004e54:	8552                	mv	a0,s4
    80004e56:	fffff097          	auipc	ra,0xfffff
    80004e5a:	bea080e7          	jalr	-1046(ra) # 80003a40 <readi>
    80004e5e:	03800793          	li	a5,56
    80004e62:	20f51063          	bne	a0,a5,80005062 <exec+0x36c>
    if(ph.type != ELF_PROG_LOAD)
    80004e66:	e1842783          	lw	a5,-488(s0)
    80004e6a:	4705                	li	a4,1
    80004e6c:	fce796e3          	bne	a5,a4,80004e38 <exec+0x142>
    if(ph.memsz < ph.filesz)
    80004e70:	e4043483          	ld	s1,-448(s0)
    80004e74:	e3843783          	ld	a5,-456(s0)
    80004e78:	1ef4e963          	bltu	s1,a5,8000506a <exec+0x374>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80004e7c:	e2843783          	ld	a5,-472(s0)
    80004e80:	94be                	add	s1,s1,a5
    80004e82:	1ef4e863          	bltu	s1,a5,80005072 <exec+0x37c>
    if(ph.vaddr % PGSIZE != 0)
    80004e86:	df043703          	ld	a4,-528(s0)
    80004e8a:	8ff9                	and	a5,a5,a4
    80004e8c:	1e079763          	bnez	a5,8000507a <exec+0x384>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80004e90:	e1c42503          	lw	a0,-484(s0)
    80004e94:	00000097          	auipc	ra,0x0
    80004e98:	e48080e7          	jalr	-440(ra) # 80004cdc <flags2perm>
    80004e9c:	86aa                	mv	a3,a0
    80004e9e:	8626                	mv	a2,s1
    80004ea0:	85ca                	mv	a1,s2
    80004ea2:	855a                	mv	a0,s6
    80004ea4:	ffffc097          	auipc	ra,0xffffc
    80004ea8:	638080e7          	jalr	1592(ra) # 800014dc <uvmalloc>
    80004eac:	e0a43423          	sd	a0,-504(s0)
    80004eb0:	1c050963          	beqz	a0,80005082 <exec+0x38c>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80004eb4:	e2843b83          	ld	s7,-472(s0)
    80004eb8:	e2042c03          	lw	s8,-480(s0)
    80004ebc:	e3842983          	lw	s3,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80004ec0:	00098463          	beqz	s3,80004ec8 <exec+0x1d2>
    80004ec4:	4901                	li	s2,0
    80004ec6:	b7a1                	j	80004e0e <exec+0x118>
    sz = sz1;
    80004ec8:	e0843903          	ld	s2,-504(s0)
    80004ecc:	b7b5                	j	80004e38 <exec+0x142>
    80004ece:	7dba                	ld	s11,424(sp)
  iunlockput(ip);
    80004ed0:	8552                	mv	a0,s4
    80004ed2:	fffff097          	auipc	ra,0xfffff
    80004ed6:	b1c080e7          	jalr	-1252(ra) # 800039ee <iunlockput>
  end_op();
    80004eda:	fffff097          	auipc	ra,0xfffff
    80004ede:	2f6080e7          	jalr	758(ra) # 800041d0 <end_op>
  p = myproc();
    80004ee2:	ffffd097          	auipc	ra,0xffffd
    80004ee6:	bca080e7          	jalr	-1078(ra) # 80001aac <myproc>
    80004eea:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    80004eec:	04853c83          	ld	s9,72(a0)
  sz = PGROUNDUP(sz);
    80004ef0:	6985                	lui	s3,0x1
    80004ef2:	19fd                	addi	s3,s3,-1 # fff <_entry-0x7ffff001>
    80004ef4:	99ca                	add	s3,s3,s2
    80004ef6:	77fd                	lui	a5,0xfffff
    80004ef8:	00f9f9b3          	and	s3,s3,a5
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    80004efc:	4691                	li	a3,4
    80004efe:	6609                	lui	a2,0x2
    80004f00:	964e                	add	a2,a2,s3
    80004f02:	85ce                	mv	a1,s3
    80004f04:	855a                	mv	a0,s6
    80004f06:	ffffc097          	auipc	ra,0xffffc
    80004f0a:	5d6080e7          	jalr	1494(ra) # 800014dc <uvmalloc>
    80004f0e:	892a                	mv	s2,a0
    80004f10:	e0a43423          	sd	a0,-504(s0)
    80004f14:	e519                	bnez	a0,80004f22 <exec+0x22c>
  if(pagetable)
    80004f16:	e1343423          	sd	s3,-504(s0)
    80004f1a:	4a01                	li	s4,0
    80004f1c:	aaa5                	j	80005094 <exec+0x39e>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004f1e:	4901                	li	s2,0
    80004f20:	bf45                	j	80004ed0 <exec+0x1da>
  uvmclear(pagetable, sz-2*PGSIZE);
    80004f22:	75f9                	lui	a1,0xffffe
    80004f24:	95aa                	add	a1,a1,a0
    80004f26:	855a                	mv	a0,s6
    80004f28:	ffffc097          	auipc	ra,0xffffc
    80004f2c:	7ea080e7          	jalr	2026(ra) # 80001712 <uvmclear>
  stackbase = sp - PGSIZE;
    80004f30:	7bfd                	lui	s7,0xfffff
    80004f32:	9bca                	add	s7,s7,s2
  for(argc = 0; argv[argc]; argc++) {
    80004f34:	e0043783          	ld	a5,-512(s0)
    80004f38:	6388                	ld	a0,0(a5)
    80004f3a:	c52d                	beqz	a0,80004fa4 <exec+0x2ae>
    80004f3c:	e9040993          	addi	s3,s0,-368
    80004f40:	f9040c13          	addi	s8,s0,-112
    80004f44:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    80004f46:	ffffc097          	auipc	ra,0xffffc
    80004f4a:	faa080e7          	jalr	-86(ra) # 80000ef0 <strlen>
    80004f4e:	0015079b          	addiw	a5,a0,1
    80004f52:	40f907b3          	sub	a5,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80004f56:	ff07f913          	andi	s2,a5,-16
    if(sp < stackbase)
    80004f5a:	13796863          	bltu	s2,s7,8000508a <exec+0x394>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80004f5e:	e0043d03          	ld	s10,-512(s0)
    80004f62:	000d3a03          	ld	s4,0(s10)
    80004f66:	8552                	mv	a0,s4
    80004f68:	ffffc097          	auipc	ra,0xffffc
    80004f6c:	f88080e7          	jalr	-120(ra) # 80000ef0 <strlen>
    80004f70:	0015069b          	addiw	a3,a0,1
    80004f74:	8652                	mv	a2,s4
    80004f76:	85ca                	mv	a1,s2
    80004f78:	855a                	mv	a0,s6
    80004f7a:	ffffc097          	auipc	ra,0xffffc
    80004f7e:	7ca080e7          	jalr	1994(ra) # 80001744 <copyout>
    80004f82:	10054663          	bltz	a0,8000508e <exec+0x398>
    ustack[argc] = sp;
    80004f86:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80004f8a:	0485                	addi	s1,s1,1
    80004f8c:	008d0793          	addi	a5,s10,8
    80004f90:	e0f43023          	sd	a5,-512(s0)
    80004f94:	008d3503          	ld	a0,8(s10)
    80004f98:	c909                	beqz	a0,80004faa <exec+0x2b4>
    if(argc >= MAXARG)
    80004f9a:	09a1                	addi	s3,s3,8
    80004f9c:	fb8995e3          	bne	s3,s8,80004f46 <exec+0x250>
  ip = 0;
    80004fa0:	4a01                	li	s4,0
    80004fa2:	a8cd                	j	80005094 <exec+0x39e>
  sp = sz;
    80004fa4:	e0843903          	ld	s2,-504(s0)
  for(argc = 0; argv[argc]; argc++) {
    80004fa8:	4481                	li	s1,0
  ustack[argc] = 0;
    80004faa:	00349793          	slli	a5,s1,0x3
    80004fae:	f9078793          	addi	a5,a5,-112 # ffffffffffffef90 <end+0xffffffff7ffda8d0>
    80004fb2:	97a2                	add	a5,a5,s0
    80004fb4:	f007b023          	sd	zero,-256(a5)
  sp -= (argc+1) * sizeof(uint64);
    80004fb8:	00148693          	addi	a3,s1,1
    80004fbc:	068e                	slli	a3,a3,0x3
    80004fbe:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80004fc2:	ff097913          	andi	s2,s2,-16
  sz = sz1;
    80004fc6:	e0843983          	ld	s3,-504(s0)
  if(sp < stackbase)
    80004fca:	f57966e3          	bltu	s2,s7,80004f16 <exec+0x220>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80004fce:	e9040613          	addi	a2,s0,-368
    80004fd2:	85ca                	mv	a1,s2
    80004fd4:	855a                	mv	a0,s6
    80004fd6:	ffffc097          	auipc	ra,0xffffc
    80004fda:	76e080e7          	jalr	1902(ra) # 80001744 <copyout>
    80004fde:	0e054863          	bltz	a0,800050ce <exec+0x3d8>
  p->trapframe->a1 = sp;
    80004fe2:	058ab783          	ld	a5,88(s5) # 1058 <_entry-0x7fffefa8>
    80004fe6:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80004fea:	df843783          	ld	a5,-520(s0)
    80004fee:	0007c703          	lbu	a4,0(a5)
    80004ff2:	cf11                	beqz	a4,8000500e <exec+0x318>
    80004ff4:	0785                	addi	a5,a5,1
    if(*s == '/')
    80004ff6:	02f00693          	li	a3,47
    80004ffa:	a039                	j	80005008 <exec+0x312>
      last = s+1;
    80004ffc:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    80005000:	0785                	addi	a5,a5,1
    80005002:	fff7c703          	lbu	a4,-1(a5)
    80005006:	c701                	beqz	a4,8000500e <exec+0x318>
    if(*s == '/')
    80005008:	fed71ce3          	bne	a4,a3,80005000 <exec+0x30a>
    8000500c:	bfc5                	j	80004ffc <exec+0x306>
  safestrcpy(p->name, last, sizeof(p->name));
    8000500e:	4641                	li	a2,16
    80005010:	df843583          	ld	a1,-520(s0)
    80005014:	158a8513          	addi	a0,s5,344
    80005018:	ffffc097          	auipc	ra,0xffffc
    8000501c:	ea6080e7          	jalr	-346(ra) # 80000ebe <safestrcpy>
  oldpagetable = p->pagetable;
    80005020:	050ab503          	ld	a0,80(s5)
  p->pagetable = pagetable;
    80005024:	056ab823          	sd	s6,80(s5)
  p->sz = sz;
    80005028:	e0843783          	ld	a5,-504(s0)
    8000502c:	04fab423          	sd	a5,72(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80005030:	058ab783          	ld	a5,88(s5)
    80005034:	e6843703          	ld	a4,-408(s0)
    80005038:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    8000503a:	058ab783          	ld	a5,88(s5)
    8000503e:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80005042:	85e6                	mv	a1,s9
    80005044:	ffffd097          	auipc	ra,0xffffd
    80005048:	bc8080e7          	jalr	-1080(ra) # 80001c0c <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    8000504c:	0004851b          	sext.w	a0,s1
    80005050:	79be                	ld	s3,488(sp)
    80005052:	7a1e                	ld	s4,480(sp)
    80005054:	6afe                	ld	s5,472(sp)
    80005056:	6b5e                	ld	s6,464(sp)
    80005058:	6bbe                	ld	s7,456(sp)
    8000505a:	6c1e                	ld	s8,448(sp)
    8000505c:	7cfa                	ld	s9,440(sp)
    8000505e:	7d5a                	ld	s10,432(sp)
    80005060:	b305                	j	80004d80 <exec+0x8a>
    80005062:	e1243423          	sd	s2,-504(s0)
    80005066:	7dba                	ld	s11,424(sp)
    80005068:	a035                	j	80005094 <exec+0x39e>
    8000506a:	e1243423          	sd	s2,-504(s0)
    8000506e:	7dba                	ld	s11,424(sp)
    80005070:	a015                	j	80005094 <exec+0x39e>
    80005072:	e1243423          	sd	s2,-504(s0)
    80005076:	7dba                	ld	s11,424(sp)
    80005078:	a831                	j	80005094 <exec+0x39e>
    8000507a:	e1243423          	sd	s2,-504(s0)
    8000507e:	7dba                	ld	s11,424(sp)
    80005080:	a811                	j	80005094 <exec+0x39e>
    80005082:	e1243423          	sd	s2,-504(s0)
    80005086:	7dba                	ld	s11,424(sp)
    80005088:	a031                	j	80005094 <exec+0x39e>
  ip = 0;
    8000508a:	4a01                	li	s4,0
    8000508c:	a021                	j	80005094 <exec+0x39e>
    8000508e:	4a01                	li	s4,0
  if(pagetable)
    80005090:	a011                	j	80005094 <exec+0x39e>
    80005092:	7dba                	ld	s11,424(sp)
    proc_freepagetable(pagetable, sz);
    80005094:	e0843583          	ld	a1,-504(s0)
    80005098:	855a                	mv	a0,s6
    8000509a:	ffffd097          	auipc	ra,0xffffd
    8000509e:	b72080e7          	jalr	-1166(ra) # 80001c0c <proc_freepagetable>
  return -1;
    800050a2:	557d                	li	a0,-1
  if(ip){
    800050a4:	000a1b63          	bnez	s4,800050ba <exec+0x3c4>
    800050a8:	79be                	ld	s3,488(sp)
    800050aa:	7a1e                	ld	s4,480(sp)
    800050ac:	6afe                	ld	s5,472(sp)
    800050ae:	6b5e                	ld	s6,464(sp)
    800050b0:	6bbe                	ld	s7,456(sp)
    800050b2:	6c1e                	ld	s8,448(sp)
    800050b4:	7cfa                	ld	s9,440(sp)
    800050b6:	7d5a                	ld	s10,432(sp)
    800050b8:	b1e1                	j	80004d80 <exec+0x8a>
    800050ba:	79be                	ld	s3,488(sp)
    800050bc:	6afe                	ld	s5,472(sp)
    800050be:	6b5e                	ld	s6,464(sp)
    800050c0:	6bbe                	ld	s7,456(sp)
    800050c2:	6c1e                	ld	s8,448(sp)
    800050c4:	7cfa                	ld	s9,440(sp)
    800050c6:	7d5a                	ld	s10,432(sp)
    800050c8:	b14d                	j	80004d6a <exec+0x74>
    800050ca:	6b5e                	ld	s6,464(sp)
    800050cc:	b979                	j	80004d6a <exec+0x74>
  sz = sz1;
    800050ce:	e0843983          	ld	s3,-504(s0)
    800050d2:	b591                	j	80004f16 <exec+0x220>

00000000800050d4 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    800050d4:	7179                	addi	sp,sp,-48
    800050d6:	f406                	sd	ra,40(sp)
    800050d8:	f022                	sd	s0,32(sp)
    800050da:	ec26                	sd	s1,24(sp)
    800050dc:	e84a                	sd	s2,16(sp)
    800050de:	1800                	addi	s0,sp,48
    800050e0:	892e                	mv	s2,a1
    800050e2:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  argint(n, &fd);
    800050e4:	fdc40593          	addi	a1,s0,-36
    800050e8:	ffffe097          	auipc	ra,0xffffe
    800050ec:	ae4080e7          	jalr	-1308(ra) # 80002bcc <argint>
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    800050f0:	fdc42703          	lw	a4,-36(s0)
    800050f4:	47bd                	li	a5,15
    800050f6:	02e7eb63          	bltu	a5,a4,8000512c <argfd+0x58>
    800050fa:	ffffd097          	auipc	ra,0xffffd
    800050fe:	9b2080e7          	jalr	-1614(ra) # 80001aac <myproc>
    80005102:	fdc42703          	lw	a4,-36(s0)
    80005106:	01a70793          	addi	a5,a4,26
    8000510a:	078e                	slli	a5,a5,0x3
    8000510c:	953e                	add	a0,a0,a5
    8000510e:	611c                	ld	a5,0(a0)
    80005110:	c385                	beqz	a5,80005130 <argfd+0x5c>
    return -1;
  if(pfd)
    80005112:	00090463          	beqz	s2,8000511a <argfd+0x46>
    *pfd = fd;
    80005116:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    8000511a:	4501                	li	a0,0
  if(pf)
    8000511c:	c091                	beqz	s1,80005120 <argfd+0x4c>
    *pf = f;
    8000511e:	e09c                	sd	a5,0(s1)
}
    80005120:	70a2                	ld	ra,40(sp)
    80005122:	7402                	ld	s0,32(sp)
    80005124:	64e2                	ld	s1,24(sp)
    80005126:	6942                	ld	s2,16(sp)
    80005128:	6145                	addi	sp,sp,48
    8000512a:	8082                	ret
    return -1;
    8000512c:	557d                	li	a0,-1
    8000512e:	bfcd                	j	80005120 <argfd+0x4c>
    80005130:	557d                	li	a0,-1
    80005132:	b7fd                	j	80005120 <argfd+0x4c>

0000000080005134 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80005134:	1101                	addi	sp,sp,-32
    80005136:	ec06                	sd	ra,24(sp)
    80005138:	e822                	sd	s0,16(sp)
    8000513a:	e426                	sd	s1,8(sp)
    8000513c:	1000                	addi	s0,sp,32
    8000513e:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80005140:	ffffd097          	auipc	ra,0xffffd
    80005144:	96c080e7          	jalr	-1684(ra) # 80001aac <myproc>
    80005148:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    8000514a:	0d050793          	addi	a5,a0,208
    8000514e:	4501                	li	a0,0
    80005150:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80005152:	6398                	ld	a4,0(a5)
    80005154:	cb19                	beqz	a4,8000516a <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80005156:	2505                	addiw	a0,a0,1
    80005158:	07a1                	addi	a5,a5,8
    8000515a:	fed51ce3          	bne	a0,a3,80005152 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    8000515e:	557d                	li	a0,-1
}
    80005160:	60e2                	ld	ra,24(sp)
    80005162:	6442                	ld	s0,16(sp)
    80005164:	64a2                	ld	s1,8(sp)
    80005166:	6105                	addi	sp,sp,32
    80005168:	8082                	ret
      p->ofile[fd] = f;
    8000516a:	01a50793          	addi	a5,a0,26
    8000516e:	078e                	slli	a5,a5,0x3
    80005170:	963e                	add	a2,a2,a5
    80005172:	e204                	sd	s1,0(a2)
      return fd;
    80005174:	b7f5                	j	80005160 <fdalloc+0x2c>

0000000080005176 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80005176:	715d                	addi	sp,sp,-80
    80005178:	e486                	sd	ra,72(sp)
    8000517a:	e0a2                	sd	s0,64(sp)
    8000517c:	fc26                	sd	s1,56(sp)
    8000517e:	f84a                	sd	s2,48(sp)
    80005180:	f44e                	sd	s3,40(sp)
    80005182:	ec56                	sd	s5,24(sp)
    80005184:	e85a                	sd	s6,16(sp)
    80005186:	0880                	addi	s0,sp,80
    80005188:	8b2e                	mv	s6,a1
    8000518a:	89b2                	mv	s3,a2
    8000518c:	8936                	mv	s2,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    8000518e:	fb040593          	addi	a1,s0,-80
    80005192:	fffff097          	auipc	ra,0xfffff
    80005196:	de2080e7          	jalr	-542(ra) # 80003f74 <nameiparent>
    8000519a:	84aa                	mv	s1,a0
    8000519c:	14050e63          	beqz	a0,800052f8 <create+0x182>
    return 0;

  ilock(dp);
    800051a0:	ffffe097          	auipc	ra,0xffffe
    800051a4:	5e8080e7          	jalr	1512(ra) # 80003788 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    800051a8:	4601                	li	a2,0
    800051aa:	fb040593          	addi	a1,s0,-80
    800051ae:	8526                	mv	a0,s1
    800051b0:	fffff097          	auipc	ra,0xfffff
    800051b4:	ae4080e7          	jalr	-1308(ra) # 80003c94 <dirlookup>
    800051b8:	8aaa                	mv	s5,a0
    800051ba:	c539                	beqz	a0,80005208 <create+0x92>
    iunlockput(dp);
    800051bc:	8526                	mv	a0,s1
    800051be:	fffff097          	auipc	ra,0xfffff
    800051c2:	830080e7          	jalr	-2000(ra) # 800039ee <iunlockput>
    ilock(ip);
    800051c6:	8556                	mv	a0,s5
    800051c8:	ffffe097          	auipc	ra,0xffffe
    800051cc:	5c0080e7          	jalr	1472(ra) # 80003788 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    800051d0:	4789                	li	a5,2
    800051d2:	02fb1463          	bne	s6,a5,800051fa <create+0x84>
    800051d6:	044ad783          	lhu	a5,68(s5)
    800051da:	37f9                	addiw	a5,a5,-2
    800051dc:	17c2                	slli	a5,a5,0x30
    800051de:	93c1                	srli	a5,a5,0x30
    800051e0:	4705                	li	a4,1
    800051e2:	00f76c63          	bltu	a4,a5,800051fa <create+0x84>
  ip->nlink = 0;
  iupdate(ip);
  iunlockput(ip);
  iunlockput(dp);
  return 0;
}
    800051e6:	8556                	mv	a0,s5
    800051e8:	60a6                	ld	ra,72(sp)
    800051ea:	6406                	ld	s0,64(sp)
    800051ec:	74e2                	ld	s1,56(sp)
    800051ee:	7942                	ld	s2,48(sp)
    800051f0:	79a2                	ld	s3,40(sp)
    800051f2:	6ae2                	ld	s5,24(sp)
    800051f4:	6b42                	ld	s6,16(sp)
    800051f6:	6161                	addi	sp,sp,80
    800051f8:	8082                	ret
    iunlockput(ip);
    800051fa:	8556                	mv	a0,s5
    800051fc:	ffffe097          	auipc	ra,0xffffe
    80005200:	7f2080e7          	jalr	2034(ra) # 800039ee <iunlockput>
    return 0;
    80005204:	4a81                	li	s5,0
    80005206:	b7c5                	j	800051e6 <create+0x70>
    80005208:	f052                	sd	s4,32(sp)
  if((ip = ialloc(dp->dev, type)) == 0){
    8000520a:	85da                	mv	a1,s6
    8000520c:	4088                	lw	a0,0(s1)
    8000520e:	ffffe097          	auipc	ra,0xffffe
    80005212:	3d6080e7          	jalr	982(ra) # 800035e4 <ialloc>
    80005216:	8a2a                	mv	s4,a0
    80005218:	c531                	beqz	a0,80005264 <create+0xee>
  ilock(ip);
    8000521a:	ffffe097          	auipc	ra,0xffffe
    8000521e:	56e080e7          	jalr	1390(ra) # 80003788 <ilock>
  ip->major = major;
    80005222:	053a1323          	sh	s3,70(s4)
  ip->minor = minor;
    80005226:	052a1423          	sh	s2,72(s4)
  ip->nlink = 1;
    8000522a:	4905                	li	s2,1
    8000522c:	052a1523          	sh	s2,74(s4)
  iupdate(ip);
    80005230:	8552                	mv	a0,s4
    80005232:	ffffe097          	auipc	ra,0xffffe
    80005236:	48a080e7          	jalr	1162(ra) # 800036bc <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    8000523a:	032b0d63          	beq	s6,s2,80005274 <create+0xfe>
  if(dirlink(dp, name, ip->inum) < 0)
    8000523e:	004a2603          	lw	a2,4(s4)
    80005242:	fb040593          	addi	a1,s0,-80
    80005246:	8526                	mv	a0,s1
    80005248:	fffff097          	auipc	ra,0xfffff
    8000524c:	c5c080e7          	jalr	-932(ra) # 80003ea4 <dirlink>
    80005250:	08054163          	bltz	a0,800052d2 <create+0x15c>
  iunlockput(dp);
    80005254:	8526                	mv	a0,s1
    80005256:	ffffe097          	auipc	ra,0xffffe
    8000525a:	798080e7          	jalr	1944(ra) # 800039ee <iunlockput>
  return ip;
    8000525e:	8ad2                	mv	s5,s4
    80005260:	7a02                	ld	s4,32(sp)
    80005262:	b751                	j	800051e6 <create+0x70>
    iunlockput(dp);
    80005264:	8526                	mv	a0,s1
    80005266:	ffffe097          	auipc	ra,0xffffe
    8000526a:	788080e7          	jalr	1928(ra) # 800039ee <iunlockput>
    return 0;
    8000526e:	8ad2                	mv	s5,s4
    80005270:	7a02                	ld	s4,32(sp)
    80005272:	bf95                	j	800051e6 <create+0x70>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80005274:	004a2603          	lw	a2,4(s4)
    80005278:	00003597          	auipc	a1,0x3
    8000527c:	38058593          	addi	a1,a1,896 # 800085f8 <etext+0x5f8>
    80005280:	8552                	mv	a0,s4
    80005282:	fffff097          	auipc	ra,0xfffff
    80005286:	c22080e7          	jalr	-990(ra) # 80003ea4 <dirlink>
    8000528a:	04054463          	bltz	a0,800052d2 <create+0x15c>
    8000528e:	40d0                	lw	a2,4(s1)
    80005290:	00003597          	auipc	a1,0x3
    80005294:	37058593          	addi	a1,a1,880 # 80008600 <etext+0x600>
    80005298:	8552                	mv	a0,s4
    8000529a:	fffff097          	auipc	ra,0xfffff
    8000529e:	c0a080e7          	jalr	-1014(ra) # 80003ea4 <dirlink>
    800052a2:	02054863          	bltz	a0,800052d2 <create+0x15c>
  if(dirlink(dp, name, ip->inum) < 0)
    800052a6:	004a2603          	lw	a2,4(s4)
    800052aa:	fb040593          	addi	a1,s0,-80
    800052ae:	8526                	mv	a0,s1
    800052b0:	fffff097          	auipc	ra,0xfffff
    800052b4:	bf4080e7          	jalr	-1036(ra) # 80003ea4 <dirlink>
    800052b8:	00054d63          	bltz	a0,800052d2 <create+0x15c>
    dp->nlink++;  // for ".."
    800052bc:	04a4d783          	lhu	a5,74(s1)
    800052c0:	2785                	addiw	a5,a5,1
    800052c2:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    800052c6:	8526                	mv	a0,s1
    800052c8:	ffffe097          	auipc	ra,0xffffe
    800052cc:	3f4080e7          	jalr	1012(ra) # 800036bc <iupdate>
    800052d0:	b751                	j	80005254 <create+0xde>
  ip->nlink = 0;
    800052d2:	040a1523          	sh	zero,74(s4)
  iupdate(ip);
    800052d6:	8552                	mv	a0,s4
    800052d8:	ffffe097          	auipc	ra,0xffffe
    800052dc:	3e4080e7          	jalr	996(ra) # 800036bc <iupdate>
  iunlockput(ip);
    800052e0:	8552                	mv	a0,s4
    800052e2:	ffffe097          	auipc	ra,0xffffe
    800052e6:	70c080e7          	jalr	1804(ra) # 800039ee <iunlockput>
  iunlockput(dp);
    800052ea:	8526                	mv	a0,s1
    800052ec:	ffffe097          	auipc	ra,0xffffe
    800052f0:	702080e7          	jalr	1794(ra) # 800039ee <iunlockput>
  return 0;
    800052f4:	7a02                	ld	s4,32(sp)
    800052f6:	bdc5                	j	800051e6 <create+0x70>
    return 0;
    800052f8:	8aaa                	mv	s5,a0
    800052fa:	b5f5                	j	800051e6 <create+0x70>

00000000800052fc <sys_dup>:
{
    800052fc:	7179                	addi	sp,sp,-48
    800052fe:	f406                	sd	ra,40(sp)
    80005300:	f022                	sd	s0,32(sp)
    80005302:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    80005304:	fd840613          	addi	a2,s0,-40
    80005308:	4581                	li	a1,0
    8000530a:	4501                	li	a0,0
    8000530c:	00000097          	auipc	ra,0x0
    80005310:	dc8080e7          	jalr	-568(ra) # 800050d4 <argfd>
    return -1;
    80005314:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80005316:	02054763          	bltz	a0,80005344 <sys_dup+0x48>
    8000531a:	ec26                	sd	s1,24(sp)
    8000531c:	e84a                	sd	s2,16(sp)
  if((fd=fdalloc(f)) < 0)
    8000531e:	fd843903          	ld	s2,-40(s0)
    80005322:	854a                	mv	a0,s2
    80005324:	00000097          	auipc	ra,0x0
    80005328:	e10080e7          	jalr	-496(ra) # 80005134 <fdalloc>
    8000532c:	84aa                	mv	s1,a0
    return -1;
    8000532e:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80005330:	00054f63          	bltz	a0,8000534e <sys_dup+0x52>
  filedup(f);
    80005334:	854a                	mv	a0,s2
    80005336:	fffff097          	auipc	ra,0xfffff
    8000533a:	298080e7          	jalr	664(ra) # 800045ce <filedup>
  return fd;
    8000533e:	87a6                	mv	a5,s1
    80005340:	64e2                	ld	s1,24(sp)
    80005342:	6942                	ld	s2,16(sp)
}
    80005344:	853e                	mv	a0,a5
    80005346:	70a2                	ld	ra,40(sp)
    80005348:	7402                	ld	s0,32(sp)
    8000534a:	6145                	addi	sp,sp,48
    8000534c:	8082                	ret
    8000534e:	64e2                	ld	s1,24(sp)
    80005350:	6942                	ld	s2,16(sp)
    80005352:	bfcd                	j	80005344 <sys_dup+0x48>

0000000080005354 <sys_read>:
{
    80005354:	7179                	addi	sp,sp,-48
    80005356:	f406                	sd	ra,40(sp)
    80005358:	f022                	sd	s0,32(sp)
    8000535a:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    8000535c:	fd840593          	addi	a1,s0,-40
    80005360:	4505                	li	a0,1
    80005362:	ffffe097          	auipc	ra,0xffffe
    80005366:	88a080e7          	jalr	-1910(ra) # 80002bec <argaddr>
  argint(2, &n);
    8000536a:	fe440593          	addi	a1,s0,-28
    8000536e:	4509                	li	a0,2
    80005370:	ffffe097          	auipc	ra,0xffffe
    80005374:	85c080e7          	jalr	-1956(ra) # 80002bcc <argint>
  if(argfd(0, 0, &f) < 0)
    80005378:	fe840613          	addi	a2,s0,-24
    8000537c:	4581                	li	a1,0
    8000537e:	4501                	li	a0,0
    80005380:	00000097          	auipc	ra,0x0
    80005384:	d54080e7          	jalr	-684(ra) # 800050d4 <argfd>
    80005388:	87aa                	mv	a5,a0
    return -1;
    8000538a:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    8000538c:	0007cc63          	bltz	a5,800053a4 <sys_read+0x50>
  return fileread(f, p, n);
    80005390:	fe442603          	lw	a2,-28(s0)
    80005394:	fd843583          	ld	a1,-40(s0)
    80005398:	fe843503          	ld	a0,-24(s0)
    8000539c:	fffff097          	auipc	ra,0xfffff
    800053a0:	3d8080e7          	jalr	984(ra) # 80004774 <fileread>
}
    800053a4:	70a2                	ld	ra,40(sp)
    800053a6:	7402                	ld	s0,32(sp)
    800053a8:	6145                	addi	sp,sp,48
    800053aa:	8082                	ret

00000000800053ac <sys_write>:
{
    800053ac:	7179                	addi	sp,sp,-48
    800053ae:	f406                	sd	ra,40(sp)
    800053b0:	f022                	sd	s0,32(sp)
    800053b2:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    800053b4:	fd840593          	addi	a1,s0,-40
    800053b8:	4505                	li	a0,1
    800053ba:	ffffe097          	auipc	ra,0xffffe
    800053be:	832080e7          	jalr	-1998(ra) # 80002bec <argaddr>
  argint(2, &n);
    800053c2:	fe440593          	addi	a1,s0,-28
    800053c6:	4509                	li	a0,2
    800053c8:	ffffe097          	auipc	ra,0xffffe
    800053cc:	804080e7          	jalr	-2044(ra) # 80002bcc <argint>
  if(argfd(0, 0, &f) < 0)
    800053d0:	fe840613          	addi	a2,s0,-24
    800053d4:	4581                	li	a1,0
    800053d6:	4501                	li	a0,0
    800053d8:	00000097          	auipc	ra,0x0
    800053dc:	cfc080e7          	jalr	-772(ra) # 800050d4 <argfd>
    800053e0:	87aa                	mv	a5,a0
    return -1;
    800053e2:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    800053e4:	0007cc63          	bltz	a5,800053fc <sys_write+0x50>
  return filewrite(f, p, n);
    800053e8:	fe442603          	lw	a2,-28(s0)
    800053ec:	fd843583          	ld	a1,-40(s0)
    800053f0:	fe843503          	ld	a0,-24(s0)
    800053f4:	fffff097          	auipc	ra,0xfffff
    800053f8:	452080e7          	jalr	1106(ra) # 80004846 <filewrite>
}
    800053fc:	70a2                	ld	ra,40(sp)
    800053fe:	7402                	ld	s0,32(sp)
    80005400:	6145                	addi	sp,sp,48
    80005402:	8082                	ret

0000000080005404 <sys_close>:
{
    80005404:	1101                	addi	sp,sp,-32
    80005406:	ec06                	sd	ra,24(sp)
    80005408:	e822                	sd	s0,16(sp)
    8000540a:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    8000540c:	fe040613          	addi	a2,s0,-32
    80005410:	fec40593          	addi	a1,s0,-20
    80005414:	4501                	li	a0,0
    80005416:	00000097          	auipc	ra,0x0
    8000541a:	cbe080e7          	jalr	-834(ra) # 800050d4 <argfd>
    return -1;
    8000541e:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005420:	02054463          	bltz	a0,80005448 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    80005424:	ffffc097          	auipc	ra,0xffffc
    80005428:	688080e7          	jalr	1672(ra) # 80001aac <myproc>
    8000542c:	fec42783          	lw	a5,-20(s0)
    80005430:	07e9                	addi	a5,a5,26
    80005432:	078e                	slli	a5,a5,0x3
    80005434:	953e                	add	a0,a0,a5
    80005436:	00053023          	sd	zero,0(a0)
  fileclose(f);
    8000543a:	fe043503          	ld	a0,-32(s0)
    8000543e:	fffff097          	auipc	ra,0xfffff
    80005442:	1e2080e7          	jalr	482(ra) # 80004620 <fileclose>
  return 0;
    80005446:	4781                	li	a5,0
}
    80005448:	853e                	mv	a0,a5
    8000544a:	60e2                	ld	ra,24(sp)
    8000544c:	6442                	ld	s0,16(sp)
    8000544e:	6105                	addi	sp,sp,32
    80005450:	8082                	ret

0000000080005452 <sys_fstat>:
{
    80005452:	1101                	addi	sp,sp,-32
    80005454:	ec06                	sd	ra,24(sp)
    80005456:	e822                	sd	s0,16(sp)
    80005458:	1000                	addi	s0,sp,32
  argaddr(1, &st);
    8000545a:	fe040593          	addi	a1,s0,-32
    8000545e:	4505                	li	a0,1
    80005460:	ffffd097          	auipc	ra,0xffffd
    80005464:	78c080e7          	jalr	1932(ra) # 80002bec <argaddr>
  if(argfd(0, 0, &f) < 0)
    80005468:	fe840613          	addi	a2,s0,-24
    8000546c:	4581                	li	a1,0
    8000546e:	4501                	li	a0,0
    80005470:	00000097          	auipc	ra,0x0
    80005474:	c64080e7          	jalr	-924(ra) # 800050d4 <argfd>
    80005478:	87aa                	mv	a5,a0
    return -1;
    8000547a:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    8000547c:	0007ca63          	bltz	a5,80005490 <sys_fstat+0x3e>
  return filestat(f, st);
    80005480:	fe043583          	ld	a1,-32(s0)
    80005484:	fe843503          	ld	a0,-24(s0)
    80005488:	fffff097          	auipc	ra,0xfffff
    8000548c:	27a080e7          	jalr	634(ra) # 80004702 <filestat>
}
    80005490:	60e2                	ld	ra,24(sp)
    80005492:	6442                	ld	s0,16(sp)
    80005494:	6105                	addi	sp,sp,32
    80005496:	8082                	ret

0000000080005498 <sys_link>:
{
    80005498:	7169                	addi	sp,sp,-304
    8000549a:	f606                	sd	ra,296(sp)
    8000549c:	f222                	sd	s0,288(sp)
    8000549e:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800054a0:	08000613          	li	a2,128
    800054a4:	ed040593          	addi	a1,s0,-304
    800054a8:	4501                	li	a0,0
    800054aa:	ffffd097          	auipc	ra,0xffffd
    800054ae:	762080e7          	jalr	1890(ra) # 80002c0c <argstr>
    return -1;
    800054b2:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800054b4:	12054663          	bltz	a0,800055e0 <sys_link+0x148>
    800054b8:	08000613          	li	a2,128
    800054bc:	f5040593          	addi	a1,s0,-176
    800054c0:	4505                	li	a0,1
    800054c2:	ffffd097          	auipc	ra,0xffffd
    800054c6:	74a080e7          	jalr	1866(ra) # 80002c0c <argstr>
    return -1;
    800054ca:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800054cc:	10054a63          	bltz	a0,800055e0 <sys_link+0x148>
    800054d0:	ee26                	sd	s1,280(sp)
  begin_op();
    800054d2:	fffff097          	auipc	ra,0xfffff
    800054d6:	c84080e7          	jalr	-892(ra) # 80004156 <begin_op>
  if((ip = namei(old)) == 0){
    800054da:	ed040513          	addi	a0,s0,-304
    800054de:	fffff097          	auipc	ra,0xfffff
    800054e2:	a78080e7          	jalr	-1416(ra) # 80003f56 <namei>
    800054e6:	84aa                	mv	s1,a0
    800054e8:	c949                	beqz	a0,8000557a <sys_link+0xe2>
  ilock(ip);
    800054ea:	ffffe097          	auipc	ra,0xffffe
    800054ee:	29e080e7          	jalr	670(ra) # 80003788 <ilock>
  if(ip->type == T_DIR){
    800054f2:	04449703          	lh	a4,68(s1)
    800054f6:	4785                	li	a5,1
    800054f8:	08f70863          	beq	a4,a5,80005588 <sys_link+0xf0>
    800054fc:	ea4a                	sd	s2,272(sp)
  ip->nlink++;
    800054fe:	04a4d783          	lhu	a5,74(s1)
    80005502:	2785                	addiw	a5,a5,1
    80005504:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005508:	8526                	mv	a0,s1
    8000550a:	ffffe097          	auipc	ra,0xffffe
    8000550e:	1b2080e7          	jalr	434(ra) # 800036bc <iupdate>
  iunlock(ip);
    80005512:	8526                	mv	a0,s1
    80005514:	ffffe097          	auipc	ra,0xffffe
    80005518:	33a080e7          	jalr	826(ra) # 8000384e <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    8000551c:	fd040593          	addi	a1,s0,-48
    80005520:	f5040513          	addi	a0,s0,-176
    80005524:	fffff097          	auipc	ra,0xfffff
    80005528:	a50080e7          	jalr	-1456(ra) # 80003f74 <nameiparent>
    8000552c:	892a                	mv	s2,a0
    8000552e:	cd35                	beqz	a0,800055aa <sys_link+0x112>
  ilock(dp);
    80005530:	ffffe097          	auipc	ra,0xffffe
    80005534:	258080e7          	jalr	600(ra) # 80003788 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005538:	00092703          	lw	a4,0(s2)
    8000553c:	409c                	lw	a5,0(s1)
    8000553e:	06f71163          	bne	a4,a5,800055a0 <sys_link+0x108>
    80005542:	40d0                	lw	a2,4(s1)
    80005544:	fd040593          	addi	a1,s0,-48
    80005548:	854a                	mv	a0,s2
    8000554a:	fffff097          	auipc	ra,0xfffff
    8000554e:	95a080e7          	jalr	-1702(ra) # 80003ea4 <dirlink>
    80005552:	04054763          	bltz	a0,800055a0 <sys_link+0x108>
  iunlockput(dp);
    80005556:	854a                	mv	a0,s2
    80005558:	ffffe097          	auipc	ra,0xffffe
    8000555c:	496080e7          	jalr	1174(ra) # 800039ee <iunlockput>
  iput(ip);
    80005560:	8526                	mv	a0,s1
    80005562:	ffffe097          	auipc	ra,0xffffe
    80005566:	3e4080e7          	jalr	996(ra) # 80003946 <iput>
  end_op();
    8000556a:	fffff097          	auipc	ra,0xfffff
    8000556e:	c66080e7          	jalr	-922(ra) # 800041d0 <end_op>
  return 0;
    80005572:	4781                	li	a5,0
    80005574:	64f2                	ld	s1,280(sp)
    80005576:	6952                	ld	s2,272(sp)
    80005578:	a0a5                	j	800055e0 <sys_link+0x148>
    end_op();
    8000557a:	fffff097          	auipc	ra,0xfffff
    8000557e:	c56080e7          	jalr	-938(ra) # 800041d0 <end_op>
    return -1;
    80005582:	57fd                	li	a5,-1
    80005584:	64f2                	ld	s1,280(sp)
    80005586:	a8a9                	j	800055e0 <sys_link+0x148>
    iunlockput(ip);
    80005588:	8526                	mv	a0,s1
    8000558a:	ffffe097          	auipc	ra,0xffffe
    8000558e:	464080e7          	jalr	1124(ra) # 800039ee <iunlockput>
    end_op();
    80005592:	fffff097          	auipc	ra,0xfffff
    80005596:	c3e080e7          	jalr	-962(ra) # 800041d0 <end_op>
    return -1;
    8000559a:	57fd                	li	a5,-1
    8000559c:	64f2                	ld	s1,280(sp)
    8000559e:	a089                	j	800055e0 <sys_link+0x148>
    iunlockput(dp);
    800055a0:	854a                	mv	a0,s2
    800055a2:	ffffe097          	auipc	ra,0xffffe
    800055a6:	44c080e7          	jalr	1100(ra) # 800039ee <iunlockput>
  ilock(ip);
    800055aa:	8526                	mv	a0,s1
    800055ac:	ffffe097          	auipc	ra,0xffffe
    800055b0:	1dc080e7          	jalr	476(ra) # 80003788 <ilock>
  ip->nlink--;
    800055b4:	04a4d783          	lhu	a5,74(s1)
    800055b8:	37fd                	addiw	a5,a5,-1
    800055ba:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800055be:	8526                	mv	a0,s1
    800055c0:	ffffe097          	auipc	ra,0xffffe
    800055c4:	0fc080e7          	jalr	252(ra) # 800036bc <iupdate>
  iunlockput(ip);
    800055c8:	8526                	mv	a0,s1
    800055ca:	ffffe097          	auipc	ra,0xffffe
    800055ce:	424080e7          	jalr	1060(ra) # 800039ee <iunlockput>
  end_op();
    800055d2:	fffff097          	auipc	ra,0xfffff
    800055d6:	bfe080e7          	jalr	-1026(ra) # 800041d0 <end_op>
  return -1;
    800055da:	57fd                	li	a5,-1
    800055dc:	64f2                	ld	s1,280(sp)
    800055de:	6952                	ld	s2,272(sp)
}
    800055e0:	853e                	mv	a0,a5
    800055e2:	70b2                	ld	ra,296(sp)
    800055e4:	7412                	ld	s0,288(sp)
    800055e6:	6155                	addi	sp,sp,304
    800055e8:	8082                	ret

00000000800055ea <sys_unlink>:
{
    800055ea:	7151                	addi	sp,sp,-240
    800055ec:	f586                	sd	ra,232(sp)
    800055ee:	f1a2                	sd	s0,224(sp)
    800055f0:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    800055f2:	08000613          	li	a2,128
    800055f6:	f3040593          	addi	a1,s0,-208
    800055fa:	4501                	li	a0,0
    800055fc:	ffffd097          	auipc	ra,0xffffd
    80005600:	610080e7          	jalr	1552(ra) # 80002c0c <argstr>
    80005604:	1a054a63          	bltz	a0,800057b8 <sys_unlink+0x1ce>
    80005608:	eda6                	sd	s1,216(sp)
  begin_op();
    8000560a:	fffff097          	auipc	ra,0xfffff
    8000560e:	b4c080e7          	jalr	-1204(ra) # 80004156 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005612:	fb040593          	addi	a1,s0,-80
    80005616:	f3040513          	addi	a0,s0,-208
    8000561a:	fffff097          	auipc	ra,0xfffff
    8000561e:	95a080e7          	jalr	-1702(ra) # 80003f74 <nameiparent>
    80005622:	84aa                	mv	s1,a0
    80005624:	cd71                	beqz	a0,80005700 <sys_unlink+0x116>
  ilock(dp);
    80005626:	ffffe097          	auipc	ra,0xffffe
    8000562a:	162080e7          	jalr	354(ra) # 80003788 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    8000562e:	00003597          	auipc	a1,0x3
    80005632:	fca58593          	addi	a1,a1,-54 # 800085f8 <etext+0x5f8>
    80005636:	fb040513          	addi	a0,s0,-80
    8000563a:	ffffe097          	auipc	ra,0xffffe
    8000563e:	640080e7          	jalr	1600(ra) # 80003c7a <namecmp>
    80005642:	14050c63          	beqz	a0,8000579a <sys_unlink+0x1b0>
    80005646:	00003597          	auipc	a1,0x3
    8000564a:	fba58593          	addi	a1,a1,-70 # 80008600 <etext+0x600>
    8000564e:	fb040513          	addi	a0,s0,-80
    80005652:	ffffe097          	auipc	ra,0xffffe
    80005656:	628080e7          	jalr	1576(ra) # 80003c7a <namecmp>
    8000565a:	14050063          	beqz	a0,8000579a <sys_unlink+0x1b0>
    8000565e:	e9ca                	sd	s2,208(sp)
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005660:	f2c40613          	addi	a2,s0,-212
    80005664:	fb040593          	addi	a1,s0,-80
    80005668:	8526                	mv	a0,s1
    8000566a:	ffffe097          	auipc	ra,0xffffe
    8000566e:	62a080e7          	jalr	1578(ra) # 80003c94 <dirlookup>
    80005672:	892a                	mv	s2,a0
    80005674:	12050263          	beqz	a0,80005798 <sys_unlink+0x1ae>
  ilock(ip);
    80005678:	ffffe097          	auipc	ra,0xffffe
    8000567c:	110080e7          	jalr	272(ra) # 80003788 <ilock>
  if(ip->nlink < 1)
    80005680:	04a91783          	lh	a5,74(s2)
    80005684:	08f05563          	blez	a5,8000570e <sys_unlink+0x124>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005688:	04491703          	lh	a4,68(s2)
    8000568c:	4785                	li	a5,1
    8000568e:	08f70963          	beq	a4,a5,80005720 <sys_unlink+0x136>
  memset(&de, 0, sizeof(de));
    80005692:	4641                	li	a2,16
    80005694:	4581                	li	a1,0
    80005696:	fc040513          	addi	a0,s0,-64
    8000569a:	ffffb097          	auipc	ra,0xffffb
    8000569e:	6e2080e7          	jalr	1762(ra) # 80000d7c <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800056a2:	4741                	li	a4,16
    800056a4:	f2c42683          	lw	a3,-212(s0)
    800056a8:	fc040613          	addi	a2,s0,-64
    800056ac:	4581                	li	a1,0
    800056ae:	8526                	mv	a0,s1
    800056b0:	ffffe097          	auipc	ra,0xffffe
    800056b4:	4a0080e7          	jalr	1184(ra) # 80003b50 <writei>
    800056b8:	47c1                	li	a5,16
    800056ba:	0af51b63          	bne	a0,a5,80005770 <sys_unlink+0x186>
  if(ip->type == T_DIR){
    800056be:	04491703          	lh	a4,68(s2)
    800056c2:	4785                	li	a5,1
    800056c4:	0af70f63          	beq	a4,a5,80005782 <sys_unlink+0x198>
  iunlockput(dp);
    800056c8:	8526                	mv	a0,s1
    800056ca:	ffffe097          	auipc	ra,0xffffe
    800056ce:	324080e7          	jalr	804(ra) # 800039ee <iunlockput>
  ip->nlink--;
    800056d2:	04a95783          	lhu	a5,74(s2)
    800056d6:	37fd                	addiw	a5,a5,-1
    800056d8:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    800056dc:	854a                	mv	a0,s2
    800056de:	ffffe097          	auipc	ra,0xffffe
    800056e2:	fde080e7          	jalr	-34(ra) # 800036bc <iupdate>
  iunlockput(ip);
    800056e6:	854a                	mv	a0,s2
    800056e8:	ffffe097          	auipc	ra,0xffffe
    800056ec:	306080e7          	jalr	774(ra) # 800039ee <iunlockput>
  end_op();
    800056f0:	fffff097          	auipc	ra,0xfffff
    800056f4:	ae0080e7          	jalr	-1312(ra) # 800041d0 <end_op>
  return 0;
    800056f8:	4501                	li	a0,0
    800056fa:	64ee                	ld	s1,216(sp)
    800056fc:	694e                	ld	s2,208(sp)
    800056fe:	a84d                	j	800057b0 <sys_unlink+0x1c6>
    end_op();
    80005700:	fffff097          	auipc	ra,0xfffff
    80005704:	ad0080e7          	jalr	-1328(ra) # 800041d0 <end_op>
    return -1;
    80005708:	557d                	li	a0,-1
    8000570a:	64ee                	ld	s1,216(sp)
    8000570c:	a055                	j	800057b0 <sys_unlink+0x1c6>
    8000570e:	e5ce                	sd	s3,200(sp)
    panic("unlink: nlink < 1");
    80005710:	00003517          	auipc	a0,0x3
    80005714:	ef850513          	addi	a0,a0,-264 # 80008608 <etext+0x608>
    80005718:	ffffb097          	auipc	ra,0xffffb
    8000571c:	e48080e7          	jalr	-440(ra) # 80000560 <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005720:	04c92703          	lw	a4,76(s2)
    80005724:	02000793          	li	a5,32
    80005728:	f6e7f5e3          	bgeu	a5,a4,80005692 <sys_unlink+0xa8>
    8000572c:	e5ce                	sd	s3,200(sp)
    8000572e:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005732:	4741                	li	a4,16
    80005734:	86ce                	mv	a3,s3
    80005736:	f1840613          	addi	a2,s0,-232
    8000573a:	4581                	li	a1,0
    8000573c:	854a                	mv	a0,s2
    8000573e:	ffffe097          	auipc	ra,0xffffe
    80005742:	302080e7          	jalr	770(ra) # 80003a40 <readi>
    80005746:	47c1                	li	a5,16
    80005748:	00f51c63          	bne	a0,a5,80005760 <sys_unlink+0x176>
    if(de.inum != 0)
    8000574c:	f1845783          	lhu	a5,-232(s0)
    80005750:	e7b5                	bnez	a5,800057bc <sys_unlink+0x1d2>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005752:	29c1                	addiw	s3,s3,16
    80005754:	04c92783          	lw	a5,76(s2)
    80005758:	fcf9ede3          	bltu	s3,a5,80005732 <sys_unlink+0x148>
    8000575c:	69ae                	ld	s3,200(sp)
    8000575e:	bf15                	j	80005692 <sys_unlink+0xa8>
      panic("isdirempty: readi");
    80005760:	00003517          	auipc	a0,0x3
    80005764:	ec050513          	addi	a0,a0,-320 # 80008620 <etext+0x620>
    80005768:	ffffb097          	auipc	ra,0xffffb
    8000576c:	df8080e7          	jalr	-520(ra) # 80000560 <panic>
    80005770:	e5ce                	sd	s3,200(sp)
    panic("unlink: writei");
    80005772:	00003517          	auipc	a0,0x3
    80005776:	ec650513          	addi	a0,a0,-314 # 80008638 <etext+0x638>
    8000577a:	ffffb097          	auipc	ra,0xffffb
    8000577e:	de6080e7          	jalr	-538(ra) # 80000560 <panic>
    dp->nlink--;
    80005782:	04a4d783          	lhu	a5,74(s1)
    80005786:	37fd                	addiw	a5,a5,-1
    80005788:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    8000578c:	8526                	mv	a0,s1
    8000578e:	ffffe097          	auipc	ra,0xffffe
    80005792:	f2e080e7          	jalr	-210(ra) # 800036bc <iupdate>
    80005796:	bf0d                	j	800056c8 <sys_unlink+0xde>
    80005798:	694e                	ld	s2,208(sp)
  iunlockput(dp);
    8000579a:	8526                	mv	a0,s1
    8000579c:	ffffe097          	auipc	ra,0xffffe
    800057a0:	252080e7          	jalr	594(ra) # 800039ee <iunlockput>
  end_op();
    800057a4:	fffff097          	auipc	ra,0xfffff
    800057a8:	a2c080e7          	jalr	-1492(ra) # 800041d0 <end_op>
  return -1;
    800057ac:	557d                	li	a0,-1
    800057ae:	64ee                	ld	s1,216(sp)
}
    800057b0:	70ae                	ld	ra,232(sp)
    800057b2:	740e                	ld	s0,224(sp)
    800057b4:	616d                	addi	sp,sp,240
    800057b6:	8082                	ret
    return -1;
    800057b8:	557d                	li	a0,-1
    800057ba:	bfdd                	j	800057b0 <sys_unlink+0x1c6>
    iunlockput(ip);
    800057bc:	854a                	mv	a0,s2
    800057be:	ffffe097          	auipc	ra,0xffffe
    800057c2:	230080e7          	jalr	560(ra) # 800039ee <iunlockput>
    goto bad;
    800057c6:	694e                	ld	s2,208(sp)
    800057c8:	69ae                	ld	s3,200(sp)
    800057ca:	bfc1                	j	8000579a <sys_unlink+0x1b0>

00000000800057cc <sys_open>:

uint64
sys_open(void)
{
    800057cc:	7131                	addi	sp,sp,-192
    800057ce:	fd06                	sd	ra,184(sp)
    800057d0:	f922                	sd	s0,176(sp)
    800057d2:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  argint(1, &omode);
    800057d4:	f4c40593          	addi	a1,s0,-180
    800057d8:	4505                	li	a0,1
    800057da:	ffffd097          	auipc	ra,0xffffd
    800057de:	3f2080e7          	jalr	1010(ra) # 80002bcc <argint>
  if((n = argstr(0, path, MAXPATH)) < 0)
    800057e2:	08000613          	li	a2,128
    800057e6:	f5040593          	addi	a1,s0,-176
    800057ea:	4501                	li	a0,0
    800057ec:	ffffd097          	auipc	ra,0xffffd
    800057f0:	420080e7          	jalr	1056(ra) # 80002c0c <argstr>
    800057f4:	87aa                	mv	a5,a0
    return -1;
    800057f6:	557d                	li	a0,-1
  if((n = argstr(0, path, MAXPATH)) < 0)
    800057f8:	0a07ce63          	bltz	a5,800058b4 <sys_open+0xe8>
    800057fc:	f526                	sd	s1,168(sp)

  begin_op();
    800057fe:	fffff097          	auipc	ra,0xfffff
    80005802:	958080e7          	jalr	-1704(ra) # 80004156 <begin_op>

  if(omode & O_CREATE){
    80005806:	f4c42783          	lw	a5,-180(s0)
    8000580a:	2007f793          	andi	a5,a5,512
    8000580e:	cfd5                	beqz	a5,800058ca <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005810:	4681                	li	a3,0
    80005812:	4601                	li	a2,0
    80005814:	4589                	li	a1,2
    80005816:	f5040513          	addi	a0,s0,-176
    8000581a:	00000097          	auipc	ra,0x0
    8000581e:	95c080e7          	jalr	-1700(ra) # 80005176 <create>
    80005822:	84aa                	mv	s1,a0
    if(ip == 0){
    80005824:	cd41                	beqz	a0,800058bc <sys_open+0xf0>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005826:	04449703          	lh	a4,68(s1)
    8000582a:	478d                	li	a5,3
    8000582c:	00f71763          	bne	a4,a5,8000583a <sys_open+0x6e>
    80005830:	0464d703          	lhu	a4,70(s1)
    80005834:	47a5                	li	a5,9
    80005836:	0ee7e163          	bltu	a5,a4,80005918 <sys_open+0x14c>
    8000583a:	f14a                	sd	s2,160(sp)
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    8000583c:	fffff097          	auipc	ra,0xfffff
    80005840:	d28080e7          	jalr	-728(ra) # 80004564 <filealloc>
    80005844:	892a                	mv	s2,a0
    80005846:	c97d                	beqz	a0,8000593c <sys_open+0x170>
    80005848:	ed4e                	sd	s3,152(sp)
    8000584a:	00000097          	auipc	ra,0x0
    8000584e:	8ea080e7          	jalr	-1814(ra) # 80005134 <fdalloc>
    80005852:	89aa                	mv	s3,a0
    80005854:	0c054e63          	bltz	a0,80005930 <sys_open+0x164>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005858:	04449703          	lh	a4,68(s1)
    8000585c:	478d                	li	a5,3
    8000585e:	0ef70c63          	beq	a4,a5,80005956 <sys_open+0x18a>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005862:	4789                	li	a5,2
    80005864:	00f92023          	sw	a5,0(s2)
    f->off = 0;
    80005868:	02092023          	sw	zero,32(s2)
  }
  f->ip = ip;
    8000586c:	00993c23          	sd	s1,24(s2)
  f->readable = !(omode & O_WRONLY);
    80005870:	f4c42783          	lw	a5,-180(s0)
    80005874:	0017c713          	xori	a4,a5,1
    80005878:	8b05                	andi	a4,a4,1
    8000587a:	00e90423          	sb	a4,8(s2)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    8000587e:	0037f713          	andi	a4,a5,3
    80005882:	00e03733          	snez	a4,a4
    80005886:	00e904a3          	sb	a4,9(s2)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    8000588a:	4007f793          	andi	a5,a5,1024
    8000588e:	c791                	beqz	a5,8000589a <sys_open+0xce>
    80005890:	04449703          	lh	a4,68(s1)
    80005894:	4789                	li	a5,2
    80005896:	0cf70763          	beq	a4,a5,80005964 <sys_open+0x198>
    itrunc(ip);
  }

  iunlock(ip);
    8000589a:	8526                	mv	a0,s1
    8000589c:	ffffe097          	auipc	ra,0xffffe
    800058a0:	fb2080e7          	jalr	-78(ra) # 8000384e <iunlock>
  end_op();
    800058a4:	fffff097          	auipc	ra,0xfffff
    800058a8:	92c080e7          	jalr	-1748(ra) # 800041d0 <end_op>

  return fd;
    800058ac:	854e                	mv	a0,s3
    800058ae:	74aa                	ld	s1,168(sp)
    800058b0:	790a                	ld	s2,160(sp)
    800058b2:	69ea                	ld	s3,152(sp)
}
    800058b4:	70ea                	ld	ra,184(sp)
    800058b6:	744a                	ld	s0,176(sp)
    800058b8:	6129                	addi	sp,sp,192
    800058ba:	8082                	ret
      end_op();
    800058bc:	fffff097          	auipc	ra,0xfffff
    800058c0:	914080e7          	jalr	-1772(ra) # 800041d0 <end_op>
      return -1;
    800058c4:	557d                	li	a0,-1
    800058c6:	74aa                	ld	s1,168(sp)
    800058c8:	b7f5                	j	800058b4 <sys_open+0xe8>
    if((ip = namei(path)) == 0){
    800058ca:	f5040513          	addi	a0,s0,-176
    800058ce:	ffffe097          	auipc	ra,0xffffe
    800058d2:	688080e7          	jalr	1672(ra) # 80003f56 <namei>
    800058d6:	84aa                	mv	s1,a0
    800058d8:	c90d                	beqz	a0,8000590a <sys_open+0x13e>
    ilock(ip);
    800058da:	ffffe097          	auipc	ra,0xffffe
    800058de:	eae080e7          	jalr	-338(ra) # 80003788 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    800058e2:	04449703          	lh	a4,68(s1)
    800058e6:	4785                	li	a5,1
    800058e8:	f2f71fe3          	bne	a4,a5,80005826 <sys_open+0x5a>
    800058ec:	f4c42783          	lw	a5,-180(s0)
    800058f0:	d7a9                	beqz	a5,8000583a <sys_open+0x6e>
      iunlockput(ip);
    800058f2:	8526                	mv	a0,s1
    800058f4:	ffffe097          	auipc	ra,0xffffe
    800058f8:	0fa080e7          	jalr	250(ra) # 800039ee <iunlockput>
      end_op();
    800058fc:	fffff097          	auipc	ra,0xfffff
    80005900:	8d4080e7          	jalr	-1836(ra) # 800041d0 <end_op>
      return -1;
    80005904:	557d                	li	a0,-1
    80005906:	74aa                	ld	s1,168(sp)
    80005908:	b775                	j	800058b4 <sys_open+0xe8>
      end_op();
    8000590a:	fffff097          	auipc	ra,0xfffff
    8000590e:	8c6080e7          	jalr	-1850(ra) # 800041d0 <end_op>
      return -1;
    80005912:	557d                	li	a0,-1
    80005914:	74aa                	ld	s1,168(sp)
    80005916:	bf79                	j	800058b4 <sys_open+0xe8>
    iunlockput(ip);
    80005918:	8526                	mv	a0,s1
    8000591a:	ffffe097          	auipc	ra,0xffffe
    8000591e:	0d4080e7          	jalr	212(ra) # 800039ee <iunlockput>
    end_op();
    80005922:	fffff097          	auipc	ra,0xfffff
    80005926:	8ae080e7          	jalr	-1874(ra) # 800041d0 <end_op>
    return -1;
    8000592a:	557d                	li	a0,-1
    8000592c:	74aa                	ld	s1,168(sp)
    8000592e:	b759                	j	800058b4 <sys_open+0xe8>
      fileclose(f);
    80005930:	854a                	mv	a0,s2
    80005932:	fffff097          	auipc	ra,0xfffff
    80005936:	cee080e7          	jalr	-786(ra) # 80004620 <fileclose>
    8000593a:	69ea                	ld	s3,152(sp)
    iunlockput(ip);
    8000593c:	8526                	mv	a0,s1
    8000593e:	ffffe097          	auipc	ra,0xffffe
    80005942:	0b0080e7          	jalr	176(ra) # 800039ee <iunlockput>
    end_op();
    80005946:	fffff097          	auipc	ra,0xfffff
    8000594a:	88a080e7          	jalr	-1910(ra) # 800041d0 <end_op>
    return -1;
    8000594e:	557d                	li	a0,-1
    80005950:	74aa                	ld	s1,168(sp)
    80005952:	790a                	ld	s2,160(sp)
    80005954:	b785                	j	800058b4 <sys_open+0xe8>
    f->type = FD_DEVICE;
    80005956:	00f92023          	sw	a5,0(s2)
    f->major = ip->major;
    8000595a:	04649783          	lh	a5,70(s1)
    8000595e:	02f91223          	sh	a5,36(s2)
    80005962:	b729                	j	8000586c <sys_open+0xa0>
    itrunc(ip);
    80005964:	8526                	mv	a0,s1
    80005966:	ffffe097          	auipc	ra,0xffffe
    8000596a:	f34080e7          	jalr	-204(ra) # 8000389a <itrunc>
    8000596e:	b735                	j	8000589a <sys_open+0xce>

0000000080005970 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005970:	7175                	addi	sp,sp,-144
    80005972:	e506                	sd	ra,136(sp)
    80005974:	e122                	sd	s0,128(sp)
    80005976:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005978:	ffffe097          	auipc	ra,0xffffe
    8000597c:	7de080e7          	jalr	2014(ra) # 80004156 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005980:	08000613          	li	a2,128
    80005984:	f7040593          	addi	a1,s0,-144
    80005988:	4501                	li	a0,0
    8000598a:	ffffd097          	auipc	ra,0xffffd
    8000598e:	282080e7          	jalr	642(ra) # 80002c0c <argstr>
    80005992:	02054963          	bltz	a0,800059c4 <sys_mkdir+0x54>
    80005996:	4681                	li	a3,0
    80005998:	4601                	li	a2,0
    8000599a:	4585                	li	a1,1
    8000599c:	f7040513          	addi	a0,s0,-144
    800059a0:	fffff097          	auipc	ra,0xfffff
    800059a4:	7d6080e7          	jalr	2006(ra) # 80005176 <create>
    800059a8:	cd11                	beqz	a0,800059c4 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    800059aa:	ffffe097          	auipc	ra,0xffffe
    800059ae:	044080e7          	jalr	68(ra) # 800039ee <iunlockput>
  end_op();
    800059b2:	fffff097          	auipc	ra,0xfffff
    800059b6:	81e080e7          	jalr	-2018(ra) # 800041d0 <end_op>
  return 0;
    800059ba:	4501                	li	a0,0
}
    800059bc:	60aa                	ld	ra,136(sp)
    800059be:	640a                	ld	s0,128(sp)
    800059c0:	6149                	addi	sp,sp,144
    800059c2:	8082                	ret
    end_op();
    800059c4:	fffff097          	auipc	ra,0xfffff
    800059c8:	80c080e7          	jalr	-2036(ra) # 800041d0 <end_op>
    return -1;
    800059cc:	557d                	li	a0,-1
    800059ce:	b7fd                	j	800059bc <sys_mkdir+0x4c>

00000000800059d0 <sys_mknod>:

uint64
sys_mknod(void)
{
    800059d0:	7135                	addi	sp,sp,-160
    800059d2:	ed06                	sd	ra,152(sp)
    800059d4:	e922                	sd	s0,144(sp)
    800059d6:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    800059d8:	ffffe097          	auipc	ra,0xffffe
    800059dc:	77e080e7          	jalr	1918(ra) # 80004156 <begin_op>
  argint(1, &major);
    800059e0:	f6c40593          	addi	a1,s0,-148
    800059e4:	4505                	li	a0,1
    800059e6:	ffffd097          	auipc	ra,0xffffd
    800059ea:	1e6080e7          	jalr	486(ra) # 80002bcc <argint>
  argint(2, &minor);
    800059ee:	f6840593          	addi	a1,s0,-152
    800059f2:	4509                	li	a0,2
    800059f4:	ffffd097          	auipc	ra,0xffffd
    800059f8:	1d8080e7          	jalr	472(ra) # 80002bcc <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    800059fc:	08000613          	li	a2,128
    80005a00:	f7040593          	addi	a1,s0,-144
    80005a04:	4501                	li	a0,0
    80005a06:	ffffd097          	auipc	ra,0xffffd
    80005a0a:	206080e7          	jalr	518(ra) # 80002c0c <argstr>
    80005a0e:	02054b63          	bltz	a0,80005a44 <sys_mknod+0x74>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005a12:	f6841683          	lh	a3,-152(s0)
    80005a16:	f6c41603          	lh	a2,-148(s0)
    80005a1a:	458d                	li	a1,3
    80005a1c:	f7040513          	addi	a0,s0,-144
    80005a20:	fffff097          	auipc	ra,0xfffff
    80005a24:	756080e7          	jalr	1878(ra) # 80005176 <create>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005a28:	cd11                	beqz	a0,80005a44 <sys_mknod+0x74>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005a2a:	ffffe097          	auipc	ra,0xffffe
    80005a2e:	fc4080e7          	jalr	-60(ra) # 800039ee <iunlockput>
  end_op();
    80005a32:	ffffe097          	auipc	ra,0xffffe
    80005a36:	79e080e7          	jalr	1950(ra) # 800041d0 <end_op>
  return 0;
    80005a3a:	4501                	li	a0,0
}
    80005a3c:	60ea                	ld	ra,152(sp)
    80005a3e:	644a                	ld	s0,144(sp)
    80005a40:	610d                	addi	sp,sp,160
    80005a42:	8082                	ret
    end_op();
    80005a44:	ffffe097          	auipc	ra,0xffffe
    80005a48:	78c080e7          	jalr	1932(ra) # 800041d0 <end_op>
    return -1;
    80005a4c:	557d                	li	a0,-1
    80005a4e:	b7fd                	j	80005a3c <sys_mknod+0x6c>

0000000080005a50 <sys_chdir>:

uint64
sys_chdir(void)
{
    80005a50:	7135                	addi	sp,sp,-160
    80005a52:	ed06                	sd	ra,152(sp)
    80005a54:	e922                	sd	s0,144(sp)
    80005a56:	e14a                	sd	s2,128(sp)
    80005a58:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005a5a:	ffffc097          	auipc	ra,0xffffc
    80005a5e:	052080e7          	jalr	82(ra) # 80001aac <myproc>
    80005a62:	892a                	mv	s2,a0
  
  begin_op();
    80005a64:	ffffe097          	auipc	ra,0xffffe
    80005a68:	6f2080e7          	jalr	1778(ra) # 80004156 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005a6c:	08000613          	li	a2,128
    80005a70:	f6040593          	addi	a1,s0,-160
    80005a74:	4501                	li	a0,0
    80005a76:	ffffd097          	auipc	ra,0xffffd
    80005a7a:	196080e7          	jalr	406(ra) # 80002c0c <argstr>
    80005a7e:	04054d63          	bltz	a0,80005ad8 <sys_chdir+0x88>
    80005a82:	e526                	sd	s1,136(sp)
    80005a84:	f6040513          	addi	a0,s0,-160
    80005a88:	ffffe097          	auipc	ra,0xffffe
    80005a8c:	4ce080e7          	jalr	1230(ra) # 80003f56 <namei>
    80005a90:	84aa                	mv	s1,a0
    80005a92:	c131                	beqz	a0,80005ad6 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005a94:	ffffe097          	auipc	ra,0xffffe
    80005a98:	cf4080e7          	jalr	-780(ra) # 80003788 <ilock>
  if(ip->type != T_DIR){
    80005a9c:	04449703          	lh	a4,68(s1)
    80005aa0:	4785                	li	a5,1
    80005aa2:	04f71163          	bne	a4,a5,80005ae4 <sys_chdir+0x94>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005aa6:	8526                	mv	a0,s1
    80005aa8:	ffffe097          	auipc	ra,0xffffe
    80005aac:	da6080e7          	jalr	-602(ra) # 8000384e <iunlock>
  iput(p->cwd);
    80005ab0:	15093503          	ld	a0,336(s2)
    80005ab4:	ffffe097          	auipc	ra,0xffffe
    80005ab8:	e92080e7          	jalr	-366(ra) # 80003946 <iput>
  end_op();
    80005abc:	ffffe097          	auipc	ra,0xffffe
    80005ac0:	714080e7          	jalr	1812(ra) # 800041d0 <end_op>
  p->cwd = ip;
    80005ac4:	14993823          	sd	s1,336(s2)
  return 0;
    80005ac8:	4501                	li	a0,0
    80005aca:	64aa                	ld	s1,136(sp)
}
    80005acc:	60ea                	ld	ra,152(sp)
    80005ace:	644a                	ld	s0,144(sp)
    80005ad0:	690a                	ld	s2,128(sp)
    80005ad2:	610d                	addi	sp,sp,160
    80005ad4:	8082                	ret
    80005ad6:	64aa                	ld	s1,136(sp)
    end_op();
    80005ad8:	ffffe097          	auipc	ra,0xffffe
    80005adc:	6f8080e7          	jalr	1784(ra) # 800041d0 <end_op>
    return -1;
    80005ae0:	557d                	li	a0,-1
    80005ae2:	b7ed                	j	80005acc <sys_chdir+0x7c>
    iunlockput(ip);
    80005ae4:	8526                	mv	a0,s1
    80005ae6:	ffffe097          	auipc	ra,0xffffe
    80005aea:	f08080e7          	jalr	-248(ra) # 800039ee <iunlockput>
    end_op();
    80005aee:	ffffe097          	auipc	ra,0xffffe
    80005af2:	6e2080e7          	jalr	1762(ra) # 800041d0 <end_op>
    return -1;
    80005af6:	557d                	li	a0,-1
    80005af8:	64aa                	ld	s1,136(sp)
    80005afa:	bfc9                	j	80005acc <sys_chdir+0x7c>

0000000080005afc <sys_exec>:

uint64
sys_exec(void)
{
    80005afc:	7121                	addi	sp,sp,-448
    80005afe:	ff06                	sd	ra,440(sp)
    80005b00:	fb22                	sd	s0,432(sp)
    80005b02:	0380                	addi	s0,sp,448
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  argaddr(1, &uargv);
    80005b04:	e4840593          	addi	a1,s0,-440
    80005b08:	4505                	li	a0,1
    80005b0a:	ffffd097          	auipc	ra,0xffffd
    80005b0e:	0e2080e7          	jalr	226(ra) # 80002bec <argaddr>
  if(argstr(0, path, MAXPATH) < 0) {
    80005b12:	08000613          	li	a2,128
    80005b16:	f5040593          	addi	a1,s0,-176
    80005b1a:	4501                	li	a0,0
    80005b1c:	ffffd097          	auipc	ra,0xffffd
    80005b20:	0f0080e7          	jalr	240(ra) # 80002c0c <argstr>
    80005b24:	87aa                	mv	a5,a0
    return -1;
    80005b26:	557d                	li	a0,-1
  if(argstr(0, path, MAXPATH) < 0) {
    80005b28:	0e07c263          	bltz	a5,80005c0c <sys_exec+0x110>
    80005b2c:	f726                	sd	s1,424(sp)
    80005b2e:	f34a                	sd	s2,416(sp)
    80005b30:	ef4e                	sd	s3,408(sp)
    80005b32:	eb52                	sd	s4,400(sp)
  }
  memset(argv, 0, sizeof(argv));
    80005b34:	10000613          	li	a2,256
    80005b38:	4581                	li	a1,0
    80005b3a:	e5040513          	addi	a0,s0,-432
    80005b3e:	ffffb097          	auipc	ra,0xffffb
    80005b42:	23e080e7          	jalr	574(ra) # 80000d7c <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005b46:	e5040493          	addi	s1,s0,-432
  memset(argv, 0, sizeof(argv));
    80005b4a:	89a6                	mv	s3,s1
    80005b4c:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005b4e:	02000a13          	li	s4,32
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005b52:	00391513          	slli	a0,s2,0x3
    80005b56:	e4040593          	addi	a1,s0,-448
    80005b5a:	e4843783          	ld	a5,-440(s0)
    80005b5e:	953e                	add	a0,a0,a5
    80005b60:	ffffd097          	auipc	ra,0xffffd
    80005b64:	fce080e7          	jalr	-50(ra) # 80002b2e <fetchaddr>
    80005b68:	02054a63          	bltz	a0,80005b9c <sys_exec+0xa0>
      goto bad;
    }
    if(uarg == 0){
    80005b6c:	e4043783          	ld	a5,-448(s0)
    80005b70:	c7b9                	beqz	a5,80005bbe <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005b72:	ffffb097          	auipc	ra,0xffffb
    80005b76:	fd6080e7          	jalr	-42(ra) # 80000b48 <kalloc>
    80005b7a:	85aa                	mv	a1,a0
    80005b7c:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005b80:	cd11                	beqz	a0,80005b9c <sys_exec+0xa0>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005b82:	6605                	lui	a2,0x1
    80005b84:	e4043503          	ld	a0,-448(s0)
    80005b88:	ffffd097          	auipc	ra,0xffffd
    80005b8c:	ff8080e7          	jalr	-8(ra) # 80002b80 <fetchstr>
    80005b90:	00054663          	bltz	a0,80005b9c <sys_exec+0xa0>
    if(i >= NELEM(argv)){
    80005b94:	0905                	addi	s2,s2,1
    80005b96:	09a1                	addi	s3,s3,8
    80005b98:	fb491de3          	bne	s2,s4,80005b52 <sys_exec+0x56>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005b9c:	f5040913          	addi	s2,s0,-176
    80005ba0:	6088                	ld	a0,0(s1)
    80005ba2:	c125                	beqz	a0,80005c02 <sys_exec+0x106>
    kfree(argv[i]);
    80005ba4:	ffffb097          	auipc	ra,0xffffb
    80005ba8:	ea6080e7          	jalr	-346(ra) # 80000a4a <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005bac:	04a1                	addi	s1,s1,8
    80005bae:	ff2499e3          	bne	s1,s2,80005ba0 <sys_exec+0xa4>
  return -1;
    80005bb2:	557d                	li	a0,-1
    80005bb4:	74ba                	ld	s1,424(sp)
    80005bb6:	791a                	ld	s2,416(sp)
    80005bb8:	69fa                	ld	s3,408(sp)
    80005bba:	6a5a                	ld	s4,400(sp)
    80005bbc:	a881                	j	80005c0c <sys_exec+0x110>
      argv[i] = 0;
    80005bbe:	0009079b          	sext.w	a5,s2
    80005bc2:	078e                	slli	a5,a5,0x3
    80005bc4:	fd078793          	addi	a5,a5,-48
    80005bc8:	97a2                	add	a5,a5,s0
    80005bca:	e807b023          	sd	zero,-384(a5)
  int ret = exec(path, argv);
    80005bce:	e5040593          	addi	a1,s0,-432
    80005bd2:	f5040513          	addi	a0,s0,-176
    80005bd6:	fffff097          	auipc	ra,0xfffff
    80005bda:	120080e7          	jalr	288(ra) # 80004cf6 <exec>
    80005bde:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005be0:	f5040993          	addi	s3,s0,-176
    80005be4:	6088                	ld	a0,0(s1)
    80005be6:	c901                	beqz	a0,80005bf6 <sys_exec+0xfa>
    kfree(argv[i]);
    80005be8:	ffffb097          	auipc	ra,0xffffb
    80005bec:	e62080e7          	jalr	-414(ra) # 80000a4a <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005bf0:	04a1                	addi	s1,s1,8
    80005bf2:	ff3499e3          	bne	s1,s3,80005be4 <sys_exec+0xe8>
  return ret;
    80005bf6:	854a                	mv	a0,s2
    80005bf8:	74ba                	ld	s1,424(sp)
    80005bfa:	791a                	ld	s2,416(sp)
    80005bfc:	69fa                	ld	s3,408(sp)
    80005bfe:	6a5a                	ld	s4,400(sp)
    80005c00:	a031                	j	80005c0c <sys_exec+0x110>
  return -1;
    80005c02:	557d                	li	a0,-1
    80005c04:	74ba                	ld	s1,424(sp)
    80005c06:	791a                	ld	s2,416(sp)
    80005c08:	69fa                	ld	s3,408(sp)
    80005c0a:	6a5a                	ld	s4,400(sp)
}
    80005c0c:	70fa                	ld	ra,440(sp)
    80005c0e:	745a                	ld	s0,432(sp)
    80005c10:	6139                	addi	sp,sp,448
    80005c12:	8082                	ret

0000000080005c14 <sys_pipe>:

uint64
sys_pipe(void)
{
    80005c14:	7139                	addi	sp,sp,-64
    80005c16:	fc06                	sd	ra,56(sp)
    80005c18:	f822                	sd	s0,48(sp)
    80005c1a:	f426                	sd	s1,40(sp)
    80005c1c:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005c1e:	ffffc097          	auipc	ra,0xffffc
    80005c22:	e8e080e7          	jalr	-370(ra) # 80001aac <myproc>
    80005c26:	84aa                	mv	s1,a0

  argaddr(0, &fdarray);
    80005c28:	fd840593          	addi	a1,s0,-40
    80005c2c:	4501                	li	a0,0
    80005c2e:	ffffd097          	auipc	ra,0xffffd
    80005c32:	fbe080e7          	jalr	-66(ra) # 80002bec <argaddr>
  if(pipealloc(&rf, &wf) < 0)
    80005c36:	fc840593          	addi	a1,s0,-56
    80005c3a:	fd040513          	addi	a0,s0,-48
    80005c3e:	fffff097          	auipc	ra,0xfffff
    80005c42:	d50080e7          	jalr	-688(ra) # 8000498e <pipealloc>
    return -1;
    80005c46:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005c48:	0c054463          	bltz	a0,80005d10 <sys_pipe+0xfc>
  fd0 = -1;
    80005c4c:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005c50:	fd043503          	ld	a0,-48(s0)
    80005c54:	fffff097          	auipc	ra,0xfffff
    80005c58:	4e0080e7          	jalr	1248(ra) # 80005134 <fdalloc>
    80005c5c:	fca42223          	sw	a0,-60(s0)
    80005c60:	08054b63          	bltz	a0,80005cf6 <sys_pipe+0xe2>
    80005c64:	fc843503          	ld	a0,-56(s0)
    80005c68:	fffff097          	auipc	ra,0xfffff
    80005c6c:	4cc080e7          	jalr	1228(ra) # 80005134 <fdalloc>
    80005c70:	fca42023          	sw	a0,-64(s0)
    80005c74:	06054863          	bltz	a0,80005ce4 <sys_pipe+0xd0>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005c78:	4691                	li	a3,4
    80005c7a:	fc440613          	addi	a2,s0,-60
    80005c7e:	fd843583          	ld	a1,-40(s0)
    80005c82:	68a8                	ld	a0,80(s1)
    80005c84:	ffffc097          	auipc	ra,0xffffc
    80005c88:	ac0080e7          	jalr	-1344(ra) # 80001744 <copyout>
    80005c8c:	02054063          	bltz	a0,80005cac <sys_pipe+0x98>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005c90:	4691                	li	a3,4
    80005c92:	fc040613          	addi	a2,s0,-64
    80005c96:	fd843583          	ld	a1,-40(s0)
    80005c9a:	0591                	addi	a1,a1,4
    80005c9c:	68a8                	ld	a0,80(s1)
    80005c9e:	ffffc097          	auipc	ra,0xffffc
    80005ca2:	aa6080e7          	jalr	-1370(ra) # 80001744 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005ca6:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005ca8:	06055463          	bgez	a0,80005d10 <sys_pipe+0xfc>
    p->ofile[fd0] = 0;
    80005cac:	fc442783          	lw	a5,-60(s0)
    80005cb0:	07e9                	addi	a5,a5,26
    80005cb2:	078e                	slli	a5,a5,0x3
    80005cb4:	97a6                	add	a5,a5,s1
    80005cb6:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005cba:	fc042783          	lw	a5,-64(s0)
    80005cbe:	07e9                	addi	a5,a5,26
    80005cc0:	078e                	slli	a5,a5,0x3
    80005cc2:	94be                	add	s1,s1,a5
    80005cc4:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    80005cc8:	fd043503          	ld	a0,-48(s0)
    80005ccc:	fffff097          	auipc	ra,0xfffff
    80005cd0:	954080e7          	jalr	-1708(ra) # 80004620 <fileclose>
    fileclose(wf);
    80005cd4:	fc843503          	ld	a0,-56(s0)
    80005cd8:	fffff097          	auipc	ra,0xfffff
    80005cdc:	948080e7          	jalr	-1720(ra) # 80004620 <fileclose>
    return -1;
    80005ce0:	57fd                	li	a5,-1
    80005ce2:	a03d                	j	80005d10 <sys_pipe+0xfc>
    if(fd0 >= 0)
    80005ce4:	fc442783          	lw	a5,-60(s0)
    80005ce8:	0007c763          	bltz	a5,80005cf6 <sys_pipe+0xe2>
      p->ofile[fd0] = 0;
    80005cec:	07e9                	addi	a5,a5,26
    80005cee:	078e                	slli	a5,a5,0x3
    80005cf0:	97a6                	add	a5,a5,s1
    80005cf2:	0007b023          	sd	zero,0(a5)
    fileclose(rf);
    80005cf6:	fd043503          	ld	a0,-48(s0)
    80005cfa:	fffff097          	auipc	ra,0xfffff
    80005cfe:	926080e7          	jalr	-1754(ra) # 80004620 <fileclose>
    fileclose(wf);
    80005d02:	fc843503          	ld	a0,-56(s0)
    80005d06:	fffff097          	auipc	ra,0xfffff
    80005d0a:	91a080e7          	jalr	-1766(ra) # 80004620 <fileclose>
    return -1;
    80005d0e:	57fd                	li	a5,-1
}
    80005d10:	853e                	mv	a0,a5
    80005d12:	70e2                	ld	ra,56(sp)
    80005d14:	7442                	ld	s0,48(sp)
    80005d16:	74a2                	ld	s1,40(sp)
    80005d18:	6121                	addi	sp,sp,64
    80005d1a:	8082                	ret
    80005d1c:	0000                	unimp
	...

0000000080005d20 <kernelvec>:
    80005d20:	7111                	addi	sp,sp,-256
    80005d22:	e006                	sd	ra,0(sp)
    80005d24:	e40a                	sd	sp,8(sp)
    80005d26:	e80e                	sd	gp,16(sp)
    80005d28:	ec12                	sd	tp,24(sp)
    80005d2a:	f016                	sd	t0,32(sp)
    80005d2c:	f41a                	sd	t1,40(sp)
    80005d2e:	f81e                	sd	t2,48(sp)
    80005d30:	fc22                	sd	s0,56(sp)
    80005d32:	e0a6                	sd	s1,64(sp)
    80005d34:	e4aa                	sd	a0,72(sp)
    80005d36:	e8ae                	sd	a1,80(sp)
    80005d38:	ecb2                	sd	a2,88(sp)
    80005d3a:	f0b6                	sd	a3,96(sp)
    80005d3c:	f4ba                	sd	a4,104(sp)
    80005d3e:	f8be                	sd	a5,112(sp)
    80005d40:	fcc2                	sd	a6,120(sp)
    80005d42:	e146                	sd	a7,128(sp)
    80005d44:	e54a                	sd	s2,136(sp)
    80005d46:	e94e                	sd	s3,144(sp)
    80005d48:	ed52                	sd	s4,152(sp)
    80005d4a:	f156                	sd	s5,160(sp)
    80005d4c:	f55a                	sd	s6,168(sp)
    80005d4e:	f95e                	sd	s7,176(sp)
    80005d50:	fd62                	sd	s8,184(sp)
    80005d52:	e1e6                	sd	s9,192(sp)
    80005d54:	e5ea                	sd	s10,200(sp)
    80005d56:	e9ee                	sd	s11,208(sp)
    80005d58:	edf2                	sd	t3,216(sp)
    80005d5a:	f1f6                	sd	t4,224(sp)
    80005d5c:	f5fa                	sd	t5,232(sp)
    80005d5e:	f9fe                	sd	t6,240(sp)
    80005d60:	c9bfc0ef          	jal	800029fa <kerneltrap>
    80005d64:	6082                	ld	ra,0(sp)
    80005d66:	6122                	ld	sp,8(sp)
    80005d68:	61c2                	ld	gp,16(sp)
    80005d6a:	7282                	ld	t0,32(sp)
    80005d6c:	7322                	ld	t1,40(sp)
    80005d6e:	73c2                	ld	t2,48(sp)
    80005d70:	7462                	ld	s0,56(sp)
    80005d72:	6486                	ld	s1,64(sp)
    80005d74:	6526                	ld	a0,72(sp)
    80005d76:	65c6                	ld	a1,80(sp)
    80005d78:	6666                	ld	a2,88(sp)
    80005d7a:	7686                	ld	a3,96(sp)
    80005d7c:	7726                	ld	a4,104(sp)
    80005d7e:	77c6                	ld	a5,112(sp)
    80005d80:	7866                	ld	a6,120(sp)
    80005d82:	688a                	ld	a7,128(sp)
    80005d84:	692a                	ld	s2,136(sp)
    80005d86:	69ca                	ld	s3,144(sp)
    80005d88:	6a6a                	ld	s4,152(sp)
    80005d8a:	7a8a                	ld	s5,160(sp)
    80005d8c:	7b2a                	ld	s6,168(sp)
    80005d8e:	7bca                	ld	s7,176(sp)
    80005d90:	7c6a                	ld	s8,184(sp)
    80005d92:	6c8e                	ld	s9,192(sp)
    80005d94:	6d2e                	ld	s10,200(sp)
    80005d96:	6dce                	ld	s11,208(sp)
    80005d98:	6e6e                	ld	t3,216(sp)
    80005d9a:	7e8e                	ld	t4,224(sp)
    80005d9c:	7f2e                	ld	t5,232(sp)
    80005d9e:	7fce                	ld	t6,240(sp)
    80005da0:	6111                	addi	sp,sp,256
    80005da2:	10200073          	sret
    80005da6:	00000013          	nop
    80005daa:	00000013          	nop
    80005dae:	0001                	nop

0000000080005db0 <timervec>:
    80005db0:	34051573          	csrrw	a0,mscratch,a0
    80005db4:	e10c                	sd	a1,0(a0)
    80005db6:	e510                	sd	a2,8(a0)
    80005db8:	e914                	sd	a3,16(a0)
    80005dba:	6d0c                	ld	a1,24(a0)
    80005dbc:	7110                	ld	a2,32(a0)
    80005dbe:	6194                	ld	a3,0(a1)
    80005dc0:	96b2                	add	a3,a3,a2
    80005dc2:	e194                	sd	a3,0(a1)
    80005dc4:	4589                	li	a1,2
    80005dc6:	14459073          	csrw	sip,a1
    80005dca:	6914                	ld	a3,16(a0)
    80005dcc:	6510                	ld	a2,8(a0)
    80005dce:	610c                	ld	a1,0(a0)
    80005dd0:	34051573          	csrrw	a0,mscratch,a0
    80005dd4:	30200073          	mret
	...

0000000080005dda <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005dda:	1141                	addi	sp,sp,-16
    80005ddc:	e422                	sd	s0,8(sp)
    80005dde:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005de0:	0c0007b7          	lui	a5,0xc000
    80005de4:	4705                	li	a4,1
    80005de6:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005de8:	0c0007b7          	lui	a5,0xc000
    80005dec:	c3d8                	sw	a4,4(a5)
}
    80005dee:	6422                	ld	s0,8(sp)
    80005df0:	0141                	addi	sp,sp,16
    80005df2:	8082                	ret

0000000080005df4 <plicinithart>:

void
plicinithart(void)
{
    80005df4:	1141                	addi	sp,sp,-16
    80005df6:	e406                	sd	ra,8(sp)
    80005df8:	e022                	sd	s0,0(sp)
    80005dfa:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005dfc:	ffffc097          	auipc	ra,0xffffc
    80005e00:	c84080e7          	jalr	-892(ra) # 80001a80 <cpuid>
  
  // set enable bits for this hart's S-mode
  // for the uart and virtio disk.
  *(uint32*)PLIC_SENABLE(hart) = (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005e04:	0085171b          	slliw	a4,a0,0x8
    80005e08:	0c0027b7          	lui	a5,0xc002
    80005e0c:	97ba                	add	a5,a5,a4
    80005e0e:	40200713          	li	a4,1026
    80005e12:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005e16:	00d5151b          	slliw	a0,a0,0xd
    80005e1a:	0c2017b7          	lui	a5,0xc201
    80005e1e:	97aa                	add	a5,a5,a0
    80005e20:	0007a023          	sw	zero,0(a5) # c201000 <_entry-0x73dff000>
}
    80005e24:	60a2                	ld	ra,8(sp)
    80005e26:	6402                	ld	s0,0(sp)
    80005e28:	0141                	addi	sp,sp,16
    80005e2a:	8082                	ret

0000000080005e2c <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005e2c:	1141                	addi	sp,sp,-16
    80005e2e:	e406                	sd	ra,8(sp)
    80005e30:	e022                	sd	s0,0(sp)
    80005e32:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005e34:	ffffc097          	auipc	ra,0xffffc
    80005e38:	c4c080e7          	jalr	-948(ra) # 80001a80 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005e3c:	00d5151b          	slliw	a0,a0,0xd
    80005e40:	0c2017b7          	lui	a5,0xc201
    80005e44:	97aa                	add	a5,a5,a0
  return irq;
}
    80005e46:	43c8                	lw	a0,4(a5)
    80005e48:	60a2                	ld	ra,8(sp)
    80005e4a:	6402                	ld	s0,0(sp)
    80005e4c:	0141                	addi	sp,sp,16
    80005e4e:	8082                	ret

0000000080005e50 <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005e50:	1101                	addi	sp,sp,-32
    80005e52:	ec06                	sd	ra,24(sp)
    80005e54:	e822                	sd	s0,16(sp)
    80005e56:	e426                	sd	s1,8(sp)
    80005e58:	1000                	addi	s0,sp,32
    80005e5a:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005e5c:	ffffc097          	auipc	ra,0xffffc
    80005e60:	c24080e7          	jalr	-988(ra) # 80001a80 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005e64:	00d5151b          	slliw	a0,a0,0xd
    80005e68:	0c2017b7          	lui	a5,0xc201
    80005e6c:	97aa                	add	a5,a5,a0
    80005e6e:	c3c4                	sw	s1,4(a5)
}
    80005e70:	60e2                	ld	ra,24(sp)
    80005e72:	6442                	ld	s0,16(sp)
    80005e74:	64a2                	ld	s1,8(sp)
    80005e76:	6105                	addi	sp,sp,32
    80005e78:	8082                	ret

0000000080005e7a <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005e7a:	1141                	addi	sp,sp,-16
    80005e7c:	e406                	sd	ra,8(sp)
    80005e7e:	e022                	sd	s0,0(sp)
    80005e80:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005e82:	479d                	li	a5,7
    80005e84:	04a7cc63          	blt	a5,a0,80005edc <free_desc+0x62>
    panic("free_desc 1");
  if(disk.free[i])
    80005e88:	0001e797          	auipc	a5,0x1e
    80005e8c:	6f878793          	addi	a5,a5,1784 # 80024580 <disk>
    80005e90:	97aa                	add	a5,a5,a0
    80005e92:	0187c783          	lbu	a5,24(a5)
    80005e96:	ebb9                	bnez	a5,80005eec <free_desc+0x72>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80005e98:	00451693          	slli	a3,a0,0x4
    80005e9c:	0001e797          	auipc	a5,0x1e
    80005ea0:	6e478793          	addi	a5,a5,1764 # 80024580 <disk>
    80005ea4:	6398                	ld	a4,0(a5)
    80005ea6:	9736                	add	a4,a4,a3
    80005ea8:	00073023          	sd	zero,0(a4)
  disk.desc[i].len = 0;
    80005eac:	6398                	ld	a4,0(a5)
    80005eae:	9736                	add	a4,a4,a3
    80005eb0:	00072423          	sw	zero,8(a4)
  disk.desc[i].flags = 0;
    80005eb4:	00071623          	sh	zero,12(a4)
  disk.desc[i].next = 0;
    80005eb8:	00071723          	sh	zero,14(a4)
  disk.free[i] = 1;
    80005ebc:	97aa                	add	a5,a5,a0
    80005ebe:	4705                	li	a4,1
    80005ec0:	00e78c23          	sb	a4,24(a5)
  wakeup(&disk.free[0]);
    80005ec4:	0001e517          	auipc	a0,0x1e
    80005ec8:	6d450513          	addi	a0,a0,1748 # 80024598 <disk+0x18>
    80005ecc:	ffffc097          	auipc	ra,0xffffc
    80005ed0:	2ee080e7          	jalr	750(ra) # 800021ba <wakeup>
}
    80005ed4:	60a2                	ld	ra,8(sp)
    80005ed6:	6402                	ld	s0,0(sp)
    80005ed8:	0141                	addi	sp,sp,16
    80005eda:	8082                	ret
    panic("free_desc 1");
    80005edc:	00002517          	auipc	a0,0x2
    80005ee0:	76c50513          	addi	a0,a0,1900 # 80008648 <etext+0x648>
    80005ee4:	ffffa097          	auipc	ra,0xffffa
    80005ee8:	67c080e7          	jalr	1660(ra) # 80000560 <panic>
    panic("free_desc 2");
    80005eec:	00002517          	auipc	a0,0x2
    80005ef0:	76c50513          	addi	a0,a0,1900 # 80008658 <etext+0x658>
    80005ef4:	ffffa097          	auipc	ra,0xffffa
    80005ef8:	66c080e7          	jalr	1644(ra) # 80000560 <panic>

0000000080005efc <virtio_disk_init>:
{
    80005efc:	1101                	addi	sp,sp,-32
    80005efe:	ec06                	sd	ra,24(sp)
    80005f00:	e822                	sd	s0,16(sp)
    80005f02:	e426                	sd	s1,8(sp)
    80005f04:	e04a                	sd	s2,0(sp)
    80005f06:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80005f08:	00002597          	auipc	a1,0x2
    80005f0c:	76058593          	addi	a1,a1,1888 # 80008668 <etext+0x668>
    80005f10:	0001e517          	auipc	a0,0x1e
    80005f14:	79850513          	addi	a0,a0,1944 # 800246a8 <disk+0x128>
    80005f18:	ffffb097          	auipc	ra,0xffffb
    80005f1c:	cd8080e7          	jalr	-808(ra) # 80000bf0 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005f20:	100017b7          	lui	a5,0x10001
    80005f24:	4398                	lw	a4,0(a5)
    80005f26:	2701                	sext.w	a4,a4
    80005f28:	747277b7          	lui	a5,0x74727
    80005f2c:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80005f30:	18f71c63          	bne	a4,a5,800060c8 <virtio_disk_init+0x1cc>
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80005f34:	100017b7          	lui	a5,0x10001
    80005f38:	0791                	addi	a5,a5,4 # 10001004 <_entry-0x6fffeffc>
    80005f3a:	439c                	lw	a5,0(a5)
    80005f3c:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005f3e:	4709                	li	a4,2
    80005f40:	18e79463          	bne	a5,a4,800060c8 <virtio_disk_init+0x1cc>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005f44:	100017b7          	lui	a5,0x10001
    80005f48:	07a1                	addi	a5,a5,8 # 10001008 <_entry-0x6fffeff8>
    80005f4a:	439c                	lw	a5,0(a5)
    80005f4c:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80005f4e:	16e79d63          	bne	a5,a4,800060c8 <virtio_disk_init+0x1cc>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80005f52:	100017b7          	lui	a5,0x10001
    80005f56:	47d8                	lw	a4,12(a5)
    80005f58:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005f5a:	554d47b7          	lui	a5,0x554d4
    80005f5e:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80005f62:	16f71363          	bne	a4,a5,800060c8 <virtio_disk_init+0x1cc>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005f66:	100017b7          	lui	a5,0x10001
    80005f6a:	0607a823          	sw	zero,112(a5) # 10001070 <_entry-0x6fffef90>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005f6e:	4705                	li	a4,1
    80005f70:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005f72:	470d                	li	a4,3
    80005f74:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80005f76:	10001737          	lui	a4,0x10001
    80005f7a:	4b14                	lw	a3,16(a4)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80005f7c:	c7ffe737          	lui	a4,0xc7ffe
    80005f80:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fda09f>
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80005f84:	8ef9                	and	a3,a3,a4
    80005f86:	10001737          	lui	a4,0x10001
    80005f8a:	d314                	sw	a3,32(a4)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005f8c:	472d                	li	a4,11
    80005f8e:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005f90:	07078793          	addi	a5,a5,112
  status = *R(VIRTIO_MMIO_STATUS);
    80005f94:	439c                	lw	a5,0(a5)
    80005f96:	0007891b          	sext.w	s2,a5
  if(!(status & VIRTIO_CONFIG_S_FEATURES_OK))
    80005f9a:	8ba1                	andi	a5,a5,8
    80005f9c:	12078e63          	beqz	a5,800060d8 <virtio_disk_init+0x1dc>
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80005fa0:	100017b7          	lui	a5,0x10001
    80005fa4:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  if(*R(VIRTIO_MMIO_QUEUE_READY))
    80005fa8:	100017b7          	lui	a5,0x10001
    80005fac:	04478793          	addi	a5,a5,68 # 10001044 <_entry-0x6fffefbc>
    80005fb0:	439c                	lw	a5,0(a5)
    80005fb2:	2781                	sext.w	a5,a5
    80005fb4:	12079a63          	bnez	a5,800060e8 <virtio_disk_init+0x1ec>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80005fb8:	100017b7          	lui	a5,0x10001
    80005fbc:	03478793          	addi	a5,a5,52 # 10001034 <_entry-0x6fffefcc>
    80005fc0:	439c                	lw	a5,0(a5)
    80005fc2:	2781                	sext.w	a5,a5
  if(max == 0)
    80005fc4:	12078a63          	beqz	a5,800060f8 <virtio_disk_init+0x1fc>
  if(max < NUM)
    80005fc8:	471d                	li	a4,7
    80005fca:	12f77f63          	bgeu	a4,a5,80006108 <virtio_disk_init+0x20c>
  disk.desc = kalloc();
    80005fce:	ffffb097          	auipc	ra,0xffffb
    80005fd2:	b7a080e7          	jalr	-1158(ra) # 80000b48 <kalloc>
    80005fd6:	0001e497          	auipc	s1,0x1e
    80005fda:	5aa48493          	addi	s1,s1,1450 # 80024580 <disk>
    80005fde:	e088                	sd	a0,0(s1)
  disk.avail = kalloc();
    80005fe0:	ffffb097          	auipc	ra,0xffffb
    80005fe4:	b68080e7          	jalr	-1176(ra) # 80000b48 <kalloc>
    80005fe8:	e488                	sd	a0,8(s1)
  disk.used = kalloc();
    80005fea:	ffffb097          	auipc	ra,0xffffb
    80005fee:	b5e080e7          	jalr	-1186(ra) # 80000b48 <kalloc>
    80005ff2:	87aa                	mv	a5,a0
    80005ff4:	e888                	sd	a0,16(s1)
  if(!disk.desc || !disk.avail || !disk.used)
    80005ff6:	6088                	ld	a0,0(s1)
    80005ff8:	12050063          	beqz	a0,80006118 <virtio_disk_init+0x21c>
    80005ffc:	0001e717          	auipc	a4,0x1e
    80006000:	58c73703          	ld	a4,1420(a4) # 80024588 <disk+0x8>
    80006004:	10070a63          	beqz	a4,80006118 <virtio_disk_init+0x21c>
    80006008:	10078863          	beqz	a5,80006118 <virtio_disk_init+0x21c>
  memset(disk.desc, 0, PGSIZE);
    8000600c:	6605                	lui	a2,0x1
    8000600e:	4581                	li	a1,0
    80006010:	ffffb097          	auipc	ra,0xffffb
    80006014:	d6c080e7          	jalr	-660(ra) # 80000d7c <memset>
  memset(disk.avail, 0, PGSIZE);
    80006018:	0001e497          	auipc	s1,0x1e
    8000601c:	56848493          	addi	s1,s1,1384 # 80024580 <disk>
    80006020:	6605                	lui	a2,0x1
    80006022:	4581                	li	a1,0
    80006024:	6488                	ld	a0,8(s1)
    80006026:	ffffb097          	auipc	ra,0xffffb
    8000602a:	d56080e7          	jalr	-682(ra) # 80000d7c <memset>
  memset(disk.used, 0, PGSIZE);
    8000602e:	6605                	lui	a2,0x1
    80006030:	4581                	li	a1,0
    80006032:	6888                	ld	a0,16(s1)
    80006034:	ffffb097          	auipc	ra,0xffffb
    80006038:	d48080e7          	jalr	-696(ra) # 80000d7c <memset>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    8000603c:	100017b7          	lui	a5,0x10001
    80006040:	4721                	li	a4,8
    80006042:	df98                	sw	a4,56(a5)
  *R(VIRTIO_MMIO_QUEUE_DESC_LOW) = (uint64)disk.desc;
    80006044:	4098                	lw	a4,0(s1)
    80006046:	100017b7          	lui	a5,0x10001
    8000604a:	08e7a023          	sw	a4,128(a5) # 10001080 <_entry-0x6fffef80>
  *R(VIRTIO_MMIO_QUEUE_DESC_HIGH) = (uint64)disk.desc >> 32;
    8000604e:	40d8                	lw	a4,4(s1)
    80006050:	100017b7          	lui	a5,0x10001
    80006054:	08e7a223          	sw	a4,132(a5) # 10001084 <_entry-0x6fffef7c>
  *R(VIRTIO_MMIO_DRIVER_DESC_LOW) = (uint64)disk.avail;
    80006058:	649c                	ld	a5,8(s1)
    8000605a:	0007869b          	sext.w	a3,a5
    8000605e:	10001737          	lui	a4,0x10001
    80006062:	08d72823          	sw	a3,144(a4) # 10001090 <_entry-0x6fffef70>
  *R(VIRTIO_MMIO_DRIVER_DESC_HIGH) = (uint64)disk.avail >> 32;
    80006066:	9781                	srai	a5,a5,0x20
    80006068:	10001737          	lui	a4,0x10001
    8000606c:	08f72a23          	sw	a5,148(a4) # 10001094 <_entry-0x6fffef6c>
  *R(VIRTIO_MMIO_DEVICE_DESC_LOW) = (uint64)disk.used;
    80006070:	689c                	ld	a5,16(s1)
    80006072:	0007869b          	sext.w	a3,a5
    80006076:	10001737          	lui	a4,0x10001
    8000607a:	0ad72023          	sw	a3,160(a4) # 100010a0 <_entry-0x6fffef60>
  *R(VIRTIO_MMIO_DEVICE_DESC_HIGH) = (uint64)disk.used >> 32;
    8000607e:	9781                	srai	a5,a5,0x20
    80006080:	10001737          	lui	a4,0x10001
    80006084:	0af72223          	sw	a5,164(a4) # 100010a4 <_entry-0x6fffef5c>
  *R(VIRTIO_MMIO_QUEUE_READY) = 0x1;
    80006088:	10001737          	lui	a4,0x10001
    8000608c:	4785                	li	a5,1
    8000608e:	c37c                	sw	a5,68(a4)
    disk.free[i] = 1;
    80006090:	00f48c23          	sb	a5,24(s1)
    80006094:	00f48ca3          	sb	a5,25(s1)
    80006098:	00f48d23          	sb	a5,26(s1)
    8000609c:	00f48da3          	sb	a5,27(s1)
    800060a0:	00f48e23          	sb	a5,28(s1)
    800060a4:	00f48ea3          	sb	a5,29(s1)
    800060a8:	00f48f23          	sb	a5,30(s1)
    800060ac:	00f48fa3          	sb	a5,31(s1)
  status |= VIRTIO_CONFIG_S_DRIVER_OK;
    800060b0:	00496913          	ori	s2,s2,4
  *R(VIRTIO_MMIO_STATUS) = status;
    800060b4:	100017b7          	lui	a5,0x10001
    800060b8:	0727a823          	sw	s2,112(a5) # 10001070 <_entry-0x6fffef90>
}
    800060bc:	60e2                	ld	ra,24(sp)
    800060be:	6442                	ld	s0,16(sp)
    800060c0:	64a2                	ld	s1,8(sp)
    800060c2:	6902                	ld	s2,0(sp)
    800060c4:	6105                	addi	sp,sp,32
    800060c6:	8082                	ret
    panic("could not find virtio disk");
    800060c8:	00002517          	auipc	a0,0x2
    800060cc:	5b050513          	addi	a0,a0,1456 # 80008678 <etext+0x678>
    800060d0:	ffffa097          	auipc	ra,0xffffa
    800060d4:	490080e7          	jalr	1168(ra) # 80000560 <panic>
    panic("virtio disk FEATURES_OK unset");
    800060d8:	00002517          	auipc	a0,0x2
    800060dc:	5c050513          	addi	a0,a0,1472 # 80008698 <etext+0x698>
    800060e0:	ffffa097          	auipc	ra,0xffffa
    800060e4:	480080e7          	jalr	1152(ra) # 80000560 <panic>
    panic("virtio disk should not be ready");
    800060e8:	00002517          	auipc	a0,0x2
    800060ec:	5d050513          	addi	a0,a0,1488 # 800086b8 <etext+0x6b8>
    800060f0:	ffffa097          	auipc	ra,0xffffa
    800060f4:	470080e7          	jalr	1136(ra) # 80000560 <panic>
    panic("virtio disk has no queue 0");
    800060f8:	00002517          	auipc	a0,0x2
    800060fc:	5e050513          	addi	a0,a0,1504 # 800086d8 <etext+0x6d8>
    80006100:	ffffa097          	auipc	ra,0xffffa
    80006104:	460080e7          	jalr	1120(ra) # 80000560 <panic>
    panic("virtio disk max queue too short");
    80006108:	00002517          	auipc	a0,0x2
    8000610c:	5f050513          	addi	a0,a0,1520 # 800086f8 <etext+0x6f8>
    80006110:	ffffa097          	auipc	ra,0xffffa
    80006114:	450080e7          	jalr	1104(ra) # 80000560 <panic>
    panic("virtio disk kalloc");
    80006118:	00002517          	auipc	a0,0x2
    8000611c:	60050513          	addi	a0,a0,1536 # 80008718 <etext+0x718>
    80006120:	ffffa097          	auipc	ra,0xffffa
    80006124:	440080e7          	jalr	1088(ra) # 80000560 <panic>

0000000080006128 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80006128:	7159                	addi	sp,sp,-112
    8000612a:	f486                	sd	ra,104(sp)
    8000612c:	f0a2                	sd	s0,96(sp)
    8000612e:	eca6                	sd	s1,88(sp)
    80006130:	e8ca                	sd	s2,80(sp)
    80006132:	e4ce                	sd	s3,72(sp)
    80006134:	e0d2                	sd	s4,64(sp)
    80006136:	fc56                	sd	s5,56(sp)
    80006138:	f85a                	sd	s6,48(sp)
    8000613a:	f45e                	sd	s7,40(sp)
    8000613c:	f062                	sd	s8,32(sp)
    8000613e:	ec66                	sd	s9,24(sp)
    80006140:	1880                	addi	s0,sp,112
    80006142:	8a2a                	mv	s4,a0
    80006144:	8bae                	mv	s7,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80006146:	00c52c83          	lw	s9,12(a0)
    8000614a:	001c9c9b          	slliw	s9,s9,0x1
    8000614e:	1c82                	slli	s9,s9,0x20
    80006150:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80006154:	0001e517          	auipc	a0,0x1e
    80006158:	55450513          	addi	a0,a0,1364 # 800246a8 <disk+0x128>
    8000615c:	ffffb097          	auipc	ra,0xffffb
    80006160:	b24080e7          	jalr	-1244(ra) # 80000c80 <acquire>
  for(int i = 0; i < 3; i++){
    80006164:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80006166:	44a1                	li	s1,8
      disk.free[i] = 0;
    80006168:	0001eb17          	auipc	s6,0x1e
    8000616c:	418b0b13          	addi	s6,s6,1048 # 80024580 <disk>
  for(int i = 0; i < 3; i++){
    80006170:	4a8d                	li	s5,3
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006172:	0001ec17          	auipc	s8,0x1e
    80006176:	536c0c13          	addi	s8,s8,1334 # 800246a8 <disk+0x128>
    8000617a:	a0ad                	j	800061e4 <virtio_disk_rw+0xbc>
      disk.free[i] = 0;
    8000617c:	00fb0733          	add	a4,s6,a5
    80006180:	00070c23          	sb	zero,24(a4) # 10001018 <_entry-0x6fffefe8>
    idx[i] = alloc_desc();
    80006184:	c19c                	sw	a5,0(a1)
    if(idx[i] < 0){
    80006186:	0207c563          	bltz	a5,800061b0 <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    8000618a:	2905                	addiw	s2,s2,1
    8000618c:	0611                	addi	a2,a2,4 # 1004 <_entry-0x7fffeffc>
    8000618e:	05590f63          	beq	s2,s5,800061ec <virtio_disk_rw+0xc4>
    idx[i] = alloc_desc();
    80006192:	85b2                	mv	a1,a2
  for(int i = 0; i < NUM; i++){
    80006194:	0001e717          	auipc	a4,0x1e
    80006198:	3ec70713          	addi	a4,a4,1004 # 80024580 <disk>
    8000619c:	87ce                	mv	a5,s3
    if(disk.free[i]){
    8000619e:	01874683          	lbu	a3,24(a4)
    800061a2:	fee9                	bnez	a3,8000617c <virtio_disk_rw+0x54>
  for(int i = 0; i < NUM; i++){
    800061a4:	2785                	addiw	a5,a5,1
    800061a6:	0705                	addi	a4,a4,1
    800061a8:	fe979be3          	bne	a5,s1,8000619e <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    800061ac:	57fd                	li	a5,-1
    800061ae:	c19c                	sw	a5,0(a1)
      for(int j = 0; j < i; j++)
    800061b0:	03205163          	blez	s2,800061d2 <virtio_disk_rw+0xaa>
        free_desc(idx[j]);
    800061b4:	f9042503          	lw	a0,-112(s0)
    800061b8:	00000097          	auipc	ra,0x0
    800061bc:	cc2080e7          	jalr	-830(ra) # 80005e7a <free_desc>
      for(int j = 0; j < i; j++)
    800061c0:	4785                	li	a5,1
    800061c2:	0127d863          	bge	a5,s2,800061d2 <virtio_disk_rw+0xaa>
        free_desc(idx[j]);
    800061c6:	f9442503          	lw	a0,-108(s0)
    800061ca:	00000097          	auipc	ra,0x0
    800061ce:	cb0080e7          	jalr	-848(ra) # 80005e7a <free_desc>
    sleep(&disk.free[0], &disk.vdisk_lock);
    800061d2:	85e2                	mv	a1,s8
    800061d4:	0001e517          	auipc	a0,0x1e
    800061d8:	3c450513          	addi	a0,a0,964 # 80024598 <disk+0x18>
    800061dc:	ffffc097          	auipc	ra,0xffffc
    800061e0:	f7a080e7          	jalr	-134(ra) # 80002156 <sleep>
  for(int i = 0; i < 3; i++){
    800061e4:	f9040613          	addi	a2,s0,-112
    800061e8:	894e                	mv	s2,s3
    800061ea:	b765                	j	80006192 <virtio_disk_rw+0x6a>
  }

  // format the three descriptors.
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    800061ec:	f9042503          	lw	a0,-112(s0)
    800061f0:	00451693          	slli	a3,a0,0x4

  if(write)
    800061f4:	0001e797          	auipc	a5,0x1e
    800061f8:	38c78793          	addi	a5,a5,908 # 80024580 <disk>
    800061fc:	00a50713          	addi	a4,a0,10
    80006200:	0712                	slli	a4,a4,0x4
    80006202:	973e                	add	a4,a4,a5
    80006204:	01703633          	snez	a2,s7
    80006208:	c710                	sw	a2,8(a4)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    8000620a:	00072623          	sw	zero,12(a4)
  buf0->sector = sector;
    8000620e:	01973823          	sd	s9,16(a4)

  disk.desc[idx[0]].addr = (uint64) buf0;
    80006212:	6398                	ld	a4,0(a5)
    80006214:	9736                	add	a4,a4,a3
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006216:	0a868613          	addi	a2,a3,168
    8000621a:	963e                	add	a2,a2,a5
  disk.desc[idx[0]].addr = (uint64) buf0;
    8000621c:	e310                	sd	a2,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    8000621e:	6390                	ld	a2,0(a5)
    80006220:	00d605b3          	add	a1,a2,a3
    80006224:	4741                	li	a4,16
    80006226:	c598                	sw	a4,8(a1)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    80006228:	4805                	li	a6,1
    8000622a:	01059623          	sh	a6,12(a1)
  disk.desc[idx[0]].next = idx[1];
    8000622e:	f9442703          	lw	a4,-108(s0)
    80006232:	00e59723          	sh	a4,14(a1)

  disk.desc[idx[1]].addr = (uint64) b->data;
    80006236:	0712                	slli	a4,a4,0x4
    80006238:	963a                	add	a2,a2,a4
    8000623a:	058a0593          	addi	a1,s4,88
    8000623e:	e20c                	sd	a1,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    80006240:	0007b883          	ld	a7,0(a5)
    80006244:	9746                	add	a4,a4,a7
    80006246:	40000613          	li	a2,1024
    8000624a:	c710                	sw	a2,8(a4)
  if(write)
    8000624c:	001bb613          	seqz	a2,s7
    80006250:	0016161b          	slliw	a2,a2,0x1
    disk.desc[idx[1]].flags = 0; // device reads b->data
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    80006254:	00166613          	ori	a2,a2,1
    80006258:	00c71623          	sh	a2,12(a4)
  disk.desc[idx[1]].next = idx[2];
    8000625c:	f9842583          	lw	a1,-104(s0)
    80006260:	00b71723          	sh	a1,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80006264:	00250613          	addi	a2,a0,2
    80006268:	0612                	slli	a2,a2,0x4
    8000626a:	963e                	add	a2,a2,a5
    8000626c:	577d                	li	a4,-1
    8000626e:	00e60823          	sb	a4,16(a2)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80006272:	0592                	slli	a1,a1,0x4
    80006274:	98ae                	add	a7,a7,a1
    80006276:	03068713          	addi	a4,a3,48
    8000627a:	973e                	add	a4,a4,a5
    8000627c:	00e8b023          	sd	a4,0(a7)
  disk.desc[idx[2]].len = 1;
    80006280:	6398                	ld	a4,0(a5)
    80006282:	972e                	add	a4,a4,a1
    80006284:	01072423          	sw	a6,8(a4)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    80006288:	4689                	li	a3,2
    8000628a:	00d71623          	sh	a3,12(a4)
  disk.desc[idx[2]].next = 0;
    8000628e:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80006292:	010a2223          	sw	a6,4(s4)
  disk.info[idx[0]].b = b;
    80006296:	01463423          	sd	s4,8(a2)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    8000629a:	6794                	ld	a3,8(a5)
    8000629c:	0026d703          	lhu	a4,2(a3)
    800062a0:	8b1d                	andi	a4,a4,7
    800062a2:	0706                	slli	a4,a4,0x1
    800062a4:	96ba                	add	a3,a3,a4
    800062a6:	00a69223          	sh	a0,4(a3)

  __sync_synchronize();
    800062aa:	0330000f          	fence	rw,rw

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    800062ae:	6798                	ld	a4,8(a5)
    800062b0:	00275783          	lhu	a5,2(a4)
    800062b4:	2785                	addiw	a5,a5,1
    800062b6:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    800062ba:	0330000f          	fence	rw,rw

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    800062be:	100017b7          	lui	a5,0x10001
    800062c2:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    800062c6:	004a2783          	lw	a5,4(s4)
    sleep(b, &disk.vdisk_lock);
    800062ca:	0001e917          	auipc	s2,0x1e
    800062ce:	3de90913          	addi	s2,s2,990 # 800246a8 <disk+0x128>
  while(b->disk == 1) {
    800062d2:	4485                	li	s1,1
    800062d4:	01079c63          	bne	a5,a6,800062ec <virtio_disk_rw+0x1c4>
    sleep(b, &disk.vdisk_lock);
    800062d8:	85ca                	mv	a1,s2
    800062da:	8552                	mv	a0,s4
    800062dc:	ffffc097          	auipc	ra,0xffffc
    800062e0:	e7a080e7          	jalr	-390(ra) # 80002156 <sleep>
  while(b->disk == 1) {
    800062e4:	004a2783          	lw	a5,4(s4)
    800062e8:	fe9788e3          	beq	a5,s1,800062d8 <virtio_disk_rw+0x1b0>
  }

  disk.info[idx[0]].b = 0;
    800062ec:	f9042903          	lw	s2,-112(s0)
    800062f0:	00290713          	addi	a4,s2,2
    800062f4:	0712                	slli	a4,a4,0x4
    800062f6:	0001e797          	auipc	a5,0x1e
    800062fa:	28a78793          	addi	a5,a5,650 # 80024580 <disk>
    800062fe:	97ba                	add	a5,a5,a4
    80006300:	0007b423          	sd	zero,8(a5)
    int flag = disk.desc[i].flags;
    80006304:	0001e997          	auipc	s3,0x1e
    80006308:	27c98993          	addi	s3,s3,636 # 80024580 <disk>
    8000630c:	00491713          	slli	a4,s2,0x4
    80006310:	0009b783          	ld	a5,0(s3)
    80006314:	97ba                	add	a5,a5,a4
    80006316:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    8000631a:	854a                	mv	a0,s2
    8000631c:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    80006320:	00000097          	auipc	ra,0x0
    80006324:	b5a080e7          	jalr	-1190(ra) # 80005e7a <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    80006328:	8885                	andi	s1,s1,1
    8000632a:	f0ed                	bnez	s1,8000630c <virtio_disk_rw+0x1e4>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    8000632c:	0001e517          	auipc	a0,0x1e
    80006330:	37c50513          	addi	a0,a0,892 # 800246a8 <disk+0x128>
    80006334:	ffffb097          	auipc	ra,0xffffb
    80006338:	a00080e7          	jalr	-1536(ra) # 80000d34 <release>
}
    8000633c:	70a6                	ld	ra,104(sp)
    8000633e:	7406                	ld	s0,96(sp)
    80006340:	64e6                	ld	s1,88(sp)
    80006342:	6946                	ld	s2,80(sp)
    80006344:	69a6                	ld	s3,72(sp)
    80006346:	6a06                	ld	s4,64(sp)
    80006348:	7ae2                	ld	s5,56(sp)
    8000634a:	7b42                	ld	s6,48(sp)
    8000634c:	7ba2                	ld	s7,40(sp)
    8000634e:	7c02                	ld	s8,32(sp)
    80006350:	6ce2                	ld	s9,24(sp)
    80006352:	6165                	addi	sp,sp,112
    80006354:	8082                	ret

0000000080006356 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    80006356:	1101                	addi	sp,sp,-32
    80006358:	ec06                	sd	ra,24(sp)
    8000635a:	e822                	sd	s0,16(sp)
    8000635c:	e426                	sd	s1,8(sp)
    8000635e:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80006360:	0001e497          	auipc	s1,0x1e
    80006364:	22048493          	addi	s1,s1,544 # 80024580 <disk>
    80006368:	0001e517          	auipc	a0,0x1e
    8000636c:	34050513          	addi	a0,a0,832 # 800246a8 <disk+0x128>
    80006370:	ffffb097          	auipc	ra,0xffffb
    80006374:	910080e7          	jalr	-1776(ra) # 80000c80 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80006378:	100017b7          	lui	a5,0x10001
    8000637c:	53b8                	lw	a4,96(a5)
    8000637e:	8b0d                	andi	a4,a4,3
    80006380:	100017b7          	lui	a5,0x10001
    80006384:	d3f8                	sw	a4,100(a5)

  __sync_synchronize();
    80006386:	0330000f          	fence	rw,rw

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    8000638a:	689c                	ld	a5,16(s1)
    8000638c:	0204d703          	lhu	a4,32(s1)
    80006390:	0027d783          	lhu	a5,2(a5) # 10001002 <_entry-0x6fffeffe>
    80006394:	04f70863          	beq	a4,a5,800063e4 <virtio_disk_intr+0x8e>
    __sync_synchronize();
    80006398:	0330000f          	fence	rw,rw
    int id = disk.used->ring[disk.used_idx % NUM].id;
    8000639c:	6898                	ld	a4,16(s1)
    8000639e:	0204d783          	lhu	a5,32(s1)
    800063a2:	8b9d                	andi	a5,a5,7
    800063a4:	078e                	slli	a5,a5,0x3
    800063a6:	97ba                	add	a5,a5,a4
    800063a8:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    800063aa:	00278713          	addi	a4,a5,2
    800063ae:	0712                	slli	a4,a4,0x4
    800063b0:	9726                	add	a4,a4,s1
    800063b2:	01074703          	lbu	a4,16(a4)
    800063b6:	e721                	bnez	a4,800063fe <virtio_disk_intr+0xa8>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    800063b8:	0789                	addi	a5,a5,2
    800063ba:	0792                	slli	a5,a5,0x4
    800063bc:	97a6                	add	a5,a5,s1
    800063be:	6788                	ld	a0,8(a5)
    b->disk = 0;   // disk is done with buf
    800063c0:	00052223          	sw	zero,4(a0)
    wakeup(b);
    800063c4:	ffffc097          	auipc	ra,0xffffc
    800063c8:	df6080e7          	jalr	-522(ra) # 800021ba <wakeup>

    disk.used_idx += 1;
    800063cc:	0204d783          	lhu	a5,32(s1)
    800063d0:	2785                	addiw	a5,a5,1
    800063d2:	17c2                	slli	a5,a5,0x30
    800063d4:	93c1                	srli	a5,a5,0x30
    800063d6:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    800063da:	6898                	ld	a4,16(s1)
    800063dc:	00275703          	lhu	a4,2(a4)
    800063e0:	faf71ce3          	bne	a4,a5,80006398 <virtio_disk_intr+0x42>
  }

  release(&disk.vdisk_lock);
    800063e4:	0001e517          	auipc	a0,0x1e
    800063e8:	2c450513          	addi	a0,a0,708 # 800246a8 <disk+0x128>
    800063ec:	ffffb097          	auipc	ra,0xffffb
    800063f0:	948080e7          	jalr	-1720(ra) # 80000d34 <release>
}
    800063f4:	60e2                	ld	ra,24(sp)
    800063f6:	6442                	ld	s0,16(sp)
    800063f8:	64a2                	ld	s1,8(sp)
    800063fa:	6105                	addi	sp,sp,32
    800063fc:	8082                	ret
      panic("virtio_disk_intr status");
    800063fe:	00002517          	auipc	a0,0x2
    80006402:	33250513          	addi	a0,a0,818 # 80008730 <etext+0x730>
    80006406:	ffffa097          	auipc	ra,0xffffa
    8000640a:	15a080e7          	jalr	346(ra) # 80000560 <panic>
	...

0000000080007000 <_trampoline>:
    80007000:	14051073          	csrw	sscratch,a0
    80007004:	02000537          	lui	a0,0x2000
    80007008:	357d                	addiw	a0,a0,-1 # 1ffffff <_entry-0x7e000001>
    8000700a:	0536                	slli	a0,a0,0xd
    8000700c:	02153423          	sd	ra,40(a0)
    80007010:	02253823          	sd	sp,48(a0)
    80007014:	02353c23          	sd	gp,56(a0)
    80007018:	04453023          	sd	tp,64(a0)
    8000701c:	04553423          	sd	t0,72(a0)
    80007020:	04653823          	sd	t1,80(a0)
    80007024:	04753c23          	sd	t2,88(a0)
    80007028:	f120                	sd	s0,96(a0)
    8000702a:	f524                	sd	s1,104(a0)
    8000702c:	fd2c                	sd	a1,120(a0)
    8000702e:	e150                	sd	a2,128(a0)
    80007030:	e554                	sd	a3,136(a0)
    80007032:	e958                	sd	a4,144(a0)
    80007034:	ed5c                	sd	a5,152(a0)
    80007036:	0b053023          	sd	a6,160(a0)
    8000703a:	0b153423          	sd	a7,168(a0)
    8000703e:	0b253823          	sd	s2,176(a0)
    80007042:	0b353c23          	sd	s3,184(a0)
    80007046:	0d453023          	sd	s4,192(a0)
    8000704a:	0d553423          	sd	s5,200(a0)
    8000704e:	0d653823          	sd	s6,208(a0)
    80007052:	0d753c23          	sd	s7,216(a0)
    80007056:	0f853023          	sd	s8,224(a0)
    8000705a:	0f953423          	sd	s9,232(a0)
    8000705e:	0fa53823          	sd	s10,240(a0)
    80007062:	0fb53c23          	sd	s11,248(a0)
    80007066:	11c53023          	sd	t3,256(a0)
    8000706a:	11d53423          	sd	t4,264(a0)
    8000706e:	11e53823          	sd	t5,272(a0)
    80007072:	11f53c23          	sd	t6,280(a0)
    80007076:	140022f3          	csrr	t0,sscratch
    8000707a:	06553823          	sd	t0,112(a0)
    8000707e:	00853103          	ld	sp,8(a0)
    80007082:	02053203          	ld	tp,32(a0)
    80007086:	01053283          	ld	t0,16(a0)
    8000708a:	00053303          	ld	t1,0(a0)
    8000708e:	12000073          	sfence.vma
    80007092:	18031073          	csrw	satp,t1
    80007096:	12000073          	sfence.vma
    8000709a:	8282                	jr	t0

000000008000709c <userret>:
    8000709c:	12000073          	sfence.vma
    800070a0:	18051073          	csrw	satp,a0
    800070a4:	12000073          	sfence.vma
    800070a8:	02000537          	lui	a0,0x2000
    800070ac:	357d                	addiw	a0,a0,-1 # 1ffffff <_entry-0x7e000001>
    800070ae:	0536                	slli	a0,a0,0xd
    800070b0:	02853083          	ld	ra,40(a0)
    800070b4:	03053103          	ld	sp,48(a0)
    800070b8:	03853183          	ld	gp,56(a0)
    800070bc:	04053203          	ld	tp,64(a0)
    800070c0:	04853283          	ld	t0,72(a0)
    800070c4:	05053303          	ld	t1,80(a0)
    800070c8:	05853383          	ld	t2,88(a0)
    800070cc:	7120                	ld	s0,96(a0)
    800070ce:	7524                	ld	s1,104(a0)
    800070d0:	7d2c                	ld	a1,120(a0)
    800070d2:	6150                	ld	a2,128(a0)
    800070d4:	6554                	ld	a3,136(a0)
    800070d6:	6958                	ld	a4,144(a0)
    800070d8:	6d5c                	ld	a5,152(a0)
    800070da:	0a053803          	ld	a6,160(a0)
    800070de:	0a853883          	ld	a7,168(a0)
    800070e2:	0b053903          	ld	s2,176(a0)
    800070e6:	0b853983          	ld	s3,184(a0)
    800070ea:	0c053a03          	ld	s4,192(a0)
    800070ee:	0c853a83          	ld	s5,200(a0)
    800070f2:	0d053b03          	ld	s6,208(a0)
    800070f6:	0d853b83          	ld	s7,216(a0)
    800070fa:	0e053c03          	ld	s8,224(a0)
    800070fe:	0e853c83          	ld	s9,232(a0)
    80007102:	0f053d03          	ld	s10,240(a0)
    80007106:	0f853d83          	ld	s11,248(a0)
    8000710a:	10053e03          	ld	t3,256(a0)
    8000710e:	10853e83          	ld	t4,264(a0)
    80007112:	11053f03          	ld	t5,272(a0)
    80007116:	11853f83          	ld	t6,280(a0)
    8000711a:	7928                	ld	a0,112(a0)
    8000711c:	10200073          	sret
	...
