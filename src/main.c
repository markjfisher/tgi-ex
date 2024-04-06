#include <stdio.h>
#include <conio.h>

int foo();
int bar();

int main() {
	int i;
	printf("hello, ");
	i = foo();
	printf("i = %d\n", i);
	i = bar();
	printf("i = %d\n", i);

	cgetc();
	return 0;
}
