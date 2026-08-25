#include <unistd.h>
#include <stdio.h>

int main(int argc, char **argv) {
    const char *proot_distro =
        "/data/data/com.termux/files/usr/bin/proot-distro";

    char *args[] = {
        (char *)proot_distro,
        "login",
        "ubuntu",
        "--",
        "/bin/bash",
        "-c",
        "echo PROOT_FROM_LAUNCHER_OK; /usr/bin/box64 --version",
        NULL
    };

    execv(proot_distro, args);
    perror("execv");
    return 127;
}
