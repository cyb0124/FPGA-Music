#ifndef _FD_GUARD_H_
#define _FD_GUARD_H_
#include <unistd.h>
#include <utility>

// Scope guard for file descriptor
// Author: Yibo Cao

struct FDGuard {
  int fd;

  FDGuard(int fd) :fd(fd) {}
  FDGuard(const FDGuard&) = delete;
  FDGuard &operator=(const FDGuard&) = delete;

  int release() {
    int result;
    std::swap(result, fd);
    return result;
  }

  ~FDGuard() {
    if (fd >= 0)
      close(fd);
  }
};

#endif
