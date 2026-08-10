#include <unistd.h>
#include <stdio.h>
#include <stdlib.h>

int main(int argc, char **argv) {
    const char *proot =
        "/data/data/com.termux/files/usr/bin/proot";

    const char *box64 = "/usr/bin/box64";

    char **args = calloc(argc + 32, sizeof(char *));
    if (!args) {
        perror("calloc");
        return 1;
    }

    int n = 0;

    args[n++] = (char *)proot;
    args[n++] = "--kill-on-exit";
    args[n++] = "--link2symlink";
    args[n++] = "--sysvipc";
    args[n++] = "--change-id=0:0";

    args[n++] =
        "--rootfs=/data/data/com.termux/files/usr/var/lib/proot-distro/containers/ubuntu/rootfs";

    args[n++] = "--cwd=/root";

    args[n++] = "--bind=/dev";
    args[n++] = "--bind=/proc";
    args[n++] = "--bind=/sys";
    args[n++] = "--bind=/dev/urandom:/dev/random";

    args[n++] = "--bind=/proc/self/fd:/dev/fd";
    args[n++] = "--bind=/proc/self/fd/0:/dev/stdin";
    args[n++] = "--bind=/proc/self/fd/1:/dev/stdout";
    args[n++] = "--bind=/proc/self/fd/2:/dev/stderr";

    /*
     * Make the x86_64 NDK directory visible inside Ubuntu.
     */
    args[n++] =
        "--bind=/data/data/com.termux/files/home/android-sdk/ndk/28.2.13676358/toolchains/llvm/prebuilt/linux-x86_64:/opt/ndk";

    args[n++] = "/bin/bash";
    args[n++] = "-c";

    char *cmd = calloc(8192, 1);
    if (!cmd) {
        perror("calloc");
        return 1;
    }

    int pos = snprintf(
        cmd,
        8192,
        "unset LD_PRELOAD; "
        "exec %s /opt/ndk/bin/lld.real",
        box64
    );

    for (int i = 1; i < argc && pos < 8100; i++) {
        pos += snprintf(
            cmd + pos,
            8192 - pos,
            " '%s'",
            argv[i]
        );
    }

    args[n++] = cmd;
    args[n] = NULL;

    unsetenv("LD_PRELOAD");

    execv(proot, args);

    perror("execv");
    return 127;
}
