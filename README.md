# Collectd Surfboard

A Perl based Collectd plugin to collect Motorola/Arris Surfboard signal metrics.

## Requirements

* collectd with Perl support
* HTML::TableExtract
* libwww-perl

## Configuration

```
LoadPlugin perl

TypesDB "/usr/share/collectd/types.db"
TypesDB "/usr/share/collectd/sb-types.db"
<Plugin perl>
  IncludeDir "/etc/collectd/lib"
  BaseName "Collectd::Plugins"
  LoadPlugin SurfBoard
</Plugin>
```

You must define the sb-types.db and in doing so will replace the default types.db. 
So you must include that back in as well.

Alternately, you can append the sb-types.db entries to the system types.db

You must place your code inside a `Collectd/Plugins` directory inside whatever 
your IncludeDir is set to. So for the above example the SurfBoard.pm script should
reside in `/etc/collectd/lib/Collectd/Plugins`.


