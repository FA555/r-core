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
