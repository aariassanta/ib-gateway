# IB Gateway — Configuración ORB-15

Docker-based IB Gateway (IBC + IB Gateway 10.45.1h) para paper trading con la cuenta `aariassanta-demo`.

## Arquitectura

```
ib-gateway (Docker) :4002 → 0.0.0.0:4002 → ib_insync / MCP :8765
```

- **Imagen base**: `ghcr.io/gnzsnz/ib-gateway:stable`
- **Imagen local**: `ib-gateway-fixed:latest` (con fixes de IB API)
- **Red**: `ib-trading-app_default` (externa)
- **Volumen**: `ib-gateway-new_ib-gateway-data` → `/home/ibgateway`
- **Puerto API**: 4002 (paper)

## Fixes aplicados

### 1. `common.sh` — Permission denied en restart loops

**Problema**: `common.sh` usa `envsubst >"${IBC_INI}"` que falla con `Permission denied` si el archivo ya existe con `root:root 600`. Esto causaba restart loops en el contenedor.

**Fix**: `rm -f "${IBC_INI}" && envsubst <"${IBC_INI_TMPL}" >"${IBC_INI}"`

### 2. `BypassOrderPrecautions=yes` — Órdenes PendingSubmit

**Problema**: Órdenes enviadas por API quedaban en `PendingSubmit` con `permId=0` — no llegaban a TWS.

**Fix**: Variable de entorno `BYPASS_WARNING=yes` → activa todos los bypass en `config.ini.tmpl`.

### 3. `TWS_ACCEPT_INCOMING=accept` — Conexiones API automáticas

**Problema**: IB Gateway mostraba diálogo "Incoming connection" que bloqueaba conexiones automáticas.

**Fix**: `TWS_ACCEPT_INCOMING=accept` en el template de IBC.

### 4. `AllowBlindTrading=yes` — Blind trading en opciones

**Problema**: Diálogo de advertencia al operar contratos sin market data subscription.

**Fix**: `ALLOW_BLIND_TRADING=yes` en el template.

## Uso

```bash
# Build de la imagen fija
cd /root/ib-gateway-new
docker build -t ib-gateway-fixed .

# Start
docker compose up -d

# Ver logs
docker logs ib-gateway

# Verificar conexión API
curl http://localhost:8765/api/status
```

## Variables de entorno (.env)

| Variable | Valor | Descripción |
|---|---|---|
| `TRADING_MODE` | `paper` | Cuenta paper |
| `IBKR_USERID` | `aariassanta-demo` | User IBKR |
| `IBKR_PASSWORD` | `***` | Password IBKR |
| `BYPASS_WARNING` | `yes` | Bypass order precautions |
| `TWS_ACCEPT_INCOMING` | `accept` | Auto-aceptar conexiones API |
| `ALLOW_BLIND_TRADING` | `yes` | Blind trading enabled |
| `READ_ONLY_API` | `no` | API permite órdenes |
| `AUTO_RESTART_TIME` | `11:45 PM` | Auto-reinicio diario |

## Testing de órdenes

```bash
cd /root/eval/orb15
/usr/local/lib/hermes-agent/venv/bin/python3.11 test_bag.py
```

**Resultado esperado**: `permId` real (no 0), orden en `reqOpenOrders()` con estado `Inactive` o `PreSubmitted`.

## Problemas conocidos

### BAG combo — Error 201 "Guaranteed-to-Lose combination orders"

Los BAG combos ITM profundos son rechazados por IBKR como *guaranteed-loss combos*. Para spreads, usar **legs separados con OCA group** en lugar de un único BAG.

### SPXW 0DTE settlement

SPXW 0DTE no liquida al close de SPX — usa settlement PM del CBOE subyacente, hasta ~81 pts de diferencia en días volátiles. El backtest usa `day_close` como aproximación.

## Volumen persistente

El volumen `ib-gateway-new_ib-gateway-data` contiene:
- `/home/ibgateway/ibc/config.ini` — settings IBC
- `/home/ibgateway/Jts/` — configuración TWS/IB Gateway
- `/home/ibgateway/scripts/` — scripts IBC (parcheados)

**AVISO**: Si el contenedor entra en restart loop, eliminar el volumen y recrearlo:
```bash
docker compose down -v
docker compose up -d
```
