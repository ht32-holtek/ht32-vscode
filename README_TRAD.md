[English](http://mcutest.holtek.com.tw/ht32-vscode/) | [中文使用手冊](#holtek-ht32-vs-code-extension)

# Holtek HT32 VS Code Extension

Holtek HT32 系列 Cortex-M 微控制器（M0+/M3/M4）專用 VS Code 擴充功能。支援匯入 Keil uVision 與 HT32-IDE 專案，或從零建立新專案，並透過內建 OpenOCD 與 e-Link32 探針實現一鍵編譯、燒錄與除錯。

---

<br>

## 功能特色

| 功能 | 說明 |
|------|------|
| **建立新專案** | 精靈式專案產生器，支援 HT32 FWLib（標準系列與 49x 系列） |
| **匯入 uVision** | 匯入 Keil `.uvprojx` / `.uvmpw` 專案，自動產生 Makefile、連結腳本、clangd 設定 |
| **匯入 HT32-IDE** | 匯入一個或多個 Eclipse CDT `.project`/`.cproject` 專案資料夾（支援多選） |
| **編譯 / 清除** | 一鍵或工具列按鈕；支援複合式 Post-Build 任務 |
| **燒錄** | 透過內建 OpenOCD + e-Link32 Pro/Lite 燒錄韌體 |
| **除錯** | Cortex-Debug + 內建 OpenOCD；支援 Flash & Debug 或 Attach 模式 |
| **專案設定** | 提供編譯器旗標、除錯介面、Post-Build 指令的 WebView 設定面板 |
| **專案檔案樹** | 原始碼群組檢視，支援新增/移除檔案與群組 |
| **設定精靈** | HT32 設定檔視覺化編輯器（`conf.h`、`usbdconf.h`、`startup.s`），相容 Keil 精靈語法 |
| **clangd / IntelliSense** | 自動產生 `.clangd` 與合併後的 `compile_commands.json` |

---

<br>

## 安裝需求

| 項目 | 說明 |
|------|------|
| 作業系統 | Windows x64 |
| 除錯器 | Holtek e-Link32 Pro / Lite；支援 J-Link、ST-Link |
| FWLib | 需要；支援 HT32F1xxxx / HT32F4xxxx / HT32F5xxxx / HT32F490x1 / HT32F491x3 / HT32F493x5 |

> **OpenOCD**：已內建<br>
> **GCC 工具鏈**：擴充功能啟動時自動偵測；找不到時透過 winget 自動安裝<br>
> **相依擴充功能**：安裝時自動一併安裝 **Cortex-Debug**（除錯介面）與 **Holtek HT32 Configuration Wizard**（[設定精靈](https://marketplace.visualstudio.com/items?itemName=holtek.ht32-config-vscode)）

---

<br>

## 安裝擴充功能

**方法一：從 .vsix 安裝**

1. VS Code → 擴充功能 → `...` → **Install from VSIX...**
2. 選取 `ht32-vscode-x.x.x.vsix`

> **注意：** VS Code 會自動從 Marketplace 尋找並安裝擴充功能的相依套件。
> 若相依套件尚未發布至 Marketplace，安裝將會失敗。

<table><tr>
<td><img src="https://raw.githubusercontent.com/ht32-holtek/ht32-vscode/main/media/1.jpg" width="350" style="border:1px solid #ccc; border-radius:4px; padding:3px;"></td>
<td><img src="https://raw.githubusercontent.com/ht32-holtek/ht32-vscode/main/media/2.jpg" width="350" style="border:1px solid #ccc; border-radius:4px; padding:3px;"></td>
</tr></table>

---

<br>

**方法二：從 Marketplace 安裝**

1. 擴充功能搜尋欄輸入 `Holtek HT32 VS Code Extension`（或直接搜尋 `holtek` / `ht32` 即可找到）
2. 點 **Install**

<img src="https://raw.githubusercontent.com/ht32-holtek/ht32-vscode/main/media/3.jpg" width="300" style="border:1px solid #ccc; border-radius:4px; padding:3px;">

---

<br>

## 介面介紹

安裝後，左側 Activity Bar 出現 **HT32 圖示**，點擊展開 HT32 面板。

**專案未開啟時**顯示 **Create / Open / Convert** 按鈕；若有歷史記錄，下方會列出 **Recent Projects**，點擊即可直接開啟。

<img src="https://raw.githubusercontent.com/ht32-holtek/ht32-vscode/main/media/4.jpg" width="300" style="border:1px solid #ccc; border-radius:4px; padding:3px;">

---

<br>

**工具列按鈕（專案載入後顯示）：**

| 按鈕 | 功能 |
|------|------|
| Build | 編譯（執行 make） |
| Debug | 透過 OpenOCD 啟動 Cortex-Debug 除錯（Flash & Debug 或 Attach 模式） |
| Clean | 刪除 `build/` 輸出目錄 |
| Download | 燒錄韌體（不啟動除錯） |
| Settings | 開啟 HT32 Settings WebView |
| Generate Config | 重新產生 `tasks.json` 與 `launch.json` |

**`···`（更多動作）** 選單另外包含：

| 項目 | 功能 |
|------|------|
| Create Project | 開啟建立專案精靈（可在專案已開啟時使用） |
| Open Project | 開啟 `.ht32vs` 專案檔 |
| Close Project | 關閉目前載入的專案 |

---

<br>

**專案檔案樹**顯示原始碼群組結構，與 Keil uVision 的群組概念相同。

<img src="https://raw.githubusercontent.com/ht32-holtek/ht32-vscode/main/media/5.jpg" width="300" style="border:1px solid #ccc; border-radius:4px; padding:3px;"><br>

右鍵選單：

| 對象 | 操作 |
|------|------|
| 樹狀根節點（`.ht32ws`） | Rename Project File（重新命名）、Add Project（新增子專案） |
| 子專案節點 | Add Group（新增群組）、Remove Project from Workspace（從 workspace 移除） |
| 群組 | Add Files to Group（新增檔案）、Remove Group（移除群組） |
| 檔案 | Remove from Group（從群組移除）、Delete File（從磁碟刪除） |

<img src="https://raw.githubusercontent.com/ht32-holtek/ht32-vscode/main/media/12.jpg" width="300" style="border:1px solid #ccc; border-radius:4px; padding:3px;"><br>
---

<br>

## 專案檔案（.ht32ws）

每個 HT32 專案都會對應一個 **`.ht32ws` 專案檔**（儲存在 `HT32_VSCode/` 內）。此檔案記錄此專案包含哪些子專案目錄，在轉換或建立專案後自動產生。

### 開啟專案

| 方式 | 說明 |
|------|------|
| **雙擊 `.ht32ws`** | 在檔案總管雙擊 `.ht32ws` 檔案，直接開啟專案 |
| **Open Project**（`HT32: Open Project`） | 透過指令瀏覽並開啟 `.ht32ws` 專案檔 |
| **Recent Projects** | 點擊最近開啟清單中的任一項目（專案未開啟時顯示） |

### 管理子專案

一個 `.ht32ws` 可包含多個子專案目錄（例如 `Project_IAP` 與 `Project_AP`），無需重新轉換即可隨時新增或移除。

| 操作 | 方式 |
|------|------|
| **新增子專案** | 在根節點按右鍵 → **Add Project to Workspace**，從同一資料夾中選擇可用目錄 |
| **移除子專案** | 在專案節點按右鍵 → **Remove Project from Workspace**，從清單中移除（磁碟上的檔案不會刪除）。僅剩一個子專案時無法執行。 |

### 重新命名專案

在 Project Tree 的根節點按右鍵 → **Rename Project File**，即可同時更名 `.ht32ws` 檔案並自動更新 Recent Projects 清單。

> 僅在 `.ht32ws` 已啟用時才顯示（Open Folder 模式下不提供此操作）。

---

<br>

## 建立新專案

> 需要先準備好 HT32 FWLib（從 Holtek 官網下載）

1. HT32 面板 → **Create Project**
2. 依精靈步驟選擇：

| 步驟 | 內容 |
|------|------|
| ① | 選擇 **HT32 FWLib 根目錄** |
| ② | 選擇 **MCU 型號** |
| ③ | 選擇輸出類型：**Application** 或 **Library** |
| ④ | 輸入**專案名稱**和儲存位置 |

<img src="https://raw.githubusercontent.com/ht32-holtek/ht32-vscode/main/media/6.jpg" width="450" style="border:1px solid #ccc; border-radius:4px; padding:3px;">

---

<br>

## 建立新專案 — 產生的檔案結構

```
MyProject/                 ← 使用者命名的專案資料夾
├── .clangd                ← 開啟專案時自動產生（clangd 設定）
└── HT32_VSCode/           ← VS Code workspace root
    ├── .vscode/
    │   ├── tasks.json
    │   ├── launch.json
    │   └── compile_commands.json
    ├── <projectName>.ht32ws
    └── <projectName>/     ← 名稱來自精靈中輸入的專案名稱
        ├── Makefile
        ├── sources.list
        ├── *.json
        ├── src/           ← 使用者原始碼
        │   ├── main.c
        │   ├── ht32fxxxx_it.c
        │   ├── system_ht32fxxxx.c
        │   ├── ht32fxxxx_conf.h
        │   └── ht32_op.c
        └── GNU_ARM/       ← 自動產生的 GCC 支援檔案
            ├── startup_ht32fxxxx_gcc_xx.s
            ├── linker.ld
            ├── syscalls.c
            └── ht32_stack_analysis.c
```

若要在同一個工作區資料夾中新增第二個專案，請在相同的 `MyProject/` 資料夾再次執行 **Create Project**，並在詢問時選擇 **Yes** 合併至現有的 `.ht32ws` 專案檔。每個專案完全獨立，放在各自的 `<projectName>/` 資料夾內。

---

<br>

## 匯入 Keil uVision 專案

1. HT32 面板 → **Convert uVision Project**
2. 選取 `.uvprojx`（單一專案）或 `.uvmpw`（多專案）

`.uvmpw` 會將所有子專案**一次全部轉換**，每個子專案各產生一個獨立的目錄，目錄名稱即為 `.uvprojx` 的檔名。

**自動產生：**

- `Makefile`（MCU 型號、編譯旗標、來源檔案）
- Linker script（放在共用 `GNU_ARM/`）：有 Keil scatter 時轉換為 `linker_script.ld`；無 scatter 時直接取自 FWLib（標準系列為 `linker.ld`，49x 系列為 `<chip>_FLASH.ld`）
- `startup_xxx_gcc.s`（從 Keil startup 轉換，放在共用 `GNU_ARM/`）
- `compile_commands.json` / `tasks.json` / `launch.json`

**單一 `.uvprojx`** — 共用檔輸出至 `HT32_VSCode/GNU_ARM/`；Makefile 與中繼資料輸出至 `HT32_VSCode/Project/`

**`.uvmpw` 多專案** — 每個子專案各一個目錄，目錄名稱取自 `.uvprojx` 檔名（例如 `Project_IAP.uvprojx` + `Project_AP.uvprojx`）：

```
<ProjectRoot>/
├── MDK_ARMv5/             ← 原始 Keil 專案
└── HT32_VSCode/           ← VS Code workspace root
    ├── .vscode/
    │   ├── tasks.json
    │   ├── launch.json
    │   └── compile_commands.json
    ├── GNU_ARM/           ← 共用：startup .s、linker script、ht32_op.c、syscalls.c、ht32_stack_analysis.c
    ├── Project_IAP/       ← 取自 uvprojx 檔名
    │   ├── Makefile
    │   └── *.json
    └── Project_AP/
        ├── Makefile
        └── *.json
```

> **IAP 路徑說明 — 將另一個子專案的 binary 嵌入原始碼：**
> GCC 組合語言或 C 的 `asm(".incbin ...")` 中，`.incbin` 的路徑以 **make 工作目錄**（`HT32_VSCode/Project_xxx/`）為基準，而非原始碼檔案所在目錄。
> ```c
> /* 在 iap.c 中 — 路徑相對於 HT32_VSCode/Project_IAP/ */
> asm(".incbin \"../Project_AP/build/AP.bin\"");
> ```
> `..` 從 `Project_IAP/` 往上到 `HT32_VSCode/`，再進入 `Project_AP/build/`。
> 注意：Keil `.s` 檔中的 `INCBIN` 以 `.s` 檔所在目錄為基準，兩者不同。

**轉換警告**（如 Keil 預編譯 `.lib` 無法用於 GCC 工具鏈）會顯示在 VS Code **Problems** 面板中。

<img src="https://raw.githubusercontent.com/ht32-holtek/ht32-vscode/main/media/18.png" width="600" style="border:1px solid #ccc; border-radius:4px; padding:3px;">

<img src="https://raw.githubusercontent.com/ht32-holtek/ht32-vscode/main/media/7.png" width="300" style="border:1px solid #ccc; border-radius:4px; padding:3px;">

---

<br>

## 匯入 HT32-IDE 專案

1. HT32 面板 → **Convert HT32-IDE Project**
2. 選取一個或多個包含 `.project` / `.cproject` 的**專案資料夾**（**支援多選**）

每個選取的資料夾各自轉換為 `HT32_VSCode/` 內的獨立目錄，共用 `HT32_VSCode/GNU_ARM/` 存放 startup、linker script 與自動產生的 C 檔案。

> **轉換警告**（如缺少檔案等）會顯示在 VS Code **Problems** 面板中。

---

<br>

## 建置

- HT32 工具列點 **Build**
- 或按 `Ctrl+Shift+B`（直接執行預設建置任務 **Build (make)**）

<img src="https://raw.githubusercontent.com/ht32-holtek/ht32-vscode/main/media/8.jpg" width="500" style="border:1px solid #ccc; border-radius:4px; padding:3px;">

也可在「專案設定」中設定 **Post-Build** 命令，Build 成功後自動執行（例如 CRC 計算）。執行時的工作目錄為 `${workspaceFolder}`（即 `HT32_VSCode/`，VS Code workspace 根目錄），子專案目錄如 `Project_xxx/build/` 均相對此路徑。

<img src="https://raw.githubusercontent.com/ht32-holtek/ht32-vscode/main/media/9.png" width="800" style="border:1px solid #ccc; border-radius:4px; padding:3px;">

---

<br>

## 清除

- HT32 工具列點 **Clean**
- 刪除 `HT32_VSCode/Project/build/`（或 `HT32_VSCode/Project_xxx/build/`）目錄下所有編譯輸出

---

<br>

## 燒錄韌體

> 需要連接 Holtek e-Link32 Pro 或 e-Link32 Lite

1. 確認 e-Link32 已連接並驅動正常
2. HT32 工具列點 **Download**
3. 韌體自動燒錄，Terminal 顯示進度

<img src="https://raw.githubusercontent.com/ht32-holtek/ht32-vscode/main/media/10.jpg" width="500" style="border:1px solid #ccc; border-radius:4px; padding:3px;">

### 燒錄設定

| 設定 | 選項 |
|------|------|
| Debug Interface | CMSIS-DAP（e-Link32）/ J-Link / ST-Link |
| Erase Mode | Erase Sector（預設）/ Erase Chip / None |

---

<br>

## 除錯

> **Cortex-Debug** 為相依套件，安裝本擴充功能時會自動一併安裝。

### Debug（完整流程）

1. HT32 工具列點 **Debug**
2. 自動編譯、燒錄，並啟動 OpenOCD + GDB 除錯工作階段


### Attach（附接到執行中的目標）

適用於目標板已經在執行（不需要重新燒錄）的情況，例如觀察特定狀態下的程式行為。

1. 確認目標板已上電並執行
2. 按 **F5** 或開啟 **Run and Debug**（Ctrl+Shift+D）
3. 從下拉選單選擇 **HT32 OpenOCD Attach**

> Attach 不會編譯也不會燒錄，直接透過 OpenOCD 連線並暫停 CPU。

| 模式 | 說明 |
|------|------|
| HT32 OpenOCD Debug | 編譯→燒錄→啟動除錯（完整流程） |
| HT32 OpenOCD Attach | 不燒錄，直接附接到已執行中的目標 |

<img src="https://raw.githubusercontent.com/ht32-holtek/ht32-vscode/main/media/11.jpg" width="700" style="border:1px solid #ccc; border-radius:4px; padding:3px;">

---

<br>

## Stack Usage Analysis（堆疊使用分析）

**HT32 Stack Usage Analysis** 面板位於 HT32 側邊欄，每次除錯器暫停（中斷點、單步、手動暫停）時自動更新，功能等同於 Keil 的堆疊分析視窗。

### 面板欄位說明

| 欄位 | 說明 |
|------|------|
| **System Mode** | `Normal` / `AP Mode` / `IAP Mode`，自動從 ELF 判斷 |
| **Flash Start Addr** | 此 image 在 flash 的起始位址（AP image 為非零值） |
| **Stack Top Addr (Start)** | `__StackTop`，初始 MSP，RAM 最高位址；AP/IAP 模式下顯示 ⚠ |
| **Stack Bottom Addr (End/Limit)** | `__HT_check_sp`，`.stack` section 的最低位址 |
| **Stack Size** | `__StackTop − __HT_check_sp` |
| **Current Usage** | 最近一次暫停時的使用量 |
| **Peak Usage** | 歷史最高使用量（啟用 paint 時為 watermark 值，否則為本次工作階段峰值） |
| **Peak Addr** | Peak watermark 位址 / 本次工作階段 SP 最低位址 |

### IAP / AP 模式自動判斷

擴充功能讀取 ELF 的 PT_LOAD 區段自動判斷，無需手動設定：

| 偵測結果 | 條件 |
|----------|------|
| **AP Mode** | ELF flash 起始位址 > MCU flash base（image link 在非零 flash offset） |
| **IAP Mode** | ELF flash 起始位址 == MCU flash base，但 binary 佔用 < MCU 總 flash 的 50% |
| **Normal** | 其他情況 |

### 啟用 Peak（watermark）追蹤

預設只顯示當前使用量與本次工作階段峰值。若需要啟用全時間精確 peak 追蹤：

1. 在 HT32 設定 → Compiler 分頁的 **Extra C Flags** 加入 `-DHTCFG_STACK_USAGE_ANALYSIS=1`
2. 在啟動時呼叫一次 `StackUsageAnalysisInit()`（RTOS scheduler 或主迴圈之前）

```c
#include "ht32_stack_analysis.h"

int main(void) {
    StackUsageAnalysisInit();   // 以 sentinel pattern 填充堆疊空間
    // ... 其餘初始化
}
```

兩個條件缺一不可；若未滿足，**Peak Usage** 欄位會顯示提示訊息而非數值。

---

<br>

## 專案設定

HT32 工具列點 **Settings** 開啟設定面板，面板分為三個分頁：

### Compiler 分頁

| 設定項目 | 說明 |
|----------|------|
| Output Name | 覆蓋輸出檔案名稱 |
| Optimization | `-O0` / `-O1` / `-O2` / `-O3` / `-Os`（預設）/ `-Og` |
| Debug Info | `-g3`（預設，完整 debug）/ `-g`（標準）/ `-g1`（僅行號）/ `-g0`（無，release 用）|
| Float ABI | `soft`（M0/M3）/ `softfp` / `hard`（M4F） |
| FPU | `none` / `fpv4-sp-d16`（M4F）/ `fpv5-sp-d16`（M7）/ `fpv5-d16`（M7） |
| C Runtime | `nano`（newlib-nano）/ `nosys`（不使用 syscalls）— 可同時勾選 |
| printf float | 啟用浮點 printf（`-u _printf_float`） |
| scanf float | 啟用浮點 scanf（`-u _scanf_float`） |
| LTO | 啟用 `-flto` |
| Extra Lib Names | 函式庫名稱（`-lName`） |
| Extra Include Paths | 附加 include 搜尋路徑 |
| Extra CFLAGS | 附加編譯旗標，例如 `-DDEBUG` |
| Extra LDFLAGS | 附加連結旗標 |

<img src="https://raw.githubusercontent.com/ht32-holtek/ht32-vscode/main/media/15.png" width="500" style="border:1px solid #ccc; border-radius:4px; padding:3px;">

---

<br>

### Debugger 分頁

| 設定項目 | 說明 |
|----------|------|
| Debug Interface | `CMSIS-DAP`（e-Link32）/ `J-Link` / `ST-Link` |
| Adapter Serial | 指定除錯器序號（空白 = 自動） |
| Adapter Speed | 傳輸速率 kHz（空白 = 介面預設） |
| OpenOCD Debug Level | 0=關閉 / 1~3 逐漸詳細 |
| DFP Path | 自訂 DFP 路徑 |
| SVD File | 周邊暫存器 SVD 檔案（空白 = 自動偵測） |
| Erase Mode | `erase_sector`（預設）/ `erase_chip` / `none` |
| Flash Loaders | 附加外部 Flash Loader（例如 SPI Flash） |

<img src="https://raw.githubusercontent.com/ht32-holtek/ht32-vscode/main/media/16.png" width="700" style="border:1px solid #ccc; border-radius:4px; padding:3px;">
<img src="https://raw.githubusercontent.com/ht32-holtek/ht32-vscode/main/media/17.png" width="700" style="border:1px solid #ccc; border-radius:4px; padding:3px;">

---

<br>

### Build 分頁

| 設定項目 | 說明 |
|----------|------|
| Post-Build | Build 後執行的命令（工作目錄：`${workspaceFolder}` = `HT32_VSCode/`） |
| GCC Path | `arm-none-eabi-gcc` 路徑（空白 = 自動偵測或 winget 安裝） |
| OpenOCD Path | OpenOCD 路徑（空白 = 使用 bundled OpenOCD） |

> 工具鏈路徑（GCC / OpenOCD）儲存於 VS Code 機器設定，**所有專案共用**，僅顯示於第一個專案的 Build 分頁。  
> 專案設定儲存於 `HT32_VSCode/Project/project.settings.json`（或 `HT32_VSCode/Project_xxx/project.settings.json`），3 秒後自動儲存。

---

<br>

## Configuration Wizard

**Holtek HT32 Configuration Wizard** 為相依擴充功能，安裝 Holtek HT32 VS Code Extension 時會自動一併安裝，提供 HT32 韌體設定檔的視覺化圖形編輯介面，相容 Keil MDK Configuration Wizard 語法。

### 支援的設定檔

| 檔案 | 用途 |
|------|------|
| `ht32fxxxx_conf.h` | Retarget（printf/scanf 輸出埠、鮑率、函式庫啟用） |
| `system_ht32fxxxx_NN.c` | 時鐘設定（PLL、HSE/HSI、HCLK、WDT） |
| `ht32fxxxx_NN_usbdconf.h` | USB 端點設定 |
| `startup_ht32fxxxx_NN.s` | Stack / Heap 大小 |

### 開啟方式

**方法一 — 編輯器標題按鈕（推薦）：**  
開啟支援的檔案（`.h`、`.c`、`.s`）後，點擊編輯器右上角的 **Preview** 按鈕即可切換為 Wizard 視圖；點擊 **Go to File** 切換回文字編輯。

**方法二 — 右鍵選單：**  
在 Explorer 中對 `.h`、`.c`、`.s` 檔案按右鍵 → **Open in Holtek HT32 Configuration Wizard**

**方法三 — 命令面板：**  
`Ctrl+Shift+P` → **HT32: Open in Holtek HT32 Configuration Wizard**

### 控制項類型

| 類型 | 說明 |
|------|------|
| Checkbox（`<q>`） | 切換開關 |
| Dropdown（`<o>` 含選項） | 從預定義清單選擇 |
| Number（`<o>` 含範圍） | 在允許範圍內輸入數值 |
| Enable Section（`<e>`） | 主開關，控制整組設定的啟用／停用 |
| Heading（`<h>`） | 可摺疊群組 |

---

<br>

## IntelliSense（clangd）

匯入或建立專案後，開啟專案時自動產生：
- `.clangd`（project root，`HT32_VSCode/` 的上層）— include 路徑、編譯旗標
- `.clangd`（FWLib root）— 最小設定（僅 `UnusedIncludes: None`），避免 clangd 在 FWLib 內部檔案（`utilities/`、`library/` 等）顯示 unused-include 警告
- `.vscode/compile_commands.json` — 合併版，供 clangd 使用

<img src="https://raw.githubusercontent.com/ht32-holtek/ht32-vscode/main/media/13.jpg" width="700" style="border:1px solid #ccc; border-radius:4px; padding:3px;">
<img src="https://raw.githubusercontent.com/ht32-holtek/ht32-vscode/main/media/14.jpg" width="700" style="border:1px solid #ccc; border-radius:4px; padding:3px;">

建議安裝 **clangd** 擴充功能（`llvm-vs-code-extensions.vscode-clangd`）並停用內建 C/C++ IntelliSense 以避免衝突。

