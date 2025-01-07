OUTPUT_ARCH(riscv)

ENTRY(_start)

BASE_ADDRESS = 0x80200000;

SECTIONS
{
    . = BASE_ADDRESS;

    s_kernel = .;

    s_text = .;
    .text : {
        *(.text.entry)
        *(.text .text.*)
    }
    . = ALIGN(4K);
    e_text = .;

    s_rodata = .;
    .rodata : {
        *(.rodata .rodata.*)
        *(.s_rodata .s_rodata.*)
    }
    . = ALIGN(4K);
    e_rodata = .;

    s_data = .;
    .data : {
        *(.data .data.*)
        *(.s_data .s_data.*)
    }
    . = ALIGN(4K);
    e_data = .;

    .bss : {
        *(.bss.stack)
        s_bss = .;
        *(.bss .bss.*)
        *(.s_bss .s_bss.*)
    }
    . = ALIGN(4K);
    e_bss = .;

    e_kernel = .;

    /DISCARD/ : {
        *(.eh_frame)
    }
}
