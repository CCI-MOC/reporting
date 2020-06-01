
# init-db
FROM perl:5.28
ADD ./src /code
WORKDIR /code

ENV PERL_MM_USE_DEFAULT=1
RUN  true \
    # Bring CPAN up-to-date
  && /usr/local/bin/cpan -j /code/cpan/Config.pm -u \
    # Enable Distroprefs w/ YAML
  && /usr/local/bin/cpan -j /code/cpan/Config.pm -i YAML \
    # Install
  && /usr/local/bin/cpan -j /code/cpan/Config.pm -i Bundle::GetInfo

# Entry
CMD ["/usr/bin/env", "perl", "docker_entrypoint.pl"]
HEALTHCHECK NONE
