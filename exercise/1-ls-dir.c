#include <dirent.h>
#include <stdio.h>
#include <stdlib.h>

int main(void) {
  DIR *d = opendir(".");
  if (!d) {
    perror("opendir");
    return EXIT_FAILURE;
  }

  for (struct dirent *dir; (dir = readdir(d));)
    puts(dir->d_name);

  closedir(d);
}
