#include <stdio.h>
#include <conio.h>

int foo();

int main() {
	int i;
	printf("hello, ");
	i = foo();
	printf("i = %d\n", i);

	cgetc();
	return 0;
}
