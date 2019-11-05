$TTL    1D
@       IN      SOA     ns1.juno.com. admin.juno.com. (
                        1               ; Serial
                        1H              ; Refresh
                        5M              ; Retry
                        1D              ; Expire
                        6H )            ; Negative Cache TTL
;name servers
@       IN      NS      ns1.juno.com.
@       IN      NS      ns2.juno.com.

;ns records
ns1     IN      A       192.168.1.109
ns2     IN      A       192.168.1.110

;host records
gitlab  IN      A       192.168.1.105
