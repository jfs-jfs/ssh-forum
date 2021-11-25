// vim: expandtab
#include <stdio.h>
#include <stdbool.h>
#include <ctype.h>

/*
 * Find expressions matching /#[0-9]{1,4}/ (#44) and replace them for
 *  - \Zb\Z5#44\Zn
 *
 * Version 0.3
 * Previoius version can be found in: https://github.com/analogcity/utils
 * 333-9 colabored to this
 *
 */

enum {
    Mark = '#'
};

char buf[5];

int
main(int argc, char *argv[])
{
    if (argc != 2) return 1;
    char *s = argv[1];
    int i;

    for (;;) {
        if (*s == Mark) {
            for (s += 1, i = 0; isdigit(*s); s++, i++) {
                if (i >= sizeof(buf) -1) break;
                buf[i] = *s;
            };
            buf[i] = 0;
            if (i < 1) {
                putc(Mark, stdout);
                continue;
            };
            fprintf(stdout, "\\Z5\\Zb%c%s\\Zn", Mark, buf);
        } else if (*s) {
            putc(*s++, stdout);
        } else
            break;
    }
    return 0;
}