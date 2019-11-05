$TTL    1D
@       IN      SOA     ns1.juno.com. admin.juno.com. (
                        1               ; Serial
                        1H              ; Refresh
                        5M              ; Retry
                        1D              ; Expire
                        6H )            ; Negative Cache TTL

@       IN      NS      ns1.juno.com.
@       IN      NS      ns2.juno.com.


105     IN      PTR     gitlab.juno.com.
