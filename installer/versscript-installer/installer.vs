§ ============================================================================
§ Versatile Language Suite Installer
§ Written entirely in Versscript (.vs) as a test project
§ Demonstrates Versscript's rich standard library for real-world tooling
§ 
§ Run: verss installer.vs
§ Run with args: verss installer.vs --mode full
§ ============================================================================

import module:file
import module:os
import module:path

§ --- Constants ---

const VERSION = "1.0.0"
const APP_NAME = "Versatile Language Suite"

const COMPONENT_VERSLANG    = "Verslang Compiler"
const COMPONENT_VERSSCRIPT  = "Versscript Runtime"
const COMPONENT_RUNTIME     = "Versatile Runtime"
const COMPONENT_VSCODE      = "VS Code Extension"
const COMPONENT_DOCS        = "Documentation"
const COMPONENT_EXAMPLES    = "Example Projects"

§ --- Color Helpers (ANSI escape codes) ---

func color(code, text) {
    return "\x1b[" + code + "m" + text + "\x1b[0m"
}

func green(text)  { return color("32", text) }
func red(text)    { return color("31", text) }
func yellow(text) { return color("33", text) }
func cyan(text)   { return color("36", text) }
func bold(text)   { return color("1", text) }
func dim(text)    { return color("2", text) }

§ --- Banner ---

func print_banner() {
    var line = "============================================================"
    println(cyan(line))
    println(cyan("  " + bold(APP_NAME + " Installer")))
    println(cyan("  Verslang + Versscript + Versatile Runtime"))
    println(cyan("  Version " + VERSION))
    println(cyan(line))
    println("")
}

§ --- Platform Detection ---

func detect_platform() {
    var plat = os.platform()
    if (plat == "windows" || plat == "win32") {
        return "windows"
    } else if (plat == "linux") {
        return "linux"
    } else if (plat == "darwin" || plat == "macos") {
        return "macos"
    }
    return "unknown"
}

§ --- Default Install Paths ---

func get_default_install_dir(platform) {
    if (platform == "windows") {
        return "C:\\Program Files\\Versatile"
    } else if (platform == "macos") {
        return "/usr/local/Cellar/versatile/" + VERSION
    }
    return "/usr/local/lib/versatile"
}

func get_bin_dir(platform, install_dir) {
    if (platform == "windows") {
        return install_dir + "\\bin"
    }
    return install_dir + "/bin"
}

§ --- Component Manifest ---

func create_manifest(mode) {
    var components = [
        {
            name: COMPONENT_VERSLANG,
            size: "2 MB",
            required: true,
            selected: true,
            installer: install_verslang
        },
        {
            name: COMPONENT_VERSSCRIPT,
            size: "4 MB",
            required: true,
            selected: true,
            installer: install_versscript
        },
        {
            name: COMPONENT_RUNTIME,
            size: "1 MB",
            required: true,
            selected: true,
            installer: install_runtime
        },
        {
            name: COMPONENT_VSCODE,
            size: "64 KB",
            required: false,
            selected: (mode == "full"),
            installer: install_vscode_extension
        },
        {
            name: COMPONENT_DOCS,
            size: "512 KB",
            required: false,
            selected: (mode == "full"),
            installer: install_documentation
        },
        {
            name: COMPONENT_EXAMPLES,
            size: "256 KB",
            required: false,
            selected: (mode == "full"),
            installer: install_examples
        }
    ]
    return components
}

§ --- Progress Display ---

func print_progress(current, total) {
    var bar_width = 40
    var filled = (current * bar_width) / total
    var bar = ""
    for (var i = 0; i < bar_width; i++) {
        if (i < filled) {
            bar = bar + "█"
        } else {
            bar = bar + "░"
        }
    }
    var pct = (current * 100) / total
    print("\r  [" + green(bar) + "] " + pct + "% ")
}

func print_step(step_num, total, message) {
    println("  " + dim("[" + step_num + "/" + total + "]") + " " + message)
}

§ --- Component Installers ---

func install_verslang(platform, install_dir) {
    var target = ""
    if (platform == "windows") {
        target = install_dir + "\\verslang"
    } else {
        target = install_dir + "/verslang"
    }

    println("        Target: " + dim(target))

    § Create installation directory
    if (!file.exists(target)) {
        file.mkdir(target)
    }

    § In a real installer, we'd copy the compiler binary:
    §   file.copy("./dist/verslang.exe", target + "\\verslang.exe")  (Windows)
    §   file.copy("./dist/verslang", target + "/verslang")           (Linux/macOS)

    § Write version marker
    file.write(target + "/version.txt", "verslang " + VERSION)

    return true
}

func install_versscript(platform, install_dir) {
    var target = ""
    if (platform == "windows") {
        target = install_dir + "\\versscript"
    } else {
        target = install_dir + "/versscript"
    }

    println("        Target: " + dim(target))

    if (!file.exists(target)) {
        file.mkdir(target)
    }

    § In a real installer, we'd copy the runtime binary + libraries:
    §   file.copy("./dist/verss.exe", target + "\\verss.exe")
    §   file.copy("./dist/versscript-runtime.dll", target + "\\versscript-runtime.dll")

    file.write(target + "/version.txt", "versscript " + VERSION)

    return true
}

func install_runtime(platform, install_dir) {
    var target = ""
    if (platform == "windows") {
        target = install_dir + "\\runtime"
    } else {
        target = install_dir + "/runtime"
    }

    println("        Target: " + dim(target))

    if (!file.exists(target)) {
        file.mkdir(target)
    }

    § The Versatile runtime bridges Verslang and Versscript:
    §   - .vtile file parser
    §   - Block dispatcher (verslang{} and versscript{} blocks)
    §   - Shared memory interface
    §   - FFI bridge

    file.write(target + "/version.txt", "versatile-runtime " + VERSION)

    return true
}

func install_vscode_extension(platform, install_dir) {
    println("        " + dim("Running: code --install-extension versatile-language-suite.vsix"))

    § In a real installer:
    §   os.exec("code --install-extension " + install_dir + "/ext/versatile-language-suite.vsix")

    return true
}

func install_documentation(platform, install_dir) {
    var target = ""
    if (platform == "windows") {
        target = install_dir + "\\docs"
    } else {
        target = install_dir + "/docs"
    }

    println("        Target: " + dim(target))

    if (!file.exists(target)) {
        file.mkdir(target)
    }

    § Write placeholder README
    var readme = "# Versatile Language Suite Documentation\n\n"
    readme = readme + "## Languages\n"
    readme = readme + "- **Verslang** (.vlang) — Low-level systems programming\n"
    readme = readme + "- **Versscript** (.vs/.verss) — Dynamic scripting language\n"
    readme = readme + "- **Versatile** (.vtile) — Combined language blocks\n\n"
    readme = readme + "## Quick Start\n"
    readme = readme + "```\nverslang hello.vlang -o hello -f pe64\n"
    readme = readme + "verss hello.vs\n"
    readme = readme + "versatile project.vtile\n```\n"

    file.write(target + "/README.md", readme)

    return true
}

func install_examples(platform, install_dir) {
    var target = ""
    if (platform == "windows") {
        target = install_dir + "\\examples"
    } else {
        target = install_dir + "/examples"
    }

    println("        Target: " + dim(target))

    if (!file.exists(target)) {
        file.mkdir(target)
    }

    § Write example files
    var hello_vlang = '§ Hello World in Verslang\n'
    hello_vlang = hello_vlang + 'external function write(fd: i32, buf: ptr<u8>, count: u64): i64\n'
    hello_vlang = hello_vlang + 'external function exit(code: i32): void\n\n'
    hello_vlang = hello_vlang + 'function _start(): void {\n'
    hello_vlang = hello_vlang + '    declare msg: array<u8, 14> = "Hello, World!\\n"\n'
    hello_vlang = hello_vlang + '    write(1, cast<ptr<u8>>(address_of(msg)), 14)\n'
    hello_vlang = hello_vlang + '    exit(0)\n'
    hello_vlang = hello_vlang + '}\n'

    file.write(target + "/hello.vlang", hello_vlang)

    var hello_vs = '§ Hello World in Versscript\n'
    hello_vs = hello_vs + 'println("Hello, World!")\n'
    hello_vs = hello_vs + '\n'
    hello_vs = hello_vs + 'var name = input("What is your name? ")\n'
    hello_vs = hello_vs + 'println("Welcome to Versscript, " + name + "!")\n'

    file.write(target + "/hello.vs", hello_vs)

    return true
}

§ --- PATH Configuration ---

func configure_path(platform, install_dir) {
    var bin_dir = get_bin_dir(platform, install_dir)
    println("  " + dim("Adding to PATH: " + bin_dir))

    if (platform == "windows") {
        § On Windows, modify user PATH via registry
        § os.exec('setx PATH "%PATH%;' + bin_dir + '"')
        println("  " + dim("  (setx PATH to include " + bin_dir + ")"))
    } else if (platform == "linux") {
        § Append to ~/.bashrc
        var bashrc = os.home() + "/.bashrc"
        var line = '\nexport PATH="$PATH:' + bin_dir + '"\n'
        println("  " + dim("  (appending to " + bashrc + ")"))
        § file.write(bashrc, file.read(bashrc) + line)
    } else if (platform == "macos") {
        § Append to ~/.zshrc
        var zshrc = os.home() + "/.zshrc"
        var line = '\nexport PATH="$PATH:' + bin_dir + '"\n'
        println("  " + dim("  (appending to " + zshrc + ")"))
        § file.write(zshrc, file.read(zshrc) + line)
    }

    return true
}

§ --- Verification ---

func verify_installation(platform, install_dir) {
    var errors = []
    var checks = [
        { name: "verslang", subdir: "verslang" },
        { name: "versscript", subdir: "versscript" },
        { name: "runtime", subdir: "runtime" }
    ]

    foreach (check in checks) {
        var dir = ""
        if (platform == "windows") {
            dir = install_dir + "\\" + check.subdir
        } else {
            dir = install_dir + "/" + check.subdir
        }

        if (file.exists(dir)) {
            println("    " + green("✓") + " " + check.name)
        } else {
            println("    " + red("✗") + " " + check.name + " — directory not found")
            errors.push(check.name)
        }
    }

    return errors.length() == 0
}

§ --- User Interaction ---

func prompt_install_mode() {
    println(bold("  Select installation mode:"))
    println("")
    println("    " + cyan("[1]") + " Full    — All components (recommended)")
    println("    " + cyan("[2]") + " Minimal — Core languages only")
    println("    " + cyan("[3]") + " Custom  — Choose components manually")
    println("")
    var choice = input("  Enter choice [1/2/3]: ")
    if (choice == "2") {
        return "minimal"
    } else if (choice == "3") {
        return "custom"
    }
    return "full"
}

func prompt_custom_components(manifest) {
    println("")
    println(bold("  Select components to install:"))
    println("")
    foreach (comp in manifest) {
        if (comp.required) {
            println("    " + green("[x]") + " " + comp.name + " " + dim("(" + comp.size + ") — required"))
        } else {
            var marker = "[ ]"
            var choice = input("    Install " + comp.name + " (" + comp.size + ")? [y/N]: ")
            if (choice == "y" || choice == "Y" || choice == "yes") {
                comp.selected = true
                println("    " + green("[x]") + " " + comp.name)
            } else {
                comp.selected = false
                println("    " + dim("[ ]") + " " + comp.name)
            }
        }
    }
    println("")
    return manifest
}

func prompt_install_dir(platform) {
    var default_dir = get_default_install_dir(platform)
    println("")
    var custom = input("  Install directory [" + default_dir + "]: ")
    if (custom == "" || custom == null) {
        return default_dir
    }
    return custom
}

func prompt_confirm(install_dir, manifest) {
    println("")
    println(bold("  Installation Summary:"))
    println("  " + dim("─────────────────────────────────────────"))
    println("  Location: " + cyan(install_dir))
    println("  Components:")
    foreach (comp in manifest) {
        if (comp.selected) {
            println("    " + green("•") + " " + comp.name + " " + dim("(" + comp.size + ")"))
        }
    }
    println("  " + dim("─────────────────────────────────────────"))
    println("")
    var confirm = input("  Proceed with installation? [Y/n]: ")
    if (confirm == "n" || confirm == "N" || confirm == "no") {
        return false
    }
    return true
}

§ --- Uninstaller ---

func uninstall(platform) {
    var install_dir = get_default_install_dir(platform)
    println("")
    println(yellow("  Uninstalling " + APP_NAME + "..."))
    println("")

    var custom = input("  Install location [" + install_dir + "]: ")
    if (custom != "" && custom != null) {
        install_dir = custom
    }

    if (!file.exists(install_dir)) {
        println(red("  Error: Directory not found: " + install_dir))
        return false
    }

    var confirm = input("  Remove " + install_dir + " and all contents? [y/N]: ")
    if (confirm != "y" && confirm != "Y") {
        println("  Uninstall cancelled.")
        return false
    }

    § Remove subdirectories
    var subdirs = ["verslang", "versscript", "runtime", "docs", "examples", "bin"]
    foreach (sub in subdirs) {
        var target_dir = ""
        if (platform == "windows") {
            target_dir = install_dir + "\\" + sub
        } else {
            target_dir = install_dir + "/" + sub
        }
        if (file.exists(target_dir)) {
            println("    Removing " + dim(target_dir))
            file.delete(target_dir)
        }
    }

    println("")
    println(green("  " + APP_NAME + " has been uninstalled."))
    return true
}

§ --- Main Installer Orchestrator ---

func main() {
    print_banner()

    § Detect platform
    var platform = detect_platform()
    println("  " + dim("Platform: " + platform))
    println("  " + dim("Architecture: " + os.arch()))
    println("  " + dim("Working directory: " + os.cwd()))
    println("")

    if (platform == "unknown") {
        println(red("  Error: Unsupported platform. Aborting."))
        os.exit(1)
    }

    § Check for --uninstall flag
    var args = process.argv
    if (args != null) {
        foreach (arg in args) {
            if (arg == "--uninstall") {
                uninstall(platform)
                os.exit(0)
            }
        }
    }

    § Step 1: Choose install mode
    var mode = "full"
    var args_mode = null
    if (args != null) {
        foreach (arg in args) {
            if (arg == "--mode") {
                § next arg should be the mode value
            }
            if (arg == "full" || arg == "minimal" || arg == "custom") {
                args_mode = arg
            }
        }
    }

    if (args_mode != null) {
        mode = args_mode
        println("  " + dim("Mode (from args): " + mode))
    } else {
        mode = prompt_install_mode()
    }

    § Step 2: Create component manifest
    var manifest = create_manifest(mode)

    § Step 3: Custom selection if needed
    if (mode == "custom") {
        manifest = prompt_custom_components(manifest)
    }

    § Step 4: Choose install directory
    var install_dir = prompt_install_dir(platform)

    § Step 5: Confirm
    if (!prompt_confirm(install_dir, manifest)) {
        println("")
        println(yellow("  Installation cancelled."))
        os.exit(0)
    }

    § Step 6: Create base directories
    println("")
    println(bold("  Installing " + APP_NAME + " v" + VERSION + "..."))
    println("  " + dim("─────────────────────────────────────────"))
    println("")

    if (!file.exists(install_dir)) {
        file.mkdir(install_dir)
    }

    var bin_dir = get_bin_dir(platform, install_dir)
    if (!file.exists(bin_dir)) {
        file.mkdir(bin_dir)
    }

    § Step 7: Install selected components
    var total_steps = 0
    foreach (comp in manifest) {
        if (comp.selected) {
            total_steps = total_steps + 1
        }
    }

    var current_step = 0
    var all_success = true

    foreach (comp in manifest) {
        if (comp.selected) {
            current_step = current_step + 1
            print_step(current_step, total_steps, "Installing " + comp.name + "...")

            var success = comp.installer(platform, install_dir)
            if (!success) {
                println("    " + red("FAILED: " + comp.name))
                all_success = false
            }

            print_progress(current_step, total_steps)
            println("")
        }
    }

    § Step 8: Configure PATH
    println("")
    print_step(current_step + 1, total_steps + 2, "Configuring PATH...")
    configure_path(platform, install_dir)

    § Step 9: Verify
    println("")
    print_step(current_step + 2, total_steps + 2, "Verifying installation...")
    println("")
    var verified = verify_installation(platform, install_dir)

    § Step 10: Done
    println("")
    if (all_success && verified) {
        var line = "============================================================"
        println(green(line))
        println(green("  " + APP_NAME + " installed successfully!"))
        println("")
        println("  Commands available after restarting your terminal:")
        println("")
        println("    " + cyan("verslang") + "  — Compile .vlang files to native x86-64 code")
        println("    " + cyan("verss") + "     — Run .vs/.verss Versscript files")
        println("    " + cyan("versatile") + " — Run .vtile combined language files")
        println("")
        println("  Install location: " + dim(install_dir))
        println(green(line))
    } else {
        println(red("  ════════════════════════════════════════════════════════"))
        println(red("  Installation completed with errors."))
        println(red("  Please check the logs above and retry."))
        println(red("  ════════════════════════════════════════════════════════"))
        os.exit(1)
    }
}

§ --- Entry Point ---

main()
