#include <stdio.h>
#include <unistd.h>


int main()
{
	int pid = fork();
	for (int i=0; i<10; i++)
		if(pid)
	printf("Mine PID: %d\nParental PID: %d\n", getpid(), getppid());
	fork();
	sleep(5);
	return 0;
}
