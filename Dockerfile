# JBrowse

#
# This docker file uses multistage builds, where the first stage (named 'build')
# gets lots of prereqs, checks out git repos and runs the setup script. The
# resulting image is over 2GB and can be deleted after building. The second
# stage (called 'production') then copies files from the first stage and
# results in a image that is just over 100MB.
#

FROM nginx:latest as build
ENV DEBIAN_FRONTEND noninteractive

RUN mkdir -p /usr/share/man/man1 /usr/share/man/man7

RUN apt-get -qq update --fix-missing
RUN apt-get --no-install-recommends -y install wget curl software-properties-common git build-essential zlib1g-dev libpng-dev perl-doc ca-certificates

RUN curl -sL https://deb.nodesource.com/setup_10.x | bash -

RUN apt-get -y install nodejs

#RUN wget --quiet https://repo.anaconda.com/miniconda/Miniconda3-4.6.14-Linux-x86_64.sh -O ~/miniconda.sh && \
#    /bin/bash ~/miniconda.sh -b -p /conda/ && \
#    rm ~/miniconda.sh

#ENV PATH="/conda/bin:${PATH}"

#this probably isn't jbrowse-dev, so no adding plugins
#RUN conda install -y --override-channels --channel iuc --channel conda-forge --channel bioconda --channel defaults jbrowse=1.16.6

#RUN git clone --single-branch --branch 1.16.6-release https://github.com/GMOD/jbrowse.git
RUN git clone --single-branch --branch 1.16.8-release https://github.com/GMOD/jbrowse.git
RUN git clone --single-branch --branch 3.0 https://github.com/alliance-genome/agr_jbrowse_config.git 
RUN git clone --single-branch --branch release-3.0.0 https://github.com/alliance-genome/agr_jbrowse_plugin.git
RUN git clone --single-branch --branch agr-release-3.0.0 https://github.com/WormBase/website-genome-browsers.git

#no longer need to fetch vcf files
#WORKDIR /agr_jbrowse_config/scripts
#RUN ./fetch_vcf.sh jbrowse

RUN mkdir /usr/share/nginx/html/jbrowse

RUN rm /usr/share/nginx/html/index.html && rm /usr/share/nginx/html/50x.html && cp -r /jbrowse/* /usr/share/nginx/html/jbrowse && \
    cp /jbrowse/.htaccess /usr/share/nginx/html/jbrowse/.htaccess && \
    cp /agr_jbrowse_config/jbrowse/jbrowse.conf /usr/share/nginx/html/jbrowse && \
    cp -r /agr_jbrowse_config/jbrowse/data /usr/share/nginx/html/jbrowse && \
    cp -r /agr_jbrowse_plugin /usr/share/nginx/html/jbrowse/plugins/AlliancePlugin && \
    cp -r /website-genome-browsers/jbrowse/jbrowse/plugins/wormbase-glyphs /usr/share/nginx/html/jbrowse/plugins

WORKDIR /usr/share/nginx/html/jbrowse

#RUN npm install yarn
#RUN ./node_modules/.bin/yarn
#RUN JBROWSE_BUILD_MIN=1 ./node_modules/.bin/yarn build

RUN ./setup.sh

FROM nginx:latest as production

COPY --from=build /usr/share/nginx/html/jbrowse/dist /usr/share/nginx/html/jbrowse/dist
COPY --from=build /usr/share/nginx/html/jbrowse/browser /usr/share/nginx/html/jbrowse/browser
COPY --from=build /usr/share/nginx/html/jbrowse/css /usr/share/nginx/html/jbrowse/css
COPY --from=build /usr/share/nginx/html/jbrowse/data /usr/share/nginx/html/jbrowse/data
COPY --from=build /usr/share/nginx/html/jbrowse/img /usr/share/nginx/html/jbrowse/img
COPY --from=build /usr/share/nginx/html/jbrowse/index.html /usr/share/nginx/html/jbrowse/index.html
COPY --from=build /usr/share/nginx/html/jbrowse/jbrowse_conf.json /usr/share/nginx/html/jbrowse/jbrowse_conf.json
COPY --from=build /usr/share/nginx/html/jbrowse/jbrowse.conf /usr/share/nginx/html/jbrowse/jbrowse.conf
COPY --from=build /usr/share/nginx/html/jbrowse/LICENSE /usr/share/nginx/html/jbrowse/LICENSE
COPY --from=build /usr/share/nginx/html/jbrowse/plugins /usr/share/nginx/html/jbrowse/plugins
COPY --from=build /usr/share/nginx/html/jbrowse/site.webmanifest /usr/share/nginx/html/jbrowse/site.webmanifest
COPY --from=build /usr/share/nginx/html/jbrowse/.htaccess /usr/share/nginx/html/jbrowse/.htaccess

VOLUME /data
COPY docker-entrypoint.sh /
CMD ["/docker-entrypoint.sh"]
