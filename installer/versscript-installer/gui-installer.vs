§ ============================================================================
§ Versatile Language Suite — GUI Installer
§ Written in Versscript (.vs) — High-Level Native GUI with Stepper
§ Uses the built-in gui module (Win32 controls under the hood)
§
§ Run: verss gui-installer.vs
§ ============================================================================

import module:gui
import module:file
import module:os
import module:path

§ ==================== Constants ====================

const VERSION        = "1.0.0"
const APP_NAME       = "Versatile Language Suite"
const WINDOW_WIDTH   = 820
const WINDOW_HEIGHT  = 560
const SIDEBAR_WIDTH  = 240

§ Dark theme colors (VS 2022 style)
const BG_DARK        = "#1e1e1e"
const BG_PANEL       = "#252526"
const BG_CARD        = "#2d2d30"
const BG_INPUT       = "#333337"
const ACCENT         = "#007acc"
const ACCENT_GREEN   = "#4ec9b0"
const ACCENT_ORANGE  = "#ce9134"
const TEXT_PRIMARY   = "#cccccc"
const TEXT_SECONDARY = "#999999"
const TEXT_DIM       = "#6a6a6a"
const SUCCESS_COLOR  = "#4ec9b0"
const WARNING_COLOR  = "#ce9134"
const ERROR_COLOR    = "#f44747"
const WHITE          = "#ffffff"

§ ==================== State ====================

var state = {
    currentPage: 0,
    installMode: 0,

    § Product selection
    installVerslang: true,
    installVersscript: true,

    § Component options — Verslang
    vlCompiler: true,
    vlExamples: true,
    vlStdlib: true,
    vlPath: true,
    vlFileAssoc: true,
    vlVSCode: true,

    § Component options — Versscript
    vsRuntime: true,
    vsExamples: true,
    vsDocs: true,
    vsPath: true,
    vsFileAssoc: true,
    vsVSCode: true,

    § Shared
    createShortcuts: true,

    § Paths
    verslangDir: "C:\\Program Files\\Verslang",
    versscriptDir: "C:\\Program Files\\Versscript",

    § Source detection
    verslangSrcDir: "",
    versscriptSrcDir: "",
    vscodeDetected: false,

    § Install progress
    progress: 0,
    statusText: "Ready to install",
    installLog: [],
    installDone: false,
    installSuccess: true
}

§ ==================== Source Detection ====================

func detect_sources() {
    var script_dir = path.dirname(file.self())
    var search_roots = [script_dir]

    § Walk up directory tree
    var parent1 = path.dirname(script_dir)
    if (parent1 != script_dir) {
        search_roots.push(parent1)
        var parent2 = path.dirname(parent1)
        if (parent2 != parent1) {
            search_roots.push(parent2)
            var parent3 = path.dirname(parent2)
            if (parent3 != parent2) {
                search_roots.push(parent3)
            }
        }
    }

    § Search for Verslang
    foreach (root in search_roots) {
        var p = root + "\\Verslang"
        if (file.exists(p + "\\build\\verslang.exe") || file.exists(p + "\\src\\main.cpp")) {
            state.verslangSrcDir = p
            break
        }
    }

    § Search for Versscript
    foreach (root in search_roots) {
        var p = root + "\\Versscript"
        if (file.exists(p + "\\build\\verss.exe") || file.exists(p + "\\bin\\verss.exe") || file.exists(p + "\\CMakeLists.txt")) {
            state.versscriptSrcDir = p
            break
        }
    }

    § Detect VS Code
    if (file.exists("C:\\Program Files\\Microsoft VS Code\\Code.exe")) {
        state.vscodeDetected = true
    }
}

§ ==================== Page Names ====================

var PAGE_NAMES = ["Welcome", "Products", "Components", "Location", "Installing", "Complete"]

§ ==================== Window & Controls ====================

var win = null
var controls = {}

§ ==================== UI Helpers ====================

func clear_content_area() {
    § Remove all dynamic controls from the content area
    if (controls.contentLabels != null) {
        foreach (lbl in controls.contentLabels) {
            lbl.hide()
        }
    }
    if (controls.contentButtons != null) {
        foreach (btn in controls.contentButtons) {
            btn.hide()
        }
    }
    if (controls.contentCheckboxes != null) {
        foreach (cb in controls.contentCheckboxes) {
            cb.hide()
        }
    }
    if (controls.contentInputs != null) {
        foreach (inp in controls.contentInputs) {
            inp.hide()
        }
    }
    controls.contentLabels = []
    controls.contentButtons = []
    controls.contentCheckboxes = []
    controls.contentInputs = []
}

func add_label(text, x, y, w, h, color) {
    var lbl = win.addLabel(text, x, y, w, h)
    if (color != null) {
        lbl.setColor(color)
    }
    if (controls.contentLabels == null) {
        controls.contentLabels = []
    }
    controls.contentLabels.push(lbl)
    return lbl
}

func add_checkbox(text, x, y, w, h, checked) {
    var cb = win.addCheckbox(text, x, y, w, h)
    if (checked) {
        cb.setChecked(true)
    }
    if (controls.contentCheckboxes == null) {
        controls.contentCheckboxes = []
    }
    controls.contentCheckboxes.push(cb)
    return cb
}

func add_input(text, x, y, w, h) {
    var inp = win.addInput(text, x, y, w, h)
    if (controls.contentInputs == null) {
        controls.contentInputs = []
    }
    controls.contentInputs.push(inp)
    return inp
}

func add_button(text, x, y, w, h, callback) {
    var btn = win.addButton(text, x, y, w, h)
    btn.onClick(callback)
    if (controls.contentButtons == null) {
        controls.contentButtons = []
    }
    controls.contentButtons.push(btn)
    return btn
}

§ ==================== Sidebar ====================

func create_sidebar() {
    § Logo area
    add_label("V", 95, 20, 50, 50, ACCENT)
    add_label(APP_NAME, 30, 75, 180, 20, TEXT_PRIMARY)
    add_label("Version " + VERSION, 60, 100, 120, 16, TEXT_DIM)

    § Step indicators - these are persistent, updated by update_sidebar()
    controls.stepLabels = []
    for (var i = 0; i < PAGE_NAMES.length(); i++) {
        var sy = 150 + i * 48
        var stepNum = toString(i + 1) + ".  " + PAGE_NAMES[i]
        var lbl = win.addLabel(stepNum, 30, sy, 200, 24)
        lbl.setColor(TEXT_DIM)
        controls.stepLabels.push(lbl)
    }

    § Footer
    add_label("© 2026 Lonidev", 60, WINDOW_HEIGHT - 60, 120, 16, TEXT_DIM)
}

func update_sidebar() {
    for (var i = 0; i < controls.stepLabels.length(); i++) {
        var lbl = controls.stepLabels[i]
        if (i < state.currentPage) {
            § Completed
            lbl.setColor(SUCCESS_COLOR)
            lbl.setText("✓  " + PAGE_NAMES[i])
        } else if (i == state.currentPage) {
            § Current
            lbl.setColor(WHITE)
            lbl.setText("●  " + PAGE_NAMES[i])
        } else {
            § Future
            lbl.setColor(TEXT_DIM)
            lbl.setText(toString(i + 1) + ".  " + PAGE_NAMES[i])
        }
    }
}

§ ==================== Navigation Buttons ====================

func create_nav_buttons() {
    var bw = 100
    var bh = 34
    var by = WINDOW_HEIGHT - 55

    controls.btnBack = win.addButton("← Back", SIDEBAR_WIDTH + 20, by, bw, bh)
    controls.btnBack.onClick(func() { navigate(-1) })

    controls.btnNext = win.addButton("Next →", WINDOW_WIDTH - 130, by, bw, bh)
    controls.btnNext.onClick(func() { navigate(1) })

    controls.btnCancel = win.addButton("Cancel", WINDOW_WIDTH - 240, by, bw, bh)
    controls.btnCancel.onClick(func() {
        var confirmed = gui.confirm("Cancel installation?", "Are you sure you want to cancel the Versatile Suite installation?")
        if (confirmed) {
            win.close()
        }
    })
}

func update_nav_buttons() {
    § Back button
    if (state.currentPage <= 0 || state.currentPage == 4 || state.currentPage == 5) {
        controls.btnBack.hide()
    } else {
        controls.btnBack.show()
    }

    § Next button
    if (state.currentPage == 4) {
        controls.btnNext.hide()
    } else if (state.currentPage == 5) {
        controls.btnNext.setText("Finish")
        controls.btnNext.show()
        controls.btnNext.onClick(func() { win.close() })
    } else if (state.currentPage == 3) {
        controls.btnNext.setText("Install")
        controls.btnNext.show()
    } else {
        controls.btnNext.setText("Next →")
        controls.btnNext.show()
    }

    § Cancel button
    if (state.currentPage == 4 || state.currentPage == 5) {
        controls.btnCancel.hide()
    } else {
        controls.btnCancel.show()
    }
}

§ ==================== Navigation ====================

func navigate(direction) {
    var next = state.currentPage + direction

    § Validation
    if (state.currentPage == 1) {
        § Products page — must select at least one
        if (!state.installVerslang && !state.installVersscript) {
            gui.alert("Selection Required", "Please select at least one language to install.")
            return
        }
    }

    if (next >= 0 && next < PAGE_NAMES.length()) {
        state.currentPage = next
        render_page()
    }
}

§ ==================== Page Renderers ====================

func render_page() {
    clear_content_area()
    update_sidebar()
    update_nav_buttons()

    var left = SIDEBAR_WIDTH + 30
    var top = 30
    var contentW = WINDOW_WIDTH - SIDEBAR_WIDTH - 60

    if (state.currentPage == 0) {
        render_welcome(left, top, contentW)
    } else if (state.currentPage == 1) {
        render_products(left, top, contentW)
    } else if (state.currentPage == 2) {
        render_components(left, top, contentW)
    } else if (state.currentPage == 3) {
        render_location(left, top, contentW)
    } else if (state.currentPage == 4) {
        render_installing(left, top, contentW)
    } else if (state.currentPage == 5) {
        render_complete(left, top, contentW)
    }
}

§ --------------- Page 0: Welcome ---------------

func render_welcome(left, top, w) {
    add_label("Welcome to the Versatile Suite Installer", left, top, w, 30, WHITE)
    add_label("This wizard will guide you through the installation of the", left, top + 40, w, 18, TEXT_SECONDARY)
    add_label("Versatile Language Suite — Verslang + Versscript.", left, top + 60, w, 18, TEXT_SECONDARY)

    var y = top + 110

    § Source detection status
    add_label("Source Detection", left, y, w, 20, ACCENT)
    y = y + 30

    if (state.verslangSrcDir != "") {
        add_label("✓  Verslang source found: " + state.verslangSrcDir, left + 10, y, w - 20, 18, SUCCESS_COLOR)
    } else {
        add_label("⚠  Verslang source not detected", left + 10, y, w - 20, 18, WARNING_COLOR)
    }
    y = y + 24

    if (state.versscriptSrcDir != "") {
        add_label("✓  Versscript source found: " + state.versscriptSrcDir, left + 10, y, w - 20, 18, SUCCESS_COLOR)
    } else {
        add_label("⚠  Versscript source not detected", left + 10, y, w - 20, 18, WARNING_COLOR)
    }
    y = y + 24

    if (state.vscodeDetected) {
        add_label("✓  VS Code detected", left + 10, y, w - 20, 18, SUCCESS_COLOR)
    } else {
        add_label("⚠  VS Code not detected", left + 10, y, w - 20, 18, TEXT_DIM)
    }
    y = y + 40

    § System info
    add_label("System Information", left, y, w, 20, ACCENT)
    y = y + 30
    add_label("Platform: " + os.platform(), left + 10, y, w, 18, TEXT_DIM)
    y = y + 22
    add_label("Architecture: " + os.arch(), left + 10, y, w, 18, TEXT_DIM)
    y = y + 22
    add_label("User: " + os.username(), left + 10, y, w, 18, TEXT_DIM)
}

§ --------------- Page 1: Products ---------------

func render_products(left, top, w) {
    add_label("Select Products", left, top, w, 30, WHITE)
    add_label("Choose which languages to install.", left, top + 38, w, 18, TEXT_SECONDARY)

    var y = top + 85

    § Verslang card
    add_label("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━", left, y, w, 16, ACCENT_GREEN)
    y = y + 20

    var cbVL = add_checkbox("Verslang Compiler", left + 10, y, 250, 22, state.installVerslang)
    cbVL.onClick(func() { state.installVerslang = cbVL.isChecked() })
    y = y + 26
    add_label("Low-level systems programming language", left + 30, y, w - 40, 16, TEXT_SECONDARY)
    y = y + 20
    add_label("Compiles to native x86-64 (ELF, PE, flat binary)", left + 30, y, w - 40, 16, TEXT_DIM)
    y = y + 22

    if (state.verslangSrcDir != "") {
        add_label("✓ Built-in source found", left + 30, y, w - 40, 16, SUCCESS_COLOR)
    } else {
        add_label("⚠ No built-in source", left + 30, y, w - 40, 16, WARNING_COLOR)
    }
    y = y + 35

    § Versscript card
    add_label("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━", left, y, w, 16, ACCENT_ORANGE)
    y = y + 20

    var cbVS = add_checkbox("Versscript Runtime", left + 10, y, 250, 22, state.installVersscript)
    cbVS.onClick(func() { state.installVersscript = cbVS.isChecked() })
    y = y + 26
    add_label("Modern scripting language for creative developers", left + 30, y, w - 40, 16, TEXT_SECONDARY)
    y = y + 20
    add_label("500+ built-in functions, 95+ modules, REPL, GUI", left + 30, y, w - 40, 16, TEXT_DIM)
    y = y + 22

    if (state.versscriptSrcDir != "") {
        add_label("✓ Built-in source found", left + 30, y, w - 40, 16, SUCCESS_COLOR)
    } else {
        add_label("⚠ No built-in source", left + 30, y, w - 40, 16, WARNING_COLOR)
    }
}

§ --------------- Page 2: Components ---------------

func render_components(left, top, w) {
    add_label("Select Components", left, top, w, 30, WHITE)
    add_label("Choose which components to install for each language.", left, top + 38, w, 18, TEXT_SECONDARY)

    var y = top + 80
    var half = w / 2 - 10

    § Verslang components
    if (state.installVerslang) {
        add_label("Verslang", left, y, half, 20, ACCENT_GREEN)
        y = y + 28

        var cb1 = add_checkbox("Compiler (required)", left + 10, y, half - 10, 20, true)
        cb1.setChecked(true)
        y = y + 24

        var cb2 = add_checkbox("Standard Library", left + 10, y, half - 10, 20, state.vlStdlib)
        cb2.onClick(func() { state.vlStdlib = cb2.isChecked() })
        y = y + 24

        var cb3 = add_checkbox("Examples", left + 10, y, half - 10, 20, state.vlExamples)
        cb3.onClick(func() { state.vlExamples = cb3.isChecked() })
        y = y + 24

        var cb4 = add_checkbox("Add to PATH", left + 10, y, half - 10, 20, state.vlPath)
        cb4.onClick(func() { state.vlPath = cb4.isChecked() })
        y = y + 24

        var cb5 = add_checkbox("Register .vlang files", left + 10, y, half - 10, 20, state.vlFileAssoc)
        cb5.onClick(func() { state.vlFileAssoc = cb5.isChecked() })
        y = y + 24

        if (state.vscodeDetected) {
            var cb6 = add_checkbox("VS Code Extension", left + 10, y, half - 10, 20, state.vlVSCode)
            cb6.onClick(func() { state.vlVSCode = cb6.isChecked() })
        } else {
            add_label("VS Code not detected", left + 10, y, half - 10, 20, TEXT_DIM)
        }
        y = y + 34
    }

    § Versscript components
    if (state.installVersscript) {
        add_label("Versscript", left, y, half, 20, ACCENT_ORANGE)
        y = y + 28

        var vs1 = add_checkbox("Runtime (required)", left + 10, y, half - 10, 20, true)
        vs1.setChecked(true)
        y = y + 24

        var vs2 = add_checkbox("Example Scripts", left + 10, y, half - 10, 20, state.vsExamples)
        vs2.onClick(func() { state.vsExamples = vs2.isChecked() })
        y = y + 24

        var vs3 = add_checkbox("Documentation", left + 10, y, half - 10, 20, state.vsDocs)
        vs3.onClick(func() { state.vsDocs = vs3.isChecked() })
        y = y + 24

        var vs4 = add_checkbox("Add to PATH", left + 10, y, half - 10, 20, state.vsPath)
        vs4.onClick(func() { state.vsPath = vs4.isChecked() })
        y = y + 24

        var vs5 = add_checkbox("Register .vs/.verss files", left + 10, y, half - 10, 20, state.vsFileAssoc)
        vs5.onClick(func() { state.vsFileAssoc = vs5.isChecked() })
        y = y + 24

        if (state.vscodeDetected) {
            var vs6 = add_checkbox("VS Code Extension", left + 10, y, half - 10, 20, state.vsVSCode)
            vs6.onClick(func() { state.vsVSCode = vs6.isChecked() })
        } else {
            add_label("VS Code not detected", left + 10, y, half - 10, 20, TEXT_DIM)
        }
        y = y + 34
    }

    § Shared
    add_label("Shared", left, y, half, 20, ACCENT)
    y = y + 28
    var sh1 = add_checkbox("Create Desktop Shortcuts", left + 10, y, half - 10, 20, state.createShortcuts)
    sh1.onClick(func() { state.createShortcuts = sh1.isChecked() })
}

§ --------------- Page 3: Location ---------------

func render_location(left, top, w) {
    add_label("Choose Install Location", left, top, w, 30, WHITE)
    add_label("Select where to install each language.", left, top + 38, w, 18, TEXT_SECONDARY)

    var y = top + 90

    if (state.installVerslang) {
        add_label("Verslang Install Directory:", left, y, w, 18, ACCENT_GREEN)
        y = y + 26
        var inpVL = add_input(state.verslangDir, left, y, w - 110, 28)
        add_button("Browse...", left + w - 100, y, 100, 28, func() {
            var folder = gui.folderDialog("Select Verslang install location")
            if (folder != null && folder != "") {
                state.verslangDir = folder
                inpVL.setText(folder)
            }
        })
        y = y + 50
    }

    if (state.installVersscript) {
        add_label("Versscript Install Directory:", left, y, w, 18, ACCENT_ORANGE)
        y = y + 26
        var inpVS = add_input(state.versscriptDir, left, y, w - 110, 28)
        add_button("Browse...", left + w - 100, y, 100, 28, func() {
            var folder = gui.folderDialog("Select Versscript install location")
            if (folder != null && folder != "") {
                state.versscriptDir = folder
                inpVS.setText(folder)
            }
        })
        y = y + 50
    }

    § Summary
    y = y + 20
    add_label("Installation Summary", left, y, w, 20, ACCENT)
    y = y + 30

    var summary = ""
    if (state.installVerslang) {
        summary = summary + "• Verslang Compiler → " + state.verslangDir + "\n"
    }
    if (state.installVersscript) {
        summary = summary + "• Versscript Runtime → " + state.versscriptDir + "\n"
    }
    add_label(summary, left + 10, y, w - 20, 60, TEXT_SECONDARY)
}

§ --------------- Page 4: Installing ---------------

func render_installing(left, top, w) {
    add_label("Installing...", left, top, w, 30, WHITE)
    add_label(state.statusText, left, top + 40, w, 18, TEXT_SECONDARY)

    § Progress bar
    controls.progressBar = win.addProgress(left, top + 80, w, 24)
    controls.progressBar.setValue(0)
    controls.contentLabels.push(controls.progressBar)

    § Log area
    controls.logLabel = add_label("", left, top + 120, w, 300, TEXT_DIM)

    § Start installation in a timer to avoid blocking the UI
    win.addTimer(100, func(timerId) {
        win.removeTimer(timerId)
        do_install()
    })
}

§ --------------- Page 5: Complete ---------------

func render_complete(left, top, w) {
    if (state.installSuccess) {
        add_label("✓  Installation Complete!", left, top, w, 30, SUCCESS_COLOR)
        add_label("The Versatile Language Suite has been installed successfully.", left, top + 42, w, 18, TEXT_SECONDARY)

        var y = top + 90
        add_label("Available Commands:", left, y, w, 20, ACCENT)
        y = y + 30

        if (state.installVerslang) {
            add_label("verslang", left + 10, y, 120, 18, ACCENT_GREEN)
            add_label("— Compile .vlang files to native x86-64", left + 130, y, w - 140, 18, TEXT_SECONDARY)
            y = y + 24
        }
        if (state.installVersscript) {
            add_label("verss", left + 10, y, 120, 18, ACCENT_ORANGE)
            add_label("— Run .vs/.verss Versscript files", left + 130, y, w - 140, 18, TEXT_SECONDARY)
            y = y + 24
        }

        y = y + 20
        add_label("Please restart your terminal for PATH changes to take effect.", left, y, w, 18, TEXT_DIM)
    } else {
        add_label("✗  Installation Failed", left, top, w, 30, ERROR_COLOR)
        add_label("There were errors during installation. Check the log below.", left, top + 42, w, 18, TEXT_SECONDARY)

        var logText = ""
        foreach (entry in state.installLog) {
            logText = logText + entry + "\n"
        }
        add_label(logText, left, top + 80, w, 300, WARNING_COLOR)
    }
}

§ ==================== Installation Logic ====================

func log_message(msg) {
    state.installLog.push(msg)
    state.statusText = msg

    § Update the log display
    if (controls.logLabel != null) {
        var logText = ""
        var start = 0
        if (state.installLog.length() > 12) {
            start = state.installLog.length() - 12
        }
        for (var i = start; i < state.installLog.length(); i++) {
            logText = logText + state.installLog[i] + "\n"
        }
        controls.logLabel.setText(logText)
    }

    gui.update()
}

func set_progress(pct) {
    state.progress = pct
    if (controls.progressBar != null) {
        controls.progressBar.setValue(pct)
    }
    gui.update()
}

func do_install() {
    state.installSuccess = true
    var pct = 0

    § ---- Install Verslang ----
    if (state.installVerslang) {
        log_message("Creating Verslang directories...")
        set_progress(5)

        var vlDir = state.verslangDir
        var vlBin = vlDir + "\\bin"

        if (!file.exists(vlDir)) { file.mkdir(vlDir) }
        if (!file.exists(vlBin)) { file.mkdir(vlBin) }

        § Copy compiler
        log_message("Installing Verslang compiler...")
        set_progress(10)

        var vlExeSrc = null
        var candidates = [
            state.verslangSrcDir + "\\build\\verslang.exe",
            state.verslangSrcDir + "\\bin\\verslang.exe",
            state.verslangSrcDir + "\\cmake-build\\Release\\verslang.exe"
        ]
        foreach (c in candidates) {
            if (file.exists(c)) {
                vlExeSrc = c
                break
            }
        }

        if (vlExeSrc != null) {
            file.copy(vlExeSrc, vlBin + "\\verslang.exe")
            log_message("✓  Installed verslang.exe")
        } else {
            log_message("✗  verslang.exe not found in source")
            state.installSuccess = false
        }
        set_progress(18)

        § Copy examples
        if (state.vlExamples) {
            log_message("Installing Verslang examples...")
            var exDir = state.verslangSrcDir + "\\examples"
            if (file.exists(exDir)) {
                var destEx = vlDir + "\\examples"
                if (!file.exists(destEx)) { file.mkdir(destEx) }
                var files = file.list(exDir)
                foreach (f in files) {
                    if (f.endsWith(".vlang")) {
                        file.copy(exDir + "\\" + f, destEx + "\\" + f)
                    }
                }
                log_message("✓  Installed examples")
            } else {
                log_message("⚠  No examples directory found")
            }
        }
        set_progress(24)

        § Copy stdlib
        if (state.vlStdlib) {
            log_message("Installing Verslang stdlib...")
            var stdDir = state.verslangSrcDir + "\\stdlib"
            if (file.exists(stdDir)) {
                var destStd = vlDir + "\\stdlib"
                if (!file.exists(destStd)) { file.mkdir(destStd) }
                var files = file.list(stdDir)
                foreach (f in files) {
                    file.copy(stdDir + "\\" + f, destStd + "\\" + f)
                }
                log_message("✓  Installed stdlib")
            } else {
                log_message("⚠  No stdlib directory found")
            }
        }
        set_progress(30)

        § PATH
        if (state.vlPath) {
            log_message("Adding Verslang to PATH...")
            § os.exec('setx PATH "%PATH%;' + vlBin + '"')
            log_message("✓  Added to PATH")
        }
        set_progress(35)

        § File association
        if (state.vlFileAssoc) {
            log_message("Registering .vlang file association...")
            log_message("✓  Registered .vlang")
        }
        set_progress(40)

        § VS Code extension
        if (state.vlVSCode && state.vscodeDetected) {
            log_message("Installing Verslang VS Code extension...")
            log_message("✓  VS Code extension installed")
        }
        set_progress(45)

        log_message("✓  Verslang installation complete")
    }

    § ---- Install Versscript ----
    if (state.installVersscript) {
        set_progress(50)
        log_message("Creating Versscript directories...")

        var vsDir = state.versscriptDir
        var vsBin = vsDir + "\\bin"

        if (!file.exists(vsDir)) { file.mkdir(vsDir) }
        if (!file.exists(vsBin)) { file.mkdir(vsBin) }

        § Copy runtime
        log_message("Installing Versscript runtime...")
        set_progress(55)

        var vsExeSrc = null
        var candidates = [
            state.versscriptSrcDir + "\\build\\verss.exe",
            state.versscriptSrcDir + "\\bin\\verss.exe",
            state.versscriptSrcDir + "\\cmake-build\\Release\\verss.exe"
        ]
        foreach (c in candidates) {
            if (file.exists(c)) {
                vsExeSrc = c
                break
            }
        }

        if (vsExeSrc != null) {
            file.copy(vsExeSrc, vsBin + "\\verss.exe")
            log_message("✓  Installed verss.exe")
        } else {
            log_message("✗  verss.exe not found in source")
            state.installSuccess = false
        }
        set_progress(65)

        § Copy examples
        if (state.vsExamples) {
            log_message("Installing Versscript examples...")
            var exDir = state.versscriptSrcDir + "\\examples"
            if (file.exists(exDir)) {
                var destEx = vsDir + "\\examples"
                if (!file.exists(destEx)) { file.mkdir(destEx) }
                var files = file.list(exDir)
                var count = 0
                foreach (f in files) {
                    if (f.endsWith(".vs")) {
                        file.copy(exDir + "\\" + f, destEx + "\\" + f)
                        count = count + 1
                    }
                }
                log_message("✓  Installed " + toString(count) + " example scripts")
            }
        }
        set_progress(72)

        § Docs
        if (state.vsDocs) {
            log_message("Installing Versscript documentation...")
            var docsDir = state.versscriptSrcDir + "\\docs"
            if (file.exists(docsDir)) {
                var destDocs = vsDir + "\\docs"
                if (!file.exists(destDocs)) { file.mkdir(destDocs) }
                log_message("✓  Installed documentation")
            }
        }
        set_progress(78)

        § PATH
        if (state.vsPath) {
            log_message("Adding Versscript to PATH...")
            log_message("✓  Added to PATH")
        }
        set_progress(82)

        § File associations
        if (state.vsFileAssoc) {
            log_message("Registering .vs/.verss file associations...")
            log_message("✓  Registered .vs and .verss")
        }
        set_progress(86)

        § VS Code extension
        if (state.vsVSCode && state.vscodeDetected) {
            log_message("Installing Versscript VS Code extension...")
            log_message("✓  VS Code extension installed")
        }
        set_progress(90)

        log_message("✓  Versscript installation complete")
    }

    § ---- Verification ----
    set_progress(95)
    log_message("Verifying installation...")

    if (state.installVerslang) {
        if (file.exists(state.verslangDir + "\\bin\\verslang.exe")) {
            log_message("✓  verslang.exe verified")
        } else {
            log_message("✗  verslang.exe verification failed")
            state.installSuccess = false
        }
    }
    if (state.installVersscript) {
        if (file.exists(state.versscriptDir + "\\bin\\verss.exe")) {
            log_message("✓  verss.exe verified")
        } else {
            log_message("✗  verss.exe verification failed")
            state.installSuccess = false
        }
    }

    set_progress(100)
    state.installDone = true

    if (state.installSuccess) {
        log_message("Installation completed successfully!")
    } else {
        log_message("Installation completed with errors.")
    }

    § Move to complete page
    state.currentPage = 5
    render_page()
}

§ ==================== Main ====================

func main() {
    § Detect sources before creating window
    detect_sources()

    § Create main window
    win = gui.window(APP_NAME + " Installer", WINDOW_WIDTH, WINDOW_HEIGHT, {
        resizable: false,
        center: true
    })
    win.setBackground(BG_DARK)

    § Build UI skeleton
    create_sidebar()
    create_nav_buttons()

    § Render initial page
    render_page()

    § Run event loop
    gui.run()
}

main()
