#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <stdio.h>
#include <windows.h>

#include "flutter_window.h"
#include "path_mirror.h"
#include "utils.h"

namespace {

void SetWorkingDirectoryToExecutableDir() {
  wchar_t exe_path[MAX_PATH];
  const DWORD len = ::GetModuleFileNameW(nullptr, exe_path, MAX_PATH);
  if (len == 0 || len >= MAX_PATH) {
    return;
  }
  for (int i = static_cast<int>(len) - 1; i >= 0; --i) {
    if (exe_path[i] == L'\\' || exe_path[i] == L'/') {
      exe_path[i] = L'\0';
      break;
    }
  }
  ::SetCurrentDirectoryW(exe_path);
}

void ShowStartupError(const wchar_t* message) {
  ::MessageBoxW(nullptr, message,
                L"Gold Monitor",
                MB_OK | MB_ICONERROR);
}

bool CheckRuntimeDependencies() {
  wchar_t exe_dir[MAX_PATH];
  const DWORD len = ::GetModuleFileNameW(nullptr, exe_dir, MAX_PATH);
  if (len == 0 || len >= MAX_PATH) {
    return true;
  }
  for (int i = static_cast<int>(len) - 1; i >= 0; --i) {
    if (exe_dir[i] == L'\\' || exe_dir[i] == L'/') {
      exe_dir[i] = L'\0';
      break;
    }
  }

  const wchar_t* required_dlls[] = {
      L"flutter_windows.dll",
      L"window_manager_plugin.dll",
  };

  for (const wchar_t* dll_name : required_dlls) {
    wchar_t dll_path[MAX_PATH];
    swprintf_s(dll_path, MAX_PATH, L"%s\\%s", exe_dir, dll_name);
    HMODULE module = ::LoadLibraryW(dll_path);
    if (!module) {
      const DWORD err = ::GetLastError();
      if (err == ERROR_MOD_NOT_FOUND || err == ERROR_DLL_NOT_FOUND) {
        ShowStartupError(
            L"Missing runtime files or VC++ redistributable.\n\n"
            L"Install VC++ 2015-2022 x64 from:\n"
            L"https://aka.ms/vs/17/release/vc_redist.x64.exe");
      } else {
        wchar_t msg[512];
        swprintf_s(
            msg, 512,
            L"Failed to load %s (error %lu).\n\n"
            L"Try running GoldMonitor.bat or move the app to D:\\GoldMonitor.",
            dll_name, err);
        ShowStartupError(msg);
      }
      return false;
    }
    ::FreeLibrary(module);
  }
  return true;
}

}  // namespace

int APIENTRY wWinMain(_In_ HINSTANCE instance, _In_opt_ HINSTANCE prev,
                      _In_ wchar_t *command_line, _In_ int show_command) {
  // Attach to console when present (e.g., 'flutter run') or create a
  // new console when running with a debugger.
  if (!::AttachConsole(ATTACH_PARENT_PROCESS) && ::IsDebuggerPresent()) {
    CreateAndAttachConsole();
  }

  // Initialize COM, so that it is available for use in the library and/or
  // plugins.
  ::CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);

  wchar_t exe_path[MAX_PATH];
  const DWORD exe_len = ::GetModuleFileNameW(nullptr, exe_path, MAX_PATH);
  if (exe_len > 0 && exe_len < MAX_PATH && !PathMirror::IsMirroredRuntime() &&
      PathMirror::PathHasNonAscii(exe_path)) {
    if (PathMirror::RelaunchFromAsciiMirror(exe_path)) {
      return EXIT_SUCCESS;
    }
    ShowStartupError(
        L"Cannot start from a folder path that contains Chinese or other "
        L"non-ASCII characters.\n\n"
        L"Please run GoldMonitor.bat, or move the app to D:\\GoldMonitor.");
    return EXIT_FAILURE;
  }

  SetWorkingDirectoryToExecutableDir();

  if (!CheckRuntimeDependencies()) {
    return EXIT_FAILURE;
  }

  flutter::DartProject project(L"data");

  std::vector<std::string> command_line_arguments =
      GetCommandLineArguments();

  project.set_dart_entrypoint_arguments(std::move(command_line_arguments));

  FlutterWindow window(project);
  Win32Window::Point origin(10, 10);
  Win32Window::Size size(1280, 720);
  if (!window.Create(L"gold_monitor", origin, size)) {
    ShowStartupError(L"Failed to create window. Try moving the app to an English-only path such as D:\\GoldMonitor.");
    return EXIT_FAILURE;
  }
  window.SetQuitOnClose(true);

  ::MSG msg;
  while (::GetMessage(&msg, nullptr, 0, 0)) {
    ::TranslateMessage(&msg);
    ::DispatchMessage(&msg);
  }

  ::CoUninitialize();
  return EXIT_SUCCESS;
}
