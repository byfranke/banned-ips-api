# Documentação da API: byFranke Banned IPs

A API fornece dados detalhados sobre endereços IP maliciosos, incluindo pontuação de risco (abuseConfidenceScore), geolocalização, provedor (ISP) e tipo de uso. Ideal para integração com sistemas de segurança como firewalls, SIEMs e outras ferramentas de análise.

[![Banned IPs | Video de Demonstração](https://img.youtube.com/vi/l4Jdnefvzb0/maxresdefault.jpg)](https://www.youtube.com/watch?v=l4Jdnefvzb0)

## Endpoint e Uso da API

```bash
curl "https://byfranke.com/api/v1/banned-ips.json"
```

### Formato de Resposta

```json
[
  {
    "ip": "1.14.155.30",
    "abuseConfidenceScore": 68,
    "totalReports": 488,
    "country": "CN",
    "isp": "Tencent Cloud Computing (Beijing) Co., Ltd.",
    "usageType": "Data Center/Web Hosting/Transit",
    "lastReportedAt": "2025-10-22T02:13:04Z",
    "checkedAt": "2025-10-22T02:13:04Z"
  }
]
```

### Campos da API

| Campo | Tipo | Descrição |
|-------|------|-----------|
| ip | string | Endereço IP |
| abuseConfidenceScore | int | Score de risco (0-100) |
| totalReports | int | Número de denúncias |
| country | string | Código do país (ISO) |
| isp | string | Provedor de internet |
| usageType | string | Tipo de uso do IP |
| lastReportedAt | datetime | Último report |
| checkedAt | datetime | Última verificação |

### Níveis de Risco

* **Crítico (100)**: Bloqueio imediato recomendado
* **Alto (75-99)**: Monitorar e considerar bloqueio
* **Médio (50-74)**: Atenção aumentada
* **Baixo (<50)**: Monitoramento padrão

## Script Auxiliar (banned-ips-hunter.sh)

Este é um script interativo em bash para auxiliar na coleta e análise dos dados da API.

### Instalação do Script

Siga os passos abaixo para instalar o script auxiliar:

```bash
# Clone o repositório
git clone https://github.com/byfranke/banned-ips-api.git
cd banned-ips-api

# Instale as dependências necessárias
sudo apt update
sudo apt install -y curl jq

# Configure as permissões
chmod +x banned-ips-hunter.sh
```

### Como Usar o Script

Execute o script para entrar no modo interativo:

```bash
./banned-ips-hunter.sh
```

#### Visualização dos Resultados

O script formata os resultados em tabelas claras e coloridas:

* Níveis de risco identificados por cores (Vermelho: Crítico, Amarelo: Alto, Verde: Baixo)
* Scores de abuso apresentados em uma escala de 0-100
* Recomendações automáticas baseadas no nível de risco
* Estatísticas detalhadas com distribuição por países e tipos de uso

O menu oferece as seguintes funcionalidades:

1. Listar apenas IPs
2. Buscar IP específico
3. Top IPs mais reportados
4. Filtrar por país
5. Filtrar por score mínimo
6. Estatísticas gerais
7. Exportar blocklist
8. Atualizar dados da API

#### Detalhes das Funcionalidades

* **Busca de IP**: Análise completa com score de risco, reports, país, ISP e recomendações
* **Top Reportados**: Lista os IPs mais reportados com detalhes (score, reports, país, ISP)
* **Filtro por País**: Lista todos os IPs de um país específico
* **Filtro por Score**: Lista IPs com score igual ou superior ao especificado
* **Estatísticas**: Mostra distribuição por níveis de risco, top 5 países e tipos de uso
* **Exportação**: Gera blocklists em TXT (IPs), CSV (detalhado) ou script iptables

Os dados são mantidos em cache local por 1 hora para otimizar as consultas.

O script mantém um cache local para otimizar as consultas. Para forçar uma atualização, use a opção correspondente no menu.

### Consultas com cURL

```bash
# Consulta básica
curl -s https://byfranke.com/api/v1/banned-ips.json | jq '.'

# Filtrar por país (BR)
curl -s https://byfranke.com/api/v1/banned-ips.json | jq '.[] | select(.country == "BR")'

# Verificar IP específico
curl -s https://byfranke.com/api/v1/banned-ips.json | jq '.[] | select(.ip == "192.168.1.1")'

# Listar IPs críticos (score 100)
curl -s https://byfranke.com/api/v1/banned-ips.json | jq '.[] | select(.abuseConfidenceScore == 100)'
```

### Exemplo em Python

```python
import requests

def check_ip(ip):
    response = requests.get('https://byfranke.com/api/v1/banned-ips.json')
    data = response.json()
    
    # Procura o IP na lista
    for entry in data:
        if entry['ip'] == ip:
            return entry
    return None

# Exemplo de uso
result = check_ip('192.168.1.1')
if result:
    print(f"IP encontrado - Score: {result['abuseConfidenceScore']}")
else:
    print("IP não encontrado na lista")

## Casos de Uso Comuns

### Integração com Firewall Linux

```bash
# Bloquear IPs de alto risco (score >= 90)
curl -s https://byfranke.com/api/v1/banned-ips.json | \
jq -r '.[] | select(.abuseConfidenceScore >= 90) | .ip' | \
while read ip; do
    iptables -A INPUT -s $ip -j DROP
done
```

### Verificação em Lote

```python
import requests
import sys

def check_ips(ip_list):
    response = requests.get('https://byfranke.com/api/v1/banned-ips.json')
    banned = {entry['ip']: entry for entry in response.json()}
    
    for ip in ip_list:
        if ip in banned:
            data = banned[ip]
            print(f"[!] {ip} - Score: {data['abuseConfidenceScore']} - País: {data['country']}")
        else:
            print(f"[✓] {ip} - Não encontrado na lista")

# Exemplo: check_ips(['1.2.3.4', '5.6.7.8'])

## Campos Disponíveis

| Campo | Tipo | Descrição |
|-------|------|-----------|
| ip | string | Endereço IP |
| abuseConfidenceScore | int | Score de risco (0-100) |
| totalReports | int | Número de denúncias |
| country | string | Código do país (ISO) |
| isp | string | Provedor de internet |
| usageType | string | Tipo de uso do IP |
| lastReportedAt | datetime | Último report |
| checkedAt | datetime | Última verificação |

## Níveis de Risco

* **Crítico (100)**: Bloqueio imediato recomendado
* **Alto (75-99)**: Monitorar e considerar bloqueio
* **Médio (50-74)**: Atenção aumentada
* **Baixo (<50)**: Monitoramento padrão

## Dicas de Implementação

1. **Cache**: Implemente cache local para reduzir requisições
2. **Rate Limiting**: Respeite limites da API
3. **Filtros Combinados**: Use múltiplos critérios para melhor precisão
4. **Logs**: Mantenha registro de IPs bloqueados
5. **Atualização**: Atualize a lista regularmente

## Segurança

* Use HTTPS sempre
* Valide os dados recebidos
* Implemente timeout nas requisições
* Considere usar proxy/cache local
* Automatize o bloqueio com cautela

## Exemplos de Integração

### Firewall Linux (iptables)
```bash
# Bloquear IPs críticos automaticamente
for ip in $(curl -s https://byfranke.com/api/v1/banned-ips.json | \
  jq -r '.[] | select(.abuseConfidenceScore == 100) | .ip'); do
    iptables -A INPUT -s $ip -j DROP
done
```

---

## Sobre

Desenvolvido por byFranke para profissionais de Cybersecurity e Threat Intelligence.
