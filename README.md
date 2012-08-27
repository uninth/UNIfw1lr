
[![Documentation][logo]][documentation]
[logo]: src/GAiA/UNIfw1lr-user-documentation.textbundle/assets/img/UNIfw1lr-coverpage.png
[documentation]: src/GAiA/UNIfw1lr-user-documentation.textbundle/UNIfw1lr.pdf

# UNIfw1lr

**UNIfw1lr** (UNI-C firewall-1 log rotation) is a set of simple firewall log
rotation and log management scripts for Check Point firewall-1.          
Version 1.0 has been tested on R77.10, R77.20 and R77.30 on both appliances and
open servers.

The binary format Check Point log files is exported to text (csv) and may
be processed with an external analyser. A wrapper for `fwlogsum` by Peter Sundstrom
is provided together with the application
[fwlogsum](http://www.ginini.com/software/fwlogsum/).

### Security

The software starts a web-server (https) on TCP port 127.0.0.1:9876. The address
may be changed in the configuration file.      
Access must be controlled in the firewall software.        
The web-server does not enforce login, as it is intended to serve log files
processed from an secured log consolidation server. The server uses the SSL
certificate of the default CA provided by Check Point.        
The web-server software is provided and maintained by Check Point.

## Deployment

The RPM and the installation instruction is found [in RPM](RPM).

## Documentation

[The documentation in pdf is here](src/GaIA/UNIfw1lr-user-documentation.textbundle/UNIfw1lr.pdf)

For recreating the pdf documentation see
[README-documentation](src/GAiA/UNIfw1lr-user-documentation.textbundle/README-documentation.md).

## Development

The source is written in perl/shell and changes should be easy to adapt.

## License

This is released under a
[modified BSD License](https://opensource.org/licenses/BSD-3-Clause). The report generator
fwlogsum by Copyright 1996, Peter Sundstrom, http://www.ginini.com/software/fwlogsum has
a GNU v2 license. Other licences may apply.

