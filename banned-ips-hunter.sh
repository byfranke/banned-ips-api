#!/bin/bash

#############################################
# Banned IPs Hunter - Threat Intelligence
# API: byFranke Banned IPs
# Autor: byFranke
# Github: https://github.com/byfranke/banned-ips-api/
#############################################

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color
BOLD='\033[1m'

API_URL="https://byfranke.com/api/v1/banned-ips.json"
CACHE_FILE="/tmp/banned-ips-cache.json"
CACHE_TIME=3600 # 1 hora

show_banner() {
    clear
    echo -e "${CYAN}${BOLD}"
    echo "╔═══════════════════════════════════════════════════════════╗"
    echo "║         BANNED IPS HUNTER - THREAT INTELLIGENCE           ║"
    echo "║                  byFranke API v1                          ║"
    echo "╚═══════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

check_dependencies() {
    local deps=("curl" "jq")
    local missing=()
    
    for cmd in "${deps[@]}"; do
        if ! command -v "$cmd" &> /dev/null; then
            missing+=("$cmd")
        fi
    done
    
    if [ ${#missing[@]} -gt 0 ]; then
        echo -e "${RED}[ERRO]${NC} Dependências ausentes: ${missing[*]}"
        echo "Instale com: sudo apt install curl jq"
        exit 1
    fi
}

fetch_data() {
    local force_refresh=${1:-false}
    
    if [ "$force_refresh" = true ] || [ ! -f "$CACHE_FILE" ] || [ $(($(date +%s) - $(stat -c %Y "$CACHE_FILE" 2>/dev/null || echo 0))) -gt $CACHE_TIME ]; then
        echo -e "${YELLOW}[*]${NC} Atualizando dados da API..."
        if curl -sf "$API_URL" -o "$CACHE_FILE"; then
            echo -e "${GREEN}[✓]${NC} Dados atualizados com sucesso"
            return 0
        else
            echo -e "${RED}[✗]${NC} Erro ao buscar dados da API"
            return 1
        fi
    else
        echo -e "${GREEN}[✓]${NC} Usando cache local (idade: $(($(date +%s) - $(stat -c %Y "$CACHE_FILE")))s)"
    fi
}

list_ips_only() {
    echo -e "\n${BOLD}═══ LISTA DE IPs BANIDOS ═══${NC}\n"
    jq -r '.[].ip' "$CACHE_FILE" | column
    echo -e "\n${CYAN}Total:${NC} $(jq 'length' "$CACHE_FILE") IPs"
}

search_ip() {
    local ip="$1"
    echo -e "\n${BOLD}═══ ANÁLISE DO IP: $ip ═══${NC}\n"
    
    local result=$(jq --arg ip "$ip" '.[] | select(.ip == $ip)' "$CACHE_FILE")
    
    if [ -z "$result" ]; then
        echo -e "${GREEN}[✓]${NC} IP não encontrado na lista de banidos"
        return 0
    fi
    
    local score=$(echo "$result" | jq -r '.abuseConfidenceScore')
    local reports=$(echo "$result" | jq -r '.totalReports')
    local country=$(echo "$result" | jq -r '.country')
    local isp=$(echo "$result" | jq -r '.isp')
    local usage=$(echo "$result" | jq -r '.usageType')
    local last_report=$(echo "$result" | jq -r '.lastReportedAt')
    
    local threat_level
    local color
    if [ "$score" -eq 100 ]; then
        threat_level="CRÍTICO"
        color=$RED
    elif [ "$score" -ge 75 ]; then
        threat_level="ALTO"
        color=$YELLOW
    elif [ "$score" -ge 50 ]; then
        threat_level="MÉDIO"
        color=$BLUE
    else
        threat_level="BAIXO"
        color=$GREEN
    fi
    
    echo -e "${color}[!] AMEAÇA DETECTADA - NÍVEL: $threat_level${NC}"
    echo ""
    echo -e "${BOLD}Score de Abuso:${NC} $score/100"
    echo -e "${BOLD}Total de Reports:${NC} $reports"
    echo -e "${BOLD}País:${NC} $country"
    echo -e "${BOLD}ISP:${NC} $isp"
    echo -e "${BOLD}Tipo de Uso:${NC} $usage"
    echo -e "${BOLD}Último Report:${NC} $last_report"
    
    echo -e "\n${BOLD}Recomendação:${NC}"
    if [ "$score" -eq 100 ]; then
        echo -e "${RED}⚠ BLOQUEIO IMEDIATO RECOMENDADO${NC}"
    elif [ "$score" -ge 75 ]; then
        echo -e "${YELLOW}⚠ Considerar bloqueio e monitoramento${NC}"
    else
        echo -e "${GREEN}ℹ Monitoramento padrão${NC}"
    fi
}

top_reported() {
    local limit=${1:-20}
    echo -e "\n${BOLD}═══ TOP $limit IPs MAIS REPORTADOS ═══${NC}\n"
    
    printf "%-4s %-18s %-8s %-10s %-6s %-35s\n" "Nº" "IP" "SCORE" "REPORTS" "PAÍS" "ISP"
    echo "────────────────────────────────────────────────────────────────────────────────────────"
    
    jq -r 'sort_by(-.totalReports) | .[:'"$limit"'] | 
           to_entries[] | 
           [.key + 1, .value.ip, .value.abuseConfidenceScore, .value.totalReports, .value.country, .value.isp] | 
           @tsv' "$CACHE_FILE" | \
    while IFS=$'\t' read -r num ip score reports country isp; do

        if [ "$score" -eq 100 ]; then
            score_color=$RED
        elif [ "$score" -ge 75 ]; then
            score_color=$YELLOW
        else
            score_color=$GREEN
        fi
        
        printf "${BOLD}%-4s${NC} %-18s ${score_color}%-8s${NC} %-10s %-6s %-35.35s\n" \
               "$num" "$ip" "$score" "$reports" "$country" "$isp"
    done
}

filter_by_country() {
    local country="$1"
    echo -e "\n${BOLD}═══ IPs DO PAÍS: $country ═══${NC}\n"
    
    local count=$(jq --arg country "$country" '[.[] | select(.country == $country)] | length' "$CACHE_FILE")
    
    if [ "$count" -eq 0 ]; then
        echo -e "${YELLOW}[!]${NC} Nenhum IP encontrado para o país: $country"
        return
    fi
    
    printf "%-18s %-8s %-10s %-40s\n" "IP" "SCORE" "REPORTS" "ISP"
    echo "────────────────────────────────────────────────────────────────────────────────"
    
    jq -r --arg country "$country" '.[] | 
           select(.country == $country) | 
           [.ip, .abuseConfidenceScore, .totalReports, .isp] | 
           @tsv' "$CACHE_FILE" | \
    while IFS=$'\t' read -r ip score reports isp; do
        printf "%-18s %-8s %-10s %-40.40s\n" "$ip" "$score" "$reports" "$isp"
    done
    
    echo -e "\n${CYAN}Total:${NC} $count IPs"
}

filter_by_score() {
    local min_score=${1:-90}
    echo -e "\n${BOLD}═══ IPs COM SCORE >= $min_score ═══${NC}\n"
    
    local count=$(jq --arg score "$min_score" '[.[] | select(.abuseConfidenceScore >= ($score | tonumber))] | length' "$CACHE_FILE")
    
    printf "%-18s %-8s %-10s %-6s %-35s\n" "IP" "SCORE" "REPORTS" "PAÍS" "ISP"
    echo "──────────────────────────────────────────────────────────────────────────────────────"
    
    jq -r --arg score "$min_score" '.[] | 
           select(.abuseConfidenceScore >= ($score | tonumber)) | 
           [.ip, .abuseConfidenceScore, .totalReports, .country, .isp] | 
           @tsv' "$CACHE_FILE" | \
    while IFS=$'\t' read -r ip score reports country isp; do
        printf "%-18s ${RED}%-8s${NC} %-10s %-6s %-35.35s\n" "$ip" "$score" "$reports" "$country" "$isp"
    done
    
    echo -e "\n${CYAN}Total:${NC} $count IPs"
}

show_statistics() {
    echo -e "\n${BOLD}═══ ESTATÍSTICAS GERAIS ═══${NC}\n"
    
    local total=$(jq 'length' "$CACHE_FILE")
    local critical=$(jq '[.[] | select(.abuseConfidenceScore == 100)] | length' "$CACHE_FILE")
    local high=$(jq '[.[] | select(.abuseConfidenceScore >= 75 and .abuseConfidenceScore < 100)] | length' "$CACHE_FILE")
    local medium=$(jq '[.[] | select(.abuseConfidenceScore >= 50 and .abuseConfidenceScore < 75)] | length' "$CACHE_FILE")
    local low=$(jq '[.[] | select(.abuseConfidenceScore < 50)] | length' "$CACHE_FILE")
    
    echo -e "${BOLD}Total de IPs:${NC} $total"
    echo ""
    echo -e "${RED}Crítico (100):${NC}     $critical"
    echo -e "${YELLOW}Alto (75-99):${NC}      $high"
    echo -e "${BLUE}Médio (50-74):${NC}     $medium"
    echo -e "${GREEN}Baixo (<50):${NC}       $low"
    echo ""
    
    echo -e "${BOLD}Top 5 Países:${NC}"
    jq -r 'group_by(.country) | 
           map({country: .[0].country, count: length}) | 
           sort_by(-.count) | 
           .[:5] | 
           .[] | 
           "\(.country): \(.count)"' "$CACHE_FILE" | \
    while read -r line; do
        echo "  • $line"
    done
    
    echo ""
    
    echo -e "${BOLD}Top 5 Tipos de Uso:${NC}"
    jq -r 'group_by(.usageType) | 
           map({type: .[0].usageType, count: length}) | 
           sort_by(-.count) | 
           .[:5] | 
           .[] | 
           "\(.type): \(.count)"' "$CACHE_FILE" | \
    while read -r line; do
        echo "  • $line"
    done
}

export_blocklist() {
    local format=${1:-txt}
    local min_score=${2:-90}
    local output_file
    
    case $format in
        txt)
            output_file="blocklist.txt"
            jq -r --arg score "$min_score" '.[] | 
                   select(.abuseConfidenceScore >= ($score | tonumber)) | 
                   .ip' "$CACHE_FILE" > "$output_file"
            ;;
        csv)
            output_file="blocklist.csv"
            echo "ip,score,reports,country,isp" > "$output_file"
            jq -r --arg score "$min_score" '.[] | 
                   select(.abuseConfidenceScore >= ($score | tonumber)) | 
                   [.ip, .abuseConfidenceScore, .totalReports, .country, .isp] | 
                   @csv' "$CACHE_FILE" >> "$output_file"
            ;;
        iptables)
            output_file="blocklist-iptables.sh"
            echo "#!/bin/bash" > "$output_file"
            echo "# Blocklist gerada em $(date)" >> "$output_file"
            echo "" >> "$output_file"
            jq -r --arg score "$min_score" '.[] | 
                   select(.abuseConfidenceScore >= ($score | tonumber)) | 
                   .ip' "$CACHE_FILE" | \
            while read -r ip; do
                echo "iptables -A INPUT -s $ip -j DROP" >> "$output_file"
            done
            chmod +x "$output_file"
            ;;
        *)
            echo -e "${RED}[✗]${NC} Formato inválido"
            return 1
            ;;
    esac
    
    echo -e "${GREEN}[✓]${NC} Blocklist exportada: $output_file"
    echo -e "${CYAN}[i]${NC} Score mínimo: $min_score"
    echo -e "${CYAN}[i]${NC} Total de IPs: $(wc -l < "$output_file")"
}

show_menu() {
    echo -e "\n${BOLD}OPÇÕES:${NC}"
    echo "  1) Listar apenas IPs"
    echo "  2) Buscar IP específico"
    echo "  3) Top IPs mais reportados"
    echo "  4) Filtrar por país"
    echo "  5) Filtrar por score mínimo"
    echo "  6) Estatísticas gerais"
    echo "  7) Exportar blocklist"
    echo "  8) Atualizar dados da API"
    echo "  0) Sair"
    echo -n -e "\n${CYAN}Escolha uma opção:${NC} "
}

main() {
    show_banner
    check_dependencies
    fetch_data
    
    while true; do
        show_menu
        read -r option
        
        case $option in
            1)
                list_ips_only
                ;;
            2)
                echo -n -e "${CYAN}Digite o IP:${NC} "
                read -r ip
                search_ip "$ip"
                ;;
            3)
                echo -n -e "${CYAN}Quantos IPs exibir? [20]:${NC} "
                read -r limit
                limit=${limit:-20}
                top_reported "$limit"
                ;;
            4)
                echo -n -e "${CYAN}Digite o código do país (ex: BR, US, CN):${NC} "
                read -r country
                filter_by_country "${country^^}"
                ;;
            5)
                echo -n -e "${CYAN}Score mínimo [90]:${NC} "
                read -r score
                score=${score:-90}
                filter_by_score "$score"
                ;;
            6)
                show_statistics
                ;;
            7)
                echo -e "\n${BOLD}Formatos disponíveis:${NC}"
                echo "  1) TXT (apenas IPs)"
                echo "  2) CSV (dados completos)"
                echo "  3) IPTABLES (script pronto)"
                echo -n -e "${CYAN}Escolha o formato:${NC} "
                read -r fmt_opt
                
                echo -n -e "${CYAN}Score mínimo [90]:${NC} "
                read -r exp_score
                exp_score=${exp_score:-90}
                
                case $fmt_opt in
                    1) export_blocklist "txt" "$exp_score" ;;
                    2) export_blocklist "csv" "$exp_score" ;;
                    3) export_blocklist "iptables" "$exp_score" ;;
                    *) echo -e "${RED}[✗]${NC} Opção inválida" ;;
                esac
                ;;
            8)
                fetch_data true
                ;;
            0)
                echo -e "\n${GREEN}[✓]${NC} Até logo!"
                exit 0
                ;;
            *)
                echo -e "${RED}[✗]${NC} Opção inválida"
                ;;
        esac
        
        echo -n -e "\n${YELLOW}Pressione ENTER para continuar...${NC}"
        read -r
    done
}

main
