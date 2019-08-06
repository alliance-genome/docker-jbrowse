# JBrowse
FROM nginx:latest
ENV DEBIAN_FRONTEND noninteractive

RUN mkdir -p /usr/share/man/man1 /usr/share/man/man7

RUN apt-get -qq update --fix-missing
RUN apt-get --no-install-recommends -y install curl software-properties-common git build-essential zlib1g-dev libxml2-dev libexpat-dev postgresql-client libpq-dev libpng-dev wget unzip perl-doc ca-certificates

RUN curl -sL https://deb.nodesource.com/setup_10.x | bash -

RUN apt-get -y install nodejs

RUN wget --quiet https://repo.anaconda.com/miniconda/Miniconda3-4.6.14-Linux-x86_64.sh -O ~/miniconda.sh && \
    /bin/bash ~/miniconda.sh -b -p /conda/ && \
    rm ~/miniconda.sh

ENV PATH="/conda/bin:${PATH}"

RUN conda install -y --override-channels --channel iuc --channel conda-forge --channel bioconda --channel defaults jbrowse=1.16.6

RUN git clone https://github.com/alliance-genome/jbrowse-config.git 
RUN git clone https://github.com/alliance-genome/AlliancePlugin.git
RUN git clone --single-branch --branch jbrowse-staging https://github.com/WormBase/website-genome-browsers.git

RUN rm /usr/share/nginx/html/index.html && rm /usr/share/nginx/html/50x.html && cp -r /conda/opt/jbrowse/* /usr/share/nginx/html/ && \
    cp /jbrowse-config/jbrowse/jbrowse.conf /usr/share/nginx/html/ && \
    cp -r /jbrowse-config/jbrowse/data /usr/share/nginx/html/ && \
    cp -r /AlliancePlugin /usr/share/nginx/html/plugins && \
    cp -r /website-genome-browsers /usr/share/nginx/html/plugins
#    cp /conda/opt/jbrowse/.htaccess /usr/share/nginx/html/ && \
#    mkdir /usr/share/nginx/html/data && \
#    cp -r /jbrowse/data /usr/share/nginx/html/data && \
#    ln -s /jbrowse/data/ /usr/share/nginx/html/data && \
#    sed -i '/include += {dataRoot}\/tracks.conf/a include += {dataRoot}\/datasets.conf' /usr/share/nginx/html/jbrowse.conf && \
#    sed -i '/include += {dataRoot}\/tracks.conf/a include += {dataRoot}\/../datasets.conf' /usr/share/nginx/html/jbrowse.conf

WORKDIR /usr/share/nginx/html/

RUN ./setup.sh

VOLUME /data
COPY docker-entrypoint.sh /
CMD ["/docker-entrypoint.sh"]
