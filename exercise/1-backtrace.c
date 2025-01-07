#include <execinfo.h>
#include <stdio.h>
#include <stdlib.h>

void print_call_stack(void) {
  void *buffer[100];
  int nptrs = backtrace(buffer, 100);
  char **strings = backtrace_symbols(buffer, nptrs);
  if (!strings) {
    perror("backtrace_symbols");
    exit(EXIT_FAILURE);
  }

  for (int i = 0; i < nptrs; ++i)
    puts(strings[i]);

  free(strings);
}

void func3(void) {
  print_call_stack();
}

void func2(void) {
  func3();
}

void func1(void) {
  func2();
}

int main(void) {
  func1();
}
