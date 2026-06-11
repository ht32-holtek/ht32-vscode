[English](http://mcutest.holtek.com.tw/ht32-vscode/) | [中文使用手冊](#holtek-ht32-vs-code-extension)

# Holtek HT32 VS Code Extension
Holtek HT32 系列 Cortex-M 微控制器專用 VS Code 擴充功能

- 支援 HT32 全系列（Cortex-M0+/M3/M4）
- 建立新專案 / 匯入 Keil uVision / 匯入 HT32-IDE
- 一鍵編譯、燒錄、除錯；內建 OpenOCD + e-Link32 支援

## 安裝需求

| 項目 | 說明 |
|------|------|
| 作業系統 | Windows x64 |
| 除錯器 | Holtek e-Link32 Pro / Lite（推薦）；支援 J-Link、ST-Link |
| FWLib | 需要；支援 HT32F1xxxx / HT32F4xxxx / HT32F5xxxx / HT32F490x1 / HT32F491x3 / HT32F493x5 |

> **GCC 工具鏈**：擴充功能啟動時自動偵測；找不到時透過 winget 自動安裝<br>
> **OpenOCD**：已內建，無需另外安裝<br>
> **相依擴充功能**：安裝時自動一併安裝 **Cortex-Debug**（除錯介面）與 **Holtek HT32 Configuration Wizard**（設定精靈）

---
## 安裝擴充功能

**方法一：從 .vsix 安裝**

1. VS Code → 擴充功能 → `...` → **Install from VSIX...**
2. 選取 `ht32-vscode-x.x.x.vsix`

<table><tr>
<td><img src="https://raw.githubusercontent.com/ht32-holtek/ht32-vscode/main/media/1.jpg" width="350" style="border:1px solid #ccc; border-radius:4px; padding:3px;"></td>
<td><img src="https://raw.githubusercontent.com/ht32-holtek/ht32-vscode/main/media/2.jpg" width="350" style="border:1px solid #ccc; border-radius:4px; padding:3px;"></td>
</tr></table>

---
**方法二：從 Marketplace 安裝**

1. 擴充功能搜尋欄輸入 `Holtek HT32 VS Code Extension`
2. 點 **Install**

<img src="https://raw.githubusercontent.com/ht32-holtek/ht32-vscode/main/media/3.jpg" width="300" style="border:1px solid #ccc; border-radius:4px; padding:3px;">

---

## 介面介紹 — 專案未開啟

安裝後，左側 Activity Bar 出現 **HT32 圖示**，點擊展開 HT32 面板。

專案未開啟時顯示 **Create / Open / Convert** 按鈕；若有歷史記錄，下方會列出 **Recent Projects**，點擊即可直接開啟。

<img src="https://raw.githubusercontent.com/ht32-holtek/ht32-vscode/main/media/4.jpg" width="300" style="border:1px solid #ccc; border-radius:4px; padding:3px;">


---

## 介面介紹 — 專案已開啟時的工具列


| 按鈕 | 功能 |
|------|------|
| Build | 編譯 |
| Debug | 除錯 |
| Clean | 清除 |
| Download | 燒錄 |
| Settings | 專案設定 |
| Generate Config | 重新產生 tasks.json / launch.json |

---

## 介面介紹 — 專案檔案樹

HT32 面板下方顯示專案的原始碼群組結構（Source Groups），與 Keil uVision 的群組概念相同。

<img src="https://raw.githubusercontent.com/ht32-holtek/ht32-vscode/main/media/5.jpg" width="300" style="border:1px solid #ccc; border-radius:4px; padding:3px;">

右鍵選單支援以下操作：

| 對象 | 操作 |
|------|------|
| 專案根節點 | 新增群組 |
| 群組 | 新增檔案、移除群組 |
| 檔案 | 從群組移除、從磁碟刪除 |

---

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

## 建立新專案 — 產生的檔案結構

```
<workspace>/
├── .clangd
├── src/
│   ├── main.c
│   ├── ht32fxxxx_it.c
│   ├── system_ht32fxxxx.c
│   ├── ht32fxxxx_conf.h
│   └── ht32_op.c
└── .vscode/
    ├── tasks.json
    ├── launch.json
    ├── compile_commands.json
    └── build-gen/
        ├── Makefile
        ├── linker_script.ld
        ├── startup_ht32fxxxx_gcc_xx.s
        ├── ht32_syscalls.c
        ├── ht32_retarget_gnu.c
        └── *.json                      ← 專案與建置中繼資料
```

> **49x 系列**（HT32F490x / 491x / 493x）的 `src/` 包含 board 支援檔（`ht32fXXXxX_board.c/h`）而非 `ht32_op.c`。

---

## 匯入 Keil uVision 專案

1. HT32 面板 → **Convert uVision Project**
2. 選取 `.uvprojx`（單一專案）或 `.uvmpw`（多專案）

`.uvmpw` 會將所有子專案**一次全部轉換**，每個子專案各產生一個獨立的目錄，名稱取自 `.uvprojx` 檔名後段（小寫）。

**自動產生：**

- `Makefile`（MCU 型號、編譯旗標、來源檔案）
- `linker_script.ld`（從 Keil scatter 轉換）
- `startup_xxx_gcc.s`（從 Keil startup 轉換）
- `compile_commands.json` / `tasks.json` / `launch.json`

**單一 `.uvprojx`** — 輸出至 `.vscode/build-gen/`

**`.uvmpw` 多專案** — 每個子專案各一個目錄，例如 `Project_IAP.uvprojx` + `Project_AP.uvprojx`：

**轉換警告:**

如 Keil 預編譯 `.lib` 無法用於 GCC 工具鏈）會顯示在 VS Code **Problems** 面板中。

<img src="https://raw.githubusercontent.com/ht32-holtek/ht32-vscode/main/media/18.png" width="600" style="border:1px solid #ccc; border-radius:4px; padding:3px;">


```
.vscode/
├── tasks.json
├── launch.json
├── build-gen-iap/
│   ├── Makefile
│   ├── linker_script.ld
│   └── *.json
└── build-gen-ap/
    ├── Makefile
    ├── linker_script.ld
    └── *.json
```


<img src="https://raw.githubusercontent.com/ht32-holtek/ht32-vscode/main/media/7.png" width="300" style="border:1px solid #ccc; border-radius:4px; padding:3px;">

---

## 匯入 HT32-IDE 專案

1. HT32 面板 → **Convert HT32-IDE Project**
2. 選取包含 `.project` / `.cproject` 的**專案資料夾**

產生的檔案與 uVision 匯入相同。

若所選資料夾下有多個子專案，會**一次全部轉換**，每個子專案各產生獨立的 `build-gen-{suffix}/` 目錄（suffix 取自子資料夾名稱後段）。全部轉換完成後，所有專案都會同時顯示在 TreeView 中。

> **轉換警告**（如缺少檔案等）會顯示在 VS Code **Problems** 面板中。

---

## 建置

- HT32 工具列點 **Build**
- 或按 `Ctrl+Shift+B`（直接執行預設建置任務 **Build (make)**）

<img src="https://raw.githubusercontent.com/ht32-holtek/ht32-vscode/main/media/8.jpg" width="500" style="border:1px solid #ccc; border-radius:4px; padding:3px;">

也可在「專案設定」中設定 **Post-Build** 命令，Build 成功後自動執行（例如 CRC 計算）。

<img src="https://raw.githubusercontent.com/ht32-holtek/ht32-vscode/main/media/9.png" width="800" style="border:1px solid #ccc; border-radius:4px; padding:3px;">

---

## 清除

- HT32 工具列點 **Clean**
- 刪除 `.vscode/build-gen/build/` 目錄下所有編譯輸出

---

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

### Build 分頁

| 設定項目 | 說明 |
|----------|------|
| Post-Build | Build 後執行的命令 |
| GCC Path | `arm-none-eabi-gcc` 路徑（空白 = 自動偵測或 winget 安裝） |
| OpenOCD Path | OpenOCD 路徑（空白 = 使用 bundled OpenOCD） |

> 工具鏈路徑（GCC / OpenOCD）儲存於 VS Code 機器設定，**所有專案共用**，僅顯示於第一個專案的 Build 分頁。  
> 專案設定儲存於 `.vscode/build-gen/project.settings.json`，3 秒後自動儲存。

---

## Configuration Wizard

**Holtek HT32 Configuration Wizard** 為相依擴充功能，安裝 Project Assistant 時會自動一併安裝，提供 HT32 韌體設定檔的視覺化圖形編輯介面，相容 Keil MDK Configuration Wizard 語法。

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

## IntelliSense（clangd）

匯入或建立專案後，自動產生：
- `.clangd`（workspace root）— include 路徑、編譯旗標
- `.vscode/compile_commands.json` — 合併版，供 clangd 使用

<img src="https://raw.githubusercontent.com/ht32-holtek/ht32-vscode/main/media/13.jpg" width="700" style="border:1px solid #ccc; border-radius:4px; padding:3px;">
<img src="https://raw.githubusercontent.com/ht32-holtek/ht32-vscode/main/media/14.jpg" width="700" style="border:1px solid #ccc; border-radius:4px; padding:3px;">

建議安裝 **clangd** 擴充功能（`llvm-vs-code-extensions.vscode-clangd`）並停用內建 C/C++ IntelliSense 以避免衝突。

