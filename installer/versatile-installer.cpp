// Versatile Language Suite — Unified Installer
// Modern native Win32 GUI installer (VS 2022 dark theme)
// Installs: Verslang compiler, Versscript runtime, VS Code extensions
// Supports: Fresh install, update, uninstall, ZIP package import
//
// Build: cl /std:c++20 /EHsc /O2 /DUNICODE /D_UNICODE /DNOMINMAX
//        versatile-installer.cpp /Fe:VersatileSetup.exe /link /SUBSYSTEM:WINDOWS
//        user32.lib gdi32.lib shell32.lib ole32.lib advapi32.lib comctl32.lib
//        dwmapi.lib shlwapi.lib uuid.lib comdlg32.lib

#ifndef UNICODE
#define UNICODE
#endif
#ifndef _UNICODE
#define _UNICODE
#endif
#define WIN32_LEAN_AND_MEAN
#ifndef NOMINMAX
#define NOMINMAX
#endif

#include <windows.h>
#include <commctrl.h>
#include <dwmapi.h>
#include <commdlg.h>
#include <shlobj.h>
#include <shlwapi.h>
#include <shellapi.h>
#include <string>
#include <vector>
#include <filesystem>
#include <fstream>
#include <sstream>
#include <functional>
#include <thread>
#include <atomic>

#pragma comment(lib, "user32.lib")
#pragma comment(lib, "gdi32.lib")
#pragma comment(lib, "shell32.lib")
#pragma comment(lib, "ole32.lib")
#pragma comment(lib, "advapi32.lib")
#pragma comment(lib, "comctl32.lib")
#pragma comment(lib, "dwmapi.lib")
#pragma comment(lib, "shlwapi.lib")
#pragma comment(lib, "comdlg32.lib")
#pragma comment(lib, "uuid.lib")
#pragma comment(linker, "/manifestdependency:\"type='win32' name='Microsoft.Windows.Common-Controls' version='6.0.0.0' processorArchitecture='*' publicKeyToken='6595b64144ccf1df' language='*'\"")

namespace fs = std::filesystem;

// ========================= Embedded Resource IDs =========================
// These must match the IDs in installer.rc
#define IDR_VERSLANG_EXE  101
#define IDR_VERSS_EXE     102

// ========================= Theme Colors (VS 2022 Dark) =========================
namespace Theme {
    constexpr COLORREF BgDark       = RGB(30, 30, 30);
    constexpr COLORREF BgPanel      = RGB(37, 37, 38);
    constexpr COLORREF BgCard       = RGB(45, 45, 48);
    constexpr COLORREF BgInput      = RGB(51, 51, 55);
    constexpr COLORREF BgHover      = RGB(62, 62, 66);
    constexpr COLORREF Accent       = RGB(0, 122, 204);
    constexpr COLORREF AccentHover  = RGB(28, 151, 234);
    constexpr COLORREF AccentPress  = RGB(0, 100, 180);
    constexpr COLORREF AccentGreen  = RGB(78, 201, 176);
    constexpr COLORREF AccentOrange = RGB(206, 145, 52);
    constexpr COLORREF AccentPurple = RGB(155, 89, 182);
    constexpr COLORREF Success      = RGB(78, 201, 176);
    constexpr COLORREF Warning      = RGB(206, 145, 52);
    constexpr COLORREF Error        = RGB(244, 71, 71);
    constexpr COLORREF TextPrimary  = RGB(204, 204, 204);
    constexpr COLORREF TextSecondary= RGB(153, 153, 153);
    constexpr COLORREF TextDim      = RGB(106, 106, 106);
    constexpr COLORREF Border       = RGB(63, 63, 70);
    constexpr COLORREF CheckOn      = RGB(0, 122, 204);
    constexpr COLORREF CheckOff     = RGB(63, 63, 70);
    constexpr COLORREF ProgressBg   = RGB(51, 51, 55);
    constexpr COLORREF ProgressFill = RGB(0, 122, 204);
    constexpr COLORREF SidebarBg    = RGB(37, 37, 38);
    constexpr COLORREF White        = RGB(255, 255, 255);
}

// ========================= Global State =========================
struct InstallerState {
    HWND hWnd = nullptr;
    HINSTANCE hInst = nullptr;
    int currentPage = 0;      // 0=welcome, 1=products, 2=components, 3=location, 4=installing, 5=complete
    bool isInstalling = false;
    std::atomic<bool> installDone{false};
    std::atomic<int> progress{0};
    std::atomic<bool> installSuccess{true};
    std::wstring statusText = L"Ready to install";

    // Installer mode: 0=Install, 1=Update, 2=Uninstall
    int installerMode = 0;

    // ========= Product Selection =========
    bool installVerslang = true;
    bool installVersscript = true;

    // ========= Install Source =========
    // 0 = Built-in (from bundled/adjacent directories)
    // 1 = From ZIP file
    int installSource = 0;
    std::wstring verslangZipPath;
    std::wstring versscriptZipPath;

    // ========= Component Options =========
    // Verslang
    bool verslangCompiler = true;
    bool verslangExamples = true;
    bool verslangStdlib = true;
    bool verslangAddToPath = true;
    bool verslangFileAssoc = true;    // .vlang files
    bool verslangVSCode = true;

    // Versscript
    bool versscriptRuntime = true;
    bool versscriptExamples = true;
    bool versscriptDocs = true;
    bool versscriptAddToPath = true;
    bool versscriptFileAssoc = true;   // .vs / .verss files
    bool versscriptVSCode = true;

    // Shared
    bool createStartMenu = true;
    bool createDesktopShortcut = false;

    // ========= Paths =========
    std::wstring verslangInstallDir = L"C:\\Program Files\\Verslang";
    std::wstring versscriptInstallDir = L"C:\\Program Files\\Versscript";
    std::wstring sourceDir;    // where the installer lives

    // ========= Source Directories (auto-detected) =========
    std::wstring verslangSrcDir;       // Verslang project root
    std::wstring versscriptSrcDir;     // Versscript project root
    std::wstring vsixPath;             // Unified VS Code extension (.vsix)
    std::wstring verslangVsixPath;     // Verslang-only VS Code ext
    std::wstring versscriptVsixPath;   // Versscript-only VS Code ext

    // ========= Detection =========
    bool vscodeDetected = false;
    std::wstring vscodePath;
    bool existingVerslang = false;
    std::wstring existingVerslangDir;
    std::wstring existingVerslangVer;
    bool existingVersscript = false;
    std::wstring existingVersscriptDir;
    std::wstring existingVersscriptVer;

    // ========= Fonts =========
    HFONT fontTitle = nullptr;
    HFONT fontSubtitle = nullptr;
    HFONT fontBody = nullptr;
    HFONT fontSmall = nullptr;
    HFONT fontBold = nullptr;
    HFONT fontIcon = nullptr;
    HFONT fontBig = nullptr;

    // ========= UI State =========
    int hoverButton = -1;
    bool buttonPressed = false;
    int scrollOffset = 0;
    std::vector<std::wstring> installLog;
};

static InstallerState g;

// ========================= Embedded Resource Extraction =========================

// Extract an embedded RCDATA resource to a file on disk.
// Returns true if extraction succeeded.
static bool ExtractEmbeddedResource(int resourceId, const fs::path& destPath) {
    HRSRC hRes = FindResourceW(g.hInst, MAKEINTRESOURCEW(resourceId), RT_RCDATA);
    if (!hRes) return false;
    HGLOBAL hData = LoadResource(g.hInst, hRes);
    if (!hData) return false;
    DWORD size = SizeofResource(g.hInst, hRes);
    if (size == 0) return false;
    void* pData = LockResource(hData);
    if (!pData) return false;

    // Ensure parent directory exists
    try { fs::create_directories(destPath.parent_path()); } catch (...) {}

    HANDLE hFile = CreateFileW(destPath.c_str(), GENERIC_WRITE, 0, nullptr,
                               CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, nullptr);
    if (hFile == INVALID_HANDLE_VALUE) return false;
    DWORD written = 0;
    BOOL ok = WriteFile(hFile, pData, size, &written, nullptr);
    CloseHandle(hFile);
    return ok && written == size;
}

// Check whether an embedded resource exists in this executable
static bool HasEmbeddedResource(int resourceId) {
    return FindResourceW(g.hInst, MAKEINTRESOURCEW(resourceId), RT_RCDATA) != nullptr;
}

// ========================= Utility Functions =========================

// Safe canonical: returns canonical path or the original if canonicalization fails
static fs::path SafeCanonical(const fs::path& p) {
    try { return fs::canonical(p); } catch (...) {}
    try { return fs::weakly_canonical(p); } catch (...) {}
    return p;
}

// Safe exists: never throws
static bool SafeExists(const fs::path& p) {
    try { return fs::exists(p); } catch (...) { return false; }
}

static void DetectSourceDir() {
    wchar_t exePath[MAX_PATH];
    GetModuleFileNameW(nullptr, exePath, MAX_PATH);

    // Use the raw path from GetModuleFileName — do NOT canonicalize.
    // fs::canonical() can return \\?\ prefixed or 8.3 short names on paths
    // with special characters (e.g. "01. Leonard") breaking subsequent operations.
    fs::path base = fs::path(exePath).parent_path();
    g.sourceDir = base.wstring();

    // Build search roots by walking up the directory tree with parent_path()
    std::vector<fs::path> searchRoots;
    searchRoots.push_back(base);                                    // installer/
    if (base.has_parent_path() && base.parent_path() != base) {
        fs::path p1 = base.parent_path();                          // versatile-project/
        searchRoots.push_back(p1);
        if (p1.has_parent_path() && p1.parent_path() != p1) {
            fs::path p2 = p1.parent_path();                        // Downloads/
            searchRoots.push_back(p2);
            if (p2.has_parent_path() && p2.parent_path() != p2) {
                searchRoots.push_back(p2.parent_path());           // one more level up
            }
        }
    }

    // Try to detect Verslang source directory
    for (auto& root : searchRoots) {
        if (!g.verslangSrcDir.empty()) break;
        fs::path p = root / L"Verslang";
        if (SafeExists(p / L"build" / L"verslang.exe") || SafeExists(p / L"src" / L"main.cpp")) {
            g.verslangSrcDir = p.wstring();   // store as-is, no canonicalization
        }
    }
    if (g.verslangSrcDir.empty() && SafeExists(base / L"build" / L"verslang.exe")) {
        g.verslangSrcDir = base.wstring();
    }

    // Try to detect Versscript source directory
    for (auto& root : searchRoots) {
        if (!g.versscriptSrcDir.empty()) break;
        fs::path p = root / L"Versscript";
        if (SafeExists(p / L"build" / L"verss.exe") || SafeExists(p / L"bin" / L"verss.exe") ||
            SafeExists(p / L"cmake-build" / L"Release" / L"verss.exe") || SafeExists(p / L"CMakeLists.txt")) {
            g.versscriptSrcDir = p.wstring();   // store as-is, no canonicalization
        }
    }
    if (g.versscriptSrcDir.empty() && SafeExists(base / L"build" / L"verss.exe")) {
        g.versscriptSrcDir = base.wstring();
    }

    // Try to find VS Code extension (.vsix)
    for (auto& root : searchRoots) {
        if (!g.vsixPath.empty()) break;
        fs::path p = root / L"versatile-vscode";
        try {
            if (SafeExists(p)) {
                for (auto& entry : fs::directory_iterator(p)) {
                    if (entry.path().extension() == L".vsix") {
                        g.vsixPath = entry.path().wstring();
                    }
                }
            }
        } catch (...) {}
    }

    // Check for Versscript-specific vsix
    if (!g.versscriptSrcDir.empty()) {
        fs::path vsDir = fs::path(g.versscriptSrcDir) / L"vscode-extension";
        try {
            if (SafeExists(vsDir)) {
                for (auto& entry : fs::directory_iterator(vsDir)) {
                    if (entry.path().extension() == L".vsix") {
                        g.versscriptVsixPath = entry.path().wstring();
                    }
                }
            }
        } catch (...) {}
    }
}

static void DetectExistingInstalls() {
    // Check Verslang
    HKEY hKey;
    if (RegOpenKeyExW(HKEY_LOCAL_MACHINE,
        L"SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Uninstall\\Verslang",
        0, KEY_READ, &hKey) == ERROR_SUCCESS) {
        wchar_t buf[512] = {};
        DWORD bufSize = sizeof(buf);
        if (RegQueryValueExW(hKey, L"InstallLocation", nullptr, nullptr, (LPBYTE)buf, &bufSize) == ERROR_SUCCESS)
            g.existingVerslangDir = buf;
        bufSize = sizeof(buf);
        if (RegQueryValueExW(hKey, L"DisplayVersion", nullptr, nullptr, (LPBYTE)buf, &bufSize) == ERROR_SUCCESS)
            g.existingVerslangVer = buf;
        RegCloseKey(hKey);
        if (!g.existingVerslangDir.empty() && fs::exists(g.existingVerslangDir)) {
            g.existingVerslang = true;
            g.verslangInstallDir = g.existingVerslangDir;
        }
    }

    // Check Versscript
    if (RegOpenKeyExW(HKEY_LOCAL_MACHINE,
        L"SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Uninstall\\Versscript",
        0, KEY_READ, &hKey) == ERROR_SUCCESS) {
        wchar_t buf[512] = {};
        DWORD bufSize = sizeof(buf);
        if (RegQueryValueExW(hKey, L"InstallLocation", nullptr, nullptr, (LPBYTE)buf, &bufSize) == ERROR_SUCCESS)
            g.existingVersscriptDir = buf;
        bufSize = sizeof(buf);
        if (RegQueryValueExW(hKey, L"DisplayVersion", nullptr, nullptr, (LPBYTE)buf, &bufSize) == ERROR_SUCCESS)
            g.existingVersscriptVer = buf;
        RegCloseKey(hKey);
        if (!g.existingVersscriptDir.empty() && fs::exists(g.existingVersscriptDir)) {
            g.existingVersscript = true;
            g.versscriptInstallDir = g.existingVersscriptDir;
        }
    }
}

static bool DetectVSCode() {
    if (fs::exists(L"C:\\Program Files\\Microsoft VS Code\\Code.exe")) {
        g.vscodePath = L"C:\\Program Files\\Microsoft VS Code\\Code.exe";
        g.vscodeDetected = true;
        return true;
    }
    wchar_t pathBuf[32768];
    if (SearchPathW(nullptr, L"code.cmd", nullptr, 32768, pathBuf, nullptr)) {
        g.vscodeDetected = true;
        g.vscodePath = pathBuf;
        return true;
    }
    if (SearchPathW(nullptr, L"code.exe", nullptr, 32768, pathBuf, nullptr)) {
        g.vscodeDetected = true;
        g.vscodePath = pathBuf;
        return true;
    }
    wchar_t* localAppData = nullptr;
    if (SUCCEEDED(SHGetKnownFolderPath(FOLDERID_LocalAppData, 0, nullptr, &localAppData))) {
        std::wstring codePath = std::wstring(localAppData) + L"\\Programs\\Microsoft VS Code\\Code.exe";
        CoTaskMemFree(localAppData);
        if (fs::exists(codePath)) {
            g.vscodePath = codePath;
            g.vscodeDetected = true;
            return true;
        }
    }
    g.vscodeDetected = false;
    return false;
}

static bool IsAdmin() {
    BOOL isAdmin = FALSE;
    PSID adminGroup = nullptr;
    SID_IDENTIFIER_AUTHORITY ntAuth = SECURITY_NT_AUTHORITY;
    if (AllocateAndInitializeSid(&ntAuth, 2, SECURITY_BUILTIN_DOMAIN_RID,
        DOMAIN_ALIAS_RID_ADMINS, 0, 0, 0, 0, 0, 0, &adminGroup)) {
        CheckTokenMembership(nullptr, adminGroup, &isAdmin);
        FreeSid(adminGroup);
    }
    return isAdmin != FALSE;
}

static void RelaunchAsAdmin() {
    wchar_t exePath[MAX_PATH];
    GetModuleFileNameW(nullptr, exePath, MAX_PATH);
    ShellExecuteW(nullptr, L"runas", exePath, nullptr, nullptr, SW_SHOW);
}

static void AddLog(const std::wstring& msg) {
    g.installLog.push_back(msg);
    g.statusText = msg;
}

static bool ExtractZip(const std::wstring& zipFile, const std::wstring& destDir) {
    fs::create_directories(destDir);
    std::wstring cmd = L"powershell -NoProfile -Command \"Expand-Archive -Path '";
    cmd += zipFile;
    cmd += L"' -DestinationPath '";
    cmd += destDir;
    cmd += L"' -Force\"";
    int len = WideCharToMultiByte(CP_UTF8, 0, cmd.c_str(), -1, nullptr, 0, nullptr, nullptr);
    std::string cmdA(len, '\0');
    WideCharToMultiByte(CP_UTF8, 0, cmd.c_str(), -1, cmdA.data(), len, nullptr, nullptr);
    FILE* pipe = _popen(cmdA.c_str(), "r");
    if (!pipe) return false;
    char buf[256];
    while (fgets(buf, sizeof(buf), pipe)) {}
    return _pclose(pipe) == 0;
}

static std::wstring BrowseForZipFile(const std::wstring& title) {
    wchar_t filename[MAX_PATH] = {};
    OPENFILENAMEW ofn = {};
    ofn.lStructSize = sizeof(ofn);
    ofn.hwndOwner = g.hWnd;
    ofn.lpstrFilter = L"ZIP Archives\0*.zip\0All Files\0*.*\0";
    ofn.lpstrFile = filename;
    ofn.nMaxFile = MAX_PATH;
    ofn.Flags = OFN_FILEMUSTEXIST | OFN_PATHMUSTEXIST;
    ofn.lpstrTitle = title.c_str();
    if (GetOpenFileNameW(&ofn)) return filename;
    return L"";
}

static std::wstring BrowseForFolder(const std::wstring& title) {
    BROWSEINFOW bi = {};
    bi.hwndOwner = g.hWnd;
    bi.lpszTitle = title.c_str();
    bi.ulFlags = BIF_RETURNONLYFSDIRS | BIF_NEWDIALOGSTYLE;
    LPITEMIDLIST pidl = SHBrowseForFolderW(&bi);
    if (pidl) {
        wchar_t path[MAX_PATH];
        if (SHGetPathFromIDListW(pidl, path)) {
            CoTaskMemFree(pidl);
            return path;
        }
        CoTaskMemFree(pidl);
    }
    return L"";
}

static bool RunCodeCommand(const std::wstring& args) {
    std::wstring cmd = L"code " + args;
    int len = WideCharToMultiByte(CP_UTF8, 0, cmd.c_str(), -1, nullptr, 0, nullptr, nullptr);
    std::string cmdA(len, '\0');
    WideCharToMultiByte(CP_UTF8, 0, cmd.c_str(), -1, cmdA.data(), len, nullptr, nullptr);
    FILE* pipe = _popen(cmdA.c_str(), "r");
    if (!pipe) return false;
    char buf[256];
    while (fgets(buf, sizeof(buf), pipe)) {}
    return _pclose(pipe) == 0;
}

static bool CopyDir(const fs::path& src, const fs::path& dst) {
    try {
        fs::create_directories(dst);
        for (auto& entry : fs::directory_iterator(src)) {
            auto dest = dst / entry.path().filename();
            if (entry.is_directory()) CopyDir(entry.path(), dest);
            else fs::copy_file(entry.path(), dest, fs::copy_options::overwrite_existing);
        }
        return true;
    } catch (...) { return false; }
}

// ========================= Drawing Helpers =========================

static void FillRect(HDC hdc, int x, int y, int w, int h, COLORREF color) {
    HBRUSH br = CreateSolidBrush(color);
    RECT rc = { x, y, x + w, y + h };
    ::FillRect(hdc, &rc, br);
    DeleteObject(br);
}

static void DrawRoundRect(HDC hdc, int x, int y, int w, int h, int r, COLORREF fill, COLORREF border) {
    HBRUSH br = CreateSolidBrush(fill);
    HPEN pen = CreatePen(PS_SOLID, 1, border);
    HBRUSH oldBr = (HBRUSH)SelectObject(hdc, br);
    HPEN oldPen = (HPEN)SelectObject(hdc, pen);
    RoundRect(hdc, x, y, x + w, y + h, r, r);
    SelectObject(hdc, oldBr);
    SelectObject(hdc, oldPen);
    DeleteObject(br);
    DeleteObject(pen);
}

static void DrawText(HDC hdc, const std::wstring& text, int x, int y, COLORREF color, HFONT font, UINT align = DT_LEFT) {
    SetTextColor(hdc, color);
    SetBkMode(hdc, TRANSPARENT);
    HFONT oldFont = (HFONT)SelectObject(hdc, font);
    RECT rc = { x, y, x + 2000, y + 200 };
    ::DrawTextW(hdc, text.c_str(), -1, &rc, align | DT_NOCLIP | DT_SINGLELINE);
    SelectObject(hdc, oldFont);
}

static SIZE MeasureText(HDC hdc, const std::wstring& text, HFONT font) {
    HFONT oldFont = (HFONT)SelectObject(hdc, font);
    SIZE sz;
    GetTextExtentPoint32W(hdc, text.c_str(), (int)text.length(), &sz);
    SelectObject(hdc, oldFont);
    return sz;
}

// ========================= Button & Checkbox Drawing =========================

struct ButtonRect { int x, y, w, h; };
static ButtonRect g_buttons[10];
static int g_buttonCount = 0;

static void DrawButton(HDC hdc, int idx, const std::wstring& text, int x, int y, int w, int h,
                        bool primary = false, bool enabled = true) {
    if (idx < 10) {
        g_buttons[idx] = { x, y, w, h };
        if (idx >= g_buttonCount) g_buttonCount = idx + 1;
    }
    COLORREF fill, border, textColor;
    if (!enabled) {
        fill = Theme::BgCard; border = Theme::Border; textColor = Theme::TextDim;
    } else if (primary) {
        fill = (g.hoverButton == idx && g.buttonPressed) ? Theme::AccentPress :
               (g.hoverButton == idx) ? Theme::AccentHover : Theme::Accent;
        border = fill; textColor = Theme::White;
    } else {
        fill = (g.hoverButton == idx && g.buttonPressed) ? Theme::BgInput :
               (g.hoverButton == idx) ? Theme::BgHover : Theme::BgCard;
        border = Theme::Border; textColor = Theme::TextPrimary;
    }
    DrawRoundRect(hdc, x, y, w, h, 6, fill, border);
    SIZE sz = MeasureText(hdc, text, g.fontBody);
    DrawText(hdc, text, x + (w - sz.cx) / 2, y + (h - sz.cy) / 2, textColor, g.fontBody);
}

struct CheckboxItem { int x, y, w, h; bool* value; std::wstring label; std::wstring description; bool enabled; };
static std::vector<CheckboxItem> g_checkboxes;

static void DrawCheckbox(HDC hdc, int x, int y, bool checked, bool enabled,
                          const std::wstring& label, const std::wstring& desc = L"") {
    int boxSize = 18;
    int boxY = y + 2;
    COLORREF boxFill = checked ? Theme::CheckOn : Theme::BgInput;
    COLORREF boxBorder = checked ? Theme::CheckOn : Theme::CheckOff;
    if (!enabled) { boxFill = Theme::BgCard; boxBorder = Theme::TextDim; }
    DrawRoundRect(hdc, x, boxY, boxSize, boxSize, 4, boxFill, boxBorder);
    if (checked) {
        HPEN pen = CreatePen(PS_SOLID, 2, Theme::White);
        HPEN oldPen = (HPEN)SelectObject(hdc, pen);
        MoveToEx(hdc, x + 4, boxY + 9, nullptr); LineTo(hdc, x + 7, boxY + 13); LineTo(hdc, x + 14, boxY + 5);
        SelectObject(hdc, oldPen); DeleteObject(pen);
    }
    DrawText(hdc, label, x + boxSize + 10, y, enabled ? Theme::TextPrimary : Theme::TextDim, g.fontBold);
    if (!desc.empty())
        DrawText(hdc, desc, x + boxSize + 10, y + 22, Theme::TextSecondary, g.fontSmall);
}

// ========================= Sidebar Drawing =========================

static void DrawSidebar(HDC hdc, [[maybe_unused]] int totalW, int totalH) {
    int sideW = 260;
    FillRect(hdc, 0, 0, sideW, totalH, Theme::SidebarBg);

    // Logo
    DrawText(hdc, L"V", 30, 28, Theme::Accent, g.fontTitle);
    DrawText(hdc, L"Versatile Suite", 70, 34, Theme::TextPrimary, g.fontSubtitle);
    DrawText(hdc, L"Language Installer", 70, 58, Theme::TextSecondary, g.fontSmall);
    DrawText(hdc, L"v1.0.0", 30, 88, Theme::TextDim, g.fontSmall);

    // Separator
    HPEN pen = CreatePen(PS_SOLID, 1, Theme::Border);
    HPEN oldPen = (HPEN)SelectObject(hdc, pen);
    MoveToEx(hdc, 20, 112, nullptr); LineTo(hdc, sideW - 20, 112);
    SelectObject(hdc, oldPen); DeleteObject(pen);

    // Steps
    const wchar_t* steps[] = { L"Welcome", L"Products", L"Components", L"Location", L"Installing", L"Complete" };
    int stepCount = 6;
    if (g.installerMode == 2) {
        steps[1] = L""; steps[2] = L""; steps[3] = L"";
        steps[4] = L"Uninstalling";
    }

    for (int i = 0; i < stepCount; i++) {
        if (steps[i][0] == L'\0') continue;
        int sy = 130 + i * 42;
        COLORREF circleColor, textColor;
        if (i < g.currentPage) { circleColor = Theme::Success; textColor = Theme::TextSecondary; }
        else if (i == g.currentPage) { circleColor = Theme::Accent; textColor = Theme::TextPrimary; FillRect(hdc, 0, sy - 2, 3, 30, Theme::Accent); }
        else { circleColor = Theme::TextDim; textColor = Theme::TextDim; }

        HBRUSH br = CreateSolidBrush(circleColor);
        HBRUSH oldBr = (HBRUSH)SelectObject(hdc, br);
        HPEN cp = CreatePen(PS_SOLID, 1, circleColor);
        HPEN oldP = (HPEN)SelectObject(hdc, cp);
        Ellipse(hdc, 30, sy + 4, 46, sy + 20);
        SelectObject(hdc, oldBr); SelectObject(hdc, oldP);
        DeleteObject(br); DeleteObject(cp);

        if (i < g.currentPage) {
            HPEN chk = CreatePen(PS_SOLID, 2, Theme::BgDark);
            HPEN oldC = (HPEN)SelectObject(hdc, chk);
            MoveToEx(hdc, 34, sy + 12, nullptr); LineTo(hdc, 37, sy + 16); LineTo(hdc, 42, sy + 8);
            SelectObject(hdc, oldC); DeleteObject(chk);
        } else {
            std::wstring num = std::to_wstring(i + 1);
            SIZE sz = MeasureText(hdc, num, g.fontSmall);
            DrawText(hdc, num, 38 - sz.cx / 2, sy + 4, (i == g.currentPage) ? Theme::White : Theme::BgDark, g.fontSmall);
        }
        DrawText(hdc, steps[i], 56, sy + 3, textColor, (i == g.currentPage) ? g.fontBold : g.fontBody);
    }

    // Footer
    DrawText(hdc, L"\xA9 2026 Lonidev", 30, totalH - 40, Theme::TextDim, g.fontSmall);

    // Right border
    pen = CreatePen(PS_SOLID, 1, Theme::Border);
    oldPen = (HPEN)SelectObject(hdc, pen);
    MoveToEx(hdc, sideW, 0, nullptr); LineTo(hdc, sideW, totalH);
    SelectObject(hdc, oldPen); DeleteObject(pen);
}

// ========================= Page 0: Welcome =========================

static void DrawWelcomePage(HDC hdc, int cx, int cy) {
    int left = 290;
    g_buttonCount = 0;
    g_checkboxes.clear();

    bool anyExisting = g.existingVerslang || g.existingVersscript;

    if (anyExisting) {
        DrawText(hdc, L"Versatile Suite Detected", left, 40, Theme::TextPrimary, g.fontTitle);
        DrawText(hdc, L"Existing language installations found on this system.", left, 82, Theme::TextSecondary, g.fontBody);

        int y = 130;
        int cardW = cx - left - 40;

        if (g.existingVerslang) {
            DrawRoundRect(hdc, left, y, cardW, 55, 8, Theme::BgCard, Theme::Border);
            DrawText(hdc, L"\x2714  Verslang " + g.existingVerslangVer, left + 20, y + 8, Theme::AccentGreen, g.fontBold);
            DrawText(hdc, g.existingVerslangDir, left + 20, y + 30, Theme::TextDim, g.fontSmall);
            y += 65;
        }
        if (g.existingVersscript) {
            DrawRoundRect(hdc, left, y, cardW, 55, 8, Theme::BgCard, Theme::Border);
            DrawText(hdc, L"\x2714  Versscript " + g.existingVersscriptVer, left + 20, y + 8, Theme::AccentOrange, g.fontBold);
            DrawText(hdc, g.existingVersscriptDir, left + 20, y + 30, Theme::TextDim, g.fontSmall);
            y += 65;
        }

        y += 15;
        DrawText(hdc, L"What would you like to do?", left, y, Theme::TextPrimary, g.fontBold);
        y += 34;

        struct ModeOption { const wchar_t* icon; const wchar_t* title; const wchar_t* desc; int mode; };
        ModeOption modes[] = {
            { L"\x21BB", L"Update / Add Languages",    L"Update existing or install additional languages", 1 },
            { L"\x2716", L"Uninstall Everything",       L"Remove all Versatile Suite components", 2 },
            { L"\x2699", L"Reinstall / Modify",         L"Fresh install with component selection", 0 },
        };

        for (int i = 0; i < 3; i++) {
            bool selected = (g.installerMode == modes[i].mode);
            DrawRoundRect(hdc, left, y, cardW, 58, 8, selected ? Theme::BgInput : Theme::BgCard, selected ? Theme::Accent : Theme::Border);
            if (selected) {
                HBRUSH br = CreateSolidBrush(Theme::Accent);
                HBRUSH oldBr = (HBRUSH)SelectObject(hdc, br);
                HPEN p = CreatePen(PS_SOLID, 1, Theme::Accent);
                HPEN oldP = (HPEN)SelectObject(hdc, p);
                RoundRect(hdc, left, y, left + 4, y + 58, 2, 2);
                SelectObject(hdc, oldBr); SelectObject(hdc, oldP);
                DeleteObject(br); DeleteObject(p);
            }
            DrawText(hdc, modes[i].icon, left + 20, y + 10, selected ? Theme::Accent : Theme::TextDim, g.fontBody);
            DrawText(hdc, modes[i].title, left + 48, y + 8, Theme::TextPrimary, g.fontBold);
            DrawText(hdc, modes[i].desc, left + 48, y + 30, Theme::TextSecondary, g.fontSmall);
            g_checkboxes.push_back({ left, y, cardW, 58, nullptr, modes[i].title, modes[i].desc, true });
            y += 68;
        }
    } else {
        DrawText(hdc, L"Welcome to the Versatile Suite", left, 40, Theme::TextPrimary, g.fontTitle);
        DrawText(hdc, L"Install the complete Versatile language ecosystem", left, 82, Theme::TextSecondary, g.fontBody);

        int y = 140;
        int cardW = cx - left - 40;
        int cardH = 72;

        struct Feature { const wchar_t* icon; const wchar_t* title; const wchar_t* desc; COLORREF accent; };
        Feature features[] = {
            { L"\x25B6", L"Verslang Compiler",     L"Low-level systems language compiling to native x86-64 machine code", Theme::AccentGreen },
            { L"\x2699", L"Versscript Runtime",    L"Modern scripting language with 500+ built-in functions and 95+ modules", Theme::AccentOrange },
            { L"\x270E", L"VS Code Extensions",    L"Syntax highlighting, IntelliSense, debugger, snippets, and themes", Theme::AccentPurple },
            { L"\x2615", L"Unified Toolchain",     L"Build, compile, run, debug — all from the command line or VS Code", Theme::Accent },
        };

        for (int i = 0; i < 4; i++) {
            int fy = y + i * (cardH + 10);
            DrawRoundRect(hdc, left, fy, cardW, cardH, 8, Theme::BgCard, Theme::Border);
            // Icon circle
            HBRUSH iBr = CreateSolidBrush(features[i].accent);
            HBRUSH oldB = (HBRUSH)SelectObject(hdc, iBr);
            HPEN iP = CreatePen(PS_SOLID, 1, features[i].accent);
            HPEN oldP = (HPEN)SelectObject(hdc, iP);
            Ellipse(hdc, left + 16, fy + 18, left + 50, fy + 52);
            SelectObject(hdc, oldB); SelectObject(hdc, oldP);
            DeleteObject(iBr); DeleteObject(iP);
            DrawText(hdc, features[i].icon, left + 25, fy + 21, Theme::White, g.fontBody);
            DrawText(hdc, features[i].title, left + 66, fy + 14, Theme::TextPrimary, g.fontBold);
            DrawText(hdc, features[i].desc, left + 66, fy + 38, Theme::TextSecondary, g.fontSmall);
        }

        int infoY = y + 4 * (cardH + 10) + 10;
        if (!IsAdmin()) {
            DrawText(hdc, L"\x26A0  This installer requires administrator privileges.", left, infoY, Theme::Warning, g.fontSmall);
        } else {
            DrawText(hdc, L"\x2714  Running with administrator privileges", left, infoY, Theme::Success, g.fontSmall);
        }
    }

    int btnY = cy - 60;
    DrawButton(hdc, 0, L"Next", cx - 140, btnY, 110, 38, true);
    DrawButton(hdc, 1, L"Cancel", cx - 260, btnY, 110, 38, false);
}

// ========================= Page 1: Product Selection =========================

static void DrawProductsPage(HDC hdc, int cx, int cy) {
    int left = 290;
    g_buttonCount = 0;
    g_checkboxes.clear();

    DrawText(hdc, L"Select Products", left, 40, Theme::TextPrimary, g.fontTitle);
    DrawText(hdc, L"Choose which languages to install", left, 76, Theme::TextSecondary, g.fontBody);

    int y = 120;
    int cardW = cx - left - 40;

    // ---- Verslang Card ----
    {
        COLORREF border = g.installVerslang ? Theme::AccentGreen : Theme::Border;
        COLORREF fill = g.installVerslang ? RGB(35, 50, 45) : Theme::BgCard;
        DrawRoundRect(hdc, left, y, cardW, 100, 10, fill, border);

        if (g.installVerslang) {
            FillRect(hdc, left, y, 4, 100, Theme::AccentGreen);
        }

        // Checkbox area
        DrawCheckbox(hdc, left + 16, y + 12, g.installVerslang, true, L"Verslang Compiler", L"");
        g_checkboxes.push_back({ left + 16, y + 12, 300, 24, &g.installVerslang, L"Verslang", L"", true });

        DrawText(hdc, L"Low-level systems programming language", left + 50, y + 38, Theme::TextSecondary, g.fontSmall);
        DrawText(hdc, L"Compiles to native x86-64 (ELF, PE, flat binary)", left + 50, y + 56, Theme::TextDim, g.fontSmall);

        // Source indicator
        bool hasEmbedded = HasEmbeddedResource(IDR_VERSLANG_EXE);
        bool hasFileSource = !g.verslangSrcDir.empty() && (
            SafeExists(fs::path(g.verslangSrcDir) / L"build" / L"verslang.exe") ||
            SafeExists(fs::path(g.verslangSrcDir) / L"bin" / L"verslang.exe") ||
            SafeExists(fs::path(g.verslangSrcDir) / L"cmake-build" / L"Release" / L"verslang.exe") ||
            SafeExists(fs::path(g.verslangSrcDir) / L"src" / L"main.cpp"));
        std::wstring srcLabel;
        COLORREF srcColor;
        if (hasEmbedded) {
            srcLabel = L"\x2714 Packaged in installer";
            srcColor = Theme::Success;
        } else if (hasFileSource) {
            srcLabel = L"\x2714 Source found on disk";
            srcColor = Theme::Success;
        } else {
            srcLabel = L"\x26A0 Not available (use ZIP)";
            srcColor = Theme::Warning;
        }
        DrawText(hdc, srcLabel, left + 50, y + 76, srcColor, g.fontSmall);
    }
    y += 115;

    // ---- Versscript Card ----
    {
        COLORREF border = g.installVersscript ? Theme::AccentOrange : Theme::Border;
        COLORREF fill = g.installVersscript ? RGB(50, 42, 30) : Theme::BgCard;
        DrawRoundRect(hdc, left, y, cardW, 100, 10, fill, border);

        if (g.installVersscript) {
            FillRect(hdc, left, y, 4, 100, Theme::AccentOrange);
        }

        DrawCheckbox(hdc, left + 16, y + 12, g.installVersscript, true, L"Versscript Runtime", L"");
        g_checkboxes.push_back({ left + 16, y + 12, 300, 24, &g.installVersscript, L"Versscript", L"", true });

        DrawText(hdc, L"Modern scripting language for creative developers", left + 50, y + 38, Theme::TextSecondary, g.fontSmall);
        DrawText(hdc, L"500+ built-in functions, 95+ modules, REPL, GUI", left + 50, y + 56, Theme::TextDim, g.fontSmall);

        bool hasEmbeddedVS = HasEmbeddedResource(IDR_VERSS_EXE);
        bool hasFileSourceVS = !g.versscriptSrcDir.empty() && (
            SafeExists(fs::path(g.versscriptSrcDir) / L"build" / L"verss.exe") ||
            SafeExists(fs::path(g.versscriptSrcDir) / L"bin" / L"verss.exe") ||
            SafeExists(fs::path(g.versscriptSrcDir) / L"cmake-build" / L"Release" / L"verss.exe") ||
            SafeExists(fs::path(g.versscriptSrcDir) / L"CMakeLists.txt"));
        std::wstring srcLabelVS;
        COLORREF srcColorVS;
        if (hasEmbeddedVS) {
            srcLabelVS = L"\x2714 Packaged in installer";
            srcColorVS = Theme::Success;
        } else if (hasFileSourceVS) {
            srcLabelVS = L"\x2714 Source found on disk";
            srcColorVS = Theme::Success;
        } else {
            srcLabelVS = L"\x26A0 Not available (use ZIP)";
            srcColorVS = Theme::Warning;
        }
        DrawText(hdc, srcLabelVS, left + 50, y + 76, srcColorVS, g.fontSmall);
    }
    y += 130;

    // ---- Install Source Section ----
    DrawText(hdc, L"Installation Source", left + 10, y, Theme::Accent, g.fontBold);
    y += 28;

    // Radio: Built-in
    {
        bool selected = (g.installSource == 0);
        DrawRoundRect(hdc, left, y, cardW, 46, 8, selected ? Theme::BgInput : Theme::BgCard, selected ? Theme::Accent : Theme::Border);
        if (selected) FillRect(hdc, left, y, 4, 46, Theme::Accent);
        DrawText(hdc, L"\x25C9", left + 16, y + 5, selected ? Theme::Accent : Theme::TextDim, g.fontBody);
        DrawText(hdc, L"Use built-in / bundled files", left + 40, y + 5, Theme::TextPrimary, g.fontBold);
        DrawText(hdc, L"Install from the compiled binaries adjacent to this installer", left + 40, y + 25, Theme::TextSecondary, g.fontSmall);
        g_checkboxes.push_back({ left, y, cardW, 46, nullptr, L"source_builtin", L"", true });
    }
    y += 54;

    // Radio: ZIP
    {
        bool selected = (g.installSource == 1);
        DrawRoundRect(hdc, left, y, cardW, 46, 8, selected ? Theme::BgInput : Theme::BgCard, selected ? Theme::Accent : Theme::Border);
        if (selected) FillRect(hdc, left, y, 4, 46, Theme::Accent);
        DrawText(hdc, L"\x25C9", left + 16, y + 5, selected ? Theme::Accent : Theme::TextDim, g.fontBody);
        DrawText(hdc, L"Install from ZIP packages", left + 40, y + 5, Theme::TextPrimary, g.fontBold);
        DrawText(hdc, L"Select ZIP archives containing pre-built language packages", left + 40, y + 25, Theme::TextSecondary, g.fontSmall);
        g_checkboxes.push_back({ left, y, cardW, 46, nullptr, L"source_zip", L"", true });
    }
    y += 60;

    // ZIP file selectors (shown only when ZIP source is selected)
    if (g.installSource == 1) {
        if (g.installVerslang) {
            DrawText(hdc, L"Verslang ZIP:", left + 10, y, Theme::TextPrimary, g.fontSmall);
            int pathW = cx - left - 200;
            std::wstring vl = g.verslangZipPath.empty() ? L"No file selected..." : g.verslangZipPath;
            DrawRoundRect(hdc, left + 10, y + 18, pathW, 28, 4, Theme::BgInput, Theme::Border);
            DrawText(hdc, vl, left + 18, y + 23, g.verslangZipPath.empty() ? Theme::TextDim : Theme::TextPrimary, g.fontSmall);
            DrawButton(hdc, 4, L"Browse", left + pathW + 20, y + 18, 90, 28, false);
            y += 56;
        }
        if (g.installVersscript) {
            DrawText(hdc, L"Versscript ZIP:", left + 10, y, Theme::TextPrimary, g.fontSmall);
            int pathW = cx - left - 200;
            std::wstring vs = g.versscriptZipPath.empty() ? L"No file selected..." : g.versscriptZipPath;
            DrawRoundRect(hdc, left + 10, y + 18, pathW, 28, 4, Theme::BgInput, Theme::Border);
            DrawText(hdc, vs, left + 18, y + 23, g.versscriptZipPath.empty() ? Theme::TextDim : Theme::TextPrimary, g.fontSmall);
            DrawButton(hdc, 5, L"Browse", left + pathW + 20, y + 18, 90, 28, false);
            y += 56;
        }
    }

    // Validation message
    if (!g.installVerslang && !g.installVersscript) {
        DrawText(hdc, L"\x26A0  Please select at least one product to install.", left, cy - 100, Theme::Warning, g.fontSmall);
    }

    int btnY = cy - 60;
    bool canNext = g.installVerslang || g.installVersscript;
    DrawButton(hdc, 0, L"Next", cx - 140, btnY, 110, 38, true, canNext);
    DrawButton(hdc, 1, L"Back", cx - 260, btnY, 110, 38, false);
    DrawButton(hdc, 2, L"Cancel", left, btnY, 110, 38, false);
}

// ========================= Page 2: Components =========================

static void DrawComponentsPage(HDC hdc, int cx, int cy) {
    int left = 290;
    g_buttonCount = 0;
    g_checkboxes.clear();

    DrawText(hdc, L"Select Components", left, 40, Theme::TextPrimary, g.fontTitle);
    DrawText(hdc, L"Choose what to install with each product", left, 76, Theme::TextSecondary, g.fontBody);

    int contentTop = 110;
    int contentBottom = cy - 70;

    HRGN clipRgn = CreateRectRgn(left, contentTop, cx - 10, contentBottom);
    SelectClipRgn(hdc, clipRgn);

    int y = contentTop - g.scrollOffset;
    int spacing = 46;

    auto addCheck = [&](bool* val, const std::wstring& label, const std::wstring& desc, bool enabled = true) {
        DrawCheckbox(hdc, left + 10, y, *val, enabled, label, desc);
        g_checkboxes.push_back({ left + 10, y, 500, 40, val, label, desc, enabled });
        y += spacing;
    };

    // ---- Verslang Components ----
    if (g.installVerslang) {
        DrawText(hdc, L"\x25B6  Verslang", left + 10, y, Theme::AccentGreen, g.fontBold);
        y += 28;

        addCheck(&g.verslangCompiler, L"Verslang Compiler (verslang.exe)",
                 L"The core compiler \x2014 Required", false);  // always required
        addCheck(&g.verslangExamples, L"Example Programs",
                 L"Bootloader, fibonacci, hello world, kernel I/O examples");
        addCheck(&g.verslangStdlib, L"Standard Library",
                 L"Standard library modules for common operations");
        addCheck(&g.verslangAddToPath, L"Add to System PATH",
                 L"Run 'verslang' from any terminal");
        addCheck(&g.verslangFileAssoc, L"Register .vlang File Association",
                 L"Associate .vlang files with the Verslang compiler");

        y += 6;

        // VS Code
        DrawText(hdc, L"VS Code Integration", left + 20, y, Theme::Accent, g.fontSmall);
        y += 20;
        if (g.vscodeDetected)
            DrawText(hdc, L"\x2714  VS Code detected", left + 20, y, Theme::Success, g.fontSmall);
        else
            DrawText(hdc, L"\x2716  VS Code not detected", left + 20, y, Theme::Warning, g.fontSmall);
        y += 18;
        addCheck(&g.verslangVSCode, L"VS Code Extension (Verslang)",
                 g.vscodeDetected ? L"Syntax highlighting, IntelliSense, debugger"
                                  : L"VS Code not found \x2014 install VS Code first",
                 g.vscodeDetected);

        y += 10;
    }

    // ---- Versscript Components ----
    if (g.installVersscript) {
        DrawText(hdc, L"\x2699  Versscript", left + 10, y, Theme::AccentOrange, g.fontBold);
        y += 28;

        addCheck(&g.versscriptRuntime, L"Versscript Runtime (verss.exe)",
                 L"Core runtime, compiler, and REPL \x2014 Required", false);
        addCheck(&g.versscriptExamples, L"Example Scripts",
                 L"Calculator, GUI demos, test scripts, and more");
        addCheck(&g.versscriptDocs, L"Documentation",
                 L"Language reference, module docs, permissions guide");
        addCheck(&g.versscriptAddToPath, L"Add to System PATH",
                 L"Run 'verss' from any terminal");
        addCheck(&g.versscriptFileAssoc, L"Register .vs / .verss File Associations",
                 L"Associate .vs and .verss files with Versscript");

        y += 6;
        DrawText(hdc, L"VS Code Integration", left + 20, y, Theme::Accent, g.fontSmall);
        y += 20;
        if (g.vscodeDetected)
            DrawText(hdc, L"\x2714  VS Code detected", left + 20, y, Theme::Success, g.fontSmall);
        else
            DrawText(hdc, L"\x2716  VS Code not detected", left + 20, y, Theme::Warning, g.fontSmall);
        y += 18;
        addCheck(&g.versscriptVSCode, L"VS Code Extension (Versscript)",
                 g.vscodeDetected ? L"Syntax highlighting, IntelliSense, debugger"
                                  : L"VS Code not found",
                 g.vscodeDetected);

        y += 10;
    }

    // ---- Shared Components ----
    DrawText(hdc, L"\x2605  System Integration", left + 10, y, Theme::AccentPurple, g.fontBold);
    y += 28;
    addCheck(&g.createStartMenu, L"Create Start Menu Entries",
             L"Add language tools to the Start Menu");
    addCheck(&g.createDesktopShortcut, L"Create Desktop Shortcuts",
             L"Add shortcuts on the Desktop");

    SelectClipRgn(hdc, nullptr);
    DeleteObject(clipRgn);

    int btnY = cy - 60;
    DrawButton(hdc, 0, L"Next", cx - 140, btnY, 110, 38, true);
    DrawButton(hdc, 1, L"Back", cx - 260, btnY, 110, 38, false);
    DrawButton(hdc, 2, L"Cancel", left, btnY, 110, 38, false);
}

// ========================= Page 3: Location =========================

static void DrawLocationPage(HDC hdc, int cx, int cy) {
    int left = 290;
    g_buttonCount = 0;
    g_checkboxes.clear();

    DrawText(hdc, L"Installation Locations", left, 40, Theme::TextPrimary, g.fontTitle);
    DrawText(hdc, L"Choose where to install each product", left, 82, Theme::TextSecondary, g.fontBody);

    int y = 140;
    int pathW = cx - left - 190;

    if (g.installVerslang) {
        DrawText(hdc, L"Verslang install directory:", left + 10, y, Theme::AccentGreen, g.fontBold);
        y += 28;
        DrawRoundRect(hdc, left + 10, y, pathW, 34, 4, Theme::BgInput, Theme::Border);
        DrawText(hdc, g.verslangInstallDir, left + 20, y + 8, Theme::TextPrimary, g.fontBody);
        DrawButton(hdc, 3, L"Browse...", left + pathW + 20, y, 110, 34, false);
        y += 56;
    }

    if (g.installVersscript) {
        DrawText(hdc, L"Versscript install directory:", left + 10, y, Theme::AccentOrange, g.fontBold);
        y += 28;
        DrawRoundRect(hdc, left + 10, y, pathW, 34, 4, Theme::BgInput, Theme::Border);
        DrawText(hdc, g.versscriptInstallDir, left + 20, y + 8, Theme::TextPrimary, g.fontBody);
        DrawButton(hdc, 6, L"Browse...", left + pathW + 20, y, 110, 34, false);
        y += 56;
    }

    // Disk space
    try {
        auto spaceInfo = fs::space(L"C:\\");
        double freeGB = (double)spaceInfo.available / (1024.0 * 1024.0 * 1024.0);
        DrawText(hdc, L"Available disk space: " + std::to_wstring((int)freeGB) + L" GB",
                 left + 10, y, Theme::TextSecondary, g.fontSmall);
    } catch (...) {}
    y += 25;
    DrawText(hdc, L"Required space: ~15 MB", left + 10, y, Theme::TextSecondary, g.fontSmall);
    y += 50;

    // Summary
    DrawText(hdc, L"Installation Summary", left + 10, y, Theme::Accent, g.fontBold);
    y += 30;

    auto summaryItem = [&](const std::wstring& label, bool enabled, COLORREF accent = Theme::Success) {
        std::wstring icon = enabled ? L"\x2714" : L"\x2716";
        COLORREF color = enabled ? accent : Theme::TextDim;
        DrawText(hdc, icon + L"  " + label, left + 20, y, color, g.fontBody);
        y += 24;
    };

    if (g.installVerslang) {
        summaryItem(L"Verslang Compiler", true, Theme::AccentGreen);
        summaryItem(L"Verslang Examples", g.verslangExamples);
        summaryItem(L"Verslang Stdlib", g.verslangStdlib);
        summaryItem(L"Verslang PATH", g.verslangAddToPath);
        summaryItem(L"Verslang .vlang assoc", g.verslangFileAssoc);
        summaryItem(L"Verslang VS Code ext", g.verslangVSCode && g.vscodeDetected);
    }
    if (g.installVersscript) {
        summaryItem(L"Versscript Runtime", true, Theme::AccentOrange);
        summaryItem(L"Versscript Examples", g.versscriptExamples);
        summaryItem(L"Versscript Docs", g.versscriptDocs);
        summaryItem(L"Versscript PATH", g.versscriptAddToPath);
        summaryItem(L"Versscript .vs/.verss assoc", g.versscriptFileAssoc);
        summaryItem(L"Versscript VS Code ext", g.versscriptVSCode && g.vscodeDetected);
    }
    summaryItem(L"Start Menu entries", g.createStartMenu);
    summaryItem(L"Desktop shortcuts", g.createDesktopShortcut);

    int btnY = cy - 60;
    DrawButton(hdc, 0, L"Install", cx - 140, btnY, 110, 38, true);
    DrawButton(hdc, 1, L"Back", cx - 260, btnY, 110, 38, false);
    DrawButton(hdc, 2, L"Cancel", left, btnY, 110, 38, false);
}

// ========================= Page 4: Installing =========================

static void DrawInstallingPage(HDC hdc, int cx, int cy) {
    int left = 290;
    g_buttonCount = 0;
    g_checkboxes.clear();

    std::wstring title = (g.installerMode == 2) ? L"Uninstalling" : L"Installing";
    DrawText(hdc, title + L" Versatile Suite", left, 40, Theme::TextPrimary, g.fontTitle);
    DrawText(hdc, L"Please wait while the operation completes...", left, 82, Theme::TextSecondary, g.fontBody);

    int y = 150;
    int barW = cx - left - 60;

    DrawText(hdc, L"Overall Progress", left + 10, y, Theme::TextPrimary, g.fontBold);
    y += 30;

    DrawRoundRect(hdc, left + 10, y, barW, 24, 12, Theme::ProgressBg, Theme::ProgressBg);
    int fillW = (int)((double)g.progress * barW / 100.0);
    if (fillW > 0) {
        HRGN rgn = CreateRoundRectRgn(left + 10, y, left + 10 + fillW, y + 24, 12, 12);
        SelectClipRgn(hdc, rgn);
        DrawRoundRect(hdc, left + 10, y, barW, 24, 12, Theme::ProgressFill, Theme::ProgressFill);
        SelectClipRgn(hdc, nullptr);
        DeleteObject(rgn);
    }
    std::wstring pctText = std::to_wstring((int)g.progress) + L"%";
    SIZE pctSize = MeasureText(hdc, pctText, g.fontSmall);
    DrawText(hdc, pctText, left + 10 + barW / 2 - pctSize.cx / 2, y + 4, Theme::White, g.fontSmall);
    y += 50;

    DrawText(hdc, g.statusText, left + 10, y, Theme::TextSecondary, g.fontBody);
    y += 40;

    // Log area
    DrawRoundRect(hdc, left + 10, y, barW, cy - y - 30, 8, Theme::BgCard, Theme::Border);
    int logY = y + 10;
    int startIdx = g.installLog.size() > 14 ? (int)(g.installLog.size() - 14) : 0;
    for (int i = startIdx; i < (int)g.installLog.size() && logY < cy - 50; i++) {
        COLORREF c = Theme::TextSecondary;
        if (g.installLog[i].find(L"\x2714") != std::wstring::npos) c = Theme::Success;
        else if (g.installLog[i].find(L"\x2716") != std::wstring::npos) c = Theme::Error;
        else if (g.installLog[i].find(L"\x26A0") != std::wstring::npos) c = Theme::Warning;
        DrawText(hdc, g.installLog[i], left + 22, logY, c, g.fontSmall);
        logY += 20;
    }
}

// ========================= Page 5: Complete =========================

static void DrawCompletePage(HDC hdc, int cx, int cy) {
    int left = 290;
    g_buttonCount = 0;
    g_checkboxes.clear();

    if (g.installSuccess) {
        // Success icon
        int iconX = left + (cx - left) / 2 - 35;
        int iconY = 50;
        HBRUSH br = CreateSolidBrush(Theme::Success);
        HBRUSH oldBr = (HBRUSH)SelectObject(hdc, br);
        HPEN pen = CreatePen(PS_SOLID, 1, Theme::Success);
        HPEN oldP = (HPEN)SelectObject(hdc, pen);
        Ellipse(hdc, iconX, iconY, iconX + 70, iconY + 70);
        SelectObject(hdc, oldBr); SelectObject(hdc, oldP);
        DeleteObject(br); DeleteObject(pen);

        HPEN chk = CreatePen(PS_SOLID, 4, Theme::BgDark);
        HPEN oldC = (HPEN)SelectObject(hdc, chk);
        MoveToEx(hdc, iconX + 18, iconY + 36, nullptr);
        LineTo(hdc, iconX + 30, iconY + 50);
        LineTo(hdc, iconX + 52, iconY + 22);
        SelectObject(hdc, oldC); DeleteObject(chk);

        std::wstring titleText = (g.installerMode == 2) ? L"Uninstallation Complete!" :
                                 (g.installerMode == 1) ? L"Update Complete!" : L"Installation Complete!";
        DrawText(hdc, titleText, left, 150, Theme::TextPrimary, g.fontTitle);
        DrawText(hdc, L"The Versatile Language Suite has been set up on your system.", left, 190, Theme::TextSecondary, g.fontBody);

        if (g.installerMode != 2) {
            int y = 240;
            DrawText(hdc, L"Getting Started", left + 10, y, Theme::Accent, g.fontBold);
            y += 36;

            struct Tip { const wchar_t* cmd; const wchar_t* desc; COLORREF accent; };
            std::vector<Tip> tips;
            if (g.installVerslang) {
                tips.push_back({ L"verslang compile hello.vlang", L"Compile a Verslang program", Theme::AccentGreen });
                tips.push_back({ L"verslang run hello.vlang",     L"Compile and run in one step", Theme::AccentGreen });
            }
            if (g.installVersscript) {
                tips.push_back({ L"verss run script.vs",    L"Run a Versscript file", Theme::AccentOrange });
                tips.push_back({ L"verss repl",             L"Start interactive REPL", Theme::AccentOrange });
            }

            for (auto& tip : tips) {
                DrawRoundRect(hdc, left + 10, y, cx - left - 60, 40, 6, Theme::BgCard, Theme::Border);
                DrawText(hdc, tip.cmd, left + 24, y + 4, tip.accent, g.fontBold);
                DrawText(hdc, tip.desc, left + 24, y + 22, Theme::TextDim, g.fontSmall);
                y += 50;
            }

            y += 10;
            DrawText(hdc, L"\x26A0  Restart your terminal for PATH changes to take effect.", left, y, Theme::Warning, g.fontSmall);
        }
    } else {
        DrawText(hdc, L"Installation Failed", left, 60, Theme::Error, g.fontTitle);
        DrawText(hdc, L"An error occurred. Check the log below.", left, 100, Theme::TextSecondary, g.fontBody);

        int y = 160;
        int barW = cx - left - 60;
        DrawRoundRect(hdc, left + 10, y, barW, cy - y - 80, 8, Theme::BgCard, Theme::Border);
        int logY = y + 10;
        for (auto& entry : g.installLog) {
            if (logY > cy - 100) break;
            COLORREF c = entry.find(L"\x2716") != std::wstring::npos ? Theme::Error : Theme::TextSecondary;
            DrawText(hdc, entry, left + 22, logY, c, g.fontSmall);
            logY += 20;
        }
    }

    int btnY = cy - 60;
    DrawButton(hdc, 0, L"Finish", cx - 140, btnY, 110, 38, true);
}

// ========================= Main Paint =========================

static void PaintWindow(HDC hdc, int cx, int cy) {
    FillRect(hdc, 0, 0, cx, cy, Theme::BgDark);
    DrawSidebar(hdc, cx, cy);
    switch (g.currentPage) {
        case 0: DrawWelcomePage(hdc, cx, cy); break;
        case 1: DrawProductsPage(hdc, cx, cy); break;
        case 2: DrawComponentsPage(hdc, cx, cy); break;
        case 3: DrawLocationPage(hdc, cx, cy); break;
        case 4: DrawInstallingPage(hdc, cx, cy); break;
        case 5: DrawCompletePage(hdc, cx, cy); break;
    }
}

// ========================= Installation Logic =========================

static void AddToSystemPath(const std::wstring& binPath) {
    HKEY hKey;
    if (RegOpenKeyExW(HKEY_LOCAL_MACHINE,
        L"SYSTEM\\CurrentControlSet\\Control\\Session Manager\\Environment",
        0, KEY_READ | KEY_WRITE, &hKey) == ERROR_SUCCESS) {
        wchar_t pathData[32768] = {};
        DWORD pathSize = sizeof(pathData);
        DWORD type = REG_EXPAND_SZ;
        RegQueryValueExW(hKey, L"Path", nullptr, &type, (LPBYTE)pathData, &pathSize);
        std::wstring currentPath = pathData;
        std::wstring pathLower = currentPath, binLower = binPath;
        for (auto& c : pathLower) c = towlower(c);
        for (auto& c : binLower) c = towlower(c);

        if (pathLower.find(binLower) == std::wstring::npos) {
            std::wstring newPath = currentPath;
            if (!newPath.empty() && newPath.back() != L';') newPath += L';';
            newPath += binPath;
            RegSetValueExW(hKey, L"Path", 0, REG_EXPAND_SZ,
                (const BYTE*)newPath.c_str(), (DWORD)((newPath.size() + 1) * sizeof(wchar_t)));
        }
        RegCloseKey(hKey);
    }
}

static void RemoveFromSystemPath(const std::wstring& binPath) {
    HKEY hKey;
    if (RegOpenKeyExW(HKEY_LOCAL_MACHINE,
        L"SYSTEM\\CurrentControlSet\\Control\\Session Manager\\Environment",
        0, KEY_READ | KEY_WRITE, &hKey) == ERROR_SUCCESS) {
        wchar_t pathData[32768] = {};
        DWORD pathSize = sizeof(pathData);
        DWORD type = REG_EXPAND_SZ;
        RegQueryValueExW(hKey, L"Path", nullptr, &type, (LPBYTE)pathData, &pathSize);
        std::wstring currentPath = pathData;
        std::wstring pathLower = currentPath, binLower = binPath;
        for (auto& c : pathLower) c = towlower(c);
        for (auto& c : binLower) c = towlower(c);
        auto pos = pathLower.find(binLower);
        if (pos != std::wstring::npos) {
            std::wstring newPath = currentPath;
            size_t endPos = pos + binPath.size();
            if (endPos < newPath.size() && newPath[endPos] == L';') endPos++;
            else if (pos > 0 && newPath[pos - 1] == L';') pos--;
            newPath.erase(pos, endPos - pos);
            RegSetValueExW(hKey, L"Path", 0, REG_EXPAND_SZ,
                (const BYTE*)newPath.c_str(), (DWORD)((newPath.size() + 1) * sizeof(wchar_t)));
        }
        RegCloseKey(hKey);
    }
}

static void RegisterFileAssociation(const std::wstring& ext, const std::wstring& typeName,
                                     const std::wstring& typeDesc, const std::wstring& exePath,
                                     const std::wstring& runArg) {
    HKEY hKey;
    if (RegCreateKeyExW(HKEY_CLASSES_ROOT, ext.c_str(), 0, nullptr, 0, KEY_WRITE, nullptr, &hKey, nullptr) == ERROR_SUCCESS) {
        RegSetValueExW(hKey, nullptr, 0, REG_SZ, (const BYTE*)typeName.c_str(), (DWORD)((typeName.size() + 1) * sizeof(wchar_t)));
        RegCloseKey(hKey);
    }
    if (RegCreateKeyExW(HKEY_CLASSES_ROOT, typeName.c_str(), 0, nullptr, 0, KEY_WRITE, nullptr, &hKey, nullptr) == ERROR_SUCCESS) {
        RegSetValueExW(hKey, nullptr, 0, REG_SZ, (const BYTE*)typeDesc.c_str(), (DWORD)((typeDesc.size() + 1) * sizeof(wchar_t)));
        RegCloseKey(hKey);
    }
    std::wstring cmdKey = typeName + L"\\shell\\open\\command";
    if (RegCreateKeyExW(HKEY_CLASSES_ROOT, cmdKey.c_str(), 0, nullptr, 0, KEY_WRITE, nullptr, &hKey, nullptr) == ERROR_SUCCESS) {
        std::wstring cmd = L"\"" + exePath + L"\" " + runArg + L" \"%1\"";
        RegSetValueExW(hKey, nullptr, 0, REG_SZ, (const BYTE*)cmd.c_str(), (DWORD)((cmd.size() + 1) * sizeof(wchar_t)));
        RegCloseKey(hKey);
    }
}

static void WriteUninstallReg(const std::wstring& productName, const std::wstring& version,
                               const std::wstring& installDir, const std::wstring& uninstallCmd) {
    HKEY hKey;
    std::wstring regKey = L"SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Uninstall\\" + productName;
    if (RegCreateKeyExW(HKEY_LOCAL_MACHINE, regKey.c_str(), 0, nullptr, 0, KEY_WRITE, nullptr, &hKey, nullptr) == ERROR_SUCCESS) {
        auto setStr = [&](const wchar_t* name, const std::wstring& val) {
            RegSetValueExW(hKey, name, 0, REG_SZ, (const BYTE*)val.c_str(), (DWORD)((val.size() + 1) * sizeof(wchar_t)));
        };
        auto setDword = [&](const wchar_t* name, DWORD val) {
            RegSetValueExW(hKey, name, 0, REG_DWORD, (const BYTE*)&val, sizeof(DWORD));
        };
        setStr(L"DisplayName", productName);
        setStr(L"DisplayVersion", version);
        setStr(L"Publisher", L"Lonidev");
        setStr(L"InstallLocation", installDir);
        setStr(L"UninstallString", uninstallCmd);
        setDword(L"NoModify", 1);
        setDword(L"NoRepair", 1);
        setDword(L"EstimatedSize", 8000);
        RegCloseKey(hKey);
    }
}

static void CreateShortcut(const std::wstring& exePath, const std::wstring& args,
                            const std::wstring& desc, const std::wstring& workDir,
                            const std::wstring& lnkPath) {
    CoInitialize(nullptr);
    IShellLinkW* psl = nullptr;
    if (SUCCEEDED(CoCreateInstance(CLSID_ShellLink, nullptr, CLSCTX_INPROC_SERVER, IID_IShellLinkW, (void**)&psl))) {
        psl->SetPath(exePath.c_str());
        psl->SetArguments(args.c_str());
        psl->SetDescription(desc.c_str());
        psl->SetWorkingDirectory(workDir.c_str());
        IPersistFile* ppf = nullptr;
        if (SUCCEEDED(psl->QueryInterface(IID_IPersistFile, (void**)&ppf))) {
            ppf->Save(lnkPath.c_str(), TRUE);
            ppf->Release();
        }
        psl->Release();
    }
    CoUninitialize();
}

static void DoUninstall() {
    g.isInstalling = true;
    g.installSuccess = true;
    g.progress = 0;
    g.installLog.clear();

    auto setP = [](int pct, const std::wstring& msg) {
        g.progress = pct; g.statusText = msg; AddLog(msg);
        InvalidateRect(g.hWnd, nullptr, FALSE); Sleep(100);
    };

    setP(5, L"Starting uninstallation...");

    // Uninstall Verslang
    if (g.existingVerslang) {
        fs::path vlDir = g.existingVerslangDir;
        fs::path vlBin = vlDir / L"bin";

        setP(10, L"Removing Verslang from PATH...");
        RemoveFromSystemPath(vlBin.wstring());
        setP(15, L"\x2714  Removed Verslang from PATH");

        setP(20, L"Removing .vlang file association...");
        RegDeleteTreeW(HKEY_CLASSES_ROOT, L".vlang");
        RegDeleteTreeW(HKEY_CLASSES_ROOT, L"VerslangFile");
        setP(25, L"\x2714  Removed .vlang association");

        setP(30, L"Removing Verslang installation files...");
        try { fs::remove_all(vlDir); } catch (...) {}
        setP(35, L"\x2714  Removed Verslang directory");

        RegDeleteTreeW(HKEY_LOCAL_MACHINE, L"SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Uninstall\\Verslang");
        setP(40, L"\x2714  Removed Verslang registry entries");
    }

    // Uninstall Versscript
    if (g.existingVersscript) {
        fs::path vsDir = g.existingVersscriptDir;
        fs::path vsBin = vsDir / L"bin";

        setP(45, L"Removing Versscript from PATH...");
        RemoveFromSystemPath(vsBin.wstring());
        setP(50, L"\x2714  Removed Versscript from PATH");

        setP(55, L"Removing .vs/.verss file associations...");
        RegDeleteTreeW(HKEY_CLASSES_ROOT, L".vs");
        RegDeleteTreeW(HKEY_CLASSES_ROOT, L".verss");
        RegDeleteTreeW(HKEY_CLASSES_ROOT, L"VersscriptFile");
        setP(60, L"\x2714  Removed file associations");

        setP(70, L"Removing Versscript installation files...");
        try { fs::remove_all(vsDir); } catch (...) {}
        setP(75, L"\x2714  Removed Versscript directory");

        RegDeleteTreeW(HKEY_LOCAL_MACHINE, L"SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Uninstall\\Versscript");
        setP(80, L"\x2714  Removed Versscript registry entries");
    }

    // Remove shortcuts
    setP(85, L"Removing shortcuts...");
    wchar_t* startPath = nullptr;
    if (SUCCEEDED(SHGetKnownFolderPath(FOLDERID_CommonPrograms, 0, nullptr, &startPath))) {
        try { fs::remove_all(fs::path(startPath) / L"Verslang"); } catch (...) {}
        try { fs::remove_all(fs::path(startPath) / L"Versscript"); } catch (...) {}
        try { fs::remove_all(fs::path(startPath) / L"Versatile Suite"); } catch (...) {}
        CoTaskMemFree(startPath);
    }
    wchar_t* deskPath = nullptr;
    if (SUCCEEDED(SHGetKnownFolderPath(FOLDERID_PublicDesktop, 0, nullptr, &deskPath))) {
        try { fs::remove(fs::path(deskPath) / L"Verslang.lnk"); } catch (...) {}
        try { fs::remove(fs::path(deskPath) / L"Versscript REPL.lnk"); } catch (...) {}
        CoTaskMemFree(deskPath);
    }
    setP(90, L"\x2714  Removed shortcuts");

    SHChangeNotify(SHCNE_ASSOCCHANGED, SHCNF_IDLIST, nullptr, nullptr);
    SendMessageTimeoutW(HWND_BROADCAST, WM_SETTINGCHANGE, 0, (LPARAM)L"Environment", SMTO_ABORTIFHUNG, 5000, nullptr);

    setP(100, L"\x2714  Uninstallation complete!");
    g.installDone = true;
}

static void DoInstall() {
    g.isInstalling = true;
    g.installSuccess = true;
    g.progress = 0;
    g.installLog.clear();

    auto setP = [](int pct, const std::wstring& msg) {
        g.progress = pct; g.statusText = msg; AddLog(msg);
        InvalidateRect(g.hWnd, nullptr, FALSE); Sleep(100);
    };

    // Determine total progress segments
    bool doVL = g.installVerslang;
    bool doVS = g.installVersscript;
    int pctBase = 2;

    // Handle ZIP extraction if needed
    fs::path vlSrcDir = g.verslangSrcDir;
    fs::path vsSrcDir = g.versscriptSrcDir;
    fs::path vlTempDir, vsTempDir;

    if (g.installSource == 1) {
        wchar_t tempPath[MAX_PATH];
        GetTempPathW(MAX_PATH, tempPath);

        if (doVL && !g.verslangZipPath.empty()) {
            setP(pctBase, L"Extracting Verslang ZIP...");
            vlTempDir = fs::path(tempPath) / L"VerslangZipExtract";
            try { fs::remove_all(vlTempDir); } catch (...) {}
            if (ExtractZip(g.verslangZipPath, vlTempDir.wstring())) {
                // Check for single root folder
                int dirs = 0; fs::path single;
                for (auto& e : fs::directory_iterator(vlTempDir)) { if (e.is_directory()) { single = e.path(); dirs++; } }
                vlSrcDir = (dirs == 1) ? single : vlTempDir;
                setP(pctBase + 3, L"\x2714  Extracted Verslang ZIP");
            } else {
                setP(pctBase + 3, L"\x2716  Failed to extract Verslang ZIP");
                g.installSuccess = false; g.installDone = true; return;
            }
        }
        pctBase += 5;

        if (doVS && !g.versscriptZipPath.empty()) {
            setP(pctBase, L"Extracting Versscript ZIP...");
            vsTempDir = fs::path(tempPath) / L"VersscriptZipExtract";
            try { fs::remove_all(vsTempDir); } catch (...) {}
            if (ExtractZip(g.versscriptZipPath, vsTempDir.wstring())) {
                int dirs = 0; fs::path single;
                for (auto& e : fs::directory_iterator(vsTempDir)) { if (e.is_directory()) { single = e.path(); dirs++; } }
                vsSrcDir = (dirs == 1) ? single : vsTempDir;
                setP(pctBase + 3, L"\x2714  Extracted Versscript ZIP");
            } else {
                setP(pctBase + 3, L"\x2716  Failed to extract Versscript ZIP");
                g.installSuccess = false; g.installDone = true; return;
            }
        }
        pctBase += 5;
    }

    // ========================= Install Verslang =========================
    if (doVL) {
        int vlStart = pctBase;
        int vlEnd = doVS ? 48 : 85;

        fs::path vlInstall = g.verslangInstallDir;
        fs::path vlBin = vlInstall / L"bin";

        setP(vlStart, L"Creating Verslang directories...");
        try { fs::create_directories(vlBin); } catch (...) {
            setP(vlStart, L"\x2716  Failed to create Verslang directory");
            g.installSuccess = false; g.installDone = true; return;
        }

        // Install compiler — try embedded resource first, then file-based fallback
        setP(vlStart + 5, L"Installing Verslang compiler...");
        bool vlExeInstalled = false;

        // Primary: extract from embedded resource
        if (!vlExeInstalled && g.installSource == 0 && HasEmbeddedResource(IDR_VERSLANG_EXE)) {
            if (ExtractEmbeddedResource(IDR_VERSLANG_EXE, vlBin / L"verslang.exe")) {
                setP(vlStart + 10, L"\x2714  Installed verslang.exe (embedded)");
                vlExeInstalled = true;
            }
        }

        // Fallback: search source directories
        if (!vlExeInstalled) {
            fs::path vlExeSrc;
            fs::path candidates[] = {
                fs::path(vlSrcDir) / L"build" / L"verslang.exe",
                fs::path(vlSrcDir) / L"bin" / L"verslang.exe",
                fs::path(vlSrcDir) / L"cmake-build" / L"Release" / L"verslang.exe",
                fs::path(vlSrcDir) / L"verslang.exe",
            };
            for (auto& c : candidates) {
                if (SafeExists(c)) { vlExeSrc = c; break; }
            }
            if (!vlExeSrc.empty()) {
                try {
                    fs::copy_file(vlExeSrc, vlBin / L"verslang.exe", fs::copy_options::overwrite_existing);
                    setP(vlStart + 10, L"\x2714  Installed verslang.exe");
                    vlExeInstalled = true;
                } catch (...) {
                    setP(vlStart + 10, L"\x2716  Failed to copy verslang.exe");
                }
            }
        }

        if (!vlExeInstalled) {
            setP(vlStart + 10, L"\x2716  verslang.exe not found");
            g.installSuccess = false;
        }

        // Copy examples
        if (g.verslangExamples) {
            setP(vlStart + 14, L"Installing Verslang examples...");
            fs::path exDir = fs::path(vlSrcDir) / L"examples";
            if (fs::exists(exDir)) {
                CopyDir(exDir, vlInstall / L"examples");
                setP(vlStart + 18, L"\x2714  Installed examples");
            } else {
                setP(vlStart + 18, L"\x26A0  No examples found");
            }
        }

        // Copy stdlib
        if (g.verslangStdlib) {
            setP(vlStart + 20, L"Installing Verslang stdlib...");
            fs::path stdDir = fs::path(vlSrcDir) / L"stdlib";
            if (fs::exists(stdDir)) {
                CopyDir(stdDir, vlInstall / L"stdlib");
                setP(vlStart + 22, L"\x2714  Installed stdlib");
            } else {
                setP(vlStart + 22, L"\x26A0  No stdlib found");
            }
        }

        // Add to PATH
        if (g.verslangAddToPath) {
            setP(vlStart + 24, L"Adding Verslang to PATH...");
            AddToSystemPath(vlBin.wstring());
            setP(vlStart + 26, L"\x2714  Added Verslang to PATH");
        }

        // File association
        if (g.verslangFileAssoc) {
            setP(vlStart + 28, L"Registering .vlang file association...");
            RegisterFileAssociation(L".vlang", L"VerslangFile", L"Verslang Source File",
                                     (vlBin / L"verslang.exe").wstring(), L"compile");
            setP(vlStart + 30, L"\x2714  Registered .vlang association");
        }

        // VS Code extension
        if (g.verslangVSCode && g.vscodeDetected) {
            setP(vlStart + 32, L"Installing Verslang VS Code extension...");
            std::wstring vsixFile = g.vsixPath.empty() ? g.verslangVsixPath : g.vsixPath;
            if (!vsixFile.empty() && fs::exists(vsixFile)) {
                if (RunCodeCommand(L"--install-extension \"" + vsixFile + L"\" --force")) {
                    setP(vlStart + 35, L"\x2714  Installed VS Code extension");
                } else {
                    setP(vlStart + 35, L"\x26A0  VS Code extension install failed");
                }
            } else {
                setP(vlStart + 35, L"\x26A0  No .vsix file found for Verslang");
            }
        }

        // Uninstall registry
        WriteUninstallReg(L"Verslang", L"1.0.0", vlInstall.wstring(),
                          L"\"" + (vlBin / L"verslang.exe").wstring() + L"\" --uninstall");

        setP(vlEnd, L"\x2714  Verslang installation complete");
    }

    // ========================= Install Versscript =========================
    if (doVS) {
        int vsStart = doVL ? 50 : pctBase;
        int vsEnd = 85;

        fs::path vsInstall = g.versscriptInstallDir;
        fs::path vsBin = vsInstall / L"bin";

        setP(vsStart, L"Creating Versscript directories...");
        try { fs::create_directories(vsBin); } catch (...) {
            setP(vsStart, L"\x2716  Failed to create Versscript directory");
            g.installSuccess = false; g.installDone = true; return;
        }

        // Install runtime — try embedded resource first, then file-based fallback
        setP(vsStart + 3, L"Installing Versscript runtime...");
        bool vsExeInstalled = false;

        // Primary: extract from embedded resource
        if (!vsExeInstalled && g.installSource == 0 && HasEmbeddedResource(IDR_VERSS_EXE)) {
            if (ExtractEmbeddedResource(IDR_VERSS_EXE, vsBin / L"verss.exe")) {
                setP(vsStart + 8, L"\x2714  Installed verss.exe (embedded)");
                vsExeInstalled = true;
            }
        }

        // Fallback: search source directories
        if (!vsExeInstalled) {
            fs::path vsExeSrc;
            fs::path candidates[] = {
                fs::path(vsSrcDir) / L"build" / L"verss.exe",
                fs::path(vsSrcDir) / L"bin" / L"verss.exe",
                fs::path(vsSrcDir) / L"cmake-build" / L"Release" / L"verss.exe",
                fs::path(vsSrcDir) / L"verss.exe",
            };
            for (auto& c : candidates) {
                if (SafeExists(c)) { vsExeSrc = c; break; }
            }
            if (!vsExeSrc.empty()) {
                try {
                    fs::copy_file(vsExeSrc, vsBin / L"verss.exe", fs::copy_options::overwrite_existing);
                    setP(vsStart + 8, L"\x2714  Installed verss.exe");
                    vsExeInstalled = true;
                } catch (...) {
                    setP(vsStart + 8, L"\x2716  Failed to copy verss.exe");
                }
            }
        }

        if (!vsExeInstalled) {
            setP(vsStart + 8, L"\x2716  verss.exe not found");
            g.installSuccess = false;
        }

        // Copy examples
        if (g.versscriptExamples) {
            setP(vsStart + 10, L"Installing Versscript examples...");
            fs::path exDir = fs::path(vsSrcDir) / L"examples";
            if (fs::exists(exDir)) {
                fs::path destEx = vsInstall / L"examples";
                try {
                    fs::create_directories(destEx);
                    int count = 0;
                    for (auto& f : fs::directory_iterator(exDir)) {
                        if (f.path().extension() == L".vs") {
                            fs::copy_file(f.path(), destEx / f.path().filename(), fs::copy_options::overwrite_existing);
                            count++;
                        }
                    }
                    setP(vsStart + 13, L"\x2714  Installed " + std::to_wstring(count) + L" example scripts");
                } catch (...) {
                    setP(vsStart + 13, L"\x26A0  Some examples failed to copy");
                }
            }
        }

        // Copy docs
        if (g.versscriptDocs) {
            setP(vsStart + 14, L"Installing Versscript documentation...");
            fs::path docsDir = fs::path(vsSrcDir) / L"docs";
            if (fs::exists(docsDir)) {
                CopyDir(docsDir, vsInstall / L"docs");
                setP(vsStart + 16, L"\x2714  Installed documentation");
            }
        }

        // Add to PATH
        if (g.versscriptAddToPath) {
            setP(vsStart + 18, L"Adding Versscript to PATH...");
            AddToSystemPath(vsBin.wstring());
            setP(vsStart + 20, L"\x2714  Added Versscript to PATH");
        }

        // File associations
        if (g.versscriptFileAssoc) {
            setP(vsStart + 22, L"Registering .vs/.verss file associations...");
            RegisterFileAssociation(L".vs", L"VersscriptFile", L"Versscript File",
                                     (vsBin / L"verss.exe").wstring(), L"run");
            RegisterFileAssociation(L".verss", L"VersscriptFile", L"Versscript File",
                                     (vsBin / L"verss.exe").wstring(), L"run");
            setP(vsStart + 24, L"\x2714  Registered .vs and .verss associations");
        }

        // VS Code extension
        if (g.versscriptVSCode && g.vscodeDetected) {
            setP(vsStart + 26, L"Installing Versscript VS Code extension...");
            // Prefer unified extension, then versscript-specific
            std::wstring vsixFile = g.vsixPath.empty() ? g.versscriptVsixPath : g.vsixPath;
            if (!vsixFile.empty() && fs::exists(vsixFile)) {
                if (RunCodeCommand(L"--install-extension \"" + vsixFile + L"\" --force")) {
                    setP(vsStart + 29, L"\x2714  Installed VS Code extension");
                } else {
                    setP(vsStart + 29, L"\x26A0  VS Code extension install failed");
                }
            } else {
                setP(vsStart + 29, L"\x26A0  No .vsix file found for Versscript");
            }
        }

        // Uninstall registry
        WriteUninstallReg(L"Versscript", L"1.2.0", vsInstall.wstring(),
                          L"\"" + (vsBin / L"verss.exe").wstring() + L"\" --uninstall");

        setP(vsEnd, L"\x2714  Versscript installation complete");
    }

    // ========================= Shared: Shortcuts =========================
    if (g.createStartMenu) {
        setP(88, L"Creating Start Menu entries...");
        wchar_t* startMenuPath = nullptr;
        if (SUCCEEDED(SHGetKnownFolderPath(FOLDERID_CommonPrograms, 0, nullptr, &startMenuPath))) {
            if (doVL) {
                fs::path menuDir = fs::path(startMenuPath) / L"Verslang";
                try { fs::create_directories(menuDir); } catch (...) {}
                fs::path vlBin = fs::path(g.verslangInstallDir) / L"bin";
                CreateShortcut((vlBin / L"verslang.exe").wstring(), L"--help", L"Verslang Compiler",
                               vlBin.wstring(), (menuDir / L"Verslang Compiler.lnk").wstring());
            }
            if (doVS) {
                fs::path menuDir = fs::path(startMenuPath) / L"Versscript";
                try { fs::create_directories(menuDir); } catch (...) {}
                fs::path vsBin = fs::path(g.versscriptInstallDir) / L"bin";
                CreateShortcut((vsBin / L"verss.exe").wstring(), L"repl", L"Versscript REPL",
                               vsBin.wstring(), (menuDir / L"Versscript REPL.lnk").wstring());
            }
            CoTaskMemFree(startMenuPath);
            setP(91, L"\x2714  Created Start Menu entries");
        }
    }

    if (g.createDesktopShortcut) {
        setP(92, L"Creating desktop shortcuts...");
        wchar_t* deskPath = nullptr;
        if (SUCCEEDED(SHGetKnownFolderPath(FOLDERID_PublicDesktop, 0, nullptr, &deskPath))) {
            if (doVS) {
                fs::path vsBin = fs::path(g.versscriptInstallDir) / L"bin";
                CreateShortcut((vsBin / L"verss.exe").wstring(), L"repl", L"Versscript REPL",
                               vsBin.wstring(), (fs::path(deskPath) / L"Versscript REPL.lnk").wstring());
            }
            if (doVL) {
                fs::path vlBin = fs::path(g.verslangInstallDir) / L"bin";
                CreateShortcut((vlBin / L"verslang.exe").wstring(), L"--help", L"Verslang Compiler",
                               vlBin.wstring(), (fs::path(deskPath) / L"Verslang.lnk").wstring());
            }
            CoTaskMemFree(deskPath);
            setP(94, L"\x2714  Created desktop shortcuts");
        }
    }

    // Broadcast environment change
    SHChangeNotify(SHCNE_ASSOCCHANGED, SHCNF_IDLIST, nullptr, nullptr);
    SendMessageTimeoutW(HWND_BROADCAST, WM_SETTINGCHANGE, 0, (LPARAM)L"Environment", SMTO_ABORTIFHUNG, 5000, nullptr);

    setP(100, g.installSuccess ? L"\x2714  Installation complete!" : L"\x2716  Installation finished with errors");

    // Clean up temp dirs
    if (!vlTempDir.empty()) { try { fs::remove_all(vlTempDir); } catch (...) {} }
    if (!vsTempDir.empty()) { try { fs::remove_all(vsTempDir); } catch (...) {} }

    g.installDone = true;
    g.isInstalling = false;
    InvalidateRect(g.hWnd, nullptr, FALSE);
}

// ========================= Event Handlers =========================

static void OnButtonClick(int idx) {
    switch (g.currentPage) {
        case 0: // Welcome
            if (idx == 0) { // Next
                if (!IsAdmin()) { RelaunchAsAdmin(); PostQuitMessage(0); return; }
                if (g.installerMode == 2) {
                    g.currentPage = 4;
                    InvalidateRect(g.hWnd, nullptr, FALSE);
                    std::thread([]() { DoUninstall(); Sleep(600); g.currentPage = 5; InvalidateRect(g.hWnd, nullptr, FALSE); }).detach();
                } else {
                    g.scrollOffset = 0;
                    g.currentPage = 1;
                }
            } else if (idx == 1) {
                if (MessageBoxW(g.hWnd, L"Cancel the installation?", L"Versatile Setup", MB_YESNO | MB_ICONQUESTION) == IDYES)
                    PostQuitMessage(0);
            }
            break;

        case 1: // Products
            if (idx == 0) { // Next
                if (!g.installVerslang && !g.installVersscript) {
                    MessageBoxW(g.hWnd, L"Please select at least one product.", L"Versatile Setup", MB_OK | MB_ICONWARNING);
                    return;
                }
                if (g.installSource == 1) {
                    if (g.installVerslang && g.verslangZipPath.empty()) {
                        MessageBoxW(g.hWnd, L"Please select a Verslang ZIP file.", L"Versatile Setup", MB_OK | MB_ICONWARNING);
                        return;
                    }
                    if (g.installVersscript && g.versscriptZipPath.empty()) {
                        MessageBoxW(g.hWnd, L"Please select a Versscript ZIP file.", L"Versatile Setup", MB_OK | MB_ICONWARNING);
                        return;
                    }
                }
                g.scrollOffset = 0;
                g.currentPage = 2;
            } else if (idx == 1) { g.currentPage = 0; }
            else if (idx == 2) {
                if (MessageBoxW(g.hWnd, L"Cancel?", L"Versatile Setup", MB_YESNO | MB_ICONQUESTION) == IDYES) PostQuitMessage(0);
            } else if (idx == 4) { // Browse Verslang ZIP
                auto p = BrowseForZipFile(L"Select Verslang ZIP Package");
                if (!p.empty()) g.verslangZipPath = p;
            } else if (idx == 5) { // Browse Versscript ZIP
                auto p = BrowseForZipFile(L"Select Versscript ZIP Package");
                if (!p.empty()) g.versscriptZipPath = p;
            }
            break;

        case 2: // Components
            if (idx == 0) { g.currentPage = 3; }
            else if (idx == 1) { g.scrollOffset = 0; g.currentPage = 1; }
            else if (idx == 2) {
                if (MessageBoxW(g.hWnd, L"Cancel?", L"Versatile Setup", MB_YESNO | MB_ICONQUESTION) == IDYES) PostQuitMessage(0);
            }
            break;

        case 3: // Location
            if (idx == 0) { // Install
                g.currentPage = 4;
                InvalidateRect(g.hWnd, nullptr, FALSE);
                std::thread([]() { DoInstall(); Sleep(600); g.currentPage = 5; InvalidateRect(g.hWnd, nullptr, FALSE); }).detach();
            } else if (idx == 1) { g.scrollOffset = 0; g.currentPage = 2; }
            else if (idx == 2) {
                if (MessageBoxW(g.hWnd, L"Cancel?", L"Versatile Setup", MB_YESNO | MB_ICONQUESTION) == IDYES) PostQuitMessage(0);
            } else if (idx == 3) { // Browse Verslang dir
                auto p = BrowseForFolder(L"Select Verslang install directory");
                if (!p.empty()) g.verslangInstallDir = p + L"\\Verslang";
            } else if (idx == 6) { // Browse Versscript dir
                auto p = BrowseForFolder(L"Select Versscript install directory");
                if (!p.empty()) g.versscriptInstallDir = p + L"\\Versscript";
            }
            break;

        case 5: // Complete
            if (idx == 0) PostQuitMessage(0);
            break;
    }
    InvalidateRect(g.hWnd, nullptr, FALSE);
}

// ========================= Window Procedure =========================

static int HitTestButton(int x, int y) {
    for (int i = 0; i < g_buttonCount; i++) {
        auto& b = g_buttons[i];
        if (x >= b.x && x < b.x + b.w && y >= b.y && y < b.y + b.h) return i;
    }
    return -1;
}

static int HitTestCheckbox(int x, int y) {
    for (int i = 0; i < (int)g_checkboxes.size(); i++) {
        auto& cb = g_checkboxes[i];
        if (g.currentPage == 2) {
            RECT rc; GetClientRect(g.hWnd, &rc);
            int ctop = 110, cbot = rc.bottom - 70;
            if (cb.y + cb.h < ctop || cb.y > cbot) continue;
        }
        if (cb.enabled && x >= cb.x && x < cb.x + cb.w && y >= cb.y && y < cb.y + cb.h) return i;
    }
    return -1;
}

static LRESULT CALLBACK WndProc(HWND hwnd, UINT msg, WPARAM wParam, LPARAM lParam) {
    switch (msg) {
        case WM_CREATE: {
            BOOL darkMode = TRUE;
            DwmSetWindowAttribute(hwnd, 20, &darkMode, sizeof(darkMode));
            SetTimer(hwnd, 1, 100, nullptr);
            return 0;
        }
        case WM_TIMER:
            if (g.currentPage == 4) InvalidateRect(hwnd, nullptr, FALSE);
            return 0;

        case WM_PAINT: {
            PAINTSTRUCT ps;
            HDC hdc = BeginPaint(hwnd, &ps);
            RECT rc; GetClientRect(hwnd, &rc);
            int cx = rc.right, cy = rc.bottom;
            HDC memDC = CreateCompatibleDC(hdc);
            HBITMAP memBm = CreateCompatibleBitmap(hdc, cx, cy);
            HBITMAP oldBm = (HBITMAP)SelectObject(memDC, memBm);
            PaintWindow(memDC, cx, cy);
            BitBlt(hdc, 0, 0, cx, cy, memDC, 0, 0, SRCCOPY);
            SelectObject(memDC, oldBm); DeleteObject(memBm); DeleteDC(memDC);
            EndPaint(hwnd, &ps);
            return 0;
        }
        case WM_MOUSEMOVE: {
            int x = LOWORD(lParam), y = HIWORD(lParam);
            int btn = HitTestButton(x, y);
            if (btn != g.hoverButton) { g.hoverButton = btn; InvalidateRect(hwnd, nullptr, FALSE); }
            TRACKMOUSEEVENT tme = { sizeof(tme), TME_LEAVE, hwnd, 0 };
            TrackMouseEvent(&tme);
            return 0;
        }
        case WM_MOUSELEAVE:
            if (g.hoverButton != -1) { g.hoverButton = -1; InvalidateRect(hwnd, nullptr, FALSE); }
            return 0;

        case WM_MOUSEWHEEL:
            if (g.currentPage == 2) {
                g.scrollOffset -= GET_WHEEL_DELTA_WPARAM(wParam) / 3;
                if (g.scrollOffset < 0) g.scrollOffset = 0;
                InvalidateRect(hwnd, nullptr, FALSE);
            }
            return 0;

        case WM_LBUTTONDOWN: {
            int x = LOWORD(lParam), y = HIWORD(lParam);
            if (HitTestButton(x, y) >= 0) { g.buttonPressed = true; InvalidateRect(hwnd, nullptr, FALSE); }
            return 0;
        }
        case WM_LBUTTONUP: {
            int x = LOWORD(lParam), y = HIWORD(lParam);
            g.buttonPressed = false;

            int btn = HitTestButton(x, y);
            if (btn >= 0) { OnButtonClick(btn); return 0; }

            int cb = HitTestCheckbox(x, y);
            if (cb >= 0 && g_checkboxes[cb].enabled) {
                auto& item = g_checkboxes[cb];

                // Welcome page — mode selection
                if (g.currentPage == 0 && item.value == nullptr) {
                    if (cb == 0) g.installerMode = 1;
                    else if (cb == 1) g.installerMode = 2;
                    else g.installerMode = 0;
                    InvalidateRect(hwnd, nullptr, FALSE);
                    return 0;
                }

                // Products page — source selection radio buttons
                if (g.currentPage == 1 && item.value == nullptr) {
                    if (item.label == L"source_builtin") g.installSource = 0;
                    else if (item.label == L"source_zip") g.installSource = 1;
                    InvalidateRect(hwnd, nullptr, FALSE);
                    return 0;
                }

                // Normal checkbox toggle
                if (item.value != nullptr) {
                    // Don't allow unchecking required items
                    if (item.value == &g.verslangCompiler || item.value == &g.versscriptRuntime)
                        return 0;
                    *item.value = !*item.value;
                    InvalidateRect(hwnd, nullptr, FALSE);
                }
            }
            return 0;
        }
        case WM_ERASEBKGND: return 1;

        case WM_GETMINMAXINFO: {
            MINMAXINFO* mmi = (MINMAXINFO*)lParam;
            mmi->ptMinTrackSize.x = 900;
            mmi->ptMinTrackSize.y = 680;
            return 0;
        }
        case WM_CLOSE:
            if (g.isInstalling) {
                MessageBoxW(hwnd, L"Installation in progress. Please wait.", L"Versatile Setup", MB_OK | MB_ICONWARNING);
                return 0;
            }
            if (g.currentPage < 4) {
                if (MessageBoxW(hwnd, L"Cancel the installation?", L"Versatile Setup", MB_YESNO | MB_ICONQUESTION) == IDYES)
                    DestroyWindow(hwnd);
            } else DestroyWindow(hwnd);
            return 0;

        case WM_DESTROY:
            KillTimer(hwnd, 1);
            PostQuitMessage(0);
            return 0;
    }
    return DefWindowProcW(hwnd, msg, wParam, lParam);
}

// ========================= Entry Point =========================

int WINAPI wWinMain(HINSTANCE hInstance, HINSTANCE, LPWSTR, int nCmdShow) {
    g.hInst = hInstance;
    CoInitialize(nullptr);

    INITCOMMONCONTROLSEX icc = { sizeof(icc), ICC_STANDARD_CLASSES | ICC_LINK_CLASS };
    InitCommonControlsEx(&icc);

    DetectSourceDir();
    DetectVSCode();
    DetectExistingInstalls();

    if (g.existingVerslang || g.existingVersscript) g.installerMode = 1;
    if (!g.vscodeDetected) { g.verslangVSCode = false; g.versscriptVSCode = false; }

    // Fonts
    g.fontTitle    = CreateFontW(30, 0, 0, 0, FW_LIGHT, 0, 0, 0, DEFAULT_CHARSET, 0, 0, CLEARTYPE_QUALITY, 0, L"Segoe UI");
    g.fontSubtitle = CreateFontW(18, 0, 0, 0, FW_NORMAL, 0, 0, 0, DEFAULT_CHARSET, 0, 0, CLEARTYPE_QUALITY, 0, L"Segoe UI");
    g.fontBody     = CreateFontW(15, 0, 0, 0, FW_NORMAL, 0, 0, 0, DEFAULT_CHARSET, 0, 0, CLEARTYPE_QUALITY, 0, L"Segoe UI");
    g.fontSmall    = CreateFontW(13, 0, 0, 0, FW_NORMAL, 0, 0, 0, DEFAULT_CHARSET, 0, 0, CLEARTYPE_QUALITY, 0, L"Segoe UI");
    g.fontBold     = CreateFontW(15, 0, 0, 0, FW_SEMIBOLD, 0, 0, 0, DEFAULT_CHARSET, 0, 0, CLEARTYPE_QUALITY, 0, L"Segoe UI Semibold");
    g.fontIcon     = CreateFontW(20, 0, 0, 0, FW_NORMAL, 0, 0, 0, DEFAULT_CHARSET, 0, 0, CLEARTYPE_QUALITY, 0, L"Segoe UI Symbol");
    g.fontBig      = CreateFontW(36, 0, 0, 0, FW_LIGHT, 0, 0, 0, DEFAULT_CHARSET, 0, 0, CLEARTYPE_QUALITY, 0, L"Segoe UI");

    WNDCLASSEXW wc = {};
    wc.cbSize = sizeof(wc);
    wc.style = CS_HREDRAW | CS_VREDRAW;
    wc.lpfnWndProc = WndProc;
    wc.hInstance = hInstance;
    wc.hCursor = LoadCursorW(nullptr, MAKEINTRESOURCEW(32512));
    wc.lpszClassName = L"VersatileInstaller";
    wc.hIcon = LoadIconW(nullptr, MAKEINTRESOURCEW(32512));
    RegisterClassExW(&wc);

    int screenW = GetSystemMetrics(SM_CXSCREEN);
    int screenH = GetSystemMetrics(SM_CYSCREEN);
    int winW = 940, winH = 720;

    g.hWnd = CreateWindowExW(0, L"VersatileInstaller", L"Versatile Suite Setup",
        WS_OVERLAPPEDWINDOW & ~WS_MAXIMIZEBOX,
        (screenW - winW) / 2, (screenH - winH) / 2, winW, winH,
        nullptr, nullptr, hInstance, nullptr);

    ShowWindow(g.hWnd, nCmdShow);
    UpdateWindow(g.hWnd);

    MSG msg;
    while (GetMessageW(&msg, nullptr, 0, 0) > 0) {
        TranslateMessage(&msg);
        DispatchMessageW(&msg);
    }

    DeleteObject(g.fontTitle); DeleteObject(g.fontSubtitle);
    DeleteObject(g.fontBody); DeleteObject(g.fontSmall);
    DeleteObject(g.fontBold); DeleteObject(g.fontIcon); DeleteObject(g.fontBig);

    CoUninitialize();
    return (int)msg.wParam;
}
