#!/bin/bash

################################################################################
# Tailscale SOP 自動化引導工具 - setup.sh
# 功能：自動安裝 + 網頁端暫停引導 + IP 監控校驗
# 支援：Ubuntu, Debian, CentOS, RHEL, macOS
################################################################################

set -e

# 顏色定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# 常數
TARGET_IP="100.99.228.47"
SHARE_URL="${TAILSCALE_SHARE_URL:-https://login.tailscale.com/a/}"
MAX_WAIT_TIME=600  # 最長等待 10 分鐘

################################################################################
# 輸出函數
################################################################################

print_title() {
    echo -e "${BLUE}════════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}════════════════════════════════════════════════════════════${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

print_instr() {
    echo -e "${CYAN}→ $1${NC}"
}

################################################################################
# 系統檢測與安裝
################################################################################

detect_os() {
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if [ -f /etc/os-release ]; then
            . /etc/os-release
            echo "$ID"
        else
            echo "linux"
        fi
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        echo "macos"
    fi
}

check_root() {
    if [[ $EUID -ne 0 ]]; then
        print_error "此腳本需要 root 或 sudo 權限"
        echo "請執行："
        echo "  sudo bash setup.sh"
        exit 1
    fi
}

check_tailscale_installed() {
    command -v tailscale &> /dev/null
}

install_tailscale() {
    local os=$(detect_os)
    
    print_title "安裝 Tailscale"
    print_info "偵測到作業系統：$os"
    
    case "$os" in
        ubuntu|debian)
            echo "執行 Ubuntu/Debian 安裝..."
            curl -fsSL https://tailscale.com/install.sh | sh
            ;;
        rhel|fedora|centos)
            echo "執行 CentOS/RHEL 安裝..."
            dnf install -y tailscale || yum install -y tailscale
            systemctl enable tailscaled
            systemctl start tailscaled
            ;;
        macos)
            echo "執行 macOS 安裝..."
            if ! command -v brew &> /dev/null; then
                print_error "需要安裝 Homebrew"
                exit 1
            fi
            brew install tailscale
            brew services start tailscale
            ;;
        *)
            print_error "不支援的作業系統：$os"
            exit 1
            ;;
    esac
    
    print_success "Tailscale 安裝完成"
    sleep 2
}

################################################################################
# 網頁端引導
################################################################################

show_web_guide() {
    print_title "安裝完成 - 需要完成網頁端步驟"
    echo ""
    echo -e "${GREEN}現在需要你在網頁端完成以下步驟：${NC}"
    echo ""
    
    print_instr "第 1 步：點擊 Share URL 並登入"
    echo "   Share URL："
    echo -e "   ${CYAN}${SHARE_URL}${NC}"
    echo ""
    echo "   動作："
    echo "   • 點擊上方連結"
    echo "   • 選擇登入方式（Google / GitHub / Microsoft）"
    echo "   • 登入你的帳戶"
    echo ""
    
    print_instr "第 2 步：填寫首次使用問卷"
    echo "   動作："
    echo "   • 回答所有問題（隨意勾選，例如 Personal Use）"
    echo "   • 點擊『下一步』"
    echo ""
    
    print_instr "第 3 步：跳過下載頁面（重要！）"
    echo "   動作："
    echo "   • 點擊『Skip』或『略過』按鈕"
    echo "   • 不要在網頁端下載安裝檔"
    echo "   • setup.sh 已自動完成安裝"
    echo ""
    
    print_instr "第 4 步：授權設備"
    echo "   動作："
    echo "   • 點擊『授權』按鈕"
    echo "   • 設備會立即加入網路"
    echo ""
    
    echo -e "${YELLOW}完成以上步驟後，按 Enter 鍵繼續...${NC}"
    read -r
}

################################################################################
# IP 監控與驗證
################################################################################

get_current_ip() {
    tailscale ip -4 2>/dev/null || echo ""
}

show_ip_instruction() {
    echo ""
    echo -e "${MAGENTA}╔─ 手動修改 IP 教學 ────────────────────╗${NC}"
    echo -e "${MAGENTA}║${NC} 若 IP 不是 100.99.228.47，需手動修改：${MAGENTA}║${NC}"
    echo -e "${MAGENTA}║${NC}  ${MAGENTA}║${NC}"
    echo -e "${MAGENTA}║${NC} 1. 進入 https://login.tailscale.com/admin${MAGENTA}║${NC}"
    echo -e "${MAGENTA}║${NC} 2. 找到你的設備${MAGENTA}║${NC}"
    echo -e "${MAGENTA}║${NC} 3. 點擊『編輯』或『Edit IP』${MAGENTA}║${NC}"
    echo -e "${MAGENTA}║${NC} 4. 修改 IPv4 為 100.99.228.47${MAGENTA}║${NC}"
    echo -e "${MAGENTA}║${NC} 5. 點擊『保存』${MAGENTA}║${NC}"
    echo -e "${MAGENTA}║${NC} 6. 刷新此頁面確認${MAGENTA}║${NC}"
    echo -e "${MAGENTA}╚─────────────────────────────────────╝${NC}"
}

monitor_ip() {
    print_title "監控 IP 變化"
    echo ""
    print_info "開始監控 IP（每 5 秒檢查一次）..."
    echo ""
    
    local start_time=$(date +%s)
    local last_ip=""
    local check_count=0
    
    while true; do
        check_count=$((check_count + 1))
        CURRENT_IP=$(get_current_ip)
        
        # 清空前 10 行以及下面的指導
        if [ $check_count -gt 1 ]; then
            # 使用 tput 清除屏幕，或者简单地输出新信息
            clear
            print_title "監控 IP 變化"
            echo ""
        fi
        
        if [ -n "$CURRENT_IP" ]; then
            if [ "$CURRENT_IP" != "$last_ip" ]; then
                print_info "當前 IP：$CURRENT_IP"
                last_ip="$CURRENT_IP"
            fi
            
            if [ "$CURRENT_IP" = "$TARGET_IP" ]; then
                echo ""
                print_success "🚀 IP 驗證成功！"
                echo -e "${GREEN}當前 IP：$CURRENT_IP 符合目標！${NC}"
                echo ""
                return 0
            else
                ELAPSED=$(($(date +%s) - start_time))
                echo -e "${YELLOW}等待中... ($ELAPSED 秒)${NC}"
                echo ""
                
                # 每 15 秒顯示一次指導
                if [ $((check_count % 3)) -eq 0 ]; then
                    show_ip_instruction
                fi
            fi
        else
            print_warning "尚未取得 IP，繼續等待..."
            echo ""
            
            # 每 15 秒顯示一次指導
            if [ $((check_count % 3)) -eq 0 ]; then
                show_ip_instruction
            fi
        fi
        
        # 檢查是否超時
        ELAPSED=$(($(date +%s) - start_time))
        if [ $ELAPSED -gt $MAX_WAIT_TIME ]; then
            echo ""
            print_error "超時：無法在 10 分鐘內取得正確的 IP"
            echo ""
            print_warning "可能原因："
            echo "  1. 未完成網頁端步驟（登入、問卷、跳過下載、授權）"
            echo "  2. 未手動修改 IP（Tailscale 預設 IP 不是 100.99.228.47）"
            echo "  3. 修改後未刷新確認"
            echo ""
            echo "請檢查上述項目並重新執行 setup.sh"
            exit 1
        fi
        
        sleep 5
    done
}

################################################################################
# 完成顯示
################################################################################

show_success() {
    echo ""
    print_title "✅ 設定成功！"
    echo ""
    print_success "Tailscale 已配置完成"
    print_success "當前 IP：$CURRENT_IP"
    print_success "設備已加入網路"
    echo ""
    echo "系統已準備就緒！"
    echo ""
    echo "後續命令："
    echo "  • 檢查狀態      tailscale status"
    echo "  • 檢查 IP       tailscale ip -4"
    echo "  • 測試連線      bash check_connection.sh"
    echo "  • 登出          tailscale logout"
    echo ""
}

################################################################################
# 主程序
################################################################################

main() {
    print_title "Tailscale SOP 自動化引導工具"
    echo ""
    
    # 檢查權限
    check_root
    
    # 檢查/安裝 Tailscale
    if check_tailscale_installed; then
        print_success "Tailscale 已安裝"
    else
        print_warning "Tailscale 未安裝，準備安裝..."
        install_tailscale
    fi
    
    echo ""
    
    # 顯示網頁端引導
    show_web_guide
    
    echo ""
    print_info "執行 tailscale up..."
    tailscale up
    
    echo ""
    echo ""
    
    # 監控 IP
    monitor_ip
    
    # 顯示完成
    show_success
}

# 錯誤處理
trap 'print_error "安裝過程中出現錯誤"; exit 1' ERR

# 主程序
main "$@"
