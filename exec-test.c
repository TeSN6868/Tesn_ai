#include <unistd.h>
#include <stdio.h>
#include <errno.h>
#include <string.h>

int main(void) {
    char *args[] = {
        "/data/data/com.termux/files/usr/bin/dash",
        "-c",
        "echo EXECVE_DASH_OK",
        NULL
    };

    execv(args[0], args);

    fprintf(stderr, "execv failed: %s\n", strerror(errno));
    return errno;
}
