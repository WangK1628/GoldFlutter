#include "path_mirror.h"

#include <shlobj.h>
#include <stdio.h>
#include <windows.h>

#include <vector>

namespace {

constexpr wchar_t kMirroredFlag[] = L"--mirrored-runtime";
constexpr wchar_t kMirrorSubdir[] = L"GoldMonitor\\runtime";

std::wstring Dirname(const std::wstring& file_path) {
  const size_t pos = file_path.find_last_of(L"\\/");
  if (pos == std::wstring::npos) {
    return file_path;
  }
  return file_path.substr(0, pos);
}

std::wstring Basename(const std::wstring& file_path) {
  const size_t pos = file_path.find_last_of(L"\\/");
  if (pos == std::wstring::npos) {
    return file_path;
  }
  return file_path.substr(pos + 1);
}

std::wstring JoinPath(const std::wstring& a, const std::wstring& b) {
  if (a.empty()) {
    return b;
  }
  if (a.back() == L'\\' || a.back() == L'/') {
    return a + b;
  }
  return a + L"\\" + b;
}

bool CommandLineHasFlag(const wchar_t* flag) {
  int argc = 0;
  wchar_t** argv = ::CommandLineToArgvW(::GetCommandLineW(), &argc);
  if (!argv) {
    return false;
  }
  bool found = false;
  for (int i = 0; i < argc; ++i) {
    if (wcscmp(argv[i], flag) == 0) {
      found = true;
      break;
    }
  }
  ::LocalFree(argv);
  return found;
}

std::wstring MirrorRoot() {
  wchar_t app_data[MAX_PATH];
  if (FAILED(SHGetFolderPathW(nullptr, CSIDL_LOCAL_APPDATA, nullptr,
                              SHGFP_TYPE_CURRENT, app_data))) {
    return L"";
  }
  return JoinPath(app_data, kMirrorSubdir);
}

bool RunRobocopy(const std::wstring& src, const std::wstring& dst) {
  wchar_t command_line[32768];
  swprintf_s(
      command_line, 32768,
      L"cmd.exe /c robocopy \"%s\" \"%s\" /E /IS /IT /NJH /NJS /NFL /NDL "
      L"/NC /NS /NP",
      src.c_str(), dst.c_str());

  STARTUPINFOW startup_info{};
  startup_info.cb = sizeof(startup_info);
  PROCESS_INFORMATION process_info{};

  if (!::CreateProcessW(nullptr, command_line, nullptr, nullptr, FALSE,
                        CREATE_NO_WINDOW, nullptr, nullptr, &startup_info,
                        &process_info)) {
    return false;
  }

  ::WaitForSingleObject(process_info.hProcess, INFINITE);
  DWORD exit_code = 1;
  ::GetExitCodeProcess(process_info.hProcess, &exit_code);
  ::CloseHandle(process_info.hProcess);
  ::CloseHandle(process_info.hThread);

  // Robocopy uses bit flags for success: 0-7 are OK.
  return exit_code < 8;
}

bool LaunchDetached(const std::wstring& exe_path,
                    const std::wstring& working_dir) {
  std::wstring command_line = L"\"" + exe_path + L"\" " + kMirroredFlag;

  STARTUPINFOW startup_info{};
  startup_info.cb = sizeof(startup_info);
  PROCESS_INFORMATION process_info{};

  std::vector<wchar_t> mutable_command(command_line.begin(),
                                       command_line.end());
  mutable_command.push_back(L'\0');

  if (!::CreateProcessW(nullptr, mutable_command.data(), nullptr, nullptr,
                        FALSE, DETACHED_PROCESS | CREATE_UNICODE_ENVIRONMENT,
                        nullptr, working_dir.c_str(), &startup_info,
                        &process_info)) {
    return false;
  }

  ::CloseHandle(process_info.hProcess);
  ::CloseHandle(process_info.hThread);
  return true;
}

}  // namespace

namespace PathMirror {

bool IsMirroredRuntime() {
  return CommandLineHasFlag(kMirroredFlag);
}

bool PathHasNonAscii(const std::wstring& path) {
  for (wchar_t ch : path) {
    if (static_cast<unsigned int>(ch) > 127) {
      return true;
    }
  }
  return false;
}

bool RelaunchFromAsciiMirror(const std::wstring& exe_path) {
  const std::wstring src_dir = Dirname(exe_path);
  const std::wstring exe_name = Basename(exe_path);
  const std::wstring dst_dir = MirrorRoot();
  if (dst_dir.empty()) {
    return false;
  }

  wchar_t app_data[MAX_PATH];
  if (FAILED(SHGetFolderPathW(nullptr, CSIDL_LOCAL_APPDATA, nullptr,
                              SHGFP_TYPE_CURRENT, app_data))) {
    return false;
  }
  ::CreateDirectoryW(JoinPath(app_data, L"GoldMonitor").c_str(), nullptr);
  ::CreateDirectoryW(dst_dir.c_str(), nullptr);

  if (!RunRobocopy(src_dir, dst_dir)) {
    return false;
  }

  const std::wstring dst_exe = JoinPath(dst_dir, exe_name);
  if (::GetFileAttributesW(dst_exe.c_str()) == INVALID_FILE_ATTRIBUTES) {
    return false;
  }

  return LaunchDetached(dst_exe, dst_dir);
}

}  // namespace PathMirror
