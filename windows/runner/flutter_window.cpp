#include "flutter_window.h"

#include <UIAutomation.h>
#include <flutter/standard_method_codec.h>
#include <oleauto.h>
#include <windows.h>

#include <optional>
#include <string>

#include "flutter/generated_plugin_registrant.h"
#include "utils.h"

namespace {

std::optional<std::string> ReadSelectedText() {
  IUIAutomation *automation = nullptr;
  if (FAILED(CoCreateInstance(CLSID_CUIAutomation, nullptr,
                              CLSCTX_INPROC_SERVER,
                              IID_PPV_ARGS(&automation)))) {
    return std::nullopt;
  }

  IUIAutomationElement *focused = nullptr;
  HRESULT result = automation->GetFocusedElement(&focused);
  if (FAILED(result) || focused == nullptr) {
    automation->Release();
    return std::nullopt;
  }

  IUIAutomationTextPattern *text_pattern = nullptr;
  result = focused->GetCurrentPatternAs(UIA_TextPatternId,
                                        IID_PPV_ARGS(&text_pattern));
  focused->Release();
  automation->Release();
  if (FAILED(result) || text_pattern == nullptr) {
    return std::nullopt;
  }

  SAFEARRAY *ranges = nullptr;
  result = text_pattern->GetSelection(&ranges);
  text_pattern->Release();
  if (FAILED(result) || ranges == nullptr) {
    return std::nullopt;
  }

  LONG lower = 0;
  LONG upper = -1;
  SafeArrayGetLBound(ranges, 1, &lower);
  SafeArrayGetUBound(ranges, 1, &upper);
  std::wstring selected;
  for (LONG index = lower; index <= upper; ++index) {
    IUIAutomationTextRange *range = nullptr;
    if (SUCCEEDED(SafeArrayGetElement(ranges, &index, &range)) &&
        range != nullptr) {
      BSTR text = nullptr;
      if (SUCCEEDED(range->GetText(-1, &text)) && text != nullptr) {
        selected.append(text, SysStringLen(text));
        SysFreeString(text);
      }
      range->Release();
    }
  }
  SafeArrayDestroy(ranges);

  if (selected.find_first_not_of(L" \t\r\n") == std::wstring::npos) {
    return std::nullopt;
  }
  return Utf8FromUtf16(selected);
}

std::optional<std::string> ReadFrontmostApplication() {
  HWND foreground = GetForegroundWindow();
  if (foreground == nullptr) {
    return std::nullopt;
  }

  DWORD process_id = 0;
  GetWindowThreadProcessId(foreground, &process_id);
  HANDLE process =
      OpenProcess(PROCESS_QUERY_LIMITED_INFORMATION, FALSE, process_id);
  if (process == nullptr) {
    return std::nullopt;
  }

  std::wstring path(32768, L'\0');
  DWORD length = static_cast<DWORD>(path.size());
  const BOOL read =
      QueryFullProcessImageNameW(process, 0, path.data(), &length);
  CloseHandle(process);
  if (!read || length == 0) {
    return std::nullopt;
  }

  path.resize(length);
  const size_t slash = path.find_last_of(L"\\/");
  std::wstring name =
      slash == std::wstring::npos ? path : path.substr(slash + 1);
  const size_t extension = name.find_last_of(L'.');
  if (extension != std::wstring::npos) {
    name.resize(extension);
  }
  return name.empty() ? std::nullopt
                      : std::optional<std::string>(Utf8FromUtf16(name));
}

bool IsUiAutomationAvailable() {
  IUIAutomation *automation = nullptr;
  const HRESULT result =
      CoCreateInstance(CLSID_CUIAutomation, nullptr, CLSCTX_INPROC_SERVER,
                       IID_PPV_ARGS(&automation));
  if (automation != nullptr) {
    automation->Release();
  }
  return SUCCEEDED(result);
}

} // namespace

FlutterWindow::FlutterWindow(const flutter::DartProject &project)
    : project_(project) {}

FlutterWindow::~FlutterWindow() {}

bool FlutterWindow::OnCreate() {
  if (!Win32Window::OnCreate()) {
    return false;
  }

  RECT frame = GetClientArea();

  // The size here must match the window dimensions to avoid unnecessary surface
  // creation / destruction in the startup path.
  flutter_controller_ = std::make_unique<flutter::FlutterViewController>(
      frame.right - frame.left, frame.bottom - frame.top, project_);
  // Ensure that basic setup of the controller was successful.
  if (!flutter_controller_->engine() || !flutter_controller_->view()) {
    return false;
  }
  RegisterPlugins(flutter_controller_->engine());

  selection_capture_channel_ =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          flutter_controller_->engine()->messenger(),
          "laterbox/selection_capture",
          &flutter::StandardMethodCodec::GetInstance());
  selection_capture_channel_->SetMethodCallHandler(
      [](const flutter::MethodCall<flutter::EncodableValue> &call,
         std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>>
             result) {
        if (call.method_name() == "readSelectedText") {
          const auto value = ReadSelectedText();
          value ? result->Success(flutter::EncodableValue(*value))
                : result->Success();
        } else if (call.method_name() == "readFrontmostApplication") {
          const auto value = ReadFrontmostApplication();
          value ? result->Success(flutter::EncodableValue(*value))
                : result->Success();
        } else if (call.method_name() == "isAccessibilityTrusted") {
          result->Success(flutter::EncodableValue(IsUiAutomationAvailable()));
        } else {
          result->NotImplemented();
        }
      });
  SetChildContent(flutter_controller_->view()->GetNativeWindow());

  flutter_controller_->engine()->SetNextFrameCallback([&]() { this->Show(); });

  // Flutter can complete the first frame before the "show window" callback is
  // registered. The following call ensures a frame is pending to ensure the
  // window is shown. It is a no-op if the first frame hasn't completed yet.
  flutter_controller_->ForceRedraw();

  return true;
}

void FlutterWindow::OnDestroy() {
  selection_capture_channel_.reset();
  if (flutter_controller_) {
    flutter_controller_ = nullptr;
  }

  Win32Window::OnDestroy();
}

LRESULT
FlutterWindow::MessageHandler(HWND hwnd, UINT const message,
                              WPARAM const wparam,
                              LPARAM const lparam) noexcept {
  // Give Flutter, including plugins, an opportunity to handle window messages.
  if (flutter_controller_) {
    std::optional<LRESULT> result =
        flutter_controller_->HandleTopLevelWindowProc(hwnd, message, wparam,
                                                      lparam);
    if (result) {
      return *result;
    }
  }

  switch (message) {
  case WM_FONTCHANGE:
    flutter_controller_->engine()->ReloadSystemFonts();
    break;
  }

  return Win32Window::MessageHandler(hwnd, message, wparam, lparam);
}
