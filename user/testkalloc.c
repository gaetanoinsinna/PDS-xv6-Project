#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"


int

main(int argc, char *argv[])

{
    printf("Free pages before allocating:%d\n",freepages());
    testkalloc();
    printf("Allocating a page...\n");
    printf("Free pages after allocating:%d\n",freepages());
    
    exit(0);

}