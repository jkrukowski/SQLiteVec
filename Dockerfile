FROM swift:latest

WORKDIR /tmp

ADD Sources ./Sources
ADD Tests ./Tests
ADD Package.swift ./

CMD swift test
