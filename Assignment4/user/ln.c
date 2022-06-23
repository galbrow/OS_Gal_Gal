#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"

int
main(int argc, char *argv[])
{
  if(argc != 3 && (argc != 4 || (argc == 4 && strcmp(argv[1],"-s") != 0 ))){
    fprintf(2, "Usage: ln old new\n");
    exit(1);
  }
  if(argc == 3) {
      if (link(argv[1], argv[2]) < 0)
          fprintf(2, "link %s %s: failed\n", argv[1], argv[2]);
  }
  if (argc == 4) {
      printf("-------------\nin ls -s %s %s\n",argv[2],argv[3]);
      //TODO: verify argv indexs && check about symlink function
      if(symlink(argv[2],argv[3]) < 0){
          fprintf(2, "link -s %s %s: failed\n", argv[2], argv[3]);
      }
  }
  exit(0);
}
