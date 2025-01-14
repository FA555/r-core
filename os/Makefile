# Building
TARGET := riscv64gc-unknown-none-elf
MODE := release
KERNEL := target/$(TARGET)/$(MODE)/os
DISASM_TMP := target/$(TARGET)/$(MODE)/asm

# Building mode argument
ifeq ($(MODE), release)
	MODE_ARG := --release
endif

# BOARD
BOARD := qemu
SBI ?= rustsbi
BOOTLOADER := ../bootloader/$(SBI)-$(BOARD).bin

# KERNEL ENTRY
KERNEL_ENTRY_PA := 0x80200000

# Binutils
OBJDUMP := rust-objdump --arch-name=riscv64
GDB := riscv64-elf-gdb

# Disassembly
DISASM ?= -x

# QEMU
QEMU_ARGS := -machine virt \
			 -nographic \
			 -bios $(BOOTLOADER) \
			 -device loader,file=$(KERNEL),addr=$(KERNEL_ENTRY_PA)

QEMU := qemu-system-riscv64

dependencies:
	(rustup target list | grep "riscv64gc-unknown-none-elf (installed)") || rustup target add $(TARGET)
	cargo install cargo-binutils
	rustup component add rust-src
	rustup component add llvm-tools-preview

build:
	@echo Platform: $(BOARD)
	@cp src/linker-$(BOARD).ld src/linker.ld
	@cargo build $(MODE_ARG)
	@rm src/linker.ld

disasm: build
	@$(OBJDUMP) $(DISASM) $(KERNEL) | less

disasm-vim: build
	@$(OBJDUMP) $(DISASM) $(KERNEL) > $(DISASM_TMP)
	@vim $(DISASM_TMP)
	@rm $(DISASM_TMP)

run: build
	@$(QEMU) $(QEMU_ARGS)

gdbserver: build
	@$(QEMU) $(QEMU_ARGS) -s -S

gdbclient: build
	@$(GDB) -ex 'file $(KERNEL)' -ex 'set arch riscv:rv64' -ex 'target remote localhost:1234'

debug: build
	@tmux new-session -d \
		"$(QEMU) $(QEMU_ARGS) -s -S" && \
		tmux split-window -h "$(GDB) -ex 'file $(KERNEL)' -ex 'set arch riscv:rv64' -ex 'target remote localhost:1234'" && \
		tmux -2 attach-session -d

clean:
	@cargo clean
	@rm -f src/linker.ld

.PHONY: build env kernel clean disasm disasm-vim run gdbserver gdbclient qemu-version-check
