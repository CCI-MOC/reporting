# get-info
FROM docker.io/robertbartlettbaron/perl_cpan:latest

# Install Dependencies
COPY ./cpan/Bundle/* 			/root/.cpan/Bundle/
COPY ./cpan/prefs/*			/root/.cpan/prefs/
COPY ./cpan/sources/authors/id/* 	/root/.cpan/sources/authors/id/
ENV PERL_MM_USE_DEFAULT=1
RUN /usr/local/bin/cpan -i Bundle::GetInfo

# Install Code
COPY ./src /code
WORKDIR /code
CMD ["/usr/bin/env", "perl", "docker_entrypoint.pl"]
HEALTHCHECK NONE
