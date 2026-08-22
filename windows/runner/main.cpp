#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <windows.h>

#include <exception>
#include <string>
#include <vector>

#include "flutter_window.h"
#include "utils.h"

namespace {

Win32Window::Size ProfileViewportFromArguments(
    const std::vector<std::string>& arguments) {
  constexpr char kPrefix[] = "--battle-profile-viewport=";
  for (const auto& argument : arguments) {
    if (argument.rfind(kPrefix, 0) != 0) {
      continue;
    }
    const std::string value = argument.substr(sizeof(kPrefix) - 1);
    const size_t separator = value.find('x');
    if (separator == std::string::npos) {
      continue;
    }
    try {
      const int width = std::stoi(value.substr(0, separator));
      const int height = std::stoi(value.substr(separator + 1));
      if (width > 0 && height > 0 &&
          value == std::to_string(width) + "x" + std::to_string(height)) {
        return Win32Window::Size(width, height);
      }
    } catch (const std::exception&) {
      continue;
    }
  }
  return Win32Window::Size(1280, 720);
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

  flutter::DartProject project(L"data");

  std::vector<std::string> command_line_arguments =
      GetCommandLineArguments();
  const Win32Window::Size size =
      ProfileViewportFromArguments(command_line_arguments);

  project.set_dart_entrypoint_arguments(std::move(command_line_arguments));

  FlutterWindow window(project);
  Win32Window::Point origin(10, 10);
  if (!window.Create(L"wuxia_idle", origin, size)) {
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
