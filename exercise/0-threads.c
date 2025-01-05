#include <pthread.h>
#include <stdio.h>
#include <unistd.h>

const int NUM_THREADS = 5;

void *worker(void *arg) {
  int thread_id = *(int *)arg;

  printf("Thread %d is reading file...\n", thread_id);
  sleep(2);

  FILE *fp = fopen("0-threads-c.txt", "a");
  if (!fp) {
    perror("fopen");
    return NULL;
  }

  fprintf(fp, "Thread %d wrote this message.\n", thread_id);
  fclose(fp);

  return NULL;
}

int main(void) {
  pthread_t threads[NUM_THREADS];
  int thread_ids[NUM_THREADS];

  for (int i = 0; i < NUM_THREADS; i++) {
    thread_ids[i] = i;
    pthread_create(&threads[i], NULL, worker, (void *)&thread_ids[i]);
  }

  puts("Main thread doing some work asynchronously...");

  for (int i = 0; i < NUM_THREADS; i++)
    pthread_join(threads[i], NULL);

  puts("All threads have finished their work.");
}
