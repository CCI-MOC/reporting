
ARG PERL_VERSION=5.32

FROM perl:${PERL_VERSION}
ENV PERL_MM_USE_DEFAULT=1

COPY Snapshot_2020_10_05_00.pm /root/.cpan/Bundle/
RUN [ "/usr/local/bin/cpan", "Bundle::Snapshot_2020_10_05_00" ]
