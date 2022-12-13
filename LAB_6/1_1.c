#include <stdio.h>

extern char **environ;
int main(int argc, char *argv[])
{
	int a =0;
	char **p = environ;
	while (*p++)
		a++;
	printf("Number of env var: %d\n", a);
	return 0;
}
