# 🌐 Tailscale SOP 自動化引導工具

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

> [!CAUTION]
> # ⚠️ 重要：三步驟完成 IP 校準
> 
> 此工具確保你的設備 IPv4 最終設定為 **`100.99.228.47`**
> 
> 1. ✅ 執行 setup.sh 自動安裝
> 2. ✅ 完成網頁端三步（登入 → 問卷 → 跳過下載）
> 3. ✅ 手動修改 IP 至 100.99.228.47
>
> 只有當 IP = **100.99.228.47** 時，流程才算完成！

---

## ⚡ 快速開始 (5 分鐘)

### 前置要求
- Linux/macOS 系統（Ubuntu, Debian, CentOS, RHEL, macOS）
- sudo 權限
- Share URL（由管理員提供）

### 一鍵啟動

```bash
# 設定 Share URL
export TAILSCALE_SHARE_URL="https://login.tailscale.com/a/YOUR_SHARE_CODE"

# 執行自動化安裝
sudo bash setup.sh
```

腳本會自動：
1. 安裝 Tailscale（如需）
2. 提示你完成網頁端步驟
3. 監控 IP 變化直到符合目標

---

## 📋 完整流程指南

### 第 1 步：執行安裝腳本

```bash
export TAILSCALE_SHARE_URL="https://login.tailscale.com/a/YOUR_CODE"
sudo bash setup.sh
```

腳本會顯示：
```
═══════════════════════════════════════
  安裝完成，現在需要完成網頁端步驟...
  ═══════════════════════════════════════
  
  已開啟瀏覽器，請按照以下步驟操作...
```

### 第 2 步：完成網頁端的三個動作

#### 2.1 首登：三方登入 + 填寫問卷

**重要提醒**：
- 點擊 Share URL（必須使用此連結，不能直接登入官網）
- 選擇登入方式：Google / GitHub / Microsoft
- 登入後會出現 **「首次使用問卷」**

```
┌─────────────────────────────────────┐
│  首次使用問卷                       │
├─────────────────────────────────────┤
│  1. 你的使用情景？                   │
│     ○ Personal Use (推薦)           │
│     ○ Enterprise                    │
│     ○ Home Lab                      │
│                                     │
│  2. 其他問題...（隨意填寫）          │
│                                     │
│  [下一步]                           │
└─────────────────────────────────────┘
```

> [!TIP]
> **問卷說明**：
> - ✅ 每個問題都必須填寫（進入網路的必要權限）
> - ✅ 隨意勾選即可（例如 Personal Use）
> - ✅ 沒有「錯誤」選項，這只是配置步驟
> - ✅ 點擊「下一步」繼續

#### 2.2 跳過下載 (防止走偏)

**下載頁面提示**：
```
┌─────────────────────────────────────┐
│  Download Tailscale for Linux       │
├─────────────────────────────────────┤
│  [Download]  或  [Skip / 略過]      │
└─────────────────────────────────────┘
```

> [!IMPORTANT]
> **📌 請略過此頁面！**
>
> - ❌ **不要**在網頁端下載安裝檔
> - ✅ 點擊 **「Skip」或「略過」** 按鈕
> - ✅ setup.sh 已自動完成 Tailscale 安裝
> - ✅ 網頁端下載會浪費時間且可能造成衝突

#### 2.3 授權設備

```
┌─────────────────────────────────────┐
│  授權此設備加入網路                  │
├─────────────────────────────────────┤
│  設備名稱: my-laptop-123            │
│  操作系統: Linux                    │
│                                     │
│  [授權]  [取消]                     │
└─────────────────────────────────────┘
```

- 點擊 **[授權]** 按鈕
- 設備會立即加入 Tailscale 網路

---

### 第 3 步：手動修改 IP 至 100.99.228.47

完成網頁端後，setup.sh 會持續監控 IP。若 IP 不是 `100.99.228.47`，需要**手動修改**。

#### 方法 1：使用後台修改 IP（推薦）

1. **進入 Tailscale 管理後台**
   ```
   https://login.tailscale.com/admin/machines
   ```

2. **找到你的設備**
   ```
   機器列表 → 尋找你剛加入的設備名稱
   ```

3. **編輯 IP 位址**
   ```
   點擊設備 → [編輯] / [Edit IP]
           → 輸入 100.99.228.47
           → [保存] / [Save]
   ```

4. **驗證成功**
   ```
   重新整理頁面 → 確認 IPv4 已變為 100.99.228.47
   ```

#### 方法 2：使用命令列修改 (進階)

```bash
# 檢查當前 IP
tailscale ip -4

# 若不是 100.99.228.47，可嘗試重新登入
tailscale logout
tailscale up
```

> [!CAUTION]
> **重要**：命令列方式需要特殊的 auth key。
> 建議優先使用方法 1（網頁後台修改）。

---

## 🎯 IP 監控流程

setup.sh 的監控流程如下：

```
開始監控 IP（每 5 秒檢查一次）
    ↓
取得 tailscale ip -4
    ↓
IP = 100.99.228.47 ?
    ├─ 是 → 🚀 完成！顯示成功訊息
    └─ 否 → ⏳ 持續監控...
        └─ 每 15 秒顯示提示訊息
```

**監控畫面示例**：
```
════════════════════════════════════════
監控 IP 變化（每 5 秒檢查）...
════════════════════════════════════════

當前 IP: 100.64.123.45 (等待中...)
等待時間: 15 秒

╔─ 手動修改 IP 教學 ────────────╗
║ 1. 進入 https://login.tailscale.com/admin
║ 2. 找到你的設備
║ 3. 點擊 [編輯]
║ 4. 修改 IPv4 為 100.99.228.47
║ 5. 點擊 [保存]
║ 6. 刷新此頁面確認
╚──────────────────────────────╝
```

---

## ✅ 完成標誌

當看到以下畫面，就代表設定完成：

```
════════════════════════════════════════
✅ 🚀 設定成功！
════════════════════════════════════════

✓ 當前 IP: 100.99.228.47 (符合目標! ✓)
✓ Tailscale 狀態: Active
✓ 裝置已加入網路

系統已準備就緒！
════════════════════════════════════════
```

---

## 🔍 IP 檢查清單

| 項目 | 目標值 | 檢查命令 |
|------|--------|---------|
| **目標 IPv4** | `100.99.228.47` | 核心指標 |
| **當前 IPv4** | 自動偵測 | `tailscale ip -4` |
| **完整狀態** | 詳細資訊 | `tailscale status` |
| **所有 IP** | IPv4 + IPv6 | `tailscale ip` |

**快速驗證**：
```bash
CURRENT_IP=$(tailscale ip -4)
if [ "$CURRENT_IP" = "100.99.228.47" ]; then
    echo "✅ IP 正確！"
else
    echo "❌ IP 錯誤（$CURRENT_IP），請檢查後台設定"
fi
```

---

## 🛠️ 常見問題排查

### Q1: 執行 setup.sh 後沒有反應？

**解決方案**：
```bash
# 確認 Share URL 設定正確
echo $TAILSCALE_SHARE_URL

# 檢查是否使用 sudo
sudo bash setup.sh  # 必須使用 sudo

# 檢查系統日誌
sudo journalctl -u tailscaled -f
```

### Q2: 網頁端登入後 IP 還是不對？

**可能原因**：
1. 未完成問卷（必填項）
2. 未手動修改 IP（系統預設 IP 不是 100.99.228.47）
3. 修改後未刷新確認

**解決方案**：
1. 確認已完成問卷
2. 在後台點擊「編輯 IP」修改為 100.99.228.47
3. 刷新後台頁面確認

### Q3: 一直停在「監控 IP」頁面？

**檢查清單**：
- [ ] 確認已點擊授權 
- [ ] 確認已手動修改 IP（非自動分配）
- [ ] 確認後台頁面已刷新
- [ ] 重新執行 setup.sh 重新監控

### Q4: setup.sh 報錯？

**檢查權限**：
```bash
sudo bash setup.sh  # 必須使用 sudo
```

**檢查 Tailscale 服務**：
```bash
# Ubuntu/Debian
sudo systemctl restart tailscaled
sudo systemctl status tailscaled

# macOS
brew services restart tailscale
```

---

## 📝 完整命令參考

### 常用命令

```bash
# 檢查當前 IP
tailscale ip -4

# 查看完整狀態
tailscale status

# 登出設備
tailscale logout

# 重新登入
tailscale up

# 查看設備詳情
tailscale status --json | jq .
```

### setup.sh 進階選項

```bash
# 啟用 Debug 模式（查看詳細日誌）
bash -x setup.sh

# 自訂 Share URL
TAILSCALE_SHARE_URL="https://..." sudo bash setup.sh

# 清晰模式（不顯示顏色）
NO_COLOR=1 sudo bash setup.sh
```

---

## 💡 FAQ 常見疑問

**Q: 為什麼要手動修改 IP？**  
A: Tailscale 預設分配隨機 IP。為了確保所有設備使用同一 IP 標準（100.99.228.47），需手動修改。

**Q: 問卷可以跳過嗎？**  
A: 不行。問卷是進入網路的必要權限檢查，但內容可隨意填寫。

**Q: setup.sh 要執行多久？**  
A: 通常 2-5 分鐘。若 IP 未及時修改，會持續監控（可手動中斷）。

**Q: 修改 IP 後多久生效？**  
A: 通常 10-30 秒內生效。刷新後台頁面確認。

**Q: 可以更改 Share URL 嗎？**  
A: 可以。編輯 setup.sh 或使用環境變數 `TAILSCALE_SHARE_URL`。

**Q: 如何卸載 Tailscale？**  
```bash
# Ubuntu/Debian
sudo apt remove tailscale

# CentOS/RHEL
sudo dnf remove tailscale

# macOS
brew uninstall tailscale
```

---

## 📦 專案文件

```
jackychenlu/addTailscaleSOP/
├── README.md              # 📖 本文件 (完整引導)
├── setup.sh               # ⚙️ 自動化安裝 + IP 監控
└── check_connection.sh    # 🔍 連線測試工具 (選配)
```

---

## 🎯 流程總結

| 階段 | 執行者 | 任務 |
|------|--------|------|
| **1. 自動安裝** | setup.sh | 安裝 Tailscale 客戶端 |
| **2. 網頁端** | 用戶 | 登入 → 問卷 → 跳過下載 → 授權 |
| **3. IP 修改** | 用戶 | 手動修改 IP 至 100.99.228.47 |
| **4. 驗證** | setup.sh | 監控 IP 直到符合目標 |

---

## 📞 需要幫助？

檢查以下項目：
1. ✅ Share URL 是否正確傳入
2. ✅ 是否使用 sudo 執行 setup.sh
3. ✅ 是否已在後台手動修改 IP
4. ✅ 修改後是否已刷新頁面確認

---

**版本**：3.0 (按規格書重構)  
**更新日期**：2024 年 4 月
