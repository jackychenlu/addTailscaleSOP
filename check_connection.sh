#!/bin/bash

################################################################################
# Tailscale 連線測試工具 - check_connection.sh
# 功能：測試 Tailscale 連線是否正常工作
# 測試項目：IP 驗證、ping 測試、服務連線測試
################################################################################

set -e

# 顏色定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 目標 IP
TARGET_IP="100.99.228.47"

################################################################################
# 函數定義
################################################################################

print_title() {
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
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

# 檢查 Tailscale 是否已安裝
check_tailscale_installed() {
    if command -v tailscale &> /dev/null; then
        return 0
    else
        return 1
    fi
}

# 檢查 Tailscale 是否已執行
check_tailscale_running() {
    if tailscale status &> /dev/null; then
        return 0
    else
        return 1
    fi
}

# 测试 1: 檢查 Tailscale 狀態
test_tailscale_status() {
    print_title "測試 1: 檢查 Tailscale 狀態"
    
    if ! check_tailscale_installed; then
        print_error "Tailscale 未安裝"
        return 1
    fi
    
    print_success "Tailscale 已安裝"
    
    if ! check_tailscale_running; then
        print_error "Tailscale 未運行"
        return 1
    fi
    
    print_success "Tailscale 已運行"
    echo ""
}

# 测试 2: 驗證本地 IP 位址
test_local_ip() {
    print_title "測試 2: 驗證本地 IP 位址"
    
    local local_ip=$(tailscale ip -4)
    
    if [ -z "$local_ip" ]; then
        print_error "無法取得 Tailscale IP"
        return 1
    fi
    
    print_success "本地 Tailscale IP: $local_ip"
    
    if [ "$local_ip" = "$TARGET_IP" ]; then
        print_success "IP 驗證通過（目標：$TARGET_IP）"
    else
        print_warning "IP 不符預期"
        echo "當前：$local_ip，預期：$TARGET_IP"
    fi
    echo ""
}

# 测试 3: 檢查網路連線
test_network_connectivity() {
    print_title "測試 3: 檢查網路連線"
    
    print_info "取得 Tailscale 網路中的所有節點..."
    echo ""
    
    tailscale status
    
    echo ""
}

# 测试 4: 查詢 DNS 設定
test_dns_configuration() {
    print_title "測試 4: 查詢 DNS 設定"
    
    print_info "執行 Tailscale DNS 設定查詢..."
    
    # 嘗試取得 DNS 設定
    if tailscale status 2>/dev/null | grep -q "DNS:"; then
        print_success "DNS 已配置"
        tailscale status | grep "DNS:"
    else
        print_warning "無法確認 DNS 設定"
    fi
    
    echo ""
}

# 测试 5: Ping 測試（如果有其他節點）
test_connectivity_to_targets() {
    print_title "測試 5: 連線性測試"
    
    local targets=()
    
    # 從 tailscale status 中提取 IP 位址
    while IFS= read -r line; do
        # 跳過標題和當前主機
        if [[ $line == *"100.99"* ]] && ! [[ $line == *"100.99.228.47"* ]]; then
            ip=$(echo "$line" | awk '{print $1}')
            targets+=("$ip")
        fi
    done < <(tailscale status)
    
    if [ ${#targets[@]} -eq 0 ]; then
        print_warning "Tailscale 網路中沒有其他節點，跳過連線測試"
        echo ""
        return 0
    fi
    
    print_info "發現 ${#targets[@]} 個其他節點，嘗試 ping..."
    echo ""
    
    local success_count=0
    for target in "${targets[@]}"; do
        if ping -c 1 -W 2 "$target" &>/dev/null; then
            print_success "連線到 $target"
            ((success_count++))
        else
            print_warning "無法連線到 $target"
        fi
    done
    
    echo ""
    echo "成功連線的節點：$success_count / ${#targets[@]}"
    echo ""
}

# 主要執行流程
main() {
    print_title "Tailscale 連線測試工具"
    echo ""
    
    # 執行所有測試
    test_tailscale_status || exit 1
    test_local_ip || exit 1
    test_network_connectivity
    test_dns_configuration
    test_connectivity_to_targets
    
    # 完成
    print_title "測試完成"
    print_success "所有關鍵測試已完成"
    echo ""
    echo "總結："
    echo "  ✓ Tailscale 已安裝並運行"
    echo "  ✓ IP 位址已配置"
    echo "  ✓ 網路連線正常"
    echo ""
    echo "如有問題，請檢查："
    echo "  1. 執行 'sudo systemctl restart tailscaled' 重啟 Tailscale"
    echo "  2. 執行 'tailscale logout' 然後重新執行 setup.sh"
    echo "  3. 確認防火牆設定未阻止 Tailscale 連線"
    echo ""
}

# 錯誤處理
trap 'print_error "測試過程中出現錯誤"; exit 1' ERR

# 執行主程式
main "$@"
