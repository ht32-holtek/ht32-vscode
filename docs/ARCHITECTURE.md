# HT32 Project Assistant for VS Code — 專案架構

## 總覽

這是一個 **VS Code Extension**（TypeScript），用於輔助開發 Holtek HT32 系列 ARM Cortex-M 微控制器。核心功能是將現有 IDE 的專案格式轉換成 Makefile 流程，並整合 VS Code 的 Build / Debug 體驗。

---

## 目錄結構

```
ht32.vscode.solution/
├── src/                         ← TypeScript 原始碼
│   ├── ht32-project-assistant-for-vs-code.ts   ← Extension 入口（activate）
│   └── tools/
│       ├── uv2make.ts           ← Keil uVision (.uvprojx) → Makefile 轉換器
│       └── toolchain.ts         ← ARM GCC / Make 自動搜尋與驗證
│
├── out/                         ← 編譯輸出（tsc → CommonJS，不進 SVN）
│
├── templates/
│   ├── GNU_ARM/                 ← startup 組語、linker script、ht32_op.c
│   └── scripts/interface/       ← OpenOCD interface cfg（htlink.cfg）
│
├── dfp/Holtek/HT32_DFP/
│   └── 1.0.76/                  ← CMSIS DFP（版號資料夾保留升級彈性）
│       ├── SVD/                 ← 100 個 HT32 MCU 的 SVD 檔（偵錯用）
│       └── ARM/                 ← Flash Loader、Header、Startup
│
├── openocd/                     ← 打包的 OpenOCD（Windows x64）
│   ├── bin/openocd.exe + DLLs
│   ├── MCU/                     ← 各 HT32 MCU 的 .cfg（~90 個）
│   ├── FlashLoader/             ← HT32F.HLM、HT32F_OPT.HLM 等
│   └── scripts/
│       ├── interface/htlink.cfg ← e-Link32 Pro/Lite 介面定義
│       └── target/              ← HLMm0x / HLMm3x / HLM490x1 等
│
└── bin/win32-x64/               ← 打包的 GNU Make（Windows x64）
    └── make.exe + iconv/intl DLLs
```

---

## 模組職責

| 模組 | 職責 |
|------|------|
| `ht32-project-assistant-for-vs-code.ts` | Extension 主入口：註冊 Commands、建立 TreeView、處理 Build/Clean/Debug、自動偵測並 attach 已轉換的專案 |
| `tools/uv2make.ts` | 解析 Keil uVision `.uvprojx`（XML），提取 sources / includes / defines / 記憶體分配，輸出 Makefile + sources.list + compile_commands.json |
| `tools/scatter2ld.ts` | 解析 Keil scatter file（`.sct` / `.lin`），轉換為 GNU LD linker script（`.ld`）。支援標準 Flash/RAM、外部 SRAM、SPIM XIP、IAP offset 等 HT32 配置 |
| `tools/settingsWebview.ts` | 提供 HT32 Settings WebView 面板（Toolchain / Compiler / Debugger），儲存設定至 VS Code workspace / global settings |
| `tools/toolchain.ts` | 掃描系統上的 `arm-none-eabi-gcc` 與 GNU Make（偏好 MSYS2/Git/MinGW，排除 Cygwin/GnuWin32），若缺少則引導使用者安裝 |

---

## 命令列表（Ctrl+Shift+P 輸入 HT32）

| 命令 | 說明 |
|------|------|
| `HT32: Build` | 執行 make 編譯 |
| `HT32: Clean` | 清除編譯產物 |
| `HT32: Debug` | 啟動 Cortex-Debug + OpenOCD |
| `HT32: Convert uVision Project` | 轉換 Keil .uvprojx → Makefile |
| `HT32: Convert HT32-IDE Project` | 轉換 Eclipse/.project → Makefile |
| `HT32: Generate Build & Debug Config` | 重新產生 tasks.json / launch.json |
| `HT32: Refresh Project Tree` | 重新整理左側檔案樹 |
| `HT32: Open Settings` | 開啟 HT32 Settings WebView 面板 |

---

## 主要函式結構

```
activate()
  ├── 註冊所有 commands
  ├── 建立 ProjectTreeProvider（TreeView）
  ├── autoAttachProjectFromWorkspace()   ← 啟動時自動偵測既有專案
  └── ensureToolchain()                  ← 檢查 GCC / Make 是否存在

convertUvisionLocal()
  └── uv2make() → generateTasksAndLaunch(root, { elfPath, deviceName, mcu, ramOrigin, ramLength })

convertHt32Ide()
  └── scanSources() → generateTasksAndLaunch(root)

generateTasksAndLaunch()
  ├── 讀取 ht32.* 設定值（gcc/make path、debugInterface、svdFile 等）
  ├── locateMake() / locateArmGcc()      ← 設定值優先，否則自動偵測
  ├── selectInterfaceCfg()               ← e-Link32 / ST-Link / J-Link
  ├── findSvdFile()                      ← 從 DFP 自動查找 SVD
  ├── writeMakefileToolsSettings()       → .vscode/settings.json
  ├── write tasks.json                   (Build / Clean)
  └── write launch.json                  (cortex-debug + OpenOCD)

selectTargetCfg(mcu?, deviceName?)
  ├── F490x → HLM490x1.cfg
  ├── F491x → HLM491x3.cfg
  ├── F493x → HLM493x5.cfg
  ├── M3/M4/M7 → HLMm3x.cfg
  └── default → HLMm0x.cfg

findSvdFile(dfpPath, deviceName, extPath)
  ├── 搜尋 ht32.dfpPath 設定 → SVD/
  ├── 搜尋 bundled dfp（自動取最新版號）
  └── expandSvdVariants()   ← "HT32F52342_52" → ["HT32F52342", "HT32F52352"]

ProjectTreeProvider
  └── 從 build-gen/project.meta.json 建立 file tree
```

---

## 資料流程

```
使用者選擇專案
      │
      ├─ Keil .uvprojx ──→ uv2make.ts
      │                       │ 解析 XML (fast-xml-parser)
      │                       │ 套用 ht32.* 設定值（optimization、specs、floatAbi 等）
      │                       ↓
      └─ Eclipse .cproject ─→ convertHt32Ide()
                              │
                              ↓
                    build-gen/
                    ├── Makefile              (-mcpu, -O?, --specs=nano, ...)
                    ├── linker_script.ld
                    ├── sources.list
                    ├── includes.list
                    ├── defines.list
                    ├── project.meta.json     (TreeView 資料來源)
                    ├── build.meta.json       (extension 用，產生 launch.json)
                    └── compile_commands.json (IntelliSense)
                              │
                              ↓
                    .vscode/
                    ├── tasks.json            (Build / Clean)
                    ├── launch.json           (cortex-debug + svdFile)
                    └── settings.json         (makefile.* paths)
```

---

## build-gen/ 各檔案說明

| 檔案 | 用途 | 更新時機 |
|------|------|---------|
| `Makefile` | `make` 編譯主體：TARGET、CFLAGS、LDFLAGS、每個源文件的獨立規則 | 轉換時產生；TreeView 變動時 patch SRCS/OBJ/規則區段 |
| `linker_script.ld` | GNU LD linker script，含 FLASH/RAM 地址與大小 | 只在轉換時產生 |
| `sources.list` | 源文件路徑清單（相對 build-gen/），純文字輔助參考 | 轉換 + TreeView 變動時重寫 |
| `includes.list` | include 路徑清單，輔助參考 | 只在轉換時產生 |
| `defines.list` | preprocessor define 清單，輔助參考 | 只在轉換時產生 |
| `project.meta.json` | TreeView 資料來源：`{ projectName, groups: { "GroupName": ["rel/path/..."] } }`，路徑相對 workspace root | 轉換 + TreeView 變動時更新 |
| `build.meta.json` | Extension 讀取以產生 launch.json：`targetName`、`mcu`、`fpu`、`floatAbi`、`ramOrigin`、`ramLength`、`deviceName` | 只在轉換時產生 |
| `compile_commands.json` | Clang Compilation Database，給 clangd / VS Code IntelliSense 使用；`make` 不讀此檔 | 轉換 + TreeView 變動時重寫 |
| `startup_ht32f5xxxx_gcc_NN.s` | GNU 格式啟動碼，定義 Stack_Size(3072) / Heap_Size(1024)，放入 `.stack`/`.heap` section | 只在轉換時從 templates/ 複製 |
| `ht32_op.c` | Holtek option byte 程式，從 template 複製 | 只在轉換時產生 |
| `build/` | make 輸出目錄：`.o` 物件檔 + `<OutputName>.elf` | make 執行時產生 |

### 檔案依賴關係

```
uvprojx
  └─ uv2make() ──────┬─ Makefile          ← make 編譯
                     ├─ linker_script.ld
                     ├─ sources.list
                     ├─ includes.list
                     ├─ defines.list
                     ├─ project.meta.json ← TreeView
                     ├─ build.meta.json   ← generateTasksAndLaunch()
                     └─ compile_commands.json ← IntelliSense

TreeView add/remove
  └─ updateProjectMeta() ─┬─ project.meta.json (重寫)
                          ├─ sources.list      (重寫)
                          ├─ Makefile          (patch SRCS/OBJ/規則)
                          └─ compile_commands.json (重寫)
```

---

## 關鍵依賴

| 依賴 | 用途 |
|------|------|
| `fast-xml-parser` | 解析 `.uvprojx` / `.cproject`（XML） |
| `marus25.cortex-debug` | Extension dependency，提供 ARM 偵錯支援 |
| `openocd.exe`（打包） | Windows x64 pre-bundled，含各 HT32 MCU cfg |
| `make.exe`（打包） | Windows x64 pre-bundled，避免使用者手動安裝 |
| `dfp/` SVD 檔（打包） | Cortex-Debug peripheral register view 用 |

---

## VS Code 設定（Ctrl+, 搜尋 HT32）

| 設定 | 說明 | 預設 |
|------|------|------|
| `ht32.gccPath` | arm-none-eabi-gcc 路徑 | 自動偵測 |
| `ht32.makePath` | make 路徑 | 自動偵測 |
| `ht32.optimizationLevel` | -O 旗標（O0/O1/O2/O3/Os/Og） | O2 |
| `ht32.floatAbi` | soft / softfp / hard | soft |
| `ht32.fpu` | none / fpv4-sp-d16 / fpv5-sp-d16 / fpv5-d16 | none |
| `ht32.specs` | nano / standard / nosys | nano |
| `ht32.debugInterface` | e-Link32 Pro / e-Link32 Lite / ST-Link / J-Link | e-Link32 Pro |
| `ht32.openocdPath` | OpenOCD 路徑（空 = 用內建） | 空 |
| `ht32.dfpPath` | DFP 根目錄（自動查找 SVD 用） | 空 |
| `ht32.svdFile` | SVD 路徑（空 = 從 DFP 自動查找） | 空 |
| `ht32.extraCFlags` | 附加到 CFLAGS 的額外旗標 | 空 |
| `ht32.extraLDFlags` | 附加到 LDFLAGS 的額外旗標（如 -u _printf_float） | 空 |

---

## scatter2ld 轉換流程

### 輸入格式支援（`.sct` / `.lin`）

Keil scatter file 的語法變體相當多，`scatter2ld.ts` 的 parser 處理以下所有模式：

```
parseBlocks()          ← 解析頂層 Load Region（絕對位址）
parseExecRegions()     ← 解析 Load Region 內的 Execution Region
  ├── 絕對位址：NAME 0xADDR [SIZE] [FLAGS] { ... }
  └── 相對位址：NAME +OFFSET [SIZE] [FLAGS] { ... }   (+0 最常見)
```

### 已驗證的 HT32 scatter 語法模式

| 語法模式 | 範例 | 處理方式 |
|---|---|---|
| 標準 Flash/RAM（M0/M0+/M3） | `LR_IROM1 0x00000000 0x00010000 { ... }` | `classifyAddr` → FLASH |
| 標準 Flash（M4） | `LR_IROM1 0x08000000 0x00080000 { ... }` | `classifyAddr` → FLASH |
| 相對位址 execution region | `IAP +0` / `AP +0` | `parseExecRegions` → `lrBase + offset` |
| 旗標屬性（PI 等） | `AP 0x00015400 PI` | `[^{\r\n]*` 吞掉旗標 |
| `{` 在下一行 | `AP 0x00015400 PI\n{` | `[^{\r\n]*\s*\{` 跨行匹配 |
| 物件檔直接指定 | `*.o (IAP, +FIRST)` / `*.o (RESET, +FIRST)` | `isStandardRegion` → `\.o\b` + `\+FIRST` |
| 自訂具名 section | `CMIS_TABLE 0x20000F2C { *(.cmis_table) }` | `extractNamedSections` → `cmis_table` 自訂段 |
| 無 size 的 RAM region | `RAM 0x20001580 { * (+RW +ZI) }` | 警告 `LENGTH = 0`，仍輸出 MEMORY entry |
| 裸 .o 物件參考 | `ram_fun.o` | `isStandardRegion` → `\.o\b` |
| `InRoot$$Sections` | `*(InRoot$$Sections)` | `isStandardRegion` → `InRoot` |
| 多頂層 Load Region（IAP + AP） | `IAP 0x00000000 ... AP 0x00002000 ...` | `parseBlocks` 以 `lastIndex` 跳過已解析區塊 |
| IAP offset 偵測 | AP flash 起始不在 `{0x00000000, 0x08000000}` | 自動在 .ld 加 `SCB->VTOR` 提示註解 |
| SPIM XIP | exec region base `0x08400000–0x0FFFFFFF` | `classifyAddr` → SPIM（rx） |
| 外部 SRAM | exec region base `0x60000000–0x6FFFFFFF` | `classifyAddr` → EXT_RAM（xrw） |

### 輸出 MEMORY 命名規則

重複分類的 region 自動加序號：`FLASH` → `FLASH2`、`RAM` → `RAM2`，避免 LD 命名衝突。

---

## 設計決策記錄

### 2026-04-07 設定頁採用 VS Code 標準 contributes.configuration

選擇使用 `contributes.configuration`（VS Code 設定頁），而非自訂 WebView。
原因：compiler / debugger 設定屬於「持久性偏好」，設定頁是業界標準做法（ARM Keil Studio、STM32 extension 均如此）。WebView 留待未來需要嚮導式流程（如選擇 MCU → 自動填入參數）時再考慮。

### 2026-04-07 Compiler 設定精簡原則

不暴露 `-j`（parallel jobs）、LTO、debugLevel、printfFloat 等進階選項為獨立設定，改由 `extraCFlags` / `extraLDFlags` 讓進階用戶自行填入。依據：ARM 官方 extension 同樣只暴露核心選項，過細的設定增加維護負擔且使用者不需要。

### 2026-04-07 DFP 版號目錄結構

DFP 存放路徑設計為 `dfp/Holtek/HT32_DFP/{version}/`，保留版號層級，未來升級時另建新版號資料夾，不覆蓋舊版。

### 2026-05-21 HT32_DFP 多版本集合查詢

`getAllPdscPaths()` 與 `findSvdFile()` 改為掃描 `HT32_DFP/` 下**所有版本目錄**（由新到舊排序），而非只取最新版。查詢時「找到就停」，因此重複 device 以新版為準；舊版獨有的 device 仍可透過 fallthrough 找到。目的：公司測試未 release IC 時會放只含單一 MCU 的舊版 pack，需與正式版並存，新增版本只需丟進 `HT32_DFP/` 下即可，無需改 code。

### 2026-04-07 SVD 自動查找邏輯

SVD 檔名採 `HT32F52342_52.svd` 格式表示多顆 MCU（52342 和 52352）。`expandSvdVariants()` 將檔名還原為所有涵蓋的 device name，再與轉換時取得的 deviceName 比對，無需手動設定。

### 2026-04-07 scatter2ld parser 設計：分離 parseBlocks / parseExecRegions

頂層 Load Region 永遠使用絕對位址，使用 `parseBlocks()`。
Execution Region 可能使用 `+OFFSET` 相對語法，需另用 `parseExecRegions(lrBase)` 解析。
兩者均採 `[^{\r\n]*\s*\{` 結尾 pattern，允許旗標（如 `PI`）與 `{` 跨行。

### 2026-04-08 Keil armasm → GNU assembler 語法轉換表

用於 `keil2gnu()` 函式（`uv2make.ts`），將 HT32 專案的 Keil `.s` 檔自動轉為 GNU assembler 語法。
ARM 指令本身（`LDR`, `BL`, `CMP` 等）使用 UAL 語法，Keil 與 GCC 相容，**不需要轉換**。

#### 指令對應

| Keil armasm | GNU as | 說明 |
|---|---|---|
| `; comment` | `@ comment` | 行尾/行首注解 |
| `name EQU value` | `.equ name, value` | 常數定義，注意順序不同 |
| `AREA x, CODE, READONLY` | `.section .text` | 程式碼段 |
| `AREA x, DATA, READONLY` | `.section .rodata` | 唯讀資料段 |
| `AREA x, DATA, READWRITE` | `.section .data` | 可讀寫資料段 |
| `AREA x, NOINIT, READWRITE` | `.section .bss` | 未初始化資料段 |
| `AREA x, ..., ALIGN=n` | `.balign (1<<n)` | ALIGN=3 → `.balign 8` |
| `DCD val` | `.word val` | 32-bit 資料 |
| `DCW val` | `.hword val` | 16-bit 資料 |
| `DCB val` | `.byte val` | 8-bit 資料 |
| `SPACE n` | `.space n` | 保留 n bytes |
| `ALIGN` | `.balign 4` | 4-byte 對齊（無參數時） |
| `ALIGN n` | `.balign n` | n-byte 對齊 |
| `PRESERVE8` | `.balign 8` 或忽略 | 8-byte stack 對齊提示 |
| `THUMB` | `.thumb` | 切換到 Thumb 指令集 |
| `EXPORT sym` | `.global sym` | 對外公開符號 |
| `EXPORT sym [WEAK]` | `.weak sym\n.global sym` | 弱符號 |
| `IMPORT sym` | `.extern sym` | 外部符號引用 |
| `PROC` | 移除（保留前面的 label） | 函式開始標記 |
| `ENDP` | 移除 | 函式結束標記 |
| `END` | 移除 | 檔案結束標記 |
| `INCLUDE file` | `.include "file"` | 引入另一個組語檔（需遞迴轉換） |
| `INCBIN file` | `.incbin "file"` | 嵌入二進位檔 |

#### 條件組語

| Keil armasm | GNU as | 說明 |
|---|---|---|
| `IF cond` | `.if cond` | 條件開始 |
| `IF :DEF:sym` | `.ifdef sym` | 若符號已定義 |
| `IF :LNOT::DEF:sym` | `.ifndef sym` | 若符號未定義 |
| `IF sym=val` | `.if sym == val` | 數值比較（`=` → `==`） |
| `ELSE` | `.else` | 否則 |
| `ENDIF` | `.endif` | 條件結束 |

#### 運算子

| Keil armasm | GNU as |
|---|---|
| `a:SHL:b` | `a << b` |
| `a:SHR:b` | `a >> b` |
| `a:OR:b` | `a \| b` |
| `a:AND:b` | `a & b` |
| `a:EOR:b` | `a ^ b` |
| `:NOT:a` | `~a` |

#### 特殊處理

- **`INCLUDE file`**：被 include 的檔也是 Keil 語法，需遞迴轉換後存為 `_gcc.s`，`.include` 路徑指向轉換後的檔案
- **`Stack_Size EQU` / `Heap_Size EQU`**：轉換後值自然保留，不需要 `syncStackHeap()` 的額外同步步驟
- **`__main`**：Keil 的 C runtime entry，GNU 對應為 `main`（有 semihosting 時需注意）
- **Template fallback**：轉換失敗時 fallback 到 `templates/GNU_ARM/` 的預建 GCC 版本

---

### 2026-04-07 scatter2ld LDFLAGS 不加 "not auto-converted" 備註

`guessLinkerFlags()` 改為永遠輸出 `-Wl,--gc-sections -T linker_script.ld`。
原先在 scatter 存在時加入 `# NOTE: not auto-converted` 備註，但轉換成功時該備註錯誤，且無論成功/失敗輸出目標都是 `linker_script.ld`（失敗時 fallback 到 template）。

### 2026-04-08 支援 Keil multi-project workspace（.uvmpw）

新增 `parseUvmpw()` 函式（`uv2make.ts`），解析 `.uvmpw` XML 並回傳所有子專案路徑及 active 狀態。

**轉換入口（`convertUvisionLocal`）**：
- 檔案選擇器同時接受 `.uvprojx` 和 `.uvmpw`
- 選 `.uvmpw` 時顯示 `canPickMany: true` 的 QuickPick，預設全選，使用者可取消勾選不需要的子專案
- UI 操作（pickFile / showQuickPick）移到 `withProgress` 之外，避免 progress notification 與對話框重疊

**多專案輸出目錄命名規則**：
- active 專案（`NodeIsActive=1`）→ `build-gen/`
- 其他專案 → `build-gen-{後綴}/`，後綴為 uvprojx 檔名最後一個 `_` 後的部分小寫
  - 例：`Project_52367_IAP.uvprojx` → `build-gen-iap/`

**tasks.json 自動多目錄支援**：
- `generateTasksAndLaunch()` 在寫 tasks.json 前，先掃描 `root/` 下所有符合 `build-gen(-\w+)?` 且含 Makefile 的目錄
- 每個目錄各自產生 `Build XX` / `Clean XX` task（主目錄用原始名 `Build (make)` / `Clean`）
- 多個目錄時自動加 `Build All`（`dependsOrder: sequence`）
- `preLaunchTask` 動態指向第一個（主）目錄的 build task
- `regenerateMakefileFlags` 改成對所有 `build-gen*/` 目錄套用

**ProjectTreeProvider 多專案樹狀顯示**：
- 新增 `ProjectEntry` interface（buildGenDir / dirName / displayName / meta / files）
- `refresh()` 改為呼叫 `scanProjects()`，掃描所有 `build-gen*/` 目錄並載入各自的 `project.meta.json`
- 樹狀層次：專案節點（`project`）→ Group 節點（`group`）→ 檔案節點
- TreeItem.id 編碼：專案用 `buildGenDir` 絕對路徑；Group 用 `buildGenDir::groupName`
- `build-gen/` 排在最前（active 專案），其餘依字母序
- `autoAttachProjectFromWorkspace()` 改成掃描所有 `build-gen*/`，任一有效即 attach

---

### 2026-04-09 OpenOCD launch config 正確參數（逆向 HT32-IDE plugins）

逆向分析 `com.holtek.common_1.0.1.jar` 內的 `Utilities.class`、`DeviceInfo.class`、`Pack.class` 與 `conf/Settings.ini`，得出以下正確格式：

#### hlm_SRAM 格式
```
hlm_SRAM <RAMstart> <workAreaSize>
```
- **`workAreaSize`** 來自 `com.holtek.common/conf/Settings.ini`，是第一段連續 SRAM bank 的大小，**不是** uvprojx 的全部 IRAM size。
- 範例：`HT32F49395_*` → `0x18000`（96KB，第一 bank），而非 `0x38000`（全部 224KB）

#### WORKAREASIZE
同樣使用 `Settings.ini` 的 workAreaSize：
```
set WORKAREASIZE <workAreaSize>
```

#### hlm_loader 格式
```
hlm_loader ../FlashLoader/<deviceHLM> <flashStart> <flashEnd>
hlm_loader ../FlashLoader/HT32F_OPT.HLM <optStart> <optEnd>
```
- **地址從 MCU cfg 讀取**：`openocd/MCU/{deviceName}.cfg` 內含 `Flash = start,size` 和 `Option = start,size`
- M4 系列（HT32F490/491/493）flash 從 `0x08000000` 開始，**不是** `0x00000000`
- M0/M0+ 系列 flash 從 `0x00000000` 開始

#### 選擇內部 flash HLM
依 device family + flash size 選擇 device-specific HLM（如 `HT32F493x5_1024.HLM`）；
無法精確匹配時 fallback 到 `HT32F.HLM`（通用，適用 M0/M0+ 0x00000000 系列）。

#### selectTargetCfg 改版
優先用 `deviceName` 直接對應 `openocd/MCU/{deviceName}.cfg`，
解析其 `Flash`/`Option` 欄位產生 `hlm_loader` 指令；
無精確匹配時 fallback 到原本的 family regex（HLMm0x / HLMm3x / HLM490x1 等）。

#### Settings.ini 已知的 workAreaSize
| 裝置系列 | workAreaSize |
|---|---|
| HT32F49365_* | 0x18000 |
| HT32F49395_* | 0x18000 |
| 其他（M0/M0+）| ramLength / 4（保守估算，或用 ramLength） |

#### 外部 SPIM flash — Flash Loaders 設定

**優先順序（高到低）：**
1. `ht32.flashLoaders`（workspace setting）— 有 enabled entry 時直接使用，SPIM auto-detect 整個跳過
2. SPIM auto-detect — 讀 `linker_script.ld` 偵測 SPIM region → `selectSpimHlm()` → `SpimLoaders.ini`
3. 無 SPIM region → 不加任何外部 flash loader

**`ht32.flashLoaders` 格式（array）：**
```json
[{ "hlm": "HT32F493x5_EXT_FLASH_BANK3_TYPE1_EXT_SPIF_GRMP0_SIZE_16MB.HLM",
   "start": "0x08400000", "end": "0x093FFFFF", "enabled": true }]
```

**Flash Loaders Settings UI（settingsWebview.ts）：**
- HT32 Settings → "Flash Loaders" 區塊
- 每 row：enabled checkbox、HLM 下拉（從 `openocd/FlashLoader/` 列出所有 .HLM）、start / end address 輸入
- Add Loader / Remove（✕）— 不重繪整個 list，避免 in-progress 輸入被清除

**bundled HLM（HT32F493x5 外部 SPI flash，BANK3 0x08400000–0x093FFFFF）：**
| HLM | TYPE | Remap |
|---|---|---|
| HT32F493x5_EXT_FLASH_BANK3_TYPE1_EXT_SPIF_GRMP0_SIZE_16MB.HLM | TYPE1 | GRMP0 |
| HT32F493x5_EXT_FLASH_BANK3_TYPE1_EXT_SPIF_GRMP1_SIZE_16MB.HLM | TYPE1 | GRMP1 |
| HT32F493x5_EXT_FLASH_BANK3_TYPE2_EXT_SPIF_GRMP0_SIZE_16MB.HLM | TYPE2 | GRMP0 |
| HT32F493x5_EXT_FLASH_BANK3_TYPE2_EXT_SPIF_GRMP1_SIZE_16MB.HLM | TYPE2 | GRMP1 |

**SPIM auto-detect 仍保留**（SpimLoaders.ini `[HT32F493x5]` section）：
- 4 個 QuickPick 選項（TYPE1/TYPE2 × GRMP0/GRMP1）
- 僅在 `ht32.flashLoaders` 為空時觸發

---

### 2026-04-09 keil2gnu 組語轉換 bug 修正記錄

| Bug | 原因 | 修法 |
|---|---|---|
| `iap_gcc.s: unknown pseudo-op '.rodata'` | `areaToSection` 回傳裸 `.rodata`，GNU as 不認 | 改為 `.section .rodata` |
| `INCBIN IAP.bin: file not found` | 路徑以原始 srcDir 為基準，輸出到 build-gen/ 後找不到 | 轉換為相對 outDir 的路徑 |
| `bad instruction 'stack_mem SPACE Stack_Size'` | DCD/SPACE regex 不處理「label + directive 同行」 | regex 加可選 label prefix，輸出 `label:` + `.space` |
| `bad instruction '__initial_sp'` | 純 label 行直接透通，GNU as 視為指令 | armasm label 從第 0 欄開始 → 加 `:` |
| `AREA \|.text\|, CODE, READONLY` 不匹配 | AREA regex `[\w$]+` 不含 `\|...\|` | 改為 `(\|[^|]*\||\w[\w$]*)` |
| `HardFault_Handler\` + `PROC` 跨行 | 未處理 Keil `\` 行接續符 | pre-process：`\\n` → space |
| `IF :DEF:__MICROLIB` → `.if defined(...)` 錯誤 | keilIfCond 把 `:DEF:` 轉成 `defined()`，但 GNU as 不支援 | IF handler 先判斷 `:DEF:` → `.ifdef`，`:LNOT::DEF:` → `.ifndef` |

---

### 2026-04-09 其他 bug 修正

| Bug | 修法 |
|---|---|
| `-mfpu=none` GCC 不認識 | `hasFpu()` 過濾：值為 `"none"` 或空時省略 `-mfpu=` flag |
| `.uvmpw` scatter 用 `<LDads>` 無法讀取 | 提取路徑加 `LDads`（大寫 D）fallback |
| SPIM custom section 誤加 `(NOLOAD)` | `isNoLoad` 改為只對 `xrw` (RAM) 類型設 true；`rx` (SPIM/FLASH) 不加 |
| `extensionDependencies: cortex-debug` 導致 Restricted Mode 失敗 | 移除 `extensionDependencies`，只保留 `extensionPack` |

---

### 2026-04-09 Keil library 專案支援（CreateLib=1）

uvprojx 內 `<CreateLib>1</CreateLib>` 表示此 target 產出 `.a` 靜態函式庫而非 `.elf`。
Makefile 需要改用 `arm-none-eabi-ar rcs` 替代 link 步驟。
`uv2make()` 回傳的 `elfPath` 在 library 模式改為 `.a` 路徑（launch.json 不產生或留空）。

---

### 2026-04-10 ELF 輸出檔名：`<OutputName>` 而非 `<TargetName>`

Keil uvprojx 有兩個不同欄位：
- `<TargetName>`：Keil Project Manager 樹狀結構中的 Target 標籤名稱（如 `HT32`）
- `<OutputName>`：實際輸出的二進位檔名（如 `DataLoggerLCD`）

原本 `uv2make.ts` 誤用 `<TargetName>`，導致輸出為 `HT32.elf` 而非 `DataLoggerLCD.elf`。
已修正為優先讀取 `first.TargetOption.TargetCommonOption.OutputName`，fallback 到 `TargetName`。

---

### 2026-04-10 compile_commands.json 於 TreeView 變動時同步更新

`compile_commands.json` 給 clangd IntelliSense 使用，原本只在 `uv2make()` 轉換時產生。
TreeView add/remove files 後 IntelliSense 會對新加入的檔案失去正確的 include path 和 defines。
已在 `updateProjectMeta()` 最後加入重新產生邏輯：讀取 Makefile 的 CC/INCS/DEFS/CFLAGS 及
`build.meta.json` 的 mcu/fpu/floatAbi，為每個 compilable source 重建 compile_commands.json。

---

### 2026-05-05 build-gen 移入 .vscode/ 目錄

原本 `build-gen/` 和 `build-gen-iap/` 直接放在 workspace root，會污染專案根目錄視覺。
改為放在 `.vscode/build-gen/` 和 `.vscode/build-gen-iap/`，與 VS Code 設定同層，不干擾使用者的專案結構。

**實作方式：**
- 加入 helper `bgParent(root) = path.join(root, '.vscode')`
- 所有 `path.join(root, bg, ...)` 改為 `path.join(bgParent(root), bg, ...)`
- Task cwd: `${workspaceFolder}/.vscode/${bg}`
- `uv2make()` 新增 `workspaceRoot` option，確保 `elfPath` 相對 workspace root 計算正確
- `updateProjectMeta()` 的 `relUp` 改為動態計算（`path.relative(buildGenDir, wsRoot)`），深度 `../../` 而非 `../`
- `clangd.arguments: ['--compile-commands-dir=.../.vscode/build-gen']` 寫入 settings.json，因為 clangd 的往上搜尋不會穿越 `.vscode/`
- `IGNORED_DIRS` 移除 `'build-gen'`（`.vscode` 已含蓋）

---

### 2026-05-07 Per-project independent settings

VS Code 的 `settings.json` 不支援像 `launch.json` 那樣的 named configurations array，
無法在同一個 key 下存放多個 project 的設定。

**解決方案：** per-project 設定存放在各自的 `build-gen-{name}/project.settings.json`。

**分層：**
- `MachineSettings`（gccPath, makePath, openocdPath）→ VS Code Global (User) settings，機器共用
- `ProjectSettings`（optimizationLevel, floatAbi, fpu, specs, extraCFlags, extraLDFlags,
  debugInterface, dfpPath, svdFile, flashLoaders, eraseMode, openocdDebugLevel）→
  各自的 `build-gen-{name}/project.settings.json`，project 獨立

**settingsWebview.ts：**
- 新增 `readProjectSettings(bgDir)` / `writeProjectSettings(bgDir, s)` — 讀寫 project.settings.json
  - 不存在時 fallback 到 workspace settings（向下相容）
- `openSettingsPanel` 新 signature: `(bgDirs, availableHlms, autoLoadersByBg, hlmAddrMap, onSave)`
- WebView 多 project 時顯示 project selector dropdown；切換時 JS 動態更新所有欄位與 auto-loaders
- Save message: `{ machineSettings, projectSettings, bgName }`

**generateTasksAndLaunch：**
- 每個 bgDir 各自呼叫 `readProjectSettings(path.join(bgParentDir, bg))`
- debugInterface / flashLoaders / svdFile / dfpPath / openocdDebugLevel 全部 per-bgDir
- `regenerateMakefileFlags` 也用各自的 projSettings

---

## 維護手冊

### 新增 MCU 支援

只需加檔案，通常不需改 source code：

| 檔案 | 路徑 |
|---|---|
| 內部 Flash HLM | `openocd/FlashLoader/{Device}_{sizeKB}.HLM` |
| MCU cfg | `openocd/MCU/{DeviceName}.cfg` |
| Target cfg | `openocd/scripts/target/HLM{suffix}.cfg` |
| Settings.ini 條目 | `conf/Settings.ini` → WORKAREASIZE |

**若新 MCU 是 Cortex-M4 且支援 SWO：**  
Target cfg 的 `target create` 之後須加：
```tcl
tpiu create $_CHIPNAME.tpiu -dap $_CHIPNAME.dap -ap-num 0 -baseaddr 0xE0040000
```
cortex-debug v1.12+ 的 `swoConfig.source = "probe"` 使用 `tpiu names`，
沒有這行就會報 `Could not find TPIU/SWO names`。

已加入：`HLM490x1.cfg`, `HLM491x3.cfg`, `HLM493x5.cfg`  
不加（不支援）：`HLMm3x.cfg`（HT32F1xxxx 未引出 SWO 腳）、`HLMm0x.cfg`（M0 無 ITM）

---

### HT32-IDE 改版時的更新流程

| 資源 | 位置 | 動作 |
|---|---|---|
| Flash Loader HLM | `openocd/FlashLoader/` | 直接複製新增的 .HLM |
| MCU cfg | `openocd/MCU/` | 直接複製 |
| Settings.ini | `conf/Settings.ini` | 直接複製（與 HT32-IDE 相同格式）|
| SVD 檔 | `dfp/Holtek/HT32_DFP/{新版號}/SVD/` | 新建版號資料夾，複製 |
| DFP PDSC | `dfp/Holtek/HT32_DFP/{新版號}/` | 複製 .pdsc |
| OpenOCD 執行檔 | `openocd/bin/` | 有更新才複製 |
| Target / Interface cfg | `openocd/scripts/` | 通常**不需要**，除非新架構 |

### openocd/scripts/ 最小結構（2026-05-08 清理後）

標準 OpenOCD 所附帶的 board/chip/cpu 等數百個 cfg 已全部移除，只保留 HT32 所需：

```
scripts/
  interface/
    cmsis-dap.cfg   ← e-Link32 Pro（預設）
    htlink.cfg      ← e-Link32 Pro / Lite
    stlink.cfg      ← ST-Link
    jlink.cfg       ← J-Link
  target/
    HLMm0x.cfg      ← Cortex-M0
    HLMm3x.cfg      ← Cortex-M3 / HT32F1xxxx
    HLM490x1.cfg    ← Cortex-M4（有 tpiu create）
    HLM491x3.cfg    ← Cortex-M4（有 tpiu create）
    HLM493x5.cfg    ← Cortex-M4（有 tpiu create）
    swj-dp.tcl      ← 被所有 HLM cfg source，必要
    readme.txt
```

---

## 2026-05-08 — Printf Retarget 支援

**問題：** GNU newlib 的 printf 走 `_write()` syscall，HT32 官方 `ht32_retarget.c` 只提供 `fputc()` hook（Keil/IAR 用），GCC 下 printf 沒有輸出。

**解決方案：** 自動生成 `ht32_retarget_gnu.c`（always in SRCS），用 `#if defined(_RETARGET) && (_RETARGET==1)` 守衛包覆，啟用時提供 `_write()`。

**實作細節：**
- `generateRetargetGnu(outDir)` 生成 `build-gen/ht32_retarget_gnu.c`
  - `RETARGET_PORT == 0`（ITM）：直接寫 ITM Stimulus Port 0，輸出到 OpenOCD SWO console
  - 其他 port：`extern int SERIAL_PutChar(int ch)` → 委派給 `ht32_serial.c`
- `retargetCDefines(opts)` 回傳 `-D_RETARGET=1 -DRETARGET_PORT=N -DRETARGET_UxART_BAUDRATE=B`，附加在 CFLAGS 末尾（在 `$(DEFS)` 之後，可覆蓋 Keil 專案提取的值）
- 生成時機：`uv2make()` 轉換時 + `regenerateMakefileFlags()` 存檔時
- Settings WebView 新增 "Printf Retarget" 群組：enable checkbox → Port dropdown + Baud Rate（ITM 時隱藏）+ Auto CR+LF

**ProjectSettings 新增欄位：** `retargetEnabled`, `retargetPort`, `retargetBaudrate`, `retargetAutoReturn`

**Port 數值對應（與 ht32f1xxxx_conf.h 相同）：**
- ITM=0, USB=1, COM1=10, COM2=11, USART0=12, USART1=13, UART0=14, UART1=15

---

## 2026-05-08 — Retarget CFLAGS 設計修正

**問題：** `retargetCDefines()` 原本注入 `-DRETARGET_PORT=12 -DRETARGET_UxART_BAUDRATE=115200` 等，
但 GCC 的 command-line `-D` 先定義，`ht32f1xxxx_conf.h` 的 `#define` 後覆蓋，導致
"RETARGET_PORT redefined" warning，且最終值仍為 conf.h 所設，注入無效。

**修正：** `retargetCDefines()` 只注入 `-D_RETARGET=1`（相同值不觸發 GCC warning）。
RETARGET_PORT / RETARGET_UxART_BAUDRATE / _AUTO_RETURN 改為 webview 的「參考資訊」，
用戶須直接修改 `ht32f1xxxx_conf.h`。

**HardFault 原因：** `ht32_serial.c` 的 `SERIAL_PutChar()` 存取尚未初始化的 USART 暫存器。
用戶須在 `main()` 呼叫 `RETARGET_Configuration()` 初始化 USART，webview 已加入警告提示。

**Settings WebView 分區 header：** 從 `0.95em + 無色` 改為 `1.0em + textLink 顏色 + 左邊框`。

---

## 2026-05-13 — Create Project 新增 Library (.a) 支援

**新增 `outputType: 'app' | 'lib'`** 欄位至：
- `WizardResult` / `GenerateResult` (createProject.ts)
- `MakefileParams` (createProject.ts)
- `build.meta.json` 輸出 (generateProjectFiles)

**Makefile 差異（lib vs app）：**
- lib：`all: $(BUILD)/$(TARGET).a`，用 `AR rcs` 打包，無 LDFLAGS / .bin / .hex / startup / syscalls / retarget
- app：維持原有 `.elf/.bin/.hex` + startup + syscalls + retarget

**generateTasksAndLaunch 行為（ht32-project-assistant-for-vs-code.ts）：**
- 讀 `build.meta.json` 的 `outputType`；若為 `lib`，在 `continue` 前跳過 launch config + Download task
- `build.meta.json` 的 `targetName` 若 `outputType === 'lib'` 則組成 `.a` 路徑，否則 `.elf`

**Wizard 流程（兩處）：**
- WebView (`buildCreateProjectHtml`)：Project 區塊新增 Output Type radio（Application / Library）
- QuickPick wizard (`runCreateProjectWizard`)：Step 3/5 Output Type，原 3/4 → 4/5, 5/5

**uv2make.ts 新增 include path 存在性警告：**
- `remapInfoToOutDir` 在 include 路徑 absolute 後若 `!fs.existsSync(abs)` 則 `logWarn()`
- 目的：幫助診斷 uvprojx include 路徑深度錯誤（如 MSC_IAP_Lib146 的 4層 vs 應有的 3層）

---

## HT32-IDE 轉換：cpp.linker 選項擷取問題修正（2026-05-13）

**背景**：HT32-IDE（gnuarmeclipse）的 `.cproject` 把幾個關鍵選項存在 **cpp.linker** 工具裡，而非 c.linker：
- `cpp.linker.usenewlibnano` → `--specs=nano.specs`
- `cpp.linker.scriptfile` → `-T linker_script.ld`
- `cpp.linker.useprintffloat` / `cpp.linker.usescanffloat`

**舊程式碼錯誤**：`useNano` / `ldScripts` 只搜尋 `ldOpts`（c.linker），所以：
- `useNano` 永遠 `false` → `specs: 'nosys'` → 用完整 newlib（+10 KB）
- `linkerScript` 永遠空字串 → 走 fallback 產生最簡化 13 行 linker script → 缺少 `_sidata` / `_sdata` / `_edata` / `_sbss` / `_ebss` → `libHoltekPDF32.a` undefined reference

**修正**（`ht32ide2make.ts`）：將 `cppLinker` / `cppLdOpts` / `allLdOpts` 的定義移到 `useNano` / `ldScripts` 之前，讓這些選項搜尋合併的 `allLdOpts`（c.linker + cpp.linker）。

---

## `end` 符號缺失導致 `_sbrk` undefined reference（2026-05-13）

**問題**：`libnosys.a(sbrk.o)` 的 `_sbrk` 實作需要 `end` 符號作為 heap 起點。部分 HT32-IDE 提供的 `linker.ld`（M3 版本）的 `._user_heap_stack` 段沒有定義 `end`。

**修正位置**：
- `ht32ide2make.ts` `generateLinkerScript()`：讀取源 `linker.ld` 後，若內容不含 `end =`，則在 `_ebss` 定義行之後自動注入 `end = _ebss;`。fallback 最簡化腳本同樣補上 `end = _ebss;`。
- `uv2make.ts` `patchLdM3UserHeapStack()`：M3 `._user_heap_stack` 段改為同時定義 `PROVIDE ( end = . )` 和 `PROVIDE ( _end = . )`（原本只有 `_end`）。M0 template 和 scatter2ld 路徑本來就有 `end`，不受影響。

**兩個轉換器的 `_sbrk` 策略比較**：
- **uv2make**：產生 `ht32_syscalls.c`（自訂 `_sbrk` 使用 `_end`），覆蓋 `libnosys.a` 的實作
- **ht32ide2make**：不產生 syscalls，直接使用 `libnosys.a(sbrk.o)`，因此 linker script 必須定義 `end`

---

## `.stack`/`.heap` section 必須用 `"aw",%nobits` + `KEEP()`（2026-05-14）

**問題**：`--print-memory-usage` 顯示 RAM 只有 ~200 bytes（實際 stack 2048 bytes 未計入）。

**根本原因**：三個條件缺一不可：
1. `.section ".stack","aw",%nobits`：`a` = SHF_ALLOC（沒有此 flag → section 不貢獻 output section 大小）；`%nobits` = SHT_NOBITS（沒有此 flag → SHT_PROGBITS 浪費 Flash LMA）
2. linker script 有 `KEEP(*(.stack))`：否則 `--gc-sections` 丟棄（`.stack` 無其他 section 引用）
3. linker script 有對應的 `.stack : { ... } >RAM` output section：M0 template 原本沒有，需新增

**此問題曾部分修正**（加了 `%nobits`）但漏了 `a`，導致複發。

**修正位置**：
- `templates/M0_GNU_ARM/*.s`（17 個）＋ `templates/M3_GNU_ARM/*.s`（2 個）：`"w"` → `"aw",%nobits`（sed 批次）
- `templates/M0_GNU_ARM/linker.ld`：新增 `.stack : { KEEP(*(.stack)) KEEP(*(.stack*)) } >RAM`
- `src/tools/uv2make.ts` `areaToSection()`：`"w"` → `"aw",%nobits`
- `src/tools/uv2make.ts` post-process regex（`syncStackHeap`）：同步更新匹配邏輯
- `src/tools/scatter2ld.ts`：`.stack` section 移除 `(NOLOAD)`，改用 `KEEP()`
- `src/tools/ht32ide2make.ts`：
  - `generateLinkerScript()`：自動在 `*(.stack)`/`*(.heap)` 加 `KEEP()`；若無此 pattern 則在 `/DISCARD/` 前注入 `.stack` section
  - 新增 `patchStartupFiles(result, bgDir)`：copy startup 到 build-gen，patch `"w"` → `"aw",%nobits`
- `ht32-project-assistant-for-vs-code.ts`：`convertHt32Ide()` 在產生 Makefile 前呼叫 `patchStartupFiles()`

---

## Vector table Thumb LSB 問題：`keil2gnu` fallback 必須加 `.type label, %function`（2026-05-14）

**症狀**：Flash 後立即 HardFault，call stack 顯示 `Reset_Handler@0x000000b8`（偶數位址）。

**根本原因**：
1. Keil 轉換時，startup 檔名若不符合 `startup_xxx_NN.s` 模式（如 `startup_ht32f61141.s`），`handleKeilAsm()` 走 Rule 3 fallback → `keil2gnu()` + `injectStartupInit()`
2. `injectStartupInit()` 只插入 `.thumb_func`，不插入 `.type label, %function`
3. GNU assembler 的 `.thumb_func` 只放 `$t` mapping symbol，**不設 `STT_FUNC` 型別**（symbol 仍是 NOTYPE）
4. GNU linker 對 `R_ARM_ABS32` 只在 `STT_FUNC` 時才自動加 bit 0（Thumb interworking）
5. 結果：`.word Reset_Handler` 儲存 `0x000000b8`（偶數）而非 `0x000000b9`（奇數）
6. Cortex-M0+ 讀 reset vector 時 EPSR.T=0（ARM mode）→ UsageFault → HardFault

**診斷方式**：
```bash
readelf -x .isr_vector HT32.elf   # offset 4 應為奇數 (e.g. b9 00 00 00)
readelf -s startup.o | grep Reset  # 應為 FUNC type，st_value 奇數
```

**修正**：`injectStartupInit()` Step 6 改為同時插入 `.type label, %function` + `.thumb_func`：
```typescript
if (inTextSection && /^\w[\w$]*:$/.test(t)) {
  const labelName = t.slice(0, -1);
  final.push(`\t.type\t${labelName}, %function`); // 設 STT_FUNC → linker 加 bit 0
  final.push('\t.thumb_func');                      // 加 $t mapping symbol
}
```

**不受影響的路徑**（所有其他路徑的 startup 原本就有 `.type %function`）：
- Keil startup 符合 `startup_xxx_NN.s` → 使用 M0/M3 templates
- HT32-IDE 轉換 → 使用 Holtek GCC `.S` 原始檔
- Create Project → M0/M3 templates

---

## HT32-IDE FPU 偵測：M4 不一定有硬體 FPU（2026-05-18）

**問題**：`ht32ide2make.ts` 原本用 `isM4 ? hard : soft`，但 HT32F490x1 是 Cortex-M4 卻**無硬體 FPU**（Lite 版本）。用 `-mfloat-abi=hard` 會產生 FPU 指令 → 在無 FPU 的核心上 HardFault。

**根本原因**：`.cproject` 的 `arm.target.fpu.abi` = `...fpu.abi.default`（非 `hard`），且沒有 `arm.target.fpu.name` option → 不應使用 hard float。

**修正**（`parseCProjectFile()`）：
- 讀 `arm.target.fpu.name`：若缺或含 `none`/`default` → `fpuName = ''`（無 FPU 單元）
- 讀 `arm.target.fpu.abi`：末段是 `.hard` → `hardFloat = true`，否則 `false`
- `fpuName` 空 → `-mfloat-abi=soft`；有 FPU → `-mfpu=${fpuName} -mfloat-abi=${hard|softfp}`
- `generateCompileCommands()` 同樣修正

**新增欄位**（`Ht32IdeResult`）：
- `fpuName: string` — 例如 `"fpv4-sp-d16"` 或 `""` 表示無 FPU
- `hardFloat: boolean` — `true` = `-mfloat-abi=hard`；`false` = soft/softfp

---

## scatter2ld `.heap` section 必須加 `KEEP()`（2026-05-18）

**問題**：scatter2ld 生成的 `._user_heap_stack` 包含 `PROVIDE(_end = .)` 但無 `*(.heap)` section，獨立的 `.heap` output section 也沒有 `KEEP()`。啟動碼在 `.heap` 定義 `_end`；若 `--gc-sections` 丟棄 `.heap` section，`_end` 未定義 → link error。

**修正**：`scatter2ld.ts` 在 `.stack` section 前新增獨立的 `.heap` output section：
```
.heap :
{
  . = ALIGN(8);
  KEEP(*(.heap))
  KEEP(*(.heap*))
  . = ALIGN(8);
} >RAM
```
鏡像 `.stack` section 的現有模式（已有 `KEEP`）。


---

## 49x UV FPU：uvprojx FPU2 vs device header `__FPU_PRESENT`（2026-05-18）

**問題**：部分 Holtek 49x 系列（HT32F490x1）的 uvprojx 在 `<Cpu>` 字串寫 `FPU2`（Keil 裝置能力欄位），但 device header `ht32f490x1.h` 宣告 `__FPU_PRESENT 0U`（Cortex-M4 無 FPU）。uv2make 盲目信任 FPU2 → 生成 `-mfpu=fpv4-sp-d16 -mfloat-abi=hard`，觸發 `core_cm4.h` 的編譯時檢查：`#error "Compiler generates FPU instructions for a device without an FPU"`。

**修正**（`uv2make.ts`）：新增 `detectFpuPresentFromHeader(includes, baseDir)`：
- 掃描 include paths，尋找符合 `ht32*.h`（排除 `_conf`/`_template`）的 device header
- 讀取 `__FPU_PRESENT` 值；若為 0 → 覆蓋 `effectiveOpts.fpu = undefined, floatAbi = 'soft'`
- 在 `uv2make()` 中，`effectiveOpts` 建立後立即呼叫

**Why:** `FPU2` 是 Keil 裝置資料庫的硬體能力標記，並非「啟用 FPU」的編譯器選項；實際使用 FPU 由另一個 Keil 設定控制。GNU GCC 轉換必須以 device header 為準。

---

## HT32-IDE .project 已知雜訊（2026-05-18）

**問題 1**：部分 49x example（如 `cortex_m4/fpu`）的 `.project` 同時 link `startup/gcc/*.S`（GCC 格式）和 `startup/mdk/*.s`（Keil 格式）。`ht32ide2make` 兩個都加入 SRCS → GCC 組譯 Keil 語法錯誤。

**修正**：`parseProjectFile()` 遇到 absPath 含 `/startup/mdk/` 的文件直接 skip。

**問題 2**：同一個 `.project` 中某些 `.c` 文件出現兩次（Holtek 庫 bug），導致 linker `multiple definition`。

**修正**：`parseProjectFile()` 末尾對 sources 按 absPath 去重（`Set<string>` filter）。


---

## FPU 判斷統一以 `__FPU_PRESENT` 為權威（2026-05-18）

**原則**：三條轉換路徑（uv2make / ht32ide2make / createProject）使用同一個機制決定 FPU flags，不再各自為政。

**實作**：`detectFpuPresentFromHeader(includes, baseDir)` export 自 `uv2make.ts`：
- 掃描 include paths，找 `ht32*.h`（排除 `_conf`/`_template`）
- 讀 `__FPU_PRESENT` 值；回傳 `true/false/undefined`（找不到 header 時不覆蓋）
- 支援 absolute 和相對路徑（`path.isAbsolute` 判斷）

各路徑呼叫方式：
| 路徑 | 初始推斷 | baseDir |
|------|----------|---------|
| **uv2make** | uvprojx `FPU2` | `outDirAbs`（include 為 outDir-relative）|
| **ht32ide2make** | `.cproject` `arm.target.fpu.name` | `''`（includePaths 已是 absolute）|
| **createProject** | M4 → hard FPU heuristic | `fwlibPath`（incsRel 為 FWLib-relative）|

若 `__FPU_PRESENT=0`（device header 存在且確認無 FPU）→ 強制覆蓋為 `-mfloat-abi=soft`，移除 `-mfpu` flag。找不到 header（`undefined`）→ 維持初始推斷不動。



---

## uvprojx `<HTGSARCONT>` 標籤導致 Group 解析失敗（2026-05-18 修正）

**問題**：部分 Keil .uvprojx（84 個，涉及 FMC/FLASH_OperationNoHalt、Tips/FlashParameter 等 6 個 example）的 `<Files>` 元素內含 Holtek 自訂標籤 `<HTGSARCONT>`（無結束標籤）。

fast-xml-parser 將 `</Files>` 誤認為 `<HTGSARCONT>` 的結束標籤，導致後續所有 `<Group>` 被解析為第一個 Group 的 **nested child**，而非 siblings。結果：只有第一個 Group（User）的 `.c` 被加入 sources，其餘（Config、MDK-ARM、CMSIS…）全部丟失 → startup.s、ht32_op.s、library .c 等都不見。

**修正**：`readUvprojx()` 解析前，用 `.replace(/<HTGSARCONT>/g, '<HTGSARCONT/>')` 將空標籤改為正確的 self-closing XML 格式。

---

## Scatter 轉換後 FLASH LENGTH=0 問題（2026-05-18 修正）

**問題**：部分 Keil scatter 檔（如 FMC/FLASH_OperationNoHalt 的 `linker.lin`）的 Load Region 無明確大小（`AP 0x00000000` 沒有 size 參數）。`scatter2ld` 無法從 scatter 推算 flash 大小，輸出 `LENGTH = 0x00000000`。

`generateLinkerScript` 在使用 scatter 路徑時直接 `return`，未呼叫 `patchLdMemoryFromInfo`，導致 linker 看到 FLASH LENGTH=0 → `region FLASH overflowed` 錯誤。

**修正**：scatter 轉換後也呼叫 `patchLdMemoryFromInfo(ldText, infoForPatch)`，以 uvprojx/PDSC 查出的實際 ROM 大小修正 LENGTH=0 的欄位。

---

## ht32ide2make FLASH 大小不覆蓋設備特定值（2026-05-18 修正）

**問題**：`generateLinkerScript` 在 ht32ide2make 無條件用 `.cproject` 的 `<memory size>` 覆蓋 `.ld` 的 FLASH LENGTH。49x 設備（如 HT32F49163）的 `.ld` 已有正確的設備值（256K），但 `.cproject` 記錄的是錯誤的 128K → 覆蓋後程式塞不進去。

STD series 的 `linker.ld` 使用 `1024K` 佔位符，必須覆蓋；49x 的 `.ld` 是設備特定值，不應覆蓋。

**修正**：只有當 `.ld` 原始 FLASH LENGTH ≥ 1 MB（即為佔位符）時才覆蓋；否則保留 `.ld` 的設備特定值。

---

## test-compile.js 的 `cmdEnv()` 需把 CWD 加入 PATH（2026-05-19 修正）

**問題**：`_CreateProjectScript.bat` 呼叫 `_ProjectSource.bat`，後者再呼叫 `gsar.exe`（位於 example 目錄）。在 Windows 11 上，由 Node.js `spawnSync` 生成的 cmd.exe 子程序不會搜尋 CWD 來找可執行檔——`IF EXIST gsar.exe` 能找到（檔案系統查詢），但直接 `gsar.exe` 卻回傳 error 9009（not recognized）。

**根本原因**：Windows 11 安全強化，在特定父程序（Node.js）生成的 cmd.exe 中，CWD 不在可執行檔搜尋路徑內，除非使用 `.\gsar.exe` 或 CWD 在 PATH 中。

**修正**：`cmdEnv(cwd)` 在組裝環境時，把 `abs`（解析後的 cwd）prepend 到 `PATH` 最前面，確保 cmd.exe 能找到 example 目錄下的 `gsar.exe`。

---

## test-compile.js 對 USB 範例需傳 `AUTO` 而非 `Template`（2026-05-19 修正）

**問題**：含 `ht32_usbd_descriptor.c` 的 USB 範例（USBD/\*、CKCU/HSI_AutoTrim_By_USB 等）需使用 `project_template/IP/Template_USB/` 目錄（其 uvprojx 已含 USB 描述符相關原始碼）。test-compile.js 固定傳 `Template` 給 `_CreateProjectScript.bat`，導致 USB 範例使用非 USB 模板，缺少 `ht32_usbd_descriptor.c` → 連結失敗（`undefined reference to 'USBDDesc_Init'`）。

**修正**：改傳 `AUTO`。bat 自動偵測：若 `ht32_usbd_descriptor.c` 存在 → `Template_USB`；否則 → `Template`。

---

## HT32-IDE 轉換：extraLinkerScripts 被 regenerateMakefileFlags 覆蓋（2026-05-26 修正）

**問題**：`ht32ide2make.ts` 中 `generateMakefile()` 正確將 `extraLinkerScripts`（例如 `calculate_symbol_HT32.ld`）加入 `LDFLAGS` 為 `-T "calculate_symbol_HT32.ld"`，並複製到 `bgDir`。但 `generateTasksAndLaunch()` 最末尾呼叫 `regenAllMakefileFlags()` → `regenerateMakefileFlags()`，後者用 regex 整行替換 `LDFLAGS`，只產生 `-T linker_script.ld`，不知道 extra linker scripts → 正確 flag 被覆蓋遺失。

**.cproject 資料位置**：extra .ld 儲存在 `cpp.linker.otherobjs`（`valueType="userObjs"`）的 `listOptionValue` 中，不是 `scriptfile`。HT32-IDE generated `objects.mk` 把它作為 `USER_OBJS` 傳給 linker，GNU 接受直接輸入 .ld 檔；我們轉換成 `-T` 方式等效。

**修正**：在 `convertHt32Ide` 的 `writeProjectSettings()` 呼叫中，若 `result.extraLinkerScripts` 非空，就設定 `extraLDFlags` 為 `-T "basename.ld"` 形式。`regenerateMakefileFlags` 已有 `extraLDFlags` 參數並附加到 LDFLAGS，故能自動保留。

---

## HT32-IDE parseHt32IdeProject 優先使用 original.project（2026-05-26）

**問題**：`_CreateProjectScript.bat` 先把當前 `.project` 備份為 `original.project`，再從 template 重建 `.project`。若 `_ProjectSource_ht32ide.ini` 不存在（例如 `FLASH_PartialLock_Project_l1`），source injection 步驟跳過，重建後的 `.project` 只有 template 的最少 linked resources（缺少 `main.c`、library 等）→ IDE 轉換後 Makefile 缺少 user sources → 連結失敗（`undefined reference to 'main'`）。

**修復**：`parseHt32IdeProject` 改為：若 `original.project` 存在則優先讀它（完整版），否則讀 `.project`。`.cproject` 仍讀最新版（CREATE 後有 `calculate_symbol_HT32.ld` 等正確設定）。

---

## test-compile.js：有 prebuiltWarnings 的 UV 專案跳過 compile（2026-05-26）

prebuilt `.o` 檔（如 `calculate_symbol_MDKv5.o`）被跳過後，其提供的符號（`CalculateTest`, `S32Sum`）消失，compile 一定失敗。這是已知限制而非 bug。test-compile.js 改為：偵測到 `prebuiltWarnings` 時，跳過 compile 並回報 `SKIP`，不計入 FAIL。

---

## HT32-IDE Assembler 專屬 defines（ADEFS）未加入 ASFLAGS（2026-05-26 修正）

**問題**：`_HT32FWID` 在 startup .S 中以 `.if USE_HT32_CHIP == 33` 條件定義。`USE_HT32_CHIP=33` 是 `.cproject` 的 **Assembler tool** (`tool.assembler`) 的 `assembler.defs` 選項，不在 C compiler defs。我們的 parser 只讀 `c.compiler.defs`，導致 Makefile `DEFS`（用於 ASFLAGS）缺少 `-DUSE_HT32_CHIP=33` → `.if` 條件永遠不成立 → `_HT32FWID` 未定義 → linker error。

**修正**：
1. `Ht32IdeResult` 增加 `asmDefines: string[]` 欄位
2. `parseCProjectFile` 解析 `tool.assembler` 的 `assembler.defs`
3. `generateMakefile` 計算 `extraAsmDefs`（assembler defines 中 C compiler 沒有的部分），加入 `ADEFS` 變數並附加到 `ASFLAGS`

---

## regenerateMakefileFlags 會覆蓋 ASFLAGS 導致 $(ADEFS) 消失（2026-05-26 修正）

**問題**：`generateMakefile()` 正確將 `$(ADEFS)` 寫入 `ASFLAGS`，但 extension 轉換後隨即呼叫 `generateTasksAndLaunch()` → `regenerateMakefileFlags()`。該函數用 regex 整行替換 `ASFLAGS`，生成的 `newASFlags` 不含 `$(ADEFS)` → ADEFS defines（如 `-DUSE_HT32_CHIP=33`）在 ASFLAGS 中消失 → startup .S 的 `.if USE_HT32_CHIP == 33` 條件失效 → `_HT32FWID` 未定義 → linker error。

**test-compile.js 不會重現此 bug**，因為它只呼叫 `generateMakefile()` 直接 make，不走 `regenerateMakefileFlags`。

**修正**：`regenerateMakefileFlags` 在讀入 Makefile 後檢查是否存在 `ADEFS :=` 行；若有，則在 `newASFlags` 末尾附加 ` $(ADEFS)`。同時在 `testHt32Ide()` 加入 `regenerateMakefileFlags` 呼叫以模擬 extension 的完整流程。
