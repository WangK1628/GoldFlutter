#ifndef RUNNER_PATH_MIRROR_H_
#define RUNNER_PATH_MIRROR_H_

#include <string>

namespace PathMirror {

// True when command line contains --mirrored-runtime.
bool IsMirroredRuntime();

// True when the path contains non-ASCII characters.
bool PathHasNonAscii(const std::wstring& path);

// Copy install dir to %LOCALAPPDATA%\GoldMonitor\runtime and start mirror exe.
// Returns true when a detached child was launched and caller should exit.
bool RelaunchFromAsciiMirror(const std::wstring& exe_path);

}  // namespace PathMirror

#endif  // RUNNER_PATH_MIRROR_H_
