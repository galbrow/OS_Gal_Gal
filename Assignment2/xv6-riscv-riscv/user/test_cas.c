//
// Created by os on 5/4/22.
//
#include "kernel/param.h"
#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"
#include "kernel/fs.h"
#include "kernel/fcntl.h"
#include "kernel/syscall.h"
#include "kernel/memlayout.h"
#include "kernel/riscv.h"

int main(int argc, char* argv[]){
    printf("main");
//    int pid, pid1;
//    pid = fork();
//
//    if (pid != 0)
//        printf("0");
////        printf("pid: %d\n", pid);
//
//    pid1 = fork();
//    if (pid1 != 0)
//        printf("0");
//        printf("pid: %d\n", pid1);

//    struct proc arr[3];

//    printf("%d\n", &arr[2] - &arr[0]);
    return 0;
};