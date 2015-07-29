//
//  UnixHelpers.c
//  Sock
//
//  Created by Rasmus Kildevæld   on 29/07/15.
//  Copyright © 2015 Rasmus Kildevæld  . All rights reserved.
//


#include <fcntl.h>
#include <sys/ioctl.h>

int ari_fcntlVi(int fildes, int cmd, int val) {
    return fcntl(fildes, cmd, val);
}

int ari_ioctlVip(int fildes, unsigned long request, int *val) {
    return ioctl(fildes, request, val);
}
