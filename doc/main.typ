#import "template/common.typ": *

#show: doc.with(
  info: (
    author: "fa_555",
    title: "rCore 记录",
    date: datetime.today(),
  ),
)

#set page(numbering: "i")

#align(
  center,
  text(
    size: 2em,
    font: sans-font,
    weight: "medium",
    fill: tint._800,
  )[rCore 记录],
)

#heading(numbering: none)[前言]

学习 rCore 课程的记录。

On aarch64 macOS Sequoia 15.2 (24C101).

#align(right, fa-555)

#show heading.where(level: 1): it => pagebreak() + it

#outline()

#set page(numbering: "1 / 1")
#counter(page).update(1)

= 第零章：配环境 <environment>

#[
  #set raw(lang: "fish")

  既然 xv6 都不需要 Linux，rCore 干嘛非得要 Linux 呢？直接在 macOS 上配。

  + Homebrew 略
  + QEMU：`brew install qemu`
  + RISC-V 调试支持：`brew install riscv64-elf-gdb`
  + 准备仓库

    #fancy-raw(```
    git clone https://github.com/rcore-os/rCore-Tutorial-v3.git
    cd rCore-Tutorial-v3
    ```)

  + Rust 工具链
    - rustup 略
    - 注意需要切换到 nightly channel: `rustup default nightly`
      - #comment[目前使用的是 1.85.0-nightly，但是疑似后面 make 会自己再下载一个 1.80.0-nightly。]
    - 准备相关的 target 和组件

      #fancy-raw(```sh
      rustup target add riscv64gc-unknown-none-elf
      cargo install cargo-binutils
      rustup component add llvm-tools-preview rust-src
      ```)

  + 运行

    #fancy-raw(```
    cd os
    make run
    ```)

  至少到目前为止跑起来了，看起来效果尚可。
]

= 第零章习题

// #problem(title: "1")[
//   在你日常使用的操作系统环境中安装并配置好实验环境。简要说明你碰到的问题/困难和解决方法。
// ][
//   参见@environment。
// ]

#problem(title: "2")[
  在 Linux 环境下编写一个会产生异常的应用程序，并简要解释操作系统的处理结果。
][
  #set raw(lang: "c")

  #code-from-file("exercise/0-segfault.c")

  当运行到 `*p = 114;` 时，由于 `p` 是空指针，访问其会触发一个异常，在 Linux 下会产生一个 `SIGSEGV` 信号。由于程序没有捕获这个信号，操作系统会终止这个程序，同时输出一些信息：

  #fancy-raw(```text
  Before segmentation fault
  fish: Job 1, './s' terminated by signal SIGSEGV (Address boundary error)
  ```)
]

#problem(title: "3")[
  在 Linux 环境下编写一个可以睡眠 5 秒后打印出一个字符串，并把字符串内容存入一个文件中的应用程序 A。（基于 C 或 Rust 语言）
][
  用 C 实现：

  #code-from-file("exercise/0-sleep.c")

  用 Rust 实现：

  #code-from-file("exercise/0-sleep.rs")
]

#problem(title: "4")[
  在 Linux 环境下编写一个可以睡眠 5 秒后打印出一个字符串，并把字符串内容存入一个文件中的应用程序 B。（基于 C 或 Rust 语言）
][
  编写这样的一个程序：主线程启动若干个线程后继续异步执行其他操作，其余每个线程睡眠 2 秒后向同一个文件中写入一条消息。

  / 并发性: 多个线程同时运行（在多核CPU上可真正并行）。
  / 异步性: 主线程发起 IO 读写请求后并不等待结果，可继续执行其他操作。
  / 共享性: 多个线程共享相同的地址空间，共享部分全局数据结构。
  / 持久性: 通过将结果输出到文件中，数据持久化到磁盘。

  用 C 实现：

  #code-from-file("exercise/0-threads.c")

  用 Rust 实现：

  #code-from-file("exercise/0-threads.rs")

  细节：这两份代码的字符数恰好相等。
]

= 第一章：应用程序与基本执行环境

删掉 metadata，裁剪出系统镜像：

#fancy-raw(```sh
rust-objcopy --strip-all target/riscv64gc-unknown-none-elf/release/os -O binary target/riscv64gc-unknown-none-elf/release/os.bin
```)

== 调用栈知识清单问答

#problem[
  - 在 RISC-V 架构上，调用者保存和被调用者保存寄存器如何划分的？
  - `sp` 和 `ra` 是调用者保存还是被调用者保存寄存器，为什么这样约定？
][
  #figure(
    caption: [RISC-V 寄存器约定#footnote[参见 #emph[RISC-V ABIs Specification] 中的 RISC-V Calling Conventions – 1. Register Convention 章节。]],
    {
      let y = (body: [是]) => text(weight: "semibold", twcolors.emerald._800, body)
      let n = (body: [否]) => text(weight: "semibold", twcolors.rose._800, body)
      let na = reason => text(twcolors.gray._400)[N/A（#reason）]

      set table.cell(breakable: false)

      table(
        inset: (x: .75em, y: .5em),
        align: (x, y) => (
          if y != 0 and x == 3 {
            left
          } else { center }
            + horizon
        ),
        columns: 5,

        table-header-maker(
          [类型],
          [名称],
          [ABI 助记别名],
          [说明],
          [多次调用是否保留值\ （被调用者保存）],
        ),

        table.cell(rowspan: 10)[整数],
        `x0`, `zero`, [零], na[不可变],
        `x1`, `ra`, [返回地址], n(),
        `x2`, `sp`, [栈指针], y(),
        `x3`, `gp`, [全局指针], na[不可写],
        `x4`, `tp`, [线程指针], na[不可写],
        [`x5` – `x7`], [`t0` – `t2`], [临时寄存器], n(),
        [`x8` – `x9`], [`s0` – `s1`], [被调用者保存寄存器], y(),
        [`x10` – `x17`], [`a0` – `a7`], [函数参数和返回值寄存器], n(),
        [`x18` – `x27`], [`s2` – `s11`], [被调用者保存寄存器], y(),
        [`x28` – `x31`], [`t3` – `t6`], [临时寄存器], n(),

        table.cell(rowspan: 5)[浮点],
        [`f0` – `f7`], [`ft0` – `ft7`], [临时寄存器], n(),
        [`f8` – `f9`], [`fs0` – `fs1`], [被调用者保存寄存器], y(
          body: [是#footnote[仅当浮点数值不大于目标 ABI 的浮点寄存器宽度时才需要保存，否则视作临时寄存器（调用者保存）。] <fpreg-callee-saved>],
        ),
        [`f10` – `f17`], [`fa0` – `fa7`], [函数参数和返回值寄存器], n(),
        [`f18` – `f27`], [`fs2` – `fs11`], [被调用者保存寄存器], y(
          body: [是#footnote(<fpreg-callee-saved>)],
        ),
        [`f28` – `f31`], [`ft8` – `ft11`], [临时寄存器], n(),

        table.cell(rowspan: 5)[向量],
        [`v0` – `v31`], table.cell(rowspan: 5)[N/A], [临时寄存器], table.cell(rowspan: 5, n()),
        `vl`, [向量长度],
        `vtype`, [向量类型寄存器],
        `vxrm`, [向量定点舍入模式寄存器],
        `vxsat`, [向量饱和标志寄存器],
      )
    },
  )

  帧指针 `fp` 是可选的。如果存在，则其必须位于 `x8`（`s0`）中，同时仍然是被调用者保存的。
]

== 基于 gdb 验证启动流程

解决方案：tmux 分屏，一边起 QEMU，一边用 gdb 连接。

#fancy-raw(```sh
qemu-system-riscv64 \
    -machine virt \
    -nographic \
    -bios $RCORE_SBI/bootloader/rustsbi-qemu.bin \
    -device loader,file=target/riscv64gc-unknown-none-elf/release/os.bin,addr=0x80200000 \
    -s -S
```)

#fancy-raw(```sh
riscv64-elf-gdb \
    -ex 'file target/riscv64gc-unknown-none-elf/release/os' \
    -ex 'set arch riscv:rv64' \
    -ex 'target remote localhost:1234'
```)

= 第一章习题

#problem(title: "1")[
  实现一个 Linux 应用程序 A，显示当前目录下的文件名。（用 C 或 Rust 编程）

  请用相关工具软件分析并给出应用程序 A 的代码段 / 数据段 / 堆 / 栈的地址空间范围。
][
  本题短暂地切到 Linux 上，因为 macOS 的可执行文件根本不是 ELF。可执行文件格式都不一样，聊 `.text`, `.data`, `.bss` 之类的那不是闹笑话吗。

  用 C 实现：

  #code-from-file("exercise/1-ls-dir.c")

  使用 `readelf` 查看可执行文件：

  #fancy-raw(```
  $ readelf -S s
  There are 38 section headers, starting at offset 0x3de0:

  Section Headers:
    [Nr] Name              Type             Address           Offset
         Size              EntSize          Flags  Link  Info  Align
    [16] .text             PROGBITS         00000000000010e0  000010e0
         000000000000013a  0000000000000000  AX       0     0     16
    [18] .rodata           PROGBITS         0000000000002000  00002000
         000000000000000e  0000000000000000   A       0     0     4
    [25] .data             PROGBITS         0000000000004000  00003000
         0000000000000010  0000000000000000  WA       0     0     8
    [26] .bss              NOBITS           0000000000004010  00003010
         0000000000000008  0000000000000000  WA       0     0     1
    [27] .comment          PROGBITS         0000000000000000  00003010
         000000000000002b  0000000000000001  MS       0     0     1
  ```)

  在 gdb 中 attach 上进程，然后：

  #fancy-raw(```
  (gdb) info proc mappings
  process 1442090
  Mapped address spaces:

            Start Addr           End Addr       Size     Offset  Perms  objfile
        0x5562d1d3f000     0x5562d1d40000     0x1000        0x0  r--p   s
        0x5562d1d40000     0x5562d1d41000     0x1000     0x1000  r-xp   s
        0x5562d1d41000     0x5562d1d42000     0x1000     0x2000  r--p   s
        0x5562d1d42000     0x5562d1d43000     0x1000     0x2000  r--p   s
        0x5562d1d43000     0x5562d1d44000     0x1000     0x3000  rw-p   s
        0x556308625000     0x556308646000    0x21000        0x0  rw-p   [heap]
        0x7f81ff65e000     0x7f81ff661000     0x3000        0x0  rw-p

  ... omitted ...
  ```)

  比对二者，我们认为：

  - `.text` 段在虚拟地址 `[0x5562d1d40000, 0x5562d1d41000) r-xp`（实际大小为 `0x13a`）。
  - `.data` 段等在虚拟地址 `[0x5562d1d43000, 0x5562d1d44000) rw-p`。
  - 堆空间在 `[0x556308625000, 0x556308646000)`。
  - 栈空间在 `[0x7f81ff65e000, 0x7f81ff661000)`。

  用 Rust 实现：

  #code-from-file("exercise/1-ls-dir.rs")

  ELF 情况与 C 版本完全相同，不再赘述。

  两份代码的行为稍有不同：C 版本会多输出 `.` 和 `..` 两个目录，Rust 版本则不会。
]

#problem(title: "2")[
  实现一个 Linux 应用程序 B，能打印出调用栈链信息。（用 C 或 Rust 编程）
][
  直接调库。不知道他们手写的是怎么搞的，反正我手写只能拿到地址，拿不到函数名。

  用 C 实现：

  #code-from-file("exercise/1-backtrace.c")

  用 Rust 实现：

  #code-from-file("exercise/1-backtrace.rs")

  Rust 的 unwind 确实非常猛，在我的机器上这一段代码就套了 20 多层。相比之下 C 就十分忠实地只有可见的这几层。
]

#problem(title: "4")[
  请基于 QEMU 模拟 RISC-V 的执行过程和 QEMU 源代码，说明 RISC-V 硬件加电后的几条指令在哪里？完成了哪些功能？
][
  我使用的是 QEMU 9.2.0。对于这个版本的 QEMU，参照 #link("https://gitlab.com/qemu-project/qemu/-/blob/stable-9.2/hw/riscv/boot.c?ref_type=heads#L407")[stable-9.2 分支的 `hw/riscv/boot.c` 中的 `riscv_setup_rom_reset_vec` 函数中的 `reset_vec[]`]：

  #fancy-raw(```c
  uint32_t reset_vec[10] = {
      0x00000297,                  /* 1:  auipc  t0, %pcrel_hi(fw_dyn) */
      0x02828613,                  /*     addi   a2, t0, %pcrel_lo(1b) */
      0xf1402573,                  /*     csrr   a0, mhartid  */
      0,
      0,
      0x00028067,                  /*     jr     t0 */
      start_addr,                  /* start: .dword */
      start_addr_hi32,
      fdt_load_addr,               /* fdt_laddr: .dword */
      fdt_load_addr_hi32,
                                   /* fw_dyn: */
  };
  if (riscv_is_32bit(harts)) {
      reset_vec[3] = 0x0202a583;   /*     lw     a1, 32(t0) */
      reset_vec[4] = 0x0182a283;   /*     lw     t0, 24(t0) */
  } else {
      reset_vec[3] = 0x0202b583;   /*     ld     a1, 32(t0) */
      reset_vec[4] = 0x0182b283;   /*     ld     t0, 24(t0) */
  }
  ```)

  以 64 位为例，这代表以下指令：

  #set raw(lang: "rvasm")

  #fancy-raw(```rvasm
      auipc t0, %pcrel_hi(fw_dyn)
      addi  a2, t0, %pcrel_lo(1b)
      csrrs a0, mhartid
      ld    a1, 32(t0)
      ld    t0, 24(t0)
      jr t0
  start_addr: .dword
  start_addr_hi32: .dword
  fdt_load_addr: .dword
  fdt_load_addr_hi32: .dword
  ```)

  指令集的简要介绍如下（参见#link("https://msyksphinz-self.github.io/riscv-isadoc/html/index.html")[RISC-V Instruction Set Specifications]，可以据此自行辨别各条指令的含义）：

  / `auipc`: Add Upper Immediate to PC.
  / `addi`: ADD Immediate.
  / `csrrs`: CSR Read and Set. (CSR: Control and Status Register)
  / `ld`: Load Doubleword.
  / `jr`: Jump Register.

  + 将固件启动代码 `fw_dyn` 的目标地址加载到 `t0` 中。
    - `auipc t0, %pcrel_hi(fw_dyn)`：将 `fw_dyn` 的高 20 位加上当前 PC 的值，加载到 `t0` 中。
      - `%pcrel_hi` 和下面的 `%pcrel_lo` 只是汇编助记。
    - `addi a2, t0, %pcrel_lo(1b)`：将 `fw_dyn` 的低 12 位加载到 `a2` 中。
      - `1b` 即 1 backward，指前一个标签的位置#footnote[注意英文与中文的不同：backward 同“之前”。]，这是为了增加代码的位置无关性。
  + 将当前硬件线程（hart）ID，也即 `mhartid`，加载到 `a0` 中。
    - `csrrs a0, mhartid` 实际上进行了如下操作：`t = CSR[0xf14]; CSR[0xf14] = t | x0; a0 = t`，也即 `a0 = CSR[0xf14]`。
  + 从内存中 `fw_dyn` 的地址处加载两个值到 `a1` 和 `t0` 中。加载值的长度与硬件位宽有关。
  + 跳转到 `t0` 中的地址。
]

#problem(title: [9])[
  现代的很多编译器生成的代码，默认情况下不再严格保存/恢复栈帧指针。在这个情况下，我们只要编译器提供足够的信息，也可以完成对调用栈的恢复。

  我们可以手动阅读汇编代码和栈上的数据，体验一下这个过程。例如，对如下两个互相递归调用的函数：

  #fancy-raw(```c
  void flip(unsigned n) {
      if ((n & 1) == 0) {
          flip(n >> 1);
      } else if ((n & 1) == 1) {
          flap(n >> 1);
      }
  }

  void flap(unsigned n) {
      if ((n & 1) == 0) {
          flip(n >> 1);
      } else if ((n & 1) == 1) {
          flap(n >> 1);
      }
  }
  ```)

  #set raw(lang: "rvasm")

  在某种编译环境下，编译器产生的代码不包括保存和恢复栈帧指针 `fp` 的代码。以下是 GDB 输出的本次运行的时候，这两个函数所在的地址和对应地址指令的反汇编，为了方便阅读节选了重要的控制流和栈操作（省略部分不含栈操作）：

  #fancy-raw(```
  (gdb) disassemble flap
  Dump of assembler code for function flap:
     0x0000000000010730 <+0>:     addi    sp,sp,-16    // 唯一入口
     0x0000000000010732 <+2>:     sd      ra,8(sp)
     ...
     0x0000000000010742 <+18>:    ld      ra,8(sp)
     0x0000000000010744 <+20>:    addi    sp,sp,16
     0x0000000000010746 <+22>:    ret                  // 唯一出口
     ...
     0x0000000000010750 <+32>:    j       0x10742 <flap+18>

  (gdb) disassemble flip
  Dump of assembler code for function flip:
     0x0000000000010752 <+0>:     addi    sp,sp,-16    // 唯一入口
     0x0000000000010754 <+2>:     sd      ra,8(sp)
     ...
     0x0000000000010764 <+18>:    ld      ra,8(sp)
     0x0000000000010766 <+20>:    addi    sp,sp,16
     0x0000000000010768 <+22>:    ret                  // 唯一出口
     ...
     0x0000000000010772 <+32>:    j       0x10764 <flip+18>
  End of assembler dump.
  ```)

  启动这个程序，在运行的时候的某个状态将其打断。此时的 `pc`, `sp`, `ra` 寄存器的值如下所示。此外，下面还给出了栈顶的部分内容。（为阅读方便，栈上的一些未初始化的垃圾数据用 `???` 代替。）

  #fancy-raw(```
  (gdb) p $pc
  $1 = (void (*)()) 0x10752 <flip>

  (gdb) p $sp
  $2 = (void *) 0x40007f1310

  (gdb) p $ra
  $3 = (void (*)()) 0x10742 <flap+18>

  (gdb) x/6a $sp
  0x40007f1310:   ???     0x10750 <flap+32>
  0x40007f1320:   ???     0x10772 <flip+32>
  0x40007f1330:   ???     0x10764 <flip+18>
  ```)

  根据给出这些信息，调试器可以如何复原出最顶层的几个调用栈信息？假设调试器可以理解编译器生成的汇编代码。
][
  #set raw(lang: "rvasm")

  首先认识到两个函数的栈帧大小都是 16，而 `ra` 总是临时保存在 `sp + 8` 指向处。

  看了好久才理解原来 `???` 是可能的 `sp` 值指向处，而有意义的值都是可能的 `sp + 8` 指向处。

  + `pc` 指向 `flip` 的开头，因此 `[0] flip`。
  + `ra` 指向 `<flap+18>`，因此 `[1] flap`。
  + 此时 `sp` 还未被修改，指向 `[1]` 的栈帧。返回地址储存在 `sp + 8` 中，即 `<flap+32>`，因此 `[2] flap`。
  + 往回倒一个栈帧，`sp` 指向 `[2]` 的栈帧。返回地址储存在 `sp + 8` 中，即 `<flip+32>`，因此 `[3] flip`。
  + 再倒一个栈帧，`sp` 指向 `[3]` 的栈帧。返回地址储存在 `sp + 8` 中，即 `<flip+18>`，因此 `[4] flip`。

  因此，根据给出的信息，我们可以复原出最顶层的 5 层调用信息。如果我们能够操作 gdb，那么可以通过查看调用栈内的内容复原整个调用栈，而不必须用到 `bt` 命令。
]

#set heading(numbering: "A.1 ")
#show heading.where(level: 1): set heading(numbering: "附录 A ")
#counter(heading).update(())

= 文档使用到的其他材料

- RISC-V 汇编语法高亮规则 #link("https://github.com/fabianschuiki/sublime-riscv-assembly/blob/master/riscv-asm.sublime-syntax")[riscv-asm.sublime-syntax]（有修改）
