FROM perl:5.20
COPY colorsummarizer-0.77 /usr/src/myapp
WORKDIR /usr/src/myapp

RUN cpan Config::General
RUN cpan Math::VecStat
RUN cpan Math::Round
RUN cpan Statistics::Descriptive
RUN cpan Statistics::Distributions
RUN cpan Statistics::Basic 
RUN cpan SVG
RUN cpan Graphics::ColorObject
RUN cpan JSON::XS
RUN cpan Algorithm::Cluster
RUN cpan Imager


CMD ["perl", "-X", "/usr/src/myapp/bin/colorsummarizer", "-dir", "\"/usr/images/*.jpg\"", "-json"]
