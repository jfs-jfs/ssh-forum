#include <stdio.h>
#include <inttypes.h>

/*
 * Adds forwards a forward slash to the end line character to be saved to the database
 * Version 0.2
 * Previoius version can be found in: https://github.com/analogcity/utils
 * 333-9 colabored to this
 *
 */

enum {
    Mark = '\n',
};


int main(int argc, char *argv[])
{
    if (argc != 2) return 1;
    char *s =  argv[1];

    for (;;s++) {
        if (*s == Mark) {
            fputs("\\\\n", stdout);
        } else  if (*s) {
            putc(*s, stdout);
        } else {
            break;
        };
    }
    return 0;
}