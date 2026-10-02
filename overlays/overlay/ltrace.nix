final: prev: {
  # ltrace 0.7.91 的测试套件在 Nix 构建沙箱里跑不过(用例需要 ptrace 权限,
  # 15 个 unexpected failures → checkPhase 失败)。工具本身可用,
  # 按 openldap.nix 的同类做法跳过 check。
  ltrace = prev.ltrace.overrideAttrs {
    doCheck = false;
  };
}
