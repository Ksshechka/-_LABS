#include <stdio.h>
#include <stdlib.h>

extern char **environ;
int main(int argc, char *argv[])
{
	
	char **p;
	for (p=environ; *p && p-environ < atoi(argv[1]); p++)
		printf(" %s\n", *p);
	return 0;
}
