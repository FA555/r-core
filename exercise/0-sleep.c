#include <stdio.h>
#include <unistd.h>

int main(void) {
  sleep(5);

  const char *message = "Hello from C after 5 seconds!\n";

  puts(message);

  FILE *fp = fopen("0-sleep-c.txt", "w");
  if (!fp) {
    perror("fopen");
    return 1;
  }

  fputs(message, fp);
  fclose(fp);
}
