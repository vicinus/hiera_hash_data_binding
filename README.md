# hiera_hash_data_binding

Data binding terminus for Puppet 3+ that changes the way puppet looks class parameters up in hiera. Drop-in replacement for the Hiera data binding terminus.

Instead of querying every class parameter in hiera, hiera is queried for every class to provide a hash where the keys are the class parameters. An small example illustrate the differences:

With the original hiera data binding configuring the parameters of the class ntp looks like this:

```yaml
ntp::package_ensure: 'latest'
ntp::preferred_servers:
  - ntp1.example.com
  - ntp2.example.com
```

for every parameter of the class ntp which should be configured an entry is made. With the HieraHash data binding terminus a class entry is made and all parameters which should be configured are added as keys:

```yaml
ntp:
  package_ensure: 'latest'
  preferred_servers:
    - ntp1.example.com
    - ntp2.example.com
```

## Adventages

* Slightly faster, because only one hiera call per class must be made instead of one per class parameter per class.
* Class parameters are automatically retrieved as hashes from hiera. Therefore hiera merge behaviours `deep` or `deeper` are working for class parameters also.

## Disadvantages 

* Not official supported
* Hiera data must be converted
* Hiera version 1.x doesn't support segmented keys to look up values in hashes and arrays, so a workaround has to be used to access class parameters in hiera

## Installation

Install the module like any other module and in the puppet.conf configuration file in the main section add `data_binding_terminus = hiera_hash` or change it if it already exists.
