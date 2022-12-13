#include <stdio.h>
#include <unistd.h>


int main()
{
	int pid = fork();
	if (!pid)
		printf("Mine PID: %d\nParental PID: %d\n", getpid(), getppid());
	return 0;
}
