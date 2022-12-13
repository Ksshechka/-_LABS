#include <stdio.h>

extern char **environ;
int main(int argc, char *argv[])
{
	char **p = environ;
	for (;*p && p-environ < 10; p++)
		printf("[%d] %s\n", p-environ, *p);
	return 0;
}
