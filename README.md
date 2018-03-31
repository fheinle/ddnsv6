# ddnsv6

Collect IPv6 addresses from hosts and update CloudFlare's DNS with their `AAAA`
records

## Installation

This script has multiple components: the *client*, which sends its host's IPv6
address to the *server*, which keeps track of addresses and runs a *worker*
which periodically updates DNS with CloudFlare. This means you'll need to
install this script on a *server* host and on all *client* hosts.

Check out the source and install dependencies:

`bundler`

Make sure you have ruby's header files installed (`ruby-dev` in
Debian's/Ubuntu's packages).

Now copy `ddnsv6.conf.yaml.example` to `ddnsv6.conf.yaml` and fill out the
settings. You can use the same config file on every host, *server* settings are
just ignored on clients and vice-versa or you can omit all the settings that
are not needed. 

* `domains` (server): a list of domains this script will manage
* `basedir` (server): the path where the server should keep its records about
  addresses. Make sure the server has write-access to this destination.
* `server` (client): the hostname the client should send its requests to
* `port` (client): the port number the client should send its requests to
* `ssl` (client): `true` or `false`, whether the client should encrypt its
  communication with the server. Only works if there's a webserver in front of
  the server app that terminates SSL. The server portion can't do SSL on its
  own.
* `cloudflare_email`: (server): account name of your CloudFlare account
* `cloudflare_key`: (server): API key for CloudFlare
* `username` (client): username to use for the client's communication with the
  server. Only works if there's a webserver in front of the server app that
  handles authentication. The server portion can't do authentication on its
  own. 
* `password` (client): password to use for the client's communication with the
  server. Only works if there's a webserver in fron of the server app that
  handles authentication. The server portion can't do authentication on its
  own.
* `prefix`(client): IPv6-Prefix (no network part) ip addresses have to match to
  be included in the IP updates. Find out your provider's prefix and add it
  here, e.g. `2001`

To run the client, you need to have an environment variable that specifies
which network interface to look up for an IP address. This is not in the config
file, in order to make using different interfaces without config changes
easier. 

* `DDNS_IFACE` (client): interface name of your desired network interface, e.g.
  `eth0` 

On the server, you need to have a `whitelist.txt` with hostnames that should be
exported to CloudFlare's DNS. This is a security measure to avoid publishing
private IPs to the public DNS hierarchy. This file needs to contain one *FQDN*
per line, like so:

```
foo.domain.invalid
bar.domain.invalid
```

# Usage

To use the tool, you'll need to run the server continuously. It is highly
recommended to put a webserver like nginx or apache in front of the server
part. You may run the server part on its own, too, but you won't have features
like authentication or SSL in that case. [Here's a list of deployment methods
for the sinatra framework](http://recipes.sinatrarb.com/p/deployment?#article). 

To use the client, just set `DDNS_IFACE` to the interface name you want the IP
address to come from and run `client.rb`, ideally from a cronjob like so:

```
*/5 * * * * DDNS_IFACE=eth0 /home/ddns/app/client.rb
```

To have the DNS records on CloudFlare's DNS servers updated, run `worker.rb`,
ideally from a cronjob like so:

```
*/10 * * * * /home/ddns/app/worker.rb
```

# See also

* [Github](https://github.com/fheinle/ddnsv6) – [Issues](https://github.com/fheinle/ddnsv6/issues)
* [Puppet Module for installation](https://forge.puppet.com/fheinle/ddnsv6)
