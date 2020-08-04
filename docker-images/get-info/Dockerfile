
# get-info
FROM perl_cpan:latest

# Install Dependencies
ADD ./cpan/Bundle/* 			/root/.cpan/Bundle/
ADD ./cpan/prefs/*			/root/.cpan/prefs/
ADD ./cpan/sources/authors/id/* 	/root/.cpan/sources/authors/id/
ENV PERL_MM_USE_DEFAULT=1
RUN /usr/local/bin/cpan -i Bundle::GetInfo

# Install Code
ADD ./src /code
WORKDIR /code
CMD ["/usr/bin/env", "perl", "docker_entrypoint.pl"]
HEALTHCHECK NONE
