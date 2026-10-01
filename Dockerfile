FROM ghcr.io/gnzsnz/ib-gateway:stable
USER root
# Fix common.sh: rm target file before redirect to avoid Permission denied on existing root-owned files
RUN sed -i 's|^[[:space:]]*envsubst <"\${IBC_INI_TMPL}" >"\${IBC_INI}"$|rm -f "${IBC_INI}" \&\& envsubst <"\${IBC_INI_TMPL}" >"\${IBC_INI}"|' /home/ibgateway/scripts/common.sh && \
    sed -i 's|^[[:space:]]*envsubst <"\${TWS_PATH}/\${TWS_INI_TMPL}" >"\${_JTS_PATH}/\${TWS_INI}"$|mkdir -p "${_JTS_PATH}" \&\& envsubst <"\${TWS_PATH}/\${TWS_INI_TMPL}" >"\${_JTS_PATH}/\${TWS_INI}"|' /home/ibgateway/scripts/common.sh && \
    sed -i '/^BypassOrderPrecautions=/d' /home/ibgateway/ibc/config.ini.tmpl && \
    sed -i '/^AllowBlindTrading=/d' /home/ibgateway/ibc/config.ini.tmpl && \
    echo "BypassOrderPrecautions=yes" >> /home/ibgateway/ibc/config.ini.tmpl && \
    echo "AllowBlindTrading=yes" >> /home/ibgateway/ibc/config.ini.tmpl
USER ibgateway

ENV BYPASS_WARNING=yes
ENV TWS_ACCEPT_INCOMING=accept
ENV ALLOW_BLIND_TRADING=yes
ENV ACCEPT_MKT_DATA_DIALOG=yes
ENV ACCEPT_NON_BROKERAGE_ACCOUNT_WARNING=yes
ENV TRADING_MODE=paper
ENV READ_ONLY_API=no
