/*
 * GstarCAD 2027 spdlog 空日志路径修复
 *
 * 背景:浩辰CAD 授权流程 GcLogger::init 会 fopen("", "ab") 打开空路径,
 * 在 Kylin 上该路径有值,在 NixOS 上为空 → 抛 spdlog::spdlog_ex 崩溃退出。
 * 此 .so 拦截 fopen,把空路径重定向到用户可写日志文件,使程序能正常启动。
 */
#define _GNU_SOURCE
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <dlfcn.h>
#include <unistd.h>
#include <sys/types.h>
#include <pwd.h>

static FILE *(*real_fopen)(const char *, const char *) = NULL;

static const char *fallback_path(void) {
  static char path[1024];
  const char *home = getenv("HOME");
  if (!home || !*home) {
    struct passwd *pw = getpwuid(getuid());
    home = pw ? pw->pw_dir : "/tmp";
  }
  snprintf(path, sizeof(path), "%s/gcadlog/gcad-empty.log", home);
  return path;
}

FILE *fopen(const char *path, const char *mode) {
  if (!real_fopen)
    real_fopen = dlsym(RTLD_NEXT, "fopen");

  if (path == NULL || path[0] == '\0') {
    const char *fb = fallback_path();
    FILE *f = real_fopen(fb, mode);
    return f;
  }
  return real_fopen(path, mode);
}