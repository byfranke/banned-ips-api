# Documentação da API: byFranke Banned IPs

A API fornece dados detalhados, incluindo pontuação de risco (abuseConfidenceScore), geolocalização, provedor (ISP) e tipo de uso, permitindo a integração direta com sistemas de segurança como firewalls, SIEMs e outras ferramentas de análise.

## Endpoint

Recupera a lista de endereços IP banidos e seus metadados de inteligência.

```
curl "https://byfranke.com/api/v1/banned-ips.json"
```

## Formato de Resposta
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

## Exemplos Rápidos

### cURL (Terminal)
```bash
# Buscar todos os IPs
curl https://byfranke.com/api/v1/banned-ips.json

# Contar total de IPs
curl -s https://byfranke.com/api/v1/banned-ips.json | jq 'length'

# Filtrar por país
curl -s https://byfranke.com/api/v1/banned-ips.json | jq '.[] | select(.country == "BR")'

# Verificar IP específico
curl -s https://byfranke.com/api/v1/banned-ips.json | jq '.[] | select(.ip == "192.168.1.1")'
```

### Python
```python
import requests

# Buscar dados
response = requests.get('https://byfranke.com/api/v1/banned-ips.json')
ips = response.json()

# Filtrar por score alto
critical = [ip for ip in ips if ip['abuseConfidenceScore'] >= 90]
print(f"IPs críticos: {len(critical)}")
```

### PowerShell
```powershell
# Buscar e filtrar
$ips = Invoke-RestMethod "https://byfranke.com/api/v1/banned-ips.json"
$ips | Where-Object { $_.abuseConfidenceScore -ge 90 }
```

### PHP
```php
$json = file_get_contents('https://byfranke.com/api/v1/banned-ips.json');
$ips = json_decode($json, true);
echo "Total: " . count($ips);
```

### JavaScript
```javascript
fetch('https://byfranke.com/api/v1/banned-ips.json')
  .then(res => res.json())
  .then(data => console.log(`Total: ${data.length}`));
```

## Arquivos de Exemplo

- **examples_python.py** - Exemplos completos em Python
- **examples_bash.sh** - Scripts em Bash com cURL e jq
- **examples_powershell.ps1** - Scripts para PowerShell
- **examples_php.php** - Implementações em PHP
- **examples_javascript.js** - Código JavaScript/Node.js

## Casos de Uso

### 1. Verificação de IP Individual
Verifica se um IP específico está na lista de banidos.

### 2. Filtros por País
Obtém todos os IPs maliciosos de um país específico.

### 3. Score de Risco
Filtra IPs baseado no nível de ameaça (0-100).

### 4. Integração com Firewall
Exporta lista de IPs para bloqueio automático.

### 5. Relatórios de Threat Intelligence
Gera estatísticas e análises sobre as ameaças.

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

- **Crítico (100)**: Bloqueio imediato recomendado
- **Alto (75-99)**: Monitorar e considerar bloqueio
- **Médio (50-74)**: Atenção aumentada
- **Baixo (<50)**: Monitoramento padrão

## Dicas de Implementação

1. **Cache**: Implemente cache local para reduzir requisições
2. **Rate Limiting**: Respeite limites da API
3. **Filtros Combinados**: Use múltiplos critérios para melhor precisão
4. **Logs**: Mantenha registro de IPs bloqueados
5. **Atualização**: Atualize a lista regularmente

## Segurança

- Use HTTPS sempre
- Valide os dados recebidos
- Implemente timeout nas requisições
- Considere usar proxy/cache local
- Automatize o bloqueio com cautela

## Exemplos de Integração

### Firewall Linux (iptables)
```bash
# Bloquear IPs críticos automaticamente
for ip in $(curl -s https://byfranke.com/api/v1/banned-ips.json | \
  jq -r '.[] | select(.abuseConfidenceScore == 100) | .ip'); do
    iptables -A INPUT -s $ip -j DROP
done
```

### Windows Firewall (PowerShell)
```powershell
$ips = Invoke-RestMethod "https://byfranke.com/api/v1/banned-ips.json"
$critical = $ips | Where-Object { $_.abuseConfidenceScore -eq 100 }
foreach ($ip in $critical) {
    New-NetFirewallRule -DisplayName "Block_$($ip.ip)" -Direction Inbound -Action Block -RemoteAddress $ip.ip
}
```

### Apache .htaccess
```php
<?php
// Gerar arquivo .htaccess
$ips = json_decode(file_get_contents('https://byfranke.com/api/v1/banned-ips.json'), true);
$htaccess = "";
foreach ($ips as $ip) {
    if ($ip['abuseConfidenceScore'] >= 90) {
        $htaccess .= "Deny from {$ip['ip']}\n";
    }
}
file_put_contents('.htaccess', $htaccess);
?>
```


---

**Desenvolvido para profissionais de Cybersecurity, Threat Intelligence e Threat Hunting**
