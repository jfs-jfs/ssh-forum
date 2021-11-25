// vim: expandtab
#include <stdio.h>
#include <stdbool.h>

/*
 * Find lines that match /^>.*$/ and wrap them in:
 *  - \Z2\Zb>  \Zn
 *
 * Version 0.3
 * Previoius version can be found in: https://github.com/analogcity/utils
 * 333-9 colabored to this
 *
 */


const char *beg = "\\Z2\\Zb>";
const char *end = "\\Zn";



enum {
    Mark    = '>',
    Newline = '\n',
};


int
main(int argc, char *argv[])
{
    if (argc != 2) return 1;
    char *s = argv[1];
    bool green = 0;

    if (*s == Mark) {
        s += 1;
        green = 1;
        fputs(beg, stdout);
    };
    for (;;) {
        if (*s == Newline) {
            if (green) {
                green = 0;
                fputs(end, stdout);
            };
            putc(Newline, stdout);
            if (*++s == Mark) {
                green = 1;
                fputs(beg, stdout);
                for (s += 1; *s != Newline && *s; s += 1) {
                    putc(*s, stdout);
                }
            };
            continue;
        };
        if (*s) {
            putc(*s++, stdout);
        } else {
            if (green)
                fputs(end, stdout);
            //putc(Newline, stdout); // trailing newline
            return 0;
        };
    };
}