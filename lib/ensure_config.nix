{ lib, ... }:

/*
  ensureSectionInFile: 确保文件包含某个 section（如 `[Plan/1]`），否则追加
  Args:
    - file: 目标文件路径（如 ".config/kuprc"）
    - section: 要确保存在的 section（如 "[Plan/1]"）
    - defaultContent: （可选）如果 section 不存在，插入的默认内容
  Returns:
    - Home Manager 配置（可直接用于 `imports`）
*/
{ file, section, defaultContent ? "" }:
{
  home.activation.ensureKupSection = lib.hm.dag.entryAfter ["writeBoundary"] ''
    File="${file}"

    # 如果文件不存在，直接创建并写入默认内容
    if [ ! -f "$File" ]; then
      echo -e "${section}\n${defaultContent}" > "$File"
      echo "Created ${file} with default content."
    else
      # 如果文件存在但缺少 section，则追加
      if ! grep -qF "${section}" "$File"; then
        echo -e "\n${section}\n${defaultContent}" >> "$File"
        echo "Appended ${section} to ${file}."
      else
        echo "${section} already exists in ${file}. No changes made."
      fi
    fi
  '';
}
