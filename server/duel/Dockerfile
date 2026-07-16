FROM ubuntu:24.04

RUN useradd --create-home --uid 10001 duel
WORKDIR /app

COPY build/server/RoamingHarvestDuelServer.x86_64 /app/RoamingHarvestDuelServer.x86_64
COPY build/server/RoamingHarvestDuelServer.pck /app/RoamingHarvestDuelServer.pck
RUN chmod 0555 /app/RoamingHarvestDuelServer.x86_64

USER duel
ENV DUEL_WS_BIND=0.0.0.0 \
    DUEL_WS_PORT=9080 \
    DUEL_MAX_CONNECTIONS=100 \
    DUEL_MAX_ROOMS=50
EXPOSE 9080

ENTRYPOINT ["/app/RoamingHarvestDuelServer.x86_64", "--headless", "--scene", "res://scenes/duel/DuelServer.tscn"]

