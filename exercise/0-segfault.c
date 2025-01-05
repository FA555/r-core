#include <stdio.h>

int main(void) {
  puts("Before segmentation fault");
  int *p = NULL;
  *p = 114;
  puts("After segmentation fault");
}
